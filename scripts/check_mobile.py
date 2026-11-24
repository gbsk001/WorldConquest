"""Mobile gesture and image-free renderer regressions; not physical-device acceptance."""
from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
h=(r/'scripts/strategy_ui_checks.luau').read_text()
h+='\nlocal Gestures=(function()\n'+(r/'src/client/TouchGestures.luau').read_text()+'\nend)()\n'
h+='''
local taps,pans,zooms=0,0,0
local g=Gestures.new(function(dx,dy)pans+=1 end,function(f,ox,oy,nx,ny)assert(f>0);zooms+=1 end,function(x,y)taps+=1 end)
g.begin(1,100,100);g.finish(1,103,104);assert(taps==1)
g.begin(1,100,100);g.move(1,120,120);g.move(1,100,100);g.finish(1,100,100);assert(taps==1 and pans==2)
for order=1,2 do
 g.begin(1,100,100);g.begin(2,200,100);g.move(2,240,100);g.finish(order,100,100);g.move(3-order,120,120);g.finish(3-order,120,120)
end
assert(taps==1 and zooms==2)
g.begin(1,20,20);g.cancel();g.finish(1,20,20);assert(taps==1)
print('Touch: tap, drag-return suppression, pinch in both release orders, one-finger continuation and cancellation passed.')
local heartbeat=signal()
local testMap={Width=8192,Height=4096,isLand=function(t)assert(t>=1 and t<=8192*4096);return t%17<12 end}
'''
s=(r/'src/client/CompatibleTiles.luau').read_text().replace('local Map=require(game:GetService("ReplicatedStorage").Shared.Map)','local Map=testMap').replace('local RunService=game:GetService("RunService")','local RunService={Heartbeat=heartbeat}')
h+='local Compatible=(function()\n'+s+'\nend)()\n'
h+='''
local canvas=Instance.new('Frame');local raster={sample=function()return 0,0,0,0 end}
local tiles=Compatible.new(canvas,raster)
for _,v in ipairs({{0,0,.09,740,370},{-100,-50,.2,844,390},{-20000,-10000,5,1024,768},{0,0,.04,320,568}})do
 tiles.update(unpack(v));tiles.invalidateAll()
 for _=1,300 do heartbeat:Fire()end
 assert(tiles.ready()and tiles.readyAt(1,1));assert(tiles.metrics().TileObjects<=8192)
end
tiles.setEnabled(false);local before=#objects;for _=1,10 do heartbeat:Fire()end;assert(#objects==before)
tiles.destroy();assert(#canvas:GetChildren()==0)
print('EditableImage unavailable: image-free pooled renderer, exact-grid sampling, four viewports/zoom/pan, bounded objects, hidden pause and cleanup passed.')
'''
p=r/'build/mobile-checks.luau';p.write_text(h)
run=subprocess.run([str(r/'build/luau/luau.exe'),str(p)],capture_output=True,text=True)
(r/'build/mobile-checks.txt').write_text(run.stdout+run.stderr);print(run.stdout+run.stderr);raise SystemExit(run.returncode)
