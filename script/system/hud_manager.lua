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
	---**Toribash touch HUD class**
	---
	---**Version 5.74**
	---* Chat command suggestions
	---
	---**Version 5.70**
	---* Added `HookNameUI`, `HookNameChat` and `HookNameCamera` fields to access hook names in a uniform way
	---* Added add camera keyframe button and slightly tweaked camera joystick
	---
	---**Version 5.66**
	---* Added camera mode button
	---* Added free cam joystick controls
	---
	---**Version 5.65**
	---* Added hud option observer to enable/disable UI
	---
	---**Version 5.64**
	---* Fixed wrong cleanup and new message setup after reaching message history limit
	---* Auto hide chat input on new room join
	---* Refresh buttons after hitting `Ready`
	---
	---**Version 5.61**
	---* Added chat tabs and whispers support
	---* Added `HubButtonHolder` field to reference Hub button by Tutorials/Events
	---* Added `GripButtonHolder` field to reference by Tutorials/Events
	---* Added `TutorialHubOverride` function callback to **TBHudInternal**
	---
	---**Version 5.60**
	---* Initial release
	---@class TBHud
	---@field MainElement UIElement
	---@field CommitStepButtonHolder UIElement
	---@field ChatButtonHolder UIElement
	---@field ChatButtonHolderBadge UIElement
	---@field HoldAllButtonHolder UIElement
	---@field GhostButtonHolder UIElement
	---@field GripButtonHolder UIElement
	---@field HubButtonHolder UIElement
	---@field CameraButtonHolder UIElement
	---@field CameraJoystickFreeHolder UIElement
	---@field CameraJoystickSensitivity number
	---@field CameraKeyframeButtonHolder UIElement
	---@field CameraKeyframeEditButtonHolder UIElement
	---@field MiscButtonHolders UIElement[]
	---@field HubHolder UIElement
	---@field HubDynamicButtonsHolder UIElement
	---@field HubDynamicState WorldState
	---@field HubSize UIElementSize
	---@field ChatHolder UIElement
	---@field ChatMiniHolder UIElement
	---@field ChatSize UIElementSize
	---@field ChatTabWidth integer
	---@field ChatActiveTab integer Currently active chat tab id
	---@field ChatMaxHistory integer Maximum number of messages that will be displayed in chat
	---@field ChatMiniMaxMessages integer Maximum number of messages that can be shown in mini chat at a time
	---@field ChatMiniDisplayPeriod number Maximum time in seconds that messages in mini chat will be displayed for
	---@field ChatMiniUpdateTime integer Last update time for mini chat
	---@field ChatMiniLastTab integer Last active mini chat tab id
	---@field WorldState WorldState Cached WorldState instance, updated every frame
	---@field ButtonsToRefresh TBHudButton[]
	---@field DefaultButtonColor Color
	---@field DefaultButtonSize number
	---@field DefaultSmallerButtonSize number
	---@field RequiresChatRefresh boolean
	TBHud = {
		Globalid = 1013,
		HubGlobalid = 1014,
		HubSize = { w = 0, h = 0 },
		ChatSize = { w = 0, h = 0},
		ChatTabWidth = 60,
		ChatActiveTab = 0,
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
		HudEnabled = true,
		HudEnableHintDisplayed = false,
		CameraJoystickSensitivity = 0.075,
		StepSingleFrame = false,
		StepSingleFramePause = false,
		HookNameUI = "__tbHudTouchInterface",
		HookNameChat = "__tbHudChatInterface",
		HookNameCamera = "__tbHudFreeCamJoystick",
		__waitingWhisper = false,
		ver = 5.74,
	}
	TBHud.__index = TBHud

	TBHud.DefaultSmallerButtonSize = TBHud.DefaultButtonSize * 0.7
	TBHud.SafeAreaOffset = TBHud.DefaultButtonSize * 3

	---**Mobile hud popup class** \
	---This class provides a uniform solution to display all information popups to users (such as broadcasts, quests, etc).
	---
	---**Version 5.60**
	---* Initial release
	---@class TBHudPopup : UIElement
	---@field Manager UIElement
	---@field Queue TBHudPopup[] Active queue of popups to display
	---@field DefaultDuration number Default popup display duration, in seconds
	---@field PopupActive boolean Whether we currently have a popup displayed to user
	---@field __touchPos Vector2Base
	---@field __touchDelta Vector2Base
	---@field __launchClock number|nil
	---@field __touchClock number|nil
	---@field __duration number
	TBHudPopup = {
		ver = TBHud.ver,
		Queue = {},
		DefaultDuration = 10,
		PopupActive = false
	}
	TBHudPopup.__index = TBHudPopup
	setmetatable(TBHudPopup, UIElement)
end

---Internal subclass for **TBHud** that holds utility functions we won't need elsewhere
---@class TBHudInternal
---@field ChatMessages ChatMessage[]
---@field ChatMessageHistory string[] User chat message history
---@field ChatMessageHistoryIndex integer
---@field TutorialHubOverride function|nil Custom function to be executed when a user presses Hub button while in Tutorial/Event mode
---@field ReadyLongPressEnabled boolean Whether `Ready` button long press functionality is enabled
---@field ListShift number[] Chat scroll bar posShift values
---@field IgnoreCommands string[] Chat commands that we want ignored in mobile UI
local TBHudInternal = {
	ChatMessages = {},
	ChatMessageHistory = {},
	ChatMessageHistoryIndex = -1,
	TutorialHubOverride = nil,
	ReadyLongPressEnabled = true,
	PauseLongPressEnabled = true,
	ListShift = { 0 },
	ChatElementHeight = 25,
	RequireListReload = false,
	IgnoreCommands = {
		"addtab",
		"closetab"
	}
}

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
				buttonIcon.imageColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
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
	if (TBHud.WorldState.game_type == 0 or players_accept_input()) then
		return true
	end
	if (#QueueList.Cache.Players.Bouts < 2) then
		---Only one player in queue, they can't play
		return false
	end

	if (QueueList.Cache.Players.Bouts[1].isMe or QueueList.Cache.Players.Bouts[2].isMe) then
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
	if (TBHud.HubHolder:isDisplayed()) then
		TBHud:reloadHubDynamicButtons()
	end
end

---Method that handles all incoming chat messages and pushes them for display
---@param msg string
---@param type ChatMessageType
---@param tab integer
function TBHudInternal.pushChatMessage(msg, type, tab)
	---Colorize first symbol if needed
	if (type > MSGTYPE.SERVER) then
		local match, matchEnd = utf8.find(msg, "([%^%%]%d%d+)>")
		if (match ~= nil) then
			msg = utf8.sub(msg, match, matchEnd - 1) .. msg
		end
	end

	local message = get_option("chatcensor") % 2 == 1 and ChatIgnore.FilterInput(msg) or msg
	---@type ChatMessage
	local chatMessage = {
		text = message,
		tab = tab,
		clock = os.clock_real()
	}
	if (#TBHudInternal.ChatMessages >= TBHud.ChatMaxHistory) then
		local messageInfo = TBHudInternal.ChatMessages[1]
		local messageHolder = TBHud.ChatHolderItems[messageInfo.tab]
		if (messageHolder and messageHolder[1]) then
			local messageLines = messageInfo.lines
			if (messageLines ~= nil and messageLines > 0) then
				for _ = 1, messageLines do
					local lineElement = messageHolder[1]
					if (lineElement ~= nil) then
						---@diagnostic disable-next-line: undefined-field
						if (messageHolder[1].isNewMessageMark) then
							messageHolder.hasNewMessageMark = nil
							messageLines = messageLines + 1
						end
						if (lineElement == TBHud.ChatHolderListing.child[1]) then
							table.remove(TBHud.ChatHolderListing.child, 1)
						end
						if (lineElement == messageHolder[1]) then
							table.remove(messageHolder, 1)
						end
						lineElement:kill()
					else
						messageLines = messageLines - 1
					end
				end
				for _, v in ipairs(messageHolder) do
					v:moveTo(nil, -v.size.h * messageLines, true)
				end
				TBHudInternal.RequireListReload = true
			end
		end
		table.remove(TBHudInternal.ChatMessages, 1)
	end

	table.insert(TBHudInternal.ChatMessages, chatMessage)
	if (TBHud.ChatHolder ~= nil and TBHud.ChatHolder:isDisplayed()) then
		if (TBHud.ChatActiveTab == tab) then
			TBHud:refreshChat()
		else
			if (TBHud.ChatTabItems[tab] == nil) then
				TBHud:spawnChatTabButton(tab)
				if (TBHud.__waitingWhisper) then
					TBHud:switchChatTab(tab)
				end
			end
			TBHud:markChatTabUnread(tab)
		end
	else
		if (TBHud.ChatTabItems[tab] == nil) then
			local button = TBHud:spawnChatTabButton(tab)
			button:hide()
		end
		for _, v in ipairs(TBHud.ChatHolderItems[tab] or {}) do
			v:hide()
		end
		-- Play some sound?
		if (TBHud.ChatActiveTab ~= tab) then
			TBHud:markChatTabUnread(tab)
			TBHud:setChatNotification()
			play_sound(67)
		end
		TBHud.ChatMiniUpdateTime = 0
		TBHud.RequiresChatRefresh = true
	end
	TBHud.__waitingWhisper = false
end

---Initializes HUD main elements
function TBHud:init()
	if (self.MainElement ~= nil) then
		return
	end

	---Reload button sizes and area offset on init in case it was triggered by resolution reload
	self.DefaultButtonSize = math.max(100, WIN_H / 10)
	self.DefaultSmallerButtonSize = self.DefaultButtonSize * 0.7
	self.SafeAreaOffset = self.DefaultButtonSize * 3
	self.ChatTabWidth = math.min(60, WIN_H / 10)
	self.ChatActiveTab = 0

	self.MainElement = UIElement:new({
		globalid = self.Globalid,
		pos = { 0, 0 },
		size = { WIN_W, WIN_H }
	})
	self.MainElement:addCustomDisplay(true, function()
		self.WorldState = UIElement.WorldState

		local hudState = TUTORIAL_ISACTIVE and true or (get_option("hud") == 1)
		if (self.HudEnabled ~= hudState) then
			if (hudState == false) then
				self.MainElement:moveTo(WIN_W * 2, 0)
				if (not self.HudEnableHintDisplayed) then
					self.HudEnableHintDisplayed = true
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.HUDINFODISABLEDTOUCH)
				end
			else
				self.MainElement:moveTo(0, 0)
			end
			self.HudEnabled = hudState
		end
	end)

	self.ButtonsToRefresh = {}

	set_option("feedback", 0)
	set_option("hint", 0)

	self:spawnCommitButton()
	self:spawnGhostButton()
	self:spawnHoldRelaxAllButton()
	self:spawnRewindButton()
	self:spawnPauseButton()
	self:spawnEditButton()
	self:spawnGripButton()
	self:spawnCancelMoveButton()
	self:spawnCameraButtons()

	self:spawnHubButton()
	self.HubSize.w = math.clamp(500, WIN_W * 0.3, WIN_W * 0.4)
	self.HubSize.h = WIN_H
	self:spawnHub()

	self:spawnChatButton()
	self.ChatSize.w = math.clamp(600 + self.ChatTabWidth, WIN_W * 0.45, WIN_W * 0.7)
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
		TBHud.ChatTabHolder = nil
		TBHud.ChatTabItems = nil
		TBHud.ChatMiniHolder = nil
		TBHud.ChatHolderListing = nil
		TBHud.ChatHolderScrollBar = nil
		TBHud.ChatHolderToReload = nil
		TBHud.ChatHolderTopBar = nil
		TBHud.HubHolder = nil
		TBHud.CommitStepButtonHolder = nil
		TBHud.ChatButtonHolder = nil
		TBHud.ChatButtonHolderBadge = nil
		TBHud.HoldAllButtonHolder = nil
		TBHud.GhostButtonHolder = nil
		TBHud.GripButtonHolder = nil
		TBHud.HubButtonHolder = nil
		TBHud.CameraButtonHolder = nil
		TBHud.CameraJoystickFreeHolder = nil
		TBHud.CameraKeyframeButtonHolder = nil
		TBHud.CameraKeyframeEditButtonHolder = nil
		TBHud.MiscButtonHolders = { }
	end

	TBHud:init()
end

---Toggles `Ready` button long press functionality on and off
---@param state boolean
function TBHud.ToggleReadyLongPress(state)
	TBHudInternal.ReadyLongPressEnabled = state
end

---Toggles `Pause` button long press functionality on and off
---@param state boolean
function TBHud.TogglePauseLongPress(state)
	TBHudInternal.PauseLongPressEnabled = state
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
	commitStepButton:addMouseUpHandler(function()
		if (self.WorldState.replay_mode ~= 0) then
			if (TUTORIAL_ISACTIVE) then
				call_hook("key_up", 32, 44)
			else
				start_new_game(true)
			end
		else
			step_game(self.WorldState.game_type == 0 and (TBHudInternal.ReadyLongPressEnabled and self.StepSingleFrame))
			commitStepButtonHolder:hide()
		end
		clickClock = 0
		TBHudInternal.refreshButtons()
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
			if (TBHudInternal.ReadyLongPressEnabled and clickClock > 0 and UIElement.clock - clickClock > UIElement.longPressDuration) then
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
				}):addAdaptedText(self.StepSingleFrame and TB_MENU_LOCALIZED.HUDSTEPFRAMEFULL or TB_MENU_LOCALIZED.HUDSTEPFRAMESINGLE, nil, nil, FONTS.LMEDIUM, nil, 0.7)
				stepSingleFrameButton:addMouseMoveHandler(function()
					if (stepSingleFrameButton.hoverState ~= BTN_DN) then
						play_haptics(0.6, HAPTICS.SELECTION)
					end
					stepSingleFrameButton.hoverState = BTN_DN
				end)
				stepSingleFrameButton:addMouseUpHandler(function()
					step_game(self.StepSingleFrame)
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
				TBMenu:showTextWithImage(stepSingleFrameButtonToggle:addChild({ shift = { 10, 3 } }), TB_MENU_LOCALIZED.HUDSTEPSINGLETOGGLE, FONTS.LMEDIUM, iconScale, self.StepSingleFrame and "../textures/menu/general/buttons/checkmark.tga" or "../textures/menu/general/buttons/crosswhite.tga", { maxTextScale = 0.7 })
				stepSingleFrameButtonToggle:addMouseMoveHandler(function()
					if (stepSingleFrameButtonToggle.hoverState ~= BTN_DN) then
						play_haptics(0.6, HAPTICS.SELECTION)
					end
					stepSingleFrameButtonToggle.hoverState = BTN_DN
				end)
				stepSingleFrameButtonToggle:addMouseUpHandler(function()
					self.StepSingleFrame = not self.StepSingleFrame
				end)
			end
		end)

	-- This button shouldn't always be available, attach a handler for it
	table.insert(self.ButtonsToRefresh, {
		button = commitStepButtonHolder,
		shouldBeDisplayed = TBHudInternal.isPlaying
	})
