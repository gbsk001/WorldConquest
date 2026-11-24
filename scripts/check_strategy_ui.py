"""Execute production GUI adapters with instance/service stubs, not Studio rendering."""
from pathlib import Path
import subprocess,re
r=Path(__file__).resolve().parents[1]
h=(r/'scripts/strategy_ui_checks.luau').read_text()
for name,path in [('Catalog','src/shared/ProgressionCatalog.luau'),('TerritoryRanking','src/shared/TerritoryRanking.luau'),('InterfaceArt','src/client/InterfaceArt.luau'),('Cosmetic','src/client/CosmeticArt.luau'),('PanelChrome','src/client/PanelChrome.luau'),('MoneyFormat','src/shared/OpenFront/MoneyFormat.luau'),('BuildingRules','src/shared/OpenFront/BuildingRules.luau'),('BuildingShop','src/client/BuildingShop.luau'),('NavalControls','src/client/NavalControls.luau'),('MissileControls','src/client/MissileControls.luau'),('MatchHUD','src/client/MatchHUD.luau'),('StrategyUI','src/client/StrategyUI.luau')]:
 s=(r/path).read_text(encoding='utf-8-sig')
 s=s.replace('local Chrome=require(script.Parent.PanelChrome)','local Chrome=PanelChrome').replace('local Ranking=require(game:GetService("ReplicatedStorage").Shared.TerritoryRanking)','local Ranking=TerritoryRanking').replace('local Map=require(game:GetService("ReplicatedStorage").Shared.Map)','local Map={LandCount=10000}')
 s=s.replace('local Art=require(script.Parent.InterfaceArt)','local Art=InterfaceArt')
 s=s.replace('local Catalog=require(game:GetService("ReplicatedStorage").Shared.ProgressionCatalog)','local Catalog=Catalog').replace('local Cosmetic=require(script.Parent.CosmeticArt)','local Cosmetic=Cosmetic')
 s=re.sub(r'local (Rules|MoneyFormat|Money)\s*=\s*require\([^\n]+',lambda m:'local '+m[1]+' = '+('BuildingRules' if m[1]=='Rules' else 'MoneyFormat'),s)
 h+='\nlocal '+name+'=(function()\n'+s+'\nend)()\n'
h+=(r/'scripts/strategy_ui_scenarios.luau').read_text()
p=r/'build/strategy-ui-checks.luau';p.write_text(h,encoding='utf-8')
subprocess.run([str(r/'build/luau/luau.exe'),str(p)],check=True)
