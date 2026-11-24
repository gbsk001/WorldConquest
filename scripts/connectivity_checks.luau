for _,case in ipairs(ConnectivityOracle.cases) do
 local width,height=case.w,case.h;local water={};for _,t in ipairs(case.water) do water[t]=true end
 local function byte(t)
  if water[t] then return 32 end
  local x=t%width;local shore=(t>=width and water[t-width]) or (t<(height-1)*width and water[t+width]) or (x>0 and water[t-1]) or (x<width-1 and water[t+1])
  return if shore then 192 else 128
 end
 local sim=Simulation.new({Width=width,Height=height,byte=byte}, {},123,{Stage=3})
 for id=1,3 do sim.enqueue({Kind="Join",UserId=id,Username="P"..id}) end;sim.step()
 for i,id in ipairs(case.owners) do if id>0 then sim.conquer(sim.Players[id],i-1) end end
 for _,p in pairs(sim.Players) do p.Border=OrderedSet.new() end
 for t=0,width*height-1 do local id=sim.Grid.ownerID(t);if id>0 and sim.Grid.isBorder(t) then sim.Players[id].Border.add(t) end end
 for _,t in ipairs(case.fallout) do sim.Grid.setState(t,8192) end
 for _,pair in ipairs(case.allies) do local p=sim.Players[pair[1]];p.Allies=p.Allies or {};p.Allies[pair[2]]=true end
 for _,attack in ipairs(case.attacks) do table.insert(sim.Players[attack[1]].Outgoing,{Target=sim.Players[attack[2]],Troops=attack[3]}) end
 local calls={};local conquer=sim.conquer
 sim.conquer=function(p,t)conquer(p,t);table.insert(calls,{t,p.SmallId})end
 local cc=Connectivity.new(sim,sim.Players[1]);local clusters=cc.calculateClusters()
 assert(#clusters==#case.clusters,case.name.." clusters")
 for i,c in ipairs(clusters) do
  assert(#c==#case.clusters[i],case.name.." cluster size")
  for j,t in ipairs(c) do assert(t==case.clusters[i][j],case.name.." DFS order") end
  assert(cc.hasDiagonalPinch(c)==case.pinches[i],case.name.." pinch detection")
 end
 cc.removeClusters()
 assert(#calls==#case.changes,case.name.." capture count "..#calls.." expected "..#case.changes)
 for i,v in ipairs(calls) do assert(v[1]==case.changes[i][1] and v[2]==case.changes[i][2],case.name.." exact capture order") end
 for i,id in ipairs(case.final) do assert(sim.Grid.ownerID(i-1)==id,case.name.." final owner") end
 local b=sim.Players[1].LargestClusterBoundingBox
 if case.box then for i=1,4 do assert(b[i]==case.box[i],case.name.." sovereign ranking") end else assert(b==nil) end
end
print("Connectivity parity: 310 actual upstream scenarios; exact clusters, DFS order, pinch flags, captors, capture order, final ownership and sovereign bounds passed.")
-- Shared scratch rollover and scheduled analysis must preserve deterministic results.
do
 local w,h=128,64
 local terrain={Width=w,Height=h,byte=function()return 128 end,MaskHash="scheduled"}
 local map={cell=function(x,y)return math.floor(y)*w+math.floor(x)+1 end}
 local function match()
  local s=Simulation.new(terrain,map,123,{Stage=3})
  for id=1,2 do s.enqueue({Kind="Join",UserId=id,Username="P"..id}) end;s.step();s.Phase="Started";s.StartTick=-100
  for y=10,30 do for x=10,30 do s.conquer(s.Players[if x==10 or x==30 or y==10 or y==30 then 2 else 1],y*w+x) end end
  for _,p in pairs(s.Players) do s.startRecruitment(p) end
  s.Grid.discardChanges();return s
 end
 local a,b=match(),match()
 for tick=1,50 do
  if tick==15 then for _,s in ipairs({a,b}) do s.relinquish(s.Players[1],20*w+20);s.conquer(s.Players[1],20*w+20) end end
  local packet,copy=a.step(),b.step();assert(buffer.tostring(packet.Changes)==buffer.tostring(copy.Changes),"scheduled connectivity replay")
 end
 assert((a.Grid.Counts[1] or 0)==0 and a.Players[1].Eliminated,"scheduled sovereign conquest")
 local cc=Connectivity.new(b,b.Players[2]);b.Traversal.gen=0xfffffffe
 cc.removeClusters();assert(b.Traversal.gen<10000,"scratch rollover")
 assert((a.Grid.Counts[2] or 0)==(b.Grid.Counts[2] or 0))
 print("Scheduled connectivity, elimination, deterministic replay and u32 scratch-generation rollover passed.")
end
-- Heavy active fronts plus the actual PlayerExecution cadence (recruitment AND connectivity).
do
 local w,h=8192,4096;local terrain={Width=w,Height=h,byte=function()return 128 end,MaskHash="heavy"}
 local s=Simulation.new(terrain,{cell=function(x,y)return math.floor(y)*w+math.floor(x)+1 end},53,{Stage=3})
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
 print(string.format("Heavy Stage 3: 100 players/50 fronts/180000 initial cells/240 ticks WITH recruitment+connectivity: mean %.3f ms p95 %.3f max %.3f; cluster CPU %.1f ms total; %d captures; delta mean %.0f B max %d B; ownership %d B; shared scratch %d B; cumulative harness heap %.0f KiB.",total/240,times[228],times[240],clusterTotal,claims,bytes/240,peakBytes,s.Grid.allocatedBytes(),s.Traversal.bytes(),gcinfo()))
end
-- Worst-case shape: two border clusters on one large territory force area traversal.
do
 local terrain={Width=8192,Height=4096,byte=function()return 128 end}
 local s=Simulation.new(terrain,{},1,{Stage=3});s.enqueue({Kind="Join",UserId=1,Username="Large"});s.step()
 local p=s.Players[1]
 for y=100,611 do for x=100,611 do
  if not (x>=350 and x<=361 and y>=350 and y<=361) then s.conquer(p,y*8192+x) end
 end end
 s.Grid.discardChanges();local cc=Connectivity.new(s,p);local began=os.clock();cc.removeClusters();local ms=(os.clock()-began)*1000
 assert(s.Grid.Counts[1]==512*512-144,"hole cannibalized sovereign territory")
 print(string.format("Adversarial 262000-cell territory with interior hole: one connectivity pass %.3f ms; shared scratch %d B (full owned area traversal, not a tick average).",ms,s.Traversal.bytes()))
end
