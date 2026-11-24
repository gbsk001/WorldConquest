"""Export authored interface strings for review/Roblox translation-table import."""
from pathlib import Path
import csv, json, re
r=Path(__file__).resolve().parents[1]
s=(r/'src/shared/LocaleStrings.luau').read_text(encoding='utf-8')
quoted=r'"(?:[^"\\]|\\.)*"'
rows={}
for match in re.finditer(r'\{('+quoted+r'),('+quoted+r'),('+quoted+r')\}',s):
    en,es,fr=[json.loads(v) for v in match.groups()]
    rows[en]=(en,es,fr)
out=r/'data/localisation.csv'
with out.open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.writer(f);w.writerow(['Key','Source','Context','Example','en','es','fr'])
    for i,(en,es,fr) in enumerate(sorted(rows.values())):
        w.writerow(['wc_'+str(i),en,'','',en,es,fr])
print(f'Exported {len(rows)} unique authored source strings, English/Spanish/French. Dynamic templates live in LocaleStrings; linguistic/rendered review is pending.')
