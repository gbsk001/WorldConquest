--!strict
local Earth = require(script.Parent:WaitForChild("EarthData"))
local Map = { Width = Earth.Width, Height = Earth.Height, LandCount = Earth.LandCount }
-- One bit per simulation cell: 4 MiB for the entire planet.
local mask = buffer.create(Map.Width * Map.Height / 8)
local runs = buffer.fromstring(Earth.Runs)
local starts: {number} = {}
local totals: {number} = {}
local cursor, total = 0, 0
local decodeDeadline=os.clock()+.002
for y = 0, Map.Height - 1 do
 if task and task.wait and y%32==0 and os.clock()>=decodeDeadline then task.wait();decodeDeadline=os.clock()+.002 end
	local count = buffer.readu16(runs, cursor)
	cursor += 2
	for _ = 1, count do
		local x, length = buffer.readu16(runs, cursor), buffer.readu16(runs, cursor + 2)
		cursor += 4
		local first = y * Map.Width + x
		table.insert(starts, first)
		total += length
		table.insert(totals, total)
		local finish = first + length
		while first < finish and first % 8 ~= 0 do
			local byte = math.floor(first / 8)
			buffer.writeu8(mask, byte, bit32.bor(buffer.readu8(mask, byte), bit32.lshift(1, first % 8)))
			first += 1
		end
		local bytes = math.floor((finish - first) / 8)
		if bytes > 0 then buffer.fill(mask, first / 8, 255, bytes); first += bytes * 8 end
		while first < finish do
			local byte = math.floor(first / 8)
			buffer.writeu8(mask, byte, bit32.bor(buffer.readu8(mask, byte), bit32.lshift(1, first % 8)))
			first += 1
		end
	end
end
assert(total == Map.LandCount)

function Map.finite(value: any): boolean
	return typeof(value) == "number" and value == value and math.abs(value) < math.huge
end
function Map.cell(x: any, y: any): number?
	if not Map.finite(x) or not Map.finite(y) or x < 0 or x >= Map.Width or y < 0 or y >= Map.Height then return nil end
	return math.floor(y) * Map.Width + math.floor(x) + 1
end
function Map.xy(id: number): (number, number)
	return (id - 1) % Map.Width, math.floor((id - 1) / Map.Width)
end
function Map.isLand(id: any): boolean
	if not Map.finite(id) or id % 1 ~= 0 or id < 1 or id > Map.Width * Map.Height then return false end
	local index = id - 1
	return bit32.band(buffer.readu8(mask, math.floor(index / 8)), bit32.lshift(1, index % 8)) ~= 0
end
function Map.landAt(index: number): number
	local lo, hi = 1, #totals
	while lo < hi do
		local mid = math.floor((lo + hi) / 2)
		if totals[mid] < index then lo = mid + 1 else hi = mid end
	end
	return starts[lo] + index - (totals[lo - 1] or 0)
end
function Map.neighbors(id: number): {number}
	local x, y = Map.xy(id)
	local result = {}
	-- Fixed order makes growth deterministic. Longitude wraps; latitude does not.
	for _, offset in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }) do
		local neighbor = Map.cell((x + offset[1]) % Map.Width, y + offset[2])
		if neighbor and Map.isLand(neighbor) then table.insert(result, neighbor) end
	end
	return result
end
-- A spawn starts as one real simulation cell, not a pre-rounded disk.
function Map.seed(id: number): {number}
	return if Map.isLand(id) then { id } else {}
end

-- Display-only area coverage LODs. Never used to validate ownership.
local mips: {[number]: buffer} = {}
local displayReady,displayPreparing=false,false
function Map.prepareDisplay()
 if displayReady then return end
 if displayPreparing then
  while not displayReady do task.wait()end
  return
 end
 displayPreparing=true
 local deadline=os.clock()+.002
	for level, data in pairs(Earth.Mips) do
		local packed = buffer.fromstring(data.Runs)
		local output = buffer.create(data.Width * data.Height)
		local input, offset = 0, 0
		while input < buffer.len(packed) do
   if task and task.wait and input%12288==0 and os.clock()>=deadline then task.wait();deadline=os.clock()+.002 end
			local length = buffer.readu16(packed, input)
			buffer.fill(output, offset, buffer.readu8(packed, input + 2), length)
			offset += length
			input += 3
		end
		assert(offset == buffer.len(output))
		mips[level] = output
	end
 displayReady=true;displayPreparing=false
end
function Map.coverage(level: number, x: number, y: number): number
	local step = 2 ^ level
	local w, h = Map.Width / step, Map.Height / step
	if y < 0 or y >= h then return 0 end
	x = x % w
	if level == 0 then return if Map.isLand(y * w + x + 1) then 1 else 0 end
	if level == 1 then
		local base = y * 2 * Map.Width + x * 2 + 1
		local count = (if Map.isLand(base) then 1 else 0) + (if Map.isLand(base + 1) then 1 else 0)
			+ (if Map.isLand(base + Map.Width) then 1 else 0) + (if Map.isLand(base + Map.Width + 1) then 1 else 0)
		return count / 4
	end
	return buffer.readu8(mips[level], y * w + x) / 255
end
return Map
