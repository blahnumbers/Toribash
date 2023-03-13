require("toriui.uielement")
require("system.menu_manager")
require("system.ignore_manager")

---@class TBHudButton
---@field button UIElement
---@field shouldBeDisplayed function

---@class ChatMessage
---@field text string Message text string
---@field tab integer Chat tab the message should belong to
---@field clock number Timestamp of when the message was received
---@field adaptedTextMini string[] Adapted string for the mini chat
---@field textColorMini Color[] Cached text display color for mini chat
---@field lines integer Lines this message will take in regular chat

if (TBHud == nil) then
	---**Touch HUD class**
	---
	---**Version 5.60**
	--- - Base implementation for gameplay buttons (ready, ghost control, chat)
	---@class TBHud
	---@field MainElement UIElement
	---@field CommitStepButtonHolder UIElement
	---@field ChatButtonHolder UIElement
	---@field HoldAllButtonHolder UIElement
	---@field GhostButtonHolder UIElement
	---@field MiscButtonHolders UIElement[]
	---@field HubHolder UIElement
	---@field HubDynamicButtonsHolder UIElement
	---@field HubDynamicState WorldState
	---@field HubSize UIElementSize
	---@field ChatHolder UIElement
	---@field ChatMiniHolder UIElement
	---@field ChatSize UIElementSize
	---@field ChatMaxHistory integer Maximum number of messages that will be displayed in chat
	---@field ChatMiniMaxMessages integer Maximum number of messages that can be shown in mini chat at a time
	---@field ChatMiniDisplayPeriod number Maximum time in seconds that messages in mini chat will be displayed for
	---@field ChatMiniUpdateTime integer Last update time for mini chat
	---@field WorldState WorldState Cached WorldState instance, updated every frame
	---@field ButtonsToRefresh TBHudButton[]
	---@field DefaultButtonColor Color
	---@field DefaultButtonSize number
	---@field DefaultSmallerButtonSize number
	---@field RequiresChatRefresh boolean
	---@field ver number
	TBHud = {
		Globalid = 1013,
		HubGlobalid = 1014,
		HubSize = { w = 0, h = 0 },
		ChatSize = { w = 0, h = 0},
		ListShift = { 0 },
		ChatMaxHistory = 2000,
		ChatMiniMaxMessages = 10,
		ChatMiniDisplayPeriod = 20,
		ChatMiniUpdateTime = 0,
		ButtonsToRefresh = {},
		MiscButtonHolders = {},
		DefaultButtonSize = math.max(100, WIN_H / 10),
		DeafultSmallerButtonSize = nil,
		DefaultButtonColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
		RequiresChatRefresh = false,
		SafeAreaOffset = 0,
		ver = 5.60,
	}
	TBHud.__index = TBHud
	setmetatable({}, TBHud)

	TBHud.DefaultSmallerButtonSize = TBHud.DefaultButtonSize * 0.7
	TBHud.SafeAreaOffset = TBHud.DefaultButtonSize * 3
end

---Internal subclass for **TBHud** that holds utility functions we won't need elsewhere
---@class TBHudInternal
---@field ChatMessages ChatMessage[]
---@field ChatMessageHistory string[] User chat message history
---@field ChatMessageHistoryIndex integer
local TBHudInternal = {
	ChatMessages = {},
	ChatMessageHistory = {},
	ChatMessageHistoryIndex = -1
}
setmetatable({}, TBHudInternal)

---@class TBHudButton : UIElement
---@field icon UIElement

---Generates a default button for touch interface
---@param holder UIElement
---@param icon ?string
---@param atlasRect ?Rect
---@param imageScale ?number
---@return TBHudButton
function TBHudInternal.generateTouchButton(holder, icon, atlasRect, imageScale)
	local touchButton = holder:addChild({
		shift = { 0, 0 },
		interactive = true,
		bgImage = "../textures/menu/general/buttons/hudtouchbutton.tga",
		imageColor = TBHud.DefaultButtonColor,
		imagePressedColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		disableUnload = true
	})
	if (icon ~= nil) then
		local imageScale = imageScale or 1
		local shift = (touchButton.size.w - touchButton.size.w * imageScale) / 2
		local buttonIcon = touchButton:addChild({
			shift = { shift, shift },
			bgImage = icon,
			imageColor = TB_MENU_DEFAULT_BG_COLOR,
			imageAtlas = atlasRect ~= nil,
			---@diagnostic disable-next-line: assign-type-mismatch
			atlas = atlasRect
		})
		buttonIcon:addCustomDisplay(function()
			if (touchButton.hoverState == BTN_DN) then
				buttonIcon.imageColor = UICOLORWHITE
			else
				buttonIcon.imageColor = TB_MENU_DEFAULT_BG_COLOR
			end
		end, true)
		touchButton.icon = buttonIcon
	end

	---@diagnostic disable-next-line: return-type-mismatch
	return touchButton
end

---Checks whether current player is participating in a fight
---@return boolean
function TBHudInternal.isPlaying()
	if (TBHud.WorldState.game_type == 0) then
		return true
	end
	local user = PlayerInfo.Get().username
	local tori = PlayerInfo.Get(get_player_info(0).name).username
	local uke = PlayerInfo.Get(get_player_info(1).name).username

	if (user == tori or user == uke) then
		return true
	end
	return false
end

---Refreshes `TBHud.ButtonsToRefresh` elements' visibility state depending on their settings
function TBHudInternal.refreshButtons()
	TBHud.WorldState = get_world_state()
	for _, v in pairs(TBHud.ButtonsToRefresh) do
		if (v.shouldBeDisplayed()) then
			if (not v.button:isDisplayed()) then
				v.button:show()
			end
		elseif (v.button:isDisplayed()) then
			v.button:hide()
		end
	end
	TBHud:reloadHubDynamicButtons()
end

