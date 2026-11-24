from pathlib import Path
import subprocess
r=Path(__file__).resolve().parents[1]
s=(r/'src/client/Main.client.luau').read_text()
fn='local function retainPrivateProfile'+s.split('local function retainPrivateProfile',1)[1].split('local function showFoundation',1)[0]
code=fn+"""
local quote={City={Cost="125000",Affordable=true,Enabled=true}}
local previous={UserId=1,Gold="999",Count=8,BuildingQuotes=quote,Naval={Warships=1},Missiles={Ready=1},Rail={Trains=1}}
local nextState={Players={{UserId=1,Gold="1000",Count=20},{UserId=2}}}
retainPrivateProfile(nextState,previous,1)
assert(nextState.Players[1].BuildingQuotes==quote and nextState.Players[1].Naval.Warships==1)
assert(nextState.Players[1].Gold=="1000" and nextState.Players[1].Count==20)
assert(nextState.Players[2].BuildingQuotes==nil)
local reset={Players={{UserId=1}}};retainPrivateProfile(reset,nil,1);assert(reset.Players[1].BuildingQuotes==nil)
local fresh={};nextState.Players[1].BuildingQuotes=fresh;retainPrivateProfile(nextState,previous,1);assert(nextState.Players[1].BuildingQuotes==fresh)
print("Private purchase state survives public metadata refresh without overwriting fresh public data, leaking other players, or carrying across reset.")
"""
p=r/'build/private-profile-checks.luau';p.write_text(code)
subprocess.run([str(r/'build/luau/luau.exe'),str(p)],check=True)
