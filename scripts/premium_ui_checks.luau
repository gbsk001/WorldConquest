local premiumRemote={OnClientEvent=signal()};local partyRemote={OnClientEvent=signal()};local requests={};local purchases=0
function premiumRemote:FireServer(a,d)table.insert(requests,{Action=a,Data=d})end
function partyRemote:FireServer(a,d)table.insert(requests,{Action="Party:"..a,Data=d})end
local localPlayer={UserId=101,Name="AcceptanceTester"}
local services={Players={LocalPlayer=localPlayer},ReplicatedStorage={WaitForChild=function(_,name)return if name=="WorldConquestProgression"then premiumRemote else partyRemote end},MarketplaceService={PromptGamePassPurchase=function()purchases+=1 end,PromptProductPurchase=function()purchases+=1 end},SocialService={CanSendGameInviteAsync=function()return false end}}
services.MarketplaceService.GetProductInfoAsync=function()return {IsForSale=true,PriceInRobux=49}end
local original=game.GetService;function game:GetService(name)return services[name]or original(self,name)end
task.spawn=function(fn,...)fn(...)end
-- MODULE --
local gui=Instance.new("ScreenGui");gui.Enabled=true;local content=Instance.new("ScrollingFrame");local layout=Instance.new("UIListLayout");local message=Instance.new("TextLabel");local page="Home";local menu;local playCount=0
local function render()
 for _,o in ipairs(content:GetChildren())do if o~=layout then o:Destroy()end end;layout.Parent=content
 assert(menu.render(page,{Screen="Menu"}),page)
end
menu=Premium.new(gui,content,layout,function(value)page=value;render()end,function()if menu then render()end end,function()playCount+=1 end,message)
premiumRemote.OnClientEvent:Fire({Profile=Rules.new(),Now=100*86400,Temporary=true,Featured="flag_aurora",RefreshAt=101*86400})
local function click(text)
 for _,o in ipairs(content:GetDescendants())do if o.ClassName=="TextButton"and o.Text==text then o.Activated:Fire();return end end
 error("Missing control: "..text)
end
for _,size in ipairs({{390,844},{844,390},{768,1024},{1024,768},{1920,1080}})do
 gui.AbsoluteSize=Vector2.new(size[1],size[2]);content.AbsoluteSize=Vector2.new(size[1]-40,size[2]-80)
 for _,target in ipairs({"Home","Shop","Flags","Arsenal","Inventory","Territory","Daily","Starter","General","Profile","Global","Party"})do
  page=target;render()
  for _,o in ipairs(content:GetDescendants())do if o.ClassName=="TextButton"then assert(o.Size.Y.Offset>=44,"touch target")end end
 end
 page="Home";render();click("PLAY");assert(content.CanvasSize.Y.Offset>=content:FindFirstChild("Global Rankings").Position.Y.Offset+44)
end
assert(playCount==5)
page="Flags";render();click("Unlock • 120 Stars");assert(requests[#requests].Action=="Buy"and requests[#requests].Data=="flag_aurora")
page="Daily";render();click("Claim daily reward");assert(requests[#requests].Action=="Daily")
page="Party";render();click("Create party");assert(requests[#requests].Action=="Party:Create")
partyRemote.OnClientEvent:Fire({Members={{UserId=101,Name="AcceptanceTester",Leader=true},{UserId=102,Name="Friend"}},Leader=101})
click("Remove");assert(requests[#requests].Action=="Party:Kick"and requests[#requests].Data==102)
page="Starter";render();click("Not Now");assert(page=="Home"and purchases==0)
local owned=Rules.new();owned.Owned.missile_pearl=true
premiumRemote.OnClientEvent:Fire({Profile=owned,Now=100*86400,Temporary=false,Offers={Starter={ID=123,Price=49,Kind="Pass"}}})
page="Starter";render();click("Purchase • 49 Robux");assert(purchases==1,"stub prompt only")
assert(not owned.Owned.flag_founder,"client prompt must not grant items")
gui.Enabled=false;local count=#objects;partyRemote.OnClientEvent:Fire({Members={}});assert(#objects==count,"hidden menu must not allocate")
print("Stage 13 production premium UI: twelve pages at five viewport sizes, touch targets, canvas bounds, purchase/claim/equip routes, party controls, disabled offers and hidden-menu allocation passed. Graphical layout stubs, not rendered Roblox; purchase prompt simulated.")
