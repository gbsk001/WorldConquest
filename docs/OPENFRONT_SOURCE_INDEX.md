# Pinned OpenFront source reference

Commit: `8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94`. Links remain fixed even if main changes. This is a navigation index, not a claim that all referenced tests were executed or every branch reviewed. See [plan](OPENFRONT_PORT_PLAN.md).

## Grid, maps, deterministic primitives

- [packages/engine-lib/src/game/GameMapImpl.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/game/GameMapImpl.ts)
- [packages/engine-lib/src/game/TerrainMapLoader.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/game/TerrainMapLoader.ts)
- [packages/engine-lib/src/game/TileSet.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/game/TileSet.ts)
- [packages/engine-lib/src/PseudoRandom.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/PseudoRandom.ts)
- [packages/engine-lib/src/DetMath.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/DetMath.ts)
- [packages/engine-lib/src/Util.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/Util.ts)
- [map-generator/map_generator.go](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/map-generator/map_generator.go)
- [map-generator/assets/maps/world/info.json](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/map-generator/assets/maps/world/info.json)

## Ticks, players, attacks, pockets

- [packages/engine/src/GameRunner.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/GameRunner.ts)
- [packages/engine/src/game/GameImpl.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/game/GameImpl.ts)
- [packages/engine/src/game/PlayerImpl.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/game/PlayerImpl.ts)
- [packages/engine/src/game/AttackImpl.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/game/AttackImpl.ts)
- [packages/engine/src/execution/AttackExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/AttackExecution.ts)
- [packages/engine/src/execution/PlayerExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/PlayerExecution.ts)
- [packages/engine/src/execution/RetreatExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/RetreatExecution.ts)
- [packages/engine/src/execution/SpawnExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/SpawnExecution.ts)
- [packages/engine/src/execution/SpawnTimerExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/SpawnTimerExecution.ts)
- [packages/engine/src/execution/WinCheckExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/WinCheckExecution.ts)
- [packages/engine/src/execution/Util.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/Util.ts)
- [packages/engine/src/execution/utils/FlatBinaryHeap.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/utils/FlatBinaryHeap.ts)

## Economy, buildings and naval

- [packages/engine/src/execution/ConstructionExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/ConstructionExecution.ts)
- [packages/engine/src/execution/UpgradeStructureExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/UpgradeStructureExecution.ts)
- [packages/engine/src/execution/CityExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/CityExecution.ts)
- [packages/engine/src/execution/FactoryExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/FactoryExecution.ts)
- [packages/engine/src/execution/PortExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/PortExecution.ts)
- [packages/engine/src/execution/TradeShipExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/TradeShipExecution.ts)
- [packages/engine/src/execution/TransportShipExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/TransportShipExecution.ts)
- [packages/engine/src/game/TransportShipUtils.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/game/TransportShipUtils.ts)
- [packages/engine/src/execution/WarshipExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/WarshipExecution.ts)
- [packages/engine/src/execution/TrainExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/TrainExecution.ts)
- [packages/engine/src/execution/TrainStationExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/TrainStationExecution.ts)
- [packages/engine/src/pathfinding/PathFinder.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/pathfinding/PathFinder.ts)
- [packages/engine/src/game/WaterManager.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/game/WaterManager.ts)

## AI entry points and dependencies

- [packages/engine/src/execution/TribeExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/TribeExecution.ts)
- [packages/engine/src/execution/TribeAttackBehavior.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/TribeAttackBehavior.ts)
- [packages/engine/src/execution/NationExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/NationExecution.ts)
- [packages/engine/src/execution/utils/AiAttackBehavior.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/utils/AiAttackBehavior.ts)
- [packages/engine/src/execution/nation/NationAttackBehavior.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/nation/NationAttackBehavior.ts)
- [packages/engine/src/execution/nation/NationStructureBehavior.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/nation/NationStructureBehavior.ts)
- [packages/engine/src/execution/nation/NationAllianceBehavior.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/nation/NationAllianceBehavior.ts)
- [packages/engine/src/execution/nation/NationWarshipBehavior.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/nation/NationWarshipBehavior.ts)
- [packages/engine/src/execution/nation/NationNukeBehavior.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/nation/NationNukeBehavior.ts)

