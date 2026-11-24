--!strict
-- Prominent corresponding-source offer, no external upload or browser navigation.
local Offer={};local active=nil
function Offer.open()
 if active then active:Destroy()end
 local config=require(game:GetService("ReplicatedStorage").Shared.Config)
 local gui=Instance.new("ScreenGui");gui.Name="WorldConquestSource";gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.DisplayOrder=90;gui.ResetOnSpawn=false;gui.Parent=game:GetService("Players").LocalPlayer.PlayerGui;active=gui
 local root=Instance.new("TextButton");root.Text="";root.AutoButtonColor=false;root.BackgroundColor3=Color3.fromRGB(13,22,36);root.Size=UDim2.fromScale(1,1);root.Parent=gui
 local panel=Instance.new("ScrollingFrame");panel.Size=UDim2.new(1,-32,1,-32);panel.Position=UDim2.fromOffset(16,16);panel.BackgroundTransparency=1;panel.BorderSizePixel=0;panel.ScrollBarThickness=4;panel.AutomaticCanvasSize=Enum.AutomaticSize.Y;panel.CanvasSize=UDim2.new();panel.Parent=root
 local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,12);layout.Parent=panel
 local function text(value,height)
  local t=Instance.new("TextLabel");t.Text=value;t.BackgroundTransparency=1;t.Size=UDim2.new(1,-12,0,height);t.TextWrapped=true;t.Font=Enum.Font.Gotham;t.TextSize=16;t.TextColor3=Color3.fromRGB(231,238,247);t.LayoutOrder=#panel:GetChildren();t.Parent=panel
 end
 local close=Instance.new("TextButton");close.Size=UDim2.new(1,-12,0,48);close.Text="Close";close.Font=Enum.Font.GothamBold;close.TextSize=16;close.Parent=panel;close.Activated:Connect(function()gui:Destroy();active=nil end)
 text("WorldConquest • Source & licences",48)
 text("Unofficial OpenFront adaptation. Copyright OpenFront and Contributors. Licensed under AGPL-3.0; see the preserved LICENSE and NOTICE for the licence and additional terms.",110)
 text("Complete corresponding source, modifications, dependency notices and build instructions:",72)
 local address=Instance.new("TextBox");address.Text=config.SourceURL;address.ClearTextOnFocus=false;address.TextEditable=false;address.AutoLocalize=false;address.TextWrapped=true;address.Font=Enum.Font.Code;address.TextSize=15;address.TextColor3=Color3.fromRGB(237,204,133);address.BackgroundColor3=Color3.fromRGB(25,37,55);address.Size=UDim2.new(1,-12,0,88);address.LayoutOrder=#panel:GetChildren();address.Parent=panel
 text("Copy the source address below to your browser.",48)
end
return Offer
