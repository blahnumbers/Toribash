-- modern main menu UI
-- DO NOT MODIFY THIS FILE

-- If tutorials are active, ESC press launches tutorial exit popup instead of main menu
if (TUTORIAL_ISACTIVE) then
	return
end
-- Also ignore for vanilla store previewer
if (STORE_VANILLA_PREVIEW) then
	return
end
if (STORE_VANILLA_POST) then
	STORE_VANILLA_POST = false
	set_option("hud", 1)
	chat_input_activate()
end

TB_MENU_DEBUG = get_option("menudebug") == 1
if (TB_MENU_DEBUG) then
	require = function(file)
		dofile(file .. ".lua")
	end
end

TB_MENU_MAIN_ISOPEN = TB_MENU_MAIN_ISOPEN or 0
TB_MENU_SPECIAL_SCREEN_ISOPEN = TB_MENU_SPECIAL_SCREEN_ISOPEN or 0
TB_MENU_CLANS_OPENCLANID = TB_MENU_CLANS_OPENCLANID or 0
TB_MENU_NOTIFICATIONS_ISOPEN = 0
TB_MENU_NOTIFICATIONS_COUNT = TB_MENU_NOTIFICATIONS_COUNT or 0
TB_MENU_REPLAYS_ONLINE = TB_MENU_REPLAYS_ONLINE or 0
TB_MENU_DOWNLOAD_INACTION = TB_MENU_DOWNLOAD_INACTION or false
TB_MENU_KEYBOARD_ENABLED = false
TB_LAST_MENU_SCREEN_OPEN = TB_LAST_MENU_SCREEN_OPEN or (get_option("newshopitem") == 1 and 1 or 2)
TB_MENU_HOME_CURRENT_ANNOUNCEMENT = TB_MENU_HOME_CURRENT_ANNOUNCEMENT or 1

if (TB_MENU_MAIN_ISOPEN == 1) then
	remove_hooks("tbMainMenuVisual")
	remove_hooks("tbMainMenuMouse")
	remove_hooks("tbMenuConsoleIgnore")
	remove_hooks("tbMenuKeyboardHandler")
	
	enable_camera_movement()
	disable_blur()
	disable_menu_keyboard()
	chat_input_activate()
	
	TB_MENU_MAIN_ISOPEN = 0
	tbMenuMain:kill()
	return
end

if (get_option("newmenu") == 0) then
	echo("You need to enable new UI to load this.")
	echo("   ^08/opt newmenu 1")
	return
end

dofile("toriui/uielement3d.lua")

-- Set old UI and return
if (WIN_W < 950 or WIN_H < 600) then
	set_option("newmenu", "0")
	return
end

dofile("system/menu_defines.lua")
require("system/menu_manager")

TBMenu:create()
TBMenu:getTranslation(get_language())

dofile("system/menu_backend_defines.lua")
require("system/network_request")
require("system/store_manager")
require("system/player_info")
--dofile("system/matchmake_manager.lua")
require("system/notifications_manager")
require("system/quests_manager")
require("system/rewards_manager") --?
require("system/clans_manager")
require("system/friendlist_manager")
require("system/replays_manager")
require("system/bounty_manager")
require("system/settings_manager")
require("system/scripts_manager")
require("system/events_manager")
require("system/events_online_manager")
require("system/news_manager")

TB_MENU_PLAYER_INFO = {}
TB_MENU_PLAYER_INFO.username = PlayerInfo:getUser()
TB_MENU_PLAYER_INFO.data = PlayerInfo:getUserData()
TB_MENU_PLAYER_INFO.ranking = PlayerInfo:getRanking()
TB_MENU_PLAYER_INFO.clan = PlayerInfo:getClan(TB_MENU_PLAYER_INFO.username)
TB_MENU_PLAYER_INFO.items = PlayerInfo:getItems(TB_MENU_PLAYER_INFO.username)

if (not TB_STORE_DATA) then
	TB_STORE_DATA = {}
