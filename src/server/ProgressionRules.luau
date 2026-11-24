--!strict
-- Original server-only, retry-safe profile transformations. AGPL-3.0.
local Catalog=require(game:GetService("ReplicatedStorage").Shared.ProgressionCatalog)
local Rules={}
function Rules.new()
 return {Version=1,Revision=0,Stars=0,Owned={flag_horizon=true},Equipped={Flag="flag_horizon"},Achievements={},Daily={Day=-1,Streak=0},Stats={Wins=0,Matches=0,Territory=0,HumanEliminations=0,BestStreak=0,Soldiers=0,Streak=0},Matches={},Receipts={},Entitlements={}}
end
function Rules.copy(old)
 if old==nil then return Rules.new()end
 assert(old.Version==1,"Unsupported profile schema; refusing to overwrite data")
 local function clone(v)if type(v)~="table"then return v end;local out={};for k,x in pairs(v)do out[k]=clone(x)end;return out end
 return clone(old)
end
local function credit(p,n)p.Stars=math.min(1000000000,p.Stars+n)end
function Rules.apply(p,action,data,now)
 if action=="Ranked"then
  if data~=p.StatsRevision then return false,"Newer records still need indexing."end
  p.RankingDirty=false
 elseif action=="Nation"then
  p.NationName=if data==""then nil else data
 elseif action=="Buy"then
  local item=Catalog.ByID[data];if not item or item.Price==nil then return false,"This item cannot be bought with Stars."end
  if p.Owned[data]then return false,"Already owned."end
  if p.Stars<item.Price then return false,"Not enough Stars."end
  p.Stars-=item.Price;p.Owned[data]=true
 elseif action=="Equip"then
  local item=Catalog.ByID[data];if not item or not p.Owned[data]then return false,"You do not own that item."end
  p.Equipped[item.Category]=data
 elseif action=="Unequip"then
  if not table.find(Catalog.Categories,data)then return false,"Unknown category."end;p.Equipped[data]=nil
 elseif action=="Daily"then
  local day=math.floor(now/86400);if day<=p.Daily.Day then return false,"Today's reward is already claimed."end
  p.Daily.Streak=if p.Daily.Day==day-1 then p.Daily.Streak%7+1 else 1;p.Daily.Day=day
  credit(p,Catalog.Daily[p.Daily.Streak]);if p.Daily.Streak==7 then p.Owned.badge_week=true end
 elseif action=="Match"then
  -- Only called by the authoritative observer, never by a client request.
  if not data.Eligible or data.Time>now+60 or data.Time<now-86400 or p.Matches[data.ID]then return false,"Ineligible or already rewarded."end
  for id,t in pairs(p.Matches)do if t<now-86400 then p.Matches[id]=nil end end
  p.Matches[data.ID]=data.Time
  p.StatsRevision=(p.StatsRevision or 0)+1;p.RankingDirty=true
  local s=p.Stats;s.Matches+=1;if data.Won then s.Wins+=1;s.Streak+=1 else s.Streak=0 end
  s.BestStreak=math.max(s.BestStreak,s.Streak);s.Territory=math.max(s.Territory,data.Territory);s.Soldiers=math.max(s.Soldiers,math.floor(data.Soldiers));s.HumanEliminations+=data.HumanEliminations or 0;s.Ships=math.max(s.Ships or 0,data.Ships or 0)
  credit(p,Catalog.Rewards.Completion+(if data.Won then Catalog.Rewards.Victory else 0))
  for _,a in ipairs(Catalog.Achievements)do if not p.Achievements[a.ID]and (s[a.Metric]or 0)>=a.Target then
   p.Achievements[a.ID]=now;credit(p,Catalog.Rewards.Achievement);if a.Item then p.Owned[a.Item]=true end
  end end
 elseif action=="Entitlement"then
  if p.Entitlements[data.Key]then return false,"Already granted."end
  p.Entitlements[data.Key]=true;for _,id in ipairs(data.Items)do assert(Catalog.ByID[id]);p.Owned[id]=true end;credit(p,data.Stars or 0)
 elseif action=="Receipt"then
  if p.Receipts[data.ID]then return false,"Already granted."end
  local count=0;for _ in pairs(p.Receipts)do count+=1 end
  -- Do not prune purchase IDs: a late receipt retry must never grant twice.
  assert(count<8000,"Receipt ledger requires migration; purchase deferred")
  p.Receipts[data.ID]=true;credit(p,data.Stars)
 else return false,"Unknown operation."end
 p.Revision+=1;return true,"Saved."
end
return Rules
