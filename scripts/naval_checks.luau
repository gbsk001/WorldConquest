local function eq(a,b,label)
 if typeof(a)~=typeof(b) then error(label..': type '..typeof(a)..'/'..typeof(b)) end
 if typeof(a)=="table" then for k,v in pairs(a) do eq(v,b[k],label..'.'..tostring(k)) end;for k in pairs(b) do if a[k]==nil then error(label..': extra '..tostring(k)) end end
 elseif a~=b then error(label..': '..tostring(a)..' != '..tostring(b)) end
end
local function makeMap(w,h,mode)
 local function neighbors(t)local a={};local x=t%w;if t>=w then table.insert(a,t-w) end;if t<(h-1)*w then table.insert(a,t+w) end;if x>0 then table.insert(a,t-1) end;if x<w-1 then table.insert(a,t+1) end;return a end
 local function land(t)return if mode==0 then t%w<=20 or t%w>=w-21 elseif mode==1 then t%w==math.floor(w/2) else (t*37+math.floor(t/w)*11)%31<7 end
 local function shore(t)for _,n in ipairs(neighbors(t)) do if land(n)~=land(t) then return true end end;return false end
 local bytes=buffer.create(w*h);local components={};local component=0
 for t=0,w*h-1 do buffer.writeu8(bytes,t,(if land(t) then 128 else 32)+(if shore(t) then 64 else 0)+(if land(t) then 0 else (t*13+math.floor(t/w)*7)%32)) end
 for t=0,w*h-1 do if not land(t) and not components[t] then component+=1;components[t]=component;local stack={t};while #stack>0 do for _,n in ipairs(neighbors(table.remove(stack))) do if not land(n) and not components[n] then components[n]=component;table.insert(stack,n) end end end end end
 local terrain={Width=w,Height=h,MaskHash='naval-fixture',byte=function(t)return buffer.readu8(bytes,t)end,waterComponent=function(t)return components[t]end}
 return terrain,Grid.new(w,h,terrain.byte)
end
for _,v in ipairs(NavalOracle.rates) do eq(NavalRules.tradeRate(v.rejected,v.ships,v.levels),v.value,'trade rate') end
for _,v in ipairs(NavalOracle.gold) do eq(tostring(NavalRules.tradeGold(v.distance,v.multiplier)),v.value,'trade gold') end
for _,v in ipairs(NavalOracle.prices) do eq(NavalRules.warshipCost(v.owned,v.built),v.value,'warship cost') end
for _,v in ipairs(NavalOracle.damage) do eq(NavalRules.shellDamage(Random32.new(v.tick).nextInt(1,6),v.veteran),v.value,'shell damage') end
for mode=0,2 do
 local terrain,grid=makeMap(64,48,mode);local path=WaterPath.new(grid,terrain)
 for i,v in ipairs(NavalOracle.paths) do if v.mode==mode then
  eq(path.raw({v.from},v.to),v.raw,'raw path '..i)
  eq(path.route(v.from,v.to,false),v.shore,'shore path '..i)
  eq(path.raw({v.from},v.to,{0,63,0,47}),v.bounded,'bounded path '..i)
 end end
 for i,v in ipairs(NavalOracle.air) do
  local step=path.stepper(false,v.seed);local route={v.from};local t=v.from
  while true do local status,n=step.next(t,v.to);if status=='COMPLETE' then break end;assert(status=='NEXT');table.insert(route,n);t=n end
  eq(route,v.path,'air '..i)
 end
