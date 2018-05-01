-- daily login rewards script
-- made by sir

dofile("system/login_daily_manager.lua")
dofile("toriui/uielement.lua")

if (ARG1 == '') then
	return
end

local days_cons = ARG1:gsub("%s%d%s%d+$", "")
local is_available = ARG1:gsub("^%d%s", ""):gsub("%s%d+$", "")
local seconds_to_next = ARG1:gsub("^%d%s%d%s", "")

if (is_available == "1") then
	rewards = LoginDaily:create()
	LoginDaily:getRewardData()
	LoginDaily:showMain(true, tonumber(days_cons), tonumber(seconds_to_next))

	add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y) UIElement:handleMouseDn(s, x, y) end)
	add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
	add_hook("mouse_move", "uiMouseHandler", function(x, y) UIElement:handleMouseHover(x, y) end)
	add_hook("draw2d", "dailyLoginVisual", function() LoginDaily:drawVisuals() end)
end