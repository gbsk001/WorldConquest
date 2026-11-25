--!strict
-- Original premium presentation, sharing the existing menu and lobby navigation.
local Players=game:GetService("Players");local RS=game:GetService("ReplicatedStorage")
local Market=game:GetService("MarketplaceService");local Social=game:GetService("SocialService")
local Catalog=require(RS.Shared.ProgressionCatalog)
local Theme=require(script.Parent.StrategyUI);local Art=require(script.Parent.InterfaceArt)
local Cosmetic=require(script.Parent.CosmeticArt)
local Premium={}
function Premium.new(gui,content,layout,navigate,refresh,play,message)
 local player=Players.LocalPlayer;local profile=nil;local offers={};local party={Members={}};local rows={};local metric="Wins"
 local remote=nil;local partyRemote=nil;local identityRemote=nil;local nationName=nil;local active="Home";local category="All";local inventory=false;local priceCache={}
 local temporary=false;local serverAt=0;local receivedAt=0;local featured=nil;local refreshAt=0;local invitationRequested=false
 local purchasesEnabled=false;local offerGeneration=0
 local pendingPurchase=nil
 local gold=Color3.fromRGB(223,188,111);local white=Color3.fromRGB(235,241,250)
 local function now()return serverAt+os.clock()-receivedAt end
 local function send(action,data)
  if remote then remote:FireServer(action,data)else message.Text="Progression is still connecting. Please retry."end
 end
 local function partySend(action,data)if partyRemote then partyRemote:FireServer(action,data)else message.Text="Party service is still connecting."end end
 local function repaint()if gui.Enabled and active~="Inactive"then refresh()end end
 local function label(parent,value,pos,size,textSize,color)
  local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Text=value;t.Position=pos;t.Size=size;t.Font=Enum.Font.GothamMedium;t.TextSize=textSize or 15;t.TextColor3=color or white;t.TextWrapped=true;t.TextXAlignment=Enum.TextXAlignment.Left;t.TextDirection=Enum.TextDirection.Auto;t.AutoLocalize=true;t.Parent=parent;return t
 end
 local function button(parent,value,fn,pos,size,icon,accent)
  local b=Instance.new("TextButton");b.Name=value;b.Text=value;b.Position=pos;b.Size=size;Theme.button(b);b.TextSize=14;b.TextDirection=Enum.TextDirection.Auto;b.AutoLocalize=true;b.Parent=parent
  if accent then b.BackgroundColor3=gold;b.TextColor3=Color3.fromRGB(18,26,39);b.Font=Enum.Font.GothamBold end
  if icon then local art=Art.icon(b,icon,22,if accent then Color3.fromRGB(18,26,39)else gold);art.Position=UDim2.fromOffset(12,11);local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,36);pad.PaddingRight=UDim.new(0,6);pad.Parent=b end
  b.Activated:Connect(fn);local tween=game:GetService("TweenService")
  b.MouseEnter:Connect(function()tween:Create(b,TweenInfo.new(.15),{BackgroundTransparency=.02}):Play()end)
  b.MouseLeave:Connect(function()tween:Create(b,TweenInfo.new(.15),{BackgroundTransparency=.14}):Play()end)
  return b
 end
 local function go(page)category="All";inventory=false;navigate(page)end
 local function text(value,h)
  local t=label(content,value,UDim2.new(),UDim2.new(1,-8,0,h or 40),15);t.LayoutOrder=#content:GetChildren();return t
 end
 local function action(value,fn,accent)
  local b=button(content,value,fn,UDim2.new(),UDim2.new(1,-8,0,48),nil,accent);b.LayoutOrder=#content:GetChildren();return b
 end
 local function product(key)
  local offer=offers[key]
  if not purchasesEnabled or not offer or temporary then message.Text="Paid offers are not enabled in this environment.";return end
  if pendingPurchase then message.Text="Finish the current Roblox purchase prompt first.";return end
  local pending={ID=offer.ID,Key=key,Kind=offer.Kind,Confirmed=false};pendingPurchase=pending
  local ok=pcall(function()
   -- Fetch the player's current Managed Price again immediately before prompting.
   local info=Market:GetProductInfoAsync(offer.ID,if offer.Kind=="Product"then Enum.InfoType.Product else Enum.InfoType.GamePass)
   if not purchasesEnabled or temporary or offers[key]~=offer then return end
   if not info.IsForSale or type(info.PriceInRobux)~="number"then error("Offer unavailable")end
   if info.PriceInRobux~=offer.Price then
    offer.Price=info.PriceInRobux;repaint();message.Text="Roblox updated this price. Review it and select Purchase again.";return
   end
   pending.Opened=true
   if offer.Kind=="Product"then Market:PromptProductPurchase(player,offer.ID)else Market:PromptGamePassPurchase(player,offer.ID)end
  end)
  if not ok or not pending.Opened then if pendingPurchase==pending then pendingPurchase=nil end end
  if not ok then message.Text="Roblox could not open this purchase. No items were granted."end
  task.delay(60,function()if pendingPurchase==pending then pendingPurchase=nil;message.Text="Purchase status is pending. Rejoin if your saved balance has not updated."end end)
 end
 local function promptClosed(id,kind,purchased)
  local pending=pendingPurchase;if not pending or pending.ID~=id or pending.Kind~=kind then return end
  pendingPurchase=nil
  if not purchased then message.Text="Purchase cancelled."
  elseif not pending.Confirmed then message.Text="Waiting for Roblox verification and a successful save…"end
 end
 if Market.PromptProductPurchaseFinished then Market.PromptProductPurchaseFinished:Connect(function(user,id,purchased)if user==player.UserId then promptClosed(id,"Product",purchased)end end)end
 if Market.PromptGamePassPurchaseFinished then Market.PromptGamePassPurchaseFinished:Connect(function(who,id,purchased)if who==player then promptClosed(id,"Pass",purchased)end end)end
 local function itemCard(item,index,cols,y)
  local width=1/cols;local card=Instance.new("Frame");card.Name=item.ID;Theme.surface(card);card.Size=UDim2.new(width,-10,0,242);card.Position=UDim2.new(((index-1)%cols)*width,0,0,y+math.floor((index-1)/cols)*254);card.Parent=content
  local preview=Cosmetic.preview(card,item,58);preview.Position=UDim2.fromOffset(16,16)
  label(card,item.Name,UDim2.fromOffset(86,14),UDim2.new(1,-100,0,48),17,gold)
  label(card,item.Description,UDim2.fromOffset(16,82),UDim2.new(1,-32,0,68),13)
  local owned=profile and profile.Owned[item.ID];local equipped=profile and profile.Equipped[item.Category]==item.ID
  label(card,if equipped then "EQUIPPED"elseif owned then "OWNED"elseif item.Price then tostring(item.Price).." Stars"else "Unlock: "..(item.Offer or item.Unlock or "Achievement"),UDim2.fromOffset(16,154),UDim2.new(1,-32,0,26),12,gold)
  if owned then button(card,if equipped then "Unequip"else "Equip",function()send(if equipped then "Unequip"else "Equip",if equipped then item.Category else item.ID)end,UDim2.fromOffset(12,190),UDim2.new(1,-24,0,44))
  elseif item.Price then button(card,"Unlock • "..item.Price.." Stars",function()send("Buy",item.ID)end,UDim2.fromOffset(12,190),UDim2.new(1,-24,0,44),nil,true)
  elseif item.Offer then button(card,"View "..item.Offer,function()go(item.Offer)end,UDim2.fromOffset(12,190),UDim2.new(1,-24,0,44))end
 end
 local api={}
 function api.render(page,state)
  active=if state.Screen=="Game"or state.Screen=="Lobby"then "Inactive"else page
  if active=="Inactive"then return false end
  local w=content.AbsoluteSize.X;local short=gui.AbsoluteSize.Y<500;local narrow=gui.AbsoluteSize.X<700
  if page=="Home"then
   layout.Parent=nil;content.Position=UDim2.fromOffset(10,0);content.Size=UDim2.new(1,-20,1,-65);content.AutomaticCanvasSize=Enum.AutomaticSize.None
   local height=math.max(if narrow then 470 else 420,content.AbsoluteSize.Y);content.CanvasSize=UDim2.fromOffset(0,height);content.ScrollingEnabled=content.AbsoluteSize.Y<height;content.ScrollBarThickness=if content.ScrollingEnabled then 3 else 0
   local bw=if narrow then 1/3 else 1/6
   local nav={{"Party","Party","Friends"},{"Settings","Settings","Settings"},{"Tutorial","Tutorial","Tutorial"},{if profile then tostring(profile.Stars).." Stars"else "Stars…","Profile","Rank"},{"Arsenal","Arsenal","Missiles"},{"Shop","Shop","Gold"}}
   for i,n in ipairs(nav)do local row=if narrow then math.floor((i-1)/3)else 0;local col=if narrow then (i-1)%3 else i-1
    button(content,n[1],function()go(n[2])end,UDim2.new(col*bw,0,0,row*50),UDim2.new(bw,-6,0,44),if narrow then nil else n[3])
   end
   local y=if narrow then 106 else 60
   local hero=label(content,"WORLD CONQUEST",UDim2.new(0,0,0,y+32),UDim2.new(1,0,0,if short then 44 else 82),if short then 30 elseif narrow then 36 else 64);hero.Font=Enum.Font.GothamBold;hero.TextXAlignment=Enum.TextXAlignment.Center
   local sub=label(content,"BUILD A NATION. SHAPE THE WORLD.",UDim2.new(0,0,0,y+(if short then 78 else 112)),UDim2.new(1,0,0,24),11,gold);sub.TextXAlignment=Enum.TextXAlignment.Center
   local info=party.MatchInfo or {};local status=if info.Unavailable then "Match directory unavailable"elseif info.Available then string.format("%d / %d %s",info.Count or 0,info.Capacity or 20,if info.ReservationCount then "human reservations"else "participants")else "PLAY to find or create a public lobby"
   if info.Deadline then status..=" • Starts in "..math.max(0,math.ceil(info.Deadline-now())).."s"end
   local nextY=y+(if short then 106 else 148)
   local s=label(content,status,UDim2.new(.15,0,0,nextY),UDim2.new(.7,0,0,32),12);s.TextXAlignment=Enum.TextXAlignment.Center
   local bottom=math.max(nextY+40,height-160)
   local b=button(content,"PLAY",play,UDim2.new(.25,0,0,bottom),UDim2.new(.5,0,0,56),"Play",true);b.Name="Play";b:SetAttribute("ActionLabel","PLAY");b.TextSize=25
   button(content,"Private Match",function()go("Private")end,UDim2.new(.25,0,0,bottom+64),UDim2.new(.5,0,0,44),"Private")
   button(content,"Global Rankings",function()go("Global");send("Board",metric)end,UDim2.new(.25,0,0,bottom+114),UDim2.new(.5,0,0,44),"Leaderboard")
   if not narrow and not short then
    button(content,"Daily Rewards",function()go("Daily")end,UDim2.new(0,0,0,bottom),UDim2.new(.23,-12,0,56),"Rank")
    button(content,"Starter Pack",function()go("Starter")end,UDim2.new(.77,12,0,bottom),UDim2.new(.23,-12,0,56),"Missiles")
   end
   if temporary then message.Text="Studio preview • progression is temporary • purchases disabled"end
   return true
  elseif page=="Shop"or page=="Arsenal"or page=="Inventory"or page=="Flags"or page=="Territory"then
   layout.Parent=nil;content.AutomaticCanvasSize=Enum.AutomaticSize.None;content.ScrollingEnabled=true;content.ScrollBarThickness=3
   local tabs={{"Featured","Shop"},{"Flags","Flags"},{"Arsenal","Arsenal"},{"Territory","Territory"},{"Inventory","Inventory"},{"Daily","Daily"},{"Starter","Starter"},{"General","General"}}
   local cols=if narrow then 2 else 4
   for i,n in ipairs(tabs)do button(content,n[1],function()go(n[2])end,UDim2.new(((i-1)%cols)/cols,0,0,math.floor((i-1)/cols)*50),UDim2.new(1/cols,-8,0,44))end
   local y=math.ceil(#tabs/cols)*50+8
   if page=="Shop"and featured then label(content,"FEATURED FLAG • selection refreshes in "..math.max(0,math.floor((refreshAt-now())/3600)).."h • regular prices",UDim2.fromOffset(0,y),UDim2.new(1,0,0,40),12,gold);y+=48 end
   local count=0;local cardCols=if w<560 then 1 elseif w<1000 then 2 else 3
   for _,item in ipairs(Catalog.Items)do
    local military=table.find({"Missile","Warship","Transport","Building","Attack","Explosion","Victory"},item.Category)~=nil
    local show=page=="Shop"and (item.ID==featured or item.Offer~=nil)or page=="Arsenal"and military or page=="Flags"and item.Category=="Flag"or page=="Territory"and not military and item.Category~="Flag"or page=="Inventory"and profile and profile.Owned[item.ID]
    if show then count+=1;itemCard(item,count,cardCols,y)end
   end
   content.CanvasSize=UDim2.fromOffset(0,y+math.ceil(count/cardCols)*254)
   local packs={};for key,offer in pairs(offers)do if offer.Kind=="Product"and offer.Stars then table.insert(packs,{Key=key,Offer=offer})end end
   table.sort(packs,function(a,b)return a.Offer.Stars<b.Offer.Stars end)
   for _,pack in ipairs(packs)do
    button(content,"Buy "..pack.Offer.Stars.." Stars • "..pack.Offer.Price.." Robux",function()product(pack.Key)end,UDim2.fromOffset(0,content.CanvasSize.Y.Offset),UDim2.new(1,-8,0,48))
    content.CanvasSize=UDim2.fromOffset(0,content.CanvasSize.Y.Offset+56)
   end
   return true
  elseif page=="Daily"then
   text("DAILY REWARDS • A new day begins at 00:00 UTC",48)
   if not profile then text("Load your profile before claiming.");action("Retry",function()send("Hello")end);return true end
   local day=math.floor(now()/86400);local claimed=profile.Daily.Day>=day
   for i,amount in ipairs(Catalog.Daily)do text("Day "..i.." • "..amount.." Stars"..(if i==7 then " + Seven Horizons badge"else "")..(if profile.Daily.Streak==i then " • current"else ""),36)end
   text("Missed days restart the calendar. Rewards are optional.",44)
   if claimed then text("Next claim in "..math.max(0,math.ceil(((day+1)*86400-now())/3600)).." hours.",44)else action("Claim daily reward",function()send("Daily")end,true)end;return true
  elseif page=="Starter"or page=="General"then
   local starter=page=="Starter";text(if starter then "STARTER PACK • Permanent ownership"else "WORLDCONQUEST GENERAL • Permanent pass",48)
   text(if starter then "Three original cosmetics. One purchase. No combat advantage."else "Exclusive General badge and nation flag. A one-time purchase, not a recurring subscription.",64)
   local ids=Catalog.PassItems[page]
   for _,id in ipairs(ids)do
    local card=Instance.new("Frame");Theme.surface(card);card.Size=UDim2.new(1,-8,0,90);card.LayoutOrder=#content:GetChildren();card.Parent=content
    local preview=Cosmetic.preview(card,Catalog.ByID[id],48);preview.Position=UDim2.fromOffset(16,14)
    label(card,Catalog.ByID[id].Name,UDim2.fromOffset(84,12),UDim2.new(1,-100,0,56),18,gold)
   end
   local owned=profile and profile.Entitlements[page];local offer=offers[page]
   if owned then text("OWNED • Find your items in Inventory.")elseif purchasesEnabled and offer and not temporary then action("Purchase • "..offer.Price.." Robux",function()product(page)end,true)else text("Not currently on sale. No purchase is available.",48)end
   action("Refresh verified ownership",function()send("RefreshPurchases")end);action("Not Now",function()go("Home")end);return true
  elseif page=="Profile"then
   local avatar=Instance.new("ImageLabel");avatar.Size=UDim2.fromOffset(70,70);avatar.BackgroundTransparency=1;avatar.Image="rbxthumb://type=AvatarHeadShot&id="..player.UserId.."&w=150&h=150";avatar.LayoutOrder=#content:GetChildren();avatar.Parent=content
   text(player.Name,32).AutoLocalize=false
   text(if profile then profile.Stars.." Stars"else "Loading…",32)
   text("NATION NAME • Roblox-filtered • Changes apply next match",48)
   local nation=Instance.new("TextBox");nation.Name="NationNameInput";nation.Text=nationName or player.Name;nation.PlaceholderText="2–32 characters";nation.ClearTextOnFocus=false;nation.AutoLocalize=false;nation.RichText=false;nation.TextDirection=Enum.TextDirection.Auto;nation.Size=UDim2.new(1,-8,0,48);nation.LayoutOrder=#content:GetChildren();nation.Font=Enum.Font.Gotham;nation.TextSize=16;nation.TextColor3=white;Theme.surface(nation);nation.Parent=content
   action("Save nation name",function()if identityRemote then identityRemote:FireServer("Set",nation.Text)else message.Text="Nation name service unavailable."end end)
   action("Use Roblox username",function()if identityRemote then identityRemote:FireServer("Reset")end end)
   if profile then
    local s=profile.Stats;text(string.format("%d public matches • %d victories • %.1f%% win rate",s.Matches,s.Wins,100*s.Wins/math.max(1,s.Matches)),52)
    for _,key in ipairs(Catalog.Metrics)do text(key..": "..s[key],32)end
    text("ACHIEVEMENTS",38);for _,a in ipairs(Catalog.Achievements)do text(a.Name.." • "..(if profile.Achievements[a.ID]then "Unlocked"else a.Target.." "..a.Metric),34)end
    text("EQUIPPED",38)
    for _,key in ipairs(Catalog.Categories)do local item=Catalog.ByID[profile.Equipped[key]];if item then
     local row=Instance.new("Frame");row.Size=UDim2.new(1,-8,0,58);row.BackgroundTransparency=1;row.LayoutOrder=#content:GetChildren();row.Parent=content
     local preview=Cosmetic.preview(row,item,36);preview.Position=UDim2.fromOffset(6,8);label(row,item.Name,UDim2.fromOffset(58,4),UDim2.new(1,-64,0,48),14)
    end end
   end
   action("Inventory & equipped cosmetics",function()go("Inventory")end);action("Daily Rewards",function()go("Daily")end);return true
  elseif page=="Global"then
   text("PUBLIC MATCH RECORDS • updated after eligible matches",48)
   for _,key in ipairs(Catalog.Metrics)do action(key,function()metric=key;rows={};repaint();send("Board",key)end)end
   text(metric,40);if #rows==0 then text(if temporary then "Global persistence is disabled in this Studio preview."else "No records returned yet. Select a category to refresh.",60)end
   for rank,row in ipairs(rows)do text(string.format("%02d  %s • %d",rank,row.Name or ("@"..row.UserId),row.Value),38).AutoLocalize=false end;return true
  elseif page=="Party"then
   text("PARTY • Queue together • Up to six friends",44)
   if party.Invitation then
    text("Party invitation",30);text(party.Invitation.Name,30).AutoLocalize=false
    action("Accept invitation",function()partySend("Accept")end,true);action("Decline invitation",function()partySend("Decline")end)
   end
   if #party.Members==0 then action("Create party",function()partySend("Create")end,true)
   else
    for _,member in ipairs(party.Members)do
     local row=Instance.new("Frame");Theme.surface(row);row.Size=UDim2.new(1,-8,0,64);row.LayoutOrder=#content:GetChildren();row.Parent=content
     local image=Instance.new("ImageLabel");image.BackgroundTransparency=1;image.Position=UDim2.fromOffset(8,8);image.Size=UDim2.fromOffset(48,48);image.Image="rbxthumb://type=AvatarHeadShot&id="..member.UserId.."&w=150&h=150";image.Parent=row
     label(row,member.Name,UDim2.fromOffset(64,2),UDim2.new(1,-160,0,32),14).AutoLocalize=false
     if member.Leader then label(row,"LEADER",UDim2.fromOffset(64,34),UDim2.new(1,-160,0,20),11)end
     if party.Leader==player.UserId and member.UserId~=player.UserId then button(row,"Remove",function()partySend("Kick",member.UserId)end,UDim2.new(1,-92,0,10),UDim2.fromOffset(84,44))end
    end
    if party.Leader==player.UserId then
     action("Invite Roblox friends",function()invitationRequested=true;partySend("Invite")end)
     action("PLAY with party",play,true)
    end
    action("Leave party",function()partySend("Leave")end)
   end
   text("Invitations expire after two minutes. Invitees confirm after joining. Only the leader queues the party; all members must be in this menu server.",80);return true
  end
  return false
 end
 task.spawn(function()
  remote=RS:WaitForChild("WorldConquestProgression",15)
  if not remote then message.Text="Progression unavailable. Matchmaking remains available.";return end
  remote.OnClientEvent:Connect(function(data)
   if data.Board then metric=data.Board;rows=data.Rows or {}else
    if data.Profile then profile=data.Profile end;temporary=data.Temporary==true;purchasesEnabled=data.PurchasesEnabled==true and not temporary
    if data.Offers then
     offerGeneration+=1;local generation=offerGeneration;offers={}
     for key,offer in pairs(if purchasesEnabled then data.Offers else {})do
      local cached=priceCache[offer.ID]
      if cached and cached.At>os.clock()-300 then offers[key]=cached.Value
      else task.spawn(function()
       local ok,info=pcall(function()return Market:GetProductInfoAsync(offer.ID,if offer.Kind=="Product"then Enum.InfoType.Product else Enum.InfoType.GamePass)end)
       if generation==offerGeneration and purchasesEnabled and ok and type(info)=="table"and info.IsForSale and type(info.PriceInRobux)=="number"then
        local priced={ID=offer.ID,Kind=offer.Kind,Stars=offer.Stars,Price=info.PriceInRobux};priceCache[offer.ID]={Value=priced,At=os.clock()};offers[key]=priced;repaint()
       end
      end)end
     end
    end
    serverAt=data.Now or serverAt;receivedAt=os.clock();featured=data.Featured or featured;refreshAt=data.RefreshAt or refreshAt
    if pendingPurchase and (data.ConfirmedProduct==pendingPurchase.ID or pendingPurchase.Kind=="Pass"and data.Profile and data.Profile.Entitlements[pendingPurchase.Key])then pendingPurchase.Confirmed=true end
    if data.Message then message.Text=data.Message end
   end;repaint()
  end);send("Hello")
 end)
 task.spawn(function()
  identityRemote=RS:WaitForChild("WorldConquestIdentity",15)
  if identityRemote then identityRemote.OnClientEvent:Connect(function(data)nationName=data.Name;if data.Message then message.Text=data.Message end;if active=="Profile"then repaint()end end);identityRemote:FireServer("Hello")end
 end)
 task.spawn(function()
  partyRemote=RS:WaitForChild("WorldConquestParty",15);if not partyRemote then return end
  partyRemote.OnClientEvent:Connect(function(data)
   party=data;if data.Message then message.Text=data.Message end
   if invitationRequested and data.InviteToken then invitationRequested=false;task.spawn(function()
    local ok=pcall(function()
     if not Social:CanSendGameInviteAsync(player)then error("Unavailable")end
     local options=Instance.new("ExperienceInviteOptions");options.LaunchData="WC13PART:"..data.InviteToken;Social:PromptGameInvite(player,options)
    end);if not ok then message.Text="Roblox invitations are unavailable for this account or device."end
   end)end
   if active=="Party"or active=="Home"then repaint()end
  end);partySend("Hello")
 end)
 return api
end
return Premium
