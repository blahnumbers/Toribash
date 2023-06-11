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
	---@field modid integer
	---@field rank integer
	---@field elo number
	---@field wins integer
	---@field loses integer

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

	---@class RankingGameStat
	---@field seasonal integer
	---@field weekly integer

	---@class RankingGameStats
	---@field games RankingGameStat
	---@field score RankingGameStat
	---@field dismembers RankingGameStat
	---@field decaps RankingGameStat
	---@field tc RankingGameStat

	---**Toribash Ranking manager class**
	---
	---**Version 5.60**
	---* New UI to accomodate for repeatable ranking seasons
	---* Game stat rankings and mod rankings
	---* Fetch ranking config (tiers, time left, etc) from game server on class load
	---* **RankingInternal** class for ranking private functions
	---@class Ranking
	---@field EloFactor number Additional Elo scaling factor that we may want to apply to any Elo gain during the season. Typically this would stay at `1`.
	---@field EloDivisor number Internal value used to retrieve games to next tier estimate
	---@field PlayerData RankingPlayerData Information about current user's ranking
	---@field PlayerTrends RankingTrendEntry[] Table with ranking trends history for the player
	---@field PlayerModRanking RankingPlayerModData[] Per-mod ranking information for currently logged in user
	---@field RankingTiers RankingTier[] Information about ranking tiers available during current ranking period
	---@field QualificationMatches integer How many games should the user play to receive a real ranking tier
	---@field QualifyingTier RankingTier Placeholder tier for players who haven't yet qualified for a ranking tier
	---@field TimeLeft integer Time left until ranking period is over
	---@field QiRequirement integer Qi requirement to participate in Toribash ranking
	---@field PlayerGameStats RankingGameStats Table containing player's game stats
	---@field LastBalance integer Current user's last TC balance, used for querying game stats updates
	---@field ToplistStalePeriod integer Time in seconds before global top list is considered outdated
	Ranking = {
		EloFactor = 1,
		EloDivisor = 400,
		RankingTiers = {
			{
				title = "Undefined",
				showRank = false,
				maxElo = 100000,
				minElo = 0,
				image = "../textures/menu/ranking/silver.tga"
			}
		},
		QualificationMatches = 10,
		QualifyingTier = {
			title = "Qualifying",
			image = "../textures/menu/ranking/silver.tga",
			showRank = false
		},
		TimeLeft = 0,
		QiRequirement = 100,
		ToplistStalePeriod = 300,
		ver = 5.60
	}
	Ranking.__index = Ranking
	setmetatable({}, Ranking)
end

---Helper class for **Ranking** manager
---@class RankingInternal
local RankingInternal = {}
setmetatable({}, RankingInternal)

