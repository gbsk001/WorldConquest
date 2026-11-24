// Actual pinned economy methods, stripped mechanically; no oracle reimplementation.
import fs from 'node:fs/promises';import crypto from 'node:crypto';import {stripTypeScriptTypes} from 'node:module';
const root=new URL('../',import.meta.url);const manifest=JSON.parse(await fs.readFile(new URL('docs/openfront-audit-manifest.json',root),'utf8'));
async function read(p){const b=await fs.readFile(new URL('build/OpenFrontIO/'+p,root));if(crypto.createHash('sha256').update(b).digest('hex')!==manifest.upstream_files[p])throw Error(p+' hash');return b.toString();}
function method(text,name){const start=text.indexOf('  '+name+'(')>=0?text.indexOf('  '+name+'('):text.search(new RegExp('  (?:private|public) '+name+'\\('));if(start<0)throw Error(name);let pos=text.indexOf('{',start),depth=1;for(let i=pos+1;i<text.length;i++){if(text[i]==='{')depth++;else if(text[i]==='}'&&--depth===0)return text.slice(start,i+1);}throw Error('unclosed');}
const config=await read('packages/engine/src/configuration/EngineConfig.ts'),player=await read('packages/engine/src/game/PlayerImpl.ts'),format=await read('packages/engine-lib/src/Format.ts');
const rules=['goldMultiplier','goldMultiplierFor','startingGold','startingGoldFor','goldAdditionRate','conquerGoldAmount','donateCooldown','infiniteGold','hasInfiniteGoldFor','costWrapper'].map(n=>method(config,n)).join('\n');
const state=['addGold','removeGold','canDonateGold','donateGold'].map(n=>method(player,n)).join('\n');
const game=await read('packages/engine/src/game/GameImpl.ts');
let program='const PlayerType={Human:"Human",Bot:"Bot",Nation:"Nation"};const GameUpdateType={},MessageType={},ATTACK_INDEX_SENT=0;const minInt=(a,b)=>a<b?a:b;class Donation {constructor(recipient,tick){this.recipient=recipient;this.tick=tick;}}\nexport class Rules { '+rules+'}\nexport class State {'+state+'}\nexport class Game {'+method(game,'conquerPlayer')+'}\n'+format;
program=stripTypeScriptTypes(program,{mode:'transform'});
await fs.writeFile(new URL('build/economy-upstream.mjs',root),program);
export const summary='Pinned economy/PlayerImpl/Format methods prepared.';
