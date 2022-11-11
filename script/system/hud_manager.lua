-- Mobile HUD manager class

if (TBHud == nil) then
	---Touch HUD class
	---@class TBHud
	---@field MainElement UIElement
	---@field DefaultButtonColor Color
	---@field DefaultButtonSize number
	---@field DefaultSmallerButtonSize number
	---@field ver number
	TBHud = {
		MainElement = nil,
		DefaultButtonSize = nil,
		DeafultSmallerButtonSize = nil,
		DefaultButtonColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
		ver = 1.0,
		__index = {}
	}
	TBHud.DefaultButtonColor[4] = 0.05
	setmetatable({}, TBHud)
end

---Internal subclass for TBHud that holds utility functions we won't need elsewhere
---@class TBHudInternal
local TBHudInternal = {}
setmetatable({}, TBHudInternal)

---Adds a 2-pixel-wide outline to the round button
---@param button UIElement
function TBHudInternal.addButtonOutline(button)
	button:addCustomDisplay(function()
		set_color(unpack(TB_MENU_DEFAULT_BG_COLOR_TRANS))
		draw_disk(button.pos.x + button.size.w / 2, button.pos.y + button.size.h / 2, button.size.w / 2 - 2, button.size.w / 2, 50, 1, 0, 360, 0)
	end)
end

---Checks whether current player is participating in a fight
---@return boolean
function TBHudInternal.isPlaying()
	if (get_world_state().game_type == 0) then
		return true
	end
	local user = PlayerInfo:getUser()
	local tori = PlayerInfo:getUser(get_player_info(0).name)
	local uke = PlayerInfo:getUser(get_player_info(1).name)

	if (user == tori or user == uke) then
		return true
	end
	return false
end

function TBHud:init()
	if (TBHud.MainElement ~= nil) then
		TBHud.MainElement:kill()
	end

	local x, y, w, h = get_window_safe_size()
	if (PLATFORM == "WINDOWS") then
		x = 0
		y = 0
		w = WIN_W
		h = WIN_H
	else
		echo("Safe zone: " .. x .. " " .. y .. " " .. w .. " " .. h)
	end
	TBHud.MainElement = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { x, y },
		size = { w, h }
	})

	TBHud.DefaultButtonSize = math.max(100, WIN_H / 10)
	TBHud.DefaultSmallerButtonSize = TBHud.DefaultButtonSize * 0.7

	if (TBHudInternal.isPlaying()) then
		TBHud:spawnCommitButton()
	end
	TBHud:spawnGhostButon()
	TBHud:spawnSettings()
	TBHud:spawnChat()
end

function TBHud:spawnCommitButton()
	if (TBHud.MainElement == nil) then return end

	local commitStepButton = TBHud.MainElement:addChild({
		pos = { -TBHud.DefaultButtonSize * 2.2, -TBHud.DefaultButtonSize * 1.5 },
		size = { TBHud.DefaultButtonSize, TBHud.DefaultButtonSize },
		shapeType = ROUNDED,
		rounded = TBHud.DefaultButtonSize,
		interactive = true,
		bgColor = TBHud.DefaultButtonColor,
		pressedColor = TB_MENU_DEFAULT_BG_COLOR_TRANS
	})
	commitStepButton:addMouseUpHandler(function() step_game() end)
	TBHudInternal.addButtonOutline(commitStepButton)

	local commitStepButtonText = commitStepButton:addChild({
		shift = { commitStepButton.size.w / 6, commitStepButton.size.h / 2.6 },
		shapeType = ROUNDED,
		rounded = 4,
		bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS
	})
	commitStepButtonText:addAdaptedText("Ready", nil, nil, 4, nil, 0.5)
end

function TBHud:spawnGhostButon()
	if (TBHud.MainElement == nil) then return end

	local ghostButton = TBHud.MainElement:addChild({
		pos = { -TBHud.DefaultButtonSize * 3.1, -TBHud.DefaultSmallerButtonSize * 1.5 },
		size = { TBHud.DefaultSmallerButtonSize, TBHud.DefaultSmallerButtonSize },
		shapeType = ROUNDED,
		rounded = TBHud.DefaultSmallerButtonSize,
		interactive = true,
		bgColor = TBHud.DefaultButtonColor,
		pressedColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		bgImage = "../textures/menu/general/buttons/ghost.tga",
		imageColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		imagePressedColor = UICOLORWHITE
	})
	TBHudInternal.addButtonOutline(ghostButton)
	ghostButton:addMouseUpHandler(function()
			set_ghost((get_ghost() + 1) % 3)
		end)
end

function TBHud:spawnSettings()
	if (TBHud.MainElement == nil) then return end

	local settingsButton = TBHud.MainElement:addChild({
		pos = { -TBHud.DefaultSmallerButtonSize * 1.4, -TBHud.DefaultSmallerButtonSize * 1.5 },
		size = { TBHud.DefaultSmallerButtonSize, TBHud.DefaultSmallerButtonSize },
		shapeType = ROUNDED,
		rounded = TBHud.DefaultSmallerButtonSize,
		interactive = true,
		bgColor = TBHud.DefaultButtonColor,
		pressedColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		bgImage = "../textures/menu/general/buttons/options.tga",
		imageColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		imagePressedColor = UICOLORWHITE
	})
	TBHudInternal.addButtonOutline(settingsButton)
end

function TBHud:spawnChat()
	if (TBHud.MainElement == nil) then return end

	local chatButton = TBHud.MainElement:addChild({
		pos = { TBHud.DefaultSmallerButtonSize * 0.4, -TBHud.DefaultSmallerButtonSize * 1.5 },
		size = { TBHud.DefaultSmallerButtonSize, TBHud.DefaultSmallerButtonSize },
		shapeType = ROUNDED,
		rounded = TBHud.DefaultSmallerButtonSize,
		interactive = true,
		bgColor = TBHud.DefaultButtonColor,
		pressedColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		bgImage = "../textures/menu/general/buttons/chat.tga",
		imageColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		imagePressedColor = UICOLORWHITE
	})
	TBHudInternal.addButtonOutline(chatButton)
end

add_hook("new_game", "tbHudTouchInterface", function() TBHud:init() end)
