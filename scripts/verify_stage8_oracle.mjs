// Run in a fresh Node process after preparing the existing Stage 1 DetMath oracle.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
const root=new URL('../',import.meta.url),path=new URL('tests/stage8/upstream-oracle.json',root);
const before=await fs.readFile(path);
await import('./prepare_missile_oracle.mjs');
await import('./generate_missile_oracle.mjs');
const after=await fs.readFile(path);
if(!before.equals(after)){
 await fs.writeFile(new URL('build/stage8-oracle-drift.json',root),after);
 await fs.writeFile(path,before);
 throw Error('Oracle regeneration drift; original fixture restored. Inspect build/stage8-oracle-drift.json.');
}
const report={byteIdentical:true,sha256:crypto.createHash('sha256').update(after).digest('hex'),commit:'8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94'};
await fs.writeFile(new URL('tests/stage8/regeneration.json',root),JSON.stringify(report,null,2));
export const summary=report;
