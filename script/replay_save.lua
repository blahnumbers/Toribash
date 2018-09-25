dofile("toriui/uielement.lua")
dofile("system/menu_manager.lua")
dofile("system/replays_manager.lua")

rploptions = { hint = get_option("hint"), feedback = get_option("feedback"), text = get_option("text") }
for i,v in pairs(rploptions) do
	set_option(i, 0)
end

local function quitReplaySave(timeout)
	remove_hooks("tbMenuKeyboardHandler")
	remove_hooks("replaySaveMouseHandler")
	replaySave:kill()
	for i,v in pairs(rploptions) do
		set_option(i, v)
	end
	if (timeout) then
		timeoutWait = UIElement:new({
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		local waitTime = os.clock()
		timeoutWait:addCustomDisplay(true, function()
				if (os.clock() > waitTime + timeout) then
					if (not tbMenuMain) then
						remove_hooks("tbMainMenuVisual")
					end
					timeoutWait:kill()
				end
			end)
		return
	end
	if (TB_MENU_MAIN_ISOPEN == 0) then
		remove_hooks("tbMainMenuVisual")
	end
end

replaySave = UIElement:new({
	pos = { WIN_W / 4, WIN_H / 2 - 90 },
	size = { WIN_W / 2, 180 },
	bgColor = TB_MENU_DEFAULT_BG_COLOR
})
UIElement:runCmd("savereplay " .. REPLAY_SAVETEMPNAME)
replaySave:addCustomDisplay(false, function()
		if (TB_MENU_MAIN_ISOPEN == 1) then
			quitReplaySave(timeout)
		end
	end)

local replaySaveTitle = UIElement:new({
	parent = replaySave,
	pos = { 10, 0 },
	size = { replaySave.size.w - 20, 50 }
})
replaySaveTitle:addAdaptedText(true, "Saving replay", nil, nil, FONTS.BIG, nil, 0.65)
local replaySaveInfo = UIElement:new({
	parent = replaySave,
	pos = { 10, replaySaveTitle.shift.y + replaySaveTitle.size.h },
	size = { replaySave.size.w - 20, 20 }
})
replaySaveInfo:addAdaptedText(true, "Replay file will be save to \'my replays\' folder", nil, nil, 4, nil, 0.6)
local replaySaveButton = UIElement:new({
	parent = replaySave,
	pos = { replaySave.size.w / 2 + 5, -50 },
	size = { replaySave.size.w / 2 - 15, 40 },
	interactive = true,
	bgColor = { 0, 0, 0, 0.1 },
	hoverColor = { 0, 0, 0, 0.3 },
	pressedColor = { 1, 1, 1, 0.2 }
})
replaySaveButton:addAdaptedText(false, "Save")

local replayCancelButton = UIElement:new({
	parent = replaySave,
	pos = { 10, -50 },
	size = { replaySave.size.w / 2 - 15, 40 },
	interactive = true,
	bgColor = { 0, 0, 0, 0.1 },
	hoverColor = { 0, 0, 0, 0.3 },
	pressedColor = { 1, 1, 1, 0.2 }
})
replayCancelButton:addAdaptedText(false, "Cancel")
replayCancelButton:addMouseHandlers(nil, function()
		quitReplaySave()
	end)
local replayNameBackground = UIElement:new({
	parent = replaySave,
	pos = { 10, replaySaveInfo.shift.y + replaySaveInfo.size.h + 10 },
	size = { replaySave.size.w - 20, 40 },
	bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
})
local replayNameOverlay = UIElement:new({
	parent = replayNameBackground,
	pos = { 1, 1 },
	size = { replayNameBackground.size.w - 2, replayNameBackground.size.h - 2 },
	bgColor = { 1, 1, 1, 0.6 }
})
local replayNameInput = UIElement:new({
	parent = replayNameOverlay,
	pos = { 10, 0 },
	size = { replayNameOverlay.size.w - 20, replayNameOverlay.size.h },
	interactive = true,
	textfield = true,
	textfieldsingleline = true
})
TBMenu:displayTextfield(replayNameInput, FONTS.SMALL, 1, UICOLORBLACK, "Enter replay name", CENTERMID)
replayNameInput:addMouseHandlers(nil, function()
		TBMenu:enableMenuKeyboard(replayNameInput)
	end)

local function saveReplay(newname)
	if (newname == "" or not newname) then
		TBMenu:showDataError("Replay name cannot be empty", true)
		return
	end
	if (newname:find("[^%d%a-_ ]") or not newname:find("[%a%d]")) then
		TBMenu:showDataError("Replay name must be alphanumeric and can only contain underscores, spaces or dashes as special characters", true)
		return
	end
	local error = move_replay("my replays/" .. REPLAY_SAVETEMPNAME .. ".rpl", "my replays/" .. newname .. ".rpl")
	if (error) then
		TBMenu:showDataError(error, true)
		return
	end
	local rplFile = Files:new("../replay/my replays/" .. newname .. ".rpl")
	if (not rplFile or not rplFile.data) then
		TBMenu:showDataError("Error renaming replay, please change replay name with replays menu", true)
		quitReplaySave(3)
		return
	end
	
	local fileData = rplFile:readAll()
	rplFile.mode = FILES_MODE_WRITE
	rplFile:reopen()
	for i,ln in pairs(fileData) do
		if (ln:find("^FIGHTNAME %d;")) then
			rplFile:writeLine("FIGHTNAME 0; " .. newname)
		else
			rplFile:writeLine(ln)
		end
	end
	rplFile:close()
	quitReplaySave()
end

replayNameInput:addEnterAction(function() saveReplay(replayNameInput.textfieldstr[1]:gsub("%.rpl$", "")) end)
replaySaveButton:addMouseHandlers(nil, function()
		saveReplay(replayNameInput.textfieldstr[1]:gsub("%.rpl$", ""))
	end)

add_hook("mouse_button_down", "replaySaveMouseHandler", function(s, x, y) 
	UIElement:handleMouseDn(s, x, y) 
	return 1
end)
add_hook("key_up", "tbMenuKeyboardHandler", function(s) UIElement:handleKeyUp(s) return 1 end)
add_hook("key_down", "tbMenuKeyboardHandler", function(s) UIElement:handleKeyDown(s) return 1 end)
add_hook("draw2d", "tbMainMenuVisual", function() TBMenu:drawVisuals() end)