end
if (not TB_STORE_DATA.ready or TB_MENU_DEBUG) then
	TB_STORE_DATA, TB_STORE_SECTIONS = Torishop:getItems()
	TB_STORE_MODELS = Torishop:getModelsData()
end

if (PlayerInfo:getLoginRewards().available and TB_STORE_DATA.ready and not TB_MENU_NOTIFICATION_LOGINREWARDS) then
	TB_MENU_NOTIFICATIONS_COUNT = TB_MENU_NOTIFICATIONS_COUNT + 1
	TB_MENU_NOTIFICATION_LOGINREWARDS = true
end

local launchOption = ARG
if (launchOption == "" and ARG1) then
	launchOption = ARG1
end
ARG, ARG1 = nil, nil
if (launchOption == "15") then
	TBMenu:showMain(true)
	TBMenu:showTorishopMain()
elseif (launchOption == "friendslist") then
	TBMenu:showMain(true)
	TBMenu:showFriendsList()
elseif (launchOption == "matchmake" and TB_MENU_SPECIAL_SCREEN_ISOPEN == 2) then
	TBMenu:showMain(true)
	TBMenu:showMatchmaking()
elseif (launchOption:match("clans ")) then
	TBMenu:showMain(true)
	local clantag = launchOption:gsub("clans ", "")
	clantag = PlayerInfo:getClanTag(clantag)
	TBMenu:showClans(clantag)
elseif (launchOption == "register") then
	TB_MENU_MAIN_ISOPEN = 0
	dofile("tutorial/tutorial_manager.lua")
	Tutorials:runTutorial(1, true)
else
	TBMenu:showMain()
end

