// Run verify_stage1_oracle.mjs, prepare_stage2_oracle.py, then this file.
// The map/player adapters supply data; actual upstream AttackExecution makes decisions.
import fs from 'node:fs/promises';
import {Rules,AttackExecution} from '../build/stage2-upstream.mjs';
const rules=new Rules();
rules._gameConfig={difficulty:'Hard'};
const curves=[];
for(const land of [1,52,1000,1000000]){
 let reserve=25000;const values=[];
 const p={units:()=>[],type:()=>'Human',numTilesOwned:()=>land,troops:()=>reserve};
 for(let tick=0;tick<250;tick++){const growth=rules.troopIncreaseRate(p);reserve+=growth<0?-Math.floor(-growth):Math.floor(growth);values.push(reserve);}
 curves.push({land,cap:rules.maxTroops(p),values});
}
const costs=[];
for(const terrain of ['Plains','Highland','Mountain'])for(const stack of [1,16,1000,5000,25000])for(const border of [1,7,50]){
 const result=rules.attackLogic({terrain,attackTroops:stack,attacker:{type:'Human',numTiles:52},defender:null,defenderHasDefensePost:false,falloutRatio:null,borderSize:border});
 costs.push({terrain,stack,border,loss:result.attackerTroopLoss,fraction:result.tickFraction});
}
const width=48,height=32,owners=new Uint16Array(width*height),changes=[],borders=new Set();
const neighbors=(ref,out)=>{let n=0,x=ref%width;if(ref>=width)out[n++]=ref-width;if(ref<(height-1)*width)out[n++]=ref+width;if(x)out[n++]=ref-1;if(x!==width-1)out[n++]=ref+1;return n;};
const land=t=>t%width!==24; // uncrossable vertical water barrier
const terrain=t=>t%13===0?'Impassable':t%3===0?'Mountain':t%3===1?'Highland':'Plains';
const map={neighbors4:neighbors,ownerID:t=>owners[t],isLand:land,isWater:t=>!land(t),isImpassable:t=>terrain(t)==='Impassable',terrainType:terrain};
const update=t=>{if(owners[t]!==1)return;const nb=[];const n=neighbors(t,nb);if(nb.slice(0,n).some(t=>owners[t]!==1))borders.add(t);else borders.delete(t);};
let reserve=25000,attacks=[],tick=0;
const target={id:()=>null,smallID:()=>0,isPlayer:()=>false};
const player={smallID:()=>1,type:()=>'Human',id:()=>1,numTilesOwned:()=>owners.reduce((a,b)=>a+(b===1),0),
 troops:()=>reserve,removeTroops:n=>{const v=Math.min(reserve,Math.floor(n));reserve-=v;return v;},addTroops:n=>{reserve+=Math.floor(n);},
 borderTiles:()=>borders,incomingAttacks:()=>[],outgoingAttacks:()=>attacks,
 conquer:t=>{owners[t]=1;update(t);const nb=[];neighbors(t,nb);for(const t of nb)update(t);changes.push(t);},
 createAttack:(_,troops)=>{const set=new Set();const a={active:true,value:troops,troops:()=>a.value,setTroops:v=>{a.value=Math.max(0,v);},target:()=>target,sourceTile:()=>null,
 borderSize:()=>set.size,clearBorder:()=>set.clear(),addBorderTile:t=>set.add(t),removeBorderTile:t=>set.delete(t),
 isActive:()=>a.active,retreated:()=>false,retreating:()=>false,delete:()=>{a.active=false;attacks=attacks.filter(x=>x!==a);}};attacks.push(a);return a;}};
const game={map:()=>map,terraNullius:()=>target,config:()=>rules,ticks:()=>tick,hasFallout:()=>false,stats:()=>({attack(){},attackMaxIncoming(){}})};
// Same supplied start cells in both implementations; no fixture-specific expansion algorithm.
const starts=[480+10,480+11,528+10,528+11];for(const t of starts)player.conquer(t);changes.length=0;
const attack=new AttackExecution(5000.9,player,null);attack.init(game,0);
const trace=[];
for(tick=1;tick<=180;tick++){
 changes.length=0;if(attack.isActive())attack.tick(tick);
 trace.push({tick,reserve,stack:attacks[0]?.troops()??0,cells:[...changes]});
}
const result={commit:'8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94',curves,costs,frontier:{width,height,starts,trace}};
await fs.mkdir(new URL('../tests/stage2/',import.meta.url),{recursive:true});
await fs.writeFile(new URL('../tests/stage2/upstream-oracle.json',import.meta.url),JSON.stringify(result,null,2)+'\n');
export const summary=`Generated ${curves.length*250} reserve values, ${costs.length} neutral formulas and ${trace.length} actual upstream attack ticks.`;
console.log(summary);
