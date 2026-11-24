"""Fresh-process actual Earth bot workloads; simulated, no Roblox transport/GPU."""
from pathlib import Path
import subprocess,json
r=Path(__file__).resolve().parents[1]
ns={'__file__':str(r/'scripts/check_stage1.py')}
exec((r/'scripts/check_stage1.py').read_text().split("h+='local Oracle='")[0],ns)
rows=[]
for n in [20,100,200,250,300,500]:
 for repeat in [1]:
  code=ns['h']+f'\nlocal COUNT={n}\n'+(r/'scripts/stage11_benchmark.luau').read_text()
  path=r/f'build/stage11-benchmark-{n}.luau';path.write_text(code,encoding='utf-8')
  run=subprocess.run([str(r/'build/luau/luau.exe'),str(path)],capture_output=True,text=True)
  print(run.stdout+run.stderr,flush=True)
  if run.returncode:raise SystemExit(run.returncode)
  values=next(x for x in run.stdout.splitlines() if x.startswith('EARTH_BOTS ')).split()[1:]
  keys=['bots','average_ms','p95_ms','worst_ms','ai_worst_ms','startup_worst_ms','heap_start_kib','heap_peak_kib','heap_end_kib','raw_bytes','peak_bytes','decisions','orders','digest','metadata_estimate_bytes','selection_p95_ms','selected_before_start']
  row=dict(zip(keys,map(float,values)));row['repeat']=repeat;row['components_ms']={line.split()[2]:float(line.split()[3]) for line in run.stdout.splitlines() if line.startswith('COMPONENT')};rows.append(row)
  if repeat==2:
   for key in ['raw_bytes','peak_bytes','decisions','orders','digest','metadata_estimate_bytes','selection_p95_ms','selected_before_start']:assert rows[-1][key]==rows[-2][key],key
(r/'build/stage11-earth-benchmarks.json').write_text(json.dumps(rows,indent=2))
