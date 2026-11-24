-- Production FoundationServer RemoteEvent boundary with two clients (service stubs, not Studio).
local function signal()local e={};function e:Connect(f)self.fn=f end;function e:Fire(...)if self.fn then self.fn(...) end end;return e end
local terrain=makeMap(192,128,0)
local map={cell=function(x,y)if typeof(x)=='number' and typeof(y)=='number' and x==x and y==y and x>=0 and y>=0 and x<192 and y<128 then return math.floor(y)*192+math.floor(x)+1 end;return nil end}
local alice,bob={UserId=1,Name='Alice'},{UserId=2,Name='Bob'}
local players={PlayerAdded=signal(),PlayerRemoving=signal()};function players:GetPlayers()return {alice,bob}end
local heartbeat=signal();local now=0
local shared={Config={SimulationSeed=12345,PortStage=6,Economy={StartingGold='2000000'},PlayerColors={1,2},RequestCooldown=.12},Map=map,OpenFront={EarthTerrain=terrain,Clock=Clock,BuildingWire=BuildingWire,ShipWire=ShipWire}}
local services={Players=players,ReplicatedStorage={WaitForChild=function()return shared end},RunService={Heartbeat=heartbeat}}
local replicas={[alice]=Replica.new(terrain),[bob]=Replica.new(terrain)};local ready,stats={},{}
local remote={OnServerEvent=signal(),attributes={},maxFragment=0};function remote:SetAttribute(k,v)self.attributes[k]=v end
local function receive(p,action,data)
 local r=replicas[p]
 if action=='FoundationBegin' then assert(r.begin(data)) elseif action=='FoundationChunk' then assert(r.chunk(data)) elseif action=='FoundationEnd' then assert(r.finish(data));ready[p]=true
 elseif action=='FoundationDelta' then remote.maxFragment=math.max(remote.maxFragment,buffer.len(data.Changes)+buffer.len(data.BuildingChanges)+buffer.len(data.ShipChanges));if ready[p] or r.loading() then assert(r.delta(data)) end
 elseif action=='FoundationStats' then assert(data.UserId==p.UserId);stats[p]=data end
end
function remote:FireClient(p,a,d)receive(p,a,d)end
function remote:FireAllClients(a,d)for p in pairs(replicas) do receive(p,a,d)end end
runFoundation({GetService=function(_,n)return services[n]end},{Parent={Simulation=Simulation}},function(x)return x end,{new=function()return remote end},{fromHSV=function()return 3 end},{clock=function()return now end},{profilebegin=function()end,profileend=function()end})
local function step()now+=.1;heartbeat:Fire(.1)end
remote.OnServerEvent:Fire(alice,'Sync');remote.OnServerEvent:Fire(bob,'Sync');step()
now+=.2;remote.OnServerEvent:Fire(alice,'SelectSpawn',20,40);remote.OnServerEvent:Fire(bob,'SelectSpawn',171,80)
for _=1,260 do step() end
assert(ready[alice] and ready[bob] and stats[alice].Count>0 and stats[bob].Count>0)
local function order(p,action,payload)now+=.2;remote.OnServerEvent:Fire(p,action,payload);step();step()end
order({UserId=1},'Naval',{Action='Transport',Sequence=1,X=171,Y=80,Allocation=.2});assert(next(replicas[alice].Ships)==nil)
order(alice,'Naval',{Action='Transport',Sequence=0/0,X=171,Y=80,Allocation=.2});assert(next(replicas[alice].Ships)==nil)
order(alice,'Naval',{Action='Transport',Sequence=1,X=171,Y=80,Allocation=.2,Troops=99999999,Owner=2,Gold='999999999'})
assert(#ShipWire.list(replicas[alice].Ships)==1 and replicas[bob].Ships[1].Owner==1 and replicas[bob].Ships[1].Troops<100000)
order(alice,'Naval',{Action='Transport',Sequence=1,X=171,Y=80,Allocation=.2});assert(#ShipWire.list(replicas[bob].Ships)==1)
order(bob,'Naval',{Action='Retreat',Sequence=1,UnitID=1});assert(bit32.band(replicas[bob].Ships[1].Flags,4)==0)
now+=2.1;remote.OnServerEvent:Fire(bob,'Sync');step();assert(replicas[bob].Ships[1] and replicas[bob].Ships[1].Owner==1,'moving-ship snapshot')
order(alice,'Naval',{Action='Retreat',Sequence=2,UnitID=1});assert(bit32.band(replicas[bob].Ships[1].Flags,4)~=0)
for _=1,100 do step() end;assert(next(replicas[alice].Ships)==nil)
order(alice,'Building',{Action='Build',Type='Port',Sequence=3,X=20,Y=40})
assert(#replicas[bob].Meta.Buildings==1 and replicas[bob].Meta.Buildings[1].UnderConstruction)
order(alice,'Naval',{Action='Warship',Sequence=4,X=80,Y=50});assert(next(replicas[alice].Ships)==nil,'unfinished port allowed warship')
for _=1,55 do step() end
assert(not replicas[bob].Meta.Buildings[1].UnderConstruction)
order(alice,'Naval',{Action='Warship',Sequence=5,X=80,Y=50});assert(stats[alice].Naval.Warships==1)
local ship=ShipWire.list(replicas[alice].Ships)[1];assert(ship.Type=='Warship' and ship.Owner==1)
order(alice,'Naval',{Action='Move',Sequence=6,UnitID=ship.ID,X=100,Y=60})
for _=1,20 do step() end
eq(ShipWire.list(replicas[alice].Ships),ShipWire.list(replicas[bob].Ships),'server replicas')
assert(remote.maxFragment<=24192 and remote.attributes.NavalMilliseconds>=0)
players.PlayerRemoving:Fire(alice);step();assert(next(replicas[bob].Ships)==nil,'disconnect fleet cleanup')
print('Stage 6 production RemoteEvent: authenticated orders, forged fields, duplicate protection, port construction, shared building/naval sequence, private HUD, moving snapshots, two replicas, cleanup and <=24 KiB fragments passed (service stubs).')
