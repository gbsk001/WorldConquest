--!strict
-- Roblox intent-only missile controls. Costs, silos, trajectories and hits are server-owned.
local Money = require(game:GetService("ReplicatedStorage").Shared.OpenFront.MoneyFormat)
local Art=require(script.Parent.InterfaceArt)
local Controls={}
function Controls.new(parent,send,notice,nextSequence,cancelOther)
 local profile,phase,mode=nil,nil,nil;local api={}
 local panel=Instance.new("ScrollingFrame");panel.Name="MissileControls";panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-8,0,36);panel.Size=UDim2.new(1,-16,0,240);panel.BackgroundColor3=Color3.fromRGB(20,36,48);panel.Visible=false;panel.ZIndex=32;panel.Parent=parent
 local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(290,240);limit.Parent=panel
 local toggle=Instance.new("TextButton");toggle.Size=UDim2.fromOffset(90,28);toggle.Position=UDim2.new(1,-286,0,4);toggle.Text="Missiles";toggle.TextColor3=Color3.new(1,1,1);toggle.BackgroundColor3=Color3.fromRGB(37,60,76);toggle.ZIndex=32;toggle.Parent=parent
 function api.cancel()mode=nil;panel.Visible=false;toggle.Text="Missiles" end
 toggle.Activated:Connect(function()if mode then api.cancel() else cancelOther();panel.Visible=not panel.Visible end end)
 local rows={}
 for i,entry in ipairs({{"AtomBomb","Atomic bomb"},{"HydrogenBomb","Hydrogen bomb"},{"MIRV","MIRV"}}) do
  local kind=entry[1];local row=Instance.new("TextButton");row.Size=UDim2.new(1,-12,0,42);row.Position=UDim2.fromOffset(6,6+(i-1)*46);row.Text=entry[2];row.TextWrapped=true;row.TextSize=13;row.TextColor3=Color3.new(1,1,1);row.BackgroundColor3=Color3.fromRGB(47,58,72);row.ZIndex=33;row.Parent=panel;local symbol=Art.icon(row,kind,18,Color3.fromRGB(173,208,233));symbol.Position=UDim2.fromOffset(8,10);local padding=Instance.new("UIPadding");padding.PaddingLeft=UDim.new(0,34);padding.PaddingRight=UDim.new(0,6);padding.Parent=row;rows[kind]={Button=row,Name=entry[2]}
  row.Activated:Connect(function()
   local quote=profile and profile.Missiles and profile.Missiles.Quotes[kind]
   if phase~="Started" or not profile or profile.Spectator or profile.Eliminated or not quote or not quote.Affordable then notice("Missile unavailable or insufficient gold.");return end
   cancelOther();mode=kind;panel.Visible=false;toggle.Text="Cancel target";notice("Choose a target for "..entry[2]..". The nearest ready silo launches; the server validates the target.")
  end)
 end
 local summary=Instance.new("TextLabel");summary.Size=UDim2.new(1,-12,0,90);summary.Position=UDim2.fromOffset(6,146);summary.BackgroundTransparency=1;summary.TextWrapped=true;summary.TextSize=12;summary.TextColor3=Color3.fromRGB(210,220,230);summary.ZIndex=33;summary.Parent=panel
 function api.update(p,currentPhase)
  profile=p;phase=currentPhase
  if phase~="Started"or p and (p.Eliminated or p.Spectator)then api.cancel();return end
  if not panel.Visible then return end
  local ready,slots,sams,reload=0,0,0,0
  if p and p.Missiles then
   for _,u in ipairs(p.Missiles.Structures) do if u.Type=="MissileSilo" then ready+=u.Ready;slots+=u.Level;reload=math.max(reload,u.Reload) else sams+=1 end end
   for kind,row in pairs(rows) do local q=p.Missiles.Quotes[kind];row.Button.Text=row.Name.."  $"..Money.money(q.Cost);row.Button.TextColor3=if q.Affordable and ready>0 then Color3.new(1,1,1) else Color3.fromRGB(150,160,170) end
  end
  summary.Text=string.format("Silo slots ready %d/%d | Reload ≤ %.1fs\nSAM launchers %d (automatic)\nSAM defence intercepts automatically",ready,slots,reload/10,sams)
  if phase~="Started" or p and (p.Spectator or p.Eliminated) then api.cancel() end
 end
 function api.click(x,y)
  if not mode then return false end
  send({Type=mode,X=x,Y=y,Sequence=nextSequence()});api.cancel();return true
 end
 game:GetService("UserInputService").InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.Escape then api.cancel() end end)
 panel.CanvasSize=UDim2.fromOffset(0,310);panel.ScrollBarThickness=4;panel.ScrollingDirection=Enum.ScrollingDirection.Y
 panel:GetPropertyChangedSignal("Visible"):Connect(function()if panel.Visible then api.update(profile,phase)end end)
 api.Panel=panel;api.Toggle=toggle
 return api
end
return Controls
