-- clan data manager class
dofile("clans/errors.lua")

DEAD = 0
ALIVE = 1
ACTIVE = 2

CLANLOGODEFAULT = "../textures/clans/default.tga"
LOGOCACHE = LOGOCACHE or {}
AVATARCACHE = AVATARCACHE or {}

DEFCOLOR = {0.7, 0.1, 0.1, 1}
DEFHOVCOLOR = {0.8,0.07,0.07,1}

CLANLISTSHIFT = CLANLISTSHIFT or { 0 }
CLANSEARCHFILTERS = CLANSEARCHFILTERS or nil

do
	Clans = {}
	Clans.__index = Clans
	local cln = {}
	setmetatable(cln, Clans)
	
	ClanData = {}
	LevelData = {}
	AchievementData = {}
		
	-- Populates clan data table
	-- clans/clan.txt is fetched from server
	function Clans:getClanData()
		local entries = 0
		local clans = {}
		local data_types = { "id", "name", "tag", "isofficial", "rank", "level", "xp", "memberstotal", "isfreeforall", "topach", "isactive", "members", "leaders" }
		local file = io.open("clans/clans.txt")
		if (file == nil) then
			err(ERR.clanDataEmpty)
			return false
		end
		
		for ln in file:lines() do
			if string.match(ln, "^CLAN") then
				local segments = 14
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				if (not data_stream[3]:match("^#") and not (data_stream[5] == "0" and data_stream[12] == "0")) then -- Ignore unofficial dead clans
					data_stream[2] = tonumber(data_stream[2])
					for i = 5, 12 do 
						data_stream[i] = tonumber(data_stream[i])
					end
					
					local clanid = data_stream[2]
					ClanData[clanid] = {}
					for i = 2, #data_types - 1 do
						ClanData[clanid][data_types[i - 1]] = data_stream[i]
					end
					local members, leaders = data_stream[13], data_stream[14]
					ClanData[clanid].members, ClanData[clanid].leaders = {}, {}
					for word in members:gmatch("%S+") do table.insert(ClanData[clanid].members, word) end
					for word in leaders:gmatch("%S+") do table.insert(ClanData[clanid].leaders, word) end
				end
			end
		end
		file:close()
	end
	
	function Clans:getLevelData()
		local data_types = { "minxp", "maxmembers", "officialonly" }
		local file = io.open("clans/clanlevels.txt")
		if (file == nil) then
			err(ERR.clanLevelDataEmpty)
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
	end
	
	function Clans:getAchievementData()
		local data_types = { "achname", "achdesc" }
		local file = io.open("clans/clanachievements.txt")
		if (file == nil) then
			err(ERR.clanAchievementDataEmpty)
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
	end
	
	function Clans:quit()
		tbMenuCurrentSection:kill(true) 
		tbMenuNavigationBar:kill()
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
		
	function Clans:getNavigationButtons(showBack)
		local buttonsData = {
			{ 
				text = "To Main", 
				action = function() Clans:quit() end, 
				width = 160 
			}
		}
		if (showBack) then
			local backButton = {
				text = "Back",
				action = function() Clans:showMain(tbMenuCurrentSection) end,
				width = 130
			}
			table.insert(buttonsData, backButton)
		end
		return buttonsData
	end
	
	function Clans:showMain(viewElement)
		viewElement:kill(true)
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Clans:getNavigationButtons(), true)
		local clanListSettings = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.3 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Clans:showUserClan(clanListSettings)
		local clanView = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w * 0.3 + 5, 0 },
			size = { viewElement.size.w * 0.7 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Clans:showClanList(clanView)
	end
	
	function Clans:showUserClan(viewElement)
		local clanUserBotSmudge = TBMenu:addBottomBloodSmudge(viewElement, 1)
		local clanid = TB_MENU_PLAYER_INFO.clan.id
		if (clanid ~= 0) then
			local userClanTitle = UIElement:new({
				parent = viewElement,
				pos = { 0, 0 },
				size = { viewElement.size.w, 50 }
			})
			userClanTitle:addCustomDisplay(true, function()
					userClanTitle:uiText("My Clan", nil, nil, FONTS.BIG, nil, 0.7, nil, nil, nil, nil, 0.2)
				end)
			local buttonHeight = 80
			local clanView = UIElement:new({
				parent = viewElement,
				pos = { 0, userClanTitle.size.h + 10 },
				size = { viewElement.size.w, viewElement.size.h - userClanTitle.size.h - buttonHeight - 20 }
			})
			local heightMod = 0
			if (clanView.size.h / 2 - 10 > 60) then
				local iconSize = clanView.size.w - 75 - buttonHeight > 256 and 256 or clanView.size.w - 75 - buttonHeight
				local clanLogo = UIElement:new({
					parent = clanView,
					pos = { (clanView.size.w - iconSize) / 2, 0 },
					size = { iconSize, iconSize },
					bgImage =  { "../textures/clans/"..clanid..".tga", CLANLOGODEFAULT }
				})
				heightMod = iconSize
				Clans:loadClanLogo(clanid, clanLogo)
			end
			local clanName = UIElement:new({
				parent = clanView,
				pos = { 0, heightMod },
				size = { clanView.size.w, 30 }
			})
			clanName:addCustomDisplay(true, function()
					clanName:uiText(TB_MENU_PLAYER_INFO.clan.name, nil, nil, FONTS.BIG, nil, 0.5)
				end)
			local memberStatus = UIElement:new({
				parent = clanView,
				pos = { 0, clanName.shift.y + clanName.size.h },
				size = { clanView.size.w, 25 },
			})
			if (TB_MENU_PLAYER_INFO.clan.isleader) then
				memberStatus:addCustomDisplay(true, function()
						memberStatus:uiText("Clan leader", nil, nil, 4, CENTERMID, 0.7)
					end)
				local otherMembers = UIElement:new({
					parent = clanView,
					pos = { 0, memberStatus.shift.y + memberStatus.size.h },
					size = { clanView.size.w, 25 }
				})
				if (#ClanData[clanid].leaders > 1) then
					local leader1 = math.random(1, #ClanData[clanid].leaders)
					while (ClanData[clanid].leaders[leader1]:lower() == TB_MENU_PLAYER_INFO.username:lower()) do
						leader1 = math.random(1, #ClanData[clanid].leaders)
					end
					local otherMembersStr = "Together with " .. ClanData[clanid].leaders[leader1]
					if (#ClanData[clanid].leaders > 2) then
						local leader2 = math.random(1, #ClanData[clanid].leaders)
						while (ClanData[clanid].leaders[leader2]:lower() == TB_MENU_PLAYER_INFO.username:lower() or leader2 == leader1) do
							leader2 = math.random(1, #ClanData[clanid].leaders)
						end
						if (otherMembers:uiText(otherMembersStr .. " and " .. ClanData[clanid].leaders[leader2], nil, nil, 4, LEFT, 0.5, nil, nil, nil, nil, nil, true)) then
							otherMembersStr = otherMembersStr .. " and " .. ClanData[clanid].leaders[leader2]
						end
					end
					otherMembers:addCustomDisplay(true, function()
							otherMembers:uiText(otherMembersStr, nil, nil, 4, CENTER, 0.5)
						end)
				end
			else 
				memberStatus:addCustomDisplay(true, function()
						memberStatus:uiText("Clan member", nil, nil, 4, CENTERMID, 0.7)
					end)
				local otherMembers = UIElement:new({
					parent = clanView,
					pos = { 0, memberStatus.shift.y + memberStatus.size.h },
					size = { clanView.size.w, 25 }
				})
				if (#ClanData[clanid].members > 1) then
					local member1 = math.random(1, #ClanData[clanid].members)
					while (ClanData[clanid].members[member1]:lower() == TB_MENU_PLAYER_INFO.username:lower()) do
						member1 = math.random(1, #ClanData[clanid].members)
					end
					local otherMembersStr = "Together with " .. ClanData[clanid].members[member1]
					if (#ClanData[clanid].members > 2) then
						local member2 = math.random(1, #ClanData[clanid].members)
						while (ClanData[clanid].members[member2]:lower() == TB_MENU_PLAYER_INFO.username:lower() or member2 == member1) do
							member2 = math.random(1, #ClanData[clanid].members)
						end
						if (otherMembers:uiText(otherMembersStr .. " and " .. ClanData[clanid].members[member2], nil, nil, 4, LEFT, 0.5, nil, nil, nil, nil, nil, true)) then
							otherMembersStr = otherMembersStr .. " and " .. ClanData[clanid].members[member2]
						end
					end
					otherMembers:addCustomDisplay(true, function()
							otherMembers:uiText(otherMembersStr, nil, nil, 4, CENTER, 0.5)
						end)
				end
			end
			local clanButton = UIElement:new({
				parent = viewElement,
				pos = { 10, -buttonHeight },
				size = { viewElement.size.w - 20, buttonHeight - 20 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.1 }
			})
			clanButton:addCustomDisplay(false, function()
					clanButton:uiText("View Clan")
				end)
			clanButton:addMouseHandlers(nil, function()
					Clans:showClan(viewElement.parent, TB_MENU_PLAYER_INFO.clan.id)
				end)
		end
	end
	
	function Clans:getDefaultFilters()
		return {
			isactive = { strict = true, val = 2 },
			isfreeforall = { strict = false, val = 0 },
			isofficial = { strict = false, val = 0 },
			sortby = "rank",
			desc = false
		}
	end
	
	function Clans:populateClanList(opt)
		local list = {}
		local options = Clans:getDefaultFilters()
		if (opt) then
			for i,v in pairs(opt) do
				if (i ~= "sortby" and i ~= "desc") then
					options[i].val = v
				else 
					options[i] = v
				end
			end
		end
		for i,v in pairs(ClanData) do
			local check = true
			for j,z in pairs(options) do
				if (type(z) == "table" and ((z.strict and z.val ~= v[j]) or (not z.strict and z.val > v[j]))) then
					check = false
					break
				end
			end
			if (check) then
				table.insert(list, v)
			end
		end
		return UIElement:qsort(list, options.sortby, options.desc)
	end
	
	function Clans:showClanListFilters(viewElement, opt)
		viewElement:kill(true)
		local options = {}
		if (opt) then
			options = opt
		else
			local opts = Clans:getDefaultFilters()
			options = {
				isactive = opts.isactive.val,
				isfreeforall = opts.isfreeforall.val,
				isofficial = opts.isofficial.val,
				sortby = opts.sortby,
				desc = opts.desc
			}
		end
		
		options.isactive = options.isactive + 1
		options.desc = options.desc and 2 or 1
		
		local sortOptions = {
			rank = { name = "Rank" },
			name = { name = "Name" },
			tag = { name = "Tag" },
			id = { name = "ID" },
			isofficial = { name = "Status" },
			isfreeforall = { name = "Join Mode" }
		}
		local activityOptions = { 
			{ name = "Dead" },
			{ name = "Inactive" },
			{ name = "Active" }
		}
		local sortOrder = {
			{ name = "Ascending" },
			{ name = "Descending" }
		}
		local optData = {
			{ opt = "isactive", name = "Activity Status", desc = "Clans are considered to be active when they have at least 5 members. Clans with no members are marked as dead.", customSelection = activityOptions },
			{ opt = "isfreeforall", name = "Only free for all clans", desc = "You can join free for all clans any time with one button click. For invite only clans, a custom application process is required." },
			{ opt = "isofficial", name = "Only official clans", desc = "Official clans have their own board on Toribash forums and have square tag brackets in game." },
			{ opt = "sortby", name = "Sort by", customSelection = sortOptions },
			{ opt = "desc", name = "Sort order", customSelection = sortOrder }
		}
		
		local toReload = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h }
		})
		local filtersTopBar = UIElement:new({
			parent = toReload,
			pos = { 0, 0 },
			size = { viewElement.size.w, 50 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		})
		local filtersBotBar = UIElement:new({
			parent = toReload,
			pos = { 0, -50 },
			size = { viewElement.size.w, 50 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		})
		local filtersTitle = UIElement:new({
			parent = filtersTopBar,
			pos = { 0, 0 },
			size = { filtersTopBar.size.w - filtersTopBar.size.h, filtersTopBar.size.h }
		})
		filtersTitle:addCustomDisplay(true, function()
				filtersTitle:uiText("Search Filters", nil, nil, FONTS.BIG, CENTERMID, 0.7, nil, nil, nil, nil, 0.2)
			end)
		local clanListFilters = TBMenu:createImageButtons(filtersTopBar, filtersTitle.size.w, 0, filtersTitle.size.h, filtersTitle.size.h, "system/clanfilters.tga", "system/clanfiltershover.tga", "system/clanfilterspressed.tga")
		clanListFilters:addMouseHandlers(nil, function()
				if (options) then
					options.isactive = options.isactive - 1
					options.desc = options.desc % 2 == 0 and true or false
				end
				Clans:showClanList(viewElement, options)
			end, nil)
		
		local filtersMain = UIElement:new({
			parent = viewElement,
			pos = { 0, filtersTopBar.size.h },
			size = { filtersTopBar.size.w, viewElement.size.h - filtersTopBar.size.h - filtersBotBar.size.h }
		})
		local filtersView = UIElement:new({
			parent = filtersMain,
			pos = { 0, 0 },
			size = { filtersMain.size.w - 30, filtersMain.size.h }
		})
		local listFilters = {}
		for i,v in pairs(optData) do
			local listFilterElement = UIElement:new({
				parent = filtersView,
				pos = { 0, #listFilters * 50 },
				size = { filtersView.size.w, 50 }
			})
			table.insert(listFilters, listFilterElement)
			local filterName = UIElement:new({
				parent = listFilterElement,
				pos = { 20, 10 },
				size = { (listFilterElement.size.w - 40) / 2, listFilterElement.size.h - 20 }
			})
			filterName:addCustomDisplay(true, function()
					filterName:uiText(optData[i].name, nil, nil, nil, LEFTMID)
				end)
			if (optData[i].desc) then
				local listFilterElement = UIElement:new({
					parent = filtersView,
					pos = { 0, #listFilters * 50 },
					size = { filtersView.size.w, 50 }
				})
				table.insert(listFilters, listFilterElement)
				local filterDesc = UIElement:new({
					parent = listFilterElement,
					pos = { 20, 10 },
					size = { listFilterElement.size.w - 40, listFilterElement.size.h - 20 }
				})
				filterDesc:addCustomDisplay(true, function()
						filterDesc:uiText(optData[i].desc, nil, nil, 4, LEFT, 0.6)
					end)
				if (i ~= #optData) then
					local separator = UIElement:new({
						parent = listFilterElement,
						pos = { 0, -1 },
						size = { listFilterElement.size.w, 1 },
						bgColor = { 0, 0, 0, 0.2 }
					})
				end
				listFilterElement:hide()
			elseif (i ~= #optData) then
				local separator = UIElement:new({
					parent = listFilterElement,
					pos = { 0, -1 },
					size = { listFilterElement.size.w, 1 },
					bgColor = { 0, 0, 0, 0.2 }
				})
			end
			local opts = optData[i].opt
			if (optData[i].customSelection) then
				local optTotal = 0
				for j, k in pairs(optData[i].customSelection) do
					optTotal = optTotal + 1
				end
				local filterOption = UIElement:new({
					parent = listFilterElement,
					pos = { listFilterElement.size.w / 2, 5 },
					size = { (listFilterElement.size.w - 40) / 2, listFilters[i].size.h - 10 },
					bgColor = { 0, 0, 0, 0.3 },
					hoverColor = { 0, 0, 0, 0.5 },
					pressedColor = { 1, 0, 0, 0.1 },
					interactive = true
				})
				local filterSelection = UIElement:new({
					parent = filtersView,
					pos = { filterOption.pos.x - filtersView.pos.x, filterOption.pos.y - filtersView.pos.y },
					size = { filterOption.size.w, filterOption.size.h * optTotal / 3 * 2 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				filterSelection:addCustomDisplay(false, function()
						if (filterSelection.pos.y < filtersMain.pos.y or filterSelection.pos.y + filterSelection.size.h > filtersMain.pos.y + filtersMain.size.h) then
							filterSelection:moveTo(filterOption.pos.x - filtersView.pos.x, filterOption.pos.y - filtersView.pos.y)
							filterSelection:hide()
						end
					end)
				local count = 0
				for j,k in pairs(optData[i].customSelection) do
					local filterSelectionOption = UIElement:new({
						parent = filterSelection,
						pos = { 0, count * filterOption.size.h / 3 * 2 },
						size = { filterOption.size.w, filterOption.size.h / 3 * 2 },
						interactive = true,
						bgColor = { 0, 0, 0, 0 },
						hoverColor = { 0, 0, 0, 0.2 },
						pressedColor = { 1, 0, 0, 0.1 }
					})
					filterSelectionOption:addCustomDisplay(false, function()
							filterSelectionOption:uiText(k.name, nil, nil, 4, CENTERMID, 0.7)
						end)
					filterSelectionOption:addMouseHandlers(nil, function()
							filterSelection:moveTo(nil, filterOption.pos.y - filtersView.pos.y)
							options[opts] = j
							filterSelection:hide()
						end, nil)
					count = count + 1
				end
				filterOption:addCustomDisplay(false, function()
						filterOption:uiText(optData[i].customSelection[options[opts]].name, nil, nil, nil, CENTERMID, nil, nil, nil, nil, nil, 0.2)
					end)
				filterOption:addMouseHandlers(function()
						if (filterSelection.pos.y + filterSelection.size.h > filtersBotBar.pos.y) then
							local lPos = filtersView:getLocalPos(0, filtersBotBar.pos.y).y
							if (lPos < 0) then
								lPos = lPos - filtersView.size.h
							end
							filterSelection:moveTo(nil, lPos - filterSelection.size.h)
						elseif (filterSelection.pos.y < filtersTopBar.pos.y + filtersTopBar.size.h) then
							local lPos = filtersView:getLocalPos(0, filtersTopBar.pos.y + filtersTopBar.size.h).y
							if (lPos < 0) then
								lPos = lPos - filtersView.size.h
							end
							filterSelection:moveTo(nil, lPos)
						end
						filterSelection:show()
					end, nil, nil)
				filterSelection:hide()
			else
				local filterCheckbox = UIElement:new({
					parent = listFilterElement,
					pos = { -60, 5 },
					size = { listFilterElement.size.h - 10, listFilterElement.size.h - 10 },
					bgColor = { 0, 0, 0, 0.3 },
					hoverColor = { 0, 0, 0, 0.5 },
					pressedColor = { 1, 0, 0, 0.1 },
					interactive = true					
				})
				local filterCheckboxIcon = UIElement:new({
					parent = filterCheckbox,
					pos = { 0, 0 },
					size = { filterCheckbox.size.w, filterCheckbox.size.h },
					bgImage = "system/checkmark.tga"
				})
				if (options[opts] == 0 or options[opts] == false) then
					filterCheckboxIcon:hide(true)
				end
				filterCheckbox:addMouseHandlers(nil, function()
						if (type(options[opts]) == "boolean") then
							options[opts] = not options[opts]
						else
							options[opts] = 1 - options[opts]
						end
						if (options[opts] == 1 or options[opts] == true) then
							filterCheckboxIcon:show(true)
						else
							filterCheckboxIcon:hide(true)
						end
					end, nil)
			end
		end
		
		local scrollActive = true
		local scrollScale = (filtersView.size.h) / (#listFilters * 50)
		if (scrollScale >= 1) then
			scrollScale = 1
			scrollActive = false
		elseif (scrollScale < 0.1) then
			scrollScale = 0.1
		end
		
		if (scrollActive) then
			local filtersScrollBG = UIElement:new({
				parent = filtersMain,
				pos = { -30, 0 },
				size = { 30, filtersMain.size.h },
				bgColor = { 0, 0, 0, 0.2 }
			})
			local filtersScrollView = UIElement:new({
				parent = filtersScrollBG,
				pos = { 5, 5 },
				size = { filtersScrollBG.size.w - 10, filtersScrollBG.size.h - 10 }
			})
			local filtersScrollBar = UIElement:new({
				parent = filtersScrollView,
				pos = { 0, 0 },
				size = { filtersScrollView.size.w, filtersScrollView.size.h * scrollScale },
				interactive = true,
				bgColor = { 0, 0, 0, 0.3 },
				hoverColor = { 0, 0, 0, 0.5 },
				pressedColor = { 1, 0, 0, 0.2 },
				scrollEnabled = true
			})
			
			for i,v in pairs(listFilters) do
				v:hide()
			end
			filtersScrollBar:makeScrollBar(filtersView, listFilters, toReload)
		else 
			filtersView.size.w = filtersMain.size.w
			for i,v in pairs(listFilters) do
				v.size.w = rosterMemberHolder.size.w
			end
		end
		
		local clanFiltersBotSmudge = TBMenu:addBottomBloodSmudge(filtersBotBar, 2)
		local filterSearchButton = UIElement:new({
			parent = filtersBotBar,
			pos = { filtersBotBar.size.w / 6, 5 },
			size = { filtersBotBar.size.w / 6 * 4, filtersBotBar.size.h - 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.1 },
			hoverSound = 31
		})
		filterSearchButton:addCustomDisplay(false, function()
				filterSearchButton:uiText("Search clans", nil, nil, FONTS.BIG, CENTERMID, 0.5)
			end)
		filterSearchButton:addMouseHandlers(nil, function()
				options.isactive = options.isactive - 1
				options.desc = options.desc % 2 == 0 and true or false
				CLANLISTSHIFT[1] = 0
				Clans:showClanList(viewElement, options)
			end, nil)
	end
	
	function Clans:showClanList(viewElement, options)
		viewElement:kill(true)
		if (CLANSEARCHFILTERS and type(CLANSEARCHFILTERS.desc) ~= "boolean") then
			CLANSEARCHFILTERS.isactive = CLANSEARCHFILTERS.isactive - 1
			CLANSEARCHFILTERS.desc = CLANSEARCHFILTERS.desc % 2 == 0 and true or false
		end
		local options = options or CLANSEARCHFILTERS
		local clanList = Clans:populateClanList(options)
		CLANSEARCHFILTERS = options
		local clanEntryHeight = 45
		-- Parent Object to hold all elements that require reloading when scrolling
		local toReload = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h }
		})
		
		-- Top and Bottom bars, keep interactive to prevent clicking through
		local clanListTopBar = UIElement:new({
			parent = toReload,
			pos = { 0, 0 },
			size = { viewElement.size.w, 80 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			interactive = true
		})
		local clanListTopBarTitle = UIElement:new({
			parent = clanListTopBar,
			pos = { 0, 0 },
			size = { clanListTopBar.size.w - 50, 50 }
		})
		clanListTopBarTitle:addCustomDisplay(true, function()
				clanListTopBarTitle:uiText("Clan List", nil, nil, FONTS.BIG, CENTERMID, 0.7, nil, nil, nil, nil, 0.2)
			end)
		local clanListFilters = TBMenu:createImageButtons(clanListTopBar, clanListTopBarTitle.size.w, 0, clanListTopBarTitle.size.h, clanListTopBarTitle.size.h, "system/clanfilters.tga", "system/clanfiltershover.tga", "system/clanfilterspressed.tga")
		clanListFilters:addMouseHandlers(nil, function()
				Clans:showClanListFilters(viewElement, options)
			end, nil)
			
		local clanListLegendRankWidth = 60
		local clanListLegendNameWidth = (clanListTopBar.size.w - clanListLegendRankWidth - 30) / 5 * 3
		local clanListLegendOfficialWidth = (clanListTopBar.size.w - clanListLegendRankWidth - 30) / 5
		local clanListLegendJoinModeWidth = (clanListTopBar.size.w - clanListLegendRankWidth - 30) / 5
		
		local clanListTopBarLegend = UIElement:new({
			parent = clanListTopBar,
			pos = { 0, clanListTopBarTitle.size.h },
			size = { clanListTopBar.size.w, clanListTopBar.size.h - clanListTopBarTitle.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		})
		local clanListLegendRank = UIElement:new({
			parent = clanListTopBarLegend,
			pos = { 0, 0 },
			size = { clanListLegendRankWidth, clanListTopBarLegend.size.h },
			bgColor = { 0, 0, 0, 0.05 }
		})
		clanListLegendRank:addCustomDisplay(false, function()
				clanListLegendRank:uiText("Rank", nil, nil, 4, CENTERMID, 0.7)
			end)
		local clanListLegendName = UIElement:new({
			parent = clanListTopBarLegend,
			pos = { clanListLegendRankWidth, 0 },
			size = { clanListLegendNameWidth, clanListTopBarLegend.size.h }
		})
		clanListLegendName:addCustomDisplay(true, function()
				clanListLegendName:uiText("Tag and name", nil, nil, 4, CENTERMID, 0.7)
			end)
		local clanListLegendOfficial = UIElement:new({
			parent = clanListTopBarLegend,
			pos = { clanListLegendRankWidth + clanListLegendNameWidth, 0 },
			size = { clanListLegendOfficialWidth, clanListTopBarLegend.size.h },
			bgColor = { 0, 0, 0, 0.05 }
		})
		clanListLegendOfficial:addCustomDisplay(false, function()
				clanListLegendOfficial:uiText("Status", nil, nil, 4, CENTERMID, 0.7)
			end)
		local clanListLegendJoinMode = UIElement:new({
			parent = clanListTopBarLegend,
			pos = { clanListLegendRankWidth + clanListLegendNameWidth + clanListLegendOfficialWidth, 0 },
			size = { clanListLegendJoinModeWidth, clanListTopBarLegend.size.h }
		})
		clanListLegendJoinMode:addCustomDisplay(true, function()
				clanListLegendJoinMode:uiText("Join Mode", nil, nil, 4, CENTERMID, 0.7)
			end)
		local clanListBotBar = UIElement:new({
			parent = toReload,
			pos = { 0, -30 },
			size = { viewElement.size.w, 30 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			interactive = true
		})
		local clanListBotSmudge = TBMenu:addBottomBloodSmudge(clanListBotBar, 2)
		
		-- Main View for Clan List
		local clanListView = UIElement:new({
			parent = viewElement,
			pos = { 0, clanListTopBar.size.h },
			size = { viewElement.size.w, viewElement.size.h - clanListTopBar.size.h - clanListBotBar.size.h }
		})
		
		-- Clan Holder Object, used to create scrollable list
		local clanListHolder = UIElement:new({
			parent = clanListView,
			pos = { 0, 0 },
			size = { clanListView.size.w - 30, clanListView.size.h }
		})
		
		local scrollActive = true
		local scrollScale = #clanList == 0 and 1 or (clanListView.size.h) / (#clanList * clanEntryHeight)
		if (scrollScale >= 1) then
			scrollScale = 1
			scrollActive = false
		elseif (scrollScale < 0.1) then
			scrollScale = 0.1
		end
		
		local clanListScrollBG = UIElement:new({
			parent = clanListView,
			pos = { -30, 0 },
			size = { 30, clanListView.size.h },
			bgColor = { 0, 0, 0, 0.2 }
		})
		local clanListScrollView = UIElement:new({
			parent = clanListScrollBG,
			pos = { 5, 5 },
			size = { clanListScrollBG.size.w - 10, clanListScrollBG.size.h - 10 }
		})
		local clanListScrollBar = UIElement:new({
			parent = clanListScrollView,
			pos = { 0, 0 },
			size = { clanListScrollView.size.w, clanListScrollView.size.h * scrollScale },
			interactive = scrollActive,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 0, 0, 0.2 },
			scrollEnabled = true
		})
		if (not scrollActive) then
			clanListScrollBar:hide()
		end
		
		if (#clanList > 0) then
			local clanListClans = {}
			for i, v in pairs(clanList) do
			 	clanListClans[i] = UIElement:new({
					parent = clanListHolder,
					pos = { 0, (i - 1) * clanEntryHeight },
					size = { clanListHolder.size.w, clanEntryHeight },
					interactive = true,
					bgColor = { 0, 0, 0, i % 2 == 0 and 0 or 0.1 },
					hoverColor = { 0, 0, 0, 0.3 },
					pressedColor = { 0, 0, 0, 0.4 },
					hoverSound = 31
				})
				clanListClans[i]:addMouseHandlers(nil, function()
						Clans:showClan(viewElement.parent, clanList[i].id)
					end, nil)
				local clanListClanRank = UIElement:new({
					parent = clanListClans[i],
					pos = { 0, 0 },
					size = { clanListLegendRankWidth, clanListClans[i].size.h },
					bgColor = { 0, 0, 0, 0.05 }
				})
				local clanRank = clanList[i].rank == 0 and "-" or clanList[i].rank
				clanListClanRank:addCustomDisplay(false, function()
						clanListClanRank:uiText(clanRank, nil, nil, 4, CENTERMID, 0.7)
					end)
				local clanListClanNameView = UIElement:new({
					parent = clanListClans[i],
					pos = { clanListLegendRankWidth, 0 },
					size = { clanListLegendNameWidth, clanListClans[i].size.h }
				})
				local clanListClanTag = UIElement:new({
					parent = clanListClanNameView,
					pos = { 0, 0 },
					size = { clanListClanNameView.size.w / 3 - 5, clanListClanNameView.size.h } 
				})
				local clanListClanName = UIElement:new({
					parent = clanListClanNameView,
					pos = { clanListClanNameView.size.w / 3 + 5, 0 },
					size = { clanListClanNameView.size.w / 3 * 2 - 5, clanListClanNameView.size.h } 
				})
				local clanListClanNameSeparator = UIElement:new({
					parent = clanListClanNameView,
					pos = { clanListClanNameView.size.w / 3 - 5, 0 },
					size = { 10, clanListClanNameView.size.h }
				})
				clanListClanNameSeparator:addCustomDisplay(true, function()
						clanListClanNameSeparator:uiText("|", nil, nil, 4, CENTERMID, 0.7)
					end)
				clanListClanTag:addCustomDisplay(true, function()
						clanListClanTag:uiText(clanList[i].tag, nil, nil, 4, RIGHTMID, 0.7)
					end)
				clanListClanName:addCustomDisplay(true, function()
						clanListClanName:uiText(clanList[i].name, nil, nil, 4, LEFTMID, 0.7)
					end)
				local clanListClanOfficial = UIElement:new({
					parent = clanListClans[i],
					pos = { clanListLegendRankWidth + clanListLegendNameWidth, 0 },
					size = { clanListLegendOfficialWidth, clanListClans[i].size.h },
					bgColor = { 0, 0, 0, 0.05 }
				})
				local officialStatus = clanList[i].isofficial == 1 and "Official" or "Unofficial"
				clanListClanOfficial:addCustomDisplay(false, function()
						clanListClanOfficial:uiText(officialStatus, nil, nil, 4, CENTERMID, 0.7)
					end)
				local clanListClanJoinMode = UIElement:new({
					parent = clanListClans[i],
					pos = { clanListLegendRankWidth + clanListLegendNameWidth + clanListLegendOfficialWidth, 0 },
					size = { clanListLegendJoinModeWidth, clanListClans[i].size.h }
				})
				local joinModeStatus = clanList[i].isfreeforall == 1 and "Free for all" or "Invite Only"
				clanListClanJoinMode:addCustomDisplay(true, function()
						clanListClanJoinMode:uiText(joinModeStatus, nil, nil, 4, CENTERMID, 0.7)
					end)
				clanListClans[i]:hide()
			end
			
			clanListScrollBar:makeScrollBar(clanListHolder, clanListClans, toReload, CLANLISTSHIFT)
		else 
			clanListHolder:addCustomDisplay(true, function()
				clanListHolder:uiText("No clans to display", nil, nil, 4)
			end)
		end
	end
	
	function Clans:showClanInfoLeft(viewElement, clanid)
		local bottomSmudge = TBMenu:addBottomBloodSmudge(viewElement, 2)
		local clanName = UIElement:new({
			parent = viewElement,
			pos = { 10, 10 },
			size = { viewElement.size.w - 20, 60 }
		})
		local clanTag = ClanData[clanid].isofficial == 1 and "[" .. ClanData[clanid].tag .. "]" or "(" .. ClanData[clanid].tag .. ")"
		local clanNameScale = 0.5
		while (not clanName:uiText(clanTag .. " " .. ClanData[clanid].name, nil, nil, FONTS.BIG, LEFT, clanNameScale, nil, nil, nil, nil, nil, true)) do
			clanNameScale = clanNameScale - 0.05
		end
		clanName:addCustomDisplay(true, function()
				clanName:uiText(clanTag .. " " .. ClanData[clanid].name, nil, nil, FONTS.BIG, CENTER, clanNameScale)
			end)
		local joinInteractive = false
		if (ClanData[clanid].isfreeforall == 1 and TB_MENU_PLAYER_INFO.clan.id == 0 and ClanData[clanid].memberstotal < LevelData[ClanData[clanid].level + 1].maxmembers) then
			joinInteractive = true
		end
		local clanJoin = UIElement:new({
			parent = viewElement,
			pos = { 10, -80 },
			size = { viewElement.size.w - 20, 70 },
			interactive = joinInteractive,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.1 }
		})
		if (joinInteractive) then
			clanJoin:addCustomDisplay(false, function()
					clanJoin:uiText("Join clan")
				end)
			clanJoin:addMouseHandlers(nil, function()
					open_url("http://forum.toribash.com/clan.php?clanid=" .. clanid .. "&join=1")
				end)
		elseif (ClanData[clanid].isfreeforall == 1) then
			clanJoin:addCustomDisplay(false, function()
					clanJoin:uiText("Free for all")
				end)
		else
			clanJoin:addCustomDisplay(false, function()
					clanJoin:uiText("Invite Only")
				end)
		end
		local freeSpace = viewElement.size.h - clanName.shift.y - clanName.size.h - clanJoin.size.h - 30
		local logoScale = 256 > freeSpace and freeSpace or 256
		local clanLogo = UIElement:new({
			parent = viewElement,
			pos = { (viewElement.size.w - logoScale) / 2, clanName.size.h + clanName.shift.y + 10 + (freeSpace - logoScale) / 2 },
			size = { logoScale, logoScale },
			bgImage =  { "../textures/clans/"..clanid..".tga", CLANLOGODEFAULT }
		})
		Clans:loadClanLogo(clanid, clanLogo)
		local logoReload = UIElement:new({
			parent = clanLogo,
			pos = { 0, 0 },
			size = { clanLogo.size.w, clanLogo.size.h },
			interactive = true,
			bgColor = { 0, 0, 0, 0 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.1 }
		})
		logoReload:addCustomDisplay(true, function()
				local color = logoReload:getButtonColor()
				set_color(unpack(color))
				draw_quad(logoReload.pos.x, logoReload.pos.y, logoReload.size.w, logoReload.size.h)
				logoReload:uiText("Reload logo", nil, nil, nil, nil, nil, nil, nil, {1, 1, 1, color[4] * 2} )
			end)
		logoReload:addMouseHandlers(nil, function()
				Clans:loadClanLogo(clanid, clanLogo, true)
			end, nil)
	end
	
	function Clans:showClanInfoMid(viewElement, clanid)
		local clanLevelValue = ClanData[clanid].level
		local clanTopAch = ClanData[clanid].topach
		local xpBarProgress = (ClanData[clanid].xp - LevelData[clanLevelValue].minxp) / (LevelData[clanLevelValue + 1].minxp - LevelData[clanLevelValue].minxp)
		if (xpBarProgress > 1) then
			xpBarProgress = 1
		end
		
		local bottomSmudge = TBMenu:addBottomBloodSmudge(viewElement, 1)
		local clanRank = UIElement:new( {
			parent = viewElement,
			pos = { 40, 10 },
			size = { (viewElement.size.w - 80) / 2, 40 }
		})
		local clanRankText = "Rank "..ClanData[clanid].rank
		if (ClanData[clanid].rank < 1) then
			clanRankText = "Unranked"
		end
		clanRank:addCustomDisplay(false, function()
			clanRank:uiText(clanRankText, nil, nil, FONTS.BIG, LEFT, 0.5)
		end)
		local clanLevel = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 2, 10 },
			size = { (viewElement.size.w - 80) / 2, 40}
		})
		clanLevel:addCustomDisplay(false, function()
			clanLevel:uiText("Level " .. clanLevelValue, nil, nil, FONTS.BIG, RIGHT, 0.5)
			end)
		local clanXpBarOutline = UIElement:new( {
			parent = viewElement,
			pos = { 30, 50 },
			size = { viewElement.size.w - 60, 60 },
			bgColor = { 0.1, 0.1, 0.1, 0.5 },
			shapeType = ROUNDED,
			rounded = 10
		})
		local clanXpBar = UIElement:new({
			parent = clanXpBarOutline,
			pos = { 2, 2 },
			size = { clanXpBarOutline.size.w - 4, clanXpBarOutline.size.h - 4 },
			bgColor = { 0.5, 0.1, 0.1, 1 },
			shapeType = clanXpBarOutline.shapeType,
			rounded = clanXpBarOutline.rounded / 5 * 4 })
		if (xpBarProgress > 0) then
			clanXpBarProgress = UIElement:new({
				parent = clanXpBar,
				pos = { 0, 0 },
				size = { clanXpBar.size.w * xpBarProgress, clanXpBar.size.h },
				bgColor = { 0.78, 0.05, 0.08, 1 },
				shapeType = clanXpBar.shapeType,
				rounded = clanXpBar.rounded,
				innerShadow = { 4, 4 },
				shadowColor = { { 0.91, 0.34, 0.24, 1 }, { 0.33, 0, 0, 1 } }
			})
		end
		
		local clanXp = UIElement:new( {
			parent = clanXpBar,
			pos = { 0, 0 },
			size = { clanXpBar.size.w, clanXpBar.size.h } } )
		clanXp:addCustomDisplay(false, function()
			clanXp:uiText(ClanData[clanid].xp .. " / " .. LevelData[clanLevelValue + 1].minxp .. " XP", clanXp.pos.x, clanXp.pos.y, FONTS.BIG, CENTERMID, 0.5, nil, 1)
		end)
		local clanWars = UIElement:new({
			parent = viewElement,
			pos = { 30, 120 },
			size = { viewElement.size.w - 60, (viewElement.size.h - 140) / 2 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.1 }
		})
		clanWars:addCustomDisplay(false, function()
				clanWars:uiText("View Wars on Forum")
			end)
		clanWars:addMouseHandlers(true, function()
				open_url("http://forum.toribash.com/clan_war.php?clanid=" .. clanid)
			end, nil)
		local clanTopAchievement = UIElement:new({
			parent = viewElement,
			pos = { 30, -(viewElement.size.h - 120) / 2 },
			size = { viewElement.size.w - 60, (viewElement.size.h - 140) / 2 },
			bgColor = { 0, 0, 0, 0.1 }
		})
		if (clanTopAch ~= 0) then
			iconScale = clanTopAchievement.size.h >= 110 and 100 or clanTopAchievement.size.h - 10
			local clanTopAchIcon = UIElement:new({
				parent = clanTopAchievement,
				pos = { 10, (clanTopAchievement.size.h - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = "/clans/achievements/" .. clanTopAch .. ".tga"
			})
			local clanTopAchName = UIElement:new({
				parent = clanTopAchievement,
				pos = { iconScale + 10, 0 },
				size = { clanTopAchievement.size.w - iconScale - 20, clanTopAchievement.size.h / 2 - 5 }
			})
			clanTopAchName:addCustomDisplay(false, function()
				clanTopAchName:uiText(AchievementData[clanTopAch].achname, nil, nil, nil, CENTERBOT)
			end)
			local clanTopAchDesc = UIElement:new({
				parent = clanTopAchievement,
				pos = { iconScale + 30, clanTopAchievement.size.h / 2 + 5 },
				size = { clanTopAchievement.size.w - iconScale - 60, clanTopAchievement.size.h / 2 - 5 },
			})
			clanTopAchDesc:addCustomDisplay(false, function()
				clanTopAchDesc:uiText(AchievementData[clanTopAch].achdesc, nil, nil, 4, CENTER, 0.7)
			end)
		else
			local clanTopAchDesc = UIElement:new({
				parent = clanTopAchievement,
				pos = { 10, 0 },
				size = { clanTopAchievement.size.w - 20, clanTopAchievement.size.h }
			})
			clanTopAchDesc:addCustomDisplay(false, function()
					clanTopAchDesc:uiText("This clan hasn't chosen an achievement to display", nil, nil, 4, nil, 0.7)
				end)
		end
	end
	
	function Clans:downloadHead(reloader, avatars, id)
		local downloads = get_downloads()
		if (table.getn(downloads) == 0) then
			if (PlayerInfo:getItems(avatars[id].player).textures.head.equipped) then
				avatars[id]:updateImage("../../custom/" .. avatars[id].player:lower() .. "/head.tga", nil, true)
			end
			if (id < #avatars) then
				id = id + 1
				download_head(avatars[id].player)
				reloader:addCustomDisplay(false, function() Clans:downloadHead(reloader, avatars, id) end)
			else 
				reloader:kill()
				remove_hooks("tbMenuConsoleIgnore")
			end
		end
	end
	
	function Clans:reloadHeadAvatars(avatars)
		download_head(avatars[1].player)
		add_hook("console", "tbMenuConsoleIgnore", function(s,i)
			return 1
		end)
		local reloader = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 0, 0 },
			size = { 1, 1 }
		})
		reloader:addCustomDisplay(false, function() Clans:downloadHead(reloader, avatars, 1) end)
	end
	
	function Clans:showClanMemberlist(viewElement, clanid)
		local shaders = get_option("shaders")
		local avatarWidth = shaders * 40
		local rosterEntryHeight = 40
		
		local toReload = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h }
		})
		local rosterTop = UIElement:new({
			parent = toReload,
			pos = { 0, 0 },
			size = { toReload.size.w, 50 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local rosterTitle = UIElement:new({
			parent = rosterTop,
			pos = { avatarWidth, 0 },
			size = { rosterTop.size.w - avatarWidth * 2, rosterTop.size.h }
		})
		local rosterStr = "Roster (" .. ClanData[clanid].memberstotal .. "/" .. LevelData[ClanData[clanid].level + 1].maxmembers .. ")"
		local rosterTextScale = 1
		while (not rosterTitle:uiText(rosterStr, nil, nil, nil, LEFT, rosterTextScale, nil, nil, nil, nil, nil, true)) do
			rosterTextScale = rosterTextScale - 0.05
		end
		rosterTitle:addCustomDisplay(true, function()
				rosterTitle:uiText(rosterStr, nil, nil, nil, nil, rosterTextScale, nil, nil, nil, nil, 0.2)
			end)
		if (shaders == 1) then
			local viewportTopReplacer = UIElement:new({
				parent = rosterTop,
				pos = { 0, 0 },
				size = { avatarWidth, rosterTop.size.h },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				viewport = true
			})
			viewportTopReplacer:addCustomDisplay(false, function()
					set_color(unpack(viewportTopReplacer.bgColor))
					draw_box(0, 0, 10, 2, 2, 2, 0, 0, 0)
				end)
		end
		local rosterBottom = UIElement:new({
			parent = toReload,
			pos = { 0, -rosterEntryHeight },
			size = { toReload.size.w, rosterEntryHeight },
			bgColor = { 0.607, 0.109, 0.109, 1 },
		})
		if (shaders == 1) then
			local viewportBotReplacer = UIElement:new({
				parent = rosterBottom,
				pos = { 0, 0 },
				size = { avatarWidth, avatarWidth },
				bgColor = rosterBottom.bgColor,
				viewport = true
			})
			viewportBotReplacer:addCustomDisplay(false, function()
					set_color(unpack(viewportBotReplacer.bgColor))
					draw_box(0, 0, 10, 2, 2, 2, 0, 0, 0)
				end)
		end
		local bottomSmudge = TBMenu:addBottomBloodSmudge(toReload, 3)
		local rosterView = UIElement:new({
			parent = viewElement,
			pos = { 0, rosterTitle.size.h },
			size = { viewElement.size.w, viewElement.size.h - rosterTitle.size.h - rosterBottom.size.h }
		})
		local rosterMemberHolder = UIElement:new({
			parent = rosterView,
			pos = { 0, 0 },
			size = { rosterView.size.w - 30, rosterView.size.h }
		})
		local rosterMembers = {}
		local headAvatars = {}
		local rosterPos = 0
		if (#ClanData[clanid].leaders > 0) then
			local leadersTitle = UIElement:new({
				parent = rosterMemberHolder,
				pos = { 0, rosterPos },
				size = { rosterMemberHolder.size.w, rosterEntryHeight }
			})
			table.insert(rosterMembers, leadersTitle)
			rosterPos = rosterPos + rosterEntryHeight
			local leaderStr = #ClanData[clanid].leaders > 1 and "Leaders" or "Leader"
			leadersTitle:addCustomDisplay(true, function()
					leadersTitle:uiText(leaderStr)
				end)
			for i,v in pairs(ClanData[clanid].leaders) do
				local leader = UIElement:new({
					parent = rosterMemberHolder,
					pos = { 0, rosterPos },
					size = { rosterMemberHolder.size.w, rosterEntryHeight },
					bgColor = rosterPos % (rosterEntryHeight * 2 ) == 0 and { 0, 0, 0, 0.1 } or { 0, 0, 0, 0 }
				})
				if (shaders == 1) then
					local avatarViewport = UIElement:new( {
						parent = leader,
						pos = { 0, 0 },
						size = { avatarWidth, avatarWidth },
						viewport = true
					})
					local headTexture = { "../../custom/tori/head.tga", "../../custom/tori/head.tga" }
					local player = PlayerInfo:getItems(v)
					if (player.textures.head.equipped) then
						headTexture[1] = "../../custom/" .. v .. "/head.tga"
					end
					local avatar = UIElement:new({
						parent = avatarViewport,
						pos = { 0, 0, 10 },
						rot = { 0, 0, 0 },
						radius = 1,
						bgColor = { 1, 1, 1, 1 },
						bgImage = headTexture
					})
					avatar.player = v
					table.insert(headAvatars, avatar)
				end
				local leaderText = UIElement:new({
					parent = leader,
					pos = { avatarWidth + 5, 0 },
					size = { leader.size.w - avatarWidth - 10, leader.size.h }
				})
				leaderText:addCustomDisplay(true, function()
						leaderText:uiText(v, nil, nil, 4, LEFTMID, 0.7)
					end)
				table.insert(rosterMembers, leader)
				rosterPos = rosterPos + rosterEntryHeight
			end
		end
		if (#ClanData[clanid].members > 0) then
			local membersTitle = UIElement:new({
				parent = rosterMemberHolder,
				pos = { 0, rosterPos },
				size = { rosterMemberHolder.size.w, rosterEntryHeight }
			})
			table.insert(rosterMembers, membersTitle)
			rosterPos = rosterPos + rosterEntryHeight
			local memberStr = #ClanData[clanid].members > 1 and "members" or "member"
			membersTitle:addCustomDisplay(true, function()
					membersTitle:uiText(memberStr)
				end)
			for i,v in pairs(ClanData[clanid].members) do
				local member = UIElement:new({
					parent = rosterMemberHolder,
					pos = { 0, rosterPos },
					size = { rosterMemberHolder.size.w, rosterEntryHeight },
					bgColor = rosterPos % (rosterEntryHeight * 2 ) == 0 and { 0, 0, 0, 0.05 } or { 0, 0, 0, 0 }
				})
				if (shaders == 1) then	
					local avatarViewport = UIElement:new( {
						parent = member,
						pos = { 0, 0 },
						size = { avatarWidth, member.size.h },
						viewport = true
					})
					local headTexture = { "../../custom/tori/head.tga", "../../custom/tori/head.tga" }
					local player = PlayerInfo:getItems(v)
					if (player.textures.head.equipped) then
						headTexture[1] = "../../custom/" .. v .. "/head.tga"
					end
					local avatar = UIElement:new({
						parent = avatarViewport,
						pos = { 0, 0, 10 },
						rot = { 0, 0, 0 },
						radius = 1,
						bgColor = { 1, 1, 1, 1 },
						bgImage = headTexture
					})
					avatar.player = v
					table.insert(headAvatars, avatar)
				end
				local memberText = UIElement:new({
					parent = member,
					pos = { avatarWidth + 5, 0 },
					size = { member.size.w - avatarWidth - 10, member.size.h }
				})
				memberText:addCustomDisplay(true, function()
						memberText:uiText(v, nil, nil, 4, LEFTMID, 0.7)
					end)
				table.insert(rosterMembers, member)
				rosterPos = rosterPos + rosterEntryHeight
			end
		end
		Clans:reloadHeadAvatars(headAvatars)
		
		local scrollActive = true
		local scrollScale = #rosterMembers == 0 and 1 or (rosterView.size.h) / (#rosterMembers * rosterEntryHeight)
		if (scrollScale >= 1) then
			scrollScale = 1
			scrollActive = false
		elseif (scrollScale < 0.1) then
			scrollScale = 0.1
		end
		
		if (scrollActive) then
			local rosterScrollBG = UIElement:new({
				parent = rosterView,
				pos = { -30, 0 },
				size = { 30, rosterView.size.h },
				bgColor = { 0, 0, 0, 0.2 }
			})
			local rosterScrollView = UIElement:new({
				parent = rosterScrollBG,
				pos = { 5, 5 },
				size = { rosterScrollBG.size.w - 10, rosterScrollBG.size.h - 10 }
			})
			local rosterScrollBar = UIElement:new({
				parent = rosterScrollView,
				pos = { 0, 0 },
				size = { rosterScrollView.size.w, rosterScrollView.size.h * scrollScale },
				interactive = scrollActive,
				bgColor = { 0, 0, 0, 0.3 },
				hoverColor = { 0, 0, 0, 0.5 },
				pressedColor = { 1, 0, 0, 0.2 },
				scrollEnabled = true
			})
			
			for i,v in pairs(rosterMembers) do
				v:hide()
			end
			rosterScrollBar:makeScrollBar(rosterMemberHolder, rosterMembers, toReload)
		else 
			rosterMemberHolder.size.w = rosterView.size.w
			for i,v in pairs(rosterMembers) do
				v.size.w = rosterMemberHolder.size.w
			end
		end
	end
	
	function Clans:showClan(viewElement, clanid)
		viewElement:kill(true)
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Clans:getNavigationButtons(true), true)
				
		local clanView = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h }
		})
		local clanInfoLeftView = UIElement:new({
			parent = clanView,
			pos = { 5, 0 },
			size = { 276, clanView.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Clans:showClanInfoLeft(clanInfoLeftView, clanid)
		local clanInfoMidView = UIElement:new({
			parent = clanView,
			pos = { clanInfoLeftView.size.w + clanInfoLeftView.shift.x + 10, 0 },
			size = { (clanView.size.w - clanInfoLeftView.size.w + clanInfoLeftView.shift.x + 20) / 3 * 2, clanView.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Clans:showClanInfoMid(clanInfoMidView, clanid)
		local clanInfoMemberlistView = UIElement:new({
			parent = clanView,
			pos = { clanInfoMidView.size.w + clanInfoMidView.shift.x + 10, 0 },
			size = { clanView.size.w - clanInfoMidView.size.w - clanInfoLeftView.size.w - 30, clanView.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Clans:showClanMemberlist(clanInfoMemberlistView, clanid)
	end
	
	function Clans:loadClanLogo(clanid, viewElement, reload)
		for i = #LOGOCACHE, 1, -1 do
			if (LOGOCACHE[i] == clanid) then
				if (reload) then
					table.remove(LOGOCACHE, i)
					break
				else
					return
				end
			end
		end
		
		download_clan_logo(clanid)
		local rotation = 0
		local scale = 0
		local transparency = { 0.8 }
		local loadView = UIElement:new({
			parent = viewElement,
			pos = { 0, -30 },
			size = { viewElement.size.w, 30 }
		})
		loadView:addCustomDisplay(true, function()
				set_color(0, 0, 0, transparency[1] / 2)
				draw_quad(loadView.pos.x, loadView.pos.y, loadView.size.w, loadView.size.h)
			end)
		local loadIndicatorDisk = UIElement:new({
			parent = loadView,
			pos = { 0, 0 },
			size = { loadView.size.h,  loadView.size.h }
		})
		local loadIndicator = UIElement:new({
			parent = loadView,
			pos = { loadView.size.h, 0 },
			size = { loadView.size.w - loadView.size.h, loadView.size.h }
		})
		loadIndicatorDisk:addCustomDisplay(true, function()
				set_color(1,1,1,transparency[1])
				draw_disk(loadIndicatorDisk.pos.x + loadIndicatorDisk.size.w / 2, loadIndicatorDisk.pos.y + loadIndicatorDisk.size.h / 2, 6, 12, 200, 1, rotation, scale, 0)
				rotation = rotation + 2.5
				scale = scale + 5
				if (scale > 360) then
					scale = -360
				end
			end)
		local updateTextScale = 1
		while (not loadIndicator:uiText("Updating", nil, nil, nil, LEFT, updateTextScale, nil, nil, nil, nil, nil, true)) do
			updateTextScale = updateTextScale - 0.05
		end
		loadIndicator:addCustomDisplay(true, function()
				local downloads = get_downloads()
				if (table.getn(downloads) == 0) then
					if (transparency[1] == 0.8) then
						viewElement:updateImage("../textures/clans/"..clanid..".tga", CLANLOGODEFAULT, true)
					end
					transparency[1] = transparency[1] - 0.05
					if (transparency[1] <= 0) then
						table.insert(LOGOCACHE, clanid)
						loadView:kill()
					end
				end
				loadIndicator:uiText("Updating", nil, nil, nil, nil, updateTextScale, nil, nil, { 1, 1, 1, transparency[1] })
			end)
	end
end