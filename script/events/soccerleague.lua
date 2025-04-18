local INTRO = 1
local OUTRO = -1

local loadExistingReplay
local finalPos = { x = 3.25, y = 45, z = 2, rad = 3, shape = CUBE, size = { 20, 5, 4 }, complete = tbTutorialsTaskMark and tbTutorialsTaskMark:isDisplayed(), visible = false }
--local trigObjectId = 32
local checkPoints = {
	{ x = -4, y = 10.94, z = 1.75, h = 6, w = 2, zh = 3.3, shape = CUBE, rad = 2.25, color = { 0, 1, 1, 0.5 }, task = 0, complete = false, costModifier = 0 },
	{ x = 4, y = 10.94, z = 1.75, h = 6, w = 2, zh = 3.3, shape = CUBE, rad = 2.25, color = { 1, 0, 0, 0.5 }, task = 1, complete = tbTutorialsTask.optional[1] and tbTutorialsTask.optional[1].complete, costModifier = 1 },
}
local replayPlaying = false
local taskToggle = nil

local NUM_JOINTS = 20
local MIN_CHECKPOINT_JOINTS = 1
local NUM_JOINTS_OUTSIDE_CHECKPOINT = math.max(0, NUM_JOINTS - MIN_CHECKPOINT_JOINTS)

