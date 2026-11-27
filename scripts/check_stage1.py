"""Compile production files and run deterministic Stage 1 tests. No Studio emulation."""
from pathlib import Path
import json,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
def source(path):
    text=(ROOT/path).read_text(encoding='utf-8-sig')
    if '--quick' in sys.argv:
        sections={
          'scripts/stage1_checks.luau':('-- Storage/serialization benchmark',None),
          'scripts/stage2_checks.luau':('-- Representative concurrent frontiers','local cap=Troops.cap(52)'),
          'scripts/stage3_checks.luau':('-- Benchmark full-resolution grid',None),
          'scripts/connectivity_checks.luau':('-- Heavy active fronts',None),
          'scripts/stage4_checks.luau':('-- Incremental economy work','-- Live attack/conquest'),
          'scripts/stage5_checks.luau':('-- Profile actual Stage 5',None),
          'scripts/rail_checks.luau':('do\n local w,h=8192,4096',None),
        }
        if path in sections:
            start,end=sections[path];a=text.index(start);b=text.index(end,a)if end else len(text)
            text=text[:a]+text[b:]
    return text
def factory(name,path,deps):
    text=source(path)
    for variable,value in deps.items():
        matches=[line for line in text.splitlines() if line.startswith(f'local {variable} = require(')]
        assert len(matches)==1,(path,variable)
        text=text.replace(matches[0],f'local {variable} = {value}')
    return f'local {name}=(function()\n{text}\nend)()\n'
def literal(value):
    if isinstance(value,dict):return '{'+','.join('['+json.dumps(k)+']='+literal(v) for k,v in value.items())+'}'
    if isinstance(value,list):return '{'+','.join(map(literal,value))+'}'
    if value is None:return 'nil'
    if isinstance(value,bool):return str(value).lower()
    return json.dumps(value)
tools=ROOT/'build/luau'
for path in (ROOT/'src').rglob('*.luau'):
    subprocess.run([str(tools/'luau-compile.exe'),str(path)],stdout=subprocess.DEVNULL,check=True)
h=factory('EarthData','src/shared/EarthData.luau',{})
h+=factory('WorldMap','src/shared/Map.luau',{'Earth':'EarthData'})
base='src/shared/OpenFront/'
for name,deps in [('EarthTopologyData',{}),('EarthTerrain',{'Data':'EarthTopologyData'}),('Grid',{}),('Random32',{}),('MinHeap',{}),('DetMath',{}),('Clock',{}),('BuildingWire',{}),('ShipWire',{}),('Replica',{'Grid':'Grid','Wire':'BuildingWire','ShipWire':'ShipWire'})]:
    h+=factory(name,base+name+'.luau',deps)
h+=factory('Executions','src/server/OpenFront/Executions.luau',{})
h+=factory('Troops',base+'Troops.luau',{'Math':'DetMath'})
h+=factory('Combat',base+'Combat.luau',{'Math':'DetMath'})
h+=factory('OrderedSet','src/server/OpenFront/OrderedSet.luau',{})
h+=factory('Spawn','src/server/OpenFront/Spawn.luau',{})
h+=factory('SpawnIndex','src/server/OpenFront/SpawnIndex.luau',{})
h+=factory('SpawnAtlas','src/server/OpenFront/SpawnAtlas.luau',{})
h+=factory('SpawnPlanner','src/server/OpenFront/SpawnPlanner.luau',{'Atlas':'SpawnAtlas'})
h+=factory('SpawnExecution','src/server/OpenFront/SpawnExecution.luau',{'Random':'Random32','Spawn':'Spawn'})
h+=factory('RetreatExecution','src/server/OpenFront/RetreatExecution.luau',{})
h+=factory('Expansion','src/server/OpenFront/Expansion.luau',{'Heap':'MinHeap','Random':'Random32','Troops':'Troops','RetreatExecution':'RetreatExecution','Combat':'Combat'})
h+=factory('Gold',base+'Gold.luau',{})
h+=factory('MoneyFormat',base+'MoneyFormat.luau',{})
h+=factory('BuildingRules',base+'BuildingRules.luau',{})
h+=factory('Economy','src/server/OpenFront/Economy.luau',{'Gold':'Gold'})
h+=factory('Buildings','src/server/OpenFront/Buildings.luau',{'Rules':'BuildingRules','Gold':'Gold','Wire':'BuildingWire'})
h+=factory('RailRules',base+'RailRules.luau',{'Math':'DetMath'})
h+=factory('RailPath','src/server/OpenFront/RailPath.luau',{})
h+=factory('Rail','src/server/OpenFront/Rail.luau',{'Path':'RailPath','Rules':'RailRules','Random':'Random32','Economy':'Economy','Gold':'Gold'})
h+=factory('NavalRules',base+'NavalRules.luau',{'Math':'DetMath'})
h+=factory('WaterPath','src/server/OpenFront/WaterPath.luau',{'Heap':'MinHeap','Random':'Random32'})
h+=factory('ShoreQuery','src/server/OpenFront/ShoreQuery.luau',{})
h+=factory('Warship','src/server/OpenFront/Warship.luau',{'Rules':'NavalRules','Random':'Random32'})
h+=factory('Naval','src/server/OpenFront/Naval.luau',{'Path':'WaterPath','Shore':'ShoreQuery','Warship':'Warship','Expansion':'Expansion','Rules':'NavalRules','Wire':'ShipWire','Random':'Random32','Troops':'Troops','Gold':'Gold','Economy':'Economy'})
h+=factory('Connectivity','src/server/OpenFront/Connectivity.luau',{})
h+=factory('MissileRules',base+'MissileRules.luau',{'Math':'DetMath'})
h+=factory('MissilePath',base+'MissilePath.luau',{})
h+=factory('Missiles','src/server/OpenFront/Missiles.luau',{'Rules':'MissileRules','Path':'MissilePath','Random':'Random32','Troops':'Troops','Gold':'Gold','Spawn':'SpawnExecution'})
h+=factory('Match','src/server/OpenFront/Match.luau',{})
h+=factory('BotRules','src/server/OpenFront/BotRules.luau',{})
h+=factory('Bots','src/server/OpenFront/Bots.luau',{'Rules':'BotRules','Random':'Random32','Troops':'Troops','Spawn':'SpawnExecution'})
h+=factory('BasicNations','src/server/OpenFront/BasicNations.luau',{'Random':'Random32','Spawn':'SpawnExecution','Expansion':'Expansion'})
h+=factory('Simulation','src/server/OpenFront/Simulation.luau',{'Grid':'Grid','Random32':'Random32','Executions':'Executions','Troops':'Troops','OrderedSet':'OrderedSet','Spawn':'Spawn','Expansion':'Expansion','SpawnExecution':'SpawnExecution','Connectivity':'Connectivity','Economy':'Economy','Buildings':'Buildings','Rail':'Rail','Naval':'Naval','Missiles':'Missiles','Match':'Match','SpawnIndex':'SpawnIndex','SpawnPlanner':'SpawnPlanner','Bots':'Bots','BasicNations':'BasicNations'})
h+='local Oracle='+literal(json.loads(source('tests/stage1/upstream-oracle.json')))+'\n'
if '--stage2-only' not in sys.argv:
    h+=source('scripts/stage1_checks.luau')
