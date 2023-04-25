-- Events manager class
require('toriui.uielement')
require('system.menu_manager')
require('system.store_manager')
require('system.friends_manager')

do
	Events = {}
	Events.__index = Events
	local cln = {}
	setmetatable(cln, Events)

	function Events:quit()
		TBMenu.CurrentSection:kill(true)
		TBMenu.NavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TB_MENU_EVENTS_OPEN = false
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end

	function Events:getNavigationButtons(showBack, showEventid)
		local navigation = {
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
				action = function() Events:quit() end
			}
		}
		if (showBack) then
			table.insert(navigation, {
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = function() Events:showEventsHome(TBMenu.CurrentSection) end
			})
		end
		if (showEventid) then
			table.insert(navigation, {
				text = TB_MENU_LOCALIZED.EVENTSEVENTINFO,
				action = function() Events:showEventInfo(showEventid) end,
				right = true
			})
		end
		return navigation
	end

	function Events:loadMovember(viewElement)
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Events:getNavigationButtons(TB_MENU_EVENTS_OPEN), true)

		local loadingView = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(loadingView, 1)
		TBMenu:displayLoadingMark(loadingView, TB_MENU_LOCALIZED.EVENTSLOADING)

		local function throwError(text)
			loadingView:kill(true)
			TBMenu:addBottomBloodSmudge(loadingView, 1)
			loadingView:addAdaptedText(nil, text)
		end

		local playerData, showWelcome = {}, false
		loadingView:addCustomDisplay(false, function()
				if (get_network_task() == 0) then
					Request:new("movember19", function()
							local response = get_network_response()
							if (response:find("ERROR;")) then
								throwError(TB_MENU_LOCALIZED.ACCOUNTINFOERROR)
								return
							end
							for ln in response:gmatch("[^\n]*\n?") do
								local ln = ln:gsub("\n$", '')
								if (ln:find("^INVID 0;")) then
									playerData.invid = ln:gsub("INVID 0;", '') + 0
								elseif (ln:find("^ITEMID 0;")) then
									playerData.itemid = ln:gsub("ITEMID 0;", '') + 0
								elseif (ln:find("^GAMESPLAYED 0;")) then
									playerData.points = ln:gsub("GAMESPLAYED 0;", '') + 0
								elseif (ln:find("^UPGRADELVL 0;")) then
									playerData.level = ln:gsub("UPGRADELVL 0;", '') + 0
								elseif (ln:find("^FIRSTRUN 0;")) then
									showWelcome = true
								end
							end
							if (loadingView:isDisplayed()) then
								loadingView:kill()
								Events:showMovember(viewElement, playerData, showWelcome)
							end
						end, function()
							throwError(TB_MENU_LOCALIZED.REQUESTCONNECTIONERROR)
						end)
					download_server_info("movember19&username=" .. TB_MENU_PLAYER_INFO.username)
					loadingView:addCustomDisplay(false, function() end)
				end
			end)
	end

	function Events:showMovemberIntro()
		local overlay = TBMenu:spawnWindowOverlay()
		overlay.bgColor[4] = 0

		local mainView = UIElement:new({
			parent = overlay,
			pos = { overlay.size.w / 5, overlay.size.h / 8 },
			size = { overlay.size.w * 0.6, overlay.size.h / 3 * 2 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		mainView.bgColor[4] = 0

		local function showMain()
			local updater = UIElement:new({
				parent = mainView,
				pos = { 0, 0 },
				size = { 0, 0 }
			})
			local welcomeTitle = UIElement:new({
				parent = mainView,
				pos = { 20, 0 },
				size = { mainView.size.w - 40, mainView.size.h / 10 },
				uiColor = table.clone(TB_MENU_UI_TEXT_COLOR)
			})
			local welcomeTitleText = UIElement:new({
				parent = welcomeTitle,
				pos = { 0, welcomeTitle.size.h / 10 },
				size = { welcomeTitle.size.w, welcomeTitle.size.h * 0.8 }
			})
			local welcomeText = UIElement:new({
				parent = mainView,
				pos = { 20, welcomeTitle.shift.y + welcomeTitle.size.h },
				size = { mainView.size.w - 40, mainView.size.h / 4 },
				uiColor = table.clone(TB_MENU_UI_TEXT_COLOR)
			})
			local imageSize = mainView.size.h / 9 * 5
			local welcomeImage = UIElement:new({
				parent = mainView,
				pos = { (mainView.size.w - imageSize) / 2, welcomeText.shift.y + welcomeText.size.h },
				size = { imageSize, imageSize },
				bgImage = "../textures/menu/promo/events/movemberwelcome.tga"
			})
			local welcomeImageOverlay = UIElement:new({
				parent = welcomeImage,
				pos = { 0, 0 },
				size = { welcomeImage.size.w, welcomeImage.size.h },
				bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR)
			})
			local welcomeButton = UIElement:new({
				parent = mainView,
				pos = { mainView.size.w / 4, welcomeImage.shift.y + welcomeImage.size.h },
				size = { mainView.size.w / 2, mainView.size.h / 12 },
				interactive = true,
				bgColor = table.clone(TB_MENU_DEFAULT_DARKER_COLOR),
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				uiColor = table.clone(TB_MENU_UI_TEXT_COLOR)
			})
			welcomeTitleText:addAdaptedText(true, "Welcome to Toribash Movember!", nil, nil, FONTS.BIG)
			welcomeText:addAdaptedText(true, "Movember is an annual event involving the growing of moustaches to raise awareness of men's health issues.\nThis year, you can be a part of the movement by wearing your free moustache item in Toribash!\nUpgrade your stache to max level until the end of November and get the grand prize - limited Krakenstache item!", nil, nil, 4)
			welcomeButton:addAdaptedText(false, "Start growing your stache!")
			welcomeButton:addMouseHandlers(nil, function()
					overlay:kill()
				end)

			welcomeTitle.uiColor[4] = 0
			welcomeText.uiColor[4] = 0
			welcomeButton.bgColor[4] = 0
			welcomeButton.uiColor[4] = 0
			local rad, step = math.pi / 3, math.pi / 45
			updater:addCustomDisplay(true, function()
					framerate = 5
					local mod = math.sin(rad)
					rad = rad + step

					welcomeTitle.uiColor[4] = welcomeTitle.uiColor[4] + 0.09 * mod
					welcomeText.uiColor[4] = welcomeText.uiColor[4] + 0.09 * mod
					welcomeImageOverlay.bgColor[4] = welcomeImageOverlay.bgColor[4] - 0.09 * mod
					welcomeButton.uiColor[4] = welcomeButton.uiColor[4] + 0.09 * mod
					welcomeButton.bgColor[4] = welcomeButton.bgColor[4] + 0.09 * mod
					if (welcomeTitle.uiColor[4] >= 1) then
						updater:kill()
					end
				end)
		end

		local rad, step = math.pi / 3, math.pi / 45
		mainView:addCustomDisplay(false, function()
				local finished = false
				local mod = math.sin(rad)
				rad = rad + step

				overlay.bgColor[4] = overlay.bgColor[4] + 0.04 * mod
				mainView.bgColor[4] = mainView.bgColor[4] + 0.09 * mod
				mainView.shift.y = mainView.shift.y + overlay.size.h / 400 * mod

				if (mainView.shift.y >= overlay.size.h / 6) then
					mainView.bgColor[4] = 1
					mainView.shift.y = overlay.size.h / 6
					finished = true
				end

				if (finished) then
					mainView:addCustomDisplay(false, function() end)
					showMain()
				end
			end)
		return mainView
	end

	function Events:getMovemberProgressInfoText()
		return "- Playing games online with your moustache equipped (1 pt per game)\n- Completing quests (20 pts per quest, up to 3 per day)\n- Logging in daily (up to 75 pts for 7th day of consecutive logins)\n- Winning bets in active rooms (up to 5 pts per won bet)\n- Winning automatic tournaments (50 pts per tourney)\n- Winning ES events (100 pts per event)"
	end

	function Events:getStacheLevelPoints(points, current)
		local stachePointLevels = {
			0, 100, 250, 500, 1000, 2000
		}

		for i = 1, #stachePointLevels do
			if (stachePointLevels[i] > points and stachePointLevels[i - 1] <= points) then
				local i = current and i - 1 or i
				return stachePointLevels[i], i
			end
		end
		return stachePointLevels[#stachePointLevels], #stachePointLevels
	end

	function Events:showMovemberPlayerStats(viewElement, playerData)
		local viewTitle = UIElement:new({
			parent = viewElement,
			pos = { 20, 10 },
			size = { viewElement.size.w - 40, viewElement.size.h / 10 }
		})
		viewTitle:addAdaptedText(true, "My stache: lvl " .. playerData.level .. ', ' .. playerData.points .. " pts", nil, nil, FONTS.BIG, nil, nil, nil, 0.6)
		local progressDataPoints, progressDataLevel = Events:getStacheLevelPoints(playerData.points)
		local progressScale = viewTitle.size.w < viewTitle.size.h / 4 and viewTitle.size.h / 4 or viewTitle.size.w
		progressScale = progressScale > 512 and 512 or progressScale
		local progressOverlay = UIElement:new({
			parent = viewElement,
			pos = { (viewElement.size.w - progressScale) / 2, math.ceil(viewTitle.shift.y + viewTitle.size.h) },
			size = { progressScale, progressScale / 2 },
			bgImage = "../textures/menu/promo/events/movemberprogress.tga"
		})
		-- Hide overlay and enable it after loading progress bar to show it on top
		progressOverlay:hide()
		local progressBackground = UIElement:new({
			parent = viewElement,
			pos = { progressOverlay.shift.x, progressOverlay.shift.y },
			size = { progressOverlay.size.w, progressOverlay.size.h / 5 * 3 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local progressDataPointsDisplay = (progressDataPoints > playerData.points and progressDataLevel == playerData.level + 1) and progressDataPoints or playerData.points
		local progressBar = UIElement:new({
			parent = progressBackground,
			pos = { 0, 0 },
			size = { progressBackground.size.w * (playerData.points / progressDataPointsDisplay), progressBackground.size.h },
			bgColor = UICOLORBLACK --{ 0.232, 0.075, 0.008, 1 }
		})
		progressOverlay:show()
		if (progressDataPoints > playerData.points and progressDataLevel == playerData.level + 1) then
			local progressTextHolder = UIElement:new({
				parent = progressBackground,
				pos = { progressBackground.size.w / 8, -progressBackground.size.h / 5 },
				size = { progressBackground.size.w * 0.75, progressBackground.size.h / 3 },
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				rounded = 5,
				shapeType = ROUNDED
			})
			local progressText = UIElement:new({
				parent = progressTextHolder,
				pos = { progressTextHolder.size.w / 10, progressTextHolder.size.h / 8 },
				size = { progressTextHolder.size.w * 0.8, progressTextHolder.size.h * 0.75 }
			})
			progressText:addAdaptedText(true, playerData.points .. " / " .. progressDataPoints .. " points", nil, nil, FONTS.BIG, nil, 0.7, nil, 1, 1)
		else
			local progressTextHolder = UIElement:new({
				parent = progressBackground,
				pos = { progressBackground.size.w / 8, -progressBackground.size.h / 5 },
				size = { progressBackground.size.w * 0.75, progressBackground.size.h / 3 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				rounded = 5,
				shapeType = ROUNDED,
				interactive = true,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKER_ORANGE
			})
			local progressText = UIElement:new({
				parent = progressTextHolder,
				pos = { progressTextHolder.size.w / 10, progressTextHolder.size.h / 8 },
				size = { progressTextHolder.size.w * 0.8, progressTextHolder.size.h * 0.75 },
				uiColor = TB_MENU_DEFAULT_YELLOW
			})
			progressText:addAdaptedText(true, "Upgrade to next level", nil, nil, FONTS.BIG, nil, 0.7)
			progressTextHolder:addMouseHandlers(nil, function()
					show_dialog_box(6, TB_MENU_LOCALIZED.STOREDIALOGUPGRADE1 .. "\nyour Moustache ".. TB_MENU_LOCALIZED.STOREDIALOGUPGRADE2 .. " " .. (playerData.level + 1) .. "?", playerData.invid)
					local background = TBMenu:spawnWindowOverlay()
					background.interactive = true
					background:activate()
					background:addMouseHandlers(nil, nil, function(x)
							if (x < WIN_W / 2) then
								background:kill()
							else
								background:kill()
								Events:loadMovember(TBMenu.CurrentSection)
							end
						end)
				end)
		end

		local progressInfo = UIElement:new({
			parent = viewElement,
			pos = { 20, progressOverlay.shift.y + progressOverlay.size.h * 0.7 + 20 },
			size = { viewElement.size.w - 40, viewElement.size.h - progressOverlay.shift.y - progressOverlay.size.h * 0.7 - 20 - viewElement.size.h / 10 }
		})
		local progressTitle = UIElement:new({
			parent = progressInfo,
			pos = { 0, 0 },
			size = { progressInfo.size.w, progressInfo.size.h / 7 }
		})
		progressTitle:addAdaptedText(true, "How to get more points", nil, nil, FONTS.BIG, LEFT, nil, nil, 0.6)
		local progressInfoText = UIElement:new({
			parent = progressInfo,
			pos = { 0, progressTitle.shift.y + progressTitle.size.h },
			size = { progressInfo.size.w, progressInfo.size.h - progressTitle.shift.y - progressTitle.size.h }
		})
		progressInfoText:addAdaptedText(true, Events:getMovemberProgressInfoText(), nil, nil, 4, LEFT, nil, 0.6)

		local threadButton = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 5, progressInfo.size.h + progressInfo.shift.y },
			size = { viewElement.size.w * 0.6, viewElement.size.h / 11 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		TBMenu:showTextExternal(threadButton, "More about Toribash Movember on forums")
		threadButton:addMouseHandlers(nil, function()
				open_url("https://forum.toribash.com/showthread.php?t=633220")
			end)
	end

	function Events:showMovemberToplist(viewElement, toplistData)
		local elementHeight = 38
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 50, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)
		TBMenu:addBottomBloodSmudge(botBar, 2)

		local toplistTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 7 },
			size = { topBar.size.w - 20, topBar.size.h - 14 }
		})
		toplistTitle:addAdaptedText(true, "Manliest Mustaches", nil, nil, FONTS.BIG, nil, nil, nil, 0.5)

		local listElements = {}
		for i,v in pairs(toplistData) do
			local topEntry1 = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, topEntry1)
			local entryUsername = UIElement:new({
				parent = topEntry1,
				pos = { 10, topEntry1.size.h * 0.15 },
				size = { topEntry1.size.w - topEntry1.size.h * 2 - 20, topEntry1.size.h * 0.85 }
			})
			entryUsername:addAdaptedText(true, v.name, nil, nil, FONTS.BIG, LEFTBOT, nil, nil, 0.4)
			local topEntry2 = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, topEntry2)
			local entryPoints = UIElement:new({
				parent = topEntry2,
				pos = { 10, topEntry2.size.h / 10 },
				size = { topEntry2.size.w - topEntry2.size.h * 2 - 20, topEntry2.size.h * 0.8 }
			})
			local pts, lvl = Events:getStacheLevelPoints(v.points, true)
			local levelString = lvl == 6 and 'MAX Level' or 'Level ' .. lvl
			entryPoints:addAdaptedText(true, levelString .. ", " .. v.points .. " points", nil, nil, 4, LEFTMID, 0.7)

			local userBelt = PlayerInfo.getBeltFromQi(v.qi)
			local entryUserbelt = UIElement:new({
				parent = topEntry2,
				pos = { -topEntry2.size.h * 2, -topEntry2.size.h * 2 },
				size = { topEntry2.size.h * 2, topEntry2.size.h * 2 },
				bgImage = userBelt.icon
			})
			entryUserbelt:addAdaptedText(false, userBelt.name .. " belt", nil, nil, nil, CENTERBOT, 0.7, nil, 1, 1)

			local separator = UIElement:new({
				parent = listingHolder,
				pos = { 10, #listElements * elementHeight + elementHeight / 2 - 1 },
				size = { listingHolder.size.w - 20, 1 },
				bgColor = { 1, 1, 1, 0.8 }
			})
			table.insert(listElements, separator)
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
	end

	function Events:loadMovemberToplist(viewElement)
		TBMenu:displayLoadingMark(viewElement, TB_MENU_LOCALIZED.EVENTSLOADINGTOPPLAYERS)

		local function throwError(text)
			viewElement:kill(true)
			TBMenu:addBottomBloodSmudge(viewElement, 2)
			viewElement:addAdaptedText(nil, text)
		end
		local waiter = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		local countdown = 10
		waiter:addCustomDisplay(true, function()
				-- Hack to prevent infinite loading
				countdown = countdown - 1
				if (countdown > 0) then
					return
				end

				local toplistData = {}
				-- Send new request only if any previous requests are finished
				if (get_network_task() == 0) then
					Request:new("movember19", function()
							local response = get_network_response()
							if (response:find("ERROR;")) then
								throwError(TB_MENU_LOCALIZED.ACCOUNTINFOERROR)
								return
							end
							for ln in response:gmatch("[^\n]*\n?") do
								local data = { ln:match(("([^\t]*)\t"):rep(3)) }
								if (data[1] ~= "USERNAME" and data[1] ~= nil) then
									table.insert(toplistData, { name = data[1], points = data[2] + 0, qi = data[3] + 0 })
								end
							end
							if (viewElement:isDisplayed()) then
								viewElement:kill(true)
								Events:showMovemberToplist(viewElement, toplistData)
							end
						end, function()
							throwError(TB_MENU_LOCALIZED.REQUESTCONNECTIONERROR)
						end)
					download_server_info("movember19&do=toplist")
					waiter:kill()
				end
			end)
	end

	function Events:showMovember(viewElement, playerData, firstLaunch)
		viewElement:kill(true)

		local toplistWidth = viewElement.size.w / 3 > 350 and 350 or viewElement.size.w / 3
		local playerStatsView = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { (viewElement.size.w - toplistWidth) - 5, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(playerStatsView, 1)
		Events:showMovemberPlayerStats(playerStatsView, playerData)

		local movemberToplistView = UIElement:new({
			parent = viewElement,
			pos = { playerStatsView.size.w + 15, 0 },
			size = { toplistWidth - 15, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(movemberToplistView, 2)

		if (firstLaunch) then
			local intro = Events:showMovemberIntro()
			intro.killAction = function()
					Events:loadMovemberToplist(movemberToplistView)
				end
		else
			Events:loadMovemberToplist(movemberToplistView)
		end
	end

	function Events:loadModChampionship(viewElement, eventid)
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Events:getNavigationButtons(TB_MENU_EVENTS_OPEN, eventid), true)
		RoomList.RefreshIfNeeded()

		local loadingView = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(loadingView, 1)
		TBMenu:displayLoadingMark(loadingView, TB_MENU_LOCALIZED.EVENTSLOADING)

		local function throwError(text)
			loadingView:kill(true)
			TBMenu:addBottomBloodSmudge(loadingView, 1)
			loadingView:addAdaptedText(nil, text)
		end

		local champInfo, playerData = { loaded = false }, { games = 0, ranking = { wins = 0, losses = 0 } }
		Request:queue(function()
				download_server_info("modchampionship&username=" .. TB_MENU_PLAYER_INFO.username)
			end,
			"modchampionship", function()
				local response = get_network_response()
				if (response:find("ERROR;")) then
					throwError(TB_MENU_LOCALIZED.ACCOUNTINFOERROR)
					return
				end
				for ln in response:gmatch("[^\n]*\n?") do
					local ln = ln:gsub("\n$", '')
					if (ln:find("^MODCHAMPIONSHIP 0;")) then
						playerData.games = ln:gsub("MODCHAMPIONSHIP 0;", '') + 0
					elseif (ln:find("^MODCHAMPRANKING 0;")) then
						local rankInfo = ln:gsub("MODCHAMPRANKING 0;", '');
						local data = { rankInfo:match(("([^\t]*)\t?"):rep(4)) }
						playerData.ranking = { elo = data[1], rank = data[2] + 0, wins = data[3] + 0, losses = data[4] + 0 }
					elseif (ln:find("^MODNAME 0;")) then
						champInfo.loaded = true
						champInfo.mod = ln:gsub("MODNAME 0;", '')
					elseif (ln:find("^CHAMPOBJECTIVE 0;")) then
						champInfo.objective = ln:gsub("CHAMPOBJECTIVE 0;", '') + 0
					elseif (ln:find("^CHAMPGAMES 0;")) then
						champInfo.progress = ln:gsub("CHAMPGAMES 0;", '') + 0
					elseif (ln:find("^CHAMPREWARD 0;")) then
						champInfo.reward = ln:gsub("CHAMPREWARD 0;", '') + 0
					elseif (ln:find("^CHAMPTIMELEFT 0;")) then
						champInfo.timeleft = ln:gsub("CHAMPTIMELEFT 0;", '') + 0
					elseif (ln:find("^CHAMPREWARDS %d;")) then
						playerData.rewards = playerData.rewards or {}
						local info = ln:gsub("CHAMPREWARDS ", '')
						rewardid = info:gsub(";.*$", '') + 0
						info = info:gsub("^%d;", '')
						local data = { info:match(("([^\t]*)\t"):rep(5)) }
						playerData.rewards[rewardid] = { tc = data[1] + 0, st = data[2] + 0, itemid = data[3] + 0, requirement = data[4] + 0, claimed = data[5] == '1' and true or false }
					end
				end
				if (playerData.rewards) then
					playerData.rewards = table.qsort(playerData.rewards, 'requirement')
				end
				if (loadingView:isDisplayed()) then
					loadingView:kill()
					Events:showModChampionship(viewElement, champInfo, playerData)
				end
			end, function()
				throwError(TB_MENU_LOCALIZED.REQUESTCONNECTIONERROR)
			end)
	end

	function Events:showModChampionshipPlayerRewards(viewElement, playerStats)
		local prizesToClaim, prizesToUnlock = {}, {}
		for i,v in pairs(playerStats.rewards) do
			if (v.requirement <= playerStats.games and not v.claimed) then
				table.insert(prizesToClaim, v)
			end
			if (v.requirement > playerStats.games) then
				table.insert(prizesToUnlock, v)
			end
		end
		local shiftY = 0
		if (#prizesToClaim > 0) then
			local prizesClaimButton = UIElement:new({
				parent = viewElement,
				pos = { 10, shiftY },
				size = { viewElement.size.w - 20, 50 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_ORANGE,
				hoverColor = TB_MENU_DEFAULT_ORANGE,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 10,
				uiColor = UICOLORBLACK
			})
			local rewardName = ""
			if (#prizesToClaim == 1) then
				if (prizesToClaim[1].tc > 0) then
					rewardName = prizesToClaim[1].tc .. " TC"
				end
				if (prizesToClaim[1].st > 0) then
					rewardName = rewardName == "" and (prizesToClaim[1].st .. " ST") or (rewardName .. " & " .. prizesToClaim[1].st .. " ST")
				end
				if (prizesToClaim[1].itemid > 0) then
					rewardName = rewardName == "" and Torishop:getItemInfo(prizesToClaim[1].itemid).itemname or (rewardName .. " & " .. Torishop:getItemInfo(prizesToClaim[1].itemid).itemname)
				end
			else
				rewardName = TB_MENU_LOCALIZED.EVENTSCLAIMALL
			end
			local rewardIcon = prizesToClaim[#prizesToClaim].itemid > 0 and Torishop:getItemIcon(prizesToClaim[#prizesToClaim].itemid) or (prizesToClaim[#prizesToClaim].st > 0 and "../textures/store/shiaitoken.tga" or (prizesToClaim[#prizesToClaim].tc > 0 and "../textures/store/toricredit.tga"))
			if (rewardIcon ~= false) then
				TBMenu:showTextWithImage(prizesClaimButton, rewardName, 2, 35, rewardIcon)
			end
			prizesClaimButton:addMouseHandlers(nil, function()
					prizesClaimButton:deactivate()
					prizesClaimButton:addCustomDisplay(false, function() end)
					prizesClaimButton:kill(true)
					TBMenu:displayLoadingMarkSmall(prizesClaimButton, TB_MENU_LOCALIZED.REWARDSCLAIMINPROGRESS .. "...", FONTS.MEDIUM)

					if (get_network_task() == 0) then
						Request:queue(function() claim_quest(-1) end,
							'modchampreward', function()
								prizesClaimButton:kill(true)
								prizesClaimButton:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIMSUCCESS)
							end, function()
								prizesClaimButton:kill(true)
								prizesClaimButton:addAdaptedText(false, TB_MENU_LOCALIZED.REQUESTUNKNOWNERROR)
							end)
					else
						local waiter = UIElement:new({
							parent = prizesClaimButton,
							pos = { 0, 0 },
							size = { 0, 0 }
						})
						waiter:addCustomDisplay(true, function()
								if (get_network_task() == 0) then
									waiter:kill()
									Request:queue(function() claim_quest(-1) end,
									'modchampreward', function()
											prizesClaimButton:kill(true)
											prizesClaimButton:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIMSUCCESS)
										end, function()
											prizesClaimButton:kill(true)
											prizesClaimButton:addAdaptedText(false, TB_MENU_LOCALIZED.REQUESTUNKNOWNERROR)
										end)
								end
							end)
					end
				end)
			shiftY = shiftY + prizesClaimButton.size.h + 10
		end
		if (#prizesToUnlock > 0 and shiftY + 100 < viewElement.size.h) then
			local prizesToUnlockTitle = UIElement:new({
				parent = viewElement,
				pos = { 0, shiftY },
				size = { viewElement.size.w, 40 }
			})
			prizesToUnlockTitle:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSPRIZESLOCKED, nil, nil, FONTS.BIG, nil, 0.6)
			shiftY = shiftY + prizesToUnlockTitle.size.h + 10
			for i,v in pairs(prizesToUnlock) do
				if (shiftY + 60 > viewElement.size.h) then
					break
				end
				local prizeHolder = UIElement:new({
					parent = viewElement,
					pos = { 0, shiftY },
					size = { viewElement.size.w, 60 }
				})
				shiftY = shiftY + prizeHolder.size.h + 5
				local prizeName = UIElement:new({
					parent = prizeHolder,
					pos = { 0, 5 },
					size = { prizeHolder.size.w, 30 }
				})
				local rewardName = ""
				if (v.tc > 0) then
					rewardName = v.tc .. " Toricredits"
				end
				if (v.st > 0) then
					rewardName = rewardName == "" and (v.st .. " Shiai Tokens") or (rewardName:gsub("Toricredits", "TC") .. " & " .. v.st .. " ST")
				end
				if (v.itemid > 0) then
					rewardName = rewardName == "" and Torishop:getItemInfo(v.itemid).itemname or (rewardName:gsub("Toricredits", "TC"):gsub("Shiai Tokens", "ST") .. " & " .. Torishop:getItemInfo(v.itemid).itemname)
				end
				local rewardIcon = v.itemid > 0 and Torishop:getItemIcon(v.itemid) or (v.st > 0 and "../textures/store/shiaitoken.tga" or (v.tc > 0 and "../textures/store/toricredit.tga"))
				if (rewardIcon ~= false) then
					TBMenu:showTextWithImage(prizeName, rewardName, 2, nil, rewardIcon)
				end
				local prizeRequirement = UIElement:new({
					parent = prizeHolder,
					pos = { 0, prizeName.size.h + prizeName.shift.y },
					size = { prizeHolder.size.w, prizeHolder.size.h - prizeName.size.h - prizeName.shift.y * 2 }
				})
				prizeRequirement:addAdaptedText(true, (v.requirement - playerStats.games) .. " " .. TB_MENU_LOCALIZED.EVENTSWINSTOUNLOCK, nil, nil, 4, nil, 0.6)
			end
		end
		if (shiftY == 0) then
			local allRewardsClaimed = UIElement:new({
				parent = viewElement,
				pos = { 10, shiftY },
				size = { viewElement.size.w - 20, viewElement.size.h / 2 }
			})
			allRewardsClaimed:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSALLREWARDSCLAIMED, nil, nil, FONTS.BIG, CENTERBOT, 0.7, nil, 0.5)
			local allRewardsClaimedInfo = UIElement:new({
				parent = viewElement,
				pos = { 10, allRewardsClaimed.size.h },
				size = { viewElement.size.w - 20, viewElement.size.h - allRewardsClaimed.size.h }
			})
			allRewardsClaimedInfo:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSKEEPPLAYINGTOGETINTOPLIST, nil, nil, 4, CENTER)
		end
	end

	function Events:modChampionshipConnect()
		local players = RoomList.GetPlayers()

		local defaultRoom, rooms = "modmania1", { "modmania%d" }
		local roomsOnline = {}
		for i, online in pairs(players) do
			for j, roomname in pairs(rooms) do
				if (online.room:find(roomname)) then
					roomsOnline[online.room] = roomsOnline[online.room] or { players = 0 }
					roomsOnline[online.room].players = roomsOnline[online.room].players + 1
					break
				end
			end
		end
		for i, room in pairs(roomsOnline) do
			room.name = i
		end
		roomsOnline = table.qsort(roomsOnline, "players", true)
		if (#roomsOnline > 0) then
			for i, room in pairs(roomsOnline) do
				if (room.players > 1 and room.players < 5) then
					close_menu()
					runCmd("jo " .. room.name)
					return
				end
			end
			close_menu()
			runCmd("jo " .. roomsOnline[1].name)
		else
			close_menu()
			runCmd("jo " .. defaultRoom)
		end
	end

	function Events:showModChampionshipToplist(toReload, listingHolder, elementHeight, toplist, mode)
		MODCHAMPIONSHIP_TOPLIST_MODE = mode and mode or 0
		local modeName = MODCHAMPIONSHIP_TOPLIST_MODE == 1 and "ranking" or "games"
		local listElements = {}
		for i,v in pairs(toplist[modeName]) do
			if (v.games) then
				local topPlayerHolder = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, topPlayerHolder)
				local topPlayerEntry = UIElement:new({
					parent = topPlayerHolder,
					pos = { 10, 3 },
					size = { topPlayerHolder.size.w - 10, topPlayerHolder.size.h - 6 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				local topPlayerPlace = UIElement:new({
					parent = topPlayerEntry,
					pos = { 10, 5 },
					size = { 30, topPlayerEntry.size.h - 10 }
				})
				topPlayerPlace:addAdaptedText(true, "#" .. i, nil, nil, 4, nil, 0.7)
				local topPlayerName = UIElement:new({
					parent = topPlayerEntry,
					pos = { 50, 5 },
					size = { (topPlayerEntry.size.w - 60) * 0.7, topPlayerEntry.size.h - 10 }
				})
				topPlayerName:addAdaptedText(true, v.name, nil, nil, nil, LEFTMID)
				local topPlayerGames = UIElement:new({
					parent = topPlayerEntry,
					pos = { -(topPlayerEntry.size.w - 60) * 0.3 - 10, 5 },
					size = { (topPlayerEntry.size.w - 60) * 0.3, topPlayerEntry.size.h - 10 }
				})
				topPlayerGames:addAdaptedText(true, v.games .. " " .. string.lower(TB_MENU_LOCALIZED.EVENTSGAMESWON), nil, nil, 4, nil, 0.6)
			elseif (v.rank) then
				local topPlayerHolder = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, topPlayerHolder)
				local topPlayerEntry = UIElement:new({
					parent = topPlayerHolder,
					pos = { 10, 3 },
					size = { topPlayerHolder.size.w - 10, topPlayerHolder.size.h - 6 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				local topPlayerPlace = UIElement:new({
					parent = topPlayerEntry,
					pos = { 10, 5 },
					size = { 30, topPlayerEntry.size.h - 10 }
				})
				topPlayerPlace:addAdaptedText(true, "#" .. v.rank, nil, nil, 4, nil, 0.7)
				local topPlayerName = UIElement:new({
					parent = topPlayerEntry,
					pos = { 50, 5 },
					size = { (topPlayerEntry.size.w - 60) * 0.7, topPlayerEntry.size.h - 10 }
				})
				topPlayerName:addAdaptedText(true, v.name, nil, nil, nil, LEFTMID)
				local topPlayerGames = UIElement:new({
					parent = topPlayerEntry,
					pos = { -(topPlayerEntry.size.w - 60) * 0.3 - 10, 5 },
					size = { (topPlayerEntry.size.w - 60) * 0.3, topPlayerEntry.size.h - 10 }
				})
				topPlayerGames:addAdaptedText(true, v.elo .. " elo", nil, nil, 4, nil, 0.6)
			end
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
		return scrollBar
	end

	function Events:showModChampionship(viewElement, champInfo, playerStats)
		local playerStatsHolder = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.35 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(playerStatsHolder, 1)
		local playerStatsTitle = UIElement:new({
			parent = playerStatsHolder,
			pos = { 10, 5 },
			size = { playerStatsHolder.size.w - 20, 40 }
		})
		playerStatsTitle:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSMYSTATS, nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
		local gamesHolderH = playerStatsHolder.size.h / 2 - playerStatsTitle.size.h - playerStatsTitle.shift.y - 5
		gamesHolderH = gamesHolderH > 70 and 70 or gamesHolderH
		local playerGamesHolder = UIElement:new({
			parent = playerStatsHolder,
			pos = { 20, playerStatsTitle.shift.y + playerStatsTitle.size.h + 5 },
			size = { playerStatsHolder.size.w - 40, gamesHolderH / 2 }
		})
		playerGamesHolder:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSGAMESWON .. ": " .. (playerStats.games > 0 and (playerStats.games .. '') or TB_MENU_LOCALIZED.WORDNONE), nil, nil, FONTS.MEDIUM, CENTERBOT)

		local hasRank = (playerStats.ranking.wins + playerStats.ranking.losses) >= 10
		local playerRankHolder = UIElement:new({
			parent = playerStatsHolder,
			pos = { playerGamesHolder.shift.x, playerGamesHolder.shift.y + playerGamesHolder.size.h + 5 },
			size = { playerGamesHolder.size.w, playerGamesHolder.size.h }
		})
		playerRankHolder:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANK .. (hasRank and (" " .. playerStats.ranking.rank .. ' (' .. playerStats.ranking.elo .. " elo)") or (": " .. TB_MENU_LOCALIZED.MATCHMAKEQUALIFYING)), nil, nil, FONTS.MEDIUM, CENTER)

		if (playerStats.rewards) then
			local playerGamesRewards = UIElement:new({
				parent = playerStatsHolder,
				pos = { 10, playerRankHolder.shift.y + playerRankHolder.size.h + 20 },
				size = { playerStatsHolder.size.w - 20, playerStatsHolder.size.h - playerRankHolder.shift.y - playerRankHolder.size.h - 20 }
			})
			Events:showModChampionshipPlayerRewards(playerGamesRewards, playerStats)
		end

		local globalChallengeHolder = UIElement:new({
			parent = viewElement,
			pos = { playerStatsHolder.size.w + 15, 0 },
			size = { viewElement.size.w * 0.3 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(globalChallengeHolder, 1)
		local globalChallengeTitle = UIElement:new({
			parent = globalChallengeHolder,
			pos = { 10, 5 },
			size = { globalChallengeHolder.size.w - 20, 70 }
		})
		globalChallengeTitle:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSCOMMUNITYOBJECTIVE, nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
		local globalChallengeTimeleft = UIElement:new({
			parent = globalChallengeHolder,
			pos = { 10, 75 },
			size = { globalChallengeHolder.size.w - 20, 25 }
		})
		globalChallengeTimeleft:addAdaptedText(true, champInfo.timeleft > 0 and (TB_MENU_LOCALIZED.EVENTSENDSIN .. " " .. TBMenu:getTime(champInfo.timeleft, 2)) or (TB_MENU_LOCALIZED.EVENTSENDED .. " " .. TBMenu:getTime(-champInfo.timeleft, 2) .. " " .. TB_MENU_LOCALIZED.EVENTSENDEDAGO))

		local bgScale = globalChallengeHolder.size.w * 0.7 > globalChallengeHolder.size.h - 250 and globalChallengeHolder.size.h - 250 or globalChallengeHolder.size.w * 0.7
		local questBackground = UIElement:new({
			parent = globalChallengeHolder,
			pos = { (globalChallengeHolder.size.w - bgScale) / 2, globalChallengeTimeleft.shift.y + globalChallengeTimeleft.size.h + 5 },
			size = { bgScale, bgScale },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			uiColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = bgScale
		})
		local progress = champInfo.progress / champInfo.objective
		local questImage = "../textures/menu/general/quests/qtype2.tga"
		if (progress > 1) then
			progress = 1
			questBackground.bgColor = table.clone(TB_MENU_DEFAULT_DARKER_ORANGE)
			questBackground.uiColor = table.clone(TB_MENU_DEFAULT_ORANGE)
			questImage = "../textures/menu/general/buttons/checkmarkbig.tga"
		end

		local questIcon = UIElement:new({
			parent = questBackground,
			pos = { bgScale / 5, bgScale / 5 },
			size = { bgScale / 5 * 3, bgScale / 5 * 3 },
			bgImage = questImage
		})
		questBackground:addCustomDisplay(false, function()
				set_color(unpack(questBackground.uiColor))
				draw_disk(questBackground.pos.x + questBackground.size.w / 2, questBackground.pos.y + questBackground.size.h / 2, questBackground.size.h / 2.75, questBackground.size.h / 2 - 5, 100, 1, -60, -240, 0)
				set_color(unpack(UICOLORWHITE))
				draw_disk(questBackground.pos.x + questBackground.size.w / 2, questBackground.pos.y + questBackground.size.h / 2, questBackground.size.h / 2.75, questBackground.size.h / 2 - 5, 100, 1, -60, -240 * progress, 0)
			end)
		local progressText = UIElement:new({
			parent = questBackground,
			pos = { 0, -questBackground.size.h / 4.5 },
			size = { questBackground.size.w, questBackground.size.h / 4.5 },
			shapeType = ROUNDED,
			rounded = 10,
			bgColor = questBackground.uiColor,
			uiColor = UICOLORWHITE
		})
		progressText:addAdaptedText(false, progress == 1 and (TB_MENU_LOCALIZED.EVENTSCOMPLETED .. "!") or (champInfo.progress .. " / " .. champInfo.objective .. "\n" .. TB_MENU_LOCALIZED.WORDGAMES))
		if (progress == 1) then
			local prizeInfo = UIElement:new({
				parent = progressText,
				pos = { 0, 0 },
				size = { progressText.size.w, progressText.size.h },
				interactive = true
			})
			TBMenu:displayHelpPopup(prizeInfo, TB_MENU_LOCALIZED.EVENTSGLOBALPRIZEWILLBESENT, nil, true)
		end

		local globalItemReward = Torishop:getItemInfo(champInfo.reward)
		local globalReward = UIElement:new({
			parent = globalChallengeHolder,
			pos = { 20, questBackground.shift.y + questBackground.size.h + 5 },
			size = { globalChallengeHolder.size.w - 40, globalChallengeHolder.size.h - questBackground.shift.y - questBackground.size.h - 70 }
		})
		TBMenu:showTextWithImage(globalReward, globalItemReward.itemname, FONTS.MEDIUM, 64, Torishop:getItemIcon(globalItemReward.itemid))

		local joinButton = UIElement:new({
			parent = globalChallengeHolder,
			pos = { 20, -60 },
			size = { globalChallengeHolder.size.w - 40, 50 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		joinButton:addAdaptedText(nil, TB_MENU_LOCALIZED.FRIENDSLISTJOINROOM)
		joinButton:addMouseHandlers(nil, function() Events:modChampionshipConnect() end)

		local toplist = { games = {}, ranking = {} }
		local playersToplistHolder = UIElement:new({
			parent = viewElement,
			pos = { globalChallengeHolder.size.w + globalChallengeHolder.shift.x + 10, 0 },
			size = { viewElement.size.w * 0.35 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local elementHeight = 50
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(playersToplistHolder, elementHeight * 2, elementHeight, 15, TB_MENU_DEFAULT_BG_COLOR)
		listingHolder.hasDataLoaded = false

		local toplistTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 5 },
			size = { topBar.size.w - 20, topBar.size.h / 2 - 10 }
		})
		toplistTitle:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSTOPLIST, nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
		TBMenu:addBottomBloodSmudge(botBar, 3)
		local toplistModeGames = UIElement:new({
			parent = topBar,
			pos = { 10, toplistTitle.shift.y + toplistTitle.size.h + 5 },
			size = { topBar.size.w / 2 - 15, topBar.size.h - toplistTitle.size.h - toplistTitle.shift.y - 10 },
			interactive = true,
			bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		toplistModeGames:addAdaptedText(false, TB_MENU_LOCALIZED.EVENTSGAMESWON)
		local toplistModeRank = UIElement:new({
			parent = topBar,
			pos = { toplistModeGames.shift.x * 2 + toplistModeGames.size.w, toplistModeGames.shift.y },
			size = { toplistModeGames.size.w, toplistModeGames.size.h },
			interactive = true,
			bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		toplistModeRank:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKERANK)

		toplistModeGames:addMouseHandlers(nil, function()
				if (listingHolder.hasDataLoaded) then
					if (listingHolder.scrollBar) then
						listingHolder.scrollBar.parent:kill()
						listingHolder:kill(true)
					end
					listingHolder.scrollBar = Events:showModChampionshipToplist(toReload, listingHolder, elementHeight, toplist, 0)
					toplistModeGames.bgColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR)
					toplistModeRank.bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR)
				end
			end)
		toplistModeRank:addMouseHandlers(nil, function()
				if (listingHolder.hasDataLoaded) then
					if (listingHolder.scrollBar) then
						listingHolder.scrollBar.parent:kill()
						listingHolder:kill(true)
					end
					listingHolder.scrollBar = Events:showModChampionshipToplist(toReload, listingHolder, elementHeight, toplist, 1)
					toplistModeRank.bgColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR)
					toplistModeGames.bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR)
				end
			end)

		TBMenu:displayLoadingMark(listingHolder, TB_MENU_LOCALIZED.EVENTSLOADINGTOPPLAYERS)
		Request:queue(function() download_server_info("modchampionship&do=toplist") end,
			"modchampionshiptoplist", function()
				local response = get_network_response()
				listingHolder:kill(true)
				if (response:sub(0, 4) ~= "USER") then
					listingHolder:addAdaptedText(true, TB_MENU_LOCALIZED.REQUESTUNKNOWNERROR)
				end
				local mode = 0
				for ln in response:gmatch("[^\n]*\n?") do
					if (ln:find("^#")) then
						mode = mode + 1
					else
						local ln = ln:gsub("\n$", '')
						if (mode == 0) then
							local data = { ln:match(("([^\t]*)\t"):rep(2)) }
							if (data[2] ~= "WINS") then
								table.insert(toplist.games, { name = data[1], games = data[2] })
							end
						elseif (mode == 1) then
							local data = { ln:match(("([^\t]*)\t"):rep(3)) }
							if (data[2] ~= "RANK") then
								table.insert(toplist.ranking, { name = data[1], rank = data[2], elo = data[3] })
							end
						end
					end
				end
				listingHolder:addCustomDisplay(false, function() end)
				if (listingHolder:isDisplayed()) then
					listingHolder.hasDataLoaded = true
					if (MODCHAMPIONSHIP_TOPLIST_MODE == 1) then
						toplistModeRank.btnUp()
					else
						toplistModeGames.btnUp()
					end
				end
			end, function()
				listingHolder:kill(true)
				listingHolder:addAdaptedText(true, TB_MENU_LOCALIZED.REQUESTCONNECTIONERROR)
			end)
	end

	function Events:getPassedEventInfo(filename)
		local eventInfo = { shortname = filename:gsub("%.dat$", '') }
		eventInfo.name = eventInfo.shortname
		local file = Files.Open("../data/script/events/" .. filename, FILES_MODE_READONLY)
		if (not file.data) then
			return eventInfo
		end
		local lines = file:readAll()
		file:close()

		for i, ln in pairs(lines) do
			if (ln:find("^EVENTNAME 0;")) then
				eventInfo.name = ln:gsub("^EVENTNAME 0;", '')
			end
			if (ln:find("^STEP")) then
				break
			end
		end
		return eventInfo
	end

	function Events:showPassedEventWinners(viewElement, data)
		viewElement:kill(true)
		viewElement:addCustomDisplay(true, function() end)

		local eventName = UIElement:new({
			parent = viewElement,
			pos = { 10, 0 },
			size = { viewElement.size.w - 20, 45 }
		})
		eventName:addAdaptedText(true, data.eventname, nil, nil, FONTS.BIG, CENTERBOT)

		local endTime = UIElement:new({
			parent = viewElement,
			pos = { 10, eventName.size.h + eventName.shift.y },
			size = { viewElement.size.w - 20, 25 }
		})
		endTime:addAdaptedText(true, data.endtimestring, nil, nil, nil, CENTER)

		local yShift = endTime.size.h + endTime.shift.y + 10
		if (data.endtimeraw > 0) then
			local winnerHolder = UIElement:new({
				parent = viewElement,
				pos = { 10, yShift },
				size = { viewElement.size.w - 20, (viewElement.size.h - yShift - 10) / 2 }
			})
			local headDisplayed = false
			if (data.winner) then
				local winnerName = data.winner:lower()

				-- make sure we can open customs on Linux
				local customs = get_files("custom", "")
				local folderFound = false
				for i,v in pairs(customs) do
					if (winnerName == v:lower()) then
						winnerName = v
						folderFound = true
						break
					end
				end
				if (folderFound) then
					local viewportSize = winnerHolder.size.w / 2 < winnerHolder.size.h - 20 and winnerHolder.size.w / 2 or winnerHolder.size.h - 20
					local viewportHolder = UIElement:new({
						parent = winnerHolder,
						pos = { (winnerHolder.size.w / 2 - viewportSize) / 2, (winnerHolder.size.h - viewportSize) / 2 },
						size = { viewportSize, viewportSize }
					})
					TBMenu:showPlayerHeadAvatar(viewportHolder, winnerName)
					headDisplayed = true
				end
				download_head(winnerName)
				local winnerInfo = UIElement:new({
					parent = winnerHolder,
					pos = { headDisplayed and (winnerHolder.size.w / 2 + 10) or 10, 0 },
					size = { headDisplayed and (winnerHolder.size.w / 2 - 20) or winnerHolder.size.w - 20, winnerHolder.size.h }
				})
				local winnerTop = UIElement:new({
					parent = winnerInfo,
					pos = { 0, 0 },
					size = { winnerInfo.size.w, winnerInfo.size.h / 2 }
				})
				winnerTop:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSWONBY, nil, nil, FONTS.BIG, headDisplayed and LEFTBOT or CENTERBOT, 0.7, nil, 0.2)
				local winnerBot = UIElement:new({
					parent = winnerInfo,
					pos = { 0, winnerTop.size.h },
					size = { winnerInfo.size.w, winnerInfo.size.h - winnerTop.size.h }
				})
				winnerBot:addAdaptedText(true, winnerName, nil, nil, FONTS.BIG, headDisplayed and LEFT or CENTER)
			else
				winnerHolder.size.h = 40
				winnerHolder:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSJUDGINGINPROGRESS)
			end
			yShift = yShift + winnerHolder.size.h + 10
		end
		local prizesHeight = viewElement.size.h - yShift > 150 and 150 or viewElement.size.h - yShift
		local prizesHolder = UIElement:new({
			parent = viewElement,
			pos = { 10, yShift + (viewElement.size.h - yShift - prizesHeight) / 2 },
			size = { viewElement.size.w - 20, prizesHeight }
		})
		local function showPrize(icon, text, pos)
			local prizeHolder = UIElement:new({
				parent = prizesHolder,
				pos = { (pos - 1) * prizesHolder.size.w / 3, 0 },
				size = { prizesHolder.size.w / 3, prizesHolder.size.h - 10 }
			})
			local iconScale = prizeHolder.size.h / 2 > prizeHolder.size.w and prizeHolder.size.w or prizeHolder.size.h / 2
			iconScale = iconScale > 64 and 64 or iconScale
			local prizeIcon = UIElement:new({
				parent = prizeHolder,
				pos = { (prizeHolder.size.w - iconScale) / 2, (prizeHolder.size.h / 2 - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = icon
			})
			local prizeText = UIElement:new({
				parent = prizeHolder,
				pos = { 10, prizeHolder.size.h / 2 },
				size = { prizeHolder.size.w - 20, prizeHolder.size.h / 2 }
			})
			prizeText:addAdaptedText(true, text, nil, nil, FONTS.BIG, nil, 0.6, nil, 0.5)
		end
		local posShift = data.itemid == 0 and 0.5 or 0
		showPrize("../textures/store/toricredit.tga", numberFormat(data.tc) .. " Toricredits", 1 + posShift)
		showPrize("../textures/store/shiaitoken.tga", numberFormat(data.st) .. " Shiai Tokens", 2 + posShift)
		if (data.itemid ~= 0) then
			local itemInfo = Torishop:getItemInfo(data.itemid)
			showPrize(Torishop:getItemIcon(itemInfo), itemInfo.itemname, 3)
		end
	end

	function Events:showPassedEventButtons(viewElement, sysname, eventid)
		viewElement:kill(true)
		local buttonWidth, buttonShift = viewElement.size.w / 3, viewElement.size.w / 3
		if (eventid) then
			local infoButton = UIElement:new({
				parent = viewElement,
				pos = { viewElement.size.w / 6 - 5, 0 },
				size = { buttonWidth, viewElement.size.h },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				hoverSound = 31
			})
			infoButton:addAdaptedText(false, TB_MENU_LOCALIZED.EVENTSVIEWMOREINFO)
			infoButton:addMouseHandlers(nil, function()
					Events:showEventInfo(eventid)
				end)
			buttonShift = viewElement.size.w / 2 + 5
		end
		local playButton = UIElement:new({
			parent = viewElement,
			pos = { buttonShift, 0 },
			size = { buttonWidth, viewElement.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			hoverSound = 31
		})
		playButton:addAdaptedText(false, TB_MENU_LOCALIZED.EVENTSPLAY)
		playButton:addMouseHandlers(nil, function()
				close_menu()
				EventsOnline:playEvent(sysname)
			end)
	end

	function Events:showPassedEventInfo(viewElement, evtname, activeId)
		viewElement:kill(true)
		TBMenu:addBottomBloodSmudge(viewElement, 2)

		local eventResponse = {}
		local eventInfo = Request:queue(function() download_server_info("passed_event_info&eventid=" .. evtname) end, "passedEventInfoFetch", function(data)
				local response = get_network_response()
				data.sysname = evtname
				for ln in response:gmatch("[^\n]*\n?") do
					local ln = ln:gsub("\n$", '')
					if (ln:find("^WINNER 0;")) then
						local winner = ln:gsub("^WINNER 0;", '')
						if (winner:len() > 1) then
							data.winner = winner
						end
					elseif (ln:find("^ENDTIME 0;")) then
						data.endtimeraw = ln:gsub("ENDTIME 0;", '') + 0
						data.endtimestring = data.endtimeraw < 0 and (TB_MENU_LOCALIZED.EVENTSENDSIN .. " " .. TBMenu:getTime(-data.endtimeraw, 2)) or (TB_MENU_LOCALIZED.EVENTSENDED .. " " .. TBMenu:getTime(data.endtimeraw, 2) .. " " .. TB_MENU_LOCALIZED.EVENTSENDEDAGO)
					elseif (ln:find("^EVENTNAME 0;")) then
						data.eventname = ln:gsub("EVENTNAME 0;", '')
					elseif (ln:find("^REWARDTC 0;")) then
						data.tc = ln:gsub("REWARDTC 0;", '') + 0
					elseif (ln:find("^REWARDST 0;")) then
						data.st = ln:gsub("REWARDST 0;", '') + 0
					elseif (ln:find("^REWARDITEM 0;")) then
						data.itemid = ln:gsub("REWARDITEM 0;", '') + 0
					end
				end
				if (not data.eventname) then
					data.failed = true
				end
			end)

		local eventInfoHolder = UIElement:new({
			parent = viewElement,
			pos = { 10, 10 },
			size = { viewElement.size.w - 20, viewElement.size.h - 60 }
		})
		TBMenu:displayLoadingMark(eventInfoHolder, TB_MENU_LOCALIZED.EVENTSLOADING)
		local eventButtonsHolder = UIElement:new({
			parent = viewElement,
			pos = { 10, eventInfoHolder.size.h + eventInfoHolder.shift.y },
			size = { viewElement.size.w - 20, viewElement.size.h - (eventInfoHolder.size.h + eventInfoHolder.shift.y * 2) }
		})
		Events:showPassedEventButtons(eventButtonsHolder, evtname, activeId)
		eventInfoHolder:addCustomDisplay(true, function()
				if (eventInfo.failed and eventInfo.ready) then
					eventInfoHolder:kill(true)
					eventInfoHolder:addAdaptedText(true, TB_MENU_LOCALIZED.ACCOUNTINFOERROR)
					return
				end
				if (eventInfo.ready and TB_STORE_DATA.ready) then
					Events:showPassedEventWinners(eventInfoHolder, eventInfo)
					return
				end
			end)
	end

	function Events:showPassedEvents(viewElement, noBack)
		if (noBack) then
			viewElement:kill(true)
		else
			TBMenu:clearNavSection()
			TBMenu:showNavigationBar(Events:getNavigationButtons(true), true)
		end

		local eventsListHolder = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.35 - 5, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local eventInfoHolder = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w * 0.35 + 5, 0 },
			size = { viewElement.size.w * 0.65 - 5, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})

		local elementHeight = 50
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(eventsListHolder, elementHeight, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)
		TBMenu:addBottomBloodSmudge(botBar, 1)

		local allEventsTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 5 },
			size = { topBar.size.w - 20, topBar.size.h - 10 }
		})
		allEventsTitle:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSVIEWIGNALLEVENTS, nil, nil, FONTS.BIG)

		local eventsListData = get_files("data/script/events", "dat")
		local eventsList = { }

		local eventsData = News:getEvents()
		if (table.empty(eventsData)) then
			listingHolder:addAdaptedText(TB_MENU_LOCALIZED.NOTHINGTOSHOW, nil, nil, FONTS.BIG, nil, 0.75)
			return
		end

		for i = 1, #eventsListData do
			local shortname = eventsListData[i]:gsub("%.dat$", '')
			eventsList[i] = { file = eventsListData[i], live = 0 }
			for j,v in pairs(eventsData) do
				if (v.eventid == shortname) then
					eventsList[i].live = -1
					eventsList[i].activeId = j
				end
			end
		end
		for _, v in pairs(eventsList) do
			v.info = Events:getPassedEventInfo(v.file)
			v.name = v.info.name
		end
		eventsList = table.qsort(eventsList, { 'name', 'live' }, false)

		local selectedButton = nil
		local listElements = {}
		local liveShown, liveOver = false, false
		for i,v in pairs(eventsList) do
			if (v.live ~= 0 and not liveShown) then
				liveShown = true
				local liveEventsCaption = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, liveEventsCaption)
				local liveEventsCaptionText = UIElement:new({
					parent = liveEventsCaption,
					pos = { 10, 0 },
					size ={ liveEventsCaption.size.w - 20, liveEventsCaption.size.h }
				})
				liveEventsCaptionText:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSLIVEEVENTS, 10, nil, FONTS.BIG, LEFTMID, 0.6, nil, 0.4)
			end
			if (v.live == 0 and liveShown and not liveOver) then
				liveOver = true
				local endedEventsCaption = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, endedEventsCaption)
				local endedEventsCaptionText = UIElement:new({
					parent = endedEventsCaption,
					pos = { 10, 0 },
					size ={ endedEventsCaption.size.w - 20, endedEventsCaption.size.h }
				})
				endedEventsCaptionText:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSENDEDEVENTS, 10, nil, FONTS.BIG, LEFTMID, 0.6, nil, 0.4)
			end
			local listEventHolder = listingHolder:addChild({
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, listEventHolder)
			local listEvent = listEventHolder:addChild({
				pos = { 10, 2 },
				size = { listEventHolder.size.w - 10, listEventHolder.size.h - 4 },
				interactive = true,
				clickThrough = true,
				hoverThrough = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			local eventInfo = v.info
			listEvent:addMouseHandlers(nil, function()
					Events:showPassedEventInfo(eventInfoHolder, eventInfo.shortname, v.activeId)
					selectedButton.bgColor = table.clone(TB_MENU_DEFAULT_DARKER_COLOR)
					listEvent.bgColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR)
					selectedButton = listEvent
				end)
			local shiftX = 0
			if (v.live ~= 0) then
				local length = get_string_length(TB_MENU_LOCALIZED.EVENTSLIVE:upper(), 4) * 0.5
				local liveCaption = listEvent:addChild({
					pos = { 10, listEvent.size.h / 4 },
					size = { length + 15, listEvent.size.h / 2 },
					bgColor = TB_MENU_DEFAULT_BLUE,
					uiShadowColor = TB_MENU_DEFAULT_DARKEST_BLUE,
					shapeType = ROUNDED,
					rounded = listEvent.size.h / 4
				})
				liveCaption:addAdaptedText(nil, TB_MENU_LOCALIZED.EVENTSLIVE:upper(), nil, nil, 4, nil, 0.5, 0.5, nil, 2)
				shiftX = shiftX + liveCaption.shift.x + liveCaption.size.w
			end
			local listEventName = UIElement:new({
				parent = listEvent,
				pos = { 10 + shiftX, 5 },
				size = { listEvent.size.w - shiftX - 20, listEvent.size.h - 10 }
			})
			listEventName:addAdaptedText(nil, eventInfo.name, nil, nil, nil, LEFTMID, nil, nil, 0.2)

			if (i == 1) then
				selectedButton = listEvent
				selectedButton.bgColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR)
				Events:showPassedEventInfo(eventInfoHolder, eventInfo.shortname, v.activeId)
			end
		end
		for _, v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
	end

	function Events:showEventsHome(viewElement)
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Events:getNavigationButtons(), true)
		TB_MENU_EVENTS_OPEN = true
		local newsData = News:getNews(true)
		local count = #newsData
		for i = count, 1, -1 do
			if (not newsData[i].isEvent) then
				table.remove(newsData, i)
			end
		end

		if (#newsData) < 2 then
			Events:showPassedEvents(viewElement, true)
			return
		end

		local buttonH = #newsData > 3 and 0.5 or 1
		local buttonW = viewElement.size.w * 0.75 / math.ceil(#newsData * buttonH)
		local shiftX, shiftY = 0, 0
		for i,v in pairs(newsData) do
			v.ratio2 = 0.66
			if (i == #newsData and shiftY == 0) then
				buttonH = 1
			end
			local newsButton = UIElement:new({
				parent = viewElement,
				pos = { 5 + shiftX, shiftY },
				size = { buttonW - 10, buttonH * viewElement.size.h - (buttonH == 1 and 0 or 5) },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			if (buttonH == 1 or shiftY > 0) then
				TBMenu:showHomeButton(newsButton, v, buttonH * i)
			else
				TBMenu:showHomeButton(newsButton, v)
			end

			if (buttonH == 1) then
				shiftX = shiftX + buttonW
			else
				shiftY = shiftY + viewElement.size.h * buttonH + 5
				if (shiftY > viewElement.size.h) then
					shiftY = 0
					shiftX = shiftX + buttonW + 5
				end
			end
		end

		local allEventsButton = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w * 0.75 + 5, 0 },
			size = { viewElement.size.w * 0.25 - 10, viewElement.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local allEventsButtonData = {
			title = TB_MENU_LOCALIZED.EVENTSALLEVENTS,
			subtitle = TB_MENU_LOCALIZED.EVENTSALLEVENTSDESC,
			ratio = 0.3,
			action = function() Events:showPassedEvents(viewElement) end
		}
		TBMenu:showHomeButton(allEventsButton, allEventsButtonData, 3)
	end

	function Events:showEventDescription(viewElement, event)
		local elementHeight = 41
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 60, 60, 20, event.accentColor)

		listingScrollBG.bgColor = { 0, 0, 0, 0 }
		local listElements = {}
		for i, info in pairs(event.data) do
			if (info.imagetitle) then
				local imageScale = elementHeight * 8 > listingHolder.size.w - 20 and (listingHolder.size.w - 20) / 8 or elementHeight
				local infoTitle = UIElement:new({
					parent = listingHolder,
					pos = { listingHolder.size.w / 2 - imageScale * 4, #listElements * elementHeight },
					size = { imageScale * 8, imageScale },
					bgImage = info.imagetitle
				})
				table.insert(listElements, infoTitle)
			elseif (info.title ~= '') then
				local infoTitle = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				infoTitle:addAdaptedText(true, info.title, nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
				table.insert(listElements, infoTitle)
			end
			if (info.desc) then
				local textString = textAdapt(info.desc, 4, 0.9, listingHolder.size.w - 80)
				local rows = math.ceil(#textString / 2)
				for i = 1, rows do
					local infoRow = UIElement:new({
						parent = listingHolder,
						pos = { 50, #listElements * elementHeight },
						size = { listingHolder.size.w - 80, elementHeight }
					})
					infoRow:addCustomDisplay(true, function()
							infoRow:uiText(textString[i * 2 - 1], nil, nil, 4, CENTER, 0.85)
							if (textString[i * 2]) then
								infoRow:uiText(textString[i * 2], nil, nil, 4, CENTERBOT, 0.85)
							end
						end)
					table.insert(listElements, infoRow)
				end
			end
			if (i < #event.data) then
				local emptyRow = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				table.insert(listElements, emptyRow)
			end
		end

		if (#listElements * elementHeight > listingHolder.size.h) then
			for i,v in pairs(listElements) do
				v:hide()
			end

			local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
			scrollBar:makeScrollBar(listingHolder, listElements, toReload, nil, nil, true)
			scrollBar.bgColor = { 0, 0, 0, 0 }
			scrollBar.hoverColor = { 0, 0, 0, 0 }
			scrollBar.pressedColor = { 0, 0, 0, 0 }
		else
			listingHolder:moveTo(0, math.ceil((listingHolder.size.h - #listElements * elementHeight) / 2), true)
		end

		return topBar, botBar
	end

	function Events:showPrizeInfo(prize, listingHolder, elements, elementHeight)
		local prize = prize or { id = 0, itemname = "Unknown Item" }
		local rewardView = UIElement:new({
			parent = listingHolder,
			pos = { 10, elements * elementHeight },
			size = { listingHolder.size.w - 20, elementHeight }
		})
		local rewardBulletpoint = UIElement:new({
			parent = rewardView,
			pos = { 0, rewardView.size.h / 2 - 3 },
			size = { 6, 6 },
			bgColor = rewardView.uiColor,
			shapeType = ROUNDED,
			rounded = rewardView.size.h
		})
		local itemIcon = UIElement:new({
			parent = rewardView,
			pos = { rewardBulletpoint.size.w + 5, 2 },
			size = { rewardView.size.h - 4, rewardView.size.h - 4 },
			bgImage = prize.icon or Torishop:getItemIcon(prize.itemid)
		})
		if (not itemIcon.bgImage) then
			itemIcon:addAdaptedText(true, "?")
		end
		local itemName = UIElement:new({
			parent = rewardView,
			pos = { rewardBulletpoint.size.w + itemIcon.size.w + 10, 0 },
			size = { rewardView.size.w - (rewardBulletpoint.size.w + itemIcon.size.w + 10), rewardView.size.h }
		})
		itemName:addAdaptedText(true, prize.itemname, nil, nil, nil, LEFTMID)
		return rewardView
	end

	function Events:showEventPrizes(viewElement, event)
		local elementHeight = 41
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 60, 60, 20, event.accentColor)

		listingScrollBG.bgColor = { 0, 0, 0, 0 }
		local listElements = {}
		if (event.prizes.imagetitle) then
			local imageScale = elementHeight * 8 > listingHolder.size.w - 20 and (listingHolder.size.w - 20) / 8 or elementHeight
			local infoTitle = UIElement:new({
				parent = listingHolder,
				pos = { listingHolder.size.w / 2 - imageScale * 4, #listElements * elementHeight },
				size = { imageScale * 8, imageScale },
				bgImage = event.prizes.imagetitle
			})
			table.insert(listElements, infoTitle)
		else
			local infoTitle = UIElement:new({
				parent = listingHolder,
				pos = { 10, #listElements * elementHeight },
				size = { listingHolder.size.w - 20, elementHeight }
			})
			infoTitle:addAdaptedText(true, "Prizes", nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
			table.insert(listElements, infoTitle)
		end

		for i, prize in ipairs(event.prizes) do
			if (prize.info) then
				local infoRow = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				infoRow:addAdaptedText(true, prize.info)
				table.insert(listElements, infoRow)
			end
			if (prize.tc) then
				local itemShopInfo = { itemname = numberFormat(prize.tc) .. " Toricredits", icon = "../textures/store/toricredit.tga" }
				local itemRewardView = Events:showPrizeInfo(itemShopInfo, listingHolder, #listElements, elementHeight)
				table.insert(listElements, itemRewardView)
			end
			if (prize.st) then
				local itemShopInfo = { itemname = prize.st .. (prize.st > 1 and " Shiai Tokens" or " Shiai Token"), icon = "../textures/store/shiaitoken.tga" }
				local itemRewardView = Events:showPrizeInfo(itemShopInfo, listingHolder, #listElements, elementHeight)
				table.insert(listElements, itemRewardView)
			end
			if (prize.itemids) then
				for i, id in pairs(prize.itemids) do
					local itemShopInfo = Torishop:getItemInfo(id)
					local itemRewardView = Events:showPrizeInfo(itemShopInfo, listingHolder, #listElements, elementHeight)
					table.insert(listElements, itemRewardView)
				end
			end
			if (i ~= #event.prizes) then
				local emptyRow = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				table.insert(listElements, emptyRow)
			end
		end

		if (#listElements * elementHeight > listingHolder.size.h) then
			for i,v in pairs(listElements) do
				v:hide()
			end

			local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
			scrollBar:makeScrollBar(listingHolder, listElements, toReload, nil, nil, true)
			scrollBar.bgColor = { 0, 0, 0, 0 }
			scrollBar.hoverColor = { 0, 0, 0, 0 }
			scrollBar.pressedColor = { 0, 0, 0, 0 }
		else
			listingHolder:moveTo(0, math.ceil((listingHolder.size.h - #listElements * elementHeight) / 2), true)
		end

		return topBar, botBar
	end

	function Events:getEventInfo(id)
		local events = News:getEvents()

		if (not table.empty(events)) then
			events[id].accentColor = events[id].accentColor or TB_MENU_DEFAULT_BG_COLOR
			return events[id]
		else
			return false
		end
	end

	function Events:showBattlepassInfo()
		local allNews = News:getNews()
		for _,v in pairs(allNews) do
			if (v.isBattlePass) then
				Events:showEventInfo(v.eventid)
			end
		end
	end

	function Events:showEventInfo(id)
		if (not TB_STORE_DATA.ready) then
			TBMenu:showStatusMessage("Please wait until Store data is ready")
			return false
		end
		local event = Events:getEventInfo(id or 1)
		if (not event) then
			TBMenu:showStatusMessage("Please wait until News data is ready")
			return false
		end

		TB_MENU_SPECIAL_SCREEN_ISOPEN = 10
		local overlay = TBMenu:spawnWindowOverlay()
		local windowSize = math.min(WIN_H - 200, (WIN_W - 200) / 2)
		local viewElement = UIElement:new({
			parent = overlay,
			pos = { (WIN_W - windowSize * 2 + 200) / 2, (WIN_H - windowSize) / 1.6 },
			size = { windowSize * 2 - 200, windowSize },
			bgColor = event.accentColor,
			uiColor = event.uiColor,
			shapeType = ROUNDED,
			rounded = 5
		})
		overlay:addMouseHandlers(nil, function()
				TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
				overlay:kill()
			end)
		if (event.eventid or event.image) then
			local backgroundImage = viewElement:addChild({
				shift = { 0, 60 },
				bgImage = { event.image ~= nil and event.image or ("../textures/menu/promo/events/" .. event.eventid .. ".tga"), "" },
				imageColor = event.overlaytransparency and { 1, 1, 1, 1 - event.overlaytransparency } or nil,
				disableUnload = true
			})
		end

		local descriptionView = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { event.prizes and viewElement.size.w * 0.6 or viewElement.size.w, viewElement.size.h }
		})
		local dtopBar, dbotBar = Events:showEventDescription(descriptionView, event)
		local ptopBar, pbotBar = dtopBar, dbotBar
		if (event.prizes) then
			local prizesView = UIElement:new({
				parent = viewElement,
				pos = { descriptionView.size.w, 0 },
				size = { viewElement.size.w - descriptionView.size.w, viewElement.size.h }
			})
			ptopBar, pbotBar = Events:showEventPrizes(prizesView, event)
		end

		local eventName = UIElement:new({
			parent = dtopBar,
			pos = { 10, 5 },
			size = { viewElement.size.w - (dtopBar.size.h - 30), dtopBar.size.h - 10 },
			bgColor = event.accentColor
		})
		if (event.prizes) then
			table.insert(ptopBar.child, eventName)
		end
		eventName:addAdaptedText(true, event.name, nil, nil, FONTS.BIG, nil, 0.75, nil, 0.5)

		local eventForumLinkHolderBG = dbotBar:addChild({
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, dbotBar.size.h },
			bgColor = event.accentColor,
			uiColor = event.accentColor
		})
		local eventForumLinkHolder = eventForumLinkHolderBG:addChild({ shift = { 100, 0 } })
		local buttonHColor, buttonPColor, delta = nil, nil, nil
		if (event.buttonHoverColor and event.buttonPressedColor) then
			buttonHColor = event.buttonHoverColor
			buttonPColor = event.buttonPressedColor
			delta = buttonHColor[1] + buttonHColor[2] + buttonHColor[3]
		else
			buttonHColor = table.clone(viewElement.uiColor)
			buttonPColor = table.clone(viewElement.uiColor)
			local delta = buttonHColor[1] + buttonHColor[2] + buttonHColor[3]
			if (delta > 1.5) then
				buttonHColor[2] = (buttonHColor[2] - math.abs(0.8 - buttonHColor[2]))
				buttonHColor[3] = (buttonHColor[3] - math.abs(0.8 - buttonHColor[3]))
				buttonPColor[2] = (buttonPColor[2] - math.abs(0.85 - buttonPColor[2]))
				buttonPColor[3] = (buttonPColor[3] - math.abs(0.85 - buttonPColor[3]))
			else
				buttonHColor[1] = (buttonHColor[1] + math.abs(0.6 - buttonHColor[1]))
				buttonPColor[1] = (buttonPColor[1] + math.abs(0.7 - buttonPColor[1]))
			end
		end

		local buttons = 0
		if (event.forumlink) then
			buttons = buttons + 1
		end
		if (event.action and TB_MENU_PLAYER_INFO.username ~= '') then
			buttons = buttons + 1
		end
		if (event.forumlink) then
			local eventForumLink = UIElement:new({
				parent = eventForumLinkHolder,
				pos = { buttons == 2 and 0 or eventForumLinkHolder.size.w * 0.3, 10 },
				size = { buttons == 2 and eventForumLinkHolder.size.w / 2.2 or eventForumLinkHolder.size.w * 0.4, eventForumLinkHolder.size.h - 20 },
				interactive = true,
				bgColor = viewElement.uiColor,
				hoverColor = buttonHColor,
				pressedColor = buttonPColor,
				shapeType = ROUNDED,
				rounded = 3
			})
			table.insert(pbotBar.child, eventForumLink)
			TBMenu:showTextExternal(eventForumLink, "View event on forums", true)
			eventForumLink:addMouseHandlers(nil, function()
					open_url(event.forumlink)
				end)
		end
		if (event.action and TB_MENU_PLAYER_INFO.username ~= '') then
			local eventActionButton = UIElement:new({
				parent = eventForumLinkHolder,
				pos = { buttons == 2 and -eventForumLinkHolder.size.w / 2.2 or eventForumLinkHolder.size.w * 0.3, 10 },
				size = { buttons == 2 and eventForumLinkHolder.size.w / 2.2 or eventForumLinkHolder.size.w * 0.4, eventForumLinkHolder.size.h - 20 },
				interactive = true,
				bgColor = viewElement.uiColor,
				hoverColor = buttonHColor,
				pressedColor = buttonPColor,
				shapeType = ROUNDED,
				rounded = 3
			})
			local eventActionDownloadManager = UIElement:new({
				parent = eventActionButton,
				pos = { 0, 0 },
				size = { 0, 0 }
			})
			eventActionDownloadManager.life = -1
			eventActionDownloadManager:addCustomDisplay(true, function()
				eventActionDownloadManager.life = eventActionDownloadManager.life + 1
				local downloads = get_downloads()
				for i,v in pairs(downloads) do
					if (v:find(event.eventid)) then
						eventActionButton:deactivate()
						return
					end
				end
				eventActionButton:activate()
				if ((#downloads == 0 and eventActionDownloadManager.life > 50) or eventActionDownloadManager.life > 600) then
					eventActionDownloadManager:kill()
				end
			end)
			table.insert(pbotBar.child, eventActionButton)
			eventActionButton:addAdaptedText(false, event.actionText)
			eventActionButton:addMouseHandlers(nil, function()
					close_menu()
					event.action()
				end)
		end

		local closeButton = UIElement:new({
			parent = ptopBar,
			pos = { -(ptopBar.size.h - 10), 10 },
			size = { ptopBar.size.h - 20, ptopBar.size.h - 20 },
			bgColor = viewElement.uiColor,
			hoverColor = buttonHColor,
			pressedColor = buttonPColor,
			rounded = 3,
			shapeType = ROUNDED,
			interactive = true
		})
		local closeImage = UIElement:new({
			parent = closeButton,
			pos = { 5, 5 },
			size = { closeButton.size.w - 10, closeButton.size.h - 10 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga",
			imageColor = viewElement.bgColor
		})
		table.insert(dtopBar.child, closeButton)
		closeButton:addMouseHandlers(nil, function()
				TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
				overlay:kill()
			end)
		if (event.eventid) then
			if (not EventsOnline:checkFiles(event.eventid, event.requireMod)) then
				download_server_file('tutorial_' .. event.eventid, 0)
			end
		end
	end
end
