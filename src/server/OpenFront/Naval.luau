--!strict
-- TransportShipExecution, TradeShipExecution, PortExecution, BoatRetreatExecution,
-- MoveWarshipExecution and PlayerImpl naval validation, OpenFront 8f1a0add.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE/NOTICE.
local Path = require(script.Parent.WaterPath)
local Shore = require(script.Parent.ShoreQuery)
local Warship = require(script.Parent.Warship)
local Expansion = require(script.Parent.Expansion)
local Rules = require(game:GetService("ReplicatedStorage").Shared.OpenFront.NavalRules)
local Wire = require(game:GetService("ReplicatedStorage").Shared.OpenFront.ShipWire)
local Random = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Random32)
local Troops = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Troops)
local Gold = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Gold)
local Economy = require(script.Parent.Economy)
local Naval={}
function Naval.new(sim,terrain)
 local grid=sim.Grid;local api={Units={},Count=0,Counts={},Path=Path.new(grid,terrain)}
 api.Shore=Shore.new(grid,api.Path)
 local changes={};local buckets={};local bucketWidth=math.ceil(grid.Width/100);local insertion=0
 local function bucket(t)return math.floor(t%grid.Width/100)+math.floor(math.floor(t/grid.Width)/100)*bucketWidth end
 local function insert(u)local k=bucket(u.Tile);buckets[k]=buckets[k] or {};table.insert(buckets[k],u);insertion+=1;u.SpatialOrder=insertion end
 local function remove(u)local k=bucket(u.Tile);local b=buckets[k];if b then local i=table.find(b,u);if i then table.remove(b,i) end;if #b==0 then buckets[k]=nil end end end
 function api.touch(u)changes[u.ID]=u end
 function api.init(p)p.Ships={};p.ShipCounts={};p.ShipConstructed={};p.Embargoes={};p.TradeGold="0";p.PiracyGold="0" end
 function api.create(p,kind,tile,params)
  local u={ID=sim.Buildings.nextID(),Type=kind,Tile=tile,Owner=p,Active=true,Health=if kind=="Warship" then 1000 else 1,Veterancy=0,Progress=0,State="patrolling",LastCombatTick=-100,LastSafe=0,Troops=0}
  for k,v in pairs(params or {}) do u[k]=v end
  api.Units[u.ID]=u;api.Count+=1;api.Counts[kind]=(api.Counts[kind] or 0)+1
  table.insert(p.Ships,u);p.ShipCounts[kind]=(p.ShipCounts[kind] or 0)+1;p.ShipConstructed[kind]=(p.ShipConstructed[kind] or 0)+1;insert(u);api.touch(u);return u
 end
 local function unown(u)local p=u.Owner;local i=table.find(p.Ships,u);if i then table.remove(p.Ships,i) end;p.ShipCounts[u.Type]-=1 end
 function api.delete(u)
  if not u.Active then return end;u.Active=false;unown(u);remove(u);api.Units[u.ID]=nil;api.Count-=1;api.Counts[u.Type]-=1;api.touch(u)
 end
 function api.capture(u,p)unown(u);u.Owner=p;table.insert(p.Ships,u);p.ShipCounts[u.Type]=(p.ShipCounts[u.Type] or 0)+1;api.touch(u) end
 function api.move(u,t)if t~=u.Tile then local changed=bucket(t)~=bucket(u.Tile);if changed then remove(u) end;u.Tile=t;if changed then insert(u) end;api.touch(u) end end
 function api.removePlayer(p,keepMissiles)for _,u in ipairs(table.clone(p.Ships)) do if not keepMissiles or table.find({"TransportShip","Warship","TradeShip","Shell","SAMMissile"},u.Type) then api.delete(u) end end end
 function api.nearby(tile,radius,types)
  local result={};local x,y=tile%grid.Width,math.floor(tile/grid.Width)
  for by=math.max(0,math.floor((y-radius)/100)),math.min(math.ceil(grid.Height/100)-1,math.floor((y+radius)/100)) do
   for bx=math.max(0,math.floor((x-radius)/100)),math.min(bucketWidth-1,math.floor((x+radius)/100)) do
    for _,kind in ipairs(types) do for _,u in ipairs(buckets[by*bucketWidth+bx] or {}) do
     if u.Type==kind and sim.Buildings.distance(tile,u.Tile)<=radius*radius then table.insert(result,u) end
    end end
   end
  end;return result
 end
 function api.ports(p)local list={};for _,u in ipairs(p.BuildingUnits) do if u.Type=="Port" and u.Active then table.insert(list,u) end end;return list end
 function api.embargo(defender,attacker)defender.Embargoes[attacker.UserId]=sim.Tick end
 function api.canTrade(a,b)
  if a==b then return false end
  local x,y=a.Embargoes[b.UserId],b.Embargoes[a.UserId]
  return (not x or sim.Tick-x>3000) and (not y or sim.Tick-y>3000)
 end
 function api.warshipSpawn(p,tile)
  if not grid.valid(tile) or grid.isLand(tile) then return nil end
  local component=api.Path.component(tile);local best,distance=nil,math.huge
  for _,port in ipairs(api.ports(p)) do local d=api.Path.distance(port.Tile,tile)
   if not port.UnderConstruction and component and api.Path.hasComponent(port.Tile,component) and d<distance then best=port.Tile;distance=d end
  end;return best
 end
 function api.price(p)return if sim.Economy.isFree(p) then "0" else Rules.warshipCost(p.ShipCounts.Warship or 0,p.ShipConstructed.Warship or 0) end
 sim.Economy.register("Naval:Transport",function()return "0" end,function(p,_,c)
  if not grid.valid(c.Tile) or (p.ShipCounts.TransportShip or 0)>=Rules.TransportLimit then return false end
  local target=sim.owner(grid.ownerID(c.Tile));if target==p or (target and not sim.canAttack(p,target)) then return false end
  if typeof(c.Allocation)~="number" or c.Allocation~=c.Allocation or c.Allocation<0 or c.Allocation>1 then return false end
  c.Troops=p.Troops*c.Allocation
  c.Target=target;c.Destination=api.Shore.target(p,c.Tile);if c.Destination==nil then return false end
  c.Source=api.Shore.launch(p,c.Destination);return c.Source~=nil
 end)
 sim.Economy.register("Naval:Warship",api.price,function(p,_,c)c.Source=api.warshipSpawn(p,c.Tile);return c.Source~=nil end)
 for _,action in ipairs({"Move","Retreat"}) do local kind=action
  sim.Economy.register("Naval:"..kind,function()return "0" end,function(p,_,c)
   local u=api.Units[c.UnitID];if not u or u.Owner~=p then return false end
   if kind=="Retreat" then return u.Type=="TransportShip" end
   return u.Type=="Warship" and grid.valid(c.Tile) and api.Path.hasComponent(u.Tile,api.Path.component(c.Tile))
  end)
 end
 function api.schedule(init,tick,alive)
  local function timed(f)local began=os.clock();f();sim.Work.NavalMilliseconds=(sim.Work.NavalMilliseconds or 0)+(os.clock()-began)*1000 end
  sim.Executions.add({activeDuringSpawnPhase=function()return false end,isActive=alive,init=function()timed(init)end,tick=function()timed(tick)end})
 end
 function api.transport(p,c)
  local amount=math.min(p.Troops,c.Troops);Troops.remove(p,amount);local u=api.create(p,"TransportShip",c.Source,{Troops=amount,TargetTile=c.Destination})
  if c.Target and sim.TransactionResults then table.insert(sim.TransactionResults,{UserId=c.Target.UserId,Message="Incoming naval invasion from "..p.Username.." (transport #"..u.ID..")."}) end
  local destination,target=c.Destination,c.Target;local retreat=nil;local step=api.Path.stepper(true)
  api.schedule(function()end,function()
   if not u.Active then return end
   if u.Retreating then
    if retreat==nil then retreat=api.Shore.launch(p,u.Tile) or false end
    if retreat==false then Troops.add(p,u.Troops);api.delete(u);return end
    destination=retreat;u.TargetTile=destination;api.touch(u)
   end
   local status,t=step.next(u.Tile,destination)
   if status=="NEXT" then api.move(u,t)
   elseif status=="NOT_FOUND" then Troops.add(p,u.Troops);api.delete(u)
   elseif grid.ownerID(destination)==p.SmallId then Troops.add(p,u.Troops*0.75);api.delete(u)
   else
    sim.conquer(p,destination)
    if target and sim.friendly(p,target) then Troops.add(p,u.Troops)
    else sim.Executions.add(Expansion.new(sim,p,u.Troops,target,destination,false)) end
    api.delete(u)
   end
  end,function()return u.Active end);return u
 end
 function api.trade(original,source,dest)
  local u=nil;local active=true;local captured=false;local traveled=0;local step=api.Path.stepper(true)
  local function complete()
   local amount=tostring(Rules.tradeGold(traveled,sim.Economy.multiplier(u.Owner)))
   if captured then Economy.add(u.Owner,amount);if u.Owner~=original then u.Owner.PiracyGold=Gold.add(u.Owner.PiracyGold or "0",amount) end
   else Economy.add(source.Owner,amount);Economy.add(dest.Owner,amount);source.Owner.TradeGold=Gold.add(source.Owner.TradeGold,amount);dest.Owner.TradeGold=Gold.add(dest.Owner.TradeGold,amount) end
   api.delete(u);active=false
  end
  api.schedule(function()end,function()
   if not u then
    local owned=false;for _,port in ipairs(api.ports(original)) do if port.Tile==source.Tile then owned=true;break end end
    if not owned or (grid.Counts[original.SmallId] or 0)==0 then active=false;return end
    u=api.create(original,"TradeShip",source.Tile,{TargetUnit=dest,LastSafe=sim.Tick})
   end
   if not u.Active then active=false;return end
   if u.Owner~=original then captured=true end
   if dest.Owner==source.Owner or (not captured and (not dest.Active or not api.canTrade(u.Owner,dest.Owner))) then api.delete(u);active=false;return end
   if captured and (u.Owner~=dest.Owner or not dest.Active) then
    local best,distance=nil,math.huge;local component=api.Path.component(u.Tile)
    for _,port in ipairs(api.ports(u.Owner)) do local d=api.Path.distance(u.Tile,port.Tile)
     if not port.UnderConstruction and not port.DeleteAt and api.Path.hasComponent(port.Tile,component) and d<distance then best=port;distance=d end
    end
    if not best then api.delete(u);active=false;return end;dest=best;u.TargetUnit=best;api.touch(u)
   end
   if u.Tile==dest.Tile then complete();return end
   local status,t=step.next(u.Tile,dest.Tile)
   if status=="NEXT" then
    if not grid.isLand(t) and bit32.band(grid.terrainByte(t),64)~=0 then u.LastSafe=sim.Tick end
    api.move(u,t);traveled+=1
   elseif status=="COMPLETE" then complete()
   else api.delete(u);active=false end
  end,function()return active end)
 end
 function api.port(port)
  if port.Type~="Port" then return end
  local rng=nil;local offset=0;local rejections=0
  api.schedule(function()rng=Random.new(sim.Tick);offset=sim.Tick%10 end,function()
   if not port.Active or port.UnderConstruction or (sim.Tick+offset)%10~=0 then return end
   local success=false
   for _=1,port.Level do
    if rng.nextInt(0,Rules.tradeRate(rejections,api.Counts.TradeShip or 0,port.Owner.BuildingOwned.Port or 0))==0 then success=true;rejections=0;break end;rejections+=1
   end
   if not success then return end
   local components={};local nb={};for i=1,grid.neighbors4(port.Tile,nb) do local c=api.Path.component(nb[i]);if not grid.isLand(nb[i]) and c then components[c]=true end end
   local candidates={};local players={};for _,p in pairs(sim.Players) do table.insert(players,p) end;table.sort(players,function(a,b)return a.SmallId<b.SmallId end)
   for _,p in ipairs(players) do if (grid.Counts[p.SmallId] or 0)>0 and api.canTrade(p,port.Owner) then
    for _,other in ipairs(api.ports(p)) do
     local reachable=false;for c in pairs(components) do if api.Path.hasComponent(other.Tile,c) then reachable=true;break end end
     if reachable then table.insert(candidates,{Unit=other,Distance=api.Path.distance(port.Tile,other.Tile),Order=#candidates+1}) end
    end
   end end
   table.sort(candidates,function(a,b)return a.Distance<b.Distance or (a.Distance==b.Distance and a.Order<b.Order) end)
   local total=0
   for i,c in ipairs(candidates) do local multiplier=1
    if c.Distance>=300 then if i-1<math.min(math.max(#candidates/3,4),#candidates) then multiplier+=1 end;if sim.friendly(port.Owner,c.Unit.Owner) then multiplier+=1 end end
    c.Weight=c.Unit.Level*multiplier;total+=c.Weight
   end
   if total==0 then return end;local chosen=rng.nextInt(0,total)
   for _,c in ipairs(candidates) do chosen-=c.Weight;if chosen<0 then api.trade(port.Owner,port,c.Unit);break end end
  end,function()return port.Active end)
 end
 function api.order(p,e)
  if not table.find({"Transport","Warship","Move","Retreat"},e.Action) then return end
  local active=true
  api.schedule(function()
   local c={Tile=e.Tile,Allocation=e.Allocation,UnitID=e.UnitID}
   local receipt,fresh=sim.Economy.purchase(p,e.Sequence,"Naval:"..e.Action,c)
   table.insert(sim.TransactionResults,{UserId=p.UserId,Receipt=receipt,Fresh=fresh,Message=if receipt.OK then (if fresh then "Naval order accepted." else "Order already processed.") else "Naval order rejected: "..receipt.Reason})
   if fresh and receipt.OK then
    if e.Action=="Transport" then p.Allocation=e.Allocation;api.transport(p,c)
    elseif e.Action=="Warship" then local u=api.create(p,"Warship",c.Source,{PatrolTile=c.Tile});Warship.start(sim,api,u)
    elseif e.Action=="Move" then local u=api.Units[c.UnitID];u.PatrolTile=c.Tile;u.TargetTile=nil;api.touch(u)
    else
     local id=c.UnitID;api.schedule(function()end,function()local u=api.Units[id];if u and u.Owner==p then u.Retreating=true;api.touch(u) end;active=false end,function()return active end);return
    end
   end;active=false
  end,function()end,function()return active end)
 end
 local function record(u)
  return {ID=u.ID,Type=u.Type,Tile=u.Tile,Owner=if u.Active then u.Owner.SmallId else 0,Health=u.Health,Veterancy=u.Veterancy,Progress=u.Progress,Troops=u.Troops,TargetTile=u.TargetTile,
   Flags=(if u.State=="retreating" then 1 elseif u.State=="docked" then 2 else 0)+(if u.Retreating then 4 else 0)+(if sim.Tick-u.LastCombatTick<=3 then 8 else 0)}
 end
 function api.snapshot()local list={};for _,u in pairs(api.Units) do table.insert(list,record(u)) end;table.sort(list,function(a,b)return a.ID<b.ID end);return list end
 function api.drain()local list={};for _,u in pairs(changes) do table.insert(list,record(u)) end;table.sort(list,function(a,b)return a.ID<b.ID end);changes={};return Wire.pack(list) end
 function api.summary(p)local price=api.price(p);return {WarshipCost=price,Affordable=Gold.compare(p.Gold,price)>=0,Transports=p.ShipCounts.TransportShip or 0,Warships=p.ShipCounts.Warship or 0,TradeShips=p.ShipCounts.TradeShip or 0} end
 return api
end
return Naval
