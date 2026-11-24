for _,v in ipairs(BuildingOracle.prices) do assert(BuildingRules.cost(v.kind,v.owned,v.constructed)==v.cost,"source cost scaling") end
assert(BuildingRules.MinDistance==BuildingOracle.constants.minDist and BuildingRules.DefenseRange==BuildingOracle.constants.defenseRange)
assert(BuildingRules.DeleteDelay==BuildingOracle.constants.deleteDelay and BuildingRules.DeleteCooldown==BuildingOracle.constants.deleteCooldown)
local function match(width,height,config,terrainByte)
 width=width or 128;height=height or 96
 local terrain={Width=width,Height=height,byte=terrainByte or function(t)return if t%width==2 or t%width==width-3 then 192 else 128 end,MaskHash="buildings"}
 local map={cell=function(x,y)if typeof(x)~="number" or typeof(y)~="number" or x<0 or y<0 or x>=width or y>=height then return nil end;return math.floor(y)*width+math.floor(x)+1 end}
 local s=Simulation.new(terrain,map,123,{Stage=5,Economy={StartingGold="1000000000"},Buildings=config})
 for id=1,2 do s.enqueue({Kind="Join",UserId=id,Username="P"..id}) end;s.step();s.Phase="Started";s.StartTick=-100
 return s,s.Players[1],s.Players[2]
end
local function fill(s,p)
 for t=0,s.Grid.Size-1 do if s.Grid.isLand(t) and not s.Grid.isImpassable(t) then s.conquer(p,t) end end;s.Grid.discardChanges()
end
local function build(s,p,kind,tile,sequence)
 s.enqueue({Kind="Building",UserId=p.UserId,Action="Build",Type=kind,Tile=tile,Sequence=sequence});s.step();s.step()
 return s.Buildings.snapshot()[s.Buildings.Count]
end
-- Run bounded floods against actual PlayerImpl results, including stable equal-distance ties.
local placementSim,placementPlayer=match(96,64);local currentMode=-1
for _,v in ipairs(BuildingOracle.placements) do
 if currentMode~=v.mode then
  currentMode=v.mode
  for t=0,96*64-1 do
   local x,y=t%96,math.floor(t/96);local owner=1
   if v.mode==1 then owner=if x<48 then 1 else 2
   elseif v.mode==2 then owner=if (x==46 and y~=30) or x==50 then 0 else 1
   elseif v.mode==3 then owner=if (x+y)%9==0 then 0 else 1 end
   placementSim.Grid.setOwnerID(t,owner)
  end
 end
 local original=placementSim.Buildings.nearby
 placementSim.Buildings.nearby=function(tile,radius)
  local result={};for _,t in ipairs(v.structures) do if placementSim.Buildings.distance(tile,t)<=radius*radius then table.insert(result,{Tile=t}) end end;return result
 end
 assert((placementSim.Buildings.placement(placementPlayer,"City",v.tile) or false)==v.land,"placement flood/ties")
 assert((placementSim.Buildings.placement(placementPlayer,"Port",v.tile) or false)==v.port,"shore placement")
 placementSim.Buildings.nearby=original
end
for _,v in ipairs(BuildingOracle.construction) do
 local s,p=match(nil,nil,{InstantBuild=v.instant});fill(s,p)
 s.enqueue({Kind="Building",UserId=1,Action="Build",Type=v.kind,Tile=128*40+2,Sequence=1});s.step()
 assert(s.Buildings.Count==0,"Construction init cannot charge/create")
 for _,expected in ipairs(v.trace) do
  s.step();local u=s.Buildings.Units[1]
  assert((u~=nil)==expected.exists and u.UnderConstruction==expected.under,"construction tick parity")
  assert(p.CityLevels==(if v.kind=="City" and not expected.under then 1 else 0),"completed city cap only")
 end
end
for _,v in ipairs(BuildingOracle.upgrades) do
 local s,p,q=match();fill(s,p);build(s,p,v.kind,128*40+2,1);local u=s.Buildings.Units[1]
 u.UnderConstruction=v.under;u.DeleteAt=if v.marked then 10000 else nil
 if not v.own then u.Owner=q end
 p.Gold=tostring(v.funds)
 s.enqueue({Kind="Building",Action="Upgrade",UserId=1,Sequence=2,UnitID=1});s.step()
 assert((u.Level==2)==v.valid,"upstream upgrade validation")
