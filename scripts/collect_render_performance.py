"""Extract genuine Studio renderer measurements; never synthesize missing rows."""
from pathlib import Path
import re,json,sys
r=Path(__file__).resolve().parents[1]
label=sys.argv[1];source=Path(sys.argv[2])
text=source.read_text(errors='replace')
pattern=r'PERFORMANCE_RENDER (\d+) (warmup|overview|detail|zoom/pan): ([\d.]+) FPS / avg ([\d.]+) p95 ([\d.]+) worst ([\d.]+) ms / total ([\d.]+) MiB heap ([\d.]+) MiB'
rows=[dict(zip(['participants','phase','fps','average_ms','p95_ms','worst_ms','studio_total_mib','luau_heap_mib'],[int(n),phase,*map(float,vals)]))for n,phase,*vals in re.findall(pattern,text)]
startup=re.findall(r'CLIENT_STARTUP load_seconds ([\d.]+) worst_frame_ms ([\d.]+)',text)
assert len(rows)==24,(source,len(rows))
result={'scope':'Roblox Studio Play Solo, isolated renderer with synthetic participants; not multiplayer server capacity','source_log':str(source),'startup':startup,'rows':rows}
(r/f'build/render-performance-{label}.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
