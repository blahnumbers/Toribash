do
	Quests = {}
	Quests.__index = Quests
	local cln = {}
	setmetatable(cln, Quests)
	
	function Quests:getQuests()
		TB_MENU_QUESTS_COUNT = 0
		local file = Files:open("../data/quest.txt")
		if (not file.data) then
			download_quest(TB_MENU_PLAYER_INFO.username)
			return false
		end
		local questData = {}
		local dataTypes = {
			{ "id", numeric = true },
			{ "type", numeric = true },
			{ "progress", numeric = true },
			{ "requirement", numeric = true },
			{ "timeleft", numeric = true },
			{ "modid", numeric = true },
			{ "modname" },
			{ "decap", boolean = true },
			{ "matchmake", boolean = true },
			{ "official", boolean = true },
			{ "reward", numeric = true },
			{ "rewardid", numeric = true },
			{ "name" },
			{ "ranked", boolean = true }
		}
		for i, ln in pairs(file:readAll()) do
			if (not ln:find("^#")) then
				local _, segments = ln:gsub("([^\t]*)\t?", "")
				local dataStream = { ln:match(("([^\t]*)\t?"):rep(segments)) }
				local quest = {}
				for i,v in pairs(dataTypes) do
					if (v.numeric or v.boolean) then
						quest[v[1]] = tonumber(dataStream[i])
						if (v.boolean) then
							quest[v[1]] = quest[v[1]] == 1
						end
					else
						quest[v[1]] = dataStream[i]
					end
				end
				table.insert(questData, quest)
				
				if (quest.progress >= quest.requirement) then
					TB_MENU_QUESTS_COUNT = TB_MENU_QUESTS_COUNT + 1
				end
			end
		end
		file:close()
		return questData
	end
	
	function Quests:getQuestById(id)
		if (not QUESTS_DATA) then
			QUESTS_DATA = Quests:getQuests()
		end
		for i,v in pairs(QUESTS_DATA) do
			if (v.id == id) then
				return v
			end
		end
		return false
	end
	
	function Quests:setQuestProgress(quest, progress)
		quest.progress = quest.requirement < progress and quest.requirement or progress
	end
	
	function Quests:getQuestName(v)
		if (v.name and v.name:len() > 1) then
			return v.name
		end
		if (v.type == 1) then
			return TB_MENU_LOCALIZED.QUESTSNAMETYPE1
		elseif (v.type == 2) then
			return TB_MENU_LOCALIZED.QUESTSNAMETYPE2
		elseif (v.type == 3) then
			return TB_MENU_LOCALIZED.QUESTSNAMETYPE3
		elseif (v.type == 4) then
			if (v.decap) then
				return TB_MENU_LOCALIZED.QUESTSNAMETYPEDECAP
			else
				return TB_MENU_LOCALIZED.QUESTSNAMETYPE4
			end
		end
		return "Toribash Quest"
	end
	
	function Quests:getQuestTarget(v)
		local targetText = ""
		if (v.type == 1) then
			targetText = TB_MENU_LOCALIZED.QUESTSPLAYREQ .. " " .. v.requirement .. " " .. (v.ranked and TB_MENU_LOCALIZED.WORDRANKED .. " " or "") .. TB_MENU_LOCALIZED.WORDGAMES
		elseif (v.type == 2) then
			targetText = TB_MENU_LOCALIZED.QUESTSWINREQ .. " " .. v.requirement .. " " .. (v.ranked and TB_MENU_LOCALIZED.WORDRANKED .. " " or "") .. TB_MENU_LOCALIZED.WORDFIGHTS
			if (v.decap) then
				targetText = targetText .. " " .. TB_MENU_LOCALIZED.QUESTSBYDECAP .. (v.ranked and " " .. TB_MENU_LOCALIZED.QUESTSRANKEDMODE or "")
			end
		elseif (v.type == 3) then
			targetText = TB_MENU_LOCALIZED.QUESTSGETREQ .. " " .. v.requirement .. " " .. TB_MENU_LOCALIZED.QUESTSGETREQ2 .. (v.ranked and " " .. TB_MENU_LOCALIZED.QUESTSRANKEDMODE or "")
		elseif (v.type == 4) then
			if (v.decap) then
				targetText = TB_MENU_LOCALIZED.QUESTSDECAPREQ .. " " .. v.requirement .. " " .. TB_MENU_LOCALIZED.WORDTIMES .. (v.ranked and " " .. TB_MENU_LOCALIZED.QUESTSRANKEDMODE or "")
			else
				targetText = TB_MENU_LOCALIZED.QUESTSDISMEMBERREQ .. " " .. v.requirement .. " " .. TB_MENU_LOCALIZED.WORDTIMES .. (v.ranked and " " .. TB_MENU_LOCALIZED.QUESTSRANKEDMODE or "")
			end
		end
		if (v.modid ~= 0) then
			targetText = targetText .. " " .. TB_MENU_LOCALIZED.WORDIN .. " " .. v.modname
		end
		if (v.matchmake) then
			targetText = targetText .. " " .. TB_MENU_LOCALIZED.QUESTSMATCHMAKEREQ
		elseif (v.official) then
			targetText = targetText .. " " .. TB_MENU_LOCALIZED.QUESTSOFFICIALREQ
		end
		return targetText
	end
	
	function Quests:getReward(v)
		if (v.rewardid == 0) then
			return v.reward .. " " .. TB_MENU_LOCALIZED.WORDTC
		end
		local item = Torishop:getItemInfo(v.rewardid)
		return item.shortname or "???"
	end
	
	function Quests:drawRewardText(quest, questReward)
		local rewardText = Quests:getReward(quest)
		if (rewardText) then
			local iconSize = questReward.size.h > 32 and 32 or questReward.size.h
			local questRewardText = UIElement:new({
				parent = questReward,
				pos = { iconSize + 20, 0 },
				size = { questReward.size.w - iconSize - 20, questReward.size.h }
			})
			questRewardText:addAdaptedText(true, rewardText)
			local textWidth = 0
			for i,v in pairs(questRewardText.dispstr) do
				local w = questRewardText.textScale * get_string_length(v, FONTS.MEDIUM)
				if (w > textWidth) then
					textWidth = w
				end
			end
					
			local questRewardIcon = UIElement:new({
				parent = questReward,
				pos = { (questReward.size.w - textWidth - iconSize - 10) / 2, (questReward.size.h - iconSize) / 2 },
				size = { iconSize, iconSize },
				bgImage = quest.rewardid == 0 and "../textures/store/toricredit_tiny.tga" or "../textures/store/items/" .. quest.rewardid .. ".tga"
			})
		end
	end
	
	function Quests:showQuest(questView, quest, bottomSmudge, customClaimFunc)
		local bgScale = questView.size.w - 20 > questView.size.h / 5 * 3 - 20 and questView.size.h / 5 * 3 - 20 or questView.size.w - 20
		local questBackground = UIElement:new({
			parent = questView,
			pos = { (questView.size.w - bgScale) / 2, 10 },
			size = { bgScale, bgScale },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = ROUNDED,
			rounded = bgScale
		})
		local qType = (quest.type == 4 and quest.decap) and "decap" or quest.type
		local questIcon = UIElement:new({
			parent = questBackground,
			pos = { bgScale / 5, bgScale / 5 },
			size = { bgScale / 5 * 3, bgScale / 5 * 3 },
			bgImage = "../textures/menu/general/quests/qtype" .. qType .. ".tga"
		})
		local progress = quest.progress / quest.requirement
		progress = progress > 1 and 1 or progress
		questBackground:addCustomDisplay(false, function()
				set_color(unpack(TB_MENU_DEFAULT_LIGHTER_COLOR))
				draw_disk(questBackground.pos.x + questBackground.size.w / 2, questBackground.pos.y + questBackground.size.h / 2, questBackground.size.h / 2 - 25, questBackground.size.h / 2 - 5, 100, 1, -60, -240, 0)
				set_color(unpack(UICOLORWHITE))
				draw_disk(questBackground.pos.x + questBackground.size.w / 2, questBackground.pos.y + questBackground.size.h / 2, questBackground.size.h / 2 - 25, questBackground.size.h / 2 - 5, 100, 1, -60, -240 * progress, 0)
			end)
		if (quest.timeleft < 0) then
			local progressText = UIElement:new({
				parent = questBackground,
				pos = { questBackground.size.w / 5, -questBackground.size.h / 5 },
				size = { questBackground.size.w / 5 * 3, questBackground.size.h / 8 }
			})
			progressText:addAdaptedText(true, quest.progress .. " / " .. quest.requirement)
		else
			quest.timetick = quest.timetick or os.time()
			local progressText = UIElement:new({
				parent = questBackground,
				pos = { questBackground.size.w / 5, -questBackground.size.h / 3 },
				size = { questBackground.size.w / 5 * 3, questBackground.size.h / 8 },
				bgColor = cloneTable(TB_MENU_DEFAULT_DARKEST_COLOR)
			})
			progressText.bgColor[4] = 0.7
			progressText:addAdaptedText(false, quest.progress .. " / " .. quest.requirement)
			local timeleftText = UIElement:new({
				parent = questBackground,
				pos = { questBackground.size.w / 5, -questBackground.size.h / 5 },
				size = { questBackground.size.w / 5 * 3, questBackground.size.h / 7 }
			})
			timeleftText:addAdaptedText(true, TBMenu:getTime(quest.timeleft - (os.time() - quest.timetick), 2) .. " left")
			timeleftText:addCustomDisplay(true, function()
					timeleftText:uiText(TBMenu:getTime(quest.timeleft - (os.time() - quest.timetick), 2) .. " left", nil, nil, nil, nil, timeleftText.textScale)
				end)
		end
		local questName = UIElement:new({
			parent = questView,
			pos = { 10, questView.size.h / 5 * 3 },
			size = { questView.size.w - 20, questView.size.h / 10 }
		})
		questName:addAdaptedText(true, Quests:getQuestName(quest), nil, nil, FONTS.BIG, nil, 0.7)
		local questTarget = UIElement:new({
			parent = questView,
			pos = { 10, questView.size.h / 10 * 7 },
			size = { questView.size.w - 20, questView.size.h / 5 }
		})
		questTarget:addAdaptedText(true, Quests:getQuestTarget(quest))
		if (TB_STORE_DATA.ready) then
			local questReward = UIElement:new({
				parent = questView,
				pos = { 5, questView.size.h / 10 * 9 },
				size = { questView.size.w - 10, questView.size.h / 10 }
			})
			Quests:drawRewardText(quest, questReward)
		end
		if (quest.progress >= quest.requirement) then
			local questClaimBg = UIElement:new({
				parent = questView,
				pos = { 0, 0 },
				size = { questView.size.w, questView.size.h },
				bgColor = { 0, 0, 0, 0.2 }
			})
			local questClaim = UIElement:new({
				parent = questClaimBg,
				pos = { 10, (questClaimBg.size.h + 32) / 3 },
				size = { questClaimBg.size.w - 20, (questClaimBg.size.h + 32) / 3 },
				shapeType = ROUNDED,
				rounded = 5,
				innerShadow = { 0, 5 },
				shadowColor = TB_MENU_DEFAULT_ORANGE,
				bgColor = TB_MENU_DEFAULT_YELLOW,
				interactive = true,
				pressedColor = { 0.902, 0.738, 0.269, 1 },
				hoverColor = { 0.969, 0.781, 0.199, 1 }
			})
			questClaim:addMouseHandlers(nil, function()
					questView:kill(true)
					TBMenu:addBottomBloodSmudge(questView, 1)
					TBMenu:displayLoadingMark(questView, "Claiming Quest")
					Request:queue(function() claim_quest(quest.id) end, "questclaim", function()
						update_tc_balance()
						TB_MENU_DOWNLOAD_INACTION = true
						tcUpdate = true
						if (customClaimFunc) then
							customClaimFunc()
						else
							Quests:showMain(true)
						end
					end)
				end)
			local claimText = UIElement:new({
				parent = questClaim,
				pos = { 10, 0 },
				size = { questClaim.size.w - 20, questClaim.size.h / 2 }
			})
			claimText:addAdaptedText(false, TB_MENU_LOCALIZED.QUESTSCLAIMREWARD, nil, nil, FONTS.BIG, nil, 0.7, nil, nil, 1.8)
			local buttonSize = questClaim.size.h - 15 > 40 and 40 or questClaim.size.h - 15
			local claimButton = UIElement:new({
				parent = questClaim,
				pos = { 10, -5 - (questClaim.size.h / 2 + buttonSize) / 2 },
				size = { questClaim.size.w - 20, buttonSize },
				shapeType = ROUNDED,
				rounded = 5,
				bgColor = { 0.594, 0.418, 0.14, 1 }
			})
			if (TB_STORE_DATA.ready) then
				Quests:drawRewardText(quest, claimButton)
			end
			bottomSmudge:reload()
		end
	end
	
	function Quests:getGlobalQuests(fileData)
		TB_MENU_QUESTS_GLOBAL_COUNT = 0
		
		local fileData = fileData or Files:open("../data/quests_global.dat")
		local globalQuests = {}
		local dataTypes = {
			{ 'id', numeric = true },
			{ 'type', numeric = true },
			{ 'name' },
			{ 'requirement', numeric = true },
			{ 'progress', numeric = true },
			{ 'modreq', numeric = true },
			{ 'claimed', boolean = true },
			{ 'available', boolean = true },
			{ 'itemid', numeric = true },
			{ 'amount', numeric = true },
			{ 'description' }
		}
		for i, ln in pairs(fileData:readAll()) do
			if (not string.match(ln, "^questid")) then
				local _, segments = ln:gsub("\t", "")
				local data_stream = { ln:match(("([^\t]*)\t?"):rep(segments)) }
				
				local quest = {}
				for i,v in pairs(dataTypes) do
					quest[v[1]] = data_stream[i]
					if (v.numeric) then
						quest[v[1]] = tonumber(quest[v[1]]) or 0
					end
					if (v.boolean) then
						quest[v[1]] = quest[v[1]] == '1'
					end
				end
				if (quest.itemid == 0) then
					quest.rewardtc = quest.amount
				elseif (quest.itemid == 2528) then
					quest.rewardst = quest.amount
				else
					quest.rewarditem = quest.itemid
				end
				quest.description = quest.description ~= '' and quest.description or false
				quest.progresspercentage = (quest.requirement / (quest.progress == 0 and 0.01 or quest.progress))
				table.insert(globalQuests, quest)
				
				if (quest.progresspercentage <= 1 and not quest.claimed) then
					TB_MENU_QUESTS_GLOBAL_COUNT = TB_MENU_QUESTS_GLOBAL_COUNT + 1
				end
			end
		end
		
		fileData:close()
		globalQuests = UIElement:qsort(globalQuests, { "type", "progresspercentage" })
		return globalQuests
	end
	
	function Quests:getGlobalQuestsNavigation()
		return {
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = function() TBMenu:clearNavSection() Notifications:showMain(true) end
			},
			{
				text = TB_MENU_LOCALIZED.QUESTSGLOBALCOMPLETED,
				action = function() Quests:showGlobalQuests(QUESTS_GLOBAL_DATA, true) end,
				right = true,
				sectionId = 2
			},
			{
				text = TB_MENU_LOCALIZED.QUESTSGLOBALACTIVE,
				action = function() Quests:showGlobalQuests(QUESTS_GLOBAL_DATA) end,
				right = true,
				sectionId = 1
			},
		}
	end
	
	function Quests:prepareGlobalQuests()
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
		tbMenuCurrentSection:kill(true)
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Quests:getGlobalQuestsNavigation(), true, true, 1)
		
		if (QUESTS_LASTUPDATE_GLOBAL.time + 60 >= os.time() or QUESTS_LASTUPDATE_GLOBAL.qi == TB_MENU_PLAYER_INFO.data.qi and not TB_MENU_DEBUG) then
			-- Not enough time has passed or they haven't played any games so progress should be same
			Quests:showGlobalQuests(QUESTS_GLOBAL_DATA)
			return
		end
		
		download_global_quests()
		local loader = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(loader, 1)
		TBMenu:displayLoadingMark(loader, TB_MENU_LOCALIZED.QUESTSGLOBALUPDATING)
		
		local questsFile = Files:open("../data/quests_global.dat")
		loader:addCustomDisplay(false, function()
				if (questsFile:isDownloading()) then
					return
				end
				
				questsFile:reopen()
				QUESTS_GLOBAL_DATA = Quests:getGlobalQuests(questsFile)
				QUESTS_LASTUPDATE_GLOBAL.time = os.time()
				QUESTS_LASTUPDATE_GLOBAL.qi = TB_MENU_PLAYER_INFO.data.qi
				Quests:showGlobalQuests(QUESTS_GLOBAL_DATA)
			end)
	end
	
	function Quests:showGlobalQuestButton(quest, listingHolder, listElements, elementHeight)
		local questHolder = UIElement:new({
			parent = listingHolder,
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, questHolder)
		local questBackground = UIElement:new({
			parent = questHolder,
			pos = { 10, 3 },
			size = { questHolder.size.w - 12, questHolder.size.h - 3 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		if (not quest.description) then
			questBackground.size.h = questBackground.size.h - 3
		end
		local questTitle = UIElement:new({
			parent = questBackground,
			pos = { 10, 5 },
			size = { questBackground.size.w / 4, questBackground.size.h - 10 }
		})
		questTitle:addAdaptedText(true, quest.name, nil, nil, nil, LEFTMID)
		
		local questProgress = quest.progress > quest.requirement and 1 or quest.progress / quest.requirement
		local questProgressOutline = UIElement:new( {
			parent = questBackground,
			pos = { questTitle.shift.x + questTitle.size.w + 10, 10 },
			size = { questBackground.size.w / 2 - 20, questBackground.size.h - 20 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = ROUNDED,
			rounded = 10
		})
		local questProgressBar = UIElement:new({
			parent = questProgressOutline,
			pos = { 2, 2 },
			size = { questProgressOutline.size.w - 4, questProgressOutline.size.h - 4 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = questProgressOutline.shapeType,
			rounded = questProgressOutline.rounded / 5 * 4
		})
		local questProgressBarState
		if (quest.progress > 0) then
			questProgressBarState = UIElement:new({
				parent = questProgressBar,
				pos = { 0, 0 },
				size = { questProgressBar.size.w * questProgress, questProgressBar.size.h },
				shapeType = questProgressBar.shapeType,
				rounded = questProgressBar.rounded,
				interactive = questProgress == 1 and not quest.claimed,
				bgColor = (quest.progresspercentage > 1 or quest.claimed) and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_ORANGE,
				hoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
				pressedColor = TB_MENU_DEFAULT_YELLOW,
				innerShadow = { 3, 3 },
				shadowColor = { (quest.progresspercentage > 1 or quest.claimed) and TB_MENU_DEFAULT_LIGHTER_COLOR or TB_MENU_DEFAULT_YELLOW, (quest.progresspercentage > 1 or quest.claimed) and TB_MENU_DEFAULT_DARKEST_COLOR or TB_MENU_DEFAULT_DARKER_ORANGE }
			})
		end
		local questProgressText = UIElement:new({
			parent = questProgressBar,
			pos = { questProgressBar.size.w / 3, 3 },
			size = { questProgressBar.size.w / 3, questProgressBar.size.h - 6 }
		})
		if (questProgress < 1) then
			questProgressText:addAdaptedText(true, quest.progress .. " / " .. quest.requirement, nil, nil, nil, nil, nil, nil, nil, 1)
		elseif (quest.claimed) then
			questProgressText:addAdaptedText(true, TB_MENU_LOCALIZED.REWARDSCLAIMSUCCESS, nil, nil, nil, nil, nil, nil, nil, 1)
		else
			questProgressText:addAdaptedText(true, TB_MENU_LOCALIZED.QUESTSCLAIMREWARD, nil, nil, nil, nil, nil, nil, nil, 1)
			questProgressBarState:addMouseHandlers(nil, function()
					questProgressBarState:deactivate(true)
					questProgressText:addCustomDisplay(true, function() end)
					TBMenu:displayLoadingMarkSmall(questProgressBarState, "", questProgressText.textFont)
					Request:queue(function() claim_quest_global(quest.id) end, "net_questclaim", function()
							questProgressBarState:kill(true)
							local response = get_network_response()
							if (response:find("GATEWAY 0; 0")) then
								TB_MENU_QUESTS_GLOBAL_COUNT = TB_MENU_QUESTS_GLOBAL_COUNT - 1
								quest.claimed = true
								questProgressBarState.bgColor = TB_MENU_DEFAULT_DARKER_COLOR
								questProgressBarState.inactiveColor = TB_MENU_DEFAULT_DARKER_COLOR
								questProgressBarState.shadowColor = { TB_MENU_DEFAULT_LIGHTER_COLOR, TB_MENU_DEFAULT_DARKEST_COLOR }
								questProgressText:addAdaptedText(true, TB_MENU_LOCALIZED.REWARDSCLAIMSUCCESS, nil, nil, nil, nil, nil, nil, nil, 1)
							else
								TBMenu:showDataError(TB_MENU_LOCALIZED.ERRORTRYAGAIN)
								questProgressBarState:activate()
								questProgressText:addAdaptedText(true, TB_MENU_LOCALIZED.QUESTSCLAIMREWARD, nil, nil, nil, nil, nil, nil, nil, 1)
							end
						end, function()
							questProgressBarState:kill(true)
							TBMenu:showDataError(TB_MENU_LOCALIZED.REWARDSCLAIMNETWORKERROR)
							questProgressBarState:activate()
							questProgressText:addAdaptedText(true, TB_MENU_LOCALIZED.QUESTSCLAIMREWARD, nil, nil, nil, nil, nil, nil, nil, 1)
						end)
				end)
		end
		
		local rewardText = quest.rewarditem and Torishop:getItemInfo(quest.rewarditem).itemname or (quest.rewardtc and (quest.rewardtc .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS) or (quest.rewardst and (quest.rewardst .. " " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS) or ""))
		if (rewardText ~= "") then
			local questRewardText = UIElement:new({
				parent = questBackground,
				pos = { questProgressOutline.shift.x + questProgressOutline.size.w + 10, questTitle.shift.y },
				size = { questBackground.size.w - questProgressOutline.size.w - questProgressOutline.shift.x - 30 - questTitle.size.h, questTitle.size.h }
			})
			questRewardText:addAdaptedText(true, TB_MENU_LOCALIZED.WORDREWARD ..  ": " .. rewardText, nil, nil, 4, RIGHTMID, 0.7)
			local rewardIcon = quest.rewarditem and Torishop:getItemIcon(quest.rewarditem) or (quest.rewardtc and "../textures/store/toricredit.tga" or "../textures/store/shiaitoken.tga")
			local questRewardIcon = UIElement:new({
				parent = questBackground,
				pos = { questRewardText.shift.x + questRewardText.size.w + 10, 5 },
				size = { questBackground.size.h - 10, questBackground.size.h - 10 },
				bgImage = rewardIcon
			})
		end
		
		if (quest.description) then
			local questDescHolder = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, questDescHolder)
			local questDescBackground = UIElement:new({
				parent = questDescHolder,
				pos = { 10, 0 },
				size = { questDescHolder.size.w - 12, questDescHolder.size.h - 3 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			})
			local questDescText = UIElement:new({
				parent = questDescBackground,
				pos = { 10, 5 },
				size = { questDescBackground.size.w - 20, questDescBackground.size.h - 10 }
			})
			questDescText:addAdaptedText(true, quest.description, nil, nil, 4, LEFT, 0.7)
		end
	end
	
	function Quests:showGlobalQuests(questsData, completed)
		tbMenuCurrentSection:kill(true)
		local completed = completed or false
		
		local elementHeight = 60
		local mainHolder = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(mainHolder, elementHeight, elementHeight - 16, 20, TB_MENU_DEFAULT_BG_COLOR)
		
		local questsHeader = UIElement:new({
			parent = topBar,
			pos = { 15, 13 },
			size = { topBar.size.w - 30, topBar.size.h - 26 }
		})
		questsHeader:addAdaptedText(true, TB_MENU_LOCALIZED.QUESTSGLOBAL, nil, nil, FONTS.BIG, LEFTMID)
		TBMenu:addBottomBloodSmudge(botBar)
		
		local listElements = {}
		local shownQuests = { count = 0 }
		local shownSections = {}
		
		if (not completed) then
			local availableQuests = 0
			local closestAndAvailableQuests = UIElement:new({
				parent = listingHolder,
				pos = { 20, #listElements * elementHeight },
				size = { listingHolder.size.w - 40, elementHeight }
			})
			closestAndAvailableQuests:addAdaptedText(false, TB_MENU_LOCALIZED.QUESTSCLOSEST, nil, nil, nil, LEFTMID)
			table.insert(listElements, closestAndAvailableQuests)
			for i, quest in pairs(UIElement:qsort(questsData, { "progresspercentage", "requirement" })) do
				if (quest.available and not quest.claimed) then
					availableQuests = availableQuests + 1
					if (not shownSections[quest.type]) then
						Quests:showGlobalQuestButton(quest, listingHolder, listElements, elementHeight)
						shownQuests[quest.id] = true
						if (quest.modreq == 0) then
							shownSections[quest.type] = true
						else
							shownSections[quest.type] = {}
							shownSections[quest.type][quest.modreq] = true
						end
						shownQuests.count = shownQuests.count + 1
					elseif (quest.progress > quest.requirement) then
						Quests:showGlobalQuestButton(quest, listingHolder, listElements, elementHeight)
						shownQuests[quest.id] = true
						shownQuests.count = shownQuests.count + 1
					elseif (type(shownSections[quest.type]) == "table") then
						if (not shownSections[quest.type][quest.modreq]) then
							Quests:showGlobalQuestButton(quest, listingHolder, listElements, elementHeight)
							shownQuests[quest.id] = true
							shownSections[quest.type][quest.modreq] = true
							shownQuests.count = shownQuests.count + 1
						end
					end
				end
			end
			if (shownQuests.count == 0) then
				closestAndAvailableQuests:kill()
				table.remove(listElements)
			end
			if (shownQuests.count < availableQuests) then
				local lockedQuestsSeparator = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				lockedQuestsSeparator:addCustomDisplay(true, function() end)
				table.insert(listElements, lockedQuestsSeparator)
				local lockedQuests = UIElement:new({
					parent = listingHolder,
					pos = { 20, #listElements * elementHeight },
					size = { listingHolder.size.w - 40, elementHeight }
				})
				lockedQuests:addAdaptedText(false, TB_MENU_LOCALIZED.QUESTSLOCKED, nil, nil, nil, LEFTMID)
				table.insert(listElements, lockedQuests)
			end
		end
		
		for i, quest in pairs(questsData) do
			if (completed == quest.claimed and not shownQuests[quest.id] and (quest.claimed or quest.available)) then
				Quests:showGlobalQuestButton(quest, listingHolder, listElements, elementHeight)
			end
		end
		
		if (#listElements == 0) then
			listingHolder:addAdaptedText(true, TB_MENU_LOCALIZED.QUESTSGLOBALEMPTY)
			return
		end
		
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
	end
	
	function Quests:showQuests()
		tbMenuCurrentSection:kill(true)
		if (TB_MENU_QUESTS_NEW) then
			TB_MENU_QUESTS_NEW = false
			TB_MENU_NOTIFICATIONS_COUNT = TB_MENU_NOTIFICATIONS_COUNT - 1
		end
		local globalQuests = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w / 7 * 2 - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			interactive = true,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverSound = 31
		})
		
		local questsToClaimIcon = nil
		if (TB_MENU_QUESTS_GLOBAL_COUNT > 0) then
			questsToClaimIcon = UIElement:new({
				parent = globalQuests,
				pos = { globalQuests.size.w / 6, globalQuests.size.h / 7 * 2 },
				size = { globalQuests.size.w / 5, globalQuests.size.w / 5 },
				shapeType = ROUNDED,
				rounded = globalQuests.size.w / 5,
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			questsToClaimIcon:addCustomDisplay(false, function()
					questsToClaimIcon:uiText("!", nil, nil, FONTS.BIG)
				end)
		end
		TBMenu:showHomeButton(globalQuests, {
				title = TB_MENU_LOCALIZED.QUESTSGLOBAL,
				subtitle = TB_MENU_LOCALIZED.QUESTSGLOBALDESC,
				ratio = 1,
				image = "../textures/menu/modmaker.tga",
				mode = ORIENTATION_PORTRAIT,
				action = function() 
						Quests:prepareGlobalQuests()
					end
			}, 1, questsToClaimIcon)
		if (questsToClaimIcon) then
			questsToClaimIcon:hide()
			questsToClaimIcon:show()
		end
		
		local questsHolder = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { globalQuests.size.w + globalQuests.shift.x + 5, 0 },
			size = { tbMenuCurrentSection.size.w - globalQuests.size.w - globalQuests.shift.x - 5, tbMenuCurrentSection.size.h }
		})
		for i, quest in pairs(QUESTS_DATA) do
			local questView = UIElement:new({
				parent = questsHolder,
				pos = { 5 + (i - 1) * questsHolder.size.w / #QUESTS_DATA, 0 },
				size = { questsHolder.size.w / #QUESTS_DATA - 10, questsHolder.size.h },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			local bottomSmudge = TBMenu:addBottomBloodSmudge(questView, i)
			Quests:showQuest(questView, quest, bottomSmudge)
		end
	end
	
	function Quests:showMain(reload)
		tbMenuCurrentSection:kill(true)
		if (QUESTS_DATA and not reload and not TB_MENU_DEBUG) then
			Quests:showQuests()
		else
			if (reload or TB_MENU_DEBUG) then
				QUESTS_UPDATE_CLOCK = os.clock()
				download_quest(TB_MENU_PLAYER_INFO.username)
			end
			local file = Files:open("../data/quest.txt")
			local waitView = UIElement:new({
				parent = tbMenuCurrentSection,
				pos = { 5, 0 },
				size = { tbMenuCurrentSection.size.w - 10, tbMenuCurrentSection.size.h },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			TBMenu:addBottomBloodSmudge(waitView, 1)
			waitView:addCustomDisplay(false, function()
					waitView:uiText(TB_MENU_LOCALIZED.QUESTSUPDATING)
					if (not file:isDownloading()) then
						file:close()
						QUESTS_DATA = Quests:getQuests()
						QUEST_REFRESH_CLAIMED = false
						if (waitView and not waitView.destroyed) then
							Quests:showQuests()
						end
					end
				end)
		end
	end
end
