local records,codes,directory=memory(),memory(),memory()
local store=LobbyStore.new(records,codes,directory,function()return clock end,guid)
local public=store.create("Public",1,"Host","job-a","",77)
assert(not pcall(function()LobbyState.new({Kind="Solo"},function()return clock end)end))
local private=store.create("Private",2,"Host","","reserved-secret",77)
do
 local groupLobby=store.create("Public",31,"Leader","group-job","",77)
 local members={{UserId=31,Name="Leader"},{UserId=32,Name="Friend"},{UserId=33,Name="FriendTwo"}}
 local claimed,tickets=store.claimGroup(groupLobby.ID,members);assert(claimed and tickets["31"]~=tickets["32"])
 assert(not store.claimGroup(private.ID,members),"private crossover")
 assert(not store.admit(groupLobby.ID,32,tickets["31"],"group-job",""),"group ticket identity")
 assert(not store.publish(groupLobby.ID,"group-job","Game",31,{[31]=true}),"AI cannot consume reserved human slots")
 for id=34,49 do assert(store.claim(groupLobby.ID,id,"Human"..id,"Public"))end
 local rejected=store.claimGroup(groupLobby.ID,{{UserId=50,Name="A"},{UserId=51,Name="B"}});assert(not rejected)
 assert(store.get(groupLobby.ID).Members["50"]==nil,"group reservation is all or nothing")
 print("Stage 13 party admission: atomic human group reservations, capacity rollback, ticket identity, private isolation and AI-start reservation barrier passed.")
end
assert(#private.Code==32 and private.Code~="reserved-secret")
assert(store.code(string.lower(private.Code)).ID==private.ID)
assert(not store.code("bad")and not store.claim(private.ID,8,"Intruder","Public"))
local r,t=store.claim(private.ID,2,"Host","Private");assert(r and t)
assert(not store.claim(private.ID,2,"Host","Private"),"duplicate reservation")
assert(not store.admit(private.ID,3,t,"private-job","reserved-secret"),"ticket bound to user")
assert(not store.admit(private.ID,2,t,"job-a",""),"private/public crossover")
assert(not store.admit(private.ID,2,"forged","private-job","reserved-secret"))
assert(store.admit(private.ID,2,t,"private-job","reserved-secret"))
assert(not store.admit(private.ID,2,t,"another-job","reserved-secret"),"split lease")
assert(not store.settings(private.ID,8,0,"Hard"),"host permission")
assert(not store.settings(private.ID,2,0,"Impossible")and not store.settings(private.ID,2,0/0,"Easy"))
assert(store.settings(private.ID,2,19,"Hard"));assert(not store.claim(private.ID,3,"Guest","Private"),"bots reserve private capacity")
assert(store.settings(private.ID,2,2,"Normal"))
local second,token=store.claim(private.ID,3,"Guest","Private");assert(second)
store.release(private.ID,3,false);assert(not store.admit(private.ID,3,token,"private-job","reserved-secret"),"released failed teleport")
store.release(private.ID,2,true);assert(store.admit(private.ID,2,t,"private-job","reserved-secret"),"grace reconnect")
store.publish(private.ID,"private-job","Game",2,{[2]=true});assert(not store.claim(private.ID,4,"Guest","Private"),"no fresh mid-game code admission")
store.release(private.ID,2,true);clock+=61;assert(not store.admit(private.ID,2,t,"private-job","reserved-secret"),"expired reconnect")
clock=0
for id=1,20 do assert(store.claim(public.ID,id,"P"..id,"Public"))end
assert(not store.claim(public.ID,21,"Full","Public"))
store.publish(public.ID,"job-a","Lobby",1,{[1]=true});assert(not store.public("job-a",77),"full directory filtering")
store.release(public.ID,20,false);store.publish(public.ID,"job-a","Lobby",1,{[1]=true});assert(store.public("job-a",77)and #store.find(77)==1)
assert(not store.public("job-a",99))
assert(not store.publish(public.ID,"job-a","Game",1,{[1]=true}),"pending humans must not become AI-filled slots")
local arrived={};for id=1,19 do arrived[id]=true end
assert(store.publish(public.ID,"job-a","Game",1,arrived));assert(#store.find(77)==0)
local state=LobbyState.new(private,function()return clock end)
state.add({UserId=2,Name="Host"});state.add({UserId=3,Name="Guest"})
assert(not state.start(3));state.remove(2);assert(state.Host==3 and state.start(3))
local projection=state.project(3);assert(not projection.Reserved and not projection.Members and not projection.Job and not projection.Token and projection.Code==private.Code)
state.remove(3);assert(state.Phase=="Closed")
local pub=LobbyState.new(public,function()return clock end);pub.add({UserId=1,Name="One"});assert(not pub.start(1));clock=15;assert(pub.start(nil));assert(pub.project(1).Bots==5)
records.Fail=true;assert(not pcall(store.claim,public.ID,1,"One","Public"));records.Fail=false
print("Stage 10 store/state: exactly two types, private codes, user-bound tickets, expiry, capacity, bot validation, host transfer, countdown, stale/full directories and failure/reconnect privacy passed.")

do
 local r={ID="roster-session-1",Kind="Private",Host=1,Bots=19,Difficulty="Normal"}
 local s=LobbyState.new(r,function()return 0 end);s.add({UserId=1,Name="Human"})
 local first=s.project(1).BotNames;local used={human=true}
 for _,name in ipairs(first)do assert(not used[string.lower(name)]);used[string.lower(name)]=true;assert(not string.match(name,"Normal %d") and not string.match(name,"Bot_%d"))end
 r.Difficulty="Hard";assert(s.project(1).BotNames[1]==first[1])
 r.Bots=2;s.project(1);r.Bots=19;assert(s.project(1).BotNames[19]==first[19])
 local again=LobbyState.new(r,function()return 0 end);again.add({UserId=1,Name="Human"});assert(again.project(1).BotNames[1]==first[1])
 local nextRound=LobbyState.new({ID="roster-session-2",Kind="Private",Host=1,Bots=5,Difficulty="Normal"},function()return 0 end);nextRound.add({UserId=1,Name="Human"});assert(nextRound.project(1).BotNames[1]~=first[1])
 print("Lobby bot identity: 19 unique names, stable difficulty/count changes, seeded reconstruction and fresh-session variation passed.")
end

-- Production Stage 11 population contract; no live MemoryStore services.
do
 local population={PublicTarget=250,SafeParticipants=20,MaximumParticipants=500}
 local s=LobbyStore.new(memory(),memory(),memory(),function()return clock end,guid,population)
 local a=s.create("Public",101,"One","job11","",77)
 local b=s.create("Public",102,"Two","job12","",77)
 assert(a.Capacity==20 and a.PublicTarget==20 and a.Seed~=b.Seed)
 local lobby=LobbyState.new(a,function()return clock end)
 lobby.add({UserId=101,Name="One"});assert(lobby.project(101).Bots==19)
 lobby.add({UserId=102,Name="Two"});local p=lobby.project(101)
 assert(p.Bots==18 and #p.BotNames==18 and p.MatchSeed==a.Seed and p.Capacity==20)
 for i=1,20 do assert(s.claim(a.ID,i,"Player"..i,"Public"))end
 assert(not s.claim(a.ID,21,"Full","Public"))
 print("Stage 11 lobby: fresh seeds, safe population cap, human priority, roster names and seed propagation passed.")
end
