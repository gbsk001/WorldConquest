"""Isolated worst-case upstream A* limit on the production-sized grid (no Studio)."""
from pathlib import Path
import subprocess,sys
root=Path(__file__).resolve().parents[1]
code='local Path=(function()\n'+(root/'src/server/OpenFront/RailPath.luau').read_text()+'\nend)()\n'
code+='local Grid=(function()\n'+(root/'src/shared/OpenFront/Grid.luau').read_text()+'\nend)()\n'
code+='''
local w,h=8192,4096
local g=Grid.new(w,h,function(t)
 local x=t%w
 local water=x>=4093 and x<=4099
 local shore=x==4092 or x==4093 or x==4099 or x==4100
 return (if water then 32 else 128)+(if shore then 64 else 0)
end)
local before=gcinfo();local began=os.clock()
local result=Path.land(g,2048*w+4050,2048*w+4140,RAIL_LENGTH_GATE)
assert(not result)
print(string.format("Adversarial 8192x4096 rail route across an impassable ocean strip: %.3f ms, heap before %.0f / after %.0f KiB. Production length gate unless --raw was specified.",(os.clock()-began)*1000,before,gcinfo()))
'''
code=code.replace('RAIL_LENGTH_GATE','nil' if '--raw' in sys.argv else '110*1.4142')
out=root/'build/rail-limit.luau';out.write_text(code)
result=subprocess.run([str(root/'build/luau/luau.exe'),str(out)],text=True,capture_output=True)
(root/'build/rail-limit-results.txt').write_text(result.stdout+result.stderr)
print(result.stdout+result.stderr);raise SystemExit(result.returncode)
