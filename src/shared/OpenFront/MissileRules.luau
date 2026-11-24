--!strict
-- OpenFront Config/EngineConfig, revision 8f1a0add. Modified 2026-11-20.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE/NOTICE.
local Math = require(script.Parent.DetMath)
local Rules={Cooldown=90,SAMSpeed=12,TargetableRange=150,MaxSAMRange=150}
Rules.Types={"AtomBomb","HydrogenBomb","MIRV"}
function Rules.cost(kind,launched)
 if kind=="AtomBomb" then return "750000" end
 if kind=="HydrogenBomb" then return "5000000" end
 if kind=="MIRV" then return tostring(25000000+15000000*launched) end
 error("invalid missile")
end
function Rules.magnitude(kind)
 if kind=="HydrogenBomb" then return 80,100 end
 return 12,if kind=="MIRVWarhead" then 18 else 30
end
function Rules.deaths(kind,troops,tiles,cap)
 if kind~="MIRVWarhead" then return 5*troops/math.max(1,tiles) end
 return 500*(1-Math.exp(-2*math.max(0,troops-.03*cap)/cap))
end
-- Independent stacks can be evaluated separately without changing any per-tile
-- rounding. Avoid per-tile empty attack/ship loops and repeated player lookups.
function Rules.damageStack(kind,value,impacted,remaining,cap,integer)
 local warhead=kind=="MIRVWarhead"
 if warhead and value<=.03*cap then return value end
 for i=0,impacted-1 do
  if value<=0 then return 0 end
  local deaths=if warhead then Rules.deaths(kind,value,remaining+impacted-i,cap) else 5*value/(remaining+impacted-i)
  if integer then deaths=math.floor(deaths) end
  value=math.max(0,value-deaths)
 end
 return value
end
function Rules.range(level)return 150-480/(level+5) end
function Rules.dynamicRange(unit,tick)
 local s=unit.SAMUpgrade
 if not s or tick-s.Tick>=45 then return Rules.range(unit.Level) end
 return s.Range+(Rules.range(unit.Level)-s.Range)*(tick-s.Tick)/45
end
return Rules
