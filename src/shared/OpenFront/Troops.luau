--!strict
-- OpenFront Config.troopCap/troopIncreaseRate, EngineConfig.attackLogic (neutral),
-- PlayerImpl reserve integer boundaries. Revision 8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94.
-- Copyright OpenFront and Contributors; AGPL-3.0, see LICENSE/NOTICE.
local Math = require(script.Parent.DetMath)
local Troops={}
local capMultiplier={Easy=0.5,Medium=0.75,Hard=1,Impossible=1.25}
local growthMultiplier={Easy=0.9,Medium=0.95,Hard=1,Impossible=1.05}
function Troops.cap(land, cities,kind,difficulty,options)
 kind=kind or "Human";difficulty=difficulty or "Hard";options=options or {}
 local cap=if kind=="Human" and options.Infinite then 1000000000 else 2*(Math.pow(land,0.6)*1000+50000)+250000*(cities or 0)
 if options.Tutorial and kind~="Human" then return cap*0.1 end
 if kind=="Bot" then return cap/3 end
 if kind=="Human" then return cap end
 assert(kind=="Nation" and capMultiplier[difficulty],"unknown player type/difficulty")
 return cap*capMultiplier[difficulty]
end
function Troops.growth(reserve,cap,kind,difficulty)
 local add=(10+Math.pow(reserve,0.73)/4)*(1-reserve/cap)
 if kind=="Bot" then add*=0.5 end
 if kind=="Nation" then assert(growthMultiplier[difficulty or "Hard"]);add*=growthMultiplier[difficulty or "Hard"] end
 return math.min(reserve+add,cap)-reserve
end
function Troops.initial(kind,difficulty,options)
 options=options or {}
 if kind=="Bot" then return 10000 end
 if kind=="Nation" then
  local values={Easy=12500,Medium=18750,Hard=25000,Impossible=31250}
  assert(values[difficulty or "Hard"]);return values[difficulty or "Hard"]
 end
 if options.Tutorial then return 60000 end
 return if options.Infinite then 1000000 else 25000
end
function Troops.attackAmount(reserve,kind) return reserve/(if kind=="Bot" then 20 else 5) end
function Troops.add(p,n)
 if n<0 then Troops.remove(p,-n) else p.Troops+=math.floor(n) end
end
function Troops.remove(p,n)
 if n<=0 then return 0 end
 local removed=math.min(p.Troops,math.floor(n));p.Troops-=removed;return removed
end
function Troops.neutral(terrain,stack,border,kind,falloutRatio)
 assert(terrain=="Plains" or terrain=="Highland" or terrain=="Mountain","unsupported attack terrain")
 local mag,cost=80,16.5
 if terrain=="Highland" then mag,cost=100,20 elseif terrain=="Mountain" then mag,cost=120,25 end
 if falloutRatio~=nil then local modifier=5-2*falloutRatio;mag*=modifier;cost*=modifier end
 return mag/(if kind=="Bot" then 10 else 5),math.clamp(2000*cost/stack,5,100)/(2*border)
end
return Troops
