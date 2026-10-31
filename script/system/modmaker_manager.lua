-- Mod Maker manager (modern toriui shell)
-- Single window, tabs on top, content pane below.
-- Colors: DARKER = resting, LIGHTER = hover, LIGHTEST = selected, DARKEST = pressed.
-- author: Snowman
require("toriui.uielement")
require("system.menu_manager")

if (ModMaker == nil) then
	local _, top_y = get_window_safe_size()

	---Mod Maker manager class (v2.3, tab grid layout, paginated content)
	---@class ModMaker
	---@field MainElement UIElement Mod Maker main holder element
	---@field DisplayPos Vector2Base Current window offset coordinates
	---@field CurrentSection integer Index of the currently selected tab
	ModMaker = {
		DisplayPos = { x = SAFE_X + 10, y = top_y + 10 },
		CurrentSection = 1,
		ver = 2.3
	}
	ModMaker.__index = ModMaker
end

-- Shared layout constants
ModMaker.PADDING = 2
ModMaker.ROW_HEIGHT = 22
ModMaker.ROW_GAP = 1
ModMaker.SECTION_GAP = 4

---Name used for the "Export" button
ModMaker.SaveName = ModMaker.SaveName or "Untitled"
---Whether the Import picker is open
ModMaker.ImportOpen = ModMaker.ImportOpen or false

-- 3D viewport drag/select state
ModMaker.SelectedEnvObj = ModMaker.SelectedEnvObj or nil
ModMaker.DragObj = nil
ModMaker.DragDistance = nil
ModMaker.DragLastX = nil
ModMaker.DragLastY = nil
ModMaker.KeyZHeld = false
ModMaker.KeyXHeld = false

-- Move gizmo: arrows at the selected object, GizmoAxis set while dragging
ModMaker.GizmoAxis = nil
ModMaker.GizmoOriginX = nil
ModMaker.GizmoOriginY = nil
ModMaker.GizmoOriginZ = nil
-- Arrow length scales with object size - see getGizmoLen()
ModMaker.GizmoBaseLen = 0.6
ModMaker.GizmoClearance = 0.3
ModMaker.HookName = "ModMakerGizmo"
ModMaker.GizmoAxes = {
	{ name = "x", dir = { 1, 0, 0 }, color = { 0.85, 0.2, 0.2, 1 } },
	{ name = "y", dir = { 0, 1, 0 }, color = { 0.25, 0.85, 0.25, 1 } },
	{ name = "z", dir = { 0, 0, 1 }, color = { 0.3, 0.55, 0.95, 1 } }
}

---Whether the viewport gizmo/click-select should be interactive right now -
---false during Test mode or replay, where objects are physically simulated
---and shouldn't be dragged around by the editor
function ModMaker.canEdit()
	return is_mod_maker_test_mode_active() ~= true and get_world_state().replay_mode == 0
end

---Cancels any active viewport drag and restores camera control
function ModMaker.cancelDrag()
	if (ModMaker.DragObj ~= nil or ModMaker.GizmoAxis ~= nil) then
		enable_mouse_camera_movement()
		ModMaker.DragObj = nil
		ModMaker.GizmoAxis = nil
	end
end

---Closes Mod Maker and restores the previous world
function ModMaker.Quit()
	ModMaker.cancelDrag()
	remove_hooks(ModMaker.HookName)
	if (ModMaker.ViewportCapture ~= nil) then
		ModMaker.ViewportCapture:kill()
		ModMaker.ViewportCapture = nil
	end
	if (ModMaker.EditButton ~= nil) then
		ModMaker.EditButton:kill()
		ModMaker.EditButton = nil
	end
	if (ModMaker.TestButton ~= nil) then
		ModMaker.TestButton:kill()
		ModMaker.TestButton = nil
	end
	if (ModMaker.MainElement ~= nil) then
		ModMaker.MainElement:kill()
		ModMaker.MainElement = nil
	end
	-- exit_mod_maker_mode() also unwinds Test mode if still active
	exit_mod_maker_mode()
end

-- Auto-close if the player joins a multiplayer server while still editing
local function modMakerAutoClose()
	if (ModMaker.MainElement ~= nil) then
		ModMaker.Quit()
	end
end
add_hook("new_mp_game", "ModMakerAutoClose", modMakerAutoClose)
add_hook("new_game_mp", "ModMakerAutoClose", modMakerAutoClose)

