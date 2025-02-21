if (MoveMemory == nil) then
	local _, top_y = get_window_safe_size()
	---@class MoveMemoryToolbar : UIElement
	---@field infoText UIElement

	---**MoveMemory manager class**
	---
	---**Version 5.74**
	---* Updates for better move recording control when run from other scripts
	---* Added `Recording` table to reference moves that are currently being recorded
	---
	---**Version 5.70**
	---* Added `HookName` field
	---
	---**Version 5.61**
	---* Added `OnOpenedEvents` and `OnClosedEvents` callback lists
	---* While in *TutorialMode*, use `ToggleTutorialQuit()` to enable or disable UI exit button
	---
	---**Version 5.60**
	---* Documentation with EmmyLua annotations
	---* Updated internals and visuals to match 5.60 design
	---@class MoveMemory
	---@field MainElement UIElement
	---@field MovesHolder UIElement
	---@field Toolbar MoveMemoryToolbar[] List of toolbar UIElements
	---@field Storage MemoryMove[] All cached MoveMemory moves
	---@field ElementHeight integer Height of MoveMemory list buttons
	---@field PlaybackActive boolean[] List of players' move playback statuses
	---@field TutorialMode boolean Whether we're currently in Tutorial mode
	---@field TutorialModeOverlay UIElement
	---@field OnOpenedEvents function[] List of callback functions to be executed whenever MoveMemory is opened
	---@field OnClosedEvents function[] List of callback functions to be executed whenever MoveMemory is closed
	MoveMemory = {
		DisplayPos = { x = SAFE_X + 10, y = top_y + 10 },
		PlaybackActive = {},
		FirstTurn = false,
		Storage = {},
		Toolbar = {},
		Recording = {},
		ElementHeight = 35,
		StoragePopulated = false,
		TutorialMode = false,
		OnOpenedEvents = { },
		OnClosedEvents = { },
		HookName = "__tbMoveMemoryManager",
		ver = 5.74
	}
	MoveMemory.__index = MoveMemory

	---Move class for **MoveMemory** manager
	---@class MemoryMove
	---@field id integer Move id in storage cache
	---@field name string Name of the movement sequence
	---@field desc string Description of the movement sequence
	---@field mod string Name of the mod that this move was made for
	---@field turns integer Number of turns in this move sequence
	---@field movements integer[][] Movements data
	---@field currentturn integer|nil Internal value to tell which turn MoveMemory should play next
	MemoryMove = {
		ver = MoveMemory.ver
	}
	MemoryMove.__index = MemoryMove
end

---Helper class for **MoveMemory** manager
---@class MoveMemoryInternal
local MoveMemoryInternal = {}

---Creates a **MemoryMove** instance from data
---@param moveData integer[][]
---@param name string?
---@param description string?
---@param mod string?
---@return MemoryMove
function MemoryMove.FromData(moveData, name, description, mod)
	---@type MemoryMove
	local memoryMove = {
		name = name or "",
		desc = description or "",
		mod = mod or "",
		movements = table.clone(moveData),
		turns = #moveData
	}
	setmetatable(memoryMove, MemoryMove)
	return memoryMove
end

---Creates a **MemoryMove** instance from opener lines
---@param openerLines string[]
---@return MemoryMove
function MemoryMove.FromOpener(openerLines)
	local moveData = { }
	local openerValues = { f = 1, b = 2, h = 3, r = 4 }
	for _, turn in ipairs(openerLines) do
		local turnMove = { }
		for i = 1, 20 do
			turnMove[i - 1] = openerValues[string.sub(turn, i, i)]
		end
		turnMove[20] = string.sub(turn, 21, 21) == '+' and 1 or 0
		turnMove[21] = string.sub(turn, 22, 22) == '+' and 1 or 0
		table.insert(moveData, turnMove)
	end
	return MemoryMove.FromData(moveData)
end

---Returns memory move as a table of opener strings
---@return string[]
function MemoryMove:toOpener()
	local openerLines = { }
	local openerValues = { "f", "b", "h", "r" }
	for _, turn in ipairs(self.movements) do
		local openerLine = ""
		for i = 0, 19 do
			openerLine = openerLine .. openerValues[turn[i]]
		end
		openerLine = openerLine .. (turn[20] == 1 and "+" or "-") .. (turn[21] == 1 and "+" or "-")
		table.insert(openerLines, openerLine)
	end
	return openerLines
