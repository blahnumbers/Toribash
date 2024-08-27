local function setStartPose()
	local startPose = {
		{ joint = JOINTS.R_HIP, state = JOINT_STATE.BACK },
		{ joint = JOINTS.L_HIP, state = JOINT_STATE.BACK },
		{ joint = JOINTS.R_GLUTE, state = JOINT_STATE.BACK },
		{ joint = JOINTS.L_GLUTE, state = JOINT_STATE.BACK },
		{ joint = JOINTS.R_PECS, state = JOINT_STATE.FORWARD },
		{ joint = JOINTS.L_PECS, state = JOINT_STATE.FORWARD },
		{ joint = JOINTS.R_SHOULDER, state = JOINT_STATE.BACK },
		{ joint = JOINTS.L_SHOULDER, state = JOINT_STATE.BACK },
		{ joint = JOINTS.R_ELBOW, state = JOINT_STATE.FORWARD },
		{ joint = JOINTS.L_ELBOW, state = JOINT_STATE.FORWARD },
		{ joint = JOINTS.ABS, state = JOINT_STATE.BACK },
	}
	for _, v in pairs(startPose) do
		set_joint_state(1, v.joint, v.state, true)
	end
end

local function checkScoreChange()
	local score = math.ceil(get_player_info(0).score)
	if (score ~= COMEBACK_LAST_SCORE) then
		COMEBACK_LAST_SCORE = score
		return true
	end
	return false
end

local function teleportUke(maxDisplace)
	local playerStomachPos = get_body_info(0, BODYPARTS.STOMACH).pos

	-- Make sure Uke isn't spawned too close to player
	local randomDisplace = { x = math.random(-maxDisplace * 1000, maxDisplace * 1000) / 1000 + 1, y = math.random(-maxDisplace * 1000, maxDisplace * 1000) / 1000 - 0.1 }
	while (math.abs(randomDisplace.x - playerStomachPos.x) < maxDisplace * 0.8 or math.abs(randomDisplace.y - playerStomachPos.y) < maxDisplace * 0.8) do
		randomDisplace = { x = math.random(-maxDisplace * 1000, maxDisplace * 1000) / 1000 + 1, y = math.random(-maxDisplace * 1000, maxDisplace * 1000) / 1000 - 0.1 }
	end

	-- Move Uke
	local relPos = get_body_info(1, BODYPARTS.STOMACH).pos
	for _, v in pairs(BODYPARTS) do
		local pos = get_body_info(1, v).pos
		set_body_pos(1, v, randomDisplace.x + pos.x - relPos.x, randomDisplace.y + pos.y - relPos.y, pos.z)
	end
	set_joint_state(1, JOINTS.NECK, JOINT_STATE.HOLD)
end

local function checkCollision()
	if (checkScoreChange()) then
		local ws = UIElement.WorldState
		if (ws.winner == -1 and ws.replay_mode == 0 and ws.match_frame ~= 0) then
			teleportUke(COMEBACK_DISPLACE)

			-- Increment teleport distance and comeback score after every teleporting
			COMEBACK_SCORE = COMEBACK_SCORE + 1
			COMEBACK_DISPLACE = COMEBACK_DISPLACE >= 6 and COMEBACK_DISPLACE or COMEBACK_DISPLACE + 0.5
		end
	end
end

