"""Create an isolated native renderer workload from a built release file."""
from pathlib import Path
import sys,xml.etree.ElementTree as E
r=Path(__file__).resolve().parents[1]
label=sys.argv[1] if len(sys.argv)>1 else 'after'
source=r/'build/WorldConquest-stage10.rbxlx'
tree=E.parse(source);root=tree.getroot()
for item in root.iter('Item'):
 if item.attrib.get('class') in ('Script','LocalScript'):
  props=item.find('Properties');el=next((x for x in props if x.attrib.get('name')=='Disabled'),None)
  if el is None:el=E.SubElement(props,'bool',{'name':'Disabled'})
  el.text='true'
sps=next(e for e in root.iter('Item')if e.attrib.get('class')=='StarterPlayerScripts')
item=E.SubElement(sps,'Item',{'class':'LocalScript','referent':'RendererAcceptance'})
props=E.SubElement(item,'Properties');E.SubElement(props,'string',{'name':'Name'}).text='RendererAcceptance'
script=(r/('scripts/render_population_acceptance.client.luau' if '--population' in sys.argv else 'scripts/render_acceptance.client.luau')).read_text()
if '--startup' in sys.argv:
 assert '--population' in sys.argv
 script=script.replace('local counts={20,50,100,200,250,500}', 'local counts={20}')
E.SubElement(props,'ProtectedString',{'name':'Source'}).text=script
tree.write(r/f'build/WorldConquest-render-{label}.rbxlx',encoding='utf-8',xml_declaration=True)
print('Created renderer-only fixture:',label)
