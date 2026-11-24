--!strict
-- Original Roblox matchmaking adapter. Cloud failures fail closed, never fabricate a join.
local Store=require(script.Parent.LobbyStore)
local State=require(script.Parent.LobbyState)
local Server={}
function Server.new(population)
 local Players=game:GetService("Players");local RS=game:GetService("ReplicatedStorage")
 local Memory=game:GetService("MemoryStoreService");local Teleport=game:GetService("TeleportService")
 local Http=game:GetService("HttpService");local Run=game:GetService("RunService")
 local studio=Run:IsStudio();local job=if studio then "studio" else game.JobId
 local remote=Instance.new("RemoteEvent");remote.Name="WorldConquestLobby";remote.Parent=RS
 local function memory()
  local data={};local api={}
  function api:GetAsync(k)local v=data[k];return if v and v.End>os.time() then v.Value else nil end
  function api:SetAsync(k,v,ttl,sort)data[k]={Value=v,End=os.time()+ttl,Sort=sort or 0};return true end
  function api:UpdateAsync(k,fn,ttl)local v=fn(self:GetAsync(k));if v~=nil then self:SetAsync(k,v,ttl)end;return v end
  function api:RemoveAsync(k)data[k]=nil end
  function api:GetRangeAsync(_,count)local out={};for k in pairs(data) do local v=self:GetAsync(k);if v then table.insert(out,{key=k,value=v})end end;table.sort(out,function(a,b)return a.key<b.key end);while #out>count do table.remove(out)end;return out end
  return api
 end
 local store=Store.new(if studio then memory() else Memory:GetHashMap(if population then "WC11SessionsV1"else "WC10SessionsV1"),if studio then memory() else Memory:GetHashMap(if population then "WC11CodesV1"else "WC10CodesV1"),if studio then memory() else Memory:GetSortedMap(if population then "WC11PublicV1"else "WC10PublicV1"),os.time,function()return Http:GenerateGUID(false)end,population)
 local bridge={Allowed={},BotSettings=nil,VerifiedParties={}};local lobby=nil;local pending={};local limits={};local closing=false
 local function reply(p,message)
  if p.Parent~=Players then return end
  local state=if lobby and lobby.Members[p.UserId] then lobby.project(p.UserId) else {Screen="Menu"}
  state.Message=message;state.LocalTest=studio;remote:FireClient(p,state)
 end
 local function broadcast(message)for _,p in ipairs(Players:GetPlayers())do reply(p,message)end end
 local function present(active)local out={};active=active or lobby;if active then for id in pairs(active.Members)do out[id]=true end end;return out end
 local function publish()
  if not lobby then return nil end
  return store.publish(lobby.Record.ID,job,lobby.Phase,lobby.Host,present())
 end
 local function drop(p,reconnect)
  if bridge.CommunicationChanged then bridge.CommunicationChanged()end
  local active=lobby;local id=active and active.Members[p.UserId] and active.Record.ID
  bridge.Allowed[p]=nil;if bridge.OnLeave then bridge.OnLeave(p)end
  if id then active.remove(p.UserId);task.spawn(function()pcall(store.release,id,p.UserId,reconnect);pcall(store.publish,id,job,active.Phase,active.Host,present(active))end) end
  if bridge.CommunicationChanged then bridge.CommunicationChanged()end
  reply(p);broadcast()
 end
 function bridge.Finish(expected)
  if bridge.CommunicationChanged then bridge.CommunicationChanged()end
  if expected and lobby and lobby.Record.ID~=expected then return end
  if lobby then local old=lobby;old.Phase="Closed";task.spawn(function()pcall(store.publish,old.Record.ID,job,"Closed",old.Host,{})end)end
  for p in pairs(bridge.Allowed)do bridge.Allowed[p]=nil end
  lobby=nil;if bridge.CommunicationChanged then bridge.CommunicationChanged()end;broadcast("Match complete. Choose Public Match or Private Match to play again.")
 end
 local function admit(p,r,token)
  if bridge.CommunicationChanged then bridge.CommunicationChanged()end
  if r.Place~=game.PlaceId then error("Wrong destination place.")end
  local reserved=if studio and r.Kind=="Private" then r.Reserved else game.PrivateServerId
  local accepted=store.admit(r.ID,p.UserId,token,job,reserved)
  if not accepted then error("Admission expired or destination does not match.") end
  if p.Parent~=Players then store.release(r.ID,p.UserId,false);return end
  if not lobby and accepted.Phase=="Game"then store.publish(r.ID,job,"Closed",accepted.Host,{});error("The match server restarted. Please choose a new match.")end
  if lobby and lobby.Phase~="Closed" and lobby.Record.ID~=r.ID then error("This server is hosting another lobby.") end
  if not lobby or lobby.Record.ID~=r.ID then lobby=State.new(accepted,os.time);if accepted.Phase=="Game" then lobby.Phase="Game" end end
  if not lobby.add(p)then error("Lobby closed.")end
  local membership=accepted.Members[tostring(p.UserId)]
  if membership and membership.Party then
   bridge.VerifiedParties[p]={ID=membership.Party,Leader=membership.PartyLeader}
   if bridge.PartyAdmitted then bridge.PartyAdmitted(p,bridge.VerifiedParties[p])end
  end
  if bridge.CommunicationChanged then bridge.CommunicationChanged()end
  if lobby.Phase=="Game" then bridge.Allowed[p]=true;if bridge.OnLate then bridge.OnLate(p)end end
  local listed=pcall(publish);broadcast(if listed then nil else "Joined locally; the server directory is temporarily unavailable.")
 end
 local function failTeleport(p,message)
  local item=pending[p];if not item then return end;pending[p]=nil
  if item.ID then pcall(store.release,item.ID,p.UserId,false)end
  if not pending[p]then reply(p,message or "Teleport failed. Your slot was released; try again.")end
 end
 local function travel(p,r,token,publicFallback)
  if pending[p] then return end
  local options=Instance.new("TeleportOptions")
  if publicFallback then options.ForcePublicServer=true;options:SetTeleportData({WC10Public=true})
  else
   if r.Reserved~="" then options.ReservedServerId=r.Reserved else options.ServerInstanceId=r.Job end
   options:SetTeleportData({WC10Session=r.ID,Ticket=token})
  end
  pending[p]={ID=r and r.ID,Token=token,Started=os.clock()};reply(p,"Joining server…")
  local ok=pcall(function()Teleport:TeleportAsync(game.PlaceId,{p},options)end)
  if not ok then failTeleport(p)end
 end
 local function joinRecord(p,r)
  if not r then error("Lobby unavailable or expired.")end
  local claimed,token=store.claim(r.ID,p.UserId,p.Name,r.Kind)
  if not claimed then error("Lobby is full, already started, or you already have a pending reservation.")end
  if claimed.Job==job or studio then
   local ok,message=pcall(admit,p,claimed,token);if not ok then store.release(r.ID,p.UserId,false);error(message)end
  else travel(p,claimed,token,false)end
 end
 local function friendRecord(p,user)
  if typeof(user)~="number" or user%1~=0 or user<1 then return nil end
  if not p:IsFriendsWithAsync(user)then return nil end
  for _,friend in ipairs(p:GetFriendsOnlineAsync(200))do
   if friend.VisitorId==user and friend.PlaceId==game.PlaceId and typeof(friend.GameId)=="string" then
    local row=store.public(friend.GameId,game.PlaceId);return row and store.get(row.ID)
   end
  end
  return nil
 end
 local function public(p,friend)
  if lobby and lobby.Members[p.UserId]then error("Leave your current lobby first.")end
  if friend then local r=friendRecord(p,friend);if not r then error("Friend's public lobby is unavailable, private, full or already playing.")end;joinRecord(p,r);return end
  -- Prefer an online friend's public lobby, without disclosing private locations.
  local ok,friends=pcall(function()return p:GetFriendsOnlineAsync(50)end)
  if ok then
   for _,f in ipairs(friends)do if f.PlaceId==game.PlaceId and typeof(f.GameId)=="string"then
    local row=store.public(f.GameId,game.PlaceId)
    if row then local r=store.get(row.ID);if r then local claimed,token=store.claim(r.ID,p.UserId,p.Name,"Public");if claimed then if claimed.Job==job then admit(p,claimed,token)else travel(p,claimed,token,false)end;return end end end
   end end
  end
  if lobby and lobby.Phase=="Lobby" and lobby.Record.Kind=="Public"then
   local r,token=store.claim(lobby.Record.ID,p.UserId,p.Name,"Public")
   if r then admit(p,r,token);return end
  end
  for _,row in ipairs(store.find(game.PlaceId))do
   local r,token=store.claim(row.ID,p.UserId,p.Name,"Public")
   if r then if r.Job==job then admit(p,r,token)else travel(p,r,token,false)end;return end
  end
  if (not lobby or lobby.Phase=="Closed") and (game.PrivateServerId=="" or studio)then
   local r=store.create("Public",p.UserId,p.Name,job,"",game.PlaceId);joinRecord(p,r)
  elseif studio then error("Local test server already has an active lobby.")
  else local r=store.create("Public",p.UserId,p.Name,"",Http:GenerateGUID(false),game.PlaceId);joinRecord(p,r)end
 end
 local function start(p)
  local active=lobby
  if not active or not bridge.OnBegin or not active.start(p and p.UserId)then error("Only the private host can start, or public countdown is not finished.")end
  local ok,r=pcall(store.publish,active.Record.ID,job,"Game",active.Host,present(active))
  if lobby~=active or active.Phase~="Game"then error("Lobby changed while starting.")end
  if not ok or not r then active.Phase="Lobby";error("Matchmaking unavailable. Start was not committed; retry.")end
  if active.Record.Kind=="Private"and (not p or p.Parent~=Players or active.Host~=p.UserId)then
   active.Phase="Lobby";pcall(publish);error("Host changed while starting. The new host may retry.")
  end
  active.Record=r
  local people={};for _,member in pairs(lobby.Members)do if member.Parent==Players then table.insert(people,member);bridge.Allowed[member]=true end end
  table.sort(people,function(a,b)return a.UserId<b.UserId end)
  local state=lobby.project(lobby.Host)
  bridge.BotSettings={Enabled=state.Bots>0,Count=state.Bots,Names=state.BotNames,Difficulty=state.Difficulty,DecisionsPerTick=2,SampleCells=64,TerrainCachePages=8192}
  bridge.MatchSeed=lobby.Record.Seed;bridge.ActiveID=lobby.Record.ID;bridge.MatchKind=lobby.Record.Kind;bridge.OnBegin(people,bridge.BotSettings);broadcast()
 end
 function bridge.InLobby(p)return lobby and lobby.Members[p.UserId]~=nil or pending[p]~=nil end
 function bridge.CommunicationScope(p)return if lobby and lobby.Members[p.UserId]then lobby.Record.ID else "menu:"..job end
 function bridge.QueueGroup(people)
  for _,p in ipairs(people)do if p.Parent~=Players or bridge.InLobby(p)then error("Every party member must be available in the main menu.")end end
  local chosen,tokens
  if lobby and lobby.Phase=="Lobby"and lobby.Record.Kind=="Public"then chosen,tokens=store.claimGroup(lobby.Record.ID,people)end
  if not chosen then for _,row in ipairs(store.find(game.PlaceId))do chosen,tokens=store.claimGroup(row.ID,people);if chosen then break end end end
  if not chosen then
   if lobby and lobby.Phase~="Closed"and studio then error("This test server has no room for the party.")end
   local localServer=(not lobby or lobby.Phase=="Closed")and(game.PrivateServerId==""or studio)
   local r=store.create("Public",people[1].UserId,people[1].Name,if localServer then job else "",if localServer then ""else Http:GenerateGUID(false),game.PlaceId)
   chosen,tokens=store.claimGroup(r.ID,people)
  end
  if not chosen then error("No public lobby has enough space for this party.")end
  if chosen.Job==job or studio then
   local ok=pcall(function()for _,p in ipairs(people)do admit(p,chosen,tokens[tostring(p.UserId)])end end)
   if not ok then
    for _,p in ipairs(people)do
     pcall(store.release,chosen.ID,p.UserId,false)
     if lobby and lobby.Record.ID==chosen.ID and lobby.Members[p.UserId]then drop(p,false)end
    end
    error("Party admission failed. Reservations released.")
   end
  else
   local options=Instance.new("TeleportOptions")
   if chosen.Reserved~=""then options.ReservedServerId=chosen.Reserved else options.ServerInstanceId=chosen.Job end
   options:SetTeleportData({WC10Session=chosen.ID,GroupTickets=tokens})
   for _,p in ipairs(people)do pending[p]={ID=chosen.ID,Token=tokens[tostring(p.UserId)],Started=os.clock()};reply(p,"Joining with your party…")end
   local ok=pcall(function()Teleport:TeleportAsync(game.PlaceId,people,options)end)
   if not ok then for _,p in ipairs(people)do failTeleport(p)end;error("Party teleport failed. Reservations released.")end
  end
 end
 function bridge.PublicInfo()
  if lobby and lobby.Phase=="Lobby"and lobby.Record.Kind=="Public"then
   local s=lobby.project(lobby.Host);return {Count=#s.Players+s.Bots,Humans=#s.Players,Capacity=s.Capacity,Deadline=lobby.Deadline,Available=true}
  end
  local rows=store.find(game.PlaceId);local row=rows[1]
  return if row then {Count=row.Count,Capacity=row.Capacity,Available=true,ReservationCount=true} else {Available=false}
 end
 local function request(p,action,data)
  if action=="Hello"then reply(p);return end
  if action=="Leave"then if pending[p]then error("Teleport is in progress; wait for its result.")end;drop(p,false);return end
  if pending[p]then error("A teleport is already pending.")end
  if action=="Public"then if not bridge.PublicParty or not bridge.PublicParty(p)then public(p)end
  elseif action=="JoinFriend"then public(p,data and data.UserId)
  elseif action=="CreatePrivate"then
   if lobby and lobby.Members[p.UserId]then error("Leave your current lobby first.")end
   if studio and lobby and lobby.Phase~="Closed"then error("Local test supports one lobby at a time.")end
   local r=store.create("Private",p.UserId,p.Name,if studio then job else "",Http:GenerateGUID(false),game.PlaceId);joinRecord(p,r)
  elseif action=="JoinPrivate"then
   if lobby and lobby.Members[p.UserId]then error("Leave your current lobby first.")end
   local r=store.code(data and data.Code);if not r then error("Private code is invalid or expired.")end;joinRecord(p,r)
  elseif action=="Settings"then
   local active=lobby
   if not active or not active.Members[p.UserId]then error("Join a private lobby first.")end
   local r=store.settings(active.Record.ID,p.UserId,data and data.Count,data and data.Difficulty)
   if lobby~=active or active.Phase~="Lobby"or active.Host~=p.UserId or p.Parent~=Players then error("Lobby changed while updating settings.")end
   if not r then error("Only the host may change valid bot settings before start; leave room for members.")end
   active.Record=r;broadcast()
  elseif action=="Start"then start(p)
  else error("Unknown lobby action.")end
 end
 remote.OnServerEvent:Connect(function(p,action,sequence,data)
  if typeof(action)~="string" or typeof(sequence)~="number" or sequence%1~=0 or sequence<1 or sequence>9007199254740991 or (data~=nil and typeof(data)~="table")then return end
  local limit=limits[p] or {Sequence=0,At=-math.huge,Busy=false};limits[p]=limit
  if sequence<=limit.Sequence then return end;limit.Sequence=sequence
  if limit.Busy or os.clock()-limit.At<0.75 then reply(p,"Please wait before trying again.");return end
  limit.At=os.clock();limit.Busy=true
  local ok,message=pcall(request,p,action,data);limit.Busy=false
  if not ok then
   -- Do not serialize engine exceptions, MemoryStore values or routing identifiers.
   local reason=tostring(message):match("%.luau:%d+: (.+)") or tostring(message):match(":%d+: (.+)")
   local allowed={"Lobby unavailable or expired.","Private code is invalid or expired.","Leave your current lobby first.","Local test supports one lobby at a time.","Local test server already has an active lobby.","A teleport is already pending.","Teleport is in progress; wait for its result.","Friend's public lobby is unavailable, private, full or already playing.","Lobby is full, already started, or you already have a pending reservation.","Only the host may change valid bot settings before start; leave room for members.","Only the private host can start, or public countdown is not finished.","Matchmaking unavailable. Start was not committed; retry."}
   reply(p,if table.find(allowed,reason)then reason else "Matchmaking service unavailable or access rejected. Please retry.")
  end
 end)
 Teleport.TeleportInitFailed:Connect(function(p,_,_,_,options)
  local item=pending[p];if not item then return end
  local data=options and options:GetTeleportData()
  if data and (data.Ticket==item.Token or data.GroupTickets and data.GroupTickets[tostring(p.UserId)]==item.Token)then failTeleport(p)end
 end)
 local function arrived(p)
  limits[p]={Sequence=0,At=-math.huge,Busy=true}
  task.spawn(function()
   local ok=pcall(function()
    local join=p:GetJoinData();local data=join.TeleportData
    if typeof(data)=="table" and typeof(data.WC10Session)=="string" and (typeof(data.Ticket)=="string"or typeof(data.GroupTickets)=="table")then
     local token=data.Ticket or data.GroupTickets[tostring(p.UserId)]
     local r=store.get(data.WC10Session);if r and typeof(token)=="string"then admit(p,r,token)else reply(p,"Previous session expired. Choose a new match.")end
    elseif typeof(join.LaunchData)=="string" and string.sub(join.LaunchData,1,5)=="WC10:"then
     local code=string.sub(join.LaunchData,6)
     if #code==32 then joinRecord(p,store.code(code))
     elseif string.sub(code,1,2)=="P:"then local r=store.get(string.sub(code,3));if r and r.Kind=="Public"then joinRecord(p,r)else error("Public invitation expired.")end
     else local friend=tonumber(code);if friend then public(p,friend)end end
    elseif typeof(data)=="table" and data.WC10Public==true then public(p)
    elseif lobby and lobby.Phase~="Closed"then
     local record=store.get(lobby.Record.ID);local member=record and record.Members[tostring(p.UserId)]
     if member and member.Expires>os.time()then admit(p,record,member.Token)else reply(p)end
    else reply(p)end
   end)
   if limits[p]then limits[p].Busy=false end
   if not ok then reply(p,"Arrival could not be verified. Choose a match or retry the invitation.")end
  end)
 end
 Players.PlayerAdded:Connect(arrived)
 Players.PlayerRemoving:Connect(function(p)drop(p,true);limits[p]=nil;pending[p]=nil;bridge.VerifiedParties[p]=nil end)
 for _,p in ipairs(Players:GetPlayers())do arrived(p)end
 task.spawn(function()
  local heartbeat=0
  while not closing do
   task.wait(1);heartbeat+=1
   if lobby and lobby.Phase=="Lobby"then
    if not lobby.Members[lobby.Host] and next(lobby.Members)then local ids={};for id in pairs(lobby.Members)do table.insert(ids,id)end;table.sort(ids);lobby.Host=ids[1] end
    if lobby.Record.Kind=="Public" and lobby.Deadline and os.time()>=lobby.Deadline then local ok=pcall(start,nil);if not ok then lobby.Deadline=os.time()+5;broadcast("Waiting for matchmaking service…")end end
    broadcast()
   end
   if heartbeat%10==0 then pcall(publish)end
   for p,item in pairs(pending)do if os.clock()-item.Started>45 then failTeleport(p,"Teleport timed out. Retry matchmaking.")end end
  end
 end)
 game:BindToClose(function()closing=true;if lobby then lobby.Phase="Closed";pcall(publish)end end)
 return bridge
end
return Server
