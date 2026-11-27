"""Validate local-only configuration branches and prepared asset files; no simulation."""
from pathlib import Path
import subprocess, json
from package_stage15_local import local_config
from configure_icon_atlases import configure
from prepare_icon_upload import validate_png
r=Path(__file__).resolve().parents[1]
source=local_config()
h='local Color3={fromRGB=function(...)return {...}end}\n'
h+='local function load(studio)\nlocal game={GetService=function()return {IsStudio=function()return studio end}end}\n'+source+'\nend\n'
h+='''
local public=load(false);local localOnly=load(true)
assert(public.Population.SafeParticipants==20 and public.BasicNations.SafeCount==0 and not public.LocalPopulationPreview)
assert(localOnly.Population.SafeParticipants==20 and localOnly.Population.PublicTarget==20)
assert(localOnly.BasicNations.Count==300 and localOnly.BasicNations.SafeCount==300 and localOnly.LocalPopulationPreview)
assert(localOnly.Bots.FillEmptySlots and localOnly.Bots.TargetPlayers==20 and localOnly.Bots.Difficulty=="Normal")
assert(localOnly.Balance.StartingSoldiers==public.Balance.StartingSoldiers and localOnly.Economy.StartingGold=="0")
print("Local population overlay: 300 grey/20 competitive only in Studio; live branch retains 0 grey/20 competitive and identical balance.")
'''
target=r/'build/stage15-preparation.luau';target.write_text(h,encoding='utf-8')
subprocess.run([str(r/'build/luau/luau.exe'),str(target)],check=True)
icon=(r/'src/client/IconAssets.luau').read_text(encoding='utf-8-sig');assert 'AtlasAssetIDs={0,0,0,0}'in icon
for ids in [[0,2,3,4],[1,1,3,4],[1,2,3],[-1,2,3,4]]:
 try:configure(icon,ids)
 except ValueError:pass
 else:raise AssertionError('Bad IDs accepted')
assert 'AtlasAssetIDs={101,102,103,104}'in configure(icon,[101,102,103,104]) # Never writes fixture IDs.
for n in range(1,5):
 name=f'LucideAtlas{n}.png'if n<4 else 'FlagAtlas.png'
 validate_png(r/'assets/gui-icons'/name,(512,512 if n<4 else 256))
print('Four real RGBA PNG atlas integrity checks passed. ID helper rejects invalid/duplicate IDs; production IDs remain unconfigured.')
