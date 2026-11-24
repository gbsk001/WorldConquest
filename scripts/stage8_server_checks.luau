-- Real FoundationServer and Replica with deterministic Roblox service stubs.
local function signal()local e={};function e:Connect(fn)self.fn=fn end;function e:Fire(...)if self.fn then self.fn(...) end end;return e end
local list={{UserId=1,Name='One'},{UserId=2,Name='Two'}}
local players={PlayerAdded=signal(),PlayerRemoving=signal()};function players:GetPlayers()return list end
local beat=signal();local now=0
local shared={Config={SimulationSeed=9,PortStage=8,RequestCooldown=.12,PlayerColors={},Buildings={InstantBuild=true},Economy={StartingGold='100000000'},Match={MaxTimerMinutes=.2}},Map=WorldMap,OpenFront={EarthTerrain=EarthTerrain,Clock=Clock,BuildingWire=BuildingWire,ShipWire=ShipWire}}
local services={Players=players,ReplicatedStorage={WaitForChild=function()return shared end},RunService={Heartbeat=beat}}
local replicas,ready,stats={},{},{};for _,p in ipairs(list) do replicas[p]=Replica.new(EarthTerrain) end
local remote={OnServerEvent=signal(),Attributes={}};local resets=0;local phases={}
function remote:SetAttribute(k,v)self.Attributes[k]=v end
function remote:FireClient(p,action,data)
 local r=replicas[p];if not r then return end
 if action=='FoundationBegin' then assert(r.begin(data))
 elseif action=='FoundationChunk' then assert(r.chunk(data))
 elseif action=='FoundationEnd' then assert(r.finish(data));ready[p]=true
 elseif action=='FoundationDelta' then if ready[p] or r.loading() then assert(r.delta(data));if r.Meta then phases[r.Meta.Phase]=true end end
 elseif action=='FoundationStats' then stats[p]=data
 elseif action=='MatchReset' then resets+=1;r.reset(data.MatchID);ready[p]=false end
end
function remote:FireAllClients(a,d)for _,p in ipairs(list) do self:FireClient(p,a,d) end end
runFoundation({GetService=function(_,n)return services[n] end},{Parent={Simulation=Simulation}},function(x)return x end,{new=function()return remote end},{fromHSV=function()return 1 end},{clock=function()return now end},{profilebegin=function()end,profileend=function()end})
local function step()now+=.1;beat:Fire(.1) end
for _,p in ipairs(list) do remote.OnServerEvent:Fire(p,'Sync') end
for _=1,260 do step() end
local profiles=replicas[list[1]].Meta.Players;local a,b=profiles[1],profiles[2]
assert(a.Spawn and b.Spawn and replicas[list[1]].Meta.Phase=='Started')
remote.OnServerEvent:Fire(list[1],'Building',{Action='Build',Type='MissileSilo',Sequence=1,X=a.X,Y=a.Y},nil,nil,1)
for _=1,4 do step() end
assert(#stats[list[1]].Missiles.Structures==1,'real remote silo construction')
for _,bad in ipairs({false,{},'bad',0/0,math.huge,-1,9007199254740992}) do now+=.2;remote.OnServerEvent:Fire(list[1],'Missile',{Type='AtomBomb',Sequence=bad,X=b.X,Y=b.Y},nil,nil,1) end
now+=.2;remote.OnServerEvent:Fire(list[1],'Missile',{Type='AtomBomb',Sequence=2,X=b.X,Y=b.Y},nil,nil,0)
step();step();assert(stats[list[1]].Missiles.Structures[1].Ready==1,'stale round cannot consume launch slot')
now+=.2;remote.OnServerEvent:Fire(list[1],'Missile',{Type='AtomBomb',Sequence=2,X=b.X,Y=b.Y,Cost='0',UserId=2},nil,nil,1)
step();step();assert(stats[list[1]].Missiles.Structures[1].Ready==0,'authenticated launch uses server owner/cost')
local charged=stats[list[1]].Gold
now+=.2;remote.OnServerEvent:Fire(list[1],'Missile',{Type='AtomBomb',Sequence=2,X=b.X,Y=b.Y},nil,nil,1)
step();step();assert(Gold.compare(stats[list[1]].Gold,charged)>=0,'replay cannot charge twice')
local late={UserId=3,Name='Late'};table.insert(list,late);replicas[late]=Replica.new(EarthTerrain);players.PlayerAdded:Fire(late);remote.OnServerEvent:Fire(late,'Sync')
for _=1,8 do step() end
assert(ready[late]);local spectator=false;for _,p in ipairs(replicas[late].Meta.Players) do if p.UserId==3 then spectator=p.Spectator end end;assert(spectator,'late join spectator')
players.PlayerRemoving:Fire(late);table.remove(list,3);step()
while remote.Attributes.SimulationTick<520 do step() end
assert(phases.Selecting and phases.Started and phases.Victory and phases.Results,'all lifecycle phases')
assert(resets==2 and remote.Attributes.MatchID==2,'one restart delivered to both clients')
for _,p in ipairs(list) do local r=replicas[p];assert(ready[p] and r.Meta.MatchID==2 and r.Meta.Phase=='Selecting');assert(r.Grid.FalloutCount==0 and next(r.Buildings)==nil and next(r.Ships)==nil) end
for _,bad in ipairs({false,{},'bad',0/0,math.huge,-1,9007199254740992}) do now+=.2;remote.OnServerEvent:Fire(list[1],'Missile',{Type='AtomBomb',Sequence=bad,X=100,Y=100},nil,nil,2) end
now+=.2;remote.OnServerEvent:Fire(list[1],'SelectSpawn',4000,2000,nil,1)
for _=1,3 do step() end
local r=replicas[list[1]];local tick=r.Tick
assert(r.delta({MatchID=1,Tick=tick+1,Changes=buffer.create(0)}));assert(r.Tick==tick,'old-round delta ignored')
assert(not r.delta({MatchID=3,Tick=tick+1,Changes=buffer.create(0)}),'future epoch requires snapshot')
assert(not r.begin({Meta={MatchID=1},MapHash=EarthTerrain.MaskHash,Count=0,Tick=tick+1,ID=9999}),'old-round snapshot rejected')
players.PlayerRemoving:Fire(list[2]);table.remove(list,2);step()
players.PlayerRemoving:Fire(list[1]);table.remove(list,1);step();step()
assert(remote.Attributes.MatchID==3,'empty server resets match')
print('Stage 8 server/replica: waiting/spawn/countdown/gameplay/victory/results/restart, two-client fresh snapshot, stale-round requests/deltas, malformed intents and empty-server cleanup passed (simulated services).')
