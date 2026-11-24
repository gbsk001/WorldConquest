# Dedicated performance optimisation — 23 November 2026

**Superseded for capacity decisions by [24 November extended active-gameplay testing](SCALABILITY_ACCEPTANCE_2026-11-24.md).** The three-minute runs expose later naval/connectivity stalls missed by the one-minute measurements below. Retain these historical numbers as their stated workload only.

This is a performance-only change to the Stage 11 project. No gameplay features, GUI redesign, ownership-resolution reduction, resource bonuses, bot cadence changes or formula changes. **Hundreds of production participants are not accepted. Public capacity remains 20.** The 250 target and 500 experimental ceiling remain configuration values, not supported production capacities.

## Implemented changes

- `src/server/OpenFront/OrderedSet.luau`: packed insertion-order frontier storage, sparse 256-cell membership pages and in-place compaction. Preserves deletion/reinsertion ordering, iteration during mutation and sampling cursor semantics. Removes large Lua hash/array overhead per participant.
- `src/shared/OpenFront/Grid.luau`: 256-cell dirty-write index pages and a bounded reusable pool (at most 4 MiB idle storage). Ownership storage remains the same 4096-cell pages and exact 8192 × 4096 grid; ordered delta coalescing and packet bytes are unchanged. Fallout writes use the same recorder.
- `src/server/OpenFront/Connectivity.luau`: smaller sparse scratch pages without changing ownership-page addressing, traversal or connectivity results.
- `src/server/OpenFront/Expansion.luau`: trusted internal owner/terrain reads for already validated neighboring cells; removes repeated validation and terrain lookups. Does not reorder heap entries, RNG calls or attacks.
- `src/shared/Config.luau`, `src/server/LobbyServer.luau`, `src/server/OpenFront/Simulation.luau`: one shared lazy server terrain cache can retain all 8192 pages (32 MiB), instead of evicting/redecoding scattered active terrain at 4096 pages. This is shared geography, not a per-bot copy. The client default remains 128 pages.
- Numerical modules `Grid`, `MinHeap`, `EarthTerrain`, `OrderedSet`, `Expansion`, `Connectivity`, `WaterPath` request Roblox server native compilation. The CLI table below measures interpreted Luau, not a claimed native-code speedup.
- `src/client/InterfaceArt.luau`: the existing original geometry is rasterized once into an 18-cell transparent 512 × 256 icon atlas. Map icons/crowns use one ImageLabel each instead of many frame/stroke children. The existing menu Earth silhouette is similarly rasterized once; its shape/style is retained. Unsupported image allocation falls back to existing geometry. No uploaded or newly licensed artwork.
- `src/client/MapView.luau`: uses the shared atlas for map units/buildings/crowns, preserving colour accents, click targets, level labels, culling, pools and coordinates. Adds atlas readiness and profiler instrumentation.
- `src/shared/Map.luau`, `src/shared/OpenFront/EarthTerrain.luau`, `src/client/MapTiles.luau`: split initial terrain/mip/overview preparation across frames. Display mips are prepared once with a completion guard. This trades additional loading latency for smaller batches; measured startup results below must be consulted rather than assuming an improvement.
- `src/client/TilePainter.luau`, `MapTiles.luau`, `MapView.luau`: MicroProfiler labels `WC.TilePaint`, `WC.TextureUpload`, `WC.CameraAndIcons` distinguish CPU painting, image upload and camera/icon placement.
- `src/client/BuildingShop.luau`, `NavalControls.luau`, `MissileControls.luau`: keep current state while hidden; only repaint quotes/cards when visible or reopened. Invalid-phase cancellation remains active while hidden.
- `src/client/Main.client.luau`: startup-duration diagnostic attribute. No navigation or gameplay API change.

The existing bounded 32-slot visible tile cache, dirty rectangles, one image upload per frame, centre-priority work, LOD reuse, 256-visible-icon limit and stationary-camera cache remain. Moving the camera transforms/culls existing objects; only newly needed or ownership-dirty tiles are painted. Maximum-detail samples still come from the original grid, including coastline and ownership boundary pixels.

