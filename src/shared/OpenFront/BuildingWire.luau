--!strict
-- Roblox transport adapter: 24 bytes per changed building, no per-tick full registry.
local Wire={Bytes=24,Types={"City","DefensePost","Factory","Port","MissileSilo","SAMLauncher"}}
function Wire.pack(list)
 local b=buffer.create(#list*24)
 for i,u in ipairs(list) do
  local o=(i-1)*24
  buffer.writeu32(b,o,u.ID);buffer.writeu32(b,o+4,u.Tile);buffer.writeu16(b,o+8,u.Owner or 0)
  buffer.writeu32(b,o+10,u.Level);buffer.writeu8(b,o+14,table.find(Wire.Types,u.Type))
  buffer.writeu8(b,o+15,if u.UnderConstruction then 1 else 0)
  buffer.writeu32(b,o+16,u.CompleteTick or 0);buffer.writeu32(b,o+20,u.DeleteAt or 4294967295)
 end
 return b
end
function Wire.read(b,size)
 if typeof(b)~="buffer" or buffer.len(b)%24~=0 then return nil end
 local result={}
 for o=0,buffer.len(b)-1,24 do
  local id,tile,owner=buffer.readu32(b,o),buffer.readu32(b,o+4),buffer.readu16(b,o+8)
  local kind=Wire.Types[buffer.readu8(b,o+14)];local level=buffer.readu32(b,o+10)
  if id==0 or tile>=size or owner>4095 or not kind or level==0 then return nil end
  local deleteAt=buffer.readu32(b,o+20)
  table.insert(result,{ID=id,Tile=tile,Owner=owner,Type=kind,Level=level,UnderConstruction=buffer.readu8(b,o+15)==1,CompleteTick=buffer.readu32(b,o+16),DeleteAt=if deleteAt==4294967295 then nil else deleteAt})
 end
 return result
end
function Wire.apply(units,list)for _,u in ipairs(list) do units[u.ID]=if u.Owner==0 then nil else u end end
function Wire.list(units)
 local result={};for _,u in pairs(units) do table.insert(result,u) end;table.sort(result,function(a,b)return a.ID<b.ID end);return result
end
return Wire
