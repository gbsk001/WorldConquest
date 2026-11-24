"""Validate replay equivalence and append measured CLI tables to acceptance report."""
from pathlib import Path
import json
r=Path(__file__).resolve().parents[1]
before=json.loads((r/'build/scalability-before.json').read_text())
after=json.loads((r/'build/scalability-after.json').read_text())
lines=['\n## Active gameplay measurements\n',
 '| Participants | Before avg / p95 / worst ms | After avg / p95 / worst ms | Peak heap MiB before → after |',
 '|---:|---:|---:|---:|']
for a,b in zip(before,after):
 for key in ['bots','raw_bytes','peak_bytes','decisions','orders','digest','metadata_estimate_bytes','selected_before_start']:
  assert a[key]==b[key],(key,a,b)
 def timings(x):return ' / '.join(f'{x[k]:.2f}'for k in ['average_ms','p95_ms','worst_ms'])
 lines.append(f"| {int(b['bots'])} | {timings(a)} | {timings(b)} | {a['heap_peak_kib']/1024:.1f} → {b['heap_peak_kib']/1024:.1f} |")
lines+=['','All five before/after replay digests, raw delta bytes, decisions, orders and metadata estimates agree. These runs do not pass a strict 100 ms worst-tick gate. Heap is sampled Luau heap, not total server process memory.','',
 '| Participants | Raw delta MiB / 180 s | Peak raw delta KiB / tick | Estimated metadata MiB (including selection) |',
 '|---:|---:|---:|---:|']
for x in after:
 lines.append(f"| {int(x['bots'])} | {x['raw_bytes']/1048576:.2f} | {x['peak_bytes']/1024:.2f} | {x['metadata_estimate_bytes']/1048576:.2f} |")
lines+=['','Raw volume excludes RemoteEvent framing, compression, Roblox transport and receiver fan-out. Metadata is a structural estimate, not serialized packet capture. Native multi-client wire measurements are still required.','']
hotspots=json.loads((r/'build/scalability-hotspots.json').read_text())
lines+=['## Focused path and impact measurements','',
 '| Route start → destination | Before ms | After ms | Result |',
 '|---|---:|---:|---|']
for a,b in zip(hotspots['before']['paths'].splitlines(),hotspots['after']['paths'].splitlines()):
 a=a.split();b=b.split();assert a[1:3]+a[4:6]==b[1:3]+b[4:6]
 lines.append(f'| {b[1]} → {b[2]} | {float(a[3]):.2f} | {float(b[3]):.2f} | {b[4]} cells; identical hash {b[5]} |')
lines+=['','These are isolated raw queries (single start, cold then shared-cache searches). A -1 result reaches the unchanged search cap. They are not identical to every multi-start route in active gameplay. No sub-100-ms bound is claimed.','',
 '| Salvo / participants | Worst simulation ms before → after | Worst including encoding ms before → after | Peak encoded application bytes before → after |',
 '|---|---:|---:|---:|']
for name in ['salvo50','salvo100','flat50','flat100']:
 a=next(x for x in hotspots['before'][name].splitlines()if x.startswith('BENCH ')).split()
 b=next(x for x in hotspots['after'][name].splitlines()if x.startswith('BENCH ')).split()
 for i in [1,8,9,10,11,12]:assert a[i]==b[i]
 lines.append(f'| {name} | {float(a[4]):.2f} → {float(b[4]):.2f} | {float(a[18]):.2f} → {float(b[18]):.2f} | {a[14]} → {b[14]} |')
lines+=['','`salvo` uses actual Earth and `flat` the original all-land stress geometry. Identical final state, ordered border/territory, troops, impact timing and raw bytes are verified. Encoding CPU is additional to simulation; smaller payloads do not prove lower Roblox wire traffic or a faster simulation.','']
p=r/'docs/SCALABILITY_ACCEPTANCE_2026-11-24.md'
s=p.read_text();s=s.split('\n## Active gameplay measurements')[0];p.write_text(s+'\n'.join(lines))
print('All five active gameplay state/payload/replay comparisons passed; report tables updated.')
