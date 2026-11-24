-- Actual production modules; upstream TS oracle supplies expected numeric values and claim order.
for _,curve in ipairs(Stage2Oracle.curves) do
 local p={Troops=25000};assert(Troops.cap(curve.land)==curve.cap)
 for _,expected in ipairs(curve.values) do Troops.add(p,Troops.growth(p.Troops,curve.cap));assert(p.Troops==expected,"Recruitment differs from source") end
end
for _,case in ipairs(Stage2Oracle.costs) do
 local loss,fraction=Troops.neutral(case.terrain,case.stack,case.border)
 assert(loss==case.loss and fraction==case.fraction,"Neutral formula differs from source")
end
local function fixture(w,h,byte)
 local terrain={Width=w,Height=h,byte=byte,MaskHash="fixture"}
 local map={LandCount=w*h,Width=w,Height=h}
 function map.cell(x,y)
  if typeof(x)~="number" or typeof(y)~="number" or x~=x or y~=y or x<0 or y<0 or x>=w or y>=h then return nil end
  return math.floor(y)*w+math.floor(x)+1
 end
 function map.xy(cell) return (cell-1)%w,math.floor((cell-1)/w) end
 function map.landAt(i) return i end
 return Simulation.new(terrain,map,51,{Stage=2}),terrain,map