local function spawnToplist(viewElement)
	local elementHeight = 30
	local toplistHolder = UIElement:new({
		parent = viewElement,
		pos = { viewElement.size.w - 300, 20 },
		size = { 300, 400 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(toplistHolder, elementHeight * 3 / 2, elementHeight - 16, 20, TB_MENU_DEFAULT_BG_COLOR)
	local hideButton = UIElement:new({
		parent = topBar,
		pos = { -topBar.size.w, 0 },
		size = { 25, topBar.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true
	})
	local rotate_dir = 0
	hideButton.toggleEnabled = type(EVENT_TOPLIST_DISPLAYED) == "nil" and true or EVENT_TOPLIST_DISPLAYED
	local angle = hideButton.toggleEnabled and 270 or 90
	if (not hideButton.toggleEnabled) then
		toplistHolder:moveTo(-25)
	end
	hideButton:addCustomDisplay(false, function()
			set_color(unpack(UICOLORWHITE))
			draw_disk(hideButton.pos.x + hideButton.size.w / 2, hideButton.pos.y + hideButton.size.h / 2, 0, hideButton.size.w / 3, 3, 1, 60 + angle, 360 + angle, 0)
			if (rotate_dir ~= 0) then
				angle = angle + 10 * rotate_dir
				if (angle < 0) then
					angle = 360 + angle
				end
				toplistHolder:moveTo((toplistHolder.size.w - 25) / 18 * rotate_dir, 0, true)
				if (angle % 180 - 90 == 0) then
					rotate_dir = 0
				end
			end
		end)
	hideButton:addMouseHandlers(nil, function()
			if (hideButton.toggleEnabled) then
				rotate_dir = 1
				hideButton.toggleEnabled = false
			else
				rotate_dir = -1
				hideButton.toggleEnabled = true
			end
			EVENT_TOPLIST_DISPLAYED = hideButton.toggleEnabled
		end)

	local toplistHeader = UIElement:new({
		parent = topBar,
		pos = { 25, 5 },
		size = { topBar.size.w - 50, topBar.size.h - 10 }
	})
	toplistHeader:addAdaptedText(true, "Quickest Players")

	local reloadButton = UIElement:new({
		parent = topBar,
		pos = { -25, 0 },
		size = { 25, topBar.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true
	})
	local reloadButtonImg = UIElement:new({
		parent = reloadButton,
		pos = { 2, (reloadButton.size.h - (reloadButton.size.w - 4)) / 2 },
		size = { reloadButton.size.w - 4, reloadButton.size.w - 4 },
		bgImage = "../textures/menu/general/buttons/reload.tga",
	})
	reloadButton:addMouseHandlers(nil, function()
			toplistHolder:kill()
			spawnToplist(viewElement)
		end)

	TBMenu:displayLoadingMark(listingHolder, "Loading Top Players")

	local toplistError = function(noEntries)
		listingHolder:kill(true)
		local errorMessage = UIElement:new({
			parent = listingHolder,
			pos = { 25, 10 },
			size = { listingHolder.size.w - 30, listingHolder.size.h - 20 }
		})
		errorMessage:addAdaptedText(true, noEntries and "No players have submitted their replays yet.\nBe the first to join the event!" or "Something went wrong, please try again later")
	end

	local toplistSuccess = function()
		listingHolder:kill(true)
		local response = get_network_response()

		local listElements = {}
		local topSpeed = 0
		for ln in response:gmatch("[^\n]*\n?") do
			if (not ln:find("^#INFO") and ln:len() > 0) then
				local _, segments = ln:gsub("\t", "")
				local data = { ln:match(("([^\t]*)\t?"):rep(segments)) }

				local playerEntry = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, playerEntry)
				local playerName = UIElement:new({
					parent = playerEntry,
					pos = { 10, 2 },
					size = { playerEntry.size.w / 2 - 15, playerEntry.size.h - 5 }
				})
				playerName:addAdaptedText(true, data[1], nil, nil, 4, LEFTMID, 0.7)

				local playerResult = UIElement:new({
					parent = playerEntry,
					pos = { playerEntry.size.w / 2 + 5, 2 },
					size = { playerEntry.size.w / 2 - 15, playerEntry.size.h - 5 }
				})
				playerResult:addAdaptedText(true, data[2] .. " frames", nil, nil, 4, RIGHTMID, 0.7)

				local playerSeparator = UIElement:new({
					parent = playerEntry,
					pos = { 25, -1 },
					size = { playerEntry.size.w - 50, 0.5 },
					bgColor = { 1, 1, 1, 0.2 }
				})

				if (topSpeed == 0) then
					topSpeed = data[2]
				end
			end
		end
		if (#listElements == 0) then
			toplistError(true)
			return
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = scrollBar
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)

		local targetFrames = UIElement:new({
			parent = topBar,
			pos = { 0, topBar.size.h },
			size = { listingHolder.size.h, listingHolder.size.h },
			bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR)
		})
		targetFrames:addCustomDisplay(false, function()
				targetFrames.bgColor[4] = 1 - (-toplistHolder.pos.x + WIN_W - 25) / (toplistHolder.size.w - 25)
				targetFrames:uiText("Top speed: " .. topSpeed .. " frames", -70, 100, FONTS.MEDIUM, nil, 0.8, -90, nil, { 1, 1, 1, targetFrames.bgColor[4] })
			end)
	end

	if (Request.queue ~= nil) then
		Request:queue(function()
			download_server_info("event_toplist&event=" .. CURRENT_TUTORIAL)
		end, "fetch_toplist", toplistSuccess, toplistError)
	else
		download_server_info("event_toplist&event=" .. CURRENT_TUTORIAL)
		Request:new("fetch_toplist", toplistSuccess, toplistError)
	end
end

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
	taskToggle.spawnTime = os.clock()
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

			if (taskToggle.spawnTime > 0 and taskToggle.toggleEnabled and taskToggle.spawnTime + 10 < os.clock()) then
				taskToggle.btnUp()
			end
		end)
	taskToggle:addMouseHandlers(nil, function()
			taskToggle.spawnTime = 0
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
	if (not check or not check.size) then
		return
	end

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
			if (grow >= 2 or rad >= math.pi) then
				check:kill()
			end
		end)
	check:show()
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
	if (not finalPos.complete and finalPos.visible) then
		if (finalPos.element) then
			finalPos.element:kill()
		end
		local destinationMark = UIElement3D:new({
			parent = tbTutorials3DHolder,
			pos = { finalPos.x, finalPos.y, finalPos.z },
			size = finalPos.size or { finalPos.rad, 500 },
			shapeType = finalPos.shape or CAPSULE,
			bgColor = finalPos.color or { 1, 0, 0, 0.5 }
		})
		finalPos.element = destinationMark

		if (trigObjectId) then
			local overseer = UIElement3D:new({
				parent = tbTutorials3DHolder,
				pos = { 0, 0, 0 },
				size = { 0, 0, 0 }
			})
			overseer:addCustomDisplay(nil, function()
					if (finalPos.complete) then
						overseer:kill()
						return
					end

					local x, y, z = get_joint_pos(0, 0)
					local dist = math.pow(finalPos.x - x, 2) + math.pow(finalPos.y - y, 2) + math.pow(finalPos.z - z, 2)
					if (dist >= 200) then
						destinationMark:show()
						destinationMark.bgColor[4] = 0.5
						set_obj_color(trigObjectId - 1, 200 / dist, math.min(1, 1 / (50 - dist)), 1, 1)
					elseif (dist < 50) then
						destinationMark:hide()
						set_obj_color(trigObjectId - 1, 1, 0, dist / 50, 1)
					else
						destinationMark:show()
						destinationMark.bgColor[4] = 0.5 / math.log(200 - dist)
						set_obj_color(trigObjectId - 1, 200 / dist, math.min(1, 1 / (50 - dist)), math.min(1, dist / 50), 1)
					end

					for i,v in pairs(ORBS_DATA) do
						if (not v.touched and v.pos) then
							local x, y, z = get_obj_pos(v.id)
							local dist = math.pow(v.pos[1] - x, 2) + math.pow(v.pos[2] - y, 2) + math.pow(v.pos[3] - z, 2)
							if (dist > 0.01) then
								v.touched = true
								set_obj_color(v.id, 0.59, 0.59, 0.59, 1)
								TBMenu:showDataError("Your result has improved by " .. (v.cost and v.cost or 100) .. " frames!", true)
							end
						end
					end
				end)
		end
	end
	for i,v in pairs(checkPoints) do
		if (not v.complete) then
			if (v.element) then
				v.element:kill()
			end
			local checkPoint = UIElement3D:new({
				parent = tbTutorials3DHolder,
				pos = { v.x, v.y, v.z + (v.shape == CAPSULE and v.zh or 0) },
				size = v.shape == CUBE and { v.h, v.w, v.zh } or { v.rad, v.zh * 2 },
				shapeType = v.shape,
				bgColor = v.color and cloneTable(v.color) or { 0, 0, 1, 0.5 }
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
			local winframe = WIN_FRAME + 10000
			for i,v in pairs(checkPoints) do
				if (v.complete == true) then
					winframe = winframe - 10000 * (v.costModifier or i)
				end
			end
			file:writeLine("#ENDFRAME " .. winframe)
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
				local prizeDelivered, replacements = response:gsub("^.*;(%w)$", '%1')
				if (replacements == 0 or prizeDelivered ~= '1') then
					CURRENT_STEP.skip = 3
				end
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
				upload_event_replay(name, "Event Squad's Soccer League entry", "ESEVNT" .. CURRENT_TUTORIAL, "replay/my replays/" .. name .. ".rpl")
			end, "replayupload", success, error)
		else
			upload_event_replay(name, "Event Squad's Soccer League entry", "ESEVNT" .. CURRENT_TUTORIAL, "replay/my replays/" .. name .. ".rpl")
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
	local buttonWidth = WIN_W / 3 > 420 and 420 or WIN_W / 3
	local submitButton = UIElement:new({
		parent = viewElement,
		pos = { (WIN_W - buttonWidth) / 2, -120 },
		size = { buttonWidth, 70 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 5
	})
	submitButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSUBMIT)
	submitButton:addMouseHandlers(nil, function()
			freeze_game()
			CURRENT_STEP.skip = skipAdd
			reqTable.ready = true
		end)
	return submitButton
end

local function restartGame()
	TUTORIAL_LEAVEGAME = true
	STOPFRAME = nil
	finalPos.complete = false
	tbTutorialsTaskMark:hide(true)
	for i,v in pairs(checkPoints) do
		v.complete = false
		if (v.task) then
			Tutorials:taskOptIncomplete(v.task)
		end
	end
	loadCheckpoints()
	REPLAY_CAN_BE_SUBMITTED = false
	WIN_FRAME = 100000
	UIElement:runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
	TUTORIAL_LEAVEGAME = false
	return 1
end

local function displayYouLostScreen(viewElement)
	local youLostBackground = UIElement:new({
		parent = viewElement,
		pos = { viewElement.size.w / 2 - 350, viewElement.size.h / 2 - 125 },
		size = { 700, 250 },
		bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR),
		shapeType = ROUNDED,
		rounded = 5
	})
	youLostBackground.bgColor[4] = 0.9
	youLostBackground:addCustomDisplay(nil, function()
			local ws = get_world_state()
			if (ws.replay_mode == 0 and ws.winner == -1) then
				youLostBackground:kill()
			end
		end)
	local youLostText = UIElement:new({
		parent = youLostBackground,
		pos = { 20, 10 },
		size = { youLostBackground.size.w - 40, youLostBackground.size.h / 3 - 15 }
	})
	youLostText:addAdaptedText(true, "You lost :(", nil, nil, FONTS.BIG)

	local youLostText2 = UIElement:new({
		parent = youLostBackground,
		pos = { 20, 15 + youLostBackground.size.h / 3 },
		size = { youLostBackground.size.w - 40, youLostBackground.size.h / 3 - 15 }
	})
	youLostText2:addAdaptedText(true, "Your ball / head shouldn't touch the red goal protectors!")

	local startOverButton = UIElement:new({
		parent = youLostBackground,
		pos = { 60, youLostText2.shift.y + youLostText2.size.h + 15 },
		size = { youLostBackground.size.w - 120, youLostBackground.size.h - 30 - (youLostText2.shift.y + youLostText2.size.h) },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 5
	})
	local startOverButtonText = UIElement:new({
		parent = startOverButton,
		pos = { 10, 5 },
		size = { startOverButton.size.w - 20, startOverButton.size.h - 10 }
	})
	startOverButtonText:addAdaptedText(true, "Start over")
	startOverButton:addMouseHandlers(nil, function()
			restartGame()
		end)
end

local function eventMain(viewElement, reqTable, skipAdd)
	dofile('system/replays_manager.lua')
	local skipAdd = skipAdd or 0
	spawnTaskToggle()
	TUTORIAL_SPECIAL_RP_IGNORE = true

	loadCheckpoints()
	chat_input_deactivate()
	if (skipAdd == 0) then
		--spawnToplist(viewElement)
		local gameRulesScreen = nil
		add_hook("leave_game", "tbTutorialsCustomStatic", function()
				if (TUTORIAL_LEAVEGAME) then
					return 1
				end
			end)
		add_hook("key_up", "tbTutorialsCustom", function(key)
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
						tbTutorialsTaskMark:hide(true)
					end
					for i,v in pairs(checkPoints) do
						if (not v.complete and v.task) then
							Tutorials:taskOptIncomplete(v.task)
						end
					end
					loadCheckpoints()
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

					finalPos.complete = false
					for i,v in pairs(checkPoints) do
						v.complete = false
					end
					if (not REPLAY_CAN_BE_SUBMITTED) then
						tbTutorialsTaskMark:hide(true)
						for i,v in pairs(checkPoints) do
							if (v.task) then
								Tutorials:taskOptIncomplete(v.task)
							end
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
					return restartGame()
				end
				if (key == 44) then
					set_replay_speed(get_replay_speed() - 0.1)
					return 1
				elseif (key == 46) then
					set_replay_speed(get_replay_speed() + 0.1)
					return 1
				end
				if (key == 108 and get_keyboard_ctrl() > 0 and not EVENT_REPLAY_BROWSER_ISOPEN) then
					if (Replays.ver and Replays.ver >= 1.1) then
						EVENT_REPLAY_BROWSER_ISOPEN = true
						Replays:showCustomReplaySelection(viewElement, CURRENT_TUTORIAL .. ".tbm", function(path)
								TUTORIAL_LEAVEGAME = true
								UIElement:runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
								TUTORIAL_LEAVEGAME = false
								finalPos.complete = false
								tbTutorialsTaskMark:hide(true)
								for i,v in pairs(checkPoints) do
									v.complete = false
									if (v.task) then
										Tutorials:taskOptIncomplete(v.task)
									end
								end
								loadExistingReplay(viewElement, reqTable, path)
								EVENT_REPLAY_BROWSER_ISOPEN = false
							end)
					end
				end
				if (get_keyboard_ctrl() > 0 or get_keyboard_alt() > 0) then
					return 1
				end
		end)
		add_hook("key_down", "tbTutorialsCustom", function(key)
				if (key == 103) then
					if (gameRulesScreen) then
						gameRulesScreen:kill()
						gameRulesScreen = nil
						return 1
					end
					gameRulesScreen = TBMenu:spawnWindowOverlay(TB_TUTORIAL_MODERN_GLOBALID)
					gameRulesScreen:addMouseHandlers(nil, function() gameRulesScreen:kill() gameRulesScreen = nil end)
					local height = math.max(250, WIN_H / 4)
					local gameRulesView = UIElement:new({
						parent = gameRulesScreen,
						pos = { WIN_W / 4, (WIN_H - height) / 2 },
						size = { WIN_W / 2, height },
						bgColor = TB_MENU_DEFAULT_BG_COLOR,
						shapeType = ROUNDED,
						rounded = 5
					})
					local rulesTitle = UIElement:new({
						parent = gameRulesView,
						pos = { 50, 10 },
						size = { gameRulesView.size.w - 100, math.min(40, gameRulesView.size.h / 5) }
					})
					rulesTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MAINMENUGAMERULESNAME, nil, nil, FONTS.BIG)
					local gameRulesCloseButton = UIElement:new({
						parent = gameRulesView,
						pos = { -rulesTitle.size.h - 5, 5 },
						size = { rulesTitle.size.h, rulesTitle.size.h },
						interactive = true,
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
						hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
						shapeType = ROUNDED,
						rounded = 4
					})
					local gameRulesCloseButtonIcon = UIElement:new({
						parent = gameRulesCloseButton,
						pos = { 10, 10 },
						size = { gameRulesCloseButton.size.w - 20, gameRulesCloseButton.size.h - 20 },
						bgImage = "../textures/menu/general/buttons/crosswhite.tga"
					})
					gameRulesCloseButton:addMouseHandlers(nil, function()
							gameRulesScreen:kill()
							gameRulesScreen = nil
						end)

					local gameRules = get_game_rules()
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
				pos = { -290, -55 },
				size = { 290, 40 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			local customReplayButtonText = UIElement:new({
				parent = customReplayButton,
				pos = { 10, 3 },
				size = { customReplayButton.size.w - customReplayButton.size.h - 20, customReplayButton.size.h - 3 }
			})
			local customReplayButtonKillOutline = UIElement:new({
				parent = customReplayButton,
				pos = { -customReplayButton.size.h + 2, 2 },
				size = { customReplayButton.size.h - 4, customReplayButton.size.h - 4 },
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				shapeType = customReplayButton.shapeType,
				rounded = customReplayButton.rounded
			})
			local customReplayButtonKill = UIElement:new({
				parent = customReplayButtonKillOutline,
				pos = { 1, 1 },
				size = { customReplayButtonKillOutline.size.w - 2, customReplayButtonKillOutline.size.h - 2 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				shapeType = customReplayButton.shapeType,
				rounded = customReplayButton.rounded
			})
			local customReplayButtonKillIcon = UIElement:new({
				parent = customReplayButtonKill,
				pos = { 5, 5 },
				size = { customReplayButtonKill.size.w - 10, customReplayButtonKill.size.h - 10 },
				bgImage = "../textures/menu/general/buttons/crosswhite.tga"
			})
			customReplayButtonText:addAdaptedText(false, TB_MENU_LOCALIZED.EVENTSLOADCUSTOMREPLAY or "Load replay (CTRL + L)")
			customReplayButton:addMouseHandlers(false, function()
					Replays:showCustomReplaySelection(viewElement, CURRENT_TUTORIAL .. ".tbm", function(path)
							TUTORIAL_LEAVEGAME = true
							UIElement:runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
							TUTORIAL_LEAVEGAME = false
							finalPos.complete = false
							tbTutorialsTaskMark:hide(true)
							for i,v in pairs(checkPoints) do
								v.complete = false
								if (v.task) then
									Tutorials:taskOptIncomplete(v.task)
								end
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

	--[[local framesElapsed = UIElement:new({
		parent = viewElement,
		pos = { 0, 50 },
		size = { WIN_W, 30 },
		uiColor = TB_MENU_DEFAULT_YELLOW
	})
	framesElapsed:addCustomDisplay(true, function()
			local ws = get_world_state()
			if (ws.match_frame > 0 or WIN_FRAME < 100000) then
				local frame = WIN_FRAME
				framesElapsed:uiText(frame .. (TB_MENU_LOCALIZED.EVENTFRAMESELAPSED and (" " .. TB_MENU_LOCALIZED.EVENTFRAMESELAPSED) or " frames elapsed"))
			end
		end)]]
	local submitButton = nil
	local frame_checked = 0
	add_hook("draw2d", "tbTutorialsCustom", function()
			local ws = get_world_state()
			if (ws.winner == 0 and not REPLAY_CAN_BE_SUBMITTED) then
				WIN_FRAME = ws.match_frame
				REPLAY_CAN_BE_SUBMITTED = true
				finalPos.complete = true
				checkpointComplete(finalPos.element)
				EventsOnline:taskComplete()
			elseif (ws.winner == 1 and WIN_FRAME == 100000) then
				WIN_FRAME = ws.match_frame
				displayYouLostScreen(viewElement)
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
			if (ws.match_frame >= ws.game_frame or ws.match_frame >= WIN_FRAME + 20) then
				TUTORIAL_LEAVEGAME = true
				rewind_replay()
				TUTORIAL_LEAVEGAME = false
				return
			end
			if (ws.match_frame ~= frame_checked) then
				if (not finalPos.complete) then
					for i,check in pairs(checkPoints) do
						if (not check.complete) then
							local criteriaMet = 19
							--for i,v in pairs(JOINTS) do
								local x, y, z = get_joint_pos(0, 0)
								-- apply displacement
								x = x - 1
								y = y + 0.1
								if (check.shape == CAPSULE) then
									local xR, yR = x - check.x, y - check.y
									if (xR * xR + yR * yR > check.rad * check.rad) then
										criteriaMet = criteriaMet + 1
										--break
									end
								else
									if (check.x - check.h / 2 > x or check.x + check.h / 2 < x or
										check.y - check.w / 2 > y or check.y + check.w / 2 < y or
										check.z - check.zh / 2 > z or check.z + check.zh / 2 < z) then
										criteriaMet = criteriaMet + 1
									end
								end
							--end
							if (criteriaMet <= NUM_JOINTS_OUTSIDE_CHECKPOINT) then
								Tutorials:taskOptComplete(check.task)
								check.complete = true
								checkpointComplete(check.element)
							end
						end
					end
					--[[local criteriaMet = 0
					for i,v in pairs(JOINTS) do
						local x, y, z = get_joint_pos(0, v)
						-- apply displacement
						x = x - 1
						y = y + 0.1
						if (finalPos.shape == CAPSULE) then
							local xR, yR = x - finalPos.x, y - finalPos.y
							if (xR * xR + yR * yR > finalPos.rad * finalPos.rad) then
								criteriaMet = criteriaMet + 1
							end
						else
							if (finalPos.x - finalPos.size[1] / 2 > x or finalPos.x + finalPos.size[1] / 2 < x or
								finalPos.y - finalPos.size[2] / 2 > y or finalPos.y + finalPos.size[2] / 2 < y or
								finalPos.z - finalPos.size[3] / 2 > z or finalPos.z + finalPos.size[3] / 2 < z) then
								criteriaMet = criteriaMet + 1
							end
						end
					end
					if (criteriaMet < NUM_JOINTS_OUTSIDE_CHECKPOINT) then
						WIN_FRAME = ws.match_frame
						REPLAY_CAN_BE_SUBMITTED = true
						finalPos.complete = true

						checkpointComplete(finalPos.element)
						EventsOnline:taskComplete()
					end--]]
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
		if (v.task) then
			Tutorials:taskOptIncomplete(v.task)
		end
	end
	loadCheckpoints()
	local rplData = replay:readAll()
	replay:close()

	local steps = {}
	for i, ln in pairs(rplData) do
		if (ln:find("^FRAME %d+")) then
			local rplFrame = ln:gsub("^FRAME (%d+);.*$", "%1")
			rplFrame = tonumber(rplFrame)
			if (#steps > 0) then
				if (rplFrame < steps[#steps].frame) then
					steps = {}
				end
			end
			table.insert(steps, { frame = rplFrame, moves = {}, grip = {} })
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
					local criteriaMet = 0
					for i,v in pairs(JOINTS) do
						local x, y, z = get_joint_pos(0, v)
						-- apply displacement
						x = x - 1
						y = y + 0.1
						if (check.shape == CAPSULE) then
							local xR, yR = x - check.x, y - check.y
							if (xR * xR + yR * yR > check.rad * check.rad) then
								criteriaMet = criteriaMet + 1
								--break
							end
						else
							if (check.x - check.h / 2 > x or check.x + check.h / 2 < x or
								check.y - check.w / 2 > y or check.y + check.w / 2 < y or
								check.z - check.zh / 2 > z or check.z + check.zh / 2 < z) then
								criteriaMet = criteriaMet + 1
							end
						end
					end
					if (criteriaMet < NUM_JOINTS_OUTSIDE_CHECKPOINT) then
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
				STOPFRAME = nil
			elseif (ws.match_frame == steps[current_step].frame) then
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
	set_discord_rpc("Soccer League " .. tutorialNum, TB_MENU_LOCALIZED.DISCORDRPCPLAYINGSPEVENT or "Playing SP Event")
end

local function launchGame(viewElement, reqTable)
	local req = { type = "newgame", ready = false }
	table.insert(reqTable, req)
	TUTORIAL_LEAVEGAME = true
	setDiscordRPC()

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
