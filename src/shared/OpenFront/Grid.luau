--!native
--!strict
-- GameMapImpl state/terrain masks and N/S/W/E semantics adapted from OpenFront 8f1a0add.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE and NOTICE.
-- Modified 2026-11-17: lazy 4096-cell buffers instead of a full Uint16Array.
local Grid = {ChunkCells=4096, OwnerMask=0xfff, FalloutBit=0x2000, DefenseBit=0x4000}
-- Exact optional transport encoding for uniform-state fragments (mass fallout
-- and disconnects). Preserve reference order; no simulation or cell omission.
function Grid.compressChanges(packed)
 local length=buffer.len(packed)
 if length<96 then return packed,nil end
 local value=buffer.readu16(packed,4)
 for offset=10,length-1,6 do if buffer.readu16(packed,offset)~=value then return packed,nil end end
 local refs=buffer.create(length/6*4)
 for offset=0,length-1,6 do buffer.writeu32(refs,offset/6*4,buffer.readu32(packed,offset)) end
 return refs,value
end
function Grid.expandChanges(refs,value,maxCells)
 if typeof(refs)~="buffer" or typeof(value)~="number" or value%1~=0 or value<0 or value>65535 or buffer.len(refs)%4~=0 or buffer.len(refs)/4>maxCells then return nil end
 local packed=buffer.create(buffer.len(refs)/4*6)
 for offset=0,buffer.len(refs)-1,4 do buffer.writeu32(packed,offset/4*6,buffer.readu32(refs,offset));buffer.writeu16(packed,offset/4*6+4,value) end
 return packed
end
-- Versioned transport-only delta coding. Keep the original ordered records;
-- most BFS neighbours fit a signed 16-bit difference, including +/-8192 rows.
function Grid.compressWire(packed)
 local n=buffer.len(packed)/6
 if n<16 then return packed,nil,nil end
 local uniform=buffer.readu16(packed,4)
 for o=10,buffer.len(packed)-1,6 do if buffer.readu16(packed,o)~=uniform then uniform=nil;break end end
 local out=buffer.create(buffer.len(packed)+4);local used=4;local previous=buffer.readu32(packed,0)
 buffer.writeu32(out,0,previous)
 if uniform==nil then buffer.writeu16(out,used,buffer.readu16(packed,4));used+=2 end
 for o=6,buffer.len(packed)-1,6 do
  local ref=buffer.readu32(packed,o);local delta=ref-previous
  local short=delta>=-32767 and delta<=32767
  local needed=(if short then 2 else 6)+(if uniform==nil then 2 else 0)
  if used+needed>buffer.len(out) then return Grid.compressChanges(packed)end
  if delta>=-32767 and delta<=32767 then buffer.writei16(out,used,delta);used+=2
  else
   -- Falling back avoids oversized scratch for adversarial scattered records.
   if used+8>buffer.len(out) then return Grid.compressChanges(packed)end
   buffer.writei16(out,used,-32768);buffer.writeu32(out,used+2,ref);used+=6
  end
  if uniform==nil then buffer.writeu16(out,used,buffer.readu16(packed,o+4));used+=2 end
  previous=ref
 end
 if used>=buffer.len(packed) then return Grid.compressChanges(packed)end
 local result=buffer.create(used);buffer.copy(result,0,out,0,used)
 return result,uniform,1
end
function Grid.expandWire(packed,uniform,maxCells,encoding)
 if encoding==nil then return if uniform~=nil then Grid.expandChanges(packed,uniform,maxCells)else packed end
 if encoding~=1 or typeof(packed)~="buffer" or buffer.len(packed)<4 then return nil end
 if uniform~=nil and (typeof(uniform)~="number" or uniform%1~=0 or uniform<0 or uniform>65535)then return nil end
 local length=buffer.len(packed);local maximum=math.min(maxCells,1+math.floor((length-4)/2))
 local result=buffer.create(maximum*6);local used=0;local offset=4;local ref=buffer.readu32(packed,0)
 while true do
  if ref<0 or ref>=maxCells or used>=maximum*6 then return nil end
  local value=uniform
  if value==nil then if offset+2>length then return nil end;value=buffer.readu16(packed,offset);offset+=2 end
  buffer.writeu32(result,used,ref);buffer.writeu16(result,used+4,value);used+=6
  if offset==length then break end
  if offset+2>length then return nil end
  local delta=buffer.readi16(packed,offset);offset+=2
  if delta==-32768 then if offset+4>length then return nil end;ref=buffer.readu32(packed,offset);offset+=4 else ref+=delta end
 end
 if used==buffer.len(result)then return result end
 local exact=buffer.create(used);buffer.copy(exact,0,result,0,used);return exact
