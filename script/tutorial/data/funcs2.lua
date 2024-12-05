local SPACEBAR = " "
local FPS_MULTIPLIER = get_option("framerate") == 30 and 2 or 1

local function requireKeyPress(viewElement, reqTable, key, show)
	local req = { type = "keypress", ready = false }
	table.insert(reqTable, req)

	local button
	if (show) then
		local displayKey = key
		local width = 100
		if (key == SPACEBAR) then
			displayKey = "SPACEBAR"
			width = 300
		end

		button = viewElement:addChild({
			pos = { 250 - width / 2, -200 },
			size = { width, 70 },
			interactive = true,
			bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
			hoverColor = table.clone(TB_MENU_DEFAULT_LIGHTEST_COLOR),
			shapeType = ROUNDED,
			rounded = 10
		})
		button:deactivate()
		button.isactive = true
		button:addAdaptedText(false, displayKey)
	end

	add_hook("key_up", Tutorials.StepHook, function(s, code)
			if (string.schar(s) == key or (code > 3 and code < 30 and string.schar(code + 93) == key)) then
				if (show and button.hoverState ~= BTN_NONE) then
					button.hoverState = BTN_NONE
					req.ready = true
					reqTable.ready = Tutorials:checkRequirements(reqTable)
				elseif (not show) then
					req.ready = true
					reqTable.ready = Tutorials:checkRequirements(reqTable)
				end
			end
		end)
	add_hook("key_down", Tutorials.StepHook, function(s, code)
			if ((string.schar(s) == key or (code > 3 and code < 30 and string.schar(code + 93) == key)) and show) then
				button.hoverState = BTN_HVR
			end
		end)
end

local function requireKeyPressC(viewElement, reqTable)
	if (not is_mobile()) then
		requireKeyPress(viewElement, reqTable, "c", true)
		return
	end

	local req = { type = "keypress", ready = false }
	table.insert(reqTable, req)

	local holdAllButton = viewElement:addChild({
		pos = { TBHud.HoldAllButtonHolder.shift.x, TBHud.HoldAllButtonHolder.shift.y },
		size = { TBHud.HoldAllButtonHolder.size.w, TBHud.HoldAllButtonHolder.size.h },
		interactive = true,
		clickThrough = true
	})

	local commitButtonDisplayOverride = nil
	if (not TBHud.CommitStepButtonHolder:isDisplayed()) then
		TBHud.CommitStepButtonHolder:show(true)
		commitButtonDisplayOverride = viewElement:addChild({
			pos = { TBHud.CommitStepButtonHolder.shift.x, TBHud.CommitStepButtonHolder.shift.y },
			size = { TBHud.CommitStepButtonHolder.size.w, TBHud.CommitStepButtonHolder.size.h },
			interactive = true
		})
	end
	holdAllButton:addMouseUpHandler(function()
		req.ready = true
		reqTable.ready = Tutorials:checkRequirements(reqTable)
		if (commitButtonDisplayOverride) then
			commitButtonDisplayOverride:kill()
			TBHud.CommitStepButtonHolder:hide(true)
		end
	end)
end

local function showKeyPressSpace(viewElement, reqTable)
	if (not is_mobile()) then
		requireKeyPress(viewElement, reqTable, SPACEBAR, true)
		return
	end

	local req = { type = "keypress", ready = false }
	table.insert(reqTable, req)

	local commitButton = viewElement:addChild({
		pos = { TBHud.CommitStepButtonHolder.shift.x, TBHud.CommitStepButtonHolder.shift.y },
		size = { TBHud.CommitStepButtonHolder.size.w, TBHud.CommitStepButtonHolder.size.h },
		interactive = true
	})
	commitButton:addMouseUpHandler(function()
		step_game()
		req.ready = true
		reqTable.ready = Tutorials:checkRequirements(reqTable)
	end)
end

local function punchingBag()
	usage_event("tutorial2lockbag")
	local groinPos = get_body_info(1, BODYPARTS.GROIN).pos
	add_hook("enter_frame", Tutorials.StaticHook, function()
			set_body_pos(1, BODYPARTS.GROIN, groinPos.x, groinPos.y, groinPos.z)
			set_body_rotation(1, BODYPARTS.GROIN, 0, 0, 0)
		end)

	if (is_mobile()) then
		TBHud.ToggleReadyLongPress(true)
	end
end

