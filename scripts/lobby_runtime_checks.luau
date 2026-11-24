clock=0
local function signal()
 local s={};function s:Connect(fn)table.insert(self,fn);return {Disconnect=function()end}end
 function s:Fire(...)for _,f in ipairs(self)do f(...)end end;return s
end
local tasks={}
local taskFake={}
local function resume(co)
 local ok,delay=coroutine.resume(co);assert(ok,delay)
 if coroutine.status(co)~="dead"then table.insert(tasks,{Thread=co,At=clock+(delay or 0)})end
end
function taskFake.spawn(fn)resume(coroutine.create(fn))end
function taskFake.wait(seconds)return coroutine.yield(seconds)end
local function advance(seconds)
 for _=1,seconds do clock+=1;local ready={};for i=#tasks,1,-1 do if tasks[i].At<=clock then table.insert(ready,table.remove(tasks,i).Thread)end end;for _,co in ipairs(ready)do resume(co)end end
end
local maps={};local memoryService={}
function memoryService:GetHashMap(name)maps[name]=maps[name]or memory();return maps[name]end
memoryService.GetSortedMap=memoryService.GetHashMap
local function person(id,data)
 local p={UserId=id,Name="Player"..id,DisplayName="Player"..id,Data=data or {},Friends={}}
 function p:GetJoinData()return self.Data end
 function p:GetFriendsOnlineAsync()return self.Friends end
 function p:IsFriendsWithAsync(id)for _,f in ipairs(self.Friends)do if f.VisitorId==id then return true end end;return false end
 return p
end
local function environment(job,reserved,list)
 local ctx={Messages={},Teleports={},Begins=0,Leaves=0,Lates=0}
 local players={PlayerAdded=signal(),PlayerRemoving=signal()};ctx.Players=players
 function players:GetPlayers()return list end
 for _,p in ipairs(list)do p.Parent=players end
 local remote={OnServerEvent=signal()};ctx.Remote=remote
 function remote:FireClient(p,data)ctx.Messages[p.UserId]=data end
 local teleport={TeleportInitFailed=signal()};ctx.Teleport=teleport
 function teleport:TeleportAsync(place,people,options)if ctx.ThrowTeleport then error("network failure")end;table.insert(ctx.Teleports,{Place=place,Player=people[1],Options=options})end
 local instance={new=function(kind)
  if kind=="RemoteEvent"then return remote end
  assert(kind=="TeleportOptions");local options={};function options:SetTeleportData(data)self.Data=data end;function options:GetTeleportData()return self.Data end;return options
 end}
 local services={Players=players,ReplicatedStorage={},MemoryStoreService=memoryService,TeleportService=teleport,HttpService={GenerateGUID=function()return guid()end},RunService={IsStudio=function()return false end}}
 local g={JobId=job,PrivateServerId=reserved,PlaceId=77,GetService=function(_,name)return services[name]end,BindToClose=function(_,fn)ctx.Close=fn end}
 local module=makeLobbyServer(g,{Parent={LobbyStore=LobbyStore,LobbyState=LobbyState}},function(x)return x end,instance,taskFake,{clock=function()return clock end,time=function()return clock end})
 ctx.Bridge=module.new();ctx.Bridge.OnBegin=function(people,bots)ctx.Begins+=1;ctx.Bots=bots;ctx.Started=people end;ctx.Bridge.OnLeave=function()ctx.Leaves+=1 end;ctx.Bridge.OnLate=function()ctx.Lates+=1 end
 function ctx.call(p,action,data,duplicate)
  advance(1);p.Seq=(p.Seq or 0)+(if duplicate then 0 else 1);remote.OnServerEvent:Fire(p,action,p.Seq,data)
 end
 function ctx.add(p)table.insert(list,p);p.Parent=players;players.PlayerAdded:Fire(p)end
 function ctx.remove(p)players.PlayerRemoving:Fire(p);p.Parent=nil;local i=table.find(list,p);if i then table.remove(list,i)end end
 return ctx
