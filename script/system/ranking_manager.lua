require('toriui.uielement')
require('system.menu_manager')
require('system.playerinfo_manager')
require('system.roomlist_manager')

if (Ranking == nil) then
	---@class RankingPlayerData
	---@field name string Name of the user whose ranking data we currently have cached
	---@field games integer User's Qi at the moment of last ranking data update

	---@class RankingPlayerModData
	---@field name string Mod name
	---@field rank integer
	---@field elo number

	---@class RankingTrendEntry
	---@field rank integer
	---@field elo number

	---@class RankingTier
	---@field title string
	---@field showRank boolean Whether this ranking tier should show public global rank
	---@field maxElo number Maximum Elo value for this tier, exclusive
	---@field minElo number Minimum Elo value for this tier, inclusive
	---@field image string Texture path for tier's icon

	---@class RankingTopPlayer : PlayerInfoRanking
	---@field username string

	---Toribash seasonal ranking manager class
	---@class Ranking
	---@field EloFactor number Additional Elo scaling factor that we may want to apply to any Elo gain during the season. Typically this would stay at `1`.
	---@field EloDivisor number Internal value used to retrieve games to next tier estimate
	---@field PlayerData RankingPlayerData Information about current user's ranking
	---@field PlayerTrends RankingTrendEntry[] Table with ranking trends history for the player
	---@field PlayerModRanking RankingPlayerModData[] Per-mod ranking information for currently logged in user
	---@field RankingTiers RankingTier[] Information about ranking tiers available during current ranking period
	---@field QualificationMatches integer How many games should the user play to receive a real ranking tier
	---@field QualifyingTier RankingTier Placeholder tier for players who haven't yet qualified for a ranking tier
	Ranking = {
		__index = {},
		EloFactor = 1,
		EloDivisor = 400,
		PlayerTrends = {},
		PlayerModRanking = {},
		RankingTiers = {
			{
				title = "Diamond",
				showRank = true,
				maxElo = 10000,
				minElo = 1690,
				image = "../textures/menu/ranking/diamond.tga"
			},
			{
				title = "Platinum I",
				showRank = true,
				maxElo = 1690,
				minElo = 1675,
				image = "../textures/menu/ranking/plat1.tga"
			},
			{
				title = "Platinum II",
				showRank = true,
				maxElo = 1675,
				minElo = 1660,
				image = "../textures/menu/ranking/plat2.tga"
			},
			{
				title = "Platinum III",
				showRank = true,
				maxElo = 1660,
				minElo = 1645,
				image = "../textures/menu/ranking/plat3.tga"
			},
			{
				title = "Gold I",
				showRank = true,
				maxElo = 1645,
				minElo = 1630,
				image = "../textures/menu/ranking/gold1.tga"
			},
			{
				title = "Gold II",
				showRank = true,
				maxElo = 1630,
				minElo = 1615,
				image = "../textures/menu/ranking/gold2.tga"
			},
			{
				title = "Gold III",
				showRank = true,
				maxElo = 1615,
				minElo = 1595,
				image = "../textures/menu/ranking/gold3.tga"
			},
			{
				title = "Silver",
				showRank = false,
				maxElo = 1595,
				minElo = 1575,
				image = "../textures/menu/ranking/silver.tga"
			},
			{
				title = "Bronze",
				showRank = false,
				maxElo = 1575,
				minElo = 1550,
				image = "../textures/menu/ranking/bronze.tga"
			},
			{
				title = "Elo Hell",
				showRank = false,
				maxElo = 1550,
				minElo = 0,
				image = "../textures/menu/ranking/elohell.tga"
			}
		},
		QualificationMatches = 10,
		QualifyingTier = {
			title = "Qualifying",
			image = "../textures/menu/ranking/silver.tga",
			showRank = false
		}
	}
	setmetatable({}, Ranking)
end

---@return MenuNavButton[]
function Ranking:getNavigationButtons()
	return {
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
			action = function()
				TBMenu.CurrentSection:kill(true)
				TBMenu.NavigationBar:kill(true)
				TBMenu:showNavigationBar()
				TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
			end
		}
	}
end

---Parses network response containing top players' ranking information
---@param data string
---@return RankingTopPlayer[]
function Ranking:parseRankingData(data)
	local rankingData = {}
	for ln in data:gmatch("[^\n]+\n?") do
		if (not ln:match("^#")) then
			local segments = 5
			local data_stream = { ln:match(("([^\t]+)\t*"):rep(segments)) }
			local entry = {
				username = data_stream[1],
				rank = tonumber(data_stream[2]) or 0,
				elo = tonumber(data_stream[3]) or 0,
				wins = tonumber(data_stream[4]) or 0,
				loses = tonumber(data_stream[5]) or 0
			}
			entry.games = entry.wins + entry.loses
			table.insert(rankingData, entry)
		end
	end
	return rankingData
end

---Parses network response containing current user's ranking information
---@param data string
---@return boolean #Whether data has been parsed successfully
function Ranking:parseRankingTrends(data)
	Ranking.PlayerTrends = {}
	Ranking.PlayerModRanking = {}
	local minElo, topElo = 10000, 0
	local mods = true

	for ln in data:gmatch("[^\n]+\n?") do
		if (ln:find("^#NO DATA FOUND")) then
			-- User hasn't played ranked yet, exit with empty data
			return true
		end
		if (ln:find("^#ELO")) then
			mods = false
		end
		if (not ln:find("^#")) then
			if (mods) then
				local _, segments = ln:gsub("([^\t]*)\t?", "")
				local data_stream = { ln:match(("([^\t]+)\t*"):rep(segments)) }
				---@type RankingPlayerModData
				local info = {
					name = data_stream[1],
					rank = tonumber(data_stream[2]) or 0,
					elo = tonumber(data_stream[3]) or 0
				}
				table.insert(Ranking.PlayerModRanking, info)
			else
				local _, segments = ln:gsub("([^\t]*)\t?", "")
				local data_stream = { ln:match(("([^\t]+)\t*"):rep(segments)) }
				local info = {
					elo = tonumber(data_stream[1]) or 0,
					rank = tonumber(data_stream[2]) or 0
				}
				topElo = math.max(topElo, info.elo)
				minElo = math.min(minElo, info.elo)
				table.insert(Ranking.PlayerTrends, info)
			end
		end
	end
	Ranking.PlayerTrends.topElo = topElo
	Ranking.PlayerTrends.minElo = minElo
	return true
