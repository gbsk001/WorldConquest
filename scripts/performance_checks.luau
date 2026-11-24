-- Synthetic load of real production algorithms, not a live 100-client FPS test.
do
	local start = os.clock()
	local spawns = {}
	for userId = 1,100 do
		assert(SpawnRules.autoSelect(spawns,userId,(userId*104729)%WorldMap.LandCount+1))
	end
	local owners = SpawnRules.start(spawns)
 local setup=os.clock()-start
 local engine=Frontier.new(owners,{MaxOwnedCells=1048576,ClaimsPerPlayerPerTick=16,ClaimsPerTick=256,FrontierChecksPerTick=4096,FrontierChecksPerPlayer=128})
 local timings,addedCount={},0
 for _=1,1000 do
  local before=os.clock()
  local changes,checks=engine.step()
  table.insert(timings,(os.clock()-before)*1000)
  local tickCount=0
  for _,g in ipairs(changes) do tickCount+=#g.Cells; assert(#g.Cells<=16) end
  assert(tickCount<=256 and checks<=4096)
  addedCount+=tickCount
 end
 table.sort(timings)
 local sum=0; for _,v in ipairs(timings) do sum+=v end
 print(string.format("100 players / 1000 ticks / %d added cells: mean %.3fms, p95 %.3fms, max %.3fms",addedCount,sum/#timings,timings[950],timings[1000]))
	local raster=OwnershipRaster.new()
	for userId=1,100 do raster.setColor(userId,55+userId*13%200,55+userId*29%200,55+userId*43%200) end
	start=os.clock()
	local total=0
	for cell,owner in pairs(owners) do
		assert(WorldMap.isLand(cell))
		raster.set(cell,owner,0,false)
		total+=1
	end
	local rasterTime=os.clock()-start
	WorldMap.prepareDisplay()
	local samples={}
	for _,level in ipairs({0,1,2,3,4,5}) do
		local slot={Level=level,X=math.floor(4500/(256*2^level)),Y=math.floor(1800/(256*2^level)),
			Pixels=buffer.create(258*258*4),Coverage=buffer.create(258*258)}
		start=os.clock()
		TilePainter.paint(slot,raster,1,true)
		local fresh=os.clock()-start
		start=os.clock()
		TilePainter.paint(slot,raster,1,false,120,135,120,135)
		local dirty=os.clock()-start
		assert(buffer.readu8(slot.Pixels,3)==255)
		local incremental={Level=slot.Level,X=slot.X,Y=slot.Y,Pixels=buffer.create(258*258*4),Coverage=buffer.create(258*258)}
		local px,py=slot.X*256*2^level+120*2^level,slot.Y*256*2^level+120*2^level
        local changed=WorldMap.cell(px,py)
        raster.set(changed,1,1,false)
        TilePainter.paint(slot,raster,1,false,121,121,121,121)
        local maxSlice=0
		for row=0,257,8 do
			local sliceStart=os.clock()
			TilePainter.paint(incremental,raster,1,true,row,math.min(257,row+7))
			maxSlice=math.max(maxSlice,os.clock()-sliceStart)
		end
		assert(buffer.tostring(incremental.Pixels)==buffer.tostring(slot.Pixels),"Frame-budgeted painting must match a complete tile")
		table.insert(samples,string.format("LOD%d new %.2fms / repaint %.2fms",level,fresh*1000,dirty*1000))
		assert(maxSlice<0.1,"Unexpectedly slow render slice")
	end
	print(string.format("%d exact ownership cells inserted in %.3fs",total,rasterTime))
	print(table.concat(samples,"; "))
	print("Performance samples are local Luau CPU timings, excluding Roblox networking, GPU and device variability.")
end
