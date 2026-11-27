--!strict
-- Roblox authority adapter around the pinned OpenFront execution lifecycle.
local Grid = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Grid)
local Random32 = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Random32)
local Executions = require(script.Parent.Executions)
local Troops = require(game:GetService("ReplicatedStorage").Shared.OpenFront.Troops)
local OrderedSet = require(script.Parent.OrderedSet)
local Spawn = require(script.Parent.Spawn)
local Expansion = require(script.Parent.Expansion)
local SpawnExecution = require(script.Parent.SpawnExecution)
local Connectivity = require(script.Parent.Connectivity)
local Economy = require(script.Parent.Economy)
local Buildings = require(script.Parent.Buildings)
local Rail = require(script.Parent.Rail)
local Naval = require(script.Parent.Naval)
local Missiles = require(script.Parent.Missiles)
local Match = require(script.Parent.Match)
local Bots = require(script.Parent.Bots)
local BasicNations = require(script.Parent.BasicNations)
local SpawnIndex = require(script.Parent.SpawnIndex)
local SpawnPlanner = require(script.Parent.SpawnPlanner)
local Simulation={}
function Simulation.new(terrain, map, seed: number, options)
	local stage2=options and options.Stage>=2
	local stage3=options and options.Stage>=3
	local stage4=options and options.Stage>=4
	local stage5=options and options.Stage>=5
	local stage6=options and options.Stage>=6
 local stage7=options and options.Stage>=7
	local stage8=options and options.Stage>=8
 if options and options.Stage>=9 and options.Bots and options.Bots.Enabled and terrain.configureCache then terrain.configureCache(options.Bots.TerrainCachePages or 8192) end
	local grid=Grid.new(terrain.Width,terrain.Height,terrain.byte)
	local rng=Random32.new(seed)
	local queue,players={},{}
	local nextID=1
	local sim={Grid=grid,Tick=0,Phase="Waiting",EndTick=0,Players=players,Seed=seed,Executions=Executions.new(),Work={Claims=0,Pops=0,CombatClaims=0,ActiveAttacks=0}}
	sim.Stage=options and options.Stage or 1;sim.LandCount=map.LandCount or terrain.LandCount or grid.Size;sim.MatchID=options and options.MatchID or 1
 sim.Terrain=terrain;sim.Balance=options and options.Balance or {}
 sim.BasicNations=BasicNations.new(sim,options and options.BasicNations)
 if sim.Stage>=11 then sim.SpawnIndex=SpawnIndex.new(grid.Width,grid.Height);sim.SpawnPlanner=SpawnPlanner.new(terrain,sim.SpawnIndex) end
 sim.TeamMode=options and options.Match and options.Match.Mode=="Team" or false
	if stage4 then sim.Economy=Economy.new(sim,options.Economy) end
	if stage5 then sim.Buildings=Buildings.new(sim,options.Buildings) end
	if stage5 then sim.Rail=Rail.new(sim) end
	if stage6 then sim.Naval=Naval.new(sim,terrain) end
 if stage8 then sim.Missiles=Missiles.new(sim);sim.Match=Match.new(sim,options.Match) end
 if sim.Stage>=9 then sim.Bots=Bots.new(sim,options.Bots) end
	function sim.conquerPlayer(winner,loser) loser.ConqueredBy=winner.UserId;if sim.ProgressionElimination then sim.ProgressionElimination(winner,loser)end;if sim.Economy then sim.Economy.conquest(winner,loser) end end
	local byID={};local attackID=0;local neighbors={}
	function sim.nextAttackID() attackID+=1;return attackID end
	local function updateBorder(ref)
		local p=byID[grid.ownerID(ref)]
		if p then if grid.isBorder(ref) then p.Border.add(ref) else p.Border.delete(ref) end end
	end
	function sim.conquer(p,ref)
		local previous=byID[grid.ownerID(ref)]
		assert(stage3 or not previous,"Stage 2 cannot capture another player")
		if previous then previous.TileVersion=(previous.TileVersion or 0)+1;previous.LastTileChange=sim.Tick;previous.Border.delete(ref);previous.Tiles.delete(ref);sim.Work.CombatClaims+=1 end
		p.Tiles.add(ref);p.LastTileChange=sim.Tick;p.TileVersion=(p.TileVersion or 0)+1
		grid.setOwnerID(ref,p.SmallId);if bit32.band(grid.state(ref),Grid.FalloutBit)~=0 then grid.setState(ref,bit32.band(grid.state(ref),bit32.bnot(Grid.FalloutBit))) end;updateBorder(ref)
		if previous and (grid.Counts[previous.SmallId] or 0)==0 then previous.Eliminated=true;sim.MetadataDirty=true end
		local n=grid.neighbors4(ref,neighbors);for i=1,n do updateBorder(neighbors[i]) end
	end
	function sim.relinquish(p,ref,fallout)
		assert(grid.ownerID(ref)==p.SmallId)
		p.LastTileChange=sim.Tick;p.TileVersion=(p.TileVersion or 0)+1;p.Border.delete(ref);p.Tiles.delete(ref)
  if fallout then grid.setState(ref,bit32.bor(bit32.band(grid.state(ref),0xf000),Grid.FalloutBit)) else grid.setOwnerID(ref,0) end
  -- Every still-owned neighbour now borders this neutral tile. Add in the same
  -- N,S,W,E order as updateBorder, without rescanning its four neighbours.
		local n=grid.neighbors4(ref,neighbors);for i=1,n do local t=neighbors[i];local owner=byID[grid.ownerID(t)];if owner then owner.Border.add(t) end end
	end
 function sim.falloutOwner(p,tiles)
  p.LastTileChange=sim.Tick;p.TileVersion=(p.TileVersion or 0)+#tiles;p.Border.deleteMany(tiles);p.Tiles.deleteMany(tiles)
 end
 function sim.falloutBorders(ref,mask)
  local w=grid.Width;local x=ref%w
  local function add(t)local owner=byID[grid.ownerUnchecked(t)];if owner then owner.Border.add(t) end end
  if bit32.band(mask,1)~=0 and ref>=w then add(ref-w) end;if bit32.band(mask,2)~=0 and ref<(grid.Height-1)*w then add(ref+w) end
  if bit32.band(mask,4)~=0 and x>0 then add(ref-1) end;if bit32.band(mask,8)~=0 and x<w-1 then add(ref+1) end
 end
	function sim.startRecruitment(p)
		local active=true;local lastCalc=0
        local connectivity=if stage3 then Connectivity.new(sim,p) else nil
		sim.Executions.add({activeDuringSpawnPhase=function() return false end,
			isActive=function() return active and players[p.UserId]==p end,
            init=function() lastCalc=sim.Tick+SpawnExecution.simpleHash(tostring(p.UserId))%20 end,
			tick=function()
                if sim.Buildings and not p.BasicNation then local began=os.clock();sim.Buildings.reconcile(p);sim.Work.BuildingMilliseconds+=(os.clock()-began)*1000 end
                local count=grid.Counts[p.SmallId] or 0
                if stage3 and count==0 then p.Eliminated=true;sim.MetadataDirty=true;if sim.Naval then sim.Naval.removePlayer(p,stage8) end;if sim.Rail then sim.Rail.removePlayer(p) end;if sim.Economy then sim.Economy.death(p) end;active=false;return end
                Troops.add(p,Troops.growth(p.Troops,Troops.cap(count,p.CityLevels or 0,p.Kind,p.Difficulty),p.Kind,p.Difficulty)*(if p.BasicNation then sim.Balance.BasicRecruitmentMultiplier or .2 else sim.Balance.RecruitmentMultiplier or 1))
                if sim.Economy and not p.BasicNation then local began=os.clock();sim.Economy.tick(p);sim.Work.EconomyMilliseconds=(sim.Work.EconomyMilliseconds or 0)+(os.clock()-began)*1000 end
                if connectivity and (sim.Tick-lastCalc>20 or count<100) and (p.LastTileChange or 0)>=lastCalc then
                    lastCalc=sim.Tick
                    local began=os.clock();connectivity.removeClusters()
                    sim.Work.ConnectivityMilliseconds=(sim.Work.ConnectivityMilliseconds or 0)+(os.clock()-began)*1000
                end
            end})
	end
	function sim.owner(id) return byID[id] end
	function sim.friendly(a,b)
		return a==b or (not b.Disconnected and ((a.Team~=nil and a.Team==b.Team) or (a.Allies and a.Allies[b.UserId]==true))) or false
	end
	function sim.canAttack(a,b)
		return players[b.UserId]==b and not sim.friendly(a,b) and (a.Kind~="Human" or (sim.Phase=="Started" and sim.Tick-(sim.StartTick or 0)>=50))
	end
	function sim.sharesBorder(a,b)
        local found=false;local nb={}
        a.Border.each(function(t)
            local n=grid.neighbors4(t,nb)
            for i=1,n do if grid.ownerID(nb[i])==b.SmallId then found=true;return false end end
        end)
        return found
    end
    local function attackStats(p)
		local list={};for _,attack in ipairs(p.Outgoing) do
			if attack.Active then table.insert(list,{ID=attack.ID,Target=if attack.Target then attack.Target.Username else "Unclaimed land",Troops=attack.Troops,Retreating=attack.Retreating}) end
		end;return list
	end
	local cachedPlayers=nil;local rosterDirty=true;local lastSpawns={}
	local function orderedPlayers()
        if cachedPlayers then return cachedPlayers end
		local ids={}; for id in pairs(players) do table.insert(ids,id) end; table.sort(ids)
		local list={}; for _,id in ipairs(ids) do table.insert(list,players[id]) end; cachedPlayers=list;return list
	end
	function sim.inSpawnPhase(): boolean return sim.Phase~="Started" end
	function sim.enqueue(event) table.insert(queue,event) end
	local function free(ref: number, userId: number): boolean
		if not grid.valid(ref) or not grid.isLand(ref) or grid.isImpassable(ref) then return false end
		if grid.ownerID(ref)~=0 then return false end
		for id,p in pairs(players) do
			if id~=userId and p.Spawn then
				if p.Spawn==ref+1 then return false end
			end
		end
		return true
	end
	local function finish()
		if stage2 then
			for _,p in ipairs(orderedPlayers()) do
				if not p.Spectator and not p.Spawn then
     local execution=SpawnExecution.new(sim,p,nil,false)
     if sim.SpawnPlanner then execution.init();execution.tick()else sim.Executions.add(execution)end
    end
			end
			sim.Phase="Started";sim.StartTick=sim.Tick;return
		end
		for _,p in ipairs(orderedPlayers()) do
			if not p.Spectator then
				if not p.Spawn then
					local start=rng.nextInt(1,map.LandCount+1)
					for offset=0,math.min(map.LandCount-1,10000) do
						local cell=map.landAt((start+offset*7919-1)%map.LandCount+1)
						if free(cell-1,p.UserId) then
							p.Spawn=cell; local x,y=map.xy(cell); p.X,p.Y=x+0.5,y+0.5; break
						end
					end
				end
				if p.Spawn then
					grid.setOwnerID(p.Spawn-1,p.SmallId)
				else p.Spectator=true end
			end
		end
		sim.Phase="Started"
	end
	function sim.metadata(includeBuildings)
		local list={}
		for _,p in ipairs(orderedPlayers()) do
			local copy={BasicNation=p.BasicNation,IsBot=p.IsBot,BotDifficulty=p.BotDifficulty,UserId=p.UserId,Username=p.Username,SmallId=p.SmallId,Spectator=p.Spectator,Spawn=p.Spawn,X=p.X,Y=p.Y,Count=grid.Counts[p.SmallId] or 0}
            -- Presentation anchor: retain a valid owned cell; bounded fallback avoids full-world scans.
            if sim.Phase=="Started" and copy.Count>0 then
                local anchor=p.LabelTile or (p.Spawn and p.Spawn-1)
                if not anchor or grid.ownerID(anchor)~=p.SmallId then
                    local candidates; candidates,p.LabelCursor=p.Tiles.sample(p.LabelCursor,64)
                    anchor=candidates[1]
                end
                p.LabelTile=anchor
                if anchor then copy.LabelX=if p.Spawn and anchor==p.Spawn-1 then p.X else anchor%grid.Width+0.5;copy.LabelY=if p.Spawn and anchor==p.Spawn-1 then p.Y else math.floor(anchor/grid.Width)+0.5 else copy.LabelHidden=true end
            elseif sim.Phase=="Started" then copy.LabelHidden=true end
			if stage2 then
				if sim.Economy then copy.Gold=p.Gold;copy.GoldIncome=if copy.Count>0 and sim.Phase=="Started" and not p.Eliminated and not p.Spectator then sim.Economy.income(p) else "0" end
				copy.Attacks=attackStats(p);copy.Eliminated=p.Eliminated;copy.Troops=p.Troops;copy.Cap=Troops.cap(copy.Count,p.CityLevels or 0,p.Kind,p.Difficulty);copy.Growth=if sim.Phase=="Started" and not p.Spectator and not p.Eliminated then Troops.growth(p.Troops,copy.Cap,p.Kind,p.Difficulty)*(if p.BasicNation then sim.Balance.BasicRecruitmentMultiplier or .2 else sim.Balance.RecruitmentMultiplier or 1) else 0
				copy.Allocation=p.Allocation;copy.Committed=if p.Attack and p.Attack.Active then p.Attack.Troops else 0
				copy.AttackID=if p.Attack and p.Attack.Active then p.Attack.ID else 0
				copy.Retreating=p.Attack~=nil and p.Attack.Retreating
			end
			table.insert(list,copy)
		end
		local selected=0;for _,row in ipairs(list)do if row.Spawn and not row.Spectator then selected+=1 end end
		return {StartTick=sim.StartTick,LandCount=sim.LandCount,RailUnits=if sim.Stage>=11 and sim.Rail then sim.Rail.snapshot()else nil,SelectedSpawns=selected,Participants=#list,Foundation=true,Stage=if sim.Stage>=9 then sim.Stage elseif stage8 then 8 elseif stage7 then 7 elseif stage6 then 6 elseif stage5 then 5 elseif stage4 then 4 elseif stage3 then 3 elseif stage2 then 2 else 1,MatchID=sim.MatchID,Winner=sim.Match and sim.Match.Winner,Rankings=sim.Match and sim.Match.Rankings,RestartAt=sim.Match and sim.Match.RestartAt,Phase=sim.Phase,EndTick=sim.EndTick,Tick=sim.Tick,Revision=sim.Tick,Players=list,Seed=seed,MapHash=terrain.MaskHash,Ships=if sim.Naval and includeBuildings~=false then sim.Naval.snapshot() else nil,Buildings=if sim.Buildings and includeBuildings~=false then sim.Buildings.snapshot() else nil}
	end
	function sim.stats()
		local list={}
		for _,p in ipairs(orderedPlayers()) do
            if p.IsBot then continue end -- Bots have no private HUD/RemoteEvent recipient.
			local count=grid.Counts[p.SmallId] or 0;local cap=Troops.cap(count,p.CityLevels or 0);local attack=p.Attack
			table.insert(list,{Economy=sim.Economy and sim.Economy.summary(p),Gold=p.Gold,GoldIncome=if sim.Economy and count>0 and sim.Phase=="Started" and not p.Eliminated and not p.Spectator then sim.Economy.income(p) else "0",Attacks=attackStats(p),Eliminated=p.Eliminated,UserId=p.UserId,Tick=sim.Tick,Count=count,Troops=p.Troops,Cap=cap,Growth=if sim.Phase=="Started" and not p.Spectator and not p.Eliminated then Troops.growth(p.Troops,cap)*(sim.Balance.RecruitmentMultiplier or 1) else 0,
				Missiles=sim.Missiles and sim.Missiles.summary(p),Naval=if sim.Naval then sim.Naval.summary(p) else nil,Rail=if sim.Rail then sim.Rail.summary(p) else nil,BuildingQuotes=if sim.Buildings then sim.Buildings.quotes(p) else nil,Allocation=p.Allocation,Committed=if attack and attack.Active then attack.Troops else 0,
				AttackID=if attack and attack.Active then attack.ID else 0,Retreating=attack~=nil and attack.Retreating})
		end
		return list
	end
	function sim.step()
  sim.Work.FrontierMilliseconds=0;sim.Work.MissileMilliseconds=0
		sim.Work.Claims=0;sim.Work.Pops=0;sim.Work.CombatClaims=0;sim.Work.ActiveAttacks=0;sim.Work.ConnectivityMilliseconds=0;sim.Work.EconomyMilliseconds=0;sim.Work.BuildingMilliseconds=0;sim.Work.RailMilliseconds=0;sim.Work.NavalMilliseconds=0
		local changed=false; local results={};sim.TransactionResults=results
		if sim.Phase=="Selecting" and sim.Tick>sim.EndTick then finish(); changed=true end
		local events=queue; queue={}
		for _,e in ipairs(events) do
			local p=players[e.UserId]
			if e.Kind=="Join" and not p and nextID<=Grid.OwnerMask then
                cachedPlayers=nil;rosterDirty=true
				players[e.UserId]={UserId=e.UserId,Username=e.Username,SmallId=nextID,Spectator=sim.Phase~="Waiting" and sim.Phase~="Selecting",Kind="Human",Difficulty="Hard",Troops=if stage2 and sim.Phase~="Started" then (sim.Balance.StartingSoldiers or Troops.initial("Human")) else 0,Allocation=sim.Balance.DefaultAllocation or .2,Border=OrderedSet.new(),Tiles=OrderedSet.new(),Outgoing={},Incoming={}}
                local joined=players[e.UserId]
                joined.IsBot=e.IsBot==true;joined.BotDifficulty=e.BotDifficulty;joined.BasicNation=e.BasicNation==true
                if joined.BasicNation then joined.Kind="Bot";joined.Troops=math.clamp(e.StartingTroops or 1000,500,1500)end
                if joined.IsBot then joined.Team=e.Team end
                if options and options.Match and options.Match.SinglePlayer and not joined.IsBot then
                 for id,other in pairs(players) do if id~=e.UserId and not other.IsBot and not other.Spectator then joined.Spectator=true;break end end
                end
				if stage8 and options.Match and options.Match.Teams and options.Match.Teams[e.UserId]~=nil then players[e.UserId].Team=options.Match.Teams[e.UserId] end
				if sim.Economy then sim.Economy.init(players[e.UserId]) end
				if sim.Buildings then sim.Buildings.init(players[e.UserId]) end
				if sim.Naval then sim.Naval.init(players[e.UserId]) end
				byID[nextID]=players[e.UserId];nextID+=1; changed=true
			elseif e.Kind=="Leave" and p then
                cachedPlayers=nil;rosterDirty=true
    if sim.SpawnIndex then sim.SpawnIndex.remove(p.UserId) end
    if sim.SpawnPlanner then sim.SpawnPlanner.remove(p.UserId)end
    if sim.Match then sim.Match.remember(p) end
				if sim.Naval then sim.Naval.removePlayer(p) end
				if sim.Rail then sim.Rail.removePlayer(p) end
				if sim.Buildings then sim.Buildings.leave(p) end
    if stage3 then
     -- All departing cells become neutral in the same ordered event. Adjacent
     -- OTHER owners remain borders (both the old owner and zero differ from
     -- theirs); the departing owner's borders will be discarded altogether.
     -- Preserve first-mutation order without rebuilding these redundant borders.
     local released=p.Tiles.Size
     p.Tiles.each(function(ref)grid.setOwnerID(ref,0)end)
     p.Tiles.clear();p.Border.clear();p.TileVersion=(p.TileVersion or 0)+released;p.LastTileChange=sim.Tick
                else grid.release(p.SmallId,function(ref)
                    local n=grid.neighbors4(ref,neighbors);for i=1,n do updateBorder(neighbors[i]) end
                end) end
				if sim.Economy then sim.Economy.leave(p) end
				byID[p.SmallId]=nil;players[e.UserId]=nil; changed=true
				local hasHuman=false;for _,remaining in pairs(players) do if not remaining.IsBot then hasHuman=true;break end end
				if not next(players) or sim.Stage>=9 and not hasHuman then
     if stage8 then sim.Phase="Results";sim.Match.RestartAt=sim.Tick+1;sim.Match.Winner={Name="All players disconnected",Draw=true}
     else sim.Phase="Waiting";sim.EndTick=0;nextID=1 end
    end
			elseif e.Kind=="Ready" and p then
				if sim.Phase=="Waiting" then sim.Phase="Selecting"; sim.EndTick=sim.Tick+200; changed=true end
			elseif stage8 and e.Kind=="Missile" and p and sim.Phase=="Started" then sim.Missiles.order(p,e)
			elseif stage6 and e.Kind=="Naval" and p then
                sim.Naval.order(p,e)
			elseif stage5 and e.Kind=="Building" and p then
                sim.Buildings.order(p,e)
			elseif stage4 and e.Kind=="Purchase" and p then
                local account,sequence,product,context=p,e.Sequence,e.Product,e.Context;local active=true
                sim.Executions.add({activeDuringSpawnPhase=function()return false end,isActive=function()return active end,init=function()end,
                    tick=function()
                        local receipt,fresh=sim.Economy.purchase(account,sequence,product,context);active=false
                        table.insert(sim.TransactionResults,{UserId=account.UserId,Receipt=receipt,Fresh=fresh,Message=if receipt.OK then "Transaction accepted." else "Transaction rejected: "..receipt.Reason})
                    end})
			elseif stage2 and e.Kind=="Expand" and p then
				local cell=map.cell(e.X,e.Y);local allocation=e.Allocation
				local target=if cell then byID[grid.ownerID(cell-1)] else nil
				local valid=sim.Phase=="Started" and not p.Spectator and cell and (not target or (stage3 and sim.canAttack(p,target) and sim.sharesBorder(p,target))) and not p.Eliminated and grid.isLand(cell-1) and not grid.isImpassable(cell-1)
				valid=valid and typeof(allocation)=="number" and allocation==allocation and allocation>=0 and allocation<=1
				if valid and math.floor(p.Troops*allocation)>0 then
					p.Allocation=allocation;sim.Executions.add(Expansion.new(sim,p,p.Troops*allocation,target))
					table.insert(results,{UserId=e.UserId,Message=if target then "Attacking "..target.Username.." along shared borders." else "Expanding along all eligible neutral borders."})
				else table.insert(results,{UserId=e.UserId,Message="Choose valid enemy or unclaimed land with soldiers available. Human spawns are immune for 5 seconds."}) end
			elseif stage2 and e.Kind=="Cancel" and p then
				for _,attack in ipairs(p.Outgoing) do
					if attack.Active and e.AttackID==attack.ID and not attack.CancelQueued then
						attack.CancelQueued=true;sim.Executions.add(Expansion.retreat(sim,p,e.AttackID))
					end
				end
			elseif e.Kind=="SelectSpawn" and p then
				local cell=map.cell(e.X,e.Y)
				if stage2 then
					if cell and not p.Spectator then sim.Executions.add(SpawnExecution.new(sim,p,cell-1,true,e.X,e.Y)) end
					continue
				end
				local success=sim.Phase=="Selecting" and not p.Spectator and cell~=nil and free(cell-1,e.UserId)
				if success then p.Spawn,p.X,p.Y=cell,e.X,e.Y; changed=true end
				table.insert(results,{UserId=e.UserId,Message=if success then "Spawn selected exactly here." else "Choose unoccupied land during spawn selection."})
			end
		end
        if sim.Bots then sim.Bots.step();sim.Work.BotMilliseconds=sim.Bots.Milliseconds end
        sim.BasicNations.step();sim.Work.BasicMilliseconds=sim.BasicNations.Milliseconds
		if sim.Phase=="Started" or sim.Phase=="Waiting" or sim.Phase=="Selecting" then sim.Executions.step(sim) end
  if sim.Match then sim.Match.tick() end
		for _,p in pairs(players) do sim.Work.ActiveAttacks+=#p.Outgoing end
		if sim.Stage>=11 and sim.Rail and sim.Tick%10==0 then local anyTrain=next(sim.Rail.Trains)~=nil;if anyTrain or sim.HadTrains then changed=true end;sim.HadTrains=anyTrain end
		if sim.MetadataDirty then changed=true;sim.MetadataDirty=false end
  if sim.Stage>=11 and sim.Phase=="Selecting"then
   sim.PendingSpawnMetadata=sim.PendingSpawnMetadata or changed
   changed=sim.Tick%2==0 and sim.PendingSpawnMetadata
   if changed then sim.PendingSpawnMetadata=false end
  end
  sim.Tick+=1
  local spawnChanges=nil;local outMeta=nil
  if changed then
   if sim.Stage>=11 and sim.Phase=="Selecting"and not rosterDirty then
    local rows={};local selected=0;local total=0
    for _,p in ipairs(orderedPlayers())do
     total+=1;if p.Spawn then selected+=1 end
     local previous=lastSpawns[p.UserId];local key=tostring(p.Spawn)..":"..tostring(p.X)..":"..tostring(p.Y)
     if previous~=key then table.insert(rows,{UserId=p.UserId,Spawn=p.Spawn or false,X=p.X,Y=p.Y,Count=grid.Counts[p.SmallId]or 0});lastSpawns[p.UserId]=key end
    end
    spawnChanges={Players=rows,Selected=selected,Participants=total}
   else
    outMeta=sim.metadata(false);rosterDirty=false
    for _,p in ipairs(orderedPlayers())do lastSpawns[p.UserId]=tostring(p.Spawn)..":"..tostring(p.X)..":"..tostring(p.Y)end
   end
  end
		return {SpawnChanges=spawnChanges,Tick=sim.Tick,Revision=sim.Tick,Changes=grid.drain(),Meta=outMeta,BuildingChanges=if sim.Buildings then sim.Buildings.drain() else nil,ShipChanges=if sim.Naval then sim.Naval.drain() else nil,
			Stats=if stage2 and sim.Tick%2==0 then sim.stats() else nil},results
	end
	return sim
end
return Simulation
