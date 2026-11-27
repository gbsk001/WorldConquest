local premiumRemote={OnClientEvent=signal()};local partyRemote={OnClientEvent=signal()};local requests={};local purchases=0
function premiumRemote:FireServer(a,d)table.insert(requests,{Action=a,Data=d})end
function partyRemote:FireServer(a,d)table.insert(requests,{Action="Party:"..a,Data=d})end
local localPlayer={UserId=101,Name="AcceptanceTester"}
local services={Players={LocalPlayer=localPlayer},ReplicatedStorage={WaitForChild=function(_,name)return if name=="WorldConquestProgression"then premiumRemote else partyRemote end},MarketplaceService={PromptGamePassPurchase=function()purchases+=1 end,PromptProductPurchase=function()purchases+=1 end},SocialService={CanSendGameInviteAsync=function()return false end}}
services.MarketplaceService.PromptProductPurchaseFinished=signal();services.MarketplaceService.PromptGamePassPurchaseFinished=signal()
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
 local bounds={}
 for _,b in ipairs(content:GetChildren())do if b.ClassName=="TextButton"then
  local w,h=content.AbsoluteSize.X,content.AbsoluteSize.Y
  local x,y=b.Position.X.Scale*w+b.Position.X.Offset,b.Position.Y.Scale*h+b.Position.Y.Offset
  local bw,bh=b.Size.X.Scale*w+b.Size.X.Offset,b.Size.Y.Scale*h+b.Size.Y.Offset
  assert(x>=0 and x+bw<=w+.01 and y>=0 and y+bh<=content.CanvasSize.Y.Offset+.01,"Home control outside scrollable bounds: "..b.Name)
  for _,a in ipairs(bounds)do assert(x>=a[1]+a[3]or a[1]>=x+bw or y>=a[2]+a[4]or a[2]>=y+bh,"Home buttons overlap: "..b.Name.." / "..a[5])end
  table.insert(bounds,{x,y,bw,bh,b.Name})
 end end
