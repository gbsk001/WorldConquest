--!strict
-- Stage 7: visible-unit objects only, with a bounded reusable label pool.
-- This is a rendering adapter; all units remain in the authoritative replica.
local Layer={}
function Layer.new(width,create,paint,transition,declutter,maxVisible)
 maxVisible=maxVisible or 256
 local active,pool={},{ }
 local list,colors={},{}
 local dirty=true;local previous=nil
 local api={Created=0,Visible=0,Pooled=0}
 -- Replica replaces the building list whenever units change; ships use a fresh list.
 function api.set(units,palette)
  if list==units then
   local same=true;for id,color in pairs(palette)do if colors[id]~=color then same=false;break end end
   if same then for id in pairs(colors)do if palette[id]==nil then same=false;break end end end
   if same then return end
  end
  list,colors=units,palette;dirty=true
 end
 function api.update(ox,oy,scale,w,h)
  if not dirty and previous and previous[1]==ox and previous[2]==oy and previous[3]==scale and previous[4]==w and previous[5]==h then return end
  previous={ox,oy,scale,w,h};dirty=false
  local visible={};local count=0;local occupied={}
  for _,u in ipairs(list) do
   local x=ox+(u.Tile%width+.5)*scale;local y=oy+(math.floor(u.Tile/width)+.5)*scale
   if x>=-14 and y>=-14 and x<=w+14 and y<=h+14 then
    local key=math.floor(x/26)..":"..math.floor(y/26)
    if not declutter or not occupied[key] and count<maxVisible then visible[u.ID]=u;count+=1;occupied[key]=true end
   end
  end
  for id,record in pairs(active) do
   if not visible[id] then
    if transition then transition(record.Icon,nil) end
    record.Icon.Visible=false;active[id]=nil
    if #pool<(if declutter then maxVisible else 128)then table.insert(pool,record.Icon) else record.Icon:Destroy() end
   end
  end
  -- Preserve source list order for overlap and equal-distance input behaviour.
  for _,u in ipairs(list) do if visible[u.ID] then
   local record=active[u.ID]
   if not record then
    local icon=table.remove(pool);if not icon then icon=create();api.Created+=1 end
    record={Icon=icon,Values={}};active[u.ID]=record
   end
   local function set(key,value)
    if record.Values[key]~=value then
     if not transition or not transition(record.Icon,key,value,record.Values[key],u) then record.Icon[key]=value end
     record.Values[key]=value
    end
   end
   paint(u,colors,set,record.Icon,scale);record.Icon.Visible=true
  end end
  api.Visible=count;api.Pooled=#pool
 end
 function api.isVisible(id)return active[id]~=nil end
 function api.destroy()
  for _,r in pairs(active) do if transition then transition(r.Icon,nil) end;r.Icon:Destroy() end
  for _,icon in ipairs(pool) do icon:Destroy() end
  table.clear(active);table.clear(pool)
 end
 return api
end
return Layer
