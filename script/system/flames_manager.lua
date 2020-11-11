-- Flames Manager

FLAMES_MENU_POS = FLAMES_MENU_POS or { x = 10, y = 10 }
FLAMES_LIST_SHIFT = FLAMES_LIST_SHIFT or { 0, 0, 1 }

do
	-- Gamerules manager class
	Flames = {}
	Flames.__index = Flames
	local cln = {}
	setmetatable(cln, Flames)
	
	function Flames:getFlameParameters()
		return {
			{ name = "FLAME_BODYPART", min = 0, max = 20 },
			{ name = "FLAME_TIMESTEP", value = math.random(30, 100), min = 0, max = 100 },
			{ name = "FLAME_DAMPING", value = 100, min = 0, max = 100 },
			{ name = "FLAME_BLEND", value = 0, toggle = true },
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
			{ name = "FLAME_ROTATABLE", value = 1, toggle = true },
			{ name = "FLAME_GRAVITY_X", value = 0, min = -100, max = 100 },
			{ name = "FLAME_GRAVITY_Y", value = 0, min = -100, max = 100 },
			{ name = "FLAME_GRAVITY_Z", value = 25, min = -100, max = 100 },
			{ name = "FLAME_VELOCITY_X", value = 0, min = -100, max = 100 },
			{ name = "FLAME_VELOCITY_Y", value = 0, min = -100, max = 100 },
			{ name = "FLAME_VELOCITY_Z", value = 0, min = -100, max = 100 },
			{ name = "FLAME_VELOCITY_RANDOM", value = 0, min = 0, max = 100 },
			{ name = "FLAME_ORBIT", value = 0, toggle = true },
			{ name = "FLAME_ORBIT_BODYPART", value = 0, depends = 39, min = 0, max = 20	},
			{ name = "FLAME_ORBIT_MAGNITUDE", value = 0, depends = 39, min = 0, max = 100 },
			{ name = "FLAME_ORBIT_EPSILON", value = 0, depends = 39, min = 0, max = 100 },
			{ name = "FLAME_GRAVITATE", value = 0, toggle = true },
			{ name = "FLAME_GRAVITATE_MAGNITUDE", value = 0, depends = 43, min = 0, max = 100 },
			{ name = "FLAME_GRAVITATE_EPSILON", value = 0, depends = 43, min = 0, max = 100 },
			{ name = "FLAME_GRAVITATE_MAX_RADIUS", value = 0, depends = 43, min = 0, max = 100 },
			{ name = "FLAME_FOLLOW", value = 0, toggle = true },
			{ name = "FLAME_FOLLOW_MAGNITUDE", value = 0, depends = 47, min = 0, max = 100 },
			{ name = "FLAME_FOLLOW_EPSILON", value = 0, depends = 47, min = 0, max = 100 },
			{ name = "FLAME_SINK_BODY", value = 0, toggle = true },
			{ name = "FLAME_SINK_BODY_BODYPART", value = 0, depends = 50, min = 0, max = 100 },
			{ name = "FLAME_SINK_BODY_RADIUS", value = 0, depends = 50, min = 0, max = 100 },
			{ name = "FLAME_ROTATABLE_GRAVITY", value = 1, toggle = true }
		}
	end
	
	function Flames:spawnFlameSettings(listingHolder, toReload, elementHeight, flameParameters, focusedParam)
		local flameParameters = flameParameters or Flames:getFlameParameters()
		
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
		for i,param in pairs(flameParameters) do
			param.value = param.value or math.random(param.min, param.max)
			local xShift = param.depends and 10 or 0
			if (not param.depends or flameParameters[param.depends].value == 1) then
				param.name = param.name:gsub("FLAME", ""):gsub("_", " ")
				local paramHolder = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight },
					bgColor = TB_MENU_DEFAULT_BG_COLOR
				})
				table.insert(listElements, paramHolder)
				local pHolder = UIElement:new({
					parent = paramHolder,
					pos = { 6, 2 },
					size = { paramHolder.size.w - 9, paramHolder.size.h - 4 },
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
							focusedParam = i
							set_flame_setting(i - 1, val)
							param.value = val
						end)
				else
					local paramSettings = {
						maxValue = param.max or 100,
						minValue = param.min or 0,
						boundParent = listingHolder.parent
					}
					local updateFunc = function(val, xPos, slider)
						focusedParam = i
						set_flame_setting(i - 1, slider.label.labelText[1])
						param.value = slider.label.labelText[1]
						if (i == 1 or i == 40) then
							local bodyName = '?'
							for bodyPart,v in pairs(BODYPARTS) do
								if (tonumber(v) == tonumber(slider.label.labelText[1])) then
									bodyName = bodyPart
								end
							end
							slider.label.labelText[1] = bodyName
						end
					end
					local pSlider = TBMenu:spawnSlider(pValueHolder, 0, 0, nil, nil, 30, 20, param.value, paramSettings, updateFunc)
				end
				pName:addAdaptedText(true, param.name, nil, nil, nil, LEFTMID, xShift > 0 and 0.75 or 0.9)
			end
			set_flame_setting(i - 1, param.value)
		end
		
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
		
		scrollBar:makeScrollBar(listingHolder, listElements, toReload, GAMERULES_LIST_SHIFT)
		
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
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(mainList, 80, 50, 15, TB_MENU_DEFAULT_BG_COLOR)
		
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
			pos = { 10, mainMoverHolder.size.h + mainMoverHolder.shift.y },
			size = { topBar.size.w - 20, topBar.size.h - mainMoverHolder.size.h - mainMoverHolder.shift.y * 2 }
		})
		flamesName:addAdaptedText(true, "Flame Forger", nil, nil, FONTS.BIG, nil, 0.6)
		
		Flames:spawnFlameSettings(listingHolder, toReload, elementHeight)
		
		local flamesCreateButton = UIElement:new({
			parent = botBar,
			pos = { 10, 5 },
			size = { botBar.size.w - 20, botBar.size.h - 10 },
			shapeType = ROUNDED,
			rounded = 3,
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		flamesCreateButton:addAdaptedText(false, "Spawn Flame")
		flamesCreateButton:addMouseHandlers(nil, function()
			
			end)
		
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
				mainView:kill()
				FLAMES_MENU_MAIN_ELEMENT = nil
			end)
	end
end
