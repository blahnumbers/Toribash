require("toriui/uielement")
local startClock = os.clock()
local replayName = ARG1:len() > 0 and ARG1 or "mytempreplay"

local replaySaveOverlay = UIElement:new({
	pos = { WIN_W / 3, WIN_H - 40 },
	size = { WIN_W / 3 - 40, 40 },
	bgColor = TB_MENU_DEFAULT_BG_COLOR
})
replaySaveOverlay:addAdaptedText(false, "Auto Replay Saver")
local replayQuitButton = UIElement:new({
	parent = replaySaveOverlay,
	pos = { replaySaveOverlay.size.w, 0 },
	size = { 40, 40 },
	interactive = true,
	bgColor = UICOLORRED,
	hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
	pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
})
local replayQuitIcon = UIElement:new({
	parent = replayQuitButton,
	pos = { 5, 5 },
	size = { replayQuitButton.size.w - 10, replayQuitButton.size.h - 10 },
	bgImage = "../textures/menu/general/buttons/crosswhite.tga"
})
replayQuitButton:addMouseHandlers(nil, function()
		replaySaveOverlay:kill()
		remove_hooks("replaySaver")
	end)
replayQuitIcon:addCustomDisplay(false, function()
		if (startClock + 10 < os.clock()) then
			startClock = os.clock()
			UIElement:runCmd("savereplay " .. replayName)
		end
	end)
	
add_hook("mouse_move", "replaySaver", function(x, y) UIElement:handleMouseHover(x, y) end)
add_hook("key_up", "replaySaver", function(s) UIElement:handleKeyUp(s) end)
add_hook("key_down", "replaySaver", function(s) UIElement:handleKeyDown(s) end)
add_hook("draw2d", "replaySaver", function()
		for i, v in pairs(UIElementManager) do
			v:updatePos()
		end
		for i, v in pairs(UIVisualManager) do
			v:display()
		end
	end)
