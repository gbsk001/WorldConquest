--!strict
-- AStar.ts / PriorityQueue.BucketQueue / AStar.Rail and StationGraphAdapter.
-- Copyright OpenFront and Contributors. AGPL-3.0; pinned 8f1a0add.
-- Sparse per-search state replaces four world-sized typed arrays (512 MiB here).
local Path={}
function Path.search(start,goal,neighbors,cost,heuristic,maxPriority,preflight,slice)
 local closed,g,prev,buckets={},{[start]=0},{[start]=-1},{}
 local count,minBucket=0,maxPriority+1
 local function push(node,priority)
  local b=math.min(math.floor(priority),maxPriority);buckets[b]=buckets[b] or {};table.insert(buckets[b],node);count+=1;minBucket=math.min(minBucket,b)
 end
 push(start,heuristic(start,goal));local iterations=500000;local nb={}
 while count>0 do
  iterations-=1;if slice and iterations%64==0 then slice()end;if iterations<=0 then return nil end
  if iterations==498976 and preflight and not preflight() then return nil end
  while not buckets[minBucket] or #buckets[minBucket]==0 do minBucket+=1 end
  local current=table.remove(buckets[minBucket]);count-=1
  if closed[current] then continue end;closed[current]=true
  if current==goal then
   local path={};local t=goal;while t~=-1 do table.insert(path,t);t=prev[t] end
   for i=1,math.floor(#path/2) do path[i],path[#path-i+1]=path[#path-i+1],path[i] end;return path
  end
  local n=neighbors(current,nb)
  for i=1,n do local nextNode=nb[i]
   if closed[nextNode] then continue end
   local tentative=g[current]+cost(current,nextNode,if prev[current]==-1 then nil else prev[current])
   if g[nextNode]==nil or tentative<g[nextNode] then prev[nextNode]=current;g[nextNode]=tentative;push(nextNode,tentative+heuristic(nextNode,goal)) end
  end
 end
 return nil
end
function Path.land(grid,from,to,maxNodes,slice)
 local function shoreline(t)return bit32.band(grid.terrainByte(t),64)~=0 end
 local function heuristic(a,b)return 2*(math.abs(a%grid.Width-b%grid.Width)+math.abs(math.floor(a/grid.Width)-math.floor(b/grid.Width))) end
 local function neighbors(t,out)
  if grid.isImpassable(t) then return 0 end
  local n=grid.neighbors4(t,out);local count=0;local shore=shoreline(t)
  for i=1,n do local v=out[i];if grid.isLand(v) or shore or shoreline(v) then count+=1;out[count]=v end end;return count
 end
 -- Stage 7: necessary-condition reachability for the caller's existing length gate.
 -- Only reject when NO path short enough can exist. Successful searches still use
 -- the original A*, tie order, costs and iteration limit below.
 local function preflight()
  local gx,gy=to%grid.Width,math.floor(to/grid.Width)
  local function lower(t)return math.abs(t%grid.Width-gx)+math.abs(math.floor(t/grid.Width)-gy) end
  local queue,depth,seen,nb={from},{0},{[from]=true},{}
  local head=1;local found=false
  while head<=#queue do
   local t,d=queue[head],depth[head];head+=1;if slice and head%64==0 then slice()end
   if t==to then found=true;break end
   if d+lower(t)+1>=maxNodes then continue end
   local n=neighbors(t,nb)
   for i=1,n do local v=nb[i]
    if not seen[v] and d+1+lower(v)+1<maxNodes then
     seen[v]=true;table.insert(queue,v);table.insert(depth,d+1)
    end
   end
  end
  return found
 end
 return Path.search(from,to,neighbors,function(a,b,previous)
  return (if not grid.isLand(b) or shoreline(b) then 6 else 1)+(if previous and a-previous~=b-a then 3 else 0)
 end,heuristic,2*(grid.Width+grid.Height)*9,if maxNodes then preflight else nil,slice)
end
return Path
