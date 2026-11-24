--!strict
-- WinCheckExecution / Config threshold rules, pinned OpenFront 8f1a0add.
-- Copyright OpenFront and Contributors. AGPL-3.0; modified 2026-11-20.
-- Results/restart timing is a Roblox session adapter, not upstream aftergame play.
local Match={}
function Match.threshold(seconds,config)
 local base=config.WinThresholdTenths or 800;local overtime=config.Overtime or {}
 if not overtime.Enabled then return base end
 local elapsed=math.floor(seconds)-(overtime.StartMinutes or 30)*60
 return if elapsed<=0 then base else math.max(0,base-math.floor(elapsed*(overtime.DropPercentPerMinute or 2)/60)*10)
end
function Match.new(sim,config)
 config=config or {};local api={Rankings={},Winner=nil,RestartAt=nil};local history={}
 assert(config.Mode==nil or config.Mode=="FFA" or config.Mode=="Team","Only normal FFA/team victory is implemented")
 assert(not config.Ranked and not config.Tutorial and not config.WaterNukes,"Ranked/tutorial/water-nuke modes are not implemented")
 function api.remember(p)
  history[p.UserId]={IsBot=p.IsBot,UserId=p.UserId,Username=p.Username,SmallId=p.SmallId,Count=sim.Grid.Counts[p.SmallId] or 0,Troops=p.Troops,Gold=p.Gold,Team=p.Team,Disconnected=true,Eliminated=p.Eliminated}
 end
 local function ranking()
  local rows={};local live={}
  for _,p in pairs(sim.Players) do
   local count=sim.Grid.Counts[p.SmallId] or 0
   local row={IsBot=p.IsBot,UserId=p.UserId,Username=p.Username,SmallId=p.SmallId,Count=count,Troops=p.Troops,Gold=p.Gold,Team=p.Team,Eliminated=p.Eliminated,Spectator=p.Spectator}
   if p.Spawn or count>0 or p.Eliminated then table.insert(rows,row) end
   live[p.UserId]=true
  end
  for id,row in pairs(history) do if not live[id] then local copy=table.clone(row);copy.Count=0;table.insert(rows,copy) end end
  table.sort(rows,function(a,b)return a.Count>b.Count or a.Count==b.Count and a.SmallId<b.SmallId end)
  for i,r in ipairs(rows) do r.Rank=i end;api.Rankings=rows;return rows
 end
 local function win(winner)
  api.Winner=winner;api.Winner.Tick=sim.Tick;sim.Phase="Victory";api.ResultsAt=sim.Tick+30;api.RestartAt=sim.Tick+180
  ranking();sim.MetadataDirty=true
 end
 function api.tick()
  if sim.Phase=="Victory" then if sim.Tick>=api.ResultsAt then sim.Phase="Results";sim.MetadataDirty=true end;return end
  if sim.Phase~="Started" or sim.Tick%10~=0 then return end
  local rows=ranking();sim.MetadataDirty=true
  local alive={};for _,row in ipairs(rows) do if row.Count>0 and not row.Disconnected then table.insert(alive,row) end end
  if #alive==0 then
   if #rows>0 then win({Name="No surviving players",Draw=true}) end
   return
  end
  local seconds=(sim.Tick-(sim.StartTick or sim.Tick))/10
  local threshold=Match.threshold(seconds,config)
  local function won(count)
   return (config.MaxTimerMinutes~=nil and seconds>=config.MaxTimerMinutes*60) or seconds>=10200
    or count*1000>math.max(0,sim.LandCount-sim.Grid.FalloutCount)*threshold
  end
  if config.Mode=="Team" then
   local teams,order={},{}
   table.sort(alive,function(a,b)return a.SmallId<b.SmallId end)
   for _,p in ipairs(alive) do if p.Team~=nil then if not teams[p.Team] then teams[p.Team]=0;table.insert(order,p.Team) end;teams[p.Team]+=p.Count end end
   local first={};for i,team in ipairs(order) do first[team]=i end
   table.sort(order,function(a,b)return teams[a]>teams[b] or teams[a]==teams[b] and first[a]<first[b] end)
   local team=order[1]
   if team and team~="Bot" and won(teams[team]) then win({Team=team,Name=tostring(team),Count=teams[team]}) end
  else local p=alive[1];if won(p.Count) then win({UserId=p.UserId,Name=p.Username,Count=p.Count}) end end
 end
 return api
end
return Match
