local SPACEBAR = " "

---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param consume boolean?
local function requireKeyPressSpace(viewElement, reqTable, consume)
	local req = { type = "keypress", ready = false }
	table.insert(reqTable, req)

	if (is_mobile()) then
		local commitButton = viewElement:addChild({
			pos = { TBHud.CommitStepButtonHolder.shift.x, TBHud.CommitStepButtonHolder.shift.y },
			size = { TBHud.CommitStepButtonHolder.size.w, TBHud.CommitStepButtonHolder.size.h },
			interactive = true,
			clickThrough = not consume
		})
		commitButton:addMouseUpHandler(function()
			step_game()
			req.ready = true
			reqTable.ready = Tutorials:checkRequirements(reqTable)
		end)
		return
	end

	add_hook("key_up", Tutorials.StepHook, function(s, code)
		if (string.schar(s) == SPACEBAR or (code > 3 and code < 30 and string.schar(code + 93) == SPACEBAR)) then
			req.ready = true
			reqTable.ready = Tutorials:checkRequirements(reqTable)
			if (consume == true) then
				return 1
			end
		end
	end)
end

local function requireKeyPressSpaceConsume(viewElement, reqTable)
	requireKeyPressSpace(viewElement, reqTable, true)
end

local function beginRecording()
	select_player(0, false)
	MoveMemory:recordMove(false)
	TUTORIAL_LEAVEGAME = false

	local blindfightDirectoryExists = false
	for _, v in ipairs(get_folders("replay")) do
		if (v == 'blindfight') then
			blindfightDirectoryExists = true
			break
		end
	end
	if (not blindfightDirectoryExists) then
		add_replay_subfolder("blindfight")
	end

	TBMenu:showStatusMessage("Make a 3-turn opener and hit \"Submit\" button")
end

---@class BlindFightOpponent
---@field username string
---@field opener MemoryMove
---@field win integer

