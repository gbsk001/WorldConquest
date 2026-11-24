--!strict
-- WarshipExecution, ShellExecution and UnitImpl veterancy/health, OpenFront 8f1a0add.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE/NOTICE.
local Rules = require(game:GetService("ReplicatedStorage").Shared.OpenFront.NavalRules)
local Random = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Random32)
local Warship={}
function Warship.health(sim,nav,u,delta)
 local health=math.clamp(u.Health+math.floor(delta),0,if u.Type=="Warship" then Rules.maxHealth(u.Veterancy) else 1)
 if health~=u.Health then u.Health=health;nav.touch(u) end
 if delta<0 and u.Type=="Warship" then u.LastCombatTick=sim.Tick end
 if health==0 then nav.delete(u) end
end
function Warship.shell(sim,nav,firing,target)
 local spawn,owner=firing.Tile,firing.Owner;local shell=nil;local active=true;local destroyAt=-1;local step,rng=nil,nil
 nav.schedule(function()step=nav.Path.stepper(false,sim.Tick);rng=Random.new(sim.Tick) end,function()
  if not shell then shell=nav.create(owner,"Shell",spawn) end
  if not shell.Active then active=false;return end
  if not target.Active or target.Owner==shell.Owner or (destroyAt~=-1 and sim.Tick>=destroyAt) then nav.delete(shell);active=false;return end
  if destroyAt==-1 and not firing.Active then destroyAt=sim.Tick+Rules.ShellLifetime end
  for _=1,3 do local status,t=step.next(shell.Tile,target.Tile)
   if status=="COMPLETE" then
    Warship.health(sim,nav,target,-Rules.shellDamage(rng.nextInt(1,6),firing.Veterancy))
    if not target.Active and firing.Active then firing.Veterancy,firing.Progress=Rules.progress(firing.Veterancy,firing.Progress,target.Type);nav.touch(firing) end
    nav.delete(shell);active=false;return
   elseif status=="NEXT" then nav.move(shell,t) end
  end
 end,function()return active end)
