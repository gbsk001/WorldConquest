"""Isolated 20/50/100-player salvo CPU/heap/logical payload benchmark, no Roblox."""
from pathlib import Path
import subprocess,json,sys
ROOT=Path(__file__).resolve().parents[1]
baseline='--baseline' in sys.argv
earth='--earth' in sys.argv
repeats=int(sys.argv[sys.argv.index('--repeats')+1]) if '--repeats' in sys.argv else 1
assert 1<=repeats<=10
if baseline:
    prefix=(ROOT/'build/stage8-baseline-checks.luau').read_text().split('\nlocal Oracle8=')[0]
else:
    ns={'__file__':str(ROOT/'scripts/check_stage1.py')}
    exec((ROOT/'scripts/check_stage1.py').read_text().split("h+='local Oracle='")[0],ns);prefix=ns['h']
label=('earth-' if earth else '')+('before' if baseline else 'after');rows=[]
for n in [20,50,100]:
    p=ROOT/f'build/stage8-bench-{label}-{n}.luau'
    p.write_text(prefix+f'\nlocal PLAYERS={n}\nlocal EARTH={str(earth).lower()}\n'+(ROOT/'scripts/stage8_benchmark.luau').read_text())
    keys=['players','average_ms','p95_ms','worst_ms','heap_start_kib','heap_peak_kib','heap_end_kib','logical_bytes_total','logical_bytes_peak_tick','grid_bytes','impacts','digest','encoded_bytes_total','encoded_bytes_peak_tick','encode_average_ms','with_encoding_average_ms','with_encoding_p95_ms','with_encoding_worst_ms']
    samples=[]
    for trial in range(repeats):
        r=subprocess.run([str(ROOT/'build/luau/luau.exe'),str(p)],capture_output=True,text=True)
        print(r.stdout+r.stderr,flush=True)
        if r.returncode:raise SystemExit(r.returncode)
        values=next(line for line in r.stdout.splitlines() if line.startswith('BENCH ')).split()[1:]
        samples.append(dict(zip(keys,map(float,values))))
    for sample in samples[1:]:
        for key in ['digest','logical_bytes_total','logical_bytes_peak_tick','encoded_bytes_total','encoded_bytes_peak_tick','impacts','grid_bytes']:
            assert sample[key]==samples[0][key],(key,samples)
    row=dict(samples[0]);row['samples']=samples;row['repeats']=repeats
    for key in ['average_ms','heap_start_kib','heap_end_kib','encode_average_ms','with_encoding_average_ms']:
        row[key]=sum(sample[key] for sample in samples)/repeats
    for key in ['p95_ms','worst_ms','heap_peak_kib','with_encoding_p95_ms','with_encoding_worst_ms']:
        row[key]=max(sample[key] for sample in samples)
    rows.append(row)
(ROOT/f'build/stage8-benchmark-{label}.json').write_text(json.dumps(rows,indent=2))
before=ROOT/('build/stage8-benchmark-'+('earth-' if earth else '')+'before.json')
if not baseline and before.exists():
    old=json.loads(before.read_text())
    for a,b in zip(old,rows):
        for key in ['players','digest','impacts','logical_bytes_total','logical_bytes_peak_tick','grid_bytes']:
            assert a[key]==b[key],(key,a,b)
    print('Before/after identical grid state, ordered borders/territory, troops, impact ticks and logical payload sizes.')
