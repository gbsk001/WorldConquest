-- Opt-in active gameplay; NEVER called by the low-resource regression gate.
local basic=table.clone(Config.BasicNations);basic.Count=BASIC;basic.SafeCount=BASIC
local options={Stage=11,Balance=Config.Balance,BasicNations=basic,Economy=Config.Economy,Buildings=Config.Buildings,Match=Config.Match,Bots={Enabled=true,Count=20,Difficulty="Normal"}}
local before=gcinfo();local began=os.clock();local s=Simulation.new(EarthTerrain,WorldMap,SEED,options)
s.Phase="Selecting";s.EndTick=200 -- AI-only fixture; live admission still uses LobbyServer.
for _=1,203 do s.step()end
local startup=os.clock()-began;local times={};local sum=0;local peak=gcinfo();local bytes=0;local worstBytes=0;local samples={};local phaseTimes={}
local function payload(value,seen)
 local kind=typeof(value)
 if kind=="buffer"then return buffer.len(value)end
 if kind=="string"then return #value end
 if kind=="number"then return 8 end
 if kind=="boolean"then return 1 end
 if kind~="table"then return 0 end
 seen=seen or {};if seen[value]then return 0 end;seen[value]=true
 local size=0;for k,v in pairs(value)do size+=payload(k,seen)+payload(v,seen)end;return size
end
local function progress()
 local basicTiles,smartTiles,alive,buildings,ships=0,0,0,s.Buildings.Count,s.Naval.Counts.TradeShip or 0
 for _,p in pairs(s.Players)do local n=s.Grid.Counts[p.SmallId]or 0;if p.BasicNation then basicTiles+=n else smartTiles+=n;if n>0 then alive+=1 end end end
 print(string.format("PROGRESS %d occupied %.4f smart %d basic %d competitiveAlive %d buildings %d tradeships %d",s.Tick,(smartTiles+basicTiles)/s.LandCount,smartTiles,basicTiles,alive,buildings,ships))
end
local geometryVersion=-1
for i=1,TICKS do
 local start=os.clock();local packet=s.step();local elapsed=(os.clock()-start)*1000
 table.insert(times,elapsed);sum+=elapsed;peak=math.max(peak,gcinfo())
 local encoded,state=Grid.compressWire(packet.Changes)
 local traffic=buffer.len(encoded)+(if state~=nil then 2 else 0)+buffer.len(packet.BuildingChanges)+buffer.len(packet.ShipChanges)+payload(packet.Meta)+payload(packet.SpawnChanges)+payload(packet.Stats)
 if geometryVersion~=s.Rail.Version then geometryVersion=s.Rail.Version;traffic+=payload(s.Rail.geometry())end
 bytes+=traffic;worstBytes=math.max(worstBytes,traffic)
 for _,key in ipairs({"BotMilliseconds","BasicMilliseconds","RailMilliseconds","NavalMilliseconds","ConnectivityMilliseconds","CombatMilliseconds","MissileMilliseconds"})do phaseTimes[key]=math.max(phaseTimes[key]or 0,s.Work[key]or 0)end
 if i%600==0 then progress()end
 if s.Phase=="Victory"or s.Phase=="Results"then break end
end
table.sort(times);progress()
print(string.format("SIMULATED basic %d competitive 20 ticks %d avg_ms %.4f p95_ms %.4f worst_ms %.4f heap_initial_kib %.0f heap_peak_kib %.0f payload_avg_Bps %.0f payload_max_tick_B %d startup_s %.3f",BASIC,#times,sum/#times,times[math.ceil(#times*.95)],times[#times],before,peak,bytes/#times*10,worstBytes,startup))
for name,value in pairs(phaseTimes)do print("SUBSYSTEM_WORST",name,value)end
print("VICTORY",s.Match.Winner and s.Match.Winner.Name or "NOT_REACHED",s.Phase)
print("Payload proxy excludes Roblox envelopes, compression, recipients, snapshots and live latency. Heap is Luau harness heap, NOT Roblox server/client memory. FPS unavailable. No live capacity certification.")