Supporting files: new `scripts/benchmark_performance.py`, `performance_storage_checks.luau`, `check_performance_storage.py`, `ordered_set_reference.luau`, `render_population_acceptance.client.luau`, `collect_render_performance.py`, `studio_performance_observer.client.luau`, `package_performance_play.py`; updated `unit_icon_checks.luau`, `check_stage10_all.py`, `package_render_acceptance.py`, `package_stage10.py`, `README.md` and this report. Generated artifacts/results are under `build/`. The release manifest records the current source hashes and narrowly scoped Studio evidence with full acceptance explicitly false.

## Controlled server comparison

`python scripts/benchmark_performance.py before-controlled` and `after-final`: fresh CLI process for each population, sequential runs, real Earth terrain, seed 12345, N−1 AI plus one observer, 202 selection ticks and 600 gameplay ticks (60 simulated gameplay seconds). No Roblox renderer/transport or concurrent benchmark processes. One timing sample per configuration; not a soak test. Separate repeated regression fixtures check determinism. Native compilation hints do not change these interpreted CLI timings.

| Total participants | Before avg / p95 / worst ms | After avg / p95 / worst ms | Peak simulation Luau heap MiB, before → after |
|---:|---:|---:|---:|
| 20 | 4.97 / 15.68 / 64.76 | 3.70 / 11.52 / 66.26 | 186.6 → 72.2 |
| 50 | 13.46 / 43.74 / 77.99 | 9.44 / 30.04 / 48.52 | 368.5 → 120.2 |
| 100 | 29.43 / 84.08 / 142.75 | 19.61 / 54.61 / 77.01 | 613.7 → 199.7 |
| 200 | 69.98 / 237.89 / 2265.93 | 43.08 / 133.57 / 1661.95 | 1007.8 → 467.6 |
| 250 | 58.64 / 207.65 / 352.90 | 36.02 / 123.50 / 233.88 | 944.5 → 379.4 |
| 500 | 68.76 / 170.21 / 328.92 | 41.46 / 91.13 / 105.88 | 1033.5 → 445.8 |

The 100-participant mean fell 33.4%, and peak heap fell 67.5%. The 20-participant worst tick did not improve. Outcomes are non-monotonic because geography, encounters, orders and the fixed decision budget differ with population; the 500 run cannot certify the 200 or 250 workload. Heap is sampled during simulation, not total process/native memory, and excludes later digest-copy allocation.

Every population has identical before/after final replay digest, raw delta bytes, peak delta bytes, metadata estimate, decisions and orders. Digests (20/50/100/200/250/500): `2430050461`, `190072895`, `918407455`, `1472872852`, `2774352481`, `3094579944`.

The dominant remaining cost is active expansion/frontier work: 34.60 ms average at 500 versus 0.21 ms AI decisions and 3.87 ms connectivity. At 200 a synchronous full-resolution naval route produces a 1661.95 ms tick. Native compilation may help numerical loops but does not establish a bounded search. Changing route results, dropping expansion work or delaying simulation actions would require separate correctness work; none was done to disguise this spike.

## Network workload

Uncompressed raw ownership/unit bytes are identical before and after. Reduced allocation cost is demonstrated; **a bandwidth reduction is not claimed**. Existing fragmentation, per-client snapshot limits and authoritative round validation remain.

| Participants | Raw gameplay delta KiB/s (60 seconds) | Largest raw tick KiB | Estimated metadata KiB/s (80.2 seconds) |
|---:|---:|---:|---:|
| 20 | 21.0 | 7.3 | 8.1 |
| 50 | 54.0 | 20.6 | 19.9 |
| 100 | 112.7 | 32.6 | 39.8 |
| 200 | 224.1 | 92.5 | 81.3 |
| 250 | 218.2 | 89.9 | 99.2 |
| 500 | 250.5 | 62.1 | 215.3 |

