"""Inject real icon registry/decoder into GUI service substitutes, never render certification."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def icons():
 h='\nlocal iconData={}\n'
 for p in sorted((ROOT/'src/client/IconData').glob('*.luau')):
  h+='iconData["'+p.stem+'"]=(function()\n'+p.read_text()+'\nend)()\n'
 h+='function iconData:FindFirstChild(name)return self[name]end\n'
 s=(ROOT/'src/client/IconAssets.luau').read_text().replace('local data=script.Parent.IconData','local data=iconData\nlocal require=function(v)return v end')
 h+='local function createIconAssets()\n'+s+'\nend\nlocal IconAssets=createIconAssets()\n'
 return h
def art(s):return s.replace('local Icons=require(script.Parent.IconAssets)','local Icons=IconAssets')
