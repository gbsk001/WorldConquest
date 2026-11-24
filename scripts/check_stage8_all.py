"""Full Stage 1-8 gate, sequential timings. Does not run Roblox Studio."""
from pathlib import Path
import subprocess,sys
root=Path(__file__).resolve().parents[1]
for name,args in [('check_stage5',[]),('check_stage6',[]),('check_luau',[]),('check_stage7',[]),('check_stage7',['--memory']),('check_stage8',[])]:
    print('Running '+name+' '+' '.join(args),flush=True)
    r=subprocess.run([sys.executable,str(root/'scripts'/f'{name}.py'),*args],cwd=root,text=True,capture_output=True)
    label=name+('-memory' if args else '')
    (root/'build'/f'{label}-stage8-final.txt').write_text(r.stdout+r.stderr)
    print(r.stdout+r.stderr,flush=True)
    if r.returncode:raise SystemExit(r.returncode)
print('All Stage 1-8 automated checks passed. Performance gates and Studio acceptance are separate; see the Stage 8 report.')
