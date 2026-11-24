"""Original vector UI artwork, supersampled PNGs and embedded alpha atlas. AGPL-3.0."""
from pathlib import Path
import math,zlib,struct
r=Path(__file__).resolve().parents[1]

out=r/'assets/gui-icons';out.mkdir(parents=True,exist_ok=True)
icons={}
def icon(name,shapes):icons[name]=shapes
def p(*xy):return ('p',xy)
def c(x,y,rx,ry=None):return ('c',(x,y,rx,ry or rx))
def poly(*xy):return ('f',xy)
icon('Army',[poly(3,2,7,3,18,17,16,19,3,6,3,2),p(13,18,18,13),p(17,19,20,22),poly(21,2,17,3,6,17,8,19,21,6,21,2),p(6,13,11,18),p(7,19,4,22)])
city=[p(2,21,22,21),p(3,21,3,10,8,10),p(9,21,9,3,15,3,15,21),p(16,8,21,8,21,21),p(12,7,12,8),p(12,12,12,13),p(12,17,12,18),p(18,12,18,13),p(6,14,6,15)]
icon('Buildings',city)
icon('Navy',[poly(2,15,22,15,18,20,6,20),p(7,14,7,10,16,10,16,14),p(11,10,11,4),p(11,5,16,7,11,7),p(16,12,21,10),p(3,23,7,22,12,23,17,22,21,23)])
icon('Missiles',[p(7,16,7,8,12,2,17,8,17,16,7,16),c(12,9,2),p(7,12,3,17,3,20,7,18),p(17,12,21,17,21,20,17,18),p(10,19,10,22),p(14,19,14,22)])
trophy=[p(6,3,18,3,18,10,16,14,12,16,8,14,6,10,6,3),p(6,5,2,5,2,9,4,12,7,12),p(18,5,22,5,22,9,20,12,17,12),p(12,16,12,21),p(7,22,17,22)]
icon('Leaderboard',trophy)
gear=[]
for i in range(32):
 a=i*math.pi/16;rad=10 if i%4 in (1,2)else 8
 gear.extend([12+rad*math.cos(a),12+rad*math.sin(a)])
icon('Settings',[p(*(gear+gear[:2])),c(12,12,3.4)])
helmet=[p(3,14,3,11,4,7,7,4,12,3,17,4,20,7,21,11,21,14,3,14),p(2,15,22,15),p(6,16,7,20,12,22,17,20,18,16),p(12,4,12,10)]
icon('Soldiers',helmet)
icon('Recruitment',[c(8,7,4),p(2,21,2,17,4,14,8,13,12,14,14,17,14,21),p(18,8,18,16),p(14,12,22,12)])
coins=[c(8,7,6,3),p(2,7,2,13,4,15,8,16),p(14,7,14,10),c(16,14,6,3),p(10,14,10,20,13,22,19,22,22,20,22,14),p(2,11,5,13,8,13),p(10,18,13,20,19,20,22,18)]
icon('Gold',coins)
icon('Income',[c(7,14,5,2.5),p(2,14,2,20,5,22,9,22,12,20,12,14),p(2,18,5,20,9,20,12,18),p(17,16,17,3),p(13,7,17,3,21,7)])
icon('Territory',[p(4,22,4,2),p(5,3,13,3,14,6,21,6,18,10,21,14,12,14,11,11,5,11)])
icon('Rank',[p(5,2,9,2,12,8,15,2,19,2,15,10),p(5,2,9,10),c(12,15,6),poly(12,11,13,14,16,14,14,16,15,19,12,17,9,19,10,16,8,14,11,14)])
icon('Friends',[c(8,7,4),p(2,21,2,17,4,14,8,13,12,14,14,17,14,21),p(18,8,18,16),p(14,12,22,12)])
icon('Exit',[p(10,3,3,3,3,21,10,21),p(9,12,22,12),p(17,7,22,12,17,17)])
def png(path,a,w,h):
 def chunk(k,b):return struct.pack('>I',len(b))+k+b+struct.pack('>I',zlib.crc32(k+b)&0xffffffff)
 raw=b''.join(b'\0'+b''.join(bytes((255,255,255,v))for v in a[y*w:(y+1)*w])for y in range(h))
 path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))
