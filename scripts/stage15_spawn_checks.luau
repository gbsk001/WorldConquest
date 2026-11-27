-- Spawn planning only: no AI gameplay, rendering or load benchmark is run here.
local function sample(seed)
 local terrain=EarthTerrain;local grid=Grid.new(terrain.Width,terrain.Height,terrain.byte)
 local index=SpawnIndex.new(grid.Width,grid.Height);local planner=assert(SpawnPlanner.new(terrain,index));planner.configure(320)
 local random=Random32.new(seed);local counts={0,0,0,0,0,0};local digest=0;local positions={}
 for id=1,320 do
  local found=false
  for _=1,4096 do
   local tile=planner.candidate(random);assert(tile,"Quota exhausted early")
   if grid.ownerID(tile)==0 and planner.accepts(id,tile)then
    local footprint=Spawn.tiles(grid,tile,true)
    if footprint and #footprint>0 then
     local region=SpawnPlanner.region(grid.Width,grid.Height,tile);assert(region>=1 and region<=6)
     for _,ref in ipairs(footprint)do assert(grid.ownerID(ref)==0 and grid.isLand(ref));grid.setOwnerID(ref,id)end
     index.set(id,tile,true);planner.reserve(id,tile,true)
     if id>20 then counts[region]+=1 end
     positions[id]=tile;digest=(digest+tile*id)%2147483647;found=true;break
    end
   end
  end
  assert(found,"Could not fill balanced spawn quota without relaxing spacing")
 end
 for region,count in ipairs(counts)do assert(count>0,"Grey nations must represent every major geographic region");assert(planner.Counts[region]==planner.Quotas[region])end
 print(string.format("SPAWN_ONLY seed %d: 300 grey regional counts %s; 320 total; minimum %.0f km; disjoint land footprints; no Antarctica; digest %d",seed,table.concat(counts,","),planner.MinimumKm,digest))
 return digest,positions
end
local a,positions=sample(150027);local b,again=sample(150027);assert(a==b);for id,t in ipairs(positions)do assert(again[id]==t)end
local c,changed=sample(150028);local varied=0;for id,t in ipairs(positions)do if changed[id]~=t then varied+=1 end end;assert(c~=a and varied>300)
sample(150029)
print("Three seeds plus replay: real Earth atlas/spatial reservations verified, no 320-participant simulation or capacity claim.")
