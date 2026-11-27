--!strict
-- Licensed Lucide icons; ISC and Feather MIT notices in assets/lucide/LICENSE.
-- Only ImageLabels. No procedural/frame/letter fallback. Upload the PNG atlases
-- and set AtlasAssetIDs for clients on which EditableImage is unavailable.
local data=script.Parent.IconData
local registry=require(data.Registry)
local API={AtlasAssetIDs={0,0,0,0},Registry=registry}
local pages={};local pending={};local failed={};local uploadedReady={}
local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";local digits={}
for i=1,#alphabet do digits[string.byte(alphabet,i)]=i-1 end
local function decode(text)
 local pad=if text:sub(-2)=="=="then 2 elseif text:sub(-1)=="="then 1 else 0
 local out=buffer.create(#text/4*3-pad);local pos=0
 for i=1,#text,4 do local a,b,c,d=string.byte(text,i,i+3);local v=digits[a]*262144+digits[b]*4096+(digits[c]or 0)*64+(digits[d]or 0)
  buffer.writeu8(out,pos,math.floor(v/65536));pos+=1
  if pos<buffer.len(out)then buffer.writeu8(out,pos,math.floor(v/256)%256);pos+=1 end
  if pos<buffer.len(out)then buffer.writeu8(out,pos,v%256);pos+=1 end
 end;return out
end
local function apply(label,page)
 if not label.Parent then return end
 if pages[page]then label.ImageContent=Content.fromObject(pages[page]);label:SetAttribute("IconReady",true)
 else label:SetAttribute("IconAssetUploadRequired",true)end
end
local function prepare(page)
 local ok,img=pcall(function()
  local height=if page==4 then 256 else 512
  local texture=game:GetService("AssetService"):CreateEditableImage({Size=Vector2.new(512,height)})
  if not texture then return nil end
  local raw=decode(require(data:FindFirstChild("Page"..page)))
  local pixels=buffer.create(512*height*4);local pixel=0;local deadline=os.clock()+.002
  for i=0,buffer.len(raw)-1,(if page==4 then 6 else 3)do
   local count=buffer.readu16(raw,i);local rgba=if page==4 then buffer.readu32(raw,i+2)else 16777215+buffer.readu8(raw,i+2)*16777216
   for _=1,count do buffer.writeu32(pixels,pixel*4,rgba);pixel+=1 end
   if task.wait and os.clock()>=deadline then task.wait();deadline=os.clock()+.002 end
  end
  assert(pixel==512*height,"Invalid icon atlas")
  texture:WritePixelsBuffer(Vector2.zero,Vector2.new(512,height),pixels);return texture
 end)
 if ok and img then pages[page]=img else failed[page]=true end
 local labels=pending[page]or {};pending[page]=nil
 for label in pairs(labels)do apply(label,page)end
end
function API.new(parent,kind,size,color)
 local cell=assert(registry[kind],"Unregistered icon: "..tostring(kind))
 local label=Instance.new("ImageLabel");label.Name=kind.."Icon";label.BackgroundTransparency=1;label.BorderSizePixel=0
 label.Active=false;label.Size=UDim2.fromOffset(size,size);label.ScaleType=Enum.ScaleType.Fit;label.ResampleMode=Enum.ResamplerMode.Default
 label.ImageColor3=if cell.Colored then Color3.new(1,1,1)else color;label.ImageRectOffset=Vector2.new(cell.X,cell.Y);label.ImageRectSize=Vector2.new(cell.Width or 128,cell.Height or 128);label.Parent=parent
 label:SetAttribute("IconSource",cell.Source)
 local id=API.AtlasAssetIDs[cell.Page]
 if id and id>0 then
  label:SetAttribute("IconAtlasAssetID",id);label.Image="rbxassetid://"..id
  local function loaded()
   label:SetAttribute("IconReady",label.IsLoaded==true)
   if label.IsLoaded then uploadedReady[cell.Page]=true end
  end
  label:GetPropertyChangedSignal("IsLoaded"):Connect(loaded);loaded()
 elseif pages[cell.Page]or failed[cell.Page]then apply(label,cell.Page)
 else
  local start=not pending[cell.Page]
  pending[cell.Page]=pending[cell.Page]or setmetatable({},{__mode="k"});pending[cell.Page][label]=true
  if start then if task.defer then task.defer(prepare,cell.Page)else prepare(cell.Page)end end
 end
 return label
end
function API.ready()return next(pages)~=nil or next(uploadedReady)~=nil end
return API
