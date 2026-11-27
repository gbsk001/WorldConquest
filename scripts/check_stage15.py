"""Small Stage 15 functional fixtures; no load benchmarks, Studio or GPU claims."""
from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1]
ns={'__file__':str(root/'scripts/check_stage1.py')}
exec((root/'scripts/check_stage1.py').read_text().split("h+='local Oracle='")[0],ns)
naval=(root/'scripts/naval_checks.luau').read_text()
helpers=naval[naval.index('local function makeMap('):naval.index('for _,v in ipairs(NavalOracle.rates)')]
helpers+=naval[naval.index('local function environment('):naval.index('for _,v in ipairs(NavalOracle.veterans)')]
helpers=helpers.replace('{Stage=6,Economy=', '{Stage=6,Balance={BoundedPaths=true,InfrastructurePresentation=true},Economy=')
code=ns['h']+(root/'scripts/stage15_checks.luau').read_text()+'\ndo\n'+helpers+(root/'scripts/stage15_infrastructure_checks.luau').read_text()+'\nend\n'
path=root/'build/stage15-functional.luau';path.write_text(code,encoding='utf-8')
run=subprocess.run([str(root/'build/luau/luau.exe'),str(path)],capture_output=True,text=True)
(root/'build/stage15-functional.txt').write_text(run.stdout+run.stderr,encoding='utf-8')
print(run.stdout+run.stderr);raise SystemExit(run.returncode)
