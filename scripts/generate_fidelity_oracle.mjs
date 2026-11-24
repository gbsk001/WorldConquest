// Executes the actual hash-checked Config, EngineConfig and SpawnExecution bodies.
import fs from 'node:fs/promises';
const {Rules,SpawnExecution}=await import(new URL('../build/stage2-upstream.mjs',import.meta.url).href+'?audit='+Date.now());
const profiles=[];
for(const kind of ['Human','Bot','Nation'])for(const difficulty of ['Easy','Medium','Hard','Impossible'])for(const tutorial of [false,true])for(const infinite of [false,true])for(const cities of [0,3]){
 const rules=new Rules();rules._gameConfig={difficulty,tutorial};rules._infinite=infinite;
 const p={units:()=>[{level:()=>cities,isUnderConstruction:()=>false},{level:()=>5,isUnderConstruction:()=>true}],type:()=>kind,numTilesOwned:()=>1234,troops:()=>25000};
 const cap=rules.maxTroops(p),growth=rules.troopIncreaseRate(p),initial=rules.startManpower({playerType:kind}),allocation=rules.attackAmount(p,null);
 const cost=rules.attackLogic({terrain:'Highland',attackTroops:5000,attacker:{type:kind,numTiles:1234},defender:null,falloutRatio:0.25,defenderHasDefensePost:false,borderSize:7});
 profiles.push({kind,difficulty,tutorial,infinite,cities,cap,growth,initial,allocation,loss:cost.attackerTroopLoss,fraction:cost.tickFraction});
}
const w=64,h=48,owner=new Uint16Array(w*h),players=new Map();let phase=true;let executions=0;
const neighbors=t=>{const out=[];if(t>=w)out.push(t-w);if(t<(h-1)*w)out.push(t+w);if(t%w)out.push(t-1);if(t%w!==w-1)out.push(t+1);return out;};
for(let id=1;id<=3;id++){
 const cells=new Set();const p={center:undefined,id:()=>String(id),team:()=>null,tiles:()=>cells,hasSpawned:()=>p.center!==undefined,
 relinquish:t=>{owner[t]=0;cells.delete(t);},conquer:t=>{if(owner[t])throw Error('adapter overwrote owner');owner[t]=id;cells.add(t);},
 setSpawnTile:t=>{p.center=t;},spawnTile:()=>p.center,type:()=>'Human'};players.set(String(id),p);
}
const gm={inSpawnPhase:()=>phase,isValidRef:t=>Number.isInteger(t)&&t>=0&&t<w*h,hasPlayer:id=>players.has(id),player:id=>players.get(id),
 config:()=>({isRandomSpawn:()=>false,gameConfig:()=>({gameType:'Multiplayer'}),minDistanceBetweenPlayers:()=>30}),
 addExecution:()=>{executions++;},stats:()=>({recordSpawnTile(){}}),width:()=>w,height:()=>h,ref:(x,y)=>y*w+x,
 x:t=>t%w,y:t=>Math.floor(t/w),isLand:t=>t%w>=3&&t%w!==32,hasOwner:t=>owner[t]!==0,
 isImpassable:t=>t%w>=50&&Math.floor(t/w)<10,isBorder:t=>neighbors(t).some(n=>owner[n]!==owner[t]),
 allPlayers:()=>[...players.values()],manhattanDist:(a,b)=>Math.abs(a%w-b%w)+Math.abs(Math.floor(a/w)-Math.floor(b/w)),
 bfs:(root,filter)=>{const queue=[root],seen=new Set(queue);for(let i=0;i<queue.length;i++)for(const n of neighbors(queue[i]))if(!seen.has(n)&&filter(gm,n)){seen.add(n);queue.push(n);}return queue;}};
const actions=[
 {id:1,tile:20*w+10,intent:true,before:true,after:true},
 {id:2,tile:20*w+10,intent:true,before:true,after:true},
 {id:2,tile:20*w+11,intent:true,before:true,after:true},
 {id:1,tile:-1,intent:true,before:true,after:true},
 {id:1,tile:1.5,intent:true,before:true,after:true},
 {id:1,tile:5*w+55,intent:true,before:true,after:true},
 {id:1,tile:30*w+20,intent:true,before:true,after:true},
 {id:2,tile:35*w+45,intent:true,before:true,after:false},
 {id:1,tile:10*w+20,intent:true,before:false,after:false},
 {id:3,tile:null,intent:false,before:false,after:false},
];
const spawns=[];
for(const action of actions){
 phase=action.before;const e=new SpawnExecution('51',{id:String(action.id),name:'P'+action.id,playerType:'Human'},action.tile??undefined,action.intent);
 e.init(gm,0);phase=action.after;e.tick(1);
 spawns.push({action,executions,players:[...players.values()].map(p=>({id:Number(p.id()),center:p.center??null,cells:[...p.tiles()]}))});
}
const out={profiles,spawns};
await fs.writeFile(new URL('../tests/stage2/fidelity-oracle.json',import.meta.url),JSON.stringify(out,null,2)+'\n');
export const summary=`Upstream source generated ${profiles.length} rule profiles and ${spawns.length} spawn lifecycle snapshots.`;
console.log(summary);
