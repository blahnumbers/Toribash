local SPACEBAR = " "
local FPS_MULTIPLIER = get_option("framerate") == 30 and 2 or 1

local function requireKeyPress(viewElement, reqTable, key, show)
	local req = { type = "keypress", ready = false }
	table.insert(reqTable, req)

	local button = nil
	if (show) then
		local displayKey = key
		local width = 100
		if (key == SPACEBAR) then
			displayKey = "SPACEBAR"
			width = 300
		end

		button = UIElement:new({
			parent = viewElement,
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

	add_hook("key_up", "tbTutorialsCustom", function(s, code)
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
	add_hook("key_down", "tbTutorialsCustom", function(s, code)
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
		for i, state in pairs(turn) do
			turn[i - 1] = state
		end
	end
end

local function moveMemoryMovesShow()
	require("system.movememory_manager")
	MoveMemory.TutorialMode = true
	MoveMemory:showMain()
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
	MoveMemory:quit()
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

return {
	RequireKeyPressCShow = requireKeyPressCShow,
	RequireKeyPressC = requireKeyPressC,
	RequireKeyPressB = requireKeyPressB,
	RequireKeyPressMShow = requireKeyPressMShow,
	RequireKeyPressM = requireKeyPressM,
	RequireKeyPressSpaceShow = showKeyPressSpaceShow,
	RequireKeyPressSpace = showKeyPressSpace,
	ShowMovememoryMoves = moveMemoryMovesShow,
	HideMovememoryMoves = moveMemoryShowExit,
	CheckJointStateChange = checkJointStates
}
