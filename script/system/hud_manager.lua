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
---@field adaptedText string[]

if (TBHud == nil) then
	---Touch HUD class
	---@class TBHud
	---@field MainElement UIElement
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
		MainElement = nil,
		ChatHolder = nil,
		ChatMiniHolder = nil,
		ChatSize = { w = 0, h = 0},
		ChatMaxHistory = 2000,
		ChatMiniMaxMessages = 10,
		ChatMiniDisplayPeriod = 20,
		ChatMiniUpdateTime = 0,
		WorldState = nil,
		ButtonsToRefresh = {},
		DefaultButtonSize = nil,
		DeafultSmallerButtonSize = nil,
		DefaultButtonColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
		RequiresChatRefresh = false,
		ver = 1.0,
		__index = {}
	}
	setmetatable({}, TBHud)
end

---Internal subclass for **TBHud** that holds utility functions we won't need elsewhere
---@class TBHudInternal
---@field ChatMessages ChatMessage[]
---@field ChatMessageHistory string[] User chat message history
---@field ChatMessageHistoryIndex integer
local TBHudInternal = {
	ChatMessages = {},
	ChatMessageHistory = {},
	ChatMessageHistoryIndex = 1
}
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

	TBHud.ButtonsToRefresh = {}
	TBHud.DefaultButtonSize = math.max(100, WIN_H / 10)
	TBHud.DefaultSmallerButtonSize = TBHud.DefaultButtonSize * 0.7

	TBHud:spawnCommitButton()
	TBHud:spawnGhostButon()
	TBHud:spawnOptionsButton()
	TBHud:spawnChatButton()

	TBHud.ChatSize.w = WIN_W * 0.4 > 600 and 600 or WIN_W * 0.4
	TBHud.ChatSize.h = WIN_H
	TBHud:spawnChat()
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
	commitStepButton:addMouseUpHandler(function()
		if (TBHud.WorldState.replay_mode == 1) then
			start_new_game()
		else
			step_game()
		end
	end)

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

function TBHud:getChatCommands()
	return {
		set = { command = "/set ^46gamerule ^47value" },
		opt = { command = "/opt ^46option ^47value" }
	}
end

