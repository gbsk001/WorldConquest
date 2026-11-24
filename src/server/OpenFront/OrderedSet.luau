--!native
--!strict
-- TileSet insertion/deletion/re-add iteration semantics; packed storage adaptation.
-- Copyright OpenFront and Contributors; AGPL-3.0, see LICENSE/NOTICE.
local Set={}
function Set.new()
 local slots=buffer.create(1024);local capacity=256;local length=0
 local index={};local deleted=0;local set={Size=0}
 local function pageFor(v,create)
  local key=bit32.rshift(v,8);local page=index[key]
  if not page and create then page=buffer.create(1024);index[key]=page end
  return page,bit32.band(v,255)*4
 end
 function set.clear()slots=buffer.create(1024);capacity=256;length=0;index={};deleted=0;set.Size=0 end
 function set.add(v)
  local page,offset=pageFor(v,true)
  if buffer.readu32(page,offset)~=0 then return end
  if length==capacity then local larger=buffer.create(capacity*8);buffer.copy(larger,0,slots);slots=larger;capacity*=2 end
  buffer.writeu32(slots,length*4,v+1);length+=1;buffer.writeu32(page,offset,length);set.Size+=1
 end
 function set.delete(v)
  local page,offset=pageFor(v,false);if not page then return end
  local i=buffer.readu32(page,offset);if i==0 then return end
  buffer.writeu32(slots,(i-1)*4,0);buffer.writeu32(page,offset,0);set.Size-=1;deleted+=1
 end
 function set.deleteMany(values)
  local removed=0
  for _,v in ipairs(values)do
   local page=index[bit32.rshift(v,8)]
   if page then
    local offset=bit32.band(v,255)*4;local position=buffer.readu32(page,offset)
    if position~=0 then
     buffer.writeu32(slots,(position-1)*4,0);buffer.writeu32(page,offset,0);removed+=1
    end
   end
  end
  set.Size-=removed;deleted+=removed
 end
 function set.sample(cursor,limit)
  local values={};if length==0 then return values,1 end
  cursor=math.clamp(cursor or 1,1,length)
  for _=1,math.min(limit,length)do
   local value=buffer.readu32(slots,(cursor-1)*4);if value~=0 then table.insert(values,value-1)end
   cursor=cursor%length+1
  end
  return values,cursor
 end
 function set.each(fn)
  if deleted>set.Size and deleted>64 then
   local n=0
   for i=0,length-1 do local value=buffer.readu32(slots,i*4);if value~=0 then
    buffer.writeu32(slots,n*4,value);n+=1;local page,offset=pageFor(value-1,false);buffer.writeu32(page,offset,n)
   end end
   length=n;deleted=0
  end
  -- Preserve live append/delete traversal semantics and exact insertion order.
  local i=0;while i<length do local value=buffer.readu32(slots,i*4);if value~=0 and fn(value-1)==false then return end;i+=1 end
 end
 return set
end
return Set
