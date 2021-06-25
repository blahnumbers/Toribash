local INTRO = 1
local OUTRO = -1

local loadExistingReplay
STOPFRAME = nil

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

local function showUploadWindow(viewElement, reqTable, onlySave)
	local uploadOverlay = nil
	
	local function uploadReplay(name)
		chat_input_deactivate()
		local name = name:gsub("%.rpl$", ""):gsub("^%/", "")
		name = name:sub(0, 35) -- attempt to fix infinite replay upload error
		if (name == '') then
			TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERROREMPTYNAME, true)
			uploadOverlay:kill()
			return false
		end
		UIElement:runCmd("savereplay " .. name)
		
		if (onlySave) then
			return
		end
		
		local tutorialNum = CURRENT_TUTORIAL:gsub("%D", "")
		local eventtag = "headinthewall" .. tutorialNum
		local overlay = TBMenu:spawnWindowOverlay()
		local width = overlay.size.w / 7 * 3
		local uploadingView = UIElement:new({
			parent = overlay,
			pos = { (overlay.size.w - width) / 2, overlay.size.h / 2 - overlay.size.h / 10 },
			size = { width, overlay.size.h / 5 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		uploadingView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYUPLOADINPROGRESS)
		
		-- Use Request:queue() in 5.44+
		if (Request.ver >= 1.1) then
			Request:queue(function()
					upload_event_replay(name, "Event Squad's Head in the Wall Event entry", "ESEVNT" .. eventtag, "replay/my replays/" .. name .. ".rpl")
				end,
				"replayupload",
				function()
					overlay:kill()
					local response = get_network_response()
					if (response:find("^SUCCESS")) then
						CURRENT_STEP.fallbackrequirement = true
						CURRENT_STEP.skip = 1
						reqTable.ready = true
					else
						TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADERROR .. ": " .. response:gsub("^ERROR 0;", ""), function() showUploadWindow(viewElement, reqTable) end, function() uploadOverlay:kill() end)
					end
				end,
				function()
					overlay:kill()
					TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADFAILED, function() showUploadWindow(viewElement, reqTable) end, function() uploadOverlay:kill() end)
				end)
		else
			upload_event_replay(name, "Event Squad's Head in the Wall Event entry", "ESEVNT" .. eventtag, "replay/my replays/" .. name .. ".rpl")
			Request:new("replayupload", function()
					overlay:kill()
					local response = get_network_response()
					if (response:find("^SUCCESS")) then
						CURRENT_STEP.fallbackrequirement = true
						CURRENT_STEP.skip = 1
						reqTable.ready = true
					else
						TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADERROR .. ": " .. response:gsub("^ERROR 0;", ""), function() showUploadWindow(viewElement, reqTable) end, function() uploadOverlay:kill() end)
					end
				end, function()
					overlay:kill()
					TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADFAILED, function() showUploadWindow(viewElement, reqTable) end, function() uploadOverlay:kill() end)
				end)
		end
	end
	
	local function cancelUpload()
		chat_input_deactivate()
		uploadOverlay:kill()
	end
	
	add_hook("key_down", "tbTutorialsCustom", function(s) UIElement:handleKeyDown(s) return 1 end)
	add_hook("key_up", "tbTutorialsCustom", function(s) UIElement:handleKeyUp(s) return 1 end)
	uploadOverlay = TBMenu:showConfirmationWindowInput(onlySave and TB_MENU_LOCALIZED.REPLAYSSAVEREPLAY or TB_MENU_LOCALIZED.EVENTSUPLOADINGENTRY, TB_MENU_LOCALIZED.REPLAYSENTERNAME, uploadReplay, cancelUpload, not onlySave and TB_MENU_LOCALIZED.EVENTSUPLOADIGNENTRYINFO or nil, TB_TUTORIAL_MODERN_GLOBALID)
end

