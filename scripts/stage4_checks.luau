for _,v in ipairs(EconomyOracle.profiles) do
 local config={StartingGold="12345",GoldMultiplier=v.multiplier,HostStartingGold="777",HostGoldMultiplier=2.345}
 assert(Economy.initial(v.kind,config,v.host)==v.initial)
 assert(Economy.rate(v.kind,config,v.host)==v.rate,"income formula")
end
local ledger={Gold="0",GoldEarned="0"}
for _,v in ipairs(EconomyOracle.balances) do
 if v.op=="add" then Economy.add(ledger,v.amount) else assert(Economy.remove(ledger,v.amount)==v.removed) end
 assert(ledger.Gold==v.balance and ledger.GoldEarned==v.earned,"BigInt ledger parity")
end
for _,v in ipairs(EconomyOracle.formatting) do assert(MoneyFormat.money(v.n)==v.text,"format "..v.n) end
local function match(config)
 local terrain={Width=128,Height=64,byte=function()return 128 end,MaskHash="economy"}
 local map={cell=function(x,y)return math.floor(y)*128+math.floor(x)+1 end}
 local s=Simulation.new(terrain,map,123,{Stage=4,Economy=config})
 for id=1,2 do s.enqueue({Kind="Join",UserId=id,Username="P"..id}) end;s.step()
 return s,terrain
end
for _,v in ipairs(EconomyOracle.loot) do
 local s=match();local a,b=s.Players[1],s.Players[2];a.Gold="10";b.Gold=v.amount;b.Kind=v.kind;b.AttacksSent=tostring(v.sent)
 s.conquerPlayer(a,b)
 assert(a.Gold==v.winner and b.Gold==v.loser and a.GoldEarned==v.earned,"GameImpl conquest parity")
 s.conquerPlayer(a,b);assert(a.Gold==v.winner,"Repeated conquest duplicated loot")
end
for _,v in ipairs(EconomyOracle.donations) do
 local s=match({DonateGold=v.enabled});local a,b=s.Players[1],s.Players[2]
 s.conquer(a,100);s.conquer(b,200);s.Phase="Started";s.Tick=0;a.Gold="101";b.Gold="19";a.Team="t";b.Team="t"
 -- Establish source history at tick 0, then restore the oracle's starting balances.
 s.Economy.donate(a,b,"1");a.Gold="100";b.Gold="20";b.GoldEarned="0"
 -- Disabled donation must still have source history for cooldown equivalence.
 if not v.enabled then s.Tick=v.tick else s.Tick=v.tick end
 if not v.friendly then b.Team=nil end
 local ok=s.Economy.donate(a,b,v.amount)
 assert(ok==v.success and a.Gold==v.from and b.Gold==v.to and b.GoldEarned==v.earned,"donation parity")
end
print("Stage 4 upstream parity: 90 starting/income profiles, 45 actual GameImpl conquest cases, 24 donation cases, exact BigInt ledger and 16 compact-format boundaries passed.")
-- Fresh orders debit once; retries/old sequence IDs never become new purchases.
local s=match({StartingGold="1000"});local a,b=s.Players[1],s.Players[2]
s.conquer(a,100);s.conquer(b,200);s.Phase="Started";s.StartTick=-100
s.Economy.register("fixture",function()return "300" end)
local receipt,fresh=s.Economy.purchase(a,1,"fixture");assert(receipt.OK and fresh and a.Gold=="700")
receipt,fresh=s.Economy.purchase(a,1,"fixture");assert(receipt.OK and not fresh and a.Gold=="700")
assert(not s.Economy.purchase(a,1,"different").OK)
assert(not s.Economy.purchase(a,0/0,"fixture").OK)
assert(not s.Economy.purchase(a,2,"unknown").OK and a.Gold=="700")
assert(not s.Economy.purchase(a,1,"fixture").OK and a.Gold=="700")
s.Economy.register("expensive",function()return "1001" end)
assert(not s.Economy.purchase(a,3,"expensive").OK and a.Gold=="700")
s.Economy.register("invalid",function()return "-1" end)
assert(not s.Economy.purchase(a,4,"invalid").OK)
s.Economy.register("blocked",function()return "1" end,function()return false end)
assert(not s.Economy.purchase(a,5,"blocked").OK)
a.Spectator=true;assert(not s.Economy.purchase(a,6,"fixture").OK);a.Spectator=false
assert(not s.Economy.purchase({UserId=1},7,"fixture").OK)
assert(not pcall(function()match({StartingGold="1000000001"})end))
assert(not pcall(function()match({GoldMultiplier=0})end))
assert(not pcall(function()match({GoldMultiplier=1001})end))
-- Stats sent counts committed troops, with floor(-refund), not a count of clicks.
a.AttacksSent="0";s.Economy.attackSent(a,5000);s.Economy.attackSent(a,-4999.5);assert(a.AttacksSent=="0")
s.Economy.attackSent(a,-.5);assert(a.AttacksSent=="-1")
-- No countdown money; source recruitment/income scheduler and replay with authoritative purchases.
local function running()
 local sim,terrain=match({StartingGold="7",GoldMultiplier=1.239})
 local p,q=sim.Players[1],sim.Players[2]
 sim.conquer(p,20*128+20);sim.conquer(q,40*128+80)
 sim.startRecruitment(p);sim.startRecruitment(q)
 for _=1,10 do sim.step() end;assert(p.Gold=="7" and p.GoldEarned=="0","income during spawn")
 sim.Phase="Started";sim.StartTick=sim.Tick;sim.step() -- pending player execution init
 sim.Economy.register("fixture",function()return "100" end)
 return sim,terrain
