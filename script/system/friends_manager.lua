require("system.roomlist_manager")
require("system.playerinfo_manager")

---@class FriendInfo
---@field username string
---@field online boolean
---@field room string

if (Friends == nil) then
	---**Friends and Ignore Manager Class**
	---
	---**Version 5.74**
	---* Ignore list refresh process tweaks to ensure we don't get empty entries
	---
	---**Version 5.62**
	---* Ignore list with ignore modes
	---* Friends list tweaks
	---* Internal tweaks to match new codestyle
	---
	---**Version 5.60**
	---* Changed class name from FriendsList to Friends
	---* Added EmmyLua annotations
	---* Use new room list functionality to search for online friends
	---@class Friends
	---@field FriendsList FriendInfo[]
	---@field ClanFriends FriendInfo[]
	---@field IgnoreList IgnoreListEntry[]
	Friends = {
		FriendsList = {},
		IgnoreList = {},
		ClanFriends = {},
		ver = 5.74
	}
	Friends.__index = Friends
end

---Exits Friends screen and opens last main menu screen
function Friends.Quit()
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
	TBMenu:clearNavSection()
	TBMenu:showNavigationBar()
	TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
end

---Returns navigation data for Friends screen
---@return MenuNavButton[]
function Friends:getNavigationButtons()
	return {
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
			action = self.Quit,
		}
	}
end

---Refreshes list of online players if it's gone stale and displays friends list with up-to-date room info
---@param viewElement UIElement
function Friends:getOnline(viewElement)
	local dataReady = true
	if (RoomList.RefreshIfNeeded()) then
		dataReady = false
		add_hook("roomlist_update", "__tbFriendsRoomListWaiter", function() dataReady = true end)
	end

	local function updateStates()
		local onlinePlayers = RoomList.GetPlayers()
		local clanFriends = {}

		for _, v in pairs(self.FriendsList) do
			v.online = false
			for _, n in pairs(onlinePlayers) do
				local pInfo = PlayerInfo.Get(n.username)
				if (utf8.lower(pInfo.username) == utf8.lower(v.username)) then
					v.online = true
					v.room = n.room
					break
				end
				if (pInfo.clan.tag ~= "" and (v.username:match("%b()") or v.username:match("%b[]") or v.username:match("%b{}"))) then
					if (utf8.lower(pInfo.clan.tag) == utf8.lower(v.username:gsub("%W", ""))) then
						table.insert(clanFriends, { username = n.username, online = true, room = n.room })
					end
				end
			end
		end

		-- Remove duplicate entries when one of friends is also found during clan friends search
		for _, v in pairs(self.FriendsList) do
			for n = #clanFriends, 1, -1 do
				if (v.username == utf8.lower(PlayerInfo.Get(clanFriends[n].username).username)) then
					table.remove(clanFriends, n)
				end
			end
		end
		self.ClanFriends = {}
		for _, v in pairs(clanFriends) do
			table.insert(self.ClanFriends, v)
		end
	end

	if (dataReady) then
		updateStates()
		self:showFriends(viewElement)
		return
	end

	local waitSpinner = TBMenu:displayLoadingMark(viewElement)
	waitSpinner:addChild({}):addCustomDisplay(true, function()
			if (dataReady) then
				waitSpinner:kill()
				updateStates()
				self:showFriends(viewElement)
			end
		end)
end

---Refreshes `Friends.IgnoreList` list in a uniform way
function Friends.RefreshIgnoreList()
	local ignoreListRaw = { }
	for _, v in ipairs(get_ignore_list()) do
		if (v ~= nil and v.name ~= nil and string.len(v.name) > 0) then
			table.insert(ignoreListRaw, v)
		end
	end
	Friends.IgnoreList = table.qsort(ignoreListRaw, "name")
end

