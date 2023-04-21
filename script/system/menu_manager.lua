-- modern main menu manager class
-- DO NOT MODIFY THIS FILE

if (TBMenu == nil) then
	---Toribash main menu class
	---
	---**Ver 5.60**
	---* All global UIElement holders are now fields of TBMenu class
	---* User bar player display will now automatically reload on customs update
	---* Increased UIElement viewport size (user bar head preview) to make sure custom obj doesn't get cut
	---* Darken head preview in user bar on `spawnWindowOverlay()` call
	---* Per-button locked message support for `showHomeButton()`
	---* Single image animated buttons for left/right bottom user bars
	---* `createImageButtons()` is now marked deprecated
	---* Use `imageColor` UIElement functionality for miscellaneous art assets to allow easily recolorable GUI
	---* Horizontal scrollable lists support
	---* Default `scrollSize` value for `prepareScrollableList()`
	---@class TBMenu
	---@field MenuMain UIElement Main menu UIElement holder
	---@field UserBar UIElement Top right user bar UIElement holder
	---@field CurrentSection UIElement Current menu section UIElement holder
	---@field NavigationBar UIElement Navigation bar UIElement holder
	---@field BottomLeftBar UIElement Bottom left bar UIElement holder
	---@field BottomRightBar UIElement Bottom right bar UIElement holder
	---@field StatusMessage TBMenuStatusMessage Status message UIElement holder
	---@field NotificationsCount UIElement Notifications count display UIElement
	---@field CurrentAnnouncementId integer Active home tab announcement ID
	TBMenu = {
		CurrentAnnouncementId = 1,
		ver = 5.60
	}
	setmetatable({}, TBMenu)
end

---Internal functions used by TBMenu
---@class TBMenuInternal
local TBMenuInternal = {
	__index = {}
}
setmetatable({}, TBMenuInternal)

---@param version string
function TBMenu.Init(version)
	TB_MENU_MAIN_ISOPEN = 1
	set_build_version(version)
	TBMenu.GetTranslation(get_language())
end

---Adjusts some internal settings for fonts to accompany for RTL languages
---@param language string
function TBMenuInternal.SetLanguageFontOptions(language)
	if (language == "hebrew" or language == "arabic") then
		FONTS.BIG = 4
		FONTS.MEDIUM = 4
		LEFT = 2
		LEFTBOT = 5
		LEFTMID = 8
	else
		FONTS.BIG = 0
		FONTS.MEDIUM = 2
		LEFT = 0
		LEFTBOT = 3
		LEFTMID = 6
	end
end

---Caches localization data to `TB_MENU_LOCALIZED` table for the provided language. \
---In case of incomplete data, uses English to make sure there are no missing localization strings.
---@param language string
function TBMenu.GetTranslation(language)
	local language = language or "english"
	local inverse = (language == "arabic" or language == "hebrew") and true
	TBMenuInternal.SetLanguageFontOptions(language)
	if (type(TB_MENU_LOCALIZED) ~= "table" or TB_MENU_LOCALIZED.language ~= language or TB_MENU_DEBUG) then
		TB_MENU_LOCALIZED = {}
		TB_MENU_LOCALIZED.language = language
	else
		return
	end

	local file = Files:open("../data/script/system/language/" .. language .. ".txt", "r")
	if (not file.data) then
		file = Files:open("../data/script/system/language/english.txt", "r")
		if (not file) then
			echo("^04Localization data not found, exiting main menu")
			if (is_steam()) then
				echo("^07If this error persists, please verify integrity of game files in your Steam Library")
			else
				echo("^07If this error persists, please reinstall Toribash to repair system files")
			end
			TBMenu.Quit()
			return
		end
	end

	for _, ln in pairs(file:readAll()) do
		if (not ln:match("^#")) then
			local data_stream = { ln:match(("([^\t]*)\t?"):rep(2)) }
			TB_MENU_LOCALIZED[data_stream[1]] = inverse and localize_rtl(data_stream[2]) or data_stream[2]
		end
	end
	file:close()

	if (language ~= "english") then
		-- Make sure there's no missing values
		local file = Files:open("../data/script/system/language/english.txt", "r")
		for _, ln in pairs(file:readAll()) do
			if (not ln:match("^#")) then
				local data_stream = { ln:match(("([^\t]*)\t?"):rep(2)) }
				if (not TB_MENU_LOCALIZED[data_stream[1]]) then
					TB_MENU_LOCALIZED[data_stream[1]] = data_stream[2]
				end
			end
		end
		file:close()
	end
end

---Exits main menu and unloads all related hooks
function TBMenu.Quit()
	remove_hooks("tbMainMenuVisual")
	remove_hooks("tbMainMenuMouse")
	remove_hooks("tbMenuConsoleIgnore")
	remove_hooks("tbMenuKeyboardHandler")

	enable_camera_movement()
	disable_blur()
	disable_menu_keyboard()
	chat_input_activate()

	TB_MENU_MAIN_ISOPEN = 0
	TBMenu.MenuMain:kill()
	TBMenu.MenuMain = nil
end

---Creates `TBMenu.CurrentSection` object to be used by main menu
function TBMenu.CreateCurrentSectionView()
	if (TBMenu.MenuMain == nil or TBMenu.MenuMain.destroyed) then return end

	local safeX = get_window_safe_size()
	if (SCREEN_RATIO > 2) then
		local offsetX = math.max(safeX, 50 * TB_MENU_GLOBAL_SCALE) + 25 * TB_MENU_GLOBAL_SCALE
		local sizeOffset = math.min(WIN_W / 8, 300)
		TBMenu.CurrentSection = TBMenu.MenuMain:addChild({
			pos = { offsetX + sizeOffset, 130 * TB_MENU_GLOBAL_SCALE },
			size = { WIN_W - offsetX - 75 * TB_MENU_GLOBAL_SCALE - sizeOffset, WIN_H - 235 * TB_MENU_GLOBAL_SCALE },
			interactive = is_mobile()
		})
	else
		local sizeOffset = math.max(safeX, 75) * TB_MENU_GLOBAL_SCALE
		TBMenu.CurrentSection = TBMenu.MenuMain:addChild({
			pos = { sizeOffset, 140 * TB_MENU_GLOBAL_SCALE + math.min(WIN_H / 16, 60) },
			size = { WIN_W - sizeOffset * 2, WIN_H - 235 * TB_MENU_GLOBAL_SCALE - math.min(WIN_H / 16, 60) },
			interactive = is_mobile()
		})
	end
end

-- Calculates image dimensions based on screen and element size
---@param width number
---@param height number
---@param ratio number
---@param shift1 number
---@param shift2 number
---@return number[]
function TBMenu:getImageDimensions(width, height, ratio, shift1, shift2)
	local elementWidth = width - 20
	if (elementWidth * ratio > height - 20) then
		elementWidth = (height - 20) / ratio
	end
	local elementHeight = elementWidth * ratio
	if (elementHeight + shift1 + shift2 <= height - 20) then
		return { elementWidth, elementHeight, 0 }
	elseif (elementHeight + shift2 <= height - 20) then
		return { elementWidth, elementHeight, shift1 }
	else
		return { elementWidth, elementHeight, shift1 + shift2 }
	end
end

---Shorthand method to create an image button.
---
---Only use this if you need to use different sprites for different button states, otherwise use a single UIElement with a white sprite and different `imageColor` / `imageHoverColor` / `imagePressedColor` values.
---@param parentElement UIElement
---@param x number
---@param y number
---@param w number
---@param h number
---@param img string
---@param imgHvr? string
---@param imgPress? string
---@param col? Color
---@param colHvr? Color
---@param colPress? Color
---@param round? number
---@return UIElement
function TBMenu:createImageButtons(parentElement, x, y, w, h, img, imgHvr, imgPress, col, colHvr, colPress, round)
	local imgHvr = imgHvr or img
	local imgPress = imgPress or img
	local col = col or nil
	local colHvr = colHvr or col
	local colPress = colPress or colHvr
	local round = round or nil
	local buttonMain = parentElement:addChild({
		pos = { x, y },
		size = { w, h },
		interactive = true,
		hoverSound = 31,
		shapeType = round and ROUNDED or SQUARE,
		rounded = round and round or 0
	})
	if (col) then
		buttonMain.bgColor = col
	end
	if (colHvr) then
		buttonMain.hoverColor = colHvr
	end
	if (colPress) then
		buttonMain.pressedColor = colPress
	end

	local buttonImage = UIElement.new({
		parent = buttonMain,
		pos = { 0, 0 },
		size = { 0, 0 },
		bgImage = img
	})
	buttonImage:addCustomDisplay(true, function() end)
	local buttonImageHover = UIElement.new({
		parent = buttonMain,
		pos = { 0, 0 },
		size = { 0, 0 },
		bgImage = imgHvr
	})
	buttonImageHover:addCustomDisplay(true, function() end)
	local buttonImagePress = UIElement.new({
		parent = buttonMain,
		pos = { 0, 0 },
		size = { 0, 0 },
		bgImage = imgPress
	})
	buttonImagePress:addCustomDisplay(true, function()
			if (buttonMain.hoverState == BTN_NONE) then
				draw_quad(buttonMain.pos.x, buttonMain.pos.y, buttonMain.size.w, buttonMain.size.h, buttonImage.bgImage)
			elseif (buttonMain.hoverState == BTN_HVR) then
				draw_quad(buttonMain.pos.x, buttonMain.pos.y, buttonMain.size.w, buttonMain.size.h, buttonImageHover.bgImage)
				set_mouse_cursor(1)
			elseif (buttonMain.hoverState == BTN_DN) then
				draw_quad(buttonMain.pos.x, buttonMain.pos.y, buttonMain.size.w, buttonMain.size.h, buttonImagePress.bgImage)
				set_mouse_cursor(1)
			end
		end)
	return buttonMain
end

