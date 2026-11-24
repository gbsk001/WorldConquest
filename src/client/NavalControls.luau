--!strict
-- Roblox input adapter. Orders contain intent only; pricing, routes and outcomes live on the server.
local MoneyFormat = require(game:GetService("ReplicatedStorage").Shared.OpenFront.MoneyFormat)
local Art=require(script.Parent.InterfaceArt)
local Controls={}
function Controls.new(parent,send,notice,hit,nextSequence,allocation,cancelBuilding)
 local profile,phase,mode,selected=nil,nil,nil,nil
 local panel=Instance.new("ScrollingFrame");panel.Name="NavalControls";panel.Size=UDim2.new(1,-16,0,210);panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-8,0,36);local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(285,210);limit.Parent=panel;panel.BackgroundColor3=Color3.fromRGB(20,36,48);panel.ZIndex=30;panel.Visible=false;panel.Active=true;panel.Parent=parent
 local toggle=Instance.new("TextButton");toggle.Size=UDim2.fromOffset(90,28);toggle.Position=UDim2.new(1,-192,0,4);toggle.Text="Navy";toggle.TextColor3=Color3.new(1,1,1);toggle.BackgroundColor3=Color3.fromRGB(37,60,76);toggle.ZIndex=30;toggle.Parent=parent
 local api={}
 function api.cancel()mode=nil;selected=nil;toggle.Text="Navy";panel.Visible=false end
 toggle.Activated:Connect(function()if mode then api.cancel() else if not panel.Visible then cancelBuilding() end;panel.Visible=not panel.Visible end end)
 local function select(value)
  if phase~="Started" or not profile or profile.Spectator or profile.Eliminated then notice("Spawn into the match first.");return end
  cancelBuilding();mode=value;selected=nil;panel.Visible=false;toggle.Text="Cancel naval"
  notice(if value=="Transport" then "Click an unclaimed or enemy coast. Uses the army allocation; maximum 3 transports; no port required." elseif value=="Warship" then "Click water reachable from your completed port to buy a patrolling warship." elseif value=="Move" then "Click your warship, then its new patrol location." else "Click your transport to return it to your coast. Successful return loses 25% of its troops.")
 end
 local rows={}
 for i,entry in ipairs({{"Transport","Launch invasion"},{"Warship","Buy warship"},{"Move","Move warship"},{"Retreat","Return transport"}}) do
  local action=entry[1];local b=Instance.new("TextButton");b.Size=UDim2.new(1,-12,0,44);b.Position=UDim2.fromOffset(6,6+(i-1)*48);b.Text=entry[2];b.TextSize=13;b.TextColor3=Color3.new(1,1,1);b.BackgroundColor3=Color3.fromRGB(37,60,76);b.ZIndex=31;b.Parent=panel;local kind=if string.find(string.lower(entry[2]),"warship")then "Warship"elseif string.find(string.lower(entry[2]),"trade")then "TradeShip"else "TransportShip";local symbol=Art.icon(b,kind,18,Color3.fromRGB(173,208,233));symbol.Position=UDim2.fromOffset(8,10);local padding=Instance.new("UIPadding");padding.PaddingLeft=UDim.new(0,34);padding.PaddingRight=UDim.new(0,6);padding.Parent=b;rows[action]=b
  b.Activated:Connect(function()if action=="Warship" and (not profile or not profile.Naval or not profile.Naval.Affordable) then notice("Insufficient money for a warship.");return end;select(action)end)
 end
 local summary=Instance.new("TextLabel");summary.Size=UDim2.new(1,-12,0,58);summary.Position=UDim2.fromOffset(6,202);summary.BackgroundTransparency=1;summary.TextWrapped=true;summary.TextSize=12;summary.TextColor3=Color3.new(1,1,1);summary.ZIndex=31;summary.Text="Ports trade automatically with other players unless embargoed.";summary.Parent=panel
 function api.update(p,currentPhase)
  profile=p;phase=currentPhase
  if phase~="Started"or p and (p.Eliminated or p.Spectator)then api.cancel();return end
  if not panel.Visible then return end
  if p and p.Naval then rows.Warship.Text="Buy warship: $"..MoneyFormat.money(p.Naval.WarshipCost);summary.Text=string.format("Transports %d/3 | Warships %d | Trade %d\nPorts trade automatically with eligible destinations.",p.Naval.Transports,p.Naval.Warships,p.Naval.TradeShips) end
  if phase~="Started" or (p and (p.Eliminated or p.Spectator)) then api.cancel() end
 end
 function api.click(x,y)
  if not mode then return false end
  local order={Action=mode,X=x,Y=y,Allocation=allocation()}
  if mode=="Move" or mode=="Retreat" then
   if not selected then
    local unit=hit(x,y);local kind=if mode=="Move" then "Warship" else "TransportShip"
    if not unit or unit.Owner~=profile.SmallId or unit.Type~=kind then notice("Click your "..kind.." icon.");return true end
    selected=unit.ID;if mode=="Move" then notice(string.format("Warship #%d: %d health, veteran %d. Click the new patrol location.",unit.ID,unit.Health,unit.Veterancy));return true end
   end;order.UnitID=selected
  end
  order.Sequence=nextSequence();send(order);api.cancel();return true
 end
 game:GetService("UserInputService").InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.Escape then api.cancel() end end)
 panel.CanvasSize=UDim2.fromOffset(0,310);panel.ScrollBarThickness=4;panel.ScrollingDirection=Enum.ScrollingDirection.Y
 panel:GetPropertyChangedSignal("Visible"):Connect(function()if panel.Visible then api.update(profile,phase)end end)
 api.Panel=panel;api.Toggle=toggle
 return api
end
return Controls
