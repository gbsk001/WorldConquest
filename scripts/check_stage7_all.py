"""Run every implemented gameplay regression plus Stage 7 stress/recovery/memory.

Sequential execution avoids contaminating benchmark timings with parallel suites.
These are standalone Luau/service-stub checks, not Studio or live-client tests.
"""
from pathlib import Path
import subprocess, sys
root=Path(__file__).resolve().parents[1]
for name,args in [('check_stage5',[]),('check_stage6',[]),('check_luau',[]),
                  ('check_stage7',[]),('check_stage7',['--memory'])]:
    print('Running '+name+' '+' '.join(args),flush=True)
    result=subprocess.run([sys.executable,str(root/'scripts'/f'{name}.py'),*args],cwd=root,capture_output=True,text=True)
    label=name+('-memory' if args else '')
    (root/'build'/f'{label}-stage7-final.txt').write_text(result.stdout+result.stderr)
    print(result.stdout+result.stderr,flush=True)
    if result.returncode: raise SystemExit(result.returncode)
print('All implemented Stage 1-6 regressions and Stage 7 checks passed. Studio acceptance remains pending.')
