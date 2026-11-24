-- Golden values are produced by actual pinned TypeScript, not the Luau implementation.
for _,case in ipairs(FidelityOracle.profiles) do
 local options={Tutorial=case.tutorial,Infinite=case.infinite}
 local cap=Troops.cap(1234,case.cities,case.kind,case.difficulty,options)
 assert(cap==case.cap,"Type/difficulty cap parity")
 assert(Troops.growth(25000,cap,case.kind,case.difficulty)==case.growth,"Type/difficulty growth parity")
 assert(Troops.initial(case.kind,case.difficulty,options)==case.initial,"Initial manpower parity")
 assert(Troops.attackAmount(25000,case.kind)==case.allocation,"Default allocation parity")
 local loss,fraction=Troops.neutral("Highland",5000,7,case.kind,0.25)
 assert(loss==case.loss and fraction==case.fraction,"Bot/fallout neutral parity")
end
local terrain={Width=64,Height=48,MaskHash="spawn-fixture",byte=function(t)
 if t%64<3 or t%64==32 then return 0 end
 return if t%64>=50 and math.floor(t/64)<10 then 159 else 128
end}
local sim=Simulation.new(terrain,{},51,{Stage=2})
for id=1,3 do sim.enqueue({Kind="Join",UserId=id,Username="P"..id}) end
sim.step()
local executions=0
sim.startRecruitment=function() executions+=1 end
for index,snapshot in ipairs(FidelityOracle.spawns) do
 local action=snapshot.action;local p=sim.Players[action.id]
 sim.Phase=if action.before then "Selecting" else "Started"
 local e=SpawnExecution.new(sim,p,action.tile,action.intent)
 e.init();sim.Phase=if action.after then "Selecting" else "Started";e.tick()
 assert(not e.isActive())
 assert(executions==snapshot.executions,"Duplicate PlayerExecution at "..index)
 for _,expected in ipairs(snapshot.players) do
  local actual=sim.Players[expected.id]
  assert(actual.Spawn==(if expected.center then expected.center+1 else nil),"Spawn centre mismatch "..index)
  local cells=actual.SpawnCells or {}
  assert(#cells==#expected.cells,"Spawn size mismatch "..index)
  for i,t in ipairs(expected.cells) do assert(cells[i]==t and sim.Grid.ownerID(t)==actual.SmallId,"Spawn BFS/restore order mismatch "..index) end
  assert((sim.Grid.Counts[actual.SmallId] or 0)==#expected.cells)
 end
end
-- Source retreat remains scheduled until the deadline even if the absorbed attack disappeared.
local p={Attack=nil};local s={Tick=10}
local retreat=RetreatExecution.new(s,p,9);retreat.init()
for tick=11,29 do s.Tick=tick;retreat.tick();assert(retreat.isActive()) end
s.Tick=30;retreat.tick();assert(not retreat.isActive())
print("Source-fidelity parity: 96 human/bot/nation/difficulty/tutorial/cheat/city profiles; 10 SpawnExecution snapshots including random, overlap, failed restore, invalid and last-tick intents; retreat lifecycle passed.")
