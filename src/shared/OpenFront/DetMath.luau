--!strict
-- OpenFront DetMath.ts at 8f1a0add, translated to Luau on 2026-11-17.
-- Copyright OpenFront and Contributors. AGPL-3.0; see LICENSE and NOTICE.
-- Buffer bit views replace JS typed-array aliases. Arithmetic order is retained.
local D={}
local bits=buffer.create(8)
local LN2,LOG2E,SQRT2=0.6931471805599453,1.4426950408889634,1.4142135623730951
local PI,PI_2,PI_4,TAN_PI_8=3.141592653589793,1.5707963267948966,0.7853981633974483,0.41421356237309503
function D.pow2(n: number): number
	if n>1023 then return math.huge end
	if n< -1022 then return 0 end
	buffer.writeu32(bits,4,bit32.lshift(n+1023,20)); buffer.writeu32(bits,0,0)
	return buffer.readf64(bits,0)
end
function D.exp(x: number): number
	if x>709 then return math.huge end
	if x< -708 then return 0 end
	local n=math.floor(x*LOG2E+0.5)
	local r=x-n*LN2
	local p=1+r*(1+r*(1/2+r*(1/6+r*(1/24+r*(1/120+r*(1/720+r*(1/5040+r*(1/40320))))))))
	return p*D.pow2(n)
end
function D.log(x: number): number
	if x<=0 then return if x==0 then -math.huge else 0/0 end
	local e=0
	if x<2.2250738585072014e-308 then x*=18014398509481984; e=-54 end
	buffer.writef64(bits,0,x)
	local high=buffer.readu32(bits,4)
	e+=bit32.band(bit32.rshift(high,20),0x7ff)-1023
	buffer.writeu32(bits,4,bit32.bor(bit32.band(high,0x000fffff),0x3ff00000))
	local m=buffer.readf64(bits,0)
	if m>SQRT2 then m*=0.5; e+=1 end
	local s=(m-1)/(m+1); local z=s*s
	local series=1+z*(1/3+z*(1/5+z*(1/7+z*(1/9+z*(1/11+z*(1/13))))))
	return e*LN2+2*s*series
end
function D.pow(x: number,y: number): number
	if y==0 or x==1 then return 1 end
	if x==0 then return if y>0 then 0 else math.huge end
	if x<0 then return 0/0 end
	return D.exp(y*D.log(x))
end
local function atanUnit(z: number): number
	local base=0
	if z>TAN_PI_8 then base=PI_4; z=(z-1)/(z+1) end
	local w=z*z
	local series=1-w*(1/3-w*(1/5-w*(1/7-w*(1/9-w*(1/11-w*(1/13-w*(1/15-w/17)))))))
	return base+z*series
end
function D.atan2(y: number,x: number): number
	if y==0 then return if x>=0 then 0 else PI end
	if x==0 then return if y>0 then PI_2 else -PI_2 end
	local ax,ay=math.abs(x),math.abs(y)
	local a=if ay<=ax then atanUnit(ay/ax) else PI_2-atanUnit(ax/ay)
	if x<0 then a=PI-a end
	return if y<0 then -a else a
end
return D
