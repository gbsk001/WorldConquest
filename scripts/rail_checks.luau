for _,v in ipairs(RailOracle.rates) do assert(RailRules.spawnRate(v.levels,v.units)==v.rate,"train spawn rate") end
for _,v in ipairs(RailOracle.gold) do assert(Gold.from(RailRules.gold(v.rel,v.visited,v.multiplier))==v.gold,"train payout") end
local function terrain(w,h,mode)
 local function water(t)
  if mode==1 then return t%w==math.floor(w/2)
  elseif mode==2 then return math.abs(t%w-math.floor(w/2))<=3
  elseif mode==3 then return (t*37+math.floor(t/w)*11)%31<7 end
  return false
 end
 local function byte(t)
  local neighbors={};local x=t%w
  if t>=w then table.insert(neighbors,t-w) end;if t<(h-1)*w then table.insert(neighbors,t+w) end
  if x>0 then table.insert(neighbors,t-1) end;if x<w-1 then table.insert(neighbors,t+1) end
  local shore=false;for _,n in ipairs(neighbors) do if water(n)~=water(t) then shore=true;break end end
  return (if water(t) then 32 else 128)+(if shore then 64 else 0)+(if mode==4 and x==math.floor(w/2) and math.floor(t/w)~=10 then 31 else 0)
 end
 return {Width=w,Height=h,byte=byte,MaskHash="rail"}
