"""Compile all Luau and run real rule modules with only Roblox service lookup stubbed.

Usage: python scripts/check_luau.py [directory containing official Luau CLI binaries]
The default is build/luau. This does not emulate Studio UI or network transport.
"""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
TOOLS = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "build/luau"


def source(path):
    return (ROOT / path).read_text(encoding="utf-8-sig")


def factory(name, path, dependencies):
    content = source(path)
    for variable, expression in dependencies.items():
        lines = content.splitlines()
        matches = [line for line in lines if line.startswith(f"local {variable} = require(")]
        assert len(matches) == 1, (path, variable)
        content = content.replace(matches[0], f"local {variable} = {expression}")
    return f"local {name} = (function()\n{content}\nend)()\n"


for path in sorted((ROOT / "src").rglob("*.luau")):
    result = subprocess.run([str(TOOLS / "luau-compile.exe"), str(path)], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    if result.returncode:
        sys.exit(result.stderr.decode("utf-8", errors="replace"))
print("All project Luau scripts compile.", flush=True)

harness = factory("EarthData", "src/shared/EarthData.luau", {})
harness += factory("WorldMap", "src/shared/Map.luau", {"Earth": "EarthData"})
harness += factory("SpawnRules", "src/server/Rules.luau", {"Map": "WorldMap"})
harness += factory("Frontier", "src/server/Frontier.luau", {"Map": "WorldMap"})
harness += factory("checkRules", "src/server/RulesTests.luau", {"Map": "WorldMap", "Rules": "SpawnRules", "Frontier": "Frontier"})
harness += "checkRules()\n"
harness += factory("MapTransform", "src/client/MapTransform.luau", {})
harness += factory("OwnershipRaster", "src/client/OwnershipRaster.luau", {"Map": "WorldMap"})
harness += factory("TilePainter", "src/client/TilePainter.luau", {"Map": "WorldMap"})
harness += source("scripts/map_checks.luau")
# The production server script runs unchanged inside a dependency-injected wrapper.
harness += "local function runServer(game, script, require, Instance, Random, Color3, task, os)\n"
harness += source("src/server/LegacyServer.luau").split("return function()",1)[1].rsplit("end",1)[0] + "\nend\n"
harness += source("scripts/server_checks.luau")
harness += factory("DirtyTiles", "src/client/DirtyTiles.luau", {})
harness += "local function makeTiles(game, script, require, Instance, Vector2, UDim2, Enum, Content)\n"
harness += source("src/client/MapTiles.luau") + "\nend\n"
harness += source("scripts/tile_checks.luau")
harness += source("scripts/performance_checks.luau")
target = ROOT / "build/checks.luau"
target.parent.mkdir(exist_ok=True)
target.write_text(harness, encoding="utf-8")
subprocess.run([str(TOOLS / "luau.exe"), str(target)], check=True)
