--!strict
-- Original presentation. Statistics use server state; no simulation or camera work.
local TextService=game:GetService("TextService")
local Art=require(script.Parent.InterfaceArt)
local Status={}
function Status.new(parent)
 local panel=Instance.new("Frame");panel.Name="MatchSummary";panel.AnchorPoint=Vector2.new(1,0);panel.BackgroundColor3=Color3.fromRGB(14,22,36);panel.BackgroundTransparency=0;panel.BorderSizePixel=0;panel.ZIndex=80;panel.Active=true;panel.Parent=parent
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,14);corner.Parent=panel
 local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(67,84,108);stroke.Transparency=.45;stroke.Parent=panel
 local padding=Instance.new("UIPadding");padding.PaddingLeft=UDim.new(0,12);padding.PaddingRight=UDim.new(0,12);padding.Parent=panel
 local layout=Instance.new("UIListLayout");layout.FillDirection=Enum.FillDirection.Horizontal;layout.VerticalAlignment=Enum.VerticalAlignment.Center;layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Padding=UDim.new(0,10);layout.Parent=panel
 local slots={};local labels={};local icons={};local api={Panel=panel,Bottom=56,Width=300}
 for i,entry in ipairs({{"Timer","Calendar","00:00"},{"Rank","Rank","—"},{"Territory","Territory","0.00%"}})do
  if i>1 then local s=Instance.new("Frame");s.Name="Separator"..i;s.LayoutOrder=i*2-1;s.Size=UDim2.fromOffset(1,20);s.BorderSizePixel=0;s.BackgroundColor3=Color3.fromRGB(65,80,103);s.BackgroundTransparency=.35;s.ZIndex=81;s.Parent=panel end
  local slot=Instance.new("Frame");slot.Name=entry[1];slot.BackgroundTransparency=1;slot.LayoutOrder=i*2;slot.ZIndex=81;slot.Parent=panel;slots[i]=slot
  local icon=Art.icon(slot,entry[2],18,if i==2 then Color3.fromRGB(241,190,91)else Color3.fromRGB(155,195,228));icon.AnchorPoint=Vector2.new(0,.5);icon.Position=UDim2.new(0,0,.5,0);icons[i]=icon
  local t=Instance.new("TextLabel");t.Name="Value";t.BackgroundTransparency=1;t.Position=UDim2.fromOffset(24,0);t.Size=UDim2.new(1,-24,1,0);t.Font=Enum.Font.GothamBold;t.TextSize=17;t.TextColor3=Color3.fromRGB(242,247,255);t.TextXAlignment=Enum.TextXAlignment.Left;t.TextWrapped=false;t.TextScaled=false;t.AutoLocalize=false;t.RichText=false;t.ZIndex=82;t.Text=entry[3];t.Parent=slot;labels[i]=t
 end
 local function measure(value,size)
  local ok,result=pcall(function()return TextService:GetTextSize(value,size,Enum.Font.GothamBold,Vector2.new(1000,100))end)
  return if ok then math.ceil(result.X)else math.ceil(#value*size*.69)
 end
 function api.resize()
  local available=math.max(240,parent.AbsoluteSize.X-16);local size=17;local widths={};local total=0
  local compact=available<320;local prefix=if compact then 20 else 24
  layout.Padding=UDim.new(0,if compact then 6 else 10)
  for i,t in ipairs(labels)do t.Position=UDim2.fromOffset(prefix,0);t.Size=UDim2.new(1,-prefix,1,0);icons[i].Size=UDim2.fromOffset(if compact then 15 else 18,if compact then 15 else 18)end
  repeat
   total=if compact then 50 else 66 -- 24 outer padding + four 10px gaps + two separators.
   for i,t in ipairs(labels)do widths[i]=prefix+measure(t.Text,size);total+=widths[i]end
   if total<=available or size<=13 then break end;size-=1
  until false
  for i,slot in ipairs(slots)do slot.Size=UDim2.fromOffset(widths[i],44);labels[i].TextSize=size end
  -- Wrap the whole component below the toolbar, never the individual statistics.
  local y=if parent.AbsoluteSize.X<total+330 then 62 else 8
  panel.Position=UDim2.new(1,-8,0,y);panel.Size=UDim2.fromOffset(total,48)
  api.Bottom=y+48;api.Width=total
  if api.OnLayout then api.OnLayout(api.Bottom,api.Width)end
 end
 function api.update(state,rank,count,land)
  local seconds=math.max(0,math.floor(((state.Tick or 0)-(state.StartTick or 0))/10))
  if state.Phase=="Selecting"then seconds=math.max(0,math.ceil(((state.EndTick or 0)-(state.Tick or 0))/10))end
  local time=if seconds>=3600 then string.format("%d:%02d:%02d",math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60)else string.format("%02d:%02d",math.floor(seconds/60),seconds%60)
  local values={time,if rank and rank~="?"then "#"..tostring(rank)else "—",string.format("%.2f%%",math.clamp((count or 0)/math.max(1,land or 1)*100,0,100))}
  local changed=false;for i,value in ipairs(values)do if labels[i].Text~=value then labels[i].Text=value;changed=true end end
  if changed then api.resize()end
 end
 parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(api.resize);api.resize()
 return api
end
return Status
