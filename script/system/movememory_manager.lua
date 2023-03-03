---@class MemoryMove
---@field id integer
---@field name string
---@field desc string
---@field mod string
---@field turns integer
---@field movements integer[][]

if (MoveMemory == nil) then
	local x, y, w, h = get_window_safe_size()
	x = math.max(x, WIN_W - x - w)
	y = math.max(y, WIN_H - y - h)

	---**MoveMemory manager class**
	---
	---**Version 5.60**
	---* Documentation with EmmyLua annotations
	---* Updated internals and visuals to match modern guidelines
	---@class MoveMemory
	---@field MainElement UIElement
	---@field Toolbar UIElement[]
	---@field Storage MemoryMove[]
	---@field PlaybackActive boolean[]
	---@field TutorialMode boolean
	---@field LastPage integer
	MoveMemory = {
		DisplayPos = { x = x + 10, y = y + 10 },
		PlaybackActive = {},
		FirstTurn = false,
		Storage = {},
		StoragePopulated = false,
		TutorialMode = false,
		ver = 5.60
	}
	setmetatable({}, MoveMemory)
end

---Helper class for **MoveMemory** manager
---@class MoveMemoryInternal
local MoveMemoryInternal = {}
setmetatable({}, MoveMemoryInternal)

---Move class for **MoveMemory** manager
---@class MemoryMove
MemoryMove = {}
MemoryMove.__index = MemoryMove

---Exits MoveMemory and destroys main holder
function MoveMemory:quit()
	if (self.MainElement ~= nil) then
		self.MainElement:kill()
		self.MainElement = nil
	end
end

---In the earlier versions of MoveMemory we used a different datafile. \
---Check if it exists and migrate data to the new one if needed.
---@return boolean
function MoveMemoryInternal.checkLegacyCache()
	local file = Files:open("system/data.mm")
	local newfile = Files:open("system/movememory.mm", FILES_MODE_WRITE)
	if (not file.data or not newfile.data) then
		file:close()
		newfile:close()
		return false
	end
	local fileData = file:readAll()
	file:close()

	for _, v in pairs(fileData) do
		newfile:writeLine(v)
	end
	newfile:close()
	return true
end

