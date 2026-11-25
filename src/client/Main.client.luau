--!strict
local startupOK,startupError=xpcall(function()
local clientBootStarted=os.clock()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
-- Keep Roblox system menu/chat; disable redundant character and roster overlays.
local StarterGui=game:GetService("StarterGui")
task.spawn(function()
 for _=1,8 do
  local ok=pcall(function()
   for _,kind in ipairs({Enum.CoreGuiType.PlayerList,Enum.CoreGuiType.Backpack,Enum.CoreGuiType.Health,Enum.CoreGuiType.EmotesMenu}) do StarterGui:SetCoreGuiEnabled(kind,false) end
  end)
  if ok then break end;task.wait(.5)
 end
end)
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(shared:WaitForChild("Config"))
task.spawn(function()require(script.Parent.CommunicationClient).start()end)
local MoneyFormat = require(shared.OpenFront.MoneyFormat)

local gui = Instance.new("ScreenGui")
gui.Name="WorldConquest"; gui.ResetOnSpawn=false; gui.DisplayOrder=10
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
-- One explicit physical-screen coordinate space. Safe insets are layout padding,
-- not an extra subtraction during picking.
gui.ScreenInsets=Enum.ScreenInsets.None
gui.ClipToDeviceSafeArea=false
gui.Parent=player:WaitForChild("PlayerGui")
local onVisibility=nil
local rendererReady=false
if UserInputService.TouchEnabled then Config.MaxImageTiles=math.min(Config.MaxImageTiles,8);Config.RenderBudgetSeconds=math.min(Config.RenderBudgetSeconds,.0015)end
pcall(function()player.PlayerGui.ScreenOrientation=Enum.ScreenOrientation.LandscapeSensor end)
if Config.PortStage>=10 then
 require(script.Parent.MainMenu).new(function(active)
  gui.Enabled=active;player:SetAttribute("WCLoading",active and not rendererReady)
  if onVisibility then onVisibility(active)end
 end)
 player:SetAttribute("WCMenuReady",true)
end
player:SetAttribute("WCLoadingStatus","Preparing Earth and multiplayer?")
local Map=require(shared:WaitForChild("Map"))
local MapView=require(script.Parent:WaitForChild("MapView"))
local remote=ReplicatedStorage:WaitForChild("WorldConquestEvent") :: RemoteEvent
local bleed=Instance.new("Frame");bleed.Name="FullScreenBackdrop";bleed.Size=UDim2.fromScale(1,1);bleed.BackgroundColor3=Color3.fromRGB(8,14,23);bleed.BorderSizePixel=0;bleed.Parent=gui
local background=Instance.new("Frame")
background.Name="SafeInterface";background.Active=false;background.BackgroundTransparency=1;background.ZIndex=30; background.BorderSizePixel=0
background.Parent=gui
local function layoutSafeArea()
	local topLeft,bottomRight=GuiService:GetGuiInset()
 pcall(function()local full=GuiService:GetInsetArea(Enum.ScreenInsets.None);local safe=GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets);topLeft=safe.Min-full.Min;bottomRight=full.Max-safe.Max end)
	background.Position=UDim2.fromOffset(topLeft.X,topLeft.Y)
	background.Size=UDim2.new(1,-topLeft.X-bottomRight.X,1,-topLeft.Y-bottomRight.Y)
end
layoutSafeArea()
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layoutSafeArea)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutSafeArea)
local function label(text: string,y: number,height: number): TextLabel
	local item=Instance.new("TextLabel")
	item.Position=UDim2.new(0,16,0,y); item.Size=UDim2.new(1,-32,0,height)
	item.BackgroundTransparency=1; item.Text=text; item.TextColor3=Color3.fromRGB(229,237,241)
	item.Font=Enum.Font.GothamMedium; item.TextScaled=true; item.TextXAlignment=Enum.TextXAlignment.Left
	local constraint=Instance.new("UITextSizeConstraint"); constraint.MaxTextSize=18; constraint.Parent=item
	item.Parent=background
	return item
end
local titleLabel=label("WORLD CONQUEST / EARTH",8,24)
if Config.SimulationMode=="Foundation" then
    titleLabel.Text="WORLD CONQUEST / unofficial adaptation | "..utf8.char(169).." OpenFront and Contributors"
