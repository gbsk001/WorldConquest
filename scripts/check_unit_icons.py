from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
h=(r/'scripts/strategy_ui_checks.luau').read_text()
for name,path in [('Art','src/client/InterfaceArt.luau'),('Layer','src/client/IconLayer.luau')]:h+='\nlocal '+name+'=(function()\n'+(r/path).read_text()+'\nend)()\n'
h+=(r/'scripts/unit_icon_checks.luau').read_text()
p=r/'build/unit-icon-checks.luau';p.write_text(h,encoding='utf-8')
subprocess.run([str(r/'build/luau/luau.exe'),str(p)],check=True)
