--!native
--!strict
-- Translation of OpenFront AttackExecution/AttackImpl/RetreatExecution,
-- pinned 8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94. Human land combat.
-- Copyright OpenFront and Contributors; AGPL-3.0, see LICENSE/NOTICE.
local Heap = require(game:GetService("ReplicatedStorage").Shared.OpenFront.MinHeap)
local Random = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Random32)
local Troops = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Troops)
local RetreatExecution = require(script.Parent.RetreatExecution)
local Combat = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Combat)
local Expansion={}
function Expansion.new(sim,p,amount,target,sourceTile,removeTroops)
 local targetID=if target then target.SmallId else 0
 local grid=sim.Grid;local owner=grid.ownerUnchecked;local terrain=grid.terrainUnchecked;local heap=Heap.new();local rng=Random.new(123)
 local border,nb,inner={},{},{};local borderSize=0
 local executionActive=true
 local attack={ID=sim.nextAttackID(),Troops=if removeTroops==false then amount else 0,SourceTile=sourceTile,Active=true,Retreating=false,Retreated=false,Owner=p,Target=target}
 local execution={Attack=attack}
 local function clear() table.clear(border);borderSize=0;heap.clear() end
 local function addNeighbors(ref)
  local n=grid.neighbors4Unchecked(ref,nb)
  for i=1,n do
   local t=nb[i]
   local byte=terrain(t);local magnitude=bit32.band(byte,31)
   if bit32.band(byte,128)~=0 and magnitude~=31 and owner(t)==targetID then
    if not border[t] then border[t]=true;borderSize+=1 end
    local owned=0;local count=grid.neighbors4Unchecked(t,inner)
    for j=1,count do if owner(inner[j])==p.SmallId then owned+=1 end end
    local mag=if magnitude<10 then 1 elseif magnitude<20 then 1.5 else 2
    heap.enqueueUnchecked(t,(rng.nextInt(0,7)+10)*(1-owned*0.5+mag/2)+sim.Tick)
   end
  end
 end
 local function refresh() clear();p.Border.each(addNeighbors) end
 local function remove(list,item)
  local result={};for _,v in ipairs(list or {}) do if v~=item then table.insert(result,v) end end;return result
 end
 function attack.delete()
  attack.Active=false
  p.Outgoing=remove(p.Outgoing,attack)
  if target then target.Incoming=remove(target.Incoming,attack) end
  if p.Attack==attack then p.Attack=p.Outgoing[#p.Outgoing] end
 end
 local function retire() attack.delete();executionActive=false end
 local function refund(penalty)
  local survivors=attack.Troops-attack.Troops*((penalty or 0)/100)
  Troops.add(p,survivors);retire()
  if sim.Economy and attack.Retreated then sim.Economy.attackSent(p,-survivors) end
 end
 local function finishDefender()
  if not target or (grid.Counts[targetID] or 0)>=100 then return end
  sim.conquerPlayer(p,target)
  local adjacent={}
  for _=1,100 do
   local progressed=false
   target.Tiles.each(function(t)
    local n=grid.neighbors4Unchecked(t,adjacent);local winner=nil
    for i=1,n do if owner(adjacent[i])==p.SmallId then winner=p;break end end
    if not winner then
     for i=1,n do
      local other=sim.owner(owner(adjacent[i]))
      if other and other~=target and not sim.friendly(other,target) then winner=other;break end
     end
    end
    if winner then sim.conquer(winner,t);sim.Work.Claims+=1;progressed=true end
   end)
   if not progressed then break end
  end
 end
 function execution.activeDuringSpawnPhase() return false end
 function execution.isActive() return executionActive end
 function execution.init()
  if sim.Players[p.UserId]~=p or (target and not sim.canAttack(p,target)) then retire();return end
  attack.Troops=if removeTroops==false then amount else Troops.remove(p,math.min(p.Troops,amount or Troops.attackAmount(p.Troops,p.Kind)))
  attack.SourceTile=sourceTile
  if target and sim.Naval then sim.Naval.embargo(target,p) end
  p.Outgoing=p.Outgoing or {};p.Incoming=p.Incoming or {}
  table.insert(p.Outgoing,attack)
  if target then target.Incoming=target.Incoming or {};table.insert(target.Incoming,attack) end
  if sourceTile~=nil then addNeighbors(sourceTile) else refresh() end
  if sim.Economy then sim.Economy.attackSent(p,attack.Troops) end
  for _,incoming in ipairs(p.Incoming) do
   if incoming.Active and incoming.Owner==target and (grid.Counts[targetID] or 0)>0 then
    if incoming.Troops>attack.Troops then incoming.Troops-=attack.Troops;retire();return
    else attack.Troops-=incoming.Troops;incoming.delete() end
   end
  end
  for _,outgoing in ipairs(p.Outgoing) do
   if sourceTile==nil and outgoing~=attack and outgoing.Active and outgoing.Target==target then
    attack.Troops+=outgoing.Troops;outgoing.delete()
   end
  end
  p.Attack=attack
  if heap.size()==0 then refund() end
 end
 function execution.tick()
  if not attack.Active or sim.Players[p.UserId]~=p then retire();return end
  if attack.Retreated then refund(if target then 25 else 0);return end
  if attack.Retreating then return end
  if target and sim.friendly(p,target) then refund();return end
  local troops=attack.Troops
  local fixedBorder=borderSize+rng.nextInt(0,5)
  local budget=1
  while budget>0 do
   if troops<1 then retire();return end
   if heap.size()==0 then refresh();refund();return end
   local t=heap.dequeue();sim.Work.Pops+=1
   if border[t] then border[t]=nil;borderSize-=1 end
   local onBorder=false;local n=grid.neighbors4Unchecked(t,nb)
   for i=1,n do if owner(nb[i])==p.SmallId then onBorder=true;break end end
   if owner(t)~=targetID or not onBorder then continue end
   local terrainByte=terrain(t)
   if bit32.band(terrainByte,128)==0 or bit32.band(terrainByte,31)==31 then continue end
   -- Upstream intentionally inserts BEFORE conquest; retain duplicates and RNG calls.
   addNeighbors(t)
   local loss,fraction
   if target then
    local defenseLoss
    loss,defenseLoss,fraction=Combat.losses(grid.terrainType(t),troops,fixedBorder,
     {Kind=p.Kind,Count=grid.Counts[p.SmallId] or 0},
       {Kind=target.Kind,Count=grid.Counts[targetID] or 0,Troops=target.Troops,Traitor=target.Traitor},sim.Buildings and sim.Buildings.defended(t,target))
    Troops.remove(target,defenseLoss)
   else loss,fraction=Troops.neutral(grid.terrainType(t),troops,fixedBorder,p.Kind,if bit32.band(grid.state(t),0x2000)~=0 then grid.FalloutCount/sim.LandCount else nil) end
   budget-=fraction;troops-=loss;attack.Troops=math.max(0,troops)
   sim.conquer(p,t);sim.Work.Claims+=1;finishDefender()
  end
 end
 local tick=execution.tick
 function execution.tick()
  local began=os.clock();tick();sim.Work.FrontierMilliseconds=(sim.Work.FrontierMilliseconds or 0)+(os.clock()-began)*1000
 end
 function execution.metrics() return heap.size(),borderSize end
 attack.Execution=execution
 return execution
end
function Expansion.retreat(sim,p,id)
 return RetreatExecution.new(sim,p,id)
end
return Expansion