---@param viewElement UIElement
---@param button UIElement
local function toggleSettings(viewElement, button)
	local windowMover = UIElement:new({
		parent = viewElement,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	button:deactivate()

	local state = viewElement.pos.y < 0 and true or false
	local targetPos = state and -WIN_H + 60 or -viewElement.size.h - WIN_H + 70
	local clock = UIElement.clock

	for _,v in pairs(viewElement.child) do
		v:setActive(state)
	end

	windowMover:addCustomDisplay(true, function()
		local ratio = UIElement.clock - clock
		viewElement:moveTo(nil, UITween.SineTween(viewElement.shift.y, targetPos, ratio))
		if (ratio >= 1) then
			windowMover:kill()
			button:activate()
		end
	end)
end

local function restartGame()
	TUTORIAL_LEAVEGAME = true
	runCmd("loadmod system/tutorial/comebackpractice.tbm")
	runCmd("set numplayers " .. COMEBACK_SETTINGS.numplayers)
	runCmd("set matchframes " .. COMEBACK_SETTINGS.matchframes)
	runCmd("set turnframes " .. COMEBACK_SETTINGS.turnframes)
	runCmd("set gravity 0.00 0.00 " .. COMEBACK_SETTINGS.gravity)
	start_new_game()
	TUTORIAL_LEAVEGAME = false
end

local function loadSettings(viewElement, reqTable, viewElementGlobal)
	local settingsState = {}
	for i,v in pairs(COMEBACK_SETTINGS) do
		settingsState[i] = v
	end

	local cbsettings =
 	{
		matchframes = {
			{ val = 2000 },
			{ val = 4000 },
			{ val = 8000 },
			{ val = 500000, name = Tutorials.LocalizedMessages.ENDLESS }
		},
		turnframes = {
			{ val = 30 },
			{ val = 50 },
			{ val = 70 }
		},
		gravity = {
			{ val = -9.87 },
			{ val = -20.00 },
			{ val = -30.00 }
		}
	}

	local canApply = false
	local applySettings = viewElement:addChild({
		pos = { 20, -70 },
		size = { viewElement.size.w - 40, 50 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		interactive = true,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
		hoverSound = 31,
		shapeType = ROUNDED,
		rounded = 4
	})

	local settingCount = 0
	for i,v in pairs(cbsettings) do
		local settingName = viewElement:addChild({
			pos = { 10, 30 + settingCount * 80 },
			size = { viewElement.size.w - 20, 30 }
		})
		settingName:addCustomDisplay(true, function()
				settingName:uiText(i, nil, nil, FONTS.BIG, nil, 0.55)
			end)
		for j,k in pairs(v) do
			local option = viewElement:addChild({
				pos = { 10 + (j - 1) / #v * (viewElement.size.w - 20), 65 + settingCount * 80 },
				size = { (viewElement.size.w - 20) / #v, 25 },
				interactive = true,
				bgColor = UICOLORWHITE,
				hoverColor = TB_MENU_DEFAULT_ORANGE,
				pressedColor = TB_MENU_DEFAULT_DARKER_ORANGE,
				uiShadowColor = TB_MENU_DEFAULT_ORANGE,
				hoverSound = 31,
				shadowOffset = 4
			})
			option:addCustomDisplay(true, function()
					option:uiText(tostring(k.name or k.val), nil, nil, nil, nil, nil, nil, k.val == settingsState[i] and 4 or nil, k.val == settingsState[i] and UICOLORBLACK or option:getButtonColor())
				end)
			option:addMouseHandlers(nil, function()
					settingsState[i] = k.val
					for o,z in pairs(settingsState) do
						canApply = z ~= COMEBACK_SETTINGS[o] and true or false
					end
				end)
		end
		settingCount = settingCount + 1
	end
	local lastState = canApply
	applySettings:addCustomDisplay(false, function()
			if (canApply) then
				applySettings:uiText(TB_MENU_LOCALIZED.SETTINGSAPPLY)
			else
				applySettings:uiText(TB_MENU_LOCALIZED.SETTINGSNOCHANGES)
			end
			if (lastState ~= canApply) then
				lastState = canApply
				applySettings:setActive(canApply, true)
			end
		end)
	applySettings:deactivate(true)
	applySettings:addMouseHandlers(nil, function()
			TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.CONFIRMAREYOUSURE, function()
					for i,v in pairs(settingsState) do
						COMEBACK_SETTINGS[i] = v
					end
					Tutorials.CurrentStep.skip = 1
					Tutorials:reqDelay(viewElementGlobal, reqTable, 0)
				end, nil, nil, nil, Tutorials.Globalid)
		end)
end

local function initComebackPractice(viewElement, reqTable)
	COMEBACK_LAST_SCORE = 0
	COMEBACK_SCORE = 0
	COMEBACK_DISPLACE = 2
	COMEBACK_SETTINGS = COMEBACK_SETTINGS or {
		matchframes = 2000,
		turnframes = 30,
		gravity = -30,
		numplayers = 2
	}
	if (viewElement ~= nil) then
		restartGame()
	end
end

local function loadVisuals(viewElement, reqTable)
	DISPLAY_FRAMES = get_world_state().game_frame
	local settingsView = viewElement:addChild({
		pos = { viewElement.size.w / 4 + 10, -viewElement.size.h - 300 },
		size = { viewElement.size.w / 2 - 20, 350 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 10,
		shadowColor = TB_MENU_DEFAULT_DARKER_COLOR,
		innerShadow = { 15, 5 }
	})
	loadSettings(settingsView, reqTable, viewElement)
	local topBar = viewElement:addChild({
		pos = { viewElement.size.w / 4, -viewElement.size.h - 10 },
		size = { viewElement.size.w / 2, 80 },
		shapeType = ROUNDED,
		rounded = 10,
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local hitCounter = topBar:addChild({
		pos = { 15, 10 },
		size = { topBar.size.w / 3 - 30, 70 }
	})
	hitCounter:addCustomDisplay(true, function()
			hitCounter:uiText(Tutorials.LocalizedMessages.SCORE .. ": " .. COMEBACK_SCORE, nil, nil, nil, LEFTMID)
		end)
	local timer = topBar:addChild({
		pos = { topBar.size.w / 3 + 15, 8 },
		size = { topBar.size.w / 3 - 30, 70 },
		uiColor = { 1, 0.8, 0, 1 }
	})
	if (COMEBACK_SETTINGS.matchframes == 500000) then
		timer:addAdaptedText(true, Tutorials.LocalizedMessages.ENDLESSMODE, nil, nil, FONTS.BIG, nil, 0.9)
	else
		timer:addCustomDisplay(true, function()
				timer:uiText(tostring(DISPLAY_FRAMES), nil, nil, FONTS.BIG, nil, 0.9)
			end)
	end
	local settings = topBar:addChild({
		pos = { -65, 20 },
		size = { 50, 50 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 10
	})
	local settingsIcon = settings:addChild({
		shift = { 5, 5 },
		bgImage = "../textures/menu/general/buttons/settingswhite.tga",
	})
	settings:addMouseHandlers(nil, function()
			toggleSettings(settingsView, settings)
		end)
	local restart = topBar:addChild({
		pos = { -125, 20 },
		size = { 50, 50 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 10
	})
	local restartIcon = restart:addChild({
		shift = { 5, 5 },
		bgImage = "../textures/menu/general/buttons/restart.tga",
	})
	restart:addMouseHandlers(nil, function()
			TBMenu:showConfirmationWindow("Are you sure you want to reset the game?", function()
					Tutorials.CurrentStep.fallback = 1
					Tutorials:reqDelay(viewElement, reqTable, 0)
				end)
		end)

	local leaveGame = false
	add_hook("end_game", Tutorials.StepHook, function(gameEndType) COMEBACKPRACTICE_GAME_END = true end)
	add_hook("draw2d", Tutorials.StepHook, function()
			checkCollision()
			local ws = UIElement.WorldState
			local frame = ws.match_frame
			DISPLAY_FRAMES = ws.game_frame - ws.match_frame
			if (DISPLAY_FRAMES < 0) then
				DISPLAY_FRAMES = 0
			end
			if ((ws.winner > -1 or COMEBACKPRACTICE_GAME_END) and not leaveGame) then
				leaveGame = true
				GAME_COUNT = (GAME_COUNT or 0) + 1
				local stopFrame = frame + 97
				local leaveGameHook = false
				add_hook("draw2d", Tutorials.StaticHook, function()
						local wsMatchFrame = UIElement.WorldState.match_frame
						if (wsMatchFrame >= stopFrame and not TUTORIAL_LEAVEGAME) then
							leaveGameHook = true
							TUTORIAL_LEAVEGAME = true
						elseif (leaveGameHook and wsMatchFrame < stopFrame and wsMatchFrame >= 1) then
							leaveGameHook = false
							TUTORIAL_LEAVEGAME = false
						end
					end)
				Tutorials:reqDelay(viewElement, reqTable, 0)
			end
		end)
end

local function comebackPractice(viewElement, reqTable)
	COMEBACKPRACTICE_GAME_END = false
	Tutorials.CurrentStep.skip = 0
	usage_event("tutorial5fight")
	setStartPose()
	initComebackPractice()
	loadVisuals(viewElement, reqTable)

	add_hook("leave_game", Tutorials.StaticHook, function()
			if (TUTORIAL_LEAVEGAME) then
				return 1
			end
		end)
	add_hook("key_up", Tutorials.StepHook, function(key)
			if (get_shift_key_state() > 0 or get_keyboard_ctrl() > 0 or get_keyboard_alt() > 0) then
				return 1
			end
	end)
end

local function setMessage()
	if (COMEBACK_SCORE == 0) then
		Tutorials:setStepMessage("SENSEIMSGFAIL")
	elseif (COMEBACK_SCORE == 1) then
		Tutorials:setStepMessage("SENSEIMSGEND1")
	elseif (COMEBACK_SCORE < 3) then
		Tutorials.LocalizedMessages.SENSEIMSGEND2 = Tutorials.LocalizedMessages.SENSEIMSGEND2:gsub("%%d", COMEBACK_SCORE)
		Tutorials:setStepMessage("SENSEIMSGEND2")
	elseif (COMEBACK_SCORE < 6) then
		Tutorials.LocalizedMessages.SENSEIMSGEND3 = Tutorials.LocalizedMessages.SENSEIMSGEND3:gsub("%%d", COMEBACK_SCORE)
		Tutorials:setStepMessage("SENSEIMSGEND3")
	else
		Tutorials.LocalizedMessages.SENSEIMSGEND4 = Tutorials.LocalizedMessages.SENSEIMSGEND4:gsub("%%d", COMEBACK_SCORE)
		Tutorials:setStepMessage("SENSEIMSGEND4")
	end
end

return {
	ComebackInit = initComebackPractice,
	PracticeCombacks = comebackPractice,
	SetMessage = setMessage,
	SetMod = restartGame
}
