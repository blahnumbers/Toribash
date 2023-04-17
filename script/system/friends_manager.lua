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
	---@field IgnoreList string[]
	Friends = {
		FriendsList = {},
		IgnoreList = {}
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

function Friends:getOnline(viewElement, noWait)
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
				if (v.username == PlayerInfo.Get(clanFriends[n].username).username) then
					table.remove(clanFriends, n)
				end
			end
		end
		for _, v in pairs(clanFriends) do
			table.insert(self.FriendsList, v)
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

	local file = Files:open("../data/buddies.txt")
	if (not file.data) then
		runCmd("ab testuser", nil, CMD_ECHO_FORCE_DISABLED)
		runCmd("rb testuser", nil, CMD_ECHO_FORCE_DISABLED)
		file:reopen()
		if (not file.data) then
			return false
		end
	end

	for _, ln in pairs(file:readAll()) do
		local segments = 3
		local data_stream = { ln:match(("([^ ]+) *"):rep(segments)) }
		table.insert(Friends.FriendsList, { username = data_stream[1], online = false, room = false })
	end

	file:close()
	local ignoreFile = Files:open("../ignorelist.txt")
	if (ignoreFile.data) then
		for _, ln in pairs(ignoreFile:readAll()) do
			table.insert(Friends.IgnoreList, ln)
		end
		ignoreFile:close()
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
	local entryHeight = 35

	local toReload = UIElement:new({
		parent = viewElement,
		pos = { 0, 0 },
		size = { viewElement.size.w, viewElement.size.h}
	})

	local friendsTopBar = UIElement:new({
		parent = toReload,
		pos = { 0, 0 },
		size = { viewElement.size.w, entryHeight },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
	})
	local friendsBotBar = UIElement:new({
		parent = toReload,
		pos = { 0, -entryHeight },
		size = { viewElement.size.w, entryHeight },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
	})
	TBMenu:addBottomBloodSmudge(friendsBotBar, 1)

	local friendsMain = UIElement:new({
		parent = viewElement,
		pos = { 0, friendsTopBar.size.h },
		size = { friendsTopBar.size.w, viewElement.size.h - friendsTopBar.size.h - friendsBotBar.size.h }
	})
	local friendsView = UIElement:new({
		parent = friendsMain,
		pos = { 0, 0 },
		size = { friendsMain.size.w - 20, friendsMain.size.h }
	})

	local friendsElements = {}
	for i,v in pairs(table.qsort(Friends.FriendsList, "online", true)) do
		local friendElement = UIElement:new({
			parent = friendsView,
			pos = { 0, (i - 1) * entryHeight },
			size = { friendsView.size.w, entryHeight },
			bgColor = i % 2 == 1 and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_DARKER_COLOR
		})
		table.insert(friendsElements, friendElement)
		local friendOnlineMarker = UIElement:new({
			parent = friendElement,
			pos = { friendElement.size.w / 40, friendElement.size.h / 3 },
			size = { friendElement.size.h / 3, friendElement.size.h / 3 },
			bgColor = v.online and UICOLORGREEN or { 0.8, 0.8, 0.8, 1},
			shapeType = ROUNDED,
			rounded = friendElement.size.h
		})
		local friendName = UIElement:new({
			parent = friendElement,
			pos = { friendOnlineMarker.shift.x + friendElement.size.h / 3 * 2, 0 },
			size = { friendElement.size.w / 3, friendElement.size.h }
		})
		friendName:addCustomDisplay(true, function()
				friendName:uiText(v.username, nil, nil, nil, LEFTMID)
			end)
		if (v.online) then
			local friendRoomLocation = UIElement:new({
				parent = friendElement,
				pos = { friendName.shift.x + friendName.size.w, 0 },
				size = { (friendElement.size.w - friendName.shift.x - friendName.size.w) / 2, friendElement.size.h }
			})
			friendRoomLocation:addCustomDisplay(false, function()
					friendRoomLocation:uiText(v.room, nil, nil, 4, nil, 0.75)
				end)
			local friendRoomJoinButton = UIElement:new({
				parent = friendElement,
				pos = { friendElement.size.w - friendRoomLocation.size.w, 5 },
				size = { friendRoomLocation.size.w - friendElement.size.h, friendElement.size.h - 10 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.2 }
			})
			friendRoomJoinButton:addCustomDisplay(false, function()
					friendRoomJoinButton:uiText(TB_MENU_LOCALIZED.FRIENDSLISTJOINROOM, nil, nil, nil, nil, 0.8)
				end)
			friendRoomJoinButton:addMouseHandlers(nil, function()
					runCmd("jo " .. v.room)
					close_menu()
				end)
		end
		if (not v.username:match("[)%]}].+")) then
			local friendRemoveButton = UIElement:new({
				parent = friendElement,
				pos = { friendElement.size.w - friendElement.size.h + 5, 5 },
				size = { friendElement.size.h - 10, friendElement.size.h - 10 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 1, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.5 },
				bgImage = "../textures/menu/general/buttons/crosswhite.tga"
			})
			friendRemoveButton:addMouseHandlers(nil, function()
				Friends:removeFriend(v.username)
				Friends:showFriends(viewElement.parent)
			end)
		end
	end
	if (#friendsElements == 0) then
		local friendsMessageTop = UIElement:new({
			parent = friendsView,
			pos = { 10, 0 },
			size = { friendsView.size.w - 20, friendsView.size.h / 2 - 5 }
		})
		friendsMessageTop:addAdaptedText(true, TB_MENU_LOCALIZED.FRIENDSLISTEMPTY .. " :(", nil, nil, FONTS.BIG, CENTERBOT)
		local friendsMessageBot = UIElement:new({
			parent = friendsView,
			pos = { 10, friendsView.size.h / 2 + 5 },
			size = { friendsView.size.w - 20, friendsView.size.h / 2 - 5 }
		})
		friendsMessageBot:addAdaptedText(true, TB_MENU_LOCALIZED.FRIENDSLISTEMPTYINFO, nil, nil, nil, CENTER)
	end

	for i,v in pairs(friendsElements) do
		v:hide()
	end

	local friendsScrollBG = UIElement:new({
		parent = friendsMain,
		pos = { -(friendsMain.size.w - friendsView.size.w), 0 },
		size = { friendsMain.size.w - friendsView.size.w, friendsView.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})

	local friendsScrollBar = TBMenu:spawnScrollBar(friendsView, #friendsElements, entryHeight)
	friendsScrollBar:makeScrollBar(friendsView, friendsElements, toReload)

	local legendInfo = {
		{ name = "", width = friendsView.size.w / 40 + entryHeight},
		{ name = TB_MENU_LOCALIZED.FRIENDSLISTLEGENDPLAYER, width = friendsView.size.w / 3 },
		{ name = TB_MENU_LOCALIZED.FRIENDSLISTLEGENDROOM, width = (friendsView.size.w * 2 / 3 - friendsView.size.w / 40 - entryHeight * 2 + 10) / 2 }
	}
	local legendShiftX = 0
	for i = 1, #legendInfo do
		local legendElement = UIElement:new({
			parent = friendsTopBar,
			pos = { legendShiftX, 0 },
			size = { legendInfo[i].width, friendsTopBar.size.h }
		})
		legendShiftX = legendShiftX + legendElement.size.w
		legendElement:addCustomDisplay(true, function()
				legendElement:uiText(legendInfo[i].name, nil, nil, 4, nil, 0.6)
			end)
	end
	local friendsRefresh = UIElement:new({
		parent = friendsBotBar,
		pos = { friendsBotBar.size.w / 4, 5 },
		size = { friendsBotBar.size.w / 2, friendsBotBar.size.h - 5 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 0, 0, 0.2 }
	})
	friendsRefresh:addCustomDisplay(false, function()
			friendsRefresh:uiText(TB_MENU_LOCALIZED.FRIENDSLISTREFRESH)
		end)
	friendsRefresh:addMouseHandlers(nil, function()
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

	local friendsView = UIElement:new({
		parent = viewElement,
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
			Friends:showMain(viewElement.parent, true)
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
			Friends:showMain(viewElement.parent, true)
		end)
end

function Friends:showMain(viewElement, noWait)
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
	Friends:getOnline(friendsView, noWait)

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
