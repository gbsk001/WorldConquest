from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
ns={'__file__':str(r/'scripts/check_stage1.py')}
exec((r/'scripts/check_stage1.py').read_text().split("h+='local Oracle='")[0],ns)
h=ns['h']+(r/'scripts/stage11_checks.luau').read_text()
p=r/'build/stage11-checks.luau';p.write_text(h,encoding='utf-8')
subprocess.run([str(r/'build/luau/luau.exe'),str(p)],check=True)
