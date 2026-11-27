--!strict
-- Adapted from OpenFront NationExecution and nation behaviours, revision 8f1a0add.
-- Copyright OpenFront and Contributors; AGPL-3.0, see LICENSE/NOTICE.
-- Bounded Roblox adapter: same command queue/resources as humans, no hidden grants.
local Rules = require(script.Parent.BotRules)
local Random = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Random32)
local Troops = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Troops)
local Spawn = require(script.Parent.SpawnExecution)
local Bots={}
function Bots.new(sim,config)
 config=config or {};local enabled=config.Enabled==true
 local difficulty=config.Difficulty or "Normal";assert(Rules.Rates[difficulty],"Bots.Difficulty must be Easy, Normal or Hard")
 local function bound(value,default,lo,hi)assert(value==nil or typeof(value)=="number" and value==value and value%1==0 and value>=lo and value<=hi,"Invalid bot work/count setting");return value or default end
 local count=bound(config.Count,5,0,500);local target=bound(config.TargetPlayers,10,1,500)
 local budget=bound(config.DecisionsPerTick,2,1,100);local samples=bound(config.SampleCells,64,4,256)
 local buildEvery=bound(config.BuildEveryDecisions,2,1,100);local advancedEvery=bound(config.AdvancedEveryDecisions,3,1,100)
 local interval=config.DecisionTicks;if interval~=nil then bound(interval,60,10,600) end
 local states={};local roster={};local cursor=1;local created=false;local api={Decisions=0,Orders=0,Visited=0,Milliseconds=0}
 local function order(p,s,e)
  s.Sequence+=1;e.UserId=p.UserId;e.Sequence=s.Sequence;sim.enqueue(e);api.Orders+=1
 end
 local function neighbours(p,s)
  local tiles;tiles,s.Border=p.Border.sample(s.Border,samples);api.Visited+=#tiles
  local free=nil;local water=nil;s.Enemies=s.Enemies or {};s.Known=s.Known or {};s.Neighbors=s.Neighbors or {};local enemies,known,nb=s.Enemies,s.Known,s.Neighbors;table.clear(enemies);table.clear(known)
  for _,tile in ipairs(tiles) do
   local n=sim.Grid.neighbors4(tile,nb)
   for i=1,n do local ref=nb[i];local owner=sim.Grid.ownerID(ref)
    if not sim.Grid.isLand(ref) then water=water or ref
    elseif not sim.Grid.isImpassable(ref) then
     if owner==0 and bit32.band(sim.Grid.state(ref),0x2000)==0 then free=free or ref
     elseif owner~=p.SmallId and not known[owner] then
      local enemy=sim.owner(owner)
      if enemy and not sim.friendly(p,enemy) then known[owner]=true;table.insert(enemies,{Player=enemy,Tile=ref,Order=#enemies+1}) end
     end
    end
   end
  end
  table.sort(enemies,function(a,b)return a.Player.Troops<b.Player.Troops or a.Player.Troops==b.Player.Troops and a.Order<b.Order end)
  return free,water,enemies
 end
 local function building(p,s,tiles,water,incoming)
  if not sim.Buildings or config.Buildings==false then return false end
  local quotes=sim.Buildings.quotes(p);local cities=p.BuildingOwned.City or 0
  local desired="City"
  if incoming>0 and (p.BuildingOwned.DefensePost or 0)<1 then desired="DefensePost"
  elseif cities>0 then
   for _,entry in ipairs({{"Port",if sim.TeamMode and difficulty~="Easy" then 1 else 0.75},{"Factory",0.75},{"SAMLauncher",Rules.SAMRatio[difficulty]},{"MissileSilo",0.2}}) do
    if (entry[1]~="Port" or water) and (p.BuildingOwned[entry[1]] or 0)<cities*entry[2] then desired=entry[1];break end
   end
  end
  local q=quotes[desired]
  if q and not q.Enabled then desired="City";q=quotes.City end
  if not q or not q.Enabled or not q.Affordable then return false end
  -- Upstream prefers upgrades above one structure per 1,500 owned tiles.
  if #p.BuildingUnits/math.max(1,p.Tiles.Size)>1/1500 then
   for _,unit in ipairs(p.BuildingUnits) do
    if unit.Type==desired and unit.Type~="DefensePost" and unit.Active and not unit.UnderConstruction and not unit.DeleteAt then order(p,s,{Kind="Building",Action="Upgrade",UnitID=unit.ID});return true end
   end
  end
  if sim.Balance and sim.Balance.ProactiveAI and (desired=="City"or desired=="Factory"or desired=="Port")then
   for _=1,math.min(4,#p.BuildingUnits)do
    s.EconomicCursor=(s.EconomicCursor or 0)%#p.BuildingUnits+1;local unit=p.BuildingUnits[s.EconomicCursor]
    if not unit.Active or unit.UnderConstruction then continue end
    for _=1,2 do
     local x=unit.Tile%sim.Grid.Width+s.Random.nextInt(-75,76);local y=math.floor(unit.Tile/sim.Grid.Width)+s.Random.nextInt(-75,76)
     if x>=0 and y>=0 and x<sim.Grid.Width and y<sim.Grid.Height then
      local tile=sim.Grid.ref(x,y)
      if sim.Buildings.placement(p,desired,tile)then order(p,s,{Kind="Building",Action="Build",Type=desired,Tile=tile});return true end
     end
    end
   end
  end
  for i=1,math.min(#tiles,4) do
   local tile=tiles[i]
   if sim.Buildings.placement(p,desired,tile) then order(p,s,{Kind="Building",Action="Build",Type=desired,Tile=tile});return true end
  end
  for _,unit in ipairs(p.BuildingUnits) do
   if unit.Active and unit.Type==desired and not unit.UnderConstruction and not unit.DeleteAt and unit.Level<3 then order(p,s,{Kind="Building",Action="Upgrade",UnitID=unit.ID});return true end
  end
  return false
 end
 local function advanced(p,s,water,enemies)
  local target=enemies[#enemies]
  -- Deterministic crown candidate from player summaries, not a territory/world scan.
  for _,other in pairs(sim.Players) do
   if other.Spawn and not other.Spectator and not other.Eliminated and not sim.friendly(p,other) then
    local count=sim.Grid.Counts[other.SmallId] or 0
    local previous=target and (sim.Grid.Counts[target.Player.SmallId] or 0) or -1
    if count>previous or count==previous and other.SmallId<target.Player.SmallId then target={Player=other,Tile=other.Spawn-1} end
   end
  end
  if sim.Missiles and config.Missiles~=false and target then
   local summary=sim.Missiles.summary(p);local ready=false
   for _,unit in ipairs(summary.Structures) do if unit.Type=="MissileSilo" and unit.Ready>0 then ready=true;break end end
   if ready then
    -- Prefer enemy structure locations already known through the local frontier.
    local tile=target.Tile
    for _,u in ipairs(target.Player.BuildingUnits or {}) do if u.Active then tile=u.Tile;break end end
    for _,entry in ipairs({{"MIRV",12,18,0.25},{"HydrogenBomb",80,100,0.4},{"AtomBomb",12,30,0.25}}) do
     local kind=entry[1]
     if summary.Quotes[kind].Affordable and sim.Missiles.source(p,kind,tile) and (kind~="MIRV" or (sim.Grid.Counts[target.Player.SmallId] or 0)>=3500)
      and Rules.coverage(sim.Grid,p,sim.owner,sim.friendly,tile,entry[2],entry[3])>=entry[4]
      and not Rules.friendlyBlast(sim.Grid,p,sim.owner,sim.friendly,tile,entry[3]) then
      order(p,s,{Kind="Missile",Type=kind,Tile=tile});return true
     end
    end
   end
  end
  if sim.Naval and config.Naval~=false and water then
   local summary=sim.Naval.summary(p)
   if difficulty~="Easy" and (p.BuildingOwned.Port or 0)>0 and summary.Warships<1 and summary.Affordable then order(p,s,{Kind="Naval",Action="Warship",Tile=water});return true end
   if summary.Transports<3 then
    -- Upstream searches up to 500 random nearby targets. Bound probes to 16 here.
    local grid=sim.Grid;local x,y=water%grid.Width,math.floor(water/grid.Width)
    for probe=1,16 do
     local tx=s.Random.nextInt(x-150,x+150);local ty=s.Random.nextInt(y-150,y+150)
     if sim.Balance and sim.Balance.ProactiveAI then
      if probe<=4 and target then
       local choices;choices,s.NavalBorder=target.Player.Border.sample(s.NavalBorder,16)
       for _,t in ipairs(choices)do if bit32.band(grid.terrainByte(t),64)~=0 then tx=t%grid.Width;ty=math.floor(t/grid.Width);break end end
      elseif probe%4==0 then tx=s.Random.nextInt(0,grid.Width);ty=s.Random.nextInt(0,grid.Height)end
     end
     if tx>=0 and ty>=0 and tx<grid.Width and ty<grid.Height then
      local tile=grid.ref(tx,ty);local owner=sim.owner(grid.ownerID(tile))
      if grid.isLand(tile) and not grid.isImpassable(tile) and grid.ownerID(tile)~=p.SmallId and (not owner or not sim.friendly(p,owner) and owner.Troops<p.Troops) then
       local nb={};local n=grid.neighbors4(tile,nb);local shore=false
       for i=1,n do if not grid.isLand(nb[i]) then shore=true end end
       if shore then order(p,s,{Kind="Naval",Action="Transport",Tile=tile,Allocation=0.2});return true end
      end
     end
    end
   end
  end
  return false
 end
 local function decide(p,s)
  api.Decisions+=1
  local free,water,enemies=neighbours(p,s)
  local tiles;tiles,s.Tiles=p.Tiles.sample(s.Tiles,8)
  local cap=Troops.cap(sim.Grid.Counts[p.SmallId] or 0,p.CityLevels or 0,"Human","Hard")
  local incoming=0
  for _,a in ipairs(p.Incoming) do if a.Active then incoming+=a.Troops end end
  if incoming>p.Troops then
   for _,attack in ipairs(p.Outgoing) do if attack.Active and not attack.Retreating and not attack.CancelQueued then order(p,s,{Kind="Cancel",AttackID=attack.ID});return end end
  end
  s.Advanced=(s.Advanced or 0)+1
  if s.Advanced%advancedEvery==0 and advanced(p,s,water,enemies) then return end
  if s.Advanced%buildEvery==0 and building(p,s,tiles,water,incoming) then return end
  local target=nil
  -- Restart empty/stale local fronts without waiting for an ever-growing capacity.
  local proactive=sim.Balance and sim.Balance.ProactiveAI
  local ready=p.Troops>=cap*s.Personality.Trigger or proactive and p.Troops>=1000 and #p.Outgoing==0
  if free and ready then target={Tile=free}
  else
   for _,enemy in ipairs(enemies) do
    if (ready or difficulty=="Hard" and incoming>0) and (enemy.Player.IsBot or Rules.humanTarget(s.Random,difficulty)) then target=enemy;break end
   end
  end
  if not target then return end
  local amount=Rules.sendTroops(p.Troops,cap,if target.Player then s.Personality.Reserve else s.Personality.Expand)
  if proactive then
   if target.Player and target.Player.Troops>p.Troops*.8 then return end
   amount=math.max(amount,p.Troops*(if target.Player then .35 else .2))
  end
  local strongest=0;for _,enemy in ipairs(enemies) do if enemy.Player~=target.Player then strongest=math.max(strongest,enemy.Player.Troops) end end
  local limit=Rules.threatCap(p.Troops,strongest,incoming,difficulty,sim.TeamMode)
  if not target.Player and limit<=0 then limit=math.ceil(p.Troops*0.05) end
  amount=math.min(amount,limit)
  if target.Player and difficulty=="Hard" and incoming==0 and amount<target.Player.Troops*0.2 then return end
  if amount>=1 and p.Troops>0 then order(p,s,{Kind="Expand",X=target.Tile%sim.Grid.Width+0.5,Y=math.floor(target.Tile/sim.Grid.Width)+0.5,Allocation=math.clamp(amount/p.Troops,0,1)}) end
 end
 function api.step()
  local began=os.clock();api.Milliseconds=0
  if not enabled then return end
  if not created and sim.Phase=="Selecting" and (sim.Stage>=11 or sim.Tick>=sim.EndTick-2) then
   local humans=0;for _,p in pairs(sim.Players) do if not p.IsBot and not p.Spectator then humans+=1 end end
   local desired=if config.FillEmptySlots then math.clamp(target-humans,0,500) else count
   sim.CompetitiveParticipants=desired+humans
   if sim.SpawnPlanner then sim.SpawnPlanner.configure(desired+humans+(sim.BasicNations and sim.BasicNations.Count or 0))end
   -- Cosmetic name stream never consumes the gameplay PRNG.
   local prefixes={"Silver","Nova","Iron","Frost","Shadow","Solar","Lunar","Crimson","Azure","Golden","Silent","Neon","Storm","Arctic","Ember","Thunder","Onyx","Cosmic","Swift","Phantom"}
   local suffixes={"Fox","Storm","Wolf","Byte","Hawk","Raven","Falcon","Knight","Viper","Tiger","Drake","Phoenix","Orbit","Blade","Echo","Comet","Lynx","Warden","Panda","Voyager"}
   local used={};for _,p in pairs(sim.Players) do used[string.lower(p.Username)]=true end
   local nameSeed=Spawn.simpleHash(tostring(sim.Seed)..":names")
   for i=1,desired do
    local n=(nameSeed+(i-1)*137)%400
    local base=prefixes[math.floor(n/20)+1]..suffixes[n%20+1]
    local username=(config.Names and config.Names[i]) or base;local attempt=1
    while not (config.Names and config.Names[i]) and used[string.lower(username)] do attempt+=1;username=base..tostring(attempt) end
    used[string.lower(username)]=true
    local id=-1000000-i;table.insert(roster,id)
    sim.enqueue({Kind="Join",UserId=id,Username=username,IsBot=true,BotDifficulty=difficulty,Team=config.Team})
    local random=Random.new(Spawn.simpleHash(tostring(id))+Spawn.simpleHash(tostring(sim.Seed)))
    local personality=Rules.personality(random,difficulty)
    local spawnRandom=Random.new(Spawn.simpleHash(tostring(sim.Seed)..":spawn:"..i))
    states[id]={Random=random,Personality=personality,Due=sim.Tick+personality.Offset,Sequence=0,Border=1,Tiles=1,SpawnAt=sim.Tick+spawnRandom.nextInt(3,150),Reconsider=if i%7==0 then spawnRandom.nextInt(150,185)else nil,SpawnRandom=spawnRandom}
   end
   created=true
  end
  if sim.Stage>=11 and sim.Phase=="Selecting"then
   local spawned=0
   for _,id in ipairs(roster)do
    local p=sim.Players[id];local s=states[id]
    if p and spawned<4 and sim.Tick>=s.SpawnAt and (not p.Spawn or s.Reconsider and sim.Tick>=sim.EndTick-200+s.Reconsider) then
     if p.Spawn then s.Reconsider=nil end
     sim.Executions.add(Spawn.new(sim,p,nil,true));s.SpawnAt=sim.Tick+5;spawned+=1
    end
   end
  end
  if sim.Phase~="Started" then api.Milliseconds=(os.clock()-began)*1000;return end
  local done=0
  for _=1,#roster do
   if done>=budget then break end
   local id=roster[cursor];cursor=cursor%#roster+1;local p=sim.Players[id];local s=states[id]
   if p and not p.Spectator and not p.Eliminated and p.Spawn and sim.Tick>=s.Due then
    s.Due=sim.Tick+(interval or s.Personality.Rate)+(if sim.Stage>=11 then s.SpawnRandom.nextInt(0,11)else 0);decide(p,s);done+=1
   end
  end
  api.Milliseconds=(os.clock()-began)*1000
 end
 api.States=states;api.Roster=roster
 return api
end
return Bots
