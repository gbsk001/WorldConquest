--!strict
return function(session)
	local Players=game:GetService("Players")
	local RS=game:GetService("ReplicatedStorage")
	local RunService=game:GetService("RunService")
	local Shared=RS:WaitForChild("Shared")
	local Config=require(Shared.Config)
	local Map=require(Shared.Map)
	local Terrain=require(Shared.OpenFront.EarthTerrain)
	local Clock=require(Shared.OpenFront.Clock)
	local Simulation=require(script.Parent.Simulation)
	local Wire=require(Shared.OpenFront.BuildingWire)
	local ShipWire=if Config.PortStage>=6 then require(Shared.OpenFront.ShipWire) else nil
	local round=1
 local activeSessionID=nil
 local function createMatch()
  local match=Config.Match
  if session then match=table.clone(match or {});match.SinglePlayer=nil end
  return Simulation.new(Terrain,Map,(if session and session.MatchSeed then session.MatchSeed else Config.SimulationSeed+round-1),{Stage=Config.PortStage,Economy=Config.Economy,Buildings=Config.Buildings,Match=match,MatchID=round,Bots=if session then session.BotSettings else Config.Bots})
 end
 local sim=createMatch()
	Players.CharacterAutoLoads=false
	local remote=Instance.new("RemoteEvent"); remote.Name="WorldConquestEvent"
	local connected,requests,transfers,ready={},{},{},{}
	local clientsByID={}
 local function broadcast(action,payload)
  if session then for p in pairs(connected)do remote:FireClient(p,action,payload)end else remote:FireAllClients(action,payload)end
 end
	local transferID=0
	local function metadata()
		local meta=sim.metadata(false)
		for _,p in ipairs(meta.Players) do p.Color=if Config.PortStage>=11 then Color3.fromHSV((p.SmallId*0.61803398875+sim.Seed%997/997)%1,.65,.95)else Config.PlayerColors[p.SmallId] or Color3.fromHSV((p.SmallId*0.61803398875)%1,0.65,0.95) end
		if session and session.Decorate then session.Decorate(meta)end
		return meta
	end
	local function join(p)
  if session and not session.Allowed[p]then return end
		if connected[p] then return end
		connected[p]=true;clientsByID[p.UserId]=p; sim.enqueue({Kind="Join",UserId=p.UserId,Username=if session and session.DisplayName then session.DisplayName(p)else p.Name,AccountUsername=p.Name})
	end
	Players.PlayerAdded:Connect(join)
	local function leave(p)
  if not connected[p]then return end
		connected[p],requests[p],transfers[p],ready[p]=nil,nil,nil,nil
		clientsByID[p.UserId]=nil
		sim.enqueue({Kind="Leave",UserId=p.UserId})
	end
 Players.PlayerRemoving:Connect(leave)
	local initial=Players:GetPlayers(); table.sort(initial,function(a,b) return a.UserId<b.UserId end)
	for _,p in ipairs(initial) do join(p) end
	remote.OnServerEvent:Connect(function(p,action,x,y,allocation,matchID)
		if not connected[p] or (action~="Sync" and action~="SelectSpawn" and action~="Expand" and action~="Cancel" and action~="Building" and action~="Naval" and action~="Missile") then return end
		if Config.PortStage>=8 and action~="Sync" and (matchID~=round or sim.Phase=="Victory" or sim.Phase=="Results") then return end
		local record=requests[p] or {}; requests[p]=record
		local now=os.clock(); local key=if action=="Sync" then "Sync" else "Action"
		local cooldown=if action=="Sync" then 2 else Config.RequestCooldown
		if now-(record[key] or -math.huge)<cooldown then return end; record[key]=now
  if action=="Sync" then
   if not transfers[p] and not ready[p] then sim.enqueue({Kind="Ready",UserId=p.UserId});ready[p]=true end
   return
  end
        if action=="Missile" then
            if Config.PortStage<8 or sim.Phase~="Started" or typeof(x)~="table" then return end
            if x.Type~="AtomBomb" and x.Type~="HydrogenBomb" and x.Type~="MIRV" then return end
            if typeof(x.Sequence)~="number" or x.Sequence%1~=0 or x.Sequence<1 or x.Sequence>9007199254740991 then return end
            local cell=Map.cell(x.X,x.Y);if not cell then return end
            sim.enqueue({Kind="Missile",Type=x.Type,Sequence=x.Sequence,Tile=cell-1,UserId=p.UserId});return
        end
        if action=="Naval" then
            if Config.PortStage<6 or sim.Phase~="Started" or typeof(x)~="table" then return end
            local function integer(v,lo,hi)return typeof(v)=="number" and v==v and v%1==0 and v>=lo and v<=hi end
            if not integer(x.Sequence,1,9007199254740991) then return end
            local order={Kind="Naval",UserId=p.UserId,Sequence=x.Sequence,Action=x.Action}
            if x.Action=="Transport" or x.Action=="Warship" or x.Action=="Move" then
                local cell=Map.cell(x.X,x.Y);if not cell then return end;order.Tile=cell-1
                if x.Action=="Transport" then
                    if typeof(x.Allocation)~="number" or x.Allocation~=x.Allocation or x.Allocation<0 or x.Allocation>1 then return end;order.Allocation=x.Allocation
                end
            elseif x.Action~="Retreat" then return end
            if x.Action=="Move" or x.Action=="Retreat" then if not integer(x.UnitID,1,4294967295) then return end;order.UnitID=x.UnitID end
            sim.enqueue(order);return
        end
		if action=="Building" then
            if Config.PortStage<5 or sim.Phase~="Started" or typeof(x)~="table" then return end
            local function integer(v,minimum,maximum)return typeof(v)=="number" and v==v and v%1==0 and v>=minimum and v<=maximum end
            if not integer(x.Sequence,1,9007199254740991) then return end
            local order={Kind="Building",UserId=p.UserId,Sequence=x.Sequence,Action=x.Action}
            if x.Action=="Build" then
                if (x.Type~="City" and x.Type~="DefensePost" and x.Type~="Factory" and x.Type~="Port" and not (Config.PortStage>=8 and (x.Type=="MissileSilo" or x.Type=="SAMLauncher"))) or not Map.cell(x.X,x.Y) then return end
                order.Type=x.Type;order.Tile=Map.cell(x.X,x.Y)-1
            elseif x.Action=="Upgrade" or x.Action=="Demolish" then
                if not integer(x.UnitID,1,9007199254740991) then return end;order.UnitID=x.UnitID
            else return end
            sim.enqueue(order);return
        end
		if action=="Cancel" then
			if typeof(x)=="number" and x==x and x%1==0 and x>0 then sim.enqueue({Kind="Cancel",UserId=p.UserId,AttackID=x}) end
			return
		end
		if not Map.cell(x,y) then remote:FireClient(p,"Result","Invalid map coordinates."); return end
		if action=="Expand" and (typeof(allocation)~="number" or allocation~=allocation or allocation<0 or allocation>1) then return end
		sim.enqueue({Kind=action,UserId=p.UserId,X=x,Y=y,Allocation=allocation})
	end)
 local snapshotTick,snapshotPages=-1,nil
 if session then
  session.OnLeave=leave
  session.OnBegin=function(list)
   activeSessionID=session.ActiveID
   local tick=sim.Tick;round+=1;sim=createMatch();sim.Tick=tick;sim.Executions.Tick=tick
   connected,requests,transfers,ready,clientsByID={},{},{},{},{};snapshotTick,snapshotPages=-1,nil
   for _,p in ipairs(list)do join(p);remote:FireClient(p,"MatchReset",{MatchID=round})end
  end
  session.OnLate=function(p)join(p);remote:FireClient(p,"MatchReset",{MatchID=round})end
 end
 local function startSnapshot(p)
  transferID+=1
  local pages=snapshotPages
  if snapshotTick~=sim.Tick then
   pages=sim.Grid.snapshotPages()
        if sim.Buildings then
            local packed=Wire.pack(sim.Buildings.snapshot())
            for offset=0,buffer.len(packed)-1,24576 do
                local b=buffer.create(math.min(24576,buffer.len(packed)-offset));buffer.copy(b,0,packed,offset,buffer.len(b))
                table.insert(pages,{Key="Buildings"..offset,Buildings=b})
            end
        end
        if sim.Naval then
            local packed=ShipWire.pack(sim.Naval.snapshot())
            for offset=0,buffer.len(packed)-1,24576 do
                local b=buffer.create(math.min(24576,buffer.len(packed)-offset));buffer.copy(b,0,packed,offset,buffer.len(b))
                table.insert(pages,{Key="Ships"..offset,Ships=b})
            end
        end
   snapshotTick,snapshotPages=sim.Tick,pages
  end
 		transfers[p]={ID=transferID,Pages=pages,Next=1}
		remote:FireClient(p,"FoundationBegin",{ID=transferID,Tick=sim.Tick,Count=#pages,Meta=metadata(),MapHash=Terrain.MaskHash})
	end
 local tickTimes={};local tickIndex=0;local tickWorst=0
 local empty=buffer.create(0)
 local function slice(packed,offset,length)
  if length==0 then return empty end
  if offset==0 and length==buffer.len(packed) then return packed end
  local result=buffer.create(length);buffer.copy(result,0,packed,offset,length);return result
 end
 local clock=Clock.new(function()
		if sim.Match and sim.Match.RestartAt and sim.Tick>=sim.Match.RestartAt then
   if session then
    connected,requests,transfers,ready,clientsByID={},{},{},{},{};snapshotTick,snapshotPages=-1,nil
    sim=createMatch();session.Finish(activeSessionID)
   else
   local tick=sim.Tick;round+=1;sim=createMatch();sim.Tick=tick;sim.Executions.Tick=tick
   transfers,ready,requests={},{},{};snapshotTick,snapshotPages=-1,nil
   local list={};for p in pairs(connected) do table.insert(list,p) end;table.sort(list,function(a,b)return a.UserId<b.UserId end)
   for _,p in ipairs(list) do sim.enqueue({Kind="Join",UserId=p.UserId,Username=p.Name});sim.enqueue({Kind="Ready",UserId=p.UserId});ready[p]=true end
   broadcast("MatchReset",{MatchID=round})
   end
  end
  local began=os.clock()
		debug.profilebegin("WorldConquest.FoundationTick")
		local packet,results=sim.step()
		if session and session.Observe then session.Observe(sim,results)end
		if packet.Meta then packet.Meta=metadata() end
		-- Fragment at record boundaries. Clients install each tick atomically.
		local bytes=buffer.len(packet.Changes);local buildingBytes=if packet.BuildingChanges then buffer.len(packet.BuildingChanges) else 0
        local shipBytes=if packet.ShipChanges then buffer.len(packet.ShipChanges) else 0
        local limit=if sim.Naval then 8064 else 12288
        local parts=math.max(1,math.ceil(bytes/limit),math.ceil(buildingBytes/limit),math.ceil(shipBytes/limit))
  local encodedBytes=0
		for part=1,parts do
			local offset=(part-1)*limit;local length=math.max(0,math.min(limit,bytes-offset))
   local changes=slice(packet.Changes,offset,length)
   local uniform,encoding=nil,nil;if Config.PortStage>=8 then changes,uniform,encoding=sim.Grid.compressWire(changes) end
   local blength=math.max(0,math.min(limit,buildingBytes-offset));local b=slice(packet.BuildingChanges,offset,blength)
   local slength=math.max(0,math.min(limit,shipBytes-offset));local ships=slice(packet.ShipChanges,offset,slength)
   encodedBytes+=buffer.len(changes)+blength+slength
			broadcast("FoundationDelta",{ChangeEncoding=encoding,UniformState=uniform,MatchID=if Config.PortStage>=8 then round else nil,Tick=packet.Tick,Revision=packet.Revision,Part=part,Parts=parts,Changes=changes,BuildingChanges=b,ShipChanges=ships,SpawnChanges=if part==parts then packet.SpawnChanges else nil,Meta=if part==parts then packet.Meta else nil})
		end
		-- Private resource HUD at 5 Hz; do not rebroadcast every player's profile each tick.
		for _,stats in ipairs(packet.Stats or {}) do
			stats.MatchID=if Config.PortStage>=8 then round else nil;local client=clientsByID[stats.UserId];if client then remote:FireClient(client,"FoundationStats",stats) end
		end
		for _,result in ipairs(results) do
   local client=clientsByID[result.UserId];if client then remote:FireClient(client,"Result",result.Message) end
		end
  local transferring=0;for _ in pairs(transfers) do transferring+=1 end
  for p in pairs(ready) do
   if not connected[p] then ready[p]=nil
   elseif transferring<4 then startSnapshot(p);ready[p]=nil;transferring+=1 end
  end
  snapshotPages=nil;snapshotTick=-1 -- transfers own the pages; don't retain an obsolete snapshot.
		remote:SetAttribute("SimulationTick",sim.Tick)
		remote:SetAttribute("OwnershipBytes",sim.Grid.allocatedBytes())
		remote:SetAttribute("TickMilliseconds",(os.clock()-began)*1000)
		remote:SetAttribute("DeltaBytes",bytes)
  remote:SetAttribute("UnitAndOwnershipDeltaBytes",bytes+buildingBytes+shipBytes)
  remote:SetAttribute("EncodedDeltaBytes",encodedBytes)
  remote:SetAttribute("DeltaFragments",parts)
  remote:SetAttribute("SnapshotTransfers",transferring)
		remote:SetAttribute("FrontierPops",sim.Work.Pops)
  remote:SetAttribute("FrontierMilliseconds",sim.Work.FrontierMilliseconds or 0)
		remote:SetAttribute("CellsClaimed",sim.Work.Claims)
		remote:SetAttribute("CombatCellsClaimed",sim.Work.CombatClaims)
		remote:SetAttribute("ActiveAttacks",sim.Work.ActiveAttacks)
		remote:SetAttribute("ConnectivityMilliseconds",sim.Work.ConnectivityMilliseconds or 0)
		remote:SetAttribute("EconomyMilliseconds",sim.Work.EconomyMilliseconds or 0)
		remote:SetAttribute("BuildingMilliseconds",sim.Work.BuildingMilliseconds or 0)
		remote:SetAttribute("BuildingCount",if sim.Buildings then sim.Buildings.Count else 0)
		remote:SetAttribute("BuildingDeltaBytes",buildingBytes)
		remote:SetAttribute("RailMilliseconds",sim.Work.RailMilliseconds or 0)
		remote:SetAttribute("NavalMilliseconds",sim.Work.NavalMilliseconds or 0)
  remote:SetAttribute("MissileMilliseconds",sim.Work.MissileMilliseconds or 0);remote:SetAttribute("MatchID",round)
        remote:SetAttribute("ShipCount",if sim.Naval then sim.Naval.Count else 0)
        remote:SetAttribute("ShipDeltaBytes",shipBytes)
        remote:SetAttribute("WaterRouteCacheBytes",if sim.Naval then sim.Naval.Path.CacheBytes else 0)
        remote:SetAttribute("WaterSearchMilliseconds",if sim.Naval then sim.Naval.Path.SearchMilliseconds else 0)
		remote:SetAttribute("TrainUnits",if sim.Rail then sim.Rail.TrainUnits else 0)
		remote:SetAttribute("TraversalScratchBytes",if sim.Traversal then sim.Traversal.bytes() else 0)
		if sim.Tick%10==0 then remote:SetAttribute("LuaHeapKiB",gcinfo()) end
  local elapsed=(os.clock()-began)*1000
  tickIndex=tickIndex%300+1;tickTimes[tickIndex]=elapsed;tickWorst=math.max(tickWorst,elapsed)
  if sim.Tick%10==0 then
   if sim.Bots then
    remote:SetAttribute("BotDecisionMilliseconds",sim.Bots.Milliseconds)
    remote:SetAttribute("BotDecisions",sim.Bots.Decisions)
    remote:SetAttribute("BotOrders",sim.Bots.Orders)
    remote:SetAttribute("BotCount",#sim.Bots.Roster)
   end
   local sorted=table.clone(tickTimes);table.sort(sorted);local sum=0;for _,v in ipairs(sorted) do sum+=v end
   remote:SetAttribute("TickAverageMilliseconds",sum/#sorted)
   remote:SetAttribute("TickP95Milliseconds",sorted[math.ceil(#sorted*.95)])
   remote:SetAttribute("TickWorstMilliseconds",tickWorst)
  end
		debug.profileend()
	end,4)
	RunService.Heartbeat:Connect(function(dt)
		clock.advance(dt)
		remote:SetAttribute("TickBacklogSeconds",clock.Backlog)
  -- At most four active joins, each <=32 KiB/frame (including unit pages).
  -- Waiting joins have no stale snapshot/catch-up queue yet.
		for p,transfer in pairs(transfers) do
   local sent=0
			for _=1,4 do
				local page=transfer.Pages[transfer.Next]
				if not page then remote:FireClient(p,"FoundationEnd",{ID=transfer.ID}); transfers[p]=nil; break end
    local size=buffer.len(page.Data or page.Buildings or page.Ships)
    if sent+size>32768 then break end;sent+=size
				remote:FireClient(p,"FoundationChunk",{ID=transfer.ID,Key=page.Key,Data=page.Data,Buildings=page.Buildings,Ships=page.Ships}); transfer.Next+=1
			end
		end
	end)
	remote.Parent=RS
end
