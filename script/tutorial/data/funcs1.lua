local INTRO = 1
local OUTRO = -1
local FPS_MULTIPLIER = get_option("framerate") == 30 and 2 or 1

local function drawSingleKey(viewElement, reqTable, key, requireSelected)
	usage_event("tutorial1" .. key .. "key")
	local BUTTON_DEFAULT_COLOR = { unpack(TB_MENU_DEFAULT_BG_COLOR) }
	local BUTTON_HOVER_COLOR = { unpack(TB_MENU_DEFAULT_LIGHTEST_COLOR) }

	local button = UIElement:new({
		parent = viewElement,
		pos = { 200, -WIN_H / 3 - 35 },
		size = { 100, 70 },
		interactive = true,
		bgColor = BUTTON_DEFAULT_COLOR,
		hoverColor = BUTTON_HOVER_COLOR,
		shapeType = ROUNDED,
		rounded = 10
	})
	button:deactivate()
	button.isactive = true
	button:addAdaptedText(false, key)

	local req = { type = "keypresscontrol", ready = false }
	table.insert(reqTable, req)

	add_hook("key_up", Tutorials.StepHook, function(s, code)
			if ((string.schar(s) == key or (code > 3 and code < 30 and string.schar(code + 93) == key)) and button.hoverState ~= BTN_NONE) then
				button.hoverState = BTN_NONE
				req.ready = true
				reqTable.ready = Tutorials:checkRequirements(reqTable)
			end
		end)
	add_hook("key_down", Tutorials.StepHook, function(s, code)
			if (requireSelected and get_world_state().selected_joint < 0) then return end
			if (string.schar(s) == key or (code > 3 and code < 30 and string.schar(code + 93) == key)) then
				button.hoverState = BTN_HVR
			end
		end)
end