end
local phaseLabel=label("Loading detailed Earth...",36,24)
local playerLabel=label("Choose your starting location on land.",64,20)
local viewport=Instance.new("Frame")
viewport.Name="MapViewport"; viewport.Position=UDim2.fromOffset(0,0)
viewport.Size=UDim2.fromScale(1,1);viewport.ZIndex=1; viewport.BackgroundColor3=Color3.fromRGB(45,93,133)
viewport.BorderSizePixel=0; viewport.Parent=gui
local status=label("Loading Natural Earth 10m land and lakes...",0,22)
status.Position=UDim2.new(0,16,1,-66)
local help=label("Drag to pan | Wheel or +/- to zoom | Click land",0,30)
help.Position=UDim2.new(0,16,1,-36); help.Size=UDim2.new(1,-190,0,30)
local Replica = require(shared.OpenFront.Replica)
local replica = if Config.SimulationMode=="Foundation" then Replica.new(require(shared.OpenFront.EarthTerrain)) else nil
local foundationReady=false
local acceptFoundation=Config.PortStage<10
local state: any=nil
local lastClick=-math.huge
local allocation=0.2
local localProfile=nil
local buildingShop=nil
local navalControls=nil
local missileControls,matchHUD=nil,nil
local strategyUI=nil
local matchID=1
local function send(action,x,y,allocation)remote:FireServer(action,x,y,allocation,matchID)end
local orderSequence=0
local function nextOrderSequence()orderSequence+=1;return orderSequence end
local view=MapView.new(viewport,function(x: number,y: number)
	if not state then return end
    if missileControls and missileControls.click(x,y) then return end
    if state.Phase~="Selecting" and state.Phase~="Started" then return end
    if navalControls and navalControls.click(x,y) then return end
    if buildingShop and buildingShop.click(x,y) then return end
	local cell=Map.cell(x,y)
	if not cell or not Map.isLand(cell) then status.Text="Oceans and lakes cannot be claimed."; return end
	local action=if state.Phase=="Selecting" then "SelectSpawn" else "Expand"
	local cooldown=if action=="Expand" then Config.ExpansionCooldown else Config.RequestCooldown
	if os.clock()-lastClick<cooldown then return end
	lastClick=os.clock()
	send(action,x,y,allocation)
end,function(message) status.Text=message end)
gui:SetAttribute("StartupMilliseconds",(os.clock()-clientBootStarted)*1000)
assert(view,"Map view initialization failed")
if Config.SimulationMode=="Foundation" and Config.PortStage>=5 then
    local BuildingShop=require(script.Parent.BuildingShop)
    buildingShop=BuildingShop.new(viewport,function(order)send("Building",order)end,function(message)status.Text=message end,view.buildingAt,nextOrderSequence,function()if navalControls then navalControls.cancel() end;if missileControls then missileControls.cancel() end end,function(kind)view.setPlacement(kind,localProfile and localProfile.SmallId)end)
end
if Config.SimulationMode=="Foundation" and Config.PortStage>=6 then
    local NavalControls=require(script.Parent.NavalControls)
    navalControls=NavalControls.new(viewport,function(order)send("Naval",order)end,function(message)status.Text=message end,view.shipAt,nextOrderSequence,function()return allocation end,function()if buildingShop then buildingShop.cancel() end;if missileControls then missileControls.cancel() end end)
end
if Config.SimulationMode=="Foundation" and Config.PortStage>=8 then
 missileControls=require(script.Parent.MissileControls).new(viewport,function(order)send("Missile",order)end,function(message)status.Text=message end,nextOrderSequence,function()if buildingShop then buildingShop.cancel() end;if navalControls then navalControls.cancel() end end)
 matchHUD=require(script.Parent.MatchHUD).new(viewport,view.focus,player.UserId)
