-- Same salvo geometry as the original failing Stage 8 workload. Each process
-- contains one player-count run, so heap peaks are not mixed with earlier tests.
local w,h=8192,4096
local terrain=if EARTH then EarthTerrain else {Width=w,Height=h,MaskHash='missile-benchmark',NoImpassable=true,byte=function()return 128 end}
local map={LandCount=w*h};function map.cell(x,y)return math.floor(y)*w+math.floor(x)+1 end
local s=Simulation.new(terrain,map,91,{Stage=8,Economy={StartingGold='999999999'},Buildings={InstantBuild=true}})
for id=1,PLAYERS do s.enqueue({Kind='Join',UserId=id,Username='P'..id}) end;s.step()
s.Phase='Started';s.StartTick=0;s.Tick=100;s.Executions=Executions.new();s.Executions.Tick=100;s.Match=nil
local sources,targets={},{}
for id=1,PLAYERS do local p=s.Players[id];p.Troops=100000;p.Spawn=1
 local x=if EARTH then 4100+(id-1)%10*70 else 100+(id-1)*70
 local y0=if EARTH then 1450+math.floor((id-1)/10)*50 else 1800
 for y=y0,y0+39 do for xx=x,x+39 do local t=y*w+xx;if s.Grid.isLand(t) and not s.Grid.isImpassable(t) then s.conquer(p,t) end end end
 sources[id]=y0*w+x;targets[id]=(y0+20)*w+x
 if EARTH then local first=nil;p.Tiles.each(function(t)first=t;return false end);assert(first,'benchmark territory must contain land')
  if not s.Grid.isLand(sources[id]) then sources[id]=first end;if not s.Grid.isLand(targets[id]) then targets[id]=first end
 end
 assert(s.Grid.isLand(sources[id]) and s.Grid.isLand(targets[id]),'benchmark source and destination must be land')
end
local heapStart=gcinfo();local heapPeak=heapStart;local times={};local sum=0;local bytes=0;local peakBytes=0;local lastImpact=0;local impactTicks={}
local encodedTotal,encodedPeak,encodeTotal=0,0,0;local withWire={};local combinedTotal=0
for t=1,180 do
 local begin=os.clock()
 if t==1 then for id=1,PLAYERS do s.Missiles.fly(s.Players[id],if id%10==0 then 'HydrogenBomb' else 'AtomBomb',sources[id],targets[id%PLAYERS+1]) end end
 local packet=s.step();local ms=(os.clock()-begin)*1000;times[t]=ms;sum+=ms
 local encodeStart=os.clock();local encoded=0
 for offset=0,buffer.len(packet.Changes)-1,8064 do
  local length=math.min(8064,buffer.len(packet.Changes)-offset);local part=buffer.create(length);buffer.copy(part,0,packet.Changes,offset,length)
  local wire=if s.Grid.compressWire then s.Grid.compressWire(part)elseif s.Grid.compressChanges then s.Grid.compressChanges(part) else part;encoded+=buffer.len(wire)
 end
 encoded+=(if packet.ShipChanges then buffer.len(packet.ShipChanges) else 0)+(if packet.BuildingChanges then buffer.len(packet.BuildingChanges) else 0)
 local encodeMS=(os.clock()-encodeStart)*1000;encodeTotal+=encodeMS;withWire[t]=ms+encodeMS;combinedTotal+=ms+encodeMS
 encodedTotal+=encoded;encodedPeak=math.max(encodedPeak,encoded)
 local n=buffer.len(packet.Changes)+(if packet.ShipChanges then buffer.len(packet.ShipChanges) else 0)+(if packet.BuildingChanges then buffer.len(packet.BuildingChanges) else 0)
 bytes+=n;peakBytes=math.max(peakBytes,n);heapPeak=math.max(heapPeak,gcinfo())
 if s.Missiles.Impacts~=lastImpact then table.insert(impactTicks,{s.Tick,s.Missiles.Impacts});lastImpact=s.Missiles.Impacts end
end
table.sort(times)
table.sort(withWire)
local digest=0
local function hash(v)digest=(digest*31+v)%4294967296 end
for _,key in ipairs(s.Grid.chunkKeys()) do local page=s.Grid.copyChunk(key);hash(key);for offset=0,8190,2 do hash(buffer.readu16(page,offset)) end end
for id=1,PLAYERS do local p=s.Players[id];hash(p.Troops);hash(s.Grid.Counts[p.SmallId] or 0);p.Border.each(function(t)hash(t)end);p.Tiles.each(function(t)hash(t)end) end
for _,v in ipairs(impactTicks) do hash(v[1]);hash(v[2]) end
print(string.format('BENCH %d %.6f %.6f %.6f %.0f %.0f %.0f %d %d %d %d %.0f %d %d %.6f %.6f %.6f %.6f',PLAYERS,sum/180,times[171],times[180],heapStart,heapPeak,gcinfo(),bytes,peakBytes,s.Grid.allocatedBytes(),s.Missiles.Impacts,digest,encodedTotal,encodedPeak,encodeTotal/180,combinedTotal/180,withWire[171],withWire[180]))
