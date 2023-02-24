require('toriui.uielement')
require('system.menu_manager')

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
				roomInfo.desc_clean = utf8.gsub(roomInfo.desc, "%^%d%d", "")
				roomInfo.desc_clean = utf8.gsub(roomInfo.desc_clean, "%%%d%d%d", "")
				roomInfo.id = roomInfo.id + 1 ---Make ids match Lua style
				table.insert(RoomListInternal.Cache, roomInfo)
			end
		end
	end
	RoomList:showMain()
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
	local elementHeight = 20
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
			pos = { shiftX, 0 },
			size = { availableAreaX * v.width, legendHolder.size.h },
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
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	roomButton:addMouseUpHandler(function()
			if (roomButton.lastClick ~= nil and roomButton.lastClick + 0.5 > UIElement.clock) then
				RoomListInternal.Connect(room)
				return
			end
			roomButton.lastClick = UIElement.clock

			if (self.SelectedButton ~= nil and not self.SelectedButton.destroyed) then
				self.SelectedButton.bgColor = table.clone(TB_MENU_DEFAULT_DARKER_COLOR)
			end
			self.SelectedButton = roomButton
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
				bgImage = v.icon
			})
			local popup = TBMenu:displayPopup(iconHolder, v.value .. "", true)
			popup:moveTo(-iconHolder.size.w - (popup.size.w - iconHolder.size.w) / 2, iconHolder.size.h)
		else
			local targetTextElement = infoBit
			if (v.textIcon) then
				local iconHolder = infoBit:addChild({
					pos = { -infoBit.size.w - infoBit.size.h / 4, 0 },
					size = { infoBit.size.h, infoBit.size.h },
					bgImage = v.textIcon
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
		end

		if (hasMatch) then
			table.insert(roomsList, v)
		end
	end

	return table.qsort(roomsList, self.Filters.SortBy, self.Filters.SortOrder, true)
end

---Displays the main list with room information
---@param viewElement UIElement
function RoomList:showRoomList(viewElement)
	viewElement:kill(true)
	TBMenu:addBottomBloodSmudge(viewElement, 1)

	self.SelectedButton = nil
	local elementHeight = 45
	local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(viewElement, elementHeight, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

	self:showRoomListLegend(topBar)

	local listElements = {}
	local unofficialCaptionDisplayed = false
	local roomsList = self:getFilteredList()
	for i, room in pairs(roomsList) do
		if (self.Filters.IsDefault) then
			if (#listElements == 0) then
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
end

---Sets the default filters for the room list
function RoomList:resetFilters()
	self.Filters.MatchesBelt = FILTER_ON
	self.Filters.PasswordProtected = FILTER_ANY
	self.Filters.IsTournament = FILTER_ANY
	self.Filters.DuelMode = FILTER_ANY
	self.Filters.HasEntryFee = FILTER_ANY
	self.Filters.SortBy = { "is_official", "id" }
	self.Filters.SortOrder = { SORT_DESCENDING, SORT_ASCENDING }
	self.Filters.IsDefault = true
end

function RoomList:showFilters()
	local overlayBackdrop = TBMenu:spawnWindowOverlay(nil, true)
	local filtersHolderBackground = overlayBackdrop:addChild({
		pos = (SCREEN_RATIO > 2) and { TBMenu.NavigationBar.shift.x + TBMenu.NavigationBar.size.w + 5, TBMenu.NavigationBar.shift.y } or { TBMenu.NavigationBar.shift.x + TBMenu.NavigationBar.size.w - 500, TBMenu.NavigationBar.shift.y + TBMenu.NavigationBar.size.h + 5 },
		size = { 500, TBMenu.CurrentSection.size.h + 15 },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		shapeType = ROUNDED,
		rounded = 4,
		interactive = true
	})
	local filtersHolder = filtersHolderBackground:addChild({
		shift = { 2, 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	}, true)

	local filterOptions = {
		{
			text = TB_MENU_LOCALIZED.ROOMLISTTOURNAMENT,
			targetField = "IsTournament"
		}
	}

	local buttonHeight = math.min(filtersHolder.size.h / #filterOptions, 45)
	for i, v in pairs(filterOptions) do

	end
end

---Displays Room List menu
function RoomList:showMain()
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
