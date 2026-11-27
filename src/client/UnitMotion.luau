--!strict
-- Cosmetic interpolation of authoritative recent rail waypoints. No prediction.
local Motion={}
function Motion.new(width)
 local active={};local api={}
 function api.cancel(icon)active[icon]=nil end
 function api.start(icon,u,old)
  if not old or not u.Motion or buffer.len(u.Motion)<8 then return false end
  local from=math.floor(old.Y.Scale*width/2)*width+math.floor(old.X.Scale*width)
  local points={};local found=nil
  for offset=0,buffer.len(u.Motion)-1,4 do local t=buffer.readu32(u.Motion,offset);table.insert(points,t);if t==from then found=#points end end
  if not found or found==#points then return false end
  active[icon]={Points=points,First=found,Elapsed=0,Duration=math.min(1.2,(#points-found)*.05)};return true
 end
 function api.step(dt)
  for icon,m in pairs(active)do
   if not icon.Visible then active[icon]=nil;continue end
   m.Elapsed=math.min(m.Duration,m.Elapsed+dt)
   local position=m.First+(#m.Points-m.First)*m.Elapsed/m.Duration
   local i=math.min(#m.Points-1,math.floor(position));local alpha=position-i
   local a,b=m.Points[i],m.Points[i+1]
   local x=(a%width+.5)*(1-alpha)+(b%width+.5)*alpha
   local y=(math.floor(a/width)+.5)*(1-alpha)+(math.floor(b/width)+.5)*alpha
   icon.Position=UDim2.fromScale(x/width,y/(width/2))
   if m.Elapsed>=m.Duration then active[icon]=nil end
  end
 end
 return api
end
return Motion
