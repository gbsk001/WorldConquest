"""Refresh acceptance documentation from recorded standalone measurements."""
from pathlib import Path
import json

root=Path(__file__).resolve().parents[1]
def read(name): return json.loads((root/'build'/name).read_text())
flat=read('stage8-benchmark-after.json')
earth=read('stage8-benchmark-earth-after.json')
manifest=read('stage8-build-manifest.json')
lines=['# Final technical acceptance — 2026-11-20', '',
'**Ready for manual multiplayer testing; not accepted for publication.** Stage 8 remains enabled. All Stage 1–8 automated regressions pass, but the 100-player worst-tick gate, large broadcasts, difficult naval searches and real Roblox/device acceptance remain open. No Studio or live test was performed.', '',
'## Changes and correctness', '',
'Fallout batches now cache writable pages and delta offsets and consolidate counters. Cached blast stencils avoid repeated distance classification and unnecessary interior boundary work. Optional uniform-state delta fragments carry four-byte cell references plus one shared state instead of six bytes per cell. Mixed/small fragments retain the original format. Replica expansion preserves atomic fragment assembly and snapshot catch-up. No impact is deferred; ownership order, RNG, casualty rounding, map resolution and OpenFront formulas are preserved.', '',
'Uniform-state round trips, malformed input rejection, atomic fragments and snapshot catch-up are covered by added tests. Before/after benchmark digests, impact timing, raw payload lengths and saved Stage 7 determinism digests match. See [implementation and source mapping](STAGE8_IMPLEMENTATION.md) and [changed files](STAGE8_CHANGED_FILES.md).', '',
'## Repeated standalone benchmarks', '',
'Each after case runs three times in a fresh standalone Luau process: averages are the mean of runs, p95 and worst are the maximum observed across runs. Historical before measurements use the saved pre-optimisation Stage 8 harness, one run per case. They precede the earlier 113.02 ms report; these numbers do not prove an improvement over that single observation. Current CPU changes are modest and the worst-case target remains unmet.', '',
'8192×4096 grid, 1,600 initial cells/player, one simultaneous missile/player (every tenth hydrogen), 180 ticks. Earth uses African land; all missiles impact. Flat 50/100 cases finish 49/99 impacts within the window. These are simulated salvos, not autonomous full matches or live capacity estimates. Idle ticks make p95 low. Encoding-inclusive timings include buffer packing, but exclude RemoteEvent serialization, transport, metadata, receiving clients and rendering.', '',
'| Fixture / players | Before simulation avg / p95 / worst ms | After simulation avg / p95 / worst ms | After including encoding avg / p95 / worst ms |',
'|---|---:|---:|---:|']
def timing(row,prefix=''): return ' / '.join(f'{row[prefix+k]:.3f}' for k in ['average_ms','p95_ms','worst_ms'])
for label,rows,beforefile in [('Flat',flat,'stage8-benchmark-before.json'),('Earth',earth,'stage8-benchmark-earth-before.json')]:
    for b,a in zip(read(beforefile),rows):
        lines.append(f'| {label} / {int(a["players"])} | {timing(b)} | {timing(a)} | {timing(a,"with_encoding_")} |')
lines += ['', '| Fixture / players | Heap start / sampled peak / end MiB | Raw total / peak tick bytes | Encoded total / peak tick bytes |', '|---|---:|---:|---:|']
for label,rows in [('Flat',flat),('Earth',earth)]:
    for a in rows:
        heap=' / '.join(f'{a[k]/1024:.1f}' for k in ['heap_start_kib','heap_peak_kib','heap_end_kib'])
        raw=f'{int(a["logical_bytes_total"]):,} / {int(a["logical_bytes_peak_tick"]):,}'
        enc=f'{int(a["encoded_bytes_total"]):,} / {int(a["encoded_bytes_peak_tick"]):,}'
        lines.append(f'| {label} / {int(a["players"])} | {heap} | {raw} | {enc} |')
