require("toriui.uielement")
require("system.menu_manager")
require("system.ignore_manager")

---@class TBHudButton
---@field button UIElement
---@field shouldBeDisplayed function

---@class ChatMessage
---@field text string
---@field tab integer
---@field clock number

if (TBHud == nil) then
	---Touch HUD class
	---@class TBHud
	---@field MainElement UIElement
	---@field ChatHolder UIElement
	---@field ChatMessages ChatMessage[]
	---@field ChatSize UIElementSize
	---@field WorldState WorldState Cached WorldState instance, updated every frame
	---@field ButtonsToRefresh TBHudButton[]
	---@field DefaultButtonColor Color
	---@field DefaultButtonSize number
	---@field DefaultSmallerButtonSize number
	---@field ver number
	TBHud = {
		MainElement = nil,
		ChatHolder = nil,
		ChatMessages = {},
		ChatSize = { w = 0, h = 0},
		WorldState = nil,
		ButtonsToRefresh = {},
		DefaultButtonSize = nil,
		DeafultSmallerButtonSize = nil,
		DefaultButtonColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
		ver = 1.0,
		__index = {}
	}
	setmetatable({}, TBHud)
end

---Internal subclass for **TBHud** that holds utility functions we won't need elsewhere
---@class TBHudInternal
local TBHudInternal = {}
setmetatable({}, TBHudInternal)

---Generates a default button for touch interface
---@param holder UIElement
---@param icon ?string
---@return UIElement
function TBHudInternal.generateTouchButton(holder, icon)
	local touchButton = holder:addChild({
		shift = { 0, 0 },
		interactive = true,
		bgImage = "../textures/menu/general/buttons/hudtouchbutton.tga",
		imageColor = TBHud.DefaultButtonColor,
		imagePressedColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
	})
	if (icon ~= nil) then
		local buttonIcon = touchButton:addChild({
			shift = { 0, 0 },
			bgImage = icon,
			imageColor = TB_MENU_DEFAULT_BG_COLOR,
		})
		buttonIcon:addCustomDisplay(function()
			if (touchButton.hoverState == BTN_DN) then
				buttonIcon.imageColor = UICOLORWHITE
			else
				buttonIcon.imageColor = TB_MENU_DEFAULT_BG_COLOR
			end
		end, true)
	end

	return touchButton
end

---Checks whether current player is participating in a fight
---@return boolean
function TBHudInternal.isPlaying()
	if (TBHud.WorldState.game_type == 0) then
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
	TBHud.MainElement:addCustomDisplay(true, function()
		TBHud.WorldState = get_world_state()
	end)

	TBHud.ChatSize.w = WIN_W * 0.4 > 400 and 400 or WIN_W * 0.4
	TBHud.ChatSize.h = WIN_H
	TBHud:spawnChat()

	TBHud.ButtonsToRefresh = {}
	TBHud.DefaultButtonSize = math.max(100, WIN_H / 10)
	TBHud.DefaultSmallerButtonSize = TBHud.DefaultButtonSize * 0.7

	TBHud:spawnCommitButton()
	TBHud:spawnGhostButon()
	TBHud:spawnOptionsButton()
	TBHud:spawnChatButton()
end

function TBHud:refreshButtons()
	for _, v in pairs(TBHud.ButtonsToRefresh) do
		if (v.shouldBeDisplayed()) then
			if (not v.button:isDisplayed()) then
				v.button:show()
			end
		elseif (v.button:isDisplayed()) then
			v.button:hide()
		end
	end
end

