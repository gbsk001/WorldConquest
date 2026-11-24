// Extract executable pinned source, never duplicate the expected algorithms.
import fs from 'node:fs/promises';import crypto from 'node:crypto';import {stripTypeScriptTypes} from 'node:module';
const root=new URL('../',import.meta.url),manifest=JSON.parse(await fs.readFile(new URL('docs/openfront-audit-manifest.json',root),'utf8'));
const hashes={};
let prior={};try{prior=JSON.parse(await fs.readFile(new URL('tests/stage5/source-hashes.json',root),'utf8')).files;}catch(e){if(e.code!=='ENOENT')throw e;}
async function read(p){const b=await fs.readFile(new URL('build/OpenFrontIO/'+p,root)),hash=crypto.createHash('sha256').update(b).digest('hex');const expected=prior[p]??manifest.upstream_files[p];if(expected&&hash!==expected)throw Error(p+' hash mismatch');hashes[p]=hash;return b.toString();}
function method(text,name){const re=new RegExp('^  (?:(?:private|public|override) )?'+name+'\\(','m'),start=text.search(re);if(start<0)throw Error(name);let pos=text.indexOf('{',start),depth=1;for(let i=pos+1;i<text.length;i++){if(text[i]==='{')depth++;else if(text[i]==='}'&&--depth===0)return text.slice(start,i+1);}throw Error(name+' unclosed');}
const config=await read('packages/engine-lib/src/configuration/Config.ts'),engine=await read('packages/engine/src/configuration/EngineConfig.ts'),player=await read('packages/engine/src/game/PlayerImpl.ts');
const configMethods=['unitInfo','instantBuild','isUnitDisabled','defensePostRange','structureMinDist','deleteUnitCooldown','deletionMarkDuration'].map(n=>method(config,n)).join('\n');
const engineMethods=['unitCost','costWrapper','infiniteGold','hasInfiniteGoldFor'].map(n=>method(engine,n)).join('\n');
const playerMethods=['validStructureSpawnTiles','landBasedStructureSpawn','portSpawn','unitsOwned','unitsConstructed','canUpgradeUnit','canUpgradeUnitType','canBuildUnitType','isUnitValidToUpgrade','canDeleteUnit','recordDeleteUnit'].map(n=>method(player,n)).join('\n');
let program=`import {pow2} from './stage1-verified-upstream.mjs';
export const UnitType=new Proxy({}, {get:(_,k)=>k});const PlayerType={Human:'Human'};${config.match(/export const SAM_CONSTRUCTION_TICKS[^;]+;/)[0]}
const Structures={types:['City','Factory','Port','DefensePost','SAMLauncher','MissileSilo']};
const assertNever=(v)=>{throw Error(v)};
const tileTraversalScratch=(mg)=>mg.scratch;const bumpTraversalGeneration=(s)=>++s.gen;
export class Rules {unitInfoCache=new Map(); _gameConfig={}; ${configMethods}\n${engineMethods}}
export class Player {${playerMethods}}
`;
// Constructor and lifecycle are used verbatim up to snapshot serialization.
for(const name of ['ConstructionExecution','UpgradeStructureExecution','DeleteUnitExecution']){
 const src=await read('packages/engine/src/execution/'+name+'.ts');const start=src.indexOf('export class '+name),end=src.indexOf('  snapshot(',start);
 program+=src.slice(start,end)+'}\n';
}
program+=`const CityExecution=class {},DefensePostExecution=class {},FactoryExecution=class {},PortExecution=class {},MissileSiloExecution=class {},SAMLauncherExecution=class {},TransportShipExecution=class {},TradeShipExecution=class {},WarshipExecution=class {},NukeExecution=class {},MessageType={};`;
await fs.writeFile(new URL('build/buildings-upstream.mjs',root),stripTypeScriptTypes(program,{mode:'transform'}));
await fs.mkdir(new URL('tests/stage5/',root),{recursive:true});
await fs.writeFile(new URL('tests/stage5/source-hashes.json',root),JSON.stringify({commit:manifest.commit,files:hashes},null,2));
export const summary='Pinned building price, placement, validation and execution methods extracted.';
