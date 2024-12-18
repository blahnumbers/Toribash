-- Events manager class
require('toriui.uielement')
require('system.menu_manager')
require('system.store_manager')
require('system.friends_manager')

do
	Events = {}
	Events.__index = Events

	function Events:quit()
		TBMenu:clearNavSection()
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

	--[[ Movember event UI
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
			loadingView:addAdaptedText(false, text)
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
			viewElement:addAdaptedText(false, text)
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
	]]

	---@class ModChampionshipInfo
	---@field loaded boolean
	---@field mod string
	---@field objective integer
	---@field progress integer
	---@field reward integer
	---@field timeleft integer

	---@class ModChampionshipPlayerRankingStats
	---@field elo number
	---@field rank integer
	---@field wins integer
	---@field losses integer

	---@class ModChampionshipPlayerReward
	---@field tc integer
	---@field st integer
	---@field itemid integer
	---@field requirement integer
	---@field claimed boolean

	---@class ModChampionshipPlayerStats
	---@field games integer
	---@field ranking ModChampionshipPlayerRankingStats
	---@field rewards ModChampionshipPlayerReward[]

	function Events:loadModChampionship(viewElement, eventid)
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Events:getNavigationButtons(TB_MENU_EVENTS_OPEN, eventid), true)
		RoomList.RefreshIfNeeded()

		local loadingView = viewElement:addChild({
			shift = { 5, 0 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(loadingView, 1)
		TBMenu:displayLoadingMark(loadingView, TB_MENU_LOCALIZED.EVENTSLOADING)

		local function throwError(text)
			loadingView:kill(true)
			TBMenu:addBottomBloodSmudge(loadingView, 1)
			loadingView:addAdaptedText(false, text)
		end

		---@type ModChampionshipInfo
		local champInfo = { loaded = false }
		---@type ModChampionshipPlayerStats
		local playerData = { games = 0, ranking = { wins = 0, losses = 0 } }
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
						local rewardid = info:gsub(";.*$", '') + 0
						info = info:gsub("^%d;", '')
						local data = { info:match(("([^\t]*)\t"):rep(5)) }
						playerData.rewards[rewardid] = { tc = data[1] + 0, st = data[2] + 0, itemid = data[3] + 0, requirement = data[4] + 0, claimed = data[5] == '1' and true or false }
					end
				end
				if (playerData.rewards) then
					playerData.rewards = table.qsort(playerData.rewards, 'requirement')
				end
				if (loadingView ~= nil and loadingView.isDisplayed and loadingView:isDisplayed()) then
					loadingView:kill()
					Events:showModChampionship(viewElement, champInfo, playerData)
				end
			end, function()
				throwError(TB_MENU_LOCALIZED.REQUESTCONNECTIONERROR)
			end)
	end

	---Displays mod championship rewards
	---@param viewElement UIElement
	---@param playerStats ModChampionshipPlayerStats
	function Events:showModChampionshipPlayerRewards(viewElement, playerStats)
		local shiftY = 0
		local prizeHolderHeight = math.min(70, (viewElement.size.h / #playerStats.rewards) - 8)
		local rewardTypes = { "tc", "st", "itemid" }
		local prizeIconHeight = math.min(viewElement.size.w / (2 * #rewardTypes) - 5, prizeHolderHeight - 10)
		local claimButtons = { }
		for _, prize in pairs(playerStats.rewards) do
			local isAvailable = not prize.claimed and prize.requirement <= playerStats.games
			local prizeHolder = viewElement:addChild({
				pos = { 0, shiftY },
				size = { viewElement.size.w, prizeHolderHeight },
				interactive = isAvailable,
				bgColor = isAvailable and TB_MENU_DEFAULT_ORANGE or TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
				pressedColor = TB_MENU_DEFAULT_YELLOW,
				inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
				shapeType = ROUNDED,
				rounded = 10
			})
			local prizeText = prizeHolder:addChild({
				pos = { 10, 5 },
				size = { prizeHolder.size.w / 2, prizeHolderHeight - 10 },
				uiColor = isAvailable and TB_MENU_DEFAULT_DARKEST_COLOR or UICOLORWHITE,
				uiShadowColor = UICOLORWHITE,
				shadowOffset = 3
			})
			prizeHolder.textView = prizeText
			if (isAvailable) then
				table.insert(claimButtons, prizeHolder)
				prizeText:addAdaptedText(true, TB_MENU_LOCALIZED.REWARDSCLAIM, nil, nil, nil, LEFTMID, nil, nil, nil, 3)
				prizeHolder:addMouseUpHandler(function()
						for _, v in pairs(claimButtons) do
							v:deactivate()
						end
						local claimSuccess = nil
						local claimOverlay = prizeHolder:addChild({
							pos = { 0, 0 },
							size = { (prizeHolder.rounded or 1) * 2, prizeHolder.size.h },
							interactive = true,
							bgColor = TB_MENU_DEFAULT_DARKER_ORANGE
						}, true)
						local claimProgress = prizeHolder:addChild({})
						TBMenu:displayLoadingMark(claimProgress, nil, (prizeHolder.size.h - 10) / 3)

						Request:queue(function() claim_quest(-1) end, "modchampionship_claimreward", function()
								local response = get_network_response()
								if (response:find("^GATEWAY 0; 1")) then
									claimSuccess = true
								else
									claimSuccess = false
									TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REWARDSCLAIMERROROTHER)
								end
							end, function()
								claimSuccess = false
								TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORTRYAGAIN .. "\n" .. get_network_error())
							end)
						local spawnClock = UIElement.clock
						claimOverlay:addCustomDisplay(function()
								local progress = (UIElement.clock - spawnClock) / 1.6
								claimOverlay.size.w = math.ceil(math.max(claimOverlay.size.w, UITween.SineTween(claimOverlay.size.w, prizeHolder.size.w, progress)))
								if ((progress >= 1 or claimOverlay.size.w >= prizeHolder.size.w) and claimSuccess ~= nil) then
									claimProgress:kill()
									if (claimSuccess == true) then
										for _, v in pairs(claimButtons) do
											v.inactiveColor = TB_MENU_DEFAULT_DARKER_COLOR
											--Set transparent color so that addAdaptedText call doesn't draw anything on top
											v.textView.uiColor = { 1, 1, 1, 0 }
											if (v.textView) then
												v.textView:addAdaptedText(true, TB_MENU_LOCALIZED.REWARDSCLAIMSUCCESS, nil, nil, nil, LEFTMID)
											end
											v.textView.uiColor[4] = 1
										end
									end
									local spawnClock = UIElement.clock
									claimOverlay:addCustomDisplay(function()
											local progress = (UIElement.clock - spawnClock) / 1.6
											claimOverlay.size.w = math.floor(UITween.SineTween(claimOverlay.size.w, 0, progress))
											claimOverlay:moveTo(-claimOverlay.size.w)
											if (progress >= 1 or claimOverlay.size.w / 2 < (claimOverlay.rounded or 1)) then
												if (claimSuccess == false) then
													for _, v in pairs(claimButtons) do
														v:activate()
													end
												end
												claimOverlay:kill()
											end
										end)
								end
							end)
					end)
			elseif (not prize.claimed) then
				prizeText:addAdaptedText(true, prize.requirement - playerStats.games .. " " .. TB_MENU_LOCALIZED.EVENTSWINSTOUNLOCK, nil, nil, nil, LEFTMID)
			else
				prizeText:addAdaptedText(true, TB_MENU_LOCALIZED.REWARDSCLAIMSUCCESS, nil, nil, nil, LEFTMID)
			end

			shiftY = shiftY + prizeHolder.size.h + 8
			local i = 0
			for _, v in pairs(rewardTypes) do
				if (type(prize[v]) == "number" and prize[v] > 0) then
					i = i + 1
					local rewardHolder = prizeHolder:addChild({
						pos = { -(i * (prizeIconHeight + 2) + 3), (prizeHolder.size.h - prizeIconHeight) / 2 },
						size = { prizeIconHeight, prizeIconHeight },
						shapeType = ROUNDED,
						rounded = 4
					})
					---@type BattlePassReward
					local prizeItem = {
						bgColor = TB_MENU_DEFAULT_BG_COLOR,
						bgOutlineColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						claimed = prize.claimed,
						static = true
					}
					prizeItem[v] = prize[v]
					BattlePass:showPrizeItem(rewardHolder, prizeItem)
				end
			end
		end
		viewElement.size.h = shiftY
	end

	---Connects the player to the most suitable modmania room
	function Events:modChampionshipConnect()
		local players = RoomList.GetPlayers()

		local defaultRoom, rooms = "modmania1", { "modmania%d" }
		local roomsOnline = {}
		for _, online in pairs(players) do
			for _, roomname in pairs(rooms) do
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
			for _, room in pairs(roomsOnline) do
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

	---Displays mod championship toplist with the specified mode
	---@param toReload UIElement
	---@param listingHolder UIElement
	---@param elementHeight integer
	---@param toplist table
	---@param mode integer
	---@return UIElement
	function Events:showModChampionshipToplist(toReload, listingHolder, elementHeight, toplist, mode)
		MODCHAMPIONSHIP_TOPLIST_MODE = mode and mode or 0
		local modeName = MODCHAMPIONSHIP_TOPLIST_MODE == 1 and "ranking" or "games"
		local listElements = {}
		for i,v in pairs(toplist[modeName]) do
			local topPlayerHolder = listingHolder:addChild({
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, topPlayerHolder)
			local topPlayerEntry = topPlayerHolder:addChild({
				pos = { 10, 3 },
				size = { topPlayerHolder.size.w - 10, topPlayerHolder.size.h - 6 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				shapeType = ROUNDED,
				rounded = 3
			})
			local topPlayerPlace = topPlayerEntry:addChild({
				pos = { 10, 5 },
				size = { 30, topPlayerEntry.size.h - 10 }
			})
			topPlayerPlace:addAdaptedText(true, "#" .. i, nil, nil, 4, nil, 0.7)
			local topPlayerName = topPlayerEntry:addChild({
				pos = { 50, 5 },
				size = { (topPlayerEntry.size.w - 60) * 0.7, topPlayerEntry.size.h - 10 }
			})
			topPlayerName:addAdaptedText(true, v.name, nil, nil, nil, LEFTMID)
			local topPlayerGames = topPlayerEntry:addChild({
				pos = { -(topPlayerEntry.size.w - 60) * 0.3 - 10, 5 },
				size = { (topPlayerEntry.size.w - 60) * 0.3, topPlayerEntry.size.h - 10 }
			})

			if (v.games) then
				topPlayerGames:addAdaptedText(true, v.games .. " " .. string.lower(TB_MENU_LOCALIZED.EVENTSGAMESWON), nil, nil, 4, nil, 0.65)
			elseif (v.rank) then
				topPlayerGames:addAdaptedText(true, v.elo .. " elo", nil, nil, 4, nil, 0.6)
			end
		end
		for _, v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
		return scrollBar
	end

	---Displays mod championship main screen
	---@param viewElement UIElement
	---@param champInfo ModChampionshipInfo
	---@param playerStats ModChampionshipPlayerStats
	function Events:showModChampionship(viewElement, champInfo, playerStats)
		local playerStatsHolder = viewElement:addChild({
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

		local lastHolder = playerGamesHolder
		--[[local hasRank = (playerStats.ranking.wins + playerStats.ranking.losses) >= 10
		local playerRankHolder = UIElement:new({
			parent = playerStatsHolder,
			pos = { playerGamesHolder.shift.x, playerGamesHolder.shift.y + playerGamesHolder.size.h + 5 },
			size = { playerGamesHolder.size.w, playerGamesHolder.size.h }
		})
		playerRankHolder:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANK .. (hasRank and (" " .. playerStats.ranking.rank .. ' (' .. playerStats.ranking.elo .. " elo)") or (": " .. TB_MENU_LOCALIZED.MATCHMAKEQUALIFYING)), nil, nil, FONTS.MEDIUM, CENTER)
		lastHolder = playerRankHolder]]

		local buttonHeight = 60
		if (playerStats.rewards) then
			local playerGamesRewards = playerStatsHolder:addChild({
				pos = { 10, lastHolder.shift.y + lastHolder.size.h + 20 },
				size = { playerStatsHolder.size.w - 20, playerStatsHolder.size.h - lastHolder.shift.y - lastHolder.size.h - 20 }
			})
			Events:showModChampionshipPlayerRewards(playerGamesRewards, playerStats)
			buttonHeight = math.min(buttonHeight, playerStatsHolder.size.h - playerGamesRewards.size.h - 35)
		end
		if (buttonHeight > 35) then
			local joinButton = playerStatsHolder:addChild({
				pos = { 10, -buttonHeight - 15 },
				size = { playerStatsHolder.size.w - 20, buttonHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			joinButton:addAdaptedText(false, TB_MENU_LOCALIZED.FRIENDSLISTJOINROOM)
			joinButton:addMouseHandlers(nil, function() Events:modChampionshipConnect() end)
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
			pos = { (globalChallengeHolder.size.w - bgScale) / 2, globalChallengeTimeleft.shift.y + globalChallengeTimeleft.size.h + 15 },
			size = { bgScale, bgScale },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			uiColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = bgScale
		})
		local progress = champInfo.progress / champInfo.objective
		if (progress > 1) then
			progress = 1
			questBackground.bgColor = table.clone(TB_MENU_DEFAULT_DARKER_ORANGE)
			questBackground.uiColor = table.clone(TB_MENU_DEFAULT_ORANGE)
		end

		local questIcon = questBackground:addChild({
			shift = { bgScale / 3, bgScale / 3 }
		})
		---@type BattlePassReward
		local prizeItem = {
			bgColor = questBackground.uiColor,
			bgOutlineColor = questBackground.bgColor,
			itemid = champInfo.reward,
			static = true,
			locked = progress < 1
		}
		BattlePass:showPrizeItem(questIcon, prizeItem)

		local is_mobile = is_mobile()
		questBackground:addCustomDisplay(false, function()
				set_color(unpack(questBackground.uiColor))
				draw_disk(questBackground.pos.x + questBackground.size.w / 2, questBackground.pos.y + questBackground.size.h / 2, questBackground.size.h / 2.75, questBackground.size.h / 2 - 5, is_mobile and 0 or 50, 1, -60, -240, 0)
				set_color(unpack(UICOLORWHITE))
				draw_disk(questBackground.pos.x + questBackground.size.w / 2, questBackground.pos.y + questBackground.size.h / 2, questBackground.size.h / 2.75, questBackground.size.h / 2 - 5, is_mobile and 0 or 50, 1, -60, -240 * progress, 0)
			end)
		local progressText = UIElement:new({
			parent = questBackground,
			pos = { 0, -questBackground.size.h / 4.5 },
			size = { questBackground.size.w, questBackground.size.h / 4.5 },
			shapeType = ROUNDED,
			rounded = 10,
			bgColor = questBackground.uiColor,
			uiColor = UICOLORWHITE,
			uiShadowColor = TB_MENU_DEFAULT_DARKEST_ORANGE,
			shadowOffset = 3
		})
		if (progress == 1) then
			progressText:addAdaptedText(false, TB_MENU_LOCALIZED.EVENTSCOMPLETED .. "!", nil, nil, FONTS.BIG, nil, 0.6, nil, nil, 6)
		else
			progressText:addAdaptedText(false, champInfo.progress .. " / " .. champInfo.objective .. "\n" .. TB_MENU_LOCALIZED.WORDGAMES)
		end

		local globalRewardInfo = globalChallengeHolder:addChild({
			pos = { 20, questBackground.shift.y + questBackground.size.h + 5 },
			size = { globalChallengeHolder.size.w - 40, globalChallengeHolder.size.h - questBackground.shift.y - questBackground.size.h - 20 }
		})
		globalRewardInfo:addAdaptedText(true, TB_MENU_LOCALIZED.MODCHAMPIONSHIPGLOBALREWARDINFO, nil, nil, FONTS.LMEDIUM, nil, 0.8)

		local toplist = { games = {}, ranking = {} }
		local playersToplistHolder = UIElement:new({
			parent = viewElement,
			pos = { globalChallengeHolder.size.w + globalChallengeHolder.shift.x + 10, 0 },
			size = { viewElement.size.w * 0.35 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local elementHeight = 50
		local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(playersToplistHolder, elementHeight, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)
		listingHolder.hasDataLoaded = false

		local toplistTitle = topBar:addChild({
			pos = { 10, 5 },
			size = { topBar.size.w - 20, topBar.size.h - 10 }
		})
		toplistTitle:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSTOPLIST, nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
		TBMenu:addBottomBloodSmudge(botBar, 3)
		--[[local toplistModeGames = UIElement:new({
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
			end)]]

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
				if (listingHolder ~= nil and listingHolder.isDisplayed and listingHolder:isDisplayed()) then
					listingHolder.hasDataLoaded = true
					Events:showModChampionshipToplist(toReload, listingHolder, elementHeight, toplist, 0)
					--[[if (MODCHAMPIONSHIP_TOPLIST_MODE == 1) then
						toplistModeRank.btnUp()
					else
						toplistModeGames.btnUp()
					end]]
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
		showPrize("../textures/store/toricredit.tga", numberFormat(data.tc) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS, 1 + posShift)
		showPrize("../textures/store/shiaitoken.tga", numberFormat(data.st) .. " " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS, 2 + posShift)
		if (data.itemid ~= 0) then
			local itemInfo = Store:getItemInfo(data.itemid)
			showPrize(itemInfo:getIconPath(), itemInfo.itemname, 3)
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
				if (eventInfo.ready and Store.Ready) then
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
				liveCaption:addAdaptedText(false, TB_MENU_LOCALIZED.EVENTSLIVE:upper(), nil, nil, 4, nil, 0.5, 0.5, nil, 2)
				shiftX = shiftX + liveCaption.shift.x + liveCaption.size.w
			end
			local listEventName = UIElement:new({
				parent = listEvent,
				pos = { 10 + shiftX, 5 },
				size = { listEvent.size.w - shiftX - 20, listEvent.size.h - 10 }
			})
			listEventName:addAdaptedText(false, eventInfo.name, nil, nil, nil, LEFTMID, nil, nil, 0.2)

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
		News:getNews()

		local newsData = {}
		---table.clone() may fail, do a soft copy of upper level only
		for _, v in pairs(News.Cache) do
			table.insert(newsData, v)
		end
		local count = #newsData
		for i = count, 1, -1 do
			if (not newsData[i].isEvent or newsData[i].isBattlePass) then
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
			bgImage = prize.icon or Store:getItemIcon(prize.itemid)
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

	---Displays event prizes in a specified UIElement viewport
	---@param viewElement UIElement
	---@param event NewsEventItemData
	---@return UIElement
	---@return UIElement
	function Events:showEventPrizes(viewElement, event)
		local elementHeight = 41
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 60, 60, 20, event.accentColor)

		listingScrollBG.bgColor = { 0, 0, 0, 0 }
		local listElements = {}
		--[[if (event.prizes.imagetitle) then
			local imageScale = elementHeight * 8 > listingHolder.size.w - 20 and (listingHolder.size.w - 20) / 8 or elementHeight
			local infoTitle = UIElement:new({
				parent = listingHolder,
				pos = { listingHolder.size.w / 2 - imageScale * 4, #listElements * elementHeight },
				size = { imageScale * 8, imageScale },
				bgImage = event.prizes.imagetitle
			})
			table.insert(listElements, infoTitle)
		else]]
			local infoTitle = UIElement:new({
				parent = listingHolder,
				pos = { 10, #listElements * elementHeight },
				size = { listingHolder.size.w - 20, elementHeight }
			})
			infoTitle:addAdaptedText(true, "Prizes", nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
			table.insert(listElements, infoTitle)
		--end

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

			local prizesToShow = {}
			if (prize.tc) then
				table.insert(prizesToShow, {
					itemname = numberFormat(prize.tc) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS,
					icon = "../textures/store/toricredit.tga"
				})
			end
			if (prize.st) then
				table.insert(prizesToShow, {
					itemname = prize.st .. " " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS,
					icon = "../textures/store/shiaitoken.tga"
				})
			end
			if (prize.bpxp) then
				table.insert(prizesToShow, {
					itemname = numberFormat(prize.bpxp) .. " " .. TB_MENU_LOCALIZED.BATTLEPASSEXPERIENCE,
					icon = "../textures/menu/battlepass/experience.tga"
				})
			end
			if (prize.itemids) then
				for _, id in pairs(prize.itemids) do
					table.insert(prizesToShow, Store:getItemInfo(id))
				end
			end
			for _, v in pairs(prizesToShow) do
				local itemRewardView = Events:showPrizeInfo(v, listingHolder, #listElements, elementHeight)
				table.insert(listElements, itemRewardView)
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
		News:getNews()
		for _,v in pairs(News.Cache) do
			if (v.isBattlePass) then
				Events:showEventInfo(v.eventid)
			end
		end
	end

	function Events:showEventInfo(id)
		if (not Store.Ready) then
			TBMenu:showStatusMessage("Please wait until Store data is ready")
			return false
		end
		local event = Events:getEventInfo(id or 1)
		if (not event) then
			TBMenu:showStatusMessage("Please wait until News data is ready")
			return false
		end

		TB_MENU_SPECIAL_SCREEN_ISOPEN = 1000
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
		viewElement.killAction = function()
			if (TB_MENU_SPECIAL_SCREEN_ISOPEN == 1000) then
				TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
			end
		end
		overlay:addMouseHandlers(nil, function()
				overlay:kill()
			end)
		if (event.eventid or event.image) then
			local backgroundImage = viewElement:addChild({
				shift = { 0, 60 },
				bgImage = { event.image ~= nil and event.image or ("../textures/menu/promo/events/" .. event.eventid .. ".tga"), "" },
				imageColor = { 1, 1, 1, 1 - (event.overlaytransparency or 0) },
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
				overlay:kill()
			end)
		if (event.eventid) then
			if (not EventsOnline:checkFiles(event.eventid, event.requireMod)) then
				download_server_file('tutorial_' .. event.eventid, 0)
			end
		end
	end
end