end
local function equal(a,b,message)
 assert(#a==#b,message.." length "..#a.."/"..#b)
 for i,v in ipairs(a) do assert(v==b[i],message.." value at "..i.." "..tostring(v).."/"..tostring(b[i])) end
end
for _,v in ipairs(RailOracle.paths) do
 local t=terrain(64,48,v.mode);local g=Grid.new(64,48,t.byte);local path=RailPath.land(g,v.from,v.to)
 if v.path then assert(path,"missing path");equal(path,v.path,"rail A* mode "..v.mode) else assert(not path,"unexpected rail path") end
end
for _,scene in ipairs(RailOracle.scenes) do
 local t=terrain(192,128,scene.mode)
 local s=Simulation.new(t,{cell=function(x,y)return math.floor(y)*192+math.floor(x)+1 end},123,{Stage=5,Economy={StartingGold="1000000000"},Buildings={InstantBuild=true}})
 for id=1,2 do s.enqueue({Kind="Join",UserId=id,Username="P"..id}) end;s.step();s.Tick=0;s.Executions.Tick=0;s.Phase="Started";s.StartTick=-100
 for tile=0,192*128-1 do if s.Grid.isLand(tile) and not s.Grid.isImpassable(tile) then s.conquer(s.Players[1],tile) end end;s.conquer(s.Players[2],0);s.Grid.discardChanges()
 local built={};local sequences={0,0}
 for tick,expected in ipairs(scene.frames) do
  local where=scene.name.." tick "..(tick-1)
  for _,e in ipairs(scene.events) do if e[1]==tick-1 then
   if e[2]=="build" then
    local p=s.Players[e[3]];local tile=e[6]*192+e[5];s.conquer(p,tile);sequences[e[3]]+=1
    s.enqueue({Kind="Building",Action="Build",UserId=p.UserId,Sequence=sequences[e[3]],Type=e[4],Tile=tile})
   elseif e[2]=="delete" then s.Buildings.destroy(built[e[3]])
   elseif e[2]=="upgrade" then
    local u=built[e[3]];sequences[u.Owner.UserId]+=1
    -- Upstream fixture upgrades immediately before this tick's executions.
    u.Level+=1;u.Owner.BuildingOwned[u.Type]+=1;u.Owner.BuildingConstructed[u.Type]+=1
   elseif e[2]=="capture" then
    local u=built[e[3]];local owner=u.Owner;s.conquer(s.Players[e[4]],u.Tile);s.Buildings.reconcile(owner)
   elseif e[2]=="embargo" then s.Players[2].Embargoes=if e[3]~=0 then {[1]=true} else {} end
  end end
  s.step()
  for _,copy in ipairs(s.Buildings.snapshot()) do local u=s.Buildings.Units[copy.ID];if not table.find(built,u) then table.insert(built,u) end end
  local stations={};for _,st in pairs(s.Rail.Stations) do table.insert(stations,st) end;table.sort(stations,function(a,b)return a.ID<b.ID end)
  assert(#stations==#expected.stations,where.." station count "..#stations.."/"..#expected.stations)
  for i,st in ipairs(stations) do
   local ex=expected.stations[i];assert(st.ID==ex.id and st.Unit.ID==ex.unit,where.." station ID")
   local members={};for _,m in ipairs(st.Cluster.Stations) do table.insert(members,m.ID) end;equal(members,ex.cluster,where.." cluster")
  end
  local rails={};for _,r in pairs(s.Rail.Rails) do table.insert(rails,r) end;table.sort(rails,function(a,b)return a.ID<b.ID end)
  assert(#rails==#expected.rails,where.." rail count")
  for i,r in ipairs(rails) do local ex=expected.rails[i];assert(r.ID==ex.id and r.From.ID==ex.from and r.To.ID==ex.to,where.." rail endpoints");equal(r.Tiles,ex.path,where.." rail geometry") end
  assert(s.Rail.TrainUnits==expected.trainUnits,where.." train count "..s.Rail.TrainUnits.."/"..expected.trainUnits)
  local trains={};for _,train in pairs(s.Rail.Trains) do table.insert(trains,train) end;table.sort(trains,function(a,b)return a.ID<b.ID end)
  assert(#trains==#expected.trains,where.." engine count")
  for i,train in ipairs(trains) do local ex=expected.trains[i];assert(train.ID==ex.id and train.Tile==ex.tile and train.Owner.UserId==ex.owner,where.." engine motion "..train.ID..":"..train.Tile.."/"..ex.id..":"..ex.tile) end
  for id=1,2 do assert((s.Players[id].TrainGold or "0")==expected.gold[id],where.." rail income "..id.." "..(s.Players[id].TrainGold or "0").."/"..expected.gold[id]) end
 end
end
print(string.format("Stage 5 rail source parity: 64 spawn rates, 112 payouts, 200 exact A* paths and %d station/rail/train/gold ticks (self/external trade, splits ahead/behind moving trains, live demolition/capture, upgrades, embargo, duplicate factory stations, water barriers) passed.",#RailOracle.scenes*700))
-- Source port station activation shares the factory proximity rule; sea spawning is excluded.
do
 local t=terrain(192,128,1);local s=Simulation.new(t,{},123,{Stage=5,Economy={StartingGold="10000000"},Buildings={InstantBuild=true}})
 s.enqueue({Kind="Join",UserId=1,Username="P"});s.step();s.Phase="Started";s.StartTick=-100;local p=s.Players[1]
 for tile=0,192*128-1 do if s.Grid.isLand(tile) then s.conquer(p,tile) end end
 for seq,kind in ipairs({"Factory","Port"}) do
  s.enqueue({Kind="Building",Action="Build",UserId=1,Sequence=seq,Type=kind,Tile=40*192+(if seq==1 then 30 else 95)})
  for _=1,5 do s.step() end
 end
 assert(s.Rail.summary(p).Stations==2 and s.Buildings.Units[2].HasStation,"coastal port joins rail network")
 for _=1,500 do s.step();if s.Rail.TrainUnits>0 then break end end
 assert(s.Rail.TrainUnits>0,"factory generated a train to port")
 p.Tiles.each(function(tile)s.relinquish(p,tile)end)
 s.startRecruitment(p);s.step();s.step()
 assert(s.Rail.TrainUnits==0 and p.Gold=="0","elimination removes trains and gold")
 for _=1,100 do s.step() end;assert(p.Gold=="0","dead train owner received later income")
end
print("Stage 5 port rail activation and PlayerExecution elimination cleanup passed; sea trade remains disabled.")
do
 local w,h=8192,4096;local t={Width=w,Height=h,byte=function()return 128 end,MaskHash="rail-profile"}
 local s=Simulation.new(t,{},123,{Stage=5,Economy={StartingGold="1000000000"},Buildings={InstantBuild=true}})
 for id=1,50 do s.enqueue({Kind="Join",UserId=id,Username="P"..id}) end;s.step();s.Phase="Started"
 for seq=1,2 do
  for id=1,50 do local x=10+((id-1)%20)*250+(seq-1)*80;local y=10+math.floor((id-1)/20)*200;local tile=y*w+x;s.conquer(s.Players[id],tile)
   s.enqueue({Kind="Building",UserId=id,Action="Build",Type=if seq==1 then "Factory" else "City",Sequence=seq,Tile=tile})
  end
  s.step();s.step()
 end
 local times={};local total,railTotal,maxTrains,bytes=0,0,0,0;local before=gcinfo()
 for _=1,1000 do
  local began=os.clock();local packet=s.step();local ms=(os.clock()-began)*1000;table.insert(times,ms);total+=ms;railTotal+=s.Work.RailMilliseconds
  maxTrains=math.max(maxTrains,s.Rail.TrainUnits/7);bytes+=buffer.len(packet.BuildingChanges)
 end
 table.sort(times);local railCells=0;for _,r in pairs(s.Rail.Rails) do railCells+=#r.Tiles end
 assert(s.Players[1].TrainGold and tonumber(s.Players[1].TrainGold)>0)
 print(string.format("Stage 5 rail load: 50 factories + 50 cities / 1000 ticks / 8192x4096; mean %.3f ms p95 %.3f max %.3f; rail CPU %.3f ms/tick; peak %d trains (%d virtual units), %d stored rail cells; stationary building updates %d B; harness heap %.0f -> %.0f KiB (GC-sensitive).",total/1000,times[950],times[1000],railTotal/1000,maxTrains,maxTrains*7,railCells,bytes,before,gcinfo()))
end
