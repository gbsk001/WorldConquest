"""Build packed terrain/water topology from the unchanged Natural Earth mask.

OpenFront's terrain bit layout, largest-water-body ocean classification, cardinal
shore detection and ceil(water distance / 2) encoding are used. No small lakes
are removed. Land elevation is UNKNOWN (magnitude 0), not invented mountain data.
"""
from pathlib import Path
from array import array
import hashlib,json,struct,sys
sys.path.insert(0,str(Path(__file__).parent))
from generate_earth import literal
ROOT=Path(__file__).resolve().parents[1]

def generate():
    manifest=json.loads((ROOT/'data/earth-manifest.json').read_text())
    mask=(ROOT/'build/earth-mask.bin').read_bytes()
    assert hashlib.sha256(mask).hexdigest()==manifest['mask_sha256']
    w,h=manifest['width'],manifest['height']; size=w*h
    parent=[]; areas=[]; rows=[]
    def find(i):
        while parent[i]!=i:
            parent[i]=parent[parent[i]]; i=parent[i]
        return i
    def union(a,b):
        a,b=find(a),find(b)
        if a!=b: parent[max(a,b)]=min(a,b)
    previous=[]
    for y in range(h):
        row=mask[y*w:(y+1)*w]; spans=[]; x=0
        while x<w:
            if row[x]: x+=1; continue
            start=x
            while x<w and not row[x]: x+=1
            label=len(parent);parent.append(label);areas.append(x-start)
            spans.append((start,x,label))
        j=0
        for start,end,label in spans:
            while j<len(previous) and previous[j][1]<=start:j+=1
            k=j
            while k<len(previous) and previous[k][0]<end:
                union(label,previous[k][2]);k+=1
        rows.append(spans);previous=spans
    totals={}
    for i,area in enumerate(areas):
        root=find(i);totals[root]=totals.get(root,0)+area
    ids={r:i+1 for i,r in enumerate(sorted(totals))}
    ocean=max(totals,key=totals.get)
    water=bytearray()
    for spans in rows:
        water+=struct.pack('<H',len(spans))
        for start,end,label in spans:water+=struct.pack('<HHI',start,end-start,ids[find(label)])
    print(f'{len(ids)} distinct water components; largest {totals[ocean]:,} cells',flush=True)
    # Exact city-block distance transform, saturated at 63 (packed depth max 31).
    dist=bytearray(0 if v else 63 for v in mask)
    for y in range(h):
        for x in range(w):
            i=y*w+x
            if dist[i]:
                v=dist[i]
                if x:v=min(v,dist[i-1]+1)
                if y:v=min(v,dist[i-w]+1)
                dist[i]=v
    for y in range(h-1,-1,-1):
        for x in range(w-1,-1,-1):
            i=y*w+x
            if dist[i]:
                v=dist[i]
                if x+1<w:v=min(v,dist[i+1]+1)
                if y+1<h:v=min(v,dist[i+w]+1)
                dist[i]=v
    terrain=bytearray(size)
    for i,value in enumerate(mask):
        if value:
            x=i%w
            shore=(x>0 and not mask[i-1]) or (x+1<w and not mask[i+1]) or (i>=w and not mask[i-w]) or (i<size-w and not mask[i+w])
            terrain[i]=128+(64 if shore else 0)
        else:terrain[i]=(64 if dist[i]==1 else 0)+dist[i]//2
    for y,spans in enumerate(rows):
        for start,end,label in spans:
            if find(label)==ocean:
                for i in range(y*w+start,y*w+end):terrain[i]|=32
    packed=bytearray()
    for offset in range(0,size,4096):
        block=terrain[offset:offset+4096];runs=bytearray();i=0
        while i<len(block):
            start=i;v=block[i]
            while i<len(block) and block[i]==v:i+=1
            runs+=struct.pack('<HB',i-start,v)
        packed+=struct.pack('<I',len(runs))+runs
    parts=['--!strict','-- Generated Natural Earth topology. Public domain geography; see data/README.md.',
      'return {',f'Width={w}, Height={h}, LandCount={manifest["land_cells"]}, OceanComponent={ids[ocean]},',
      'ElevationKnown=false,',f'MaskHash="{manifest["mask_sha256"]}",',
      f'TerrainHash="{hashlib.sha256(terrain).hexdigest()}",','Blocks='+literal(packed)+',','WaterRuns='+literal(water)+',','}']
    (ROOT/'src/shared/OpenFront/EarthTopologyData.luau').write_text('\n'.join(parts)+'\n')
    (ROOT/'build/earth-terrain.bin').write_bytes(terrain)
    report={'mask_sha256':manifest['mask_sha256'],'terrain_sha256':hashlib.sha256(terrain).hexdigest(),'water_components':len(ids),'ocean_cells':totals[ocean],'terrain_rle_bytes':len(packed),'water_run_bytes':len(water),'elevation_known':False}
    (ROOT/'data/earth-topology-manifest.json').write_text(json.dumps(report,indent=2)+'\n')
    print(report,flush=True)
if __name__=='__main__':generate()
