--!strict
-- Original WorldConquest transient matchmaking. No persistent friendship database.
local Store={}
function Store.new(records,codes,directory,now,guid,population)
 local api={}
 local capacity=if population then math.clamp(math.floor(population.SafeParticipants or 20),2,math.min(500,population.MaximumParticipants or 500))else 20
 local function members(r)
  local count=0;for _,m in pairs(r.Members) do if m.Expires>now() then count+=1 end end;return count
 end
 function api.create(kind,host,name,job,reserved,place)
  assert(kind=="Public" or kind=="Private")
  local id=guid();local code=if kind=="Private" then string.upper(string.gsub(guid(),"%-","")) else nil
  local r={ID=id,Kind=kind,Host=host,Job=job,Reserved=reserved,Place=place,Code=code,Phase="Lobby",Bots=5,Difficulty="Normal",Capacity=capacity,Members={},Lease=now()+45}
  if population then
   local seed=23;for i=1,#id do seed=(seed*31+string.byte(id,i))%2147483647 end
   r.Seed=seed;r.PublicTarget=math.min(capacity,population.PublicTarget or 250)
  end
  records:SetAsync(id,r,120);if code then codes:SetAsync(code,id,120) end
  return r
 end
 function api.get(id)return records:GetAsync(id)end
 function api.code(code)
  if typeof(code)~="string" or #code~=32 or not string.match(code,"^[%x]+$") then return nil end
  local id=codes:GetAsync(string.upper(code));return if id then api.get(id) else nil
 end
 function api.claim(id,user,name,kind)
  local token=guid();local result=records:UpdateAsync(id,function(r)
   if not r or r.Kind~=kind or r.Phase~="Lobby" then return nil end
   local key=tostring(user);local old=r.Members[key]
   if old and old.Expires>now() then return nil end
   local maximum=if kind=="Private" then r.Capacity-r.Bots else r.Capacity
   if members(r)>=maximum then return nil end
   r.Members[key]={Name=name,Token=token,Expires=now()+90,Connected=false};return r
  end,120)
  if not result or not result.Members[tostring(user)] or result.Members[tostring(user)].Token~=token then return nil end
  return result,token
 end
 function api.admit(id,user,token,job,reserved)
  return records:UpdateAsync(id,function(r)
   local m=r and r.Members[tostring(user)]
   if not m or m.Token~=token or m.Expires<=now() or r.Phase=="Closed" then return nil end
   if r.Reserved~="" then
    if r.Reserved~=reserved then return nil end
    if r.Job~="" and r.Job~=job and r.Lease>now() then return nil end
    r.Job=job
   elseif r.Kind~="Public" or reserved~="" or r.Job~=job then return nil end
   m.Connected=true;m.Expires=now()+120;r.Lease=now()+45;return r
  end,120)
 end
 function api.claimGroup(id,people)
  if #people<1 or #people>6 then return nil end
  local tokens={};local group=guid();for _,p in ipairs(people)do if tokens[tostring(p.UserId)]then return nil end;tokens[tostring(p.UserId)]=guid()end
  local result=records:UpdateAsync(id,function(r)
   if not r or r.Kind~="Public"or r.Phase~="Lobby"or members(r)+#people>r.Capacity then return nil end
   for _,p in ipairs(people)do local m=r.Members[tostring(p.UserId)];if m and m.Expires>now()then return nil end end
   for _,p in ipairs(people)do r.Members[tostring(p.UserId)]={Name=p.Name,Token=tokens[tostring(p.UserId)],Expires=now()+90,Connected=false,Party=group,PartyLeader=people[1].UserId}end
   return r
  end,120)
  if not result then return nil end
  for _,p in ipairs(people)do local m=result.Members[tostring(p.UserId)];if not m or m.Token~=tokens[tostring(p.UserId)]then return nil end end
  return result,tokens
 end
 function api.release(id,user,reconnect)
  return records:UpdateAsync(id,function(r)
   if not r then return nil end
   local key=tostring(user);local m=r.Members[key]
   if m and reconnect then m.Connected=false;m.Expires=now()+60 else r.Members[key]=nil end
   return r
  end,120)
 end
 function api.settings(id,user,count,difficulty)
  if typeof(count)~="number" or count%1~=0 or count<0 or count>capacity-1 or not table.find({"Easy","Normal","Hard"},difficulty) then return nil end
  return records:UpdateAsync(id,function(r)
   if not r or r.Kind~="Private" or r.Phase~="Lobby" or r.Host~=user or members(r)+count>r.Capacity then return nil end
   r.Bots=count;r.Difficulty=difficulty;return r
  end,120)
 end
 function api.publish(id,job,phase,host,present)
  local r=records:UpdateAsync(id,function(value)
   if not value or value.Job~=job then return nil end
    -- Commit the roster only after all live human reservations have arrived.
    -- This runs inside UpdateAsync, so a concurrent claim cannot lose to AI fill.
    if phase=="Game" and value.Phase=="Lobby" and value.Kind=="Public" then
     for key,m in pairs(value.Members)do
      if m.Expires>now() and not present[tonumber(key)] then return nil end
     end
    end
   value.Phase=phase;value.Host=host;value.Lease=now()+45
   for key,m in pairs(value.Members) do
    if present[tonumber(key)] then m.Connected=true;m.Expires=now()+120 elseif m.Expires<=now() then value.Members[key]=nil end
   end
   return value
  end,120)
  if r then
   if r.Code and phase~="Closed" then codes:SetAsync(r.Code,id,120) end
   if r.Kind=="Public" then
    if phase=="Lobby" then directory:SetAsync(job,{ID=id,Kind="Public",Place=r.Place,Job=job,Count=members(r),Capacity=r.Capacity,Expires=now()+30},40,members(r))
    else directory:RemoveAsync(job) end
   end
  end
  return r
 end
 function api.public(job,place)
  local r=directory:GetAsync(job)
  return if r and r.Kind=="Public" and r.Place==place and r.Expires>now() and r.Count<(r.Capacity or 20) then r else nil
 end
 function api.find(place)
  local list=directory:GetRangeAsync(Enum.SortDirection.Descending,20);local result={}
  for _,entry in ipairs(list) do local r=entry.value;if r.Kind=="Public" and r.Place==place and r.Expires>now() and r.Count<(r.Capacity or 20) then table.insert(result,r) end end
  return result
 end
 return api
end
return Store
