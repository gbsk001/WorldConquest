"""Build a separate Studio-only population candidate. Does not start a simulation.
Public source Config and public place are never edited. Rojo overlays only Config.
"""
from pathlib import Path
import json, subprocess, hashlib, xml.etree.ElementTree as ET
r=Path(__file__).resolve().parents[1]
def literal(v):
 if isinstance(v,bool):return str(v).lower()
 if isinstance(v,str):return json.dumps(v)
 assert isinstance(v,(int,float));return str(v)
def local_config():
 base=(r/'src/shared/Config.luau').read_text(encoding='utf-8-sig')
 profile=json.loads((r/'tests/stage15/local-profile.json').read_text())
 assert profile['studio_only']is True
 assert profile['overrides']['Population']['SafeParticipants']==20
 assert profile['overrides']['BasicNations']['SafeCount']==300
 block='\n-- Generated LOCAL preview: larger population never applies on a live server.\nif game:GetService("RunService"):IsStudio() then\n'
 for group,fields in profile['overrides'].items():
  assert group in ('BasicNations','Population','Bots')
  for key,value in fields.items():
   assert key.isidentifier();block+=f' Config.{group}.{key}={literal(value)}\n'
 block+=' Config.LocalPopulationPreview=true\nend\nreturn Config\n'
 assert base.rstrip().endswith('return Config')
 return base.rsplit('return Config',1)[0]+block
def main():
 out=r/'build';out.mkdir(exist_ok=True)
 config=out/'stage15-local-config.luau';config.write_text(local_config(),encoding='utf-8')
 project=json.loads((r/'default.project.json').read_text())
 def absolute(node):
  if not isinstance(node,dict):return
  if '$path'in node:node['$path']=(r/node['$path']).as_posix()
  for value in node.values():absolute(value)
 absolute(project)
 project['name']='WorldConquest Stage15 LOCAL 300'
 project['tree']['ReplicatedStorage']['Shared']['Config']={'$path':config.as_posix()}
 path=out/'stage15-local.project.json';path.write_text(json.dumps(project,indent=2),encoding='utf-8')
 artifact=out/'WorldConquest-stage15-LOCAL-300-grey-20-competitive.rbxlx'
 subprocess.run([str(Path.home()/'.aftman/bin/rojo.exe'),'build',str(path),'--output',str(artifact)],check=True,cwd=r)
 sources=[e.text or '' for e in ET.parse(artifact).findall('.//Properties/*')if e.attrib.get('name')=='Source']
 assert sources.count(local_config())==1
 for p in (r/'src').rglob('*.luau'):
  if p!=r/'src/shared/Config.luau':assert p.read_text(encoding='utf-8-sig')in sources,p
 info={'artifact':artifact.relative_to(r).as_posix(),'sha256':hashlib.sha256(artifact.read_bytes()).hexdigest(),'studio_only':True,'simulated':False,'benchmarked':False,'public_config_modified':False}
 (out/'stage15-local-build.json').write_text(json.dumps(info,indent=2))
 print(json.dumps(info,indent=2))
if __name__=='__main__':main()
