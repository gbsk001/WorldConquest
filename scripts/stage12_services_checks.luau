-- Execute the actual server adapters with explicitly simulated Roblox services.
local function signal()
 local callbacks={};return {Connect=function(_,fn)table.insert(callbacks,fn);return {Disconnect=function()end}end,Fire=function(_,...)for _,fn in ipairs(callbacks)do fn(...)end end}
end
local services={};local game={GetService=function(_,key)return assert(services[key],key)end}
local remotes={};local Instance={new=function(class)
 local o={ClassName=class,OnServerEvent=signal(),Destroyed=false}
 function o:FireClient(p,value)self.Last=value;self.Recipient=p end
 function o:SetUserIdAccessList(ids)self.Access=ids end
 function o:Destroy()self.Destroyed=true end
 table.insert(remotes,o);return o
end}
Enum.AccessModifierType={Allow="Allow"}
local current=100;local os={clock=function()return current end}
local tasks={};local task={spawn=function(fn,...)local co=coroutine.create(fn);local ok,err=coroutine.resume(co,...);assert(ok,err);table.insert(tasks,co)end,wait=function()coroutine.yield()end}
local people={};local Players={PlayerAdded=signal(),PlayerRemoving=signal(),GetPlayers=function()return people end}
local function person(id)
 local p={UserId=id,Name="Account"..id,Parent=Players,Attributes={}}
 function p:GetAttribute(k)return self.Attributes[k]end
 function p:SetAttribute(k,v)self.Attributes[k]=v end
 table.insert(people,p);return p
end
local one=person(1);local two=person(2)
services.Players=Players;services.ReplicatedStorage={};local filterDown=false
services.TextService={FilterStringAsync=function(_,text)
 if filterDown then error("filter unavailable")end
 return {GetNonChatStringForBroadcastAsync=function()return if text=="Rejected"then "########"else text end}
end}
local groupsDown=false
services.VoiceChatService={GetChatGroupsAsync=function()if groupsDown then error("permission service unavailable")end;return {{"eligible"},{"eligible"}}end}
-- MODULES --
local identityDisk={};local store={Cache={[1]={},[2]={}}};local identityDown=false
function store.transact(id,action,value)
 assert(action=="Nation");if identityDown then return nil,"offline"end
 identityDisk[id]={NationName=if value==""then nil else value};return identityDisk[id]
end
local bridge={Allowed={}}
local remote=Identity.new(bridge,store)
remote.OnServerEvent:Fire(one,"Set","日本国");assert(one:GetAttribute("WCNationName")=="日本国" and identityDisk[1].NationName=="日本国")
remote.OnServerEvent:Fire(one,"Reset");assert(one:GetAttribute("WCNationName")=="日本国","rate limit")
current+=4;remote.OnServerEvent:Fire(one,"Set","Rejected");assert(one:GetAttribute("WCNationName")=="日本国")
filterDown=true;current+=4;remote.OnServerEvent:Fire(one,"Set","Raw secret");assert(one:GetAttribute("WCNationName")=="日本国");filterDown=false
identityDown=true;current+=4;remote.OnServerEvent:Fire(one,"Set","Valid name");assert(one:GetAttribute("WCNationName")=="日本国");identityDown=false
bridge.Allowed[one]=true;current+=4;remote.OnServerEvent:Fire(one,"Reset");assert(one:GetAttribute("WCNationName")=="日本国");bridge.Allowed[one]=nil
current+=4;remote.OnServerEvent:Fire(one,"Reset");assert(one:GetAttribute("WCNationName")==nil and bridge.DisplayName(one)==one.Name)
bridge.ProfileReady(two,{NationName="Rejected"});assert(two:GetAttribute("WCNationName")==nil)
bridge.ProfileReady(two,{NationName="République"});assert(bridge.DisplayName(two)=="République")
local scope={[one]="public",[two]="public"};bridge.CommunicationScope=function(p)return scope[p]end
Communication.new(bridge)
local microphones={};for _,o in ipairs(remotes)do if o.ClassName=="AudioDeviceInput"then microphones[o.Player]=o end end
assert(microphones[one].Muted and microphones[two].Muted)
assert(#microphones[one].Access==1 and microphones[one].Access[1]==2)
local loop=tasks[#tasks]
scope[two]="private";bridge.CommunicationChanged();assert(#microphones[one].Access==0 and not one:GetAttribute("WCVoiceAvailable"))
assert(coroutine.resume(loop));assert(#microphones[one].Access==0 and #microphones[two].Access==0)
scope[two]="public";bridge.CommunicationChanged();assert(coroutine.resume(loop));assert(#microphones[one].Access==1)
groupsDown=true;assert(coroutine.resume(loop));assert(#microphones[one].Access==0 and not one:GetAttribute("WCVoiceAvailable"))
Players.PlayerRemoving:Fire(two);assert(microphones[two].Destroyed)
print("Production IdentityServer: filtered-only persistence, filter/storage outages, reset, cooldown, match lock and re-filter on load passed.")
print("Production CommunicationServer: default microphone mute, same-scope routing, immediate revocation, private isolation, permission outage and disconnect cleanup passed. Audio/Roblox permission APIs simulated.")
