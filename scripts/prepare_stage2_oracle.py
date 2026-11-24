"""Mechanically erase types from pinned upstream methods; never implement expected algorithms in Luau."""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'docs/openfront-audit-manifest.json').read_text())
def read(name):
    data=(ROOT/'build/OpenFrontIO'/name).read_bytes()
    assert hashlib.sha256(data).hexdigest()==manifest['upstream_files'][name],name
    return data.decode()
def erase(s):
    s=re.sub(r'\b(private|public|readonly|export)\s+','',s)
    s=re.sub(r': (PlayerLike \| TerraNullius|SpawnArea \| undefined|Spawn \| undefined|TileRef\[\] \| null|Player \| TerraNullius|Player \| null|Attack \| null|number \| null|TileRef \| null|TileRef\[\]|AttackLogicInput|AttackLogicResult|TerrainType|PlayerLike|PlayerInfo|PlayerID \| null|PlayerID|PseudoRandom|GameID|Player|GameMap|Game|Attack|boolean|string|number|void|TerraNullius)', '',s)
    s=s.replace(' as Player','').replace('<TileRef>','').replace(': TileRef','').replace(' implements Execution','')
    return s
attack=read('packages/engine/src/execution/AttackExecution.ts')
attack=attack[attack.index('const malusForRetreat'):attack.index('  snapshot(')]+'}\n'
attack=erase(attack)
attack=attack.replace('  ) {}','  ) {this.startTroops=startTroops;this._owner=_owner;this._targetID=_targetID;this.sourceTile=sourceTile;this.removeTroops=removeTroops;}')
config=read('packages/engine-lib/src/configuration/Config.ts')
config=config[config.index('  maxTroops(player'):config.index('  nukeMagnitudes(')]
config=erase(config)
engine=read('packages/engine/src/configuration/EngineConfig.ts')
base=engine[engine.index('function terrainAttackBase'):engine.index('/**\n * The engine')]
base=re.sub(r': \{\s*mag: number;\s*tileCost: number;\s*\}', '',base)
base=erase(base)
logic=erase(engine[engine.index('  attackLogic(input:'):engine.index('  boatAttackAmount(')])
initial=erase(engine[engine.index('  attackAmount(attacker:'):engine.index('  goldAdditionRate(')])
fallout=erase(engine[engine.index('  falloutDefenseModifier('):engine.index('  defensePostDefenseBonus(')])
spawn=read('packages/engine/src/execution/SpawnExecution.ts')
spawn=spawn[spawn.index('export class SpawnExecution'):spawn.index('  snapshot(')]+'}\n'
spawn=erase(spawn).replace('tile?', 'tile').replace('center?', 'center').replace('area?: SpawnArea','area')
spawn=spawn.replace('    this.random = new PseudoRandom(', '    this.playerInfo=playerInfo;this.tile=tile;this.fromIntent=fromIntent;\n    this.random = new PseudoRandom(')
spawn=spawn.replace('getTeamSpawnArea()','getTeamSpawnArea()')
util=read('packages/engine-lib/src/Util.ts')
simple=erase(util[util.index('export function simpleHash('):util.index('export function calculateBoundingBox(')])
spawnUtil=read('packages/engine/src/execution/Util.ts')
start=spawnUtil.index('export function getSpawnTiles(',spawnUtil.index('export function getSpawnTiles(')+1)
start=spawnUtil.index('export function getSpawnTiles(',start+1)
spawnUtil=erase(spawnUtil[start:spawnUtil.index('export function closestTile(')])
mapSource=read('packages/engine-lib/src/game/GameMapImpl.ts')
distance=mapSource[mapSource.index('  const dist2 = dist * dist;',mapSource.index('export function euclDistFN')):mapSource.index('export function manhattanDistFN')]
distance=erase('function euclDistFN(root,dist,center=false){\n'+distance)
header='''import {PseudoRandom,FlatBinaryHeap,pow,exp,log} from './stage1-verified-upstream.mjs';
const PlayerType={Human:'Human',Bot:'Bot',Nation:'Nation'};
const TerrainType={Plains:'Plains',Highland:'Highland',Mountain:'Mountain',Impassable:'Impassable'};
const UnitType={City:'City'}, Difficulty={Easy:'Easy',Medium:'Medium',Hard:'Hard',Impossible:'Impossible'};
const GameType={Singleplayer:'Singleplayer'};
class PlayerExecution {constructor(player){this.player=player;}}
class TribeExecution {constructor(player){this.player=player;}}
const Relation={Hostile:'Hostile'},MessageType={ATTACK_CANCELLED:'cancel'};
const renderTroops=x=>String(x);
const within=(x,a,b)=>Math.max(a,Math.min(b,x));
'''
constants=erase(engine[engine.index('const LARGE_TERRITORY_MIDPOINT'):engine.index('function terrainAttackBase')])
sigmoid=erase(util[util.index('export function sigmoid('):util.index('// Longest label')])
header+=constants+sigmoid
extra=''
for source,name in [(engine,'traitorSpeedDebuff'),(engine,'defensePostDefenseBonus'),(engine,'defensePostSpeedBonus'),(read('packages/engine-lib/src/configuration/Config.ts'),'traitorDefenseDebuff'),(read('packages/engine-lib/src/configuration/Config.ts'),'defensePostRange')]:
    extra+=erase(re.search(r'  '+name+r'\(\): number \{.*?\n  \}',source,re.S).group())+'\n'
wrapper='class Rules {gameConfig(){return this._gameConfig;}cityTroopIncrease(){return 250000;}hasInfiniteTroopsFor(){return !!this._infinite;}hasInfiniteTroopsForInfo(){return !!this._infinite;}\n'+extra+config+logic+initial+fallout+'}\n'
(ROOT/'build/stage2-upstream.mjs').write_text(header+base+wrapper+attack+simple+distance+spawnUtil+spawn+'\nexport {Rules,AttackExecution,SpawnExecution};\n')
print('Pinned upstream AttackExecution and recruitment/neutral formulas prepared without algorithm changes.')
