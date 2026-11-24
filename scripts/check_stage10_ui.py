"""Execute menu navigation callbacks and layout math with GUI/platform stubs."""
from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
h=(r/'scripts/strategy_ui_checks.luau').read_text()
money=(r/'src/shared/OpenFront/MoneyFormat.luau').read_text()
h+='\nlocal MoneyFormat=(function()\n'+money+'\nend)()\n'
h+='local InterfaceArt=(function()\n'+(r/'src/client/InterfaceArt.luau').read_text()+'\nend)()\n'
h+='local TerritoryRanking=(function()\n'+(r/'src/shared/TerritoryRanking.luau').read_text()+'\nend)()\n'
h+='local PanelChrome=(function()\n'+(r/'src/client/PanelChrome.luau').read_text().replace('local Art=require(script.Parent.InterfaceArt)','local Art=InterfaceArt')+'\nend)()\n'
theme=(r/'src/client/StrategyUI.luau').read_text().replace('local Money=require(game:GetService("ReplicatedStorage").Shared.OpenFront.MoneyFormat)','local Money=MoneyFormat')
theme=theme.replace('local Chrome=require(script.Parent.PanelChrome)','local Chrome=PanelChrome').replace('local Ranking=require(game:GetService("ReplicatedStorage").Shared.TerritoryRanking)','local Ranking=TerritoryRanking')
theme=theme.replace('local Art=require(script.Parent.InterfaceArt)','local Art=InterfaceArt')
h+='local StrategyUI=(function()\n'+theme+'\nend)()\n'
h+=(r/'scripts/menu_ui_stubs.luau').read_text()
menu=(r/'src/client/MainMenu.luau').read_text().replace('local Config=require(RS.Shared.Config)','local Config=menuConfig').replace('local Theme=require(script.Parent.StrategyUI)','local Theme=StrategyUI').replace('local Art=require(script.Parent.InterfaceArt)','local Art=InterfaceArt').replace('local Map=require(RS.Shared.Map)','local Map={Width=8192,Height=4096,isLand=function()return false end}')
h+='\nlocal MainMenu=(function()\n'+menu+'\nend)()\n'+(r/'scripts/menu_ui_checks.luau').read_text()
p=r/'build/stage10-ui-checks.luau';p.write_text(h,encoding='utf-8')
run=subprocess.run([str(r/'build/luau/luau.exe'),str(p)],capture_output=True,text=True)
(r/'build/stage10-ui-results.txt').write_text(run.stdout+run.stderr);print(run.stdout+run.stderr);raise SystemExit(run.returncode)
