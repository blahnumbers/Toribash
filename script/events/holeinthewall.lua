local INTRO = 1
local OUTRO = -1

local function showOverlay(viewElement, reqTable, out, speed)
	local speed = speed or 1
	local req = { type = "transition", ready = false }
	table.insert(reqTable, req)
	
	if (tbOutOverlay) then
		tbOutOverlay:kill()
	end
	local overlay = UIElement:new({
		parent = out and tbTutorialsOverlay or viewElement,
		pos = { 0, 0 },
		size = { viewElement.size.w, viewElement.size.h },
		bgColor = cloneTable(UICOLORWHITE)
	})
	if (out) then
		tbOutOverlay = overlay
	end
	overlay.bgColor[4] = out and 0 or 1
	overlay:addCustomDisplay(true, function()
			overlay.bgColor[4] = overlay.bgColor[4] + (out and 0.02 or -0.02) * speed
			if (not out and overlay.bgColor[4] <= 0) then
				req.ready = true
				reqTable.ready = Tutorials:checkRequirements(reqTable)
				overlay:kill()
			elseif (out and overlay.bgColor[4] >= 1) then
				req.ready = true
				reqTable.ready = Tutorials:checkRequirements(reqTable)
			end
			set_color(unpack(overlay.bgColor))
			draw_quad(overlay.pos.x, overlay.pos.y, overlay.size.w, overlay.size.h)
		end)
end

local function introOverlay(viewElement, reqTable)
	showOverlay(viewElement, reqTable)
end

local function outroOverlay(viewElement, reqTable)
	showOverlay(viewElement, reqTable, true)
end

local function showUploadWindow(viewElement, reqTable)
	CURRENT_STEP.fallbackrequirement = true
	
	local function uploadReplay(name)
		local name = name:gsub("%.rpl$", ""):gsub("^%/", "")
		if (name == '') then
			TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERROREMPTYNAME, true)
			CURRENT_STEP.fallbackrequirement = false
			reqTable.ready = true
			return false
		end
		UIElement:runCmd("savereplay " .. name)
		open_upload_replay(	TB_MENU_LOCALIZED.REPLAYSUPLOADCONFIRM:gsub("\\n", "\n"),
							name,
							"Event Squad's Hole in the Wall Event entry",
							"#esevent" .. CURRENT_TUTORIAL,
							"replay/my replays/" .. name .. ".rpl"
						)
		
		-- keep step state update in mouse_move hook as it'd only fire after upload window has been closed
		add_hook("mouse_move", "tbTutorialsCustom", function(x, y) 
				if (x < WIN_W / 2) then
					CURRENT_STEP.fallbackrequirement = false
				end
				reqTable.ready = true
			end)
	end
	
	local function cancelUpload()
		CURRENT_STEP.fallbackrequirement = false
		reqTable.ready = true
	end
	
	add_hook("key_down", "tbTutorialsCustom", function(s) UIElement:handleKeyDown(s) return 1 end)
	add_hook("key_up", "tbTutorialsCustom", function(s) UIElement:handleKeyUp(s) return 1 end)
	TBMenu:showConfirmationWindowInput("Uploading event entry", "Enter your replay name", uploadReplay, cancelUpload)
end