These are workload payload/serialization estimates, not observed Roblox wire bandwidth. Buffer compression, transport overhead, private stats, fragmentation and number of connected human clients affect actual traffic. AI does not create a network connection. Broadcasting to many real clients multiplies server egress. The 100-participant simultaneous-impact regression still generates a 2,203,700-byte raw burst; this remains a recovery/backpressure risk despite bounded fragments. Do not interpret the ordinary expansion table as a missile stress result.

## Automated verification

`python scripts/check_stage10_all.py`: **all Stage 1–11 functional regressions passed** on the revised sources. Includes pinned upstream parity, deterministic expansion/combat, connectivity, rail/naval, economy/buildings, missile/SAM/MIRV/fallout/regeneration, victory/results/restart/round isolation, authoritative remote validation, snapshots/recovery, bot identity/spawn/replay, lobby/private access, UI navigation/closing/leaderboard/crowns and map coordinate/dirty-tile checks. These use CLI/stubbed services; not real clients or live matchmaking.

Additional `check_performance_storage.py`: 100,000 differential operations against the saved original OrderedSet, exact order/cursors, tile zero, clear, append/delete during traversal. `check_unit_icons.py`: all original graphical kinds, 18 transparent atlas regions, one atlas allocation, one object per map icon, bounded pooled rendering of 5,000 units. All production Luau compiles. Logs: `build/performance-regressions.txt` and existing per-suite final logs.

The functional suite's 100-participant impact stress still recorded **170.53 and 172.92 ms worst ticks** in the final rerun (139.60/160.13 ms in the preceding run). The 50-participant impact cases recorded 72.82 and 68.68 ms; the 20 cases 27.21 and 27.35 ms. Functional correctness passing does not mean the 100 ms performance gate passed. Public capacity stays 20; 50 is a useful next staging candidate, not newly certified production support.

## Native Studio rendering and gameplay

Actual Roblox Studio Play Solo renderer, 1096 × 675 game viewport on this desktop (MicroProfiler reports Ryzen 7 7800X3D, RTX 4060, 15,465 MB system memory, auto quality 21). Six populations run sequentially, 48 seconds each (12 seconds warmup/overview/detail/zoom-pan), with synthetic participant records and six buildings each. The fixture has no server gameplay; every test uses the same fixed synthetic terrain patches, including unlabelled patches outside the current roster. Other Studio places remained open but idle; only one playtest was active and no CPU benchmarks ran during frame sampling. One before/after run, not statistical/device certification. FPS is 1000/mean RenderStepped interval.

| Participants | Zoom/pan FPS before → after | Avg / p95 / worst frame ms, before → after | Sampled client Luau heap peak MiB, before → after |
|---:|---:|---:|---:|
| 20 | 60.0 → 60.0 | 16.67 / 17.77 / 25.02 → 16.67 / 17.82 / 22.41 | 38.6 → 39.3 |
| 50 | 60.0 → 60.0 | 16.67 / 18.09 / 22.91 → 16.67 / 18.11 / 21.87 | 48.6 → 47.6 |
| 100 | 60.0 → 60.0 | 16.67 / 18.04 / 22.43 → 16.67 / 17.91 / 21.58 | 51.9 → 51.7 |
| 200 | 59.9 → 60.0 | 16.69 / 18.02 / 52.20 → 16.67 / 18.01 / 22.28 | 53.3 → 52.6 |
| 250 | 60.0 → 60.0 | 16.67 / 18.27 / 24.85 → 16.66 / 17.86 / 21.82 | 51.9 → 52.8 |
| 500 | 57.6 → 60.0 | 17.35 / 31.28 / 54.96 → 16.67 / 17.98 / 21.74 | 57.8 → 55.2 |

