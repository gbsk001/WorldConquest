--!strict
-- Port of PlayerImpl placement/counts, ConstructionExecution, UpgradeStructureExecution,
-- DeleteUnitExecution, UnitImpl ownership and PlayerExecution structure reconciliation.
-- Copyright OpenFront and Contributors. AGPL-3.0; pinned 8f1a0add, modified 2026-11-18.
local Rules = require(game:GetService("ReplicatedStorage").Shared.OpenFront.BuildingRules)
local Gold = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Gold)
local Wire = require(game:GetService("ReplicatedStorage").Shared.OpenFront.BuildingWire)
local Buildings={}
function Buildings.new(sim,config)
 config=config or {}
 local grid=sim.Grid
 local function enabled(kind)return (kind~="MissileSilo" and kind~="SAMLauncher" or (sim.Stage or 0)>=8) and not (config.Disabled and config.Disabled[kind]) end
 local api={Units={},Count=0,Version=0}
 local serial=0
 function api.nextID()serial+=1;return serial end
 local buckets={};local bucketWidth=math.ceil(grid.Width/32)
 local function bucket(tile)return math.floor(tile%grid.Width/32)+math.floor(math.floor(tile/grid.Width)/32)*bucketWidth end
 local changes={}
 local function dirty(u)api.Version+=1;sim.MetadataDirty=true;changes[u.ID]=u end
 local function changed(p)
  p.CityLevels=0;p.BuildingOwned={}
  for _,u in ipairs(p.BuildingUnits) do
   p.BuildingOwned[u.Type]=(p.BuildingOwned[u.Type] or 0)+(if u.UnderConstruction then 1 else u.Level)
   if u.Type=="City" and not u.UnderConstruction then p.CityLevels+=u.Level end
  end
 end
 function api.init(p)p.BuildingUnits={};p.BuildingOwned={};p.BuildingConstructed={};p.CityLevels=0;p.LastDeleteUnitTick=-1 end
 local function removeOwned(p,u)
  local index=table.find(p.BuildingUnits,u);if index then table.remove(p.BuildingUnits,index) end;changed(p)
 end
 function api.distance(a,b)
  local dx=a%grid.Width-b%grid.Width;local dy=math.floor(a/grid.Width)-math.floor(b/grid.Width)
  return dx*dx+dy*dy
 end
 function api.nearby(tile,radius,kind,owner,includeConstruction)
  local result={};local x,y=tile%grid.Width,math.floor(tile/grid.Width)
  for by=math.max(0,math.floor((y-radius)/32)),math.min(math.ceil(grid.Height/32)-1,math.floor((y+radius)/32)) do
   for bx=math.max(0,math.floor((x-radius)/32)),math.min(bucketWidth-1,math.floor((x+radius)/32)) do
    for _,u in ipairs(buckets[by*bucketWidth+bx] or {}) do
     if (not kind or u.Type==kind) and (not owner or u.Owner==owner) and (includeConstruction or not u.UnderConstruction) and api.distance(tile,u.Tile)<=radius*radius then table.insert(result,u) end
    end
   end
  end
  -- Spatial storage must not make insertion order depend on bucket traversal.
  table.sort(result,function(a,b)return a.ID<b.ID end)
  return result
 end
 function api.defended(tile,p)
  local x,y=tile%grid.Width,math.floor(tile/grid.Width)
  for by=math.max(0,math.floor((y-30)/32)),math.min(math.ceil(grid.Height/32)-1,math.floor((y+30)/32)) do
   for bx=math.max(0,math.floor((x-30)/32)),math.min(bucketWidth-1,math.floor((x+30)/32)) do
    for _,u in ipairs(buckets[by*bucketWidth+bx] or {}) do
     if u.Type=="DefensePost" and u.Owner==p and not u.UnderConstruction and api.distance(tile,u.Tile)<=900 then return true end
    end
   end
  end
  return false
 end
 function api.price(p,kind)
  if p.Kind=="Human" and sim.Economy.isFree(p) then return "0" end
  return Rules.cost(kind,p.BuildingOwned,p.BuildingConstructed)
 end
 function api.quotes(p)
  local out={}
  for _,kind in ipairs(Rules.Types) do local cost=api.price(p,kind);out[kind]={Cost=cost,Affordable=Gold.compare(p.Gold,cost)>=0,Enabled=enabled(kind)} end
  return out
 end
 function api.placement(p,kind,tile)
  if not Rules.Info[kind] or not enabled(kind) or not grid.valid(tile) or grid.ownerID(tile)~=p.SmallId then return nil end
  -- Exact upstream bounded flood: N/S/W/E push, LIFO traversal, stable distance ties.
  local nearby=api.nearby(tile,30,nil,nil,true)
  local visited={[tile]=true};local list={tile};local stack={tile};local nb={}
  while #stack>0 do
   local t=table.remove(stack);local n=grid.neighbors4(t,nb)
   for i=1,n do local v=nb[i]
    if not visited[v] and grid.ownerID(v)==p.SmallId and api.distance(v,tile)<225 then visited[v]=true;table.insert(list,v);table.insert(stack,v) end
   end
  end
  local valid={}
  for order,t in ipairs(list) do
   local blocked=false
   for _,u in ipairs(nearby) do if api.distance(t,u.Tile)<225 then blocked=true;break end end
   if not blocked then table.insert(valid,{Tile=t,Distance=api.distance(t,tile),Order=order}) end
  end
  table.sort(valid,function(a,b)return a.Distance<b.Distance or (a.Distance==b.Distance and a.Order<b.Order) end)
  for _,candidate in ipairs(valid) do
   if kind~="Port" or bit32.band(grid.terrainByte(candidate.Tile),64)~=0 then return candidate.Tile end
  end
  return nil
 end
 function api.destroy(u)
  if not u or not u.Active then return end
  u.Active=false;api.Units[u.ID]=nil;api.Count-=1
  if sim.Rail and u.HasStation then sim.Rail.removeUnit(u) end
  local b=buckets[bucket(u.Tile)];table.remove(b,table.find(b,u));if #b==0 then buckets[bucket(u.Tile)]=nil end
  removeOwned(u.Owner,u);dirty(u)
 end
 function api.reconcile(p)
  -- PlayerExecution walks the previous array even when capture replaces the owner's array.
  local units=table.clone(p.BuildingUnits)
  for _,u in ipairs(units) do
   local owner=sim.owner(grid.ownerID(u.Tile))
   if not owner then api.destroy(u)
   elseif owner~=p then
    if u.Type=="DefensePost" then api.destroy(u)
    else
     removeOwned(p,u);u.Owner=owner;u.DeleteAt=nil;table.insert(owner.BuildingUnits,u);changed(owner);dirty(u);if sim.Rail and sim.Rail.invalidateGeometry then sim.Rail.invalidateGeometry()end
    end
   end
  end
 end
 function api.leave(p)for _,u in ipairs(table.clone(p.BuildingUnits)) do api.destroy(u) end end
 function api.snapshot()
  local result={}
  for _,u in pairs(api.Units) do table.insert(result,{ID=u.ID,Type=u.Type,Tile=u.Tile,Owner=u.Owner.SmallId,Level=u.Level,UnderConstruction=u.UnderConstruction,CompleteTick=u.CompleteTick,DeleteAt=u.DeleteAt}) end
  table.sort(result,function(a,b)return a.ID<b.ID end);return result
 end
 function api.drain()
  local list={}
  for _,u in pairs(changes) do table.insert(list,{ID=u.ID,Type=u.Type,Tile=u.Tile,Owner=if u.Active then u.Owner.SmallId else 0,Level=u.Level,UnderConstruction=u.UnderConstruction,CompleteTick=u.CompleteTick,DeleteAt=u.DeleteAt}) end
  table.sort(list,function(a,b)return a.ID<b.ID end);changes={};return Wire.pack(list)
 end
 local function validUnit(p,context,upgrade)
  local u=if typeof(context)=="table" then api.Units[context.UnitID] else nil
  if not u or u.Owner~=p or not u.Active then return false end
  if upgrade then return Rules.Info[u.Type].Upgradeable and not u.UnderConstruction and not u.DeleteAt and not (config.Disabled and config.Disabled[u.Type]) end
  return grid.ownerID(u.Tile)==p.SmallId and grid.isLand(u.Tile) and sim.Tick-p.LastDeleteUnitTick>=300
 end
 for _,kind in ipairs(Rules.Types) do
  local product=kind
  sim.Economy.register("Build:"..product,function(p)return api.price(p,product) end,function(p,_,context)
   if typeof(context)~="table" then return false end
   context.Placement=api.placement(p,product,context.Tile);return context.Placement~=nil
  end)
 end
 sim.Economy.register("Upgrade",function(p,_,c)return api.price(p,api.Units[c.UnitID].Type) end,function(p,_,c)return validUnit(p,c,true) end)
 sim.Economy.register("Demolish",function()return "0" end,function(p,_,c)return validUnit(p,c,false) end)
 local function purchase(p,e,product,context)
  local receipt,fresh=sim.Economy.purchase(p,e.Sequence,product,context)
  table.insert(sim.TransactionResults,{UserId=p.UserId,Receipt=receipt,Fresh=fresh,
   Message=if receipt.OK then (if fresh then product.." accepted." else "Order already processed; no second charge.") else "Building order rejected: "..receipt.Reason})
  return fresh and receipt.OK
 end
 function api.order(p,e)
  local active=true;local u=nil;local remaining=0
  local execution={activeDuringSpawnPhase=function()return false end,isActive=function()return active end}
  function execution.init()
   if e.Action=="Upgrade" then
    if purchase(p,e,"Upgrade",{UnitID=e.UnitID}) then
     local unit=api.Units[e.UnitID];if sim.Missiles then sim.Missiles.upgrade(unit) end;unit.Level+=1;p.BuildingConstructed[unit.Type]=(p.BuildingConstructed[unit.Type] or 0)+1;changed(p);dirty(unit)
    end
    active=false
   elseif e.Action=="Demolish" then
    if purchase(p,e,"Demolish",{UnitID=e.UnitID}) then
     u=api.Units[e.UnitID];p.LastDeleteUnitTick=sim.Tick;u.DeleteAt=sim.Tick+300;dirty(u)
    else active=false end
   elseif e.Action~="Build" or not Rules.Info[e.Type] or not grid.valid(e.Tile) then active=false end
  end
  function execution.tick()
   if e.Action=="Demolish" then
    if not u.Active then active=false
    elseif u.DeleteAt and sim.Tick>u.DeleteAt then api.destroy(u);active=false end
    return
   end
   if not u then
    local context={Tile=e.Tile}
    if not purchase(p,e,"Build:"..e.Type,context) then active=false;return end
    serial+=1
    local duration=if config.InstantBuild then 0 else Rules.Info[e.Type].Duration
    u={ID=serial,Type=e.Type,Tile=context.Placement,Owner=p,Level=1,Active=true,UnderConstruction=duration>0,CompleteTick=sim.Tick+duration+1}
    api.Units[serial]=u;api.Count+=1;table.insert(p.BuildingUnits,u)
    local key=bucket(u.Tile);buckets[key]=buckets[key] or {};table.insert(buckets[key],u)
    p.BuildingConstructed[u.Type]=(p.BuildingConstructed[u.Type] or 0)+1;changed(p);dirty(u)
    remaining=duration
    if duration==0 then u.CompleteTick=sim.Tick;active=false;if sim.Rail then sim.Rail.completed(u) end;if sim.Naval then sim.Naval.port(u) end;if sim.Missiles then sim.Missiles.completed(u) end end
    return
   end
   if not u.Active then active=false;return end
   if remaining==0 then
    u.UnderConstruction=false;changed(u.Owner);dirty(u);active=false
    if not u.Owner.IsBot then table.insert(sim.TransactionResults,{UserId=u.Owner.UserId,Message=Rules.Info[u.Type].Name.." construction complete."})end
    if sim.Rail then sim.Rail.completed(u) end;if sim.Naval then sim.Naval.port(u) end;if sim.Missiles then sim.Missiles.completed(u) end;return
   end
   remaining-=1
  end
  local init,tick=execution.init,execution.tick
  function execution.init()local began=os.clock();init();sim.Work.BuildingMilliseconds=(sim.Work.BuildingMilliseconds or 0)+(os.clock()-began)*1000 end
  function execution.tick()local began=os.clock();tick();sim.Work.BuildingMilliseconds=(sim.Work.BuildingMilliseconds or 0)+(os.clock()-began)*1000 end
  sim.Executions.add(execution)
 end
 return api
end
return Buildings