end

---Exits MoveMemory and destroys main holder
function MoveMemory.Quit()
	if (MoveMemory.MainElement ~= nil) then
		MoveMemory.MainElement:kill()
		MoveMemory.MainElement = nil
		MoveMemory.TutorialModeOverlay = nil
	end
end

---In the earlier versions of MoveMemory we used a different datafile. \
---Check if it exists and migrate data to the new one if needed.
---@return boolean
function MoveMemoryInternal.checkLegacyCache()
	local file = Files.Open("system/data.mm")
	local newfile = Files.Open("system/movememory.mm", FILES_MODE_WRITE)
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

---Adds a callback function to be executed on MoveMemory display event
---@param name string
---@param func function
function MoveMemory.AddOnOpenedEvent(name, func)
	MoveMemory.OnOpenedEvents[name] = func
end

---@param name string
function MoveMemory.RemoveOnOpenedEvent(name)
	MoveMemory.OnOpenedEvents[name] = nil
end

---Adds a callback function to be executed on MoveMemory hide event
---@param name string
---@param func function
function MoveMemory.AddOnClosedEvent(name, func)
	MoveMemory.OnClosedEvents[name] = func
end

---@param name string
function MoveMemory.RemoveOnClosedEvent(name)
	MoveMemory.OnClosedEvents[name] = nil
end

