from pathlib import Path
import subprocess,sys,json
r=Path(__file__).resolve().parents[1]
ns={'__file__':str(r/'scripts/check_stage1.py')}
exec((r/'scripts/check_stage1.py').read_text().split("h+='local Oracle='")[0],ns)
seeds=int(sys.argv[1])if len(sys.argv)>1 else 100
p=r/'build/spawn-distribution-checks.luau';p.write_text(ns['h']+f'\nlocal SEEDS={seeds}\n'+(r/'scripts/spawn_distribution_checks.luau').read_text())
run=subprocess.run([str(r/'build/luau/luau.exe'),str(p)],capture_output=True,text=True)
(r/f'build/spawn-distribution-{seeds}.txt').write_text(run.stdout+run.stderr)
rows=[]
for line in run.stdout.splitlines():
 if line.startswith('DISTRIBUTION'):
  v=line.split();keys=['minimum_km','mean_nearest_km','max_10degree_bin','average_tick_ms','p95_tick_ms','worst_tick_ms','candidate_attempts','digest','heap_kib','selection_ticks','reconsiderations']
  rows.append(dict(participants=int(v[1]),seed=int(v[2]),regions=list(map(int,v[3].split(','))),**dict(zip(keys,map(float,v[4:])))))
(r/f'build/spawn-distribution-{seeds}.json').write_text(json.dumps(rows,indent=2))
print('\n'.join(run.stdout.splitlines()[-10:]));print(run.stderr);raise SystemExit(run.returncode)
