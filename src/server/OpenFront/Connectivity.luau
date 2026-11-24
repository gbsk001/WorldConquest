--!native
--!strict
-- PlayerExecution.ts connectivity, revision 8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE/NOTICE.
-- Modified 2026-11-18: Luau, 1-based lists and shared sparse u32 scratch pages.
local Connectivity={}
local function sparse()
 local pages={};local bytes=0
 local function fill(first,last,value)
  for key=math.floor(first/256),math.floor(last/256) do
   local page=pages[key];if not page then page=buffer.create(1024);pages[key]=page;bytes+=1024 end
   for offset=math.max(first-key*256,0)*4,math.min(last-key*256,255)*4,4 do buffer.writeu32(page,offset,value) end
  end
 end
 return setmetatable({}, {
  __index=function(_,t) local page=pages[math.floor(t/256)];return if page then buffer.readu32(page,(t%256)*4) else 0 end,
  __newindex=function(_,t,value)
   local key=math.floor(t/256);local page=pages[key]
   if not page then if value==0 then return end;page=buffer.create(1024);pages[key]=page;bytes+=1024 end
   buffer.writeu32(page,(t%256)*4,value)
  end,
 }),function() table.clear(pages);bytes=0 end,function()return bytes end,fill,pages
end
function Connectivity.new(sim,p)
 local map=sim.Grid;local w,h=map.Width,map.Height;local mine=p.SmallId
 if not sim.Traversal then
  local visited,clear,bytes,fill,pages=sparse();local index,_,indexBytes=sparse()
  sim.Traversal={visited=visited,pages=pages,fill=fill,clear=clear,bytes=function()return bytes()+indexBytes()end,index=index,stack={},gen=0}
 end
 local state=sim.Traversal;local visited,stack=state.visited,state.stack
 local nb,nb8={},{};local api={};local territoryIds=nil;local nextTerritoryId=1
 local function alive()return (map.Counts[mine] or 0)>0 end
 local function x(t)return t%w end
 local function y(t)return math.floor(t/w) end
 local function edge(t)return x(t)==0 or x(t)==w-1 or t<w or t>=(h-1)*w end
 local function fallout(t)return bit32.band(map.state(t),0x2000)~=0 end
 local function shore(t)return bit32.band(map.terrainUnchecked(t),0x40)~=0 end
 local coastNeighbors={}
 local function oceanShore(t)
  if not map.isLand(t) then return false end
  local n=map.neighbors4Unchecked(t,coastNeighbors)
  for i=1,n do if bit32.band(map.terrainUnchecked(coastNeighbors[i]),0x20)~=0 then return true end end
  return false
 end
 local function bump()
  state.gen+=1;if state.gen==0xffffffff then state.clear();state.gen=1 end;return state.gen
 end
 local function bumps(count)
  local first=bump();local last=first;for _=2,count do last=bump() end
  return if last-first==count-1 then first else bumps(count)
 end
 local function neighbors8(t,out)
  local n=0;local xx=x(t);local north=t>=w;local south=t<(h-1)*w
  if xx~=0 then if north then n+=1;out[n]=t-1-w end;n+=1;out[n]=t-1;if south then n+=1;out[n]=t-1+w end end
  if north then n+=1;out[n]=t-w end;if south then n+=1;out[n]=t+w end
  if xx~=w-1 then if north then n+=1;out[n]=t+1-w end;n+=1;out[n]=t+1;if south then n+=1;out[n]=t+1+w end end
  return n
 end
 local function box()return {1e9,1e9,-1e9,-1e9} end
 local function bound(b,t)local xx,yy=x(t),y(t);b[1]=math.min(b[1],xx);b[2]=math.min(b[2],yy);b[3]=math.max(b[3],xx);b[4]=math.max(b[4],yy) end
 local function contains(a,b)return a[1]<=b[1] and a[2]<=b[2] and a[3]>=b[3] and a[4]>=b[4] end
 local function flood(gen,starts,diag,include,outbox)
  local result={};table.clear(stack)
  local function mark(t)visited[t]=gen;table.insert(result,t);table.insert(stack,t);if outbox then bound(outbox,t) end end
  for _,t in ipairs(starts) do if visited[t]~=gen and include(t) then mark(t) end end
  local out=if diag then nb8 else nb
  while #stack>0 do
   local t=table.remove(stack);local n=if diag then neighbors8(t,out) else map.neighbors4Unchecked(t,out)
   for i=1,n do local v=out[i];if visited[v]~=gen and include(v) then mark(v) end end
  end
  return result
 end
 function api.calculateClusters()
  local clusters,boxes={},{};if p.Border.Size==0 then return clusters,boxes end
  local borderGen=bumps(2);local current=borderGen+1
  p.Border.each(function(t)visited[t]=borderGen end)
  p.Border.each(function(t)
   if visited[t]==current then return end
   local b=box();local c=flood(current,{t},true,function(v)return visited[v]==borderGen end,b)
   table.insert(clusters,c);table.insert(boxes,b)
  end)
  return clusters,boxes
 end
 function api.hasDiagonalPinch(cluster)
  for _,t in ipairs(cluster) do
   if map.ownerUnchecked(t)~=mine or t>=(h-1)*w or map.ownerUnchecked(t+w)==mine then continue end
   local xx=x(t)
   if (xx<w-1 and map.ownerUnchecked(t+w+1)==mine and map.ownerUnchecked(t+1)~=mine)
    or (xx>0 and map.ownerUnchecked(t+w-1)==mine and map.ownerUnchecked(t-1)~=mine) then return true end
  end;return false
 end
 local function seedSpan(from,to,owner,gen)
  local inRun,met=false,false
  for key=math.floor(from/256),math.floor(to/256) do
   local marks=state.pages[key];local owned=map.readStatePage(math.floor(key/16));local base=key*256
   for offset=math.max(from-base,0),math.min(to-base,255) do
    local stamp=if marks then buffer.readu32(marks,offset*4) else 0
    local value=if owned then buffer.readu16(owned,((base+offset)%4096)*2) else 0
    if stamp<gen and bit32.band(value,0xfff)==owner then
     if not inRun then table.insert(stack,base+offset);inRun=true end
    else inRun=false;met=met or bit32.band(value,0x2000)~=0 end
   end
  end;return met
 end
 local function floodComponent(start,tGen,areaGen,id,falls)
  table.clear(stack);table.insert(stack,start);local met=false;local size=0
  while #stack>0 do
   local seed=table.remove(stack);if visited[seed]>=areaGen then continue end
   local row=seed-seed%w;local last=row+w-1;local l,r=map.ownerRun(seed,mine)
   state.fill(l,r,tGen);size+=r-l+1
   met=met or (l>row and fallout(l-1)) or (r<last and fallout(r+1))
   if row>0 then met=seedSpan(l-w,r-w,mine,areaGen) or met end
   if row<(h-1)*w then met=seedSpan(l+w,r+w,mine,areaGen) or met end
  end
  falls[id]=met;return size
 end
 function api.floodTerritoryAreas(clusters)
  local sizes,ids,areas,falls={},{},{[0]=0},{[0]=false};local maximum=0
  local areaGen=bumps(#clusters*4+16);local nextID=1
  for i,cluster in ipairs(clusters) do
   local tileIds={};ids[i]=tileIds;local largest=0
   for j,t in ipairs(cluster) do
    tileIds[j]=0
    if visited[t]>=areaGen then
     local id=visited[t]-areaGen+1;tileIds[j]=id;largest=math.max(largest,areas[id]);continue
    end
    if map.ownerUnchecked(t)~=mine then continue end
    local id=nextID;nextID+=1;tileIds[j]=id;local gen=areaGen+id-1
    while state.gen<gen and state.gen>=areaGen do bump() end
    local size=floodComponent(t,gen,areaGen,id,falls);areas[id]=size;largest=math.max(largest,size)
   end
   sizes[i]=largest;maximum=math.max(maximum,largest)
  end
  return {sizes=sizes,ids=ids,areas=areas,falls=falls,maximum=maximum}
 end
 local function largestCluster(clusters,boxes,sizes)
  local largest=1
  for i=2,#clusters do
   if sizes[i]>sizes[largest] then largest=i
   elseif sizes[i]==sizes[largest] then
    local a,b=boxes[i],boxes[largest];local area=(a[3]-a[1]+1)*(a[4]-a[2]+1);local best=(b[3]-b[1]+1)*(b[4]-b[2]+1)
    if area>best or (area==best and #clusters[i]>#clusters[largest]) then largest=i end
   end
  end;return largest
 end
 function api.isEnclosed(start,b)
  local gen=bump();table.clear(stack);visited[start]=gen;table.insert(stack,start)
  while #stack>0 do
   local t=table.remove(stack);local xx,yy=x(t),y(t)
   if xx<b[1]-1 or xx>b[3]+1 or yy<b[2]-1 or yy>b[4]+1 or edge(t) then return false end
   local n=map.neighbors4Unchecked(t,nb)
   for i=1,n do
    local v=nb[i];if visited[v]==gen then continue end
    local owner=map.ownerUnchecked(v)
    if owner==mine then visited[v]=gen;table.insert(stack,v)
    elseif owner==0 and (not map.isLand(v) or not fallout(v)) then return false end
   end
  end;return true
 end
 function api.getCapturingPlayer(cluster)
  local counts,ordered={},{}
  for _,t in ipairs(cluster) do
   local n=map.neighbors4Unchecked(t,nb)
   for i=1,n do
    local id=map.ownerUnchecked(nb[i]);if id==0 or id==mine then continue end
    local owner=sim.owner(id)
    if not sim.friendly(owner,p) then
     if counts[owner]==nil then counts[owner]=0;table.insert(ordered,owner) end
     counts[owner]+=1
    end
   end
  end
  local winner=nil;local troops=0
  for _,owner in ipairs(ordered) do for _,attack in ipairs(owner.Outgoing) do
   if attack.Target==p and attack.Troops>troops then troops=attack.Troops;winner=owner end
  end end
  if winner then return winner end
  local count=0;for _,owner in ipairs(ordered) do if counts[owner]>count then count=counts[owner];winner=owner end end
  return winner
 end
 local function transfer(owner,tiles)
  if (map.Counts[mine] or 0)==#tiles then sim.conquerPlayer(owner,p) end
  for _,t in ipairs(tiles) do sim.conquer(owner,t);sim.Work.Claims+=1 end
 end
 local function markRejected(start,gen,b)
  table.clear(stack);visited[start]=gen;table.insert(stack,start)
  while #stack>0 do
   local t=table.remove(stack);local n=map.neighbors4Unchecked(t,nb)
   for i=1,n do
    local v=nb[i];if visited[v]==gen or map.ownerUnchecked(v)~=mine then continue end
    local xx,yy=x(v),y(v)
    if xx>=b[1]-1 and xx<=b[3]+1 and yy>=b[2]-1 and yy<=b[4]+1 then visited[v]=gen;table.insert(stack,v) end
   end
  end
 end
 local function removeCluster(cluster,b,known,pinched)
  for _,t in ipairs(cluster) do if map.ownerUnchecked(t)~=mine then return false end end
  if #cluster==0 then return false end
  if not pinched then
   local captor=known or api.getCapturingPlayer(cluster);if not captor or not api.isEnclosed(cluster[1],b) then return false end
   transfer(captor,flood(bump(),{cluster[1]},false,function(t)return map.ownerUnchecked(t)==mine end));return true
  end
  local gen=bump();local removed=false
  for _,t in ipairs(cluster) do
   if not alive() then break end
   if visited[t]==gen or map.ownerUnchecked(t)~=mine then continue end
   if not api.isEnclosed(t,b) then markRejected(t,gen,b);continue end
   local tiles=flood(gen,{t},false,function(v)return map.ownerUnchecked(v)==mine end)
   if #tiles>0 then local captor=known or api.getCapturingPlayer(tiles);if captor then removed=true;transfer(captor,tiles) end end
  end;return removed
 end
 local function surrounded(cluster,b,sovereign)
  local enemy=0;local has=false;local bounds=box()
  for _,t in ipairs(cluster) do
   if edge(t) or (if sovereign then oceanShore(t) else shore(t)) then return nil end
   local n=map.neighbors4Unchecked(t,nb)
   for i=1,n do
    local v=nb[i];local id=map.ownerUnchecked(v)
    if id==mine then continue end
    if sovereign then
     if id==0 then return nil end
     if enemy==0 then enemy=id elseif enemy~=id then return nil end
     bound(bounds,v)
    elseif id~=0 then has=true;bound(bounds,v)
    elseif fallout(v) then bound(bounds,v) else return nil end
   end
  end
  if contains(bounds,b) then
   if sovereign then return if enemy~=0 then sim.owner(enemy) else nil end
   if has then return true end
  end;return nil
 end
 local function assignTerritory(clusters,a,b)
  if territoryIds[a]~=-1 and territoryIds[a]==territoryIds[b] then return end
  if territoryIds[a]~=-1 and territoryIds[b]~=-1 then return end
  local index=if territoryIds[b]==-1 then b else a
  local id=nextTerritoryId;nextTerritoryId+=1
  local gen=bump();table.clear(stack);local start=clusters[index][1]
  if not start or map.ownerUnchecked(start)~=mine then return end
  territoryIds[index]=id;table.insert(stack,start)
  while #stack>0 do
   local seed=table.remove(stack);if visited[seed]>=gen then continue end
   local row=seed-seed%w;local last=row+w-1;local l,r=seed,seed
   while l>row and visited[l-1]<gen and map.ownerUnchecked(l-1)==mine do l-=1 end
   while r<last and visited[r+1]<gen and map.ownerUnchecked(r+1)==mine do r+=1 end
   for t=l,r do visited[t]=gen;local c=state.index[t];if c>0 then territoryIds[c]=id end end
   local from,to=if l>row then l-1 else l,if r<last then r+1 else r
   if row>0 then seedSpan(from-w,to-w,mine,gen) end
   if row<(h-1)*w then seedSpan(from+w,to+w,mine,gen) end
  end
 end
 local function isHole(i,clusters,boxes)
  for j=1,#clusters do
   if j~=i and contains(boxes[j],boxes[i]) then
    if not territoryIds then
     territoryIds={};for c,cluster in ipairs(clusters) do territoryIds[c]=-1;for _,t in ipairs(cluster) do state.index[t]=c end end
    end
    assignTerritory(clusters,i,j)
    if territoryIds[i]~=-1 and territoryIds[i]==territoryIds[j] then return true end
   end
  end;return false
 end
 local function evaluatePinch(cluster,areas,tileIds)
  if not alive() then return end
  local gen=bump()
  for j,start in ipairs(cluster) do
   if not alive() then break end
   local id=tileIds and tileIds[j]
   if id and id~=0 and (areas.areas[id]>=areas.maximum or not areas.falls[id]) then continue end
   if state.gen<gen then gen=bump() end
   if map.ownerUnchecked(start)~=mine or visited[start]>=gen then continue end
   local met=false;visited[start]=gen;table.clear(stack);table.insert(stack,start)
   local tiles={start};local b=box();bound(b,start)
   while #stack>0 do
    local t=table.remove(stack);bound(b,t);local n=map.neighbors4Unchecked(t,nb)
    for k=1,n do local v=nb[k];met=met or fallout(v)
     if visited[v]<gen and map.ownerUnchecked(v)==mine then visited[v]=gen;table.insert(tiles,v);table.insert(stack,v) end
    end
   end
   if #tiles>=areas.maximum or not met then continue end
   if api.isEnclosed(start,b) then local captor=api.getCapturingPlayer(tiles);if captor then transfer(captor,tiles) end end
  end
 end
 function api.removeClusters()
  local clusters,boxes=api.calculateClusters()
  if #clusters==0 then p.LargestClusterBoundingBox=nil;return end
  local pinched={};for i,c in ipairs(clusters) do pinched[i]=api.hasDiagonalPinch(c) end
  local areas=if #clusters>1 or pinched[1] then api.floodTerritoryAreas(clusters) else nil
  local largest=if areas then largestCluster(clusters,boxes,areas.sizes) else 1
  p.LargestClusterBoundingBox=boxes[largest]
  local removed={};local captor=surrounded(clusters[largest],boxes[largest],true)
  if captor and not sim.friendly(captor,p) then removed[largest]=removeCluster(clusters[largest],boxes[largest],captor,pinched[largest]) end
  for i,c in ipairs(clusters) do
   if not alive() then break end
   if i~=largest and surrounded(c,boxes[i],false) then removed[i]=removeCluster(c,boxes[i],nil,pinched[i]) end
  end
  territoryIds=nil;nextTerritoryId=1
  for i,c in ipairs(clusters) do
   if not alive() then break end
   if removed[i] or not pinched[i] or isHole(i,clusters,boxes) then continue end
   evaluatePinch(c,areas or {maximum=0},if areas then areas.ids[i] else nil)
  end
  if territoryIds then for _,c in ipairs(clusters) do for _,t in ipairs(c) do state.index[t]=0 end end end
  territoryIds=nil;nextTerritoryId=1
 end
 return api
end
return Connectivity
