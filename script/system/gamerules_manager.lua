-- Gamerules manager

GAMERULES_MENU_POS = GAMERULES_MENU_POS or { x = 10, y = 10 }
GAMERULES_LIST_SHIFT = GAMERULES_LIST_SHIFT or { 0, 0, 1 }
GAMERULES_MENU_LAST_CLICKED = nil
GAMERULES_MENU_START_NEW_GAME = get_option("grnewgame")

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
			allowNegative = g.allowNegative,
			allowDecimal = g.allowDecimal,
			dependsAll = g.dependsAll,
			value = nil
		}
		if (g.onSetValue) then
			rule.onSetValue = g.onSetValue
		end
		setmetatable(rule, self)
		if (g.gameValue) then
			rule:setValue(g.gameValue)
		end
		if (g.options) then
			rule:setOptions(g.options)
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

	function Gamerule:setSliderSettings(min, max, isBool, minDisp, maxDisp)
		self.slider = { minValue = min, maxValue = max, isBoolean = isBool, minValueDisp = minDisp, maxValueDisp = maxDisp }
	end

	function Gamerule:setOptions(opts)
		self.options = {}
		self.dropdown = {}
		for i,v in pairs(opts) do
			self.options[i] = { name = v.name, title = v.title, value = v.value }
		end
	end


	-- Gamerules manager class
	Gamerules = {}
	Gamerules.__index = Gamerules
	local cln = {}
	setmetatable(cln, Gamerules)

	function Gamerules:parseEngageValue(val)
		local data = { val:match(("([^,]*),?"):rep(12)) }
		local returnVal = {}

		local toriPos = {}
		table.insert(toriPos, { title = 'x', value = data[1] })
		table.insert(toriPos, { title = 'y', value = data[2] })
		table.insert(toriPos, { title = 'z', value = data[3] })
		local ukePos = {}
		table.insert(ukePos, { title = 'x', value = data[4] })
		table.insert(ukePos, { title = 'y', value = data[5] })
		table.insert(ukePos, { title = 'z', value = data[6] })
		local p3Pos = {}
		table.insert(p3Pos, { title = 'x', value = data[7] })
		table.insert(p3Pos, { title = 'y', value = data[8] })
		table.insert(p3Pos, { title = 'z', value = data[9] })
		local p4Pos = {}
		table.insert(p4Pos, { title = 'x', value = data[10] })
		table.insert(p4Pos, { title = 'y', value = data[11] })
		table.insert(p4Pos, { title = 'z', value = data[12] })

		table.insert(returnVal, toriPos)
		table.insert(returnVal, ukePos)
		table.insert(returnVal, p3Pos)
		table.insert(returnVal, p4Pos)

		return returnVal
	end

	function Gamerules:getRules()
		local rulesList = {
			{ name = "mod", title = "Mod name", type = GAMERULE_STRING, readonly = true },
			{ name = "numplayers", title = "Num Players", type = GAMERULE_ENUM,
				options = {
					{ value = 1, title = "One Player" },
					{ value = 2, title = "Two Players" },
					{ value = 3, title = "Three Players" },
					{ value = 4, title = "Four Players" }
				},
				hidden = get_world_state().game_type == 1,
				triggerUpdate = true
			},
			{ name = "matchframes", title = "Match Frames", type = GAMERULE_INT },
			{ name = "turnframes", title = "Turn Frames", type = GAMERULE_STRING },
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
			{ name = "engagedistance", title = "Engage Distance", type = GAMERULE_INT, allowNegative = true },
			{ name = "engageheight", title = "Engage Height", type = GAMERULE_INT },
			{ name = "engagerotation", title = "Engage Rotation", type = GAMERULE_INT, allowNegative = true },
			--{ name = "engagespace", type = GAMERULE_INT }, -- This is used for 3/4 player mode only, we don't use that
			{ name = "engageplayerpos", title = "Custom Player Position", section = GAMERULES_SECTION_MISC, type = GAMERULE_CUSTOM,
				onSet = function(val)
					if (type(val) ~= "string") then
						return val
					end
					return Gamerules:parseEngageValue(val)
				end,
			 	null = "0,0,0,0,0,0" },
			{ name = "engageplayerrot", title = "Custom Player Rotation", section = GAMERULES_SECTION_MISC, type = GAMERULE_CUSTOM,
				onSet = function(val)
					if (type(val) ~= "string") then
						return val
					end
					return Gamerules:parseEngageValue(val)
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
					if (type(val) ~= "string") then
						return val
					end
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
			{ name = "ghostspeed", title = "Ghost Speed", depends = "ghostcustom", section = GAMERULES_SECTION_GHOST, type = GAMERULE_SLIDER, slider = { 10, 150, false, "0.1x", "5x" },
				onSet = function(val)
					local val = val + 0
					if (val <= 100) then
						return val
					else
						val = (val - 100) / 8
						return val + 100
					end
				end
		 	},
			{ name = "grabmode", title = "Grab Mode", depends = "grip", section = GAMERULES_SECTION_GRAB, triggerUpdate = true, type = GAMERULE_ENUM,
				options = {
					{ value = 0, title = "Fixed" },
					{ value = 1, title = "Rotatable" }
				}
			},
			{ name = "tearthreshold", title = "Tear Threshold", depends = {"grip", "grabmode"}, dependsAll = true, section = GAMERULES_SECTION_GRAB, type = GAMERULE_INT }
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
				gameRule:setSliderSettings(unpack(v.slider))
			end
			local grValue = get_gamerule(v.name)
			if (v.name == "mod") then
				grValue = grValue:find("%.tbm$") and grValue or (grValue .. ".tbm")
				if (grValue:find("%w:")) then
					-- Mod is loaded from disk, escape
					local cnt = 0
					grValue, cnt = grValue:gsub("^.*(data/mod)%/", '')
					if (cnt == 0) then
						grValue = grValue:gsub("^.*%/", '')
					end
					cnt = 0
					grValue, cnt = grValue:gsub("^.*(data\\mod)%\\", '')
					if (cnt == 0) then
						grValue = grValue:gsub("^.*%\\", '')
					end
				end
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

	function Gamerules:showGamerule(v, listingHolder, elementHeight, listElements, sectionId, ruleId, changedValues, updateFunc, prevInput)
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

		if (v.type == GAMERULE_INT or v.type == GAMERULE_STRING) then
			grName.size.w = listingHolder.size.w / 3 * 2 - 10
			if (not v.readonly) then
				local grInput = TBMenu:spawnTextField(grValueHolder, grValueHolder.size.w / 2, nil, grValueHolder.size.w / 2, nil, changedValues[v.name] and changedValues[v.name].value or v.value, { isNumeric = v.type == GAMERULE_INT, allowDecimal = v.allowDecimal, allowNegative = v.allowNegative }, 4, 0.7, UICOLORWHITE, nil, CENTERMID, nil, nil, true)
				grInput:addTabAction(scrollTabFunc)
				if (prevInput) then
					prevInput:addTabSwitch(grInput)
					grInput:addTabSwitchPrev(prevInput)
				end
				local inputLastValue = grInput.textfieldstr[1]
				grInput:addKeyboardHandlers(function()
						if (v.name == "turnframes") then
							local newInput = grInput.textfieldstr[1]:sub(grInput.textfieldindex, grInput.textfieldindex)
							if (newInput:len() > 0 and not newInput:match("[0-9,]")) then
								grInput.textfieldstr[1] = grInput.textfieldstr[1]:sub(0, grInput.textfieldindex - 1) .. grInput.textfieldstr[1]:sub(grInput.textfieldindex + 1)
								grInput.textfieldindex = grInput.textfieldindex - 1
							end
						end
					end, function()
						if (not changedValues[v.name]) then
							changedValues[v.name] = Gamerule:new(v)
						end
						changedValues[v.name]:setValue(grInput.textfieldstr[1])
						if (changedValues[v.name].gameValue ~= inputLastValue) then
							grInput.requireUpdate = true
							inputLastValue = changedValues[v.name].gameValue
						end
					end)
				grInput:addEnterAction(function()
						grInput.keyUpCustom()
						grInput.requireUpdate = false
						updateFunc()
					end)
				if (v.triggerUpdate) then
					local inputUpdater = UIElement:new({
						parent = grInput,
						pos = { 0, 0 },
						size = { 0, 0 }
					})
					local lastValue = grInput.textfieldstr[1]
					inputUpdater:addCustomDisplay(true, function()
							if (grInput.requireUpdate and not grInput.keyboard) then
								if (lastValue ~= grInput.textfieldstr[1] and (lastValue == '0' or grInput.textfieldstr[1] == '0')) then
									grInput.requireUpdate = false
									updateFunc()
								end
							end
						end)
				end
				grInput.name = v.name
				prevInput = grInput
			else
				grValueHolder:addAdaptedText(true, v.value, -4, nil, 4, RIGHTMID, 0.7)
			end
		elseif (v.type == GAMERULE_BOOL) then
			grName.size.w = listingHolder.size.w / 3 * 2 - 10
			local grToggle = TBMenu:spawnToggle(grValueHolder, -grValueHolder.size.h, nil, nil, nil, changedValues[v.name] and changedValues[v.name].value or v.value, function(val)
					if (not changedValues[v.name]) then
						changedValues[v.name] = Gamerule:new(v)
					end
					changedValues[v.name]:setValue(val)
					if (v.triggerUpdate) then
						updateFunc()
					end
				end)

			grToggle:addEnterAction(function()
					GAMERULES_LAST_SELECTED_GAMERULE = v.name
					grToggle.btnUp()
				end)
			grToggle:addTabAction(scrollTabFunc)
			if (prevInput) then
				prevInput:addTabSwitch(grToggle)
				grToggle:addTabSwitchPrev(prevInput)
			end
			grToggle.name = v.name
			prevInput = grToggle
		elseif (v.type == GAMERULE_ENUM) then
			v.dropdown = {}
			local selectedDropdown
			for num,k in pairs(v.options) do
				table.insert(v.dropdown, {
					text = k.title,
					action = function()
						if (not changedValues[v.name]) then
							changedValues[v.name] = Gamerule:new(v)
						end
						changedValues[v.name]:setValue(k.value)
						if (v.triggerUpdate) then
							updateFunc()
						end
					end
				})
				if (not selectedDropdown) then
					if (changedValues[v.name]) then
						if (changedValues[v.name].value == k.value) then
							selectedDropdown = v.dropdown[num]
						end
					elseif (k.value == tonumber(v.value)) then
						selectedDropdown = v.dropdown[num]
					end
				end
			end
			if (not selectedDropdown) then
				selectedDropdown = v.dropdown[1]
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
			TBMenu:spawnDropdown(grDropdownHolder, v.dropdown, 30, 124, selectedDropdown, { scale = 0.6, fontid = 4 }, { scale = 0.5, fontid = 4 })
		elseif (v.type == GAMERULE_SLIDER) then
			local sliderValue = changedValues[v.name] and changedValues[v.name].value or v.value
			local sliderSettings = {
				maxValue = v.slider.maxValue or 1,
				minValue = v.slider.minValue or 0,
				maxValueDisp = v.slider.maxValueDisp or maxVal,
				minValueDisp = v.slider.minValueDisp or minVal,
				isBoolean = v.slider.isBoolean
			}
			if (sliderSettings.maxValueDisp == 128) then
				sliderSettings.maxValueDisp = "100"
			end
			local updateFunc = function(val, xPos, slider)
				if (not changedValues[v.name]) then
					changedValues[v.name] = Gamerule:new(v)
				end
				if (v.name == "ghostspeed") then
					val = val > 100 and (100 + math.floor((val - 100) / 2.5) * 20) or val
					slider.label.labelText[1] = (math.floor(val) / 100) .. ''
				end
				changedValues[v.name]:setValue(val)
			end

			local slider = TBMenu:spawnSlider(grValueHolder, 0, 0, nil, nil, 30, 20, sliderValue, sliderSettings, updateFunc)
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
					local grInput = TBMenu:spawnTextField(grValueInputsHolder, 10 + (grValueInputsHolder.size.w / 3 - 5) * counter, 4, grValueInputsHolder.size.w / 3 - 10, grValueInputsHolder.size.h - 6, k.value, { isNumeric = true, allowDecimal = true, allowNegative = true }, 4, 0.7, UICOLORWHITE, k.title, CENTERMID, nil, nil, true)
					table.insert(gravInputs, grInput)
					counter = counter + 1
				end
				for j,grInput in pairs(gravInputs) do
					grInput:addTabAction(scrollTabFunc)
					if (prevInput) then
						prevInput:addTabSwitch(grInput)
						grInput:addTabSwitchPrev(prevInput)
					end
					grInput:addEnterAction(function()
							grInput.keyUpCustom()
						end)
					grInput:addKeyboardHandlers(nil, function()
							if (not changedValues[v.name]) then
								changedValues[v.name] = Gamerule:new(v)
							end
							local gravity = gravInputs[1].textfieldstr[1] .. " " .. gravInputs[2].textfieldstr[1] .. " " .. gravInputs[3].textfieldstr[1]
							changedValues[v.name]:setValue(gravity)
						end)
					grInput.name = v.name .. j
					prevInput = grInput
				end
			elseif (v.name == "engageplayerpos" or v.name == "engageplayerrot") then
				grHolder.size.h = elementHeight - grHolder.shift.y
				grName.size.w = listingHolder.size.w - 10

				local num_players = changedValues["numplayers"] and changedValues["numplayers"].gameValue or get_gamerule("numplayers")
				local engageInputs = {}
				local playerNames = { "Tori", "Uke", "Nage", "P4" }

				for i = 1, num_players do
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
					grValueTitle:addAdaptedText(true, playerNames[i], nil, nil, nil, LEFTMID, 0.8)
					local grValueInputsHolder = UIElement:new({
						parent = grValueHolderNewline,
						pos = { grValueTitle.shift.x + grValueTitle.size.w + 5, 0 },
						size = { grValueHolderNewline.size.w - grValueTitle.shift.x - grValueTitle.size.w - 15, grValueHolderNewline.size.h },
						shapeType = ROUNDED,
						rounded = 3
					})
					local counter = 0
					-- v.value[i] might be empty... make sure it isn't
					v.value[i] = v.value[i] or { { title = 'x', value = '' }, { title = 'y', value = '' }, { title = 'z', value = '' } }
					for j,k in pairs(v.value[i]) do
						local grInput = TBMenu:spawnTextField(grValueInputsHolder, (grValueInputsHolder.size.w / 3 + 2.5) * counter, 2, grValueInputsHolder.size.w / 3 - 5, grValueInputsHolder.size.h - 4, k.value, { isNumeric = true, allowDecimal = true, allowNegative = true }, 4, 0.7, UICOLORWHITE, k.title, CENTERMID, nil, nil, true)
						table.insert(engageInputs, grInput)
						counter = counter + 1
					end
				end

				for j,grInput in pairs(engageInputs) do
					grInput:addTabAction(scrollTabFunc)
					if (prevInput) then
						prevInput:addTabSwitch(grInput)
						grInput:addTabSwitchPrev(prevInput)
					end
					grInput:addEnterAction(function()
							grInput.keyUpCustom()
						end)
					grInput:addKeyboardHandlers(nil, function()
							if (not changedValues[v.name]) then
								changedValues[v.name] = Gamerule:new(v)
							end
							local engage = ''
							for k,input in pairs(engageInputs) do
								engage = engage .. (engage == '' and '' or ",") .. input.textfieldstr[1]
							end
							changedValues[v.name]:setValue(engage)
						end)
					grInput.name = v.name .. j
					prevInput = grInput
				end
			end
		end
		grName:addAdaptedText(true, v.title, nil, nil, nil, LEFTMID, xShift > 0 and 0.75 or 0.9)
		return prevInput
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
		local lastInput = nil
		local switchTarget, switchNext = false, false
		for x,section in pairs(gamerules) do
			for i,v in pairs(section) do
				if (GAMERULES_LAST_SELECTED_GAMERULE == v.name or switchNext) then
					if (lastInput) then
						switchTarget = lastInput
					else
						switchNext = true
					end
					GAMERULES_LAST_SELECTED_GAMERULE = nil
				end
				if (not v.hidden) then
					if (searchStr:len() > 0) then
						if (v.name:find(searchStr) or v.title:find(searchStr)) then
							lastInput = Gamerules:showGamerule(v, listingHolder, elementHeight, listElements, x, i, changedValues, thisFunc, lastInput)
						end
					else
						if (#v.depends == 0) then
							lastInput = Gamerules:showGamerule(v, listingHolder, elementHeight, listElements, x, i, changedValues, thisFunc, lastInput)
						else
							local dependsCount = v.dependsAll and #v.depends or 1
							for j,rule in pairs(v.depends) do
								if (Gamerules:findRuleValue(rule, gamerules, changedValues)) then
									dependsCount = dependsCount - 1
									if (dependsCount == 0) then
										lastInput = Gamerules:showGamerule(v, listingHolder, elementHeight, listElements, x, i, changedValues, thisFunc, lastInput)
										break
									end
								end
							end
						end
					end
				end
				if (switchTarget) then
					if (switchNext) then
						lastInput.tabswitchprevaction()
					else
						switchTarget.tabswitchaction()
					end
				end
			end
		end
		GAMERULES_LAST_SELECTED_GAMERULE = nil

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
		usage_event("gamerules")
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
			size = { mainView.size.w, mainView.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = mainView.shapeType,
			rounded = mainView.rounded
		})

		local elementHeight = 36
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(mainList, 80, 70, 15, TB_MENU_DEFAULT_BG_COLOR)

		topBar.shapeType = mainView.shapeType
		topBar:setRounded(mainView.rounded)
		botBar.shapeType = mainView.shapeType
		botBar:setRounded(mainView.rounded)

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
		local newGameToggle = TBMenu:spawnToggle(grNewGameToggleView, 5, 2, grNewGameToggleView.size.h - 4, grNewGameToggleView.size.h - 4, GAMERULES_MENU_START_NEW_GAME, function(val) GAMERULES_MENU_START_NEW_GAME = val set_option("grnewgame", val) end)
		local grNewGameText = UIElement:new({
			parent = grNewGameToggleView,
			pos = { 6 + grNewGameToggleView.size.h, 0 },
			size = { grNewGameToggleView.size.w - 10 - grNewGameToggleView.size.h, grNewGameToggleView.size.h }
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
								if (rule.name == "engageplayerpos" and changedValues[rule.name].gameValue:match("^[0%.,]+$")) then
									changedValues[rule.name].gameValue = "0"
								end
								set_gamerule(rule.name, changedValues[rule.name].gameValue)
							end
						end
					end
				end
				if (GAMERULES_MENU_START_NEW_GAME == 1) then
					remove_hooks("tbGamerulesKeyboard")
					mainView:kill()
					GAMERULES_MENU_MAIN_ELEMENT = nil
					if (get_world_state().game_type == 1) then
						local delayedResetter = UIElement:new({
							globalid = TB_MENU_HUB_GLOBALID,
							pos = { 0, 0 },
							size = { 0, 0 }
						})
						delayedResetter.spawnTime = os.clock()
						delayedResetter:addCustomDisplay(true, function()
								if (delayedResetter.spawnTime + 0.5 <= os.clock()) then
									delayedResetter:kill()
									UIElement:runCmd("reset")
								end
							end)
					else
						start_new_game()
					end
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