---Reads the data file and populates moves list
---@return boolean
function MoveMemory:getOpeners()
	self.Storage = {}
	self.StoragePopulated = false

	local file = Files:open("system/movememory.mm", FILES_MODE_READONLY)
	if (not file.data) then
		if (not is_mobile()) then
			if (pcall(MoveMemoryInternal.checkLegacyCache) == false) then
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MOVEMEMORYLOADERROR)
				return self.StoragePopulated
			end
			file = Files:open("system/movememory.mm", FILES_MODE_READONLY)
		end
		if (not file.data) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MOVEMEMORYLOADERROR)
			return self.StoragePopulated
		end
	end
	local fileData = file:readAll()
	file:close()

	for _, line in pairs(fileData) do
		pcall(function()
			local line = line:gsub("[\n]?$", "")
			if (line:find("^NAME")) then
				MoveMemory.Storage[#MoveMemory.Storage + 1] = {
					id = #MoveMemory.Storage + 1,
					name = line:gsub("^NAME ", "")
				}
				setmetatable(MoveMemory.Storage[#MoveMemory.Storage], MemoryMove)
			elseif (#MoveMemory.Storage > 0) then
				if (line:find("^DESC")) then
					MoveMemory.Storage[#MoveMemory.Storage].desc = line:gsub("^DESC ", "")
				elseif (line:find("^MOD")) then
					MoveMemory.Storage[#MoveMemory.Storage].mod = line:gsub("^MOD ", ""):gsub("%.tbm$", "")
				elseif (line:find("^TURN")) then
					if (not MoveMemory.Storage[#MoveMemory.Storage].movements) then
						MoveMemory.Storage[#MoveMemory.Storage].movements = {}
					end
					line = line:gsub("^TURN ", "")
					local min, max = line:find("^%d+;")
					local turn = tonumber(line:sub(min, max - 1))
					if (turn ~= nil) then
						MoveMemory.Storage[#MoveMemory.Storage].movements[turn] = {}
						if (not MoveMemory.Storage[#MoveMemory.Storage].turns) then
							MoveMemory.Storage[#MoveMemory.Storage].turns = turn
						elseif (MoveMemory.Storage[#MoveMemory.Storage].turns < turn) then
							MoveMemory.Storage[#MoveMemory.Storage].turns = turn
						end

						line = line:gsub("^%d+; ", "")
						local _, count = line:gsub("%d+", "")
						local data_stream = { line:match(("(%d+ %d+) *"):rep(count / 2)) }
						for _, v in pairs(data_stream) do
							local info = { v:match(("(%d+) *"):rep(2)) }
							MoveMemory.Storage[#MoveMemory.Storage].movements[turn][tonumber(info[1])] = tonumber(info[2])
						end
					end
				end
			end
		end)
	end

	self.StoragePopulated = true
	return self.StoragePopulated
end

---Checks whether a move with same data is defined in datafile
---@param moveData MemoryMove
---@return boolean
function MoveMemory:isMoveStored(moveData)
	if (not self.StoragePopulated) then
		if (not self:getOpeners()) then
			return false
		end
	end

	for _,v in ipairs(self.Storage) do
		if (v.name == moveData.name and v.mod == moveData.mod and v.turns == moveData.turns) then
			---Do we want to run a full check including actual movements? Probably not
			return true
		end
	end

	return false
end

---Writes move data to the datafile
---@param fileInterface ?File
function MemoryMove:writeToFile(fileInterface)
	if (utf8.len(self.name) == 0) then
		return
	end

	local file = fileInterface or Files:open("system/movememory.mm", FILES_MODE_APPEND)
	if (not file.data) then
		return
	end

	file:writeLine("")
	file:writeLine("NAME " .. self.name)
	if (self.desc) then
		file:writeLine("DESC " .. self.desc)
	end
	if (self.mod) then
		file:writeLine("MOD " .. self.mod)
	end
	for i, turn in pairs(self.movements) do
		local line = "TURN " .. i .. "; "
		for joint, state in pairs(turn) do
			line = line .. joint .. " " .. state .. " "
		end
		file:writeLine(line)
	end
	if (fileInterface == nil) then
		file:close()
	end
end

function MoveMemory:showSaveRecordingComplete(successAction, discard)
	local overlay = TBMenu:spawnWindowOverlay()
	local function quitMoveSave()
		overlay:kill()
	end

	local moveSave = UIElement:new({
		parent = overlay,
		pos = { WIN_W / 4, WIN_H / 2 - 140 },
		size = { WIN_W / 2, 280 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	local moveSaveTitle = UIElement:new({
		parent = moveSave,
		pos = { 10, 0 },
		size = { moveSave.size.w - 20, 50 }
	})
	moveSaveTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MOVEMEMORYSAVING, nil, nil, FONTS.BIG, nil, 0.65)
	local moveSaveButton = UIElement:new({
		parent = moveSave,
		pos = { moveSave.size.w / 2 + 5, -50 },
		size = { moveSave.size.w / 2 - 15, 40 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	moveSaveButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSAVE)

	local moveCancelButton = UIElement:new({
		parent = moveSave,
		pos = { 10, -50 },
		size = { moveSave.size.w / 2 - 15, 40 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	moveCancelButton:addAdaptedText(false, discard and TB_MENU_LOCALIZED.BUTTONDISCARD or TB_MENU_LOCALIZED.BUTTONCANCEL)
	moveCancelButton:addMouseHandlers(nil, function()
			quitMoveSave()
			if (discard) then
				successAction()
			end
		end)
	local moveNameBackground = UIElement:new({
		parent = moveSave,
		pos = { 10, moveSaveTitle.shift.y + moveSaveTitle.size.h + 10 },
		size = { moveSave.size.w - 20, 40 },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	local moveNameOverlay = UIElement:new({
		parent = moveNameBackground,
		pos = { 1, 1 },
		size = { moveNameBackground.size.w - 2, moveNameBackground.size.h - 2 },
		bgColor = { 1, 1, 1, 0.6 }
	})
	local moveNameInput = UIElement:new({
		parent = moveNameOverlay,
		pos = { 10, 0 },
		size = { moveNameOverlay.size.w - 20, moveNameOverlay.size.h },
		interactive = true,
		textfield = true,
		textfieldsingleline = true
	})
	TBMenu:displayTextfield(moveNameInput, FONTS.SMALL, 1, UICOLORBLACK, TB_MENU_LOCALIZED.MOVEMEMORYENTERMOVENAME, CENTERMID)
	moveNameInput:addMouseHandlers(nil, function() moveNameInput:enableMenuKeyboard() end)

	local moveDescBackground = UIElement:new({
		parent = moveSave,
		pos = { 10, moveNameBackground.shift.y + moveNameBackground.size.h + 10 },
		size = { moveSave.size.w - 20, 40 },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	local moveDescOverlay = UIElement:new({
		parent = moveDescBackground,
		pos = { 1, 1 },
		size = { moveDescBackground.size.w - 2, moveDescBackground.size.h - 2 },
		bgColor = { 1, 1, 1, 0.6 }
	})
	local moveDescInput = UIElement:new({
		parent = moveDescOverlay,
		pos = { 10, 0 },
		size = { moveDescOverlay.size.w - 20, moveDescOverlay.size.h },
		interactive = true,
		textfield = true,
		textfieldsingleline = true
	})
	TBMenu:displayTextfield(moveDescInput, FONTS.SMALL, 1, UICOLORBLACK, TB_MENU_LOCALIZED.MOVEMEMORYENTERMOVEDESCOPT, CENTERMID)
	moveDescInput:addMouseHandlers(nil, function() moveDescInput:enableMenuKeyboard() end)

	local moveModBackground = UIElement:new({
		parent = moveSave,
		pos = { 10, moveDescBackground.shift.y + moveDescBackground.size.h + 10 },
		size = { moveSave.size.w - 20, 40 },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	local moveModOverlay = UIElement:new({
		parent = moveModBackground,
		pos = { 1, 1 },
		size = { moveModBackground.size.w - 2, moveModBackground.size.h - 2 },
		bgColor = { 1, 1, 1, 0.6 }
	})
	local moveModInput = UIElement:new({
		parent = moveModOverlay,
		pos = { 10, 0 },
		size = { moveModOverlay.size.w - 20, moveModOverlay.size.h },
		interactive = true,
		textfield = true,
		textfieldsingleline = true,
		textfieldstr = { get_game_rules().mod:gsub("%.tbm$", "") }
	})
	TBMenu:displayTextfield(moveModInput, FONTS.SMALL, 1, UICOLORBLACK, TB_MENU_LOCALIZED.MOVEMEMORYENTERMODNAMEOPT, CENTERMID)
	moveModInput:addMouseHandlers(nil, function() moveModInput:enableMenuKeyboard() end)

	local function saveMove(name, description, mod)
		if (name:len() == 0) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MOVEMEMORYMODNAMEEMPTYERROR)
			return
		end
		local file = Files:open("system/movememory.mm", FILES_MODE_APPEND)
		if (not file.data) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MOVEMEMORYMOVESAVEERRORPERMS)
			return
		end
		file:writeLine("")
		file:writeLine("NAME " .. name)
		if (description:len() > 0) then
			file:writeLine("DESC " .. description)
		end
		if (mod:len() > 0) then
			file:writeLine("MOD " .. mod)
		end
		for i,v in pairs(MOVEMEMORY_MOVE_RECORD) do
			local line = "TURN " .. i .. "; "
			for j, k in pairs(v) do
				line = line .. k.joint .. " " .. k.state .. " "
			end
			file:writeLine(line)
		end
		file:close()
		quitMoveSave()
		successAction()
		MoveMemory:reload()
	end

	moveSaveButton:addMouseHandlers(nil, function() saveMove(moveNameInput.textfieldstr[1], moveDescInput.textfieldstr[1], moveModInput.textfieldstr[1]) end)
end

function MoveMemory:recordMove()
	local ws = get_world_state()
	local player = ws.selected_player
	if (player < 0) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MOVEMEMORYERRORNOTINGAME)
		return false
	end
	if (MoveMemory.PlaybackActive[player]) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MOVEMEMORYERRORSTOPMOVE)
		return false
	end
	local turn = ws.match_turn + 1
	MOVEMEMORY_MOVE_RECORD = {}

	local function cancelRecording()
		remove_hooks("tbMoveMemoryRecordMove")
		if (MoveMemory.Toolbar[0]) then
			MoveMemory.Toolbar[0]:kill()
			MoveMemory.Toolbar[0] = nil
		end
	end
	local function saveRecording(exitAction, discard)
		MoveMemory:showSaveRecordingComplete(exitAction, discard)
	end
	MoveMemory:showToolbar(player, TB_MENU_LOCALIZED.MOVEMEMORYRECORDINGMOVE .. " #" .. turn .. " (" .. #MOVEMEMORY_MOVE_RECORD .. " " .. TB_MENU_LOCALIZED.WORDTOTAL .. ")", cancelRecording, saveRecording)
	add_hook("exit_freeze", "tbMoveMemoryRecordMove", function()
			MOVEMEMORY_MOVE_RECORD[#MOVEMEMORY_MOVE_RECORD + 1] = {}
			for i,v in pairs(JOINTS) do
				table.insert(MOVEMEMORY_MOVE_RECORD[#MOVEMEMORY_MOVE_RECORD], { joint = v, state = get_joint_info(player, v).state })
			end
			table.insert(MOVEMEMORY_MOVE_RECORD[#MOVEMEMORY_MOVE_RECORD], { joint = 20, state = get_grip_info(player, 11) })
			table.insert(MOVEMEMORY_MOVE_RECORD[#MOVEMEMORY_MOVE_RECORD], { joint = 21, state = get_grip_info(player, 12) })
			MoveMemory:showToolbar(player, TB_MENU_LOCALIZED.MOVEMEMORYRECORDINGMOVE .. " #" .. get_world_state().match_turn + 2 .. " (" .. #MOVEMEMORY_MOVE_RECORD .. " " .. TB_MENU_LOCALIZED.WORDTOTAL .. ")", cancelRecording, saveRecording)
		end)
	add_hook("leave_game", "tbMoveMemoryRecordMove", function() if (not ESC_KEY_PRESSED) then if (#MOVEMEMORY_MOVE_RECORD > 0) then saveRecording(cancelRecording, true) else cancelRecording() end end end)
end

---Deletes a move from the data file
---@param memorymove MemoryMove
---@return boolean
function MoveMemory:deleteMove(memorymove)
	for i, move in ipairs(self.Storage) do
		if (memorymove.id == move.id and memorymove.name == move.name) then
			table.remove(self.Storage, i)
			break
		end
	end

	local file = Files:open("system/movememory.mm", FILES_MODE_WRITE)
	if (not file.data) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MOVEMEMORYERRORUPDATINGDATA)
		return false
	end

	for _, v in ipairs(self.Storage) do
		v:writeToFile(file)
	end
	file:close()
	return true
end

---Reloads MoveMemory window
function MoveMemory:reload()
	MoveMemory:quit()
	MoveMemory:showMain()
end

---Displays MoveMemory main window
function MoveMemory:showMain()
	echo("Echo showing main")
	local status, error = pcall(function() MoveMemory:getOpeners() end)
	if (not status) then
		echo("Error getting openers")
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.WORDERROR .. " " .. error)
		return
	end
	if (not MoveMemory.StoragePopulated) then
		echo("Not populated, exiting")
		return
	end

	local winWidth = 300 > WIN_W / 3 and WIN_W / 3 or 300
	MoveMemory.MainElement = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { MoveMemory.DisplayPos.x, MoveMemory.DisplayPos.y },
		size = { winWidth, WIN_H / 4 * 3 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		shapeType = ROUNDED,
		rounded = 4,
		uiColor = { 0, 0, 0, 1 }
	})
	MoveMemory.MainElement.pos = MoveMemory.DisplayPos
	local moveMemoryMoverHolder = MoveMemory.MainElement:addChild({
		size = { MoveMemory.MainElement.size.w, 20 },
		rounded = { 4, 0 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	}, true)
	local moveMemoryMover = moveMemoryMoverHolder:addChild({
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
	if (not MoveMemory.TutorialMode) then
		moveMemoryMover:addMouseHandlers(function(s, x, y)
					moveMemoryMover.pressedPos.x = x - moveMemoryMover.pos.x
					moveMemoryMover.pressedPos.y = y - moveMemoryMover.pos.y
				end, nil, function(x, y)
				if (moveMemoryMover.hoverState == BTN_DN) then
					local x = x - moveMemoryMover.pressedPos.x
					local y = y - moveMemoryMover.pressedPos.y
					x = x < 0 and 0 or (x + MoveMemory.MainElement.size.w > WIN_W and WIN_W - MoveMemory.MainElement.size.w or x)
					y = y < 0 and 0 or (y + MoveMemory.MainElement.size.h > WIN_H and WIN_H - MoveMemory.MainElement.size.h or y)
					MoveMemory.MainElement:moveTo(x, y)
				end
			end)
	end
	local moveMemoryHolder = MoveMemory.MainElement:addChild({
		pos = { 0, moveMemoryMoverHolder.size.h },
		size = { MoveMemory.MainElement.size.w, MoveMemory.MainElement.size.h - moveMemoryMoverHolder.size.h - MoveMemory.MainElement.rounded }
	})
	local moveMemoryTitle = UIElement:new({
		parent = moveMemoryHolder,
		pos = { 0, 0 },
		size = { moveMemoryHolder.size.w, 40 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		uiColor = UICOLORWHITE
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
	if (not MoveMemory.TutorialMode) then
		moveMemoryAddMove:addMouseHandlers(nil, function()
				MoveMemory:recordMove()
			end)
	end
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


	if (#MoveMemory.Storage == 0) then
		moveMemoryHolder:addAdaptedText(true, TB_MENU_LOCALIZED.MOVEMEMORYNOMOVESFOUND, nil, nil, nil, nil, nil, nil, 0)
		return
	end
	local featuredHolder = moveMemoryHolder:addChild({
		pos = { 0, moveMemoryTitle.size.h },
		size = { moveMemoryHolder.size.w, 110 }
	})
	local memoryOpeners = {}
	local suggested = MoveMemory:spawnSuggested(featuredHolder)
	if (not suggested) then
		featuredHolder:kill()
		---@diagnostic disable-next-line: cast-local-type
		featuredHolder = nil
		for _, v in pairs(MoveMemory.Storage) do
			table.insert(memoryOpeners, v)
		end
	else
		for _, v in pairs(MoveMemory.Storage) do
			local skip = false
			for _, k in pairs(suggested) do
				if (v.id == k.id) then
					skip = true
				end
			end
			if (not skip) then
				table.insert(memoryOpeners, v)
			end
		end
	end
	local openersHolder = UIElement:new({
		parent = moveMemoryHolder,
		pos = { 0, featuredHolder and featuredHolder.shift.y + featuredHolder.size.h or moveMemoryTitle.size.h },
		size = { moveMemoryHolder.size.w, featuredHolder and moveMemoryHolder.size.h - featuredHolder.size.h - featuredHolder.shift.y or moveMemoryHolder.size.h - moveMemoryTitle.size.h }
	})
	MoveMemory:spawnOpeners(openersHolder, memoryOpeners, MoveMemory.LastPage, suggested)
end

---Displays MoveMemory toolbar
---@param id integer
---@param text string
---@param killAction function
---@param saveAction ?function
function MoveMemory:showToolbar(id, text, killAction, saveAction)
	if (MoveMemory.TutorialMode) then
		return
	end
	MoveMemory.Toolbar = MoveMemory.Toolbar or { }
	local posY = nil
	if (MoveMemory.Toolbar[id]) then
		posY = MoveMemory.Toolbar[id].pos.y
		MoveMemory.Toolbar[id]:kill()
		MoveMemory.Toolbar[id] = nil
	end

	local count = #MoveMemory.Toolbar
	if (count == 1) then
		posY = nil
	end

	local toolbarH = WIN_W / 25 > 60 and 60 or WIN_W / 25
	local widthMod = saveAction and toolbarH - 10 or 0
	MoveMemory.Toolbar[id] = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { WIN_W / 6 * 4 - widthMod, posY or WIN_H - 50 - toolbarH * (count + 1) - count },
		size = { WIN_W / 6 * 2 - (100 - widthMod), toolbarH },
		bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		shapeType = ROUNDED,
		rounded = 10
	})
	local moveMemoryTurnInfo = MoveMemory.Toolbar[id]:addChild({
		pos = { 10, 10 },
		size = { MoveMemory.Toolbar[id].size.w - 60 - widthMod, MoveMemory.Toolbar[id].size.h - 20 }
	})
	moveMemoryTurnInfo:addAdaptedText(true, text, nil, nil, nil, LEFTMID)

	local killButtonSize = MoveMemory.Toolbar[id].size.h / 3 * 2
	local moveMemoryToolbarKill = MoveMemory.Toolbar[id]:addChild({
		pos = { -killButtonSize - killButtonSize / 4, killButtonSize / 4 },
		size = { killButtonSize, killButtonSize },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		pressedColor = { 1, 1, 1, 0.3 },
		shapeType = ROUNDED,
		rounded = 4
	})
	local moveMemoryToolbarKillIcon = moveMemoryToolbarKill:addChild({
		shift = { 5, 5 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga",
	})
	moveMemoryToolbarKill:addMouseUpHandler(killAction)
	if (saveAction) then
		local moveMemoryToolbarSave = MoveMemory.Toolbar[id]:addChild({
			pos = { -killButtonSize * 2 - killButtonSize / 4 - 5, killButtonSize / 4 },
			size = { killButtonSize, killButtonSize },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
			pressedColor = { 1, 1, 1, 0.3 },
			shapeType = ROUNDED,
			rounded = 4
		})
		local moveMemoryToolbarSaveIcon = moveMemoryToolbarSave:addChild({
			shift = { 5, 5 },
			bgImage = "../textures/menu/general/buttons/savewhite.tga",
		})
		moveMemoryToolbarSave:addMouseHandlers(nil, function()
				saveAction(function()
					killAction()
				end)
			end)
	end
end

---Plays move for the current turn
---@param memorymove MemoryMove
---@param spawnHook ?boolean
---@param player ?integer
---@param noToolbar ?boolean
function MoveMemory:playMove(memorymove, spawnHook, player, noToolbar)
	local worldstate = get_world_state()
	local player = player or worldstate.selected_player
	if (player < 0 or player >= worldstate.num_players) then
		TBMenu:showStatusMessage("Please select a player to run the opener")
		return
	end

	MoveMemory.PlaybackActive[player] = true

	local function playMoveQuit()
		MoveMemory.PlaybackActive[player] = false
		memorymove.currentturn = false
		remove_hooks("tbMoveMemoryPlayTurns" .. player)
		if (MoveMemory.Toolbar and MoveMemory.Toolbar[player]) then
			MoveMemory.Toolbar[player]:kill()
			MoveMemory.Toolbar[player] = nil
		end
	end

	local turn = spawnHook and (MoveMemory.FirstTurn and 1 or worldstate.match_turn + 1) or memorymove.currentturn
	if (type(turn) ~= "number" or type(memorymove.turns) ~= "number" or memorymove.turns < turn) then
		playMoveQuit()
		return
	end
	if (memorymove.movements[turn]) then
		for joint, state in pairs(memorymove.movements[turn]) do
			if (joint < 20) then
				local state = math.min(math.max(state, 1), 4)
				set_joint_state(player, joint, state)
			else
				-- Hand ids are 11 and 12, in data files we use 20 and 21
				local state = math.min(math.max(state, 0), 1)
				set_grip_info(player, joint - 9, state)
			end
		end
	end
	memorymove.currentturn = turn + 1

	---Force refresh ghost using current mode
	set_ghost(get_ghost())

	if (not noToolbar) then
		MoveMemory:showToolbar(player, memorymove.name .. ": " .. TB_MENU_LOCALIZED.WORDTURN .. " " .. turn .. " " .. TB_MENU_LOCALIZED.PAGINATIONPAGEOF .. " " .. memorymove.turns, playMoveQuit)
	end
	if (spawnHook) then
		add_hook("enter_freeze", "tbMoveMemoryPlayTurns" .. player, function() MoveMemory:playMove(memorymove, false, player, noToolbar) end)
		add_hook("end_game", "tbMoveMemoryPlayTurns" .. player, playMoveQuit)
		add_hook("match_begin", "tbMoveMemoryPlayTurns" .. player, playMoveQuit)
	end
end

---Displays move item in UI
---@param viewElement UIElement
---@param memorymove MemoryMove
---@param pos integer
---@param shift ?integer
---@param toReload ?UIElement
---@return UIElement
function MoveMemory:spawnMovementButton(viewElement, memorymove, pos, shift, toReload)
	local shift = shift or 0
	local buttonHolder = viewElement:addChild({
		pos = { 0, shift + pos * 45 },
		size = { viewElement.size.w, 45 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		hoverColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR),
		pressedColor = table.clone(TB_MENU_DEFAULT_LIGHTER_COLOR),
		uiColor = UICOLORWHITE
	})
	buttonHolder.hoverColor[4] = 0.5
	buttonHolder.pressedColor[4] = 0.5

	local openerDelete = TBMenu:createImageButtons(buttonHolder, -40, 0, 40, 40, "../textures/menu/general/buttons/trash.tga", "../textures/menu/general/buttons/trashhvr.tga", "../textures/menu/general/buttons/trashblack.tga", { 0, 0, 0, 0 })
	buttonHolder:addMouseHandlers(nil, function()
			MoveMemory:playMove(memorymove, true)
		end, function()
			if (not openerDelete.isactive) then
				openerDelete:show()
				openerDelete:activate()
				if (toReload) then
					toReload:reload()
				end
			end
		end)
	openerDelete:addCustomDisplay(false, function()
			if (buttonHolder.hoverState == BTN_NONE) then
				if (openerDelete.hoverState ~= BTN_NONE) then
					buttonHolder.hoverState = BTN_HVR
					return
				end
				buttonHolder.bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS
				openerDelete:deactivate()
				openerDelete:hide()
			end
		end)
	if (not MoveMemory.TutorialMode) then
		openerDelete:addMouseHandlers(nil, function() TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.MOVEMEMORYDELETEMOVECONFIRM, function() MoveMemory:deleteMove(memorymove) MoveMemory:quit() MoveMemory:showMain() end) end, function() buttonHolder.bgColor = buttonHolder.hoverColor end)
	end

	-- why the fuck is this flickering
	local nameHolder = UIElement:new({
		parent = buttonHolder,
		pos = { 5, 2 },
		size = { buttonHolder.size.w - 40, 22 }
	})
	nameHolder:addCustomDisplay(true, function() end)

	-- nameHolder isn't used for display because it doesn't work
	-- I have no idea why's that happening
	local nameHolder2 = UIElement:new({
		parent = buttonHolder,
		pos = { 5, 2 },
		size = { buttonHolder.size.w - 40, 22 }
	})
	nameHolder2:addAdaptedText(true, memorymove.name, nil, nil, FONTS.MEDIUM, LEFTBOT, nil, 0.7)
	if (memorymove.desc) then
		local descHolder = UIElement:new({
			parent = buttonHolder,
			pos = { 5, nameHolder.shift.y + nameHolder.size.h },
			size = { buttonHolder.size.w - 40, buttonHolder.size.h - nameHolder.size.h - nameHolder.shift.y * 2 }
		})
		descHolder:addAdaptedText(true, memorymove.desc, nil, nil, FONTS.SMALL, LEFT, nil, 0.7)
	end
	return buttonHolder
end

---Displays toggle whether to run openers from the start
---@param viewElement UIElement
function MoveMemory:spawnFirstTurnToggle(viewElement)
	local toggleText = viewElement:addChild({
		pos = { 10, 5 },
		size = { viewElement.size.w - 60, viewElement.size.h - 6 }
	})
	toggleText:addAdaptedText(true, "Run opener from start", nil, nil, nil, LEFTMID, 0.8)

	local toggleView = viewElement:addChild({
		pos = { -37, 7 },
		size = { 30, 30 }
	})
	local toggleBG = toggleView:addChild({
		shapeType = ROUNDED,
		rounded = 3,
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	local toggleView = toggleBG:addChild({
		shift = { 1, 1 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
		interactive = true
	}, true)
	local toggleIcon = toggleView:addChild({
		bgImage = "../textures/menu/general/buttons/checkmark.tga"
	})
	if (not MoveMemory.FirstTurn) then
		toggleIcon:hide(true)
	end
	toggleView:addMouseHandlers(nil, function()
			MoveMemory.FirstTurn = not MoveMemory.FirstTurn
			if (MoveMemory.FirstTurn) then
				toggleIcon:show(true)
			else
				toggleIcon:hide(true)
			end
		end)
end

---Displays main openers list
---@param viewElement UIElement
---@param memoryOpeners MemoryMove[]
---@param page integer
---@param suggested ?MemoryMove[]
function MoveMemory:spawnOpeners(viewElement, memoryOpeners, page, suggested)
	MoveMemory.LastPage = page or 1
	viewElement:kill(true)

	if (#memoryOpeners > 0) then
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, suggested and 45 or 35, 40, 20, { 0, 0, 0, 0 })

		local openersTitle = UIElement:new({
			parent = topBar,
			pos = { 0, 0 },
			size = { topBar.size.w, topBar.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			uiColor = UICOLORWHITE
		})
		openersTitle:addAdaptedText(false, TB_MENU_LOCALIZED.MOVEMEMORYALLMOVES .. ":", 5, -5, 4, LEFTBOT, 0.7)
		local botBarOverlay = UIElement:new({
			parent = botBar,
			pos = { 0, 0 },
			size = { botBar.size.w, botBar.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			uiColor = UICOLORWHITE
		})
		botBarOverlay:addCustomDisplay(true, function()
			set_color(unpack(botBarOverlay.bgColor))
			draw_disk(botBarOverlay.pos.x + 4, botBarOverlay.pos.y + botBarOverlay.size.h, 0, 4, 100, 1, -90, 90, 0)
			draw_disk(botBarOverlay.pos.x + botBarOverlay.size.w - 4, botBarOverlay.pos.y + botBarOverlay.size.h, 0, 4, 100, 1, 0, 90, 0)
			draw_quad(botBarOverlay.pos.x, botBarOverlay.pos.y, botBarOverlay.size.w, botBarOverlay.size.h)
			draw_quad(botBarOverlay.pos.x + 4, botBarOverlay.pos.y + botBarOverlay.size.h, botBarOverlay.size.w - 8, 4)
		end)
		MoveMemory:spawnFirstTurnToggle(botBarOverlay)
		local scrollBackdrop = UIElement:new({
			parent = listingScrollBG,
			pos = { 0, 0 },
			size = { listingScrollBG.size.w, listingScrollBG.size.h },
			bgColor = { unpack(TB_MENU_DEFAULT_DARKER_COLOR) }
		})
		scrollBackdrop.bgColor[4] = 0.6

		local listElements = {}
		for i, v in pairs(memoryOpeners) do
			local button = MoveMemory:spawnMovementButton(listingHolder, v, i - 1, nil, botBar)
			table.insert(listElements, button)
		end

		for _, v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, 45)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
	end
end

---Spawns suggested openers for display
---@param viewElement UIElement
---@return MemoryMove[]|nil
function MoveMemory:spawnSuggested(viewElement)
	local loadedMod = get_game_rules().mod:gsub("%.tbm$", "")
	local suggestedOpeners = {}
	local displayedSuggested = {}
	for _, v in pairs(MoveMemory.Storage) do
		if (v.mod) then
			if (loadedMod:find(v.mod) and v.mod:len() > 0) then
				table.insert(suggestedOpeners, v)
			end
		end
	end
	if (#suggestedOpeners == 0) then
		return nil
	end

	local suggestedTitle = viewElement:addChild({
		size = { viewElement.size.w, 35 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		uiColor = UICOLORWHITE
	})
	viewElement.size.h = #suggestedOpeners > 2 and 2 * 45 + 35 or #suggestedOpeners * 45 + 35
	suggestedTitle:addAdaptedText(false, TB_MENU_LOCALIZED.MOVEMEMORYSUGGESTEDMOVES .. " (" .. loadedMod:upper() .. "):", 5, -5, 4, LEFTBOT, 0.7)
	for i, v in pairs(suggestedOpeners) do
		if (i * 40 + 35 > viewElement.size.h) then
			return displayedSuggested
		end
		table.insert(displayedSuggested, v)
		MoveMemory:spawnMovementButton(viewElement, v, i - 1, 35)
	end
	return displayedSuggested
end

---Spawns a hook to open movememory on `M` key press \
---Make sure we also check CTRL and ALT aren't pressed as those are tied to mod list / modmaker
function MoveMemory:init()
	add_hook("key_down", "tbMoveMemoryHotkeyListener", function(key)
		if (key == 109 and get_keyboard_ctrl() == 0 and get_keyboard_alt() == 0) then
			if (MoveMemory.MainElement) then
				MoveMemory:quit()
			elseif (get_option("movememory") == 1) then
				MoveMemory:showMain()
			end
		end
	end)
end
MoveMemory:init()
