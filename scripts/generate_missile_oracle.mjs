import fs from 'node:fs/promises';
import {Rules,MirvExecution,Blast,MapBFS,ParabolaUniversalPathFinder,SAMPlan} from '../build/missile-upstream.mjs';
const rules=new Rules(),output={paths:[],blast:[],deaths:[],ranges:[],thresholds:[],mirv:[],sam:[]};
function map(w,h){let g=new MapBFS();Object.assign(g,{width_:w,height_:h,bfsQueue:[],bfsGen:0,width:()=>w,height:()=>h,x:t=>t%w,y:t=>Math.floor(t/w),ref:(x,y)=>y*w+x,config:()=>rules,ticks:()=>123,euclideanDistSquared:(a,b)=>(a%w-b%w)**2+(Math.floor(a/w)-Math.floor(b/w))**2,isImpassable:t=>t%97===0});return g;}
for(let i=0;i<70;i++){
 let w=i<10?128:8192,h=i<10?96:4096,g=map(w,h),a=(i*123457)%(w*h),b=(i*76543+8231)%(w*h),speed=[10,22,23,24,25,26][i%6];
 let m=new MirvExecution();m.mg=g;let ms=m.calculateDeterministicSpeed(a,b);
 for(let s of [speed,ms])output.paths.push({w,h,a,b,s,mirv:ms,path:new ParabolaUniversalPathFinder(g,{increment:s}).findPath(a,b)});
}
for(let kind of ['AtomBomb','HydrogenBomb','MIRVWarhead'])for(let tick of [1,123,9001]){
 for(let mode of [0,1,2])for(let dst of [0,128*256+128]){
 let g=map(256,256);g.isImpassable=t=>mode===1?t%97===0:mode===2?t%256===130:false;g.ticks=()=>tick;let n=new Blast();n.mg=g;n.dst=dst;n.nuke={type:()=>kind};output.blast.push({kind,tick,mode,dst,tiles:[...n.tilesToDestroy()]});
 }
}
for(let kind of ['AtomBomb','HydrogenBomb','MIRVWarhead'])for(let troops of [0,5,9000,1e6])for(let tiles of [0,1,100,10000])output.deaths.push({kind,troops,tiles,cap:123456,value:rules.nukeDeathFactor(kind,troops,tiles,123456)});
for(let level=1;level<=100;level++)output.ranges.push({level,value:rules.samRange(level)});
for(let i=0;i<100;i++){
 const w=512,h=256,g=map(w,h),src=180*w+30,dst=180*w+450,speed=i%2?10:22,path=new ParabolaUniversalPathFinder(g,{increment:speed}).findPath(src,dst);
 const tile=(100+i%6*20)*w+430-i%5*30,index=i%(path.length-1),wait=i%4*5,level=1+i%9,upgrade=i%3===0;
 const sam={level:()=>level,samLauncherState:()=>upgrade?{upgradeStartTick:95,startRange:rules.samRange(Math.max(1,level-1)),targetLevel:level}:undefined};
 g.manhattanDist=(a,b)=>Math.abs(a%w-b%w)+Math.abs(Math.floor(a/w)-Math.floor(b/w));
 const plan=new SAMPlan();plan.mg=g;plan.sam=sam;const result=plan.computeInterceptionTile({trajectory:()=>path,trajectoryIndex:()=>index,nukeState:()=>({waitTicks:wait})},tile,100);
 output.sam.push({src,dst,speed,tile,index:index+1,wait,level,upgrade,tick:result.tick,target:result.tile});
}
for(let seconds of [0,1799,1800,1829.9,1830,1860,4200,10000])for(let enabled of [false,true]){rules.overtime={enabled,startMinutes:30,dropPercentPerMinute:2};output.thresholds.push({seconds,enabled,value:rules.percentageTilesOwnedToWinTenths(seconds)});}
for(let scenario=0;scenario<5;scenario++){
 const w=scenario===3?8192:768,h=scenario===3?4096:1024,src=700*w+20,dst=scenario===3?1800*w+4000:600*w+500;let tick=100,moved=[],plans=[],active=true,tile=src;
 const target={id:()=> '2',isPlayer:()=>true,updateRelation(){}},neutral={isPlayer:()=>false};
 const g=map(w,h);g.isImpassable=()=>false;g.isLand=()=>true;g.ticks=()=>tick;
 g.owner=t=>t%w>=300 && Math.floor(t/w)>=200 && Math.floor(t/w)<=(scenario===3?3900:900) && !(scenario===1&&tick>=104&&t%w>500)?target:neutral;
 g.manhattanDist=(a,b)=>Math.abs(a%w-b%w)+Math.abs(Math.floor(a/w)-Math.floor(b/w));
 const unit={id:()=>1,tile:()=>tile,isActive:()=>active,move(t){tile=t;moved.push([tick,t]);},delete(){active=false;}};
 const p={id:()=> '1',canBuild:()=>src,buildUnit:()=>unit,units:()=>[],allianceWith:()=>null,updateRelation(){}};
 Object.assign(g,{recordMirvLaunch(){},stats:()=>({bombLaunch(){},bombLand(){}}),displayIncomingUnit(){},addExecution(e){plans.push({tick:tick+1,args:e.args.slice(2),execution:e});}});
 const execution=new MirvExecution(p,dst);execution.init(g,99); // seeded from g.ticks(), not its argument
 for(;tick<170&&execution.isActive();tick++){if(scenario===2&&tick===104||scenario===4&&tick===120)active=false;execution.tick(tick);}
 output.mirv.push({scenario,w,h,src,dst,moved,plans:plans.map(p=>({tick:p.tick,dst:p.args[0],src:p.args[1],speed:p.args[2],wait:p.args[3],cancelled:!!p.execution.cancelled}))});
}
await fs.writeFile(new URL('../tests/stage8/upstream-oracle.json',import.meta.url),JSON.stringify(output));
export const summary=Object.fromEntries(Object.entries(output).map(([k,v])=>[k,v.length]));
