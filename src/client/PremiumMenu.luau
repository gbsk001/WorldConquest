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
   layout.Parent=nil;content.Position=UDim2.fromOffset(8,0);content.Size=UDim2.new(1,-16,1,-48);content.AutomaticCanvasSize=Enum.AutomaticSize.None
   content.ScrollingEnabled=false;content.ScrollBarThickness=0
   local width=math.max(240,content.AbsoluteSize.X);local height=math.max(230,content.AbsoluteSize.Y)
   content.CanvasSize=UDim2.fromOffset(0,height)
   local phone=width<620;local compact=height<440
   button(content,"Party",function()go("Party")end,UDim2.fromOffset(0,0),UDim2.fromOffset(if phone then 84 else 132,44),"Friends")
   local settings=button(content,"",function()go("Settings")end,UDim2.fromOffset(if phone then 90 else 140,0),UDim2.fromOffset(44,44),"Settings");settings.Name="Settings"
   local tutorial=button(content,"",function()go("Tutorial")end,UDim2.fromOffset(if phone then 138 else 188,0),UDim2.fromOffset(44,44),"Tutorial");tutorial.Name="Tutorial"
   local stars=button(content,if profile then tostring(profile.Stars).." Stars"else "Stars?",function()go("Profile")end,UDim2.new(1,-(if phone then (if width<340 then 88 else 124)else 162),0,0),UDim2.fromOffset(if phone then (if width<340 then 88 else 124)else 162,44),nil);stars.TextColor3=gold;stars.Name="StarsBalance"
   local heroY=if compact then 56 else 84
   local hero=label(content,"WORLD CONQUEST",UDim2.fromOffset(0,heroY),UDim2.new(1,-(if phone then 0 else 250),0,if compact then 50 else 94),if compact then 34 elseif phone then 34 else 64)
   hero.Name="WorldConquestTitle";hero.Font=Enum.Font.GothamBlack;hero.TextStrokeColor3=Color3.fromRGB(4,10,18);hero.TextStrokeTransparency=.3;hero.TextXAlignment=Enum.TextXAlignment.Center;hero.TextColor3=Color3.fromRGB(255,240,209)
   local sub=label(content,"BUILD A NATION. SHAPE THE WORLD.",UDim2.fromOffset(0,heroY+(if compact then 50 else 96)),UDim2.new(1,-(if phone then 0 else 250),0,22),10,gold);sub.TextXAlignment=Enum.TextXAlignment.Center
   local promoWidth=if phone then (width-12)/3 else 238
   local promoTop=if phone then heroY+(if compact then 80 else 135)else (if compact then 50 else 108)
   local promoHeight=if compact then 44 elseif phone then 116 else 100
   local entries={{"Flag Shop","Flags","flag_aurora",Color3.fromRGB(46,54,89)},{"Starter Pack","Starter","missile_founder",Color3.fromRGB(86,46,43)},{"General Pass","General","badge_general",Color3.fromRGB(62,55,38)}}
   for i,entry in ipairs(entries)do
    local x=if phone then (i-1)*(promoWidth+6)else width-promoWidth
    local y=if phone then promoTop else promoTop+(i-1)*(promoHeight+(if compact then 4 else 8))
    local card=button(content,entry[1],function()go(entry[2])end,UDim2.fromOffset(x,y),UDim2.fromOffset(promoWidth,promoHeight));card.Name=entry[1];card.BackgroundColor3=entry[4];card.TextSize=if phone then 12 else 17;card.TextYAlignment=Enum.TextYAlignment.Bottom
    local pad=Instance.new("UIPadding");pad.PaddingBottom=UDim.new(0,8);pad.Parent=card
    local art=Cosmetic.preview(card,Catalog.ByID[entry[3]],if compact then 26 else 48);art.AnchorPoint=Vector2.new(.5,0);art.Position=UDim2.new(.5,0,0,6)
   end
   local arsenalY=if phone then promoTop+promoHeight+10 else (if compact then 194 else 54)
   local arsenalX=if phone then 0 else width-238
   button(content,"Arsenal",function()go("Arsenal")end,UDim2.fromOffset(arsenalX,arsenalY),UDim2.fromOffset(if phone then (width-8)/2 else 115,44),"Missiles")
   button(content,"Shop",function()go("Shop")end,UDim2.fromOffset(arsenalX+(if phone then (width+8)/2 else 123),arsenalY),UDim2.fromOffset(if phone then (width-8)/2 else 115,44),"Gold")
   if not phone and compact and height<242 then height=242;content.CanvasSize=UDim2.fromOffset(0,height);content.ScrollingEnabled=true end
   local bottom=height-(if compact then 104 else 126)
   local playWidth=if phone then width else math.min(700,width-270)
   local playX=if phone then 0 else math.max(0,(width-250-playWidth)/2)
   local b=button(content,"PLAY",play,UDim2.fromOffset(playX,bottom),UDim2.fromOffset(playWidth,if compact then 50 else 62),"Play",true);b.Name="Play";b:SetAttribute("ActionLabel","PLAY");b.Font=Enum.Font.GothamBlack;b.TextSize=28
   button(content,"Private Match",function()go("Private")end,UDim2.fromOffset(playX,bottom+(if compact then 56 else 68)),UDim2.fromOffset(playWidth/2-4,44),"Private")
   button(content,"Global Rankings",function()go("Global");send("Board",metric)end,UDim2.fromOffset(playX+playWidth/2+4,bottom+(if compact then 56 else 68)),UDim2.fromOffset(playWidth/2-4,44),"Leaderboard")
   if not phone then button(content,"Daily Rewards",function()go("Daily")end,UDim2.fromOffset(0,54),UDim2.fromOffset(142,44),"Rank")end
   -- Portrait uses stacked artwork; short landscape keeps promotions to the right.
   if phone and arsenalY+50>bottom then
    local extra=arsenalY+50-bottom;content.CanvasSize=UDim2.fromOffset(0,height+extra);content.ScrollingEnabled=true;content.ScrollBarThickness=3
    b.Position=UDim2.fromOffset(playX,bottom+extra)
    for _,name in ipairs({"Private Match","Global Rankings"})do local control=content:FindFirstChild(name);control.Position=UDim2.fromOffset(control.Position.X.Offset,control.Position.Y.Offset+extra)end
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
