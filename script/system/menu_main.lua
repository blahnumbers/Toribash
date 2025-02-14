-- modern main menu UI
-- DO NOT MODIFY THIS FILE

-- If tutorials are active, ESC press launches tutorial exit popup instead of main menu
-- Also ignore for vanilla store previewer
if (TUTORIAL_ISACTIVE or STORE_VANILLA_PREVIEW) then
	return
end
if (STORE_VANILLA_POST) then
	STORE_VANILLA_POST = false
	set_option("hud", 1)
	chat_input_activate()
end

TB_MENU_DEBUG = get_option("menudebug") == 1
if (TB_MENU_DEBUG) then
	_G.old_require = _G.old_require or require
	require = function(file)
		dofile(file:gsub("%.", "/") .. ".lua")
	end
elseif (_G.old_require ~= nil) then
	require = _G.old_require
	_G.old_require = nil
end

---Global flag to tell if main menu is currently open
TB_MENU_MAIN_ISOPEN = TB_MENU_MAIN_ISOPEN or 0
TB_MENU_SPECIAL_SCREEN_ISOPEN = TB_MENU_SPECIAL_SCREEN_ISOPEN or 0
TB_MENU_CLANS_OPENCLANID = TB_MENU_CLANS_OPENCLANID or 0
TB_MENU_NOTIFICATIONS_COUNT = TB_MENU_NOTIFICATIONS_COUNT or 0
TB_MENU_REPLAYS_ONLINE = TB_MENU_REPLAYS_ONLINE or 0
TB_LAST_MENU_SCREEN_OPEN = TB_LAST_MENU_SCREEN_OPEN or 2

require("toriui.uielement3d")

---Global menu scale that adapts to user's current screen resolution
TB_MENU_GLOBAL_SCALE = math.min(WIN_H > 720 and 1 or WIN_H / 720, WIN_W > 1280 and 1 or WIN_W / 1280)

require("system.menu_defines")
require("system.iofiles")
require("system.menu_manager")

if (TB_MENU_MAIN_ISOPEN == 1) then
	TBMenu.Quit()
	return
end

if (get_option("newmenu") == 0) then
	echo("You need to enable new UI to load this.")
	echo("   ^08/opt newmenu 1")
	return
end

TBMenu.Init(_G.MENU_VERSION)
require("system.menu_backend_defines")
require("system.network_request")
require("system.downloader_manager")
require("system.roomlist_manager")
require("system.store_manager")
require("system.playerinfo_manager")
require("system.notifications_manager")
require("system.quests_manager")
require("system.rewards_manager")
require("system.clans_manager")
require("system.friends_manager")
require('system.mods_manager')
require("system.bounty_manager")
require("system.settings_manager")
require("system.scripts_manager")
require("system.tutorial_manager")
require("system.events_manager")
require("system.events_online_manager")
require("system.news_manager")
require("system.market_manager")
require("system.battlepass_manager")
require("system.ignore_manager")
require("system.queuelist_manager")
if (is_mobile()) then
	require("system.hud_manager")
end
require("system.replays_manager")
require("system.replay_hud")
require("system.gamerules_manager")
require("system.atmospheres_manager")
require("system.movememory_manager")
require("system.tooltip_manager")
require("system.broadcast_manager")
require("system.flames_manager")

TB_MENU_PLAYER_INFO = PlayerInfo.Get(PLAYERINFO_SCOPE_GENERAL)
TB_MENU_PLAYER_INFO:getClan()
TB_MENU_PLAYER_INFO:getRanking()
TB_MENU_PLAYER_INFO:getItems(PLAYERINFO_CSCOPE_ALL)
TB_MENU_CUSTOMS_REFRESHED = false

if (not Store.Ready or TB_MENU_DEBUG) then
	Store.GetItems()
	Store.GetModelsData()
end

if (PlayerInfo:getLoginRewards().available and Store.Ready and not TB_MENU_NOTIFICATION_LOGINREWARDS) then
	TB_MENU_NOTIFICATIONS_COUNT = TB_MENU_NOTIFICATIONS_COUNT + 1
	TB_MENU_NOTIFICATION_LOGINREWARDS = true
