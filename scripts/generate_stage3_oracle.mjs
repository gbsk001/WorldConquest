// Copyright OpenFront and Contributors; AGPL-3.0. Runs actual pinned TS after type erasure.
import fs from 'node:fs/promises';
const {Rules,AttackExecution}=await import(new URL('../build/stage2-upstream.mjs?combat='+Date.now(),import.meta.url).href);
const {PlayerExecution}=await import(new URL('../build/connectivity-upstream.mjs',import.meta.url).href);
const rules=new Rules();rules._gameConfig={difficulty:'Hard'};
const formulas=[];
for(const terrain of ['Plains','Highland','Mountain'])for(const count of [52,300000,2000000])for(const ratio of [0,.1,.6,1,3,100])for(const traitor of [false,true]){
 const input={terrain,attackTroops:25000,borderSize:17,attacker:{type:'Human',numTiles:count},defender:{type:'Human',numTiles:count+20,troops:25000*ratio,isTraitor:traitor,isDisconnectedTeammate:false},defenderHasDefensePost:false,falloutRatio:null};
 formulas.push({input,result:rules.attackLogic(input)});
}
for(const terrain of ['Plains','Highland','Mountain'])for(const ratio of [0,.5,1]){
 const input={terrain,attackTroops:25000,borderSize:5,attacker:{type:'Human',numTiles:10000},defender:{type:'Bot',numTiles:500,troops:3500,isTraitor:false,isDisconnectedTeammate:false},defenderHasDefensePost:true,falloutRatio:ratio};formulas.push({input,result:rules.attackLogic(input)});
}
const scenarios=[];
for(const connectivity of [false,true])for(const name of ['battle','conquest','counter','equal','multi','cancel','merge','island']){
 const W=48,H=32,owners=new Uint16Array(W*H),changes=[];let tick=0,serial=0;const executions=[];
 const neighbors=(t,out)=>{let n=0,x=t%W;if(t>=W)out[n++]=t-W;if(t<(H-1)*W)out[n++]=t+W;if(x)out[n++]=t-1;if(x<W-1)out[n++]=t+1;return n;};
 const land=t=>t%W!==40;
 const terrain=t=>t%3===0?'Mountain':t%3===1?'Highland':'Plains';
 const map={width:()=>W,height:()=>H,x:t=>t%W,y:t=>Math.floor(t/W),isShore:t=>t%W===39||t%W===41,isOceanShore:t=>t%W===39||t%W===41,isOnEdgeOfMap:t=>t%W===0||t%W===W-1||t<W||t>=(H-1)*W,hasFallout:()=>false,neighbors8:(t,out)=>{let n=0;for(const dx of [-1,0,1])for(const dy of [-1,0,1])if((dx||dy)&&t%W+dx>=0&&t%W+dx<W&&Math.floor(t/W)+dy>=0&&Math.floor(t/W)+dy<H)out[n++]=t+dx+dy*W;return n;},neighbors4:neighbors,ownerID:t=>owners[t],isLand:land,isWater:t=>!land(t),isImpassable:()=>false,terrainType:terrain};
 const neutral={id:()=>null,smallID:()=>0,isPlayer:()=>false};const players=[];
 const update=t=>{const p=players[owners[t]-1];if(!p)return;const out=[];neighbors(t,out);if(out.some(t=>owners[t]!==p.id()))p.border.add(t);else p.border.delete(t);};
 for(let id=1;id<=3;id++){
  const p={reserve:100000,owned:new Set(),border:new Set(),out:[],incoming:[],smallID:()=>id,id:()=>id,type:()=>'Human',isPlayer:()=>true,isAlive:()=>p.owned.size>0,numTilesOwned:()=>p.owned.size,tiles:()=>p.owned,
   troops:()=>p.reserve,removeTroops:n=>{const v=Math.min(p.reserve,Math.floor(n));p.reserve-=v;return v;},addTroops:n=>{p.reserve+=Math.floor(n);},
   isFriendly:o=>o===p,canAttackPlayer:o=>o!==p,isTraitor:()=>false,isDisconnected:()=>false,isOnSameTeam:()=>false,addEmbargo(){},incomingAllianceRequests:()=>[],relation:()=>'Hostile',updateRelation(){},
   borderTiles:()=>p.border,outgoingAttacks:()=>p.out,incomingAttacks:()=>p.incoming.filter(a=>a.attacker().isAlive()),
   conquer:t=>{const old=players[owners[t]-1];if(old){old.owned.delete(t);old.border.delete(t);}owners[t]=id;p.owned.add(t);update(t);const nb=[];neighbors(t,nb);for(const t of nb)update(t);changes.push([t,id]);},
   createAttack:(target,amount)=>{const border=new Set();const a={serial:++serial,value:amount,active:true,stopping:false,stopped:false,troops:()=>a.value,setTroops:v=>{a.value=Math.max(0,v);},target:()=>target,attacker:()=>p,sourceTile:()=>null,borderSize:()=>border.size,clearBorder:()=>border.clear(),addBorderTile:t=>border.add(t),removeBorderTile:t=>border.delete(t),isActive:()=>a.active,retreating:()=>a.stopping,retreated:()=>a.stopped,delete:()=>{a.active=false;p.out=p.out.filter(v=>v!==a);target.incoming=target.incoming.filter(v=>v!==a);}};p.out.push(a);target.incoming.push(a);return a;}
  };players.push(p);
 }
 const game={width:()=>W,height:()=>H,ownerID:t=>owners[t],playerBySmallID:id=>players[id-1],map:()=>map,terraNullius:()=>neutral,player:id=>players[id-1],hasPlayer:id=>id>=1&&id<=3,owner:t=>players[owners[t]-1]??neutral,config:()=>rules,ticks:()=>tick,hasFallout:()=>false,hasUnitNearby:()=>false,stats:()=>({attack(){},attackMaxIncoming(){},attackCancel(){}}),conquerPlayer(){},displayMessage(){},forEachNeighbor:(t,fn)=>{const nb=[];neighbors(t,nb);nb.forEach(fn);}};
 const starts=[];for(let y=6;y<26;y++)for(let x=3;x<39;x++){const id=x<15?1:x<27?2:3;if((name==='conquest'||name==='island')&&id===2&&y>=10)continue;players[id-1].conquer(y*W+x);starts.push([y*W+x,id]);}
 if(name==='island'){players[1].conquer(8*W+43);starts.push([8*W+43,2]);}
 const orders=[{tick:0,from:1,to:2,amount:name==='equal'?5000:60000}];
 if(name==='counter'||name==='equal')orders.push({tick:0,from:2,to:1,amount:name==='equal'?5000:25000});
 if(name==='multi')orders.push({tick:0,from:3,to:2,amount:60000});
 if(name==='merge')orders.push({tick:5,from:1,to:2,amount:20000});
 const clusterExecutions=players.map(p=>{const e=new PlayerExecution(p);e.init(game,0);return e;});
 const trace=[];
 for(tick=0;tick<65;tick++){
  changes.length=0;
  if(name==='cancel'){const a=players[0].out[0];if(a&&tick===3)a.stopping=true;if(a&&tick===23)a.stopped=true;}
  for(const e of executions)if(e.isActive())e.tick(tick);
  if(connectivity)for(const e of clusterExecutions)e.removeClusters();
  for(const o of orders.filter(o=>o.tick===tick)){const e=new AttackExecution(o.amount,players[o.from-1],o.to);e.init(game,tick);executions.push(e);}
  trace.push({tick,changes:[...changes],players:players.map(p=>({reserve:p.reserve,count:p.owned.size,attacks:p.out.map(a=>({id:a.serial,troops:a.value}))}))});
 }
 scenarios.push({connectivity,name,width:W,height:H,starts,orders,trace});
}
await fs.mkdir(new URL('../tests/stage3/',import.meta.url),{recursive:true});
await fs.writeFile(new URL('../tests/stage3/upstream-oracle.json',import.meta.url),JSON.stringify({commit:'8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94',formulas,scenarios})+'\n');
export const summary=`${formulas.length} source combat formulas; ${scenarios.length} x 65 actual AttackExecution ticks.`;