---Method that handles all incoming chat messages and pushes them for display
---@param msg string
---@param type ChatMessageType
---@param tab integer
function TBHudInternal.pushChatMessage(msg, type, tab)
	---Colorize first symbol if needed
	if (type > MSGTYPE.SERVER) then
		local match, matchEnd = utf8.find(msg, "(^?%%?%d+)>")
		if (match ~= nil) then
			msg = utf8.sub(msg, match, matchEnd - 1) .. msg
		end
	end

	local message = get_option("chatcensor") % 2 == 1 and ChatIgnore:filterInput(msg) or msg
	---@type ChatMessage
	local chatMessage = {
		text = message,
		tab = tab,
		clock = os.clock_real()
	}
	table.insert(TBHudInternal.ChatMessages, chatMessage)
	if (#TBHudInternal.ChatMessages > TBHud.ChatMaxHistory) then
		table.remove(TBHudInternal.ChatMessages, 1)
		if (TBHud.ChatHolderItems ~= nil) then
			TBHud.ChatHolderItems[1]:kill()
			table.remove(TBHud.ChatHolderItems, 1)
			for _, v in pairs(TBHud.ChatHolderItems) do
				v:moveTo(nil, -v.size.h, true)
			end
		end
	end

	if (TBHud.ChatHolder ~= nil and TBHud.ChatHolder:isDisplayed()) then
		TBHud:refreshChat()
	else
		for _, v in pairs(TBHud.ChatHolderItems) do
			v:hide()
		end
		TBHud.ChatMiniUpdateTime = 0
		TBHud.RequiresChatRefresh = true
	end
end

---Initializes HUD main elements
function TBHud:init()
	if (self.MainElement ~= nil) then
		return
	end

	self.MainElement = UIElement:new({
		globalid = self.Globalid,
		pos = { 0, 0 },
		size = { WIN_W, WIN_H }
	})
	self.MainElement:addCustomDisplay(true, function()
		self.WorldState = get_world_state()
	end)

	self.ButtonsToRefresh = {}

	set_option("feedback", 0)
	set_option("hint", 0)

	self:spawnCommitButton()
	self:spawnGhostButton()
	self:spawnHoldRelaxAllButton()
	self:spawnRewindButton()
	self:spawnPauseButton()

	self:spawnHubButton()
	self.HubSize.w = WIN_W * 0.3 > 400 and 400 or WIN_W * 0.3
	self.HubSize.h = WIN_H
	self:spawnHub()

	self:spawnChatButton()
	self.ChatSize.w = WIN_W * 0.4 > 600 and 600 or WIN_W * 0.4
	self.ChatSize.h = WIN_H
	self:spawnChat()

	TBHudInternal.refreshButtons()
end

function TBHud.Reload()
	if (TBHud.MainElement ~= nil) then
		TBHud.MainElement:kill()
		TBHud.MainElement = nil
		TBHud.ChatHolder = nil
		TBHud.ChatHolderItems = nil
		TBHud.ChatMiniHolder = nil
		TBHud.ChatHolderListing = nil
		TBHud.ChatHolderScrollBar = nil
		TBHud.ChatHolderToReload = nil
		TBHud.ChatHolderTopBar = nil
		TBHud.HubHolder = nil
		TBHud.CommitStepButtonHolder = nil
		TBHud.ChatButtonHolder = nil
		TBHud.HoldAllButtonHolder = nil
		TBHud.GhostButtonHolder = nil
		TBHud.MiscButtonHolders = { }
	end

	TBHud:init()
end

---Spawns commit turn / new game button and its corresponding longpress menu
function TBHud:spawnCommitButton()
	if (self.MainElement == nil) then return end

	local commitStepButtonHolder = self.MainElement:addChild({
		pos = { -self.DefaultButtonSize * 2.2, -self.DefaultButtonSize - self.DefaultSmallerButtonSize * 0.5 },
		size = { self.DefaultButtonSize, self.DefaultButtonSize }
	})
	self.CommitStepButtonHolder = commitStepButtonHolder
	local commitStepButton = TBHudInternal.generateTouchButton(commitStepButtonHolder)

	local clickClock = 0
	local stepSingleFrame = false
	commitStepButton:addMouseUpHandler(function()
		if (self.WorldState.replay_mode ~= 0) then
			start_new_game(true)
		else
			step_game(self.WorldState.game_type == 0 and stepSingleFrame)
		end
		clickClock = 0
	end)
	commitStepButton:addMouseDownHandler(function()
		if (self.WorldState.replay_mode == 0 and self.WorldState.game_type == 0) then
			clickClock = os.clock_real()
		end
	end)

	local commitStepButtonText = commitStepButton:addChild({
		shift = { commitStepButton.size.w / 6, commitStepButton.size.h / 2.6 },
		shapeType = ROUNDED,
		rounded = 4,
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	---@param text string
	local setCommitStepButtonText = function(text)
		commitStepButtonText.size.w = commitStepButton.size.w
		commitStepButtonText:addAdaptedText(text, nil, nil, 4, nil, 0.6)
		commitStepButtonText.size.w = math.min(commitStepButtonText.size.w, get_string_length(commitStepButtonText.dispstr[1], commitStepButtonText.textFont) * commitStepButtonText.textScale + 20)
		commitStepButtonText:moveTo((commitStepButton.size.w - commitStepButtonText.size.w) / 2)
	end
	setCommitStepButtonText(TB_MENU_LOCALIZED.MOBILEHUDREADY)

	commitStepButton:addCustomDisplay(function()
			if (self.WorldState.game_type == 0 and self.WorldState.replay_mode ~= 0) then
				if (commitStepButtonText.str ~= TB_MENU_LOCALIZED.MOBILEHUDNEWGAME) then
					setCommitStepButtonText(TB_MENU_LOCALIZED.MOBILEHUDNEWGAME)
				end
			elseif (commitStepButtonText.str ~= TB_MENU_LOCALIZED.MOBILEHUDREADY) then
				setCommitStepButtonText(TB_MENU_LOCALIZED.MOBILEHUDREADY)
			end
			if (clickClock > 0 and UIElement.clock - clickClock > UIElement.longPressDuration) then
				disable_mouse_camera_movement()
				play_haptics(0.2, HAPTICS.IMPACT)
				clickClock = 0
				local optionsHolder = commitStepButtonHolder:addChild({
					pos = { -commitStepButton.size.w * 1.8, -commitStepButton.size.h * 2 },
					size = { commitStepButton.size.w * 2.6, commitStepButton.size.h * 0.9 },
					bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
					shapeType = ROUNDED,
					rounded = 5
				})
				---Setup invisible element that would kill our object on mouse up event
				local optionsKiller = optionsHolder:addChild({
					pos = { -WIN_W * 2, -WIN_H * 2 },
					size = { WIN_W * 4, WIN_H * 4 },
					interactive = true
				})
				optionsKiller.hoverState = BTN_DN
				optionsKiller:addMouseUpHandler(function() optionsHolder:kill() enable_mouse_camera_movement() end)

				local stepSingleFrameButton = optionsHolder:addChild({
					pos = { 2, 2 },
					size = { optionsHolder.size.w - 4, (optionsHolder.size.h - 6) / 2 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					hoverThrough = true,
					clickThrough = true
				}, true)
				stepSingleFrameButton:addCustomDisplay(function()
					if (not (
						MOUSE_X >= stepSingleFrameButton.pos.x and MOUSE_X <= stepSingleFrameButton.pos.x + stepSingleFrameButton.size.w and
						MOUSE_Y >= stepSingleFrameButton.pos.y and MOUSE_Y <= stepSingleFrameButton.pos.y + stepSingleFrameButton.size.h)) then
						stepSingleFrameButton.hoverState = BTN_NONE
					end
				end, true)
				stepSingleFrameButton:addChild({
					shift = { 10, 3 }
				}):addAdaptedText(stepSingleFrame and TB_MENU_LOCALIZED.HUDSTEPFRAMEFULL or TB_MENU_LOCALIZED.HUDSTEPFRAMESINGLE, nil, nil, FONTS.LMEDIUM, nil, 0.7)
				stepSingleFrameButton:addMouseMoveHandler(function()
					if (stepSingleFrameButton.hoverState ~= BTN_DN) then
						play_haptics(0.6, HAPTICS.SELECTION)
					end
					stepSingleFrameButton.hoverState = BTN_DN
				end)
				stepSingleFrameButton:addMouseUpHandler(function()
					step_game(not stepSingleFrame)
				end)

				local stepSingleFrameButtonToggle = optionsHolder:addChild({
					pos = { stepSingleFrameButton.shift.x, stepSingleFrameButton.shift.y * 2 + stepSingleFrameButton.size.h },
					size = { stepSingleFrameButton.size.w, stepSingleFrameButton.size.h },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					hoverThrough = true,
					clickThrough = true
				}, true)
				stepSingleFrameButtonToggle:addCustomDisplay(function()
					if (not (
						MOUSE_X >= stepSingleFrameButtonToggle.pos.x and MOUSE_X <= stepSingleFrameButtonToggle.pos.x + stepSingleFrameButtonToggle.size.w and
						MOUSE_Y >= stepSingleFrameButtonToggle.pos.y and MOUSE_Y <= stepSingleFrameButtonToggle.pos.y + stepSingleFrameButtonToggle.size.h)) then
							stepSingleFrameButtonToggle.hoverState = BTN_NONE
					end
				end, true)
				local iconScale = stepSingleFrameButtonToggle.size.h * 0.5
				TBMenu:showTextWithImage(stepSingleFrameButtonToggle:addChild({ shift = { 10, 3 } }), TB_MENU_LOCALIZED.HUDSTEPSINGLETOGGLE, FONTS.LMEDIUM, iconScale, stepSingleFrame and "../textures/menu/general/buttons/checkmark.tga" or "../textures/menu/general/buttons/crosswhite.tga", { maxTextScale = 0.7 })
				stepSingleFrameButtonToggle:addMouseMoveHandler(function()
					if (stepSingleFrameButtonToggle.hoverState ~= BTN_DN) then
						play_haptics(0.6, HAPTICS.SELECTION)
					end
					stepSingleFrameButtonToggle.hoverState = BTN_DN
				end)
				stepSingleFrameButtonToggle:addMouseUpHandler(function()
					stepSingleFrame = not stepSingleFrame
				end)
			end
		end)

	-- This button shouldn't always be available, attach a handler for it
	table.insert(self.ButtonsToRefresh, {
		button = commitStepButtonHolder,
		shouldBeDisplayed = TBHudInternal.isPlaying
	})
end

function TBHud:spawnGhostButton()
	if (self.MainElement == nil) then return end

	local ghostButtonHolder = self.MainElement:addChild({
		pos = { -self.DefaultButtonSize * 3.1, -self.DefaultSmallerButtonSize * 1.5 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	self.GhostButtonHolder = ghostButtonHolder
	local ghostButton = TBHudInternal.generateTouchButton(ghostButtonHolder, "../textures/menu/general/buttons/ghost.tga")

	ghostButtonHolder:addCustomDisplay(true, function()
		local shouldBeDisplayed = TBHud.WorldState.replay_mode == 0 and is_game_frozen() == 1
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

function TBHud:spawnHoldRelaxAllButton()
	if (self.MainElement == nil) then return end

	local holdRelaxAllButtonHolder = self.MainElement:addChild({
		pos = { -self.DefaultButtonSize * 2.9, -self.DefaultSmallerButtonSize * 2.7 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	self.HoldAllButtonHolder = holdRelaxAllButtonHolder

	local holdAll = true
	local holdRelaxAllButton = TBHudInternal.generateTouchButton(holdRelaxAllButtonHolder)
	local relaxAllText = holdRelaxAllButton:addChild({
		shift = { 5, holdRelaxAllButton.size.h / 3 },
		shapeType = ROUNDED,
		rounded = 4,
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	relaxAllText:addAdaptedText(TB_MENU_LOCALIZED.MOBILEHUDRELAXALL, nil, nil, FONTS.LMEDIUM, nil, 0.5)
	local holdAllText = holdRelaxAllButton:addChild({
		shift = { 5, holdRelaxAllButton.size.h / 3 },
		shapeType = ROUNDED,
		rounded = 4,
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local function toggleButtonsDisplay()
		if (holdAll) then
			relaxAllText:hide()
			holdAllText:show()
		else
			relaxAllText:show()
			holdAllText:hide()
		end
	end
	holdAllText:addAdaptedText(TB_MENU_LOCALIZED.MOBILEHUDHOLDALL, nil, nil, FONTS.LMEDIUM, nil, 0.5)
	holdRelaxAllButton:addMouseUpHandler(function()
		for _, v in pairs(JOINTS) do
			set_joint_state(self.WorldState.selected_player, v, holdAll and JOINT_STATE.HOLD or JOINT_STATE.RELAX, true)
		end
		holdAll = not holdAll
		toggleButtonsDisplay()
	end)
	toggleButtonsDisplay()
	holdRelaxAllButtonHolder:addCustomDisplay(true, function()
		local shouldBeDisplayed = players_accept_input()
		if (shouldBeDisplayed and not holdRelaxAllButton:isDisplayed()) then
			holdRelaxAllButton:show()
		elseif (not shouldBeDisplayed and holdRelaxAllButton:isDisplayed()) then
			holdRelaxAllButton:hide()
		end
	end)
end

function TBHud:spawnRewindButton()
	if (self.MainElement == nil) then return end

	local rewindButtonHolder = self.MainElement:addChild({
		pos = { -self.DefaultButtonSize * 2.05, -self.DefaultSmallerButtonSize * 3.15 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	table.insert(self.MiscButtonHolders, rewindButtonHolder)
	TBHudInternal.generateTouchButton(rewindButtonHolder, "../textures/menu/general/buttons/reload.tga", nil, 0.8):addMouseUpHandler(rewind_replay)
	table.insert(self.ButtonsToRefresh, {
		button = rewindButtonHolder,
		shouldBeDisplayed = function() return self.WorldState.game_type == 0 end
	})
end

function TBHud:spawnPauseButton()
	if (self.MainElement == nil) then return end

	local pauseButtonHolder = self.MainElement:addChild({
		pos = { -self.DefaultButtonSize * 2.9, -self.DefaultSmallerButtonSize * 2.7 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	table.insert(self.MiscButtonHolders, pauseButtonHolder)
	local pauseButton = TBHudInternal.generateTouchButton(pauseButtonHolder, "../textures/menu/general/buttons/playpause.tga", { x = 0, y = 0, w = 128, h = 128 }, 0.8)
	pauseButton:addMouseUpHandler(toggle_game_pause)
	table.insert(self.ButtonsToRefresh, {
		button = pauseButtonHolder,
		shouldBeDisplayed = function() return self.WorldState.game_type == 0 and self.WorldState.replay_mode > 0 end
	})
	pauseButtonHolder:addCustomDisplay(true, function()
			pauseButton.icon.atlas.x = is_game_paused() and 0 or pauseButton.icon.atlas.w
		end)
end

function TBHud:spawnHubButton()
	if (self.MainElement == nil) then return end

	local settingsButtonHolder = self.MainElement:addChild({
		pos = { -self.DefaultSmallerButtonSize * 1.4, -self.DefaultSmallerButtonSize * 1.5 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	TBHudInternal.generateTouchButton(settingsButtonHolder, "../textures/menu/general/buttons/options.tga"):addMouseUpHandler(function()
		if (TUTORIAL_ISACTIVE) then
			open_menu(19)
		else
			TBHud:toggleHub(true)
		end
	end)
end

---@class HudDynamicButtonData
---@field title string
---@field icon AtlasData
---@field action function
---@field displayCondition function

---Reloads Hub's dynamic buttons section. \
---**This must be executed after QueueList has received the list update.**
function TBHud:reloadHubDynamicButtons()
	if (self.HubDynamicButtonsHolder == nil) then return end

	local playerInfoRaw = QueueList:getCurrentPlayerInfo()
	---@type QueueListPlayerInfo?
	local playerInfo = playerInfoRaw and {
		spectator = playerInfoRaw.spectator,
		admin = playerInfoRaw.admin,
		halfop = playerInfoRaw.halfop,
		op = playerInfoRaw.op
	}

	---First check if we actually need to reload any buttons
	---We don't want to run this code unless we actually know we'll have to reload buttons
	if (self.HubDynamicState ~= nil) then
		if (self.HubDynamicState.game_type == self.WorldState.game_type and
			self.HubDynamicState.replay_mode == self.WorldState.replay_mode and
			table.compare(self.HubDynamicState.PlayerInfo or {}, playerInfo or {})) then
			return
		end
	end
	self.HubDynamicState = table.clone(self.WorldState)
	self.HubDynamicState.PlayerInfo = playerInfo
	self.HubDynamicButtonsHolder:kill(true)

	---@type HudDynamicButtonData[]
	local buttonOptions = {
		{
			title = TB_MENU_LOCALIZED.MOBILEHUDHUBSPECTATE,
			icon = {
				filename = "../textures/menu/general/spectate_joinqueue_icon.tga",
				atlas = { x = 0, y = 0, w = 128, h = 128 }
			},
			action = function() runCmd("spec", true) end,
			displayCondition = function()
				return playerInfo ~= nil and not playerInfo.spectator or false
			end
		},
		{
			title = TB_MENU_LOCALIZED.MOBILEHUDHUBJOINQUEUE,
			icon = {
				filename = "../textures/menu/general/spectate_joinqueue_icon.tga",
				atlas = { x = 128, y = 0, w = 128, h = 128 }
			},
			action = function() runCmd("enter", true) end,
			displayCondition = function()
				return playerInfo ~= nil and playerInfo.spectator or false
			end
		},
		{
			title = TB_MENU_LOCALIZED.REPLAYSSAVEREPLAY,
			icon = {
				filename = "../textures/menu/general/buttons/savewhite.tga"
			},
			action = function() dofile("system/replay_save.lua") end,
			displayCondition = function() return true end
		}
	}

	local buttonSize = math.min(50, math.floor(self.HubDynamicButtonsHolder.size.h / 5))
	local buttonsDisplayed = 0
	for _, v in pairs(buttonOptions) do
		if (v.displayCondition()) then
			local buttonHolder = self.HubDynamicButtonsHolder:addChild({
				pos = { 0, buttonsDisplayed * buttonSize },
				size = { self.HubDynamicButtonsHolder.size.w, buttonSize }
			})
			buttonsDisplayed = buttonsDisplayed + 1

			local button = buttonHolder:addChild({
				shift = { 0, 3 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 5
			})
			local buttonIcon = button:addChild({
				pos = { 10, 10 },
				size = { button.size.h - 20, button.size.h - 20 },
				bgImage = v.icon.filename,
				imageAtlas = v.icon.atlas ~= nil,
				atlas = v.icon.atlas
			})
			local buttonText = button:addChild({
				pos = { button.size.h, 5 },
				size = { button.size.w - button.size.h - 5, button.size.h - 10 }
			})
			buttonText:addAdaptedText(true, v.title, nil, nil, FONTS.MEDIUM, LEFTMID)
			button:addMouseUpHandler(function()
					self:toggleHub(false)
					v.action()
				end)
		end
	end

	if (not self.HubDynamicButtonsHolder:isDisplayed()) then
		self.HubDynamicButtonsHolder:show()
		self.HubDynamicButtonsHolder:hide()
	else
		self.HubHolder:reload()
	end
end

---Spawns right side hud hub menu
function TBHud:spawnHub()
	if (self.MainElement == nil) then return end
	local safe_x, safe_y = get_window_safe_size()


	if (self.HubHolder ~= nil) then
		self.HubHolder:kill()
	end
	self.HubHolder = self.MainElement:addChild({
		globalid = self.HubGlobalid,
		pos = { self.MainElement.size.w, 0 },
		size = { self.MainElement.size.w, self.MainElement.size.h },
		bgColor = UICOLORBLACK,
		interactive = true
	})
	self.HubHolder:addMouseUpHandler(function() self:toggleHub(false) end)

	local hubBackground = self.HubHolder:addChild({
		pos = { -self.HubSize.w - safe_x, 0 },
		size = { self.HubSize.w + safe_x, self.HubSize.h },
		bgColor = { 1, 1, 1, 0.7 },
		interactive = true
	})
	local hubMainHolder = hubBackground:addChild({
		pos = { 0, 0 },
		size = { self.HubSize.w, self.HubSize.h }
	})
	local topRowButtons = {
		{
			title = TB_MENU_LOCALIZED.MAINMENUMODLISTNAME,
			image = "../textures/menu/general/mods_icon.tga",
			action = function() dofile("system/mods.lua") end
		},
		{
			title = TB_MENU_LOCALIZED.MAINMENUGAMERULESNAME,
			image = "../textures/menu/general/gamerules_icon.tga",
			action = function() dofile("system/gamerules.lua") end
		},
		{
			title = TB_MENU_LOCALIZED.SHADERSATMOSNAME,
			image = "../textures/menu/general/shaders_icon.tga",
			action = function() dofile("system/atmo.lua") end
		}
	}
	local numButtons = #topRowButtons
	local buttonSize = (hubMainHolder.size.w - 20) / numButtons - 10 * ((numButtons - 1) / numButtons)
	local topButtonsHolder = hubMainHolder:addChild({
		pos = { 10, math.max(safe_y, 20) },
		size = { hubMainHolder.size.w - 20, buttonSize }
	})
	for i, v in pairs(topRowButtons) do
		local buttonElement = topButtonsHolder:addChild({
			pos = { (i - 1) * (buttonSize + 10), 0 },
			size = { buttonSize, buttonSize },
			bgImage = "../textures/menu/button_backdrop.tga",
			imageColor = TB_MENU_DEFAULT_BG_COLOR,
			imageHoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
			imagePressedColor = TB_MENU_DEFAULT_DARKER_ORANGE,
			interactive = true
		})
		buttonElement:addMouseUpHandler(function()
			self:toggleHub(false)
			v.action()
		end)
		buttonElement:addChild({
			shift = { 10, 10 },
			bgImage = v.image
		})
		local buttonTitleHolder = buttonElement:addChild({
			pos = { 0, -30 },
			size = { buttonElement.size.w, 30 },
			bgColor = buttonElement.imageAnimateColor,
			shapeType = ROUNDED,
			rounded = { 0, 5 }
		})
		buttonTitleHolder:addChild({ shift = { 5, 2 }}):addAdaptedText(false, v.title)
	end

	local mainMenuButton = hubMainHolder:addChild({
		pos = { 10, -50 - math.max(safe_y, 20) },
		size = { hubMainHolder.size.w - 20, 50 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 5
	})
	mainMenuButton:addChild({ shift = { 10, 5 }}):addAdaptedText("> " .. TB_MENU_LOCALIZED.MOBILEHUDTOMAINMENU)
	mainMenuButton:addMouseUpHandler(function() open_menu(19) TBHud:toggleHub(false) end)

	local middleSectionHolder = hubMainHolder:addChild({
		pos = { topButtonsHolder.shift.x, topButtonsHolder.shift.y + topButtonsHolder.size.h + 20 },
		size = { topButtonsHolder.size.w, hubMainHolder.size.h - (topButtonsHolder.shift.y + topButtonsHolder.size.h + 20) - (mainMenuButton.size.h + 20 + math.max(safe_y, 20)) }
	})
	self.HubDynamicButtonsHolder = middleSectionHolder
	self:reloadHubDynamicButtons()

	self.HubHolder:hide(true)
end

function TBHud:toggleHub(state)
	if (state == true) then
		self.HubHolder:show(true)
	end

	local clock = UIElement.clock
	local safe_x = get_window_safe_size()
	if (state == true) then
		self.HubHolder:moveTo(self.HubSize.w)
	end
	self.HubHolder:addCustomDisplay(true, function()
		local tweenValue = (UIElement.clock - clock) * 6
		if (state) then
			self.HubHolder:moveTo(UITween.SineTween(self.HubHolder.pos.x, 0, tweenValue))
		else
			self.HubHolder:moveTo(UITween.SineTween(self.HubHolder.pos.x, self.HubSize.w + safe_x, tweenValue))
		end

		if (tweenValue >= 1) then
			if (state) then
				self.HubHolder:addCustomDisplay(true, function() end)
			else
				self.HubHolder:hide(true)
			end
		end
	end)
end

---@class HudChatCommand
---@field command string Example command displayed in UI
---@field regex string Regex expression to match input against
---@field replacement string String to replace with

---Returns the list of chat commands data that will be used for chat autofilling
---@return HudChatCommand[]
function TBHud:getChatCommands()
	return {
		--set = { command = "/set ^46gamerule ^47value", regex = "^(/%w+) ?(%w+ )?(%w+ )?.*", replacement = "%1 %2%3" },
		--opt = { command = "/opt ^46option ^47value", regex = "^(/%w+) ?(%w+ )?(%w+ )?.*", replacement = "%1 %2%3" }
	}
end

---Spawns the chat button for touch UI
function TBHud:spawnChatButton()
	if (self.MainElement == nil) then return end

	local chatButtonHolder = self.MainElement:addChild({
		pos = { self.DefaultSmallerButtonSize * 0.4, -self.DefaultSmallerButtonSize * 1.5 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	self.ChatButtonHolder = chatButtonHolder
	local chatButton = TBHudInternal.generateTouchButton(chatButtonHolder, "../textures/menu/general/buttons/chat.tga")

	chatButtonHolder:addCustomDisplay(function()
		if (self.ChatHolder ~= nil) then
			if (chatButton:isDisplayed() and self.ChatHolder:isDisplayed()) then
				chatButton:hide()
			elseif (not chatButton:isDisplayed() and not self.ChatHolder:isDisplayed()) then
				chatButton:show()
			end
		end
	end)
	chatButton:addMouseUpHandler(function()
		self:toggleChat(true)
	end)
end

---Parses a string and checks the last used color for the string
---@param str string
---@return Color|nil
function TBHudInternal.getLastColorFromString(str)
	local color, rpl = string.gsub(str, ".*[%^%%](%d%d+).*", "%1")
	if (rpl == 1 and string.len(color) > 0) then
		local colid = tonumber(color)
		if (colid and colid >= 0 and colid < COLORS.NUM_COLORS) then
			local colinfo = get_color_info(colid)
			return { colinfo.r, colinfo.g, colinfo.b, 1 }
		end
	end
	return nil
end

---Reloads chat display
function TBHud:refreshChat()
	local elementHeight = 18

	if (self.ChatHolderItems == nil) then
		-- Do the initial setup
		local x, y = get_window_safe_size()
		local chatMessagesHolder = self.ChatHolder:addChild({
			pos = { x, -self.ChatSize.h },
			size = { self.ChatSize.w, self.ChatSize.h },
			bgColor = table.clone(UICOLORWHITE),
			uiColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		chatMessagesHolder.bgColor[4] = 0.7
		local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(chatMessagesHolder, 1, 40 + math.max(30, y), 16, { 0, 0, 0, 0 })

		---@type UIElement[]
		self.ChatHolderItems = {}
		for _, message in pairs(TBHudInternal.ChatMessages) do
			message.lines = 0
			local messageStrings = textAdapt(message.text, FONTS.SMALL, 1, listingHolder.size.w - 32)
			local nextColor = nil
			for _, str in pairs(messageStrings) do
				local chatMessage = listingHolder:addChild({
					pos = { 16, #self.ChatHolderItems * elementHeight },
					size = { listingHolder.size.w - 32, elementHeight },
					uiColor = nextColor
				})
				chatMessage:addAdaptedText(true, str, nil, nil, FONTS.SMALL, LEFT, 1, 1)
				table.insert(self.ChatHolderItems, chatMessage)
				nextColor = TBHudInternal.getLastColorFromString(str)
				message.lines = message.lines + 1
			end
		end

		local botBarGradient = botBar:addChild({
			pos = { 0, -botBar.size.h - 5 },
			size = { botBar.size.w, 10 },
			bgGradient = { UICOLORWHITE, { 1, 1, 1, 0 } }
		})
		local botBarBackdrop = botBar:addChild({
			pos = { 0, 5 },
			size = { botBar.size.w, botBar.size.h - 5 },
			bgColor = UICOLORWHITE
		})
		local chatInputHolder = botBar:addChild({
			pos = { 20, botBar.size.h - 30 - math.max(y, 30) },
			size = { botBar.size.w - 40, 30 },
			shapeType = ROUNDED,
			rounded = 4,
			uiColor = UICOLORWHITE,
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local chatInputField = TBMenu:spawnTextField2(chatInputHolder, { x = 30, w = chatInputHolder.size.w - 120 }, nil, nil, {
			fontId = FONTS.SMALL,
			textAlign = LEFTMID,
			textScale = 1,
			textColor = table.clone(UICOLORWHITE),
			keepFocusOnHide = true,
			darkerMode = true
		})
		local destroySuggestions = function()
			if (chatInputField.suggestionsDropdown ~= nil) then
				chatInputField.suggestionsDropdown:kill()
				chatInputField.suggestionsDropdown = nil
			end
		end
		chatInputField:addInputCallback(function()
				destroySuggestions()

				local typeCommand, replacements = chatInputField.textfieldstr[1]:gsub("^/(%w+).*", "%1")
				if (replacements == 0) then
					return
				end

				local commands = self:getChatCommands()
				local targetCommands = {}
				for cmd, _ in pairs(commands) do
					if (cmd:find("^" .. typeCommand)) then
						table.insert(targetCommands, commands[cmd])
					end
				end
				if (#targetCommands == 0) then
					return
				end

				local dropdownList = {}
				for _, cmdInfo in pairs(targetCommands) do
					table.insert(dropdownList, {
						text = cmdInfo.command,
						action = function() end
					})
				end

				chatInputField.suggestionsDropdown = TBMenu:spawnDropdown(chatInputHolder, dropdownList, chatInputField.size.h, WIN_H / 3, { text = '' }, nil, { scale = 0.65, fontid = 4, uppercase = false, alignment = LEFTMID }, true, true, true)
				chatInputField.suggestionsDropdown.uiColor = UICOLORWHITE
				---@diagnostic disable-next-line: undefined-field
				chatInputField.suggestionsDropdown.selectedElement:hide(true)
				---@diagnostic disable-next-line: undefined-field
				chatInputField.suggestionsDropdown.selectedElement:btnUp()
			end)
		-- Don't need chat history for mobile for now
		chatInputField:addKeyboardHandlers(function(key)
				if (key == 273 or key == 274) then -- arrow up or down
					if (key == 273) then
						TBHudInternal.ChatMessageHistoryIndex = math.max(TBHudInternal.ChatMessageHistoryIndex - 1, 1)
					else
						TBHudInternal.ChatMessageHistoryIndex = math.min(TBHudInternal.ChatMessageHistoryIndex + 1, #TBHudInternal.ChatMessageHistory)
					end
					chatInputField.textfieldstr[1] = TBHudInternal.ChatMessageHistory[TBHudInternal.ChatMessageHistoryIndex]
					chatInputField.textfieldindex = utf8.len(chatInputField.textfieldstr[1])
				end
			end)
		chatInputField:addEnterAction(function()
				if (utf8.len(chatInputField.textfieldstr[1]) == 0) then return end
				if (string.find(chatInputField.textfieldstr[1], "^/")) then
					local cmd = chatInputField.textfieldstr[1]:gsub("^/(.+)", "%1")
					runCmd(cmd, self.WorldState.game_type == 1)
				else
					---@diagnostic disable-next-line: undefined-global
					send_chat_message(chatInputField.textfieldstr[1])
				end
				add_chat_history(chatInputField.textfieldstr[1])
				table.insert(TBHudInternal.ChatMessageHistory, #TBHudInternal.ChatMessageHistory, chatInputField.textfieldstr[1])
				TBHudInternal.ChatMessageHistoryIndex = #TBHudInternal.ChatMessageHistory
				chatInputField:clearTextfield()
				destroySuggestions()
			end)
		local chatMessagePrevious = chatInputHolder:addChild({
			pos = { 0, 0 },
			size = { chatInputField.parent.parent.shift.x, chatInputHolder.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		}, true)
		chatMessagePrevious:addChild({
			shift = { chatMessagePrevious.size.w / 2 - (chatMessagePrevious.size.h - 4) / 4, 2 },
			bgImage = "../textures/menu/general/buttons/arrowleft.tga"
		})
		chatMessagePrevious:addMouseUpHandler(function()
			---Simulate key up press
			chatInputField.keyDownCustom(273)
		end)
		local chatInputSubmit = chatInputHolder:addChild({
			pos = { chatInputField.parent.parent.shift.x + chatInputField.parent.parent.size.w, 0 },
			size = { chatInputHolder.size.w - chatInputField.parent.parent.shift.x - chatInputField.parent.parent.size.w, chatInputHolder.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		chatInputSubmit:addChild({ shift = { 10, 3 }}):addAdaptedText("Submit")
		chatInputSubmit:addMouseUpHandler(chatInputField.enteraction)

		self.ChatHolderToReload = toReload
		self.ChatHolderListing = listingHolder
		self.ChatHolderTopBar = topBar
	else
		local i = 1
		if (-self.ChatHolderListing.shift.y >= #self.ChatHolderItems * elementHeight) then
			TBHud.ListShift[1] = 0
		end

		for _, message in pairs(TBHudInternal.ChatMessages) do
			if (i > #self.ChatHolderItems) then
				local messageStrings = textAdapt(message.text, FONTS.SMALL, 1, self.ChatHolderListing.size.w - 32)
				message.lines = 0
				local nextColor = nil
				for _, str in pairs(messageStrings) do
					local chatMessage = self.ChatHolderListing:addChild({
						pos = { 16, #self.ChatHolderItems * elementHeight },
						size = { self.ChatHolderListing.size.w - 32, elementHeight },
						uiColor = nextColor
					})
					chatMessage:addAdaptedText(true, str, nil, nil, FONTS.SMALL, LEFT, 1, 1)
					table.insert(self.ChatHolderItems, chatMessage)
					nextColor = TBHudInternal.getLastColorFromString(str)
					message.lines = message.lines + 1

					if (self.ChatHolderScrollBar ~= nil) then
						chatMessage:hide(true)
					end
				end
			end
			i = i + message.lines
		end
	end

	if (self.ChatHolderItems[1] ~= nil) then
		local listingHolder = self.ChatHolderListing
		if (#self.ChatHolderItems * elementHeight > listingHolder.size.h) then
			if (self.ChatHolderScrollBar == nil) then
				for _, v in pairs(self.ChatHolderItems) do
					v:hide(true)
				end

				-- Don't forget to move listing holder back in place
				listingHolder:moveTo(nil, self.ChatHolderTopBar.size.w)
				self.ChatHolderScrollBar = TBMenu:spawnScrollBar(listingHolder, #self.ChatHolderItems, elementHeight)
				self.ChatHolderScrollBar:makeScrollBar(listingHolder, self.ChatHolderItems, self.ChatHolderToReload, TBHud.ListShift)
			else
				self.ChatHolderScrollBar.size.h = math.max(0.1, math.min(1, (listingHolder.size.h) / (#self.ChatHolderItems * elementHeight) or listingHolder.size.h)) * self.ChatHolderScrollBar.parent.size.h
			end

			if (TBHud.ListShift[1] == 0) then
				local hoverState = self.ChatHolderScrollBar.hoverState
				self.ChatHolderScrollBar.hoverState = BTN_DN
				self.ChatHolderScrollBar.btnHover(self.ChatHolderScrollBar.parent.pos.x + 1, self.ChatHolderScrollBar.parent.pos.y + self.ChatHolderScrollBar.parent.size.h - 2)
				self.ChatHolderScrollBar.hoverState = hoverState
			else
				local scrollProgress = -(self.ChatHolderListing.size.h + self.ChatHolderListing.shift.y) / (#self.ChatHolderItems * elementHeight - self.ChatHolderListing.size.h)
				self.ChatHolderScrollBar:moveTo(nil, (self.ChatHolderScrollBar.parent.size.h - self.ChatHolderScrollBar.size.h) * scrollProgress)
			end
		else
			listingHolder:moveTo(nil, listingHolder.parent.size.h - elementHeight * #self.ChatHolderItems)
		end
	end

	self.RequiresChatRefresh = false
end

function TBHud:toggleChat(state)
	if (state == true) then
		self.ChatHolder:show(true)
		if (self.RequiresChatRefresh) then
			self:refreshChat()
		end
	end

	local clock = UIElement.clock
	self.ChatHolder:addCustomDisplay(true, function()
		local tweenValue = (UIElement.clock - clock) * 6
		if (state) then
			self.ChatHolder:moveTo(nil, UITween.SineTween(self.ChatHolder.pos.y, 0, tweenValue))
		else
			self.ChatHolder:moveTo(nil, UITween.SineTween(self.ChatHolder.pos.y, self.ChatHolder.size.h, tweenValue))
		end

		if (tweenValue >= 1) then
			if (state == false) then
				self.ChatHolder:hide(true)
			else
				self.ChatHolder:addCustomDisplay(true, function() end)
			end
		end
	end)
end

---Spawns mini chat holder
function TBHud:spawnMiniChat()
	if (self.ChatMiniHolder ~= nil) then
		self.ChatMiniHolder:kill()
	end
	self.ChatMiniHolder = self.MainElement:addChild({
		pos = { self.DefaultSmallerButtonSize * 1.7, 0 },
		size = { self.ChatSize.w, WIN_H - self.DefaultButtonSize * 0.35 }
	})

	---@type ChatMessage[]
	local messagesToDisplay = {}
	local refreshMiniChat = function()
		messagesToDisplay = {}
		for i = #TBHudInternal.ChatMessages, 1, -1 do
			if (TBHudInternal.ChatMessages[i].clock < UIElement.clock - self.ChatMiniDisplayPeriod) then
				break
			end
			table.insert(messagesToDisplay, TBHudInternal.ChatMessages[i])
			if (#messagesToDisplay == self.ChatMiniMaxMessages) then
				break
			end
		end
		for i, v in pairs(messagesToDisplay) do
			messagesToDisplay[i].adaptedTextMini = textAdapt(v.text, FONTS.SMALL, 1, self.ChatMiniHolder.size.w)
			messagesToDisplay[i].textColorMini = { nil }
			local displayColor = nil
			for j, line in pairs(messagesToDisplay[i].adaptedTextMini) do
				displayColor = TBHudInternal.getLastColorFromString(line) or displayColor
				messagesToDisplay[i].textColorMini[j + 1] = displayColor
			end
		end
		self.ChatMiniUpdateTime = os.time()
	end

	self.ChatMiniHolder:addCustomDisplay(function()
			if (self.ChatHolder:isDisplayed()) then return end
			if (os.time() ~= self.ChatMiniUpdateTime) then
				refreshMiniChat()
			end
			local linesPrinted = 0
			for _, v in pairs(messagesToDisplay) do
				local textOpacity = UITween.SineEaseOut((v.clock - UIElement.clock + (self.ChatMiniDisplayPeriod - 1)) / 3)
				for i = #v.adaptedTextMini, 1, -1 do
					local displayColor = table.clone(v.textColorMini[i] or TB_MENU_DEFAULT_DARKEST_COLOR)
					displayColor[4] = textOpacity
					self.ChatMiniHolder:uiText(v.adaptedTextMini[i], nil, -linesPrinted * 20, FONTS.SMALL, LEFTBOT, 1, nil, nil, displayColor)
					linesPrinted = linesPrinted + 1
					if (linesPrinted > self.ChatMiniMaxMessages) then
						return
					end
				end
			end
		end)
end

function TBHud:loadChatHistory()
	TBHudInternal.ChatMessageHistory = get_chat_history()
	table.insert(TBHudInternal.ChatMessageHistory, "")
	TBHudInternal.ChatMessageHistoryIndex = #TBHudInternal.ChatMessageHistory
end

function TBHud:spawnChat()
	if (self.MainElement == nil) then return end

	set_option("chat", 0)
	if (self.ChatHolder ~= nil) then
		self.ChatHolder:kill()
	end
	self.ChatHolder = self.MainElement:addChild({
		pos = { 0, self.MainElement.size.h },
		size = { self.MainElement.size.w, self.MainElement.size.h },
		interactive = true
	})
	self.ChatHolder:addMouseUpHandler(function() self:toggleChat(false) end)
	self:refreshChat()
	self:spawnMiniChat()
	self:loadChatHistory()

	self.ChatHolder:hide(true)
end

TBHud.Reload()
add_hook("resolution_changed", "tbHudTouchInterface", TBHud.Reload)
add_hook("new_game", "tbHudTouchInterface", TBHudInternal.refreshButtons)
add_hook("spec_update", "tbHudTouchInterface", TBHudInternal.refreshButtons)
add_hook("bout_update", "tbHudTouchInterface", TBHudInternal.refreshButtons)
add_hook("enter_frame", "tbHudTouchInterface", TBHudInternal.refreshButtons)
add_hook("console_post", "tbHudChatInterface", TBHudInternal.pushChatMessage)
