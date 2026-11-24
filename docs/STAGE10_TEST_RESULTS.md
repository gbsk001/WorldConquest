# Stage 10 acceptance evidence — 2026-11-20

The final `python scripts/check_stage10_all.py` run passed Stage 1–8, Stage 9, existing strategy GUI, Stage 10 store/state/server/Foundation integration, and Stage 10 menu checks. Production Luau compiled. Stage 10 integration checks were rerun successfully after the final asynchronous lobby-context guards. No gameplay formulas or performance assertions were relaxed.

Logs are in `build/check_stage8_all-stage10-final.txt`, `build/check_stage9-stage10-final.txt`, `build/check_strategy_ui-stage10-final.txt`, `build/check_stage10-stage10-final.txt` and `build/check_stage10_ui-stage10-final.txt`. These execute local Luau with simulated players and stubbed Roblox services/GUI. They do not establish native API success, rendered layout correctness or live server capacity.

The first full run failed an existing Stage 2 performance assertion: 100-player p95 was about 298 ms against a 100 ms threshold. Its log is retained at `build/stage10-first-run-timing-failure.txt`. An unchanged isolated rerun passed at 63.901 ms p95 (12.539 ms average, 104.468 ms worst), followed by the passing full gate. Timing variance remains material; the passing rerun does not erase the first result.

## Latest local stress measurements

Representative first-run Stage 9 synthetic bot fixture results from the final gate:

| Simulated bots | Average tick ms | p95 ms | Worst ms | Peak Luau heap KiB | Total encoded bytes | Peak encoded bytes |
|---|---:|---:|---:|---:|---:|---:|
| 20 | 2.898 | 7.680 | 24.736 | 96,115 | 869,466 | 5,442 |
| 50 | 4.522 | 12.871 | 26.930 | 117,463 | 1,130,856 | 10,068 |
| 100 | 5.979 | 19.429 | 32.956 | 121,951 | 1,414,968 | 15,042 |

Repeated runs matched deterministic digests for all three loads. These fixture timings are not the larger actual-Earth workload in the Stage 9 performance report. Encoded bytes are fixture telemetry, not Roblox wire throughput or per-second network measurements.

The final Stage 8 simultaneous-impact stress still reached **159.131 ms worst tick at 100 simulated players**, with a maximum encoded delta of **2,203,700 bytes**. Functional checks passed, but this remains a performance/publication risk. The new 20-participant lobby cap does not certify live capacity. No cloud matchmaking latency benchmark was performed.

Lobby broadcasts run at 1 Hz and directory refresh at 10-second intervals. Automated menu tests verified that countdown updates allocate no new GUI instances. Native MemoryStore request rates, teleport latency, actual network traffic, long-session memory and rendered desktop/mobile frame rates require staging measurement.

## Candidate and next step

`python scripts/package_stage10.py` builds `build/WorldConquest-stage10.rbxlx` and verifies every embedded production source against the current Rojo tree. `build/stage10-build-manifest.json` records source/artifact hashes and explicitly marks Studio testing, live-service testing and publication false.

Proceed with [manual acceptance](STAGE10_ACCEPTANCE.md). Native matchmaking/social APIs, full matches, failure recovery, rendered mobile controls, existing upstream deviations and the public AGPL corresponding-source offer remain release gates. The implementation is a manual-testing candidate, not a production-certified release.
