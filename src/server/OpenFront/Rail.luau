--!strict
-- RailNetworkImpl, RailroadSpatialGrid, TrainStation, TrainStationExecution,
-- City/Factory/Port station creation and TrainExecution, OpenFront 8f1a0add.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE and NOTICE.
-- Rail/trains are server data, not Roblox Parts. Car motion is cosmetic and not instantiated.
local Path = require(script.Parent.RailPath)
local Rules = require(game:GetService("ReplicatedStorage").Shared.OpenFront.RailRules)
local Random = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Random32)
local Economy = require(script.Parent.Economy)
local Gold = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Gold)
local Rail={}
local function remove(list,item)local i=table.find(list,item);if i then table.remove(list,i) end end
local function add(list,item)if not table.find(list,item) then table.insert(list,item) end end
local function tradeStation(s)return s.Unit.Type=="City" or s.Unit.Type=="Port" end
function Rail.new(sim)
 local grid=sim.Grid;local b=sim.Buildings
 local api={Stations={},Rails={},Trains={},TrainUnits=0,Version=0,NextStation=1,NextRail=0}
 local function schedule(execution)
  local init,tick=execution.init,execution.tick
  execution.init=function()local began=os.clock();init();sim.Work.RailMilliseconds=(sim.Work.RailMilliseconds or 0)+(os.clock()-began)*1000 end
  execution.tick=function()local began=os.clock();tick();sim.Work.RailMilliseconds=(sim.Work.RailMilliseconds or 0)+(os.clock()-began)*1000 end
  sim.Executions.add(execution)
 end
 local connectQueue={};local connectJob=nil;local connectBudget=0
 local routeCache={};local routeOrder={}
 local function pathSlice()
  connectBudget-=64;if connectBudget<=0 then coroutine.yield()end
 end
 local function landRoute(from,to)
  -- Terrain is immutable for a match. Direction remains part of the key to
  -- preserve A* tie-breaking. Only geometry is cached, never trade eligibility.
  local key=tostring(from)..":"..to;local cached=routeCache[key]
  if cached~=nil then return if cached then table.clone(cached)else nil end
  local route=Path.land(grid,from,to,110*1.4142,if sim.Balance and sim.Balance.BoundedPaths then pathSlice else nil)
  if #routeOrder>=256 then routeCache[table.remove(routeOrder,1)]=nil end
  table.insert(routeOrder,key);routeCache[key]=if route then table.clone(route)else false
  return route
 end
 local stationOrder,byUnit,railCells,railKeys,dirtyClusters={},{},{},{},{}
 local function mark()api.Version+=1 end
 local function cellKey(x,y)return tostring(x)..":"..tostring(y) end
 local function unregister(r)
  for _,key in ipairs(railKeys[r] or {}) do remove(railCells[key],r);if #railCells[key]==0 then railCells[key]=nil end end;railKeys[r]=nil
 end
 local function register(r)
  unregister(r);local keys={}
  for _,t in ipairs(r.Tiles) do
   local key=cellKey(math.floor(t%grid.Width/4),math.floor(math.floor(t/grid.Width)/4))
   if not table.find(keys,key) then table.insert(keys,key);railCells[key]=railCells[key] or {};table.insert(railCells[key],r) end
  end
  railKeys[r]=keys
 end
 local function railsNear(tile)
  local result={};local x,y=tile%grid.Width,math.floor(tile/grid.Width)
  for cx=math.floor((x-3)/4),math.floor((x+3)/4) do for cy=math.floor((y-3)/4),math.floor((y+3)/4) do
   for _,r in ipairs(railCells[cellKey(cx,cy)] or {}) do add(result,r) end
  end end;return result
 end
 local function other(r,s)return if r.From==s then r.To else r.From end
 local function unlink(r)
  remove(r.From.Rails,r);remove(r.To.Rails,r);r.From.Neighbor[other(r,r.From)]=nil;r.To.Neighbor[other(r,r.To)]=nil
  unregister(r);api.Rails[r.ID]=nil;mark()
 end
 local function link(a,c,tiles,registerNow)
  local r={ID=api.NextRail,From=a,To=c,Tiles=tiles};api.NextRail+=1;api.Rails[r.ID]=r
  table.insert(a.Rails,r);table.insert(c.Rails,r);a.Neighbor[c]=r;c.Neighbor[a]=r
  if registerNow~=false then register(r) end;mark();return r
 end
 local function clusterAdd(cluster,s)
  if s.Cluster and s.Cluster~=cluster then remove(s.Cluster.Stations,s);remove(s.Cluster.Trade,s) end
  add(cluster.Stations,s);if tradeStation(s) then add(cluster.Trade,s) end;s.Cluster=cluster
 end
 local function merge(clusters)
  if #clusters<=1 then return end
  local merged={Stations={},Trade={}}
  for _,c in ipairs(clusters) do for _,s in ipairs(table.clone(c.Stations)) do clusterAdd(merged,s) end end
 end
 local function reachable(start,hops)
  local seen={[start]=true};local list={start};local frontier={start}
  for _=1,hops do
   if #frontier==0 then break end;local nextFront={}
   for _,s in ipairs(frontier) do for _,r in ipairs(s.Rails) do local v=other(r,s)
    if not seen[v] then seen[v]=true;table.insert(list,v);table.insert(nextFront,v) end
   end end;frontier=nextFront
  end;return seen,list
 end
 function api.recompute()
  for _,c in ipairs(dirtyClusters) do
   local remaining=table.clone(c.Stations)
   while #remaining>0 do
    local _,connected=reachable(remaining[1],#stationOrder)
    for _,s in ipairs(connected) do remove(remaining,s) end
    if #remaining>0 then local nc={Stations={},Trade={}};for _,s in ipairs(connected) do clusterAdd(nc,s) end end
   end
  end;dirtyClusters={}
 end
 function api.removeUnit(unit)
  local s=byUnit[unit];if not s then return end
  for _,r in ipairs(table.clone(s.Rails)) do unlink(r) end
  api.Stations[s.ID]=nil;remove(stationOrder,s);byUnit[unit]=nil
  for _,v in ipairs(stationOrder) do if v.Unit==unit then byUnit[unit]=v;break end end
  unit.HasStation=false
  local c=s.Cluster;if c then remove(c.Stations,s);remove(c.Trade,s);if #c.Stations>0 then add(dirtyClusters,c) else remove(dirtyClusters,c) end end
  mark()
 end
 local function nearby(tile,types)
  local list=b.nearby(tile,110,nil,nil,false);local filtered={}
  for _,u in ipairs(list) do if table.find(types,u.Type) then table.insert(filtered,u) end end
  -- UnitGrid's 100-cell row-major buckets, requested type order, insertion order.
  table.sort(filtered,function(a,c)
   local ay,cy=math.floor(math.floor(a.Tile/grid.Width)/100),math.floor(math.floor(c.Tile/grid.Width)/100)
   if ay~=cy then return ay<cy end
   local ax,cx=math.floor(a.Tile%grid.Width/100),math.floor(c.Tile%grid.Width/100);if ax~=cx then return ax<cx end
   local at,ct=table.find(types,a.Type),table.find(types,c.Type);if at~=ct then return at<ct end;return a.ID<c.ID
  end);return filtered
 end
 local function connect(s)
  api.Stations[s.ID]=s;table.insert(stationOrder,s);if not byUnit[s.Unit] then byUnit[s.Unit]=s end
  local edited={}
  for _,r in ipairs(railsNear(s.Unit.Tile)) do
   local closest,dist=1,math.huge
   for i,t in ipairs(r.Tiles) do local d=b.distance(t,s.Unit.Tile);if d<dist then dist=d;closest=i end end
   if closest==1 or closest>#r.Tiles then continue end
   local from,to=r.From,r.To;local a,c={},{}
   for i,t in ipairs(r.Tiles) do table.insert(if i<closest then a else c,t) end
   unlink(r);local first=link(from,s,a,false);local second=link(s,to,c,false);register(second);register(first)
   if from.Cluster then clusterAdd(from.Cluster,s);add(edited,from.Cluster) end
  end
  if #edited>0 then merge(edited);return end
  local candidates={}
  for index,u in ipairs(nearby(s.Unit.Tile,{"City","Factory","Port"})) do
   local n=byUnit[u];if u~=s.Unit and n and n.Cluster then table.insert(candidates,{Station=n,Distance=b.distance(u.Tile,s.Unit.Tile),Order=index}) end
  end
  table.sort(candidates,function(a,c)return a.Distance<c.Distance or (a.Distance==c.Distance and a.Order<c.Order) end)
  local seen=reachable(s,4)
  for _,v in ipairs(candidates) do
   if seen[v.Station] or v.Distance<=225 then continue end
   local path=landRoute(s.Unit.Tile,v.Station.Unit.Tile)
   if s.Unit.Active and v.Station.Unit.Active and api.Stations[v.Station.ID]==v.Station and v.Station.Cluster and path and #path>0 and #path<110*1.4142 then
    link(s,v.Station,path);local c=v.Station.Cluster;clusterAdd(c,s);add(edited,c);seen=reachable(s,4)
   end
  end
  if #edited==0 then clusterAdd({Stations={},Trade={}},s) else merge(edited) end
  if not s.Unit.Active then api.removeUnit(s.Unit)end
 end
 function api.stationPath(from,to)
  if from.Cluster~=to.Cluster then return nil end
  local ids=Path.search(from.ID,to.ID,function(id,out)
   local s=api.Stations[id];if not s then return 0 end
   for i,r in ipairs(s.Rails) do out[i]=other(r,s).ID end;return #s.Rails
  end,function()return 1 end,function(a,c)
   local x,y=api.Stations[a],api.Stations[c];if not x or not y then return 0 end
   local t,u=x.Unit.Tile,y.Unit.Tile;return math.abs(t%grid.Width-u%grid.Width)+math.abs(math.floor(t/grid.Width)-math.floor(u/grid.Width))
  end,grid.Width+grid.Height)
  if not ids then return nil end;local result={};for _,id in ipairs(ids) do table.insert(result,api.Stations[id]) end;return result
 end
 local function oriented(a,c)
  local r=a.Neighbor[c];if not r then return nil end
  if r.To==c then return r.Tiles end
  local tiles={};for i=#r.Tiles,1,-1 do table.insert(tiles,r.Tiles[i]) end;return tiles
 end
 local function canTrade(p,s)
  local owner=s.Unit.Owner
  if sim.Naval then return owner==p or sim.Naval.canTrade(p,owner) end
  return owner==p or not ((p.Embargoes and p.Embargoes[owner.UserId]) or (owner.Embargoes and owner.Embargoes[p.UserId]))
 end
 local function recordMotion(u,path)
  if not (sim.Balance and sim.Balance.InfrastructurePresentation)then return end
  local history=u.Motion or {};local previous=history[#history];local a,c=nil,nil
  for i,t in ipairs(path)do if t==previous then a=i end;if t==u.Tile then c=i end end
  if a and c then
   local direction=if c>=a then 1 else -1
   for i=a+direction,c,direction do table.insert(history,path[i])end
  elseif previous~=u.Tile then table.insert(history,u.Tile)end
  while #history>25 do table.remove(history,1)end;u.Motion=history
 end
 function api.launch(p,from,to)
  local active=true;local train=nil;local stations=nil;local tiles=nil
  local current,pathIndex,stops=0,0,0;local pathTiles={}
  local traversed={}
  local function saveTraversed(from,speed)
   if sim.Stage<8 then return end
   for i=from,math.min(from+speed-1,#tiles-1) do
    local tile=if i<0 then pathTiles[i+pathIndex+1] else tiles[i+1]
    table.insert(traversed,tile);if #traversed>15 then table.remove(traversed,1) end
   end
  end
  local function destroy()
   if not active then return end
   active=false
   if train then api.Trains[train.ID]=nil;api.TrainUnits-=1;for _,car in ipairs(train.Cars) do if car.Active then car.Active=false;api.TrainUnits-=1 end end end
  end
  local function stop(station)
   if not tradeStation(station) then return end
   local owner=station.Unit.Owner
   local relationship=if owner==p then "self" elseif p.Team~=nil and p.Team==owner.Team then "team" elseif p.Allies and p.Allies[owner.UserId] then "ally" else "other"
   local gold=Gold.from(Rules.gold(relationship,stops,sim.Economy.multiplier(p)))
   if owner~=p then Economy.add(owner,gold);Economy.recordTrade(owner,gold,"Rail",sim.Tick,station.Unit);owner.TrainGold=Gold.add(owner.TrainGold or "0",gold) end
   Economy.add(p,gold);Economy.recordTrade(p,gold,"Rail",sim.Tick,from.Unit);p.TrainGold=Gold.add(p.TrainGold or "0",gold);stops+=1
  end
  local function splitPath()
   local path=api.stationPath(stations[1],stations[2]);if not path or #path<=2 then return nil end
   local segments={};local cursor=pathIndex
   for i=1,#path-1 do
    local segment=oriented(path[i],path[i+1]);if not segment then return nil end;table.insert(segments,segment)
    for _,t in ipairs(segment) do cursor+=1;if pathTiles[cursor]~=t then return nil end end
   end
   return path,segments,cursor
  end
  local function replaceFirst(path,start)
   local out={};for i=start or 1,#path do table.insert(out,path[i]) end
   for i=3,#stations do table.insert(out,stations[i]) end;stations=out
  end
  schedule({activeDuringSpawnPhase=function()return false end,isActive=function()return active end,
   init=function()
    stations=api.stationPath(from,to)
    if not stations or #stations<=1 then active=false;return end
    tiles=oriented(stations[1],stations[2]);if not tiles or not grid.isLand(from.Unit.Tile) or grid.isImpassable(from.Unit.Tile) or (grid.Counts[p.SmallId] or 0)==0 then active=false;return end
    train={ID=b.nextID(),Owner=p,Tile=from.Unit.Tile,Destroy=destroy,Cars={}}
    for _=1,6 do table.insert(train.Cars,{ID=b.nextID(),Tile=from.Unit.Tile,Active=true}) end
    api.Trains[train.ID]=train;api.TrainUnits+=7
    for i=1,#stations-1 do local seg=oriented(stations[i],stations[i+1]);if not seg then destroy();return end;for _,t in ipairs(seg) do table.insert(pathTiles,t) end end
    if #pathTiles==0 or pathTiles[1]~=train.Tile then table.insert(pathTiles,1,train.Tile);pathIndex=1;current=-1 end
   end,
   tick=function()
    if not tiles or #stations<2 then destroy();return end
    if not stations[1].Neighbor[stations[2]] then
     local path,segments,cursor=splitPath()
     if path and cursor==pathIndex+#tiles then
      local activeSegment,segmentStart,boundary=1,0,0
      for i=1,#segments-1 do
       boundary+=#segments[i]
       local before,after=tiles[boundary],tiles[boundary+1]
       local stopIndex=if b.distance(before,path[i+1].Unit.Tile)<=b.distance(after,path[i+1].Unit.Tile) then boundary-1 else boundary
       if current<=stopIndex then break end;activeSegment=i+1;segmentStart=boundary
      end
      pathIndex+=segmentStart;current-=segmentStart;tiles=segments[activeSegment];replaceFirst(path,activeSegment)
     end
    end
    if not stations[1].Unit.Active or not stations[2].Unit.Active or not canTrade(p,stations[2]) then destroy();return end
    saveTraversed(current,2);current+=2;local leftover=current-#tiles
    if leftover>=0 then
     stop(stations[2])
     if #stations<=2 then destroy();return end
     pathIndex+=#tiles;table.remove(stations,1)
     local nextTiles=oriented(stations[1],stations[2])
     if not nextTiles then local path,segments=splitPath();if path then replaceFirst(path);nextTiles=segments[1] end end
     if not nextTiles then destroy();return end
     tiles=nextTiles;current=leftover;saveTraversed(0,leftover)
    end
    local nextTile=tiles[current+1];if not nextTile or nextTile==0 then destroy();return end;train.Tile=nextTile
    if sim.Stage>=8 then for i=6,1,-1 do local index=i*2+3;if #traversed>=index then train.Cars[i].Tile=traversed[index] end end end
    if sim.Balance and sim.Balance.InfrastructurePresentation then
     local motionPath=table.clone(traversed);table.insert(motionPath,train.Tile)
     recordMotion(train,motionPath);for _,car in ipairs(train.Cars)do recordMotion(car,motionPath)end
    end
   end})
 end
 local function addStation(unit,spawnTrains)
  unit.HasStation=true
  local active=true;local station=nil;local random=nil;local lastSpawn=0
  schedule({activeDuringSpawnPhase=function()return false end,isActive=function()return active end,
   init=function()if spawnTrains then random=Random.new(sim.Tick) end end,
   tick=function()
    if not station then
     station={ID=api.NextStation,Unit=unit,Rails={},Neighbor={}};api.NextStation+=1;if sim.Balance and sim.Balance.BoundedPaths then table.insert(connectQueue,station)else connect(station)end
    end
    if not unit.Active then active=false;return end
    if not spawnTrains or sim.Tick<lastSpawn+10 or not station.Cluster then return end
    local eligible={};for _,s in ipairs(station.Cluster.Trade) do if canTrade(unit.Owner,s) then table.insert(eligible,s) end end
    if #eligible==0 then return end
    local levels=unit.Owner.BuildingOwned.Factory or 0
    local rate=Rules.spawnRate(levels,api.TrainUnits);local spawn=false
    for _=1,unit.Level do if random.nextInt(0,rate)==0 then spawn=true;break end end
    if not spawn then return end
    local destination=nil
    for i,s in ipairs(eligible) do if random.nextInt(0,i)==0 then destination=s end end
    if not destination or destination==station then return end
    api.launch(unit.Owner,station,destination);lastSpawn=sim.Tick
   end})
 end
 function api.completed(unit)
  if unit.Type~="City" and unit.Type~="Factory" and unit.Type~="Port" then return end
  local first=true;local active=true
  schedule({activeDuringSpawnPhase=function()return false end,isActive=function()return active end,init=function()end,
   tick=function()
    if unit.Type=="Port" and not unit.Active then active=false;return end
    if first or (unit.Type=="Port" and not unit.HasStation) then
     first=false
     if unit.Type=="Factory" then
      local structures=nearby(unit.Tile,{"City","Port","Factory"});addStation(unit,true)
      for _,u in ipairs(structures) do if not u.HasStation then addStation(u,false) end end
     elseif #nearby(unit.Tile,{"Factory"})>0 then addStation(unit,false) end
    end
    if not unit.Active then active=false end
   end})
 end
 function api.invalidateGeometry()mark()end
 function api.geometry()
  local rows={}
  for id,r in pairs(api.Rails)do
   local turns={};local last=nil
   for i,t in ipairs(r.Tiles)do
    local direction=if i<#r.Tiles then r.Tiles[i+1]-t else nil
    if i==1 or i==#r.Tiles or direction~=last then table.insert(turns,t)end
    last=direction
   end
   local packed=buffer.create(#turns*4);for i,t in ipairs(turns)do buffer.writeu32(packed,(i-1)*4,t)end
   table.insert(rows,{ID=id,Owner=r.From.Unit.Owner.SmallId,Points=packed})
  end
  table.sort(rows,function(a,b)return a.ID<b.ID end);return rows
 end
 function api.snapshot()
  local out={}
  local function row(u,kind,owner)
   local packed=nil
   if u.Motion then packed=buffer.create(#u.Motion*4);for i,tile in ipairs(u.Motion)do buffer.writeu32(packed,(i-1)*4,tile)end end
   return {ID="rail"..u.ID,Type=kind,Owner=owner,Tile=u.Tile,Flags=0,Motion=packed,MotionTick=sim.Tick}
  end
  for _,t in pairs(api.Trains)do
   table.insert(out,row(t,"Train",t.Owner.SmallId))
   for _,car in ipairs(t.Cars)do if car.Active then table.insert(out,row(car,"Carriage",t.Owner.SmallId))end end
  end
  table.sort(out,function(a,b)return a.ID<b.ID end);return out
 end
 function api.summary(p)
  local stations,trains=0,0
  for _,s in ipairs(stationOrder) do if s.Unit.Owner==p and s.Unit.Active then stations+=1 end end
  for _,t in pairs(api.Trains) do if t.Owner==p then trains+=1 end end
  local routes=0
  for _,r in pairs(api.Rails)do
   local c=r.From.Cluster;local factory=false
   if c and #c.Trade>0 then for _,s in ipairs(c.Stations)do if s.Unit.Active and s.Unit.Type=="Factory"and s.Unit.Owner==p then factory=true;break end end end
   if factory and r.From.Unit.Active and r.To.Unit.Active and canTrade(p,r.From)and canTrade(p,r.To)then routes+=1 end
  end
  return {Stations=stations,Trains=trains,Routes=routes,Gold=p.TrainGold or "0"}
 end
 function api.removePlayer(p)
  local removeTrains={};for _,t in pairs(api.Trains) do if t.Owner==p then table.insert(removeTrains,t) end end
  for _,t in ipairs(removeTrains) do t.Destroy() end
 end
 schedule({activeDuringSpawnPhase=function()return false end,isActive=function()return true end,init=function()end,tick=function()
  api.recompute()
  if not connectJob and #connectQueue>0 then local s=table.remove(connectQueue,1);connectJob=coroutine.create(function()if s.Unit.Active then connect(s)end end)end
  if connectJob then
   connectBudget=512;local ok,err=coroutine.resume(connectJob);assert(ok,err)
   if coroutine.status(connectJob)=="dead"then connectJob=nil end
  end
 end})
 return api
end
return Rail
