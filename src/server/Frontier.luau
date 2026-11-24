--!strict
-- Persistent FIFO frontier, not click-centred circles or radius flood fills.
local Map = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Map"))
local Frontier = {}

function Frontier.new(owners: {[number]: number}, limits: any)
	local owned: {[number]: {[number]: boolean}} = {}
	local counts: {[number]: number} = {}
	local queues: {[number]: any} = {}
	local order: {number} = {}
	local total, rotation = 0, 1
	local function enqueue(userId: number, cell: number)
		local queue = queues[userId]
		if queue and not owners[cell] and not queue.Pending[cell] and Map.isLand(cell) then
			queue.Tail += 1
			queue.Items[queue.Tail] = cell
			queue.Pending[cell] = true
		end
	end
	local function adjacent(userId: number, cell: number): boolean
		for _, id in ipairs(Map.neighbors(cell)) do if owners[id] == userId then return true end end
		return false
	end
	local function claim(userId: number, cell: number): boolean
		if total >= limits.MaxOwnedCells or not owned[userId] or not Map.isLand(cell)
			or owners[cell] or not adjacent(userId, cell) then return false end
		owners[cell] = userId
		owned[userId][cell] = true
		counts[userId] += 1
		total += 1
		queues[userId].Pending[cell] = nil
		for _, neighbor in ipairs(Map.neighbors(cell)) do enqueue(userId, neighbor) end
		return true
	end
	-- Sorted initialization makes identical worlds produce identical queues.
	local initial = {}
	for cell, userId in pairs(owners) do
		if not owned[userId] then
			owned[userId], counts[userId] = {}, 0
			queues[userId] = { Items = {}, Pending = {}, Head = 1, Tail = 0 }
			table.insert(order, userId)
		end
		owned[userId][cell] = true
		counts[userId] += 1
		total += 1
		table.insert(initial, cell)
	end
	table.sort(order)
	table.sort(initial)
	for _, cell in ipairs(initial) do
		for _, neighbor in ipairs(Map.neighbors(cell)) do enqueue(owners[cell], neighbor) end
	end

	local engine = { Owners = owners, Owned = owned, Counts = counts }
	function engine.atCapacity(): boolean return total >= limits.MaxOwnedCells end
	function engine.claimCell(userId: number, cell: any): (boolean, string)
		if not Map.isLand(cell) then return false, "Oceans and lakes cannot be claimed." end
		if engine.atCapacity() then return false, "This prototype's ownership memory limit has been reached." end
		if owners[cell] then return false, "That cell is already owned." end
		if not claim(userId, cell) then return false, "Choose one empty cell sharing an edge with your land." end
		return true, "One cell claimed. Automatic frontier growth continues."
	end
	function engine.step(): ({any}, number)
		local changes = {}
		local claimed, checked = 0, 0
		if #order == 0 or engine.atCapacity() then return changes, checked end
		local start = rotation
		for offset = 0, #order - 1 do
			local position = (start + offset - 1) % #order + 1
			local userId = order[position]
			local queue = queues[userId]
			local cells = {}
			-- Newly exposed cells wait until a later tick: never grow a long tunnel
			-- in one tick while neglecting the original frontier on the other sides.
			local waveEnd = queue.Tail
			local examined = 0
			while queue.Head <= waveEnd and #cells < limits.ClaimsPerPlayerPerTick
				and claimed < limits.ClaimsPerTick and checked < limits.FrontierChecksPerTick
				and examined < limits.FrontierChecksPerPlayer and not engine.atCapacity() do
				local cell = queue.Items[queue.Head]
				queue.Items[queue.Head] = nil
				queue.Head += 1
				checked += 1
				examined += 1
				if queue.Pending[cell] then
					queue.Pending[cell] = nil
					if claim(userId, cell) then table.insert(cells, cell); claimed += 1 end
				end
			end
			if #cells > 0 then table.insert(changes, { Owner = userId, Cells = cells, Count = counts[userId] }) end
			-- Reclaim consumed queue storage without rescanning territory interiors.
			if queue.Head > 4096 and queue.Head > queue.Tail / 2 then
				local compact = {}
				for i = queue.Head, queue.Tail do table.insert(compact, queue.Items[i]) end
				queue.Items, queue.Head, queue.Tail = compact, 1, #compact
			end
			rotation = position % #order + 1
			if claimed >= limits.ClaimsPerTick or checked >= limits.FrontierChecksPerTick or engine.atCapacity() then break end
		end
		-- Rotate ties even when every player's whole allowance fitted this tick.
		if rotation == start then rotation = start % #order + 1 end
		return changes, checked
	end
	function engine.release(userId: number): {number}
		local released = {}
		for cell in pairs(owned[userId] or {}) do
			owners[cell] = nil
			table.insert(released, cell)
		end
		total -= #released
		owned[userId], counts[userId], queues[userId] = nil, nil, nil
		local position = table.find(order, userId)
		if position then table.remove(order, position) end
		rotation = 1
		table.sort(released)
		-- Freed borders become eligible for surviving neighbours immediately.
		for _, cell in ipairs(released) do
			for _, neighbor in ipairs(Map.neighbors(cell)) do
				local other = owners[neighbor]
				if other then enqueue(other, cell) end
			end
		end
		return released
	end
	return engine
end
return Frontier
