--!strict
-- Atomic UpdateAsync; cached data is never written back as a whole profile.
local Rules=require(script.Parent.ProgressionRules)
local Store={}
function Store.new(dataStore,now)
 local api={Cache={}};local busy={};local detached={}
 function api.transact(user,action,data)
  if busy[user]then return nil,"A save is in progress. Try again."end
  if action==nil then detached[user]=nil end
  busy[user]=true;local message="Loaded."
  local ok,result=pcall(function()return dataStore:UpdateAsync("u"..user,function(old)
   local p=Rules.copy(old)
   if action then local _,m=Rules.apply(p,action,data,now());message=m end
   return p
  end)end);busy[user]=nil
  if not ok then return nil,"Saving is unavailable. Nothing was acknowledged; please retry."end
  if not detached[user]then api.Cache[user]=result end;return result,message
 end
 function api.forget(user)detached[user]=true;api.Cache[user]=nil end
 return api
end
return Store