---Method that handles all incoming chat messages and pushes them for display
---@param msg string
---@param type integer
---@param tab integer
function TBHud:pushChatMessage(msg, type, tab)
	local message = get_option("chatcensor") % 2 == 1 and ChatIgnore:filterInput(msg) or msg
	---@type ChatMessage
	local chatMessage = {
		text = message,
		tab = tab,
		clock = os.clock()
	}
	table.insert(TBHudInternal.ChatMessages, chatMessage)
	if (#TBHudInternal.ChatMessages > TBHud.ChatMaxHistory) then
		table.remove(TBHudInternal.ChatMessages, 1)
		TBHud.ChatHolderItems[1]:kill()
		table.remove(TBHud.ChatHolderItems, 1)
		for _, v in pairs(TBHud.ChatHolderItems) do
			v:moveTo(nil, -v.size.h, true)
		end
	end

	if (TBHud.ChatHolder:isDisplayed()) then
		TBHud:refreshChat()
	else
		for _, v in pairs(TBHud.ChatHolderItems) do
			v:hide()
		end
		TBHud.ChatMiniUpdateTime = 0
		TBHud.RequiresChatRefresh = true
	end
end

---Spawns the chat button for touch UI
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

---Reloads chat display
function TBHud:refreshChat()
	local elementHeight = 18

	if (TBHud.ChatHolderItems == nil) then
		-- Do the initial setup
		local chatMessagesHolder = TBHud.ChatHolder:addChild({
			pos = { 15, -TBHud.ChatSize.h },
			size = { TBHud.ChatSize.w, TBHud.ChatSize.h },
			bgColor = table.clone(UICOLORWHITE),
			uiColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		chatMessagesHolder.bgColor[4] = 0.7
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(chatMessagesHolder, elementHeight, 70, 16, { 0, 0, 0, 0 })

		---@type UIElement[]
		TBHud.ChatHolderItems = {}
		for _, message in pairs(TBHudInternal.ChatMessages) do
			local messageStrings = textAdapt(message.text, FONTS.SMALL, 1, listingHolder.size.w - 32)
			for _, string in pairs(messageStrings) do
				local chatMessage = listingHolder:addChild({
					pos = { 16, #TBHud.ChatHolderItems * elementHeight },
					size = { listingHolder.size.w - 32, elementHeight }
				})
				chatMessage:addAdaptedText(true, string, nil, nil, FONTS.SMALL, LEFT, 1, 1)
				table.insert(TBHud.ChatHolderItems, chatMessage)
			end
		end

		local chatInputHolder = botBar:addChild({
			pos = { 20, botBar.size.h - 60 },
			size = { botBar.size.w - 40, 30 },
			shapeType = ROUNDED,
			rounded = 4,
			uiColor = UICOLORWHITE
		})
		local chatInputField = TBMenu:spawnTextField2(chatInputHolder)
		chatInputField:addInputCallback(function()
				if (chatInputField.suggestionsDropdown ~= nil) then
					chatInputField.suggestionsDropdown:kill()
					chatInputField.suggestionsDropdown = nil
				end

				local typeCommand, replacements = chatInputField.textfieldstr[1]:gsub("^/(%w+).*", "%1")
				if (replacements == 0) then
					return
				end

				local commands = TBHud:getChatCommands()
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
				for cmd, cmdInfo in pairs(targetCommands) do
					table.insert(dropdownList, {
						text = cmdInfo.command,
						action = function() end
					})
				end

				chatInputField.suggestionsDropdown = TBMenu:spawnDropdown(chatInputHolder, dropdownList, chatInputField.size.h, WIN_H / 3, { text = '' }, nil, { scale = 0.65, fontid = 4, uppercase = false, alignment = LEFTMID }, true, true)
				chatInputField.suggestionsDropdown.uiColor = UICOLORWHITE
				---@diagnostic disable-next-line: undefined-field
				chatInputField.suggestionsDropdown.selectedElement:hide(true)
				---@diagnostic disable-next-line: undefined-field
				chatInputField.suggestionsDropdown.selectedElement:btnUp()
			end)
		-- Don't need chat history for mobile for now
		--[[chatInputField:addKeyboardHandlers(nil, function(key)
				if (key == 273 or key == 274) then -- arrow up or down
					if (key == 273) then
						TBHudInternal.ChatMessageHistoryIndex = math.min(TBHudInternal.ChatMessageHistoryIndex + 1, #TBHudInternal.ChatMessageHistory)
					else
						TBHudInternal.ChatMessageHistoryIndex = math.max(TBHudInternal.ChatMessageHistoryIndex - 1, 1)
					end[TBHudInternal.ChatMessageHistoryIndex])
					chatInputField.textfieldstr[1] = TBHudInternal.ChatMessageHistory[TBHudInternal.ChatMessageHistoryIndex]
					chatInputField.textfieldindex = utf8.len(chatInputField.textfieldstr[1])
				end
			end)]]
		chatInputField:addEnterAction(function()
				if (string.find(chatInputField.textfieldstr[1], "^/")) then
					local cmd = chatInputField.textfieldstr[1]:gsub("^/(.+)", "%1")
					runCmd(cmd, TBHud.WorldState.game_type == 1)
				else
					---@diagnostic disable-next-line: undefined-global
					send_chat_message(chatInputField.textfieldstr[1])
				end
				table.insert(TBHudInternal.ChatMessageHistory, #TBHudInternal.ChatMessageHistory - 2, chatInputField.textfieldstr[1])
				chatInputField:clearTextfield()
			end)

		TBHud.ChatHolderToReload = toReload
		TBHud.ChatHolderListing = listingHolder
		TBHud.ChatHolderTopBar = topBar
	else
		for i, message in pairs(TBHudInternal.ChatMessages) do
			if (i > #TBHud.ChatHolderItems) then
				local messageStrings = textAdapt(message.text, FONTS.SMALL, 1, TBHud.ChatHolderListing.size.w - 32)
				for _, string in pairs(messageStrings) do
					local chatMessage = TBHud.ChatHolderListing:addChild({
						pos = { 16, #TBHud.ChatHolderItems * elementHeight },
						size = { TBHud.ChatHolderListing.size.w - 32, elementHeight }
					})
					chatMessage:addAdaptedText(true, string, nil, nil, FONTS.SMALL, LEFT, 1, 1)
					table.insert(TBHud.ChatHolderItems, chatMessage)

					if (TBHud.ChatHolderScrollBar ~= nil) then
						chatMessage:hide(true)
					end
				end
			end
		end
	end

	if (TBHud.ChatHolderItems[1] ~= nil) then
		local listingHolder = TBHud.ChatHolderListing
		if (#TBHud.ChatHolderItems * elementHeight > listingHolder.size.h) then
			if (TBHud.ChatHolderScrollBar == nil) then
				for _, v in pairs(TBHud.ChatHolderItems) do
					v:hide(true)
				end

				-- Don't forget to move listing holder back in place
				listingHolder:moveTo(nil, TBHud.ChatHolderTopBar.size.w)
				TBHud.ChatHolderScrollBar = TBMenu:spawnScrollBar(listingHolder, #TBHud.ChatHolderItems, elementHeight)
				TBHud.ChatHolderScrollBar:makeScrollBar(listingHolder, TBHud.ChatHolderItems, TBHud.ChatHolderToReload)
			else
				TBHud.ChatHolderScrollBar.size.h = math.max(0.1, math.min(1, (listingHolder.size.h) / (#TBHud.ChatHolderItems * elementHeight) or listingHolder.size.h)) * TBHud.ChatHolderScrollBar.parent.size.h
			end

			local hoverState = TBHud.ChatHolderScrollBar.hoverState
			TBHud.ChatHolderScrollBar.hoverState = BTN_DN
			TBHud.ChatHolderScrollBar.btnHover(TBHud.ChatHolderScrollBar.parent.pos.x + 1, TBHud.ChatHolderScrollBar.parent.pos.y + TBHud.ChatHolderScrollBar.parent.size.h - 2)
			TBHud.ChatHolderScrollBar.hoverState = hoverState
		else
			listingHolder:moveTo(nil, listingHolder.parent.size.h - elementHeight * #TBHud.ChatHolderItems)
		end
	end

	TBHud.RequiresChatRefresh = false
end

function TBHud:toggleChat(state)
	if (state == true) then
		TBHud.ChatHolder:show(true)
		if (TBHud.RequiresChatRefresh) then
			TBHud:refreshChat()
		end
	end

	local clock = os.clock()
	TBHud.ChatHolder:addCustomDisplay(true, function()
		local tweenValue = UITween.SineEaseIn((os.clock() - clock) * 6)
		TBHud.ChatHolder:moveTo(nil, state and TBHud.ChatHolder.size.h - tweenValue * TBHud.ChatHolder.size.h or tweenValue * TBHud.ChatHolder.size.h)

		if (tweenValue == 1) then
			if (state == false) then
				TBHud.ChatHolder:hide(true)
			else
				TBHud.ChatHolder:addCustomDisplay(true, function() end)
			end
		end
	end)
end

function TBHud:spawnMiniChat()
	if (TBHud.ChatMiniHolder ~= nil) then
		TBHud.ChatMiniHolder:kill()
	end
	TBHud.ChatMiniHolder = TBHud.MainElement:addChild({
		pos = { TBHud.DefaultSmallerButtonSize * 1.7, 0 },
		size = { TBHud.ChatSize.w, WIN_H - TBHud.DefaultButtonSize * 0.35 }
	})

	---@type ChatMessage[]
	local messagesToDisplay = {}
	local refreshMiniChat = function()
		messagesToDisplay = {}
		for i = #TBHudInternal.ChatMessages, 1, -1 do
			if (TBHudInternal.ChatMessages[i].clock < os.clock() - TBHud.ChatMiniDisplayPeriod) then
				break
			end
			table.insert(messagesToDisplay, TBHudInternal.ChatMessages[i])
			if (#messagesToDisplay == TBHud.ChatMiniMaxMessages) then
				break
			end
		end
		for i, v in pairs(messagesToDisplay) do
			messagesToDisplay[i].adaptedText = textAdapt(v.text, FONTS.SMALL, 1, TBHud.ChatMiniHolder.size.w)
		end
		TBHud.ChatMiniUpdateTime = os.time()
	end

	TBHud.ChatMiniHolder:addCustomDisplay(function()
			if (TBHud.ChatHolder:isDisplayed()) then return end
			if (os.time() ~= TBHud.ChatMiniUpdateTime) then
				refreshMiniChat()
			end
			local linesPrinted = 0
			local clock = os.clock()
			for _, v in pairs(messagesToDisplay) do
				local textOpacity = UITween.SineEaseOut((v.clock - clock + (TBHud.ChatMiniDisplayPeriod - 1)) / 3)
				for i = #v.adaptedText, 1, -1 do
					TBHud.ChatMiniHolder:uiText(v.adaptedText[i], nil, -linesPrinted * 20, FONTS.SMALL, LEFTBOT, 1, nil, nil, { TB_MENU_DEFAULT_DARKEST_COLOR[1], TB_MENU_DEFAULT_DARKEST_COLOR[2], TB_MENU_DEFAULT_DARKEST_COLOR[3], textOpacity })
					linesPrinted = linesPrinted + 1
					if (linesPrinted > TBHud.ChatMiniMaxMessages) then
						return
					end
				end
			end
		end)
end

function TBHud:loadChatHistory()
	TBHudInternal.ChatMessageHistory = get_chat_history()
end

function TBHud:spawnChat()
	if (TBHud.MainElement == nil or TBHud.ChatHolder ~= nil) then return end

	set_option("chat", 0)
	TBHud.ChatHolder = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { TBHud.MainElement.pos.x, TBHud.MainElement.pos.y + TBHud.MainElement.size.h },
		size = { TBHud.MainElement.size.w, TBHud.MainElement.size.h },
		interactive = true
	})
	TBHud.ChatHolder:hide(true)
	TBHud.ChatHolder:addMouseUpHandler(function() TBHud:toggleChat(false) end)
	TBHud:refreshChat()
	TBHud:spawnMiniChat()
	TBHud:loadChatHistory()
end

add_hook("resolution_changed", "tbHudTouchInterface", function() TBHud:init() end)
add_hook("new_game", "tbHudTouchInterface", function() TBHud:refreshButtons() end)
add_hook("console_post", "tbHudChatInterface", function(msg, type, tab)
	TBHud:pushChatMessage(msg, type, tab)
end)
