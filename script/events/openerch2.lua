local INTRO = 1
local OUTRO = -1

local loadOpener, loadExistingReplay
local openerStopframe = 50
STOPFRAME = openerStopframe

local prizeRewards = {
	st = {
		2, 5, 9, 14, 20
	},
	tc = 700
}

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
	taskToggle.killAction = function() taskToggle = nil end
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

local function setModSettings()
	UIElement:runCmd("set mod classic.tbm")
	start_new_game()
	UIElement:runCmd("set matchframes 1000")
	UIElement:runCmd("set engagedistance 300")
	UIElement:runCmd("set fracture 0")
	UIElement:runCmd("set gravity 0 0 -30")
	start_new_game()
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
				reqTable.ready = EventsOnline:checkRequirements(reqTable)
				overlay:kill()
			elseif (out and overlay.bgColor[4] >= 1) then
				req.ready = true
				reqTable.ready = EventsOnline:checkRequirements(reqTable)
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
	EventsOnline:taskComplete()
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
		
		local tutorialNum = CURRENT_TUTORIAL:gsub("%D", "")
		local eventtag = "openerch" .. tutorialNum
		upload_event_replay(name, "Event Squad's Opener Challenge Event entry", "ESEVNT" .. eventtag, "replay/my replays/" .. name .. ".rpl")
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
	local skipAdd = skipAdd or 0
	local submitButton = UIElement:new({
		parent = viewElement,
		pos = { WIN_W / 2 - 250, -100 },
		size = { 500, 60 },
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
	local advComplete = false
	TUTORIAL_SPECIAL_RP_IGNORE = true
	
	spawnTaskToggle()
	--EventsOnline:taskOptIncomplete(1)
	
	chat_input_deactivate()
	if (skipAdd == 0) then
		local gameRulesScreen = nil
		add_hook("leave_game", "tbTutorialsCustomStatic", function()
				if (TUTORIAL_LEAVEGAME) then
					return 1
				end
			end)
		add_hook("key_up", "tbTutorialsCustom", function(key)
				local ws = get_world_state()
				if (key == 101) then
					if (ws.match_frame < openerStopframe) then
						return 1
					end
					TUTORIAL_LEAVEGAME = true
					tbTutorialsTaskMark:hide(true)
					TUTORIAL_LEAVEGAME = false
					REPLAY_CAN_BE_SUBMITTED = false
					--EventsOnline:taskOptIncomplete(1)
					advComplete = false
				end
				if (key == 102) then
					dofile("system/replay_save.lua")
					return 1
				end
				if (key == 114) then
					if (ws.replay_mode == 0) then
						STOPFRAME = ws.match_frame
					end
					if (STOPFRAME < openerStopframe) then
						STOPFRAME = openerStopframe
						return 1
					end
					TUTORIAL_LEAVEGAME = true
					rewind_replay()
					TUTORIAL_LEAVEGAME = false
					return 1
				end
				if (key == 32) then
					if (ws.replay_mode == 1) then
						TUTORIAL_LEAVEGAME = true
						STOPFRAME = openerStopframe
						setModSettings()
						loadOpener()
						REPLAY_CAN_BE_SUBMITTED = false
						TUTORIAL_LEAVEGAME = false
						return 1
					elseif (ws.match_frame < ws.game_frame) then
						STOPFRAME = ws.match_frame
					end
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
				if (key == 108 and get_keyboard_ctrl() > 0) then
					if (Replays.ver and Replays.ver >= 1.1 and not REPLAYS_CUSTOM_SELECTOR_ACTIVE) then
						Replays:showCustomReplaySelection(viewElement, "classic", function(path)
								TUTORIAL_LEAVEGAME = true
								setModSettings()
								TUTORIAL_LEAVEGAME = false
								loadExistingReplay(viewElement, reqTable, false, path)
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
				bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR_TRANS),
				hoverColor = TB_MENU_DEFAULT_BG_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			customReplayButton.bgColor[4] = 0.7
			local customReplayButtonKill = UIElement:new({
				parent = customReplayButton,
				pos = { customReplayButton.size.w, 0 },
				size = { 40, 40 },
				interactive = true,
				bgColor = cloneTable(customReplayButton.bgColor),
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
					Replays:showCustomReplaySelection(viewElement, "classic", function(path)
							TUTORIAL_LEAVEGAME = true
							setModSettings()
							TUTORIAL_LEAVEGAME = false
							loadExistingReplay(viewElement, reqTable, false, path)
						end)
				end)
			customReplayButtonKill:addMouseHandlers(nil, function()
					customReplayButton:kill()
				end)
		end
	end
	
	local submitButton = nil
	local frame_checked = 0
	add_hook("draw2d", "tbTutorialsCustom", function()
			local ws = get_world_state()
			if (STOPFRAME) then
				if (ws.match_frame >= STOPFRAME and ws.replay_mode == 1) then
					edit_game()
				end
			end
			if (skipAdd == 0) then
				if (not submitButton and REPLAY_CAN_BE_SUBMITTED) then
					submitButton = showSubmitButton(viewElement, reqTable)
				elseif (ws.replay_mode == 0) then
					if (submitButton and not REPLAY_CAN_BE_SUBMITTED) then
						submitButton:kill()
						submitButton = nil
					end
				end
			end
			if (ws.match_frame >= ws.game_frame) then
				TUTORIAL_LEAVEGAME = true
				rewind_replay()
				TUTORIAL_LEAVEGAME = false
				return
			end
			if (ws.match_frame ~= frame_checked and ws.replay_mode == 0) then
				local criteriaMet1 = false
				local dismembers = 0
				local prizes = { st = 0, tc = 0 }
				for i,v in pairs(JOINTS) do
					if (get_joint_dismember(1, v)) then
						dismembers = dismembers + 1
					end
				end
				if (dismembers > 1) then
					REPLAY_CAN_BE_SUBMITTED = true
					for i, v in pairs(prizeRewards.st) do
						if (v > dismembers) then
							break
						end
						prizes.st = i
					end
					prizes.tc = dismembers * prizeRewards.tc
				end
				
				local text = tbTutorialsTask.extra[1].element.child[1].str
				text = text:gsub("%d+", dismembers)
				tbTutorialsTask.extra[1].element.child[1]:addAdaptedText(true, text, nil, nil, 4, LEFTMID, 0.6)
				
				local text2 = tbTutorialsTask.extra[2].element.child[1].str
				text2 = text2:gsub("%d+ ST", prizes.st .. " ST")
				text2 = text2:gsub("%d+ TC", prizes.tc .. " TC")
				tbTutorialsTask.extra[2].element.child[1]:addAdaptedText(true, text2, nil, nil, 4, LEFTMID, 0.6)
				frame_checked = ws.match_frame
			end
		end)
end

local function setDiscordRPC()
	local tutorialNum = CURRENT_TUTORIAL:gsub("%D", "")
	set_discord_rpc("Opener Challenge " .. tutorialNum, TB_MENU_LOCALIZED.DISCORDRPCPLAYINGSPEVENT or "Playing SP Event")
end

local function launchGame(viewElement, reqTable)
	local req = { type = "newgame", ready = false }
	table.insert(reqTable, req)
	TUTORIAL_LEAVEGAME = true
	setDiscordRPC()
	
	REPLAY_CAN_BE_SUBMITTED = false
	setModSettings()
	local wipReplay = Files:new("../replay/my replays/--eventtmp" .. CURRENT_TUTORIAL .. ".rpl")
	if (wipReplay.data) then
		for i,ln in pairs(wipReplay:readAll()) do
			if (ln:find("^JOINT")) then
				CURRENT_STEP.skip = 4
				wipReplay:close()
				break
			end
		end
	else
		--open_replay("system/events/" .. CURRENT_TUTORIAL .. ".rpl")
		--freeze_game()
		--REPLAY_RUNNING = true
	end
	
	local reqElement = UIElement:new({
		parent = viewElement,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	reqElement:addCustomDisplay(true, function()
			req.ready = true
			reqTable.ready = EventsOnline:checkRequirements(reqTable)
			reqElement:kill()
			TUTORIAL_LEAVEGAME = false
		end)
end

local function checkOpenerReplay(viewElement, reqTable)
	local req = { type = "newgame", ready = false }
	table.insert(reqTable, req)
	
	local rplFile = Files:new("../replay/system/events/" .. CURRENT_TUTORIAL .. ".rpl")
	if (not rplFile.data) then
		dofile("system/network_request.lua")
		local loader = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 5, viewElement.size.h / 4 },
			size = { viewElement.size.w / 5 * 3, viewElement.size.h / 2 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			uiColor = { 1, 1, 1, 1 }
		})
		TBMenu:displayLoadingMark(loader, "Downloading opener from server...")
		local waiter = UIElement:new({
			parent = loader,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		waiter:addCustomDisplay(true, function()
				if (get_network_task() == 0) then
					Request:new("openerChallenge", function()
							local downloader = UIElement:new({
								parent = loader,
								pos = { 0, 0 },
								size = { 0, 0 }
							})
							downloader:addCustomDisplay(true, function()
									for i,v in pairs(get_downloads()) do
										if (v:find(CURRENT_TUTORIAL)) then
											return
										end
									end
									downloader:kill()
									req.ready = true
									reqTable.ready = EventsOnline:checkRequirements(reqTable)
								end)
						end)
					download_server_file('get_event_replay&name=' .. CURRENT_TUTORIAL, 0)
					waiter:kill()
				end
			end)
	else
		rplFile:close()
		req.ready = true
		reqTable.ready = EventsOnline:checkRequirements(reqTable)
	end
	local headTexture = Files:new("../custom/fred/head.tga")
	if (not headTexture.data) then
		download_head("fred")
	end
	headTexture:close()
end

loadExistingReplay = function(viewElement, reqTable, openerOnly, path)
	tbTutorialsTaskMark:hide(true)
	local opener = Files:new("../replay/system/events/" .. CURRENT_TUTORIAL .. ".rpl")
	if (not opener.data) then
		reqTable.ready = true
		return false
	end
	local openerData = opener:readAll()
	opener:close()
	local openerSteps = {}
	for i,ln in pairs(openerData) do
		if (ln:find("^FRAME %d+")) then
			local rplFrame = ln:gsub("^FRAME ", ""):gsub("%D?;.*$", "")
			table.insert(openerSteps, { frame = tonumber(rplFrame), moves = {}, grip = {} })
			if (#openerSteps ~= 1) then
				openerSteps[#openerSteps - 1].turnLength = openerSteps[#openerSteps].frame - openerSteps[#openerSteps - 1].frame
			end
		elseif (ln:find("JOINT 0;")) then
			local jointMoves = ln:gsub("JOINT 0; ", "")
			local _, count = jointMoves:gsub(" ", "")
			count = (count + 1) / 2
			local data_stream = { jointMoves:match(("(%d+ %d+) *"):rep(count)) }
			for i,v in pairs(data_stream) do
				local info = { v:match(("(%d+) *"):rep(2)) }
				openerSteps[#openerSteps].moves[info[1] + 0] = info[2] + 0
			end
		elseif (ln:find("GRIP 0;")) then
			local gripChanges = ln:gsub("GRIP 0; ", "")
			local data_stream = { gripChanges:match(("(%d) ?"):rep(2)) }
			if (data_stream[1] ~= '0') then
				openerSteps[#openerSteps].grip[12] = data_stream[1] == '1' and 1 or 0
			end
			if (data_stream[2] ~= '0') then
				openerSteps[#openerSteps].grip[11] = data_stream[2] == '1' and 1 or 0
			end
		end
	end
	openerSteps[#openerSteps].turnLength = openerStopframe - openerSteps[#openerSteps].frame
	eventMain(viewElement, reqTable, 2)
	
	local current_step = 1
	
	local replay = Files:new(path and ("../replay/" .. path) or ("../replay/my replays/--eventtmp" .. CURRENT_TUTORIAL .. ".rpl"))
	local setReady = false
	if (not replay.data) then
		setReady = true
	end
	if (setReady or openerOnly) then
		if (openerOnly and not setReady) then
			replay:close()
		end 
		add_hook("draw2d", "tbTutorialsCustomStatic", function()
				local ws = get_world_state()
				if (ws.match_frame == openerStopframe) then
					remove_hook("draw2d", "tbTutorialsCustomStatic")
					freeze_game()
					edit_game()
					if (setReady and not path) then
						reqTable.ready = true
					end
				end
				if (ws.match_frame == openerSteps[current_step].frame) then
					for i,v in pairs(openerSteps[current_step].moves) do
						set_joint_state(0, i, v)
					end
					for i,v in pairs(openerSteps[current_step].grip) do
						set_grip_info(0, i, v)
					end
					run_frames(openerSteps[current_step].turnLength)
					current_step = current_step + 1
				end
			end)
		return true
	end
	
	local rplData = replay:readAll()
	replay:close()
	local steps = {}
	local acceptStep = false
	for i, ln in pairs(rplData) do
		if (ln:find("^FRAME %d+")) then
			local rplFrame = ln:gsub("^FRAME ", ""):gsub("%D?;.*$", "")
			if (#steps > 0) then
				if (tonumber(rplFrame) < steps[#steps].frame) then
					steps = {}
				end
			end
			if (tonumber(rplFrame) < openerStopframe) then
				acceptStep = false
			else
				acceptStep = true
				table.insert(steps, { frame = tonumber(rplFrame), moves = {}, grip = {} })
				if (#steps ~= 1) then
					steps[#steps - 1].turnLength = steps[#steps].frame - steps[#steps - 1].frame
				end
			end
		elseif (ln:find("JOINT 0;") and acceptStep) then
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
	if (#steps > 0) then
		openerSteps[#openerSteps].turnLength = steps[1].frame - openerSteps[#openerSteps].frame
		for i,v in pairs(steps) do
			table.insert(openerSteps, v)
		end
		STOPFRAME = openerSteps[#openerSteps].frame
	else
		openerSteps[#openerSteps].turnLength = openerStopframe - openerSteps[#openerSteps].frame
		table.insert(openerSteps, { frame = openerStopframe, moves = {}, grip = {} })
	end
	add_hook("draw2d", "tbTutorialsCustomStatic", function()
			local ws = get_world_state()
			if (current_step > #openerSteps) then
				remove_hook("draw2d", "tbTutorialsCustomStatic")
				freeze_game()
				edit_game()
				if (not path) then
					reqTable.ready = true
				end
			end
			if (ws.match_frame == openerSteps[current_step].frame) then
				for i,v in pairs(openerSteps[current_step].moves) do
					set_joint_state(0, i, v)
				end
				for i,v in pairs(openerSteps[current_step].grip) do
					set_grip_info(0, i, v)
				end
				if (current_step ~= #openerSteps) then
					run_frames(openerSteps[current_step].turnLength)
				end
				current_step = current_step + 1
			end
		end)
end

loadOpener = function(viewElement, reqTable)
	TUTORIAL_LEAVEGAME = true
	setModSettings()
	TUTORIAL_LEAVEGAME = false
	loadExistingReplay(viewElement, reqTable, true)
end

functions = {
	IntroOverlay = introOverlay,
	OutroOverlay = outroOverlay,
	InitCheckpoints = loadCheckpoints,
	PrepareNewGame = launchGame,
	PlayOpener = loadOpener,
	LoadReplay = loadExistingReplay,
	OpenerChallenge = eventMain,
	UploadEventEntry = showUploadWindow,
	CheckReplay = checkOpenerReplay
}
