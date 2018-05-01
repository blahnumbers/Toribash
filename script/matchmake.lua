-- matchmake UI
-- DO NOT MODIFY THIS FILE
if (not TBMenu) then
	return
end

dofile("toriui/uielement.lua")
dofile("system/matchmake_manager.lua")

Matchmake:connect()
Matchmake:showMain()

add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y) UIElement:handleMouseDn(s, x, y) end)
add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
add_hook("mouse_move", "uiMouseHandler", function(x, y) UIElement:handleMouseHover(x, y) end)
add_hook("draw2d", "tbMatchmakeVisual", function() Matchmake:drawVisuals() end)