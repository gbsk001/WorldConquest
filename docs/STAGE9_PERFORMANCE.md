# Stage 9 measured performance

All figures are standalone Luau simulations, **not Roblox Studio/live tests**. Each run uses the actual 8192×4096 Earth terrain, 20/50/100 autonomous Normal bots plus one idle human, default fair resources, two decisions per tick, 64 border-slot probes, and 600 measured ticks (60 simulation seconds). The countdown is shortened in the fixture; ten setup ticks are excluded from steady-state statistics and their worst cost is reported separately. Each repeat starts a fresh process. This is early expansion, not a rich late-game naval/nuclear match.

The before uses the prior 128-page terrain cache with linear eviction search. The after uses a 4,096-page server cache and O(1) linked eviction. Identical final packed-grid/reserve/gold digests, decision/order counts and total/peak raw payloads are required between repeats and before/after. Timings vary with scheduling and GC; averages below are means of two runs, p95/worst are maximum observed across the two.

| Bots (+1 human) | Before avg / p95 / worst ms | After avg / p95 / worst ms | After AI worst ms | Startup worst ms |
|---:|---:|---:|---:|---:|
| 20 | 16.85 / 59.47 / 150.30 | 7.07 / 22.77 / 40.73 | 1.39 | 9.70 |
| 50 | 40.23 / 117.16 / 1092.93 | 17.03 / 56.85 / 126.80 | 1.18 | 23.08 |
| 100 | 90.35 / 416.61 / 1068.26 | 32.46 / 92.15 / 191.64 | 3.68 | 42.43 |

| Bots | After heap start / peak / end MiB | Raw buffers total / peak tick bytes | Decisions / orders |
|---:|---:|---:|---:|
| 20 | 40.2 / 231.6 / 172.9 | 1,580,704 / 9,996 | 201 / 46 |
| 50 | 48.0 / 435.4 / 254.5 | 3,847,014 / 23,712 | 495 / 109 |
| 100 | 59.1 / 616.7 / 598.2 | 7,602,008 / 37,916 | 962 / 216 |

Heap is gcinfo() including loaded modules and the harness, with peak sampled at tick boundaries and end after digest work. It is not Roblox server RSS, device memory or proof of a leak. The terrain cache is bounded at 16 MiB on enabled Stage 9 servers; the default client decoded cache stays 512 KiB. Overall heap remains substantial at 100 bots.

Raw buffers count ownership/building/ship deltas before optional uniform-state encoding. Metadata, private stats, packet headers, compression, real transport and client paint/upload costs are excluded. Bots do not receive network packets; these cases have one idle human. Do not interpret 100 bots as 100 receiving Roblox clients.

Twenty bots pass the earlier <20 ms average / <50 ms p95 / <100 ms worst targets in this early workload. Fifty bots fail p95/worst; 100 bots fail all three. Five bots remain the default. No live capacity is certified. Earlier Stage 8 simultaneous-impact and Stage 6 adversarial naval-path stalls remain additional risks. Keep 50/100 as stress configurations until measured/fixed in realistic long sessions.

The compact 512×256 fixture separately checks two identical 600-tick replays at each requested bot count. Its timings are logged in build/stage9-results.txt and must not replace these Earth figures. The direct parity suite compares 300 original nation personalities and 30 original nuclear helper cases. Full Stage 1–8 regressions and GUI adapter checks are separate from performance acceptance.

Reproduce with `python scripts/benchmark_bots.py` and `python scripts/report_stage9.py`. Source behavior, configuration, deviations and Studio steps are in [Stage 9 implementation](STAGE9_IMPLEMENTATION.md).
