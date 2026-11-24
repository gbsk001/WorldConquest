# Final technical acceptance — 2026-11-20

**Ready for manual multiplayer testing; not accepted for publication.** Stage 8 remains enabled. All Stage 1–8 automated regressions pass, but the 100-player worst-tick gate, large broadcasts, difficult naval searches and real Roblox/device acceptance remain open. No Studio or live test was performed.

## Changes and correctness

Fallout batches now cache writable pages and delta offsets and consolidate counters. Cached blast stencils avoid repeated distance classification and unnecessary interior boundary work. Optional uniform-state delta fragments carry four-byte cell references plus one shared state instead of six bytes per cell. Mixed/small fragments retain the original format. Replica expansion preserves atomic fragment assembly and snapshot catch-up. No impact is deferred; ownership order, RNG, casualty rounding, map resolution and OpenFront formulas are preserved.

Uniform-state round trips, malformed input rejection, atomic fragments and snapshot catch-up are covered by added tests. Before/after benchmark digests, impact timing, raw payload lengths and saved Stage 7 determinism digests match. See [implementation and source mapping](STAGE8_IMPLEMENTATION.md) and [changed files](STAGE8_CHANGED_FILES.md).

## Repeated standalone benchmarks

Each after case runs three times in a fresh standalone Luau process: averages are the mean of runs, p95 and worst are the maximum observed across runs. Historical before measurements use the saved pre-optimisation Stage 8 harness, one run per case. They precede the earlier 113.02 ms report; these numbers do not prove an improvement over that single observation. Current CPU changes are modest and the worst-case target remains unmet.

8192×4096 grid, 1,600 initial cells/player, one simultaneous missile/player (every tenth hydrogen), 180 ticks. Earth uses African land; all missiles impact. Flat 50/100 cases finish 49/99 impacts within the window. These are simulated salvos, not autonomous full matches or live capacity estimates. Idle ticks make p95 low. Encoding-inclusive timings include buffer packing, but exclude RemoteEvent serialization, transport, metadata, receiving clients and rendering.

| Fixture / players | Before simulation avg / p95 / worst ms | After simulation avg / p95 / worst ms | After including encoding avg / p95 / worst ms |
|---|---:|---:|---:|
| Flat / 20 | 0.896 / 0.223 / 87.725 | 0.355 / 0.178 / 24.749 | 0.369 / 0.178 / 26.119 |
| Flat / 50 | 1.954 / 0.394 / 283.548 | 0.650 / 0.390 / 56.721 | 0.678 / 0.390 / 61.042 |
| Flat / 100 | 4.091 / 0.840 / 602.087 | 1.270 / 0.876 / 104.388 | 1.325 / 0.877 / 112.797 |
| Earth / 20 | 11.148 / 0.183 / 994.773 | 0.472 / 0.171 / 26.432 | 0.482 / 0.171 / 27.075 |
| Earth / 50 | 29.053 / 0.395 / 4074.250 | 1.082 / 0.384 / 73.017 | 1.112 / 0.385 / 74.125 |
| Earth / 100 | 61.667 / 0.856 / 7333.431 | 2.133 / 1.020 / 114.341 | 2.173 / 1.021 / 115.665 |

| Fixture / players | Heap start / sampled peak / end MiB | Raw total / peak tick bytes | Encoded total / peak tick bytes |
|---|---:|---:|---:|
| Flat / 20 | 30.8 / 51.7 / 33.3 | 668,122 / 310,846 | 500,572 / 207,444 |
| Flat / 50 | 36.0 / 54.9 / 50.1 | 1,495,434 / 992,458 | 1,131,484 / 662,172 |
| Flat / 100 | 45.3 / 75.5 / 59.2 | 3,129,054 / 2,128,478 | 2,355,988 / 1,420,052 |
| Earth / 20 | 32.1 / 52.4 / 56.3 | 572,170 / 192,640 | 436,412 / 179,712 |
| Earth / 50 | 40.6 / 73.6 / 62.8 | 1,263,670 / 481,600 | 978,564 / 447,936 |
| Earth / 100 | 54.2 / 94.2 / 100.1 | 2,322,800 / 947,108 | 1,820,832 / 885,144 |

