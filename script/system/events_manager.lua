-- Events manager class
require('toriui.uielement')
require('system.menu_manager')
require('system.store_manager')
require('system.friends_manager')

---@class EventRewardBase
---@field tc integer
---@field st integer
---@field itemid integer
---@field bpxp integer
---@field qi integer

---@class StaticEventReward : EventRewardBase
---@field info string

---@class BlindFightPlayer
---@field userid string
---@field name string
---@field wins integer
---@field prestige integer

---@class BlindFightRPG
---@field strength integer
---@field speed integer
---@field endurance integer

---@class BlindFightData
---@field modName string
---@field endtime integer
---@field seasonEndtime integer
---@field lastupdate integer
---@field players BlindFightPlayer[]
---@field defeated string[]
---@field groupTitle string
---@field gamesPlayed integer
---@field gamesWon integer
---@field userMoves MemoryMove|nil
---@field minVersion integer?
---@field numGroupPlayers integer
---@field minPromoteGroupPlayers integer
---@field pendingRewards boolean
---@field tierRewards EventRewardBase[]
---@field prestigeRewards EventRewardBase[]
---@field userRPG BlindFightRPG
---@field promotePlayersPercentage number
---@field userStats BlindFightPlayer
---@field rpgDecayRate number

if (Events == nil) then
	---**Events manager class**
	---
	---**Version 5.74**
	---* Update to match modern design
	---* Blind Fight interface and client logic
	---@class Events
	---@field EventStalePeriod integer Period in seconds before event data is considered stale
	---@field BlindFightMode integer Blind Fight launch mode
	---@field LastEventSection integer Last active static event section
	Events = {
		EventStalePeriod = 600,
		BlindFightMode = 0,
		LastEventSection = 1,
		HomeListShift = { 0 },
		HookName = "__tbEventsManager",
		ver = 5.74
	}
	Events.__index = Events
end

---@class StaticEventInfo
---@field rewards StaticEventReward[]
---@field claimed integer Highest reward tier claimed by player

---@class EventsInternal
---@field ConfigFile string Config file path
---@field Config table Table containing configuration option values
---@field BlindFight ?BlindFightData Blind Fight event data for current user
---@field EventStorage ?StaticEventInfo[] Static event info cache
---@field StaticEventVersion integer Last game build that featured new static events
local EventsInternal = {
	ConfigFile = "../data/events.cfg",
	Config = { },
	BlindFight = nil,
	EventStorage = nil,
	StaticEventVersion = 250305
}

function EventsInternal.LoadConfig()
	local f = Files.Open(EventsInternal.ConfigFile, FILES_MODE_READONLY)
	local configLines = f:readAll()
	f:close()

	EventsInternal.Config = {
		BlindFightPlays = 0
	}
	for _, line in ipairs(configLines) do
		local data = { line:match(("([^\t]*)\t?"):rep(2)) }
		data[2] = tonumber(data[2])
		if (data[2] ~= nil) then
			EventsInternal.Config[data[1]] = data[2]
		end
	end
end

function EventsInternal.SaveConfig()
	local f = Files.Open(EventsInternal.ConfigFile, FILES_MODE_WRITE)
	for i, v in pairs(EventsInternal.Config) do
		f:writeLine(i .. "\t" .. tostring(v))
	end
	f:close()
end

---Returns Events configuration option value
---@param option string
---@return integer
function Events.GetConfig(option)
	return EventsInternal.Config[option]
end

---Sets Events configuration option value and saves changes if needed
---@param option string
---@param value integer
---@param save boolean
---@overload fun(option: string, value: integer)
function Events.SetConfig(option, value, save)
	if (EventsInternal.Config[option] == value) then
		return
	end
	EventsInternal.Config[option] = value
	if (save == nil or save == true) then
		EventsInternal.SaveConfig()
	end
end

---Exits Events menu and opens last opened main menu screen
function Events.Quit()
	TBMenu:clearNavSection()
	TBMenu:showNavigationBar()
	TB_MENU_EVENTS_OPEN = false
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
	TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
end

---Resets any cached events data for current user
function EventsInternal.Reset()
	EventsInternal.BlindFight = nil
	EventsInternal.EventStorage = nil
	Events:refreshBlindFight()
end

---Returns a table containing current Blind Fight state
---@return BlindFightData?
function Events.GetBlindFight()
	local dataCopy = table.clone(EventsInternal.BlindFight)
	if (dataCopy ~= nil and dataCopy.userMoves ~= nil) then
		setmetatable(dataCopy.userMoves, MemoryMove)
	end
	return dataCopy
end

