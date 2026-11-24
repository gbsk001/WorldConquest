--!strict
-- Run manually from Studio's SERVER Command Bar; isolated tables only.
local Frontier = require(script.Parent:WaitForChild("Frontier"))
local Rules = require(script.Parent:WaitForChild("Rules"))
local Map = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Map"))

return function()
	local function at(lon: number, lat: number): number
		return assert(Map.cell((lon + 180) / 360 * Map.Width, (90 - lat) / 180 * Map.Height))
	end
	local africa, asia = at(20, 5), at(100, 45)
	local ocean = at(-140, 0)
	assert(Map.isLand(africa) and Map.isLand(asia))
	assert(not Map.isLand(ocean))
	local spawns: {[number]: number} = {}
	assert(Rules.selectSpawn(spawns, -1, africa))
	assert(not Rules.selectSpawn(spawns, -2, africa), "Same spawn must be rejected")
	assert(Rules.selectSpawn(spawns, -2, Map.neighbors(africa)[1]), "Distinct adjacent cells are valid spawns")
	assert(Rules.selectSpawn(spawns, -2, asia))
	assert(not Rules.selectSpawn(spawns, -1, asia))
	assert(spawns[-1] == africa, "Rejected moves must preserve the previous spawn")
	assert(not Rules.selectSpawn(spawns, -1, ocean))
	for _, bad in ipairs({ 0, -1, 1.5, 0 / 0, math.huge, Map.Width * Map.Height + 1, "1", false, {} }) do
		assert(not Rules.selectSpawn(spawns, -1, bad), "Malformed cell must be rejected")
	end
	assert(not Rules.selectSpawn(spawns, -1, nil))
	local moved = at(-100, 40)
	assert(Rules.selectSpawn(spawns, -1, moved))
	assert(Rules.selectSpawn(spawns, -3, africa), "Moving must free the previous reservation")
	assert(Rules.autoSelect(spawns, -4, 1), "Automatic placement must find free land")
	local owners = Rules.start(spawns)
	local counts: {[number]: number} = {}
	for cell, owner in pairs(owners) do
		assert(Map.isLand(cell), "No starting territory may include ocean")
		counts[owner] = (counts[owner] or 0) + 1
	end
	for userId, cell in pairs(spawns) do
		assert(owners[cell] == userId)
		assert(counts[userId] == 1)
	end
	-- Geography is intentionally disconnected: no artificial bridges over oceans.
	for _, cell in ipairs({ africa, asia, moved, at(135, -25), at(-42, 73) }) do
		local seed = Map.seed(cell)
		for _, neighbor in ipairs(seed) do assert(Map.isLand(neighbor)) end
		for _, neighbor in ipairs(Map.neighbors(cell)) do
			assert(table.find(Map.neighbors(neighbor), cell), "Adjacency must be reciprocal")
		end
	end
	assert(Map.cell(-1, 0) == nil and Map.cell(Map.Width, 0) == nil)
	assert(Map.cell(0, -1) == nil and Map.cell(0, Map.Height) == nil)
 local limits = {MaxOwnedCells=1048576,ClaimsPerPlayerPerTick=16,ClaimsPerTick=256,FrontierChecksPerTick=4096,FrontierChecksPerPlayer=128}
 local first = Frontier.new(Rules.start({[-1]=africa}),limits)
 local replay = Frontier.new(Rules.start({[-1]=africa}),limits)
 local hx,hy=Map.xy(africa)
 assert(not first.claimCell(-1,Map.cell(hx+1,hy+1)),"Diagonal-only cells are not adjacent")
 local a,b = first.step(),replay.step()
 assert(#a[1].Cells==4,"First wave must claim all four edges, not a disk")
 for i,cell in ipairs(a[1].Cells) do assert(cell==b[1].Cells[i]) end
 assert(not first.claimCell(-1,asia) and not first.claimCell(-1,ocean))
 for _=1,100 do
  local before=table.clone(first.Owners)
  a,b=first.step(),replay.step()
  assert(#a==#b)
  for j,g in ipairs(a) do
   assert(#g.Cells<=16 and #g.Cells==#b[j].Cells)
   for i,cell in ipairs(g.Cells) do
    assert(cell==b[j].Cells[i] and not before[cell] and Map.isLand(cell))
    local touches=false
    for _,n in ipairs(Map.neighbors(cell)) do if before[n]==g.Owner then touches=true end end
    assert(touches,"Every claim must share an edge with pre-tick territory")
   end
  end
 end
 local island=Frontier.new(Rules.start({[-1]=at(-155.6,19.6)}),limits)
 for _=1,1000 do island.step() end
 for cell in pairs(island.Owners) do
  local x,y=Map.xy(cell)
  local lon,lat=x/Map.Width*360-180,90-y/Map.Height*180
  assert(lon>-156.2 and lon< -154.7 and lat>18.8 and lat<20.4,"Ocean jump")
  for _,n in ipairs(Map.neighbors(cell)) do assert(island.Owners[n],"Island must fill completely") end
 end
 local small=table.clone(limits); small.MaxOwnedCells=5
 local capped=Frontier.new({[africa]=1},small)
 capped.step(); assert(capped.atCapacity() and #capped.step()==0)
 assert(#capped.release(1)==5 and not capped.atCapacity())
 local neighbor=Map.neighbors(africa)[1]
 local freed=Frontier.new({[africa]=1,[neighbor]=2},limits)
 freed.release(2); assert(freed.claimCell(1,neighbor) and freed.Counts[1]==2)
 print("Spawn, single-cell starts, entire frontier, deterministic waves, capacity, release and island isolation passed.")
end
