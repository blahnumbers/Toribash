_G.MENU_VERSION = 250411

--These used to be in menu_manager.lua

ORIENTATION_PORTRAIT = 1
ORIENTATION_LANDSCAPE = 2
ORIENTATION_LANDSCAPE_SHORTER = 3
TB_MENU_LANGUAGE = TB_MENU_LANGUAGE or nil
TB_MENU_LOCALIZED = TB_MENU_LOCALIZED or {}
TB_MENU_IGNORE_REWARDS = 0

-- Menu UI defines

TB_MENU_HUB_GLOBALID = 1000
TB_MENU_MAIN_GLOBALID = 1001
TB_ATMOSPHERES_GLOBALID = 1002
TB_TUTORIAL_MODERN_GLOBALID = 1003
TB_TOOLTIP_GLOBALID = 1010
TB_MOVEMEMORY_GLOBALID = 1011
TB_QUEUELIST_GLOBALID = 1012


-- Colors

TB_MENU_DEFAULT_BG_COLOR = { 0.67, 0.11, 0.11, 1 }
TB_MENU_DEFAULT_BG_COLOR_TRANS = { 0.67, 0.11, 0.11, 0.5 }
TB_MENU_DEFAULT_DARKER_COLOR = { 0.607, 0.109, 0.109, 1 }
TB_MENU_DEFAULT_DARKEST_COLOR = { 0.55, 0.05, 0.05, 1 }
TB_MENU_DEFAULT_LIGHTER_COLOR = { 0.8, 0.25, 0.25, 1 }
TB_MENU_DEFAULT_LIGHTEST_COLOR = { 0.9, 0.62, 0.62, 1 }
TB_MENU_DEFAULT_YELLOW = { 0.973, 0.886, 0.247, 1 }
TB_MENU_DEFAULT_ORANGE = { 0.965, 0.725, 0.172, 1 }
TB_MENU_DEFAULT_DARKER_ORANGE = { 0.965, 0.606, 0.109, 1 }
TB_MENU_DEFAULT_DARKEST_ORANGE = { 0.851, 0.508, 0.034, 1 }
TB_MENU_DEFAULT_BLUE = { 0.242, 0.626, 1, 1 }
TB_MENU_DEFAULT_DARKER_BLUE = { 0.159, 0.54, 0.91, 1 }
TB_MENU_DEFAULT_DARKEST_BLUE = { 0.089, 0.418, 0.701, 1 }
TB_MENU_DEFAULT_INACTIVE_COLOR = { 0.8, 0.8, 0.8, 1 }
TB_MENU_DEFAULT_INACTIVE_COLOR_DARK = { 0.635, 0.353, 0.353, 1 }
TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS = { 0.6, 0.6, 0.6, 0.5 }

TB_MENU_UI_TEXT_COLOR = { 1, 1, 1, 1 }
TB_MENU_UI_TEXT_SHADOW_COLOR = { 0, 0, 0, 0.6 }


-- Textures

TB_MENU_GAME_LOGO = "../textures/menu/logos/toribash_modern_small.tga"
TB_MENU_GAME_LOGO_BIG = "../textures/menu/logos/toribash_modern.tga"
TB_MENU_GAME_TITLE = "../textures/menu/logos/toribashgametitle_modern.tga"
TB_MENU_USERBAR_MAIN = "../textures/menu/general/topbarbgmain.tga"
TB_MENU_USERBAR_WIDE = "../textures/menu/general/topbarbgmainwide.tga"
TB_MENU_USERBAR_LEFT = "../textures/menu/general/topbarbgleft.tga"
TB_MENU_BLOODSPLATTER_LEFT = "../textures/menu/general/bloodsplatleft.tga"
TB_MENU_BLOODSPLATTER_RIGHT = "../textures/menu/general/bloodsplatright.tga"
TB_MENU_BOTTOM_SMUDGE_BIG = "../textures/menu/general/bottomsmudgebig.tga"
TB_MENU_BOTTOM_SMUDGE_MEDIUM1 = "../textures/menu/general/bottomsmudgemedium1.tga"
TB_MENU_BOTTOM_SMUDGE_MEDIUM2 = "../textures/menu/general/bottomsmudgemedium2.tga"

