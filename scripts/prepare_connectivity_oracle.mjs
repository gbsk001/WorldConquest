// Runs pinned upstream PlayerExecution unchanged apart from TypeScript erasure and import wiring.
// Copyright OpenFront and Contributors; AGPL-3.0.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import {stripTypeScriptTypes} from 'node:module';
const root=new URL('../',import.meta.url);
const manifest=JSON.parse(await fs.readFile(new URL('docs/openfront-audit-manifest.json',root),'utf8'));
async function source(path){const b=await fs.readFile(new URL('build/OpenFrontIO/'+path,root));if(crypto.createHash('sha256').update(b).digest('hex')!==manifest.upstream_files[path])throw Error('source hash '+path);return b.toString();}
let player=await source('packages/engine/src/execution/PlayerExecution.ts');
player=player.slice(player.indexOf('const TICKS_PER_CLUSTER_CALC'),player.indexOf('  snapshot('))+'}\n';
let scratch=await source('packages/engine/src/game/TileTraversalScratch.ts');
scratch=scratch.replace(/^import[\s\S]*?;\r?\n/gm,'');
let util=await source('packages/engine-lib/src/Util.ts');
const mode=util.slice(util.indexOf('export function getMode'),util.indexOf('export function calculateBoundingBoxCenter'));
const hash=util.slice(util.indexOf('export function simpleHash'),util.indexOf('export function calculateBoundingBox('));
const prelude="class Cell {constructor(x,y){this.x=x;this.y=y;}}\nconst Structures=new Set(),UnitType={},PlayerType={Bot:'Bot'};\n";
const output=stripTypeScriptTypes(prelude+scratch+mode+hash+player,{mode:'transform'});
await fs.writeFile(new URL('build/connectivity-upstream.mjs',root),output);
export const summary='Hash-verified PlayerExecution and TileTraversalScratch prepared using Node TypeScript erasure.';
