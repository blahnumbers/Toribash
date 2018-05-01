do
	ES = {}
    ES.__index = ES
    
	ESVIEWLASTPOST = ESVIEWLASTPOST or {20, 20}
	
    function ES:create()
		local cln = {}
		setmetatable(cln, ES)
    end
	
	function ES:showMain()
		esBG = UIElement:new( {	pos = ESVIEWLASTPOST,
	 							size = {400, 300},
								bgColor = {0.2,0.2,0.2,1},
								shapeType = ROUNDED,
								rounded = 10,
								innerShadow = {15, 15},
								shadowColor = { { 0.2,0.2,0.2,1 }, { 0.1,0.1,0.1,1 } },
								interactive = true } )
		esBG:addMouseHandlers(
			function(s,x,y)
				esBG.pressedPos.x = esBG.pos.x - x
				esBG.pressedPos.y = esBG.pos.y - y
			end, nil, 
			function(x,y)
				if (esBG.hoverState == BTN_DN) then
					local posX = x + esBG.pressedPos.x
					local posY = y + esBG.pressedPos.y
					esBG:moveTo(posX, posY)
					ESVIEWLASTPOST = { posX, posY }
				end
			end)
		local esQuit = UIElement:new( {	parent = esBG,
										pos = {-45,5},
										size = {40,40},
										bgColor = {0.4,0.4,0.4,1},
										interactive = true,
										shapeType = ROUNDED,
										rounded = 10,
										pressedColor = {0.8,0.2,0.2,1},
										hoverColor = {0.05,0.05,0.05,1} } )
		esQuit:addCustomDisplay(false, function()
			local indent = 10
			local weight = 5
			-- Quit button
			if (esQuit.hoverState == BTN_DN) then
				set_color(0,0,0,1)
			else
				set_color(1,1,1,1)
			end
			draw_line(esQuit.pos.x + indent, esQuit.pos.y + indent, esQuit.pos.x + esQuit.size.w - indent, esQuit.pos.y + esQuit.size.h - indent, weight)
			draw_line(esQuit.pos.x + esQuit.size.w - indent, esQuit.pos.y + indent, esQuit.pos.x + indent, esQuit.pos.y + esQuit.size.h - indent, weight)
		end)
		esQuit:addMouseHandlers(function() end, function()
				remove_hooks("esAssistantVisual")
				esBG:kill()
			end, function() end)
		ES:showMainPage()
	end
	
	function ES:showMainPage()
		local esMainView = UIElement:new( {	parent = esBG,
											pos = {0,0},
											size = {esBG.size.w, esBG.size.h} } )
		local esSetupButton = UIElement:new( {	parent = esMainView,
												pos = {20,60},
												size = {esMainView.size.w - 40, 40},
												bgColor = {0.7,0.7,0.7,1},
												shapeType = ROUNDED,
												rounded = 5,
												innerShadow = {5,5},
												shadowColor = {{0.95,0.95,0.95,1},{0.4,0.4,0.4,1}},
												interactive = true,
												hoverColor = {0.85,0.85,0.85,1},
												pressedColor = {0.55,0.55,0.55,1} } )
		esSetupButton:addCustomDisplay(false, function()
				esSetupButton:uiText("Setup Room", nil, esSetupButton.pos.y + 6, nil, nil, nil, nil, 1)
			end)
		esSetupButton:addMouseHandlers(function() end, function()
				esMainView:kill()
				ES:showSetup()
			end, function() end)
		local esStartButton = UIElement:new( {	parent = esMainView,
												pos = {20,110},
												size = {esMainView.size.w - 40, 40},
												bgColor = {0.7,0.7,0.7,1},
												shapeType = ROUNDED,
												rounded = 5,
												innerShadow = {5,5},
												shadowColor = {{0.95,0.95,0.95,1},{0.4,0.4,0.4,1}},
												interactive = true,
												hoverColor = {0.85,0.85,0.85,1},
												pressedColor = {0.55,0.55,0.55,1} } )
		esStartButton:addCustomDisplay(false, function()
				esStartButton:uiText("Start event", nil, esStartButton.pos.y + 6, nil, nil, nil, nil, 1)
			end)
		esStartButton:addMouseHandlers(function() end, function()
				esMainView:kill()
				ES:showEventStart()
			end, function() end)
	end
	
	function ES:showSetup()
		local ROOMSETUPDATA = getRoomSetupData()
		local esSetupView = UIElement:new( {	parent = esBG,
												pos = {0,0},
												size = {esBG.size.w, esBG.size.h} } )
		local esSetupTitle = UIElement:new( {	parent = esSetupView,
												pos = {0,5},
												size = {esSetupView.size.w - 95, 40} } )
		esSetupTitle:addCustomDisplay(false, function()
				esSetupTitle:uiText("Room Setup", nil, nil, FONTS.BIG, nil, 0.65, nil, 1.5)
			end)
		local esBackButton = UIElement:new( {	parent = esSetupView,
												pos = {-90,5},
												size = {40,40},
												bgColor = {0.4,0.4,0.4,1},
												interactive = true,
												shapeType = ROUNDED,
												rounded = 10,
												pressedColor = {0.7,0.7,0.7,1},
												hoverColor = {0.05,0.05,0.05,1} } )
		esBackButton:addMouseHandlers(function() end, function()
				esSetupView:kill()
				ES:showMainPage()
			end, function() end)
		esBackButton:addCustomDisplay(false, function()
			local indent = 10
			local weight = 5
			-- Back button
			if (esBackButton.hoverState == BTN_DN) then
				set_color(0,0,0,1)
			else
				set_color(1,1,1,1)
			end
			draw_line(esBackButton.pos.x + esBackButton.size.w / 2, esBackButton.pos.y + esBackButton.size.h / 2, esBackButton.pos.x + esBackButton.size.w - indent, esBackButton.pos.y + esBackButton.size.h / 2, weight)
			draw_disk(esBackButton.pos.x + esBackButton.size.w / 5 * 2, esBackButton.pos.y + esBackButton.size.h / 2, 0, 9, 3, 1, -90, 360, 0)
		end)
		local esSetupOptions = {}
		local esSetupInputs = {}
		for i = 1, #ROOMSETUPDATA do
			esSetupOptions[i] = UIElement:new( {	parent = esSetupView,
													pos = { 10, 50 + 28 * (i - 1) },
													size = { 140, 25 } } )
			esSetupOptions[i]:addCustomDisplay(false, function()
					esSetupOptions[i]:uiText(ROOMSETUPDATA[i].name, nil, nil, nil, RIGHT, nil, nil, 1)
				end)
			esSetupInputs[i] = UIElement:new( {	parent = esSetupView,
												pos = {160, 50 + 28 * (i - 1)},
												size = {esSetupView.size.w - 170, 25},
												bgColor = {0.9,0.9,0.9,1},
												interactive = true,
												textfield = true,
												textfieldstr = ROOMSETUPDATA[i].value,
											 	isNumeric = ROOMSETUPDATA[i].isNumeric } )
			esSetupInputs[i]:addCustomDisplay(false, function()
					esSetupInputs[i]:uiText(esSetupInputs[i].textfieldstr[1], esSetupInputs[i].pos.x + 5, esSetupInputs[i].pos.y + 3, 1, LEFT, nil, nil, nil, UICOLORBLACK)
					if (esSetupInputs[i].keyboard) then
						if (math.floor(os.clock() * 1.5 % 2) == 1) then
							esSetupInputs[i]:uiText(esSetupInputs[i].textfieldstr[1] .. " ", esSetupInputs[i].pos.x + 5, esSetupInputs[i].pos.y + 3, 1, LEFT, nil, nil, nil, UICOLORBLACK)
						else 
							esSetupInputs[i]:uiText(esSetupInputs[i].textfieldstr[1] .. "|", esSetupInputs[i].pos.x + 5, esSetupInputs[i].pos.y + 3, 1, LEFT, nil, nil, nil, UICOLORBLACK)
						end
					end
				end)
		end
		
		local esSetupRunButton = UIElement:new( {	parent = esSetupView,
													pos = {20, -60},
													size = {esSetupView.size.w - 40, 50},
													bgColor = {0.7,0.7,0.7,1},
													shapeType = ROUNDED,
													rounded = 5,
													innerShadow = {5,5},
													shadowColor = {{0.95,0.95,0.95,1},{0.4,0.4,0.4,1}},
													interactive = true,
													hoverColor = {0.85,0.85,0.85,1},
													pressedColor = {0.55,0.55,0.55,1} } )
		esSetupRunButton:addCustomDisplay(false, function()
				esSetupRunButton:uiText("Begin Tournament", nil, esSetupRunButton.pos.y + 5, FONTS.BIG, nil, 0.6, nil, 1.5)
			end)
		esSetupRunButton:addMouseHandlers(function() end, function()
				runCommands(ROOMSETUPDATA)
			end, function() end)
	end
	
	function ES:showEventStart()
		local WELCOMEMESSAGE = getWelcomeMessage()
		local esStartView = UIElement:new( {	parent = esBG,
												pos = {0,0},
												size = {esBG.size.w, esBG.size.h} } )
		local esStartTitle = UIElement:new( {	parent = esStartView,
												pos = {0,5},
												size = {esStartView.size.w - 95, 40} } )
		esStartTitle:addCustomDisplay(false, function()
				esStartTitle:uiText("Room Start", nil, nil, FONTS.BIG, nil, 0.65, nil, 1.5)
			end)
		local esBackButton = UIElement:new( {	parent = esStartView,
												pos = {-90,5},
												size = {40,40},
												bgColor = {0.4,0.4,0.4,1},
												interactive = true,
												shapeType = ROUNDED,
												rounded = 10,
												pressedColor = {0.7,0.7,0.7,1},
												hoverColor = {0.05,0.05,0.05,1} } )
		esBackButton:addMouseHandlers(function() end, function()
				esStartView:kill()
				ES:showMainPage()
			end, function() end)
		esBackButton:addCustomDisplay(false, function()
			local indent = 10
			local weight = 5
			-- Back button
			if (esBackButton.hoverState == BTN_DN) then
				set_color(0,0,0,1)
			else
				set_color(1,1,1,1)
			end
			draw_line(esBackButton.pos.x + esBackButton.size.w / 2, esBackButton.pos.y + esBackButton.size.h / 2, esBackButton.pos.x + esBackButton.size.w - indent, esBackButton.pos.y + esBackButton.size.h / 2, weight)
			draw_disk(esBackButton.pos.x + esBackButton.size.w / 5 * 2, esBackButton.pos.y + esBackButton.size.h / 2, 0, 9, 3, 1, -90, 360, 0)
		end)
		local esStartDesc = UIElement:new( {	parent = esStartView,
												pos = { 10, 50 },
												size = { 140, 25 } } )
		esStartDesc:addCustomDisplay(false, function()
				esStartDesc:uiText("Message", nil, nil, nil, RIGHT, nil, nil, 1)
			end)
		local esStartMessage = UIElement:new( {	parent = esStartView,
												pos = { 160, 50 },
												size = { esStartView.size.w - 170, 100 },
												bgColor = {0.9,0.9,0.9,1},
												interactive = true,
												textfield = true,
												textfieldstr = WELCOMEMESSAGE[1].value} )
		esStartMessage:addCustomDisplay(false, function()
				esStartMessage:uiText(esStartMessage.textfieldstr[1] .. " ", esStartMessage.pos.x, esStartMessage.pos.y, 1, LEFT, nil, nil, nil, UICOLORBLACK)
				if (esStartMessage.keyboard) then 
					if (math.floor(os.clock() * 1.5 % 2) == 1) then
						esStartMessage:uiText(esStartMessage.textfieldstr[1] .. " ", esStartMessage.pos.x, esStartMessage.pos.y, 1, LEFT, nil, nil, nil, UICOLORBLACK)
					else
						esStartMessage:uiText(esStartMessage.textfieldstr[1] .. "|", esStartMessage.pos.x, esStartMessage.pos.y, 1, LEFT, nil, nil, nil, UICOLORBLACK)
					end
				end
			end)
		local esStartButton = UIElement:new( {	parent = esStartView,
												pos = {20, -60},
												size = {esStartView.size.w - 40, 50},
												bgColor = {0.7,0.7,0.7,1},
												shapeType = ROUNDED,
												rounded = 5,
												innerShadow = {5,5},
												shadowColor = {{0.95,0.95,0.95,1},{0.4,0.4,0.4,1}},
												interactive = true,
												hoverColor = {0.85,0.85,0.85,1},
												pressedColor = {0.55,0.55,0.55,1} } )
	esStartButton:addCustomDisplay(false, function()
			esStartButton:uiText("Begin Tourney", nil, esStartButton.pos.y + 5, FONTS.BIG, nil, 0.6, nil, 1.5)
		end)
	esStartButton:addMouseHandlers(function() end, function()
			runCommands(WELCOMEMESSAGE)
		end, function() end)
	end
	
	function getRoomSetupData()
		return {
			{ name = "Mod", value = { "aikidobigdojo.tbm" }, cmd = "set mod" },
			{ name = "Motd", value = { "test2" }, cmd = "motd" },
			{ name = "Desc", value = { "test" }, cmd = "desc" },
			{ name = "Min Qi", value = { "20" }, cmd = "minbelt", isNumeric = true },
			{ name = "Max Qi", value = { "" }, cmd = "maxbelt", isNumeric = true },
			{ name = "Max Clients", value = { "25" }, cmd = "maxclients", isNumeric = true },
		}
	end
	
	function getWelcomeMessage()
		return {
			{ name = "Message", value = { "Hello and welcome to this tourney!" }, cmd = "centerprint" },
			{ name = "Desc", value = { "aaa" }, cmd = "desc" },
			{ name = "Knockout", value = { "on" }, cmd = "knockout" }
		}
	end
	
	function runCommands(cmd)
		for key, val in pairs(cmd) do
			if (val.value[1] ~= "") then
				echo(val.cmd .. " " .. val.value[1])
				UIElement:runCmd("sa \n" .. val.cmd .. " " .. val.value[1] .. "\n")
			end
		end
	end
	
	function ES:drawVisuals()
		for i, v in pairs(UIElementManager) do
			v:updatePos()
		end
		for i, v in pairs(UIVisualManager) do
			v:display()
		end
	end
end