---@param showBack boolean?
---@param showEventid integer?
---@return MenuNavButton[]
function Events:getNavigationButtons(showBack, showEventid)
	local navigation = {
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
			action = Events.Quit
		}
	}
	if (showBack) then
		table.insert(navigation, {
			text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
			action = Events.ShowHome
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
---@field rooms string[]

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

---Loads information about mod championship event with the specified id
---@param viewElement UIElement
---@param eventid integer
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
	local champInfo = { loaded = false, rooms = { "modmania%d" } }
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
				ln = ln:gsub("\n$", '')
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
				elseif (ln:find("^CHAMPROOMS 0;")) then
					ln = ln:gsub("^CHAMPROOMS 0;", "")
					local _, segments = ln:gsub("\t", "")
					champInfo.rooms = { ln:match(("([^\t]*)\t"):rep(segments)) }
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
---@param rooms string[]
function Events:modChampionshipConnect(rooms)
	local players = RoomList.GetPlayers()

	local defaultRoom = string.gsub(rooms[1], "%%d", "1")
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
		joinButton:addMouseHandlers(nil, function() Events:modChampionshipConnect(champInfo.rooms) end)
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

---@class EventBaseInfo
---@field shortname string
---@field name string
---@field description string?
---@field id integer?

---Returns event name as specified in its data file
---@param filename string
---@return EventBaseInfo
function EventsInternal.GetEventBaseInfo(filename)
	local eventInfo = {
		shortname = string.gsub(filename, "(.+)%.dat$", '%1')
	}
	if (string.find(eventInfo.shortname, "[\\/]")) then
		eventInfo.shortname = string.gsub(eventInfo.shortname, "^.*[\\/]", '')
	end
	eventInfo.name = eventInfo.shortname

	local file = Files.Open("../data/script/events/" .. filename, FILES_MODE_READONLY)
	if (not file.data) then
		return eventInfo
	end
	local lines = file:readAll()
	file:close()

	for _, ln in pairs(lines) do
		if (ln:find("^EVENTNAME 0;")) then
			eventInfo.name = ln:gsub("^EVENTNAME 0;", '')
		elseif (ln:find("^EVENTDESC 0;")) then
			eventInfo.description = ln:gsub("^EVENTDESC 0;", '')
		elseif (ln:find("^EVENTID 0;")) then
			eventInfo.id = ln:gsub("^EVENTID 0;", '')
			eventInfo.id = tonumber(eventInfo.id)
		elseif (ln:find("^STEP")) then
			break
		end
	end
	return eventInfo
end

--[[
---Displays event winners for available events
---@param viewElement UIElement
---@param data table
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
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(eventsListHolder, elementHeight, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)
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
]]

---Queues a request to fetch information about all available static event rewards. \
---Results will be cached in `EventsInternal.EventStorage` on success.
function Events.FetchStaticEvents()
	Request:queue(function()
		download_server_info("events_static&username=" .. TB_MENU_PLAYER_INFO.username)
	end, "eventManagerStaticEvents", function(_, response)
		if (response:find("^Error")) then
			TBMenu:showStatusMessage(response)
			return
		end
		EventsInternal.EventStorage = { }
		for ln in response:gmatch("[^\n]+\n?") do
			local _, segments = ln:gsub("([^\t]*)\t?", "")
			local data = { ln:match(("([^\t]*)\t?"):rep(segments)) }
			local eventid = tonumber(data[1])
			if (eventid ~= nil) then
				EventsInternal.EventStorage[eventid] = EventsInternal.EventStorage[eventid] or {
					rewards = { }, claimed = 0
				}
				local rewardid = tonumber(data[2])
				if (rewardid ~= nil) then
					EventsInternal.EventStorage[eventid].rewards[rewardid] = {
						tc = tonumber(data[4]) or 0,
						st = tonumber(data[5]) or 0,
						itemid = tonumber(data[6]) or 0,
						bpxp = tonumber(data[7]) or 0,
						info = data[8]
					}
					if (data[3] == '1') then
						EventsInternal.EventStorage[eventid].claimed = math.max(rewardid, EventsInternal.EventStorage[eventid].claimed)
					end
				end
			end
		end
		if (table.size(EventsInternal.EventStorage) == 0) then
			EventsInternal.EventStorage = nil
		end
	end, function(_, response)
		EventsInternal.EventStorage = nil
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ACCOUNTINFOERROR .. ": " .. response)
	end)
end

---Displays information about a static event
---@param viewElement UIElement
---@param eventInfo EventBaseInfo
function EventsInternal.ShowStaticEventInfo(viewElement, eventInfo)
	viewElement:kill(true)
	TBMenu:addBottomBloodSmudge(viewElement, 2)

	local eventTitle = viewElement:addChild({
		pos = { 15, 10 },
		size = { viewElement.size.w - 30, 80 }
	})
	local eventName = utf8.gsub(eventInfo.name, ":", "\n")
	eventTitle:addAdaptedText(eventName, { font = FONTS.BIG, maxscale = 0.8 })
	if (#eventTitle.dispstr == 1) then
		eventTitle.size.h = 40
	end

	---Prepare a scrollable list for prizes area in case they don't fit.
	---To make sure we don't get visible bars, topBar acts as parent for description
	---and botBar as parent for play button
	local eventInfoHolder = viewElement:addChild({
		pos = { 0, eventTitle.shift.y + eventTitle.size.h },
		size = { viewElement.size.w, viewElement.size.h - eventTitle.shift.y - eventTitle.size.h }
	})
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(eventInfoHolder, 100, 85, 20, viewElement.bgColor)

	local eventDescription = topBar:addChild({
		pos = { eventTitle.shift.x, 0 },
		size = { eventTitle.size.w, topBar.size.h }
	})
	eventDescription:addAdaptedText(eventInfo.description or "", { font = FONTS.LMEDIUM })
	local playButton = botBar:addChild({
		pos = { eventTitle.shift.x, 10 },
		size = { eventTitle.size.w, botBar.size.h - 20 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	playButton:addAdaptedText(TB_MENU_LOCALIZED.EVENTSPLAY)
	playButton:addMouseUpHandler(function()
			close_menu()
			EventsOnline:playEvent(eventInfo.shortname)
		end)

	local displayPrizes = function()
		if (listingHolder.scrollBar ~= nil) then
			listingHolder.scrollBar.holder:kill()
		end
		listingHolder:kill(true)
		local storageEventInfo = EventsInternal.EventStorage[eventInfo.id]
		if (storageEventInfo == nil) then
			listingHolder:addChild({ shift = { 30, 20 }}):addAdaptedText(TB_MENU_LOCALIZED.EVENTSSTATICEVENTNOREWARDS)
			return
		end
		local listElements = {}
		local elementHeight = botBar.size.h
		for tier, v in pairs(storageEventInfo.rewards) do
			local isClaimed = tier <= storageEventInfo.claimed
			local prizeHolder = listingHolder:addChild({
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, prizeHolder)
			local prizeBackground = prizeHolder:addChild({
				pos = { 10, 2 },
				size = { prizeHolder.size.w - 12, prizeHolder.size.h - 4 },
				bgColor = isClaimed and TB_MENU_DEFAULT_DARKER_BLUE or TB_MENU_DEFAULT_DARKER_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			local prizeInfo = prizeBackground:addChild({
				pos = { 0, 4 },
				size = { prizeBackground.size.w / 2, prizeBackground.size.h - 8 }
			})
			prizeInfo:addAdaptedText(v.info, { font = FONTS.LMEDIUM, maxscale = 0.85, align = LEFTMID, padding = { x = 10 } })
			local prizesHolder = prizeBackground:addChild({
				pos = { prizeInfo.shift.x * 2 + prizeInfo.size.w, prizeInfo.shift.y },
				size = { prizeInfo.size.w, prizeInfo.size.h }
			})
			---@type BattlePassReward[]
			local prizesList = { }
			if (v.tc > 0) then
				table.insert(prizesList, {
					tc = v.tc,
					claimed = isClaimed,
					static = true
				})
			end
			if (v.st > 0) then
				table.insert(prizesList, {
					st = v.st,
					claimed = isClaimed,
					static = true
				})
			end
			if (v.itemid > 0) then
				table.insert(prizesList, {
					itemid = v.itemid,
					claimed = isClaimed,
					static = true
				})
			end
			if (v.bpxp > 0) then
				table.insert(prizesList, {
					bpxp = v.bpxp,
					claimed = isClaimed,
					static = true
				})
			end
			local prizeIconSize = math.min(prizesHolder.size.h, prizesHolder.size.w / #prizesList)
			for i, prize in pairs(prizesList) do
				local prizeDisplayHolder = prizesHolder:addChild({
					pos = { -i * prizeIconSize, 0 },
					size = { prizeIconSize - 10, prizeIconSize }
				})
				BattlePass:showPrizeItem(prizeDisplayHolder, prize)
			end
		end
		if (#listElements * elementHeight > listingHolder.size.h) then
			for _, v in ipairs(listElements) do
				v:hide()
			end
			local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
			listingHolder.scrollBar = scrollBar
			scrollBar:makeScrollBar(listingHolder, listElements, toReload)
		else
			listingHolder:moveTo(6)
		end
	end
	if (EventsInternal.EventStorage == nil) then
		TBMenu:displayLoadingMark(listingHolder)
		listingHolder:addCustomDisplay(function()
				if (EventsInternal.EventStorage == nil) then return end
				listingHolder:addCustomDisplay(false, nil)
				displayPrizes()
			end)
	else
		displayPrizes()
	end
end

function Events.ShowHome()
	TBMenu:clearNavSection()
	TBMenu:showNavigationBar({{
		text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
		action = Events.Quit
	}}, true)

	TB_MENU_SPECIAL_SCREEN_ISOPEN = 13

	if (EventsInternal.EventStorage == nil) then
		Events.FetchStaticEvents()
	end

	local eventInfos = {
		{
			image = "../textures/menu/promo/events/openerchallenge-static.tga",
			eventNameFormat = "^oc%d+%.dat$",
			events = {}, buttonParts = {}
		},
		{
			image = "../textures/menu/promo/events/freerunfrenzy-static.tga",
			eventNameFormat = "^frf%d+%.dat$",
			events = {}, buttonParts = {}
		},
		{
			image = "../textures/menu/promo/events/floorislava-static.tga",
			eventNameFormat = "^fil%d+%.dat$",
			events = {}, buttonParts = {}
		}
	}

	local eventsHolder = TBMenu.CurrentSection:addChild({
		pos = { 5, 0 },
		size = { math.min(TBMenu.CurrentSection.size.w * 0.6, 1000), TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:addBottomBloodSmudge(eventsHolder, 1)
	local eventTypeSelectorHolder = eventsHolder:addChild({
		pos = { 0, 0 },
		size = { eventsHolder.size.w * 0.4, eventsHolder.size.h }
	})
	local typeEventButtonsHolder = eventsHolder:addChild({
		pos = { eventTypeSelectorHolder.size.w, 0 },
		size = { eventsHolder.size.w - eventTypeSelectorHolder.size.w, eventsHolder.size.h }
	})

	local eventInfoHolder = TBMenu.CurrentSection:addChild({
		pos = { eventsHolder.shift.x + eventsHolder.size.w + 10, 0 },
		size = { TBMenu.CurrentSection.size.w - eventsHolder.shift.x * 2 - eventsHolder.size.w - 10, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(eventTypeSelectorHolder, 65, 50, 0, eventsHolder.bgColor)
	local toReload2, topBar2, botBar2, _, listingHolder2 = TBMenu:prepareScrollableList(typeEventButtonsHolder, topBar.size.h, botBar.size.h, 20, eventsHolder.bgColor)

	topBar2:moveTo(-topBar2.size.w - topBar.size.w)
	topBar2.size.w = eventsHolder.size.w
	topBar.size.w = eventsHolder.size.w
	topBar:addAdaptedText(TB_MENU_LOCALIZED.EVENTSSTATICEVENTS, { font = FONTS.BIG, maxscale = 0.8 })
	topBar2:addAdaptedText(TB_MENU_LOCALIZED.EVENTSSTATICEVENTS, { font = FONTS.BIG, maxscale = 0.8 })

	local elementHeight = math.min((listingHolder.size.w - 12) * 0.5625 / 5, 50)
	local listElements = {}
	local directoryContents = get_files("data/script/events", "dat")
	for id, v in ipairs(eventInfos) do
		for _, data in pairs(directoryContents) do
			if (string.match(data, v.eventNameFormat)) then
				table.insert(v.events, EventsInternal.GetEventBaseInfo(data))
			end
		end
		v.events = table.qsort(v.events, "name", SORT_ASCENDING)
		local showTypeEvents = function()
			Events.LastEventSection = id
			if (listingHolder2.scrollBar ~= nil) then
				listingHolder2.scrollBar.holder:kill()
			end
			listingHolder2:kill(true)
			local listElements2 = { }
			local selectedButton = nil
			for i, b in ipairs(v.events) do
				local buttonHolder = listingHolder2:addChild({
					pos = { 0, #listElements2 * 50 },
					size = { listingHolder2.size.w, 50 }
				})
				table.insert(listElements2, buttonHolder)
				local eventButton = buttonHolder:addChild({
					pos = { 8, 2 },
					size = { buttonHolder.size.w - 8, buttonHolder.size.h - 4 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					shapeType = ROUNDED,
					rounded = 4,
					clickThrough = true,
					hoverThrough = true
				})
				eventButton:addChild({ shift = { 10, 4 } }):addAdaptedText(b.name, { align = LEFTMID })
				eventButton:addMouseUpHandler(function()
					if (selectedButton ~= nil) then
						selectedButton.bgColor = TB_MENU_DEFAULT_DARKER_COLOR
						selectedButton.hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR
					end
					eventButton.bgColor = TB_MENU_DEFAULT_DARKER_BLUE
					eventButton.hoverColor = TB_MENU_DEFAULT_DARKEST_BLUE
					selectedButton = eventButton
					EventsInternal.ShowStaticEventInfo(eventInfoHolder, b)
					end)
				if (i == 1) then
					eventButton.btnUp()
				end
			end
			for _, e in ipairs(listElements2) do
				e:hide()
			end
			local scrollBar = TBMenu:spawnScrollBar(listingHolder2, #listElements2, 50)
			listingHolder2.scrollBar = scrollBar
			scrollBar:makeScrollBar(listingHolder2, listElements2, toReload2)

			for i, event in ipairs(eventInfos) do
				if (i == id) then
					for _, b in ipairs(event.buttonParts) do
						b.imageColor = { 1, 1, 1, 1 }
					end
				else
					for _, b in ipairs(event.buttonParts) do
						b.imageColor = { 0.65, 0.65, 0.65, 1 }
					end
				end
			end
		end
		for i = 1, 5 do
			local imageDisplayHolder = listingHolder:addChild({
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, imageDisplayHolder)
			local imageDisplay = imageDisplayHolder:addChild({
				pos = { 10, 0 },
				size = { imageDisplayHolder.size.w - 12, imageDisplayHolder.size.h },
				bgImage = v.image,
				imageAtlas = true,
				atlas = {
					x = 0, y = (i - 1) * 180, w = 1600, h = 180
				},
				interactive = true,
				imageColor = { 0.65, 0.65, 0.65, 1 },
				imageHoverColor = UICOLORWHITE,
				clickThrough = true,
				hoverThrough = true,
				hoverSound = 31
			})
			imageDisplay:addMouseUpHandler(showTypeEvents)
			table.insert(v.buttonParts, imageDisplay)
			if (i == 1) then
				imageDisplay:addChild({ size = { imageDisplay.size.w, 3 }, bgColor = eventsHolder.bgColor })
				TBMenu:addOuterRounding(imageDisplay:addChild({ pos = { 0, 3 } }), eventsHolder.bgColor, { 4, 4, 0, 0 })
			elseif (i == 5) then
				imageDisplay:addChild({ pos = { 0, -3 }, size = { imageDisplay.size.w, 3 }, bgColor = eventsHolder.bgColor })
				TBMenu:addOuterRounding(imageDisplay:addChild({ pos = { 0, -imageDisplay.size.h - 3 }}), eventsHolder.bgColor, { 0, 0, 4, 4 })
			end
		end
		if (Events.LastEventSection == id) then
			showTypeEvents()
		end
	end
	for _, v in ipairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar
	scrollBar:makeScrollBar(listingHolder, listElements, toReload, Events.HomeListShift)

	listingView:addCustomDisplay(function()
			for _, v in pairs(eventInfos) do
				local hoverState, hoverClock, hoverSame = v.buttonParts[1].hoverState, v.buttonParts[1].hoverClock, true
				for i = 2, #v.buttonParts do
					if (hoverState ~= v.buttonParts[i].hoverState and v.buttonParts[i]:isDisplayed()) then
						hoverState = math.max(hoverState, v.buttonParts[i].hoverState)
						hoverClock = math.max(hoverClock, v.buttonParts[i].hoverClock)
						hoverSame = false
					end
				end
				if (not hoverSame) then
					for _, b in ipairs(v.buttonParts) do
						if (b:isDisplayed()) then
							b.hoverState = hoverState
							b.hoverClock = hoverClock
						end
					end
				end
			end
		end)

	Events.SetConfig("challenges", EventsInternal.StaticEventVersion, true)
end

function Events:showEventDescription(viewElement, event)
	local elementHeight = 41
	local toReload, topBar, botBar, _, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 60, 60, 20, event.accentColor)

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
			infoTitle:addAdaptedText(info.title, { font = FONTS.BIG, intensity = 0.5, shadow = 2 })
			table.insert(listElements, infoTitle)
		end
		if (info.desc) then
			local textString = textAdapt(info.desc, 4, 0.9, listingHolder.size.w - 80)
			local rows = math.ceil(#textString / 2)
			for i = 1, rows do
				local infoRow = UIElement:new({
					parent = listingHolder,
					pos = { 50, #listElements * elementHeight },
					size = { listingHolder.size.w - 80, elementHeight },
					shadowOffset = 1
				})
				infoRow:addCustomDisplay(true, function()
						infoRow:uiText(textString[i * 2 - 1], nil, nil, 4, CENTER, 0.85, nil, 1)
						if (textString[i * 2]) then
							infoRow:uiText(textString[i * 2], nil, nil, 4, CENTERBOT, 0.85, nil, 1)
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
		for _, v in pairs(listElements) do
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
	prize = prize or { id = 0, itemname = "Unknown Item" }
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
	itemName:addAdaptedText(prize.itemname, { align = LEFTMID, shadow = 1 })
	return rewardView
end

---Displays event prizes in a specified UIElement viewport
---@param viewElement UIElement
---@param event NewsEventItemData
---@return UIElement
---@return UIElement
function Events:showEventPrizes(viewElement, event)
	local elementHeight = 41
	local toReload, topBar, botBar, _, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 60, 60, 20, event.accentColor)

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
		infoTitle:addAdaptedText("Prizes", { font = FONTS.BIG, intensity = 0.5, shadow = 2 })
		table.insert(listElements, infoTitle)
	--end

	for i, prize in ipairs(event.prizes) do
		if (prize.info) then
			local infoRow = UIElement:new({
				parent = listingHolder,
				pos = { 10, #listElements * elementHeight },
				size = { listingHolder.size.w - 20, elementHeight }
			})
			infoRow:addAdaptedText(prize.info, { shadow = 1 })
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
		for _, v in pairs(listElements) do
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

function Events.ShowBattlepassInfo()
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
		uiShadowColor = event.accentColor,
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
		viewElement:addChild({
			shift = { 0, 60 },
			bgImage = { event.image ~= nil and event.image or ("../textures/menu/promo/events/" .. event.eventid .. ".tga"), "" },
			imageColor = { 1, 1, 1, 1 - (event.overlaytransparency or 0) },
			disableUnload = true
		})
	end

	local descriptionView = viewElement:addChild({
		size = { event.prizes and viewElement.size.w * 0.6 or viewElement.size.w, viewElement.size.h }
	}, true)
	local dtopBar, dbotBar = Events:showEventDescription(descriptionView, event)
	local ptopBar, pbotBar = dtopBar, dbotBar
	if (event.prizes) then
		local prizesView = viewElement:addChild({
			pos = { descriptionView.size.w, 0 },
			size = { viewElement.size.w - descriptionView.size.w, viewElement.size.h }
		}, true)
		ptopBar, pbotBar = Events:showEventPrizes(prizesView, event)
	end

	local eventName = dtopBar:addChild({
		pos = { 10, 5 },
		size = { viewElement.size.w - (dtopBar.size.h - 30), dtopBar.size.h - 10 }
	})
	if (event.prizes) then
		table.insert(ptopBar.child, eventName)
	end
	eventName:addAdaptedText(event.name, {
		font = FONTS.BIG, maxscale = 0.85, intensity = 1
	})

	local eventForumLinkHolderBG = dbotBar:addChild({
		pos = { 5, 0 },
		size = { viewElement.size.w - 10, dbotBar.size.h },
		bgColor = event.accentColor,
		uiColor = event.accentColor
	})
	local eventForumLinkHolder = eventForumLinkHolderBG:addChild({ shift = { 100, 0 } })
	local buttonHColor, buttonPColor = nil, nil
	if (event.buttonHoverColor and event.buttonPressedColor) then
		buttonHColor = event.buttonHoverColor
		buttonPColor = event.buttonPressedColor
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

	local closeButton = TBMenu:spawnCloseButton(ptopBar, {
		x = -(ptopBar.size.h - 10), y = 10, w = ptopBar.size.h - 20, h = ptopBar.size.h - 20
	}, function() overlay:kill() end, { default = viewElement.uiColor, hover = buttonHColor, pressed = buttonPColor, ui = viewElement.bgColor })
	closeButton:setRounded(viewElement.rounded)
	table.insert(dtopBar.child, closeButton)

	if (event.eventid) then
		if (not EventsOnline:checkFiles(event.eventid, event.requireMod)) then
			download_server_file('tutorial_' .. event.eventid, 0)
		end
	end
end

---Displays Blind Fight league promotion interface
---@param overlay UIElement
---@param prizes EventRewardBase[]
---@param onContinue ?function
---@param leagueName ?string
function Events:showBlindFightPromotion(overlay, prizes, onContinue, leagueName)
	overlay:kill(true)
	local spawnClock = UIElement.clock
	local spawnArea = { x = overlay.size.w / 2.5, y = overlay.size.h / 3 }
	local blobSegments = is_mobile() and 0 or 24
	local blobSegmetsLarge = is_mobile() and 0 or 64
	local prizeList = table.clone(prizes) -- Make sure we operate on a copy so that the original list can be destroyed

	---@param blob UIElement
	---@param delay number
	---@param targetSize number
	---@param targetPulseSize number
	local drawBlob = function(blob, delay, targetSize, targetPulseSize)
		if (spawnClock + delay > UIElement.clock) then return end
		set_color(blob.bgColor[1], blob.bgColor[2], blob.bgColor[3], blob.bgColor[4])
		local time = (UIElement.clock - spawnClock - delay) * 3
		if (time < 0.65) then
			blob.size.h = UITween.SineEaseOut(time / 0.65, targetSize * 1.15)
		elseif (time <= 0.9) then
			blob.size.h = UITween.SineTween(targetSize * 1.15, targetSize, (time - 0.65) * 4)
		else
			time = ((time - 0.9) / 10) % 2
			if (time < 1) then
				blob.size.h = UITween.LinearTween(targetSize, targetPulseSize, time)
			else
				blob.size.h = UITween.LinearTween(targetPulseSize, targetSize * 1, time - 1)
			end
		end
		draw_disk(blob.pos.x, blob.pos.y, 0, blob.size.h, blob.size.h > 50 and blobSegmetsLarge or blobSegments, 1, 0, 360, 0)
	end

	---@param blob UIElement
	local function drawBlobSimple(blob, speed)
		set_color(blob.bgColor[1], blob.bgColor[2], blob.bgColor[3], blob.bgColor[4])
		draw_disk(blob.pos.x, blob.pos.y, 0, blob.size.h, blobSegments, 1, 0, 360, 0)
		blob.pos.y = blob.pos.y - UITween.LinearEaseIn(UIElement.deltaClock, speed)
		if (blob.pos.y < -blob.size.h) then
			blob.pos.y = overlay.size.h + blob.size.h
		end
	end

	for i = 1, 40 do
		local delay = math.random() * 2
		local targetSize = math.random(8, 24)
		local side = i % 4 + 1
		local spawnPos = { (overlay.size.w - spawnArea.x) / 2 + math.random(0, spawnArea.x / 2), (overlay.size.h - spawnArea.y) / 2 + math.random(0, spawnArea.x / 2) }
		if (side % 2 == 0) then
			spawnPos[1] = overlay.size.w / 2 + math.random(0, spawnArea.x / 2)
		end
		if (side > 2) then
			spawnPos[2] = overlay.size.h / 2 + math.random(0, spawnArea.y / 2)
		end
		local blob = overlay:addChild({
			pos = spawnPos,
			size = { 0, 0 },
			bgColor = { 0.15 + math.random() * 0.06, 0.06 + math.random() * 0.037, 0.16 + math.random() * 0.059, 1 }
		})
		blob:addCustomDisplay(true, function()
				drawBlob(blob, delay, targetSize, targetSize * 1.2)
			end)
	end
	for _ = 1, 50 do
		local scale = math.random(6, 12)
		local targetAlpha = math.random() * 0.5 + 0.5
		local speed = 10 + math.random(20)
		local blob = overlay:addChild({
			pos = { math.random(overlay.size.w), math.random(overlay.size.h) },
			size = { 0, scale },
			bgColor = { 0.1523, 0.0625, 0.1641, 0 }
		})
		blob:addCustomDisplay(true, function()
				if (blob.bgColor[4] < 0.7) then
					blob.bgColor[4] = UITween.SineTween(blob.bgColor[4], targetAlpha, (UIElement.clock - spawnClock) * 0.25)
				end
				drawBlobSimple(blob, speed)
			end)
	end
	local mainBlobHolder = overlay:addChild({
		pos = { (overlay.size.w - spawnArea.x) / 2, (overlay.size.h - spawnArea.y) / 2 },
		size = { spawnArea.x, spawnArea.y }
	})
	local mainBlob = mainBlobHolder:addChild({
		pos = { mainBlobHolder.size.w / 2, mainBlobHolder.size.h / 2 },
		size = { 0, 0 },
		bgColor = { 0.1523, 0.0625, 0.1641, 1 }
	})
	local textSpawned, prizesSpawned, buttonSpawned = false, false, false
	local iconScale = math.min(96, (mainBlobHolder.size.h - 40) / 3)
	local textDelay = 0.1
	local prizesDelay = 0.6
	local buttonDelay = 1.8
	local drawText
	if (leagueName == nil) then
		drawText = function()
			if (UIElement.clock - spawnClock - textDelay > 0 and not textSpawned) then
				textSpawned = true
				local textElement = mainBlobHolder:addChild({
					pos = { 25, 20 },
					size = { mainBlobHolder.size.w - 50, (mainBlobHolder.size.h - 60) / 3 },
					uiColor = { 1, 1, 1, 0 },
					uiShadowColor = { 0.1523, 0.0625, 0.1641, 0 },
					shadowOffset = 2
				})
				local textScale = 0.5
				textElement:addCustomDisplay(true, function()
					local textSpawnClock = UIElement.clock - spawnClock - textDelay
					if (textElement.uiColor[4] < 1) then
						textElement.uiColor[4] = UITween.SineTween(0, 1, textSpawnClock)
						textElement.uiShadowColor[4] = textElement.uiColor[4]
						textScale = UITween.SineTween(textScale, 1, textSpawnClock)
						textElement:uiText(TB_MENU_LOCALIZED.BLINDFIGHTLEAGUEVICTORY, nil, nil, FONTS.BIG, CENTERBOT, textScale, nil, 4)
					else
						textElement:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTLEAGUEVICTORY, { font = FONTS.BIG, align = CENTERBOT, minscale = textScale, maxscale = textScale, shadow = 4 }, true)
					end
				end)
			end
		end
	else
		local promotedLeague = utf8.gsub(TB_MENU_LOCALIZED.BLINDFIGHTLEAGUEPROMOTION, "{x}", leagueName)
		drawText = function()
			if (UIElement.clock - spawnClock - textDelay > 0 and not textSpawned) then
				textSpawned = true
				local textElement = mainBlobHolder:addChild({
					pos = { 25, 20 },
					size = { mainBlobHolder.size.w - 50, (mainBlobHolder.size.h - 60) / 3 }
				})
				local textElementVictory = textElement:addChild({
					size = { textElement.size.w, textElement.size.h * 0.65 },
					uiColor = { 1, 1, 1, 0 },
					uiShadowColor = { 0.1523, 0.0625, 0.1641, 0 },
					shadowOffset = 2
				})
				local textScale = 0.5
				textElementVictory:addCustomDisplay(true, function()
					local textSpawnClock = UIElement.clock - spawnClock - textDelay
					if (textElementVictory.uiColor[4] < 1) then
						textElementVictory.uiColor[4] = UITween.SineTween(0, 1, textSpawnClock)
						textElementVictory.uiShadowColor[4] = textElementVictory.uiColor[4]
						textScale = UITween.SineTween(textScale, 1, textSpawnClock)
						textElementVictory:uiText(TB_MENU_LOCALIZED.BLINDFIGHTLEAGUEVICTORY, nil, nil, FONTS.BIG, CENTERBOT, textScale, nil, 4)
					else
						textElementVictory:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTLEAGUEVICTORY, { font = FONTS.BIG, align = CENTERBOT, minscale = textScale, maxscale = textScale, shadow = 4 }, true)
					end
				end)

				local textElementPromotion = textElement:addChild({
					pos = { 0, textElementVictory.size.h },
					size = { textElement.size.w, textElement.size.h - textElementVictory.size.h },
					uiColor = { 1, 1, 1, 0 },
					uiShadowColor = { 0.1523, 0.0625, 0.1641, 0 },
					shadowOffset = 1
				})
				textElementPromotion:addCustomDisplay(true, function()
					local textSpawnClock = UIElement.clock - spawnClock - textDelay - 0.15
					if (textElementPromotion.uiColor[4] < 1) then
						textElementPromotion.uiColor[4] = UITween.SineTween(0, 1, textSpawnClock)
						textElementPromotion.uiShadowColor[4] = textElementPromotion.uiColor[4]
						textScale = UITween.SineTween(textScale, 1, textSpawnClock)
						textElementPromotion:uiText(promotedLeague, nil, nil, FONTS.MEDIUM, CENTERBOT, textScale, nil, 2)
					else
						textElementPromotion:addAdaptedText(promotedLeague, { font = FONTS.MEDIUM, align = CENTERBOT, minscale = textScale, maxscale = textScale, shadow = 2 }, true)
					end
				end)
			end
		end
	end
	
	mainBlob:addCustomDisplay(true, function(init)
			if (init) then return end
			if (textSpawned and prizesSpawned and buttonSpawned) then
				mainBlob:addCustomDisplay(true, function()
					drawBlob(mainBlob, 0, spawnArea.y / 2, spawnArea.y / 1.9)
				end)
				return
			end

			drawBlob(mainBlob, 0, spawnArea.y / 2, spawnArea.y / 1.9)

			drawText()
			if (UIElement.clock - spawnClock - prizesDelay > 0 and not prizesSpawned) then
				prizesSpawned = true
				local prizeElements = {}
				local numPrizes = #prizeList
				local prizeStartPos = (mainBlobHolder.size.w - numPrizes * iconScale - (numPrizes - 1) * 10) / 2
				for i, v in pairs(prizeList) do
					local prizeElement = mainBlobHolder:addChild({
						pos = { prizeStartPos + (i - 1) * (iconScale + 10), (mainBlobHolder.size.h - iconScale) / 2 },
						size = { iconScale, iconScale }
					})
					table.insert(prizeElements, prizeElement)
					BattlePass:showPrizeItem(prizeElement, {
						tc = v.tc,
						st = v.st,
						bpxp = v.bpxp,
						itemid = v.itemid,
						qi = v.qi,
						static = true,
						bgOutlineColor = { 0.424, 0.263, 0.38, 1 },
						bgColor = { 0.204, 0.084, 0.202, 1 },
						textBackdropColor = { 0.204, 0.084, 0.202, 0.67 },
						textColor = { 1, 1, 1, 0 },
						withoutPopup = true
					})
				end

				---@param element UIElement
				---@param a number
				local function setTransparency(element, a)
					if (element.uiColor) then
						element.uiColor[4] = a
					end
					if (element.uiShadowColor) then
						element.uiShadowColor[4] = a
					end
					if (element.bgColor and element.bgColor[4] > 0) then
						if (element.__initialAlpha == nil) then
							element.__initialAlpha = element.bgColor[4]
						end
						element.bgColor[4] = math.min(a, element.__initialAlpha)
					end
					if (element.imageColor) then
						element.imageColor[4] = a
					end
					for _, v in pairs(element.child) do
						setTransparency(v, a)
					end
				end
				local observer = mainBlobHolder:addChild({})
				observer:addCustomDisplay(true, function()
						local prizeSpawnClock = (UIElement.clock - spawnClock - prizesDelay) * 2
						local transparency = UITween.SineTween(0.01, 1, prizeSpawnClock)
						for _, v in pairs(prizeElements) do
							setTransparency(v, transparency)
						end
						if (prizeSpawnClock >= 1) then
							observer:kill()
						end
					end)
			end
			if (UIElement.clock - spawnClock - buttonDelay > 0 and not buttonSpawned) then
				buttonSpawned = true
				local buttonWidth = spawnArea.y * 1.25
				local buttonHeight = math.min(55, (mainBlobHolder.size.h - 60) / 3)
				local continueButton = mainBlobHolder:addChild({
					pos = { (mainBlobHolder.size.w - buttonWidth) / 2, -buttonHeight - 20 },
					size = { buttonWidth, buttonHeight },
					bgColor = { 0.224, 0.118, 0.224, 0 },
					hoverColor = { 0.424, 0.263, 0.38, 1 },
					pressedColor = { 0.148, 0.094, 0.153, 1 },
					interactive = true,
					shapeType = ROUNDED,
					rounded = 5
				})
				local continueText = continueButton:addChild({
					shift = { 25, 8 },
					uiColor = { 1, 1, 1, 0 }
				})
				continueText:addAdaptedText(TB_MENU_LOCALIZED.BUTTONCONTINUE)
				continueButton:addCustomDisplay(function()
						local transparency = UITween.SineTween(0, 1, UIElement.clock - spawnClock - buttonDelay)
						continueButton.bgColor[4] = transparency
						continueText.uiColor[4] = transparency
					end, true)
				if (onContinue) then
					continueButton:addMouseUpHandler(onContinue)
				else
					continueButton:addMouseUpHandler(function() overlay:kill() request_app_review() end)
				end
			end
		end)
	local secBlob1 = mainBlobHolder:addChild({
		pos = { mainBlobHolder.size.w / 2 - spawnArea.y / 2.5, mainBlobHolder.size.h / 2 + spawnArea.y / 6 },
		size = { 0, 0 },
		bgColor = { 0.1523, 0.0625, 0.1641, 1 }
	})
	secBlob1:addCustomDisplay(true, function()
			drawBlob(secBlob1, 0.125, spawnArea.y / 2.4, spawnArea.y / 2.5)
		end)
	local secBlob2 = mainBlobHolder:addChild({
		pos = { mainBlobHolder.size.w / 2 + spawnArea.y / 1.9, mainBlobHolder.size.h / 2 - spawnArea.y / 6 },
		size = { 0, 0 },
		bgColor = { 0.1523, 0.0625, 0.1641, 1 }
	})
	secBlob2:addCustomDisplay(true, function()
			drawBlob(secBlob2, 0.25, spawnArea.y / 3.4, spawnArea.y / 3.6)
		end)
	local secBlob3 = mainBlobHolder:addChild({
		pos = { mainBlobHolder.size.w / 2 + spawnArea.y / 2.1, mainBlobHolder.size.h / 2 + spawnArea.y / 4 },
		size = { 0, 0 },
		bgColor = { 0.1523, 0.0625, 0.1641, 1 }
	})
	secBlob3:addCustomDisplay(true, function()
			drawBlob(secBlob3, 0.075, spawnArea.y / 4.1, spawnArea.y / 3.9)
		end)

	spawnClock = os.clock_real()

	---Refresh player balance and battle pass experience
	update_tc_balance()
	BattlePass:getUserData()
end

---Parses Blind Fight rewards network response string
---@param ln string
---@return EventRewardBase[]
function Events.ParseBlindFightRewards(ln)
	local _, segments = ln:gsub("\t", "")
	local data = { ln:match(("([^\t]*)\t?"):rep(segments)) }
	local rewards = {}
	local tc = tonumber(data[2]) or 0
	local st = tonumber(data[3]) or 0
	local bpxp = tonumber(data[4]) or 0
	local qi = tonumber(data[6]) or 0
	if (tc > 0) then table.insert(rewards, { tc = tc }) end
	if (st > 0) then table.insert(rewards, { st = st }) end
	if (bpxp > 0) then table.insert(rewards, { bpxp = bpxp }) end
	if (qi > 0) then table.insert(rewards, { qi = qi }) end
	for _, v in pairs(string.explode(data[5], ":")) do
		local itemid = tonumber(v) or 0
		if (itemid > 0) then
			table.insert(rewards, { itemid = itemid })
		end
	end
	return rewards
end

---Spawns a prestige icon in the specified UIElement viewport
---@param viewElement UIElement
---@param prestige integer
---@param rect ?Rect
---@param withPopup ?boolean
---@return UIElement?
---@return UIElement?
function Events:displayBlindFightPrestige(viewElement, prestige, rect, withPopup)
	if (prestige < 1 or prestige > 20) then
		return nil
	end

	if (rect == nil) then
		rect = {
			x = 0, y = 0,
			w = math.min(viewElement.size.h, viewElement.size.w), h = math.min(viewElement.size.h, viewElement.size.w)
		}
	else
		if (rect.x == nil) then
			rect.x = 0
		end
		if (rect.y == nil) then
			rect.y = 0
		end
		if (rect.w == nil) then
			rect.w = math.min(viewElement.size.h, viewElement.size.w)
		end
		if (rect.h == nil) then
			rect.h = math.min(viewElement.size.h, viewElement.size.w)
		end
	end

	if (withPopup == nil) then
		withPopup = true
	end

	local prestigeBackdrop = viewElement:addChild({
		pos = { rect.x, rect.y },
		size = { rect.w, rect.h },
		interactive = true,
		bgImage = "../textures/menu/blindfight/prestige-backdrop.tga",
		imageAtlas = true,
		atlas = {
			x = math.floor((prestige - 1) / 5) * 128, y = 0,
			w = 128, h = 128
		},
		imageColor = { 0.1523, 0.0625, 0.1641, 0.75 },
		imageHoverColor = { 0.1523, 0.0625, 0.1641, 1 },
		imagePressedColor = { 0.1523, 0.0625, 0.1641, 1 }
	})
	prestigeBackdrop:addChild({
		bgImage = "../textures/menu/blindfight/prestige.tga",
		imageAtlas = true,
		atlas = {
			x = (prestige % 5) * 128, y = 0,
			w = 128, h = 128
		}
	})

	local popup
	if (prestigeBackdrop ~= nil and withPopup) then
		popup = TBMenu:displayPopup(prestigeBackdrop, TB_MENU_LOCALIZED.BLINDFIGHTPRESTIGE .. " " .. prestige)
		if (popup ~= nil) then
			popup:moveTo(-(prestigeBackdrop.size.w + popup.size.w) / 2, prestigeBackdrop.size.h + 5)
		end
	end
	return prestigeBackdrop, popup
end

---Displays Blind Fight prestige confirmation window
function EventsInternal.ShowBlindFightPrestigeConfirmation()
	local overlay = TBMenu:spawnWindowOverlay({ 0.204, 0.084, 0.202, 0.95 })

	local confirmationWindowDimensions = {
		math.min(WIN_W * 0.75, 1300), math.min(WIN_H * 0.5, 400)
	}
	local confirmationWindow = overlay:addChild({
		pos = { (WIN_W - confirmationWindowDimensions[1]) / 2, (WIN_H - confirmationWindowDimensions[2]) / 2 },
		size = confirmationWindowDimensions,
		uiColor = { 1, 1, 1, 1 },
		uiShadowColor = { 0, 0, 0, 1 },
		shapeType = ROUNDED,
		rounded = 5
	})
	local closeButton = overlay:addChild({
		pos = { -math.max(80, SAFE_X), math.max(30, SAFE_Y) },
		size = { 50, 50 },
		interactive = true,
		bgImage = "../textures/menu/general/buttons/crosswhite.tga",
		imageColor = { 1, 1, 1, 1 },
		imageHoverColor = { 0.863, 0.824, 0.624, 1 },
		imagePressedColor = { 0.424, 0.263, 0.38, 1 }
	})
	closeButton:addMouseUpHandler(function() overlay:kill() end)
	local confirmationTitle = confirmationWindow:addChild({
		pos = { 0, 0 },
		size = { confirmationWindow.size.w, 50 }
	})
	confirmationTitle:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTPRESTIGESTATSELECT, { font = FONTS.BIG, intensity = 0.5 })

	local selectedStat = -1
	local selectedButton, selectedStatDisplay = nil, nil
	---@param stat integer
	---@param button UIElement
	---@param statDisplay UIElement
	local setActiveButton = function(stat, button, statDisplay)
		if (selectedButton ~= nil) then
			selectedButton.bgColor = { 0.269, 0.081, 0.303, 1 }
			selectedButton.uiColor = { 1, 1, 1, 1 }
		end
		if (selectedStatDisplay ~= nil) then
			selectedStatDisplay.uiColor = { 1, 1, 1, 1 }
			local statText = EventsInternal.BlindFight.userRPG.endurance
			if (selectedStat == 0) then
				statText = EventsInternal.BlindFight.userRPG.strength
			elseif (selectedStat == 1) then
				statText = EventsInternal.BlindFight.userRPG.speed
			end
			selectedStatDisplay:addAdaptedText(statText .. "%")
		end
		selectedStat = stat
		selectedButton = button
		selectedStatDisplay = statDisplay
		selectedButton.bgColor = { 0.749, 0.636, 0.764, 1 }
		selectedButton.uiColor = { 0, 0, 0, 1 }
		selectedStatDisplay.uiColor = { 0.184, 0.09, 0.192, 1 }

		local statText = EventsInternal.BlindFight.userRPG.endurance * EventsInternal.BlindFight.rpgDecayRate
		if (stat == 0) then
			statText = EventsInternal.BlindFight.userRPG.strength * EventsInternal.BlindFight.rpgDecayRate
		elseif (stat == 1) then
			statText = EventsInternal.BlindFight.userRPG.speed * EventsInternal.BlindFight.rpgDecayRate
		end
		selectedStatDisplay:addAdaptedText("< " .. statText .. "% >")
	end

	local buttonWidth = (confirmationWindow.size.w - 60) / 3
	local strengthButton = confirmationWindow:addChild({
		pos = { 10, confirmationTitle.shift.y + confirmationTitle.size.h + 10 },
		size = { buttonWidth, confirmationWindow.size.h - confirmationTitle.shift.y - confirmationTitle.size.h - 100 },
		interactive = true,
		bgColor = { 0.269, 0.081, 0.303, 1 },
		hoverColor = { 0.424, 0.263, 0.38, 1 },
		pressedColor = { 0.184, 0.09, 0.192, 1 }
	}, true)
	local strengthButtonTitle = strengthButton:addChild({
		pos = { 10, 5 },
		size = { strengthButton.size.w - 20, (strengthButton.size.h - 10) / 3 }
	})
	strengthButtonTitle:addAdaptedText(TB_MENU_LOCALIZED.RPGSTRENGTH, { font = FONTS.BIG, shadow = 2, maxscale = 0.8 })
	local strengthButtonCurrent = strengthButton:addChild({
		pos = { strengthButtonTitle.shift.x, strengthButtonTitle.shift.y + strengthButtonTitle.size.h },
		size = { strengthButtonTitle.size.w, strengthButtonTitle.size.h / 2 },
		uiColor = { 1, 1, 1, 1 }
	})
	strengthButtonCurrent:addAdaptedText(EventsInternal.BlindFight.userRPG.strength .. "%")
	local strengthButtonInfo = strengthButton:addChild({
		pos = { strengthButtonTitle.shift.x, strengthButtonCurrent.shift.y + strengthButtonCurrent.size.h },
		size = { strengthButtonTitle.size.w, strengthButton.size.h - strengthButtonCurrent.size.h - strengthButtonCurrent.shift.y - strengthButtonTitle.shift.y }
	})
	strengthButtonInfo:addAdaptedText(TB_MENU_LOCALIZED.RPGSTRENGTHINFO, { font = FONTS.LMEDIUM, maxscale = 0.85, shadow = 1 })
	strengthButton:addMouseUpHandler(function()
			setActiveButton(0, strengthButton, strengthButtonCurrent)
		end)

	local speedButton = confirmationWindow:addChild({
		pos = { strengthButton.shift.x + strengthButton.size.w + 20, strengthButton.shift.y },
		size = { buttonWidth, strengthButton.size.h },
		interactive = true,
		bgColor = { 0.269, 0.081, 0.303, 1 },
		hoverColor = { 0.424, 0.263, 0.38, 1 },
		pressedColor = { 0.184, 0.09, 0.192, 1 }
	}, true)
	local speedButtonTitle = speedButton:addChild({
		pos = { strengthButtonTitle.shift.x, strengthButtonTitle.shift.y },
		size = { strengthButtonTitle.size.w, strengthButtonTitle.size.h }
	})
	speedButtonTitle:addAdaptedText(TB_MENU_LOCALIZED.RPGSPEED, { font = FONTS.BIG, shadow = 2, maxscale = 0.8 })
	local speedButtonCurrent = speedButton:addChild({
		pos = { strengthButtonCurrent.shift.x, strengthButtonCurrent.shift.y },
		size = { strengthButtonCurrent.size.w, strengthButtonCurrent.size.h },
		uiColor = { 1, 1, 1, 1 }
	})
	speedButtonCurrent:addAdaptedText(EventsInternal.BlindFight.userRPG.speed .. "%")
	local speedButtonInfo = speedButton:addChild({
		pos = { strengthButtonInfo.shift.x, strengthButtonInfo.shift.y },
		size = { strengthButtonInfo.size.w, strengthButtonInfo.size.h }
	})
	speedButtonInfo:addAdaptedText(TB_MENU_LOCALIZED.RPGSPEEDINFO, { font = FONTS.LMEDIUM, maxscale = 0.85, shadow = 1 })
	speedButton:addMouseUpHandler(function()
			setActiveButton(1, speedButton, speedButtonCurrent)
		end)

	local enduranceButton = confirmationWindow:addChild({
		pos = { speedButton.shift.x + speedButton.size.w + 20, strengthButton.shift.y },
		size = { buttonWidth, strengthButton.size.h },
		interactive = true,
		bgColor = { 0.269, 0.081, 0.303, 1 },
		hoverColor = { 0.424, 0.263, 0.38, 1 },
		pressedColor = { 0.184, 0.09, 0.192, 1 }
	}, true)
	local enduranceButtonTitle = enduranceButton:addChild({
		pos = { strengthButtonTitle.shift.x, strengthButtonTitle.shift.y },
		size = { strengthButtonTitle.size.w, strengthButtonTitle.size.h }
	})
	enduranceButtonTitle:addAdaptedText(TB_MENU_LOCALIZED.RPGENDURANCE, { font = FONTS.BIG, shadow = 2, maxscale = 0.8 })
	local enduranceButtonCurrent = enduranceButton:addChild({
		pos = { strengthButtonCurrent.shift.x, strengthButtonCurrent.shift.y },
		size = { strengthButtonCurrent.size.w, strengthButtonCurrent.size.h },
		uiColor = { 1, 1, 1, 1 }
	})
	enduranceButtonCurrent:addAdaptedText(EventsInternal.BlindFight.userRPG.endurance .. "%")
	local enduranceButtonInfo = enduranceButton:addChild({
		pos = { strengthButtonInfo.shift.x, strengthButtonInfo.shift.y },
		size = { strengthButtonInfo.size.w, strengthButtonInfo.size.h }
	})
	enduranceButtonInfo:addAdaptedText(TB_MENU_LOCALIZED.RPGENDURANCEINFO, { font = FONTS.LMEDIUM, maxscale = 0.85, shadow = 1 })
	enduranceButton:addMouseUpHandler(function()
			setActiveButton(2, enduranceButton, enduranceButtonCurrent)
		end)

	local prestigeButtonWidth = math.min(400, confirmationWindow.size.w - 20)
	local prestigeButton = confirmationWindow:addChild({
		pos = { (confirmationWindow.size.w - prestigeButtonWidth) / 2, -70 },
		size = { prestigeButtonWidth, 70 },
		interactive = true,
		bgColor = { 0.269, 0.081, 0.303, 1 },
		hoverColor = { 0.424, 0.263, 0.38, 1 },
		pressedColor = { 0.184, 0.09, 0.192, 1 },
		inactiveColor = { 0.749, 0.636, 0.764, 1 }
	}, true)
	prestigeButton:addCustomDisplay(function()
			if (selectedStat > -1) then
				prestigeButton:activate()
				prestigeButton:addCustomDisplay(false, nil)
			end
		end)
	prestigeButton:addChild({ shift = { 20, 7 }}):addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTPRESTIGE)
	prestigeButton:addMouseUpHandler(function()
			---@diagnostic disable-next-line: undefined-global
			Request:queue(function() submit_blindfight_prestige(selectedStat) end, "blindfight_prestige", function(_, response)
				overlay:kill()
				if (response:find("^PRESTIGE_REWARDS")) then
					local rewards = Events.ParseBlindFightRewards(response)
					local promoOverlay = TBMenu:spawnWindowOverlay({ 1, 1, 1, 0.9 })
					Events:showBlindFightPromotion(promoOverlay, rewards, nil, TB_MENU_LOCALIZED.BLINDFIGHTPRESTIGE .. " " .. (EventsInternal.BlindFight.userStats.prestige + 1))
					Events:refreshBlindFight(nil, nil, function()
							if (TB_MENU_MAIN_ISOPEN == 0 or TB_MENU_SPECIAL_SCREEN_ISOPEN ~= 12) then
								return
							end
							if (promoOverlay == nil or promoOverlay.destroyed) then
								Events:showBlindFightMain(TBMenu.CurrentSection)
							else
								promoOverlay:addChild({}).killAction = function()
									if (TB_MENU_MAIN_ISOPEN == 1) then
										Events:showBlindFightMain(TBMenu.CurrentSection)
									end
								end
							end
						end)
					return
				end
				local error = string.gsub(response, "^ERROR ", "")
				TBMenu:showStatusMessage(error)
			end, function(_, response)
				overlay:kill()
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ACCOUNTINFOERROR .. "\n" .. response)
			end)
			confirmationWindow:kill(true)
			TBMenu:displayLoadingMark(confirmationWindow)
		end)
	prestigeButton:deactivate()
end

---Animates in Blind Fight prestige screen with information and rewards display
---@param _ any
---@param x integer
---@param y integer
function EventsInternal.ShowBlindFightPrestige(_, x, y)
	local overlay = TBMenu:spawnWindowOverlay({ 0.204, 0.084, 0.202, 0.95 })

	local displayHolderDimensions = {
		math.min(WIN_W * 0.6, 1200), math.min(WIN_H * 0.5, 600)
	}
	local prizeDisplayHolder = overlay:addChild({
		pos = { (WIN_W - displayHolderDimensions[1]) / 2, (WIN_H - displayHolderDimensions[2]) / 2 },
		size = displayHolderDimensions,
		uiColor = { 1, 1, 1, 1 }
	})
	local closeButton = overlay:addChild({
		pos = { -math.max(80, SAFE_X), math.max(30, SAFE_Y) },
		size = { 50, 50 },
		interactive = true,
		bgImage = "../textures/menu/general/buttons/crosswhite.tga",
		imageColor = { 1, 1, 1, 1 },
		imageHoverColor = { 0.863, 0.824, 0.624, 1 },
		imagePressedColor = { 0.424, 0.263, 0.38, 1 }
	})
	closeButton:addMouseUpHandler(function() overlay:kill() end)
	local prestigeTitle = prizeDisplayHolder:addChild({
		pos = { 80, 0 },
		size = { prizeDisplayHolder.size.w - 160, prizeDisplayHolder.size.h / 9 },
		uiColor = { 1, 1, 1, 1 }
	})
	prestigeTitle:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTPRESTIGE, { font = FONTS.BIG })
	local prestigeDescription = prizeDisplayHolder:addChild({
		pos = { prestigeTitle.shift.x, prestigeTitle.shift.y + prestigeTitle.size.h },
		size = { prestigeTitle.size.w, prizeDisplayHolder.size.h / 5 },
		uiColor = { 1, 1, 1, 1 }
	})
	prestigeDescription:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTPRESTIGEINFO, { font = FONTS.LMEDIUM })
	local prestigeIconsHolder = prizeDisplayHolder:addChild({
		pos = { prestigeTitle.shift.x, prestigeDescription.shift.y + prestigeDescription.size.h },
		size = { prestigeTitle.size.w, prizeDisplayHolder.size.h / 8 }
	})
	if (EventsInternal.BlindFight.userStats.prestige > 0) then
		local prestigeUpgradeArrow = prestigeIconsHolder:addChild({
			pos = { prestigeIconsHolder.size.w / 2 - prestigeIconsHolder.size.h, 0 },
			size = { prestigeIconsHolder.size.h * 2, prestigeIconsHolder.size.h },
			bgImage = "../textures/menu/blindfight/prestigearrow.tga"
		})
		local currentPrestige = prestigeIconsHolder:addChild({
			pos = { prestigeUpgradeArrow.shift.x - prestigeUpgradeArrow.size.w, 0 },
			size = { prestigeUpgradeArrow.size.h, prestigeUpgradeArrow.size.h },
			bgColor = { 0.424, 0.263, 0.38, 1 },
			shapeType = ROUNDED,
			rounded = prestigeUpgradeArrow.size.h
		})
		Events:displayBlindFightPrestige(currentPrestige, EventsInternal.BlindFight.userStats.prestige, {
			x = 2, y = 2, w = currentPrestige.size.w - 4, h = currentPrestige.size.h - 4
		}, false)
		local nextPrestige = prestigeIconsHolder:addChild({
			pos = { prestigeUpgradeArrow.shift.x + prestigeUpgradeArrow.size.w * 1.5, 0 },
			size = { prestigeUpgradeArrow.size.h, prestigeUpgradeArrow.size.h },
			bgColor = { 0.424, 0.263, 0.38, 1 },
			shapeType = ROUNDED,
			rounded = prestigeUpgradeArrow.size.h
		})
		Events:displayBlindFightPrestige(nextPrestige, EventsInternal.BlindFight.userStats.prestige + 1, {
			x = 2, y = 2, w = nextPrestige.size.w - 4, h = nextPrestige.size.h - 4
		}, false)
	else
		Events:displayBlindFightPrestige(prestigeIconsHolder, EventsInternal.BlindFight.userStats.prestige + 1, { x = prestigeIconsHolder.size.w / 2 - prestigeIconsHolder.size.h / 4, w = prestigeIconsHolder.size.h }, false)
	end
	local prestigePrizesInfo = prizeDisplayHolder:addChild({
		pos = { prestigeTitle.shift.x, prestigeIconsHolder.shift.y + prestigeIconsHolder.size.h },
		size = { prestigeTitle.size.w, prizeDisplayHolder.size.h / 6 },
		uiColor = { 1, 1, 1, 1 }
	})
	prestigePrizesInfo:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTPRESTIGEREWARDS, { font = FONTS.LMEDIUM })

	local prestigePrizesHolder = prizeDisplayHolder:addChild({
		pos = { prestigeTitle.shift.x, prestigePrizesInfo.shift.y + prestigePrizesInfo.size.h },
		size = { prestigeTitle.size.w, prizeDisplayHolder.size.h / 4 }
	})
	local numPrizes = #EventsInternal.BlindFight.prestigeRewards
	local prizeWidth = math.min(prestigePrizesHolder.size.w / numPrizes, prestigePrizesHolder.size.h)
	local shiftX = (prestigePrizesHolder.size.w - prizeWidth * numPrizes) / 2
	for i, v in pairs(EventsInternal.BlindFight.prestigeRewards) do
		local prizeElementHolder = prestigePrizesHolder:addChild({
			pos = { shiftX + (i - 1) * prizeWidth, (prestigePrizesHolder.size.h - prizeWidth + 10) / 2 },
			size = { prizeWidth, prizeWidth - 10 }
		})
		BattlePass:showPrizeItem(prizeElementHolder, {
			itemid = v.itemid,
			tc = v.tc,
			st = v.st,
			bpxp = v.bpxp,
			qi = v.qi,
			static = true,
			bgColor = { 0.204, 0.084, 0.202, 1 },
			bgOutlineColor = { 0, 0, 0, 1 },
			textBackdropColor = { 0.204, 0.084, 0.202, 0.67 },
			textColor = { 1, 1, 1, 1 },
			withoutPopup = true
		})
	end
	local prestigeButtonWidth = math.max(400, numPrizes * prizeWidth - 10)
	local prestigeButton = prizeDisplayHolder:addChild({
		pos = { (prizeDisplayHolder.size.w - prestigeButtonWidth) / 2, -prizeDisplayHolder.size.h / 8 },
		size = { prestigeButtonWidth, prizeDisplayHolder.size.h / 8 },
		interactive = true,
		bgColor = { 0.269, 0.081, 0.303, 1 },
		hoverColor = { 0.204, 0.084, 0.202, 1 },
		pressedColor = { 0.184, 0.09, 0.192, 1 },
		uiColor = UICOLORWHITE,
		shapeType = ROUNDED,
		rounded = 4
	})
	prestigeButton:addAdaptedText(TB_MENU_LOCALIZED.BUTTONCONTINUE)
	prestigeButton:addMouseUpHandler(function()
		overlay:kill()
		EventsInternal.ShowBlindFightPrestigeConfirmation()
	end)
	prizeDisplayHolder:hide()

	---@param element UIElement
	---@param alpha number
	---@param setDefaults ?boolean
	local function setOpacityRecursive(element, alpha, setDefaults)
		if (setDefaults) then
			element.__defaultAlpha = {
				bgColor = element.bgColor[4],
				uiColor = element.uiColor[4],
				imageColor = element.imageColor and element.imageColor[4]
			}
		end
		element.bgColor[4] = math.min(alpha, element.__defaultAlpha.bgColor)
		element.uiColor[4] = math.min(alpha, element.__defaultAlpha.uiColor)
		if (element.imageColor) then
			element.imageColor[4] = math.min(alpha, element.__defaultAlpha.imageColor)
		end
		for _, v in pairs(element.child) do
			setOpacityRecursive(v, alpha, setDefaults)
		end
	end

	local overlayGrow = 10
	local numSlices = is_mobile() and 0 or 160
	local spawnClock = os.clock_real()
	local animateClock = 0
	local targetSize = math.sqrt(WIN_W * WIN_W + WIN_H * WIN_H)
	overlay:addCustomDisplay(true, function()
			set_color(overlay.bgColor[1], overlay.bgColor[2], overlay.bgColor[3], overlay.bgColor[4])
			draw_disk(x, y, 0, overlayGrow, numSlices, 1, 0, 360, 0)
			overlayGrow = math.floor(UITween.LinearTween(overlayGrow, targetSize, UIElement.clock - spawnClock) * 1000) / 1000
			if (overlayGrow >= WIN_W / 3 and not prizeDisplayHolder:isDisplayed()) then
				animateClock = UIElement.clock
				prizeDisplayHolder:show()
				setOpacityRecursive(prizeDisplayHolder, 0, true)

				local prizeAnimator = overlay:addChild({})
				prizeAnimator:addCustomDisplay(true, function()
					local alpha = UITween.SineEaseIn(UIElement.clock - animateClock)
					setOpacityRecursive(prizeDisplayHolder, alpha)
					if (alpha == 1) then
						prizeAnimator:kill()
					end
				end)
			end
			if (overlayGrow == targetSize) then
				overlay:addCustomDisplay(false, nil)
			end
		end)
end

---@param viewElement UIElement
function Events:showBlindFightMain(viewElement)
	if (viewElement == nil or viewElement.destroyed or EventsInternal.BlindFight == nil) then
		return
	end
	if (EventsInternal.BlindFight.userMoves == nil or EventsInternal.BlindFight.userMoves.turns == 0) then
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
		close_menu()
		self.BlindFightMode = 2
		EventsOnline:playEvent("blindfight")
		return
	end
	viewElement:kill(true)

	local playerInfoViewWidth = math.min(viewElement.size.w * 0.65, viewElement.size.w - 450)
	local playerInfoView = viewElement:addChild({
		pos = { 5, 0 },
		size = { playerInfoViewWidth, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local toplistView = viewElement:addChild({
		pos = { playerInfoView.shift.x + playerInfoView.size.w + 10, 0 },
		size = { viewElement.size.w - playerInfoView.shift.x * 2 - 10 - playerInfoView.size.w, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	local buttonsVertical = playerInfoView.size.h >= playerInfoView.size.w
	local maxBackdropSize = { x = playerInfoView.size.w - 20, y = playerInfoView.size.h - (buttonsVertical and 250 or 180) }
	local backdropSize = { x = maxBackdropSize.x, y = maxBackdropSize.x * 0.41 }
	if (backdropSize.y > maxBackdropSize.y) then
		backdropSize.y = maxBackdropSize.y
		backdropSize.x = backdropSize.y * 2.438
	end
	local playerInfoViewBackdrop = playerInfoView:addChild({
		pos = { 10 + (maxBackdropSize.x - backdropSize.x) / 2, 10 + (maxBackdropSize.y - backdropSize.y) / 3 },
		size = { backdropSize.x, backdropSize.y },
		bgImage = "../textures/menu/blindfight/scoresplash.tga"
	})
	local statsHolderSize = { math.min(450, playerInfoViewBackdrop.size.w * 0.4 ), math.min(150, playerInfoViewBackdrop.size.h * 0.4) }
	local playerInfoTierHeight = math.max(0, math.min(playerInfoViewBackdrop.size.h - 110 - statsHolderSize[2], playerInfoViewBackdrop.size.h * 0.415 - statsHolderSize[2] * 0.5))
	local playerInfoTierInfo = playerInfoViewBackdrop:addChild({
		pos = { playerInfoViewBackdrop.size.w * 0.615 - statsHolderSize[1] * 0.5, playerInfoTierHeight },
		size = statsHolderSize
	})
	playerInfoTierInfo:addAdaptedText(EventsInternal.BlindFight.groupTitle, { font = FONTS.BIG, intensity = 1, shadow = 4, shadowColor = { 0.1523, 0.0625, 0.1641, 1 } })
	local playerInfoDataHolder = playerInfoTierInfo:addChild({
		pos = { 0, playerInfoTierInfo.size.h },
		size = { playerInfoTierInfo.size.w, 60 },
		bgColor = { 0.1523, 0.0625, 0.1641, 1 },
		innerShadow = 3,
		shadowColor = { UICOLORWHITE, UICOLORBLACK },
		shapeType = ROUNDED,
		rounded = 10
	})
	playerInfoDataHolder:addChild({
		shift = { 25, 10 }
	}):addAdaptedText(EventsInternal.BlindFight.gamesPlayed .. " " .. utf8.lower(TB_MENU_LOCALIZED.EVENTSGAMESPLAYED) .. ", " .. EventsInternal.BlindFight.gamesWon .. " " .. utf8.lower(TB_MENU_LOCALIZED.EVENTSGAMESWON))

	local timeRemainingVerticalOffset = -60
	local timeRemainingBaseText = TB_MENU_LOCALIZED.BLINDFIGHTTIMEUNTILLEAGUERESET
	local playButtonsHolderHeight = buttonsVertical and 260 or 170
	if (EventsInternal.BlindFight.endtime == EventsInternal.BlindFight.seasonEndtime) then
		timeRemainingVerticalOffset = -40
		timeRemainingBaseText = TB_MENU_LOCALIZED.BLINDFIGHTTIMEUNTILSEASONEND
		playButtonsHolderHeight = playButtonsHolderHeight - 10
	end
	local numRewards = #EventsInternal.BlindFight.tierRewards
	local rewardsHolderHeight = math.min(playerInfoDataHolder.size.w / numRewards, 102, backdropSize.y * 0.2)
	--if (playerInfoView.pos.y + playerInfoView.size.h - playButtonsHolderHeight - playerInfoDataHolder.pos.y - playerInfoDataHolder.size.h - rewardsHolderHeight - 10 > 0) then
		local tierRewardsHolder = playerInfoDataHolder:addChild({
			pos = { 0, playerInfoDataHolder.size.h + 5 },
			size = { playerInfoDataHolder.size.w, rewardsHolderHeight }
		})
		local startX = tierRewardsHolder.size.w - numRewards * tierRewardsHolder.size.h + 6
		for i, v in pairs(EventsInternal.BlindFight.tierRewards) do
			local tierReward = tierRewardsHolder:addChild({
				pos = { startX + (i - 1) * tierRewardsHolder.size.h, 3 },
				size = { tierRewardsHolder.size.h - 6, tierRewardsHolder.size.h - 6 }
			})
			BattlePass:showPrizeItem(tierReward, {
				bgColor = { 0.204, 0.084, 0.202, 1 },
				bgOutlineColor = { 0, 0, 0, 1 },
				textBackdropColor = { 0.204, 0.084, 0.202, 0.67 },
				textColor = { 1, 1, 1, 1 },
				static = true,
				tc = v.tc,
				st = v.st,
				itemid = v.itemid,
				bpxp = v.bpxp,
				qi = v.qi
			})
		end
		local tierRewardsCaption = tierRewardsHolder:addChild({
			pos = { -tierRewardsHolder.size.w * 1.7 + startX - 10, 0 },
			size = { tierRewardsHolder.size.w * 0.7, tierRewardsHolder.size.h },
			uiShadowColor = { 0.1523, 0.0625, 0.1641, 1 },
		})
		tierRewardsCaption:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTPROMOTIONREWARDS, { font = FONTS.BIG, align = RIGHTMID, maxscale = 0.65, shadow = 4 })
	--end

	local playButtonsHolder = playerInfoView:addChild{
		pos = { 0, -playButtonsHolderHeight },
		size = { playerInfoView.size.w, playButtonsHolderHeight },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	}
	TBMenu:addBottomBloodSmudge(playButtonsHolder, 1)
	local makeOpenerButton = playButtonsHolder:addChild({
		pos = { 20, 20 },
		size = { buttonsVertical and playButtonsHolder.size.w - 40 or (playButtonsHolder.size.w - 40) / 2 - 10, 80 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	makeOpenerButton:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTREDOOPENER, { font = FONTS.BIG, maxscale = 0.65, padding = { x = 10, y = 10, w = 10, h = 10 } })
	makeOpenerButton:addMouseUpHandler(function()
			close_menu()
			self.BlindFightMode = 0
			EventsOnline:playEvent("blindfight")
		end)
	
	local resimulateButton = playButtonsHolder:addChild({
		pos = { buttonsVertical and makeOpenerButton.shift.x or playButtonsHolder.size.w / 2 + 10, buttonsVertical and makeOpenerButton.shift.y + makeOpenerButton.size.h + 10 or makeOpenerButton.shift.y },
		size = { makeOpenerButton.size.w, makeOpenerButton.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		shapeType = makeOpenerButton.shapeType,
		rounded = makeOpenerButton.rounded
	})
	resimulateButton:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTFIGHTAGAIN, { font = FONTS.BIG, maxscale = 0.65, padding = { x = 10, y = 10, w = 10, h = 10 } })
	resimulateButton:addMouseUpHandler(function()
			close_menu()
			self.BlindFightMode = 1
			EventsOnline:playEvent("blindfight")
		end)

	local leagueTimeRemaining = playButtonsHolder:addChild({
		pos = { 20, timeRemainingVerticalOffset },
		size = { playButtonsHolder.size.w - 40, 25 }
	})
	leagueTimeRemaining:addCustomDisplay(function(init)
			if (init == true) then return end
			local timeleft = EventsInternal.BlindFight.endtime - os.time()
			if (timeleft > 0) then
				leagueTimeRemaining:uiText(timeRemainingBaseText .. " " .. TBMenu:getTime(timeleft, 2), nil, nil, FONTS.LMEDIUM, nil, 0.85)
			else
				Events:showBlindFight()
			end
		end)
	if (EventsInternal.BlindFight.endtime ~= EventsInternal.BlindFight.seasonEndtime) then
		local seasonTimeRemaining = playButtonsHolder:addChild({
			pos = { leagueTimeRemaining.shift.x, leagueTimeRemaining.shift.y + leagueTimeRemaining.size.h },
			size = { leagueTimeRemaining.size.w, leagueTimeRemaining.size.h }
		})
		seasonTimeRemaining:addCustomDisplay(function(init)
				if (init == true) then return end
				local timeleft = EventsInternal.BlindFight.seasonEndtime - os.time()
				if (timeleft > 0) then
					seasonTimeRemaining:uiText(TB_MENU_LOCALIZED.BLINDFIGHTTIMEUNTILSEASONEND .. " " .. TBMenu:getTime(timeleft, 2), nil, nil, FONTS.LMEDIUM, nil, 0.85)
				else
					Events:showBlindFight()
				end
			end)
	end

	local elementHeight = 50
	local botBarHeight = EventsInternal.BlindFight.prestigeRewards == nil and 160 or 110
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(toplistView, elementHeight * 1.5, botBarHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

	local numPlayers = #EventsInternal.BlindFight.players
	local leaguePlayersTitle = topBar:addChild({ shift = { 25, 10 } })
	leaguePlayersTitle:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTCURRENTLEAGUE .. " (" .. numPlayers .. "/" .. EventsInternal.BlindFight.numGroupPlayers .. ")", nil, nil, FONTS.BIG, nil, 0.65)

	botBar.bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	TBMenu:addBottomBloodSmudge(botBar, 2)

	if (EventsInternal.BlindFight.prestigeRewards ~= nil) then
		local prestigeButton = botBar:addChild({
			pos = { 10, 10 },
			size = { botBar.size.w - 20, 90 },
			interactive = true,
			bgColor = { 0.204, 0.084, 0.202, 1 },
			hoverColor = { 0.269, 0.081, 0.303, 1 },
			pressedColor = { 0.184, 0.09, 0.192, 1 },
			uiColor = UICOLORWHITE,
			shapeType = ROUNDED,
			rounded = 4
		})
		local bubbles = { }
		local blobSegments = is_mobile() and 0 or 24
		for _ = 1, 20 do
			table.insert(bubbles, {
				pos = { x = prestigeButton.pos.x + math.random(0, prestigeButton.size.w), y = prestigeButton.pos.y + math.random(0, prestigeButton.size.h) * 2 },
				dir = { x = (math.random() - 0.5) * 5, y = 10 + math.random() * 30 },
				size = math.random(4, 12),
				bgColor = { 0.15 + math.random() * 0.06, 0.06 + math.random() * 0.037, 0.16 + math.random() * 0.059, 0 }
			})
		end
		prestigeButton:addCustomDisplay(function()
				for _, v in pairs(bubbles) do
					if (v.pos.y < prestigeButton.pos.y - prestigeButton.size.h) then
						v.bgColor[4] = math.floor(UITween.LinearTween(v.bgColor[4], 0, UIElement.deltaClock) * 1000) / 1000
					elseif (v.pos.y < prestigeButton.pos.y + prestigeButton.size.h) then
						if (v.bgColor[4] < 1) then
							v.bgColor[4] = math.min(1, v.bgColor[4] + UIElement.deltaClock)
						end
					end
					set_color(v.bgColor[1], v.bgColor[2], v.bgColor[3], v.bgColor[4])
					draw_disk(v.pos.x, v.pos.y, 0, v.size, blobSegments, 1, 0, 360, 0)
					v.pos.x = v.pos.x + v.dir.x * UIElement.deltaClock
					v.pos.y = v.pos.y - v.dir.y * UIElement.deltaClock
					if (v.bgColor[4] <= 0) then
						v.pos.y = prestigeButton.pos.y + math.random(0, prestigeButton.size.h)
						v.pos.x = prestigeButton.pos.x + math.random(0, prestigeButton.size.w)
					end
				end
			end)
		prestigeButton:addMouseUpHandler(EventsInternal.ShowBlindFightPrestige)
		prestigeButton:addChild({ shift = { 25, 10 } }):addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTPRESTIGE, { font = FONTS.BIG, maxscale = 0.75 })
	else
		local leagueInfo = botBar:addChild({ shift = { 25, 10 }	})
		local leagueInfoMessage = TB_MENU_LOCALIZED.BLINDFIGHTLEAGUEINSUFFICIENTPLAYERSINFO
		local numPromotePlayers = math.floor(numPlayers * EventsInternal.BlindFight.promotePlayersPercentage)
		if (numPlayers >= EventsInternal.BlindFight.minPromoteGroupPlayers) then
			leagueInfoMessage = utf8.gsub(TB_MENU_LOCALIZED.BLINDFIGHTLEAGUEPROMOTIONINFO, "{x}", tostring(numPromotePlayers))
			if (numPlayers == EventsInternal.BlindFight.numGroupPlayers) then
				leagueInfo.size.h = leagueInfo.size.h / 2 - 9
				local leagueInfoOrWord = leagueInfo:addChild({
					pos = { 0, leagueInfo.size.h },
					size = { leagueInfo.size.w, 18 },
					uiColor = TB_MENU_DEFAULT_INACTIVE_COLOR
				})
				leagueInfoOrWord:addAdaptedText(TB_MENU_LOCALIZED.WORDOR, { font = FONTS.LMEDIUM, maxscale = 0.75 })
				local leagueInfoInstant = leagueInfo:addChild({
					pos = { 0, leagueInfo.size.h + 18 }
				})
				leagueInfoInstant:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTLEAGUEPROMOTIONINFOINSTANT, { font = FONTS.LMEDIUM, maxscale = 0.85, baselineScale = 1.2 })
			end
		end
		leagueInfo:addAdaptedText(leagueInfoMessage, { font = FONTS.LMEDIUM, maxscale = 0.85, baselineScale = 1.2 })
	end

	local listElements = {}
	for i, v in pairs(EventsInternal.BlindFight.players) do
		local listElement = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, listElement)
		local isUser = utf8.lower(v.name) == utf8.lower(TB_MENU_PLAYER_INFO.username)
		local isDefeated = in_array(v.userid, EventsInternal.BlindFight.defeated)
		local playerEntry = listElement:addChild({
			pos = { 10, 2 },
			size = { listElement.size.w - 12, listElement.size.h - 4 },
			bgColor = isUser and TB_MENU_DEFAULT_DARKER_BLUE or (isDefeated and TB_MENU_DEFAULT_DARKER_COLOR or TB_MENU_DEFAULT_DARKEST_COLOR),
			shapeType = ROUNDED,
			rounded = 3
		})
		if (not isUser and not isDefeated) then
			local undefeatedIcon = playerEntry:addChild({
				pos = { 6 + playerEntry.size.h / 3, playerEntry.size.h / 3 },
				size = { playerEntry.size.h / 3, playerEntry.size.h / 3 },
				bgColor = TB_MENU_DEFAULT_ORANGE,
				shapeType = ROUNDED,
				rounded = playerEntry.size.h
			})
		elseif (i < 4 and v.wins > 0) then
			local placementIcon = playerEntry:addChild({
				pos = { 10, 2 },
				size = { playerEntry.size.h - 4, playerEntry.size.h - 4 },
				bgImage = "../textures/menu/general/laurel.tga",
				imageColor = i == 1 and get_color_rgba(COLORS.GOLD) or (i == 2 and get_color_rgba(COLORS.QUICKSILVER) or get_color_rgba(COLORS.BRONZE))
			})
			local textSize = placementIcon.size.w * 0.7
			placementIcon:addChild({
				pos = { (placementIcon.size.h - textSize) / 2, 0 },
				size = { textSize, textSize }
			}):addAdaptedText(tostring(i), { shadow = 1 })
		end
		local playerName = playerEntry:addChild({
			pos = { 15 + playerEntry.size.h, 5 },
			size = { playerEntry.size.w / 2 - 30 - playerEntry.size.h, playerEntry.size.h - 10 }
		})
		playerName:addAdaptedText(v.name, { align = LEFTMID })
		if (v.prestige > 0) then
			local nameLength = get_string_length(playerName.dispstr[1], playerName.textFont) * playerName.textScale
			Events:displayBlindFightPrestige(playerName, v.prestige, {
				x = nameLength + 5, y = 7, w = playerName.size.h - 14, h = playerName.size.h - 14
			})
		end
		local playerWins = playerEntry:addChild({
			pos = { playerName.shift.x + playerName.size.w + 10, playerName.shift.y },
			size = { playerEntry.size.w - playerName.shift.x - playerName.size.w - 20, playerName.size.h }
		})
		playerWins:addAdaptedText(utf8.gsub(TB_MENU_LOCALIZED.EVENTSPLAYERWINS, "{x}", v.wins), nil, nil, FONTS.MEDIUM, RIGHTMID)
	end

	if (#listElements * elementHeight > listingHolder.size.h) then
		for _, v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
	else
		listingHolder:moveTo(6, nil, true)
	end

	if (EventsInternal.BlindFight.pendingRewards) then
		local overlay = TBMenu:spawnWindowOverlay({ 1, 1, 1, 0.9 })
		overlay.uiColor = { 0.1523, 0.0625, 0.1641, 1 }
		---@diagnostic disable-next-line: undefined-global
		Request:queue(claim_blindfight_rewards, "blindfight_rewardclaim", function(_, response)
			if (response:find("^LEAGUE_PROMOTED_REWARDS\t")) then
				local claimedRewards = Events.ParseBlindFightRewards(response)
				Events:showBlindFightPromotion(overlay, claimedRewards, nil, EventsInternal.BlindFight.groupTitle)
				return
			end
			overlay:kill()
		end, function()
			overlay:kill()
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ACCOUNTINFOERROR)
		end)
		TBMenu:displayLoadingMark(overlay)
		EventsInternal.BlindFight.pendingRewards = false
	end
end

function Events:showBlindFight()
	TBMenu:clearNavSection()
	TBMenu:showNavigationBar(Events:getNavigationButtons(TB_MENU_EVENTS_OPEN), true)

	usage_event("blindfight")

	if (self.GetConfig("BlindFightPlays") == 0) then
		close_menu()
		self.BlindFightMode = 2
		EventsOnline:playEvent("blindfight")
		return
	end

	TB_MENU_SPECIAL_SCREEN_ISOPEN = 12
	local time = os.time()
	if (EventsInternal.BlindFight == nil or EventsInternal.BlindFight.endtime < time or EventsInternal.BlindFight.lastupdate + self.EventStalePeriod < time) then
		local loaderView = TBMenu.CurrentSection:addChild({
			shift = { 5, 0 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(loaderView)
		local loadingMark = TBMenu:displayLoadingMark(loaderView)
		self:refreshBlindFight(loaderView, loadingMark, function()
				self:showBlindFightMain(TBMenu.CurrentSection)
			end)
	else
		self:showBlindFightMain(TBMenu.CurrentSection)
	end
end

---Refreshes Blind Fight data
---@param loaderView UIElement?
---@param loadingMark UIElement?
---@param onComplete function?
function Events:refreshBlindFight(loaderView, loadingMark, onComplete)
	Request:queue(function()
		download_server_info("blindfight&user=" .. TB_MENU_PLAYER_INFO.username)
	end, "blindfight_leagueinfo", function(_, response)
		if (loadingMark ~= nil and not loadingMark.destroyed) then
			loadingMark:kill()
		end
		if (string.find(response, "^ERROR")) then
			if (loaderView ~= nil and not loaderView.destroyed) then
				local errorMessage = response:gsub("^ERROR ", "")
				loaderView:addChild({ shift = { 100, 50 }}):addAdaptedText(errorMessage)
			end
			EventsInternal.BlindFight = nil
			return
		end

		EventsInternal.BlindFight = { players = { }, defeated = { }, lastupdate = os.time(), groupTitle = "", tierRewards = { }, userRPG = { strength = 0, speed = 0, endurance = 0 } }
		local autoupdate = get_option("autoupdate")
		for ln in response:gmatch("[^\n]*\n?") do
			ln = ln:gsub("\n$", "")
			if (ln:find("^SEASON_INFO\t")) then
				local _, segments = ln:gsub("\t", "")
				local data = { ln:match(("([^\t]*)\t"):rep(segments)) }
				EventsInternal.BlindFight.modName = data[2]
				EventsInternal.BlindFight.endtime = os.time() + data[3]
				EventsInternal.BlindFight.groupTitle = data[4]
				EventsInternal.BlindFight.gamesPlayed = tonumber(data[5]) or 0
				EventsInternal.BlindFight.gamesWon = tonumber(data[6]) or 0
				EventsInternal.BlindFight.seasonEndtime = os.time() + data[7]
				---Make sure we have the mod locally in case of non-standard ones
				runCmd("dl " .. EventsInternal.BlindFight.modName, false, CMD_ECHO_FORCE_DISABLED)
			elseif (ln:find("^BLINDFIGHT\t")) then
				local _, segments = ln:gsub("\t", "")
				local data = { ln:match(("([^\t]*)\t"):rep(segments)) }
				EventsInternal.BlindFight.minVersion = tonumber(data[2]) or 250129
				EventsInternal.BlindFight.numGroupPlayers = tonumber(data[3]) or 8
				EventsInternal.BlindFight.minPromoteGroupPlayers = tonumber(data[4]) or 5
				EventsInternal.BlindFight.promotePlayersPercentage = tonumber(data[5]) or 0.375
				EventsInternal.BlindFight.rpgDecayRate = tonumber(data[6]) or 0.75
			elseif (ln:find("^LEAGUE_PENDING_REWARDS\t")) then
				EventsInternal.BlindFight.pendingRewards = true
			elseif (ln:find("^LEAGUE_REWARDS\t")) then
				EventsInternal.BlindFight.tierRewards = Events.ParseBlindFightRewards(ln)
			elseif (ln:find("^LEAGUE_PRESTIGE\t")) then
				EventsInternal.BlindFight.prestigeRewards = Events.ParseBlindFightRewards(ln)
			elseif (ln:len() > 0) then
				local _, segments = ln:gsub("\t", "")
				local data = { ln:match(("([^\t]*)\t"):rep(segments)) }
				table.insert(EventsInternal.BlindFight.players, {
					userid = data[1],
					name = data[2],
					wins = tonumber(data[3]) or 0,
					prestige = tonumber(data[6]) or 0
				})
				if (string.lower(data[2]) == string.lower(TB_MENU_PLAYER_INFO.username)) then
					_, segments = string.gsub(data[4], ":", "")
					EventsInternal.BlindFight.defeated = { string.match(data[4], ("([^:]*):?"):rep(segments + 1)) }
					_, segments = string.gsub(data[5], ":", "")
					local openerLines = { string.match(data[5], ("([^:]*):?"):rep(segments + 1)) }
					EventsInternal.BlindFight.userMoves = MemoryMove.FromOpener(openerLines)
					EventsInternal.BlindFight.userRPG.strength = tonumber(data[7]) or 0
					EventsInternal.BlindFight.userRPG.speed = tonumber(data[8]) or 0
					EventsInternal.BlindFight.userRPG.endurance = tonumber(data[9]) or 0
					EventsInternal.BlindFight.userStats = EventsInternal.BlindFight.players[#EventsInternal.BlindFight.players]
				elseif (autoupdate == 1) then
					---Download base player customs so we see them when fighting
					download_head(data[2])
				end
			end
		end
		EventsInternal.BlindFight.players = table.qsort(EventsInternal.BlindFight.players, "wins", SORT_DESCENDING)
		if (onComplete ~= nil) then
			onComplete()
		end
	end, function(_, error)
		EventsInternal.BlindFight = nil
		if (loaderView ~= nil and not loaderView.destroyed) then
			loaderView:addChild({ shift = { 100, 50 }}):addAdaptedText(error)
			if (loadingMark ~= nil and not loadingMark.destroyed) then
				loadingMark:kill()
			end
		end
	end)
end

function Events.HasNewChallenges()
	return Events.GetConfig("challenges") ~= EventsInternal.StaticEventVersion
end

EventsInternal.LoadConfig()
Events:refreshBlindFight()
add_hook("login", Events.HookName, EventsInternal.Reset)