function TBHud:spawnCommitButton()
	if (TBHud.MainElement == nil) then return end

	local commitStepButtonHolder = TBHud.MainElement:addChild({
		pos = { -TBHud.DefaultButtonSize * 2.2, -TBHud.DefaultButtonSize * 1.5 },
		size = { TBHud.DefaultButtonSize, TBHud.DefaultButtonSize }
	})
	local commitStepButton = TBHudInternal.generateTouchButton(commitStepButtonHolder)
	commitStepButton:addMouseUpHandler(function() step_game() end)

	local commitStepButtonText = commitStepButton:addChild({
		shift = { commitStepButton.size.w / 6, commitStepButton.size.h / 2.6 },
		shapeType = ROUNDED,
		rounded = 4,
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	commitStepButtonText:addAdaptedText("Ready", nil, nil, 4, nil, 0.5)

	-- This button shouldn't always be available, attach a handler for it
	table.insert(TBHud.ButtonsToRefresh, {
		button = commitStepButtonHolder,
		shouldBeDisplayed = TBHudInternal.isPlaying
	})
end

function TBHud:spawnGhostButon()
	if (TBHud.MainElement == nil) then return end

	local ghostButtonHolder = TBHud.MainElement:addChild({
		pos = { -TBHud.DefaultButtonSize * 3.1, -TBHud.DefaultSmallerButtonSize * 1.5 },
		size = { TBHud.DefaultSmallerButtonSize, TBHud.DefaultSmallerButtonSize }
	})
	local ghostButton = TBHudInternal.generateTouchButton(ghostButtonHolder, "../textures/menu/general/buttons/ghost.tga")

	ghostButtonHolder:addCustomDisplay(true, function()
		local shouldBeDisplayed = TBHud.WorldState.replay_mode == 0
		if (shouldBeDisplayed and not ghostButton:isDisplayed()) then
			ghostButton:show()
		elseif (not shouldBeDisplayed and ghostButton:isDisplayed()) then
			ghostButton:hide()
		end
	end)
	ghostButton:addMouseUpHandler(function()
			set_ghost((get_ghost() + 1) % 3)
		end)
end

function TBHud:spawnOptionsButton()
	if (TBHud.MainElement == nil) then return end

	local settingsButtonHolder = TBHud.MainElement:addChild({
		pos = { -TBHud.DefaultSmallerButtonSize * 1.4, -TBHud.DefaultSmallerButtonSize * 1.5 },
		size = { TBHud.DefaultSmallerButtonSize, TBHud.DefaultSmallerButtonSize }
	})
	local settingsButton = TBHudInternal.generateTouchButton(settingsButtonHolder, "../textures/menu/general/buttons/options.tga")
end

---Method that handles all incoming chat messages and pushes them for display
---@param msg string
---@param type integer
---@param tab integer
function TBHud:pushChatMessage(msg, type, tab)
	local message = get_option("chatcensor") % 2 == 1 and ChatIgnore:filterInput(msg) or msg
	table.insert(TBHud.ChatMessages, {
		text = message,
		tab = tab,
		clock = os.clock()
	})

	if (TBHud.ChatHolder:isDisplayed()) then
		TBHud:refreshChat()
	end
end

function TBHud:spawnChatButton()
	if (TBHud.MainElement == nil) then return end

	local chatButtonHolder = TBHud.MainElement:addChild({
		pos = { TBHud.DefaultSmallerButtonSize * 0.4, -TBHud.DefaultSmallerButtonSize * 1.5 },
		size = { TBHud.DefaultSmallerButtonSize, TBHud.DefaultSmallerButtonSize }
	})
	local chatButton = TBHudInternal.generateTouchButton(chatButtonHolder, "../textures/menu/general/buttons/chat.tga")

	chatButton:addMouseUpHandler(function()
		TBHud:toggleChat(true)
	end)
end

function TBHud:refreshChat()
	TBHud.ChatHolder:kill(true)

	local chatMessagesHolder = TBHud.ChatHolder:addChild({
		pos = { 15, -TBHud.ChatSize.h },
		size = { TBHud.ChatSize.w, TBHud.ChatSize.h },
		bgColor = table.clone(UICOLORWHITE),
		uiColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	chatMessagesHolder.bgColor[4] = 0.7
	local elementHeight = 18
	local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(chatMessagesHolder, 30, 150, 16, { 0, 0, 0, 0 })

	local listElements = {}
	for _, message in pairs(TBHud.ChatMessages) do
		local messageStrings = textAdapt(message.text, FONTS.SMALL, 1, listingHolder.size.w)
		for _, string in pairs(messageStrings) do
			local chatMessage = listingHolder:addChild({
				pos = { 16, #listElements * elementHeight },
				size = { listingHolder.size.w - 32, elementHeight }
			})
			chatMessage:addAdaptedText(true, string, nil, nil, FONTS.SMALL, LEFT, 1, 1)
			table.insert(listElements, chatMessage)
		end
	end

	if (#listElements * elementHeight > listingHolder.size.h) then
		for i,v in pairs(listElements) do
			v:hide()
		end

		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
	end

	local chatInputField = TBMenu:spawnTextField2(botBar, { x = 20, y = botBar.size.h - 60, w = botBar.size.w - 40, h = 40 })
	chatInputField:addEnterAction(function()
			runCmd(chatInputField.textfieldstr[1], true)
			chatInputField:clearTextfield()
		end)
end

function TBHud:toggleChat(state)
	if (state == true) then
		TBHud.ChatHolder:show()
		TBHud:refreshChat()
	end

	local clock = os.clock()
	TBHud.ChatHolder:addCustomDisplay(true, function()
		local tweenValue = UITween.SineEaseIn((os.clock() - clock) * 6)
		TBHud.ChatHolder:moveTo(nil, state and TBHud.ChatHolder.size.h - tweenValue * TBHud.ChatHolder.size.h or tweenValue * TBHud.ChatHolder.size.h)

		if (tweenValue == 1) then
			if (state == false) then
				TBHud.ChatHolder:hide()
			else
				TBHud.ChatHolder:addCustomDisplay(true, function() end)
			end
		end
	end)
end

function TBHud:spawnChat()
	if (TBHud.MainElement == nil) then return end

	set_option("chat", 0)
	if (TBHud.ChatHolder ~= nil) then
		TBHud.ChatHolder:kill()
	end
	TBHud.ChatHolder = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { TBHud.MainElement.pos.x, TBHud.MainElement.pos.y + TBHud.MainElement.size.h },
		size = { TBHud.MainElement.size.w, TBHud.MainElement.size.h },
		interactive = true
	})
	TBHud.ChatHolder:addMouseUpHandler(function() TBHud:toggleChat(false) end)
	TBHud:refreshChat()
end

add_hook("resolution_changed", "tbHudTouchInterface", function() TBHud:init() end)
add_hook("new_game", "tbHudTouchInterface", function() TBHud:refreshButtons() end)
add_hook("console_post", "tbHudChatInterface", function(msg, type, tab)
	TBHud:pushChatMessage(msg, type, tab)
end)
