-- Atmospheres 2.0 manager
-- Do not modify this file
require("system.atmospheres_defines")

---@class ShaderOption
---@field id integer
---@field name string Option name
---@field value number|number[] Option value

if (Atmospheres == nil) then
	local x, y = get_window_safe_size()

	---@class Atmospheres
	---@field MainElement UIElement
	---@field StoredOptions ShaderOption[] Initial values of the options that were modified by the current shader
	---@field CurrentShader ShaderOption[] Current shader values
	---@field DisplayPos Vector2 Window display offset
	---@field ListShift number[] Scroll bar state
	---@field DefaultShader string Default shader name
	---@field SelectedScreen integer Selected screen id
	---@field DebugHolder2D UIElement UIElement holder for debug info
	Atmospheres = {
		MainElement = nil,
		EntityHolder = nil,
		StoredOptions = {},
		CurrentShader = {},
		DisplayPos = { x = x + 10, y = y + 10 },
		ListShift = { 0 },
		DefaultShader = nil,
		SelectedScreen = 1,
		DebugHolder2D = nil,
		ver = 5.60
	}
	Atmospheres.__index = Atmospheres
	setmetatable({}, Atmospheres)
end

---Reverts all shader options to their initial state, destroys all atmo objects and unloads the draw3d hook
function Atmospheres.unload()
	for _,v in pairs(Atmospheres.StoredOptions) do
		set_option(v.name, v.value)
	end
	Atmospheres.StoredOptions = {}
	_ATMO = nil
	if (Atmospheres.EntityHolder ~= nil) then
		Atmospheres.EntityHolder:kill()
		Atmospheres.EntityHolder = nil
	end
	if (Atmospheres.DefaultShader) then
		runCmd("lws " .. Atmospheres.DefaultShader:gsub("^data/shader/", ""))
	end
	if (Atmospheres.DebugHolder2D ~= nil) then
		Atmospheres.DebugHolder2D:kill()
		Atmospheres.DebugHolder2D = nil
	end
	remove_hook("draw3d", "atmospheres")
end

---@class AtmosphereEntity3D : UIElement3DOptions
---@field name string Object name
---@field parent string Parent object name
---@field count integer Object spawn count
---@field rpos number[] Object spawn position randomizer values
---@field rsize number[] Object spawn size randomizer values
---@field rcolor Color Object color randomizer values
---@field color Color Object color

---@class Atmosphere
---@field shader string Custom shader name
---@field entities AtmosphereEntity3D[] List of all settings to generate Atmosphere objects
---@field shaderopts ShaderOption[] List of all custom shader options that this Atmosphere will modify
---@field opts table List of all game options that this Atmosphere will modify

