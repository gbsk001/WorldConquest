"""Package existing licensed PNG atlases; validate PNG integrity without GUI/libraries."""
from pathlib import Path
import struct,zlib,hashlib,json,shutil,zipfile
r=Path(__file__).resolve().parents[1]
def validate_png(path,expected):
 raw=path.read_bytes();assert raw[:8]==b'\x89PNG\r\n\x1a\n'
 pos=8;data=bytearray();header=None
 while pos<len(raw):
  size=struct.unpack('>I',raw[pos:pos+4])[0];kind=raw[pos+4:pos+8];chunk=raw[pos+8:pos+8+size]
  crc=struct.unpack('>I',raw[pos+8+size:pos+12+size])[0];assert zlib.crc32(kind+chunk)&0xffffffff==crc
  if kind==b'IHDR':header=struct.unpack('>IIBBBBB',chunk)
  if kind==b'IDAT':data.extend(chunk)
  pos+=size+12
  if kind==b'IEND':break
 assert header==(*expected,8,6,0,0,0),'Expected non-interlaced 8-bit RGBA PNG'
 pixels=zlib.decompress(data);assert len(pixels)==expected[1]*(1+expected[0]*4)
 return {'width':expected[0],'height':expected[1],'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
def main():
 target=r/'build/Stage15-icon-upload';target.mkdir(parents=True,exist_ok=True)
 entries=[]
 for page,name in enumerate(['LucideAtlas1.png','LucideAtlas2.png','LucideAtlas3.png','FlagAtlas.png'],1):
  source=r/'assets/gui-icons'/name;info=validate_png(source,(512,256 if page==4 else 512))
  shutil.copyfile(source,target/name);entries.append({'slot':page,'filename':name,**info})
 for source,name in [('assets/gui-icons/LICENSE.txt','Lucide-ISC-Feather-MIT.txt'),('LICENSE','WorldConquest-AGPL-3.0.txt'),('NOTICE','NOTICE.txt'),('docs/STAGE15_MANUAL_SETUP.md','UPLOAD-INSTRUCTIONS.md')]:shutil.copyfile(r/source,target/name)
 (target/'atlas-manifest.json').write_text(json.dumps({'images':entries,'uploaded':False,'ids_configured':False},indent=2))
 archive=r/'build/WorldConquest-icon-atlases-upload.zip'
 with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=3)as z:
  for p in sorted(target.iterdir()):
   if p.is_file():z.write(p,p.name)
 print('Prepared four CRC/decompression-verified RGBA PNG atlases, licences, checksums and instructions:',archive)
if __name__=='__main__':main()
