--!strict
-- Only broadcast-filtered names are saved or replicated. AGPL-3.0.
local Names=require(script.Parent.NationNames)
local Identity={}
function Identity.new(session,store)
 local Players=game:GetService("Players");local RS=game:GetService("ReplicatedStorage");local Text=game:GetService("TextService")
 local remote=Instance.new("RemoteEvent");remote.Name="WorldConquestIdentity";remote.Parent=RS
 local limits={};local generation={}
 local function reply(p,message)if p.Parent==Players then remote:FireClient(p,{Name=p:GetAttribute("WCNationName")or p.Name,Message=message})end end
 function session.DisplayName(p)return p:GetAttribute("WCNationName")or p.Name end
 function session.ProfileReady(p,profile)
  if p:GetAttribute("WCNationName")or not profile.NationName or session.Allowed[p]then return end
  local version=(generation[p]or 0)+1;generation[p]=version
  task.spawn(function()
   local filtered=Names.filter(profile.NationName,p.UserId,Text)
   if filtered and generation[p]==version and p.Parent==Players and not session.Allowed[p]then p:SetAttribute("WCNationName",filtered);reply(p)end
  end)
 end
 remote.OnServerEvent:Connect(function(p,action,value)
  local l=limits[p]or{At=-math.huge};limits[p]=l
  if l.Busy or os.clock()-l.At<3 then return end;l.At=os.clock()
  if action=="Hello"then reply(p);return end
  if action~="Set"and action~="Reset"then return end
  if session.Allowed[p]then reply(p,"Change your nation name between matches.");return end
  if not store.Cache[p.UserId]then reply(p,"Your profile is still loading. Please retry.");return end
  l.Busy=true;generation[p]=(generation[p]or 0)+1
  local filtered,message=nil,nil;if action~="Reset"then filtered,message=Names.filter(value,p.UserId,Text)end
  if action=="Reset"or filtered then
   if p.Parent~=Players or session.Allowed[p]then l.Busy=false;reply(p,"The match started; try again after this round.");return end
   local result;result,message=store.transact(p.UserId,"Nation",filtered or "")
   if result then p:SetAttribute("WCNationName",result.NationName);message="Nation name saved."end
  end
  l.Busy=false;reply(p,message)
 end)
 Players.PlayerRemoving:Connect(function(p)limits[p]=nil;generation[p]=nil end)
 for _,p in ipairs(Players:GetPlayers())do local profile=store.Cache[p.UserId];if profile then session.ProfileReady(p,profile)end end
 return remote
end
return Identity