## Rendering, UI, multiplayer

- [src/client/render/gl/passes/TerritoryPass.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/src/client/render/gl/passes/TerritoryPass.ts)
- [src/client/render/gl/passes/TerrainPass.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/src/client/render/gl/passes/TerrainPass.ts)
- [src/client/render/gl/shaders/border-compute/border-compute.frag.glsl](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/src/client/render/gl/shaders/border-compute/border-compute.frag.glsl)
- [src/client/hud/layers/ControlPanel.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/src/client/hud/layers/ControlPanel.ts)
- [src/client/hud/layers/BuildMenu.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/src/client/hud/layers/BuildMenu.ts)
- [src/client/WorkerClient.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/src/client/WorkerClient.ts)
- [src/client/ClientGameRunner.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/src/client/ClientGameRunner.ts)
- [src/server/GameServer.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/src/server/GameServer.ts)
- [src/server/Consensus.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/src/server/Consensus.ts)
- [src/server/IntentAuthorization.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/src/server/IntentAuthorization.ts)
- [packages/engine/src/snapshot/README.md](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/snapshot/README.md)

## Oracle fixtures to port and run

- [tests/AttackLogicGolden.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/AttackLogicGolden.test.ts)
- [tests/AttackScenarios.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/AttackScenarios.test.ts)
- [tests/Attack.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/Attack.test.ts)
- [tests/PseudoRandom.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/PseudoRandom.test.ts)
- [tests/core/DetMath.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/core/DetMath.test.ts)
- [tests/TradeTrainGolden.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/TradeTrainGolden.test.ts)
- [tests/TradeTrainScenarios.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/TradeTrainScenarios.test.ts)
- [tests/PortExecution.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/PortExecution.test.ts)
- [tests/ConquerGold.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/ConquerGold.test.ts)
- [tests/economy/ConstructionCost.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/economy/ConstructionCost.test.ts)
- [tests/economy/ConstructionGold.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/economy/ConstructionGold.test.ts)
- [tests/core/game/TransportShipUtils.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/core/game/TransportShipUtils.test.ts)
- [tests/core/executions/TransportShipExecution.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/core/executions/TransportShipExecution.test.ts)
- [tests/core/executions/LargestClusterRanking.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/core/executions/LargestClusterRanking.test.ts)
- [tests/core/executions/ClusterTerritories.test.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/tests/core/executions/ClusterTerritories.test.ts)

## Licensing

- [LICENSE](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/LICENSE)
- [LICENSE-ASSETS](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/LICENSE-ASSETS)
- [LICENSING.md](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/LICENSING.md)
- [CREDITS.md](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/CREDITS.md)
- [map-generator/assets/LICENSE](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/map-generator/assets/LICENSE)
- [resources/LICENSE](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/resources/LICENSE)
- [proprietary/LICENSE](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/proprietary/LICENSE)

## Balance method and constant index

Generated from the two actual configuration files at the pinned commit. Names and line links identify the source of all balance methods, including optional mechanics omitted from the first implementation stages. This is not a substitute for reading callers and overrides.

### packages/engine-lib/src/configuration/Config.ts

