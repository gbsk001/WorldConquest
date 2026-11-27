--!strict
-- Original WorldConquest menu; platform friends/invites, no synthetic game modes.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Social=game:GetService("SocialService")
local Config=require(RS.Shared.Config)
local Theme=require(script.Parent.StrategyUI)
local Art=require(script.Parent.InterfaceArt)
local TweenService=game:GetService("TweenService")
local GuiService=game:GetService("GuiService")
local Menu={};local activeRequest=nil
function Menu.request(action,data)if activeRequest then activeRequest(action,data)end end
function Menu.new(showGame)
 local player=Players.LocalPlayer;local remote=RS:WaitForChild("WorldConquestLobby")
 local gui=Instance.new("ScreenGui");gui.Name="WorldConquestMenu";gui.ResetOnSpawn=false;gui.DisplayOrder=30;gui.ScreenInsets=Enum.ScreenInsets.None;gui.ClipToDeviceSafeArea=false;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=player.PlayerGui
 local shade=Instance.new("Frame");shade.Size=UDim2.fromScale(1,1);shade.BackgroundColor3=Color3.fromRGB(9,14,23);shade.BackgroundTransparency=0;shade.BorderSizePixel=0;shade.Active=false;shade.Name="MenuBackground";shade.ZIndex=0;shade.Parent=gui
 -- Decorative map must never block menu controls or depend on image permission.
 local schedule=task.defer or task.spawn
 schedule(function()pcall(function()local map=require(RS.Shared.Map);if shade.Parent then Art.world(shade,map)end end)end)
 local overlay=Instance.new("Frame");overlay.Size=UDim2.fromScale(1,1);overlay.BackgroundColor3=Color3.fromRGB(5,10,20);overlay.BackgroundTransparency=.38;overlay.BorderSizePixel=0;overlay.Name="BackgroundShade";overlay.ZIndex=2;overlay.Active=false;overlay.Parent=shade
 local panel=Instance.new("Frame");panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.BackgroundTransparency=1;panel.ZIndex=10;panel.Parent=gui;panel.Name="MenuComposition"
 local scale=Instance.new("UIScale");scale.Parent=panel
 local title=Instance.new("TextLabel");title.Position=UDim2.fromOffset(20,12);title.Size=UDim2.new(1,-40,0,80);title.BackgroundTransparency=1;title.Font=Enum.Font.GothamBold;title.TextSize=64;title.TextColor3=Color3.fromRGB(235,241,250);title.TextXAlignment=Enum.TextXAlignment.Left;title.Text="WORLD CONQUEST";title.Parent=panel
 local subtitle=Instance.new("TextLabel");subtitle.Position=UDim2.fromOffset(22,94);subtitle.Size=UDim2.new(1,-40,0,36);subtitle.BackgroundTransparency=1;subtitle.Font=Enum.Font.Gotham;subtitle.TextSize=12;subtitle.TextXAlignment=Enum.TextXAlignment.Left;subtitle.TextWrapped=true;subtitle.TextColor3=Color3.fromRGB(180,194,215);subtitle.Text="Earth is yours to contest.\nUnofficial adaptation · © OpenFront and Contributors";subtitle.Parent=panel
 local content=Instance.new("ScrollingFrame");content.Position=UDim2.fromOffset(20,150);content.Size=UDim2.new(1,-40,1,-220);content.BackgroundTransparency=1;content.BorderSizePixel=0;content.ScrollBarThickness=4;content.AutomaticCanvasSize=Enum.AutomaticSize.Y;content.CanvasSize=UDim2.new();content.ZIndex=20;content.Parent=panel
 local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,10);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=content
 local message=Instance.new("TextLabel");message.Position=UDim2.new(0,20,1,-66);message.Size=UDim2.new(1,-40,0,54);message.BackgroundTransparency=1;message.Font=Enum.Font.Gotham;message.TextSize=13;message.TextWrapped=true;message.TextColor3=Color3.fromRGB(139,195,244);message.ZIndex=70;message.Parent=panel
 local state={Screen="Menu"};local page="Home";local sequence=0;local revision=0;local renderKey="";local countdown=nil;local tutorial=1;local received=false
 local render;local premium=nil
 local matchmaking=false;local playButton=nil;local busySerial=0
 local function resize()
  local value=player:GetAttribute("MenuScale") or 1;scale.Scale=value
  local inset,endInset=GuiService:GetGuiInset();endInset=endInset or Vector2.zero
  pcall(function()local full=GuiService:GetInsetArea(Enum.ScreenInsets.None);local safe=GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets);inset=safe.Min-full.Min;endInset=full.Max-safe.Max end)
  local h=gui.AbsoluteSize.Y-inset.Y-endInset.Y-24
  panel.Position=UDim2.new(.5,(inset.X-endInset.X)/2,0,inset.Y+12);panel.AnchorPoint=Vector2.new(.5,0)
  panel.Size=UDim2.fromOffset(math.max(240,math.min(1180,gui.AbsoluteSize.X-inset.X-endInset.X-32))/value,math.max(240,h)/value)
  local short=gui.AbsoluteSize.Y<500
  title.TextSize=if short then 30 elseif gui.AbsoluteSize.X<700 then 34 else 64
  title.Size=UDim2.new(1,-70,0,if short then 40 else 80)
  subtitle.Position=UDim2.fromOffset(22,if short then 52 else 94);subtitle.Size=UDim2.new(1,-40,0,if short then 24 else 36)
  content.Position=UDim2.fromOffset(20,if short then 82 else 150);content.Size=UDim2.new(1,-40,1,if short then -128 else -220)
  message.Position=UDim2.new(0,20,1,if short then -42 else -66);message.Size=UDim2.new(1,-40,0,if short then 22 else 54);message.TextSize=if short then 10 else 13
  if render then render() end
 end
 gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize);player:GetAttributeChangedSignal("MenuScale"):Connect(resize);resize()
 local function send(action,data)
  if action=="Public"then
   if matchmaking then return end
   matchmaking=true;busySerial+=1;local ticket=busySerial
   if playButton then playButton.Text="FINDING MATCH..."end
   message.Text="Finding your public match..."
   task.delay(25,function()if matchmaking and busySerial==ticket then matchmaking=false;if playButton then playButton.Text="PLAY"end;message.Text="Matchmaking is taking longer than expected. You can retry."end end)
  end
  sequence+=1;remote:FireServer(action,sequence,data)
 end;activeRequest=send
 local function clear()
  revision+=1;countdown=nil
  for _,child in ipairs(content:GetChildren())do if child~=layout then child:Destroy()end end
  content.CanvasPosition=Vector2.zero;layout.Parent=content;content.AutomaticCanvasSize=Enum.AutomaticSize.Y;content.ScrollBarThickness=3;content.ScrollingEnabled=true
 end
 local function text(value,height)
  local t=Instance.new("TextLabel");t.Size=UDim2.new(1,-8,0,height or 42);t.BackgroundTransparency=1;t.Font=Enum.Font.Gotham;t.TextSize=15;t.TextColor3=Color3.fromRGB(214,226,243);t.TextWrapped=true;t.TextXAlignment=Enum.TextXAlignment.Left;t.Text=value;t.LayoutOrder=#content:GetChildren();t.Parent=content;return t
 end
 local function button(value,fn,height,accent)
  local b=Instance.new("TextButton");b.Size=UDim2.new(1,-8,0,height or 52);b.Text=value;b.LayoutOrder=#content:GetChildren();Theme.button(b);b.TextSize=16;b.TextXAlignment=Enum.TextXAlignment.Left;local padding=Instance.new("UIPadding");padding.PaddingLeft=UDim.new(0,18);padding.PaddingRight=UDim.new(0,18);padding.Parent=b;if accent then b.BackgroundColor3=accent end;b.Parent=content
  local kind=if string.find(value,"Settings")then "Settings"elseif string.find(value,"Tutorial")then "Tutorial"elseif string.find(string.lower(value),"friend")then "Friends"elseif string.find(value,"Leave")then "Exit"elseif value=="Back"then "Back"elseif string.find(string.lower(value),"private")then "Private"else nil
  if kind and (height or 52)<=68 then padding:Destroy();Art.buttonContent(b,kind,false)end
  b.Activated:Connect(fn)
  b.AutoButtonColor=false
  local function hover(on)TweenService:Create(b,TweenInfo.new(.16,Enum.EasingStyle.Quad),{BackgroundTransparency=if on then .02 else .14}):Play()end
  b.MouseEnter:Connect(function()hover(true)end);b.MouseLeave:Connect(function()hover(false)end)
  return b
 end
 local function navigate(nextPage)page=nextPage;render()end
 local function invite()
  task.spawn(function()
   local ok,allowed=pcall(function()return Social:CanSendGameInviteAsync(player)end)
   if not ok or not allowed then message.Text="Roblox invitations are unavailable for this account or device.";return end
   local options=Instance.new("ExperienceInviteOptions")
   if state.Code then options.LaunchData="WC10:"..state.Code elseif state.InviteSession then options.LaunchData="WC10:P:"..state.InviteSession end
   local opened=pcall(function()Social:PromptGameInvite(player,options)end)
   if not opened then message.Text="The Roblox invitation prompt could not open. Try again later."end
  end)
 end
 local steps={
  {"1 / 7 · Spawn","When the map is ready, choose unoccupied land during the countdown. Tap again to move your spawn. No choice? The server assigns one."},
  {"2 / 7 · Expand","Select neutral land to expand along eligible borders. Recruitment rebuilds your reserve. Drag to pan; wheel or Settings controls zoom Earth."},
  {"3 / 7 · Army","Open Army and drag the allocation slider from 1–100%. Keep reserves at home. Cycle your attacks and use Stop / return when needed."},
  {"4 / 7 · Combat","Select enemy territory to attack shared borders. Defence, terrain and reserves matter. Enemy retreat loses soldiers; eliminated players spectate."},
  {"5 / 7 · Economy","Gold arrives over time. Buildings shows real costs and effects. Place cities and factories on your land; upgrade or demolish using their controls."},
  {"6 / 7 · Navy","Launch invasions at reachable coasts. Completed ports allow warships and automatic trade. Select your ship before issuing move or return orders."},
  {"7 / 7 · Missiles","Build a silo and wait for its launch slot. Choose a missile and target; SAMs intercept automatically. Fallout changes land value. Victory opens results, then returns everyone to the menu."},
 }
 render=function()
  clear()
  local hero=page=="Home"and state.Screen~="Lobby"
  title.TextSize=if gui.AbsoluteSize.X<700 then 32 elseif hero then 64 else 46
  content.Position=UDim2.fromOffset(20,if hero then 150 else 126)
  content.Size=UDim2.new(1,-40,1,if hero then -220 else -196)
  if gui.AbsoluteSize.X>=800 then content.ScrollBarThickness=0 end
  if gui.AbsoluteSize.Y<500 and not hero then content.Position=UDim2.fromOffset(12,82);content.Size=UDim2.new(1,-24,1,-132)end
  local premiumPage=premium and premium.render(page,state)
  title.Visible=not (premiumPage and page=="Home");subtitle.Visible=title.Visible
  if premiumPage then
   -- The premium pages share this existing root, close control and safe area.
  elseif page=="Settings"then
   text("SETTINGS")
   button("Communication & microphone",function()require(script.Parent.CommunicationClient).open()end)
   button("Language: "..(player:GetAttribute("WCLanguage")or "auto"),function()
    local choices={"auto","en-us","es-es","fr-fr"};local index=table.find(choices,player:GetAttribute("WCLanguage")or "auto")or 1
    player:SetAttribute("WCLanguage",choices[index%#choices+1]);render()
   end)
   button("Source & licences",function()require(script.Parent.SourceOffer).open()end)
   button("Menu UI scale: "..math.round((player:GetAttribute("MenuScale") or 1)*100).."%",function()
    local current=player:GetAttribute("MenuScale") or 1;player:SetAttribute("MenuScale",if current==1 then 1.1 elseif current==1.1 then .9 else 1);render()
   end)
   button("Map frame budget: "..(if Config.RenderBudgetSeconds<.003 then "Low CPU" else "Balanced"),function()Config.RenderBudgetSeconds=if Config.RenderBudgetSeconds<.003 then .003 else .0015;render()end)
   text("Low CPU limits map painting work per frame; it preserves map resolution and may finish updates more slowly.",66)
   text("Audio: this build has no custom soundtrack. Use Roblox's system menu for device volume and graphics quality.",66)
   button("Back",function()navigate("Home")end)
  elseif page=="Tutorial"then
   text(steps[tutorial][1],38);text(steps[tutorial][2],142)
   if tutorial>1 then button("Previous",function()tutorial-=1;render()end)end
   button(if tutorial==#steps then "Finish tutorial" else "Next",function()if tutorial==#steps then navigate("Home")else tutorial+=1;render()end end)
   button("Skip tutorial",function()navigate("Home")end)
  elseif page=="Private"then
   text("PRIVATE MATCH")
   button("Host a private lobby",function()send("CreatePrivate")end,68,Color3.fromRGB(48,64,88))
   text("Have a private join code? Paste it below.",40)
   local code=Instance.new("TextBox");code.Size=UDim2.new(1,-8,0,52);code.PlaceholderText="32-character private code";code.Text="";code.ClearTextOnFocus=false;code.Font=Enum.Font.Gotham;code.TextSize=14;code.TextColor3=Color3.new(1,1,1);code.LayoutOrder=#content:GetChildren();Theme.surface(code);code.Parent=content
   button("Join private lobby",function()send("JoinPrivate",{Code=string.gsub(code.Text,"%s","")})end)
   button("Back",function()navigate("Home")end)
  elseif state.Screen=="Lobby"then
   layout.Parent=nil;content.AutomaticCanvasSize=Enum.AutomaticSize.None
   local mobile=gui.AbsoluteSize.X<600
   local short=gui.AbsoluteSize.Y<500
   content.ScrollBarThickness=if mobile then 3 else 0;content.ScrollingEnabled=mobile
   local roster=Instance.new("ScrollingFrame");roster.BorderSizePixel=0;roster.ScrollBarThickness=if (state.Bots or 0)+#(state.Players or {})>20 then 3 else 0;roster.CanvasSize=UDim2.fromOffset(0,44+math.ceil(((state.Bots or 0)+#(state.Players or {}))/(if mobile then 2 else 4))*58);roster.Name="ParticipantCards";roster.BackgroundTransparency=1;roster.Size=if mobile then UDim2.new(1,0,0,math.ceil((#(state.Players or {})+(state.Bots or 0))/2)*62+48)else UDim2.new(.66,-18,1,0);roster.Parent=content
   local heading=Instance.new("TextLabel");heading.BackgroundTransparency=1;heading.Font=Enum.Font.GothamBold;heading.TextSize=16;heading.TextColor3=Color3.fromRGB(218,230,244);heading.TextXAlignment=Enum.TextXAlignment.Left;heading.Size=UDim2.new(1,0,0,38);heading.Text=string.format("%d PLAYERS",#(state.Players or {})+(state.Bots or 0));heading.Parent=roster
   local index=0;local columns=if mobile or gui.AbsoluteSize.X<1000 then 2 else 4
   roster.ScrollBarThickness=3;roster.CanvasSize=UDim2.fromOffset(0,44+math.ceil(((state.Bots or 0)+#(state.Players or {}))/columns)*58)
   local function participant(name,user,host)
    local card=Instance.new("Frame");card.Name="Participant";Theme.surface(card);card.Position=UDim2.new((index%columns)/columns,0,0,44+math.floor(index/columns)*58);card.Size=UDim2.new(1/columns,-8,0,50);card.Parent=roster;index+=1
    if user and user>0 then local avatar=Instance.new("ImageLabel");avatar.Size=UDim2.fromOffset(32,32);avatar.Position=UDim2.fromOffset(8,9);avatar.BackgroundTransparency=1;avatar.Image="rbxthumb://type=AvatarHeadShot&id="..user.."&w=150&h=150";avatar.Parent=card
    else local icon=Art.profile(card,name,32);icon.Position=UDim2.fromOffset(8,9)end
    local label=Instance.new("TextLabel");label.BackgroundTransparency=1;label.Position=UDim2.fromOffset(46,5);label.Size=UDim2.new(1,-50,0,22);label.Text=name;label.TextSize=13;label.Font=Enum.Font.GothamMedium;label.TextXAlignment=Enum.TextXAlignment.Left;label.TextColor3=Color3.fromRGB(239,244,252);label.TextTruncate=Enum.TextTruncate.AtEnd;label.Parent=card
    label.AutoLocalize=false;label.RichText=false
    local detail=Instance.new("TextLabel");detail.BackgroundTransparency=1;detail.Position=UDim2.fromOffset(46,28);detail.Size=UDim2.new(1,-50,0,16);detail.Text=if host then "HOST" else "READY";detail.TextSize=10;detail.Font=Enum.Font.Gotham;detail.TextXAlignment=Enum.TextXAlignment.Left;detail.TextColor3=Color3.fromRGB(134,169,193);detail.Parent=card
   end
   for _,p in ipairs(state.Players or {})do participant(p.NationName or p.Name,p.UserId,p.Host)end
   for _,name in ipairs(state.BotNames or {})do participant(name,nil,false)end
   local side=Instance.new("ScrollingFrame");side.CanvasSize=UDim2.new();side.BorderSizePixel=0;side.ScrollBarThickness=3;side.BackgroundTransparency=1;side.Position=if mobile then UDim2.fromOffset(0,roster.Size.Y.Offset+16)else UDim2.fromScale(.68,0);side.Size=if mobile then UDim2.new(1,0,0,430)else UDim2.new(.32,0,1,0);side.Parent=content
   local y=0
   local function sideItem(item,h)item.Parent=side;item.Position=UDim2.fromOffset(0,y);item.Size=UDim2.new(1,0,0,h);y+=h+6;return item end
   countdown=sideItem(text(if state.Countdown then tostring(state.Countdown).."s"else "READY",54),54);countdown.Font=Enum.Font.GothamBold;countdown.TextSize=44;countdown.TextColor3=Color3.fromRGB(221,193,135)
   if state.Code then
    local code=Instance.new("TextBox");code.Text=state.Code;code.TextEditable=false;code.ClearTextOnFocus=false;code.Font=Enum.Font.Code;code.TextSize=12;code.TextColor3=Color3.fromRGB(224,199,143);Theme.surface(code);sideItem(code,34)
   end
   sideItem(button("Invite friends",invite,44,Color3.fromRGB(30,74,87)),44)
   if state.MatchType=="Private"and state.Host then
    local minus=sideItem(button("- Bot",function()send("Settings",{Count=math.max(0,state.Bots-1),Difficulty=state.Difficulty})end),44);minus.Size=UDim2.new(.48,0,0,44)
    local plus=button("+ Bot",function()send("Settings",{Count=math.min((state.Capacity or 20)-1,state.Bots+1),Difficulty=state.Difficulty})end);plus.Parent=side;plus.Position=UDim2.new(.52,0,0,y-50);plus.Size=UDim2.new(.48,0,0,44)
    sideItem(button("Difficulty: "..state.Difficulty,function()local choices={"Easy","Normal","Hard"};send("Settings",{Count=state.Bots,Difficulty=choices[(table.find(choices,state.Difficulty)or 1)%3+1]})end),44)
    sideItem(button("Start match",function()send("Start")end,48,Color3.fromRGB(37,93,73)),44)
   end
   sideItem(button("Leave lobby",function()send("Leave")end,40,Color3.fromRGB(75,40,48)),44)
   side.CanvasSize=UDim2.fromOffset(0,y);content.CanvasSize=if mobile then UDim2.fromOffset(0,roster.Size.Y.Offset+y+32)else UDim2.new()
  else
   layout.Parent=nil;content.AutomaticCanvasSize=Enum.AutomaticSize.None
   local mobile=gui.AbsoluteSize.X<700 or gui.AbsoluteSize.Y<500
   content.ScrollBarThickness=if mobile then 3 else 0;content.ScrollingEnabled=mobile
   local function card(label,description,kind,x,y,w,h,color,fn)
    local b=button(label,fn,h,color);b.Name=kind.."Card";b.Position=UDim2.new(x,0,0,y);b.Size=UDim2.new(w,-10,0,h);b.Text="";b.ClipsDescendants=true
    local padding=b:FindFirstChildOfClass("UIPadding");if padding then padding.PaddingLeft=UDim.new(0,0);padding.PaddingRight=UDim.new(0,0)end
    local icon=Art.icon(b,kind,if h>100 then 38 else 24,Color3.fromRGB(158,202,230));icon.Position=UDim2.fromOffset(24,if h>100 then 24 else 22)
    local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Text=label;t.Font=Enum.Font.GothamBold;t.TextSize=if h>100 then 24 else 18;t.TextColor3=Color3.fromRGB(244,247,252);t.TextXAlignment=Enum.TextXAlignment.Left;t.Position=UDim2.fromOffset(if h>100 then 24 else 66,if h>100 then 86 else 16);t.Size=UDim2.new(1,-48,0,32);t.Parent=b
    local d=Instance.new("TextLabel");d.BackgroundTransparency=1;d.Text=description;d.Font=Enum.Font.Gotham;d.TextSize=13;d.TextWrapped=true;d.TextColor3=Color3.fromRGB(164,190,212);d.TextXAlignment=Enum.TextXAlignment.Left;d.Position=UDim2.fromOffset(if h>100 then 24 else 66,if h>100 then 126 else 46);d.Size=UDim2.new(1,-90,0,38);d.Parent=b
    -- Accessible activation text retained as an attribute; visible typography is separate.
    b:SetAttribute("ActionLabel",label)
    return b
   end
   local h=if gui.AbsoluteSize.Y<500 then 64 elseif mobile then 108 else 150
   playButton=button(if matchmaking then "FINDING MATCH..."else "PLAY",function()send("Public")end,h,Color3.fromRGB(24,66,91));playButton.Name="Play";playButton:SetAttribute("ActionLabel","PLAY");playButton.Size=UDim2.new(1,-10,0,h);playButton.Position=UDim2.fromOffset(0,0);playButton.TextXAlignment=Enum.TextXAlignment.Center;playButton.Font=Enum.Font.GothamBold;playButton.TextSize=36
   local icon=Art.icon(playButton,"Play",30,Color3.fromRGB(178,220,246));icon.Position=UDim2.new(.5,-100,.5,-15)
   local row=h+12
   local private=button("Private Match",function()navigate("Private")end,76);private:SetAttribute("ActionLabel","PRIVATE MATCH");private.Position=UDim2.new(0,0,0,row);private.Size=UDim2.new(1,-10,0,if gui.AbsoluteSize.Y<500 then 48 else 76)
   local secondary=row+(if gui.AbsoluteSize.Y<500 then 60 else 88)
   local settings=button("Settings",function()navigate("Settings")end);settings.Position=UDim2.fromOffset(0,secondary);settings.Size=UDim2.new(.5,-10,0,44)
   local tutorialButton=button("Tutorial",function()tutorial=1;navigate("Tutorial")end);tutorialButton.Position=UDim2.new(.5,0,0,secondary);tutorialButton.Size=UDim2.new(.5,-10,0,44)
   content.CanvasSize=UDim2.fromOffset(0,secondary+50)
  end
  local lobbyHome=state.Screen=="Lobby"and page=="Home"
  title.Text=if lobbyHome then string.upper(state.MatchType).." LOBBY"else "WORLD CONQUEST"
  subtitle.Text=if lobbyHome then "Rally your allies. Prepare for deployment. Matches may include AI opponents."else "ONE PLANET. COUNTLESS POSSIBILITIES."
 end
 remote.OnClientEvent:Connect(function(nextState)
  received=true
  local old=state.Screen;state=nextState
  if state.Screen~="Menu"or state.Message then matchmaking=false;busySerial+=1;if playButton then playButton.Text="PLAY"end end
  gui.Enabled=state.Screen~="Game";showGame(state.Screen=="Game")
  if state.Message then message.Text=state.Message elseif state.LocalTest then message.Text="Studio local lobby test · cloud matchmaking, invites and teleports need live verification."end
  local key=state.Screen..tostring(state.MatchType)..tostring(state.Bots)..tostring(state.Difficulty)..tostring(state.Host)..tostring(state.Code)
  for _,p in ipairs(state.Players or {})do key..=tostring(p.UserId)..tostring(p.Host)..tostring(p.NationName)end
  for _,name in ipairs(state.BotNames or {})do key..=name end
  if old~=state.Screen then page="Home"end
  if key~=renderKey then renderKey=key;render()end
  if countdown then countdown.Text=if state.Countdown then tostring(state.Countdown).."s"else "READY"end
 end)
 local credit=Instance.new("TextLabel");credit.Name="Attribution";credit.BackgroundTransparency=1;credit.Position=UDim2.new(0,20,1,-22);credit.Size=UDim2.new(1,-40,0,18);credit.Font=Enum.Font.Gotham;credit.TextSize=10;credit.TextColor3=Color3.fromRGB(140,159,181);credit.Text="Unofficial OpenFront adaptation / ? OpenFront and Contributors / AGPL-3.0";credit.TextWrapped=true;credit.Size=UDim2.new(1,-40,0,26);credit.Position=UDim2.new(0,20,1,-26);credit.Parent=panel
 local close=Instance.new("TextButton");close.Name="CloseMenuPage";close.Text="";close.Size=UDim2.fromOffset(44,44);close.Position=UDim2.new(1,-56,0,8);close.BackgroundTransparency=.2;close.BackgroundColor3=Color3.fromRGB(27,39,55);close.ZIndex=60;close.Parent=panel
 local x=Art.icon(close,"Close",18,Color3.fromRGB(223,235,248));x.Position=UDim2.fromOffset(13,13)
 close.Activated:Connect(function()navigate("Home")end)
 local previousRender=render;render=function()previousRender();close.Visible=page~="Home"end
 if Config.PremiumEnabled then
  premium=require(script.Parent.PremiumMenu).new(gui,content,layout,navigate,function()render()end,function()send("Public")end,message)
 end
 game:GetService("UserInputService").InputBegan:Connect(function(input,processed)if input.KeyCode==Enum.KeyCode.Escape and gui.Enabled and page~="Home"then navigate("Home")end end)
 showGame(false);render();send("Hello")
 for _,delay in ipairs({2,6,12})do task.delay(delay,function()if not received and gui.Parent then send("Hello")end end)end
 return {Gui=gui,Request=send}
end
return Menu
