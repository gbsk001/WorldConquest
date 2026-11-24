"""Verify the shipped elevation overlay independently using only Python stdlib."""
from pathlib import Path
import re,struct,hashlib,json
root=Path(__file__).resolve().parents[1]
m=json.loads((root/'data/elevation-manifest.json').read_text())
b=(root/'data/earth-elevation-rle.bin').read_bytes();assert len(b)==m['encoded_bytes']
out=bytearray();pos=0
while pos<len(b):
 size=struct.unpack_from('<I',b,pos)[0];pos+=4;end=pos+size;page=bytearray()
 while pos<end:
  n,v=struct.unpack_from('<HB',b,pos);pos+=3;assert n>0 and v in (0,10,20);page.extend(bytes([v])*n)
 assert pos==end and len(page)==4096;out.extend(page)
assert len(out)==8192*4096 and hashlib.sha256(out).hexdigest()==m['class_sha256']
mask=(root/'build/earth-mask.bin').read_bytes();assert hashlib.sha256(mask).hexdigest()==m['land_mask_sha256']
counts={0:0,10:0,20:0}
for land,value in zip(mask,out):
 if land:counts[value]+=1
 else:assert value==0,'ocean/lake elevation altered'
assert {str(k):v for k,v in counts.items()}==m['classes']
for sample in m['samples']:assert out[sample['cell']]==sample['magnitude']
print('All 33,554,432 elevation cells verified; class hash, land/lake mask, class counts and geographic samples passed.')
