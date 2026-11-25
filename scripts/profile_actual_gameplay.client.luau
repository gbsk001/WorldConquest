-- Original AGPL-3.0 diagnostic. Add temporarily as a LocalScript to StarterPlayerScripts.
-- Observes the actual game. Does NOT create synthetic participants or move the camera.
-- Remove before production distribution; this file is not mapped by default.project.json.
local Run=game:GetService("RunService")
local Players=game:GetService("Players")
local Stats=game:GetService("Stats")
local Http=game:GetService("HttpService")
local started=os.clock();local frames={};local total=0;local maximumMemory=0;local maxHeap=0;local interval=started
local function network(name)
 local ok,value=pcall(function()return Stats.Network.ServerStatsItem[name]:GetValue()end)
 return if ok then value else nil
end
Run.RenderStepped:Connect(function(dt)
 frames[#frames+1]=dt*1000;total+=dt*1000
 if os.clock()-interval<15 then return end
 local pg=Players.LocalPlayer:FindFirstChild("PlayerGui")
 local gameUI=pg and pg:FindFirstChild("WorldConquest")
 local canvas=gameUI and gameUI:FindFirstChild("Earth",true)
 maximumMemory=math.max(maximumMemory,Stats:GetTotalMemoryUsageMb());maxHeap=math.max(maxHeap,gcinfo()/1024)
 table.sort(frames)
 local average=total/#frames
 local row={Elapsed=os.clock()-started,Frames=#frames,FPS=1000/average,AverageMilliseconds=average,P95Milliseconds=frames[math.ceil(#frames*.95)],WorstMilliseconds=frames[#frames],TotalMemoryMiB=maximumMemory,LuauHeapMiB=maxHeap,GameVisible=gameUI and gameUI.Enabled or false,StartupMilliseconds=gameUI and gameUI:GetAttribute("StartupMilliseconds"),ReceiveKbps=network("Data Receive Kbps"),SendKbps=network("Data Send Kbps"),Renderer=canvas and canvas:GetAttributes(),Studio=Run:IsStudio(),SyntheticPopulation=false}
 print("WC_ACTUAL_GAMEPLAY "..Http:JSONEncode(row))
 table.clear(frames);total=0;interval=os.clock()
end)
