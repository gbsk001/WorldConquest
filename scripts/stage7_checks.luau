-- Full-resolution synthetic fixtures, real Stage 6 production simulation.
local function digest(h,s)
 for i=1,#s do h=(bit32.bxor(h,string.byte(s,i))*33)%4294967296 end;return h
end
-- Large ownership: exact interior-hole traversal and atomic disconnect burst.
do
 local w=8192;local t={Width=w,Height=4096,MaskHash='large',byte=function()return 128 end}
 local s=Simulation.new(t,{},3,{Stage=6});s.enqueue({Kind='Join',UserId=1,Username='Large'});s.step()
 local p=s.Players[1]
 for y=100,611 do for x=3800,4311 do
  if not (x>=4050 and x<=4061 and y>=350 and y<=361) then
   local ref=y*w+x;s.Grid.setOwnerID(ref,1);p.Tiles.add(ref)
  end
 end end
 p.Tiles.each(function(ref)if s.Grid.isBorder(ref) then p.Border.add(ref) end end)
 s.Grid.discardChanges();local cc=Connectivity.new(s,p);local began=os.clock();cc.removeClusters()
 local ms=(os.clock()-began)*1000;assert(s.Grid.Counts[1]==262000)
 s.enqueue({Kind='Leave',UserId=1});began=os.clock();local packet=s.step();local leave=(os.clock()-began)*1000
 assert(s.Grid.Counts[1]==0 and p.Tiles.Size==0 and p.Border.Size==0 and buffer.len(packet.Changes)==262000*6)
 local offset=0
 for y=100,611 do for x=3800,4311 do if not (x>=4050 and x<=4061 and y>=350 and y<=361) then
  assert(buffer.readu32(packet.Changes,offset)==y*w+x and buffer.readu16(packet.Changes,offset+4)==0);offset+=6
 end end end
 print(string.format('Large cross-page territory: connectivity %.3f ms; 262000-cell atomic disconnect %.3f ms, %d payload bytes.',ms,leave,buffer.len(packet.Changes)))
