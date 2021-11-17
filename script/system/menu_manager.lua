-- modern main menu manager class
-- DO NOT MODIFY THIS FILE

do
	TBMenu = {}
	TBMenu.__index = TBMenu
	local cln = {}
	setmetatable(cln, TBMenu)

	function TBMenu:create()
		TB_MENU_MAIN_ISOPEN = 1
		set_build_version("211117")
	end

	function TBMenu:setLanguageFontOptions(language)
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
		
		-- Scaling for huge screens
		-- Doesn't look good, scrap it
		--[[if (WIN_W * WIN_H > 2000000) then
			UI_HIGH_RESOLUTION_MODE = true
		else
			UI_HIGH_RESOLUTION_MODE = false
		end]]
	end

	function TBMenu:getTranslation(language)
		local language = language or "english"
		local inverse = (language == "arabic" or language == "hebrew") and true 
		TBMenu:setLanguageFontOptions(language)
		if (type(TB_MENU_LOCALIZED) ~= "table" or TB_MENU_LOCALIZED.language ~= language or TB_MENU_DEBUG) then
			TB_MENU_LOCALIZED = {}
			TB_MENU_LOCALIZED.language = language
		else
			return
		end

		local file = io.open("data/script/system/language/" .. language .. ".txt", "r", 1)
		if (not file) then
			file = io.open("data/script/system/language/english.txt", "r", 1)
			if (not file) then
				echo("^04Localization data not found, exiting main menu")
				if (is_steam()) then
					echo("^07If this error persists, please verify integrity of game files in your Steam Library")
				else
					echo("^07If this error persists, please reinstall Toribash to repair system files")
				end
				TBMenu:quit()
				return
			end
		end

		for ln in file:lines() do
			if (not ln:match("^#")) then
				local data_stream = { ln:match(("([^\t]*)\t?"):rep(2)) }
				TB_MENU_LOCALIZED[data_stream[1]] = inverse and localize_rtl(data_stream[2]) or data_stream[2]
			end
		end
		file:close()

		if (language ~= "english") then
			-- Make sure there's no missing values
			local file = io.open("data/script/system/language/english.txt", "r", 1)
			for ln in file:lines() do
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

	function TBMenu:quit()
		remove_hooks("tbMainMenuVisual")
		remove_hooks("tbMainMenuMouse")
		remove_hooks("tbMenuConsoleIgnore")
		remove_hooks("tbMenuKeyboardHandler")
		
		enable_camera_movement()
		disable_blur()
		disable_menu_keyboard()
		chat_input_activate()
		
		TB_MENU_MAIN_ISOPEN = 0
		tbMenuMain:kill()
	end

	function TBMenu:createCurrentSectionView()
		tbMenuCurrentSection = UIElement:new( {
			parent = tbMenuMain,
			pos = { 75 * TB_MENU_GLOBAL_SCALE, 140 * TB_MENU_GLOBAL_SCALE + WIN_H / 16 },
			size = { WIN_W - 150 * TB_MENU_GLOBAL_SCALE, WIN_H - 250 * TB_MENU_GLOBAL_SCALE - WIN_H / 16 }
		})
	end

	-- Get image based on screen and element size
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
		return { elementWidth, elementHeight, heightShift }
	end

	function TBMenu:createImageButtons(parentElement, x, y, w, h, img, imgHvr, imgPress, col, colHvr, colPress, round)
		if (not parentElement or not x or not y or not w or not h or not img) then
			return false
		end
		local imgHvr = imgHvr or img
		local imgPress = imgPress or img
		local col = col or nil
		local colHvr = colHvr or col
		local colPress = colPress or colHvr
		local round = round or nil
		local buttonMain = UIElement:new( {
			parent = parentElement,
			pos = { x, y },
			size = { w, h },
			interactive = true,
			bgColor = col,
			hoverColor = colHvr,
			pressedColor = colPress,
			hoverSound = 31,
			shapeType = round and ROUNDED or SQUARE,
			rounded = round and round or 0
		})
		local buttonImage = UIElement:new( {
			parent = buttonMain,
			pos = { 0, 0 },
			size = { 0, 0 },
			bgImage = img
		})
		buttonImage:addCustomDisplay(true, function() end)
		local buttonImageHover = UIElement:new( {
			parent = buttonMain,
			pos = { 0, 0 },
			size = { 0, 0 },
			bgImage = imgHvr
		})
		buttonImageHover:addCustomDisplay(true, function() end)
		local buttonImagePress = UIElement:new( {
			parent = buttonMain,
			pos = { 0, 0 },
			size = { 0, 0 },
			bgImage = imgPress
		})
		buttonImagePress:addCustomDisplay(true, function()
				if (buttonMain.hoverState == false) then
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

	function TBMenu:changeCurrentEvent(viewElement, eventsData, eventItems, clock, reloadElement, direction)
		for i, v in pairs(eventItems) do
			if (i == TB_MENU_HOME_CURRENT_ANNOUNCEMENT) then
				v:hide()
				TB_MENU_HOME_CURRENT_ANNOUNCEMENT = TB_MENU_HOME_CURRENT_ANNOUNCEMENT + direction
				if (TB_MENU_HOME_CURRENT_ANNOUNCEMENT > #eventItems) then
					TB_MENU_HOME_CURRENT_ANNOUNCEMENT = TB_MENU_HOME_CURRENT_ANNOUNCEMENT - #eventItems
				elseif (TB_MENU_HOME_CURRENT_ANNOUNCEMENT < 1) then
					TB_MENU_HOME_CURRENT_ANNOUNCEMENT = #eventItems
				end
				eventItems[TB_MENU_HOME_CURRENT_ANNOUNCEMENT]:show()
				local function behavior()
					eventsData[TB_MENU_HOME_CURRENT_ANNOUNCEMENT].action()
					if (eventsData[TB_MENU_HOME_CURRENT_ANNOUNCEMENT].stop) then
						clock.pause = true
					end
				end
				viewElement:addMouseHandlers(nil, behavior, nil)
				reloadElement:reload()
				local tickTime = os.clock() * 10
				clock.start = math.floor(tickTime)
				clock.last = math.floor(tickTime)
				clock.pause = false
				break
			end
		end
	end

	function TBMenu:showHome()
		if (not tbMenuCurrentSection) then
			TBMenu:createCurrentSectionView()
		end
		
		-- Table to store event announcement data
		local newsData = News:getNews()
		
		-- If download is in progress, show loading screen instead
		if (newsData.downloading) then
			local homeView = UIElement:new({
				parent = tbMenuCurrentSection,
				pos = { 5, 0 },
				size = { tbMenuCurrentSection.size.w - 10, tbMenuCurrentSection.size.h },
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
		local rightSideWidth = (tbMenuCurrentSection.size.h * 0.7 - 10) * 1.513 + 10
		local homeAnnouncements = UIElement:new( {
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w - rightSideWidth - 10, tbMenuCurrentSection.size.h }
		})
		local featuredEvent = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { homeAnnouncements.size.w + 15, 0 },
			size = { rightSideWidth, tbMenuCurrentSection.size.h * 0.7 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverSound = 31
		})
		local viewEventsButton = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { featuredEvent.shift.x, tbMenuCurrentSection.size.h * 0.7 + 10 },
			size = { rightSideWidth, tbMenuCurrentSection.size.h * 0.3 - 10 },
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
			title = "View All Events",
			ratio = 0.3,
			action = function() Events:showEventsHome(tbMenuCurrentSection) end
		}
		
		-- Store all elements that would require reloading when switching event announcements in one table
		local toReload = UIElement:new({
			parent = homeAnnouncements,
			pos = { 0, 0 },
			size = { homeAnnouncements.size.w, homeAnnouncements.size.h }
		})
		homeAnnouncements.toReload = toReload

		local textHeight, descHeight = homeAnnouncements.size.h / 9, homeAnnouncements.size.h / 8
		local elementWidth, elementHeight, heightShift = unpack(TBMenu:getImageDimensions(homeAnnouncements.size.w, homeAnnouncements.size.h, 0.5, textHeight, descHeight))
		
		-- Spawn event announcement elements
		-- Make sure rotateClock is spawned before that
		local tickTime = os.clock() * 10
		local rotateClock = { start = math.floor(tickTime), last = math.floor(tickTime) }
		local eventItems = {}
		for i, v in pairs(eventsData) do
			local titleTextScale, subtitleTextScale = 1, 1
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
			if (i ~= TB_MENU_HOME_CURRENT_ANNOUNCEMENT) then
				eventItems[i]:hide()
			end
		end

		if (#eventsData > 1) then
			-- Spawn progress bar before next/prev buttons
			local eventDisplayTime = UIElement:new( {
				parent = toReload,
				pos = { 0, 0 },
				size = { 0, 0 }
			})

			-- Auto-rotate event announcements
			local rotateTime = 100
			featuredEventData.action = function()
				if (featuredEventData.initAction) then
					featuredEventData.initAction()
				end
				rotateClock.pause = true
			end
			local timeData = eventItems[1].button.pos.y > eventItems[1].image.pos.y + eventItems[1].image.size.h and { x = eventItems[1].image.pos.x, width = eventItems[1].image.size.w } or { x = eventItems[1].button.pos.x + 10, width = eventItems[1].button.size.w - 20 } 
			eventDisplayTime:addCustomDisplay(true, function()
					if (not rotateClock.pause) then
						set_color(1,1,1,0.6)
						draw_quad(timeData.x, eventItems[1].image.pos.y + eventItems[1].image.size.h - 5, (os.clock() * 10 - rotateClock.start) % rotateTime / rotateTime * timeData.width, 5)
					end
				end)
			homeAnnouncements:addCustomDisplay(false, function()
					if ((math.floor(os.clock() * 10) - rotateClock.start) % rotateTime == 0 and math.floor(os.clock() * 10) ~= rotateClock.last and not rotateClock.pause) then
						TBMenu:changeCurrentEvent(homeAnnouncements, eventsData, eventItems, rotateClock, toReload, 1)
					end
				end)
				
			-- Manual announcement change
			local eventPrevButton = TBMenu:createImageButtons(toReload, 10, 10 + elementHeight / 2 - 32, 32, 64, "../textures/menu/general/buttons/arrowleft.tga", nil, nil, { 0, 0, 0, 0 }, { 0, 0, 0, 0.7 })
			eventPrevButton:addMouseHandlers(nil, function()
					TBMenu:changeCurrentEvent(homeAnnouncements, eventsData, eventItems, rotateClock, toReload, -1)
					eventPrevButton.hoverState = BTN_HVR
				end, nil)
			local eventNextButton = TBMenu:createImageButtons(toReload, toReload.size.w - 42, 10 + elementHeight / 2 - 32, 32, 64, "../textures/menu/general/buttons/arrowright.tga", nil, nil, { 0, 0, 0, 0 }, { 0, 0, 0, 0.7 })
			eventNextButton:addMouseHandlers(nil, function()
					TBMenu:changeCurrentEvent(homeAnnouncements, eventsData, eventItems, rotateClock, toReload, 1)
					eventNextButton.hoverState = BTN_HVR
				end, nil)
		end
		TBMenu:showHomeButton(featuredEvent, featuredEventData)
		TBMenu:showHomeButton(viewEventsButton, viewEventsButtonData, 2)
	end

	function TBMenu:showHomeButton(viewElement, buttonData, hasSmudge, extraElements, lockedMessage)
		-- Add hover sound by default so it doesn't have to be set for each element manually
		viewElement.hoverSound = 31
		
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
		local itemIcon = UIElement:new({
			parent = viewElement,
			pos = { (viewElement.size.w - elementWidth) / 2, 10 },
			size = { elementWidth, elementHeight },
			bgImage = selectedIcon,
			uiColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		TBMenu:addOuterRounding(itemIcon, viewElement.animateColor)
		
		if (type(selectedIcon) == "table") then
			local filename = selectedIcon[1]:gsub(".*/", "")
			for i,v in pairs(NEWS_DOWNLOAD_QUEUE) do
				if (v:find(filename)) then
					TBMenu:displayLoadingMark(itemIcon, nil, elementHeight / 5)
					add_hook("downloader_complete", "menuMain" .. filename, function(name)
							if (name:find(filename .. "$")) then
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
							end
						end)
					break
				end
			end
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
		if (hasSmudge) then
			TBMenu:addBottomBloodSmudge(viewElement, hasSmudge)
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
					overlay.bgColor = cloneTable(viewElement.pressedColor)
					for i,v in pairs(extraElements) do
						if (type(v) == "table") then
							v.bgColor = cloneTable(viewElement.pressedColor)
						end
					end
				end, function()
					if (buttonData.quit) then
						close_menu()
					end
					buttonData.action()
					overlay.bgColor = viewElement.animateColor
					for i,v in pairs(extraElements) do
						if (type(v) == "table") then
							v.bgColor = viewElement.animateColor
						end
					end
				end)
		else
			viewElement:addMouseHandlers(nil, function() if (buttonData.quit) then close_menu() end buttonData.action() end)
		end
		if (buttonData.locked and lockedMessage) then
			viewElement:deactivate()
			local lockedMessageView = UIElement:new({
				parent = itemIcon,
				pos = { 0, 0 },
				size = { itemIcon.size.w, viewElement.size.h - 20 - titleHeight - descHeight },
				bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR)
			})
			lockedMessageView.bgColor[4] = 0.7
			lockedMessageView:addAdaptedText(nil, lockedMessage)
		end
		return titleHeight, descHeight
	end

	-- Clears navigation bar and current section element for side modules
	function TBMenu:clearNavSection()
		if (tbMenuNavigationBar) then
			tbMenuNavigationBar:kill(true)
		end
		if (not tbMenuCurrentSection) then
			TBMenu:createCurrentSectionView()
		else
			tbMenuCurrentSection:kill(true)
		end
	end

	function TBMenu:showClans(clantag)
		if (not tbMenuCurrentSection) then
			TBMenu:createCurrentSectionView()
		end
		Clans:showMain(tbMenuCurrentSection, clantag)
	end

	function TBMenu:showMarket()
		if (not tbMenuCurrentSection) then
			TBMenu:createCurrentSectionView()
		end
		Market:showMain(tbMenuCurrentSection)
	end

	function TBMenu:showReplays()
		tbMenuBottomLeftBar:hide()
		TBMenu:clearNavSection()

		if (TB_MENU_REPLAYS_ONLINE == 1) then
			local menubg = UIElement:new({
				parent = tbMenuCurrentSection,
				pos = { 5, 0 },
				size = { tbMenuCurrentSection.size.w - 10, tbMenuCurrentSection.size.h },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			TBMenu:addBottomBloodSmudge(menubg, 1)
			Replays:getServerReplays()
		else
			Replays:showMain(tbMenuCurrentSection)
		end
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 5
	end

	function TBMenu:showNotifications()
		if (not TB_STORE_DATA.ready) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.STOREDATALOADERROR)
			return
		end
		TBMenu:clearNavSection()
		Notifications:showMain()
	end

	function TBMenu:showScripts()
		TBMenu:clearNavSection()
		Scripts:showMain()
		TBMenu:showNavigationBar(Scripts:getNavigationButtons(), true)
	end

	function TBMenu:showSettings()
		tbMenuBottomLeftBar:hide()
		TBMenu:clearNavSection()
		Settings:showMain()
		TBMenu:showNavigationBar(Settings:getNavigationButtons(), true, true, TB_MENU_SETTINGS_SCREEN_ACTIVE or 1)
	end

	function TBMenu:showFriendsList()
		TBMenu:clearNavSection()
		FriendsList:showMain(tbMenuCurrentSection)
		TBMenu:showNavigationBar(FriendsList:getNavigationButtons(), true)
	end

	function TBMenu:showBounties()
		if (TB_BOUNTIES_DEFINED) then
			TBMenu:clearNavSection()
			Bounty:prepare()
			TBMenu:showNavigationBar(Bounty:getNavigationButtons(), true)
		else
			open_url("http://forum.toribash.com/tori_bounty.php")
		end
	end

	function TBMenu:prepareScrollableList(viewElement, topBarH, botBarH, scrollWidth, accentColor)
		local topBarH = topBarH or 50
		local toReload = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h }
		})
		local topBar = UIElement:new({
			parent = toReload,
			pos = { 0, 0 },
			size = { viewElement.size.w, topBarH },
			interactive = true,
			bgColor = accentColor or TB_MENU_DEFAULT_DARKER_COLOR
		})
		local botBar = UIElement:new({
			parent = toReload,
			pos = { 0, -botBarH },
			size = { viewElement.size.w, botBarH },
			interactive = true,
			bgColor = accentColor or TB_MENU_DEFAULT_DARKER_COLOR
		})
		local listingView = UIElement:new({
			parent = viewElement,
			pos = { 0, topBar.size.h },
			size = { viewElement.size.w, viewElement.size.h - topBar.size.h - botBar.size.h },
			interactive = true
		})
		local listingHolder = UIElement:new({
			parent = listingView,
			pos = { 0, 0 },
			size = { listingView.size.w - scrollWidth, listingView.size.h }
		})
		local listingScrollBG = UIElement:new({
			parent = listingView,
			pos = { -scrollWidth, 0 },
			size = { scrollWidth, listingView.size.h },
			bgColor = accentColor or TB_MENU_DEFAULT_DARKER_COLOR
		})
		listingHolder.scrollBG = listingScrollBG
		return toReload, topBar, botBar, listingView, listingHolder, listingScrollBG
	end

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
			local sPos, ePos = returnval:find(("%d+%s%S+%s"):rep(cut))
			if (ePos) then
				returnval = returnval:sub(0, ePos - 1)
			end
		end
		return returnval 
	end

	function TBMenu:spawnWindowOverlay(globalid, withMouseHandler)
		TB_MENU_POPUPS_DISABLED = true
		local globalid = globalid or nil
		UIScrollbarIgnore = true
		local overlay = UIElement:new({
			globalid = TB_MENU_MAIN_ISOPEN == 0 and (globalid or TB_MENU_HUB_GLOBALID),
			parent = tbMenuMain,
			pos = { 0, 0 },
			size = { WIN_W, WIN_H },
			interactive = true,
			bgColor = { 0, 0, 0, 0.4 }
		})
		overlay.killAction = function()
			UIScrollbarIgnore = false
			TB_MENU_POPUPS_DISABLED = false
		end
		if (withMouseHandler) then
			overlay:addMouseHandlers(nil, function()
					overlay:kill()
				end)
		end
		return overlay
	end

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
		local textField = TBMenu:spawnTextField(confirmBoxView, 10, confirmBoxTitle.shift.y + confirmBoxTitle.size.h + subtitleSet * 25 + 10, confirmBoxView.size.w - 20, 30, nil, nil, 1, nil, nil, inputInfo)
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
		local confirmBoxMessage = UIElement:new({
			parent = confirmBoxView,
			pos = { 10, 10 },
			size = { confirmBoxView.size.w - 20, (confirmBoxView.size.h - 20) / 3 * 2 }
		})
		local actions = thirdAction and 3 or 2
		confirmBoxMessage:addAdaptedText(true, message)
		while (confirmBoxMessage.textScale < 0.8 and confirmBoxView.size.h < confirmOverlay.size.h * 0.75) do
			confirmBoxView.size.h = confirmBoxView.size.h + 50
			confirmBoxMessage.size.h = (confirmBoxView.size.h - 20) / 3 * 2
			confirmBoxView:moveTo(nil, -25, true)
			confirmBoxMessage.str = nil
			confirmBoxMessage:addAdaptedText(true, message)
		end
		local cancelButton = UIElement:new({
			parent = confirmBoxView,
			pos = { 10, -(confirmBoxView.size.h - 20) / 3 + 5 },
			size = { confirmBoxView.size.w / actions - 15, (confirmBoxView.size.h - 20) / 4 },
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
		local acceptButton = UIElement:new({
			parent = confirmBoxView,
			pos = { -confirmBoxView.size.w / actions + 5, -(confirmBoxView.size.h - 20) / 3 + 5 },
			size = { confirmBoxView.size.w / actions - 15, (confirmBoxView.size.h - 20) / 4 },
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
			local thirdButton = UIElement:new({
				parent = confirmBoxView,
				pos = { confirmBoxView.size.w / actions + 5, -(confirmBoxView.size.h - 20) / 3 + 5 },
				size = { confirmBoxView.size.w / actions - 10, (confirmBoxView.size.h - 20) / 4 },
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

	function TBMenu:showDataError(message, noParent, time)
		local transparency = 0
		local bgColor, uiColor = { 0, 0, 0, transparency }, { 1, 1, 1, transparency }
		if (tbMenuDataErrorMessage) then
			tbMenuDataErrorMessage:kill()
			tbMenuDataErrorMessage = nil
		end
		local dataErrorY = (tbMenuMain and tbMenuMain.pos.y > 0) and (-tbMenuMain.pos.y) or WIN_H
		local messageWidth = WIN_W / 2 > 800 and 800 or WIN_W / 2
		tbMenuDataErrorMessage = UIElement:new({
			globalid = noParent and TB_MENU_HUB_GLOBALID,
			parent = tbMenuMain,
			pos = { (WIN_W - messageWidth) / 2, dataErrorY },
			size = { messageWidth, 54 },
			bgColor = bgColor,
			shapeType = ROUNDED,
			rounded = 5
		})
		local errorMessageView = UIElement:new({
			parent = tbMenuDataErrorMessage,
			pos = { tbMenuDataErrorMessage.size.w / 10, tbMenuDataErrorMessage.size.h / 10 },
			size = { tbMenuDataErrorMessage.size.w * 0.8, tbMenuDataErrorMessage.size.h * 0.8 }
		})
		errorMessageView:addAdaptedText(true, message, nil, nil, 4, nil, 0.9, nil, nil, nil, uiColor)
		
		while (errorMessageView.textScale < 0.65) do
			tbMenuDataErrorMessage.size.h = tbMenuDataErrorMessage.size.h + 10
			errorMessageView.size.h = tbMenuDataErrorMessage.size.h * 0.8
			errorMessageView.str = ''
			errorMessageView:addAdaptedText(true, message, nil, nil, 4, nil, 0.9, nil, nil, nil, uiColor)
		end
		
		local option = get_option("hint")
		if (noParent) then
			set_option("hint", 0)
		end
		tbMenuDataErrorMessage.startTime = os.clock()
		local moveRad = math.pi / 4
		local time = time and time or 5
		tbMenuDataErrorMessage:addCustomDisplay(false, function()
				if (tbMenuDataErrorMessage.pos.y > WIN_H - tbMenuDataErrorMessage.size.h - 10) then
					tbMenuDataErrorMessage:moveTo(nil, -(tbMenuDataErrorMessage.size.h / 9) * math.sin(moveRad), true)
					moveRad = moveRad + (math.pi / 20)
					transparency = transparency + (math.pi / 40)
					bgColor[4] = 0.8 * transparency
					uiColor[4] = transparency
				else
					tbMenuDataErrorMessage:addCustomDisplay(false, function()
							if (os.clock() - tbMenuDataErrorMessage.startTime > time) then
								transparency = transparency - 0.05
								bgColor[4] = 0.8 * transparency
								uiColor[4] = transparency
							end
							if (transparency <= 0) then
								tbMenuDataErrorMessage:kill()
								if (noParent) then
									set_option("hint", option)
								end
							end
						end)
				end
			end)
		return errorMessageView
	end

	function TBMenu:showTorishopMain()
		if (not tbMenuCurrentSection) then
			TBMenu:createCurrentSectionView()
		end
		Torishop:showMain(tbMenuCurrentSection)
	end

	function TBMenu:showAccountMain(reload)
		if (not tbMenuCurrentSection) then
			TBMenu:createCurrentSectionView()
		else
			tbMenuCurrentSection:kill(true)
		end
		
		local lastSpecialScreen = TB_MENU_SPECIAL_SCREEN_ISOPEN
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar({
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = function() 
					TB_MENU_SPECIAL_SCREEN_ISOPEN = lastSpecialScreen
					tbMenuCurrentSection:kill(true)
					tbMenuNavigationBar:kill(true)
					TBMenu:showNavigationBar()
					TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
				end,
			}
		}, true)
		TB_MENU_SPECIAL_SCREEN_ISOPEN = IGNORE_NAVBAR_SCROLL
		
		local accountView = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local elementHeight = 50
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(accountView, accountView.size.h / 10 > elementHeight and accountView.size.h / 10 or elementHeight, elementHeight - 16, 20, TB_MENU_DEFAULT_BG_COLOR)
	
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
					TBMenu:showAccountMain(true)
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
		
		local accountDatas = PlayerInfo:getServerUserinfo(nil, reload)
		if (accountDatas.ready) then
			showAccountData(accountDatas)
		else
			local infoMessage = UIElement:new({
				parent = listingHolder,
				pos = { 0, 0 },
				size = { listingHolder.size.w, listingHolder.size.h }
			})
			TBMenu:displayLoadingMark(infoMessage, TB_MENU_LOCALIZED.ACCOUNTGETTINGINFO)
			local infoUpdater = UIElement:new({
				parent = infoMessage,
				pos = { 0, 0 },
				size = { 0, 0 }
			})
			infoUpdater:addCustomDisplay(true, function()
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
		
		--[[local inventoryButton = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5 + tbMenuCurrentSection.size.w * 0.667, 0 },
			size = { tbMenuCurrentSection.size.w * 0.333 - 10, tbMenuCurrentSection.size.h / 2 - 5 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverSound = 31,
			interactive = true
		})
		local inventoryButtonData = {
			title = TB_MENU_LOCALIZED.STOREGOTOINVENTORY,
			subtitle = TB_MENU_LOCALIZED.STOREINVENTORYDESC,
			image = "../textures/menu/inventory.tga",
			ratio = 0.435,
			action = function()
					if (TB_STORE_DATA.ready) then
						Torishop:prepareInventory(tbMenuCurrentSection)
					else
						TBMenu:showDataError(TB_MENU_LOCALIZED.STOREDATALOADERROR)
					end
				end
		}
		TBMenu:showHomeButton(inventoryButton, inventoryButtonData)
		
		local clansButton = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5 + tbMenuCurrentSection.size.w * 0.667, tbMenuCurrentSection.size.h / 2 + 5 },
			size = { tbMenuCurrentSection.size.w * 0.333 - 10, tbMenuCurrentSection.size.h / 2 - 5 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverSound = 31,
			interactive = true
		})
		local clansButtonData = {
			title = TB_MENU_LOCALIZED.MAINMENUCLANSNAME,
			subtitle = TB_MENU_LOCALIZED.MAINMENUCLANSDESC,
			image = "../textures/menu/clans.tga",
			ratio = 0.5,
			action = function() TBMenu:showClans() end
		}
		TBMenu:showHomeButton(clansButton, clansButtonData, 2)]]
	end

	function TBMenu:showMatchmaking()
		if (not tbMenuCurrentSection) then
			TBMenu:createCurrentSectionView()
		end
		-- Connect user to matchmake server
		Matchmake:connect()
		Matchmake:showMain(tbMenuCurrentSection)
	end

	function TBMenu:showPlaySection()
		local tbMenuPlayButtonsData = {
			{ title = TB_MENU_LOCALIZED.MAINMENUFREEPLAYNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUFREEPLAYDESC, size = 0.5, ratio = 0.5, image = "../textures/menu/freeplay.tga", mode = ORIENTATION_LANDSCAPE, action = function() open_menu(1) end },
			{ title = TB_MENU_LOCALIZED.MAINMENUREPLAYSNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUREPLAYSDESC, size = 0.25, ratio = 1.055, image = "../textures/menu/replays2.tga", mode = ORIENTATION_PORTRAIT, action = function() TBMenu:showReplays() end },
			{ title = TB_MENU_LOCALIZED.MAINMENUROOMLISTNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUROOMLISTDESC, size = 0.25, ratio = 1.055, image = "../textures/menu/multiplayer.tga", mode = ORIENTATION_PORTRAIT, action = function() set_mouse_cursor(0, true) open_menu(2) end }
		}
		
		if (TB_MENU_PLAYER_INFO.username == '') then
			tbMenuPlayButtonsData[3] = nil
			tbMenuPlayButtonsData[1].size = 0.667
			tbMenuPlayButtonsData[2].size = 0.333
		end
		TBMenu:showSection(tbMenuPlayButtonsData)
	end

	function TBMenu:showPracticeSection()
		dofile("tutorial/tutorial_manager.lua")
		local tbMenuPracticeButtonsData = Tutorials:getMainMenuButtons()
		TBMenu:showSection(tbMenuPracticeButtonsData)
	end
	
	function TBMenu:showHotkeys()
		TB_MENU_SPECIAL_SCREEN_ISOPEN = IGNORE_NAVBAR_SCROLL
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
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(hotkeysView, elementHeight, elementHeight - 16, 20, TB_MENU_DEFAULT_BG_COLOR)
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
		for i,v in pairs(listElements) do
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

	function TBMenu:showToolsSection()
		local tbMenuToolsButtonsData = {
			{ title = TB_MENU_LOCALIZED.MAINMENUMODLISTNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUMODLISTDESC, size = 0.25, ratio = 1.055, image = "../textures/menu/modlist2.tga", action = function() dofile("system/mods.lua") end, quit = true },
			{ title = TB_MENU_LOCALIZED.MAINMENUGAMERULESNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUGAMERULESDESC, size = 0.25, vsize, ratio = 1.055, image = "../textures/menu/gamerules2.tga", action = function() dofile("system/gamerules.lua") end, quit = true },
			{ title = TB_MENU_LOCALIZED.MAINMENUMODMAKERNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUMODMAKERDESC, size = 0.25, vsize = 0.5, ratio = 1.055, image = "../textures/menu/modmaker2.tga", ratio2 = 0.5, image2 = "../textures/menu/modmaker3.tga", action = function() open_menu(17) end },
			{ title = TB_MENU_LOCALIZED.MAINMENUSCRIPTSNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUSCRIPTSDESC, size = 0.25, vsize = 0.5, ratio = 1.055, image = "../textures/menu/scripts.tga", ratio2 = 0.5, image2 = "../textures/menu/scripts2.tga", action = function() TBMenu:showScripts() end },
			{ title = TB_MENU_LOCALIZED.MAINMENUSHADERSNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUSHADERSDESC, size = 0.25, vsize = 0.5, ratio = 0.5, image = "../textures/menu/shaders2.tga", action = function()
					dofile("system/atmospheres_manager.lua")
					if (ATMO_MENU_MAIN_ELEMENT) then
						ATMO_MENU_MAIN_ELEMENT:kill()
						ATMO_MENU_MAIN_ELEMENT = nil
					end
					Atmospheres:showMain()
				end, quit = true },
			{ title = TB_MENU_LOCALIZED.MAINMENUHOTKEYSNAME, subtitle = TB_MENU_LOCALIZED.MAINMENUHOTKEYSDESC, size = 0.25, vsize = 0.5, ratio = 1.055, image = "../textures/menu/hotkeys.tga", ratio2 = 0.5, image2 = "../textures/menu/hotkeys2.tga", action = function() TBMenu:showHotkeys() end },
		}
		TBMenu:showSection(tbMenuToolsButtonsData)
	end

	function TBMenu:addBottomBloodSmudge(parentElement, num, scale)
		if (not parentElement) then
			return false
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
			pos = { 0, -(scale / 2) },
			size = { parentElement.size.w, scale },
			bgImage = bottomSmudge
		})
		return smudgeElement
	end
	
	function TBMenu:showSection(buttonsData, shift, lockedMessage)
		if (not tbMenuCurrentSection) then
			TBMenu:createCurrentSectionView()
		end
		local sectionX = shift and shift + 15 or 5
		local sectionY = 0
		for i,v in pairs(buttonsData) do
			local buttonView = UIElement:new({
				parent = tbMenuCurrentSection,
				pos = { sectionX, sectionY },
				size = { tbMenuCurrentSection.size.w * v.size - 10, v.vsize and (tbMenuCurrentSection.size.h * v.vsize - 5) or tbMenuCurrentSection.size.h },
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				interactive = true,
				hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				hoverSound = 31
			})
			sectionY = v.vsize and sectionY + buttonView.size.h + 10 or sectionY
			sectionY = sectionY >= tbMenuCurrentSection.size.h and 0 or sectionY
			sectionX = sectionY == 0 and sectionX + buttonView.size.w + 10 or sectionX
			TBMenu:showHomeButton(buttonView, v, sectionY == 0 and i, nil, lockedMessage)
		end
	end

	function TBMenu:openMenu(screenId)
		if (tbMenuBottomLeftBar) then
			tbMenuBottomLeftBar:show()
		end
		
		-- If last used screen was matchmaking, disable search and disconnect from lobby
		if (TB_MATCHMAKER_SEARCHSTATUS) then
			TB_MATCHMAKER_SEARCHSTATUS = nil
			if (get_world_state().game_type == 0) then
				UIElement:runCmd("matchmake disconnect")
			end
		end
		
		if (TB_MENU_SPECIAL_SCREEN_ISOPEN == 1) then
			TBMenu:showTorishopMain()
			Torishop:prepareInventory(tbMenuCurrentSection)
		--[[elseif (TB_MENU_SPECIAL_SCREEN_ISOPEN == 3) then
			TBMenu:showClans()
			if (TB_MENU_CLANS_OPENCLANID ~= 0) then
				Clans:showClan(tbMenuCurrentSection, TB_MENU_CLANS_OPENCLANID)
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
			Torishop:showStoreSection(tbMenuCurrentSection, TB_LAST_STORE_SECTION, TB_LAST_STORE_SECTIONID)
		elseif (screenId == 1) then
			TBMenu:showHome()
		elseif (screenId == 2) then
			TBMenu:showPlaySection()
		elseif (screenId == 3) then
			TBMenu:showPracticeSection()
		elseif (screenId == 4) then
			TBMenu:showModsSection()
		elseif (screenId == 5) then
			TBMenu:showToolsSection()
		elseif (screenId == 6) then
			TBMenu:showTorishopMain()
		elseif (screenId == 7) then
			TBMenu:showAccountMain()
		elseif (screenId == 8) then
			TBMenu:showMatchmaking()
		elseif (screenId == 9) then
			TBMenu:showClans()
		elseif (screenId == 10) then
			TBMenu:showMarket()
		elseif (screenId == 101) then
			TBMenu:showNotifications()
		elseif (screenId == 102) then
			TBMenu:showFriendsList()
		end
	end

	function TBMenu:showGameLogo()
		local logo = TB_MENU_GAME_LOGO
		local gametitle = TB_MENU_GAME_TITLE
		local logoSize = 90 * TB_MENU_GLOBAL_SCALE
		local gameTitleSize = 256 * TB_MENU_GLOBAL_SCALE
		local customLogo = io.open("custom/" .. TB_MENU_PLAYER_INFO.username .. "/logo.tga", "r", 1)
		if (customLogo) then
			logo = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/logo.tga"
			logoSize = 120
			customLogo:close()
		end
		local customGametitle = io.open("custom/" .. TB_MENU_PLAYER_INFO.username .. "/header.tga", "r", 1)
		if (customGametitle) then
			gametitle = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/header.tga"
			customGametitle:close()
		end
		local tbMenuLogo = UIElement:new( {
			parent = tbMenuMain,
			pos = { logoSize / 9 * 5, 10 },
			size = { logoSize, logoSize },
			bgImage = logo
		})
		local tbMenuGameTitle = UIElement:new( {
			parent = tbMenuMain,
			pos = { logoSize / 9 * 14 + 5, 15 },
			size = { gameTitleSize, gameTitleSize },
			bgImage = gametitle
		})
	end

	function TBMenu:buttonGrowHover(viewElement, iconElement)
		local scale = 1.1
		local growth = 0.4
		if (viewElement.hoverState == BTN_HVR) then
			if (iconElement.size.h < viewElement.size.h * scale) then
				iconElement.size.h = iconElement.size.h + growth
				iconElement.size.w = iconElement.size.h
				if (iconElement.shift.x >= 0) then
					iconElement:moveTo(-viewElement.size.w - growth / 2, -viewElement.size.h - growth / 2)
				else
					iconElement:moveTo(iconElement.shift.x - growth / 2, iconElement.shift.y - growth / 2)
				end
			end
		elseif (viewElement.hoverState == BTN_DN) then
			iconElement.size.h = viewElement.size.h * scale
			iconElement.size.w = iconElement.size.h
			iconElement:moveTo(-viewElement.size.w - viewElement.size.h * (scale - 1) / 2, -viewElement.size.h - viewElement.size.h * (scale - 1) / 2)
		else
			iconElement.size.h = viewElement.size.h
			iconElement.size.w = iconElement.size.h
			iconElement:moveTo(0, 0)
		end
	end

	function TBMenu:showUserBar()
		local tbMenuTopBarWidth = math.ceil(512 * (TB_MENU_GLOBAL_SCALE or 1))
		if (tbMenuUserBar) then
			tbMenuUserBar:kill()
			tbMenuUserBar = nil
		end

		tbMenuUserBar = UIElement:new( {
			parent = tbMenuMain,
			pos = {-tbMenuTopBarWidth, 0},
			size = {tbMenuTopBarWidth, 100}
		})
		local tbMenuUserBarBottomSplat2 = UIElement:new( {
			parent = tbMenuUserBar,
			pos = {-tbMenuTopBarWidth, 0},
			size = {tbMenuTopBarWidth, tbMenuTopBarWidth / 4},
			bgImage = TB_MENU_USERBAR_MAIN
		})
		local tbMenuUserBarSplat = UIElement:new( {
			parent = tbMenuUserBar,
			pos = { math.ceil(-tbMenuTopBarWidth * 1.25), 0 },
			size = { tbMenuTopBarWidth / 4, tbMenuTopBarWidth / 4 },
			bgImage = TB_MENU_USERBAR_LEFT
		})
		local tbMenuUserHeadAvatarViewport = UIElement:new( {
			parent = tbMenuUserBar,
			pos = { -tbMenuUserBar.size.w - tbMenuTopBarWidth / 16, 0 },
			size = { tbMenuTopBarWidth / 5, tbMenuTopBarWidth / 5 },
			viewport = true
		})
		local tbMenuUserHeadAvatarViewport3D = UIElement3D:new({
			globalid = TB_MENU_MAIN_GLOBALID,
			shapeType = VIEWPORT,
			parent = tbMenuUserHeadAvatarViewport,
			pos = { 0, 0, 0 },
			size = { 0, 0, 0 },
			rot = { 0, 0, 0 },
			viewport = true
		})
		table.insert(tbMenuUserHeadAvatarViewport.child, tbMenuUserHeadAvatarViewport3D)
		local playerHeadHolder = UIElement3D:new({
			parent = tbMenuUserHeadAvatarViewport3D,
			shapeType = SPHERE,
			pos = { 0, 0, 9.7 },
			size = { 0.6, 0.6, 0.6 },
			rot = { 0, 0, 0 },
			viewport = true
		})
		if (UIMODE_LIGHT) then
			playerHeadHolder:rotate(0, 0, -16)
		else
			local headRotation = math.pi / 2
			playerHeadHolder:addCustomDisplay(true, function()
					playerHeadHolder:rotate(0, 0, math.cos(headRotation))
					headRotation = headRotation + math.pi / 570
				end)
		end
		local color = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force)
		local headAvatarNeck = UIElement3D:new({
			parent = playerHeadHolder,
			pos = { 0, 0.2, -0.48},
			rot = { 0, 0, 0 },
			size = { 0.5, 0, 0 },
			shapeType = SPHERE,
			viewport = true,
			bgColor = { color.r, color.g, color.b, 1 },
			effects = TB_MENU_PLAYER_INFO.items.effects.force
		})
		local headTexture = { "../../custom/tori/head.tga", "../../custom/tori/head.tga" }
		if (TB_MENU_PLAYER_INFO.items.textures.head.equipped) then
			headTexture[1] = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/head.tga"
		end
		local headAvatarHead = UIElement3D:new({
			parent = playerHeadHolder,
			shapeType = SPHERE,
			pos = { 0, 0, 0.2 },
			rot = { 0, 0, 0 },
			size = { 0.9, 0, 0 },
			bgColor = { 1, 1, 1, 1 },
			bgImage = headTexture,
			viewport = true,
			effects = TB_MENU_PLAYER_INFO.items.effects.head
		})
		if (TB_MENU_PLAYER_INFO.items.objs.head.equipped) then
			local objScale = TB_MENU_PLAYER_INFO.items.objs.head.dynamic and 2 or 10
			if (TB_MENU_PLAYER_INFO.items.objs.head.partless and headAvatarHead) then
				headAvatarHead:kill()
			end
			local modelColor = get_color_info(TB_MENU_PLAYER_INFO.items.objs.head.colorid)
			modelColor.a = TB_MENU_PLAYER_INFO.items.objs.head.alpha / 255
			local headObjModel = UIElement3D:new({
				parent = playerHeadHolder,
				shapeType = CUSTOMOBJ,
				objModel = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/head",
				pos = { 0, 0, 0.2 },
				rot = { 0, 0, 0 },
				size = { objScale * 0.9, objScale * 0.9, objScale * 0.9 },
				bgColor = { modelColor.r, modelColor.g, modelColor.b, modelColor.a },
				viewport = true
			})
		end
		local tbMenuUserName = UIElement:new( {
			parent = tbMenuUserBar,
			pos = { tbMenuTopBarWidth / 6, tbMenuTopBarWidth / 50 },
			size = { tbMenuTopBarWidth / 1.5, tbMenuTopBarWidth / 20 }
		})
		local displayName = TB_MENU_PLAYER_INFO.username == "" and "Tori" or TB_MENU_PLAYER_INFO.username
		tbMenuUserName.size.w = get_string_length(displayName, 0) * 0.55 + 10
		tbMenuUserName:addCustomDisplay(false, function()
				tbMenuUserName:uiText(displayName, tbMenuUserName.pos.x + 2, tbMenuUserName.pos.y + 2, 0, 0, 0.55, nil, nil, {0,0,0,0.2}, nil, 0)
				tbMenuUserName:uiText(displayName, nil, nil, 0, 0, 0.55, nil, nil, nil, nil, 0.5)
			end)
			
		local accountButton = UIElement:new({
			parent = tbMenuUserBar,
			pos = { tbMenuUserName.shift.x + tbMenuUserName.size.w, tbMenuUserName.shift.y + 3 },
			size = { tbMenuUserBar.size.w - tbMenuUserName.shift.x * 2, tbMenuUserName.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKER_ORANGE,
			shapeType = ROUNDED,
			rounded = tbMenuUserName.size.h
		})
		accountButton:addAdaptedText(nil, TB_MENU_LOCALIZED.NAVBUTTONACCOUNT, 15, nil, 4, LEFTMID, 0.7)
		accountButton.size.w = get_string_length(accountButton.dispstr[1], accountButton.textFont) * accountButton.textScale + 30
		accountButton:addCustomDisplay(false, function() end)
		local accountButtonText = UIElement:new({
			parent = accountButton,
			pos = { 10, accountButton.size.h * 0.05 },
			size = { accountButton.size.w - 20, accountButton.size.h * 0.9 }
		})
		TBMenu:showTextWithImage(accountButtonText, TB_MENU_LOCALIZED.NAVBUTTONACCOUNT, 4, accountButtonText.size.h * 0.75, TB_MENU_LOGOUT_BUTTON)
		accountButton:addMouseHandlers(nil, function()
				TBMenu:showAccountMain()
			end)
		
		--[[
		local tbMenuLogoutButton = TBMenu:createImageButtons(tbMenuUserBar, tbMenuTopBarWidth / 6 + 10 + get_string_length(displayName, 0) * 0.55, tbMenuTopBarWidth / 34, tbMenuTopBarWidth / 20, tbMenuTopBarWidth / 20, TB_MENU_LOGOUT_BUTTON, TB_MENU_LOGOUT_BUTTON_HOVER, TB_MENU_LOGOUT_BUTTON_PRESS)
		tbMenuLogoutButton:addMouseHandlers(nil, function()
				open_menu(18)
			end, nil)
		]]
		
		local tbMenuClan = UIElement:new( {
			parent = tbMenuUserBar,
			pos = { tbMenuTopBarWidth / 6, tbMenuTopBarWidth / 11.5 },
			size = { tbMenuTopBarWidth / 1.5, tbMenuTopBarWidth / 25 }
		})
		if (TB_MENU_GLOBAL_SCALE < 1) then
			tbMenuClan:hide()
		end
		if (TB_MENU_PLAYER_INFO.clan.id ~= 0) then
			tbMenuClan:addAdaptedText(true, TB_MENU_LOCALIZED.MAINMENUUSERCLAN .. ": " .. TB_MENU_PLAYER_INFO.clan.tag .. ((TB_MENU_PLAYER_INFO.clan.name ~= '') and ("  |  " .. TB_MENU_PLAYER_INFO.clan.name) or ''), nil, nil, 4, 0, 0.6)
		end
		
		local tbMenuUserTcView = UIElement:new( {
			parent = tbMenuUserBar,
			pos = { tbMenuTopBarWidth / 6, tbMenuTopBarWidth / 8 },
			size = { tbMenuTopBarWidth / 3, tbMenuTopBarWidth / 20 },
			bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR),
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
			hoverSound = 31,
			shapeType = ROUNDED,
			rounded = 13
		})
		tbMenuUserTcView.bgColor[4] = 0.01
		local tcPopup = TBMenu:displayHelpPopup(tbMenuUserTcView, TB_MENU_LOCALIZED.USERBARTCINFO, nil, true)
		tbMenuUserTcView:addMouseHandlers(nil, function()
				if (TB_STORE_DATA.ready) then
					Torishop:showStoreSection(tbMenuCurrentSection, 4, 1)
					tcPopup:reload(true)
				end
			end)
		tcPopup:moveTo(nil, 36, true)
		
		local tbMenuUserTcIcon = UIElement:new( {
			parent = tbMenuUserTcView,
			pos = { 0, -tbMenuUserTcView.size.h - 1.5 },
			size = { tbMenuUserTcView.size.h + 3, tbMenuUserTcView.size.h + 3 },
			bgImage = "../textures/store/toricredit_tiny.tga"
		})
		local tbMenuUserTcBalance = UIElement:new( {
			parent = tbMenuUserTcView,
			pos = { tbMenuUserTcView.size.h + 10, 0 },
			size = { tbMenuUserTcView.size.w - tbMenuUserTcIcon.size.w - 5, tbMenuUserTcView.size.h }
		})
		tbMenuUserTcBalance:addAdaptedText(true, PlayerInfo:currencyFormat(TB_MENU_PLAYER_INFO.data.tc), nil, nil, 2, 6, 0.9)
		tbMenuUserTcView.size.w = get_string_length(tbMenuUserTcBalance.dispstr[1], tbMenuUserTcBalance.textFont) * tbMenuUserTcBalance.textScale + 50
		
		local tbMenuUserStView = UIElement:new( {
			parent = tbMenuUserBar,
			pos = { tbMenuTopBarWidth / 2, tbMenuTopBarWidth / 8 },
			size = { tbMenuTopBarWidth / 5, tbMenuTopBarWidth / 20 },
			bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR),
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
			hoverSound = 31,
			shapeType = ROUNDED,
			rounded = 13
		})
		tbMenuUserStView.bgColor[4] = 0.01
		local stPopup = TBMenu:displayHelpPopup(tbMenuUserStView, TB_MENU_LOCALIZED.USERBARSTINFO, nil, true)
		tbMenuUserStView:addMouseHandlers(nil, function()
				if (TB_STORE_DATA.ready) then
					Torishop:showStoreSection(tbMenuCurrentSection, 4, 2)
					stPopup:reload(true)
				end
			end)
		stPopup:moveTo(nil, 36, true)
		
		local tbMenuUserStIcon = UIElement:new( {
			parent = tbMenuUserStView,
			pos = { 0, -tbMenuUserStView.size.h - 1.5 },
			size = { tbMenuUserStView.size.h + 3, tbMenuUserStView.size.h + 3},
			bgImage = "../textures/store/shiaitoken_tiny.tga"
		})
		local tbMenuUserStBalance = UIElement:new( {
			parent = tbMenuUserStView,
			pos = { tbMenuUserStView.size.h + 10, 0 },
			size = { tbMenuUserStView.size.w - 30, tbMenuUserStView.size.h }
		})
		tbMenuUserStBalance:addAdaptedText(true, PlayerInfo:currencyFormat(TB_MENU_PLAYER_INFO.data.st), nil, 1, 2, 6, 0.9)
		tbMenuUserStView.size.w = get_string_length(tbMenuUserStBalance.dispstr[1], tbMenuUserStBalance.textFont) * tbMenuUserStBalance.textScale + 50
		
		local tbMenuUserBeltIcon = UIElement:new({
			parent = tbMenuUserBar,
			pos = { -tbMenuTopBarWidth / 4, 0 },
			size = { tbMenuTopBarWidth / 4.5, tbMenuTopBarWidth / 4.5 },
			bgImage = TB_MENU_PLAYER_INFO.data.belt.icon
		})
		local tbMenuUserQi = UIElement:new( {
			parent = tbMenuUserBar,
			pos = { -tbMenuTopBarWidth / 4, tbMenuTopBarWidth / 10 },
			size = { tbMenuTopBarWidth / 4.5, tbMenuTopBarWidth / 13 }
		})
		tbMenuUserQi:addAdaptedText(true, TB_MENU_PLAYER_INFO.data.belt.name .. " belt", nil, nil, 2, nil, nil, nil, nil, 1)
		
		TB_MENU_CUSTOMS_REFRESHED = false
		tbMenuUserBar:addCustomDisplay(false, function()
				if (TB_MENU_CUSTOMS_REFRESHED) then
					TB_MENU_CUSTOMS_REFRESHED = false
					
					tbMenuUserTcBalance:addAdaptedText(true, PlayerInfo:currencyFormat(TB_MENU_PLAYER_INFO.data.tc), nil, 1, 2, 6, 0.9)
					tbMenuUserTcView.size.w = get_string_length(tbMenuUserTcBalance.dispstr[1], tbMenuUserTcBalance.textFont) * tbMenuUserTcBalance.textScale + 50
					
					tbMenuUserStBalance:addAdaptedText(true, PlayerInfo:currencyFormat(TB_MENU_PLAYER_INFO.data.st), nil, 1, 2, 6, 0.9)
					tbMenuUserStView.size.w = get_string_length(tbMenuUserStBalance.dispstr[1], tbMenuUserStBalance.textFont) * tbMenuUserStBalance.textScale + 50
					
					if (TB_MENU_PLAYER_INFO.clan.id ~= 0) then
						tbMenuClan:addAdaptedText(true, TB_MENU_LOCALIZED.MAINMENUUSERCLAN .. ": " .. TB_MENU_PLAYER_INFO.clan.tag .. ((TB_MENU_PLAYER_INFO.clan.name ~= '') and ("  |  " .. TB_MENU_PLAYER_INFO.clan.name) or ''), nil, nil, 4, 0, 0.6)
					end
					tbMenuUserBeltIcon:updateImage(TB_MENU_PLAYER_INFO.data.belt.icon)
					tbMenuUserQi:addAdaptedText(true, TB_MENU_PLAYER_INFO.data.belt.name .. " belt", nil, nil, 2, nil, nil, nil, nil, 1)
				end
			end)
	end
	
	function TBMenu:showPlayerHeadAvatar(viewElement, player)
		local viewportSize = viewElement.size.w > viewElement.size.h and viewElement.size.h or viewElement.size.w
		local headViewport = UIElement:new( {
			parent = viewElement,
			pos = { (viewElement.size.w - viewportSize) / 2, (viewElement.size.h - viewportSize) / 2 },
			size = { viewportSize, viewportSize },
			viewport = true
		})
		local headViewport3D = UIElement3D:new({
			globalid = TB_MENU_MAIN_GLOBALID,
			shapeType = VIEWPORT,
			parent = headViewport,
			pos = { 0, 0, 0 },
			size = { 0, 0, 0 },
			rot = { 0, 0, 0 },
			viewport = true
		})
		table.insert(headViewport.child, headViewport3D)
		
		local customs = PlayerInfo:getItems(player)
		local headTexture = { "../../custom/tori/head.tga", "../../custom/tori/head.tga" }
		if (customs.textures.head.equipped) then
			headTexture[1] = "../../custom/" .. player .. "/head.tga"
		end
		local color = get_color_info(customs.colors.force)
		local playerNeckHolder = UIElement3D:new({
			parent = headViewport3D,
			shapeType = SPHERE,
			pos = { -0.04, 0.18, 9.22},
			rot = { 0, 0, 0 },
			size = { 0.5, 0, 0 },
			viewport = true,
			bgColor = { color.r, color.g, color.b, 1 }
		})
		local playerHeadHolder = UIElement3D:new({
			parent = headViewport3D,
			shapeType = SPHERE,
			pos = { 0, 0, 9.9 },
			size = { 0.9, 0, 0 },
			rot = { 0, 0, -10 },
			bgColor = { 1, 1, 1, 1 },
			bgImage = headTexture,
			viewport = true
		})
		if (customs.objs.head.equipped) then
			local objScale = customs.objs.head.dynamic and 2 or 10
			if (customs.objs.head.partless and headAvatarHead) then
				headAvatarHead:kill()
			end
			local modelColor = get_color_info(customs.objs.head.colorid)
			modelColor.a = customs.objs.head.alpha / 255
			local headObjModel = UIElement3D:new({
				parent = headViewport3D,
				shapeType = CUSTOMOBJ,
				objModel = "../../custom/" .. player .. "/head",
				pos = { 0, 0, 9.7 },
				rot = { 0, 0, -10 },
				size = { objScale * 0.9, objScale * 0.9, objScale * 0.9 },
				bgColor = { modelColor.r, modelColor.g, modelColor.b, modelColor.a },
				viewport = true
			})
		end
	end
	
	function TBMenu:showNavigationBar(buttonsData, customNav, customNavHighlight, selectedId)
		local tbMenuNavigationButtonsData = buttonsData or TBMenu:getMainNavigationButtons()
		local tbMenuNavigationButtons = {}
		local selectedId = selectedId or 0
		
		local navHeight = WIN_H / 16 > 60 and 60 or WIN_H / 16
		local navX = { l = { 30 } , r = { -30 } }
		tbMenuNavigationBar = tbMenuNavigationBar or UIElement:new({
			parent = tbMenuMain,
			pos = { 50 * TB_MENU_GLOBAL_SCALE, 130 * TB_MENU_GLOBAL_SCALE },
			size = { WIN_W - 100 * TB_MENU_GLOBAL_SCALE, navHeight },
			bgColor = { 0, 0, 0, 0.9 },
			shapeType = ROUNDED,
			rounded = 10
		})
		
		-- Check if total button width doesn't exceed navbar width
		-- Assign button width accordingly
		local totalWidth = tbMenuNavigationBar.size.w
		local fontScale = 0.65
		local fontId = FONTS.BIG
		local temp = tbMenuNavigationBar:addChild({
			size = { tbMenuNavigationBar.size.w, tbMenuNavigationBar.size.h / 6 * 4 }
		})
		
		while (totalWidth > tbMenuNavigationBar.size.w - navX.l[1] + navX.r[1]) do
			totalWidth = 0
			fontScale = fontScale - 0.05
			for i,v in pairs(tbMenuNavigationButtonsData) do
				if (getFontMod(fontId) * 10 * fontScale > temp.size.h) then
					totalWidth = tbMenuNavigationBar.size.w
					break
				end
				
				local string = v.misctext and v.text .. " " .. v.misctext or v.text
				temp:addAdaptedText(true, string, nil, nil, fontId, nil, fontScale, fontScale, nil, nil, nil, nil, nil, true)
				v.width = get_string_length(temp.dispstr[1] .. "_____", temp.textFont) * temp.textScale
				totalWidth = totalWidth + v.width
			end
		end
		temp:kill()
		
		for i, v in pairs(tbMenuNavigationButtonsData) do
			local navX = v.right and navX.r or navX.l
			tbMenuNavigationButtons[i] = UIElement:new( {
				parent = tbMenuNavigationBar,
				pos = { v.right and navX[1] - v.width or navX[1], 0 },
				size = { v.width, tbMenuNavigationBar.size.h },
				bgColor = { 0.2, 0.2, 0.2, 0 },
				interactive = true,
				hoverColor = TB_NAVBAR_DEFAULT_BG_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverSound = 31
			})
			navX[1] = v.right and navX[1] - v.width or navX[1] + v.width
			if ((not customNav and TB_LAST_MENU_SCREEN_OPEN == v.sectionId) or (customNav and customNavHighlight and selectedId == v.sectionId)) then
				tbMenuNavigationButtons[i].bgColor = TB_NAVBAR_DEFAULT_BG_COLOR
			end
			tbMenuNavigationButtons[i]:addCustomDisplay(false, function()
					set_color(tbMenuNavigationButtons[i].animateColor[1] - 0.1, tbMenuNavigationButtons[i].animateColor[2], tbMenuNavigationButtons[i].animateColor[3], tbMenuNavigationButtons[i].animateColor[4])
					for j = tbMenuNavigationBar.size.h - 10, 10, -10 do
						draw_line(tbMenuNavigationButtons[i].pos.x, tbMenuNavigationButtons[i].pos.y - 1 + j, tbMenuNavigationButtons[i].pos.x + j, tbMenuNavigationButtons[i].pos.y + 1, 0.5)
					end
					for j = 0, tbMenuNavigationButtons[i].size.w - tbMenuNavigationBar.size.h, 10 do
						draw_line(tbMenuNavigationButtons[i].pos.x + tbMenuNavigationBar.size.h + j, tbMenuNavigationButtons[i].pos.y + 1, tbMenuNavigationButtons[i].pos.x + j, tbMenuNavigationButtons[i].pos.y + tbMenuNavigationBar.size.h - 1, 0.5)
					end
					for j = tbMenuNavigationBar.size.h - 10, 10, -10 do
						draw_line(tbMenuNavigationButtons[i].pos.x + tbMenuNavigationButtons[i].size.w - j, tbMenuNavigationButtons[i].pos.y + tbMenuNavigationBar.size.h - 1, tbMenuNavigationButtons[i].pos.x + tbMenuNavigationButtons[i].size.w, tbMenuNavigationButtons[i].pos.y + tbMenuNavigationBar.size.h - 1 - j, 0.5)
					end
				end)
			local buttonText = tbMenuNavigationButtons[i]:addChild({ shift = { 15, tbMenuNavigationBar.size.h / 6 } })
			if (v.misctext) then
				local width = get_string_length(v.misctext .. "__", FONTS.MEDIUM)
				local miscMark = UIElement:new({
					parent = buttonText,
					pos = { -(buttonText.size.w - get_string_length(v.text, fontId) * fontScale + width - 16) / 2, 0 },
					size = { width, buttonText.size.h },
					bgColor = TB_MENU_DEFAULT_ORANGE,
					uiColor = UICOLORBLACK,
					shapeType = ROUNDED,
					rounded = buttonText.size.h
				})
				miscMark:addAdaptedText(false, v.misctext)
				buttonText:addCustomDisplay(true, function()
					buttonText:uiText(v.text, -width / 2, nil, fontId, nil, fontScale)
				end)
			else
				buttonText:addCustomDisplay(true, function()
					buttonText:uiText(v.text, nil, nil, fontId, nil, fontScale)
				end)
			end
			tbMenuNavigationButtons[i]:addMouseHandlers(nil, function()
					if (not customNav) then
						if (v.sectionId ~= TB_LAST_MENU_SCREEN_OPEN) then
							tbMenuCurrentSection:kill(true)
							TB_LAST_MENU_SCREEN_OPEN = v.sectionId
							for i, v in pairs(tbMenuNavigationButtons) do
								v.bgColor = { 0.2, 0.2, 0.2, 0 }
							end
							tbMenuNavigationButtons[i].bgColor = TB_NAVBAR_DEFAULT_BG_COLOR
							TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
						end
					else
						if (customNavHighlight) then
							if (v.sectionId ~= selectedId and v.sectionId ~= -1) then
								selectedId = v.sectionId
								for i, v in pairs(tbMenuNavigationButtons) do
									v.bgColor = { 0.2, 0.2, 0.2, 0 }
								end
								tbMenuNavigationButtons[i].bgColor = TB_NAVBAR_DEFAULT_BG_COLOR
							end
						end
						v.action()
					end
				end, nil)
		end
	end

	function TBMenu:getNearbyMenu(dir)
		local buttons = TBMenu:getMainNavigationButtons()
		local prev, next, found
		for i,v in pairs(buttons) do
			if (found) then
				next = v
				break
			end
			if (v.sectionId == TB_LAST_MENU_SCREEN_OPEN) then
				found = v
			end
			if (not found) then
				prev = v
			end
		end
		if (not found) then
			return nil
		end
		
		if (dir) then
			if (found.right) then
				if (not next) then
					return prev.sectionId
				end
				return buttons[1].sectionId
			end
			if (next.right) then
				return buttons[#buttons].sectionId
			end
			return next.sectionId
		end
		if (found.right) then
			if (next) then
				return next.sectionId
			end
			local rval
			for i,v in pairs(buttons) do
				if (v.right) then
					return rval
				end
				rval = v.sectionId
			end
		end
		if (not prev) then
			for i,v in pairs(buttons) do
				if (v.right) then
					return v.sectionId
				end
			end
		end
		return prev.sectionId
	end

	function TBMenu:getMainNavigationButtons()
		local buttonData = {
			{ text = TB_MENU_LOCALIZED.NAVBUTTONNEWS, sectionId = 1 },
			{ text = TB_MENU_LOCALIZED.NAVBUTTONPLAY, sectionId = 2 },
			{ text = TB_MENU_LOCALIZED.NAVBUTTONPRACTICE, sectionId = 3 },
			{ text = TB_MENU_LOCALIZED.NAVBUTTONSTORE, sectionId = 6 },
			{ text = TB_MENU_LOCALIZED.NAVBUTTONMARKET, sectionId = 10 },
			{ text = TB_MENU_LOCALIZED.MAINMENUCLANSNAME, sectionId = 9 },
			{ text = TB_MENU_LOCALIZED.NAVBUTTONTOOLS, sectionId = 5, right = true },
			--{ text = TB_MENU_LOCALIZED.NAVBUTTONACCOUNT, sectionId = 7, right = true },
		}
		if (TB_MENU_PLAYER_INFO.username == '') then
			buttonData[6] = nil
		end
		--[[if (TB_MENU_PLAYER_INFO.data.qi >= 500) then
			table.insert(buttonData, { text = TB_MENU_LOCALIZED.MAINMENURANKEDNAME, sectionId = 8, right = true })
		end]]
		return buttonData
	end

	function TBMenu:showBottomBar(leftOnly)
		local buttonSize = 50 * TB_MENU_GLOBAL_SCALE
		tbMenuBottomLeftBar = tbMenuBottomLeftBar or UIElement:new( {
			parent = tbMenuMain,
			pos = { 45 * TB_MENU_GLOBAL_SCALE, -buttonSize / 5 * 7 },
			size = { 110 * TB_MENU_GLOBAL_SCALE, buttonSize }
		})
		local shopCheckExit = function()
			if (STORE_VANILLA_PREVIEW) then
				STORE_VANILLA_PREVIEW = false
				remove_hooks("storevanillapreview")
				set_option("uke", 1)
				tbMenuHide:show()
				storeVanillaHolder:kill()
				STORE_VANILLA_POST = true
				start_new_game()
			end
		end
		local tbMenuBottomLeftButtonsData = {
			{ action = function() if (TB_MENU_SPECIAL_SCREEN_ISOPEN ~= 8) then TBMenu:showFriendsList() else FriendsList:quit() end end, image = TB_MENU_FRIENDS_BUTTON, imageHover = TB_MENU_FRIENDS_BUTTON_HOVER, imagePress = TB_MENU_FRIENDS_BUTTON_PRESS },
			{ action = function() if (TB_MENU_SPECIAL_SCREEN_ISOPEN ~= 4) then TBMenu:showNotifications() else Notifications:quit() end end, image = TB_MENU_NOTIFICATIONS_BUTTON, imageHover = TB_MENU_NOTIFICATIONS_BUTTON_HOVER, imagePress = TB_MENU_NOTIFICATIONS_BUTTON_PRESS },
			{ action = function() if (TB_MENU_SPECIAL_SCREEN_ISOPEN ~= 7) then TBMenu:showBounties() else Bounty:quit() end end, image = TB_MENU_BOUNTY_BUTTON, imageHover = TB_MENU_BOUNTY_BUTTON_HOVER, imagePress = TB_MENU_BOUNTY_BUTTON_PRESS },
			{ action = function() usage_event("discord") open_url("https://toribash.com/discord.php") end, image = TB_MENU_DISCORD_BUTTON, imageHover = TB_MENU_DISCORD_BUTTON_HOVER, imagePress = TB_MENU_DISCORD_BUTTON_PRESS }
		}
		local tbMenuBottomLeftButtons = {}
		for i, v in pairs(tbMenuBottomLeftButtonsData) do
			tbMenuBottomLeftButtons[i] = TBMenu:createImageButtons(tbMenuBottomLeftBar, (i - 1) * (tbMenuBottomLeftBar.size.h + 10), 0, tbMenuBottomLeftBar.size.h, tbMenuBottomLeftBar.size.h, v.image, v.imageHover, v.imagePress)
			tbMenuBottomLeftButtons[i]:addMouseHandlers(nil, function() shopCheckExit() v.action() end, nil)
		end
		local notificationsCountWidth = get_string_length(TB_MENU_NOTIFICATIONS_COUNT + TB_MENU_NOTIFICATIONS_NET_COUNT + TB_MENU_QUESTS_GLOBAL_COUNT + TB_MENU_QUESTS_COUNT, FONTS.MEDIUM) * 0.9
		notificationsCountWidth = notificationsCountWidth > tbMenuBottomLeftBar.size.h / 2 and (notificationsCountWidth > tbMenuBottomLeftBar.size.h and tbMenuBottomLeftBar.size.h or notificationsCountWidth) or tbMenuBottomLeftBar.size.h / 2
		tbMenuNotificationsCount = UIElement:new({
			parent = tbMenuBottomLeftButtons[2],
			pos = { -notificationsCountWidth, 0 },
			size = { notificationsCountWidth, tbMenuBottomLeftBar.size.h / 2 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = tbMenuBottomLeftBar.size.h
		})
		tbMenuNotificationsCount:addCustomDisplay(false, function()
				tbMenuNotificationsCount:uiText(TB_MENU_NOTIFICATIONS_COUNT + TB_MENU_NOTIFICATIONS_NET_COUNT + TB_MENU_QUESTS_GLOBAL_COUNT + TB_MENU_QUESTS_COUNT + TB_MENU_QUEST_NOTIFICATIONS, nil, nil, FONTS.MEDIUM, nil, 0.7, 0.4)
			end)
		tbMenuBottomLeftButtons[2]:addCustomDisplay(true, function()
				if (TB_MENU_NOTIFICATIONS_COUNT + TB_MENU_NOTIFICATIONS_NET_COUNT + TB_MENU_QUESTS_GLOBAL_COUNT + TB_MENU_QUESTS_COUNT == 0) then
					tbMenuNotificationsCount:hide()
					tbMenuNotificationsCount.hidden = true
				elseif (tbMenuNotificationsCount.hidden) then
					tbMenuNotificationsCount:show()
					tbMenuNotificationsCount.hidden = false
				end
			end)
		tbMenuBottomLeftBar.size.w = #tbMenuBottomLeftButtonsData * (tbMenuBottomLeftBar.size.h + 10)
		if (leftOnly) then
			return
		end

		tbMenuBottomRightBar = tbMenuBottomRightBar or UIElement:new({
			parent = tbMenuMain,
			pos = { -145 * TB_MENU_GLOBAL_SCALE, -buttonSize / 5 * 7 },
			size = { 110 * TB_MENU_GLOBAL_SCALE, buttonSize }
		})
		local tbMenuBottomRightButtonsData = {
			{ action = function() open_menu(4) end, image = TB_MENU_QUIT_BUTTON, imageHover = TB_MENU_QUIT_BUTTON_HOVER, imagePress = TB_MENU_QUIT_BUTTON_PRESS },
			{ action = function() TBMenu:showSettings() end, image = TB_MENU_SETTINGS_BUTTON, imageHover = TB_MENU_SETTINGS_BUTTON_HOVER, imagePress = TB_MENU_SETTINGS_BUTTON_PRESS }
		}
		local tbMenuBottomRightButtons = {}
		for i,v in pairs(tbMenuBottomRightButtonsData) do
			tbMenuBottomRightButtons[i] = TBMenu:createImageButtons(tbMenuBottomRightBar, -i * (tbMenuBottomRightBar.size.h + 10), 0, tbMenuBottomRightBar.size.h, tbMenuBottomRightBar.size.h, v.image, v.imageHover, v.imagePress)
			tbMenuBottomRightButtons[i]:addMouseHandlers(nil, function() shopCheckExit() v.action() end, nil)
		end
		local tbMenuDownloads = UIElement:new({
			parent = tbMenuMain,
			pos = { -300, -25 },
			size = { 300, 25 }
		})
		tbMenuDownloads:addCustomDisplay(true, function()
				local downloads = #get_downloads() or 0
				if (downloads > 0) then
					tbMenuDownloads:uiText(TB_MENU_LOCALIZED.DOWNLOADINGFILESWAIT, -10, nil, 4, RIGHTMID, 0.5, nil, nil, UICOLORBLACK)
				end
			end)
		local tbMenuVersion = UIElement:new({
			parent = tbMenuMain,
			pos = { -25, -25 },
			size = { 300, 25 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.001 },
			hoverColor = { 0, 0, 0, 1 },
			pressedColor = { 0, 0, 0, 1 }
		})
		tbMenuVersion:addCustomDisplay(true, function()
				local downloads = #get_downloads() or 0
				if (downloads == 0) then
					tbMenuVersion:uiText("Toribash " .. TORIBASH_VERSION .. (BETA_VERSION or '') .. " build ver " .. BUILD_VERSION, -280, nil, 4, RIGHTMID, 0.5, nil, nil, tbMenuVersion:getButtonColor())
				end
			end)
	end
	
	function TBMenu:playMenuSwitchAnimation()
		if (UIMODE_LIGHT) then return end
		local speedMod = get_option("framerate") == 30 and 2 or 1
		local currentSectionMover = UIElement:new({
			parent = tbMenuMain,
			pos = { -tbMenuMain.size.w + tbMenuCurrentSection.shift.x, tbMenuCurrentSection.shift.y },
			size = { tbMenuCurrentSection.size.w, tbMenuCurrentSection.size.h }
		})
		for i,v in pairs(tbMenuCurrentSection.child) do
			table.insert(currentSectionMover.child, v)
			v.parent = currentSectionMover
		end
		tbMenuCurrentSection.child = {}
		local rad = math.pi / 3
		currentSectionMover:addCustomDisplay(true, function()
				if (-currentSectionMover.pos.x >= currentSectionMover.size.w) then
					currentSectionMover:kill()
				end
				currentSectionMover:moveTo(-WIN_W / 10 * math.sin(rad) * speedMod, nil, true)
			end)
			
		tbMenuCurrentSection:moveTo(WIN_W)
		tbMenuCurrentSection:addCustomDisplay(true, function()
				tbMenuCurrentSection:moveTo(-WIN_W / 10 * math.sin(rad) * speedMod, nil, true)
				rad2 = rad + math.pi / 50
				if (tbMenuCurrentSection.shift.x <= 75 * TB_MENU_GLOBAL_SCALE) then
					tbMenuCurrentSection:moveTo(75 * TB_MENU_GLOBAL_SCALE)
					tbMenuCurrentSection:addCustomDisplay(true, function() end)
				end
		end)
	end

	function TBMenu:showMain(noload)
		local mainBgColor = nil
		tbMenuMain = UIElement:new( {
			globalid = TB_MENU_MAIN_GLOBALID,
			pos = { 0, 0 },
			size = { WIN_W, WIN_H },
			uiColor = TB_MENU_UI_TEXT_COLOR,
			uiShadowColor = TB_MENU_UI_TEXT_SHADOW_COLOR
		})
		local tbMenuBackground = UIElement:new({
			parent = tbMenuMain,
			pos = { 0, - WIN_H * 2 },
			size = { WIN_W, WIN_H * 3 },
			bgColor = { 0, 0, 0, 0 }
		})
		if (enable_blur() == 0) then
			tbMenuBackground.bgColor = {0, 0, 0, 0.1}
		else
			BLURENABLED = true
		end
		tbMenuHide = TBMenu:createImageButtons(tbMenuMain, WIN_W / 2 - 32, -74, 64, 64, "../textures/menu/general/buttons/arrowbot.tga", nil, nil, {0, 0, 0, 0}, { 0, 0, 0, 0.2 }, { 0, 0, 0, 0.4}, 32)
		tbMenuHide.state = 0
		tbMenuHide:addMouseHandlers(nil, function()
				if (tbMenuHide.state == 0) then
					tbMenuHide.state = -1
					tbMenuHide.progress = -math.pi/6
					disable_blur()
				elseif (tbMenuHide.state == 2) then
					tbMenuHide.state = 1
					tbMenuHide.progress = math.pi / 2
				end
			end, nil)
		tbMenuHide:addCustomDisplay(false, function()
				if (tbMenuHide.state == -1) then
					tbMenuHide.progress = tbMenuHide.progress + math.pi / 40
					tbMenuMain:moveTo(nil, tbMenuMain.pos.y + (WIN_H / 15) * math.sin(tbMenuHide.progress))
					tbMenuHide:moveTo(nil, -tbMenuMain.pos.y - 74)
					if (not BLURENABLED) then
						tbMenuBackground.bgColor[4] = tbMenuBackground.bgColor[4] - (0.1 / 15) * math.sin(tbMenuHide.progress)
					end
					if (tbMenuMain.pos.y >= WIN_H) then
						for i = 1, 3 do
							tbMenuHide.child[i]:updateImage("../textures/menu/general/buttons/arrowtop.tga")
						end
						tbMenuMain:moveTo(nil, WIN_H)
						tbMenuHide:moveTo(nil, -tbMenuMain.pos.y - 74)
						tbMenuHide.state = 2
						tbMenuBackground.bgColor[4] = 0
					end
				elseif (tbMenuHide.state == 1) then
					tbMenuHide.progress = tbMenuHide.progress + math.pi / 50
					tbMenuMain:moveTo(nil, tbMenuMain.pos.y - (WIN_H / 15) * math.sin(tbMenuHide.progress))
					tbMenuHide:moveTo(nil, -tbMenuMain.pos.y - 74)
					if (not BLURENABLED) then
						tbMenuBackground.bgColor[4] = tbMenuBackground.bgColor[4] + (0.1 / 15) * math.sin(tbMenuHide.progress)
					end
					if (tbMenuMain.pos.y <= 0) then
						for i = 1, 3 do
							tbMenuHide.child[i]:updateImage("../textures/menu/general/buttons/arrowbot.tga")
						end
						tbMenuMain:moveTo(nil, 0)
						tbMenuHide:moveTo(nil, -tbMenuMain.pos.y - 74)
						tbMenuHide.state = 0
						if (enable_blur() == 0) then
							tbMenuBackground.bgColor[4] = 0.1
						end
					end
				end
			end, false)
		local splatLeftImg = TB_MENU_BLOODSPLATTER_LEFT
		local splatCustom = false
		local customLogo = io.open("custom/" .. TB_MENU_PLAYER_INFO.username .. "/splatt1.tga", "r", 1)
		if (customLogo) then
			splatLeftImg = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/splatt1.tga"
			splatCustom = true
			customLogo:close()
		end
		local splatLeft = UIElement:new( {
			parent = tbMenuMain,
			pos = { 10, 200 },
			size = { WIN_H - 320, WIN_H - 320 },
			bgImage = splatLeftImg
		})
		local splatRight = UIElement:new( {
			parent = tbMenuMain,
			pos = { -(WIN_H - 320) - 10, 200 },
			size = { WIN_H - 320, WIN_H - 320 },
			bgImage = splatCustom and splatLeftImg or TB_MENU_BLOODSPLATTER_RIGHT
		})
		
		local menuNavigationScroll = UIElement:new({
			parent = tbMenuMain,
			pos = { 0, 0 },
			size = { 0, 0 },
			interactive = true
		})
		menuNavigationScroll.scrollEnabled = true
		menuNavigationScroll.lastTime = 0
		menuNavigationScroll:addCustomDisplay(true, function() end)
		menuNavigationScroll:addMouseHandlers(function(s)
				local clocktime = math.floor(os.clock() * 2 + 0.5) / 2
				-- Mouse scroll can trigger multiple times per frame for some reason, we don't want that
				if (menuNavigationScroll.lastTime == clocktime or TB_MENU_SPECIAL_SCREEN_ISOPEN ~= 0) then
					return
				end
				local id = TBMenu:getNearbyMenu(s == 5)
				if (id) then
					TB_LAST_MENU_SCREEN_OPEN = id
					--TBMenu:playMenuSwitchAnimation()
					TBMenu:clearNavSection()
					TBMenu:showNavigationBar()
					TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
					menuNavigationScroll.lastTime = clocktime
				end
			end)
		
		TBMenu:showGameLogo()
		TBMenu:showUserBar()
		TBMenu:showNavigationBar()
		TBMenu:showBottomBar()
		if (not noload) then
			TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
		end
	end

	-- Displays login error
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

	function TBMenu:spawnDropdown(holderElement, listElements, elementHeight, maxHeight, selectedItem, textSettings, listTextSettings, keepFocus, noOverlaying)
		local listElementsDisplay = {}
		for i,v in pairs(listElements) do
			if (not v.default) then
				table.insert(listElementsDisplay, v)
			end
		end
		
		local maxHeight = maxHeight or #listElementsDisplay * elementHeight + 4
		if (maxHeight > #listElementsDisplay * elementHeight + 4) then
			maxHeight = #listElementsDisplay * elementHeight + 4
		end
		local selectedItem = selectedItem or listElements[1]
		if (type(selectedItem) ~= "table") then
			selectedItem = listElements[selectedItem] or listElements[1]
		end
		local textSettings = textSettings or {}
		textSettings.fontid = textSettings.fontid or 4
		textSettings.scale = textSettings.scale or 1
		textSettings.orientation = textSettings.orientation or LEFTMID
		
		local listTextSettings = listTextSettings or {}
		listTextSettings.fontid = listTextSettings.fontid or 4
		listTextSettings.scale = listTextSettings.scale or 1
		listTextSettings.orientation = listTextSettings.orientation or CENTERMID
		
		local overlay = UIElement:new({
			parent = holderElement,
			pos = { 0, 0 },
			size = { WIN_W, WIN_H },
			interactive = not keepFocus,
			scrollEnabled = true
		})
		local dropdownView = UIElement:new({
			parent = overlay,
			pos = { 0, 0 },
			size = { holderElement.size.w, maxHeight },
			bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = holderElement.shapeType,
			rounded = holderElement.rounded and holderElement.rounded * 4 / 3 or 0
		})
		overlay:addMouseHandlers(function(s)
				if (s >= 4) then
					overlay:hide(true)
				end
			end, function()
				overlay:hide(true)
			end)
		local function updatePos(t)
			t:updateChildPos()
			for i,v in pairs(t.child) do
				updatePos(v)
			end
		end
		
		local addedShift = noOverlaying and elementHeight or 0
		dropdownView:addCustomDisplay(false, function()
				overlay.pos.x = 0
				overlay.pos.y = 0
				for i,v in pairs(overlay.child) do
					v:updateChildPos()
				end
				local dropdownPosY = holderElement.pos.y + addedShift + maxHeight > WIN_H - 25 and (holderElement.pos.y - maxHeight < 25 and WIN_H - 25 - maxHeight - addedShift or holderElement.pos.y - maxHeight) or holderElement.pos.y + addedShift
				dropdownView:moveTo(holderElement.pos.x, dropdownPosY)
				dropdownView.pos.x = overlay.pos.x + dropdownView.shift.x
				dropdownView.pos.y = overlay.pos.y + dropdownView.shift.y
				for i,v in pairs(dropdownView.child) do
					updatePos(v)
				end
			end, true)
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
		selectedElementText:addAdaptedText(false, selectedItem.text:upper(), nil, nil, textSettings.fontid, textSettings.orientation, textSettings.scale)
		local selectedElementArrow = UIElement:new({
			parent = selectedElement,
			pos = { -selectedElement.size.h, 0 },
			size = { selectedElement.size.h, selectedElement.size.h },
			bgImage = "../textures/menu/general/buttons/arrowbotwhite.tga"
		})
		
		local toReload, topBar, botBar, listingView, listingHolder
		if (#listElementsDisplay * elementHeight > maxHeight) then
			toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(dropdownView, elementHeight, elementHeight, 15, TB_MENU_DEFAULT_LIGHTER_COLOR)
			local topEdge = UIElement:new({
				parent = topBar,
				pos = { 0, -topBar.size.h - (dropdownView.rounded or 0) },
				size = { topBar.size.w, topBar.size.h * 1.5 },
				bgColor = topBar.bgColor,
				innerShadow = elementHeight / 2,
				shadowColor = { holderElement.bgColor, { 0, 0, 0, 0 } },
				shapeType = dropdownView.shapeType,
				rounded = dropdownView.rounded
			})
			local botEdge = UIElement:new({
				parent = botBar,
				pos = { 0, -botBar.size.h * 1.5 + (dropdownView.rounded or 0) },
				size = { botBar.size.w, botBar.size.h * 1.5 },
				bgColor = botBar.bgColor,
				innerShadow = elementHeight / 2,
				shadowColor = { { 0, 0, 0, 0 }, holderElement.bgColor },
				shapeType = dropdownView.shapeType,
				rounded = dropdownView.rounded
			})
		else
			listingHolder = dropdownView
		end
		
		local listElements = {}
		for i,v in pairs(listElementsDisplay) do
			local element = UIElement:new({
				parent = listingHolder,
				pos = { 2, 2 + (i - 1) * elementHeight },
				size = { listingHolder.size.w - 4, elementHeight },
				interactive = true,
				bgColor = selectedItem == v and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_LIGHTER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
				inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS,
				shapeType = holderElement.shapeType,
				rounded = holderElement.rounded
			})
			v.element = element
			table.insert(listElements, element)
			if (v.locked) then
				element.uiColor = cloneTable(UICOLORBLACK)
				element:deactivate(true)
			end
			element:addChild({ shift = { 10, 1 }}):addAdaptedText(false, v.text:upper(), nil, nil, listTextSettings.fontid, listTextSettings.orientation, listTextSettings.scale)
			element:addMouseHandlers(nil, function()
					overlay:hide(true)
					selectedElementText:addAdaptedText(false, v.text:upper(), nil, nil, textSettings.fontid, textSettings.orientation, textSettings.scale)
					selectedElement:show()
					if (selectedItem == v) then
						return
					end
					if (selectedItem and selectedItem.element) then
						selectedItem.element.bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR
					end
					v.element.bgColor = TB_MENU_DEFAULT_BG_COLOR
					selectedItem = v
					if (v.action) then
						v.action()
					end
				end)
		end
		
		if (#listElements * elementHeight > maxHeight) then
			local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
			listingHolder.scrollBar = scrollBar
			scrollBar:makeScrollBar(listingHolder, listElements, toReload)
			
			overlay.listElements = listElements
			overlay.listHolder = listingHolder
			overlay.listReload = toReload
		end
		
		selectedElement:addMouseHandlers(nil, function()
				overlay:show(true)
				if (overlay.listElements) then
					for i,v in pairs(overlay.listElements) do
						v:hide()
					end
					overlay.listHolder.scrollBar:makeScrollBar(overlay.listHolder, overlay.listElements, overlay.listReload)
				end
			end)
		overlay:hide(true)
		
		overlay.selectedElement = selectedElement
		return overlay
	end

	-- Spawns default menu scroll bar
	function TBMenu:spawnScrollBar(holderElement, listElements, elementHeight)
		local scrollActive = true
		local scrollScale = listElements > 0 and (holderElement.size.h) / (listElements * elementHeight) or holderElement.size.h
		if (scrollScale >= 1) then
			scrollScale = 1
			scrollActive = false
		elseif (scrollScale < 0.1) then
			scrollScale = 0.1
		end

		local scrollBackground = UIElement:new({
			parent = holderElement.parent,
			pos = { -holderElement.parent.size.w + holderElement.size.w, 0 },
			size = { holderElement.parent.size.w - holderElement.size.w, holderElement.size.h },
			bgColor = holderElement.scrollBG and holderElement.scrollBG.bgColor
		})
		local scrollView = UIElement:new({
			parent = holderElement.parent,
			pos = { -(holderElement.parent.size.w - holderElement.size.w) / 4 * 3, 5 },
			size = { (holderElement.parent.size.w - holderElement.size.w) / 2, holderElement.size.h - 10 }
		})
		local scrollBar = UIElement:new({
			parent = scrollView,
			pos = { 0, 0 },
			size = { scrollView.size.w, scrollView.size.h * scrollScale },
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
	
	-- Draws quarter disks that cover element's corners for a fake rounded effect
	-- Designed to use with images on single color backgrounds
	-- To make regular UIElements rounded, use shapeType and rounded params
	function TBMenu:addOuterRounding(e, color, rounding)
		if (UIMODE_LIGHT) then return end
		
		local color = color or TB_MENU_DEFAULT_BG_COLOR
		local rounding = rounding or 5
		local roundingWidth = rounding * 1.4
		
		e:addChild({}):addCustomDisplay(true, function()
				set_color(unpack(color))
				draw_disk(e.pos.x + rounding, e.pos.y + rounding, rounding, roundingWidth, 100, 1, -180, 90, 0)
				draw_disk(e.pos.x + e.size.w - rounding, e.pos.y + rounding, rounding, roundingWidth, 100, 1, 90, 90, 0)
				draw_disk(e.pos.x + rounding, e.pos.y + e.size.h - rounding, rounding, roundingWidth, 100, 1, 0, -90, 0)
				draw_disk(e.pos.x + e.size.w - rounding, e.pos.y + e.size.h - rounding, rounding, roundingWidth, 100, 1, 0, 90, 0)
			end)
	end
	
	function TBMenu:generatePaginationData(totalPages, maxPages, currentPage)
		local pagesButtonsPre, pagesButtons = {}, {}
		
		local showPrev, showNext
		local pagesNavArr = { 10, 50, 100, 500 }
		
		local page = 0
		local navPages = math.floor(maxPages / 2)
		
		-- Potentially slower but produces better results
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
			local sorted = qsort(pages, 'v')
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
		
		for i,v in pairs(sorted) do
			table.insert(pagesButtons, v.v)
		end
		
		
		-- Basically what we use for pagination on forums
		-- Quicker but may not be looking nice - I'm not sure how to properly limit number of buttons
		--[[while (page < totalPages) do
			page = page + 1
			
			local added = false
			if (math.abs(page - currentPage) >= navPages) then
				if (page == 1 or page == totalPages) then
					table.insert(pagesButtons, page)
					added = true
				elseif(in_array(math.abs(page - currentPage), pagesNavArr)) then
					table.insert(pagesButtons, page)
					added = true
				end
			else
				table.insert(pagesButtons, page)
				added = true
			end
			
			if (not added) then
				if (currentPage > 1 and page == currentPage - 1) then
					table.insert(pagesButtons, page)
				elseif (currentPage < totalPages and page == currentPage + 1) then
					table.insert(pagesButtons, page)
				end
			end
		end]]
		
		return pagesButtons
	end

	function TBMenu:displayLoadingMark(element, message, size)
		local size = size or 20
		local loadMark = UIElement:new({
			parent = element,
			pos = { 0, 0 },
			size = { element.size.w, element.size.h }
		})
		local grow, rotate = 0, 0
		loadMark:addCustomDisplay(true, function()
				set_color(unpack(loadMark.uiColor or UICOLORWHITE))
				draw_disk(loadMark.pos.x + loadMark.size.w / 2, loadMark.pos.y + loadMark.size.h / 2 - (message and 40 or 0), size * 0.6, size, 500, 1, rotate, grow, 0)
				grow = grow + 4
				rotate = rotate + 2
				if (grow >= 360) then
					grow = -360
				end
			end)
		if (message) then
			local textView = UIElement:new({
				parent = loadMark,
				pos = { 10, loadMark.size.h / 2 },
				size = { loadMark.size.w - 20, loadMark.size.h }
			})
			textView:addAdaptedText(true, message, nil, nil, nil, CENTER)
		end
	end
	
	function TBMenu:displayLoadingMarkSmall(viewElement, message, fontid, loadScale, fontScale)
		local fontid = fontid or FONTS.MEDIUM
		local loadScale = loadScale or 26
		if (loadScale > viewElement.size.h) then
			loadScale = viewElement.size.h
		end
		local textView = UIElement:new({
			parent = viewElement,
			pos = { loadScale * 0.8, 0 },
			size = { viewElement.size.w - loadScale * 1.2, viewElement.size.h }
		})
		textView:addAdaptedText(false, message, loadScale * 0.7, nil, fontid, nil, fontScale)
		local fontid = textView.textFont
		local posX = get_string_length(textView.dispstr[1], fontid) * textView.textScale
		local loadElement = UIElement:new({
			parent = textView,
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
	
	function TBMenu:showTextWithImage(viewElement, text, fontid, imgScale, imgWhite, imgBlack, left)
		local imgScale = imgScale or 26
		if (imgScale > viewElement.size.h) then
			imgScale = viewElement.size.h
		end
		local imgBlack = imgBlack or imgWhite
		local textView = UIElement:new({
			parent = viewElement,
			pos = { imgScale * 0.8, 0 },
			size = { viewElement.size.w - imgScale * 1.15, viewElement.size.h }
		})
		textView:addAdaptedText(true, text, left and imgScale * 0.7 or -imgScale * 0.7, nil, fontid, nil, nil, nil, fontid == FONTS.BIG and 0.5)
		
		local fontid = textView.textFont
		local textScale = textView.textScale
		local posX = 0
		for i,v in pairs(textView.dispstr) do
			local lineWidth = get_string_length(v, fontid)
			if (lineWidth > posX) then
				posX = lineWidth
			end
		end
		posX = posX * textScale
		local bgColorDelta = viewElement.bgColor[1] + viewElement.bgColor[2] + viewElement.bgColor[3]
		local imageElement = UIElement:new({
			parent = textView,
			pos = { (textView.size.w + (left and (-posX - imgScale) or (posX - imgScale))) / 2, (textView.size.h - imgScale) / 2 },
			size = { imgScale, imgScale },
			bgImage = bgColorDelta > 1.5 and imgBlack or imgWhite
		})
	end
	
	function TBMenu:showTextExternal(viewElement, text)
		TBMenu:showTextWithImage(viewElement, text, FONTS.MEDIUM, 26, "../textures/menu/general/buttons/external.tga", "../textures/menu/general/buttons/externalblack.tga")
	end

	function TBMenu:displayHelpPopup(element, message, forceManualPosCheck, noMark)
		local messageElement = UIElement:new({
			parent = element,
			pos = { 0, 0 },
			size = { WIN_W / 3, WIN_H / 7 },
			bgColor = { 0, 0, 0, 0.8 },
			uiColor = UICOLORWHITE,
			shapeType = ROUNDED,
			rounded = 5
		})

		if (not forceManualPosCheck) then
			if (messageElement.pos.x < 0) then
				messageElement:moveTo(messageElement:getLocalPos(10, 0).x)
			end
			if (messageElement.pos.y < 0) then
				messageElement:moveTo(nil, messageElement:getLocalPos(0, 10).y)
			end
			if (messageElement.pos.x + messageElement.size.w > WIN_W) then
				messageElement:moveTo((WIN_W - messageElement.pos.x - messageElement.size.w) - 10, nil, true)
			end
			if (messageElement.pos.y + messageElement.size.h > WIN_H) then
				messageElement:moveTo(nil, (WIN_H - messageElement.pos.y - messageElement.size.h) - 10, true)
			end
		end

		local messageText = UIElement:new({
			parent = messageElement,
			pos = { 10, 5 },
			size = { messageElement.size.w - 20, messageElement.size.h - 10 }
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
		local pressTime = 0

		if (forceManualPosCheck) then
			element:addCustomDisplay(false, function()
					if (not messageElement or messageElement.destroyed) then return end
					if (not TB_MENU_POPUPS_DISABLED and MOUSE_X > element.pos.x and MOUSE_Y > element.pos.y and MOUSE_X < element.pos.x + element.size.w and MOUSE_Y < element.pos.y + element.size.h) then
						element.hoverState = element.hoverState == nil and BTN_HVR or element.hoverState
						if (not popupShown) then
							pressTime = pressTime + 0.07
							if (pressTime > 1) then
								messageElement:show(true)
								popupShown = true
							end
						end
					elseif (popupShown) then
						messageElement:hide(true)
						pressTime = 0
						popupShown = false
					end
				end, true)
		else
			element:addCustomDisplay(false, function()
					if (not messageElement or messageElement.destroyed) then return end
					if (not TB_MENU_POPUPS_DISABLED and element.hoverState == BTN_HVR) then
						if (not popupShown) then
							pressTime = pressTime + 0.07
							if (pressTime > 1) then
								messageElement:show(true)
								popupShown = true
							end
						end
					elseif (popupShown) then
						if (not element.hoverState) then
							messageElement:hide(true)
							pressTime = 0
							popupShown = false
						end
					end
				end, true)
		end
		
		if (not noMark) then
			local questionmark = UIElement:new({
				parent = element,
				pos = { 0, 0 },
				size = { element.size.w, element.size.h }
			})
			questionmark:addAdaptedText(true, "?", nil, nil, nil, nil, 0.7)
		end
		
		return messageElement
	end
	
	function TBMenu:displayPopup(element, message, forceManualPosCheck)
		return TBMenu:displayHelpPopup(element, message, forceManualPosCheck, true)
	end
	
	function TBMenu:spawnSlider(parent, x, y, w, h, textWidth, sliderRadius, value, settings, sliderFunc, onMouseDown, onMouseUp)
		local x = x or 0
		local y = y or 0
		local w = w or parent.size.w - x * 2
		local h = h or parent.size.h - y * 2
		local textWidth = textWidth or w / 8
		local sliderRadius = sliderRadius or 20
		
		local settings = settings or {}
		settings.maxValue = settings.maxValue or 1
		settings.minValue = settings.minValue or 0
		settings.maxValueDisp = settings.maxValueDisp or settings.maxValue
		settings.minValueDisp = settings.minValueDisp or settings.minValue
		settings.decimal = settings.decimal or 0
		local value = value or minVal
		
		local minText = UIElement:new({
			parent = parent,
			pos = { x, y },
			size = { textWidth, h }
		})
		minText:addAdaptedText(false, settings.minValueDisp .. "", nil, nil, 4, RIGHTMID, 0.7)
		local maxText = UIElement:new({
			parent = parent,
			pos = { -textWidth - x, y },
			size = { textWidth, h }
		})
		maxText:addAdaptedText(false, settings.maxValueDisp .. "", nil, nil, 4, LEFTMID, 0.7)
		
		local sliderBG = UIElement:new({
			parent = parent,
			pos = { x + textWidth + 5, y },
			size = { w - (textWidth + 5) * 2, h },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			interactive = true
		})
		sliderBG:addCustomDisplay(true, function()
				set_color(unpack(sliderBG.bgColor))
				draw_quad(sliderBG.pos.x, sliderBG.pos.y + h / 2 - 3, sliderBG.size.w, 6)
			end)
		local sliderPos = 0
		value = value > settings.maxValue and 1 or (-settings.minValue + value) / (-settings.minValue + settings.maxValue)
		sliderPos = value * (sliderBG.size.w - sliderRadius)
		local slider = UIElement:new({
			parent = sliderBG,
			pos = { sliderPos, (-sliderBG.size.h - sliderRadius) / 2 },
			size = { sliderRadius, sliderRadius },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			inactiveColor = { 0.5, 0.5, 0.5, 1 },
			shapeType = ROUNDED,
			rounded = sliderRadius
		})
		local sliderLabel = UIElement:new({
			parent = slider,
			pos = { -sliderRadius - 5, -slider.size.h - sliderRadius },
			size = { sliderRadius + 10, sliderRadius },
			bgColor = cloneTable(TB_MENU_DEFAULT_LIGHTER_COLOR),
			uiColor = cloneTable(UICOLORWHITE),
			shapeType = ROUNDED,
			rounded = 4
		})
		sliderLabel.bgColor[4] = 0
		sliderLabel.uiColor[4] = 0
		sliderLabel.labelText = { "" }
		sliderLabel:addCustomDisplay(false, function()
				if (sliderLabel.uiColor[4] > 0) then
					sliderLabel:uiText(sliderLabel.labelText[1], nil, nil, 4, nil, 0.5)
					if (not slider.pressed) then
						sliderLabel.uiColor[4] = sliderLabel.uiColor[4] - 0.02
						sliderLabel.bgColor[4] = sliderLabel.bgColor[4] - 0.02
					end
				end
			end)
		sliderLabel:addCustomDisplay(false, function()
				if (sliderLabel.uiColor[4] > 0) then
					-- Adapt label width to be able to fit the text
					local textWidth = get_string_length(sliderLabel.labelText[1], 4) * 0.5 + 16
					local targetWidth = textWidth > sliderRadius + 10 and textWidth or sliderRadius + 10
					if (targetWidth ~= sliderLabel.size.w) then
						sliderLabel.size.w = targetWidth
						sliderLabel:moveTo((-sliderRadius - sliderLabel.size.w) / 2)
					end
					
					-- If bounding element is defined, we may want to display label below the slider
					if (settings.boundParent) then
						if (sliderLabel.lastY ~= sliderLabel.shift.y) then
							if (settings.boundParent.pos.y >= slider.pos.y - sliderRadius) then
								sliderLabel:moveTo(nil, slider.size.h)
								sliderLabel:reload()
							else
								sliderLabel:moveTo(nil, -slider.size.h - sliderRadius)
								sliderLabel:reload()
							end
							sliderLabel.lastY = sliderLabel.pos.y
						end
					end
				end
			end, true)
			
		slider.settings = settings
		slider.label = sliderLabel
		slider:addMouseHandlers(function()
				slider.pressed = true
				slider.pressedPos = slider:getLocalPos()
				if (onMouseDown) then
					onMouseDown()
				end
			end, function()
				slider.pressed = false
				if (onMouseUp) then
					onMouseUp()
				end
			end, function()
				if (slider.pressed) then
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
					
					local val = xPos / (sliderBG.size.w - sliderRadius) * (settings.maxValue - settings.minValue) + settings.minValue
					local multiplyBy = tonumber('1' .. string.rep('0', settings.decimal))
					sliderLabel.labelText[1] = (math.floor(val * multiplyBy) / multiplyBy) .. ''
					sliderLabel.uiColor[4] = 1
					sliderLabel.bgColor[4] = 1
					
					if (sliderFunc) then
						sliderFunc(val, xPos, slider)
					end
				end
			end)
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
		sliderBG:addMouseHandlers(function()
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
			slider:moveTo(xPos)
			
			local val = xPos / (sliderBG.size.w - sliderRadius) * (settings.maxValue - settings.minValue) + settings.minValue
			local multiplyBy = tonumber('1' .. string.rep('0', settings.decimal))
			sliderLabel.labelText[1] = (math.floor(val * multiplyBy) / multiplyBy) .. ''
			sliderLabel.uiColor[4] = 1
			sliderLabel.bgColor[4] = 1
			
			if (sliderFunc) then
				sliderFunc(val, xPos, slider)
			end
		end)
		return slider
	end
	
	function TBMenu:spawnToggle(parent, x, y, w, h, toggleValue, updateFunc)
		local x = x or 0
		local y = y or 0
		local w = w or parent.size.h
		local h = h or parent.size.h
		
		local toggleBG = UIElement:new({
			parent = parent,
			pos = { x, y },
			size = { w, h },
			shapeType = parent.shapeType,
			rounded = parent.rounded,
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local toggleView = UIElement:new({
			parent = toggleBG,
			pos = { 1, 1 },
			size = { toggleBG.size.w - 2, toggleBG.size.h - 2 },
			shapeType = parent.shapeType,
			rounded = parent.rounded,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			interactive = true,
			toggle = true
		})
		toggleView:addCustomDisplay(nil, function()
				if (toggleView.keyboard and not toggleView.hoverState) then
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
				toggleView.hoverState = false
			end)
		local toggleIcon = UIElement:new({
			parent = toggleView,
			pos = { 0, 0 },
			size = { toggleView.size.w, toggleView.size.h },
			bgImage = "../textures/menu/general/buttons/checkmark.tga"
		})
		if (toggleValue == '0' or toggleValue == 0 or toggleValue == false) then
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
				updateFunc(toggleValue)
			end)
		return toggleView
	end

	function TBMenu:spawnTextField(parent, x, y, w, h, textFieldString, inputSettings, fontid, scale, color, defaultStr, orientation, noCursor, multiLine, darkerMode)
		if (not parent) then
			return false
		end
		local x = x or 0
		local y = y or 0
		local w = w or parent.size.w
		local h = h or parent.size.h
		local fontid = fontid or 4
		local color = color or cloneTable(UICOLORBLACK)
		local inputSettings = type(inputSettings) == "table" and inputSettings or { isNumeric = inputSettings }

		local textBg = UIElement:new({
			parent = parent,
			pos = { x, y },
			size = { w, h },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = parent.shapeType,
			rounded = parent.rounded
		})
		local input = UIElement:new({
			parent = textBg,
			pos = { 1, 1 },
			size = { textBg.size.w - 2, textBg.size.h - 2 },
			interactive = true,
			bgColor = darkerMode and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_LIGHTER_COLOR,
			hoverColor = darkerMode and TB_MENU_DEFAULT_LIGHTER_COLOR or TB_MENU_DEFAULT_LIGHTEST_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS,
			shapeType = textBg.shapeType,
			rounded = textBg.rounded
		})
		local inputField = UIElement:new({
			parent = input,
			pos = { 4, 1 },
			size = { input.size.w - 8, input.size.h - 2 },
			interactive = true,
			textfield = true,
			isNumeric = inputSettings.isNumeric,
			allowDecimal = inputSettings.allowDecimal,
			allowNegative = inputSettings.allowNegative,
			textfieldstr = textFieldString,
			textfieldsingleline = not multiLine,
			shapeType = textBg.shapeType,
			rounded = textBg.rounded
		})
		inputField:addMouseHandlers(function()
				inputField:enableMenuKeyboard()
			end)
		TBMenu:displayTextfield(inputField, fontid, scale, color, defaultStr, orientation, noCursor)
		return inputField
	end

	function TBMenu:displayTextfield(element, fontid, scale, color, defaultStr, orientation, noCursor)
		local defaultStr = defaultStr or ""
		local orientation = orientation or LEFTMID
		local scale = scale or 1
		
		element:addAdaptedText(true, defaultStr, nil, nil, fontid, orientation, scale, nil, nil, nil, nil, nil, true)
		local defaultStringScale = element.textScale

		element:addCustomDisplay(true, function()
				if (element.keyboard == true) then
					set_color(1, 1, 1, 0.2)
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
					
					local part1 = element.textfieldstr[1]:sub(0, element.textfieldindex)
					local part2 = element.textfieldstr[1]:sub(element.textfieldindex + 1)
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
end

-- Get translation here so other scripts that use menu manager have translation data
TBMenu:getTranslation(get_language())
