--!strict
-- Native audio streams, local receive mute, native moderation/blocking UI.
local Players=game:GetService("Players");local Starter=game:GetService("StarterGui")
local Client={};local started=false;local routes={};local muted={};local output=nil
local function wire(source,target,parent)local w=Instance.new("Wire");w.SourceInstance=source;w.TargetInstance=target;w.Parent=parent;return w end
function Client.start()
 if started then return end;started=true
 task.spawn(function()for _=1,8 do
  local ok=pcall(function()Starter:SetCoreGuiEnabled(Enum.CoreGuiType.Chat,true);Starter:SetCore("AvatarContextMenuEnabled",true)end)
  if ok then break end;task.wait(.5)
 end end)
 local ok=pcall(function()output=Instance.new("AudioDeviceOutput");output.Name="WorldConquestVoiceOutput";output.Player=Players.LocalPlayer;output.Parent=workspace end)
 if not ok then output=nil;return end
 local function attach(p,device)
  if p==Players.LocalPlayer or not device:IsA("AudioDeviceInput")or device.Name~="WorldConquestMicrophone"or routes[p]then return end
  local fader=Instance.new("AudioFader");fader.Name="Voice_"..p.UserId;fader.Volume=if muted[p.UserId]then 0 else 1;fader.Parent=output
  wire(device,fader,fader);wire(fader,output,fader);routes[p]=fader
  device.Destroying:Connect(function()if routes[p]==fader then routes[p]=nil end;fader:Destroy()end)
 end
 local function joined(p)p.ChildAdded:Connect(function(d)attach(p,d)end);for _,d in ipairs(p:GetChildren())do attach(p,d)end end
 Players.PlayerAdded:Connect(joined);Players.PlayerRemoving:Connect(function(p)if routes[p]then routes[p]:Destroy();routes[p]=nil end;muted[p.UserId]=nil end)
 for _,p in ipairs(Players:GetPlayers())do joined(p)end
end
function Client.status()
 local p=Players.LocalPlayer;local input=p:FindFirstChild("WorldConquestMicrophone")
 if not input or not p:GetAttribute("WCVoiceAvailable")then return p:GetAttribute("WCVoiceStatus")or "Voice unavailable"end
 return if input.Muted then "Microphone muted"elseif not input.Active then "Enable your microphone using Roblox controls"else "Microphone on"
end
function Client.toggleMicrophone()
 local input=Players.LocalPlayer:FindFirstChild("WorldConquestMicrophone")
 if input and Players.LocalPlayer:GetAttribute("WCVoiceAvailable")then input.Muted=not input.Muted end
 return Client.status()
end
function Client.toggleMute(p)
 muted[p.UserId]=not muted[p.UserId];if routes[p]then routes[p].Volume=if muted[p.UserId]then 0 else 1 end
 return muted[p.UserId]
end
function Client.isMuted(p)return muted[p.UserId]==true end
function Client.block(p)return pcall(function()Starter:SetCore("PromptBlockPlayer",p)end)end
local panelGui=nil
function Client.open()
 Client.start()
 if panelGui then panelGui:Destroy()end
 local Theme=require(script.Parent.StrategyUI)
 local gui=Instance.new("ScreenGui");gui.Name="WorldConquestCommunication";gui.DisplayOrder=80;gui.ResetOnSpawn=false;gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.Parent=Players.LocalPlayer.PlayerGui;panelGui=gui
 local shade=Instance.new("TextButton");shade.Text="";shade.AutoButtonColor=false;shade.BackgroundColor3=Color3.fromRGB(7,13,23);shade.BackgroundTransparency=.15;shade.Size=UDim2.fromScale(1,1);shade.Parent=gui
 local panel=Instance.new("ScrollingFrame");Theme.surface(panel);panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.new(1,-24,1,-24);panel.ScrollBarThickness=4;panel.AutomaticCanvasSize=Enum.AutomaticSize.Y;panel.CanvasSize=UDim2.new();panel.Parent=shade
 local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(600,650);limit.Parent=panel
 local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,8);layout.Parent=panel
 local function text(value,h)
  local t=Instance.new("TextLabel");t.Text=value;t.TextWrapped=true;t.TextDirection=Enum.TextDirection.Auto;t.TextColor3=Color3.fromRGB(230,237,247);t.Font=Enum.Font.Gotham;t.TextSize=14;t.BackgroundTransparency=1;t.Size=UDim2.new(1,-12,0,h or 48);t.LayoutOrder=#panel:GetChildren();t.Parent=panel;return t
 end
 local function button(value,fn)
  local b=Instance.new("TextButton");b.Text=value;Theme.button(b);b.Size=UDim2.new(1,-12,0,48);b.LayoutOrder=#panel:GetChildren();b.Parent=panel;b.Activated:Connect(function()fn(b)end);return b
 end
 button("Close",function()gui:Destroy();panelGui=nil end)
 text("COMMUNICATION",36)
 local status=text(Client.status(),48)
 local subscriptions={}
 local function watch(signal) table.insert(subscriptions,signal:Connect(function()if status.Parent then status.Text=Client.status()end end))end
 watch(Players.LocalPlayer:GetAttributeChangedSignal("WCVoiceAvailable"));watch(Players.LocalPlayer:GetAttributeChangedSignal("WCVoiceStatus"))
 local function watchInput(input)
  if input.Name=="WorldConquestMicrophone"then watch(input:GetPropertyChangedSignal("Muted"));watch(input:GetPropertyChangedSignal("Active"))end
 end
 for _,input in ipairs(Players.LocalPlayer:GetChildren())do watchInput(input)end
 table.insert(subscriptions,Players.LocalPlayer.ChildAdded:Connect(watchInput))
 gui.Destroying:Connect(function()for _,c in ipairs(subscriptions)do c:Disconnect()end end)
 button("Toggle microphone",function()status.Text=Client.toggleMicrophone()end)
 local chat=text("Checking Roblox text-chat permissions…",44)
 task.spawn(function()
  local ok,allowed=pcall(function()return game:GetService("TextChatService"):CanUserChatAsync(Players.LocalPlayer.UserId)end)
  if chat.Parent then chat.Text=if ok and allowed then "Use Roblox's chat button to send messages. Native filtering and mute commands apply."else "Text chat is unavailable or restricted by Roblox account permissions."end
 end)
 text("Reporting: open the Roblox system menu, choose Report, then select the player and reason. Roblox also provides voice and text moderation controls. This game cannot override age, parental, blocking or microphone permissions.",120)
 local people=Players:GetPlayers();table.sort(people,function(a,b)return a.UserId<b.UserId end)
 for _,p in ipairs(people)do if p~=Players.LocalPlayer then
  local label=text("@"..p.Name,30);label.AutoLocalize=false
  button(if Client.isMuted(p)then "Unmute voice"else "Mute voice",function(b)local on=Client.toggleMute(p);b.Text=if on then "Unmute voice"else "Mute voice"end)
  button("Block player in Roblox",function()if not Client.block(p)then status.Text="Open Roblox's system menu to block or report this player."end end)
 end end
end
return Client
