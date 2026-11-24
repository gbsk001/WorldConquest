--!strict
-- Fixed 100 ms simulation steps. Frame budget delays work; it never skips ticks.
local Clock={Step=0.1}
function Clock.new(step: ()->(), maxSteps: number?)
	local accumulated=0
	local clock={Tick=0,Backlog=0}
	function clock.advance(dt: number): number
		assert(dt==dt and dt>=0 and dt<math.huge)
		accumulated+=dt
		local count=0
		while accumulated+1e-9>=Clock.Step and count<(maxSteps or 4) do
			step(); accumulated-=Clock.Step; clock.Tick+=1; count+=1
		end
		clock.Backlog=math.max(0,accumulated)
		return count
	end
	return clock
end
return Clock
