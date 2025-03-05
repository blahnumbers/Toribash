-- Atmospheres 2.0 manager
-- Do not modify this file
require("system.atmospheres_defines")

---@class ShaderOption
---@field name string Game option name
---@field value integer Game option value
---@field id ShaderOptionId
---@field values number[]
---@field skyreload boolean Whether this option requires a sky reload
---@field count integer Count of values used by this option
---@field names string[] Slider names
---@field maxValue number Maximum slider value
---@field minValue number Minimum slider value
---@field boolean boolean Whether this option only accepts 1 and 0 as value

if (Atmospheres == nil) then
	local _, top_y = get_window_safe_size()

	---**Atmospheres and Shaders manager**
	---
	---**Version 5.74**
	---* Automatically look up a corresponding lua file in atmospheres directory when loading an atmo
	---* `drawfunc` and `framefunc` parameters to specify custom behaviors for atmo objects
	---* `dojosize` parameter for objects for dynamic scaling based on dojo size
	---* `AtmospheresInternal` utility class to store data we only want accessible locally
	---
	---**Version 5.63**
	---* `no_depth` support for atmo objects to skip depth writing when rendering
	---* `rpos_precision`, `rsize_precision`, `rcolor_precision` override values support for atmo objects to control value randomizers
	---* Added `Atmospheres.HookName` as an easily accessible generic hook name for all Atmospheres loops
	---* Added `Atmospheres.RandomPrecision` as a uniform default value to use when generating objects with random values
	---
	---**Version 5.62**
	---* Safety tweaks when parsing atmo file
	---* Ability to load tbm files as atmos by specifying the path outside atmospheres dir
	---
	---**Version 5.61**
	---* Added `Quit` method to exit Atmospheres from other scripts
	---
	---**Version 5.60**
	---* Internal updates to match new codestyle and EmmyLua annotations
	---@class Atmospheres
	---@field Globalid integer Global id for all Atmospheres class UIElement and UIElement3D objects
	---@field MainElement UIElement Main holder UIElement for Atmospheres window
	---@field EntityHolder UIElement3D Main holder UIElement3D for Atmospheres objects
	---@field StoredOptions ShaderOption[] Initial values of the options that were modified by the current shader
	---@field CurrentShader ShaderOption[] Current shader values
	---@field DisplayPos Vector2Base Window display offset coordinates
	---@field ListShift number[] Scroll bar state
	---@field DefaultShader string Default shader name
	---@field SelectedScreen integer Selected screen id
	---@field DebugHolder2D UIElement UIElement holder for debug info
	---@field HookName string Generic hook name for all Atmospheres class loops
	---@field RandomPrecision integer Default precision for random value generators
	---@field ReplaySpeed number Current replay speed, updated every frame
	Atmospheres = {
		Globalid = 1002,
		StoredOptions = {},
		CurrentShader = {},
		DisplayPos = { x = SAFE_X + 10, y = top_y + 10 },
		ListShift = { 0 },
		SelectedScreen = 1,
		HookName = "__tbAtmospheresManager",
		RandomPrecision = 1000,
		ReplaySpeed = 1,
		ver = 5.74
	}
	Atmospheres.__index = Atmospheres
end

---**Internal utility class for Atmospheres manager**
---@class AtmospheresInternal
---@field EntityList UIElement3D[]
local AtmospheresInternal = {
	EntityList = {}
}

---Destroys Atmospheres main view
function Atmospheres.Quit()
	if (Atmospheres.MainElement ~= nil) then
		Atmospheres.MainElement:kill()
		Atmospheres.MainElement = nil
	end
end