end
local a,b,c=person(1),person(2),person(3)
local hub=environment("hub","",{a,b,c})
assert(hub.Messages[1].Screen=="Menu")
hub.call(a,"Public");assert(hub.Messages[1].Screen=="Lobby"and hub.Messages[1].MatchType=="Public")
hub.call(b,"Public");c.Friends={{VisitorId=1,PlaceId=77,GameId="hub"}};hub.call(c,"JoinFriend",{UserId=1});assert(#hub.Messages[3].Players==3)
hub.call(a,"CreatePrivate",nil,true);assert(#hub.Teleports==0,"duplicate sequence ignored")
local lobbyNames=hub.Messages[1].BotNames;assert(#lobbyNames==5)
advance(16);assert(hub.Bots.Names[1]==lobbyNames[1],"Lobby roster must be passed to AI unchanged");assert(hub.Begins==1 and hub.Bots.Count==5 and hub.Bots.Difficulty=="Normal"and #hub.Started==3)
hub.remove(c);local reconnect=person(3);hub.add(reconnect);assert(hub.Lates==1 and hub.Messages[3].Screen=="Game")
hub.Bridge.Finish();assert(hub.Messages[1].Screen=="Menu"and not next(hub.Bridge.Allowed))
hub.call(a,"CreatePrivate");local first=hub.Teleports[#hub.Teleports];assert(first.Options.ReservedServerId and first.Options.Data.Ticket and not first.Options.Data.Reserved)
local wrong={GetTeleportData=function()return {Ticket="stale"}end};hub.Teleport.TeleportInitFailed:Fire(a,nil,nil,77,wrong)
local count=#hub.Teleports;hub.call(a,"CreatePrivate");assert(#hub.Teleports==count,"one pending teleport")
hub.Teleport.TeleportInitFailed:Fire(a,nil,nil,77,first.Options);hub.call(a,"CreatePrivate");assert(#hub.Teleports==count+1)
local trip=hub.Teleports[#hub.Teleports];hub.remove(a)
local host=person(1,{TeleportData=trip.Options.Data});local room=environment("room",trip.Options.ReservedServerId,{host})
assert(room.Messages[1].MatchType=="Private"and room.Messages[1].Host)
local code=room.Messages[1].Code;assert(#code==32 and code~=trip.Options.ReservedServerId)
hub.call(b,"JoinPrivate",{Code=code});local guestTrip=hub.Teleports[#hub.Teleports];assert(guestTrip.Options.ReservedServerId==trip.Options.ReservedServerId)
hub.remove(b);local guest=person(2,{TeleportData=guestTrip.Options.Data});room.add(guest)
room.call(guest,"Settings",{Count=0,Difficulty="Easy"});assert(room.Messages[2].Bots==5)
room.call(host,"Settings",{Count=3,Difficulty="Hard"});assert(room.Messages[1].Bots==3)
room.call(guest,"Start");assert(room.Begins==0)
room.remove(host);advance(1);assert(room.Messages[2].Host)
room.call(guest,"Settings",{Count=1,Difficulty="Easy"});room.call(guest,"Start");assert(room.Begins==1 and room.Bots.Count==1 and room.Bots.Difficulty=="Easy")
for _,ctx in ipairs({hub,room})do for _,data in pairs(ctx.Messages)do assert(not data.Reserved and not data.Ticket and not data.Job and not data.Members)end end
room.Bridge.Finish();room.call(guest,"Public");local publicTrip=room.Teleports[#room.Teleports];assert(publicTrip.Options.ReservedServerId~=trip.Options.ReservedServerId,"new public destination never reuses private room")
room.Teleport.TeleportInitFailed:Fire(guest,nil,nil,77,publicTrip.Options)
room.ThrowTeleport=true;room.call(guest,"CreatePrivate");assert(string.find(room.Messages[2].Message,"Teleport failed",1,true))
hub.Close();room.Close()
print("Stage 10 production LobbyServer: public friend join/countdown, duplicate protection, private routing, ticket admission, host transfer/settings/start, reconnect, stale/failed teleports and menu return passed (service stubs).")
