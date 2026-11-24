--!native
--!strict
-- Adapted from OpenFront FlatBinaryHeap.ts, pinned 8f1a0add.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE and NOTICE.
-- Modified 2026-11-17: packed Luau f32 priorities/u32 tile IDs, same tie ordering.
local Heap = {}
function Heap.new(capacity: number?)
	local cap=capacity or 1024
	assert(cap>=1 and cap%1==0)
	local pri,tiles=buffer.create(cap*4),buffer.create(cap*4)
	local len=0
	local result={}
	function result.size(): number return len end
	function result.clear() len=0 end
	function result.enqueueUnchecked(tile: number, priority: number)
		if len==cap then
			local p,t=buffer.create(cap*8),buffer.create(cap*8)
			buffer.copy(p,0,pri); buffer.copy(t,0,tiles)
			pri,tiles,cap=p,t,cap*2
		end
		local i=len; len+=1
		-- Compare the incoming DOUBLE before its first f32 write, like upstream.
		while i>0 do
			local parent=math.floor((i-1)/2)
			if priority>=buffer.readf32(pri,parent*4) then break end
			buffer.writef32(pri,i*4,buffer.readf32(pri,parent*4))
			buffer.writeu32(tiles,i*4,buffer.readu32(tiles,parent*4)); i=parent
		end
		buffer.writef32(pri,i*4,priority); buffer.writeu32(tiles,i*4,tile)
	end
	function result.enqueue(tile: number, priority: number)
  assert(tile>=0 and tile<4294967296 and tile%1==0)
  assert(priority==priority and math.abs(priority)<math.huge)
  result.enqueueUnchecked(tile,priority)
 end
	function result.dequeue(): number
		assert(len>0,"heap empty")
		local top=buffer.readu32(tiles,0); len-=1
		local lastPri,lastTile=buffer.readf32(pri,len*4),buffer.readu32(tiles,len*4)
		local i=0
		while true do
			local left=i*2+1
			if left>=len then break end
			local right=left+1
			local child=if right<len and buffer.readf32(pri,right*4)<buffer.readf32(pri,left*4) then right else left
			if lastPri<=buffer.readf32(pri,child*4) then break end
			buffer.writef32(pri,i*4,buffer.readf32(pri,child*4))
			buffer.writeu32(tiles,i*4,buffer.readu32(tiles,child*4)); i=child
		end
		buffer.writef32(pri,i*4,lastPri); buffer.writeu32(tiles,i*4,lastTile)
		return top
	end
	function result.getState()
		local p,t=buffer.create(len*4),buffer.create(len*4)
		buffer.copy(p,0,pri,0,len*4); buffer.copy(t,0,tiles,0,len*4)
		return {Priorities=p,Tiles=t,Capacity=cap}
	end
	function result.restore(state)
		assert(buffer.len(state.Priorities)==buffer.len(state.Tiles) and buffer.len(state.Tiles)%4==0)
		cap=state.Capacity; len=buffer.len(state.Tiles)/4; assert(cap>=math.max(1,len))
		pri,tiles=buffer.create(cap*4),buffer.create(cap*4)
		buffer.copy(pri,0,state.Priorities); buffer.copy(tiles,0,state.Tiles)
	end
	return result
end
return Heap
