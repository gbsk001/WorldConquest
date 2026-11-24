local function fixture(n,difficulty,extra)
 local w,h=512,256
 local terrain={Width=w,Height=h,LandCount=w*h,MaskHash="bot-test",byte=function()return 128 end}
 local map={LandCount=w*h,cell=function(x,y)if x>=0 and y>=0 and x<w and y<h then return math.floor(y)*w+math.floor(x)+1 end;return nil end}
 local bots={Enabled=true,Count=n,Difficulty=difficulty or "Normal",DecisionsPerTick=2,SampleCells=64}
 for k,v in pairs(extra or {}) do bots[k]=v end
 local s=Simulation.new(terrain,map,(extra and extra.TestSeed) or 12345,{Stage=9,Bots=bots,Economy={StartingGold="0"},Buildings={InstantBuild=extra and extra.TestInstantBuild==true,Disabled=extra and extra.TestDisabled},Match={SinglePlayer=extra and extra.TestSinglePlayer==true,Mode=extra and extra.TestTeamMode,Teams=extra and extra.TestTeams}})
 s.enqueue({Kind="Join",UserId=1,Username=(extra and extra.TestHuman) or "Human"});s.enqueue({Kind="Ready",UserId=1});s.step();s.EndTick=3
 for _=1,8 do s.step()end
 return s
end
do
 for _,row in ipairs(BotOracle.personalities) do
  local seed=SpawnExecution.simpleHash("-1000001")+SpawnExecution.simpleHash(tostring(row.seed))
  local p=BotRules.personality(Random32.new(seed),row.difficulty)
  assert(p.Trigger==row.trigger and p.Reserve==row.reserve and p.Expand==row.expand and p.Rate==row.rate and p.Offset==row.offset,"Original NationExecution personality parity")
 end
 for _,row in ipairs(BotOracle.coverage) do
  local grid={Width=160,Height=160,ref=function(x,y)return y*160+x end,ownerID=function(t)return (t*17+math.floor(t/160)*row.scenario)%11 end}
  local function owner(id)return if id==0 then nil else {ID=id}end
  local function friendly(_,p)return p.ID==1 or p.ID==2 end
  assert(math.abs(BotRules.coverage(grid,{},owner,friendly,80*160+80,row.inner,row.outer)-row.coverage)<1e-12)
  assert(BotRules.friendlyBlast(grid,{},owner,friendly,80*160+80,row.outer)==row.friendly)
 end
 local a=BotRules.personality(Random32.new(42),"Easy");local b=BotRules.personality(Random32.new(42),"Easy")
 assert(a.Trigger==b.Trigger and a.Rate==b.Rate and a.Rate>=65 and a.Rate<100)
 for _,difficulty in ipairs({"Easy","Normal","Hard"})do for seed=1,100 do
  local p=BotRules.personality(Random32.new(seed),difficulty);local range=BotRules.Rates[difficulty]
  assert(p.Trigger>=.5 and p.Trigger<.6 and p.Reserve>=.3 and p.Reserve<.4 and p.Expand>=.1 and p.Expand<.2 and p.Rate>=range[1] and p.Rate<range[2])
 end end
 assert(BotRules.sendTroops(600,1000,.35)==250 and BotRules.threatCap(1000,800,0,"Hard",false)==400)
