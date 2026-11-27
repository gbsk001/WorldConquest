--!strict
-- Original lightweight controller using upstream spawn/expansion/combat adapters.
-- Copyright OpenFront and Contributors; AGPL-3.0, see LICENSE/NOTICE.
local Random = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Random32)
local Spawn = require(script.Parent.SpawnExecution)
local Expansion = require(script.Parent.Expansion)
local Basic={}
function Basic.new(sim,config)
 config=config or {}
 local requested=math.clamp(math.floor(config.Count or 350),0,500)
 local count=if config.Enabled then math.min(requested,math.clamp(math.floor(config.SafeCount or 0),0,500))else 0
 local states={};local roster={};local cursor=1;local made=0;local api={Count=count,Decisions=0,Milliseconds=0}
 local rng=Random.new(Spawn.simpleHash(tostring(sim.Seed)..":basic-nations"))
 local budget=math.clamp(math.floor(config.DecisionsPerTick or 4),1,16)
 local interval=math.clamp(math.floor(config.DecisionTicks or 120),30,600)
 function api.step()
  local started=os.clock()
  if sim.Phase=="Selecting"then
   if made==0 and count>0 and sim.SpawnPlanner then
    local competitive=sim.CompetitiveParticipants
    if not competitive then competitive=0;for _,p in pairs(sim.Players)do if not p.BasicNation and not p.Spectator then competitive+=1 end end end
    sim.SpawnPlanner.configure(count+competitive)
   end
   -- Bounded roster construction and spawn work throughout the existing countdown.
   for _=1,math.min(8,count-made)do
    made+=1;local id=-2000000-made
    states[id]={Due=sim.Tick+rng.nextInt(2,math.max(3,sim.EndTick-sim.Tick-10)),Cursor=1,Random=Random.new(rng.nextInt(1,2147483647))}
    table.insert(roster,id)
    sim.enqueue({Kind="Join",UserId=id,Username="Nation "..made,IsBot=true,BasicNation=true,StartingTroops=rng.nextInt(config.MinSoldiers or 500,(config.MaxSoldiers or 1500)+1)})
   end
   local spawned=0
   for _,id in ipairs(roster)do
    local p=sim.Players[id];local s=states[id]
    if spawned<8 and p and not p.Spawn and sim.Tick>=s.Due then
     sim.Executions.add(Spawn.new(sim,p,nil,true));s.Due=sim.Tick+3;spawned+=1
    end
   end
  elseif sim.Phase=="Started"then
   local decisions=0
   for _=1,#roster do
    if decisions>=budget then break end
    local id=roster[cursor];cursor=cursor%#roster+1;local p=sim.Players[id];local s=states[id]
    if not p or p.Eliminated or p.Spectator or not p.Spawn or sim.Tick<s.Due then continue end
    s.Due=sim.Tick+interval+s.Random.nextInt(0,interval);decisions+=1;api.Decisions+=1
    if #p.Outgoing>0 or p.Troops<100 then continue end
    local cells;cells,s.Cursor=p.Border.sample(s.Cursor,12)
    local source=nil;local nb={}
    for _,tile in ipairs(cells)do
     local n=sim.Grid.neighbors4(tile,nb)
     for i=1,n do local t=nb[i]
      if sim.Grid.ownerID(t)==0 and sim.Grid.isLand(t)and not sim.Grid.isImpassable(t)then source=tile;break end
     end
     if source then break end
    end
    if source then sim.Executions.add(Expansion.new(sim,p,math.floor(p.Troops*.2),nil,source))end
   end
  end
  api.Milliseconds=(os.clock()-started)*1000
 end
 return api
end
return Basic
