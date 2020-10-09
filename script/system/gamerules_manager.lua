-- Gamerules manager

GAMERULES_MENU_POS = GAMERULES_MENU_POS or { x = 10, y = 10 }
GAMERULES_LIST_SHIFT = GAMERULES_LIST_SHIFT or { 0, 0, 1 }
GAMERULES_MENU_LAST_CLICKED = nil
GAMERULES_MENU_START_NEW_GAME = GAMERULES_MENU_START_NEW_GAME == nil and true or GAMERULES_MENU_START_NEW_GAME

GAMERULE_BOOL = 0
GAMERULE_INT = 1
GAMERULE_STRING = 2
GAMERULE_ENUM = 3
GAMERULE_SLIDER = 4
GAMERULE_CUSTOM = 5

GAMERULES_SECTION_DEFAULT = 1
GAMERULES_SECTION_DQ = 2
GAMERULES_SECTION_DISMEMBER = 3
GAMERULES_SECTION_FRACTURE = 4
GAMERULES_SECTION_GHOST = 5
GAMERULES_SECTION_GRAB = 6
GAMERULES_SECTION_MISC = 7

do
	-- Gamerule struct
	Gamerule = {}
	Gamerule.__index = Gamerule
	
	function Gamerule:new(g)
		local rule = {
			name = g.name,
			type = g.type,
			title = g.title,
			depends = type(g.depends) == "table" and g.depends or { g.depends },
			readonly = g.readonly,
			hidden = g.hidden,
			null = g.null or '0',
			triggerUpdate = g.triggerUpdate,
			value = nil
		}
		if (g.onSetValue) then
			rule.onSetValue = g.onSetValue
		end
		setmetatable(rule, self)
		if (g.value) then
			self:setValue(g.value)
		end
		if (g.options) then
			self:setOptions(g.options)
		end
		return rule
	end
	
	function Gamerule:onUpdate(func)
		self.onSetValue = function()
			self.value = func(self.value)
		end
	end
	
	function Gamerule:setValue(value)
		self.value = value
		self.gameValue = value
		if (self.onSetValue) then
			self.onSetValue()
		end
	end
	
	function Gamerule:setSliderSettings(min, max, isBool)
		self.slider = { minValue = min, maxValue = max, isBoolean = isBool }
	end
	
	function Gamerule:setOptions(opts)
		self.options = {}
		self.dropdown = {}
		for i,v in pairs(opts) do
			self.options[i] = { name = v.name, title = v.title }
		end
	end
	
	
	-- Gamerules manager class
	Gamerules = {}
	Gamerules.__index = Gamerules
	local cln = {}
	setmetatable(cln, Gamerules)
	
	function Gamerules:getRules()
		local rulesList = {
			{ name = "mod", title = "Mod name", type = GAMERULE_STRING, readonly = true },
			{ name = "matchframes", title = "Match Frames", type = GAMERULE_INT },
			{ name = "turnframes", title = "Turn Frames", type = GAMERULE_INT },
			{ name = "flags", title = "Flags", type = GAMERULE_INT, hidden = true },
			{ name = "grip", title = "Grip", section = GAMERULES_SECTION_GRAB, triggerUpdate = true, type = GAMERULE_BOOL },
			{ name = "dismemberment", title = "Dismemberment", section = GAMERULES_SECTION_DISMEMBER, triggerUpdate = true, type = GAMERULE_BOOL },
			{ name = "fracture", title = "Fracture", section = GAMERULES_SECTION_FRACTURE, triggerUpdate = true, type = GAMERULE_BOOL },
			{ name = "disqualification", title = "Disqualification", section = GAMERULES_SECTION_DQ, triggerUpdate = true, type = GAMERULE_BOOL },
			{ name = "dqtimeout", title = "DQ Timeout", depends = "disqualification", section = GAMERULES_SECTION_DQ, type = GAMERULE_INT },
			{ name = "dqflag", title = "DQ Mode", depends = "dqtimeout", section = GAMERULES_SECTION_DQ, type = GAMERULE_ENUM,
				options = {
					{ value = 0, title = "Follow Timeout" },
					{ value = 1, title = "Instant Outside Dojo" }
				},
			},
			{ name = "dismemberthreshold", title = "Dismember Threshold", depends = "dismemberment", section = GAMERULES_SECTION_DISMEMBER, type = GAMERULE_INT },
			{ name = "fracturethreshold", title = "Fracture Threshold", depends = "fracture", section = GAMERULES_SECTION_FRACTURE, type = GAMERULE_INT },
			{ name = "pointthreshold", title = "Point Score Threshold", section = GAMERULES_SECTION_MISC, type = GAMERULE_INT },
			{ name = "winpoint", title = "Win Points Requirement", section = GAMERULES_SECTION_MISC, type = GAMERULE_INT },
			{ name = "dojosize", title = "Dojo Size", triggerUpdate = true, type = GAMERULE_INT },
			{ name = "dojotype", title = "Dojo Type", depends = "dojosize", type = GAMERULE_ENUM,
				options = {
					{ value = 0, title = "Square" },
					{ value = 1, title = "Round" }
				},
			},
			{ name = "engagedistance", title = "Engage Distance", type = GAMERULE_INT },
			{ name = "engageheight", title = "Engage Height", type = GAMERULE_INT },
			{ name = "engagerotation", title = "Engage Rotation", type = GAMERULE_INT },
			--{ name = "engagespace", type = GAMERULE_INT }, -- This is used for 3/4 player mode only, we don't use that
			{ name = "engageplayerpos", title = "Custom Player Position", section = GAMERULES_SECTION_MISC, type = GAMERULE_CUSTOM,
				onSet = function(val)
					local data = { val:match(("([^,]*),?"):rep(6)) }
					local returnVal = {}
					local toriPos = {}
					table.insert(toriPos, { title = 'x', value = data[1] })
					table.insert(toriPos, { title = 'y', value = data[2] })
					table.insert(toriPos, { title = 'z', value = data[3] })
					local ukePos = {}
					table.insert(ukePos, { title = 'x', value = data[4] })
					table.insert(ukePos, { title = 'y', value = data[5] })
					table.insert(ukePos, { title = 'z', value = data[6] })
					
					table.insert(returnVal, toriPos)
					table.insert(returnVal, ukePos)
					return returnVal
				end,
			 	null = "0,0,0,0,0,0" },
			{ name = "engageplayerrot", title = "Custom Player Rotation", section = GAMERULES_SECTION_MISC, type = GAMERULE_CUSTOM,
				onSet = function(val)
					local data = { val:match(("([^,]*),?"):rep(6)) }
					local returnVal = {}
					local toriPos = {}
					table.insert(toriPos, { title = 'x', value = data[1] })
					table.insert(toriPos, { title = 'y', value = data[2] })
					table.insert(toriPos, { title = 'z', value = data[3] })
					local ukePos = {}
					table.insert(ukePos, { title = 'x', value = data[4] })
					table.insert(ukePos, { title = 'y', value = data[5] })
					table.insert(ukePos, { title = 'z', value = data[6] })
					
					table.insert(returnVal, toriPos)
					table.insert(returnVal, ukePos)
					return returnVal
				end,
			 	null = "0,0,0,0,0,0" },
			{ name = "damage", title = "Damage Scoring", type = GAMERULE_ENUM,
				options = {
					{ value = 0, title = "Opponent Only" },
					{ value = 1, title = "Both Players" },
					{ value = 2, title = "Only Self" }
				}
			},
			{ name = "gravity", title = "Gravity", type = GAMERULE_CUSTOM,
				onSet = function(val)
					local data = { val:match(("([^ ]*) ?"):rep(3)) }
					local returnVal = {}
					table.insert(returnVal, { title = 'x', value = data[1] })
					table.insert(returnVal, { title = 'y', value = data[2] })
					table.insert(returnVal, { title = 'z', value = data[3] })
					return returnVal
				end
			},
			{ name = "sumo", title = "DQ Sumo Mode", depends = { "disqualification", "dojosize" }, section = GAMERULES_SECTION_DQ, type = GAMERULE_ENUM,
				options = {
					{ value = 0, title = "Hands + Feet" },
					{ value = 1, title = "Hands + Wrists + Feet + Ankles" }
				}
			},
			{ name = "reactiontime", title = "Turn Reaction Time", section = GAMERULES_SECTION_MISC, type = GAMERULE_INT },
			{ name = "drawwinner", title = "Winner on Draw", section = GAMERULES_SECTION_MISC, type = GAMERULE_ENUM,
				options = {
					{ value = 0, title = "Default" },
					{ value = 1, title = "Tori Wins" },
					{ value = 2, title = "Uke Wins" }
				}
			},
			{ name = "maxcontacts", title = "Max Contacts", section = GAMERULES_SECTION_MISC, type = GAMERULE_INT },
			{ name = "ghostcustom", title = "Custom Ghosts", section = GAMERULES_SECTION_GHOST, triggerUpdate = true, type = GAMERULE_BOOL },
			{ name = "ghostlength", title = "Ghost Length", depends = "ghostcustom", section = GAMERULES_SECTION_GHOST, type = GAMERULE_SLIDER, slider = { 0, 500, false },
		 		onSet = function(val)
					return val + 0
				end
			},
			{ name = "ghostspeed", title = "Ghost Speed", depends = "ghostcustom", section = GAMERULES_SECTION_GHOST, type = GAMERULE_SLIDER, slider = { 0.1, 5, false },
				onSet = function(val)
					return (val + 0) / 100
				end
		 	},
			{ name = "grabmode", title = "Grab Mode", depends = "grip", section = GAMERULES_SECTION_GRAB, type = GAMERULE_ENUM,
				options = {
					{ value = 0, title = "Fixed" },
					{ value = 1, title = "Rotatable" }
				}
			},
			{ name = "tearthreshold", title = "Tear Threshold", depends = "grabmode", section = GAMERULES_SECTION_GRAB, type = GAMERULE_INT }
		}
		
		local gameRules = {}
		for i,v in pairs(rulesList) do
			local gameRule = Gamerule:new(v)
			if (v.onSet) then
				gameRule:onUpdate(v.onSet)
			end
			if (v.type == GAMERULE_ENUM) then
				gameRule:setOptions(v.options)
			elseif (v.type == GAMERULE_SLIDER) then
				gameRule:setSliderSettings(v.slider[1], v.slider[2], v.slider[3])
			end
			local grValue = get_gamerule(v.name)
			if (v.name == "mod") then
				grValue = grValue:find("%.tbm$") and grValue or (grValue .. ".tbm")
			end
			gameRule:setValue(grValue)
			v.section = v.section or GAMERULES_SECTION_DEFAULT
			if (not gameRules[v.section]) then
				gameRules[v.section] = {}
			end
			table.insert(gameRules[v.section], gameRule)
		end
		return gameRules
	end
	
	function Gamerules:showGamerule(v, listingHolder, elementHeight, listElements, sectionId, ruleId, changedValues, updateFunc)
		local xShift = (not in_array(sectionId, { GAMERULES_SECTION_DEFAULT, GAMERULES_SECTION_MISC}) and ruleId > 1) and 10 or 0
		local grHolderMain = UIElement:new({
			parent = listingHolder,
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		table.insert(listElements, grHolderMain)
		local grHolder = UIElement:new({
			parent = grHolderMain,
			pos = { 6, 2 },
			size = { grHolderMain.size.w - 9, grHolderMain.size.h - 4 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local grName = UIElement:new({
			parent = grHolder,
			pos = { xShift + 10, 5 },
			size = { grHolder.size.w / 2 - 20 - xShift, grHolder.size.h - 10 }
		})
		local grValueHolder = UIElement:new({
			parent = grHolder,
			pos = { xShift + grName.size.w + grName.shift.x + 5, 2 },
			size = { grHolder.size.w - grName.size.w - grName.shift.x * 2 - 5, grHolder.size.h - 4 },
			shapeType = ROUNDED,
			rounded = 3
		})
		if (v.type == GAMERULE_INT or v.type == GAMERULE_STRING) then
			grName.size.w = listingHolder.size.w / 3 * 2 - 10
			if (not v.readonly) then
				local grInput = TBMenu:spawnTextField(grValueHolder, grValueHolder.size.w / 2, nil, grValueHolder.size.w / 2, nil, changedValues[v.name] and changedValues[v.name].value or v.value, v.type == GAMERULE_INT, 4, 0.7, UICOLORWHITE, nil, CENTERMID, nil, nil, true)
				grInput:addKeyboardHandlers(nil, function()
						if (not changedValues[v.name]) then
							changedValues[v.name] = Gamerule:new(v)
						end
						changedValues[v.name]:setValue(grInput.textfieldstr[1])
						grInput.requireUpdate = true
					end)
				if (v.triggerUpdate) then
					local inputUpdater = UIElement:new({
						parent = grInput,
						pos = { 0, 0 },
						size = { 0, 0 }
					})
					inputUpdater:addCustomDisplay(true, function()
							if (grInput.requireUpdate and not grInput.keyboard) then
								grInput.requireUpdate = false
								updateFunc()
							end
						end)
				end
			else
				grValueHolder:addAdaptedText(true, v.value, -4, nil, 4, RIGHTMID, 0.7)
			end
		elseif (v.type == GAMERULE_BOOL) then
			grName.size.w = listingHolder.size.w / 3 * 2 - 10
			local grToggleValue = changedValues[v.name] and changedValues[v.name].value or v.value
			local grToggleBG = UIElement:new({
				parent = grValueHolder,
				pos = { -grValueHolder.size.h, 0 },
				size = { grValueHolder.size.h, grValueHolder.size.h },
				shapeType = ROUNDED,
				rounded = 3,
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			local grToggleView = UIElement:new({
				parent = grToggleBG,
				pos = { 1, 1 },
				size = { grToggleBG.size.w - 2, grToggleBG.size.h - 2 },
				shapeType = ROUNDED,
				rounded = 3,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
				interactive = true
			})
			local grToggleIcon = UIElement:new({
				parent = grToggleView,
				pos = { 0, 0 },
				size = { grToggleView.size.w, grToggleView.size.h },
				bgImage = "../textures/menu/general/buttons/checkmark.tga"
			})
			if (grToggleValue == '0' or grToggleValue == 0) then
				grToggleIcon:hide(true)
			end
			grToggleView:addMouseHandlers(nil, function()
					grToggleValue = 1 - grToggleValue
					if (grToggleValue == 1) then
						grToggleIcon:show(true)
					else
						grToggleIcon:hide(true)
					end
					if (not changedValues[v.name]) then
						changedValues[v.name] = Gamerule:new(v)
					end
					changedValues[v.name]:setValue(grToggleValue)
					if (v.triggerUpdate) then
						updateFunc()
					end
				end)
		elseif (v.type == GAMERULE_ENUM) then
			v.dropdown = {}
			for value,k in pairs(v.options) do
				table.insert(v.dropdown, {
					text = k.title,
					action = function()
						if (not changedValues[v.name]) then
							changedValues[v.name] = Gamerule:new(v)
						end
						changedValues[v.name]:setValue(value - 1)
					end
				})
			end
			local grDropdownOutline = UIElement:new({
				parent = grValueHolder,
				pos = { 0, 0 },
				size = { grValueHolder.size.w, grValueHolder.size.h },
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				shapeType = ROUNDED,
				rounded = 3
			})
			local grDropdownHolder = UIElement:new({
				parent = grDropdownOutline,
				pos = { 1, 1 },
				size = { grDropdownOutline.size.w - 2, grDropdownOutline.size.h - 2 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
				shapeType = ROUNDED,
				rounded = 3
			})
			TBMenu:spawnDropdown(grDropdownHolder, v.dropdown, 30, 120, v.dropdown[v.value + 1], 0.6, 4, 0.5, 4)
		elseif (v.type == GAMERULE_SLIDER) then
			local value = changedValues[v.name] and changedValues[v.name].value or v.value
			local maxVal = v.slider.maxValue or 1
			local minVal = v.slider.minValue or 0
			local minText = UIElement:new({
				parent = grValueHolder,
				pos = { 0, 0 },
				size = { 30, grValueHolder.size.h }
			})
			minText:addAdaptedText(false, minVal .. "", nil, nil, 4, RIGHTMID, 0.7)
			local maxText = UIElement:new({
				parent = grValueHolder,
				pos = { -30, 0 },
				size = { 30, grValueHolder.size.h }
			})
			maxText:addAdaptedText(false, maxVal == 128 and 100 or maxVal .. "", nil, nil, 4, LEFTMID, 0.7)
			local sliderBG = UIElement:new({
				parent = grValueHolder,
				pos = { 35, 0 },
				size = { grValueHolder.size.w - 70, grValueHolder.size.h },
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				interactive = true
			})
			sliderBG:addCustomDisplay(true, function()
					set_color(unpack(sliderBG.bgColor))
					draw_quad(sliderBG.pos.x, sliderBG.pos.y + grValueHolder.size.h / 2 - 3, sliderBG.size.w, 6)
				end)
			local sliderPos = 0
			value = value > maxVal and 1 or value / maxVal
			sliderPos = value * (sliderBG.size.w - 20)
			local slider = UIElement:new({
				parent = sliderBG,
				pos = { sliderPos, -sliderBG.size.h / 2 - 10 },
				size = { 20, 20 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
				shapeType = ROUNDED,
				rounded = 20
			})
			slider:addMouseHandlers(function()
					slider.pressed = true
					slider.pressedPos = slider:getLocalPos()
				end, function()
					slider.pressed = false
				end, function()
					if (slider.pressed) then
						local xPos = MOUSE_X - sliderBG.pos.x - slider.pressedPos.x
						if (xPos < 0) then
							xPos = 0
						elseif (xPos > sliderBG.size.w - slider.size.w) then
							xPos = sliderBG.size.w - slider.size.w
						end
						if (v.slider.isBoolean) then
							if (xPos + slider.size.w / 2 > sliderBG.size.w / 2) then
								xPos = sliderBG.size.w - slider.size.w
							else
								xPos = 0
							end
						end
						slider:moveTo(xPos, nil)
						changedValues[v.name]:setValue(xPos / (sliderBG.size.w - 20) * (maxVal - minVal) + minVal)
					end
				end)
			sliderBG:addMouseHandlers(function()
				local pos = sliderBG:getLocalPos()
				local xPos = pos.x - slider.size.w / 2
				if (xPos < 0) then
					xPos = 0
				elseif (xPos > sliderBG.size.w - slider.size.w) then
					xPos = sliderBG.size.w - slider.size.w
				end
				slider:moveTo(xPos)
				changedValues[v.name]:setValue(xPos / (sliderBG.size.w - 20) * (maxVal - minVal) + minVal)
			end)
		else
			if (v.name == "gravity") then
				grHolder.size.h = elementHeight - grHolder.shift.y
				local grValueHolderNewlineHolder = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight },
					bgColor = TB_MENU_DEFAULT_BG_COLOR
				})
				table.insert(listElements, grValueHolderNewlineHolder)
				local grValueHolderNewline = UIElement:new({
					parent = grValueHolderNewlineHolder,
					pos = { 6, 0 },
					size = { grValueHolderNewlineHolder.size.w - 9, grValueHolderNewlineHolder.size.h - 2 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				local grValueInputsHolder = UIElement:new({
					parent = grValueHolderNewline,
					pos = { 0, 0 },
					size = { grValueHolderNewline.size.w, grValueHolderNewline.size.h },
					shapeType = ROUNDED,
					rounded = 3
				})
				local gravInputs = {}
				local counter = 0
				for j,k in pairs(v.value) do
					local grInput = TBMenu:spawnTextField(grValueInputsHolder, 10 + (grValueInputsHolder.size.w / 3 - 5) * counter, 4, grValueInputsHolder.size.w / 3 - 10, grValueInputsHolder.size.h - 6, k.value, true, 4, 0.7, UICOLORWHITE, k.title, CENTERMID, nil, nil, true)
					table.insert(gravInputs, grInput)
					counter = counter + 1
				end
				for j,grInput in pairs(gravInputs) do
					grInput:addKeyboardHandlers(nil, function()
							if (not changedValues[v.name]) then
								changedValues[v.name] = Gamerule:new(v)
							end
							local gravity = gravInputs[1].textfieldstr[1] .. " " .. gravInputs[2].textfieldstr[1] .. " " .. gravInputs[3].textfieldstr[1]
							changedValues[v.name]:setValue(gravity)
						end)
				end
			elseif (v.name == "engageplayerpos" or v.name == "engageplayerrot") then
				grHolder.size.h = elementHeight - grHolder.shift.y
				grName.size.w = listingHolder.size.w - 10
				local grValueHolderNewlineHolder = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight },
					bgColor = TB_MENU_DEFAULT_BG_COLOR
				})
				table.insert(listElements, grValueHolderNewlineHolder)
				local grValueHolderNewline = UIElement:new({
					parent = grValueHolderNewlineHolder,
					pos = { 6, 0 },
					size = { grValueHolderNewlineHolder.size.w - 9, grValueHolderNewlineHolder.size.h },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				local grValueTitle = UIElement:new({
					parent = grValueHolderNewline,
					pos = { 10, 0 },
					size = { grValueHolderNewline.size.w / 5, grValueHolderNewline.size.h }
				})
				grValueTitle:addAdaptedText(true, 'Tori', nil, nil, nil, LEFTMID, 0.8)
				local grValueInputsHolder = UIElement:new({
					parent = grValueHolderNewline,
					pos = { grValueTitle.shift.x + grValueTitle.size.w + 5, 0 },
					size = { grValueHolderNewline.size.w - grValueTitle.shift.x - grValueTitle.size.w - 15, grValueHolderNewline.size.h },
					shapeType = ROUNDED,
					rounded = 3
				})
				local engageInputs = {}
				local counter = 0
				for j,k in pairs(v.value[1]) do
					local grInput = TBMenu:spawnTextField(grValueInputsHolder, (grValueInputsHolder.size.w / 3 + 2.5) * counter, 2, grValueInputsHolder.size.w / 3 - 5, grValueInputsHolder.size.h - 4, k.value, true, 4, 0.7, UICOLORWHITE, k.title, CENTERMID, nil, nil, true)
					table.insert(engageInputs, grInput)
					counter = counter + 1
				end
				
				local grValueHolderNewlineHolder2 = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight },
					bgColor = TB_MENU_DEFAULT_BG_COLOR
				})
				table.insert(listElements, grValueHolderNewlineHolder2)
				local grValueHolderNewline2 = UIElement:new({
					parent = grValueHolderNewlineHolder2,
					pos = { 6, 0 },
					size = { grValueHolderNewlineHolder2.size.w - 9, grValueHolderNewlineHolder2.size.h - 2 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				local grValueTitle2 = UIElement:new({
					parent = grValueHolderNewline2,
					pos = { 10, 0 },
					size = { grValueHolderNewline2.size.w / 5, grValueHolderNewline2.size.h }
				})
				grValueTitle2:addAdaptedText(true, 'Uke', nil, nil, nil, LEFTMID, 0.8)
				local grValueInputsHolder2 = UIElement:new({
					parent = grValueHolderNewline2,
					pos = { grValueTitle2.shift.x + grValueTitle2.size.w + 5, 0 },
					size = { grValueHolderNewline2.size.w - grValueTitle2.shift.x - grValueTitle2.size.w - 15, grValueHolderNewline2.size.h },
					shapeType = ROUNDED,
					rounded = 3
				})
				counter = 0
				for j,k in pairs(v.value[2]) do
					local grInput = TBMenu:spawnTextField(grValueInputsHolder2, (grValueInputsHolder2.size.w / 3 + 2.5) * counter, 2, grValueInputsHolder2.size.w / 3 - 5, grValueInputsHolder2.size.h - 4, k.value, true, 4, 0.7, UICOLORWHITE, k.title, CENTERMID, nil, nil, true)
					table.insert(engageInputs, grInput)
					counter = counter + 1
				end
				
				for j,grInput in pairs(engageInputs) do
					grInput:addKeyboardHandlers(nil, function()
							if (not changedValues[v.name]) then
								changedValues[v.name] = Gamerule:new(v)
							end
							local engage = engageInputs[1].textfieldstr[1] .. "," .. engageInputs[2].textfieldstr[1] .. "," .. engageInputs[3].textfieldstr[1] .. "," .. engageInputs[4].textfieldstr[1] .. "," .. engageInputs[5].textfieldstr[1] .. "," .. engageInputs[6].textfieldstr[1]
							changedValues[v.name]:setValue(engage)
						end)
				end
			end
		end
		grName:addAdaptedText(true, v.title, nil, nil, nil, LEFTMID, xShift > 0 and 0.75 or 0.9)
	end
	
	function Gamerules:findRuleValue(ruleName, gamerules, changedValues)
		if (changedValues[ruleName]) then
			return (changedValues[ruleName].gameValue .. '') ~= changedValues[ruleName].null
		end
		
		for i,section in pairs(gamerules) do
			for j,rule in pairs(section) do
				if (rule.name == ruleName) then
					return (rule.gameValue .. '') ~= rule.null
				end
			end
		end
		return nil
	end
	
	function Gamerules:spawnMainList(listingHolder, toReload, gameRulesName, elementHeight, search, gamerules, changedValues)
		-- We need these for collapsible sections
		local lastListHeight = GAMERULES_LIST_SHIFT[2]
		local lastListProgress = GAMERULES_LIST_SHIFT[1] > 0 and GAMERULES_LIST_SHIFT[1] / GAMERULES_LIST_SHIFT[3] or 0
		local targetListShift = listingHolder.shift.y < 0 and -listingHolder.shift.y or listingHolder.size.h
		targetListShift = targetListShift - listingHolder.size.h
		
		if (listingHolder.scrollBar) then
			listingHolder.scrollBar:kill()
		end
		listingHolder:kill(true)
		listingHolder:moveTo(nil, 0)
		
		local searchStr = search and search.textfieldstr[1] or ''
		gameRulesName:addAdaptedText(true, TB_MENU_LOCALIZED.MAINMENUGAMERULESNAME .. ((search and searchStr ~= "") and (": \"" .. searchStr:sub(0, 16) .. (searchStr:len() > 16 and "..." or '') .. "\"") or ""), nil, nil, FONTS.BIG, nil, 0.6)
		
		local thisFunc = function()
			Gamerules:spawnMainList(listingHolder, toReload, gameRulesName, elementHeight, search, gamerules, changedValues)
		end
		
		local listElements = {}
		for x,section in pairs(gamerules) do
			for i,v in pairs(section) do
				if (not v.hidden) then
					if (searchStr:len() > 0) then
						if (v.name:find(searchStr) or v.title:find(searchStr)) then
							Gamerules:showGamerule(v, listingHolder, elementHeight, listElements, x, i, changedValues, thisFunc)
						end
					else
						if (#v.depends == 0) then
							Gamerules:showGamerule(v, listingHolder, elementHeight, listElements, x, i, changedValues, thisFunc)
						else
							for j,rule in pairs(v.depends) do
								if (Gamerules:findRuleValue(rule, gamerules, changedValues)) then
									Gamerules:showGamerule(v, listingHolder, elementHeight, listElements, x, i, changedValues, thisFunc)
									break
								end
							end
						end
					end
				end
			end
		end
		
		if (#listElements == 0) then
			local element = UIElement:new({
				parent = listingHolder,
				pos = { 0, 0 },
				size = { listingHolder.size.w, listingHolder.size.h },
			})
			table.insert(listElements, element)
			element:addAdaptedText(false, TB_MENU_LOCALIZED.NOFILESFOUND .. " :(")
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = scrollBar
		
		-- Set shift for collapsible sections
		GAMERULES_LIST_SHIFT[2] = #listElements * elementHeight
		targetListShift = targetListShift > GAMERULES_LIST_SHIFT[2] - listingHolder.size.h and GAMERULES_LIST_SHIFT[2] - listingHolder.size.h or targetListShift
		GAMERULES_LIST_SHIFT[3] = scrollBar.parent.size.h - scrollBar.size.h
		GAMERULES_LIST_SHIFT[1] = targetListShift / (GAMERULES_LIST_SHIFT[2] - listingHolder.size.h) * GAMERULES_LIST_SHIFT[3]
		
		scrollBar:makeScrollBar(listingHolder, listElements, toReload, GAMERULES_LIST_SHIFT)
	end
	
	function Gamerules:showMain()
		local gamerules = Gamerules:getRules()
		
		local mainView = UIElement:new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { GAMERULES_MENU_POS.x, GAMERULES_MENU_POS.y },
			size = { 400, WIN_H / 4 * 3 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		GAMERULES_MENU_MAIN_ELEMENT = mainView
		GAMERULES_MENU_POS = mainView.pos
		
		local mainList = UIElement:new({
			parent = mainView,
			pos = { 0, 0 },
			size = { mainView.size.w, mainView.size.h},
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local elementHeight = 36
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
		
		local gameRulesName = UIElement:new({
			parent = topBar,
			pos = { 10, mainMoverHolder.size.h + mainMoverHolder.shift.y },
			size = { topBar.size.w - 20, topBar.size.h - mainMoverHolder.size.h - mainMoverHolder.shift.y * 2 }
		})
		
		local changedValues = {}
		add_hook("key_up", "tbGamerulesKeyboard", function(s) return(UIElement:handleKeyUp(s)) end)
		add_hook("key_down", "tbGamerulesKeyboard", function(s) return(UIElement:handleKeyDown(s)) end)
		local searchHolder = UIElement:new({
			parent = botBar,
			pos = { 0, 0 },
			size = { botBar.size.w, botBar.size.h },
			shapeType = ROUNDED,
			rounded = 3
		})
		local search = TBMenu:spawnTextField(searchHolder, 5, 5, searchHolder.size.w - 10, searchHolder.size.h - 45, nil, nil, 1, nil, nil, TB_MENU_LOCALIZED.SEARCHNOTE)
		search:addKeyboardHandlers(nil, function()
				GAMERULES_LIST_SHIFT[1] = 0
				Gamerules:spawnMainList(listingHolder, toReload, gameRulesName, elementHeight, search, gamerules, changedValues)
			end)
		Gamerules:spawnMainList(listingHolder, toReload, gameRulesName, elementHeight, nil, gamerules, changedValues)
		
		local grNewGameToggleView = UIElement:new({
			parent = botBar,
			pos = { 0, -35 },
			size = { botBar.size.w / 2, 30 }
		})
		local grNewGameToggleBG = UIElement:new({
			parent = grNewGameToggleView,
			pos = { 5, 2 },
			size = { grNewGameToggleView.size.h - 4, grNewGameToggleView.size.h - 4 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = ROUNDED,
			rounded = 3
		})
		local grNewGameToggle = UIElement:new({
			parent = grNewGameToggleBG,
			pos = { 1, 1 },
			size = { grNewGameToggleBG.size.w - 2, grNewGameToggleBG.size.h - 2 },
			interactive = true,
			shapeType = ROUNDED,
			rounded = 3,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
		})
		local grNewGameToggleIcon = UIElement:new({
			parent = grNewGameToggle,
			pos = { 0, 0 },
			size = { grNewGameToggle.size.w, grNewGameToggle.size.h },
			bgImage = "../textures/menu/general/buttons/checkmark.tga"
		})
		if (not GAMERULES_MENU_START_NEW_GAME) then
			grNewGameToggleIcon:hide()
		end
		grNewGameToggle:addMouseHandlers(nil, function()
				GAMERULES_MENU_START_NEW_GAME = not GAMERULES_MENU_START_NEW_GAME
				if (not GAMERULES_MENU_START_NEW_GAME) then
					grNewGameToggleIcon:hide()
				else
					grNewGameToggleIcon:show()
				end
			end)
		local grNewGameText = UIElement:new({
			parent = grNewGameToggleView,
			pos = { grNewGameToggleBG.shift.x * 2 + grNewGameToggleBG.size.w, 0 },
			size = { grNewGameToggleView.size.w - grNewGameToggleBG.shift.x * 3 - grNewGameToggleBG.size.w, grNewGameToggleView.size.h }
		})
		grNewGameText:addAdaptedText(true, TB_MENU_LOCALIZED.GAMERULESRESTARTGAME, nil, nil, 4, LEFTMID, 0.7)
		
		local grNewGameButton = UIElement:new({
			parent = botBar,
			pos = { botBar.size.w / 2 + 5, -35 },
			size = { botBar.size.w / 2 - 10, 28 },
			shapeType = ROUNDED,
			rounded = 3,
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		grNewGameButton:addAdaptedText(false, "Apply")
		grNewGameButton:addMouseHandlers(nil, function()
				for i,section in pairs(gamerules) do
					for j,rule in pairs(section) do
						if (changedValues[rule.name]) then
							if (changedValues[rule.name].gameValue ~= rule.gameValue) then
								set_gamerule(rule.name, changedValues[rule.name].gameValue)
							end
						end
					end
				end
				remove_hooks("tbGamerulesKeyboard")
				mainView:kill()
				GAMERULES_MENU_MAIN_ELEMENT = nil
				if (GAMERULES_MENU_START_NEW_GAME) then
					start_new_game()
				end
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
				remove_hooks("tbGamerulesKeyboard")
				mainView:kill()
				GAMERULES_MENU_MAIN_ELEMENT = nil
			end)
	end
end
