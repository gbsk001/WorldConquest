--!strict
-- EngineConfig trainSaturation/trainSpawnRate/smallEconomySpawnBoost/trainGold.
-- Copyright OpenFront and Contributors. AGPL-3.0; pinned 8f1a0add.
local Math = require(script.Parent.DetMath)
local Rules={}
function Rules.spawnRate(levels,units)
 local function sigmoid(value,decay,mid)return 1/(1+Math.exp(-decay*(value-mid))) end
 local saturation=math.max(1-sigmoid(units,0.6931471805599453/100,560),0.25*(1-sigmoid(units,0.6931471805599453/150,900)))
 local boost=if levels<=0 then 1 else 1+(0.5*math.clamp((6-levels)/5,0,1))/levels
 return math.max(1,math.floor(((levels+20)*165/21)/(saturation*boost)))
end
function Rules.gold(relationship,visited,multiplier)
 local base=if relationship=="self" then 10000 elseif relationship=="ally" then 35000 else 25000
 return math.floor(math.max(5000,base-math.max(0,visited-9)*5000)*multiplier)
end
return Rules