lines += ['',
'Heap is gcinfo(), including harness/modules, not process RSS or Roblox memory. Peak is sampled at tick boundaries; end is after digest work and may exceed it. No long-session leak conclusion follows. Raw data and individual repeats are retained in build/stage8-benchmark-*.json.', '',
'## Network bursts and capacity', '',
'The burst is caused by many changed ownership/fallout cells at once, broadcast to every client. Fragmentation limits each message but does not limit aggregate fan-out. Uniform fragments shrink by one third; total 100-player payload falls 24.7% on flat terrain and 21.6% on Earth. Mixed-state initial claims dominate the Earth peak, which falls only 6.5%. This is logical buffer reduction, not measured Roblox bandwidth savings.', '',
'At 100 receiving clients the encoded peak still represents approximately 142 MB aggregate flat / 88.5 MB Earth before transport. Transport compression, headers and actual serialization costs are unknown. Do not enable a 100-player release based on these measurements. Twenty and fifty simulated salvos meet isolated tick targets; mixed combat, large MIRVs, recovery and clients can cost more. Begin manual acceptance at two clients, then ten/twenty. No live player capacity is certified.', '',
'## Verification and candidate', '',
'`python scripts/check_stage8_all.py` passed after the production changes: Stage 1–5 parity/combat/economy/buildings/7,000 rail ticks; Stage 6 naval parity/4,810 trace ticks/authority; compilation; Stage 7 stress, determinism, memory, snapshots/recovery and icon pooling; Stage 8 missiles/SAM/interception/casualties/fallout/MIRV, victory/elimination/rankings/results/restart and stale-round/network tests. Logs: `build/check_*-stage8-final.txt`. Performance gates are separate and remain open. Earlier Stage 2 high-player timing and difficult full-resolution naval A* also remain risks.', '',
'Pinned original-source MIRV regeneration and predictive SAM/curve/blast/casualty oracles are documented in the Stage 8 report; regeneration SHA-256 is recorded in `tests/stage8/regeneration.json`. This is targeted parity, not complete upstream end-to-end equivalence.', '',
'Reproduce with `python scripts/check_stage8_all.py`, `python scripts/benchmark_stage8.py --repeats 3`, `python scripts/benchmark_stage8.py --earth --repeats 3`, then `python scripts/package_stage8.py` and `python scripts/report_stage8_acceptance.py`.', '',
f'The verified candidate is `build/WorldConquest-stage8.rbxlx`: {manifest["source_files_verified"]} embedded current sources, Stage 8 enabled. SHA-256 `{manifest["sha256"]}`. The per-source manifest is `build/stage8-build-manifest.json`. The root place remains older. Follow the [manual Studio acceptance checklist](STAGE8_STUDIO_CHECKLIST.md); every live acceptance item is still pending.', '',
'## Upstream deviations and publication blockers', '',
'The custom Natural Earth/ETOPO raster differs from upstream authored maps. Full-resolution naval A*/shore routing differs from hierarchical upstream routing and can alter travel timing/trade payouts. Train carriages are virtual. Normal FFA/server-team victory is implemented; ranked/tutorial modes, water-changing nukes, autonomous bot lobby, diplomacy/alliance-request UI, team-selection UI, disconnected-team inheritance and persistent/cross-server ranked recovery are absent. Alliances are not shared victory teams in the pinned normal rules. Frozen results/automatic restart and all-disconnected reset are Roblox adaptations. Client projectile interpolation differs from upstream artwork/playback. No new gameplay features were added for acceptance.', '',
'Publication blockers: worst tick >100 ms; large per-client/broadcast bursts; pathological naval routing; no recorded full-match multiplayer, recovery, desktop/mobile GPU/input or long-session memory acceptance; no hundred-player full-MIRV stress certification; and no public corresponding-source offer. `Config.SourceURL` is blank. Host complete corresponding source for the deployed adaptation (including build instructions and required notices) and connect the visible offer before release. Preserve AGPL, additional terms, copyright and NOTICE. Existing Natural Earth public-domain / NOAA ETOPO CC0 provenance is in data/README.md and manifests; no new third-party image/audio/model assets were added. Existing asset provenance is documented, not a blanket legal certification. Nothing was published.', '']
(root/'docs/FINAL_TECHNICAL_ACCEPTANCE.md').write_text('\n'.join(lines),encoding='utf-8')
report=root/'docs/STAGE8_IMPLEMENTATION.md'
s=report.read_text(encoding='utf-8')
s=s.replace('The raw wire payload size is unchanged: this work optimises replication packing,\nnot a new compressed protocol or a proven Roblox network-throughput solution.', 'The raw six-byte logical delta remains unchanged. Optional uniform-state fragments\nnow use four-byte references and a common state; clients expand them before atomic\napplication. Mixed fragments retain the existing encoding. Actual Roblox transport\nthroughput remains unverified.')
start=s.index('## Benchmarks (')
end=s.index('## Automated verification',start)
s=s[:start]+'## Benchmarks (standalone Luau, simulated players only)\n\nThe latest three-repeat timings, memory, raw/encoded payloads, historical before\ncomparisons and limitations are in [final technical acceptance](FINAL_TECHNICAL_ACCEPTANCE.md).\nThat report supersedes earlier single-run measurements. The 100-player worst-tick\ngate remains open; no live capacity is certified.\n\n'+s[end:]
report.write_text(s,encoding='utf-8')
readme=root/'README.md'
tail=readme.read_text(encoding='utf-8').split('## Retained legacy prototype documentation',1)[1]
readme.write_text('''# WorldConquest

The default Rojo project enables **Stage 8** (`SimulationMode="Foundation", PortStage=8`), including missiles, SAM defence, normal FFA/team victory, results and fresh-round restart over the implemented Stage 1–7 systems.

**Automated Stage 1–8 regressions pass; technical acceptance remains open.** The 100-player worst-tick target and large network bursts are unresolved, and no live Studio/mobile acceptance was performed. Read [final technical acceptance](docs/FINAL_TECHNICAL_ACCEPTANCE.md) for latest repeated benchmarks, limitations and publication blockers, and [Stage 8 implementation](docs/STAGE8_IMPLEMENTATION.md) for upstream mapping/formulas.

Run `python scripts/check_stage8_all.py` for regressions. Run `rojo serve default.project.json`, stop Studio Play and sync, or open `build/WorldConquest-stage8.rbxlx`. The root `WorldConquest.rbxlx` remains the older place. Use the [manual multiplayer checklist](docs/STAGE8_STUDIO_CHECKLIST.md); the candidate is for testing, not a certified release.

Preserve [NOTICE](NOTICE) and [LICENSE]. Public corresponding-source hosting is not configured (`Config.SourceURL` is blank).

## Retained legacy prototype documentation'''+tail,encoding='utf-8')
baseline=root/'build/stage8-baseline/src'
changed=[]
for p in sorted((root/'src').rglob('*.luau')):
    old=baseline/p.relative_to(root/'src')
    if not old.exists() or old.read_bytes()!=p.read_bytes():
        changed.append(f'- `{p.relative_to(root).as_posix()}`'+(' (new)' if not old.exists() else ''))