atlas=bytearray(512*512);cells=[]
for i,(name,shapes)in enumerate(icons.items()):
 mask=bytearray(512*512);svg=[]
 for kind,v in shapes:
  if kind=='c':
   cx,cy,rx,ry=v
   def hit(x,y):return abs(math.sqrt(((x-cx)/rx)**2+((y-cy)/ry)**2)-1)*min(rx,ry)<=1
   bounds=(cx-rx-1,cy-ry-1,cx+rx+1,cy+ry+1)
   svg.append(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}"/>')
  else:
   pts=list(zip(v[::2],v[1::2]));segments=list(zip(pts,pts[1:]+(pts[:1]if kind=='f'else [])))
   def hit(x,y):
    if kind=='f':
     inside=False
     for (ax,ay),(bx,by)in segments:
      if (ay>y)!=(by>y)and x<(bx-ax)*(y-ay)/(by-ay)+ax:inside=not inside
     return inside
    for (ax,ay),(bx,by)in segments:
     dx,dy=bx-ax,by-ay;t=max(0,min(1,((x-ax)*dx+(y-ay)*dy)/(dx*dx+dy*dy)))
     if (x-ax-t*dx)**2+(y-ay-t*dy)**2<=1:return True
    return False
   bounds=(min(v[::2])-1,min(v[1::2])-1,max(v[::2])+1,max(v[1::2])+1)
   svg.append(('<polygon fill="white" stroke="none"'if kind=='f'else '<polyline')+' points="'+' '.join(f'{a},{b}'for a,b in pts)+'"/>')
  for py in range(max(0,int(bounds[1]*512/24)),min(512,math.ceil(bounds[3]*512/24))):
   for px in range(max(0,int(bounds[0]*512/24)),min(512,math.ceil(bounds[2]*512/24))):
    if hit((px+.5)*24/512,(py+.5)*24/512):mask[py*512+px]=1
 a=bytearray(round(sum(mask[(y*4+dy)*512+x*4+dx]for dy in range(4)for dx in range(4))*255/16)for y in range(128)for x in range(128))
 ox,oy=i%4*128,i//4*128
 for y in range(128):atlas[(oy+y)*512+ox:(oy+y)*512+ox+128]=a[y*128:y*128+128]
 cells.append(f'{name}=Vector2.new({ox},{oy})');png(out/f'{name}.png',a,128,128)
 (out/f'{name}.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'+''.join(svg)+'</svg>')
png(out/'atlas.png',atlas,512,512)
flat=atlas;runs=bytearray();start=0
while start<len(flat):
 end=start+1
 while end<len(flat)and flat[end]==flat[start]and end-start<65535:end+=1
 runs+=struct.pack('<HB',end-start,int(flat[start]));start=end
literal=''.join('\\%03d'%b for b in runs)
block='-- BEGIN GENERATED GUI ATLAS\nlocal guiCells={'+','.join(cells)+'}\nlocal guiAlpha="'+literal+'"\n-- END GENERATED GUI ATLAS\n'
path=r/'src/client/InterfaceArt.luau';s=path.read_text()
if '-- BEGIN GENERATED GUI ATLAS' in s:
 start=s.index('-- BEGIN GENERATED GUI ATLAS');end=s.index('-- END GENERATED GUI ATLAS')+len('-- END GENERATED GUI ATLAS\n');s=s[:start]+block+s[end:]
else:s=s.replace('local Art={}\n','local Art={}\n'+block)
path.write_text(s)
(out/'LICENSE.txt').write_text('Original WorldConquest GUI icon artwork. Distributed under AGPL-3.0 with this project; see ../../LICENSE and ../../NOTICE. No third-party assets. Regenerate with scripts/generate_gui_icons.py.\n')
print('Generated',len(icons),'original 128px transparent icons; atlas RLE bytes',len(runs))
