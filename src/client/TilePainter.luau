--!strict
-- Pure CPU tile painter, also exercised by the local performance checks.
local Map = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Map"))
local Painter = { Size = 256, Padded = 258 }
local SIZE, PADDED = Painter.Size, Painter.Padded
function Painter.paint(slot: any, raster: any, now: number, fresh: boolean, firstRow: number?, lastRow: number?, firstColumn: number?, lastColumn: number?)
 if debug.profilebegin then debug.profilebegin("WC.TilePaint")end
	for y = firstRow or 0, lastRow or (PADDED-1) do
		for x = firstColumn or 0, lastColumn or (PADDED-1) do
			local index = y * PADDED + x
			local px, py = slot.X * SIZE + x - 1, slot.Y * SIZE + y - 1
			local land
			if fresh then
					local coverage = math.floor(Map.coverage(slot.Level, px, py)*255+0.5)
					buffer.writeu8(slot.Coverage, index, coverage)
					land = coverage / 255
			else land = buffer.readu8(slot.Coverage, index)/255 end
			local r, g, b, owned = raster.sample(slot.Level, px, py, now)
			if owned == 1 then land = 1 end
			local neutral = math.max(0, land - owned)
			r = math.clamp(math.floor(20*(1-land) + 115*neutral + r + 0.5), 0, 255)
			g = math.clamp(math.floor(45*(1-land) + 139*neutral + g + 0.5), 0, 255)
			b = math.clamp(math.floor(65*(1-land) + 128*neutral + b + 0.5), 0, 255)
			buffer.writeu32(slot.Pixels, index*4, r + g*256 + b*65536 + 4278190080)
		end
	end
 if debug.profileend then debug.profileend()end
end
return Painter
