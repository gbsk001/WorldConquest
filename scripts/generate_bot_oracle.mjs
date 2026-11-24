// Execute pinned original TypeScript methods, stripping types only.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import {stripTypeScriptTypes} from 'node:module';
const root=new URL('../',import.meta.url),files={};
async function read(p){const s=await fs.readFile(new URL('build/OpenFrontIO/'+p,root),'utf8');files[p]=crypto.createHash('sha256').update(s).digest('hex');return s;}
function block(s,start){let at=s.indexOf('{',start),depth=1;for(let i=at+1;i<s.length;i++){if(s[i]==='{')depth++;else if(s[i]==='}'&&--depth===0)return s.slice(start,i+1);}throw Error('unterminated');}
function method(s,name){const start=s.search(new RegExp('^  (?:(?:private|public|override) )?'+name+'\\(','m'));if(start<0)throw Error(name);return block(s,start);}
const nation=await read('packages/engine/src/execution/NationExecution.ts');
const random=await read('packages/engine-lib/src/PseudoRandom.ts');
const util=await read('packages/engine-lib/src/Util.ts');
const planning=await read('packages/engine/src/execution/nation/NationNukePlanning.ts');
const attack=await read('packages/engine/src/execution/nation/NationAttackBehavior.ts');
await read('packages/engine/src/execution/utils/AiAttackBehavior.ts');await read('packages/engine/src/execution/nation/NationStructureBehavior.ts');
let code='const Difficulty={Easy:"Easy",Medium:"Normal",Hard:"Hard",Impossible:"Impossible"};const assertNever=()=>{throw Error("difficulty")};\n'+random+'\n'+block(util,util.indexOf('export function simpleHash('));
code+='\nexport class Nation{'+method(nation,'constructor').replaceAll('private ','')+method(nation,'getAttackRate')+'}\n';
for(const name of ['enemyLandBlastCoverage','blastHitsFriendlyLand'])code+=block(planning,planning.indexOf('export function '+name+'('))+'\n';
const out=new URL('build/bot-upstream.mjs',root);await fs.writeFile(out,stripTypeScriptTypes(code,{mode:'transform'}));
const upstream=await import(out.href+'?generation='+Date.now());
const personalities=[];
for(const difficulty of ['Easy','Normal','Hard'])for(let seed=1;seed<=100;seed++){
 const bot=new upstream.Nation(String(seed),{playerInfo:{id:String(-1000001)}});bot.mg={config:()=>({gameConfig:()=>({difficulty})})};
 const rate=bot.getAttackRate();const offset=bot.random.nextInt(0,rate);
 personalities.push({difficulty,seed,trigger:bot.triggerRatio,reserve:bot.reserveRatio,expand:bot.expandRatio,rate,offset});
}
const coverage=[];
for(let scenario=0;scenario<30;scenario++){
 const size=160,center=80*size+80,inner=scenario%2?80:12,outer=scenario%2?100:30;
 const ownerId=t=>(t*17+Math.floor(t/size)*scenario)%11;
 const owner=id=>({isPlayer:()=>id>0,id});const player={isFriendly:p=>p.id===1||p.id===2};
 const game={config:()=>({nukeMagnitudes:()=>({inner,outer})}),x:t=>t%size,y:t=>Math.floor(t/size),isValidCoord:(x,y)=>x>=0&&y>=0&&x<size&&y<size,ref:(x,y)=>y*size+x,owner:t=>owner(ownerId(t)),ownerID:ownerId,players:()=>Array.from({length:10},(_,i)=>({...owner(i+1),smallID:()=>i+1}))};
 coverage.push({scenario,inner,outer,coverage:upstream.enemyLandBlastCoverage(game,player,center,'AtomBomb'),friendly:upstream.blastHitsFriendlyLand(game,player,center,'AtomBomb')});
}
await fs.mkdir(new URL('tests/stage9/',root),{recursive:true});
await fs.writeFile(new URL('tests/stage9/upstream-oracle.json',root),JSON.stringify({personalities,coverage}));
await fs.writeFile(new URL('tests/stage9/source-hashes.json',root),JSON.stringify({commit:'8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94',files},null,2));
export const summary={personalities:personalities.length,coverage:coverage.length};
