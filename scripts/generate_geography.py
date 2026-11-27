"""Public-domain Natural Earth II terrain colour tiles; no gameplay data changes.
Build dependency: Pillow 13.0.0. Source raster and visual grid are 10800x5400; simulation stays 8192x4096.
"""
from pathlib import Path
import sys, zipfile, hashlib, json, struct, base64
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'build/stage14libs'))
from PIL import Image
Image.MAX_IMAGE_PIXELS=None
sys.path.insert(0,str(ROOT/'scripts'))
source=ROOT/'data/NE2_50M_SR.zip'
if not source.exists():source.write_bytes((ROOT/'build/NE2_50M_SR.zip').read_bytes())
assert hashlib.sha256(source.read_bytes()).hexdigest()=='0e9838cb3acb10ce4674b74a8f79bd5aae02e4b715185d54f018afaf4d9451f4', 'Source raster changed'
with zipfile.ZipFile(source) as z:
 image=Image.open(z.open('NE2_50M_SR/NE2_50M_SR.tif'));assert image.size==(10800,5400)
 transform=z.read('NE2_50M_SR/NE2_50M_SR.tfw').decode().split()
 assert abs(float(transform[0])-360/10800)<1e-10 and float(transform[3])<0
 native_width,native_height=image.size
 # Shared natural palette; deterministic quantisation without dithering/noise.
 pal=image.quantize(colors=128,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
 palette=pal.getpalette()[:384]
 target=ROOT/'src/shared/Geography';target.mkdir(exist_ok=True)
 sizes=[]
 for level in range(7):
  w,h=(native_width+2**level-1)//2**level,(native_height+2**level-1)//2**level
  indexed=pal if level==0 else image.resize((w,h),Image.Resampling.BOX).quantize(palette=pal,dither=Image.Dither.NONE)
  tiles=[];width=min(w,64);height=min(h,64)
  for ty in range(0,h,64):
   for tx in range(0,w,64):
    raw=indexed.crop((tx,ty,tx+width,ty+height)).tobytes();encoded=bytearray();start=0
    while start<len(raw):
     end=start+1
     while end<len(raw) and raw[end]==raw[start] and end-start<256:end+=1
     encoded+=bytes((end-start-1,raw[start]));start=end
    # Literal raw pages when RLE is larger. Each page is at most 4096 bytes.
    tiles.append(bytes([1])+encoded if len(encoded)<len(raw) else bytes([0])+raw)
  # Each lazy group is bounded; loading a close-zoom tile never parses a whole continent.
  group_size=128
  for group in range((len(tiles)+group_size-1)//group_size):
   part='-- Natural Earth II v3.2.0, public domain; generated immutable page group.\nreturn {\n'+',\n'.join(chr(34)+base64.b64encode(x).decode()+chr(34) for x in tiles[group*group_size:(group+1)*group_size])+'\n}\n'
   (target/f'Level{level}Part{group+1}.luau').write_text(part,encoding='utf-8')
  contents='-- Generated from Natural Earth II v3.2.0, public domain. See data/geography-manifest.json.\nreturn {Width='+str(w)+',Height='+str(h)+',TileWidth='+str(width)+',TileHeight='+str(height)+',GroupSize='+str(group_size)+'}\n'
  (target/f'Level{level}.luau').write_text(contents,encoding='utf-8');sizes.append(sum(map(len,tiles)))
 (target/'Palette.luau').write_text('-- Natural Earth II public-domain colour palette.\nreturn {'+','.join(str(palette[i]+palette[i+1]*256+palette[i+2]*65536) for i in range(0,384,3))+'}\n')
 image.resize((1024,512),Image.Resampling.LANCZOS).save(ROOT/'build/stage14-geography-preview.png')
manifest={'dataset':'Natural Earth II v3.2.0 shaded relief, idealized land cover','url':'https://naturalearth.s3.amazonaws.com/50m_raster/NE2_50M_SR.zip','license':'Public domain','license_url':'https://www.naturalearthdata.com/about/terms-of-use/','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'source_dimensions':[10800,5400],'display_dimensions':[10800,5400],'simulation_dimensions':[8192,4096],'projection':'Equirectangular; original georeferencing retained','palette_colors':128,'encoded_bytes_per_level':sizes,'method':'Retain native source resolution independently of simulation, median-cut palette, no dithering; prefiltered display LODs. Existing detailed land/lake mask is authoritative.','limitations':'Idealized land cover and shaded relief, not current satellite photography or a new elevation DEM. ETOPO gameplay elevation remains unchanged.'}
(ROOT/'data/geography-manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps(manifest,indent=2))
