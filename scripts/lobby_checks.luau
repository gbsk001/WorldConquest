local Enum={SortDirection={Descending=1}}
local function clone(v)if typeof(v)~="table"then return v end;local out={};for k,x in pairs(v)do out[k]=clone(x)end;return out end
local clock=0;local serial=0
local function guid()serial+=1;return string.format("%08x-0000-4000-8000-%012x",serial,serial)end
local function memory()
 local data={};local api={Fail=false}
 function api:GetAsync(k)assert(not self.Fail,"storage unavailable");local v=data[k];return if v and v.End>clock then clone(v.Value)else nil end
 function api:SetAsync(k,v,ttl,sort)assert(not self.Fail);data[k]={Value=clone(v),End=clock+ttl,Sort=sort or 0};return true end
 function api:UpdateAsync(k,fn,ttl)local v=fn(self:GetAsync(k));if v~=nil then self:SetAsync(k,v,ttl)end;return clone(v)end
 function api:RemoveAsync(k)data[k]=nil end
 function api:GetRangeAsync(_,count)local out={};for k in pairs(data)do local v=self:GetAsync(k);if v then table.insert(out,{key=k,value=v})end end;table.sort(out,function(a,b)return a.key<b.key end);while #out>count do table.remove(out)end;return out end
 return api
end
