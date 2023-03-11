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
					reqTable.ready = Tutorials.CheckRequirements(reqTable)
				elseif (not show) then
					req.ready = true
					reqTable.ready = Tutorials.CheckRequirements(reqTable)
				end
			end
		end)
	add_hook("key_down", "tbTutorialsCustom", function(s, code)
			if ((string.schar(s) == key or (code > 3 and code < 30 and string.schar(code + 93) == key)) and show) then
				button.hoverState = BTN_HVR
			end
		end)
end

local function requireKeyPressC(viewElement, reqTable)
	requireKeyPress(viewElement, reqTable, "c")
end

local function showKeyPressSpace(viewElement, reqTable)
	requireKeyPress(viewElement, reqTable, SPACEBAR)
end

local function requireKeyPressB(viewElement, reqTable)
	requireKeyPress(viewElement, reqTable, "b")
end

local function requireKeyPressM(viewElement, reqTable)
	MoveMemory.TutorialMode = true
	requireKeyPress(viewElement, reqTable, "m")
end

local function moveMemoryShow(viewElement, reqTable, static)
	require("system.movememory_manager")
	local moveMemoryMain = UIElement:new({
		parent = viewElement,
		pos = { 50, WIN_H / 6 },
		size = { 250, WIN_H / 3 * 2 },
		bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR_TRANS),
		shapeType = ROUNDED,
		rounded = 4,
		uiColor = { 0, 0, 0, 1 }
	})
	local moveMemoryMoverHolder = UIElement:new({
		parent = moveMemoryMain,
		pos = { 0, 0 },
		size = { moveMemoryMain.size.w, 20 },
		bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
		shapeType = moveMemoryMain.shapeType,
		rounded = moveMemoryMain.rounded
	})
	local moveMemoryMover = UIElement:new({
		parent = moveMemoryMoverHolder,
		pos = { 0, 0 },
		size = { moveMemoryMoverHolder.size.w, moveMemoryMoverHolder.size.h },
		interactive = true,
		bgColor = UICOLORWHITE,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
	})
	moveMemoryMover:addCustomDisplay(true, function()
			set_color(unpack(moveMemoryMover:getButtonColor()))
			local posX = moveMemoryMover.pos.x + moveMemoryMover.size.w / 2 - 15
			draw_quad(posX, moveMemoryMover.pos.y + 5, 30, 2)
			draw_quad(posX, moveMemoryMover.pos.y + 13, 30, 2)
		end)
	local moveMemoryHolder = UIElement:new({
		parent = moveMemoryMain,
		pos = { 0, moveMemoryMoverHolder.size.h },
		size = { moveMemoryMain.size.w, moveMemoryMain.size.h - moveMemoryMoverHolder.size.h - moveMemoryMain.rounded}
	})
	moveMemoryHolder:addCustomDisplay(true, function() end)
	local moveMemoryTitleBg = UIElement:new({
		parent = moveMemoryHolder,
		pos = { 0, 0 },
		size = { moveMemoryHolder.size.w, 40 },
		bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
		uiColor = UICOLORWHITE
	})
	if (not static) then
		moveMemoryMain.bgColor[4] = 0
		moveMemoryMain:addCustomDisplay(false, function()
				if (moveMemoryMain.bgColor[4] < 0.5) then
					moveMemoryMain.bgColor[4] = moveMemoryMain.bgColor[4] + 0.1 * FPS_MULTIPLIER
				end
			end)
		moveMemoryMoverHolder.bgColor[4] = 0
		moveMemoryTitleBg.bgColor[4] = 0
		moveMemoryTitleBg:addCustomDisplay(false, function()
				if (moveMemoryTitleBg.bgColor[4] < 1) then
					moveMemoryTitleBg.bgColor[4] = moveMemoryTitleBg.bgColor[4] + 0.1 * FPS_MULTIPLIER
				end
				if (moveMemoryMoverHolder.bgColor[4] < 1) then
					moveMemoryMoverHolder.bgColor[4] = moveMemoryMoverHolder.bgColor[4] + 0.1 * FPS_MULTIPLIER
				end
			end)
	end
	moveMemoryMoverHolder:addCustomDisplay(true, function()
			set_color(unpack(moveMemoryMoverHolder.bgColor))
			draw_disk(moveMemoryMoverHolder.pos.x + moveMemoryMain.rounded, moveMemoryMoverHolder.pos.y + moveMemoryMain.rounded, 0, moveMemoryMain.rounded, 100, 1, -180, 90, 0)
			draw_disk(moveMemoryMoverHolder.pos.x + moveMemoryMoverHolder.size.w - moveMemoryMain.rounded, moveMemoryMoverHolder.pos.y + moveMemoryMain.rounded, 0, moveMemoryMain.rounded, 100, 1, 90, 90, 0)
			draw_quad(moveMemoryMoverHolder.pos.x + moveMemoryMain.rounded, moveMemoryMoverHolder.pos.y, moveMemoryMoverHolder.size.w - moveMemoryMain.rounded * 2, moveMemoryMain.rounded)
			draw_quad(moveMemoryMoverHolder.pos.x, moveMemoryMoverHolder.pos.y + moveMemoryMain.rounded, moveMemoryMoverHolder.size.w, moveMemoryMoverHolder.size.h - moveMemoryMain.rounded)
		end)
	local moveMemoryTitle = UIElement:new({
		parent = moveMemoryTitleBg,
		pos = { 0, 0 },
		size = { moveMemoryTitleBg.size.w, moveMemoryTitleBg.size.h }
	})
	moveMemoryTitle:addAdaptedText(false, "MOVEMEMORY", -10, nil, nil, nil, nil, nil, 0)
	local moveMemoryAddMove = UIElement:new({
		parent = moveMemoryTitle,
		pos = { -30, 10 },
		size = { 20, 20 },
		interactive = true,
		bgColor = { 1, 1, 1, 0.1 },
		hoverColor = { 1, 1, 1, 0.3 },
		pressedColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	moveMemoryAddMove:addCustomDisplay(false, function()
			set_color(1, 1, 1, 0.8)
			draw_quad(	moveMemoryAddMove.pos.x + moveMemoryAddMove.size.w / 2 - 1,
						moveMemoryAddMove.pos.y + 4,
						2,
						moveMemoryAddMove.size.h - 8	)
			draw_quad(	moveMemoryAddMove.pos.x + 4,
						moveMemoryAddMove.pos.y + moveMemoryAddMove.size.h / 2 - 1,
						moveMemoryAddMove.size.w - 8,
						2	)
		end)

	local openersHolder = UIElement:new({
		parent = moveMemoryHolder,
		pos = { 0, moveMemoryTitle.size.h },
		size = { moveMemoryHolder.size.w, moveMemoryHolder.size.h - moveMemoryTitle.size.h }
	})

	-- prevent interactions
	local clickOverlay = UIElement:new({
		parent = moveMemoryMain,
		pos = { 0, 0 },
		size = { moveMemoryMain.size.w, moveMemoryMain.size.h },
		interactive = true
	})
	return openersHolder, { moveMemoryMain, moveMemoryMoverHolder, moveMemoryTitleBg }
end

local function moveMemoryAddMoves(moves)
	local storedMoves = {}
	local file = Files:open("system/movememory.mm")
	if (file.data) then
		for i, ln in pairs(file:readAll()) do
			if (ln:find("^NAME")) then
				storedMoves[#storedMoves + 1] = { name = ln:gsub("^NAME ", "") }
			end
		end
	end
	file:reopen(FILES_MODE_APPEND)
	if (not file.data) then
		return
	end
	for i,v in pairs(moves) do
		local write = true
		if (#storedMoves > 0) then
			for j, k in pairs(storedMoves) do
				if (k.name:find(v.name)) then
					write = false
					break
				end
			end
		end
		if (write) then
			file:writeLine("")
			file:writeLine("NAME " .. v.name)
			if (v.desc) then
				file:writeLine("DESC " .. v.desc)
			end
			if (v.mod) then
				file:writeLine("MOD " .. v.mod)
			end
			for j, k in pairs(v.turnsdata) do
				file:writeLine(k)
			end
		end
	end
	file:close()
end

local function moveMemoryMovesShow(viewElement, reqTable, rpt)
	local openersHolder, toAnimate = moveMemoryShow(viewElement, nil, true)
	local moves = {
		{
			name = "Noobclap",
			desc = "Simple hand clap move",
			turnsdata = {
				"TURN 1; 0 3 1 3 2 3 3 3 4 2 5 3 6 3 7 2 8 3 9 3 10 3 11 3 12 3 13 3 14 3 15 3 16 3 17 3 18 3 19 3 20 1 21 1"
			}
		},
		{
			name = "Right Uppercut",
			desc = "Two-turn punch",
			turnsdata = {
				"TURN 1; 0 3 8 4 1 3 15 3 3 3 16 3 5 4 17 3 6 2 13 3 7 3 19 3 4 3 18 3 11 3 2 3 10 3 9 2 14 3 12 3 20 0 21 0",
				"TURN 2; 0 3 8 4 1 2 15 3 3 3 16 3 5 2 17 3 6 1 13 3 7 3 19 3 4 2 18 3 11 3 2 3 10 1 9 2 14 3 12 3 20 0 21 0"
			}

		},
		{
			name = "High Kick",
			desc = "High left leg kick",
			turnsdata = {
				"TURN 1; 0 3 8 3 1 2 15 1 3 3 16 3 5 3 17 2 6 3 13 2 7 3 19 3 4 2 18 3 11 3 2 2 10 3 9 3 14 2 12 2 20 0 21 0",
				"TURN 2; 0 3 8 3 1 2 15 1 3 3 16 3 5 3 17 1 6 3 13 2 7 3 19 3 4 2 18 3 11 3 2 2 10 3 9 3 14 2 12 2 20 0 21 0"
			}
		}
	}
	MoveMemory:spawnOpeners(openersHolder, moves, 1)
	if (not rpt) then
		for i = 2, #openersHolder.child do
			local trans = 0.5
			local v = openersHolder.child[i]
			v:addCustomDisplay(false, function()
					set_color(1, 1, 1, trans)
					draw_quad(v.pos.x - (0.5 - trans) * 10, v.pos.y - (0.5 - trans) * 10, v.size.w + (0.5 - trans) * 20, v.size.h + (0.5 - trans) * 20)
					if (trans <= 0) then
						v:addCustomDisplay(false, function() end)
					end
					trans = trans - 0.02
				end)
		end
		moveMemoryAddMoves(moves)
	else
		return toAnimate
	end
end

local function moveMemoryShowExit(viewElement)
	local toAnimate = moveMemoryMovesShow(viewElement, nil, true)
	for i,v in pairs(toAnimate) do
		v:addCustomDisplay(false, function()
				if (v.bgColor[4] > 0) then
					v.bgColor[4] = v.bgColor[4] - 0.1 * FPS_MULTIPLIER
				end
			end)
	end
	toAnimate[1]:addCustomDisplay(false, function()
			if (toAnimate[1].uiColor[4] > 0) then
				toAnimate[1].uiColor[4] = toAnimate[1].uiColor[4] - 0.1 * FPS_MULTIPLIER
			else
				toAnimate[1]:kill()
			end
		end)
	MoveMemory.PlaybackActive[0] = false
	MoveMemory.PlaybackActive[1] = false
end

local function checkJointStates(viewElement, reqTable)
	local req = { type = "jointstatecheck", ready = false }
	table.insert(reqTable, req)

	local states = {}
	for i,v in pairs(JOINTS) do
		states[v] = get_joint_info(0, v).state
	end

	local checker = UIElement:new({
		parent = viewElement,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	checker:addCustomDisplay(true, function()
			for i,v in pairs(JOINTS) do
				if (get_joint_info(0, v).state ~= states[v]) then
					req.ready = true
					reqTable.ready = Tutorials.CheckRequirements(reqTable)
					checker:kill()
				end
			end
		end)
end

return {
	RequireKeyPressC = requireKeyPressC,
	RequireKeyPressB = requireKeyPressB,
	RequireKeyPressM = requireKeyPressM,
	RequireKeyPressSpace = showKeyPressSpace,
	ShowMovememory = moveMemoryShow,
	ShowMovememoryMoves = moveMemoryMovesShow,
	HideMovememoryMoves = moveMemoryShowExit,
	CheckJointStateChange = checkJointStates
}
