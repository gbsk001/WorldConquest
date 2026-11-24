"""Write measured bot performance and source change inventory."""
from pathlib import Path
import json
r=Path(__file__).resolve().parents[1]
before=json.loads((r/'build/stage9-earth-benchmarks-before.json').read_text())
after=json.loads((r/'build/stage9-earth-benchmarks.json').read_text())
for a,b in zip(before,after):
 for key in ['bots','repeat','digest','decisions','orders','raw_bytes','peak_bytes']:assert a[key]==b[key],key
lines=['# Stage 9 measured performance','',
'All figures are standalone Luau simulations, **not Roblox Studio/live tests**. Each run uses the actual 8192×4096 Earth terrain, 20/50/100 autonomous Normal bots plus one idle human, default fair resources, two decisions per tick, 64 border-slot probes, and 600 measured ticks (60 simulation seconds). The countdown is shortened in the fixture; ten setup ticks are excluded from steady-state statistics and their worst cost is reported separately. Each repeat starts a fresh process. This is early expansion, not a rich late-game naval/nuclear match.', '',
'The before uses the prior 128-page terrain cache with linear eviction search. The after uses a 4,096-page server cache and O(1) linked eviction. Identical final packed-grid/reserve/gold digests, decision/order counts and total/peak raw payloads are required between repeats and before/after. Timings vary with scheduling and GC; averages below are means of two runs, p95/worst are maximum observed across the two.', '',
'| Bots (+1 human) | Before avg / p95 / worst ms | After avg / p95 / worst ms | After AI worst ms | Startup worst ms |', '|---:|---:|---:|---:|---:|']
for count in [20,50,100]:
 def group(rows):return [x for x in rows if x['bots']==count]
 b,a=group(before),group(after)
 def timing(rows):return f'{sum(x["average_ms"] for x in rows)/len(rows):.2f} / {max(x["p95_ms"] for x in rows):.2f} / {max(x["worst_ms"] for x in rows):.2f}'
 lines.append(f'| {count} | {timing(b)} | {timing(a)} | {max(x["ai_worst_ms"] for x in a):.2f} | {max(x["startup_worst_ms"] for x in a):.2f} |')
lines+=['','| Bots | After heap start / peak / end MiB | Raw buffers total / peak tick bytes | Decisions / orders |', '|---:|---:|---:|---:|']
for count in [20,50,100]:
 a=[x for x in after if x['bots']==count];first=a[0]
 mem=' / '.join(f'{max(x[k] for x in a)/1024:.1f}' for k in ['heap_start_kib','heap_peak_kib','heap_end_kib'])
 lines.append(f'| {count} | {mem} | {int(first["raw_bytes"]):,} / {int(first["peak_bytes"]):,} | {int(first["decisions"])} / {int(first["orders"])} |')
lines+=['',
'Heap is gcinfo() including loaded modules and the harness, with peak sampled at tick boundaries and end after digest work. It is not Roblox server RSS, device memory or proof of a leak. The terrain cache is bounded at 16 MiB on enabled Stage 9 servers; the default client decoded cache stays 512 KiB. Overall heap remains substantial at 100 bots.', '',
'Raw buffers count ownership/building/ship deltas before optional uniform-state encoding. Metadata, private stats, packet headers, compression, real transport and client paint/upload costs are excluded. Bots do not receive network packets; these cases have one idle human. Do not interpret 100 bots as 100 receiving Roblox clients.', '',
'Twenty bots pass the earlier <20 ms average / <50 ms p95 / <100 ms worst targets in this early workload. Fifty bots fail p95/worst; 100 bots fail all three. Five bots remain the default. No live capacity is certified. Earlier Stage 8 simultaneous-impact and Stage 6 adversarial naval-path stalls remain additional risks. Keep 50/100 as stress configurations until measured/fixed in realistic long sessions.', '',
'The compact 512×256 fixture separately checks two identical 600-tick replays at each requested bot count. Its timings are logged in build/stage9-results.txt and must not replace these Earth figures. The direct parity suite compares 300 original nation personalities and 30 original nuclear helper cases. Full Stage 1–8 regressions and GUI adapter checks are separate from performance acceptance.', '',
'Reproduce with `python scripts/benchmark_bots.py` and `python scripts/report_stage9.py`. Source behavior, configuration, deviations and Studio steps are in [Stage 9 implementation](STAGE9_IMPLEMENTATION.md).', '']
(r/'docs/STAGE9_PERFORMANCE.md').write_text('\n'.join(lines),encoding='utf-8')
print('Stage 9 Earth before/after digests and payloads match. Wrote performance report.')
