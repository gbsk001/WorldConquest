--!strict
-- First replicated, dependency-free recovery UI; never waits for map modules.
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui");gui.Name="WorldConquestLoading";gui.ResetOnSpawn=false;gui.DisplayOrder=1000;gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
local panel=Instance.new("Frame");panel.Size=UDim2.fromScale(1,1);panel.BackgroundColor3=Color3.fromRGB(9,16,26);panel.BorderSizePixel=0;panel.Parent=gui
local label=Instance.new("TextLabel");label.BackgroundTransparency=1;label.Position=UDim2.fromScale(.08,.28);label.Size=UDim2.fromScale(.84,.32);label.Font=Enum.Font.GothamMedium;label.TextSize=20;label.TextColor3=Color3.fromRGB(223,235,248);label.TextWrapped=true;label.Text="WORLD CONQUEST\nConnecting…";label.Parent=panel
local retry=Instance.new("TextButton");retry.AnchorPoint=Vector2.new(.5,0);retry.Position=UDim2.fromScale(.5,.65);retry.Size=UDim2.fromOffset(220,48);retry.Text="Reconnect to WorldConquest";retry.Font=Enum.Font.GothamMedium;retry.TextSize=14;retry.TextColor3=Color3.new(1,1,1);retry.BackgroundColor3=Color3.fromRGB(30,74,102);retry.Visible=false;retry.Parent=panel
gui.Parent=player:WaitForChild("PlayerGui")
pcall(function()game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()end)
local began=os.clock();local busy=false
retry.Activated:Connect(function()
 if busy then return end;busy=true;retry.Text="Reconnecting…"
 local ok=pcall(function()game:GetService("TeleportService"):Teleport(game.PlaceId,player)end)
 if not ok then label.Text="Reconnect was unavailable. Please leave and join this same experience again."end
 task.delay(10,function()busy=false;retry.Text="Reconnect to WorldConquest"end)
end)
while gui.Parent do
 local failure=player:GetAttribute("WCStartupError")
 local ready=player:GetAttribute("WCMenuReady")or player:GetAttribute("WCRendererReady")
 local loading=player:GetAttribute("WCLoading")==true
 gui.Enabled=not ready or loading or failure~=nil
 if failure then label.Text="WorldConquest couldn't finish loading.\n"..tostring(failure).."\nPlease reconnect.";retry.Visible=true
 elseif os.clock()-began>30 and gui.Enabled then label.Text="Loading is taking longer than expected.\n"..(player:GetAttribute("WCLoadingStatus")or "Waiting for the server…");retry.Visible=true
 else label.Text="WORLD CONQUEST\n"..(player:GetAttribute("WCLoadingStatus")or "Connecting…");retry.Visible=false end
 task.wait(.25)
end
