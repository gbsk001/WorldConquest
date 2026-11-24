"""Independently decode the shipped terrain module and verify every cell's hash."""
from pathlib import Path
import hashlib,json,re,struct
ROOT=Path(__file__).resolve().parents[1]
text=(ROOT/'src/shared/OpenFront/EarthTopologyData.luau').read_text()
manifest=json.loads((ROOT/'data/earth-topology-manifest.json').read_text())
encoded=text.split('Blocks=table.concat({',1)[1].split('})',1)[0]
packed=bytes(int(m[1]) for m in re.finditer(r'\\(\d{3})',encoded))
assert len(packed)==manifest['terrain_rle_bytes']
decoded=bytearray();offset=0
while offset<len(packed):
    length=struct.unpack_from('<I',packed,offset)[0];offset+=4
    end=offset+length;page=bytearray()
    while offset<end:
        run,value=struct.unpack_from('<HB',packed,offset);offset+=3
        page.extend(bytes([value])*run)
    assert offset==end and len(page)==4096
    decoded.extend(page)
assert len(decoded)==8192*4096
assert hashlib.sha256(decoded).hexdigest()==manifest['terrain_sha256']
mask=bytes(255 if v&128 else 0 for v in decoded)
assert hashlib.sha256(mask).hexdigest()==manifest['mask_sha256']
print('All 33,554,432 terrain cells decode exactly; land mask hash unchanged.')
