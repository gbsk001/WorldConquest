--!strict
-- Rasterised existing flag designs, shared with shop and map. AGPL-3.0.
local Catalog=require(game:GetService("ReplicatedStorage").Shared.ProgressionCatalog)
local Art=require(script.Parent.InterfaceArt)
local Cosmetic={}
function Cosmetic.tint(equipped,category,fallback)
 local item=equipped and Catalog.ByID[equipped[category]];return if item and item.Tint then Color3.fromHex(item.Tint)else fallback
end
function Cosmetic.flag(parent,id,width)
 local item=Catalog.ByID[id];if not item or item.Category~="Flag"then return nil end
 local root=Art.icon(parent,"Flag_"..id,width,Color3.new(1,1,1));root.Name="NationFlag";root.Size=UDim2.fromOffset(width,width*.6);root.ZIndex=(parent.ZIndex or 1)+1

 return root
end
function Cosmetic.preview(parent,item,size)
 if item.Category=="Flag"then return Cosmetic.flag(parent,item.ID,size)end
 return Art.icon(parent,item.Icon or "Rank",size,Color3.fromHex(item.Tint or "D9BB75"))
end
return Cosmetic
