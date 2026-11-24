--!strict
-- One gesture owns the whole touch sequence. Pinching can never become a tap.
local Gestures={}
function Gestures.new(pan,zoom,tap)
 local touches={};local order={};local suppressed=false
 local api={}
 function api.begin(id,x,y)
  if touches[id]then return end
  touches[id]={X=x,Y=y,StartX=x,StartY=y};table.insert(order,id)
  if #order>1 then suppressed=true end
 end
 function api.move(id,x,y)
  local t=touches[id];if not t then return end
  if #order>=2 then
   local a,b=touches[order[1]],touches[order[2]]
   local ox,oy=(a.X+b.X)/2,(a.Y+b.Y)/2;local distance=math.sqrt((a.X-b.X)^2+(a.Y-b.Y)^2)
   t.X,t.Y=x,y
   local nx,ny=(a.X+b.X)/2,(a.Y+b.Y)/2;local nextDistance=math.sqrt((a.X-b.X)^2+(a.Y-b.Y)^2)
   if distance>2 and nextDistance>2 then zoom(nextDistance/distance,ox,oy,nx,ny)end
  else
   if (x-t.StartX)^2+(y-t.StartY)^2>64 then suppressed=true end
   if suppressed then pan(x-t.X,y-t.Y)end;t.X,t.Y=x,y
  end
 end
 function api.finish(id,x,y)
  local t=touches[id];if not t then return end
  local select=#order==1 and not suppressed and (x-t.StartX)^2+(y-t.StartY)^2<=64
  touches[id]=nil;table.remove(order,table.find(order,id));if #order==0 then suppressed=false end
  if select then tap(x,y)end
 end
 function api.cancel()table.clear(touches);table.clear(order);suppressed=false end
 return api
end
return Gestures
