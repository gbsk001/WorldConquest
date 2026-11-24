# Stage 8 changed files

Cumulative production differences against the saved pre-Stage-8 source tree (`build/stage8-baseline/src`); this workspace has no Git metadata. “New” means absent from that snapshot.

- `src/client/BuildingShop.luau`
- `src/client/IconLayer.luau`
- `src/client/Main.client.luau`
- `src/client/MapView.luau`
- `src/client/MatchHUD.luau` (new)
- `src/client/MissileControls.luau` (new)
- `src/client/NavalControls.luau`
- `src/client/OwnershipRaster.luau`
- `src/client/StrategyUI.luau` (new)
- `src/server/OpenFront/Buildings.luau`
- `src/server/OpenFront/Expansion.luau`
- `src/server/OpenFront/FoundationServer.luau`
- `src/server/OpenFront/Match.luau` (new)
- `src/server/OpenFront/Missiles.luau` (new)
- `src/server/OpenFront/Naval.luau`
- `src/server/OpenFront/OrderedSet.luau`
- `src/server/OpenFront/Rail.luau`
- `src/server/OpenFront/Simulation.luau`
- `src/shared/Config.luau`
- `src/shared/OpenFront/BuildingRules.luau`
- `src/shared/OpenFront/BuildingWire.luau`
- `src/shared/OpenFront/EarthTerrain.luau`
- `src/shared/OpenFront/Grid.luau`
- `src/shared/OpenFront/MissilePath.luau` (new)
- `src/shared/OpenFront/MissileRules.luau` (new)
- `src/shared/OpenFront/Replica.luau`
- `src/shared/OpenFront/ShipWire.luau`

Final acceptance changes specifically touch Grid (batched page access and optional uniform encoding), Missiles (geometry stencil/interior handling), FoundationServer (encoded fragments/byte metric), Replica (decode before atomic application), scripts/missile_checks.luau (codec/recovery regressions), scripts/stage8_benchmark.luau and scripts/benchmark_stage8.py (encoding timing and repeated measurements).

Reproduction/package documentation: scripts/package_stage8.py, scripts/report_stage8_acceptance.py, docs/FINAL_TECHNICAL_ACCEPTANCE.md, docs/STAGE8_IMPLEMENTATION.md, docs/STAGE8_STUDIO_CHECKLIST.md, docs/STAGE8_CHANGED_FILES.md, docs/OPENFRONT_SOURCE_INDEX.md, README.md and NOTICE. Stage 8 oracle generators, regression harnesses and tests/stage8 fixtures are retained. Latest measurements, suite logs, verified Rojo artifact and source-hash manifest are under build/.
