--!strict
-- Roblox friendship checked on server; invites expire in 120 seconds.
local State=require(script.Parent.PartyState)
local Server={}
function Server.new(session)
 local Players=game:GetService("Players");local RS=game:GetService("ReplicatedStorage")
 local Memory=game:GetService("MemoryStoreService");local Http=game:GetService("HttpService")
 local Teleport=game:GetService("TeleportService");local studio=game:GetService("RunService"):IsStudio()
 local temporary={};local invitations=if studio then {SetAsync=function(_,k,v)temporary[k]=v end,GetAsync=function(_,k)return temporary[k]end}else Memory:GetHashMap("WC13PartyInvites")
 local state=State.new();local incoming={};local limits={};local travelling={};local info={Available=false}
 local remote=Instance.new("RemoteEvent");remote.Name="WorldConquestParty";remote.Parent=RS
 local function reply(p,message)
  if p.Parent~=Players then return end
  local party=state.Parties[state.Membership[p.UserId]];local members={}
  if party then for _,id in ipairs(party.Members)do local member=Players:GetPlayerByUserId(id);if member then table.insert(members,{UserId=id,Name=member.Name,Leader=id==party.Leader})end end end
  local invitation=incoming[p];if invitation and invitation.Expires<os.time()then incoming[p]=nil;invitation=nil end
  remote:FireClient(p,{Members=members,Leader=party and party.Leader,InviteToken=party and party.Token,Invitation=invitation and {Leader=invitation.Leader,Name=invitation.Name,Expires=invitation.Expires},Message=message,MatchInfo=info,Now=os.time()})
 end
 local function broadcast()for _,p in ipairs(Players:GetPlayers())do reply(p)end end
 function session.PartyAdmitted(p,verified)
  -- Called only after user-bound MemoryStore admission; never from TeleportData.
  if state.Membership[p.UserId]then return end
  local party=state.Parties[verified.ID]
  if not party then party=state.create(verified.ID,p.UserId)else state.add(verified.ID,p.UserId)end
  if table.find(party.Members,verified.Leader)then party.Leader=verified.Leader end
  broadcast()
 end
 local function fresh(p)
  local party=state.Parties[state.Membership[p.UserId]];if not party or party.Leader~=p.UserId then error("Only the party leader can invite.")end
  local token=Http:GenerateGUID(false);party.Token=token
  invitations:SetAsync(token,{Party=party.ID,Leader=p.UserId,Name=p.Name,Job=game.JobId,Place=game.PlaceId,Expires=os.time()+120},120)
 end
 local function invited(p,token)
  if type(token)~="string"or #token>64 then return nil end
  local item=invitations:GetAsync(token)
  if not item or item.Expires<=os.time()or item.Place~=game.PlaceId or item.Leader==p.UserId or not p:IsFriendsWithAsync(item.Leader)then return nil end
  item.Token=token;return item
 end
 local function acceptLocal(p,item)
  local party=state.Parties[item.Party]
  if not party or party.Leader~=item.Leader or party.Token~=item.Token or session.InLobby(p)then return false end
  for _,id in ipairs(party.Members)do local member=Players:GetPlayerByUserId(id);if not member or session.InLobby(member)then return false end end
  return state.add(item.Party,p.UserId)
 end
 function session.PublicParty(p)
  local party=state.Parties[state.Membership[p.UserId]];if not party then return false end
  if party.Leader~=p.UserId then reply(p,"Only the party leader can press PLAY.");return true end
  if party.Queued then reply(p,"Your party is already queueing.");return true end
  local people={};for _,id in ipairs(party.Members)do local member=Players:GetPlayerByUserId(id);if not member then reply(p,"Wait for all party members to arrive.");return true end;table.insert(people,member)end
  -- The admission record stores the first member as leader, including after transfers.
  table.sort(people,function(a,b)if a==b then return false elseif a.UserId==party.Leader then return true elseif b.UserId==party.Leader then return false else return a.UserId<b.UserId end end)
  party.Queued=true
  local ok=pcall(session.QueueGroup,people);party.Queued=false
  if not ok then reply(p,"The party could not join together. Check that everyone is in the menu, then retry.")end
  return true
 end
 remote.OnServerEvent:Connect(function(p,action,data)
  if type(action)~="string"or (data~=nil and (type(data)~="number"or data%1~=0 or data<=0))then return end
  local l=limits[p]or{At=-math.huge};limits[p]=l;if l.Busy or os.clock()-l.At<1 then return end;l.At=os.clock();l.Busy=true
  local ok=pcall(function()
   if action=="Hello"then reply(p);return end
   if session.InLobby(p)or travelling[p]then reply(p,"Manage your party from the main menu.");return end
   if action=="Create"then state.create(Http:GenerateGUID(false),p.UserId);fresh(p)
   elseif action=="Invite"then fresh(p)
   elseif action=="Leave"then state.remove(p.UserId,p.UserId)
   elseif action=="Kick"then if not state.remove(data,p.UserId)then error("Not permitted")end
   elseif action=="Decline"then incoming[p]=nil
   elseif action=="Accept"then
    local item=incoming[p]and invited(p,incoming[p].Token);if not item then error("Invitation expired")end
    if state.Membership[p.UserId]then error("Leave your party first")end
    if item.Job==game.JobId or studio then
     if not acceptLocal(p,item)then error("Party full or unavailable")end;incoming[p]=nil
    else
     local options=Instance.new("TeleportOptions");options.ServerInstanceId=item.Job;options:SetTeleportData({WC13Party=item.Token})
     travelling[p]=os.clock();local success=pcall(function()Teleport:TeleportAsync(game.PlaceId,{p},options)end)
     if not success then travelling[p]=nil;error("Teleport failed")end
    end
   end
   broadcast()
  end);l.Busy=false;if not ok then reply(p,"Party request unavailable, expired or not permitted. Please retry.")end
 end)
 local function arrived(p)task.spawn(function()
  local ok=pcall(function()
   local join=p:GetJoinData();local token=if type(join.TeleportData)=="table"then join.TeleportData.WC13Party else nil
   if token then local item=invited(p,token);if not item or item.Job~=game.JobId or not acceptLocal(p,item)then error("Expired party")end
   elseif type(join.LaunchData)=="string"and string.sub(join.LaunchData,1,9)=="WC13PART:"then incoming[p]=invited(p,string.sub(join.LaunchData,10))end
  end);reply(p,if ok then nil else "Party invitation expired or the party is full.");broadcast()
 end)end
 Players.PlayerAdded:Connect(arrived);Players.PlayerRemoving:Connect(function(p)state.remove(p.UserId,p.UserId,true);limits[p]=nil;incoming[p]=nil;travelling[p]=nil;broadcast()end)
 Teleport.TeleportInitFailed:Connect(function(p)if travelling[p]then travelling[p]=nil;reply(p,"Party teleport failed. You can retry accepting the invitation.")end end)
 for _,p in ipairs(Players:GetPlayers())do arrived(p)end
 for p,verified in pairs(session.VerifiedParties or {})do session.PartyAdmitted(p,verified)end
 task.spawn(function()while remote.Parent do
  task.wait(10);local ok,result=pcall(session.PublicInfo);info=if ok then result else {Unavailable=true}
  for p,at in pairs(travelling)do if os.clock()-at>45 then travelling[p]=nil end end;broadcast()
 end end)
end
return Server