end
assert(playCount==5)
page="Flags";render();click("Unlock • 120 Stars");assert(requests[#requests].Action=="Buy"and requests[#requests].Data=="flag_aurora")
page="Daily";render();click("Claim daily reward");assert(requests[#requests].Action=="Daily")
page="Party";render();click("Create party");assert(requests[#requests].Action=="Party:Create")
partyRemote.OnClientEvent:Fire({Members={{UserId=101,Name="AcceptanceTester",Leader=true},{UserId=102,Name="Friend"}},Leader=101})
click("Remove");assert(requests[#requests].Action=="Party:Kick"and requests[#requests].Data==102)
page="Starter";render();click("Not Now");assert(page=="Home"and purchases==0)
local owned=Rules.new();owned.Owned.missile_pearl=true
premiumRemote.OnClientEvent:Fire({Profile=owned,Now=100*86400,Temporary=false,PurchasesEnabled=true,Offers={Starter={ID=2098697285,Kind="Pass"}}})
page="Starter";render();click("Purchase • 49 Robux");assert(purchases==1,"stub prompt only")
services.MarketplaceService.PromptGamePassPurchaseFinished:Fire(localPlayer,2098697285,false)
assert(message.Text=="Purchase cancelled.")
assert(not owned.Owned.flag_founder,"client prompt must not grant items")
-- A later disable must invalidate delayed client price lookups and old button callbacks.
local staleButton=content:FindFirstChild("Purchase • 49 Robux")
premiumRemote.OnClientEvent:Fire({Profile=owned,Temporary=false,PurchasesEnabled=false,Offers={}})
staleButton.Activated:Fire();assert(purchases==1,"disabled stale callback must not open a prompt")
local realSpawn=task.spawn;local pendingPrices={};task.spawn=function(fn,...)table.insert(pendingPrices,{Fn=fn,Args={...}})end
services.MarketplaceService.GetProductInfoAsync=function(_,id)assert(id==2099891345);return {IsForSale=true,PriceInRobux=399}end
premiumRemote.OnClientEvent:Fire({Profile=owned,Temporary=false,PurchasesEnabled=true,Offers={General={ID=2099891345,Kind="Pass"}}})
premiumRemote.OnClientEvent:Fire({Profile=owned,Temporary=false,PurchasesEnabled=false,Offers={}})
for _,pending in ipairs(pendingPrices)do pending.Fn(table.unpack(pending.Args))end;task.spawn=realSpawn
page="General";render();assert(not content:FindFirstChild("Purchase • 399 Robux"),"late response must not revive disabled offer")
premiumRemote.OnClientEvent:Fire({Profile=owned,Temporary=false,PurchasesEnabled=true,Offers={General={ID=2099891345,Kind="Pass"}}})
page="General";render();click("Purchase • 399 Robux");assert(purchases==2)
services.MarketplaceService.PromptGamePassPurchaseFinished:Fire(localPlayer,2099891345,false)
premiumRemote.OnClientEvent:Fire({Profile=owned,Temporary=true,PurchasesEnabled=true,Offers={General={ID=2099891345,Kind="Pass"}}})
page="General";render();assert(not content:FindFirstChild("Purchase • 399 Robux"),"Studio cannot enable purchases")
local packOffers={};local actualPrices={};local expectedAmounts={}
for i,product in ipairs(ProductionCommerceConfig.StarsProducts)do
 packOffers["Stars"..product.Stars]={ID=product.ID,Kind="Product",Stars=product.Stars}
 actualPrices[product.ID]=i*13 -- Deliberately different from intended base prices.
 expectedAmounts[product.ID]=product.Stars
end
services.MarketplaceService.GetProductInfoAsync=function(_,id)return {IsForSale=true,PriceInRobux=assert(actualPrices[id])}end
local prompts={};services.MarketplaceService.PromptProductPurchase=function(_,who,id)assert(who==localPlayer);table.insert(prompts,id)end
for _,size in ipairs({{390,844},{844,390},{768,1024},{1024,768},{1920,1080}})do
 gui.AbsoluteSize=Vector2.new(size[1],size[2]);content.AbsoluteSize=Vector2.new(size[1]-40,size[2]-80)
 premiumRemote.OnClientEvent:Fire({Profile=owned,Temporary=false,PurchasesEnabled=true,Offers=packOffers})
 for _,pageName in ipairs({"Shop","Arsenal","Flags","Territory","Inventory"})do
  page=pageName;render()
  for _,product in ipairs(ProductionCommerceConfig.StarsProducts)do
   local caption="Buy "..product.Stars.." Stars • "..actualPrices[product.ID].." Robux"
   local b=content:FindFirstChild(caption);assert(b and b.Size.Y.Offset>=44)
   assert(content.CanvasSize.Y.Offset>=b.Position.Y.Offset+b.Size.Y.Offset)
   local count=#prompts;click(caption);click(caption);assert(#prompts==count+1 and prompts[#prompts]==product.ID,"only one official prompt at a time")
   services.MarketplaceService.PromptProductPurchaseFinished:Fire(localPlayer.UserId,product.ID,true)
   assert(message.Text=="Waiting for Roblox verification and a successful save…")
   assert(owned.Stars==0,"closing a prompt must not grant currency")
  end
 end
end
page="Shop";render()
local first=ProductionCommerceConfig.StarsProducts[1];local oldPrice=actualPrices[first.ID];actualPrices[first.ID]=oldPrice+1
local count=#prompts;click("Buy 100 Stars • "..oldPrice.." Robux");assert(#prompts==count and message.Text=="Roblox updated this price. Review it and select Purchase again.")
click("Buy 100 Stars • "..actualPrices[first.ID].." Robux");assert(#prompts==count+1)
premiumRemote.OnClientEvent:Fire({Profile=owned,Temporary=false,PurchasesEnabled=true,Offers=packOffers,ConfirmedProduct=first.ID,Message="Purchase verified: 100 Stars saved."})
services.MarketplaceService.PromptProductPurchaseFinished:Fire(localPlayer.UserId,first.ID,true)
assert(message.Text=="Purchase verified: 100 Stars saved.","native close must not replace server confirmation")
print("Four Stars purchase controls: five shop pages across phone/tablet/desktop sizes, Managed Prices, exact prompt IDs, double-tap prevention, price changes, cancellation and no premature confirmation passed (GUI/service stubs).")
gui.Enabled=false;local count=#objects;partyRemote.OnClientEvent:Fire({Members={}});assert(#objects==count,"hidden menu must not allocate")
print("Stage 13 production premium UI: twelve pages at five viewport sizes, touch targets, canvas bounds, purchase/claim/equip routes, party controls, disabled offers and hidden-menu allocation passed. Graphical layout stubs, not rendered Roblox; purchase prompt simulated.")
