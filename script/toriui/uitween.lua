require("toriui.uielement3d")

local m_elasticA = 1.0
local m_elasticP = 0.3
local m_elasticS = m_elasticP / 4
local m_backS = 1.70158;

if (UITween == nil) then
	---Manager class to allow generic smooth transitions
	UITween = {
		ver = 1.0,
		__index = {}
	}
	setmetatable({}, UITween)
end

---Internal UITween clamping function
---@param ratio number
---@return number
---@return boolean
local function clamp(ratio)
	ratio = math.max(math.min(ratio, 1), 0)
	if (ratio == 0 or ratio == 1) then
		return ratio, true
	end
	return ratio, false
end

---Tweens a value from 0 to 1 according to the specified mode
---@param ratio number
---@param mode? string
---@return number
function UITween.EaseIn(ratio, mode)
	return UITween.SineEaseIn(ratio)
end

---@param ratio number
---@return number
function UITween.SineEaseIn(ratio)
	local ratio, exit = clamp(ratio)
	if (exit) then return ratio end
	return 1 - math.cos(ratio * (math.pi / 2));
end

---@param ratio number
---@return number
function UITween.SineEaseOut(ratio)
	local ratio, exit = clamp(ratio)
	if (exit) then return ratio end
	return math.sin(ratio * (math.pi / 2));
end

---@param x number
---@param y number
---@param ratio number
---@return number
function UITween.SineTween(x, y, ratio)
	local ratio = clamp(ratio)
	return x * UITween.SineEaseOut(1 - ratio) + y * UITween.SineEaseIn(ratio)
end