end
function Warship.start(sim,nav,u)
 local grid=sim.Grid;local distance=sim.Buildings.distance;local step=nav.Path.stepper(true)
 local rng=nil;local lastShell=0;local sent={};local lastManual=0;local observed=nil;local remainder=0;local emitted=false
 local function fullyHealed()return u.Health>=Rules.maxHealth(u.Veterancy) end
 local function currentPort()for _,p in ipairs(nav.ports(u.Owner)) do if p.Tile==u.RetreatPort then return p end end;return nil end
 local function docked(port,exclude)
  local list={};for _,s in ipairs(nav.nearby(port.Tile,Rules.DockingRange,{"Warship"})) do
   if s~=exclude and s.Owner==u.Owner and s.State~="patrolling" and s.TargetTile==nil then table.insert(list,s) end
  end;return list
 end
 local function nearest(available,exclude)
  local best,d=nil,math.huge;local component=nav.Path.component(u.Tile);if not component then return nil end
  for _,p in ipairs(nav.ports(u.Owner)) do
   if (not available or #docked(p,exclude)<p.Level) and (if available then nav.Path.hasComponent(p.Tile,component) else nav.Path.component(p.Tile)==component) then
    local value=distance(u.Tile,p.Tile);if value<d then d=value;best=p.Tile end
   end
  end;return best,d
 end
 local function cancel(clear)
  remainder=0;u.State="patrolling";u.RetreatPort=nil;if clear~=false then u.TargetTile=nil end;nav.touch(u)
 end
 local function target(includeTrade)
  local best,priority,dist=nil,math.huge,math.huge
  local types=if includeTrade then {"TransportShip","Warship","TradeShip"} else {"TransportShip","Warship"}
  local hasPort=nil
  for _,s in ipairs(nav.nearby(u.Tile,Rules.TargetRange,types)) do
   if s==u or s.Owner==u.Owner or not sim.canAttack(u.Owner,s.Owner) or sent[s] or (s.Type=="Warship" and s.State=="docked") then continue end
   if s.Type=="TradeShip" then
    if hasPort==nil then hasPort=false;local component=nav.Path.component(u.Tile)
     for _,p in ipairs(nav.ports(u.Owner)) do if not p.DeleteAt and not p.UnderConstruction and nav.Path.hasComponent(p.Tile,component) then hasPort=true;break end end
    end
    if not hasPort or u.PatrolTile==nil or sim.Tick-s.LastSafe<Rules.PiracyGrace or (s.TargetUnit and (s.TargetUnit.Owner==u.Owner or sim.friendly(s.TargetUnit.Owner,u.Owner))) or distance(u.PatrolTile,s.Tile)>Rules.PatrolRange^2 then continue end
   end
   local rank=if s.Type=="TransportShip" then 0 elseif s.Type=="Warship" then 1 else 2;local d=distance(u.Tile,s.Tile)
   if rank<priority or (rank==priority and d<dist) then best=s;priority=rank;dist=d end
  end;return best
 end
 local function shoot()
  u.LastCombatTick=sim.Tick;nav.touch(u)
  if sim.Tick-lastShell>Rules.ShellRate then
   local t=u.TargetUnit;if t.Type~="TransportShip" then lastShell=sim.Tick end
   Warship.shell(sim,nav,u,t)
   if t.Type~="Warship" then sent[t]=true;u.TargetUnit=nil end
  end
 end
 local function repair()
  if u.State=="patrolling" then return false end
  local enemy=target(false);if enemy then u.TargetUnit=enemy;shoot() end
  local port=currentPort()
  if not port then u.RetreatPort=nearest(true,u)
  elseif #docked(port,nil)>=port.Level then local alternative=nearest(true,nil);if alternative then u.RetreatPort=alternative end
  else local closer,d=nearest(true,nil);if closer and closer~=0 and d<distance(u.Tile,u.RetreatPort)*Rules.PortSwitchRatio then u.RetreatPort=closer end end
  if not u.RetreatPort then cancel();return false end
  if not enemy then u.TargetUnit=nil end
  port=currentPort()
  if distance(u.Tile,u.RetreatPort)<=Rules.DockingRange^2 then
   if port and #docked(port,u)<port.Level then u.TargetTile=nil;u.State="docked";nav.touch(u);return true
   elseif fullyHealed() then cancel();return false else return true end
  end
  u.TargetTile=u.RetreatPort;local status,t=step.next(u.Tile,u.RetreatPort)
  if status=="NEXT" or status=="COMPLETE" then nav.move(u,t);if status=="COMPLETE" and t==u.RetreatPort then u.TargetTile=nil end
  else u.RetreatPort=nearest(true,u);if not u.RetreatPort then cancel() end end
  return true
 end
 local function randomTile(allowShoreline)
  if not grid.valid(u.PatrolTile) then return nil end
  local range,attempts,expansions=Rules.PatrolRange,0,0;local component=nav.Path.component(u.Tile)
  while expansions<3 do
   local x=u.PatrolTile%grid.Width+rng.nextInt(-range/2,range/2);local y=math.floor(u.PatrolTile/grid.Width)+rng.nextInt(-range/2,range/2)
   if x<0 or y<0 or x>=grid.Width or y>=grid.Height then continue end
   local t=y*grid.Width+x
   if grid.isLand(t) or (not allowShoreline and bit32.band(grid.terrainByte(t),64)~=0) or (component and not nav.Path.hasComponent(t,component)) then
    attempts+=1;if attempts==500 then expansions+=1;attempts=0;range+=math.floor(range/2) end;continue
   end;return t
  end
  if not allowShoreline then return randomTile(true) end;return nil
 end
 local function patrol()
  if u.TargetTile==nil then u.TargetTile=randomTile(false);if u.TargetTile==nil then return end;nav.touch(u) end
  local status,t=step.next(u.Tile,u.TargetTile)
  if status=="COMPLETE" then u.TargetTile=nil;nav.move(u,t)
  elseif status=="NEXT" then nav.move(u,t) else u.TargetTile=nil end
 end
 local function capture(t)nav.capture(t,u.Owner);u.Veterancy,u.Progress=Rules.progress(u.Veterancy,u.Progress,"TradeShip");u.TargetUnit=nil;nav.touch(u) end
 local function hunt()
  u.LastCombatTick=sim.Tick;nav.touch(u)
  for _=1,2 do local t=u.TargetUnit;local d=nav.Path.distance(u.Tile,t.Tile)
   if d<=5 then capture(t);return end
   if d<=20 then
    local best=nil;local nb={};for i=1,grid.neighbors4(u.Tile,nb) do local n=nb[i];local nd=nav.Path.distance(n,t.Tile);if not grid.isLand(n) and nd<d then best=n;d=nd end end
    if best then nav.move(u,best);continue end
   end
   local status,n=step.next(u.Tile,t.Tile,5);if status=="COMPLETE" then capture(t);return elseif status=="NEXT" then nav.move(u,n) end
  end
 end
 nav.schedule(function()rng=Random.new(sim.Tick);observed=u.PatrolTile end,function()
  if not u.Active then return end
  if u.Health<=0 then nav.delete(u);return end
  local combat=sim.Tick-u.LastCombatTick<=3;if emitted and not combat then nav.touch(u) end;emitted=combat
  local before=u.Health
  for _,p in ipairs(nav.ports(u.Owner)) do if distance(u.Tile,p.Tile)<=Rules.HealingRange^2 then Warship.health(sim,nav,u,Rules.PassiveHealing);break end end
  if u.State=="docked" then local port=currentPort()
   if port then local ships=docked(port,nil);if table.find(ships,u) then remainder+=port.Level*Rules.HealingPerPortLevel/#ships;local healing=math.floor(remainder);if healing>0 then remainder-=healing;Warship.health(sim,nav,u,healing) end end end
  end
  if observed~=nil and observed~=u.PatrolTile then lastManual=sim.Tick;if u.State~="patrolling" then cancel(false) end end;observed=u.PatrolTile
  if u.State=="docked" then if not currentPort() or fullyHealed() then cancel() end;if u.State=="docked" then return end end
  if repair() then return end
  if sim.Tick-lastManual>=50 and before<math.floor(Rules.maxHealth(u.Veterancy)*Rules.RetreatPercent/100) and #nav.ports(u.Owner)>0 then
   local port=nearest(false,nil);if port then u.RetreatPort=port;u.State="retreating";remainder=0;u.TargetUnit=nil;nav.touch(u) end
   if repair() then return end
  end
  u.TargetUnit=target(true)
  if u.TargetUnit and (u.TargetUnit.Type=="TransportShip" or u.TargetUnit.Type=="Warship") then shoot();patrol()
  elseif u.TargetUnit then hunt() else patrol() end
 end,function()return u.Active end)
end
return Warship
