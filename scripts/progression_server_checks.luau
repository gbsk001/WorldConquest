assert(ProductionCommerceConfig.StarterPassID==2098697285 and ProductionCommerceConfig.GeneralPassID==2099891345)
assert(ProductionCommerceConfig.EnablePaidPurchasePrompts==false)
assert(#ProductionCommerceConfig.PurchaseTestUserIDs==1 and ProductionCommerceConfig.PurchaseTestUserIDs[1]==11327713454)
local expectedStars={[3735920468]=100,[3735920863]=500,[3735920948]=1000,[3735921042]=5000}
assert(#ProductionCommerceConfig.StarsProducts==4)
for _,product in ipairs(ProductionCommerceConfig.StarsProducts)do assert(expectedStars[product.ID]==product.Stars)end
local commerceConfig=table.clone(ProductionCommerceConfig)
commerceConfig.DataStoreName="TEST";commerceConfig.EnablePaidPurchasePrompts=true;commerceConfig.PurchaseTestUserIDs={}
local liveStore={};local failSave=false;local storedDS={UpdateAsync=function(_,key,fn)if failSave then error("offline")end;liveStore[key]=fn(liveStore[key]);return liveStore[key]end}
local dataService={GetDataStore=function()return storedDS end,GetOrderedDataStore=function()return {UpdateAsync=function()end,GetSortedAsync=function()return{GetCurrentPage=function()return {}end}end}end}
local persons={};local playerService={PlayerAdded=signal(),PlayerRemoving=signal()}
function playerService:GetPlayers()return persons end
function playerService:GetPlayerByUserId(id)for _,p in ipairs(persons)do if p.UserId==id then return p end end end
local human={UserId=101,Name="Human",Parent=playerService};persons={human}
local marketService={PromptGamePassPurchaseFinished=signal(),GetProductInfoAsync=function()return {IsForSale=true,PriceInRobux=49}end,UserOwnsGamePassAsync=function()return false end}
marketService.GetPassOwnershipAsync=function()return {Owned=false,Active=true}end
local serverRemotes={};local oldInstance=Instance.new
Instance.new=function(class)
 local obj=oldInstance(class)
 if class=="RemoteEvent"then obj.OnServerEvent=signal();obj.ByUser={};function obj:FireClient(p,payload)self.Last=payload;self.ByUser[p.UserId]=payload end;table.insert(serverRemotes,obj)end
 return obj
end
services.Players=playerService;services.MarketplaceService=marketService;services.DataStoreService=dataService;services.RunService={IsStudio=function()return false end};services.BadgeService={AwardBadgeAsync=function()end}
task.wait=function()end
-- MODULE --
local bridge={Allowed={[human]=true},ActiveID="verifiedMatch",MatchKind="Public"}
local server=ProgressionServer.new(bridge);local net=serverRemotes[#serverRemotes]
assert(liveStore.u101 and liveStore.u101.Stars==0)
assert(not liveStore.u101.Owned.flag_founder,"active trial must not grant permanent pass items")
assert(net.Last.Profile.Receipts==nil and net.Last.Profile.Matches==nil,"do not replicate ledgers")
local receipt={PlayerId=101,ProductId=3735920863,PurchaseId="real-service-stub-id"}
assert(marketService.ProcessReceipt(receipt)==Enum.ProductPurchaseDecision.PurchaseGranted)
assert(marketService.ProcessReceipt(receipt)==Enum.ProductPurchaseDecision.PurchaseGranted and liveStore.u101.Stars==500)
receipt.ProductId=999;assert(marketService.ProcessReceipt(receipt)==Enum.ProductPurchaseDecision.NotProcessedYet)
receipt.ProductId=3735920863;receipt.PurchaseId="failure";failSave=true;assert(marketService.ProcessReceipt(receipt)==Enum.ProductPurchaseDecision.NotProcessedYet);assert(not liveStore.u101.Receipts.failure and not net.Last.ConfirmedProduct);failSave=false
assert(marketService.ProcessReceipt(receipt)==Enum.ProductPurchaseDecision.PurchaseGranted)
assert(liveStore.u101.Stars==1000 and net.Last.ConfirmedProduct==3735920863)
for id,quantity in pairs(expectedStars)do
 local payment={PlayerId=101,ProductId=id,PurchaseId="quantity-"..id,CurrencySpent=1}
 local oldStars=liveStore.u101.Stars
 assert(marketService.ProcessReceipt(payment)==Enum.ProductPurchaseDecision.PurchaseGranted)
 assert(liveStore.u101.Stars==oldStars+quantity,"Managed Price must not change quantity")
 assert(marketService.ProcessReceipt(payment)==Enum.ProductPurchaseDecision.PurchaseGranted and liveStore.u101.Stars==oldStars+quantity)
end
assert(marketService.ProcessReceipt({PlayerId=999,ProductId=3735920468,PurchaseId="absent"})==Enum.ProductPurchaseDecision.NotProcessedYet)
assert(marketService.ProcessReceipt({PlayerId=101,ProductId=3735920468})==Enum.ProductPurchaseDecision.NotProcessedYet)
local originalUpdate=storedDS.UpdateAsync;local attempts=0
storedDS.UpdateAsync=function(self,key,fn)attempts+=1;if attempts==1 then error("transient save failure")end;return originalUpdate(self,key,fn)end
assert(marketService.ProcessReceipt({PlayerId=101,ProductId=3735920468,PurchaseId="retry-in-callback"})==Enum.ProductPurchaseDecision.PurchaseGranted and attempts==2)
storedDS.UpdateAsync=originalUpdate
-- Simulate a durable commit followed by a lost response: retry must not double-credit.
local committed=false;local priorBalance=liveStore.u101.Stars
storedDS.UpdateAsync=function(self,key,fn)local result=originalUpdate(self,key,fn);if not committed then committed=true;error("connection lost after commit")end;return result end
assert(marketService.ProcessReceipt({PlayerId=101,ProductId=3735920948,PurchaseId="lost-save-response"})==Enum.ProductPurchaseDecision.PurchaseGranted)
assert(liveStore.u101.Stars==priorBalance+1000);storedDS.UpdateAsync=originalUpdate
local sim={Tick=0,StartTick=0,Phase="Started",Players={[101]={UserId=101,SmallId=1,Troops=12000}},Grid={Counts={[1]=25000}},Match={Winner={UserId=101}}}
bridge.Observe(sim,{})
for i=1,6 do sim.Tick=i*300;sim.Players[101].TileVersion=i*100;bridge.Observe(sim,{{UserId=101,Message="Expanding along all eligible neutral borders."}})end
sim.Phase="Victory";bridge.Observe(sim,{})
assert(liveStore.u101.Stats.Matches==1 and liveStore.u101.Stats.Wins==1 and liveStore.u101.Owned.flag_victor)
local balance=liveStore.u101.Stars;bridge.Observe(sim,{});assert(liveStore.u101.Stars==balance)
bridge.ActiveID="privateMatch";bridge.MatchKind="Private";sim.Tick=0;sim.Phase="Started";bridge.Observe(sim,{})
for i=1,6 do sim.Tick=i*300;sim.Players[101].TileVersion=i*100;bridge.Observe(sim,{{UserId=101,Message="Expanding along all eligible neutral borders."}})end
sim.Phase="Victory";bridge.Observe(sim,{});assert(liveStore.u101.Stars==balance)
bridge.ActiveID="afkMatch";bridge.MatchKind="Public";sim.Tick=0;sim.Phase="Started";bridge.Observe(sim,{})
sim.Tick=2000;sim.Phase="Victory";bridge.Observe(sim,{});assert(liveStore.u101.Stars==balance)
local meta={Players={{UserId=101}}};bridge.Decorate(meta);assert(meta.Players[1].Cosmetics.Flag==nil,"No automatically equipped flags")
net.OnServerEvent:Fire(human,"Match","fake");assert(liveStore.u101.Stars==balance)
print("Stage 13 production server: receipt retry/idempotency, unknown product, DataStore outage deferral, authoritative completion/victory, private/AFK exclusion, no client reward endpoint and cosmetic projection passed. Roblox services simulated; no live purchase or persistence verification.")
local purchased={};local checkCount=0
marketService.GetPassOwnershipAsync=function(_,player,id)
 assert(player==human and (id==2098697285 or id==2099891345));checkCount+=1
 return {Owned=purchased[id]==true,Active=true}
end
marketService.PromptGamePassPurchaseFinished:Fire(human,999,true);assert(checkCount==0)
marketService.PromptGamePassPurchaseFinished:Fire(human,commerceConfig.StarterPassID,false);assert(checkCount==0)
marketService.PromptGamePassPurchaseFinished:Fire(human,commerceConfig.StarterPassID,true);assert(not liveStore.u101.Owned.flag_founder,"trial signal is not a purchase")
purchased[commerceConfig.StarterPassID]=true
failSave=true;marketService.PromptGamePassPurchaseFinished:Fire(human,commerceConfig.StarterPassID,true);assert(not liveStore.u101.Entitlements.Starter);failSave=false
marketService.PromptGamePassPurchaseFinished:Fire(human,commerceConfig.StarterPassID,true)
for _,id in ipairs(Catalog.PassItems.Starter)do assert(liveStore.u101.Owned[id],id)end
for _,id in ipairs(Catalog.PassItems.General)do assert(not liveStore.u101.Owned[id],"Starter must not grant General")end
local before=liveStore.u101.Revision;marketService.PromptGamePassPurchaseFinished:Fire(human,commerceConfig.StarterPassID,true);assert(liveStore.u101.Revision==before)
purchased[commerceConfig.GeneralPassID]=true
marketService.PromptGamePassPurchaseFinished:Fire(human,commerceConfig.GeneralPassID,true)
for _,id in ipairs(Catalog.PassItems.General)do assert(liveStore.u101.Owned[id],id)end
assert(liveStore.u101.Stars==balance,"passes grant cosmetics only")
assert(server.Store.transact(101,"Equip","flag_general").Equipped.Flag=="flag_general")
-- Fresh production adapter/cache, same simulated durable storage: rejoin restores rewards.
commerceConfig.EnablePaidPurchasePrompts=false
local infoCalls=0;marketService.GetProductInfoAsync=function()infoCalls+=1;return {IsForSale=true,PriceInRobux=399}end
local restored=ProgressionServer.new({Allowed={}});local restoredNet=serverRemotes[#serverRemotes]
assert(restoredNet.Last.PurchasesEnabled==false and next(restoredNet.Last.Offers)==nil and infoCalls==0)
assert(restored.Store.Cache[101].Equipped.Flag=="flag_general")
for _,ids in pairs(Catalog.PassItems)do for _,id in ipairs(ids)do assert(restored.Store.Cache[101].Owned[id],id)end end
local rev=liveStore.u101.Revision
ProgressionServer.new({Allowed={}});assert(liveStore.u101.Revision==rev,"rejoin must not duplicate permanent grants")
-- Fail closed on unsupported/malformed ownership APIs; keep already saved earned inventory intact.
liveStore.u101=nil;marketService.GetPassOwnershipAsync=function()return nil end
local malformed=ProgressionServer.new({Allowed={}});assert(not malformed.Store.Cache[101].Entitlements.Starter)
marketService.GetPassOwnershipAsync=nil
local unsupported=ProgressionServer.new({Allowed={}});assert(not unsupported.Store.Cache[101].Entitlements.General)
marketService.GetPassOwnershipAsync=function()error("Roblox ownership unavailable")end
local unavailable=ProgressionServer.new({Allowed={}});assert(not unavailable.Store.Cache[101].Owned.missile_founder)
-- Existing genuine buyers can restore both passes even with all new prompts disabled.
marketService.GetPassOwnershipAsync=function()return {Owned=true,Active=true}end
local disabled=ProgressionServer.new({Allowed={}});assert(disabled.Store.Cache[101].Entitlements.Starter and disabled.Store.Cache[101].Entitlements.General)
assert(serverRemotes[#serverRemotes].Last.PurchasesEnabled==false and next(serverRemotes[#serverRemotes].Last.Offers)==nil)
-- Receipts are still fulfilled while advertising/prompts are disabled.
local repeated={PlayerId=101,ProductId=3735921042,PurchaseId="cross-server-5000"}
local handlerA=marketService.ProcessReceipt;assert(handlerA(repeated)==Enum.ProductPurchaseDecision.PurchaseGranted)
local newServer=ProgressionServer.new({Allowed={}});local handlerB=marketService.ProcessReceipt
assert(handlerB(repeated)==Enum.ProductPurchaseDecision.PurchaseGranted and handlerA(repeated)==Enum.ProductPurchaseDecision.PurchaseGranted)
assert(liveStore.u101.Stars==5000 and newServer.Store.Cache[101].Stars==5000)
assert(newServer.Store.transact(101,"Buy","flag_aurora").Owned.flag_aurora)
assert(newServer.Store.transact(101,"Equip","flag_aurora").Equipped.Flag=="flag_aurora")
local persistent=ProgressionServer.new({Allowed={}});assert(persistent.Store.Cache[101].Stars==4880 and persistent.Store.Cache[101].Equipped.Flag=="flag_aurora")
-- Balance caps must defer rather than acknowledge a truncated paid grant.
liveStore.u101.Stars=999999950
assert(marketService.ProcessReceipt({PlayerId=101,ProductId=3735920468,PurchaseId="cap"})==Enum.ProductPurchaseDecision.NotProcessedYet)
assert(liveStore.u101.Stars==999999950 and not liveStore.u101.Receipts.cap)
commerceConfig.PurchaseTestUserIDs={101};ProgressionServer.new({Allowed={}})
assert(serverRemotes[#serverRemotes].Last.PurchasesEnabled==true,"explicit listed test account")
commerceConfig.PurchaseTestUserIDs={102};ProgressionServer.new({Allowed={}})
assert(serverRemotes[#serverRemotes].Last.PurchasesEnabled==false and next(serverRemotes[#serverRemotes].Last.Offers)==nil,"unlisted users must remain disabled")
commerceConfig.PurchaseTestUserIDs={}
-- Exercise the delivered allowlist with both accounts present in the same server.
-- A matching display/username cannot authorize a different numeric UserId.
local owner={UserId=11327713454,Name="Owi00013",Parent=playerService}
local outsider={UserId=102,Name="Owi00013",Parent=playerService}
persons={owner,outsider};commerceConfig.PurchaseTestUserIDs=table.clone(ProductionCommerceConfig.PurchaseTestUserIDs)
marketService.GetPassOwnershipAsync=function()return {Owned=false,Active=false}end
local controlled=ProgressionServer.new({Allowed={}});local controlledNet=serverRemotes[#serverRemotes]
local permitted=controlledNet.ByUser[owner.UserId];local denied=controlledNet.ByUser[outsider.UserId]
assert(commerceConfig.EnablePaidPurchasePrompts==false and permitted.PurchasesEnabled and not denied.PurchasesEnabled)
assert(next(denied.Offers)==nil,"non-tester must receive no purchase offers")
assert(permitted.Offers.Starter.ID==2098697285 and permitted.Offers.General.ID==2099891345)
local count=0;for _ in pairs(permitted.Offers)do count+=1 end;assert(count==6)
for product,quantity in pairs(expectedStars)do
 assert(permitted.Offers["Stars"..quantity].ID==product)
 local purchase={PlayerId=owner.UserId,ProductId=product,PurchaseId="owner-"..product}
 assert(marketService.ProcessReceipt(purchase)==Enum.ProductPurchaseDecision.PurchaseGranted)
 assert(marketService.ProcessReceipt(purchase)==Enum.ProductPurchaseDecision.PurchaseGranted)
end
assert(controlled.Store.Cache[owner.UserId].Stars==6600)
marketService.GetPassOwnershipAsync=function(_,p)return {Owned=p.UserId==owner.UserId,Active=true}end
local ownerRejoin=ProgressionServer.new({Allowed={}})
assert(ownerRejoin.Store.Cache[owner.UserId].Stars==6600)
for _,items in pairs(Catalog.PassItems)do for _,item in ipairs(items)do assert(ownerRejoin.Store.Cache[owner.UserId].Owned[item])end end
assert(not ownerRejoin.Store.Cache[outsider.UserId].Entitlements.Starter)
services.RunService.IsStudio=function()return true end
ProgressionServer.new({Allowed={}})
assert(not serverRemotes[#serverRemotes].ByUser[owner.UserId].PurchasesEnabled,"Studio must not bypass the paid-prompt gate")
services.RunService.IsStudio=function()return false end
persons={human};commerceConfig.PurchaseTestUserIDs={}
print("Delivered Owi00013 numeric allowlist: all six offers, same-name outsider denied, four receipt quantities/duplicates, 6600 Stars and both pass reward sets restored in a fresh service instance; Studio remains disabled. Simulated Roblox services only.")
print("Configured real pass IDs: exact separate reward sets, trial/cancel/unknown-ID rejection, failed-save retry, duplicate-event safety, cosmetics-only grants, disabled prompts and fresh-server inventory/equipment persistence passed with simulated Roblox storage/ownership APIs.")
print("All four configured Stars products: exact quantities independent of price, atomic receipt/balance writes, duplicate/reordered/cross-server delivery, save retry/outage, absent player, malformed ID, disabled-prompt fulfilment, cosmetic spending/equip persistence and balance-cap deferral passed (service stubs, no Robux spent).")
for _,population in ipairs({20,100,250,500})do
 bridge.ActiveID="observer"..population;sim.Phase="Started";sim.Tick=0
 for id=2,population do sim.Players[-id]={UserId=-id,SmallId=id,IsBot=true,Troops=10000};sim.Grid.Counts[id]=1000 end
 local samples={};local total=0;local beforeKB=gcinfo()
 for i=1,1000 do sim.Tick=i*10;local at=os.clock();bridge.Observe(sim,{});local ms=(os.clock()-at)*1000;total+=ms;samples[i]=ms end
 table.sort(samples)
 print(string.format("Progression observer only / %d participants / 1000 samples: avg %.4f ms, p95 %.4f ms, worst %.4f ms, heap change %.1f KiB. Excludes simulation/network/GPU/DataStore latency.",population,total/1000,samples[950],samples[1000],gcinfo()-beforeKB))
end
