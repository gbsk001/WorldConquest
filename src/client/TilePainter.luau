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
            local terrain=Map.terrain
			local px, py = slot.X * SIZE + x - 1, slot.Y * SIZE + y - 1
			local land
			if fresh then
					local coverage = math.floor(Map.coverage(slot.Level, px, py)*255+0.5)
					buffer.writeu8(slot.Coverage, index, coverage)
					land = coverage / 255
			else land = buffer.readu8(slot.Coverage, index)/255 end
			local r, g, b, owned = raster.sample(slot.Level, px, py, now)
			if owned == 1 and not terrain then land = 1 end
            local neutral = math.max(0, land - owned)
            if terrain then
                if not slot.Base then slot.Base=buffer.create(PADDED*PADDED*4)end
                local base
                if fresh then
                    local tr,tg,tb=terrain(slot.Level,px,py)
                    -- Existing detailed coastline/lake mask wins over raster water edges.
                    tr=math.floor(39*(1-land)+tr*land+.5);tg=math.floor(91*(1-land)+tg*land+.5);tb=math.floor(133*(1-land)+tb*land+.5)
                    base=tr+tg*256+tb*65536;buffer.writeu32(slot.Base,index*4,base)
                else base=buffer.readu32(slot.Base,index*4)end
                local alpha=if owned==1 then .58 else 0
                r=math.floor((base%256)*(1-alpha)+r*alpha+.5)
                g=math.floor((math.floor(base/256)%256)*(1-alpha)+g*alpha+.5)
                b=math.floor(math.floor(base/65536)*(1-alpha)+b*alpha+.5)
            else
                r=math.clamp(math.floor(20*(1-land)+115*neutral+r+.5),0,255)
                g=math.clamp(math.floor(45*(1-land)+139*neutral+g+.5),0,255)
                b=math.clamp(math.floor(65*(1-land)+128*neutral+b+.5),0,255)
            end
			buffer.writeu32(slot.Pixels, index*4, r + g*256 + b*65536 + 4278190080)
		end
	end
 if debug.profileend then debug.profileend()end
end
return Painter
