"""Disposable Studio fixture. Never publish this output. Build release first."""
from pathlib import Path
import xml.etree.ElementTree as E
r=Path(__file__).resolve().parents[1]
tree=E.parse(r/'build/WorldConquest-stage10.rbxlx');root=tree.getroot()
for el in root.findall('.//Properties/*'):
 if el.attrib.get('name')!='Source' or not el.text:continue
 if 'StartingGold="0"' in el.text:
  el.text=el.text.replace('StartingGold="0"','StartingGold="50000000"').replace('InstantBuild=false','InstantBuild=true')
 if 'bridge.BotSettings={Enabled=state.Bots>0' in el.text:
  el.text=el.text.replace('bridge.BotSettings={Enabled=state.Bots>0','bridge.BotSettings={Enabled=false')
sps=next(e for e in root.iter('Item')if e.attrib.get('class')=='StarterPlayerScripts')
item=E.SubElement(sps,'Item',{'class':'LocalScript','referent':'IconPreviewFixture'})
props=E.SubElement(item,'Properties');E.SubElement(props,'string',{'name':'Name'}).text='IconPreviewFixture'
E.SubElement(props,'ProtectedString',{'name':'Source'}).text=(r/'scripts/icon_preview.client.luau').read_text()
tree.write(r/'build/WorldConquest-icon-preview.rbxlx',encoding='utf-8',xml_declaration=True)
print('TEST ONLY: extra gold, instant buildings, AI execution disabled, G toggles icon gallery. Not release gameplay.')
