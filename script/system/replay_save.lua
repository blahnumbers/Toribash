if (TBMenu == nil) then
	open_menu(19)
	close_menu()
end

require("toriui.uielement")
require("system.menu_manager")

REPLAY_SAVETEMPNAME = "--localreplaytempfile"
REPLAY_FOLDER = REPLAY_FOLDER or '/my replays'
REPLAY_SELECTOR_SHIFT = REPLAY_SELECTOR_SHIFT or { 0 }

rploptions = { hint = get_option("hint"), feedback = get_option("feedback") }
--local REPLAY_NEWGAME = false

for i,v in pairs(rploptions) do
	set_option(i, 0)
end

local function quitReplaySave()
	remove_hooks("replaySaveHandler")
	for i,v in pairs(rploptions) do
		set_option(i, v)
	end
	replaySaveOverlay:kill()
end

replaySaveOverlay = TBMenu:spawnWindowOverlay(TB_MENU_HUB_GLOBALID)
local replaySave = UIElement:new({
	parent = replaySaveOverlay,
	pos = { WIN_W / 4, WIN_H / 2 - 90 },
	size = { WIN_W / 2, 180 },
	bgColor = TB_MENU_DEFAULT_BG_COLOR,
	shapeType = ROUNDED,
	rounded = 5,
	interactive = true
})
UIElement:runCmd("savereplay " .. REPLAY_SAVETEMPNAME)

local replaySaveTitle = replaySave:addChild({
	pos = { 10, 0 },
	size = { replaySave.size.w - 20, 50 }
})
replaySaveTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSSAVING, nil, nil, FONTS.BIG, nil, 0.65)
local replayFolderPicker = replaySave:addChild({
	pos = { 10, replaySaveTitle.size.h + replaySaveTitle.shift.y + 10 },
	size = { (replaySave.size.w - 20) / 3, 40 },
	bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
	rounded = 4
}, true)
local dropdownOptions = {}
local folderPrefix = REPLAY_FOLDER .. '/'
local defaultFolderId = nil
local getFolders
getFolders = function(dir, level)
	for i,v in pairs(get_files('replay' .. dir, '')) do
		if (not v:match(".rpl$") and (dir .. "/" .. v ~= '/system') and not v:find("^%.+[%s%S]*$") and not v:find("%.%a+$")) then
			table.insert(dropdownOptions, {
				text = (level > 0 and ('' .. string.rep(" ", level * 2)) or '') .. v .. '',
				action = function()
					REPLAY_FOLDER = dir .. "/" .. v
					folderPrefix = REPLAY_FOLDER .. '/'
				end
			})
			if ((dir .. "/" .. v) == REPLAY_FOLDER) then
				defaultFolderId = #dropdownOptions
			end
			getFolders(dir .. '/' .. v, level + 1)
		end
	end
end
pcall(function() getFolders('', 0) end)

if (#dropdownOptions > 0) then
	local dropdown = TBMenu:spawnDropdown(replayFolderPicker, dropdownOptions, 30, WIN_H / 3, defaultFolderId, { scale = 0.8 }, { scale = 0.6, orientation = LEFTMID })
	dropdown.selectedElement:addMouseHandlers(nil, function()
		dropdown:show(true)
		if (dropdown.listElements) then
			for i,v in pairs(dropdown.listElements) do
				v:hide()
			end
			dropdown.listHolder.scrollBar:makeScrollBar(dropdown.listHolder, dropdown.listElements, dropdown.listReload, REPLAY_SELECTOR_SHIFT, nil, true)
		end
	end)
else
	replayFolderPicker.size.w = 0
	replayFolderPicker.shift.x = 0
end

local replaySaveButton = replaySave:addChild({
	pos = { replaySave.size.w / 2 + 5, -50 },
	size = { replaySave.size.w / 2 - 15, 40 },
	interactive = true,
	bgColor = { 0, 0, 0, 0.1 },
	hoverColor = { 0, 0, 0, 0.3 },
	pressedColor = { 1, 1, 1, 0.2 },
	rounded = 4
}, true)
replaySaveButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSAVE)

local replayCancelButton = replaySave:addChild({
	pos = { 10, -50 },
	size = { replaySave.size.w / 2 - 15, 40 },
	interactive = true,
	bgColor = { 0, 0, 0, 0.1 },
	hoverColor = { 0, 0, 0, 0.3 },
	pressedColor = { 1, 1, 1, 0.2 },
	rounded = 4
}, true)
replayCancelButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCANCEL)
replayCancelButton:addMouseHandlers(nil, function()
		quitReplaySave()
	end)

local replayNameBackground = replaySave:addChild({
	pos = { replayFolderPicker.shift.x + replayFolderPicker.size.w + 10, replayFolderPicker.shift.y },
	size = { replaySave.size.w - replayFolderPicker.shift.x - replayFolderPicker.size.w - 20, replayFolderPicker.size.h },
	bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
	rounded = 4
}, true)
local replayNameInput = TBMenu:spawnTextField(replayNameBackground, nil, nil, nil, nil, nil, nil, 4, 0.7, UICOLORWHITE, TB_MENU_LOCALIZED.REPLAYSENTERNAME, CENTERMID, nil, nil, true)

local function saveReplay(newname)
	if (newname == "" or not newname) then
		TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERROREMPTYNAME, true)
		return
	end
	if (newname:find("[^%d%a-_ ]") or not newname:find("[%a%d]")) then
		TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORCHARACTERS, true)
		return
	end
	local filename = folderPrefix .. newname

	local doRenameReplay = function()
		-- Delete existing replay if it exists
		local error = rename_replay("my replays/" .. REPLAY_SAVETEMPNAME .. ".rpl", filename .. ".rpl")
		if (error) then
			TBMenu:showDataError(error, true)
			return
		end
		local rplFile = Files:open("../replay" .. filename .. ".rpl")
		if (not rplFile.data) then
			TBMenu:showDataError(TB_MENU_LOCALIZED.REPLAYSERRORRENAMING, true)
			quitReplaySave()
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

	local file = Files:open("../replay" .. filename .. ".rpl")
	if (file.data) then
		file:close()
		TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYWITHNAMEEXISTSPROMPT, function()
			delete_replay(filename .. ".rpl")
			doRenameReplay()
		end)
	else
		doRenameReplay()
	end
end

replayNameInput:addEnterAction(function() saveReplay(replayNameInput.textfieldstr[1]:gsub("%.rpl$", "")) end)
replaySaveButton:addMouseHandlers(nil, function()
		saveReplay(replayNameInput.textfieldstr[1]:gsub("%.rpl$", ""))
	end)

add_hook("key_up", "replaySaveHandler", function(s) UIElement:handleKeyUp(s) return 1 end)
add_hook("key_down", "replaySaveHandler", function(s) UIElement:handleKeyDown(s) return 1 end)
--add_hook("new_game_mp", "replaySaveHandler", function() REPLAY_NEWGAME = true end)

replayNameInput:btnDown()
replayNameInput.keyboard = true
disable_camera_movement()
