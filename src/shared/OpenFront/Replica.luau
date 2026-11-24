--!strict
-- Atomic snapshot install and ordered authoritative deltas; no client simulation.
local Grid = require(script.Parent.Grid)
local Wire = require(script.Parent.BuildingWire)
local ShipWire = require(script.Parent.ShipWire)
local Replica={}
function Replica.new(terrain)
	local replica={Grid=Grid.new(terrain.Width,terrain.Height,terrain.byte,false),Tick=-1,Meta=nil,Buildings={},Ships={}}
	local pending=nil
	local fragments=nil
 local minimumMatch=0
	local function apply(packet)
		if packet.Tick<=replica.Tick then return true end -- duplicate reliable delivery/recovery
		if packet.Tick~=replica.Tick+1 or typeof(packet.Changes)~="buffer" or buffer.len(packet.Changes)%6~=0 then return false end
        local buildings=if packet.BuildingChanges then Wire.read(packet.BuildingChanges,replica.Grid.Size) else {}
        local ships=if packet.ShipChanges then ShipWire.read(packet.ShipChanges,replica.Grid.Size) else {}
        if not buildings or not ships then return false end
		for offset=0,buffer.len(packet.Changes)-1,6 do
			local ref,value=buffer.readu32(packet.Changes,offset),buffer.readu16(packet.Changes,offset+4)
			if not replica.Grid.valid(ref) then return false end
            -- Ref is validated above. One immutable terrain read replaces the
            -- nested isLand/isImpassable calls (three validation/LRU visits).
            if bit32.band(value,Grid.OwnerMask)~=0 then
                local byte=replica.Grid.terrainUnchecked(ref)
                if bit32.band(byte,128)==0 or bit32.band(byte,31)==31 then return false end
            end
		end
		for offset=0,buffer.len(packet.Changes)-1,6 do replica.Grid.setState(buffer.readu32(packet.Changes,offset),buffer.readu16(packet.Changes,offset+4)) end
		replica.Grid.discardChanges(); replica.Tick=packet.Tick
		if packet.Meta then replica.Meta=packet.Meta end
        if packet.SpawnChanges and replica.Meta then
            for _,change in ipairs(packet.SpawnChanges.Players)do
                for _,p in ipairs(replica.Meta.Players)do if p.UserId==change.UserId then
                    p.Spawn=change.Spawn or nil;p.X=change.X;p.Y=change.Y;p.Count=change.Count;break
                end end
            end
            replica.Meta.SelectedSpawns=packet.SpawnChanges.Selected;replica.Meta.Participants=packet.SpawnChanges.Participants
        end
        if #ships>0 then ShipWire.apply(replica.Ships,ships) end
        if replica.Meta and replica.Meta.Stage and replica.Meta.Stage>=6 and (packet.Meta or #ships>0) then replica.Meta.Ships=ShipWire.list(replica.Ships) end
        if #buildings>0 then Wire.apply(replica.Buildings,buildings) end
        if replica.Meta and replica.Meta.Stage and replica.Meta.Stage>=5 and (packet.Meta or #buildings>0) then replica.Meta.Buildings=Wire.list(replica.Buildings) end
		return true
	end
	function replica.begin(message)
  if message.Meta and message.Meta.MatchID and message.Meta.MatchID<minimumMatch then return false end
		fragments=nil
		if message.MapHash~=terrain.MaskHash or message.Count<0 or message.Count>math.ceil(terrain.Width*terrain.Height/Grid.ChunkCells)+math.ceil(terrain.Width*terrain.Height/1024) then pending=nil; return false end
		pending={ID=message.ID,Tick=message.Tick,Count=message.Count,Seen={},Received=0,Queue={},QueueBytes=0,Meta=message.Meta,Buildings={},Ships={},Grid=Grid.new(terrain.Width,terrain.Height,terrain.byte,false)}
        if message.Meta and message.Meta.Ships then ShipWire.apply(pending.Ships,message.Meta.Ships) end
        if message.Meta and message.Meta.Buildings then Wire.apply(pending.Buildings,message.Meta.Buildings) end
		return true
	end
	function replica.chunk(message)
		if not pending or message.ID~=pending.ID then return false end
		if pending.Seen[message.Key] then return true end
        if message.Ships then
            local list=ShipWire.read(message.Ships,terrain.Width*terrain.Height);if not list then pending=nil;return false end
            ShipWire.apply(pending.Ships,list);pending.Seen[message.Key]=true;pending.Received+=1;return true
        end
        if message.Buildings then
            local list=Wire.read(message.Buildings,terrain.Width*terrain.Height);if not list then pending=nil;return false end
            Wire.apply(pending.Buildings,list);pending.Seen[message.Key]=true;pending.Received+=1;return true
        end
		local ok=pcall(pending.Grid.loadChunk,message.Key,message.Data)
		if not ok then pending=nil; return false end
		pending.Grid.discardChanges(); pending.Seen[message.Key]=true; pending.Received+=1
		return true
	end
	function replica.delta(packet)
  if typeof(packet)=="table" and (packet.UniformState~=nil or packet.ChangeEncoding~=nil) then
   local decoded=Grid.expandWire(packet.Changes,packet.UniformState,terrain.Width*terrain.Height,packet.ChangeEncoding)
   if not decoded then return false end
   packet=table.clone(packet);packet.Changes=decoded;packet.UniformState=nil;packet.ChangeEncoding=nil
  end
  local expected=(pending and pending.Meta and pending.Meta.MatchID) or (if minimumMatch>0 then minimumMatch else nil) or (replica.Meta and replica.Meta.MatchID)
  if typeof(packet)=="table" and packet.MatchID and expected and packet.MatchID~=expected then
   return packet.MatchID<expected,nil
  end
  if typeof(packet)~="table" or typeof(packet.Tick)~="number" or packet.Tick%1~=0 or packet.Tick<0
   or typeof(packet.Changes)~="buffer" or buffer.len(packet.Changes)%6~=0 then return false end
  if packet.Parts and (typeof(packet.Parts)~="number" or packet.Parts%1~=0 or packet.Parts<1 or packet.Parts>32768
   or typeof(packet.Part)~="number" or packet.Part%1~=0 or packet.Part<1 or packet.Part>packet.Parts) then return false end
  if packet.BuildingChanges and (typeof(packet.BuildingChanges)~="buffer" or buffer.len(packet.BuildingChanges)%24~=0) then return false end
  if packet.ShipChanges and (typeof(packet.ShipChanges)~="buffer" or buffer.len(packet.ShipChanges)%32~=0) then return false end
		if packet.Parts and packet.Parts>1 then
			if packet.Part==1 then fragments={Tick=packet.Tick,Parts=packet.Parts,Next=1,Buffers={},Bytes=0,BuildingBuffers={},BuildingBytes=0,ShipBuffers={},ShipBytes=0} end
			if not fragments or fragments.Tick~=packet.Tick or fragments.Parts~=packet.Parts or fragments.Next~=packet.Part then fragments=nil;return false end
			if typeof(packet.Changes)~="buffer" or buffer.len(packet.Changes)%6~=0 then fragments=nil;return false end
			fragments.Bytes+=buffer.len(packet.Changes)
			if fragments.Bytes>terrain.Width*terrain.Height*6 then fragments=nil;return false end
			table.insert(fragments.Buffers,packet.Changes);fragments.Next+=1
            if packet.ShipChanges then
                if typeof(packet.ShipChanges)~="buffer" or buffer.len(packet.ShipChanges)%32~=0 then fragments=nil;return false end
                fragments.ShipBytes+=buffer.len(packet.ShipChanges);if fragments.ShipBytes>terrain.Width*terrain.Height*32 then fragments=nil;return false end
                table.insert(fragments.ShipBuffers,packet.ShipChanges)
            end
            if packet.BuildingChanges then
                if typeof(packet.BuildingChanges)~="buffer" or buffer.len(packet.BuildingChanges)%24~=0 then fragments=nil;return false end
                fragments.BuildingBytes+=buffer.len(packet.BuildingChanges)
                if fragments.BuildingBytes>terrain.Width*terrain.Height*24 then fragments=nil;return false end
                table.insert(fragments.BuildingBuffers,packet.BuildingChanges)
            end
			if packet.Part<packet.Parts then return true,nil end
			local packed=buffer.create(fragments.Bytes);local offset=0
			for _,b in ipairs(fragments.Buffers) do buffer.copy(packed,offset,b);offset+=buffer.len(b) end
            local buildings=buffer.create(fragments.BuildingBytes);local bo=0
            for _,b in ipairs(fragments.BuildingBuffers) do buffer.copy(buildings,bo,b);bo+=buffer.len(b) end
			local ships=buffer.create(fragments.ShipBytes);local so=0
            for _,b in ipairs(fragments.ShipBuffers) do buffer.copy(ships,so,b);so+=buffer.len(b) end
			packet={SpawnChanges=packet.SpawnChanges,MatchID=packet.MatchID,ShipChanges=ships,Tick=packet.Tick,Changes=packed,Meta=packet.Meta,BuildingChanges=buildings};fragments=nil
		end
		if pending then
			if packet.Tick>pending.Tick then
    pending.QueueBytes+=buffer.len(packet.Changes)+(if packet.BuildingChanges then buffer.len(packet.BuildingChanges) else 0)+(if packet.ShipChanges then buffer.len(packet.ShipChanges) else 0)
    -- Bound catch-up memory as well as tick count; request a fresh snapshot on overflow.
    if #pending.Queue>=2048 or pending.QueueBytes>16*1024*1024 then pending=nil; return false end
				table.insert(pending.Queue,packet)
			end
			return true,packet
		end
		return apply(packet),packet
	end
	function replica.finish(message)
		if not pending or pending.ID~=message.ID or pending.Received~=pending.Count then pending=nil; return false end
		local staging=pending; pending=nil
		local previousGrid,previousTick,previousMeta,previousBuildings,previousShips=replica.Grid,replica.Tick,replica.Meta,replica.Buildings,replica.Ships
		replica.Grid,replica.Tick,replica.Meta=staging.Grid,staging.Tick,staging.Meta
  minimumMatch=math.max(minimumMatch,if staging.Meta then staging.Meta.MatchID or 0 else 0)
        replica.Buildings=staging.Buildings;replica.Ships=staging.Ships
        if replica.Meta and replica.Meta.Stage and replica.Meta.Stage>=6 then replica.Meta.Ships=ShipWire.list(replica.Ships) end
        if replica.Meta and replica.Meta.Stage and replica.Meta.Stage>=5 then replica.Meta.Buildings=Wire.list(replica.Buildings) end
		for _,packet in ipairs(staging.Queue) do
			if not apply(packet) then replica.Grid,replica.Tick,replica.Meta,replica.Buildings,replica.Ships=previousGrid,previousTick,previousMeta,previousBuildings,previousShips; return false end
		end
		return true
	end
	function replica.reset(matchID)pending=nil;fragments=nil;if matchID then minimumMatch=math.max(minimumMatch,matchID) end end
	function replica.loading(): boolean return pending~=nil end
	return replica
end
return Replica
