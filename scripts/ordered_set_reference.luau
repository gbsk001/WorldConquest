--!strict
-- TileSet insertion/deletion/re-add iteration semantics; Roblox table storage adaptation.
-- Copyright OpenFront and Contributors; AGPL-3.0, see LICENSE/NOTICE.
local Set={}
function Set.new()
 local slots,index={},{};local deleted=0
 local set={Size=0}
 function set.clear() slots,index={},{};deleted=0;set.Size=0 end
 function set.add(v) if index[v] then return end;table.insert(slots,v);index[v]=#slots;set.Size+=1 end
 function set.delete(v)
  local i=index[v];if not i then return end
  slots[i]=false;index[v]=nil;set.Size-=1;deleted+=1
 end
 function set.deleteMany(values)
  local removed=0
  for _,v in ipairs(values) do local i=index[v];if i then slots[i]=false;index[v]=nil;removed+=1 end end
  set.Size-=removed;deleted+=removed
 end
 -- Bounded deterministic cursor for AI. Tombstones count against the work budget.
 function set.sample(cursor,limit)
  local values={};local total=#slots
  if total==0 then return values,1 end
  cursor=math.clamp(cursor or 1,1,total)
  for _=1,math.min(limit,total) do
   local value=slots[cursor];if value~=false then table.insert(values,value) end
   cursor=cursor%total+1
  end
  return values,cursor
 end
 function set.each(fn)
  -- This use only mutates between traversals; compact without changing live order.
  if deleted>set.Size and deleted>64 then
   local dense={};for _,v in ipairs(slots) do if v~=false then table.insert(dense,v);index[v]=#dense end end
   slots=dense;deleted=0
  end
  local i=1;while i<=#slots do local v=slots[i];if v~=false and fn(v)==false then return end;i+=1 end
 end
 return set
end
return Set
