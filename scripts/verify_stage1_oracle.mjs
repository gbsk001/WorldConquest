// Re-run the pinned upstream implementations against the committed input vectors.
// Run: node scripts/verify_stage1_oracle.mjs (requires the audited build/OpenFrontIO checkout).
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import {fileURLToPath, pathToFileURL} from 'node:url';
import path from 'node:path';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const manifest=JSON.parse(await fs.readFile(path.join(root,'docs/openfront-audit-manifest.json'),'utf8'));
const oracle=JSON.parse(await fs.readFile(path.join(root,'tests/stage1/upstream-oracle.json'),'utf8'));
if(oracle.commit!==manifest.commit) throw Error('Oracle revision mismatch');
async function source(name) {
  const bytes=await fs.readFile(path.join(root,'build/OpenFrontIO',name));
  if(crypto.createHash('sha256').update(bytes).digest('hex')!==manifest.upstream_files[name]) throw Error('Unaudited source: '+name);
  return bytes.toString('utf8');
}
let rng=await source('packages/engine-lib/src/PseudoRandom.ts');
rng=rng.slice(0,rng.indexOf('  // Generates a random ID'))+'}\n';
rng=rng.replace(/\b(private|readonly)\s+/g,'').replace(/: \[number, number, number, number\]/g,'').replace(/: (number\[\]|number|PseudoRandom)/g,'').replace(/ as PseudoRandom/g,'');
let heap=await source('packages/engine/src/execution/utils/FlatBinaryHeap.ts');
heap=heap.slice(heap.indexOf('/**'));
heap=heap.slice(0,heap.indexOf('  /**\n   * Live entries'))+heap.slice(heap.indexOf('  /** double the underlying storage */'));
heap=heap.replace(/\bprivate\s+/g,'').replace(/: (Float32Array|TileRef\[\]|TileRef|number|void)/g,'').replace(/<TileRef>/g,'');
const math=(await source('packages/engine-lib/src/DetMath.ts')).replace(/: number/g,'');
const target=path.join(root,'build/stage1-verified-upstream.mjs');
await fs.writeFile(target,rng+'\n'+heap+'\n'+math);
const upstream=await import(pathToFileURL(target));
const same=(a,b)=>{if(JSON.stringify(a)!==JSON.stringify(b))throw Error('Upstream oracle mismatch');};
for(const c of oracle.rng) {
  const r=new upstream.PseudoRandom(c.seed);same(r.getState(),c.initial);
  same(Array.from({length:c.values.length},()=>r.next()),c.values);same(r.getState(),c.state);
}
const h=new upstream.FlatBinaryHeap(2), popped=[];
for(const op of oracle.heap.ops) if(op[0]==='push')h.enqueue(op[1],op[2]);else popped.push(h.dequeue());
same(popped,oracle.heap.dequeues);
for(const c of oracle.math) same(upstream[c.name](...c.args),c.value);
export const result='Pinned source hashes and all committed RNG/heap/math oracle values verified.';
console.log(result);
