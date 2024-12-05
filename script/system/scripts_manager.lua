if (Scripts == nil) then
	---**Scripts manager class**
	---
	---**Version 5.73**
	---* Remember last scroll position
	---* Double click to load script from the list
	---
	---**Version 5.70**
	---* Reworked backend to match modern manager classes
	---* Reworked visuals to match modern design
	---* Script autoloading support (via `profile.tbs` management)
	---@class Scripts
	---@field MainView UIElement
	---@field InfoView UIElement
	---@field AutoStart string[] List of scripts that will be loaded on game startup
	---@field AutoStartArgs string[] List of launch arguments for autostart scripts
	---@field AutoStartMisc string[] Lits of other commands that will be executed on startup
	---@field ListShift number[]
	Scripts = {
		AutoStart = {},
		AutoStartArgs = {},
		AutoStartMisc = {},
		ListShift = { 0 },
		ver = 5.73
	}
	Scripts.__index = Scripts
end

---@class ScriptsInternal
---Internal utility class for **Scripts** manager
local ScriptsInternal = {}
ScriptsInternal.__index = ScriptsInternal

---Exits Scripts menu and opens last main menu screen
function Scripts.Quit()
	Scripts.ListShift[1] = 0
	Scripts.LastDisplayedScript = nil
	Scripts.LastSelectedButton = nil

	TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
	TBMenu:clearNavSection()
	TBMenu:showNavigationBar()
	TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
end

---Returns a list of navigation buttons used by Scripts menu
---@return MenuNavButton[]
function Scripts:getNavigationButtons()
	return {
			{
			text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
			action = Scripts.Quit
		}
	}
end

---Checks whether specified folder within `data/script` is used by system classes
---@param folder string
---@return boolean
function ScriptsInternal.IsDefaultDirectory(folder)
	local defaultFolders = {
		"system", "toriui", "tutorial", "torishop", "events"
	}
	for _, v in ipairs(defaultFolders) do
		if (v == folder) then
			return true
		end
	end
	return false
end

---@class ScriptDirectory
---@field name string
---@field path string
---@field files string[]
---@field contents ScriptDirectory[]
---@field parent ScriptDirectory|nil

