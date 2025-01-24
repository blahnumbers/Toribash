---@param element UIElement3D
---@param speed number
local function bubbleBounce(element, speed)
	---setup bounce if no data exists
	if (element.bouncePower == nil) then
		element.initialSize = table.clone(element.size)
		element.bouncePower = math.random(150, 400) / 1000
		element.maxvelocity = 0.65
		element.velocity = math.random(-element.maxvelocity * 100, element.maxvelocity * 100) / 100
		return
	end
	if (element.pos.z <= 0) then
		element.velocity = element.bouncePower
	elseif (element.pos.z < element.initialSize.x) then
		element.size.x = element.initialSize.x + (1 - math.pow(element.pos.z / element.initialSize.x, 0.75)) * element.initialSize.x * 0.5
	end
	element.velocity = math.min(element.velocity - 0.002 * speed, element.maxvelocity)
	element:moveTo(0, 0, element.velocity * speed)
end

return {
	onEnterFrame = bubbleBounce
}