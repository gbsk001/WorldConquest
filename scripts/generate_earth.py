"""Generate an 8192x4096 Earth mask from Natural Earth 10m land MINUS lakes.

Standard library only. Scan-converts the ORIGINAL detailed polygons at cell
centres, including holes. Also generates averaged display LODs, never simulation
LODs. No enlargement of the previous 110m mask is involved.
"""
import hashlib
import json
import math
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
WIDTH, HEIGHT = 8192, 4096


def rasterize(mask, document, value):
    for feature in document["features"]:
        geom = feature["geometry"]
        assert geom["type"] in ("Polygon", "MultiPolygon")
        polygons = [geom["coordinates"]] if geom["type"] == "Polygon" else geom["coordinates"]
        for polygon in polygons:
            crossings = {}
            for ring in polygon:
                for a, b in zip(ring, ring[1:]):
                    ax, ay = (a[0]+180)*WIDTH/360, (90-a[1])*HEIGHT/180
                    bx, by = (b[0]+180)*WIDTH/360, (90-b[1])*HEIGHT/180
                    if ay == by:
                        continue
                    first = max(0, math.ceil(min(ay, by) - 0.5))
                    last = min(HEIGHT, math.ceil(max(ay, by) - 0.5))
                    for y in range(first, last):
                        x = ax + (y + 0.5 - ay) * (bx - ax) / (by - ay)
                        crossings.setdefault(y, []).append(x)
            for y, row in crossings.items():
                row.sort()
                assert len(row) % 2 == 0
                for left, right in zip(row[::2], row[1::2]):
                    start, end = max(0, math.ceil(left-0.5)), min(WIDTH, math.ceil(right-0.5))
                    if end > start:
                        mask[y][start:end] = bytes([value]) * (end-start)


def png(path, rows):
    width, height = len(rows[0]), len(rows)
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind+data))
    # Indexed grayscale coverage palette, blending ocean and land.
    palette = bytes(c for n in range(256) for c in (round(20+95*n/255), round(45+94*n/255), round(65+63*n/255)))
    content = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 3, 0, 0, 0))
    content += chunk(b"PLTE", palette)
    content += chunk(b"IDAT", zlib.compress(b"".join(b"\0"+bytes(row) for row in rows))) + chunk(b"IEND", b"")
    path.write_bytes(content)


def binary_runs(rows):
    out = bytearray()
    total = 0
    for row in rows:
        runs = []
        x = 0
        while x < len(row):
            if not row[x]:
                x += 1
                continue
            start = x
            while x < len(row) and row[x]:
                x += 1
            runs.append((start, x-start))
            total += x-start
        out += struct.pack("<H", len(runs))
        for start, length in runs:
            out += struct.pack("<HH", start, length)
    return out, total


def coverage_runs(rows):
    out = bytearray()
    for row in rows:
        x = 0
        while x < len(row):
            start, value = x, row[x]
            while x < len(row) and row[x] == value:
                x += 1
            out += struct.pack("<HB", x-start, value)
    return out


def literal(data):
    # Raw bytes in Luau string literals; no runtime base64/hex parsing.
    chunks = ['"' + ''.join('\\%03d' % byte for byte in data[i:i+1024]) + '"' for i in range(0, len(data), 1024)]
    return "table.concat({\n" + ",\n".join(chunks) + "\n})"


def sample(rows, lon, lat):
    return rows[int((90-lat)*HEIGHT/180)][int((lon+180)*WIDTH/360)]


def validate(rows):
    for name, lon, lat in [("Africa",20,5), ("America",-100,40), ("Europe",15,50),
                           ("Asia",100,45), ("Australia",135,-25), ("Greenland",-42,73),
                           ("Antarctica",0,-85), ("Hawaii",-155.6,19.6), ("Sicily",14.2,37.5),
                           ("Sri Lanka",80.7,7.8), ("Taiwan",121,23.7), ("Corsica",9.1,42.1)]:
        assert sample(rows,lon,lat), name
    for name, lon, lat in [("Pacific",-140,0), ("Atlantic",-30,0), ("Indian Ocean",80,-30),
                           ("Superior",-87,47.5), ("Victoria",33,-1), ("Caspian",51,42),
                           ("Baikal",108,53.5), ("English Channel",0,50), ("Taiwan Strait",119.5,24)]:
        assert not sample(rows,lon,lat), name


if __name__ == "__main__":
    rows = [bytearray(WIDTH) for _ in range(HEIGHT)]
    hashes = {}
    for name, value in [("land",255), ("lakes",0)]:
        path = ROOT / f"data/ne_10m_{name}.geojson"
        hashes[path.name] = hashlib.sha256(path.read_bytes()).hexdigest()
        rasterize(rows, json.loads(path.read_text(encoding="utf-8")), value)
        print(f"Rasterized 10m {name}", flush=True)
    validate(rows)
    runs, total = binary_runs(rows)
    # Reconstruct every simulation row independently from the packed data.
    offset = 0
    for expected in rows:
        count, = struct.unpack_from("<H", runs, offset); offset += 2
        actual = bytearray(WIDTH)
        for _ in range(count):
            start, length = struct.unpack_from("<HH", runs, offset); offset += 4
            actual[start:start+length] = b'\xff' * length
        assert actual == expected
    assert offset == len(runs)
    build = ROOT / "build"
    build.mkdir(exist_ok=True)
    png(build / "earth-detail.png", rows)
    (build / "earth-mask.bin").write_bytes(b"".join(rows))
    parts = ["--!strict\n-- Generated from Natural Earth 10m v5.1.2 land minus lakes. Public domain; see data/README.md.",
             "return {", f"Width = {WIDTH}, Height = {HEIGHT}, LandCount = {total},", "Runs = " + literal(runs) + ",", "Mips = {"]
    current = rows
    for level in range(1, 7):
        coarse = []
        for y in range(0, len(current), 2):
            a, b = current[y], current[y+1]
            coarse.append(bytearray((v+w+x+z+2)//4 for v,w,x,z in zip(a[::2],a[1::2],b[::2],b[1::2])))
        current = coarse
        # Level 1 is sampled from four bits; level >=2 uses precomputed coverage.
        if level >= 2:
            packed = coverage_runs(current)
            parts.append(f"[{level}] = {{ Width = {len(current[0])}, Height = {len(current)}, Runs = {literal(packed)} }},")
        if level == 3:
            png(build / "earth-preview.png", current)
    parts += ["},", "}"]
    (ROOT / "src/shared/EarthData.luau").write_text("\n".join(parts)+"\n", encoding="utf-8")
    manifest = {"width":WIDTH,"height":HEIGHT,"land_cells":total,"source_sha256":hashes,"mask_sha256":hashlib.sha256(b''.join(rows)).hexdigest()}
    (ROOT / "data/earth-manifest.json").write_text(json.dumps(manifest,indent=2)+"\n", encoding="utf-8")
    print(f"Validated original 10m geography, lakes, islands and lossless mask encoding: {total:,} land cells.")
