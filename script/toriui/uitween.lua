require("toriui.uielement3d")

local sin = math.sin
local cos = math.cos
local mclamp = math.clamp
local pi = math.pi

---@alias UITweenMode
---| "linear"
---| "sine"

if (UITween == nil) then
	---Manager class to allow framerate independent smooth transitions
	---
	---**Version 5.71**
	---* Minor performance improvements by using local references to math global functions
	UITween = {
		ver = 5.71
	}
	UITween.__index = UITween
end

---Internal UITween clamping function
---@param ratio number
---@return number
---@return boolean
local function clamp(ratio)
	ratio = mclamp(ratio, 0, 1)
	if (ratio == 0 or ratio == 1) then
		return ratio, true
	end
	return ratio, false
end

---Tweens a value according to the specified mode
---@param mode UITweenMode
---@param ratio number
---@param value number?
---@return number?
function UITween.EaseIn(mode, ratio, value)
	if (mode == "sine") then
		return UITween.SineEaseIn(ratio, value)
	elseif (mode == "linear") then
		return UITween.LinearEaseIn(ratio, value)
	end
	return UITween.LinearEaseIn(ratio, value)
end

---Tweens a value according to the specified mode
---@param mode UITweenMode
---@param ratio number
---@param value number?
---@return number?
function UITween.EaseOut(mode, ratio, value)
	if (mode == "sine") then
		return UITween.SineEaseOut(ratio, value)
	elseif (mode == "linear") then
		return UITween.LinearEaseOut(ratio, value)
	end
	return UITween.LinearEaseOut(ratio, value)
end

---Returns a tweened value between x and y according to the sepcified mode
---@param mode UITweenMode
---@param x number
---@param y number
---@param ratio number
---@return number?
function UITween.TweenValue(mode, x, y, ratio)
	if (mode == "sine") then
		return UITween.SineTween(x, y, ratio)
	elseif (mode == "linear") then
		return UITween.LinearTween(x, y, ratio)
	end
	return UITween.LinearTween(x, y, ratio)
end

---@param ratio number
---@param value number?
---@return number
function UITween.SineEaseIn(ratio, value)
	local ratio, exit = clamp(ratio)
	if (exit) then return (value or 1) * ratio end
	return (value or 1) * (1 - cos(ratio * (pi / 2)));
end

---@param ratio number
---@param value number?
---@return number
function UITween.SineEaseOut(ratio, value)
	local ratio, exit = clamp(ratio)
	if (exit) then return (value or 1) * ratio end
	return (value or 1) * sin(ratio * (pi / 2));
end

---@param x number
---@param y number
---@param ratio number
---@return number
function UITween.SineTween(x, y, ratio)
	local ratio = clamp(ratio)
	return UITween.SineEaseOut(1 - ratio, x) + UITween.SineEaseIn(ratio, y)
end

---@param ratio number
---@param value number?
---@return number
function UITween.LinearEaseIn(ratio, value)
	local ratio = clamp(ratio)
	return (value or 1) * ratio;
end

---@param ratio number
---@param value number?
---@return number
function UITween.LinearEaseOut(ratio, value)
	local ratio = clamp(ratio)
	return (value or 1) * (1 - ratio);
end

---@param x number
---@param y number
---@param ratio number
---@return number
function UITween.LinearTween(x, y, ratio)
	return UITween.LinearEaseOut(ratio, x) + UITween.LinearEaseIn(ratio, y)
end

---Per-frame version of `x = UITween.SineTween(x, y, ratio)`, for a value that eases from wherever it currently is
---and gets fed back in every drawn frame. Moves `x` the share of the way to `y` that SineTween moved it per frame
---at `UIElement.REFERENCE_FPS`, scaled to the time this frame took, so the animation looks the same at any frame rate.
---Reaches `y` once `ratio` reaches 1, like SineTween.
---@param x number Current value
---@param y number Target value
---@param ratio number Same ratio you would pass to SineTween
---@return number
function UITween.SineFrameTween(x, y, ratio)
	local ratio = clamp(ratio)
	return UIElement.frameApproach(x, y, 1 - cos(ratio * (pi / 2)))
end

---Per-frame version of `x = UITween.LinearTween(x, y, ratio)`, see `UITween.SineFrameTween()`
---@param x number Current value
---@param y number Target value
---@param ratio number Same ratio you would pass to LinearTween
---@return number
function UITween.LinearFrameTween(x, y, ratio)
	return UIElement.frameApproach(x, y, (clamp(ratio)))
end
