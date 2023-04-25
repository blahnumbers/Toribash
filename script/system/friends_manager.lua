---@class FriendInfo
---@field username string
---@field online boolean
---@field room string

if (Friends == nil) then
	---**Friends Manager Class**
	---
	---**Version 5.60**
	---* Changed class name from FriendsList to Friends
	---* Added EmmyLua annotations
	---* Use new room list functionality to search for online friends
	---@class Friends
	---@field FriendsList FriendInfo[]
	---@field ClanFriends FriendInfo[]
	---@field IgnoreList string[]
	Friends = {
		FriendsList = {},
		IgnoreList = {},
		ClanFriends = {},
		ver = 5.60
	}
	Friends.__index = Friends
	setmetatable({}, Friends)
end

function Friends:quit()
	if (get_option("newmenu") == 0) then
		TBMenu.MenuMain:kill()
		remove_hooks("tbMainMenuVisual")
		return
	end
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
	TBMenu.CurrentSection:kill(true)
	TBMenu.NavigationBar:kill(true)
	TBMenu:showNavigationBar()
	TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
end

function Friends:getNavigationButtons()
	local buttonText = get_option("newmenu") == 0 and TB_MENU_LOCALIZED.NAVBUTTONEXIT or TB_MENU_LOCALIZED.NAVBUTTONTOMAIN
	local navigation = {
		{
			text = buttonText,
			action = function() Friends:quit() end,
			width = get_string_length(buttonText, FONTS.BIG) * 0.65 + 30
		}
	}
	return navigation
end

function Friends:getOnline(viewElement)
	local dataReady = true
	if (RoomList.RefreshIfNeeded()) then
		dataReady = false
		add_hook("roomlist_update", "friendsRoomListWaiter", function() dataReady = true end)
	end

	local function updateStates()
		local onlinePlayers = RoomList.GetPlayers()
		local clanFriends = {}

		for _, v in pairs(self.FriendsList) do
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
		Friends:showFriends(viewElement)
		return
	end

	local waitSpinner = TBMenu:displayLoadingMark(viewElement)
	waitSpinner:addChild({}):addCustomDisplay(true, function()
			if (dataReady) then
				waitSpinner:kill()
				updateStates()
				Friends:showFriends(viewElement)
			end
		end)
end

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

	local ignoreFile = Files.Open("../ignorelist.txt")
	if (ignoreFile.data) then
		local ignoreData = ignoreFile:readAll()
		ignoreFile:close()
		for _, ln in pairs(ignoreData) do
			table.insert(Friends.IgnoreList, ln)
		end
	end

	return true
end

function Friends:addFriend(player)
	local friend = { username = utf8.lower(player), online = false, room = false }
	table.insert(self.FriendsList, friend)
	runCmd("addbuddy " .. friend.username, nil, CMD_ECHO_FORCE_DISABLED)
end

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
	local player = utf8.lower(player)
	for _, v in pairs(self.FriendsList) do
		if (utf8.lower(v.username) == player) then
			return true
		end
	end
	return false
end

function Friends:addIgnore(player)
	local player = player:lower()
	table.insert(self.IgnoreList, player)
	runCmd("ignore add " .. player, nil, CMD_ECHO_FORCE_DISABLED)
end

function Friends:removeIgnore(player)
	local player = player:lower()
	for i,v in pairs(self.IgnoreList) do
		if (v == player) then
			table.remove(self.IgnoreList, i)
			break
		end
	end
	runCmd("ignore remove " .. player, nil, CMD_ECHO_FORCE_DISABLED)
end

---Returns whether user with the specified name is being ignored
---@param player string
---@return boolean
function Friends:isIgnored(player)
	local player = utf8.lower(player)
	for _, v in pairs(self.IgnoreList) do
		if (utf8.lower(v) == player) then
			return true
		end
	end
	return false
end

