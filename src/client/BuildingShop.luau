--!strict
-- Roblox shop adapter. Rules are authoritative on the server; no price is sent.
local Rules = require(game:GetService("ReplicatedStorage").Shared.OpenFront.BuildingRules)
local MoneyFormat = require(game:GetService("ReplicatedStorage").Shared.OpenFront.MoneyFormat)
local Art=require(script.Parent.InterfaceArt)
local Chrome=require(script.Parent.PanelChrome)
local Shop={}
function Shop.new(parent,send,notice,hit,nextSequence,cancelNaval,preview)
 local mode=nil;local sequence=0;local profile=nil;local phase=nil
 local panel=Instance.new("ScrollingFrame");panel.Name="BuildingShop";panel.Size=UDim2.new(1,-16,0,164)
 panel.CanvasSize=UDim2.fromOffset(1500,0);panel.ScrollBarThickness=4;panel.ScrollingDirection=Enum.ScrollingDirection.X
 local maxSize=Instance.new("UISizeConstraint");maxSize.MaxSize=Vector2.new(1400,164);maxSize.Parent=panel
 panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-8,0,36);panel.BackgroundColor3=Color3.fromRGB(20,36,48);panel.BorderSizePixel=0;panel.ZIndex=30;panel.Visible=false;panel.Active=true;panel.Parent=parent
 local function button(text,y,height)
  local b=Instance.new("TextButton");b.Size=UDim2.new(1,-12,0,height);b.Position=UDim2.fromOffset(6,y)
  b.BackgroundColor3=Color3.fromRGB(37,60,76);b.TextColor3=Color3.new(1,1,1);b.TextWrapped=true;b.Font=Enum.Font.Gotham;b.TextSize=13;b.Text=text;b.ZIndex=31;b.Parent=panel
  return b
 end
 local toggle=Instance.new("TextButton");toggle.Name="Buildings";toggle.Size=UDim2.fromOffset(90,28);toggle.Position=UDim2.new(1,-98,0,4)
 toggle.Text="Buildings";toggle.TextSize=14;toggle.BackgroundColor3=Color3.fromRGB(37,60,76);toggle.TextColor3=Color3.new(1,1,1);toggle.ZIndex=30;toggle.Parent=parent
 toggle.Activated:Connect(function()if not panel.Visible and cancelNaval then cancelNaval() end;panel.Visible=not panel.Visible end)
 local rows={};local extraRows={};local attached=nil
 local function select(value)
  if phase~="Started" or not profile or profile.Spectator or profile.Eliminated then notice("Buildings are available after spawning into the match.");return end
  if cancelNaval then cancelNaval() end;mode=value;if preview then preview(if Rules.Info[value]then value else nil)end;panel.Visible=false;toggle.Text="Cancel placement";for kind,row in pairs(rows)do row:SetAttribute("Selected",kind==value)end
  notice(if value=="Upgrade" then "Click your completed building icon to buy one level." elseif value=="Demolish" then "Click your building icon to mark demolition (30 seconds; no refund)." else "Place "..Rules.Info[value].Name.." on your land. "..Rules.Info[value].Effect)
 end
 for index,kind in ipairs(Rules.Types) do
  local key=kind;local row=button(Rules.Info[kind].Name,(index-1)*72+6,66);rows[kind]=row
  row.Size=UDim2.fromOffset(108,128);row.Position=UDim2.fromOffset(8+(index-1)*116,8);row.TextYAlignment=Enum.TextYAlignment.Bottom;row.TextSize=13
  local icon=Art.icon(row,kind,36,Color3.fromRGB(211,224,236));icon.Position=UDim2.fromOffset(36,12)
  row.TextXAlignment=Enum.TextXAlignment.Center;local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,4);pad.PaddingRight=UDim.new(0,4);pad.PaddingBottom=UDim.new(0,12);pad.Parent=row
  row.Activated:Connect(function()
   local quote=profile and profile.BuildingQuotes and profile.BuildingQuotes[key]
   if not quote or not quote.Affordable or not quote.Enabled then notice("Building unavailable or insufficient money.");return end
   select(key)
  end)
 end
 local upgrade=button("Upgrade",8,54);upgrade.Position=UDim2.fromOffset(1170,8);upgrade.Size=UDim2.fromOffset(128,54);upgrade.Activated:Connect(function()select("Upgrade")end)
 local demolish=button("Demolish",70,54);demolish.Position=UDim2.fromOffset(1170,70);demolish.Size=UDim2.fromOffset(128,54);demolish.Activated:Connect(function()select("Demolish")end)
 local pending=Instance.new("TextLabel");pending.Position=UDim2.fromOffset(8,138);pending.Size=UDim2.fromOffset(1290,20);pending.BackgroundTransparency=1;pending.TextColor3=Color3.fromRGB(180,190,200);pending.TextWrapped=true;pending.TextSize=12;pending.ZIndex=31;pending.Text="Silos hold launch slots. SAM launchers intercept automatically.";pending.Parent=panel
 local api={}
 local detailHost=parent.Parent and parent.Parent:FindFirstChild("SafeInterface")or parent
 local selected=nil;local detail=Instance.new("ScrollingFrame");detail.Name="BuildingInfo";detail.Size=UDim2.new(1,-24,1,-24);detail.CanvasSize=UDim2.fromOffset(0,236);detail.ScrollBarThickness=4;detail.ScrollingDirection=Enum.ScrollingDirection.Y;detail.Position=UDim2.new(1,-12,0,64);detail.AnchorPoint=Vector2.new(1,0);detail.BackgroundColor3=Color3.fromRGB(15,23,35);detail.BackgroundTransparency=.08;detail.BorderSizePixel=0;detail.ZIndex=45;detail.Active=true;detail.Visible=false;detail.Parent=detailHost
 local detailLimit=Instance.new("UISizeConstraint");detailLimit.MaxSize=Vector2.new(310,224);detailLimit.Parent=detail
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=detail
 Chrome.close(detail)
 local description=Instance.new("TextLabel");description.BackgroundTransparency=1;description.Position=UDim2.fromOffset(56,12);description.Size=UDim2.new(1,-68,0,110);description.Font=Enum.Font.GothamMedium;description.TextSize=14;description.TextColor3=Color3.fromRGB(230,239,250);description.TextWrapped=true;description.TextXAlignment=Enum.TextXAlignment.Left;description.ZIndex=46;description.Parent=detail
 local function action(text,x,width,fn)
  local b=Instance.new("TextButton");b.Text=text;b.Position=UDim2.fromOffset(x,138);b.Size=UDim2.fromOffset(width,40);b.TextSize=13;b.Font=Enum.Font.GothamMedium;b.TextColor3=Color3.fromRGB(230,239,250);b.BackgroundColor3=Color3.fromRGB(32,52,71);b.ZIndex=46;b.Parent=detail;b.Activated:Connect(fn);return b
 end
 local function selectedAction(kind)
  if not selected or not profile or phase~="Started"or selected.Owner~=profile.SmallId or profile.Spectator or profile.Eliminated then notice("Select one of your buildings during gameplay.");return end
  sequence+=1;send({Action=kind,UnitID=selected.ID,Sequence=if nextSequence then nextSequence()else sequence});detail.Visible=false
 end
 local upgradeButton=action("Upgrade",12,136,function()selectedAction("Upgrade")end);upgradeButton.Size=UDim2.new(.5,-18,0,44)
 local demolishButton=action("Demolish",160,136,function()selectedAction("Demolish")end);demolishButton.Position=UDim2.new(.5,6,0,138);demolishButton.Size=UDim2.new(.5,-18,0,44)
 local close=action("Close",12,284,function()detail.Visible=false end);close.Position=UDim2.fromOffset(12,188);close.Size=UDim2.new(1,-24,0,44)
 function api.inspect(unit)
  if not Rules.Info[unit.Type]then return false end
  selected=unit;detail.Visible=true
  local own=profile and profile.SmallId==unit.Owner and phase=="Started"and not profile.Spectator and not profile.Eliminated
  upgradeButton.Visible=own and Rules.Info[unit.Type].Upgradeable and not unit.UnderConstruction;demolishButton.Visible=own and not unit.UnderConstruction
  local art=detail:FindFirstChild("InformationIcon");if art then art:Destroy()end
  art=Art.icon(detail,unit.Type,30,Color3.fromRGB(173,208,233));art.Name="InformationIcon";art.Position=UDim2.fromOffset(14,18);art.ZIndex=46
  local q=profile and profile.BuildingQuotes and profile.BuildingQuotes[unit.Type]
  description.Text=Rules.Info[unit.Type].Name.." / Level "..unit.Level.."\n"..Rules.Info[unit.Type].Effect.."\n"..(if Rules.Info[unit.Type].Upgradeable then "Upgrade $"..(if q then MoneyFormat.money(q.Cost)else "unavailable")else "Not upgradeable")..(if unit.UnderConstruction then "\nUnder construction"else "")
  return true
 end
 function api.cancel()if preview then preview(nil)end;detail.Visible=false;mode=nil;toggle.Text="Buildings";panel.Visible=false end
 toggle.Activated:Connect(function()if mode then api.cancel();panel.Visible=false end end)
 game:GetService("UserInputService").InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.Escape then api.cancel();panel.Visible=false end end)
 function api.update(p,currentPhase)
  profile=p;phase=currentPhase
  if phase~="Started"or p and (p.Eliminated or p.Spectator)then api.cancel();return end
  if not panel.Visible then return end
  if p and p.Rail then pending.Text=string.format("Rail: %d stations / %d trains / $%s earned\nAutomatic sea trade; SAM defence is automatic.",p.Rail.Stations,p.Rail.Trains,MoneyFormat.money(p.Rail.Gold)) end
  for kind,row in pairs(rows) do
   local info=Rules.Info[kind];local quote=p and p.BuildingQuotes and p.BuildingQuotes[kind]
   row.Text=info.Name.."\n$"..(if quote then MoneyFormat.money(quote.Cost) else "...")
   row:SetAttribute("Description",info.Effect)
   row.BackgroundColor3=if quote and quote.Affordable and quote.Enabled then Color3.fromRGB(24,48,64)else Color3.fromRGB(25,30,40)
   row.TextColor3=if quote and quote.Affordable and quote.Enabled then Color3.new(1,1,1) else Color3.fromRGB(155,165,175)
  end
  if phase~="Started" or (p and (p.Eliminated or p.Spectator)) then api.cancel() end
 end
 function api.attach(navy,missiles)
  if attached then return end;attached=true
  for i,entry in ipairs({{"Warship","Warship"},{"AtomBomb","Atom Bomb"},{"HydrogenBomb","Hydrogen Bomb"},{"MIRV","MIRV"}})do
   local kind=entry[1];local b=button(entry[2],8,128);b.Name=kind.."Construction";b.Position=UDim2.fromOffset(8+(i+5)*116,8);b.Size=UDim2.fromOffset(108,128);b.TextYAlignment=Enum.TextYAlignment.Bottom
   local pad=Instance.new("UIPadding");pad.PaddingBottom=UDim.new(0,12);pad.Parent=b
   local art=Art.icon(b,kind,36,Color3.fromRGB(211,224,236));art.Position=UDim2.fromOffset(36,12)
   extraRows[kind]={Button=b,Name=entry[2]}
   b.Activated:Connect(function()
    if kind=="Warship"then if navy then navy.select("Warship")end elseif missiles then missiles.select(kind)end
   end)
  end
 end
 local originalUpdate=api.update
 function api.update(p,currentPhase)
  originalUpdate(p,currentPhase)
  if not panel.Visible then return end
  for kind,r in pairs(extraRows)do
   local q=if kind=="Warship"then p and p.Naval else p and p.Missiles and p.Missiles.Quotes[kind]
   local cost=q and (q.Cost or q.WarshipCost)
   r.Button.Text=r.Name.."\n$"..(if cost then MoneyFormat.money(cost)else "...")
   r.Button.TextColor3=if q and q.Affordable then Color3.new(1,1,1)else Color3.fromRGB(145,155,173)
  end
 end
 function api.click(x,y)
  if not mode then local unit=hit(x,y);return if unit then api.inspect(unit)else false end
  if phase~="Started" or not profile or profile.Eliminated or profile.Spectator then api.cancel();return true end
  local order={Action="Build",Type=mode,X=x,Y=y}
  if mode=="Upgrade" or mode=="Demolish" then
   local unit=hit(x,y)
   if not unit or unit.Owner~=profile.SmallId then notice("Click one of your building icons.");return true end
   order={Action=mode,UnitID=unit.ID}
  end
  sequence+=1;order.Sequence=if nextSequence then nextSequence() else sequence;send(order);api.cancel();return true
 end
 panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
  local short=panel.AbsoluteSize.Y<150;local height=if short then 104 else 128
  for _,row in pairs(rows)do row.Size=UDim2.fromOffset(108,height)end
  for _,entry in pairs(extraRows)do entry.Button.Size=UDim2.fromOffset(108,height)end
  pending.Visible=not short;upgrade.Size=UDim2.fromOffset(128,if short then 44 else 54);demolish.Position=UDim2.fromOffset(1170,if short then 60 else 70);demolish.Size=UDim2.fromOffset(128,if short then 44 else 54)
 end)
 panel:GetPropertyChangedSignal("Visible"):Connect(function()if panel.Visible then api.update(profile,phase)end end)
 api.Panel=panel;api.Toggle=toggle
 return api
end
return Shop
