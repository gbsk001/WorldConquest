-- Executes production server against deterministic service stubs (not live transport).
local function signal()
	local event={handlers={}}
	function event:Connect(callback) table.insert(self.handlers,callback) end
	function event:Fire(...) for _,callback in ipairs(self.handlers) do callback(...) end end
	return event
end
local now=0
local a,b={UserId=-1,Name="Alice"},{UserId=-2,Name="Bob"}
local players={PlayerAdded=signal(),PlayerRemoving=signal()}
function players:GetPlayers() return {a,b} end
local config={SpawnSeconds=20,RequestCooldown=0.12,ExpansionCooldown=0.25,PlayerColors={"blue","red","green"}}
config.GrowthTickSeconds=0.1; config.ClaimsPerPlayerPerTick=16; config.ClaimsPerTick=256
config.FrontierChecksPerTick=4096; config.FrontierChecksPerPlayer=128; config.MaxOwnedCells=1048576
local modules={Config=config,Map=WorldMap,Rules=SpawnRules,Frontier=Frontier}
local folder={}
function folder:WaitForChild(name) return modules[name] or folder end
local services={Players=players,ReplicatedStorage=folder,Workspace={GetServerTimeNow=function() return now end}}
local remote={OnServerEvent=signal(),messages={},results={}}
local replicas={{},{}}
local metadata=nil
local function apply(replica,action,data)
	if action=="State" then
		table.clear(replica)
		for _,group in ipairs(data.Territory) do
			for offset=0,buffer.len(group.Cells)-1,4 do replica[buffer.readu32(group.Cells,offset)]=group.Owner end
		end
	elseif action=="Delta" then
		for _,group in ipairs(data.Groups) do
            for offset=0,buffer.len(group.Cells)-1,4 do replica[buffer.readu32(group.Cells,offset)]=group.Owner end
        end
	end
	if data.Released then
		for offset=0,buffer.len(data.Released)-1,4 do replica[buffer.readu32(data.Released,offset)]=nil end
	end
end
function remote:FireAllClients(action,data)
	table.insert(self.messages,{Action=action,Data=data})
	if action~="Delta" then metadata=data end
	for _,replica in ipairs(replicas) do apply(replica,action,data) end
end
function remote:FireClient(player,action,data)
	if action=="State" then
		metadata=data
		apply(replicas[if player==a then 1 else 2],action,data)
	else table.insert(self.results,{Player=player,Message=data}) end
end
local loop
runServer({GetService=function(_,name) return services[name] end},{Parent=folder},function(v) return v end,
	{new=function() return remote end},{new=function() return {NextInteger=function() return 1 end} end},
	{fromHSV=function(h) return h end},{spawn=function(f) loop=coroutine.create(f); assert(coroutine.resume(loop)) end,wait=function() coroutine.yield() end},{clock=function() return now end})
local function request(player,action,x,y) remote.OnServerEvent:Fire(player,action,x,y) end
local function at(lon,lat) return (lon+180)/360*WorldMap.Width,(90-lat)/180*WorldMap.Height end
assert(metadata.Phase=="Waiting")
request(a,"Sync")
assert(metadata.Phase=="Selecting" and metadata.Deadline==20)
local ax,ay=at(20.0123,5.0123)
now=0.2
request(a,"SelectSpawn",ax,ay)
assert(next(replicas[1])==nil)
request(b,"SelectSpawn",ax,ay)
assert(remote.results[#remote.results].Message:find("Too close"))
local before=#remote.messages
request(a,"SelectSpawn",at(100,45))
assert(#remote.messages==before,"Rate limiting")
now=1
request(a,"SelectSpawn",0/0,20)
for _,profile in ipairs(metadata.Players) do
	if profile.UserId==a.UserId then assert(profile.X==ax and profile.Y==ay,"Exact subcell position must survive validation") end
end
now=19.9
request(a,"SelectSpawn",at(100.0123,45.0123))
now=20.2
request(a,"SelectSpawn",at(-100,40))
assert(metadata.Phase=="Started")
for _,profile in ipairs(metadata.Players) do assert(profile.Spawn and profile.Count==1) end
local target=nil
for cell,owner in pairs(replicas[1]) do
	if owner==a.UserId then
		for _,neighbor in ipairs(WorldMap.neighbors(cell)) do if not replicas[1][neighbor] then target=neighbor; break end end
	end
	if target then break end
end
assert(target)
local x,y=WorldMap.xy(target)
now=21
request(a,"Expand",x+0.25,y+0.75)
assert(coroutine.resume(loop))
local delta=remote.messages[#remote.messages]
assert(delta.Action=="Delta" and #delta.Data.Groups>0)
assert(replicas[1][target]==a.UserId and replicas[2][target]==a.UserId)
for cell,owner in pairs(replicas[1]) do assert(replicas[2][cell]==owner and WorldMap.isLand(cell)) end
before=#remote.messages
request(b,"Expand",x+0.25,y+0.75)
assert(#remote.messages==before,"Competing expansion cannot overwrite")
local c={UserId=-3,Name="LateJoiner"}
players.PlayerAdded:Fire(c)
for _,profile in ipairs(metadata.Players) do if profile.UserId==c.UserId then assert(profile.Spectator and not profile.Spawn) end end
request(c,"Expand",at(-100,40))
assert(#remote.messages==before+1)
now=24
request(b,"Sync")
for cell,owner in pairs(replicas[1]) do assert(replicas[2][cell]==owner,"Full sync must agree with deltas") end
players.PlayerRemoving:Fire(a)
for _,owner in pairs(replicas[1]) do assert(owner~=a.UserId) end
players.PlayerRemoving:Fire(b); players.PlayerRemoving:Fire(c)
assert(metadata.Phase=="Waiting" and next(replicas[1])==nil)
now=30
players.PlayerAdded:Fire(a); request(a,"Sync")
assert(metadata.Phase=="Selecting" and metadata.Deadline==50)
print("Server checks passed: exact spawn points, deadline, simultaneous start, expansion deltas, conflicts, late join, cleanup, reset.")
