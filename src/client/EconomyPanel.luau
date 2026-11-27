--!strict
-- Read-only presentation of authoritative in-match gold, never permanent Stars.
local Money=require(game:GetService("ReplicatedStorage").Shared.OpenFront.MoneyFormat)
local Panel={}
function Panel.new(parent)
 local labels={};local latest=nil
 local entries={{"Gold","Gold balance"},{"Base","Base income / s"},{"Rail","Rail trade / s"},{"Sea","Maritime trade / s"},{"Total","Total income / s"},{"Cities","Cities"},{"Factories","Factories"},{"Ports","Ports"},{"ActiveRoutes","Working rail links + trade ships"}}
 local title=Instance.new("TextLabel");title.Name="EconomyHeading";title.BackgroundTransparency=1;title.Text="ECONOMY";title.Font=Enum.Font.GothamBold;title.TextSize=19;title.TextColor3=Color3.fromRGB(241,190,91);title.Position=UDim2.fromOffset(14,12);title.Size=UDim2.new(1,-70,0,30);title.TextXAlignment=Enum.TextXAlignment.Left;title.Parent=parent
 for i,e in ipairs(entries)do
  local name=Instance.new("TextLabel");name.Name=e[1].."Name";name.BackgroundTransparency=1;name.Text=e[2];name.TextSize=13;name.Font=Enum.Font.GothamMedium;name.TextColor3=Color3.fromRGB(185,201,222);name.Position=UDim2.fromOffset(14,48+(i-1)*34);name.Size=UDim2.new(.65,-14,0,32);name.TextXAlignment=Enum.TextXAlignment.Left;name.TextWrapped=true;name.Parent=parent
  local value=Instance.new("TextLabel");value.Name=e[1].."Value";value.BackgroundTransparency=1;value.Text="—";value.TextSize=16;value.Font=Enum.Font.GothamBold;value.TextColor3=Color3.fromRGB(241,245,250);value.Position=UDim2.new(.65,0,0,48+(i-1)*34);value.Size=UDim2.new(.35,-14,0,32);value.TextXAlignment=Enum.TextXAlignment.Right;value.Parent=parent;labels[e[1]]=value
 end
 local note=Instance.new("TextLabel");note.BackgroundTransparency=1;note.Text="Trade rates show recent completed deliveries (up to 30 seconds), not guaranteed income. Tap a building to inspect its contribution.";note.TextWrapped=true;note.TextSize=12;note.Font=Enum.Font.Gotham;note.TextColor3=Color3.fromRGB(164,183,207);note.Position=UDim2.fromOffset(14,360);note.Size=UDim2.new(1,-28,0,74);note.Parent=parent
 parent.CanvasSize=UDim2.fromOffset(0,448)
 local function paint()if not latest or not parent.Visible then return end;for key,label in pairs(labels)do label.Text=Money.money(latest[key]or 0)end end
 parent:GetPropertyChangedSignal("Visible"):Connect(paint)
 return {update=function(p)latest=p and p.Economy;paint()end}
end
return Panel
