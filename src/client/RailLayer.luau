--!strict
-- Original pooled 2-D rail presentation. Vertices preserve every path turn.
local RailLayer={}
function RailLayer.new(parent,width,mobile)
 local data={};local segments={};local buckets={};local pool={};local serial=0;local pending=nil;local match=nil
 local api={};local cap=if mobile then 160 else 420;local bucketWidth=math.ceil(width/256)
 local function rebuild()
  table.clear(segments);table.clear(buckets)
  local ids={};for id in pairs(data)do table.insert(ids,id)end;table.sort(ids)
  for _,id in ipairs(ids)do local route=data[id];local points=route.Points
   for offset=4,buffer.len(points)-1,4 do
    local a,b=buffer.readu32(points,offset-4),buffer.readu32(points,offset)
    local ax,ay=a%width+.5,math.floor(a/width)+.5;local bx,by=b%width+.5,math.floor(b/width)+.5
    local s={AX=ax,AY=ay,BX=bx,BY=by,Owner=route.Owner};table.insert(segments,s)
    for y=math.floor(math.min(ay,by)/256),math.floor(math.max(ay,by)/256)do for x=math.floor(math.min(ax,bx)/256),math.floor(math.max(ax,bx)/256)do
     local key=y*bucketWidth+x;buckets[key]=buckets[key]or {};table.insert(buckets[key],s)
    end end
   end
  end
 end
 function api.clear()data={};pending=nil;match=nil;serial=0;rebuild();for _,line in ipairs(pool)do line.Visible=false end end
 function api.receive(packet,currentMatch)
  if packet.MatchID~=currentMatch then return false end
  if match~=currentMatch then api.clear();match=currentMatch end
  if packet.Version<serial then return false end
  if packet.First then pending={Version=packet.Version,Next=1,Data={}}end
  if not pending or pending.Version~=packet.Version or pending.Next~=packet.Part then return false end
  for _,r in ipairs(packet.Routes)do pending.Data[r.ID]=r end
  pending.Next+=1
  if packet.Last then data=pending.Data;serial=pending.Version;pending=nil;rebuild();return true end
  return false
 end
 function api.update(ox,oy,scale,w,h,palette)
  local shown=0;local seen={}
  if scale>=.6 then
   local x0,x1=math.max(0,math.floor(-ox/scale/256)),math.min(bucketWidth-1,math.floor((w-ox)/scale/256))
   local y0,y1=math.max(0,math.floor(-oy/scale/256)),math.floor((h-oy)/scale/256)
   for y=y0,y1 do for x=x0,x1 do for _,s in ipairs(buckets[y*bucketWidth+x]or {})do
    if seen[s]then continue end;seen[s]=true
    local ax,ay,bx,by=ox+s.AX*scale,oy+s.AY*scale,ox+s.BX*scale,oy+s.BY*scale
    if math.max(ax,bx)<0 or math.min(ax,bx)>w or math.max(ay,by)<0 or math.min(ay,by)>h or shown>=cap then continue end
    shown+=1;local line=pool[shown]
    if not line then line=Instance.new("Frame");line.Name="RailSegment";line.AnchorPoint=Vector2.new(.5,.5);line.BorderSizePixel=0;line.Active=false;line.ZIndex=3;line.BackgroundColor3=Color3.fromRGB(197,184,157);line.BackgroundTransparency=.1;line.Parent=parent;pool[shown]=line end
    local color=palette and palette[s.Owner]
    line.BackgroundColor3=if color then Color3.new(.6*.77+.4*color.R,.6*.72+.4*color.G,.6*.62+.4*color.B)else Color3.fromRGB(197,184,157)
    local dx,dy=bx-ax,by-ay;line.Position=UDim2.fromOffset((ax+bx)/2-ox,(ay+by)/2-oy);line.Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy)+1,math.clamp(scale*.4,1,2));line.Rotation=math.deg(math.atan2(dy,dx));line.Visible=true
   end end end
  end
  for i=shown+1,#pool do pool[i].Visible=false end
 end
 return api
end
return RailLayer
