-- Local visual acceptance fixture only. Never packaged in release.
local p=game.Players.LocalPlayer
local art=require(p.PlayerScripts:WaitForChild("Client"):WaitForChild("InterfaceArt"))
local gui=Instance.new("ScreenGui");gui.Name="IconAcceptanceFixture";gui.DisplayOrder=1000;gui.Enabled=false;gui.Parent=p:WaitForChild("PlayerGui")
local frame=Instance.new("Frame");frame.Size=UDim2.fromScale(.85,.75);frame.Position=UDim2.fromScale(.075,.1);frame.BackgroundColor3=Color3.fromRGB(15,23,35);frame.Parent=gui
local types={"City","Factory","DefensePost","Port","SAMLauncher","MissileSilo","TransportShip","Warship","TradeShip","Train","Carriage","AtomBomb","HydrogenBomb","MIRV","MIRVWarhead","SAMMissile","Shell"}
for i,kind in ipairs(types)do local x=(i-1)%6;local y=math.floor((i-1)/6);local icon=art.icon(frame,kind,44,Color3.fromRGB(210,230,250));icon.Position=UDim2.new(x/6,34,y/3,30);local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Text=kind;t.TextColor3=Color3.new(1,1,1);t.TextSize=12;t.Size=UDim2.new(1/6,0,0,25);t.Position=UDim2.new(x/6,0,y/3,85);t.Parent=frame end
local title=Instance.new("TextLabel");title.Text="LOCAL ICON FIXTURE / G closes / extra gold & instant buildings";title.Size=UDim2.new(1,0,0,26);title.Position=UDim2.fromOffset(0,-26);title.BackgroundColor3=Color3.fromRGB(15,23,35);title.TextColor3=Color3.new(1,1,1);title.Parent=frame
game:GetService("UserInputService").InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.G then gui.Enabled=not gui.Enabled end end)
