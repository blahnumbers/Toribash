local SPACEBAR = " "

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

local function requireKeyPressCShow(viewElement, reqTable)
	requireKeyPress(viewElement, reqTable, "c", true)
end

local function requireKeyPressC(viewElement, reqTable)
	requireKeyPress(viewElement, reqTable, "c")
end

local function showKeyPressSpaceShow(viewElement, reqTable)
	requireKeyPress(viewElement, reqTable, SPACEBAR, true)
end

local function showKeyPressSpace(viewElement, reqTable)
	requireKeyPress(viewElement, reqTable, SPACEBAR)
end

local function requireKeyPressB(viewElement, reqTable)
	requireKeyPress(viewElement, reqTable, "b")
end

local function requireKeyPressMShow(viewElement, reqTable)
	MoveMemory.TutorialMode = true
	requireKeyPress(viewElement, reqTable, "m", true)
end

local function requireKeyPressM(viewElement, reqTable)
	MoveMemory.TutorialMode = true
	requireKeyPress(viewElement, reqTable, "m")
end

local memoryMoves = {
	{
		name = "Noobclap",
		desc = "Simple hand clap move",
		movements = {
			{ 3, 3, 3, 3, 2, 3, 3, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 1 }
		},
		turns = 1
	},
	{
		name = "Right Uppercut",
		desc = "Two-turn punch",
		movements = {
			{ 3, 4, 3, 3, 3, 3, 4, 3, 2, 3, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 0, 0 },
			{ 3, 4, 2, 3, 3, 3, 2, 3, 1, 3, 3, 3, 2, 3, 3, 3, 1, 2, 3, 3, 0, 0 }
		},
		turns = 2
	},
	{
		name = "High Kick",
		desc = "High left leg kick",
		movements = {
			{ 3, 3, 2, 1, 3, 3, 3, 2, 3, 2, 3, 3, 2, 3, 3, 2, 3, 3, 2, 2, 0, 0 },
			{ 3, 3, 2, 1, 3, 3, 3, 1, 3, 2, 3, 3, 2, 3, 3, 2, 3, 3, 2, 2, 0, 0 }
		},
		turns = 2
	}
}
for _, move in pairs(memoryMoves) do
	for _, turn in pairs(move.movements) do
		for i = 1, #turn do
			turn[i - 1] = turn[i]
		end
		table.remove(turn)
	end
end

local function moveMemoryMovesShow()
	require("system.movememory_manager")
	MoveMemory.TutorialMode = true
	MoveMemory:showMain()
	MoveMemory.MovesHolder:addCustomDisplay(true, nil)
	MoveMemory:spawnOpeners(MoveMemory.MovesHolder, memoryMoves)
	MoveMemory.MainElement:moveTo(SAFE_X + 10, Tutorials.TaskViewHolder.pos.y + Tutorials.TaskViewHolder.size.h + 10)
	MoveMemory.MainElement:addChild({ interactive = true })

	for _, v in pairs(memoryMoves) do
		---@type MemoryMove
		v = v
		setmetatable(v, MemoryMove)
		if (not MoveMemory:isMoveStored(v)) then
			v:writeToFile()
		end
	end
end

local function moveMemoryShowExit()
	MoveMemory.Quit()
end