---Initializes friends and ignore lists
---@return boolean
function Friends.Init()
	Friends.FriendsList = {}
	Friends.IgnoreList = {}

	local file = Files.Open("../data/buddies.txt")
	if (not file.data) then
		runCmd("ab testuser", nil, CMD_ECHO_FORCE_DISABLED)
		runCmd("rb testuser", nil, CMD_ECHO_FORCE_DISABLED)
		file:reopen()
		if (not file.data) then
			return false
		end
	end

	local friendsData = file:readAll()
	file:close()
	for _, ln in pairs(friendsData) do
		local segments = 3
		local data_stream = { ln:match(("([^ ]+) *"):rep(segments)) }
		table.insert(Friends.FriendsList, { username = data_stream[1], online = false, room = false })
	end

	Friends.RefreshIgnoreList()

	return true
end

---Adds a user to friends list
---@param player string
function Friends:addFriend(player)
	local friend = { username = utf8.lower(player), online = false, room = false }
	table.insert(self.FriendsList, friend)
	runCmd("addbuddy " .. friend.username, nil, CMD_ECHO_FORCE_DISABLED)
end

---Removes a user from friends list
---@param player string
function Friends:removeFriend(player)
	for i,v in pairs(self.FriendsList) do
		if (v.username == player) then
			table.remove(self.FriendsList, i)
			break
		end
	end
	runCmd("removebuddy " .. player, nil, CMD_ECHO_FORCE_DISABLED)
end

---Returns whether user with the specified name is a friend
---@param player string
---@return boolean
function Friends:isFriend(player)
	player = string.lower(player)
	for _, v in pairs(self.FriendsList) do
		if (string.lower(v.username) == player) then
			return true
		end
	end
	return false
end

---Adds a user to ignore list with the specified mode
---@param player string
---@param mode IgnoreMode
function Friends:addIgnore(player, mode)
	add_ignore_list(string.lower(player), mode)
	self.RefreshIgnoreList()
end

---Removes a user from ignore list with the specified mode
---@param player string
---@param mode IgnoreMode
function Friends:removeIgnore(player, mode)
	remove_ignore_list(string.lower(player), mode)
	self.RefreshIgnoreList()
end

---Returns whether user with the specified name is being ignored
---@param player string
---@param mode IgnoreMode
---@return boolean
function Friends:isIgnored(player, mode)
	local player = string.lower(player)
	for _, v in pairs(self.IgnoreList) do
		if (string.lower(v.name) == player) then
			return bit.band(v.mode, mode) ~= 0
		end
	end
	return false
end

