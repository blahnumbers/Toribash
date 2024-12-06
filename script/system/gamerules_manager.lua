-- Gamerules manager
require("toriui.uielement")
require("system.menu_manager")

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

---@alias GameruleType
---| 0 GAMERULE_BOOL
---| 1 GAMERULE_INT
---| 2 GAMERULE_STRING
---| 3 GAMERULE_ENUM
---| 4 GAMERULE_SLIDER
---| 5 GAMERULE_CUSTOM

---@class GameruleOption
---@field value integer
---@field title string

---@class GameruleSliderSettings
---@field minValue number Minimum allowed value
---@field maxValue number Maximum allowed value
---@field isBoolean boolean Whether this slider can only have 2 states
---@field minValueDisp string Minimum value display override
---@field maxValueDisp string Maximum value display override

---@class GameruleBase
---@field name string Internal gamerule name, used for setting the value with Toribash API
---@field type GameruleType
---@field title string Display gamerule name for the UI
---@field readonly boolean
---@field hidden boolean
---@field null string Gamerule default value
---@field triggerUpdate boolean Whether modifying this gamerule should trigger GUI reload
---@field allowNegative boolean Whether this gamerule accepts negative values
---@field allowDecimal boolean Whether this gamerule accepts float values
---@field dependsAll boolean Whether this gamerule depends on all gamerules from `depends` list
---@field onSetValue function Custom function to trigger on value change
---@field gameValue string Internal value for Toribash API
---@field options GameruleOption[]
---@field onSet function Custom function to execute when setting gamerule value

---@class GameruleCreateProperties : GameruleBase
---@field depends string|string[] Gamerule name or names that gamerule should depend on
---@field slider table List of initialization values for gamerule slider

---@class Gamerule : GameruleBase
---@field depends string[] List of gamerule names that current gamerule depends on
---@field value any Internal gamerule value
---@field slider GameruleSliderSettings Gamerule slider settings
Gamerule = { }
Gamerule.__index = Gamerule

