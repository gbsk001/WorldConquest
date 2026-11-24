--!strict
-- Original WorldConquest presentation. Gameplay remains in the existing adapters.
local TweenService=game:GetService("TweenService")
local Art=require(script.Parent.InterfaceArt)
local Chrome=require(script.Parent.PanelChrome)
local Ranking=require(game:GetService("ReplicatedStorage").Shared.TerritoryRanking)
local UI={}
local navy=Color3.fromRGB(15,23,35)
local raised=Color3.fromRGB(27,39,55)
local blue=Color3.fromRGB(104,174,244)
local Money=require(game:GetService("ReplicatedStorage").Shared.OpenFront.MoneyFormat)
function UI.surface(object)
 object.BackgroundColor3=navy;object.BackgroundTransparency=0.14;object.BorderSizePixel=0
 local corner=object:FindFirstChildOfClass("UICorner") or Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=object
 local stroke=object:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke");stroke.Color=Color3.fromRGB(68,86,109);stroke.Transparency=0.72;stroke.Parent=object
end
function UI.button(button)
 UI.surface(button);button.BackgroundColor3=raised;button.Font=Enum.Font.GothamMedium;button.TextSize=13;button.TextColor3=Color3.fromRGB(229,236,245);button.TextWrapped=true
 if string.find(button.Text,"Demolish",1,true) then button.TextColor3=Color3.fromRGB(238,142,145) end
