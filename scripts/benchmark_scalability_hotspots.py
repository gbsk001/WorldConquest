"""Compare saved pre-change sources with current exact path/salvo workloads."""
from pathlib import Path
import subprocess,json
r=Path(__file__).resolve().parents[1]
results={}
for label in ['before','after']:
 ns={'__file__':str(r/'scripts/check_stage1.py')}
 loader=(r/'scripts/check_stage1.py').read_text().split("h+='local Oracle='")[0]
 if label=='before':
  loader=loader.replace("return (ROOT/path).read_text(encoding='utf-8-sig')","return ((ROOT/'build/scalability-baseline'/path) if (ROOT/'build/scalability-baseline'/path).exists() else (ROOT/path)).read_text(encoding='utf-8-sig')")
 exec(loader,ns)
 workloads={'paths': '''
EarthTerrain.configureCache(8192)
local grid=Grid.new(8192,4096,EarthTerrain.byte)
local path=WaterPath.new(grid,EarthTerrain)
for _,pair in ipairs({{30427171,31393958},{30533944,31393958},{30427171,31287487},{5488371,3849972}})do
 local began=os.clock();local route=path.raw({pair[1]},pair[2]);local ms=(os.clock()-began)*1000
 local hash=0;if route then for _,t in ipairs(route)do hash=(hash*31+t)%4294967296 end end
 print('PATH',pair[1],pair[2],ms,route and #route or -1,hash,gcinfo())
end
'''}
 for n in [50,100]:
  workloads['salvo'+str(n)]=f'local PLAYERS={n}\nlocal EARTH=true\n'+(r/'scripts/stage8_benchmark.luau').read_text()
  workloads['flat'+str(n)]=f'local PLAYERS={n}\nlocal EARTH=false\n'+(r/'scripts/stage8_benchmark.luau').read_text()
 results[label]={}
 for name,body in workloads.items():
  p=r/f'build/scalability-{label}-{name}.luau';p.write_text(ns['h']+'\n'+body)
  run=subprocess.run([str(r/'build/luau/luau.exe'),str(p)],capture_output=True,text=True)
  print(label,name,run.stdout,run.stderr,flush=True)
  if run.returncode:raise SystemExit(run.returncode)
  results[label][name]=run.stdout
  (r/'build/scalability-hotspots.json').write_text(json.dumps(results,indent=2))
before=results['before']['paths'].splitlines();after=results['after']['paths'].splitlines()
for a,b in zip(before,after):
 assert a.split()[1:3]+a.split()[4:6]==b.split()[1:3]+b.split()[4:6],(a,b)
for name in ['salvo50','salvo100','flat50','flat100']:
 a=next(x for x in results['before'][name].splitlines()if x.startswith('BENCH ')).split()
 b=next(x for x in results['after'][name].splitlines()if x.startswith('BENCH ')).split()
 for i in [1,8,9,10,11,12]:assert a[i]==b[i],(name,i,a,b)
print('Exact route hashes, salvo state hashes, impact timing and raw payload parity passed.')
