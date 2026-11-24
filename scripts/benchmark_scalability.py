"""Fresh-process actual Earth bot workloads; simulated, no Roblox transport/GPU."""
from pathlib import Path
import subprocess,json,sys
r=Path(__file__).resolve().parents[1]
ns={'__file__':str(r/'scripts/check_stage1.py')}
loader=(r/'scripts/check_stage1.py').read_text().split("h+='local Oracle='")[0]
if len(sys.argv)>1 and sys.argv[1].startswith('before'):
 loader=loader.replace("return (ROOT/path).read_text(encoding='utf-8-sig')","return ((ROOT/'build/scalability-baseline'/path) if (ROOT/'build/scalability-baseline'/path).exists() else (ROOT/path)).read_text(encoding='utf-8-sig')")
exec(loader,ns)
label=sys.argv[1] if len(sys.argv)>1 else 'after'
rows=[]
for n in [50,100,200,250,500]:
 for repeat in [1]:
  code=ns['h'].replace('api.SearchMilliseconds+=(os.clock()-began)*1000;return found', 'local elapsed=(os.clock()-began)*1000;if elapsed>100 then print("SLOW_ROUTE", starts[1],goal,elapsed,api.Pops,found and #found or -1)end;api.SearchMilliseconds+=elapsed;return found')+f'\nlocal COUNT={n}\n'+(r/'scripts/stage11_benchmark.luau').read_text().replace('600','1800').replace('times[570]','times[1710]')
  path=r/f'build/scalability-{label}-{n}.luau';path.write_text(code,encoding='utf-8')
  run=subprocess.run([str(r/'build/luau/luau.exe'),str(path)],capture_output=True,text=True)
  print(run.stdout+run.stderr,flush=True)
  if run.returncode:raise SystemExit(run.returncode)
  values=next(x for x in run.stdout.splitlines() if x.startswith('EARTH_BOTS ')).split()[1:]
  keys=['bots','average_ms','p95_ms','worst_ms','ai_worst_ms','startup_worst_ms','heap_start_kib','heap_peak_kib','heap_end_kib','raw_bytes','peak_bytes','decisions','orders','digest','metadata_estimate_bytes','selection_p95_ms','selected_before_start']
  row=dict(zip(keys,map(float,values)));row['repeat']=repeat;row['components_ms']={line.split()[2]:float(line.split()[3]) for line in run.stdout.splitlines() if line.startswith('COMPONENT')};rows.append(row)
  if repeat==2:
   for key in ['raw_bytes','peak_bytes','decisions','orders','digest','metadata_estimate_bytes','selection_p95_ms','selected_before_start']:assert rows[-1][key]==rows[-2][key],key
(r/('build/scalability-'+(sys.argv[1] if len(sys.argv)>1 else 'after')+'.json')).write_text(json.dumps(rows,indent=2))
