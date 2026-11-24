import fs from 'node:fs/promises';
const {Rules,State,Game,renderNumber}=await import(new URL('../build/economy-upstream.mjs?x='+Date.now(),import.meta.url).href);
const rules=new Rules(),profiles=[];
for(const kind of ['Human','Nation','Bot'])for(const multiplier of [.1,1,1.239,3.333,1000])for(const host of [false,true])for(const land of [1,52,1000000]){
 rules._gameConfig={startingGold:12345,goldMultiplier:multiplier,hostCheats:{startingGold:777,goldMultiplier:2.345}};
 const p={playerType:kind,isLobbyCreator:host};const rate=rules.goldAdditionRate({type:()=>kind,isLobbyCreator:()=>host,numTilesOwned:()=>land,troops:()=>land*21});
 profiles.push({kind,multiplier,host,land,initial:String(rules.startingGold(p)),rate:String(rate)});
}
const balances=[];const state=new State();state._gold=0n;state._goldEarned=0n;
for(const [op,amount] of [['add','100'],['remove','33'],['add','9007199254740993'],['add','999999999999999999999999999999999999'],['remove','9007199254740999'],['remove','0'],['remove','999999999999999999999999999999999999999999']]){
 let removed=null;if(op==='add')state.addGold(BigInt(amount));else removed=String(state.removeGold(BigInt(amount)));
 balances.push({op,amount,removed,balance:String(state._gold),earned:String(state._goldEarned)});
}
const loot=[];rules._gameConfig={};
for(const kind of ['Human','Bot','Nation'])for(const amount of ['0','1','999','9007199254740993','9999999999999999999999999'])for(const sent of [0,1,-1]){
 const winner=new State(),loser=new State();winner._gold=10n;winner._goldEarned=0n;loser._gold=BigInt(amount);loser._goldEarned=0n;
 Object.assign(loser,{gold:()=>loser._gold,type:()=>kind,isDisconnected:()=>false,displayName:()=>'L',id:()=>2});Object.assign(winner,{type:()=>'Human',id:()=>1,clientID:()=>1});
 const game=new Game();game._config=rules;game._stats={getPlayerStats:()=>({attacks:[BigInt(sent)]})};game.stats=()=>new Proxy({},{get:()=>()=>{}});game.players=()=>[winner,loser];game.displayMessage=()=>{};game.addUpdate=()=>{};game.ticks=()=>0;
 game.conquerPlayer(winner,loser);
 loot.push({kind,amount,sent,winner:String(winner._gold),loser:String(loser._gold),earned:String(winner._goldEarned)});
}
const formatting=['0','999','1000','9999','10000','99999','100000','999999','1000000','9999999','10000000','999999999','1000000000','9999999999','10000000000','9007199254740993'].map(n=>({n,text:renderNumber(BigInt(n))}));
const donations=[];
for(const friendly of [false,true])for(const enabled of [false,true])for(const tick of [99,100])for(const amount of ['0','30','200']){
 const a=new State(),b=new State();a._gold=100n;a._goldEarned=0n;b._gold=20n;b._goldEarned=0n;
 Object.assign(a,{isAlive:()=>true,isFriendly:()=>friendly,id:()=>1});Object.assign(b,{isAlive:()=>true,type:()=>'Human',gold:()=>b._gold,id:()=>2});a.sentDonations=[{recipient:b,tick:0}];a.mg={ticks:()=>tick,config:()=>({donateGold:()=>enabled,donateCooldown:()=>100}),stats:()=>({goldDonationReceived(){}}),addUpdate(){}};
 const success=a.canDonateGold(b)&&a.donateGold(b,BigInt(amount));donations.push({friendly,enabled,tick,amount,success,from:String(a._gold),to:String(b._gold),earned:String(b._goldEarned)});
}
const costs=[];
for(const kind of ['Human','Nation','Bot'])for(const infinite of [false,true])for(const host of [false,true]){
 rules._gameConfig={infiniteGold:infinite,hostCheats:{infiniteGold:true}};
 const p={type:()=>kind,isLobbyCreator:()=>host,unitsOwned:()=>2,unitsConstructed:()=>1};
 costs.push({kind,infinite,host,cost:String(rules.costWrapper(n=>100+50*n,'Fixture')({},p))});
}
await fs.mkdir(new URL('../tests/stage4/',import.meta.url),{recursive:true});
await fs.writeFile(new URL('../tests/stage4/upstream-oracle.json',import.meta.url),JSON.stringify({profiles,balances,loot,formatting,donations,costs})+'\n');
export const summary=`${profiles.length} income/start profiles; ${loot.length} GameImpl loot cases; ${donations.length} donations; BigInt ledger and format boundaries`;
