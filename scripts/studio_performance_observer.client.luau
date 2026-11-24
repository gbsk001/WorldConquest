-- Disposable acceptance instrumentation; never packaged in the release.
local Run=game:GetService("RunService")
local Stats=game:GetService("Stats")
local Players=game:GetService("Players")
local frames={};local began=os.clock();local total=0;local worst=0
Run.RenderStepped:Connect(function(dt)
 frames[#frames+1]=dt*1000;total=math.max(total,Stats:GetTotalMemoryUsageMb());worst=math.max(worst,dt*1000)
end)
task.spawn(function()
 while task.wait(10)do
  table.sort(frames);local sum=0;for _,v in frames do sum+=v end
  if #frames>0 then print(string.format("LIVE_CLIENT elapsed %.1f fps %.2f avg %.3f p95 %.3f worst %.3f totalMiB %.2f heapMiB %.2f",os.clock()-began,1000/(sum/#frames),sum/#frames,frames[math.ceil(#frames*.95)],frames[#frames],total,gcinfo()/1024))end
  table.clear(frames)
  for _,v in game.ReplicatedStorage:GetDescendants()do
   if v:IsA("RemoteEvent")and v:GetAttribute("SimulationTick")then
    -- Studio truncates long log entries; keep measurements independently readable.
    local values=v:GetAttributes();local keys={};for key in pairs(values)do table.insert(keys,key)end;table.sort(keys)
    for i=1,#keys,8 do
     local group={};for j=i,math.min(i+7,#keys)do group[keys[j]]=values[keys[j]]end
     print("LIVE_SERVER",game:GetService("HttpService"):JSONEncode(group))
    end
   end
  end
  local ok,values=pcall(function()
   return {ReceiveKBps=Stats.DataReceiveKbps,SendKBps=Stats.DataSendKbps}
  end)
  if ok then print("LIVE_NETWORK",game:GetService("HttpService"):JSONEncode(values))end
  local gui=Players.LocalPlayer.PlayerGui:FindFirstChild("WorldConquest")
  if gui then
   print("LIVE_STARTUP",gui:GetAttribute("StartupMilliseconds"))
   local earth=gui:FindFirstChild("Earth",true)
   if earth then print("LIVE_RENDER",game:GetService("HttpService"):JSONEncode(earth:GetAttributes()))end
  end
 end
end)