end
if buildingShop then buildingShop.attach(navalControls,missileControls)end
local selectedAttackID=nil
local attackSelector=nil
local resources=label("",89,24)
strategyUI=require(script.Parent.StrategyUI).new(background,viewport,titleLabel,phaseLabel,playerLabel,status,help,resources,view,if Config.PortStage>=10 then function()require(script.Parent.MainMenu).request("Leave")end else nil)
for index,control in pairs({[2]=buildingShop,[3]=navalControls,[4]=missileControls,[5]=matchHUD}) do
 if control then strategyUI.mount(control.Toggle,control.Panel,index,control.cancel) end
end
resources.Visible=false
local identityRemote=nil
task.spawn(function()
 identityRemote=ReplicatedStorage:WaitForChild("WorldConquestIdentity",30)
 if identityRemote then
  strategyUI.bindNation(function(value)identityRemote:FireServer(if value==""then "Reset"else "Set",value)end)
  identityRemote.OnClientEvent:Connect(function(payload)strategyUI.nation(payload.Name);if payload.Message then strategyUI.notify(payload.Message)end end)
  identityRemote:FireServer("Hello")
 end
end)
if Config.SimulationMode=="Foundation" and Config.PortStage>=2 then

	local function control(text,x,width,callback)
		local b=Instance.new("TextButton");b.Position=UDim2.fromOffset(12,12+x);b.Size=UDim2.new(1,-24,0,44)
		b.BackgroundColor3=Color3.fromRGB(37,60,76);b.TextColor3=Color3.new(1,1,1);b.TextSize=14;b.Text=text;b.Parent=strategyUI.Army;b.ZIndex=46;require(script.Parent.StrategyUI).button(b)
		b.Activated:Connect(callback);return b
	end
	-- ControlPanel.ts: range input min=1, max=100, default integer step, ratio=value/100.
	local amount=Instance.new("TextLabel");amount.Position=UDim2.fromOffset(12,12);amount.Size=UDim2.new(1,-24,0,44);amount.BackgroundTransparency=1;amount.Text="Allocate 20%";amount.Font=Enum.Font.GothamMedium;amount.TextSize=18;amount.TextColor3=Color3.fromRGB(104,174,244);amount.ZIndex=46;amount.Parent=strategyUI.Army
	local slider=control("",52,160,function() end);slider.AutoButtonColor=false;slider.BackgroundTransparency=1
 local track=Instance.new("Frame");track.Name="AllocationTrack";track.Position=UDim2.new(0,0,.5,-3);track.Size=UDim2.new(1,0,0,6);track.BackgroundColor3=Color3.fromRGB(45,62,82);track.BorderSizePixel=0;track.ZIndex=47;track.Parent=slider
 local trackCorner=Instance.new("UICorner");trackCorner.CornerRadius=UDim.new(1,0);trackCorner.Parent=track
	local fill=Instance.new("Frame");fill.BorderSizePixel=0;fill.BackgroundColor3=Color3.fromRGB(75,165,255)
	fill.Size=UDim2.fromScale(19/99,1);fill.Parent=track
 local thumb=Instance.new("Frame");thumb.Name="AllocationThumb";thumb.AnchorPoint=Vector2.new(.5,.5);thumb.Position=UDim2.fromScale(19/99,.5);thumb.Size=UDim2.fromOffset(18,18);thumb.BackgroundColor3=Color3.fromRGB(224,236,250);thumb.BorderSizePixel=0;thumb.ZIndex=49;thumb.Parent=slider
 local thumbCorner=Instance.new("UICorner");thumbCorner.CornerRadius=UDim.new(1,0);thumbCorner.Parent=thumb
	fill.ZIndex=48;fill.BackgroundTransparency=0
	local dragging=false;local dragInput=nil
	local function setPointer(position)
		local fraction=math.clamp((position.X-slider.AbsolutePosition.X)/math.max(1,slider.AbsoluteSize.X),0,1)
		local value=math.round(1+fraction*99);allocation=value/100
		amount.Text=string.format("Allocate %d%%",value);fill.Size=UDim2.fromScale((value-1)/99,1);thumb.Position=UDim2.fromScale((value-1)/99,.5);strategyUI.setAllocation(allocation)
	end
 strategyUI.bindAllocation(function(value)
  allocation=value;amount.Text=string.format("Allocate %d%%",math.round(value*100));fill.Size=UDim2.fromScale((value*100-1)/99,1);thumb.Position=UDim2.fromScale((value*100-1)/99,.5)
 end)
	slider.InputBegan:Connect(function(input)
		if dragging then return end
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true;dragInput=input;strategyUI.Army.ScrollingEnabled=false;setPointer(input.Position) end
	end)
	local changed=UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input==dragInput) then setPointer(input.Position) end
	end)
	local ended=UserInputService.InputEnded:Connect(function(input)
		if input==dragInput then dragging=false;dragInput=nil;strategyUI.Army.ScrollingEnabled=true end
	end)
 UserInputService.WindowFocusReleased:Connect(function()dragging=false;dragInput=nil;strategyUI.Army.ScrollingEnabled=true end)
	gui.Destroying:Connect(function() changed:Disconnect();ended:Disconnect() end)
	control("Stop / return",104,115,function()
        if selectedAttackID then send("Cancel",selectedAttackID) end
    end)
    attackSelector=control("No attack",156,245,function()
        local attacks=if localProfile then localProfile.Attacks or {} else {}
        for index,attack in ipairs(attacks) do
            if attack.ID==selectedAttackID then
                local nextAttack=attacks[index%#attacks+1];selectedAttackID=nextAttack.ID
                attackSelector.Text=nextAttack.Target.." (click to cycle)";return
            end
        end
    end)
end

local function updatePlayerLabel()
	for _,profile in ipairs(state.Players) do
		if profile.UserId==player.UserId then
			localProfile=profile
            strategyUI.stats(profile,state)
            local selected=nil;local committed=0
            for _,attack in ipairs(profile.Attacks or {}) do
                committed+=attack.Troops
                if attack.ID==selectedAttackID then selected=attack end
            end
            selected=selected or (profile.Attacks or {})[1]
            selectedAttackID=if selected then selected.ID else nil
            if attackSelector then attackSelector.Text=if selected then selected.Target..(if selected.Retreating then " (returning)" else " (click to cycle)") else "No attack" end
            profile.Committed=committed
			if profile.Troops then resources.Text=string.format("Soldiers %d / %d | +%d/s | Committed %d%s",profile.Troops,math.floor(profile.Cap),math.floor(profile.Growth)*10,math.floor(profile.Committed),if profile.Retreating then " (returning)" else "") end
			if profile.Gold then
                resources.Text=string.format("Soldiers %s/%s | +%s/s | Army %s%s | $%s (+%s/s)",
                    MoneyFormat.money(profile.Troops),MoneyFormat.money(math.floor(profile.Cap)),MoneyFormat.money(math.floor(profile.Growth)*10),
                    MoneyFormat.money(math.floor(profile.Committed)),if profile.Retreating then " returning" else "",
                    MoneyFormat.money(profile.Gold),MoneyFormat.money(if profile.GoldIncome=="0" then "0" else profile.GoldIncome.."0"))
            end
            local rank="—"
            for i,p in ipairs(state.Rankings or {}) do if p.UserId==player.UserId or p.SmallId==profile.SmallId then rank=tostring(i);break end end
            resources.Text..=" | Land "..MoneyFormat.money(profile.Count).." | Rank "..rank
			playerLabel.TextColor3=profile.Color
            if buildingShop then buildingShop.update(profile,state.Phase) end
            if navalControls then navalControls.update(profile,state.Phase) end
            if missileControls then missileControls.update(profile,state.Phase) end
			playerLabel.Text=string.format("@%s | %s | Land cells: %d",profile.Username,
				if profile.Eliminated then "Eliminated / spectating" elseif profile.Spectator then "Spectating" elseif profile.Spawn then "Spawn selected" else "Choose a spawn",profile.Count)
		end
	end
end
local resyncPending=false
local lastServerMessage=os.clock()
local function resync()
	if resyncPending then return end
	resyncPending=true
	task.delay(2.1,function() resyncPending=false; send("Sync") end)
end
task.spawn(function()
 while gui.Parent do
  task.wait(3)
  if gui.Enabled and acceptFoundation and os.clock()-lastServerMessage>8 then
   status.Text="Reconnecting to the match…";resync()
  end
 end
end)
-- Public metadata omits private purchase quotes. Retain the last private packet
-- through metadata refreshes; MatchReset clears localProfile before a new round.
local function retainPrivateProfile(newState,previous,userID)
    if not previous or previous.UserId~=userID then return end
    for _,profile in ipairs(newState.Players)do if profile.UserId==userID then
        for _,key in ipairs({"BuildingQuotes","Naval","Missiles","Rail"})do
            if profile[key]==nil then profile[key]=previous[key]end
        end
        return
    end end
end
local function showFoundation(full, changes)
    if not replica or not replica.Meta then return end
    local starting=replica.Meta.Phase=="Started" and (not state or state.Phase~="Started")
    state=table.clone(replica.Meta)
    retainPrivateProfile(state,localProfile,player.UserId)
    state.Tick=replica.Tick
    if full then view.setGrid(replica.Grid) end
    if changes then view.foundationDelta(changes,replica.Grid) end
    view.render(state)
    updatePlayerLabel()
    if matchHUD then matchHUD.update(state) end
    if starting then
        for _,p in ipairs(state.Players) do if p.UserId==player.UserId and p.Spawn then view.focus(p.X,p.Y) end end
    end
    if state.Phase=="Selecting" then status.Text="Click land to select or move your spawn."
    elseif state.Phase=="Victory" or state.Phase=="Results" then status.Text=if Config.PortStage>=10 then "Match ended. Results will return you to the main menu."else "Match ended. See results; the next round starts automatically."
    elseif starting or full then status.Text="Click neutral land to expand or enemy land to attack shared borders. Enemy retreat loses 25%." end
end
onVisibility=function(active)
    if not active then
        acceptFoundation=false;foundationReady=false;state=nil;localProfile=nil
        if replica then replica.reset(matchID)end
        strategyUI.close();view.clear()
    end
end
remote.OnClientEvent:Connect(function(action: string,payload: any)
 lastServerMessage=os.clock()
    if action=="MatchReset" then
        acceptFoundation=true
        matchID=payload.MatchID;foundationReady=false;replica.reset(matchID);state=nil;localProfile=nil;orderSequence=0;selectedAttackID=nil
        if buildingShop then buildingShop.cancel() end;if navalControls then navalControls.cancel() end;if missileControls then missileControls.cancel() end
        strategyUI.close();phaseLabel.Text="Preparing next match...";status.Text="Synchronising the new round..."
        if Config.PortStage>=10 then task.spawn(function()local deadline=os.clock()+15;repeat task.wait(.05)until view.ready()or os.clock()>deadline;send("Sync")end)end
        return
    end
    if string.sub(action,1,10)=="Foundation"and not acceptFoundation then return end
    if action=="FoundationStats" then
        if payload.MatchID and payload.MatchID~=matchID then return end
        if state and foundationReady and payload.UserId==player.UserId then
            for _,profile in ipairs(state.Players) do if profile.UserId==player.UserId then
                if not profile.StatsTick or payload.Tick>=profile.StatsTick then
                    for key,value in pairs(payload) do if key~="UserId" and key~="Tick" then profile[key]=value end end
                    profile.StatsTick=payload.Tick;updatePlayerLabel()
                end
            end end
        end
        return
    end
    if replica and string.sub(action,1,10)=="Foundation" then
        local ok=true
        if action=="FoundationBegin" then ok=replica.begin(payload);if ok and payload.Meta then matchID=payload.Meta.MatchID or matchID end
        elseif action=="FoundationChunk" then ok=replica.chunk(payload)
        elseif action=="FoundationEnd" then
            ok=replica.finish(payload)
            if ok then foundationReady=true; showFoundation(true,nil) end
        elseif action=="FoundationDelta" then
            if not foundationReady and not replica.loading() then return end
            local complete
            ok,complete=replica.delta(payload)
            if ok and not complete then return end
            if complete then payload=complete end
            if ok and not replica.loading() then
                if payload.Meta or payload.SpawnChanges then showFoundation(false,payload.Changes)
                else
                    if state then
                        state.Tick=replica.Tick
                        for _,profile in ipairs(state.Players)do profile.Count=replica.Grid.Counts[profile.SmallId] or 0 end
                        view.ranks(state)
                        if matchHUD then matchHUD.update(state)end
                    end
                    if buffer.len(payload.Changes)>0 then view.foundationDelta(payload.Changes,replica.Grid) end
                    if payload.ShipChanges and buffer.len(payload.ShipChanges)>0 and state then view.renderShips(replica.Meta.Ships or {},state.Players) end
                    if payload.BuildingChanges and buffer.len(payload.BuildingChanges)>0 and state then view.renderBuildings(replica.Meta.Buildings or {},state.Players) end
                end
            end
        end
        if not ok then resync() end
        return
    end
	if action=="Result" then status.Text=payload;strategyUI.notify(payload); return end
	if action~="State" and action~="Update" and action~="Delta" then return end
	if state and payload.Revision<state.Revision then return end
	if action=="Delta" then
		if not state or payload.Revision~=state.Revision+1 then resync(); return end
		state.Revision=payload.Revision
		for _,group in ipairs(payload.Groups) do
			view.delta(group.Owner,group.Cells,false)
			for _,profile in ipairs(state.Players) do if profile.UserId==group.Owner then profile.Count=group.Count end end
		end
		state.GrowthLimited=payload.GrowthLimited
		status.Text=if state.GrowthLimited then "Prototype ownership limit reached; growth paused." else "Frontier grows automatically. Click an adjacent empty cell to claim it."
		updatePlayerLabel()
		return
	end
	if action=="Update" and state and payload.Revision~=state.Revision+1 then resync() end
	local starting = payload.Phase=="Started" and (not state or state.Phase~="Started")
	state=payload
	view.render(state)
	if starting then
		for _,profile in ipairs(state.Players) do
			if profile.UserId==player.UserId and profile.Spawn then view.focus(profile.X,profile.Y) end
		end
	end
	updatePlayerLabel()
	if state.Phase=="Started" then
		status.Text=if state.GrowthLimited then "Prototype ownership limit reached; growth paused." else "Frontier grows automatically. Click an adjacent empty cell to claim it."
	elseif state.Phase=="Selecting" then
		status.Text="Click land to select or move your spawn. No selection? A free spawn will be assigned."
	end
end)
local displayedPhase,displayedTick=nil,nil
RunService.RenderStepped:Connect(function()
	if not state then return end
 if state.Foundation and displayedPhase==state.Phase and displayedTick==state.Tick then return end
 displayedPhase,displayedTick=state.Phase,state.Tick
    if matchHUD then matchHUD.update(state) end
	if state.Phase=="Selecting" then
		phaseLabel.Text=string.format("CHOOSE YOUR SPAWN / %ds",math.max(0,math.ceil(if state.Foundation then (state.EndTick-state.Tick)*0.1 else state.Deadline-Workspace:GetServerTimeNow())))
        if state.SelectedSpawns then phaseLabel.Text..=string.format(" / %d of %d selected",state.SelectedSpawns,state.Participants or #state.Players)end
	elseif state.Phase=="Started" then
        local seconds=math.floor((state.Tick or 0)/10)
        phaseLabel.Text=string.format("WORLD CONQUEST   •   %02d:%02d",math.floor(seconds/60),seconds%60)
	elseif state.Phase=="Victory" or state.Phase=="Results" then phaseLabel.Text=state.Phase..(if Config.PortStage>=10 then " / Main menu in "else " / Next match in ")..math.max(0,math.ceil(((state.RestartAt or state.Tick)-state.Tick)/10)).."s"
	else phaseLabel.Text="Waiting for players..." end
end)
-- Do not start the timer until the initial visible map is actually painted.
local renderDeadline=os.clock()+20
repeat task.wait(0.05) until view.ready()or os.clock()>renderDeadline
rendererReady=true;player:SetAttribute("WCRendererReady",true);player:SetAttribute("WCLoading",false)
status.Text="Connecting to match..."
send("Sync")

end,debug.traceback)
if not startupOK then warn("WorldConquest startup: "..tostring(startupError));game:GetService("Players").LocalPlayer:SetAttribute("WCStartupError","Client initialization failed. The error was recorded in the client log.")end
