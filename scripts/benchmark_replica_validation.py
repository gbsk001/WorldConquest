"""Identical client delta workload before/after; interpreted CPU, no FPS claim."""
from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
ns={'__file__':str(r/'scripts/check_stage1.py')}
exec((r/'scripts/check_stage1.py').read_text().split("h+='local Oracle='")[0],ns)
source=(r/'build/scalability-baseline/src/shared/OpenFront/Replica.luau').read_text()
for name,value in [('Grid','Grid'),('Wire','BuildingWire'),('ShipWire','ShipWire')]:
 line=next(x for x in source.splitlines()if x.startswith('local '+name+' = require('))
 source=source.replace(line,'local '+name+' = '+value)
h=ns['h']+'\nlocal Before=(function()\n'+source+'\nend)()\n'+'''
local refs={}
for y=1450,1550 do for x=4000,4500 do
 local ref=y*8192+x;if bit32.band(EarthTerrain.byte(ref),128)~=0 then table.insert(refs,ref)end
 if #refs==8192 then break end
end;if #refs==8192 then break end end
assert(#refs==8192)
for _,entry in ipairs({{'before',Before},{'after',Replica}})do
 local replica=entry[2].new(EarthTerrain);local samples={};local sum=0
 for tick=0,100 do
  local packed=buffer.create(#refs*6)
  for i,ref in ipairs(refs)do buffer.writeu32(packed,(i-1)*6,ref);buffer.writeu16(packed,(i-1)*6+4,tick%2+1)end
  local began=os.clock();assert(replica.delta({Tick=tick,Changes=packed}));local elapsed=(os.clock()-began)*1000
  if tick>0 then samples[#samples+1]=elapsed;sum+=elapsed end
 end
 assert(replica.Grid.Counts[1]==8192 and replica.Grid.Counts[2]==0)
 table.sort(samples);print('REPLICA',entry[1],sum/#samples,samples[95],samples[100],replica.Tick)
end
'''
p=r/'build/replica-validation-benchmark.luau';p.write_text(h)
run=subprocess.run([str(r/'build/luau/luau.exe'),str(p)],capture_output=True,text=True)
(r/'build/replica-validation-benchmark.txt').write_text(run.stdout+run.stderr)
print(run.stdout+run.stderr);raise SystemExit(run.returncode)
