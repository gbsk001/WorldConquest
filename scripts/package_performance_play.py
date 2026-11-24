"""Add read-only measurements to a disposable production gameplay fixture."""
from pathlib import Path
import xml.etree.ElementTree as E
r=Path(__file__).resolve().parents[1]
tree=E.parse(r/'build/WorldConquest-stage10.rbxlx')
sps=next(e for e in tree.getroot().iter('Item')if e.attrib.get('class')=='StarterPlayerScripts')
item=E.SubElement(sps,'Item',{'class':'LocalScript','referent':'PerformanceObserver'})
props=E.SubElement(item,'Properties')
E.SubElement(props,'string',{'name':'Name'}).text='PerformanceObserver'
E.SubElement(props,'ProtectedString',{'name':'Source'}).text=(r/'scripts/studio_performance_observer.client.luau').read_text()
tree.write(r/'build/WorldConquest-performance-play.rbxlx',encoding='utf-8',xml_declaration=True)
print('Created production gameplay fixture with read-only performance observer')
