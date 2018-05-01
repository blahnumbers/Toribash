-- beginner clans manager class

do
	BeginnerClans = {}
	BeginnerClans.__index = BeginnerClans
	
	RED = {	name = "Red",
			desc = "We are Red, the best clan because it's the best color, join us to fight those Blue dummies!",
			discordInvite = "https://discord.gg/PBrzuS6",
			clanid = 2194,
			forumid = 793 }
			
	BLUE = {	name = "Blue",
				desc = "We are Blue, the best clan because it's the best color, join us to fight those Red dummies!",
				discordInvite = "https://discord.gg/zFzScza",
				clanid = 2193,
				forumid = 794 }
	
	function BeginnerClans:create()
		local cln = {}
		setmetatable(cln, BeginnerClans)
	end
	
	function BeginnerClans:canShow()
		add_hook("console", "beginnerClanConsoleIgnore", function(s,i)
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
			return 1
		end
		
		for ln in file:lines() do
			if string.match(ln, "^BELT 0;") then
				local qi = string.gsub(ln, "BELT 0;", "")
				if (tonumber(qi) > 999 or tonumber(qi) < 1) then
					return 0
				end
			end
		end
		file:close()
		
		local file = io.open("clans/clans.txt", "r")
		if (file == nil) then
			return 1
		end
		for ln in file:lines() do
			if string.match(ln, "%s" .. player_name .. "%s") then
				file:close()
				return 0
			end
		end
		file:close()
		
		return 1
	end
	
	function BeginnerClans:showMain()
		beginnerClansBG = UIElement:new( {	pos = { WIN_W/2 - 400, WIN_H/2 - 225 },
											size = {800, 450},
											shapeType = ROUNDED,
											rounded = 20,
											bgColor = {0,0,0,0.95} } )
		beginnerClans = UIElement:new( {	parent = beginnerClansBG,
											pos = { 4, 4 },
											size = { beginnerClansBG.size.w - 8, beginnerClansBG.size.h - 8 },
											shapeType = beginnerClansBG.shapeType,
											rounded = 16,
											bgColor = {0.7, 0, 0, 1},
											innerShadow = {0, 15},
											shadowColor = { {0,0,0,0}, {0.5,0,0,1} } } )
		local bQuitButton = UIElement:new( {	parent = beginnerClans,
												pos = { -50, 5 },
												size = { 40, 40 },
												bgColor = { 0,0,0,0.7 },
												shapeType = ROUNDED,
												rounded = 17,
												interactive = true,
												hoverColor = { 0.2,0,0,0.7},
												pressedColor = { 1,0,0,0.5} } )
		bQuitButton:addCustomDisplay(false, function()
			local indent = 12
			local weight = 5
			set_color(1,1,1,1)
			draw_line(bQuitButton.pos.x + indent, bQuitButton.pos.y + indent, bQuitButton.pos.x + bQuitButton.size.w - indent, bQuitButton.pos.y + bQuitButton.size.h - indent, weight)
			draw_line(bQuitButton.pos.x + bQuitButton.size.w - indent, bQuitButton.pos.y + indent, bQuitButton.pos.x + indent, bQuitButton.pos.y + bQuitButton.size.h - indent, weight)
		end)
		bQuitButton:addMouseHandlers(function() end, function()
				if (get_option(BEGINNERCLANUIOPT) == 0) then
					beginnerClansBG:kill()
					set_option(BEGINNERCLANUIOPT, 1)
					remove_hooks("beginnerClansVisual")
					--remove_hooks("uiMouseHandler")
				else
					BeginnerClans:showQuit()
				end
			end, function() end)
		local beginnerClansView = UIElement:new( {	parent = beginnerClans,
													pos = { 0, 0 },
													size = { beginnerClans.size.w, beginnerClans.size.h } } )
		local beginnerClansTitle = UIElement:new( {	parent = beginnerClansView,
													pos = { 0, 10 },
													size = { beginnerClansView.size.w, 50 } } )
		beginnerClansTitle:addCustomDisplay(false, function()
			beginnerClansTitle:uiText("Join a beginner clan!", nil, nil, FONTS.BIG, nil, 0.85, nil, 2)
		end)
		
		local bClanRed = UIElement:new( {	parent = beginnerClansView,
											pos = {80, 75},
											size = {250, 250},
											shapeType = ROUNDED,
											rounded = 125,
											bgColor = {0, 0, 0, 0.5},
											interactive = true,
											hoverColor = {0, 0, 0, 1},
											pressedColor = {0.4, 0, 0, 1}, 
											bgImage = "system/beginnerclanred.tga" } )
		bClanRed:addMouseHandlers(function() end, function()
			beginnerClansView:kill()
			BeginnerClans:showClan(RED)
		end, function() end)
		local bClanRedText = UIElement:new( {	parent = bClanRed, 
												pos = {0, -80},
												size = { bClanRed.size.w, 50 } } )
		bClanRedText:addCustomDisplay(false, function()
			bClanRedText:uiText(RED.name, nil, nil, FONTS.BIG, nil, nil, nil, 1.5, {1,0,0,1})
		end)
		local bClanBlue = UIElement:new( {	parent = beginnerClansView,
											pos = {-330, 75},
											size = {250, 250},
											shapeType = ROUNDED,
											rounded = 125,
											bgColor = {0, 0, 0, 0.5},
											interactive = true,
											hoverColor = {0, 0, 0, 1},
											pressedColor = {0.1, 0.15, 0.4, 1}, 
											bgImage = "system/beginnerclanblue.tga" } )
		local bClanBlueText = UIElement:new( {	parent = bClanBlue, 
												pos = {0, -80},
												size = { bClanBlue.size.w, 50 } } )
		bClanBlue:addMouseHandlers(function() end, function()
			beginnerClansView:kill()
			BeginnerClans:showClan(BLUE)
		end, function() end)
		bClanBlueText:addCustomDisplay(false, function()
			bClanBlueText:uiText(BLUE.name, nil, nil, FONTS.BIG, nil, nil, nil, 1.5, {0.4,0.5,1,1})
		end)
		local beginnerClansDesc = UIElement:new( {	parent = beginnerClansView,
													pos = {0, -100},
													size = {beginnerClansView.size.w, 85} } )
		beginnerClansDesc:addCustomDisplay(false, function()
			beginnerClansDesc:uiText("Joining a beginner clan will help you to learn things faster and find opponents easier!", nil, nil, FONTS.BIG, nil, 0.6, nil, 1)
		end)
	end
	
	function BeginnerClans:showClan(bClan)
		local bClanView = UIElement:new( {	parent = beginnerClans,
											pos = { 0, 0 },
											size = { beginnerClans.size.w, beginnerClans.size.h } } )
		local bClanViewBackButton = UIElement:new( {	parent = bClanView,
													pos = {10, 5},
													size = {35, 35},
													bgColor = {0.2,0,0,1},
													interactive = true,
													hoverColor = { 0.2,0,0,0.7},
													pressedColor = { 1,0,0,0.5},
													shapeType = ROUNDED,
													rounded = 10 } )
		bClanViewBackButton:addCustomDisplay(false, function()
			local indent = 4
			local weight = 10
			-- Back button
			if (bClanViewBackButton.hoverState == BTN_DN) then
				set_color(0,0,0,1)
			else
				set_color(1,1,1,1)
			end
			draw_line(bClanViewBackButton.pos.x + indent * 2, bClanViewBackButton.pos.y + bClanViewBackButton.size.h / 2, bClanViewBackButton.pos.x + bClanViewBackButton.size.w - indent, bClanViewBackButton.pos.y + bClanViewBackButton.size.h / 2, weight)
			draw_disk(bClanViewBackButton.pos.x + 14, bClanViewBackButton.pos.y + 13.5 + indent, 0, 11, 3, 1, -90, 360, 0)
		end)
		bClanViewBackButton:addMouseHandlers(function() end, function()
			bClanView:kill()
			BeginnerClans:showMain()
		end, function() end)

		local bClanTitle = UIElement:new( {	parent = bClanView,
											pos = { 0, 0 },
											size = { bClanView.size.w, 50 } } )
		bClanTitle:addCustomDisplay(false, function()
			bClanTitle:uiText(bClan.name, nil, nil, FONTS.BIG, nil, 0.85, nil, 2)
		end)
		
		local bClanLogo = UIElement:new( {	parent = bClanView,
											pos = { 25, 70 },
											size = { 250, 250 },
											bgColor = {0,0,0,0.7},
											shapeType = ROUNDED,
											rounded = 250,
											bgImage = "system/beginnerclan"..string.lower(bClan.name)..".tga" } )
		local bClanDesc = UIElement:new( {	parent = bClanView,
											pos = { -500, 70 },
											size = {475, 120 } } )
		bClanDesc:addCustomDisplay(false, function()
			bClanDesc:uiText(bClan.desc, nil, nil, FONTS.BIG, LEFT, 0.57, nil, 1)
		end)
		local bClanClanBG = UIElement:new( {	parent = bClanView,
											pos = { -500, 190 },
											size = { 475, 50 },
											bgColor = {0,0,0,0.4},
											shapeType = ROUNDED,
											rounded = 8 } )
		local bClanClan = UIElement:new( {	parent = bClanClanBG,
											pos = { 2, 2 },
											size = { bClanClanBG.size.w - 4, bClanClanBG.size.h - 4 },
											bgColor = { 0.8,0,0,1},
											shapeType = ROUNDED,
											rounded = 6,
											interactive = true,
											hoverColor = { 0.9,0,0,1 },
											pressedColor = { 0.6,0,0,1 },
											innerShadow = {0, 3},
											shadowColor = { {0,0,0,0}, {0.6,0,0,1} } } )
		bClanClan:addCustomDisplay(false, function()
			bClanClan:uiText("View Clan on toribash.com", nil, bClanClan.pos.y + 3, FONTS.BIG, nil, 0.6, nil, 1.5)
		end)
		bClanClan:addMouseHandlers(function() end, function()
			open_url("http://forum.toribash.com/clan.php?clanid=" .. bClan.clanid)
		end, function() end)
		local bClanForumBG = UIElement:new( {	parent = bClanView,
												pos = { -500, 245 },
												size = { 475, 50 },
												bgColor = {0,0,0,0.4},
												shapeType = ROUNDED,
												rounded = 8 } )
		local bClanForum = UIElement:new( {	parent = bClanForumBG,
											pos = { 2, 2 },
											size = { bClanForumBG.size.w - 4, bClanForumBG.size.h - 4 },
											bgColor = { 0.8,0,0,1},
											shapeType = ROUNDED,
											rounded = 6,
											interactive = true,
											hoverColor = { 0.9,0,0,1 },
											pressedColor = { 0.6,0,0,1 },
											innerShadow = {0, 3},
											shadowColor = { {0,0,0,0}, {0.6,0,0,1} } } )
		bClanForum:addCustomDisplay(false, function()
			bClanForum:uiText("View Clan Forum", nil, bClanForum.pos.y + 3, FONTS.BIG, nil, 0.6, nil, 1.5)
		end)
		bClanForum:addMouseHandlers(function() end, function()
			open_url("http://forum.toribash.com/forumdisplay.php?f=" .. bClan.forumid)
		end, function() end)
		local bClanDiscordBG = UIElement:new( {	parent = bClanView,
												pos = { -500, 300 },
												size = { 475, 50 },
												bgColor = {0,0,0,0.4},
												shapeType = ROUNDED,
												rounded = 8 } )
		local bClanDiscord = UIElement:new( {	parent = bClanDiscordBG,
												pos = { 2, 2 },
												size = { bClanDiscordBG.size.w - 4, bClanDiscordBG.size.h - 4 },
												bgColor = { 0.44, 0.53, 0.85, 1 },
												shapeType = ROUNDED,
												rounded = 6,
												interactive = true,
												hoverColor = { 0.54, 0.63, 0.95, 1 },
												pressedColor = { 0.44, 0.43, 0.75, 1 },
												innerShadow = {0, 3},
												shadowColor = { {0,0,0,0}, {0.35, 0.42, 0.68, 1} } } )
		local bClanDiscordLogo = UIElement:new( {	parent = bClanDiscordBG,
													pos = { 20, 0 },
													size = {50, 50},
													bgImage = "system/discordLogo.tga" } )
		bClanDiscord:addCustomDisplay(false, function()
			bClanDiscord:uiText("Clan Discord", nil, bClanDiscord.pos.y + 3, FONTS.BIG, nil, 0.6, nil, 1.5)
		end)
		bClanDiscord:addMouseHandlers(function() end, function()
			open_url(bClan.discordInvite)
		end, function() end)
		local bClanJoinBG = UIElement:new( {	parent = bClanView,
											pos = { 20, -80 },
											size = { bClanView.size.w - 40, 60 },
											bgColor = {0,0,0,0.4},
											shapeType = ROUNDED,
											rounded = 8 } )
		local bClanJoin = UIElement:new( {	parent = bClanJoinBG,
											pos = { 2, 2 },
											size = { bClanJoinBG.size.w - 4, bClanJoinBG.size.h - 4 },
											bgColor = { 0.8,0,0,1},
											shapeType = ROUNDED,
											rounded = 6,
											interactive = true,
											hoverColor = { 0.9,0,0,1 },
											pressedColor = { 0.6,0,0,1 },
											innerShadow = {0, 3},
											shadowColor = { {0,0,0,0}, {0.6,0,0,1} } } )
		bClanJoin:addCustomDisplay(false, function()
			bClanJoin:uiText("Join Clan", nil, bClanJoin.pos.y + 10, FONTS.BIG, nil, 0.6, nil, 1.5)
		end)
		bClanJoin:addMouseHandlers(function() end, function()
			open_url("http://forum.toribash.com/clan.php?clanid=" .. bClan.clanid .. "&join=1")
		end, function() end)
	end
	
	function BeginnerClans:showQuit(opt)
		local bQuitViewFade = UIElement:new( {	parent = beginnerClans,
												pos = { 0, 0 },
												size = { beginnerClans.size.w, beginnerClans.size.h },
												shapeType = beginnerClans.shapeType,
												rounded = beginnerClans.rounded,
												interactive = true,
												bgColor = { 0, 0, 0, 0.8 } } )
		local bQuitView = UIElement:new( {	parent = bQuitViewFade,
											pos = { bQuitViewFade.size.w / 2 - 225, bQuitViewFade.size.h / 2 - 70 },
											size = { 450, 140 },
											shapeType = bQuitViewFade.shapeType,
											rounded = bQuitViewFade.rounded,
											bgColor = {0.7, 0, 0, 1},
											innerShadow = {0, 5},
											shadowColor = { {0,0,0,0}, {0.5,0,0,1} } } )
		local bQuitText = UIElement:new( {	parent = bQuitView,
											pos = { 10, 5 },
											size = { bQuitView.size.w - 20, 80 } } )
		bQuitText:addCustomDisplay(false, function()
			bQuitText:uiText("Do you want to see this message on next game launch?", nil, nil, FONTS.BIG, nil, 0.45, nil, 1)
		end)
		local bQuitShow = UIElement:new( {	parent = bQuitView,
											pos = { -bQuitView.size.w / 2 + 10, -80 },
											size = { bQuitView.size.w / 2 - 20, 70 },
											bgColor = { 0.8,0,0,1},
											shapeType = ROUNDED,
											rounded = 15,
											interactive = true,
											hoverColor = { 0.9,0,0,1 },
											pressedColor = { 0.6,0,0,1 } } )
		bQuitShow:addCustomDisplay(false, function()
			bQuitShow:uiText("Yes", nil, nil, FONTS.BIG, nil, 0.6, nil, 1.5)
			bQuitShow:uiText("I may join later", nil, bQuitShow.pos.y + 40, nil, nil, 0.8, nil, 1)
		end)
		bQuitShow:addMouseHandlers(function() end, function()
			beginnerClansBG:kill()
			remove_hooks("beginnerClansVisual")
			--remove_hooks("uiMouseHandler")
		end, function() end)
		local bQuitCancel = UIElement:new( {	parent = bQuitView,
												pos = { 10, -80 },
												size = { bQuitView.size.w / 2 - 20, 70 },
												bgColor = { 0.8,0,0,1},
												shapeType = ROUNDED,
												rounded = 15,
												interactive = true,
												hoverColor = { 0.9,0,0,1 },
												pressedColor = { 0.6,0,0,1 } } )
		bQuitCancel:addCustomDisplay(false, function()
			bQuitCancel:uiText("No", nil, nil, FONTS.BIG, nil, 0.6, nil, 1.5)
			bQuitCancel:uiText("Never show this again", bQuitCancel.pos.x + 3, bQuitCancel.pos.y + 40, nil, nil, 0.8, nil, 1)
		end)
		bQuitCancel:addMouseHandlers(function() end, function()
			beginnerClansBG:kill()
			set_option(BEGINNERCLANUIOPT, 2)
			remove_hooks("beginnerClansVisual")
			--remove_hooks("uiMouseHandler")
		end, function() end)
	end

	function BeginnerClans:drawVisuals()
		for i, v in pairs(UIElementManager) do
			v:updatePos()
		end
		for i, v in pairs(UIVisualManager) do
			v:display()
		end
	end
		
end