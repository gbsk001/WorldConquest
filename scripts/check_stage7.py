"""Stage 7 production-module stress/recovery checks; simulated players, NOT Studio.

--baseline loads the saved pre-change src under build/stage7-baseline.
--memory runs the isolated packed-grid memory workload instead of match stress.
"""
from pathlib import Path
import subprocess, sys, json, re
ROOT=Path(__file__).resolve().parents[1]
namespace={'__file__':str(ROOT/'scripts/check_stage1.py')}
loader=(ROOT/'scripts/check_stage1.py').read_text().split("h+='local Oracle='")[0]
if '--baseline' in sys.argv:
    loader='\n'.join(line for line in loader.splitlines() if not line.startswith("h+=factory('BotRules'") and not line.startswith("h+=factory('Bots'"))
    loader=loader.replace(",'Bots':'Bots'",'')
    loader=loader.replace("return (ROOT/path).read_text(encoding='utf-8-sig')", "return (ROOT/('build/stage7-baseline/'+path if path.startswith('src/') else path)).read_text(encoding='utf-8-sig')")
exec(loader,namespace)
code=namespace['h']
if '--memory' in sys.argv:
    code+=(ROOT/'scripts/stage7_memory_checks.luau').read_text()
else:
    code+='\nlocal BASELINE='+('true' if '--baseline' in sys.argv else 'false')+'\n'
    code+=(ROOT/'scripts/stage7_checks.luau').read_text()
    if '--baseline' not in sys.argv:
        code+=namespace['factory']('IconLayer','src/client/IconLayer.luau',{})
        code+=(ROOT/'scripts/stage7_recovery_checks.luau').read_text()
        code+='\nlocal function runFoundation(game,script,require,Instance,Color3,os,debug)\n'+(ROOT/'src/server/OpenFront/FoundationServer.luau').read_text().split('return function(session)',1)[1].rsplit('end',1)[0]+'\nend\ndo\n'
        code+=(ROOT/'scripts/stage7_server_checks.luau').read_text()+'\nend\n'
label='stage7-'+('memory' if '--memory' in sys.argv else 'before' if '--baseline' in sys.argv else 'after')
path=ROOT/('build/'+label+'.luau');path.write_text(code)
result=subprocess.run([str(ROOT/'build/luau/luau.exe'),str(path)],capture_output=True,text=True)
(ROOT/('build/'+label+'-results.txt')).write_text(result.stdout+result.stderr)
print(result.stdout+result.stderr)
if result.returncode==0 and '--memory' not in sys.argv:
    actual={n:int(h) for n,h in re.findall(r'DIGEST (\d+) (\d+)',result.stdout)}
    expected=json.loads((ROOT/'tests/stage7/baseline-digests.json').read_text())
    assert actual==expected, 'Deterministic match output differs from the pre-Stage-7 source'
    print('All five match digests match the saved pre-Stage-7 baseline.')
raise SystemExit(result.returncode)
