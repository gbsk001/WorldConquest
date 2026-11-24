--!native
--!strict
-- Read-only compressed terrain, shared lazy bounded LRU decoded pages.
-- Clients default to 512 KiB; servers may retain all 32 MiB to avoid thrashing.
local Data = require(script.Parent.EarthTopologyData)
local Terrain={Width=Data.Width,Height=Data.Height,LandCount=Data.LandCount,MaskHash=Data.MaskHash,ElevationKnown=Data.ElevationKnown,ElevationHash=Data.ElevationHash}
local blocks,water=buffer.fromstring(Data.Blocks),buffer.fromstring(Data.WaterRuns)
local offsets,rows={},{}
local cursor=0
Terrain.NoImpassable=true
local decodeDeadline=os.clock()+.002
for key=0,Data.Width*Data.Height/4096-1 do
 if task and task.wait and key%128==0 and os.clock()>=decodeDeadline then task.wait();decodeDeadline=os.clock()+.002 end
	offsets[key]=cursor+4;local finish=cursor+4+buffer.readu32(blocks,cursor)
 if Terrain.NoImpassable then for pos=cursor+4,finish-1,3 do if bit32.band(buffer.readu8(blocks,pos+2),159)==159 then Terrain.NoImpassable=false;break end end end
 cursor=finish
end
assert(cursor==buffer.len(blocks))
cursor=0
for y=0,Data.Height-1 do rows[y]=cursor; cursor+=2+buffer.readu16(water,cursor)*8 end
assert(cursor==buffer.len(water))
local pages,previous,following={},{},{}
local allocated,capacity=0,128
local oldest,newest=nil,nil
local misses,evictions=0,0
local function unlink(key)
 local before,after=previous[key],following[key]
 if before~=nil then following[before]=after else oldest=after end
 if after~=nil then previous[after]=before else newest=before end
 previous[key],following[key]=nil,nil
end
local function evict()
 local key=oldest;unlink(key);pages[key]=nil;allocated-=1;evictions+=1
end
-- Client default remains 512 KiB. Stage 9 server opts into a bounded larger cache.
function Terrain.configureCache(count)
 assert(count%1==0 and count>=128 and count<=8192)
 capacity=count;while allocated>capacity do evict() end
end
function Terrain.cacheMetrics()return {Pages=allocated,Capacity=capacity,Misses=misses,Evictions=evictions}end
function Terrain.byte(ref: number): number
	assert(ref%1==0 and ref>=0 and ref<Data.Width*Data.Height)
	local key=math.floor(ref/4096)
	local page=pages[key]
	if not page then
        misses+=1
		if allocated>=capacity then evict() end
		page=buffer.create(4096); local pos=offsets[key]; local finish=pos+buffer.readu32(blocks,pos-4); local target=0
		while pos<finish do
			local length=buffer.readu16(blocks,pos)
			buffer.fill(page,target,buffer.readu8(blocks,pos+2),length); target+=length; pos+=3
		end
		assert(target==4096);pages[key]=page;allocated+=1
	elseif newest~=key then unlink(key) end
    if newest~=key then
     previous[key]=newest;if newest~=nil then following[newest]=key else oldest=key end;newest=key
    end
	return buffer.readu8(page,ref%4096)
end
function Terrain.waterComponent(ref: number): number?
	local x,y=ref%Data.Width,math.floor(ref/Data.Width)
	local row=rows[y]; if not row then return nil end
	local lo,hi=0,buffer.readu16(water,row)-1
	while lo<=hi do
		local mid=math.floor((lo+hi)/2); local pos=row+2+mid*8
		local first,length=buffer.readu16(water,pos),buffer.readu16(water,pos+2)
		if x<first then hi=mid-1 elseif x>=first+length then lo=mid+1 else return buffer.readu32(water,pos+4) end
	end
	return nil
end
function Terrain.cacheBytes(): number return allocated*4096 end
-- Immutable terrain pages may be shared by one route service across all ships.
-- Validate/decode once per page rather than touching the LRU for every A* edge.
function Terrain.readPage(key)
 Terrain.byte(key*4096)
 return pages[key]
end
-- A blast traverses a disk in BFS order, revisiting far more than the LRU's
-- 128 row pages. Decode each intersecting page once into a small immutable
-- window, so a hydrogen impact cannot thrash the global terrain cache.
function Terrain.region(x0,y0,x1,y1)
 assert(x0>=0 and y0>=0 and x1<Data.Width and y1<Data.Height and x1>=x0 and y1>=y0)
 local width=x1-x0+1;local data=buffer.create(width*(y1-y0+1))
 for y=y0,y1 do
  local x=x0
  while x<=x1 do
   local ref=y*Data.Width+x;Terrain.byte(ref)
   local offset=ref%4096;local count=math.min(4096-offset,x1-x+1)
   buffer.copy(data,(y-y0)*width+x-x0,pages[math.floor(ref/4096)],offset,count);x+=count
  end
 end
 return function(ref)return buffer.readu8(data,(math.floor(ref/Data.Width)-y0)*width+ref%Data.Width-x0) end
end
return Terrain