end
local oracle=Stage2Oracle.frontier
local sim=fixture(oracle.width,oracle.height,function(t)
 return if t%48==24 then 0 elseif t%13==0 then 159 elseif t%3==0 then 148 elseif t%3==1 then 138 else 128
end)
sim.enqueue({Kind="Join",UserId=1,Username="Oracle"});sim.step()
local p=sim.Players[1];p.Troops=25000;sim.Tick=0
for _,t in ipairs(oracle.starts) do sim.conquer(p,t) end;sim.Grid.discardChanges()
local e=Expansion.new(sim,p,5000.9);e.init()
assert(p.Troops==20000,"Only actual integer reserves fund the stack")
for _,trace in ipairs(oracle.trace) do
 sim.Tick=trace.tick;if e.isActive() then e.tick() end
 assert(p.Troops==trace.reserve and (if p.Attack then p.Attack.Troops else 0)==trace.stack,"Stack/reserve trace mismatch "..trace.tick)
 local changes=sim.Grid.drain();assert(buffer.len(changes)==#trace.cells*6,"Claim count differs at tick "..trace.tick)
 for i,t in ipairs(trace.cells) do assert(buffer.readu32(changes,(i-1)*6)==t,"Heap frontier ordering differs at tick "..trace.tick);assert(t%48<24,"Crossed ocean") end
end
print("Stage 2 upstream parity: 1,000 reserve steps, 45 costs/speeds, 180 exact AttackExecution ticks including cell order passed.")

-- Same order trace on two authority instances and a receiving client.
local function match()
 local s,terrain,map=fixture(128,64,function(t) return if t%128==64 then 0 else 128 end)
 for id=1,2 do s.enqueue({Kind="Join",UserId=id,Username="P"..id}) end
 s.enqueue({Kind="Ready",UserId=1})
 s.enqueue({Kind="SelectSpawn",UserId=1,X=20.125,Y=30.875})
 s.enqueue({Kind="SelectSpawn",UserId=2,X=38.125,Y=30.875})
 for _=1,205 do s.step() end
 assert(s.Grid.Counts[1]==52 and s.Grid.Counts[2]==52,"Source radius-4 footprint")
 assert(s.Players[2].X==38.125)
 return s,terrain,map
end
local s,t,map=match();local twin=match()
local client=Replica.new(t);local keys=s.Grid.chunkKeys()
assert(client.begin({ID=1,Tick=s.Tick,Count=#keys,MapHash=t.MaskHash,Meta=s.metadata()}))
for _,key in ipairs(keys) do assert(client.chunk({ID=1,Key=key,Data=s.Grid.copyChunk(key)})) end
assert(client.finish({ID=1}))
local function order(s,event) s.enqueue(table.clone(event)) end
for tick=1,150 do
 if tick==1 or tick==25 then
  for id=1,2 do local ev={Kind="Expand",UserId=id,X=30,Y=10,Allocation=0.2};order(s,ev);order(twin,ev) end
 end
 if tick==40 then
  local ev={Kind="Cancel",UserId=1,AttackID=s.Players[1].Attack.ID};order(s,ev);order(twin,ev)
 end
 local packet=s.step();local other=twin.step()
 assert(buffer.tostring(packet.Changes)==buffer.tostring(other.Changes))
 assert(client.delta(packet))
 for id=1,2 do assert(s.Players[id].Troops==twin.Players[id].Troops) end
 if tick==42 then assert(s.Players[1].Attack.Retreating) end
 if tick==62 then assert(not s.Players[1].Attack,"Delayed refund must finish") end
end
for _,key in ipairs(s.Grid.chunkKeys()) do
 assert(buffer.tostring(s.Grid.copyChunk(key))==buffer.tostring(client.Grid.copyChunk(key)))
end
for ref=64,128*64-1,128 do assert(s.Grid.ownerID(ref)==0) end
-- Server rejects forged ownership, other-player clicks, invalid allocation, NaN and late spectator orders.
local before=s.Grid.Counts[1]
for _,allocation in ipairs({0,-1,2,math.huge,0/0}) do s.enqueue({Kind="Expand",UserId=1,X=100,Y=30,Allocation=allocation}) end
s.enqueue({Kind="Expand",UserId=1,X=38,Y=30,Allocation=1})
s.enqueue({Kind="Join",UserId=3,Username="Late"});s.enqueue({Kind="Expand",UserId=3,X=30,Y=10,Allocation=1});s.step()
assert(not s.Players[1].Attack and s.Grid.Counts[1]==before and s.Players[3].Spectator)
print("Stage 2 two-player authority/replay/replica, contested frontier, radius-4 spawns, cancellation, invalid orders and water barrier passed.")

-- Empty frontier refunds immediately; reserve rounding cannot mint soldiers.
local sealed=fixture(1,1,function() return 128 end)
sealed.enqueue({Kind="Join",UserId=1,Username="Sealed"});sealed.step()
local sp=sealed.Players[1];sp.Troops=25000;sealed.conquer(sp,0)
local empty=Expansion.new(sealed,sp,1234.9);empty.init();assert(sp.Troops==25000 and not empty.isActive())
-- Reinforcement absorbs a retreating stack, so the old delayed execution cannot refund it.
local merge=match();local mp=merge.Players[1]
merge.enqueue({Kind="Expand",UserId=1,X=50,Y=30,Allocation=0.5});merge.step()
local old=mp.Attack;merge.enqueue({Kind="Cancel",UserId=1,AttackID=old.ID});merge.step();merge.step()
merge.enqueue({Kind="Expand",UserId=1,X=50,Y=30,Allocation=0.5});merge.step()
assert(not old.Active and mp.Attack.ID~=old.ID and not mp.Attack.Retreating)
local paid=mp.Troops+mp.Attack.Troops
for _=1,22 do merge.step() end
assert(mp.Troops+(if mp.Attack then mp.Attack.Troops else 0)<paid+22*500,"Absorbed attack refunded twice")

-- Multipart ticks are invisible until the final fragment, then install together.
local r=Replica.new(t);assert(r.begin({ID=1,Tick=0,Count=0,MapHash=t.MaskHash,Meta={}}));assert(r.finish({ID=1}))
local b1,b2=buffer.create(6),buffer.create(6);buffer.writeu32(b1,0,1);buffer.writeu16(b1,4,1);buffer.writeu32(b2,0,2);buffer.writeu16(b2,4,2)
local ok,complete=r.delta({Tick=1,Part=1,Parts=2,Changes=b1});assert(ok and not complete and r.Grid.ownerID(1)==0)
ok,complete=r.delta({Tick=1,Part=2,Parts=2,Changes=b2});assert(ok and complete and r.Grid.ownerID(1)==1 and r.Grid.ownerID(2)==2)
assert(not r.delta({Tick=2,Part=2,Parts=2,Changes=b2}))
print("Stage 2 no-front refunds, merged-retreat protection and atomic fragmented deltas passed.")

-- Representative concurrent frontiers on the full-sized sparse grid, no world scan.
local perf=fixture(8192,4096,function() return 128 end)
for id=1,100 do
 perf.enqueue({Kind="Join",UserId=id,Username="P"..id})
end
perf.enqueue({Kind="Ready",UserId=1})
for id=1,100 do perf.enqueue({Kind="SelectSpawn",UserId=id,X=100+(id%10)*700,Y=100+math.floor(id/10)*300}) end
for _=1,205 do perf.step() end
local durations,totalBytes,maxBytes,totalClaims,pops={},0,0,0,0
local heapPeak=gcinfo()
for tick=1,300 do
 if tick%75==1 then for id=1,100 do perf.enqueue({Kind="Expand",UserId=id,X=8000,Y=4000,Allocation=0.2}) end end
 local began=os.clock();local packet=perf.step();table.insert(durations,os.clock()-began)
 local bytes=buffer.len(packet.Changes);totalBytes+=bytes;maxBytes=math.max(maxBytes,bytes)
 totalClaims+=perf.Work.Claims;pops+=perf.Work.Pops
 heapPeak=math.max(heapPeak,gcinfo())
end
table.sort(durations);local sum=0;for _,v in ipairs(durations) do sum+=v end
print(string.format("Stage 2 100 players/300 ticks: mean %.3f ms, p95 %.3f ms, max %.3f ms; %d claims, %d heap pops; ownership %d bytes; delta mean %.0f B/tick, max %d B; harness Lua heap peak %.0f KiB (includes earlier tests).",sum/#durations*1000,durations[285]*1000,durations[#durations]*1000,totalClaims,pops,perf.Grid.allocatedBytes(),totalBytes/300,maxBytes,heapPeak))
assert(totalClaims>10000 and durations[285]<0.1,"Representative fixture exceeds 100ms p95 tick budget")
print("Performance excludes Roblox transport/GPU and uses flat fixture terrain; actual Earth uses the separately documented NOAA elevation classification.")

local earth=Simulation.new(EarthTerrain,WorldMap,12345,{Stage=2})
for id=1,32 do
 earth.enqueue({Kind="Join",UserId=id,Username="Earth"..id})
 local cell=WorldMap.landAt(math.floor(WorldMap.LandCount*id/33));local x,y=WorldMap.xy(cell)
 earth.enqueue({Kind="SelectSpawn",UserId=id,X=x+0.25,Y=y+0.75})
end
-- Ready must precede selection commands; submit again once phase is active.
earth.enqueue({Kind="Ready",UserId=1});earth.step()
for id=1,32 do local cell=WorldMap.landAt(math.floor(WorldMap.LandCount*id/33));local x,y=WorldMap.xy(cell);earth.enqueue({Kind="SelectSpawn",UserId=id,X=x+0.25,Y=y+0.75}) end
for _=1,204 do earth.step() end
local times,bytes,claims={},0,0
local tx,ty=WorldMap.xy(WorldMap.landAt(1))
for tick=1,120 do
 if tick%40==1 then for id=1,32 do earth.enqueue({Kind="Expand",UserId=id,X=tx,Y=ty,Allocation=0.2}) end end
 local began=os.clock();local packet=earth.step();table.insert(times,os.clock()-began)
 bytes+=buffer.len(packet.Changes);claims+=earth.Work.Claims
 for offset=0,buffer.len(packet.Changes)-1,6 do
  local ref=buffer.readu32(packet.Changes,offset);assert(WorldMap.isLand(ref+1),"Earth expansion crossed water")
 end
end
table.sort(times);local total=0;for _,v in ipairs(times) do total+=v end
print(string.format("Actual Earth 32 players/120 ticks: mean %.3f ms, p95 %.3f ms, max %.3f ms; %d claims; %.0f delta bytes/tick; %d ownership bytes; %d decoded-terrain bytes.",total/120*1000,times[114]*1000,times[120]*1000,claims,bytes/120,earth.Grid.allocatedBytes(),EarthTerrain.cacheBytes()))
assert(claims>1000 and times[114]<0.1)
local cap=Troops.cap(52);local capped={Troops=math.floor(cap)}
for _=1,100 do Troops.add(capped,Troops.growth(capped.Troops,cap)) end
assert(capped.Troops<=cap)
local over={Troops=math.ceil(cap)+100};Troops.add(over,Troops.growth(over.Troops,cap));assert(over.Troops==math.ceil(cap))
assert(Troops.remove({Troops=100},0.99)==0)
