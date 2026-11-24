--!strict
-- Retained prototype fallback; not OpenFront rules.
return function()
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Map = require(Shared:WaitForChild("Map"))
local Rules = require(script.Parent:WaitForChild("Rules"))
local Frontier = require(script.Parent:WaitForChild("Frontier"))
Players.CharacterAutoLoads = false
local remote = Instance.new("RemoteEvent")
remote.Name = "WorldConquestEvent"
local phase, deadline, revision = "Waiting", 0, 0
local spawns: {[number]: number} = {}
local positions: {[number]: {X: number, Y: number}} = {}
local owners: {[number]: number} = {}
local owned: {[number]: {[number]: boolean}} = {}
local counts: {[number]: number} = {}
local slots: {[Player]: number} = {}
local usedSlots: {[number]: boolean} = {}
local eligible: {[Player]: boolean} = {}
local lastAction: {[Player]: number} = {}
local lastSync: {[Player]: number} = {}
local random = Random.new()
local engine: any = nil
local pending: {[number]: {number}} = {}
local lastCapacity = false
local function enqueueChanges(userId: number, cells: {number})
	pending[userId] = pending[userId] or {}
	for _, cell in ipairs(cells) do table.insert(pending[userId], cell) end
end

local function pack(cells: {number}): buffer
	local data = buffer.create(#cells * 4)
	for index, cell in ipairs(cells) do buffer.writeu32(data, (index - 1) * 4, cell) end
	return data
end
local function snapshot(full: boolean)
	local roster = {}
	for player, slot in pairs(slots) do
		local position = positions[player.UserId]
		table.insert(roster, {
			UserId = player.UserId, Username = player.Name, Count = counts[player.UserId] or 0,
			Color = Config.PlayerColors[slot] or Color3.fromHSV((slot * 0.61803398875) % 1, 0.65, 0.95),
			Spawn = spawns[player.UserId], X = if position then position.X else nil,
			Y = if position then position.Y else nil, Spectator = not eligible[player],
		})
	end
	table.sort(roster, function(a, b) return a.UserId < b.UserId end)
	local territory = nil
	if full then
		territory = {}
		for userId, cells in pairs(owned) do
			local ids = {}
			for cell in pairs(cells) do table.insert(ids, cell) end
			table.sort(ids)
			table.insert(territory, { Owner = userId, Cells = pack(ids) })
		end
	end
	return { Phase = phase, Deadline = deadline, Revision = revision, Players = roster, Territory = territory, GrowthLimited = engine ~= nil and engine.atCapacity() }
end
local function broadcast(full: boolean, released: buffer?)
	revision += 1
	local data = snapshot(full)
	data.Released = released
	remote:FireAllClients(if full then "State" else "Update", data)
end
local function finishSelection()
	if phase ~= "Selecting" or Workspace:GetServerTimeNow() < deadline then return end
	for player in pairs(slots) do
		if eligible[player] and not spawns[player.UserId] then
			if Rules.autoSelect(spawns, player.UserId, random:NextInteger(1, Map.LandCount)) then
				local x, y = Map.xy(spawns[player.UserId])
				positions[player.UserId] = { X = x + 0.5, Y = y + 0.5 }
			else eligible[player] = nil end
		end
	end
	-- No yields: validation/placement/ownership commit is one server transaction.
	owners = Rules.start(spawns)
	engine = Frontier.new(owners, Config)
	owned, counts = engine.Owned, engine.Counts
	table.clear(pending)
	lastCapacity = false
	phase = "Started"
	broadcast(true, nil)
end
local function addPlayer(player: Player)
	if slots[player] then return end
	finishSelection()
	local slot = 1
	while usedSlots[slot] do slot += 1 end
	slots[player], usedSlots[slot] = slot, true
	eligible[player] = if phase ~= "Started" then true else nil
	broadcast(false, nil)
end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player)
	local uid, slot = player.UserId, slots[player]
	if slot then usedSlots[slot] = nil end
	slots[player], eligible[player], lastAction[player], lastSync[player] = nil, nil, nil, nil
	spawns[uid], positions[uid], counts[uid] = nil, nil, nil
	local released = if engine then engine.release(uid) else {}
	pending[uid] = nil
	if next(slots) == nil then
		phase, deadline = "Waiting", 0
		engine = nil
		table.clear(pending)
		table.clear(owners); table.clear(owned); table.clear(spawns); table.clear(positions); table.clear(counts)
	end
	broadcast(false, pack(released))
end)
remote.OnServerEvent:Connect(function(player: Player, action: any, x: any, y: any)
	if not slots[player] or (action ~= "Sync" and action ~= "SelectSpawn" and action ~= "Expand") then return end
	local now = os.clock()
	local limits = if action == "Sync" then lastSync else lastAction
	local cooldown = if action == "Sync" then 2 elseif action == "Expand" then Config.ExpansionCooldown else Config.RequestCooldown
	if now - (limits[player] or -math.huge) < cooldown then return end
	limits[player] = now
	finishSelection()
	if action == "Sync" then
		if phase == "Waiting" then
			phase = "Selecting"
			deadline = Workspace:GetServerTimeNow() + Config.SpawnSeconds
			broadcast(true, nil)
		else remote:FireClient(player, "State", snapshot(true)) end
		return
	end
	local cell = Map.cell(x, y)
	if not cell or not Map.isLand(cell) then
		remote:FireClient(player, "Result", "Choose land, not ocean or lake.")
		return
	end
	if action == "SelectSpawn" then
		if phase ~= "Selecting" or not eligible[player] then
			remote:FireClient(player, "Result", "Spawn selection is closed.")
			return
		end
		local success, message = Rules.selectSpawn(spawns, player.UserId, cell)
		if success then
			positions[player.UserId] = { X = x, Y = y } -- preserve the precise validated point
			broadcast(false, nil)
		end
		remote:FireClient(player, "Result", message)
	elseif phase == "Started" and eligible[player] and owned[player.UserId] then
		local success, message = engine.claimCell(player.UserId, cell)
		if success then enqueueChanges(player.UserId, { cell }) end
		remote:FireClient(player, "Result", message)
	else
		remote:FireClient(player, "Result", "You cannot expand before the start or while spectating.")
	end
end)
remote.Parent = ReplicatedStorage
for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
task.spawn(function()
	while true do
		task.wait(Config.GrowthTickSeconds)
		finishSelection()
		if phase == "Started" and engine then
			local changes = engine.step()
			for _, group in ipairs(changes) do enqueueChanges(group.Owner, group.Cells) end
			local limited = engine.atCapacity()
			if next(pending) or limited ~= lastCapacity then
				local groups, userIds = {}, {}
				for userId in pairs(pending) do table.insert(userIds, userId) end
				table.sort(userIds)
				for _, userId in ipairs(userIds) do
					table.insert(groups, { Owner = userId, Cells = pack(pending[userId]), Count = counts[userId] or 0 })
				end
				table.clear(pending)
				revision += 1
				remote:FireAllClients("Delta", { Revision = revision, Groups = groups, GrowthLimited = limited })
				lastCapacity = limited
			end
		end
	end
end)

end
