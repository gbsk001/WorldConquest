--!strict
-- Exact unsigned integer storage for upstream Gold (BigInt). Decimal strings on wire.
-- Roblox adapter, 2026-11-18. AGPL-3.0; see LICENSE/NOTICE.
local Gold={}
function Gold.valid(v) return typeof(v)=="string" and (v=="0" or string.match(v,"^[1-9][0-9]*$")~=nil) end
function Gold.from(v)
 if typeof(v)=="number" then assert(v>=0 and v<math.huge and v%1==0);return string.format("%.0f",v) end
 assert(Gold.valid(v));return v
end
function Gold.compare(a,b)
 if #a~=#b then return if #a<#b then -1 else 1 end
 return if a==b then 0 elseif a<b then -1 else 1
end
function Gold.add(a,b)
 local out={};local carry=0;local n=math.max(#a,#b)
 for offset=0,n-1 do
  local i,j=#a-offset,#b-offset
  local v=(if i>0 then string.byte(a,i)-48 else 0)+(if j>0 then string.byte(b,j)-48 else 0)+carry
  out[n-offset]=string.char(48+v%10);carry=math.floor(v/10)
 end
 return (if carry>0 then "1" else "")..table.concat(out)
end
function Gold.subtract(a,b)
 assert(Gold.compare(a,b)>=0);local out={};local borrow=0
 for offset=0,#a-1 do
  local i,j=#a-offset,#b-offset;local v=string.byte(a,i)-48-borrow-(if j>0 then string.byte(b,j)-48 else 0)
  if v<0 then v+=10;borrow=1 else borrow=0 end;out[i]=string.char(v+48)
 end
 local result=string.gsub(table.concat(out),"^0+","");return if result=="" then "0" else result
end
function Gold.half(a)
 local out={};local carry=0
 for i=1,#a do local v=carry*10+string.byte(a,i)-48;out[i]=string.char(48+math.floor(v/2));carry=v%2 end
 local result=string.gsub(table.concat(out),"^0+","");return if result=="" then "0" else result
end
return Gold
