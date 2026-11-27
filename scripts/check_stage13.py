from gui_harness import icons, art
"""Production Stage 13 modules with service/GUI stubs, never real purchases."""
from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
def src(p): return (r/p).read_text(encoding='utf-8-sig')
def module(name,p,replacements=()):
 s=src(p)
 for a,b in replacements:s=s.replace(a,b)
 return '\nlocal '+name+'=(function()\n'+s+'\nend)()\n'
h=''
h+=module('ProductionCommerceConfig','src/server/CommerceConfig.luau')
h+=module('Catalog','src/shared/ProgressionCatalog.luau')
h+=module('Rules','src/server/ProgressionRules.luau',[('local Catalog=require(game:GetService("ReplicatedStorage").Shared.ProgressionCatalog)','local Catalog=Catalog')])
h+=module('ProfileStore','src/server/ProfileStore.luau',[('local Rules=require(script.Parent.ProgressionRules)','local Rules=Rules')])
h+=module('PartyState','src/server/PartyState.luau')
h+=src('scripts/progression_checks.luau')
h+=src('scripts/strategy_ui_checks.luau')
h+='\nColor3.fromHex=function(hex)return Color3.fromRGB(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16))end\n'
h+=icons()
h+='local Art=(function()\n'+art(src('src/client/InterfaceArt.luau'))+'\nend)()\n'
h+=module('Cosmetic','src/client/CosmeticArt.luau',[('local Catalog=require(game:GetService("ReplicatedStorage").Shared.ProgressionCatalog)','local Catalog=Catalog'),('local Art=require(script.Parent.InterfaceArt)','local Art=Art')])
h+='\nlocal Theme={surface=function(o)o.BackgroundTransparency=.14 end,button=function(o)o.TextSize=14 end}\n'
h+=src('scripts/premium_ui_checks.luau').split('-- MODULE --')[0]
h+=module('Strings','src/shared/LocaleStrings.luau')
h+=module('Localisation','src/client/Localisation.luau',[('local Strings=require(game:GetService("ReplicatedStorage").Shared.LocaleStrings)','local Strings=Strings')])
h+=module('Premium','src/client/PremiumMenu.luau',[
 ('local Catalog=require(RS.Shared.ProgressionCatalog)','local Catalog=Catalog'),
 ('local Theme=require(script.Parent.StrategyUI);local Art=require(script.Parent.InterfaceArt)','local Theme=Theme;local Art=Art'),
 ('local Cosmetic=require(script.Parent.CosmeticArt)','local Cosmetic=Cosmetic'),
 ('local Localisation=require(script.Parent.Localisation)','local Localisation=Localisation')])
h+=src('scripts/premium_ui_checks.luau').split('-- MODULE --')[1]
h+='''
local mainLobby={OnClientEvent=signal(),FireServer=function()end}
localPlayer.PlayerGui=Instance.new("Frame")
function localPlayer:GetAttribute()return nil end
function localPlayer:GetAttributeChangedSignal()return signal()end
services.GuiService={GetGuiInset=function()return Vector2.zero,Vector2.zero end}
services.ReplicatedStorage.WaitForChild=function(_,name)
 if name=="WorldConquestLobby"then return mainLobby end
 return if name=="WorldConquestProgression"then premiumRemote else partyRemote
end
'''
h+=module('MainMenu','src/client/MainMenu.luau',[
 ('local Config=require(RS.Shared.Config)','local Config={PremiumEnabled=true,SourceURL="",RenderBudgetSeconds=.003}'),
 ('local Theme=require(script.Parent.StrategyUI)','local Theme=Theme'),
 ('local Art=require(script.Parent.InterfaceArt)','local Art=Art'),
 ('require(script.Parent.PremiumMenu)','Premium')])
h+='''
local realMenu=MainMenu.new(function()end)
mainLobby.OnClientEvent:Fire({Screen="Menu"})
local shopControl=nil
for _,o in ipairs(realMenu.Gui:GetDescendants())do if o.ClassName=="TextButton"and o.Name=="Shop"then shopControl=o end end
assert(shopControl,"actual MainMenu must load PremiumMenu when enabled")
shopControl.Activated:Fire()
local inventoryControl=nil
for _,o in ipairs(realMenu.Gui:GetDescendants())do if o.ClassName=="TextButton"and o.Name=="Inventory"then inventoryControl=o end end
assert(inventoryControl,"actual main-menu navigation must open the shop")
print("Stage 13 actual MainMenu integration: enabled premium home and Shop/Inventory navigation reached in the existing ScreenGui.")
'''
h+=src('scripts/progression_server_checks.luau').split('-- MODULE --')[0]
h+=module('LeaderboardStore','src/server/LeaderboardStore.luau',[('local Catalog=require(game:GetService("ReplicatedStorage").Shared.ProgressionCatalog)','local Catalog=Catalog')])
h+=module('ProgressionServer','src/server/ProgressionServer.luau',[
 ('local Catalog=require(game:GetService("ReplicatedStorage").Shared.ProgressionCatalog)','local Catalog=Catalog'),
 ('local Store=require(script.Parent.ProfileStore)','local Store=ProfileStore'),
 ('local Config=require(script.Parent.CommerceConfig)','local Config=commerceConfig'),
 ('local LeaderboardStore=require(script.Parent.LeaderboardStore)','local LeaderboardStore=LeaderboardStore')])
h+=src('scripts/progression_server_checks.luau').split('-- MODULE --')[1]
h+=src('scripts/party_server_checks.luau').split('-- MODULE --')[0]
h+=module('PartyServer','src/server/PartyServer.luau',[
 ('local State=require(script.Parent.PartyState)','local State=PartyState;local os=partyClock')])
h+=src('scripts/party_server_checks.luau').split('-- MODULE --')[1]
p=r/'build/stage13-checks.luau';p.write_text(h,encoding='utf-8')
result=subprocess.run([str(r/'build/luau/luau.exe'),str(p)],capture_output=True,text=True)
(r/'build/stage13-results.txt').write_text(result.stdout+result.stderr,encoding='utf-8')
print(result.stdout+result.stderr);raise SystemExit(result.returncode)
