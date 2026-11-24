local commerceConfig={DataStoreName="TEST",StarterPassID=12,GeneralPassID=13,StarsProductID=14,EnableStarsProduct=true,StarsPerPurchase=500,BadgeIDs={}}
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
 if class=="RemoteEvent"then obj.OnServerEvent=signal();function obj:FireClient(_,payload)self.Last=payload end;table.insert(serverRemotes,obj)end
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
local receipt={PlayerId=101,ProductId=14,PurchaseId="real-service-stub-id"}
assert(marketService.ProcessReceipt(receipt)==Enum.ProductPurchaseDecision.PurchaseGranted)
assert(marketService.ProcessReceipt(receipt)==Enum.ProductPurchaseDecision.PurchaseGranted and liveStore.u101.Stars==500)
receipt.ProductId=999;assert(marketService.ProcessReceipt(receipt)==Enum.ProductPurchaseDecision.NotProcessedYet)
receipt.ProductId=14;receipt.PurchaseId="failure";failSave=true;assert(marketService.ProcessReceipt(receipt)==Enum.ProductPurchaseDecision.NotProcessedYet);failSave=false
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
local meta={Players={{UserId=101}}};bridge.Decorate(meta);assert(meta.Players[1].Cosmetics.Flag=="flag_horizon")
net.OnServerEvent:Fire(human,"Match","fake");assert(liveStore.u101.Stars==balance)
print("Stage 13 production server: receipt retry/idempotency, unknown product, DataStore outage deferral, authoritative completion/victory, private/AFK exclusion, no client reward endpoint and cosmetic projection passed. Roblox services simulated; no live purchase or persistence verification.")
marketService.GetPassOwnershipAsync=function()return {Owned=true,Active=true}end
marketService.PromptGamePassPurchaseFinished:Fire(human,12,true)
assert(liveStore.u101.Owned.flag_founder and liveStore.u101.Owned.badge_general)
local before=liveStore.u101.Revision;marketService.PromptGamePassPurchaseFinished:Fire(human,12,true);assert(liveStore.u101.Revision==before)
print("Permanent pass verification: trial rejected; Owned=true grants persist once (API stubs).")
for _,population in ipairs({20,100,250,500})do
 bridge.ActiveID="observer"..population;sim.Phase="Started";sim.Tick=0
 for id=2,population do sim.Players[-id]={UserId=-id,SmallId=id,IsBot=true,Troops=10000};sim.Grid.Counts[id]=1000 end
 local samples={};local total=0;local beforeKB=gcinfo()
 for i=1,1000 do sim.Tick=i*10;local at=os.clock();bridge.Observe(sim,{});local ms=(os.clock()-at)*1000;total+=ms;samples[i]=ms end
 table.sort(samples)
 print(string.format("Progression observer only / %d participants / 1000 samples: avg %.4f ms, p95 %.4f ms, worst %.4f ms, heap change %.1f KiB. Excludes simulation/network/GPU/DataStore latency.",population,total/1000,samples[950],samples[1000],gcinfo()-beforeKB))
end
