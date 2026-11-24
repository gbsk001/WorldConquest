import fs from 'node:fs/promises';
const {PlayerExecution}=await import(new URL('../build/connectivity-upstream.mjs',import.meta.url).href);
const cases=[];
function run(name,w,h,owners,water=[],fallout=[],attacks=[],allies=[]){
 const input=[...owners],changes=[],killed=[];const ocean=new Set(water),radio=new Set(fallout),players=[];
 const neighbors4=(t,out)=>{let n=0,x=t%w;if(t>=w)out[n++]=t-w;if(t<(h-1)*w)out[n++]=t+w;if(x)out[n++]=t-1;if(x<w-1)out[n++]=t+1;return n;};
 const neighbors8=(t,out)=>{let n=0,x=t%w;for(const dx of [-1,0,1])for(const dy of [-1,0,1])if((dx||dy)&&x+dx>=0&&x+dx<w&&Math.floor(t/w)+dy>=0&&Math.floor(t/w)+dy<h)out[n++]=t+dy*w+dx;return n;};
 const nearWater=t=>{const nb=[];neighbors4(t,nb);return nb.some(v=>ocean.has(v));};
 const map={width:()=>w,height:()=>h,x:t=>t%w,y:t=>Math.floor(t/w),ownerID:t=>owners[t],neighbors4,neighbors8,isLand:t=>!ocean.has(t),hasFallout:t=>radio.has(t),isShore:nearWater,isOceanShore:nearWater,isOnEdgeOfMap:t=>t%w===0||t%w===w-1||t<w||t>=(h-1)*w};
 const update=t=>{const p=players[owners[t]-1];if(!p)return;const nb=[];neighbors4(t,nb);if(nb.some(v=>owners[v]!==p.id()))p.border.add(t);else p.border.delete(t);};
 for(let id=1;id<=3;id++){const p={border:new Set(),owned:new Set(),id:()=>id,smallID:()=>id,isAlive:()=>p.owned.size>0,numTilesOwned:()=>p.owned.size,borderTiles:()=>p.border,isFriendly:other=>other===p||allies.some(pair=>pair[0]===id&&pair[1]===other.id()),outgoingAttacks:()=>attacks.filter(a=>a[0]===id).map(a=>({target:()=>players[a[1]-1],troops:()=>a[2]})),conquer:t=>{const old=players[owners[t]-1];if(old){old.border.delete(t);old.owned.delete(t);}owners[t]=id;radio.delete(t);p.owned.add(t);update(t);const nb=[];neighbors4(t,nb);nb.forEach(update);changes.push([t,id]);}};players.push(p);}
 for(let t=0;t<owners.length;t++)if(owners[t])players[owners[t]-1].owned.add(t);
 for(let t=0;t<owners.length;t++)update(t);
 const game={width:()=>w,height:()=>h,map:()=>map,config:()=>({}),ownerID:t=>owners[t],playerBySmallID:id=>players[id-1],conquerPlayer:(a,b)=>killed.push([a.id(),b.id()])};
 const exec=new PlayerExecution(players[0]);exec.init(game,0);
 const before=exec.calculateClusters();const pinches=before.clusters.map(c=>exec.hasDiagonalPinch(c));
 exec.removeClusters();const b=players[0].largestClusterBoundingBox;
 cases.push({name,w,h,owners:input,water,fallout,attacks,allies,clusters:before.clusters,pinches,changes,final:[...owners],box:b?[b.min.x,b.min.y,b.max.x,b.max.y]:null,killed});
}
function shape(name,fn){const w=32,h=32,o=Array(w*h).fill(0),water=[],fallout=[],attacks=[],allies=[];const fill=(id,x0,y0,x1,y1)=>{for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++)o[y*w+x]=id;};fn({o,w,h,fill,water,fallout,attacks,allies});run(name,w,h,o,water,fallout,attacks,allies);}
shape('single-enemy-enclosure',({fill})=>{fill(2,4,4,16,16);fill(1,5,5,15,15);});
shape('one-cell-escape',({fill})=>{fill(2,4,4,16,16);fill(1,5,5,15,15);fill(0,4,10,4,10);});
shape('diagonal-clean',({fill})=>{fill(2,4,4,20,20);fill(1,5,5,12,12);fill(1,13,13,14,14);fill(0,4,5,4,5);});
shape('diagonal-fallout',({fill,fallout,w})=>{fill(2,4,4,20,20);fill(1,5,5,12,12);fill(1,13,13,14,14);fill(0,4,5,4,5);fill(0,13,12,13,12);fallout.push(12*w+13);});
shape('hole-rim',({fill})=>{fill(1,3,3,26,26);fill(2,12,12,16,16);fill(1,13,13,15,15);});
shape('lake-escape',({fill,water,w})=>{fill(2,4,4,16,16);fill(1,5,5,15,15);fill(0,4,10,4,10);water.push(10*w+4);});
shape('multi-enemy-secondary',({fill,attacks})=>{fill(1,1,1,10,10);fill(2,17,17,25,25);fill(3,21,17,25,25);fill(1,18,18,24,24);attacks.push([3,1,5000],[2,1,1000]);});
shape('friendly-enclosure',({fill,allies})=>{fill(2,4,4,16,16);fill(1,5,5,15,15);allies.push([2,1]);});
shape('edge-no-wrap',({fill})=>{fill(1,0,0,0,20);fill(1,31,10,31,30);});
shape('comb-and-ring',({fill})=>{fill(1,2,2,14,14);fill(0,5,5,11,11);fill(1,20,2,20,25);fill(1,22,2,22,25);fill(1,24,2,24,25);fill(1,20,25,24,25);});
let seed=728374;const rand=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};
for(let i=0;i<300;i++){
 const w=20,h=20,o=Array(w*h).fill(0),water=[],fallout=[];
 for(let t=0;t<o.length;t++){o[t]=Math.floor(rand()*4);if(o[t]===0){if(rand()<.25)water.push(t);else if(rand()<.5)fallout.push(t);}}
 run('seeded-'+i,w,h,o,water,fallout,i%2?[[2,1,4000],[3,1,8000]]:[],i%5===0?[[2,1]]:[]);
}
await fs.writeFile(new URL('../tests/stage3/connectivity-oracle.json',import.meta.url),JSON.stringify({commit:'8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94',cases})+'\n');
export const summary=`${cases.length} actual upstream connectivity scenarios; ${cases.reduce((n,c)=>n+c.changes.length,0)} captures`;