end
print('Stage 6 upstream parity: 168 spawn rates, 32 trade payouts, 30 warship prices, 100 shell rolls, 450 exact raw/shore/bounded water paths and 30 air routes passed.')
local function environment(isolate)
 local terrain,grid=makeMap(192,128,0)
 local map={};function map.cell(x,y)if typeof(x)=='number' and typeof(y)=='number' and x>=0 and y>=0 and x<192 and y<128 then return math.floor(y)*192+math.floor(x)+1 end;return nil end
 local sim=Simulation.new(terrain,map,77,{Stage=6,Economy={StartingGold='10000000'},Buildings={InstantBuild=true}})
 for id=1,3 do sim.enqueue({Kind='Join',UserId=id,Username='P'..id}) end;sim.step()
 sim.Phase='Started';sim.StartTick=0;sim.Tick=100;sim.Executions=Executions.new();sim.Executions.Tick=100
 local players={sim.Players[1],sim.Players[2],sim.Players[3]};for _,p in ipairs(players) do p.Troops=100000 end
 for t=0,192*128-1 do if t%192<=20 then sim.conquer(players[1],t) elseif t%192>=171 then sim.conquer(players[2],t) end end
 sim.Grid.discardChanges();local nav=sim.Naval;local landings={};local original=sim.conquer
 function sim.conquer(p,t)original(p,t);table.insert(landings,{sim.Tick,t,p.SmallId}) end
 local originalAdd=sim.Executions.add
 function sim.Executions.add(e)
  if isolate~=false and e.Attack then
   -- Isolate naval execution parity; full AttackExecution integration is tested below.
   local init=e.init;local active=true
   originalAdd({activeDuringSpawnPhase=function()return false end,isActive=function()return active end,init=function()
    local a=e.Attack;table.insert(landings,{sim.Tick,'attack',a.Troops,a.Owner.SmallId,if a.Target then a.Target.UserId else nil,a.SourceTile,false});active=false
   end,tick=function()end})
  else originalAdd(e) end
 end
 local function port(p,t)
  local u={ID=sim.Buildings.nextID(),Type='Port',Tile=t,Owner=p,Active=true,UnderConstruction=false,Level=1}
  sim.Buildings.Units[u.ID]=u;sim.Buildings.Count+=1;table.insert(p.BuildingUnits,u);p.BuildingOwned.Port=(p.BuildingOwned.Port or 0)+1;return u
 end
 local ports={port(players[1],40*192+20),port(players[2],80*192+171)}
 local function event(e)
  local kind,p,a,b=e[2],players[e[3]],e[4],e[5]
  if kind=='transport' then
   nav.schedule(function()local dst=nav.Shore.target(p,a);local src=if dst then nav.Shore.launch(p,dst) else nil;if src then nav.transport(p,{Source=src,Destination=dst,Target=sim.owner(sim.Grid.ownerID(a)),Troops=b}) end end,function()end,function()return false end)
  elseif kind=='warship' then
   nav.schedule(function()local src=nav.warshipSpawn(p,a);if src then Economy.remove(p,nav.price(p));local u=nav.create(p,'Warship',src,{PatrolTile=a});Warship.start(sim,nav,u) end end,function()end,function()return false end)
  elseif kind=='trade' then nav.trade(p,ports[1],ports[2])
  elseif kind=='ports' then for _,u in ipairs(ports) do nav.port(u) end
  elseif kind=='retreat' then local active=true;nav.schedule(function()end,function()local u=nav.Units[a];if u and u.Owner==p then u.Retreating=true end;active=false end,function()return active end)
  elseif kind=='move' then nav.schedule(function()local u=nav.Units[a];if u then u.PatrolTile=b;u.TargetTile=nil end end,function()end,function()return false end)
  elseif kind=='damage' then if nav.Units[a] then Warship.health(sim,nav,nav.Units[a],-b) end
  elseif kind=='capture' then if nav.Units[a] then nav.capture(nav.Units[a],p) else local u=sim.Buildings.Units[a];table.remove(u.Owner.BuildingUnits,table.find(u.Owner.BuildingUnits,u));u.Owner.BuildingOwned.Port-=u.Level;u.Owner=p;table.insert(p.BuildingUnits,u);p.BuildingOwned.Port=(p.BuildingOwned.Port or 0)+u.Level end
  elseif kind=='upgrade' then sim.Buildings.Units[a].Level+=1;sim.Buildings.Units[a].Owner.BuildingOwned.Port+=1
  elseif kind=='delete' then if nav.Units[a] then nav.delete(nav.Units[a]) else sim.Buildings.Units[a].Active=false end
  elseif kind=='port' then port(p,a)
  elseif kind=='neutral' then players[2].Tiles.each(function(t)sim.relinquish(players[2],t)end) end
 end
 local function step()sim.TransactionResults={};sim.Work.NavalMilliseconds=0;sim.Executions.step(sim);sim.Tick+=1 end
 local function snapshot()
  local ships={};for _,u in pairs(nav.Units) do table.insert(ships,{id=u.ID,type=u.Type,tile=u.Tile,owner=u.Owner.SmallId,hp=u.Health,vet=u.Veterancy,progress=u.Progress,troops=u.Troops,target=u.TargetTile,state=u.State,retreat=u.Retreating or false}) end
  table.sort(ships,function(a,b)return a.id<b.id end)
  local gold,troops={},{};for _,p in ipairs(players) do table.insert(gold,p.Gold);table.insert(troops,p.Troops) end
  return {ships=ships,gold=gold,troops=troops,landings=landings}
 end
 return {Sim=sim,Nav=nav,Players=players,Terrain=terrain,Map=map,event=event,step=step,snapshot=snapshot}
