--!strict
-- SpatialQuery translated from OpenFront 8f1a0add. Copyright OpenFront and Contributors; AGPL-3.0.
local Shore={}
function Shore.new(grid,path)
 local api={};local caches=setmetatable({},{__mode="k"})
 local function shore(t)return grid.isLand(t) and bit32.band(grid.terrainByte(t),64)~=0 end
 local function cache(p)
  local c=caches[p];if not c or c.Version~=(p.TileVersion or 0) or c.Count>=4096 then
   c={Version=p.TileVersion or 0,Components={},Shores={},Launches={},Count=0};caches[p]=c
   p.Border.each(function(t)if shore(t) then local component=path.component(t);if component then c.Components[component]=true;table.insert(c.Shores,t) end end end)
  end;return c
 end
 function api.target(p,tile)
  local c=cache(p);if not next(c.Components) then return nil end
  local owner=grid.ownerID(tile);local best=nil;local distance=math.huge;local stack,visited,nb={},{},{}
  local function mark(t)
   visited[t]=true;table.insert(stack,t)
   if shore(t) and grid.ownerID(t)==owner and c.Components[path.component(t)] then
    local d=path.distance(t,tile);if d<distance then best=t;distance=d end
   end
  end
  mark(tile);if distance==0 then return best end
  while #stack>0 do local t=table.remove(stack)
   for i=1,grid.neighbors4(t,nb) do local n=nb[i];if not visited[n] and path.distance(n,tile)<=50 then mark(n) end end
   if distance<=1 then break end
  end;return best
 end
 function api.launch(p,tile)
  local c=cache(p);if c.Launches[tile]~=nil then return c.Launches[tile] or nil end
  local component=path.component(tile);local candidates={}
  if component and (not grid.isLand(tile) or shore(tile)) then for _,t in ipairs(c.Shores) do if path.component(t)==component then table.insert(candidates,t) end end end
  local route=if #candidates>0 then path.route(candidates,tile,false) else nil
  local result=if route then route[1] else nil
  if route and #route>50 then
   local near={};local minX,maxX,minY,maxY=math.huge,-1,math.huge,-1
   for _,t in ipairs(candidates) do if path.distance(t,result)<=20 then
    table.insert(near,t);local x,y=t%grid.Width,math.floor(t/grid.Width);minX=math.min(minX,x);maxX=math.max(maxX,x);minY=math.min(minY,y);maxY=math.max(maxY,y)
   end end
   if #near>1 then
    local function bounds(t,clamp)
     local x,y=t%grid.Width,math.floor(t/grid.Width);local b={math.min(minX,x)-10,math.max(maxX,x)+10,math.min(minY,y)-10,math.max(maxY,y)+10}
     if clamp then b={math.max(0,b[1]),math.min(grid.Width-1,b[2]),math.max(0,b[3]),math.min(grid.Height-1,b[4])} end;return b
    end
    local lo,hi,best=50,math.min(200,#route-1),50
    for _=1,5 do if lo>hi then break end;local mid=math.floor((lo+hi)/2);local b=bounds(route[mid+1],false)
     if (b[2]-b[1]+1)*(b[4]-b[3]+1)<=10000 then best=mid;lo=mid+1 else hi=mid-1 end
    end
    local b=bounds(route[best+1],true)
    if (b[2]-b[1]+1)*(b[4]-b[3]+1)<=10000 then local refined=path.raw(near,route[best+1],b);if refined then result=refined[1] end end
   end
  end
  c.Launches[tile]=result or false;c.Count+=1;return result
 end
 return api
end
return Shore
