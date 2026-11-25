--!strict
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Map = require(Shared:WaitForChild("Map"))
local Config = require(Shared:WaitForChild("Config"))
local Transform = require(script.Parent:WaitForChild("MapTransform"))
local Tiles = require(script.Parent:WaitForChild("MapTiles"))
local Raster = require(script.Parent:WaitForChild("OwnershipRaster"))
local BuildingRules = require(Shared.OpenFront.BuildingRules)
local IconLayer = require(script.Parent.IconLayer)
local Art=require(script.Parent.InterfaceArt)
local Cosmetic=require(script.Parent.CosmeticArt)
local Ranking=require(Shared.TerritoryRanking)
local TouchGestures=require(script.Parent.TouchGestures)
local MapView = {}

function MapView.new(viewport: Frame, onSelect: (number, number) -> (), onNotice: (string) -> ())
	local screenGui = viewport:FindFirstAncestorWhichIsA("ScreenGui") :: ScreenGui
	viewport.ClipsDescendants = true
	local canvas = Instance.new("Frame")
	canvas.Name = "Earth"
	canvas.BackgroundColor3 = Color3.fromRGB(39,91,133)
	canvas.BorderSizePixel = 0
	canvas.ClipsDescendants = true
	canvas.Parent = viewport
	Art.prepareMapIcons()
    canvas:SetAttribute("IconAtlasEnabled",Art.mapIconsReady())
	local terrainColors=require(script.Parent.TerrainColors)
    Map.terrain=terrainColors.sample
	local raster = Raster.new()
	local ok,tiles = pcall(Tiles.new,canvas,raster)
	if not ok or not tiles then
  for _,child in ipairs(canvas:GetChildren())do if child.Name=="EarthTile"then child:Destroy()end end
  tiles=require(script.Parent.CompatibleTiles).new(canvas,raster)
  onNotice("Compatibility graphics enabled. Pinch or use Settings to zoom for finer detail.")
 end
	local markerLayer = Instance.new("Frame")
	markerLayer.Name = "SpawnMarkers"
	markerLayer.Size = UDim2.fromScale(1,1)
	markerLayer.BackgroundTransparency = 1
	markerLayer.ZIndex = 5
	markerLayer.Parent = canvas
	local inputSurface = Instance.new("TextButton")
	inputSurface.Name = "MapInput"
	inputSurface.Size = UDim2.fromScale(1,1)
	inputSurface.BackgroundTransparency = 1
	inputSurface.Text = ""
	inputSurface.AutoButtonColor = false
	inputSurface.ZIndex = 20
	inputSurface.Parent = viewport

	local zoom, scale = 1, 1
    local zoomGoal=nil;local zoomPoint=nil
	local origin = Vector2.zero
	local previousSize = Vector2.zero
	local markers: {[number]: Frame} = {}
    local shipList,buildingList={},{};local railList={}
    local markerOrder={};local placementKind=nil;local placementOwner=nil;local preview=nil;local foundationGrid=nil
    local labelVersion=0;local lastLabels={};local palette={}
    local renderWorst=0
 local lastTouchPoint=nil
    local function layoutNames()
        local bounds=viewport.AbsoluteSize
        if lastLabels.Version==labelVersion and lastLabels.X==origin.X and lastLabels.Y==origin.Y and lastLabels.Scale==scale and lastLabels.W==bounds.X and lastLabels.H==bounds.Y then return end
        lastLabels={Version=labelVersion,X=origin.X,Y=origin.Y,Scale=scale,W=bounds.X,H=bounds.Y}
        local occupied={};local cells={}
        for _,marker in ipairs(markerOrder) do
            local x=origin.X+marker.Position.X.Scale*Map.Width*scale
            local y=origin.Y+marker.Position.Y.Scale*Map.Height*scale
            local label=marker:FindFirstChild("Username")
            marker.Visible=x>=0 and y>=0 and x<bounds.X and y<bounds.Y
            local visible=marker.Visible and y>=30
            if zoom<2 and not marker:GetAttribute("Local") and #occupied>=18 then visible=false end
            if visible then
                local bx,by=math.floor(x/168),math.floor(y/38)
                for yy=by-1,by+1 do for xx=bx-1,bx+1 do
                    local boxes=cells[xx..":"..yy];if boxes then for _,box in ipairs(boxes)do if math.abs(x-box[1])<168 and math.abs(y-box[2])<38 then visible=false;break end end end
                end end
            end
            if label then label.Visible=visible end
            if visible then local box={x,y};table.insert(occupied,box);local key=math.floor(x/168)..":"..math.floor(y/38);local boxes=cells[key];if not boxes then boxes={};cells[key]=boxes end;table.insert(boxes,box)end
        end
    end
    local function createIcon()
        local icon=Instance.new("TextLabel")
        icon.AnchorPoint=Vector2.new(.5,.5);icon.BorderSizePixel=0;icon.Active=false
        local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,5);corner.Parent=icon
        icon.BorderColor3=Color3.new(1,1,1);icon.TextColor3=Color3.new(1,1,1)
        icon.TextStrokeTransparency=.1;icon.Font=Enum.Font.GothamBold;icon.TextSize=12
        icon.Visible=false;icon.BackgroundTransparency=1;icon.TextXAlignment=Enum.TextXAlignment.Right;icon.Parent=markerLayer;return icon
    end
    local function position(u,colors,set)
        set("Position",UDim2.fromScale((u.Tile%Map.Width+.5)/Map.Width,(math.floor(u.Tile/Map.Width)+.5)/Map.Height))
        set("BackgroundColor3",colors[u.Owner] or Color3.new(.5,.5,.5))
    end
    local missileTypes={AtomBomb=true,HydrogenBomb=true,MIRV=true,MIRVWarhead=true,SAMMissile=true}
    local tweens={}
    local function animate(icon,key,value,old,u)
        if key==nil or key=="Position" then
            if tweens[icon] then tweens[icon]:Cancel();tweens[icon]=nil end
            if key=="Position" and old and icon.Visible and missileTypes[u.Type] then
                local tween=TweenService:Create(icon,TweenInfo.new(.1,Enum.EasingStyle.Linear),{Position=value})
                tweens[icon]=tween;tween:Play();return true
            end
        end
        return false
    end
    local ownerCosmetics={};local participantCosmetics={}
    local effectPool={};local effectActive=0;local effectSerial=0;local attackSerials={}
    local function pulse(x,y,color)
        if effectActive>=20 or not viewport.Visible then return end
        local sx,sy=origin.X+x*scale,origin.Y+y*scale
        if sx<0 or sy<0 or sx>viewport.AbsoluteSize.X or sy>viewport.AbsoluteSize.Y then return end
        local ring=table.remove(effectPool)
        if not ring then
            ring=Instance.new("Frame");ring.BackgroundTransparency=1;ring.Active=false;ring.AnchorPoint=Vector2.new(.5,.5);ring.ZIndex=8;ring.Parent=markerLayer
            local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(1,0);corner.Parent=ring
            local stroke=Instance.new("UIStroke");stroke.Name="PulseStroke";stroke.Thickness=2;stroke.Parent=ring
        end
        effectActive+=1;ring.Visible=true;ring.Size=UDim2.fromOffset(8,8);ring.Position=UDim2.fromScale(x/Map.Width,y/Map.Height)
        ring.PulseStroke.Color=color;ring.PulseStroke.Transparency=.15
        TweenService:Create(ring,TweenInfo.new(.65),{Size=UDim2.fromOffset(52,52)}):Play()
        TweenService:Create(ring.PulseStroke,TweenInfo.new(.65),{Transparency=1}):Play()
        task.delay(.7,function()effectActive-=1;if ring.Parent then ring.Visible=false;table.insert(effectPool,ring)end end)
    end
    local function symbol(icon,u,colors,scale)
        local category=if missileTypes[u.Type]then "Missile"elseif u.Type=="Warship"then "Warship"elseif u.Type=="TransportShip"then "Transport"else "Building"
        local equipped=ownerCosmetics[u.Owner];local finish=equipped and equipped[category]or ""
        local art=icon:FindFirstChild("UnitArt")
        if not art or art:GetAttribute("Kind")~=u.Type or art:GetAttribute("Finish")~=finish then
            if art then art:Destroy()end
            art=Art.mapIcon(icon,u.Type,24,Cosmetic.tint(equipped,category,Color3.fromRGB(240,245,251)));art.Position=UDim2.fromOffset(6,0);art.Name="UnitArt";art:SetAttribute("Kind",u.Type);art:SetAttribute("Finish",finish)
            local resize=Instance.new("UIScale");resize.Name="ZoomScale";resize.Parent=art
            local accent=Instance.new("Frame");accent.Name="OwnerAccent";accent.Position=UDim2.fromOffset(0,25);accent.Size=UDim2.fromOffset(24,2);accent.BorderSizePixel=0;accent.Parent=art
        end
        local size=math.clamp(14+math.log(math.max(.1,scale)*10)*4,14,30)
        if u.Type=="Shell"then size=6 end
        if art.ZoomScale.Scale~=size/24 then art.ZoomScale.Scale=size/24 end
        local color=colors[u.Owner]or Color3.new(.6,.6,.6);if art.OwnerAccent.BackgroundColor3~=color then art.OwnerAccent.BackgroundColor3=color end
        local bounds=UDim2.fromOffset(size+12,size+4);if icon.Size~=bounds then icon.Size=bounds end
    end
    local ships=IconLayer.new(Map.Width,createIcon,function(u,colors,set,icon,iconScale)
        position(u,colors,set);set("Name","Ship"..u.ID);set("ZIndex",9);set("Text","");set("BackgroundTransparency",1)
        symbol(icon,u,colors,iconScale)
    end,animate,true,if UserInputService.TouchEnabled then 96 else 256)
    local buildings=IconLayer.new(Map.Width,createIcon,function(u,colors,set,icon,iconScale)
        position(u,colors,set);set("Name","Building"..u.ID);set("ZIndex",8);set("BackgroundTransparency",1)
        set("Text",tostring(u.Level));symbol(icon,u,colors,iconScale)
    end,nil,true,if UserInputService.TouchEnabled then 96 else 256)

 local lastMetrics=0;local iconWorst=0
 local viewDirty=true
 local function update()viewDirty=true end
 	local function flushView()
        if not screenGui.Enabled then return end
		local bounds = viewport.AbsoluteSize
		if bounds.X <= 0 or bounds.Y <= 0 then return end
        if debug.profilebegin then debug.profilebegin("WC.CameraAndIcons")end
		local nextScale = math.min(bounds.X/Map.Width,bounds.Y/Map.Height)*zoom
		if previousSize ~= bounds and previousSize.X > 0 then
			local centre = (previousSize/2-origin)/scale
			origin = bounds/2-centre*nextScale
		end
		previousSize, scale = bounds, nextScale
		local size = Vector2.new(Map.Width*scale,Map.Height*scale)
		origin = Vector2.new(Transform.clampOrigin(origin.X,size.X,bounds.X),Transform.clampOrigin(origin.Y,size.Y,bounds.Y))
		canvas.Position = UDim2.fromOffset(origin.X,origin.Y)
		canvas.Size = UDim2.fromOffset(size.X,size.Y)
		tiles.update(origin.X,origin.Y,scale,bounds.X,bounds.Y)
        layoutNames()
        if preview then
            local mouse
            if lastTouchPoint or UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
             mouse=if lastTouchPoint then lastTouchPoint-viewport.AbsolutePosition else bounds/2
            else
             local physical=UserInputService:GetMouseLocation();local root=screenGui.AbsolutePosition
             local gx,gy=Transform.screenToGui(physical.X,physical.Y,root.X,root.Y);mouse=Vector2.new(gx,gy)-viewport.AbsolutePosition
            end
            local x,y=(mouse.X-origin.X)/scale,(mouse.Y-origin.Y)/scale
            preview.Visible=mouse.X>=0 and mouse.Y>=0 and mouse.X<bounds.X and mouse.Y<bounds.Y
            preview.Position=UDim2.fromScale(x/Map.Width,y/Map.Height)
            local cell=Map.cell(x,y);local valid=cell and Map.isLand(cell) and (not foundationGrid or foundationGrid.ownerID(cell-1)==placementOwner)
            preview.Outline.Color=if valid then Color3.fromRGB(100,225,170)else Color3.fromRGB(245,110,115)
        end
        local iconStart=os.clock()
        ships.update(origin.X,origin.Y,scale,bounds.X,bounds.Y)
        buildings.update(origin.X,origin.Y,scale,bounds.X,bounds.Y)
        local iconMS=(os.clock()-iconStart)*1000;iconWorst=math.max(iconWorst,iconMS)
        if os.clock()-lastMetrics>=1 then
            lastMetrics=os.clock()
            for key,value in pairs(tiles.metrics()) do canvas:SetAttribute(key,value) end
            canvas:SetAttribute("IconMilliseconds",iconMS);canvas:SetAttribute("IconWorstMilliseconds",iconWorst)
            canvas:SetAttribute("VisibleUnitIcons",ships.Visible+buildings.Visible)
            canvas:SetAttribute("PooledUnitIcons",ships.Pooled+buildings.Pooled)
        end
        if debug.profileend then debug.profileend()end
	end
	local function pointer(input: InputObject): Vector2
		if input.UserInputType==Enum.UserInputType.Touch then return Vector2.new(input.Position.X,input.Position.Y)end
		-- Mouse button InputObject.Position can be stale. Always read current mouse.
		local physical = if input.UserInputType == Enum.UserInputType.Touch
			then Vector2.new(input.Position.X,input.Position.Y) else UserInputService:GetMouseLocation()
		local root = screenGui.AbsolutePosition
		local x,y = Transform.screenToGui(physical.X,physical.Y,root.X,root.Y)
		return Vector2.new(x,y)
	end
	local function inside(point: Vector2): boolean
		local localPoint = point-viewport.AbsolutePosition
		return localPoint.X >= 0 and localPoint.Y >= 0 and localPoint.X < viewport.AbsoluteSize.X and localPoint.Y < viewport.AbsoluteSize.Y
	end
	local function zoomAt(factor: number, screenPoint: Vector2)
		local point = screenPoint-viewport.AbsolutePosition
		local oldScale = scale
		zoom = math.clamp(zoom*factor,1,Config.MaxZoom)
		local newScale = math.min(viewport.AbsoluteSize.X/Map.Width,viewport.AbsoluteSize.Y/Map.Height)*zoom
		origin = point-(point-origin)*(newScale/oldScale)
        scale=newScale -- Camera events may coalesce before the next rendered frame.
		update()
	end
	local drag: InputObject? = nil
	local startPoint, startOrigin = Vector2.zero, Vector2.zero
	local moved = false
    local function overPanel(point)
        for _,name in ipairs({"LeaveConfirmation","BuildingInfo","BuildingShop","NavalControls","MissileControls","MatchResults","Army","Settings","SpawnSelection","CommandBar","CommandToolbar","MatchSummary","Notification"}) do
            local panel=viewport:FindFirstChild(name)or (screenGui:FindFirstChild("SafeInterface") and screenGui.SafeInterface:FindFirstChild(name))or viewport.Parent:FindFirstChild(name)
            if panel and panel.Visible then
                local offset=point-panel.AbsolutePosition;local size=panel.AbsoluteSize
                if offset.X>=0 and offset.Y>=0 and offset.X<size.X and offset.Y<size.Y then return true end
            end
        end
        return false
    end
	local function selectPoint(point)
  if not screenGui.Enabled or not inside(point)or overPanel(point)then return end
  local rect,size=canvas.AbsolutePosition,canvas.AbsoluteSize
  local x,y=Transform.toMap(point.X,point.Y,rect.X,rect.Y,size.X,size.Y,Map.Width,Map.Height)
  if x and y then if tiles.readyAt(x,y)then onSelect(x,y)else onNotice("Loading map detail…")end end
 end
 local gestures=TouchGestures.new(function(dx,dy)origin+=Vector2.new(dx,dy);update()end,
  function(factor,ox,oy,nx,ny)zoomAt(factor,Vector2.new(ox,oy));origin+=Vector2.new(nx-ox,ny-oy);update()end,
  function(x,y)selectPoint(Vector2.new(x,y))end)
	inputSurface.InputBegan:Connect(function(input)
        if not screenGui.Enabled then return end
		if input.UserInputType==Enum.UserInputType.Touch then
   local p=pointer(input);if not overPanel(p)then lastTouchPoint=p;zoomGoal=nil;gestures.begin(input,p.X,p.Y)end;return
  end
		if drag then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if overPanel(pointer(input)) then return end
		zoomGoal=nil
		drag, startPoint, startOrigin, moved = input, pointer(input), origin, false
	end)
	UserInputService.InputChanged:Connect(function(input)
        if not screenGui.Enabled then drag=nil;gestures.cancel();return end
  if input.UserInputType==Enum.UserInputType.Touch then local p=pointer(input);lastTouchPoint=p;gestures.move(input,p.X,p.Y);return end
  if input.UserInputType==Enum.UserInputType.MouseMovement then lastTouchPoint=nil end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local point = pointer(input)
            for _,name in ipairs({"LeaveConfirmation","BuildingInfo","BuildingShop","NavalControls","MissileControls","MatchResults","Army","Settings","SpawnSelection","CommandBar","CommandToolbar","MatchSummary","Notification"}) do
            local shop=viewport:FindFirstChild(name)or (screenGui:FindFirstChild("SafeInterface") and screenGui.SafeInterface:FindFirstChild(name))or viewport.Parent:FindFirstChild(name)
            if shop and shop.Visible then
                local localPoint=point-shop.AbsolutePosition;local bounds=shop.AbsoluteSize
                if localPoint.X>=0 and localPoint.Y>=0 and localPoint.X<bounds.X and localPoint.Y<bounds.Y then return end
            end
			end
			if inside(point) then zoomGoal=math.clamp((zoomGoal or zoom)*1.2^input.Position.Z,1,Config.MaxZoom);zoomPoint=point end
		elseif drag and (input == drag or (drag.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then
			local delta = pointer(input)-startPoint
			if delta.Magnitude > 6 then moved = true end
			if moved then origin = startOrigin+delta; update() end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.Touch then local p=pointer(input);gestures.finish(input,p.X,p.Y);return end
		if input ~= drag then return end
		drag = nil
		local point = pointer(input)
		if not moved and (point-startPoint).Magnitude <= 6 and inside(point) and not overPanel(point) then
			local rect, size = canvas.AbsolutePosition, canvas.AbsoluteSize
			local x,y = Transform.toMap(point.X,point.Y,rect.X,rect.Y,size.X,size.Y,Map.Width,Map.Height)
			if x and y then
				if tiles.readyAt(x,y) then onSelect(x,y) else onNotice("Loading this map detail. Try again in a moment.") end
			end
		end
	end)
	UserInputService.WindowFocusReleased:Connect(function() drag = nil;gestures.cancel() end)
	viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	-- Retry tile allocation/LOD changes on limited-memory clients.
	local connection = RunService.RenderStepped:Connect(function(dt)
        if zoomGoal and screenGui.Enabled then
            local nextZoom=zoom+(zoomGoal-zoom)*math.min(1,dt*22)
            if math.abs(zoomGoal-nextZoom)<.002 then nextZoom=zoomGoal;zoomGoal=nil end
            zoomAt(nextZoom/zoom,zoomPoint)
        end
        if viewDirty then viewDirty=false;flushView()
        elseif screenGui.Enabled then tiles.update(origin.X,origin.Y,scale,viewport.AbsoluteSize.X,viewport.AbsoluteSize.Y)end
    end)
    screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()if tiles.setEnabled then tiles.setEnabled(screenGui.Enabled)end;viewDirty=true end)
	flushView()

	local view = {}
 tiles.OnFailure=function()
  tiles.destroy();tiles=require(script.Parent.CompatibleTiles).new(canvas,raster)
  update();onNotice("Recovered using compatibility graphics.")
 end
    function view.setPlacement(kind,owner)
        placementKind=kind;placementOwner=owner
        if preview then preview:Destroy();preview=nil end
        if kind then
            preview=Art.icon(markerLayer,kind,30,Color3.fromRGB(235,242,255));preview.AnchorPoint=Vector2.new(.5,.5);preview.ZIndex=12
            local outline=Instance.new("UIStroke");outline.Name="Outline";outline.Thickness=1.5;outline.Parent=preview
        end
    end
    function view.shipAt(x,y)
        local closest,distance=nil,math.huge
        for _,u in ipairs(shipList) do
            local dx=(x-(u.Tile%Map.Width+0.5))*scale;local dy=(y-(math.floor(u.Tile/Map.Width)+0.5))*scale
            if table.find({"TransportShip","Warship","TradeShip"},u.Type) and math.abs(dx)<=12 and math.abs(dy)<=12 and dx*dx+dy*dy<distance then closest=u;distance=dx*dx+dy*dy end
        end;return closest
    end
    function view.renderShips(list,players)
        shipList=table.clone(list);for _,u in ipairs(railList)do table.insert(shipList,u)end;local colors={}
        for _,p in ipairs(players) do colors[p.SmallId]=p.Color;ownerCosmetics[p.SmallId]=p.Cosmetics;participantCosmetics[p.UserId]=p.Cosmetics end
        ships.set(shipList,colors)
    end
    function view.buildingAt(x,y)
        local closest=nil;local distance=math.huge
        for _,u in ipairs(buildingList) do
            local dx=(x-(u.Tile%Map.Width+0.5))*scale;local dy=(y-(math.floor(u.Tile/Map.Width)+0.5))*scale
            if buildings.isVisible(u.ID) and math.abs(dx)<=18 and math.abs(dy)<=18 and dx*dx+dy*dy<distance then closest=u;distance=dx*dx+dy*dy end
        end
        return closest
    end
    function view.renderBuildings(list,players)
        buildingList=list;local colors={}
        for _,p in ipairs(players) do colors[p.SmallId]=p.Color;ownerCosmetics[p.SmallId]=p.Cosmetics end
        buildings.set(list,colors)
    end
    function view.clear()
        effectSerial=0;table.clear(attackSerials);table.clear(ownerCosmetics);table.clear(participantCosmetics)
        for id,marker in pairs(markers)do marker:Destroy();markers[id]=nil end
        table.clear(markerOrder);labelVersion+=1
        buildingList={};shipList={};railList={};ships.set({},{});buildings.set({},{})
        ships.update(0,0,1,0,0);buildings.update(0,0,1,0,0)
        raster.setGrid(nil);raster.clear();foundationGrid=nil;view.setPlacement(nil,nil);tiles.invalidateAll();view.reset()
    end
    function view.setGrid(grid)
        foundationGrid=grid
        raster.setGrid(grid)
        tiles.invalidateAll()
    end
    function view.foundationDelta(packed, grid)
        tiles.invalidateChanges(packed)
    end
    function view.ready(): boolean return tiles.ready() end
	function view.zoomBy(factor: number) zoomGoal=nil;zoomAt(factor,viewport.AbsolutePosition+viewport.AbsoluteSize/2) end
	function view.focus(x: number, y: number)
        zoomGoal=nil
		local bounds = viewport.AbsoluteSize
		zoom = math.clamp(1 / math.min(bounds.X/Map.Width,bounds.Y/Map.Height),1,Config.MaxZoom)
		scale = math.min(bounds.X/Map.Width,bounds.Y/Map.Height)*zoom
		origin = bounds/2-Vector2.new(x,y)*scale
		update()
	end
	function view.reset() zoomGoal=nil;zoom=1;scale=math.min(viewport.AbsoluteSize.X/Map.Width,viewport.AbsoluteSize.Y/Map.Height); origin=Vector2.zero; update() end
	function view.delta(owner: number, packed: buffer, animate: boolean, deferInvalidation: boolean?)
		local now = os.clock()
		for offset = 0,buffer.len(packed)-1,4 do
			local cell = buffer.readu32(packed,offset)
			raster.set(cell,owner,now,animate)
			if not deferInvalidation then tiles.invalidate(cell,animate) end
		end
	end
    local crownColors={Color3.fromRGB(239,197,91),Color3.fromRGB(204,216,234),Color3.fromRGB(203,142,91)}
    function view.ranks(state)
        local ranks=Ranking.crowns(state.Players,state.Phase)
        for id,marker in pairs(markers)do
            local rank=ranks[id]or 0
            if marker:GetAttribute("CrownRank")~=rank then
                marker:SetAttribute("CrownRank",rank)
                local old=marker:FindFirstChild("TerritoryCrown");if old then old:Destroy()end
                if rank>0 then
                    local crown=Art.mapIcon(marker,"Crown",19,Cosmetic.tint(participantCosmetics[id],"Crown",crownColors[rank]));crown.Name="TerritoryCrown";crown.AnchorPoint=Vector2.new(.5,1);crown.Position=UDim2.new(.5,0,0,-42)
                    TweenService:Create(crown,TweenInfo.new(.2,Enum.EasingStyle.Quad),{Position=UDim2.new(.5,0,0,-36)}):Play()
                end
            end
        end
    end
	function view.render(state: any)
        local began=os.clock();local labelsChanged=false
        railList=state.RailUnits or {}
        view.renderBuildings(state.Buildings or {},state.Players)
        view.renderShips(state.Ships or {},state.Players)
        for _,event in ipairs(state.CosmeticEffects or {})do
            if event.ID>effectSerial then
                effectSerial=event.ID
                if state.Tick-event.Tick<=10 then pulse(event.Tile%Map.Width+.5,math.floor(event.Tile/Map.Width)+.5,Cosmetic.tint(ownerCosmetics[event.Owner],"Explosion",Color3.fromRGB(237,196,124)))end
            end
        end
		local present: {[number]: boolean} = {}
        table.clear(markerOrder)
		for _, profile in ipairs(state.Players) do
			present[profile.UserId] = true
			local id=profile.SmallId or profile.UserId
            if palette[id]~=profile.Color then palette[id]=profile.Color;raster.setColor(id,profile.Color.R*255,profile.Color.G*255,profile.Color.B*255)end
            raster.setStyle(id,profile.Cosmetics and profile.Cosmetics.Pattern=="pattern_weave",profile.Cosmetics and profile.Cosmetics.Border=="border_ink")
            if profile.Cosmetics and profile.Cosmetics.Attack and profile.AttackID and profile.AttackID>0 and attackSerials[id]~=profile.AttackID then
                attackSerials[id]=profile.AttackID
                if profile.LabelX or profile.X then pulse(profile.LabelX or profile.X,profile.LabelY or profile.Y,Cosmetic.tint(profile.Cosmetics,"Attack",Color3.fromRGB(131,189,235)))end
            end
			local marker = markers[profile.UserId]
			if profile.Spawn and not profile.LabelHidden then
				if not marker then
                    labelsChanged=true
					marker = Instance.new("Frame")
					marker.Name = profile.Username
					marker.AnchorPoint = Vector2.new(0.5,0.5)
					marker.Size = UDim2.fromOffset(8,8)
                    marker.Active=false
					marker.BorderSizePixel = 0
					marker.ZIndex = 6
					marker.Parent = markerLayer
					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(1,0); corner.Parent=marker
					local stroke = Instance.new("UIStroke")
					stroke.Color=Color3.new(1,1,1); stroke.Thickness=1.5; stroke.Parent=marker
					local name = Instance.new("TextLabel")
					name.Name="Username";name.AutoLocalize=false;name.RichText=false; name.AnchorPoint=Vector2.new(0.5,1)
					name.Position=UDim2.new(0.5,0,0,-4); name.Size=UDim2.fromOffset(164,32)
					name.BackgroundTransparency=1;name.BorderSizePixel=0;name.Active=false; name.Font=Enum.Font.GothamBold; name.TextSize=12
					name.TextStrokeColor3=Color3.fromRGB(9,14,22);name.TextStrokeTransparency=0.35; name.ZIndex=7; name.Parent=marker
                    -- No background, badge or input surface on territory labels.
					markers[profile.UserId]=marker
				end
				if marker.BackgroundColor3~=profile.Color then marker.BackgroundColor3=profile.Color end
                local own=profile.UserId==game:GetService("Players").LocalPlayer.UserId;if marker:GetAttribute("Local")~=own then marker:SetAttribute("Local",own)end
                local dot=if own then 12 else 7;local bounds=UDim2.fromOffset(dot,dot);if marker.Size~=bounds then marker.Size=bounds end
				-- This is the exact inverse of click conversion. No cell-centre snap.
				local position=UDim2.fromScale((profile.LabelX or profile.X)/Map.Width,(profile.LabelY or profile.Y)/Map.Height);if marker.Position~=position then marker.Position=position;labelsChanged=true end
				local name = marker:FindFirstChild("Username") :: TextLabel
				local text=profile.Username..(if profile.Troops then "\n"..tostring(math.floor(profile.Troops)).." soldiers" else "");if name.Text~=text then name.Text=text end
                name.TextColor3=Color3.fromRGB(246,248,252)
                name.TextStrokeColor3=Cosmetic.tint(profile.Cosmetics,"NameTag",Color3.fromRGB(9,14,22))
                -- Names remain high-contrast; optional flags never replace the name.
                name:SetAttribute("AccountUsername",profile.AccountUsername or profile.Username)
                local flagID=profile.Cosmetics and profile.Cosmetics.Flag
                if marker:GetAttribute("FlagID")~=flagID then
                    marker:SetAttribute("FlagID",flagID);local old=name:FindFirstChild("NationFlag");if old then old:Destroy()end
                    if flagID then local flag=Cosmetic.flag(name,flagID,20);if flag then flag.Position=UDim2.new(0,-26,.5,-7)end end
                end
                if profile.UserId==game:GetService("Players").LocalPlayer.UserId then table.insert(markerOrder,1,marker)else table.insert(markerOrder,marker)end
			elseif marker then marker:Destroy(); markers[profile.UserId]=nil;labelsChanged=true end
		end
		for id,marker in pairs(markers) do if not present[id] then marker:Destroy(); markers[id]=nil;labelsChanged=true end end
        if labelsChanged then labelVersion+=1 end
		layoutNames()
        view.ranks(state)
        local elapsed=(os.clock()-began)*1000;renderWorst=math.max(renderWorst,elapsed);canvas:SetAttribute("RosterRenderMilliseconds",elapsed);canvas:SetAttribute("RosterRenderWorstMilliseconds",renderWorst)
		if state.Territory then
			raster.clear()
			for _,group in ipairs(state.Territory) do view.delta(group.Owner,group.Cells,false,true) end
			tiles.invalidateAll()
		end
		if state.Released then view.delta(0,state.Released,false,true); tiles.invalidateAll() end
		if state.Phase == "Selecting" and not state.Foundation then
			raster.clear()
			for _,profile in ipairs(state.Players) do
				if profile.Spawn and not profile.LabelHidden then
					for _,cell in ipairs(Map.seed(profile.Spawn)) do raster.set(cell,profile.UserId,os.clock(),false) end
				end
			end
			tiles.invalidateAll()
		end
	end
	viewport.Destroying:Connect(function() connection:Disconnect(); ships.destroy(); buildings.destroy(); tiles.destroy() end)
	return view
end
return MapView
