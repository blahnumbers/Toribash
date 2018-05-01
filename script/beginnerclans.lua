-- beginner clans join ui

if (BEGINNERCLANUIOPT) then
	return
end
BEGINNERCLANUIOPT = "clanuipopup"

dofile("system/beginner_clans_manager.lua")
dofile("toriui/uielement.lua")

if (get_option(BEGINNERCLANUIOPT) == 2) then
	return
end

BeginnerClans:create()
local canShow = BeginnerClans:canShow()
remove_hooks("beginnerClanConsoleIgnore")

if (canShow == 0) then 
	return
end

BeginnerClans:showMain()

add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y) UIElement:handleMouseDn(s, x, y) end)
add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
add_hook("mouse_move", "uiMouseHandler", function(x, y) UIElement:handleMouseHover(x, y) end)
add_hook("draw2d", "beginnerClansVisual", function() BeginnerClans:drawVisuals() end)