function Friends:showFriendsList(viewElement)
	local elementHeight = 40
	local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(viewElement, elementHeight, elementHeight + 10, 20, TB_MENU_DEFAULT_BG_COLOR)
	TBMenu:addBottomBloodSmudge(botBar, 1)

	local listElements = {}
	---@type FriendInfo[]
	local friendsList = {}
	for _, v in pairs(Friends.FriendsList) do
		table.insert(friendsList, v)
	end
	for _, v in pairs(Friends.ClanFriends) do
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
				pos = { 10 + friendName.shift.x, 0 },
				size = { friendName.size.w, topBar.size.h }
			}):addAdaptedText(TB_MENU_LOCALIZED.FRIENDSLISTLEGENDPLAYER, nil, nil, FONTS.LMEDIUM, nil, 0.65)
			topBar:addChild({
				pos = { 10 + friendName.shift.x + friendName.size.w, 0 },
				size = { (friendElement.size.w - friendName.shift.x - friendName.size.w) / 2, topBar.size.h }
			}):addAdaptedText(TB_MENU_LOCALIZED.FRIENDSLISTLEGENDROOM, nil, nil, FONTS.LMEDIUM, nil, 0.65)
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
				Friends:removeFriend(v.username)
				Friends:showFriends(viewElement.parent)
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
	scrollBar:makeScrollBar(listingHolder, listElements, toReload)

	local friendsRefresh = botBar:addChild({
		shift = { botBar.size.w / 3, 5 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	friendsRefresh:addAdaptedText(TB_MENU_LOCALIZED.FRIENDSLISTREFRESH)
	friendsRefresh:addMouseUpHandler(function()
			local friendsView = viewElement.parent
			viewElement:kill()
			Friends:getOnline(friendsView)
		end)
end

function Friends:showFriends(viewElement)
	viewElement:kill(true)
	local headerTitle = UIElement:new({
		parent = viewElement,
		pos = { 0, 0 },
		size = { viewElement.size.w, 50 }
	})
	local titleTextScale = 0.7
	while (not headerTitle:uiText(TB_MENU_LOCALIZED.FRIENDSLISTTITLE, nil, nil, FONTS.BIG, 0, titleTextScale, nil, nil, nil, nil, nil, true)) do
		titleTextScale = titleTextScale - 0.05
	end
	headerTitle:addCustomDisplay(true, function()
			headerTitle:uiText(TB_MENU_LOCALIZED.FRIENDSLISTTITLE, nil, nil, FONTS.BIG, nil, titleTextScale)
		end)

	local friendsView = viewElement:addChild({
		pos = { 0, headerTitle.size.h },
		size = { viewElement.size.w, viewElement.size.h - headerTitle.size.h }
	})
	Friends:showFriendsList(friendsView)
end

function Friends:showMenu(viewElement)
	local friendAddView = UIElement:new({
		parent = viewElement,
		pos = { 0, 0 },
		size = { viewElement.size.w, viewElement.size.h / 4 }
	})
	local imageSize = viewElement.size.w / 4 * 5 < viewElement.size.h / 7 * 5 and viewElement.size.w / 4 * 5 or viewElement.size.h / 7 * 5
	local friendImage = UIElement:new({
		parent = viewElement,
		pos = { imageSize > viewElement.size.w and -viewElement.size.w - (imageSize - viewElement.size.w) / 2 or (viewElement.size.w - imageSize) / 2, viewElement.size.h / 3 + (viewElement.size.h / 7 * 4 - imageSize) / 2 },
		size = { imageSize, imageSize },
		bgImage = "../textures/menu/friendslist.tga"
	})
	local friendAddTitle = UIElement:new({
		parent = friendAddView,
		pos = { 0, 0 },
		size = { friendAddView.size.w, friendAddView.size.h / 2 }
	})
	friendAddTitle:addCustomDisplay(true, function()
			friendAddTitle:uiText(TB_MENU_LOCALIZED.FRIENDSLISTADDFRIEND)
		end)
	local elementHeight = friendAddView.size.h / 2 > 30 and 30 or friendAddView.size.h / 2
	local friendAddInputBG = UIElement:new({
		parent = friendAddView,
		pos = { elementHeight / 2, friendAddView.size.h / 2 },
		size = { friendAddView.size.w - elementHeight, elementHeight },
		shapeType = ROUNDED,
		rounded = 3
	})
	friendAddInputBG:addCustomDisplay(true, function() end)
	local friendAddInputField = TBMenu:spawnTextField2(friendAddInputBG, {
		w = friendAddInputBG.size.w - elementHeight - 5
	}, nil, TB_MENU_LOCALIZED.FRIENDSLISTSEARCHDEFAULT, {
		fontId = 4,
		textScale = 0.75,
		textColor = UICOLORWHITE
	})
	friendAddInputField:addEnterAction(function()
			Friends:addFriend(friendAddInputField.textfieldstr[1])
			Friends:showMain(viewElement.parent)
		end)
	local addFriendButton = UIElement:new({
		parent = friendAddInputBG,
		pos = { -elementHeight, 0 },
		size = { elementHeight, elementHeight },
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.6 },
		pressedColor = { 0, 1, 0, 0.6 },
		shapeType = ROUNDED,
		rounded = 3
	})
	addFriendButton:addCustomDisplay(false, function()
			set_color(1, 1, 1, 1)
			draw_quad(	addFriendButton.pos.x + addFriendButton.size.w / 2 - 1,
						addFriendButton.pos.y + addFriendButton.size.h / 6,
						2,
						addFriendButton.size.h / 6 * 4	)
			draw_quad(	addFriendButton.pos.x + addFriendButton.size.w / 6,
						addFriendButton.pos.y + addFriendButton.size.h / 2 - 1,
						addFriendButton.size.w / 6 * 4,
						2	)
		end)
	addFriendButton:addMouseHandlers(nil, function()
			Friends:addFriend(friendAddInputField.textfieldstr[1])
			Friends:showMain(viewElement.parent)
		end)
end

function Friends:showMain(viewElement)
	usage_event("friendslist")
	viewElement:kill(true)
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 8
	local friendsView = UIElement:new({
		parent = viewElement,
		pos = { 5, 0 },
		size = { viewElement.size.w * 0.7 - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:addBottomBloodSmudge(friendsView, 1)
	Friends:getOnline(friendsView)

	local friendsMenu = UIElement:new({
		parent = viewElement,
		pos = { friendsView.size.w + 15, 0 },
		size = { viewElement.size.w - friendsView.size.w - 20, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:addBottomBloodSmudge(friendsMenu, 2)
	Friends:showMenu(friendsMenu)
end

Friends.Init()