local function drawWASD(viewElement, reqTable, shift, fade)
	set_camera_mode(0)
	local BUTTON_DEFAULT_COLOR = { unpack(TB_MENU_DEFAULT_BG_COLOR) }
	local BUTTON_HOVER_COLOR = { unpack(TB_MENU_DEFAULT_LIGHTEST_COLOR) }
	local wasdButtonsView = UIElement:new({
		parent = viewElement,
		pos = { 100, -320 },
		size = { 300, 200 }
	})

	local keysToPress = {
		w = { pressed = false, pos = 2 },
		a = { pressed = false, pos = 4 },
		s = { pressed = false, pos = 5 },
		d = { pressed = false, pos = 6 },
	}
	if (shift) then
		keysToPress.shift = { pressed = false, pos = 7, size = 3 }
	end
	for i,v in pairs(keysToPress) do
		v.keyButton = UIElement:new({
			parent = wasdButtonsView,
			pos = { (v.pos - 1) % 3 * wasdButtonsView.size.w / 3 + 5, math.floor((v.pos - 1) / 3) * wasdButtonsView.size.h / 3 },
			size = { wasdButtonsView.size.w / 3 * (v.size and v.size or 1) - 10, wasdButtonsView.size.h / 3 - 5 },
			interactive = true,
			bgColor = BUTTON_DEFAULT_COLOR,
			hoverColor = BUTTON_HOVER_COLOR,
			shapeType = ROUNDED,
			rounded = 10
		})
		v.keyButton:deactivate()
		v.keyButton.isactive = true
		v.keyButton:addAdaptedText(false, i)
	end
	if (fade) then
		BUTTON_DEFAULT_COLOR[4] = (fade == INTRO and 0 or 1)
		local transparencyController = UIElement:new({
			parent = wasdButtonsView,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		transparencyController:addCustomDisplay(true, function()
				BUTTON_DEFAULT_COLOR[4] = BUTTON_DEFAULT_COLOR[4] + 0.04 * fade * FPS_MULTIPLIER
				if (fade == 1) then
					if (BUTTON_DEFAULT_COLOR[4] >= 1) then
						BUTTON_DEFAULT_COLOR[4] = 1
						transparencyController:kill()
					end
				else
					if (BUTTON_DEFAULT_COLOR[4] <= 0) then
						wasdButtonsView:kill()
						BUTTON_DEFAULT_COLOR[4] = 0
					end
				end
			end)
	end

	if (reqTable) then
		local req = { type = "cameracontrols", ready = false }
		table.insert(reqTable, req)

		add_hook("key_up", Tutorials.StepHook, function(key, code)
				if (shift and get_shift_key_state() == 0) then
					keysToPress.shift.keyButton.hoverState = BTN_NONE
				end
				for i,v in pairs(keysToPress) do
					if (i ~= "shift") then
						if (string.schar(code + 93) == i) then
							v.keyButton.hoverState = BTN_NONE
						end
						if (shift) then
							if ((string.schar(code + 93) == "w" or string.schar(code + 93) == "s") and get_shift_key_state() > 0) then
								req.ready = true
								reqTable.ready = Tutorials:checkRequirements(reqTable)
							end
						else
							local ready = true
							for i,v in pairs(keysToPress) do
								if (not v.pressed) then
									ready = false
								end
							end
							if (ready) then
								req.ready = true
								reqTable.ready = Tutorials:checkRequirements(reqTable)
							end
						end
					end
				end
			end)
		add_hook("key_down", Tutorials.StepHook, function(key, code)
				if (shift and get_shift_key_state() > 0) then
					keysToPress.shift.keyButton.hoverState = BTN_HVR
				end
				for i,v in pairs(keysToPress) do
					if (i ~= "shift") then
						if (string.schar(code + 93) == i) then
							if (shift) then
								if (get_shift_key_state() > 0 and i ~= "shift") then
									keysToPress[i].pressed = true
								end
							else
								keysToPress[i].pressed = true
							end
							keysToPress[i].keyButton.hoverState = BTN_HVR
							break
						end
					end
				end
			end)
	end
end

local function prepareClassicCamera()
	add_hook("camera", "tbTutorial1Camera", function()
			local camera_info = get_camera_info()
			set_camera_mode(3)
			set_camera_lookat(camera_info.lookat.x, camera_info.lookat.y, camera_info.lookat.z)
			set_camera_pos(camera_info.pos.x, camera_info.pos.y, camera_info.pos.z)
			set_camera_mode(0)
			remove_hook("camera", "tbTutorial1Camera")
		end)
end

local function drawWASDStatic(viewElement, reqTable, shift, fade)
	usage_event("tutorial1wasd")
	drawWASD(viewElement, nil, shift, fade or INTRO)
	prepareClassicCamera()
end

local function waitCameraPositionChange(viewElement, reqTable)
	local cameraPos = nil
	local req = { type = "cameracontrols", ready = false }
	table.insert(reqTable, req)

	add_hook("camera", "tbTutorial1CameraPos", function()
			local cameraInfo = get_camera_info()
			cameraPos = cameraPos or cameraInfo.pos
			local cameraMag = math.sqrt(math.pow(cameraPos.x - cameraInfo.pos.x, 2) + math.pow(cameraPos.y - cameraInfo.pos.y, 2) + math.pow(cameraPos.z - cameraInfo.pos.z, 2))
			if (cameraMag > 1) then
				remove_hook("camera", "tbTutorial1CameraPos")
				local markReady = function()
					req.ready = true
					reqTable.ready = Tutorials:checkRequirements(reqTable)
					remove_hook("mouse_button_up", "tbTutorial1CameraPos")
				end
				add_hook("mouse_button_up", "tbTutorial1CameraPos", markReady)
				local clock = UIElement.clock
				viewElement:addChild({}):addCustomDisplay(true, function()
						if (UIElement.clock - clock > 1) then
							clock = UIElement.clock
							markReady()
						end
					end)
			end
		end)
end

local function prepareCameraControls(viewElement, reqTable, shift, fade)
	prepareClassicCamera()
	if (not is_mobile()) then
		drawWASDStatic(viewElement, reqTable, shift, fade)
	else
		enable_mouse_camera_movement()
	end
end

local function showCameraInvertModes(viewElement, reqTable)
	Tutorials:reqButton(reqTable)

	local buttonWidth = math.clamp(WIN_W / 3, 400, 600)
	local buttonHeight = math.clamp(WIN_H / 10, 60, 120)
	local invertHorizontalButton = viewElement:addChild({
		pos = { Tutorials.HintMessageView.pos.x, Tutorials.HintMessageView.pos.y - buttonHeight * 3 },
		size = { buttonWidth, buttonHeight },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local function toggleOption(button, text, state)
		button:kill(true)
		if (state) then
			button:addChild({}):addAdaptedText(text)
		else
			TBMenu:showTextWithImage(button, text, FONTS.MEDIUM, 32, "../textures/menu/general/buttons/checkmark.tga", nil, true)
		end
	end
	invertHorizontalButton:addMouseUpHandler(function()
			local currentval = get_option("invertedcam") or 0
			local invertedx = 1 - (bit.band(currentval, 1) ~= 0 and 1 or 0)
			local invertedy = bit.band(currentval, 2) ~= 0 and 1 or 0
			set_option("invertedcam", bit.bor(invertedx, invertedy * 2))
			toggleOption(invertHorizontalButton, TB_MENU_LOCALIZED.SETTINGSCAMERAINVERTX, invertedx == 1)
		end)

	local invertVerticalButton = viewElement:addChild({
		pos = { invertHorizontalButton.shift.x, invertHorizontalButton.shift.y + buttonHeight * 1.4 },
		size = { buttonWidth, buttonHeight },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	invertVerticalButton:addMouseUpHandler(function()
			local currentval = get_option("invertedcam") or 0
			local invertedx = bit.band(currentval, 1) ~= 0 and 1 or 0
			local invertedy = 1 - (bit.band(currentval, 2) ~= 0 and 1 or 0)
			set_option("invertedcam", bit.bor(invertedx, invertedy * 2))
			toggleOption(invertVerticalButton, TB_MENU_LOCALIZED.SETTINGSCAMERAINVERTY, invertedy == 1)
		end)

	local currentval = get_option("invertedcam") or 0
	toggleOption(invertHorizontalButton, TB_MENU_LOCALIZED.SETTINGSCAMERAINVERTX, bit.band(currentval, 1) ~= 0)
	toggleOption(invertVerticalButton, TB_MENU_LOCALIZED.SETTINGSCAMERAINVERTY, bit.band(currentval, 2) ~= 0)
end

local function drawWASDShift(viewElement, reqTable)
	drawWASD(viewElement, reqTable, true)
end

local function drawWASDShiftStatic(viewElement, reqTable)
	drawWASDStatic(viewElement, nil, true, OUTRO)
end

local function setIntroPlayers()
	set_joint_color(0, 50, 27)
	set_joint_color(1, 50, 30)
	set_torso_color(0, 27)
	set_torso_color(1, 30)
end

local function drawSingleKeyC(viewElement, reqTable)
	drawSingleKey(viewElement, reqTable, "c")
end

local function drawSingleKeyZ(viewElement, reqTable)
	drawSingleKey(viewElement, reqTable, "z", true)
end

local function drawSingleKeyX(viewElement, reqTable)
	drawSingleKey(viewElement, reqTable, "x", true)
end

local function fractureToriKnee()
	usage_event("tutorial1cbreakleg")
	fracture_joint(0, JOINTS.L_KNEE)
end

local function waitButton(_, reqTable)
	Tutorials:reqButton(reqTable)
end

local function waitJointWheel(_, reqTable)
	local req = { type = "waitjointwheel", ready = false }
	table.insert(reqTable, req)

	Tutorials:reqButton(reqTable)

	Tooltip.AddOnToggleWheelEvent("tutorial1jointwheel", function()
			req.ready = true
			reqTable.ready = Tutorials:checkRequirements(reqTable)
			Tooltip.RemoveOnTapEvent("tutorial1jointwheel")
		end)
end

---@param viewElement UIElement
local function waitRelaxAll(viewElement, reqTable)
	local req = { type = "waitrelaxall", ready = false }
	table.insert(reqTable, req)

	local radius = TBHud.HoldAllButtonHolder.size.w / 2
	local buttonIndicator = viewElement:addChild({
		pos = { TBHud.HoldAllButtonHolder.pos.x + radius, TBHud.HoldAllButtonHolder.pos.y + radius },
		size = { radius - 1, radius - 1 }
	})
	local maxGrow = 15
	local grow = 0
	local jointStates = {}
	for _, v in pairs(JOINTS) do
		jointStates[v] = get_joint_info(0, v).state
	end
	buttonIndicator:addCustomDisplay(true, function()
			for _, v in pairs(JOINTS) do
				if (get_joint_info(0, v).state ~= jointStates[v]) then
					req.ready = true
					reqTable.ready = Tutorials:checkRequirements(reqTable)
					break
				end
			end
			grow = grow + maxGrow / tonumber(get_option("framerate") or 60)
			if (grow > maxGrow) then
				grow = 0
			end
			set_color(TB_MENU_DEFAULT_BG_COLOR[1], TB_MENU_DEFAULT_BG_COLOR[2], TB_MENU_DEFAULT_BG_COLOR[3], 1 - grow / maxGrow)
			draw_disk(buttonIndicator.pos.x, buttonIndicator.pos.y, buttonIndicator.size.w, buttonIndicator.size.w + grow, 0, 1, 0, 360, 0)
		end)
end

return {
	PrepareCameraControls = prepareCameraControls,
	DrawWASDCameraControls = is_mobile() and waitCameraPositionChange or drawWASD,
	DrawWASDShiftCameraControls = is_mobile() and showCameraInvertModes or drawWASDShift,
	HideWASDShiftControls = is_mobile() and function() end or drawWASDShiftStatic,
	SetIntroPlayers = setIntroPlayers,
	DrawXKey = is_mobile() and waitJointWheel or drawSingleKeyX,
	DrawZKey = is_mobile() and waitButton or drawSingleKeyZ,
	DrawCKey = is_mobile() and waitRelaxAll or drawSingleKeyC,
	BreakLeg = fractureToriKnee,
	PrepareCamera = prepareClassicCamera,
}
