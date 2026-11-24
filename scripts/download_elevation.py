from pathlib import Path
import urllib.request,hashlib
url='https://www.ngdc.noaa.gov/mgg/global/relief/ETOPO2022/data/60s/60s_surface_elev_gtif/ETOPO_2022_v1_60s_N90W180_surface.tif'
p=Path('build/ETOPO_2022_v1_60s_N90W180_surface.tif')
with urllib.request.urlopen(url,timeout=60) as r,p.open('wb') as out:
 while data:=r.read(4*1024*1024):out.write(data)
digest=hashlib.sha256(p.read_bytes()).hexdigest()
assert p.stat().st_size==465969062 and digest=='9d27d4b8ea8e76977e2988bca667d7c8fa68b927355feffcddd6b4875a7fd08e', 'Downloaded ETOPO differs from pinned source'
print(p.stat().st_size,digest)
