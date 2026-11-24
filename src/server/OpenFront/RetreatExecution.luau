--!strict
-- RetreatExecution.ts, revision 8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE/NOTICE.
local RetreatExecution={}
function RetreatExecution.new(sim,p,id)
 local active,ordered,start=true,false,0
 return {
  activeDuringSpawnPhase=function() return false end,isActive=function() return active end,
  init=function() start=sim.Tick end,
  tick=function()
   local attack=p.Attack
   for _,candidate in ipairs(p.Outgoing or {}) do if candidate.ID==id then attack=candidate;break end end
   if not ordered then
    if attack and attack.Active and attack.ID==id then attack.Retreating=true end
    ordered=true
   end
   if sim.Tick>=start+20 then
    if attack and attack.Active and attack.ID==id then attack.Retreated=true end
    active=false
   end
  end,
 }
end
return RetreatExecution