---Displays friends list in a UIElement viewport
---@param viewElement UIElement
function Friends:showFriends(viewElement)
	viewElement:kill(true)
	local elementHeight = 50
	local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(viewElement, 80, elementHeight + 10, 20, TB_MENU_DEFAULT_BG_COLOR)
	TBMenu:addBottomBloodSmudge(botBar, 1)

	local refreshButtonWidth = math.min(get_string_length(TB_MENU_LOCALIZED.WORDREFRESHACTION, FONTS.MEDIUM) + elementHeight + 30, topBar.size.w / 2 - 20)
	local friendsTitle = topBar:addChild({
		pos = { 10, 5 },
		size = { topBar.size.w - refreshButtonWidth - 30, topBar.size.h / 2 }
	})
	friendsTitle:addAdaptedText(TB_MENU_LOCALIZED.FRIENDSLISTTITLE, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, 0.4)

	local refreshButton = topBar:addChild({
		pos = { -refreshButtonWidth - 10, 10 },
		size = { refreshButtonWidth, elementHeight - 10 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
		shapeType = ROUNDED,
		rounded = 4
	})
	TBMenu:showTextWithImage(refreshButton, TB_MENU_LOCALIZED.WORDREFRESHACTION, FONTS.MEDIUM, 24, "../textures/menu/general/buttons/reload.tga", { imagePadding = 5, floatLeft = true })
	refreshButton:addMouseUpHandler(function()
			viewElement:kill(true)
			self.ListShift = { 0, 0, 0 }
			self:getOnline(viewElement)
		end)
	refreshButton:deactivate(true)
	local updateClock = UIElement.clock
	refreshButton:addCustomDisplay(function()
			if (UIElement.clock - updateClock > RoomList.RefreshPeriod) then
				refreshButton:activate(true)
				refreshButton:addCustomDisplay(function() end)
			end
		end)

	local addFriendBackdrop = botBar:addChild({
		pos = { 20, 5 },
		size = { botBar.size.w - 40, botBar.size.h - 10 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	local addFriendHolder = botBar:addChild({
		pos = { 10, 5 },
		size = { botBar.size.w - math.min(botBar.size.w / 4, 270), botBar.size.h - 10 },
		shapeType = ROUNDED,
		rounded = 4
	})
	local addFriendInput = TBMenu:spawnTextField2(addFriendHolder, nil, nil, TB_MENU_LOCALIZED.FRIENDSLISTSEARCHDEFAULT, {
		fontId = FONTS.LMEDIUM, textScale = 0.85, maxLength = 30, customRegex = "[a-zA-Z0-9_-%[%]%(%)]"
	})
	local addFriendAction = function()
		if (string.len(addFriendInput.textfieldstr[1]) == 0) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.FRIENDSADDERRORNAMEINVALID)
			return
		end
		self:addFriend(addFriendInput.textfieldstr[1])
		self.ListShift = { 0, 0, 0 }
		self:showFriends(viewElement)
	end
	addFriendInput:addEnterAction(addFriendAction)
	local addFriendButton = botBar:addChild({
		pos = { addFriendHolder.shift.x + addFriendHolder.size.w, addFriendHolder.shift.y },
		size = { botBar.size.w - addFriendHolder.shift.x * 2 - addFriendHolder.size.w, addFriendHolder.size.h },
		shapeType = addFriendHolder.shapeType,
		rounded = addFriendHolder.rounded,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	addFriendButton:addChild({ shift = { 10, 5 } }):addAdaptedText(TB_MENU_LOCALIZED.QUEUELISTDROPDOWNADDFRIEND)
	addFriendButton:addMouseUpHandler(addFriendAction)

	local listElements = {}
	---@type FriendInfo[]
	local friendsList = {}
	for _, v in pairs(self.FriendsList) do
		table.insert(friendsList, v)
	end
	for _, v in pairs(self.ClanFriends) do
		table.insert(friendsList, v)
	end
	for _, v in pairs(table.qsort(friendsList, { "username", "online" }, { SORT_ASCENDING, SORT_DESCENDING })) do
		local friendElementHolder = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, friendElementHolder)
		local friendElement = friendElementHolder:addChild({
			pos = { 10, 2 },
			size = { friendElementHolder.size.w - 10, friendElementHolder.size.h - 4 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		local friendOnlineMarker = friendElement:addChild({
			pos = { 10, friendElement.size.h / 3 },
			size = { friendElement.size.h / 3, friendElement.size.h / 3 },
			bgColor = v.online and UICOLORGREEN or TB_MENU_DEFAULT_INACTIVE_COLOR,
			shapeType = ROUNDED,
			rounded = friendElement.size.h / 3
		})
		local friendName = friendElement:addChild({
			pos = { friendOnlineMarker.shift.x * 2 + friendOnlineMarker.size.w, 0 },
			size = { friendElement.size.w / 3, friendElement.size.h }
		})
		friendName:addAdaptedText(true, v.username, nil, nil, nil, LEFTMID)
		if (#listElements == 1) then
			topBar:addChild({
				pos = { 10 + friendName.shift.x, topBar.size.h / 2 + 10 },
				size = { friendName.size.w, topBar.size.h / 2 - 15 }
			}):addAdaptedText(TB_MENU_LOCALIZED.FRIENDSLISTLEGENDPLAYER, nil, nil, FONTS.LMEDIUM, CENTERBOT, 0.65)
			topBar:addChild({
				pos = { 10 + friendName.shift.x + friendName.size.w, topBar.size.h / 2 + 10 },
				size = { (friendElement.size.w - friendName.shift.x - friendName.size.w) / 2, topBar.size.h / 2 - 15 }
			}):addAdaptedText(TB_MENU_LOCALIZED.FRIENDSLISTLEGENDROOM, nil, nil, FONTS.LMEDIUM, CENTERBOT, 0.65)
		end
		local joinButton
		if (v.online) then
			local friendRoomLocation = friendElement:addChild({
				pos = { friendName.shift.x + friendName.size.w, 0 },
				size = { (friendElement.size.w - friendName.shift.x - friendName.size.w) / 2, friendElement.size.h }
			})
			friendRoomLocation:addAdaptedText(true, v.room, nil, nil, 4, nil, 0.75)
			joinButton = friendElement:addChild({
				pos = { friendElement.size.w - friendRoomLocation.size.w, 0 },
				size = { friendRoomLocation.size.w, friendElement.size.h },
				interactive = true,
				clickThrough = true,
				hoverThrough = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			}, true)
			joinButton:addAdaptedText(TB_MENU_LOCALIZED.FRIENDSLISTJOINROOM)
			joinButton:addMouseUpHandler(function()
					runCmd("jo " .. v.room)
					close_menu()
				end)
		end
		if (not v.username:match("[)%]}].+")) then
			local friendRemoveButton = friendElement:addChild({
				pos = { friendElement.size.w - friendElement.size.h, 0 },
				size = { friendElement.size.h, friendElement.size.h },
				interactive = true,
				clickThrough = true,
				hoverThrough = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			}, true)
			if (joinButton) then
				joinButton.size.w = joinButton.size.w - friendRemoveButton.size.w - 5
			end
			friendElement.size.w = friendRemoveButton.shift.x - 5
			friendRemoveButton:addMouseUpHandler(function()
					self:removeFriend(v.username)
					self.ListShift[3] = listingHolder.shift.y < 0 and -listingHolder.shift.y - listingHolder.size.h or 0
					self:showFriends(viewElement)
				end)
			friendRemoveButton:addChild({
				shift = { 5, 5 },
				bgImage = "../textures/menu/general/buttons/crosswhite.tga"
			})
		end
		if (joinButton) then
			friendElement.size.w = joinButton.shift.x - 5
		end
	end
	if (#listElements == 0) then
		local friendsMessageTop = listingView:addChild({
			pos = { 10, 0 },
			size = { listingView.size.w - 20, listingView.size.h / 2 - 5 }
		})
		friendsMessageTop:addAdaptedText(true, TB_MENU_LOCALIZED.FRIENDSLISTEMPTY .. " :(", nil, nil, FONTS.BIG, CENTERBOT)
		local friendsMessageBot = listingView:addChild({
			pos = { 10, listingView.size.h / 2 + 5 },
			size = { listingView.size.w - 20, listingView.size.h / 2 - 5 }
		})
		friendsMessageBot:addAdaptedText(true, TB_MENU_LOCALIZED.FRIENDSLISTEMPTYINFO, nil, nil, nil, CENTER)
	end

	for _, v in pairs(listElements) do
		v:hide()
	end

	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar

	self.ListShift[2] = #listElements * elementHeight
	local targetListShift = self.ListShift[3] > self.ListShift[2] - listingHolder.size.h and self.ListShift[2] - listingHolder.size.h or self.ListShift[3]
	self.ListShift[3] = scrollBar.parent.size.h - scrollBar.size.h
	self.ListShift[1] = targetListShift / (self.ListShift[2] - listingHolder.size.h) * self.ListShift[3]
	scrollBar:makeScrollBar(listingHolder, listElements, toReload, self.ListShift)
end

---@class IgnoreListMode
---@field mode IgnoreMode
---@field icon string
---@field hint string

---Returns table containing available ignore types
---@return IgnoreListMode[]
function Friends:getIgnoreTypes()
	return {
		{	mode = IGNORE_MODE.CHAT,		icon = "../textures/menu/general/buttons/chat.tga",			hint = TB_MENU_LOCALIZED.IGNORELISTCHAT			},
		{	mode = IGNORE_MODE.SOUNDS,		icon = "../textures/menu/general/buttons/sound.tga",		hint = TB_MENU_LOCALIZED.IGNORELISTSOUNDS		},
		{	mode = IGNORE_MODE.PARTICLES,	icon = "../textures/menu/general/buttons/particles.tga",	hint = TB_MENU_LOCALIZED.IGNORELISTPARTICLES	},
		{	mode = IGNORE_MODE.MODELS,		icon = "../textures/menu/general/buttons/objitems.tga",		hint = TB_MENU_LOCALIZED.IGNORELISTMODELS		}
	}
end

---Displays ignore list manage window
---@param username string
---@param targetIgnoreMode ?IgnoreMode
---@param onComplete ?function
function Friends:manageIgnoreList(username, targetIgnoreMode, onComplete)
	username = string.lower(username)
	if (targetIgnoreMode == nil) then
		---@diagnostic disable-next-line: cast-local-type
		targetIgnoreMode = 0
		for _, v in pairs(self.IgnoreList) do
			if (v.name == username) then
				targetIgnoreMode = v.mode
			end
		end
	end

	local overlay = TBMenu:spawnWindowOverlay()
	local ignoreTypes = self:getIgnoreTypes()
	local windowSize = {
		x = math.min(WIN_W / 2, 650),
		y = 140 + #ignoreTypes * 50
	}
	local manageWindow = overlay:addChild({
		shift = { (WIN_W - windowSize.x) / 2, (WIN_H - windowSize.y) / 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local closeButton = manageWindow:addChild({
		pos = { -50, 10 },
		size = { 40, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	closeButton:addChild({ shift = { 5, 5 }, bgImage = "../textures/menu/general/buttons/cross.tga" })
	closeButton:addMouseUpHandler(function()
			overlay:kill()
		end)

	local manageTitle = manageWindow:addChild({
		pos = { 10, 10 },
		size = { manageWindow.size.w - 60, 40 }
	})
	manageTitle:addAdaptedText(true, TB_MENU_LOCALIZED.IGNORELISTMANAGEWINDOW .. " " .. username, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, 0.4)

	local applyButton = manageWindow:addChild({
		pos = { manageWindow.size.w / 4, -60 },
		size = { manageWindow.size.w / 2, 50 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	applyButton:addChild({ shift = { 10, 5 } }):addAdaptedText(true, TB_MENU_LOCALIZED.WORDAPPLY)
	applyButton:addMouseUpHandler(function()
			self:removeIgnore(username, IGNORE_MODE.ALL)
			if (targetIgnoreMode ~= 0) then
				---@diagnostic disable-next-line: param-type-mismatch
				self:addIgnore(username, targetIgnoreMode)
			end
			overlay:kill()
			if (onComplete ~= nil) then
				onComplete()
			end
		end)
	for i, v in pairs(ignoreTypes) do
		local typeHolder = manageWindow:addChild({
			pos = { 40, 70 + 50 * (i - 1) },
			size = { manageWindow.size.w - 80, 50 }
		}, true)
		local typeInfo = typeHolder:addChild({
			pos = { 0, 10 },
			size = { typeHolder.size.w * 0.8, 30 }
		})
		typeInfo:addAdaptedText(true, v.hint, nil, nil, nil, LEFTMID)
		TBMenu:spawnToggle(typeHolder, -40, 5, 40, 40, bit.band(v.mode, targetIgnoreMode) ~= 0, function(val)
				if (val) then
					targetIgnoreMode = bit.bor(targetIgnoreMode, v.mode)
				else
					targetIgnoreMode = bit.bxor(targetIgnoreMode, bit.band(targetIgnoreMode, v.mode))
				end
			end)
	end
end

---Displays ignore list in a UIElement viewport
---@param viewElement UIElement
function Friends:showIgnoreList(viewElement)
	viewElement:kill(true)

	local elementHeight = 50
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(viewElement, elementHeight, elementHeight + 10, 20, TB_MENU_DEFAULT_BG_COLOR)
	TBMenu:addBottomBloodSmudge(botBar, 1)
	topBar:addChild({ shift = { 10, 5 } }):addAdaptedText(TB_MENU_LOCALIZED.IGNORELISTTITLE, nil, nil, FONTS.BIG, nil, 0.65, nil, 0.4)

	local ignoreInputHolder = botBar:addChild({
		shift = { 10, 5 },
		shapeType = ROUNDED,
		rounded = 4
	})
	local ignoreInputBackdrop = ignoreInputHolder:addChild({
		shift = { 10, 0 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	local ignoreInput = TBMenu:spawnTextField2(ignoreInputHolder, { w = ignoreInputHolder.size.w - ignoreInputHolder.size.h	}, nil, TB_MENU_LOCALIZED.IGNORELISTINPUTHINT, { fontId = FONTS.LMEDIUM, textScale = 0.85, maxLength = 30, customRegex = "[a-zA-Z0-9_-]" })
	local addIgnoreAction = function()
		if (string.len(ignoreInput.textfieldstr[1]) == 0) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.IGNORELISTADDERRORNAMEINVALID)
			return
		end
		self:manageIgnoreList(ignoreInput.textfieldstr[1], nil, function() self:showIgnoreList(viewElement) end)
	end
	ignoreInput:addEnterAction(addIgnoreAction)
	local ignoreAddButton = ignoreInputHolder:addChild({
		pos = { -ignoreInputHolder.size.h, 0 },
		size = { ignoreInputHolder.size.h, ignoreInputHolder.size.h },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		bgImage = "../textures/menu/general/buttons/addsign.tga"
	}, true)
	ignoreAddButton:addMouseUpHandler(addIgnoreAction)

	local ignoreTypes = self:getIgnoreTypes()
	local listElements = {}
	for _, v in pairs(self.IgnoreList) do
		local elementHolder = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, elementHolder)
		local element = elementHolder:addChild({
			pos = { 5, 2 },
			size = { elementHolder.size.w - elementHolder.size.h - 6, elementHolder.size.h - 4 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		local iconHolderWidth = math.min((#ignoreTypes + 1) * element.size.h, element.size.w / 2)
		local iconButtonWidth = iconHolderWidth / (#ignoreTypes + 1)
		local nameHolder = element:addChild({
			pos = { 10, 3 },
			size = { element.size.w - iconHolderWidth - 30, element.size.h - 6 }
		})
		nameHolder:addAdaptedText(true, v.name, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)

		local editButton = elementHolder:addChild({
			pos = { -element.size.h, element.shift.y },
			size = { element.size.h, element.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = element.shapeType,
			rounded = element.rounded
		})
		editButton:addChild({ shift = { 3, 3 }, bgImage = "../textures/menu/general/buttons/edit.tga" })
		editButton:addMouseUpHandler(function()
				self:manageIgnoreList(v.name, v.mode, function()
						self:showIgnoreList(viewElement)
					end)
			end)

		local iconsDisplayed = 0
		for _, ignore in pairs(ignoreTypes) do
			if (bit.band(ignore.mode, v.mode) ~= 0) then
				iconsDisplayed = iconsDisplayed + 1
				local icon = element:addChild({
					pos = { -iconButtonWidth * iconsDisplayed - 6, (element.size.h - iconButtonWidth) / 2 },
					size = { iconButtonWidth, iconButtonWidth },
					bgImage = ignore.icon,
					interactive = true,
					imageColor = { 1, 1, 1, 0.9 },
					imageHoverColor = UICOLORWHITE,
					imagePressedColor = UICOLORWHITE
				})
				local popup = TBMenu:displayPopup(icon, ignore.hint, true)
				if (popup ~= nil) then
					popup:moveTo(-popup.size.w - iconButtonWidth - 5)
				end
			end
		end
	end

	for _, v in pairs(listElements) do
		v:hide()
	end

	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar
	scrollBar:makeScrollBar(listingHolder, listElements, toReload)
end

function Friends:showMain(viewElement)
	usage_event("friendslist")
	viewElement:kill(true)
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 8

	self.ListShift = { 0, 0, 0 }
	local friendsView = viewElement:addChild({
		pos = { 5, 0 },
		size = { viewElement.size.w * 0.7 - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:addBottomBloodSmudge(friendsView, 1)
	self:getOnline(friendsView)

	local friendsMenu = viewElement:addChild({
		pos = { friendsView.size.w + 15, 0 },
		size = { viewElement.size.w - friendsView.size.w - 20, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:addBottomBloodSmudge(friendsMenu, 2)
	self:showIgnoreList(friendsMenu)
end

Friends.Init()
