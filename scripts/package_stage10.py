"""Build the Stage 10 Rojo candidate and verify every embedded production source."""
from pathlib import Path
import subprocess,xml.etree.ElementTree as ET,hashlib,json
r=Path(__file__).resolve().parents[1];artifact=r/'build/WorldConquest-stage10.rbxlx'
artifact.parent.mkdir(parents=True,exist_ok=True)
subprocess.run([str(Path.home()/'.aftman/bin/rojo.exe'),'build',str(r/'default.project.json'),'--output',str(artifact)],check=True,cwd=r)
embedded=[e.text or '' for e in ET.parse(artifact).findall('.//Properties/*')if e.attrib.get('name')=='Source']
files={}
for p in sorted((r/'src').rglob('*.luau')):
 assert p.read_text(encoding='utf-8-sig')in embedded,p
 files[p.relative_to(r).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
assert 'PortStage = 11,'in(r/'src/shared/Config.luau').read_text(encoding='utf-8')
preview_path=r/'build/studio-gui-icons-preview-2026-11-24.json'
if not preview_path.exists():preview_path=r/'build/studio-spawn-preview-2026-11-24.json'
if not preview_path.exists():preview_path=r/'build/studio-performance-preview-2026-11-24.json'
if not preview_path.exists():preview_path=r/'build/studio-performance-preview-2026-11-23.json'
if not preview_path.exists():preview_path=r/'build/studio-gui-update-preview-2026-11-23.json'
preview=json.loads(preview_path.read_text()) if preview_path.exists() else {}
preview_matches=preview.get('files')==files
manifest={'stage':13,'simulation_stage':11,'stage12_implemented':True,'stage12_live_verified':False,'artifact':artifact.relative_to(r).as_posix(),'sha256':hashlib.sha256(artifact.read_bytes()).hexdigest(),'files':files,'studio_full_acceptance':False,'studio_render_preview':preview.get('scope') if preview_matches else None,'live_services_tested':False,'published':False}
(r/'build/stage10-build-manifest.json').write_text(json.dumps(manifest,indent=2))
print(f'Verified {len(files)} current sources in Stage 10 candidate. No live testing or publication.')
