-- Real production adapter, deterministic service stubs. No real Roblox clients.
local function signal()
 local e={};function e:Connect(fn)self.fn=fn end;function e:Fire(...)if self.fn then self.fn(...) end end;return e
end
local list={};for id=1,10 do list[id]={UserId=id,Name='P'..id} end
local players={PlayerAdded=signal(),PlayerRemoving=signal()};function players:GetPlayers()return list end
local beat=signal();local now=0
local shared={Config={SimulationSeed=9,PortStage=7,RequestCooldown=.12,PlayerColors={},Economy={StartingGold='1000000'}},Map=WorldMap,OpenFront={EarthTerrain=EarthTerrain,Clock=Clock,BuildingWire=BuildingWire,ShipWire=ShipWire}}
local rs={WaitForChild=function()return shared end}
local services={Players=players,ReplicatedStorage=rs,RunService={Heartbeat=beat}}
local replicas,ready,stats={},{},{};for _,p in ipairs(list) do replicas[p]=Replica.new(EarthTerrain) end
local remote={OnServerEvent=signal(),Attributes={}};local active,peak,begins=0,0,0;local frameBytes={}
function remote:SetAttribute(k,v)self.Attributes[k]=v end
function remote:FireClient(p,action,data)
 local r=replicas[p];if not r then return end
 if action=='FoundationBegin' then begins+=1;active+=1;peak=math.max(peak,active);assert(r.begin(data))
 elseif action=='FoundationChunk' then
  frameBytes[p]=(frameBytes[p] or 0)+buffer.len(data.Data or data.Buildings or data.Ships);assert(frameBytes[p]<=32768)
  assert(r.chunk(data))
 elseif action=='FoundationEnd' then active-=1;assert(r.finish(data));ready[p]=true
 elseif action=='FoundationDelta' then if ready[p] or r.loading() then assert(r.delta(data)) end
 elseif action=='FoundationStats' then assert(data.UserId==p.UserId);stats[p]=data end
end
function remote:FireAllClients(action,data)for _,p in ipairs(list) do self:FireClient(p,action,data) end end
runFoundation({GetService=function(_,n)return services[n] end},{Parent={Simulation=Simulation}},function(x)return x end,
 {new=function()return remote end},{fromHSV=function()return 1 end},{clock=function()return now end},{profilebegin=function()end,profileend=function()end})
local function step()table.clear(frameBytes);now+=.1;beat:Fire(.1) end
for _,p in ipairs(list) do for _=1,100 do remote.OnServerEvent:Fire(p,'Sync') end end
for _=1,6 do step() end
assert(begins==10 and peak<=4)
for _,p in ipairs(list) do assert(ready[p]) end
local valid=(20+180)/360*8192;local y=(90-5)/180*4096
for _,p in ipairs(list) do remote.OnServerEvent:Fire(p,'SelectSpawn',valid+p.UserId*30,y) end
for _=1,210 do step() end
for _,value in ipairs({false,{},'bad',0/0,math.huge,-math.huge,-1,9007199254740992}) do
 now+=.2
 remote.OnServerEvent:Fire(list[1],'Expand',value,y,1)
 now+=.2;remote.OnServerEvent:Fire(list[1],'Building',{Action='Build',Sequence=value,Type='City',X=valid,Y=y})
 now+=.2;remote.OnServerEvent:Fire(list[1],'Naval',{Action='Move',Sequence=1,UnitID=value,X=valid,Y=y})
end
now+=.2;remote.OnServerEvent:Fire({UserId=1,Name='Spoof'},'Expand',valid,y,1)
remote.OnServerEvent:Fire(list[1],'GrantGold','999999999999999999')
for _=1,3 do step() end
assert(stats[list[1]].Committed==0 and #stats[list[1]].Attacks==0)
assert(replicas[list[1]].Meta.Stage==7)
assert(remote.Attributes.TickAverageMilliseconds~=nil and remote.Attributes.TickP95Milliseconds~=nil)
players.PlayerRemoving:Fire(list[10]);for _=1,3 do step() end
assert(replicas[list[1]].Grid.Counts[10]==0)
print('Stage 7 production RemoteEvent: 10 simulated clients, 1000 Sync attempts/10 snapshots, <=4 active transfers, <=32 KiB/client/frame, malformed/forged inputs, Stage 7 telemetry and disconnect recovery passed.')
