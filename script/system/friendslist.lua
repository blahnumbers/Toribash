-- DO NOT MODIFY THIS FILE
-- Old UI friends interface

TB_MENU_DEFAULT_BG_COLOR = { 0.67, 0.11, 0.11, 1 }
TB_MENU_DEFAULT_DARKER_COLOR = { 0.607, 0.109, 0.109, 1 }

dofile("toriui/uielement.lua")
dofile("system/menu_manager.lua")
dofile("system/friendlist_manager.lua")

if (TBMenu.MenuMain) then
	FRIENDSLIST_OPEN = false
	TBMenu.MenuMain:kill()
end

FRIENDSLIST_OPEN = true
TBMenu:open()
function TBMenu:addBottomBloodSmudge() end
TBMenu:getTranslation(get_language())

TBMenu.MenuMain = UIElement:new({
	globalid = 1100,
	pos = { WIN_W / 8, WIN_H / 5 },
	size = { WIN_W / 8 * 6, WIN_H / 5 * 3 },
})
local navBarBG = UIElement:new({
	parent = TBMenu.MenuMain,
	pos = { 0, 0 },
	size = { TBMenu.MenuMain.size.w, 50 },
	bgColor = { 0, 0, 0, 0.95 }
})
TBMenu.NavigationBar = UIElement:new({
	parent = navBarBG,
	pos = { 0, 0 },
	size = { navBarBG.size.w, navBarBG.size.h }
})

TBMenu.CurrentSection = UIElement:new({
	parent = TBMenu.MenuMain,
	pos = { 0, 50 },
	size = { TBMenu.MenuMain.size.w, TBMenu.MenuMain.size.h - 50 },
	bgColor = TB_MENU_DEFAULT_DARKER_COLOR
})

TBMenu:showFriendsList()

add_hook("key_up", "tbMenuKeyboardHandler", function(s) UIElement:handleKeyUp(s) if (FRIENDSLIST_OPEN) then return 1 end end)
add_hook("key_down", "tbMenuKeyboardHandler", function(s) UIElement:handleKeyDown(s) if (FRIENDSLIST_OPEN) then return 1 end end)
add_hook("draw2d", "tbMainMenuVisual", function() UIElement:drawVisuals(1100) end)
