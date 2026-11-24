--!strict
-- Exactly two match types. All client projections deliberately omit routing secrets.
local State={}
function State.new(record,now)
 assert(record.Kind=="Public" or record.Kind=="Private")
 local api={Record=record,Members={},Phase="Lobby",Deadline=nil,Host=record.Host,BotNames={}}
 function api.add(p)
  if api.Phase=="Closed" then return false end
  api.Members[p.UserId]=p
  if record.Kind=="Public" and not api.Deadline then api.Deadline=now()+15 end
  return true
 end
 function api.remove(id)
  api.Members[id]=nil
  if api.Host==id then
   local ids={};for user in pairs(api.Members) do table.insert(ids,user) end;table.sort(ids);api.Host=ids[1]
  end
  if not next(api.Members) then api.Phase="Closed";api.Deadline=nil end
 end
 function api.start(user)
  if api.Phase~="Lobby" or not next(api.Members) then return false end
  if record.Kind=="Private" and user~=api.Host then return false end
  if record.Kind=="Public" and (not api.Deadline or now()<api.Deadline) then return false end
  api.Phase="Game";return true
 end
 function api.project(user)
  local record=api.Record
  local people={};for id,p in pairs(api.Members) do table.insert(people,{UserId=id,Name=p.DisplayName or p.Name,NationName=if p.GetAttribute then p:GetAttribute("WCNationName")else nil,Host=id==api.Host}) end
  table.sort(people,function(a,b)return a.UserId<b.UserId end)
  local bots=if record.Kind=="Public" then (if record.PublicTarget then math.max(0,record.PublicTarget-#people)else math.min(5,20-#people)) else record.Bots
  local used={};for _,p in pairs(api.Members) do used[string.lower(p.Name)]=true;used[string.lower(p.DisplayName or p.Name)]=true end
  for _,name in ipairs(api.BotNames) do used[string.lower(name)]=true end
  local first={"xShadow","FrostByte","LunarFox","Maximus","NovaStorm","AlexPro","DarkKnight","SilentWolf","PixelPilot","JustJay","Mango","Noodle","GGSam","Ace","Rookie","Sky","Echo","BlueJay","Captain","Zed","SilverFox","Luna","Kai","Cyber","Toast","Orbit","Riley","Lucky","Zero","Blitz","Ninja","Quest"}
  local last={"","27","X","77","_GG","99","Plays","_YT","Pro","42","Live","101","TV","9","Rush","One"}
  local seed=record.Seed or 17;if not record.Seed then for i=1,#record.ID do seed=(seed*31+string.byte(record.ID,i))%10000019 end end
  for i=#api.BotNames+1,bots do
   local n=(seed+i*137)%512;local base=first[n%32+1]..last[math.floor(n/32)+1];local name=base;local suffix=1
   while used[string.lower(name)] do suffix+=1;name=base..suffix end
   api.BotNames[i]=name;used[string.lower(name)]=true
  end
  local names={};for i=1,bots do names[i]=api.BotNames[i] end
  return {Capacity=record.Capacity or 20,MatchSeed=record.Seed,BotNames=names,Screen=if api.Phase=="Game" then "Game" else "Lobby",MatchType=record.Kind,Players=people,Bots=bots,Difficulty=if record.Kind=="Public" then "Normal" else record.Difficulty,Host=user==api.Host,Countdown=if api.Deadline then math.max(0,math.ceil(api.Deadline-now())) else nil,Code=if record.Kind=="Private" and api.Members[user] then record.Code else nil,InviteSession=if record.Kind=="Public" then record.ID else nil}
 end
 return api
end
return State
