"""Production Luau + pinned JS parity; simulated services, never Studio."""
from pathlib import Path
import json,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
ns={'__file__':str(ROOT/'scripts/check_stage1.py')}
exec((ROOT/'scripts/check_stage1.py').read_text().split("h+='local Oracle='")[0],ns)
h=ns['h']+'\nlocal Oracle8='+ns['literal'](json.loads((ROOT/'tests/stage8/upstream-oracle.json').read_text()))+'\n'
checks=(ROOT/'scripts/missile_checks.luau').read_text()
if '--quick' in sys.argv: checks=checks.split('-- Determinism and mixed missile stress;')[0]
h+=checks
h+='\nlocal function runFoundation(game,script,require,Instance,Color3,os,debug)\n'+(ROOT/'src/server/OpenFront/FoundationServer.luau').read_text().split('return function(session)',1)[1].rsplit('end',1)[0]+'\nend\ndo\n'
h+=(ROOT/'scripts/stage8_server_checks.luau').read_text()+'\nend\n'
p=ROOT/'build/stage8-checks.luau';p.write_text(h)
r=subprocess.run([str(ROOT/'build/luau/luau.exe'),str(p)],capture_output=True,text=True)
(ROOT/'build/stage8-results.txt').write_text(r.stdout+r.stderr);print(r.stdout+r.stderr);raise SystemExit(r.returncode)