local function showSubmitButton(viewElement, reqTable, skipAdd)
	local submitButton = UIElement:new({
		parent = viewElement,
		pos = { WIN_W / 5, -WIN_H / 12 - 50 },
		size = { WIN_W / 5 * 3, WIN_H / 12 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true
	})
	submitButton:addAdaptedText(false, 'Submit Replay')
	submitButton:addMouseHandlers(nil, function()
			freeze_game()
			CURRENT_STEP.skip = skipAdd
			reqTable.ready = true
		end)
	return submitButton
end

local function eventMain(viewElement, reqTable, skipAdd)
	local skipAdd = skipAdd or 0
	TUTORIAL_SPECIAL_RP_IGNORE = true
	
	chat_input_deactivate()
	if (skipAdd == 0) then
		add_hook("leave_game", "tbTutorialsCustomStatic", function()
				if (TUTORIAL_LEAVEGAME) then
					return 1
				end
			end)
		add_hook("key_up", "tbTutorialsCustom", function(key)
				if (get_keyboard_ctrl() > 0 or get_keyboard_alt() > 0) then
					return 1
				end
				if (key == 101) then
					TUTORIAL_LEAVEGAME = true
					edit_game()
					TUTORIAL_LEAVEGAME = false
					REPLAY_CAN_BE_SUBMITTED = false
					return 1
				end
				if (key == 102) then
					dofile("system/replay_save.lua")
					return 1
				end
				if (key == 114) then
					TUTORIAL_LEAVEGAME = true
					rewind_replay()
					TUTORIAL_LEAVEGAME = false
					return 1
				end
				if (key == 32 and get_world_state().replay_mode == 1) then
					TUTORIAL_LEAVEGAME = true
					UIElement:runCmd("lm system/events/holeinthewall.tbm")
					REPLAY_CAN_BE_SUBMITTED = false
					TUTORIAL_LEAVEGAME = false
					return 1
				end
				if (key == 44) then
					set_replay_speed(get_replay_speed() - 0.1)
				elseif (key == 46) then
					set_replay_speed(get_replay_speed() + 0.1)
				end
		end)
	end
	
	local submitButton = nil
	add_hook("draw2d", "tbTutorialsCustom", function()
			local ws = get_world_state()
			if (not submitButton and REPLAY_CAN_BE_SUBMITTED) then
				submitButton = showSubmitButton(viewElement, reqTable, skipAdd)
			elseif (ws.replay_mode == 0) then
				if (submitButton and not REPLAY_CAN_BE_SUBMITTED) then
					submitButton:kill()
					submitButton = nil
				end
				for i,v in pairs(JOINTS) do
					if (get_joint_dismember(0, v)) then
						remove_hook("draw2d", "tbTutorialsCustomStatic")
						REPLAY_CAN_BE_SUBMITTED = false
						freeze_game()
						run_frames(50)
						CURRENT_STEP.skip = 1 + skipAdd
						reqTable.ready = true
						return
					end
				end
			end
			if (ws.winner == 1 and ws.match_frame < ws.game_frame) then
				REPLAY_CAN_BE_SUBMITTED = false
				remove_hook("draw2d", "tbTutorialsCustomStatic")
				freeze_game()
				run_frames(50)
				CURRENT_STEP.skip = 2 + skipAdd
				reqTable.ready = true
				return
			end
			if (ws.match_frame == ws.game_frame) then
				TUTORIAL_LEAVEGAME = true
				rewind_replay()
				TUTORIAL_LEAVEGAME = false
				return
			end
			if (not REPLAY_CAN_BE_SUBMITTED) then
				local criteriaMet = true
				for i,v in pairs(JOINTS) do
					local x, y, z = get_joint_pos(0, v)
					if (y > -20) then
						criteriaMet = false
						break
					end
				end
				if (criteriaMet) then
					REPLAY_CAN_BE_SUBMITTED = true
				end
			end
		end)
end

local function loadExistingReplay(viewElement, reqTable)
	local replay = Files:new("../replay/my replays/--eventtmpholeinthewall.rpl")
	if (not replay.data) then
		reqTable.ready = true
		return false
	end
	local rplData = replay:readAll()
	replay:close()
	
	eventMain(viewElement, reqTable, 2)
	--local framerate = get_option("framerate")
	local steps = {}
	for i, ln in pairs(rplData) do
		if (ln:find("^FRAME %d+")) then
			local rplFrame = ln:gsub("^FRAME ", ""):gsub("%D?;.*$", "")
			table.insert(steps, { frame = tonumber(rplFrame), moves = {} })
			if (#steps ~= 1) then
				steps[#steps - 1].turnLength = steps[#steps].frame - steps[#steps - 1].frame
				--[[if (framerate == 30) then
					steps[#steps - 1].turnLengthAdapted = math.floor(steps[#steps - 1].turnLength / 2) * 2
				end]]
			end
		elseif (ln:find("JOINT 0;")) then
			local jointMoves = ln:gsub("JOINT 0; ", "")
			local _, count = jointMoves:gsub(" ", "")
			count = (count + 1) / 2
			local data_stream = { jointMoves:match(("(%d+ %d+) *"):rep(count)) }
			for i,v in pairs(data_stream) do
				local info = { v:match(("(%d+) *"):rep(2)) }
				steps[#steps].moves[info[1] + 0] = info[2] + 0
			end
		end
	end
	local current_step = 1
	add_hook("draw2d", "tbTutorialsCustomStatic", function()
			local ws = get_world_state()
			if (current_step > #steps) then
				remove_hook("draw2d", "tbTutorialsCustomStatic")
				freeze_game()
				edit_game()
				reqTable.ready = true
			end
			if (ws.match_frame == steps[current_step].frame) then
				for i,v in pairs(steps[current_step].moves) do
					set_joint_state(0, i, v)
				end
				if (current_step ~= #steps) then
					run_frames(steps[current_step].turnLength)
				end
				current_step = current_step + 1
			end
			--[[if ((ws.match_frame == steps[current_step].frame - 1) and steps[current_step - 1].turnLengthAdapted) then
				run_frames(1)
			end]]
		end)
end

local function showEndScreen()
	local buttons = {
		{ title = "Keep fighting Uke to train your skills and unlock new moves", size = 0.5, shift = 0, image = "../textures/menu/tutorial4.tga", action = function() Tutorials:runTutorial(CURRENT_TUTORIAL) end },
		{ title = "Put your skills against real players online", size = 0.25, shift = 0, image = "../textures/menu/matchmaking.tga", action = function() Tutorials:beginnerConnect() end },
		{ title = "Return to main menu", size = 0.25, shift = 0, image = "../textures/menu/multiplayer.tga", action = function() Tutorials:quit() end }
	}
	EventsOnline:showTutorialEnd(buttons)
end

local function launchGame(viewElement, reqTable)
	local req = { type = "newgame", ready = false }
	table.insert(reqTable, req)
	TUTORIAL_LEAVEGAME = true
	
	REPLAY_CAN_BE_SUBMITTED = false
	UIElement:runCmd("lm system/events/holeinthewall.tbm")
	local wipReplay = Files:new("../replay/my replays/--eventtmpholeinthewall.rpl")
	if (wipReplay.data) then
		CURRENT_STEP.skip = 3
		wipReplay:close()
	end
	
	local reqElement = UIElement:new({
		parent = viewElement,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	reqElement:addCustomDisplay(true, function()
			req.ready = true
			reqTable.ready = Tutorials:checkRequirements(reqTable)
			reqElement:kill()
			TUTORIAL_LEAVEGAME = false
		end)
end

local function showYouLostScreen(viewElement, reqTable, offPlatform)
	local holder = UIElement:new({
		parent = viewElement,
		pos = { WIN_W / 6, WIN_H / 2 - 75 },
		size = { WIN_W / 3 * 2, 150 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local title = UIElement:new({
		parent = holder,
		pos = { 10, 5 },
		size = { holder.size.w - 20, 40 }
	})
	title:addAdaptedText(true, "You lost!", nil, nil, FONTS.BIG)
	local message = UIElement:new({
		parent = holder,
		pos = { 10, 50 },
		size = { holder.size.w - 20, 40 }
	})
	message:addAdaptedText(true, offPlatform and "Try to stay on the moving platform next time!" or "Try not to get dismembered next time!")
	local restartButton = UIElement:new({
		parent = holder,
		pos = { 10, 100 },
		size = { holder.size.w / 2 - 15, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	local rewindButton = UIElement:new({
		parent = holder,
		pos = { holder.size.w / 2 + 5, 100 },
		size = { holder.size.w / 2 - 15, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	restartButton:addAdaptedText(false, "New Game")
	rewindButton:addAdaptedText(false, "Rewind This Replay")
	restartButton:addMouseHandlers(nil, function()
			REPLAY_CAN_BE_SUBMITTED = false
			TUTORIAL_LEAVEGAME = true
			UIElement:runCmd("lm system/events/holeinthewall.tbm")
			TUTORIAL_LEAVEGAME = false
			reqTable.ready = true
		end)
	rewindButton:addMouseHandlers(nil, function()
			TUTORIAL_LEAVEGAME = true
			rewind_replay()
			TUTORIAL_LEAVEGAME = false
			reqTable.ready = true
		end)
end

local function showYouLostScreen2(viewElement, reqTable)
	showYouLostScreen(viewElement, reqTable, true)
end

functions = {
	IntroOverlay = introOverlay,
	OutroOverlay = outroOverlay,
	PrepareNewGame = launchGame,
	LoadReplay = loadExistingReplay,
	HoleInTheWall = eventMain,
	UploadEventEntry = showUploadWindow,
	PlayerLostDM = showYouLostScreen,
	PlayerLostOffPlatform = showYouLostScreen2
}