local function eventMain(viewElement, reqTable, skipAdd)
	local skipAdd = skipAdd or 0
	TUTORIAL_SPECIAL_RP_IGNORE = true
	
	spawnTaskToggle()
	tbTutorialsTaskMark:hide(true)
	REPLAY_CAN_BE_SUBMITTED = false
	--[[if (#tbTutorialsTask.extra > 0) then
		tbTutorialsTask.extra[1].element.shift.y = tbTutorialsTask.size.h + 40
	end]]
	
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
					STOPFRAME = nil
					TUTORIAL_LEAVEGAME = true
					tbTutorialsTaskMark:hide(true)
					TUTORIAL_LEAVEGAME = false
					REPLAY_CAN_BE_SUBMITTED = false
				end
				if (key == 102) then
					dofile("system/replay_save.lua")
					return 1
				end
				if (key == 114) then
					STOPFRAME = ws.match_frame
					if (STOPFRAME == 0) then
						STOPFRAME = nil
						return 1
					end
					TUTORIAL_LEAVEGAME = true
					rewind_replay()
					TUTORIAL_LEAVEGAME = false
					return 1
				end
				if (key == 32 and ws.replay_mode == 1) then
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
				if (get_keyboard_ctrl() > 0 or get_keyboard_alt() > 0) then
					return 1
				end
		end)
		add_hook("key_down", "tbTutorialsCustom", function(key)
				if (key == 103 and get_keyboard_ctrl() > 0) then
					if (not gameRulesScreen) then
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
					else
						gameRulesScreen:kill()
						gameRulesScreen = nil
					end
					return 1
				end
			end)
	end
	
	local frame_checked = 0
	add_hook("draw2d", "tbTutorialsCustom", function()
			local ws = get_world_state()
			if (frame_checked == ws.match_frame) then
				return
			end
			if (STOPFRAME) then
				if (ws.match_frame >= STOPFRAME and ws.replay_mode == 1) then
					edit_game()
				end
			end
			
			if (ws.winner == 1 or ws.match_frame >= ws.game_frame) then
				REPLAY_CAN_BE_SUBMITTED = false
				remove_hook("draw2d", "tbTutorialsCustomStatic")
				freeze_game()
				CURRENT_STEP.skip = 1
				reqTable.ready = true
				return
			elseif (ws.winner == 0) then
				local criteriaMet = 0
				local bPos = get_body_info(0, 0).pos
				local targets = {
					{ x = 0, y = 23.4, z = 0.5, h = 5.1, w = 4.1, zh = 1 },
					{ x = 0, y = 32.4, z = 0.5, h = 3.1, w = 2.2, zh = 1 },
					{ x = 0, y = 41.8, z = 0.5, h = 1.9, w = 1.4, zh = 1 },
				}
				
				-- Values are off
				bPos.x = bPos.x - 1
				bPos.y = bPos.y + 0.1
				for i,v in pairs(targets) do
					if (v.x + v.w / 2 > bPos.x and v.x - v.w / 2 < bPos.x and
						v.y + v.h / 2 > bPos.y and v.y - v.h / 2 < bPos.y and
						v.z + v.zh / 2 > bPos.z and v.z - v.zh / 2 < bPos.z) then
						criteriaMet = i
						break
					end
				end
				if (criteriaMet > 0) then
					freeze_game()
					CURRENT_STEP.skip = 0
					reqTable.ready = true
				end
			end
			frame_checked = ws.match_frame
		end)
end

local function setDiscordRPC()
	local tutorialNum = CURRENT_TUTORIAL:gsub("%D", "")
	set_discord_rpc("Head in the Wall " .. tutorialNum, TB_MENU_LOCALIZED.DISCORDRPCPLAYINGSPEVENT or "Playing SP Event")
end

