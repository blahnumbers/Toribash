local INTRO = 1
local OUTRO = -1

local armJoints = { 5, 6, 8, 9, 10, 11 }
local loadExistingReplay
local finalPos = { x = 0, y = 49, z = 0, rad = 3.15, complete = tbTutorialsTaskMark and tbTutorialsTaskMark:isDisplayed() }
local checkPoints = {
	{ x = -6, y = 23.5, z = 0.5, h = 5, w = 5, zh = 5, rad = 5, task = 1, complete = tbTutorialsTask.optional[1] and tbTutorialsTask.optional[1].complete },
}
local replayPlaying = false
local taskToggle = nil

local function spawnTaskToggle()
	if (not Tutorials.ver or Tutorials.ver < 1.1 or taskToggle) then
		return
	end
	
	taskToggle = UIElement:new({
		parent = tbTutorialsTask,
		pos = { tbTutorialsTask.size.w, 0 },
		size = { tbTutorialsTask.size.h, tbTutorialsTask.size.h },
		bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR),
		hoverColor = TB_MENU_DEFAULT_BG_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true
	})
	taskToggle.bgColor[4] = 0.7
	taskToggle.animateColor[4] = 0.7
	taskToggle.toggleEnabled = true
	local angle = 90
	local rotate_dir = 0
	taskToggle:addCustomDisplay(false, function()
			set_color(unpack(UICOLORWHITE))
			draw_disk(taskToggle.pos.x + taskToggle.size.w / 2, taskToggle.pos.y + taskToggle.size.h / 2, 0, taskToggle.size.w / 5, 3, 1, 60 + angle, 360 + angle, 0)
			if (rotate_dir ~= 0) then
				angle = angle + 10 * rotate_dir
				if (angle % 180 - 90 == 0) then
					rotate_dir = 0
				end
			end
		end)
	taskToggle:addMouseHandlers(nil, function()
			if (taskToggle.toggleEnabled) then
				rotate_dir = 1
				taskToggle.toggleEnabled = false
				Tutorials:showTaskWindow({}, true, true)
			else
				rotate_dir = -1
				taskToggle.toggleEnabled = true
				Tutorials:showTaskWindow({}, false, true)
			end
		end)
end

local function checkpointComplete(check)
	local grow = 0
	local rad = 0
	local colorDir = 1
	local initialSize = cloneTable(check.size)
	check:addCustomDisplay(false, function()
			rad = rad + math.pi / 40
			local increment = math.sin(rad) / 10
			grow = grow + increment
			check.bgColor[4] = check.bgColor[4] - colorDir * increment
			check.size.x = initialSize.x + grow * initialSize.x
			if (grow >= 2) then
				check:kill()
			end
		end)
end

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

local function loadCheckpoints()
	if (not finalPos.complete) then
		if (finalPos.element) then
			finalPos.element:kill()
		end
		local destinationMark = UIElement3D:new({
			parent = tbTutorials3DHolder,
			pos = { finalPos.x, finalPos.y, finalPos.z + 500 },
			size = { finalPos.rad, 1000 },
			shapeType = CAPSULE,
			bgColor = { 1, 0, 0, 0.5 }
		})
		finalPos.element = destinationMark
	end
	for i,v in pairs(checkPoints) do
		if (not v.complete) then
			if (v.element) then
				v.element:kill()
			end
			local checkPoint = UIElement3D:new({
				parent = tbTutorials3DHolder,
				pos = { v.x, v.y, v.z + 500 },
				size = { v.rad, 1000 },
				shapeType = CAPSULE,
				bgColor = { 0, 0, 1, 0.3 }
			})
			v.element = checkPoint
		end
	end
end

