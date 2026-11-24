--!strict
-- Direct non-team SpawnExecution.ts translation, revision 8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE/NOTICE.
-- Roblox adapter supplies Player, match ID and fractional marker coordinates.
local Random = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Random32)
local Spawn = require(script.Parent.Spawn)
local SpawnExecution={}
function SpawnExecution.simpleHash(value)
 local hash=0
 local function unit(char) hash=bit32.band(hash*31+char,0xffffffff) end
 for _,char in utf8.codes(value) do
  if char>65535 then char-=65536;unit(0xd800+math.floor(char/1024));unit(0xdc00+char%1024) else unit(char) end
 end
 if hash>=2147483648 then hash-=4294967296 end
 return math.abs(hash)
end
function SpawnExecution.new(sim,p,tile,fromIntent,x,y)
 p.SpawnAttempts=(p.SpawnAttempts or 0)+1
 local random=Random.new(SpawnExecution.simpleHash(tostring(p.UserId))+SpawnExecution.simpleHash(tostring(sim.Seed))+(if sim.Stage>=11 then p.SpawnAttempts*7919 else 0))
 local active=true;local queuedDuringSpawnPhase=false
 local grid=sim.Grid
 local function getSpawn(center)
  if center~=nil then
   if sim.SpawnIndex and (not grid.isLand(center) or grid.isImpassable(center) or grid.ownerID(center)~=0 or sim.SpawnIndex.near(p.UserId,center,9))then return nil end
   local tiles=Spawn.tiles(grid,center,false)
   if #tiles==0 then return nil end
   return {Center=center,Tiles=tiles}
  end
  if sim.SpawnPlanner then
   for _=1,192 do
    local candidate=sim.SpawnPlanner.candidate(random)
    if not candidate then return nil end
    if grid.ownerID(candidate)==0 and sim.SpawnPlanner.accepts(p.UserId,candidate)then
     local tiles=Spawn.tiles(grid,candidate,true)
     if tiles then return {Center=candidate,Tiles=tiles}end
    end
   end
   return nil -- Retry on a later selection tick; never relax spacing or use Antarctica.
  end
  for tries=1,(if sim.Stage>=11 then 96 else 1000) do
   local rx=random.nextInt(0,grid.Width);local ry=random.nextInt(0,grid.Height)
   if sim.SpawnIndex and tries<=32 and random.nextInt(0,4)==0 then
    local cluster=sim.SpawnIndex.sample(random)
    if cluster then rx=math.clamp(cluster.X+random.nextInt(-160,161),0,grid.Width-1);ry=math.clamp(cluster.Y+random.nextInt(-160,161),0,grid.Height-1)end
   end
   center=grid.ref(rx,ry)
   if not grid.isLand(center) or grid.ownerID(center)~=0 or grid.isBorder(center) then continue end
   local near=false
   if sim.SpawnIndex then near=sim.SpawnIndex.near(p.UserId,center,30)
   elseif tries<=750 then
    for id,other in pairs(sim.Players) do
     if id~=p.UserId and other.Spawn then
      local t=other.Spawn-1
      if math.abs(t%grid.Width-rx)+math.abs(math.floor(t/grid.Width)-ry)<30 then near=true;break end
     end
    end
   end
   if near then continue end
   local tiles=Spawn.tiles(grid,center,true)
   if tiles then return {Center=center,Tiles=tiles} end
  end
  return nil
 end
 return {
  activeDuringSpawnPhase=function() return true end,isActive=function() return active end,
  init=function() queuedDuringSpawnPhase=sim.inSpawnPhase() end,
  tick=function()
   active=false
   if tile~=nil and not grid.valid(tile) then return end
   if sim.Players[p.UserId]~=p then return end
   if fromIntent and (not queuedDuringSpawnPhase or sim.Stage>=11 and sim.Phase~="Selecting") then return end
   local previous=p.SpawnCells or {}
   for _,ref in ipairs(previous) do sim.relinquish(p,ref) end
   local planner=sim.SpawnPlanner
   local displaced={}
   if planner then planner.remove(p.UserId)end
   local function displace(id)
    local bot=sim.Players[id];if not bot or not bot.IsBot then return end
    for _,ref in ipairs(bot.SpawnCells or {})do sim.relinquish(bot,ref)end
    bot.Spawn=nil;bot.SpawnCells=nil;bot.X=nil;bot.Y=nil
    sim.SpawnIndex.remove(id);planner.remove(id);sim.MetadataDirty=true
    table.insert(displaced,bot)
   end
   if planner and tile~=nil and not p.IsBot and grid.isLand(tile)and not grid.isImpassable(tile)
    and not sim.SpawnIndex.near(p.UserId,tile,9,false)then
    -- Human-human reservations stay protected; AI reservations yield first.
    for _,id in ipairs(sim.SpawnIndex.geographic(p.UserId,tile,planner.MinimumKm,true))do displace(id)end
   end
   local spawn=getSpawn(tile)
   if not spawn then
    for _,ref in ipairs(previous) do sim.conquer(p,ref) end
    if planner and p.Spawn then planner.reserve(p.UserId,p.Spawn-1,p.IsBot)end
    return
   end
   for _,ref in ipairs(spawn.Tiles) do sim.conquer(p,ref) end
   if not p.Spawn and not p.SpawnRecruitmentStarted then sim.startRecruitment(p);p.SpawnRecruitmentStarted=true end
   p.Spawn=spawn.Center+1;p.SpawnCells=spawn.Tiles
   if sim.SpawnIndex then sim.SpawnIndex.set(p.UserId,spawn.Center,p.IsBot)end
   if planner then
    planner.reserve(p.UserId,spawn.Center,p.IsBot)
    if not p.IsBot and sim.Phase=="Selecting"then for _,id in ipairs(planner.excessBots())do displace(id)end end
   end
   p.X,p.Y=if x~=nil then x else spawn.Center%grid.Width+0.5,if y~=nil then y else math.floor(spawn.Center/grid.Width)+0.5
   -- Commit the human reservation first, then relocate yielding bots in a
   -- deterministic order. This also handles last-countdown-tick selections.
   for _,bot in ipairs(displaced)do local replacement=SpawnExecution.new(sim,bot,nil,false);replacement.init();replacement.tick()end
   sim.MetadataDirty=true
  end,
 }
end
return SpawnExecution
