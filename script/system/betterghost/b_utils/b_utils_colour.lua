---Better Ghost by bleed
---Draws a ghost showing where each fighter will be when the current turn ends
---Original post: https://forum.toribash.com/showthread.php?t=672946
---
---@author bleed (original)
---@author surge (modifications)
---@author AssassinPro, niavic, barbarbar, LostMail (additional credits)

---@class BetterGhostColour
local colour = {}

---Hue, saturation and lightness, all from 0 to 1
---@param r number
---@param g number
---@param b number
---@return number hue
---@return number saturation
---@return number lightness
local function to_hsl(r, g, b)
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local lightness = (max + min) / 2
	if max == min then
		return 0, 0, lightness
	end

	local delta = max - min
	local saturation = lightness > 0.5 and delta / (2 - max - min) or delta / (max + min)
	local hue
	if max == r then
		hue = (g - b) / delta + (g < b and 6 or 0)
	elseif max == g then
		hue = (b - r) / delta + 2
	else
		hue = (r - g) / delta + 4
	end
	return hue / 6, saturation, lightness
end

---@param p number
---@param q number
---@param hue number
---@return number
local function get_channel(p, q, hue)
	hue = hue % 1
	if hue < 1 / 6 then
		return p + (q - p) * 6 * hue
	elseif hue < 1 / 2 then
		return q
	elseif hue < 2 / 3 then
		return p + (q - p) * (2 / 3 - hue) * 6
	end
	return p
end

---@param hue number
---@param saturation number
---@param lightness number
---@return number r
---@return number g
---@return number b
local function from_hsl(hue, saturation, lightness)
	if saturation == 0 then
		return lightness, lightness, lightness
	end

	local q = lightness < 0.5 and lightness * (1 + saturation) or lightness + saturation - lightness * saturation
	local p = 2 * lightness - q
	return get_channel(p, q, hue + 1 / 3), get_channel(p, q, hue), get_channel(p, q, hue - 1 / 3)
end

---A colour that's easy to tell apart from `rgba`: the opposite hue, or for greys, white and black, the
---other end of light and dark. Keeps the alpha
---@param rgba Color
---@return Color
function colour.get_contrasting(rgba)
	-- Some shop colours go above 1 (Gold, Diamond), so work on a 0-1 copy and scale the result back up after
	local scale = math.max(1, rgba[1], rgba[2], rgba[3])
	local hue, saturation, lightness = to_hsl(rgba[1] / scale, rgba[2] / scale, rgba[3] / scale)
	if saturation < 0.2 then
		lightness = lightness < 0.5 and 0.8 or 0.2
	else
		hue = hue + 0.5
		-- Dark red and dark cyan are still hard to tell apart, so very dark or light colours flip too
		if math.abs(lightness - 0.5) > 0.2 then
			lightness = 1 - lightness
		end
	end

	local r, g, b = from_hsl(hue, saturation, lightness)
	return { r * scale, g * scale, b * scale, rgba[4] }
end

return colour
