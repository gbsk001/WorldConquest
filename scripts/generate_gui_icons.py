"""Rasterise audited Lucide SVGs, not hand-drawn geometry. No uploads or fake IDs."""
from pathlib import Path
import sys,json,hashlib,io,struct,base64,re
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'build/iconlibs'))
from PIL import Image,ImageDraw
import resvg_py
source=ROOT/'assets/lucide';manifest=json.loads((source/'manifest.json').read_text())
out=ROOT/'assets/gui-icons';out.mkdir(exist_ok=True)
generated=ROOT/'src/client/IconData';generated.mkdir(exist_ok=True)
names=sorted(manifest['sha256']);images=[]
for name in names:
 data=(source/(name+'.svg')).read_bytes();assert hashlib.sha256(data).hexdigest()==manifest['sha256'][name]
 svg=data.decode().replace('currentColor','white')
 svg=re.sub(r'width="24"','width="256"',svg);svg=re.sub(r'height="24"','height="256"',svg)
 png=resvg_py.svg_to_bytes(svg_string=svg)
 image=Image.open(io.BytesIO(png)).convert('RGBA');assert image.size==(256,256)
 images.append(image.resize((112,112),Image.Resampling.LANCZOS))
 (out/(name+'.png')).write_bytes(png)
cells={};previews=Image.new('RGB',(768,((len(names)+5)//6)*154),(19,29,44));draw=ImageDraw.Draw(previews)
for i,(name,image) in enumerate(zip(names,images)):
 previews.paste(image,((i%6)*128+8,(i//6)*154),image);draw.text(((i%6)*128+4,(i//6)*154+118),name,fill='white')
for page in range((len(names)+15)//16):
 atlas=Image.new('RGBA',(512,512),(255,255,255,0))
 for cell,name in enumerate(names[page*16:(page+1)*16]):
  x,y=(cell%4)*128,(cell//4)*128;atlas.paste(images[page*16+cell],(x+8,y+8))
  cells[name]=(page+1,x,y)
 atlas.save(out/f'LucideAtlas{page+1}.png')
 raw=atlas.getchannel('A').tobytes();runs=bytearray();start=0
 while start<len(raw):
  end=start+1
  while end<len(raw) and raw[end]==raw[start] and end-start<65535:end+=1
  runs+=struct.pack('<HB',end-start,raw[start]);start=end
 (generated/f'Page{page+1}.luau').write_text('-- Lucide ISC / Feather MIT. See assets/lucide/LICENSE. Generated alpha RLE.\nreturn "'+base64.b64encode(runs).decode()+'"\n',encoding='utf-8')
registry='-- Generated registry; pinned vector provenance in assets/lucide/manifest.json.\nreturn {\n'
for kind,name in manifest['icons'].items():
 page,x,y=cells[name];registry+=f' {kind}={{Page={page},X={x},Y={y},Source="{name}"}},\n'
flags=ROOT/'assets/flags';flags.mkdir(exist_ok=True)
atlas=Image.new('RGBA',(512,256),(0,0,0,0))
catalog=(ROOT/'src/shared/ProgressionCatalog.luau').read_text()
items=re.findall(r'ID="(flag_[^"]+)"[^\n]+Colors=\{([^}]+)\},Design="([^"]+)"',catalog)
assert len(items)<=8 and len(items)>0
for i,(key,values,design) in enumerate(items):
 colors=re.findall(r'"([A-Fa-f0-9]+)"',values)
 def rect(x,y,w,h,c):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#{c}"/>'
 shapes=rect(0,0,100,60,colors[0])
 if design=='Disc':shapes+=f'<circle cx="50" cy="30" r="18" fill="#{colors[1]}"/>'
 elif design=='Cross':
  shapes+=rect(28,0,14,60,colors[2])+rect(0,22.8,100,14.4,colors[2])+rect(31,0,8,60,colors[1])+rect(0,25.8,100,8.4,colors[1])
 elif design=='Vertical':shapes+=rect(100/3,0,100/3,60,colors[1])+rect(200/3,0,100/3,60,colors[2])
 else:shapes+=rect(0,20,100,20,colors[1])+rect(0,40,100,20,colors[2])
 svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="320" height="192" viewBox="0 0 100 60">{shapes}</svg>'
 (flags/(key+'.svg')).write_text(svg);png=resvg_py.svg_to_bytes(svg_string=svg);(flags/(key+'.png')).write_bytes(png)
 image=Image.open(io.BytesIO(png)).resize((120,72),Image.Resampling.LANCZOS)
 x,y=i%4*128,i//4*128;atlas.paste(image,(x+4,y+4))
 registry+=f' Flag_{key}={{Page=4,X={x},Y={y},Width=128,Height=80,Colored=true,Source="{key}"}},\n'
atlas.save(out/'FlagAtlas.png')
raw=atlas.tobytes();runs=bytearray();start=0
while start<len(raw):
 end=start+4
 while end<len(raw) and raw[end:end+4]==raw[start:start+4] and (end-start)//4<65535:end+=4
 runs+=struct.pack('<H',(end-start)//4)+raw[start:start+4];start=end
(generated/'Page4.luau').write_text('-- Original WorldConquest flags and national flag geometry. AGPL-3.0.\nreturn "'+base64.b64encode(runs).decode()+'"\n')
registry+='}\n';(generated/'Registry.luau').write_text(registry,encoding='utf-8')
previews.save(ROOT/'build/lucide-contact-sheet.png')
(out/'manifest.json').write_text(json.dumps({'source_commit':manifest['commit'],'source_pixels':256,'atlas_cell_pixels':128,'atlas_pages':4,'license':'../lucide/LICENSE','registry':manifest['icons']},indent=2))
print('Generated',len(names),'256px PNGs and three 512px icon atlases plus the original flag atlas. No Roblox assets uploaded.')
