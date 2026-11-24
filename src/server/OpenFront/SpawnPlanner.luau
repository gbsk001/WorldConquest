--!strict
-- Original Earth spawn-distribution adapter. Gameplay footprints remain upstream.
-- Preserve LICENSE/NOTICE (AGPL-3.0). Geographic quotas are not political borders.
local Atlas = require(script.Parent.SpawnAtlas)
local Planner={}
local regions={};local total=0
for i,r in ipairs(Atlas.Regions)do regions[i]={Name=r.Name,Weight=r.Weight,Spans=buffer.fromstring(r.Spans)};total+=r.Weight end
function Planner.region(width,height,tile)
 local lon=(tile%width+.5)*360/width-180;local lat=90-(math.floor(tile/width)+.5)*180/height
 if lat < -60 then return 0 end
 if lon < -110 and lat < 25 or lon>=110 and lat < -10 or lon>=130 and lat<0 or lon>=160 and lat<20 then return 6 end
 if lon < -168 and lat>55 then return 5 end
 if lon < -30 then return if lat>=12 or lon<-77 and lat>=7 then 1 else 2 end
 local south=if lon < -5 then 36 elseif lon<15 then 38 elseif lon<28 then 35 elseif lon<45 then 42 else 55
 if lon>=-25 and lon<60 and lat>=south then return 3 end
 local east=if lat>=30 then 35 elseif lat>=12 then 32+(30-lat)*.65 else 60
 if lon>=-30 and lon<east and lat<38 then return 4 end
 return 5
end
function Planner.new(terrain,index)
 if terrain.Width~=Atlas.Width or terrain.Height~=Atlas.Height or terrain.MaskHash~=Atlas.MaskHash then return nil end
 local population=20;local reservations={};local counts={0,0,0,0,0,0};local humans={0,0,0,0,0,0};local outsideHumans=0
 local api={Regions=regions,Counts=counts,Quotas={},MinimumKm=1800,Attempts=0}
 local function quotas()
  local q=table.clone(humans);local assigned=outsideHumans;for _,n in ipairs(q)do assigned+=n end
  for _=assigned+1,population do
   local best,score=1,-math.huge
   for i,r in ipairs(regions)do local d=(population-outsideHumans)*r.Weight/total-q[i];if d>score then best,score=i,d end end
   q[best]+=1
  end
  api.Quotas=q
 end
 function api.configure(n)
  population=math.max(1,n);api.MinimumKm=math.clamp(1800*math.sqrt(20/population),300,1800)
  index.configureGeographic(api.MinimumKm);quotas()
 end
 function api.remove(id)
  local e=reservations[id];if not e then return end
  if e.Region>0 then counts[e.Region]-=1;if not e.IsBot then humans[e.Region]-=1 end
  elseif not e.IsBot then outsideHumans-=1 end
  reservations[id]=nil;if not e.IsBot then quotas()end
 end
 function api.reserve(id,tile,isBot)
  api.remove(id);local region=Planner.region(terrain.Width,terrain.Height,tile)
  reservations[id]={Region=region,IsBot=isBot==true}
  if region>0 then counts[region]+=1;if not isBot then humans[region]+=1 end
  elseif not isBot then outsideHumans+=1 end
  if not isBot then quotas()end
 end
 function api.excessBots()
  local extra={};local remaining=table.clone(counts);local ids={};for id in pairs(reservations)do table.insert(ids,id)end;table.sort(ids)
  for _,id in ipairs(ids)do local e=reservations[id];local r=e.Region
   if e.IsBot and r>0 and remaining[r]>api.Quotas[r]then table.insert(extra,id);remaining[r]-=1 end
  end;return extra
 end
 function api.candidate(random)
  local missing=0;for i=1,6 do missing+=math.max(0,api.Quotas[i]-counts[i])end
  if missing==0 then return nil end
  local pick=random.nextInt(0,missing);local region=1
  for i=1,6 do pick-=math.max(0,api.Quotas[i]-counts[i]);if pick<0 then region=i;break end end
  local r=regions[region];local value=random.next()*r.Weight;local data=r.Spans
  local lo,hi=0,buffer.len(data)/14-1
  while lo<hi do local mid=math.floor((lo+hi)/2);if buffer.readf64(data,mid*14+6)<=value then lo=mid+1 else hi=mid end end
  local offset=lo*14;api.Attempts+=1
  return buffer.readu32(data,offset)+random.nextInt(0,buffer.readu16(data,offset+4))
 end
 function api.accepts(id,tile)
  return not index.near(id,tile,9)and #index.geographic(id,tile,api.MinimumKm)==0
 end
 api.configure(population);return api
end
return Planner
