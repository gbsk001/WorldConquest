local s=Simulation.new(EarthTerrain,WorldMap,12345,{Stage=11,Bots={Enabled=true,Count=COUNT-1,Difficulty="Normal",DecisionsPerTick=2,SampleCells=64}})
s.enqueue({Kind="Join",UserId=1,Username="Observer"});s.enqueue({Kind="Ready",UserId=1})
local startup=0
local selection={};local selected=0;local metadataBytes=0
local function estimate(v)
 if typeof(v)=="table"then local n=2;for k,item in pairs(v)do n+=#tostring(k)+estimate(item)+3 end;return n elseif typeof(v)=="string"then return #v+2 else return #tostring(v)end
end
for i=1,202 do local before=os.clock();local packet=s.step();selection[i]=(os.clock()-before)*1000;startup=math.max(startup,selection[i]);if packet.Meta then metadataBytes+=estimate(packet.Meta)end;if packet.SpawnChanges then metadataBytes+=estimate(packet.SpawnChanges)end;if i==199 then for _,p in pairs(s.Players)do if p.Spawn then selected+=1 end end end end
local components={}
local start=gcinfo();local peak=start;local times={};local ai=0;local totalBytes,peakBytes=0,0
for i=1,600 do
 local before=os.clock();local packet=s.step();times[i]=(os.clock()-before)*1000;for k,v in pairs(s.Work)do if string.find(k,"Milliseconds",1,true)then components[k]=(components[k]or 0)+v end end;ai=math.max(ai,s.Bots.Milliseconds);peak=math.max(peak,gcinfo())
 if packet.Meta then metadataBytes+=estimate(packet.Meta)end;if packet.SpawnChanges then metadataBytes+=estimate(packet.SpawnChanges)end
 local size=buffer.len(packet.Changes)+(packet.ShipChanges and buffer.len(packet.ShipChanges) or 0)+(packet.BuildingChanges and buffer.len(packet.BuildingChanges) or 0)
 totalBytes+=size;peakBytes=math.max(peakBytes,size)
end
local hash=0;for _,key in ipairs(s.Grid.chunkKeys())do local b=s.Grid.copyChunk(key);for i=0,buffer.len(b)-1 do hash=(hash*33+buffer.readu8(b,i))%4294967296 end end
for _,id in ipairs(s.Bots.Roster)do local p=s.Players[id];hash=(hash+math.floor(p.Troops)+tonumber(p.Gold))%4294967296 end
table.sort(selection);table.sort(times);local total=0;for _,v in ipairs(times)do total+=v end
print(string.format("EARTH_BOTS %d %.6f %.6f %.6f %.6f %.6f %.0f %.0f %.0f %d %d %d %d %.0f %d %.6f %d",COUNT,total/#times,times[570],times[600],ai,startup,start,peak,gcinfo(),totalBytes,peakBytes,s.Bots.Decisions,s.Bots.Orders,hash,metadataBytes,selection[192],selected))

for k,v in pairs(components)do print("COMPONENT",COUNT,k,v/600)end