-- Wait for customs update on client start
if (os.clock() < 10) then
	add_hook("draw2d", "playerinfoUpdate", function()
		for i,v in pairs(get_downloads()) do
			if (v:find("item.dat")) then
				return
			end
		end
		TB_MENU_PLAYER_INFO.data = PlayerInfo:getUserData()
		TB_MENU_PLAYER_INFO.items = PlayerInfo:getItems(TB_MENU_PLAYER_INFO.username)
		TB_MENU_PLAYER_INFO.clan = PlayerInfo:getClan(TB_MENU_PLAYER_INFO.username)
		download_quest(TB_MENU_PLAYER_INFO.username)
		download_global_quests()
		if (TB_MENU_MAIN_ISOPEN == 1) then
			TBMenu:showUserBar()
		end
		add_hook("draw2d", "playerinfoUpdate", function()
				if (#get_downloads() == 0) then
					TB_MENU_PLAYER_INFO.ranking = PlayerInfo:getRanking()
					TB_STORE_DATA, TB_STORE_SECTIONS = Torishop:getItems()
					TB_STORE_MODELS = Torishop:getModelsData()
					QUESTS_DATA = Quests:getQuests()
					QUESTS_GLOBAL_DATA = Quests:getGlobalQuests()
					download_clan()
					if (not is_steam()) then
						Request:queue(function() get_latest_version() end,"versioncheck", function()
								local latestVersion = get_network_response()
								local currentVersion = tonumber(TORIBASH_VERSION)
								latestVersion = tonumber(latestVersion)
								if (currentVersion < latestVersion) then
									TBMenu:showConfirmationWindow("Toribash " .. latestVersion .. " is now available.\nWould you like to download it now?", function() open_url("https://www.toribash.com/downloads.php") end)
								end
							end)
					end
					add_hook("draw2d", "playerinfoUpdate", function()
						if (get_network_task() == 0) then
							download_server_file("news" .. (is_steam() and "light" or ("&ver=" .. TORIBASH_VERSION)), 0)
							add_hook("draw2d", "playerinfoUpdate", function()
									if (#get_downloads() == 0) then
										if (PlayerInfo:getLoginRewards().available) then
											if (TB_MENU_MAIN_ISOPEN == 1 and TB_MENU_SPECIAL_SCREEN_ISOPEN == 0 and TB_MENU_IGNORE_REWARDS == 0) then
												if (not TB_MENU_NOTIFICATION_LOGINREWARDS) then
													TB_MENU_NOTIFICATIONS_COUNT = TB_MENU_NOTIFICATIONS_COUNT + 1
													TB_MENU_NOTIFICATION_LOGINREWARDS = true
												end
												TBMenu:showNotifications()
											-- else
											-- Need to add some way to display the reward has been claimed first
											-- 	claim_reward()
											-- 	Request:new("loginreward", function() update_tc_balance() end)
											end
										end
										remove_hooks("playerinfoUpdate")
									end
								end)
						end
					end)
				end
			end)
	end)
	
	-- Set default atmosphere from a draw2d hook so that shader settings are applied properly
	if (not DEFAULT_ATMOSPHERE_ISSET) then
		add_hook("draw2d", "atmodefault", function()
				dofile("system/atmospheres_defines.lua")
				dofile("system/atmospheres_manager.lua")
				Atmospheres:loadDefaultAtmo()
				remove_hooks("atmodefault")
			end)
	end
end

UIElement:mouseHooks()
add_hook("key_up", "tbMenuKeyboardHandler", function(s) UIElement:handleKeyUp(s) return 1 end)
add_hook("key_down", "tbMenuKeyboardHandler", function(s) UIElement:handleKeyDown(s) return 1 end)
add_hook("draw2d", "tbMainMenuVisual", function() UIElement:drawVisuals(TB_MENU_MAIN_GLOBALID) end)
add_hook("draw_viewport", "tbMainMenuVisual", function() UIElement3D:drawViewport(TB_MENU_MAIN_GLOBALID) end)

add_hook("console", "tbMainMenuStatic", function(s, i)
		if (s == "Download complete" and TB_MENU_DOWNLOAD_INACTION) then
			TB_MENU_DOWNLOAD_INACTION = false
			return 1
		end
	end)
add_hook("new_mp_game", "tbMainMenuStatic", function()
		TB_MATCHMAKER_SEARCHSTATUS = nil
		set_discord_rpc("", "")
		if (TB_MENU_MAIN_ISOPEN == 1) then
			close_menu()
		end
	end)

-- Keep hub elements always displayed above tooltip and movememory
add_hook("draw2d", "tbMainHubVisual", function()
		if (TB_MENU_MAIN_ISOPEN == 0) then
			if (TOOLTIP_ACTIVE) then
				UIElement:drawVisuals(TB_TOOLTIP_GLOBALID)
			end
			if (TB_MOVEMEMORY_ISOPEN == 1) then
				UIElement:drawVisuals(TB_MOVEMEMORY_GLOBALID)
			end
			UIElement:drawVisuals(TB_MENU_HUB_GLOBALID)
		end
	end)
add_hook("draw_viewport", "tbMainHubVisual", function()
		if (TB_MENU_MAIN_ISOPEN == 0) then
			UIElement3D:drawViewport(TB_MENU_HUB_GLOBALID)
		end
	end)

-- Load miscellaneous scripts
if (get_option("chatcensor") > 0 and not CHATIGNORE_ACTIVE) then
	dofile("system/ignore_manager.lua")
	ChatIgnore:activate()
end
if (get_option("movememory") == 1 and not MOVEMEMORY_ACTIVE) then
	dofile("system/movememory_manager.lua")
	MoveMemory:spawnHotkeyListener()
end
if (get_option("tooltip") == 1 and not TOOLTIP_ACTIVE) then
	dofile("system/tooltip_manager.lua")
	Tooltip:create()
end
if (get_option("showbroadcast") and not BROADCASTS_ACTIVE) then
	dofile("system/broadcast_manager.lua")
	Broadcasts:activate()
end
if (not QueueList) then
	local qmF = Files:new('system/queuelist_manager.lua')
	if (qmF.data) then
		qmF:close()
		dofile("system/queuelist_manager.lua")
	end
end
Notifications:getTotalNotifications()

if (launchOption == 'register') then
	remove_hooks("tbMainMenuVisual")
	remove_hooks("tbMainMenuMouse")
	remove_hooks("tbMenuConsoleIgnore")
	remove_hooks("tbMenuKeyboardHandler")
end
