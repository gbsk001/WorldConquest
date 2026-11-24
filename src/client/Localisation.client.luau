--!strict
-- Localises all WorldConquest screens, including dynamic HUD text, once per change.
local Players=game:GetService("Players");local player=Players.LocalPlayer
local Localisation=require(script.Parent.Localisation)
local records=setmetatable({},{__mode="k"});local api=nil
local function visible(object)
 local root=object:FindFirstAncestorWhichIsA("ScreenGui")
 return root and string.sub(root.Name,1,13)=="WorldConquest"and root.Enabled
end
local function paint(object,record)
 if record.Writing or object.AutoLocalize==false or not visible(object)or not api then return end
 record.Writing=true;record.Applied=api.text(record.Source);object.Text=record.Applied;object.TextDirection=Enum.TextDirection.Auto;record.Writing=false
end
local function refresh()for object,record in pairs(records)do if object.Parent then paint(object,record)end end end
local function bind(object)
 if object:IsA("ScreenGui")and string.sub(object.Name,1,13)=="WorldConquest"then object:GetPropertyChangedSignal("Enabled"):Connect(refresh)end
 if not object:IsA("TextLabel")and not object:IsA("TextButton")then return end
 local record={Source=object.Text,Writing=false};records[object]=record
 local connection=object:GetPropertyChangedSignal("Text"):Connect(function()
  -- Roblox may defer property signals until after Writing is reset.
  if record.Writing or object.Text==record.Applied then return end;record.Source=object.Text;paint(object,record)
 end)
 object.Destroying:Connect(function()connection:Disconnect();records[object]=nil end)
 paint(object,record)
end
local root=player:WaitForChild("PlayerGui")
local function language()
 if api and api.destroy then api.destroy()end
 api=Localisation.new(player,root,refresh);refresh()
end
root.DescendantAdded:Connect(bind);for _,object in ipairs(root:GetDescendants())do bind(object)end
player:GetAttributeChangedSignal("WCLanguage"):Connect(language);language()
