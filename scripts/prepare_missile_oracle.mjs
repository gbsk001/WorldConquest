// Execute original pinned upstream algorithms, replacing platform imports only.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import {stripTypeScriptTypes} from 'node:module';
const root=new URL('../',import.meta.url),hashes={};
const previous=JSON.parse(await fs.readFile(new URL('tests/stage8/source-hashes.json',root),'utf8'));
async function read(p){let s=await fs.readFile(new URL('build/OpenFrontIO/'+p,root),'utf8');hashes[p]=crypto.createHash('sha256').update(s).digest('hex');if(previous.files[p]&&previous.files[p]!==hashes[p])throw Error('Pinned source changed: '+p);return s;}
function clean(s){return s.replace(/^import[\s\S]*?;\s*/gm,'');}
function method(s,name){let start=s.search(new RegExp('^  (?:(?:private|public|override) )?'+name+'\\(','m'));if(start<0)throw Error(name);let pos=s.indexOf('{',start),depth=1;for(let i=pos+1;i<s.length;i++){if(s[i]==='{')depth++;else if(s[i]==='}'&&--depth===0)return s.slice(start,i+1);}throw Error(name);}
let out=`import {exp} from './stage1-verified-upstream.mjs';const UnitType=new Proxy({}, {get:(_,k)=>k}),PathStatus=UnitType;const TileSet=Set;const within=(v,a,b)=>Math.min(Math.max(v,a),b);const PERCENT_TILES_OWNED_TO_WIN=80;\n`;
out+=clean(await read('packages/engine/src/utilities/Line.ts'));
out+=clean(await read('packages/engine/src/pathfinding/PathFinder.Parabola.ts'));
out+=clean(await read('packages/engine-lib/src/PseudoRandom.ts'));
let config=await read('packages/engine-lib/src/configuration/Config.ts'),engine=await read('packages/engine/src/configuration/EngineConfig.ts');
out+='export class Rules{_gameConfig={};overtimeConfig(){return this.overtime??{enabled:false};}waterNukes(){return false;}\n'+['nukeMagnitudes','samRange','maxSamRange','SAMCooldown','percentageTilesOwnedToWinTenths'].map(n=>method(config,n)).join('\n')+['nukeDeathFactor','nukeSpeed','mirvNormalizeTargetTicks','dynamicSamRange','samUpgradeDuration','defaultNukeTargetableRange'].map(n=>method(engine,n)).join('\n')+'}\n';
let mirv=await read('packages/engine/src/execution/MIRVExecution.ts');
const util=await read('packages/engine-lib/src/Util.ts');out+=util.slice(util.indexOf('export function simpleHash('),util.indexOf('\n}',util.indexOf('export function simpleHash('))+2)+'\n';
out+='const MessageType=UnitType;const UniversalPathFinding={Parabola:(g,o)=>new ParabolaUniversalPathFinder(g,o)};class NukeExecution{constructor(...args){this.args=args;}cancel(){this.cancelled=true;}}\n';
out+=mirv.slice(mirv.indexOf('export class MirvExecution'),mirv.indexOf('  snapshot('))+'}\n';
let nuke=await read('packages/engine/src/execution/NukeExecution.ts');
out+='export class Blast{'+method(nuke,'tilesToDestroy')+'}\n';
let sam=await read('packages/engine/src/execution/SAMLauncherExecution.ts');
out+='export class SAMPlan{missileSpeed=12;'+['tickToReach','checkDetonationInterception','isTargetableAt','computeInterceptionTile'].map(n=>method(sam,n)).join('\n')+'}\n';
let map=await read('packages/engine-lib/src/game/GameMapImpl.ts');
out+='export class MapBFS{'+['bfs','bfsSearch','tryPushNeighbor','expandNeighbors','bumpBfsGeneration'].map(n=>method(map,n)).join('\n')+'}\n';
for(const p of ['SAMLauncherExecution','SAMMissileExecution','MissileSiloExecution','WinCheckExecution'])await read('packages/engine/src/execution/'+p+'.ts');
await fs.mkdir(new URL('tests/stage8/',root),{recursive:true});
await fs.writeFile(new URL('build/missile-upstream.mjs',root),stripTypeScriptTypes(out,{mode:'transform'}));
await fs.writeFile(new URL('tests/stage8/source-hashes.json',root),JSON.stringify({commit:'8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94',files:hashes},null,2));
export const summary='Original curve, MIRV speed, blast BFS, casualty, SAM range and threshold methods extracted.';
