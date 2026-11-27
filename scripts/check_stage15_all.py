"""Sequential functional regression gate. Heavy load and rendered tests excluded.

Run under scripts/run_idle.py to inherit one logical CPU and below-normal priority.
The full benchmark suites remain available without --quick, after authorisation.
"""
from pathlib import Path
import subprocess, sys
r=Path(__file__).resolve().parents[1]
checks=[('check_luau','--quick'),('check_stage5','--quick'),('check_stage6','--quick'),
 ('check_stage7','--quick'),('check_stage8','--quick'),('check_stage9','--quick'),
 ('check_strategy_ui',),('check_stage10',),('check_stage10_ui',),('check_map_labels',),
 ('check_unit_icons',),('check_private_profile',),('check_stage11',),('check_wire_codec',),
 ('check_stage12',),('check_stage13',),('check_mobile',),('check_stage14','--quick'),('check_stage15',)]
if '--from' in sys.argv:
 start=sys.argv[sys.argv.index('--from')+1];checks=checks[next(i for i,c in enumerate(checks)if c[0]==start):]
for name,*args in checks:
 print('Running '+name+' '+' '.join(args),flush=True)
 run=subprocess.run([sys.executable,str(r/'scripts'/f'{name}.py'),*args],cwd=r,capture_output=True,text=True)
 output=run.stdout+run.stderr
 (r/'build'/f'{name}-stage15-acceptance.txt').write_text(output,encoding='utf-8')
 print('\n'.join(output.splitlines()[-8:]),flush=True)
 if run.returncode:raise SystemExit(run.returncode)
print('Stage 1–15 functional gate passed. Load, GPU, Studio and physical-device acceptance deferred.')
