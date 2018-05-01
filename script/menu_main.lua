-- modern main menu UI
-- DO NOT MODIFY THIS FILE

TB_MENU_MAIN_ISOPEN = TB_MENU_MAIN_ISOPEN or 0
TB_MENU_MATCHMAKE_ISOPEN = TB_MENU_MATCHMAKE_ISOPEN or 0
TB_MENU_NOTIFICATIONS_ISOPEN = 0
TB_LAST_MENU_SCREEN_OPEN = TB_LAST_MENU_SCREEN_OPEN or 2
TB_MENU_HOME_CURRENT_ANNOUNCEMENT = TB_MENU_HOME_CURRENT_ANNOUNCEMENT or 1

if (TB_MENU_MAIN_ISOPEN == 1) then
	remove_hooks("tbMainMenuVisual")
	remove_hooks("tbMenuConsoleIgnore")
	disable_blur()
	TB_MENU_MAIN_ISOPEN = 0
	tbMenuMain:kill()
	return
end

dofile("toriui/uielement.lua")
dofile("system/menu_manager.lua")
dofile("system/player_info.lua")
dofile("system/matchmake_manager.lua")
dofile("system/rewards_manager.lua")
dofile("system/clans_manager.lua")
dofile("system/store_manager.lua")

TB_MENU_PLAYER_INFO = {}
TB_MENU_PLAYER_INFO.username = PlayerInfo:getUser()
TB_MENU_PLAYER_INFO.data = PlayerInfo:getUserData()
TB_MENU_PLAYER_INFO.ranking = PlayerInfo:getRanking()
TB_MENU_PLAYER_INFO.clan = PlayerInfo:getClan(TB_MENU_PLAYER_INFO.username)
TB_MENU_PLAYER_INFO.items = PlayerInfo:getItems(TB_MENU_PLAYER_INFO.username)

TB_STORE_DATA = TB_STORE_DATA or { onsale = { name = "Updating.." } }

TBMenu:create()
TBMenu:showMain()

if (PlayerInfo:getLoginRewards().available) then
	TBMenu:showLoginRewards()
end

-- Wait for customs update on client start
if (os.clock() < 10) then
	add_hook("draw2d", "playerinfoUpdate", function()
			if (#get_downloads() == 0) then
				TB_MENU_PLAYER_INFO.data = PlayerInfo:getUserData()
				TB_MENU_PLAYER_INFO.ranking = PlayerInfo:getRanking()
				TB_MENU_PLAYER_INFO.clan = PlayerInfo:getClan(TB_MENU_PLAYER_INFO.username)
				TB_MENU_PLAYER_INFO.items = PlayerInfo:getItems(TB_MENU_PLAYER_INFO.username)
				TB_STORE_DATA = Torishop:getItems()
				TB_STORE_DATA.onsale = Torishop:getSaleItem()
				if (PlayerInfo:getLoginRewards().available) then
					TBMenu:showLoginRewards()
				end
				remove_hooks("playerinfoUpdate")
			end
		end)
end

add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y) 
	UIElement:handleMouseDn(s, x, y) 
	if (TB_MENU_MAIN_ISOPEN == 1) then 
		return 1 
	end 
end)
add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
add_hook("mouse_move", "uiMouseHandler", function(x, y) 
	UIElement:handleMouseHover(x, y) 
	if (INVENTORY_UPDATE) then
		if (x ~= INVENTORY_MOUSE_POS.x or y ~= INVENTORY_MOUSE_POS.y) then
			Torishop:refreshInventory()
		end
	end
	if (TB_MENU_MAIN_ISOPEN == 1) then 
		return 1 
	end 
end)
add_hook("draw2d", "tbMainMenuVisual", function() TBMenu:drawVisuals() end)
add_hook("draw_viewport", "tbMainMenuVisual", function() TBMenu:drawViewport() end)
add_hook("new_mp_game", "tbMainMenuVisual", function() close_menu() end)