--!strict
-- EngineConfig naval rules / UnitImpl veterancy, OpenFront 8f1a0add.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE and NOTICE.
local Math = require(script.Parent.DetMath)
local Rules={TransportLimit=3,TargetRange=130,PatrolRange=100,ShellRate=20,DockingRange=5,PassiveHealing=1,HealingRange=150,HealingPerPortLevel=5,RetreatPercent=75,PortSwitchRatio=0.75,MaxVeterancy=3,PiracyGrace=20,ShellLifetime=50}
function Rules.warshipCost(owned,constructed)return tostring(math.min(1000000,(math.min(owned,constructed)+1)*250000)) end
function Rules.tradeGold(distance,multiplier)return math.floor((75000/(1+Math.exp(-0.03*(distance-300)))+50*distance)*multiplier) end
function Rules.tradeRate(rejections,ships,levels)
 local function sigmoid(v,d,m)return 1/(1+Math.exp(-d*(v-m))) end
 local saturation=math.max(1-sigmoid(ships,0.6931471805599453/50,330),0.25*(1-sigmoid(ships,0.6931471805599453/100,800)))
 local boost=if levels<=0 then 1 else 1+(0.5*math.clamp((6-levels)/5,0,1))/levels
 return math.max(1,math.floor(((100/(boost*boost))*(1/(rejections+1)))/saturation))
end
function Rules.shellDamage(roll,veterancy)return math.floor(((roll-1)*25+200)*(100+veterancy*20)/100) end
function Rules.maxHealth(veterancy)return math.floor(1000*(100+veterancy*20)/100) end
function Rules.progress(veterancy,progress,kind)
 if kind=="Warship" then return math.min(3,veterancy+1),0 end
 if veterancy>=3 then return veterancy,progress end
 progress+=if kind=="TransportShip" then 25 else 10
 while progress>=250 and veterancy<3 do progress-=250;veterancy+=1 end
 return veterancy,if veterancy>=3 then 0 else progress
end
return Rules
