local s=Simulation.new(EarthTerrain,WorldMap,12345,{Stage=9,Bots={Enabled=true,Count=COUNT,Difficulty="Normal",DecisionsPerTick=2,SampleCells=64}})
s.enqueue({Kind="Join",UserId=1,Username="Observer"});s.enqueue({Kind="Ready",UserId=1})
local startup=0
for i=1,10 do local before=os.clock();s.step();startup=math.max(startup,(os.clock()-before)*1000);if i==1 then s.EndTick=3 end end
local start=gcinfo();local peak=start;local times={};local ai=0;local totalBytes,peakBytes=0,0
for i=1,600 do
 local before=os.clock();local packet=s.step();times[i]=(os.clock()-before)*1000;ai=math.max(ai,s.Bots.Milliseconds);peak=math.max(peak,gcinfo())
 local size=buffer.len(packet.Changes)+(packet.ShipChanges and buffer.len(packet.ShipChanges) or 0)+(packet.BuildingChanges and buffer.len(packet.BuildingChanges) or 0)
 totalBytes+=size;peakBytes=math.max(peakBytes,size)
end
local hash=0;for _,key in ipairs(s.Grid.chunkKeys())do local b=s.Grid.copyChunk(key);for i=0,buffer.len(b)-1 do hash=(hash*33+buffer.readu8(b,i))%4294967296 end end
for _,id in ipairs(s.Bots.Roster)do local p=s.Players[id];hash=(hash+math.floor(p.Troops)+tonumber(p.Gold))%4294967296 end
table.sort(times);local total=0;for _,v in ipairs(times)do total+=v end
print(string.format("EARTH_BOTS %d %.6f %.6f %.6f %.6f %.6f %.0f %.0f %.0f %d %d %d %d %.0f",COUNT,total/#times,times[570],times[600],ai,startup,start,peak,gcinfo(),totalBytes,peakBytes,s.Bots.Decisions,s.Bots.Orders,hash))
