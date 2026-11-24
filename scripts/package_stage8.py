"""Build a reviewable Rojo candidate and verify embedded sources; no publishing."""
from pathlib import Path
import subprocess,xml.etree.ElementTree as ET,hashlib,json
root=Path(__file__).resolve().parents[1]
rojo=Path.home()/'.aftman/bin/rojo.exe'
output=root/'build/WorldConquest-stage8.rbxlx'
subprocess.run([str(rojo),'build',str(root/'default.project.json'),'--output',str(output)],check=True,cwd=root)
tree=ET.parse(output);embedded=[]
for item in tree.findall('.//Item'):
    props=item.find('Properties')
    if props is None:continue
    src=props.find("*[@name='Source']")
    if src is not None:embedded.append(src.text or '')
files={}
for p in sorted((root/'src').rglob('*.luau')):
    source=p.read_text(encoding='utf-8-sig')
    assert source in embedded, f'Rojo artifact missing current source: {p}'
    files[p.relative_to(root).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
assert 'PortStage = 8,' in (root/'src/shared/Config.luau').read_text()
manifest={'stage':8,'source_files_verified':len(files),'artifact':'build/WorldConquest-stage8.rbxlx','sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'files':files,'studio_tested':False,'published':False}
(root/'build/stage8-build-manifest.json').write_text(json.dumps(manifest,indent=2))
print(f'Verified {len(files)} current Luau sources in Stage 8 artifact; SHA-256 {manifest["sha256"]}. No Studio/live test or publication performed.')