end

local launchOption = ARG
if (launchOption == "" and ARG1) then
	launchOption = ARG1
end
---@diagnostic disable-next-line: assign-type-mismatch
ARG, ARG1 = nil, nil
if (launchOption == "15") then
	TBMenu:showMain(true)
	TBMenu:showStoreMain()
elseif (launchOption == "friendslist") then
	TBMenu:showMain(true)
	TBMenu:showFriendsList()
--[[elseif (launchOption == "matchmake" and TB_MENU_SPECIAL_SCREEN_ISOPEN == 2) then
	TBMenu:showMain(true)
	TBMenu:showMatchmaking()]]
elseif (launchOption:match("clans ")) then
	TBMenu:showMain(true)
	local player = launchOption:gsub("clans ", "")
	TBMenu:showClans(PlayerInfo.Get(player).clan.tag)
elseif (launchOption == "register") then
	TB_MENU_MAIN_ISOPEN = 0
	usage_event("registertutorial")
else
	TBMenu:showMain()
end

local newsRefreshPeriod = get_option("autoupdate") == 1 and 600 or 86400
if (News.LastRefresh < os.clock_real() - newsRefreshPeriod) then
	TBMenu.RefreshData()
end

-- Only called on first menu launch
if (not _G.FIRST_LAUNCH and TBMenu.MenuMain ~= nil) then
	if (not is_steam() and not is_mobile()) then
		Request:queue(get_latest_version, "versioncheck", function()
				local latestVersion = tonumber(get_network_response())
				local currentVersion = tonumber(TORIBASH_VERSION)
				if (currentVersion < latestVersion) then
					TBMenu:showConfirmationWindow("Toribash " .. latestVersion .. " is now available.\nWould you like to download it now?", function() open_url("https://www.toribash.com/downloads") end)
				end
			end)
	end
	local rewardsObserver = TBMenu.MenuMain:addChild({})
	rewardsObserver:addCustomDisplay(true, function()
			local hasRewards = not table.empty(Rewards.Data)
			if (not hasRewards) then
				local downloads = get_downloads()
				for _, v in ipairs(downloads) do
					if (string.find(v, "loginrewards%.txt")) then
						return
					end
				end
				Rewards.ParseData()
			end
			if (PlayerInfo:getLoginRewards().available and
				Store.Ready and Store.Discounts.Prime ~= nil and
				not table.empty(Rewards.Data) and
				not TB_MENU_NOTIFICATION_LOGINREWARDS) then
				TB_MENU_NOTIFICATIONS_COUNT = TB_MENU_NOTIFICATIONS_COUNT + 1
				TB_MENU_NOTIFICATION_LOGINREWARDS = true
				TBMenu:showNotifications()
				rewardsObserver:kill()
			end
		end)
	_G.FIRST_LAUNCH = true
end

add_hook("draw2d", "__tbMainMenuVisual", function() UIElement.drawVisuals(TB_MENU_MAIN_GLOBALID) end)
add_hook("draw_viewport", "__tbMainMenuVisual", function() UIElement3D.drawViewport(TB_MENU_MAIN_GLOBALID) end)
add_hook("resolution_changed", "__tbMainMenuVisual", function()
		if (TB_MENU_MAIN_ISOPEN == 1) then
			close_menu()
			open_menu(19)
		end
	end)

