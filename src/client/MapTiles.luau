--!strict
-- Bounded, view-dependent EditableImage tiles. One image upload per frame.
-- Zoom selects new samples from the detailed mask, not an enlarged overview.
local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Map = require(Shared:WaitForChild("Map"))
local Config = require(Shared:WaitForChild("Config"))
local Painter = require(script.Parent:WaitForChild("TilePainter"))
local Dirty=require(script.Parent.DirtyTiles)
local Tiles = {}
local SIZE, PADDED = Painter.Size, Painter.Padded

function Tiles.new(canvas: Frame, raster: any)
 if Config.ForceCompatibleRenderer then return nil end -- Diagnostic/fallback override, never changes simulation.
	local pool: {any} = {}
	local budget = Config.MaxImageTiles
	local active: {[string]: any} = {}
	local signature = ""
	local currentLevel = 0
	local roundRobin = 0
	local stopped = false
 local enabled=true;local pendingAllocation=false;local generation=0
 local centreX,centreY=0,0
	local function createSlot(): any
		local ok, image = pcall(function() return AssetService:CreateEditableImage({ Size = Vector2.new(PADDED, PADDED) }) end)
		if not ok or not image then return nil end
		local label = Instance.new("ImageLabel")
		label.Name = "EarthTile"
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.ImageContent = Content.fromObject(image)
		label.ImageRectOffset = Vector2.new(1, 1)
		label.ImageRectSize = Vector2.new(SIZE, SIZE)
		label.ResampleMode = Enum.ResamplerMode.Pixelated
		label.Visible = false
		label.ZIndex = 2
		label.Parent = canvas
		local slot = { Image = image, Label = label, Key = "", Painted = "", Visible = false,
			Pixels = buffer.create(PADDED * PADDED * 4), Coverage = buffer.create(PADDED * PADDED), Dirty = false }
		table.insert(pool, slot)
		return slot
	end
	-- A genuine averaged overview remains beneath loading detail, avoiding holes
	-- while the higher-resolution visible tiles are generated over several frames.
	local overview = createSlot()
	if not overview then return nil end
	local overviewOK=pcall(function()
	Map.prepareDisplay()
	table.remove(pool)
	overview.Level, overview.X, overview.Y = 5, 0, 0
	local deadline=os.clock()+.002
	for row=0,129,4 do
  Painter.paint(overview,raster,os.clock(),true,row,math.min(129,row+3))
  if task and task.wait and os.clock()>=deadline then task.wait();deadline=os.clock()+.002 end
 end
	overview.Image:WritePixelsBuffer(Vector2.zero, Vector2.new(PADDED,PADDED), overview.Pixels)
 end)
 if not overviewOK then overview.Label:Destroy();overview.Image:Destroy();return nil end
	overview.Label.ZIndex = 0
	overview.Label.Position = UDim2.fromScale(0,0)
	overview.Label.Size = UDim2.fromScale(1,1)
	overview.Label.ImageRectSize = Vector2.new(256,128)
	overview.Label.Visible = true
	-- Its upload scratch buffers are not needed after the initial overview.
	overview.Pixels, overview.Coverage, overview.Base = nil, nil, nil
	if not createSlot() then overview.Label:Destroy(); overview.Image:Destroy(); return nil end
	local function key(level: number, x: number, y: number): string return level .. ":" .. x .. ":" .. y end
 local result = {Metrics={PaintMilliseconds=0,UploadMilliseconds=0,UploadBytes=0,PaintWorstMilliseconds=0,UploadWorstMilliseconds=0,AllocationMilliseconds=0,InvalidationMilliseconds=0,InvalidationVisits=0}}
 function result.setEnabled(value)enabled=value end
	function result.update(ox: number, oy: number, scale: number, width: number, height: number)
		local level = math.clamp(math.floor(math.log(1 / math.max(scale, 0.0001)) / math.log(2)), 0, 6)
		local x0, x1, y0, y1, extent
		repeat
			extent = SIZE * 2 ^ level
			x0 = math.max(0, math.floor(-ox / scale / extent))
			y0 = math.max(0, math.floor(-oy / scale / extent))
			x1 = math.min(math.ceil(Map.Width / extent) - 1, math.floor((width - ox) / scale / extent))
			y1 = math.min(math.ceil(Map.Height / extent) - 1, math.floor((height - oy) / scale / extent))
			if (x1-x0+1)*(y1-y0+1) <= budget or level == 6 then break end
			level += 1
		until false
		local nextSignature = string.format("%d:%d:%d:%d:%d:%d", level, x0, x1, y0, y1, budget)
		if signature == nextSignature then return end
		signature, currentLevel = nextSignature, level
        generation+=1;centreX=(width/2-ox)/scale;centreY=(height/2-oy)/scale
		local wanted: {[string]: boolean} = {}
		for y = y0, y1 do for x = x0, x1 do wanted[key(level,x,y)] = true end end
		for _, slot in ipairs(pool) do
			slot.Visible = wanted[slot.Key] == true
			local e=SIZE*2^(slot.Level or 0)
            local intersects=slot.Level and (slot.X+1)*e*scale+ox>=0 and slot.X*e*scale+ox<=width and (slot.Y+1)*e*scale+oy>=0 and slot.Y*e*scale+oy<=height
            slot.Label.Visible=(slot.Visible or intersects==true)and slot.Painted==slot.Key
            slot.Label.ZIndex=if slot.Visible then 2 else 1
		end
		table.clear(active)
		for y = y0, y1 do
			for x = x0, x1 do
				local tileKey = key(level, x, y)
				local chosen = nil
				for _, slot in ipairs(pool) do if slot.Key == tileKey then chosen = slot; break end end
                if not chosen then
                    -- Prefer spare storage; preserve recent detailed tiles across LOD changes.
                    for _,slot in ipairs(pool)do if slot.Key==""then chosen=slot;break end end
                end
                if not chosen and #pool<budget then pendingAllocation=true;signature="";return end
                if not chosen then
                    for _,slot in ipairs(pool)do if not slot.Visible and (not chosen or (slot.LastUsed or 0)<(chosen.LastUsed or 0))then chosen=slot end end
                end
                if not chosen then signature="";return end
				if chosen.Key ~= tileKey then
					chosen.Key, chosen.Painted, chosen.Dirty = tileKey, "", true
                    chosen.Bounds=nil
					chosen.Level, chosen.X, chosen.Y = level, x, y
				end
				chosen.Visible = true;chosen.LastUsed=generation;chosen.Label.ZIndex=2
				chosen.Label.Position = UDim2.fromScale(x * extent / Map.Width, y * extent / Map.Height)
				chosen.Label.Size = UDim2.fromScale(extent / Map.Width, extent / Map.Height)
				chosen.Label.Visible = chosen.Painted == tileKey
				active[tileKey] = chosen
			end
		end
	end
	function result.invalidate(cell: number, animate: boolean)
		local x, y = Map.xy(cell)
		for _, slot in ipairs(pool) do
			if slot.Level then
				local step = 2 ^ slot.Level
				local extent = SIZE * step
				-- Includes the one-texel gutter; neighbouring tiles share edge samples.
				if x >= slot.X * extent - step and x < (slot.X+1)*extent + step
					and y >= slot.Y*extent - step and y < (slot.Y+1)*extent + step then
					slot.Dirty = true
					local px = math.floor(x / step) - slot.X * SIZE + 1
					local py = math.floor(y / step) - slot.Y * SIZE + 1
					if slot.Bounds then
						local b = slot.Bounds
						b[1],b[2],b[3],b[4] = math.min(b[1],px),math.min(b[2],py),math.max(b[3],px),math.max(b[4],py)
					else slot.Bounds = {px,py,px,py} end
				end
			end
		end
	end
	function result.invalidateAll()
		for _, slot in ipairs(pool) do slot.Dirty = true; slot.Bounds = {0,0,PADDED-1,PADDED-1} end
	end
 -- Border shading depends on cardinal neighbours. Invalidate their bounding
 -- rectangle in one pool walk rather than five walks per changed cell.
 function result.invalidateChanges(packed)
  local began=os.clock()
  result.Metrics.InvalidationVisits=Dirty.apply(pool,packed,Map.Width,Map.Height,SIZE,PADDED)
  result.Metrics.InvalidationMilliseconds=(os.clock()-began)*1000
 end

	function result.readyAt(x: number, y: number): boolean
		local extent = SIZE * 2 ^ currentLevel
		local slot = active[key(currentLevel, math.floor(x/extent), math.floor(y/extent))]
		return slot ~= nil and slot.Painted == slot.Key
	end
	function result.ready(): boolean
		if pendingAllocation or signature=="" or next(active) == nil then return false end
		for _, slot in pairs(active) do if slot.Painted ~= slot.Key then return false end end
		return true
	end
	local job: any = nil
	local connection = RunService.Heartbeat:Connect(function()
		if stopped or not enabled then return end
        result.Metrics.AllocationMilliseconds=0
        if pendingAllocation then
            pendingAllocation=false;local began=os.clock();local slot=createSlot()
            result.Metrics.AllocationMilliseconds=(os.clock()-began)*1000
            if not slot then budget=#pool end
            signature=""
            return -- At most one image allocation per frame, outside camera/input handlers.
        end
		if job and (not job.Slot.Visible or job.Key ~= job.Slot.Key) then
			-- The CPU buffer can contain a partial, not-yet-uploaded repaint.
			job.Slot.Dirty = true
			job.Slot.Bounds = {0,0,PADDED-1,PADDED-1}
			job = nil
		end
        if not job then
            local best=nil;local distance=math.huge
            for _,slot in ipairs(pool)do if slot.Visible and slot.Dirty then
                local extent=SIZE*2^slot.Level
                local d=((slot.X+.5)*extent-centreX)^2+((slot.Y+.5)*extent-centreY)^2
                -- Unpainted visible detail wins, then distance to the viewport centre.
                if slot.Painted~=slot.Key then d-=Map.Width*Map.Width end
                if d<distance then best=slot;distance=d end
            end end
            if best then
                local fresh=best.Painted~=best.Key
                local b=if fresh then {0,0,PADDED-1,PADDED-1}else best.Bounds or {0,0,PADDED-1,PADDED-1}
                job={Slot=best,Key=best.Key,Row=b[2],Bounds=b,Time=os.clock(),Fresh=fresh}
                best.Bounds,best.Dirty=nil,false
            end
        end
  result.Metrics.PaintMilliseconds=0;result.Metrics.UploadMilliseconds=0;result.Metrics.UploadBytes=0
  if not job then return end
		local started = os.clock()
		repeat
			local last = math.min(job.Bounds[4], job.Row+(if Map.terrain then 0 else 7))
			Painter.paint(job.Slot, raster, job.Time, job.Fresh, job.Row, last, job.Bounds[1], job.Bounds[3])
			job.Row = last+1
		until job.Row > job.Bounds[4] or os.clock()-started >= Config.RenderBudgetSeconds
  result.Metrics.PaintMilliseconds=(os.clock()-started)*1000
  result.Metrics.PaintWorstMilliseconds=math.max(result.Metrics.PaintWorstMilliseconds,result.Metrics.PaintMilliseconds)
		if job.Row > job.Bounds[4] then
   local uploadStart=os.clock()
			local slot = job.Slot
			local b = job.Bounds
			local w,h = b[3]-b[1]+1,b[4]-b[2]+1
			local full=w==PADDED and h==PADDED
            local pixels=if full then slot.Pixels else buffer.create(w*h*4)
            if not full then for row=0,h-1 do buffer.copy(pixels,row*w*4,slot.Pixels,((row+b[2])*PADDED+b[1])*4,w*4)end end
			if debug.profilebegin then debug.profilebegin("WC.TextureUpload")end
   local uploaded,reason=pcall(function()slot.Image:WritePixelsBuffer(Vector2.new(b[1],b[2]), Vector2.new(w,h), pixels)end)
   if debug.profileend then debug.profileend()end
   if not uploaded then
    stopped=true;if warn then warn("WorldConquest texture upload failed: "..tostring(reason))end
    if result.OnFailure then if task and task.defer then task.defer(result.OnFailure)else result.OnFailure()end end;return
   end
   result.Metrics.UploadBytes=buffer.len(pixels)
   result.Metrics.UploadMilliseconds=(os.clock()-uploadStart)*1000
   result.Metrics.UploadWorstMilliseconds=math.max(result.Metrics.UploadWorstMilliseconds,result.Metrics.UploadMilliseconds)
			slot.Painted = slot.Key
			slot.Label.Visible = true
			-- Finish in-flight tiles even under continuous multiplayer updates; newer
			-- changes schedule another pass instead of starving an unfinished image.
			-- Changes arriving during this job retain their own dirty bounds.
			job = nil -- At most one changed EditableImage is uploaded this frame.
		end
	end)
 function result.metrics()
  local dirty=0;for _,slot in ipairs(pool) do if slot.Visible and slot.Dirty then dirty+=1 end end
  result.Metrics.DirtyVisibleTiles=dirty
  result.Metrics.PaintJobAgeSeconds=if job then os.clock()-job.Time else 0
  result.Metrics.TileObjects=#pool+1
  return result.Metrics
 end
	function result.destroy()
		stopped = true
		connection:Disconnect()
		for _, slot in ipairs(pool) do slot.Label:Destroy(); slot.Image:Destroy() end
		overview.Label:Destroy(); overview.Image:Destroy()
	end
	return result
end
return Tiles
