--!strict
-- Original WorldConquest persistent progression adapter. AGPL-3.0.
local Catalog=require(game:GetService("ReplicatedStorage").Shared.ProgressionCatalog)
local Store=require(script.Parent.ProfileStore)
local Config=require(script.Parent.CommerceConfig)
local LeaderboardStore=require(script.Parent.LeaderboardStore)
local Server={}
function Server.new(session)
 local Players=game:GetService("Players");local RS=game:GetService("ReplicatedStorage")
 local Data=game:GetService("DataStoreService");local Market=game:GetService("MarketplaceService")
 local Badges=game:GetService("BadgeService");local Run=game:GetService("RunService")
 local studio=Run:IsStudio();local temporary={}
 -- Studio never writes production progression or pretends to verify purchases.
 local store=Store.new(if studio then {UpdateAsync=function(_,key,fn)temporary[key]=fn(temporary[key]);return temporary[key]end}else Data:GetDataStore(Config.DataStoreName),os.time)
 local rankings=LeaderboardStore.new(Data,Config.DataStoreName,store)
 local remote=Instance.new("RemoteEvent");remote.Name="WorldConquestProgression";remote.Parent=RS
 local limits={};local offers={};local boards={};local observed={};local matchID=nil;local matchAt=0;local done=false
 local function send(p,message)
  if p.Parent~=Players then return end
  local profile=store.Cache[p.UserId];local featured,refresh=Catalog.featured(os.time())
  local projected=if profile then {Version=profile.Version,Revision=profile.Revision,Stars=profile.Stars,Owned=profile.Owned,Equipped=profile.Equipped,Achievements=profile.Achievements,Daily=profile.Daily,Stats=profile.Stats,Entitlements=profile.Entitlements}else nil
  remote:FireClient(p,{Profile=projected,Message=message,Temporary=studio,Offers=offers,Now=os.time(),Featured=featured,RefreshAt=refresh})
 end
 local function saved(p,action,data)
  local profile,message=store.transact(p.UserId,action,data)
  if profile and session.ProfileReady then session.ProfileReady(p,profile)end
  send(p,message);return profile
 end
 local function passes(p)
  if studio then return end
  for _,o in ipairs({{Key="Starter",ID=Config.StarterPassID,Items={"missile_founder","flag_founder","badge_founder"}},{Key="General",ID=Config.GeneralPassID,Items={"flag_general","badge_general"}}})do
   if o.ID>0 then
    local ok,ownership=pcall(function()return Market:GetPassOwnershipAsync(p,o.ID)end)
    -- Temporary trials must never turn into permanent inventory grants.
    if ok and ownership.Owned==true and not (store.Cache[p.UserId]and store.Cache[p.UserId].Entitlements[o.Key])then saved(p,"Entitlement",o)end
   end
  end
 end
 task.spawn(function()
  for _,o in ipairs({{Key="Starter",ID=Config.StarterPassID},{Key="General",ID=Config.GeneralPassID},{Key="Stars",ID=if Config.EnableStarsProduct then Config.StarsProductID else 0}})do
   if o.ID>0 then local ok,info=pcall(Market.GetProductInfoAsync,Market,o.ID,if o.Key=="Stars"then Enum.InfoType.Product else Enum.InfoType.GamePass)
    local supported=o.Key=="Stars"or pcall(function()assert(Market.GetPassOwnershipAsync)end)
    if ok and supported and info.IsForSale and type(info.PriceInRobux)=="number"then offers[o.Key]={ID=o.ID,Kind=if o.Key=="Stars"then "Product"else "Pass"}end
   end
  end
  for _,p in ipairs(Players:GetPlayers())do send(p)end
 end)
 Market.ProcessReceipt=function(receipt)
  if studio or not Config.EnableStarsProduct or Config.StarsProductID<=0 or receipt.ProductId~=Config.StarsProductID then return Enum.ProductPurchaseDecision.NotProcessedYet end
  local p=Players:GetPlayerByUserId(receipt.PlayerId);if not p then return Enum.ProductPurchaseDecision.NotProcessedYet end
  local result=store.transact(p.UserId,"Receipt",{ID=tostring(receipt.PurchaseId),Stars=Config.StarsPerPurchase})
  if result and result.Receipts[tostring(receipt.PurchaseId)]then send(p,"Purchase saved.");return Enum.ProductPurchaseDecision.PurchaseGranted end
  return Enum.ProductPurchaseDecision.NotProcessedYet
 end
 Market.PromptGamePassPurchaseFinished:Connect(function(p,id)
  if id==Config.StarterPassID or id==Config.GeneralPassID then task.spawn(passes,p)end
 end)
 local function board(p,metric)
  if not table.find(Catalog.Metrics,metric)then return end
  local cached=boards[metric]
  if not cached or cached.At<os.time()-60 then
   local rows={};local ok=true
   if not studio then ok=pcall(function()
    local pages=Data:GetOrderedDataStore(Config.DataStoreName.."_"..metric):GetSortedAsync(false,25)
    for _,row in ipairs(pages:GetCurrentPage())do
     local id=tonumber(row.key);if id and id>0 then
      local named,name=pcall(Players.GetNameFromUserIdAsync,Players,id)
      table.insert(rows,{UserId=id,Name=if named then name else nil,Value=row.value})
     end
    end
   end)end
   if not ok then send(p,"Global rankings are temporarily unavailable.");return end
   cached={At=os.time(),Rows=rows};boards[metric]=cached
  end
  remote:FireClient(p,{Board=metric,Rows=cached.Rows,Temporary=studio})
 end
 remote.OnServerEvent:Connect(function(p,action,data)
  if type(action)~="string"or (data~=nil and (type(data)~="string"or #data>80))then return end
  local l=limits[p]or{At=-math.huge};limits[p]=l
  if l.Busy or os.clock()-l.At<.8 then return end;l.At=os.clock();l.Busy=true
  local ok=pcall(function()
   if action=="Hello"then if not store.Cache[p.UserId]then saved(p,nil,nil)else send(p)end
   elseif action=="Board"then board(p,data)
   elseif action=="RefreshPurchases"then passes(p);send(p)
   elseif action=="Buy"or action=="Equip"or action=="Unequip"or action=="Daily"then
    if not store.Cache[p.UserId]then send(p,"Load your profile before making changes.");return end
    if session.Allowed[p]and (action=="Equip"or action=="Unequip")then send(p,"Equip cosmetics from the main menu between matches.");return end
    saved(p,action,data)
   end
  end)
  l.Busy=false;if not ok then send(p,"The request could not be saved. Please retry.")end
 end)
 local function arrived(p)task.spawn(function()local profile=saved(p,nil,nil);passes(p);if profile and not studio then rankings.flush(p.UserId,profile)end end)end
 Players.PlayerAdded:Connect(arrived);Players.PlayerRemoving:Connect(function(p)limits[p]=nil;store.forget(p.UserId)end)
 for _,p in ipairs(Players:GetPlayers())do arrived(p)end
 local cosmetics={};local effects={};local effectID=0;local defaultNation={Flag="flag_horizon"}
 function session.Decorate(meta)
  meta.CosmeticEffects=effects
  for _,list in ipairs({meta.Players or {},meta.Rankings or {}})do
   for _,p in ipairs(list)do
    local equipped=cosmetics[p.UserId]or defaultNation;p.Cosmetics=equipped
    local color=equipped and Catalog.ByID[equipped.Color]
    if color then p.Color=Color3.fromHex(color.Tint)end
   end
  end
 end
 function session.Observe(sim,results)
  if session.ActiveID~=matchID then
   matchID=session.ActiveID;matchAt=os.time();observed={};cosmetics={};done=false;effects={};effectID=0
   for p in pairs(session.Allowed)do local profile=store.Cache[p.UserId];if profile then cosmetics[p.UserId]=table.clone(profile.Equipped)end end
   sim.PresentationImpact=function(owner,tile)
    local equipped=cosmetics[owner.UserId]
    if equipped and equipped.Explosion and #effects<20 then
     effectID+=1;table.insert(effects,{ID=effectID,Owner=owner.SmallId,Tile=tile,Tick=sim.Tick});sim.MetadataDirty=true
    end
   end
   sim.ProgressionElimination=function(winner,loser)
    local w,l=observed[winner.UserId],observed[loser.UserId]
    if w and l and winner~=loser and not winner.IsBot and not loser.IsBot and not l.Counted then w.Eliminations+=1;l.Counted=true end
   end
  end
  if not matchID or done then return end
  for _,r in ipairs(results or {})do
   -- Commands only count with authoritative world progress or a fresh paid
   -- gameplay purchase. Repeating an idle order cannot manufacture activity.
   local o=observed[r.UserId];local p=sim.Players[r.UserId]
   if o and p and not p.IsBot then
    local expansion=string.sub(r.Message or "",1,10)=="Expanding "or string.sub(r.Message or "",1,10)=="Attacking "
    local progressed=expansion and (p.TileVersion or 0)>(o.LastActionVersion or 0)
    local purchased=r.Fresh and r.Receipt and r.Receipt.OK and r.Receipt.Cost and r.Receipt.Cost~="0"
    local launched=table.find({"AtomBomb launched.","HydrogenBomb launched.","MIRV launched."},r.Message or "")~=nil
    if progressed or purchased or launched then o.Windows[math.floor(sim.Tick/300)]=true;o.LastActionVersion=p.TileVersion or 0 end
   end
  end
  if sim.Tick%10~=0 then return end
  for i=#effects,1,-1 do if effects[i].Tick<sim.Tick-10 then table.remove(effects,i)end end
  for id,p in pairs(sim.Players)do if not p.IsBot and not p.Spectator then
   local o=observed[id]or{Windows={},Territory=0,Soldiers=0,Eliminations=0,Ships=0};observed[id]=o
   o.Territory=math.max(o.Territory,sim.Grid.Counts[p.SmallId]or 0);o.Soldiers=math.max(o.Soldiers,p.Troops or 0)
   o.Ships=math.max(o.Ships,(p.ShipConstructed and ((p.ShipConstructed.Warship or 0)+(p.ShipConstructed.TransportShip or 0)))or 0)
   if p.ConqueredBy and not o.Counted then o.Counted=true;local winner=observed[p.ConqueredBy];if winner then winner.Eliminations+=1 end end
  end end
  if sim.Phase~="Victory"and sim.Phase~="Results"then return end;done=true
  local rewards=Catalog.Rewards;local elapsed=(sim.Tick-(sim.StartTick or sim.Tick))/10
  for id,o in pairs(observed)do
   local windows=0;for _ in pairs(o.Windows)do windows+=1 end
   local p=Players:GetPlayerByUserId(id)
   local eligible=session.MatchKind=="Public"and id>0 and p~=nil and elapsed>=rewards.MinimumSeconds and windows>=rewards.ActiveWindows and o.Territory>=rewards.MinimumTerritory
   if eligible then
    local data={ID=matchID,Time=matchAt,Eligible=true,Won=sim.Match.Winner and sim.Match.Winner.UserId==id,Territory=o.Territory,Soldiers=o.Soldiers,HumanEliminations=o.Eliminations,Ships=o.Ships}
    task.spawn(function()
     local profile
     for attempt=1,4 do profile=store.transact(id,"Match",data);if profile then break end;task.wait(attempt*2)end
     if p.Parent==Players then send(p,if profile then "Public match progression saved."else "Progression could not be saved. Please report this match.")end
     if profile and not studio then
      rankings.flush(id,profile)
      for key in pairs(profile.Achievements)do local badge=Config.BadgeIDs[key];if badge and badge>0 then pcall(Badges.AwardBadgeAsync,Badges,id,badge)end end
     end
    end)
   end
  end
 end
 if Run.Heartbeat then
  local elapsed=0
  Run.Heartbeat:Connect(function(dt)
   elapsed+=dt;if elapsed<60 or studio then return end;elapsed=0
   for _,p in ipairs(Players:GetPlayers())do local profile=store.Cache[p.UserId];if profile and profile.RankingDirty then task.spawn(rankings.flush,p.UserId,profile)end end
  end)
 end
 return {Store=store}
end
return Server
