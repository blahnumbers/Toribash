local FILTER_ANY = nil
local FILTER_OFF = false
local FILTER_ON = true

---@alias RoomListFilterState
---| nil	#FILTER_ANY
---| false	#FILTER_OFF
---| true	#FILTER_ON

---@class RoomListFilters
---@field MatchesBelt RoomListFilterState
---@field PasswordProtected RoomListFilterState
---@field IsTournament RoomListFilterState
---@field IsOfficial RoomListFilterState
---@field IsRanked RoomListFilterState
---@field DuelMode RoomListFilterState
---@field HasEntryFee RoomListFilterState
---@field SortBy string[]
---@field SortOrder SortOrder[]
---@field IsDefault boolean

if (RoomList == nil) then
	---**Room List manager class**
	---
	---**Version 5.60**
	---* Initial release
	---@class RoomList
	---@field RefreshPeriod number Time in seconds before room cache is considered stale
	---@field MainListView UIElement Room list holder element
	---@field SelectedButton UIElement Currently selected room list button
	---@field RoomInfoView UIElement Room information holder element
	---@field Filters RoomListFilters
	RoomList = {
		ver = 5.60,
		RefreshPeriod = 60,
		Filters = { }
	}
	RoomList.__index = RoomList
	setmetatable({}, RoomList)
end

---@class RoomListInfoExtended : RoomListInfo
---@field id integer Room id incremented by 1 to match Lua style
---@field desc_clean string Color-coding free room description
---@field mod string Mod name, this is identical to `gamerules.mod`

---**Room List internal helper class**
---@class RoomListInternal
---@field Cache RoomListInfoExtended[] List of cached rooms
---@field UpdateError string|nil
---@field UpdateTimestamp number
local RoomListInternal = {
	Cache = { },
	UpdateTimestamp = -10000,
	UpdateError = nil
}

function RoomListInternal.RefreshData()
	refresh_roomlist()
end

---Resets cache state to its default value and sets current time as last update timestamp
---@param reload ?boolean
function RoomListInternal.ResetCache(reload)
	RoomListInternal.Cache = { }
	RoomListInternal.UpdateError = nil
	RoomListInternal.UpdateTimestamp = reload and -10000 or os.clock_real()
end

---Retrieves room information and stores it in cache
function RoomListInternal.CacheRooms()
	local numRooms = get_roomlist_num_rooms()
	if (numRooms ~= nil) then
		for i = 0, numRooms - 1 do
			local roomInfo = get_roomlist_room_info(i)
			if (roomInfo ~= nil) then
				roomInfo.desc_clean = stripColors(roomInfo.desc)
				roomInfo.id = roomInfo.id + 1 ---Make ids match Lua style
				roomInfo.mod = roomInfo.gamerules.mod
				table.insert(RoomListInternal.Cache, roomInfo)
			end
		end
	end
	if (TB_MENU_SPECIAL_SCREEN_ISOPEN == 2) then
		RoomList:showMain()
	end
end

---Connects to the specified room and closes menu
---@param room RoomListInfoExtended
function RoomListInternal.Connect(room)
	local hostnameClean = utf8.gsub(room.hostname, ":", " ")
	runCmd("co " .. hostnameClean)
	close_menu()
end

---Returns navigation buttons data for Room List class
---@return MenuNavButton[]
function RoomListInternal.GetNavigationButtons()
	---@type MenuNavButton[]
	local navigationButtons = {
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
			action = function()
				TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
				TBMenu:clearNavSection()
				TBMenu:showNavigationBar()
				TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
			end
		},
		{
			text = TB_MENU_LOCALIZED.WORDREFRESHACTION,
			action = function()
				RoomListInternal.ResetCache(true)
				RoomList:showMain()
			end,
			right = true
		},
		{
			text = TB_MENU_LOCALIZED.ROOMLISTFILTERS,
			action = function()
				RoomList:showFilters()
			end,
			right = true
		}
	}
	return navigationButtons
end