---Internal TBMenu function to rotate News section displayed event
---@param viewElement UIElement
---@param eventsData NewsItemData[]
---@param eventItems UIElement[]
---@param clock table
---@param reloadElement UIElement
---@param direction integer
function TBMenuInternal.ChangeCurrentEvent(viewElement, eventsData, eventItems, clock, reloadElement, direction)
	for i, v in pairs(eventItems) do
		if (i == TBMenu.CurrentAnnouncementId) then
			v:hide()
			TBMenu.CurrentAnnouncementId = TBMenu.CurrentAnnouncementId + direction
			if (TBMenu.CurrentAnnouncementId > #eventItems) then
				TBMenu.CurrentAnnouncementId = TBMenu.CurrentAnnouncementId - #eventItems
			elseif (TBMenu.CurrentAnnouncementId < 1) then
				TBMenu.CurrentAnnouncementId = #eventItems
			end
			eventItems[TBMenu.CurrentAnnouncementId]:show()
			local function behavior()
				eventsData[TBMenu.CurrentAnnouncementId].action()
				--[[if (eventsData[TBMenu.CurrentAnnouncementId].stop) then
					clock.pause = true
				end]]
			end
			viewElement:addMouseHandlers(nil, behavior, nil)
			reloadElement:reload()
			local tickTime = os.clock_real()
			clock.start = tickTime
			clock.last = tickTime + 10
			clock.pause = false
			UIElement.handleMouseHover(MOUSE_X, MOUSE_Y)
			break
		end
	end
end

---Displays Home menu with announcements
function TBMenu:showHome()
	if (TBMenu.CurrentSection == nil or TBMenu.CurrentSection.destroyed) then
		TBMenu.CreateCurrentSectionView()
	end

	-- Table to store event announcement data
	local newsData = News:getNews()

	-- If download is in progress, show loading screen instead
	if (newsData.downloading) then
		local homeView = TBMenu.CurrentSection:addChild({
			shift = { 5, 0 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		homeView:addCustomDisplay(false, function()
				if (not newsData.file:isDownloading()) then
					homeView:kill()
					TBMenu:showHome()
				end
			end)
		TBMenu:addBottomBloodSmudge(homeView)
		TBMenu:displayLoadingMark(homeView, TB_MENU_LOCALIZED.NEWSDOWNLOADING)
		return
	end

	usage_event("news");
	set_option("newshopitem", 0)
	-- Create and load regular announcements view
	-- Featured event banner needs to have even borders, make sure it's scaled accordingly to 775x512 default size
	local rightSideWidth = math.min((TBMenu.CurrentSection.size.h * 0.7 - 15) * 1.513, WIN_W / 3) - 10
	local homeAnnouncements = TBMenu.CurrentSection:addChild({
		pos = { 5, 0 },
		size = { TBMenu.CurrentSection.size.w - rightSideWidth - 30, TBMenu.CurrentSection.size.h }
	})
	local featuredEvent = TBMenu.CurrentSection:addChild({
		pos = { homeAnnouncements.shift.x + homeAnnouncements.size.w + 10, 0 },
		size = { rightSideWidth + 10, rightSideWidth / 1.513 + 10 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		hoverSound = 31
	})
	local viewEventsButton = TBMenu.CurrentSection:addChild({
		pos = { featuredEvent.shift.x, featuredEvent.shift.y + featuredEvent.size.h + 10 },
		size = { featuredEvent.size.w, TBMenu.CurrentSection.size.h - featuredEvent.shift.y - featuredEvent.size.h - 10 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		hoverSound = 31
	})

	local eventsData, featuredEvents, featuredEventData = {}, {}, {}
	for i,v in pairs(newsData) do
		if (v.featured) then
			table.insert(featuredEvents, v)
			featuredEventData = v
		else
			table.insert(eventsData, v)
		end
	end
	if (#featuredEvents > 1) then
		featuredEventData = featuredEvents[math.random(1, #featuredEvents)]
	end

	local viewEventsButtonData = {
		title = TB_MENU_LOCALIZED.EVENTSALLEVENTS,
		ratio = 0.3,
		action = function() Events:showEventsHome(TBMenu.CurrentSection) end
	}

	-- Store all elements that would require reloading when switching event announcements in one table
	homeAnnouncements.toReload = homeAnnouncements:addChild({})

	local textHeight, descHeight = homeAnnouncements.size.h / 9, homeAnnouncements.size.h / 8
	local elementWidth, elementHeight, heightShift = unpack(TBMenu:getImageDimensions(homeAnnouncements.size.w, homeAnnouncements.size.h, 0.5, textHeight, descHeight))

	-- Spawn event announcement elements
	-- Make sure rotateClock is spawned before that
	local tickTime = os.clock_real()
	local rotateClock = { start = tickTime, last = tickTime + 10 }
	local eventItems = {}
	local newsItemShown = false
	for i, v in pairs(eventsData) do
		eventItems[i] = UIElement:new({
			parent = homeAnnouncements,
			pos = { 0, 0 },
			size = { homeAnnouncements.size.w, homeAnnouncements.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			interactive = true,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverSound = 31
		})
		if (v.initAction) then
			v.action = function() usage_event("newsview" .. v.title) v.initAction() rotateClock.pause = true end
		end
		TBMenu:showHomeButton(eventItems[i], v, 1)
		if (i ~= TBMenu.CurrentAnnouncementId) then
			eventItems[i]:hide()
		else
			newsItemShown = true
		end
	end

	if (not newsItemShown) then
		-- Make sure we don't end up with empty news section if there was a news update while they're playing
		eventItems[1]:show()
		TBMenu.CurrentAnnouncementId = 1
	end

	if (#eventsData > 1) then
		-- Spawn progress bar before next/prev buttons
		local eventDisplayTime = homeAnnouncements.toReload:addChild({
			size = { 0, 0 }
		})

		-- Auto-rotate event announcements
		featuredEventData.action = function()
			if (featuredEventData.initAction) then
				featuredEventData.initAction()
			end
			rotateClock.pause = true
		end
		local timeData = eventItems[1].button.pos.y > eventItems[1].image.pos.y + eventItems[1].image.size.h and { x = eventItems[1].image.pos.x, width = eventItems[1].image.size.w } or { x = eventItems[1].button.pos.x + 10, width = eventItems[1].button.size.w - 20 }
		eventDisplayTime:addCustomDisplay(true, function()
				if (not rotateClock.pause) then
					set_color(1, 1, 1, 1)
					draw_quad(timeData.x, eventItems[1].image.pos.y + eventItems[1].image.size.h - 5, (UIElement.clock - rotateClock.start) / 10 * timeData.width, 5)
				end
			end)
		homeAnnouncements:addCustomDisplay(false, function()
				if (UIElement.clock > rotateClock.last and not rotateClock.pause) then
					TBMenuInternal.ChangeCurrentEvent(homeAnnouncements, eventsData, eventItems, rotateClock, homeAnnouncements.toReload, 1)
				end
			end)

		-- Manual announcement change
		local btnBgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR)
		btnBgColor[4] = 0
		local eventPrevButton = homeAnnouncements.toReload:addChild({
			pos = { 10, 10 + elementHeight / 2 - 32 },
			size = { 32, 64 },
			bgImage = "../textures/menu/general/buttons/arrowleft.tga",
			imageColor = { 0, 0, 0, 1 },
			imageHoverColor = { 255, 255, 255, 1 },
			imagePressedColor = { 255, 255, 255, 1 },
			bgColor = btnBgColor,
			hoverColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
			pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
			interactive = true,
			hoverThrough = true
		})
		eventPrevButton:addMouseHandlers(nil, function()
				TBMenuInternal.ChangeCurrentEvent(homeAnnouncements, eventsData, eventItems, rotateClock, homeAnnouncements.toReload, -1)
				eventPrevButton.hoverState = BTN_HVR
			end, nil)
		local eventNextButton = homeAnnouncements.toReload:addChild({
			pos = { homeAnnouncements.toReload.size.w - 42, 10 + elementHeight / 2 - 32 },
			size = { 32, 64 },
			bgImage = "../textures/menu/general/buttons/arrowright.tga",
			imageColor = { 0, 0, 0, 1 },
			imageHoverColor = { 255, 255, 255, 1 },
			imagePressedColor = { 255, 255, 255, 1 },
			bgColor = btnBgColor,
			hoverColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
			pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
			interactive = true,
			hoverThrough = true
		})
		eventNextButton:addMouseHandlers(nil, function()
				TBMenuInternal.ChangeCurrentEvent(homeAnnouncements, eventsData, eventItems, rotateClock, homeAnnouncements.toReload, 1)
				eventNextButton.hoverState = BTN_HVR
			end, nil)
	end

	---Do not show any text for featured events, promo image only
	featuredEventData.title = nil
	featuredEventData.subtitle = nil
	TBMenu:showHomeButton(featuredEvent, featuredEventData)
	TBMenu:showHomeButton(viewEventsButton, viewEventsButtonData, 2)
end

---Generic function to display a main menu section button
---@param viewElement UIElement
---@param buttonData MenuSectionButton
---@param hasSmudge ?integer
---@param extraElements ?UIElement[]
---@param lockedMessage ?string
---@return number
---@return number
function TBMenu:showHomeButton(viewElement, buttonData, hasSmudge, extraElements, lockedMessage)
	-- Add hover sound by default so it doesn't have to be set for each element manually
	viewElement.hoverSound = 31
	local lockedMessage = lockedMessage or buttonData.lockedMessage

	local titleHeight = buttonData.title and (buttonData.subtitle and viewElement.size.h / 5 or viewElement.size.h / 3) or 0
	titleHeight = titleHeight > WIN_H / 15 and WIN_H / 15 or titleHeight
	local descHeight = buttonData.subtitle and viewElement.size.h / 6 or 0
	descHeight = descHeight > WIN_H / 15 and WIN_H / 15 or descHeight
	local elementWidth, elementHeight, heightShift = unpack(TBMenu:getImageDimensions(viewElement.size.w, viewElement.size.h, buttonData.ratio, titleHeight, descHeight))
	local selectedIcon = buttonData.image
	if (elementHeight > viewElement.size.h - 20 - titleHeight - descHeight and buttonData.ratio2) then
		elementWidth, elementHeight, heightShift = unpack(TBMenu:getImageDimensions(viewElement.size.w, viewElement.size.h, buttonData.ratio2, titleHeight, descHeight))
		selectedIcon = buttonData.image2
	end
	local extraElements = extraElements or {}
	if (hasSmudge and not (buttonData.title or buttonData.subtitle)) then
		TBMenu:addBottomBloodSmudge(viewElement, hasSmudge)
	end
	local itemIcon = UIElement:new({
		parent = viewElement,
		pos = { (viewElement.size.w - elementWidth) / 2, 10 },
		size = { elementWidth, elementHeight },
		bgImage = selectedIcon,
		disableUnload = buttonData.disableUnload,
		uiColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})

	---Hack to register toReload field for EmmyLua
	viewElement.parent.toReload = viewElement.parent.toReload

	if (type(selectedIcon) == "table") then
		local filename = selectedIcon[1]:gsub(".*/", "")
		for _, v in pairs(NEWS_DOWNLOAD_QUEUE) do
			if (v:find(filename)) then
				TBMenu:displayLoadingMark(itemIcon, nil, elementHeight / 5)
				add_hook("downloader_complete", "menuMain" .. filename, function(name)
						if (name:find(filename .. "$")) then
							Downloader:safeCall(function()
								News:removeFromQueue(name)
								if (viewElement:isDisplayed()) then
									viewElement:kill(true)
									TBMenu:showHomeButton(viewElement, buttonData, hasSmudge, extraElements, lockedMessage)
									if (viewElement.parent and viewElement.parent.toReload) then
										viewElement.parent.toReload:reload()
									end
								else
									local reloader = UIElement:new({
										parent = viewElement,
										pos = { 0, 0 },
										size = { 0, 0 }
									})
									reloader:hide()
									reloader:addCustomDisplay(true, function()
											if (reloader:isDisplayed()) then
												viewElement:kill(true)
												TBMenu:showHomeButton(viewElement, buttonData, hasSmudge, extraElements, lockedMessage)
												viewElement.parent.toReload:reload()
											end
										end)
								end
								remove_hooks("menuMain" .. filename)
							end)
						end
					end)
				break
			end
		end
	end

	-- Make sure we spawn it before buttonOverlay element so that subsequent show() calls on parent don't make blood smudge overlay the text
	if (hasSmudge and (buttonData.title or buttonData.subtitle)) then
		TBMenu:addBottomBloodSmudge(viewElement, hasSmudge)
	end
	local buttonOverlay = UIElement:new( {
		parent = viewElement,
		pos = { 0, -titleHeight - descHeight - 10 },
		size = { viewElement.size.w, titleHeight + descHeight }
	})
	viewElement.button = buttonOverlay
	viewElement.image = itemIcon
	local overlay = nil
	if (viewElement.size.h + buttonOverlay.shift.y < itemIcon.shift.y + itemIcon.size.h) then
		overlay = UIElement:new({
			parent = itemIcon,
			pos = { 0, viewElement.size.h + buttonOverlay.shift.y - itemIcon.shift.y - itemIcon.size.h },
			size = { itemIcon.size.w, -buttonOverlay.shift.y - itemIcon.shift.y - (viewElement.size.h - 20 - itemIcon.size.h) },
			bgColor = viewElement.animateColor
		})
	end
	if (buttonData.title) then
		local buttonTitleView = UIElement:new( {
			parent = buttonOverlay,
			pos = { 10, 0 },
			size = { buttonOverlay.size.w - 20, titleHeight }
		})
		local buttonTitle = UIElement:new( {
			parent = buttonTitleView,
			pos = { 5, 5 },
			size = { buttonTitleView.size.w - 10, buttonTitleView.size.h - 5 }
		})
		buttonTitle:addAdaptedText(true, buttonData.title, nil, nil, FONTS.BIG, buttonData.subtitle and LEFTBOT or LEFT, nil, nil, 0.4)
	end
	if (buttonData.subtitle) then
		local buttonSubtitleView = UIElement:new( {
			parent = buttonOverlay,
			pos = { 10, titleHeight },
			size = { buttonOverlay.size.w - 20, descHeight }
		})
		local buttonSubtitle = UIElement:new( {
			parent = buttonSubtitleView,
			pos = { 5, 0 },
			size = { buttonSubtitleView.size.w - 10, buttonSubtitleView.size.h - 5 }
		})
		buttonSubtitle:addAdaptedText(true, buttonData.subtitle, nil, nil, 4, LEFT)
	end
	if (overlay) then
		viewElement:addMouseHandlers(function()
				overlay.bgColor = table.clone(viewElement.pressedColor)
				for i,v in pairs(extraElements) do
					if (type(v) == "table") then
						v.bgColor = table.clone(viewElement.pressedColor)
					end
				end
			end, function()
				if (buttonData.quit) then
					close_menu()
				end
				if (buttonData.action) then
					buttonData.action()
				end
				overlay.bgColor = viewElement.animateColor
				for i,v in pairs(extraElements) do
					if (type(v) == "table") then
						v.bgColor = viewElement.animateColor
					end
				end
			end)
	else
		viewElement:addMouseHandlers(nil, function()
			if (buttonData.quit) then
				close_menu()
			end
			if (buttonData.action) then
				buttonData.action()
			end
		end)
	end
	if (buttonData.locked and lockedMessage) then
		viewElement:deactivate()
		local lockedMessageView = itemIcon:addChild({
			pos = { 0, 0 },
			size = { itemIcon.size.w, viewElement.size.h - 20 - titleHeight - descHeight },
			bgColor = TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS,
			uiColor = UICOLORWHITE
		})
		local lockedMessageTextBG = lockedMessageView:addChild({
			pos = { lockedMessageView.size.w * 0.1, lockedMessageView.size.h / 5 * 3 },
			size = { lockedMessageView.size.w * 0.8, lockedMessageView.size.h / 3 },
			bgColor = { 0, 0, 0, 0.5 },
			shapeType = ROUNDED,
			rounded = 5
		})
		local lockedMessageText = lockedMessageTextBG:addChild({
			shift = { 10, 5 }
		})
		lockedMessageText:addAdaptedText(nil, lockedMessage)

		local maxLen, lines = 0, 0
		for _, v in pairs(lockedMessageText.dispstr) do
			maxLen = math.max(maxLen, get_string_length(v, lockedMessageText.textFont) * lockedMessageText.textScale)
			lines = lines + 1
		end
		lockedMessageTextBG.size.w = math.min(lockedMessageTextBG.size.w, maxLen + 40)
		lockedMessageTextBG.size.h = math.min(lockedMessageTextBG.size.h, lines * getFontMod(lockedMessageText.textFont) * lockedMessageText.textScale * 10 + 20)
		lockedMessageText.size.w = lockedMessageTextBG.size.w - 20
		lockedMessageText.size.h = lockedMessageTextBG.size.h - 10
		lockedMessageTextBG:moveTo((lockedMessageView.size.w - lockedMessageTextBG.size.w) / 2, lockedMessageView.size.h / 15 * 14 - lockedMessageTextBG.size.h)
	end

	-- Add rounding after everything else to make sure any added elements are covered
	TBMenu:addOuterRounding(itemIcon, viewElement.animateColor)
	return titleHeight, descHeight
end

---Clears navigation bar and current section element for side modules
function TBMenu:clearNavSection()
	if (TBMenu.NavigationBar and not TBMenu.NavigationBar.destroyed) then
		TBMenu.NavigationBar:kill()
		TBMenu.NavigationBar = nil
	end
	if (TBMenu.CurrentSection == nil or TBMenu.CurrentSection.destroyed) then
		TBMenu.CreateCurrentSectionView()
	else
		TBMenu.CurrentSection:kill(true)
	end
end

---Displays Clans menu
function TBMenu:showClans(clantag)
	if (TBMenu.CurrentSection == nil or TBMenu.CurrentSection.destroyed) then
		TBMenu.CreateCurrentSectionView()
	end
	Clans:showMain(TBMenu.CurrentSection, clantag)
end

---Displays Market menu
function TBMenu:showMarket()
	if (TBMenu.CurrentSection == nil or TBMenu.CurrentSection.destroyed) then
		TBMenu.CreateCurrentSectionView()
	end
	Market:showMain(TBMenu.CurrentSection)
end

---Displays Replays menu
function TBMenu:showReplays()
	TBMenu.BottomLeftBar:hide()
	TBMenu:clearNavSection()

	if (TB_MENU_REPLAYS_ONLINE == 1) then
		TBMenu:showNavigationBar(Replays:getNavigationButtons(true), true)
		local menubg = UIElement:new({
			parent = TBMenu.CurrentSection,
			pos = { 5, 0 },
			size = { TBMenu.CurrentSection.size.w - 10, TBMenu.CurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(menubg, 1)
		Replays:getServerReplays()
	else
		Replays:showMain(TBMenu.CurrentSection)
	end
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 5
end

---Displays Notifications menu
function TBMenu:showNotifications()
	if (not TB_STORE_DATA.ready) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREDATALOADERROR)
		return
	end
	TBMenu:clearNavSection()
	Notifications:showMain()
end

---Displays Scripts menu
function TBMenu:showScripts()
	TBMenu:clearNavSection()
	Scripts:showMain()
	TBMenu:showNavigationBar(Scripts:getNavigationButtons(), true)
end

---Displays Settings menu
function TBMenu:showSettings()
	TBMenu.BottomLeftBar:hide()
	TBMenu:clearNavSection()
	Settings:showMain()
	TBMenu:showNavigationBar(Settings:getNavigationButtons(), true, true, TB_MENU_SETTINGS_SCREEN_ACTIVE or 1)
end

---Displays Friends menu
function TBMenu:showFriendsList()
	TBMenu:clearNavSection()
	Friends:showMain(TBMenu.CurrentSection)
	TBMenu:showNavigationBar(Friends:getNavigationButtons(), true)
end

---Displays Bounties menu
function TBMenu:showBounties()
	TBMenu:clearNavSection()
	Bounty:prepare()
	TBMenu:showNavigationBar(Bounty:getNavigationButtons(), true)
end

---Prepares all UIElements to make a scrollable list within a specified UIElement viewport
---@param viewElement UIElement
---@param firstBarSize? number Dimensions of the first bar (top bar height for SCROLL_VERTICAL orientation, left bar width for SCROLL_HORIZONTAL). Defaults to `50`.
---@param secondBarSize? number Dimensions of the second bar (bottom bar height for SCROLL_VERTICAL orientation, right bar width for SCROLL_HORIZONTAL). Defaults to `firstBarSize` value.
---@param scrollSize? number Scroll bar dimensions. Defaults to `20`.
---@param accentColor? Color Background color for all bars. Defaults to `TB_MENU_DEFAULT_DARKER_COLOR`.
---@param orientation? UIElementScrollMode Orientation for the scrollable list. Supported values are SCROLL_VERTICAL or SCROLL_HORIZONTAL. Defaults to `SCROLL_VERTICAL`.
---@return UIElement toReload Object that will be always displayed on top of all list objects. All bars are parented to it.
---@return UIElement firstBar
---@return UIElement secondBar
---@return UIElement listingView
---@return UIElement listingHolder Object that will move when interacting with the list. Assign all list elements as its children.
---@return UIElement scrollBackground
function TBMenu:prepareScrollableList(viewElement, firstBarSize, secondBarSize, scrollSize, accentColor, orientation)
	local firstBarSize = firstBarSize or 50
	local secondBarSize = secondBarSize or firstBarSize
	local scrollSize = scrollSize or 20
	local accentColor = accentColor or table.clone(TB_MENU_DEFAULT_DARKER_COLOR)
	local orientation = orientation or SCROLL_VERTICAL

	local toReload = UIElement:new({
		parent = viewElement,
		pos = { 0, 0 },
		size = { viewElement.size.w, viewElement.size.h }
	})

	local shiftX, shiftY = 0, 0
	local firstBar, secondBar
	if (orientation == SCROLL_VERTICAL) then
		firstBar = toReload:addChild({
			pos = { 0, 0 },
			size = { viewElement.size.w, firstBarSize },
			interactive = true,
			bgColor = accentColor
		})
		secondBar = toReload:addChild({
			pos = { 0, -secondBarSize },
			size = { viewElement.size.w, secondBarSize },
			interactive = true,
			bgColor = accentColor
		})
		shiftY = firstBarSize
	else
		firstBar = toReload:addChild({
			pos = { 0, 0 },
			size = { firstBarSize, viewElement.size.h },
			interactive = true,
			bgColor = accentColor
		})
		secondBar = toReload:addChild({
			pos = { -secondBarSize, 0 },
			size = { secondBarSize, viewElement.size.h },
			interactive = true,
			bgColor = accentColor
		})
		shiftX = firstBarSize
	end

	local listingView = UIElement:new({
		parent = viewElement,
		pos = { shiftX, shiftY },
		size = { viewElement.size.w - (shiftX > 0 and (firstBarSize + secondBarSize) or 0), viewElement.size.h - (shiftY > 0 and (firstBarSize + secondBarSize) or 0) },
		interactive = true
	})
	local listingHolder = UIElement:new({
		parent = listingView,
		pos = { 0, 0 },
		size = orientation == SCROLL_VERTICAL and { listingView.size.w - scrollSize, listingView.size.h } or { listingView.size.w, listingView.size.h - scrollSize}
	})
	local listingScrollBG = UIElement:new({
		parent = listingView,
		pos = orientation == SCROLL_VERTICAL and { -scrollSize, 0 } or { 0, -scrollSize },
		size = orientation == SCROLL_VERTICAL and { scrollSize, listingView.size.h } or { listingView.size.w, scrollSize },
		bgColor = accentColor
	})
	listingHolder.scrollBG = listingScrollBG
	return toReload, firstBar, secondBar, listingView, listingHolder, listingScrollBG
end

---Returns a human readable string from specified number of seconds
---@param seconds integer
---@param cut ?integer
---@return string
function TBMenu:getTime(seconds, cut)
	local returnval = ""
	local timeleft = 0
	local timetype = ""
	if (math.floor(seconds / 3600 / 24 / 365) > 1) then
		timetype = TB_MENU_LOCALIZED.REWARDSTIMEYEARS
		timeleft = math.floor(seconds / 3600 / 24 / 365)
		if (timeleft > 4 and TB_MENU_LOCALIZED.language == "russian") then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEYEARSRUS
		end
		seconds = seconds - timeleft * 3600 * 24 * 365
		returnval = timeleft .. " " .. timetype
	end
	if (math.floor(seconds / 3600 / 24 / 365) == 1) then
		timetype = TB_MENU_LOCALIZED.REWARDSTIMEYEAR
		timeleft = math.floor(seconds / 3600 / 24 / 365)
		seconds = seconds - timeleft * 3600 * 24 * 365
		returnval = timeleft .. " " .. timetype
	end
	if (math.floor(seconds / 3600 / 24 / 30.4) > 2) then
		timetype = TB_MENU_LOCALIZED.REWARDSTIMEMONTHS
		timeleft = math.floor(seconds / 3600 / 24 / 30)
		if (timeleft > 4 and TB_MENU_LOCALIZED.language == "russian") then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEMONTHSRUS
		end
		seconds = seconds - timeleft * 3600 * 24 * 30
		returnval = returnval .. " " .. timeleft .. " " .. timetype
	end
	if (math.floor(seconds / 3600 / 24 / 7) > 1) then
		timetype = TB_MENU_LOCALIZED.REWARDSTIMEWEEKS
		timeleft = math.floor(seconds / 3600 / 24 / 7)
		if (timeleft > 4 and TB_MENU_LOCALIZED.language == "russian") then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEWEEKSRUS
		end
		seconds = seconds - timeleft * 3600 * 24 * 7
		returnval = returnval .. " " .. timeleft .. " " .. timetype
	end
	if (math.floor(seconds / 3600 / 24 / 7) == 1) then
		timetype = TB_MENU_LOCALIZED.REWARDSTIMEWEEK
		timeleft = math.floor(seconds / 3600 / 24 / 7)
		seconds = seconds - timeleft * 3600 * 24 * 7
		returnval = returnval .. " " .. timeleft .. " " .. timetype
	end
	if (math.floor(seconds / 3600 / 24) > 1) then
		timetype = TB_MENU_LOCALIZED.REWARDSTIMEDAYS
		timeleft = math.floor(seconds / 3600 / 24)
		if (timeleft > 4 and TB_MENU_LOCALIZED.language == "russian") then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEDAYSRUS
		end
		seconds = seconds - timeleft * 3600 * 24
		returnval = returnval .. " " .. timeleft .. " " .. timetype
	end
	if (math.floor(seconds / 3600 / 24) == 1) then
		timetype = TB_MENU_LOCALIZED.REWARDSTIMEDAY
		timeleft = math.floor(seconds / 3600 / 24)
		seconds = seconds - timeleft * 3600 * 24
		returnval = returnval .. " " .. timeleft .. " " .. timetype
	end
	if (math.floor(seconds / 3600) > 1) then
		timetype = TB_MENU_LOCALIZED.REWARDSTIMEHOURS
		timeleft = math.floor(seconds / 3600)
		if (timeleft > 4 and TB_MENU_LOCALIZED.language == "russian") then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEHOURSRUS
		end
		seconds = seconds - timeleft * 3600
		returnval = returnval .. " " .. timeleft .. " " .. timetype
	end
	if (math.floor(seconds / 3600) == 1) then
		timetype = TB_MENU_LOCALIZED.REWARDSTIMEHOUR
		timeleft = math.floor(seconds / 3600)
		seconds = seconds - timeleft * 3600
		returnval = returnval .. " " .. timeleft .. " " .. timetype
	end
	if (math.floor(seconds / 60) > 1) then
		timetype = TB_MENU_LOCALIZED.REWARDSTIMEMINUTES
		timeleft = math.floor(seconds / 60)
		if (timeleft > 4 and TB_MENU_LOCALIZED.language == "russian") then
			timetype = TB_MENU_LOCALIZED.REWARDSTIMEMINUTESRUS
		end
		seconds = seconds - timeleft * 60
		returnval = returnval .. " " .. timeleft .. " " .. timetype
	end
	if (math.floor(seconds / 60) == 1) then
		timetype = TB_MENU_LOCALIZED.REWARDSTIMEMINUTE
		timeleft = math.floor(seconds / 60)
		seconds = seconds - timeleft * 60
		returnval = returnval .. " " .. timeleft .. " " .. timetype
	end
	if (seconds > 0 and timetype == "") then
		timetype = TB_MENU_LOCALIZED.REWARDSTIMESECONDS
		returnval = returnval .. " " .. seconds .. " " .. timetype
	end
	returnval = returnval:gsub("^ ", "")
	if (cut) then
		local _, ePos = returnval:find(("%d+%s%S+%s"):rep(cut))
		if (ePos) then
			returnval = returnval:sub(0, ePos - 1)
		end
	end
	return returnval
end

---Spawns an overlay that slightly dims main menu
---@param globalid ?integer
---@param withMouseHandler ?boolean
---@return UIElement
---@overload fun(self: TBMenu, withMouseHandler: boolean) : UIElement
function TBMenu:spawnWindowOverlay(globalid, withMouseHandler)
	if (type(globalid) == "boolean") then
		withMouseHandler = globalid
		globalid = nil
	end
	TB_MENU_POPUPS_DISABLED = true
	UIScrollbarIgnore = true
	local overlay = UIElement:new({
		---@diagnostic disable-next-line: assign-type-mismatch
		globalid = globalid,
		---@diagnostic disable-next-line: assign-type-mismatch
		parent = globalid == nil and TBMenu.MenuMain,
		pos = { 0, 0 },
		size = { WIN_W, WIN_H },
		interactive = true,
		bgColor = { 0, 0, 0, 0.4 }
	})
	if (TBMenu.UserBar ~= nil) then
		for _, v in pairs(TBMenu.UserBar.headDisplayObjects) do
			v.bgColor[1] = v.bgColor[1] - 0.4
			v.bgColor[2] = v.bgColor[2] - 0.4
			v.bgColor[3] = v.bgColor[3] - 0.4
		end
	end

	overlay.killAction = function()
		UIScrollbarIgnore = false
		TB_MENU_POPUPS_DISABLED = false

		if (TBMenu.UserBar == nil) then return end
		for _, v in pairs(TBMenu.UserBar.headDisplayObjects) do
			v.bgColor[1] = v.bgColor[1] + 0.4
			v.bgColor[2] = v.bgColor[2] + 0.4
			v.bgColor[3] = v.bgColor[3] + 0.4
		end
	end
	if (withMouseHandler) then
		overlay:addMouseHandlers(nil, function()
				overlay:kill()
			end)
	end
	return overlay
end

---Displays a generic confirmation window with a text input field
---@param title string
---@param inputInfo string
---@param confirmAction function
---@param cancelAction ?function
---@param subtitle ?string
---@param globalid ?integer
---@return UIElement
function TBMenu:showConfirmationWindowInput(title, inputInfo, confirmAction, cancelAction, subtitle, globalid)
	local subtitleSet = subtitle and 1 or 0
	local confirmOverlay = TBMenu:spawnWindowOverlay(globalid)
	local confirmBoxView = UIElement:new({
		parent = confirmOverlay,
		pos = { confirmOverlay.size.w / 4, confirmOverlay.size.h / 2 - 80 - subtitleSet * 20 },
		size = { confirmOverlay.size.w / 2, 160 + subtitleSet * 20 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 5
	})
	local confirmBoxTitle = UIElement:new({
		parent = confirmBoxView,
		pos = { 10, 5 },
		size = { confirmBoxView.size.w - 20, 45 }
	})
	confirmBoxTitle:addAdaptedText(true, title, nil, nil, FONTS.BIG, nil, 0.65)
	if (subtitleSet) then
		local confirmBoxSubtitle = UIElement:new({
			parent = confirmBoxView,
			pos = { 10, confirmBoxTitle.shift.y + confirmBoxTitle.size.h },
			size = { confirmBoxView.size.w - 20, 20 }
		})
		confirmBoxSubtitle:addAdaptedText(true, subtitle, nil, nil, 4, nil, 0.6)
	end
	local textField = TBMenu:spawnTextField2(confirmBoxView, { x = 10, y = confirmBoxTitle.shift.y + confirmBoxTitle.size.h + subtitleSet * 25 + 10, w = confirmBoxView.size.w - 20, h = 30 }, nil, inputInfo)
	local cancelButton = UIElement:new({
		parent = confirmBoxView,
		pos = { 10, -50 },
		size = { confirmBoxView.size.w / 2 - 15, 40 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 1, 1, 0.2 },
		shapeType = ROUNDED,
		rounded = 4
	})
	cancelButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCANCEL)
	cancelButton:addMouseHandlers(nil, function()
			confirmOverlay:kill()
			if (cancelAction) then
				cancelAction(textField.textfieldstr[1])
			end
		end)
	local acceptButton = UIElement:new({
		parent = confirmBoxView,
		pos = { confirmBoxView.size.w / 2 + 5, -50 },
		size = { confirmBoxView.size.w / 2 - 15, 40 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 1, 1, 0.2 },
		shapeType = cancelButton.shapeType,
		rounded = cancelButton.rounded
	})
	acceptButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCONTINUE)
	acceptButton:addMouseHandlers(nil, function()
			confirmOverlay:kill()
			confirmAction(textField.textfieldstr[1])
		end)
	return confirmOverlay
end

---Generic function to display a confirmation window
---@param message string
---@param confirmAction function
---@param cancelAction ?function
---@param thirdAction ?function
---@param thirdButtonText ?string
---@param globalid ?integer
---@return UIElement
function TBMenu:showConfirmationWindow(message, confirmAction, cancelAction, thirdAction, thirdButtonText, globalid)
	local confirmOverlay = TBMenu:spawnWindowOverlay(globalid)
	local width = thirdAction and confirmOverlay.size.w / 7 * 4 or confirmOverlay.size.w / 7 * 3
	local confirmBoxView = UIElement:new({
		parent = confirmOverlay,
		pos = { (confirmOverlay.size.w - width) / 2, confirmOverlay.size.h / 2 - confirmOverlay.size.h / 10 },
		size = { width, confirmOverlay.size.h / 5 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 5
	})
	local confirmBoxMessage = confirmBoxView:addChild({
		pos = { 10, 10 },
		size = { confirmBoxView.size.w - 20, confirmBoxView.size.h - 80 }
	})
	local actions = thirdAction and 3 or 2
	confirmBoxMessage:addAdaptedText(true, message)
	while (confirmBoxMessage.textScale < 1 and confirmBoxView.size.h < confirmOverlay.size.h * 0.75) do
		confirmBoxView.size.h = confirmBoxView.size.h + 50
		confirmBoxMessage.size.h = confirmBoxView.size.h - 80
		confirmBoxView:moveTo(nil, -25, true)
		confirmBoxMessage.str = nil
		confirmBoxMessage:addAdaptedText(true, message)
	end
	confirmBoxView:updatePos()
	local cancelButton = confirmBoxView:addChild({
		pos = { 10, -60 },
		size = { confirmBoxView.size.w / actions - 15, 50 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	cancelButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCANCEL)
	cancelButton:addMouseHandlers(nil, function()
			confirmOverlay:kill()
			if (cancelAction) then
				cancelAction()
			end
		end)
	local acceptButton = confirmBoxView:addChild({
		pos = { -confirmBoxView.size.w / actions + 5, -60 },
		size = { confirmBoxView.size.w / actions - 15, 50 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	acceptButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCONTINUE)
	acceptButton:addMouseHandlers(nil, function()
			confirmOverlay:kill()
			confirmAction()
		end)
	if (thirdAction) then
		local thirdButton = confirmBoxView:addChild({
			pos = { confirmBoxView.size.w / actions + 5, -60 },
			size = { confirmBoxView.size.w / actions - 10, 50 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		if (thirdButtonText) then
			thirdButton:addAdaptedText(false, thirdButtonText)
		end
		thirdButton:addMouseHandlers(nil, function()
				confirmOverlay:kill()
				thirdAction()
			end)
	end
	return confirmOverlay
end

---@class TBMenuStatusMessage : UIElement
---@field messageView UIElement
---@field startTime number
---@field endTime number

---Displays a popup message on the bottom of the screen
---@param message string Message that will be displayed to the user
---@param time ?number Duration during which the message will be displayed
function TBMenu:showStatusMessage(message, time)
	local time = time or 5
	local transparency = 0
	local bgColor, uiColor = { 0, 0, 0, transparency }, { 1, 1, 1, transparency }
	if (TBMenu.StatusMessage) then
		TBMenu.StatusMessage:kill()
		TBMenu.StatusMessage = nil
	end
	local dataErrorY = (TBMenu.MenuMain and TBMenu.MenuMain.pos.y > 0) and (-TBMenu.MenuMain.pos.y) or WIN_H
	local messageWidth = WIN_W / 2 > 800 and 800 or WIN_W / 2
	TBMenu.StatusMessage = UIElement:new({
		---@diagnostic disable-next-line: assign-type-mismatch
		globalid = TB_MENU_MAIN_ISOPEN == 0 and TB_MENU_HUB_GLOBALID or nil,
		parent = TBMenu.MenuMain,
		pos = { (WIN_W - messageWidth) / 2, dataErrorY },
		size = { messageWidth, 54 },
		bgColor = bgColor,
		shapeType = ROUNDED,
		rounded = 5
	})
	local errorMessageView = TBMenu.StatusMessage:addChild({
		pos = { TBMenu.StatusMessage.size.w / 10, TBMenu.StatusMessage.size.h / 10 },
		size = { TBMenu.StatusMessage.size.w * 0.8, TBMenu.StatusMessage.size.h * 0.8 }
	})
	errorMessageView:addAdaptedText(true, message, nil, nil, 4, nil, 0.9, nil, nil, nil, uiColor)
	TBMenu.StatusMessage.messageView = errorMessageView

	while (errorMessageView.textScale < 0.65) do
		TBMenu.StatusMessage.size.h = TBMenu.StatusMessage.size.h + 10
		errorMessageView.size.h = TBMenu.StatusMessage.size.h * 0.8
		errorMessageView.str = ''
		errorMessageView:addAdaptedText(true, message, nil, nil, 4, nil, 0.9, nil, nil, nil, uiColor)
	end

	TBMenu.StatusMessage.startTime = UIElement.clock
	TBMenu.StatusMessage.endTime = UIElement.clock + time + 0.5
	local targetOffsetY = WIN_H - TBMenu.StatusMessage.size.h - 10
	TBMenu.StatusMessage:addCustomDisplay(false, function()
			if (TBMenu.StatusMessage.pos.y > targetOffsetY) then
				local tweenRatio = (UIElement.clock - TBMenu.StatusMessage.startTime) / 2
				TBMenu.StatusMessage:moveTo(nil, UITween.SineTween(TBMenu.StatusMessage.pos.y, targetOffsetY, tweenRatio))
				transparency = UITween.SineEaseIn(tweenRatio * 2)
				bgColor[4] = 0.8 * transparency
				uiColor[4] = transparency
			else
				TBMenu.StatusMessage:addCustomDisplay(false, function()
						if (TBMenu.StatusMessage.endTime < UIElement.clock) then
							transparency = 1 - UITween.SineEaseOut(UIElement.clock - TBMenu.StatusMessage.endTime)
							bgColor[4] = 0.8 * transparency
							uiColor[4] = transparency

							if (transparency <= 0) then
								TBMenu.StatusMessage:kill()
							end
						end
					end)
			end
		end)
end

---@deprecated
---Use `TBMenu:showStatusMessage()` instead \
---@see TBMenu.showStatusMessage
function TBMenu:showDataError(message, noParent, time)
	TBMenu:showStatusMessage(message, time)
end

---Displays Store menu
function TBMenu:showTorishopMain()
	if (TBMenu.CurrentSection == nil or TBMenu.CurrentSection.destroyed) then
		TBMenu.CreateCurrentSectionView()
	end
	Torishop:showMain(TBMenu.CurrentSection)
end

---Displays Account menu
function TBMenu:showAccountMain()
	local lastSpecialScreen = TB_MENU_SPECIAL_SCREEN_ISOPEN
	TBMenu:clearNavSection()
	TBMenu:showNavigationBar({
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
			action = function()
				TB_MENU_SPECIAL_SCREEN_ISOPEN = lastSpecialScreen
				TBMenu.CurrentSection:kill(true)
				TBMenu.NavigationBar:kill(true)
				TBMenu:showNavigationBar()
				TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
			end,
		}
	}, true)

	local accountView = UIElement:new({
		parent = TBMenu.CurrentSection,
		pos = { 5, 0 },
		size = { TBMenu.CurrentSection.size.w - 10, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local elementHeight = 50
	local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(accountView, accountView.size.h / 10 > elementHeight and accountView.size.h / 10 or elementHeight, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

	TBMenu:addBottomBloodSmudge(botBar, 1)
	local accountTitle = UIElement:new({
		parent = topBar,
		pos = { 20, 5 },
		size = { topBar.size.w / 2 - 25, topBar.size.h - 10 }
	})
	accountTitle:addAdaptedText(true, TB_MENU_LOCALIZED.ACCOUNTTITLEINFO, nil, nil, FONTS.BIG, LEFTMID, nil, nil, 0.2)
	local accountDataRefresh = UIElement:new({
		parent = topBar,
		pos = { -45, 5 },
		size = { 40, 40 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 3
	})
	local accountDataRefreshIcon = UIElement:new({
		parent = accountDataRefresh,
		pos = { 5, 5 },
		size = { accountDataRefresh.size.w - 10, accountDataRefresh.size.h - 10 },
		bgImage = "../textures/menu/general/buttons/restart.tga"
	})
	accountDataRefresh:addMouseHandlers(nil, function()
			if (get_network_task() == 0) then
				TBMenu:showAccountMain()
			end
		end)
	local switchButtonSize = topBar.size.w / 2 - 55 > 250 and 250 or topBar.size.w / 2 - 55
	local accountSwitch = UIElement:new({
		parent = topBar,
		pos = { -switchButtonSize - 50, 5 },
		size = { switchButtonSize, 40 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 3
	})
	TBMenu:showTextWithImage(accountSwitch, TB_MENU_LOCALIZED.ACCOUNTSWITCH, FONTS.MEDIUM, 24, TB_MENU_LOGOUT_BUTTON)
	accountSwitch:addMouseHandlers(nil, function() open_menu(18) end)

	local function showAccountData(data)
		local listElements = {}
		for i,v in pairs(data) do
			if (type(v) == "table") then
				local infoBG = UIElement:new({
					parent = listingHolder,
					pos = { 0, elementHeight * #listElements },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, infoBG)
				local infoHolder = UIElement:new({
					parent = infoBG,
					pos = { 10, 5 },
					size = { infoBG.size.w - 10, elementHeight - 10 },
					bgColor = v.customColor or TB_MENU_DEFAULT_DARKER_COLOR,
					uiColor = v.customUiColor,
					interactive = v.action,
					hoverColor = v.customHoverColor or TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				})
				local infoText = UIElement:new({
					parent = infoHolder,
					pos = { 10, 0 },
					size = { infoHolder.size.w - 20, infoHolder.size.h }
				})
				if (v.hint) then
					local hintSign = UIElement:new({
						parent = infoHolder,
						pos = { 5, 5 },
						size = { 30, 30 },
						bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						hoverColor = TB_MENU_DEFAULT_BG_COLOR,
						shapeType = ROUNDED,
						uiColor = UICOLORWHITE,
						rounded = 36,
						interactive = true
					})
					TBMenu:displayHelpPopup(hintSign, v.hint)
					infoText:moveTo(40)
					infoText.size.w = infoHolder.size.w - 50
				end
				infoText:addAdaptedText(true, v.name .. ": " .. v.value, nil, nil, nil, LEFTMID)
				if (v.action) then
					infoHolder:addMouseHandlers(nil, v.action)
				end
			end
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = scrollBar
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
	end

	local accountDatas = PlayerInfo.getServerUserinfo()
	local infoMessage = listingHolder:addChild({})
	TBMenu:displayLoadingMark(infoMessage, TB_MENU_LOCALIZED.ACCOUNTGETTINGINFO)
	infoMessage:addChild({}):addCustomDisplay(true, function()
			if (accountDatas.ready) then
				if (accountDatas.failed) then
					infoMessage:kill(true)
					infoMessage:addAdaptedText(true, TB_MENU_LOCALIZED.ACCOUNTINFOERROR)
					return
				end
				infoMessage:kill()
				accountDatas.ready = nil

				showAccountData(accountDatas)
			end
		end)
end

---@deprecated
function TBMenu:showMatchmaking()
	--[[require("system/matchmake_manager")
	if (not TBMenu.CurrentSection) then
		TBMenu.CreateCurrentSectionView()
	end
	-- Connect user to matchmake server
	Ranking:connect()
	Ranking:showMain(TBMenu.CurrentSection)]]
end

---Displays Battle Pass menu
function TBMenu:showBattlepass()
	if (TBMenu.CurrentSection == nil or TBMenu.CurrentSection.destroyed) then
		TBMenu.CreateCurrentSectionView()
	end
	BattlePass:showMain()
end

---Displays Play menu
function TBMenu:showPlaySection()
	local tbMenuPlayButtonsData = {
		{ title = TB_MENU_LOCALIZED.MAINMENUFREEPLAYNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUFREEPLAYDESC, size = 0.5, ratio = 0.5, image = "../textures/menu/freeplay.tga", mode = ORIENTATION_LANDSCAPE, action = function() open_menu(1) end, disableUnload = true },
		{ title = TB_MENU_LOCALIZED.MAINMENUREPLAYSNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUREPLAYSDESC, size = 0.25, ratio = 1.055, image = "../textures/menu/replays2.tga", mode = ORIENTATION_PORTRAIT, action = function() TBMenu:showReplays() end, disableUnload = true },
		{ title = TB_MENU_LOCALIZED.MAINMENUROOMLISTNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUROOMLISTDESC, size = 0.25, ratio = 1.055, image = "../textures/menu/multiplayer.tga", mode = ORIENTATION_PORTRAIT, action = function() RoomList:showMain() end, disableUnload = true }
	}

	if (TB_MENU_PLAYER_INFO.username == '') then
		tbMenuPlayButtonsData[3] = nil
		tbMenuPlayButtonsData[1].size = 0.667
		tbMenuPlayButtonsData[2].size = 0.333
	end
	TBMenu:showSection(tbMenuPlayButtonsData)
end

---Displays Tutorials menu
function TBMenu:showPracticeSection()
	dofile("tutorial/tutorial_manager.lua")
	local tbMenuPracticeButtonsData = Tutorials:getMainMenuButtons()
	TBMenu:showSection(tbMenuPracticeButtonsData)
end

---Displays Toribash hotkeys
function TBMenu:showHotkeys()
	local overlay = TBMenu:spawnWindowOverlay()
	overlay:addMouseHandlers(nil, function()
			TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
			overlay:kill()
		end)
	local hotkeysView = UIElement:new({
		parent = overlay,
		pos = { WIN_W / 10, 100 },
		size = { WIN_W * 0.8, WIN_H - 200 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	local elementHeight = 50
	local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(hotkeysView, elementHeight, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)
	local hotkeysTitle = UIElement:new({
		parent = topBar,
		pos = { 10, 0 },
		size = { topBar.size.w - 20, topBar.size.h }
	})
	hotkeysTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MAINMENUHOTKEYSNAME, nil, nil, FONTS.BIG)
	local backButton = UIElement:new({
		parent = topBar,
		pos = { -(get_string_length(TB_MENU_LOCALIZED.NAVBUTTONBACK, FONTS.MEDIUM) + 100), 10 },
		size = { get_string_length(TB_MENU_LOCALIZED.NAVBUTTONBACK, FONTS.MEDIUM) + 90, topBar.size.h - 20 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	backButton:addAdaptedText(false, TB_MENU_LOCALIZED.NAVBUTTONBACK)
	backButton:addMouseHandlers(nil, function()
			overlay:kill()
		end)
	TBMenu:addBottomBloodSmudge(botBar, 1)

	local hotkeys = {
		{
			name = TB_MENU_LOCALIZED.HOTKEYSBASICCONTROLS,
			items = {
				{
					keys = { { "w", "a", "s", "d" }, "shift" },
					desc = TB_MENU_LOCALIZED.HOTKEYSCAMERACONTROLS
				},
				{
					keys = { "c" },
					desc = TB_MENU_LOCALIZED.HOTKEYSHOLDALL
				},
				{
					keys = { "x" },
					desc = TB_MENU_LOCALIZED.HOTKEYSHOLDRELAX
				},
				{
					keys = { "z" },
					desc = TB_MENU_LOCALIZED.HOTKEYSCONTRACTEXTEND
				},
				{
					keys = { "l" },
					desc = TB_MENU_LOCALIZED.HOTKEYSGRABUNGRAB
				},
				{
					keys = { "v" },
					desc = TB_MENU_LOCALIZED.HOTKEYSGRABALL
				},
				{
					keys = { "f" },
					desc = TB_MENU_LOCALIZED.HOTKEYSSAVEREPLAY
				},
				{
					keys = { "g" },
					desc = TB_MENU_LOCALIZED.HOTKEYSTORIGHOST
				},
				{
					keys = { "b" },
					desc = TB_MENU_LOCALIZED.HOTKEYSPLAYERSGHOST
				},
				{
					keys = { "space", "shift" },
					desc = TB_MENU_LOCALIZED.HOTKEYSTURN
				},
			}
		},
		{
			name = TB_MENU_LOCALIZED.HOTKEYSCHAT,
			items = {
				{
					keys = { { "enter", "t" } },
					desc = TB_MENU_LOCALIZED.HOTKEYSOPENCHAT
				},
				{
					keys = { Settings:getKeyName(get_option("chattoggle")) },
					desc = TB_MENU_LOCALIZED.HOTKEYSTOGGLECHAT
				},
				{
					keys = { { "pgup", "pgdn" } },
					desc = TB_MENU_LOCALIZED.HOTKEYSSCROLLCHAT
				},
				{
					keys = { { "home", "end" } },
					desc = TB_MENU_LOCALIZED.HOTKEYSSCROLLCHATMAX
				}
			}
		},
		{
			name = TB_MENU_LOCALIZED.HOTKEYSREPLAYS,
			items = {
				{
					keys = { Settings:getKeyName(get_option("replayhudtoggle")) },
					desc = TB_MENU_LOCALIZED.SETTINGSREPLAYHUDTOGGLE
				},
				{
					keys = { "r" },
					desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYRESTART
				},
				{
					keys = { "p" },
					desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYPAUSE
				},
				{
					keys = { "e" },
					desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYEDIT
				},
				{
					keys = { "k" },
					desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYKEYFRAME
				},
				{
					keys = { "i" },
					desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYKEYFRAMESCLEAR
				},
				{
					keys = { { "<", ">" }, "shift" },
					desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYSPEED
				},
				{
					keys = { "ctrl", "]" },
					desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYNEXT
				},
				{
					keys = { "ctrl", "[" },
					desc = TB_MENU_LOCALIZED.HOTKEYSREPLAYPREV
				}
			}
		},
		{
			name = TB_MENU_LOCALIZED.HOTKEYSOTHER,
			items = {
				{
					keys = { "ctrl", "m" },
					desc = TB_MENU_LOCALIZED.HOTKEYSMODLIST
				},
				{
					keys = { "ctrl", "h" },
					desc = TB_MENU_LOCALIZED.HOTKEYSSHADERS
				},
				{
					keys = { "ctrl", "g" },
					desc = TB_MENU_LOCALIZED.HOTKEYSGAMERULES
				},
				{
					keys = { "ctrl", "enter" },
					desc = TB_MENU_LOCALIZED.HOTKEYSFULLSCREEN
				},
				{
					keys = { "1", "7" },
					dash = true,
					desc = TB_MENU_LOCALIZED.HOTKEYSCAMERAMODES
				}
			}
		}
	}

	local listElements = {}
	for i, section in pairs(hotkeys) do
		local sectionTitle = UIElement:new({
			parent = listingHolder,
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		sectionTitle:addAdaptedText(false, section.name, 10, nil, FONTS.BIG, LEFTMID, 0.6, nil, 0.2)
		table.insert(listElements, sectionTitle)
		for i, hotkey in pairs(section.items) do
			local hotkeyView = UIElement:new({
				parent = listingHolder,
				pos = { 10, #listElements * elementHeight + 5 },
				size = { listingHolder.size.w - 20, elementHeight - 10 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			})
			table.insert(listElements, hotkeyView)
			local description = UIElement:new({
				parent = hotkeyView,
				pos = { 10, 0 },
				size = { hotkeyView.size.w / 2 - 10, hotkeyView.size.h }
			})
			description:addAdaptedText(true, hotkey.desc, nil, nil, nil, LEFTMID)
			local kPos = description.size.w + 20
			for i, key in pairs(hotkey.keys) do
				if (type(key) == "table") then
					for i, v in pairs(key) do
						if (i > 1) then
							local commaSign = UIElement:new({
								parent = hotkeyView,
								pos = { kPos, 0 },
								size = { get_string_length(",", FONTS.MEDIUM) + 10, hotkeyView.size.h - 5 }
							})
							commaSign:addAdaptedText(true, ",", nil, nil, FONTS.MEDIUM, LEFTBOT)
							kPos = kPos + commaSign.size.w
						end
						local keyViewBG = UIElement:new({
							parent = hotkeyView,
							pos = { kPos, 5 },
							size = { hotkeyView.size.h - 10 + get_string_length(v, FONTS.MEDIUM), hotkeyView.size.h - 10 },
							bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
							shapeType = ROUNDED,
							rounded = 4
						})
						local keyView = UIElement:new({
							parent = keyViewBG,
							pos = { 1, 1 },
							size = { keyViewBG.size.w - 2, keyViewBG.size.h - 2 },
							bgColor = TB_MENU_DEFAULT_BG_COLOR,
							shapeType = ROUNDED,
							rounded = 4,
							innerShadow = { 2, 2 },
							shadowColor = { TB_MENU_DEFAULT_LIGHTER_COLOR, TB_MENU_DEFAULT_DARKEST_COLOR }
						})
						keyView:addAdaptedText(false, v)
						kPos = kPos + keyView.size.w + 5
					end
				else
					if (#hotkeyView.child > 1) then
						local plusSign = UIElement:new({
							parent = hotkeyView,
							pos = { kPos, 0 },
							size = { get_string_length(hotkey.dash and "-" or "+", FONTS.MEDIUM) + 10, hotkeyView.size.h }
						})
						plusSign:addAdaptedText(true, hotkey.dash and "-" or "+", nil, nil, FONTS.MEDIUM)
						kPos = kPos + plusSign.size.w + 5
					end
					local keyViewBG = UIElement:new({
						parent = hotkeyView,
						pos = { kPos, 5 },
						size = { hotkeyView.size.h - 10 + get_string_length(key, FONTS.MEDIUM), hotkeyView.size.h - 10 },
						bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						shapeType = ROUNDED,
						rounded = 4
					})
					local keyView = UIElement:new({
						parent = keyViewBG,
						pos = { 1, 1 },
						size = { keyViewBG.size.w - 2, keyViewBG.size.h - 2 },
						bgColor = TB_MENU_DEFAULT_BG_COLOR,
						shapeType = ROUNDED,
						rounded = 4,
						innerShadow = { 2, 2 },
						shadowColor = { TB_MENU_DEFAULT_LIGHTER_COLOR, TB_MENU_DEFAULT_DARKEST_COLOR }
					})
					keyView:addAdaptedText(false, key)
					kPos = kPos + keyView.size.w + 5
				end
			end
		end
	end
	for _, v in pairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	scrollBar:makeScrollBar(listingHolder, listElements, toReload, nil, nil, true)
	UIScrollbarIgnore = true
end

-- Not used anymore
-- function TBMenu:showModsSection()
-- 	local tbMenuModsButtonsData = {
-- 		{ title = TB_MENU_LOCALIZED.MAINMENUMODMAKERNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUMODMAKERDESC, size = 0.25, image = "../textures/menu/modmaker.tga", mode = ORIENTATION_PORTRAIT, action = function() open_menu(17) end },
-- 		{ title = TB_MENU_LOCALIZED.MAINMENUGAMERULESNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUGAMERULESDESC, size = 0.25, image = "../textures/menu/gamerules.tga", mode = ORIENTATION_PORTRAIT, action = function() open_menu(5) end, quit = true },
-- 		{ title = TB_MENU_LOCALIZED.MAINMENUMODLISTNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUMODLISTDESC, size = 0.5, image = "../textures/menu/modlist.tga", mode = ORIENTATION_LANDSCAPE, action = function()
-- 				dofile("system/mods_manager.lua")
-- 				if (MODS_MENU_MAIN_ELEMENT) then
-- 					MODS_MENU_MAIN_ELEMENT:kill()
-- 					MODS_MENU_MAIN_ELEMENT = nil
-- 				end
-- 				Mods:showMain()
-- 			end, quit = true }
-- 	}
-- 	TBMenu:showSection(tbMenuModsButtonsData)
-- end

---@class MenuSectionButton
---@field title string Button heading text
---@field subtitle string Button description text
---@field lockedMessage string Locked button information string
---@field locked boolean Whether this button should be locked
---@field size number Horizontal button scale (percentage of total section width)
---@field vsize number Vertical button scale (percentage of total section height)
---@field ratio number Image proportions ratio
---@field image string|string[] Image path
---@field ratio2 number Alternative image proportions ratio
---@field image2 string|string[] Alternative image path
---@field action function Function that will be executed on button click
---@field quit boolean Whether pressing this button should exit main menu
---@field disableUnload boolean Whether button image shouldn't be unloaded on UIElement destruction

---Displays Tools screen
function TBMenu:showToolsSection()
	---@type MenuSectionButton[]
	local tbMenuToolsButtonsData = {
		{ title = TB_MENU_LOCALIZED.MAINMENUMODLISTNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUMODLISTDESC, size = 0.25, ratio = 1.055, image = "../textures/menu/modlist2.tga", action = function() dofile("system/mods.lua") end, quit = true, disableUnload = true },
		{ title = TB_MENU_LOCALIZED.MAINMENUGAMERULESNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUGAMERULESDESC, size = 0.25, ratio = 1.055, image = "../textures/menu/gamerules2.tga", action = function() dofile("system/gamerules.lua") end, quit = true, disableUnload = true },
		{ title = TB_MENU_LOCALIZED.MAINMENUMODMAKERNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUMODMAKERDESC, size = 0.25, vsize = 0.5, ratio = 1.055, image = "../textures/menu/modmaker2.tga", ratio2 = 0.5, image2 = "../textures/menu/modmaker3.tga", action = function() open_menu(17) end, disableUnload = true },
		{ title = TB_MENU_LOCALIZED.MAINMENUSCRIPTSNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUSCRIPTSDESC, size = 0.25, vsize = 0.5, ratio = 1.055, image = "../textures/menu/scripts.tga", ratio2 = 0.5, image2 = "../textures/menu/scripts2.tga", action = function() TBMenu:showScripts() end, disableUnload = true },
		{ title = TB_MENU_LOCALIZED.MAINMENUSHADERSNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUSHADERSDESC, size = 0.25, vsize = 0.5, ratio = 0.5, image = "../textures/menu/shaders2.tga", action = function()
				dofile("system/atmo.lua")
			end, quit = true, disableUnload = true },
		{ title = TB_MENU_LOCALIZED.MAINMENUHOTKEYSNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUHOTKEYSDESC, size = 0.25, vsize = 0.5, ratio = 1.055, image = "../textures/menu/hotkeys.tga", ratio2 = 0.5, image2 = "../textures/menu/hotkeys2.tga", action = function() TBMenu:showHotkeys() end, disableUnload = true },
	}
	TBMenu:showSection(tbMenuToolsButtonsData)
end

---Adds a generic blood smudge at the bottom of the specified UIElement
---@param parentElement UIElement
---@param num ?integer
---@param scale ?integer
---@return UIElement|nil
function TBMenu:addBottomBloodSmudge(parentElement, num, scale)
	if (not parentElement) then
		return nil
	end
	local scale = (scale or 64) * TB_MENU_GLOBAL_SCALE
	local bottomSmudge = TB_MENU_BOTTOM_SMUDGE_BIG
	local num = num or 1
	if (parentElement.size.w < 400) then
		if (num % 2 == 1) then
			bottomSmudge = TB_MENU_BOTTOM_SMUDGE_MEDIUM1
		else
			bottomSmudge = TB_MENU_BOTTOM_SMUDGE_MEDIUM2
		end
	end
	local smudgeElement = UIElement:new({
		parent = parentElement,
		pos = { 0, -(scale * 0.75) },
		size = { parentElement.size.w, scale },
		bgImage = bottomSmudge,
		disableUnload = true,
		imageColor = parentElement.interactive and parentElement.animateColor or parentElement.bgColor
	})
	return smudgeElement
end

---Generic function to build a main menu screen using the provided buttons data
---@param buttonsData MenuSectionButton[]
---@param shift ?number
---@param lockedMessage ?string
function TBMenu:showSection(buttonsData, shift, lockedMessage)
	if (TBMenu.CurrentSection == nil or TBMenu.CurrentSection.destroyed) then
		TBMenu.CreateCurrentSectionView()
	end
	local sectionX = shift and shift + 15 or 5
	local sectionY = 0
	for i,v in pairs(buttonsData) do
		local buttonView = UIElement:new({
			parent = TBMenu.CurrentSection,
			pos = { sectionX, sectionY },
			size = { TBMenu.CurrentSection.size.w * v.size - 10, v.vsize and (TBMenu.CurrentSection.size.h * v.vsize - 5) or TBMenu.CurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			interactive = true,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverSound = 31
		})
		sectionY = v.vsize and sectionY + buttonView.size.h + 10 or sectionY
		sectionY = sectionY >= TBMenu.CurrentSection.size.h and 0 or sectionY
		sectionX = sectionY == 0 and sectionX + buttonView.size.w + 10 or sectionX
		TBMenu:showHomeButton(buttonView, v, sectionY == 0 and i or nil, nil, lockedMessage)
	end
end

---Opens main menu screen by its id or a screen with the corresponding `TB_MENU_SPECIAL_SCREEN_ISOPEN` in case it's valid value.
---@param screenId integer
function TBMenu:openMenu(screenId)
	if (TBMenu.BottomLeftBar) then
		TBMenu.BottomLeftBar:show()
	end

	-- If last used screen was matchmaking, disable search and disconnect from lobby
	--[[if (TB_MATCHMAKER_SEARCHSTATUS) then
		TB_MATCHMAKER_SEARCHSTATUS = nil
		if (get_world_state().game_type == 0) then
			UIElement:runCmd("matchmake disconnect")
		end
	end]]

	if (TB_MENU_SPECIAL_SCREEN_ISOPEN == 1) then
		TBMenu:showTorishopMain()
		Torishop:prepareInventory(TBMenu.CurrentSection)
	elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 2) then
		RoomList:showMain()
	--[[elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 3) then
		TBMenu:showClans()
		if (TB_MENU_CLANS_OPENCLANID ~= 0) then
			Clans:showClan(TBMenu.CurrentSection, TB_MENU_CLANS_OPENCLANID)
		end]]
	elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 4) then
		TBMenu:showNotifications()
	elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 5) then
		TBMenu:showReplays()
	elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 6) then
		TBMenu:showSettings()
	elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 7) then
		TBMenu:showBounties()
	elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 8) then
		TBMenu:showFriendsList()
	elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 9) then
		TBMenu:showTorishopMain()
		Torishop:showStoreSection(TBMenu.CurrentSection, TB_LAST_STORE_SECTION, TB_LAST_STORE_SECTIONID)
	elseif (screenId == 1) then
		TBMenu:showHome()
	elseif (screenId == 2) then
		TBMenu:showPlaySection()
	elseif (screenId == 3) then
		TBMenu:showPracticeSection()
	--elseif (screenId == 4) then
		--TBMenu:showModsSection()
	elseif (screenId == 5) then
		TBMenu:showToolsSection()
	elseif (screenId == 6) then
		TBMenu:showTorishopMain()
	elseif (screenId == 7) then
		TBMenu:showAccountMain()
	--[[elseif (screenId == 8) then
		TBMenu:showMatchmaking()]]
	elseif (screenId == 9) then
		TBMenu:showClans()
	elseif (screenId == 10) then
		TBMenu:showMarket()
	elseif (screenId == 11) then
		TBMenu:showBattlepass()
	elseif (screenId == 101) then
		TBMenu:showNotifications()
	elseif (screenId == 102) then
		TBMenu:showFriendsList()
	end
end

---Displays Toribash (or user custom loaded) logo on top left
function TBMenu:showGameLogo()
	local logo = TB_MENU_GAME_LOGO
	local gametitle = TB_MENU_GAME_TITLE
	local logoSize = 90 * TB_MENU_GLOBAL_SCALE
	local gameTitleSize = 256 * TB_MENU_GLOBAL_SCALE
	local customLogo = Files:open("../custom/" .. TB_MENU_PLAYER_INFO.username .. "/logo.tga")
	if (customLogo.data) then
		logo = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/logo.tga"
		logoSize = 120
		customLogo:close()
	end
	local customGametitle = Files:open("custom/" .. TB_MENU_PLAYER_INFO.username .. "/header.tga")
	if (customGametitle.data) then
		gametitle = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/header.tga"
		customGametitle:close()
	end
	local tbMenuLogo = TBMenu.MenuMain:addChild({
		pos = { logoSize / 9 * 5, 10 },
		size = { logoSize, logoSize },
		bgImage = logo,
		disableUnload = true,
		interactive = is_mobile()
	})
	local tbMenuGameTitle = TBMenu.MenuMain:addChild({
		pos = { logoSize / 9 * 14 + 5, 15 },
		size = { gameTitleSize, gameTitleSize },
		bgImage = gametitle,
		disableUnload = true,
		interactive = is_mobile()
	})
end

---Displays top right user bar
function TBMenu:showUserBar()
	local userBarImageWidth = math.ceil((SCREEN_RATIO > 2 and 1024 or 640) * (TB_MENU_GLOBAL_SCALE or 1))
	local userBarWidth = math.min(userBarImageWidth, WIN_W / 2)
	if (TBMenu.UserBar) then
		TBMenu.UserBar:kill()
		TBMenu.UserBar = nil
	end

	TBMenu.UserBar = TBMenu.MenuMain:addChild({
		pos = { -userBarWidth, 0 },
		size = { userBarWidth, 100 }
	})

	local userBarImage = TBMenu.UserBar:addChild({
		pos = { 1, -TBMenu.UserBar.size.h - 1 },
		size = { userBarImageWidth, userBarImageWidth / (SCREEN_RATIO > 2 and 8 or 5) },
		bgImage = SCREEN_RATIO > 2 and TB_MENU_USERBAR_WIDE or TB_MENU_USERBAR_MAIN,
		disableUnload = true,
		imageColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = is_mobile()
	})
	local headViewportHolder = TBMenu.UserBar:addChild({
		pos = { userBarImage.size.h * 0.7, -TBMenu.UserBar.size.h - userBarImage.size.h / 10 },
		size = { userBarImage.size.h, userBarImage.size.h }
	})
	local headViewport = TBMenu:showPlayerHeadAvatar(headViewportHolder, TB_MENU_PLAYER_INFO, true)
	TBMenu.UserBar.headDisplayObjects = headViewport.avatarObjects
	if (not UIElement.lightUIMode) then
		local headRotation = math.pi / 2
		headViewport.rootHolder:addCustomDisplay(true, function()
				headViewport.rootHolder:rotate(0, 0, math.cos(headRotation))
				headRotation = headRotation + math.pi / 570
			end)
	end

	local safe_x, _, safe_w, _ = get_window_safe_size()
	safe_x = math.max(safe_x, WIN_W - safe_x - safe_w, SCREEN_RATIO > 2 and 30 or 10)
	local infoHolder = TBMenu.UserBar:addChild({
		pos = { userBarImage.size.h * 1.75, 10 },
		size = { TBMenu.UserBar.size.w - userBarImage.size.h * 1.75 - safe_x, userBarImage.size.h * 0.9 - 20 }
	})
	local clanDisplayed = TB_MENU_PLAYER_INFO.clan.id ~= 0
	local tbMenuUserName = infoHolder:addChild({
		pos = { 0, 0 },
		size = { infoHolder.size.w / 2, math.min(40, infoHolder.size.h / (clanDisplayed and 2.6 or 2)) },
		shadowOffset = 0
	})
	local displayName = TB_MENU_PLAYER_INFO.username == "" and "Tori" or TB_MENU_PLAYER_INFO.username
	tbMenuUserName:addAdaptedText(true, displayName, nil, nil, 0, LEFTMID, 0.7, nil, 0.5, 2)
	tbMenuUserName.size.w = get_string_length(tbMenuUserName.dispstr[1], tbMenuUserName.textFont) * tbMenuUserName.textScale + 15

	local accountButton = infoHolder:addChild({
		pos = { tbMenuUserName.shift.x + tbMenuUserName.size.w, tbMenuUserName.shift.y + 2 },
		size = { infoHolder.size.w - tbMenuUserName.shift.x * 2, tbMenuUserName.size.h - 4 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKER_ORANGE,
		shapeType = ROUNDED,
		rounded = tbMenuUserName.size.h
	})
	accountButton:addAdaptedText(nil, TB_MENU_LOCALIZED.NAVBUTTONACCOUNT, 15, nil, 4, LEFTMID, 0.65)
	accountButton.size.w = get_string_length(accountButton.dispstr[1], accountButton.textFont) * accountButton.textScale + accountButton.size.h + 30
	accountButton:addCustomDisplay(false, function() end)
	local accountButtonText = accountButton:addChild({
		shift = { 10, accountButton.size.h * 0.05 },
	})
	TBMenu:showTextWithImage(accountButtonText, TB_MENU_LOCALIZED.NAVBUTTONACCOUNT, 4, accountButtonText.size.h * 0.8, TB_MENU_LOGOUT_BUTTON, {
		maxTextScale = 0.65
	})
	accountButton:addMouseHandlers(nil, function()
			if (string.len(PlayerInfo.Get().username) > 0) then
				TBMenu:showAccountMain()
			else
				open_menu(18)
			end
		end)

	local infoOffset = tbMenuUserName.shift.y + tbMenuUserName.size.h
	local tbMenuClan = nil
	if (clanDisplayed) then
		tbMenuClan = infoHolder:addChild({
			pos = { 0, infoOffset },
			size = { infoHolder.size.w - infoHolder.size.h, infoHolder.size.h / 5 }
		})
		if (TB_MENU_PLAYER_INFO.clan.id ~= 0) then
			tbMenuClan:addAdaptedText(true, TB_MENU_LOCALIZED.MAINMENUUSERCLAN .. ": " .. TB_MENU_PLAYER_INFO.clan.tag .. ((TB_MENU_PLAYER_INFO.clan.name ~= '') and ("  |  " .. TB_MENU_PLAYER_INFO.clan.name) or ''), nil, nil, 4, LEFT, math.max(0.55, tbMenuUserName.textScale))
		end
		infoOffset = infoOffset + tbMenuClan.size.h
	else
		infoOffset = infoOffset + infoHolder.size.h / 10
	end

	local tcView = infoHolder:addChild({
		pos = { 0, infoOffset },
		size = { (infoHolder.size.w - infoHolder.size.h - 20) / 2, clanDisplayed and infoHolder.size.h / 3 or infoHolder.size.h / 2.5 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		hoverSound = 31,
		shapeType = ROUNDED,
		rounded = infoHolder.size.h
	})
	local tcPopup = TBMenu:displayPopup(tcView, TB_MENU_LOCALIZED.USERBARTCINFO)
	tcView:addMouseHandlers(nil, function()
			if (TB_STORE_DATA.ready) then
				Torishop:showStoreSection(TBMenu.CurrentSection, 4, 1)
				tcPopup:reload()
			end
		end)

	local tcIcon = tcView:addChild({
		pos = { 0, -tcView.size.h - 1 },
		size = { tcView.size.h + 3, tcView.size.h + 3 },
		bgImage = "../textures/store/toricredit.tga",
		disableUnload = true
	})
	local tcBalance = tcView:addChild({
		pos = { tcView.size.h + 10, 0 },
		size = { tcView.size.w - tcIcon.size.w - 5, tcView.size.h }
	})
	tcBalance:addAdaptedText(true, numberFormat(TB_MENU_PLAYER_INFO.data.tc), nil, nil, 2, LEFTMID, 0.9)
	tcView.size.w = get_string_length(tcBalance.dispstr[1], tcBalance.textFont) * tcBalance.textScale + tcView.size.h + 30
	tcPopup:moveTo(math.min(tcPopup.shift.x, -tcView.size.w - (tcPopup.size.w - tcView.size.w) / 2), tcView.size.h + 5)

	local stView = infoHolder:addChild({
		pos = { tcView.shift.x + tcView.size.w + 15, tcView.shift.y },
		size = { (infoHolder.size.w - infoHolder.size.h - 20) / 2 - 15, tcView.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		hoverSound = 31,
		shapeType = ROUNDED,
		rounded = tcView.size.h
	})
	local stPopup = TBMenu:displayPopup(stView, TB_MENU_LOCALIZED.USERBARSTINFO)
	stView:addMouseHandlers(nil, function()
			if (TB_STORE_DATA.ready) then
				Torishop:showStoreSection(TBMenu.CurrentSection, 4, 2)
				stPopup:reload()
			end
		end)

	local stIcon = stView:addChild({
		pos = { 0, -stView.size.h - 1 },
		size = { stView.size.h + 2, stView.size.h + 2 },
		bgImage = "../textures/store/shiaitoken.tga",
		disableUnload = true
	})
	local stBalance = stView:addChild( {
		pos = { stView.size.h + 10, 0 },
		size = { stView.size.w - stIcon.size.w - 5, stView.size.h }
	})
	stBalance:addAdaptedText(true, numberFormat(TB_MENU_PLAYER_INFO.data.st), nil, nil, 2, LEFTMID, 0.9)
	stView.size.w = get_string_length(stBalance.dispstr[1], stBalance.textFont) * stBalance.textScale + stView.size.h + 30
	stPopup:moveTo(math.min(stPopup.shift.x, -stView.size.w - (stPopup.size.w - stView.size.w) / 2), stView.size.h + 5)

	local userBelt = infoHolder:addChild({
		pos = { -infoHolder.size.h - 20, -infoHolder.size.h - 10 },
		size = { infoHolder.size.h + 20, infoHolder.size.h + 20 },
		bgImage = TB_MENU_PLAYER_INFO.data.belt.icon,
		disableUnload = true
	})
	local beltTitle = userBelt:addChild({
		pos = { 0, userBelt.size.h / 2 },
		size = { userBelt.size.w, userBelt.size.h / 2 - 10 },
		uiShadowColor = UICOLORBLACK,
		shadowOffset = 1
	})
	beltTitle:addAdaptedText(TB_MENU_PLAYER_INFO.data.belt.name .. " " .. TB_MENU_LOCALIZED.WORDBELT, nil, nil, 2, nil, nil, nil, nil, 1)

	TB_MENU_CUSTOMS_REFRESHED = false
	TBMenu.UserBar:addCustomDisplay(false, function()
			if (TB_MENU_CUSTOMS_REFRESHED) then
				TB_MENU_CUSTOMS_REFRESHED = false

				tcBalance.size.w = infoHolder.size.w / 3
				tcBalance:addAdaptedText(true, numberFormat(TB_MENU_PLAYER_INFO.data.tc), nil, nil, tcBalance.textFont, LEFTMID, tcBalance.textScale)
				tcView.size.w = get_string_length(tcBalance.dispstr[1], tcBalance.textFont) * tcBalance.textScale + tcView.size.h + 30
				tcPopup:moveTo(-tcView.size.w - (tcPopup.size.w - tcView.size.w) / 2, tcView.size.h + 5)

				stView:moveTo(tcView.shift.x + tcView.size.w + 20)
				stBalance.size.w = infoHolder.size.w / 3
				stBalance:addAdaptedText(true, numberFormat(TB_MENU_PLAYER_INFO.data.st), nil, nil, stBalance.textFont, LEFTMID, stBalance.textScale)
				stView.size.w = get_string_length(stBalance.dispstr[1], stBalance.textFont) * stBalance.textScale + stView.size.h + 30
				stPopup:moveTo(-stView.size.w - (stPopup.size.w - stView.size.w) / 2, stView.size.h + 5)

				if (TB_MENU_PLAYER_INFO.clan.id ~= 0 and tbMenuClan) then
					tbMenuClan:addAdaptedText(true, TB_MENU_LOCALIZED.MAINMENUUSERCLAN .. ": " .. TB_MENU_PLAYER_INFO.clan.tag .. ((TB_MENU_PLAYER_INFO.clan.name ~= '') and ("  |  " .. TB_MENU_PLAYER_INFO.clan.name) or ''), nil, nil, 4, 0, 0.6)
				end
				userBelt:updateImage(TB_MENU_PLAYER_INFO.data.belt.icon)
				beltTitle:addAdaptedText(true, TB_MENU_PLAYER_INFO.data.belt.name .. " " .. TB_MENU_LOCALIZED.WORDBELT, nil, nil, 2, nil, nil, nil, nil, 1)
			end
		end)
end

---@class TBHeadAvatarViewport : UIElement
---@field objectViewport UIElement3D
---@field rootHolder UIElement3D
---@field avatarObjects UIElement3D[]

---Generic function to display player head in a viewport
---@param viewElement UIElement
---@param player PlayerInfo
---@param extraSize ?boolean
---@return TBHeadAvatarViewport
---@overload fun(self:TBMenu, viewElement:UIElement, player:string, extraSize?:boolean):TBHeadAvatarViewport
function TBMenu:showPlayerHeadAvatar(viewElement, player, extraSize)
	local viewportSize = math.min(viewElement.size.w, viewElement.size.h) * (extraSize == true and 2 or 1)

	---@type TBHeadAvatarViewport
	---@diagnostic disable-next-line: assign-type-mismatch
	local headViewport = viewElement:addChild({
		pos = { -viewElement.size.w - math.abs((viewElement.size.w - viewportSize) / 2), -viewElement.size.h - math.abs((viewElement.size.h - viewportSize) / 2) },
		size = { viewportSize, viewportSize },
		viewport = true
	})
	headViewport.avatarObjects = {}
	headViewport.objectViewport = UIElement3D:new({
		globalid = viewElement.globalid,
		shapeType = VIEWPORT,
		parent = headViewport,
		pos = { 0, 0, 0 },
		size = { 0, 0, 0 },
		rot = { 0, 0, 0 },
		viewport = true
	})
	headViewport.rootHolder = headViewport.objectViewport:addChild({
		shapeType = CUBE,
		size = { 0, 0, 0 },
		rot = { 0, 0, -10 }
	})

	local playerName = ""
	local customs = player.items
	if (type(player) == "string") then
		customs = PlayerInfo:getItems(player, PLAYERINFO_CSCOPE_ALL)
		playerName = player
	else
		if (player.items == nil or
			player.items.colors == nil or
			player.items.effects == nil or
			player.items.objs == nil or
			player.items.textures == nil) then
			customs = player:getItems(PLAYERINFO_CSCOPE_ALL)
		end
		playerName = player.username
	end

	local headTexture = { "../../custom/tori/head.tga", "../../custom/tori/head.tga" }
	if (customs.textures.head.equipped) then
		headTexture[1] = "../../custom/" .. playerName .. "/head.tga"
	end
	local playerHeadHolder = headViewport.rootHolder:addChild({
		shapeType = SPHERE,
		pos = { 0, 0, 10 },
		size = { extraSize and 0.45 or 0.9, 0, 0 },
		bgColor = { 1, 1, 1, 1 },
		bgImage = headTexture,
		effects = customs.effects.head
	})
	table.insert(headViewport.avatarObjects, playerHeadHolder)
	local playerNeckHolder = playerHeadHolder:addChild({
		shapeType = SPHERE,
		pos = { 0, playerHeadHolder.size.x / 9 * 1.8, -playerHeadHolder.size.x / 9 * 5.8},
		size = { playerHeadHolder.size.x / 9 * 5, 0, 0 },
		bgColor = get_color_rgba(customs.colors.force),
		effects = customs.effects.force
	})
	table.insert(headViewport.avatarObjects, playerNeckHolder)
	if (customs.objs.head.equipped) then
		local objScale = customs.objs.head.dynamic and 2 or 10
		if (customs.objs.head.partless and playerHeadHolder) then
			playerHeadHolder:kill()
		end
		local modelColor = get_color_rgba(customs.objs.head.colorid)
		modelColor[4] = customs.objs.head.alpha / 255
		local headObjModel = playerHeadHolder:addChild({
			shapeType = CUSTOMOBJ,
			objModel = "../../custom/" .. playerName .. "/head",
			size = { objScale * playerHeadHolder.size.x, objScale * playerHeadHolder.size.x, objScale * playerHeadHolder.size.x },
			bgColor = modelColor
		})
		table.insert(headViewport.avatarObjects, headObjModel)
	end

	return headViewport
end

-- TBMenu navigation button data
---@class MenuNavButton
---@field text string Main button text
---@field misctext string|nil Miscellaneous button text, will be displayed in a frame nearby
---@field width number Button width assigned by showNavigationBar()
---@field action function Function that will be executed when button is pressed
---@field right boolean If true, button will be displayed on the right side of the navigation bar
---@field sectionId integer Menu section id that will be assigned to TB_LAST_MENU_SCREEN_OPEN on button click
---@field adapted string[] Adapted button text, only used for mobile nav buttons

---Displays mobile navigation bar using the provided data.
---@see TBMenu.showNavigationBar
---@param buttonsData MenuNavButton[] Buttons data. If not specified, default main menu navigation buttons data will be used instead.
---@param customNav? boolean Whether the provided data is not supposed to use TB_LAST_MENU_SCREEN_OPEN to mark the currently active button. *You likely want this set to true*.
---@param customNavHighlight? boolean Whether to remember the last selected button and keep it marked as active
---@param selectedId? integer Button ID that would be selected by default \
---@overload fun(self: TBMenu)
function TBMenu:showMobileNavigationBar(buttonsData, customNav, customNavHighlight, selectedId)
	local tbMenuNavigationButtonsData = buttonsData or TBMenu:getMainNavigationButtons()
	local tbMenuNavigationButtons = {}
	local selectedId = selectedId or 0

	local navWidth = math.min(WIN_W / 8, 300)
	local navY = { t = { 10 } , b = { -10 } }

	if (TBMenu.NavigationBar and not TBMenu.NavigationBar.destroyed) then
		TBMenu.NavigationBar:kill(true)
		TBMenu.NavigationBar = nil
	end
	local safeX = get_window_safe_size()
	TBMenu.NavigationBar = UIElement:new({
		parent = TBMenu.MenuMain,
		pos = { math.max(safeX, 50 * TB_MENU_GLOBAL_SCALE), 130 * TB_MENU_GLOBAL_SCALE },
		size = { navWidth, WIN_H - 220 * TB_MENU_GLOBAL_SCALE },
		bgColor = { 0, 0, 0, 0.9 },
		shapeType = ROUNDED,
		rounded = 10,
		interactive = is_mobile()
	})

	---Unlike with horizontal menu, button always have the same width but may be multiline.
	---We need to calculate target font scale to render all captions at the same size and see whether
	---buttons with long text can be newlined and still fit the navigation

	local navbarArea = TBMenu.NavigationBar.size.h - navY.t[1] - navY.b[1]
	local buttonHeight = math.min(navbarArea / (#tbMenuNavigationButtonsData + 1), 60)
	local fontScale = 0.65
	local fontId = FONTS.BIG

	local targetWidth = 500000
	while (targetWidth > TBMenu.NavigationBar.size.w) do
		local availableHeight = navbarArea - buttonHeight
		fontScale = fontScale - 0.05
		local runMaxWidth = 0
		for _, v in pairs(tbMenuNavigationButtonsData) do
			availableHeight = availableHeight - buttonHeight

			local currentWidth = get_string_length(v.text, fontId) * fontScale + 30
			local miscTextWidth = v.misctext and (get_string_length(v.misctext, fontId) * fontScale * 0.8 + 20) or 0
			currentWidth = currentWidth + miscTextWidth

			if (currentWidth > TBMenu.NavigationBar.size.w) then
				v.adapted = textAdapt(v.text, fontId, fontScale, TBMenu.NavigationBar.size.w - 30, true)

				local lastStringWidth = get_string_length(v.adapted[#v.adapted], fontId) * fontScale + 30
				if (lastStringWidth + miscTextWidth > TBMenu.NavigationBar.size.w) then
					if (miscTextWidth > 0) then
						table.insert(v.adapted, v.misctext)
						lastStringWidth = miscTextWidth
					else
						runMaxWidth = 500000
						break
					end
				end
				availableHeight = availableHeight + buttonHeight - (#v.adapted * buttonHeight * 0.75)
				if (availableHeight < 0) then
					runMaxWidth = 500000
					break
				end
				runMaxWidth = math.max(runMaxWidth, TBMenu.NavigationBar.size.w)
			else
				v.adapted = { v.text }
				runMaxWidth = math.max(runMaxWidth, currentWidth)
			end
		end
		if (fontScale < 0.45 and fontId == FONTS.BIG) then
			fontId = FONTS.MEDIUM
			fontScale = 1.05
		else
			targetWidth = math.min(targetWidth, runMaxWidth)
		end
	end

	for i, v in pairs(tbMenuNavigationButtonsData) do
		local navY = v.right and navY.b or navY.t
		local height = buttonHeight * math.max(1, #v.adapted * 0.75)
		tbMenuNavigationButtons[i] = UIElement:new({
			parent = TBMenu.NavigationBar,
			pos = { 0, v.right and navY[1] - height or navY[1] },
			size = { TBMenu.NavigationBar.size.w, height },
			bgColor = { 0.2, 0.2, 0.2, 0 },
			interactive = true,
			hoverColor = TB_MENU_DEFAULT_BG_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverSound = 31
		})
		navY[1] = v.right and navY[1] - tbMenuNavigationButtons[i].size.h or navY[1] + tbMenuNavigationButtons[i].size.h
		if ((not customNav and TB_LAST_MENU_SCREEN_OPEN == v.sectionId) or (customNav and customNavHighlight and selectedId == v.sectionId)) then
			tbMenuNavigationButtons[i].bgColor = TB_MENU_DEFAULT_BG_COLOR
		end
		tbMenuNavigationButtons[i]:addCustomDisplay(false, function()
				set_color(tbMenuNavigationButtons[i].animateColor[1] - 0.1, tbMenuNavigationButtons[i].animateColor[2], tbMenuNavigationButtons[i].animateColor[3], tbMenuNavigationButtons[i].animateColor[4])
				for j = buttonHeight - 10, 10, -10 do
					draw_line(tbMenuNavigationButtons[i].pos.x, tbMenuNavigationButtons[i].pos.y - 1 + j, tbMenuNavigationButtons[i].pos.x + j, tbMenuNavigationButtons[i].pos.y + 1, 0.5)
				end
				for j = 0, tbMenuNavigationButtons[i].size.w - buttonHeight, 10 do
					draw_line(tbMenuNavigationButtons[i].pos.x + buttonHeight + j, tbMenuNavigationButtons[i].pos.y + 1, tbMenuNavigationButtons[i].pos.x + j, tbMenuNavigationButtons[i].pos.y + buttonHeight - 1, 0.5)
				end
				for j = buttonHeight - 10, 10, -10 do
					draw_line(tbMenuNavigationButtons[i].pos.x + tbMenuNavigationButtons[i].size.w - j, tbMenuNavigationButtons[i].pos.y + buttonHeight - 1, tbMenuNavigationButtons[i].pos.x + tbMenuNavigationButtons[i].size.w, tbMenuNavigationButtons[i].pos.y + buttonHeight - 1 - j, 0.5)
				end
			end)
		local buttonText = tbMenuNavigationButtons[i]:addChild({ shift = { 15, buttonHeight / 6 } })
		if (v.misctext) then
			local width = get_string_length(v.misctext, fontId) * fontScale * 0.8 + 20
			local newlined = v.adapted[#v.adapted] == v.misctext
			local miscMark = buttonText:addChild({
				pos = { newlined and (buttonText.size.w - width) / 2 or -(buttonText.size.w - get_string_length(v.adapted[#v.adapted], fontId) * fontScale + width - 16) / 2, -buttonHeight * 0.55 },
				size = { width, buttonHeight * 0.5 },
				bgColor = TB_MENU_DEFAULT_ORANGE,
				uiColor = UICOLORBLACK,
				shapeType = ROUNDED,
				rounded = buttonText.size.h / 2
			})
			miscMark:addAdaptedText(false, v.misctext, nil, nil, fontId, nil, fontScale * 0.8, nil, 0.7)
			if (#v.adapted == 1 or newlined) then
				buttonText:addAdaptedText(true, v.text .. (newlined and "\n" or ''), not newlined and -width / 2, nil, fontId, nil, fontScale)
			else
				local textLines = table.clone(v.adapted)
				table.remove(textLines)
				buttonText:addAdaptedText(true, table.implode(textLines, "\n") .. "\n", nil, nil, fontId, nil, fontScale)
				buttonText:addChild({}):addAdaptedText(true, string.rep("\n", #v.adapted - 1) .. v.adapted[#v.adapted], -width / 2, nil, fontId, nil, fontScale)
			end
		else
			buttonText:addAdaptedText(true, v.text, nil, nil, fontId, nil, fontScale)
		end
		tbMenuNavigationButtons[i]:addMouseHandlers(nil, function()
				if (not customNav) then
					if (v.sectionId == -1) then
						close_menu()
						return
					end
					if (v.sectionId ~= TB_LAST_MENU_SCREEN_OPEN) then
						TBMenu.CurrentSection:kill(true)
						TB_LAST_MENU_SCREEN_OPEN = v.sectionId
						for i, v in pairs(tbMenuNavigationButtons) do
							v.bgColor = { 0.2, 0.2, 0.2, 0 }
						end
						tbMenuNavigationButtons[i].bgColor = TB_MENU_DEFAULT_BG_COLOR
						TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
					end
				else
					if (customNavHighlight) then
						if (v.sectionId ~= selectedId and v.sectionId ~= -1) then
							selectedId = v.sectionId
							for i, v in pairs(tbMenuNavigationButtons) do
								v.bgColor = { 0.2, 0.2, 0.2, 0 }
							end
							tbMenuNavigationButtons[i].bgColor = TB_MENU_DEFAULT_BG_COLOR
						end
					end
					v.action()
				end
			end, nil)
	end
end

---Displays navigation bar using the provided data
---@param buttonsData MenuNavButton[] Buttons data. If not specified, default main menu navigation buttons data will be used instead.
---@param customNav? boolean Whether the provided data is not supposed to use TB_LAST_MENU_SCREEN_OPEN to mark the currently active button. *You likely want this set to true*.
---@param customNavHighlight? boolean Whether to remember the last selected button and keep it marked as active
---@param selectedId? integer Button ID that would be selected by default
---@overload fun(self: TBMenu)
function TBMenu:showNavigationBar(buttonsData, customNav, customNavHighlight, selectedId)
	if (SCREEN_RATIO > 2) then
		TBMenu:showMobileNavigationBar(buttonsData, customNav, customNavHighlight, selectedId)
		return
	end

	local tbMenuNavigationButtonsData = buttonsData or TBMenu:getMainNavigationButtons()
	local tbMenuNavigationButtons = {}
	local selectedId = selectedId or 0

	local navHeight = WIN_H / 16 > 60 and 60 or WIN_H / 16
	local navX = { l = { 30 } , r = { -30 } }

	if (TBMenu.NavigationBar and not TBMenu.NavigationBar.destroyed) then
		TBMenu.NavigationBar:kill(true)
		TBMenu.NavigationBar = nil
	end
	TBMenu.NavigationBar = UIElement:new({
		parent = TBMenu.MenuMain,
		pos = { 50 * TB_MENU_GLOBAL_SCALE, 130 * TB_MENU_GLOBAL_SCALE },
		size = { WIN_W - 100 * TB_MENU_GLOBAL_SCALE, navHeight },
		bgColor = { 0, 0, 0, 0.9 },
		shapeType = ROUNDED,
		rounded = 10,
		interactive = is_mobile()
	})

	-- Check if total button width doesn't exceed navbar width
	-- Assign button width accordingly
	local totalWidth = TBMenu.NavigationBar.size.w
	local fontScale = 0.65
	local fontId = FONTS.BIG
	local temp = TBMenu.NavigationBar:addChild({
		size = { TBMenu.NavigationBar.size.w, TBMenu.NavigationBar.size.h / 6 * 4 }
	})

	while (totalWidth > TBMenu.NavigationBar.size.w - navX.l[1] + navX.r[1]) do
		totalWidth = 0
		fontScale = fontScale - 0.05
		for i,v in pairs(tbMenuNavigationButtonsData) do
			if (getFontMod(fontId) * 10 * fontScale > temp.size.h) then
				totalWidth = TBMenu.NavigationBar.size.w
				break
			end

			temp:addAdaptedText(true, v.text, nil, nil, fontId, nil, fontScale, fontScale)
			v.width = (get_string_length(temp.dispstr[1], temp.textFont) + 110) * temp.textScale
			if (v.misctext) then
				v.width = v.width + (get_string_length(v.misctext, temp.textFont) + 40) * temp.textScale * 0.8
			end
			totalWidth = totalWidth + v.width
		end
	end
	temp:kill()

	for i, v in pairs(tbMenuNavigationButtonsData) do
		local navX = v.right and navX.r or navX.l
		tbMenuNavigationButtons[i] = UIElement:new( {
			parent = TBMenu.NavigationBar,
			pos = { v.right and navX[1] - v.width or navX[1], 0 },
			size = { v.width, TBMenu.NavigationBar.size.h },
			bgColor = { 0.2, 0.2, 0.2, 0 },
			interactive = true,
			hoverColor = TB_MENU_DEFAULT_BG_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverSound = 31
		})
		navX[1] = v.right and navX[1] - v.width or navX[1] + v.width
		if ((not customNav and TB_LAST_MENU_SCREEN_OPEN == v.sectionId) or (customNav and customNavHighlight and selectedId == v.sectionId)) then
			tbMenuNavigationButtons[i].bgColor = TB_MENU_DEFAULT_BG_COLOR
		end
		tbMenuNavigationButtons[i]:addCustomDisplay(false, function()
				set_color(tbMenuNavigationButtons[i].animateColor[1] - 0.1, tbMenuNavigationButtons[i].animateColor[2], tbMenuNavigationButtons[i].animateColor[3], tbMenuNavigationButtons[i].animateColor[4])
				for j = TBMenu.NavigationBar.size.h - 10, 10, -10 do
					draw_line(tbMenuNavigationButtons[i].pos.x, tbMenuNavigationButtons[i].pos.y - 1 + j, tbMenuNavigationButtons[i].pos.x + j, tbMenuNavigationButtons[i].pos.y + 1, 0.5)
				end
				for j = 0, tbMenuNavigationButtons[i].size.w - TBMenu.NavigationBar.size.h, 10 do
					draw_line(tbMenuNavigationButtons[i].pos.x + TBMenu.NavigationBar.size.h + j, tbMenuNavigationButtons[i].pos.y + 1, tbMenuNavigationButtons[i].pos.x + j, tbMenuNavigationButtons[i].pos.y + TBMenu.NavigationBar.size.h - 1, 0.5)
				end
				for j = TBMenu.NavigationBar.size.h - 10, 10, -10 do
					draw_line(tbMenuNavigationButtons[i].pos.x + tbMenuNavigationButtons[i].size.w - j, tbMenuNavigationButtons[i].pos.y + TBMenu.NavigationBar.size.h - 1, tbMenuNavigationButtons[i].pos.x + tbMenuNavigationButtons[i].size.w, tbMenuNavigationButtons[i].pos.y + TBMenu.NavigationBar.size.h - 1 - j, 0.5)
				end
			end)
		local buttonText = tbMenuNavigationButtons[i]:addChild({ shift = { 15, TBMenu.NavigationBar.size.h / 6 } })
		if (v.misctext) then
			local width = (get_string_length(v.misctext, fontId) + 40) * fontScale * 0.8
			local miscMark = UIElement:new({
				parent = buttonText,
				pos = { -(buttonText.size.w - get_string_length(v.text, fontId) * fontScale + width - 16) / 2, buttonText.size.h * 0.125 },
				size = { width, buttonText.size.h * 0.75 },
				bgColor = TB_MENU_DEFAULT_ORANGE,
				uiColor = UICOLORBLACK,
				shapeType = ROUNDED,
				rounded = buttonText.size.h / 2
			})
			miscMark:addAdaptedText(false, v.misctext, nil, nil, fontId, nil, nil, nil, 0.7)
			buttonText:addAdaptedText(true, v.text, -width / 2, nil, fontId, nil, fontScale)
		else
			buttonText:addAdaptedText(true, v.text, nil, nil, fontId, nil, fontScale)
		end
		tbMenuNavigationButtons[i]:addMouseHandlers(nil, function()
				if (not customNav) then
					if (v.sectionId == -1) then
						close_menu()
						return
					end
					if (v.sectionId ~= TB_LAST_MENU_SCREEN_OPEN) then
						TBMenu.CurrentSection:kill(true)
						TB_LAST_MENU_SCREEN_OPEN = v.sectionId
						for i, v in pairs(tbMenuNavigationButtons) do
							v.bgColor = { 0.2, 0.2, 0.2, 0 }
						end
						tbMenuNavigationButtons[i].bgColor = TB_MENU_DEFAULT_BG_COLOR
						TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
					end
				else
					if (customNavHighlight) then
						if (v.sectionId ~= selectedId and v.sectionId ~= -1) then
							selectedId = v.sectionId
							for i, v in pairs(tbMenuNavigationButtons) do
								v.bgColor = { 0.2, 0.2, 0.2, 0 }
							end
							tbMenuNavigationButtons[i].bgColor = TB_MENU_DEFAULT_BG_COLOR
						end
					end
					v.action()
				end
			end, nil)
	end
end

---Helper function to get closest menu in a specified direction
---@deprecated
---@param dir boolean
---@return MenuNavButton?
function TBMenuInternal.GetNearbyMenu(dir)
	local buttons = TBMenu:getMainNavigationButtons()
	local reordered, right = {}, {}
	local found = nil
	for _, v in pairs(buttons) do
		if (v.right) then
			table.insert(right, v)
		else
			table.insert(reordered, v)
			if (v.sectionId == TB_LAST_MENU_SCREEN_OPEN) then
				found = #reordered
			end
		end
	end
	for _, v in pairs(table.reverse(right)) do
		table.insert(reordered, v)
		if (v.sectionId == TB_LAST_MENU_SCREEN_OPEN) then
			found = #reordered
		end
	end
	if (not found) then
		return nil
	end

	local targetButton = found - 1 * (dir and 1 or -1)
	if (targetButton > #reordered) then
		targetButton = 1
	elseif (targetButton < 1) then
		targetButton = #reordered
	end
	return reordered[targetButton].sectionId
end

---Returns default navigation buttons data
---@return MenuNavButton[]
function TBMenu:getMainNavigationButtons()
	local storeMiscText = TB_STORE_DISCOUNTS and (#TB_STORE_DISCOUNTS > 0 and (TB_MENU_LOCALIZED.STORESALE1 .. TB_MENU_LOCALIZED.STORESALE2) or nil) or nil
	local buttonData = {
		{ text = TB_MENU_LOCALIZED.NAVBUTTONNEWS, sectionId = 1 },
		{ text = TB_MENU_LOCALIZED.NAVBUTTONPLAY, sectionId = 2 },
		{ text = TB_MENU_LOCALIZED.NAVBUTTONPRACTICE, sectionId = 3 },
	}
	if (TB_MENU_PLAYER_INFO.username ~= '') then
		table.insert(buttonData, { text = TB_MENU_LOCALIZED.NAVBUTTONSTORE, sectionId = 6, misctext = storeMiscText })
		table.insert(buttonData, { text = TB_MENU_LOCALIZED.NAVBUTTONMARKET, sectionId = 10 })
		table.insert(buttonData, { text = TB_MENU_LOCALIZED.MAINMENUCLANSNAME, sectionId = 9 })
	end
	if (is_mobile() == false) then
		table.insert(buttonData, { text = TB_MENU_LOCALIZED.NAVBUTTONTOOLS, sectionId = 5, right = true })
	else
		table.insert(buttonData, { text = TB_MENU_LOCALIZED.MAINMENUCLOSE, sectionId = -1, right = true })
	end
	if (TB_MENU_PLAYER_INFO.data.qi >= 20) then
		---@type MenuNavButton
		local battlePassButton = {
			text = TB_MENU_LOCALIZED.BATTLEPASSTITLE,
			sectionId = 11,
			right = not is_mobile()
		}
		if (BattlePass.UserData) then
			if (BattlePass.UserData.level == 0 and BattlePass.UserData.xp < 100 and not BattlePass.wasOpened) then
				battlePassButton.misctext = "New!"
			elseif (BattlePass.UserData.level_available > BattlePass.UserData.level) then
				battlePassButton.misctext = "!"
			end
			table.insert(buttonData, battlePassButton)
		end
	end
	return buttonData
end

---Displays main menu bottom bar buttons
---@param leftOnly ?boolean
function TBMenu:showBottomBar(leftOnly)
	local safe_x, _, safe_w, _ = get_window_safe_size()
	safe_x = math.max(safe_x, WIN_W - safe_x - safe_w)
	local barSafe_x = math.max(safe_x, 45)

	local buttonSize = 50 * TB_MENU_GLOBAL_SCALE
	if (TBMenu.BottomLeftBar == nil or TBMenu.BottomLeftBar.destroyed) then
		TBMenu.BottomLeftBar = TBMenu.MenuMain:addChild({
			pos = { barSafe_x * TB_MENU_GLOBAL_SCALE, -buttonSize * 1.4 },
			size = { 110 * TB_MENU_GLOBAL_SCALE, buttonSize }
		})
	else
		TBMenu.BottomLeftBar:kill(true)
	end

	local shopCheckExit = function()
		if (STORE_VANILLA_PREVIEW) then
			STORE_VANILLA_PREVIEW = false
			remove_hooks("storevanillapreview")
			set_option("uke", 1)
			TBMenu.HideButton:show()
			storeVanillaHolder:kill()
			STORE_VANILLA_POST = true
			start_new_game()
		end
	end
	local tbMenuBottomLeftButtonsData = { }
	if (string.len(TB_MENU_PLAYER_INFO.username) > 0) then
		table.insert(tbMenuBottomLeftButtonsData, { action = function() if (TB_MENU_SPECIAL_SCREEN_ISOPEN ~= 8) then TBMenu:showFriendsList() else Friends:quit() end end, image = TB_MENU_FRIENDS_BUTTON })
		table.insert(tbMenuBottomLeftButtonsData, { action = function() if (TB_MENU_SPECIAL_SCREEN_ISOPEN ~= 4) then TBMenu:showNotifications() else Notifications:quit() end end, image = TB_MENU_NOTIFICATIONS_BUTTON })
		table.insert(tbMenuBottomLeftButtonsData, { action = function() if (TB_MENU_SPECIAL_SCREEN_ISOPEN ~= 7) then TBMenu:showBounties() else Bounty.Quit() end end, image = TB_MENU_BOUNTY_BUTTON })
	end
	table.insert(tbMenuBottomLeftButtonsData, { action = function() usage_event("discord") open_url("https://toribash.com/discord.php") end, image = TB_MENU_DISCORD_BUTTON })

	local tbMenuBottomLeftButtons = {}
	for i, v in pairs(tbMenuBottomLeftButtonsData) do
		tbMenuBottomLeftButtons[i] = TBMenu.BottomLeftBar:addChild({
			pos = { (i - 1) * (TBMenu.BottomLeftBar.size.h + 10), 0 },
			size = { TBMenu.BottomLeftBar.size.h, TBMenu.BottomLeftBar.size.h },
			bgImage = v.image,
			imageColor = TB_MENU_DEFAULT_BG_COLOR,
			imageHoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			imagePressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
			disableUnload = true,
			interactive = true
		})
		tbMenuBottomLeftButtons[i]:addMouseHandlers(nil, function() shopCheckExit() v.action() end, nil)
	end
	if (string.len(TB_MENU_PLAYER_INFO.username) > 0) then
		local notificationsCountWidth = get_string_length("" .. (TB_MENU_NOTIFICATIONS_COUNT + TB_MENU_NOTIFICATIONS_UNREAD_COUNT + TB_MENU_QUESTS_GLOBAL_COUNT + TB_MENU_QUESTS_COUNT), FONTS.MEDIUM) * 0.9
		notificationsCountWidth = notificationsCountWidth > TBMenu.BottomLeftBar.size.h / 2 and (notificationsCountWidth > TBMenu.BottomLeftBar.size.h and TBMenu.BottomLeftBar.size.h or notificationsCountWidth) or TBMenu.BottomLeftBar.size.h / 2
		TBMenu.NotificationsCount = tbMenuBottomLeftButtons[2]:addChild({
			pos = { -notificationsCountWidth, 0 },
			size = { notificationsCountWidth, TBMenu.BottomLeftBar.size.h / 2 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = TBMenu.BottomLeftBar.size.h
		})
		TBMenu.NotificationsCount:addCustomDisplay(false, function()
				local totalCount = tostring(TB_MENU_NOTIFICATIONS_COUNT + TB_MENU_NOTIFICATIONS_UNREAD_COUNT + TB_MENU_QUESTS_GLOBAL_COUNT + TB_MENU_QUESTS_COUNT + TB_MENU_QUEST_NOTIFICATIONS)
				TBMenu.NotificationsCount:uiText(totalCount, nil, nil, FONTS.MEDIUM, nil, 0.7, 0.4)
			end)
		tbMenuBottomLeftButtons[2]:addCustomDisplay(function()
				if (TB_MENU_NOTIFICATIONS_COUNT + TB_MENU_NOTIFICATIONS_UNREAD_COUNT + TB_MENU_QUESTS_GLOBAL_COUNT + TB_MENU_QUESTS_COUNT == 0) then
					TBMenu.NotificationsCount:hide()
					TBMenu.NotificationsCount.hidden = true
				elseif (TBMenu.NotificationsCount.hidden) then
					TBMenu.NotificationsCount:show()
					TBMenu.NotificationsCount.hidden = false
				end
			end)
	end
	TBMenu.BottomLeftBar.size.w = #tbMenuBottomLeftButtonsData * (TBMenu.BottomLeftBar.size.h + 10)
	if (leftOnly) then
		return
	end

	if (TBMenu.BottomRightBar == nil or TBMenu.BottomRightBar.destroyed) then
		TBMenu.BottomRightBar = TBMenu.MenuMain:addChild({
			pos = { -(barSafe_x + 100) * TB_MENU_GLOBAL_SCALE, -buttonSize * 1.4 },
			size = { 110 * TB_MENU_GLOBAL_SCALE, buttonSize }
		})
	else
		TBMenu.BottomRightBar:kill(true)
	end

	local tbMenuBottomRightButtonsData = { }
	if (not is_mobile()) then
		table.insert(tbMenuBottomRightButtonsData, { action = function() open_menu(4) end, image = TB_MENU_QUIT_BUTTON })
	end
	table.insert(tbMenuBottomRightButtonsData, { action = function() TBMenu:showSettings() end, image = TB_MENU_SETTINGS_BUTTON })

	local tbMenuBottomRightButtons = {}
	for i,v in pairs(tbMenuBottomRightButtonsData) do
		tbMenuBottomRightButtons[i] = TBMenu.BottomRightBar:addChild({
			pos = { -i * (TBMenu.BottomRightBar.size.h + 10), 0 },
			size = { TBMenu.BottomRightBar.size.h, TBMenu.BottomRightBar.size.h },
			bgImage = v.image,
			imageColor = TB_MENU_DEFAULT_BG_COLOR,
			imageHoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			imagePressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
			disableUnload = true,
			interactive = true
		})
		tbMenuBottomRightButtons[i]:addMouseHandlers(nil, function() shopCheckExit() v.action() end, nil)
	end

	local statusMessage = TBMenu.MenuMain:addChild({
		pos = { -math.max(safe_x, 10) - 300, -25 },
		size = { 300, 25 },
		uiColor = { 0, 0, 0, 0.7 }
	})
	statusMessage:addCustomDisplay(true, function()
			local downloads = #get_downloads() or 0
			if (downloads > 0) then
				statusMessage:uiText(TB_MENU_LOCALIZED.DOWNLOADINGFILESWAIT, nil, nil, 4, RIGHTMID, 0.5)
			else
				statusMessage:uiText("v" .. TORIBASH_VERSION .. (BETA_VERSION or '') .. "." .. BUILD_VERSION, nil, nil, 4, RIGHTMID, 0.5)
			end
		end)
end

---Plays main menu section switch animation
---@deprecated
function TBMenu:playMenuSwitchAnimation()
	if (UIElement.lightUIMode) then return end
	local speedMod = get_option("framerate") == 30 and 2 or 1
	local currentSectionMover = UIElement:new({
		parent = TBMenu.MenuMain,
		pos = { -TBMenu.MenuMain.size.w + TBMenu.CurrentSection.shift.x, TBMenu.CurrentSection.shift.y },
		size = { TBMenu.CurrentSection.size.w, TBMenu.CurrentSection.size.h }
	})
	for i,v in pairs(TBMenu.CurrentSection.child) do
		table.insert(currentSectionMover.child, v)
		v.parent = currentSectionMover
	end
	TBMenu.CurrentSection.child = {}
	local rad = math.pi / 3
	currentSectionMover:addCustomDisplay(true, function()
			if (-currentSectionMover.pos.x >= currentSectionMover.size.w) then
				currentSectionMover:kill()
			end
			currentSectionMover:moveTo(-WIN_W / 10 * math.sin(rad) * speedMod, nil, true)
		end)

	TBMenu.CurrentSection:moveTo(WIN_W)
	TBMenu.CurrentSection:addCustomDisplay(true, function()
			TBMenu.CurrentSection:moveTo(-WIN_W / 10 * math.sin(rad) * speedMod, nil, true)
			rad2 = rad + math.pi / 50
			if (TBMenu.CurrentSection.shift.x <= 75 * TB_MENU_GLOBAL_SCALE) then
				TBMenu.CurrentSection:moveTo(75 * TB_MENU_GLOBAL_SCALE)
				TBMenu.CurrentSection:addCustomDisplay(true, function() end)
			end
	end)
end

---Prepares and displays Main Menu. \
---Executing this with `noload` enabled will only prepare main menu root elements without opening last active menu screen.
---@param noload ?boolean
function TBMenu:showMain(noload)
	TBMenu.MenuMain = UIElement:new({
		globalid = TB_MENU_MAIN_GLOBALID,
		pos = { 0, 0 },
		size = { WIN_W, WIN_H },
		uiColor = TB_MENU_UI_TEXT_COLOR,
		uiShadowColor = TB_MENU_UI_TEXT_SHADOW_COLOR,
		interactive = is_mobile()
	})
	TBMenu.MenuMain:addMouseUpHandler(close_menu)
	TBMenu.CreateCurrentSectionView()
	local tbMenuBackground = TBMenu.MenuMain:addChild({
		pos = { 0, - WIN_H * 2 },
		size = { WIN_W, WIN_H * 3 },
		bgColor = { 0, 0, 0, 0 }
	})
	if (enable_blur() == 0) then
		tbMenuBackground.bgColor[4] = 0.1
	else
		BLURENABLED = true
	end
	TBMenu.HideButton = TBMenu.MenuMain:addChild({
		pos = { TBMenu.MenuMain.size.w / 2 - 32, -74 },
		size = { 64, 64 },
		shapeType = ROUNDED,
		rounded = 32,
		interactive = true,
		bgColor = { 0, 0, 0, 0.01 },
		hoverColor = { 0, 0, 0, 0.4 },
		pressedColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		bgImage = "../textures/menu/general/buttons/arrowbot.tga"
	})
	TBMenu.HideButton.state = 0
	TBMenu.HideButton:addMouseUpHandler(function()
			if (TBMenu.HideButton.state == 0) then
				TBMenu.HideButton.state = -1
				TBMenu.HideButton.progress = -math.pi/6
				disable_blur()
			elseif (TBMenu.HideButton.state == 2) then
				TBMenu.HideButton.state = 1
				TBMenu.HideButton.progress = math.pi / 2
			end
		end)
	TBMenu.HideButton:addCustomDisplay(false, function()
			if (TBMenu.HideButton.state == -1) then
				TBMenu.HideButton.progress = TBMenu.HideButton.progress + math.pi / 40
				TBMenu.MenuMain:moveTo(nil, TBMenu.MenuMain.pos.y + (WIN_H / 15) * math.sin(TBMenu.HideButton.progress))
				TBMenu.HideButton:moveTo(nil, -TBMenu.MenuMain.pos.y - 74)
				if (not BLURENABLED) then
					tbMenuBackground.bgColor[4] = tbMenuBackground.bgColor[4] - (0.1 / 15) * math.sin(TBMenu.HideButton.progress)
				end
				if (TBMenu.MenuMain.pos.y >= WIN_H) then
					for i = 1, 3 do
						TBMenu.HideButton:updateImage("../textures/menu/general/buttons/arrowtop.tga")
					end
					TBMenu.MenuMain:moveTo(nil, WIN_H)
					TBMenu.HideButton:moveTo(nil, -TBMenu.MenuMain.pos.y - 74)
					TBMenu.HideButton.state = 2
					tbMenuBackground.bgColor[4] = 0
				end
			elseif (TBMenu.HideButton.state == 1) then
				TBMenu.HideButton.progress = TBMenu.HideButton.progress + math.pi / 50
				TBMenu.MenuMain:moveTo(nil, TBMenu.MenuMain.pos.y - (WIN_H / 15) * math.sin(TBMenu.HideButton.progress))
				TBMenu.HideButton:moveTo(nil, -TBMenu.MenuMain.pos.y - 74)
				if (not BLURENABLED) then
					tbMenuBackground.bgColor[4] = tbMenuBackground.bgColor[4] + (0.1 / 15) * math.sin(TBMenu.HideButton.progress)
				end
				if (TBMenu.MenuMain.pos.y <= 0) then
					for i = 1, 3 do
						TBMenu.HideButton:updateImage("../textures/menu/general/buttons/arrowbot.tga")
					end
					TBMenu.MenuMain:moveTo(nil, 0)
					TBMenu.HideButton:moveTo(nil, -TBMenu.MenuMain.pos.y - 74)
					TBMenu.HideButton.state = 0
					if (enable_blur() == 0) then
						tbMenuBackground.bgColor[4] = 0.1
					end
				end
			end
		end, false)
	local splatLeftImg = TB_MENU_BLOODSPLATTER_LEFT
	local splatCustom = false
	local customLogo = Files:open("../custom/" .. TB_MENU_PLAYER_INFO.username .. "/splatt1.tga")
	if (customLogo.data) then
		splatLeftImg = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/splatt1.tga"
		splatCustom = true
		customLogo:close()
	end
	local splatRes = (WIN_H - 320) * TB_MENU_GLOBAL_SCALE
	local splatLeft = TBMenu.MenuMain:addChild({
		pos = { TBMenu.CurrentSection.shift.x - 60 * TB_MENU_GLOBAL_SCALE, TBMenu.CurrentSection.shift.y },
		size = { splatRes, splatRes },
		bgImage = splatLeftImg,
		disableUnload = true,
		imageColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local splatRight = TBMenu.MenuMain:addChild({
		pos = { TBMenu.CurrentSection.shift.x + TBMenu.CurrentSection.size.w + 60 * TB_MENU_GLOBAL_SCALE - splatRes, splatLeft.shift.y },
		size = { splatRes, splatRes },
		bgImage = splatCustom and splatLeftImg or TB_MENU_BLOODSPLATTER_RIGHT,
		disableUnload = true,
		imageColor = TB_MENU_DEFAULT_BG_COLOR
	})

	-- People don't really like this one, disable unless it can be somehow improved
	--[[local menuNavigationScroll = UIElement:new({
		parent = TBMenu.MenuMain,
		pos = { 0, 0 },
		size = { 0, 0 },
		interactive = true
	})
	menuNavigationScroll.scrollEnabled = true
	menuNavigationScroll.lastTime = 0
	menuNavigationScroll:addCustomDisplay(true, function() end)
	menuNavigationScroll:addMouseHandlers(function(s)
			local clocktime = math.floor(os.clock_real() * 2 + 0.5) / 2
			-- Mouse scroll can trigger multiple times per frame for some reason, we don't want that
			if (menuNavigationScroll.lastTime == clocktime or TB_MENU_SPECIAL_SCREEN_ISOPEN ~= 0) then
				return
			end
			local id = TBMenuInternal.GetNearbyMenu(s == 5)
			if (id) then
				TB_LAST_MENU_SCREEN_OPEN = id
				--TBMenu:playMenuSwitchAnimation()
				TBMenu:clearNavSection()
				TBMenu:showNavigationBar()
				TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
				menuNavigationScroll.lastTime = clocktime
			end
		end)]]

	TBMenu:showGameLogo()
	TBMenu:showUserBar()
	TBMenu:showNavigationBar()
	TBMenu:showBottomBar()
	if (not noload) then
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
end

---Displays login error. Typically used to block large UI buttons that are only available for logged in users.
---@param viewElement UIElement
---@param actionStr string
function TBMenu:showLoginError(viewElement, actionStr)
	viewElement:kill(true)
	local background = UIElement:new({
		parent = viewElement,
		pos = { 5, 0 },
		size = { viewElement.size.w - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:addBottomBloodSmudge(background, 1)
	local errorMessage = UIElement:new({
		parent = background,
		pos = { background.size.w / 4, 0 },
		size = { background.size.w / 2, background.size.h / 2 - 10 }
	})
	errorMessage:addCustomDisplay(true, function()
			errorMessage:uiText(TB_MENU_LOCALIZED.MAINMENUSIGNINERROR .. " " .. actionStr, nil, nil, nil, CENTERBOT)
		end)
	local loginButton = UIElement:new({
		parent = background,
		pos = { background.size.w / 4, background.size.h / 2 + 10 },
		size = { background.size.w / 2, background.size.h / 5 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	loginButton:addCustomDisplay(false, function()
			loginButton:uiText("Log in / Create account")
		end)
	loginButton:addMouseHandlers(nil, function()
			open_menu(18)
		end)
end

---@class UIDropdown : UIElement
---@field listElements UIElement[]
---@field listHolder UIElement
---@field listToReload UIElement
---@field selectedElement UIElement
---@field selectItem function
---@field selectedId function
---@field displayOptions DropdownElement[]

---@class DropdownElement
---@field default boolean --Legacy parameter, use `hidden` instead
---@field hidden boolean
---@field text string
---@field action function
---@field element UIElement
---@field itemId integer
---@field selected ?boolean

---@class DropdownSettings
---@field fontid FontId
---@field scale number
---@field alignment UIElementTextAlign
---@field orientation UIElementTextAlign Deprecated, use `alignment` instead. Will be removed with future releases.
---@field uppercase boolean

---@param holderElement UIElement
---@param listElements DropdownElement[]
---@param elementHeight number
---@param maxHeight ?number
---@param selectedItem ?integer|DropdownElement
---@param textSettings ?DropdownSettings
---@param listTextSettings ?DropdownSettings
---@param keepFocus ?boolean
---@param noOverlaying ?boolean
---@param forceDisplayAbove ?boolean
---@return UIDropdown
function TBMenu:spawnDropdown(holderElement, listElements, elementHeight, maxHeight, selectedItem, textSettings, listTextSettings, keepFocus, noOverlaying, forceDisplayAbove)
	local listElementsDisplay = {}
	for _, v in pairs(listElements) do
		if (not v.default and not v.hidden) then
			table.insert(listElementsDisplay, v)
		end
	end

	local maxHeight = maxHeight or #listElementsDisplay * elementHeight + 6
	if (maxHeight > #listElementsDisplay * elementHeight + 6) then
		maxHeight = #listElementsDisplay * elementHeight + 6
	end

	if (selectedItem == nil) then
		for i, v in pairs(listElements) do
			if (v.selected) then
				if (selectedItem == nil) then
					selectedItem = listElements[i]
				end
				v.selected = nil
			end
		end
		selectedItem = selectedItem or listElements[1]
	elseif (type(selectedItem) ~= "table") then
		selectedItem = listElements[selectedItem] or listElements[1]
	end

	local textSettings = textSettings or {}
	textSettings.fontid = textSettings.fontid or 4
	textSettings.scale = textSettings.scale or 1
	textSettings.alignment = textSettings.alignment or textSettings.orientation or LEFTMID
	textSettings.uppercase = textSettings.uppercase == nil and true or textSettings.uppercase

	local listTextSettings = listTextSettings or {}
	listTextSettings.fontid = listTextSettings.fontid or 4
	listTextSettings.scale = listTextSettings.scale or 1
	listTextSettings.alignment = listTextSettings.alignment or listTextSettings.orientation or CENTERMID
	listTextSettings.uppercase = listTextSettings.uppercase == nil and true or listTextSettings.uppercase

	---@type UIDropdown
	---@diagnostic disable-next-line: assign-type-mismatch
	local overlay = holderElement:addChild({
		size = { WIN_W, WIN_H },
		interactive = not keepFocus
	})
	local dropdownViewBackdrop = overlay:addChild({
		size = { holderElement.size.w, maxHeight },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = holderElement.shapeType,
		rounded = holderElement.rounded
	})
	local dropdownView = dropdownViewBackdrop:addChild({
		shift = { 1, 1 },
		bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	overlay:addMouseHandlers(function(s)
			if (s >= 4) then
				overlay:hide(true)
			end
		end, function()
			overlay:hide(true)
		end)

	local function fixPosition()
		overlay:moveTo(-overlay.parent.size.w - overlay.parent.pos.x, -overlay.parent.size.h - overlay.parent.pos.y)
		overlay:updatePos()

		local addedShift = noOverlaying and elementHeight or 0
		local dropdownPosY = holderElement.pos.y + addedShift
		if (forceDisplayAbove or (holderElement.pos.y + addedShift + maxHeight > WIN_H - 25)) then
			if (holderElement.pos.y - maxHeight < 25) then
				dropdownPosY = WIN_H - 25 - maxHeight - addedShift
			else
				dropdownPosY = holderElement.pos.y - maxHeight
			end
		end
		dropdownViewBackdrop:moveTo(holderElement.pos.x, dropdownPosY)
	end

	local selectedElement = UIElement:new({
		parent = holderElement,
		pos = { 0, 0 },
		size = { holderElement.size.w, holderElement.size.h },
		interactive = true,
		bgColor = holderElement.bgColor or TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = holderElement.hoverColor or TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = holderElement.pressedColor or TB_MENU_DEFAULT_BG_COLOR,
		inactiveColor = holderElement.inactiveColor or TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS,
		shapeType = holderElement.shapeType,
		rounded = holderElement.rounded
	})
	local selectedElementText = UIElement:new({
		parent = selectedElement,
		pos = { 10, 2 },
		size = { selectedElement.size.w - selectedElement.size.h - 10, selectedElement.size.h - 4 }
	})
	selectedElementText:addAdaptedText(false, textSettings.uppercase and selectedItem.text:upper() or selectedItem.text, nil, nil, textSettings.fontid, textSettings.alignment, textSettings.scale)
	local selectedElementArrow = selectedElement:addChild({
		pos = { -selectedElement.size.h, 0 },
		size = { selectedElement.size.h, selectedElement.size.h },
		bgImage = "../textures/menu/general/buttons/arrowbotwhite.tga"
	})

	local toReload, topBar, botBar, listingHolder
	if (#listElementsDisplay * elementHeight > maxHeight) then
		toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(dropdownView:addChild({ shift = { 0, 2 } }), elementHeight, elementHeight, 15, TB_MENU_DEFAULT_LIGHTER_COLOR)
		local topEdge = topBar:addChild({
			pos = { 0, -topBar.size.h - (dropdownView.rounded or 0) },
			size = { topBar.size.w, topBar.size.h * 1.5 },
			bgColor = topBar.bgColor,
			innerShadow = elementHeight / 2,
			shadowColor = { holderElement.bgColor, { 0, 0, 0, 0 } },
			shapeType = dropdownView.shapeType,
			rounded = dropdownView.rounded
		})
		local botEdge = botBar:addChild({
			pos = { 0, -botBar.size.h * 1.5 + (dropdownView.rounded or 0) },
			size = { botBar.size.w, botBar.size.h * 1.5 },
			bgColor = botBar.bgColor,
			innerShadow = elementHeight / 2,
			shadowColor = { { 0, 0, 0, 0 }, holderElement.bgColor },
			shapeType = dropdownView.shapeType,
			rounded = dropdownView.rounded
		})
	else
		listingHolder = dropdownView:addChild({ shift = { 0, 2 } })
	end

	local selectedItemId = 1

	---Marks an item as selected and executes its on submit action
	---@param item DropdownElement
	overlay.selectItem = function(item)
			selectedElementText:addAdaptedText(false, listTextSettings.uppercase and item.text:upper() or item.text, nil, nil, textSettings.fontid, textSettings.alignment, textSettings.scale)
			selectedElement:show()
			if (selectedItem == item) then
				return
			end
			if (selectedItem and selectedItem.element) then
				selectedItem.element.bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			end
			item.element.bgColor = TB_MENU_DEFAULT_BG_COLOR
			selectedItem = item
			selectedItemId = item.itemId
			if (selectedItem.action) then
				selectedItem.action()
			end
		end

	local listElements = {}
	for i, v in pairs(listElementsDisplay) do
		local elementHolder = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, elementHolder)
		local element = elementHolder:addChild({
			shift = { 3, 1 },
			interactive = true,
			clickThrough = toReload ~= nil,
			hoverThrough = toReload ~= nil,
			bgColor = selectedItem == v and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_LIGHTER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS,
			shapeType = holderElement.shapeType,
			rounded = holderElement.rounded
		})
		v.element = element
		v.itemId = i
		if (v.locked) then
			element.uiColor = table.clone(UICOLORBLACK)
			element:deactivate(true)
		end
		if (selectedItem == v) then
			selectedItemId = i
		end
		element:addChild({ shift = { 10, 1 }}):addAdaptedText(false, listTextSettings.uppercase and v.text:upper() or v.text, nil, nil, listTextSettings.fontid, listTextSettings.alignment, listTextSettings.scale)
		element:addMouseHandlers(nil, function()
				overlay:hide(true)
				overlay.selectItem(v)
			end)
	end

	if (#listElements * elementHeight > maxHeight) then
		for _, v in pairs(listElements) do
			v:hide(true)
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = scrollBar
		local targetShift = { (scrollBar.parent.size.h - scrollBar.size.h) * ((selectedItemId - 1) / (#listElementsDisplay - 1)) }
		scrollBar:makeScrollBar(listingHolder, listElements, toReload, targetShift)

		overlay.listElements = listElements
		overlay.listHolder = listingHolder
		overlay.listToReload = toReload

		---Hack to register overlay.listHolder.scrollBar for EmmyLua
		---@type UIElement
		overlay.listHolder.scrollBar = overlay.listHolder.scrollBar
	end

	selectedElement:addMouseHandlers(nil, function()
			fixPosition()
			overlay:show(true)
			if (overlay.listToReload ~= nil) then
				overlay.listToReload:reload()
			end
		end)
	overlay:hide(true)

	overlay.displayOptions = listElementsDisplay
	overlay.selectedElement = selectedElement
	overlay.selectedId = function() return selectedItemId end
	return overlay
end

---Spawns default menu scroll bar
---@param holderElement UIElement
---@param numElements integer
---@param elementSize number
---@param orientation ?UIElementScrollMode
---@return UIElement
function TBMenu:spawnScrollBar(holderElement, numElements, elementSize, orientation)
	local orientation = orientation or SCROLL_VERTICAL
	local scrollActive = true
	local scrollScale
	if (orientation == SCROLL_VERTICAL) then
		scrollScale = numElements > 0 and (holderElement.size.h) / (numElements * elementSize) or holderElement.size.h
	else
		scrollScale = numElements > 0 and (holderElement.size.w) / (numElements * elementSize) or holderElement.size.w
	end

	if (scrollScale >= 1) then
		scrollScale = 1
		scrollActive = false
	elseif (scrollScale < 0.1) then
		scrollScale = 0.1
	end

	---Hack to register scrollBG as a valid holderElement field
	---@type UIElement
	holderElement.scrollBG = holderElement.scrollBG

	local scrollBackground, scrollView
	if (orientation == SCROLL_VERTICAL) then
		scrollBackground = holderElement.parent:addChild({
			pos = { -holderElement.parent.size.w + holderElement.size.w, 0 },
			size = { holderElement.parent.size.w - holderElement.size.w, holderElement.size.h },
			bgColor = holderElement.scrollBG and holderElement.scrollBG.bgColor
		})
		scrollView = holderElement.parent:addChild({
			pos = { -(holderElement.parent.size.w - holderElement.size.w) * 0.75, 5 },
			size = { (holderElement.parent.size.w - holderElement.size.w) / 2, holderElement.size.h - 10 }
		})
	else
		scrollBackground = holderElement.parent:addChild({
			pos = { 0, -holderElement.parent.size.h + holderElement.size.h },
			size = { holderElement.size.w, holderElement.parent.size.h - holderElement.size.h },
			bgColor = holderElement.scrollBG and holderElement.scrollBG.bgColor
		})
		scrollView = holderElement.parent:addChild({
			pos = { 5, -(holderElement.parent.size.h - holderElement.size.h) * 0.75 },
			size = { holderElement.size.w - 10, (holderElement.parent.size.h - holderElement.size.h) / 2 }
		})
	end
	local scrollBar = scrollView:addChild({
		size = orientation == SCROLL_VERTICAL and { scrollView.size.w, scrollView.size.h * scrollScale } or { scrollView.size.w * scrollScale, scrollView.size.h },
		interactive = scrollActive,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.6 },
		scrollEnabled = true,
		shapeType = ROUNDED,
		rounded = 10
	})
	scrollBar.holder = scrollBackground
	return scrollBar
end

-- Draws quarter disks that cover element's corners for a fake rounded effect. Designed to use with images on single color backgrounds.
--
-- *To make regular UIElements rounded, use `shapeType` and `rounded` UIElementOptions parameters.*
---@param e UIElement UIElement object that we'll be applying the effect to
---@param color? Color
---@param rounding? number[]|number
---@return nil
function TBMenu:addOuterRounding(e, color, rounding)
	if (UIElement.lightUIMode) then return end

	local color = color or TB_MENU_DEFAULT_BG_COLOR
	local rounding = rounding or 5
	if (type(rounding) ~= "table") then
		rounding = { rounding }
	end
	rounding[2] = rounding[2] or rounding[1]
	rounding[3] = rounding[3] or rounding[1]
	rounding[4] = rounding[4] or rounding[1]

	local roundingWidth = {
		rounding[1] * 1.4,
		rounding[2] * 1.4,
		rounding[3] * 1.4,
		rounding[4] * 1.4
	}
	local roundingSlices = {
		math.min(rounding[1] * 4, 50),
		math.min(rounding[2] * 4, 50),
		math.min(rounding[3] * 4, 50),
		math.min(rounding[4] * 4, 50)
	}

	e:addChild({}):addCustomDisplay(true, function()
			set_color(unpack(color))
			draw_disk(e.pos.x + rounding[1], e.pos.y + rounding[1], rounding[1], roundingWidth[1], roundingSlices[1], 1, -180, 90, 0)
			draw_disk(e.pos.x + e.size.w - rounding[2], e.pos.y + rounding[2], rounding[2], roundingWidth[2], roundingSlices[2], 1, 90, 90, 0)
			draw_disk(e.pos.x + rounding[3], e.pos.y + e.size.h - rounding[3], rounding[3], roundingWidth[3], roundingSlices[3], 1, 0, -90, 0)
			draw_disk(e.pos.x + e.size.w - rounding[4], e.pos.y + e.size.h - rounding[4], rounding[4], roundingWidth[4], roundingSlices[4], 1, 0, 90, 0)
		end)
end

---Generic function to generate pagination data
---@param totalPages integer
---@param maxPages integer
---@param currentPage integer
---@return table
function TBMenu:generatePaginationData(totalPages, maxPages, currentPage)
	local pagesButtonsPre, pagesButtons = {}, {}
	local pagesNavArr = { 10, 50, 100, 500 }

	table.insert(pagesButtonsPre, { v = 1 })
	if (totalPages > 1) then
		table.insert(pagesButtonsPre, { v = totalPages })
	end
	for i = math.max(1, currentPage - 1), math.min(currentPage + 1, totalPages) do
		table.insert(pagesButtonsPre, { v = i })
	end
	for i,v in pairs(pagesNavArr) do
		if (currentPage - v > 1) then
			table.insert(pagesButtonsPre, { v = currentPage - v })
		end
		if (currentPage + v < totalPages) then
			table.insert(pagesButtonsPre, { v = currentPage + v })
		end
	end

	local removeDuplicates = function(pages)
		local sorted = table.qsort(pages, 'v')
		for i = #sorted, 2, -1 do
			if (sorted[i].v == sorted[i - 1].v) then
				table.remove(sorted, i)
			end
		end
		return sorted
	end

	local sorted = removeDuplicates(pagesButtonsPre)
	if (#sorted < maxPages) then
		local limit = 2
		while (#sorted < totalPages) do
			table.insert(sorted, { v = math.min(currentPage + limit, totalPages) })
			table.insert(sorted, { v = math.max(1, currentPage - limit) })
			local new = removeDuplicates(sorted)
			for i = 1, #sorted do sorted[i] = nil end
			for i = 1, #new do sorted[i] = new[i] end

			limit = limit + 1
			if (#sorted >= maxPages or limit > totalPages) then
				break
			end
		end
	end

	local loops = 0
	while (#sorted > maxPages) do
		local targetId
		for i,v in pairs(sorted) do
			if (v.v == currentPage) then
				targetId = i
				break
			end
		end
		local otherId = math.ceil(maxPages / 4)
		if (targetId + otherId < totalPages) then
			table.remove(sorted, targetId + otherId)
		end
		if (#sorted == maxPages) then
			break
		end
		if (targetId - otherId > 1) then
			table.remove(sorted, targetId - otherId)
		end
		loops = loops + 1
		if (loops > 100) then
			break
		end
	end

	for _, v in pairs(sorted) do
		table.insert(pagesButtons, v.v)
	end

	return pagesButtons
end

---@class UILoadingMark : UIElement
---@field textView ?UIElement

---Displays a generic message with a spinning wheel element within a specified viewport
---@param element UIElement
---@param message ?string
---@param size ?number
---@return UILoadingMark
function TBMenu:displayLoadingMark(element, message, size)
	local size = size or 20
	---@type UILoadingMark
	---@diagnostic disable-next-line: assign-type-mismatch
	local loadMark = element:addChild({})
	local grow, rotate = 0, 0
	loadMark:addCustomDisplay(true, function()
			set_color(unpack(loadMark.uiColor or UICOLORWHITE))
			draw_disk(loadMark.pos.x + loadMark.size.w / 2, loadMark.pos.y + loadMark.size.h / 2 - (message and 40 or 0), size * 0.6, size, 20, 1, rotate, grow, 0)
			grow = grow + 4
			rotate = rotate + 2
			if (grow >= 360) then
				grow = -360
			end
		end)
	if (message) then
		local textView = loadMark:addChild({
			pos = { 10, loadMark.size.h / 2 },
			size = { loadMark.size.w - 20, loadMark.size.h }
		})
		textView:addAdaptedText(true, message, nil, nil, nil, CENTER)
		loadMark.textView = textView
	end
	return loadMark
end

---Generic function to display a small spinning wheel with text in a specified viewport
---@param viewElement UIElement
---@param message string
---@param fontid ?FontId
---@param loadScale ?number
---@param fontScale ?number
function TBMenu:displayLoadingMarkSmall(viewElement, message, fontid, loadScale, fontScale)
	local fontid = fontid or FONTS.MEDIUM
	local loadScale = loadScale or 26
	if (loadScale > viewElement.size.h) then
		loadScale = viewElement.size.h
	end
	local textView = viewElement:addChild({
		pos = { loadScale * 0.8, 0 },
		size = { viewElement.size.w - loadScale * 1.2, viewElement.size.h }
	})
	textView:addAdaptedText(false, message, loadScale * 0.7, nil, fontid, nil, fontScale)
	local fontid = textView.textFont
	local posX = get_string_length(textView.dispstr[1], fontid) * textView.textScale
	local loadElement = textView:addChild({
		pos = { (textView.size.w - posX - loadScale * 1.2) / 2, (textView.size.h - loadScale) / 2 },
		size = { loadScale, loadScale }
	})
	local grow, rotate = 0, 0
	loadElement:addCustomDisplay(true, function()
			set_color(unpack(loadElement.uiColor or UICOLORWHITE))
			draw_disk(loadElement.pos.x + loadElement.size.w / 2, loadElement.pos.y + loadElement.size.h / 2, loadScale / 3, loadScale / 2, 360, 1, rotate, grow, 0)
			grow = grow + 4
			rotate = rotate + 2
			if (grow >= 360) then
				grow = -360
			end
		end)
end

---@class MenuTextImageOptions
---@field useUiColor boolean
---@field textLeft boolean
---@field maxTextScale number

---Generic method to display a text string with an image on the side
---@param viewElement UIElement
---@param text string
---@param fontid FontId
---@param imgScale? number
---@param imgWhite string
---@param textImageOptions? MenuTextImageOptions
---@param left? boolean Deprecated, use `textImageOptions.textLeft` instead
function TBMenu:showTextWithImage(viewElement, text, fontid, imgScale, imgWhite, textImageOptions, left)
	local textImageOptions = type(textImageOptions) == "table" and textImageOptions or {
		useUiColor = textImageOptions,
		textLeft = left
	}
	local imgScale = math.min(viewElement.size.h, imgScale or 26)
	local textView = viewElement:addChild({
		pos = { imgScale * 0.8, 0 },
		size = { viewElement.size.w - imgScale * 1.15, viewElement.size.h }
	})
	textView:addAdaptedText(true, text, textImageOptions.textLeft and imgScale * 0.7 or -imgScale * 0.7, nil, fontid, nil, textImageOptions.maxTextScale or 1, nil, fontid == FONTS.BIG and 0.5 or 1)

	local fontid = textView.textFont
	local textScale = textView.textScale
	local posX = 0
	for _, v in pairs(textView.dispstr) do
		local lineWidth = get_string_length(v, fontid)
		if (lineWidth > posX) then
			posX = lineWidth
		end
	end
	posX = posX * textScale
	local imageElement = textView:addChild({
		pos = { (textImageOptions.textLeft and (-textView.size.w - (posX + imgScale)) or (textView.size.w + (posX - imgScale))) / 2, (textView.size.h - imgScale) / 2 },
		size = { imgScale, imgScale },
		bgImage = imgWhite,
		imageColor = textImageOptions.useUiColor and viewElement.uiColor or { 1, 1, 1, 1 }
	})
end

---Shorthand function to display text with "external" icon nearby \
---@see TBMenu.showTextWithImage
---@param viewElement UIElement
---@param text string
---@param useUiColor ?boolean
function TBMenu:showTextExternal(viewElement, text, useUiColor)
	TBMenu:showTextWithImage(viewElement, text, FONTS.MEDIUM, 26, "../textures/menu/general/buttons/external.tga", { useUiColor = useUiColor or false })
end

---Generic method to display a question mark with a help popup on mouse hover over the specified object \
---@see TBMenu.displayPopup
---@param element UIElement
---@param message string
---@param forceManualPosCheck ?boolean
---@param noMark ?boolean
---@param maxHeight ?number
---@return UIElement
function TBMenu:displayHelpPopup(element, message, forceManualPosCheck, noMark, maxHeight)
	local messageElement = element:addChild({
		size = { WIN_W / 3, maxHeight or WIN_H / 7 },
		bgColor = { 0, 0, 0, 0.8 },
		uiColor = UICOLORWHITE,
		shapeType = ROUNDED,
		rounded = 5
	})

	local safe_x, safe_y, safe_w, safe_h = get_window_safe_size()
	safe_x = math.max(safe_x, WIN_W - safe_x - safe_w)
	safe_y = math.max(safe_y, WIN_H - safe_y - safe_h)

	if (not forceManualPosCheck) then
		if (messageElement.pos.x < 0) then
			messageElement:moveTo(messageElement:getLocalPos(10, 0).x)
		end
		if (messageElement.pos.y < 0) then
			messageElement:moveTo(nil, messageElement:getLocalPos(0, 10).y)
		end
		if (messageElement.pos.x + messageElement.size.w > WIN_W - safe_x) then
			messageElement:moveTo((WIN_W - messageElement.pos.x - messageElement.size.w) - math.max(safe_x, 10), nil, true)
		end
		if (messageElement.pos.y + messageElement.size.h > WIN_H - safe_y) then
			messageElement:moveTo(nil, (WIN_H - messageElement.pos.y - messageElement.size.h) - math.max(safe_y, 10), true)
		end
	end

	local messageText = messageElement:addChild({
		shift = { 10, 5 }
	})
	messageText:addAdaptedText(true, message, nil, nil, 4, nil, 0.7)
	local textWidth = get_string_length(messageText.dispstr[1], messageText.textFont) * messageText.textScale
	for i = 2, #messageText.dispstr do
		textWidth = math.max(textWidth, get_string_length(messageText.dispstr[i], messageText.textFont) * messageText.textScale)
	end
	if (textWidth + 20 < messageText.size.w) then
		messageElement.size.w = textWidth + 40
		messageText.size.w = textWidth + 20
	end
	local textHeight = getFontMod(messageText.textFont) * 10 * messageText.textScale * #messageText.dispstr
	if (textHeight + 10 < messageText.size.h) then
		messageElement.size.h = textHeight + 20
		messageText.size.h = textHeight + 10
	end
	messageElement:hide(true)

	local popupShown = false
	if (forceManualPosCheck) then
		element:addCustomDisplay(false, function()
				if (not messageElement or messageElement.destroyed) then return end
				if (not TB_MENU_POPUPS_DISABLED and MOUSE_X > element.pos.x and MOUSE_Y > element.pos.y and MOUSE_X < element.pos.x + element.size.w and MOUSE_Y < element.pos.y + element.size.h) then
					element.hoverState = element.hoverState == nil and BTN_HVR or element.hoverState
					messageElement.hoverClock = messageElement.hoverClock or UIElement.clock
					if (not popupShown and UIElement.clock - messageElement.hoverClock >= 0.3) then
						messageElement:show(true)
						popupShown = true
					end
				elseif (popupShown) then
					messageElement.hoverClock = nil
					messageElement:hide(true)
					popupShown = false
				end
			end, true)
	else
		element:addCustomDisplay(false, function()
				if (not messageElement or messageElement.destroyed) then return end
				if (element.hoverState >= BTN_HVR) then
					if (not popupShown and UIElement.clock - element.hoverClock >= 0.3) then
						messageElement:show(true)
						popupShown = true
					end
				elseif (popupShown) then
					if (element.hoverState == BTN_NONE) then
						messageElement:hide(true)
						popupShown = false
					end
				end
			end, true)
	end

	if (not noMark) then
		element:addChild({}):addAdaptedText(true, "?", nil, nil, nil, nil, 0.7)
	end

	return messageElement
end

---Generic method to display a text popup on mouse hover over the specified object
---@param element UIElement
---@param message string
---@param forceManualPosCheck ?boolean
---@param maxHeight ?number
---@return UIElement
function TBMenu:displayPopup(element, message, forceManualPosCheck, maxHeight)
	return TBMenu:displayHelpPopup(element, message, forceManualPosCheck, true, maxHeight)
end

---@class SliderSettings
---@field boundParent UIElement
---@field maxValue number
---@field minValue number
---@field maxValueDisp number|string Display override for max value
---@field minValueDisp number|string Display override for min value
---@field decimal integer
---@field isBoolean boolean
---@field darkerMode boolean
---@field displayName string
---@field textWidth number
---@field sliderRadius number

---@class UISlider : UIElement
---@field label UIElement
---@field settings SliderSettings
---@field lastVal number|nil
---@field pressedPos Vector2
---@field setValue function

---Spawns a generic slider with callbacks
---@param parent UIElement
---@param rect ?Rect
---@param value ?number
---@param settings ?SliderSettings
---@param sliderFunc ?function
---@param onMouseDown ?function
---@param onMouseUp ?function
---@return UISlider
function TBMenu:spawnSlider2(parent, rect, value, settings, sliderFunc, onMouseDown, onMouseUp)
	local rect = rect or {}
	rect.x = rect.x or 0
	rect.y = rect.y or 0
	rect.w = rect.w or parent.size.w - rect.x * 2
	rect.h = rect.h or parent.size.h - rect.y * 2

	local settings = settings or {}
	settings.maxValue = settings.maxValue or 1
	settings.minValue = settings.minValue or 0
	settings.maxValueDisp = settings.maxValueDisp or settings.maxValue
	settings.minValueDisp = settings.minValueDisp or settings.minValue
	settings.decimal = settings.decimal or 0
	settings.textWidth = settings.textWidth or rect.w / 8
	settings.sliderRadius = settings.sliderRadius or math.min(20, parent.size.h)

	local value = value or settings.minValue

	local minText = parent:addChild({
		pos = { rect.x, rect.y },
		size = { settings.textWidth, rect.h }
	})
	minText:addAdaptedText(true, settings.minValueDisp .. "", nil, nil, 4, RIGHTMID, 0.7)
	local maxText = parent:addChild({
		pos = { -settings.textWidth - rect.x, rect.y },
		size = { settings.textWidth, rect.h }
	})
	maxText:addAdaptedText(true, settings.maxValueDisp .. "", nil, nil, 4, LEFTMID, 0.7)

	if (settings.displayName) then
		local displayNameText = parent:addChild({
			pos = { rect.x + rect.w / 3, rect.y },
			size = { rect.w / 3, rect.h / 2 }
		})
		displayNameText:addAdaptedText(true, settings.displayName, nil, nil, 4, nil, 0.7)
	end

	local sliderBG = parent:addChild({
		pos = { rect.x + settings.textWidth + 5, rect.y },
		size = { rect.w - (settings.textWidth + 5) * 2, rect.h },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true
	})
	sliderBG:addCustomDisplay(true, function()
			set_color(unpack(sliderBG.bgColor))
			draw_quad(sliderBG.pos.x, sliderBG.pos.y + rect.h / 2 - 3, sliderBG.size.w, 6)
		end)
	local sliderPos = 0
	value = value > settings.maxValue and 1 or (-settings.minValue + value) / (-settings.minValue + settings.maxValue)
	sliderPos = value * (sliderBG.size.w - settings.sliderRadius)

	---@type UISlider
	---@diagnostic disable-next-line: assign-type-mismatch
	local slider = sliderBG:addChild({
		pos = { sliderPos, (-sliderBG.size.h - settings.sliderRadius) / 2 },
		size = { settings.sliderRadius, settings.sliderRadius },
		interactive = true,
		bgColor = settings.darkerMode and TB_MENU_DEFAULT_DARKER_COLOR or TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
		inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR,
		shapeType = ROUNDED,
		rounded = settings.sliderRadius
	})
	local sliderLabel = slider:addChild({
		pos = { -settings.sliderRadius - 5, -slider.size.h - settings.sliderRadius },
		size = { settings.sliderRadius + 10, settings.sliderRadius },
		bgColor = table.clone(TB_MENU_DEFAULT_LIGHTER_COLOR),
		uiColor = table.clone(UICOLORWHITE),
		shapeType = ROUNDED,
		rounded = 4
	})
	sliderLabel.bgColor[4] = 0
	sliderLabel.uiColor[4] = 0
	sliderLabel.labelText = { "" }
	local sliderLabelOutClock = UIElement.clock
	sliderLabel:addCustomDisplay(false, function()
			if (sliderLabel.uiColor[4] > 0) then
				sliderLabel:uiText(sliderLabel.labelText[1], nil, nil, 4, nil, 0.5)
				if (slider.hoverState ~= BTN_DN) then
					sliderLabel.uiColor[4] = UITween.SineTween(sliderLabel.uiColor[4], 0, UIElement.clock - sliderLabelOutClock)
					sliderLabel.bgColor[4] = sliderLabel.uiColor[4]
				end
			end
		end)
	sliderLabel:addCustomDisplay(false, function()
			if (sliderLabel.uiColor[4] > 0) then
				-- Adapt label width to be able to fit the text
				local textWidth = get_string_length(sliderLabel.labelText[1], 4) * 0.5 + 16
				local targetWidth = textWidth > settings.sliderRadius + 10 and textWidth or settings.sliderRadius + 10
				if (targetWidth ~= sliderLabel.size.w) then
					sliderLabel.size.w = targetWidth
					sliderLabel:moveTo((-settings.sliderRadius - sliderLabel.size.w) / 2)
				end

				-- If bounding element is defined, we may want to display label below the slider
				if (settings.boundParent) then
					if (sliderLabel.lastY ~= sliderLabel.shift.y) then
						if (settings.boundParent.pos.y >= slider.pos.y - settings.sliderRadius) then
							sliderLabel:moveTo(nil, slider.size.h)
							sliderLabel:reload()
						else
							sliderLabel:moveTo(nil, -slider.size.h - settings.sliderRadius)
							sliderLabel:reload()
						end
						sliderLabel.lastY = sliderLabel.pos.y
					end
				end
			end
		end, true)

	slider.settings = settings
	slider.label = sliderLabel
	slider.lastVal = nil
	slider:addMouseHandlers(function()
			disable_mouse_camera_movement()
			slider.pressedPos = slider:getLocalPos()
			if (onMouseDown) then
				onMouseDown()
			end
		end, function()
			enable_mouse_camera_movement()
			sliderLabelOutClock = UIElement.clock
			if (onMouseUp) then
				onMouseUp()
			end
		end, function()
			if (slider.hoverState == BTN_DN) then
				local xPos = MOUSE_X - sliderBG.pos.x - slider.pressedPos.x
				if (xPos < 0) then
					xPos = 0
				elseif (xPos > sliderBG.size.w - slider.size.w) then
					xPos = sliderBG.size.w - slider.size.w
				end
				if (settings.isBoolean) then
					if (xPos + slider.size.w / 2 > sliderBG.size.w / 2) then
						xPos = sliderBG.size.w - slider.size.w
					else
						xPos = 0
					end
				end
				slider:moveTo(xPos, nil)

				local val = xPos / (sliderBG.size.w - settings.sliderRadius) * (settings.maxValue - settings.minValue) + settings.minValue
				sliderLabel.uiColor[4] = 1
				sliderLabel.bgColor[4] = 1

				if (sliderFunc and slider.lastVal ~= val) then
					local multiplyBy = tonumber('1' .. string.rep('0', settings.decimal))
					sliderLabel.labelText[1] = (math.floor(val * multiplyBy) / multiplyBy) .. ''
					sliderFunc(val, xPos, slider)
				end
				slider.lastVal = val
			end
		end)
	slider:addMouseUpOutsideHandler(slider.btnUp)
	slider.setValue = function(val, updateLabel)
		local val = val > settings.maxValue and settings.maxValue or (val < settings.minValue and settings.minValue or val)
		slider:moveTo(val / settings.maxValue * (sliderBG.size.w - slider.size.w), nil)

		if (updateLabel) then
			local multiplyBy = tonumber('1' .. string.rep('0', settings.decimal))
			sliderLabel.labelText[1] = (math.floor(val * multiplyBy) / multiplyBy) .. ''
			sliderLabel.uiColor[4] = 1
			sliderLabel.bgColor[4] = 1
		end
	end
	sliderBG:addMouseDownHandler(function(s, x, y)
		local pos = sliderBG:getLocalPos()
		local xPos = pos.x - slider.size.w / 2
		if (xPos < 0) then
			xPos = 0
		elseif (xPos > sliderBG.size.w - slider.size.w) then
			xPos = sliderBG.size.w - slider.size.w
		end
		if (settings.isBoolean) then
			if (xPos + slider.size.w / 2 > sliderBG.size.w / 2) then
				xPos = sliderBG.size.w - slider.size.w
			else
				xPos = 0
			end
		end
		sliderBG.hoverState = BTN_NONE

		slider:moveTo(xPos)
		slider.hoverState = BTN_DN
		slider.btnDown(s, x, y)
		slider.btnHover(x, y)
	end)
	return slider
end

---Legacy function to spawn sliders. Use `TBMenu:spawnSlider2()` instead.
---@param parent UIElement
---@param x ?number
---@param y ?number
---@param w ?number
---@param h ?number
---@param textWidth ?number
---@param sliderRadius ?number
---@param value ?number
---@param settings SliderSettings
---@param sliderFunc any
---@param onMouseDown any
---@param onMouseUp any
---@deprecated
function TBMenu:spawnSlider(parent, x, y, w, h, textWidth, sliderRadius, value, settings, sliderFunc, onMouseDown, onMouseUp)
	settings = settings or {}
	---@diagnostic disable-next-line: assign-type-mismatch
	settings.textWidth = textWidth
	---@diagnostic disable-next-line: assign-type-mismatch
	settings.sliderRadius = sliderRadius

	---@diagnostic disable-next-line: assign-type-mismatch
	return TBMenu:spawnSlider2(parent, { x = x, y = y, w = w, h = h }, value, settings, sliderFunc, onMouseDown, onMouseUp)
end

---Spawns a generic toggle with callbacks
---@param parent UIElement
---@param x ?number
---@param y ?number
---@param w ?number
---@param h ?number
---@param toggleValue ?string|number|boolean
---@param updateFunc ?function
---@return UIElement
function TBMenu:spawnToggle(parent, x, y, w, h, toggleValue, updateFunc)
	---@type Rect
	local rect = {
		x = x or 0,
		y = y or 0,
		w = w or parent.size.h,
		h = h or parent.size.h
	}

	local toggleBG = parent:addChild({
		pos = { rect.x, rect.y },
		size = { rect.w, rect.h },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	}, true)
	local toggleView = toggleBG:addChild({
		shift = { 1, 1 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
		interactive = true,
		toggle = true
	}, true)
	toggleView:addCustomDisplay(nil, function()
			if (toggleView.keyboard and toggleView.hoverState == BTN_NONE) then
				toggleView.hoverState = BTN_FOCUS
			end
		end, true)
	toggleView:addOnReceiveTabFocus(function()
			toggleView:enableMenuKeyboard()
			toggleView.keyboard = true
			toggleView.hoverState = BTN_FOCUS
		end)
	toggleView:addOnLoseTabFocus(function()
			toggleView:disableMenuKeyboard()
			toggleView.keyboard = false
			toggleView.hoverState = BTN_NONE
		end)
	local toggleIcon = toggleView:addChild({ bgImage = "../textures/menu/general/buttons/checkmark.tga" })

	if (tonumber(toggleValue) == 0 or toggleValue == false) then
		toggleIcon:hide(true)
	end
	toggleView:addMouseHandlers(nil, function(s, x, y)
			if (type(toggleValue) == "boolean") then
				toggleValue = not toggleValue
			else
				toggleValue = 1 - toggleValue
			end
			if (toggleValue == 1 or toggleValue == true) then
				toggleIcon:show(true)
			else
				toggleIcon:hide(true)
			end
			if (updateFunc ~= nil) then
				updateFunc(toggleValue)
			end
		end)
	return toggleView
end

---@class TextFieldInputSettings
---@field fontId FontId
---@field textAlign UIElementTextAlign
---@field textScale number
---@field textColor Color
---@field isNumeric boolean
---@field allowDecimal boolean
---@field allowNegative boolean
---@field allowMultiline boolean
---@field darkerMode boolean
---@field noCursor boolean
---@field keepFocusOnHide boolean
---@field maxLength integer
---@field customRegex string

---@type TextFieldInputSettings
local TextFieldDefaultInputSettings = {
	fontId = FONTS.SMALL,
	textAlign = LEFTMID,
	textScale = 1,
	textColor = table.clone(UICOLORBLACK),
	isNumeric = false,
	allowMultiline = false,
	noCursor = false,
	keepFocusOnHide = false,
	maxLength = 0
}

---Generates a generic text field UIElement.
---@param viewElement UIElement
---@param rect ?Rect
---@param textFieldString ?string|string[]
---@param defaultString ?string
---@param inputSettings ?TextFieldInputSettings
---@return UIElement
function TBMenu:spawnTextField2(viewElement, rect, textFieldString, defaultString, inputSettings)
	local rect = rect or { }
	local inputSettings = inputSettings or TextFieldDefaultInputSettings
	local textBg = viewElement:addChild({
		pos = { rect.x or 0, rect.y or 0 },
		size = { rect.w or viewElement.size.w, rect.h or viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	}, true)
	local lightColor, lightestColor = {}, {}
	for i, v in pairs(TB_MENU_DEFAULT_BG_COLOR) do
		lightColor[i] = v + 0.05
		lightestColor[i] = v + 0.1
	end
	local input = textBg:addChild({
		shift = { 1, 1 },
		interactive = true,
		bgColor = inputSettings.darkerMode and TB_MENU_DEFAULT_BG_COLOR or lightColor,
		hoverColor = inputSettings.darkerMode and lightColor or lightestColor,
		inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS
	}, true)
	local inputField = input:addChild({
		shift = { 4, 1 },
		interactive = true,
		textfield = true,
		hoverThrough = true,
		clickThrough = true,
		isNumeric = inputSettings.isNumeric,
		allowDecimal = inputSettings.allowDecimal,
		allowNegative = inputSettings.allowNegative,
		customRegex = inputSettings.customRegex,
		maxLength = inputSettings.maxLength,
		textfieldstr = textFieldString or "",
		textfieldsingleline = not inputSettings.allowMultiline,
		textfieldkeepfocusonhide = inputSettings.keepFocusOnHide,
		uiColor = viewElement.uiColor or UICOLORWHITE
	}, true)
	inputField:addMouseHandlers(function()
			inputField:enableMenuKeyboard()
		end)
	inputField.killAction = function() inputField:disableMenuKeyboard() end
	TBMenuInternal.DisplayTextfield(inputField, inputSettings.fontId or 4, inputSettings.textScale, inputSettings.textColor or inputField.uiColor, defaultString, inputSettings.textAlign, inputSettings.noCursor)
	return inputField
end

---@deprecated
---Use `TBMenu:spawnTextField2()` instead.
---@param parent UIElement
---@param x ?number
---@param y ?number
---@param w ?number
---@param h ?number
---@param textFieldString ?string|string[]
---@param inputSettings ?TextFieldInputSettings
---@param fontid ?FontId
---@param scale ?number
---@param color ?Color
---@param defaultStr ?string
---@param orientation ?UIElementTextAlign
---@param noCursor ?boolean
---@param multiLine ?boolean
---@param darkerMode ?boolean
---@return UIElement
---@overload fun(self:TBMenu, parent:UIElement, x?:number, y?:number, w?:number, h?:number, textFieldString?:string|string[], isNumeric?:boolean, fontid?:FontId, scale?:number, color?:Color, defaultStr?:string, orientation?:UIElementTextAlign, noCursor?:boolean, multiLine?:boolean, darkerMode?:boolean):UIElement
function TBMenu:spawnTextField(parent, x, y, w, h, textFieldString, inputSettings, fontid, scale, color, defaultStr, orientation, noCursor, multiLine, darkerMode)
	if (not parent) then
		return parent
	end
	local rect = {
		x = x or 0,
		y = y or 0,
		w = w or parent.size.w,
		h = h or parent.size.h
	}
	local inputSettings = type(inputSettings) == "table" and inputSettings or { isNumeric = inputSettings }
	inputSettings.noCursor = noCursor or false
	inputSettings.allowMultiline = multiLine or false
	inputSettings.darkerMode = darkerMode or false
	inputSettings.fontId = fontid or 4
	inputSettings.textScale = scale or 1
	inputSettings.textColor = color or table.clone(UICOLORBLACK)
	inputSettings.textAlign = orientation or LEFTMID

	return TBMenu:spawnTextField2(parent, rect, textFieldString, defaultStr, inputSettings)
end

---Internal method to display text field
---@param element UIElement
---@param fontid FontId
---@param scale number
---@param color Color
---@param defaultStr ?string
---@param orientation ?UIElementTextAlign
---@param noCursor ?boolean
function TBMenuInternal.DisplayTextfield(element, fontid, scale, color, defaultStr, orientation, noCursor)
	local defaultStr = defaultStr or ""
	local orientation = orientation or LEFTMID

	element:addAdaptedText(true, defaultStr, nil, nil, fontid, orientation, scale, nil, nil, nil, nil, nil, true)
	local defaultStringScale = element.textScale

	element:addCustomDisplay(true, function()
			if (element.keyboard == true) then
				set_color(1, 1, 1, 0.15)
				if (element.parent.shapeType == ROUNDED) then
					draw_disk(element.parent.pos.x + element.parent.rounded, element.parent.pos.y + element.parent.rounded + element.parent.innerShadow[1], 0, element.parent.rounded, 500, 1, -180, 90, 0)
					draw_disk(element.parent.pos.x + element.parent.rounded, element.parent.pos.y + element.parent.size.h - element.parent.rounded - element.parent.innerShadow[2], 0, element.parent.rounded, 500, 1, -90, 90, 0)
					draw_disk(element.parent.pos.x + element.parent.size.w - element.parent.rounded, element.parent.pos.y + element.parent.rounded + element.parent.innerShadow[1], 0, element.parent.rounded, 500, 1, 90, 90, 0)
					draw_disk(element.parent.pos.x + element.parent.size.w - element.parent.rounded, element.parent.pos.y + element.parent.size.h - element.parent.rounded - element.parent.innerShadow[2], 0, element.parent.rounded, 500, 1, 0, 90, 0)
					draw_quad(element.parent.pos.x + element.parent.rounded, element.parent.pos.y + element.parent.innerShadow[1], element.parent.size.w - element.parent.rounded * 2, element.parent.rounded)
					draw_quad(element.parent.pos.x, element.parent.pos.y + element.parent.rounded + element.parent.innerShadow[1], element.parent.size.w, element.parent.size.h - element.parent.rounded * 2 - element.parent.innerShadow[2] - element.parent.innerShadow[1])
					draw_quad(element.parent.pos.x + element.parent.rounded, element.parent.pos.y + element.parent.size.h - element.parent.rounded - element.parent.innerShadow[2], element.parent.size.w - element.parent.rounded * 2, element.parent.rounded)
				else
					draw_quad(element.parent.pos.x, element.parent.pos.y, element.parent.size.w, element.parent.size.h)
				end

				local part1 = utf8.sub(element.textfieldstr[1], 0, element.textfieldindex)
				local part2 = utf8.sub(element.textfieldstr[1], element.textfieldindex + 1)
				local displayString = part1 .. (noCursor and "" or "|") .. part2
				element:uiText(displayString, nil, nil, fontid, orientation, scale, nil, nil, color, nil, nil, nil, nil, nil, true)
			else
				if (element.menuKeyboardId) then
					element:disableMenuKeyboard()
				end
				if (element.textfieldstr[1] == "") then
					element:uiText(defaultStr, nil, nil, fontid, orientation, defaultStringScale, nil, nil, { color[1], color[2], color[3], color[4] * 0.5 }, nil, nil, nil, nil, nil, true)
				else
					element:uiText(element.textfieldstr[1], nil, nil, fontid, orientation, scale, nil, nil, color, nil, nil, nil, nil, nil, true)
				end
			end
		end)
end

TBMenu.GetTranslation(get_language())