---Reads the data file and populates moves list
---@return boolean
function MoveMemory:getOpeners()
	self.Storage = {}
	self.StoragePopulated = false

	local file = Files.Open("system/movememory.mm", FILES_MODE_READONLY)
	if (not file.data) then
		if (not is_mobile()) then
			if (pcall(MoveMemoryInternal.checkLegacyCache) == false) then
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MOVEMEMORYLOADERROR)
				return self.StoragePopulated
			end
			file:reopen()
		else
			file:reopen(FILES_MODE_WRITE)
			file:reopen(FILES_MODE_READONLY)
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
			if (line:find("^NAME")) then
				self.Storage[#self.Storage + 1] = {
					id = #self.Storage + 1,
					name = line:gsub("^NAME ", "")
				}
				setmetatable(self.Storage[#self.Storage], MemoryMove)
			elseif (#self.Storage > 0) then
				if (line:find("^DESC")) then
					self.Storage[#self.Storage].desc = line:gsub("^DESC ", "")
				elseif (line:find("^MOD")) then
					self.Storage[#self.Storage].mod = line:gsub("^MOD ", ""):gsub("%.tbm$", "")
				elseif (line:find("^TURN")) then
					if (not self.Storage[#self.Storage].movements) then
						self.Storage[#self.Storage].movements = {}
					end
					line = line:gsub("^TURN ", "")
					local min, max = line:find("^%d+;")
					if (min ~= nil and max ~= nil) then
						local turn = tonumber(line:sub(min, max - 1))
						if (turn ~= nil) then
							self.Storage[#self.Storage].movements[turn] = {}
							if (not self.Storage[#self.Storage].turns) then
								self.Storage[#self.Storage].turns = turn
							elseif (self.Storage[#self.Storage].turns < turn) then
								self.Storage[#self.Storage].turns = turn
							end

							line = line:gsub("^%d+; ", "")
							local _, count = line:gsub("%d+", "")
							local data_stream = { line:match(("(%d+ %d+) *"):rep(count / 2)) }
							for _, v in pairs(data_stream) do
								local info = { v:match(("(%d+) *"):rep(2)) }
								self.Storage[#self.Storage].movements[turn][tonumber(info[1])] = tonumber(info[2])
							end
						end
					end
				end
			end
		end)
	end

	---Clean up moves without any data written to them
	for i = #self.Storage, 1, -1 do
		if (self.Storage[i].movements == nil or table.empty(self.Storage[i].movements)) then
			table.remove(self.Storage, i)
		end
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
---@return boolean
function MemoryMove:writeToFile(fileInterface)
	if (string.len(self.name) == 0) then
		return false
	end

	local file = fileInterface or Files.Open("system/movememory.mm", FILES_MODE_APPEND)
	if (not file.data) then
		return false
	end

	file:writeLine("")
	file:writeLine("NAME " .. self.name)
	if (self.desc and string.len(self.desc) > 0) then
		file:writeLine("DESC " .. self.desc)
	end
	if (self.mod and string.len(self.mod) > 0) then
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
	return true
end

---Displays move recording save window
---@param moveData integer[][]
---@param successAction ?function
function MoveMemory:showSaveRecordingComplete(moveData, successAction)
	local overlay = TBMenu:spawnWindowOverlay()

	local windowWidth = math.min(WIN_W / 2, 550)
	local windowHolder = overlay:addChild({
		shift = { (WIN_W - windowWidth) / 2, WIN_H / 2 - 140 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local windowTitle = windowHolder:addChild({
		pos = { 60, 0 },
		size = { windowHolder.size.w - 120, 50 }
	})
	windowTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MOVEMEMORYSAVING, nil, nil, FONTS.BIG, nil, 0.65)
	local closeButton = windowHolder:addChild({
		pos = { -windowTitle.size.h + 5, 5 },
		size = { windowTitle.size.h - 10, windowTitle.size.h - 10 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	closeButton:addChild({
		shift = { 5, 5 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})
	closeButton:addMouseUpHandler(function()
			overlay:kill()
		end)

	local moveSaveButton = windowHolder:addChild({
		pos = { windowHolder.size.w / 4, -50 },
		size = { windowHolder.size.w / 2, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	moveSaveButton:addAdaptedText(TB_MENU_LOCALIZED.BUTTONSAVE)

	local moveNameBackground = windowHolder:addChild({
		pos = { 10, windowTitle.shift.y + windowTitle.size.h + 10 },
		size = { windowHolder.size.w - 20, 40 },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	}, true)
	local moveNameInput = TBMenu:spawnTextField2(moveNameBackground, nil, nil, TB_MENU_LOCALIZED.MOVEMEMORYENTERMOVENAME, {
		textAlign = CENTERMID,
		fontId = FONTS.LMEDIUM,
		textScale = 0.7
	})

	local moveDescBackground = windowHolder:addChild({
		pos = { 10, moveNameBackground.shift.y + moveNameBackground.size.h + 10 },
		size = { moveNameBackground.size.w, moveNameBackground.size.h },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	}, true)
	local moveDescInput = TBMenu:spawnTextField2(moveDescBackground, nil, nil, TB_MENU_LOCALIZED.MOVEMEMORYENTERMOVEDESCOPT, {
		textAlign = CENTERMID,
		fontId = FONTS.LMEDIUM,
		textScale = 0.7
	})

	local moveModBackground = windowHolder:addChild({
		pos = { 10, moveDescBackground.shift.y + moveDescBackground.size.h + 10 },
		size = { moveDescBackground.size.w, moveDescBackground.size.h },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	}, true)
	local modname = get_game_rules().mod:gsub("%.tbm$", "")
	local moveModInput = TBMenu:spawnTextField2(moveModBackground, nil, modname, TB_MENU_LOCALIZED.MOVEMEMORYENTERMODNAMEOPT, {
		textAlign = CENTERMID,
		fontId = FONTS.LMEDIUM,
		textScale = 0.7
	})

	local function saveMove(name, description, mod)
		if (string.len(name) == 0) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MOVEMEMORYMODNAMEEMPTYERROR)
			return
		end

		local memoryMove = MemoryMove.FromData(moveData, name, description, mod)
		if (not memoryMove:writeToFile()) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MOVEMEMORYERRORUPDATINGDATA)
			return
		end

		overlay:kill()
		if (successAction) then
			successAction()
		end
		if (self.MainElement ~= nil) then
			self:reload()
		end
	end

	moveSaveButton:addMouseUpHandler(function()
		saveMove(moveNameInput.textfieldstr[1], moveDescInput.textfieldstr[1], moveModInput.textfieldstr[1])
	end)
end

---Begins MoveMemory move recording and spawns callback listeners
---@param spawnToolbar boolean? Whether to spawn toolbar, defaults to `true`
function MoveMemory:recordMove(spawnToolbar)
	local ws = get_world_state()
	local player = ws.selected_player
	if (player < 0) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MOVEMEMORYERRORNOTINGAME)
		return
	end
	if (self.PlaybackActive[player]) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MOVEMEMORYERRORSTOPMOVE)
		return
	end

	local recordMove = { }
	for _ = 1, ws.match_turn do
		table.insert(recordMove, {})
	end

	local hookName = MoveMemory.HookName .. "Record" .. player
	local function cancelRecording()
		self:cancelRecording(player)
	end

	spawnToolbar = spawnToolbar == nil and true or spawnToolbar
	if (spawnToolbar == true) then
		self:showToolbar(player, TB_MENU_LOCALIZED.MOVEMEMORYRECORDINGTURN .. " #" .. (#recordMove + 1), cancelRecording, function()
				self:showSaveRecordingComplete(recordMove, cancelRecording)
			end)
	end
	add_hook("exit_freeze", hookName, function()
			table.insert(recordMove, {})
			for _, v in pairs(JOINTS) do
				recordMove[#recordMove][v] = get_joint_info(player, v).state
			end
			recordMove[#recordMove][20] = get_grip_info(player, 11)
			recordMove[#recordMove][21] = get_grip_info(player, 12)
			if (spawnToolbar) then
				self:updateToolbar(player, TB_MENU_LOCALIZED.MOVEMEMORYRECORDINGTURN .. " #" .. (#recordMove + 1))
			end
		end)
	if (spawnToolbar) then
		add_hook("leave_game", hookName, function()
				if (#recordMove > 0) then
					self:showSaveRecordingComplete(recordMove)
				end
				cancelRecording()
			end)
	end

	self.Recording[player] = recordMove
end

---Cancels ongoing recording of a move for the specified player
---@param player integer
function MoveMemory:cancelRecording(player)
	local hookName = MoveMemory.HookName .. "Record" .. player
	remove_hooks(hookName)
	if (self.Toolbar[player]) then
		self.Toolbar[player]:kill()
		self.Toolbar[player] = nil
	end
	self.Recording[player] = nil
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

	local file = Files.Open("system/movememory.mm", FILES_MODE_WRITE)
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
	self.Quit()
	self:showMain()
end

---Toggles UI quit button while in Tutorial mode
---@param enabled boolean
function MoveMemory:toggleTutorialQuit(enabled)
	if (self.TutorialModeOverlay == nil) then return end
	self.TutorialModeOverlay.size.w = enabled and self.MainElement.size.w - self.TutorialModeOverlay.size.h or self.MainElement.size.w
end

---Displays MoveMemory main window
function MoveMemory:showMain()
	local status, error = pcall(function() self:getOpeners() end)
	if (not self.TutorialMode) then
		if (not status) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.WORDERROR .. " " .. error)
			return
		end
		if (not self.StoragePopulated) then
			return
		end
	end

	for _, v in pairs(self.OnOpenedEvents) do
		if (type(v) == "function") then
			pcall(v)
		end
	end

	local windowMover
	self.MainElement, self.MovesHolder, windowMover = TBMenu:spawnMoveableWindow(self.DisplayPos)
	self.DisplayPos = self.MainElement.pos
	self.MainElement.killAction = function()
		self.MainElement = nil
		self.TutorialModeOverlay = nil
		for _, v in pairs(self.OnClosedEvents) do
			if (type(v) == "function") then
				pcall(v)
			end
		end
	end

	if (self.TutorialMode) then
		self.TutorialModeOverlay = self.MainElement:addChild({
			pos = { 0, 0 },
			size = { self.MainElement.size.w, windowMover.size.h },
			interactive = true
		})
	end

	if (#self.Storage == 0) then
		if (not self.TutorialMode) then
			local memoryHeader = self.MovesHolder:addChild({
				size = { self.MovesHolder.size.w, 40 }
			})
			memoryHeader:addChild({ shift = { memoryHeader.size.h, 5 }}):addAdaptedText(true, TB_MENU_LOCALIZED.MOVEMEMORYTITLE, nil, nil, FONTS.BIG, nil, 0.7)
			local addMoveButton = memoryHeader:addChild({
				pos = { 10, 5 },
				size = { memoryHeader.size.h - 10, memoryHeader.size.h - 10 },
				interactive = true,
				bgImage = "../textures/menu/general/buttons/addsign.tga",
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			addMoveButton:addMouseHandlers(nil, function()
					self:recordMove()
				end)
			local addMoveTooltip = TBMenu:displayPopup(addMoveButton, TB_MENU_LOCALIZED.MOVEMEMORYRECORDINFO)
			if (addMoveTooltip ~= nil) then
				addMoveTooltip:moveTo(addMoveButton.size.w + 5)
			end
			self.MovesHolder:addChild({ shift = { 0, 40 } }):addAdaptedText(true, TB_MENU_LOCALIZED.MOVEMEMORYNOMOVESFOUND, nil, nil, nil, nil, nil, nil, 0)
			return
		end
		self.MovesHolder:addAdaptedText(true, TB_MENU_LOCALIZED.MOVEMEMORYNOMOVESFOUND, nil, nil, nil, nil, nil, nil, 0)
		return
	end

	self:spawnOpeners(self.MovesHolder)
end

---Fixes toolbars order when new ones are spawned or existing ones are destroyed
---@param killId ?integer
function MoveMemory:fixToolbarOrder(killId)
	local safe_y = math.max(SAFE_Y, is_mobile() and TBHud.DefaultSmallerButtonSize * 3.5 or 50)

	local height = nil
	local cnt = 0
	for i = 0, 3 do
		if (i ~= killId and self.Toolbar[i] ~= nil) then
			if (height == nil) then
				height = self.Toolbar[i].size.h
			end
			cnt = cnt + 1
			self.Toolbar[i]:moveTo(nil, WIN_H - safe_y - height * cnt)
		end
	end
end

---Displays MoveMemory toolbar
---@param id integer
---@param text string
---@param killAction function
---@param saveAction ?function
function MoveMemory:showToolbar(id, text, killAction, saveAction)
	if (self.TutorialMode) then return end

	if (self.Toolbar[id]) then
		self.Toolbar[id]:kill()
		self.Toolbar[id] = nil
	end

	local toolbarHeight = math.min(WIN_H / 10, 60)
	local toolbarWidth = math.min(WIN_W / 4, 400, is_mobile() and (TBHud.DefaultButtonSize * 3.1 - SAFE_X) or WIN_W)
	local safe_x = math.max(SAFE_X, 10)

	---@diagnostic disable-next-line: assign-type-mismatch
	self.Toolbar[id] = UIElement.new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { WIN_W - safe_x - toolbarWidth, WIN_H },
		size = { toolbarWidth, toolbarHeight }
	})
	self:fixToolbarOrder()
	self.Toolbar[id].killAction = function() self:fixToolbarOrder(id) end
	local toolbarHolder = self.Toolbar[id]:addChild({
		shift = { 0, 4 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		shapeType = ROUNDED,
		rounded = 4
	})
	local toolbarPlayerHolder = toolbarHolder:addChild({
		size = { toolbarHolder.size.h, toolbarHolder.size.h }
	})
	TBMenu:showPlayerHeadAvatar(toolbarPlayerHolder, get_player_info(id).name)

	local buttonClose = toolbarHolder:addChild({
		pos = { -toolbarHolder.size.h + 5, 5 },
		size = { toolbarHolder.size.h - 10, toolbarHolder.size.h - 10 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
		hoverColor = TB_MENU_DEFAULT_BG_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	buttonClose:addChild({
		shift = { 5, 5 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga",
	})
	buttonClose:addMouseUpHandler(killAction)

	if (saveAction) then
		local saveButton = toolbarHolder:addChild({
			pos = { buttonClose.shift.x - buttonClose.size.w - 5, buttonClose.shift.y },
			size = { buttonClose.size.w, buttonClose.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
			hoverColor = TB_MENU_DEFAULT_BG_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		saveButton:addChild({
			shift = { 5, 5 },
			bgImage = "../textures/menu/general/buttons/savewhite.tga",
		})
		saveButton:addMouseUpHandler(function()
				saveAction(killAction)
			end)
	end

	self.Toolbar[id].infoText = toolbarHolder:addChild({
		pos = { toolbarPlayerHolder.size.h, 5 },
		size = { toolbarHolder.size.w - toolbarPlayerHolder.size.h * (saveAction and 3 or 2), toolbarHolder.size.h - 10 }
	})
	self.Toolbar[id].infoText:addAdaptedText(true, text, nil, nil, nil, LEFTMID)
end

---Updates toolbar info message
---@param id integer
---@param text string
function MoveMemory:updateToolbar(id, text)
	if (self.Toolbar[id] == nil) then return end
	self.Toolbar[id].infoText:addAdaptedText(true, text, nil, nil, nil, LEFTMID)
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

	local hookName = MoveMemory.HookName .. "Play" .. player
	self.PlaybackActive[player] = self.PlaybackActive[player] or spawnHook
	local function playMoveQuit()
		self.PlaybackActive[player] = false
		memorymove.currentturn = nil
		remove_hooks(hookName)
		if (self.Toolbar and self.Toolbar[player]) then
			self.Toolbar[player]:kill()
			self.Toolbar[player] = nil
		end
	end

	local turn = spawnHook and (self.FirstTurn and 1 or worldstate.match_turn + 1) or memorymove.currentturn
	if (type(turn) ~= "number" or type(memorymove.turns) ~= "number" or memorymove.turns < turn) then
		playMoveQuit()
		return
	end
	if (memorymove.movements[turn]) then
		---Set grip states first, then set joint states with ghost update and effects
		if (memorymove.movements[turn][20] ~= nil) then
			set_grip_info(player, 11, math.clamp(memorymove.movements[turn][20], 0, 1))
		end
		if (memorymove.movements[turn][21] ~= nil) then
			set_grip_info(player, 12, math.clamp(memorymove.movements[turn][21], 0, 1))
		end
		for joint, state in pairs(memorymove.movements[turn]) do
			if (joint < 20) then
				local state = math.min(math.max(state, 1), 4)
				set_joint_state(player, joint, state, self.PlaybackActive[player])
			end
		end
	end
	memorymove.currentturn = turn + 1

	if (not noToolbar) then
		if (spawnHook) then
			self:showToolbar(player, memorymove.name .. ": " .. TB_MENU_LOCALIZED.WORDTURN .. " " .. turn .. " " .. TB_MENU_LOCALIZED.PAGINATIONPAGEOF .. " " .. memorymove.turns, playMoveQuit)
		else
			self:updateToolbar(player, memorymove.name .. ": " .. TB_MENU_LOCALIZED.WORDTURN .. " " .. turn .. " " .. TB_MENU_LOCALIZED.PAGINATIONPAGEOF .. " " .. memorymove.turns)
		end
	end
	if (spawnHook) then
		add_hook("enter_freeze", hookName, function()
				self:playMove(memorymove, false, player, noToolbar)
			end)
		add_hook("end_game", hookName, playMoveQuit)
		add_hook("match_begin", hookName, playMoveQuit)
	end
end

---Displays move item in UI
---@param viewElement UIElement
---@param memorymove MemoryMove
---@param listElements UIElement[]
function MoveMemory:spawnMovementButton(viewElement, memorymove, listElements)
	local buttonTopHolder = viewElement:addChild({
		pos = { 0, #listElements * self.ElementHeight },
		size = { viewElement.size.w, self.ElementHeight }
	})
	table.insert(listElements, buttonTopHolder)
	local moveButton = buttonTopHolder:addChild({
		pos = { 10, 2 },
		size = { buttonTopHolder.size.w - 12, buttonTopHolder.size.h - 4 },
		interactive = true,
		clickThrough = true,
		hoverThrough = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	moveButton:addMouseUpHandler(function()
			self:playMove(memorymove, true)
		end)

	if (not self.TutorialMode) then
		local deleteButton = moveButton:addChild({
			pos = { -moveButton.size.h + 1, 1 },
			size = { moveButton.size.h - 2, moveButton.size.h - 2 },
			interactive = true,
			hoverThrough = true,
			bgImage = "../textures/menu/general/buttons/trash.tga",
			bgColor = moveButton.animateColor,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			imageColor = UICOLORWHITE,
			imageHoverColor = UICOLORBLACK,
			imagePressedColor = UICOLORBLACK,
			rounded = moveButton.size.h
		}, true)
		deleteButton:addMouseUpHandler(function()
				TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.MOVEMEMORYDELETEMOVECONFIRM, function()
						self:deleteMove(memorymove)
						self:reload()
					end)
			end)
	end

	local moveName = moveButton:addChild({
		pos = { 5, 2 },
		size = { moveButton.size.w - moveButton.size.h - 10, moveButton.size.h - 4 }
	})
	moveName:addAdaptedText(true, memorymove.name, nil, nil, FONTS.MEDIUM, LEFTBOT, nil, 0.7)
	if (memorymove.desc and string.len(memorymove.desc) > 0) then
		moveButton.size.h = moveButton.parent.size.h - moveButton.shift.y + 0.01
		moveButton:setRounded({ moveButton.rounded, 0 })
		local buttonBotHolder = viewElement:addChild({
			pos = { 0, #listElements * self.ElementHeight },
			size = { viewElement.size.w, self.ElementHeight }
		})
		table.insert(listElements, buttonBotHolder)
		local descButton = buttonBotHolder:addChild({
			pos = { moveButton.shift.x, 0 },
			size = { moveButton.size.w, moveButton.size.h },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = moveButton.shapeType,
			rounded = { moveButton.roundedInternal[2], moveButton.roundedInternal[1] }
		})
		descButton.btnUp = moveButton.btnUp
		moveButton:addCustomDisplay(false, function()
			if (descButton.hoverState ~= moveButton.hoverState and descButton:isDisplayed()) then
				if (moveButton.hoverState > descButton.hoverState) then
					descButton.hoverState = moveButton.hoverState
					descButton.hoverClock = moveButton.hoverClock
				else
					moveButton.hoverState = descButton.hoverState
					moveButton.hoverClock = descButton.hoverClock
				end
			end
		end, true)
		local descHolder = descButton:addChild({
			pos = { 5, 2 },
			size = { descButton.size.w - 10, descButton.size.h - 4 },
			uiColor = TB_MENU_DEFAULT_INACTIVE_COLOR
		})
		descHolder:addAdaptedText(true, memorymove.desc, nil, nil, 4, LEFT, 0.65, 0.65)
	end
end

---Displays toggle whether to run openers from the start
---@param viewElement UIElement
function MoveMemory:spawnFirstTurnToggle(viewElement)
	local toggleView = viewElement:addChild({
		pos = { 5, -33 },
		size = { 26, 26 },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		shapeType = ROUNDED,
		rounded = 3
	})
	TBMenu:spawnToggle(toggleView, nil, nil, nil, nil, self.FirstTurn, function(state)
			self.FirstTurn = state
		end)

	local toggleLegend = viewElement:addChild({
		pos = { toggleView.shift.x * 2 + toggleView.size.w, toggleView.shift.y },
		size = { viewElement.size.w - (toggleView.shift.x * 3 + toggleView.size.w), toggleView.size.h }
	})
	toggleLegend:addAdaptedText(true, TB_MENU_LOCALIZED.MOVEMEMORYRUNFROMBEGINNING, nil, nil, 4, LEFTMID, 0.75)
end

---Displays main openers list
---@param viewElement UIElement
---@param memoryOpeners ?MemoryMove[]
function MoveMemory:spawnOpeners(viewElement, memoryOpeners)
	viewElement:kill(true)
	local headerHeight = 40
	local featuredHolder = nil

	if (memoryOpeners == nil) then
		memoryOpeners = {}
		featuredHolder = viewElement:addChild({
			pos = { 0, headerHeight },
			size = { viewElement.size.w, math.min(viewElement.size.h / 4, self.ElementHeight * 5) }
		})
		local suggested = self:spawnSuggested(featuredHolder)
		if (table.empty(suggested)) then
			featuredHolder:kill()
			featuredHolder = nil
			for _, v in pairs(self.Storage) do
				table.insert(memoryOpeners, v)
			end
		else
			for _, v in pairs(self.Storage) do
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
	end

	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(viewElement, headerHeight + (featuredHolder and featuredHolder.size.h or 0), 40, 20, TB_MENU_DEFAULT_BG_COLOR)

	if (featuredHolder ~= nil) then
		---We want to detach featuredHolder from viewElement and attach it to topBar so that it gets refreshed when list is scrolled
		---It was the first object to get added so should be safe to do it without searching through the whole child tree
		table.remove(viewElement.child, 1)
		table.insert(topBar.child, featuredHolder)
		featuredHolder.parent = topBar
		featuredHolder:reload()
	end

	local memoryHeader = topBar:addChild({
		size = { topBar.size.w, headerHeight }
	})
	memoryHeader:addChild({ shift = { memoryHeader.size.h, 5 }}):addAdaptedText(true, TB_MENU_LOCALIZED.MOVEMEMORYTITLE, nil, nil, FONTS.BIG, nil, 0.7)

	if (not self.TutorialMode) then
		local addMoveButton = memoryHeader:addChild({
			pos = { 10, 5 },
			size = { memoryHeader.size.h - 10, memoryHeader.size.h - 10 },
			interactive = true,
			bgImage = "../textures/menu/general/buttons/addsign.tga",
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		addMoveButton:addMouseHandlers(nil, function()
				self:recordMove()
			end)
		local addMoveTooltip = TBMenu:displayPopup(addMoveButton, TB_MENU_LOCALIZED.MOVEMEMORYRECORDINFO)
		if (addMoveTooltip ~= nil) then
			addMoveTooltip:moveTo(addMoveButton.size.w + 5)
		end
	end

	botBar:setRounded({ 0, 4 })
	self:spawnFirstTurnToggle(botBar)

	local listElements = {}
	for _, v in pairs(memoryOpeners) do
		self:spawnMovementButton(listingHolder, v, listElements)
	end

	for _, v in pairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, self.ElementHeight)
	scrollBar:makeScrollBar(listingHolder, listElements, toReload)
end

---Returns a list of suggested openers
---@return MemoryMove[]
function MoveMemory:getSuggestedMoves()
	local loadedMod = get_game_rules().mod:gsub("%.tbm$", "")
	local suggestedOpeners = {}
	for _, v in pairs(self.Storage) do
		if (v.mod and string.len(v.mod) > 0) then
			if (loadedMod:find(v.mod)) then
				table.insert(suggestedOpeners, v)
			end
		end
	end
	return suggestedOpeners
end

---Spawns suggested openers for display
---@param viewElement UIElement
---@return MemoryMove[]
function MoveMemory:spawnSuggested(viewElement)
	local displayedSuggested = {}
	local suggestedOpeners = self:getSuggestedMoves()
	if (#suggestedOpeners == 0) then
		return displayedSuggested
	end

	local featuredHolder = viewElement:addChild({
		pos = { 10, 0 },
		size = { viewElement.size.w - 20, viewElement.size.h - 4 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local suggestedTitle = featuredHolder:addChild({
		pos = { 10, 0 },
		size = { featuredHolder.size.w - 20, self.ElementHeight }
	})
	suggestedTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MOVEMEMORYSUGGESTEDMOVES, nil, nil, nil, LEFTMID)

	local listElements = { suggestedTitle }
	for _, v in pairs(suggestedOpeners) do
		if ((#listElements + 2) * self.ElementHeight > featuredHolder.size.h) then
			break
		end
		table.insert(displayedSuggested, v)
		self:spawnMovementButton(featuredHolder, v, listElements)
	end
	for _, v in pairs(listElements) do
		if (v.child[1]) then
			v.child[1]:moveTo(2)
			v.child[1].size.w = v.size.w - 4
			v.child[1].bgColor = TB_MENU_DEFAULT_BG_COLOR
		end
	end
	featuredHolder.size.h = #listElements * self.ElementHeight
	viewElement.size.h = featuredHolder.size.h + 4
	return displayedSuggested
end

---Spawns a hook to open movememory on `M` key press \
---Make sure we also check CTRL and ALT aren't pressed as those are tied to mod list / modmaker
function MoveMemory.Init()
	add_hook("key_up", MoveMemory.HookName, function(key)
		if (key == 109 and get_keyboard_ctrl() == 0 and get_keyboard_alt() == 0) then
			if (MoveMemory.MainElement) then
				MoveMemory.Quit()
			elseif (get_option("movememory") == 1) then
				MoveMemory:showMain()
			end
		end
	end)
	pcall(function() MoveMemory:getOpeners() end)
end
MoveMemory.Init()
