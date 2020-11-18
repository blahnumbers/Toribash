-- Flames Manager

FLAMES_MENU_POS = FLAMES_MENU_POS or { x = 10, y = 10 }
FLAMES_LIST_SHIFT = FLAMES_LIST_SHIFT or { 0, 0, 1 }
FLAMES_USER_DATA = FLAMES_USER_DATA or { }
FLAME_DIALOG_FORGE = 120

do
	-- Gamerules manager class
	Flames = {}
	Flames.__index = Flames
	local cln = {}
	setmetatable(cln, Flames)
	
	function Flames:storeCurrentFlames()
		for flameid = 0, 4 do
			FLAMES_USER_DATA[flameid] = {}
			local empty = true
			for id = 0, 52 do
				FLAMES_USER_DATA[flameid][id] = get_flame_setting(0, flameid, id)
				if (empty and FLAMES_USER_DATA[flameid][id] ~= 0) then
					empty = false
				end
			end
			FLAMES_USER_DATA[flameid].empty = empty
		end
	end
	
	function Flames:recoverPlayerFlames()
		for flameid,flame in pairs(FLAMES_USER_DATA) do
			for id,val in pairs(flame) do
				if (type(id) == "number") then
					set_flame_setting(id, val, flameid)
				end
			end
		end
	end
	
	function Flames:getFlameGroups()
		return {
			{ name = "General", ids = { 1, 2, 3, 4, 5 } },
			{ name = "Color", ids = { 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 } },
			{ name = "Size", ids = { 17, 18, 19, 20, 21, 22, 23, 24, 25, 26 } },
			{ name = "Gravity & Displacement", ids = { 53, 32, 33, 34, 38, 35, 36, 37, 27, 28, 29, 30, 31 } },
			{ name = "Advanced", ids = { 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52 } }
		}
	end
	
	function Flames:getFlameCostEstimate(flame)
		local cost = 15000 +
			math.abs(flame[4].value) * 20000 +																				-- Blend
			math.abs(flame[10].value / 255) * 10000 +																		-- Color Random
			(math.abs(flame[15].value / 255) * 10000 +																		-- Color Target Random
			math.abs((flame[6].value - flame[11].value) / 255) * 2500 +														-- Color R Diff
			math.abs((flame[7].value - flame[12].value) / 255) * 2500 +														-- Color G Diff
			math.abs((flame[8].value - flame[13].value) / 255) * 2500) * (math.abs(flame[16].value) > 0 and 1 or 0) +		-- Color B Diff
			math.abs(flame[18].value / 100) * 5000 +																		-- Age Limit
			math.abs(flame[21].value / 100) * 30000 +																		-- Emit Amount
			math.abs(flame[22].value / 100) * 10000 +																		-- Size
			(math.abs(flame[22].value - flame[24].value) / 100) * (math.abs(flame[25].value) > 0 and 1 or 0) * 10000 +		-- Size Diff
			math.abs(((flame[23].value + flame[26].value * (flame[25].value > 0 and 1 or 0)) / 100)) * 5000 +				-- Size Random
			math.abs(flame[27].value / 100) * 2500 +																		-- Displace X
			math.abs(flame[28].value / 100) * 2500 + 																		-- Displace Y
			math.abs(flame[29].value / 100) * 2500 +																		-- Displace Z
			math.abs(flame[30].value / 100) * 5000 +																		-- Displace Random
			math.abs(flame[32].value) * 100 +																				-- Gravity X
			math.abs(flame[33].value) * 100 +																				-- Gravity Y
			math.abs(flame[34].value - 30) * 100 +																			-- Gravity Z
			math.abs(flame[35].value) * 100 +																				-- Velocity X
			math.abs(flame[36].value) * 100 +																				-- Velocity Y
			math.abs(flame[37].value) * 100 +																				-- Velocity Z
			math.abs(flame[38].value / 100) * 5000 +																		-- Velocity Random
			math.abs(flame[39].value) * 10000 +																				-- Orbit
			math.abs(flame[43].value) * 10000 +																				-- Gravitate
			math.abs(flame[47].value) * 10000 +																				-- Follow
			math.abs(flame[50].value) * 10000																				-- Sink
		return math.floor(cost / 100) * 100
	end
	
	function Flames:quit()
		if (FLAMES_MENU_MAIN_ELEMENT) then
			FLAMES_MENU_MAIN_ELEMENT:kill()
			FLAMES_MENU_MAIN_ELEMENT = nil
		end
		Flames:recoverPlayerFlames()
		remove_hooks("tbFlamesKeyboard")
	end
	
	function Flames:getFlameParameters()
		return {
			{ name = "FLAME_BODYPART", min = 0, max = 20 },
			{ name = "FLAME_TIMESTEP", value = math.random(30, 100), min = 0, max = 100 },
			{ name = "FLAME_DAMPING", value = 100, min = 0, max = 100 },
			{ name = "FLAME_BLEND", value = 0, toggle = true, hasDependency = true },
			{ name = "FLAME_SINK", value = 1, toggle = true },
			{ name = "FLAME_COLOR_R", min = 0, max = 255 },
			{ name = "FLAME_COLOR_G", min = 0, max = 255 },
			{ name = "FLAME_COLOR_B", min = 0, max = 255 },
			{ name = "FLAME_COLOR_A", min = 0, max = 255 },
			{ name = "FLAME_COLOR_RANDOM", value = 0, min = 0, max = 255 },
			{ name = "FLAME_TARGET_COLOR_R", min = 0, max = 255 },
			{ name = "FLAME_TARGET_COLOR_G", min = 0, max = 255 },
			{ name = "FLAME_TARGET_COLOR_B", min = 0, max = 255 },
			{ name = "FLAME_TARGET_COLOR_A", min = 0, max = 255 },
			{ name = "FLAME_TARGET_COLOR_RANDOM", value = 0, min = 0, max = 255 },
			{ name = "FLAME_TARGET_COLOR_SCALE", value = 30, min = 0, max = 100 },
			{ name = "FLAME_AGE_START", value = 0, min = 0, max = 100 },
			{ name = "FLAME_AGE_LIMIT", value = 60, min = 0, max = 100 },
			{ name = "FLAME_AGE_SIGMA", value = 0, min = 0, max = 200 },
			{ name = "FLAME_EMIT_SCALE", value = 20, min = 0, max = 100 },
			{ name = "FLAME_EMIT_AMOUNT", value = 25, min = 0, max = 100 },
			{ name = "FLAME_SIZE", value = 20, min = 0, max = 100 },
			{ name = "FLAME_SIZE_RANDOM", value = 0, min = 0, max = 100 },
			{ name = "FLAME_TARGET_SIZE", value = 10, min = 0, max = 100 },
			{ name = "FLAME_TARGET_SIZE_SCALE", value = 0, min = 0, max = 100 },
			{ name = "FLAME_TARGET_SIZE_RANDOM", value = 10, min = 0, max = 100 },
			{ name = "FLAME_RANDOM_DISPLACE_X", value = 0, min = 0, max = 100 },
			{ name = "FLAME_RANDOM_DISPLACE_Y", value = 0, min = 0, max = 100 },
			{ name = "FLAME_RANDOM_DISPLACE_Z", value = 0, min = 0, max = 100 },
			{ name = "FLAME_RANDOM_DISPLACE_RANDOM", value = 0, min = 0, max = 100 },
			{ name = "FLAME_RELATIVE_VELOCITY", value = 1, toggle = true },
			{ name = "FLAME_GRAVITY_X", value = 0, min = -100, max = 100 },
			{ name = "FLAME_GRAVITY_Y", value = 0, min = -100, max = 100 },
			{ name = "FLAME_GRAVITY_Z", value = 25, min = -100, max = 100 },
			{ name = "FLAME_VELOCITY_X", value = 0, min = -100, max = 100 },
			{ name = "FLAME_VELOCITY_Y", value = 0, min = -100, max = 100 },
			{ name = "FLAME_VELOCITY_Z", value = 0, min = -100, max = 100 },
			{ name = "FLAME_VELOCITY_RANDOM", value = 0, min = 0, max = 100 },
			{ name = "FLAME_ORBIT", value = 0, toggle = true, hasDependency = true },
			{ name = "FLAME_ORBIT_BODYPART", value = 0, depends = 39, min = 0, max = 20	},
			{ name = "FLAME_ORBIT_MAGNITUDE", value = 0, depends = 39, min = 0, max = 100 },
			{ name = "FLAME_ORBIT_EPSILON", value = 0, depends = 39, min = 0, max = 100 },
			{ name = "FLAME_GRAVITATE", value = 0, toggle = true, hasDependency = true },
			{ name = "FLAME_GRAVITATE_MAGNITUDE", value = 0, depends = 43, min = 0, max = 100 },
			{ name = "FLAME_GRAVITATE_EPSILON", value = 0, depends = 43, min = 0, max = 100 },
			{ name = "FLAME_GRAVITATE_MAX_RADIUS", value = 0, depends = 43, min = 0, max = 100 },
			{ name = "FLAME_FOLLOW", value = 0, toggle = true, hasDependency = true },
			{ name = "FLAME_FOLLOW_MAGNITUDE", value = 0, depends = 47, min = 0, max = 100 },
			{ name = "FLAME_FOLLOW_EPSILON", value = 0, depends = 47, min = 0, max = 100 },
			{ name = "FLAME_SINK_BODY", value = 0, toggle = true, hasDependency = true },
			{ name = "FLAME_SINK_BODY_BODYPART", value = 0, depends = 50, min = 0, max = 20 },
			{ name = "FLAME_SINK_BODY_RADIUS", value = 0, depends = 50, min = 0, max = 100 },
			{ name = "FLAME_RELATIVE_GRAVITY", value = 0, toggle = true }
		}
	end
	
	function Flames:spawnFlameSettings(listingHolder, toReload, elementHeight, flamesData, flameId)
		local flameId = flameId or 0
		local flameParameters
		if (flamesData) then
			flameParameters = flamesData
		else
			flameParameters = cloneTable(FLAMES_USER_DATA)
			for i,flame in pairs(flameParameters) do
				flameParameters[i] = Flames:getFlameParameters()
				if (not flame.empty) then
					for id,v in pairs(flameParameters[i]) do
						flameParameters[i][id].value = flame[id - 1] or flameParameters[i][id].value
					end
				end
			end
		end
		
		local lastListHeight = FLAMES_LIST_SHIFT[2]
		local lastListProgress = FLAMES_LIST_SHIFT[1] > 0 and FLAMES_LIST_SHIFT[1] / FLAMES_LIST_SHIFT[3] or 0
		local targetListShift = listingHolder.shift.y < 0 and -listingHolder.shift.y or listingHolder.size.h
		targetListShift = targetListShift - listingHolder.size.h
		
		if (listingHolder.scrollBar) then
			listingHolder.scrollBar:kill()
		end
		listingHolder:kill(true)
		listingHolder:moveTo(nil, 0)
		
		local scrollTabFunc = function(input, prev)
				local dir = prev and 1 or -1
				local tempX, tempY = MOUSE_X, MOUSE_Y
				MOUSE_X, MOUSE_Y = listingHolder.parent.pos.x + 1, listingHolder.parent.pos.y + 1
				if (not input:isDisplayed()) then
					while (not input:isDisplayed()) do
						listingHolder.scrollBar.btnDown(4, 0, dir)
					end
				end
				if (dir == -1) then
					if (input.pos.y + input.size.h > listingHolder.parent.pos.y + listingHolder.parent.size.h) then
						listingHolder.scrollBar.btnDown(4, 0, -1)
					end
				else
					if (input.pos.y < listingHolder.parent.pos.y) then
						listingHolder.scrollBar.btnDown(4, 0, 1)
					end
				end
				MOUSE_X, MOUSE_Y = tempX, tempY
			end
		
		local listElements = {}
		local nameWidth = listingHolder.size.w / 3 > 180 and 180 or listingHolder.size.w / 3
		local flameGroups = Flames:getFlameGroups()
		for gid,group in pairs(flameGroups) do
			local groupHolder = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			table.insert(listElements, groupHolder)
			local groupName = UIElement:new({
				parent = groupHolder,
				pos = { 20, 3 },
				size = { groupHolder.size.w - 40, groupHolder.size.h - 6 }
			})
			groupName:addAdaptedText(true, group.name, nil, nil, FONTS.BIG, LEFTMID, 0.5)
			for j,i in pairs(group.ids) do
				local param = flameParameters[flameId][i]
				param.value = param.value or math.random(param.min, param.max)
				local xShift = param.depends and 10 or 0
				if (not param.depends or flameParameters[flameId][param.depends].value == 1) then
					param.name = param.name:gsub("FLAME_", ""):gsub("_", " ")
					local paramHolder = UIElement:new({
						parent = listingHolder,
						pos = { 0, #listElements * elementHeight },
						size = { listingHolder.size.w, elementHeight },
						bgColor = TB_MENU_DEFAULT_BG_COLOR
					})
					table.insert(listElements, paramHolder)
					local pHolder = UIElement:new({
						parent = paramHolder,
						pos = { 10, 2 },
						size = { paramHolder.size.w - 10, paramHolder.size.h - 4 },
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
						shapeType = ROUNDED,
						rounded = 3
					})
					local pName = UIElement:new({
						parent = pHolder,
						pos = { xShift + 10, 5 },
						size = { nameWidth - xShift, pHolder.size.h - 10 }
					})
					
					local pValueHolder = UIElement:new({
						parent = pHolder,
						pos = { xShift + pName.size.w + pName.shift.x + 5, 3 },
						size = { pHolder.size.w - pName.size.w - pName.shift.x * 2 - 5, pHolder.size.h - 6 },
						shapeType = ROUNDED,
						rounded = 3
					})
					
					if (param.toggle) then
						local pToggle = TBMenu:spawnToggle(pValueHolder, -pValueHolder.size.h, nil, nil, nil, param.value, function(val)
								param.value = val
								set_flame_setting(i - 1, param.value, flameId)
								toReload.costDisplay.tc = Flames:getFlameCostEstimate(flameParameters[flameId])
								toReload.costDisplay:addAdaptedText(true, "Flame price estimate: " .. toReload.costDisplay.tc .. " TC", nil, nil, nil, LEFTMID)
								if (param.hasDependency) then
									Flames:spawnFlameSettings(listingHolder, toReload, elementHeight, flameParameters, flameId)
								end
							end)
					else
						local paramSettings = {
							maxValue = param.max or 100,
							minValue = param.min or 0,
							boundParent = listingHolder.parent
						}
						local updateFunc = function(val, xPos, slider)
							param.value = tonumber(slider.label.labelText[1])
							set_flame_setting(i - 1, param.value, flameId)
							toReload.costDisplay.tc = Flames:getFlameCostEstimate(flameParameters[flameId])
							toReload.costDisplay:addAdaptedText(true, "Flame price estimate: " .. toReload.costDisplay.tc .. " TC", nil, nil, nil, LEFTMID)
							if (in_array(i, { 1, 40, 51 })) then
								local bodyName = '?'
								for bodyPart,v in pairs(BODYPARTS) do
									if (tonumber(v) == tonumber(slider.label.labelText[1])) then
										bodyName = bodyPart:gsub("^(L_)", "LEFT "):gsub("^(R_)", "RIGHT ")
									end
								end
								slider.label.labelText[1] = bodyName
							end
						end
						local pSlider = TBMenu:spawnSlider(pValueHolder, 0, 0, nil, nil, 30, 20, param.value, paramSettings, updateFunc)
					end
					set_flame_setting(i - 1, param.value, flameId)
					pName:addAdaptedText(true, param.name, nil, nil, nil, LEFTMID, xShift > 0 and 0.75 or 0.9)
				end
			end
		end
		toReload.costDisplay.tc = Flames:getFlameCostEstimate(flameParameters[flameId])
		toReload.costDisplay:addAdaptedText(true, "Flame price estimate: " .. toReload.costDisplay.tc .. " TC", nil, nil, nil, LEFTMID)
		
		for i,v in pairs(listElements) do
			v:hide()
		end
		
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = scrollBar
		
		-- Set shift for collapsible sections
		FLAMES_LIST_SHIFT[2] = #listElements * elementHeight
		targetListShift = targetListShift > FLAMES_LIST_SHIFT[2] - listingHolder.size.h and FLAMES_LIST_SHIFT[2] - listingHolder.size.h or targetListShift
		FLAMES_LIST_SHIFT[3] = scrollBar.parent.size.h - scrollBar.size.h
		FLAMES_LIST_SHIFT[1] = targetListShift / (FLAMES_LIST_SHIFT[2] - listingHolder.size.h) * FLAMES_LIST_SHIFT[3]
		
		scrollBar:makeScrollBar(listingHolder, listElements, toReload, FLAMES_LIST_SHIFT)
		
		return flameParameters
	end
	
	function Flames:showMain()
		local mainView = UIElement:new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { FLAMES_MENU_POS.x, FLAMES_MENU_POS.y },
			size = { 600 > WIN_W / 2 and WIN_W / 2 or 600, WIN_H / 4 * 3 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		FLAMES_MENU_MAIN_ELEMENT = mainView
		FLAMES_MENU_POS = mainView.pos
		
		local mainList = UIElement:new({
			parent = mainView,
			pos = { 0, 0 },
			size = { mainView.size.w, mainView.size.h},
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local elementHeight = 40
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(mainList, 80, 70, 15, TB_MENU_DEFAULT_BG_COLOR)
		
		local mainMoverHolder = UIElement:new({
			parent = topBar,
			pos = { 0, 0 },
			size = { topBar.size.w, 30 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = mainView.shapeType,
			rounded = mainView.rounded
		})
		local mainMover = UIElement:new({
			parent = mainMoverHolder,
			pos = { 0, 0 },
			size = { mainMoverHolder.size.w, mainMoverHolder.size.h },
			interactive = true,
			bgColor = UICOLORWHITE,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
		})
		mainMover:addCustomDisplay(true, function()
				set_color(unpack(mainMover:getButtonColor()))
				local posX = mainMover.pos.x + mainMover.size.w / 2 - 15
				draw_quad(posX, mainMover.pos.y + 10, 30, 2)
				draw_quad(posX, mainMover.pos.y + 18, 30, 2)
			end)
		mainMover:addMouseHandlers(function(s, x, y)
					mainMover.pressedPos.x = x - mainMover.pos.x
					mainMover.pressedPos.y = y - mainMover.pos.y
				end, nil, function(x, y)
				if (mainMover.hoverState == BTN_DN) then
					local x = x - mainMover.pressedPos.x
					local y = y - mainMover.pressedPos.y
						x = x < 0 and 0 or (x + mainView.size.w > WIN_W and WIN_W - mainView.size.w or x)
					y = y < 0 and 0 or (y + mainView.size.h > WIN_H and WIN_H - mainView.size.h or y)
					mainView:moveTo(x, y)
				end
			end)
		
		local flamesName = UIElement:new({
			parent = topBar,
			pos = { 20, mainMoverHolder.size.h + mainMoverHolder.shift.y },
			size = { topBar.size.w / 2 - 25, topBar.size.h - mainMoverHolder.size.h - mainMoverHolder.shift.y * 2 }
		})
		flamesName:addAdaptedText(true, "Flame Forger", nil, nil, FONTS.BIG, LEFTMID, 0.6)
		
		local flameCostEstimate = UIElement:new({
			parent = botBar,
			pos = { 10, 5 },
			size = { botBar.size.w - 20, 22 }
		})
		flameCostEstimate.tc = 0
		toReload.costDisplay = flameCostEstimate
		
		local flameParameters = Flames:spawnFlameSettings(listingHolder, toReload, elementHeight)
		
		local flameIdShift = flamesName.shift.x + flamesName.size.w + 10
		flameIdShift = flameIdShift < topBar.size.w - 240 and topBar.size.w - 240 or flameIdShift
		local flameIdHolder = UIElement:new({
			parent = topBar,
			pos = { flameIdShift, flamesName.shift.y + 5 },
			size = { topBar.size.w - flameIdShift - 10, flamesName.size.h - 10 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = 3
		})
		local currentFlameId = 0
		local flameSlots = {}
		for i = 1, 5 do
			table.insert(flameSlots, {
				text = "Flame Slot " .. i,
				action = function()
					currentFlameId = i - 1
					Flames:spawnFlameSettings(listingHolder, toReload, elementHeight, flameParameters, currentFlameId)
				end
			})
		end
		local flameIdDropdown = TBMenu:spawnDropdown(flameIdHolder, flameSlots, flameIdHolder.size.h / 3 * 2, nil, flameSlots[1], 0.6, 4, 0.5, 4)
		
		local flamesButtonsHolder = UIElement:new({
			parent = botBar,
			pos = { 0, flameCostEstimate.shift.y + flameCostEstimate.size.h },
			size = { botBar.size.w, botBar.size.h - flameCostEstimate.shift.y - flameCostEstimate.size.h }
		})
		local flamesBrowseButton = UIElement:new({
			parent = flamesButtonsHolder,
			pos = { 10, 5 },
			size = { flamesButtonsHolder.size.w / 3 - 13, flamesButtonsHolder.size.h - 10 },
			shapeType = ROUNDED,
			rounded = 3,
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = { 0.6, 0.6, 0.6, 0.6 }
		})
		flamesBrowseButton:deactivate(true)
		flamesBrowseButton:addAdaptedText(false, "Browse")
		flamesBrowseButton:addMouseHandlers(nil, function()
				
			end)
		local flamesCreateButton = UIElement:new({
			parent = flamesButtonsHolder,
			pos = { flamesBrowseButton.shift.x + flamesBrowseButton.size.w + 6, 5 },
			size = { flamesButtonsHolder.size.w - flamesBrowseButton.size.w - flamesBrowseButton.shift.x * 2 - 6, flamesButtonsHolder.size.h - 10 },
			shapeType = ROUNDED,
			rounded = 3,
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		flamesCreateButton:addAdaptedText(false, "Forge Flame")
		flamesCreateButton:addMouseHandlers(nil, function()
				local confirmOverlay = TBMenu:showConfirmationWindowInput("Forging your Flame", "Flame Name",
					function(name)
						local name = name:gsub(";", '')
						if (name == '') then
							TBMenu:showDataError("Flame name cannot be empty", true)
							return
						end
						
						local flameSettingsString = ''
						for i,v in pairs(flameParameters[currentFlameId]) do
							flameSettingsString = flameSettingsString .. v.value .. " "
						end
						
						local overlay = TBMenu:spawnWindowOverlay()
						local loadingMark = UIElement:new({
							parent = overlay,
							pos = { overlay.size.w / 2 - 200, overlay.size.h / 2 - 50 },
							size = { 400, 100 },
							bgColor = TB_MENU_DEFAULT_BG_COLOR
						})
						TBMenu:displayLoadingMarkSmall(loadingMark, TB_MENU_LOCALIZED.REQUESTFINISHINGACTIVE)
						Request:queue(function()
								show_dialog_box(FLAME_DIALOG_FORGE, "Forging '" .. name .. "' flame for " .. flameCostEstimate.tc .. " Toricredits.\nAre you sure?", name .. ";" .. flameCostEstimate.tc .. ";" .. flameSettingsString, true)
								loadingMark:kill(true)
								TBMenu:displayLoadingMarkSmall(loadingMark, TB_MENU_LOCALIZED.NETWORKLOADING)
								
								overlay:addMouseHandlers(nil, nil, function(x)
										if (x < WIN_W / 2) then
											overlay:kill()
											Request:cancelCurrentRequest()
										else
											overlay:addMouseHandlers(nil, nil, function() end)
										end
									end)
								end, "flameforge", function()
									overlay:kill()
									local response = get_network_response()
									local result = response:find("GATEWAY 0; 0")
									local error = not result and response:gsub("GATEWAY 0; 1 ", "") or false
									
									if (error) then
										Files:writeDebug(error)
										TBMenu:showDataError(error, true)
										return
									end
									
									local invid = response:gsub("GATEWAY 0; 0 ", "")
									TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASESUCCESSFUL, function()
											Flames:quit()
											INVENTORY_UPDATE = true
											INVENTORY_MOUSE_POS = { x = posX, y = posY }
											show_dialog_box(INVENTORY_ACTIVATE, TB_MENU_LOCALIZED.STOREDIALOGACTIVATE1 .. " " .. name  .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 .. "?"), invid)
										end)
								end, function()
									overlay:kill()
									TBMenu:showDataError(TB_MENU_LOCALIZED.ERRORTRYAGAIN, true)
								end)
						
					end, nil, "You will be charged " .. flameCostEstimate.tc .. " Toricredits for spawning the flame", TB_MENU_HUB_GLOBALID)
				table.insert(FLAMES_MENU_MAIN_ELEMENT.child, confirmOverlay)
			end)
			
		add_hook("key_up", "tbFlamesKeyboard", function(s) return(UIElement:handleKeyUp(s)) end)
		add_hook("key_down", "tbFlamesKeyboard", function(s) return(UIElement:handleKeyDown(s)) end)
		
		local quitButton = UIElement:new({
			parent = mainMoverHolder,
			pos = { -mainMoverHolder.size.h, 0 },
			size = { mainMoverHolder.size.h , mainMoverHolder.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
			shapeType = ROUNDED,
			rounded = 4
		})
		local quitIcon = UIElement:new({
			parent = quitButton,
			pos = { 2, 2 },
			size = { quitButton.size.w - 4, quitButton.size.h - 4 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		quitButton:addMouseHandlers(nil, function()
				Flames:quit()
			end)
	end
end
