import fs from 'node:fs/promises';
const R=await import(new URL('../build/rail-upstream.mjs?x='+Date.now(),import.meta.url).href);
const rules=new R.Rules(),rates=[],gold=[],paths=[],scenes=[];
for(const levels of [0,1,2,5,6,10,20,100])for(const units of [0,7,210,500,560,810,900,1200])rates.push({levels,units,rate:rules.trainSpawnRate(levels,units)});
for(const rel of ['self','team','ally','other'])for(const visited of [0,1,9,10,11,12,20])for(const multiplier of [.1,1,1.239,1000])gold.push({rel,visited,multiplier,gold:String(rules.trainGold(rel,visited,{multiplier}))});
function makeMap(w,h,mode){
 const water=t=>mode===1?(t%w===Math.floor(w/2)):mode===2?(Math.abs(t%w-Math.floor(w/2))<=3):mode===3?((t*37+Math.floor(t/w)*11)%31<7):false;
 const ns=t=>{const a=[],x=t%w;if(t>=w)a.push(t-w);if(t<(h-1)*w)a.push(t+w);if(x>0)a.push(t-1);if(x<w-1)a.push(t+1);return a;};
 const shore=t=>ns(t).some(n=>water(t)!==water(n));
 return {width:()=>w,height:()=>h,x:t=>t%w,y:t=>Math.floor(t/w),isWater:water,isLand:t=>!water(t),isShoreline:shore,isImpassable:t=>mode===4&&t%w===Math.floor(w/2)&&Math.floor(t/w)!==10,
  terrainByte:t=>water(t)?32+(shore(t)?64:0):128+(shore(t)?64:0)+(mode===4&&t%w===Math.floor(w/2)&&Math.floor(t/w)!==10?31:0)};
}
for(let mode=0;mode<5;mode++){
 const map=makeMap(64,48,mode),astar=new R.AStarRail(map);
 for(let i=0;i<40;i++){const from=(i*137+5)%(64*48),to=(i*773+2040)%(64*48);paths.push({mode,from,to,path:astar.findPath(from,to)});}
}
function environment(mode=0){
 const map=makeMap(192,128,mode),config=new R.Rules();config.isUnitDisabled=()=>false;config.unitInfo=t=>({constructionDuration:0,upgradable:t!=='DefensePost'});
 let tick=0,nextUnit=0,active=[],pending=[];const units=new Map(),players=[];
 let network;const mg={...map,map:()=>map,config:()=>config,ticks:()=>tick,unitInfo:config.unitInfo,isValidRef:t=>t>=0&&t<192*128,addUpdate(){},recordMotionPlan(){},stats:()=>new Proxy({}, {get:()=>()=>{}}),railNetwork:()=>network,
  addExecution:e=>pending.push(e),unitCount:t=>[...units.values()].filter(u=>u.type()===t&&u.isActive()).length};
 const unitGrid=new R.UnitGrid(mg);mg.nearbyUnits=(...args)=>unitGrid.nearbyUnits(...args);mg.hasUnitNearby=(...args)=>unitGrid.hasUnitNearby(...args);
 for(let id=1;id<=2;id++){
  const p={ID:id,trainGold:0n,team:null,allied:false,embargo:false,multiplier:1,id:()=>id,units:t=>[...units.values()].filter(u=>u.isActive()&&u.owner()===p&&u.type()===t),unitCount:t=>p.units(t).reduce((a,u)=>a+u.level(),0),canBuild:(t,tile)=>tile,
   addGold(){},addTrainGold:n=>p.trainGold+=n,canTrade:q=>p!==q&&!p.embargo&&!q.embargo,isOnSameTeam:q=>p.team!==null&&p.team===q.team,isAlliedWith:q=>p.allied&&q.allied,
   buildUnit:(type,tile,params={})=>{
    const u={ID:++nextUnit,kind:type,t:tile,p,active:true,under:false,station:false,lvl:1,id:()=>u.ID,type:()=>type,tile:()=>u.t,owner:()=>u.p,isActive:()=>u.active,isUnderConstruction:()=>u.under,setUnderConstruction:v=>u.under=v,level:()=>u.lvl,hasTrainStation:()=>u.station,setTrainStation:v=>u.station=v,
     move:t=>{u.t=t;},setLoaded(){},setReachedTarget(){},delete:()=>{u.active=false;unitGrid.removeUnit(u);units.delete(u.ID);if(u.station)network.removeStation(u);}};
    units.set(u.ID,u);unitGrid.addUnit(u);return u;
   }};players.push(p);
 }
 const manager=new R.StationManagerImpl();const astar=new R.AStarRail(map);
 network=new R.RailNetworkImpl(mg,manager,{findTilePath:(a,b)=>astar.findPath(a,b)??[],findStationsPath:(a,b)=>new R.StationPathFinder(mg).findPath(a,b)??[]});
 pending.push(new R.RecomputeRailClusterExecution(network));
 function step(){for(const e of active)if(e.isActive())e.tick(tick);for(let i=0;i<pending.length;i++){pending[i].init(mg,tick);active.push(pending[i]);}pending=[];active=active.filter(e=>e.isActive());tick++;}
 function snapshot(){
  const stations=[...manager.getAll()].map(s=>({id:s.id,unit:s.unit.ID,cluster:[...(s.getCluster()?.stations??[])].map(n=>n.id)}));
  const rails=new Map();for(const s of manager.getAll())for(const r of s.getRailroads())rails.set(r.id,{id:r.id,from:r.from.id,to:r.to.id,path:r.tiles});
  const trains=[...units.values()].filter(u=>u.kind==='Train').filter((u,i,a)=>i%7===0).map(u=>({id:u.ID,owner:u.p.ID,tile:u.t}));
  return {stations,rails:[...rails.values()].sort((a,b)=>a.id-b.id),trains,gold:players.map(p=>String(p.trainGold)),trainUnits:mg.unitCount('Train')};
 }
 return {mg,players,units,step,snapshot,getTick:()=>tick,construct:(p,type,x,y)=>pending.push(new R.ConstructionExecution(players[p-1],type,y*192+x))};
}
const configurations=[
 {name:'self',mode:0,events:[[0,'build',1,'Factory',20,40],[0,'build',1,'City',100,40]]},
 {name:'two-owners-chain',mode:0,events:[[0,'build',1,'Factory',20,40],[0,'build',2,'City',80,40],[0,'build',2,'City',140,40]]},
 {name:'split-and-delete',mode:0,events:[[0,'build',1,'Factory',20,40],[0,'build',1,'City',120,40],[120,'build',1,'City',70,40],[300,'delete',3]]},
 {name:'capture-upgrade-embargo',mode:0,events:[[0,'build',1,'Factory',20,40],[0,'build',2,'City',100,40],[100,'upgrade',1],[200,'capture',1,2],[350,'embargo',2],[500,'embargo',0]]},
 {name:'multiple-factories',mode:0,events:[[0,'build',1,'Factory',20,40],[0,'build',1,'Factory',80,40],[0,'build',1,'City',45,80],[0,'build',2,'City',140,40]]},
 {name:'water-no-route',mode:2,events:[[0,'build',1,'Factory',55,40],[0,'build',1,'City',125,40]]},
 {name:'split-under-moving-train',mode:0,events:[[0,'build',1,'Factory',20,40],[0,'build',1,'City',120,40],[160,'build',1,'City',70,40]]},
 {name:'split-behind-moving-train',mode:0,events:[[0,'build',1,'Factory',20,40],[0,'build',1,'City',120,40],[180,'build',1,'City',70,40]]},
 {name:'destroy-live-destination',mode:0,events:[[0,'build',1,'Factory',20,40],[0,'build',1,'City',120,40],[170,'delete',2]]},
 {name:'capture-live-destination',mode:0,events:[[0,'build',1,'Factory',20,40],[0,'build',1,'City',120,40],[170,'capture',2,2]]},
];
for(const scene of configurations){
 const env=environment(scene.mode),frames=[];const built=[];
 for(let t=0;t<700;t++){
  for(const e of scene.events.filter(e=>e[0]===t)){
   if(e[1]==='build')env.construct(e[2],e[3],e[4],e[5]);
   else if(e[1]==='delete')built[e[2]-1].delete();
   else if(e[1]==='capture')built[e[2]-1].p=env.players[e[3]-1];
   else if(e[1]==='upgrade')built[e[2]-1].lvl++;
   else if(e[1]==='embargo')env.players[1].embargo=e[2]!==0;
  }
  env.step();for(const u of env.units.values())if(u.kind!=='Train'&&!built.includes(u))built.push(u);
  frames.push(env.snapshot());
 }
 scenes.push({...scene,frames});
}
await fs.writeFile(new URL('../tests/stage5/rail-oracle.json',import.meta.url),JSON.stringify({rates,gold,paths,scenes})+'\n');
export const summary=`${rates.length} spawn rates, ${gold.length} trade payouts, ${paths.length} rail paths, ${scenes.length*700} rail/trains/cluster/owner timelines`;