local function showDamageBar()
	local textColor = table.clone(UICOLORTORI)
	textColor[4] = 0
	t2DamageMeter = Tutorials.MainView:addChild({
		pos = { -440 - math.max(SAFE_X, 10), 7 },
		size = { 440, 40 },
		bgColor = textColor
	})
	local transparencyAnimation = UIElement:new({
		parent = t2DamageMeter,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	transparencyAnimation:addCustomDisplay(true, function()
			textColor[4] = textColor[4] + 0.04 * FPS_MULTIPLIER
			if (textColor[4] >= 1) then
				textColor[4] = 1
				transparencyAnimation:kill()
			end
		end)
	t2DamageMeter:addCustomDisplay(true, function()
			local damage = math.ceil(get_player_info(1).injury)
			t2DamageMeter:uiText(tostring(damage), nil, nil, FONTS.BIG, RIGHTMID, 1, nil, nil, textColor, nil, 0)
			t2DamageMeter:uiText(TB_MENU_PLAYER_INFO.username or "Damage", nil, 35, nil, RIGHTMID, 1, nil, nil, textColor, nil, 0)
		end)
end

local function showTimer()
	local start_frame = get_world_state().match_frame
	local textColor = table.clone(UICOLORTORI)
	textColor[4] = 0

	t2Timer = Tutorials.MainView:addChild({
		pos = { 0, 0 },
		size = { Tutorials.MainView.size.w, 90 },
		bgColor = textColor
	})
	transparencyAnimation = UIElement:new({
		parent = t2DamageMeter,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	transparencyAnimation:addCustomDisplay(true, function()
			t2Timer.bgColor[4] = t2Timer.bgColor[4] + 0.04 * FPS_MULTIPLIER
			if (t2Timer.bgColor[4] >= 1) then
				t2Timer.bgColor = t2DamageMeter.bgColor
				transparencyAnimation:kill()
			end
		end)
	t2Timer:addCustomDisplay(true, function()
			local current_frame = Tutorials.WorldState.match_frame
			local frame = 500 - (current_frame - start_frame)

			set_color(1, (500 - (current_frame - start_frame)) / 650, 0, t2Timer.bgColor[4] / 3)
			draw_disk(t2Timer.pos.x + t2Timer.size.w / 2, t2Timer.pos.y + t2Timer.size.h / 2 + 3, t2Timer.size.h / 10, t2Timer.size.h / 2 - 5, 500, 1, 180 + (current_frame - start_frame) / 50 * 36, (500 - (current_frame - start_frame)) / 50 * 36, 0)
			t2Timer:uiText(tostring(frame < 0 and 0 or frame), nil, nil, FONTS.BIG, nil, 1, nil, 1, { 1, 0.8, 0, 1 }, { 1, 1, 1, 0.4 }, 0)
		end)
end

local function hideDamageAndTimerBars(viewElement, reqTable)
	local req = { type = "animationOutro", ready = false }
	table.insert(reqTable, req)

	local transparencyAnimation = UIElement:new({
		parent = t2DamageMeter,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	transparencyAnimation:addCustomDisplay(true, function()
			t2DamageMeter.bgColor[4] = t2DamageMeter.bgColor[4] - 0.04 * FPS_MULTIPLIER
			if (t2DamageMeter.bgColor[4] <= 0) then
				t2DamageMeter:kill()
				t2Timer:kill()
				req.ready = true
				reqTable.ready = Tutorials:checkRequirements(reqTable)
			end
		end)
end

local function showDamageAndTimerBars()
	showTimer()
	showDamageBar()
end

local function unloadStaticHook(viewElement, reqTable)
	remove_hooks(Tutorials.StaticHook)
	hideDamageAndTimerBars(viewElement, reqTable)
end

local function unloadStaticHookWithAchievement(viewElement, reqTable)
	usage_event("tutorial2achievement")
	unloadStaticHook(viewElement, reqTable)
	---@diagnostic disable-next-line: undefined-global
	award_achievement(788)
end

local function showWaitButtonMisc(viewElement, reqTable)
	if (not is_mobile()) then
		Tutorials:reqButton(reqTable)
		return
	end

	---@type TutorialStepRequirement
	local req = { type = "custom", ready = false }
	table.insert(reqTable, req)

	local miniWaitButton = viewElement:addChild({
		pos = { -TBHud.DefaultButtonSize * 2.05, -TBHud.DefaultSmallerButtonSize * 3.15 },
		size = { TBHud.DefaultSmallerButtonSize, TBHud.DefaultSmallerButtonSize },
		shapeType = Tutorials.ContinueButton.shapeType,
		rounded = Tutorials.ContinueButton.rounded,
		bgColor = Tutorials.ContinueButton.bgColor,
		hoverColor = Tutorials.ContinueButton.hoverColor,
		pressedColor = Tutorials.ContinueButton.pressedColor,
		inactiveColor = Tutorials.ContinueButton.inactiveColor,
		interactive = true,
		hoverSound = Tutorials.ContinueButton.hoverSound
	})
	local buttonPulse = miniWaitButton:addChild({
		pos = { miniWaitButton.size.w / 2, miniWaitButton.size.h / 2 },
		size = { miniWaitButton.size.w / 2, miniWaitButton.size.h / 2 },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	local pulseClock = 0
	buttonPulse:addCustomDisplay(true, function()
			if (pulseClock == 0) then
				pulseClock = UIElement.clock + 0.2
			end
			local pulseRatio = UITween.SineEaseOut(UIElement.clock - pulseClock)
			local r, g, b, a = unpack(buttonPulse.bgColor)
			set_color(r, g, b, a - pulseRatio)
			draw_disk(buttonPulse.pos.x, buttonPulse.pos.y, buttonPulse.size.w, buttonPulse.size.w * (1 + pulseRatio / 2), 50, 1, 0, 360, 0)
			if (pulseRatio == 1) then
				pulseClock = UIElement.clock + 0.2
			end
		end)
	miniWaitButton:addChild({
		shift = { miniWaitButton.size.w / 6, miniWaitButton.size.w / 6 },
		bgImage = "../textures/menu/general/buttons/playpause.tga",
		imageAtlas = true,
		atlas = { x = 0, y = 0, w = 128, h = 128 }
	})
	miniWaitButton:addMouseUpHandler(function()
		req.ready = true
		reqTable.ready = Tutorials:checkRequirements(reqTable)
	end)
end

return {
	RequireKeyPressC = requireKeyPressC,
	RequireKeyPressSpace = showKeyPressSpace,
	LockPunchingBag = punchingBag,
	ClearStaticHooks = unloadStaticHook,
	ClearStaticHooksAch = unloadStaticHookWithAchievement,
	ShowDamageBar = showDamageBar,
	ShowTimer = showTimer,
	ShowDamageAndTimer = showDamageAndTimerBars,
	HideDamageTimer = hideDamageAndTimerBars,
	WaitButtonMini = showWaitButtonMisc
}
