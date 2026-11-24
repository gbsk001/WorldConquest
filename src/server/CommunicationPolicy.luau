--!strict
-- Restricts native audio; never substitutes for Roblox's own communication gates.
local Policy={}
function Policy.allowed(source,target,sourceGroups,targetGroups,sourceScope,targetScope)
 if source==target or sourceScope~=targetScope or type(sourceGroups)~="table"or type(targetGroups)~="table"then return false end
 for _,a in ipairs(sourceGroups)do if type(a)=="string"then for _,b in ipairs(targetGroups)do if a==b then return true end end end end
 return false
end
return Policy
