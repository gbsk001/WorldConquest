--!strict
-- Bounded visible-row runs, only used when EditableImage is unavailable.
-- Presentation LOD only: authoritative 8192x4096 cells are never changed.
local Map=require(game:GetService("ReplicatedStorage").Shared.Map)
local RunService=game:GetService("RunService")
local Tiles={}
function Tiles.new(canvas,raster)
 local pool={};local enabled=true;local wanted=nil;local job=nil;local dirty=true;local painted="";local last=0
 local api={};local maxObjects=8192
 canvas:SetAttribute("CompatibleRenderer",true)
 function api.update(ox,oy,scale,w,h)
  local level=math.max(0,math.ceil(math.log(math.max(1,w/96/scale,h/64/scale))/math.log(2)))
  local step=2^level
  local x0=math.max(0,math.floor(-ox/scale/step));local y0=math.max(0,math.floor(-oy/scale/step))
  local x1=math.min(math.ceil(Map.Width/step)-1,math.ceil((w-ox)/scale/step));local y1=math.min(math.ceil(Map.Height/step)-1,math.ceil((h-oy)/scale/step))
  local key=string.format("%d:%d:%d:%d:%d",level,x0,y0,x1,y1)
  wanted={Key=key,Level=level,Step=step,X0=x0,Y0=y0,X1=x1,Y1=y1}
 end
 local function invalidate()dirty=true end
 api.invalidate= invalidate;api.invalidateAll=invalidate;api.invalidateChanges=invalidate
 function api.setEnabled(value)enabled=value end
 function api.ready()return painted~=""end
 function api.readyAt()return true end -- Tap validation always uses exact full-resolution land.
 function api.metrics()return {CompatibleRenderer=true,TileObjects=#pool}end
 local connection=RunService.Heartbeat:Connect(function()
  if not enabled or not wanted then return end
  if not job and (wanted.Key~=painted or dirty and os.clock()-last>.25)then job=table.clone(wanted);job.Y=job.Y0;job.Count=0;dirty=false end
  if not job then return end
  local began=os.clock()
  repeat
   local y=job.Y;local x=job.X or job.X0
   local function color(px)
    local t=y*job.Step*Map.Width+px*job.Step
    local r,g,b,owned=raster.sample(job.Level,px,y,0)
    if owned==1 then return Color3.fromRGB(r,g,b)end
    return if Map.isLand(t+1)then Color3.fromRGB(115,139,128)else Color3.fromRGB(20,45,65)
   end
   while x<=job.X1 do
    local first=x;local shade=color(x);x+=1
    while x<=job.X1 and color(x)==shade do x+=1 end
    job.Count+=1;assert(job.Count<=maxObjects,"Compatibility viewport exceeded its object budget")
    local f=pool[job.Count]
    if not f then f=Instance.new("Frame");f.Name="CompatibleMapRun";f.BorderSizePixel=0;f.Active=false;f.ZIndex=2;f.Parent=canvas;pool[job.Count]=f end
    f.BackgroundColor3=shade;f.Position=UDim2.fromScale(first*job.Step/Map.Width,y*job.Step/Map.Height);f.Size=UDim2.fromScale((x-first)*job.Step/Map.Width,job.Step/Map.Height);f.Visible=true
    job.X=x;if os.clock()-began>=.0015 then break end
   end
   if x>job.X1 then job.Y+=1;job.X=nil end
  until job.Y>job.Y1 or os.clock()-began>=.0015
  if job.Y>job.Y1 then for i=job.Count+1,#pool do pool[i].Visible=false end;painted=job.Key;last=os.clock();job=nil end
 end)
 function api.destroy()connection:Disconnect();for _,f in ipairs(pool)do f:Destroy()end;table.clear(pool)end
 return api
end
return Tiles