end
for _,v in ipairs(NavalOracle.veterans) do local veteran,progress=0,0;for i,kind in ipairs(v.kinds) do veteran,progress=NavalRules.progress(veteran,progress,kind);eq({veterancy=veteran,veterancyProgress=progress},v.trace[i],'veterancy '..i) end end
local sceneTicks=0
for _,scene in ipairs(NavalOracle.scenes) do
 local env=environment()
 for t=0,scene.ticks-1 do
  for _,e in ipairs(scene.events) do if e[1]==t then env.event(e) end end
  env.step();eq(env.snapshot(),scene.trace[t+1],scene.name..' tick '..t);sceneTicks+=1
 end
end
print('Stage 6 original transport, retreat, landing, simultaneous invasion, trade, ports, warship, interception and repair traces: '..sceneTicks..' ticks passed (full-resolution water adapter).')
-- Run the real authoritative order queue, economy and landing AttackExecution together.
do
 local env=environment(false);local sim,nav,p,q=env.Sim,env.Nav,env.Players[1],env.Players[2]
 local seq=0
 local function order(owner,action,tile,id,ratio,sequence)
  seq+=1;sim.enqueue({Kind='Naval',UserId=owner.UserId,Action=action,Tile=tile,UnitID=id,Allocation=ratio or 0.2,Sequence=sequence or seq});local packet=sim.step();return packet
 end
 local before=p.Troops
 order(p,'Transport',40*192+20);assert(nav.Count==0 and p.Troops==before,'self invasion')
 order(p,'Transport',80*192+171,nil,0/0);assert(nav.Count==0,'NaN allocation')
 order(p,'Transport',80*192+171,nil,2);assert(nav.Count==0,'oversized allocation')
 order(p,'Warship',40*192+20);assert(nav.Count==0,'land patrol')
 local first=seq+1;order(p,'Transport',80*192+171,nil,0.2,first);assert(nav.Count==1 and p.Troops==80000)
 order(p,'Transport',80*192+171,nil,0.2,first);assert(nav.Count==1 and p.Troops==80000,'duplicate troop debit')
 local ship=p.Ships[1];order(q,'Retreat',nil,ship.ID);assert(not ship.Retreating,'foreign boat control')
 order(p,'Transport',70*192+171);order(p,'Transport',60*192+171);assert(p.ShipCounts.TransportShip==3)
 local reserved=p.Troops;order(p,'Transport',50*192+171);assert(p.ShipCounts.TransportShip==3 and p.Troops==reserved,'three boat cap')
 local initial=sim.Grid.Counts[p.SmallId]
 local replicas={Replica.new(env.Terrain),Replica.new(env.Terrain)}
 for _,r in ipairs(replicas) do
  local keys=sim.Grid.chunkKeys();assert(r.begin({ID=1,Tick=sim.Tick,Count=#keys,MapHash=env.Terrain.MaskHash,Meta=sim.metadata()}))
  for _,k in ipairs(keys) do assert(r.chunk({ID=1,Key=k,Data=sim.Grid.copyChunk(k)})) end;assert(r.finish({ID=1}))
 end
 local captures=0
 for _=1,260 do
  local packet=sim.step();for _,r in ipairs(replicas) do assert(r.delta(packet)) end
  for o=0,buffer.len(packet.Changes)-1,6 do local t=buffer.readu32(packet.Changes,o);assert(sim.Grid.isLand(t));captures+=1 end
 end
 assert((sim.Grid.Counts[p.SmallId] or 0)>initial and captures>3,'landing must feed real cell combat')
 assert(nav.Counts.TransportShip==0 and sim.Grid.Counts[2]<initial,'enemy land conquered')
 for _,r in ipairs(replicas) do eq(r.Grid.Counts,sim.Grid.Counts,'multiplayer ownership');eq(ShipWire.list(r.Ships),nav.snapshot(),'multiplayer ships') end
 local gold=p.Gold;local packet=order(p,'Warship',60*192+85);assert(p.ShipCounts.Warship==1 and p.Gold==Gold.subtract(gold,'250000'))
 local w=p.Ships[#p.Ships];local paid=p.Gold
 order(p,'Warship',60*192+85,nil,nil,seq);assert(p.ShipCounts.Warship==1 and p.Gold==paid,'duplicate purchase')
 order(q,'Move',60*192+95,w.ID);assert(w.PatrolTile==60*192+85,'foreign ship move')
 local old=sim.Tick;sim.Naval.embargo(q,p);assert(not nav.canTrade(p,q));sim.Tick=old+3000;assert(not nav.canTrade(p,q));sim.Tick+=1;assert(nav.canTrade(p,q));sim.Tick=old
 print('Stage 6 real order/economy/landing-combat integration: validation, allocation, idempotency, cap, ownership, simultaneous landings, embargo expiry and two matching replicas passed.')
end
-- Atomic fragmented ship deltas and malformed wire rejection.
do
 local terrain=makeMap(64,48,0);local r=Replica.new(terrain)
 assert(r.begin({ID=1,Tick=0,Count=0,MapHash=terrain.MaskHash,Meta={Stage=6,Players={}}}));assert(r.finish({ID=1}))
 local list={};for i=1,1200 do table.insert(list,{ID=i,Type='Warship',Owner=1,Tile=30,Health=1000,Flags=0}) end
 local b=ShipWire.pack(list);local parts=math.ceil(buffer.len(b)/8064)
 for part=1,parts do local offset=(part-1)*8064;local bytes=math.min(8064,buffer.len(b)-offset);local fragment=buffer.create(bytes);buffer.copy(fragment,0,b,offset,bytes)
  assert(r.delta({Tick=1,Parts=parts,Part=part,Changes=buffer.create(0),ShipChanges=fragment}));if part<parts then assert(r.Tick==0 and next(r.Ships)==nil) end
 end
 assert(#ShipWire.list(r.Ships)==1200 and r.Tick==1)
 local malformed=buffer.create(32);buffer.writeu32(malformed,0,1);buffer.writeu32(malformed,4,999999);buffer.writeu8(malformed,10,1)
 assert(not r.delta({Tick=2,Changes=buffer.create(0),ShipChanges=malformed}));assert(r.Tick==1)
 local removal=ShipWire.pack({{ID=1,Type='Warship',Owner=0,Tile=30}});assert(r.delta({Tick=2,Changes=buffer.create(0),ShipChanges=removal}));assert(r.Ships[1]==nil)
 print('Stage 6 1200-ship snapshot/delta records, atomic fragments, deletion and malformed-packet rejection passed.')
end
-- Deterministic replay with actual landing combat and a shared purchase sequence.
local function replay()
 local env=environment(false);local sim=env.Sim;local hashes={}
 for tick=1,300 do
  if tick==1 or tick==10 then for id=1,2 do sim.enqueue({Kind='Naval',Action='Transport',UserId=id,Sequence=tick,Tile=if id==1 then 80*192+171 else 40*192+20,Allocation=.2}) end end
  if tick==20 then sim.enqueue({Kind='Naval',Action='Warship',UserId=1,Sequence=tick,Tile=60*192+80}) end
  local packet=sim.step();table.insert(hashes,buffer.tostring(packet.Changes)..buffer.tostring(packet.ShipChanges)..sim.Players[1].Gold..':'..sim.Players[1].Troops)
 end;return hashes
end
eq(replay(),replay(),'300-tick replay');print('Stage 6 300-tick full authoritative combat/naval deterministic replay passed.')
-- Earth routing: real terrain/components, no land crossing, immutable route cache.
do
 local grid=Grid.new(EarthTerrain.Width,EarthTerrain.Height,EarthTerrain.byte);local path=WaterPath.new(grid,EarthTerrain)
 local function ref(lon,lat)return math.floor((90-lat)/180*grid.Height)*grid.Width+math.floor((lon+180)/360*grid.Width)end
 for i,pair in ipairs({{-50,35,-15,45},{36,23,55,15},{-6,49,1,50},{130,15,145,35}}) do
  local a,b=ref(pair[1],pair[2]),ref(pair[3],pair[4]);local began=os.clock();local pops=path.Pops;local before=gcinfo();local route=path.route(a,b,true);local ms=(os.clock()-began)*1000
  assert(route,'Earth route '..i);for j,t in ipairs(route) do assert(not grid.isLand(t) or j==1 or j==#route,'route crossed land');if j>1 then assert(path.distance(route[j-1],t)==1,'route jumped') end end
  local cached=os.clock();eq(path.route(a,b,true),route,'cached Earth route');local hit=(os.clock()-cached)*1000
  print(string.format('Earth naval route %d: %d cells, %.3f ms first / %.3f ms cached, %d heap pops; Lua heap %.0f -> %.0f KiB, retained route cache %d B.',i,#route,ms,hit,path.Pops-pops,before,gcinfo(),path.CacheBytes))
 end
end
-- Fleet workload: 100 independently patrolling warships, source targeting and healing.
do
 local env=environment(false);local sim=env.Sim;local nav=env.Nav;local p=env.Players[1]
 for i=1,100 do local u=nav.create(p,'Warship',50*192+80,{PatrolTile=60*192+90});Warship.start(sim,nav,u) end
 local times,bytes,total,peak={},0,0,0;local heap=gcinfo()
 for _=1,300 do local began=os.clock();local packet=sim.step();local ms=(os.clock()-began)*1000;table.insert(times,ms);total+=ms;bytes+=buffer.len(packet.ShipChanges);peak=math.max(peak,buffer.len(packet.ShipChanges)) end
 table.sort(times);print(string.format('Naval fleet 100 warships / 300 ticks: mean %.3f ms p95 %.3f max %.3f; ship payload mean %.0f B/tick max %d B; heap %.0f -> %.0f KiB; %d path searches.',total/300,times[285],times[300],bytes/300,peak,heap,gcinfo(),nav.Path.Searches))
end

-- Dense combat workload (same original combat cadence, no timing-based budgets).
do
 local env=environment(false);local sim,nav=env.Sim,env.Nav
 for i=1,100 do local p=env.Players[if i%2==0 then 1 else 2];local u=nav.create(p,'Warship',(50+i%20)*192+80+i%30,{PatrolTile=60*192+95});Warship.start(sim,nav,u) end
 local times,total,bytes,peak,peakUnits={},0,0,0,0
 for _=1,300 do local began=os.clock();local packet=sim.step();local ms=(os.clock()-began)*1000;table.insert(times,ms);total+=ms;bytes+=buffer.len(packet.ShipChanges);peak=math.max(peak,buffer.len(packet.ShipChanges));peakUnits=math.max(peakUnits,nav.Count) end
 table.sort(times);print(string.format('Naval combat 100 warships / 300 ticks: mean %.3f ms p95 %.3f max %.3f; peak %d ships/shells; payload mean %.0f B/tick max %d B; %d surviving warships.',total/300,times[285],times[300],peakUnits,bytes/300,peak,nav.Counts.Warship or 0))
end
-- Water components prevent disconnected lake/ocean voyages; memo hits are copies.
do
 local terrain,grid=makeMap(64,48,1);local path=WaterPath.new(grid,terrain)
 assert(path.route(20*64+10,20*64+50,true)==nil);assert(path.route(20*64+10,20*64+50,true)==nil and path.Hits==1)
 local route=path.route(10*64+5,40*64+20,true);local first=route[1];route[1]=999999;assert(path.route(10*64+5,40*64+20,true)[1]==first)
 print('Disconnected water rejection and immutable cached route results passed.')
end
-- Adversarial core-search cost, deliberately bypassing the component fast rejection.
do
 local w,h=512,512;local terrain={Width=w,Height=h,byte=function(t)return if t%w==256 then 128 else 63 end}
 local path=WaterPath.new(Grid.new(w,h,terrain.byte),terrain);local began=os.clock();local heap=gcinfo()
 assert(path.raw({10*w+10},490*w+490)==nil)
 print(string.format('Adversarial raw A* 512x512 divided basin: %.3f ms, %d pops, harness heap %.0f -> %.0f KiB. Normal component validation rejects this route before A*.',(os.clock()-began)*1000,path.Pops,heap,gcinfo()))
end
-- Actual neutral beachhead and source no-return-shore refund branch.
do
 local env=environment(false);local sim,p,q=env.Sim,env.Players[1],env.Players[2]
 q.Tiles.each(function(t)sim.relinquish(q,t)end)
 local count=sim.Grid.Counts[p.SmallId]
 sim.enqueue({Kind='Naval',Action='Transport',UserId=1,Sequence=1,Tile=80*192+171,Allocation=.2})
 for _=1,250 do sim.step() end
 assert(sim.Grid.Counts[p.SmallId]>count+1 and (p.ShipCounts.TransportShip or 0)==0,'neutral landing expansion')
 local other=environment(false);local s,a=other.Sim,other.Players[1]
 s.enqueue({Kind='Naval',Action='Transport',UserId=1,Sequence=1,Tile=80*192+171,Allocation=.2});s.step();local u=a.Ships[1]
 for y=0,127 do s.relinquish(a,y*192+20) end
 s.enqueue({Kind='Naval',Action='Retreat',UserId=1,Sequence=2,UnitID=u.ID})
 for _=1,4 do s.step() end
 assert(not u.Active and a.Troops==100000,'no return shore refunds full committed amount')
 print('Actual neutral landing/expansion and no-return-shore full refund passed.')
end
