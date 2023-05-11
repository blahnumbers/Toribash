local function launchUkeBehavior()
	usage_event("tutorial4fight")
	require("system.movememory_manager")

	local moveBase = {
		{
			name = "G-Kick",
			desc = "Gman80's aikido kick",
			message = "GMANKICK",
			mod = "aikido",
			{ grip = { 1, 0 }, joint = { 3, 2, 3, 3, 2, 3, 3, 1, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 3, 3 } },
			{ grip = { 1, 0 }, joint = { 3, 2, 3, 3, 2, 3, 3, 1, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 3, 3 } },
			{ grip = { 0, 0 }, joint = { 3, 2, 3, 3, 2, 3, 3, 1, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 3, 3 } },
			{ grip = { 0, 0 }, joint = { 3, 2, 3, 3, 3, 3, 3, 1, 3, 3, 3, 3, 2, 1, 3, 3, 3, 3, 3, 3 } },
			{ grip = { 0, 0 }, joint = { 3, 2, 3, 3, 3, 3, 3, 1, 3, 3, 3, 3, 2, 3, 3, 3, 3, 3, 3, 3 } },
		},
		{
			name = "Kick lift",
			desc = "Fnugget's infamous aikido kick lift",
			message = "FNUGGETKICK",
			mod = "aikido",
			{ grip = { 0, 1 }, joint = { 1, 1, 1, 2, 1, 3, 2, 2, 4, 4, 1, 4, 2, 2, 1, 2, 2, 3, 2, 2 } },
			{ grip = { 0, 1 }, joint = { 1, 1, 1, 3, 1, 3, 2, 2, 2, 1, 1, 1, 2, 2, 1, 2, 1, 3, 2, 2 } },
			{ grip = { 0, 1 }, joint = { 1, 4, 2, 1, 4, 1, 1, 4, 2, 1, 1, 1, 1, 2, 1, 2, 2, 1, 1, 4 } },
		},
		{
			name = "Floor throw",
			desc = "Aikido throw by evilperson",
			message = "EVILTHROW",
			mod = "aikido",
			{ grip = { 0, 0 }, joint = { 4, 4, 4, 4, 2, 4, 4, 2, 4, 4, 4, 4, 2, 2, 4, 4, 2, 2, 4, 4 } },
			{ grip = { 1, 1 }, joint = { 3, 2, 3, 3, 4, 3, 3, 4, 3, 4, 3, 3, 2, 3, 4, 1, 3, 3, 3, 3 } },
			{ grip = { 1, 1 }, joint = { 3, 1, 2, 3, 1, 3, 2, 2, 3, 4, 3, 3, 2, 1, 2, 2, 1, 4, 3, 1 } },
			{ grip = { 1, 1 }, joint = { 3, 1, 2, 2, 1, 1, 2, 2, 2, 4, 3, 3, 1, 2, 2, 2, 1, 4, 3, 1 } },
			{ grip = { 1, 1 }, joint = { 3, 1, 2, 2, 1, 2, 2, 2, 2, 4, 3, 3, 2, 2, 1, 2, 4, 4, 2, 1 } },
			{ grip = { 1, 1 }, joint = { 3, 1, 2, 2, 1, 2, 1, 2, 2, 2, 2, 3, 1, 1, 2, 2, 2, 4, 2, 2 } },
		},
		{
			name = "Kyat's Kick Lift",
			desc = "Aikido kick lift by Kyat",
			message = "KYATKICKLIFT",
			mod = "aikido",
			{ grip = { 1, 0 }, joint = { 3, 2, 2, 3, 2, 3, 3, 1, 3, 3, 1, 3, 2, 2, 2, 1, 3, 2, 3, 3 } },
			{ grip = { 1, 0 }, joint = { 3, 2, 2, 3, 2, 3, 3, 1, 3, 3, 1, 3, 2, 2, 2, 1, 3, 1, 3, 3 } },
			{ grip = { 1, 0 }, joint = { 3, 2, 2, 3, 2, 2, 3, 1, 3, 3, 1, 3, 1, 1, 2, 3, 3, 1, 3, 3 } },
			{ grip = { 1, 0 }, joint = { 3, 2, 2, 3, 2, 2, 3, 4, 3, 3, 1, 3, 1, 1, 2, 3, 3, 1, 3, 3 } },
		},
		{
			name = "Floor push",
			desc = "Evilperson's aikido floor push",
			message = "EVILPUSH",
			mod = "aikido",
			{ grip = { 0, 0 }, joint = { 4, 4, 4, 4, 2, 4, 4, 2, 4, 4, 4, 4, 2, 2, 4, 4, 2, 2, 4, 4 } },
			{ grip = { 1, 1 }, joint = { 3, 2, 3, 3, 4, 3, 3, 4, 3, 3, 3, 3, 3, 3, 4, 1, 4, 3, 3, 3 } },
			{ grip = { 1, 1 }, joint = { 3, 2, 3, 2, 2, 3, 3, 1, 1, 3, 3, 3, 3, 3, 2, 1, 1, 4, 3, 3 } },
			{ grip = { 1, 1 }, joint = { 3, 2, 3, 2, 2, 3, 3, 1, 1, 3, 3, 3, 3, 3, 2, 2, 1, 1, 3, 3 } },
			{ grip = { 1, 1 }, joint = { 3, 2, 1, 2, 2, 3, 3, 1, 1, 2, 3, 1, 3, 3, 2, 2, 1, 1, 3, 3 } },
			{ grip = { 1, 1 }, joint = { 3, 2, 1, 2, 2, 3, 3, 1, 1, 2, 3, 1, 3, 3, 2, 2, 1, 1, 3, 3 } },
			{ grip = { 1, 1 }, joint = { 3, 2, 1, 2, 2, 3, 2, 1, 1, 2, 1, 1, 3, 3, 2, 4, 1, 4, 2, 3 } },
		},
		{
			name = "Dojo push",
			desc = "Evilperson's aikido dojo push",
			message = "EVILPUSH2",
			mod = "aikido",
			{ grip = { 0, 0 }, joint = { 4, 2, 2, 4, 2, 1, 4, 4, 4, 4, 4, 4, 2, 4, 2, 4, 4, 4, 4, 4 } },
			{ grip = { 1, 0 }, joint = { 4, 2, 2, 4, 2, 2, 4, 4, 4, 4, 4, 4, 2, 4, 2, 1, 4, 4, 4, 4 } },
			{ grip = { 1, 1 }, joint = { 4, 1, 2, 4, 1, 2, 4, 2, 2, 4, 4, 4, 1, 1, 1, 2, 1, 1, 4, 1 } },
			{ grip = { 1, 1 }, joint = { 4, 1, 2, 4, 1, 2, 4, 2, 2, 4, 4, 4, 1, 1, 1, 2, 1, 1, 4, 1 } },
			{ grip = { 1, 1 }, joint = { 4, 1, 1, 4, 1, 2, 4, 2, 1, 4, 4, 4, 2, 1, 1, 1, 1, 1, 4, 1 } },
		}
	}

	local comboId = math.random(1, #moveBase)
	local selectedMove = moveBase[comboId]

	---@type MemoryMove
	local ukeMove = { movements = {}, name = selectedMove.name, mod = selectedMove.mod, desc = selectedMove.desc, message = selectedMove.message }
	for i, turn in pairs(selectedMove) do
		if (type(i) == "number") then
			ukeMove.movements[i] = {}
			for joint, state in pairs(turn.joint) do
				ukeMove.movements[i][joint - 1] = state
			end
			ukeMove.movements[i][20] = turn.grip[1]
			ukeMove.movements[i][21] = turn.grip[2]
			ukeMove.turns = i
		end
	end
	setmetatable(ukeMove, MemoryMove)
	FIGHTUKE_MOVE = ukeMove

	MoveMemory:playMove(ukeMove, true, 1, true)
end

local function challengeUke(viewElement, reqTable)
	FIGHTUKE_GAME_ENDED = false
	GAME_COUNT = GAME_COUNT or 0
	MOVEMEMORY_USED = MOVEMEMORY_USED or false
	---@diagnostic disable-next-line: assign-type-mismatch
	FIGHTUKE_MOVE = nil
	local endless = false
	local leaveGame = false

	launchUkeBehavior()
	local configTutorial = Tutorials:getConfig()
	if (configTutorial > Tutorials.CurrentTutorial) then
		endless = true
	end
	remove_hook("draw2d", "tbTutorialsCustomStatic")
	add_hook("leave_game", "tbTutorialsCustomStatic", function()
			if (TUTORIAL_LEAVEGAME) then
				return 1
			end
		end)
	add_hook("key_up", "tbTutorialsCustom", function(key)
			if (get_shift_key_state() > 0 or get_keyboard_ctrl() > 0 or get_keyboard_alt() > 0) then
				return 1
			elseif (key == 109) then
				MOVEMEMORY_USED = true
			end
	end)
	add_hook("end_game", "tbTutorialsCustom", function() FIGHTUKE_GAME_ENDED = true end)
	add_hook("draw2d", "tbTutorialsCustom", function()
			local ws = get_world_state()
			local frame = ws.match_frame
			if ((ws.winner > -1 or FIGHTUKE_GAME_ENDED) and not leaveGame) then
				leaveGame = true
				GAME_COUNT = GAME_COUNT + 1
				if (ws.winner == 0) then
					if (not MoveMemory:isMoveStored(FIGHTUKE_MOVE)) then
						FIGHTUKE_MOVE:writeToFile()
					end
					if (not endless) then
						reqTable.skip = 8
					else
						reqTable.skip = 6
					end
				elseif (GAME_COUNT == 1 and not MOVEMEMORY_USED and not endless) then
					reqTable.skip = 2
				end
				local stopFrame = frame + 97
				local leaveGameHook = false
				add_hook("draw2d", "tbTutorialsCustomStatic", function()
						local wsMatchFrame = get_world_state().match_frame
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

local function enterFreeze()
	freeze_game()
end

local function setMessage(viewElement, reqTable)
	Tutorials:showMessage(viewElement, reqTable, Tutorials.LocalizedMessages[FIGHTUKE_MOVE.message], "Uke")
end

local function showEndScreen()
	RoomList.RefreshIfNeeded()
	local buttons = {
		{ title = "Keep fighting Uke to train your skills and unlock new moves", size = 0.5, shift = 0, image = "../textures/menu/tutorial4.tga", action = function() Tutorials:runTutorial(Tutorials.CurrentTutorial) end },
		{ title = "Put your skills against real players online", size = 0.25, shift = 0, image = "../textures/menu/matchmaking.tga", action = function() Tutorials:beginnerConnect() end },
		{ title = "Return to main menu", size = 0.25, shift = 0, image = "../textures/menu/multiplayer.tga", action = function() Tutorials:quit() end }
	}
	Tutorials:showTutorialEnd(buttons)
end

local function setChallengeIntroSkip(viewElement, reqTable)
	local config = Tutorials:getConfig()
	if (config > Tutorials.CurrentTutorial) then
		reqTable.skip = 6
		Tutorials:reqDelay(viewElement, reqTable, 0)
	else
		Tutorials:reqDelay(viewElement, reqTable, 0)
	end
end

return {
	ChallengeUke = challengeUke,
	FreezeGame = enterFreeze,
	SetUkeMessage = setMessage,
	EndingScreen = showEndScreen,
	SetChallengeIntro = setChallengeIntroSkip
}
