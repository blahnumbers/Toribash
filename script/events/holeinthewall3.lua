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
		chat_input_deactivate()
		local name = name:gsub("%.rpl$", ""):gsub("^%/", "")
		if (name == '') then
			TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERROREMPTYNAME, true)
			CURRENT_STEP.fallbackrequirement = false
			reqTable.ready = true
			return false
		end
		UIElement:runCmd("savereplay " .. name)
		upload_event_replay(name, "Event Squad's Hole in the Wall Event entry", "ESEVNT" .. CURRENT_TUTORIAL, "replay/my replays/" .. name .. ".rpl")
		local overlay = TBMenu:spawnWindowOverlay()
		local width = overlay.size.w / 7 * 3
		local uploadingView = UIElement:new({
			parent = overlay,
			pos = { (overlay.size.w - width) / 2, overlay.size.h / 2 - overlay.size.h / 10 },
			size = { width, overlay.size.h / 5 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		uploadingView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYUPLOADINPROGRESS)
		Request:new("replayupload", function()
				overlay:kill()
				local response = get_network_response()
				if (response:find("^SUCCESS")) then
					reqTable.ready = true
				else
					TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADERROR .. ": " .. response:gsub("^ERROR 0;", ""), function() showUploadWindow(viewElement, reqTable) end, function() CURRENT_STEP.fallbackrequirement = false reqTable.ready = true end)
				end
			end, function()
				overlay:kill()
				TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADFAILED, function() showUploadWindow(viewElement, reqTable) end, function() CURRENT_STEP.fallbackrequirement = false reqTable.ready = true end)
			end)
	end
	
	local function cancelUpload()
		chat_input_deactivate()
		CURRENT_STEP.fallbackrequirement = false
		reqTable.ready = true
	end
	
	add_hook("key_down", "tbTutorialsCustom", function(s) UIElement:handleKeyDown(s) return 1 end)
	add_hook("key_up", "tbTutorialsCustom", function(s) UIElement:handleKeyUp(s) return 1 end)
	TBMenu:showConfirmationWindowInput(TB_MENU_LOCALIZED.EVENTSUPLOADINGENTRY, TB_MENU_LOCALIZED.REPLAYSENTERNAME, uploadReplay, cancelUpload)
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
	submitButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSUBMIT)
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
		local gameRulesScreen = nil
		add_hook("leave_game", "tbTutorialsCustomStatic", function()
				if (TUTORIAL_LEAVEGAME) then
					return 1
				end
			end)
		add_hook("key_up", "tbTutorialsCustom", function(key)
				if (key == 101) then
					TUTORIAL_LEAVEGAME = true
					STOPFRAME = nil
					edit_game()
					tbTutorialsTaskMark:hide(true)
					TUTORIAL_LEAVEGAME = false
					REPLAY_CAN_BE_SUBMITTED = false
					return 1
				end
				if (key == 102) then
					dofile("system/replay_save.lua")
					return 1
				end
				if (key == 114) then
					STOPFRAME = get_world_state().match_frame
					if (STOPFRAME == 0) then
						STOPFRAME = nil
						return 1
					end
					TUTORIAL_LEAVEGAME = true
					rewind_replay()
					TUTORIAL_LEAVEGAME = false
					return 1
				end
				if (key == 32 and get_world_state().replay_mode == 1) then
					TUTORIAL_LEAVEGAME = true
					STOPFRAME = nil
					UIElement:runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
					REPLAY_CAN_BE_SUBMITTED = false
					TUTORIAL_LEAVEGAME = false
					return 1
				end
				if (key == 44) then
					set_replay_speed(get_replay_speed() - 0.1)
					return 1
				elseif (key == 46) then
					set_replay_speed(get_replay_speed() + 0.1)
					return 1
				end
				if (key == 103 and gameRulesScreen) then
					gameRulesScreen:kill()
					gameRulesScreen = nil
					return 1
				end
				if (get_keyboard_ctrl() > 0 or get_keyboard_alt() > 0) then
					return 1
				end
		end)
		add_hook("key_down", "tbTutorialsCustom", function(key)
				if (key == 103 and not gameRulesScreen) then
					gameRulesScreen = TBMenu:spawnWindowOverlay(TB_TUTORIAL_MODERN_GLOBALID)
					local gameRulesView = UIElement:new({
						parent = gameRulesScreen,
						pos = { WIN_W / 4, WIN_H / 2 - WIN_H / 8 },
						size = { WIN_W / 2, WIN_H / 4 },
						bgColor = TB_MENU_DEFAULT_BG_COLOR
					})
					local gameRules = get_game_rules()
					local rulesTitle = UIElement:new({
						parent = gameRulesView,
						pos = { 0, 10 },
						size = { gameRulesView.size.w, gameRulesView.size.h / 5 }
					})
					rulesTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MAINMENUGAMERULESNAME, nil, nil, FONTS.BIG)
					local rules = {}
					table.insert(rules, { name = "Mod", value = gameRules.mod:gsub("^.*/", "") })
					table.insert(rules, { name = "Gravity", value = gameRules.gravity:gsub("^" .. ("[-]?[%.%d]*%s"):rep(2), "") })
					table.insert(rules, { name = "Dismemberment", value = gameRules.dismemberment == '1' and TB_MENU_LOCALIZED.SETTINGSENABLED or TB_MENU_LOCALIZED.SETTINGSDISABLED })
					if (gameRules.dismemberment == '1') then
						table.insert(rules, { name = "DM Threshold", value = gameRules.dismemberthreshold })
					end
					table.insert(rules, { name = "Fracture", value = gameRules.fracture == '1' and TB_MENU_LOCALIZED.SETTINGSENABLED or TB_MENU_LOCALIZED.SETTINGSDISABLED })
					if (gameRules.fracture == '1') then
						table.insert(rules, { name = "Frac Threshold", value = gameRules.fracturethreshold })
					end
					table.insert(rules, { name = "Grip", value = gameRules.grip == '1' and TB_MENU_LOCALIZED.SETTINGSENABLED or TB_MENU_LOCALIZED.SETTINGSDISABLED })
					
					local posY = rulesTitle.shift.y + rulesTitle.size.h
					for i,v in pairs(rules) do
						local ruleHolder = UIElement:new({
							parent = gameRulesView,
							pos = { 0, posY },
							size = { gameRulesView.size.w, (gameRulesView.size.h - rulesTitle.size.h - rulesTitle.shift.y * 2) / #rules }
						})
						posY = posY + ruleHolder.size.h
						local ruleTitle = UIElement:new({
							parent = ruleHolder,
							pos = { ruleHolder.size.w / 20, ruleHolder.size.h / 10 },
							size = { ruleHolder.size.w * 0.425, ruleHolder.size.h * 0.8 }
						})
						ruleTitle:addAdaptedText(true, v.name, nil, nil, 4, RIGHTMID)
						local ruleValue = UIElement:new({
							parent = ruleHolder,
							pos = { -ruleTitle.size.w - ruleTitle.shift.x, ruleTitle.shift.y },
							size = { ruleTitle.size.w, ruleTitle.size.h }
						})
						ruleValue:addAdaptedText(true, v.value, nil, nil, 4, LEFTMID)
					end					
					return 1
				end
			end)
		
		--[[local customReplayButton = UIElement:new({
			parent = viewElement,
			pos = { -200, 20 },
			size = { 200, 45 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		customReplayButton:addAdaptedText(false, "Load Custom Replay")
		customReplayButton:addMouseHandlers(false, function()
				Replays:getReplayFiles()
			end)]]
	end
	
	local submitButton = nil
	add_hook("draw2d", "tbTutorialsCustom", function()
			local ws = get_world_state()
			if (STOPFRAME) then
				if (ws.match_frame >= STOPFRAME) then
					edit_game()
					STOPFRAME = nil
				end
			end
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
				CURRENT_STEP.skip = 2 + skipAdd
				reqTable.ready = true
				return
			end
			if (ws.match_frame >= ws.game_frame) then
				TUTORIAL_LEAVEGAME = true
				rewind_replay()
				TUTORIAL_LEAVEGAME = false
				return
			end
			if (not REPLAY_CAN_BE_SUBMITTED and ws.replay_mode == 0) then
				local criteriaMet = true
				for i,v in pairs(JOINTS) do
					local x, y, z = get_joint_pos(0, v)
					if (y > -15) then
						criteriaMet = false
						break
					end
				end
				if (criteriaMet) then
					REPLAY_CAN_BE_SUBMITTED = true
					EventsOnline:taskComplete()
				end
			end
		end)
end

local function loadExistingReplay(viewElement, reqTable)
	local replay = Files:open("../replay/my replays/--eventtmp" .. CURRENT_TUTORIAL .. ".rpl")
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
			if (#steps > 0) then
				if (tonumber(rplFrame) < steps[#steps].frame) then
					steps = {}
				end
			end
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

local function launchGame(viewElement, reqTable)
	local req = { type = "newgame", ready = false }
	table.insert(reqTable, req)
	TUTORIAL_LEAVEGAME = true
	download_head("relax")
	
	REPLAY_CAN_BE_SUBMITTED = false
	UIElement:runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
	local wipReplay = Files:open("../replay/my replays/--eventtmp" .. CURRENT_TUTORIAL .. ".rpl")
	if (wipReplay.data) then
		for i,ln in pairs(wipReplay:readAll()) do
			if (ln:find("^JOINT")) then
				CURRENT_STEP.skip = 4
				wipReplay:close()
				break
			end
		end
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
	local scale = WIN_W / 5 > WIN_H / 4 and WIN_H / 4 or WIN_W / 5
	local holder = UIElement:new({
		parent = viewElement,
		pos = { (WIN_W - (scale * 4 + 20)) / 2, -scale - 70 },
		size = { scale * 4 + 20, scale + 20 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local background = UIElement:new({
		parent = holder,
		pos = { 10, 10 },
		size = { holder.size.w - 20, holder.size.h - 20 },
		bgImage = "../textures/menu/promo/events/hitw_youlost2.tga"
	})
	local message = UIElement:new({
		parent = holder,
		pos = { holder.size.w * 0.57, holder.size.h * 0.4 },
		size = { holder.size.w * 0.35, (holder.size.h - 55) * 0.5 },
		uiColor = TB_MENU_DEFAULT_YELLOW,
		uiShadowColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	message:addAdaptedText(true, offPlatform and TB_MENU_LOCALIZED.EVENTSTRYSTAYONPLATFORM or TB_MENU_LOCALIZED.EVENTSTRYNOTGETDISMEMBERED, nil, nil, nil, nil, nil, nil, nil, 1.5)
	local restartButton = UIElement:new({
		parent = holder,
		pos = { 10, -50 },
		size = { holder.size.w / 2 - 15, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	local rewindButton = UIElement:new({
		parent = holder,
		pos = { holder.size.w / 2 + 5, -50 },
		size = { holder.size.w / 2 - 15, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	restartButton:addAdaptedText(false, TB_MENU_LOCALIZED.EVENTSNEWGAME)
	rewindButton:addAdaptedText(false, TB_MENU_LOCALIZED.EVENTSREWIND)
	restartButton:addMouseHandlers(nil, function()
			REPLAY_CAN_BE_SUBMITTED = false
			TUTORIAL_LEAVEGAME = true
			UIElement:runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
			TUTORIAL_LEAVEGAME = false
			reqTable.ready = true
		end)
	rewindButton:addMouseHandlers(nil, function()
			TUTORIAL_LEAVEGAME = true
			rewind_replay()
			TUTORIAL_LEAVEGAME = false
			reqTable.ready = true
		end)
	local loseFrame, gamePaused = 0, false
	add_hook("draw2d", "tbTutorialsCustom", function()
			local ws = get_world_state()
			if (ws.winner > 0 and loseFrame == 0) then
				loseFrame = ws.match_frame
			end
			if (loseFrame > 0 and ws.match_frame > loseFrame + 30 and not gamePaused) then
				freeze_game()
				gamePaused = true
			end
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
