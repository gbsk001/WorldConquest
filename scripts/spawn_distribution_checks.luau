-- Actual production Earth/simulation, selection-only capacity test, not gameplay certification.
local function sphere(t)
 local lon=(t%8192+.5)/8192*2*math.pi-math.pi;local lat=math.pi/2-(math.floor(t/8192)+.5)/4096*math.pi
 return {math.cos(lat)*math.cos(lon),math.sin(lat),math.cos(lat)*math.sin(lon)}
end
local function make(n,seed)
 local s=Simulation.new(EarthTerrain,WorldMap,seed,{Stage=11,Bots={Enabled=true,Count=n-1,Difficulty='Normal'}})
 s.enqueue({Kind='Join',UserId=1,Username='Human'});s.enqueue({Kind='Ready',UserId=1});return s
end
local function run(n,seed,unique)
 local s=make(n,seed);local sum,worst=0,0;local times={};local choices={};local changed=0;local previous={}
 for tick=1,202 do
  local began=os.clock();local packet=s.step();local ms=(os.clock()-began)*1000;sum+=ms;worst=math.max(worst,ms);times[tick]=ms
  if packet.SpawnChanges then for _,p in ipairs(packet.SpawnChanges.Players)do
   if p.Spawn then choices[tick]=true;if previous[p.UserId] and previous[p.UserId]~=p.Spawn then changed+=1 end;previous[p.UserId]=p.Spawn end
  end end
 end
 assert(s.Phase=='Started')
 local list={};for _,p in pairs(s.Players)do assert(p.Spawn,'missing spawn '..n..'/'..seed..'/'..p.UserId);table.insert(list,p)end
 table.sort(list,function(a,b)return a.UserId<b.UserId end);assert(#list==n)
 local regions={0,0,0,0,0,0};local occupied={};local vectors={};local bins={};local maxBin=0;local hash=0
 local islands={0,0,0,0,0};local boxes={{166,179,-48,-34},{129,146,30,46},{-9,2,50,59},{43,51,-26,-11},{-161,-154,18,23}}
 for _,p in ipairs(list)do
  local t=p.Spawn-1;local r=SpawnPlanner.region(8192,4096,t);assert(r>0,'Antarctica')
  regions[r]+=1;assert(s.Grid.isLand(t)and not s.Grid.isImpassable(t));vectors[#vectors+1]=sphere(t)
  local lon=(t%8192+.5)/8192*360-180;local lat=90-(math.floor(t/8192)+.5)/4096*180
  for i,b in ipairs(boxes)do if lon>=b[1]and lon<=b[2]and lat>=b[3]and lat<=b[4]then islands[i]+=1 end end
  for _,ref in ipairs(p.SpawnCells)do assert(not occupied[ref],'overlap');occupied[ref]=p.UserId;assert(s.Grid.isLand(ref))end
  hash=(hash*31+t)%4294967296;if unique then unique[t]=true end
  local key=math.floor((t%8192)/8192*36)+36*math.floor(math.floor(t/8192)/4096*18)
  bins[key]=(bins[key]or 0)+1;maxBin=math.max(maxBin,bins[key])
 end
 local minimum=math.huge;local nearest={};for i=1,n do nearest[i]=math.huge end
 for i,a in ipairs(vectors)do for j=i+1,n do local b=vectors[j];local chord=math.sqrt((a[1]-b[1])^2+(a[2]-b[2])^2+(a[3]-b[3])^2)
  local km=12742*math.asin(math.min(1,chord/2));minimum=math.min(minimum,km);nearest[i]=math.min(nearest[i],km);nearest[j]=math.min(nearest[j],km)
 end end
 assert(minimum>=s.SpawnPlanner.MinimumKm-1e-6,'geographic spacing')
 for i,count in ipairs(regions)do assert(count==s.SpawnPlanner.Quotas[i],'regional quota');assert(count>0)end
 local distinct=0;for _ in pairs(choices)do distinct+=1 end;assert(distinct>math.min(8,n/2))
 local nn=0;for _,d in ipairs(nearest)do nn+=d end;table.sort(times)
 print('DISTRIBUTION',n,seed,table.concat(regions,','),minimum,nn/n,maxBin,sum/202,times[192],worst,s.SpawnPlanner.Attempts,hash,gcinfo(),distinct,changed)
 print('ISLAND_BOXES',n,seed,table.concat(islands,','))
 return hash
end
for _,n in ipairs({20,50,100,250,500})do
 local unique={};local digests={};local first=nil
 for seed=1,SEEDS do local digest=run(n,seed*104729+37,unique);assert(not digests[digest],'repeated match layout');digests[digest]=true;if seed==1 then first=digest end end
 assert(run(n,104766,nil)==first,'same-seed replay')
 local count=0;for _ in pairs(unique)do count+=1 end
 assert(count/(n*SEEDS)>.98,'insufficient location diversity');print('DIVERSITY',n,count,n*SEEDS)
end
-- Geographic index must work at high latitude and across the date line.
do
 local index=SpawnIndex.new(8192,4096);index.configureGeographic(360)
 local function tile(lon,lat)return math.floor((90-lat)/180*4096)*8192+math.floor((lon+180)/360*8192)end
 index.set(1,tile(179.9,0),true);assert(#index.geographic(2,tile(-179.9,0),50)==1)
 index.set(2,tile(0,85),true);assert(#index.geographic(3,tile(10,85),150)==1)
end
-- Human selections take precedence, including an occupied AI root and late moves.
do
 local s=make(50,23456);local starts={};local original=s.startRecruitment
 s.startRecruitment=function(p)starts[p.UserId]=(starts[p.UserId]or 0)+1;original(p)end
 for _=1,170 do s.step()end
 local target=s.Players[s.Bots.Roster[1]].Spawn-1;local bot=s.Players[s.Bots.Roster[1]];local username=bot.Username
 s.enqueue({Kind='SelectSpawn',UserId=1,X=target%8192+.25,Y=math.floor(target/8192)+.75})
 for _=1,4 do s.step()end
 assert(s.Players[1].Spawn==target+1 and bot.Spawn~=target+1 and bot.Spawn and bot.Username==username)
 assert(s.Grid.ownerID(target)==s.Players[1].SmallId)
 local far=s.Players[s.Bots.Roster[2]].Spawn-1
 while s.Tick<s.EndTick-2 do s.step()end
 s.enqueue({Kind='SelectSpawn',UserId=1,X=far%8192+.25,Y=math.floor(far/8192)+.75})
 for _=1,8 do s.step()end
 assert(s.Players[1].Spawn==far+1 and s.Phase=='Started')
 for _,p in pairs(s.Players)do assert(p.Spawn and not p.Eliminated);assert(starts[p.UserId]==1,'duplicate recruitment after displacement')end
 print('Human priority: occupied AI root, geographic exclusion, stable identity, quota rebalance and final-countdown move passed.')
end
print('Balanced spawn distribution and deterministic replay passed.')
-- Two real-Earth replicas see the same human override; human reservations win
-- against both AI and later human requests, and invalid water rolls back.
do
 local s=Simulation.new(EarthTerrain,WorldMap,91823,{Stage=11,Bots={Enabled=true,Count=18,Difficulty='Normal'}})
 local replicas={Replica.new(EarthTerrain),Replica.new(EarthTerrain)}
 for _,r in ipairs(replicas)do r.begin({ID=1,Tick=0,Count=0,MapHash=EarthTerrain.MaskHash,Meta=s.metadata()});assert(r.finish({ID=1}))end
 s.enqueue({Kind='Join',UserId=1,Username='One'});s.enqueue({Kind='Join',UserId=2,Username='Two'});s.enqueue({Kind='Ready',UserId=1})
 local function step(n)
  for _=1,n do local packet=s.step();packet.MatchID=1
   for _,r in ipairs(replicas)do assert(r.delta(packet));if packet.Meta or packet.SpawnChanges then
    for _,p in ipairs(r.Meta.Players)do assert(p.Spawn==s.Players[p.UserId].Spawn,'replica spawn mismatch')end
   end end
  end
 end
 step(170);local target=s.Players[s.Bots.Roster[1]].Spawn-1
 local function select(id,t)s.enqueue({Kind='SelectSpawn',UserId=id,X=t%8192+.5,Y=math.floor(t/8192)+.5})end
 select(1,target);select(2,target);step(4)
 assert(s.Players[1].Spawn==target+1 and not s.Players[2].Spawn,'human reservation displaced')
 select(1,0);step(4);assert(s.Players[1].Spawn==target+1,'water request lost valid reservation')
 local nextTarget=s.Players[s.Bots.Roster[2]].Spawn-1;select(1,nextTarget);step(4);select(2,target);step(4)
 assert(s.Players[1].Spawn==nextTarget+1 and s.Players[2].Spawn==target+1)
 print('Real Earth: two replicated clients, AI yielding, simultaneous human collision, invalid water rollback and released reservation passed.')
end
