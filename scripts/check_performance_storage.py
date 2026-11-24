from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
old=(r/'scripts/ordered_set_reference.luau').read_text()
new=(r/'src/server/OpenFront/OrderedSet.luau').read_text()
h='local Old=(function()\n'+old+'\nend)()\nlocal New=(function()\n'+new+'\nend)()\n'
h+=(r/'scripts/performance_storage_checks.luau').read_text()
p=r/'build/performance-storage-checks.luau';p.write_text(h)
subprocess.run([str(r/'build/luau/luau.exe'),str(p)],check=True)
