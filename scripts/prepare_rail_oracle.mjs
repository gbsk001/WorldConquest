// Mechanically extracted pinned upstream rail implementation for differential tests.
import fs from 'node:fs/promises';import crypto from 'node:crypto';import {stripTypeScriptTypes} from 'node:module';
const root=new URL('../',import.meta.url),hashes={};
const audit=JSON.parse(await fs.readFile(new URL('docs/openfront-audit-manifest.json',root),'utf8'));
let prior={};try{prior=JSON.parse(await fs.readFile(new URL('tests/stage5/rail-source-hashes.json',root),'utf8')).files;}catch(e){if(e.code!=='ENOENT')throw e;}
async function read(p){const s=await fs.readFile(new URL('build/OpenFrontIO/'+p,root),'utf8');hashes[p]=crypto.createHash('sha256').update(s).digest('hex');const expected=prior[p]??audit.upstream_files[p];if(expected&&expected!==hashes[p])throw Error('Pinned source changed: '+p);return s;}
function noImports(s){return s.replace(/^import[\s\S]*?;\s*/gm,'');}
function method(s,name){const re=new RegExp('^  (?:(?:private|public|override) )?'+name+'(?:<[^>]*>)?\\(','m'),start=s.search(re);if(start<0)throw Error(name);let pos=s.indexOf('{',start),depth=1;for(let i=pos+1;i<s.length;i++){if(s[i]==='{')depth++;else if(s[i]==='}'&&--depth===0)return s.slice(start,i+1);}throw Error(name);}
function cls(s,name){const start=s.indexOf('export class '+name);return s.slice(start,s.indexOf('  snapshot(',start))+'}\n';}
let out=`import {exp} from './stage1-verified-upstream.mjs';const UnitType=new Proxy({}, {get:(_,k)=>k}),TrainType=UnitType,GameUpdateType=UnitType;const DebugSpan={wrap:(_,f)=>f()};const within=(v,a,b)=>Math.max(a,Math.min(b,v));const toInt=(n)=>BigInt(Math.floor(n));const sigmoid=(v,d,m)=>1/(1+exp(-d*(v-m)));\n`;
out+=noImports(await read('packages/engine-lib/src/PseudoRandom.ts'))+'\n';
out+=noImports(await read('packages/engine/src/pathfinding/algorithms/PriorityQueue.ts'))+'\n';
out+=noImports(await read('packages/engine/src/pathfinding/algorithms/AStar.ts'))+'\n';
out+=noImports(await read('packages/engine/src/pathfinding/algorithms/AStar.Rail.ts'))+'\n';
out+=noImports(await read('packages/engine/src/pathfinding/PathFinder.Station.ts'))+'\n';
out+=noImports(await read('packages/engine-lib/src/game/UnitGrid.ts'))+'\n';
out+=noImports(await read('packages/engine/src/game/RailroadSpatialGrid.ts'))+'\n';
const railroad=await read('packages/engine/src/game/Railroad.ts');out+=cls(railroad,'Railroad');out+=railroad.slice(railroad.indexOf('export function getOrientedRailroad'));
const station=await read('packages/engine/src/game/TrainStation.ts');out+=station.slice(station.indexOf('interface TrainStopHandler'),station.indexOf('export class TrainStation'));out+=cls(station,'TrainStation')+cls(station,'Cluster');out+=station.slice(station.indexOf('\nfunction rel('));
for(const name of ['CityExecution','FactoryExecution','TrainStationExecution','TrainExecution','RecomputeRailClusterExecution','ConstructionExecution'])out+=cls(await read('packages/engine/src/execution/'+name+'.ts'),name);
const network=await read('packages/engine/src/game/RailNetworkImpl.ts');
out+='export class StationManagerImpl {stations=new Set();stationsById=[];stationsByUnit=new Map();nextId=1;\n'+['addStation','removeStation','findStation','getAll','getById','count','rebuildStationsByUnit'].map(n=>method(network.slice(network.indexOf('export class StationManagerImpl')),n)).join('\n')+'}\n';
out+='export class RailNetworkImpl {maxConnectionDistance=4;stationRadius=3;gridCellSize=4;nextId=0;dirtyClusters=new Set();networkVersion=0;\nconstructor(game,manager,pathService){this.game=game;this._stationManager=manager;this.pathService=pathService;this.railGrid=new RailSpatialGrid(game,4);}\n';
out+=['stationManager','connectStation','recomputeClusters','removeStation','findStationsPath','connectToExistingRails','connectToNearbyStations','disconnectFromNetwork','deleteCluster','connectWithPath','validRailPath','planNearbyConnections','stationsWithin','computeCluster','mergeClusters'].map(n=>method(network.slice(network.indexOf('export class RailNetworkImpl')),n)).join('\n')+'}\n';
const engine=await read('packages/engine/src/configuration/EngineConfig.ts');
out+='export class Rules {goldMultiplierFor(p){return p.multiplier??1;}trainStationMaxRange(){return 110;}\n'+['trainSaturation','trainSpawnRate','smallEconomySpawnBoost','trainGold','trainStationMinRange','railroadMaxSize'].map(n=>method(engine,n)).join('\n')+'}\n';
await fs.writeFile(new URL('build/rail-upstream.ts',root),out);
await fs.writeFile(new URL('build/rail-upstream.mjs',root),stripTypeScriptTypes(out,{mode:'transform'}));
await fs.writeFile(new URL('tests/stage5/rail-source-hashes.json',root),JSON.stringify({commit:'8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94',files:hashes},null,2));
export const summary='Original rail graph, spatial queries, A*, train executors and trade formulas extracted.';