---Parses atmo data into an Atmosphere object
---@param filename string
---@return Atmosphere|nil
function Atmospheres.parseFile(filename)
	local file = Files:open(filename, 'r')
	if (file.data == nil) then
		return nil
	end

	---@type Atmosphere
	local atmosphere = { entities = {}, shaderopts = {}, opts = {} }
	for _, ln in pairs(file:readAll()) do
		local ln = ln:gsub("^%s*", ""):gsub("[\r\n]", "")
		if (ln:find("^shader ")) then
			local shader = ln:gsub("^shader ", "")
			if (not shader:find("%.inc.?$")) then
				shader = shader .. ".inc"
			end
			atmosphere.shader = shader
		elseif (ln:find("^shaderopt ")) then
			local data = { ln:gsub("^shaderopt ", ""):match(("([^ ]+) *"):rep(5)) }
			data[1] = tonumber(data[1]) and tonumber(data[1]) or SHADER_OPTIONS[data[1]:upper()]
			for i = 2, 5 do
				data[i] = tonumber(data[i])
			end
			atmosphere.shaderopts[data[1]] = { data[2], data[3], data[4], data[5] }
		elseif (ln:find("^opt ")) then
			local data = { ln:gsub("^opt ", ""):match(("([^ ]+) *"):rep(2)) }
			table.insert(atmosphere.opts, { name = data[1], value = tonumber(data[2]) })
		elseif (ln:find("^env_obj ")) then
			local entityid = ln:gsub("^env_obj ", "")
			atmosphere.entities[#atmosphere.entities + 1] = {
				name = entityid,
				pos = { 0, 0, 0 },
				rot = { 0, 0, 0 },
				size = { 1, 1, 1 },
				color = { 1, 1, 1, 1 },
				shape = CUBE
			}
		elseif (#atmosphere.entities > 0) then
			local data, dataName = {}, ""
			if (ln:find("^parent ")) then
				atmosphere.entities[#atmosphere.entities].parent = ln:gsub("^parent ", "")
			elseif (ln:find("^shape ")) then
				local shape = ln:gsub("^shape ", "")
				local targetShape = CUBE
				local model = nil
				if (shape:find("^box") or shape:find("^cube")) then
					targetShape = CUBE
				elseif (shape:find("^cylinder") or shape:find("^capsule")) then
					targetShape = CAPSULE
				elseif (shape:find("^sphere")) then
					targetShape = SPHERE
				elseif (shape:find("^custom")) then
					model = shape:gsub("^custom ", "")
					targetShape = CUSTOMOBJ
				end
				atmosphere.entities[#atmosphere.entities].shape = targetShape
				atmosphere.entities[#atmosphere.entities].model = model
			elseif (ln:find("^size ") or ln:find("^sides ")) then
				data = { ln:gsub("^si[zd]e[s]? ", ""):match(("([^ ]+) *"):rep(3)) }
				dataName = "size"
			elseif (ln:find("^randomsize ")) then
				data = { ln:gsub("^randomsize ", ""):match(("([^ ]+) *"):rep(3)) }
				dataName = "rsize"
			elseif (ln:find("^pos ")) then
				data = { ln:gsub("^pos ", ""):match(("([^ ]+) *"):rep(3)) }
				dataName = "pos"
			elseif (ln:find("^randompos ")) then
				data = { ln:gsub("^randompos ", ""):match(("([^ ]+) *"):rep(3)) }
				dataName = "rpos"
			elseif (ln:find("^rot ")) then
				data = { ln:gsub("^rot ", ""):match(("([^ ]+) *"):rep(3)) }
				dataName = "rot"
			elseif (ln:find("^rotate ")) then
				data = { ln:gsub("^rotate ", ""):match(("([^ ]+) *"):rep(3)) }
				dataName = "rotation"
				atmosphere.entities[#atmosphere.entities].animated = true
			elseif (ln:find("^move ")) then
				data = { ln:gsub("^move ", ""):match(("([^ ]+) *"):rep(3)) }
				dataName = "movement"
				atmosphere.entities[#atmosphere.entities].animated = true
			elseif (ln:find("^colo[u]?r ")) then
				data = { ln:gsub("^colo[u]?r ", ""):match(("([^ ]+) *"):rep(4)) }
				if (tonumber(data[1]) > 2 or tonumber(data[2]) > 2 or tonumber(data[3]) > 2) then
					for i = 1, 3 do
						data[i] = data[i] / 256
					end
				end
				dataName = "color"
			elseif (ln:find("^randomcolo[u]?r ")) then
				data = { ln:gsub("^randomcolo[u]?r ", ""):match(("([^ ]+) *"):rep(4)) }
				if (tonumber(data[1]) > 2 or tonumber(data[2]) > 2 or tonumber(data[3]) > 2) then
					for i = 1, 3 do
						data[i] = data[i] / 256
					end
				end
				dataName = "rcolor"
			elseif (ln:find("^count ")) then
				local count = ln:gsub("^count ", "")
				atmosphere.entities[#atmosphere.entities].count = tonumber(count) or 1
			end
			if (#data > 0) then
				if (not atmosphere.entities[#atmosphere.entities][dataName]) then
					atmosphere.entities[#atmosphere.entities][dataName] = {}
				end
				for i,v in pairs(data) do
					if (tonumber(v)) then
						atmosphere.entities[#atmosphere.entities][dataName][i] = v + 0
					elseif (dataName == "rotation" or dataName == "movement") then
						atmosphere.entities[#atmosphere.entities][dataName][i] = v
					end
				end
			end
		end
	end

	file:close()
	return atmosphere
end

---Gets the default world shader from user config
function Atmospheres.getDefaultWorldShader()
	local file = Files:open("../custom.cfg")
	if (file.data) then
		for _, ln in pairs(file:readAll()) do
			if (ln:find("^customworldshader ")) then
				Atmospheres.DefaultShader = ln:gsub("customworldshader ", ""):gsub("\"", "")
				if (Atmospheres.DefaultShader:len() < 5) then
					Atmospheres.DefaultShader = "default.inc"
				end
				break
			end
		end
	end
	file:close()
end

---Helper function to spawn a toggle used in Shader Maker. \
---No longer used, we use the generic TBMenu:spawnSlider2() implementation instead
---@deprecated
function Atmospheres.spawnToggle(viewElement, x, y, w, h, toggleTable, i)
	local maxVal = toggleTable.maxValue or 1
	local minVal = toggleTable.minValue or 0
	local name = toggleTable.names[i] or ""
	local toggleView = viewElement:addChild({
		pos = { x, y },
		size = { w, h }
	})
	local minText = toggleView:addChild({
		pos = { 0, 0 },
		size = { 30, 15 }
	})
	minText:addAdaptedText(false, minVal .. "", nil, nil, 4, LEFTMID, 0.5)
	local maxText = toggleView:addChild({
		pos = { -30, 0 },
		size = { 30, 15 }
	})
	maxText:addAdaptedText(false, maxVal .. "", nil, nil, 4, RIGHTMID, 0.5)
	local nameText = toggleView:addChild({
		pos = { toggleView.size.w / 3, 0 },
		size = { toggleView.size.w / 3, 15 }
	})
	nameText:addAdaptedText(false, name, nil, nil, 4, nil, 0.7)
	local toggleBG = toggleView:addChild({
		pos = { 0, 30 },
		size = { toggleView.size.w, toggleView.size.h - 40 },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true
	})
	local togglePos = 0
	if (toggleTable and i) then
		toggleTable[i] = tonumber(toggleTable[i]) > maxVal and 1 or tonumber(toggleTable[i]) / maxVal
		togglePos = toggleTable[i] * (toggleBG.size.w - 10)
	end
	local toggle = toggleBG:addChild({
		pos = { togglePos, -toggleBG.size.h - toggleBG.shift.y + 15 },
		size = { 10, toggleView.size.h - 20 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
	})
	toggle:addMouseHandlers(function()
			toggle.pressed = true
			toggle.pressedPos = toggle:getLocalPos()
		end, function()
			toggle.pressed = false
			runCmd("worldshader " .. toggleTable.id .. " " .. toggleTable[1] .. " " .. toggleTable[2] .. " " .. toggleTable[3] .. " " .. toggleTable[4])
		end, function()
			if (toggle.pressed) then
				local xPos = MOUSE_X - toggleView.pos.x - toggle.pressedPos.x
				if (xPos < 0) then
					xPos = 0
				elseif (xPos > toggleView.size.w - toggle.size.w) then
					xPos = toggleView.size.w - toggle.size.w
				end
				if (toggleTable.boolean) then
					if (xPos + toggle.size.w / 2 > toggleView.size.w / 2) then
						xPos = toggleView.size.w - toggle.size.w
					else
						xPos = 0
					end
				end
				toggle:moveTo(xPos, nil)
				toggleTable[i] = xPos / (toggleView.size.w - 10) * (maxVal - minVal) + minVal
			end
		end)
	toggleBG:addMouseHandlers(function()
		local pos = toggleBG:getLocalPos()
		local xPos = pos.x - toggle.size.w / 2
		if (xPos < 0) then
			xPos = 0
		elseif (xPos > toggleView.size.w - toggle.size.w) then
			xPos = toggleView.size.w - toggle.size.w
		end
		if (toggleTable.boolean) then
			if (xPos + toggle.size.w / 2 > toggleView.size.w / 2) then
				xPos = toggleView.size.w - toggle.size.w
			else
				xPos = 0
			end
		end
		toggle:moveTo(xPos)
		toggleTable[i] = xPos / (toggleView.size.w - 10) * (maxVal - minVal) + minVal
		runCmd("worldshader " .. toggleTable.id .. " " .. toggleTable[1] .. " " .. toggleTable[2] .. " " .. toggleTable[3] .. " " .. toggleTable[4])
	end)
	return toggle
end

---Displays main controls for Shader Editor
function Atmospheres.showShaderControls()
	if (not SHADER_OPTIONS.FLOOR_COLOR) then
		return
	end
	local options = { { name = "hint", value = 0 }, { name = "feedback", value = 0 } }
	for _, v in pairs(options) do
		local found = false
		for _, k in pairs(Atmospheres.StoredOptions) do
			if (k.name == v.name) then
				found = true
			end
		end
		if (not found) then
			table.insert(Atmospheres.StoredOptions, { name = v.name, value = get_option(v.name) })
		end
		set_option(v.name, v.value)
	end

	local x, y, w, h = get_window_safe_size()
	local viewElementHolder = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { 0, y + h - 90 },
		size = { WIN_W, 90 },
		bgColor = { 1, 1, 1, 0.35 }
	})
	local viewElement = viewElementHolder:addChild({
		shift = { WIN_W / 10, 15 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local toggleView = viewElement:addChild({
		shift = { viewElement.size.w / 4, 5 },
	})
	local currentControl = {}
	local shaderList = {}
	local updateOnDraw = {}

	viewElement:addCustomDisplay(false, function()
			local drawn = false
			for _, func in pairs(updateOnDraw) do
				func()
				drawn = true
			end
			if (drawn) then
				updateOnDraw = {}
			end
		end)

	local function spawnToggles()
		for i = 1, currentControl.count do
			TBMenu:spawnSlider2(toggleView, {
				x = (i - 1) * toggleView.size.w / currentControl.count + 5,
				y = 0,
				w = toggleView.size.w / currentControl.count - 10,
				h = toggleView.size.h
			}, tonumber(currentControl[i]), {
				maxValue = currentControl.maxValue,
				minValue = currentControl.minValue,
				isBoolean = currentControl.boolean,
				displayName = currentControl.names[i],
				decimal = 2,
				darkerMode = true
			}, function(value)
				currentControl[i] = value
				updateOnDraw[i] = function() runCmd("worldshader " ..  currentControl.id .. " " .. currentControl[1] .. " " .. currentControl[2] .. " " .. currentControl[3] .. " " .. currentControl[4]) end
			end)
		end
	end

	for i,v in pairs(SHADER_OPTIONS) do
		if (v < 16) then
			local dropAction = function()
				currentControl = Atmospheres.CurrentShader[i]
				toggleView:kill(true)
				spawnToggles()
			end
			table.insert(shaderList, { text = i:gsub("_", " "), action = dropAction })
		end
	end
	currentControl = Atmospheres.CurrentShader.BACKGROUND_COLOR
	spawnToggles()

	local dropdownView = UIElement:new({
		parent = viewElement,
		pos = { 10, 10 },
		size = { viewElement.size.w / 4 - 20, viewElement.size.h - 20 },
		shapeType = ROUNDED,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		rounded = 5
	})
	TBMenu:spawnDropdown(dropdownView, shaderList, 25, WIN_H - 100, nil, { scale = 0.7 }, { scale = 0.6 })

	local closeButton = UIElement:new({
		parent = viewElement,
		pos = { -viewElement.size.h + 10, 10 },
		size = { viewElement.size.h - 20, viewElement.size.h - 20 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 5
	})
	local closeIcon = UIElement:new({
		parent = closeButton,
		pos = { 10, 10 },
		size = { closeButton.size.w - 20, closeButton.size.h - 20 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})
	closeButton:addMouseHandlers(nil, function()
			viewElementHolder:kill()
			for i,v in pairs(options) do
				for j,k in pairs(Atmospheres.StoredOptions) do
					if (v.name == k.name) then
						set_option(k.name, k.value)
						break
					end
				end
			end
		end)
	local saveButton = UIElement:new({
		parent = viewElement,
		pos = { viewElement.size.w / 4 * 3 + 10, 10 },
		size = { viewElement.size.w / 4 - 65, viewElement.size.h - 20 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 5
	})
	saveButton:addAdaptedText(false, TB_MENU_LOCALIZED.SHADERSSAVESHADER)
	saveButton:addMouseHandlers(nil, function()
			TBMenu:showConfirmationWindowInput(TB_MENU_LOCALIZED.SHADERSSAVING, TB_MENU_LOCALIZED.SHADERSINPUTNAME, function(name)
				local name = name:gsub("%.inc.?$", "")
				local function save()
					local file = Files:open("../data/shader/" .. name .. ".inc", FILES_MODE_WRITE)
					if (file.data) then
						for i,v in pairs(Atmospheres.CurrentShader) do
							local line = i:lower() .. " " .. v[1] .. " " .. v[2] .. " " .. v[3] .. " " .. v[4]
							file:writeLine(line)
						end
						file:close()
					else
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORCREATINGFILE, true)
					end
				end
				local file = Files:open("../data/shader/" .. name .. ".inc")
				if (file.data) then
					file:close()
					TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.SHADERSERRORFILEEXISTS, save)
				else
					save()
				end
			end)
		end)
end

function Atmospheres.setShaderInfo()
	Atmospheres.CurrentShader = {}
	Atmospheres.getShaderOpts()
end

function Atmospheres.getShaderOptName(id)
	for i,v in pairs(SHADER_OPTIONS) do
		if (id == v) then
			return i
		end
	end
end

function Atmospheres.getShaderOpts(id)
	local id = id or 0
	add_hook("console", "atmospheresSystem", function(ln)
			if (ln:find("worldshader")) then
				remove_hooks("atmospheresSystem")
				if (id < 33) then
					Atmospheres.getShaderOpts(id + 1)
				end
				return 1
			elseif (ln:match("[^ ]+ [^ ]+ [^ ]+ [^ ]+ *")) then
				local data = { ln:match(("([^ ]+) *"):rep(4)) }
				for i = 1, 4 do
					data[i] = tonumber(data[i]) .. ""
				end
				data.id = id
				Atmospheres.getShaderOptionData(data)
				Atmospheres.CurrentShader[Atmospheres.getShaderOptName(id)] = data
				return 1
			end
		end)
	runCmd("worldshader " .. id, false, true)
end

---Populates shader options table with additional data
---@param opt ShaderOption
function Atmospheres.getShaderOptionData(opt)
	if (opt.id == 2) then
		opt.count = 4
		opt.names = { "R", "G", "B", "A" }
	elseif (opt.id == 5) then
		opt.count = 1
		opt.names = { "Distance" }
		opt.minValue = -50
		opt.maxValue = 50
	elseif (opt.id == 6 or opt.id == 7) then
		opt.count = 1
		opt.names = { "Enable" }
		opt.boolean = true
	elseif (opt.id == 9 or opt.id == 8) then
		opt.count = 3
		opt.names = { "X", "Y", "Z" }
	elseif (opt.id == 15) then
		opt.count = 1
		opt.names = { "Power" }
	else
		opt.count = 3
		opt.names = { "R", "G", "B" }
	end
end

function Atmospheres.setDefaultAtmo(filename)
	local config = Files:open("../data/atmospheres/atmo.cfg", FILES_MODE_WRITE)
	config:writeLine(filename)
	config:close()
end

function Atmospheres.loadDefaultAtmo()
	local config = Files:open("../data/atmospheres/atmo.cfg")
	if (not config.data) then
		return
	end
	local configData = config:readAll()
	if (configData ~= nil and configData[1] ~= nil) then
		Atmospheres.loadAtmo(configData[1])
	end
	config:close()
end

function Atmospheres.loadAtmo(filename)
	Atmospheres.unload()
	if (filename:lower() == "default.atmo") then
		return
	end

	Atmospheres.getDefaultWorldShader()
	add_hook("draw3d", "atmospheres", function() UIElement3D:drawVisuals(TB_ATMOSPHERES_GLOBALID) end)
	_ATMO = {}
	Atmospheres.EntityHolder = UIElement3D:new({
		globalid = TB_ATMOSPHERES_GLOBALID,
		pos = { 0, 0, 0 },
		size = { 0, 0, 0 }
	})
	Atmospheres.EntityHolder:addOnEnterFrame(function()
			ATMOSPHERES_ANIMATED = true
		end)
	Atmospheres.EntityHolder:addCustomDisplay(true, function()
			ATMOSPHERES_ANIMATED = false
		end, true)
	--[[Atmospheres.EntityHolder:addCustomDisplay(true, function()
		local ws = get_world_state()
		ATMOSPHERES_ANIMATED =	(ws.game_paused == 0 and is_game_frozen() == 1 and ws.replay_mode == 1) or
								(ws.game_paused == 0 and is_game_frozen() == 0 and ws.replay_mode == 0) or
								(ws.replay_mode == 2 and ws.game_paused == 0)
	end)]]

	local atmoData = Atmospheres.parseFile("../data/atmospheres/" .. filename)
	if (atmoData == nil) then
		return
	end

	local entityList = {}
	for _, entity in pairs(atmoData.entities) do
		if (entity.count) then
			for i = 1, entity.count do
				local entityRandom = table.clone(entity)
				entityRandom.name = entity.name .. i
				if (entity.rpos) then
					entityRandom.pos = {
						entity.pos[1] + math.random(-entity.rpos[1] * 100, entity.rpos[1] * 100) / 100,
						entity.pos[2] + math.random(-entity.rpos[2] * 100, entity.rpos[2] * 100) / 100,
						entity.pos[3] + math.random(-entity.rpos[3] * 100, entity.rpos[3] * 100) / 100
					}
				end
				if (entity.rsize) then
					entityRandom.size = {
						entity.size[1] + math.random(-entity.rsize[1] * 100, entity.rsize[1] * 100) / 100,
						entity.size[2] + math.random(-entity.rsize[2] * 100, entity.rsize[2] * 100) / 100,
						entity.size[3] + math.random(-entity.rsize[3] * 100, entity.rsize[3] * 100) / 100
					}
				end
				if (entity.rcolor) then
					entityRandom.color = {
						entity.color[1] + math.random(-entity.rcolor[1] * 100, entity.rcolor[1] * 100) / 100,
						entity.color[2] + math.random(-entity.rcolor[2] * 100, entity.rcolor[2] * 100) / 100,
						entity.color[3] + math.random(-entity.rcolor[3] * 100, entity.rcolor[3] * 100) / 100,
						entity.color[4] + math.random(-entity.rcolor[4] * 100, entity.rcolor[4] * 100) / 100
					}
				end
				Atmospheres.spawnObject(Atmospheres.EntityHolder, entityList, entityRandom)
			end
		else
			Atmospheres.spawnObject(Atmospheres.EntityHolder, entityList, entity)
		end
	end

	if (atmoData.shader) then
		runCmd("lws " .. atmoData.shader)
	end
	for i,v in pairs(atmoData.shaderopts) do
		runCmd("worldshader " .. i .. " " .. v[1] .. " " .. v[2] .. " " .. v[3] .. " " .. v[4])
	end
	Atmospheres.setShaderInfo()
	for i,v in pairs(atmoData.opts) do
		local found = false
		for j,k in pairs(Atmospheres.StoredOptions) do
			if (k.name == v.name) then
				found = true
			end
		end
		if (not found) then
			table.insert(Atmospheres.StoredOptions, { name = v.name, value = get_option(v.name) })
		end
		set_option(v.name, v.value)
	end
end

function Atmospheres.spawnObject(entityHolder, entityList, entity)
	local item = UIElement3D:new({
		parent = entity.parent and entityList[entity.parent] or entityHolder,
		pos = { unpack(entity.pos) },
		rot = { unpack(entity.rot) },
		size = { unpack(entity.size) },
		bgColor = { unpack(entity.color) },
		shapeType = entity.shape,
		objModel = entity.model
	})
	entityList[entity.name] = item
	if (TB_MENU_DEBUG) then
		Atmospheres.DebugHolder2D = Atmospheres.DebugHolder2D or UIElement:new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		Atmospheres.DebugHolder2D:addCustomDisplay(true, function() end)
		local itemText = Atmospheres.DebugHolder2D:addChild({
			size = { 60, 20 }
		})
		itemText:addAdaptedText(true, entity.name)
		item:addCustomDisplay(false, function()
				local x, y = get_screen_pos(item.pos.x, item.pos.y, item.pos.z)
				itemText:moveTo(x, y)
			end)
	end
	if (entity.animated) then
		local rotate, move = function() end, function() end
		if (entity.rotation) then
			local r = {}
			for i,v in pairs(entity.rotation) do
				r[i] = Atmospheres.getFunction(i, v, entity, item, "rot")
			end
			rotate = function()
					item:rotate(r[1](), r[2](), r[3]())
				end
		end
		if (entity.movement) then
			local m = {}
			for i,v in pairs(entity.movement) do
				m[i] = Atmospheres.getFunction(i, v, entity, item, "pos")
			end
			move = function()
					item:moveTo(m[1](), m[2](), m[3]())
				end
		end
		item:addCustomDisplay(false, function()
				if (ATMOSPHERES_ANIMATED) then
					move()
					rotate()
				end
			end)
	end
end

function Atmospheres.getFunction(i, v, entity, obj, ftype)
	local r
	if (type(v) == "number") then
		if (ftype == "pos" and v == 0) then
			r = function()
				return nil
			end
		else
			r = function()
				return v
			end
		end
	else
		local val = entity[ftype][i]
		if (v:find("lock%b();")) then
			val = val + (v:gsub("^lock%(", ""):gsub("%);.*", "") + 0)
			v = v:gsub("lock%b();[_]?", "")
		end
		v = v:gsub("_", " "):gsub("X", "_ATMO['" .. entity.name .. i .. ftype .. "']"):gsub("entity", "_ATMO['" .. entity.name .. "info']")
		v = v:gsub("%Aos%.", ""):gsub("%Aio%.", ""):gsub("%Atable%.", ""):gsub("_G", "")
		_ATMO[entity.name .. i .. ftype] = val
		_ATMO[entity.name .. "info"] = { pos = obj.pos, size = obj.size }
		r = function()
			local f, err = loadstring(v)
			if (f ~= nil and not err) then
				return f()
			end
			return 0
		end
	end
	return r
end

function Atmospheres.spawnMainList(listingHolder, toReload, elementHeight, path, ext, func, searchField)
	if (listingHolder.scrollBar) then
		listingHolder.scrollBar:kill()
	end
	listingHolder:kill(true)
	listingHolder:moveTo(nil, 0)

	local search = searchField and searchField.textfieldstr[1] or ""
	local listElements = {}
	local atmos = get_files(path, ext)

	local defaultHolder = listingHolder:addChild({
		pos = { 0, #listElements * elementHeight },
		size = { listingHolder.size.w, elementHeight }
	})
	table.insert(listElements, defaultHolder)
	local default = defaultHolder:addChild({
		pos = { 5, 2 },
		size = { defaultHolder.size.w - 5, defaultHolder.size.h - 4 },
		interactive = true,
		clickThrough = true,
		hoverThrough = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 3
	})
	default:addChild({
		pos = { 5, 2 },
		size = { elementHeight - 5, elementHeight - 5 },
		bgImage = "../textures/menu/general/back.tga"
	})
	local defaultText = default:addChild({
		pos = { elementHeight, 0 },
		size = { default.size.w - elementHeight, elementHeight }
	})
	if (search == "") then
		defaultText:addAdaptedText(false, TB_MENU_LOCALIZED.SHADERSRESETTODEFAULT, 10, nil, 4, LEFTMID, 0.8)
		default:addMouseHandlers(nil, function()
				func("default." .. ext)
			end)
	else
		defaultText:addAdaptedText(false, TB_MENU_LOCALIZED.NAVBUTTONBACK, 10, nil, 4, LEFTMID, 0.8)
		default:addMouseHandlers(nil, function()
				searchField:clearTextfield()
				Atmospheres.spawnMainList(listingHolder, toReload, elementHeight, path, ext, func, searchField)
			end)
	end

	for _, file in pairs(atmos) do
		local fileLower = utf8.lower(file)
		if (utf8.find(fileLower, search) and not (utf8.match(fileLower, "default")) and not (utf8.match(fileLower, "atmo.cfg"))) then
			local buttonHolder = listingHolder:addChild({
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, buttonHolder)
			local button = buttonHolder:addChild({
				pos = { 5, 2 },
				size = { buttonHolder.size.w - 5, buttonHolder.size.h - 4 },
				interactive = true,
				clickThrough = true,
				hoverThrough = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 3
			})
			button:addAdaptedText(false, file:gsub("%." .. ext .. "$", ""), 10, nil, 4, LEFTMID, 0.8, 0.8)
			button:addMouseHandlers(nil, function()
					func(file)
				end)
		end
	end
	if (#listElements == 0) then
		local element = listingHolder:addChild({})
		table.insert(listElements, element)
		element:addAdaptedText(false, TB_MENU_LOCALIZED.NOFILESFOUND .. " :(")
	end
	for _, v in pairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar
	scrollBar:makeScrollBar(listingHolder, listElements, toReload, Atmospheres.ListShift)
end

function Atmospheres.showMain()
	Atmospheres.setShaderInfo()
	if (Atmospheres.MainElement ~= nil) then
		Atmospheres.MainElement:kill()
	end
	Atmospheres.MainElement = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { Atmospheres.DisplayPos.x, Atmospheres.DisplayPos.y },
		size = { WIN_W / 4, WIN_H / 4 * 3 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	Atmospheres.DisplayPos = Atmospheres.MainElement.pos

	local mainList = Atmospheres.MainElement:addChild({}, true)
	local elementHeight = 36
	local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(mainList, 75, 80, 20, Atmospheres.MainElement.bgColor)

	topBar.shapeType = mainList.shapeType
	topBar:setRounded(mainList.rounded)
	botBar.shapeType = mainList.shapeType
	botBar:setRounded(mainList.rounded)

	local search = TBMenu:spawnTextField2(botBar, {
		x = 5,
		y = 5,
		w = botBar.size.w - 10,
		h = botBar.size.h - 50
	}, nil, TB_MENU_LOCALIZED.SEARCHNOTE, {
		fontId = 4,
		textScale = 0.65,
		textAlign = LEFTMID,
		keepFocusOnHide = true,
		darkerMode = true
	})

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
		end, function ()
			enable_mouse_camera_movement()
		end, function(x, y)
			if (mainMover.hoverState == BTN_DN) then
				local x = x - mainMover.pressedPos.x
				local y = y - mainMover.pressedPos.y
				x = x < 0 and 0 or (x + Atmospheres.MainElement.size.w > WIN_W and WIN_W - Atmospheres.MainElement.size.w or x)
				y = y < 0 and 0 or (y + Atmospheres.MainElement.size.h > WIN_H and WIN_H - Atmospheres.MainElement.size.h or y)
				Atmospheres.MainElement:moveTo(x, y)
			end
		end)

	local shaderEditorButton = botBar:addChild({
		pos = { 5, botBar.size.h - 40 },
		size = { botBar.size.w - 10, 35 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true
	}, true)
	shaderEditorButton:addAdaptedText(false, TB_MENU_LOCALIZED.SHADERSEDITOR)
	shaderEditorButton:addMouseHandlers(nil, function()
			Atmospheres.MainElement:kill()
			Atmospheres.MainElement = nil
			Atmospheres.showShaderControls()
		end)

	local mainList = {
		{
			text = TB_MENU_LOCALIZED.SHADERSNAME,
			action = function(noreload)
					if (not noreload) then
						Atmospheres.ListShift[1] = 0
					end
					Atmospheres.SelectedScreen = 1
					Atmospheres.spawnMainList(listingHolder, toReload, elementHeight, "data/shader", "inc", function(file)
							Atmospheres.DefaultShader = file
							runCmd("lws " .. file)
						end, search)
				end
		},
		{
			text = TB_MENU_LOCALIZED.SHADERSATMOSNAME,
			action = function(noreload)
					if (not noreload) then
						Atmospheres.ListShift[1] = 0
					end
					Atmospheres.SelectedScreen = 2
					Atmospheres.spawnMainList(listingHolder, toReload, elementHeight, "data/atmospheres", "atmo", function(file)
							Atmospheres.loadAtmo(file)
							Atmospheres.setDefaultAtmo(file)
						end, search)
				end
		}
	}

	local modeSwitchHolder = topBar:addChild({
		pos = { 0, 35 },
		size = { topBar.size.w, topBar.size.h - 40 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local buttonWidth = (modeSwitchHolder.size.w - ((#mainList + 1) * 10)) / #mainList
	for i, v in pairs(mainList) do
		local button = modeSwitchHolder:addChild({
			pos = { 10 + (10 + buttonWidth) * (i - 1), 0 },
			size = { buttonWidth, modeSwitchHolder.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS,
			shapeType = ROUNDED,
			rounded = 4
		})
		v.element = button
		button:addChild({ shift = { 5, 2 }}):addAdaptedText(true, v.text)
		button:addMouseUpHandler(function()
			mainList[Atmospheres.SelectedScreen].element:activate(true)
			v.action()
			button:deactivate(true)
		end)

		if (i == Atmospheres.SelectedScreen) then
			button:deactivate(true)
			v.action(true)
		end
	end

	search:addKeyboardHandlers(nil, function()
			mainList[Atmospheres.SelectedScreen].action()
			search.btnDown()
		end)

	local quitButton = mainMoverHolder:addChild({
		pos = { -mainMoverHolder.size.h, 0 },
		size = { mainMoverHolder.size.h , mainMoverHolder.size.h },
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
			Atmospheres.MainElement:kill()
			Atmospheres.MainElement = nil
		end)
end

Atmospheres.loadDefaultAtmo()
