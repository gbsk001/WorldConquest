"""OPT-IN heavy Earth simulation runner. Not invoked by the functional gate.

Only run after the owner authorises resource-intensive benchmarks. No Studio or
live service access. Each population gets its own process to avoid retained heaps.
"""
from pathlib import Path
import argparse, subprocess, json
r=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--allow-heavy',action='store_true')
parser.add_argument('--basic',nargs='+',type=int,default=[100,200,300,400,500])
parser.add_argument('--ticks',type=int,default=18000)
parser.add_argument('--seed',type=int,default=150027)
args=parser.parse_args()
if not args.allow_heavy:parser.error('Deferred: run only after authorisation, with --allow-heavy.')
assert all(0<=n<=500 for n in args.basic) and 1<=args.ticks<=102000
ns={'__file__':str(r/'scripts/check_stage1.py')}
exec((r/'scripts/check_stage1.py').read_text().split("h+='local Oracle='")[0],ns)
config='local Color3={fromRGB=function(...)return {...}end}\n'+ns['factory']('Config','src/shared/Config.luau',{})
for count in args.basic:
 code=ns['h']+config+f'\nlocal BASIC={count};local TICKS={args.ticks};local SEED={args.seed}\n'+(r/'scripts/stage15_load.luau').read_text()
 target=r/f'build/stage15-load-{count}.luau';target.write_text(code,encoding='utf-8')
 with (r/f'build/stage15-load-{count}.txt').open('w',encoding='utf-8')as log:
  result=subprocess.run([str(r/'build/luau/luau.exe'),str(target)],stdout=log,stderr=subprocess.STDOUT)
 print(f'Population {count}+20: exit {result.returncode}; see build/stage15-load-{count}.txt',flush=True)
 if result.returncode:raise SystemExit(result.returncode)