end
do
 local s=fixture(1,"Hard",{DecisionTicks=10,TestInstantBuild=true,Naval=false,Missiles=false,TestSinglePlayer=true})
 local p=s.Players[s.Bots.Roster[1]];local human=s.Players[1]
 s.enqueue({Kind="Join",UserId=2,Username="Second"});s.step();assert(s.Players[2].Spectator)
 p.Gold="20000000" -- Test setup only: no production AI grant.
 local old={};p.Tiles.each(function(t)table.insert(old,t)end);for _,t in ipairs(old)do s.relinquish(p,t)end
 for y=80,139 do for x=40,99 do s.conquer(p,y*512+x)end end
 for _=1,120 do s.step()end
 assert(#p.BuildingUnits>0 and p.BuildingOwned.City>0,"Bot must purchase a city")
 local stats=s.stats();for _,row in ipairs(stats)do assert(row.UserId~=p.UserId,"No private bot HUD generation")end
 -- Forced incoming army exercises defence without changing production rules.
 local outgoing={Active=true,ID=999,Troops=100,Retreating=false};table.insert(p.Outgoing,outgoing)
 table.insert(p.Incoming,{Active=true,Troops=p.Troops+1,Owner=human})
 local log={};local enqueue=s.enqueue;s.enqueue=function(e)table.insert(log,e);enqueue(e)end
 s.Bots.States[p.UserId].Due=s.Tick;s.step();assert(log[#log].Kind=="Cancel" and log[#log].AttackID==999)
 table.remove(p.Outgoing);table.remove(p.Incoming)
 -- Lose every owned cell; normal recruitment detects elimination and AI stops.
 old={};p.Tiles.each(function(t)table.insert(old,t)end);for _,t in ipairs(old)do s.relinquish(p,t)end
 s.step();s.step();assert(p.Eliminated)
 local decisions=s.Bots.Decisions;for _=1,20 do s.step()end;assert(s.Bots.Decisions==decisions)
 print("Stage 9 actual building purchase, single-player spectator policy, defence cancellation, private stats exclusion and elimination passed.")
end
do
 local s=fixture(1,"Hard",{DecisionTicks=10,TestInstantBuild=true,Buildings=false,Naval=false})
 local p=s.Players[s.Bots.Roster[1]];local human=s.Players[1]
 for _,who in ipairs({p,human})do local old={};who.Tiles.each(function(t)table.insert(old,t)end);for _,t in ipairs(old)do s.relinquish(who,t)end end
 for y=80,179 do for x=40,139 do s.conquer(p,y*512+x)end;for x=250,349 do s.conquer(human,y*512+x)end end
 p.Spawn=130*512+90+1;human.Spawn=130*512+300+1;p.Gold="8000000"
 local state=s.Bots.States[p.UserId];state.Sequence+=1
 s.enqueue({Kind="Building",UserId=p.UserId,Action="Build",Type="MissileSilo",Tile=p.Spawn-1,Sequence=state.Sequence})
 for _=1,3 do s.step()end
 assert(p.BuildingOwned.MissileSilo==1)
 s.Tick=s.StartTick+60;state.Advanced=2;state.Due=s.Tick
 local log={};local enqueue=s.enqueue;s.enqueue=function(e)table.insert(log,e);enqueue(e)end
 s.step();assert(log[#log] and log[#log].Kind=="Missile","AI must choose a real missile")
 for _=1,3 do s.step()end
 assert(tonumber(p.Gold)<7000000 and (s.Naval.Counts.HydrogenBomb or 0)+(s.Naval.Counts.AtomBomb or 0)>0,"Bot missile must purchase and launch")
 -- Normal victory routine allows a bot winner; no bespoke win shortcut.
 s.conquer(p,0);s.LandCount=s.Grid.Counts[p.SmallId];s.Tick=math.ceil(s.Tick/10)*10;s.Match.tick()
 assert(s.Match.Winner and s.Match.Winner.UserId==p.UserId and s.Phase=="Victory")
 local decisions=s.Bots.Decisions;s.step();assert(s.Bots.Decisions==decisions)
 print("Stage 9 authoritative missile purchase/launch, bot victory and frozen AI passed.")
end
local function digest(s)
 local h=0
 for _,key in ipairs(s.Grid.chunkKeys())do local b=s.Grid.copyChunk(key);for i=0,buffer.len(b)-1 do h=(h*33+buffer.readu8(b,i))%4294967296 end end
 local ids={};for id in pairs(s.Players)do table.insert(ids,id)end;table.sort(ids)
 for _,id in ipairs(ids)do local p=s.Players[id];h=(h+math.floor(p.Troops)+(tonumber(p.Gold) or 0))%4294967296 end
 return h
end
do
 local s=fixture(3);assert(#s.Bots.Roster==3 and s.Stage==9 and s.metadata().Stage==9)
 for _,id in ipairs(s.Bots.Roster)do local p=s.Players[id];assert(p.IsBot and p.Spawn and p.Kind=="Human" and p.Gold==s.Players[1].Gold and p.Troops==s.Players[1].Troops)end
 local initial=s.Grid.Counts[s.Players[s.Bots.Roster[1]].SmallId]
 for _=1,500 do s.step()end
 assert(s.Bots.Orders>0 and s.Grid.Counts[s.Players[s.Bots.Roster[1]].SmallId]>initial)
 local disabled=fixture(4,"Normal",{Enabled=false});assert(#disabled.Bots.Roster==0)
 local zero=fixture(0);assert(#zero.Bots.Roster==0)
 local teams=fixture(1,"Hard",{Team="AI",TestTeamMode="Team",TestTeams={[1]="Humans"}})
 assert(teams.TeamMode and teams.Players[teams.Bots.Roster[1]].Team=="AI" and teams.Players[1].Team=="Humans")
 local fill=fixture(4,"Normal",{FillEmptySlots=true,TargetPlayers=5});assert(#fill.Bots.Roster==4)
 s.enqueue({Kind="Leave",UserId=1});s.step();assert(s.Phase=="Results" and s.Match.RestartAt)
 print("Stage 9 spawn, human-equivalent resources, expansion, disable/fill and human-disconnect lifecycle passed.")
end
do
 local s=fixture(1,"Hard",{DecisionTicks=10,TestInstantBuild=true,Naval=false,Missiles=false,TestDisabled={Factory=true,Port=true,SAMLauncher=true,MissileSilo=true}})
 local p=s.Players[s.Bots.Roster[1]];p.Gold="10000000"
 for _=1,160 do s.step()end
 local upgraded=false;for _,u in ipairs(p.BuildingUnits)do if u.Type=="City" and u.Level>1 then upgraded=true end end
 assert(upgraded,"AI must upgrade using authoritative building API")
end
do
 local w,h=128,64
 local terrain={Width=w,Height=h,LandCount=4096,MaskHash="bot-sea",byte=function(t)local x=t%w;return if x==31 or x==96 then 192 elseif x<32 or x>=96 then 128 elseif x==32 or x==95 then 96 else 32 end,waterComponent=function(t)local x=t%w;return if x>=32 and x<96 then 1 else nil end}
 local map={LandCount=4096,cell=function(x,y)if x>=0 and y>=0 and x<w and y<h then return math.floor(y)*w+math.floor(x)+1 end end}
 local s=Simulation.new(terrain,map,42,{Stage=9,Bots={Enabled=true,Count=1,Difficulty="Hard",Buildings=false,Missiles=false,AdvancedEveryDecisions=1,DecisionTicks=10},Buildings={InstantBuild=true}})
 s.enqueue({Kind="Join",UserId=1,Username="Human"});s.enqueue({Kind="Ready",UserId=1});s.step();s.EndTick=3;for _=1,8 do s.step()end
 local p=s.Players[s.Bots.Roster[1]];local human=s.Players[1]
 for _,who in ipairs({p,human})do local old={};who.Tiles.each(function(t)table.insert(old,t)end);for _,t in ipairs(old)do s.relinquish(who,t)end end
 for y=0,h-1 do for x=0,31 do s.conquer(p,y*w+x)end;for x=96,127 do s.conquer(human,y*w+x)end end
 p.Border.each(function()end);p.Gold="10000000";p.Troops=100000;human.Troops=1000;p.Spawn=32*w+16+1;human.Spawn=32*w+110+1
 local state=s.Bots.States[p.UserId];state.Sequence+=1;state.Due=math.huge
 s.enqueue({Kind="Building",UserId=p.UserId,Action="Build",Type="Port",Tile=32*w+31,Sequence=state.Sequence});for _=1,3 do s.step()end
 assert(p.BuildingOwned.Port==1);s.Tick=s.StartTick+60;state.Due=s.Tick
 for _=1,4 do s.step()end
 assert(p.ShipCounts.Warship==1,"Bot must buy an actual warship from its port")
 -- Continue bounded probes until a valid opposing coast is selected.
 for _=1,600 do s.step()end
 assert((p.ShipConstructed.TransportShip or 0)>0,"Bot must launch a valid transport")
 print("Stage 9 upgrades and coastal warship/transport purchases passed.")
end
do
 local s=fixture(1,"Hard",{DecisionTicks=10,Buildings=false,Naval=false,Missiles=false})
 local p=s.Players[s.Bots.Roster[1]];local human=s.Players[1]
 for _,who in ipairs({p,human})do local old={};who.Tiles.each(function(t)table.insert(old,t)end);for _,t in ipairs(old)do s.relinquish(who,t)end end
 for y=80,109 do for x=40,69 do s.conquer(p,y*512+x)end;for x=70,99 do s.conquer(human,y*512+x)end end
 local nb={};p.Border.each(function(t)for i=1,s.Grid.neighbors4(t,nb)do local ref=nb[i];if s.Grid.ownerID(ref)==0 then s.Grid.setState(ref,Grid.FalloutBit)end end end)
 p.Troops=Troops.cap(900,0);human.Troops=1000;s.Tick=s.StartTick+60;s.Bots.States[p.UserId].Due=s.Tick
 local log={};local enqueue=s.enqueue;s.enqueue=function(e)table.insert(log,e);enqueue(e)end
 for _=1,20 do s.step()end
 assert(#log>0 and log[1].Kind=="Expand" and s.Grid.Counts[human.SmallId]<900,"Bot must launch and resolve real enemy combat")
 print("Stage 9 enemy selection and actual territory combat passed.")
end
for _,count in ipairs(if QUICK then {} else {20,50,100})do
 local expected=nil
 for repeatIndex=1,2 do
  local s=fixture(count);local times={};local ai={};local bytes=0;local peak=gcinfo();local worstBytes=0
  for i=1,600 do local before=s.Bots.Decisions;local began=os.clock();local packet=s.step();times[i]=(os.clock()-began)*1000;ai[i]=s.Bots.Milliseconds
   assert(s.Bots.Decisions-before<=2);local size=buffer.len(packet.Changes)+(packet.ShipChanges and buffer.len(packet.ShipChanges) or 0)+(packet.BuildingChanges and buffer.len(packet.BuildingChanges) or 0);bytes+=size;worstBytes=math.max(worstBytes,size);peak=math.max(peak,gcinfo())
  end
  local hash=digest(s);if expected then assert(hash==expected,"Bot replay diverged")else expected=hash end
  table.sort(times);table.sort(ai);local total=0;for _,v in ipairs(times)do total+=v end
  print(string.format("BOTS %d run %d avg %.3f p95 %.3f worst %.3f aiWorst %.3f heapPeakKiB %.0f bytes %d peakBytes %d decisions %d digest %.0f",count,repeatIndex,total/#times,times[math.ceil(#times*.95)],times[#times],ai[#ai],peak,bytes,worstBytes,s.Bots.Decisions,hash))
 end
end

-- Cosmetic identities are seeded separately from AI and remain stable in a round.
do
 local a=fixture(100);local b=fixture(100);local c=fixture(100,"Normal",{TestSeed=12346})
 local used={human=true};local changed=false
 for _,id in ipairs(a.Bots.Roster) do
  local name=a.Players[id].Username
  assert(not used[string.lower(name)] and string.match(name,"^[A-Za-z]+$"));used[string.lower(name)]=true
  assert(name==b.Players[id].Username);changed=changed or name~=c.Players[id].Username
 end
 assert(changed)
 local first=a.Players[a.Bots.Roster[1]].Username
 local collision=fixture(1,"Normal",{TestHuman=string.lower(first)})
 assert(string.lower(collision.Players[collision.Bots.Roster[1]].Username)~=string.lower(first))
 for _=1,20 do a.step()end
 assert(a.Players[a.Bots.Roster[1]].Username==first)
 local p=a.Players[a.Bots.Roster[1]]
 local before=a.metadata();local old={};p.Tiles.each(function(t)table.insert(old,t)end)
 for _,tile in ipairs(old)do a.relinquish(p,tile)end
 local newTile=256*100+100;a.conquer(p,newTile)
 for _=1,20 do a.metadata()end
 local meta=a.metadata()
 for _,row in ipairs(meta.Players)do if row.UserId==p.UserId then
  assert(not row.LabelHidden and a.Grid.ownerID(math.floor(row.LabelY)*a.Grid.Width+math.floor(row.LabelX))==p.SmallId)
 end end
 print("Presentation: 100 unique seeded names, human collision, round variation, stable names and owned-land anchors passed.")
end
