// Extract the pinned upstream implementations; imports/platform adapters only are replaced.
import fs from 'node:fs/promises';import crypto from 'node:crypto';import {stripTypeScriptTypes} from 'node:module';
const root=new URL('../',import.meta.url),hashes={};
const audit=JSON.parse(await fs.readFile(new URL('docs/openfront-audit-manifest.json',root),'utf8'));
let prior={};try{prior=JSON.parse(await fs.readFile(new URL('tests/stage6/source-hashes.json',root),'utf8')).files;}catch(e){if(e.code!=='ENOENT')throw e;}
async function read(p){const s=await fs.readFile(new URL('build/OpenFrontIO/'+p,root),'utf8');hashes[p]=crypto.createHash('sha256').update(s).digest('hex');if((prior[p]??audit.upstream_files[p])&&(prior[p]??audit.upstream_files[p])!==hashes[p])throw Error('Source changed '+p);return s;}
function clean(s){return s.replace(/^import[\s\S]*?;\s*/gm,'');}
function cls(s,name){const a=s.indexOf('export class '+name);return s.slice(a,s.indexOf('  snapshot(',a))+'}\n';}
function method(s,name){const re=new RegExp('^  (?:(?:private|public|override) )?'+name+'(?:<[^>]*>)?\\(','m'),start=s.search(re);if(start<0)throw Error(name);let pos=s.indexOf('{',start),depth=1;for(let i=pos+1;i<s.length;i++){if(s[i]==='{')depth++;else if(s[i]==='}'&&--depth===0)return s.slice(start,i+1);}throw Error(name);}
let out=`import {exp} from './stage1-verified-upstream.mjs';const UnitType=new Proxy({}, {get:(_,k)=>k}),PlayerType=UnitType,MessageType=UnitType,PathStatus=UnitType;const DebugSpan={wrap:(_,f)=>f(),set(){}};const within=(v,a,b)=>Math.min(Math.max(v,a),b);const sigmoid=(v,d,m)=>1/(1+exp(-d*(v-m)));const isUnit=u=>typeof u.tile==='function';const findMinimumBy=(a,f,test=()=>true)=>{let best,score=Infinity;for(const v of a)if(test(v)&&f(v)<score){best=v;score=f(v);}return best;};const findClosestBy=(a,f,test)=>findMinimumBy(a,f,test)??null;const renderTroops=String,renderNumber=String;const malusForRetreat=25;const tileTraversalScratch=g=>g.scratch;const bumpTraversalGeneration=s=>++s.gen;const TrainStationExecution=class{};export class AttackExecution{constructor(...args){this.args=args;}};\n`;
out+=clean(await read('packages/engine-lib/src/PseudoRandom.ts'));
out+=clean(await read('packages/engine/src/pathfinding/algorithms/PriorityQueue.ts'));
out+=clean(await read('packages/engine/src/pathfinding/algorithms/AStar.Water.ts'));
let bounded=clean(await read('packages/engine/src/pathfinding/algorithms/AStar.WaterBounded.ts'));bounded=bounded.replace(/\b(LAND_BIT|MAGNITUDE_MASK|COST_SCALE|BASE_COST|getMagnitudePenalty)\b/g,'bounded_$1');out+=bounded;
out+=clean(await read('packages/engine/src/pathfinding/transformers/ShoreCoercingTransformer.ts'));
out+=clean(await read('packages/engine/src/pathfinding/PathFinder.Air.ts'));
out+=clean(await read('packages/engine/src/pathfinding/PathFinderStepper.ts'));
out+=clean(await read('packages/engine-lib/src/game/UnitGrid.ts'));
// The water-domain adapter uses the same full-resolution fallback as Luau, not upstream HPA/minimap.
out+=`export const PathFinding={Water:g=>new ShoreCoercingTransformer(new AStarWater(g),g),Air:g=>new PathFinderStepper(new AirPathFinder(g))};export class WaterPathFinder extends PathFinderStepper{constructor(g){super(PathFinding.Water(g),{equals:(a,b)=>a===b,distance:(a,b)=>g.manhattanDist(a,b)});this.finder=PathFinding.Water(g);}findPath(a,b){return this.finder.findPath(a,b);}pathForTraversal(a,b){return this.findPath(a,b)??[a];}}\n`;
const spatial=clean(await read('packages/engine/src/pathfinding/spatial/SpatialQuery.ts'));out+=spatial;
out+=clean(await read('packages/engine/src/game/TransportShipUtils.ts'));
for(const n of ['TransportShipExecution','TradeShipExecution','PortExecution','WarshipExecution','ShellExecution','BoatRetreatExecution','MoveWarshipExecution'])out+=cls(await read('packages/engine/src/execution/'+n+'.ts'),n);
const engine=await read('packages/engine/src/configuration/EngineConfig.ts');
out+='export class Rules{goldMultiplierFor(p){return p.multiplier??1;}isUnitDisabled(){return false;}unitInfo(t){return {damage:250};}\n'+['boatMaxNumber','boatAttackAmount','tradeShipGold','tradeShipShortRangeDebuff','proximityBonusPortsNb','tradeShipSaturation','tradeShipSpawnRate','smallEconomySpawnBoost','warshipPatrolRange','warshipTargettingRange','warshipShellAttackRate','warshipDockingRange','warshipPortHealingBonusPerLevel','warshipRetreatHealthPercent','warshipPassiveHealing','warshipPassiveHealingRange','warshipPortSwitchThreshold','warshipMaxVeterancy','warshipVeterancyShellDamageBonus','warshipVeterancyTransportKills','warshipVeterancyTradeCaptures','shellLifetime'].map(n=>method(engine,n)).join('\n')+'}\n';
const unit=await read('packages/engine/src/game/UnitImpl.ts');out+='export class Veteran {constructor(rules){this.mg={config:()=>rules,addUpdate(){}};this._warshipState={veterancy:0,veterancyProgress:0};}toUpdate(){}\n'+['increaseVeterancy','recordKill','recordTradeCapture','addVeterancyProgress'].map(n=>method(unit,n)).join('\n')+'}\n';
for(const p of ['packages/engine/src/game/PlayerImpl.ts','packages/engine/src/execution/AttackExecution.ts','packages/engine/src/execution/PlayerExecution.ts','src/client/hud/layers/PlayerActionHandler.ts','packages/engine-api/src/Schemas.ts'])await read(p);
await fs.mkdir(new URL('tests/stage6/',root),{recursive:true});
await fs.writeFile(new URL('build/naval-upstream.ts',root),out);
await fs.writeFile(new URL('build/naval-upstream.mjs',root),stripTypeScriptTypes(out,{mode:'transform'}));
await fs.writeFile(new URL('tests/stage6/source-hashes.json',root),JSON.stringify({commit:'8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94',files:hashes},null,2));
export const summary='Pinned original naval executions, spatial query, routing and rules extracted.';
