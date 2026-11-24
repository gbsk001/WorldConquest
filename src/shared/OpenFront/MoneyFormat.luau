--!strict
-- Format.ts renderNumber, default precision; OpenFront 8f1a0add, AGPL-3.0.
local Format={}
function Format.money(gold)
 local n=math.max(tonumber(gold) or 0,0)
 if n==math.huge then return "very large" end -- display only; balance stays exact
 if n>=1e10 then return string.format("%.1fB",math.floor(n/1e8)/10)
 elseif n>=1e9 then return string.format("%.2fB",math.floor(n/1e7)/100)
 elseif n>=1e7 then return string.format("%.1fM",math.floor(n/1e5)/10)
 elseif n>=1e6 then return string.format("%.2fM",math.floor(n/1e4)/100)
 elseif n>=1e5 then return string.format("%.0fK",math.floor(n/1e3))
 elseif n>=1e4 then return string.format("%.1fK",math.floor(n/100)/10)
 elseif n>=1e3 then return string.format("%.2fK",math.floor(n/10)/100)
 else return tostring(math.floor(n)) end
end
return Format