(root/'docs/STAGE8_CHANGED_FILES.md').write_text('''# Stage 8 changed files

Cumulative production differences against the saved pre-Stage-8 source tree (`build/stage8-baseline/src`); this workspace has no Git metadata. “New” means absent from that snapshot.

'''+ '\n'.join(changed)+'''

Final acceptance changes specifically touch Grid (batched page access and optional uniform encoding), Missiles (geometry stencil/interior handling), FoundationServer (encoded fragments/byte metric), Replica (decode before atomic application), scripts/missile_checks.luau (codec/recovery regressions), scripts/stage8_benchmark.luau and scripts/benchmark_stage8.py (encoding timing and repeated measurements).

Reproduction/package documentation: scripts/package_stage8.py, scripts/report_stage8_acceptance.py, docs/FINAL_TECHNICAL_ACCEPTANCE.md, docs/STAGE8_IMPLEMENTATION.md, docs/STAGE8_STUDIO_CHECKLIST.md, docs/STAGE8_CHANGED_FILES.md, docs/OPENFRONT_SOURCE_INDEX.md, README.md and NOTICE. Stage 8 oracle generators, regression harnesses and tests/stage8 fixtures are retained. Latest measurements, suite logs, verified Rojo artifact and source-hash manifest are under build/.
''',encoding='utf-8')
print('Updated acceptance report, Stage 8 benchmark reference, changed-files list and README.')