---Reverts all shader options to their initial state, destroys all atmo objects and unloads the draw3d hook
function Atmospheres.Unload()
	for _,v in pairs(Atmospheres.StoredOptions) do
		set_option(v.name, v.value)
	end
	Atmospheres.StoredOptions = {}
	_ATMO = nil
	if (Atmospheres.EntityHolder ~= nil) then
		Atmospheres.EntityHolder:kill()
		Atmospheres.EntityHolder = nil
	end
	if (Atmospheres.DebugHolder2D ~= nil) then
		Atmospheres.DebugHolder2D:kill()
		Atmospheres.DebugHolder2D = nil
	end
	Atmospheres.RestoreShader()
	AtmospheresInternal.EntityList = {}
	remove_hooks(Atmospheres.HookName)
end

---Loads default shader (if specified)
function Atmospheres.RestoreShader()
	if (Atmospheres.DefaultShader) then
		runCmd("lws " .. Atmospheres.DefaultShader)
	end
end

---@class AtmosphereEntity3D : UIElement3DOptions
---@field name string Object name
---@field parent string Parent object name
---@field count integer Object spawn count
---@field rpos number[] Object spawn position randomizer values
---@field rpos_precision number|nil
---@field rsize number[] Object spawn size randomizer values
---@field rsize_precision number|nil
---@field rcolor Color Object color randomizer values
---@field rcolor_precision number|nil
---@field color Color Object color
---@field shape UIElement3DShape
---@field model string
---@field animated boolean
---@field movement string[]|number[]
---@field rotation string[]|number[]
---@field min_level GraphicsLevel Minimum graphics level to display this object
---@field max_level GraphicsLevel Maximum graphics level to display this object
---@field dojosize number|nil Reference dojo size used by the object
---@field queue_player integer Queue player id
---@field drawfunc function|nil Custom `draw3d` function
---@field enterframefunc function|nil Custom `enter_frame` function

---@class Atmosphere
---@field shader string Custom shader name
---@field entities AtmosphereEntity3D[] List of all settings to generate Atmosphere objects
---@field shaderopts ShaderOption[] List of all custom shader options that this Atmosphere will modify
---@field opts table List of all game options that this Atmosphere will modify
---@field funcs function[] List of custom atmo functions