---Returns script contents by the specified path
---@param path string? Defaults to `data/script`
---@param name string? Directory name
---@return ScriptDirectory
function Scripts:getScriptFiles(path, name)
	path = path or "data/script"
	name = name or utf8.gsub(path, "^data/script[/]?", "")

	local data = { name = name, path = path, files = {}, folders = {}, contents = {} }
	for _, v in ipairs(get_files(path, "")) do
		if (utf8.match(v, ".lua$")) then
			table.insert(data.files, v)
		end
	end
	for _, v in ipairs(get_folders(path)) do
		if (path ~= "data/script" or not ScriptsInternal.IsDefaultDirectory(v)) then
			table.insert(data.contents, self:getScriptFiles(path .. "/" .. v, v))
			data.contents[#data.contents].parent = data
		end
	end
	return data
end

---Fetches list of scripts and commands to execute on game startup
function Scripts:getAutostartScripts()
	local autostartFile = Files.Open("../profile.tbs", FILES_MODE_READONLY)
	local autostartLines = autostartFile:readAll()
	autostartFile:close()

	self.AutoStart = {}
	self.AutoStartArgs = {}
	self.AutoStartMisc = {}
	for _, v in ipairs(autostartLines) do
		if (utf8.find(v, "^ls ")) then
			local loadscriptLine = utf8.gsub(v, "^ls ", "")
			local args = { utf8.match(loadscriptLine, ("([^ ]*) ?"):rep(2)) }
			table.insert(self.AutoStart, args[1])
			self.AutoStartArgs[#self.AutoStart] = args[2]
		else
			table.insert(self.AutoStartMisc, v)
		end
	end
end

---Trims script filenames so we can get a local path that can be used by `/ls` command
---@param file string
---@return string
function ScriptsInternal.TrimFilename(file)
	file = utf8.gsub(file, "^data/script/", "")
	file = utf8.gsub(file, "^/", "")
	return file
end

---Checks whether the specified script is going to be run on startup
---@param file string Path to script file
---@return boolean
---@return integer? index
function Scripts:isAutostartScript(file)
	file = ScriptsInternal.TrimFilename(file)
	for i, v in ipairs(self.AutoStart) do
		if (v == file) then
			return true, i
		end
	end
	return false
end

---Updates `profile.tbs` file with current autostart settings
---@return boolean
function ScriptsInternal.UpdateProfile()
	local profileFile = Files.Open("../profile.tbs", FILES_MODE_WRITE)
	if (profileFile.data == nil) then
		return false
	end

	for _, v in ipairs(Scripts.AutoStartMisc) do
		profileFile:writeLine(v)
	end
	for i, v in ipairs(Scripts.AutoStart) do
		profileFile:writeLine("ls " .. v .. " " .. Scripts.AutoStartArgs[i])
	end
	profileFile:close()
	return true
end

---Adds script to autostart list and refreshes profile file
---@param file string Path to script file
---@param launchArgs string
function Scripts:addAutostartScript(file, launchArgs)
	file = ScriptsInternal.TrimFilename(file)
	if (self:isAutostartScript(file)) then
		return
	end
	echo("Adding autostart script " .. file .. " with launch args \"" .. launchArgs .. "\"")
	table.insert(self.AutoStart, file)
	self.AutoStartArgs[#self.AutoStart] = launchArgs
	ScriptsInternal.UpdateProfile()
end

---Removes script from autostart list and refreshes profile file
---@param file string Path to script file
function Scripts:removeAutostartScript(file)
	local autostart, idx = self:isAutostartScript(file)
	if (autostart) then
		table.remove(self.AutoStart, idx)
		table.remove(self.AutoStartArgs, idx)
	end
	ScriptsInternal.UpdateProfile()
end

---Displays a list of scripts and subfolders in a specified UIElement view
---@param files ScriptDirectory
function Scripts:showScriptsList(files)
	self.MainView:kill(true)
	local elementHeight = math.clamp(math.ceil(WIN_H / 20), 40, 55)
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(self.MainView, 60, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)
	TBMenu:addBottomBloodSmudge(botBar, 1)

	local windowTitle = topBar:addChild({
		shift = { 10, 5 }
	})
	local shortPath = utf8.gsub(files.path, "^data/script[/]?", "")
	windowTitle:addAdaptedText(true, TB_MENU_LOCALIZED.LUASCRIPTSNAME .. (shortPath ~= "" and ": " .. shortPath or ""), nil, nil, FONTS.BIG, LEFTMID, 0.65)

	local listElements = {}
	if (shortPath ~= "") then
		local backButtonHolder = listingHolder:addChild({
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, backButtonHolder)
		local backButton = backButtonHolder:addChild({
			pos = { 10, 2 },
			size = { backButtonHolder.size.w - 10, backButtonHolder.size.h - 4 },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		backButton:addChild({
			pos = { 5, 0 },
			size = { elementHeight, elementHeight },
			bgImage = "../textures/menu/general/back.tga"
		})
		backButton:addChild({
			pos = { elementHeight, 0 },
			size = { backButton.size.w - elementHeight, elementHeight }
		}):addAdaptedText(false, TB_MENU_LOCALIZED.NAVBUTTONBACK, 10, nil, 4, LEFTMID, 0.8, 0.8)
		backButton:addMouseUpHandler(function()
				self.ListShift[1] = 0
				self.LastDisplayedScript = nil
				self.LastSelectedButton = nil
				self:showScriptsList(files.parent)
			end)
	end
	for i, folder in ipairs(files.contents) do
		local element = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, element)
		local button = element:addChild({
			pos = { 10, 2 },
			size = { element.size.w - 10, element.size.h - 4 },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		button:addAdaptedText(false, folder.name, elementHeight / 2 + 20, nil, 4, LEFTMID, 0.8, 0.8)
		button:addMouseUpHandler(function()
				self.ListShift[1] = 0
				self.LastDisplayedScript = nil
				self.LastSelectedButton = nil
				self:showScriptsList(files.contents[i])
			end)
		local buttonIcon = button:addChild({
			parent = element,
			pos = { 10, elementHeight / 4 },
			size = { elementHeight / 2, elementHeight / 2 },
			bgImage = "../textures/menu/general/folder.tga"
		})
	end
	local infoDisplayed = false
	for _, file in ipairs(files.files) do
		local element = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, element)
		local button = element:addChild({
			pos = { 10, 2 },
			size = { element.size.w - 10, element.size.h - 4 },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = table.clone(TB_MENU_DEFAULT_DARKER_COLOR),
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		local buttonText
		local toggleAutostartPill = function(state, noReload)
			button:kill(true)
			if (state) then
				local buttonAutostart = button:addChild({
					shift = { 10, 5 },
					bgColor = TB_MENU_DEFAULT_BLUE,
					uiColor = UICOLORBLACK,
					rounded = 50
				}, true)
				buttonAutostart:addAdaptedText(TB_MENU_LOCALIZED.LUAAUTOSTARTENABLED, nil, nil, FONTS.LMEDIUM, CENTERMID, 0.65)
				local buttonWidth = get_string_length(buttonAutostart.dispstr[1], buttonAutostart.textFont) * buttonAutostart.textScale + 26
				buttonAutostart.size.w = buttonWidth
				buttonAutostart:moveTo(-buttonAutostart.size.w - 10)

				buttonText = button:addChild({
					pos = { 10, 0 },
					size = { button.size.w - buttonAutostart.size.w - 30, button.size.h }
				})
			else
				buttonText = button:addChild({
					shift = { 10, 0 }
				})
			end
			if (not button:isDisplayed()) then
				button:show()
				button:hide()
			end
			buttonText:addAdaptedText(file, nil, nil, 4, LEFTMID, 0.8, 0.8)
			if (not noReload) then
				toReload:reload()
			end
		end
		local path = shortPath .. "/" .. file
		toggleAutostartPill(self:isAutostartScript(path), true)
		button.lastPress = 0
		button:addMouseUpHandler(function()
				if (UIElement.clock - button.lastPress < 0.5) then
					local _, idx = self:isAutostartScript(path)
					runCmd("ls " .. path .. " " .. (idx ~= nil and self.AutoStartArgs[idx] or ""))
					close_menu()
					return
				end
				button.lastPress = UIElement.clock
				self:showScriptInfo(path, toggleAutostartPill)
				self.LastDisplayedScript = path
				if (self.LastSelectedButton ~= nil and not self.LastSelectedButton.destroyed) then
					self.LastSelectedButton.bgColor = table.clone(TB_MENU_DEFAULT_DARKER_COLOR)
				end
				self.LastSelectedButton = button
				self.LastSelectedButton.bgColor = table.clone(TB_MENU_DEFAULT_LIGHTER_COLOR)
			end)
		if (self.LastDisplayedScript == path) then
			self:showScriptInfo(path, toggleAutostartPill)
			self.LastSelectedButton = button
			self.LastSelectedButton.bgColor = table.clone(TB_MENU_DEFAULT_LIGHTER_COLOR)
			infoDisplayed = true
		end
	end
	for _, v in ipairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar
	scrollBar:makeScrollBar(listingHolder, listElements, toReload, self.ListShift)

	if (not infoDisplayed) then
		self:showScriptInfo()
	end
end

--[[function Scripts:showSource(info)
	local overlay = TBMenu:spawnWindowOverlay()
	local scriptData = UIElement:new({
		parent = overlay,
		pos = { WIN_W / 10, WIN_H / 8 },
		size = { WIN_W * 0.8, WIN_H / 8 * 6 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	overlay:addMouseHandlers(nil, function()
			overlay:kill()
		end)
	local elementHeight = 16
	local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(scriptData, 50, elementHeight, 30, TB_MENU_DEFAULT_BG_COLOR)
	local quitButton = UIElement:new({
		parent = topBar,
		pos = { -45, 5 },
		size = { 40, 40 },
		rounded = 3,
		shapeType = ROUNDED,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = { 1, 0, 0, 0.4 }
	})
	local quitIcon = UIElement:new({
		parent = quitButton,
		pos = { 5, 5 },
		size = { quitButton.size.w - 10, quitButton.size.h - 10 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})
	quitButton:addMouseHandlers(nil, function()
			overlay:kill()
		end)
	local sourceTitle = UIElement:new({
		parent = topBar,
		pos = { 10, 0 },
		size = { topBar.size.w - 60, topBar.size.h }
	})
	sourceTitle:addAdaptedText(true, TB_MENU_LOCALIZED.LUAVIEWINGSORCE, nil, nil, FONTS.BIG, nil, 0.6)
	local listElements = {}
	for i, ln in pairs(info) do
		local textString = textAdapt(ln, 1, 1, listingHolder.size.w - 10, nil, true)
		for i = 1, #textString do
			local infoRow = UIElement:new({
				parent = listingHolder,
				pos = { 5, #listElements * elementHeight },
				size = { listingHolder.size.w - 10, elementHeight }
			})
			local string = textString[i]
			infoRow:addCustomDisplay(true, function()
					infoRow:uiText(string, nil, nil, 1, LEFT, 0.9)
				end)
			table.insert(listElements, infoRow)
		end
	end
	for i,v in pairs(listElements) do
		v:hide()
	end
	local scriptDataScroll = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	scriptDataScroll:makeScrollBar(listingHolder, listElements, toReload)
end]]

---Displays script information in the right panel
---@param path string?
---@param autostartUpdateFunc function?
function Scripts:showScriptInfo(path, autostartUpdateFunc)
	self.InfoView:kill(true)
	TBMenu:addBottomBloodSmudge(self.InfoView, 2)

	local warningViewHeight = math.min(self.InfoView.size.h / 3, 300)
	local warningView = self.InfoView:addChild({
		pos = { 10, self.InfoView.size.h - warningViewHeight - 16 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		size = { self.InfoView.size.w - 20, warningViewHeight },
		shapeType = ROUNDED,
		rounded = 4
	})
	local warningViewMessage = warningView:addChild({
		pos = { 10, 5 },
		size = { warningView.size.w - 20, warningView.size.h - 70 }
	})
	warningViewMessage:addAdaptedText(true, TB_MENU_LOCALIZED.LUASCRIPTSTHIRDPARTYWARNING1 .. "\n\n" .. TB_MENU_LOCALIZED.LUASCRIPTSTHIRDPARTYWARNING2 .. "\n\n" .. TB_MENU_LOCALIZED.LUASCRIPTSTHIRDPARTYWARNING3, nil, nil, FONTS.LMEDIUM, CENTERMID)

	local luaBoardButton = warningView:addChild({
		pos = { 10, -65 },
		size = { warningView.size.w - 20, 55 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
	}, true)
	TBMenu:showTextExternal(luaBoardButton, TB_MENU_LOCALIZED.LUASCRIPTSFORUMBOARD)
	luaBoardButton:addMouseUpHandler(function()
			open_url("https://forum.toribash.com/forumdisplay.php?f=65")
		end)

	if (path == nil) then
		return
	end

	local scriptName = self.InfoView:addChild({
		pos = { 10, 5 },
		size = { self.InfoView.size.w - 20, 40 }
	})
	scriptName:addAdaptedText(true, path:gsub("^.*/", ""))


	---Some security measures, we read the file and check if it loads other stuff
	local alertLevels = {
		fileAccess = false,
		otherScripts = false
	}
	local scriptFile = Files.Open(path)
	local scriptLines = scriptFile:readAll()
	scriptFile:close()

	for _, info in ipairs(scriptLines) do
		if (not alertLevels.fileAccess) then
			if (string.find(info, "io.[p]?open") or
				string.find(info, "Files[%.:][oO]pen") or
				string.find(info, "Files:new") or
				string.find(info, "file_open%(")) then
				alertLevels.fileAccess = true
			end
		end
		if (not alertLevels.otherScripts) then
			local idx = string.find(info, "dofile%(") or string.find(info, "require%(") or string.find(info, "loadfile%(") or string.find(info, "loadstring%(")
			if (idx) then
				---Let's check what's being loaded, it can be system classes which we don't need to worry about
				local startidx, endidx = string.find(info, ".*%)?", idx)
				if (startidx ~= nil) then
					---Is it possible that we get a nil here but it's actually a valid code that would load something?
					local loadpath = string.sub(info, startidx + 2, endidx - 2)
					if (string.find(loadpath, "^system[/%.]") == nil and string.find(loadpath, "^toriui[/%.]") == nil) then
						alertLevels.otherScripts = true
					end
				end
			end
		end
	end

	---Show warning pills
	local shiftY = scriptName.shift.y * 2 + scriptName.size.h
	for alert, v in pairs(alertLevels) do
		if (v == true) then
			local alertPill = self.InfoView:addChild({
				pos = { 10, shiftY },
				size = { self.InfoView.size.w - 20, 30 },
				interactive = true,
				bgColor = UICOLORRED,
				hoverColor = { 1, 0.125, 0.125, 1 },
				shapeType = ROUNDED,
				rounded = 15
			})
			shiftY = shiftY + alertPill.size.h + 5
			local localizedString = "LUA" .. string.upper(alert) .. "WARNING"
			alertPill:addAdaptedText(TB_MENU_LOCALIZED[localizedString], nil, nil, FONTS.LMEDIUM, CENTERMID, 0.8)
			local alertWidth = get_string_length(alertPill.dispstr[1], alertPill.textFont) * alertPill.textScale + 26
			alertPill.size.w = alertWidth
			alertPill:moveTo((self.InfoView.size.w - alertWidth) / 2)

			local popup = TBMenu:displayPopup(alertPill, TB_MENU_LOCALIZED[localizedString .. "HINT"])
			if (popup ~= nil) then
				popup:moveTo((-alertPill.size.w - popup.size.w) / 2, alertPill.size.h + 5)
			end
		end
	end

	local loadScriptButton = self.InfoView:addChild({
		pos = { warningView.shift.x, warningView.shift.y - 65 },
		size = { warningView.size.w, 55 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	loadScriptButton:addAdaptedText(false, TB_MENU_LOCALIZED.LUALOADSCRIPT)
	local autostartHolder = self.InfoView:addChild({
		pos = { loadScriptButton.shift.x, loadScriptButton.shift.y - 120 },
		size = { loadScriptButton.size.w, 110 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local autostartLabel = autostartHolder:addChild({
		pos = { 10, 10 },
		size = { autostartHolder.size.w - 20, 35 }
	})
	autostartLabel:addAdaptedText(TB_MENU_LOCALIZED.LUAAUTOSTARTLABEL)
	local autostartDropdownHolder = autostartHolder:addChild({
		pos = { autostartLabel.shift.x, autostartLabel.size.h + autostartLabel.shift.y * 2 },
		size = { autostartLabel.size.w, autostartHolder.size.h - autostartLabel.size.h - autostartLabel.shift.y * 3 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	}, true)

	local autostart, idx = self:isAutostartScript(path)
	local launchArgInputHolder = self.InfoView:addChild({
		pos = { autostartHolder.shift.x, autostartHolder.shift.y - 40 },
		size = { autostartHolder.size.w, 30 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	}, true)
	local launchArgInput = TBMenu:spawnTextField2(launchArgInputHolder, nil, idx ~= nil and self.AutoStartArgs[idx] or "", TB_MENU_LOCALIZED.LUAAUTOSTARARGSHINT, { textAlign = LEFTMID, textScale = 0.7 })

	loadScriptButton:addMouseUpHandler(function()
			runCmd("ls " .. path .. " " .. launchArgInput.textfieldstr[1])
			close_menu()
		end)

	---@type DropdownElement[]
	local autostartDropdownElements = {
		{
			text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
			action = function()
				Scripts:removeAutostartScript(path)
				if (autostartUpdateFunc) then
					autostartUpdateFunc(false)
				end
			end
		},
		{
			text = TB_MENU_LOCALIZED.SETTINGSENABLED,
			action = function()
				Scripts:addAutostartScript(path, launchArgInput.textfieldstr[1])
				if (autostartUpdateFunc) then
					autostartUpdateFunc(true)
				end
			end,
			selected = autostart
		}
	}
	TBMenu:spawnDropdown(autostartDropdownHolder, autostartDropdownElements, autostartDropdownHolder.size.h, nil, nil, {
		fontid = FONTS.LMEDIUM, alignment = CENTERMID, scale = 0.7, uppercase = true
	}, {
		fontid = FONTS.LMEDIUM, alignment = CENTERMID, scale = 0.7, uppercase = true
	})
end

---Displays Scripts' menu main screen
function Scripts:showMain()
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 11
	usage_event("scripts")
	TBMenu.CurrentSection:kill(true)

	local infoViewWidth = math.min(TBMenu.CurrentSection.size.w * 0.4, 550)
	self.InfoView = TBMenu.CurrentSection:addChild({
		pos = { TBMenu.CurrentSection.size.w - infoViewWidth - 5, 0 },
		size = { infoViewWidth, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	self.MainView = TBMenu.CurrentSection:addChild({
		pos = { 5, 0 },
		size = { TBMenu.CurrentSection.size.w - infoViewWidth - 20, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	self:getAutostartScripts()
	self:showScriptsList(self:getScriptFiles())
end