end
function UI.new(root,viewport,title,phase,profile,status,help,resources,view,leaveMatch)
 local api={};local reduced=false;local opened=nil
 local function frame(name,parent)
  local f=Instance.new("Frame");f.Name=name;f.Parent=parent;f.ZIndex=40;UI.surface(f);return f
 end
 local bar=frame("CommandBar",root);bar.Position=UDim2.fromOffset(10,50);bar.Size=UDim2.new(1,-20,0,98)
 title.Parent=bar;title.Position=UDim2.fromOffset(12,6);title.Size=UDim2.new(.62,-24,0,16);title.TextSize=11;title.TextScaled=false;title.TextColor3=Color3.fromRGB(146,164,187)
 phase.Parent=bar;phase.Position=UDim2.new(.62,0,0,6);phase.Size=UDim2.new(.38,-12,0,22);phase.TextSize=15;phase.TextScaled=false
 resources.Parent=bar;resources.Position=UDim2.fromOffset(12,48);resources.Size=UDim2.new(1,-24,0,42);resources.TextScaled=true;resources.TextWrapped=true;resources.TextColor3=Color3.fromRGB(225,199,137)
 profile.Parent=bar;profile.Visible=false;resources.Visible=false
 local stats={};local statIcons={}
 for i,name in ipairs({"SOLDIERS","RECRUIT / S","GOLD","INCOME / S","TERRITORY","RANK"}) do
  local cell=Instance.new("TextLabel");cell.Name=name;cell.BackgroundTransparency=1;cell.Font=Enum.Font.GothamMedium;cell.TextSize=13;cell.Text="-";cell.TextWrapped=true;cell.TextXAlignment=Enum.TextXAlignment.Left;cell.TextColor3=if i==3 or i==4 then Color3.fromRGB(225,199,137) elseif i==2 then Color3.fromRGB(130,204,168) else Color3.fromRGB(224,233,246);cell.ZIndex=41;cell.Parent=bar;stats[i]=cell
  local icon=Art.icon(bar,({"Soldiers","Recruitment","Gold","Income","Territory","Rank"})[i],16,cell.TextColor3);statIcons[i]=icon
  local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,24);pad.Parent=cell
 end
 function api.stats(p,state)
  local rank="—"
  for i,row in ipairs(Ranking.sorted(state.Players or state.Rankings or {})) do if row.UserId==p.UserId then rank=tostring(i);break end end
  local values={Money.money(p.Troops or 0),Money.money(math.floor(p.Growth or 0)*10),"$"..Money.money(p.Gold or "0"),"$"..Money.money(if not p.GoldIncome or p.GoldIncome=="0" then "0" else p.GoldIncome.."0"),Money.money(p.Count or 0),rank}
  for i,cell in ipairs(stats) do local heading=if root.AbsoluteSize.Y<500 then ({"TROOPS","RECRUIT","GOLD","INCOME","LAND","RANK"})[i]else cell.Name;local text=heading.."\n"..values[i];if cell.Text~=text then cell.Text=text end end
 end
 local function resize()
  local short=root.AbsoluteSize.Y<500
  local narrow=root.AbsoluteSize.X<(if short then 520 else 620);local columns=if narrow then 3 else 6;local height=if narrow then (if short then 100 else 124)elseif short then 64 else 80
  title.Visible=not short;phase.Position=if short then UDim2.fromOffset(8,2)else UDim2.new(.62,0,0,6);phase.Size=if short then UDim2.new(1,-16,0,20)else UDim2.new(.38,-12,0,22);phase.TextSize=if short then 12 else 15
  bar.Position=UDim2.fromOffset(10,if short then 44 else 50)
  bar.Size=UDim2.new(1,-20,0,height)
  viewport.Position=UDim2.fromOffset(0,height+(if short then 48 else 58));viewport.Size=UDim2.new(1,0,1,-height-(if short then 132 else 170))
  status.Position=UDim2.new(0,18,1,if short then -84 else -108);status.Size=UDim2.new(1,-36,0,if short then 22 else 38)
  for i,cell in ipairs(stats) do
   local row=math.floor((i-1)/columns)*(if short then 34 else 44)
   statIcons[i].Position=UDim2.new(((i-1)%columns)/columns,12,0,(if short then 30 else 36)+row)
   cell.Position=UDim2.new(((i-1)%columns)/columns,12,0,(if short then 24 else 30)+row);cell.Size=UDim2.new(1/columns,-16,0,if short then 34 else 42);cell.TextSize=if short then 11 else 13
  end
 end
 viewport.Position=UDim2.fromOffset(0,114);viewport.Size=UDim2.new(1,0,1,-226)
 root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize()
 status.TextWrapped=true;status.TextScaled=true;status.TextColor3=blue
 help.Visible=false
 local dock=frame("CommandToolbar",root);dock.Position=UDim2.new(0,10,1,-66);dock.Size=UDim2.new(1,-20,0,56)
 local layout=Instance.new("UIListLayout");layout.FillDirection=Enum.FillDirection.Horizontal;layout.Padding=UDim.new(0,4);layout.HorizontalAlignment=Enum.HorizontalAlignment.Center;layout.VerticalAlignment=Enum.VerticalAlignment.Center;layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=dock
 local buttons={};local panels={};local cancel={}
 local function closeOthers(except)
  local info=viewport:FindFirstChild("BuildingInfo");if info and info~=except then info.Visible=false end
  for _,p in ipairs(panels) do if p~=except then p.Visible=false end end
  for p,fn in pairs(cancel) do if p~=except then fn() end end
 end
 function api.mount(button,panel,order,onCancel)
  button.Parent=dock;button.AnchorPoint=Vector2.zero;button.LayoutOrder=order;button.Size=UDim2.new(1/6,-6,0,44);button.Position=UDim2.new();button.ZIndex=42;UI.button(button);table.insert(buttons,button)
  local icon=Art.icon(button,({"Army","Buildings","Navy","Missiles","Leaderboard","Settings"})[order] or "Settings",18,blue);icon.Position=UDim2.new(.5,-9,0,4)
  button.TextSize=11;button.TextYAlignment=Enum.TextYAlignment.Bottom;local pad=Instance.new("UIPadding");pad.PaddingBottom=UDim.new(0,3);pad.Parent=button
  panel.Parent=viewport;panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-10,0,8);panel.Size=UDim2.new(1,-20,1,-16);panel.ZIndex=45;panel.Active=true;UI.surface(panel)
  local limit=panel:FindFirstChildOfClass("UISizeConstraint") or Instance.new("UISizeConstraint");limit.MaxSize=if panel.Name=="MatchResults"then Vector2.new(290,500)else Vector2.new(340,520);limit.Parent=panel
  for _,child in ipairs(panel:GetDescendants()) do
   if child:IsA("GuiObject") then child.ZIndex=46 end
   if child:IsA("TextButton") then UI.button(child) end
  end
  table.insert(panels,panel);if onCancel then cancel[panel]=onCancel end
  Chrome.close(panel,onCancel)
  panel:GetPropertyChangedSignal("Visible"):Connect(function()
   if panel.Visible then
    closeOthers(panel);opened=panel;button.BackgroundColor3=Color3.fromRGB(42,68,94)
    if not reduced then panel.Position=UDim2.new(1,6,0,8);TweenService:Create(panel,TweenInfo.new(0.16,Enum.EasingStyle.Quad),{Position=UDim2.new(1,-10,0,8)}):Play() end
   else button.BackgroundColor3=raised;if opened==panel then opened=nil end end
  end)
 end
 local function localPanel(name,order)
  local panel=Instance.new("ScrollingFrame");panel.Name=name;panel.Visible=false;panel.CanvasSize=UDim2.fromOffset(0,310);panel.ScrollBarThickness=4;panel.ScrollingDirection=Enum.ScrollingDirection.Y
  local button=Instance.new("TextButton");button.Text=name
  button.Activated:Connect(function()panel.Visible=not panel.Visible end)
  api.mount(button,panel,order);return panel
 end
 api.Army=localPanel("Army",1)
 local settings=localPanel("Settings",6)
 local function setting(text,y,callback)
  local b=Instance.new("TextButton");b.Size=UDim2.new(1,-24,0,44);b.Position=UDim2.fromOffset(12,y);b.Text=text;b.ZIndex=46;b.Parent=settings;UI.button(b);b.Activated:Connect(function()callback(b)end)
 end
 setting("Fit Earth to screen",12,function()view.reset()end)
 setting("Zoom in",64,function()view.zoomBy(1.5)end)
 setting("Zoom out",116,function()view.zoomBy(1/1.5)end)
 setting("Motion: subtle",168,function(b)reduced=not reduced;b.Text=if reduced then "Motion: reduced" else "Motion: subtle" end)
 setting("Communication & microphone",220,function()api.close();require(script.Parent.CommunicationClient).open()end)
 setting("Source & licences",272,function()api.close();require(script.Parent.SourceOffer).open()end)
 local note=Instance.new("TextLabel");note.BackgroundTransparency=1;note.Position=UDim2.fromOffset(12,224);note.Size=UDim2.new(1,-24,0,140);note.Text="Drag Earth to pan. Pinch, use the wheel or zoom controls.\nSettings apply to this client session.\n\nUnofficial OpenFront adaptation\n© OpenFront and Contributors\nAGPL source offer required before publication.";note.TextWrapped=true;note.Font=Enum.Font.Gotham;note.TextSize=13;note.TextColor3=blue;note.ZIndex=46;note.Parent=settings;settings.CanvasSize=UDim2.fromOffset(0,380)
 local notification=frame("Notification",root);notification.Position=UDim2.new(0.5,0,1,-112);notification.AnchorPoint=Vector2.new(0.5,1);notification.Size=UDim2.new(1,-36,0,64);notification.Visible=false
 local message=Instance.new("TextLabel");message.Size=UDim2.new(1,-24,1,-12);message.Position=UDim2.fromOffset(12,6);message.BackgroundTransparency=1;message.TextWrapped=true;message.Font=Enum.Font.GothamMedium;message.TextSize=14;message.TextColor3=Color3.fromRGB(230,237,245);message.ZIndex=41;message.Parent=notification
 local dismissed=false
 local news=Instance.new("TextButton");news.Name="NotificationsToggle";news.Text="Notifications";news.Size=UDim2.fromOffset(118,34);news.Position=UDim2.new(1,-128,0,8);news.ZIndex=45;news.Parent=root;UI.button(news)
 news.Activated:Connect(function()dismissed=false;notification.Visible=not notification.Visible end)
 Chrome.close(notification,function()dismissed=true end)
 local confirmation=frame("LeaveConfirmation",root);confirmation.Size=UDim2.fromScale(1,1);confirmation.Position=UDim2.fromOffset(0,0);confirmation.ZIndex=70;confirmation.Active=true;confirmation.Visible=false
 local warning=Instance.new("TextLabel");warning.BackgroundTransparency=1;warning.Text="Leave this match?\nYour current match progress will be abandoned.";warning.TextWrapped=true;warning.TextColor3=Color3.fromRGB(235,241,250);warning.Font=Enum.Font.GothamMedium;warning.TextSize=16;warning.Position=UDim2.new(.1,0,.5,-80);warning.Size=UDim2.new(.8,0,0,65);warning.ZIndex=71;warning.Parent=confirmation
 local function confirmButton(text,x,fn)
  local b=Instance.new("TextButton");b.Text=text;b.Position=UDim2.new(x,0,.5,0);b.Size=UDim2.new(.4,-8,0,44);b.ZIndex=71;b.Parent=confirmation;UI.button(b);b.Activated:Connect(fn);return b
 end
 confirmButton("Stay",.1,function()confirmation.Visible=false end)
 confirmButton("Leave Match",.5,function()confirmation.Visible=false;api.close();if leaveMatch then leaveMatch()end end)
 local leave=Instance.new("TextButton");leave.Name="LeaveGame";leave.Text="Leave Game";leave.Position=UDim2.fromOffset(10,8);leave.Size=UDim2.fromOffset(142,34);leave.ZIndex=45;leave.Parent=root;UI.button(leave)
 local exitIcon=Art.icon(leave,"Exit",18,Color3.fromRGB(229,181,168));exitIcon.Position=UDim2.fromOffset(8,8)
 local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,25);pad.Parent=leave
 leave.Activated:Connect(function()api.close();confirmation.Visible=true end)
 Chrome.close(confirmation)
 local serial=0
 note.Position=UDim2.fromOffset(12,336);settings.CanvasSize=UDim2.fromOffset(0,496)
 function api.notify(text)
  serial+=1;local id=serial;message.Text=text;if not dismissed then notification.Visible=true end
  task.delay(4,function()if serial==id then notification.Visible=false end end)
 end
 function api.close()closeOthers(nil);confirmation.Visible=false;notification.Visible=false end
 local escape=game:GetService("UserInputService").InputBegan:Connect(function(input,processed)if input.KeyCode==Enum.KeyCode.Escape then api.close() end end)
 root.Destroying:Connect(function()escape:Disconnect()end)
 return api
end
return UI