| Symbol | Source line |
| --- | --- |
| `DEFAULT_SPAWN_IMMUNITY_TICKS` | [L20](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L20) |
| `SAM_CONSTRUCTION_TICKS` | [L23](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L23) |
| `DOOMSDAY_CLOCK_DEFAULTS` | [L35](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L35) |
| `PERCENT_TILES_OWNED_TO_WIN` | [L74](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L74) |
| `OVERTIME_DEFAULTS` | [L81](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L81) |
| `constructor` | [L89](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L89) |
| `isReplay` | [L96](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L96) |
| `isIntentionalSpectator` | [L101](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L101) |
| `traitorDefenseDebuff` | [L105](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L105) |
| `traitorDuration` | [L108](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L108) |
| `doomsdayClockConfig` | [L113](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L113) |
| `overtimeConfig` | [L136](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L136) |
| `spawnImmunityDuration` | [L146](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L146) |
| `nationSpawnImmunityDuration` | [L151](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L151) |
| `hasExtendedSpawnImmunity` | [L154](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L154) |
| `gameConfig` | [L158](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L158) |
| `cityTroopIncrease` | [L162](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L162) |
| `msPerTick` | [L165](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L165) |
| `SAMCooldown` | [L168](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L168) |
| `SiloCooldown` | [L171](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L171) |
| `defensePostRange` | [L175](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L175) |
| `isUnitDisabled` | [L179](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L179) |
| `instantBuild` | [L182](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L182) |
| `disableAlliances` | [L185](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L185) |
| `isRandomSpawn` | [L193](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L193) |
| `infiniteTroops` | [L196](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L196) |
| `donateTroops` | [L199](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L199) |
| `trainStationMaxRange` | [L202](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L202) |
| `unitInfo` | [L206](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L206) |
| `hasInfiniteTroopsFor` | [L268](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L268) |
| `deletionMarkDuration` | [L275](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L275) |
| `deleteUnitCooldown` | [L279](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L279) |
| `allianceRequestDuration` | [L282](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L282) |
| `allianceDuration` | [L285](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L285) |
| `percentageTilesOwnedToWinTenths` | [L296](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L296) |
| `percentageTilesOwnedToWin` | [L319](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L319) |
| `armyLimitWarningThreshold` | [L322](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L322) |
| `numSpawnPhaseTurns` | [L325](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L325) |
| `maxTroops` | [L335](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L335) |
| `maxTroopsWithoutCities` | [L340](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L340) |
| `troopCap` | [L344](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L344) |
| `troopIncreaseRate` | [L385](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L385) |
| `nukeMagnitudes` | [L419](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L419) |
| `nukeAllianceBreakThreshold` | [L434](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L434) |
| `samRange` | [L438](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L438) |
| `maxSamRange` | [L443](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L443) |
| `structureMinDist` | [L447](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L447) |
| `warshipVeterancyHealthBonus` | [L453](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L453) |
| `allianceExtensionPromptOffset` | [L457](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts#L457) |

### packages/engine/src/configuration/EngineConfig.ts

| Symbol | Source line |
| --- | --- |
| `LARGE_TERRITORY_MIDPOINT` | [L58](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L58) |
| `LARGE_TERRITORY_STEEPNESS` | [L59](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L59) |
| `LARGE_ATTACKER_DEPTH` | [L62](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L62) |
| `LARGE_DEFENDER_DEPTH` | [L63](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L63) |
| `BOT_DEFENDER_LOSS_MULT` | [L64](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L64) |
| `TERRA_NULLIUS_COST_SCALE` | [L65](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L65) |
| `TERRA_NULLIUS_MIN_COST` | [L66](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L66) |
| `TERRA_NULLIUS_MAX_COST` | [L67](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L67) |
| `ATTACKER_LOSS_BASE` | [L73](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L73) |
| `CHEAPEST_TROOP_RATIO` | [L75](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L75) |
| `ATTACKER_LOSS_PER_DENSITY` | [L76](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L76) |
| `SPEED_COST_DIVISOR` | [L80](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L80) |
| `LARGE_ATTACKER_SPEED_DEPTH` | [L85](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L85) |
| `traitorSpeedDebuff` | [L128](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L128) |
| `teamLandShareWinThresholdTenths` | [L132](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L132) |
| `setDifficulty` | [L136](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L136) |
| `setGameType` | [L140](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L140) |
| `falloutDefenseModifier` | [L144](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L144) |
| `defensePostDefenseBonus` | [L150](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L150) |
| `defensePostSpeedBonus` | [L154](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L154) |
| `playerTeams` | [L158](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L158) |
| `spawnNations` | [L162](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L162) |
| `bots` | [L166](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L166) |
| `disableNavMesh` | [L169](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L169) |
| `waterNukes` | [L172](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L172) |
| `infiniteGold` | [L175](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L175) |
| `donateGold` | [L178](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L178) |
| `goldMultiplier` | [L181](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L181) |
| `startingGold` | [L184](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L184) |
| `trainSaturation` | [L215](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L215) |
| `trainSpawnRate` | [L221](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L221) |
| `smallEconomySpawnBoost` | [L239](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L239) |
| `trainGold` | [L244](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L244) |
| `trainStationMinRange` | [L269](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L269) |
| `railroadMaxSize` | [L272](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L272) |
| `tradeShipGold` | [L276](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L276) |
| `tradeShipSaturation` | [L304](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L304) |
| `tradeShipSpawnRate` | [L311](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L311) |
| `hasInfiniteGoldFor` | [L331](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L331) |
| `unitInfo` | [L337](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L337) |
| `unitCost` | [L347](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L347) |
| `hasInfiniteTroopsForInfo` | [L409](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L409) |
| `goldMultiplierFor` | [L417](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L417) |
| `conquerGoldAmount` | [L426](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L426) |
| `startingGoldFor` | [L437](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L437) |
| `costWrapper` | [L446](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L446) |
| `defaultDonationAmount` | [L467](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L467) |
| `donateCooldown` | [L470](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L470) |
| `embargoAllCooldown` | [L473](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L473) |
| `emojiMessageDuration` | [L476](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L476) |
| `emojiMessageWindow` | [L480](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L480) |
| `emojiMessageLimit` | [L487](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L487) |
| `quickChatCooldown` | [L490](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L490) |
| `targetDuration` | [L493](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L493) |
| `targetCooldown` | [L496](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L496) |
| `allianceRequestCooldown` | [L499](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L499) |
| `temporaryEmbargoDuration` | [L502](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L502) |
| `minDistanceBetweenPlayers` | [L505](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L505) |
| `boatMaxNumber` | [L508](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L508) |
| `numBots` | [L514](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L514) |
| `attackLogic` | [L531](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L531) |
| `boatAttackAmount` | [L624](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L624) |
| `warshipShellLifetime` | [L631](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L631) |
| `tradeShipShortRangeDebuff` | [L635](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L635) |
| `proximityBonusPortsNb` | [L639](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L639) |
| `attackAmount` | [L643](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L643) |
| `startManpower` | [L651](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L651) |
| `goldAdditionRate` | [L675](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L675) |
| `nukeSpeed` | [L686](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L686) |
| `mirvNormalizeTargetTicks` | [L699](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L699) |
| `defaultNukeTargetableRange` | [L703](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L703) |
| `defaultSamRange` | [L707](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L707) |
| `samUpgradeDuration` | [L711](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L711) |
| `dynamicSamRange` | [L715](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L715) |
| `defaultSamMissileSpeed` | [L730](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L730) |
| `nukeDeathFactor` | [L735](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L735) |
| `shellLifetime` | [L753](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L753) |
| `warshipPatrolRange` | [L757](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L757) |
| `warshipTargettingRange` | [L761](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L761) |
| `warshipShellAttackRate` | [L765](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L765) |
| `warshipDockingRange` | [L769](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L769) |
| `warshipPortHealingBonusPerLevel` | [L773](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L773) |
| `warshipRetreatHealthPercent` | [L779](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L779) |
| `warshipPassiveHealing` | [L783](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L783) |
| `warshipPassiveHealingRange` | [L787](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L787) |
| `warshipPortSwitchThreshold` | [L791](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L791) |
| `warshipMaxVeterancy` | [L798](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L798) |
| `warshipVeterancyShellDamageBonus` | [L804](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L804) |
| `warshipVeterancyTransportKills` | [L809](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L809) |
| `warshipVeterancyTradeCaptures` | [L814](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L814) |
| `defensePostShellAttackRate` | [L818](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L818) |
| `safeFromPiratesCooldownMax` | [L822](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L822) |
| `defensePostTargettingRange` | [L826](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts#L826) |


## Implemented connectivity update — 2026-11-18

PlayerExecution.ts and TileTraversalScratch.ts map to src/server/OpenFront/Connectivity.luau
and Simulation.luau scheduling. See STAGE3_CONNECTIVITY_ACCEPTANCE.md for the method
mapping and actual-source oracle tests. Source revision remains 8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94.

## Stage 4 implementation mapping - 2026-11-18

EngineConfig.ts goldMultiplierFor/startingGoldFor/goldAdditionRate/conquerGoldAmount,
PlayerImpl.ts addGold/removeGold/canDonateGold/donateGold, GameImpl.conquerPlayer and
StatsImpl attack/cancel accounting map to Economy.luau and simulation conquest hooks.
Format.ts renderNumber maps to MoneyFormat.luau. See STAGE4_IMPLEMENTATION.md and
the hash-checked prepare_economy_oracle.mjs for exact implemented method coverage.

## Stage 5 implementation references

Pinned executable extraction hashes: `tests/stage5/source-hashes.json` and
`tests/stage5/rail-source-hashes.json`. See [the implementation report](STAGE5_IMPLEMENTATION.md).

- [packages/engine-lib/src/PseudoRandom.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/PseudoRandom.ts)
- [packages/engine-lib/src/configuration/Config.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts)
- [packages/engine-lib/src/game/UnitGrid.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/game/UnitGrid.ts)
- [packages/engine/src/configuration/EngineConfig.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts)
- [packages/engine/src/execution/CityExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/CityExecution.ts)
- [packages/engine/src/execution/ConstructionExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/ConstructionExecution.ts)
- [packages/engine/src/execution/DeleteUnitExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/DeleteUnitExecution.ts)
- [packages/engine/src/execution/FactoryExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/FactoryExecution.ts)
- [packages/engine/src/execution/RecomputeRailClusterExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/RecomputeRailClusterExecution.ts)
- [packages/engine/src/execution/TrainExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/TrainExecution.ts)
- [packages/engine/src/execution/TrainStationExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/TrainStationExecution.ts)
- [packages/engine/src/execution/UpgradeStructureExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/UpgradeStructureExecution.ts)
- [packages/engine/src/game/PlayerImpl.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/game/PlayerImpl.ts)
- [packages/engine/src/game/RailNetworkImpl.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/game/RailNetworkImpl.ts)
- [packages/engine/src/game/Railroad.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/game/Railroad.ts)
- [packages/engine/src/game/RailroadSpatialGrid.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/game/RailroadSpatialGrid.ts)
- [packages/engine/src/game/TrainStation.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/game/TrainStation.ts)
- [packages/engine/src/pathfinding/PathFinder.Station.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/pathfinding/PathFinder.Station.ts)
- [packages/engine/src/pathfinding/algorithms/AStar.Rail.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/pathfinding/algorithms/AStar.Rail.ts)
- [packages/engine/src/pathfinding/algorithms/AStar.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/pathfinding/algorithms/AStar.ts)
- [packages/engine/src/pathfinding/algorithms/PriorityQueue.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/pathfinding/algorithms/PriorityQueue.ts)

## Stage 6 implementation and fixtures

See [Stage 6 source-to-Luau mapping](STAGE6_IMPLEMENTATION.md), `tests/stage6/source-hashes.json`, and `scripts/prepare_naval_oracle.mjs`. The executable naval oracle uses original TypeScript execution classes with a documented full-resolution routing adapter, not the native HPA/minimap pipeline.

## Stage 8 and technical acceptance

See [Stage 8 mapping and formulas](STAGE8_IMPLEMENTATION.md),
[technical acceptance](FINAL_TECHNICAL_ACCEPTANCE.md),
`tests/stage8/source-hashes.json` and `scripts/prepare_missile_oracle.mjs`.
The pinned NukeExecution, MIRVExecution, SAMLauncherExecution,
SAMMissileExecution, MissileSiloExecution, WinCheckExecution, Line and Parabola
sources supply the rules. `scripts/verify_stage8_oracle.mjs` verifies executable
fixture regeneration. Roblox lifecycle, UI and transport adaptations and
unsupported upstream modes are explicitly documented in the report.
