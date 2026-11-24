"""Stage 9 deterministic production simulation, not live Roblox."""
from pathlib import Path
import subprocess,json,sys
r=Path(__file__).resolve().parents[1]
ns={'__file__':str(r/'scripts/check_stage1.py')}
exec((r/'scripts/check_stage1.py').read_text().split("h+='local Oracle='")[0],ns)
h=ns['h']+'\nlocal QUICK='+str('--quick' in sys.argv).lower()+'\nlocal BotOracle='+ns['literal'](json.loads((r/'tests/stage9/upstream-oracle.json').read_text()))+'\n'+(r/'scripts/bot_checks.luau').read_text()
h+='\nlocal function runFoundation(game,script,require,Instance,Color3,os,debug)\n'+(r/'src/server/OpenFront/FoundationServer.luau').read_text().split('return function(session)',1)[1].rsplit('end',1)[0]+'\nend\ndo\n'
server=(r/'scripts/stage8_server_checks.luau').read_text().split('local function step()')[0]
server=server.replace('PortStage=8','PortStage=9,Bots={Enabled=true,Count=2,Difficulty="Normal"}').replace('MaxTimerMinutes=.2','MaxTimerMinutes=.1,SinglePlayer=true')
h+=server+'''\nlocal function step()now+=.1;beat:Fire(.1)end
for _,p in ipairs(list)do remote.OnServerEvent:Fire(p,'Sync')end
for _=1,240 do step()end
local function checkRoster()
 local bots=0;local spectator=false
 for _,p in ipairs(replicas[list[1]].Meta.Players)do
  if p.IsBot then bots+=1;assert(p.Spawn)end
  if p.UserId==2 then spectator=p.Spectator end
 end
 assert(bots==2 and spectator and replicas[list[1]].Meta.Stage==9)
end
checkRoster()
for _=1,500 do step()end
assert(remote.Attributes.MatchID==2 and resets==2);checkRoster()
assert(remote.Attributes.BotCount==2 and remote.Attributes.BotDecisions>=0)
print('Stage 9 real server adapter: two replicas, solo spectator policy, labelled bots, fresh bot roster after restart and telemetry passed (stubbed services).')
end
'''
p=r/'build/stage9-checks.luau';p.write_text(h,encoding='utf-8')
result=subprocess.run([str(r/'build/luau/luau.exe'),str(p)],capture_output=True,text=True)
(r/'build'/('stage9-quick-results.txt' if '--quick' in sys.argv else 'stage9-results.txt')).write_text(result.stdout+result.stderr)
print(result.stdout+result.stderr);raise SystemExit(result.returncode)