local function launchGame(viewElement, reqTable)
	local req = { type = "newgame", ready = false }
	table.insert(reqTable, req)
	TUTORIAL_LEAVEGAME = true
	setDiscordRPC()
	local headTexture = Files:open("../custom/Elmindreda/head.tga")
	if (not headTexture.data) then
		download_head("Elmindreda")
	end
	headTexture:close()
	
	REPLAY_CAN_BE_SUBMITTED = false
	UIElement:runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
	local wipReplay = Files:open("../replay/my replays/--eventtmp" .. CURRENT_TUTORIAL .. ".rpl")
	if (wipReplay.data) then
		for i,ln in pairs(wipReplay:readAll()) do
			if (ln:find("^JOINT")) then
				CURRENT_STEP.skip = 7
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
			reqTable.ready = EventsOnline:checkRequirements(reqTable)
			reqElement:kill()
			TUTORIAL_LEAVEGAME = false
		end)
end

local function playerLose(viewElement, reqTable)
	tbTutorialsTaskMark:hide(true)
	play_sound(7)
	local backgroundSplash = UIElement:new({
		parent = viewElement,
		pos = { viewElement.size.w / 2, viewElement.size.h / 2 },
		size = { 0, 0 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
	})
	local doShowPlayerLose = function()
		local loseText = UIElement:new({
			parent = backgroundSplash,
			pos = { 20, 10 },
			size = { backgroundSplash.size.w - 40, backgroundSplash.size.h * 0.3 }
		})
		loseText:addAdaptedText(true, "R.I.P", nil, nil, FONTS.BIG)
		local loseTextInfo = UIElement:new({
			parent = backgroundSplash,
			pos = { 20, loseText.shift.y + loseText.size.h },
			size = { backgroundSplash.size.w - 40, backgroundSplash.size.h * 0.3 - 10 }
		})
		loseTextInfo:addAdaptedText(true, "You missed both your head ^16AND ^01your reward. That hurts!")
		local restartButton = UIElement:new({
			parent = backgroundSplash,
			pos = { 20, backgroundSplash.size.h * 0.6 },
			size = { backgroundSplash.size.w - 40, backgroundSplash.size.h * 0.4 - 10 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		restartButton:addAdaptedText(false, TB_MENU_LOCALIZED.EVENTSPLAYAGAIN or "Play again")
		restartButton:addMouseHandlers(nil, function()
				TUTORIAL_LEAVEGAME = true
				STOPFRAME = nil
				UIElement:runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
				REPLAY_CAN_BE_SUBMITTED = false
				TUTORIAL_LEAVEGAME = false
				CURRENT_STEP.fallbackrequirement = false
				reqTable.ready = true
			end)
	end
	local rad = math.pi / 4
	backgroundSplash:addCustomDisplay(false, function()
			rad = rad + math.pi / 24
			backgroundSplash.size.w = backgroundSplash.size.w + math.ceil(math.sin(rad) * 46)
			backgroundSplash.size.h = backgroundSplash.size.h + math.ceil(math.sin(rad) * 13)
			backgroundSplash:moveTo((viewElement.size.w - backgroundSplash.size.w) / 2, (viewElement.size.h - backgroundSplash.size.h) / 2)
			if (backgroundSplash.size.w >= 550) then
				backgroundSplash:addCustomDisplay(false, function() end)
				doShowPlayerLose()
				rad = math.pi / 4
				local overlayLayer = UIElement:new({
					parent = backgroundSplash,
					pos = { 0, 0 },
					size = { backgroundSplash.size.w, backgroundSplash.size.h },
					bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR)
				})
				overlayLayer:addCustomDisplay(false, function()
					rad = rad + math.pi / 60
					overlayLayer.bgColor[4] = overlayLayer.bgColor[4] - math.sin(rad) * 0.04
					if (overlayLayer.bgColor[4] <= 0) then
						overlayLayer:kill()
					end
				end)
			end
		end)
end

local function playerWin(viewElement, reqTable)
	EventsOnline:taskComplete()
	play_sound(50)
	local backgroundSplash = UIElement:new({
		parent = viewElement,
		pos = { viewElement.size.w / 2, viewElement.size.h / 2 },
		size = { 0, 0 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
	})
	local doShowPlayerWin = function()
		local congratsText = UIElement:new({
			parent = backgroundSplash,
			pos = { 20, 10 },
			size = { backgroundSplash.size.w - 40, backgroundSplash.size.h / 5 }
		})
		congratsText:addAdaptedText(true, "Bullseye!", nil, nil, FONTS.BIG)
		local submitButton = UIElement:new({
			parent = backgroundSplash,
			pos = { 20, backgroundSplash.size.h / 6 * 2 },
			size = { backgroundSplash.size.w - 40, backgroundSplash.size.h / 3 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		submitButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSUBMIT)
		submitButton:addMouseHandlers(nil, function()
			showUploadWindow(viewElement, reqTable)
		end)
		local playAgainView = UIElement:new({
			parent = backgroundSplash,
			pos = { 20, -backgroundSplash.size.h / 3 + 10 },
			size = { backgroundSplash.size.w - 40, backgroundSplash.size.h / 3 - 20 }
		})
		local saveReplay = UIElement:new({
			parent = playAgainView,
			pos = { 0, 0 },
			size = { playAgainView.size.w / 2 - 5, playAgainView.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		saveReplay:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSSAVEREPLAY)
		saveReplay:addMouseHandlers(nil, function()
				showUploadWindow(viewElement, reqTable, true)
			end)
		local restartGame = UIElement:new({
			parent = playAgainView,
			pos = { -playAgainView.size.w / 2 + 5, 0 },
			size = { playAgainView.size.w / 2 - 5, playAgainView.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		restartGame:addAdaptedText(false, TB_MENU_LOCALIZED.EVENTSNEWGAME)
		restartGame:addMouseHandlers(nil, function()
				TUTORIAL_LEAVEGAME = true
				STOPFRAME = nil
				UIElement:runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
				REPLAY_CAN_BE_SUBMITTED = false
				TUTORIAL_LEAVEGAME = false
				CURRENT_STEP.fallbackrequirement = false
				reqTable.ready = true
			end)
	end
	local rad = math.pi / 4
	backgroundSplash:addCustomDisplay(false, function()
			rad = rad + math.pi / 24
			backgroundSplash.size.w = backgroundSplash.size.w + math.ceil(math.sin(rad) * 46)
			backgroundSplash.size.h = backgroundSplash.size.h + math.ceil(math.sin(rad) * 13)
			backgroundSplash:moveTo((viewElement.size.w - backgroundSplash.size.w) / 2, (viewElement.size.h - backgroundSplash.size.h) / 2)
			if (backgroundSplash.size.w >= 550) then
				backgroundSplash:addCustomDisplay(false, function() end)
				doShowPlayerWin()
				rad = math.pi / 4
				local overlayLayer = UIElement:new({
					parent = backgroundSplash,
					pos = { 0, 0 },
					size = { backgroundSplash.size.w, backgroundSplash.size.h },
					bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR)
				})
				overlayLayer:addCustomDisplay(false, function()
					rad = rad + math.pi / 60
					overlayLayer.bgColor[4] = overlayLayer.bgColor[4] - math.sin(rad) * 0.04
					if (overlayLayer.bgColor[4] <= 0) then
						overlayLayer:kill()
					end
				end)
			end
		end)
end

loadExistingReplay = function(viewElement, reqTable, rplFile)
	local replay = Files:open(rplFile and ("../replay/" .. rplFile) or ("../replay/my replays/--eventtmp" .. CURRENT_TUTORIAL .. ".rpl"))
	if (not replay.data) then
		reqTable.ready = not rplFile
		return false
	end
	local rplData = replay:readAll()
	replay:close()
	
	eventMain(viewElement, reqTable, 2)
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
	add_hook("draw2d", "tbTutorialsCustomStatic", function()
			local ws = get_world_state()
			if (current_step > #steps) then
				remove_hook("draw2d", "tbTutorialsCustomStatic")
				freeze_game()
				edit_game()
				reqTable.ready = not rplFile
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

functions = {
	IntroOverlay = introOverlay,
	OutroOverlay = outroOverlay,
	PrepareNewGame = launchGame,
	LoadReplay = loadExistingReplay,
	HeadInTheWall = eventMain,
	PlayerWon = playerWin,
	PlayerLost = playerLose
}