end
function Grid.new(width: number, height: number, terrain: (number)->number, trackChanges: boolean?)
	assert(width>0 and height>0 and width%1==0 and height%1==0)
	local size=width*height
	local chunks,nonzero,counts,shared={},{},{},{}
 local offsets={};local dirtyPool={};local packed=buffer.create(1536);local used=0;local allocated=0
 local function record(ref,value)
  local key=bit32.rshift(ref,8);local page=offsets[key]
  if not page then page=table.remove(dirtyPool)or buffer.create(1024);offsets[key]=page end
  local index=bit32.band(ref,255)*4;local offset=buffer.readu32(page,index)
  if offset==0 then
   if used+6>buffer.len(packed) then local larger=buffer.create(buffer.len(packed)*2);buffer.copy(larger,0,packed,0,used);packed=larger end
   offset=used+1;buffer.writeu32(page,index,offset);buffer.writeu32(packed,used,ref);used+=6
  end
  buffer.writeu16(packed,offset+3,value)
 end
	local grid={Width=width,Height=height,Size=size,Counts=counts,FalloutCount=0}
 grid.compressChanges=Grid.compressChanges
 grid.compressWire=Grid.compressWire
	function grid.valid(ref): boolean
		return typeof(ref)=="number" and ref==ref and ref%1==0 and ref>=0 and ref<size
	end
	function grid.ref(x: number,y: number): number
		assert(x%1==0 and y%1==0 and x>=0 and x<width and y>=0 and y<height)
		return y*width+x
	end
	function grid.neighbors4Unchecked(ref: number, out: {number}): number
		local x=ref%width; local n=0
		if ref>=width then n+=1; out[n]=ref-width end
		if ref<(height-1)*width then n+=1; out[n]=ref+width end
		if x~=0 then n+=1; out[n]=ref-1 end
		if x~=width-1 then n+=1; out[n]=ref+1 end
		return n
	end
 function grid.neighbors4(ref: number,out: {number}): number
  assert(grid.valid(ref));return grid.neighbors4Unchecked(ref,out)
 end
	function grid.terrainByte(ref: number): number assert(grid.valid(ref)); return terrain(ref) end
	function grid.isLand(ref: number): boolean return bit32.band(grid.terrainByte(ref),128)~=0 end
	function grid.isImpassable(ref: number): boolean return grid.isLand(ref) and bit32.band(terrain(ref),31)==31 end
	function grid.terrainType(ref: number): string
		local b=grid.terrainByte(ref); local m=bit32.band(b,31)
		if bit32.band(b,128)==0 then return "Ocean" end
		return if m==31 then "Impassable" elseif m<10 then "Plains" elseif m<20 then "Highland" else "Mountain"
	end
	function grid.state(ref: number): number
		assert(grid.valid(ref)); local chunk=chunks[math.floor(ref/Grid.ChunkCells)]
		return if chunk then buffer.readu16(chunk,(ref%Grid.ChunkCells)*2) else 0
	end
 local function ownerAt(ref: number): number
  local chunk=chunks[bit32.rshift(ref,12)]
  return if chunk then bit32.band(buffer.readu16(chunk,bit32.band(ref,4095)*2),Grid.OwnerMask) else 0
 end
 function grid.ownerID(ref: number): number assert(grid.valid(ref));return ownerAt(ref) end
 -- Internal read-only access for packed traversal kernels. Never mutate this buffer.
 function grid.readStatePage(key) return chunks[key] end
 -- Stage 7: scan a complete horizontal owned run without repeated validation,
 -- division and table lookups per cell. Callers supply a validated owned seed.
 function grid.ownerRun(seed,owner)
  assert(grid.valid(seed) and grid.ownerID(seed)==owner and owner~=0)
  local row=seed-seed%width;local last=row+width-1
  local function walk(t,stop,step)
   while t~=stop do
    local key=math.floor(t/4096);local page=chunks[key]
    local edge=if step==1 then math.min(stop-1,key*4096+4095) else math.max(stop+1,key*4096)
    while (if step==1 then t<=edge else t>=edge) do
     if not page or bit32.band(buffer.readu16(page,(t%4096)*2),Grid.OwnerMask)~=owner then return t-step end
     t+=step
    end
   end
   return t-step
  end
  return walk(seed,row-1,-1),walk(seed,last+1,1)
 end
	local function writeState(ref: number, value: number, old: number)
		if old==value then return end
		local owner,previous=bit32.band(value,Grid.OwnerMask),bit32.band(old,Grid.OwnerMask)
		if owner~=0 then local byte=terrain(ref);assert(bit32.band(byte,128)~=0 and bit32.band(byte,31)~=31,"unclaimable terrain") end
  grid.FalloutCount+=(if bit32.band(value,Grid.FalloutBit)~=0 then 1 else 0)-(if bit32.band(old,Grid.FalloutBit)~=0 then 1 else 0)
		local key=math.floor(ref/Grid.ChunkCells)
		if not chunks[key] then chunks[key]=buffer.create(Grid.ChunkCells*2); nonzero[key]=0;allocated+=Grid.ChunkCells*2 end
  if shared[key] then
   local copy=buffer.create(Grid.ChunkCells*2);buffer.copy(copy,0,chunks[key]);chunks[key]=copy;shared[key]=nil
  end
		buffer.writeu16(chunks[key],(ref%Grid.ChunkCells)*2,value)
		if old==0 then nonzero[key]+=1 end
		if value==0 then nonzero[key]-=1 end
		if nonzero[key]==0 then chunks[key],nonzero[key]=nil,nil;allocated-=Grid.ChunkCells*2 end
		if previous~=owner then
			if previous~=0 then counts[previous]=(counts[previous] or 0)-1 end
			if owner~=0 then counts[owner]=(counts[owner] or 0)+1 end
		end
  if trackChanges~=false then
   record(ref,value)
  end
	end
 -- Internal kernels accept only validated, terrain-tested blast cells.
 grid.ownerUnchecked=ownerAt
 grid.terrainUnchecked=terrain
 function grid.applyFalloutBatch(tiles,onOwner,origin,readTerrain)
  local pages={};local fallout=0
  for _,tile in ipairs(tiles) do
   local ref=if origin then origin+tile else tile
   if readTerrain and bit32.band(readTerrain(ref),128)==0 then continue end
   local key=bit32.rshift(ref,12);local page=pages[key]
   if not page then page={Data=chunks[key],Added=0};pages[key]=page end
   local chunk=page.Data;local index=bit32.band(ref,4095)
   local old=if chunk then buffer.readu16(chunk,index*2) else 0
   local value=bit32.bor(bit32.band(old,0xf000),0x2000)
   if old==value then continue end
   local previous=bit32.band(old,4095)
   if bit32.band(old,0x2000)==0 then fallout+=1 end
   if not page.Writable then
    if not chunk then chunk=buffer.create(8192);chunks[key]=chunk;nonzero[key]=0;allocated+=8192
    elseif shared[key] then local copy=buffer.create(8192);buffer.copy(copy,0,chunk);chunk=copy;chunks[key]=chunk;shared[key]=nil end
    page.Data=chunk;page.Writable=true
   end
   buffer.writeu16(chunk,index*2,value)
   if old==0 then page.Added+=1 end
   if previous~=0 then counts[previous]-=1 end
   if trackChanges~=false then
    record(ref,value)
   end
   if previous~=0 then onOwner(previous,ref) end
  end
  grid.FalloutCount+=fallout
  for key,page in pairs(pages) do if page.Added>0 then nonzero[key]+=page.Added end end
 end
	function grid.setState(ref: number, value: number)
		assert(value%1==0 and value>=0 and value<=65535)
		writeState(ref,value,grid.state(ref))
	end
	function grid.setOwnerID(ref: number, owner: number)
		assert(owner%1==0 and owner>=0 and owner<=Grid.OwnerMask)
		local old=grid.state(ref)
		writeState(ref,bit32.bor(bit32.band(old,0xf000),owner),old)
	end
	function grid.isBorder(ref: number): boolean
  assert(grid.valid(ref));local owner=ownerAt(ref);local x=ref%width
  return (ref>=width and ownerAt(ref-width)~=owner)
   or (ref<(height-1)*width and ownerAt(ref+width)~=owner)
   or (x~=0 and ownerAt(ref-1)~=owner)
   or (x~=width-1 and ownerAt(ref+1)~=owner)
	end
	function grid.chunkKeys(): {number}
		local keys={}; for key in pairs(chunks) do table.insert(keys,key) end; table.sort(keys); return keys
	end
	function grid.copyChunk(key: number): buffer
		local b=buffer.create(Grid.ChunkCells*2); if chunks[key] then buffer.copy(b,0,chunks[key]) end; return b
	end
 -- Read-only page references. Future writes copy just the affected 8 KiB page.
 -- Multiple joins at the same tick can share this immutable snapshot in memory.
 function grid.snapshotPages()
  local pages={}
  for _,key in ipairs(grid.chunkKeys()) do shared[key]=true;table.insert(pages,{Key=key,Data=chunks[key]}) end
  return pages
 end
	function grid.loadChunk(key: number, data: buffer)
		assert(key%1==0 and key>=0 and key*Grid.ChunkCells<size and buffer.len(data)==Grid.ChunkCells*2)
  if trackChanges==false and not chunks[key] then
   local added={};local live=0;local fallout=0;local cells=math.min(Grid.ChunkCells,size-key*Grid.ChunkCells)
   for i=0,cells-1 do
    local value=buffer.readu16(data,i*2);local owner=bit32.band(value,Grid.OwnerMask)
    if value~=0 then live+=1 end
    if bit32.band(value,Grid.FalloutBit)~=0 then fallout+=1 end
    if owner~=0 then
     local byte=terrain(key*Grid.ChunkCells+i)
     assert(bit32.band(byte,128)~=0 and bit32.band(byte,31)~=31,"unclaimable snapshot terrain")
     added[owner]=(added[owner] or 0)+1
    end
   end
   if live>0 then
    local copy=buffer.create(Grid.ChunkCells*2);buffer.copy(copy,0,data,0,cells*2)
    chunks[key]=copy;nonzero[key]=live;allocated+=Grid.ChunkCells*2
    for owner,count in pairs(added) do counts[owner]=(counts[owner] or 0)+count end
    grid.FalloutCount+=fallout
   end
   return
  end
		for i=0,math.min(Grid.ChunkCells,size-key*Grid.ChunkCells)-1 do
			grid.setState(key*Grid.ChunkCells+i,buffer.readu16(data,i*2))
		end
	end
	function grid.release(owner: number,onRelease)
		assert(owner>0)
		for _,key in ipairs(grid.chunkKeys()) do
			for i=0,math.min(Grid.ChunkCells,size-key*Grid.ChunkCells)-1 do
				local ref=key*Grid.ChunkCells+i
				if grid.ownerID(ref)==owner then grid.setOwnerID(ref,0);if onRelease then onRelease(ref) end end
			end
		end
	end
 local function resetDirty()
  -- Reuse a bounded 4 MiB of scratch instead of allocating 16 KiB per touched
  -- world page on every tick. Packet reference order and coalescing are unchanged.
  for key,page in pairs(offsets)do
   if #dirtyPool<4096 then buffer.fill(page,0,0);table.insert(dirtyPool,page)end
   offsets[key]=nil
  end
  used=0
 end
	function grid.drain(): buffer
  local result=buffer.create(used);buffer.copy(result,0,packed,0,used)
  resetDirty()
  if buffer.len(packed)>393216 then packed=buffer.create(1536) end
  return result
	end
	function grid.discardChanges() resetDirty();if buffer.len(packed)>393216 then packed=buffer.create(1536) end end
	function grid.allocatedBytes(): number return allocated end
	return grid
end
return Grid
