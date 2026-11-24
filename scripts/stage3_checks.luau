-- Pinned upstream numerical and execution parity. AGPL-3.0, OpenFront contributors.
for _,case in ipairs(Stage3Oracle.formulas) do
 local i=case.input;local d=i.defender
 local a,b,c=Combat.losses(i.terrain,i.attackTroops,i.borderSize,{Kind=i.attacker.type,Count=i.attacker.numTiles},
  {Kind=d.type,Count=d.numTiles,Troops=d.troops,Traitor=d.isTraitor,DisconnectedTeammate=d.isDisconnectedTeammate},i.defenderHasDefensePost,i.falloutRatio)
 assert(a==case.result.attackerTroopLoss and b==case.result.defenderTroopLoss and c==case.result.tickFraction,"combat formula differs from source")
end
for _,case in ipairs(Stage3Oracle.scenarios) do
 local width,height=case.width,case.height
 local function byte(t)
  if t%width==40 then return 0 end
  -- GameMap terrain byte: land flag 0x80, magnitude thresholds 10/20.
  return 128+(if t%3==0 then 25 elseif t%3==1 then 15 else 0)
 end
 local map={cell=function(x,y) if x>=0 and y>=0 and x<width and y<height then return math.floor(y)*width+math.floor(x)+1 end;return nil end}
 local sim=Simulation.new({Width=width,Height=height,byte=byte,MaskHash="fixture"},map,123,{Stage=3})
 for id=1,3 do sim.enqueue({Kind="Join",UserId=id,Username="P"..id}) end
 sim.step();sim.Phase="Started";sim.StartTick=-50
 for _,p in pairs(sim.Players) do p.Troops=100000 end
 for _,cell in ipairs(case.starts) do sim.conquer(sim.Players[cell[2]],cell[1]) end
 sim.Grid.discardChanges()
 -- Capture calls, including repeated captures, must agree with the upstream trace.
 local actual={};local conquer=sim.conquer
 sim.conquer=function(p,t) conquer(p,t);table.insert(actual,{t,p.SmallId}) end
 local executions={};local clusters={}
 for id=1,3 do clusters[id]=Connectivity.new(sim,sim.Players[id]) end
 for _,frame in ipairs(case.trace) do
  sim.Tick=frame.tick;table.clear(actual)
  local p=sim.Players[1];local attack=p.Outgoing[1]
  if case.name=="cancel" and attack then
   if frame.tick==3 then attack.Retreating=true end
   if frame.tick==23 then attack.Retreated=true end
  end
  for _,execution in ipairs(executions) do if execution.isActive() then execution.tick() end end
  if case.connectivity then for _,c in ipairs(clusters) do c.removeClusters() end end
  for _,order in ipairs(case.orders) do if order.tick==frame.tick then
   local execution=Expansion.new(sim,sim.Players[order.from],order.amount,sim.Players[order.to]);execution.init();table.insert(executions,execution)
  end end
  local context=case.name.." tick "..frame.tick
  assert(#actual==#frame.changes,context.." capture count "..#actual.." expected "..#frame.changes)
  for n,cell in ipairs(actual) do assert(cell[1]==frame.changes[n][1] and cell[2]==frame.changes[n][2],context.." capture order") end
  for id,expected in ipairs(frame.players) do
   local p=sim.Players[id]
   assert(p.Troops==expected.reserve,context.." reserves")
   assert((sim.Grid.Counts[id] or 0)==expected.count,context.." ownership")
   assert(#p.Outgoing==#expected.attacks,context.." outgoing count")
   for n,a in ipairs(p.Outgoing) do assert(a.ID==expected.attacks[n].id and a.Troops==expected.attacks[n].troops,context.." committed stack") end
  end
 end
end
print("Stage 3 exact source parity: 117 combat formulas; 1040 battle/connectivity/counterattack/conquest/multi-attacker/merge/cancellation/island ticks including every capture and troop stack passed.")
local function combatMatch()
 local terrain={Width=128,Height=64,byte=function(t)return if t%128==100 then 0 else 128 end,MaskHash="combat-test"}
 local map={cell=function(x,y) if typeof(x)~="number" or typeof(y)~="number" or x~=x or y~=y or x<0 or y<0 or x>=128 or y>=64 then return nil end;return math.floor(y)*128+math.floor(x)+1 end}
 local s=Simulation.new(terrain,map,123,{Stage=3})
 for id=1,3 do s.enqueue({Kind="Join",UserId=id,Username="P"..id}) end;s.step()
 for y=10,29 do for x=10,69 do local id=math.floor((x-10)/20)+1;s.conquer(s.Players[id],y*128+x) end end
 s.Phase="Started";s.StartTick=s.Tick
 for _,p in pairs(s.Players) do p.Troops=100000;s.startRecruitment(p) end
 s.Grid.discardChanges();return s,terrain
end
local s,terrain=combatMatch();local replay=combatMatch()
local replica=Replica.new(terrain);local keys=s.Grid.chunkKeys()
assert(replica.begin({ID=1,Tick=s.Tick,Count=#keys,MapHash=terrain.MaskHash,Meta=s.metadata()}))
for _,key in ipairs(keys) do assert(replica.chunk({ID=1,Key=key,Data=s.Grid.copyChunk(key)})) end
assert(replica.finish({ID=1}))
local function both(e) s.enqueue(table.clone(e));replay.enqueue(table.clone(e)) end
-- Self, nonadjacent target, water, invalid allocation and immunity must not commit troops.
for tick=1,160 do
 if tick<=5 then
  local x=({15,55,100,35,35})[tick]
  both({Kind="Expand",UserId=1,X=x,Y=15,Allocation=if tick==4 then 0/0 else 1})
 end
 if tick==52 then
  both({Kind="Expand",UserId=1,X=35,Y=15,Allocation=0.4})
  both({Kind="Expand",UserId=3,X=35,Y=15,Allocation=0.4})
 end
 if tick==55 then both({Kind="Expand",UserId=2,X=15,Y=15,Allocation=0.2}) end
 if tick==60 and s.Players[1].Attack then both({Kind="Cancel",UserId=1,AttackID=s.Players[1].Attack.ID}) end
 local packet=s.step();local copy=replay.step()
 assert(buffer.tostring(packet.Changes)==buffer.tostring(copy.Changes),"combat replay delta")
 assert(replica.delta(packet),"combat client replication")
 for id,p in pairs(s.Players) do
  assert(p.Troops==replay.Players[id].Troops,"combat replay reserve")
  assert((replica.Grid.Counts[id] or 0)==(s.Grid.Counts[id] or 0),"replica count")
  if tick<=50 then assert(#p.Outgoing==0,"invalid or immune attack committed troops") end
 end
end
for _,key in ipairs(s.Grid.chunkKeys()) do assert(buffer.tostring(s.Grid.copyChunk(key))==buffer.tostring(replica.Grid.copyChunk(key))) end
-- Init rechecks friendship and target removal; rejected orders must not deduct.
local p,q=s.Players[1],s.Players[2];local before=p.Troops
p.Team="A";q.Team="A";local e=Expansion.new(s,p,5000,q);e.init();assert(p.Troops==before and not e.isActive())
p.Team=nil;q.Team=nil
-- Dedicated complete elimination: reserve remains, recruitment stops, no resurrection orders.
local dead,dt=combatMatch();dead.Tick=100;dead.StartTick=0
local victim=dead.Players[2];local cells={};victim.Tiles.each(function(t)table.insert(cells,t)end)
for _,t in ipairs(cells) do dead.conquer(dead.Players[1],t) end
local reserve=victim.Troops
for _=1,5 do dead.enqueue({Kind="Expand",UserId=2,X=90,Y=15,Allocation=1});dead.step() end
assert(victim.Eliminated and victim.Troops==reserve and #victim.Outgoing==0)
print("Stage 3 authority: immunity/self/friendly/nonadjacent/water/NaN validation, deterministic 160-tick contested combat replay and replica ownership, elimination and stopped recruitment passed.")
-- Benchmark full-resolution grid, 100 humans on 50 active shared land fronts.
do
 local width,height=8192,4096
 local t={Width=width,Height=height,byte=function()return 128 end,MaskHash="benchmark"}
 local map={cell=function(x,y)return math.floor(y)*width+math.floor(x)+1 end}
 local b=Simulation.new(t,map,17,{Stage=3})
 for id=1,100 do b.enqueue({Kind="Join",UserId=id,Username="P"..id}) end;b.step();b.Phase="Started";b.StartTick=-50
 for pair=0,49 do
  local ox=(pair%10)*80+10;local oy=math.floor(pair/10)*80+10
  for y=oy,oy+59 do for x=ox,ox+59 do b.conquer(b.Players[pair*2+(if x<ox+30 then 1 else 2)],y*width+x) end end
 end
 for _,p in pairs(b.Players) do p.Troops=500000 end
 for pair=0,49 do b.Executions.add(Expansion.new(b,b.Players[pair*2+1],100000,b.Players[pair*2+2])) end
 b.Grid.discardChanges()
 local times={};local bytes,maxBytes,pops,claims=0,0,0,0;local peak=gcinfo()
 for _=1,200 do
  local start=os.clock();local packet=b.step();table.insert(times,(os.clock()-start)*1000)
  local n=buffer.len(packet.Changes);bytes+=n;maxBytes=math.max(maxBytes,n);pops+=b.Work.Pops;claims+=b.Work.Claims;peak=math.max(peak,gcinfo())
 end
 table.sort(times);local total=0;for _,ms in ipairs(times) do total+=ms end
 print(string.format("Stage 3 100 humans/50 combat fronts/8192x4096/200 ticks: mean %.3f ms, p95 %.3f ms, max %.3f ms; %d claims, %d heap pops; ownership %d B; deltas mean %.0f B/tick, max %d B; cumulative harness heap %.0f KiB.",total/#times,times[190],times[200],claims,pops,b.Grid.allocatedBytes(),bytes/200,maxBytes,peak))
end
