-- modern main menu UI
-- DO NOT MODIFY THIS FILE

TB_MENU_MAIN_ISOPEN = TB_MENU_MAIN_ISOPEN or 0
TB_MENU_INVENTORY_ISOPEN = TB_MENU_INVENTORY_ISOPEN or 0
TB_MENU_MATCHMAKE_ISOPEN = TB_MENU_MATCHMAKE_ISOPEN or 0
TB_MENU_CLANS_ISOPEN = TB_MENU_CLANS_ISOPEN or 0
TB_MENU_CLANS_OPENCLANID = TB_MENU_CLANS_OPENCLANID or 0
TB_MENU_NOTIFICATIONS_ISOPEN = 0
TB_MENU_DOWNLOAD_INACTION = TB_MENU_DOWNLOAD_INACTION or false
TB_LAST_MENU_SCREEN_OPEN = TB_LAST_MENU_SCREEN_OPEN or 2
TB_MENU_HOME_CURRENT_ANNOUNCEMENT = TB_MENU_HOME_CURRENT_ANNOUNCEMENT or 1

if (TORISHOP_ISOPEN == 1) then
	start_new_game()
	TORISHOP_ISOPEN = 0
end

if (TB_MENU_MAIN_ISOPEN == 1) then
	remove_hooks("tbMainMenuVisual")
	remove_hooks("tbMenuConsoleIgnore")
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

TB_MENU_PLAYER_INFO = {}
TB_MENU_PLAYER_INFO.username = PlayerInfo:getUser()
TB_MENU_PLAYER_INFO.data = PlayerInfo:getUserData()
TB_MENU_PLAYER_INFO.ranking = PlayerInfo:getRanking()
TB_MENU_PLAYER_INFO.clan = PlayerInfo:getClan(TB_MENU_PLAYER_INFO.username)
TB_MENU_PLAYER_INFO.items = PlayerInfo:getItems(TB_MENU_PLAYER_INFO.username)

if (os.clock() < 10) then
	TB_STORE_DATA = { onsale = Torishop:getSaleItem(true) }
else 
	TB_STORE_DATA = Torishop:getItems()
	TB_STORE_DATA.onsale = Torishop:getSaleItem()
end

TBMenu:showMain()


if (PlayerInfo:getLoginRewards().available) then
	TBMenu:showLoginRewards()
end
local launchOption = ARG1
if (launchOption == "15") then
	TBMenu:showTorishopMain()
end
if (launchOption == "matchmake" and TB_MENU_MATCHMAKE_ISOPEN == 0) then
	TBMenu:showMatchmaking()
end
if (launchOption:match("clans ")) then
	TBMenu:showClans()
	local clantag = launchOption:gsub("clans ", "")
	clantag = PlayerInfo:getClanTag(clantag)
	local clanid
	for i,v in pairs(ClanData) do
		if (v.tag == clantag) then
			clanid = v.id
			break
		end
	end
	if (clanid) then
		Clans:showClan(tbMenuCurrentSection, clanid)
	end
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
				if (PlayerInfo:getLoginRewards().available and TB_MENU_MAIN_ISOPEN == 1) then
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