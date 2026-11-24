local function eq(a,b,label)
 if typeof(a)~=typeof(b) then error(label..': type mismatch') end
 if typeof(a)=='table' then assert(#a==#b,label..': length '..#a..'/'..#b);for k,v in pairs(a) do eq(v,b[k],label..'.'..tostring(k)) end
 elseif a~=b then error(label..': '..tostring(a)..' != '..tostring(b)) end
end
do
 for _,state in ipairs({0,8192,65535}) do
  local raw=buffer.create(8064);for i=0,1343 do buffer.writeu32(raw,i*6,i*3);buffer.writeu16(raw,i*6+4,state) end
  local encoded,value=Grid.compressChanges(raw);eq(value,state,'uniform state');eq(buffer.len(encoded),5376,'uniform size')
  eq(buffer.tostring(Grid.expandChanges(encoded,value,4096)),buffer.tostring(raw),'exact uniform round trip')
  buffer.writeu16(raw,4,1);local mixed,flag=Grid.compressChanges(raw);assert(flag==nil and mixed==raw,'mixed fallback')
 end
 for _,v in ipairs({false,{},'8192',-1,65536,0/0,math.huge}) do assert(Grid.expandChanges(buffer.create(4),v,100)==nil) end
 assert(Grid.expandChanges(buffer.create(3),0,100)==nil and Grid.expandChanges(buffer.create(8),0,1)==nil)
 local terrain={Width=64,Height=64,MaskHash='uniform-wire',byte=function()return 128 end};local r=Replica.new(terrain)
 assert(r.begin({ID=1,Tick=0,Count=0,MapHash=terrain.MaskHash,Meta={MatchID=1,Stage=8}}));assert(r.finish({ID=1}))
 for part=1,2 do
  local raw=buffer.create(96);for i=0,15 do buffer.writeu32(raw,i*6,(part-1)*16+i);buffer.writeu16(raw,i*6+4,8192) end
  local encoded,value=Grid.compressChanges(raw)
  assert(r.delta({MatchID=1,Tick=1,Part=part,Parts=2,Changes=encoded,UniformState=value}))
  if part==1 then eq(r.Grid.FalloutCount,0,'fragment atomicity') end
 end
 eq(r.Grid.FalloutCount,32,'compressed replica fallout');eq(r.Tick,1,'compressed replica tick')
 local page=r.Grid.copyChunk(0)
 assert(r.begin({ID=2,Tick=1,Count=1,MapHash=terrain.MaskHash,Meta={MatchID=1,Stage=8}}))
 local refs=buffer.create(64);for i=0,15 do buffer.writeu32(refs,i*4,i+32) end
 assert(r.delta({MatchID=1,Tick=2,Changes=refs,UniformState=8192}))
 assert(r.chunk({ID=2,Key=0,Data=page}));assert(r.finish({ID=2}));eq(r.Grid.FalloutCount,48,'compressed snapshot catch-up')
 print('Uniform-state transport: exact order/state round trips, mixed fallback and malformed/oversized rejection passed.')
end
for i,v in ipairs(Oracle8.paths) do
 local g=Grid.new(v.w,v.h,function()return 128 end)
 eq(MissilePath.mirvSpeed(g,v.a,v.b),v.mirv,'MIRV speed '..i)
 eq(MissilePath.route(g,v.a,v.b,v.s),v.path,'curve '..i)
end
for _,v in ipairs(Oracle8.deaths) do eq(MissileRules.deaths(v.kind,v.troops,v.tiles,v.cap),v.value,'casualties') end
for _,v in ipairs(Oracle8.ranges) do eq(MissileRules.range(v.level),v.value,'SAM range') end
for _,v in ipairs(Oracle8.thresholds) do eq(Match.threshold(v.seconds,{Overtime={Enabled=v.enabled}}),v.value,'threshold') end
for _,kind in ipairs({'AtomBomb','HydrogenBomb','MIRVWarhead'}) do for _,troops in ipairs({0,1,12345,99999.234,1000000}) do
 for _,loss in ipairs({0,1,5,5000}) do for _,remaining in ipairs({0,10000}) do for _,integer in ipairs({true,false}) do
  local expected=troops
  for i=0,loss-1 do local deaths=MissileRules.deaths(kind,expected,remaining+loss-i,123456);expected=math.max(0,expected-(if integer then math.floor(deaths) else deaths)) end
  eq(MissileRules.damageStack(kind,troops,loss,remaining,123456,integer),expected,'independent damage stack exact arithmetic')
 end end end
end end
local function environment(w,h,impassable,options,instant)
 local terrain={Width=w,Height=h,MaskHash='missile-test',byte=function(t)return if impassable and t%97==0 then 159 else 128 end}
 local map={LandCount=w*h};function map.cell(x,y)if typeof(x)=='number' and typeof(y)=='number' and x==x and y==y and x>=0 and y>=0 and x<w and y<h then return math.floor(y)*w+math.floor(x)+1 end;return nil end
 local sim=Simulation.new(terrain,map,91,{Stage=8,Economy={StartingGold='999999999'},Buildings={InstantBuild=instant~=false},Match=options})
 for id=1,2 do sim.enqueue({Kind='Join',UserId=id,Username='P'..id}) end;sim.step()
 sim.Phase='Started';sim.StartTick=0;sim.Tick=100;sim.Executions=Executions.new();sim.Executions.Tick=100
 for _,p in pairs(sim.Players) do p.Troops=100000;p.Spawn=1 end
 return sim,terrain
end
do
 for _,v in ipairs(Oracle8.blast) do
  local s=environment(256,256)
  local function blocked(t)return if v.mode==1 then t%97==0 elseif v.mode==2 then t%256==130 else false end
  s.Grid.isImpassable=blocked;s.Grid.terrainUnchecked=function(t)return if blocked(t) then 159 else 128 end
  eq(s.Missiles.blastTiles(v.dst,v.kind,v.tick),v.tiles,'blast '..v.kind..v.tick..':'..v.mode..':'..v.dst)
  eq(s.Missiles.blastTiles(v.dst,v.kind,v.tick),v.tiles,'cached blast')
 end
end
print('Stage 8 executable upstream parity: 140 exact trajectories/MIRV speeds, 54 ordered blast footprints (clear/blocked/clipped/cache), 48 casualty formulas, 100 SAM ranges, 16 victory thresholds passed.')
for _,v in ipairs(Oracle8.mirv) do
 local s=environment(v.w,v.h);s.Match=nil;local plans,moved={},{}
 s.Grid.ownerID=function(t)return if t%v.w>=300 and math.floor(t/v.w)>=200 and math.floor(t/v.w)<=(if v.scenario==3 then 3900 else 900) and not (v.scenario==1 and s.Tick>=104 and t%v.w>500) then 2 else 0 end
 local move=s.Naval.move;function s.Naval.move(u,t)if u.Type=='MIRV' then table.insert(moved,{s.Tick,t}) end;move(u,t) end
 local delete=s.Naval.delete;function s.Naval.delete(u)if u.TestPlan then u.Active=false;u.TestPlan.cancelled=true else delete(u) end end
 function s.Missiles.fly(_,kind,src,dst,speed,wait)
  assert(kind=='MIRVWarhead');local plan={tick=s.Tick,src=src,dst=dst,speed=speed,wait=wait,cancelled=false};table.insert(plans,plan);return {Active=true,TestPlan=plan}
 end
 local carrier=s.Missiles.mirv(s.Players[1],v.src,v.dst)
 while s.Tick<170 do if v.scenario==2 and s.Tick==104 or v.scenario==4 and s.Tick==120 then s.Naval.delete(carrier) end;s.step() end
 eq(moved,v.moved,'MIRV motion '..v.scenario);eq(plans,v.plans,'MIRV target/speed/delay/revalidation '..v.scenario)
end
print('Full upstream MIRV execution traces: ordered destinations, motion, speed, wait ticks, ownership revalidation and external cancellation passed.')
assert(#Oracle8.mirv[4].plans==350,'full MIRV cap fixture')
do local s=environment(512,256)
 for _,v in ipairs(Oracle8.sam) do
  local sam={Tile=v.tile,Level=v.level,SAMUpgrade=if v.upgrade then {Tick=95,Range=MissileRules.range(math.max(1,v.level-1))} else nil}
  local u={Trajectory=MissilePath.route(s.Grid,v.src,v.dst,v.speed),Index=v.index,Wait=v.wait}
  local tick,tile=s.Missiles.interceptionPlan(sam,u);eq(tick,v.tick,'SAM schedule');if tick>=0 then eq(tile,v.target,'SAM intercept tile') end
 end
end
print('100 original predictive SAM schedules/target tiles, including waits, upgrades and unreachable paths, passed.')
local function own(s,p,x0,y0,x1,y1)for y=y0,y1 do for x=x0,x1 do s.conquer(p,y*s.Grid.Width+x) end end end
local function build(s,p,kind,tile,seq)
 s.enqueue({Kind='Building',Action='Build',UserId=p.UserId,Type=kind,Tile=tile,Sequence=seq});s.step();s.step()
 for _,u in ipairs(p.BuildingUnits) do if u.Type==kind then return u end end;error('failed building '..kind)
end
do
 local s=environment(256,256,false,nil,false);s.Match=nil;local p=s.Players[1];own(s,p,20,20,100,100)
 local silo=build(s,p,'MissileSilo',50*256+50,1);assert(silo.UnderConstruction);assert(not s.Missiles.source(p,'AtomBomb',150*256+150))
 for _=1,100 do s.step() end;assert(silo.UnderConstruction);s.step();assert(not silo.UnderConstruction,'silo construction completes after source counter')
 local sam=build(s,p,'SAMLauncher',80*256+80,2);assert(sam.UnderConstruction)
 for _=1,300 do s.step() end;assert(sam.UnderConstruction);s.step();assert(not sam.UnderConstruction,'SAM construction')
 local old=MissileRules.range(1);s.enqueue({Kind='Building',Action='Upgrade',UserId=1,UnitID=sam.ID,Sequence=3});s.step()
 eq(sam.Level,2,'SAM level');assert(#sam.MissileQueue==1);eq(MissileRules.dynamicRange(sam,s.Tick-1),old,'upgrade starts at old range')
 eq(MissileRules.dynamicRange(sam,s.Tick+44),MissileRules.range(2),'upgrade reaches new range')
 print('Silo/SAM normal construction, unavailable unfinished launchers and SAM upgrade cooldown/range passed.')
end
do
 local s=environment(768,1024);s.Match=nil;local a,c=s.Players[1],s.Players[2]
 own(s,a,0,680,40,720);own(s,c,300,200,767,900);c.Troops=1000000
 build(s,a,'MissileSilo',700*768+20,1)
 s.enqueue({Kind='Missile',Type='MIRV',UserId=1,Tile=600*768+500,Sequence=2});s.step();s.step()
 eq(a.Gold,'973999999','MIRV purchase');local peak=0
 for _=1,180 do s.step();peak=math.max(peak,s.Naval.Count) end
 assert(peak>1 and s.Missiles.Impacts>1 and s.Missiles.Impacts<=350 and s.Naval.Count==0,'real MIRV warheads impact and clean up')
 assert(s.Grid.FalloutCount>0 and c.Troops<1000000 and c.Troops>=0)
 print('Actual MIRV order, global price/count, live child executions, casualties, fallout and complete projectile cleanup passed; impacts '..s.Missiles.Impacts..'.')
end
do
 local s=environment(512,256);local a,c=s.Players[1],s.Players[2]
 own(s,a,0,100,45,145);own(s,c,400,80,510,200)
 local silo=build(s,a,'MissileSilo',120*512+20,1);eq(a.Gold,'998999999','silo price');assert(silo and #silo.MissileQueue==0)
 local dst=140*512+450;local before=s.Grid.Counts[2]
 s.enqueue({Kind='Missile',Type='AtomBomb',UserId=1,Tile=dst,Sequence=2});s.step();s.step()
 eq(a.Gold,'998249999','atomic price');eq(#silo.MissileQueue,1,'slot consumed')
 s.enqueue({Kind='Missile',Type='AtomBomb',UserId=1,Tile=dst,Sequence=2});s.step();s.step();eq(a.Gold,'998249999','duplicate launch')
 for _=1,80 do s.step() end
 eq(s.Missiles.Impacts,1,'one impact');assert(s.Grid.Counts[2]<before and c.Troops<100000);assert(s.Grid.FalloutCount>0)
 eq(s.Grid.ownerID(dst),0,'impact relinquishes');s.conquer(c,dst);assert(bit32.band(s.Grid.state(dst),0x2000)==0)
 for _=1,20 do s.step() end;eq(#silo.MissileQueue,0,'reload 90 ticks')
 s.enqueue({Kind='Building',Action='Upgrade',UserId=1,UnitID=silo.ID,Sequence=3});s.step();eq(silo.Level,2,'silo upgrade');eq(#silo.MissileQueue,1,'new slot reload')
 a.Team='Blue';c.Team='Blue';assert(not s.Missiles.source(a,'AtomBomb',dst),'team protection')
 assert(not s.Missiles.source(a,'MIRV',0),'MIRV needs target owner')
 local sam=build(s,c,'SAMLauncher',95*512+450,1);assert(sam);eq(s.Missiles.price(a,'MIRV'),'25000000','MIRV price')
 s.Missiles.MIRVsLaunched=3;eq(s.Missiles.price(a,'MIRV'),'70000000','global MIRV escalation')
 a.Team=nil;c.Team=nil
 local missile=s.Missiles.fly(a,'HydrogenBomb',120*512+20,dst)
 for _=1,100 do s.step() end
 assert(not missile.Active);assert(s.Missiles.Interceptions>0,'predictive SAM interception');eq(s.Missiles.Impacts,1,'SAM prevented blast')
 print('Missile integration: purchase/replay, silo inventory/reload/upgrade, impact/casualties/fallout/reclaim, team protection and predictive SAM passed.')
end
do
 -- Optimized ordered border updates against the former per-cell implementation,
 -- including map edges, blocked inner regions, flags, and copy-on-write pages.
 for mode=0,2 do
  local fast=environment(96,96,mode==1);local slow=environment(96,96,mode==1)
  fast.Match=nil;slow.Match=nil
  for t=0,96*96-1 do if not fast.Grid.isImpassable(t) then
   local id=if t%96<48 then 1 else 2;fast.conquer(fast.Players[id],t);slow.conquer(slow.Players[id],t)
  end end
  fast.Grid.discardChanges();slow.Grid.discardChanges();local frozen=fast.Grid.snapshotPages()
  local dst=if mode==2 then 30*96+30 else 48*96+48
  local tiles=fast.Missiles.blastTiles(dst,'AtomBomb',123)
  for _,t in ipairs(tiles) do local p=slow.owner(slow.Grid.ownerID(t));if p then slow.relinquish(p,t) end;if slow.Grid.isLand(t) then slow.Grid.setState(t,bit32.bor(slow.Grid.state(t),0x2000)) end end
  fast.Tick=123;local u=fast.Naval.create(fast.Players[1],'AtomBomb',dst,{TargetTile=dst});fast.Missiles.detonate(u)
  for t=0,96*96-1 do eq(fast.Grid.state(t),slow.Grid.state(t),'optimized fallout state') end
  for id=1,2 do local a,b={},{};fast.Players[id].Border.each(function(t)table.insert(a,t)end);slow.Players[id].Border.each(function(t)table.insert(b,t)end);eq(a,b,'ordered post-blast borders') end
  assert(#frozen>0)
  for _,page in ipairs(frozen) do for i=0,math.min(4095,96*96-1-page.Key*4096) do
   local t=page.Key*4096+i;local original=if fast.Grid.isImpassable(t) then 0 elseif t%96<48 then 1 else 2
   eq(buffer.readu16(page.Data,i*2),original,'blast snapshot copy-on-write')
  end end
  eq(fast.Grid.FalloutCount,slow.Grid.FalloutCount,'fallout denominator')
 end
 local s=environment(256,256);s.Match=nil;local p=s.Players[1];own(s,p,80,80,180,180)
 local dst=128*256+128;p.Outgoing={{Troops=1}};p.Troops=1
 local ship=s.Naval.create(p,'TransportShip',5,{Troops=1});local u=s.Naval.create(p,'HydrogenBomb',dst,{TargetTile=dst})
 local destroyed=false;s.Rail.TrainUnits=7;s.Rail.Trains[100]={ID=100,Tile=0,Cars={{Active=true,Tile=dst},{Active=true,Tile=0}},Destroy=function()destroyed=true end}
 s.Missiles.detonate(u);assert(p.Troops>=0 and p.Outgoing[1].Troops>=0 and ship.Troops>=0,'nonnegative stacks')
 assert(not destroyed and not s.Rail.Trains[100].Cars[1].Active and s.Rail.TrainUnits==6,'independent carriage blast loss')
 print('Blast integration: optimized versus reference ordered borders/state, blocked/edge terrain, nonnegative reserve/attack/transport casualties and rail carriage damage passed.')
end
do
 local s=environment(100,100);local a,c=s.Players[1],s.Players[2]
 own(s,a,0,0,79,99);own(s,c,80,0,80,99);s.Tick=110;s.Match.tick();assert(not s.Match.Winner,'strict >80%')
 s.conquer(a,81);s.Tick=120;s.Match.tick();eq(s.Phase,'Victory','victory');eq(s.Match.Winner.UserId,1,'winner')
 local count=s.Grid.Counts[1];for _=1,31 do s.step() end;eq(s.Phase,'Results','results');eq(s.Grid.Counts[1],count,'frozen ownership')
 eq(s.Match.RestartAt,300,'restart deadline')
 local team=environment(100,100,false,{Mode='Team',Teams={[1]='Blue',[2]='Blue'}});own(team,team.Players[1],0,0,49,99);own(team,team.Players[2],50,0,81,99);team.Tick=110;team.Match.tick();eq(team.Match.Winner.Team,'Blue','team aggregate')
 local timer=environment(100,100,false,{MaxTimerMinutes=1});own(timer,timer.Players[1],0,0,5,5);timer.Tick=600;timer.Match.tick();eq(timer.Match.Winner.UserId,1,'timer leader')
 local f=environment(100,100);own(f,f.Players[1],0,0,39,99);f.Grid.FalloutCount=6000;f.Tick=110;f.Match.tick();assert(f.Match.Winner,'fallout reduces denominator')
 print('Victory: strict threshold, team aggregation, timed leader, fallout denominator, freeze/results/restart deadline passed.')
end
-- Determinism and mixed missile stress; full-resolution sparse grid, simulated owners.
local function stress(players)
 local s=environment(8192,4096);s.Match=nil;s.Phase='Started'
 for id=3,players do s.enqueue({Kind='Join',UserId=id,Username='P'..id}) end;s.step()
 for _,p in pairs(s.Players) do p.Spectator=false;local x=100+(p.UserId-1)*70;own(s,p,x,1800,x+39,1839) end
 local times={};local heap=gcinfo();local maxBytes=0;local digest=0
 for t=1,180 do
  local start=os.clock()
  if t==1 then for id=1,players do local p=s.Players[id];s.Missiles.fly(p,if id%10==0 then 'HydrogenBomb' else 'AtomBomb',1800*8192+100+(id-1)*70,1820*8192+100+(id%players)*70) end end
  local packet=s.step();table.insert(times,(os.clock()-start)*1000);maxBytes=math.max(maxBytes,buffer.len(packet.Changes)+(if packet.ShipChanges then buffer.len(packet.ShipChanges) else 0))
 end
 for _,p in pairs(s.Players) do digest+=p.SmallId*(s.Grid.Counts[p.SmallId] or 0) end
 local sum=0;for _,v in ipairs(times) do sum+=v end;table.sort(times)
 print(string.format('STAGE8_STRESS %d players avg %.3f p95 %.3f worst %.3f ms heapDelta %.1f KiB maxDelta %d bytes impacts %d digest %d',players,sum/#times,times[math.ceil(#times*.95)],times[#times],gcinfo()-heap,maxBytes,s.Missiles.Impacts,digest))
 return digest
end
for _,n in ipairs({2,10,20,50,100}) do eq(stress(n),stress(n),'deterministic missile stress '..n) end