At 500, the detail phase also improved from 59.0 FPS / p95 32.33 ms to 60.0 FPS / p95 18.07 ms. The population warmup worst frame fell from 175.82 to 121.76 ms, **still a noticeable loading spike**. Static overview was already 60 FPS. Atlas readiness was true in the native runtime, not only in GUI stubs. Visible graphical icons, levels, crowns, transparent labels and sharp coastline/ownership cells were inspected in Studio after zooming.

Stats total memory at the final 500 phase was 2881.1 → 2269.6 MiB. This includes Studio/native resources and is not a clean client-only savings figure; use the Luau heap column for script memory. Full per-phase results and provenance: `build/render-performance-before.json`, `build/render-performance-after.json`.

Startup fixture (requires map/modules, creates view and synthetic data, then configures 20 records): original **2.101 s / worst frame 72.757 ms**. Initial fixed-batch yielding regressed to **4.188 s / 79.383 ms**. Replaced unconditional waits with approximately 2 ms initialization CPU budgets, checked between bounded batches. Final dedicated startup recheck: **2.316 s / 37.774 ms**. Worst startup frame improved about 48%; total loading time is 0.215 s longer than baseline. This is not a claim that cold startup is freeze-free. The six-population camera table predates only this initialization scheduling adjustment; final 20-population camera/startup recheck and normal gameplay verify the final build separately. The final 20-record recheck held 60 FPS, p95 18.11 ms, with a 47.77 ms zoom/pan outlier (`build/startup-final-native.txt`); not every worst-frame sample improved.

Opened Studio MicroProfiler, inspected frame/timeline views and exported traces: `build/performance-evidence/baseline-idle-microprofile.html` (idle baseline, not a zoom-cost comparison), `after-zoom-microprofile.html` (revised manual wheel zoom). The full rendering benchmarks were sampled without the profiler overlay. The available evidence supports improved 500-record camera performance and reduced GUI-object construction; it does not establish that every user-reported freeze has been reproduced or eliminated. Tile painting, native image allocation/GC, bulk roster creation and full-game simulation must still be considered separately.

### Final production-code Play Solo check

Opened the rebuilt production-code fixture with a read-only observer, not the old root prototype. Verified PLAY → public lobby with 20 participants → staggered selection and a human spawn change → gameplay/expansion → changing rankings/crowns → panel opening/closing → Leave Game returning to Home. Also opened/closed Friends and created a six-participant private host lobby with new names, join code and existing host controls. Building/naval/missile panels refreshed correctly after being hidden. Actual purchases, complete victory and live invitations were not re-certified by this short visual check.

The ordinary match **did not pass stable-60-FPS acceptance**. The menu/map initialization attribute was 1964.90 ms, but the observer saw a 180.12 ms frame in its first 10 seconds, including engine/server startup. During unprofiled active gameplay, a 10-second interval at elapsed 110.2 seconds measured **54.12 FPS, mean 18.48 / p95 52.29 / worst 71.51 ms**. After the profiler was turned off, elapsed 260.4 seconds measured **48.76 FPS, mean 20.51 / p95 50.92 / worst 72.09 ms**. Intervals while MicroProfiler was visible/dumping are diagnostic, not clean timing comparisons (one fell to 39.27 FPS). There is no equivalent full-game baseline run, so no full-game FPS improvement is claimed.

Across the observed public match, server telemetry's maximum rolling mean/p95 were **24.70 / 67.02 ms**, cumulative worst **86.83 ms**; these are rolling telemetry extrema, not a single whole-match distribution. Sampled server heap reached **197,392 KiB (192.8 MiB)**, client heap at least **122.95 MiB**, and Stats total memory at least **3410.1 MiB** in Studio. The longer run exceeds the 60-second CLI memory sample, emphasizing why that short benchmark is not a capacity certificate.

Client diagnostics recorded worst tile painting **5.67 ms**, upload **0.17 ms**, roster repaint **2.21 ms**, and at most 33 map images (32 cached slots plus overview). MicroProfiler showed foreground task spikes during ongoing simulation; the current evidence suggests shared Play Solo server/client scheduling and simulation work contribute substantially beyond the texture uploader. This is an inference, not a proven attribution of every long frame. A separate-process server/client profile is still needed. The active-game trace is saved as `build/performance-evidence/full-game-microprofile.html`; telemetry is `build/full-game-native.txt`.

