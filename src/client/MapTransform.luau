--!strict
-- Normalize physical input to the explicit ScreenInsets.None root's reported
-- GUI origin once. Read the ACTUAL canvas rectangle, never a guessed inset.
local Transform = {}
function Transform.screenToGui(sx: number, sy: number, rootX: number, rootY: number): (number, number)
	return sx + rootX, sy + rootY
end
function Transform.toMap(sx: number, sy: number, left: number, top: number, width: number, height: number, mapWidth: number, mapHeight: number): (number?, number?)
	if width <= 0 or height <= 0 then return nil, nil end
	local u, v = (sx - left) / width, (sy - top) / height
	if u < 0 or u >= 1 or v < 0 or v >= 1 then return nil, nil end
	return u * mapWidth, v * mapHeight
end
function Transform.toScreen(x: number, y: number, left: number, top: number, width: number, height: number, mapWidth: number, mapHeight: number): (number, number)
	return left + x / mapWidth * width, top + y / mapHeight * height
end
function Transform.clampOrigin(value: number, extent: number, available: number): number
	return if extent <= available then (available - extent) / 2 else math.clamp(value, available - extent, 0)
end
return Transform
