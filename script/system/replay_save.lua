if (TBMenu == nil) then
	open_menu(19)
	close_menu()
end
if (TBMenu.ReplaySaveOverlay ~= nil) then
	return
end

require("toriui.uielement")
require("system.menu_manager")
require("system.replays_manager")

TBMenu.ReplaySaveOverlay = TBMenu:spawnWindowOverlay(TB_MENU_HUB_GLOBALID)
local defaultKillAction = TBMenu.ReplaySaveOverlay.killAction
TBMenu.ReplaySaveOverlay.killAction = function()
	if (defaultKillAction ~= nil) then
		defaultKillAction()
	end
	TBMenu.ReplaySaveOverlay = nil
	enable_camera_movement()
end

local replaySave = TBMenu.ReplaySaveOverlay:addChild({
	shift = { WIN_W / 4, WIN_H / 2 - 90 },
	bgColor = TB_MENU_DEFAULT_BG_COLOR,
	shapeType = ROUNDED,
	rounded = 5,
	interactive = true
})
runCmd("savereplay " .. Replays.GetSaveTempName(), nil, CMD_ECHO_FORCE_DISABLED)

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

local folderPrefix = Replays.SaveFolder .. '/'
local dropdownOptions = Replays:getReplayFoldersDropdownOptions(function(path)
		Replays.SaveFolder = path
		folderPrefix = Replays.SaveFolder .. '/'
	end, Replays.SaveFolder)
if (#dropdownOptions > 0) then
	TBMenu:spawnDropdown(replayFolderPicker, dropdownOptions, 30, WIN_H / 3, nil, { scale = 0.8 }, { scale = 0.6, orientation = LEFTMID })
else
	replayFolderPicker.size.w = 0
	replayFolderPicker:moveTo(0)
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
		TBMenu.ReplaySaveOverlay:kill()
	end)

local replayNameBackground = replaySave:addChild({
	pos = { replayFolderPicker.shift.x + replayFolderPicker.size.w + 10, replayFolderPicker.shift.y },
	size = { replaySave.size.w - replayFolderPicker.shift.x - replayFolderPicker.size.w - 20, replayFolderPicker.size.h },
	bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
	rounded = 4
}, true)
local replayNameInput = TBMenu:spawnTextField2(replayNameBackground, { }, nil, TB_MENU_LOCALIZED.REPLAYSENTERNAME, {
	fontId = 4,
	textScale = 0.7,
	textAlign = CENTERMID,
	darkerMode = true
})

local function saveReplay(newname)
	if (newname == "" or not newname) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERROREMPTYNAME)
		return
	end
	if (utf8.find(newname, "[^%d%a-_ ]") or not utf8.find(newname, "[%a%d]")) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORCHARACTERS)
		return
	end
	local filename = folderPrefix .. newname

	local doRenameReplay = function()
		local error = rename_replay("my replays/" .. Replays.GetSaveTempName() .. ".rpl", filename .. ".rpl")
		if (error) then
			TBMenu:showStatusMessage(error)
			return
		end
		local rplFile = Files.Open("../replay/" .. filename .. ".rpl")
		if (not rplFile.data) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORRENAMING)
			TBMenu.ReplaySaveOverlay:kill()
			return
		end

		---Updated behavior as per Toribash 5.65 \
		---Write full replay data to a string, if there are no errors overwrite the original file.
		---This way we ensure we don't get stuck with an unclosed file interface and the replay
		---doesn't get corrupted in case of parsing errors.
		local fileData = rplFile:readAll()
		rplFile:close()
		local newData = ""

		local res = pcall(function()
			for _, ln in pairs(fileData) do
				if (utf8.find(ln, "^FIGHTNAME %d;")) then
					newData = newData .. "FIGHTNAME 0; " .. newname .. "\n"
				else
					newData = newData .. ln .. "\n"
				end
			end
		end)

		---Consider showing some error if result is false?
		---Replay is saved but it will display a temp file name when viewed
		if (res == true) then
			rplFile:reopen(FILES_MODE_WRITE)
			rplFile:writeLine(newData)
			rplFile:close()
		end

		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSSAVEREPLAYSUCCESS .. " " .. filename .. ".rpl")
		TBMenu.ReplaySaveOverlay:kill()

		---Request app review on mobile platforms
		pcall(function()
			if (not TUTORIAL_ISACTIVE and TB_MENU_PLAYER_INFO.data.qi > 19) then
				request_app_review()
			end
		end)
	end

	local file = Files.Open("../replay/" .. filename .. ".rpl")
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

replayNameInput.btnDown()
replayNameInput.keyboard = true
disable_camera_movement()
