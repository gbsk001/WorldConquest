from pathlib import Path
import subprocess,json,sys
ROOT=Path(__file__).resolve().parents[1]
# Reuse the exact production module loader, without running previous suites twice.
namespace={'__file__':str(ROOT/'scripts/check_stage1.py')}
s=(ROOT/'scripts/check_stage1.py').read_text();exec(s.split("h+='local Oracle='")[0],namespace)
h=namespace['h']+'\nlocal NavalOracle='+namespace['literal'](json.loads((ROOT/'tests/stage6/upstream-oracle.json').read_text()))+'\n'
checks=(ROOT/'scripts/naval_checks.luau').read_text()
if '--quick' in sys.argv:
 for start,end in [('-- Earth routing:', '-- Water components prevent'),('-- Adversarial core-search cost','-- Actual neutral beachhead')]:
  a=checks.index(start);b=checks.index(end,a);checks=checks[:a]+checks[b:]
h+=checks
h+='\nlocal function runFoundation(game,script,require,Instance,Color3,os,debug)\n'+(ROOT/'src/server/OpenFront/FoundationServer.luau').read_text().split('return function(session)',1)[1].rsplit('end',1)[0]+'\nend\ndo\n'+(ROOT/'scripts/naval_server_checks.luau').read_text()+'\nend\n'
(ROOT/'build/stage6-checks.luau').write_text(h)
r=subprocess.run([str(ROOT/'build/luau/luau.exe'),str(ROOT/'build/stage6-checks.luau')],text=True,capture_output=True)
(ROOT/'build/stage6-results.txt').write_text(r.stdout+r.stderr);print(r.stdout+r.stderr);raise SystemExit(r.returncode)
