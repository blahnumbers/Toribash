-- Mods manager

if (Mods == nil) then
	local _, top_y = get_window_safe_size()

	---@class ModsListEntryInfo
	---@field time number Click time in seconds
	---@field mod string

	---@class ModFolder
	---@field name string
	---@field mods string[]
	---@field folders string[]
	---@field contents ModFolder[]
	---@field parent ModFolder|nil

	---**Mod browser class**
	---
	---**Version 5.61**
	---* Updated keyboard return type for search bar on mobile devices
	---* On mobile, hitting return key in search bar now hides the keyboard
	---* Added `Quit()` method to exit Mods from other scripts
	---
	---**Version 5.60**
	---* Moved globals to be Mods class fields
	---* Updates for touch input and new UIElement functionality
	---* Visuals update to match modern style
	---@class Mods
	---@field MainElement UIElement
	---@field DisplayPos Vector2Base Current target position for mod browser window
	---@field LastShift number[] Last scroll list shift
	---@field LastMenu ModsListEntryInfo Last clicked menu button
	---@field StartNewGame boolean Whether to automatically start new game after loading mod
	Mods = {
		DisplayPos = { x = SAFE_X + 10, y = top_y + 10 },
		ListShift = { 0 },
		StartNewGame = true,
		ver = 5.61
	}
	Mods.__index = Mods
end

---Destroys Mods main view
function Mods.Quit()
	if (Mods.MainElement ~= nil) then
		Mods.MainElement:kill()
		Mods.MainElement = nil
	end
end

---Internal helper class for **Mods manager**
---@class ModsInternal
---@field CurrentFolder ModFolder Last opened mod folder
local ModsInternal = {}

---Generic function to execute on mod button click
---@param file string
function ModsInternal.ButtonClick(file)
	local clock = os.clock_real()
	if (not Mods.LastMenu) then
		---@type ModsListEntryInfo
		Mods.LastMenu = { time = clock, mod = file }
	elseif (Mods.LastMenu.time + 0.5 > clock and Mods.LastMenu.mod == file) then
		if (file:find("^/")) then
			file = file:sub(2)
		end
		runCmd("loadmod " .. file)
		if (Mods.StartNewGame and UIElement.WorldState.game_type == 1) then
			runCmd("reset")
		end
	else
		---@type ModsListEntryInfo
		Mods.LastMenu = { time = clock, mod = file }
	end
end