---Parses atmo data into an Atmosphere object
---@param filename string
---@return Atmosphere|nil
function Atmospheres.ParseFile(filename)
	local file = Files.Open(filename, FILES_MODE_READONLY)
	if (file.data == nil) then
		return nil
	end

	local luafileName = utf8.gsub(filename, ".atmo$", ".lua")
	local luafile = Files.Open(luafileName, FILES_MODE_READONLY)
	local luafileFuncs = loadstring(luafile:readAll(true)) or function() end
	luafile:close()

	---@type Atmosphere
	local atmosphere = { entities = {}, shaderopts = {}, opts = {}, funcs = luafileFuncs() or {} }
	local fileData = file:readAll()
	file:close()
	local doIgnore = false
	for _, ln in pairs(fileData) do
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
				shape = CUBE,
				min_level = 0,
				max_level = 2
			}
			doIgnore = false
		elseif (ln:find("^player %d")) then
			doIgnore = true
		elseif (doIgnore == false and #atmosphere.entities > 0) then
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
				---@diagnostic disable-next-line: assign-type-mismatch
				atmosphere.entities[#atmosphere.entities].model = model
			elseif (ln:find("^size ") or ln:find("^sides ")) then
				data = { ln:gsub("^si[zd]e[s]? ", ""):match(("([^ ]+) *"):rep(3)) }
				dataName = "size"
			elseif (ln:find("^size_dojo ")) then
				local dojosize = ln:gsub("^size_dojo ", "")
				atmosphere.entities[#atmosphere.entities].dojosize = tonumber(dojosize)
			elseif (ln:find("^randomsize ") or ln:find("^rsize ")) then
				data = { ln:gsub("^r[andom]*size ", ""):match(("([^ ]+) *"):rep(3)) }
				dataName = "rsize"
			elseif (ln:find("^rsize_precision ") or ln:find("randomsize_precision")) then
				local precision = ln:gsub("^r[andom]*size_precision ", "")
				atmosphere.entities[#atmosphere.entities].rsize_precision = tonumber(precision)
			elseif (ln:find("^pos ")) then
				data = { ln:gsub("^pos ", ""):match(("([^ ]+) *"):rep(3)) }
				dataName = "pos"
			elseif (ln:find("^randompos ") or ln:find("^rpos ")) then
				data = { ln:gsub("^r[andom]*pos ", ""):match(("([^ ]+) *"):rep(3)) }
				dataName = "rpos"
			elseif (ln:find("^rpos_precision ") or ln:find("^randompos_precision")) then
				local precision = ln:gsub("^r[andom]*pos_precision ", "")
				atmosphere.entities[#atmosphere.entities].rpos_precision = tonumber(precision)
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
			elseif (ln:find("^colo[u]?r ") or ln:find("^col ")) then
				data = { ln:gsub("^col[our]* ", ""):match(("([^ ]+) *"):rep(4)) }
				if (tonumber(data[1]) > 2 or tonumber(data[2]) > 2 or tonumber(data[3]) > 2) then
					for i = 1, 3 do
						data[i] = data[i] / 256
					end
				end
				dataName = "color"
			elseif (ln:find("^rcol[our]* ") or ln:find("^randomcol[our]* ")) then
				data = { ln:gsub("^r[andom]*col[our]* ", ""):match(("([^ ]+) *"):rep(4)) }
				if (tonumber(data[1]) > 2 or tonumber(data[2]) > 2 or tonumber(data[3]) > 2) then
					for i = 1, 3 do
						data[i] = data[i] / 256
					end
				end
				dataName = "rcolor"
			elseif (ln:find("^rcol[our]*_precision ") or ln:find("^randomcol[our]*_precision ")) then
				local precision = ln:gsub("^r[andom]*col[our]*_precision ", "")
				atmosphere.entities[#atmosphere.entities].rcolor_precision = tonumber(precision)
			elseif (ln:find("^count ")) then
				local count = ln:gsub("^count ", "")
				atmosphere.entities[#atmosphere.entities].count = tonumber(count) or 1
			elseif (ln:find("^no_depth 1")) then
				atmosphere.entities[#atmosphere.entities].ignoreDepth = true
			elseif (ln:find("^min_level ")) then
				local level = ln:gsub("^min_level ", "")
				atmosphere.entities[#atmosphere.entities].min_level = tonumber(level) or atmosphere.entities[#atmosphere.entities].min_level
			elseif (ln:find("^max_level ")) then
				local level = ln:gsub("^max_level ", "")
				atmosphere.entities[#atmosphere.entities].max_level = tonumber(level) or atmosphere.entities[#atmosphere.entities].max_level
			elseif (ln:find("^queue_player ")) then
				local playerid = ln:gsub("^queue_player ", "")
				atmosphere.entities[#atmosphere.entities].queue_player = tonumber(playerid) or 0
			elseif (ln:find("^drawfunc ")) then
				local fname = ln:gsub("^drawfunc ", "")
				atmosphere.entities[#atmosphere.entities].drawfunc = atmosphere.funcs[fname]
			elseif (ln:find("^framefunc ")) then
				local fname = ln:gsub("^framefunc ", "")
				atmosphere.entities[#atmosphere.entities].enterframefunc = atmosphere.funcs[fname]
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

	return atmosphere
end

---Gets the default world shader from user config
function Atmospheres.GetDefaultWorldShader()
	Atmospheres.DefaultShader = string.gsub(get_shader_name(), "^data/shader/", "")
	if (string.len(Atmospheres.DefaultShader) == 0) then
		Atmospheres.DefaultShader = "default.inc"
	end
end

---Displays main controls for Shader Editor
function Atmospheres.ShowShaderControls()
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
	local viewElementHolder = UIElement.new({
		globalid = is_mobile() and TBHud.HubGlobalid or TB_MENU_HUB_GLOBALID,
		pos = { 0, y + h - 90 },
		size = { WIN_W, WIN_H - y - h + 90 },
		interactive = is_mobile()
	})
	if (is_mobile()) then
		viewElementHolder:addCustomDisplay(function()
				local color = get_shader_option(0)
				viewElementHolder.bgColor[1] = color[1]
				viewElementHolder.bgColor[2] = color[2]
				viewElementHolder.bgColor[3] = color[3]
				viewElementHolder.bgColor[4] = 0.8
			end, true)
		viewElementHolder:addChild({
			pos = { 0, -viewElementHolder.size.h - 15 },
			size = { viewElementHolder.size.w, 15 },
			bgGradient = { { 1, 1, 1, 1 }, { 1, 1, 1, 0 } },
			imageColor = viewElementHolder.bgColor,
			interactive = true
		})
		local function toggleHudButtons(state)
			for _, v in pairs(TBHud.MiscButtonHolders) do
				v:setVisible(state)
			end
			TBHud.ChatButtonHolder:setVisible(state)
			TBHud.GhostButtonHolder:setVisible(state)
			TBHud.CommitStepButtonHolder:setVisible(state)
			TBHud.HoldAllButtonHolder:setVisible(state)
			TBHud.GripButtonHolder:setVisible(state)
		end
		toggleHudButtons(false)
		viewElementHolder.killAction = function() toggleHudButtons(true) end
	end
	local viewElement = viewElementHolder:addChild({
		pos = { WIN_W / 10, 15 },
		size = { WIN_W * 0.8, 60 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local toggleView = viewElement:addChild({
		shift = { viewElement.size.w / 4, 5 },
	})
	local currentControl = {}
	local shaderList = {}
	local updateOnDraw = nil

	viewElement:addCustomDisplay(false, function()
			if (updateOnDraw) then
				updateOnDraw()
				updateOnDraw = nil
			end
		end)

	local function spawnToggles()
		for i = 1, currentControl.count do
			TBMenu:spawnSlider2(toggleView, {
				x = (i - 1) * toggleView.size.w / currentControl.count + 5,
				y = 0,
				w = toggleView.size.w / currentControl.count - 10,
				h = toggleView.size.h
			}, currentControl.values[i], {
				maxValue = currentControl.maxValue,
				minValue = currentControl.minValue,
				isBoolean = currentControl.boolean,
				displayName = currentControl.names[i],
				decimal = 2,
				darkerMode = true
			}, function(value)
				currentControl.values[i] = value
				updateOnDraw = function()
					set_shader_option(currentControl.id, currentControl.values[1], currentControl.values[2], currentControl.values[3], currentControl.values[4], true, 64)
				end
			end, nil, function()
					if (currentControl.skyreload) then
						set_shader_option(currentControl.id, currentControl.values[1], currentControl.values[2], currentControl.values[3], currentControl.values[4])
					end
				end)
		end
	end

	for i,v in pairs(SHADER_OPTIONS) do
		if (v < 16) then
			local dropAction = function()
				currentControl = Atmospheres.CurrentShader[v]
				toggleView:kill(true)
				spawnToggles()
			end
			table.insert(shaderList, { text = i:gsub("_", " "), action = dropAction })
		end
	end
	currentControl = Atmospheres.CurrentShader[0]
	spawnToggles()

	local dropdownView = viewElement:addChild({
		pos = { 10, 10 },
		size = { viewElement.size.w / 4 - 20, viewElement.size.h - 20 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	TBMenu:spawnDropdown(dropdownView, shaderList, 25, WIN_H - 100, nil, { scale = 0.7 }, { scale = 0.6 })

	local closeButton = viewElement:addChild({
		pos = { -viewElement.size.h + 10, 10 },
		size = { viewElement.size.h - 20, viewElement.size.h - 20 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_BG_COLOR
	}, true)
	local closeIcon = closeButton:addChild({
		shift = { 10, 10 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})
	closeButton:addMouseUpHandler(function()
			viewElementHolder:kill()
			for _, v in pairs(options) do
				for _, k in pairs(Atmospheres.StoredOptions) do
					if (v.name == k.name) then
						set_option(k.name, k.value)
						break
					end
				end
			end
		end)
	local saveButton = viewElement:addChild({
		pos = { viewElement.size.w / 4 * 3 + 10, 10 },
		size = { viewElement.size.w / 4 - 65, viewElement.size.h - 20 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_BG_COLOR
	}, true)
	saveButton:addAdaptedText(TB_MENU_LOCALIZED.SHADERSSAVESHADER)
	saveButton:addMouseUpHandler(function()
			TBMenu:showConfirmationWindowInput(TB_MENU_LOCALIZED.SHADERSSAVING, TB_MENU_LOCALIZED.SHADERSINPUTNAME, function(name)
				local name = name:gsub("%.inc.?$", "")
				local function save()
					local file = Files.Open("../data/shader/" .. name .. ".inc", FILES_MODE_WRITE)
					if (file.data) then
						for opt, id in pairs(SHADER_OPTIONS) do
							pcall(function()
								if (Atmospheres.CurrentShader[id] ~= nil) then
									local v = Atmospheres.CurrentShader[id].values
									file:writeLine(string.lower(opt) .. " " .. v[1] .. " " .. v[2] .. " " .. v[3] .. " " .. v[4])
								end
							end)
						end
						file:close()
					else
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORCREATINGFILE)
					end
				end
				local file = Files.Open("../data/shader/" .. name .. ".inc")
				if (file.data) then
					file:close()
					TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.SHADERSERRORFILEEXISTS, save)
				else
					save()
				end
			end)
		end)
end

---Resets **CurrentShader** table and populates it with currently loaded shader data
function Atmospheres.SetShaderInfo()
	Atmospheres.CurrentShader = {}
	Atmospheres.GetShaderOpts()
end

---Returns shader option name by its id
---@param id ShaderOptionId
---@return string
function Atmospheres.GetShaderOptName(id)
	for i, v in pairs(SHADER_OPTIONS) do
		if (id == v) then
			return i
		end
	end
	return ""
end

---Populates **CurrentShader** table with the settings for the specified shader option
---@param id ShaderOptionId?
function Atmospheres.GetShaderOpts(id)
	---@type ShaderOption
	local data = {
		id = id or 0,
		values = get_shader_option(id or 0)
	}
	Atmospheres.GetShaderOptionData(data)
	Atmospheres.CurrentShader[data.id] = data

	if (data.id < 33) then
		Atmospheres.GetShaderOpts(data.id + 1)
	end
end

---Populates shader options table with additional data
---@param opt ShaderOption
function Atmospheres.GetShaderOptionData(opt)
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

	if (opt.id == 0 or (opt.id >= 9 and opt.id <= 15)) then
		opt.skyreload = true
	end
end

---Writes an atmosphere's path as the default one in config file
---@param filename string
function Atmospheres.SetDefaultAtmo(filename)
	local config = Files.Open("../data/atmospheres/atmo.cfg", FILES_MODE_WRITE)
	config:writeLine(filename)
	config:close()
end

---Loads user's specified default atmosphere
function Atmospheres.LoadDefaultAtmo()
	local config = Files.Open("../data/atmospheres/atmo.cfg")
	if (not config.data) then
		return
	end
	local configData = config:readAll()
	config:close()
	if (configData ~= nil and configData[1] ~= nil) then
		Atmospheres.LoadAtmo(configData[1])
	end
end

---Loads an atmosphere from the specified file path
---@param filename string
---@param refreshDefaultShader ?boolean
function Atmospheres.LoadAtmo(filename, refreshDefaultShader)
	Atmospheres.Unload()
	if (type(filename) ~= "string" or string.lower(filename) == "default.atmo") then
		return
	end

	if (Atmospheres.DefaultShader == nil or refreshDefaultShader) then
		Atmospheres.GetDefaultWorldShader()
	end

	add_hook("draw3d", Atmospheres.HookName, function() UIElement3D.drawVisuals(Atmospheres.Globalid) end)
	add_hook("enter_frame", Atmospheres.HookName, function() UIElement3D.drawEnterFrame(Atmospheres.Globalid) end)
	_ATMO = {}
	Atmospheres.EntityHolder = UIElement3D.new({
		globalid = Atmospheres.Globalid,
		pos = { 0, 0, 0 },
		size = { 0, 0, 0 }
	})
	Atmospheres.EntityHolder:addCustomDisplay(function()
		Atmospheres.ReplaySpeed = get_replay_cache() > 0 and math.abs(get_replay_speed()) or 1
	end)

	local atmoPath = "../data/atmospheres/"
	if (string.find(filename, "^%.%./")) then
		atmoPath = "../data/"
		filename = string.gsub(filename, "^%.%./", "")
	end
	local atmoData = Atmospheres.ParseFile(atmoPath .. filename)
	if (atmoData == nil) then
		return
	end

	local newgameHookRequired = false
	local graphics_level = Settings.GetLevel()

	for _, entity in pairs(atmoData.entities) do
		if (graphics_level >= entity.min_level and graphics_level <= entity.max_level) then
			if (entity.count) then
				for i = 1, entity.count do
					local entityRandom = table.clone(entity)
					entityRandom.name = entity.name .. i
					if (entity.rpos) then
						local precision = entity.rpos_precision or Atmospheres.RandomPrecision
						entityRandom.pos = {
							entity.pos[1] + math.random(-entity.rpos[1] * precision, entity.rpos[1] * precision) / precision,
							entity.pos[2] + math.random(-entity.rpos[2] * precision, entity.rpos[2] * precision) / precision,
							entity.pos[3] + math.random(-entity.rpos[3] * precision, entity.rpos[3] * precision) / precision
						}
					end
					if (entity.rsize) then
						local precision = entity.rsize_precision or Atmospheres.RandomPrecision
						entityRandom.size = {
							entity.size[1] + math.random(-entity.rsize[1] * precision, entity.rsize[1] * precision) / precision,
							entity.size[2] + math.random(-entity.rsize[2] * precision, entity.rsize[2] * precision) / precision,
							entity.size[3] + math.random(-entity.rsize[3] * precision, entity.rsize[3] * precision) / precision
						}
					end
					if (entity.rcolor) then
						local precision = entity.rcolor_precision or Atmospheres.RandomPrecision
						entityRandom.color = {
							entity.color[1] + math.random(-entity.rcolor[1] * precision, entity.rcolor[1] * precision) / precision,
							entity.color[2] + math.random(-entity.rcolor[2] * precision, entity.rcolor[2] * precision) / precision,
							entity.color[3] + math.random(-entity.rcolor[3] * precision, entity.rcolor[3] * precision) / precision,
							entity.color[4] + math.random(-entity.rcolor[4] * precision, entity.rcolor[4] * precision) / precision
						}
					end
					Atmospheres.SpawnObject(Atmospheres.EntityHolder, entityRandom)
				end
			else
				Atmospheres.SpawnObject(Atmospheres.EntityHolder, entity)
			end
			if (entity.dojosize) then
				newgameHookRequired = true
			end
		end
	end

	if (newgameHookRequired) then
		local applyDojoSize = function()
			local gamerules = get_game_rules()
			local dojosize = gamerules.dojotype == 0 and gamerules.dojosize or gamerules.dojosize * 2
			local entityDojoSize = nil
			for _, v in pairs(AtmospheresInternal.EntityList) do
				---@diagnostic disable-next-line: undefined-field
				entityDojoSize = v.dojosize
				if (entityDojoSize ~= nil) then
					local lastSize = table.clone(v.size)
					local scaleFactor = math.max(dojosize, 450) / entityDojoSize
					---@diagnostic disable-next-line: undefined-field
					v.size.x = v.initialSize.x * scaleFactor
					---@diagnostic disable-next-line: undefined-field
					v.size.y = v.initialSize.y * scaleFactor
					---@diagnostic disable-next-line: undefined-field
					v.size.z = v.initialSize.z * scaleFactor
					if (not table.equals(lastSize, v.size)) then
						---@diagnostic disable-next-line: undefined-field
						v:moveTo(v.initialPos.x, v.initialPos.y, v.initialPos.z, true)
						---@diagnostic disable-next-line: undefined-field
						v:moveTo((v.initialPos.x - 1) * (v.size.x - v.initialSize.x) / 2, (v.initialPos.y + 0.1) * (v.size.y - v.initialSize.y) / 2, v.initialPos.z * (v.size.z - v.initialSize.z))
					end
				end
			end
		end
		add_hook("new_game", Atmospheres.HookName, applyDojoSize)
		applyDojoSize()
	end

	if (atmoData.shader) then
		runCmd("lws " .. atmoData.shader)
	end
	for i, v in pairs(atmoData.shaderopts) do
		set_shader_option(i, v[1], v[2], v[3], v[4], i == #atmoData.shaderopts)
	end
	Atmospheres.SetShaderInfo()
	for _, v in pairs(atmoData.opts) do
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
end

---Spawns a UIElement3D object based on provided atmo entity settings
---@param entityHolder UIElement3D
---@param entity AtmosphereEntity3D
function Atmospheres.SpawnObject(entityHolder, entity)
	local item = UIElement3D.new({
		parent = (entity.parent and AtmospheresInternal.EntityList[entity.parent]) and AtmospheresInternal.EntityList[entity.parent] or entityHolder,
		pos = { unpack(entity.pos) },
		rot = { unpack(entity.rot) },
		size = { unpack(entity.size) },
		bgColor = { unpack(entity.color) },
		shapeType = entity.shape,
		objModel = entity.model,
		ignoreDepth = entity.ignoreDepth
	})
	if (entity.dojosize) then
		item.dojosize = entity.dojosize
		item.initialSize = table.clone(item.size)
		item.initialPos = table.clone(item.shift)
	end
	AtmospheresInternal.EntityList[entity.name] = item
	if (TB_MENU_DEBUG) then
		Atmospheres.DebugHolder2D = Atmospheres.DebugHolder2D or UIElement.new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		Atmospheres.DebugHolder2D:addCustomDisplay(true, function() end)
		local itemText = Atmospheres.DebugHolder2D:addChild({
			size = { 60, 20 }
		})
		itemText:addAdaptedText(true, entity.name)
		item:addChild({}):addCustomDisplay(function()
				local x, y, z = get_screen_pos(item.pos.x, item.pos.y, item.pos.z)
				if (z == 0) then
					itemText:moveTo(x, y)
				else
					itemText:moveTo(WIN_W, 0)
				end
			end)
	end
	if (entity.drawfunc) then
		if (entity.enterframefunc) then
			item:addCustomDisplay(function()
				if (UIElement.WorldState.replay_mode == 0 and UIElement.WorldState.match_frame == 0) then
					entity.enterframefunc(item, Atmospheres.ReplaySpeed)
				end
				entity.drawfunc(item)
			end)
		else
			item:addCustomDisplay(entity.drawfunc)
		end
	elseif (entity.enterframefunc) then
		item:addCustomDisplay(function()
			if (UIElement.WorldState.replay_mode == 0 and UIElement.WorldState.match_frame == 0) then
				entity.enterframefunc(item, 0.2)
			end
		end)
	end
	if (entity.animated or entity.enterframefunc) then
		local rotate, move = function() end, function() end
		if (entity.rotation) then
			local r = {}
			for i,v in pairs(entity.rotation) do
				r[i] = Atmospheres.GetFunction(i, v, entity, item, "rot")
			end
			rotate = function()
					item:rotate(r[1](), r[2](), r[3]())
				end
		end
		if (entity.movement) then
			local m = {}
			for i,v in pairs(entity.movement) do
				m[i] = Atmospheres.GetFunction(i, v, entity, item, "pos")
			end
			move = function()
					item:moveTo(m[1](), m[2](), m[3]())
				end
		end
		item:addOnEnterFrame(function()
				move()
				rotate()
				if (entity.enterframefunc) then
					entity.enterframefunc(item, Atmospheres.ReplaySpeed)
				end
			end)
	end
end

---@alias AtmoEntityFunctionType
---| "rot"
---| "pos"

---Parses a function from the atmospheres file
---@param i integer Entity id
---@param v string|number Function input to parse
---@param entity AtmosphereEntity3D
---@param obj UIElement3D
---@param ftype AtmoEntityFunctionType
---@return function
function Atmospheres.GetFunction(i, v, entity, obj, ftype)
	local resultFunc = function() end
	if (type(v) == "number") then
		if (ftype ~= "pos" or v ~= 0) then
			resultFunc = function()
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
		resultFunc = function()
			local f, err = loadstring(v)
			if (f ~= nil and not err) then
				return f()
			end
			return 0
		end
	end
	return resultFunc
end

---Spawns atmospheres list
---@param listingHolder UIElement
---@param toReload UIElement
---@param elementHeight integer
---@param path string
---@param ext string
---@param func function
---@param searchField UIElement
function Atmospheres.SpawnMainList(listingHolder, toReload, elementHeight, path, ext, func, searchField)
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
				Atmospheres.SpawnMainList(listingHolder, toReload, elementHeight, path, ext, func, searchField)
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

---Displays Atmospheres main window
function Atmospheres:showMain()
	Atmospheres.SetShaderInfo()
	if (Atmospheres.MainElement ~= nil) then
		Atmospheres.MainElement:kill()
	end
	local holderElement
	Atmospheres.MainElement, holderElement = TBMenu:spawnMoveableWindow(Atmospheres.DisplayPos)
	Atmospheres.DisplayPos = Atmospheres.MainElement.pos
	Atmospheres.MainElement.killAction = function() Atmospheres.MainElement = nil end

	local elementHeight = 36
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(holderElement, 45, 80, 20, TB_MENU_DEFAULT_BG_COLOR)

	topBar.shapeType = holderElement.shapeType
	topBar:setRounded(holderElement.rounded)
	botBar.shapeType = holderElement.shapeType
	botBar:setRounded(holderElement.rounded)

	local search = TBMenu:spawnTextField2(botBar, {
		x = 5,
		y = 5,
		w = botBar.size.w - 10,
		h = botBar.size.h - 50
	}, nil, TB_MENU_LOCALIZED.SEARCHNOTE, {
		fontId = 4,
		textScale = 0.65,
		textAlign = LEFTMID,
		keepFocusOnHide = true
	})

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
			Atmospheres.ShowShaderControls()
		end)

	local mainList = {
		{
			text = TB_MENU_LOCALIZED.SHADERSNAME,
			action = function(noreload)
					if (not noreload) then
						Atmospheres.ListShift[1] = 0
					end
					Atmospheres.SelectedScreen = 1
					Atmospheres.SpawnMainList(listingHolder, toReload, elementHeight, "data/shader", "inc", function(file)
							runCmd("lws " .. file)
							Atmospheres.GetDefaultWorldShader()
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
					Atmospheres.SpawnMainList(listingHolder, toReload, elementHeight, "data/atmospheres", "atmo", function(file)
							Atmospheres.LoadAtmo(file)
							Atmospheres.SetDefaultAtmo(file)
						end, search)
				end
		}
	}

	local modeSwitchHolder = topBar:addChild({
		pos = { 0, 5 },
		size = { topBar.size.w, topBar.size.h - 10 },
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
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
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
end

Atmospheres.LoadDefaultAtmo()