The first observer used a StatsItem name unavailable in this environment. Corrected the reusable observer to the documented `Stats.DataReceiveKbps` / `DataSendKbps` properties and sampled those read-only through Studio's client command bar. Play Solo reported **0 received KB/s** and approximately **0.44–0.48 sent KB/s**; the local combined test does not provide representative gameplay wire traffic. Do not substitute those numbers for a real-client bandwidth test. See [Stats property units](https://create.roblox.com/docs/reference/engine/classes/Stats). High-population network evidence remains the raw payload table, with actual transport/fanout explicitly unverified.

**Readiness:** useful measured improvements, all functional regressions passing, and a rebuilt candidate ready for further manual/performance investigation. Not a completed performance acceptance, stable-60-FPS release, or production approval for 50/100/250/500. The largest workload tested was 500 simulated participants; the retained public limit is 20, and even that limit needs separate-process/mobile/full-match acceptance. No maximum reliable production capacity has been established by these tests.

## Reproduction and remaining acceptance

1. Open `build/WorldConquest-stage10.rbxlx`, not the obsolete root `WorldConquest.rbxlx`. Stop any old test first. Alternatively sync `default.project.json` with the existing Rojo plugin, then restart Play. The build script verifies all 69 current production sources and Stage 11 enablement.
2. Run the automated suite and `python scripts/check_performance_storage.py`. Run `python scripts/benchmark_performance.py after-recheck` with other simulations stopped. Saved before/current JSON is under `build/performance-*.json`.
3. Isolated native renderer: `python scripts/package_render_acceptance.py performance-after --population`, open that fixture and Play. Six populations × 48 seconds; 6 buildings per participant, fixed synthetic patches, 1024 ownership changes every 0.25 seconds, overview/detail/repeated focus/zoom. This is a renderer fixture, not a 500-person match. Extract results using `collect_render_performance.py` and the actual Studio log path.
4. Normal gameplay with read-only diagnostics: `python scripts/package_performance_play.py`, open `build/WorldConquest-performance-play.rbxlx`. PLAY → lobby → choose/change land → start → expand. The observer logs RenderStepped, server remote telemetry and Stats transport rates every 10 seconds. Never publish either fixture; only the rebuilt release.
5. Use Studio MicroProfiler (Ctrl+F6), Detailed mode and Dump. Inspect the three `WC.*` scopes during wheel zoom and drag pan, tile uploads and population arrival. Also sample Script Profiler; numerical server code may show `<native>`. Compare cold/warm caches at the same viewport, with other play sessions stopped. See [MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler/use-microprofiler), [Script Profiler](https://create.roblox.com/docs/studio/optimization/scriptprofiler), [native compilation](https://create.roblox.com/docs/luau/native-code-gen).
6. Still required: two or more actual Studio clients, slow receiver/late join/reconnect during large changes, full mature matches, concurrent naval routes and missile impacts, high connected-human fanout, low-memory/mobile devices and sustained maximum-detail camera movement. Test PLAY, Private, Friends, leaderboard/crowns, panel closing, Leave/Stay, icons, placement and return to menu. No production capacity increase until these pass within budgets.

Publication blockers remain: >100 ms mixed-load/route/impact spikes, unverified high-human-count transport/backpressure, mobile and multi-client acceptance, published MemoryStore/Teleport/reserved-server/friend-invite checks, and blank `Config.SourceURL`. Preserve `LICENSE`/`NOTICE`, OpenFront AGPL notices and Natural Earth attribution; host the complete corresponding source for the exact release and configure the source offer before publishing. Original icon geometry remains original; no external icon assets were added. Existing upstream deviations in the Stage 8/9/11 reports remain, and this performance task does not certify missing gameplay parity.
