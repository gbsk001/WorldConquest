--!strict
-- Bounded, session-local presentation; not a log of routine simulation actions.
local TweenService=game:GetService("TweenService")
local Art=require(script.Parent.InterfaceArt)
local Toasts={}
local colors={Success=Color3.fromRGB(109,220,164),Info=Color3.fromRGB(116,182,243),Reward=Color3.fromRGB(241,190,91),Error=Color3.fromRGB(243,125,135)}
function Toasts.new(parent)
 local root=Instance.new("Frame");root.Name="ToastStack";root.AnchorPoint=Vector2.new(1,0);root.BackgroundTransparency=1;root.Active=false;root.ZIndex=75;root.Parent=parent
 local items={};local preference="Important";local reduced=false;local alive=true;local api={Root=root}
 local function arrange()
  for i,item in ipairs(items)do item.Root.Position=UDim2.fromOffset(0,(i-1)*72)end
  root.Size=UDim2.fromOffset(math.min(336,math.max(240,parent.AbsoluteSize.X-16)),#items*72)
 end
 function api.layout(bottom)root.Position=UDim2.new(1,-8,0,bottom+8);arrange()end
 local function remove(item)
  local index=table.find(items,item);if not index then return end;table.remove(items,index);item.Generation+=1
  item.Root:Destroy();arrange()
 end
 local function expire(item)
  item.Generation+=1;local generation=item.Generation
  task.delay(2.8,function()
   if not alive or generation~=item.Generation or not table.find(items,item)then return end
   if reduced then remove(item);return end
   TweenService:Create(item.Root,TweenInfo.new(.16),{BackgroundTransparency=1}):Play()
   TweenService:Create(item.Text,TweenInfo.new(.16),{TextTransparency=1}):Play()
   task.delay(.16,function()if generation==item.Generation then remove(item)end end)
  end)
 end
 function api.push(message,category,important)
  if typeof(message)~="string"or message==""then return end
  local lower=string.lower(message)
  if string.find(lower,"expanding along",1,true)or string.find(lower,"expansion ordered",1,true)then return end
  category=category or (if string.find(lower,"fail",1,true)or string.find(lower,"invalid",1,true)or string.find(lower,"cannot",1,true)or string.find(lower,"not enough",1,true)then "Error"elseif string.find(lower,"purchas",1,true)or string.find(lower,"reward",1,true)or string.find(lower,"construct",1,true)then "Reward"else "Info")
  if category=="Info"then
   if string.find(lower,"rejected",1,true)or string.find(lower,"incoming",1,true)then category="Error"
   elseif string.find(lower,"achievement",1,true)or string.find(lower,"upgraded",1,true)or string.find(lower,"earned",1,true)then category="Reward"
   elseif string.find(lower,"captured",1,true)then category="Success"end
  end
  if not colors[category]then category="Info"end
  if preference=="Minimal"and category~="Error"and category~="Reward"then return end
  if preference=="Important"and important==false then return end
  for _,item in ipairs(items)do if item.Message==message then
   item.Count+=1;item.Text.Text=message.." ×"..item.Count;item.Text.TextTransparency=0;item.Root.BackgroundTransparency=0;expire(item);return
  end end
  if #items==3 then remove(items[1])end
  local panel=Instance.new("Frame");panel.Name="Toast";panel.BackgroundColor3=Color3.fromRGB(16,25,39);panel.BackgroundTransparency=0;panel.BorderSizePixel=0;panel.Size=UDim2.new(1,0,0,64);panel.ZIndex=76;panel.Active=false;panel.Parent=root
  local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,12);c.Parent=panel
  local stroke=Instance.new("UIStroke");stroke.Color=colors[category];stroke.Transparency=.65;stroke.Parent=panel
  local icon=Art.icon(panel,if category=="Success"then "Check"elseif category=="Reward"then "Stars"else "Notification",20,colors[category]);icon.Position=UDim2.fromOffset(12,22)
  local t=Instance.new("TextLabel");t.Name="Message";t.BackgroundTransparency=1;t.Position=UDim2.fromOffset(42,8);t.Size=UDim2.new(1,-88,1,-16);t.Text=message;t.TextWrapped=true;t.TextTruncate=Enum.TextTruncate.AtEnd;t.TextSize=14;t.Font=Enum.Font.GothamMedium;t.TextColor3=Color3.fromRGB(238,244,252);t.TextXAlignment=Enum.TextXAlignment.Left;t.ZIndex=77;t.Parent=panel
  local close=Instance.new("TextButton");close.Name="Dismiss";close.Text="";close.Size=UDim2.fromOffset(44,44);close.Position=UDim2.new(1,-44,0,10);close.BackgroundTransparency=1;close.ZIndex=78;close.Parent=panel
  local cross=Art.icon(close,"Close",14,Color3.fromRGB(179,196,218));cross.Position=UDim2.fromOffset(15,15)
  local item={Root=panel,Text=t,Message=message,Count=1,Generation=0};table.insert(items,item);close.Activated:Connect(function()remove(item)end);arrange()
  if not reduced then local target=panel.Position;panel.Position=UDim2.new(target.X.Scale,target.X.Offset+16,target.Y.Scale,target.Y.Offset);panel.BackgroundTransparency=1;t.TextTransparency=1;TweenService:Create(panel,TweenInfo.new(.16),{Position=target,BackgroundTransparency=0}):Play();TweenService:Create(t,TweenInfo.new(.16),{TextTransparency=0}):Play()end
  expire(item)
 end
 function api.clear()while #items>0 do remove(items[#items])end end
 function api.preference(value)assert(value=="All"or value=="Important"or value=="Minimal");preference=value;api.clear()end
 function api.motion(value)reduced=value end
 function api.obscured(value)root.Visible=not value end
 parent.Destroying:Connect(function()alive=false;api.clear()end)
 api.layout(56);return api
end
return Toasts
