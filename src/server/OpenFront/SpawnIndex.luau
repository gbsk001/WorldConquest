--!strict
-- Deterministic spatial reservations; presentation/placement adapter, not combat rules.
local Index={}
function Index.new(width,height)
 local buckets,entries={},{};local order,known={},{};local stride=math.ceil(width/32)
 local geo={};local geoSize=.06;height=height or width/2
 local function vector(tile)
  local lon=((tile%width+.5)/width*2-1)*math.pi
  local lat=(.5-(math.floor(tile/width)+.5)/height)*math.pi;local c=math.cos(lat)
  return c*math.cos(lon),math.sin(lat),c*math.sin(lon)
 end
 local function geoKey(x,y,z)return (x*1000+y)*1000+z end
 local function insertGeo(id,e)
  e.GX,e.GY,e.GZ=vector(e.Tile)
  e.GeoKey=geoKey(math.floor((e.GX+1)/geoSize),math.floor((e.GY+1)/geoSize),math.floor((e.GZ+1)/geoSize))
  geo[e.GeoKey]=geo[e.GeoKey]or {};geo[e.GeoKey][id]=e
 end
 local api={}
 function api.configureGeographic(km)
  geoSize=2*math.sin(km/6371/2);table.clear(geo)
  for id,e in pairs(entries)do insertGeo(id,e)end
 end
 function api.geographic(id,tile,km,botsOnly)
  local x,y,z=vector(tile);local chord=2*math.sin(km/6371/2);local found={}
  for bx=math.floor((x+1-chord)/geoSize),math.floor((x+1+chord)/geoSize)do
   for by=math.floor((y+1-chord)/geoSize),math.floor((y+1+chord)/geoSize)do
    for bz=math.floor((z+1-chord)/geoSize),math.floor((z+1+chord)/geoSize)do
     for other,e in pairs(geo[geoKey(bx,by,bz)]or {})do
      if other~=id and (botsOnly==nil or e.IsBot==botsOnly) and (e.GX-x)^2+(e.GY-y)^2+(e.GZ-z)^2<chord*chord then table.insert(found,other)end
     end
    end
   end
  end
  table.sort(found);return found
 end
 function api.remove(id)
  local old=entries[id];if not old then return end
  local bucket=buckets[old.Key];bucket[id]=nil;if not next(bucket)then buckets[old.Key]=nil end;entries[id]=nil
  local g=geo[old.GeoKey];g[id]=nil;if not next(g)then geo[old.GeoKey]=nil end
 end
 function api.set(id,tile,isBot)
  if not known[id]then known[id]=true;table.insert(order,id)end
  api.remove(id);local x,y=tile%width,math.floor(tile/width);local key=math.floor(y/32)*stride+math.floor(x/32)
  local entry={X=x,Y=y,Tile=tile,IsBot=isBot==true,Key=key};entries[id]=entry;buckets[key]=buckets[key]or {};buckets[key][id]=entry;insertGeo(id,entry)
 end
 function api.sample(random)if #order==0 then return nil end;return entries[order[random.nextInt(1,#order+1)]]end
 function api.near(id,tile,distance,botsOnly)
  local x,y=tile%width,math.floor(tile/width)
  for by=math.max(0,math.floor((y-distance)/32)),math.floor((y+distance)/32)do
   for bx=math.max(0,math.floor((x-distance)/32)),math.min(stride-1,math.floor((x+distance)/32))do
    for other,e in pairs(buckets[by*stride+bx]or {})do
     if other~=id and (botsOnly==nil or e.IsBot==botsOnly) and (e.X-x)^2+(e.Y-y)^2<distance*distance then return true end
    end
   end
  end
  return false
 end
 return api
end
return Index
