"""Generate a geographically aligned terrain-class overlay from NOAA ETOPO 2022.
Data adaptation: metres -> OpenFront class, NOT a claimed upstream DEM rule.
Dependencies are build-only: numpy, tifffile, imagecodecs (see requirements-elevation.txt).
"""
from pathlib import Path
import sys,hashlib,json,struct
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'build/pythonlibs'))
import numpy as np
import tifffile
sys.path.insert(0,str(ROOT/'scripts'))
from generate_earth import literal
PATH=ROOT/'build/ETOPO_2022_v1_60s_N90W180_surface.tif'
URL='https://www.ngdc.noaa.gov/mgg/global/relief/ETOPO2022/data/60s/60s_surface_elev_gtif/ETOPO_2022_v1_60s_N90W180_surface.tif'
source_sha=hashlib.sha256(PATH.read_bytes()).hexdigest()
assert source_sha=="9d27d4b8ea8e76977e2988bca667d7c8fa68b927355feffcddd6b4875a7fd08e", "ETOPO source changed"
w,h=8192,4096
with tifffile.TiffFile(PATH) as f:
 p=f.pages[0]
 assert p.shape==(10800,21600) and str(p.dtype)=='float32'
 assert p.tags['ModelTiepointTag'].value==(0.,0.,0.,-180.,90.,0.)
 assert p.tags['ModelPixelScaleTag'].value[:2]==(1/60,1/60)
 assert 4326 in p.tags['GeoKeyDirectoryTag'].value
 # Disk-backed decoding avoids keeping the full 933 MB DEM in a Python heap.
 dem=p.asarray(out=str(ROOT/'build/etopo-decoded.memmap'))
 x=np.floor((np.arange(w)+.5)*21600/w).astype(np.int32)
 y=np.floor((np.arange(h)+.5)*10800/h).astype(np.int32)
 height=dem[np.ix_(y,x)]
 assert np.isfinite(height).all() and height.min()>-12000 and height.max()<10000
mask=np.frombuffer((ROOT/'build/earth-mask.bin').read_bytes(),dtype=np.uint8).reshape(h,w)!=0
# No universally defined metres-to-magnitude rule exists in the upstream PNG generator.
# Explicit adapter: <1000m plains, 1000..<2000m highland, >=2000m mountain.
classes=np.where(mask,np.where(height>=2000,20,np.where(height>=1000,10,0)),0).astype(np.uint8)
raw=classes.tobytes();packed=bytearray()
for offset in range(0,len(raw),4096):
 block=raw[offset:offset+4096];runs=bytearray();i=0
 while i<len(block):
  first=i;v=block[i]
  while i<len(block) and block[i]==v:i+=1
  runs+=struct.pack('<HB',i-first,v)
 packed+=struct.pack('<I',len(runs))+runs
sha=hashlib.sha256(raw).hexdigest()
(ROOT/'data/earth-elevation-rle.bin').write_bytes(packed)
(ROOT/'build/earth-elevation-classes.bin').write_bytes(raw)
samples=[]
for name,lon,lat in [('Himalaya',86,28),('Tibet',90,32),('Andes',-70,-32),('Netherlands',5,52),('Central Africa',20,5),('Rockies',-106,40),('Pacific',-140,0)]:
 xx=int((lon+180)/360*w);yy=int((90-lat)/180*h)
 samples.append(dict(name=name,longitude=lon,latitude=lat,cell=yy*w+xx,land=bool(mask[yy,xx]),metres=float(height[yy,xx]),magnitude=int(classes[yy,xx])))
manifest=dict(dataset='NOAA NCEI ETOPO 2022 v1, 60 arc-second ice surface',url=URL,doi='10.25921/fd45-gt74',license='CC0-1.0',license_source='https://www.ncei.noaa.gov/access/metadata/landing-page/bin/iso?id=gov.noaa.ngdc.mgg.dem%3Aetopo_2022',accessed='2026-11-18',source_sha256=source_sha,class_sha256=sha,land_mask_sha256=hashlib.sha256((ROOT/'build/earth-mask.bin').read_bytes()).hexdigest(),width=w,height=h,method='nearest source sample at target pixel centre; existing Natural Earth land/lake mask unchanged',thresholds_metres=[1000,2000],upstream_deviation='DEM classification adapter, not upstream PNG artwork or a source-defined metre conversion',classes={str(v):int(np.count_nonzero(mask & (classes==v))) for v in [0,10,20]},encoded_bytes=len(packed),samples=samples)
(ROOT/'data/elevation-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(manifest,indent=2))

# Bake classes into the existing packed terrain to avoid a second runtime decode/merge.
base=np.frombuffer((ROOT/'build/earth-terrain.bin').read_bytes(),dtype=np.uint8).copy()
flat=classes.reshape(-1);land=(base & 128)!=0
base[land]=(base[land] & 224)|flat[land]
combined=base.tobytes();cp=bytearray()
for offset in range(0,len(combined),4096):
 block=combined[offset:offset+4096];runs=bytearray();i=0
 while i<len(block):
  first=i;v=block[i]
  while i<len(block) and block[i]==v:i+=1
  runs+=struct.pack('<HB',i-first,v)
 cp+=struct.pack('<I',len(runs))+runs
module=ROOT/'src/shared/OpenFront/EarthTopologyData.luau'
old=module.read_text();old=old.replace('-- Generated Natural Earth topology. Public domain geography; see data/README.md.','-- Natural Earth public-domain topology + NOAA ETOPO 2022 CC0 elevation; see data/README.md.');start=old.index('Blocks=');end=old.index('WaterRuns=')
old=old[:start]+'Blocks='+literal(cp)+',\n'+old[end:]
import re
combined_hash=hashlib.sha256(combined).hexdigest()
old=re.sub(r'TerrainHash="[^"]*"','TerrainHash="'+combined_hash+'"',old)
old=old.replace('ElevationKnown=false','ElevationKnown=true')
old=re.sub(r'ElevationHash="[^"]*",\n','',old)
old=old.replace('ElevationKnown=true,','ElevationKnown=true,\nElevationHash="'+sha+'",')
module.write_text(old)
(ROOT/'build/earth-terrain.bin').write_bytes(combined)
topology=ROOT/'data/earth-topology-manifest.json';tm=json.loads(topology.read_text())
tm.update(terrain_sha256=combined_hash,terrain_rle_bytes=len(cp),elevation_known=True,elevation_manifest='elevation-manifest.json')
topology.write_text(json.dumps(tm,indent=2)+'\n')
print('Baked combined terrain',len(cp),'encoded bytes; hash',combined_hash)