---Builds the Gamerules tab
---@param contentPane UIElement
function ModMaker.buildGamerulesTab(contentPane)
	require("system.gamerules_manager")
	local gamerules = Gamerules.getRules()
	local changedValues = {}

	local elementHeight = 34
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(contentPane, 32, 42, 16, contentPane.bgColor)

	local gameRulesName = topBar:addChild({
		pos = { 8, 0 },
		size = { topBar.size.w - 16, topBar.size.h }
	})

	Gamerules.spawnMainList(listingHolder, toReload, gameRulesName, elementHeight, nil, gamerules, changedValues)

	local newGameToggleView = botBar:addChild({
		pos = { 5, 5 },
		size = { botBar.size.w / 2, 26 }
	}, true)
	TBMenu:spawnToggle(newGameToggleView, 0, 1, newGameToggleView.size.h - 2, newGameToggleView.size.h - 2, Gamerules.StartNewgame, function(val)
			Gamerules.StartNewgame = val
			set_option("grnewgame", val)
			save_custom_config()
		end)
	local newGameText = UIElement:new({
		parent = newGameToggleView,
		pos = { 6 + newGameToggleView.size.h, 0 },
		size = { newGameToggleView.size.w - 10 - newGameToggleView.size.h, newGameToggleView.size.h }
	})
	newGameText:addAdaptedText(true, TB_MENU_LOCALIZED.GAMERULESRESTARTGAME, nil, nil, 4, LEFTMID, 0.55)

	local applyButton = botBar:addChild({
		pos = { botBar.size.w / 2, 5 },
		size = { botBar.size.w / 2 - 5, 24 },
		shapeType = ROUNDED,
		rounded = 3,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	applyButton:addAdaptedText(false, TB_MENU_LOCALIZED.WORDAPPLY)
	applyButton:addMouseHandlers(nil, function()
			for _, section in pairs(gamerules) do
				for _, rule in pairs(section) do
					if (changedValues[rule.name] and changedValues[rule.name].gameValue ~= rule.gameValue) then
						if (rule.name == "engageplayerpos" and changedValues[rule.name].gameValue:match("^[0%.,]+$")) then
							changedValues[rule.name].gameValue = "0"
						end
						set_gamerule(rule.name, changedValues[rule.name].gameValue)
					end
				end
			end
			if (Gamerules.StartNewgame) then
				if (get_world_state().game_type == 1) then
					runCmd("reset")
				else
					start_new_game()
				end
			end
		end)
end

---Body part names, matches get_mod_body/set_mod_body's body_index order
ModMaker.BODY_PART_NAMES = {
	"Head", "Breast", "Chest", "Stomach", "Thorax",
	"R Pecs", "R Biceps", "R Triceps", "L Pecs", "L Biceps", "L Triceps",
	"R Hand", "L Hand", "R Butt", "L Butt",
	"R Thigh", "L Thigh", "L Leg", "R Leg", "R Foot", "L Foot"
}

ModMaker.SelectedBodyPlayer = ModMaker.SelectedBodyPlayer or 0
ModMaker.SelectedBodyPart = ModMaker.SelectedBodyPart or 0
---Current page of the Body tab's property list
ModMaker.BodyFieldsPage = ModMaker.BodyFieldsPage or 1

---Spawns a label + numeric input row
---@param parent UIElement
---@param y number
---@param rowHeight number
---@param label string
---@param initialValue number
---@param allowNegative boolean
---@param onChange fun(val: number)
---@param scrollStep ?number Amount applied per mouse wheel notch while hovering the value (default 0.01)
function ModMaker.spawnNumberRow(parent, y, rowHeight, label, initialValue, allowNegative, onChange, scrollStep)
	local scrollStep = scrollStep or 0.01
	local row = parent:addChild({
		pos = { 0, y },
		size = { parent.size.w, rowHeight },
		interactive = true,
		scrollEnabled = true
	})
	local labelText = row:addChild({
		pos = { 4, 0 },
		size = { row.size.w / 2 - 4, row.size.h }
	})
	labelText:addAdaptedText(false, label, nil, nil, 4, LEFTMID, 0.55)

	local input = TBMenu:spawnTextField2(row, {
		x = row.size.w / 2,
		w = row.size.w / 2 - 4
	}, string.format("%.2f", initialValue), nil, {
		isNumeric = true,
		allowDecimal = true,
		allowNegative = allowNegative,
		fontId = 4,
		textScale = 0.55,
		textAlign = CENTERMID,
		darkerMode = true,
		inputType = KEYBOARD_INPUT.NUMBERPAD,
		returnKeyType = KEYBOARD_RETURN.DONE
	})
	input:addInputCallback(function()
			local val = tonumber(input.textfieldstr[1])
			if (val) then
				onChange(val)
			end
		end)

	-- Scroll to nudge the value while hovering it (btn 4/5 = up/down).
	-- Wheel events don't give real cursor coords, so use MOUSE_X/Y instead.
	row.btnDown = function(btn, x, y)
		if (btn < 4) then
			return
		end
		local hovered = MOUSE_X >= input.pos.x and MOUSE_X <= input.pos.x + input.size.w and
			MOUSE_Y >= input.pos.y and MOUSE_Y <= input.pos.y + input.size.h
		if (not hovered) then
			return
		end
		local val = tonumber(input.textfieldstr[1])
		if (not val) then
			return true
		end
		val = val + (btn == 4 and scrollStep or -scrollStep)
		if (not allowNegative) then
			val = math.max(0, val)
		end
		input.textfieldstr[1] = string.format("%.2f", val)
		onChange(val)
		return true
	end
	return row
end

---Spawns a label + toggle row
---@param parent UIElement
---@param y number
---@param rowHeight number
---@param label string
---@param initialValue boolean
---@param onChange fun(val: boolean)
function ModMaker.spawnToggleRow(parent, y, rowHeight, label, initialValue, onChange)
	local row = parent:addChild({
		pos = { 0, y },
		size = { parent.size.w, rowHeight }
	})
	local labelText = row:addChild({
		pos = { 4, 0 },
		size = { row.size.w / 2 - 4, row.size.h }
	})
	labelText:addAdaptedText(false, label, nil, nil, 4, LEFTMID, 0.55)

	local toggleView = row:addChild({
		pos = { row.size.w / 2, 0 },
		size = { rowHeight, rowHeight }
	})
	TBMenu:spawnToggle(toggleView, 0, 0, toggleView.size.w, toggleView.size.h, initialValue, onChange)
	return row
end

---Spawns a label + text input row
---@param parent UIElement
---@param y number
---@param rowHeight number
---@param label string
---@param initialValue string
---@param onChange fun(val: string)
function ModMaker.spawnTextRow(parent, y, rowHeight, label, initialValue, onChange)
	local row = parent:addChild({
		pos = { 0, y },
		size = { parent.size.w, rowHeight }
	})
	local labelText = row:addChild({
		pos = { 4, 0 },
		size = { row.size.w / 2 - 4, row.size.h }
	})
	labelText:addAdaptedText(false, label, nil, nil, 4, LEFTMID, 0.55)

	local input = TBMenu:spawnTextField2(row, {
		x = row.size.w / 2,
		w = row.size.w / 2 - 4
	}, initialValue or "", nil, {
		fontId = 4,
		textScale = 0.55,
		textAlign = LEFTMID,
		darkerMode = true,
		inputType = KEYBOARD_INPUT.ASCII,
		returnKeyType = KEYBOARD_RETURN.DONE
	})
	input:addInputCallback(function()
			onChange(input.textfieldstr[1])
		end)
	return row
end

---Shared trigger fields for Body/Joint/Objects tabs
ModMaker.TRIGGER_FIELD_DEFS = {
	{ "Trigger ID", "trig_id", false },
	{ "Trigger Mask", "trig_mask", false },
	{ "Trigger Action", "trig_action", false },
	{ "Trigger Sound", "trig_sound", false },
	{ "Trigger Color R", "trig_color_r", false },
	{ "Trigger Color G", "trig_color_g", false },
	{ "Trigger Color B", "trig_color_b", false },
	{ "Trigger Color A", "trig_color_a", false },
	{ "Trigger Score", "trig_score", true }
}

---Appends the shared trigger fields to an entries list
---@param entries table[]
function ModMaker.appendTriggerEntries(entries)
	for _, f in pairs(ModMaker.TRIGGER_FIELD_DEFS) do
		table.insert(entries, { kind = "field", label = f[1], field = f[2], allowNeg = f[3] })
	end
	table.insert(entries, { kind = "toggle", label = "Score Once", field = "trig_scoreonce" })
end

---Renders one row of a paginated field list (shared by Body/Joint/Objects)
---@param holder UIElement
---@param y number
---@param entry table
---@param ROW_HEIGHT number
---@param ROW_GAP number
---@param getField fun(field: string): any
---@param setField fun(field: string, val: any)
---@param rebuild fun() Refreshes the tab after a change
function ModMaker.renderFieldEntry(holder, y, entry, ROW_HEIGHT, ROW_GAP, getField, setField, rebuild)
	if (entry.kind == "shape") then
		local currentType = getField("type") or 0
		local shapeNames = { "Sphere", "Box", "Cylinder" }
		local shapeRow = holder:addChild({
			pos = { 0, y },
			size = { holder.size.w, ROW_HEIGHT }
		})
		local bw = shapeRow.size.w / 3
		for si = 0, 2 do
			local shapeBtn = shapeRow:addChild({
				pos = { si * bw + ROW_GAP, 0 },
				size = { bw - ROW_GAP * 2, ROW_HEIGHT },
				shapeType = ROUNDED,
				rounded = 2,
				interactive = true,
				bgColor = currentType == si and TB_MENU_DEFAULT_LIGHTEST_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			shapeBtn:addAdaptedText(false, shapeNames[si + 1], nil, nil, 4, CENTERMID, 0.5)
			shapeBtn:addMouseHandlers(nil, function()
					setField("type", si)
					refresh_mod_maker_world()
					rebuild()
				end)
		end
	elseif (entry.kind == "toggle") then
		local value = getField(entry.field) or false
		ModMaker.spawnToggleRow(holder, y, ROW_HEIGHT, entry.label, value, function(val)
				setField(entry.field, val)
				refresh_mod_maker_world()
			end)
	elseif (entry.kind == "slider") then
		-- entry.scale converts 0-255 display range to 0.0-1.0 storage
		local scale = entry.scale or 1
		local value = (getField(entry.field) or 0) * scale
		local row = holder:addChild({
			pos = { 0, y },
			size = { holder.size.w, ROW_HEIGHT }
		})
		local labelText = row:addChild({
			pos = { 4, 0 },
			size = { row.size.w / 2 - 4, row.size.h }
		})
		labelText:addAdaptedText(false, entry.label, nil, nil, 4, LEFTMID, 0.55)
		local sliderHolder = row:addChild({
			pos = { row.size.w / 2, 0 },
			size = { row.size.w / 2 - 4, row.size.h }
		})
		TBMenu:spawnSlider2(sliderHolder, nil, value, {
			minValue = entry.sliderMin or 0,
			maxValue = entry.sliderMax or 255,
			decimal = 0,
			-- Dark red knob so it stands out
			darkerMode = true
		}, function(val)
				setField(entry.field, val / scale)
				refresh_mod_maker_world()
			end)
	else
		-- entry.scale lets a field display a different range than stored
		local scale = entry.scale or 1
		local value = (getField(entry.field) or 0) * scale
		ModMaker.spawnNumberRow(holder, y, ROW_HEIGHT, entry.label, value, entry.allowNeg or false, function(val)
				setField(entry.field, val / scale)
				refresh_mod_maker_world()
			end)
	end
end

---Builds a paginated fields panel (avoids the framework's unreliable
---scrollbar/virtualization by only creating rows that fit)
---@param contentPane UIElement
---@param topY number Local Y where the panel starts
---@param pageStateKey string ModMaker field used to persist the current page
---@param entries table[] One entry per row to render
---@param renderEntry fun(holder: UIElement, y: number, entry: table) Builds one row
---@return UIElement fieldsHolder
function ModMaker.buildPaginatedFieldsPanel(contentPane, topY, pageStateKey, entries, renderEntry)
	local PADDING = ModMaker.PADDING
	local ROW_HEIGHT = ModMaker.ROW_HEIGHT
	local ROW_GAP = ModMaker.ROW_GAP
	local SECTION_GAP = ModMaker.SECTION_GAP

	local fieldsHeight = math.max(0, contentPane.size.h - topY - PADDING)
	local fieldsHolder = contentPane:addChild({
		pos = { 0, topY },
		size = { contentPane.size.w, fieldsHeight },
		bgColor = contentPane.bgColor
	})

	local rowUnit = ROW_HEIGHT + ROW_GAP
	local rowsPerPageNoPager = math.max(1, math.floor((fieldsHeight + ROW_GAP) / rowUnit))
	local needsPager = #entries > rowsPerPageNoPager
	local pagerHeight = needsPager and (ROW_HEIGHT + SECTION_GAP) or 0
	local rowsPerPage = needsPager and math.max(1, math.floor((fieldsHeight - pagerHeight + ROW_GAP) / rowUnit)) or rowsPerPageNoPager
	local totalPages = math.max(1, math.ceil(#entries / rowsPerPage))

	ModMaker[pageStateKey] = ModMaker[pageStateKey] or 1
	if (ModMaker[pageStateKey] > totalPages) then
		ModMaker[pageStateKey] = totalPages
	end
	if (ModMaker[pageStateKey] < 1) then
		ModMaker[pageStateKey] = 1
	end
	local page = ModMaker[pageStateKey]
	local startIdx = (page - 1) * rowsPerPage + 1
	local endIdx = math.min(startIdx + rowsPerPage - 1, #entries)

	local y = PADDING
	for i = startIdx, endIdx do
		renderEntry(fieldsHolder, y, entries[i])
		y = y + rowUnit
	end

	if (needsPager) then
		local pagerRow = fieldsHolder:addChild({
			pos = { 0, fieldsHolder.size.h - ROW_HEIGHT },
			size = { fieldsHolder.size.w, ROW_HEIGHT }
		})
		local prevBtn = pagerRow:addChild({
			pos = { 0, 0 },
			size = { pagerRow.size.w / 4, ROW_HEIGHT },
			shapeType = ROUNDED,
			rounded = 2,
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		prevBtn:addAdaptedText(false, "< Prev", nil, nil, 4, CENTERMID, 0.5)
		prevBtn:addMouseHandlers(nil, function()
				if (ModMaker[pageStateKey] > 1) then
					ModMaker[pageStateKey] = ModMaker[pageStateKey] - 1
					ModMaker.selectSection(ModMaker.CurrentSection)
				end
			end)

		local pageLabel = pagerRow:addChild({
			pos = { pagerRow.size.w / 4, 0 },
			size = { pagerRow.size.w / 2, ROW_HEIGHT }
		})
		pageLabel:addAdaptedText(true, "Page " .. page .. " / " .. totalPages, nil, nil, 4, CENTERMID, 0.5)

		local nextBtn = pagerRow:addChild({
			pos = { pagerRow.size.w * 3 / 4, 0 },
			size = { pagerRow.size.w / 4, ROW_HEIGHT },
			shapeType = ROUNDED,
			rounded = 2,
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		nextBtn:addAdaptedText(false, "Next >", nil, nil, 4, CENTERMID, 0.5)
		nextBtn:addMouseHandlers(nil, function()
				if (ModMaker[pageStateKey] < totalPages) then
					ModMaker[pageStateKey] = ModMaker[pageStateKey] + 1
					ModMaker.selectSection(ModMaker.CurrentSection)
				end
			end)
	end

	return fieldsHolder
end

---Names for player slots 0-3, used by the Body/Joint player toggle
ModMaker.PLAYER_NAMES = { "You", "Uke", "Nage", "P4" }

---Spawns a 4-way player toggle row (You/Uke/Nage/P4)
---@param parent UIElement
---@param y number
---@param rowHeight number
---@param selected integer Currently selected player index (0-3)
---@param onSelect fun(player: integer)
---@return UIElement toggleRow
function ModMaker.spawnPlayerToggle(parent, y, rowHeight, selected, onSelect)
	local PADDING = ModMaker.PADDING
	local ROW_GAP = ModMaker.ROW_GAP
	local toggleRow = parent:addChild({
		pos = { PADDING, y },
		size = { parent.size.w - PADDING * 2, rowHeight }
	})
	local cellWidth = toggleRow.size.w / #ModMaker.PLAYER_NAMES
	for i = 0, #ModMaker.PLAYER_NAMES - 1 do
		local btn = toggleRow:addChild({
			pos = { i * cellWidth + ROW_GAP, 0 },
			size = { cellWidth - ROW_GAP * 2, rowHeight },
			shapeType = ROUNDED,
			rounded = 2,
			interactive = true,
			bgColor = selected == i and TB_MENU_DEFAULT_LIGHTEST_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		btn:addAdaptedText(false, ModMaker.PLAYER_NAMES[i + 1], nil, nil, 4, CENTERMID, 0.5)
		btn:addMouseHandlers(nil, function() onSelect(i) end)
	end
	return toggleRow
end

---Builds the Body tab
---@param contentPane UIElement
function ModMaker.buildBodyTab(contentPane)
	local player = ModMaker.SelectedBodyPlayer
	local body = ModMaker.SelectedBodyPart
	local PADDING = ModMaker.PADDING
	local ROW_HEIGHT = ModMaker.ROW_HEIGHT
	local ROW_GAP = ModMaker.ROW_GAP
	local SECTION_GAP = ModMaker.SECTION_GAP

	-- 1) Player toggle
	local toggleRow = ModMaker.spawnPlayerToggle(contentPane, PADDING, ROW_HEIGHT, player, function(i)
			ModMaker.SelectedBodyPlayer = i
			ModMaker.BodyFieldsPage = 1
			ModMaker.selectSection(ModMaker.CurrentSection)
		end)

	-- 2) Body part grid
	local gridCols = 3
	local numGridRows = math.ceil(#ModMaker.BODY_PART_NAMES / gridCols)
	-- Use .shift (local offset), not .pos (absolute screen coordinate)
	local gridTop = toggleRow.shift.y + toggleRow.size.h + SECTION_GAP
	local gridHolder = contentPane:addChild({
		pos = { PADDING, gridTop },
		size = { contentPane.size.w - PADDING * 2, numGridRows * (ROW_HEIGHT + ROW_GAP) - ROW_GAP }
	})
	local cellWidth = gridHolder.size.w / gridCols
	for r = 0, numGridRows - 1 do
		local gridRow = gridHolder:addChild({
			pos = { 0, r * (ROW_HEIGHT + ROW_GAP) },
			size = { gridHolder.size.w, ROW_HEIGHT }
		})
		for c = 0, gridCols - 1 do
			local index = r * gridCols + c
			local partName = ModMaker.BODY_PART_NAMES[index + 1]
			if (partName) then
				local cell = gridRow:addChild({
					pos = { c * cellWidth + ROW_GAP, 0 },
					size = { cellWidth - ROW_GAP * 2, ROW_HEIGHT },
					shapeType = ROUNDED,
					rounded = 2,
					interactive = true,
					bgColor = index == body and TB_MENU_DEFAULT_LIGHTEST_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
				})
				cell:addAdaptedText(false, partName, nil, nil, 4, CENTERMID, 0.45)
				cell:addMouseHandlers(nil, function()
						ModMaker.SelectedBodyPart = index
						ModMaker.BodyFieldsPage = 1
						ModMaker.selectSection(ModMaker.CurrentSection)
					end)
			end
		end
	end

	-- 3) Property panel
	local fieldsTop = gridHolder.shift.y + gridHolder.size.h + SECTION_GAP

	-- Flatten shape row + fields into one list for page math
	local entries = {}
	if (body ~= 0) then
		table.insert(entries, { kind = "shape" })
	end
	local fieldDefs = {
		{ "Position X", "pos_x", true }, { "Position Y", "pos_y", true }, { "Position Z", "pos_z", true },
		{ "Rotation X", "rot_x", true }, { "Rotation Y", "rot_y", true }, { "Rotation Z", "rot_z", true },
		{ "Scale X", "sides_x", false }, { "Scale Y", "sides_y", false }, { "Scale Z", "sides_z", false },
		{ "Density", "density", false }, { "Hardness", "hardness", false },
		{ "Friction", "friction", false }, { "Bounce", "bounce", false },
		{ "Thrust Frames", "thrust_frames", false }, { "Thrust X", "thrust_x", true },
		{ "Thrust Y", "thrust_y", true }, { "Thrust Z", "thrust_z", true }
	}
	for _, f in pairs(fieldDefs) do
		table.insert(entries, { kind = "field", label = f[1], field = f[2], allowNeg = f[3] })
	end
	table.insert(entries, { kind = "toggle", label = "Thrust Relative", field = "thrust_relative" })
	ModMaker.appendTriggerEntries(entries)

	local function getField(field) return get_mod_body(player, body, field) end
	local function setField(field, val) set_mod_body(player, body, field, val) end
	local function rebuild() ModMaker.selectSection(ModMaker.CurrentSection) end

	ModMaker.buildPaginatedFieldsPanel(contentPane, fieldsTop, "BodyFieldsPage", entries, function(holder, y, entry)
		ModMaker.renderFieldEntry(holder, y, entry, ROW_HEIGHT, ROW_GAP, getField, setField, rebuild)
	end)
end

---Joint names, matches get_mod_joint/set_mod_joint's joint_index order
ModMaker.JOINT_NAMES = {
	"Neck", "Splex", "Lumbar", "Abs",
	"R Axilla", "R Shoulder", "R Elbow",
	"L Axilla", "L Shoulder", "L Elbow",
	"R Wrist", "L Wrist",
	"R Glute", "L Glute",
	"R Hip", "L Hip",
	"R Knee", "L Knee", "R Ankle", "L Ankle"
}

ModMaker.SelectedJointPlayer = ModMaker.SelectedJointPlayer or 0
ModMaker.SelectedJoint = ModMaker.SelectedJoint or 0

---Builds the Joint tab
---@param contentPane UIElement
function ModMaker.buildJointTab(contentPane)
	local player = ModMaker.SelectedJointPlayer
	local joint = ModMaker.SelectedJoint
	local PADDING = ModMaker.PADDING
	local ROW_HEIGHT = ModMaker.ROW_HEIGHT
	local ROW_GAP = ModMaker.ROW_GAP
	local SECTION_GAP = ModMaker.SECTION_GAP

	-- 1) Player toggle
	local toggleRow = ModMaker.spawnPlayerToggle(contentPane, PADDING, ROW_HEIGHT, player, function(i)
			ModMaker.SelectedJointPlayer = i
			ModMaker.JointFieldsPage = 1
			ModMaker.selectSection(ModMaker.CurrentSection)
		end)

	-- 2) Joint grid
	local gridCols = 3
	local numGridRows = math.ceil(#ModMaker.JOINT_NAMES / gridCols)
	local gridTop = toggleRow.shift.y + toggleRow.size.h + SECTION_GAP
	local gridHolder = contentPane:addChild({
		pos = { PADDING, gridTop },
		size = { contentPane.size.w - PADDING * 2, numGridRows * (ROW_HEIGHT + ROW_GAP) - ROW_GAP }
	})
	local cellWidth = gridHolder.size.w / gridCols
	for r = 0, numGridRows - 1 do
		local gridRow = gridHolder:addChild({
			pos = { 0, r * (ROW_HEIGHT + ROW_GAP) },
			size = { gridHolder.size.w, ROW_HEIGHT }
		})
		for c = 0, gridCols - 1 do
			local index = r * gridCols + c
			local jointName = ModMaker.JOINT_NAMES[index + 1]
			if (jointName) then
				local cell = gridRow:addChild({
					pos = { c * cellWidth + ROW_GAP, 0 },
					size = { cellWidth - ROW_GAP * 2, ROW_HEIGHT },
					shapeType = ROUNDED,
					rounded = 2,
					interactive = true,
					bgColor = index == joint and TB_MENU_DEFAULT_LIGHTEST_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
				})
				cell:addAdaptedText(false, jointName, nil, nil, 4, CENTERMID, 0.45)
				cell:addMouseHandlers(nil, function()
						ModMaker.SelectedJoint = index
						ModMaker.JointFieldsPage = 1
						ModMaker.selectSection(ModMaker.CurrentSection)
					end)
			end
		end
	end

	-- 3) Property panel
	local fieldsTop = gridHolder.shift.y + gridHolder.size.h + SECTION_GAP
	local fieldDefs = {
		{ "Position X", "pos_x", true }, { "Position Y", "pos_y", true }, { "Position Z", "pos_z", true },
		{ "Axis X", "axis_x", true }, { "Axis Y", "axis_y", true }, { "Axis Z", "axis_z", true },
		{ "Hi Stop", "histop", true }, { "Lo Stop", "lostop", true },
		{ "Max Force", "maxforce", false }, { "Max Velocity", "maxvelocity", false },
		{ "Radius", "radius", false }, { "Density", "density", false }, { "Hardness", "hardness", false },
		{ "Friction", "friction", false }, { "Bounce", "bounce", false }
	}
	local entries = {}
	for _, f in pairs(fieldDefs) do
		table.insert(entries, { kind = "field", label = f[1], field = f[2], allowNeg = f[3] })
	end
	ModMaker.appendTriggerEntries(entries)

	local function getField(field) return get_mod_joint(player, joint, field) end
	local function setField(field, val) set_mod_joint(player, joint, field, val) end
	local function rebuild() ModMaker.selectSection(ModMaker.CurrentSection) end

	ModMaker.buildPaginatedFieldsPanel(contentPane, fieldsTop, "JointFieldsPage", entries, function(holder, y, entry)
		ModMaker.renderFieldEntry(holder, y, entry, ROW_HEIGHT, ROW_GAP, getField, setField, rebuild)
	end)
end

ModMaker.SelectedEnvObj = ModMaker.SelectedEnvObj or nil

---Builds the Objects tab
---@param contentPane UIElement
function ModMaker.buildObjectsTab(contentPane)
	local PADDING = ModMaker.PADDING
	local ROW_HEIGHT = ModMaker.ROW_HEIGHT
	local ROW_GAP = ModMaker.ROW_GAP
	local SECTION_GAP = ModMaker.SECTION_GAP

	local activeObjs = get_active_mod_envobjs() or {}
	local numObjs = 0
	for _ in pairs(activeObjs) do
		numObjs = numObjs + 1
	end

	-- 1) New/Delete object controls
	local toolbarRow = contentPane:addChild({
		pos = { PADDING, PADDING },
		size = { contentPane.size.w - PADDING * 2, ROW_HEIGHT }
	})
	local newBtn = toolbarRow:addChild({
		pos = { 0, 0 },
		size = { toolbarRow.size.w / 2 - PADDING / 2, toolbarRow.size.h },
		shapeType = ROUNDED,
		rounded = 2,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	newBtn:addAdaptedText(false, "+ New Object", nil, nil, 4, CENTERMID, 0.5)
	newBtn:addMouseHandlers(nil, function()
			local newIndex = create_mod_envobj()
			if (newIndex ~= nil) then
				ModMaker.SelectedEnvObj = newIndex
				ModMaker.ObjectsFieldsPage = 1
			end
			-- Rebuilds the world so the new object actually shows up
			refresh_mod_maker_world()
			ModMaker.selectSection(ModMaker.CurrentSection)
		end)

	local deleteBtn = toolbarRow:addChild({
		pos = { toolbarRow.size.w / 2 + PADDING / 2, 0 },
		size = { toolbarRow.size.w / 2 - PADDING / 2, toolbarRow.size.h },
		shapeType = ROUNDED,
		rounded = 2,
		interactive = numObjs > 0,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		inactiveColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	deleteBtn:addAdaptedText(false, "Delete Object", nil, nil, 4, CENTERMID, 0.5)
	if (numObjs > 0) then
		deleteBtn:addMouseHandlers(nil, function()
				if (ModMaker.SelectedEnvObj ~= nil) then
					delete_mod_envobj(ModMaker.SelectedEnvObj)
					ModMaker.SelectedEnvObj = nil
					ModMaker.ObjectsFieldsPage = 1
				end
				refresh_mod_maker_world()
				ModMaker.selectSection(ModMaker.CurrentSection)
			end)
	end

	if (numObjs == 0) then
		local hint = contentPane:addChild({
			pos = { PADDING, toolbarRow.shift.y + toolbarRow.size.h + SECTION_GAP },
			size = { contentPane.size.w - PADDING * 2, 50 }
		})
		hint:addAdaptedText(true, TB_MENU_LOCALIZED.MODMAKERNOOBJECTS or "This mod has no environment objects yet.", nil, nil, 4, CENTERMID, 0.55)
		return
	end

	-- Keep current selection if still active, else fall back to first
	local selected = activeObjs[0]
	if (ModMaker.SelectedEnvObj ~= nil) then
		for _, idx in pairs(activeObjs) do
			if (idx == ModMaker.SelectedEnvObj) then
				selected = idx
				break
			end
		end
	end
	ModMaker.SelectedEnvObj = selected

	-- 2) Object grid
	local gridCols = 3
	local numGridRows = math.ceil(numObjs / gridCols)
	local gridTop = toolbarRow.shift.y + toolbarRow.size.h + SECTION_GAP
	local gridHolder = contentPane:addChild({
		pos = { PADDING, gridTop },
		size = { contentPane.size.w - PADDING * 2, numGridRows * (ROW_HEIGHT + ROW_GAP) - ROW_GAP }
	})
	local cellWidth = gridHolder.size.w / gridCols
	for r = 0, numGridRows - 1 do
		local gridRow = gridHolder:addChild({
			pos = { 0, r * (ROW_HEIGHT + ROW_GAP) },
			size = { gridHolder.size.w, ROW_HEIGHT }
		})
		for c = 0, gridCols - 1 do
			local i = r * gridCols + c
			local objIndex = activeObjs[i]
			if (objIndex ~= nil) then
				local cell = gridRow:addChild({
					pos = { c * cellWidth + ROW_GAP, 0 },
					size = { cellWidth - ROW_GAP * 2, ROW_HEIGHT },
					shapeType = ROUNDED,
					rounded = 2,
					interactive = true,
					bgColor = objIndex == selected and TB_MENU_DEFAULT_LIGHTEST_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
				})
				cell:addAdaptedText(false, "Object " .. objIndex, nil, nil, 4, CENTERMID, 0.45)
				cell:addMouseHandlers(nil, function()
						ModMaker.SelectedEnvObj = objIndex
						ModMaker.ObjectsFieldsPage = 1
						ModMaker.selectSection(ModMaker.CurrentSection)
					end)
			end
		end
	end

	-- 3) Property panel
	local fieldsTop = gridHolder.shift.y + gridHolder.size.h + SECTION_GAP
	local fieldDefs = {
		{ "Position X", "pos_x", true }, { "Position Y", "pos_y", true }, { "Position Z", "pos_z", true },
		{ "Rotation X", "rot_x", true }, { "Rotation Y", "rot_y", true }, { "Rotation Z", "rot_z", true },
		{ "Scale X", "dims_x", false }, { "Scale Y", "dims_y", false }, { "Scale Z", "dims_z", false },
		{ "Mass", "mass", false },
		{ "Hardness", "hardness", false }, { "Friction", "friction", false }, { "Bounce", "bounce", false }
	}
	local colorFieldDefs = {
		{ "Color R", "color_r", false }, { "Color G", "color_g", false },
		{ "Color B", "color_b", false }, { "Color A", "color_a", false }
	}
	local entries = {}
	table.insert(entries, { kind = "shape" })
	table.insert(entries, { kind = "toggle", label = "Static", field = "static" })
	for _, f in pairs(fieldDefs) do
		table.insert(entries, { kind = "field", label = f[1], field = f[2], allowNeg = f[3] })
	end
	-- Color sliders shown 0-255, stored as 0.0-1.0
	for _, f in pairs(colorFieldDefs) do
		table.insert(entries, { kind = "slider", label = f[1], field = f[2], scale = 255 })
	end
	ModMaker.appendTriggerEntries(entries)

	local function getField(field) return get_mod_envobj(selected, field) end
	local function setField(field, val) set_mod_envobj(selected, field, val) end
	local function rebuild() ModMaker.selectSection(ModMaker.CurrentSection) end

	ModMaker.buildPaginatedFieldsPanel(contentPane, fieldsTop, "ObjectsFieldsPage", entries, function(holder, y, entry)
		ModMaker.renderFieldEntry(holder, y, entry, ROW_HEIGHT, ROW_GAP, getField, setField, rebuild)
	end)
end

---Builds the Advanced tab (thrust settings for the selected object)
---@param contentPane UIElement
function ModMaker.buildAdvancedTab(contentPane)
	local PADDING = ModMaker.PADDING
	local ROW_HEIGHT = ModMaker.ROW_HEIGHT

	local selected = ModMaker.SelectedEnvObj
	local activeObjs = get_active_mod_envobjs() or {}
	local stillActive = false
	for _, idx in pairs(activeObjs) do
		if (idx == selected) then
			stillActive = true
			break
		end
	end

	if (selected == nil or not stillActive) then
		local hint = contentPane:addChild({
			pos = { PADDING, PADDING },
			size = { contentPane.size.w - PADDING * 2, 50 }
		})
		hint:addAdaptedText(true, TB_MENU_LOCALIZED.MODMAKERSELECTOBJECTFIRST or "Pick an object on the Objects tab first.", nil, nil, 4, CENTERMID, 0.55)
		return
	end

	local header = contentPane:addChild({
		pos = { PADDING, PADDING },
		size = { contentPane.size.w - PADDING * 2, ROW_HEIGHT }
	})
	header:addAdaptedText(false, "Object " .. selected .. " - Thrust", nil, nil, 4, LEFTMID, 0.5)

	local fieldsTop = header.shift.y + header.size.h + ModMaker.SECTION_GAP
	local entries = {
		{ kind = "field", label = "Thrust Frames", field = "thrust_frames" },
		{ kind = "field", label = "Thrust X", field = "thrust_x", allowNeg = true },
		{ kind = "field", label = "Thrust Y", field = "thrust_y", allowNeg = true },
		{ kind = "field", label = "Thrust Z", field = "thrust_z", allowNeg = true },
		{ kind = "toggle", label = "Relative to object", field = "thrust_relative" }
	}

	ModMaker.buildPaginatedFieldsPanel(contentPane, fieldsTop, "AdvancedFieldsPage", entries, function(holder, y, entry)
		if (entry.kind == "toggle") then
			local value = get_mod_envobj(selected, entry.field) or false
			ModMaker.spawnToggleRow(holder, y, ROW_HEIGHT, entry.label, value, function(val)
					set_mod_envobj(selected, entry.field, val)
					refresh_mod_maker_world()
				end)
		else
			local value = get_mod_envobj(selected, entry.field) or 0
			ModMaker.spawnNumberRow(holder, y, ROW_HEIGHT, entry.label, value, entry.allowNeg or false, function(val)
					set_mod_envobj(selected, entry.field, val)
					refresh_mod_maker_world()
				end)
		end
	end)
end

---Builds the Misc tab (mod message, custom world model, and the remove/reset tools)
---@param contentPane UIElement
function ModMaker.buildMiscTab(contentPane)
	local PADDING = ModMaker.PADDING
	local ROW_HEIGHT = ModMaker.ROW_HEIGHT
	local SECTION_GAP = ModMaker.SECTION_GAP

	-- Same pair of buttons the old Mod Maker has on its Misc tab
	local toolbarRow = contentPane:addChild({
		pos = { PADDING, PADDING },
		size = { contentPane.size.w - PADDING * 2, ROW_HEIGHT }
	})
	local removeBtn = toolbarRow:addChild({
		pos = { 0, 0 },
		size = { toolbarRow.size.w / 2 - PADDING / 2, toolbarRow.size.h },
		shapeType = ROUNDED,
		rounded = 2,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	removeBtn:addAdaptedText(false, "Remove All Objects", nil, nil, 4, CENTERMID, 0.5)
	removeBtn:addMouseHandlers(nil, function()
			-- Deactivate every env joint first so nothing is left pointing at a deleted object
			for _, idx in pairs(get_active_mod_envjoints() or {}) do
				delete_mod_envjoint(idx)
			end
			for _, idx in pairs(get_active_mod_envobjs() or {}) do
				delete_mod_envobj(idx)
			end
			ModMaker.SelectedEnvObj = nil
			ModMaker.SelectedEnvJoint = nil
			refresh_mod_maker_world()
			ModMaker.selectSection(ModMaker.CurrentSection)
		end)

	local resetBtn = toolbarRow:addChild({
		pos = { toolbarRow.size.w / 2 + PADDING / 2, 0 },
		size = { toolbarRow.size.w / 2 - PADDING / 2, toolbarRow.size.h },
		shapeType = ROUNDED,
		rounded = 2,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	resetBtn:addAdaptedText(false, "Reset Everything To Default", nil, nil, 4, CENTERMID, 0.5)
	resetBtn:addMouseHandlers(nil, function()
			-- Reloads default.tbm into the maker, same as the old "Reset Everything To Default"
			if (import_mod_into_maker("default.tbm")) then
				ModMaker.SelectedBodyPart = 0
				ModMaker.SelectedJoint = 0
			end
			ModMaker.SelectedEnvObj = nil
			ModMaker.SelectedEnvJoint = nil
			refresh_mod_maker_world()
			ModMaker.selectSection(ModMaker.CurrentSection)
		end)

	local entries = {
		{ kind = "text", label = "Message of the Day", get = get_mod_message, set = set_mod_message },
		{ kind = "toggle", label = "Use World Model", get = get_mod_use_model, set = set_mod_use_model },
		{ kind = "text", label = "World Model Name", get = get_mod_model_name, set = set_mod_model_name }
	}

	local fieldsTop = toolbarRow.shift.y + toolbarRow.size.h + SECTION_GAP
	ModMaker.buildPaginatedFieldsPanel(contentPane, fieldsTop, "MiscFieldsPage", entries, function(holder, y, entry)
		if (entry.kind == "toggle") then
			local value = entry.get() or false
			ModMaker.spawnToggleRow(holder, y, ROW_HEIGHT, entry.label, value, function(val)
					entry.set(val)
					refresh_mod_maker_world()
				end)
		else
			local value = entry.get() or ""
			ModMaker.spawnTextRow(holder, y, ROW_HEIGHT, entry.label, value, function(val)
					entry.set(val)
					refresh_mod_maker_world()
				end)
		end
	end)
end

ModMaker.SelectedEnvJoint = ModMaker.SelectedEnvJoint or nil

---Builds the Joint Objects tab (joints between two environment objects)
---@param contentPane UIElement
function ModMaker.buildJointObjectsTab(contentPane)
	local PADDING = ModMaker.PADDING
	local ROW_HEIGHT = ModMaker.ROW_HEIGHT
	local ROW_GAP = ModMaker.ROW_GAP
	local SECTION_GAP = ModMaker.SECTION_GAP

	local activeObjs = get_active_mod_envobjs() or {}
	local numActiveObjs = 0
	for _ in pairs(activeObjs) do
		numActiveObjs = numActiveObjs + 1
	end

	local activeJoints = get_active_mod_envjoints() or {}
	local numJoints = 0
	for _ in pairs(activeJoints) do
		numJoints = numJoints + 1
	end

	-- 1) New/Delete controls
	local toolbarRow = contentPane:addChild({
		pos = { PADDING, PADDING },
		size = { contentPane.size.w - PADDING * 2, ROW_HEIGHT }
	})
	local newBtn = toolbarRow:addChild({
		pos = { 0, 0 },
		size = { toolbarRow.size.w / 2 - PADDING / 2, toolbarRow.size.h },
		shapeType = ROUNDED,
		rounded = 2,
		interactive = numActiveObjs >= 2,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		inactiveColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	newBtn:addAdaptedText(false, "+ New Joint", nil, nil, 4, CENTERMID, 0.5)
	if (numActiveObjs >= 2) then
		newBtn:addMouseHandlers(nil, function()
				local newIndex = create_mod_envjoint(activeObjs[0], activeObjs[1])
				if (newIndex ~= nil) then
					ModMaker.SelectedEnvJoint = newIndex
					ModMaker.JointObjectsFieldsPage = 1
				end
				refresh_mod_maker_world()
				ModMaker.selectSection(ModMaker.CurrentSection)
			end)
	end

	local deleteBtn = toolbarRow:addChild({
		pos = { toolbarRow.size.w / 2 + PADDING / 2, 0 },
		size = { toolbarRow.size.w / 2 - PADDING / 2, toolbarRow.size.h },
		shapeType = ROUNDED,
		rounded = 2,
		interactive = numJoints > 0,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		inactiveColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	deleteBtn:addAdaptedText(false, "Delete Joint", nil, nil, 4, CENTERMID, 0.5)
	if (numJoints > 0) then
		deleteBtn:addMouseHandlers(nil, function()
				if (ModMaker.SelectedEnvJoint ~= nil) then
					delete_mod_envjoint(ModMaker.SelectedEnvJoint)
					ModMaker.SelectedEnvJoint = nil
					ModMaker.JointObjectsFieldsPage = 1
				end
				refresh_mod_maker_world()
				ModMaker.selectSection(ModMaker.CurrentSection)
			end)
	end

	if (numJoints == 0) then
		local hint = contentPane:addChild({
			pos = { PADDING, toolbarRow.shift.y + toolbarRow.size.h + SECTION_GAP },
			size = { contentPane.size.w - PADDING * 2, 50 }
		})
		hint:addAdaptedText(true, numActiveObjs >= 2
			and (TB_MENU_LOCALIZED.MODMAKERNOENVJOINTS or "No joints between objects yet.")
			or (TB_MENU_LOCALIZED.MODMAKERNEEDTWOOBJECTS or "Add at least 2 objects on the Objects tab first."),
			nil, nil, 4, CENTERMID, 0.55)
		return
	end

	local selected = activeJoints[0]
	if (ModMaker.SelectedEnvJoint ~= nil) then
		for _, idx in pairs(activeJoints) do
			if (idx == ModMaker.SelectedEnvJoint) then
				selected = idx
				break
			end
		end
	end
	ModMaker.SelectedEnvJoint = selected

	-- 2) Joint grid
	local gridCols = 2
	local numGridRows = math.ceil(numJoints / gridCols)
	local gridTop = toolbarRow.shift.y + toolbarRow.size.h + SECTION_GAP
	local gridHolder = contentPane:addChild({
		pos = { PADDING, gridTop },
		size = { contentPane.size.w - PADDING * 2, numGridRows * (ROW_HEIGHT + ROW_GAP) - ROW_GAP }
	})
	local cellWidth = gridHolder.size.w / gridCols
	for r = 0, numGridRows - 1 do
		local gridRow = gridHolder:addChild({
			pos = { 0, r * (ROW_HEIGHT + ROW_GAP) },
			size = { gridHolder.size.w, ROW_HEIGHT }
		})
		for c = 0, gridCols - 1 do
			local i = r * gridCols + c
			local jointIndex = activeJoints[i]
			if (jointIndex ~= nil) then
				local o1 = get_mod_envjoint(jointIndex, "obj1") or 0
				local o2 = get_mod_envjoint(jointIndex, "obj2") or 0
				local cell = gridRow:addChild({
					pos = { c * cellWidth + ROW_GAP, 0 },
					size = { cellWidth - ROW_GAP * 2, ROW_HEIGHT },
					shapeType = ROUNDED,
					rounded = 2,
					interactive = true,
					bgColor = jointIndex == selected and TB_MENU_DEFAULT_LIGHTEST_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
				})
				cell:addAdaptedText(false, "Obj " .. o1 .. " <-> " .. o2, nil, nil, 4, CENTERMID, 0.4)
				cell:addMouseHandlers(nil, function()
						ModMaker.SelectedEnvJoint = jointIndex
						ModMaker.JointObjectsFieldsPage = 1
						ModMaker.selectSection(ModMaker.CurrentSection)
					end)
			end
		end
	end

	-- 3) Property panel
	local fieldsTop = gridHolder.shift.y + gridHolder.size.h + SECTION_GAP
	local entries = {
		{ kind = "field", label = "Object 1", field = "obj1" },
		{ kind = "field", label = "Object 2", field = "obj2" },
		{ kind = "field", label = "Position X", field = "pos_x", allowNeg = true },
		{ kind = "field", label = "Position Y", field = "pos_y", allowNeg = true },
		{ kind = "field", label = "Position Z", field = "pos_z", allowNeg = true },
		{ kind = "field", label = "Axis X", field = "axis_x", allowNeg = true },
		{ kind = "field", label = "Axis Y", field = "axis_y", allowNeg = true },
		{ kind = "field", label = "Axis Z", field = "axis_z", allowNeg = true },
		{ kind = "field", label = "Hi Stop", field = "histop", allowNeg = true },
		{ kind = "field", label = "Lo Stop", field = "lostop", allowNeg = true },
		{ kind = "field", label = "Max Force", field = "maxforce" },
		{ kind = "field", label = "Max Velocity", field = "maxvelocity" },
		{ kind = "field", label = "Hardness", field = "hardness" },
		{ kind = "field", label = "Bounce", field = "bounce" },
		{ kind = "toggle", label = "Visible", field = "visible" }
	}

	local function getField(field) return get_mod_envjoint(selected, field) end
	local function setField(field, val) set_mod_envjoint(selected, field, val) end
	local function rebuild() ModMaker.selectSection(ModMaker.CurrentSection) end

	ModMaker.buildPaginatedFieldsPanel(contentPane, fieldsTop, "JointObjectsFieldsPage", entries, function(holder, y, entry)
		ModMaker.renderFieldEntry(holder, y, entry, ROW_HEIGHT, ROW_GAP, getField, setField, rebuild)
	end)
end

---Returns the list of Mod Maker sections
---@return table
function ModMaker.getSections()
	return {
		{ title = TB_MENU_LOCALIZED.MODMAKERSECTIONGAMERULES or "Gamerules", buildContent = ModMaker.buildGamerulesTab },
		{ title = TB_MENU_LOCALIZED.MODMAKERSECTIONOBJECTS or "Objects", buildContent = ModMaker.buildObjectsTab },
		{ title = TB_MENU_LOCALIZED.MODMAKERSECTIONJOINTOBJECTS or "Joint Objects", buildContent = ModMaker.buildJointObjectsTab },
		{ title = TB_MENU_LOCALIZED.MODMAKERSECTIONADVANCED or "Advanced", buildContent = ModMaker.buildAdvancedTab },
		{ title = TB_MENU_LOCALIZED.MODMAKERSECTIONBODY or "Body", buildContent = ModMaker.buildBodyTab },
		{ title = TB_MENU_LOCALIZED.MODMAKERSECTIONJOINT or "Joint", buildContent = ModMaker.buildJointTab },
		{ title = TB_MENU_LOCALIZED.MODMAKERSECTIONMISC or "Misc", buildContent = ModMaker.buildMiscTab }
	}
end

---Switches the active tab and rebuilds the content pane
---@param index integer
function ModMaker.selectSection(index)
	if (not ModMaker.MainElement or not ModMaker.ContentPane) then
		return
	end
	ModMaker.CurrentSection = index
	ModMaker.ContentPane:kill(true)

	if (ModMaker.ImportOpen) then
		ModMaker.buildImportPicker(ModMaker.ContentPane)
	else
		local sections = ModMaker.getSections()
		sections[index].buildContent(ModMaker.ContentPane)
	end

	for i, button in pairs(ModMaker.TabButtons) do
		button.bgColor = i == index and TB_MENU_DEFAULT_LIGHTEST_COLOR or TB_MENU_DEFAULT_DARKER_COLOR
	end
end

---Builds the Import file picker
---@param contentPane UIElement
function ModMaker.buildImportPicker(contentPane)
	local PADDING = ModMaker.PADDING
	local ROW_HEIGHT = ModMaker.ROW_HEIGHT
	local SECTION_GAP = ModMaker.SECTION_GAP

	local header = contentPane:addChild({
		pos = { PADDING, PADDING },
		size = { contentPane.size.w - PADDING * 2, ROW_HEIGHT }
	})
	header:addAdaptedText(false, "Pick a mod to import", nil, nil, 4, LEFTMID, 0.5)

	local cancelBtn = header:addChild({
		pos = { header.size.w - 60, 0 },
		size = { 60, ROW_HEIGHT },
		shapeType = ROUNDED,
		rounded = 2,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	cancelBtn:addAdaptedText(false, "Cancel", nil, nil, 4, CENTERMID, 0.45)
	cancelBtn:addMouseHandlers(nil, function()
			ModMaker.ImportOpen = false
			ModMaker.selectSection(ModMaker.CurrentSection)
		end)

	-- List data/mod files plus data/mod/modmaker/ (export target)
	local mods = {}
	for _, v in pairs(get_files("data/mod", "") or {}) do
		if (type(v) == "string" and v:match("%.tbm$")) then
			table.insert(mods, v)
		end
	end
	-- get_modmaker_files() so exported mods actually show up here
	for _, v in pairs(get_modmaker_files("data/mod/modmaker", "") or {}) do
		if (type(v) == "string" and v:match("%.tbm$")) then
			table.insert(mods, "modmaker/" .. v)
		end
	end
	table.sort(mods)

	local fieldsTop = header.shift.y + header.size.h + SECTION_GAP
	if (#mods == 0) then
		local hint = contentPane:addChild({
			pos = { PADDING, fieldsTop },
			size = { contentPane.size.w - PADDING * 2, 50 }
		})
		hint:addAdaptedText(true, "No mods found in data/mod.", nil, nil, 4, CENTERMID, 0.55)
		return
	end

	ModMaker.buildPaginatedFieldsPanel(contentPane, fieldsTop, "ImportFieldsPage", mods, function(holder, y, name)
			local row = holder:addChild({
				pos = { 0, y },
				size = { holder.size.w, ROW_HEIGHT },
				shapeType = ROUNDED,
				rounded = 2,
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			row:addAdaptedText(false, (name:gsub("%.tbm$", "")), nil, nil, 4, LEFTMID, 0.5, nil, 6)
			row:addMouseHandlers(nil, function()
					if (import_mod_into_maker(name)) then
						ModMaker.SelectedBodyPart = 0
						ModMaker.SelectedJoint = 0
						ModMaker.SelectedEnvObj = nil
						ModMaker.SelectedEnvJoint = nil
						ModMaker.SaveName = (name:gsub("%.tbm$", ""))
						echo("Imported " .. name)
					end
					ModMaker.ImportOpen = false
					ModMaker.selectSection(ModMaker.CurrentSection)
				end)
		end)
end

---Draws one arrowhead (4-tri pyramid) at the tip of a gizmo arrow
---@param tipX number
---@param tipY number
---@param tipZ number
---@param dx number Unit axis direction x
---@param dy number Unit axis direction y
---@param dz number Unit axis direction z
---@param headLen number
---@param headWidth number
function ModMaker.drawGizmoHead(tipX, tipY, tipZ, dx, dy, dz, headLen, headWidth)
	-- Build a perpendicular basis (u, v) for the pyramid base
	local hx, hy, hz = 0, 0, 1
	if (math.abs(dz) > 0.9) then
		hx, hy, hz = 1, 0, 0
	end
	local ux, uy, uz = dy * hz - dz * hy, dz * hx - dx * hz, dx * hy - dy * hx
	local ulen = math.sqrt(ux * ux + uy * uy + uz * uz)
	ux, uy, uz = ux / ulen, uy / ulen, uz / ulen
	local vx, vy, vz = dy * uz - dz * uy, dz * ux - dx * uz, dx * uy - dy * ux

	local w = headWidth
	local baseX = tipX - dx * headLen
	local baseY = tipY - dy * headLen
	local baseZ = tipZ - dz * headLen
	local c1x, c1y, c1z = baseX + ux * w, baseY + uy * w, baseZ + uz * w
	local c2x, c2y, c2z = baseX - ux * w, baseY - uy * w, baseZ - uz * w
	local c3x, c3y, c3z = baseX + vx * w, baseY + vy * w, baseZ + vz * w
	local c4x, c4y, c4z = baseX - vx * w, baseY - vy * w, baseZ - vz * w

	draw_triangle(tipX, tipY, tipZ, c1x, c1y, c1z, c3x, c3y, c3z)
	draw_triangle(tipX, tipY, tipZ, c3x, c3y, c3z, c2x, c2y, c2z)
	draw_triangle(tipX, tipY, tipZ, c2x, c2y, c2z, c4x, c4y, c4z)
	draw_triangle(tipX, tipY, tipZ, c4x, c4y, c4z, c1x, c1y, c1z)
end

---Arrow reach for an object - scales with object size
---@param idx integer
function ModMaker.getGizmoLen(idx)
	local dx = get_mod_envobj(idx, "dims_x") or 0.5
	local dy = get_mod_envobj(idx, "dims_y") or 0.5
	local dz = get_mod_envobj(idx, "dims_z") or 0.5
	local objReach = math.max(dx, dy, dz) * 0.5
	return math.max(ModMaker.GizmoBaseLen, objReach + ModMaker.GizmoClearance)
end

---draw3d hook: draws the move gizmo at the selected object, if any
function ModMaker.drawGizmo()
	if (ModMaker.SelectedEnvObj == nil or ModMaker.MainElement == nil or not ModMaker.canEdit()) then
		return
	end
	local idx = ModMaker.SelectedEnvObj
	local px = get_mod_envobj(idx, "pos_x") or 0
	local py = get_mod_envobj(idx, "pos_y") or 0
	local pz = get_mod_envobj(idx, "pos_z") or 0
	local len = ModMaker.getGizmoLen(idx)
	local headLen = len * 0.22
	local headWidth = len * 0.07

	for _, axis in pairs(ModMaker.GizmoAxes) do
		local dx, dy, dz = axis.dir[1], axis.dir[2], axis.dir[3]
		local tipX = px + dx * len
		local tipY = py + dy * len
		local tipZ = pz + dz * len
		local c = axis.color
		local highlight = (ModMaker.GizmoAxis == axis)
		set_color(c[1], c[2], c[3], highlight and 1 or c[4])
		draw_line_3d(px, py, pz, tipX, tipY, tipZ, highlight and 4 or 3)
		ModMaker.drawGizmoHead(tipX, tipY, tipZ, dx, dy, dz, headLen, headWidth)
	end
end

---Closest point on an axis line to a mouse ray, in units from origin
function ModMaker.axisRayParam(originX, originY, originZ, dirX, dirY, dirZ, rayOx, rayOy, rayOz, rayDx, rayDy, rayDz)
	local rX, rY, rZ = rayOx - originX, rayOy - originY, rayOz - originZ
	local b = rayDx * dirX + rayDy * dirY + rayDz * dirZ
	local d = rayDx * rX + rayDy * rY + rayDz * rZ
	local e = dirX * rX + dirY * rY + dirZ * rZ
	local denom = 1 - b * b
	if (math.abs(denom) < 1e-5) then
		-- Ray is (near) parallel to the axis, no sane intersection
		return nil
	end
	return (e - b * d) / denom
end

---Ray-casts the cursor against the selected object's gizmo arrows
---@return table|nil axis entry from ModMaker.GizmoAxes, or nil if no hit
function ModMaker.pickGizmoAxis(x, y)
	if (ModMaker.SelectedEnvObj == nil) then
		return nil
	end
	local idx = ModMaker.SelectedEnvObj
	local px = get_mod_envobj(idx, "pos_x") or 0
	local py = get_mod_envobj(idx, "pos_y") or 0
	local pz = get_mod_envobj(idx, "pos_z") or 0

	local rox, roy, roz = ray_world_point(x, y, 0)
	local rex, rey, rez = ray_world_point(x, y, 1)
	if (rox == nil or rex == nil) then
		return nil
	end
	local rdx, rdy, rdz = rex - rox, rey - roy, rez - roz

	-- Tolerance scales with distance so picking feels consistent
	local camDx, camDy, camDz = px - rox, py - roy, pz - roz
	local camDist = math.sqrt(camDx * camDx + camDy * camDy + camDz * camDz)
	local tolerance = math.max(0.05, camDist * 0.02)
	local len = ModMaker.getGizmoLen(idx)

	local best, bestDist = nil, tolerance
	for _, axis in pairs(ModMaker.GizmoAxes) do
		local dx, dy, dz = axis.dir[1], axis.dir[2], axis.dir[3]
		local t = 0
		while (t <= len) do
			local sx, sy, sz = px + dx * t, py + dy * t, pz + dz * t
			local vx, vy, vz = sx - rox, sy - roy, sz - roz
			local proj = vx * rdx + vy * rdy + vz * rdz
			local cx, cy, cz = rox + rdx * proj, roy + rdy * proj, roz + rdz * proj
			local ddx, ddy, ddz = sx - cx, sy - cy, sz - cz
			local dist = math.sqrt(ddx * ddx + ddy * ddy + ddz * ddz)
			if (dist < bestDist) then
				bestDist = dist
				best = axis
			end
			t = t + 0.05
		end
	end
	return best
end

---Displays Mod Maker main view
function ModMaker.showMain()
	-- Force off - if left at 1, shouldReceiveInput() blocks all our clicks
	TB_MENU_MAIN_ISOPEN = 0
	usage_event("modmaker")
	local sections = ModMaker.getSections()
	local topBarHeight = 30
	local tabCols = 4
	local tabRowHeight = 24
	local tabRows = math.ceil(#sections / tabCols)
	local tabBarHeight = tabRows * tabRowHeight + 6

	-- Full-viewport capture for click-select/drag/rotate/scale on objects.
	-- Created before the window so window elements get first refusal on clicks.
	ModMaker.ViewportCapture = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { 0, 0 },
		size = { WIN_W, WIN_H },
		interactive = true,
		keyboard = true,
		permanentListener = true,
		scrollEnabled = true
	})

	-- post_draw3d, not draw3d - draw3d fires before the floor/reflection
	-- composite, which was blending back over the gizmo near ground level.
	remove_hooks(ModMaker.HookName)
	add_hook("post_draw3d", ModMaker.HookName, ModMaker.drawGizmo)

	local function withinMainWindow(x, y)
		local m = ModMaker.MainElement
		return m ~= nil and x >= m.pos.x and x <= m.pos.x + m.size.w and
			y >= m.pos.y and y <= m.pos.y + m.size.h
	end

	-- Z/X held = rotate that axis instead of moving the object
	ModMaker.ViewportCapture:addKeyboardHandlers(function(key)
			if (key == 122) then
				ModMaker.KeyZHeld = true
			elseif (key == 120) then
				ModMaker.KeyXHeld = true
			end
		end, function(key)
			if (key == 122) then
				ModMaker.KeyZHeld = false
			elseif (key == 120) then
				ModMaker.KeyXHeld = false
			end
		end)

	ModMaker.ViewportCapture:addMouseHandlers(function(btn, x, y)
			-- Refuse to pick/drag/scale while Test mode or replay is running -
			-- objects are physically simulated then, not editor-positioned
			if (not ModMaker.canEdit()) then
				return false
			end

			-- Wheel (btn 4/5): Ctrl+wheel moves along view axis, plain wheel
			-- scales. Uses MOUSE_X/MOUSE_Y, not x/y (that's the scroll delta).
			if (btn == 4 or btn == 5) then
				if (ModMaker.SelectedEnvObj == nil or withinMainWindow(MOUSE_X, MOUSE_Y)) then
					return false
				end
				if (pick_mod_envobj(MOUSE_X, MOUSE_Y) ~= ModMaker.SelectedEnvObj) then
					return false
				end

				if (get_keyboard_ctrl() > 0) then
					-- View direction, so the object moves straight along it
					local sx, sy, sz = ray_world_point(MOUSE_X, MOUSE_Y, 0)
					local ex, ey, ez = ray_world_point(MOUSE_X, MOUSE_Y, 1)
					if (sx == nil or ex == nil) then
						return false
					end
					local dx, dy, dz = ex - sx, ey - sy, ez - sz
					local step = (btn == 4) and -0.15 or 0.15
					local idx = ModMaker.SelectedEnvObj
					set_mod_envobj(idx, "pos_x", (get_mod_envobj(idx, "pos_x") or 0) + dx * step)
					set_mod_envobj(idx, "pos_y", (get_mod_envobj(idx, "pos_y") or 0) + dy * step)
					set_mod_envobj(idx, "pos_z", (get_mod_envobj(idx, "pos_z") or 0) + dz * step)
					refresh_mod_maker_world()
					ModMaker.selectSection(ModMaker.CurrentSection)
					return true
				end

				local factor = (btn == 4) and 1.08 or (1 / 1.08)
				for _, axis in pairs({ "dims_x", "dims_y", "dims_z" }) do
					local cur = get_mod_envobj(ModMaker.SelectedEnvObj, axis) or 0.3
					set_mod_envobj(ModMaker.SelectedEnvObj, axis, math.max(0.05, cur * factor))
				end
				refresh_mod_maker_world()
				ModMaker.selectSection(ModMaker.CurrentSection)
				return true
			end

			if (btn ~= 1) then
				-- A second button (e.g. right-click camera) cancels the drag
				ModMaker.cancelDrag()
				return false
			end
			if (withinMainWindow(x, y)) then
				return false
			end
			if (is_camera_drag_active()) then
				-- Camera drag already active, refuse to start an object drag
				return false
			end

			-- Move gizmo takes priority over picking/selecting a new object
			local gizmoAxis = ModMaker.pickGizmoAxis(x, y)
			if (gizmoAxis ~= nil) then
				local idx = ModMaker.SelectedEnvObj
				disable_mouse_camera_movement()
				ModMaker.GizmoAxis = gizmoAxis
				ModMaker.GizmoOriginX = get_mod_envobj(idx, "pos_x") or 0
				ModMaker.GizmoOriginY = get_mod_envobj(idx, "pos_y") or 0
				ModMaker.GizmoOriginZ = get_mod_envobj(idx, "pos_z") or 0
				return true
			end

			local idx, dist = pick_mod_envobj(x, y)
			if (idx == nil) then
				-- Clicked empty space, deselect
				if (ModMaker.SelectedEnvObj ~= nil) then
					ModMaker.SelectedEnvObj = nil
					ModMaker.selectSection(ModMaker.CurrentSection)
				end
				return false
			end

			-- Disable camera movement so dragging doesn't also spin it
			disable_mouse_camera_movement()
			ModMaker.DragObj = idx
			ModMaker.DragDistance = dist or 5
			ModMaker.DragLastX = x
			ModMaker.DragLastY = y
			ModMaker.SelectedEnvObj = idx
			ModMaker.ObjectsFieldsPage = 1
			ModMaker.selectSection(ModMaker.CurrentSection)
			return true
		end, function()
			if (ModMaker.DragObj ~= nil or ModMaker.GizmoAxis ~= nil) then
				-- Normal mouse-up: drag is done, do the one full rebuild now
				refresh_mod_maker_world()
				ModMaker.cancelDrag()
				ModMaker.selectSection(ModMaker.CurrentSection)
			end
		end, function(x, y)
			if (ModMaker.ViewportCapture.hoverState ~= BTN_DN or (ModMaker.DragObj == nil and ModMaker.GizmoAxis == nil)) then
				return
			end
			if (not ModMaker.canEdit()) then
				-- Mode changed mid-drag (e.g. replay started) - drop it
				ModMaker.cancelDrag()
				ModMaker.selectSection(ModMaker.CurrentSection)
				return
			end
			if (is_camera_drag_active()) then
				-- Right button pressed mid-drag, cancel as a safety net
				ModMaker.cancelDrag()
				ModMaker.selectSection(ModMaker.CurrentSection)
				return
			end

			if (ModMaker.GizmoAxis ~= nil) then
				-- Axis-locked move: project the mouse ray onto the axis
				local idx = ModMaker.SelectedEnvObj
				if (idx == nil) then
					ModMaker.cancelDrag()
					ModMaker.selectSection(ModMaker.CurrentSection)
					return
				end
				local rox, roy, roz = ray_world_point(x, y, 0)
				local rex, rey, rez = ray_world_point(x, y, 1)
				if (rox ~= nil and rex ~= nil) then
					local rdx, rdy, rdz = rex - rox, rey - roy, rez - roz
					local axis = ModMaker.GizmoAxis
					local t = ModMaker.axisRayParam(ModMaker.GizmoOriginX, ModMaker.GizmoOriginY, ModMaker.GizmoOriginZ,
						axis.dir[1], axis.dir[2], axis.dir[3], rox, roy, roz, rdx, rdy, rdz)
					if (t ~= nil) then
						local nx = ModMaker.GizmoOriginX + axis.dir[1] * t
						local ny = ModMaker.GizmoOriginY + axis.dir[2] * t
						local nz = ModMaker.GizmoOriginZ + axis.dir[3] * t
						set_mod_envobj(idx, "pos_x", nx)
						set_mod_envobj(idx, "pos_y", ny)
						set_mod_envobj(idx, "pos_z", nz)
						set_obj_pos(idx, nx, ny, nz)
					end
				end
				return
			end

			-- Live set_obj_pos/set_obj_rot each frame, not a full world
			-- rebuild (too slow every drag frame) - refresh happens once on release
			local idx = ModMaker.DragObj
			if (ModMaker.KeyZHeld or ModMaker.KeyXHeld) then
				local delta = (x - ModMaker.DragLastX) * 0.02
				if (ModMaker.KeyZHeld) then
					set_mod_envobj(idx, "rot_z", (get_mod_envobj(idx, "rot_z") or 0) + delta)
				end
				if (ModMaker.KeyXHeld) then
					set_mod_envobj(idx, "rot_x", (get_mod_envobj(idx, "rot_x") or 0) + delta)
				end
				set_obj_rot(idx, get_mod_envobj(idx, "rot_x") or 0, get_mod_envobj(idx, "rot_y") or 0, get_mod_envobj(idx, "rot_z") or 0)
			else
				local wx, wy, wz = ray_world_point(x, y, ModMaker.DragDistance)
				if (wx ~= nil) then
					set_mod_envobj(idx, "pos_x", wx)
					set_mod_envobj(idx, "pos_y", wy)
					set_mod_envobj(idx, "pos_z", wz)
					set_obj_pos(idx, wx, wy, wz)
				end
			end
			ModMaker.DragLastX = x
			ModMaker.DragLastY = y
		end, nil, function()
			if (ModMaker.DragObj ~= nil or ModMaker.GizmoAxis ~= nil) then
				-- Full rebuild once, now that the drag is actually done
				refresh_mod_maker_world()
				ModMaker.cancelDrag()
				ModMaker.selectSection(ModMaker.CurrentSection)
			end
		end)

	local mainViewBackground = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { ModMaker.DisplayPos.x, ModMaker.DisplayPos.y },
		size = { math.min(WIN_W - 60, 420), math.clamp(490, 400, WIN_H - 120) },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	ModMaker.MainElement = mainViewBackground
	ModMaker.DisplayPos = mainViewBackground.pos

	local mainView = mainViewBackground:addChild({
		shift = { 2, 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	}, true)

	local topBar = mainView:addChild({
		size = { mainView.size.w, topBarHeight },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		interactive = true
	}, true)
	topBar:addAdaptedText(false, TB_MENU_LOCALIZED.MAINMENUMODMAKERNAME or "Mod Maker", nil, nil, FONTS.BIG, CENTERMID, 0.65)
	topBar:addMouseHandlers(function(s, x, y)
			disable_mouse_camera_movement()
			topBar.pressedPos.x = x - topBar.pos.x
			topBar.pressedPos.y = y - topBar.pos.y
		end, enable_mouse_camera_movement, function(x, y)
			if (topBar.hoverState == BTN_DN) then
				local x = x - topBar.pressedPos.x
				local y = y - topBar.pressedPos.y
				x = x < 0 and 0 or (x + ModMaker.MainElement.size.w > WIN_W and WIN_W - ModMaker.MainElement.size.w or x)
				y = y < 0 and 0 or (y + ModMaker.MainElement.size.h > WIN_H and WIN_H - ModMaker.MainElement.size.h or y)
				ModMaker.MainElement:moveTo(x, y)
			end
		end, nil, enable_mouse_camera_movement)

	local quitButton = topBar:addChild({
		pos = { -topBar.size.h, 0 },
		size = { topBar.size.h, topBar.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	quitButton:addChild({
		shift = { 3, 3 },
		bgImage = TB_MENU_BUTTON_CROSSWHITE
	})
	quitButton:addMouseHandlers(nil, ModMaker.Quit)

	if (not is_mod_maker_mode_active()) then
		-- Mod Maker mode failed to activate (e.g. multiplayer/replay active)
		local notice = mainView:addChild({
			pos = { 0, topBar.size.h + topBar.shift.y },
			size = { mainView.size.w, mainView.size.h - topBar.shift.y - topBar.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		notice:addAdaptedText(true, TB_MENU_LOCALIZED.MODMAKERUNAVAILABLE or
			"Mod Maker isn't available right now (multiplayer match or replay in progress).",
			nil, nil, 4, nil, 0.6)
		return
	end

	-- "Edit" button brings the editor back after Test mode
	ModMaker.EditButton = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { WIN_W - 90, 130 },
		size = { 80, 26 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	ModMaker.EditButton:addAdaptedText(false, "Edit", nil, nil, 4, CENTERMID, 0.5)
	ModMaker.EditButton:addMouseHandlers(nil, function()
			exit_mod_maker_test_mode()
			TB_MENU_MAIN_ISOPEN = 0
			ModMaker.EditButton:hide()
			-- ViewportCapture must show() before MainElement (same order as
			-- their creation) or it swallows clicks meant for the window
			ModMaker.ViewportCapture:show()
			ModMaker.MainElement:show()
			ModMaker.TestButton:show()
			-- Rebuild active tab so scroll lists (e.g. Gamerules) don't keep
			-- stale drag/touch state from before the hide/show round-trip
			ModMaker.selectSection(ModMaker.CurrentSection)
		end)
	ModMaker.EditButton:hide()

	ModMaker.TestButton = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { WIN_W - 90, 130 },
		size = { 80, 26 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	ModMaker.TestButton:addAdaptedText(false, "Test", nil, nil, 4, CENTERMID, 0.5)
	ModMaker.TestButton:addMouseHandlers(nil, function()
			if (enter_mod_maker_test_mode()) then
				ModMaker.cancelDrag()
				ModMaker.MainElement:hide()
				ModMaker.ViewportCapture:hide()
				ModMaker.TestButton:hide()
				ModMaker.EditButton:show()
			end
		end)

	-- Lighter shade than topBar so tab buttons have contrast
	local tabBar = mainView:addChild({
		pos = { 0, topBar.size.h + topBar.shift.y },
		size = { mainView.size.w, tabBarHeight },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	-- Persistent Export/Import toolbar, applies to the whole mod
	local fileBarHeight = ModMaker.ROW_HEIGHT + ModMaker.PADDING * 2
	local fileBar = mainView:addChild({
		pos = { 0, tabBar.shift.y + tabBar.size.h },
		size = { mainView.size.w, fileBarHeight },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})

	local fileBtnWidth = 56
	local exportBtn = fileBar:addChild({
		pos = { ModMaker.PADDING, ModMaker.PADDING },
		size = { fileBtnWidth, fileBar.size.h - ModMaker.PADDING * 2 },
		shapeType = ROUNDED,
		rounded = 2,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	exportBtn:addAdaptedText(false, "Export", nil, nil, 4, CENTERMID, 0.45)

	local importBtn = fileBar:addChild({
		pos = { fileBar.size.w - fileBtnWidth - ModMaker.PADDING, ModMaker.PADDING },
		size = { fileBtnWidth, fileBar.size.h - ModMaker.PADDING * 2 },
		shapeType = ROUNDED,
		rounded = 2,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	importBtn:addAdaptedText(false, "Import", nil, nil, 4, CENTERMID, 0.45)
	importBtn:addMouseHandlers(nil, function()
			ModMaker.ImportOpen = true
			ModMaker.selectSection(ModMaker.CurrentSection)
		end)

	local saveNameField = TBMenu:spawnTextField2(fileBar, {
		x = exportBtn.shift.x + exportBtn.size.w + ModMaker.PADDING * 2,
		w = fileBar.size.w - fileBtnWidth * 2 - ModMaker.PADDING * 6
	}, ModMaker.SaveName, nil, {
		fontId = 4,
		textScale = 0.5,
		darkerMode = true,
		inputType = KEYBOARD_INPUT.ASCII
	})
	saveNameField:addInputCallback(function()
			ModMaker.SaveName = saveNameField.textfieldstr[1]
		end)

	exportBtn:addMouseHandlers(nil, function()
			local name = (ModMaker.SaveName and ModMaker.SaveName ~= "") and ModMaker.SaveName or "Untitled"
			local written = export_mod_maker(name)
			if (written) then
				ModMaker.SaveName = (written:gsub("^modmaker/", ""):gsub("%.tbm$", ""))
				-- Update the field the textfield actually renders
				saveNameField.textfieldstr[1] = ModMaker.SaveName
				echo("Exported mod as " .. written)
			else
				-- Visible sign export failed (reason is in debug console)
				echo("Export failed - see debug console for details")
			end
		end)

	-- Use .shift, not .pos (absolute screen coordinate)
	ModMaker.ContentPane = mainView:addChild({
		pos = { 0, fileBar.shift.y + fileBar.size.h },
		size = { mainView.size.w, mainView.size.h - fileBar.shift.y - fileBar.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	ModMaker.TabButtons = {}
	local cellWidth = tabBar.size.w / tabCols
	for i, section in pairs(sections) do
		local index = i - 1
		local col = index % tabCols
		local row = math.floor(index / tabCols)
		local button = tabBar:addChild({
			pos = { col * cellWidth + 1, 3 + row * tabRowHeight },
			size = { cellWidth - 2, tabRowHeight - 2 },
			shapeType = ROUNDED,
			rounded = 2,
			interactive = true,
			bgColor = i == ModMaker.CurrentSection and TB_MENU_DEFAULT_LIGHTEST_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		button:addAdaptedText(false, section.title, nil, nil, 4, CENTERMID, 0.45)
		button:addMouseHandlers(nil, function()
				ModMaker.ImportOpen = false
				ModMaker.selectSection(i)
			end)
		ModMaker.TabButtons[i] = button
	end

	ModMaker.selectSection(ModMaker.CurrentSection)
end