---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param opponentInfos BlindFightOpponent[]
local function showPostSimulation(viewElement, reqTable, opponentInfos)
	viewElement:kill(true)

	local rewindObserver = viewElement:addChild({})
	local rewindFrame = UIElement.WorldState.match_frame
	rewindObserver:addCustomDisplay(function()
		if (UIElement.WorldState.match_frame == rewindFrame) then
			TUTORIAL_LEAVEGAME = true
			rewind_replay()
			run_frames(rewindFrame)
			TUTORIAL_LEAVEGAME = false
		end
	end)

	local fightResultsView = viewElement:addChild({
		pos = { -400, 100 },
		size = { 350, viewElement.size.h - 200 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local elementHeight = 40
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(fightResultsView, 60, 135, 20, TB_MENU_DEFAULT_BG_COLOR)
	topBar.shapeType = ROUNDED
	topBar:setRounded({ fightResultsView.roundedInternal[1], 0 })
	botBar.shapeType = ROUNDED
	botBar:setRounded({ 0, fightResultsView.roundedInternal[1] })

	topBar:addChild({ shift = { 20, 10 } }):addAdaptedText("Results", nil, nil, FONTS.BIG, CENTERMID, 0.65, nil, 0.25)

	local exitButton = botBar:addChild({
		pos = { 10, -65 },
		size = { botBar.size.w - 20, 55 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	exitButton:addAdaptedText("exit")
	exitButton:addMouseUpHandler(function()
			Tutorials:quit()
		end)

	local redoButton = botBar:addChild({
		pos = { 10, -125 },
		size = { exitButton.size.w, exitButton.size.h },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	redoButton:addAdaptedText("Redo Opener")
	redoButton:addMouseUpHandler(function()
			Tutorials.CurrentStep.fallback = 4
			Tutorials.ProgressStep = 0
			for _, req in pairs(reqTable) do
				pcall(function() req.ready = true end)
			end
			reqTable.ready = true
		end)

	local listElements = {}
	for _, opponent in ipairs(opponentInfos) do
		local infoHolder = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, infoHolder)
		local opponentView = infoHolder:addChild({
			pos = { 10, 2 },
			size = { infoHolder.size.w - 12, infoHolder.size.h - 4 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		local opponentName = opponentView:addChild({
			pos = { 10, 5 },
			size = { opponentView.size.w * 0.65, opponentView.size.h - 10 }
		})
		opponentName:addAdaptedText(opponent.username, nil, nil, FONTS.MEDIUM, LEFTMID)
		local opponentWinStatus = opponentView:addChild({
			pos = { opponentName.shift.x * 2 + opponentName.size.w, opponentName.shift.y },
			size = { opponentView.size.w - opponentName.shift.x * 3 - opponentName.size.w, opponentName.size.h },
			shadowOffset = 2,
			uiShadowColor = opponent.win == 0 and TB_MENU_DEFAULT_BLUE or UICOLORRED
		})
		opponentWinStatus:addAdaptedText(opponent.win == 0 and "Win" or (opponent.win == 1 and "Loss" or "Draw"), nil, nil, nil, nil, nil, nil, nil, 2)
	end

	if (#listElements * elementHeight > listingHolder.size.h) then
		for _, v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = scrollBar
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
	else
		listingHolder:moveTo(6, nil, true)
	end
end

---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param playerMove MemoryMove
---@param opponentInfos BlindFightOpponent[]
---@param id integer
local function showSimulationResults(viewElement, reqTable, playerMove, opponentInfos, id)
	viewElement:kill(true)

	TUTORIAL_LEAVEGAME = true
	start_new_game()
	TUTORIAL_LEAVEGAME = false

	UIElement.WorldState = get_world_state()
	runCmd("lp 1 " .. opponentInfos[id].username)
	Tutorials:setOption("hint", 0)

	playerMove.currentturn = 1
	opponentInfos[id].opener.currentturn = 1

	local step = 0
	local frame = 0
	local endframe = UIElement.WorldState.game_frame
	local gameObserver = viewElement:addChild({})
	local spawnVictoryText = function()
		local victoryText = gameObserver:addChild({
			pos = { -1, WIN_H / 2 - 20 },
			size = { 500, 40 },
			uiColor = UIElement.WorldState.winner == -1 and TB_MENU_DEFAULT_DARKEST_COLOR or (UIElement.WorldState.winner == 0 and TB_MENU_DEFAULT_BLUE or TB_MENU_DEFAULT_BG_COLOR),
			uiShadowColor = UICOLORWHITE,
			shadowOffset = 4
		})
		local spawnClock = UIElement.clock
		local victoryTextString = UIElement.WorldState.winner == -1 and "Draw!" or (UIElement.WorldState.winner == 0 and "Victory!" or "Loss!")
		victoryText:addCustomDisplay(function()
				if (spawnClock + 0.25 > UIElement.clock) then
					victoryText:moveTo(UITween.SineTween(victoryText.shift.x, -gameObserver.size.w / 2 - victoryText.size.w * 0.35, (UIElement.clock - spawnClock) * 4))
				elseif (spawnClock + 1.25 < UIElement.clock) then
					victoryText:moveTo(UITween.SineTween(victoryText.shift.x, -WIN_W - victoryText.size.w, (UIElement.clock - spawnClock - 1.25) * 4))
				else
					victoryText:moveTo(-2, nil, true)
				end
				victoryText:uiText(victoryTextString, nil, nil, FONTS.BIG, CENTERMID, nil, nil, 4)
			end)
	end
	gameObserver:addCustomDisplay(function()
		if (UIElement.WorldState.winner > -1 and UIElement.WorldState.match_frame < endframe) then
			endframe = UIElement.WorldState.match_frame
		end
		if (UIElement.WorldState.match_frame == endframe) then
			spawnVictoryText()
		end
		if (endframe + 90 < UIElement.WorldState.match_frame) then
			local rplName = "blindfight/blindfight-" .. os.date("%Y%m%d-%H%M%S", os.time()) .. "-" .. opponentInfos[id].username
			Files.WriteDebug("Saving replay as " .. rplName .. ": winner " .. UIElement.WorldState.winner)
			runCmd("savereplay ../" .. rplName)
			if (#opponentInfos > id) then
				showSimulationResults(viewElement, reqTable, playerMove, opponentInfos, id + 1)
			else
				showPostSimulation(viewElement, reqTable, opponentInfos)
			end
		elseif (endframe > UIElement.WorldState.match_frame) then
			if (UIElement.WorldState.match_frame == frame) then
				frame = frame + get_turn_frame(step)
				step = step + 1
			elseif (UIElement.WorldState.match_frame < frame) then
				if (playerMove.currentturn == step) then
					MoveMemory:playMove(playerMove, false, 0, true)
					MoveMemory:playMove(opponentInfos[id].opener, false, 1, true)
				end
				step_game(true)
			end
		end
	end)
end

---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param moveData MemoryMove
---@param onError function
local function submitMove(viewElement, reqTable, moveData, onError)
	Request:queue(function()
			Files.WriteDebug("submitting moves to server")
			local openerString = table.implode(moveData:toOpener(), ":")
			openerString = string.gsub(openerString, "+", "%%2b")
			---@diagnostic disable-next-line: undefined-global
			submit_blindfight_move(openerString)
		end, "blindfight_submit", function()
			if (not TUTORIAL_ISACTIVE) then Files.WriteDebug("tutorial not active") return end
			local response = get_network_response()
			Files.WriteDebug(response)
			if (string.find(response, "^ERROR")) then
				onError()
				TBMenu:showStatusMessage("Error submitting your move, please try again.\nIf the error persists, please contact support.")
				return
			end
			local opponentInfos = {}
			local autoupdate = get_option("autoupdate")
			for ln in response:gmatch("[^\n]*\n") do
				local _, segments = ln:gsub("\t", "")
				local data = { ln:match(("([^\t]*)\t?"):rep(segments)) }
				table.insert(opponentInfos, {
					username = data[1],
					opener = MemoryMove.FromOpener(string.explode(data[2], ':')),
					win = tonumber(data[3]) or 2
				})
				if (autoupdate == 1) then
					download_head(data[1])
				end
			end
			showSimulationResults(viewElement, reqTable, moveData, opponentInfos, 1)
		end, function()
			Files.WriteDebug(get_network_error())
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORTRYAGAIN .. "\n(" .. get_network_error() .. ")")
			onError()
		end)
end

---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
local function onRecordingComplete(viewElement, reqTable)
	local req = { type = "completeRecording", ready = false }
	table.insert(reqTable, req)

	local moveData = MemoryMove.FromData(MoveMemory.Recording[0])
	MoveMemory:cancelRecording(0)


	local currentFrame = UIElement.WorldState.match_frame + get_turn_frame(3) + 40
	run_frames(get_turn_frame(3) + 40)
	viewElement:addChild({}):addCustomDisplay(function()
			if (UIElement.WorldState.match_frame == currentFrame) then
				TUTORIAL_LEAVEGAME = true
				rewind_replay()
				run_frames(currentFrame)
				TUTORIAL_LEAVEGAME = false
			end
		end)

	local showButtons
	local waitView
	showButtons = function()
		Files.WriteDebug("showButtons")
		if (waitView ~= nil) then
			Files.WriteDebug("hiding waitView")
			waitView:hide()
		end
		local buttonWidth = math.min(390, WIN_W / 2 - (is_mobile() and TBHud.DefaultButtonSize * 3.5 or 100))
		local redoMoveButton = viewElement:addChild({
			pos = { viewElement.size.w / 2 - buttonWidth - 10, -math.max(50, SAFE_Y) - 75 },
			size = { buttonWidth, 75 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		redoMoveButton:addAdaptedText("Redo Opener")
		redoMoveButton:addMouseUpHandler(function()
				Tutorials.CurrentStep.fallback = 4
				Tutorials.ProgressStep = 0
				req.ready = true
				reqTable.ready = true
			end)
		local submitMoveButton = viewElement:addChild({
			pos = { viewElement.size.w / 2 + 10, redoMoveButton.shift.y },
			size = { redoMoveButton.size.w, redoMoveButton.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		submitMoveButton:addAdaptedText("Submit Opener")
		submitMoveButton:addMouseUpHandler(function()
				submitMove(viewElement, reqTable, moveData, showButtons)
				redoMoveButton:kill()
				submitMoveButton:kill()
				if (waitView == nil) then
					waitView = viewElement:addChild({
						pos = { viewElement.size.w / 2 - 300, -125 },
						size = { 600, 75 },
						bgColor = TB_MENU_DEFAULT_BG_COLOR,
						shapeType = ROUNDED,
						rounded = 4
					})
					TBMenu:displayLoadingMark(waitView)
				else
					waitView:show()
				end
			end)
	end
	showButtons()
end

---@diagnostic disable-next-line: lowercase-global
functions = {
	WaitSpace = requireKeyPressSpace,
	WaitSpaceConsume = requireKeyPressSpaceConsume,
	BeginRecording = beginRecording,
	OnRecordingComplete = onRecordingComplete
}
