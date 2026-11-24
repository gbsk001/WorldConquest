--!strict
-- Adapted from OpenFront PseudoRandom.ts, commit 8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE and NOTICE.
-- Modified 2026-11-17: Luau bit32, exact imul limbs, explicit serializable state.
local Random32 = {}
local MOD = 4294967296
function Random32.imul(a: number, b: number): number
	local al, bl = a % 65536, b % 65536
	return (al * bl + ((math.floor(a / 65536) * bl + al * math.floor(b / 65536)) % 65536) * 65536) % MOD
end
local function signed(n: number): number return if n >= 2147483648 then n - MOD else n end
function Random32.fromState(state: {number})
	assert(#state == 4)
	local a,b,c,d = state[1]%MOD,state[2]%MOD,state[3]%MOD,state[4]%MOD
	local rng = {}
	function rng.next(): number
		local t = (a+b+d)%MOD
		d = (d+1)%MOD
		a = bit32.bxor(b,bit32.rshift(b,9))
		b = (c+bit32.lshift(c,3))%MOD
		c = (bit32.bor(bit32.lshift(c,21),bit32.rshift(c,11))+t)%MOD
		return t/MOD
	end
	function rng.nextInt(lo: number, hi: number): number
		lo,hi=math.floor(lo),math.floor(hi)
		return math.floor(rng.next()*(hi-lo))+lo
	end
	function rng.getState(): {number} return {signed(a),signed(b),signed(c),signed(d)} end
	return rng
end
function Random32.new(seed: number)
	assert(seed==seed and math.abs(seed)<math.huge,"finite seed required")
	local h = (if seed < 0 then math.ceil(seed) else math.floor(seed))%MOD
	local function split(): number
		h=(h+0x9e3779b9)%MOD
		local t=Random32.imul(bit32.bxor(h,bit32.rshift(h,16)),0x21f0aaad)
		t=Random32.imul(bit32.bxor(t,bit32.rshift(t,15)),0x735a2d97)
		return bit32.bxor(t,bit32.rshift(t,15))
	end
	local rng=Random32.fromState({split(),split(),split(),split()})
	for _=1,12 do rng.next() end
	return rng
end
return Random32
