"""Build an isolated extraction of the prepared ZIP; never upload or publish."""
from pathlib import Path, PurePosixPath
import hashlib, json, subprocess, zipfile, xml.etree.ElementTree as ET

root=Path(__file__).resolve().parents[1]
package=json.loads((root/'build/source-package.json').read_text())
archive=root/package['archive']
assert hashlib.sha256(archive.read_bytes()).hexdigest()==package['sha256']
target=root/'build'/('source-check-'+package['sha256'][:12])
target.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(archive) as z:
    for item in z.infolist():
        name=PurePosixPath(item.filename)
        assert not name.is_absolute() and '..' not in name.parts and '\\' not in item.filename
        assert (target/item.filename).resolve().is_relative_to(target.resolve())
    z.extractall(target)
manifest=json.loads((target/'SOURCE-MANIFEST.json').read_text())
for name,entry in manifest['files'].items():
    assert hashlib.sha256((target/name).read_bytes()).hexdigest()==entry['sha256'],name
(target/'build').mkdir(exist_ok=True)
artifact=target/'build/WorldConquest-stage10.rbxlx'
subprocess.run([str(Path.home()/'.aftman/bin/rojo.exe'),'build',str(target/'default.project.json'),'--output',str(artifact)],cwd=target,check=True)
embedded=[e.text or '' for e in ET.parse(artifact).findall('.//Properties/*')if e.attrib.get('name')=='Source']
sources=list((target/'src').rglob('*.luau'))
for source in sources:
    assert source.read_text(encoding='utf-8-sig')in embedded,source
digest=hashlib.sha256(artifact.read_bytes()).hexdigest()
assert digest==manifest['artifact_sha256'],'Clean place differs from the candidate'
result={'archive':package['archive'],'sources_checked':len(sources),'matching_place_sha256':digest,
        'clean_rojo_build':True,'studio_tested':False,'uploaded':False}
(root/'build/source-build-verification.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
