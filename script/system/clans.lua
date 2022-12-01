-- clans view script
-- made by sir
CLANLISTLASTPOS = { scroll = {}, list = {} }
TB_MENU_DEFAULT_BG_COLOR = { 0.67, 0.11, 0.11, 1 }
TB_MENU_DEFAULT_DARKER_COLOR = { 0.607, 0.109, 0.109, 1 }

dofile("system/menu_manager.lua")
dofile("system/clans_manager.lua")
dofile("system/player_info.lua")
dofile("toriui/uielement.lua")

if (TBMenu.MenuMain) then
	TBMenu.MenuMain:kill()
end

TB_MENU_PLAYER_INFO = {}
TB_MENU_PLAYER_INFO.username = PlayerInfo:getUser()
TB_MENU_PLAYER_INFO.clan = PlayerInfo:getClan(TB_MENU_PLAYER_INFO.username)

TBMenu:open()
function TBMenu:addBottomBloodSmudge() end
TBMenu:getTranslation(get_language())

if (not Clans:getLevelData() or not Clans:getAchievementData() or not Clans:getClanData()) then
	return
end

TBMenu.MenuMain = UIElement:new({
	globalid = 1101,
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

local clanId = nil
if (ARG ~= "") then
	local clanTag = PlayerInfo:getClanTag(ARG)
	for i,v in pairs(ClanData) do
		if (v.tag == clanTag) then
			clanId = v.id
			break
		end
	end
end

if (clanId) then
	Clans:showClan(TBMenu.CurrentSection, clanId)
else
	Clans:showMain(TBMenu.CurrentSection)
end


add_hook("draw2d", "tbMainMenuVisual", function() UIElement:drawVisuals(1101) end)
add_hook("draw_viewport", "tbMainMenuVisual", function() UIElement:drawViewport(1101) end)
