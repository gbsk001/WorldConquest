--!strict
local Map = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Map"))
local Rules = {}
export type Spawns = {[number]: number}

function Rules.selectSpawn(spawns: Spawns, userId: number, cell: any): (boolean, string)
	if not Map.isLand(cell) then return false, "Choose land, not ocean or lake." end
	local occupied: {[number]: boolean} = {}
	for otherId, otherCell in pairs(spawns) do
		if otherId ~= userId then
			for _, id in ipairs(Map.seed(otherCell)) do occupied[id] = true end
		end
	end
	for _, id in ipairs(Map.seed(cell)) do
		if occupied[id] then return false, "Too close to another spawn. Choose unoccupied land." end
	end
	spawns[userId] = cell
	return true, "Spawn selected exactly here. You can move it until the countdown ends."
end
function Rules.autoSelect(spawns: Spawns, userId: number, startIndex: number): boolean
	-- A coprime stride samples the whole land inventory without a huge cell table.
	for offset = 0, math.min(Map.LandCount - 1, 10000) do
		local cell = Map.landAt((startIndex + offset * 7919 - 1) % Map.LandCount + 1)
		if Rules.selectSpawn(spawns, userId, cell) then return true end
	end
	return false
end
function Rules.start(spawns: Spawns): {[number]: number}
	local owners: {[number]: number} = {}
	for userId, cell in pairs(spawns) do
		for _, id in ipairs(Map.seed(cell)) do
			assert(owners[id] == nil, "Overlapping reservations")
			owners[id] = userId
		end
	end
	return owners
end
return Rules
