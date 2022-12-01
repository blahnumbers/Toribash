-- daily login rewards script

dofile("system/menu_manager.lua")
dofile("system/notifications_manager.lua")
dofile("system/rewards_manager.lua")
dofile("system/store_manager.lua")
dofile("system/player_info.lua")
dofile("toriui/uielement.lua")

if (ARG == '') then
	return
end

local days_cons = ARG:gsub("%s%d%s%d+$", "")
local is_available = ARG:gsub("^%d%s", ""):gsub("%s%d+$", "")
local seconds_to_next = ARG:gsub("^%d%s%d%s", "")

local function showRewards()
	function TBMenu:addBottomBloodSmudge() end
	TBMenu:getTranslation(get_language())

	TB_MENU_PLAYER_INFO = {}
	TB_MENU_PLAYER_INFO.username = PlayerInfo:getUser()
	TB_MENU_PLAYER_INFO.data = PlayerInfo:getUserData()

	TBMenu.MenuMain = UIElement:new({
		globalid = 1105,
		pos = { WIN_W / 10, WIN_H / 7 },
		size = { WIN_W / 10 * 8, WIN_H / 7 * 5 },
	})
	local navBarBG = UIElement:new({
		parent = TBMenu.MenuMain,
		pos = { 0, 0 },
		size = { TBMenu.MenuMain.size.w, 30 },
		bgColor = { 0, 0, 0, 0.95 }
	})
	TBMenu.NavigationBar = UIElement:new({
		parent = navBarBG,
		pos = { 0, 0 },
		size = { navBarBG.size.w, navBarBG.size.h }
	})

	TBMenu.CurrentSection = UIElement:new({
		parent = TBMenu.MenuMain,
		pos = { 0, navBarBG.size.h },
		size = { TBMenu.MenuMain.size.w, TBMenu.MenuMain.size.h - navBarBG.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})

	if (Notifications:showLoginRewards() == 0) then
		local startTime = os.time()
		TBMenu.CurrentSection:addCustomDisplay(false, function()
				TBMenu.CurrentSection:uiText("Updating data" .. string.rep(".", os.time() - startTime % 4, nil), nil, nil, FONTS.BIG)
				if (Notifications:showLoginRewards() ~= 0) then
					TBMenu.CurrentSection:addCustomDisplay(false, function() end)
				end
			end)
	end
	TBMenu:showNavigationBar({
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONEXIT,
			action = function() remove_hooks("tbMainMenuVisual") TBMenu.MenuMain:kill() end,
			width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONEXIT, FONTS.BIG) * 0.65 + 30
		}
	}, true)

	add_hook("draw2d", "tbMainMenuVisual", function() UIElement:drawVisuals(1105) end)
end

if (is_available == "1") then
	TB_STORE_DATA = Torishop:getItems()
	if (TB_STORE_DATA.failed) then
		add_hook("draw2d", "tbRewardsStoreWait", function()
				TB_STORE_DATA = Torishop:getItems()
				if (not TB_STORE_DATA.failed) then
					TB_STORE_DATA.ready = true
					remove_hooks("tbRewardsStoreWait")
					showRewards()
				end
			end)
	else
		TB_STORE_DATA.ready = true
		showRewards()
	end
end
