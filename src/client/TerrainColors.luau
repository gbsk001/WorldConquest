--!strict
-- Public-domain Natural Earth II, native 8192x4096 display grid. AGPL-3.0 adapter.
-- Lazy immutable pages: one shared 2 MiB cache, never one terrain copy per owner.
local folder=game:GetService("ReplicatedStorage").Shared.Geography
local palette=require(folder.Palette)
local levels={};local cache={};local sequence=0;local count=0
local digits={};local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
for i=1,#alphabet do digits[string.byte(alphabet,i)]=i-1 end
local function decode(text)
 local padding=if string.sub(text,-2)=="=="then 2 elseif string.sub(text,-1)=="="then 1 else 0
 local length=#text/4*3-padding;local out=buffer.create(length);local pos=0
 for i=1,#text,4 do
  local a,b,c,d=string.byte(text,i,i+3)
  local value=digits[a]*262144+digits[b]*4096+(digits[c]or 0)*64+(digits[d]or 0)
  buffer.writeu8(out,pos,math.floor(value/65536));pos+=1
  if pos<length then buffer.writeu8(out,pos,math.floor(value/256)%256);pos+=1 end
  if pos<length then buffer.writeu8(out,pos,value%256);pos+=1 end
 end
 return out
end
local api={Misses=0}
function api.sample(level,x,y)
 level=math.clamp(level,0,6)
 local data=levels[level]
 if not data then data=require(folder:FindFirstChild("Level"..level));levels[level]=data end
 if y<0 or y>=data.Height then return 39,91,133 end
 x=x%data.Width
 local key=math.floor(y/data.TileHeight)*math.ceil(data.Width/data.TileWidth)+math.floor(x/data.TileWidth)+1
 local id=level*100000+key;local page=cache[id];sequence+=1
 if not page then
  api.Misses+=1
  if count>=512 then local oldest,age=nil,math.huge;for k,p in pairs(cache)do if p.Used<age then oldest=k;age=p.Used end end;cache[oldest]=nil;count-=1 end
  local encoded=decode(data.Tiles[key]);local pixels
  if buffer.readu8(encoded,0)==0 then pixels=buffer.create(buffer.len(encoded)-1);buffer.copy(pixels,0,encoded,1)
  else
   pixels=buffer.create(data.TileWidth*data.TileHeight);local out=0
   for pos=1,buffer.len(encoded)-1,2 do local n=buffer.readu8(encoded,pos)+1;buffer.fill(pixels,out,buffer.readu8(encoded,pos+1),n);out+=n end
   assert(out==buffer.len(pixels),"Invalid geography page")
  end
  page={Pixels=pixels,Used=sequence};cache[id]=page;count+=1
 end
 page.Used=sequence
 local color=palette[buffer.readu8(page.Pixels,(y%data.TileHeight)*data.TileWidth+x%data.TileWidth)+1]
 return color%256,math.floor(color/256)%256,math.floor(color/65536)
end
return api