local function showUploadWindow(viewElement, reqTable)
	CURRENT_STEP.fallbackrequirement = true
	
	local function uploadReplay(name)
		chat_input_deactivate()
		local name = name:gsub("%.rpl$", ""):gsub("^%/", "")
		name = name:sub(0, 35) -- attempt to fix infinite replay upload error
		if (name == '') then
			TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERROREMPTYNAME, true)
			CURRENT_STEP.fallbackrequirement = false
			reqTable.ready = true
			return false
		end
		UIElement:runCmd("savereplay " .. name)
		local file = Files:open("../replay/my replays/" .. name .. ".rpl", FILES_MODE_APPEND)
		if (file.data) then
			file:writeLine("#ENDFRAME " .. WIN_FRAME)
			file:close()
		end
		
		local overlay = TBMenu:spawnWindowOverlay()
		local width = overlay.size.w / 7 * 3
		local uploadingView = UIElement:new({
			parent = overlay,
			pos = { (overlay.size.w - width) / 2, overlay.size.h / 2 - overlay.size.h / 10 },
			size = { width, overlay.size.h / 5 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		uploadingView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYUPLOADINPROGRESS)
		local success = function()
			overlay:kill()
			local response = get_network_response()
			if (response:find("^SUCCESS")) then
				reqTable.ready = true
			else
				TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADERROR .. ": " .. response:gsub("^ERROR 0;", ""), function() showUploadWindow(viewElement, reqTable) end, function() CURRENT_STEP.fallbackrequirement = false reqTable.ready = true end)
			end
		end
		local error = function()
			overlay:kill()
			TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADFAILED, function() showUploadWindow(viewElement, reqTable) end, function() CURRENT_STEP.fallbackrequirement = false reqTable.ready = true end)
		end
		if (Request.queue ~= nil) then
			Request:queue(function()
				upload_event_replay(name, "Event Squad's Leggang Rise Up event entry", "ESEVNT" .. CURRENT_TUTORIAL, "replay/my replays/" .. name .. ".rpl")
			end, "replayupload", success, error)
		else
			upload_event_replay(name, "Event Squad's Leggang Rise Up event entry", "ESEVNT" .. CURRENT_TUTORIAL, "replay/my replays/" .. name .. ".rpl")
			Request:new("replayupload", success, error)
		end
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
	local skipAdd = skipAdd or 0
	local buttonWidth = WIN_W / 3 > 350 and 350 or WIN_W / 3
	local submitButton = UIElement:new({
		parent = viewElement,
		pos = { (WIN_W - buttonWidth) / 2, -120 },
		size = { buttonWidth, 70 },
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
	dofile('system/replays_manager.lua')
	local skipAdd = skipAdd or 0
	spawnTaskToggle()
	TUTORIAL_SPECIAL_RP_IGNORE = true
	
	loadCheckpoints()
	chat_input_deactivate()
	if (skipAdd == 0) then
		local gameRulesScreen = nil
		add_hook("leave_game", "tbTutorialsCustomStatic", function()
				if (TUTORIAL_LEAVEGAME) then
					return 1
				end
			end)
		add_hook("key_up", "tbTutorialsCustom", function(key)
				if (key == 103 and gameRulesScreen) then
					gameRulesScreen:kill()
					gameRulesScreen = nil
					return 1
				end
				if (replayPlaying) then
					return 1
				end
				if (key == 101) then
					TUTORIAL_LEAVEGAME = true
					STOPFRAME = nil
					edit_game()
					if (not finalPos.complete) then
						REPLAY_CAN_BE_SUBMITTED = false
						WIN_FRAME = 100000
					end
					TUTORIAL_LEAVEGAME = false
					return 1
				end
				if (key == 102) then
					dofile("system/replay_save.lua")
					return 1
				end
				if (key == 114) then
					if (get_world_state().replay_mode == 0) then
						STOPFRAME = get_world_state().match_frame
					end
					if (STOPFRAME == 0) then
						STOPFRAME = nil
						return 1
					end
					TUTORIAL_LEAVEGAME = true
					rewind_replay()
					TUTORIAL_LEAVEGAME = false
					if (not REPLAY_CAN_BE_SUBMITTED) then
						finalPos.complete = false
						tbTutorialsTaskMark:hide(true)
						for i,v in pairs(checkPoints) do
							v.complete = false
							Tutorials:taskOptIncomplete(v.task)
							tbTutorialsTask.optional[i].markFail:hide(true)
						end
						loadCheckpoints()
					end
					return 1
				end
				if (key == 32 and get_world_state().replay_mode == 1) then
					if (REPLAY_CAN_BE_SUBMITTED) then
						local rplName = CURRENT_TUTORIAL .. "-" .. os.date("%- %X")
						UIElement:runCmd("savereplay " .. rplName)
						TBMenu:showDataError("Your replay has been auto-saved as " .. rplName)
					end
					TUTORIAL_LEAVEGAME = true
					STOPFRAME = nil
					finalPos.complete = false
					tbTutorialsTaskMark:hide(true)
					for i,v in pairs(checkPoints) do
						v.complete = false
						Tutorials:taskOptIncomplete(v.task)
						tbTutorialsTask.optional[i].markFail:hide(true)
					end
					loadCheckpoints()
					REPLAY_CAN_BE_SUBMITTED = false
					WIN_FRAME = 100000
					UIElement:runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
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
				if (key == 108 and get_keyboard_ctrl() > 0) then
					if (Replays.ver and Replays.ver >= 1.1) then
						Replays:showCustomReplaySelection(viewElement, CURRENT_TUTORIAL .. ".tbm", function(path)
								TUTORIAL_LEAVEGAME = true
								UIElement:runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
								TUTORIAL_LEAVEGAME = false
								finalPos.complete = false
								tbTutorialsTaskMark:hide(true)
								for i,v in pairs(checkPoints) do
									v.complete = false
									Tutorials:taskOptIncomplete(v.task)
									tbTutorialsTask.optional[i].markFail:hide(true)
								end
								loadExistingReplay(viewElement, reqTable, path)
							end)
					end
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
		
		if (Replays.ver and Replays.ver >= 1.1) then
			local customReplayButton = UIElement:new({
				parent = viewElement,
				pos = { -290, -90 },
				size = { 250, 40 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
				hoverColor = TB_MENU_DEFAULT_BG_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			local customReplayButtonKill = UIElement:new({
				parent = customReplayButton,
				pos = { customReplayButton.size.w, 0 },
				size = { 40, 40 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
				hoverColor = TB_MENU_DEFAULT_BG_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			local customReplayButtonKillIcon = UIElement:new({
				parent = customReplayButtonKill,
				pos = { 8, 8 },
				size = { customReplayButtonKill.size.w - 16, customReplayButtonKill.size.h - 16 },
				bgImage = "../textures/menu/general/buttons/crosswhite.tga"
			})
			customReplayButton:addAdaptedText(false, TB_MENU_LOCALIZED.EVENTSLOADCUSTOMREPLAY or "Load replay (CTRL + L)")
			customReplayButton:addMouseHandlers(false, function()
					Replays:showCustomReplaySelection(viewElement, CURRENT_TUTORIAL .. ".tbm", function(path)
							TUTORIAL_LEAVEGAME = true
							UIElement:runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
							TUTORIAL_LEAVEGAME = false
							finalPos.complete = false
							tbTutorialsTaskMark:hide(true)
							for i,v in pairs(checkPoints) do
								v.complete = false
								Tutorials:taskOptIncomplete(v.task)
								tbTutorialsTask.optional[i].markFail:hide(true)
							end
							loadExistingReplay(viewElement, reqTable, path)
						end)
				end)
			customReplayButtonKill:addMouseHandlers(nil, function()
					customReplayButton:kill()
				end)
		end
		if (get_world_state().replay_mode == 0) then
			loadExistingReplay(viewElement, reqTable)
		end
	end
	
	local submitButton = nil
	local frame_checked = 0
	add_hook("draw2d", "tbTutorialsCustom", function()
			local ws = get_world_state()
			if (ws.winner == 0 and finalPos.complete and not REPLAY_CAN_BE_SUBMITTED) then
				WIN_FRAME = ws.match_frame
				REPLAY_CAN_BE_SUBMITTED = true
				EventsOnline:taskComplete()
			end
			if (STOPFRAME) then
				if (ws.match_frame >= STOPFRAME) then
					edit_game()
					STOPFRAME = nil
				end
			end
			if (not submitButton and REPLAY_CAN_BE_SUBMITTED) then
				submitButton = showSubmitButton(viewElement, reqTable)
			elseif (ws.replay_mode == 0) then
				if (submitButton and not REPLAY_CAN_BE_SUBMITTED) then
					submitButton:kill()
					submitButton = nil
				end
			end
			if (ws.match_frame >= ws.game_frame or ws.match_frame >= WIN_FRAME + 40) then
				TUTORIAL_LEAVEGAME = true
				rewind_replay()
				TUTORIAL_LEAVEGAME = false
				return
			end
			if (ws.match_frame ~= frame_checked) then
				if (not finalPos.complete) then
					for i,check in pairs(checkPoints) do
						if (not check.complete) then
							local criteriaMet = true
							for i,v in pairs(JOINTS) do
								if (not in_array(v, armJoints)) then
									local x, y, z = get_joint_pos(0, v)
									-- apply displacement
									x = x - 1
									y = y + 0.1
									local xR, yR = x - check.x, y - check.y
									if (xR * xR + yR * yR > check.rad * check.rad) then
										criteriaMet = false
										break
									end
								end
							end
							if (criteriaMet) then
								Tutorials:taskOptComplete(check.task)
								check.complete = true
								checkpointComplete(check.element)
							end
						end
					end
					local criteriaMet = true
					for i,v in pairs(JOINTS) do
						if (not in_array(v, armJoints)) then
							local x, y, z = get_joint_pos(0, v)
							-- apply displacement
							x = x - 1
							y = y + 0.1
							--[[if (z < finalPos.z - finalPos.rad / 2 or z > finalPos.z + finalPos.rad) then
								criteriaMet = false
								break
							end]]
							local xR, yR = x - finalPos.x, y - finalPos.y
							if (xR * xR + yR * yR > finalPos.rad * finalPos.rad) then
								criteriaMet = false
								break
							end
						end
					end
					if (criteriaMet) then
						finalPos.complete = true
						checkpointComplete(finalPos.element)
					end
				end
				frame_checked = ws.match_frame
			end
		end)
end

loadExistingReplay = function(viewElement, reqTable, rplFile)
	local replay = Files:open(rplFile and ("../replay/" .. rplFile) or ("../replay/my replays/--eventtmp" .. CURRENT_TUTORIAL .. ".rpl"))
	if (not replay.data) then
		return false
	end
	for i,v in pairs(checkPoints) do
		v.complete = false
		Tutorials:taskOptIncomplete(v.task)
		tbTutorialsTask.optional[i].markFail:hide(true)
	end
	loadCheckpoints()
	local rplData = replay:readAll()
	replay:close()
	
	local steps = {}
	for i, ln in pairs(rplData) do
		if (ln:find("^FRAME %d+")) then
			local rplFrame = ln:gsub("^FRAME ", ""):gsub("%D?;.*$", "")
			if (#steps > 0) then
				if (tonumber(rplFrame) < steps[#steps].frame) then
					steps = {}
				end
			end
			table.insert(steps, { frame = tonumber(rplFrame), moves = {}, grip = {} })
			if (#steps ~= 1) then
				steps[#steps - 1].turnLength = steps[#steps].frame - steps[#steps - 1].frame
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
		elseif (ln:find("GRIP 0;")) then
			local gripChanges = ln:gsub("GRIP 0; ", "")
			local data_stream = { gripChanges:match(("(%d) ?"):rep(2)) }
			if (data_stream[1] ~= '0') then
				steps[#steps].grip[12] = data_stream[1] == '1' and 1 or 0
			end
			if (data_stream[2] ~= '0') then
				steps[#steps].grip[11] = data_stream[2] == '1' and 1 or 0
			end
		end
	end
	local current_step = 1
	replayPlaying = true
	add_hook("draw2d", "tbTutorialsCustomStatic", function()
			local ws = get_world_state()
			for i,check in pairs(checkPoints) do
				if (not check.complete) then
					local criteriaMet = true
					for i,v in pairs(JOINTS) do
						if (not in_array(v, armJoints)) then
							local x, y, z = get_joint_pos(0, v)
							local x, y, z = get_joint_pos(0, v)
							-- apply displacement
							x = x - 1
							y = y + 0.1
							local xR, yR = x - check.x, y - check.y
							if (xR * xR + yR * yR > check.rad * check.rad) then
								criteriaMet = false
								break
							end
						end
					end
					if (criteriaMet) then
						Tutorials:taskOptComplete(check.task)
						check.complete = true
						checkpointComplete(check.element)
					end
				end
			end
			if (current_step > #steps) then
				replayPlaying = false
				remove_hook("draw2d", "tbTutorialsCustomStatic")
				freeze_game()
				edit_game()
			end
			if (ws.match_frame == steps[current_step].frame) then
				for i,v in pairs(steps[current_step].moves) do
					set_joint_state(0, i, v)
				end
				for i,v in pairs(steps[current_step].grip) do
					set_grip_info(0, i, v)
				end
				if (current_step ~= #steps) then
					run_frames(steps[current_step].turnLength)
				end
				current_step = current_step + 1
			end
		end)
end

local function setDiscordRPC()
	local tutorialNum = CURRENT_TUTORIAL:gsub("%D", "")
	set_discord_rpc("Leggang Rise Up " .. tutorialNum, TB_MENU_LOCALIZED.DISCORDRPCPLAYINGSPEVENT or "Playing SP Event")
end

local function launchGame(viewElement, reqTable)
	local req = { type = "newgame", ready = false }
	table.insert(reqTable, req)
	TUTORIAL_LEAVEGAME = true
	setDiscordRPC()
	download_head("aliosa")
	
	REPLAY_CAN_BE_SUBMITTED = false
	WIN_FRAME = 100000

	UIElement:runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
	local wipReplay = Files:open("../replay/my replays/--eventtmp" .. CURRENT_TUTORIAL .. ".rpl")
	if (wipReplay.data) then
		for i,ln in pairs(wipReplay:readAll()) do
			if (ln:find("^JOINT")) then
				CURRENT_STEP.skip = 5
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

functions = {
	IntroOverlay = introOverlay,
	OutroOverlay = outroOverlay,
	InitCheckpoints = loadCheckpoints,
	PrepareNewGame = launchGame,
	LoadReplay = loadExistingReplay,
	EventMain = eventMain,
	UploadEventEntry = showUploadWindow
}
