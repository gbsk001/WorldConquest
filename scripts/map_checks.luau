-- Actual transform and colour-raster modules, across layout/inset/zoom variants.
local checks = 0
for _, size in ipairs({ {320,568}, {800,600}, {1920,1080}, {2560,1080} }) do
	for _, inset in ipairs({0,36,58,90}) do
		for _, zoom in ipairs({1,1.5,4,16,64}) do
			local vw, vh = size[1]-24, math.max(100,size[2]-166-inset)
			local scale = math.min(vw/WorldMap.Width,vh/WorldMap.Height)*zoom
			local width,height = WorldMap.Width*scale,WorldMap.Height*scale
			for _, pan in ipairs({0,0.2,0.7,1}) do
				local left = 12 + MapTransform.clampOrigin(-(width-vw)*pan,width,vw)
				local top = inset+94 + MapTransform.clampOrigin(-(height-vh)*pan,height,vh)
				for _, fraction in ipairs({0.125,0.37,0.5,0.875}) do
					local sx,sy = 12+vw*fraction,inset+94+vh*fraction
					-- Studio reports a None-inset root at (0,-inset), even though its
					-- physical top-left is (0,0). Normalize input and geometry together.
					local gx,gy = MapTransform.screenToGui(sx,sy,0,-inset)
					local x,y = MapTransform.toMap(gx,gy,left,top-inset,width,height,WorldMap.Width,WorldMap.Height)
					if x and y then
						local mx,my = MapTransform.toScreen(x,y,left,top,width,height,WorldMap.Width,WorldMap.Height)
						assert(math.abs(mx-sx)<1e-7 and math.abs(my-sy)<1e-7, "Marker must remain exactly under pointer")
						assert(WorldMap.cell(x,y)==math.floor(y)*WorldMap.Width+math.floor(x)+1)
						checks += 1
					end
				end
			end
		end
	end
end
assert(MapTransform.toMap(5,5,20,20,100,100,8192,4096)==nil, "Map padding cannot be selected")
local raster=OwnershipRaster.new()
raster.setColor(1,220,80,40)
local cell=WorldMap.cell(4000,2200)
assert(cell)
raster.set(cell,1,10,true)
local r,_,_,n=raster.sample(0,4000,2200,10)
assert(r==220 and n==1,"Immediate exact colour; no blending")
local _,_,_,empty=raster.sample(0,4001,2200,10)
assert(empty==0,"Adjacent unclaimed cell must stay empty")
raster.set(cell,0,12,false)
assert(raster.Owners[cell]==nil)
print(string.format("%d screen/map/marker round trips; exact square ownership passed.",checks))
