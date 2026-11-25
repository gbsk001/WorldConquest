"""Production geography/painter/cache and icon CPU checks. NOT a Roblox render test."""
from pathlib import Path
import subprocess,json
ROOT=Path(__file__).resolve().parents[1]
def module(name,path,replacements=()):
 s=(ROOT/path).read_text(encoding='utf-8-sig')
 for a,b in replacements:s=s.replace(a,b)
 return '\nlocal '+name+'=(function()\n'+s+'\nend)()\n'
h='local files={}\n'
for p in sorted((ROOT/'src/shared/Geography').glob('*.luau')):
 h+='files["'+p.stem+'"]=(function()\n'+p.read_text()+'\nend)()\n'
h+=module('Terrain','src/client/TerrainColors.luau',[
 ('local folder=game:GetService("ReplicatedStorage").Shared.Geography','local folder={Palette=files.Palette,FindFirstChild=function(_,name)return files[name]end}\nlocal require=function(v)return v end')])
h+='''
local times={};local sum=0;local cold=gcinfo()
for n=1,64 do
 local start=os.clock();local x=(n*113)%8000;local y=(n*59)%4000
 for i=0,255 do Terrain.sample(0,(x+i)%8192,y)end
 local ms=(os.clock()-start)*1000;times[n]=ms;sum+=ms
end
table.sort(times)
print(string.format("GEO_ROW cold samples avg %.3f p95 %.3f worst %.3f ms; heap delta %.1f KiB",sum/64,times[61],times[64],gcinfo()-cold))
for level=0,6 do
 local x,y=math.floor(4000/2^level),math.floor(1800/2^level)
 local r,g,b=Terrain.sample(level,x,y);assert(r>=0 and r<=255 and b<=255)
 local rr,gg,bb=Terrain.sample(level,x+8192/2^level,y);assert(rr==r and gg==g and bb==b,"geographic longitude wrap")
end
local terrainCalls=0
local Map={coverage=function()return 1 end,terrain=function(...)terrainCalls+=1;return Terrain.sample(...)end}
'''
h+=module('Painter','src/client/TilePainter.luau',[
 ('local Map = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Map"))','local Map=Map')])
h+='''
local slot={Level=0,X=15,Y=7,Pixels=buffer.create(258*258*4),Coverage=buffer.create(258*258)}
local owner=0;local raster={sample=function()return 100*owner,200*owner,40*owner,owner end}
Painter.paint(slot,raster,0,true,10,10,10,10)
local base=buffer.readu32(slot.Pixels,(10*258+10)*4);local calls=terrainCalls
owner=1;Painter.paint(slot,raster,0,false,10,10,10,10)
assert(terrainCalls==calls and buffer.readu32(slot.Pixels,(10*258+10)*4)~=base,"ownership updates reuse immutable terrain")
owner=0;Painter.paint(slot,raster,0,false,10,10,10,10)
assert(buffer.readu32(slot.Pixels,(10*258+10)*4)==base,"released land restores exact terrain colour")
Map.coverage=function()return .25 end
owner=0;Painter.paint(slot,raster,0,true,10,10,10,10)
local coast=buffer.readu32(slot.Pixels,(10*258+10)*4)
owner=1;Painter.paint(slot,raster,0,true,10,10,10,10)
owner=0;Painter.paint(slot,raster,0,false,10,10,10,10)
assert(buffer.readu32(slot.Pixels,(10*258+10)*4)==coast,"cold owned coastline caches terrain independent of ownership")
print("Terrain: native grid samples, all seven LODs, longitude wrap, cached recolouring and release restoration passed.")
'''
h+=module('Layer','src/client/IconLayer.luau')
h+='''
local units={};for i=1,5000 do units[i]={ID=i,Tile=(i*7919)%(8192*4096)}end
local layer=Layer.new(8192,function()return {Destroy=function()end}end,function()end,nil,true)
layer.set(units,{})
local samples={};local total=0
for i=1,300 do local start=os.clock();layer.update(-8000-i*2,-4000-i,2,1920,1080);local ms=(os.clock()-start)*1000;samples[i]=ms;total+=ms end
table.sort(samples)
assert(layer.Candidates<5000/4 and layer.Visible<=256,"zoomed views query the spatial index")
local created=layer.Created;for _=1,1000 do layer.update(-8600,-4300,2,1920,1080)end;assert(layer.Created==created)
print(string.format("ICON_DETAIL 5000 units avg %.3f p95 %.3f worst %.3f ms; candidates %d; created %d",total/300,samples[285],samples[300],layer.Candidates,created))
print("Stage 14 CPU-only checks passed. No Studio/GPU/physical-device FPS certification.")
'''
p=ROOT/'build/stage14-checks.luau';p.write_text(h,encoding='utf-8')
run=subprocess.run([str(ROOT/'build/luau/luau.exe'),str(p)],capture_output=True,text=True)
(ROOT/'build/stage14-results.txt').write_text(run.stdout+run.stderr)
print(run.stdout+run.stderr);raise SystemExit(run.returncode)