end
local left,t=running();local right=running();local r=Replica.new(t);local keys=left.Grid.chunkKeys()
assert(r.begin({ID=1,Tick=left.Tick,Count=#keys,MapHash=t.MaskHash,Meta=left.metadata()}))
for _,key in ipairs(keys) do assert(r.chunk({ID=1,Key=key,Data=left.Grid.copyChunk(key)})) end;assert(r.finish({ID=1}))
for tick=1,300 do
 if tick==50 or tick==51 then for _,v in ipairs({left,right}) do v.enqueue({Kind="Purchase",UserId=1,Sequence=1,Product="fixture"}) end end
 if tick==100 then for _,v in ipairs({left,right}) do v.conquer(v.Players[1],20*128+21) end end
 local packet=left.step();local other=right.step();assert(r.delta(packet))
 assert(buffer.tostring(packet.Changes)==buffer.tostring(other.Changes))
 for id=1,2 do assert(left.Players[id].Gold==right.Players[id].Gold) end
 local expected=tostring(7+123*tick-(if tick>=51 then 100 else 0))
 assert(left.Players[1].Gold==expected,"fixed income/replay "..tick)
 assert(left.Players[2].Gold==tostring(7+123*tick),"territory/population must not change income")
end
left.relinquish(left.Players[2],40*128+80);left.step();assert(left.Players[2].Gold=="0","death clears gold")
left.step();assert(left.Players[2].Gold=="0")
assert(left.stats()[2].GoldIncome=="0","dead player HUD income")
print("Stage 4 transaction validation/idempotency, config limits, net attack statistics, 300-tick multiplayer replay, fixed territory-independent income, no countdown income and death cleanup passed.")
-- Incremental economy work has no map access; profile 100 players x 1000 ticks.
do
 local sim={Players={},Grid={Counts={}},Phase="Started",Tick=0};local e=Economy.new(sim,{})
 for i=1,100 do local p={UserId=i,SmallId=i,Kind="Human"};sim.Players[i]=p;e.init(p) end
 local times={};local total=0;local before=gcinfo()
 for tick=1,1000 do local start=os.clock();for i=1,100 do e.tick(sim.Players[i]) end;local ms=(os.clock()-start)*1000;times[tick]=ms;total+=ms end
 table.sort(times);for _,p in pairs(sim.Players) do assert(p.Gold=="100000" and p.GoldEarned=="100000") end
 print(string.format("Stage 4 income-only 100 players/1000 ticks: mean %.3f ms p95 %.3f max %.3f; harness heap before %.0f / after %.0f KiB; no grid reads.",total/1000,times[950],times[1000],before,gcinfo()))
end
-- Live attack/conquest and connectivity hooks, not just isolated loot formulas.
do
 local sim=match();local a,b=sim.Players[1],sim.Players[2]
 for y=10,19 do for x=10,29 do sim.conquer(if x<25 then a else b,y*128+x) end end
 sim.Phase="Started";sim.StartTick=-100;a.Gold="100";b.Gold="999";b.AttacksSent="100";b.Troops=0
 local attack=Expansion.new(sim,a,25000,b);attack.init();attack.tick()
 assert(b.Eliminated and b.Gold=="0" and a.Gold=="599","attack conquest loot hook")
 local enclosed=match();local inner,outer=enclosed.Players[1],enclosed.Players[2]
 for y=10,30 do for x=10,30 do enclosed.conquer(if x==10 or x==30 or y==10 or y==30 then outer else inner,y*128+x) end end
 inner.Gold="1001";inner.AttacksSent="1";outer.Gold="10"
 Connectivity.new(enclosed,inner).removeClusters()
 assert(inner.Eliminated and inner.Gold=="0" and outer.Gold=="510","encirclement loot hook")
end
print("Stage 4 actual attack/remnant and encirclement conquest accounting hooks passed.")

do
 local w,h=8192,4096;local terrain={Width=w,Height=h,byte=function()return 128 end,MaskHash="heavy"}
 local s=Simulation.new(terrain,{cell=function(x,y)return math.floor(y)*w+math.floor(x)+1 end},53,{Stage=4})
 for id=1,100 do s.enqueue({Kind="Join",UserId=id,Username="P"..id}) end;s.step();s.Phase="Started";s.StartTick=-100
 for pair=0,49 do
  local ox=10+(pair%10)*90;local oy=10+math.floor(pair/10)*90
  for y=oy,oy+59 do for x=ox,ox+59 do s.conquer(s.Players[pair*2+(if x<ox+30 then 1 else 2)],y*w+x) end end
 end
 for _,p in pairs(s.Players) do p.Troops=500000;s.startRecruitment(p) end
 for pair=0,49 do s.Executions.add(Expansion.new(s,s.Players[pair*2+1],150000,s.Players[pair*2+2])) end
 s.Grid.discardChanges();local times={};local total,clusterTotal,bytes,peakBytes,claims=0,0,0,0,0
 for _=1,240 do
  local start=os.clock();local packet=s.step();local elapsed=(os.clock()-start)*1000;table.insert(times,elapsed);total+=elapsed
  clusterTotal+=s.Work.ConnectivityMilliseconds or 0;local n=buffer.len(packet.Changes);bytes+=n;peakBytes=math.max(peakBytes,n);claims+=s.Work.Claims
 end
 table.sort(times)
 print(string.format("Heavy Stage 4: 100 players/50 fronts/180000 initial cells/240 ticks WITH income+recruitment+connectivity: mean %.3f ms p95 %.3f max %.3f; cluster CPU %.1f ms total; %d captures; delta mean %.0f B max %d B; ownership %d B; shared scratch %d B; cumulative harness heap %.0f KiB.",total/240,times[228],times[240],clusterTotal,claims,bytes/240,peakBytes,s.Grid.allocatedBytes(),s.Traversal.bytes(),gcinfo()))
end

for _,v in ipairs(EconomyOracle.costs) do
 local sim=match({StartingGold="1000",InfiniteGold=v.infinite,HostInfiniteGold=true})
 local p=sim.Players[1];p.Kind=v.kind;p.IsHost=v.host;sim.Phase="Started";sim.conquer(p,100)
 sim.Economy.register("fixture",function()return "150" end)
 local receipt=sim.Economy.purchase(p,1,"fixture")
 assert(receipt.OK and receipt.Cost==v.cost and p.Gold==Gold.subtract("1000",v.cost),"source cost-wrapper infinite gold semantics")
end
print("Stage 4 12 source cost-wrapper human/nation/bot and host/infinite-gold cases passed; no balance infinity or building created.")

do
 local sim=match({StartingGold="10",HostUserId=1,HostStartingGold="20",HostGoldMultiplier=2})
 assert(sim.Players[1].Gold=="30" and sim.Players[2].Gold=="10")
 assert(sim.Economy.income(sim.Players[1])=="200" and sim.Economy.income(sim.Players[2])=="100")
 assert(not sim.Economy.purchase(sim.Players[1],1,{}).OK)
end
print("Server-configured host identity and malformed product validation passed.")
