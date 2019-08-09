local INTRO = 1
local OUTRO = -1

local openerStopframe = 60
STOPFRAME = openerStopframe

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
	local skipAdd = skipAdd or 0
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
	
	EventsOnline:taskOptIncomplete(1)
	EventsOnline:taskOptIncomplete(2)
	
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
					if (get_world_state().match_frame < openerStopframe) then
						return 1
					end
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
					STOPFRAME = get_world_state().match_frame
					if (STOPFRAME < openerStopframe) then
						STOPFRAME = openerStopframe
						return 1
					end
					TUTORIAL_LEAVEGAME = true
					rewind_replay()
					TUTORIAL_LEAVEGAME = false
					return 1
				end
				if (key == 32 and get_world_state().replay_mode == 1) then
					TUTORIAL_LEAVEGAME = true
					STOPFRAME = openerStopframe
					open_replay("system/events/" .. CURRENT_TUTORIAL .. ".rpl")
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
	end
	
	local submitButton = nil
	local advComplete = false
	add_hook("draw2d", "tbTutorialsCustom", function()
			local ws = get_world_state()
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
			if (ws.match_frame >= ws.game_frame) then
				TUTORIAL_LEAVEGAME = true
				rewind_replay()
				TUTORIAL_LEAVEGAME = false
				return
			end
			if (not REPLAY_CAN_BE_SUBMITTED and ws.replay_mode == 0) then
				if (get_joint_dismember(1, 0)) then
					REPLAY_CAN_BE_SUBMITTED = true
					EventsOnline:taskOptComplete(1)
				end
			end
			if (not advComplete and ws.replay_mode == 0) then
				local criteriaMet = true
				for i,v in pairs(JOINTS) do
					local dismembered = get_joint_dismember(1, v)
					if (in_array(v, { 1, 2, 3 })) then
						if (not dismembered) then
							criteriaMet = false
						end
					end
					if (in_array(v, { 4, 5, 7, 8, 12, 13, 14, 15 })) then
						if (dismembered) then
							criteriaMet = false
						end
					end
				end
				if (criteriaMet) then
					EventsOnline:taskOptComplete(2)
					advComplete = true
				end
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
	UIElement:runCmd("lm classic.tbm")
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
		open_replay("system/events/" .. CURRENT_TUTORIAL .. ".rpl")
		freeze_game()
		REPLAY_RUNNING = true
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

local function playOpenerFrames()
	run_frames(openerStopframe)
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
	download_head("fred")
end

functions = {
	IntroOverlay = introOverlay,
	OutroOverlay = outroOverlay,
	InitCheckpoints = loadCheckpoints,
	PrepareNewGame = launchGame,
	OpenerChallenge = eventMain,
	UploadEventEntry = showUploadWindow,
	PlayOpener = playOpenerFrames,
	CheckReplay = checkOpenerReplay
}
