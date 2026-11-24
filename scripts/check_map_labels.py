"""Execute production label culling at multiple camera transforms; no Studio rendering."""
from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
s=(r/'src/client/MapView.luau').read_text()
assert 'name.BackgroundTransparency=1' in s and 'name.Active=false' in s
assert 'name.TextColor3=Color3.fromRGB(246,248,252)' in s
assert 'name.BackgroundTransparency=0.' not in s
assert 'local gx,gy=Transform.screenToGui(physical.X,physical.Y,root.X,root.Y)' in s, 'placement must share inset transform with map input'
body=s.split('    local function layoutNames()',1)[1].split('    local function createIcon()',1)[0]
h='''local zoom=1;local labelVersion=0;local lastLabels={}
local Map={Width=8192,Height=4096}
local viewport={AbsoluteSize={X=1000,Y=600}}
local origin={X=0,Y=0};local scale=.1
local function marker(x,y)
 local label={Visible=true}
 return {Position={X={Scale=x/8192},Y={Scale=y/4096}},GetAttribute=function()return false end,FindFirstChild=function()return label end}
end
local markerOrder={marker(1000,1000),marker(1100,1000),marker(4000,2000)}
local function layoutNames()'''+body+'''
layoutNames()
assert(markerOrder[1]:FindFirstChild().Visible)
assert(not markerOrder[2]:FindFirstChild().Visible)
assert(markerOrder[3]:FindFirstChild().Visible)
scale=2;origin={X=-1800,Y=-1800};layoutNames()
assert(markerOrder[1]:FindFirstChild().Visible and markerOrder[2]:FindFirstChild().Visible)
assert(not markerOrder[3]:FindFirstChild().Visible)
for _,size in ipairs({{320,568},{390,844},{768,1024},{1920,1080},{2560,1440}})do
 viewport.AbsoluteSize={X=size[1],Y=size[2]};layoutNames()
 for _,m in ipairs(markerOrder)do assert(m.Position.X.Scale>0)end
end
print('Transparent passive labels: production overlap culling, zoom/pan, offscreen clipping and five viewport sizes passed (not rendered Studio).')
'''
p=r/'build/map-label-checks.luau';p.write_text(h)
subprocess.run([str(r/'build/luau/luau.exe'),str(p)],check=True)
