--!strict
-- DistanceBasedBezierCurve / ParabolaUniversalPathFinder, OpenFront 8f1a0add.
-- Copyright OpenFront and Contributors. AGPL-3.0; modified 2026-11-20.
local Path={}
local function round(n)return math.floor(n+.5) end
function Path.controls(grid,from,to,unclamped)
 local x,y=from%grid.Width,math.floor(from/grid.Width)
 local dx,dy=to%grid.Width-x,math.floor(to/grid.Width)-y
 local height=math.max(math.sqrt(dx*dx+dy*dy)/3,50)
 local a,b=y+dy/4-height,y+dy*3/4-height
 return {x,y,x+dx/4,if unclamped then a else math.clamp(a,0,grid.Height-1),x+dx*3/4,if unclamped then b else math.clamp(b,0,grid.Height-1),x+dx,y+dy}
end
function Path.curve(points,spacing)
 local p={};for i,v in ipairs(points) do p[i]=round(v)*256 end
 local out={{round(points[1]),round(points[2])}}
 local lastX,lastY,accum,total=p[1],p[2],0,0
 local threshold=math.max(256,round(spacing*256))
 local function subdivide(ax,ay,bx,by,cx,cy,dx,dy,depth)
  local dist=math.abs(bx-ax)+math.abs(by-ay)+math.abs(cx-bx)+math.abs(cy-by)+math.abs(dx-cx)+math.abs(dy-cy)
  if dist<=256 or depth>=10 then
   local ex,ey=ax-lastX,ay-lastY;local d=math.floor(math.sqrt(ex*ex+ey*ey));accum+=d;total+=d;lastX,lastY=ax,ay
   while accum>=threshold do table.insert(out,{math.floor((ax+128)/256),math.floor((ay+128)/256)});accum-=threshold end
   return
  end
  local abx,aby=math.floor((ax+bx)/2),math.floor((ay+by)/2)
  local bcx,bcy=math.floor((bx+cx)/2),math.floor((by+cy)/2)
  local cdx,cdy=math.floor((cx+dx)/2),math.floor((cy+dy)/2)
  local abcX,abcY=math.floor((abx+bcx)/2),math.floor((aby+bcy)/2)
  local bcdX,bcdY=math.floor((bcx+cdx)/2),math.floor((bcy+cdy)/2)
  local mx,my=math.floor((abcX+bcdX)/2),math.floor((abcY+bcdY)/2)
  subdivide(ax,ay,abx,aby,abcX,abcY,mx,my,depth+1)
  subdivide(mx,my,bcdX,bcdY,cdx,cdy,dx,dy,depth+1)
 end
 subdivide(p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],0)
 local ex,ey=p[7]-lastX,p[8]-lastY;total+=math.floor(math.sqrt(ex*ex+ey*ey))
 local x,y=round(points[7]),round(points[8]);local last=out[#out]
 if last[1]~=x or last[2]~=y then table.insert(out,{x,y}) end
 return out,total/256
end
function Path.route(grid,from,to,speed)
 local points=Path.curve(Path.controls(grid,from,to),speed);local result={}
 for _,p in ipairs(points) do table.insert(result,grid.ref(math.clamp(p[1],0,grid.Width-1),math.clamp(p[2],0,grid.Height-1))) end
 return result
end
function Path.mirvSpeed(grid,from,to)
 local _,ideal=Path.curve(Path.controls(grid,from,to,true),15)
 local ticks=math.floor(ideal/15*100);local target=1400
 if ticks>1400 then local d=ticks-1400;target+=math.floor(math.sqrt(d))*14+math.floor(d*10/100)
 elseif ticks<1400 then target-=math.floor(math.sqrt(1400-ticks))*10 end
 target=math.max(100,target)
 local _,length=Path.curve(Path.controls(grid,from,to),15)
 return math.max(1,math.floor((round(length*256)*100+math.floor(target/2))/target)/256)
end
return Path
