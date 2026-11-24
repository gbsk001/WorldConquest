--!strict
-- Unicode validation before Roblox filtering. Never a replacement for moderation.
local Names={}
function Names.validate(value)
 if type(value)~="string"or #value>128 then return nil end
 local length=utf8.len(value);if not length or length<2 or length>32 then return nil end
 local parts={};local visible=0
 for _,code in utf8.codes(value)do
  if code<32 or code>=127 and code<=159 or code==0x200B or code==0xFEFF or code>=0x2028 and code<=0x202E or code>=0x2060 and code<=0x206F or code==60 or code==62 or code==35 then return nil end
  if code==0xA0 or code>=0x2000 and code<=0x200A or code==0x202F or code==0x205F or code==0x3000 then code=32 end
  if code~=32 and code~=0x200C and code~=0x200D then visible+=1 end
  table.insert(parts,utf8.char(code))
 end
 local text=table.concat(parts):gsub(" +"," "):gsub("^ +",""):gsub(" +$","")
 local lower=string.lower(text)
 if visible<2 or string.find(lower,"https?://")or string.find(lower,"www%.")then return nil end
 return text
end
function Names.filter(value,user,service)
 local clean=Names.validate(value);if not clean then return nil,"Use 2–32 readable characters without links or formatting controls."end
 local ok,filtered=pcall(function()
  local result=service:FilterStringAsync(clean,user,Enum.TextFilterContext.PublicChat)
  return result:GetNonChatStringForBroadcastAsync()
 end)
 if not ok or type(filtered)~="string"then return nil,"Roblox could not filter this name. Please retry."end
 if not Names.validate(filtered)then return nil,"Choose a different nation name."end
 return filtered
end
return Names