end
local function sameGrid(a,b)
 local keys=a.chunkKeys();assert(#keys==#b.chunkKeys())
 for _,key in ipairs(keys) do assert(buffer.tostring(a.copyChunk(key))==buffer.tostring(b.copyChunk(key))) end
end
local function beginReplica(s,t,id)
 local r=Replica.new(t);local pages={}
 for _,key in ipairs(s.Grid.chunkKeys()) do table.insert(pages,{Key=key,Data=s.Grid.copyChunk(key)}) end
 assert(r.begin({ID=id,Tick=s.Tick,Count=#pages,MapHash=t.MaskHash,Meta=s.metadata()}))
 return r,pages
end
local function install(r,pages,id)
 for _,page in ipairs(pages) do assert(r.chunk({ID=id,Key=page.Key,Data=page.Data})) end
 assert(r.finish({ID=id}))
end
for _,count in ipairs({2,10,20,50,100}) do
 local w,h=8192,4096
 local t={Width=w,Height=h,MaskHash='stage7-synthetic',byte=function(tile)return if tile>=3000*w then 63 elseif tile>=2999*w then 192 else 128 end,
  waterComponent=function(tile)return if tile>=3000*w then 1 else nil end}
 local s=Simulation.new(t,{cell=function(x,y)return math.floor(y)*w+math.floor(x)+1 end},53,{Stage=6,Economy={StartingGold='1000000000'},Buildings={InstantBuild=true}})
 for id=1,count do s.enqueue({Kind='Join',UserId=id,Username='P'..id}) end;s.step();s.Phase='Started';s.StartTick=-100
 for pair=0,count/2-1 do
  local ox=10+(pair%10)*100;local oy=10+math.floor(pair/10)*100
  for y=oy,oy+59 do for x=ox,ox+59 do s.conquer(s.Players[pair*2+(if x<ox+30 then 1 else 2)],y*w+x) end end
 end
 local setupMax=0
 for sequence=1,2 do
  for id=1,count do
   local tile=(1200+math.floor((id-1)/20)*200)*w+50+(id-1)%20*300+(sequence-1)*80
   s.conquer(s.Players[id],tile)
   s.enqueue({Kind='Building',Action='Build',UserId=id,Sequence=sequence,Type=if sequence==1 then 'Factory' else 'City',Tile=tile})
  end
  for _=1,2 do local began=os.clock();s.step();setupMax=math.max(setupMax,(os.clock()-began)*1000) end
 end
 for id=1,count do
  local p=s.Players[id];p.Troops=500000;s.startRecruitment(p)
  local tile=(3020+math.floor((id-1)/20)*100)*w+50+(id-1)%20*180
  local u=s.Naval.create(p,'Warship',tile,{PatrolTile=tile+30});Warship.start(s,s.Naval,u)
 end
 for pair=0,count/2-1 do s.Executions.add(Expansion.new(s,s.Players[pair*2+1],150000,s.Players[pair*2+2])) end
 s.Grid.discardChanges()
 local r,pages=beginReplica(s,t,1);install(r,pages,1)
 local late,latePages=nil,nil
 local times={};local total,bytes,peakBytes,claims,pops,connect,rail,naval,frontier=0,0,0,0,0,0,0,0,0
 local replicaCPU=0;local memory=gcinfo();local peakMemory=memory;local hash=5381;local disconnect=0
 for tick=1,300 do
  if tick==100 then late,latePages=beginReplica(s,t,2) end
  if tick==240 then s.enqueue({Kind='Leave',UserId=count}) end
  if tick==245 then s.enqueue({Kind='Join',UserId=count,Username='Rejoined'}) end
  local began=os.clock();local packet=s.step();local elapsed=(os.clock()-began)*1000
  if tick==240 then disconnect=elapsed end
  times[tick]=elapsed;total+=elapsed
  local payload=buffer.len(packet.Changes)+buffer.len(packet.BuildingChanges)+buffer.len(packet.ShipChanges)
  bytes+=payload;peakBytes=math.max(peakBytes,payload);claims+=s.Work.Claims;pops+=s.Work.Pops
  connect+=s.Work.ConnectivityMilliseconds;rail+=s.Work.RailMilliseconds;naval+=s.Work.NavalMilliseconds;frontier+=s.Work.FrontierMilliseconds or 0
  peakMemory=math.max(peakMemory,gcinfo())
  hash=digest(hash,buffer.tostring(packet.Changes)..buffer.tostring(packet.BuildingChanges)..buffer.tostring(packet.ShipChanges))
  for id=1,count do local p=s.Players[id];if p then hash=digest(hash,p.Gold..':'..string.format('%.17g',p.Troops)) end end
  began=os.clock();assert(r.delta(packet))
  if late then assert(late.delta(packet));if tick==110 then install(late,latePages,2);latePages=nil;sameGrid(late.Grid,s.Grid) end end
  replicaCPU+=(os.clock()-began)*1000
 end
 sameGrid(r.Grid,s.Grid);sameGrid(late.Grid,s.Grid)
 assert(s.Players[count].Spectator and not s.Players[count].Spawn)
 assert(buffer.tostring(ShipWire.pack(ShipWire.list(r.Ships)))==buffer.tostring(ShipWire.pack(s.Naval.snapshot())))
 assert(buffer.tostring(BuildingWire.pack(BuildingWire.list(r.Buildings)))==buffer.tostring(BuildingWire.pack(s.Buildings.snapshot())))
 table.sort(times)
 print(string.format('SIMULATED %d players: mean %.3f p95 %.3f worst %.3f ms; setup %.3f disconnect %.3f ms; claims %d pops %d; bytes/tick %.0f peak %d; grid %d scratch %d B; heap start %.0f peak %.0f end %.0f KiB; replica %.3f ms/tick; connectivity %.3f rail %.3f naval %.3f frontier %.3f ms/tick.',count,total/300,times[285],times[300],setupMax,disconnect,claims,pops,bytes/300,peakBytes,s.Grid.allocatedBytes(),s.Traversal.bytes(),memory,peakMemory,gcinfo(),replicaCPU/300,connect/300,rail/300,naval/300,frontier/300))
 print(string.format('DIGEST %d %.0f',count,hash))
end
-- Original 783 ms failure geometry, with exactly the production rail length gate.
do
 local w=8192;local g=Grid.new(w,4096,function(t)
  local x=t%w;return (if x>=4093 and x<=4099 then 32 else 128)+(if x==4092 or x==4093 or x==4099 or x==4100 then 64 else 0)
 end)
 local began=os.clock();assert(not RailPath.land(g,2048*w+4050,2048*w+4140,110*1.4142))
 print(string.format('Unreachable production rail rejection: %.3f ms.',(os.clock()-began)*1000))
end
