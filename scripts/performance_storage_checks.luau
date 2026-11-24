local a,b=Old.new(),New.new()
local seed=123
local function random(n)seed=(seed*1664525+1013904223)%4294967296;return seed%n end
local function compare()
 assert(a.Size==b.Size)
 local x,y={},{};a.each(function(t)table.insert(x,t)end);b.each(function(t)table.insert(y,t)end)
 assert(#x==#y);for i,v in ipairs(x)do assert(y[i]==v,"ordered set traversal drift")end
 local cursor=random(30000)+1
 local xs,xc=a.sample(cursor,64);local ys,yc=b.sample(cursor,64);assert(xc==yc and #xs==#ys)
 for i,v in ipairs(xs)do assert(ys[i]==v)end
end
for i=1,100000 do
 local v=random(33554432)
 if i%3==0 then a.delete(v);b.delete(v)else a.add(v);b.add(v)end
 if i%1000==0 then compare()end
end
for i=0,1000 do a.add(i);b.add(i)end
for i=0,1000 do a.delete(i);b.delete(i)end
compare()
a.clear();b.clear();a.add(0);b.add(0)
a.each(function(v)if v<20 then a.add(v+1);a.delete(v)end end)
b.each(function(v)if v<20 then b.add(v+1);b.delete(v)end end)
compare();assert(a.Size==1)
a.clear();b.clear()
for i=0,2047 do a.add(i);b.add(i)end
for i=0,1535 do a.delete(i);b.delete(i)end
compare() -- forces compaction with more tombstones than live entries
for i=0,511 do a.add(i);b.add(i)end
compare()
print("Packed ordered sets: 100000 operations, exact order/cursors, zero tile, clear and append/delete during traversal passed.")
local batch={0,0,1,300,512,2000,33554431,33554431}
for _,v in ipairs(batch)do a.delete(v)end;b.deleteMany(batch);compare()
print("Bulk removal preserves duplicates, missing values, tombstones and cursor order.")
