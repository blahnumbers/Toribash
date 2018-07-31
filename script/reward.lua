-- daily login rewards script
-- made by sir

dofile("system/menu_manager.lua")
dofile("system/rewards_manager.lua")
dofile("system/store_manager.lua")
dofile("system/player_info.lua")
dofile("toriui/uielement.lua")

if (ARG1 == '') then
	return
end

local days_cons = ARG1:gsub("%s%d%s%d+$", "")
local is_available = ARG1:gsub("^%d%s", ""):gsub("%s%d+$", "")
local seconds_to_next = ARG1:gsub("^%d%s%d%s", "")

TB_STORE_DATA = Torishop:getItems()
if (TB_STORE_DATA) then
	TB_STORE_DATA.ready = true
else 
	return
end

if (is_available == "1") then
	TB_MENU_NOTIFICATIONS_COUNT = 1
	TBMenu:create()
	function TBMenu:addBottomBloodSmudge() end
	TBMenu:getTranslation(get_language())
	
	TB_MENU_PLAYER_INFO = {}
	TB_MENU_PLAYER_INFO.username = PlayerInfo:getUser()
	TB_MENU_PLAYER_INFO.data = PlayerInfo:getUserData()
	
	tbMenuMain = UIElement:new({
		pos = { WIN_W / 8, WIN_H / 5 },
		size = { WIN_W / 8 * 6, WIN_H / 5 * 3 },
	})
	local navBarBG = UIElement:new({
		parent = tbMenuMain,
		pos = { 0, 0 },
		size = { tbMenuMain.size.w, 50 },
		bgColor = { 0, 0, 0, 0.95 }
	})
	tbMenuNavigationBar = UIElement:new({
		parent = navBarBG,
		pos = { 0, 0 },
		size = { navBarBG.size.w, navBarBG.size.h }
	})
	
	tbMenuCurrentSection = UIElement:new({
		parent = tbMenuMain,
		pos = { 0, 50 },
		size = { tbMenuMain.size.w, tbMenuMain.size.h - 50 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	
	TB_MENU_MAIN_ISOPEN = 0
	if (TBMenu:showLoginRewards() == 0) then
		local startTime = os.time()
		tbMenuCurrentSection:addCustomDisplay(false, function()
				tbMenuCurrentSection:uiText("Updating data" .. string.rep(".", os.time() - startTime % 4, nil), nil, nil, FONTS.BIG)
				if (TBMenu:showLoginRewards() ~= 0) then
					tbMenuCurrentSection:addCustomDisplay(false, function() end)
				end
			end)
	end

	add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y) UIElement:handleMouseDn(s, x, y) end)
	add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
	add_hook("mouse_move", "uiMouseHandler", function(x, y) UIElement:handleMouseHover(x, y) end)
	add_hook("draw2d", "tbMainMenuVisual", function() TBMenu:drawVisuals() end)
end