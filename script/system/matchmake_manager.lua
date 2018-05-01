-- matchmake manager class
-- DO NOT MODIFY THIS FILE

TB_MATCHMAKER_INFO = nil

MM_MATCHMAKER_MODS = MM_MATCHMAKER_MODS or {
	{
		title = "Grappling",
		searchVal = 1,
		selected = true
	},
	{
		title = "Kicking",
		searchVal = 2,
		selected = false
	},
	{
		title = "Striking",
		searchVal = 4,
		selected = false
	}
}

do
	Matchmake = {}
    Matchmake.__index = Matchmake
	local cln = {}
	setmetatable(cln, Matchmake)
		
	function Matchmake:getMatchmaker()
		TB_MATCHMAKER_INFO = get_matchmaker().info
	end
	
	-- Connects to matchmake server in idle mode, do not instantly search for a fight
	function Matchmake:connect()
		UIElement:runCmd("matchmake pause")
		Matchmake:getMatchmaker()
	end
	
	function Matchmake:quit()
		TB_MENU_MATCHMAKE_ISOPEN = 0
		UIElement:runCmd("matchmake disconnect")
		tbMenuCurrentSection:kill(true) 
		tbMenuNavigationBar:kill()
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function Matchmake:drawRanked(viewElement)
		if (TB_MENU_PLAYER_INFO.data.qi < 500) then
			local scale = viewElement.size.w > viewElement.size.h and viewElement.size.h / 2 or viewElement.size.w / 2
			local scale = scale > 256 and 256 or scale
			local availableBeltIcon = UIElement:new({
				parent = viewElement,
				pos = { (viewElement.size.w - scale) / 2, (viewElement.size.h / 3 * 2 - scale) / 2 },
				size = { scale, scale },
				bgImage = "../textures/menu/belts/brown.tga"
			})
			local availableBeltText = UIElement:new({
				parent = viewElement,
				pos = { 50, -viewElement.size.h / 3 },
				size = { viewElement.size.w - 100, viewElement.size.h / 4 }
			})
			availableBeltText:addCustomDisplay(true, function()
					availableBeltText:uiText("Ranked Matchmaking is available with Brown Belt", nil, nil, FONTS.BIG, nil, 0.6)
				end)
		else
			local mmRankedTitle = UIElement:new({
				parent = viewElement,
				pos = { 5, 20 },
				size = { viewElement.size.w - 10, 50 }
			})
			local titleSizeMod = 0.8
			local rankedStr = "Ranked Mode"
			local rankedSearchDisabled = get_world_state().game_type == 1 and (PlayerInfo:getUser(get_player_info(0).name) == TB_MENU_PLAYER_INFO.username or PlayerInfo:getUser(get_player_info(1).name))
			while (mmRankedTitle:uiText(rankedStr, nil, nil, FONTS.BIG, LEFT, titleSizeMod, nil, nil, nil, nil, nil, true) == false) do
				titleSizeMod = titleSizeMod - 0.05
			end
			mmRankedTitle:addCustomDisplay(true, function()
					mmRankedTitle:uiText(rankedStr, nil, nil, FONTS.BIG, nil, titleSizeMod)
				end)
			if (TB_MENU_PLAYER_INFO.ranking.elo) then
				local mmRankedInfo = UIElement:new({
					parent = viewElement,
					pos = { 40, 80 },
					size = { viewElement.size.w - 80, viewElement.size.h - 250 }
				})
				local iconScale = mmRankedInfo.size.w - 250 < mmRankedInfo.size.h and mmRankedInfo.size.w - 250 or mmRankedInfo.size.h
				if (iconScale > 64) then
					local mmRankedIcon = UIElement:new({
						parent = mmRankedInfo,
						pos = { 0, (mmRankedInfo.size.h - iconScale) / 2 },
						size = { iconScale, iconScale },
						bgImage = TB_MENU_PLAYER_INFO.ranking.image
					})
				else 
					iconScale = -20
				end
				local mmRankedInfoText = UIElement:new({
					parent = mmRankedInfo,
					pos = { iconScale + 20, mmRankedInfo.size.h / 2 - 50 },
					size = { mmRankedInfo.size.w - iconScale - 20, 100 }
				})
				local mmRankedInfoTier = UIElement:new({
					parent = mmRankedInfoText,
					pos = { 0, 0 },
					size = { mmRankedInfoText.size.w, 40 }
				})
				mmRankedInfoTier:addCustomDisplay(true, function()
						mmRankedInfoTier:uiText(TB_MENU_PLAYER_INFO.ranking.title, nil, nil, FONTS.BIG, LEFT, titleSizeMod - 0.2)
					end)
				if (TB_MENU_PLAYER_INFO.ranking.rank) then
					local mmRankedInfoRank = UIElement:new({
						parent = mmRankedInfoText,
						pos = { 0, 40 },
						size = { mmRankedInfoText.size.w, 30 }
					})
					mmRankedInfoRank:addCustomDisplay(true, function()
							mmRankedInfoRank:uiText("Rank " .. TB_MENU_PLAYER_INFO.ranking.rank, nil, nil, nil, LEFT)
						end)
				end
				local mmRankedInfoGames = UIElement:new({
					parent = mmRankedInfoText,
					pos = { 0, 70 },
					size = { mmRankedInfoText.size.w, 30 }
				})
				local games = TB_MENU_PLAYER_INFO.ranking.wins + TB_MENU_PLAYER_INFO.ranking.loses
				local winrate = games ~= 0 and math.floor(TB_MENU_PLAYER_INFO.ranking.wins / games * 100 + 0.5) or nil
				local gameInfoStr = games .. " fights total"
				gameInfoStr = winrate and (gameInfoStr .. ", " .. winrate .. "% win rate") or gameInfoStr
				mmRankedInfoGames:addCustomDisplay(true, function()
						mmRankedInfoGames:uiText(gameInfoStr, nil, nil, 4, LEFT, 0.7)
					end)
			end
			local rankedPlayers = UIElement:new({
				parent = viewElement,
				pos = { 20, viewElement.size.h - 170 },
				size = { viewElement.size.w - 40, 30 }
			})
			rankedPlayers:addCustomDisplay(true, function()
					if (TB_MATCHMAKER_INFO.ranked == 0) then
						rankedPlayers:uiText("No players currently searching")
					elseif (TB_MATCHMAKER_INFO.ranked == 1) then
						rankedPlayers:uiText(TB_MATCHMAKER_INFO.ranked .. " player searching")
					else
						rankedPlayers:uiText(TB_MATCHMAKER_INFO.ranked .. " players searching")
					end
				end)
			local rankedSearchButton = UIElement:new({
				parent = viewElement,
				pos = { 50, -120 },
				size = { viewElement.size.w - 100, 90 },
				bgColor = { 0, 0, 0, 0.3 },
				hoverColor = { 0, 0, 0, 0.5 },
				pressedColor = { 1, 0, 0, 0.2 },
				interactive = not rankedSearchDisabled,
				hoverSound = 31,
				downSound = 50
			})
			local rankedSearchProgress = UIElement:new({
				parent = viewElement,
				pos = { viewElement.size.w / 4 + 30, -140 },
				size = { viewElement.size.w / 2, 20 }
			})
			local progress, rotation = 0, 0
			rankedSearchProgress:addCustomDisplay(false, function()
					rankedSearchProgress:uiText("Searching for a match", nil, nil, nil, LEFT)
					set_color(1,1,1,0.8)
					draw_disk(rankedSearchProgress.pos.x - 20, rankedSearchProgress.pos.y + 12, 6, 14, 500, 1, rotation, progress, 0)
					progress = progress == 360 and -360 or progress + 5
					rotation = rotation + 3
				end)
			local rankedSearchButtonStop = UIElement:new({
				parent = viewElement,
				pos = { 50, -100 },
				size = { viewElement.size.w - 100, 60 },
				bgColor = { 0, 0, 0, 0.3 },
				hoverColor = { 0, 0, 0, 0.5 },
				pressedColor = { 1, 0, 0, 0.2 },
				interactive = true,
				hoverSound = 31
			})
			rankedSearchProgress:hide()
			rankedSearchButtonStop:hide()
			rankedSearchButton:addCustomDisplay(false, function()
					rankedSearchButton:uiText("Search", nil, nil, FONTS.BIG, nil, 0.7, nil, 1)
				end)
			rankedSearchButton:addMouseHandlers(nil, function()
					UIElement:runCmd("matchmake ranked continue")
					Matchmake:getMatchmaker()
					rankedSearchButton:hide()
					progress = 0
					rankedSearchProgress:show()
					rankedSearchButtonStop:show()
				end, nil)
			rankedSearchButtonStop:addCustomDisplay(false, function()
					rankedSearchButtonStop:uiText("Stop search", nil, rankedSearchButtonStop.pos.y + 8, FONTS.BIG, nil, 0.7, nil, 1)
				end)
			rankedSearchButtonStop:addMouseHandlers(nil, function()
					UIElement:runCmd("matchmake on 8 0 1")
					Matchmake:getMatchmaker()
					rankedSearchButton:show()
					rankedSearchProgress:hide()
					rankedSearchButtonStop:hide()
				end)
		end
		local bottomSplat = TBMenu:addBottomBloodSmudge(viewElement, 1)
	end
	
	function Matchmake:getNavigationButtons()
		local buttonsData = {
			{ 
				text = "To Main", 
				action = function() Matchmake:quit() end, 
				width = 160 
			},
			--[[{ 
				text = "Back",
				action = function()
					
				end,
				width = 120
			}]]
		}
		return buttonsData
	end
	
	function Matchmake:drawUnranked(viewElement)
		local mmUnrankedTitle = UIElement:new({
			parent = viewElement,
			pos = { 5, 20 },
			size = { viewElement.size.w - 10, 50 }
		})
		local unrankedSearchDisabled = get_world_state().game_type == 1 and (PlayerInfo:getUser(get_player_info(0).name) == TB_MENU_PLAYER_INFO.username or PlayerInfo:getUser(get_player_info(1).name))
		local titleSizeMod = 0.8
		local unrankedStr = "Casual Play"
		while (mmUnrankedTitle:uiText(unrankedStr, nil, nil, FONTS.BIG, LEFT, titleSizeMod, nil, nil, nil, nil, nil, true) == false) do
			titleSizeMod = titleSizeMod - 0.05
		end
		mmUnrankedTitle:addCustomDisplay(true, function()
				mmUnrankedTitle:uiText(unrankedStr, nil, nil, FONTS.BIG, nil, titleSizeMod)
			end)
		local unrankedModsView = UIElement:new( {
			parent = viewElement,
			pos = { 50, 80 },
			size = { viewElement.size.w - 100, viewElement.size.h - 220 }
		})
		local unrankedMods = {}
		for i, v in pairs(MM_MATCHMAKER_MODS) do
			unrankedMods[i] = {}
			unrankedMods[i].view = UIElement:new({
				parent = unrankedModsView,
				pos = { 0, (i - 1) * unrankedModsView.size.h / #MM_MATCHMAKER_MODS + 5 },
				size = { unrankedModsView.size.w, unrankedModsView.size.h / #MM_MATCHMAKER_MODS - 10 },
				bgColor = { 0, 0, 0, 0.2 }
			})
			unrankedMods[i].text = UIElement:new({
				parent = unrankedMods[i].view,
				pos = { 0, 0 },
				size = { unrankedMods[i].view.size.w - 70, unrankedMods[i].view.size.h }
			})
			unrankedMods[i].text:addCustomDisplay(true, function()
					unrankedMods[i].text:uiText(MM_MATCHMAKER_MODS[i].title, unrankedMods[i].text.pos.x + 20, unrankedMods[i].text.pos.y + unrankedMods[i].text.size.h / 2 - 18, FONTS.BIG, LEFT, 0.6)
				end)
			unrankedMods[i].checkbox = UIElement:new({
				parent = unrankedMods[i].view,
				pos = { -50, 0 },
				size = { 50, 50 },
				bgColor = { 0, 0, 0, 0.5 },
				interactive = true,
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 0, 0, 0, 0.7 },
				downSound = 31
			})
			unrankedMods[i].checkimage = UIElement:new({
				parent = unrankedMods[i].checkbox,
				pos = { 0, 0 },
				size = { unrankedMods[i].checkbox.size.w, unrankedMods[i].checkbox.size.h },
				bgImage = "system/checkmark.tga"
			})
			if (not MM_MATCHMAKER_MODS[i].selected) then
				unrankedMods[i].checkimage:hide()
			end
			unrankedMods[i].checkbox:addMouseHandlers(nil, function()
					MM_MATCHMAKER_MODS[i].selected = not MM_MATCHMAKER_MODS[i].selected
					if (MM_MATCHMAKER_MODS[i].selected) then
						unrankedMods[i].checkimage:show()
					else
						unrankedMods[i].checkimage:hide()
					end
				end, nil)
		end
		local unrankedBestMatch = UIElement:new({
			parent = viewElement,
			pos = { 50, -120 },
			size = { (viewElement.size.w - 100) / 2 - 10, 90 },
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 0, 0, 0.2 },
			interactive = not unrankedSearchDisabled,
			hoverSound = 31
		})
		local unrankedSearchSettings = UIElement:new({
			parent = viewElement,
			pos = { -(viewElement.size.w - 100) / 2 - 40, -120 },
			size = { (viewElement.size.w - 100) / 2 - 10, 90 },
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 0, 0, 0.2 },
			interactive = not unrankedSearchDisabled,
			hoverSound = 31
		})
		local unrankedSearchStop = UIElement:new({
			parent = viewElement,
			pos = { 50, -90 },
			size = { viewElement.size.w - 100, 60 },
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 0, 0, 0.2 },
			interactive = true,
			hoverSound = 31			
		})
		local searchStr = { str = "", part1 = "Searching for a ", part2 = " match" }
		local unrankedSearchProgress = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 6 + 30, -140 },
			size = { viewElement.size.w / 3 * 2, 50 }
		})
		local progress, rotation = 0, 0
		unrankedSearchProgress:addCustomDisplay(false, function()
				unrankedSearchProgress:uiText(searchStr.part1 .. searchStr.str .. searchStr.part2, nil, nil, nil, LEFTMID, 0.8)
				set_color(1,1,1,0.8)
				draw_disk(unrankedSearchProgress.pos.x - 30, unrankedSearchProgress.pos.y + unrankedSearchProgress.size.h / 2, 6, 14, 500, 1, rotation, progress, 0)
				progress = progress == 360 and -360 or progress + 5
				rotation = rotation + 3
			end)
		unrankedSearchStop:addCustomDisplay(false, function()
				unrankedSearchStop:uiText("Stop Search", nil, nil, FONTS.BIG, nil, 0.7, nil, 1)		
			end)
		unrankedSearchStop:addMouseHandlers(nil, function()
				UIElement:runCmd("matchmake pause")
				searchStr.str = ""
				unrankedSearchStop:hide()
				unrankedSearchProgress:hide()
				unrankedSearchSettings:show()
				unrankedBestMatch:show()
			end, nil)
		unrankedBestMatch:addCustomDisplay(false, function()
				unrankedBestMatch:uiText("Find", nil, unrankedBestMatch.pos.y + 10, FONTS.BIG, CENTER, 0.7, nil, 1)
				unrankedBestMatch:uiText("best match", nil, unrankedBestMatch.pos.y + 55, nil, CENTER, 0.9, nil, 0.6)
			end)
		unrankedBestMatch:addMouseHandlers(nil, function()
				local bestMatch, maxPlayers = 0, 0
				Matchmake:getMatchmaker()
				if (TB_MATCHMAKER_INFO.grappling >= maxPlayers) then
					bestMatch = TB_MATCHMAKER_INFO.grappling == maxPlayers and bestMatch + MM_MATCHMAKER_MODS[1].searchVal or MM_MATCHMAKER_MODS[1].searchVal
					maxPlayers = TB_MATCHMAKER_INFO.grappling
					searchStr.str = searchStr.str == "" and "grappling" or searchStr.str .. " + grappling"
				end
				if (TB_MATCHMAKER_INFO.kicking >= maxPlayers) then
					bestMatch = TB_MATCHMAKER_INFO.kicking == maxPlayers and bestMatch + MM_MATCHMAKER_MODS[2].searchVal or MM_MATCHMAKER_MODS[2].searchVal
					maxPlayers = TB_MATCHMAKER_INFO.kicking
					searchStr.str = searchStr.str == "" and "kicking" or searchStr.str .. " + kicking"
				end
				if (TB_MATCHMAKER_INFO.striking >= maxPlayers) then
					bestMatch = TB_MATCHMAKER_INFO.striking == maxPlayers and bestMatch + MM_MATCHMAKER_MODS[3].searchVal or MM_MATCHMAKER_MODS[3].searchVal
					maxPlayers = TB_MATCHMAKER_INFO.striking
					searchStr.str = searchStr.str == "" and "striking" or searchStr.str .. " + striking"
				end
				UIElement:runCmd("matchmake on " .. bestMatch .. " 0 0")
				unrankedBestMatch:hide()
				unrankedSearchSettings:hide()
				unrankedSearchStop:show()
				unrankedSearchProgress:show()
			end, nil)
		unrankedSearchSettings:addCustomDisplay(false, function()
				unrankedSearchSettings:uiText("Search", nil, unrankedSearchSettings.pos.y + 10, FONTS.BIG, CENTER, 0.7, nil, 1)
				unrankedSearchSettings:uiText("with settings", nil, unrankedSearchSettings.pos.y + 55, nil, CENTER, 0.9, nil, 0.6)
			end)
		unrankedSearchSettings:addMouseHandlers(nil, function()
				local mods = 0
				for i,v in pairs(MM_MATCHMAKER_MODS) do
					if (v.selected) then
						mods = mods + v.searchVal
					end
				end
				searchStr.str = "custom"
				unrankedSearchProgress.shift.y = -130
				unrankedSearchProgress.size.h = 20
				if (not unrankedSearchProgress:uiText(searchStr.part1 .. searchStr.str .. searchStr.part2, nil, nil, nil, LEFT, nil, nil, nil, nil, nil, nil, true)) then
					unrankedSearchProgress.shift.y = -150
					unrankedSearchProgress.size.h = 45
				end
				UIElement:runCmd("matchmake on" .. mods .. " 0 0")
				unrankedBestMatch:hide()
				unrankedSearchSettings:hide()
				unrankedSearchStop:show()
				unrankedSearchProgress:show()
			end, nil)
		unrankedSearchStop:hide()
		unrankedSearchProgress:hide()
	end
	
	function Matchmake:showMain(elementView)
		TB_MENU_MATCHMAKE_ISOPEN = 1
		local mmTimeRefresh = os.time()
		local refreshLast = mmTimeRefresh
		elementView:addCustomDisplay(true, function()
				if ((os.time() - mmTimeRefresh) % 2 == 0 and refreshLast ~= os.time()) then
					refreshLast = os.time()
					Matchmake:getMatchmaker()
				end
			end)
		local mmRankedButton = UIElement:new({
			parent = elementView,
			pos = { 5, 0 },
			size = { elementView.size.w / 2 - 10, elementView.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local mmUnrankedButton = UIElement:new({
			parent = elementView,
			pos = { elementView.size.w / 2 + 5, 0 },
			size = { elementView.size.w / 2 - 10, elementView.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local mmUnrankedBottomSplat = TBMenu:addBottomBloodSmudge(mmUnrankedButton, 2)
		local mmRankedWait = UIElement:new({
			parent = mmRankedButton,
			pos = { 0, 0 },
			size = { mmRankedButton.size.w, mmRankedButton.size.h }
		})
		mmRankedWait:addCustomDisplay(true, function()
			if (TB_MENU_PLAYER_INFO.ranking.elo == 0) then
				TB_MENU_PLAYER_INFO.ranking = PlayerInfo:getRanking()
				mmRankedWait:uiText("Updating Ranking Stats...", nil, nil, FONTS.MEDIUM, CENTERMID)
			else 
				Matchmake:drawRanked(mmRankedButton)
				mmRankedWait:kill()
			end
		end)
		Matchmake:drawUnranked(mmUnrankedButton)
	end
		
end