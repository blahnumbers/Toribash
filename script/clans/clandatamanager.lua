-- clan data manager class

dofile("clans/errors.lua")

DEAD = 0
ALIVE = 1
ACTIVE = 2

CLANLOGODEFAULT = "clans/clanLogoDefault.tga"
LOGOCACHE = {}

DEFCOLOR = {0.7, 0.1, 0.1, 1}
DEFHOVCOLOR = {0.8,0.07,0.07,1}

do
	Clan = {}
	Clan.__index = Clan
	
	ClanData = {}
	LevelData = {}
	AchievementData = {}
	
	-- Creates clan class
	function Clan:create(player)
		local cln = {}
		setmetatable(cln, Clan)
	
		if not (player:find('%[') or player:find('%(')) then
			cln.clanid = nil
		elseif (player == nil) then
			cln.clanid = getClanId(get_master().master.nick, true)
		else 
			cln.clanid = getClanId(player)
		end
		return cln
	end
	
	
	-- Populates clan data table
	-- clans/clan.txt is fetched from server
	function Clan:getClanData()
		local entries = 0
		local clans = {}
		local data_types = { "clanname", "clantag", "isofficial", "rank", "clanlevel", "clanxp", "memberstotal", "isfreeforall", "clantopach", "isactive", "members", "leaders" }
		local file = io.open("clans/clans.txt")
		if (file == nil) then
			err(ERR.clanDataEmpty)
			file:close()
			return false
		end
		
		for ln in file:lines() do
			if string.match(ln, "^CLAN") then
				local segments = 14
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				--if (data_stream[12] == "2") then
					local clanid = tonumber(data_stream[2])
					for i = 5, 12 do 
						data_stream[i] = tonumber(data_stream[i])
					end

					data_stream[3] = data_stream[3]:gsub('%W+%d+%W*', '')
					data_stream[4] = data_stream[4]:gsub('%W+%d+%W*', '')
					
					ClanData[clanid] = {}
					
					for i, v in ipairs(data_types) do
						ClanData[clanid][v] = data_stream[i + 2]
					end
					entries = entries + 1
					clans[entries] = clanid
				--end
			end
		end
		
		file:close()
		return clans
	end
	
	function Clan:getLevelData()
		local data_types = { "minxp", "maxmembers", "officialonly" }
		local file = io.open("clans/clanlevels.txt")
		if (file == nil) then
			err(ERR.clanLevelDataEmpty)
			file:close()
			return false
		end
		
		for ln in file:lines() do
			if string.match(ln, "^LEVEL") then
				local segments = 5
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local level = tonumber(data_stream[2])
				LevelData[level] = {}
				
				for i, v in ipairs(data_types) do
					LevelData[level][v] = tonumber(data_stream[i + 2])
				end
			end
		end
		
		file:close()
		return entries
	end
	
	function Clan:getAchievementData()
		local data_types = { "achname", "achdesc" }
		local file = io.open("clans/clanachievements.txt")
		if (file == nil) then
			err(ERR.clanAchievementDataEmpty)
			file:close()
			return false
		end
		
		for ln in file:lines() do
			if string.match(ln, "^ACHIEVEMENT") then
				local segments = 4
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local level = tonumber(data_stream[2])
				AchievementData[level] = {}
				
				for i, v in ipairs(data_types) do
					AchievementData[level][v] = data_stream[i + 2]
				end
			end
		end
		
		file:close()
		return entries
	end
	
	function Clan:showMain()
		clanViewBG = UIElement:new( {	pos = CLANVIEWLASTPOS or {WIN_W/2 - 400, WIN_H/2 - 225},
										size = {800, 450},
										bgColor = {0,0,0,.95},
										shapeType = ROUNDED,
										rounded = 10 } )
		clanView = UIElement:new( {	parent = clanViewBG,
											pos = {4,4},
											bgColor = {0.7,0.1,0.1,1},
											size = {clanViewBG.size.w - 8, clanViewBG.size.h - 8},
											shapeType = clanViewBG.shapeType,
											rounded = clanViewBG.rounded / 3 * 2,
											innerShadow = {0, 5},
											shadowColor = { {0,0,0,0}, {0.5,0.05,0.05,1} } } )
		clanTopBar = UIElement:new( {	parent = clanView,
											pos = {0,0},
											bgColor = {0.6,0,0,1},
											size = {clanView.size.w, 50},
											interactive = true,
											shapeType = clanView.shapeType,
											rounded = clanView.rounded } )
		clanTopBar:addCustomDisplay(false, function()
				draw_quad(clanTopBar.pos.x, clanTopBar.pos.y + clanTopBar.size.h - 10, clanTopBar.size.w, 10)
			end)
		clanTopBar:addMouseHandlers(
			function(s,x,y)
				clanTopBar.pressedPos.x = clanTopBar.pos.x - x - 4
				clanTopBar.pressedPos.y = clanTopBar.pos.y - y - 4
			end, nil, 
			function(x,y)
				if (clanTopBar.hoverState == BTN_DN) then
					local posX = x + clanTopBar.pressedPos.x
					local posY = y + clanTopBar.pressedPos.y
					clanViewBG:moveTo(posX, posY)
					CLANVIEWLASTPOS = { posX, posY }
				end
			end)
		clanViewQuitButton = UIElement:new( {	parent = clanTopBar,
												pos = {-45, 5},
												size = {35, 35},
												bgColor = {0.2,0,0,1},
												interactive = true,
												hoverColor = {0.6,0.4,0.4,1},
												pressedColor = DEFHOVCOLOR,
												shapeType = ROUNDED,
												rounded = 10 } )
		clanViewQuitButton:addMouseHandlers(function() end,
			function()
				remove_hooks("clanVisual")
				--remove_hooks("uiMouseHandler")
				remove_hooks("logodownload")
				clanViewBG:kill()
			end, function() end)
		clanViewQuitButton:addCustomDisplay(false, function()
			local indent = 8
			local weight = 10
			-- Quit button
			if (clanViewQuitButton.hoverState == BTN_DN) then
				set_color(0,0,0,1)
			else
				set_color(1,1,1,1)
			end
			draw_line(clanViewQuitButton.pos.x + indent, clanViewQuitButton.pos.y + indent, clanViewQuitButton.pos.x + clanViewQuitButton.size.w - indent, clanViewQuitButton.pos.y + clanViewQuitButton.size.h - indent, weight)
			draw_line(clanViewQuitButton.pos.x + clanViewQuitButton.size.w - indent, clanViewQuitButton.pos.y + indent, clanViewQuitButton.pos.x + indent, clanViewQuitButton.pos.y + clanViewQuitButton.size.h - indent, weight)
		end)
		clanViewBackButton = UIElement:new( {	parent = clanTopBar,
												pos = {10, 5},
												size = {35, 35},
												bgColor = {0.2,0,0,1},
												interactive = true,
												hoverColor = {0.6,0.4,0.4,1},
												pressedColor = DEFHOVCOLOR,
												shapeType = ROUNDED,
												rounded = 10 } )
		clanViewBackButton:addCustomDisplay(false, function()
			local indent = 4
			local weight = 10
			-- Back button
			if (clanViewBackButton.hoverState == BTN_DN) then
				set_color(0,0,0,1)
			else
				set_color(1,1,1,1)
			end
			draw_line(clanViewBackButton.pos.x + indent * 2, clanViewBackButton.pos.y + clanViewBackButton.size.h / 2, clanViewBackButton.pos.x + clanViewBackButton.size.w - indent, clanViewBackButton.pos.y + clanViewBackButton.size.h / 2, weight)
			draw_disk(clanViewBackButton.pos.x + 14, clanViewBackButton.pos.y + 13.5 + indent, 0, 11, 3, 1, -90, 360, 0)
		end)
		tabName = UIElement:new( {	parent = clanTopBar,
									pos = {clanViewBackButton.size.w + 20,2},
									size = {clanView.size.w - clanViewQuitButton.size.w - clanViewBackButton.size.w - 40, 45} } )
	end
	
	--Displays clan list
	function Clan:showClanList(mode)
		local mode = mode or ACTIVE
		local clans = {}
		
		for i = 1, #allClans do
			if (ClanData[allClans[i]].isactive >= mode) then
				table.insert(clans, allClans[i])
			end
		end
		
		local clanListView = UIElement:new( {	parent = clanView,
												pos = { 0, clanTopBar.size.h },
												size = {clanView.size.w, clanView.size.h - clanTopBar.size.h - 40} } )
												
		local clanListClan = {}
		local clanListClanRank = {}
		local clanListClanTag = {} 
		local clanListClanName = {}
		local clanListClanMembers = {}
		local clanListClanOfficial = {}
		local clanListClanJoinMode = {}
		local listEntryHeight = 40
				
		local clanListClanArea = UIElement:new( {	parent = clanListView,
												pos = {0, -clanListView.size.h + listEntryHeight},
												size = {clanListView.size.w - 25, clanListView.size.h},
												color = {0,0,0,1} } )
		
		local clanListScroll = UIElement:new( {	parent = clanListView,
												pos = {-25, listEntryHeight},
												size = {25, clanListView.size.h - listEntryHeight},
												bgColor = {0.45,0,0,1} } )
		
		local scrollScale = (clanListClanArea.size.h) / (#clans * listEntryHeight)
		local scrollBarInteractive = true
		
		if (scrollScale > 1) then
			scrollScale = 1
			scrollBarInteractive = false
		elseif (scrollScale < 0.1) then
			scrollScale = 0.1
		end
			
		local clanListScrollBar = UIElement:new( {	parent = clanListScroll,
													pos = {2.5, 5},
													size = {20, (clanListScroll.size.h - 10) * scrollScale},
													bgColor = {1,1,1,0.7},
													interactive = scrollBarInteractive,
													hoverColor = {1,1,1,1},
													pressedColor = {1,0,0,0.5},
													scrollEnabled = true } )
		
		for i = 1, #clans do
			local isEven = 0
			if (i / 2 == math.floor(i / 2)) then 
				isEven = 0.1
			end
			clanListClan[i] = UIElement:new( {	parent = clanListClanArea,
												pos = { 0, (i - 1) * listEntryHeight},
												size = { clanListClanArea.size.w, listEntryHeight },
												bgColor = {0.6 + isEven, 0.02 + isEven / 2, 0.02 + isEven / 2, 1},
												interactive = true,
												hoverColor = {0, 0, 0, 0.6},
												pressedColor = {0, 0, 0, 0.15} } )
			clanListClanRank[i] = UIElement:new( {	parent = clanListClan[i],
													pos = {10, 9},
													size = {60, clanListClan[i].size.h} } )
			clanListClanTag[i] = UIElement:new( {	parent = clanListClan[i],
													pos = {80, 9},
													size = {115, clanListClan[i].size.h} } )
			clanListClanName[i] = UIElement:new( {	parent = clanListClan[i],
													pos = {205, 0},
													size = {175, clanListClan[i].size.h + 5} } )
			clanListClanMembers[i] = UIElement:new( {	parent = clanListClan[i],
														pos = {390, 9},
														size = {100, clanListClan[i].size.h - 18} } )
			clanListClanOfficial[i] = UIElement:new( {	parent = clanListClan[i],
														pos = {500, 9},
														size = {100, clanListClan[i].size.h} } )
			clanListClanJoinMode[i] = UIElement:new( {	parent = clanListClan[i],
														pos = {610, 9},
														size = {150, clanListClan[i].size.h} } )
														
			-- run replacement draw function to ensure proper scroll work
			clanListClan[i]:addCustomDisplay(false, function()				
				-- Draw clan info
				local textScaleMod = 0.75
				
				local clanRank = ClanData[clans[i]].rank
				if (clanRank == 0) then 
					clanRank = "-"
				end
				set_color(1,1,1,1)
				clanListClanRank[i]:uiText(clanRank, nil, nil, 4, CENTER, textScaleMod)
				
				local clanTag = "(" .. ClanData[clans[i]].clantag .. ")"
				if (ClanData[clans[i]].isofficial == 1) then
					clanTag = "[" .. ClanData[clans[i]].clantag .. "]"
				end
				clanListClanTag[i]:uiText(clanTag, nil, nil, 4, RIGHT, textScaleMod)
				
				draw_quad(clanListClanName[i].pos.x - 5.5, clanListClanName[i].pos.y + 10, 1, 20)
				local clanName = ClanData[clans[i]].clanname
				if (get_string_length(clanName, FONTS.MEDIUM) * textScaleMod > clanListClanName[i].size.w) then
					clanListClanName[i]:uiText(clanName, clanListClanName[i].pos.x, clanListClanName[i].pos.y, 4, LEFT, textScaleMod)
				else
					clanListClanName[i]:uiText(clanName, clanListClanName[i].pos.x, clanListClanName[i].pos.y + 9, 4, LEFT, textScaleMod)
				end
				
				clanListClanMembers[i]:uiText(ClanData[clans[i]].memberstotal .. "/" .. LevelData[ClanData[clans[i]].clanlevel + 1].maxmembers, clanListClanMembers[i].pos.x, clanListClanMembers[i].pos.y, 4, CENTER, textScaleMod)
				
				if (ClanData[clans[i]].isofficial == 1) then
					clanListClanOfficial[i]:uiText("Official", clanListClanOfficial[i].pos.x, clanListClanOfficial[i].pos.y, 4, CENTER, textScaleMod)
				else 
					clanListClanOfficial[i]:uiText("Unofficial", clanListClanOfficial[i].pos.x, clanListClanOfficial[i].pos.y, 4, CENTER, textScaleMod)
				end
				
				if (ClanData[clans[i]].isfreeforall == 1) then
					clanListClanJoinMode[i]:uiText("Free for all", clanListClanJoinMode[i].pos.x, clanListClanJoinMode[i].pos.y, 4, CENTER, textScaleMod)
				else 
					clanListClanJoinMode[i]:uiText("Invite Only", clanListClanJoinMode[i].pos.x, clanListClanJoinMode[i].pos.y, 4, CENTER, textScaleMod)
				end
				
				if (i ~= #clans) then
					draw_line(clanListClan[i].pos.x, clanListClan[i].pos.y + clanListClan[i].size.h - 1, clanListClan[i].pos.x + clanListClan[i].size.w, clanListClan[i].pos.y + clanListClan[i].size.h - 1, 1)
				end
			end)
			clanListClan[i]:addMouseHandlers(function() end, 
				function()
					CLANLISTLASTPOS = { scroll = clanListScrollBar:getPos(), list = clanListClanArea:getPos() }
					clanListView:kill()
					Clan:showClan(clans[i], true)
				end, function() end)
		end
		
		clanListTopBar = UIElement:new( {	parent = clanListView,
											pos = {0,0},
											bgColor = {0.45,0,0,1},
											size = {clanView.size.w, listEntryHeight},
											interactive = true } )
											
		clanListClanRank[#clans + 1] = UIElement:new( {	parent = clanListTopBar,
												pos = {10, 9},
												size = {60, clanListTopBar.size.h} } )
		clanListClanTag[#clans + 1] = UIElement:new( {	parent = clanListTopBar,
												pos = {80, 9},
												size = {250, clanListTopBar.size.h} } )
		clanListClanMembers[#clans + 1] = UIElement:new( {	parent = clanListTopBar,
													pos = {390, 9},
													size = {100, clanListTopBar.size.h - 18} } )
		clanListClanOfficial[#clans + 1] = UIElement:new( {	parent = clanListTopBar,
													pos = {500, 9},
													size = {100, clanListTopBar.size.h} } )
		clanListClanJoinMode[#clans + 1] = UIElement:new( {	parent = clanListTopBar,
													pos = {610, 9},
													size = {150, clanListTopBar.size.h} } )
		
		clanListTopBar:addCustomDisplay(false, function()
			set_color(1,1,1,1)
			draw_line(clanListTopBar.pos.x, clanListTopBar.pos.y, clanListTopBar.pos.x + clanListTopBar.size.w, clanListTopBar.pos.y, 2)
			clanListClanRank[#clanListClanRank]:uiText("Rank")
			clanListClanTag[#clanListClanTag]:uiText("Clan Name")
			clanListClanMembers[#clanListClanMembers]:uiText("Members")
			clanListClanOfficial[#clanListClanOfficial]:uiText("Status")
			clanListClanJoinMode[#clanListClanJoinMode]:uiText("Join Mode")
		end)
											
		clanListBotBar = UIElement:new( {	parent = clanListView,
											pos = {0,clanListView.size.h},
											bgColor = {0.45,0,0,1},
											size = {clanView.size.w, listEntryHeight},
											shapeType = clanView.shapeType,
											rounded = clanView.rounded,
											interactive = true } )
											
		clanListBotBar:addCustomDisplay(false, function()
				set_color(0.45,0,0,1)
				draw_quad(clanListBotBar.pos.x, clanListBotBar.pos.y, clanListBotBar.size.w, 10)
			end)
		
		local myClan = UIElement:new( {	parent = clanListBotBar,
										pos = { clanListBotBar.size.w / 2 - 150, 3 },
										size = { 300, clanListBotBar.size.h - 6 },
										shapeType = ROUNDED,
										rounded = 5,
										bgColor = DEFCOLOR,
										interactive = true,
										hoverColor = DEFHOVCOLOR,
										pressedColor = {0.6,0,0,1} } )
		if (playerClan ~= 0) then
			myClan:addCustomDisplay(false, function()
				myClan:uiText(ClanData[playerClan].clanname, nil, myClan.pos.y + 4, nil, nil, nil, nil, 1)
			end)
			myClan:addMouseHandlers(function() end,
				function()
					CLANLISTLASTPOS = { scroll = clanListScrollBar:getPos(), list = clanListClanArea:getPos() }
					clanListView:kill()
					Clan:showClan(playerClan, true)
				end, function() end)
		else
			myClan:addCustomDisplay(false, function()
				myClan:uiText("Create new clan", nil, myClan.pos.y + 4, nil, nil, nil, nil, 1)
			end)
			myClan:addMouseHandlers(function() end,
				function()
					open_url("http://forum.toribash.com/clan_register.php")
				end, function() end)
		end
		
		clanListScrollBar.pressedPos = { x = 0, y = 0 }
		
		clanListScrollBar:addScrollFor(clanListClanArea, clanListClan, clanListTopBar, clanListBotBar, CLANLISTLASTPOS.list[2], CLANLISTLASTPOS.scroll[2])
		
		clanViewBackButton:addMouseHandlers(function() end,	function() end, function() end)
		clanViewBackButton:hide()
		tabName:addCustomDisplay(false, function()
			--[[local modeStr = "Active"
			if (mode == DEAD) then
				modeStr = "All"
			elseif (mode == ALIVE) then
				modeStr = "Alive"
			end
			tabName:uiText("Clan List - " .. modeStr, tabName.pos.x, tabName.pos.y, FONTS.BIG, CENTER, 0.7)--]]
			tabName:uiText("Clan List", tabName.pos.x, tabName.pos.y, FONTS.BIG, CENTER, 0.7, nil, 1.5)
			end)			
	end
	
	-- Displays single clan data
	function Clan:showClan(clanid, logoReload)
		local logoReload = logoReload or nil
		local clanLevelValue = ClanData[clanid].clanlevel
		local clanTopAch = ClanData[clanid].clantopach
		local xpBarProgress = (ClanData[clanid].clanxp - LevelData[clanLevelValue].minxp) / (LevelData[clanLevelValue + 1].minxp - LevelData[clanLevelValue].minxp)
		if (xpBarProgress > 1) then
			xpBarProgress = 1
		end
		local elementBgColor = {0,0,0,0.1}
		
		local clanInfoView = UIElement:new( {	parent = clanView,
												pos = { 265, clanTopBar.size.h + 10 },
												size = { clanView.size.w - 275, clanView.size.h - clanTopBar.size.h - 20},
												bgColor = elementBgColor,
												shapeType = ROUNDED,
												rounded = 10 } )
		local clanInfoRightView = UIElement:new( {	parent = clanView,
													pos = { 10, clanTopBar.size.h + 10 },
													size = { 250, clanView.size.h - clanTopBar.size.h - 20 } } )
		local clanLevel = UIElement:new( {	parent = clanInfoView,
											pos = {0, 5},
											size = {clanInfoView.size.w, 35} } )
		clanLevel:addCustomDisplay(false, function()
			clanLevel:uiText("Clan Level " .. clanLevelValue, clanLevel.pos.x, clanLevel.pos.y, FONTS.BIG, CENTER, 0.6, nil, 1.5)
			end)
		local clanXpBarOutline = UIElement:new( {	parent = clanInfoView,
													pos = {10, 45},
													size = {clanInfoView.size.w - 20, 50},
													bgColor = { 0.1, 0.1, 0.1, 0.5 },
													shapeType = ROUNDED,
													rounded = 10 } )
		local clanXpBar = UIElement:new( {	parent = clanXpBarOutline,
											pos = {2, 2},
											size = {clanXpBarOutline.size.w - 4, clanXpBarOutline.size.h - 4},
											bgColor = {0.5, 0.1, 0.1, 1},
											shapeType = clanXpBarOutline.shapeType,
											rounded = clanXpBarOutline.rounded / 5 * 4 } )
		local clanXpBarProgress
		if (xpBarProgress > 0) then
			clanXpBarProgress = UIElement:new( {	parent = clanXpBar,
													pos = {0, 0},
													size = {clanXpBar.size.w * xpBarProgress, clanXpBar.size.h},
													bgColor = {0.78,0.05,0.08,1},
													shapeType = clanXpBar.shapeType,
													rounded = clanXpBar.rounded,
													innerShadow = { 4, 4 },
													shadowColor = { { 0.91, 0.34, 0.24, 1 }, { 0.33, 0, 0, 1 } } } )
		end
		
		local clanXp = UIElement:new( {	parent = clanXpBar,
										pos = {0, 8},
										size = {clanInfoView.size.w, 25} } )
		clanXp:addCustomDisplay(false, function()
			clanXp:uiText(ClanData[clanid].clanxp .. " / " .. LevelData[clanLevelValue + 1].minxp .. " XP", clanXp.pos.x, clanXp.pos.y, FONTS.BIG, CENTER, 0.5, nil, 1.5)
		end)
		local clanForumLinkOutline = UIElement:new( {	parent = clanInfoView,
														pos = {clanInfoView.size.w / 2 - 150, -60},
														size = {300, 50},
														bgColor = {0.1,0.1,0.1,0.5},
														shapeType = ROUNDED,
														rounded = 10 } )
		local clanForumLink = UIElement:new( {	parent = clanForumLinkOutline,
												pos = {2, 2},
												size = {clanForumLinkOutline.size.w - 4, clanForumLinkOutline.size.h - 4},
												bgColor = DEFCOLOR,
												interactive = true,
												hoverColor = DEFHOVCOLOR,
												pressedColor = {0.6,0,0,1},
												shapeType = clanForumLinkOutline.shapeType,
												rounded = clanForumLinkOutline.rounded / 5 * 4 } )
		clanForumLink:addMouseHandlers(nil,
			function()
				open_url("http://forum.toribash.com/clan.php?clanid="..clanid)
			end, nil)
		clanForumLink:addCustomDisplay(false, function()
			clanForumLink:uiText("Clan page on forum", clanForumLink.pos.x, clanForumLink.pos.y + 10, FONTS.MEDIUM, CENTER, 1, nil, 1)
		end)
		local clanMembersOutline = UIElement:new( {	parent = clanInfoView,
													pos = { 10, clanLevel.size.h + clanXpBarOutline.size.h + 20 },
													size = {clanInfoView.size.w - 20, 90},
													bgColor = {0.1,0.1,0.1,0.5},
													shapeType = ROUNDED,
													rounded = 10 } )
		local clanMembers = UIElement:new( {	parent = clanMembersOutline,
												pos = {2,2},
												size = {clanMembersOutline.size.w - 4, clanMembersOutline.size.h - 4},
												bgColor = DEFCOLOR,
												interactive = true,
												hoverColor = DEFHOVCOLOR,
												pressedColor = {0.6,0,0,1},
												shapeType = clanMembersOutline.shapeType,
												rounded = clanMembersOutline.rounded / 5 * 4 } )
		clanMembers:addCustomDisplay(false, function()
			clanMembers:uiText("Clan Roster", clanMembers.pos.x, clanMembers.pos.y + 5, FONTS.BIG, CENTER, 0.5, nil, 1.5)
			clanMembers:uiText("Click to see all clan members", clanMembers.pos.x, clanMembers.pos.y + 45, FONTS.MEDIUM, CENTER, 0.9, nil, 1)
		end)
		clanMembers:addMouseHandlers(nil,
			function()
				clanInfoView:kill()
				clanInfoRightView:kill()
				remove_hooks("logodownload")
				Clan:showMembers(clanid)
			end, nil)
		local clanTopAchievementOutline = UIElement:new( {	parent = clanInfoView,
															pos = { 10, 205 },
															size = {clanInfoView.size.w - 20, 100},
															bgColor = {0.1,0.1,0.1,0.5},
															shapeType = ROUNDED,
															rounded = 10 } )
		local clanTopAchievement = UIElement:new( {	parent = clanTopAchievementOutline,
													pos = {2,2},
													size = {clanTopAchievementOutline.size.w - 4, clanTopAchievementOutline.size.h - 4},
													bgColor = DEFCOLOR,
													shapeType = clanTopAchievementOutline.shapeType,
													rounded = clanTopAchievementOutline.rounded / 5 * 4 } )
		if (clanTopAch ~= 0) then
			local clanTopAchIcon = UIElement:new( {	parent = clanTopAchievement,
												pos = {10, 8},
												size = {80,80},
												bgImage = "/clans/achievements/"..clanTopAch..".tga" } )
			local clanTopAchName = UIElement:new( {	parent = clanTopAchievement,
												pos = {100, 5},
												size = {clanTopAchievement.size.w - 110, 20} } )
			clanTopAchName:addCustomDisplay(false, function()
				clanTopAchName:uiText(AchievementData[clanTopAch].achname, clanTopAchName.pos.x, clanTopAchName.pos.y, FONTS.MEDIUM, CENTER, 1, nil, 1)
			end)
			local clanTopAchDesc = UIElement:new( {	parent = clanTopAchievement,
													pos = {100, 30},
													size = {clanTopAchievement.size.w - 110, 66} } )
			clanTopAchDesc:addCustomDisplay(false, function()
				clanTopAchDesc:uiText(AchievementData[clanTopAch].achdesc, clanTopAchDesc.pos.x, clanTopAchDesc.pos.y, 4, CENTER, 0.75)
			end)
		else
			local clanTopAchDesc = UIElement:new( {	parent = clanTopAchievement,
												pos = {50, 25},
												size = {clanTopAchievement.size.w - 100, 50} } )
			clanTopAchDesc:addCustomDisplay(false,
				function()
					clanTopAchDesc:uiText("This clan hasnt chosen an achievement to display", clanTopAchDesc.pos.x, clanTopAchDesc.pos.y, FONTS.MEDIUM, CENTER, 1, nil, 1)
				end)
		end
		local clanRank = UIElement:new( {	parent = clanInfoRightView,
											pos = { 0, 0 },
											size = { clanInfoRightView.size.w, 50 },
											bgColor = elementBgColor,
											shapeType = ROUNDED,
											rounded = 10 } )
		local clanRankText = "Rank "..ClanData[clanid].rank
		if (ClanData[clanid].rank < 1) then
			clanRankText = "Unranked"
		end
		clanRank:addCustomDisplay(false, function()
			clanRank:uiText(clanRankText, nil, clanRank.pos.y + 7, FONTS.BIG, CENTER, 0.6, nil, 1.5)
		end)
		local clanLogo = UIElement:new( {	parent = clanInfoRightView,
											pos = { 0, clanRank.size.h + 5 },
											size = { 250, 250 },
											bgColor = elementBgColor,
											bgImage =  { "../textures/clans/"..clanid..".tga", CLANLOGODEFAULT },
											shapeType = ROUNDED,
											rounded = 10 } )
		if (logoReload == true) then 
			loadClanLogo(clanid, clanLogo)
		end
		local clanJoin = UIElement:new( {	parent = clanInfoRightView,
											pos = { 0, clanRank.size.h + clanLogo.size.h + 10 },
											size = { 250, 62 },
											bgColor = elementBgColor,
											shapeType = ROUNDED,
											rounded = 10 } )
		local clanJoinButtonOutline = nil
		local clanJoinButton = nil
		if (ClanData[clanid].isfreeforall == 1 and FREEJOINENABLED) then
			clanJoinButtonOutline = UIElement:new( {	parent = clanJoin,
														pos = { 10, 10 },
														size = {clanJoin.size.w - 20, clanJoin.size.h - 20},
														bgColor = {0.1,0.1,0.1,0.5},
														shapeType = ROUNDED,
														rounded = 10 } )
			clanJoinButton = UIElement:new( {	parent = clanJoinButtonOutline,
												pos = { 2, 2 },
												size = {clanJoinButtonOutline.size.w - 4, clanJoinButtonOutline.size.h - 4},
												bgColor = DEFCOLOR,
												interactive = true,
												hoverColor = DEFHOVCOLOR,
												pressedColor = {0.6,0,0,1},
												shapeType = clanJoinButtonOutline.shapeType,
												rounded = clanJoinButtonOutline.rounded / 5 * 4 } )
			clanJoinButton:addCustomDisplay(false, function()
				clanJoinButton:uiText("Join Clan", clanJoinButton.pos.x, clanJoinButton.pos.y + 5, FONTS.MEDIUM, CENTER, nil, nil, 1)
			end)
			clanJoinButton:addMouseHandlers(nil,
				function()
				open_url("http://forum.toribash.com/clan.php?clanid="..clanid.."&join=1")
			end, nil)
		elseif (ClanData[clanid].isfreeforall == 1) then
			clanJoin:addCustomDisplay(false, function()
				clanJoin:uiText("Free to join", clanJoin.pos.x, clanJoin.pos.y + 15, FONTS.MEDIUM, CENTER, nil, nil, 1)
			end)
		else
			clanJoin:addCustomDisplay(false, function()
				clanJoin:uiText("Invite Only", clanJoin.pos.x, clanJoin.pos.y + 15, FONTS.MEDIUM, CENTER, nil, nil, 1)
			end)
		end

		clanViewBackButton:show()
		clanViewBackButton:addMouseHandlers(function() end, function()
			clanInfoView:kill()
			clanInfoRightView:kill()
			remove_hooks("logodownload")
			Clan:showClanList()
			end, function() end)
		tabName:addCustomDisplay(false, function()
			local clanNameStr = nil
			if (ClanData[clanid].isofficial == 1) then
				clanNameStr = "[" .. ClanData[clanid].clantag .. "] " .. ClanData[clanid].clanname
			else
				clanNameStr = "(" .. ClanData[clanid].clantag .. ") " .. ClanData[clanid].clanname
			end
			tabName:uiText(clanNameStr, tabName.pos.x, tabName.pos.y, FONTS.BIG, CENTER, 0.7, nil, 1.5)
			end)
	end
	
	-- Displays clan members and leaders
	function Clan:showMembers(clanid)
		local elementBgColor = {0,0,0,0.1}
		local clanLeadersView = UIElement:new( {	parent = clanView,
													pos = { 10, clanTopBar.size.h + 10 },
													size = { 200, clanView.size.h - clanTopBar.size.h - 20 },
													bgColor = elementBgColor,
													shapeType = ROUNDED,
													rounded = 10 } )
		local clanMembersView = UIElement:new( {	parent = clanView,
													pos = { clanLeadersView.size.w + 20, clanTopBar.size.h + 10 },
													size = { clanView.size.w - clanLeadersView.size.w - 30, clanView.size.h - clanTopBar.size.h - 20 },
													bgColor = elementBgColor,
													shapeType = ROUNDED,
													rounded = 10 } )
		local clanLeadersCaption = UIElement:new( {	parent = clanLeadersView,
													pos = {0, 0},
													size = {clanLeadersView.size.w, 25} } )
		clanLeadersCaption:addCustomDisplay(false, function()
			if (ClanData[clanid].leaders:match("%s")) then
				clanLeadersCaption:uiText("Leaders", clanLeadersCaption.pos.x, clanLeadersCaption.pos.y, FONTS.BIG, CENTER, 0.6, nil, 1.5)
			else
				clanLeadersCaption:uiText("Leader", clanLeadersCaption.pos.x, clanLeadersCaption.pos.y, FONTS.BIG, CENTER, 0.6, nil, 1.5)
			end
		end)
		local clanMembersCaption = UIElement:new( {	parent = clanMembersView,
													pos = {0, 0},
													size = {clanMembersView.size.w, 25} } )
		clanMembersCaption:addCustomDisplay(false, function()
			clanMembersCaption:uiText("Members", clanMembersCaption.pos.x, clanMembersCaption.pos.y, FONTS.BIG, CENTER, 0.6, nil, 1.5)
		end)
		local clanLeaders = UIElement:new( {	parent = clanLeadersView,
												pos = {10, clanLeadersCaption.size.h + 15},
												size = {clanLeadersView.size.w - 20, clanLeadersView.size.h - clanLeadersCaption.size.h - 25} } )
		local clanLeadersAll = textAdapt(ClanData[clanid].leaders, FONTS.MEDIUM, 1, 20)
		local clanLeadersList = {}
		for i = 1, #clanLeadersAll do
			if (i * 25 > clanLeaders.size.h) then
				break
			end
			clanLeadersList[i] = UIElement:new( {	parent = clanLeaders,
													pos = {0, (i-1)*25},
													size = {clanLeaders.size.w, 25},
													bgColor = {1,1,1,1},
													interactive = true,
													hoverColor = {0.8,0.8,0.8,1},
													pressedColor = {0.4,0.4,0.4,1} } )
			clanLeadersList[i]:addCustomDisplay(true, function()
				local color = clanLeadersList[i]:getButtonColor()
				clanLeadersList[i]:uiText(clanLeadersAll[i], clanLeadersList[i].pos.x, clanLeadersList[i].pos.y, FONTS.MEDIUM, CENTER, nil, nil, 1, color)
			end)
			clanLeadersList[i]:addMouseHandlers(nil, function()
				open_url("http://forum.toribash.com/member.php?username="..clanLeadersAll[i])
			end, nil)
		end
		local clanMembers = UIElement:new( {	parent = clanMembersView,
												pos = {10, clanMembersCaption.size.h + 10},
												size = {clanMembersView.size.w - 20, clanMembersView.size.h - clanMembersCaption.size.h - 20} } )
		local clanMembersAll = textAdapt(ClanData[clanid].members, FONTS.MEDIUM, 1, 30)
		local clanMembersList = {}
		local memberPos = { x = 0, y = -25 }
		for i = 1, #clanMembersAll do
			memberPos.y = memberPos.y + 30
			if (memberPos.x + 320 > clanMembers.size.w and memberPos.y + 60 > clanMembers.size.h) then
				clanMembersList[i] = UIElement:new ( {	parent = clanMembers,
														pos = {-160, -40},
														size = {160, 40},
														bgColor = {0.1,0.1,0.1,0.5},
														shapeType = ROUNDED,
														rounded = 10 } )
				clanMembersList[i + 1] = UIElement:new ( {	parent = clanMembersList[i],
														pos = {2, 2},
														size = {clanMembersList[i].size.w - 4, clanMembersList[i].size.h - 4},
														bgColor = {1,1,1,.5},
														shapeType = ROUNDED,
														rounded = 8,
														interactive = true,
														hoverColor = {0.8,0.8,0.8,.5},
														pressedColor = {0.4,0.4,0.4,.5} } )
				clanMembersList[i + 1]:addCustomDisplay(false, function()
					clanMembersList[i + 1]:uiText("View All", clanMembersList[i].pos.x, clanMembersList[i].pos.y + 6, FONTS.MEDIUM, CENTER, nil, nil, 1)
				end)
				clanMembersList[i + 1]:addMouseHandlers(nil, function()
					open_url("http://forum.toribash.com/clan.php?clanid="..clanid)
				end, nil)
				break
			end--]]
			if (memberPos.y + 50 > clanMembers.size.h) then
				memberPos.x = memberPos.x + 160
				memberPos.y = 5
			end
			clanMembersList[i] = UIElement:new( {	parent = clanMembers,
													pos = {memberPos.x, memberPos.y},
													size = {160, 40},
													bgColor = {1,1,1,1},
													interactive = true,
													hoverColor = {0.8,0.8,0.8,1},
													pressedColor = {0.4,0.4,0.4,1} } )
			clanMembersList[i]:addCustomDisplay(true, function()
				local color = clanMembersList[i]:getButtonColor()
				clanMembersList[i]:uiText(clanMembersAll[i], clanMembersList[i].pos.x, clanMembersList[i].pos.y, FONTS.MEDIUM, LEFT, nil, nil, 1, color)
			end)
			clanMembersList[i]:addMouseHandlers(nil, function()
				open_url("http://forum.toribash.com/member.php?username="..clanMembersAll[i])
			end, nil)
		end
		
		clanViewBackButton:addMouseHandlers(function() end,
			function()
				Clan:showClan(clanid, true)
				clanLeadersView:kill()
				clanMembersView:kill()
			end, function() end)
		tabName:addCustomDisplay(false, function()
			local clanNameStr = nil
			if (ClanData[clanid].isofficial == 1) then
				clanNameStr = "[" .. ClanData[clanid].clantag .. "] Clan Roster"
			else
				clanNameStr = "(" .. ClanData[clanid].clantag .. ") Clan Roster"
			end
			tabName:uiText(clanNameStr, tabName.pos.x, tabName.pos.y, FONTS.BIG, CENTER, 0.7, nil, 1.5)
			end)
	end
	

	function getClanId(player, ownData)
		local ownData = ownData or false
		local str = "[%)%]]"
		local strMatch = string.find(player, str)
		local tag = string.sub(player, 2, strMatch - 1)
		
		if (ownData) then
			return Clan:getPlayerClan()
		end
		
		for i = 1, #allClans do
			if (string.lower(ClanData[allClans[i]].clantag) == string.lower(tag)) then
				return allClans[i]
			end
		end
	end
	
	function Clan:getPlayerClan()
		add_hook("console", "consoletext", function(s,i)
			remove_hooks("consoletext")
			return 1
		end)
		
		local player_name = get_master().master.nick
		if (player_name == "") then
			return 0
		end
		player_name = player_name:gsub("%b{}", "")
		player_name = player_name:gsub("%b[]", "")
		player_name = player_name:gsub("%b()", "")
		
		local file = io.open("custom/" .. player_name .. "/item.dat", 'r', 1)
		
		if (file == nil) then
			err(ERR.playerFolderPerms)
			return 0
		end
					
		for ln in file:lines() do
			if string.match(ln, "CLAN 0;") then
				local clanid = string.gsub(ln, "CLAN 0;", "")
				local clanid = clanid:match("%d+");
				clanid = tonumber(clanid)
				file:close()
				return clanid
			end
		end
		err(ERR.playerFolderClan)
		file:close()
		return 0
	end
	
	function loadClanLogo(clanid, element)
		for i = 1, #LOGOCACHE do
			if (LOGOCACHE[i] == clanid) then
				return
			end
		end
		
		download_clan_logo(clanid)
		local rotation = 0
		local scale = 0
		local transparency = 0.8
		add_hook("draw2d", "logodownload", function()
			local downloads = get_downloads()
				set_color(0,0,0,transparency - 0.4)
				draw_quad(element.pos.x, element.pos.y + element.size.h - 30, element.size.w, 30)
				set_color(1,1,1,transparency)
				draw_disk(element.pos.x + 65, element.pos.y + element.size.h - 15, 6, 12, 200, 1, rotation, scale, 0)
				rotation = rotation + 2.5
				scale = scale + 5
				if (scale > 360) then
					scale = -360
				end
				draw_text("Updating", element.pos.x + 90, element.pos.y + element.size.h - 28, FONTS.MEDIUM)
				draw_text("Updating", element.pos.x + 90, element.pos.y + element.size.h - 28, FONTS.MEDIUM)
			if (table.getn(downloads) == 0) then
				if (transparency == 0.8) then
					element:updateImage("../textures/clans/"..clanid..".tga", CLANLOGODEFAULT)
				end
				transparency = transparency - 0.05
				if (transparency <= 0) then
					table.insert(LOGOCACHE, clanid)
					remove_hooks("logodownload")
				end
			end
		end)
	end
	
	function Clan:drawVisuals()
		for i, v in pairs(UIElementManager) do
			v:updatePos()
		end
		for i, v in pairs(UIVisualManager) do
			v:display()
		end
	end
end