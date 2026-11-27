-- Deliberately small controlled combat fixture, not an Earth load benchmark.
do
 local w,h=32,16
 local t={Width=w,Height=h,LandCount=w*h,MaskHash="grey-conquest",byte=function()return 128 end}
 local map={cell=function(x,y)return math.floor(y)*w+math.floor(x)+1 end}
 local s=Simulation.new(t,map,21,{Stage=11,Balance={StartingSoldiers=5000,RecruitmentMultiplier=.5,BasicRecruitmentMultiplier=.2,ProactiveAI=true,BoundedPaths=true},Bots={Enabled=true,Count=1,Difficulty="Normal",Buildings=false,Naval=false,Missiles=false},Match={WinThresholdTenths=800}})
 s.Phase="Selecting";s.EndTick=200;s.step();s.step()
 s.enqueue({Kind="Join",UserId=-2000001,Username="Grey",IsBot=true,BasicNation=true,StartingTroops=500});s.step()
 local smart=s.Players[s.Bots.Roster[1]];local grey=s.Players[-2000001]
 -- Fixed contiguous border makes combat unavoidable before more neutral land is accessible.
 for _,p in ipairs({smart,grey})do local old={};p.Tiles.each(function(tile)table.insert(old,tile)end);for _,tile in ipairs(old)do s.relinquish(p,tile)end end
 for y=0,h-1 do for x=0,13 do s.conquer(if x<8 then smart else grey,y*w+x)end end
 smart.Spawn=1;grey.Spawn=9;smart.Eliminated=false;grey.Eliminated=false
 s.Phase="Started";s.StartTick=s.Tick;s.startRecruitment(smart);s.startRecruitment(grey)
 local conqueredAt=nil;local expanded=false
 for _=1,1600 do
  s.step()
  if grey.Eliminated and not conqueredAt then conqueredAt=s.Tick end
  if conqueredAt and (s.Grid.Counts[smart.SmallId]or 0)>14*h then expanded=true;break end
 end
 assert(conqueredAt and expanded,"Competitive AI must eliminate the grey defender and then expand into neutral land")
 assert(s.Bots.Orders>=2 and grey.Tiles.Size==0 and s.Economy.income(grey)=="0")
 print(string.format("SMART_GREY_CONQUEST normal AI: 5000 vs 500 initial soldiers; grey eliminated at tick %d, subsequent expansion tick %d, territory %d -> %d, orders %d",conqueredAt,s.Tick,8*h,s.Grid.Counts[smart.SmallId],s.Bots.Orders))
end
