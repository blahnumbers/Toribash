-- modern main menu UI
-- DO NOT MODIFY THIS FILE

TB_MENU_DEBUG = false

TB_MENU_MAIN_ISOPEN = TB_MENU_MAIN_ISOPEN or 0
TB_MENU_INVENTORY_ISOPEN = TB_MENU_INVENTORY_ISOPEN or 0
TB_MENU_MATCHMAKE_ISOPEN = TB_MENU_MATCHMAKE_ISOPEN or 0
TB_MENU_CLANS_ISOPEN = TB_MENU_CLANS_ISOPEN or 0
TB_MENU_CLANS_OPENCLANID = TB_MENU_CLANS_OPENCLANID or 0
TB_MENU_NOTIFICATIONS_ISOPEN = 0
TB_MENU_NOTIFICATIONS_COUNT = 0
TB_MENU_REPLAYS_ISOPEN = TB_MENU_REPLAYS_ISOPEN or 0
TB_MENU_REPLAYS_ONLINE = TB_MENU_REPLAYS_ONLINE or 0
TB_MENU_DOWNLOAD_INACTION = TB_MENU_DOWNLOAD_INACTION or false
TB_MENU_KEYBOARD_ENABLED = false
TB_LAST_MENU_SCREEN_OPEN = TB_LAST_MENU_SCREEN_OPEN or 2
TB_MENU_HOME_CURRENT_ANNOUNCEMENT = TB_MENU_HOME_CURRENT_ANNOUNCEMENT or 1

if (TORISHOP_ISOPEN == 1) then
	start_new_game()
	TORISHOP_ISOPEN = 0
end

--[[if (not TB_MENU_CHAT_IGNORE_OVERRIDE) then --and not TB_MENU_CHAT_IGNORE) then
	dofile("system/ignore_manager.lua")
	ChatIgnore:activate()
end]]

if (TB_MENU_MAIN_ISOPEN == 1) then
	remove_hooks("tbMainMenuVisual")
	remove_hooks("tbMenuConsoleIgnore")
	remove_hooks("tbMenuKeyboardHandler")
	
	enable_camera_movement()
	disable_menu_keyboard()
	disable_blur()
	
	TB_MENU_MAIN_ISOPEN = 0
	tbMenuMain:kill()
	return
end

if (get_option("newmenu") == 0) then
	echo("You need to enable new UI to load this.")
	echo("   ^08/opt newmenu 1")
	return
end

dofile("toriui/uielement.lua")

-- Set old UI and restart game client on low resolution
if (WIN_W < 950 or WIN_H < 600) then
	echo("^04Screen resolution too low, switching to old UI")
	set_option("newmenu", "0")
	close_menu()
	return
end

dofile("system/menu_manager.lua")

TBMenu:create()
TBMenu:getTranslation(get_language())

dofile("system/store_manager.lua")
dofile("system/player_info.lua")
dofile("system/matchmake_manager.lua")
dofile("system/rewards_manager.lua")
dofile("system/clans_manager.lua")
dofile("system/friendlist_manager.lua")
dofile("system/replays_manager.lua")
dofile("system/bounty_manager.lua")

TB_MENU_PLAYER_INFO = {}
TB_MENU_PLAYER_INFO.username = PlayerInfo:getUser()
TB_MENU_PLAYER_INFO.data = PlayerInfo:getUserData()
TB_MENU_PLAYER_INFO.ranking = PlayerInfo:getRanking()
TB_MENU_PLAYER_INFO.clan = PlayerInfo:getClan(TB_MENU_PLAYER_INFO.username)
TB_MENU_PLAYER_INFO.items = PlayerInfo:getItems(TB_MENU_PLAYER_INFO.username)

if (PlayerInfo:getLoginRewards().available and TB_STORE_DATA.ready) then
	TB_MENU_NOTIFICATIONS_COUNT = TB_MENU_NOTIFICATIONS_COUNT + 1
end

if (os.clock() < 10) then
	TB_STORE_DATA = { onsale = Torishop:getSaleItem(true) }
else 
	TB_STORE_DATA = Torishop:getItems()
	if (TB_STORE_DATA) then
		TB_STORE_DATA.ready = true
		TB_STORE_DATA.onsale = Torishop:getSaleItem()
	end
end


local launchOption = ARG1
if (launchOption == "15") then
	TBMenu:showMain(true)
	TBMenu:showTorishopMain()
elseif (launchOption == "friendslist") then
	TBMenu:showMain(true)
	TBMenu:showFriendsList()
elseif (launchOption == "matchmake" and TB_MENU_MATCHMAKE_ISOPEN == 0) then
	TBMenu:showMain(true)
	TBMenu:showMatchmaking()
elseif (launchOption:match("clans ")) then
	TBMenu:showMain(true)
	local clantag = launchOption:gsub("clans ", "")
	clantag = PlayerInfo:getClanTag(clantag)
	TBMenu:showClans(clantag)
else
	TBMenu:showMain()
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
				if (TB_STORE_DATA) then
					TB_STORE_DATA.ready = true
					TB_STORE_DATA.onsale = Torishop:getSaleItem()
				end
				if (PlayerInfo:getLoginRewards().available and TB_MENU_MAIN_ISOPEN == 1) then
					if (TB_MENU_INVENTORY_ISOPEN == 0 and TB_MENU_MATCHMAKE_ISOPEN == 0 and TB_MENU_CLANS_ISOPEN == 0) then
						TBMenu:showLoginRewards()
					end
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
			if (x > WIN_W / 2) then
				Torishop:refreshInventory()
				if (INVENTORY_SELECTION_RESET) then
					INVENTORY_SELECTED_ITEMS = {}
					INVENTORY_SELECTION_RESET = false
				end
			else
				INVENTORY_UPDATE = false
				INVENTORY_SELECTION_RESET = false
			end
		end
	end
	if (TB_MENU_MAIN_ISOPEN == 1) then 
		return 1 
	end 
end)
add_hook("key_up", "tbMenuKeyboardHandler", function(s) UIElement:handleKeyUp(s) return 1 end)
add_hook("key_down", "tbMenuKeyboardHandler", function(s) UIElement:handleKeyDown(s) return 1 end)
add_hook("draw2d", "tbMainMenuVisual", function() TBMenu:drawVisuals() end)
add_hook("draw_viewport", "tbMainMenuVisual", function() TBMenu:drawViewport() end)
add_hook("console", "tbMainMenuStatic", function(s, i) 
		if (s == "Download complete" and TB_MENU_DOWNLOAD_INACTION) then 
			TB_MENU_DOWNLOAD_INACTION = false 
			return 1 
		end 
	end)
add_hook("new_mp_game", "tbMainMenuStatic", function() 
		if (TB_MENU_MAIN_ISOPEN == 1) then 
			TB_MATCHMAKER_SEARCHSTATUS = nil
			close_menu() 
		end
	end)