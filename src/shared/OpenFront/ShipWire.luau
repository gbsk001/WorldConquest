--!strict
-- Roblox incremental unit wire adapter. No client-authoritative ship state.
local Wire={Size=32,Types={"TransportShip","Warship","TradeShip","Shell","AtomBomb","HydrogenBomb","MIRV","MIRVWarhead","SAMMissile"}}
function Wire.pack(list)
 local b=buffer.create(#list*32)
 for i,u in ipairs(list) do local o=(i-1)*32
  buffer.writeu32(b,o,u.ID);buffer.writeu32(b,o+4,u.Tile);buffer.writeu16(b,o+8,u.Owner)
  buffer.writeu8(b,o+10,assert(table.find(Wire.Types,u.Type)));buffer.writeu8(b,o+11,u.Flags or 0)
  buffer.writeu16(b,o+12,u.Health or 1);buffer.writeu8(b,o+14,u.Veterancy or 0);buffer.writeu16(b,o+16,u.Progress or 0)
  buffer.writeu32(b,o+20,u.TargetTile or 0xffffffff);buffer.writef64(b,o+24,u.Troops or 0)
 end;return b
end
function Wire.read(b,size)
 if typeof(b)~="buffer" or buffer.len(b)%32~=0 then return nil end
 local list={}
 for o=0,buffer.len(b)-1,32 do
  local id,tile,owner,kind=buffer.readu32(b,o),buffer.readu32(b,o+4),buffer.readu16(b,o+8),Wire.Types[buffer.readu8(b,o+10)]
  local target,troops=buffer.readu32(b,o+20),buffer.readf64(b,o+24)
  if id==0 or tile>=size or owner>4095 or not kind or (target~=0xffffffff and target>=size) or troops~=troops or troops<0 or troops==math.huge then return nil end
  table.insert(list,{ID=id,Tile=tile,Owner=owner,Type=kind,Flags=buffer.readu8(b,o+11),Health=buffer.readu16(b,o+12),Veterancy=buffer.readu8(b,o+14),Progress=buffer.readu16(b,o+16),TargetTile=if target==0xffffffff then nil else target,Troops=troops})
 end;return list
end
function Wire.apply(units,list)for _,u in ipairs(list) do units[u.ID]=if u.Owner==0 then nil else u end end
function Wire.list(units)local list={};for _,u in pairs(units) do table.insert(list,u) end;table.sort(list,function(a,b)return a.ID<b.ID end);return list end
return Wire
