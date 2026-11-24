--!strict
-- NukeExecution, MIRVExecution, SAMLauncher/ SAMMissile/ MissileSiloExecution.
-- Copyright OpenFront and Contributors. AGPL-3.0; pinned 8f1a0add, modified 2026-11-20.
-- Default fallout rules; optional terrain-changing water nukes are not enabled.
local Rules = require(game:GetService("ReplicatedStorage").Shared.OpenFront.MissileRules)
local Path = require(game:GetService("ReplicatedStorage").Shared.OpenFront.MissilePath)
local Random = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Random32)
local Troops = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Troops)
local Gold = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Gold)
local Spawn = require(script.Parent.SpawnExecution)
local Missiles={}
function Missiles.new(sim)
 local grid,nav,b=sim.Grid,sim.Naval,sim.Buildings
 local api={MIRVsLaunched=0,Impacts=0,Interceptions=0}
 local nuclear={"AtomBomb","HydrogenBomb","MIRVWarhead"}
 local function schedule(tick,alive,init)
  local function run(f)local began=os.clock();f();sim.Work.MissileMilliseconds=(sim.Work.MissileMilliseconds or 0)+(os.clock()-began)*1000 end
  sim.Executions.add({activeDuringSpawnPhase=function()return false end,isActive=alive,init=function()if init then run(init) end end,tick=function()run(tick)end})
 end
 local function notify(p,message)if sim.TransactionResults and sim.Players[p.UserId]==p then table.insert(sim.TransactionResults,{UserId=p.UserId,Message=message}) end end
 local function sameTeam(a,c)return a.Team~=nil and a.Team==c.Team end
 local function breakAlliance(a,c)
  if a.Allies then a.Allies[c.UserId]=nil end;if c.Allies then c.Allies[a.UserId]=nil end
 end
 local function betray(p,dst,kind)
  if kind=="MIRVWarhead" then return end
  if kind=="MIRV" then local q=sim.owner(grid.ownerID(dst));if q then breakAlliance(p,q) end;return end
  local inner,outer=Rules.magnitude(kind);local counts={};local x,y=dst%grid.Width,math.floor(dst/grid.Width)
  for yy=math.max(0,y-outer),math.min(grid.Height-1,y+outer) do for xx=math.max(0,x-outer),math.min(grid.Width-1,x+outer) do
   local d=(x-xx)^2+(y-yy)^2
   if d<=outer*outer then local id=grid.ownerID(yy*grid.Width+xx);if id>0 then counts[id]=(counts[id] or 0)+(if d<=inner*inner then 1 else .5) end end
  end end
  for _,u in ipairs(b.nearby(dst,outer,nil,nil,true)) do counts[u.Owner.SmallId]=101 end
  for id,count in pairs(counts) do if count>100 then local q=sim.owner(id);if q then breakAlliance(p,q) end end end
 end
 function api.price(p,kind)return if sim.Economy.isFree(p) then "0" else Rules.cost(kind,api.MIRVsLaunched) end
 function api.source(p,kind,tile)
  if not table.find(Rules.Types,kind) or not grid.valid(tile) or grid.isImpassable(tile) or sim.Tick-(sim.StartTick or 0)<50 then return nil end
  local q=sim.owner(grid.ownerID(tile));if kind=="MIRV" and not q then return nil end
  if q and sameTeam(p,q) then return nil end
  if p.Team and kind~="MIRV" then local _,outer=Rules.magnitude(kind)
   for _,u in ipairs(b.nearby(tile,outer,nil,nil,true)) do if sameTeam(p,u.Owner) then return nil end end
  end
  local best,distance=nil,math.huge
  for _,u in ipairs(p.BuildingUnits) do
   if u.Type=="MissileSilo" and u.Active and not u.UnderConstruction and #(u.MissileQueue or {})<u.Level then
    local d=nav.Path.distance(u.Tile,tile);if d<distance then best=u;distance=d end
   end
  end;return best
 end
 for _,kind in ipairs(Rules.Types) do local product=kind
  sim.Economy.register("Missile:"..product,function(p)return api.price(p,product) end,function(p,_,c)
   if typeof(c)~="table" then return false end;c.Silo=api.source(p,product,c.Tile);return c.Silo~=nil
  end)
 end
 local function exactBlast(dst,kind,tick,readTerrain)
  local inner,outer=Rules.magnitude(kind);local rng=Random.new(tick)
  local queue,seen,nb={dst},{[dst]=true},{};local head=1
  if bit32.band(readTerrain(dst),159)==159 then return {} end
  while head<=#queue do local t=queue[head];head+=1
   for i=1,grid.neighbors4(t,nb) do local v=nb[i]
    if not seen[v] then
     local d=b.distance(dst,v)
     -- Failed fringe candidates may be tested again from a different neighbour.
     if d<=outer*outer and (d<=inner*inner or rng.nextInt(0,2)==0) and bit32.band(readTerrain(v),159)~=159 then seen[v]=true;table.insert(queue,v) end
    end
   end
  end;return queue
 end
 -- A simultaneous salvo shares RNG/geometry. On default fallout terrain never
 -- changes. A passable footprint is translation invariant; if ANY selected
 -- cell is impassable, use the original terrain-sensitive BFS instead. Failed
 -- fringe candidates consume RNG before terrain filtering in upstream too.
 local geometryTick=-1;local geometry={};local stencils={}
 function api.blastTiles(dst,kind,tick,forImpact)
  if geometryTick~=tick then geometryTick=tick;geometry={} end
  local inner,r=Rules.magnitude(kind);local x,y=dst%grid.Width,math.floor(dst/grid.Width)
  local left,right,top,bottom=math.min(r,x),math.min(r,grid.Width-1-x),math.min(r,y),math.min(r,grid.Height-1-y)
  local readTerrain=if sim.Terrain and sim.Terrain.region then sim.Terrain.region(x-left,y-top,x+right,y+bottom) else grid.terrainUnchecked
  local key=kind..':'..left..':'..right..':'..top..':'..bottom
  local shape=geometry[key]
  if not shape then
   local stride=2*r+1;local center=r*stride+r;local queue={center};local seen=buffer.create(stride*stride);buffer.writeu8(seen,center,1)
   local stencil=stencils[kind]
   if not stencil then
    stencil=buffer.create(stride*stride)
    for yy=-r,r do for xx=-r,r do local d=xx*xx+yy*yy;buffer.writeu8(stencil,(yy+r)*stride+xx+r,if d<=inner*inner then 2 elseif d<=r*r then 1 else 0) end end
    stencils[kind]=stencil
   end
   local rng=Random.new(tick);local head=1;shape={}
   local function visit(v)
    if buffer.readu8(seen,v)~=0 then return end
    local class=buffer.readu8(stencil,v)
    if class==2 or class==1 and rng.next()<.5 then buffer.writeu8(seen,v,1);table.insert(queue,v) end
   end
   while head<=#queue do
    local v=queue[head];head+=1;local dx,dy=v%stride-r,math.floor(v/stride)-r;table.insert(shape,dy*grid.Width+dx)
    if dy>-top then visit(v-stride) end;if dy<bottom then visit(v+stride) end
    if dx>-left then visit(v-1) end;if dx<right then visit(v+1) end
   end
   local borders={}
   for i,v in ipairs(queue) do
    local dx,dy=v%stride-r,math.floor(v/stride)-r;local mask=0
    if dx*dx+dy*dy<=(inner-1)*(inner-1) then continue end
    if dy==-r or buffer.readu8(seen,v-stride)==0 then mask+=1 end
    if dy==r or buffer.readu8(seen,v+stride)==0 then mask+=2 end
    if dx==-r or buffer.readu8(seen,v-1)==0 then mask+=4 end
    if dx==r or buffer.readu8(seen,v+1)==0 then mask+=8 end
    if mask~=0 then borders[shape[i]]=mask end
   end
   shape.Borders=borders
   geometry[key]=shape
  end
  if forImpact and sim.Terrain and sim.Terrain.NoImpassable then return shape,nil,shape.Borders,readTerrain end
  local result=if forImpact then nil else table.create(#shape);local land={}
  for i,offset in ipairs(shape) do
   local t=dst+offset;local byte=readTerrain(t)
   if bit32.band(byte,159)==159 then
    local exact=exactBlast(dst,kind,tick,readTerrain);local landExact={}
    for _,v in ipairs(exact) do if bit32.band(readTerrain(v),128)~=0 then table.insert(landExact,v) end end
    return exact,landExact
   end
   if result then result[i]=t end
   if bit32.band(byte,128)~=0 then table.insert(land,t) end
  end
  return result,land,shape.Borders
 end
 function api.detonate(u)
  local dst,kind=u.TargetTile,u.Type;local _,outer=Rules.magnitude(kind)
  local affected,order,released,byOwner={},{},{},{}
  local shape,land,borders,readTerrain=api.blastTiles(dst,kind,sim.Tick,true)
  grid.applyFalloutBatch(land or shape,function(id,t)
   local mask=if borders then borders[t-dst] or 0 else 15
   if mask~=0 then table.insert(released,t);table.insert(released,mask) end
   local cells=byOwner[id]
   if not cells then local p=sim.owner(id);cells={};byOwner[id]=cells;affected[p]=cells;table.insert(order,p)end
   table.insert(cells,t)
  end,if readTerrain then dst else nil,readTerrain)
  -- No execution observes a partially applied impact. Update only surviving
  -- neighbours after all removals, preserving first surviving insertion order.
  for _,p in ipairs(order) do sim.falloutOwner(p,affected[p]) end
  for i=1,#released,2 do sim.falloutBorders(released[i],released[i+1]) end
  for _,p in ipairs(order) do
   local count=grid.Counts[p.SmallId] or 0;local cap=Troops.cap(count,p.CityLevels or 0,p.Kind,p.Difficulty)
   local transports={};for _,ship in ipairs(p.Ships) do if ship.Type=="TransportShip" then table.insert(transports,ship) end end
   p.Troops=Rules.damageStack(kind,p.Troops,#affected[p],count,cap,true)
   for _,attack in ipairs(p.Outgoing) do attack.Troops=Rules.damageStack(kind,attack.Troops,#affected[p],count,cap,false) end
   for _,ship in ipairs(transports) do ship.Troops=Rules.damageStack(kind,ship.Troops,#affected[p],count,cap,false) end
   for _,ship in ipairs(transports) do nav.touch(ship) end
   if count==0 then p.Eliminated=true;sim.MetadataDirty=true;if sim.ProgressionElimination then sim.ProgressionElimination(u.Owner,p)end end
   notify(p,kind.." impact from "..u.Owner.Username..": "..#affected[p].." land cells lost.")
  end
  for _,unit in ipairs(b.nearby(dst,outer,nil,nil,true)) do if b.distance(dst,unit.Tile)<outer*outer then b.destroy(unit) end end
  for _,unit in ipairs(nav.nearby(dst,outer,{"TransportShip","Warship","TradeShip","Shell"})) do if b.distance(dst,unit.Tile)<outer*outer then nav.delete(unit) end end
  local trains={};for _,train in pairs(sim.Rail.Trains) do table.insert(trains,train) end
  table.sort(trains,function(a,c)return a.ID<c.ID end)
  for _,train in ipairs(trains) do
   if b.distance(dst,train.Tile)<outer*outer then train.Destroy()
   else for _,car in ipairs(train.Cars) do if car.Active and b.distance(dst,car.Tile)<outer*outer then car.Active=false;sim.Rail.TrainUnits-=1 end end end
  end
  api.Impacts+=1
  if sim.PresentationImpact then sim.PresentationImpact(u.Owner,dst)end
  nav.delete(u)
 end
 function api.fly(p,kind,src,dst,speed,wait)
  local route=Path.route(grid,src,dst,speed or 10)
  local u=nav.create(p,kind,src,{TargetTile=dst,Trajectory=route,Index=1,Wait=wait or 0})
  betray(p,dst,kind)
  local target=sim.owner(grid.ownerID(dst));if target and kind~="MIRVWarhead" then notify(target,kind.." inbound from "..p.Username..".") end
  schedule(function()
   if u.Wait>0 then u.Wait-=1;return end
   u.Index+=1
   if u.Index>=#route then
    u.Index=#route;nav.move(u,dst)
    for _,sam in ipairs(nav.nearby(dst,12,{"SAMMissile"})) do if sam.TargetUnit==u and sam.Owner~=p then return end end
    api.detonate(u)
   else nav.move(u,route[u.Index]) end
  end,function()return u.Active end)
  return u
 end
 function api.mirv(p,src,dst,initTick)
  local rng=Random.new((initTick or sim.Tick)+Spawn.simpleHash(tostring(p.UserId)));local target=grid.ownerID(dst)
  local x,y=dst%grid.Width,math.floor(dst/grid.Width)
  local separate=grid.ref(math.floor((x+src%grid.Width)/2),math.min(grid.Height-1,math.max(0,y-500)+50))
  local speed=Path.mirvSpeed(grid,src,separate);local path=Path.route(grid,src,separate,speed)
  local u=nav.create(p,"MIRV",src,{TargetTile=dst});api.MIRVsLaunched+=1;betray(p,dst,"MIRV")
  local q=sim.owner(target);if q then notify(q,"MIRV inbound from "..p.Username..".") end
  local targets={dst};local cells={};local failures=0;local spawned=false;local separated=false;local index=2;local children={}
  local function key(t)return math.floor((t%grid.Width-x+1500)/55),math.floor((math.floor(t/grid.Width)-y+1500)/55) end
  local function add(t)local cx,cy=key(t);local k=cy*57+cx;cells[k]=cells[k] or {};table.insert(cells[k],t) end;add(dst)
  local function attempt()
   if failures>=1500 then return end
   for _=1,100 do
    local r=rng.next();local xx=math.max(0,x-1500)+math.floor(r*(math.min(grid.Width-1,x+1500)-math.max(0,x-1500)+1))
    local yy=math.max(0,y-1500)+math.floor((r*15485863%1)*(math.min(grid.Height-1,y+1500)-math.max(0,y-1500)+1))
    if (xx-x)^2+(yy-y)^2>2250000 then continue end
    local t=yy*grid.Width+xx;if grid.ownerID(t)~=target or not grid.isLand(t) or grid.isImpassable(t) then continue end
    local cx,cy=key(t);local overlap=#(cells[cy*57+cx] or {})>=2
    for gy=math.max(0,cy-1),math.min(56,cy+1) do for gx=math.max(0,cx-1),math.min(56,cx+1) do
     for _,v in ipairs(cells[gy*57+gx] or {}) do if nav.Path.distance(t,v)<55 then overlap=true end end
    end end
    if overlap then failures+=1;if failures>=1500 then return end
    else failures=0;table.insert(targets,t);add(t);return end
   end
  end
  local function fill(n)for _=1,n do if #targets>=350 or failures>=1500 then break end;attempt() end end
  local function tick()
   local remaining=#path-index -- excludes source and endpoint, like upstream fullPath.
   if remaining<=20 and remaining>10 then fill(100) end
   if remaining<=10 and not spawned then
    spawned=true;local retained={}
    for _,t in ipairs(targets) do if t==dst or grid.ownerID(t)==target then table.insert(retained,t) end end
    if #retained<#targets then failures=0 end;targets=retained;cells={};for _,t in ipairs(targets) do add(t) end
    fill(500+(10-remaining)*50)
    local decorated={};for i,t in ipairs(targets) do table.insert(decorated,{Tile=t,Order=i,Distance=nav.Path.distance(t,dst)}) end
    table.sort(decorated,function(a,c)return a.Distance>c.Distance or a.Distance==c.Distance and a.Order<c.Order end)
    for i,v in ipairs(decorated) do
     local delay=math.max(0,remaining)+rng.nextInt(0,15);local destination=v.Tile;local extra=math.min(4,math.floor((i-1)/70));local active=true
     schedule(function()if u.Active or separated then table.insert(children,api.fly(p,"MIRVWarhead",separate,destination,22+extra,delay)) end;active=false end,function()return active end)
    end
   end
   if index<#path then nav.move(u,path[index]);index+=1 else separated=true;nav.delete(u) end
  end
  schedule(tick,function()
   if not u.Active and not separated then for _,child in ipairs(children) do if child.Active then nav.delete(child) end end end
   return u.Active
  end)
  -- MIRV moves on its creation tick, unlike Atom/Hydrogen.
  tick();return u
 end
 function api.order(p,e)
  local active=true;local initTick=sim.Tick
  schedule(function()
   local context={Tile=e.Tile};local receipt,fresh=sim.Economy.purchase(p,e.Sequence,"Missile:"..tostring(e.Type),context)
   notify(p,if receipt.OK then (if fresh then e.Type.." launched." else "Launch already processed; no second charge.") else "Missile order rejected: "..tostring(receipt.Reason))
   if fresh and receipt.OK then
    local silo=context.Silo;silo.MissileQueue=silo.MissileQueue or {};local last=0
    for _,tick in ipairs(silo.MissileQueue) do last=math.max(tick+1,last+1) end
    if e.Type=="MIRV" then api.mirv(p,silo.Tile,e.Tile,initTick) else api.fly(p,e.Type,silo.Tile,e.Tile,10,math.max(0,last-sim.Tick)) end
    table.insert(silo.MissileQueue,sim.Tick)
   end;active=false
  end,function()return active end,function()initTick=sim.Tick end)
 end
 function api.upgrade(unit)
  if unit.Type~="MissileSilo" and unit.Type~="SAMLauncher" then return end
  unit.MissileQueue=unit.MissileQueue or {};table.insert(unit.MissileQueue,sim.Tick)
  if unit.Type=="SAMLauncher" then unit.SAMUpgrade={Tick=sim.Tick,Range=Rules.dynamicRange(unit,sim.Tick)};unit.SAMCache={} end
 end
 local function interception(sam,u)
  local route=u.Trajectory;local minimum=math.huge;local last=-1;local increasing=0
  for i=u.Index,#route-1 do
   local tile=route[i];local d=b.distance(sam.Tile,tile);minimum=math.min(minimum,d)
   increasing=if last~=-1 and d>last then increasing+1 else 0;last=d
   local ticks=i-u.Index+u.Wait;local samTicks=math.ceil(nav.Path.distance(sam.Tile,tile)/12)
   local range=Rules.dynamicRange(sam,sim.Tick+ticks)
   if d<=range*range and ticks>=samTicks and (b.distance(tile,route[1])<22500 or b.distance(tile,route[#route])<22500) then return ticks-samTicks,tile end
   if increasing>3 and d>22500 then break end
  end
  local expTicks=#route-u.Index+u.Wait;local range=Rules.dynamicRange(sam,sim.Tick+expTicks)
  if #route>=2 and b.distance(sam.Tile,route[#route])<=range*range then
   local tile=route[#route-1];local ticks=#route-1-u.Index+u.Wait-math.ceil(nav.Path.distance(sam.Tile,tile)/12)
   if ticks>=0 then return ticks,tile end
  end
  return if minimum>22500 then -2 else -1,sam.Tile
 end
 api.interceptionPlan=interception
 function api.intercept(sam,target,tile)
  local owner=sam.Owner;local u=nil;local active=true;local step=nav.Path.stepper(false,sim.Tick)
  local function tick()
   if not u then u=nav.create(owner,"SAMMissile",sam.Tile,{TargetUnit=target,TargetTile=tile}) end
   if not u.Active then active=false;return end
   if not target.Active or not sam.Active or target.Owner==owner or not table.find(nuclear,target.Type) then if target.Active then target.Targeted=false end;nav.delete(u);active=false;return end
   for _=1,12 do
    local status,t=step.next(u.Tile,tile)
    if status=="COMPLETE" then nav.delete(target);nav.delete(u);active=false;api.Interceptions+=1;notify(owner,"Missile intercepted.");return end
    nav.move(u,t)
   end
  end
  schedule(tick,function()return active end,tick)
 end
 function api.completed(unit)
  if unit.Type~="MissileSilo" and unit.Type~="SAMLauncher" then return end
  unit.MissileQueue=unit.MissileQueue or {};unit.SAMCache={}
  schedule(function()
   local queue=unit.MissileQueue
   while #queue>0 and sim.Tick-queue[1]>=90 do table.remove(queue,1);if unit.Type=="MissileSilo" then break end end
   if unit.Type~="SAMLauncher" or #queue>=unit.Level then return end
   if (nav.Counts.AtomBomb or 0)+(nav.Counts.HydrogenBomb or 0)+(nav.Counts.MIRVWarhead or 0)==0 then return end
   local targets={};local seen={}
   for _,u in ipairs(nav.nearby(unit.Tile,600,nuclear)) do
    if not u.Targeted and not sim.friendly(unit.Owner,u.Owner) then
     seen[u.ID]=true;local cached=unit.SAMCache[u.ID]
     if cached and (cached.Tick<0 or cached.Tick>sim.Tick+1) then continue end
     local delay,tile
     if cached and (cached.Tick==sim.Tick or cached.Tick==sim.Tick+1) then delay,tile=0,cached.Tile
     else delay,tile=interception(unit,u) end
     if delay>=0 and delay<=1 then
      unit.SAMCache[u.ID]=nil
      local score=(if u.Type=="HydrogenBomb" then 70001 else 0)+math.max(0,200000-nav.Path.distance(unit.Tile,u.TargetTile)*1000)+math.max(0,10000-math.max(1,#u.Trajectory-u.Index+1)*100)
      table.insert(targets,{Unit=u,Tile=tile,Score=score,Order=#targets+1})
     else unit.SAMCache[u.ID]={Tick=if delay>=0 then sim.Tick+delay else delay,Tile=tile} end
    end
   end
   for id in pairs(unit.SAMCache) do if not seen[id] then unit.SAMCache[id]=nil end end
   table.sort(targets,function(a,c)return a.Score>c.Score or a.Score==c.Score and a.Order<c.Order end)
   for _,v in ipairs(targets) do if #queue>=unit.Level then break end;table.insert(queue,sim.Tick);v.Unit.Targeted=true;api.intercept(unit,v.Unit,v.Tile) end
  end,function()return unit.Active end)
 end
 function api.summary(p)
  local list={};for _,u in ipairs(p.BuildingUnits) do if u.Type=="MissileSilo" or u.Type=="SAMLauncher" then
   local queue=u.MissileQueue or {};table.insert(list,{ID=u.ID,Type=u.Type,Level=u.Level,Ready=if u.UnderConstruction then 0 else math.max(0,u.Level-#queue),Reload=if queue[1] then math.max(0,90-(sim.Tick-queue[1])) else 0})
  end end
  local quotes={};for _,kind in ipairs(Rules.Types) do local price=api.price(p,kind);quotes[kind]={Cost=price,Affordable=Gold.compare(p.Gold,price)>=0} end
  return {Structures=list,Quotes=quotes,Impacts=api.Impacts,Interceptions=api.Interceptions}
 end
 return api
end
return Missiles
