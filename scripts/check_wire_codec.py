"""Lossless transport checks, including escape boundaries and malformed input."""
from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
h='local Grid=(function()\n'+(r/'src/shared/OpenFront/Grid.luau').read_text()+'\nend)()\n'
h+='''
local seed=12345
local function rand()seed=(seed*1664525+1013904223)%4294967296;return seed end
for trial=1,500 do
 local count=trial*7%2048;local raw=buffer.create(count*6);local ref=rand()%33554432
 for i=0,count-1 do
  if trial%3==0 then ref=rand()%33554432 else ref=(ref+(if i%7==0 then 8192 else 1))%33554432 end
  buffer.writeu32(raw,i*6,ref);buffer.writeu16(raw,i*6+4,if trial%2==0 then 8192 else rand()%65536)
 end
 local packed,state,encoding=Grid.compressWire(raw)
 local decoded=Grid.expandWire(packed,state,33554432,encoding)
 assert(decoded and buffer.tostring(decoded)==buffer.tostring(raw),'ordered round trip '..trial)
 assert(buffer.len(packed)<=buffer.len(raw))
end
assert(not Grid.expandWire(buffer.create(3),0,33554432,1))
assert(not Grid.expandWire(buffer.create(4),65536,33554432,1))
assert(not Grid.expandWire(buffer.create(4),nil,33554432,1))
assert(not Grid.expandWire(buffer.create(4),0,33554432,2))
local escape=buffer.create(6);buffer.writei16(escape,4,-32768)
assert(not Grid.expandWire(escape,0,33554432,1))
print('Wire codec: 500 exact ordered round trips, mixed/uniform/escaped/scattered records and malformed packets passed.')
'''
p=r/'build/wire-codec-checks.luau';p.write_text(h)
subprocess.run([str(r/'build/luau/luau.exe'),str(p)],check=True)
