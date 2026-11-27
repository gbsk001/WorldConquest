-- Small functional fixtures only. Large Earth populations belong to the opt-in load runner.
do
 local t={Width=16,Height=8,LandCount=128,MaskHash="victory-basic",byte=function()return 128 end}
 local s=Simulation.new(t,{},1,{Stage=11,Match={WinThresholdTenths=800}})
 s.enqueue({Kind="Join",UserId=1,Username="Winner"});s.enqueue({Kind="Join",UserId=-1,Username="Grey",IsBot=true,BasicNation=true,StartingTroops=700});s.step()
 local p,b=s.Players[1],s.Players[-1];s.Phase="Started";s.StartTick=0;p.Spawn=1;b.Spawn=128
 for tile=0,126 do s.conquer(p,tile)end;s.conquer(b,127)
 s.Tick=10;s.Match.tick();assert(s.Match.Winner.UserId==1 and #s.Match.Rankings==1,"A remaining grey nation cannot become a competitor or block the normal threshold")
 s.conquer(p,127);assert(b.Eliminated);s.Match.remember(b);s.Players[-1]=nil
 s.Tick=40;s.Match.tick();assert(s.Phase=="Results"and #s.Match.Rankings==1)
 local fresh=Simulation.new(t,{},2,{Stage=11});assert(next(fresh.Players)==nil and next(fresh.Rail.Rails)==nil and fresh.Rail.TrainUnits==0 and fresh.BasicNations.Count==0)
 print("Stage 15 basic-nation elimination, competitive victory/results exclusion and fresh-round infrastructure isolation passed.")
end
do
 local terrain={Width=512,Height=256,MaskHash="stage15",byte=function()return 128 end,LandCount=512*256}
 local map={LandCount=terrain.LandCount,cell=function(x,y)return if x>=0 and y>=0 and x<512 and y<256 then math.floor(y)*512+math.floor(x)+1 else nil end}
 local function run(seed)
  local s=Simulation.new(terrain,map,seed,{Stage=11,Balance={StartingSoldiers=5000,RecruitmentMultiplier=.5,ProactiveAI=true,BoundedPaths=true},Bots={Enabled=true,Count=2},BasicNations={Enabled=true,Count=6,SafeCount=6},Match={}})
  s.enqueue({Kind="Join",UserId=1,Username="Human"});s.enqueue({Kind="Ready",UserId=1});s.step();assert(s.Players[1].Troops==5000)
  for _=1,205 do s.step()end
  local basic=0;local snapshots={};local total=0
  for id,p in pairs(s.Players)do
   assert(p.Spawn and s.Grid.isLand(p.Spawn-1));snapshots[id]=p.Spawn;total+=s.Grid.Counts[p.SmallId]or 0
   if p.BasicNation then basic+=1;assert(p.Kind=="Bot"and p.Gold=="0"and p.Troops<1600)end
  end
  assert(basic==6 and s.BasicNations.Count==6)
  local seen={};for _,p in pairs(s.Players)do p.Tiles.each(function(t)assert(not seen[t]);seen[t]=true end)end
  for _=1,240 do s.step()end
  local expanded=0;local hash=0
  for _,p in pairs(s.Players)do
   if p.BasicNation then assert(#p.BuildingUnits==0 and #p.Ships==0 and p.Gold=="0");expanded+=math.max(0,(s.Grid.Counts[p.SmallId]or 0)-#p.SpawnCells)end
   hash=(hash+(s.Grid.Counts[p.SmallId]or 0)*p.SmallId+p.Troops)%2147483647
  end
  assert(expanded>0 and s.Bots.Orders>0,"Both AI paths must make progress")
  for _,r in ipairs(s.Match.Rankings)do assert(not s.Players[r.UserId].BasicNation)end
  assert(#s.stats()==1,"Basic and competitive bots have no private remote HUD")
  return hash,snapshots
 end
 local a,spawns=run(17);local b,again=run(17);assert(a==b)
 for id,t in pairs(spawns)do assert(again[id]==t)end
 local _,different=run(18);local varied=0;for id,t in pairs(spawns)do if different[id]~=t then varied+=1 end end;assert(varied>=6)
 local s=Simulation.new(terrain,map,1,{Stage=11,BasicNations={Enabled=true,Count=350,SafeCount=0}});assert(s.BasicNations.Count==0)
 print("Stage 15: small dual-AI roster, configured balances, staggered valid spawns, disjoint footprints, expansion, no basic infrastructure, competitive rankings and seeded replay passed.")
end
do
 local terrain={Width=48,Height=24,byte=function()return 63 end}
 local grid=Grid.new(48,24,terrain.byte);local expected=WaterPath.new(grid,terrain).route(0,48*24-1,true)
 local path=WaterPath.new(grid,terrain);local tick=0;path.configureBudget(function()return tick end,64)
 local step=path.stepper(true);local tile=0;local moves={tile};local waits=0
 for _=1,2000 do
  tick+=1;local before=path.Pops;local status,nextTile=step.next(tile,48*24-1)
  assert(path.Pops-before<=64,"Bounded work must be deterministic, not wall-clock dependent")
  if status=="PENDING"then waits+=1 elseif status=="NEXT"then tile=nextTile;table.insert(moves,tile)elseif status=="COMPLETE"then break else error(status)end
 end
 assert(waits>0 and #moves==#expected);for i,t in ipairs(expected)do assert(moves[i]==t)end
 local x=path.beginTask(function()path.workSlice();return 7 end);assert(x);local done,v=path.resumeTask(x);if not done then tick+=1;done,v=path.resumeTask(x)end;assert(done and v==7)
 print("Stage 15: bounded naval search yields, retains exact synchronous route, completes and releases worker slots.")
end
do
 local grid=Grid.new(64,64,function()return 128 end)
 local baseline=RailPath.land(grid,0,60*64+60,160)
 local yields=0;local thread=coroutine.create(function()return RailPath.land(grid,0,60*64+60,160,function()coroutine.yield()end)end)
 local result
 repeat local ok,v=coroutine.resume(thread);assert(ok,v);result=v;yields+=1 until coroutine.status(thread)=="dead"
 assert(yields>1 and #baseline==#result);for i,t in ipairs(baseline)do assert(result[i]==t)end
 assert(Gold.divideSmall("999999999999999999999999999999",30)=="33333333333333333333333333333")
 local sim={Tick=100,StartTick=0,Phase="Started",Grid={Counts={[1]=1}},Players={}}
 local e=Economy.new(sim,{});local p={SmallId=1,UserId=1,Kind="Human",BuildingUnits={},ShipCounts={}};sim.Players[1]=p;e.init(p)
 Economy.recordTrade(p,"10000","Rail",100);Economy.recordTrade(p,"20000","Sea",100)
 local summary=e.summary(p);assert(summary.Base=="1000"and summary.Rail=="1000"and summary.Sea=="2000"and summary.Total=="4000"and p.Gold=="0")
 sim.Tick=410;summary=e.summary(p);assert(summary.Rail=="0"and summary.Sea=="0","Expired deliveries cannot manufacture passive income")
 print("Stage 15: bounded rail search preserves exact route; exact-decimal rolling trade totals expire without granting gold.")
end