if (ROOT/'scripts/stage2_checks.luau').exists():
    h+='\ndo\nlocal Stage2Oracle='+literal(json.loads(source('tests/stage2/upstream-oracle.json')))+'\n'+source('scripts/stage2_checks.luau')+'\nend\n'
    h+='\ndo\nlocal FidelityOracle='+literal(json.loads(source('tests/stage2/fidelity-oracle.json')))+'\n'+source('scripts/fidelity_checks.luau')+'\nend\n'
    h+='\nlocal function runFoundation(game,script,require,Instance,Color3,os,debug)\n'
    h+=source('src/server/OpenFront/FoundationServer.luau').split('return function(session)',1)[1].rsplit('end',1)[0]+'\nend\n'
    h+='do\n'+source('scripts/stage2_server_checks.luau')+'\nend\n'
if (ROOT/'scripts/stage3_checks.luau').exists():
    h+='\ndo\nlocal Stage3Oracle='+literal(json.loads(source('tests/stage3/upstream-oracle.json')))+'\n'+source('scripts/stage3_checks.luau')+'\nend\n'
h+='\ndo\n'+source('scripts/stage3_server_checks.luau')+'\nend\n'
h+='\ndo\nlocal ConnectivityOracle='+literal(json.loads(source('tests/stage3/connectivity-oracle.json')))+'\n'+source('scripts/connectivity_checks.luau')+'\nend\n'
h+='\ndo\nlocal ElevationOracle='+literal(json.loads(source('data/elevation-manifest.json')))+'\n'+source('scripts/elevation_checks.luau')+'\nend\n'
h+='\ndo\nlocal EconomyOracle='+literal(json.loads(source('tests/stage4/upstream-oracle.json')))+'\n'+source('scripts/stage4_checks.luau')+'\nend\n'
h+='\ndo\n'+source('scripts/stage4_server_checks.luau')+'\nend\n'
if '--stage5' in sys.argv:
    h+='\ndo\nlocal BuildingOracle='+literal(json.loads(source('tests/stage5/upstream-oracle.json')))+'\n'+source('scripts/stage5_checks.luau')+'\nend\n'
    h+='\ndo\n'+source('scripts/stage5_server_checks.luau')+'\nend\n'
    h+='\ndo\nlocal RailOracle='+literal(json.loads(source('tests/stage5/rail-oracle.json')))+'\n'+source('scripts/rail_checks.luau')+'\nend\n'
(ROOT/'build/stage1-checks.luau').write_text(h)
result=subprocess.run([str(tools/'luau.exe'),str(ROOT/'build/stage1-checks.luau')],capture_output=True,text=True)
(ROOT/('build/stage5-results.txt' if '--stage5' in sys.argv else 'build/stage4-results.txt' if '--stage4' in sys.argv else 'build/stage3-results.txt' if '--stage3' in sys.argv else 'build/stage2-results.txt' if '--stage2-only' in sys.argv else 'build/stage1-results.txt')).write_text(result.stdout+result.stderr)
print(result.stdout+result.stderr)
raise SystemExit(result.returncode)
