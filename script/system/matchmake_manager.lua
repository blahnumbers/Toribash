-- matchmake manager class
-- DO NOT MODIFY THIS FILE

TB_MATCHMAKER_INFO = nil
TB_MATCHMAKER_SEARCHSTATUS = TB_MATCHMAKER_SEARCHSTATUS or nil

MM_MATCHMAKER_MODS = MM_MATCHMAKER_MODS or {
	{
		title = TB_MENU_LOCALIZED.MATCHMAKEMODGRAPPLING,
		searchVal = 1,
		selected = true
	},
	{
		title = TB_MENU_LOCALIZED.MATCHMAKEMODKICKING,
		searchVal = 2,
		selected = false
	},
	{
		title = TB_MENU_LOCALIZED.MATCHMAKEMODSTRIKING,
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
		if (TB_MENU_MATCHMAKE_ISOPEN == 0 and get_world_state().game_type == 0) then
			UIElement:runCmd("matchmake pause")
		end
		Matchmake:getMatchmaker()
	end
	
	function Matchmake:quit()
		TB_MENU_MATCHMAKE_ISOPEN = 0
		TB_MATCHMAKER_SEARCHSTATUS = nil
		if (get_world_state().game_type == 0) then
			UIElement:runCmd("matchmake disconnect")
		end
		tbMenuCurrentSection:kill(true) 
		tbMenuNavigationBar:kill(true)
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
					availableBeltText:uiText(TB_MENU_LOCALIZED.MATCHMAKERANKEDBELT, nil, nil, FONTS.BIG, nil, 0.6)
				end)
		else
			local mmRankedTitle = UIElement:new({
				parent = viewElement,
				pos = { 5, viewElement.size.h / 25 },
				size = { viewElement.size.w - 10, viewElement.size.h / 7 }
			})
			local titleSizeMod = 1
			local rankedStr = TB_MENU_LOCALIZED.MATCHMAKERANKEDMODE
			local rankedSearchDisabled = get_world_state().game_type == 1-- and (PlayerInfo:getUser(get_player_info(0).name) == TB_MENU_PLAYER_INFO.username or PlayerInfo:getUser(get_player_info(1).name) == TB_MENU_PLAYER_INFO.username)
			while (mmRankedTitle:uiText(rankedStr, nil, nil, FONTS.BIG, LEFT, titleSizeMod, nil, nil, nil, nil, nil, true) == false) do
				titleSizeMod = titleSizeMod - 0.05
			end
			mmRankedTitle:addCustomDisplay(true, function()
					mmRankedTitle:uiText(rankedStr, nil, nil, FONTS.BIG, nil, titleSizeMod)
				end)
			if (TB_MENU_PLAYER_INFO.ranking.elo) then
				local mmRankedInfo = UIElement:new({
					parent = viewElement,
					pos = { viewElement.size.w / 20, mmRankedTitle.size.h + mmRankedTitle.shift.y * 2 },
					size = { viewElement.size.w / 20 * 18, viewElement.size.h / 5 * 2 }
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
				local details = TB_MENU_PLAYER_INFO.ranking.rank and 3 or 2					
				local mmRankedInfoTier = UIElement:new({
					parent = mmRankedInfoText,
					pos = { 0, 0 },
					size = { mmRankedInfoText.size.w, mmRankedInfoText.size.h / details }
				})
				mmRankedInfoTier:addCustomDisplay(true, function()
						mmRankedInfoTier:uiText(TB_MENU_PLAYER_INFO.ranking.title, nil, nil, FONTS.BIG, CENTERBOT, titleSizeMod - 0.2)
					end)
				if (TB_MENU_PLAYER_INFO.ranking.rank) then
					local mmRankedInfoRank = UIElement:new({
						parent = mmRankedInfoText,
						pos = { 0, mmRankedInfoText.size.h / details },
						size = { mmRankedInfoText.size.w, mmRankedInfoText.size.h / details }
					})
					mmRankedInfoRank:addCustomDisplay(true, function()
							mmRankedInfoRank:uiText(TB_MENU_LOCALIZED.MATCHMAKERANK .. " " .. TB_MENU_PLAYER_INFO.ranking.rank, nil, nil, nil, CENTERMID)
						end)
				end
				local mmRankedInfoGames = UIElement:new({
					parent = mmRankedInfoText,
					pos = { 0, mmRankedInfoText.size.h / details * (details - 1) },
					size = { mmRankedInfoText.size.w, mmRankedInfoText.size.h / details }
				})
				local games = TB_MENU_PLAYER_INFO.ranking.wins + TB_MENU_PLAYER_INFO.ranking.loses
				local winrate = games ~= 0 and math.floor(TB_MENU_PLAYER_INFO.ranking.wins / games * 100 + 0.5) or nil
				local gameInfoStr = games .. " " .. TB_MENU_LOCALIZED.MATCHMAKEFIGHTSTOTAL
				gameInfoStr = winrate and (gameInfoStr .. ", " .. winrate .. "% " .. TB_MENU_LOCALIZED.MATCHMAKEWINRATE) or gameInfoStr
				mmRankedInfoGames:addCustomDisplay(true, function()
						mmRankedInfoGames:uiText(gameInfoStr, nil, nil, 4, CENTER, 0.7)
					end)
			end
			local rankedPlayers = UIElement:new({
				parent = viewElement,
				pos = { viewElement.size.w / 10, -viewElement.size.h / 11 * 4 },
				size = { viewElement.size.w / 10 * 8, viewElement.size.h / 10 }
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
			local rankedSearchButton = UIElement:new({
				parent = viewElement,
				pos = { viewElement.size.w / 10, -viewElement.size.h / 4 },
				size = { viewElement.size.w / 10 * 8, viewElement.size.h / 5 },
				bgColor = { 0, 0, 0, 0.3 },
				hoverColor = { 0, 0, 0, 0.5 },
				pressedColor = { 1, 0, 0, 0.2 },
				interactive = not rankedSearchDisabled,
				hoverSound = 31,
				downSound = 50
			})
			local rankedSearchProgress = UIElement:new({
				parent = viewElement,
				pos = { viewElement.size.w / 10, -viewElement.size.h / 11 * 4 },
				size = { viewElement.size.w / 10 * 8, viewElement.size.h / 10 },
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
				pos = { viewElement.size.w / 10, -viewElement.size.h / 4 },
				size = { viewElement.size.w / 10 * 8, viewElement.size.h / 5 },
				bgColor = { 0, 0, 0, 0.3 },
				hoverColor = { 0, 0, 0, 0.5 },
				pressedColor = { 1, 0, 0, 0.2 },
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
			rankedSearchButton:addCustomDisplay(false, function()
					rankedSearchButton:uiText(TB_MENU_LOCALIZED.MATCHMAKESEARCH, nil, nil, FONTS.BIG, nil, 0.7, nil, 1)
				end)
			rankedSearchButton:addMouseHandlers(nil, function()
					UIElement:runCmd("matchmake ranked continue")
					TB_MATCHMAKER_SEARCHSTATUS = 1
					Matchmake:getMatchmaker()
					progress = 0
					rankedSearchButton:hide()
					rankedSearchProgress:show()
					rankedPlayers:hide()
					rankedSearchButtonStop:show()
				end, nil)
			rankedSearchButtonStop:addCustomDisplay(false, function()
					rankedSearchButtonStop:uiText(TB_MENU_LOCALIZED.MATCHMAKESTOPSEARCH, nil, nil, FONTS.BIG, nil, 0.7, nil, 1)
				end)
			rankedSearchButtonStop:addMouseHandlers(nil, function()
					UIElement:runCmd("matchmake on 8 0 1")
					TB_MATCHMAKER_SEARCHSTATUS = nil
					Matchmake:getMatchmaker()
					rankedSearchButton:show()
					rankedPlayers:show()
					rankedSearchProgress:hide()
					rankedSearchButtonStop:hide()
				end)
		end
		local bottomSplat = TBMenu:addBottomBloodSmudge(viewElement, 1)
	end
	
	function Matchmake:getNavigationButtons()
		local buttonsData = {
			{ 
				text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN, 
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
	
	function Matchmake:drawUnrankedSearchButton(viewElement, posX, posY, sizeX, sizeY, string1, string2, isDisabled)
		local button = UIElement:new({
			parent = viewElement,
			pos = { posX, posY },
			size = { sizeX, sizeY },
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 0, 0, 0.2 },
			interactive = not isDisabled,
			hoverSound = 31
		})
		local str1 = UIElement:new({
			parent = button,
			pos = { 0, 2 },
			size = { button.size.w, button.size.h / 5 * 3 - 2 }
		})
		local strSize = 1
		while (not str1:uiText(string1, nil, nil, FONTS.BIG, nil, strSize, nil, nil, nil, nil, nil, true)) do
			strSize = strSize - 0.05
		end
		str1:addCustomDisplay(true, function()
				str1:uiText(string1, nil, nil, FONTS.BIG, nil, strSize, nil, 1)
			end)
		local str2 = UIElement:new({
			parent = button,
			pos = { button.size.w / 8, str1.size.h },
			size = { button.size.w / 8 * 6, button.size.h - str1.size.h - 2 }
		})
		local strSize2 = strSize - 0.1
		while (not str2:uiText(string2, nil, nil, FONTS.BIG, nil, strSize2, nil, nil, nil, nil, nil, true)) do
			strSize2 = strSize2 - 0.05
		end
		str2:addCustomDisplay(true, function()
				str2:uiText(string2, nil, nil, FONTS.BIG, nil, strSize2, nil, 0.7)
			end)
		return button
	end
	
	function Matchmake:drawUnranked(viewElement)
		local mmUnrankedTitle = UIElement:new({
			parent = viewElement,
			pos = { 5, viewElement.size.h / 25 },
			size = { viewElement.size.w - 10, viewElement.size.h / 7 }
		})
		local unrankedSearchDisabled = get_world_state().game_type == 1-- and (PlayerInfo:getUser(get_player_info(0).name) == TB_MENU_PLAYER_INFO.username or PlayerInfo:getUser(get_player_info(1).name) == TB_MENU_PLAYER_INFO.username)
		local titleSizeMod = 1
		local unrankedStr = TB_MENU_LOCALIZED.MATCHMAKEUNRANKEDMODE
		while (mmUnrankedTitle:uiText(unrankedStr, nil, nil, FONTS.BIG, LEFT, titleSizeMod, nil, nil, nil, nil, nil, true) == false) do
			titleSizeMod = titleSizeMod - 0.05
		end
		mmUnrankedTitle:addCustomDisplay(true, function()
				mmUnrankedTitle:uiText(unrankedStr, nil, nil, FONTS.BIG, nil, titleSizeMod)
			end)
		local unrankedModsView = UIElement:new( {
			parent = viewElement,
			pos = { viewElement.size.w / 10, mmUnrankedTitle.size.h + mmUnrankedTitle.shift.y * 2 },
			size = { viewElement.size.w - viewElement.size.w / 5, viewElement.size.h / 2 }
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
			local checkBoxScale = unrankedModsView.size.h / #MM_MATCHMAKER_MODS - 10 > 64 and 64 or unrankedModsView.size.h / #MM_MATCHMAKER_MODS - 10
			unrankedMods[i].checkbox = UIElement:new({
				parent = unrankedMods[i].view,
				pos = { -checkBoxScale - (unrankedModsView.size.h / #MM_MATCHMAKER_MODS - 10 - checkBoxScale) / 2, (unrankedModsView.size.h / #MM_MATCHMAKER_MODS - 10 - checkBoxScale) / 2 },
				size = { checkBoxScale, checkBoxScale },
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
				bgImage = "../textures/menu/general/buttons/checkmark.tga"
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
		local unrankedBestMatch = Matchmake:drawUnrankedSearchButton(viewElement, viewElement.size.w / 10, -viewElement.size.h / 4, viewElement.size.w / 5 * 2 - 10, viewElement.size.h / 5, TB_MENU_LOCALIZED.MATCHMAKEFINDBESTMATCH1, TB_MENU_LOCALIZED.MATCHMAKEFINDBESTMATCH2, unrankedSearchDisabled)
		local unrankedSearchSettings = Matchmake:drawUnrankedSearchButton(viewElement, viewElement.size.w / 5 * 2 + viewElement.size.w / 10 + 10, -viewElement.size.h / 4, viewElement.size.w / 5 * 2 - 10, viewElement.size.h / 5, TB_MENU_LOCALIZED.MATCHMAKESEARCHSETTINGS1, TB_MENU_LOCALIZED.MATCHMAKESEARCHSETTINGS2, unrankedSearchDisabled)
		local unrankedSearchStop = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 10, -viewElement.size.h / 4 },
			size = { viewElement.size.w / 10 * 8, viewElement.size.h / 5 },
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 0, 0, 0.2 },
			interactive = true,
			hoverSound = 31			
		})
		local searchStr = { str = "", part1 = TB_MENU_LOCALIZED.MATCHMAKESEARCHING .. ".." }
		local unrankedSearchProgress = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 10, unrankedModsView.shift.y },
			size = { viewElement.size.w / 10 * 8, unrankedModsView.size.h },
			interactive = true,
			bgColor = { 0, 0, 0, 0.7 }
		})
		local progress, rotation, size = 0, 0, unrankedSearchProgress.size.h > 20 and 20 or unrankedSearchProgress.size.h
		unrankedSearchProgress:addCustomDisplay(false, function()
				unrankedSearchProgress:uiText(searchStr.part1, nil, nil, nil, nil, 0.8)
				set_color(1,1,1,0.8)
				draw_disk(unrankedSearchProgress.pos.x + unrankedSearchProgress.size.w / 2 - get_string_length(searchStr.part1, FONTS.MEDIUM) / 2 - size / 3 * 2, unrankedSearchProgress.pos.y + unrankedSearchProgress.size.h / 2, size / 2, size, 500, 1, rotation, progress, 0)
				progress = progress == 360 and -360 or progress + 5
				rotation = rotation + 3
			end)
		unrankedSearchStop:addCustomDisplay(false, function()
				unrankedSearchStop:uiText(TB_MENU_LOCALIZED.MATCHMAKESTOPSEARCH, nil, nil, FONTS.BIG, nil, 0.7, nil, 1)		
			end)
		unrankedSearchStop:addMouseHandlers(nil, function()
				UIElement:runCmd("matchmake on 8 0 1")
				TB_MATCHMAKER_SEARCHSTATUS = nil
				searchStr.str = ""
				unrankedSearchStop:hide()
				unrankedSearchProgress:hide()
				unrankedSearchSettings:show()
				unrankedBestMatch:show()
			end, nil)
		unrankedBestMatch:addMouseHandlers(nil, function()
				local bestMatch, maxPlayers = 0, 0
				Matchmake:getMatchmaker()
				if (TB_MATCHMAKER_INFO.grappling >= maxPlayers) then
					bestMatch = TB_MATCHMAKER_INFO.grappling == maxPlayers and bestMatch + MM_MATCHMAKER_MODS[1].searchVal or MM_MATCHMAKER_MODS[1].searchVal
					maxPlayers = TB_MATCHMAKER_INFO.grappling
					--searchStr.str = searchStr.str == "" and TB_MENU_LOCALIZED.MATCHMAKEMODGRAPPLING:lower() or searchStr.str .. " + " .. TB_MENU_LOCALIZED.MATCHMAKEMODGRAPPLING:lower()
				end
				if (TB_MATCHMAKER_INFO.kicking >= maxPlayers) then
					bestMatch = TB_MATCHMAKER_INFO.kicking == maxPlayers and bestMatch + MM_MATCHMAKER_MODS[2].searchVal or MM_MATCHMAKER_MODS[2].searchVal
					maxPlayers = TB_MATCHMAKER_INFO.kicking
					--searchStr.str = searchStr.str == "" and TB_MENU_LOCALIZED.MATCHMAKEMODKICKING:lower() or searchStr.str .. " + " .. TB_MENU_LOCALIZED.MATCHMAKEMODKICKING:lower()
				end
				if (TB_MATCHMAKER_INFO.striking >= maxPlayers) then
					bestMatch = TB_MATCHMAKER_INFO.striking == maxPlayers and bestMatch + MM_MATCHMAKER_MODS[3].searchVal or MM_MATCHMAKER_MODS[3].searchVal
					maxPlayers = TB_MATCHMAKER_INFO.striking
					--searchStr.str = searchStr.str == "" and TB_MENU_LOCALIZED.MATCHMAKEMODSTRIKING:lower() or searchStr.str .. " + " .. TB_MENU_LOCALIZED.MATCHMAKEMODSTRIKING:lower()
				end
				UIElement:runCmd("matchmake on " .. bestMatch .. " 0 0")
				TB_MATCHMAKER_SEARCHSTATUS = 2
				unrankedBestMatch:hide()
				unrankedSearchSettings:hide()
				unrankedSearchStop:show()
				unrankedSearchProgress:show()
			end, nil)
		unrankedSearchSettings:addMouseHandlers(nil, function()
				local mods = 0
				for i,v in pairs(MM_MATCHMAKER_MODS) do
					if (v.selected) then
						mods = mods + v.searchVal
					end
				end
				searchStr.str = TB_MENU_LOCALIZED.MATCHMAKESEARCHCUSTOM
				UIElement:runCmd("matchmake on " .. mods .. " 0 0")
				TB_MATCHMAKER_SEARCHSTATUS = 2
				unrankedBestMatch:hide()
				unrankedSearchSettings:hide()
				unrankedSearchStop:show()
				unrankedSearchProgress:show()
			end, nil)
		if (TB_MATCHMAKER_SEARCHSTATUS == 2) then
			unrankedBestMatch:hide()
			unrankedSearchSettings:hide()
		else
			unrankedSearchStop:hide()
			unrankedSearchProgress:hide()
		end
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
		local rankedWaitBottomSmudge = TBMenu:addBottomBloodSmudge(mmRankedWait, 1)
		mmRankedWait:addCustomDisplay(true, function()
			if (TB_MENU_PLAYER_INFO.ranking.elo == 0) then
				TB_MENU_PLAYER_INFO.ranking = PlayerInfo:getRanking()
				mmRankedWait:uiText(TB_MENU_LOCALIZED.MATCHMAKEUPDATINGRANK, nil, nil, FONTS.MEDIUM, CENTERMID)
			else 
				Matchmake:drawRanked(mmRankedButton)
				mmRankedWait:kill()
			end
		end)
		Matchmake:drawUnranked(mmUnrankedButton)
	end
		
end