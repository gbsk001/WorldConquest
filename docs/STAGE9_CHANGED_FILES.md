# Stage 9 changed files

- `src/server/OpenFront/BotRules.luau` — new translated reaction/reserve/threat and nuclear planning helpers.
- `src/server/OpenFront/Bots.luau` — new bounded scheduler, roster, decision state, economy/combat/advanced intent adapter.
- `src/server/OpenFront/OrderedSet.luau` — bounded cursor sampling without changing existing iteration order.
- `src/server/OpenFront/Simulation.luau` — Stage 9 lifecycle, fair bot identity, solo admission, stats exclusion and bot scheduling.
- `src/server/OpenFront/FoundationServer.luau` — bot configuration passthrough and profiling attributes.
- `src/server/OpenFront/Match.luau` — bot identity in authoritative rankings/history.
- `src/shared/Config.luau` — Stage 9 enabled; five Normal bots by default.
- `src/shared/OpenFront/EarthTerrain.luau` — constant-time LRU eviction and bounded server cache configuration; exact terrain bytes unchanged.
- `src/client/MatchHUD.luau` — `[BOT]` label on the existing leaderboard/results.
- `scripts/check_stage1.py`, `check_stage7.py` — load new dependencies while retaining historical baseline loading.
- `scripts/check_stage9.py`, `bot_checks.luau` — rules, advanced gameplay, lifecycle, server/replica and repeated compact-load tests.
- `scripts/generate_bot_oracle.mjs`, `tests/stage9/*` — executed original upstream fixtures and source hashes.
- `scripts/benchmark_bots.py`, `bot_benchmark.luau`, `report_stage9.py` — repeated actual-Earth measurements and report generation.
- `scripts/package_stage9.py` — verified Rojo candidate and per-source manifest.
- `docs/STAGE9_IMPLEMENTATION.md`, `STAGE9_PERFORMANCE.md`, `STAGE9_CHANGED_FILES.md`, `README.md`, `NOTICE` — configuration, mapping, deviations, acceptance steps and notices.

No new image, font, audio or model assets. Existing map transforms, GUI shell and human gameplay APIs are retained. Generated build artifacts, manifests and measurements are under `build/`.
