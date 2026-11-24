"""Build and verify the Stage 9 Rojo candidate without publishing."""
from pathlib import Path
import subprocess,xml.etree.ElementTree as ET,hashlib,json
r=Path(__file__).resolve().parents[1]
artifact=r/'build/WorldConquest-stage9.rbxlx'
subprocess.run([str(Path.home()/'.aftman/bin/rojo.exe'),'build',str(r/'default.project.json'),'--output',str(artifact)],check=True,cwd=r)
embedded=[e.text or '' for e in ET.parse(artifact).findall('.//Properties/*') if e.attrib.get('name')=='Source']
files={}
for p in sorted((r/'src').rglob('*.luau')):
 assert p.read_text(encoding='utf-8-sig') in embedded,p
 files[p.relative_to(r).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
assert 'PortStage = 9,' in (r/'src/shared/Config.luau').read_text(encoding='utf-8')
result={'stage':9,'artifact':artifact.relative_to(r).as_posix(),'sha256':hashlib.sha256(artifact.read_bytes()).hexdigest(),'files':files,'studio_tested':False,'published':False}
(r/'build/stage9-build-manifest.json').write_text(json.dumps(result,indent=2))
print(f'Verified {len(files)} current Luau sources in Stage 9 build. No Studio/live testing or publication.')
