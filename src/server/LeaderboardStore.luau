--!strict
-- Repairable, monotonic projections of authoritative profile statistics.
local Catalog=require(game:GetService("ReplicatedStorage").Shared.ProgressionCatalog)
local Writer={}
function Writer.new(data,prefix,profiles)
 local api={};local busy={}
 function api.flush(user,profile)
  if busy[user]or not profile or not profile.RankingDirty then return false end
  busy[user]=true
  local ok=pcall(function()
   for _,metric in ipairs(Catalog.Metrics)do
    data:GetOrderedDataStore(prefix.."_"..metric):UpdateAsync(tostring(user),function(old)return math.max(old or 0,profile.Stats[metric])end)
   end
  end)
  if ok then local saved=profiles.transact(user,"Ranked",profile.StatsRevision);ok=saved~=nil end
  busy[user]=nil;return ok
 end
 return api
end
return Writer
