"""Prepare, never upload, the corresponding-source distribution from an allowlist.

Reject symlinks, credential/private-data paths and recognisable credential formats.
This is a focused packaging check, not a guarantee that every conceivable secret is detectable.
"""
from pathlib import Path
import hashlib, json, re, zipfile

root = Path(__file__).resolve().parents[1]
out = root / 'build'
out.mkdir(exist_ok=True)
roots = ('src', 'scripts', 'tests', 'assets', 'data', 'docs', 'third_party')
top = ('LICENSE', 'NOTICE', 'README.md', 'BUILDING.md', 'DEPENDENCIES.md',
       'default.project.json', 'aftman.toml', '.gitignore')
forbidden = {'.git', '.codex', '.agents', '.aws', '.ssh', 'node_modules', '__pycache__'}
blocked_names = re.compile(r'(^\.env($|\.)|credential|secret|player.?data|datastore.?dump|\.pem$|\.pfx$|\.key$)', re.I)
patterns = {
    'private-key': re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    'github-token': re.compile(rb'(?:gh[pousr]_[A-Za-z0-9]{32,}|github_pat_[A-Za-z0-9_]{60,})'),
    'aws-access-key': re.compile(rb'AKIA[0-9A-Z]{16}'),
    'openai-key': re.compile(rb'sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{40,}'),
    'roblox-cookie': re.compile(rb'WARNING:-DO-NOT-SHARE-THIS[^\r\n]{150,}'),
    'assigned-secret': re.compile(rb'''(?im)(?:api[_-]?key|password|client[_-]?secret|access[_-]?token)\s*[:=]\s*["'][A-Za-z0-9_+/=-]{24,}["']'''),
}
paths = [root / p for p in top]
for folder in roots:
    paths.extend(p for p in (root / folder).rglob('*') if p.is_file())
files = {}
violations = []
for path in sorted(paths):
    relative = path.relative_to(root)
    if any(p in forbidden for p in relative.parts) or path.suffix == '.pyc':
        continue
    assert not path.is_symlink(), f'Symlink requires manual review: {relative}'
    assert path.resolve().is_relative_to(root.resolve()), relative
    if blocked_names.search(path.name):
        violations.append({'file': relative.as_posix(), 'reason': 'sensitive filename'})
        continue
    content = path.read_bytes()
    for kind, pattern in patterns.items():
        if pattern.search(content):
            violations.append({'file': relative.as_posix(), 'reason': kind})
    assert len(content) < 100_000_000, f'GitHub file limit: {relative}'
    files[relative.as_posix()] = {'sha256': hashlib.sha256(content).hexdigest(), 'bytes': len(content)}
audit = {'allowlisted_roots': roots, 'excluded': ['build/**', 'root place files', 'profile.out', 'credentials/config caches', 'runtime profiles/logs', '__pycache__'],
         'files_checked': len(files), 'findings': violations, 'uploaded': False,
         'scope': 'Local allowlist and credential-pattern scan; no runtime player database exported.'}
(out / 'source-audit.json').write_text(json.dumps(audit, indent=2), encoding='utf-8')
assert not violations, 'Source audit failed; inspect build/source-audit.json (secret values are not printed).'
build_manifest = json.loads((out / 'stage10-build-manifest.json').read_text())
for name, digest in build_manifest['files'].items():
    assert files[name]['sha256'] == digest, f'Rebuild the game first: {name}'
manifest = {'repository': 'https://github.com/gbsk001/WorldConquest', 'license': 'AGPL-3.0 with preserved upstream Section 7 terms',
            'artifact_sha256': build_manifest['sha256'], 'files': files,
            'uploaded': False, 'public_availability_verified': False}
manifest_bytes = json.dumps(manifest, indent=2).encode('utf-8')
identifier = hashlib.sha256(manifest_bytes).hexdigest()[:12]
archive = out / f'WorldConquest-source-{identifier}.zip'
with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for name in files:
        z.write(root / name, name)
    z.writestr('SOURCE-MANIFEST.json', manifest_bytes)
    z.writestr('SOURCE-AUDIT.json', json.dumps(audit, indent=2))
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    for name, entry in files.items():
        assert hashlib.sha256(z.read(name)).hexdigest() == entry['sha256']
result = {'archive': archive.relative_to(root).as_posix(), 'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
          'bytes': archive.stat().st_size, 'files': len(files), 'artifact_sha256': build_manifest['sha256'], 'uploaded': False}
(out / 'source-package.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
print(json.dumps(result, indent=2))
