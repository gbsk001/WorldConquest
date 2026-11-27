--!strict
-- Shared licensed image registry. Original layout code remains AGPL-3.0.
local Icons=require(script.Parent.IconAssets)
local Art={}
function Art.icon(parent,kind,size,color)return Icons.new(parent,kind,size,color)end
function Art.mapIcon(parent,kind,size,color)return Icons.new(parent,kind,size,color)end
function Art.prepareMapIcons()end -- Atlases load once on demand, never during camera updates.
function Art.mapIconsReady()return Icons.ready()end
function Art.buttonContent(button,kind,iconOnly)
 button.TextWrapped=false;button.TextScaled=false;button.TextTransparency=1
 local content=Instance.new("Frame");content.Name="ButtonContent";content.BackgroundTransparency=1;content.Active=false;content.Position=UDim2.fromOffset(10,0);content.Size=UDim2.new(1,-20,1,0);content.Parent=button
 local layout=Instance.new("UIListLayout");layout.FillDirection=Enum.FillDirection.Horizontal;layout.VerticalAlignment=Enum.VerticalAlignment.Center;layout.HorizontalAlignment=Enum.HorizontalAlignment.Center;layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Padding=UDim.new(0,8);layout.Parent=content
 local icon=Art.icon(content,kind,24,button.TextColor3);icon.LayoutOrder=1
 local label=nil
 local tooltip=nil
 if iconOnly then
  tooltip=Instance.new("TextLabel");tooltip.Name="ControlTooltip";tooltip.Visible=false;tooltip.Active=false;tooltip.BackgroundColor3=Color3.fromRGB(15,23,35);tooltip.BorderSizePixel=0;tooltip.TextColor3=Color3.new(1,1,1);tooltip.Font=Enum.Font.GothamMedium;tooltip.TextSize=14;tooltip.TextWrapped=false;tooltip.TextScaled=false;tooltip.Size=UDim2.fromOffset(132,30);tooltip.Position=UDim2.new(0,0,1,6);tooltip.Parent=button
  button.MouseEnter:Connect(function()tooltip.Visible=true end);button.MouseLeave:Connect(function()tooltip.Visible=false end)
 end
 if not iconOnly then
  label=Instance.new("TextLabel");label.Name="ButtonLabel";label.BackgroundTransparency=1;label.Active=false;label.LayoutOrder=2;label.Size=UDim2.new(1,-32,1,0);label.TextWrapped=false;label.TextScaled=false;label.TextTruncate=Enum.TextTruncate.AtEnd;label.Parent=content
 end
 local function sync()
  icon.ImageColor3=button.TextColor3;content.ZIndex=button.ZIndex+1;icon.ZIndex=content.ZIndex
  if label then label.Text=button.Text;label.TextColor3=button.TextColor3;label.Font=button.Font;label.TextSize=button.TextSize;label.ZIndex=content.ZIndex end
  if tooltip then tooltip.Text=if button.Text~=""then button.Text else button.Name;tooltip.ZIndex=content.ZIndex+10 end
  button:SetAttribute("AccessibleLabel",button.Text)
 end
 for _,property in ipairs({"Name","Text","TextColor3","Font","TextSize","ZIndex"})do button:GetPropertyChangedSignal(property):Connect(sync)end
 sync();return icon,label
end
function Art.cardContent(button,kind)
 button.TextTransparency=1;button.TextScaled=false
 local content=Instance.new("Frame");content.Name="CardContent";content.BackgroundTransparency=1;content.Active=false;content.Position=UDim2.fromOffset(6,8);content.Size=UDim2.new(1,-12,1,-16);content.Parent=button
 local layout=Instance.new("UIListLayout");layout.FillDirection=Enum.FillDirection.Vertical;layout.VerticalAlignment=Enum.VerticalAlignment.Center;layout.HorizontalAlignment=Enum.HorizontalAlignment.Center;layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Padding=UDim.new(0,4);layout.Parent=content
 local icon=Art.icon(content,kind,32,button.TextColor3);icon.LayoutOrder=1
 local label=Instance.new("TextLabel");label.Name="CardLabel";label.LayoutOrder=2;label.Size=UDim2.new(1,0,0,44);label.BackgroundTransparency=1;label.Active=false;label.Font=Enum.Font.GothamMedium;label.TextSize=14;label.TextWrapped=true;label.TextScaled=false;label.Parent=content
 local function sync()label.Text=button.Text;label.TextColor3=button.TextColor3;icon.ImageColor3=button.TextColor3;content.ZIndex=button.ZIndex+1;icon.ZIndex=content.ZIndex;label.ZIndex=content.ZIndex end
 for _,key in ipairs({"Text","TextColor3","ZIndex"})do button:GetPropertyChangedSignal(key):Connect(sync)end
 sync();return icon,label
end
function Art.profile(parent,name,size)
 local seed=29;for i=1,#name do seed=(seed*31+string.byte(name,i))%16777213 end
 local root=Instance.new("Frame");root.Name="GeneratedProfile";root.Size=UDim2.fromOffset(size,size);root.BackgroundColor3=Color3.fromRGB(24,35,51);root.BorderSizePixel=0;root.Active=false;root.Parent=parent
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(1,0);corner.Parent=root
 local color=Color3.fromRGB(100+seed%140,110+math.floor(seed/140)%130,120+math.floor(seed/19600)%120)
 local icon=Art.icon(root,"Profile",size*.72,color);icon.AnchorPoint=Vector2.new(.5,.5);icon.Position=UDim2.fromScale(.5,.5)
 return root
end
function Art.world(parent,map)
 -- A dedicated low sibling branch; deferred imagery can never cover menu content.
 local world=Instance.new("Frame");world.Name="EarthSilhouette";world.BackgroundTransparency=1;world.Size=UDim2.fromScale(1,1);world.ZIndex=0;world.Active=false;world.ClipsDescendants=true;world.Parent=parent
 local canvas=Instance.new("Frame");canvas.Name="MenuTerrain";canvas.BorderSizePixel=0;canvas.BackgroundColor3=Color3.fromRGB(39,91,133);canvas.ZIndex=0;canvas.Active=false;canvas.Parent=world
 local terrain=require(script.Parent.TerrainColors);map.terrain=terrain.sample;map.terrainDensity=terrain.Density
 local raster={sample=function()return 0,0,0,0 end}
 local tiles=require(script.Parent.MapTiles).new(canvas,raster)
 if not tiles then tiles=require(script.Parent.CompatibleTiles).new(canvas,raster)end
 local screen=parent:FindFirstAncestorWhichIsA("ScreenGui")
 local last=nil;local lastX=nil;local lastY=nil
 local function update()
  local enabled=not screen or screen.Enabled;tiles.setEnabled(enabled);if not enabled then return end
  local size=world.AbsoluteSize;if size.X<=0 or size.Y<=0 then return end
  local scale=math.max(size.X/map.Width,size.Y/map.Height)
  local x=(size.X-map.Width*scale)/2;local y=(size.Y-map.Height*scale)/2
  if last~=scale or lastX~=x or lastY~=y then canvas.Position=UDim2.fromOffset(x,y);canvas.Size=UDim2.fromOffset(map.Width*scale,map.Height*scale);last=scale;lastX=x;lastY=y end
  tiles.update(x,y,scale,size.X,size.Y)
 end
 local connection=game:GetService("RunService").Heartbeat:Connect(update)
 world.Destroying:Connect(function()connection:Disconnect();tiles.destroy()end)
 update();return world
end
return Art
