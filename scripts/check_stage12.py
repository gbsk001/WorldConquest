"""Stage 12 production rules, service rejection and cross-server storage repair tests.
No Roblox filtering/voice/remote persistence is impersonated as a live test.
"""
from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
def module(name,path,replacements=()):
 s=(r/path).read_text(encoding='utf-8-sig')
 for a,b in replacements:s=s.replace(a,b)
 return '\nlocal '+name+'=(function()\n'+s+'\nend)()\n'
h='local Enum={TextFilterContext={PublicChat="PublicChat"}}\n'
h+=module('Names','src/server/NationNames.luau')
h+=module('Policy','src/server/CommunicationPolicy.luau')
h+=module('Strings','src/shared/LocaleStrings.luau')
h+=module('Catalog','src/shared/ProgressionCatalog.luau')
h+=module('Rules','src/server/ProgressionRules.luau',[('local Catalog=require(game:GetService("ReplicatedStorage").Shared.ProgressionCatalog)','local Catalog=Catalog')])
h+=module('Store','src/server/ProfileStore.luau',[('local Rules=require(script.Parent.ProgressionRules)','local Rules=Rules')])
h+=module('Writer','src/server/LeaderboardStore.luau',[('local Catalog=require(game:GetService("ReplicatedStorage").Shared.ProgressionCatalog)','local Catalog=Catalog')])
h+=(r/'scripts/stage12_checks.luau').read_text(encoding='utf-8')
h+=(r/'scripts/stage12_services_checks.luau').read_text(encoding='utf-8').split('-- MODULES --')[0]
h+=module('Identity','src/server/IdentityServer.luau',[('local Names=require(script.Parent.NationNames)','local Names=Names')])
h+=module('Communication','src/server/CommunicationServer.luau',[('local Policy=require(script.Parent.CommunicationPolicy)','local Policy=Policy')])
h+=(r/'scripts/stage12_services_checks.luau').read_text(encoding='utf-8').split('-- MODULES --')[1]
p=r/'build/stage12-checks.luau';p.write_text(h,encoding='utf-8')
run=subprocess.run([str(r/'build/luau/luau.exe'),str(p)],capture_output=True,text=True)
(r/'build/stage12-results.txt').write_text(run.stdout+run.stderr,encoding='utf-8')
print(run.stdout+run.stderr)
raise SystemExit(run.returncode)
