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
 viewport.Position=UDim2.fromOffset(0,0);viewport.Size=UDim2.fromScale(1,1)
 local function frame(name,parent)
  local f=Instance.new("Frame");f.Name=name;f.Parent=parent;f.ZIndex=40;UI.surface(f);return f
 end
 local gold=Color3.fromRGB(241,190,91)
 local function text(parent,name,value,pos,size,fontSize)
  local t=Instance.new("TextLabel");t.Name=name;t.Text=value;t.Position=pos;t.Size=size;t.BackgroundTransparency=1;t.TextColor3=Color3.fromRGB(241,245,252);t.Font=Enum.Font.GothamBold;t.TextSize=fontSize or 15;t.TextWrapped=true;t.ZIndex=41;t.Parent=parent;return t
 end
 -- The map occupies a separate full-screen branch. Only these floating surfaces receive input.
 title.Visible=false;profile.Visible=false;resources.Visible=false;help.Visible=false
 local bar=frame("CommandBar",root);bar.Visible=false;bar.AnchorPoint=Vector2.new(.5,1);bar.Active=true
 local stats={};local statIcons={}
 for i,name in ipairs({"SOLDIERS","RECRUIT / S","GOLD","INCOME / S","TERRITORY","RANK"})do
  local t=text(bar,name,"?",UDim2.new(),UDim2.new(),16);stats[i]=t
  if i<=3 then local icon=Art.icon(bar,({"Soldiers","Recruitment","Gold"})[i],18,if i==3 then gold else Color3.fromRGB(188,211,230));statIcons[i]=icon end
 end
 stats[4].Visible=false;stats[5].Visible=false;stats[6].Visible=false
 local capTrack=Instance.new("Frame");capTrack.Name="TroopCapacity";capTrack.BorderSizePixel=0;capTrack.BackgroundColor3=Color3.fromRGB(47,60,79);capTrack.Position=UDim2.fromOffset(14,47);capTrack.Size=UDim2.fromOffset(300,3);capTrack.Parent=bar
 local cap=Instance.new("Frame");cap.BorderSizePixel=0;cap.BackgroundColor3=gold;cap.Size=UDim2.fromScale(0,1);cap.Parent=capTrack
 local sending=text(bar,"Sending","SENDS ?",UDim2.new(),UDim2.new(),12)
 local allocation=.2;local latest=nil;local currentPhase=nil;local allocationChanged=nil
 local quick={};local buildControl=nil;local constructionPanel=nil
 function api.setAllocation(value)
  allocation=math.clamp(value,.01,1)
  for _,entry in ipairs(quick)do entry.Button.BackgroundColor3=if math.abs(entry.Value-allocation)<.001 then gold else raised;entry.Button.TextColor3=if math.abs(entry.Value-allocation)<.001 then navy else Color3.fromRGB(225,233,245)end
  sending.Text="SENDS "..Money.money(math.floor((latest and latest.Troops or 0)*allocation))
 end
 function api.bindAllocation(fn)allocationChanged=fn end
 for i,value in ipairs({.10,.25,.35,.50,.75})do
  local b=Instance.new("TextButton");b.Name="Allocation"..math.round(value*100);b.Text=tostring(math.round(value*100)).."%";b.ZIndex=42;b.Parent=bar;UI.button(b)
  table.insert(quick,{Button=b,Value=value});b.Activated:Connect(function()api.setAllocation(value);if allocationChanged then allocationChanged(value)end end)
 end
 local summary=frame("MatchSummary",root);summary.AnchorPoint=Vector2.new(1,0);summary.Position=UDim2.new(1,-8,0,8);summary.Size=UDim2.fromOffset(248,44)
 phase.Parent=summary;phase.Position=UDim2.fromOffset(10,2);phase.Size=UDim2.fromOffset(100,40);phase.TextScaled=false;phase.TextSize=13;phase.Font=Enum.Font.GothamBold
 local rankText=text(summary,"RankTerritory","?",UDim2.fromOffset(110,2),UDim2.new(1,-120,1,-4),13)
 local spawn=frame("SpawnSelection",root);spawn.Visible=false;spawn.Active=true;spawn.AnchorPoint=Vector2.new(.5,0);spawn.Position=UDim2.new(.5,0,0,66);spawn.Size=UDim2.new(1,-20,0,142)
 local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(620,142);limit.Parent=spawn
 local heading=text(spawn,"SpawnHeading","CHOOSE YOUR STARTING LOCATION",UDim2.fromOffset(14,10),UDim2.new(1,-86,0,24),17);heading.TextXAlignment=Enum.TextXAlignment.Left
 local hint=text(spawn,"SpawnHint","Tap available land to place your capital.",UDim2.fromOffset(14,39),UDim2.new(1,-86,0,22),12);hint.TextXAlignment=Enum.TextXAlignment.Left
 local placed=text(spawn,"SpawnCount","Waiting for selections",UDim2.fromOffset(14,65),UDim2.new(1,-86,0,22),12);placed.TextXAlignment=Enum.TextXAlignment.Left
 local circle=frame("Countdown",spawn);circle.AnchorPoint=Vector2.new(1,0);circle.Position=UDim2.new(1,-12,0,12);circle.Size=UDim2.fromOffset(56,56);circle:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(1,0)
 local seconds=text(circle,"Seconds","20",UDim2.fromScale(0,0),UDim2.fromScale(1,1),24)
 local segments={};for i=1,20 do local dot=Instance.new("Frame");local angle=(i-1)/20*math.pi*2-math.pi/2;dot.AnchorPoint=Vector2.new(.5,.5);dot.Size=UDim2.fromOffset(4,6);dot.Position=UDim2.new(.5,math.cos(angle)*29,.5,math.sin(angle)*29);dot.Rotation=(i-1)*18;dot.BorderSizePixel=0;dot.BackgroundColor3=gold;dot.Parent=circle;segments[i]=dot end
 local nation=Instance.new("TextBox");nation.Name="NationNameInput";nation.Position=UDim2.fromOffset(14,94);nation.Size=UDim2.new(1,-160,0,44);nation.Text="";nation.PlaceholderText="Nation name (optional)";nation.ClearTextOnFocus=false;nation.Font=Enum.Font.GothamBold;nation.TextSize=14;nation.TextColor3=Color3.new(1,1,1);nation.AutoLocalize=false;nation.RichText=false;nation.ZIndex=42;UI.surface(nation);nation.Parent=spawn
 local save=Instance.new("TextButton");save.Name="SaveNationName";save.Text="Save name";save.Position=UDim2.new(1,-138,0,94);save.Size=UDim2.fromOffset(124,44);save.ZIndex=42;UI.button(save);save.Parent=spawn
 local saveName=nil;save.Activated:Connect(function()if saveName then saveName(nation.Text)end end)
 function api.bindNation(fn)saveName=fn end
 function api.nation(value)if value then nation.Text=value end end
 local dock=Instance.new("Frame");dock.Name="CommandToolbar";dock.BackgroundTransparency=1;dock.Size=UDim2.fromOffset(304,48);dock.Position=UDim2.fromOffset(8,8);dock.ZIndex=40;dock.Parent=root
 local layout=Instance.new("UIListLayout");layout.FillDirection=Enum.FillDirection.Horizontal;layout.Padding=UDim.new(0,5);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=dock
 local function resize()
  local narrow=root.AbsoluteSize.X<700;local short=root.AbsoluteSize.Y<500
  bar.Position=UDim2.new(.5,0,1,-8);bar.Size=UDim2.fromOffset(math.min(900,root.AbsoluteSize.X-16),if narrow then 124 else 78)
  local width=math.min(900,root.AbsoluteSize.X-16)
  local compact=not narrow and width<800
  for i=1,3 do local x=(i-1)*(if narrow then math.max(64,(width-86)/3)elseif compact then 86 else 112)+12;statIcons[i].Position=UDim2.fromOffset(x,14);stats[i].Position=UDim2.fromOffset(x+24,7);stats[i].Size=UDim2.fromOffset(if narrow then math.max(40,(width-86)/3-24)elseif compact then 62 else 84,34);stats[i].TextSize=if narrow or compact then 12 else 17 end
  capTrack.Size=UDim2.fromOffset(math.min(300,width-104),3)
  for i,entry in ipairs(quick)do entry.Button.Position=UDim2.fromOffset((if narrow then 10 elseif compact then 270 else 348)+(i-1)*46,if narrow then 60 else 16);entry.Button.Size=UDim2.fromOffset(44,44)end
  if buildControl then buildControl.AnchorPoint=Vector2.new(1,0);buildControl.Position=UDim2.new(1,-8,0,8);buildControl.Size=UDim2.fromOffset(if narrow then 62 else 70,if narrow then 44 else 56)end
  sending.Position=UDim2.fromOffset(if narrow then 244 elseif compact then 512 else 590,if narrow then 61 else 12);sending.Size=UDim2.fromOffset(math.max(44,width-(if narrow then 330 elseif compact then 612 else 690)),44)
  if constructionPanel then constructionPanel.Position=UDim2.new(.5,0,1,if narrow then -140 else -94);constructionPanel.Size=UDim2.new(1,-20,0,if short then 134 else 164)end
  summary.Position=UDim2.new(1,-8,0,if root.AbsoluteSize.X<740 then 62 else 8)
  spawn.Position=UDim2.new(.5,0,0,if root.AbsoluteSize.X<740 then 112 else 66)
  heading.TextSize=if narrow or compact then 12 else 17
  status.Position=UDim2.new(.5,0,1,if narrow then -140 else -90);status.AnchorPoint=Vector2.new(.5,1);status.Size=UDim2.new(1,-32,0,22);status.TextSize=12;status.ZIndex=65
 end
 root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);resize()
 status.TextWrapped=true;status.TextScaled=false;status.TextStrokeTransparency=.3;status.TextStrokeColor3=navy;status.TextColor3=Color3.fromRGB(238,241,250)
 local lastPhase=nil
 function api.stats(p,state)
  latest=p;currentPhase=state.Phase
  local rank="?";for i,row in ipairs(Ranking.sorted(state.Players or state.Rankings or {}))do if row.UserId==p.UserId then rank=tostring(i);break end end
  stats[1].Text=Money.money(p.Troops or 0);stats[2].Text="+"..Money.money(math.floor(p.Growth or 0)*10).."/s";stats[2].TextColor3=Color3.fromRGB(112,221,164);stats[3].Text=Money.money(p.Gold or "0");stats[3].TextColor3=gold
  cap.Size=UDim2.fromScale(math.clamp((p.Troops or 0)/math.max(1,p.Cap or 1),0,1),1)
  local mapLand=11014740
  rankText.Text="#"..rank.."  ?  "..string.format("%.2f%%",(p.Count or 0)/mapLand*100)
  bar.Visible=state.Phase=="Started"and not p.Spectator and not p.Eliminated
  spawn.Visible=state.Phase=="Selecting"
  local remaining=math.max(0,math.ceil(((state.EndTick or 0)-(state.Tick or 0))/10));seconds.Text=tostring(remaining)
  for i,dot in ipairs(segments)do dot.BackgroundTransparency=if i<=remaining then 0 else .82 end
  placed.Text=tostring(state.SelectedSpawns or 0).." / "..tostring(state.Participants or #(state.Players or {})).." selected"..(if p.Spawn then " ? Location confirmed"else "")
  if lastPhase~=state.Phase then
   if state.Phase=="Selecting"then view.reset()elseif state.Phase=="Started"and p.Spawn and view.focus then view.focus(p.LabelX or p.X,p.LabelY or p.Y)end
   lastPhase=state.Phase
  end
  api.setAllocation(allocation)
  if api.phase then api.phase(state.Phase)end
 end
 local buttons={};local panels={};local cancel={}
 local function closeOthers(except)
  local info=viewport:FindFirstChild("BuildingInfo");if info and info~=except then info.Visible=false end
  for _,p in ipairs(panels) do if p~=except then p.Visible=false end end
  for p,fn in pairs(cancel) do if p~=except then fn() end end
 end
 function api.mount(button,panel,order,onCancel)
  button.Parent=dock;button.Visible=order>=5;button.AnchorPoint=Vector2.zero;button.LayoutOrder=order;button.Size=UDim2.fromOffset(44,44);button.Position=UDim2.new();button.ZIndex=42;UI.button(button);buttons[order]=button
  local icon=Art.icon(button,({"Army","Buildings","Navy","Missiles","Leaderboard","Settings"})[order] or "Settings",18,blue);icon.Position=UDim2.new(.5,-9,0,4)
  button.TextSize=8;button.TextYAlignment=Enum.TextYAlignment.Bottom;local pad=Instance.new("UIPadding");pad.PaddingBottom=UDim.new(0,3);pad.Parent=button
  if order==2 then buildControl=button;button.Parent=bar;button.AnchorPoint=Vector2.new(1,.5);button.Position=UDim2.new(1,-10,.5,0);button.Size=UDim2.fromOffset(70,56);button.Text="BUILD";button.TextSize=12;button.BackgroundColor3=Color3.fromRGB(81,65,39);resize()end
  panel.Parent=root;panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-10,0,64);panel.Size=UDim2.new(1,-20,1,-160);panel.ZIndex=45;panel.Active=true;UI.surface(panel)
  local limit=panel:FindFirstChildOfClass("UISizeConstraint") or Instance.new("UISizeConstraint");limit.MaxSize=if panel.Name=="MatchResults"then Vector2.new(290,500)else Vector2.new(340,520);limit.Parent=panel
  for _,child in ipairs(panel:GetDescendants()) do
   if child:IsA("GuiObject") then child.ZIndex=46 end
   if child:IsA("TextButton") then UI.button(child) end
  end
  if panel.Name=="BuildingShop"then constructionPanel=panel;panel.AnchorPoint=Vector2.new(.5,1);panel.Position=UDim2.new(.5,0,1,-144);panel.Size=UDim2.new(1,-20,0,164);limit.MaxSize=Vector2.new(1400,164);resize()end
  table.insert(panels,panel);if onCancel then cancel[panel]=onCancel end
  Chrome.close(panel,onCancel)
  panel:GetPropertyChangedSignal("Visible"):Connect(function()
   if panel.Visible then
    closeOthers(panel);opened=panel;button.BackgroundColor3=Color3.fromRGB(42,68,94)
    if not reduced and panel.Name~="BuildingShop" then panel.Position=UDim2.new(1,6,0,64);TweenService:Create(panel,TweenInfo.new(0.16,Enum.EasingStyle.Quad),{Position=UDim2.new(1,-10,0,64)}):Play() end
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
 local notification=frame("Notification",root);notification.Position=UDim2.new(0.5,0,1,-112);notification.AnchorPoint=Vector2.new(0.5,1);notification.Size=UDim2.new(1,-36,0,64);notification.ZIndex=100;notification.Visible=false
 local message=Instance.new("TextLabel");message.Size=UDim2.new(1,-24,1,-12);message.Position=UDim2.fromOffset(12,6);message.BackgroundTransparency=1;message.TextWrapped=true;message.Font=Enum.Font.GothamMedium;message.TextSize=14;message.TextColor3=Color3.fromRGB(230,237,245);message.ZIndex=41;message.Parent=notification
 local dismissed=false
 local news=Instance.new("TextButton");news.Name="NotificationsToggle";news.Text="Notifications";news.Size=UDim2.fromOffset(118,34);news.Position=UDim2.fromOffset(8,62);news.ZIndex=45;news.Parent=settings;news.Position=UDim2.fromOffset(12,548);news.Size=UDim2.new(1,-24,0,44);UI.button(news)
 news.Activated:Connect(function()dismissed=false;notification.Visible=not notification.Visible end)
 Chrome.close(notification,function()dismissed=true end)
 local confirmation=frame("LeaveConfirmation",root);confirmation.Size=UDim2.fromScale(1,1);confirmation.Position=UDim2.fromOffset(0,0);confirmation.ZIndex=70;confirmation.Active=true;confirmation.Visible=false
 local warning=Instance.new("TextLabel");warning.BackgroundTransparency=1;warning.Text="Leave this match?\nYour current match progress will be abandoned.";warning.TextWrapped=true;warning.TextColor3=Color3.fromRGB(235,241,250);warning.Font=Enum.Font.GothamMedium;warning.TextSize=16;warning.Position=UDim2.new(.1,0,.5,-80);warning.Size=UDim2.new(.8,0,0,65);warning.ZIndex=71;warning.Parent=confirmation
 local function confirmButton(text,x,fn)
  local b=Instance.new("TextButton");b.Text=text;b.Position=UDim2.new(x,0,.5,0);b.Size=UDim2.new(.4,-8,0,44);b.ZIndex=71;b.Parent=confirmation;UI.button(b);b.Activated:Connect(fn);return b
 end
 confirmButton("Stay",.1,function()confirmation.Visible=false end)
 confirmButton("Leave Match",.5,function()confirmation.Visible=false;api.close();if leaveMatch then leaveMatch()end end)
 local leave=Instance.new("TextButton");leave.Name="LeaveGame";leave.Text="Leave Game";leave.TextSize=8;leave.Position=UDim2.fromOffset(264,8);leave.Size=UDim2.fromOffset(44,44);leave.ZIndex=45;leave.Parent=root;UI.button(leave);leave.TextSize=8;leave.TextYAlignment=Enum.TextYAlignment.Bottom
 local exitIcon=Art.icon(leave,"Exit",18,Color3.fromRGB(229,181,168));exitIcon.Position=UDim2.fromOffset(8,8)
 local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,25);pad.Parent=leave
 leave.Activated:Connect(function()api.close();confirmation.Visible=true end)
 Chrome.close(confirmation)
 function api.phase(value)
  for order,b in pairs(buttons)do b.Visible=order>=5 or value=="Started"end
  if value=="Selecting"then for _,p in ipairs(panels)do p.Visible=false end end
 end
 local helpButton=Instance.new("TextButton");helpButton.Name="Help";helpButton.Text="";helpButton.Size=UDim2.fromOffset(44,44);helpButton.Position=UDim2.fromOffset(8,62);helpButton.ZIndex=42;helpButton.Parent=root;UI.button(helpButton)
 local helpArt=Art.icon(helpButton,"Tutorial",22,blue);helpArt.Position=UDim2.fromOffset(11,11)
 helpButton.Activated:Connect(function()api.notify("Tap land to expand or attack. Drag to pan; pinch to zoom. Army offers exact allocation and recall. BUILD opens construction; Navy and Missiles select targets.")end)
 local serial=0
 note.Position=UDim2.fromOffset(12,336);settings.CanvasSize=UDim2.fromOffset(0,608)
 setting("Tutorial / help",496,function()api.notify("Tap land to expand. Drag to pan; pinch to zoom. BUILD opens construction. Army offers precise allocation and recall. Navy launches ships; Missiles selects targets.")end)
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