---Displays information about the specified room
---@param room RoomListInfoExtended
function RoomList:showRoomInfo(room)
	local elementHeight = math.max(20, WIN_H / 40)
	local buttonHeight = math.min(self.RoomInfoView.size.h / 6, 50)
	local toReload, topBar, botBar, listingView, listingHolder, scrollBarBG = TBMenu:prepareScrollableList(self.RoomInfoView, elementHeight, buttonHeight, 15, TB_MENU_DEFAULT_BG_COLOR)

	listingView.bgColor = table.clone(TB_MENU_DEFAULT_LIGHTEST_COLOR)
	listingView.shapeType = ROUNDED
	listingView:setRounded({ 4, 0 })
	listingHolder.uiColor = table.clone(UICOLORBLACK)
	scrollBarBG.bgColor = { 0, 0, 0, 0 }
	local joinRoomButton = botBar:addChild({
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = { 0, 4 }
	})
	joinRoomButton:addChild({ 10, 5 }):addAdaptedText(true, TB_MENU_LOCALIZED.FRIENDSLISTJOINROOM)
	joinRoomButton:addMouseUpHandler(function()
			RoomListInternal.Connect(room)
		end)

	local infoBits = {
		TB_MENU_LOCALIZED.ROOMLISTROOMNAME .. ": " .. room.name,
		room.desc_clean,
		TB_MENU_LOCALIZED.ROOMLISTROOMMOD .. ": " .. room.gamerules.mod
	}
	if (room.is_password_protected) then
		table.insert(infoBits, TB_MENU_LOCALIZED.ROOMLISTPRIVATEINFO)
	end
	if (room.is_tournament) then
		table.insert(infoBits, TB_MENU_LOCALIZED.ROOMLISTTOURNAMENT)
	end
	if (room.is_duel_mode) then
		table.insert(infoBits, TB_MENU_LOCALIZED.ROOMLISTDUELMODEON .. (room.duel_amount ~= nil and (": " .. room.duel_amount .. " " .. TB_MENU_LOCALIZED.WORDTC) or ""))
	end
	if (room.is_ranked) then
		table.insert(infoBits, TB_MENU_LOCALIZED.ROOMLISTRANKED)
	end
	if (room.gamerules.reactiontime < 15) then
		table.insert(infoBits, TB_MENU_LOCALIZED.ROOMLISTQUICKREACTIONROOM)
	end
	if (room.num_players > 0) then
		table.insert(infoBits, "")
		table.insert(infoBits, TB_MENU_LOCALIZED.ROOMLISTROOMPLAYERS)
		for _, v in pairs(room.players) do
			if (utf8.find(v, "^​")) then
				v = "^08" .. v
			end
			table.insert(infoBits, "  " .. v)
		end
	end

	local listElements = {}
	for _, v in pairs(infoBits) do
		local infoBitElement = listingHolder:addChild({
			pos = { 10, #listElements * elementHeight },
			size = { listingHolder.size.w - 20, elementHeight }
		})
		table.insert(listElements, infoBitElement)
		infoBitElement:addAdaptedText(true, v, nil, nil, 1, LEFTMID, 1, 1)
		if (#infoBitElement.dispstr > 1) then
			for i = 2, #infoBitElement.dispstr do
				local infoBitElementExtra = listingHolder:addChild({
					pos = { infoBitElement.shift.x, #listElements * elementHeight },
					size = { infoBitElement.size.w, elementHeight }
				})
				infoBitElementExtra:addAdaptedText(true, infoBitElement.dispstr[i], nil, nil, 1, LEFTMID, 1, 1)
				table.insert(listElements, infoBitElementExtra)
				infoBitElementExtra:hide(true)

				infoBitElement:addAdaptedText(true, infoBitElement.dispstr[1], nil, nil, 1, LEFTMID, 1, 1)
			end
		end
		infoBitElement:hide(true)
	end

	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar
	scrollBar:makeScrollBar(listingHolder, listElements, toReload)
end

---Displays room list legend
---@param viewElement UIElement
function RoomList:showRoomListLegend(viewElement)
	---Same struct as in RoomList:showRoomListButton()
	local datasToDisplay = {
		{
			value = TB_MENU_LOCALIZED.ROOMLISTROOMID, width = 0.05,
			orientation = CENTERBOT,
			sortOptions = { sortBy = "id", sortOrder = SORT_ASCENDING }
		},
		{
			value = TB_MENU_LOCALIZED.ROOMLISTROOMNAME, width = 0.15,
			sortOptions = { sortBy = "name", sortOrder = SORT_ASCENDING }
		},
		{
			value = TB_MENU_LOCALIZED.ROOMLISTROOMDESC,
			width = 0.35,
			sortOptions = { sortBy = "desc_clean", sortOrder = SORT_ASCENDING }
		},
		{
			value = TB_MENU_LOCALIZED.ROOMLISTROOMMOD,
			orientation = CENTERBOT,
			width = 0.20,
			sortOptions = { sortBy = "mod", sortOrder = SORT_ASCENDING }
		},
		{
			value = TB_MENU_LOCALIZED.ROOMLISTROOMMINBELT,
			width = 0.075,
			orientation = CENTERBOT,
			sortOptions = { sortBy = "min_belt", sortOrder = SORT_ASCENDING }
		},
		{
			value = TB_MENU_LOCALIZED.ROOMLISTROOMMAXBELT,
			width = 0.075,
			orientation = CENTERBOT,
			sortOptions = { sortBy = "max_belt", sortOrder = SORT_DESCENDING }
		},
		{
			value = TB_MENU_LOCALIZED.ROOMLISTROOMPLAYERS,
			width = 0.1,
			orientation = CENTERBOT,
			sortOptions = { sortBy = "num_players", sortOrder = SORT_DESCENDING }
		}
	}
	local legendHolder = viewElement:addChild({
		pos = { 10, 0 },
		size = { viewElement.size.w - 32, viewElement.size.h - 6 }
	})
	local shiftWidth = math.min(10, legendHolder.size.w / 50)
	local shiftX = shiftWidth
	local availableAreaX = legendHolder.size.w - shiftWidth * #datasToDisplay
	local minScale = 1
	for _, v in pairs(datasToDisplay) do
		local infoBit = legendHolder:addChild({
			pos = { shiftX, 6 },
			size = { availableAreaX * v.width, legendHolder.size.h - 6 },
			interactive = true,
			bgColor = UICOLORWHITE,
			hoverColor = TB_MENU_DEFAULT_ORANGE,
			pressedColor = TB_MENU_DEFAULT_YELLOW
		})
		infoBit:addAdaptedText(true, v.value, nil, nil, nil, v.orientation or LEFTBOT)
		infoBit:addMouseUpHandler(function()
				self.Filters.IsDefault = false
				for i = #self.Filters.SortBy, 1, -1 do
					if (self.Filters.SortBy[i] == v.sortOptions.sortBy) then
						self.Filters.SortOrder[i] = not self.Filters.SortOrder[i]
					else
						table.remove(self.Filters.SortBy, i)
						table.remove(self.Filters.SortOrder, i)
					end
				end
				if (#self.Filters.SortBy == 0) then
					table.insert(self.Filters.SortBy, v.sortOptions.sortBy)
					table.insert(self.Filters.SortOrder, v.sortOptions.sortOrder)
				end

				---Mark cache recent so we don't start a refresh on showMain() call
				RoomListInternal.UpdateTimestamp = UIElement.clock
				self:showRoomList(self.MainListHolder)
			end)

		minScale = math.min(minScale, infoBit.textScale)
		v.element = infoBit
		shiftX = shiftX + infoBit.size.w + shiftWidth
	end
	for _, v in pairs(datasToDisplay) do
		v.element:addCustomDisplay(true, function()
			v.element:uiText(v.element.str, nil, nil, v.element.textFont, v.orientation or LEFTBOT, minScale, nil, nil, v.element:getButtonColor())
		end)
	end
end

---Generic function to display room list buttons
---@param viewElement UIElement
---@param room RoomListInfoExtended
---@return UIElement
function RoomList:showRoomListButton(viewElement, room)
	local matchesBelt = room.min_belt <= TB_MENU_PLAYER_INFO.data.qi and (room.max_belt == 0 or room.max_belt >= TB_MENU_PLAYER_INFO.data.qi)
	local roomButton = viewElement:addChild({
		pos = { 10, 2 },
		size = { viewElement.size.w - 12, viewElement.size.h - 4 },
		interactive = true,
		clickThrough = true,
		hoverThrough = true,
		shapeType = ROUNDED,
		rounded = 4,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		uiColor = matchesBelt and { 1, 1, 1, 1 } or { 1, 1, 1, 0.6 }
	})
	roomButton:addMouseUpHandler(function()
			if (roomButton.lastClick ~= nil and roomButton.lastClick + 0.5 > UIElement.clock) then
				RoomListInternal.Connect(room)
				return
			end
			roomButton.lastClick = UIElement.clock

			if (self.SelectedButton ~= nil and not self.SelectedButton.destroyed) then
				self.SelectedButton.bgColor = table.clone(self.SelectedButton.defaultBgColor)
			end
			self.SelectedButton = roomButton
			self.SelectedButton.defaultBgColor = table.clone(self.SelectedButton.bgColor)
			self.SelectedButton.bgColor = table.clone(TB_MENU_DEFAULT_LIGHTER_COLOR)
			self:showRoomInfo(room)
		end)

	local minBeltInfo = PlayerInfo.getBeltFromQi(room.min_belt)
	local maxBeltInfo = PlayerInfo.getBeltFromQi(room.max_belt)
	local datasToDisplay = {
		{
			value = room.id, width = 0.05,				-- 0.05
			orientation = CENTERMID
		},
		{
			value = room.name, width = 0.15				-- 0.20
		},
		{
			value = room.desc_clean,
			width = 0.35,								-- 0.55
			shadowValue = room.desc,
			textIcon = room.is_password_protected and "../textures/menu/general/buttons/locked.tga" or nil,
			textIconHint = TB_MENU_LOCALIZED.ROOMLISTPRIVATEINFO
		},
		{
			value = utf8.gsub(room.gamerules.mod, "%.tbm$", ""),
			orientation = CENTERMID,
			width = 0.20								-- 0.75
		},
		{
			value = room.min_belt .. " " .. TB_MENU_LOCALIZED.WORDQI .. "\n" .. minBeltInfo.name .. " " .. TB_MENU_LOCALIZED.WORDBELT,
			icon = minBeltInfo.icon,
			width = 0.075,								-- 0.825
			orientation = CENTERMID
		},
		{
			value = room.max_belt .. " " .. TB_MENU_LOCALIZED.WORDQI .. "\n" .. maxBeltInfo.name .. " " .. TB_MENU_LOCALIZED.WORDBELT,
			icon = maxBeltInfo.icon,
			width = 0.075,								-- 0.90
			orientation = CENTERMID
		},
		{
			value = room.num_players .. " / " .. room.max_clients,
			width = 0.1,								-- 1.00
			orientation = CENTERMID
		}
	}
	local shiftWidth = math.min(10, roomButton.size.w / 50)
	local shiftX = shiftWidth
	local availableAreaX = roomButton.size.w - shiftWidth * #datasToDisplay
	for _, v in pairs(datasToDisplay) do
		if (v.shadowValue) then
			local infoShadow = roomButton:addChild({
				pos = { v.textIcon and shiftX + (roomButton.size.h - 6) * 0.75 or shiftX, 3 },
				size = { availableAreaX * v.width, roomButton.size.h - 6 },
				uiColor = { 0, 0, 0, 0 }
			})
			infoShadow:addAdaptedText(true, v.shadowValue, nil, nil, 4, v.orientation or LEFTMID, 0.65, nil, nil, 2)
		end
		local infoBit = roomButton:addChild({
			pos = { shiftX, 3 },
			size = { availableAreaX * v.width, roomButton.size.h - 6 }
		})
		if (v.icon) then
			local iconHolder = infoBit:addChild({
				shift = { (infoBit.size.w - infoBit.size.h) / 2, 0 },
				bgImage = v.icon,
				imageColor = matchesBelt and { 1, 1, 1, 1 } or { 1, 1, 1, 0.6 }
			})
			local popup = TBMenu:displayPopup(iconHolder, v.value .. "", true)
			popup:moveTo(-iconHolder.size.w - (popup.size.w - iconHolder.size.w) / 2, iconHolder.size.h)
		else
			local targetTextElement = infoBit
			if (v.textIcon) then
				local iconHolder = infoBit:addChild({
					pos = { -infoBit.size.w - infoBit.size.h / 4, 0 },
					size = { infoBit.size.h, infoBit.size.h },
					bgImage = v.textIcon,
					imageColor = matchesBelt and { 1, 1, 1, 1 } or { 1, 1, 1, 0.6 }
				})
				local popup = TBMenu:displayPopup(iconHolder, v.textIconHint, true)
				popup:moveTo(iconHolder.size.w + 5)
				targetTextElement = infoBit:addChild({
					pos = { iconHolder.size.h * 0.75, 0 },
					size = { infoBit.size.w - iconHolder.size.w - 5, infoBit.size.h }
				})
			end
			targetTextElement:addAdaptedText(true, v.value, nil, nil, 4, v.orientation or LEFTMID, 0.65)
		end
		shiftX = shiftX + infoBit.size.w + shiftWidth
	end

	return roomButton
end

---Returns the list of rooms that match current search filters
---@return RoomListInfoExtended[]
function RoomList:getFilteredList()
	---@type RoomListInfoExtended[]
	local roomsList = {}
	for _, v in pairs(RoomListInternal.Cache) do
		local hasMatch = true
		if (self.Filters.MatchesBelt ~= FILTER_ANY and self.Filters.MatchesBelt ~= (v.min_belt <= TB_MENU_PLAYER_INFO.data.qi and (v.max_belt == 0 or v.max_belt >= TB_MENU_PLAYER_INFO.data.qi))) then
			hasMatch = false
		elseif (self.Filters.HasEntryFee ~= FILTER_ANY and self.Filters.HasEntryFee ~= (v.entry_fee ~= 0)) then
			hasMatch = false
		elseif (self.Filters.DuelMode ~= FILTER_ANY and self.Filters.DuelMode ~= v.is_duel_mode) then
			hasMatch = false
		elseif (self.Filters.PasswordProtected ~= FILTER_ANY and self.Filters.PasswordProtected ~= v.is_password_protected) then
			hasMatch = false
		elseif (self.Filters.IsTournament ~= FILTER_ANY and self.Filters.IsTournament ~= v.is_tournament) then
			hasMatch = false
		elseif (self.Filters.IsOfficial ~= FILTER_ANY and self.Filters.IsOfficial ~= v.is_official) then
			hasMatch = false
		elseif (self.Filters.IsRanked ~= FILTER_ANY and self.Filters.IsRanked ~= v.is_ranked) then
			hasMatch = false
		end

		if (hasMatch) then
			table.insert(roomsList, v)
		end
	end

	return table.qsort(roomsList, self.Filters.SortBy, self.Filters.SortOrder, true)
end

---Displays featured buttons for the rooms list
---@param roomsList RoomListInfoExtended[]
---@param viewElement UIElement
---@param listElements UIElement[]
---@param elementHeight integer
function RoomList:showRoomListFeatured(roomsList, viewElement, listElements, elementHeight)
	local featuredRooms = {}
	local hasEventRoom, hasAutoTourney, hasFavourite, hasQuickLobby, hasFriendRoom, hasAiFightRoom, hasPublicRoom = false, false, false, false, false, false, false
	local roomListShuffled = table.shuffle(roomsList)
	for _, v in pairs(roomListShuffled) do
		local nameLower = utf8.lower(v.name)
		if (v.num_players > 0) then ---There's no need to show empty rooms in featured list
			if (not hasEventRoom and
				(nameLower == "etourney" or
				nameLower == "ehotseat" or
				nameLower == "eduel" or
				nameLower == "ebets" or
				nameLower == "elounge")) then
				table.insert(featuredRooms, v)
				hasEventRoom = true
			elseif (not hasAutoTourney and v.is_tournament and v.is_official) then
				table.insert(featuredRooms, v)
				hasAutoTourney = true
			elseif (not hasQuickLobby and utf8.find(v.name, "^qa%d") and v.num_players < v.max_clients) then
				table.insert(featuredRooms, v)
				hasQuickLobby = true
			elseif (not hasPublicRoom and utf8.find(v.name, "^public%d") and v.num_players < v.max_clients / 2) then
				table.insert(featuredRooms, v)
				hasPublicRoom = true
			elseif (not hasAiFightRoom and utf8.find(v.name, "^aifight%d")) then
				table.insert(featuredRooms, v)
				hasAiFightRoom = true
			else
				if (not hasFriendRoom) then
					for _, player in pairs(v.players) do
						if (Friends:isFriend(player)) then
							table.insert(featuredRooms, v)
							hasFriendRoom = true
							break
						end
					end
				end
			end
		end
	end

	if (#featuredRooms == 0) then
		return
	end

	local buttonWidth = elementHeight * 6
	local maxButtons = math.floor(viewElement.size.w / (buttonWidth + 10))

	---Buttons take multiple list lines
	---This is done so we don't need to make huge list borders on top and bottom
	for _ = 1, 2 do
		local lineElement = viewElement:addChild({
			pos = { 10, #listElements * elementHeight },
			size = { viewElement.size.w - 10, elementHeight }
		})
		table.insert(listElements, lineElement)
	end
	for i = 1, math.min(maxButtons, #featuredRooms) do
		local room = featuredRooms[i]
		local imageModName = utf8.gsub(room.gamerules.mod, "(%a+).*", "%1")
		local topRowLine = listElements[1]:addChild({
			pos = { (i - 1) * (buttonWidth + 10), 0 },
			size = { buttonWidth, elementHeight },
			interactive = true,
			bgImage = { "../textures/menu/multiplayer/" .. imageModName .. "-featured.tga", "../textures/menu/multiplayer/other-featured.tga" },
			imageAtlas = true,
			atlas = { x = 0, y = 0, w = 900, h = 150 },
			imageColor = { 1, 1, 1, 0.8 },
			imageHoverColor = { 1, 1, 1, 1 },
			imagePressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			disableUnload = true
		})
		TBMenu:addOuterRounding(topRowLine, TB_MENU_DEFAULT_BG_COLOR, { 10, 10, 0, 0 })
		local midRowLine = listElements[2]:addChild({
			pos = { (i - 1) * (buttonWidth + 10), 0 },
			size = { buttonWidth, elementHeight },
			interactive = true,
			bgImage = { "../textures/menu/multiplayer/" .. imageModName .. "-featured.tga", "../textures/menu/multiplayer/other-featured.tga" },
			imageAtlas = true,
			atlas = { x = 0, y = 150, w = 900, h = 150 },
			imageColor = topRowLine.imageColor,
			imageHoverColor = topRowLine.imageHoverColor,
			imagePressedColor = topRowLine.imagePressedColor,
			disableUnload = true
		})
		TBMenu:addOuterRounding(midRowLine, TB_MENU_DEFAULT_BG_COLOR, { 0, 0, 10, 10 })

		topRowLine:addCustomDisplay(function()
			if (midRowLine.hoverState ~= topRowLine.hoverState and midRowLine:isDisplayed()) then
				if (topRowLine.hoverState > midRowLine.hoverState) then
					midRowLine.hoverState = topRowLine.hoverState
					midRowLine.hoverClock = topRowLine.hoverClock
				else
					topRowLine.hoverState = midRowLine.hoverState
					topRowLine.hoverClock = midRowLine.hoverClock
				end
			end
		end, true)

		local joinRoom = function()
			if (topRowLine.lastClick ~= nil and topRowLine.lastClick + 0.5 > UIElement.clock) then
				RoomListInternal.Connect(room)
				return
			end
			topRowLine.lastClick = UIElement.clock

			if (self.SelectedButton ~= nil and not self.SelectedButton.destroyed) then
				---@diagnostic disable-next-line: undefined-field
				self.SelectedButton.bgColor = table.clone(self.SelectedButton.defaultBgColor)
			end
			self.SelectedButton = nil
			self:showRoomInfo(room)
		end
		topRowLine:addMouseUpHandler(joinRoom)
		midRowLine:addMouseUpHandler(joinRoom)

		local roomNameHolder = midRowLine:addChild({
			pos = { 10, 0 },
			size = { midRowLine.size.w - 20, midRowLine.size.h / 2 },
			uiColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			uiShadowColor = UICOLORWHITE
		})
		roomNameHolder:addAdaptedText(true, room.name .. "  (" .. room.num_players .. "/" .. room.max_clients .. ")", nil, nil, FONTS.MEDIUM, LEFTMID, 0.9, nil, nil, 2)
		midRowLine:addChild({
			pos = { 10, roomNameHolder.size.h },
			size = { roomNameHolder.size.w, midRowLine.size.h - roomNameHolder.size.h },
			uiColor = roomNameHolder.uiColor,
			uiShadowColor = roomNameHolder.uiShadowColor
		}):addAdaptedText(true, room.gamerules.mod, nil, nil, 1, LEFT, 1, nil, nil, 1)
	end
end

---Displays the main list with room information
---@param viewElement UIElement
function RoomList:showRoomList(viewElement)
	viewElement:kill(true)
	TBMenu:addBottomBloodSmudge(viewElement, 1)

	self.SelectedButton = nil
	local elementHeight = math.min(70, math.max(45, WIN_H / 20))
	local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(viewElement, elementHeight, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

	self:showRoomListLegend(topBar)

	local listElements = {}
	local unofficialCaptionDisplayed = false
	local roomsList = self:getFilteredList()

	if (#roomsList == 0) then
		listingHolder:addChild({ shift = { 20, 30 }}):addAdaptedText(true, TB_MENU_LOCALIZED.ROOMLISTNOMATCHINGROOMSFOUND)
		return
	end

	if (self.Filters.IsDefault) then
		self:showRoomListFeatured(roomsList, listingHolder, listElements, elementHeight)
	end
	for i, room in pairs(roomsList) do
		if (self.Filters.IsDefault) then
			if (i == 1 and room.is_official == true) then
				local listElement = listingHolder:addChild({
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, listElement)
				local infoMarkScale = 24
				local infoPopupHolder = listElement:addChild({
					pos = { 10, listElement.size.h - infoMarkScale - 3 },
					size = { infoMarkScale, infoMarkScale },
					shapeType = ROUNDED,
					rounded = listElement.size.h,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					interactive = true
				})
				local infoPopup = TBMenu:displayHelpPopup(infoPopupHolder, TB_MENU_LOCALIZED.ROOMLISTOFFICIALROOMSINFO, true)
				infoPopup:moveTo(infoPopupHolder.size.w + 5)
				listElement:addChild({
					pos = { infoPopupHolder.shift.x * 2 + infoPopupHolder.size.w, 3 },
					size = { listElement.size.w - infoPopupHolder.size.w - infoPopupHolder.shift.x * 3, listElement.size.h - 6 }
				}):addAdaptedText(true, TB_MENU_LOCALIZED.ROOMLISTOFFICIALROOMS, nil, nil, nil, LEFTBOT)
				listElement:hide(true)
			elseif (room.is_official == false and not unofficialCaptionDisplayed) then
				unofficialCaptionDisplayed = true
				local listElement = listingHolder:addChild({
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, listElement)
				listElement:addChild({ shift = { 10, 3 }}):addAdaptedText(true, TB_MENU_LOCALIZED.ROOMLISTPRIVATEROOMS, nil, nil, nil, LEFTBOT)
				listElement:hide(true)
			end
		end

		local listElement = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, listElement)
		local button = self:showRoomListButton(listElement, room)
		if (i == 1) then
			button.btnUp()
		end
		listElement:hide(true)
	end

	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar
	scrollBar:makeScrollBar(listingHolder, listElements, toReload)
end

---Displays mod selection for the new room
---@param viewElement UIElement
---@return string[]
function RoomList:displayCreateRoomMods(viewElement, mainListBotBar)
	local elementHeight = 36
	local toReload, topBar, botBar, listingView, listingHolder, scrollBarBG = TBMenu:prepareScrollableList(viewElement, elementHeight + 40, 0, 20, TB_MENU_DEFAULT_BG_COLOR)
	table.insert(toReload.child, mainListBotBar)

	local modInputHolder = topBar:addChild({
		pos = { 5, 3 },
		size = { topBar.size.w - 20, 34 },
		shapeType = viewElement.shapeType,
		rounded = viewElement.rounded
	})
	local modInputField = TBMenu:spawnTextField2(modInputHolder, nil, nil, "Room mod", {
		textAlign = LEFTMID, darkerMode = true, fontId = 4, textScale = 0.7, keepFocusOnHide = true, customRegex = "[%a%d%.-_]+"
	})
	local lastText = modInputField.textfieldstr[1]
	local onSelectFunc = function(modname)
		modInputField:clearTextfield()
		modInputField.textInput(modname)
	end
	modInputField:addKeyboardHandlers(nil, function()
			if (lastText ~= modInputField.textfieldstr[1]) then
				Mods.ListShift[1] = 0
				Mods.spawnMainList(listingHolder, toReload, topBar, elementHeight, Mods.CurrentFolder, modInputField, onSelectFunc, true)
				lastText = modInputField.textfieldstr[1]
			end
		end)
	Mods.CurrentFolder = Mods.getModFiles()
	Mods.spawnMainList(listingHolder, toReload, topBar, elementHeight, Mods.CurrentFolder, modInputField, onSelectFunc, true)

	return modInputField.textfieldstr
end

function RoomList:createRoom()
	local backdropOverlay = TBMenu:spawnWindowOverlay(nil, true)
	local roomCreateSize = { math.min(WIN_W - TBMenu.NavigationBar.shift.x * 2, 1000), math.min(WIN_H - TBMenu.NavigationBar.shift.y * 2, 500) }
	local createRoomBackground = backdropOverlay:addChild({
		shift = { (backdropOverlay.size.w - roomCreateSize[1]) / 2, (backdropOverlay.size.h - roomCreateSize[2]) / 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	local elementHeight = 40
	local toReload, topBar, botBar, listingView, listingHolder, scrollBarBG = TBMenu:prepareScrollableList(createRoomBackground, elementHeight + 20, elementHeight + 20, 20, TB_MENU_DEFAULT_BG_COLOR)

	topBar.shapeType = ROUNDED
	topBar:setRounded({ 4, 0 })
	botBar.shapeType = ROUNDED
	botBar:setRounded({ 0, 4 })
	listingView.size.w = createRoomBackground.size.w / 3 * 2
	listingHolder.size.w = listingView.size.w - scrollBarBG.size.w
	local closeButton = topBar:addChild({
		pos = { -10 - elementHeight, 10 },
		size = { elementHeight, elementHeight },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	closeButton:addChild({
		shift = { 10, 10 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})
	closeButton:addMouseUpHandler(function() backdropOverlay:kill() end)
	local createRoomTitle = topBar:addChild({
		pos = { 60, 10 },
		size = { createRoomBackground.size.w - 120, elementHeight }
	})
	createRoomTitle:addAdaptedText(true, TB_MENU_LOCALIZED.ROOMLISTCREATEROOMTITLE, nil, nil, FONTS.BIG)

	local TYPE_INPUT = 0
	local TYPE_DROPDOWN = 1
	local TYPE_CHECKBOX = 2

	---@class CreateRoomOption
	---@field title string
	---@field default string
	---@field type integer
	---@field action function
	---@field options DropdownElement[]|TextFieldInputSettings
	---@field targetValue string[]|number[]
	---@field required boolean
	---@field errorMessage string
	---@field customRegex string
	---@field minValue integer
	---@field maxValue integer

	---@type CreateRoomOption[]
	local createRoomFields = {
		{
			title = TB_MENU_LOCALIZED.ROOMLISTCREATEROOMNAME,
			type = TYPE_INPUT,
			action = function(val) runCmd("join " .. val, true) end,
			required = true,
			errorMessage = TB_MENU_LOCALIZED.ROOMLISTCREATEROOMNAMEEMPTYERROR,
			options = { customRegex = "[%a%d]+" }
		},
		{
			title = TB_MENU_LOCALIZED.ROOMLISTCREATEROOMDESC,
			default = TB_MENU_PLAYER_INFO.username .. "'s server",
			type = TYPE_INPUT,
			action = function(val) runCmd("desc " .. val, true) end,
			options = { customRegex = "[%C%Z]+" }
		},
		{
			title = TB_MENU_LOCALIZED.ROOMLISTCREATEROOMPASS,
			default = TB_MENU_LOCALIZED.ROOMLISTCREATEROOMPASSINFO,
			type = TYPE_INPUT,
			action = function(val) runCmd("passwd " .. val, true) end
		},
		{
			title = TB_MENU_LOCALIZED.ROOMLISTCREATEROOMMINBELT,
			type = TYPE_DROPDOWN,
			options = {
				{
					text = TB_MENU_LOCALIZED.ROOMLISTCREATENORESTRICTIONS,
					value = 0
				},
				{
					text = "Yellow Belt",
					value = 20
				},
				{
					text = "Orange Belt",
					value = 50
				},
				{
					text = "Green Belt",
					value = 100
				},
				{
					text = "Blue Belt",
					value = 200
				},
				{
					text = "Brown Belt",
					value = 500
				},
				{
					text = "Black Belt",
					value = 1000
				},
				{
					text = "Master Belt",
					value = 15000
				},
				{
					text = "Custom Belt",
					value = 20000
				},
				{
					text = "God Belt",
					value = 50000
				},
				{
					text = "One Belt",
					value = 100000
				}
			},
			action = function(val) runCmd("minbelt " .. val, true) end
		},
		{
			title = TB_MENU_LOCALIZED.ROOMLISTCREATEROOMMAXBELT,
			type = TYPE_DROPDOWN,
			options = {
				{
					text = TB_MENU_LOCALIZED.ROOMLISTCREATENORESTRICTIONS,
					value = 0
				},
				{
					text = "White Belt",
					value = 19
				},
				{
					text = "Yellow Belt",
					value = 49
				},
				{
					text = "Orange Belt",
					value = 99
				},
				{
					text = "Green Belt",
					value = 199
				},
				{
					text = "Blue Belt",
					value = 499
				},
				{
					text = "Brown Belt",
					value = 999
				},
				{
					text = "Black Belt",
					value = 1999
				},
				{
					text = "Master Belt",
					value = 19999
				},
				{
					text = "Custom Belt",
					value = 49999
				},
				{
					text = "God Belt",
					value = 99999
				}
			},
			action = function(val) runCmd("maxbelt " .. val, true) end
		},
		{
			title = TB_MENU_LOCALIZED.ROOMLISTCREATEROOMMAXCLIENTS,
			type = TYPE_INPUT,
			options = { isNumeric = true, allowNegative = false, allowDecimal = false, textAlign = CENTERMID },
			minValue = 2,
			maxValue = 32,
			default = "12",
			action = function(val) runCmd("maxclients " .. val, true) end
		}
	}

	local updateCreateRoomButton

	local listElements = {}
	for _, v in pairs(createRoomFields) do
		local fieldHolder = listingHolder:addChild({
			pos = { 20, #listElements * elementHeight },
			size = { listingHolder.size.w - 40, elementHeight },
			shapeType = ROUNDED,
			rounded = 3
		})
		table.insert(listElements, fieldHolder)
		local fieldLegend = fieldHolder:addChild({
			pos = { 0, 4 },
			size = { fieldHolder.size.w / 3, fieldHolder.size.h - 8 }
		})
		fieldLegend:addAdaptedText(true, v.title, nil, nil, nil, LEFTMID)

		v.targetValue = { "" }
		if (v.type == TYPE_INPUT) then
			---@type TextFieldInputSettings
			local options = {
				fontId = 4,
				darkerMode = true,
				textAlign = LEFTMID,
				textScale = 0.7
			}
			if (v.options) then
				for i, v in pairs(v.options) do
					options[i] = v
				end
			end
			local hasButtons = options.isNumeric and not options.allowDecimal and v.minValue and v.maxValue
			local textField = TBMenu:spawnTextField2(fieldHolder, {
				x = fieldLegend.size.w + (hasButtons and (fieldHolder.size.h - 6) * 2 or 0),
				w = fieldHolder.size.w - fieldLegend.size.w - (hasButtons and (fieldHolder.size.h - 6) * 4 or 0),
				y = 3,
				h = fieldHolder.size.h - 6
			}, v.targetValue, v.default, options)
			if (v.required) then
				textField:addInputCallback(function()
						updateCreateRoomButton()
					end)
			end
			if (hasButtons) then
				local prevButton = fieldHolder:addChild({
					pos = { fieldLegend.size.w, 3 },
					size = { (fieldHolder.size.h - 6) * 2 - 6, fieldHolder.size.h - 6 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				}, true)
				prevButton:addAdaptedText("<", nil, nil, FONTS.BIG)
				prevButton:addMouseUpHandler(function()
						local inputValue = textField.textfieldstr[1] == "" and tonumber(v.default) or tonumber(textField.textfieldstr[1])
						if (inputValue and inputValue > v.minValue) then
							textField:clearTextfield()
							textField.textInput(tostring(inputValue - 1))
						end
					end)

				local nextButton = fieldHolder:addChild({
					pos = { -prevButton.size.w, prevButton.shift.y },
					size = { prevButton.size.w, prevButton.size.h },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				}, true)
				nextButton:addAdaptedText(">", nil, nil, FONTS.BIG)
				nextButton:addMouseUpHandler(function()
						local inputValue = textField.textfieldstr[1] == "" and tonumber(v.default) or tonumber(textField.textfieldstr[1])
						if (inputValue and inputValue < v.maxValue) then
							textField:clearTextfield()
							textField.textInput(tostring(inputValue + 1))
						end
					end)
			end
		elseif (v.type == TYPE_DROPDOWN) then
			local fieldDropdownHolder = fieldHolder:addChild({
				pos = { fieldLegend.size.w, 3 },
				size = { fieldHolder.size.w - fieldLegend.size.w, fieldHolder.size.h - 6 }
			}, true)
			for _, option in pairs (v.options) do
				---@diagnostic disable-next-line: undefined-field
				option.action = function() v.targetValue[1] = option.value end
			end
			local fieldDropdownParent = fieldDropdownHolder:addChild({
				shift = { fieldDropdownHolder.size.h * 2, 0 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			}, true)
			local dropdown = TBMenu:spawnDropdown(fieldDropdownParent, v.options, fieldDropdownHolder.size.h, nil, nil, {
				fontid = 4, scale = 0.7, alignment = LEFTMID, uppercase = false
			}, {
				fontid = 4, scale = 0.7, alignment = LEFTMID, uppercase = false
			})
			local prevButton = fieldDropdownHolder:addChild({
				pos = { 0, 0 },
				size = { fieldDropdownHolder.size.h * 2 - 6, fieldDropdownHolder.size.h },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			}, true)
			prevButton:addAdaptedText("<", nil, nil, FONTS.BIG)
			prevButton:addMouseUpHandler(function()
					dropdown.selectItem(dropdown.displayOptions[math.max(1, dropdown.selectedId() - 1)])
				end)

			local nextButton = fieldDropdownHolder:addChild({
				pos = { -fieldDropdownHolder.size.h * 2 + 6, 0 },
				size = { fieldDropdownHolder.size.h * 2 - 6, fieldDropdownHolder.size.h },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			}, true)
			nextButton:addAdaptedText(">", nil, nil, FONTS.BIG)
			nextButton:addMouseUpHandler(function()
					dropdown.selectItem(dropdown.displayOptions[math.min(#dropdown.displayOptions, dropdown.selectedId() + 1)])
				end)
		end
	end

	if (#listElements * elementHeight > listingHolder.size.h) then
		for _, v in pairs(listElements) do
			v:hide(true)
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = scrollBar
		scrollBar:makeScrollBar(listingHolder, listElements, toReload, nil, nil, true)
	else
		scrollBarBG:hide()
		listingHolder:moveTo((listingView.size.w - listingHolder.size.w) / 2)
	end

	local createRoomModHolder = createRoomBackground:addChild({
		pos = { listingView.size.w, topBar.size.h },
		size = { createRoomBackground.size.w - listingView.size.w, createRoomBackground.size.h - topBar.size.h * 2 }
	}, true)
	local targetMod = self:displayCreateRoomMods(createRoomModHolder, botBar)

	local createRoomButtonSize = math.min(350, botBar.size.w / 2)
	local createRoomButtonBackdrop = botBar:addChild({
		shift = { (botBar.size.w - createRoomButtonSize) / 2, 10 },
		interactive = true
	})
	local createRoomButton = createRoomButtonBackdrop:addChild({
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS,
		shapeType = createRoomBackground.shapeType,
		rounded = createRoomBackground.rounded
	})
	createRoomButton:addAdaptedText("Create room")
	createRoomButton:addMouseUpHandler(function()
			createRoomBackground:kill(true)
			TBMenu:displayLoadingMark(createRoomBackground, TB_MENU_LOCALIZED.ROOMLISTCREATEPLEASEWAIT)
			createRoomFields[1].action(createRoomFields[1].targetValue[1])
			add_hook("new_mp_game", "roomListMultiplayerCreateJoinRoom", function()
				remove_hooks("roomListMultiplayerCreateJoinRoom")
				if (targetMod[1] ~= "") then
					runCmd("loadmod " .. targetMod[1], true)
					runCmd("reset", true)
				end
				for i, v in pairs(createRoomFields) do
					if (i > 1 and v.targetValue[1] ~= "") then
						v.action(v.targetValue[1])
					end
				end
				backdropOverlay:kill()
				close_menu()
			end)
		end)
	createRoomButton:deactivate(true)

	local createRoomTooltip
	createRoomTooltip = TBMenu:displayPopup(createRoomButtonBackdrop, createRoomFields[1].errorMessage)
	createRoomTooltip:moveTo(-createRoomButtonBackdrop.size.w + (createRoomButtonBackdrop.size.w - createRoomTooltip.size.w) / 2, -createRoomButtonBackdrop.size.h - createRoomTooltip.size.h - 5)
	updateCreateRoomButton = function()
		for _, v in pairs(createRoomFields) do
			if (v.required and v.targetValue[1] == "") then
				createRoomButton:deactivate(true)

				if (createRoomTooltip ~= nil) then
					createRoomTooltip:kill()
					createRoomTooltip = nil
				end
				createRoomTooltip = TBMenu:displayPopup(createRoomButtonBackdrop, v.errorMessage)
				createRoomTooltip:moveTo(-createRoomButtonBackdrop.size.w + (createRoomButtonBackdrop.size.w - createRoomTooltip.size.w) / 2, -createRoomButtonBackdrop.size.h - createRoomTooltip.size.h - 5)
				return
			end
		end
		createRoomButton:activate(true)
		if (createRoomTooltip ~= nil) then
			createRoomTooltip:kill()
			createRoomTooltip = nil
		end
	end
end

---Prepares the right side of Room List menu with room info and misc buttons
---@param viewElement UIElement
function RoomList:prepareInfoView(viewElement)
	self.RoomInfoView = viewElement:addChild({
		pos = { 10, 0 },
		size = { viewElement.size.w - 20, viewElement.size.h / 2 }
	})

	local buttonHeight = math.min(self.RoomInfoView.size.h / 6, 50)
	local newRoomButton = viewElement:addChild({
		pos = { 10, -buttonHeight - 10 },
		size = { viewElement.size.w - 20, buttonHeight },
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	newRoomButton:addChild({ shift = { 10, 5 }}):addAdaptedText(true, TB_MENU_LOCALIZED.ROOMLISTCREATEROOM)
	newRoomButton:addMouseUpHandler(function() self:createRoom() end)
end

---Sets the default filters for the room list
function RoomList:resetFilters()
	if (self.Filters.SortBy == nil) then
		self.Filters.MatchesBelt = FILTER_ON
		self.Filters.PasswordProtected = FILTER_ANY
		self.Filters.IsTournament = FILTER_ANY
		self.Filters.DuelMode = FILTER_ANY
		self.Filters.HasEntryFee = FILTER_ANY
		self.Filters.IsOfficial = FILTER_ANY
		self.Filters.IsRanked = FILTER_ANY
	end

	self.Filters.SortBy = { "is_official", "id" }
	self.Filters.SortOrder = { SORT_DESCENDING, SORT_ASCENDING }
	self.Filters.IsDefault = true
end

function RoomList:showFilters()
	local filterOptions = {
		{
			text = TB_MENU_LOCALIZED.ROOMLISTFILTERBELTMATCH,
			targetField = "MatchesBelt"
		},
		{
			text = TB_MENU_LOCALIZED.ROOMLISTFILTEROFFICIALONLY,
			targetField = "IsOfficial"
		},
		{
			text = TB_MENU_LOCALIZED.ROOMLISTFILTERPASSWORDPROTECTED,
			targetField = "PasswordProtected"
		},
		{
			text = TB_MENU_LOCALIZED.ROOMLISTTOURNAMENT,
			targetField = "IsTournament"
		},
		{
			text = TB_MENU_LOCALIZED.ROOMLISTRANKED,
			targetField = "IsRanked"
		},
		{
			text = TB_MENU_LOCALIZED.ROOMLISTFILTERDUELROOM,
			targetField = "DuelMode"
		},
		{
			text = TB_MENU_LOCALIZED.ROOMLISTFILTERHASENTRYFEE,
			targetField = "HasEntryFee"
		}
	}
	local defaultListHeight = TBMenu.CurrentSection.size.h + 15 - 4
	local buttonHeight = math.min((defaultListHeight - 20) / #filterOptions, 45)
	local targetListHeight = buttonHeight * #filterOptions + 20 + 4

	local overlayBackdrop = TBMenu:spawnWindowOverlay(nil, true)
	local filtersHolderBackground = overlayBackdrop:addChild({
		pos = (SCREEN_RATIO > 2) and { TBMenu.NavigationBar.shift.x + TBMenu.NavigationBar.size.w + 5, TBMenu.NavigationBar.shift.y + TBMenu.CurrentSection.size.h + 15 - targetListHeight } or { TBMenu.NavigationBar.shift.x + TBMenu.NavigationBar.size.w - 500, TBMenu.NavigationBar.shift.y + TBMenu.NavigationBar.size.h + 5 },
		size = { 500, targetListHeight },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		shapeType = ROUNDED,
		rounded = 4,
		interactive = true
	})
	local filtersHolder = filtersHolderBackground:addChild({
		shift = { 2, 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	}, true)

	local reloadList = function()
		overlayBackdrop:kill()
		self:showRoomList(self.MainListHolder)
		self:showFilters()
	end

	for i, v in pairs(filterOptions) do
		local filterElement = filtersHolder:addChild({
			pos = { 10, 10 + (i - 1) * buttonHeight },
			size = { filtersHolder.size.w - 20, buttonHeight }
		})
		local filterLegend = filterElement:addChild({
			pos = { 0, 3 },
			size = { filterElement.size.w / 3 * 2 - 10, filterElement.size.h - 6 }
		})
		filterLegend:addAdaptedText(true, v.text, nil, nil, nil, LEFTMID)
		local filterDropdownHolder = filterElement:addChild({
			pos = { filterLegend.size.w + 10, 3 },
			size = { filterElement.size.w - filterLegend.size.w - 10, filterElement.size.h - 6 },
			shapeType = ROUNDED,
			rounded = 3,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})

		---@type DropdownElement[]
		local dropdownOptions = {
			{
				text = TB_MENU_LOCALIZED.SETTINGSENABLED,
				action = function()
					self.Filters[v.targetField] = FILTER_ON
					reloadList()
				end
			},
			{
				text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
				action = function()
					self.Filters[v.targetField] = FILTER_OFF
					reloadList()
				end
			},
			{
				text = TB_MENU_LOCALIZED.ROOMLISTFILTERANY,
				action = function()
					self.Filters[v.targetField] = FILTER_ANY
					reloadList()
				end
			}
		}
		local selectedId = self.Filters[v.targetField] == nil and 3 or (self.Filters[v.targetField] == true and 1 or 2)
		local filterDropdown = TBMenu:spawnDropdown(filterDropdownHolder, dropdownOptions, filterDropdownHolder.size.h, nil, selectedId, { fontid = FONTS.MEDIUM }, { fontid = 4, scale = 0.65 })
	end
end

---Refreshes the list if it's gotten stale
---@return boolean
function RoomList.RefreshIfNeeded()
	if (RoomListInternal.UpdateTimestamp + RoomList.RefreshPeriod < UIElement.clock) then
		RoomListInternal.RefreshData()
		return true
	end
	return false
end

---Returns a copy of room list cache
---@return RoomListInfoExtended[]
function RoomList.GetRooms()
	return table.clone(RoomListInternal.Cache)
end

---@class RoomListPlayer
---@field username string
---@field room string

---Returns list of all players currently online
---@return RoomListPlayer[]
function RoomList.GetPlayers()
	---@type RoomListPlayer[]
	local playersList = {}
	for _, room in pairs(RoomListInternal.Cache) do
		for _, player in pairs(room.players) do
			table.insert(playersList, { username = player, room = room.name })
		end
	end
	return playersList
end

---Displays Room List menu
function RoomList:showMain()
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 2
	TBMenu:clearNavSection()
	TBMenu:showNavigationBar(RoomListInternal.GetNavigationButtons(), true)
	self:resetFilters()

	---Data is stale, queue an update
	if (RoomListInternal.UpdateTimestamp + self.RefreshPeriod < UIElement.clock) then
		RoomListInternal.RefreshData()
		local updatingView = TBMenu.CurrentSection:addChild({
			shift = { 5, 0 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(updatingView)
		TBMenu:displayLoadingMark(updatingView, TB_MENU_LOCALIZED.ROOMLISTUPDATING)
		return
	end

	---We got no data after update, display error message
	if (#RoomListInternal.Cache == 0) then
		local errorView = TBMenu.CurrentSection:addChild({
			shift = { 5, 0 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(errorView)

		local errorMessage = errorView:addChild({
			pos = { 20, 10 },
			size = { errorView.size.w - 40, errorView.size.h / 2 - 20 }
		})
		if (RoomListInternal.UpdateError ~= nil) then
			errorMessage:addAdaptedText(true, TB_MENU_LOCALIZED.ROOMLISTUPDATEFAIL .. "\n" .. RoomListInternal.UpdateError, nil, nil, nil, CENTERBOT)
		else
			errorMessage:addAdaptedText(true, TB_MENU_LOCALIZED.ROOMLISTEMPTY, nil, nil, nil, CENTERBOT)
		end

		local buttonWidth = math.min(errorView.size.w / 3, 250)
		local refreshButton = errorView:addChild({
			pos = { (errorView.size.w - buttonWidth) / 2, errorMessage.shift.y + 20 },
			size = { buttonWidth, buttonWidth / 5 },
			interactive = true,
			shapeType = ROUNDED,
			rounded = 4,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		refreshButton:addChild({ shift = { 10, 5 } }):addAdaptedText(true, TB_MENU_LOCALIZED.WORDREFRESHACTION)
		refreshButton:addMouseUpHandler(RoomListInternal.RefreshData)
		return
	end

	self.MainListHolder = TBMenu.CurrentSection:addChild({
		pos = { 5, 0 },
		size = { math.max(TBMenu.CurrentSection.size.w - 300, TBMenu.CurrentSection.size.w * 0.75 - 15), TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local roomInfoView = TBMenu.CurrentSection:addChild({
		pos = { self.MainListHolder.shift.x + self.MainListHolder.size.w + 10, 0 },
		size = { TBMenu.CurrentSection.size.w - self.MainListHolder.size.w - self.MainListHolder.shift.x * 2, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:addBottomBloodSmudge(roomInfoView, 2)
	self:prepareInfoView(roomInfoView)
	self:showRoomList(self.MainListHolder)
end

---Keep this hook running forever so we can update room cache from other sources and not just RoomListInternal.RefreshData() call
add_hook("roomlist_update", "roomListCacheUpdater", function(error)
	RoomListInternal.ResetCache()
	if (utf8.len(error) ~= 0) then
		RoomListInternal.UpdateError = error
		return
	end
	RoomListInternal.CacheRooms()
end)

TB_MENU_DEBUG = true
TBMenu:getTranslation(get_language())
TB_MENU_DEBUG = false
