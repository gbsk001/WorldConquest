
local function copy(v)if typeof(v)~="table"then return v end;local out={};for k,x in pairs(v)do out[k]=copy(x)end;return out end
local function run(seed)
 local w,h=2048,1024
 local terrain={Width=w,Height=h,LandCount=w*h,MaskHash="stage11",byte=function(t)return if t%w<20 then 0 else 128 end}
 local map={LandCount=w*h,cell=function(x,y)return if x>=0 and y>=0 and x<w and y<h then math.floor(y)*w+math.floor(x)+1 else nil end}
 local s=Simulation.new(terrain,map,seed,{Stage=11,Bots={Enabled=true,Count=98,Difficulty="Normal",DecisionsPerTick=2}})
 local replicas={Replica.new(terrain),Replica.new(terrain)}
 for _,r in ipairs(replicas)do r.begin({ID=1,Tick=0,Count=0,MapHash="stage11",Meta=s.metadata()});assert(r.finish({ID=1}))end
 s.enqueue({Kind="Join",UserId=1,Username="One"});s.enqueue({Kind="Join",UserId=2,Username="Two"});s.enqueue({Kind="Ready",UserId=1})
 local selectedTicks={};local seen={};local deltaCount=0;local reconsidered=0;local digest={}
 for tick=1,205 do
  if tick==4 then s.enqueue({Kind="SelectSpawn",UserId=1,X=100.25,Y=100.75});s.enqueue({Kind="SelectSpawn",UserId=2,X=100.25,Y=100.75})end
  if tick==8 then assert(s.Players[1].Spawn and not s.Players[2].Spawn);s.enqueue({Kind="SelectSpawn",UserId=1,X=400.25,Y=400.75})end
  if tick==12 then assert(s.Players[1].X==400.25);s.enqueue({Kind="SelectSpawn",UserId=2,X=100.25,Y=100.75})end
  if tick==16 then assert(s.Players[2].X==100.25);s.enqueue({Kind="SelectSpawn",UserId=2,X=3,Y=3})end
  local packet=s.step();packet.MatchID=1
  for _,r in ipairs(replicas)do assert(r.delta(copy(packet)));assert(r.Tick==s.Tick)end
  if packet.SpawnChanges then deltaCount+=1 end
  for id,p in pairs(s.Players)do if p.Spawn then
   assert((p.Spawn-1)%w>=20 and s.Grid.isLand(p.Spawn-1))
   if not seen[id]then selectedTicks[tick]=true elseif seen[id]~=p.Spawn then reconsidered+=1 end
   seen[id]=p.Spawn
  end end
  if packet.Meta or packet.SpawnChanges then
   for _,r in ipairs(replicas)do for _,row in ipairs(r.Meta.Players)do assert(row.Spawn==s.Players[row.UserId].Spawn)end end
  end
 end
 local distinct=0;for _ in pairs(selectedTicks)do distinct+=1 end
 assert(distinct>20 and reconsidered>1 and deltaCount>20)
 local list={};for _,p in pairs(s.Players)do assert(p.Spawn);table.insert(list,p)end
 table.sort(list,function(a,b)return a.UserId<b.UserId end)
 for i,p in ipairs(list)do for j=i+1,#list do local q=list[j];local dx=p.X-q.X;local dy=p.Y-q.Y;assert(dx*dx+dy*dy>=81)end;table.insert(digest,p.Username..":"..p.Spawn)end
 assert(s.Phase=="Started"and #list==100)
 s.enqueue({Kind="SelectSpawn",UserId=1,X=800,Y=800});local old=s.Players[1].Spawn;s.step();assert(s.Players[1].Spawn==old)
 return table.concat(digest,"|")
end
local a=run(12345);assert(a==run(12345));assert(a~=run(98765))
print("Stage 11: 100 staggered selections, changed seed/replay, two replica synchronisation, reservations, human movement, invalid water, AI reconsideration and countdown lock passed.")


