-- Run production RemoteEvent adapter with two replicas and deterministic service/clock stubs.
local function signal()
 local e={};function e:Connect(fn) self.fn=fn end;function e:Fire(...) if self.fn then self.fn(...) end end;return e
end
local alice,bob={UserId=1,Name="Alice"},{UserId=2,Name="Bob"}
local players={PlayerAdded=signal(),PlayerRemoving=signal()};function players:GetPlayers() return {alice,bob} end
local heartbeat=signal();local now=0
local shared={Config={SimulationSeed=12345,PortStage=2,PlayerColors={1,2},RequestCooldown=0.12},Map=WorldMap,OpenFront={EarthTerrain=EarthTerrain,Clock=Clock}}
local rs={WaitForChild=function() return shared end}
local services={Players=players,ReplicatedStorage=rs,RunService={Heartbeat=heartbeat}}
local replicas={[alice]=Replica.new(EarthTerrain),[bob]=Replica.new(EarthTerrain)}
local ready,stats={},{}
local remote={OnServerEvent=signal(),attributes={},maxFragment=0}
function remote:SetAttribute(key,value) self.attributes[key]=value end
local function receive(p,action,data)
 local r=replicas[p]
 if action=="FoundationBegin" then assert(r.begin(data))
 elseif action=="FoundationChunk" then assert(r.chunk(data))
 elseif action=="FoundationEnd" then assert(r.finish(data));ready[p]=true
 elseif action=="FoundationDelta" then
  remote.maxFragment=math.max(remote.maxFragment,buffer.len(data.Changes))
  if ready[p] or r.loading() then assert(r.delta(data)) end
 elseif action=="FoundationStats" then assert(data.UserId==p.UserId);stats[p]=data end
end
function remote:FireClient(p,action,data) receive(p,action,data) end
function remote:FireAllClients(action,data) for p in pairs(replicas) do receive(p,action,data) end end
runFoundation({GetService=function(_,name) return services[name] end},{Parent={Simulation=Simulation}},function(x)return x end,
 {new=function() return remote end},{fromHSV=function() return 3 end},{clock=function() return now end},{profilebegin=function()end,profileend=function()end})
local function step() now+=0.1;heartbeat:Fire(0.1) end
remote.OnServerEvent:Fire(alice,"Sync");remote.OnServerEvent:Fire(bob,"Sync");step()
assert(ready[alice] and ready[bob])
local x,y=(20+180)/360*8192,(90-5)/180*4096
now+=0.2;remote.OnServerEvent:Fire(alice,"SelectSpawn",x,y);remote.OnServerEvent:Fire(bob,"SelectSpawn",x+30,y)
for _=1,205 do step() end
assert(stats[alice].Count==52 and stats[bob].Count==52)
local before=stats[alice].Troops
remote.OnServerEvent:Fire({UserId=1,Name="Forged"},"Expand",x+100,y,1)
remote.OnServerEvent:Fire(alice,"Expand",x+100,y,0/0);step()
assert(stats[alice].Troops>=before)
now+=0.2;remote.OnServerEvent:Fire(alice,"Expand",x+100,y,0.2)
for _=1,20 do step() end
assert(stats[alice].Count>52 and stats[alice].Committed>0)
assert(stats[bob].Count==52 and stats[bob].Committed==0)
for _,key in ipairs(replicas[alice].Grid.chunkKeys()) do assert(buffer.tostring(replicas[alice].Grid.copyChunk(key))==buffer.tostring(replicas[bob].Grid.copyChunk(key))) end
remote.OnServerEvent:Fire(alice,"Cancel",stats[alice].AttackID)
for _=1,25 do step() end
assert(stats[alice].Committed==0)
players.PlayerRemoving:Fire(bob);step()
assert(replicas[alice].Grid.Counts[2]==0)
assert(remote.maxFragment<=24576 and remote.attributes.SimulationTick>200)
print("Production server adapter: authenticated/rate-limited orders, two replicas, private HUD routing, cancel and disconnect release passed.")
