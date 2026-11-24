--!strict
-- Exact sparse ownership. Overview sampling never changes simulation cells.
local Map = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Map"))
local Raster = {}
function Raster.new()
	local owners, colors = {}, {}
	local grid=nil
	local result = { Owners = owners }
	function result.setGrid(value) grid=value end
	function result.setColor(id, r, g, b) colors[id] = {r,g,b} end
	function result.setStyle(id,pattern,border)local c=colors[id];if c then c[4]=pattern;c[5]=border end end
	function result.clear() table.clear(owners) end
	function result.set(cell, owner, _now, _animate)
		owners[cell] = if owner == 0 then nil else owner
	end
	function result.sample(level, x, y, _now)
		local step = 2 ^ level
		local px, py = x * step, y * step
		if py < 0 or py >= Map.Height then return 0,0,0,0 end
		local owner = if grid then (if px>=0 and px<Map.Width then grid.ownerID(py*Map.Width+px) else 0) else owners[py * Map.Width + px % Map.Width + 1]
		local color = colors[owner]
		if not color then
            if grid and px>=0 and px<Map.Width and bit32.band(grid.state(py*Map.Width+px),0x2000)~=0 then return 110,85,115,1 end
            return 0,0,0,0
        end
		local shade = if grid and level==0 and grid.isBorder(py*Map.Width+px) then 0.72 else 1
		if shade<1 and color[5]then shade=.62 elseif level<=1 and color[4]and (px+py)%16<3 then shade=.94 end
		return color[1]*shade,color[2]*shade,color[3]*shade,1
	end
	return result
end
return Raster
