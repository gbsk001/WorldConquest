import fs from 'node:fs/promises';
const N=await import(new URL('../build/naval-upstream.mjs?x='+Date.now(),import.meta.url).href);
const B=await import(new URL('../build/buildings-upstream.mjs',import.meta.url).href);
const rules=new N.Rules(),rates=[],gold=[],prices=[],damage=[],paths=[],air=[],scenes=[],veterans=[];
for(const levels of [0,1,2,5,6,10,100])for(const ships of [0,130,330,415,800,1200])for(const rejected of [0,1,7,50])rates.push({levels,ships,rejected,value:rules.tradeShipSpawnRate(rejected,ships,levels)});
for(const distance of [0,1,50,299,300,301,1000,10000])for(const multiplier of [.1,1,1.239,1000])gold.push({distance,multiplier,value:String(rules.tradeShipGold(distance,{multiplier}))});
for(const owned of [0,1,2,3,4,100])for(const built of [0,1,2,3,10])prices.push({owned,built,value:String(new B.Rules().unitCost('Warship')({}, {type:()=> 'Human',isLobbyCreator:()=>false,unitsOwned:()=>owned,unitsConstructed:()=>built}))});
function map(w,h,mode=0){
 const ns=t=>{let a=[],x=t%w;if(t>=w)a.push(t-w);if(t<(h-1)*w)a.push(t+w);if(x>0)a.push(t-1);if(x<w-1)a.push(t+1);return a;};
 const land=t=>mode===0?(t%w<=20||t%w>=w-21):mode===1?(t%w===Math.floor(w/2)):((t*37+Math.floor(t/w)*11)%31<7);
 const shore=t=>ns(t).some(n=>land(n)!==land(t));const terrain=Uint8Array.from({length:w*h},(_,t)=>(land(t)?128:32)+(shore(t)?64:0)+(land(t)?0:(t*13+Math.floor(t/w)*7)%32));
 const components=new Int32Array(w*h);let component=0;for(let i=0;i<w*h;i++)if(!land(i)&&!components[i]){components[i]=++component;let q=[i];while(q.length){for(const n of ns(q.pop()))if(!land(n)&&!components[n]){components[n]=component;q.push(n);}}}
 const comp=t=>{if(components[t])return components[t];for(const n of ns(t))if(components[n])return components[n];return null;};
 return {terrain,width:()=>w,height:()=>h,x:t=>t%w,y:t=>Math.floor(t/w),ref:(x,y)=>y*w+x,isValidCoord:(x,y)=>Number.isInteger(x)&&Number.isInteger(y)&&x>=0&&y>=0&&x<w&&y<h,isValidRef:t=>Number.isInteger(t)&&t>=0&&t<w*h,isWater:t=>!land(t),isLand:land,isShore:shore,isShoreline:shore,isImpassable:()=>false,waterVersion:()=>0,waterGraphVersion:()=>0,neighbors:ns,forEachNeighbor:(t,f)=>ns(t).forEach(f),neighbors4:(t,b)=>{const n=ns(t);n.forEach((v,i)=>b[i]=v);return n.length;},getWaterComponent:comp,hasWaterComponent:(t,c)=>c!==null&&(comp(t)===c||ns(t).some(n=>!land(n)&&comp(n)===c)),manhattanDist:(a,b)=>Math.abs(a%w-b%w)+Math.abs(Math.floor(a/w)-Math.floor(b/w)),euclideanDistSquared:(a,b)=>(a%w-b%w)**2+(Math.floor(a/w)-Math.floor(b/w))**2,ticks:()=>100};
}
for(let mode=0;mode<3;mode++){
 const m=map(64,48,mode),raw=new N.AStarWater(m),shore=new N.ShoreCoercingTransformer(raw,m),bounded=new N.AStarWaterBounded(m,64*48);
 for(let i=0;i<50;i++){const from=(i*137+5)%(64*48),to=(i*773+2040)%(64*48);paths.push({mode,from,to,raw:raw.findPath(from,to),shore:shore.findPath(from,to),bounded:bounded.searchBounded(from,to,{minX:0,maxX:63,minY:0,maxY:47})});}
 for(let seed=0;seed<10;seed++){m.ticks=()=>seed;const f=new N.AirPathFinder(m);air.push({seed,from:65,to:3000,path:f.findPath(65,3000)});}
}
for(const veteran of [0,1,2,3])for(let tick=0;tick<25;tick++){
 const shell=new N.ShellExecution(0,{}, {veterancy:()=>veteran},{});shell.init({ticks:()=>tick,config:()=>rules},tick);damage.push({veteran,tick,value:shell.getEffectOnTargetForTesting()});
}
for(const kinds of [Array(35).fill('TransportShip'),Array(80).fill('TradeShip'),['TransportShip','TradeShip','Warship',...Array(10).fill('TransportShip'),'Warship']]){const u=new N.Veteran(rules),trace=[];for(const kind of kinds){if(kind==='TradeShip')u.recordTradeCapture();else u.recordKill(kind);trace.push({...u._warshipState});}veterans.push({kinds,trace});}
function environment(){
 const m=map(192,128);let tick=100,nextID=0,pending=[],active=[];const units=new Map(),players=[],landings=[];const owners=new Uint8Array(192*128);for(let t=0;t<owners.length;t++)owners[t]=t%192<=20?1:t%192>=171?2:0;
 const neutral={isPlayer:()=>false,id:()=>null,smallID:()=>0};let unitGrid;
 const g={...m,map:()=>m,ticks:()=>tick,config:()=>rules,scratch:{visited:new Uint32Array(192*128),stack:[],gen:0},nextShipStagger:()=>0,recordMotionPlan(){},displayMessage(){},displayIncomingUnit(){},hasUnitNearby:()=>false,stats:()=>new Proxy({},{get:()=>()=>{}}),players:()=>players,owner:t=>players[owners[t]-1]??neutral,ownerID:t=>owners[t],addExecution:e=>pending.push(e),unitCount:t=>[...units.values()].filter(u=>u.kind===t).length};
 m.ownerID=g.ownerID;unitGrid=new N.UnitGrid(g);g.nearbyUnits=(...args)=>unitGrid.nearbyUnits(...args);
 for(let id=1;id<=3;id++){
  const p={ID:id,money:10000000n,reserve:100000,version:0,multiplier:1,border:new Set(),id:()=>id,smallID:()=>id,isPlayer:()=>true,type:()=> 'Human',name:()=> 'P'+id,displayName:()=> 'P'+id,isDisconnected:()=>false,isFriendly:q=>p===q,isOnSameTeam:()=>false,inDoomsdayClock:()=>false,canAttackPlayer:q=>q!==p,incomingAllianceRequests:()=>[],rejectAllianceRequest(){},tileChangeVersion:()=>p.version,borderTiles:()=>p.border,troops:()=>p.reserve,addTroops:n=>p.reserve+=Math.floor(n),removeTroops:n=>{const x=Math.min(p.reserve,Math.floor(n));p.reserve-=x;return x;},addGold:n=>p.money+=n,addTradeGold(){},addPiracyGold(){},canTrade:q=>q!==p,units:t=>[...units.values()].filter(u=>u.p===p&&(!t||u.kind===t)),unitCount:t=>p.units(t).reduce((a,u)=>a+u.lvl,0),captureUnit:u=>u.p=p,
   conquer:t=>{owners[t]=id;p.version++;landings.push([tick,t,id]);},bestTransportShipSpawn:t=>N.bestShoreDeploymentSource(g,p,t)??false,
   canBuild:(type,t)=>{if(type==='TransportShip')return N.canBuildTransportShip(g,p,t);if(type==='TradeShip')return p.units('Port').some(u=>u.t===t)?t:false;if(type==='Warship'){if(!m.isWater(t))return false;let best=null,d=Infinity;for(const port of p.units('Port'))if(!port.under&&m.hasWaterComponent(port.t,m.getWaterComponent(t))&&m.manhattanDist(port.t,t)<d){best=port.t;d=m.manhattanDist(port.t,t);}return best??false;}return t;},
   buildUnit:(kind,t,params={})=>{
    if(kind==='TransportShip')p.removeTroops(params.troops);if(kind==='Warship')p.money-=250000n;
    const u={ID:++nextID,kind,t,last:t,p,active:true,under:false,lvl:1,hp:kind==='Warship'?1000:1,vet:0,progress:0,army:params.troops??0,safe:params.lastSetSafeFromPirates??0,state:{state:'patrolling',patrolTile:params.patrolTile,lastCombatTick:-100},target:params.targetTile,targetU:params.targetUnit,transport:{isRetreating:false},id:()=>u.ID,type:()=>kind,tile:()=>u.t,lastTile:()=>u.last,owner:()=>u.p,isActive:()=>u.active,isUnderConstruction:()=>u.under,isMarkedForDeletion:()=>false,level:()=>u.lvl,hasTrainStation:()=>true,hasHealth:()=>kind==='Warship',health:()=>u.hp,maxHealth:()=>Math.floor(1000*(100+u.vet*20)/100),veterancy:()=>u.vet,troops:()=>u.army,
     warshipState:()=>({...u.state,isInCombat:tick-u.state.lastCombatTick<=3}),updateWarshipState:s=>{if(s.isInCombat)u.state.lastCombatTick=tick;Object.assign(u.state,s);},transportShipState:()=>u.transport,updateTransportShipState:s=>Object.assign(u.transport,s),targetTile:()=>u.target,setTargetTile:t=>u.target=t,targetUnit:()=>u.targetU,setTargetUnit:v=>u.targetU=v,setSafeFromPirates:()=>u.safe=tick,isSafeFromPirates:()=>tick-u.safe<20,
     touch(){},setReachedTarget(){},move:t=>{u.last=u.t;u.t=t;unitGrid.updateUnitCell(u);},delete:()=>{u.active=false;unitGrid.removeUnit(u);units.delete(u.ID);},modifyHealth:n=>{u.hp=Math.max(0,Math.min(kind==='Warship'?u.maxHealth():1,u.hp+Math.floor(n)));if(n<0)u.state.lastCombatTick=tick;if(u.hp===0)u.delete();},
     recordKill:kind=>{if(kind==='Warship'){u.vet=Math.min(3,u.vet+1);u.progress=0;}else progress(25);},recordTradeCapture:()=>progress(10)};
    function progress(n){if(u.vet>=3)return;u.progress+=n;while(u.progress>=250&&u.vet<3){u.vet++;u.progress-=250;}if(u.vet>=3)u.progress=0;}
    units.set(u.ID,u);unitGrid.addUnit(u);return u;
   }};players.push(p);
 }
 for(let t=0;t<owners.length;t++)if(owners[t]&&m.isShore(t))players[owners[t]-1].border.add(t);
 const ports=[players[0].buildUnit('Port',40*192+20),players[1].buildUnit('Port',80*192+171)];
 function event(e){const [when,kind,pid,a,b]=e,p=players[pid-1];if(kind==='transport')pending.push(new N.TransportShipExecution(p,a,b));else if(kind==='warship')pending.push(new N.WarshipExecution({owner:p,patrolTile:a}));else if(kind==='trade')pending.push(new N.TradeShipExecution(p,ports[0],ports[1]));else if(kind==='ports')ports.forEach(port=>pending.push(new N.PortExecution(port)));else if(kind==='retreat')pending.push(new N.BoatRetreatExecution(p,a));else if(kind==='move')pending.push(new N.MoveWarshipExecution(p,[a],b));else if(kind==='damage')units.get(a)?.modifyHealth(-b);else if(kind==='capture')players[pid-1].captureUnit(units.get(a));else if(kind==='delete')units.get(a)?.delete();else if(kind==='port')p.buildUnit('Port',a);else if(kind==='upgrade')units.get(a).lvl++;else if(kind==='neutral'){for(let t=0;t<owners.length;t++)if(owners[t]===2)owners[t]=0;players[1].border.clear();players[1].version++;}}
 function step(){for(const e of active)if(e.isActive())e.tick(tick);for(let i=0;i<pending.length;i++){const e=pending[i];if(e instanceof N.AttackExecution){landings.push([tick,'attack',e.args[0],e.args[1].ID,e.args[2],e.args[3],e.args[4]]);continue;}e.init(g,tick);active.push(e);}pending=[];active=active.filter(e=>e.isActive());tick++;}
 function snapshot(){return {ships:[...units.values()].filter(u=>u.kind!=='Port').map(u=>({id:u.ID,type:u.kind,tile:u.t,owner:u.p.ID,hp:u.hp,vet:u.vet,progress:u.progress,troops:u.army,target:u.target??null,state:u.state.state,retreat:u.transport.isRetreating})),gold:players.map(p=>String(p.money)),troops:players.map(p=>p.reserve),landings:[...landings]};}
 return {event,step,snapshot};
}
const setups=[
 {name:'neutral-invasion',events:[[0,'neutral',1],[0,'transport',1,80*192+171,20000]],ticks:250},
 {name:'fractional-transport',events:[[0,'transport',1,80*192+171,20000.75]],ticks:250},
 {name:'zero-transport',events:[[0,'transport',1,80*192+171,0]],ticks:250},
 {name:'transport-landing',events:[[0,'transport',1,80*192+171,20000]],ticks:250},
 {name:'transport-retreat',events:[[0,'transport',1,80*192+171,20000],[30,'retreat',1,3]],ticks:200},
 {name:'simultaneous-invasion',events:[[0,'transport',1,80*192+171,20000],[0,'transport',2,40*192+20,20000],[0,'transport',1,60*192+171,15000]],ticks:260},
 {name:'trade',events:[[0,'trade',1]],ticks:250},
 {name:'ports',events:[[0,'ports',1]],ticks:700},
 {name:'warships',events:[[0,'warship',1,60*192+85],[0,'warship',2,60*192+105]],ticks:350},
 {name:'interception',events:[[0,'transport',1,80*192+171,20000],[0,'warship',2,60*192+105]],ticks:300},
 {name:'repair-manual',events:[[0,'warship',1,45*192+80],[15,'damage',1,3,500],[45,'move',1,3,70*192+100]],ticks:250},
 {name:'piracy',events:[[0,'port',3,100*192+20],[0,'trade',1],[0,'warship',3,60*192+90]],ticks:500},
 {name:'port-upgrade-and-capture',events:[[0,'ports',1],[20,'upgrade',1,1],[50,'trade',1],[100,'capture',1,2]],ticks:400},
 {name:'captured-trade',events:[[0,'port',3,100*192+20],[0,'trade',1],[60,'capture',3,4]],ticks:350},
 {name:'destroyed-port',events:[[0,'trade',1],[60,'delete',1,2]],ticks:250}
];
for(const setup of setups){const env=environment(),trace=[];for(let t=0;t<setup.ticks;t++){for(const e of setup.events)if(e[0]===t)env.event(e);env.step();trace.push(env.snapshot());}scenes.push({...setup,trace});}
await fs.writeFile(new URL('../tests/stage6/upstream-oracle.json',import.meta.url),JSON.stringify({rates,gold,prices,damage,paths,air,scenes,veterans}));
export const summary={rates:rates.length,paths:paths.length,scenes:scenes.length,ticks:scenes.reduce((s,c)=>s+c.trace.length,0)};
