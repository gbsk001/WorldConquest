--!strict
-- OpenFront GameImpl.executeNextTick execution ordering, adapted 2026-11-17.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE and NOTICE.
local Executions={}
function Executions.new()
	local active,pending={},{}
	local scheduler={Tick=0}
	function scheduler.add(execution) table.insert(pending,execution) end
	function scheduler.step(context)
		-- Tick old executions first; initialize queued executions afterwards.
		for _,e in ipairs(active) do
			if (not context.inSpawnPhase() or e.activeDuringSpawnPhase()) and e.isActive() then e.tick(scheduler.Tick) end
		end
		local waiting={}
		local i=1
		while i<=#pending do
			local e=pending[i]
			if not context.inSpawnPhase() or e.activeDuringSpawnPhase() then
				e.init(context,scheduler.Tick); table.insert(active,e)
			else table.insert(waiting,e) end
			i+=1
		end
		pending=waiting
		local remaining={}
		for _,e in ipairs(active) do if e.isActive() then table.insert(remaining,e) end end
		active=remaining; scheduler.Tick+=1
	end
	return scheduler
end
return Executions
