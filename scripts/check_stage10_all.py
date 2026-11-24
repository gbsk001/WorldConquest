"""Sequential Stage 1-11 functional regressions; no live-services certification."""
from pathlib import Path
import subprocess,sys
r=Path(__file__).resolve().parents[1]
for name in ['check_stage8_all','check_stage9','check_strategy_ui','check_stage10','check_stage10_ui','check_map_labels','check_unit_icons','check_private_profile','check_stage11','check_performance_storage','check_wire_codec','check_stage12','check_stage13']:
 print('Running '+name,flush=True)
 result=subprocess.run([sys.executable,str(r/'scripts'/f'{name}.py')],cwd=r,capture_output=True,text=True)
 output=result.stdout+result.stderr;(r/'build'/f'{name}-stage10-final.txt').write_text(output)
 print('\n'.join(output.splitlines()[-14:]),flush=True)
 if result.returncode:raise SystemExit(result.returncode)
subprocess.run([sys.executable,str(r/'scripts/check_mobile.py')],cwd=r,check=True)
print('Running balanced Earth spawn regression (two seeds per population)',flush=True)
subprocess.run([sys.executable,str(r/'scripts/check_spawn_distribution.py'),'2'],cwd=r,check=True)
print('All Stage 1-13 automated functional regressions passed. Native multiplayer/live acceptance remains pending.')
