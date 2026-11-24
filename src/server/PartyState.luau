--!strict
-- Original, transient parties. No friendship database, maximum six humans.
local State={}
function State.new()
 local api={Parties={},Membership={}}
 function api.create(id,user)
  if api.Membership[user]then return api.Parties[api.Membership[user]]end
  local p={ID=id,Leader=user,Members={user}};api.Parties[id]=p;api.Membership[user]=id;return p
 end
 function api.add(id,user)
  local p=api.Parties[id];if not p or api.Membership[user]or #p.Members>=6 or p.Queued then return false end
  table.insert(p.Members,user);api.Membership[user]=id;return true
 end
 function api.remove(user,actor,disconnect)
  local id=api.Membership[user];local p=id and api.Parties[id]
  if not p or p.Queued and not disconnect or (actor~=user and actor~=p.Leader)then return false end
  table.remove(p.Members,table.find(p.Members,user));api.Membership[user]=nil
  if #p.Members==0 then api.Parties[id]=nil elseif p.Leader==user then p.Leader=p.Members[1]end;return true
 end
 return api
end
return State
