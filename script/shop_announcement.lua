if (SHOP_ANNOUNCEMENT_LAUNCHED == true) then
	SHOP_ANNOUNCEMENT_LAUNCHED = false
	shopAnnViewBG:kill()
	remove_hooks("shopAnnouncementVisual")
end

if (get_option("newshopitem") == 0 and not ARG1:match("-override")) then
	return
end

dofile("system/shop_announcement_manager.lua")
dofile("toriui/uielement.lua")

ShopAnn:create()
ShopAnn:showMain()
SHOP_ANNOUNCEMENT_LAUNCHED = true

add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y) UIElement:handleMouseDn(s, x, y) end)
add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
add_hook("mouse_move", "uiMouseHandler", function(x, y) UIElement:handleMouseHover(x, y) end)
add_hook("draw2d", "shopAnnouncementVisual", function() ShopAnn:drawVisuals() end)