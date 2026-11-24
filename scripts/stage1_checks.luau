-- Production modules + pinned upstream oracle, executed in the official Luau CLI.
local function equal(a,b)
	assert(#a==#b)
	for i,v in ipairs(a) do assert(v==b[i],"Mismatch at "..i..": "..tostring(v).." / "..tostring(b[i])) end
end
for _,case in ipairs(Oracle.rng) do
	local rng=Random32.new(case.seed); equal(rng.getState(),case.initial)
	for _,expected in ipairs(case.values) do assert(rng.next()==expected,"RNG differs from upstream") end
	equal(rng.getState(),case.state)
	local restored=Random32.fromState(rng.getState())
	for _=1,100 do assert(rng.next()==restored.next()) end
end
local heap=MinHeap.new(2); local pop=0
for _,op in ipairs(Oracle.heap.ops) do
	if op[1]=="push" then heap.enqueue(op[2],op[3]) else pop+=1; assert(heap.dequeue()==Oracle.heap.dequeues[pop],"Heap differs from upstream at pop "..pop) end
end
heap.enqueue(20,1.00000003);heap.enqueue(21,1)
local clone=MinHeap.new();clone.restore(heap.getState())
while heap.size()>0 do assert(heap.dequeue()==clone.dequeue()) end
for _,case in ipairs(Oracle.math or {}) do assert(DetMath[case.name](unpack(case.args))==case.value,"DetMath mismatch: "..case.name) end
print("Pinned upstream parity: 1280 RNG values, 4522 heap operations; state restoration and deterministic math passed.")

local function fixture()
	return Grid.new(5,4,function(ref) return if ref==7 then 0 elseif ref==19 then 159 else 128 end)
end
local grid=fixture();local n={}
assert(grid.neighbors4(0,n)==2); equal({n[1],n[2]},{5,1})
assert(grid.neighbors4(4,n)==2); equal({n[1],n[2]},{9,3})
assert(grid.neighbors4(6,n)==4);equal(n,{1,11,5,7})
assert(not grid.valid(-1) and not grid.valid(20) and not grid.valid(0/0))
assert(not pcall(grid.setOwnerID,7,1) and not pcall(grid.setOwnerID,19,1))
grid.setState(6,0x6001);grid.setOwnerID(6,2)
assert(grid.state(6)==0x6002 and grid.Counts[1]==0 and grid.Counts[2]==1 and grid.isBorder(6))
grid.setOwnerID(6,0);assert(grid.state(6)==0x6000)
grid.setState(6,0);assert(grid.allocatedBytes()==0)
local types=Grid.new(5,1,function(ref) return ({128,138,148,159,0})[ref+1] end)
for i,v in ipairs({"Plains","Highland","Mountain","Impassable","Ocean"}) do assert(types.terrainType(i-1)==v) end

-- Earth geography remains the original detailed Natural Earth mask.
local function at(lon,lat) return math.floor((90-lat)/180*4096)*8192+math.floor((lon+180)/360*8192) end
for _,point in ipairs({{20,5},{100,45},{-100,40},{135,-25},{-155.6,19.6},{121,23.7},{0,-85}}) do
	local ref=at(unpack(point)); assert(bit32.band(EarthTerrain.byte(ref),128)~=0 and WorldMap.isLand(ref+1))
end
for _,point in ipairs({{-140,0},{-87,47.5},{108,53.5},{51,42},{119.5,24}}) do assert(bit32.band(EarthTerrain.byte(at(unpack(point))),128)==0) end
assert(EarthTerrain.waterComponent(at(-140,0))~=EarthTerrain.waterComponent(at(-87,47.5)))
assert(bit32.band(EarthTerrain.byte(at(-140,0)),32)~=0 and bit32.band(EarthTerrain.byte(at(-87,47.5)),32)==0)
local r=Random32.new(999)
for _=1,10000 do
	local ref=r.nextInt(0,8192*4096)
	assert((bit32.band(EarthTerrain.byte(ref),128)~=0)==WorldMap.isLand(ref+1))
end
assert(EarthTerrain.cacheBytes()<=128*4096)
print("Packed grid masks, no-wrap cardinal order, terrain classes, lakes/ocean and 10,000 Earth samples passed.")

-- Ordered simulation replay, varying wall-clock frame cadence, fractional picks.
local function run(frame)
	local sim=Simulation.new(EarthTerrain,WorldMap,51)
	sim.enqueue({Kind="Join",UserId=-2,Username="Alice"});sim.enqueue({Kind="Join",UserId=-1,Username="Bob"})
	sim.enqueue({Kind="Ready",UserId=-2})
	local ref=at(20,5);local x,y=WorldMap.xy(ref+1)
	sim.enqueue({Kind="SelectSpawn",UserId=-2,X=x+0.125,Y=y+0.875})
	sim.enqueue({Kind="SelectSpawn",UserId=-1,X=x+0.125,Y=y+0.875})
	local packets={};local c=Clock.new(function() local packet=sim.step();table.insert(packets,packet) end,4)
	for _,dt in ipairs(frame) do c.advance(dt) end
	while c.Backlog>=0.1-1e-8 do c.advance(0) end
	return sim,packets
end
local a,packets=run(table.create(240,0.1));local b=run(table.create(60,0.4))
assert(a.Tick==240 and b.Tick==240 and a.Phase=="Started")
local am,bm=a.metadata(),b.metadata()
for i,p in ipairs(am.Players) do
	assert(p.Spawn==bm.Players[i].Spawn and p.Count==1)
	assert(a.Grid.ownerID(p.Spawn-1)==p.SmallId)
end
assert(am.Players[1].X%1==0.125 and am.Players[1].Y%1==0.875)
equal(a.Grid.chunkKeys(),b.Grid.chunkKeys())
for _,key in ipairs(a.Grid.chunkKeys()) do assert(buffer.tostring(a.Grid.copyChunk(key))==buffer.tostring(b.Grid.copyChunk(key))) end

-- Actual snapshot receiver: staging remains hidden until End; delayed deltas replay.
local replica=Replica.new(EarthTerrain)
local keys=a.Grid.chunkKeys();local before=replica.Grid
assert(replica.begin({ID=1,Tick=a.Tick,Count=#keys,Meta=a.metadata(),MapHash=EarthTerrain.MaskHash}))
for _,key in ipairs(keys) do assert(replica.chunk({ID=1,Key=key,Data=a.Grid.copyChunk(key)})) end
assert(replica.Grid==before)
a.enqueue({Kind="Leave",UserId=-1});local packet=a.step();assert(replica.delta(packet))
assert(replica.finish({ID=1}) and replica.Tick==a.Tick)
for _,key in ipairs(keys) do assert(buffer.tostring(replica.Grid.copyChunk(key))==buffer.tostring(a.Grid.copyChunk(key))) end
assert(not replica.delta({Tick=a.Tick+2,Changes=buffer.create(0)}),"Missing ticks must require resync")
assert(not replica.begin({ID=2,Tick=0,Count=0,MapHash="wrong"}))
assert(replica.begin({ID=3,Tick=a.Tick,Count=1,Meta=a.metadata(),MapHash=EarthTerrain.MaskHash}))
assert(not replica.finish({ID=3}),"Incomplete snapshot must not install")
assert(replica.Tick==a.Tick)
print("240-tick frame-cadence replay, exact spawn positions, automatic spawns, atomic snapshot/delta recovery passed.")

-- Exact upstream old-tick -> initialize-pending -> next-tick scheduling.
local scheduler=Executions.new();local log={};local context={inSpawnPhase=function() return false end}
local function exec(id)
	local active=true
	return {activeDuringSpawnPhase=function() return false end,isActive=function() return active end,
	init=function(_,tick) table.insert(log,id.." init "..tick) end,
	tick=function(tick) table.insert(log,id.." tick "..tick); active=false end}
end
scheduler.add(exec("a"));scheduler.step(context);scheduler.add(exec("b"));scheduler.step(context);scheduler.step(context)
equal(log,{"a init 0","a tick 1","b init 1","b tick 2"})

-- Storage/serialization benchmark independent of geography and Stage 2 gameplay.
local load=Grid.new(8192,4096,function() return 128 end)
local start=os.clock()
for ref=0,1048575 do load.setOwnerID(ref,ref%100+1) end
local fill=os.clock()-start
assert(load.allocatedBytes()==2097152)
start=os.clock();local delta=load.drain();local encode=os.clock()-start
assert(buffer.len(delta)==1048576*6)
print(string.format("1,048,576 owned cells: %.3fs writes, %.3fs delta packing, %d state bytes (excluding dirty-index tables).",fill,encode,load.allocatedBytes()))