end
for _,v in ipairs(BuildingOracle.demolitions) do
 local s,p=match();fill(s,p);build(s,p,"City",128*40+2,1);local u=s.Buildings.Units[1]
 s.Tick=v.start;s.enqueue({Kind="Building",Action="Demolish",UserId=1,Sequence=2,UnitID=1});s.step()
 assert((u.DeleteAt~=nil)==v.accepted and u.DeleteAt==v.markedAt,"initial cooldown starts at -1")
 if v.accepted then
  s.Tick=v.markedAt;s.step();assert(u.Active,"strictly greater than deletionAt")
  s.step();assert(not u.Active,"delayed destruction")
 end
end
print(string.format("Stage 5 upstream parity: %d prices, %d exact placement floods, 8 construction timelines, 64 upgrade validations and demolition boundaries passed.",#BuildingOracle.prices,#BuildingOracle.placements))
-- Exactly-once debit/effect, shared counts, capture, destruction, defenses and city cap.
local s,p,q=match();fill(s,p)
local start=p.Gold
build(s,p,"City",128*40+2,1)
assert(p.Gold==Gold.subtract(start,"125000") and p.BuildingOwned.City==1 and p.CityLevels==0)
build(s,p,"City",128*40+2,1);assert(s.Buildings.Count==1 and p.Gold==Gold.subtract(start,"125000"),"duplicate charge/effect")
build(s,p,"City",128*40+3,2);assert(s.Buildings.Count==2,"source moves to nearest valid tile")
assert(s.Buildings.distance(s.Buildings.Units[1].Tile,s.Buildings.Units[2].Tile)>=225)
for _=1,30 do s.step() end
assert(p.CityLevels==2 and s.stats()[1].Cap==Troops.cap(s.Grid.Counts[p.SmallId],2))
local cap=p.CityLevels;local u=s.Buildings.Units[1]
s.conquer(q,u.Tile);s.Buildings.reconcile(p)
assert(u.Owner==q and p.CityLevels==cap-1 and q.CityLevels==1 and (q.BuildingConstructed.City or 0)==0,"capture retains level, not lifetime built count")
assert(s.Buildings.price(q,"City")=="125000","captured units do not overcharge")
local post=build(s,p,"DefensePost",128*75+80,3);local du=s.Buildings.Units[post.ID]
assert(not s.Buildings.defended(du.Tile,p));for _=1,51 do s.step() end
assert(s.Buildings.defended(du.Tile+30,p) and not s.Buildings.defended(du.Tile+31,p))
local a,b={Kind="Human",Count=5000},{Kind="Human",Count=5000,Troops=200000}
local l1,d1,f1=Combat.losses("Plains",100000,20,a,b,false);local l2,d2,f2=Combat.losses("Plains",100000,20,a,b,s.Buildings.defended(du.Tile,p))
assert(math.abs(l2/l1-5)<1e-12 and d1==d2 and math.abs(f2/f1-3)<1e-12)
s.conquer(q,du.Tile);s.Buildings.reconcile(p);assert(not du.Active and not s.Buildings.defended(du.Tile,p))
local factory=build(s,p,"Factory",128*15+80,4);assert(s.Buildings.price(p,"Port")=="250000")
local captured=s.Buildings.Units[factory.ID];s.conquer(q,captured.Tile);s.Buildings.reconcile(p)
for _=1,25 do s.step() end;assert(captured.Owner==q and not captured.UnderConstruction,"captured construction continues")
local before=p.Gold;build(s,p,"Port",128*70+40,5);assert(before==p.Gold,"inland port rejected without charge")
build(s,p,"City",u.Tile,6);assert(before==p.Gold,"enemy placement rejected")
local fc=s.Buildings.Count;s.enqueue({Kind="Building",Action="Upgrade",UserId=1,Sequence=7,UnitID=u.ID});s.step();assert(before==p.Gold and u.Level==1,"enemy upgrade rejected")
local city2=s.Buildings.Units[2];s.Tick=400;s.enqueue({Kind="Building",Action="Demolish",UserId=1,Sequence=8,UnitID=2});s.step()
s.conquer(q,city2.Tile);s.Buildings.reconcile(p);assert(city2.DeleteAt==nil,"capture cancels deletion")
s.Tick=800;s.step();assert(city2.Active)
s.relinquish(q,city2.Tile);s.Buildings.reconcile(q);assert(not city2.Active,"unowned structures destroyed")
print("Stage 5 transactions, captures, pending construction transfer, demolition cancellation, city capacities, exact defense radius/strength, invalid land and shared Factory/Port costs passed.")
-- Two-player deterministic orders and atomic snapshot metadata recovery.
local function replay()
 local s,p,q=match(128,96,{InstantBuild=true});fill(s,p)
 for y=0,95 do for x=64,127 do s.conquer(q,y*128+x) end end;s.Grid.discardChanges()
 local frames={};local r=Replica.new({Width=128,Height=96,byte=function()return 128 end,MaskHash="buildings"})
 local meta=s.metadata();local keys=s.Grid.chunkKeys()
 assert(r.begin({ID=1,Tick=s.Tick,Count=#keys,MapHash="buildings",Meta=meta}))
 for _,key in ipairs(keys) do assert(r.chunk({ID=1,Key=key,Data=s.Grid.copyChunk(key)})) end;assert(r.finish({ID=1}))
 for tick=1,90 do
  if tick==1 then for id=1,2 do s.enqueue({Kind="Building",Action="Build",UserId=id,Sequence=1,Type="City",Tile=128*30+(if id==1 then 30 else 90)}) end end
  if tick==4 then for id=1,2 do s.enqueue({Kind="Building",Action="Upgrade",UserId=id,Sequence=2,UnitID=id}) end end
  if tick==5 then s.enqueue({Kind="Building",Action="Upgrade",UserId=1,Sequence=2,UnitID=1}) end
  if tick==15 then s.conquer(q,128*30+30);s.Buildings.reconcile(p) end
  local packet=s.step();assert(r.delta({Tick=packet.Tick,Revision=packet.Revision,Changes=packet.Changes,BuildingChanges=packet.BuildingChanges,Part=1,Parts=1,Meta=packet.Meta}))
  local units=s.Buildings.snapshot();local row={p.Gold,q.Gold,tostring(p.CityLevels),tostring(q.CityLevels)}
  for _,unit in ipairs(units) do table.insert(row,unit.ID..":"..unit.Owner..":"..unit.Level) end
  frames[tick]=table.concat(row,"|")
 end
 assert(#r.Meta.Buildings==2 and r.Meta.Buildings[1].Owner==q.SmallId and r.Meta.Buildings[2].Level==2)
 return table.concat(frames,"\n")
end
assert(replay()==replay(),"building replay")
print("Stage 5 simultaneous multiplayer orders, duplicate upgrades, capture sync and deterministic replay passed (Luau harness, not Studio).")
-- Packed changes, zero-cost idle packets, fragmented atomic install and removal records.
do
 local units={};for id=1,1200 do units[id]={ID=id,Tile=id,Owner=1,Type="City",Level=2,UnderConstruction=id%2==0,CompleteTick=52} end
 local packed=BuildingWire.pack(units);assert(buffer.len(packed)==28800)
 local terrain={Width=128,Height=96,byte=function()return 128 end,MaskHash="wire"};local r=Replica.new(terrain)
 assert(r.begin({ID=1,Tick=0,Count=0,MapHash="wire",Meta={Stage=5,Players={}}}));assert(r.finish({ID=1}))
 for part=1,3 do
  local offset=(part-1)*12288;local b=buffer.create(math.min(12288,buffer.len(packed)-offset));buffer.copy(b,0,packed,offset,buffer.len(b))
  assert(r.delta({Tick=1,Part=part,Parts=3,Changes=buffer.create(0),BuildingChanges=b,Meta=if part==3 then {Stage=5,Players={}} else nil}))
  assert(r.Tick==(if part<3 then 0 else 1),"partial building delta installed")
 end
 assert(#r.Meta.Buildings==1200 and r.Meta.Buildings[1200].Level==2)
 local removed=table.clone(units[42]);removed.Owner=0
 assert(r.delta({Tick=2,Changes=buffer.create(0),BuildingChanges=BuildingWire.pack({removed}),Meta={Stage=5,Players={}}}))
 assert(not r.Buildings[42] and #r.Meta.Buildings==1199)
 assert(not r.delta({Tick=3,Changes=buffer.create(0),BuildingChanges=buffer.create(1)}))
 assert(r.Tick==2,"invalid wire mutates replica")
end
-- Structures cannot bridge water in placement; owned water is impossible in Grid.
do
 local s,p=match(64,48,nil,function(t)return if t%64==31 then 32 elseif t%64==30 or t%64==32 then 192 else 128 end)
 fill(s,p);local chosen=s.Buildings.placement(p,"Port",24*64+25)
 assert(chosen and chosen%64==30,"port chooses owned bank without crossing water")
 assert(s.Buildings.placement(p,"City",24*64+31)==nil)
end
print("Stage 5 compact 24-byte replication, 1200-building atomic fragments, malformed packets, removal and water-separated shore placement passed.")
-- Profile actual Stage 5 with 100 humans, 400 buildings and 50 active combat fronts.
do
 local w,h=8192,4096;local terrain={Width=w,Height=h,byte=function()return 128 end,MaskHash="heavy-buildings"}
 local s=Simulation.new(terrain,{cell=function(x,y)return math.floor(y)*w+math.floor(x)+1 end},53,{Stage=5,Economy={StartingGold="1000000000"}})
 for id=1,100 do s.enqueue({Kind="Join",UserId=id,Username="P"..id}) end;s.step();s.Phase="Started";s.StartTick=-100
 local positions={}
 for pair=0,49 do
  local ox=10+(pair%10)*90;local oy=10+math.floor(pair/10)*90
  for y=oy,oy+59 do for x=ox,ox+59 do s.conquer(s.Players[pair*2+(if x<ox+30 then 1 else 2)],y*w+x) end end
  positions[pair*2+1]={ox+7,oy+7};positions[pair*2+2]={ox+37,oy+7}
 end
 s.Grid.discardChanges();local heapBefore=gcinfo();local purchaseMax=0;local purchaseBytes=0
 for seq=1,4 do
  for id=1,100 do local pos=positions[id];s.enqueue({Kind="Building",Action="Build",UserId=id,Sequence=seq,Type=if seq==4 then "DefensePost" else "City",Tile=(pos[2]+(seq-1)*15)*w+pos[1]}) end
  for _=1,2 do local began=os.clock();local packet=s.step();purchaseMax=math.max(purchaseMax,(os.clock()-began)*1000);purchaseBytes+=buffer.len(packet.BuildingChanges) end
 end
 assert(s.Buildings.Count==400);for _=1,52 do s.step() end
 local heapAfter=gcinfo()
 for id=1,100 do local p=s.Players[id];p.Troops=500000;s.startRecruitment(p) end
 for pair=0,49 do s.Executions.add(Expansion.new(s,s.Players[pair*2+1],150000,s.Players[pair*2+2])) end
 local times={};local total,bytes,claims,buildingCPU,buildingBytes=0,0,0,0,0
 for _=1,240 do
  local began=os.clock();local packet=s.step();local ms=(os.clock()-began)*1000;table.insert(times,ms);total+=ms
  bytes+=buffer.len(packet.Changes);claims+=s.Work.Claims;buildingCPU+=s.Work.BuildingMilliseconds;buildingBytes+=buffer.len(packet.BuildingChanges)
 end
 table.sort(times)
 print(string.format("Heavy Stage 5: 100 players/400 buildings/50 combat fronts/8192x4096/240 ticks: mean %.3f ms p95 %.3f max %.3f; building lifecycle %.3f ms/tick; %d claims; grid delta %.0f B/tick, building delta %.0f B/tick; 400 purchases %d bytes, worst 100-order tick %.3f ms; harness heap before %.0f/after %.0f KiB (GC-sensitive, not isolated memory).",total/240,times[228],times[240],buildingCPU/240,claims,bytes/240,buildingBytes/240,purchaseBytes,purchaseMax,heapBefore,heapAfter))
 assert(buffer.len(s.step().BuildingChanges)==0,"idle building updates must be empty")
end
