# Balanced Earth spawn acceptance — 24 November 2026

Implemented in the production Stage 11 path and rebuilt `build/WorldConquest-stage10.rbxlx`. Public capacity remains **20**. No GUI, ownership resolution, economy, combat, starting-footprint or bot decision formulas were changed. This report certifies spawn selection through 500 simulated participants, not 500-player active gameplay.

## Cause and implementation

The previous automatic picker sampled uniform map pixels and deliberately clustered some candidates near existing selections. Earth uses an equirectangular longitude/latitude projection: uniform pixels overrepresent northern land. The new Earth planner uses regional land-area quotas followed by seeded, rejection-based Poisson-disc sampling. It never uses fixed spawn coordinates or a displayed grid.

An offline-generated, server-only atlas contains 65,226 contiguous playable row spans (913,164 binary bytes). Each span is weighted by its length times `cos(latitude)`, proportional to spherical cell area in this projection. Binary searches choose random land cells without runtime world scans. The atlas is shared between participants, guarded by map dimensions/mask hash, and generated against the terrain SHA-256 in `data/spawn-atlas-manifest.json`. Candidates still pass the existing full starting-footprint/ownership validation. Regenerate the atlas after changing terrain. Other maps retain their previous picker.

Six explicit gameplay geography regions approximate continents; they are not political boundaries. Greenland is North America; Chukotka is Asia; Australia, New Zealand, New Guinea and Pacific islands are Oceania. Land south of 60°S is excluded from automatic selection. Human selection on valid Antarctic land remains allowed.

| Region | Latitude-corrected land share | Slots at 20 | Slots at 500 |
|---|---:|---:|---:|
| North America | 17.42% | 3 | 87 |
| South America | 13.28% | 3 | 66 |
| Europe | 6.91% | 1 | 35 |
| Africa | 22.49% | 5 | 112 |
| Asia | 33.19% | 7 | 166 |
| Oceania | 6.72% | 1 | 34 |

Integer quotas allocate each remaining slot to the greatest land-area deficit. Human selections are fixed first; quotas and AI reservations rebalance around them. Thus humans can deliberately concentrate on one continent without being moved or refused merely to satisfy quotas.

Geographic spacing is `clamp(1800 * sqrt(20 / participants), 300, 1800)` kilometres. Unit-sphere XYZ hashing searches nearby spatial buckets; exact chord-distance comparisons implement the great-circle exclusion, including high latitudes and the date line. A separate existing nine-cell reservation check protects unchanged starting footprints. The larger geographic exclusion applies to automatic selections and AI around humans; humans retain their existing freedom to select near other humans without overlapping.

Automatic attempts are bounded at 192 candidates per execution and retried during selection without relaxing distance. Existing staggered selection/reconsideration timing and batched marker replication remain. A human can select an AI's occupied starting location: affected AI reservations yield, the human selection commits, and displaced AI relocate in deterministic ID order in the same tick. Recruitment is started only once, including last-countdown moves. Missing automatic selections are resolved before switching to gameplay instead of queuing them behind recruitment.

Existing public/private lobby GUID-derived seeds remain the source of new random match seeds. Explicitly replaying an identical seed reproduces the complete layout. Usernames and participant styling remain unchanged; relocation preserves identity.

## Automated evidence

`python scripts/check_spawn_distribution.py 100` runs actual production Earth/simulation code for 100 different seeds at **each** of 20, 50, 100, 250 and 500 participants, plus same-seed replays. Each population contains one automatically placed human and the remaining AI. These are selection-only CLI simulations, not Roblox networked clients.

All 500 layouts passed: all participants placed, all six region quotas satisfied, zero ocean/impassable/Antarctic automatic roots, zero overlapping starting footprints, required geographic spacing preserved, varied/staggered live selections, and identical replay digests. 92,000 initial selections were tested, excluding replay runs and reconsiderations.

| Participants | Lowest measured separation km | Mean nearest-neighbour km | Largest 10°×10° bin | Unique roots across 100 seeds |
|---|---:|---:|---:|---:|
| 20 | 1801.703 | 2574.0 | 1 | 2000 / 2000 |
| 50 | 1138.442 | 1483.2 | 2 | 4998 / 5000 |
| 100 | 805.023 | 1022.6 | 3 | 9991 / 10000 |
| 250 | 509.117 | 632.4 | 5 | 24959 / 25000 |
| 500 | 360.002 | 439.6 | 8 | 49789 / 50000 |

Clustering is constrained by both regional quotas and minimum geodesic spacing. The diagnostic longitude/latitude bins are not equal-area and are not used by the sampler. No seed produced a repeated complete layout. At 500, the regional vector was 87/66/35/112/166/34 in every unconstrained layout.

