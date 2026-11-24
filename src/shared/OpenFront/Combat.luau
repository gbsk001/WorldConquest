--!strict
-- EngineConfig.ts attackLogic / largeTerritoryBonus, pinned 8f1a0add.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE and NOTICE.
local Math = require(script.Parent.DetMath)
local Combat={}
local function bonus(tiles,depth)
 return 1-depth*(1/(1+Math.exp(-2.5*(Math.log(tiles)-Math.log(300000)))))
end
function Combat.losses(terrain,stack,border,attacker,defender,post,fallout)
 local mag,cost
 if terrain=="Plains" then mag,cost=80,16.5
 elseif terrain=="Highland" then mag,cost=100,20
 elseif terrain=="Mountain" then mag,cost=120,25
 else error("Cannot attack impassable terrain") end
 if post then mag*=5;cost*=3 end
 if fallout~=nil then local modifier=5-2*fallout;mag*=modifier;cost*=modifier end
 if defender.DisconnectedTeammate then mag=0 end
 if (attacker.Kind=="Human" or attacker.Kind=="Nation") and defender.Kind=="Bot" then mag*=0.7 end
 local largeA,largeD=bonus(attacker.Count,0.7),bonus(defender.Count,0.3)
 local lossMod=if defender.Traitor then 0.5 else 1
 local costMod=if defender.Traitor then 0.8 else 1
 local defenseLoss=defender.Troops/defender.Count
 local ratio=defender.Troops/stack
 local attackLoss=mag*lossMod*math.clamp(ratio,0.6,2)*(0.463*largeA*largeD+0.0039*defenseLoss)
 local speedCost=(math.clamp(ratio,0.82,7.5)*math.clamp(ratio/20,1,50))/8.55
 local fraction=(speedCost*cost*bonus(attacker.Count,0.73)*largeD*costMod)/border
 return attackLoss,defenseLoss,fraction
end
return Combat
