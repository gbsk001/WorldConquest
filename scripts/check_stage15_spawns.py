"""Small geography-only checks, not the deferred large-population gameplay test."""
from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
ns={'__file__':str(r/'scripts/check_stage1.py')}
exec((r/'scripts/check_stage1.py').read_text().split("h+='local Oracle='")[0],ns)
target=r/'build/stage15-spawn-only.luau';target.write_text(ns['h']+(r/'scripts/stage15_spawn_checks.luau').read_text(),encoding='utf-8')
run=subprocess.run([str(r/'build/luau/luau.exe'),str(target)],capture_output=True,text=True)
(r/'build/stage15-spawn-only.txt').write_text(run.stdout+run.stderr,encoding='utf-8')
print(run.stdout+run.stderr);raise SystemExit(run.returncode)
