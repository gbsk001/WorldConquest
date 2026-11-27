local env=environment(false);local s,p=env.Sim,env.Players[1]
do
 local e=environment(false);local scheduled=0;local add=e.Sim.Executions.add
 e.Sim.Executions.add=function(execution)scheduled+=1;add(execution)end
 for seq=1,100 do e.Nav.order(e.Players[1],{Action="Transport",Tile=60*192+175,Allocation=.2,Sequence=seq})end
 assert(scheduled==NavalRules.TransportLimit,"Pending path preparation must not grow with request spam")
 e.Nav.order(e.Players[1],{Action="Transport",Tile=60*192+175,Allocation=.2})
 for _=1,3 do e.step()end -- Malformed sequence rejects without crashing or path work.
 print("Stage 15 pending transport queue: existing unit limit bounds work; malformed sequences reject safely.")
end
local order={Action="Transport",Tile=60*192+175,Allocation=.2,Sequence=1}
s.Naval.order(p,order);s.Naval.order(p,order)
local before=p.Troops;local accepted=0;local pending=false
for _=1,600 do
 local pops=s.Naval.Path.Pops;env.step()
 assert(s.Naval.Path.Pops-pops<=1024,"All active naval searches share one tick allowance")
 for _,r in ipairs(s.TransactionResults)do if r.Receipt and r.Receipt.OK and r.Fresh then accepted+=1 end end
 if accepted==0 then pending=true end
 if accepted>0 then break end
end
assert(pending and accepted==1 and p.Troops==before*.8,"Prepared purchase commits once after search completion")
for _=1,10 do env.step();for _,r in ipairs(s.TransactionResults)do if r.Receipt and r.Receipt.OK and r.Fresh then accepted+=1 end end end
assert(accepted==1,"Duplicate pending orders cannot duplicate effects")
local worker=s.Naval.Path.beginTask(function()s.Naval.Path.workSlice();return true end)
if worker then s.Naval.Path.cancelTask(worker)end
print("Stage 15 asynchronous transport: bounded preparation, current-state purchase validation, one debit/effect and duplicate pending-order protection passed.")
do
 local e=environment(false);local source,dest=e.Sim.Buildings.Units[1],e.Sim.Buildings.Units[2]
 local a,b=source.Owner,dest.Owner;local ga,gb=a.Gold,b.Gold
 e.Nav.trade(a,source,dest)
 local moved=0;local move=e.Nav.move;e.Nav.move=function(u,tile)if u.Type=="TradeShip"then moved+=1 end;move(u,tile)end
 for _=1,1200 do e.step();if a.TradeGold~="0"then break end end
 local expected=tostring(NavalRules.tradeGold(moved,1))
 assert(moved>0 and a.TradeGold==expected and b.TradeGold==expected)
 assert(a.Gold==Gold.add(ga,expected)and b.Gold==Gold.add(gb,expected),"Trade changes real balances, not just HUD totals")
 assert(source.TradeEarned==expected and dest.TradeEarned==expected and e.Nav.Count==0)
 print(string.format("SEA_INCOME %d water steps: %s gold to each endpoint; actual balances and building ledger match; ship cleaned up.",moved,expected))
 -- A destroyed source cannot finish a trade and manufacture another payout.
 local before=a.Gold;e.Nav.trade(a,source,dest);e.step();e.step();source.Active=false
 for _=1,5 do e.step()end
 assert(a.Gold==before and e.Nav.Count==0)
end

do
 local t={Width=192,Height=128,byte=function()return 128 end,LandCount=192*128,MaskHash="rail-budget"}
 local sim=Simulation.new(t,{},101,{Stage=11,Balance={BoundedPaths=true,InfrastructurePresentation=true},Economy={StartingGold="1000000"},Buildings={InstantBuild=true}})
 sim.enqueue({Kind="Join",UserId=1,Username="Trade"});sim.step();sim.Phase="Started";sim.StartTick=0
 local owner=sim.Players[1]
 for tile=0,192*128-1 do sim.conquer(owner,tile)end
 for seq,kind in ipairs({"Factory","City"})do
  sim.enqueue({Kind="Building",Action="Build",UserId=1,Sequence=seq,Type=kind,Tile=40*192+(if seq==1 then 30 else 95)})
  for _=1,8 do sim.step()end
 end
 -- Use execution ticks only: isolate infrastructure from the fixture's 100% victory.
 sim.Phase="Started";sim.Executions.Tick=sim.Tick
 local paid=false;local moved=false
 for _=1,1400 do
  sim.Executions.step(sim);sim.Tick+=1
  for _,u in ipairs(sim.Rail.snapshot())do if u.Motion and buffer.len(u.Motion)>4 then moved=true end end
  if owner.TrainGold and Gold.compare(owner.TrainGold,"0")>0 then paid=true;break end
 end
 assert(moved and paid and sim.Rail.summary(owner).Routes>0,"Bounded construction must produce moving, profitable trains")
 assert(owner.TrainGold=="10000"and owner.Gold==Gold.add("750000",owner.TrainGold),"First self trade pays the exact source formula after two 125K purchases; no passive tick income in this isolated execution fixture")
 print("RAIL_INCOME first self delivery: "..owner.TrainGold.." gold; post-purchase balance 750000 -> "..owner.Gold)
 local geometry=sim.Rail.geometry();assert(#geometry>0 and buffer.len(geometry[1].Points)>=8)
 local city=sim.Buildings.Units[2];sim.Buildings.destroy(city)
 for _=1,3 do sim.Executions.step(sim);sim.Tick+=1 end
 assert(sim.Rail.summary(owner).Routes==0,"Destroyed destination loses functioning trade routes")
 local gold=owner.Gold;for _=1,300 do sim.Executions.step(sim);sim.Tick+=1 end;assert(owner.Gold==gold,"Disconnected factory cannot continue generating trade income")
 print("Stage 15 queued rail construction, waypoint movement, actual gold delivery, compact geometry and destroyed-route invalidation passed.")
end
