--!native
--!strict
-- AStar.Water, ShoreCoercingTransformer, PathFinderStepper and AirPathFinder.
-- Copyright OpenFront and Contributors. AGPL-3.0; pinned 8f1a0add.
-- Roblox adaptation: sparse full-resolution searches; no 2x/HPA minimap pipeline.
local Heap = require(game:GetService("ReplicatedStorage").Shared.OpenFront.MinHeap)
local Random = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Random32)
local Path={}
function Path.new(grid,terrain)
 local api={Searches=0,Hits=0,CacheBytes=0,Pops=0,SearchMilliseconds=0}
 local cache={};local serial=0;local limit=24000000;local entries=0
 local terrainPages={}
 local function terrainAt(ref)
  if not terrain.readPage then return grid.terrainUnchecked(ref)end
  local key=bit32.rshift(ref,12);local page=terrainPages[key]
  if not page then page=terrain.readPage(key);terrainPages[key]=page end
  return buffer.readu8(page,bit32.band(ref,4095))
 end
 local function distance(a,b)return math.abs(a%grid.Width-b%grid.Width)+math.abs(math.floor(a/grid.Width)-math.floor(b/grid.Width)) end
 api.distance=distance
 function api.component(tile)
  if not grid.valid(tile) then return nil end
  if terrain.waterComponent then
   local c=terrain.waterComponent(tile);if c then return c end
   local nb={};for i=1,grid.neighbors4(tile,nb) do c=terrain.waterComponent(nb[i]);if c then return c end end
  end
  return nil
 end
 function api.hasComponent(tile,c)
  if not c then return false end
  if api.component(tile)==c then return true end
  local nb={};for i=1,grid.neighbors4(tile,nb) do if not grid.isLand(nb[i]) and api.component(nb[i])==c then return true end end;return false
 end
 function api.raw(starts,goal,bounds)
  local began=os.clock();api.Searches+=1
  local heap=Heap.new();local closed,g,prev={},{},{};local nb={};local f=buffer.create(4)
  local readTerrain=terrainAt;local width,height=grid.Width,grid.Height
  local enqueue=heap.enqueueUnchecked or heap.enqueue
  local gx,gy=goal%grid.Width,math.floor(goal/grid.Width)
  local dx,dy=gx-starts[1]%grid.Width,gy-math.floor(starts[1]/grid.Width);local norm=math.max(1,math.abs(dx)+math.abs(dy))
  local weight=if bounds then 3 else 5
  local function push(t,cost,tie)
   local x,y=t%grid.Width,math.floor(t/grid.Width)
   local cross=if tie then math.floor(math.abs(dx*(y-gy)-dy*(x-gx))*99/norm/norm) else 0
   -- PriorityQueue.MinHeap rounds to Float32 before comparing, unlike FlatBinaryHeap.
   buffer.writef32(f,0,cost+weight*100*(math.abs(x-gx)+math.abs(y-gy))+cross)
   enqueue(t,buffer.readf32(f,0))
  end
  for _,t in ipairs(starts) do g[t]=0;prev[t]=-1;push(t,0,false) end
  local remaining=if bounds then 100000 else 1000000;local found=nil
  while heap.size()>0 do
   remaining-=1;if remaining<=0 then break end
   local t=heap.dequeue();api.Pops+=1;if closed[t] then continue end;closed[t]=true
   if t==goal then
    found={};while t~=-1 do table.insert(found,t);t=prev[t] end
    for i=1,math.floor(#found/2) do found[i],found[#found-i+1]=found[#found-i+1],found[i] end;break
   end
   local x0=t%width;local ncount=0
   if t>=width then ncount+=1;nb[ncount]=t-width end
   if t<(height-1)*width then ncount+=1;nb[ncount]=t+width end
   if x0>0 then ncount+=1;nb[ncount]=t-1 end
   if x0<width-1 then ncount+=1;nb[ncount]=t+1 end
   for i=1,ncount do local n=nb[i];local x,y=n%width,math.floor(n/width)
    if bounds and (x<bounds[1] or x>bounds[2] or y<bounds[3] or y>bounds[4]) then continue end
    if closed[n] then continue end
    local byte=readTerrain(n)
    if n==goal or bit32.band(byte,128)==0 then
     local mag=bit32.band(byte,31);local cost=g[t]+100+(if mag<3 then (if bounds then 300 else 1000) elseif mag<=10 then 0 else 100)
     if not g[n] or cost<g[n] then g[n]=cost;prev[n]=t;push(n,cost,true) end
    end
   end
  end
  api.SearchMilliseconds+=(os.clock()-began)*1000;return found
 end
 local function bestWater(t)
  local best,score=nil,-1;local nb,inner={},{}
  for i=1,grid.neighbors4(t,nb) do local n=nb[i]
   if not grid.isLand(n) then local count=0;for j=1,grid.neighbors4(n,inner) do if not grid.isLand(inner[j]) then count+=1 end end
    if count>score then score=count;best=n end
   end
  end;return best
 end
 function api.route(from,to,memo)
  local starts=if typeof(from)=="table" then from else {from}
  if #starts==0 or not grid.valid(to) then return nil end
  for _,t in ipairs(starts) do if not grid.valid(t) then return nil end end
  local key=if memo and #starts==1 then starts[1]..":"..to else nil
  serial+=1
  if key and cache[key] then api.Hits+=1;cache[key].Stamp=serial;local b=cache[key].Data;if b==false then return nil end
   local list={};for o=0,buffer.len(b)-1,4 do table.insert(list,buffer.readu32(b,o)) end;return list
  end
  local waterStarts,original={},{};local goal=if grid.isLand(to) then bestWater(to) else to
  if not goal then return nil end
  local component=api.component(goal)
  for _,t in ipairs(starts) do local water=if grid.isLand(t) then bestWater(t) else t
   if water and (not component or not terrain.waterComponent or api.component(water)==component) then
    table.insert(waterStarts,water);original[water]=if water==t then nil else t
   end
  end
  local result=nil
  if #waterStarts>0 then result=api.raw(waterStarts,goal) end
  if result then
   if original[result[1]] then table.insert(result,1,original[result[1]]) end
   if goal~=to and result[#result]~=to then table.insert(result,to) end
  end
  if key then
   local bytes=64+(if result then #result*4 else 0)
   if bytes<=limit then
    while api.CacheBytes+bytes>limit or entries>=4096 do
     local victim,oldest=nil,math.huge;for k,v in pairs(cache) do if v.Stamp<oldest then oldest=v.Stamp;victim=k end end
     api.CacheBytes-=cache[victim].Bytes;cache[victim]=nil;entries-=1
    end
    local packed=false;if result then packed=buffer.create(#result*4);for i,t in ipairs(result) do buffer.writeu32(packed,(i-1)*4,t) end end
    cache[key]={Data=packed,Bytes=bytes,Stamp=serial};api.CacheBytes+=bytes;entries+=1
   end
  end;return result
 end
 function api.stepper(memo,airSeed)
  local destination=nil;local path=nil;local index=1
  local function find(from,to)
   if airSeed==nil then return api.route(from,to,memo) end
   local rng=Random.new(airSeed);local list={from};local t=from
   while t~=to do
    local x,y=t%grid.Width,math.floor(t/grid.Width);local tx,ty=to%grid.Width,math.floor(to/grid.Width)
    if x==tx then y+=if y<ty then 1 else -1
    elseif y==ty then x+=if x<tx then 1 else -1
    elseif rng.nextInt(0,math.floor(1+math.abs(ty-y)/(math.abs(tx-x)+1)))==0 then x+=if x<tx then 1 else -1
    else y+=if y<ty then 1 else -1 end
    t=y*grid.Width+x;table.insert(list,t)
   end;return list
  end
  local step={}
  function step.next(from,to,dist)
   if not grid.valid(from) or not grid.valid(to) then return "NOT_FOUND" end
   if from==to then return "COMPLETE",to end
   if dist and dist>0 and airSeed==nil and distance(from,to)<=dist then return "COMPLETE",from end
   if destination~=to then path=nil;index=1;destination=to end
   if not path then
    local list=find(from,to);if not list then return "NOT_FOUND" end
    path=buffer.create(#list*4);for i,t in ipairs(list) do buffer.writeu32(path,(i-1)*4,t) end
    index=if list[1]==from then 2 else 1
   end
   if index>1 and buffer.readu32(path,(index-2)*4)~=from then path=nil;return step.next(from,to,dist) end
   if index>buffer.len(path)/4 then return "COMPLETE",to end
   local t=buffer.readu32(path,(index-1)*4);index+=1;return "NEXT",t
  end
  return step
 end
 return api
end
return Path