end

---Displays player's ranking information with trends in a UIElement viewport
---@param viewElement UIElement
---@return nil
function Ranking:showRankingTrendsWithHistory(viewElement)
	viewElement:kill(true)
	viewElement.bgColor = { 0, 0, 0, 0 }

	local userTrendsView = UIElement:new({
		parent = viewElement,
		pos = { 0, 0 },
		size = { viewElement.size.w, viewElement.size.h / 3 - 5 }
	})
	local rankTrendView = UIElement:new({
		parent = userTrendsView,
		pos = { 0, 0 },
		size = { not TB_MENU_PLAYER_INFO.ranking.qualifying and userTrendsView.size.w / 2 - 5 or userTrendsView.size.w, userTrendsView.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local trend = nil
	local currentRank = TB_MENU_PLAYER_INFO.ranking.rank
	local compareRank = currentRank
	if (currentRank) then
		for i = #Ranking.PlayerTrends, 1, -1 do
			if (Ranking.PlayerTrends[i].rank ~= compareRank) then
				compareRank = Ranking.PlayerTrends[i].rank
				break
			end
		end
		trend = currentRank == compareRank and 0 or (currentRank > compareRank and -1 or 1)
	end

	local rankTrendViewTitle = rankTrendView:addChild({
		pos = { 10, 5 },
		size = { rankTrendView.size.w - 20, 30}
	})
	rankTrendViewTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKEGLOBALRANKING, nil, nil, FONTS.BIG, nil, nil, nil, 0.1)
	local rankedInfoView = rankTrendView:addChild({
		pos = { 10, rankTrendViewTitle.shift.y * 2 + rankTrendViewTitle.size.h },
		size = { rankTrendView.size.w - 20, rankTrendView.size.h - rankTrendViewTitle.shift.y * 3 - rankTrendViewTitle.size.h }
	})
	local iconScale = math.min(rankedInfoView.size.w / 2, rankedInfoView.size.h)
	local iconFieldScale = math.max(rankedInfoView.size.w / 5 * 2, iconScale)
	local rankingTierIconHolder = rankedInfoView:addChild({
		pos = { rankedInfoView.size.w / 2 - iconFieldScale, (rankedInfoView.size.h - iconScale) / 2 },
		size = { iconFieldScale, iconScale }
	})
	local rankingTierIcon = rankingTierIconHolder:addChild({
		shift = { (iconFieldScale - iconScale) / 2, 0 },
		bgImage = TB_MENU_PLAYER_INFO.ranking.tier.image,
		imageColor = TB_MENU_PLAYER_INFO.ranking.qualifying and { 0.2, 0.2, 0.2, 1 } or UICOLORWHITE
	})
	rankingTierIcon:moveTo(nil, -iconScale * 0.1, true)
	local rankingTierTitle = rankingTierIcon:addChild({
		pos = { 0, TB_MENU_PLAYER_INFO.ranking.nextTierElo > 0 and (-iconScale / 7 * 3) or (-iconScale / 3) },
		size = { iconScale, TB_MENU_PLAYER_INFO.ranking.nextTierElo > 0 and (iconScale / 5) or (iconScale / 4) },
		shapeType = ROUNDED,
		rounded = TB_MENU_PLAYER_INFO.ranking.nextTierElo > 0 and { 5, 0 } or 5,
		bgColor = { 0, 0, 0, 0.4 }
	})
	rankingTierTitle:addChild({ shift = { 10, 2 } }):addAdaptedText(TB_MENU_PLAYER_INFO.ranking.tier.title, nil, nil, FONTS.BIG, nil, 0.7, nil, 0.3)

	if (TB_MENU_PLAYER_INFO.ranking.nextTierElo > 0) then
		local nextTierGamesHolder = rankingTierTitle:addChild({
			pos = { 0, rankingTierTitle.size.h },
			size = { rankingTierTitle.size.w, math.min(rankingTierTitle.size.h * 1.2, 40) },
			bgColor = { 0, 0, 0, 0.4 },
			rounded = { 0, 5 },
			interactive = true
		}, true)

		local bestAverageOpponent = 1.01 * (TB_MENU_PLAYER_INFO.ranking.elo + 1600) / 2
		local worstAverageOpponent = (1600 / TB_MENU_PLAYER_INFO.ranking.elo) * (TB_MENU_PLAYER_INFO.ranking.elo + 1600) / 2

		local minGamesToNextTier = math.ceil((TB_MENU_PLAYER_INFO.ranking.nextTierElo - TB_MENU_PLAYER_INFO.ranking.elo) / (Ranking.EloFactor * (1 - (1 / ( 1 + (math.pow(TB_MENU_PLAYER_INFO.ranking.elo, (bestAverageOpponent - TB_MENU_PLAYER_INFO.ranking.elo) / Ranking.EloDivisor)))))))
		local maxGamesToNextTier = math.ceil((TB_MENU_PLAYER_INFO.ranking.nextTierElo - TB_MENU_PLAYER_INFO.ranking.elo) / (Ranking.EloFactor * (1 - (1 / ( 1 + (math.pow(TB_MENU_PLAYER_INFO.ranking.elo, (worstAverageOpponent - TB_MENU_PLAYER_INFO.ranking.elo) / Ranking.EloDivisor)))))))

		local winsToNextTierString = (minGamesToNextTier == maxGamesToNextTier and minGamesToNextTier or (minGamesToNextTier .. " - " .. maxGamesToNextTier)) .. " " .. TB_MENU_LOCALIZED.MATCHMAKEWINSTONEXTTIER
		nextTierGamesHolder:addChild({
			pos = { 5, 0 },
			size = { nextTierGamesHolder.size.w - 10, nextTierGamesHolder.size.h - 5 }
		}):addAdaptedText(winsToNextTierString, nil, nil, 4, nil, 0.8)

		local eloGainPopup = TBMenu:displayPopup(nextTierGamesHolder, TB_MENU_LOCALIZED.MATCHMAKEELOGAININFO)
		eloGainPopup:moveTo(-(eloGainPopup.size.w - nextTierGamesHolder.size.w) / 2, nextTierGamesHolder.size.h + 5, true)
		eloGainPopup:updateChildPos()
		if (eloGainPopup.pos.x < 10) then
			eloGainPopup:moveTo(10 - eloGainPopup.pos.x, nil, true)
		end
	end

	local rankedInfoTextHolder = rankedInfoView:addChild({
		pos = { rankedInfoView.size.w / 2, 0 },
		size = { iconFieldScale, rankedInfoView.size.h }
	})
	local eloTextShift, eloTextSize = 0, rankedInfoTextHolder.size.h / 2
	if (TB_MENU_PLAYER_INFO.ranking.tier.showRank) then
		local rankedInfoTextRank = rankedInfoTextHolder:addChild({
			pos = { 0, 0 },
			size = { rankedInfoTextHolder.size.w, rankedInfoTextHolder.size.h / 3 }
		})
		if (trend and trend ~= 0) then
			TBMenu:showTextWithImage(rankedInfoTextRank, TB_MENU_LOCALIZED.MATCHMAKERANK .. " " .. TB_MENU_PLAYER_INFO.ranking.rank, FONTS.BIG, 20, trend > 0 and "../textures/menu/general/buttons/doublearrowup.tga" or "../textures/menu/general/buttons/doublearrowdown.tga")
		else
			rankedInfoTextRank:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANK .. " " .. TB_MENU_PLAYER_INFO.ranking.rank, nil, nil, FONTS.BIG, CENTERBOT)
		end
		eloTextShift = rankedInfoTextRank.size.h
		eloTextSize = rankedInfoTextRank.size.h
	end

	if (not TB_MENU_PLAYER_INFO.ranking.qualifying) then
		local rankedInfoTextElo = rankedInfoTextHolder:addChild({
			pos = { 0, eloTextShift },
			size = { rankedInfoTextHolder.size.w, eloTextSize }
		})
		rankedInfoTextElo:addAdaptedText(true, string.format("%4.2f", TB_MENU_PLAYER_INFO.ranking.elo) .. " " .. TB_MENU_LOCALIZED.MATCHMAKEELO, nil, nil, FONTS.BIG, nil, 0.55, nil, 0.3)

		local rankedInfoTextGames = UIElement:new({
			parent = rankedInfoTextHolder,
			pos = { 0, rankedInfoTextElo.shift.y + rankedInfoTextElo.size.h },
			size = { rankedInfoTextHolder.size.w, rankedInfoTextHolder.size.h / 4 }
		})
		local games = TB_MENU_PLAYER_INFO.ranking.wins + TB_MENU_PLAYER_INFO.ranking.loses
		local winrate = games ~= 0 and math.floor(TB_MENU_PLAYER_INFO.ranking.wins / games * 100 + 0.5) or nil
		local gameInfoStr = games .. " " .. TB_MENU_LOCALIZED.MATCHMAKEFIGHTSTOTAL
		gameInfoStr = winrate and (gameInfoStr .. "\n" .. winrate .. "% " .. TB_MENU_LOCALIZED.MATCHMAKEWINRATE) or gameInfoStr
		rankedInfoTextGames:addAdaptedText(true, gameInfoStr, nil, nil, 4, CENTER, 0.85)

		local modTrendsView = UIElement:new({
			parent = userTrendsView,
			pos = { userTrendsView.size.w / 2 + 5, 0 },
			size = { userTrendsView.size.w / 2 - 5, userTrendsView.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local modTrendsTitle = UIElement:new({
			parent = modTrendsView,
			pos = { 10, 5 },
			size = { modTrendsView.size.w - 20, 30 }
		})
		modTrendsTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANKINGMODS, nil, nil, FONTS.BIG, nil, nil, nil, 0.1)

		local modListView = UIElement:new({
			parent = modTrendsView,
			pos = { 0, modTrendsTitle.shift.y + modTrendsTitle.size.h + 5 },
			size = { modTrendsView.size.w, modTrendsView.size.h - modTrendsTitle.shift.y - modTrendsTitle.size.h - 10 }
		})
		local height = math.min(WIN_H / 35, 25)
		local maxDisplay = math.floor(modListView.size.h / height)
		local modsToShow = math.min(#Ranking.PlayerModRanking, maxDisplay)
		local posY = modListView.size.h / modsToShow
		if (#Ranking.PlayerModRanking == 0) then
			modListView:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANKEDMODSEMPTY)
		end
		for i, v in pairs(table.qsort(Ranking.PlayerModRanking, { "rank", "name" })) do
			if (i > maxDisplay) then
				break
			end
			local modTrend = UIElement:new({
				parent = modTrendsView,
				pos = { 10, modTrendsTitle.shift.y + modTrendsTitle.size.h + posY / 2 + (i - 1) * height },
				size = { modTrendsView.size.w - 20, height }
			})
			local modName = UIElement:new({
				parent = modTrend,
				pos = { 0, 0 },
				size = { modTrend.size.w / 2, modTrend.size.h }
			})
			modName:addAdaptedText(true, v.name:gsub("%.tbm$", ''), nil, nil, nil, LEFTMID, 0.8, nil, 0)
			local modStats = UIElement:new({
				parent = modTrend,
				pos = { modTrend.size.w / 2 + 20, 0 },
				size = { modTrend.size.w / 2 - 20, modTrend.size.h }
			})
			modStats:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANK .. " " .. v.rank .. ", " .. v.elo .. " " .. TB_MENU_LOCALIZED.MATCHMAKEELO, nil, nil, nil, RIGHTMID, 0.8, nil, 0)
		end
	else
		rankedInfoTextHolder:addChild({
			shift = { 0, rankedInfoTextHolder.size.h / 5 }
		}):addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKEQUALIFICATIONINFO)
	end

	local trendsView = UIElement:new({
		parent = viewElement,
		pos = { 0, userTrendsView.size.h + 10 },
		size = { viewElement.size.w, viewElement.size.h - userTrendsView.size.h - 10 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local trendsTitle = UIElement:new({
		parent = trendsView,
		pos = { 10, 10 },
		size = { trendsView.size.w - 20, 35 }
	})
	trendsTitle:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKERANKINGTRENDS, nil, nil, FONTS.BIG)

	local trendsChartBG = UIElement:new({
		parent = trendsView,
		pos = { 0, trendsTitle.shift.y + trendsTitle.size.h + 20 },
		size = { trendsView.size.w, trendsView.size.h - trendsTitle.shift.y - trendsTitle.size.h - 20 }
	})
	TBMenu:addBottomBloodSmudge(trendsView, 1)

	if (#Ranking.PlayerTrends < 4) then
		trendsChartBG:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKEMOREGAMESREQUIREDFORTRENDS)
	else
		local trendsChartView = UIElement:new({
			parent = trendsChartBG,
			pos = { 70, 10 },
			size = { trendsChartBG.size.w - 90, trendsChartBG.size.h - 40 }
		})
		local eloScale = (Ranking.PlayerTrends.topElo - Ranking.PlayerTrends.minElo) / trendsChartView.size.h
		local width = trendsChartView.size.w / (#Ranking.PlayerTrends - 1)
		local lineLeft = UIElement:new({
			parent = trendsChartBG,
			pos = { trendsChartView.shift.x, trendsChartView.shift.y },
			size = { 1, trendsChartView.size.h },
			bgColor = { 1, 1, 1, 0.4 }
		})
		local legendLeft = UIElement:new({
			parent = lineLeft,
			pos = { -trendsChartView.shift.x + 10, -lineLeft.size.h - 9 },
			size = { trendsChartView.shift.x - 20, lineLeft.size.h + 20 }
		})
		legendLeft:addAdaptedText(true, TB_MENU_LOCALIZED.WORDELO, nil, nil, 4, RIGHTMID, 0.8)
		local maxeloLeft = UIElement:new({
			parent = legendLeft,
			pos = { 0, 0 },
			size = { legendLeft.size.w, legendLeft.size.h }
		})
		maxeloLeft:addAdaptedText(true, Ranking.PlayerTrends.topElo, nil, nil, 4, RIGHT, 0.6)
		local mineloLeft = UIElement:new({
			parent = legendLeft,
			pos = { 0, 0 },
			size = { legendLeft.size.w, legendLeft.size.h }
		})
		mineloLeft:addAdaptedText(true, Ranking.PlayerTrends.minElo, nil, nil, 4, RIGHTBOT, 0.6)
		local lineBot = UIElement:new({
			parent = trendsChartBG,
			pos = { trendsChartView.shift.x, trendsChartView.shift.y + trendsChartView.size.h },
			size = { trendsChartView.size.w, 1 },
			bgColor = { 1, 1, 1, 0.4 }
		})
		local legendBot = UIElement:new({
			parent = lineBot,
			pos = { 0, 5 },
			size = { lineBot.size.w, 20 }
		})
		legendBot:addAdaptedText(true, TB_MENU_LOCALIZED.RANKINGTRENDSLEGENDLASTGAMES1 .. " " .. #Ranking.PlayerTrends .. " " .. TB_MENU_LOCALIZED.RANKINGTRENDSLEGENDLASTGAMES2, nil, nil, 4, CENTER, 0.8)
		for i, info in ipairs(Ranking.PlayerTrends) do
			if (not Ranking.PlayerTrends[i + 1]) then
				break
			end
			local elo = info.elo
			local linePart = trendsChartView:addChild({
				pos = { (i - 1) * width, (Ranking.PlayerTrends.topElo - elo) / eloScale },
				size = { i * width, (Ranking.PlayerTrends.topElo - Ranking.PlayerTrends[i + 1].elo) / eloScale }
			})
			local targetElo = linePart:addChild({
				pos = { 0, 0 },
				size = { 8, 8 },
				shapeType = ROUNDED,
				rounded = 4,
				bgColor = UICOLORWHITE,
				interactive = true
			})
			targetElo:moveTo(-targetElo.size.w / 2, -targetElo.size.h / 2, true)
			local popup = TBMenu:displayPopup(targetElo, elo .. " " .. TB_MENU_LOCALIZED.WORDELO)
			popup:moveTo(-popup.size.w / 2, -popup.size.h * 1.5)
			if (not Ranking.PlayerTrends[i + 2]) then
				local targetEloFinal = trendsChartView:addChild({
					pos = { linePart.size.w, linePart.size.h },
					size = { 8, 8 },
					shapeType = ROUNDED,
					rounded = 4,
					bgColor = UICOLORWHITE,
					interactive = true
				})
				targetEloFinal:moveTo(-targetEloFinal.size.w / 2, -targetEloFinal.size.h / 2, true)
				local popup = TBMenu:displayPopup(targetEloFinal, elo .. " " .. TB_MENU_LOCALIZED.WORDELO)
				popup:moveTo(-popup.size.w / 2, -popup.size.h * 1.5)
			end
			linePart:addCustomDisplay(true, function()
					set_color(1, 1, 1, 0.6)
					draw_line(linePart.pos.x, linePart.pos.y, trendsChartView.pos.x + linePart.size.w, trendsChartView.pos.y + linePart.size.h, 2)
				end)
		end
	end
end

---Displays top global players in a specified UIElement viewport
---@param viewElement UIElement
---@param playerRanking RankingTopPlayer[]
---@return nil
function Ranking:showGlobalRankToplist(viewElement, playerRanking)
	viewElement:kill(true)

	local elementHeight = 45
	local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 50, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)
	TBMenu:addBottomBloodSmudge(botBar, 2)

	local topPlayersTitle = UIElement:new({
		parent = topBar,
		pos = { 10, 0 },
		size = { topBar.size.w - 20, topBar.size.h }
	})
	topPlayersTitle:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKETOPRANKEDPLAYERS, nil, nil, FONTS.BIG, nil, 0.65)

	local listElements = {}
	if (#playerRanking == 0) then
		listingHolder:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANKEDTOPEMPTY)
		return
	end
	for _, player in pairs(playerRanking) do
		PlayerInfo.getRankTier(player)
		local playerView = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, playerView)
		local playerViewBG = playerView:addChild({
			pos = { 10, 0 },
			size = { playerView.size.w - 10, playerView.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = { 4, 0 }
		})
		local playerTier = playerViewBG:addChild({
			pos = { 0, 0 },
			size = { playerViewBG.size.h, playerViewBG.size.h },
			bgImage = player.tier.image
		})
		local playerName = playerViewBG:addChild({
			pos = { playerViewBG.size.h + 10, 0 },
			size = { (playerViewBG.size.w - playerViewBG.size.h - 20) / 3 * 2, playerViewBG.size.h }
		})
		playerName:addAdaptedText(true, player.username, nil, nil, nil, LEFTMID)
		if (player.tier.showRank) then
			local playerRank = playerViewBG:addChild({
				pos = { playerName.shift.x + playerName.size.w, 0 },
				size = { playerViewBG.size.w - playerName.shift.x - playerName.size.w - 10, playerName.size.h }
			})
			playerRank:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANK .. " " .. player.rank, nil, nil, nil, RIGHTMID)
		end

		local playerInfoView = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, playerInfoView)
		local playerInfoViewBG = playerInfoView:addChild({
			pos = { 10, 0 },
			size = { playerInfoView.size.w - 10, playerInfoView.size.h - 10 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = { 0, 4 }
		})
		local playerRankTitle = playerInfoViewBG:addChild({
			pos = { 3, 0 },
			size = { playerInfoViewBG.size.w / 3 - 6, playerInfoViewBG.size.h }
		})
		playerRankTitle:addAdaptedText(true, player.tier.title, nil, nil, 4, nil, 0.7)
		local playerGames = playerInfoViewBG:addChild({
			pos = { playerInfoViewBG.size.w / 3 + 3, 0 },
			size = { playerInfoViewBG.size.w / 3 - 6, playerInfoViewBG.size.h }
		})
		playerGames:addAdaptedText(true, player.games .. " " .. TB_MENU_LOCALIZED.MATCHMAKEFIGHTSTOTAL, nil, nil, 4, nil, 0.7)
		local playerWinRatio = playerInfoViewBG:addChild({
			pos = { -playerInfoViewBG.size.w / 3 + 3, 0 },
			size = { playerInfoViewBG.size.w / 3 - 6, playerInfoViewBG.size.h }
		})
		playerWinRatio:addAdaptedText(true, math.floor(player.wins / player.games * 100) .. "% " .. TB_MENU_LOCALIZED.MATCHMAKEWINLOSE, nil, nil, 4, nil, 0.7)
	end
	for i,v in pairs(listElements) do
		v:hide()
	end

	local listingScrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingScrollBar:makeScrollBar(listingHolder, listElements, toReload)
end

function Ranking:refreshRankingTrends(viewElement)
	local loaderHolder = viewElement:addChild({ shift = { viewElement.size.w / 8, viewElement.size.h / 3 }})
	TBMenu:displayLoadingMark(loaderHolder, TB_MENU_LOCALIZED.MATCHMAKEUPDATINGTRENDS)
	Request:queue(fetch_ranking_trends, "ranking_trends", function()
			local response = get_network_response()
			if (not Ranking:parseRankingTrends(response)) then
				viewElement:kill(true)
				viewElement:addChild({ shift = { viewElement.size.w / 8, viewElement.size.h / 3 } }):addAdaptedText(true, TB_MENU_LOCALIZED.ERRORTRYAGAIN)
				TBMenu:addBottomBloodSmudge(viewElement, 1)
				return
			end
			Ranking:showRankingTrendsWithHistory(viewElement)
		end, function()
			viewElement:kill(true)
			viewElement:addChild({ shift = { viewElement.size.w / 8, viewElement.size.h / 3 } }):addAdaptedText(true, TB_MENU_LOCALIZED.ERRORTRYAGAIN)
			TBMenu:addBottomBloodSmudge(viewElement, 1)
		end)
end

function Ranking:refreshRankingToplist(viewElement)
	local loaderHolder = viewElement:addChild({ shift = { viewElement.size.w / 8, viewElement.size.h / 3 }})
	TBMenu:displayLoadingMark(loaderHolder, TB_MENU_LOCALIZED.EVENTSLOADINGTOPPLAYERS)
	Request:queue(fetch_ranking_toplist, "ranking_toplist", function()
			local response = get_network_response()
			local rankingToplist = Ranking:parseRankingData(response)
			Ranking:showGlobalRankToplist(viewElement, rankingToplist)
		end, function()
			viewElement:kill(true)
			viewElement:addChild({ shift = { viewElement.size.w / 8, viewElement.size.h / 3 } }):addAdaptedText(true, TB_MENU_LOCALIZED.ERRORTRYAGAIN)
			TBMenu:addBottomBloodSmudge(viewElement, 1)
		end)
end

function Ranking:showGlobalRanking()
	TBMenu.CurrentSection:kill(true)
	TBMenu:showNavigationBar(Ranking:getNavigationButtons(), true)

	local playerRankingView = UIElement:new({
		parent = TBMenu.CurrentSection,
		pos = { 5, 0 },
		size = { TBMenu.CurrentSection.size.w * 0.65 - 10, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:addBottomBloodSmudge(playerRankingView, 1)
	if (not Ranking.PlayerData or (Ranking.PlayerData.name ~= TB_MENU_PLAYER_INFO.username or Ranking.PlayerData.games ~= TB_MENU_PLAYER_INFO.ranking.wins + TB_MENU_PLAYER_INFO.ranking.loses) or TB_MENU_DEBUG) then
		Ranking.PlayerData = { name = TB_MENU_PLAYER_INFO.username, games = TB_MENU_PLAYER_INFO.ranking.wins + TB_MENU_PLAYER_INFO.ranking.loses }
		Ranking:refreshRankingTrends(playerRankingView)
	else
		Ranking:showRankingTrendsWithHistory(playerRankingView)
	end

	local rankingTopView = UIElement:new({
		parent = TBMenu.CurrentSection,
		pos = { TBMenu.CurrentSection.size.w * 0.65 + 5, 0 },
		size = { TBMenu.CurrentSection.size.w * 0.35 - 10, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	Ranking:refreshRankingToplist(rankingTopView)
end

---@deprecated
---Legacy function to display main ranking screen. Will be removed with future releases.
function Ranking:showRankedLegacy()
	-- TBMenu:clearNavSection()
	-- TBMenu:showNavigationBar(Ranking:getNavigationButtons(), true)

	local rankedButtons = {
		{
			title = "Welcome to Toribash Season 7!",
			image = "../textures/menu/promo/season7.tga",
			ratio = 0.5,
			disableUnload = true,
			action = function() Events:showEventInfo(3) end
		},
		{
			ratio = 0.5,
			title = TB_MENU_LOCALIZED.MATCHMAKEGLOBALRANKING,
			subtitle = TB_MENU_LOCALIZED.MATCHMAKEGLOBALRANKINGDESC,
			action = function() Ranking:showGlobalRanking() end
		},
	}
	local seasonInfo = UIElement:new({
		parent = TBMenu.CurrentSection,
		pos = { 5, 0 },
		size = { TBMenu.CurrentSection.size.w * 0.4 - 10, TBMenu.CurrentSection.size.h / 3 * 2 - 5 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	TBMenu:showHomeButton(seasonInfo, rankedButtons[1])

	local seasonToplist = UIElement:new({
		parent = TBMenu.CurrentSection,
		pos = { 5, seasonInfo.size.h + 10 },
		size = { seasonInfo.size.w, TBMenu.CurrentSection.size.h - seasonInfo.size.h - 15},
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	TBMenu:showHomeButton(seasonToplist, rankedButtons[2], 1)


	local viewElement = UIElement:new({
		parent = TBMenu.CurrentSection,
		pos = { seasonInfo.size.w + 15, 0 },
		size = { (TBMenu.CurrentSection.size.w - seasonInfo.size.w) / 5 * 3 - 20, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:addBottomBloodSmudge(viewElement, 2)

	if (TB_MENU_PLAYER_INFO.data.qi < 500) then
		local scale = viewElement.size.w > viewElement.size.h and viewElement.size.h / 2 or viewElement.size.w / 2
		local scale = scale > 256 and 256 or scale
		local availableBeltIcon = UIElement:new({
			parent = viewElement,
			pos = { (viewElement.size.w - scale) / 2, (viewElement.size.h / 2 - scale) / 2 },
			size = { scale, scale },
			bgImage = "../textures/menu/belts/brown.tga"
		})
		local availableBeltText = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 10, viewElement.size.h / 2 },
			size = { viewElement.size.w * 0.8, viewElement.size.h / 4 }
		})
		availableBeltText:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANKEDBELT, nil, nil, FONTS.BIG, nil, nil, nil, 0.4)
		local purchaseQi = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 20, -viewElement.size.h / 5 },
			size = { viewElement.size.w * 0.9, viewElement.size.h / 6 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		purchaseQi:addMouseHandlers(nil, function()
				TBMenu:openMenu(6)
				Torishop:showStoreSection(TBMenu.CurrentSection, nil, nil, 1612)
			end)
		TBMenu:showTextWithImage(purchaseQi, TB_MENU_LOCALIZED.STOREGETMORE .. " Qi " .. TB_MENU_LOCALIZED.STOREVIEWIN2, FONTS.MEDIUM, 64, "../textures/store/items/1612.tga")
	else
		local mmRankedTitle = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 20, viewElement.size.h / 100 },
			size = { viewElement.size.w * 0.9, viewElement.size.h / 10 - viewElement.size.h / 50 }
		})
		mmRankedTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANKEDMODE, nil, nil, FONTS.BIG)
		if (TB_MENU_PLAYER_INFO.ranking.elo) then
			local mmRankedInfo = UIElement:new({
				parent = viewElement,
				pos = { 10, mmRankedTitle.size.h + mmRankedTitle.shift.y },
				size = { viewElement.size.w - 20, TB_MENU_PLAYER_INFO.ranking.nextTierElo > 0 and viewElement.size.h / 16 * 7 or viewElement.size.h / 2 }
			})
			local iconScale = mmRankedInfo.size.w / 2 < mmRankedInfo.size.h and mmRankedInfo.size.w / 2 or mmRankedInfo.size.h
			if (iconScale > 64) then
				local mmRankedIcon = UIElement:new({
					parent = mmRankedInfo,
					pos = { 0, (mmRankedInfo.size.h - iconScale) / 2 },
					size = { iconScale, iconScale },
					bgImage = TB_MENU_PLAYER_INFO.ranking.image
				})
			else
				iconScale = 0
			end

			local mmRankedInfoText = UIElement:new({
				parent = mmRankedInfo,
				pos = { iconScale, 0 },
				size = { mmRankedInfo.size.w - iconScale, mmRankedInfo.size.h }
			})
			local details = 3
			local mmRankedInfoTier = UIElement:new({
				parent = mmRankedInfoText,
				pos = { 0, 0 },
				size = { mmRankedInfoText.size.w, mmRankedInfoText.size.h / details }
			})
			mmRankedInfoTier:addAdaptedText(true, TB_MENU_PLAYER_INFO.ranking.title, nil, nil, FONTS.BIG, CENTERBOT, 0.6)
			if (TB_MENU_PLAYER_INFO.ranking.rank) then
				local mmRankedInfoRank = UIElement:new({
					parent = mmRankedInfoText,
					pos = { 0, mmRankedInfoText.size.h / details * (details - 2) },
					size = { mmRankedInfoText.size.w, mmRankedInfoText.size.h / details }
				})
				mmRankedInfoRank:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANK .. " " .. TB_MENU_PLAYER_INFO.ranking.rank .. "\n(" .. string.format("%4.2f", TB_MENU_PLAYER_INFO.ranking.elo) .. " " .. TB_MENU_LOCALIZED.MATCHMAKEELO .. ")")
			else
				local mmRankedInfoElo = UIElement:new({
					parent = mmRankedInfoText,
					pos = { 0, mmRankedInfoText.size.h / details * (details - 2) },
					size = { mmRankedInfoText.size.w, mmRankedInfoText.size.h / details }
				})
				mmRankedInfoElo:addAdaptedText(true, string.format("%4.2f", TB_MENU_PLAYER_INFO.ranking.elo) .. " " .. TB_MENU_LOCALIZED.MATCHMAKEELO)
			end
			local mmRankedInfoGames = UIElement:new({
				parent = mmRankedInfoText,
				pos = { 0, mmRankedInfoText.size.h / details * (details - 1) },
				size = { mmRankedInfoText.size.w, mmRankedInfoText.size.h / details }
			})
			local games = TB_MENU_PLAYER_INFO.ranking.wins + TB_MENU_PLAYER_INFO.ranking.loses
			local winrate = games ~= 0 and math.floor(TB_MENU_PLAYER_INFO.ranking.wins / games * 100 + 0.5) or nil
			local gameInfoStr = games .. " " .. TB_MENU_LOCALIZED.MATCHMAKEFIGHTSTOTAL
			gameInfoStr = winrate and (gameInfoStr .. "\n" .. winrate .. "% " .. TB_MENU_LOCALIZED.MATCHMAKEWINRATE) or gameInfoStr
			mmRankedInfoGames:addAdaptedText(true, gameInfoStr, nil, nil, 4, CENTER, 0.7)
		end

		if (TB_MENU_PLAYER_INFO.ranking.nextTierElo > 0) then
			local gamesHolder = UIElement:new({
				parent = viewElement,
				pos = { 0, mmRankedTitle.size.h + mmRankedTitle.shift.y + viewElement.size.h / 16 * 7 },
				size = { viewElement.size.w, viewElement.size.h / 2 - viewElement.size.h / 16 * 7 }
			})
			local gamesToNextTier = UIElement:new({
				parent = gamesHolder,
				pos = { 30, 0 },
				size = { gamesHolder.size.w - 30, gamesHolder.size.h}
			})

			local bestAverageOpponent = 1.01 * (TB_MENU_PLAYER_INFO.ranking.elo + 1600) / 2
			local worstAverageOpponent = (1600 / TB_MENU_PLAYER_INFO.ranking.elo) * (TB_MENU_PLAYER_INFO.ranking.elo + 1600) / 2

			local minGamesToNextTier = math.ceil((TB_MENU_PLAYER_INFO.ranking.nextTierElo - TB_MENU_PLAYER_INFO.ranking.elo) / (Ranking.EloFactor * (1 - (1 / ( 1 + (math.pow(TB_MENU_PLAYER_INFO.ranking.elo, (bestAverageOpponent - TB_MENU_PLAYER_INFO.ranking.elo) / ELO_DIVISOR)))))))
			local maxGamesToNextTier = math.ceil((TB_MENU_PLAYER_INFO.ranking.nextTierElo - TB_MENU_PLAYER_INFO.ranking.elo) / (Ranking.EloFactor * (1 - (1 / ( 1 + (math.pow(TB_MENU_PLAYER_INFO.ranking.elo, (worstAverageOpponent - TB_MENU_PLAYER_INFO.ranking.elo) / ELO_DIVISOR)))))))

			local winsToNextTierString = (minGamesToNextTier == maxGamesToNextTier and minGamesToNextTier or (minGamesToNextTier .. " - " .. maxGamesToNextTier)) .. " " .. TB_MENU_LOCALIZED.MATCHMAKEWINSTONEXTTIER
			gamesToNextTier:addCustomDisplay(false, function()
					gamesToNextTier:uiText(winsToNextTierString)
				end)

			local signScale = gamesToNextTier.size.h > 30 and 30 or gamesToNextTier.size.h
			local maxLen = 0
			for i,v in pairs(gamesToNextTier.dispstr) do
				if (maxLen < get_string_length(v, FONTS.MEDIUM)) then
					maxLen = get_string_length(v, FONTS.MEDIUM)
				end
			end
			local gamesToNextTierInfo = UIElement:new({
				parent = gamesHolder,
				pos = { (gamesHolder.size.w - maxLen) / 2 - 30, (gamesHolder.size.h - signScale) / 2 },
				size = { signScale, signScale },
				interactive = true,
				bgColor = { 0, 0, 0, 0.2 },
				hoverColor = { 1, 1, 1, 0.2 },
				pressedColor = { 1, 1, 1, 0.2 },
				shapeType = ROUNDED,
				rounded = signScale
			})
			TBMenu:displayHelpPopup(gamesToNextTierInfo, TB_MENU_LOCALIZED.MATCHMAKEELOGAININFO)
		end

		local rankedPlayers = UIElement:new({
			parent = viewElement,
			pos = { 10, -viewElement.size.h / 3 },
			size = { viewElement.size.w - 20, viewElement.size.h / 12 }
		})
		rankedPlayers:addCustomDisplay(false, function()
				if (TB_MATCHMAKER_INFO.ranked == 0 or TB_MATCHMAKER_INFO.ranked > 65535) then
					rankedPlayers:uiText(TB_MENU_LOCALIZED.MATCHMAKENOPLAYERS)
				elseif (TB_MATCHMAKER_INFO.ranked == 1) then
					rankedPlayers:uiText(TB_MATCHMAKER_INFO.ranked .. " " .. TB_MENU_LOCALIZED.MATCHMAKEPLAYERSEARCHING)
				else
					rankedPlayers:uiText(TB_MATCHMAKER_INFO.ranked .. " " .. TB_MENU_LOCALIZED.MATCHMAKEPLAYERSSEARCHING)
				end
			end)
		local rankedSearchEnabled = get_world_state().game_type == 0 and true or false
		local rankedSearchButton = UIElement:new({
			parent = viewElement,
			pos = { 10, -viewElement.size.h / 4 },
			size = { viewElement.size.w - 20, viewElement.size.h / 9 },
			bgColor = rankedSearchEnabled and TB_MENU_DEFAULT_DARKER_COLOR or { 0.5, 0.5, 0.5, 0.9 },
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = rankedSearchEnabled,
			hoverSound = 31,
			downSound = 50
		})
		local rankedSearchProgress = UIElement:new({
			parent = viewElement,
			pos = { rankedPlayers.shift.x, rankedPlayers.shift.y },
			size = { rankedPlayers.size.w, rankedPlayers.size.h },
		})
		local progress, rotation = 0, 0
		rankedSearchProgress:addCustomDisplay(false, function()
				rankedSearchProgress:uiText(TB_MENU_LOCALIZED.MATCHMAKESEARCHING)
				set_color(1,1,1,0.8)
				draw_disk(rankedSearchProgress.pos.x + rankedSearchProgress.size.w / 2 - get_string_length(TB_MENU_LOCALIZED.MATCHMAKESEARCHING, FONTS.MEDIUM) / 2 - rankedSearchProgress.size.h / 3 * 2, rankedSearchProgress.pos.y + rankedSearchProgress.size.h / 2, rankedSearchProgress.size.h / 5, rankedSearchProgress.size.h / 3, 500, 1, rotation, progress, 0)
				progress = progress == 360 and -360 or progress + 5
				rotation = rotation + 3
			end)
		local rankedSearchButtonStop = UIElement:new({
			parent = viewElement,
			pos = { rankedSearchButton.shift.x, rankedSearchButton.shift.y },
			size = { rankedSearchButton.size.w, rankedSearchButton.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
			hoverSound = 31
		})
		if (TB_MATCHMAKER_SEARCHSTATUS == 1) then
			rankedSearchButton:hide()
			rankedPlayers:hide()
		else
			rankedSearchProgress:hide()
			rankedSearchButtonStop:hide()
		end
		if (rankedSearchEnabled) then
			rankedSearchButton:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKESEARCH, nil, nil, FONTS.BIG, nil, 0.65)
		else
			rankedSearchButton:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKECANTSEARCH)
		end
		rankedSearchButton:addMouseHandlers(nil, function()
				UIElement:runCmd("matchmake ranked continue")
				set_discord_rpc(TB_MENU_LOCALIZED.MATCHMAKERANKEDMODE, TB_MENU_LOCALIZED.DISCORDRPCMATCHMAKING)
				TB_MATCHMAKER_SEARCHSTATUS = 1
				Ranking:getMatchmaker()
				progress = 0
				rankedSearchButton:hide()
				rankedSearchProgress:show()
				rankedPlayers:hide()
				rankedSearchButtonStop:show()
			end, nil)
		rankedSearchButtonStop:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKESTOPSEARCH, nil, nil, FONTS.BIG, nil, 0.65)
		rankedSearchButtonStop:addMouseHandlers(nil, function()
				UIElement:runCmd("matchmake on 8 0 1")
				set_discord_rpc("", "")
				TB_MATCHMAKER_SEARCHSTATUS = nil
				Ranking:getMatchmaker()
				rankedSearchButton:show()
				rankedPlayers:show()
				rankedSearchProgress:hide()
				rankedSearchButtonStop:hide()
			end)

		RoomList.RefreshIfNeeded()
		local roomJoinButton = UIElement:new({
			parent = viewElement,
			pos = { rankedSearchButton.shift.x, -viewElement.size.h / 8 },
			size = { rankedSearchButton.size.w, rankedSearchButton.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		roomJoinButton:addAdaptedText(false, TB_MENU_LOCALIZED.FRIENDSLISTJOINROOM, nil, nil, FONTS.BIG, nil, 0.65)
		roomJoinButton:addMouseHandlers(nil, function()
				UIElement:runCmd("matchmake on 8 0 1")
				set_discord_rpc("", "")
				TB_MATCHMAKER_SEARCHSTATUS = nil
				local players = RoomList.GetPlayers()
				local rooms = { "ranked%d" }
				local roomsOnline = {}
				for i, online in pairs(players) do
					if (online.room:find(rooms[1])) then
						roomsOnline[online.room] = roomsOnline[online.room] or { players = 0 }
						roomsOnline[online.room].players = roomsOnline[online.room].players + 1
					end
				end
				for i, room in pairs(roomsOnline) do
					room.name = i
				end
				roomsOnline = UIElement:qsort(roomsOnline, "players", true)
				if (#roomsOnline > 0) then
					for i, room in pairs(roomsOnline) do
						if (room.players > 1 and room.players < 5) then
							UIElement:runCmd("jo " .. room.name)
							close_menu()
							return
						end
					end
					UIElement:runCmd("jo " .. roomsOnline[1].name)
					close_menu()
					return
				else
					UIElement:runCmd("jo ranked1")
					close_menu()
					return
				end
			end)
	end

	local quests = Quests:getQuests() or {}
	local rankedQuestData = nil
	for i,v in pairs(quests) do
		if (v.ranked) then
			rankedQuestData = v
			break
		end
	end

	local rankedQuest = UIElement:new({
		parent = TBMenu.CurrentSection,
		pos = { viewElement.shift.x + viewElement.size.w + 10, 0 },
		size = { (TBMenu.CurrentSection.size.w - viewElement.shift.x - viewElement.size.w) - 15, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local bloodSmudge = TBMenu:addBottomBloodSmudge(rankedQuest, 3)
	if (not rankedQuestData) then
		local rankedQuestText = UIElement:new({
			parent = rankedQuest,
			pos = { 10, 10 },
			size = { rankedQuest.size.w - 20, rankedQuest.size.h - 20 }
		})
		rankedQuestText:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKENORANKEDQUEST)
		return
	end
	Quests:showQuest(rankedQuest, rankedQuestData, bloodSmudge, function()
			rankedQuest:kill(true)
			bloodSmudge = TBMenu:addBottomBloodSmudge(rankedQuest, 3)
			local questsView = UIElement:new({
				parent = rankedQuest,
				pos = { rankedQuest.size.w / 10, rankedQuest.size.h / 7 * 3 },
				size = { rankedQuest.size.w * 0.8, rankedQuest.size.h / 7 },
				shapeType = ROUNDED,
				rounded = 3,
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			questsView:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKEVIEWQUESTS)
			questsView:addMouseHandlers(nil, function()
					TBMenu:openMenu(101)
				end)
		end)
end
