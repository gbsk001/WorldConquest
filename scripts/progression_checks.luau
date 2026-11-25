local now=100*86400;local p=Rules.new()
local ok=Rules.apply(p,"Buy","missile_pearl",now);assert(not ok and p.Stars==0)
assert(not Rules.apply(p,"Equip","missile_founder",now))
assert(Rules.apply(p,"Daily",nil,now));assert(p.Stars==25)
assert(not Rules.apply(p,"Daily",nil,now));assert(not Rules.apply(p,"Daily",nil,now-86400))
for i=1,6 do assert(Rules.apply(p,"Daily",nil,now+i*86400))end
assert(p.Owned.badge_week and p.Daily.Streak==7)
assert(Rules.apply(p,"Daily",nil,now+8*86400));assert(p.Daily.Streak==1)
assert(Rules.apply(p,"Buy","missile_pearl",now));assert(Rules.apply(p,"Equip","missile_pearl",now));assert(p.Equipped.Missile=="missile_pearl")
local stars=p.Stars;assert(not Rules.apply(p,"Buy","missile_pearl",now)and p.Stars==stars)
assert(Rules.apply(p,"Unequip","Missile",now));assert(p.Equipped.Missile==nil)
local reward={ID="public:1",Time=now,Eligible=false,Won=true,Territory=15000,Soldiers=3000,HumanEliminations=1}
assert(not Rules.apply(p,"Match",reward,now));reward.Eligible=true
assert(Rules.apply(p,"Match",reward,now));assert(p.Stats.Wins==1 and p.Stats.Matches==1 and p.Stats.HumanEliminations==1 and p.Owned.flag_victor)
stars=p.Stars;assert(not Rules.apply(p,"Match",reward,now));assert(stars==p.Stars)
reward.ID="expired";assert(not Rules.apply(p,"Match",reward,now+86401))
assert(Rules.apply(p,"Receipt",{ID="receipt:1",Stars=500},now));stars=p.Stars
assert(not Rules.apply(p,"Receipt",{ID="receipt:1",Stars=500},now));assert(stars==p.Stars)
assert(Rules.apply(p,"Entitlement",{Key="Starter",Items={"missile_founder","flag_founder","badge_founder"}},now))
assert(not Rules.apply(p,"Entitlement",{Key="Starter",Items={"missile_founder"}},now))
local saved={};local fail=false;local retries=0
local ds={UpdateAsync=function(_,key,fn)
 if fail then error("throttled")end
 local first=fn(saved[key]);local second=fn(saved[key]);retries+=1
 assert(first.Stars==second.Stars,"UpdateAsync callback must be retry-safe");saved[key]=second;return second
end}
local a=ProfileStore.new(ds,function()return now end);local b=ProfileStore.new(ds,function()return now end)
assert(a.transact(1,"Daily"));assert(b.transact(1,"Daily"));assert(saved.u1.Stars==25)
fail=true;local failed=a.transact(1,"Daily");assert(not failed and saved.u1.Stars==25);fail=false
assert(a.transact(1,"Receipt",{ID="abc",Stars=500}));assert(b.transact(1,"Receipt",{ID="abc",Stars=500}));assert(saved.u1.Stars==525)
saved.u2={Version=99};assert(not a.transact(2));assert(saved.u2.Version==99)
local concurrent={};local second=nil;local interleave=true
local concurrentDS={UpdateAsync=function(_,key,fn)
 if interleave then
  interleave=false;fn(concurrent[key]) -- first server's initial, uncommitted attempt
  assert(second.transact(7,"Receipt",{ID="same-payment",Stars=5000}))
 end
 concurrent[key]=fn(concurrent[key]);return concurrent[key]
end}
local first=ProfileStore.new(concurrentDS,function()return now end);second=ProfileStore.new(concurrentDS,function()return now end)
assert(first.transact(7,"Receipt",{ID="same-payment",Stars=5000}));assert(concurrent.u7.Stars==5000,"interleaved servers must grant once")
local parties=PartyState.new();local group=parties.create("p",1)
assert(parties.add("p",2));assert(not parties.add("p",2));assert(not parties.remove(1,2))
for id=3,6 do assert(parties.add("p",id))end;assert(not parties.add("p",7))
group.Queued=true;assert(not parties.remove(2,1));group.Queued=false
assert(parties.remove(1,1));assert(group.Leader==2);assert(parties.remove(3,2));assert(not parties.remove(4,7))
local started=os.clock();for i=1,10000 do local q=Rules.new();Rules.apply(q,"Daily",nil,now)end
print(string.format("Stage 13 rules: ownership, balance, UTC daily calendar, duplicate match/receipt/pass grants, retries, failure-closed saves, schema safety and party permissions passed. 10,000 fresh profile/daily operations: %.2f ms (local CPU).",(os.clock()-started)*1000))