-- Buttons

TB_MENU_QUIT_BUTTON = "../textures/menu/general/buttons/quit.tga"
TB_MENU_QUIT_BUTTON_HOVER = "../textures/menu/general/buttons/quithover.tga"
TB_MENU_QUIT_BUTTON_PRESS = "../textures/menu/general/buttons/quitpress.tga"
TB_MENU_SETTINGS_BUTTON = "../textures/menu/general/buttons/settings.tga"
TB_MENU_SETTINGS_BUTTON_HOVER = "../textures/menu/general/buttons/settingsredhover.tga"
TB_MENU_SETTINGS_BUTTON_PRESS = "../textures/menu/general/buttons/settingsredpress.tga"
TB_MENU_FRIENDS_BUTTON = "../textures/menu/general/buttons/friends.tga"
TB_MENU_FRIENDS_BUTTON_HOVER = "../textures/menu/general/buttons/friendshover.tga"
TB_MENU_FRIENDS_BUTTON_PRESS = "../textures/menu/general/buttons/friendspress.tga"
TB_MENU_NOTIFICATIONS_BUTTON = "../textures/menu/general/buttons/notifications.tga"
TB_MENU_NOTIFICATIONS_BUTTON_HOVER = "../textures/menu/general/buttons/notificationshover.tga"
TB_MENU_NOTIFICATIONS_BUTTON_PRESS = "../textures/menu/general/buttons/notificationspress.tga"
TB_MENU_DISCORD_BUTTON = "../textures/menu/general/buttons/discord.tga"
TB_MENU_DISCORD_BUTTON_HOVER = "../textures/menu/general/buttons/discordredhover.tga"
TB_MENU_DISCORD_BUTTON_PRESS = "../textures/menu/general/buttons/discordredpress.tga"
TB_MENU_LOGOUT_BUTTON = "../textures/menu/general/buttons/logout.tga"
TB_MENU_LOGOUT_BUTTON_HOVER = "../textures/menu/general/buttons/logouthover.tga"
TB_MENU_LOGOUT_BUTTON_PRESS = "../textures/menu/general/buttons/logoutpressed.tga"
TB_MENU_BOUNTY_BUTTON = "../textures/menu/general/buttons/bounty.tga"
TB_MENU_BOUNTY_BUTTON_HOVER = "../textures/menu/general/buttons/bountyredhover.tga"
TB_MENU_BOUNTY_BUTTON_PRESS = "../textures/menu/general/buttons/bountyredpress.tga"

TB_MENU_CLANFILTERS_BUTTON = "../textures/menu/general/buttons/clanfilters.tga"
TB_MENU_CLANFILTERS_BUTTON_HOVER = "../textures/menu/general/buttons/clanfiltershover.tga"
TB_MENU_CLANFILTERS_BUTTON_PRESS = "../textures/menu/general/buttons/clanfilterspressed.tga"

TB_MENU_BUTTON_CROSSWHITE = "../textures/menu/general/buttons/crosswhite.tga"

local overrideActive = false

