"""Production lobby algorithms and adapters with deterministic service stubs, not live Roblox."""
from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
def source(p):return (r/p).read_text(encoding='utf-8-sig')
h=source('scripts/lobby_checks.luau')
for name in ['LobbyStore','LobbyState']:
 h+=f'\nlocal {name}=(function()\n'+source(f'src/server/{name}.luau')+'\nend)()\n'
h+=source('scripts/lobby_scenarios.luau')
h+='\nlocal function makeLobbyServer(game,script,require,Instance,task,os)\n'+source('src/server/LobbyServer.luau')+'\nend\n'
h+=source('scripts/lobby_runtime_checks.luau')
ns={'__file__':str(r/'scripts/check_stage1.py')}
exec(source('scripts/check_stage1.py').split("h+='local Oracle='")[0],ns)
h+='\ndo\n'+ns['h']+'\nlocal function runFoundation(game,script,require,Instance,Color3,os,debug,session)\n'+source('src/server/OpenFront/FoundationServer.luau').split('return function(session)',1)[1].rsplit('end',1)[0]+'\nend\n'
h+='local finished=0;local bridge={Allowed={},BotSettings={Enabled=true,Count=5,Names={"xShadow27","FrostByte","LunarFox","Maximus","AlexPro"},Difficulty="Normal"}};bridge.Finish=function()finished+=1;bridge.Allowed={}end\n'
server=source('scripts/stage8_server_checks.luau').split('local function step()')[0]
server=server.replace("{UserId=2,Name='Two'}","{UserId=2,Name='Two'},{UserId=3,Name='MenuOnly'}").replace('PortStage=8','PortStage=10').replace('MaxTimerMinutes=.2','MaxTimerMinutes=.1,SinglePlayer=true')
server=server.replace('profileend=function()end})','profileend=function()end},bridge)')
h+=server+source('scripts/lobby_foundation_checks.luau')+'\nend\n'
p=r/'build/stage10-checks.luau';p.write_text(h,encoding='utf-8')
for path in (r/'src').rglob('*.luau'):
 subprocess.run([str(r/'build/luau/luau-compile.exe'),str(path)],stdout=subprocess.DEVNULL,check=True)
run=subprocess.run([str(r/'build/luau/luau.exe'),str(p)],capture_output=True,text=True)
(r/'build/stage10-results.txt').write_text(run.stdout+run.stderr);print(run.stdout+run.stderr);raise SystemExit(run.returncode)
