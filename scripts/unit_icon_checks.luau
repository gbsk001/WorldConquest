local parent=Instance.new("Frame")
local saved=game.GetService;local allocations=0
Content={fromObject=function(v)return v end}
game.GetService=function(self,name)
 if name=="AssetService"then return {CreateEditableImage=function(_,options)
  allocations+=1;assert(options.Size.X==512 and (options.Size.Y==512 or options.Size.Y==256))
  local image={};function image:WritePixelsBuffer(_,_,pixels)self.Pixels=pixels end;return image
 end}end
 return saved(self,name)
end
for kind,cell in pairs(IconAssets.Registry)do
 local icon=Art.icon(parent,kind,24,Color3.new(1,1,1))
 assert(icon.ClassName=="ImageLabel"and icon.BackgroundTransparency==1 and #icon:GetDescendants()==0)
 assert(icon:GetAttribute("IconReady")and icon.ResampleMode==Enum.ResamplerMode.Default)
 local count=0
 for y=cell.Y,cell.Y+127 do for x=cell.X,cell.X+127 do if buffer.readu8(icon.ImageContent.Pixels,(y*512+x)*4+3)>0 then count+=1 end end end
 assert(count>80 and count<10000,"Missing or opaque icon")
end
assert(allocations==4,"shared lazy atlas pages")
for _=1,100 do Art.mapIcon(parent,"City",24,Color3.new(1,1,1))end
assert(allocations==4,"no repeated texture creation")
print("Licensed icons: all registry entries decode to transparent image cells, four shared atlases, no frame/letter geometry.")
game.GetService=function(self,name)if name=="AssetService"then return {CreateEditableImage=function()error("Image API denied")end}end;return saved(self,name)end
local denied=createIconAssets()
local missing=denied.new(parent,"Army",24,Color3.new(1,1,1))
assert(missing.ClassName=="ImageLabel"and missing:GetAttribute("IconAssetUploadRequired")and #missing:GetDescendants()==0)
assert(not missing:GetAttribute("IconReady"),"Never pretend an absent uploaded atlas is ready")
game.GetService=saved
print("Image API denial: labelled upload-required state, no fabricated asset IDs or frame substitute.")
local layer=Layer.new(8192,function()return {Destroy=function()end}end,function(u,colors,set) set("Text","")end,nil,true)
local units={};for i=1,5000 do units[i]={ID=i,Tile=(i*7919)%(8192*4096)}end
layer.set(units,{})
local times={};local created=0
for i=1,200 do local t=os.clock();layer.update(-i*2,-i,.3,1920,1080);times[i]=(os.clock()-t)*1000;assert(layer.Visible<=256)end
created=layer.Created;local t=os.clock();for _=1,1000 do layer.update(-400,-200,.3,1920,1080)end;assert(layer.Created==created)
table.sort(times);local sum=0;for _,v in ipairs(times)do sum+=v end
print(string.format("ICON_CPU 5000 units avg %.3f p95 %.3f worst %.3f ms; max 256 visible; cached stationary updates; no Roblox GPU claim",sum/#times,times[190],times[200]))