Island diagnostic boxes (New Zealand, Japan, Britain/Ireland, Madagascar, Hawaii respectively) received **145 / 305 / 156 / 279 / 2** roots across the 100 500-participant matches. At 20 the totals were **4 / 9 / 1 / 17 / 0**. These are bounding-box observations, not exact island polygons. Small islands are eligible in proportion to usable land, not guaranteed a slot in every small match. Islands too small to fit the unchanged complete AI starting footprint remain ineligible.

Additional actual-Earth tests cover two client replicas receiving AI relocation, simultaneous humans requesting the same root, preservation of the first human reservation, invalid-water rollback, releasing/reusing an old human location, stable AI names, regional rebalancing, late-countdown movement and no duplicate recruitment. Date-line and high-latitude index tests pass. The complete existing Stage 1–11 functional regression suite passed; its runner now includes a short balanced-spawn regression. Full 100-seed distribution testing remains a separate command.

## Selection timing

Latest sequential CLI run, Studio play stopped, 202 simulation steps per match. Average is the mean of match averages; p95 is the **largest per-match p95**, worst is the largest observed single tick, including the transition to gameplay. These numbers are not active-match throughput, client FPS or production capacity measurements.

| Participants | Average tick ms | Maximum match p95 ms | Worst tick ms |
|---|---:|---:|---:|
| 20 | 0.048 | 0.493 | 3.361 |
| 50 | 0.099 | 0.600 | 5.406 |
| 100 | 0.199 | 0.899 | 7.739 |
| 250 | 0.526 | 1.681 | 11.627 |
| 500 | 1.042 | 2.438 | 13.373 |

Raw results: `build/spawn-distribution-100.txt` and `.json`. Heap readings in those rows include the long-running test harness and uncollected previous simulations, so they must not be interpreted as per-bot or isolated-server memory. Earlier overlapping Studio/regression runs had scheduler outliers above 100 ms; the concurrent JSON is retained separately. This change makes no claim that existing large active-match bottlenecks are resolved. Public capacity is unchanged.

## Actual Studio inspection

Opened a freshly loaded, byte-identical copy of the rebuilt place (`build/WorldConquest-spawn-balanced.rbxlx`), with no test configuration overrides. In native Studio Play Solo, verified the 20-participant public lobby, random names, staggered circular spawn markers, increasing selected count, markers across all six continents/regions, no Antarctic markers, transparent labels, and transition into gameplay with the existing HUD/leaderboard. Clicked the AI-selected Greenland location during selection and the human started there. This was an actual rendered Roblox test, not a GUI stub.

This task did **not** repeat a native two-client Studio session or test published servers. Two-client synchronization above is automated production-replica testing. Hundreds of rendered participants, adverse network latency and mobile acceptance remain unverified. `build/studio-spawn-preview-2026-11-24.json` records the inspected source hashes; the package manifest only carries that preview when all source hashes match.

Manual follow-up: open `build/WorldConquest-stage10.rbxlx` (not the obsolete root prototype), start a local server with two clients, join the same public lobby, select/change AI-held locations from each client and verify matching markers/counters. Try both humans on the same location, water, islands, date-line land and a move just before zero. Confirm neither human is moved by AI, zoom/pan stays aligned, and all participants start together. Repeat matches to see different layouts. Leave the safe participant cap at 20 until separate active-gameplay capacity acceptance passes.

## Changed files

- `src/server/OpenFront/SpawnPlanner.luau` — shared weighted sampling, regional quotas and human-aware rebalance.
- `src/server/OpenFront/SpawnAtlas.luau`, `scripts/generate_spawn_atlas.py`, `data/spawn-atlas-manifest.json` — reproducible terrain-derived land atlas.
- `src/server/OpenFront/SpawnIndex.luau` — geographic spatial hash and typed reservations.
- `src/server/OpenFront/SpawnExecution.luau` — automatic picker, human priority, deterministic relocation and one-time recruitment.
- `src/server/OpenFront/Simulation.luau`, `Bots.luau` — planner setup, population configuration, reservation cleanup and countdown finalization.
- `scripts/check_stage1.py`, `check_spawn_distribution.py`, `spawn_distribution_checks.luau`, `check_stage10_all.py` — factory wiring, 100-seed metrics and regressions.
- `scripts/package_stage10.py`, `README.md`, this report — verified build/preview and acceptance documentation.
- `build/WorldConquest-stage10.rbxlx`, build manifest and test/preview evidence — rebuilt with all 71 production sources verified.

AGPL notices and existing source attribution are preserved. No external artwork or new asset licences are introduced. Existing publication blockers (including corresponding-source availability and unverified production matchmaking/performance) remain as documented in the scalability acceptance report.