Heap is gcinfo(), including harness/modules, not process RSS or Roblox memory. Peak is sampled at tick boundaries; end is after digest work and may exceed it. No long-session leak conclusion follows. Raw data and individual repeats are retained in build/stage8-benchmark-*.json.

## Network bursts and capacity

The burst is caused by many changed ownership/fallout cells at once, broadcast to every client. Fragmentation limits each message but does not limit aggregate fan-out. Uniform fragments shrink by one third; total 100-player payload falls 24.7% on flat terrain and 21.6% on Earth. Mixed-state initial claims dominate the Earth peak, which falls only 6.5%. This is logical buffer reduction, not measured Roblox bandwidth savings.

At 100 receiving clients the encoded peak still represents approximately 142 MB aggregate flat / 88.5 MB Earth before transport. Transport compression, headers and actual serialization costs are unknown. Do not enable a 100-player release based on these measurements. Twenty and fifty simulated salvos meet isolated tick targets; mixed combat, large MIRVs, recovery and clients can cost more. Begin manual acceptance at two clients, then ten/twenty. No live player capacity is certified.

## Verification and candidate

`python scripts/check_stage8_all.py` passed after the production changes: Stage 1–5 parity/combat/economy/buildings/7,000 rail ticks; Stage 6 naval parity/4,810 trace ticks/authority; compilation; Stage 7 stress, determinism, memory, snapshots/recovery and icon pooling; Stage 8 missiles/SAM/interception/casualties/fallout/MIRV, victory/elimination/rankings/results/restart and stale-round/network tests. Logs: `build/check_*-stage8-final.txt`. Performance gates are separate and remain open. Earlier Stage 2 high-player timing and difficult full-resolution naval A* also remain risks.

Pinned original-source MIRV regeneration and predictive SAM/curve/blast/casualty oracles are documented in the Stage 8 report; regeneration SHA-256 is recorded in `tests/stage8/regeneration.json`. This is targeted parity, not complete upstream end-to-end equivalence.

Reproduce with `python scripts/check_stage8_all.py`, `python scripts/benchmark_stage8.py --repeats 3`, `python scripts/benchmark_stage8.py --earth --repeats 3`, then `python scripts/package_stage8.py` and `python scripts/report_stage8_acceptance.py`.

The verified candidate is `build/WorldConquest-stage8.rbxlx`: 58 embedded current sources, Stage 8 enabled. SHA-256 `d2d01c48f2075f130533c705f65229f2ef354f0345f67380670be4f1187bb33d`. The per-source manifest is `build/stage8-build-manifest.json`. The root place remains older. Follow the [manual Studio acceptance checklist](STAGE8_STUDIO_CHECKLIST.md); every live acceptance item is still pending.

## Upstream deviations and publication blockers

The custom Natural Earth/ETOPO raster differs from upstream authored maps. Full-resolution naval A*/shore routing differs from hierarchical upstream routing and can alter travel timing/trade payouts. Train carriages are virtual. Normal FFA/server-team victory is implemented; ranked/tutorial modes, water-changing nukes, autonomous bot lobby, diplomacy/alliance-request UI, team-selection UI, disconnected-team inheritance and persistent/cross-server ranked recovery are absent. Alliances are not shared victory teams in the pinned normal rules. Frozen results/automatic restart and all-disconnected reset are Roblox adaptations. Client projectile interpolation differs from upstream artwork/playback. No new gameplay features were added for acceptance.

Publication blockers: worst tick >100 ms; large per-client/broadcast bursts; pathological naval routing; no recorded full-match multiplayer, recovery, desktop/mobile GPU/input or long-session memory acceptance; no hundred-player full-MIRV stress certification; and no public corresponding-source offer. `Config.SourceURL` is blank. Host complete corresponding source for the deployed adaptation (including build instructions and required notices) and connect the visible offer before release. Preserve AGPL, additional terms, copyright and NOTICE. Existing Natural Earth public-domain / NOAA ETOPO CC0 provenance is in data/README.md and manifests; no new third-party image/audio/model assets were added. Existing asset provenance is documented, not a blanket legal certification. Nothing was published.