---Method to get and cache all mods within a directory
---@param path ?string
---@return ModFolder
function Mods.GetModFiles(path)
	local path = path or "data/mod"
	---@type ModFolder
	local data = { name = path, mods = {}, folders = {}, contents = {} }
	local modFiles = get_files(path, "")
	if (_G.PLATFORM == "IPHONEOS") then
		table.sort(modFiles)
	end
	for _, v in pairs(modFiles) do
		if (v:match(".tbm$")) then
			table.insert(data.mods, v)
		elseif (not v:find("^%.+[%s%S]*$") and v ~= "system" and v ~= "modmaker_draft" and not v:find("%.%a+$")) then
			table.insert(data.folders, v)
			data.contents[#data.folders] = Mods.GetModFiles(path .. "/" .. v)
			data.contents[#data.folders].parent = data
		end
	end
	return data
end

---Refreshes mod cache and returns current folder with the updated data
---@return ModFolder
function ModsInternal.RefreshCurrentFolder()
	local modsData = Mods.GetModFiles()
	if (ModsInternal.CurrentFolder == nil) then
		return modsData
	end

	local checkCurrentFolder
	checkCurrentFolder = function(folder)
		if (folder.name == ModsInternal.CurrentFolder.name and (folder.parent == ModsInternal.CurrentFolder.parent or (folder.parent ~= nil and ModsInternal.CurrentFolder.parent ~= nil and folder.parent.name == ModsInternal.CurrentFolder.parent.name))) then
			return folder
		end
		for _, v in pairs(folder.contents) do
			local result = checkCurrentFolder(v)
			if (result ~= nil) then
				return result
			end
		end
		return nil
	end

	ModsInternal.CurrentFolder = checkCurrentFolder(modsData) or modsData
	return ModsInternal.CurrentFolder
end

---Helper function to nicely format folder names
---@param text string
---@return string
function ModsInternal.CleanFolderName(text)
	pcall(function()
		text = utf8.upper(utf8.sub(text, 1, 1)) .. utf8.sub(text, 2)
		text = utf8.gsub(text, "([^_])(%u%l)", "%1 %2")
		text = utf8.gsub(text, "_", " & ")
	end)
	return text
end

---Generic function to spawn a list button
---@param listingHolder UIElement
---@param listElements UIElement[]
---@param elementHeight number
---@param icon string|nil
---@param text string
---@param pressFunc function
---@param iconScale ?UIElementSize
---@param leftOffset ?number
---@return UIElement
function Mods.SpawnListButton(listingHolder, listElements, elementHeight, icon, text, pressFunc, iconScale, leftOffset)
	local buttonHolder = listingHolder:addChild({
		pos = { 0, #listElements * elementHeight },
		size = { listingHolder.size.w, elementHeight }
	})
	table.insert(listElements, buttonHolder)
	local button = buttonHolder:addChild({
		pos = { 5, 2 },
		size = { buttonHolder.size.w - 5, buttonHolder.size.h - 4 },
		interactive = true,
		clickThrough = true,
		hoverThrough = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 3
	})

	local shiftModifier = leftOffset or 0
	if (icon ~= nil) then
		local iconScale = iconScale and { iconScale.w or button.size.h, iconScale.h or button.size.h } or { button.size.h, button.size.h }
		local buttonIcon = button:addChild({
			pos = { shiftModifier + 5, (button.size.h - iconScale[2]) / 2 },
			size = iconScale,
			bgImage = icon
		})
		shiftModifier = buttonIcon.size.w + buttonIcon.shift.x
		if (icon == "../textures/menu/general/folder.tga") then
			text = ModsInternal.CleanFolderName(text)
		end
	end
	local buttonText = button:addChild({
		pos = { shiftModifier + 5, 0 },
		size = { button.size.w - shiftModifier - 10, button.size.h }
	})
	buttonText:addAdaptedText(false, text, nil, nil, 4, LEFTMID, 0.8, 0.8)
	button:addMouseUpHandler(pressFunc)

	return buttonHolder
end

---Function to spawn the main list with mods
---@param listingHolder UIElement
---@param toReload UIElement
---@param topBar UIElement
---@param elementHeight number
---@param data ?ModFolder
---@param search ?UIElement
---@param modLoadCustomFunc ?function
---@param scrollOverride ?boolean
function Mods.SpawnMainList(listingHolder, toReload, topBar, elementHeight, data, search, modLoadCustomFunc, scrollOverride)
	if (data == nil) then
		data = ModsInternal.CurrentFolder
		if (data == nil) then
			data = ModsInternal.RefreshCurrentFolder()
		end
	end
	if (listingHolder.scrollBar) then
		listingHolder.scrollBar:kill()
	end
	listingHolder:kill(true)
	listingHolder:moveTo(nil, 0)
	if (topBar.title) then
		topBar.title:kill()
		topBar.title = nil
	end

	local extraShift = { x = 0, y = 0 }
	topBar.helpPopup = topBar.helpPopup
	if (topBar.helpPopup ~= nil) then
		extraShift.x = topBar.helpPopup.size.w + topBar.helpPopup.shift.x
		extraShift.y = topBar.helpPopup.shift.y
	else
		extraShift.y = -elementHeight
	end
	local modsFolderName = topBar:addChild({
		pos = { extraShift.x + 5, extraShift.y },
		size = { topBar.size.w - 15 - extraShift.x, elementHeight }
	})
	topBar.title = modsFolderName

	local folderDisplayName = string.gsub(data.name, "^data/mod", "Mods")
	folderDisplayName = utf8.gsub(folderDisplayName, "^.*/([^/]+)", "%1")
	folderDisplayName = ModsInternal.CleanFolderName(folderDisplayName)
	modsFolderName:addAdaptedText(true, folderDisplayName, nil, nil, topBar.helpPopup and FONTS.BIG or FONTS.MEDIUM, LEFTMID, topBar.helpPopup and 0.6 or 1, nil, 0.5)

	local searchString = search and utf8.gsub(utf8.lower(search.textfieldstr[1]), "([^%w])", "%%%1") or ""
	local listElements = {}
	ModsInternal.CurrentFolder = data

	local modpath = utf8.gsub(data.name, "^data/mod/?", "")
	if (data.name ~= "data/mod" or searchString ~= "") then
		Mods.SpawnListButton(listingHolder, listElements, elementHeight, "../textures/menu/general/back.tga", TB_MENU_LOCALIZED.NAVBUTTONBACK, function()
			Mods.ListShift[1] = 0
			if (search ~= nil) then
				search:clearTextfield()
			end
			Mods.SpawnMainList(listingHolder, toReload, topBar, elementHeight, data.parent and data.parent or data, search, modLoadCustomFunc, scrollOverride)
		end, { w = elementHeight * 0.5, h = elementHeight * 0.5 })
	end

	local modmakerId = 0
	local spawnFolders

	---@param data ModFolder
	---@param level integer
	---@return boolean
	spawnFolders = function(data, level)
		local foundMatch = false
		for i, folder in pairs(data.folders) do
			if (folder == "modmaker") then
				modmakerId = i
			else
				local element = Mods.SpawnListButton(listingHolder, listElements, elementHeight, "../textures/menu/general/folder.tga", folder, function()
					Mods.ListShift[1] = 0
					if (search ~= nil) then
						search:clearTextfield()
					end
					Mods.SpawnMainList(listingHolder, toReload, topBar, elementHeight, data.contents[i], search, modLoadCustomFunc, scrollOverride)
				end, { w = elementHeight * 0.5, h = elementHeight * 0.5 }, level * 20)
				if (searchString ~= "") then
					local inserted = spawnFolders(data.contents[i], level + 1)
					if (not inserted) then
						table.remove(listElements)
					end
					for _, file in pairs(data.contents[i].mods) do
						pcall(function()
							local filename = file:gsub("%.tbm$", "")
							if (utf8.find(utf8.lower(filename), searchString)) then
								if (not inserted) then
									inserted = true
									table.insert(listElements, element)
								end
								Mods.SpawnListButton(listingHolder, listElements, elementHeight, "../textures/menu/general/buttons/arrowright.tga", filename, function()
									if (modLoadCustomFunc) then
										modLoadCustomFunc(file)
									else
										ModsInternal.ButtonClick(modpath .. "/" .. file)
									end
								end, { w = elementHeight / 2 }, level * 20)
							end
						end)
					end
					if (not inserted) then
						element:kill()
					else
						foundMatch = true
					end
				end
			end
		end
		return foundMatch
	end
	spawnFolders(data, 0)
	if (modmakerId > 0) then
		local element = Mods.SpawnListButton(listingHolder, listElements, elementHeight, "../textures/menu/general/folder.tga", data.folders[modmakerId], function()
			Mods.ListShift[1] = 0
			if (search ~= nil) then
				search:clearTextfield()
			end
			Mods.SpawnMainList(listingHolder, toReload, topBar, elementHeight, data.contents[modmakerId], search, modLoadCustomFunc, scrollOverride)
		end, { w = elementHeight * 0.5, h = elementHeight * 0.5 })
		table.remove(listElements)
		local inserted = false
		if (searchString ~= "") then
			for _, file in pairs(data.contents[modmakerId].mods) do
				if (file:lower():find(searchString)) then
					if (not inserted) then
						inserted = true
						table.insert(listElements, element)
					end
					local filename = file:gsub("%.tbm$", "")
					Mods.SpawnListButton(listingHolder, listElements, elementHeight, "../textures/menu/general/buttons/arrowright.tga", filename, function()
						if (modLoadCustomFunc) then
							modLoadCustomFunc(file)
						else
							ModsInternal.ButtonClick(modpath .. "/" .. file)
						end
					end, { w = elementHeight / 2 })
				end
			end
			if (not inserted) then
				element:kill()
			end
		else
			table.insert(listElements, element)
		end
	end
	for _, file in pairs(data.mods) do
		local filename = file:gsub("%.tbm$", "")
		pcall(function()
			if (utf8.find(utf8.lower(filename), searchString)) then
				Mods.SpawnListButton(listingHolder, listElements, elementHeight, nil, filename, function()
					if (modLoadCustomFunc) then
						modLoadCustomFunc(file)
					else
						ModsInternal.ButtonClick(modpath .. "/" .. file)
					end
				end)
			end
		end)
	end
	if (#listElements == 0) then
		local element = UIElement:new({
			parent = listingHolder,
			pos = { 0, 0 },
			size = { listingHolder.size.w, listingHolder.size.h },
		})
		table.insert(listElements, element)
		element:addAdaptedText(false, TB_MENU_LOCALIZED.NOFILESFOUND .. " :(")
	end
	for _, v in pairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar
	scrollBar:makeScrollBar(listingHolder, listElements, toReload, Mods.ListShift, nil, scrollOverride)
end

---Creates mod browser window
function Mods.showMain()
	-- Safety check just in case this wasn't called from mods.lua so that we don't get stuck with two browsers on screen
	if (Mods.MainElement ~= nil) then
		Mods.MainElement:kill()
		Mods.MainElement = nil
	end

	local mainViewBackground = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { Mods.DisplayPos.x, Mods.DisplayPos.y },
		size = { math.min(WIN_W / 2, 400), math.clamp(650, WIN_H / 2, WIN_H - 100) },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	Mods.MainElement = mainViewBackground
	Mods.DisplayPos = mainViewBackground.pos

	local mainView = mainViewBackground:addChild({
		shift = { 2, 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	}, true)

	local elementHeight = 36
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(mainView, 75, 70, 20, mainView.bgColor)

	topBar.shapeType = mainView.shapeType
	topBar:setRounded(mainView.rounded)
	botBar.shapeType = mainView.shapeType
	botBar:setRounded(mainView.rounded)

	local mainMoverHolder = topBar:addChild({
		size = { topBar.size.w, 30 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	}, true)
	local mainMover = mainMoverHolder:addChild({
		interactive = true,
		bgColor = UICOLORWHITE,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
	})
	mainMover:addCustomDisplay(true, function()
			set_color(unpack(mainMover:getButtonColor()))
			local posX = mainMover.pos.x + mainMover.size.w / 2 - 15
			draw_quad(posX, mainMover.pos.y + 10, 30, 2)
			draw_quad(posX, mainMover.pos.y + 18, 30, 2)
		end)
	mainMover:addMouseHandlers(function(s, x, y)
				disable_mouse_camera_movement()
				mainMover.pressedPos.x = x - mainMover.pos.x
				mainMover.pressedPos.y = y - mainMover.pos.y
			end, enable_mouse_camera_movement, function(x, y)
			if (mainMover.hoverState == BTN_DN) then
				local x = x - mainMover.pressedPos.x
				local y = y - mainMover.pressedPos.y
					x = x < 0 and 0 or (x + Mods.MainElement.size.w > WIN_W and WIN_W - Mods.MainElement.size.w or x)
				y = y < 0 and 0 or (y + Mods.MainElement.size.h > WIN_H and WIN_H - Mods.MainElement.size.h or y)
				Mods.MainElement:moveTo(x, y)
			end
		end, nil, enable_mouse_camera_movement)

	local helpPopupSize = topBar.size.h - mainMoverHolder.size.h - 10
	local helpPopupHolder = topBar:addChild({
		pos = { 5, mainMoverHolder.size.h + 5 },
		size = { helpPopupSize, helpPopupSize },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = helpPopupSize
	})
	topBar.helpPopup = helpPopupHolder
	local helpPopup = TBMenu:displayHelpPopup(helpPopupHolder, "Double click on a mod to load it")
	if (helpPopup ~= nil) then
		helpPopup:moveTo(helpPopupSize + 5, (helpPopupSize - helpPopup.size.h) / 2, true)
	end

	local modNewGameToggleView = botBar:addChild({
		pos = { 0, -35 },
		size = { mainView.size.w, 30 }
	}, true)
	local modNewGameToggleBG = modNewGameToggleView:addChild({
		pos = { 5, 2 },
		size = { modNewGameToggleView.size.h - 4, modNewGameToggleView.size.h - 4 },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	}, true)
	local modNewGameToggle = modNewGameToggleBG:addChild({
		shift = { 1, 1 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
	}, true)
	local modNewGameToggleIcon = modNewGameToggle:addChild({
		bgImage = "../textures/menu/general/buttons/checkmark.tga"
	})
	if (not Mods.StartNewGame) then
		modNewGameToggleIcon:hide(true)
	end
	modNewGameToggle:addMouseUpHandler(function()
		Mods.StartNewGame = not Mods.StartNewGame
			if (not Mods.StartNewGame) then
				modNewGameToggleIcon:hide(true)
			else
				modNewGameToggleIcon:show(true)
			end
		end)
	local modNewGameText = modNewGameToggleView:addChild({
		pos = { modNewGameToggleBG.shift.x * 2 + modNewGameToggleBG.size.w, 0 },
		size = { modNewGameToggleView.size.w - modNewGameToggleBG.shift.x * 3 - modNewGameToggleBG.size.w, modNewGameToggleView.size.h }
	})
	modNewGameText:addAdaptedText(true, TB_MENU_LOCALIZED.MODSRESTARTGAME, nil, nil, 4, LEFTMID, 0.7)

	local search = TBMenu:spawnTextField2(botBar, {
		x = 5, y = 5,
		w = botBar.size.w - 10, h = botBar.size.h - 40
	}, nil, TB_MENU_LOCALIZED.SEARCHNOTE, {
		fontId = 4,
		textScale = 0.65,
		textAlign = LEFTMID,
		keepFocusOnHide = true,
		darkerMode = true,
		returnKeyType = KEYBOARD_RETURN.DONE
	})
	local lastText = search.textfieldstr[1]
	search:addInputCallback(function()
			if (lastText ~= search.textfieldstr[1]) then
				Mods.ListShift[1] = 0
				Mods.SpawnMainList(listingHolder, toReload, topBar, elementHeight, ModsInternal.CurrentFolder, search)
				lastText = search.textfieldstr[1]
			end
		end)
	if (is_mobile()) then
		search:addEnterAction(function()
				search.keyboard = false
				search:disableMenuKeyboard()
			end)
	end

	ModsInternal.RefreshCurrentFolder()
	Mods.SpawnMainList(listingHolder, toReload, topBar, elementHeight, ModsInternal.CurrentFolder, search)

	local quitButton = mainMoverHolder:addChild({
		pos = { -mainMoverHolder.size.h, 0 },
		size = { mainMoverHolder.size.h, mainMoverHolder.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true
	}, true)
	quitButton:addChild({
		shift = { 2, 2 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})
	quitButton:addMouseHandlers(nil, function()
			Mods.MainElement:kill()
			Mods.MainElement = nil
		end)
end
