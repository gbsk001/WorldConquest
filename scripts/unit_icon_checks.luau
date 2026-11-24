
local parent=Instance.new("Frame")
for _,kind in ipairs({"City","Factory","DefensePost","Port","SAMLauncher","MissileSilo","TransportShip","Warship","TradeShip","Train","Carriage","AtomBomb","HydrogenBomb","MIRV","MIRVWarhead","SAMMissile","Shell"})do
 local icon=Art.icon(parent,kind,24,Color3.new(1,1,1));assert(icon.BackgroundTransparency==1 and #icon:GetDescendants()>2)
 for _,child in ipairs(icon:GetDescendants())do assert(child.ClassName~="TextLabel" and child.ClassName~="ImageLabel","Only original graphical geometry")end
end
local layer=Layer.new(8192,function()return {Destroy=function()end}end,function(u,colors,set) set("Text","")end,nil,true)
local units={};for i=1,5000 do units[i]={ID=i,Tile=(i*7919)%(8192*4096)}end
layer.set(units,{})
local times={};local created=0
for i=1,200 do local t=os.clock();layer.update(-i*2,-i,.3,1920,1080);times[i]=(os.clock()-t)*1000;assert(layer.Visible<=256)end
created=layer.Created;local t=os.clock();for _=1,1000 do layer.update(-400,-200,.3,1920,1080)end;assert(layer.Created==created)
table.sort(times);local sum=0;for _,v in ipairs(times)do sum+=v end
print(string.format("ICON_CPU 5000 units avg %.3f p95 %.3f worst %.3f ms; max 256 visible; cached stationary updates; no Roblox GPU claim",sum/#times,times[190],times[200]))
print("17 original graphical unit/building types, transparent containers, bounded density and stable pooling passed.")

-- Raster atlas uses the exact same original geometry with transparent gutters.
local saved=game.GetService;local upload=nil;local allocations=0
Content={fromObject=function(v)return v end}
game.GetService=function(self,name)
 if name=="AssetService"then return {CreateEditableImage=function(_,options)
  allocations+=1;assert(options.Size.X==512 and options.Size.Y==256)
  return {WritePixelsBuffer=function(_,_,_,pixels)upload=pixels end}
 end}end
 return saved(self,name)
end
Art.prepareMapIcons();Art.prepareMapIcons();assert(allocations==1 and upload)
for i,kind in ipairs({"City","Factory","DefensePost","Port","SAMLauncher","MissileSilo","TransportShip","Warship","TradeShip","Train","Carriage","AtomBomb","HydrogenBomb","MIRV","MIRVWarhead","SAMMissile","Shell","Crown"})do
 local icon=Art.mapIcon(parent,kind,24,Color3.new(1,1,1));assert(icon.ClassName=="ImageLabel" and icon.BackgroundTransparency==1 and #icon:GetDescendants()==0)
 local count=0;local ox,oy=((i-1)%8)*64,math.floor((i-1)/8)*64
 for y=0,63 do for x=0,63 do if buffer.readu8(upload,((oy+y)*512+ox+x)*4+3)>0 then count+=1 end end end
 assert(count>20 and count<3000,"Missing or opaque atlas icon")
end
print("Original map atlas: 18 transparent graphical cells, shared texture allocation and one GUI object per icon passed (CPU/stubs).")
