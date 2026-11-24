--!strict
-- A fixed, touch-sized close control outside scrolling content.
local Art=require(script.Parent.InterfaceArt)
local Chrome={}
function Chrome.close(panel,callback)
 local parent=panel.Parent
 local b=Instance.new("TextButton");b.Name=panel.Name.."Close";b.Text="";b.Size=UDim2.fromOffset(44,44);b.BackgroundColor3=Color3.fromRGB(27,39,55);b.BackgroundTransparency=.12;b.BorderSizePixel=0;b.ZIndex=90;b.Parent=parent
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=b
 local icon=Art.icon(b,"Close",16,Color3.fromRGB(211,225,243));icon.Position=UDim2.fromOffset(14,14)
 local function update()
  b.Visible=panel.Visible;b.Position=UDim2.fromOffset(panel.AbsolutePosition.X-parent.AbsolutePosition.X+panel.AbsoluteSize.X-48,panel.AbsolutePosition.Y-parent.AbsolutePosition.Y+4)
 end
 panel:GetPropertyChangedSignal("Visible"):Connect(update)
 panel:GetPropertyChangedSignal("AbsolutePosition"):Connect(update)
 panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
 panel.Destroying:Connect(function()b:Destroy()end)
 b.Activated:Connect(function()panel.Visible=false;if callback then callback()end end)
 update();return b
end
return Chrome