local function checkJointStates(viewElement, reqTable)
	local req = { type = "jointstatecheck", ready = false }
	table.insert(reqTable, req)

	local states = {}
	for _, v in pairs(JOINTS) do
		states[v] = get_joint_info(0, v).state
	end

	local checker = UIElement:new({
		parent = viewElement,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	checker:addCustomDisplay(true, function()
			for _, v in pairs(JOINTS) do
				if (get_joint_info(0, v).state ~= states[v]) then
					req.ready = true
					reqTable.ready = Tutorials:checkRequirements(reqTable)
					checker:kill()
				end
			end
		end)
end

---@param viewElement UIElement
local function waitRelaxAll(viewElement, reqTable)
	local req = { type = "waitrelaxall", ready = false }
	table.insert(reqTable, req)

	local buttonIndicator = viewElement:addChild({
		pos = { TBHud.HoldAllButtonHolder.pos.x, TBHud.HoldAllButtonHolder.pos.y },
		size = { TBHud.HoldAllButtonHolder.size.w / 2, TBHud.HoldAllButtonHolder.size.h / 2 }
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
			draw_disk(buttonIndicator.pos.x + buttonIndicator.size.w, buttonIndicator.pos.y + buttonIndicator.size.h, buttonIndicator.size.w, buttonIndicator.size.w + grow, 0, 1, 0, 360, 0)
		end)
end

---@param viewElement UIElement
---@param onSelect function
local function displayMobileHubMovememory(viewElement, onSelect)
	local uiOverlay = viewElement:addChild({
		interactive = true
	})
	local hubBackground = uiOverlay:addChild({
		pos = { uiOverlay.size.w, 0 },
		size = { TBHud.HubSize.w + SAFE_X, viewElement.size.h },
		bgColor = { 1, 1, 1, 0.7 }
	})
	local buttonSize = (TBHud.HubSize.w - 20) / 4
	local moveMemoryButton = hubBackground:addChild({
		pos = { 10, math.max(SAFE_Y, 20) },
		size = { buttonSize, buttonSize },
		bgImage = "../textures/menu/button_backdrop.tga",
		imageColor = TB_MENU_DEFAULT_BG_COLOR,
		imageHoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
		imagePressedColor = TB_MENU_DEFAULT_DARKER_ORANGE,
		interactive = true
	})
	moveMemoryButton:addMouseUpHandler(function()
			if (MoveMemory.MainElement == nil) then
				MoveMemory:showMain()
			else
				MoveMemory.Quit()
			end
			onSelect()
		end)
		moveMemoryButton:addChild({
		pos = { 10, 2 },
		size = { moveMemoryButton.size.w - 20, moveMemoryButton.size.h - 20 },
		bgImage = "../textures/menu/general/movememory_icon.tga"
	})
	local buttonTitleHolder = moveMemoryButton:addChild({
		pos = { 0, -30 },
		size = { moveMemoryButton.size.w, 30 },
		bgColor = moveMemoryButton.imageAnimateColor,
		shapeType = ROUNDED,
		rounded = { 0, 5 }
	})
	buttonTitleHolder:addChild({ shift = { 5, 2 }}):addAdaptedText(TB_MENU_LOCALIZED.MOVEMEMORYTITLE)


	local clock = UIElement.clock
	hubBackground:addCustomDisplay(true, function()
		local tweenValue = (UIElement.clock - clock) * 6
		hubBackground:moveTo(UITween.SineTween(hubBackground.shift.x, uiOverlay.size.w - hubBackground.size.w, tweenValue))
		if (tweenValue >= 1) then
			hubBackground:addCustomDisplay(function() end)
		end
	end)

	local buttonExit = hubBackground:addChild({
		pos = { 10, -50 - math.max(SAFE_Y, 20) },
		size = { hubBackground.size.w - 20, 50 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 5
	})
	buttonExit:addChild({ shift = { 10, 5 }}):addAdaptedText("> " .. TB_MENU_LOCALIZED.MOBILEHUDTOMAINMENU)
	buttonExit:addMouseUpHandler(function() open_menu(19) end)
end

local function waitMovememory(viewElement, reqTable, isExit)
	local req = { type = "waitmovememory", ready = false }
	table.insert(reqTable, req)

	local completeRequirement = function()
		TBHud.SetTutorialHubOverride(nil)
		MoveMemory.RemoveOnOpenedEvent("tutorial3movememory")
		MoveMemory.RemoveOnClosedEvent("tutorial3movememory")

		req.ready = true
		reqTable.ready = Tutorials:checkRequirements(reqTable)
	end

	TBHud.SetTutorialHubOverride(function()
		displayMobileHubMovememory(viewElement, completeRequirement)
	end)
	local radius = TBHud.HubButtonHolder.size.w / 2
	local buttonIndicator = viewElement:addChild({
		pos = { TBHud.HubButtonHolder.pos.x + radius, TBHud.HubButtonHolder.pos.y + radius },
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

	if (isExit) then
		MoveMemory:toggleTutorialQuit(true)
		MoveMemory.AddOnClosedEvent("tutorial3movememory", completeRequirement)
	else
		MoveMemory.AddOnOpenedEvent("tutorial3movememory", completeRequirement)
	end
end

local function waitMovememoryExit(viewElement, reqTable)
	waitMovememory(viewElement, reqTable, true)
end

local function waitStep(viewElement, reqTable)
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

local function moveMessageView()
	Tutorials.MessageView.t3Mover = Tutorials.MessageView:addChild({})
	Tutorials.MessageView.t3MoverInitialPos = Tutorials.MessageView.shift.y
	local spawnTime = UIElement.clock
	Tutorials.MessageView.t3Mover:addCustomDisplay(true, function()
			local ratio = UIElement.clock - spawnTime
			Tutorials.MessageView:moveTo(nil, UITween.SineTween(Tutorials.MessageView.shift.y, Tutorials.MessageView.t3MoverInitialPos - TBHud.HoldAllButtonHolder.size.h, ratio))
			if (ratio >= 1) then
				Tutorials.MessageView.t3Mover:kill()
			end
		end)
end

local function moveMessageViewBack()
	Tutorials.MessageView.t3Mover = Tutorials.MessageView:addChild({})
	Tutorials.MessageView.t3MoverInitialPos = Tutorials.MessageView.t3MoverInitialPos or Tutorials.MessageView.shift.y + TBHud.HoldAllButtonHolder.size.h
	local spawnTime = UIElement.clock
	Tutorials.MessageView.t3Mover:addCustomDisplay(true, function()
			local ratio = UIElement.clock - spawnTime
			Tutorials.MessageView:moveTo(nil, UITween.SineTween(Tutorials.MessageView.shift.y, Tutorials.MessageView.t3MoverInitialPos, ratio))
			if (ratio == 1) then
				Tutorials.MessageView.t3Mover:kill()
			end
		end)
end

return {
	RequireKeyPressCShow = is_mobile() and waitRelaxAll or requireKeyPressCShow,
	RequireKeyPressC = is_mobile() and waitRelaxAll or requireKeyPressC,
	RequireKeyPressMShow = is_mobile() and waitMovememory or requireKeyPressMShow,
	RequireKeyPressM = is_mobile() and waitMovememoryExit or requireKeyPressM,
	RequireKeyPressSpaceShow = is_mobile() and waitStep or showKeyPressSpaceShow,
	RequireKeyPressSpace = is_mobile() and waitStep or showKeyPressSpace,
	ShowMovememoryMoves = moveMemoryMovesShow,
	HideMovememoryMoves = moveMemoryShowExit,
	CheckJointStateChange = checkJointStates,
	MoveMessageViewMobile = is_mobile() and moveMessageView or function() end,
	MoveMessageViewMobileBack = is_mobile() and moveMessageViewBack or function() end
}
