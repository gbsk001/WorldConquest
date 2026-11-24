--!strict
-- Native Roblox voice for a 2D game without characters. No audio is recorded.
local Policy=require(script.Parent.CommunicationPolicy)
local Communication={}
function Communication.new(session)
 local Players=game:GetService("Players");local Voice=game:GetService("VoiceChatService")
 local inputs={};local epoch=0
 local function silence()
  for _,input in pairs(inputs)do input:SetUserIdAccessList({})end
  for _,p in ipairs(Players:GetPlayers())do p:SetAttribute("WCVoiceAvailable",false);p:SetAttribute("WCVoiceStatus","Checking Roblox communication permissions")end
 end
 function session.CommunicationChanged()epoch+=1;silence()end
 local function refresh()
  local list=Players:GetPlayers();table.sort(list,function(a,b)return a.UserId<b.UserId end)
  local snapshot=epoch
  local ok,groups=pcall(function()return Voice:GetChatGroupsAsync(list)end)
  if not ok or type(groups)~="table"or #groups~=#list or snapshot~=epoch then silence();return end
  for i,p in ipairs(list)do
   if p.Parent~=Players then continue end
   local permitted={};local scope=session.CommunicationScope(p)
   for j,other in ipairs(list)do
    if other.Parent==Players and Policy.allowed(p.UserId,other.UserId,groups[i],groups[j],scope,session.CommunicationScope(other))then table.insert(permitted,other.UserId)end
   end
   local input=inputs[p]
   if not input and #groups[i]>0 then
    input=Instance.new("AudioDeviceInput");input.Name="WorldConquestMicrophone";input.AccessType=Enum.AccessModifierType.Allow;input:SetUserIdAccessList({});input.Muted=true;input.Player=p;input.Parent=p;inputs[p]=input
   end
   if input then input:SetUserIdAccessList(permitted)end
   p:SetAttribute("WCVoiceAvailable",#groups[i]>0);p:SetAttribute("WCVoiceStatus",if #groups[i]>0 then "Roblox voice available"else "Voice unavailable for this account or session")
  end
 end
 local function changed(p)
  session.CommunicationChanged();p:SetAttribute("WCVoiceAvailable",false);p:SetAttribute("WCVoiceStatus","Checking Roblox communication permissions")
 end
 Players.PlayerAdded:Connect(changed)
 Players.PlayerRemoving:Connect(function(p)session.CommunicationChanged();local input=inputs[p];if input then input:Destroy()end;inputs[p]=nil end)
 for _,p in ipairs(Players:GetPlayers())do changed(p)end
 task.spawn(function()
  while true do
   local ok=pcall(refresh)
   if not ok then silence()end
   for _,p in ipairs(Players:GetPlayers())do if not inputs[p]then p:SetAttribute("WCVoiceStatus","Voice requires Roblox eligibility and experience communication settings")end end
   task.wait(15)
  end
 end)
end
return Communication