---Initializes **Ranking** class by requesting config data from web server
function RankingInternal.Init()
	local lastTimeleft = Ranking.TimeLeft
	---@type RankingTier[]
	local rankingTiers = {}
	Request:queue(function() lastTimeleft = os.time() download_server_info("ranking_config") end, "rankingInitConfigurate", function()
			local response = get_network_response()
			local mode = 0
			for ln in response:gmatch("[^\n]+\n?") do
				pcall(function()
					if (ln:find("^#")) then
						mode = 1
					elseif (mode == 0) then
						local val = ln:gsub("%D", "")
						if (ln:find("^QualifyGames %d")) then
							Ranking.QualificationMatches = tonumber(val) or Ranking.QualificationMatches
						elseif (ln:find("^QiRequirement %d")) then
							Ranking.QiRequirement = tonumber(val) or Ranking.QiRequirement
						elseif (ln:find("^TimeLeft %d")) then
							Ranking.TimeLeft = lastTimeleft + (tonumber(val) or 0)
						end
					else
						local _, segments = ln:gsub("([^\t]*)\t", "")
						local data_stream = { ln:match(("([^\t]+)\t*"):rep(segments)) }
						local min_elo = tonumber(data_stream[2]) or 0
						local texture, lvl = string.gsub(data_stream[1], " ?I", "")
						texture = "../textures/menu/ranking/" .. string.lower(string.gsub(texture, "%W", "")) .. (lvl > 0 and lvl or "") .. ".tga"
						if (#rankingTiers > 0) then
							rankingTiers[#rankingTiers].maxElo = min_elo
						end
						table.insert(rankingTiers, {
							title = data_stream[1],
							showRank = data_stream[3] == '1',
							maxElo = 100000,
							minElo = min_elo,
							image = texture
						})
					end
				end)
			end

			if (#rankingTiers > 0) then
				Ranking.RankingTiers = rankingTiers
			end
			if (lastTimeleft ~= Ranking.TimeLeft) then
				TBMenu:reloadNavigationIfNeeded()
				if (Ranking.ActiveOverlay and not Ranking.ActiveOverlay.destroyed) then
					Ranking.ActiveOverlay:reload()
				end
			end
			if (TB_MENU_PLAYER_INFO and TB_MENU_PLAYER_INFO.getRanking) then
				TB_MENU_PLAYER_INFO:getRanking()
			end
			---@diagnostic disable-next-line: undefined-global
			set_ranking_qualifygames(Ranking.QualificationMatches)
		end)
end

---Returns whether ranking data update is required
---@return boolean
function Ranking.IsUpdateRequired()
	if (Ranking.PlayerData == nil) then
		Ranking.PlayerData = {
			name = TB_MENU_PLAYER_INFO.username,
			games = TB_MENU_PLAYER_INFO.ranking.wins + TB_MENU_PLAYER_INFO.ranking.loses
		}
		return true
	end
	return Ranking.PlayerData.name ~= TB_MENU_PLAYER_INFO.username or Ranking.PlayerData.games ~= TB_MENU_PLAYER_INFO.ranking.wins + TB_MENU_PLAYER_INFO.ranking.loses
end

---Parses network response containing top players' ranking information
---@param data string
---@return RankingTopPlayer[]
function RankingInternal.ParseMainData(data)
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
function RankingInternal.ParseTrends(data)
	Ranking.PlayerTrends = {}
	Ranking.PlayerModRanking = {}
	local minElo, topElo = 10000, 0
	local mods = true

	for ln in data:gmatch("[^\n]+\n?") do
		if (ln:find("^#NO DATA FOUND")) then
			-- User hasn't played ranked yet, exit with empty data
			return
		end
		if (ln:find("^#ELO")) then
			mods = false
		end
		if (not ln:find("^#")) then
			if (mods) then
				local _, segments = ln:gsub("([^\t]*)\t", "")
				local data_stream = { ln:match(("([^\t]+)\t*"):rep(segments)) }
				---@type RankingPlayerModData
				local info = {
					name = data_stream[1],
					rank = tonumber(data_stream[2]) or 0,
					elo = tonumber(data_stream[3]) or 0,
					modid = tonumber(data_stream[4]) or 0,
					wins = tonumber(data_stream[5]) or 0,
					loses = tonumber(data_stream[6]) or 0
				}
				table.insert(Ranking.PlayerModRanking, info)
			else
				local _, segments = ln:gsub("([^\t]*)\t", "")
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
end

---Parses user game stats data retrieved from web server
---@param data string
function RankingInternal.ParseGameStats(data)
	Ranking.PlayerGameStats = {}
	for ln in data:gmatch("[^\n]+\n?") do
		if (ln:find("^INVALID USER")) then
			---Invalid user specified, exit
			return
		end
		if (not ln:find("^#")) then
			local _, segments = ln:gsub("([^\t]*)\t", "")
			local data_stream = { ln:match(("([^\t]+)\t*"):rep(segments)) }
			Ranking.PlayerGameStats[data_stream[2]] = Ranking.PlayerGameStats[data_stream[2]] or { }
			if (data_stream[1] == '1') then
				Ranking.PlayerGameStats[data_stream[2]].weekly = tonumber(data_stream[3]) or 0
			elseif (data_stream[1] == '0') then
				Ranking.PlayerGameStats[data_stream[2]].seasonal = tonumber(data_stream[3]) or 0
			end
		end
	end
end

---@class RankingGameStatToplistEntry[]
---@field rank integer
---@field user string
---@field result integer

---@class RankingGameStatToplist
---@field weekly RankingGameStatToplistEntry[]
---@field seasonal RankingGameStatToplistEntry[]

---Parses game stats toplist data retrieved from web server
---@param data string
---@return RankingGameStatToplist
function RankingInternal.ParseGameStatsToplist(data)
	---@type RankingGameStatToplist
	local toplist = {
		weekly = { },
		seasonal = { }
	}
	for ln in data:gmatch("[^\n]+\n?") do
		if (not ln:find("^#")) then
			local _, segments = ln:gsub("([^\t]*)\t", "")
			local data_stream = { ln:match(("([^\t]+)\t*"):rep(segments)) }
			---@type RankingGameStatToplistEntry
			local entry = {
				rank = tonumber(data_stream[2]) or 0,
				user = data_stream[3],
				result = tonumber(data_stream[4]) or 0
			}
			if (data_stream[5] == '7') then
				table.insert(toplist.weekly, entry)
			else
				table.insert(toplist.seasonal, entry)
			end
		end
	end
	if (#toplist.seasonal == 0 and #toplist.weekly ~= 0) then
		---This will happen on day 7 of the ranking season, just use weekly results
		toplist.seasonal = toplist.weekly
	end
	return toplist
end

---Displays player ranking trends in a UIElement viewport
---@param viewElement UIElement
function Ranking.ShowTrends(viewElement)
	if (#Ranking.PlayerTrends < 4) then
		viewElement:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKEMOREGAMESREQUIREDFORTRENDS)
	else
		local trendsChartView = viewElement:addChild({
			pos = { 70, 10 },
			size = { viewElement.size.w - 90, viewElement.size.h - 40 }
		})
		local eloScale = (Ranking.PlayerTrends.topElo - Ranking.PlayerTrends.minElo) / trendsChartView.size.h
		local width = trendsChartView.size.w / (#Ranking.PlayerTrends - 1)
		local lineLeft = viewElement:addChild({
			pos = { trendsChartView.shift.x, trendsChartView.shift.y },
			size = { 1, trendsChartView.size.h },
			bgColor = { 1, 1, 1, 0.4 }
		})
		local legendLeft = lineLeft:addChild({
			pos = { -trendsChartView.shift.x + 10, -lineLeft.size.h - 9 },
			size = { trendsChartView.shift.x - 20, lineLeft.size.h + 20 }
		})
		legendLeft:addAdaptedText(true, TB_MENU_LOCALIZED.WORDELO, nil, nil, 4, RIGHTMID, 0.8)
		legendLeft:addChild({}):addAdaptedText(true, Ranking.PlayerTrends.topElo, nil, nil, 4, RIGHT, 0.6)
		legendLeft:addChild({}):addAdaptedText(true, Ranking.PlayerTrends.minElo, nil, nil, 4, RIGHTBOT, 0.6)

		local lineBot = viewElement:addChild({
			pos = { trendsChartView.shift.x, trendsChartView.shift.y + trendsChartView.size.h },
			size = { trendsChartView.size.w, 1 },
			bgColor = { 1, 1, 1, 0.4 }
		})
		local legendBot = lineBot:addChild({
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
				size = { 24, 24 },
				shapeType = ROUNDED,
				rounded = 12,
				bgColor = { 0, 0, 0, 0.01 },
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				interactive = true
			})
			local targetEloStatic = targetElo:addChild({
				shift = { 8, 8 },
				bgColor = UICOLORWHITE
			}, true)
			targetElo:moveTo(-targetElo.size.w / 2, -targetElo.size.h / 2, true)
			local popup = TBMenu:displayPopup(targetElo, elo .. " " .. TB_MENU_LOCALIZED.WORDELO)
			popup:moveTo(-popup.size.w / 2 - 12, -popup.size.h * 1.5)
			if (not Ranking.PlayerTrends[i + 2]) then
				local targetEloFinal = trendsChartView:addChild({
					pos = { linePart.size.w, linePart.size.h },
					size = { 24, 24 },
					shapeType = ROUNDED,
					rounded = 12,
					bgColor = { 0, 0, 0, 0.01 },
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					interactive = true
				})
				local targetEloStatic = targetEloFinal:addChild({
					shift = { 8, 8 },
					bgColor = UICOLORWHITE
				}, true)
				targetEloFinal:moveTo(-targetEloFinal.size.w / 2, -targetEloFinal.size.h / 2, true)
				local popup = TBMenu:displayPopup(targetEloFinal, elo .. " " .. TB_MENU_LOCALIZED.WORDELO)
				popup:moveTo(-popup.size.w / 2 - 12, -popup.size.h * 1.5)
			end
			linePart:addCustomDisplay(true, function()
					set_color(1, 1, 1, 0.6)
					draw_line(linePart.pos.x, linePart.pos.y, trendsChartView.pos.x + linePart.size.w, trendsChartView.pos.y + linePart.size.h, 2)
				end)
		end
	end
end

---Displays player's ranking information with trends in a UIElement viewport
---@param viewElement UIElement
function Ranking:showRankingTrendsWithHistory(viewElement)
	viewElement:kill(true)
	viewElement.bgColor = { 0, 0, 0, 0 }

	local userTrendsView = viewElement:addChild({
		size = { viewElement.size.w, viewElement.size.h / 3 - 5 }
	})
	local rankTrendView = userTrendsView:addChild({
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
end

---Displays top global players in a specified UIElement viewport
---@param viewElement UIElement
---@param playerRanking RankingTopPlayer[]
---@param title string
---@param globalElo ?boolean
---@param playerData ?PlayerInfoRanking
function Ranking.ShowToplist(viewElement, playerRanking, title, globalElo, playerData)
	viewElement:kill(true)

	local elementHeight = 36
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(viewElement, globalElo and 50 or 70, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

	if (globalElo) then
		TBMenu:addBottomBloodSmudge(botBar, 2)
		topBar:addChild({ shift = { 10, 0 } }):addAdaptedText(true, title, nil, nil, FONTS.BIG, nil, 0.55, nil, 0.1)
	else
		topBar.shapeType = viewElement.shapeType
		botBar.shapeType = viewElement.shapeType
		topBar:setRounded({ viewElement.rounded, 0 })
		botBar:setRounded({ 0, viewElement.rounded })

		local quitButton = topBar:addChild({
			pos = { -50, 10 },
			size = { 40, 40 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
			shapeType = ROUNDED,
			rounded = 4
		})
		quitButton:addChild({
			shift = { 2, 2 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		quitButton:addMouseHandlers(nil, function()
				if (Ranking.ActiveOverlay) then
					Ranking.ActiveOverlay:kill()
				end
			end)

		topBar:addChild({
			pos = { 10, 4 },
			size = { topBar.size.w - 70, topBar.size.h - 8 }
		}):addAdaptedText(true, title, nil, nil, FONTS.BIG, LEFTMID, 0.55, nil, 0.1)
	end

	if (#playerRanking == 0) then
		listingHolder:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANKEDTOPEMPTY)
		return
	end

	local rankingDisplay = table.clone(playerRanking)
	if (playerData) then
		local isAdded = false
		for _, v in pairs(rankingDisplay) do
			if (v.username == TB_MENU_PLAYER_INFO.username) then
				v.isUser = true
				isAdded = true
				break
			end
		end
		if (not isAdded) then
			table.insert(rankingDisplay, {
				username = TB_MENU_PLAYER_INFO.username,
				wins = playerData.wins,
				loses = playerData.loses,
				games = playerData.wins + playerData.loses,
				elo = playerData.elo,
				rank = playerData.rank,
				isUser = true
			})
		end
	end

	local listElements = {}
	for _, player in pairs(rankingDisplay) do
		if (globalElo) then
			PlayerInfo.getRankTier(player)
		end
		local playerView = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, playerView)
		local playerViewBG = playerView:addChild({
			pos = { 10, 2 },
			size = { playerView.size.w - 10, playerView.size.h - 2 },
			---@diagnostic disable-next-line: undefined-field
			bgColor = player.isUser and TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS or TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = { 4, 0 }
		})
		local imageShift = 10
		if (globalElo) then
			local playerTierTop = playerViewBG:addChild({
				pos = { 0, 0 },
				size = { playerViewBG.size.h * 2, playerViewBG.size.h },
				bgImage = player.tier.image,
				imageAtlas = true,
				atlas = {
					x = 0, y = 0,
					w = 256, h = 128
				}
			})
			imageShift = playerTierTop.size.w + playerTierTop.shift.x
		end
		local playerName = playerViewBG:addChild({
			pos = { imageShift, 0 },
			size = { (playerViewBG.size.w - imageShift) / 3 * 2 - 5, playerViewBG.size.h - 2 }
		})
		playerName:addAdaptedText(true, player.username, nil, nil, nil, LEFTBOT)
		if (not globalElo or player.tier.showRank) then
			local playerRank = playerViewBG:addChild({
				pos = { playerName.shift.x + playerName.size.w + 5, playerName.shift.y },
				size = { playerViewBG.size.w - playerName.shift.x - playerName.size.w - 15, playerName.size.h }
			})
			playerRank:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANK .. " " .. player.rank, nil, nil, nil, RIGHTBOT)
		end

		local playerInfoView = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, playerInfoView)
		local playerInfoViewBG = playerInfoView:addChild({
			pos = { 10, 0 },
			size = { playerInfoView.size.w - 10, playerInfoView.size.h - 2 },
			---@diagnostic disable-next-line: undefined-field
			bgColor = player.isUser and TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS or TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = { 0, 4 }
		})
		if (globalElo) then
			playerInfoViewBG:addChild({
				pos = { 0, 0 },
				size = { playerViewBG.size.h * 2, playerViewBG.size.h },
				bgImage = player.tier.image,
				imageAtlas = true,
				atlas = {
					x = 0, y = 128,
					w = 256, h = 128
				}
			})
			local playerRankTitle = playerInfoViewBG:addChild({
				pos = { imageShift, 2 },
				size = { (playerInfoViewBG.size.w - imageShift) * 0.3, playerInfoViewBG.size.h }
			})
			playerRankTitle:addAdaptedText(true, player.tier.title, nil, nil, 4, LEFT, 0.7)
			local playerGames = playerInfoViewBG:addChild({
				pos = { playerRankTitle.size.w + playerRankTitle.shift.x, playerRankTitle.shift.y + 1 },
				size = { playerInfoViewBG.size.w - imageShift - playerRankTitle.size.w - 10, playerRankTitle.size.h - 2 }
			})
			playerGames:addAdaptedText(false, player.games .. " " .. TB_MENU_LOCALIZED.WORDGAMES .. ", " .. math.round(player.wins / player.games * 100) .. "% " .. TB_MENU_LOCALIZED.MATCHMAKEWINRATE, nil, nil, 4, RIGHT, 0.6)
		else
			playerInfoViewBG:addChild({ shift = { 10, 2 } }):addAdaptedText(false, player.games .. " " .. TB_MENU_LOCALIZED.WORDGAMES .. ", " .. math.round(player.wins / player.games * 100) .. "% " .. TB_MENU_LOCALIZED.MATCHMAKEWINRATE, nil, nil, 4, RIGHT, 0.6)
		end
	end
	for _, v in pairs(listElements) do
		v:hide()
	end

	local listingScrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingScrollBar:makeScrollBar(listingHolder, listElements, toReload, nil, nil, not globalElo)
end

---Queues ranking trends data update and displays a corresponding screen
---@param viewElement UIElement
function Ranking:refreshRankingTrends(viewElement)
	local loaderHolder = viewElement:addChild({ shift = { viewElement.size.w / 8, viewElement.size.h / 3 }})
	TBMenu:displayLoadingMark(loaderHolder, TB_MENU_LOCALIZED.MATCHMAKEUPDATINGTRENDS)
	Request:queue(fetch_ranking_trends, "ranking_trends", function()
			RankingInternal.ParseTrends(get_network_response())
			if (loaderHolder == nil or loaderHolder.destroyed) then return end

			self.ShowTrends(viewElement)
		end, function()
			if (loaderHolder == nil or loaderHolder.destroyed) then return end

			viewElement:kill(true)
			viewElement:addChild({ shift = { viewElement.size.w / 8, viewElement.size.h / 3 } }):addAdaptedText(true, TB_MENU_LOCALIZED.ERRORTRYAGAIN)
			TBMenu:addBottomBloodSmudge(viewElement, 1)
		end)
end

---Queues global ranking toplist data update and displays a corresponding screen
---@param viewElement UIElement
---@param modid integer
---@param title string
---@param userRanking PlayerInfoRanking
---@overload fun(self: Ranking, viewElement:UIElement)
function Ranking:refreshRankingToplist(viewElement, modid, title, userRanking)
	if (modid ~= nil or (self.EloRanking == nil or self.EloRankingTimestamp == nil or os.time() - self.EloRankingTimestamp > self.ToplistStalePeriod)) then
		local loaderHolder = viewElement:addChild({ shift = { viewElement.size.w / 8, viewElement.size.h / 3 }})
		TBMenu:displayLoadingMark(loaderHolder, TB_MENU_LOCALIZED.EVENTSLOADINGTOPPLAYERS)
		Request:queue(function() fetch_ranking_toplist(modid) end, "ranking_toplist" .. tostring(modid), function()
				if (loaderHolder == nil or loaderHolder.destroyed) then return end

				local ranking = RankingInternal.ParseMainData(get_network_response())
				if (modid == nil) then
					self.EloRanking = ranking
					self.EloRankingTimestamp = os.time()
					self.ShowToplist(viewElement, self.EloRanking, TB_MENU_LOCALIZED.MATCHMAKETOPRANKEDPLAYERS, true, TB_MENU_PLAYER_INFO.ranking)
				else
					self.ShowToplist(viewElement, ranking, tostring(title), false, userRanking)
				end
			end, function()
				if (loaderHolder == nil or loaderHolder.destroyed) then return end

				viewElement:kill(true)
				viewElement:addChild({ shift = { viewElement.size.w / 8, viewElement.size.h / 3 } }):addAdaptedText(true, TB_MENU_LOCALIZED.ERRORTRYAGAIN)
				TBMenu:addBottomBloodSmudge(viewElement, 1)
			end)
	else
		self.ShowToplist(viewElement, self.EloRanking, TB_MENU_LOCALIZED.MATCHMAKETOPRANKEDPLAYERS, true, TB_MENU_PLAYER_INFO.ranking)
	end
end

---Displays user's trends in a viewport
function Ranking.ShowUserTrends()
	Ranking.ActiveOverlay = TBMenu:spawnWindowOverlay()
	local overlayKillAction = Ranking.ActiveOverlay.killAction
	Ranking.ActiveOverlay.killAction = function() overlayKillAction() Ranking.ActiveOverlay = nil end

	local viewWidth = math.clamp(WIN_W * 0.65, 800, WIN_W * 0.8)
	local viewHeight = math.clamp(WIN_H * 0.5, 500, WIN_H - TBMenu.UserBar.size.h * 2 - 40)
	local trendsMainView = Ranking.ActiveOverlay:addChild({
		shift = { (WIN_W - viewWidth) / 2, (WIN_H - viewHeight) / 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local trendsTopBar = trendsMainView:addChild({
		pos = { 10, 10 },
		size = { trendsMainView.size.w - 20, 40 }
	})
	local quitButton = trendsTopBar:addChild({
		pos = { -trendsTopBar.size.h, 0 },
		size = { trendsTopBar.size.h, trendsTopBar.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	quitButton:addChild({
		shift = { 2, 2 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})
	quitButton:addMouseUpHandler(function() Ranking.ActiveOverlay:kill() end)
	trendsTopBar:addChild({
		shift = { quitButton.size.w + 10, 0 }
	}):addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANKINGTRENDS, nil, nil, FONTS.BIG, nil, 0.65)
	local trendsView = trendsMainView:addChild({
		pos = { trendsTopBar.shift.x, trendsTopBar.shift.y * 2 + trendsTopBar.size.h },
		size = { trendsTopBar.size.w, trendsMainView.size.h - trendsTopBar.size.h - trendsTopBar.shift.y * 3 }
	})
	Ranking.ShowTrends(trendsView)
end

---Displays user main ranking info
---@param viewElement UIElement
function Ranking.ShowUserEloStats(viewElement)
	viewElement:kill(true)
	viewElement:setActive(Ranking.PlayerTrends ~= nil)

	local trend = nil
	local currentRank = TB_MENU_PLAYER_INFO.ranking.rank
	local compareRank = currentRank
	if (currentRank and Ranking.PlayerTrends) then
		for i = #Ranking.PlayerTrends, 1, -1 do
			if (Ranking.PlayerTrends[i].rank ~= compareRank) then
				compareRank = Ranking.PlayerTrends[i].rank
				break
			end
		end
		trend = currentRank == compareRank and 0 or (currentRank > compareRank and -1 or 1)
	end

	local rankTrendViewTitle = viewElement:addChild({
		pos = { 10, 5 },
		size = { viewElement.size.w - 20, 30}
	})
	rankTrendViewTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKEGLOBALRANKING, nil, nil, FONTS.BIG, nil, nil, nil, 0.1)
	local rankedInfoView = viewElement:addChild({
		pos = { 10, rankTrendViewTitle.shift.y * 2 + rankTrendViewTitle.size.h },
		size = { viewElement.size.w - 20, viewElement.size.h - rankTrendViewTitle.shift.y * 3 - rankTrendViewTitle.size.h }
	})
	local iconScale = math.min(rankedInfoView.size.w / 2, rankedInfoView.size.h, 256)
	local iconFieldScale = math.max(rankedInfoView.size.w / 2, iconScale)
	local rankingTierIconHolder = rankedInfoView:addChild({
		pos = { rankedInfoView.size.w / 2 - iconFieldScale, (rankedInfoView.size.h - iconScale) / 2 },
		size = { iconFieldScale, iconScale }
	})

	---Our icons have quite a bit of empty area on the sides
	---We want to render it slightly bigger here
	local iconMultiplier = 1.3
	local xShift = (iconFieldScale - iconScale * iconMultiplier) / 2
	if (xShift < 0) then
		xShift = xShift - rankingTierIconHolder.size.w
	end
	local rankingTierIcon = rankingTierIconHolder:addChild({
		pos = { xShift, -rankingTierIconHolder.size.h - iconScale * (iconMultiplier - 1) / 2 },
		size = { iconScale * iconMultiplier, iconScale * iconMultiplier },
		bgImage = TB_MENU_PLAYER_INFO.ranking.tier.image,
		imageColor = TB_MENU_PLAYER_INFO.ranking.qualifying and { 0.2, 0.2, 0.2, 1 } or UICOLORWHITE
	})

	local infoBitHeight = 35
	local rankingTierTitle = rankingTierIconHolder:addChild({
		pos = { 0, TB_MENU_PLAYER_INFO.ranking.nextTierElo > 0 and -infoBitHeight * 2 or -infoBitHeight },
		size = { rankingTierIconHolder.size.w, infoBitHeight },
		uiShadowColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	rankingTierTitle:addAdaptedText(TB_MENU_PLAYER_INFO.ranking.tier.title, nil, nil, FONTS.BIG, nil, 0.7, nil, nil, 4)

	if (TB_MENU_PLAYER_INFO.ranking.nextTierElo > 0) then
		local buttonColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR)
		buttonColor[4] = 0.75
		local nextTierGamesHolder = rankingTierIconHolder:addChild({
			pos = { rankingTierIcon.shift.x + rankingTierIcon.size.w * 0.1, rankingTierTitle.shift.y + rankingTierTitle.size.h },
			size = { rankingTierIcon.size.w * 0.8, infoBitHeight },
			interactive = true,
			bgColor = buttonColor,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = ROUNDED,
			rounded = 10
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
			TBMenu:showTextWithImage(rankedInfoTextRank, TB_MENU_LOCALIZED.MATCHMAKERANK .. " " .. TB_MENU_PLAYER_INFO.ranking.rank, FONTS.BIG, rankedInfoTextRank.size.h * 0.75, trend > 0 and "../textures/menu/general/trendup.tga" or "../textures/menu/general/trenddown.tga", { imageColor = trend > 0 and UICOLORGREEN or UICOLORRED } )
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
		local winrate = games ~= 0 and math.round(TB_MENU_PLAYER_INFO.ranking.wins / games * 10000) / 100 or nil
		local gameInfoStr = games .. " " .. TB_MENU_LOCALIZED.MATCHMAKEFIGHTSTOTAL
		gameInfoStr = winrate and (gameInfoStr .. "\n" .. winrate .. "% " .. TB_MENU_LOCALIZED.MATCHMAKEWINRATE) or gameInfoStr
		rankedInfoTextGames:addAdaptedText(true, gameInfoStr, nil, nil, 4, CENTER, 0.85)
	else
		rankedInfoTextHolder:addChild({
			shift = { 0, rankedInfoTextHolder.size.h / 5 }
		}):addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKEQUALIFICATIONINFO)
	end
end

---Loads mod ranking and displays it in a separate window
---@param modid integer
---@param modname string
---@param userStats PlayerInfoRanking
function Ranking.ShowModRanking(modid, modname, userStats)
	Ranking.ActiveOverlay = TBMenu:spawnWindowOverlay()
	local overlayKillAction = Ranking.ActiveOverlay.killAction
	Ranking.ActiveOverlay.killAction = function() overlayKillAction() Ranking.ActiveOverlay = nil end

	local viewWidth = math.clamp(WIN_W / 3, 350, 500)
	local rankingView = Ranking.ActiveOverlay:addChild({
		shift = { (WIN_W - viewWidth) / 2, TBMenu.UserBar.size.h + 20 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	Ranking:refreshRankingToplist(rankingView, modid, TB_MENU_LOCALIZED.RANKINGMODBESTPLAYERS1 .. " " .. modname .. " " .. TB_MENU_LOCALIZED.RANKINGMODBESTPLAYERS2, userStats)
end

---Displays user mod ranking stats or a loading animation if `Ranking.PlayerModRanking` is nil
---@param viewElement UIElement
function Ranking.ShowUserModStats(viewElement)
	viewElement:kill(true)

	local modTrendsTitle = viewElement:addChild({
		pos = { 10, 5 },
		size = { viewElement.size.w - 20, 30 }
	})
	modTrendsTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANKINGMODS, nil, nil, FONTS.BIG, nil, nil, nil, 0.1)

	if (Ranking.PlayerModRanking == nil) then
		TBMenu:displayLoadingMark(viewElement)
		return
	end

	local modListView = viewElement:addChild({
		pos = { 0, modTrendsTitle.shift.y + modTrendsTitle.size.h + 5 },
		size = { viewElement.size.w, viewElement.size.h - modTrendsTitle.shift.y - modTrendsTitle.size.h - 10 }
	})
	if (#Ranking.PlayerModRanking == 0) then
		modListView:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANKEDMODSEMPTY)
		return
	end

	local maxDisplay = math.min(4, #Ranking.PlayerModRanking, math.floor(modListView.size.h / 55))
	local elementHeight = math.min(modListView.size.h / maxDisplay, 55)
	for i, v in pairs(table.qsort(Ranking.PlayerModRanking, { "rank", "name" })) do
		if (i > maxDisplay) then
			break
		end
		local modTrend = modListView:addChild({
			pos = { 0, (i - 1) * elementHeight },
			size = { modListView.size.w, elementHeight }
		})
		local modTrendBG = modTrend:addChild({
			shift = { 7, 2 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
			shapeType = ROUNDED,
			rounded = 6
		})
		local modName = modTrendBG:addChild({
			pos = { 10, 5 },
			size = { modTrendBG.size.w - 20, modTrendBG.size.h * 0.5 }
		})
		local modNameStr = v.name:gsub("%.tbm$", '')
		modName:addAdaptedText(true, modNameStr, nil, nil, nil, LEFTBOT)
		local modStats = modTrendBG:addChild({
			pos = { modName.shift.x, modName.size.h + modName.shift.y },
			size = { modName.size.w, modName.size.h }
		})
		modStats:addAdaptedText(true, TB_MENU_LOCALIZED.MATCHMAKERANK .. " " .. v.rank .. ", " .. v.elo .. " " .. TB_MENU_LOCALIZED.MATCHMAKEELO, nil, nil, FONTS.LMEDIUM, RIGHT, 0.7)

		modTrendBG:addMouseUpHandler(function()
				Ranking.ShowModRanking(v.modid, modNameStr, {
					rank = v.rank,
					elo = v.elo,
					wins = v.wins,
					loses = v.loses,
					games = v.wins + v.loses
				})
			end)
	end
end

---Returns a shortened value with a postfix string to use for rendering
---@param val number
---@return number
---@return string
function RankingInternal.GetShortenedValue(val)
	local adjusted, text = val, ""
	local options = { "K", "M", "B" }
	for _, v in pairs(options) do
		local checkValue = adjusted / 1000
		if (checkValue > 1000) then
			adjusted = math.floor(checkValue)
			text = v
		else
			break
		end
	end
	return adjusted, text
end


---@alias RankingGameStatType
---| "games"
---| "score"
---| "dismembers"
---| "decaps"
---| "tc"

---Displays a window with game stat toplist
---@param stat RankingGameStatType
function Ranking.ShowGameStatToplist(stat)
	Ranking.ActiveOverlay = TBMenu:spawnWindowOverlay()
	local overlayKillAction = Ranking.ActiveOverlay.killAction
	Ranking.ActiveOverlay.killAction = function() overlayKillAction() Ranking.ActiveOverlay = nil end

	local toplistHolder = Ranking.ActiveOverlay:addChild({
		shift = { WIN_W / 4, TBMenu.UserBar.size.h + 20 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})

	local toplistHolderTop = toplistHolder:addChild({
		pos = { 10, 10 },
		size = { toplistHolder.size.w - 20, 40 }
	})
	local quitButton = toplistHolderTop:addChild({
		pos = { -toplistHolderTop.size.h, 0 },
		size = { toplistHolderTop.size.h, toplistHolderTop.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	quitButton:addChild({
		shift = { 2, 2 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})
	quitButton:addMouseHandlers(nil, function()
			Ranking.ActiveOverlay:kill()
		end)

	toplistHolderTop:addChild({
		pos = { 10, 0 },
		size = { toplistHolderTop.size.w - 20 - quitButton.size.w, toplistHolderTop.size.h }
	}):addAdaptedText(true, TB_MENU_LOCALIZED["RANKINGGAMESTATTOPLIST" .. string.upper(stat)], nil, nil, FONTS.BIG, LEFTMID, 0.6, nil, 0.1)

	local toplistHolderBot = toplistHolder:addChild({
		pos = { 10, -30 },
		size = { toplistHolder.size.w - 20, 30 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	local toplistHolderView = toplistHolder:addChild({
		pos = { 10, toplistHolderTop.shift.y * 2 + toplistHolderTop.size.h },
		size = { toplistHolder.size.w - 20, toplistHolder.size.h - toplistHolderTop.shift.y * 2 - toplistHolderTop.size.h - toplistHolderBot.size.h }
	})
	TBMenu:displayLoadingMark(toplistHolderView, TB_MENU_LOCALIZED.NETWORKLOADING)

	---@param extraString string?
	local function dataError(extraString)
		extraString = extraString and ("\n" .. extraString) or ""
		toplistHolderView:kill(true)
		toplistHolderView:addAdaptedText(true, TB_MENU_LOCALIZED.RANKINGTOPLISTERROR .. extraString)
	end

	---@param toplistData RankingGameStatToplistEntry[]
	---@param viewElement UIElement
	---@param titleString string
	---@param botBarOverride UIElement
	local function displayResults(toplistData, viewElement, titleString, botBarOverride)
		viewElement:kill(true)
		local elementHeight = 40
		local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(viewElement, 60, viewElement.rounded, 20)
		local listElements = {}

		topBar.shapeType = ROUNDED
		botBar.shapeType = ROUNDED
		topBar:setRounded({ viewElement.rounded, 0 })
		botBar:setRounded({ 0, viewElement.rounded })
		topBar:addAdaptedText(titleString, nil, nil, FONTS.BIG, nil, 0.55, nil, 0.1)

		for _, v in pairs(toplistData) do
			local toplistEntry = listingHolder:addChild({
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, toplistEntry)
			local entryBG = toplistEntry:addChild({
				pos = { 10, 2 },
				size = { toplistEntry.size.w - 12, toplistEntry.size.h - 4 },
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				shapeType = ROUNDED,
				rounded = 3
			})
			local entryRank = entryBG:addChild({
				pos = { 10, 5 },
				size = { 30, entryBG.size.h - 10 }
			})
			entryRank:addAdaptedText(true, "#" .. v.rank, nil, nil, FONTS.LMEDIUM, RIGHTMID, 0.6)
			local entryUser = entryBG:addChild({
				pos = { 55, entryRank.shift.y },
				size = { (entryBG.size.w - 70) * 0.65, entryRank.size.h }
			})
			entryUser:addAdaptedText(true, v.user, nil, nil, nil, LEFTMID)
			local entryResult = entryBG:addChild({
				pos = { -(entryBG.size.w - 70) * 0.35 - 10, entryRank.shift.y },
				size = { (entryBG.size.w - 70) * 0.35, entryRank.size.h }
			})
			local adjustedResult, adjustedPostfix = RankingInternal.GetShortenedValue(v.result)
			entryResult:addAdaptedText(true, numberFormat(adjustedResult) .. adjustedPostfix, nil, nil, FONTS.LMEDIUM, RIGHTMID, 0.75)
			toplistEntry:hide()
		end

		table.insert(toReload.child, botBarOverride)
		local listingScrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = listingScrollBar
		listingScrollBar:makeScrollBar(listingHolder, listElements, toReload, nil, nil, true)
	end

	Request:queue(function()
			download_server_info("ranking_gamestats_toplist&stat=" .. stat)
		end, "ranking_gamestats_" .. stat, function()
			if (toplistHolder == nil or toplistHolder.destroyed) then return end
			local toplistData = RankingInternal.ParseGameStatsToplist(get_network_response())
			if (#toplistData.weekly == 0) then
				dataError()
			else
				toplistHolderView:kill(true)
				local weeklyTopHolder = toplistHolderView:addChild({
					size = { toplistHolderView.size.w / 2 - 5, toplistHolderView.size.h },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					shapeType = ROUNDED,
					rounded = 10
				})
				displayResults(toplistData.weekly, weeklyTopHolder, TB_MENU_LOCALIZED.RANKINGPASTWEEK, toplistHolderBot)

				local seasonalTopHolder = toplistHolderView:addChild({
					pos = { weeklyTopHolder.size.w + 10, 0 },
					size = { weeklyTopHolder.size.w, toplistHolderView.size.h },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					shapeType = ROUNDED,
					rounded = 10
				})
				displayResults(toplistData.seasonal, seasonalTopHolder, TB_MENU_LOCALIZED.RANKINGTHISSEASON, toplistHolderBot)
			end
		end, function()
			if (toplistHolder == nil or toplistHolder.destroyed) then return end
			dataError(get_network_error())
		end)
end

---Displays user ranking game stat info
---@param viewElement UIElement
---@param stat RankingGameStatType
function Ranking.ShowUserGameStat(viewElement, stat)
	viewElement:kill(true)

	local icon = "../textures/menu/general/quests/"
	if (stat == "games") then
		icon = icon .. "qtype1.tga"
	elseif (stat == "score") then
		icon = icon .. "qtype3.tga"
	elseif (stat == "dismembers") then
		icon = icon .. "qtype4.tga"
	elseif (stat == "decaps") then
		icon = icon .. "qtypedecap.tga"
	elseif (stat == "tc") then
		icon = icon .. "qtypetc.tga"
	else
		return
	end

	local iconScale = math.min(256, viewElement.size.w - 20, viewElement.size.h - 20)
	viewElement:addChild({
		pos = { (viewElement.size.w - iconScale) / 2, (viewElement.size.h - iconScale) / 2 },
		size = { iconScale, iconScale },
		bgImage = icon,
		imageColor = { 1, 1, 1, 0.65 }
	})
	local statTitle = viewElement:addChild({
		pos = { 10, 5 },
		size = { viewElement.size.w - 20, 30 }
	})
	statTitle:addAdaptedText(true, TB_MENU_LOCALIZED["RANKINGGAMESTAT" .. string.upper(stat)], nil, nil, FONTS.BIG, nil, nil, nil, 0.1)

	if (Ranking.PlayerGameStats == nil) then
		TBMenu:displayLoadingMark(viewElement)
		return
	end

	local statValueSeasonal = viewElement:addChild({
		pos = { 10, viewElement.size.h / 2 },
		size = { viewElement.size.w - 20, viewElement.size.h / 4 },
		uiShadowColor = viewElement.bgColor
	})
	local seasonalAdjusted, seasonalPostfix = RankingInternal.GetShortenedValue(Ranking.PlayerGameStats[stat].seasonal)
	statValueSeasonal:addAdaptedText(true, numberFormat(seasonalAdjusted) .. seasonalPostfix .. "\nthis season", nil, nil, FONTS.BIG, nil, nil, nil, nil, 4)
	local statValueWeekly = viewElement:addChild({
		pos = { 10, viewElement.size.h * 0.8 },
		size = { viewElement.size.w - 20, viewElement.size.h / 5 },
		uiShadowColor = viewElement.bgColor
	})
	local weeklyAdjusted, weeklyPostfix = RankingInternal.GetShortenedValue(Ranking.PlayerGameStats[stat].seasonal)
	statValueWeekly:addAdaptedText(true, numberFormat(weeklyAdjusted) .. weeklyPostfix .. " past week", nil, nil, nil, CENTER, nil, nil, nil, 2)

	viewElement:addMouseUpHandler(function()
			Ranking.ShowGameStatToplist(stat)
		end)
end

---Displays user ranking information
---@param viewElement UIElement
function Ranking.ShowUserStats(viewElement)
	local mainRankingView = viewElement:addChild({
		pos = { 10, 10 },
		size = { (viewElement.size.w - 30) * 0.65, (viewElement.size.h - 20) * 0.4 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 10
	})
	mainRankingView:addMouseUpHandler(Ranking.ShowUserTrends)
	Ranking.ShowUserEloStats(mainRankingView)

	local modRankingView = viewElement:addChild({
		pos = { mainRankingView.shift.x * 2 + mainRankingView.size.w, mainRankingView.shift.y },
		size = { viewElement.size.w - mainRankingView.size.w - mainRankingView.shift.x * 3, mainRankingView.size.h },
		bgColor = mainRankingView.bgColor,
		shapeType = mainRankingView.shapeType,
		rounded = mainRankingView.rounded
	})
	Ranking.ShowUserModStats(modRankingView)

	local gameStats = { "games", "score", "dismembers", "decaps", "tc" }
	local gameStatViewports = { }
	local gameStatWidth = (viewElement.size.w - mainRankingView.shift.x * (#gameStats + 1)) / #gameStats
	local gameStatHeight = (viewElement.size.h - mainRankingView.shift.y * 4 - mainRankingView.size.h)
	local gameStatPosY = mainRankingView.shift.y * 2 + mainRankingView.size.h
	for i, v in pairs(gameStats) do
		local statView = viewElement:addChild({
			pos = { mainRankingView.shift.x * i + gameStatWidth * (i - 1), gameStatPosY },
			size = { gameStatWidth, gameStatHeight },
			bgColor = mainRankingView.bgColor,
			shapeType = mainRankingView.shapeType,
			rounded = mainRankingView.rounded,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true
		})
		gameStatViewports[i] = statView
		Ranking.ShowUserGameStat(statView, v)
	end

	if (Ranking.PlayerModRanking == nil or Ranking.PlayerTrends == nil or Ranking.IsUpdateRequired()) then
		Request:queue(fetch_ranking_trends, "ranking_trends", function()
			RankingInternal.ParseTrends(get_network_response())
			if (mainRankingView and not mainRankingView.destroyed) then
				Ranking.ShowUserEloStats(mainRankingView)
				Ranking.ShowUserModStats(modRankingView)
				if (Ranking.ActiveOverlay and not Ranking.ActiveOverlay.destroyed) then
					Ranking.ActiveOverlay:reload()
				end
			end
		end)
	end
	if (Ranking.LastBalance == nil or Ranking.LastBalance ~= TB_MENU_PLAYER_INFO.data.tc or Ranking.IsUpdateRequired()) then
		Request:queue(function() download_server_info("ranking_gamestats&username=" .. TB_MENU_PLAYER_INFO.username) end, "ranking_gamestats", function()
			Ranking.LastBalance = TB_MENU_PLAYER_INFO.data.tc
				RankingInternal.ParseGameStats(get_network_response())
				if (viewElement and not viewElement.destroyed) then
					for i, v in pairs(gameStats) do
						Ranking.ShowUserGameStat(gameStatViewports[i], v)
					end
				end
				if (Ranking.ActiveOverlay and not Ranking.ActiveOverlay.destroyed) then
					Ranking.ActiveOverlay:reload()
				end
			end)
	end
end

---Displays Ranking main screen
function Ranking:showMain()
	local toplistWidth = math.clamp(400, TBMenu.CurrentSection.size.w * 0.2, TBMenu.CurrentSection.size.w * 0.4)
	local mainView = TBMenu.CurrentSection:addChild({
		pos = { 5, 0 },
		size = { TBMenu.CurrentSection.size.w - toplistWidth - 15, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:addBottomBloodSmudge(mainView)

	local toplistView = TBMenu.CurrentSection:addChild({
		pos = { mainView.shift.x + mainView.size.w + 10, 0 },
		size = { toplistWidth, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	self:refreshRankingToplist(toplistView)
	self.ShowUserStats(mainView)
end


--[[ Deprecated functions, these will be removed in future ]]

---@deprecated
---Legacy function to get navigation buttons. Will be removed with future releases.
---@return MenuNavButton[]
function Ranking:getNavigationButtons()
	return {
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
			action = function()
				TBMenu:clearNavSection()
				TBMenu:showNavigationBar()
				TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
			end
		}
	}
end

---@deprecated
---Legacy function to display global ranking. Will be removed with future releases.
function Ranking:showGlobalRanking()
	TBMenu.CurrentSection:kill(true)
	---@diagnostic disable-next-line: deprecated
	TBMenu:showNavigationBar(Ranking:getNavigationButtons(), true)

	local playerRankingView = UIElement:new({
		parent = TBMenu.CurrentSection,
		pos = { 5, 0 },
		size = { TBMenu.CurrentSection.size.w * 0.65 - 10, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:addBottomBloodSmudge(playerRankingView, 1)
	if (Ranking.IsUpdateRequired() or TB_MENU_DEBUG) then
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
			---@diagnostic disable-next-line: deprecated
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
					bgImage = TB_MENU_PLAYER_INFO.ranking.tier.image
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
			mmRankedInfoTier:addAdaptedText(true, TB_MENU_PLAYER_INFO.ranking.tier.title, nil, nil, FONTS.BIG, CENTERBOT, 0.6)
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

			local minGamesToNextTier = math.ceil((TB_MENU_PLAYER_INFO.ranking.nextTierElo - TB_MENU_PLAYER_INFO.ranking.elo) / (Ranking.EloFactor * (1 - (1 / ( 1 + (math.pow(TB_MENU_PLAYER_INFO.ranking.elo, (bestAverageOpponent - TB_MENU_PLAYER_INFO.ranking.elo) / Ranking.EloDivisor)))))))
			local maxGamesToNextTier = math.ceil((TB_MENU_PLAYER_INFO.ranking.nextTierElo - TB_MENU_PLAYER_INFO.ranking.elo) / (Ranking.EloFactor * (1 - (1 / ( 1 + (math.pow(TB_MENU_PLAYER_INFO.ranking.elo, (worstAverageOpponent - TB_MENU_PLAYER_INFO.ranking.elo) / Ranking.EloDivisor)))))))

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
				--[[if (TB_MATCHMAKER_INFO.ranked == 0 or TB_MATCHMAKER_INFO.ranked > 65535) then
					rankedPlayers:uiText(TB_MENU_LOCALIZED.MATCHMAKENOPLAYERS)
				elseif (TB_MATCHMAKER_INFO.ranked == 1) then
					rankedPlayers:uiText(TB_MATCHMAKER_INFO.ranked .. " " .. TB_MENU_LOCALIZED.MATCHMAKEPLAYERSEARCHING)
				else
					rankedPlayers:uiText(TB_MATCHMAKER_INFO.ranked .. " " .. TB_MENU_LOCALIZED.MATCHMAKEPLAYERSSEARCHING)
				end]]
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
				---@diagnostic disable-next-line: deprecated
				UIElement:runCmd("matchmake ranked continue")
				set_discord_rpc(TB_MENU_LOCALIZED.MATCHMAKERANKEDMODE, TB_MENU_LOCALIZED.DISCORDRPCMATCHMAKING)
				TB_MATCHMAKER_SEARCHSTATUS = 1
				--Ranking:getMatchmaker()
				progress = 0
				rankedSearchButton:hide()
				rankedSearchProgress:show()
				rankedPlayers:hide()
				rankedSearchButtonStop:show()
			end, nil)
		rankedSearchButtonStop:addAdaptedText(false, TB_MENU_LOCALIZED.MATCHMAKESTOPSEARCH, nil, nil, FONTS.BIG, nil, 0.65)
		rankedSearchButtonStop:addMouseHandlers(nil, function()
				---@diagnostic disable-next-line: deprecated
				UIElement:runCmd("matchmake on 8 0 1")
				set_discord_rpc("", "")
				TB_MATCHMAKER_SEARCHSTATUS = 0
				--Ranking:getMatchmaker()
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
				---@diagnostic disable-next-line: deprecated
				UIElement:runCmd("matchmake on 8 0 1")
				set_discord_rpc("", "")
				TB_MATCHMAKER_SEARCHSTATUS = 0
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
				---@diagnostic disable-next-line: deprecated
				roomsOnline = UIElement:qsort(roomsOnline, "players", true)
				if (#roomsOnline > 0) then
					for i, room in pairs(roomsOnline) do
						if (room.players > 1 and room.players < 5) then
							---@diagnostic disable-next-line: deprecated
							UIElement:runCmd("jo " .. room.name)
							close_menu()
							return
						end
					end
					---@diagnostic disable-next-line: deprecated
					UIElement:runCmd("jo " .. roomsOnline[1].name)
					close_menu()
					return
				else
					---@diagnostic disable-next-line: deprecated
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
	---@diagnostic disable-next-line: param-type-mismatch
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

RankingInternal.Init()