local function setDefinesOverrides()
	TB_MENU_DEFAULT_BG_COLOR = { 0.15, 0.15, 0.15, 1 }
	TB_MENU_DEFAULT_BG_COLOR_TRANS = { 0.15, 0.15, 0.15, 0.5 }
	TB_MENU_DEFAULT_DARKER_COLOR = { 0.1, 0.1, 0.1, 1 }
	TB_MENU_DEFAULT_DARKEST_COLOR = { 0.06, 0.06, 0.06, 1 }
	--TB_NAVBAR_DEFAULT_BG_COLOR = { 0.835, 0.576, 0.349, 1 }
	TB_MENU_DEFAULT_LIGHTER_COLOR = { 0.2, 0.2, 0.20, 1 }
	TB_MENU_DEFAULT_LIGHTEST_COLOR = { 0.25, 0.25, 0.25, 1 }

	TB_MENU_UI_TEXT_COLOR = { 1, 1, 1, 1 }
	TB_MENU_UI_TEXT_SHADOW_COLOR = { 0, 0, 0, 0.6 }

	--[[TB_MENU_GAME_LOGO = "../textures/menu/logos/toribash_halloween_small.tga"
	TB_MENU_USERBAR_MAIN = "../textures/menu/general/topbarbgmain_halloween.tga"
	TB_MENU_USERBAR_LEFT = "../textures/menu/general/topbarbgleft_halloween.tga"
	TB_MENU_BLOODSPLATTER_LEFT = "../textures/menu/general/batsleft_halloween.tga"
	TB_MENU_BLOODSPLATTER_RIGHT = "../textures/menu/general/batsright_halloween.tga"
	TB_MENU_BOTTOM_SMUDGE_BIG = "../textures/menu/general/bottomsmudgebighalloween.tga"
	TB_MENU_BOTTOM_SMUDGE_MEDIUM1 = "../textures/menu/general/bottomsmudgemedium1halloween.tga"
	TB_MENU_BOTTOM_SMUDGE_MEDIUM2 = "../textures/menu/general/bottomsmudgemedium2halloween.tga"

	TB_MENU_QUIT_BUTTON = "../textures/menu/general/buttons/halloween/quit.tga"
	TB_MENU_QUIT_BUTTON_HOVER = "../textures/menu/general/buttons/halloween/quithover.tga"
	TB_MENU_QUIT_BUTTON_PRESS = "../textures/menu/general/buttons/halloween/quitpress.tga"
	TB_MENU_SETTINGS_BUTTON = "../textures/menu/general/buttons/halloween/settings.tga"
	TB_MENU_SETTINGS_BUTTON_HOVER = "../textures/menu/general/buttons/halloween/settingshover.tga"
	TB_MENU_SETTINGS_BUTTON_PRESS = "../textures/menu/general/buttons/halloween/settingspress.tga"
	TB_MENU_FRIENDS_BUTTON = "../textures/menu/general/buttons/halloween/friends.tga"
	TB_MENU_FRIENDS_BUTTON_HOVER = "../textures/menu/general/buttons/halloween/friendshover.tga"
	TB_MENU_FRIENDS_BUTTON_PRESS = "../textures/menu/general/buttons/halloween/friendspress.tga"
	TB_MENU_NOTIFICATIONS_BUTTON = "../textures/menu/general/buttons/halloween/notifications.tga"
	TB_MENU_NOTIFICATIONS_BUTTON_HOVER = "../textures/menu/general/buttons/halloween/notificationshover.tga"
	TB_MENU_NOTIFICATIONS_BUTTON_PRESS = "../textures/menu/general/buttons/halloween/notificationspress.tga"
	TB_MENU_DISCORD_BUTTON = "../textures/menu/general/buttons/halloween/discord.tga"
	TB_MENU_DISCORD_BUTTON_HOVER = "../textures/menu/general/buttons/halloween/discordhover.tga"
	TB_MENU_DISCORD_BUTTON_PRESS = "../textures/menu/general/buttons/halloween/discordpress.tga"
	--TB_MENU_LOGOUT_BUTTON = "../textures/menu/general/buttons/halloween/logout.tga"
	--TB_MENU_LOGOUT_BUTTON_HOVER = "../textures/menu/general/buttons/halloween/logouthover.tga"
	--TB_MENU_LOGOUT_BUTTON_PRESS = "../textures/menu/general/buttons/halloween/logoutpressed.tga"

	TB_MENU_CLANFILTERS_BUTTON_HOVER = "../textures/menu/general/buttons/halloween/clanfiltershover.tga"
	TB_MENU_CLANFILTERS_BUTTON_PRESS = "../textures/menu/general/buttons/halloween/clanfilterspressed.tga"]]
end

if (overrideActive) then
	setDefinesOverrides()
end
