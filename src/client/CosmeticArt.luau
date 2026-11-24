--!strict
-- Original resolution-independent flag geometry. AGPL-3.0.
local Catalog=require(game:GetService("ReplicatedStorage").Shared.ProgressionCatalog)
local Art=require(script.Parent.InterfaceArt)
local Cosmetic={}
function Cosmetic.tint(equipped,category,fallback)
 local item=equipped and Catalog.ByID[equipped[category]];return if item and item.Tint then Color3.fromHex(item.Tint)else fallback
end
function Cosmetic.flag(parent,id,width)
 local item=Catalog.ByID[id];if not item or item.Category~="Flag"then return nil end
 local root=Instance.new("Frame");root.Name="NationFlag";root.Size=UDim2.fromOffset(width,width*.6);root.BackgroundTransparency=1;root.ClipsDescendants=true;root.Active=false;root.ZIndex=(parent.ZIndex or 1)+1;root.Parent=parent
 local function rect(x,y,w,h,color)
  local r=Instance.new("Frame");r.BorderSizePixel=0;r.BackgroundColor3=Color3.fromHex(color);r.Position=UDim2.fromScale(x,y);r.Size=UDim2.fromScale(w,h);r.Active=false;r.ZIndex=root.ZIndex+1;r.Parent=root;return r
 end
 local colors=item.Colors;rect(0,0,1,1,colors[1])
 if item.Design=="Disc"then local d=rect(.32,.2,.36,.6,colors[2]);local round=Instance.new("UICorner");round.CornerRadius=UDim.new(1,0);round.Parent=d
 elseif item.Design=="Cross"then rect(.28,0,.14,1,colors[3]);rect(0,.38,1,.24,colors[3]);rect(.31,0,.08,1,colors[2]);rect(0,.43,1,.14,colors[2])
 elseif item.Design=="Vertical"then rect(1/3,0,1/3,1,colors[2]);rect(2/3,0,1/3,1,colors[3])
 else rect(0,1/3,1,1/3,colors[2]);rect(0,2/3,1,1/3,colors[3])end
 return root
end
function Cosmetic.preview(parent,item,size)
 if item.Category=="Flag"then return Cosmetic.flag(parent,item.ID,size)end
 return Art.icon(parent,item.Icon or "Rank",size,Color3.fromHex(item.Tint or "D9BB75"))
end
return Cosmetic
