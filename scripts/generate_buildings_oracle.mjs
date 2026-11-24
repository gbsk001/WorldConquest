import fs from 'node:fs/promises';
const {Rules,Player,ConstructionExecution,DeleteUnitExecution,UpgradeStructureExecution}=await import(new URL('../build/buildings-upstream.mjs?x='+Date.now(),import.meta.url).href);
const types=['City','DefensePost','Factory','Port'],prices=[],counts=[],placements=[],construction=[],upgrades=[],demolitions=[];
const rules=new Rules();
for(const kind of types)for(const n of [0,1,2,3,4,10,100])for(const constructed of [0,1,3,99])for(const other of [0,1,5]){
 const owned={City:n,DefensePost:n,Factory:n,Port:n};owned[kind==='Port'?'Factory':'Port']=other;
 const built={City:constructed,DefensePost:constructed,Factory:constructed,Port:constructed};
 prices.push({kind,owned,constructed:built,cost:String(rules.unitCost(kind)({}, {type:()=> 'Human',isLobbyCreator:()=>false,unitsOwned:t=>owned[t],unitsConstructed:t=>built[t]}))});
}
for(const under of [false,true])for(const level of [1,2,3,20]){
 const p=new Player();p.myUnitsOwnedMemo=new Map();p._myUnitsVersion=0;p._units=[{type:()=> 'City',isUnderConstruction:()=>under,level:()=>level}];counts.push({under,level,owned:p.unitsOwned('City')});
}
const width=96,height=64;
function env(mode,structures){
 const p=new Player();p.smallID=()=>1;const owned=t=>{
  const x=t%width,y=Math.floor(t/width);if(mode===1)return x<48?1:2;if(mode===2)return (x===46&&y!==30)||x===50?0:1;if(mode===3)return (x+y)%9===0?0:1;return 1;
 };
 const distance=(a,b)=>(a%width-b%width)**2+(Math.floor(a/width)-Math.floor(b/width))**2;
 const mg={owner:t=>owned(t)===1?p:null,config:()=>rules,isShore:t=>t%width===2||t%width===93,
  nearbyUnits:()=>structures.map(t=>({unit:{tile:()=>t}})),euclideanDistSquared:distance,
  map:()=>({width:()=>width,ownerID:owned,forEachNeighbor:(t,fn)=>{const x=t%width;if(t>=width)fn(t-width);if(t<(height-1)*width)fn(t+width);if(x!==0)fn(t-1);if(x!==width-1)fn(t+1);}}),
  scratch:{visited:new Uint32Array(width*height),stack:[],gen:0}};
 p.mg=mg;return p;
}
for(let mode=0;mode<4;mode++)for(const occupied of [[],[32*width+46],[32*width+46,32*width+65],[30*width+31,30*width+61]])for(const y of [0,1,29,30,32,63])for(const x of [0,1,2,15,31,46,47,48,49,50,65,93,95]){
 const tile=y*width+x,near=occupied.filter(t=>(t%width-x)**2+(Math.floor(t/width)-y)**2<=900),p=env(mode,near);
 placements.push({mode,structures:occupied,tile,land:p.landBasedStructureSpawn(tile),port:p.portSpawn(tile,null)});
}
for(const kind of types)for(const instant of [false,true]){
 const r=new Rules();r._gameConfig={instantBuild:instant};let now=0,unit=null,executions=0;
 const p={canBuild:()=>100,buildUnit:()=>unit={under:false,isActive:()=>true,owner:()=>p,setUnderConstruction:v=>unit.under=v}};
 const mg={config:()=>r,isValidRef:()=>true,unitInfo:t=>r.unitInfo(t),addExecution:()=>executions++};
 const exec=new ConstructionExecution(p,kind,100);exec.init(mg,now);const trace=[];
 for(now=1;now<=55;now++){if(exec.isActive())exec.tick(now);trace.push({tick:now,exists:!!unit,under:unit?.under??false,active:exec.isActive(),effects:executions});}
 construction.push({kind,instant,duration:r.unitInfo(kind).constructionDuration,trace});
}
// Actual upgrade validation and execution, including construction/deletion/enemy ownership.
for(const kind of types)for(const under of [false,true])for(const marked of [false,true])for(const own of [false,true])for(const funds of [0,1000000]){
 const p=new Player();p._gold=BigInt(funds);p.isAlive=()=>true;p.mg={config:()=>rules,unitInfo:t=>({...rules.unitInfo(t),cost:()=>125000n})};
 const u={type:()=>kind,isUnderConstruction:()=>under,isMarkedForDeletion:()=>marked,owner:()=>own?p:null};
 upgrades.push({kind,under,marked,own,funds,valid:p.canUpgradeUnit(u)});
}
for(const start of [298,299,300,600]){
 let now=start,markedAt=null,deleted=false;
 const p=new Player();p.lastDeleteUnitTick=-1;p.id=()=>1;p.displayName=()=> 'P';p.mg={ticks:()=>now,config:()=>rules};
 const unit={owner:()=>p,isActive:()=>!deleted,tile:()=>42,markForDeletion:()=>markedAt=now+rules.deletionMarkDuration(),isOverdueDeletion:()=>markedAt!==null&&now-markedAt>0,delete:()=>deleted=true};
 const mg={unit:()=>unit,owner:()=>({isPlayer:()=>true,id:()=>1}),isLand:()=>true,inSpawnPhase:()=>false,displayMessage(){}};
 const exec=new DeleteUnitExecution(p,1);exec.init(mg,now);const accepted=markedAt!==null;
 for(now=start+1;now<=start+302;now++)if(exec.isActive())exec.tick(now);
 demolitions.push({start,accepted,markedAt,deleted});
}
const constants={minDist:rules.structureMinDist(),defenseRange:rules.defensePostRange(),deleteCooldown:rules.deleteUnitCooldown(),deleteDelay:rules.deletionMarkDuration()};
await fs.writeFile(new URL('../tests/stage5/upstream-oracle.json',import.meta.url),JSON.stringify({prices,counts,placements,construction,upgrades,demolitions,constants})+'\n');
export const summary=`${prices.length} prices, ${placements.length} placements, ${construction.length} construction timelines, ${upgrades.length} upgrade validations, demolition boundaries`;
