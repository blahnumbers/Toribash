---BLINDFIGHT

---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
local function requireKeyPressSpace(viewElement, reqTable)
	local req = { type = "keypress", ready = false }
	table.insert(reqTable, req)

	if (is_mobile()) then
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

	add_hook("key_up", Tutorials.StepHook, function(s, code)
		if (string.schar(s) == " " or (code > 3 and code < 30 and string.schar(code + 93) == " ")) then
			req.ready = true
			reqTable.ready = Tutorials:checkRequirements(reqTable)
		end
	end)
end

---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
local function requireKeyPressSpaceFirst(viewElement, reqTable)
	requireKeyPressSpace(viewElement, reqTable)
	if (Events.BlindFightMode == 2) then
		Tutorials:showMessageWindow(reqTable)
		Tutorials:showMessage(viewElement, reqTable, TB_MENU_LOCALIZED.BLINDFIGHTINFOHINT, "SENSEI")
	end
end

local function quit()
	MoveMemory:cancelRecording(0)
	add_hook("pre_draw", Tutorials.HookName, function()
		close_menu()
		Tutorials:quit()
	end)
end

local function onExit()
	if (Tutorials.QuitOverlay) then
		Tutorials.QuitOverlay:kill()
		Tutorials.QuitOverlay = nil
		return
	end
	if (Tutorials.CurrentStep.id < 3 or Tutorials.CurrentStep.id == 7) then
		quit()
		return
	end
	if (Tutorials.CurrentStep.id < 6) then
		Tutorials.QuitOverlay = TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.BLINDFIGHTLEAVINGPROMPT, quit, function()
				close_menu()
				TUTORIAL_LEAVEGAME = false
			end, nil, nil, Tutorials.Globalid)
		return
	end

	---Disallow exiting in other cases
	add_hook("pre_draw", Tutorials.HookName, function()
			TUTORIAL_LEAVEGAME = true
			close_menu()
			TUTORIAL_LEAVEGAME = false
			remove_hook("pre_draw", Tutorials.HookName)
		end)
end