---Returns a new Gamerule object created from specified settings
---@param g GameruleCreateProperties|Gamerule
---@return Gamerule
function Gamerule.New(g)
	---@type Gamerule
	local rule = {
		name = g.name,
		type = g.type,
		title = g.title,
		---@diagnostic disable-next-line: assign-type-mismatch
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
	setmetatable(rule, Gamerule)
	if (g.gameValue) then
		rule:setValue(g.gameValue)
	end
	if (g.options) then
		rule:setOptions(g.options)
	end
	return rule
end

---Updates Gamerule object's `onSetValue()` function with the specified one
---@param func function
function Gamerule:onUpdate(func)
	self.onSetValue = function()
		self.value = func(self.value)
	end
end

---Sets Gamerule value and triggers `onSetValue()` function if it's specified
---@param value string
function Gamerule:setValue(value)
	self.value = value
	self.gameValue = value
	if (self.onSetValue) then
		self.onSetValue()
	end
end

---Sets Gamerule slider settings
---@param min number
---@param max number
---@param isBool boolean
---@param minDisp string
---@param maxDisp string
function Gamerule:setSliderSettings(min, max, isBool, minDisp, maxDisp)
	self.slider = { minValue = min, maxValue = max, isBoolean = isBool, minValueDisp = minDisp, maxValueDisp = maxDisp }
end

---Sets Gamerule options
---@param opts GameruleOption[]
function Gamerule:setOptions(opts)
	self.options = {}
	self.dropdown = {}
	for i,v in pairs(opts) do
		self.options[i] = { title = v.title, value = v.value }
	end
end

if (Gamerules == nil) then
	local _, top_y = get_window_safe_size()

	---**Gamerules manager class**
	---
	---**Version 5.61**
	---* Updated keyboard input and return types for input fields on mobile devices
	---* Use proper input handler for search bar
	---* Added `Quit()` method to exit Gamerules from other scripts
	---
	---**Version 5.60**
	---* Documentation with EmmyLua annotations
	---@class Gamerules
	---@field MainElement UIElement Gamerules main holder element
	---@field DisplayPos Vector2Base Current gamerules window offset coordinates
	---@field ListShift number[] Gamerules list shift information
	---@field StartNewgame boolean Whether newgame should be triggered when applying changes
	---@field LastSelectedRule string|nil
	Gamerules = {
		DisplayPos = { x = SAFE_X + 10, y = top_y + 10 },
		ListShift = { 0, 0, 1 },
		StartNewgame = get_option("grnewgame") == 1,
		LastSelectedRule = nil,
		ver = 5.61
	}
	Gamerules.__index = Gamerules
end

---Destroys Gamerules main view
function Gamerules.Quit()
	if (Gamerules.MainElement ~= nil) then
		Gamerules.MainElement:kill()
		Gamerules.MainElement = nil
	end
end

---Parses `playerengage`-like gamerules for GUI display
---@param val string
---@return table
function Gamerules.parseEngageValue(val)
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

---Returns the list of Gamerules
---@return Gamerule[]
function Gamerules.getRules()
	---@type GameruleCreateProperties[]
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
				return Gamerules.parseEngageValue(val)
			end,
			null = "0,0,0,0,0,0" },
		{ name = "engageplayerrot", title = "Custom Player Rotation", section = GAMERULES_SECTION_MISC, type = GAMERULE_CUSTOM,
			onSet = function(val)
				if (type(val) ~= "string") then
					return val
				end
				return Gamerules.parseEngageValue(val)
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

	---@type Gamerule[]
	local gameRules = {}
	for _, v in pairs(rulesList) do
		local gameRule = Gamerule.New(v)
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
			grValue = grValue:gsub("^.*[%/%\\]", '')
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

---Displays a single Gamerule
---@param v Gamerule
---@param listingHolder UIElement
---@param elementHeight number
---@param listElements UIElement[]
---@param sectionId integer
---@param ruleId integer
---@param changedValues Gamerule[]
---@param updateFunc function
---@param prevInput? UIElement
---@return UIElement?
function Gamerules.showGamerule(v, listingHolder, elementHeight, listElements, sectionId, ruleId, changedValues, updateFunc, prevInput)
	local xShift = (not in_array(sectionId, { GAMERULES_SECTION_DEFAULT, GAMERULES_SECTION_MISC}) and ruleId > 1) and 10 or 0
	local grHolderMain = listingHolder:addChild({
		pos = { 0, #listElements * elementHeight },
		size = { listingHolder.size.w, elementHeight },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
	})
	table.insert(listElements, grHolderMain)
	local grHolder = grHolderMain:addChild({
		pos = { 6, 2 },
		size = { grHolderMain.size.w - 6, grHolderMain.size.h - 4 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = ROUNDED,
		rounded = 3
	})
	local grName = grHolder:addChild({
		pos = { xShift + 10, 5 },
		size = { grHolder.size.w / 2 - 20 - xShift, grHolder.size.h - 10 }
	})
	local grValueHolder = grHolder:addChild({
		pos = { xShift + grName.size.w + grName.shift.x + 5, 2 },
		size = { grHolder.size.w - grName.size.w - grName.shift.x * 2 - 5, grHolder.size.h - 4 }
	}, true)

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
			local grInput = TBMenu:spawnTextField2(grValueHolder, {
				x = grValueHolder.size.w / 2,
				w = grValueHolder.size.w / 2
			}, changedValues[v.name] and changedValues[v.name].value or v.value, nil, {
				isNumeric = v.type == GAMERULE_INT and v.name ~= "turnframes",
				allowDecimal = v.allowDecimal,
				allowNegative = v.allowNegative,
				fontId = 4,
				textScale = 0.7,
				textAlign = CENTERMID,
				darkerMode = true,
				inputType = (v.allowNegative and _G.PLATFORM == "IPHONEOS") and KEYBOARD_INPUT.ASCII or KEYBOARD_INPUT.NUMBERPAD,
				returnKeyType = KEYBOARD_RETURN.DONE
			})
			grInput:addTabAction(scrollTabFunc)
			if (prevInput) then
				prevInput:addTabSwitch(grInput)
				grInput:addTabSwitchPrev(prevInput)
			end
			local inputLastValue = grInput.textfieldstr[1]
			grInput:addInputCallback(function()
					if (v.name == "turnframes") then
						local newInput = grInput.textfieldstr[1]:sub(grInput.textfieldindex, grInput.textfieldindex)
						if (newInput:len() > 0 and not newInput:match("[0-9,]")) then
							grInput.textfieldstr[1] = grInput.textfieldstr[1]:sub(0, grInput.textfieldindex - 1) .. grInput.textfieldstr[1]:sub(grInput.textfieldindex + 1)
							grInput.textfieldindex = grInput.textfieldindex - 1
						end
					end
					if (not changedValues[v.name]) then
						changedValues[v.name] = Gamerule.New(v)
					end
					changedValues[v.name]:setValue(grInput.textfieldstr[1])
					if (changedValues[v.name].gameValue ~= inputLastValue) then
						grInput.requireUpdate = true
						inputLastValue = changedValues[v.name].gameValue
					end
				end)
			grInput:addEnterAction(function()
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
			grValueHolder:addAdaptedText(true, v.value, -4, nil, 4, RIGHTMID, 0.7, 0.7)
			if (grValueHolder.dispstr[1] ~= v.value) then
				TBMenu:displayPopup(grValueHolder:addChild({ interactive = true }), v.value)
			end
		end
	elseif (v.type == GAMERULE_BOOL) then
		grName.size.w = listingHolder.size.w / 3 * 2 - 10
		local grToggle = TBMenu:spawnToggle(grValueHolder, -grValueHolder.size.h, nil, nil, nil, changedValues[v.name] and changedValues[v.name].value or v.value, function(val)
				if (not changedValues[v.name]) then
					changedValues[v.name] = Gamerule.New(v)
				end
				changedValues[v.name]:setValue(val)
				if (v.triggerUpdate) then
					updateFunc()
				end
			end)

		grToggle:addEnterAction(function()
				Gamerules.LastSelectedRule = v.name
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
						changedValues[v.name] = Gamerule.New(v)
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
		---@type SliderSettings
		local sliderSettings = {
			maxValue = v.slider.maxValue or 1,
			minValue = v.slider.minValue or 0,
			maxValueDisp = v.slider.maxValueDisp or v.slider.maxValue,
			minValueDisp = v.slider.minValueDisp or v.slider.minValue,
			isBoolean = v.slider.isBoolean,
			textWidth = 30,
			sliderRadius = 20
		}
		local updateFunc = function(val, _, slider)
			if (not changedValues[v.name]) then
				changedValues[v.name] = Gamerule.New(v)
			end
			if (v.name == "ghostspeed") then
				val = val > 100 and (100 + math.floor((val - 100) / 2.5) * 20) or val
				slider.label.labelText[1] = (math.floor(val) / 100) .. ''
			end
			changedValues[v.name]:setValue(val)
		end

		TBMenu:spawnSlider2(grValueHolder, {}, sliderValue, sliderSettings, updateFunc)
	else
		if (v.name == "gravity") then
			grHolder.size.h = elementHeight - grHolder.shift.y
			grHolder:setRounded({ 3, 0 })
			local grValueHolderNewlineHolder = listingHolder:addChild({
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			table.insert(listElements, grValueHolderNewlineHolder)
			local grValueHolderNewline = grValueHolderNewlineHolder:addChild({
				pos = { grHolder.shift.x, 0 },
				size = { grHolder.size.w, grValueHolderNewlineHolder.size.h - 2 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				shapeType = ROUNDED,
				rounded = { 0, 3 }
			})
			local grValueInputsHolder = grValueHolderNewline:addChild({ rounded = 3 }, true)
			---@type UIElement[]
			local gravInputs = {}
			local counter = 0
			for i, k in pairs(v.value) do
				local grInput = TBMenu:spawnTextField2(grValueInputsHolder, {
					x = 10 + (grValueInputsHolder.size.w / 3 - 5) * counter,
					y = 4,
					w = grValueInputsHolder.size.w / 3 - 10,
					h = grValueInputsHolder.size.h - 6
				}, k.value, k.title, {
					isNumeric = true,
					allowDecimal = true,
					allowNegative = true,
					fontId = 4,
					textScale = 0.7,
					textAlign = CENTERMID,
					darkerMode = true,
					inputType = _G.PLATFORM == "IPHONEOS" and KEYBOARD_INPUT.ASCII or KEYBOARD_INPUT.NUMBERPAD,
					returnKeyType = i == 3 and KEYBOARD_RETURN.DONE or KEYBOARD_RETURN.NEXT
				})
				table.insert(gravInputs, grInput)
				counter = counter + 1
			end
			for j, grInput in ipairs(gravInputs) do
				grInput:addTabAction(scrollTabFunc)
				if (prevInput) then
					prevInput:addTabSwitch(grInput)
					grInput:addTabSwitchPrev(prevInput)
				end
				grInput:addEnterAction(function()
						grInput.keyUpCustom()
						if (is_mobile()) then
							if (j < 3 and grInput.tabswitchaction) then
								grInput.tabswitchaction()
							elseif (j == 3) then
								updateFunc()
							end
						end
					end)
				grInput:addInputCallback(function()
						if (not changedValues[v.name]) then
							changedValues[v.name] = Gamerule.New(v)
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
			grHolder:setRounded({ 3, 0 })

			local num_players = tonumber(changedValues["numplayers"] and changedValues["numplayers"].gameValue or get_gamerule("numplayers")) or 2
			local engageInputs = {}
			local playerNames = { "Tori", "Uke", "Nage", "P4" }
			local num_inputs = num_players * 3

			for i = 1, num_players do
				local grValueHolderNewlineHolder = listingHolder:addChild({
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight },
					bgColor = TB_MENU_DEFAULT_BG_COLOR
				})
				table.insert(listElements, grValueHolderNewlineHolder)
				local grValueHolderNewline = grValueHolderNewlineHolder:addChild({
					pos = { grHolder.shift.x, 0 },
					size = { grHolder.size.w, grValueHolderNewlineHolder.size.h - (i == num_players and 2 or 0) },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					shapeType = i == num_players and ROUNDED or SQUARE,
					rounded = i == num_players and { 0, 3 } or 0
				})
				local grValueTitle = grValueHolderNewline:addChild({
					pos = { 10, 0 },
					size = { grValueHolderNewline.size.w / 5, grValueHolderNewline.size.h }
				})
				grValueTitle:addAdaptedText(true, playerNames[i], nil, nil, nil, LEFTMID, 0.8)
				local grValueInputsHolder = grValueHolderNewline:addChild({
					pos = { grValueTitle.shift.x + grValueTitle.size.w + 5, 0 },
					size = { grValueHolderNewline.size.w - grValueTitle.shift.x - grValueTitle.size.w - 15, grValueHolderNewline.size.h },
					shapeType = ROUNDED,
					rounded = 3
				})
				local counter = 0
				-- v.value[i] might be empty... make sure it isn't
				v.value[i] = v.value[i] or { { title = 'x', value = '' }, { title = 'y', value = '' }, { title = 'z', value = '' } }
				for j, k in pairs(v.value[i]) do
					local grInput = TBMenu:spawnTextField2(grValueInputsHolder, {
						x = (grValueInputsHolder.size.w / 3 + 2.5) * counter,
						y = 4,
						w = grValueInputsHolder.size.w / 3 - 5,
						h = grValueInputsHolder.size.h - (i == num_players and 6 or 8)
					}, k.value, k.title, {
						isNumeric = true,
						allowDecimal = true,
						allowNegative = true,
						fontId = 4,
						textScale = 0.7,
						textAlign = CENTERMID,
						darkerMode = true,
						inputType = _G.PLATFORM == "IPHONEOS" and KEYBOARD_INPUT.ASCII or KEYBOARD_INPUT.NUMBERPAD,
						returnKeyType = (i * j == num_inputs) and KEYBOARD_RETURN.DONE or KEYBOARD_RETURN.NEXT
					})
					table.insert(engageInputs, grInput)
					counter = counter + 1
				end
			end

			for j, grInput in pairs(engageInputs) do
				grInput:addTabAction(scrollTabFunc)
				if (prevInput) then
					prevInput:addTabSwitch(grInput)
					grInput:addTabSwitchPrev(prevInput)
				end
				grInput:addEnterAction(function()
						grInput.keyUpCustom()
						if (is_mobile()) then
							if (j < num_inputs and grInput.tabswitchaction) then
								grInput.tabswitchaction()
							elseif (j == num_inputs) then
								updateFunc()
							end
						end
					end)
				grInput:addInputCallback(function()
						if (not changedValues[v.name]) then
							changedValues[v.name] = Gamerule.New(v)
						end
						local engage = ''
						for _, input in pairs(engageInputs) do
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

---Returns whether the specified gamerule's `gameValue` is the default one
---@param ruleName string
---@param gamerules Gamerule[]
---@param changedValues Gamerule[]
---@return boolean
function Gamerules.findRuleValue(ruleName, gamerules, changedValues)
	if (changedValues[ruleName]) then
		return (changedValues[ruleName].gameValue .. '') ~= changedValues[ruleName].null
	end

	for _, section in pairs(gamerules) do
		for _, rule in pairs(section) do
			if (rule.name == ruleName) then
				return (rule.gameValue .. '') ~= rule.null
			end
		end
	end
	return false
end

---Displays main elements of the Gamerules menu
---@param listingHolder UIElement
---@param toReload UIElement
---@param gameRulesName UIElement
---@param elementHeight number
---@param search? UIElement
---@param gamerules Gamerule[]
---@param changedValues Gamerule[]
function Gamerules.spawnMainList(listingHolder, toReload, gameRulesName, elementHeight, search, gamerules, changedValues)
	local targetListShift = listingHolder.shift.y < 0 and -listingHolder.shift.y or listingHolder.size.h
	targetListShift = targetListShift - listingHolder.size.h

	if (listingHolder.scrollBar) then
		listingHolder.scrollBar:kill()
	end
	listingHolder:kill(true)
	listingHolder:moveTo(nil, 0)

	local searchStr = search and search.textfieldstr[1] or ''
	gameRulesName:addAdaptedText(true, TB_MENU_LOCALIZED.MAINMENUGAMERULESNAME .. ((search and searchStr ~= "") and (": \"" .. searchStr:sub(0, 16) .. (searchStr:len() > 16 and "..." or '') .. "\"") or ""), nil, nil, FONTS.BIG, nil, 0.6)

	searchStr = string.escape(searchStr)
	local thisFunc = function()
		Gamerules.spawnMainList(listingHolder, toReload, gameRulesName, elementHeight, search, gamerules, changedValues)
	end

	local listElements = {}
	local lastInput = nil
	local switchTarget, switchNext = false, false
	for x,section in pairs(gamerules) do
		for i,v in pairs(section) do
			if (Gamerules.LastSelectedRule == v.name or switchNext) then
				if (lastInput) then
					switchTarget = lastInput
				else
					switchNext = true
				end
				Gamerules.LastSelectedRule = nil
			end
			if (not v.hidden) then
				if (searchStr:len() > 0) then
					if (v.name:find(searchStr) or v.title:find(searchStr)) then
						lastInput = Gamerules.showGamerule(v, listingHolder, elementHeight, listElements, x, i, changedValues, thisFunc, lastInput)
					end
				else
					if (#v.depends == 0) then
						lastInput = Gamerules.showGamerule(v, listingHolder, elementHeight, listElements, x, i, changedValues, thisFunc, lastInput)
					else
						local dependsCount = v.dependsAll and #v.depends or 1
						for _, rule in pairs(v.depends) do
							if (Gamerules.findRuleValue(rule, gamerules, changedValues)) then
								dependsCount = dependsCount - 1
								if (dependsCount == 0) then
									lastInput = Gamerules.showGamerule(v, listingHolder, elementHeight, listElements, x, i, changedValues, thisFunc, lastInput)
									break
								end
							end
						end
					end
				end
			end
			if (switchTarget) then
				if (switchNext) then
					if (lastInput) then
						lastInput.tabswitchprevaction()
					end
				else
					switchTarget.tabswitchaction()
				end
			end
		end
	end
	Gamerules.LastSelectedRule = nil

	for _, v in pairs(listElements) do
		v:hide()
	end

	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar

	-- Set shift for collapsible sections
	Gamerules.ListShift[2] = #listElements * elementHeight
	targetListShift = targetListShift > Gamerules.ListShift[2] - listingHolder.size.h and Gamerules.ListShift[2] - listingHolder.size.h or targetListShift
	Gamerules.ListShift[3] = scrollBar.parent.size.h - scrollBar.size.h
	Gamerules.ListShift[1] = targetListShift / (Gamerules.ListShift[2] - listingHolder.size.h) * Gamerules.ListShift[3]

	scrollBar:makeScrollBar(listingHolder, listElements, toReload, Gamerules.ListShift)
end

---Prepares the base for gamerules menu
function Gamerules.showMain()
	usage_event("gamerules")
	local gamerules = Gamerules.getRules()

	local mainViewBackground = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { Gamerules.DisplayPos.x, Gamerules.DisplayPos.y },
		size = { math.min(WIN_W / 2, 400), math.clamp(650, WIN_H / 2, WIN_H - 100) },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	Gamerules.MainElement = mainViewBackground
	Gamerules.DisplayPos = mainViewBackground.pos

	local mainView = mainViewBackground:addChild({
		shift = { 2, 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	}, true)

	local elementHeight = 38
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(mainView, 80, 75, 20, mainView.bgColor)

	topBar.shapeType = mainView.shapeType
	topBar:setRounded(mainView.rounded)
	botBar.shapeType = mainView.shapeType
	botBar:setRounded(mainView.rounded)

	local mainMoverHolder = topBar:addChild({
		size = { topBar.size.w, 30 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	}, true)
	local mainMover = mainMoverHolder:addChild({
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
				disable_mouse_camera_movement()
				mainMover.pressedPos.x = x - mainMover.pos.x
				mainMover.pressedPos.y = y - mainMover.pos.y
			end, enable_mouse_camera_movement, function(x, y)
			if (mainMover.hoverState == BTN_DN) then
				local x = x - mainMover.pressedPos.x
				local y = y - mainMover.pressedPos.y
					x = x < 0 and 0 or (x + Gamerules.MainElement.size.w > WIN_W and WIN_W - Gamerules.MainElement.size.w or x)
				y = y < 0 and 0 or (y + Gamerules.MainElement.size.h > WIN_H and WIN_H - Gamerules.MainElement.size.h or y)
				Gamerules.MainElement:moveTo(x, y)
			end
		end, nil, enable_mouse_camera_movement)

	local gameRulesName = topBar:addChild({
		pos = { 10, mainMoverHolder.size.h + mainMoverHolder.shift.y },
		size = { topBar.size.w - 20, topBar.size.h - mainMoverHolder.size.h - mainMoverHolder.shift.y * 2 }
	})

	local changedValues = {}
	local searchHolder = botBar:addChild({
		shapeType = ROUNDED,
		rounded = 3
	})
	local search = TBMenu:spawnTextField2(searchHolder, { x = 5, y = 5, w = searchHolder.size.w - 10, h = searchHolder.size.h - 45 }, nil, TB_MENU_LOCALIZED.SEARCHNOTE, {
		fontId = FONTS.LMEDIUM,
		textScale = 0.65,
		returnKeyType = KEYBOARD_RETURN.DONE
	})
	local lastSearch = search.textfieldstr[1]
	search:addInputCallback(function()
			if (lastSearch ~= search.textfieldstr[1]) then
				lastSearch = search.textfieldstr[1]
				Gamerules.ListShift[1] = 0
				Gamerules.spawnMainList(listingHolder, toReload, gameRulesName, elementHeight, search, gamerules, changedValues)
				search.btnDown()
			end
		end)
	if (is_mobile()) then
		search:addEnterAction(function()
				search.keyboard = false
				search:disableMenuKeyboard()
			end)
	end
	Gamerules.spawnMainList(listingHolder, toReload, gameRulesName, elementHeight, nil, gamerules, changedValues)

	local grNewGameToggleView = botBar:addChild({
		pos = { 0, -35 },
		size = { botBar.size.w / 2, 30 }
	}, true)
	TBMenu:spawnToggle(grNewGameToggleView, 5, 2, grNewGameToggleView.size.h - 4, grNewGameToggleView.size.h - 4, Gamerules.StartNewgame, function(val) Gamerules.StartNewgame = val set_option("grnewgame", val) save_custom_config() end)
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
	grNewGameButton:addAdaptedText(false, TB_MENU_LOCALIZED.WORDAPPLY)
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
			if (Gamerules.StartNewgame) then
				Gamerules.MainElement:kill()
				Gamerules.MainElement = nil
				if (get_world_state().game_type == 1) then
					local delayedResetter = UIElement:new({
						globalid = TB_MENU_HUB_GLOBALID,
						pos = { 0, 0 },
						size = { 0, 0 }
					})
					delayedResetter.spawnTime = UIElement.clock
					delayedResetter:addCustomDisplay(true, function()
							if (delayedResetter.spawnTime + 0.5 <= UIElement.clock) then
								delayedResetter:kill()
								runCmd("reset")
							end
						end)
				else
					start_new_game()
				end
			end
		end)

	local quitButton = mainMoverHolder:addChild({
		pos = { -mainMoverHolder.size.h, 0 },
		size = { mainMoverHolder.size.h, mainMoverHolder.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	quitButton:addChild({
		shift = { 2, 2 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})
	quitButton:addMouseHandlers(nil, function()
			Gamerules.MainElement:kill()
			Gamerules.MainElement = nil
		end)
end