add_hook("login", "__tbMainMenuStatic", TBMenu.RefreshData)
add_hook("downloader_complete", "__tbMainMenuStatic", function(filename)
		if (filename:find("custom/.*") and not filename:find(TB_MENU_PLAYER_INFO.username)) then
			-- Most files we'll download will be from custom, sort them out so we don't run checks on them
			return
		end
		if (filename:find("custom/" .. TB_MENU_PLAYER_INFO.username .. "/item.dat")) then
			Downloader.SafeCall(function()
				TB_MENU_PLAYER_INFO:getUserData()
				TB_MENU_PLAYER_INFO:getItems(PLAYERINFO_CSCOPE_ALL)
				TB_MENU_PLAYER_INFO:getClan()
				TB_MENU_CUSTOMS_REFRESHED = true
				if (TB_MENU_MAIN_ISOPEN == 1) then
					TBMenu:showUserBar()
				end
			end)
		elseif (filename:find("data/store.txt")) then
			Downloader.SafeCall(Store.GetItems)
		elseif (filename:find("data/store_obj.txt")) then
			Downloader.SafeCall(Store.GetModelsData)
		elseif (filename:find("data/clans.txt")) then
			Downloader.SafeCall(function()
				Clans:getClanData(true)
				TB_MENU_PLAYER_INFO:getClan()
				TB_MENU_CUSTOMS_REFRESHED = true
			end)
		elseif (filename:find("data/clanlevels.txt")) then
			Downloader.SafeCall(function()
				Clans:getLevelData(true)
			end)
		elseif (filename:find("data/clanachievements.txt")) then
			Downloader.SafeCall(function()
				Clans:getAchievementData(true)
			end)
		elseif (filename:find("data/quest.txt")) then
			Downloader.SafeCall(function()
				Quests:getQuests()
			end)
		elseif (filename:find("data/quests_global.dat")) then
			Downloader.SafeCall(function()
				Quests:getGlobalQuests()
			end)
		elseif (filename:find("data/inventory.txt")) then
			Downloader.SafeCall(Store.ParseInventory)
		elseif (filename:find("data/script/system/loginrewards.txt")) then
			Downloader.SafeCall(Rewards.ParseData)
		end
	end)

-- Clear any custom discord RPC message that was set earlier
add_hook("new_mp_game", "__tbMainMenuStatic", function()
		set_discord_rpc("", "")
	end)

---Spawn generic display hooks
---We want Tooltip and QueueList to stay below main elements to ensure they aren't blocking the view
add_hook("draw2d", "__tbMainHubVisual", function()
		if (TB_MENU_MAIN_ISOPEN == 1) then return end
		if (Tooltip.IsActive) then
			UIElement.drawVisuals(Tooltip.Globalid)
		end
		UIElement.drawVisuals(QueueList.Globalid)
		UIElement.drawVisuals(TB_MENU_HUB_GLOBALID)
	end)
add_hook("draw_viewport", "__tbMainHubVisual", function()
		if (TB_MENU_MAIN_ISOPEN == 1) then return end
		UIElement3D.drawViewport(QueueList.Globalid)
		UIElement3D.drawViewport(TB_MENU_HUB_GLOBALID)
	end)
add_hook("draw3d", "__tbMainHubVisual", function()
		UIElement3D.drawVisuals(TB_MENU_HUB_GLOBALID)
	end)
local enterFrame3D = function() UIElement3D.drawEnterFrame(TB_MENU_HUB_GLOBALID) end
add_hook("enter_frame", "__tbMainHubVisual", enterFrame3D)
add_hook("enter_freeze", "__tbMainHubVisual", enterFrame3D)
add_hook("new_game", "__tbMainHubVisual", enterFrame3D)

if (is_mobile()) then
	---Spawn mobile HUD separately and make sure it's above all other elements
	---This setup *will* work because we're now using deterministic execution order for hooks
	add_hook("draw2d", "__tbMobileHudVisual", function()
		if (TB_MENU_MAIN_ISOPEN == 1) then return end
		UIElement.drawVisuals(TBHud.Globalid)
		UIElement.drawVisuals(TBHud.HubGlobalid)
	end)
	add_hook("draw_viewport", "__tbMobileHudVisual", function()
		if (TB_MENU_MAIN_ISOPEN == 1) then return end
		UIElement3D.drawViewport(TBHud.Globalid)
		UIElement3D.drawViewport(TBHud.HubGlobalid)
	end)
end

Notifications:getTotalNotifications()

if (launchOption == 'register') then
	remove_hooks("__tbMainMenuVisual")
	remove_hooks("__tbMenuConsoleIgnore")
	Tutorials:runTutorial(1, nil, true)
end
