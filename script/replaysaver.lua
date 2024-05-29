require("toriui.uielement")
local startClock = -60
local replayName = ARG:len() > 0 and ARG or "autosave"
local currentFrame = -1

local replaySaveOverlay = UIElement.new({
	pos = { WIN_W - 300, WIN_H - 25 },
	size = { 300, 25 },
	bgColor = TB_MENU_DEFAULT_BG_COLOR,
	shapeType = ROUNDED,
	rounded = 3
})
replaySaveOverlay:addChild({ shift = { 30, 2 } }):addAdaptedText(false, "Auto Replay Saver: On")
local infoButton = replaySaveOverlay:addChild({
	pos = { 2, 0 },
	size = { replaySaveOverlay.size.h, replaySaveOverlay.size.h },
	interactive = true,
	bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
	hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
	rounded = replaySaveOverlay.size.h
}, true)
local popup = TBMenu:displayHelpPopup(infoButton, "Current replay will be automatically saved as \"my replays\\" .. replayName .. "\" every minute with the date appended at the end")
if (popup ~= nil) then
	popup:moveTo(nil, -infoButton.size.h - popup.size.h - 5)
end
local replayQuitButton = replaySaveOverlay:addChild({
	pos = { -replaySaveOverlay.size.h, 0 },
	size = { replaySaveOverlay.size.h, replaySaveOverlay.size.h },
	interactive = true,
	bgColor = UICOLORRED,
	hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
	pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
})
local replayQuitIcon = replayQuitButton:addChild({
	shift = { 5, 5 },
	bgImage = "../textures/menu/general/buttons/crosswhite.tga"
})
replayQuitButton:addMouseHandlers(nil, function()
		replaySaveOverlay:kill()
	end)
replayQuitIcon:addCustomDisplay(false, function()
		if (startClock + 60 < UIElement.clock) then
			startClock = UIElement.clock
			local frame = get_world_state().match_frame
			if (currentFrame ~= frame) then
				currentFrame = frame
				runCmd("savereplay " .. replayName .. "-" .. os.date("%y%m%d-%I%p"), false, CMD_ECHO_FORCE_DISABLED)
			end
		end
	end)
