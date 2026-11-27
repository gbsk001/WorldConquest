local parent=Instance.new("Frame");local orders={};local sequence=0
local function nextSequence()sequence+=1;return sequence end
local function send(order)table.insert(orders,order)end
local function notice(_)end
local owned={ID=42,Owner=1,Type="Warship",Health=100,Veterancy=0}
local function hit()return owned end
local function noop()end
local shop=BuildingShop.new(parent,send,notice,hit,nextSequence,noop)
local navy=NavalControls.new(parent,send,notice,hit,nextSequence,function()return .37 end,noop)
local missiles=MissileControls.new(parent,send,notice,nextSequence,noop)
local hud=MatchHUD.new(parent)
local profile={UserId=1,SmallId=1,Count=100,Troops=1000,Gold="999999999",Growth=2,GoldIncome="5",BuildingQuotes={},Naval={Affordable=true,WarshipCost="100",Transports=0,Warships=1,TradeShips=0},Missiles={Structures={{Type="MissileSilo",Ready=1,Level=1,Reload=0}},Quotes={}}}
for _,kind in ipairs(BuildingRules.Types)do profile.BuildingQuotes[kind]={Affordable=true,Enabled=true,Cost="100"}end
for _,kind in ipairs({"AtomBomb","HydrogenBomb","MIRV"})do profile.Missiles.Quotes[kind]={Affordable=true,Cost="100"}end
local function click(panel,prefix)
 for _,o in ipairs(panel:GetDescendants())do if o.ClassName=="TextButton" and string.sub(o.Text,1,#prefix)==prefix then o.Activated:Fire();return end end
 error("Missing control "..prefix)
end
shop.update(profile,"Started");navy.update(profile,"Started");missiles.update(profile,"Started")
for _,kind in ipairs(BuildingRules.Types)do click(shop.Panel,BuildingRules.Info[kind].Name);assert(shop.click(20,30));assert(orders[#orders].Type==kind)end
click(shop.Panel,"Upgrade");shop.click(1,2);assert(orders[#orders].Action=="Upgrade" and orders[#orders].UnitID==42)
click(shop.Panel,"Demolish");shop.click(1,2);assert(orders[#orders].Action=="Demolish")
click(navy.Panel,"Launch invasion");navy.click(1,2);assert(orders[#orders].Allocation==.37)
click(navy.Panel,"Buy warship");navy.click(1,2);assert(orders[#orders].Action=="Warship")
click(navy.Panel,"Move warship");navy.click(1,2);navy.click(3,4);assert(orders[#orders].UnitID==42)
owned.Type="TransportShip";click(navy.Panel,"Return transport");navy.click(1,2);assert(orders[#orders].Action=="Retreat")
for _,entry in ipairs({{"Atomic bomb","AtomBomb"},{"Hydrogen bomb","HydrogenBomb"},{"MIRV","MIRV"}})do click(missiles.Panel,entry[1]);assert(missiles.click(40,50));assert(orders[#orders].Type==entry[2])end
local count=#orders;profile.Spectator=true;missiles.update(profile,"Started");click(missiles.Panel,"Atomic bomb");assert(not missiles.click(1,2) and #orders==count);profile.Spectator=false
for i,order in ipairs(orders)do assert(order.Sequence==i)end
local root=Instance.new("Frame");local viewport=Instance.new("Frame");viewport.Parent=root;local labels={};for i=1,6 do labels[i]=Instance.new("TextLabel")end
local zoom=0;local fits=0
local ui=StrategyUI.new(root,viewport,labels[1],labels[2],labels[3],labels[4],labels[5],labels[6],{reset=function()fits+=1 end,zoomBy=function(n)zoom+=n end})
ui.mount(shop.Toggle,shop.Panel,2,shop.cancel);ui.mount(navy.Toggle,navy.Panel,3,navy.cancel);ui.mount(missiles.Toggle,missiles.Panel,4,missiles.cancel);ui.mount(hud.Toggle,hud.Panel,5)
shop.Toggle.Activated:Fire();navy.Toggle.Activated:Fire();assert(navy.Panel.Visible and not shop.Panel.Visible)
click(root,"Settings");assert(not navy.Panel.Visible);click(root,"Fit Earth");click(root,"Zoom in");click(root,"Zoom out");click(root,"Motion: subtle");assert(fits==1 and zoom>1)
for _,size in ipairs({{320,568},{390,844},{768,1024},{844,390},{1366,768},{1920,1080}})do
 root.AbsoluteSize=Vector2.new(size[1],size[2]);assert(viewport.Size.X.Scale==1 and viewport.Size.Y.Scale==1 and viewport.Position.X.Offset==0 and viewport.Position.Y.Offset==0,"HUD must not shrink the map")
end
ui.stats(profile,{Rankings={profile}});ui.notify("Test");ui.close();assert(not shop.Panel.Visible and not navy.Panel.Visible)
hud.update({MatchID=1,Phase="Victory",Tick=10,RestartAt=190,Winner={Name="Tester"},Rankings={}});assert(hud.Panel.Visible)
hud.update({MatchID=2,Phase="Selecting",Tick=0,Rankings={}});assert(not hud.Panel.Visible)
print("Production GUI adapters: build/upgrade/demolish, all navy/missile actions, authority guards, sequence, exclusive panels, settings, results/restart and six layout sizes passed (stubbed; not rendered Studio).")

for _,phase in ipairs({"Victory","Results"})do
 hud.update({MatchID=3,Phase=phase,Tick=if phase=="Victory"then 20 else 30,RestartAt=190,Winner={Name="FrostByte"},Rankings={{Username="FrostByte",IsBot=true,Count=12,Troops=100,Gold="0"},{Username="Human",IsBot=false,Count=10,Troops=90,Gold="0"}}})
 local count=0
 for _,row in ipairs(hud.Panel:GetDescendants())do if row.Name=="RankingCard"and row.Visible then count+=1;assert(not string.find(row.Text,"[BOT]",1,true) and not string.find(row.Text,"[AI]",1,true))end end
 assert(count==2)
end
print("Rankings/results use the same participant text formatter without individual AI labels.")

profile.Spectator=false;shop.update(profile,"Started");assert(shop.inspect({ID=42,Type="City",Owner=profile.SmallId,Level=2}))
local detail=parent:FindFirstChild("BuildingInfo")
assert(detail and detail.Visible);click(detail,"Upgrade");assert(orders[#orders].Action=="Upgrade" and orders[#orders].UnitID==42)
print("Building inspection uses existing authoritative upgrade action and correct unit ID.")

do
 local located=nil
 local board=MatchHUD.new(parent,function(x,y)located={x,y}end,1)
 local people={};for i=1,500 do people[i]={UserId=i,SmallId=i,Username="Player"..i,Count=i,X=i,Y=i+1}end
 local state={MatchID=9,Phase="Started",Tick=1,Players=people}
 board.update(state);assert(not board.Panel.Visible,"Live rankings start collapsed");board.Toggle.Activated:Fire()
 local function cards()local out={};for _,o in ipairs(board.Panel:GetChildren())do if o.Name=="RankingCard"and o.Visible then table.insert(out,o)end end;return out end
 assert(#cards()==11,"Top ten plus own outside-rank row")
 cards()[1].Activated:Fire();assert(located)
 local crowns=TerritoryRanking.crowns(people,"Started");assert(crowns[500]==1 and crowns[499]==2 and crowns[498]==3)
 assert(next(TerritoryRanking.crowns(people,"Selecting"))==nil)
 people[1].Count=1000;board.update(state);crowns=TerritoryRanking.crowns(people,"Started");assert(crowns[1]==1 and crowns[500]==2 and #cards()==10)
 people[1].Eliminated=true;board.update(state);assert(TerritoryRanking.crowns(people,"Started")[1]==nil)
 people[498].Count=500;assert(TerritoryRanking.sorted(people)[1].SmallId==498,"Territory ties use SmallId")
 board.Toggle.Activated:Fire();local before=#objects;people[10].Count=2000;board.update(state);assert(not board.Panel.Visible and #objects==before,"Closed leaderboard remains closed and allocation-free")
 board.update({MatchID=9,Phase="Victory",Tick=20,RestartAt=200,Rankings={}});assert(board.Panel.Visible)
 board.Panel.Visible=false;board.update({MatchID=9,Phase="Results",Tick=30,RestartAt=200,Rankings={}});assert(not board.Panel.Visible,"Results stats must not reopen a closed panel")
 print("Live top ten: 500 participants, local outside rank, locate, crown transfer, ties, elimination, hidden allocation and results close persistence passed.")
end

do
 local root=Instance.new("Frame");local viewport=Instance.new("Frame");viewport.Parent=root
 local labels={};for i=1,6 do labels[i]=Instance.new("TextLabel")end
 local left=0
 local ui=StrategyUI.new(root,viewport,labels[1],labels[2],labels[3],labels[4],labels[5],labels[6],{},function()left+=1 end)
 click(root,"Leave Game");assert(root:FindFirstChild("LeaveConfirmation").Visible and left==0)
 click(root,"Stay");assert(not root:FindFirstChild("LeaveConfirmation").Visible and left==0)
 click(root,"Leave Game");click(root,"Leave Match");assert(left==1 and not root:FindFirstChild("LeaveConfirmation").Visible)
 ui.Army.Visible=true;root:GetDescendants();local x=root:FindFirstChild("ArmyClose");assert(x and x.Visible);x.Activated:Fire();assert(not ui.Army.Visible)
 ui.Army.Visible=true;input.InputBegan:Fire({KeyCode=Enum.KeyCode.Escape},true);assert(not ui.Army.Visible,"Escape closes custom panels even when CoreGui processes it")
 print("Permanent Leave confirmation, Stay, server callback and independent graphical close controls passed.")
end

-- Stage 14: real adapters share the horizontal construction menu and exact orders.
do
 profile.Spectator=false;owned.Type="Warship";shop.attach(navy,missiles)
 shop.update(profile,"Started");navy.update(profile,"Started");missiles.update(profile,"Started")
 for _,entry in ipairs({{"Warship","Warship"},{"Atom Bomb","AtomBomb"},{"Hydrogen Bomb","HydrogenBomb"},{"MIRV","MIRV"}})do
  shop.Panel.Visible=true;shop.update(profile,"Started");click(shop.Panel,entry[1])
  if entry[2]=="Warship"then assert(navy.click(100,120))else assert(missiles.click(100,120))end
  assert((orders[#orders].Type or orders[#orders].Action)==entry[2])
 end
 assert(shop.Panel.ScrollingDirection==Enum.ScrollingDirection.X)
 print("Horizontal construction: six existing buildings plus warship/three missiles share authoritative actions and quotes.")
end
do
 local root=Instance.new("Frame");local viewport=Instance.new("Frame");viewport.Parent=root
 local labels={};for i=1,6 do labels[i]=Instance.new("TextLabel")end
 local fits,focus,ratio,nation=0,0,nil,nil
 local ui=nil
 -- A separate instance supplies explicit map callbacks for phase transitions.
 root=Instance.new("Frame");viewport=Instance.new("Frame");viewport.Parent=root
 ui=StrategyUI.new(root,viewport,labels[1],labels[2],labels[3],labels[4],labels[5],labels[6],{reset=function()fits+=1 end,focus=function()focus+=1 end})
 ui.bindAllocation(function(value)ratio=value end);ui.bindNation(function(value)nation=value end)
 click(root,"35%");assert(ratio==.35)
 local field=root:FindFirstChild("SpawnSelection"):FindFirstChild("NationNameInput");field.Text="Nova Republic";click(root,"Save name");assert(nation=="Nova Republic")
 local p={UserId=7,Troops=1000,Cap=2000,Count=100,Gold="100",Spawn=1,X=1,Y=1}
 local state={Phase="Selecting",Players={p},SelectedSpawns=3,Participants=20,EndTick=200,Tick=50}
 ui.stats(p,state);assert(fits==1)
 assert(root:FindFirstChild("SpawnSelection").Visible and not root:FindFirstChild("CommandBar").Visible)
 state.Phase="Started";ui.stats(p,state);ui.stats(p,state);assert(focus==1 and root:FindFirstChild("CommandBar").Visible)
 p.Economy={Gold="100",Base="1000",Rail="500",Sea="750",Total="2250",Cities=1,Factories=2,Ports=3,ActiveRoutes=4};ui.stats(p,state)
 local economy=root:FindFirstChild("Economy");assert(economy and not economy.Visible)
 root:FindFirstChild("CommandBar"):FindFirstChild("ViewEconomy").Activated:Fire()
 assert(economy.Visible and economy:FindFirstChild("RailValue").Text=="500")
 root:FindFirstChild("EconomyClose").Activated:Fire();assert(not economy.Visible)
 for _,size in ipairs({{320,568},{390,844},{844,390},{768,1024},{1024,768},{1920,1080}})do
  root.AbsoluteSize=Vector2.new(size[1],size[2]);local bar=root:FindFirstChild("CommandBar");assert(bar.Size.X.Offset<=size[1] and bar.Size.Y.Offset<=132)
 end
 print("Floating HUD: exact allocation callback, accessible nation submission, selecting/gameplay visibility, one-time fit/focus and phone/tablet/desktop bounds passed.")
end