---@param viewElement UIElement
---@param message string
local function showErrorBox(viewElement, message)
	local overlay = viewElement:addChild({
		interactive = true,
		bgColor = { 1, 1, 1, 1 }
	})
	local maxWidth = math.min(overlay.size.w * 0.6, 700)
	local messageHolder = overlay:addChild({
		pos = { (overlay.size.w - maxWidth) / 2, overlay.size.h / 2 - 90 },
		size = { maxWidth, 180 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	messageHolder:addChild({ pos = { 10, 10 }, size = { messageHolder.size.w - 20, messageHolder.size.h - 85 } }):addAdaptedText(message)
	local okButton = messageHolder:addChild({
		pos = { messageHolder.size.w / 4, -65 },
		size = { messageHolder.size.w / 2, 55 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	okButton:addAdaptedText(TB_MENU_LOCALIZED.BUTTONOK)
	okButton:addMouseUpHandler(function()
			overlay:kill()
			quit()
		end)
end

---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
local function showEventInfo(viewElement, reqTable)
	local req = { type = "info", ready = false }
	table.insert(reqTable, req)

	local overlay = viewElement:addChild({ bgColor = { 1, 1, 1, 1 }, interactive = true })
	local messages = {
		Tutorials.LocalizedMessages['INTRO1'],
		utf8.gsub(Tutorials.LocalizedMessages['INTRO2'], "{modname}", Events.GetBlindFight().modName),
		Tutorials.LocalizedMessages['INTRO3'],
		Tutorials.LocalizedMessages['INTRO4'],
		Tutorials.LocalizedMessages['INTRO5'],
		Tutorials.LocalizedMessages['INTRO6'],
	}
	---@type UIElement[]
	local messageElements = {}
	local totalHeight = 0
	local fontMod = getFontMod(FONTS.LMEDIUM + 10) * 10

	local testMessage = overlay:addChild({
		shift = { overlay.size.w * 0.2, overlay.size.h * 0.15 }, uiColor = UICOLORWHITE
	})
	local testMessageStr = "";
	for _, v in ipairs(messages) do
		testMessageStr = testMessageStr .. v .. "\n\n"
	end
	testMessage:addAdaptedText(testMessageStr, { font = FONTS.LMEDIUM + 10 })
	local targetScale = testMessage.textScale
	testMessage:kill()
	for _, v in ipairs(messages) do
		local messageElement = overlay:addChild({
			shift = { overlay.size.w * 0.2, overlay.size.h * 0.13 },
			uiColor = { 0, 0, 0, 0 }
		})
		table.insert(messageElements, messageElement)
		messageElement:addAdaptedText(v, { font = FONTS.LMEDIUM + 10, maxscale = targetScale })
		local lines = #messageElement.dispstr
		messageElement.size.h = fontMod * targetScale * (lines + 1)
		totalHeight = totalHeight + messageElement.size.h
	end

	local function waitAnimateOut()
		local req2 = { type = "animateOut", ready = false }
		table.insert(reqTable, req2)
		local beginClock = 0
		overlay:addCustomDisplay(function()
				for _, v in pairs(reqTable) do
					if (type(v) == "table" and v.ready == false and v.type ~= req2.type) then
						return
					end
				end
				if (beginClock == 0) then
					Tutorials:hideWaitButton()
					beginClock = UIElement.clock
				end
				overlay.bgColor[4] = UITween.SineTween(overlay.bgColor[4], 0, UIElement.clock - beginClock)
				for _, v in pairs(messageElements) do
					v.uiColor[4] = overlay.bgColor[4]
				end
				if (overlay.bgColor[4] == 0) then
					req2.ready = true
					reqTable.ready = true
				end
			end, true)
	end

	local anchorPos = (overlay.size.h - totalHeight) / 2
	local currentObserver = nil
	for i, v in ipairs(messageElements) do
		v:moveTo(nil, anchorPos)
		anchorPos = anchorPos + v.size.h
		local observer = v:addChild({})
		observer:addCustomDisplay(true, function(init)
			if (init == true) then return end
			currentObserver = observer
			if (v.uiColor[4] < 1) then
				v.uiColor[4] = math.ceil(UITween.SineTween(v.uiColor[4], 1, UIElement.deltaClock * 12) * 1000) / 1000
			else
				if (i == #messageElements) then
					req.ready = true
					Tutorials:reqButton(reqTable)
					waitAnimateOut()
				else
					messageElements[i + 1]:show()
				end
				observer:kill()
				currentObserver = nil
			end
		end)
		v:hide()
	end
	overlay:addMouseDownHandler(function()
			if (currentObserver ~= nil) then
				currentObserver.parent.uiColor[4] = 1
			end
		end)
	messageElements[1]:show()
	Tutorials:showWaitButton()
end

---Sets RPG values and required gamerules for the upcoming game
---@param userRPG BlindFightRPG
---@param opponentRPG ?BlindFightRPG
local function resetGame(userRPG, opponentRPG)
	opponentRPG = opponentRPG or { strength = 100, speed = 100, endurance = 100 }
	rpg_state(true)
	set_rpg(0, userRPG.strength, userRPG.speed, userRPG.endurance)
	set_rpg(1, opponentRPG.strength, opponentRPG.speed, opponentRPG.endurance)
	start_new_game()

	---Max contacts need to be set after new game with cur prefix!
	---Otherwise they get rewritten due to how gamerules are initialized with RPG enabled
	set_gamerule("curmaxcontacts", "32")
end

local function initialize(viewElement, reqTable)
	local currentVersion = tonumber(_G.BUILD_VERSION) or 0
	local blindFight = Events.GetBlindFight()
	if (blindFight == nil or blindFight.modName == nil or (blindFight.minVersion and blindFight.minVersion > currentVersion)) then
		local req = { type = "exit", ready = false }
		table.insert(reqTable, req)
		
		local errorMessage = TB_MENU_LOCALIZED.BLINDFIGHTDATAERROR
		if (Events ~= nil and blindFight ~= nil and blindFight.minVersion and blindFight.minVersion > currentVersion) then
			errorMessage = TB_MENU_LOCALIZED.BLINDFIGHTUPDATECLIENT
		end
		showErrorBox(viewElement, errorMessage)
		return
	end

	--[[local blindfightDirectoryExists = false
	for _, v in ipairs(get_folders("replay")) do
		if (v == 'blindfight') then
			blindfightDirectoryExists = true
			break
		end
	end
	if (not blindfightDirectoryExists) then
		add_replay_subfolder("blindfight")
	end]]

	Tutorials:setQuitPopupOverride(onExit)

	select_player(0, false)
	TUTORIAL_LEAVEGAME = true
	runCmd("lm " .. blindFight.modName)
	resetGame(blindFight.userRPG, nil)
	TUTORIAL_LEAVEGAME = false

	if (Events.BlindFightMode == 1) then
		Tutorials.CurrentStep.skip = 4
		return
	end

	Tutorials.CurrentStep.skip = 0
	MoveMemory:recordMove(false)
	if (Events.BlindFightMode == 2) then
		showEventInfo(viewElement, reqTable)
	elseif (Events.GetConfig("BlindFightPlays") > 2 or Events.BlindFightMode == 10) then
		set_hint_override(TB_MENU_LOCALIZED.BLINDFIGHTINFOHINT)
	else
		Tutorials:showMessageWindow(reqTable)
		Tutorials:showMessage(viewElement, reqTable, TB_MENU_LOCALIZED.BLINDFIGHTINFOHINT, "SENSEI")
	end
end

---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
local function showVictoryScreen(viewElement, reqTable)
	local overlay = viewElement:addChild({ bgColor = { 1, 1, 1, 0.01 } })
	local spawnClock = UIElement.clock
	overlay:addCustomDisplay(function()
			if (overlay.bgColor[4] < 0.9) then
				overlay.bgColor[4] = UITween.SineTween(0, 0.9, UIElement.clock - spawnClock)
			else
				overlay.customDisplay = nil
			end
		end)
	Events:showBlindFightPromotion(overlay, Events.BlindFightRewards, function() Tutorials:quit() request_app_review() end)
	Events.BlindFightRewards = nil
end

---@class BlindFightOpponent
---@field username string
---@field opener MemoryMove
---@field win integer
---@field rpg BlindFightRPG

---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
local function showPostSimulation(viewElement, reqTable)
	viewElement:kill(true)
	Tutorials.CurrentStep.fallback = nil

	local rewindObserver = viewElement:addChild({})
	local rewindFrame = UIElement.WorldState.match_frame
	rewindObserver:addCustomDisplay(function()
		if (UIElement.WorldState.match_frame >= rewindFrame) then
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

	topBar:addChild({ shift = { 20, 10 } }):addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTRESULTS, {
		font = FONTS.BIG, align = CENTERMID, maxscale = 0.65, intensity = 0.25
	})

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
	exitButton:addAdaptedText(TB_MENU_LOCALIZED.NAVBUTTONEXIT)
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
	redoButton:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTREDOOPENER)
	redoButton:addMouseUpHandler(function()
			Tutorials.CurrentStep.fallback = 6
			Tutorials.ProgressStep = 0
			for _, req in pairs(reqTable) do
				pcall(function() req.ready = true end)
			end
			reqTable.ready = true
		end)

	local listElements = {}
	for _, opponent in ipairs(Events.BlindFightOpponents) do
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
		local winMessage = opponent.win == 0 and TB_MENU_LOCALIZED.BLINDFIGHTWIN or (opponent.win == 1 and TB_MENU_LOCALIZED.BLINDFIGHTLOSS or TB_MENU_LOCALIZED.BLINDFIGHTDRAW)
		opponentWinStatus:addAdaptedText(winMessage, { shadow = 2 })
	end
	Events.BlindFightOpponents = nil

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
---@param rewardsEarned BlindFightReward[]
---@param id integer
local function showSimulationResults(viewElement, reqTable, playerMove, opponentInfos, rewardsEarned, id)
	viewElement:kill(true)

	local blindFight = Events.GetBlindFight()
	if (blindFight == nil) then
		quit()
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.BLINDFIGHTDATAERROR)
		return
	end

	TUTORIAL_LEAVEGAME = true
	resetGame(blindFight.userRPG, opponentInfos[id].rpg)
	TUTORIAL_LEAVEGAME = false

	UIElement.WorldState = get_world_state()
	runCmd("lp 1 " .. opponentInfos[id].username)

	playerMove.currentturn = 1
	opponentInfos[id].opener.currentturn = 1

	local step = 0
	local frame = 0
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
		local victoryTextString = UIElement.WorldState.winner == -1 and TB_MENU_LOCALIZED.BLINDFIGHTDRAW or (UIElement.WorldState.winner == 0 and TB_MENU_LOCALIZED.BLINDFIGHTWIN or TB_MENU_LOCALIZED.BLINDFIGHTLOSS)
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
	local victoryTextSpawned = false
	add_hook("pre_draw", "__blindFightManager", function()
		if (UIElement.WorldState.gameover_frame == -1) then
			if (UIElement.WorldState.match_frame == frame) then
				frame = frame + get_turn_frame(step)
				step = step + 1
			end
			if (UIElement.WorldState.match_frame < frame) then
				if (playerMove.currentturn == step) then
					MoveMemory:playMove(playerMove, false, 0, true)
					MoveMemory:playMove(opponentInfos[id].opener, false, 1, true)
				end
				step_game(true, true)
			end
		else
			if (UIElement.WorldState.match_frame >= UIElement.WorldState.gameover_frame and not victoryTextSpawned) then
				victoryTextSpawned = true
				spawnVictoryText()
			elseif (UIElement.WorldState.gameover_frame + 90 < UIElement.WorldState.match_frame) then
				--[[local rplName = "blindfight/blindfight-" .. os.date("%Y%m%d-%H%M%S", os.time()) .. "-" .. opponentInfos[id].username
				runCmd("savereplay ../" .. rplName)]]
				remove_hook("pre_draw", "__blindFightManager")
				if (#opponentInfos > id) then
					showSimulationResults(viewElement, reqTable, playerMove, opponentInfos, rewardsEarned, id + 1)
				else
					if (not table.empty(rewardsEarned)) then
						Tutorials.CurrentStep.skip = 1
					end
					Events.BlindFightRewards = rewardsEarned
					Events.BlindFightOpponents = opponentInfos
					for _, req in pairs(reqTable) do
						pcall(function() req.ready = true end)
					end
					reqTable.ready = true
				end
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
			local openerString = table.implode(moveData:toOpener(), ":")
			openerString = string.gsub(openerString, "+", "%%2b")
			---@diagnostic disable-next-line: undefined-global
			submit_blindfight_move(openerString)
		end, "blindfight_submit", function(_, response)
			if (string.find(response, "^ERROR")) then
				onError()
				return
			end
			local opponentInfos = {}
			local rewardsEarned = {}
			local autoupdate = get_option("autoupdate")
			for ln in response:gmatch("[^\n]*\n") do
				if (ln:find("^LEAGUE_PROMOTED_REWARDS")) then
					rewardsEarned = Events.ParseBlindFightRewards(ln)
				else
					local _, segments = ln:gsub("\t", "")
					local data = { ln:match(("([^\t]*)\t?"):rep(segments)) }
					table.insert(opponentInfos, {
						username = data[1],
						opener = MemoryMove.FromOpener(string.explode(data[2], ':')),
						win = tonumber(data[3]) or 2,
						rpg = {
							strength = tonumber(data[4]) or 0,
							speed = tonumber(data[5]) or 0,
							endurance = tonumber(data[6]) or 0
						}
					})
					if (autoupdate == 1) then
						download_head(data[1])
					end
				end
			end
			TB_MENU_SPECIAL_SCREEN_ISOPEN = 12
			showSimulationResults(viewElement, reqTable, moveData, opponentInfos, rewardsEarned, 1)
			Events.SetConfig("BlindFightPlays", Events.GetConfig("BlindFightPlays") + 1)
			Events:refreshBlindFight()
		end, function(_, error)
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORTRYAGAIN .. "\n(" .. error .. ")")
			onError()
		end)
end

---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
local function onRecordingComplete(viewElement, reqTable)
	Tutorials.CurrentStep.fallback = nil

	local req = { type = "completeRecording", ready = false }
	table.insert(reqTable, req)

	local blindFight = Events.GetBlindFight()
	if (blindFight ~= nil and Events.BlindFightMode == 1 and blindFight.userMoves ~= nil) then
		local overlay = viewElement:addChild({ bgColor = UICOLORWHITE, interactive = true, uiColor = UICOLORBLACK })
		TBMenu:displayLoadingMark(overlay, TB_MENU_LOCALIZED.BLINDFIGHTSIMULATING)
		submitMove(viewElement, reqTable, blindFight.userMoves, function()
				overlay:kill()
				showErrorBox(viewElement, TB_MENU_LOCALIZED.BLINDFIGHTERRORSUBMITTINGMOVE)
			end)
		Events.BlindFightMode = 0
		return
	end

	if (MoveMemory.Recording[0] == nil) then
		MoveMemory:cancelRecording(0)
		Tutorials:quit()
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.BLINDFIGHTERROREMPTYRECORDING)
		return
	end
	local moveData = MemoryMove.FromData(MoveMemory.Recording[0])
	MoveMemory:cancelRecording(0)

	local currentFrame = UIElement.WorldState.match_frame + get_turn_frame(3) + 40
	run_frames(get_turn_frame(3) + 40)
	viewElement:addChild({}):addCustomDisplay(function()
			if (UIElement.WorldState.match_frame >= currentFrame) then
				TUTORIAL_LEAVEGAME = true
				rewind_replay()
				run_frames(currentFrame)
				TUTORIAL_LEAVEGAME = false
			end
		end)

	local showButtons
	local waitView
	showButtons = function()
		if (waitView ~= nil) then
			waitView:hide()
		end
		local buttonWidth = math.min(390, WIN_W / 2 - (is_mobile() and TBHud.DefaultButtonSize * 1.5 or 100))
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
		redoMoveButton:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTREDOOPENER)
		redoMoveButton:addMouseUpHandler(function()
				Tutorials.CurrentStep.fallback = 5
				Tutorials.ProgressStep = 0
				req.ready = true
				reqTable.ready = true
				Events.BlindFightMode = 10
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
		submitMoveButton:addAdaptedText(TB_MENU_LOCALIZED.BLINDFIGHTSUBMITMOVES)
		submitMoveButton:addMouseUpHandler(function()
				submitMove(viewElement, reqTable, moveData, function()
					showButtons()
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.BLINDFIGHTERRORSUBMITTINGMOVE)
				end)
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
return {
	WaitSpace = requireKeyPressSpace,
	WaitSpaceFirst = requireKeyPressSpaceFirst,
	Initialize = initialize,
	OnRecordingComplete = onRecordingComplete,
	DisplayResults = showPostSimulation,
	DisplayVictory = showVictoryScreen
}
