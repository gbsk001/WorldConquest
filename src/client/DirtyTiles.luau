--!strict
-- Coalesce exact ownership changes into small world rectangles before touching tiles.
-- This only broadens repaint bounds; it never changes ownership or samples.
local Dirty={}
function Dirty.apply(pool,packed,width,height,size,padded)
 local groups={};local stride=math.ceil(width/32)
 for offset=0,buffer.len(packed)-1,6 do
  local ref=buffer.readu32(packed,offset);local x,y=ref%width,math.floor(ref/width)
  local key=math.floor(y/32)*stride+math.floor(x/32);local b=groups[key]
  if b then b[1]=math.min(b[1],x);b[2]=math.min(b[2],y);b[3]=math.max(b[3],x);b[4]=math.max(b[4],y)else groups[key]={x,y,x,y}end
 end
 local visited=0
 for _,bounds in pairs(groups)do
  local left,right=math.max(0,bounds[1]-1),math.min(width-1,bounds[3]+1)
  local top,bottom=math.max(0,bounds[2]-1),math.min(height-1,bounds[4]+1)
  for _,slot in ipairs(pool)do if slot.Level then
   visited+=1
   local step=2^slot.Level/(slot.Density or 1);local extent=size*step
   if right>=slot.X*extent-step and left<(slot.X+1)*extent+step and bottom>=slot.Y*extent-step and top<(slot.Y+1)*extent+step then
    local x0=math.clamp(math.floor(left/step)-slot.X*size+1,0,padded-1)
    local x1=math.clamp(math.ceil((right+1)/step)-slot.X*size,0,padded-1)
    local y0=math.clamp(math.floor(top/step)-slot.Y*size+1,0,padded-1)
    local y1=math.clamp(math.ceil((bottom+1)/step)-slot.Y*size,0,padded-1)
    slot.Dirty=true
    if slot.Bounds then local b=slot.Bounds;b[1]=math.min(b[1],x0);b[2]=math.min(b[2],y0);b[3]=math.max(b[3],x1);b[4]=math.max(b[4],y1)else slot.Bounds={x0,y0,x1,y1}end
   end
  end end
 end
 return visited
end
return Dirty