end

function TBHud.ResetCameraButtonPositions()
	TBHud.CameraButtonHolder:moveTo(TBHud.DefaultSmallerButtonSize * 1.7, -TBHud.DefaultSmallerButtonSize * 1.5)
	TBHud.CameraJoystickFreeHolder:moveTo(TBHud.DefaultSmallerButtonSize * 2.35, -TBHud.DefaultSmallerButtonSize * 3.8)
end

function TBHud:spawnCameraButtons()
	if (self.MainElement == nil) then return end

	local cameraButtonHolder = self.MainElement:addChild({
		pos = { self.DefaultSmallerButtonSize * 1.7, -self.DefaultSmallerButtonSize * 1.5 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	self.CameraButtonHolder = cameraButtonHolder
	local cameraButton = TBHudInternal.generateTouchButton(cameraButtonHolder, "../textures/menu/general/buttons/camera.tga")

	local cameraKeyframeButtonHolder = self.MainElement:addChild({
		pos = { self.DefaultSmallerButtonSize * 1.05, -self.DefaultSmallerButtonSize * 2.6 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	self.CameraKeyframeButtonHolder = cameraKeyframeButtonHolder
	local cameraKeyframeButton = TBHudInternal.generateTouchButton(cameraKeyframeButtonHolder, "../textures/menu/general/buttons/keyframenew.tga")
	cameraKeyframeButton:addMouseUpHandler(function()
			save_camera_keyframe()
		end)

	local cameraKeyframeEditButtonHolder = self.MainElement:addChild({
		pos = { self.DefaultSmallerButtonSize * 2.35, -self.DefaultSmallerButtonSize * 2.6 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	self.CameraKeyframeEditButtonHolder = cameraKeyframeEditButtonHolder
	local cameraKeyframeEditButton = TBHudInternal.generateTouchButton(cameraKeyframeEditButtonHolder, "../textures/menu/general/buttons/keyframeedit.tga")
	cameraKeyframeEditButton:hide()

	local clickClock = 0
	cameraButton:addMouseDownHandler(function() clickClock = os.clock_real() end)
	cameraButton:addMouseUpHandler(function()
		clickClock = 0
		if (get_camera_mode() ~= CAMERA_MODE.DEFAULT) then
			set_camera_mode(CAMERA_MODE.DEFAULT)
			return
		end
		runCmd("zp " .. (self.WorldState.selected_player + 1) % self.WorldState.num_players)
		enable_mouse_camera_movement()
	end)
	cameraButton:addCustomDisplay(function()
		if (not TUTORIAL_ISACTIVE and self.WorldState.replay_mode ~= 0 and not self.CameraKeyframeButtonHolder:isDisplayed()) then
			self.CameraKeyframeButtonHolder:show()
		elseif ((TUTORIAL_ISACTIVE or self.WorldState.replay_mode == 0) and self.CameraKeyframeButtonHolder:isDisplayed()) then
			self.CameraKeyframeButtonHolder:hide()
			self.CameraKeyframeEditButtonHolder:hide()
		end

		if (clickClock > 0 and UIElement.clock - clickClock > UIElement.longPressDuration) then
			disable_mouse_camera_movement()
			play_haptics(0.2, HAPTICS.IMPACT)
			clickClock = 0
			local optionsHolder = cameraButtonHolder:addChild({
				pos = { 0, -cameraButton.size.h * 3.6 },
				size = { cameraButton.size.w * 3, cameraButton.size.h * 2.5 },
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

			local cameraButtons = {
				{ name = TB_MENU_LOCALIZED.CAMERAUKE, mode = CAMERA_MODE.UKE },
				{ name = TB_MENU_LOCALIZED.CAMERATORI, mode = CAMERA_MODE.TORI },
				{ name = TB_MENU_LOCALIZED.CAMERAFREE, mode = CAMERA_MODE.FREE },
				{ name = TB_MENU_LOCALIZED.CAMERADEFAULT, mode = CAMERA_MODE.DEFAULT }
			}
			local buttonHeight = (optionsHolder.size.h - 2) / #cameraButtons
			local activeMode = get_camera_mode()
			for i, v in pairs(cameraButtons) do
				local button = optionsHolder:addChild({
					pos = { 2, 2 + (i - 1) * buttonHeight },
					size = { optionsHolder.size.w - 4, buttonHeight - 2 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
					hoverThrough = true,
					clickThrough = true
				}, true)
				button:addAdaptedText(v.name, nil, nil, FONTS.LMEDIUM, nil, 0.7)
				if (activeMode == v.mode) then
					button:deactivate()
				else
					button:addCustomDisplay(function()
						if (not (
							MOUSE_X >= button.pos.x and MOUSE_X <= button.pos.x + button.size.w and
							MOUSE_Y >= button.pos.y and MOUSE_Y <= button.pos.y + button.size.h)) then
							button.hoverState = BTN_NONE
						end
					end, true)
					button:addMouseMoveHandler(function()
						if (button.hoverState ~= BTN_DN) then
							play_haptics(0.6, HAPTICS.SELECTION)
						end
						button.hoverState = BTN_DN
					end)
					button:addMouseUpHandler(function() set_camera_mode(v.mode) end)
				end
			end
		end
	end)
	local cameraFreeJoystickHolder = self.MainElement:addChild({
		pos = { self.DefaultSmallerButtonSize * 2.35, -self.DefaultSmallerButtonSize * 3.8 },
		size = { self.DefaultSmallerButtonSize * 2.25, self.DefaultSmallerButtonSize * 2.25 }
	})
	self.CameraJoystickFreeHolder = cameraFreeJoystickHolder
	local cameraJoystickBackground = TBHudInternal.generateTouchButton(cameraFreeJoystickHolder)
	cameraJoystickBackground:deactivate()
	local cameraJoystick = cameraJoystickBackground:addChild({
		shift = { self.DefaultSmallerButtonSize * 0.6, self.DefaultSmallerButtonSize * 0.6 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = ROUNDED,
		rounded = cameraJoystickBackground.size.w
	})

	local defaultPos = table.clone(cameraJoystick.shift)
	local joystickOffset = cameraJoystick.size.w / 2
	local joystickBackgroundHalfWidth = cameraJoystickBackground.size.w / 2
	local joystickMaxMagnitude = cameraJoystickBackground.size.w / 3
	local joystickVector = Vector2.New()
	local mouseDownPosition = { x = 0, y = 0 }

	local function onJoystickUp()
		if (defaultPos ~= nil) then
			cameraJoystick:moveTo(defaultPos.x, defaultPos.y)
		end
		joystickVector.x = 0
		joystickVector.y = 0
		remove_hooks(TBHud.HookNameCamera)
		enable_mouse_camera_movement()
	end
	cameraJoystick:addMouseUpHandler(onJoystickUp)
	cameraJoystick:addMouseUpOutsideHandler(onJoystickUp)

	---@param cameraPos Vector3Base
	---@param cameraLookat Vector3Base
	---@return Vector3
	---@return Vector3
	---@return Vector3
	local function getCameraVectors(cameraPos, cameraLookat)
		local front = Vector3.New(
			cameraLookat.x - cameraPos.x,
			cameraLookat.y - cameraPos.y,
			cameraLookat.z - cameraPos.z
		)
		local side = Vector3.New(front.y, -front.x):normalize()
		local up = front:cross(side):normalize()
		return front, side, up
	end

	cameraJoystick:addMouseDownHandler(function()
			disable_mouse_camera_movement()
			mouseDownPosition = cameraJoystick:getLocalPos(MOUSE_X, MOUSE_Y)
			mouseDownPosition.x = mouseDownPosition.x - joystickOffset
			mouseDownPosition.y = mouseDownPosition.y - joystickOffset

			add_hook("touch_fingermotion_ignore", TBHud.HookNameCamera, function() return 1 end)
			add_hook("camera", TBHud.HookNameCamera, function()
					local cameraInfo = get_camera_info()
					local cameraPos = Vector3.New(cameraInfo.pos.x, cameraInfo.pos.y, cameraInfo.pos.z)
					local cameraLookat = Vector3.New(cameraInfo.lookat.x, cameraInfo.lookat.y, cameraInfo.lookat.z)
					local _, side, up = getCameraVectors(cameraPos, cameraInfo.lookat)
					local moveVector = side:multiply(-joystickVector.x * self.CameraJoystickSensitivity):add(up:multiply(-joystickVector.y * self.CameraJoystickSensitivity))
					local newPos = cameraPos:add(moveVector)
					local newLookat = cameraLookat:add(moveVector)
					set_camera_lookat(newLookat.x, newLookat.y, newLookat.z)
					set_camera_pos(newPos.x, newPos.y, newPos.z)
				end)
		end)
	cameraJoystick:addMouseMoveHandler(function()
			if (cameraJoystick.hoverState == BTN_DN) then
				local mousePos = cameraJoystickBackground:getLocalPos(MOUSE_X - mouseDownPosition.x, MOUSE_Y - mouseDownPosition.y)
				joystickVector.x = joystickBackgroundHalfWidth - mousePos.x
				joystickVector.y = joystickBackgroundHalfWidth - mousePos.y
				local magnitude = math.sqrt(joystickVector.x * joystickVector.x + joystickVector.y * joystickVector.y)
				if magnitude > joystickMaxMagnitude then
					local scaleFactor = joystickMaxMagnitude / magnitude
					joystickVector.x = joystickVector.x * scaleFactor
					joystickVector.y = joystickVector.y * scaleFactor
				end
				mousePos.x = joystickBackgroundHalfWidth - joystickVector.x - joystickOffset
				mousePos.y = joystickBackgroundHalfWidth - joystickVector.y - joystickOffset
				if (mousePos.x < 0) then
					mousePos.x = mousePos.x - cameraJoystickBackground.size.w
				end
				if (mousePos.y < 0) then
					mousePos.y = mousePos.y - cameraJoystickBackground.size.h
				end
				joystickVector = joystickVector:multiply(1 / joystickBackgroundHalfWidth)
				cameraJoystick:moveTo(mousePos.x, mousePos.y)
			end
		end)

	cameraFreeJoystickHolder:addCustomDisplay(true, function()
			local cameraMode = get_camera_mode()
			if (cameraMode == CAMERA_MODE.FREE and not cameraJoystickBackground:isDisplayed()) then
				cameraJoystickBackground:show()
				cameraKeyframeEditButton:hide()
			elseif (cameraMode ~= CAMERA_MODE.FREE and cameraJoystickBackground:isDisplayed()) then
				cameraJoystickBackground:hide()
			end
		end)
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
			local ghost_mode = get_ghost()
			if (self.WorldState.selected_player == -1) then
				if (ghost_mode == 2) then
					set_ghost(0)
					return
				end
				set_ghost(2)
				return
			end
			set_ghost((ghost_mode + 1) % 3)
		end)
end

function TBHud:spawnHoldRelaxAllButton()
	if (self.MainElement == nil) then return end

	local holdRelaxAllButtonHolder = self.MainElement:addChild({
		pos = { -self.DefaultButtonSize * 2.9, -self.DefaultSmallerButtonSize * 2.7 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	self.HoldAllButtonHolder = holdRelaxAllButtonHolder

	local holdAll = false
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
	holdAllText:addAdaptedText(TB_MENU_LOCALIZED.MOBILEHUDHOLDALL, nil, nil, FONTS.LMEDIUM, nil, 0.5)
	holdRelaxAllButton:addMouseUpHandler(function()
		for _, v in pairs(JOINTS) do
			set_joint_state(self.WorldState.selected_player, v, holdAll and JOINT_STATE.HOLD or JOINT_STATE.RELAX, true)
		end
	end)
	local function toggleButtonsDisplay(state)
		if (state == holdAll) then return end
		holdAll = state
		holdAllText:setVisible(holdAll)
		relaxAllText:setVisible(not holdAll)
	end
	toggleButtonsDisplay(true)
	holdRelaxAllButtonHolder:addCustomDisplay(true, function()
		local shouldBeDisplayed = players_accept_input()
		if (shouldBeDisplayed and not holdRelaxAllButton:isDisplayed()) then
			holdRelaxAllButton:show()
		elseif (not shouldBeDisplayed and holdRelaxAllButton:isDisplayed()) then
			holdRelaxAllButton:hide()
		end
		if (holdRelaxAllButton:isDisplayed() and self.WorldState.selected_player > -1) then
			for _, v in pairs(JOINTS) do
				if (get_joint_info(self.WorldState.selected_player, v).state == JOINT_STATE.HOLD) then
					toggleButtonsDisplay(false)
					break
				end
				toggleButtonsDisplay(true)
			end
		end
	end)
end

function TBHud:spawnRewindButton()
	if (self.MainElement == nil) then return end

	local rewindButtonHolder = self.MainElement:addChild({
		pos = { -self.DefaultButtonSize * 1.2, -self.DefaultSmallerButtonSize * 2.7 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	table.insert(self.MiscButtonHolders, rewindButtonHolder)
	local rewindButton = TBHudInternal.generateTouchButton(rewindButtonHolder, "../textures/menu/general/buttons/reload.tga", nil, 0.8)
	rewindButton:addMouseUpHandler(function()
		if (TUTORIAL_ISACTIVE) then
			call_hook("key_up", 114, 21)
		else
			rewind_replay()
		end
	end)
	table.insert(self.ButtonsToRefresh, {
		button = rewindButtonHolder,
		shouldBeDisplayed = function() return self.WorldState.game_type == 0 end
	})
end

function TBHud:spawnPauseButton()
	if (self.MainElement == nil) then return end

	local pauseButtonHolder = self.MainElement:addChild({
		pos = { -self.DefaultButtonSize * 2.05, -self.DefaultSmallerButtonSize * 3.15 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	table.insert(self.MiscButtonHolders, pauseButtonHolder)
	local pauseButton = TBHudInternal.generateTouchButton(pauseButtonHolder, "../textures/menu/general/buttons/playpause.tga", { x = 0, y = 0, w = 128, h = 128 }, 0.8)
	local clickClock = 0
	pauseButton:addMouseDownHandler(function()
		clickClock = os.clock_real()
	end)
	pauseButton:addMouseUpHandler(function()
		clickClock = 0
		if (TUTORIAL_ISACTIVE) then
			call_hook("key_up", 112, 19)
		else
			toggle_game_pause(self.StepSingleFramePause)
		end
	end)
	table.insert(self.ButtonsToRefresh, {
		button = pauseButtonHolder,
		shouldBeDisplayed = function() return self.WorldState.game_type == 0 and self.WorldState.replay_mode > 0 end
	})
	pauseButtonHolder:addCustomDisplay(true, function()
			local gamePaused = is_game_paused()
			pauseButton.icon.atlas.x = gamePaused and (self.StepSingleFramePause and pauseButton.icon.atlas.w * 2 or 0) or pauseButton.icon.atlas.w
			if (gamePaused and (not TUTORIAL_ISACTIVE or TBHudInternal.PauseLongPressEnabled)) then
				if (clickClock > 0 and UIElement.clock - clickClock > UIElement.longPressDuration) then
					disable_mouse_camera_movement()
					play_haptics(0.2, HAPTICS.IMPACT)
					clickClock = 0
					local optionsHolder = pauseButtonHolder:addChild({
						pos = { -self.DefaultButtonSize * 1.3 - self.DefaultSmallerButtonSize * 0.5, -self.DefaultButtonSize - self.DefaultSmallerButtonSize },
						size = { self.DefaultButtonSize * 2.6, self.DefaultButtonSize * 0.9 },
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
					}):addAdaptedText(self.StepSingleFramePause and TB_MENU_LOCALIZED.HUDRESUMEREPLAY or TB_MENU_LOCALIZED.HUDSTEPFRAMESINGLE, nil, nil, FONTS.LMEDIUM, nil, 0.7)
					stepSingleFrameButton:addMouseMoveHandler(function()
						if (stepSingleFrameButton.hoverState ~= BTN_DN) then
							play_haptics(0.6, HAPTICS.SELECTION)
						end
						stepSingleFrameButton.hoverState = BTN_DN
					end)
					stepSingleFrameButton:addMouseUpHandler(function()
						toggle_game_pause(not self.StepSingleFramePause)
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
					TBMenu:showTextWithImage(stepSingleFrameButtonToggle:addChild({ shift = { 10, 3 } }), TB_MENU_LOCALIZED.HUDSTEPSINGLETOGGLE, FONTS.LMEDIUM, iconScale, self.StepSingleFramePause and "../textures/menu/general/buttons/checkmark.tga" or "../textures/menu/general/buttons/crosswhite.tga", { maxTextScale = 0.7 })
					stepSingleFrameButtonToggle:addMouseMoveHandler(function()
						if (stepSingleFrameButtonToggle.hoverState ~= BTN_DN) then
							play_haptics(0.6, HAPTICS.SELECTION)
						end
						stepSingleFrameButtonToggle.hoverState = BTN_DN
					end)
					stepSingleFrameButtonToggle:addMouseUpHandler(function()
						self.StepSingleFramePause = not self.StepSingleFramePause
					end)
				end
			end
		end)
end

function TBHudInternal.editGame()
	edit_game()
	TBHudInternal.refreshButtons()
end

function TBHud:spawnEditButton()
	if (self.MainElement == nil) then return end

	local editButtonHolder = self.MainElement:addChild({
		pos = { -self.DefaultButtonSize * 2.9, -self.DefaultSmallerButtonSize * 2.7 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	table.insert(self.MiscButtonHolders, editButtonHolder)
	local editButton = TBHudInternal.generateTouchButton(editButtonHolder, "../textures/menu/general/buttons/edit.tga", nil, 0.6)
	editButton:addMouseUpHandler(function()
		if (TUTORIAL_ISACTIVE) then
			call_hook("key_up", 101, 8)
			TBHudInternal.refreshButtons()
		else
			TBHudInternal.editGame()
		end
	end)
	table.insert(self.ButtonsToRefresh, {
		button = editButtonHolder,
		shouldBeDisplayed = function() return self.WorldState.game_type == 0 and self.WorldState.replay_mode > 0 end
	})
end

function TBHud:spawnCancelMoveButton()
	if (self.MainElement == nil) then return end

	local cancelMoveButtonHolder = self.MainElement:addChild({
		pos = { -self.DefaultButtonSize * 1.2, -self.DefaultSmallerButtonSize * 2.7 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	local cancelMoveButton = TBHudInternal.generateTouchButton(cancelMoveButtonHolder, "../textures/menu/general/buttons/undo.tga", nil, 0.6)
	cancelMoveButton:addMouseHandlers(undo_move_changes)
	table.insert(self.ButtonsToRefresh, {
		button = cancelMoveButtonHolder,
		shouldBeDisplayed = function()
			return players_accept_input() and self.WorldState.game_type == 1 and self.WorldState.replay_mode == 0 and TBHudInternal.isPlaying()
		end
	})
end

function TBHud:spawnGripButton()
	if (self.MainElement == nil) then return end

	local gripButtonHolder = self.MainElement:addChild({
		pos = { -self.DefaultButtonSize * 2.05, -self.DefaultSmallerButtonSize * 3.15 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	self.GripButtonHolder = gripButtonHolder
	local gripButton = TBHudInternal.generateTouchButton(gripButtonHolder, "../textures/menu/general/buttons/grip.tga", nil, 0.8)
	gripButton:addMouseUpHandler(function()
			if (self.WorldState.selected_player == -1) then return end
			local gripState = 1 - math.max(
				get_grip_info(self.WorldState.selected_player, BODYPARTS.L_HAND),
				get_grip_info(self.WorldState.selected_player, BODYPARTS.R_HAND)
			)
			set_grip_info(self.WorldState.selected_player, BODYPARTS.L_HAND, gripState)
			set_grip_info(self.WorldState.selected_player, BODYPARTS.R_HAND, gripState)

			--We also need to manually reset ghost as set_grip_info doesn't do that
			local ghost_mode = get_ghost()
			if (ghost_mode ~= 0) then
				set_ghost(0)
				set_ghost(ghost_mode)
			end
		end)

	gripButtonHolder:addCustomDisplay(true, function()
			local shouldBeDisplayed = players_accept_input()
			if (shouldBeDisplayed and not gripButton:isDisplayed()) then
				gripButton:show()
			elseif (not shouldBeDisplayed and gripButton:isDisplayed()) then
				gripButton:hide()
			end
		end)
end

---Sets the `TutorialHubOverride` function or resets it
---@param func function|nil
function TBHud.SetTutorialHubOverride(func)
	TBHudInternal.TutorialHubOverride = func
end

function TBHud:spawnHubButton()
	if (self.MainElement == nil) then return end

	local settingsButtonHolder = self.MainElement:addChild({
		pos = { -self.DefaultSmallerButtonSize * 1.4, -self.DefaultSmallerButtonSize * 1.5 },
		size = { self.DefaultSmallerButtonSize, self.DefaultSmallerButtonSize }
	})
	self.HubButtonHolder = settingsButtonHolder
	TBHudInternal.generateTouchButton(settingsButtonHolder, "../textures/menu/general/buttons/options.tga"):addMouseUpHandler(function()
		if (TUTORIAL_ISACTIVE) then
			if (TBHudInternal.TutorialHubOverride ~= nil) then
				TBHudInternal.TutorialHubOverride()
			else
				open_menu(19)
			end
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
---@param override boolean?
function TBHud:reloadHubDynamicButtons(override)
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
	if (self.HubDynamicState ~= nil and not override) then
		if (self.HubDynamicState.game_type == self.WorldState.game_type and
			self.HubDynamicState.replay_mode == self.WorldState.replay_mode and
			table.equals(self.HubDynamicState.PlayerInfo or {}, playerInfo or {})) then
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
		},
		{
			title = TB_MENU_LOCALIZED.MOBILEHUDSAVEMOD,
			icon = {
				filename = "../textures/menu/general/buttons/download.tga"
			},
			action = function()
				local modname = get_gamerule("mod")
				modname = utf8.gsub(modname, ".*[\\/]", "")
				if (export_mod("data/mod/downloads/" .. modname)) then
					TBMenu:showStatusMessage(modname .. " " .. TB_MENU_LOCALIZED.MOBILEHUDSAVEMODSUCCESS)
				else
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MOBILEHUDSAVEMODFAILURE .. " " .. modname)
				end
			end,
			displayCondition = function()
				if (self.WorldState.game_type == 1) then return false end
				local firstSymbol = utf8.sub(get_gamerule("mod"), 0, 1)
				return firstSymbol == '/' or firstSymbol == "\\"
			end
		}
	}

	local featuredMoves = MoveMemory:getSuggestedMoves()
	---Insert two featured moves max at first positions in the list
	for i = 1, math.min(#featuredMoves, 2) do
		table.insert(buttonOptions, i, {
			title = featuredMoves[i].name,
			icon = {
				filename = "../textures/menu/general/movememory_icon.tga"
			},
			action = function() MoveMemory:playMove(featuredMoves[i], true) end,
			displayCondition = players_accept_input
		})
	end

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
		pos = { -self.HubSize.w - SAFE_X, 0 },
		size = { self.HubSize.w + SAFE_X, self.HubSize.h },
		bgColor = { 1, 1, 1, 0.7 },
		interactive = true
	})
	local hubMainHolder = hubBackground:addChild({
		pos = { 0, 0 },
		size = { self.HubSize.w, self.HubSize.h }
	})
	local topRowButtons = {
		{
			title = TB_MENU_LOCALIZED.MOVEMEMORYTITLE,
			image = "../textures/menu/general/movememory_icon.tga",
			action = function() if (MoveMemory.MainElement == nil) then MoveMemory:showMain() else MoveMemory.Quit() end end
		},
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
		pos = { 10, math.max(SAFE_Y, 20) },
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
		---Button icon, display it slightly above center so that it gets overlayed by text a bit less
		buttonElement:addChild({
			pos = { 10, 2 },
			size = { buttonElement.size.w - 20, buttonElement.size.h - 20 },
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
		pos = { 10, -50 - math.max(SAFE_Y, 20) },
		size = { hubMainHolder.size.w - 20, 50 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 5
	})
	mainMenuButton:addChild({ shift = { 10, 5 }}):addAdaptedText("> " .. TB_MENU_LOCALIZED.MOBILEHUDTOMAINMENU)
	mainMenuButton:addMouseUpHandler(function() open_menu(19) self:toggleHub(false) end)

	local middleSectionHolder = hubMainHolder:addChild({
		pos = { topButtonsHolder.shift.x, topButtonsHolder.shift.y + topButtonsHolder.size.h + 20 },
		size = { topButtonsHolder.size.w, hubMainHolder.size.h - (topButtonsHolder.shift.y + topButtonsHolder.size.h + 20) - (mainMenuButton.size.h + 20 + math.max(SAFE_Y, 20)) }
	})
	self.HubDynamicButtonsHolder = middleSectionHolder
	self:reloadHubDynamicButtons()

	self.HubHolder:hide(true)
end

---Toggles right hub menu on or off
---@param state boolean
function TBHud:toggleHub(state)
	if (state == true) then
		self:reloadHubDynamicButtons(true)
		self.HubHolder:show(true)
	end

	local clock = UIElement.clock
	if (state == true) then
		self.HubHolder:moveTo(self.HubSize.w)
	end
	self.HubHolder:addCustomDisplay(true, function()
		local tweenValue = (UIElement.clock - clock) * 6
		if (state) then
			self.HubHolder:moveTo(UITween.SineTween(self.HubHolder.pos.x, 0, tweenValue))
		else
			self.HubHolder:moveTo(UITween.SineTween(self.HubHolder.pos.x, self.HubSize.w + SAFE_X, tweenValue))
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
---@field cmd string|string[] Base command string
---@field info string Example command displayed in UI
---@field regex string Regex expression to match input against
---@field replacement string String to replace with
---@field autoSubmit boolean? Whether this command can be auto submitted upon selection from suggestions
---@field submitCmdMatch boolean? Whether this command should stop being suggested after it gets input arguments
---@field typeCommandRegex string? Custom regex used for matching chat input
---@field requireOperator boolean? Whether this command requires op in multiplayer
---@field requireOnline boolean? Whether this is a multiplayer only command
---@field requireFighter boolean? Whether this command is only available to active fighters

---Returns the list of chat commands data that will be used for chat autofilling
---@return HudChatCommand[]
function TBHud:getChatCommands()
	return {
		{
			cmd = "set",
			info = "/set %125- list all gamerules",
			regex = "^(/%w+).*",
			replacement = "/set",
			submitCmdMatch = true,
			autoSubmit = true
		},
		{
			cmd = "set",
			info = "/set ^38gamerule ^47[value] %125- view or set new gamerule value",
			regex = "^(/%w+) ?(%w*) ?(%w*).*",
			replacement = "/set %2 %3",
			requireOperator = true
		},
		{
			cmd = "opt",
			info = "/opt ^38option ^47[value] %125- view or set new option value",
			regex = "^(/%w+) ?(%w*) ?(%w*).*",
			replacement = "/opt %2 %3"
		},
		{
			cmd = "spectate",
			info = "/spec %125- join spectators",
			regex = "^(/%w+).*",
			replacement = "/sp",
			submitCmdMatch = true,
			autoSubmit = true,
			requireOnline = true
		},
		{
			cmd = "enter",
			info = "/enter %125- enter fighting queue",
			regex = "^(/%w+).*",
			replacement = "/en",
			submitCmdMatch = true,
			autoSubmit = true,
			requireOnline = true
		},
		{
			cmd = "emote",
			info = "/emote ^47message %125- display emote message",
			regex = "^(/%w+) ?(.*)",
			replacement = "/emote %2",
			requireFighter = true
		},
		{
			cmd = "join",
			info = "/join ^47roomname %125- join a multiplayer room",
			regex = "^(/%w+) ?(.*)",
			replacement = "/join %2",
		},
		{
			cmd = { "dl", "download" },
			info = "/dl ^47username %125- download player's custom tori",
			regex = "^(/%w+) ?([^%. ]*).*",
			replacement = "/dl %2",
		},
		{
			cmd = { "dl", "download" },
			info = "/dl ^47modname.tbm %125- download a custom mod",
			regex = "^(/%w+) ?([^%. ]*).*",
			replacement = "/dl %2.tbm",
		},
		{
			cmd = { "rt", "reset" },
			info = "/reset %125- reset and restart current fight",
			regex = "^(/%w+).*",
			replacement = "/rt",
			submitCmdMatch = true,
			autoSubmit = true,
			requireOperator = true
		},
		{
			cmd = { "lm", "loadmod" },
			info = "/loadmod ^47modname %125- load a game mod and restart fight",
			regex = "^(/%w+) ?([^%. ]*).*",
			replacement = "/lm %2",
			requireOperator = true
		},
		{
			cmd = { "lp", "loadplayer" },
			info = "/loadplayer ^38id ^47username %125- load user's customs for specified player",
			regex = "^(/%w+) ?(%d*) ?(%w*).*",
			replacement = "/lp %2 %3"
		},
		{
			cmd = "bet",
			info = "/bet ^38amount ^47username %125- bet TC on player's victory in current fight",
			regex = "^(/%w+) ?(%d*) ?(%w*).*",
			replacement = "/bet %2 %3",
			requireOnline = true
		},
		{
			cmd = "bets",
			info = "/bet %125- show all active bets",
			regex = "^(/%w+).*",
			replacement = "/bets",
			requireOnline = true,
			submitCmdMatch = true,
			autoSubmit = true
		},
		{
			cmd = "passwd",
			info = "/pass ^47password %125- enter a password protected room",
			regex = "^(/%w+) ?(.*)",
			replacement = "/pass %2",
			requireOnline = true
		},
		{
			cmd = "decapprize",
			info = "/decappize ^47amount %125- add TC to current decap prize",
			regex = "^(/%w+) ?(%d*).*",
			replacement = "/decapprize %2",
			requireOnline = true
		},
		{
			cmd = "dismemberprize",
			info = "/dismemberprize ^47amount %125- add TC to current dismember prize",
			regex = "^(/%w+) ?(%d*).*",
			replacement = "/dismemberprize %2",
			requireOnline = true
		},
		{
			cmd = "motd",
			info = "/motd ^47message %125- set room welcome message",
			regex = "^(/%w+) ?(.*)",
			replacement = "/motd %2",
			requireOnline = true
		},
		{
			cmd = "desc",
			info = "/desc ^47message %125- set room description for room list",
			regex = "^(/%w+) ?(.*)",
			replacement = "/desc %2",
			requireOnline = true
		},
		{
			cmd = "vip add",
			info = "/vip add ^47username %125- add player to room's vip list",
			regex = "^(/%w+) ?[ad]* ?(.*)",
			typeCommandRegex = "^/(%w+ ?%w*).*",
			replacement = "/vip add %2",
			requireOnline = true
		},
		{
			cmd = "vip del",
			info = "/vip del ^47username %125- remove player from room's vip list",
			regex = "^(/%w+) ?[del]* ?(.*)",
			typeCommandRegex = "^/(%w+ ?%w*).*",
			replacement = "/vip del %2",
			requireOnline = true
		},
		{
			cmd = "vip list",
			info = "/vip list %125- show vip list for current room",
			regex = "^(/%w+).*",
			typeCommandRegex = "^/(%w+ ?%w*).*",
			replacement = "/vip list",
			requireOnline = true,
			autoSubmit = true
		},
		{
			cmd = "vip clear",
			info = "/vip clear %125- clear current room's vip list",
			regex = "^(/%w+).*",
			typeCommandRegex = "^/(%w+ ?%w*).*",
			replacement = "/vip clear",
			requireOnline = true
		},
		{
			cmd = "clanvip add",
			info = "/clanvip add ^47clan %125- add clan to room's vip list",
			regex = "^(/%w+) ?[ad]* ?(.*)",
			typeCommandRegex = "^/(%w+ ?%w*).*",
			replacement = "/clanvip add %2",
			requireOnline = true
		},
		{
			cmd = "clanvip del",
			info = "/clanvip del ^47username %125- remove clan from room's vip list",
			regex = "^(/%w+) ?[del]* ?(.*)",
			typeCommandRegex = "^/(%w+ ?%w*).*",
			replacement = "/clanvip del %2",
			requireOnline = true
		},
		{
			cmd = "clanvip list",
			info = "/clanvip list %125- show clan vip list for current room",
			regex = "^(/%w+).*",
			typeCommandRegex = "^/(%w+ ?%w*).*",
			replacement = "/clanvip list",
			requireOnline = true,
			autoSubmit = true
		},
		{
			cmd = "clanvip clear",
			info = "/clanvip clear %125- clear current room's clan vip list",
			regex = "^(/%w+).*",
			typeCommandRegex = "^/(%w+ ?%w*).*",
			replacement = "/clanvip clear",
			requireOnline = true
		},
		{
			cmd = "viponly",
			info = "/viponly ^47on|off %125- toggle whether current room's vip only status",
			regex = "^(/%w+) ?(.*)",
			replacement = "/viponly %2",
			requireOnline = true
		},
		{
			cmd = "duel start",
			info = "/duel start ^47amount %125- enable duel mode with a specified wager",
			regex = "^(/%w+) ?[star]* ?(%d*).*",
			typeCommandRegex = "^/(%w+ ?%w*).*",
			replacement = "/duel start %2",
			requireOnline = true,
			requireOperator = true
		},
		{
			cmd = "duel stop",
			info = "/duel stop %125- disable duel mode",
			regex = "^(/%w+).*",
			typeCommandRegex = "^/(%w+ ?%w*).*",
			replacement = "/duel stop",
			requireOnline = true,
			requireOperator = true
		},
		{
			cmd = "duel earnings",
			info = "/duel earnings %125- show your earnings in this dueling session",
			regex = "^(/%w+).*",
			typeCommandRegex = "^/(%w+ ?%w*).*",
			replacement = "/duel earnings",
			requireOnline = true,
			autoSubmit = true
		},
		{
			cmd = "duel status",
			info = "/duel status %125- show your earnings in this dueling session",
			regex = "^(/%w+).*",
			typeCommandRegex = "^/(%w+ ?%w*).*",
			replacement = "/duel status",
			requireOnline = true,
			autoSubmit = true
		},
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
	self.ChatButtonHolderBadge = chatButton:addChild({
		pos = { chatButton.size.w * 0.66, -chatButton.size.h - chatButton.size.h * 0.125 },
		size = { chatButton.size.w * 0.5, chatButton.size.h / 3 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = chatButton.size.h / 4
	})
	self.ChatButtonHolderBadge:hide(true)

	chatButtonHolder:addCustomDisplay(function()
		if (self.ChatHolder ~= nil) then
			if (chatButton:isActive() and self.ChatHolder:isDisplayed()) then
				chatButton:setActive(false)
			elseif (not chatButton:isActive() and not self.ChatHolder:isDisplayed()) then
				chatButton:setActive(true)
				self:setChatNotification()
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

---Sets chat notification in case there are unread tabs
function TBHud:setChatNotification()
	local notifications = 0
	for i, v in pairs(self.ChatTabItems) do
		if (type(i) == "number" and v.hasUnread) then
			notifications = notifications + 1
		end
	end
	if (notifications > 0) then
		self.ChatButtonHolderBadge:show(true)
		self.ChatButtonHolderBadge:addAdaptedText(tostring(notifications))
	else
		self.ChatButtonHolderBadge:hide(true)
	end
end

---Switches from the active chat tab to the specified one
---@param tab integer
function TBHud:switchChatTab(tab)
	if (self.ChatActiveTab == tab) then return end

	---We must preserve the original child table as it's being referenced by scrollable list code!
	---Clean it properly instead of just resetting it to a new empty table
	for i = #self.ChatHolderListing.child, 1, -1 do
		self.ChatHolderListing.child[i]:hide(true)
		table.remove(self.ChatHolderListing.child, i)
	end

	TBHudInternal.ListShift[1] = 0

	self.ChatTabItems[self.ChatActiveTab].imageColor = table.clone(UICOLORWHITE)
	self.ChatTabItems[tab].imageColor = table.clone(TB_MENU_DEFAULT_BG_COLOR_TRANS)
	self.ChatTabItems[tab].hasUnread = false
	self.ChatActiveTab = tab

	self:refreshChat()
end

---@class TBHudTabButton : UIElement
---@field hasUnread boolean
---@field outline UIElement
---@field legend UIElement

---Spawns a chat tab button for the specified tab id
---@param tab integer
---@return TBHudTabButton
function TBHud:spawnChatTabButton(tab)
	---@type TBHudTabButton
	---@diagnostic disable-next-line: assign-type-mismatch
	local tabButton = self.ChatTabHolder:addChild({
		pos = { 0, table.size(self.ChatTabItems) * self.ChatTabWidth },
		size = { SAFE_X + self.ChatTabWidth, self.ChatTabWidth },
		interactive = true,
		bgGradient = { UICOLORWHITE, { 1, 1, 1, 0 } },
		bgGradientMode = BODYPARTS.L_THIGH,
		imageColor = UICOLORWHITE,
		imageHoverColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		imagePressedColor = TB_MENU_DEFAULT_BG_COLOR_TRANS
	})
	local tabButtonOutline = tabButton:addChild({
		pos = { SAFE_X + 5, 5 },
		size = { tabButton.size.h - 10, tabButton.size.h - 10 },
		bgColor = UICOLORWHITE,
		shapeType = ROUNDED,
		rounded = self.ChatTabWidth
	})
	local tabPlayerHeadHolder = tabButton:addChild({
		pos = { SAFE_X + 5, 5 },
		size = { tabButton.size.h - 10, tabButton.size.h - 10 }
	})
	local playerInfo = PlayerInfo.Get(get_chat_tab_name(tab))
	local tabName = playerInfo.username
	TBMenu:showPlayerHeadAvatar(tabPlayerHeadHolder, tabName)

	local tabLegend = tabButton:addChild({
		pos = { SAFE_X + self.ChatTabWidth, 0 },
		size = { self.ChatTabWidth * 3, self.ChatTabWidth }
	})
	tabLegend:addAdaptedText(tabName, nil, nil, 4, LEFTMID, 1, 1)
	local tabCloseButton = tabLegend:addChild({
		pos = { tabLegend.size.w + self.ChatTabWidth * 0.25, self.ChatTabWidth * 0.05 },
		size = { self.ChatTabWidth * 0.7, self.ChatTabWidth * 0.7 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
		hoverColor = UICOLORRED,
		pressedColor = UICOLORRED,
		shapeType = ROUNDED,
		rounded = self.ChatTabWidth * 0.2
	})
	tabCloseButton:addChild({
		shift = { 5, 5 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})
	tabCloseButton:addMouseUpHandler(function()
		self:destroyChatTabButton(tab)
	end)

	tabButton.outline = tabButtonOutline
	tabButton.legend = tabLegend
	tabButton.hasUnread = true

	if (self.ChatTabItems.extendButton.__extendState) then
		tabButton.size.w = self.ChatTabItems[0].size.w
		tabButton.outline.size.w = tabButton.size.w - 10
	else
		tabLegend:hide(true)
	end

	tabButton:addMouseUpHandler(function()
			self:switchChatTab(tab)
		end)

	if (self.ChatTabItems[tab] ~= nil) then
		self.ChatTabItems[tab]:kill()
	end
	self.ChatTabItems[tab] = tabButton
	return tabButton
end

---Destroys chat tab button, performs cleanup and reorders remaining items
---@param tab integer
function TBHud:destroyChatTabButton(tab)
	if (self.ChatTabItems[tab] == nil) then return end

	if (tab == self.ChatActiveTab) then
		self:switchChatTab(0)
	end
	self.ChatTabItems[tab]:kill()
	self.ChatTabItems[tab] = nil
	for _, v in ipairs(self.ChatHolderItems[tab] or {}) do
		v:kill()
	end
	TBHud.ChatHolderItems[tab] = nil
	for i = #TBHudInternal.ChatMessages, 1, -1 do
		if (TBHudInternal.ChatMessages[i].tab == tab) then
			table.remove(TBHudInternal.ChatMessages, i)
		end
	end

	local cnt = 2
	for i, v in pairs(self.ChatTabItems) do
		local id = tonumber(i) or -1
		if (id > 0) then
			v:moveTo(nil, self.ChatTabWidth * cnt)
			cnt = cnt + 1
		end
	end

	close_chat_tab(tab)
end

---Marks a chat tab as unread
---@param tab integer
function TBHud:markChatTabUnread(tab)
	if (self.ChatTabItems[tab] == nil) then return end

	self.ChatTabItems[tab].hasUnread = true
	self.ChatTabItems[tab].imageColor = TB_MENU_DEFAULT_ORANGE
end

---Initializes chat and its elements
function TBHud:initChat()
	if (self.ChatHolderItems ~= nil) then return end

	---@type UIElement[][]
	self.ChatHolderItems = { }
	---@type TBHudTabButton[]
	self.ChatTabItems = { }

	local chatMainHolder = self.ChatHolder:addChild({
		pos = { 0, -self.ChatSize.h },
		size = { self.ChatSize.w + SAFE_X, self.ChatSize.h },
		bgColor = table.clone(UICOLORWHITE),
		uiColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true
	})
	chatMainHolder.bgColor[4] = 0.7

	local chatMessagesHolder = chatMainHolder:addChild({
		pos = { SAFE_X + self.ChatTabWidth, 0 },
		size = { chatMainHolder.size.w - SAFE_X - self.ChatTabWidth, chatMainHolder.size.h }
	})
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(chatMessagesHolder, 1, 50 + math.max(SAFE_Y, 30), 16, { 0, 0, 0, 0 })

	self.ChatTabHolder = chatMainHolder:addChild({
		pos = { 0, math.max(SAFE_Y, 30) },
		size = { self.ChatTabWidth + SAFE_X, chatMainHolder.size.h - math.max(SAFE_Y, 30) * 2 },
		uiColor = table.clone(TB_MENU_DEFAULT_DARKER_COLOR)
	})
	local extendTabsButton = self.ChatTabHolder:addChild({
		pos = { 0, 0 },
		size = { self.ChatTabWidth + SAFE_X, self.ChatTabWidth },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	extendTabsButton:addCustomDisplay(true, function()
			set_color(unpack(extendTabsButton:getButtonColor()))
			draw_quad(extendTabsButton.pos.x, extendTabsButton.pos.y, extendTabsButton.size.w - 10, extendTabsButton.size.h)
			draw_disk(extendTabsButton.pos.x + extendTabsButton.size.w - 10, extendTabsButton.pos.y + 10, 0, 10, 0, 1, 90, 90, 0)
			draw_disk(extendTabsButton.pos.x + extendTabsButton.size.w - 10, extendTabsButton.pos.y + extendTabsButton.size.h - 10, 0, 10, 0, 1, 0, 90, 0)
			draw_quad(extendTabsButton.pos.x + extendTabsButton.size.w - 10, extendTabsButton.pos.y + 10, 10, extendTabsButton.size.h - 20)
		end)
	local extendTabsButtonImage = extendTabsButton:addChild({
		pos = { SAFE_X + self.ChatTabWidth / 4, 0 },
		size = { self.ChatTabWidth / 2, self.ChatTabWidth },
		bgImage = "../textures/menu/general/buttons/arrowright.tga"
	})
	extendTabsButton.__extendState = false
	extendTabsButton:addMouseUpHandler(function()
			local targetWidth = SAFE_X + self.ChatTabWidth
			extendTabsButton.__extendState = not extendTabsButton.__extendState
			if (extendTabsButton.__extendState) then
				table.insert(topBar.child, self.ChatTabHolder)
				extendTabsButtonImage:updateImage("../textures/menu/general/buttons/arrowleft.tga")
				targetWidth = SAFE_X + self.ChatTabWidth * 5
			else
				for i, v in pairs(topBar.child) do
					if (v == self.ChatTabHolder) then
						table.remove(topBar.child, i)
						break
					end
				end
				extendTabsButtonImage:updateImage("../textures/menu/general/buttons/arrowright.tga")
			end

			local spawnClock = UIElement.clock
			extendTabsButtonImage:addCustomDisplay(function()
					local ratio = (UIElement.clock - spawnClock) * 3
					for i, v in pairs(self.ChatTabItems) do
						if (type(i) == "number") then
							v.size.w = UITween.SineTween(v.size.w, targetWidth, ratio)
							v.outline.size.w = v.size.w - SAFE_X - 10
							if (extendTabsButton.__extendState) then
								v.legend.uiColor[4] = math.max(0.01, ratio)
							end
						end
					end
					if (ratio >= 1) then
						extendTabsButtonImage:addCustomDisplay(function() end)
					end
				end)
			for i, v in pairs(self.ChatTabItems) do
				if (type(i) == "number") then
					v:reload()
					v.legend:setVisible(extendTabsButton.__extendState, true)
				end
			end
		end)
	self.ChatTabItems.extendButton = extendTabsButton

	local globalTabButton = self.ChatTabHolder:addChild({
		pos = { 0, self.ChatTabWidth },
		size = { self.ChatTabWidth + SAFE_X, self.ChatTabWidth },
		interactive = true,
		bgGradient = { UICOLORWHITE, { 1, 1, 1, 0 } },
		bgGradientMode = BODYPARTS.L_THIGH,
		imageColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		imageHoverColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		imagePressedColor = TB_MENU_DEFAULT_BG_COLOR_TRANS
	})
	local globalTabButtonOutline = globalTabButton:addChild({
		pos = { SAFE_X + 5, 5 },
		size = { globalTabButton.size.h - 10, globalTabButton.size.h - 10 },
		bgColor = UICOLORWHITE,
		shapeType = ROUNDED,
		rounded = self.ChatTabWidth
	})
	globalTabButton:addChild({
		pos = { SAFE_X + 5, 5 },
		size = { globalTabButton.size.h - 10, globalTabButton.size.h - 10 },
		bgImage = "../textures/menu/general/buttons/chatglobal.tga",
		imageColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local tabLegend = globalTabButton:addChild({
		pos = { SAFE_X + self.ChatTabWidth, 0 },
		size = { self.ChatTabWidth * 3, self.ChatTabWidth }
	})
	tabLegend:addAdaptedText("Global Chat", nil, nil, 4, LEFTMID, 1)
	tabLegend:hide(true)
	globalTabButton.outline = globalTabButtonOutline
	globalTabButton.legend = tabLegend
	globalTabButton:addMouseUpHandler(function()
			self:switchChatTab(0)
		end)
	self.ChatTabItems[0] = globalTabButton

	local botBarGradient = botBar:addChild({
		pos = { -botBar.size.w - self.ChatTabWidth - SAFE_X, -botBar.size.h - 5 },
		size = { botBar.size.w + self.ChatTabWidth + SAFE_X, 10 },
		bgGradient = { UICOLORWHITE, { 1, 1, 1, 0 } }
	})
	local botBarBackdrop = botBar:addChild({
		pos = { botBarGradient.shift.x, 5 },
		size = { botBarGradient.size.w, botBar.size.h - 5 },
		bgColor = UICOLORWHITE
	})
	local chatInputHolder = botBar:addChild({
		pos = { 20, botBar.size.h - 40 - math.max(SAFE_Y, 30) },
		size = { botBar.size.w - 40, 40 },
		shapeType = ROUNDED,
		rounded = 4,
		uiColor = UICOLORWHITE,
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	local chatInputField = TBMenu:spawnTextField2(chatInputHolder, { x = 35, w = chatInputHolder.size.w - 120 }, nil, nil, {
		fontId = FONTS.SMALL + 10,
		textAlign = LEFTMID,
		textScale = 0.75,
		textColor = table.clone(UICOLORWHITE),
		keepFocusOnHide = true,
		darkerMode = true,
		returnKeyType = KEYBOARD_RETURN.SEND,
		inputType = KEYBOARD_INPUT.DEFAULT --Make sure we allow language switching!
	})
	self.ChatHolder.destroySuggestions = function()
		if (chatInputField.suggestionsDropdown ~= nil) then
			chatInputField.suggestionsDropdown.selectedElement:kill()
			chatInputField.suggestionsDropdown:kill()
			chatInputField.suggestionsDropdown = nil
		end
	end
	chatInputField:addInputCallback(function()
			self.ChatHolder.destroySuggestions()

			local typeCommand, replacements = chatInputField.textfieldstr[1]:gsub("^/(%w+).*", "%1")
			if (replacements == 0) then
				set_menu_keyboard(chatInputField.inputType, true, chatInputField.returnKeyType)
				return
			end

			set_menu_keyboard(chatInputField.inputType, false, chatInputField.returnKeyType)

			local commands = self:getChatCommands()
			---@type HudChatCommand[]
			local targetCommands = {}
			for _, command in ipairs(commands) do
				local playerInfo = QueueList:getCurrentPlayerInfo()
				if ((not command.requireOnline or self.WorldState.game_type == 1) and
					(not command.requireOperator or not playerInfo or playerInfo.op or playerInfo.admin) and
					(not command.requireFighter or not playerInfo or playerInfo.is_fighter) and
					(not command.submitCmdMatch or chatInputField.textfieldstr[1] == "/" .. typeCommand)) then
					---@type string[]
					---@diagnostic disable-next-line: assign-type-mismatch
					local cmds = type(command.cmd) == "string" and { command.cmd } or command.cmd
					local typeSpecificCommand = command.typeCommandRegex and chatInputField.textfieldstr[1]:gsub(command.typeCommandRegex, "%1") or typeCommand
					for _, v in pairs(cmds) do
						if (string.find(v, "^" .. typeSpecificCommand)) then
							table.insert(targetCommands, command)
							break
						end
					end
				end
			end
			if (#targetCommands == 0) then
				return
			end

			local regainFocus = function(override)
				if (override or chatInputField.menuKeyboardId ~= nil) then
					chatInputField.keyboard = true
					disable_camera_movement()
					chatInputField.btnDown()
				end
			end
			local dropdownList = {}
			for _, cmdInfo in pairs(targetCommands) do
				table.insert(dropdownList, {
					text = cmdInfo.info,
					action = function()
						local newInput = utf8.gsub(chatInputField.textfieldstr[1], cmdInfo.regex, cmdInfo.replacement)
						chatInputField:clearTextfield()
						chatInputField.textInput(newInput)
						chatInputField.textInputCustom()
						if (cmdInfo.autoSubmit) then
							chatInputField.enteraction()
						end
					end,
					preAction = function()
						regainFocus(true)
					end
				})
			end

			chatInputField.suggestionsDropdown = TBMenu:spawnDropdown(chatInputHolder, dropdownList, chatInputField.size.h, WIN_H / 3, { text = '' }, nil, { scale = 0.65, fontid = 4, uppercase = false, alignment = LEFTMID }, true, true, true)
			chatInputField.suggestionsDropdown.uiColor = UICOLORWHITE
			chatInputField.suggestionsDropdown.selectedElement:hide(true)
			chatInputField.suggestionsDropdown.selectedElement.btnUp()
			if (chatInputField.suggestionsDropdown.listHolder ~= nil) then
				local suggestionsListView = chatInputField.suggestionsDropdown.listHolder.parent
				local mouseDown = suggestionsListView.btnDown
				local mouseMove = suggestionsListView.btnHover
				suggestionsListView.btnDown = function(...) mouseDown(...) regainFocus() end
				suggestionsListView.mouseHover = function(...) mouseMove(...) regainFocus() end
			end
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

			local cmdIdx, cmdEnd = string.find(chatInputField.textfieldstr[1], "^/(%w+)")
			if (cmdIdx ~= nil) then
				local cmd = string.sub(chatInputField.textfieldstr[1], cmdIdx + 1, cmdEnd)
				if (in_array(cmd, TBHudInternal.IgnoreCommands)) then
					chatInputField:clearTextfield()
					self.ChatHolder.destroySuggestions()
					return
				end
				local message = string.sub(chatInputField.textfieldstr[1], cmdIdx + 1)
				runCmd(message, self.WorldState.game_type == 1)
			else
				---@diagnostic disable-next-line: undefined-global
				send_chat_message(chatInputField.textfieldstr[1], self.ChatActiveTab)
			end
			add_chat_history(chatInputField.textfieldstr[1])
			table.insert(TBHudInternal.ChatMessageHistory, #TBHudInternal.ChatMessageHistory, chatInputField.textfieldstr[1])
			TBHudInternal.ChatMessageHistoryIndex = #TBHudInternal.ChatMessageHistory

			chatInputField:clearTextfield()
			self.ChatHolder.destroySuggestions()
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
	chatInputSubmit:addChild({ shift = { 10, 3 }}):addAdaptedText(TB_MENU_LOCALIZED.BUTTONSEND)
	chatInputSubmit:addMouseUpHandler(chatInputField.enteraction)

	self.ChatHolderToReload = toReload
	self.ChatHolderListing = listingHolder
	self.ChatHolderTopBar = topBar
end

function TBHud:scrollChatIntoPosition()
	if (TBHudInternal.ListShift[1] == 0) then
		self.ChatHolderScrollBar:moveTo(nil, self.ChatHolderScrollBar.parent.size.h - self.ChatHolderScrollBar.size.h)
		self.ChatHolderListing:moveTo(nil, -#self.ChatHolderItems[self.ChatActiveTab] * TBHudInternal.ChatElementHeight)
		self.ChatHolderScrollBar.listReload()
	else
		local scrollProgress = -(self.ChatHolderListing.size.h + self.ChatHolderListing.shift.y) / (#self.ChatHolderItems[self.ChatActiveTab] * TBHudInternal.ChatElementHeight - self.ChatHolderListing.size.h)
		self.ChatHolderScrollBar:moveTo(nil, (self.ChatHolderScrollBar.parent.size.h - self.ChatHolderScrollBar.size.h) * scrollProgress)
		if (TBHudInternal.RequireListReload) then
			self.ChatHolderScrollBar.listReload()
		end
	end
	TBHudInternal.RequireListReload = false
end

---Reloads chat display
function TBHud:refreshChat()
	if (self.ChatHolderItems == nil) then return end
	if (self.ChatHolderItems[self.ChatActiveTab] == nil) then
		self.ChatHolderItems[self.ChatActiveTab] = { }
	end
	local holderItems = self.ChatHolderItems[self.ChatActiveTab]
	local listingHolder = self.ChatHolderListing

	if (-listingHolder.shift.y >= #holderItems * TBHudInternal.ChatElementHeight) then
		TBHudInternal.ListShift[1] = 0
	end

	local tabWasSwitched = #listingHolder.child == 0 and #holderItems > 0
	if (tabWasSwitched) then
		local offsetIdx = -1
		for i = #holderItems, 1, -1 do
			---@diagnostic disable-next-line: undefined-field
			if (holderItems[i].isNewMessageMark) then
				offsetIdx = i
				holderItems[i]:kill()
				table.remove(holderItems, i)
				holderItems.hasNewMessageMark = nil
			else
				if (tabWasSwitched) then
					table.insert(listingHolder.child, 1, holderItems[i])
				end
			end
		end
		if (offsetIdx >= 0) then
			for i = offsetIdx, #holderItems do
				holderItems[i].shift.y = holderItems[i].shift.y - TBHudInternal.ChatElementHeight
			end
		end
	end

	local i = 1
	for _, message in pairs(TBHudInternal.ChatMessages) do
		if (message.tab == self.ChatActiveTab) then
			if (i > #holderItems - (holderItems.hasNewMessageMark and 1 or 0) or message.lines == nil) then
				if (tabWasSwitched) then
					tabWasSwitched = false
					holderItems.hasNewMessageMark = true
					local newMessageMark = listingHolder:addChild({
						pos = { 16, #holderItems * TBHudInternal.ChatElementHeight },
						size = { listingHolder.size.w - 32, TBHudInternal.ChatElementHeight },
						uiColor = UICOLORWHITE
					})
					local halfHeight = newMessageMark.size.h / 2
					local quadOffset = newMessageMark.size.h * 0.066
					newMessageMark:addCustomDisplay(true, function()
							local lineY = newMessageMark.pos.y + halfHeight
							set_color(unpack(TB_MENU_DEFAULT_BG_COLOR))
							draw_line(newMessageMark.pos.x, lineY, newMessageMark.pos.x + newMessageMark.size.w - 80, lineY, 2)
							draw_disk(newMessageMark.pos.x + newMessageMark.size.w - 80 - newMessageMark.size.h / 4, lineY, 0, halfHeight, 3, 1, 30, 360, 0)
							draw_quad(newMessageMark.pos.x + newMessageMark.size.w - 80, newMessageMark.pos.y + quadOffset, 70.2, newMessageMark.size.h - quadOffset * 2)
							draw_disk(newMessageMark.pos.x + newMessageMark.size.w - 10, newMessageMark.pos.y + quadOffset + 10, 0, 10, 0, 1, 90, 90, 0)
							draw_disk(newMessageMark.pos.x + newMessageMark.size.w - 10, newMessageMark.pos.y + newMessageMark.size.h - quadOffset - 10, 0, 10, 0, 1, 0, 90, 0)
							draw_quad(newMessageMark.pos.x + newMessageMark.size.w - 10, newMessageMark.pos.y + quadOffset + 9.8, 10, newMessageMark.size.h - 19.6 - quadOffset * 2)
						end)
					newMessageMark.isNewMessageMark = true
					table.insert(holderItems, newMessageMark)

					newMessageMark:addChild({
						pos = { -80, 6 },
						size = { 70, newMessageMark.size.h - 12 }
					}):addAdaptedText(true, utf8.upper(TB_MENU_LOCALIZED.WORDNEW), nil, nil, FONTS.LMEDIUM)
				end
				local messageStrings = textAdapt(message.text, FONTS.SMALL + 10, 0.72, listingHolder.size.w - 32)
				message.lines = 0
				local nextColor = nil
				for _, str in pairs(messageStrings) do
					local chatMessage = listingHolder:addChild({
						pos = { 16, #holderItems * TBHudInternal.ChatElementHeight },
						size = { listingHolder.size.w - 32, TBHudInternal.ChatElementHeight },
						---@diagnostic disable-next-line: assign-type-mismatch
						uiColor = nextColor
					})
					chatMessage:addAdaptedText(true, str, nil, nil, FONTS.SMALL + 10, LEFT, 0.72, 0.72)
					table.insert(holderItems, chatMessage)
					nextColor = TBHudInternal.getLastColorFromString(str)
					message.lines = message.lines + 1

					if (self.ChatHolderScrollBar ~= nil and self.ChatHolderScrollBar:isDisplayed()) then
						chatMessage:hide(true)
					end
				end
			end
			i = i + message.lines
		end
	end

	if (#holderItems * TBHudInternal.ChatElementHeight > listingHolder.size.h) then
		if (self.ChatHolderScrollBar == nil) then
			for _, v in ipairs(holderItems) do
				v:hide(true)
			end

			-- Don't forget to move listing holder back in place
			listingHolder:moveTo(nil, self.ChatHolderTopBar.size.w)
			self.ChatHolderScrollBar = TBMenu:spawnScrollBar(listingHolder, #holderItems, TBHudInternal.ChatElementHeight)
			self.ChatHolderScrollBar.bgColor = table.clone(TB_MENU_DEFAULT_INACTIVE_COLOR)
			self.ChatHolderScrollBar:makeScrollBar(listingHolder, listingHolder.child, self.ChatHolderToReload, TBHudInternal.ListShift)
		else
			if (not self.ChatHolderScrollBar:isDisplayed()) then
				self.ChatHolderScrollBar:show(true)
			end
			self.ChatHolderScrollBar.size.h = math.max(0.1, math.min(1, (listingHolder.size.h) / (#holderItems * TBHudInternal.ChatElementHeight) or listingHolder.size.h)) * self.ChatHolderScrollBar.parent.size.h
		end

		self:scrollChatIntoPosition()
	else
		if (self.ChatHolderScrollBar ~= nil and self.ChatHolderScrollBar:isDisplayed()) then
			self.ChatHolderScrollBar:hide(true)
		end
		for _, v in ipairs(holderItems) do
			v:show(true)
		end
		listingHolder:moveTo(nil, listingHolder.parent.size.h - TBHudInternal.ChatElementHeight * #holderItems)
	end

	self.RequiresChatRefresh = false
end

function TBHud:toggleChat(state)
	if (state == true) then
		self.ChatHolder:show(true)
		if (self.RequiresChatRefresh) then
			self:refreshChat()
		end
	elseif (self.ChatTabItems.extendButton ~= nil and self.ChatTabItems.extendButton.__extendState == true) then
		self.ChatTabItems.extendButton.btnUp()
	end

	local clock = UIElement.clock
	self.ChatHolder:addCustomDisplay(true, function()
		local tweenValue = (UIElement.clock - clock) * 6
		if (state) then
			self.ChatHolder:moveTo(nil, UITween.SineTween(self.ChatHolder.pos.y, 0, tweenValue))
		else
			self.ChatHolder:moveTo(nil, UITween.SineTween(self.ChatHolder.pos.y, self.ChatHolder.size.h, tweenValue))
			---@diagnostic disable-next-line: undefined-field
			self.ChatHolder.destroySuggestions()
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
		pos = { self.DefaultSmallerButtonSize * 3, 0 },
		size = { self.ChatSize.w * 0.75, WIN_H - self.DefaultButtonSize * 0.35 }
	})

	---@type ChatMessage[]
	local messagesToDisplay = {}
	local refreshMiniChat = function()
		messagesToDisplay = {}
		for i = #TBHudInternal.ChatMessages, 1, -1 do
			if (TBHudInternal.ChatMessages[i].clock < UIElement.clock - self.ChatMiniDisplayPeriod) then
				break
			end
			if (TBHudInternal.ChatMessages[i].tab == self.ChatActiveTab) then
				table.insert(messagesToDisplay, TBHudInternal.ChatMessages[i])
				if (#messagesToDisplay == self.ChatMiniMaxMessages) then
					break
				end
			end
		end
		for i, v in pairs(messagesToDisplay) do
			messagesToDisplay[i].adaptedTextMini = textAdapt(v.text, 11, 0.55, self.ChatMiniHolder.size.w)
			messagesToDisplay[i].textColorMini = { nil }
			local displayColor = nil
			for j, line in pairs(messagesToDisplay[i].adaptedTextMini) do
				displayColor = TBHudInternal.getLastColorFromString(line) or displayColor
				messagesToDisplay[i].textColorMini[j + 1] = displayColor
			end
		end
		self.ChatMiniUpdateTime = os.time()
		self.ChatMiniLastTab = self.ChatActiveTab
	end

	self.ChatMiniHolder:addCustomDisplay(function()
			if (self.ChatHolder:isDisplayed() or self.CameraJoystickFreeHolder.child[1]:isDisplayed()) then return end
			if (os.time() ~= self.ChatMiniUpdateTime or self.ChatMiniLastTab ~= self.ChatActiveTab) then
				refreshMiniChat()
			end
			local linesPrinted = 0
			for _, v in pairs(messagesToDisplay) do
				local textOpacity = UITween.SineEaseOut((v.clock - UIElement.clock + (self.ChatMiniDisplayPeriod - 1)) / 3)
				for i = #v.adaptedTextMini, 1, -1 do
					local displayColor = table.clone(v.textColorMini[i] or TB_MENU_DEFAULT_DARKEST_COLOR)
					displayColor[4] = textOpacity
					self.ChatMiniHolder:uiText(v.adaptedTextMini[i], nil, { 0, linesPrinted * 20 }, 11, LEFTBOT, 0.55, nil, nil, displayColor)
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
	self:initChat()
	self:spawnMiniChat()
	self:loadChatHistory()

	TBHudInternal.LearnCommands()

	self.ChatHolder:hide(true)
end

---Adds our most common commands to device dictionary to make sure autocorrect doesn't make things annoying. \
---Command prefix should be omitted, iOS doesn't consider `/` to be a valid word symbol.
function TBHudInternal.LearnCommands()
	local commands = {
		"em",
		"sh",
		"sp", "spec",
		"jo",
		"rf",
		"sa",
		"dl",
		"rt",
		"pa", "pass", "passwd",
		"lm", "loadmod",
		"ls", "loadscript",
		"opt",
		"co",
		"rec",
		"lp", "loadplayer",
		"am",
		"sm",
		"dm",
		"echo", "ec",
		"setowner",
		"maxrake",
		"minbet",
		"betframes",
		"cancelbets",
		"fuke",
		"specall",
		"muteall", "unmuteall",
		"nudgeup", "nudgedown",
		"fspec", "fenter",
		"fjoin",
		"fknock",
		"enterfee",
		"afkpenalty",
		"decapprize",
		"dismemberprize",
		"op", "deop",
		"minbelt", "maxbelt",
		"queuejump",
		"maxclients",
		"realtimeghost",
		"motd",
		"desc",
		"modlist",
		"buynudge",
		"nudgeprice",
		"selfbet",
		"minsb",
		"stopbet",
		"clanvip",
		"viponly",
		"setafk"
	}
	for _, v in pairs(commands) do
		keyboard_learn_word(v)
	end
end

---Initialized popup manager UIElement
function TBHudInternal.PopupInit()
	if (TBHudPopup.Manager) then
		if (not TBHudPopup.Manager:isDisplayed()) then
			TBHudPopup.Manager:show()
		end
		return
	end

	TBHudPopup.Manager = UIElement:new({
		globalid = TBHud.Globalid,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	TBHudPopup.Manager:addCustomDisplay(true, function()
			if (not TBHudPopup.PopupActive and #TBHudPopup.Queue > 0) then
				TBHudPopup.PopupActive = true
				TBHudPopup.Queue[1].__launchClock = UIElement.clock
				TBHudPopup.Queue[1]:show()
				table.remove(TBHudPopup.Queue, 1)
				for _, v in pairs(TBHudPopup.Queue) do
					if (v:isDisplayed()) then
						v:hide()
					end
				end
			end
			if (#TBHudPopup.Queue == 0) then
				TBHudPopup.Manager:hide()
			end
		end)
	TBHudPopup.Manager:show()
end

---Updates popup's launch time to trigger close animation
function TBHudPopup:Close()
	self.__launchClock = UIElement.clock - self.__duration - 0.2
end

---Creates a generic mobile popup view at the top of the screen
---@param duration ?number
---@return TBHudPopup
function TBHudPopup.New(duration)
	TBHudInternal.PopupInit()

	local safe_y = math.max(10, SAFE_Y)
	local popupWidth = math.min(1000, WIN_W * 0.6)
	local popupHeight = math.min(100, WIN_H * 0.2)

	---@type TBHudPopup
	---@diagnostic disable-next-line: assign-type-mismatch
	local popupView = UIElement:new({
		globalid = TBHud.Globalid,
		pos = { (WIN_W - popupWidth) / 2, -popupHeight },
		size = { popupWidth, popupHeight },
		interactive = true,
		bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
		shapeType = ROUNDED,
		rounded = 10
	})
	setmetatable(popupView, TBHudPopup)
	popupView.bgColor[4] = 0.9
	popupView.__duration = duration or TBHudPopup.DefaultDuration
	popupView.__touchPos = { x = -1, y = -1 }
	popupView.__touchDelta = { x = 0, y = 0 }
	popupView.killAction = function() TBHudPopup.PopupActive = false end

	local mouseUp = function()
		enable_mouse_camera_movement()
		popupView.__touchPos.x = -1
		popupView.__touchPos.y = -1
		popupView.__touchDelta.x = 0
		popupView.__touchDelta.y = 0
		popupView.__launchClock = popupView.__launchClock + (UIElement.clock - popupView.__touchClock)
		popupView.__touchClock = UIElement.clock
	end
	popupView:addMouseHandlers(function(_, x, y)
			disable_mouse_camera_movement()
			popupView.__touchPos.x = x
			popupView.__touchPos.y = y
			popupView.__touchClock = UIElement.clock
		end, mouseUp, function(x, y)
			if (popupView.hoverState == BTN_DN) then
				popupView.__touchDelta.x = x - popupView.__touchPos.x
				popupView.__touchDelta.y = y - popupView.__touchPos.y
			end
		end, nil, mouseUp)

	popupView:addCustomDisplay(function()
			if (popupView.__launchClock == nil) then return end
			if (popupView.pos.y < safe_y) then
				popupView:moveTo(nil, math.ceil(UITween.SineTween(popupView.pos.y, safe_y, UIElement.clock - popupView.__launchClock)))
				popupView:updatePos()
			else
				popupView:addCustomDisplay(function()
					if (UIElement.clock - popupView.__launchClock > popupView.__duration) then
						if (popupView.pos.y > -popupView.size.h) then
							popupView:moveTo(nil, math.floor(UITween.SineTween(popupView.pos.y, -popupView.size.h, UIElement.clock - popupView.__duration - popupView.__launchClock)))
							popupView:updatePos()
						else
							popupView:kill()
						end
					elseif (popupView.__touchPos.y ~= -1) then
						if (popupView.__touchDelta.y ~= 0) then
							popupView.__touchPos.x = MOUSE_X
							popupView.__touchPos.y = MOUSE_Y
							popupView:moveTo(nil, popupView.__touchDelta.y, true)
							if (popupView.pos.y > safe_y) then
								popupView:moveTo(nil, safe_y)
							end
							popupView:updatePos()
							if (math.abs(popupView.__touchDelta.y) > 25 or popupView.pos.y < -popupView.size.h * 0.8) then
								popupView:Close()
							end
							popupView.__touchDelta.y = 0
							popupView.__touchDelta.x = 0
						end
					elseif (popupView.pos.y ~= safe_y and popupView.__touchClock ~= nil) then
						popupView:moveTo(nil, math.ceil(UITween.SineTween(popupView.pos.y, safe_y, (UIElement.clock - popupView.__touchClock) * 2)))
					end
				end, true)
			end
		end, true)

	table.insert(TBHudPopup.Queue, popupView)
	return popupView
end

function TBHudInternal.toggleChatOff()
	disable_menu_keyboard()
	TBHud:toggleChat(false)
end

TBHud.Reload()
add_hook("resolution_changed", TBHud.HookNameUI, TBHud.Reload)
add_hook("new_game", TBHud.HookNameUI, TBHudInternal.refreshButtons)
add_hook("spec_update", TBHud.HookNameUI, TBHudInternal.refreshButtons)
add_hook("bout_update", TBHud.HookNameUI, TBHudInternal.refreshButtons)
add_hook("enter_frame", TBHud.HookNameUI, TBHudInternal.refreshButtons)
add_hook("enter_freeze", TBHud.HookNameUI, TBHudInternal.refreshButtons)
add_hook("exit_freeze", TBHud.HookNameUI, TBHudInternal.refreshButtons)
add_hook("new_game_mp", TBHud.HookNameUI, TBHudInternal.refreshButtons)
add_hook("console_post", TBHud.HookNameChat, TBHudInternal.pushChatMessage)
add_hook("new_mp_game", TBHud.HookNameUI, TBHudInternal.toggleChatOff)
