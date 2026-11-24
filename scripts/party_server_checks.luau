local partyNow=1000;local partyClock={time=function()return partyNow end,clock=function()return partyNow end}
local inviteMemory={};local inviteStore={SetAsync=function(_,k,v)inviteMemory[k]=v end,GetAsync=function(_,k)return inviteMemory[k]end}
local uuid=0
services.HttpService={GenerateGUID=function()uuid+=1;return "test-guid-"..uuid end}
services.MemoryStoreService={GetHashMap=function()return inviteStore end}
local teleports=0;services.TeleportService={TeleportInitFailed=signal(),TeleportAsync=function()teleports+=1 end}
game.JobId="same-server";game.PlaceId=77
local function partyPlayer(id,name,friends)
 local p={UserId=id,Name=name,Parent=playerService,JoinData={}}
 function p:GetJoinData()return self.JoinData end
 function p:IsFriendsWithAsync()return friends end
 return p
end
human=partyPlayer(101,"Leader",true);persons={human}
task.spawn=function(fn,...)
 local thread=coroutine.create(fn);local ok,errorMessage=coroutine.resume(thread,...);assert(ok,errorMessage)
end
task.wait=function()coroutine.yield()end
-- MODULE --
local groupCalls=0;local lobbyBridge={InLobby=function()return false end,QueueGroup=function(people)groupCalls+=1;assert(#people==2)end,PublicInfo=function()return {Available=false}end}
PartyServer.new(lobbyBridge)
local partyNet=serverRemotes[#serverRemotes]
partyNet.OnServerEvent:Fire(human,"Create");local token=partyNet.Last.InviteToken;assert(token)
local friend=partyPlayer(102,"Friend",true);friend.JoinData={LaunchData="WC13PART:"..token};table.insert(persons,friend)
playerService.PlayerAdded:Fire(friend);assert(partyNet.Last.Invitation and partyNet.Last.Invitation.Leader==101)
partyNow+=2;partyNet.OnServerEvent:Fire(friend,"Accept");assert(#partyNet.Last.Members==2)
assert(lobbyBridge.PublicParty(friend));assert(groupCalls==0,"nonleader cannot queue")
assert(lobbyBridge.PublicParty(human));assert(groupCalls==1)
partyNow+=2;partyNet.OnServerEvent:Fire(friend,"Kick",101);assert(#partyNet.Last.Members==2,"member cannot kick leader")
local stranger=partyPlayer(103,"Stranger",false);stranger.JoinData={LaunchData="WC13PART:"..token};table.insert(persons,stranger)
playerService.PlayerAdded:Fire(stranger);assert(not partyNet.Last.Invitation,"friendship required")
partyNow+=121;local late=partyPlayer(104,"LateFriend",true);late.JoinData={LaunchData="WC13PART:"..token};table.insert(persons,late)
playerService.PlayerAdded:Fire(late);assert(not partyNet.Last.Invitation,"invitation expired")
playerService.PlayerRemoving:Fire(human);partyNow+=2;partyNet.OnServerEvent:Fire(friend,"Hello");assert(partyNet.Last.Leader==102)
print("Stage 13 production PartyServer: create, Roblox-friend invite admission, accept, nonfriend/expired rejection, leader-only group queue, kick permission and disconnect leadership transfer passed (service stubs; no actual invitation sent).")
-- Destination arrivals may be reordered. Only the server-verified admission hook restores a party.
local first=partyPlayer(201,"ArrivedFirst",true);local leader=partyPlayer(202,"VerifiedLeader",true)
table.insert(persons,first);table.insert(persons,leader)
lobbyBridge.PartyAdmitted(first,{ID="verified-transfer",Leader=202})
lobbyBridge.PartyAdmitted(leader,{ID="verified-transfer",Leader=202})
partyNow+=2;partyNet.OnServerEvent:Fire(first,"Hello");assert(partyNet.Last.Leader==202 and #partyNet.Last.Members==2)
lobbyBridge.QueueGroup=function(people)assert(people[1]==leader and people[2]==first);groupCalls+=1 end
assert(lobbyBridge.PublicParty(leader));assert(groupCalls==2)
lobbyBridge.PartyAdmitted(first,{ID="verified-transfer",Leader=202})
partyNow+=2;partyNet.OnServerEvent:Fire(first,"Hello");assert(#partyNet.Last.Members==2,"duplicate admission must not duplicate membership")
print("Verified cross-server party restoration: reordered arrivals, original leader, duplicate admission and leader-first requeue passed with service stubs.")
