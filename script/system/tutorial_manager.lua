-- Tutorials manager
require("system.iofiles")
require("system.movememory_manager")
require("system.friends_manager")
require("system.tooltip_manager")

if (Tutorials == nil) then
	---**Toribash Tutorials class**
	---
	---**Version 5.60**
	---* Updates to work with new Tooltip backend
	---* New `TutorialsInternal.LoadFile()` method to make sure we can load files on mobile platforms
	---@class Tutorials
	---@field Globalid integer Tutorials UIElement globalid
	---@field ReplaySpeed number Current replay playback speed
	---@field ReplayCache boolean Whether replay cache is enabled for current replay
	---@field WorldState WorldState Cached world state, updated every frame
	---@field CurrentTutorial number|string Current tutorial id or name
	---@field CurrentStep TutorialStep Current tutorial step
	---@field MainView UIElement Main UIElement holder for Tutorials GUI
	---@field QuitOverlay UIElement Overlay UIElement displayed on ESC key press
	---@field StepOverlay UIElement Intro / outro overlay UIElement
	---@field ContinueButton TutorialContinueButton `Continue` button UIElement
	---@field TaskView UIElement Task window UIElement
	---@field TaskViewHolder TutorialsTaskView Task window holder UIElement
	---@field HintView UIElement Hint window UIElement
	---@field HintMessageView UIElement Hint window message holder UIElement
	---@field MessageViewHolder UIElement Player message window holder UIElement
	---@field MessageView UIElement Player message window UIElement
	---@field MessageViewNameBG UIElement Player message name background UIElement
	---@field MessageViewName UIElement Player message name UIElement
	---@field MessageViewBG UIElement Player message background UIElement
	---@field MessageHeadViewport UIElement Player message head viewport UIElement
	---@field TotalSteps integer Total steps that mark visual progression in current tutorial
	---@field ProgressStep integer Current tutorial visual progression step
	---@field UnignoredKeys integer[] Keys which should be allowed
	---@field UnignoredJoints PlayerJoint[] Joint ids which states can be currently modified
	---@field StoredOptions TutorialOption[] List of modified game options with their original values
	---@field RequireCloseMenu boolean Internal flag whether main menu needs to be closed
	---@field QuitPopupIgnore boolean Internal flag whether quit popup ignore mode is enabled
	---@field QuitPopupOverride function|nil Optional quit popup override function
	---@field ver number
	Tutorials = {
		ver = 5.60,
		Globalid = 1003,
		ReplaySpeed = 1,
		ReplayCache = false,
		TotalSteps = 0,
		ProgressStep = 0,
		StoredOptions = {}
	}
	Tutorials.__index = Tutorials
	setmetatable({}, Tutorials)
end

---Helper class for **Tutorials** with methods that don't need to be public
---@class TutorialsInternal
local TutorialsInternal = { }
setmetatable({}, TutorialsInternal)

---Multiplatform method of loading code from a file. \
---On platforms with no working Lua file interface, we read file contents to a string and then pass it to `loadstring()` instead.
---@param path string
---@return function?
function TutorialsInternal.LoadFile(path)
	if (not is_mobile()) then
		return loadfile(path)
	end

	local file = Files:open(path)
	if (file.data and type(file.data) == "number") then
		---@diagnostic disable-next-line: param-type-mismatch
		local fileContents = file_read(file.data)
		file:close()
		return loadstring(fileContents)
	end
	return nil
end

---@param type TutorialStepRequirementType
---@return TutorialStepRequirement
function TutorialsInternal.NewRequirement(type)
	return { type = type, ready = false }
end

---Creates a new Tutorial step requirement and adds it the specified requirements list
---@param type TutorialStepRequirementType
---@param reqTable TutorialStepRequirement[]
---@return TutorialStepRequirement
function TutorialsInternal.AddRequirement(type, reqTable)
	local requirement = TutorialsInternal.NewRequirement(type)
	table.insert(reqTable, requirement)
	return requirement
end

---Exits Tutorial mode and resets the state back to default
function Tutorials:quit()
	for _, v in pairs(self.StoredOptions) do
		set_option(v.name, v.value)
		TutorialsInternal.HandleMobileOption(v)
	end
	self.StoredOptions = {}

	chat_input_activate()
	if (is_mobile()) then
		TBHud.ChatButtonHolder:show()
	end
	enable_mouse_camera_movement()

	self.MainView:kill()
	self.MainView3D:kill()
	self.CurrentStep = {}

	TUTORIALJOINTLOCK = false
	TUTORIALKEYBOARDLOCK = false
	MoveMemory.TutorialMode = false
	TUTORIAL_ISACTIVE = false
	TUTORIAL_LEAVEGAME = false

	remove_hooks("tbTutorialsVisual")
	remove_hooks("tbTutorialKeyboardHandler")
	remove_hooks("tbTutorialsCustom")
	remove_hooks("tbTutorialsCustomStatic")
	remove_hooks("tbMoveMemoryPlayTurns0")
	remove_hooks("tbMoveMemoryPlayTurns1")
	runCmd("lm classic")

	if (self.QuitOverlay) then
		self.QuitOverlay:kill()
		self.QuitOverlay = nil
	end

	set_discord_rpc("", "")
	disable_player_select(-1)
	open_menu(19)
end

---Sets `quitPopup` override for Tutorials UI
---@param func ?function
function Tutorials:setQuitPopupOverride(func)
	self.QuitPopupOverride = func
end

---Displays Tutorial exit prompt
function Tutorials:quitPopup()
	if (self.QuitPopupOverride) then
		self.QuitPopupOverride()
		return
	end

	if (self.QuitOverlay) then
		self.QuitOverlay:kill()
		self.QuitOverlay = nil
		if (self.RequireCloseMenu) then
			self.QuitPopupIgnore = true
			close_menu()
		end
		return
	end
	if (self.QuitPopupIgnore) then
		self.QuitPopupIgnore = false
		return
	end
	self.QuitOverlay = TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.TUTORIALSLEAVINGPROMPT,
		function()
			close_menu()
			self:quit()
		end,
		function()
			close_menu()
			TUTORIAL_LEAVEGAME = false
		end,
		nil,
		nil,
		self.Globalid)
end

---Loads localization data for the specified tutorial
---@param id integer|string Tutorial id
---@param language ?string Language to get localization for
---@param path ?string Custom path to the localization data file
---@return boolean
function Tutorials:getLocalization(id, language, path)
	self.LocalizedMessages = {}

	local language = language or get_language()
	local path = path or "../data/tutorials/tutorial"
	local localization = Files:open(path .. id .. "_" .. language .. ".txt")
	if (not localization.data) then
		if (language == "english") then
			return false
		else
			return self:getLocalization(id, "english", path)
		end
	end

	for _, ln in pairs(localization:readAll()) do
		if (not ln:match("^#")) then
			local data_stream = { ln:match(("([^\t]*)\t?"):rep(2)) }
			self.LocalizedMessages[data_stream[1]] = data_stream[2]
		end
	end
	localization:close()

	if (language ~= "english") then
		-- Make sure there's no missing values
		local localization = Files:open(path .. id .. "_english.txt")
		for i, ln in pairs(localization:readAll()) do
			if (not ln:match("^#")) then
				local data_stream = { ln:match(("([^\t]*)\t?"):rep(2)) }
				if (not self.LocalizedMessages[data_stream[1]]) then
					self.LocalizedMessages[data_stream[1]] = data_stream[2]
				end
			end
		end
		localization:close()
	end
	return true
end

---@class TutorialTask
---@field id integer Task id
---@field text string Task objective text
---@field complete boolean
---@field element UIElement
---@field mark UIElement
---@field markFail UIElement

---@class TutorialMove
---@field joint PlayerJoint
---@field state PlayerJointState

---@class TutorialMoveRequirement
---@field joint string Joint name as defined in `JOINTS`
---@field state PlayerJointState
---@field opt boolean Whether this requirement is optional
---@field optTask integer Optional task id to mark completed

---@class TutorialOption
---@field name string
---@field value integer

---@class TutorialStep
---@field id integer Step id
---@field skip integer Number of steps to skip after current step completion
---@field fallback integer Number of steps to fall back to after current step completion
---@field newgame boolean Whether this step should trigger new game
---@field mod string Custom mod name that should be loaded for this step
---@field replay string Replay name that should be loaded for this step
---@field cached integer Replay cache mode to use for replay loading
---@field loadplayers string[] Player customs to load for this step
---@field enablecamera boolean Whether camera should be enabled on this step
---@field disablecamera boolean Whether camera should be disabled on this step
---@field damage integer Damage requirement for this step
---@field damageopt integer Optional damage requirement for this step
---@field dismember string Dismember requirement for this step
---@field fracture string Fracture requirement for this step
---@field showsaymessage boolean Whether player say window should appear on this step
---@field hidesaymessage boolean Whether player say window should disappear on this step
---@field showhintmessage boolean Whether hint window should appear on this step
---@field hidehintmessage boolean Whether hint window should disappear on this step
---@field showtaskmessage boolean Whether task window should appear on this step
---@field hidetaskmessage boolean Whether task window should disappear on this step
---@field showwaitbtn boolean Whether continue button should appear on this step
---@field hidewaitbtn boolean Whether continue button should disappear on this step
---@field marktaskcomplete boolean Whether main task should get marked completed on this step
---@field taskoptcomplete integer Optional task id that should get marked completed on this step
---@field taskoptional TutorialTask[] List of optional (with completion status display) tasks for this step
---@field taskadditional TutorialTask[] List of additional (no completion status display) tasks for this step
---@field task string Task message for this step
---@field message string Message for say or hint window for this step
---@field messageby string Message author for say window for this step
---@field progressstep boolean Whether this step should move completion progress bar
---@field delay integer Minimum delay until next step (in seconds)
---@field victory boolean Whether this step requires player in Tori spot to win
---@field editgame boolean Whether this step should trigger edit mode entry
---@field playframes integer Number of frames to play during this step
---@field moveplayer TutorialMove[] Moves to execute by players on this step
---@field movejoint TutorialMoveRequirement[] Moves for player to execute to progress through this step
---@field waitbtn boolean Whether progressing through this step requires user to press Continue button
---@field jointlock boolean Whether joints should be locked on this step
---@field jointunlock boolean Whether joints should be unlocked on this step
---@field keyboardlock boolean Whether keyboard input should be locked on this step
---@field shiftunlock boolean Whether shift key input should be unlocked on this step
---@field playsound integer Sound id to play on this step
---@field failframe integer Game frame that marks current step as failed and triggers step fallback
---@field fallbackrequirement boolean Whether fallback requirement is active for this step
---@field proceedframe integer Game frame that marks current step as complete
---@field ghostmode GhostMode Ghost mode to activate on this step
---@field keyboardunlock boolean Whether keyboard input should be unlocked on this step
---@field keystounlock string List of symbols which corresponding keys should be unlocked
---@field introOverlay boolean Whether intro overlay animation should display on this step
---@field outroOverlay boolean Whether outro overlay animation should display on this step
---@field playerlock integer Player id which selection should be disabled on this step
---@field customfuncfile function|nil Custom function data for this step
---@field customfunc string Custom function name for this step
---@field opt boolean Whether this step has game options overrides specified
---@field opts TutorialOption[] List of game options to set on this step
---@field cameramode CameraMode Camera mode to set on this step

---Loads the Tutorial steps data
---@param id number|string Tutorial id
---@param path ?string Custom tutorial data file path
---@return TutorialStep[]?
function Tutorials:loadTutorial(id, path)
	local cfuncpath = path and utf8.gsub(path, "%.%./data/", "") or "tutorial/data/funcs"
	local path = path or "../data/tutorials/tutorial"
	local tutorial = Files:open(path .. id .. ".dat")
	if (not tutorial.data) then
		download_server_file("tutorial_" .. id .. "&language=" .. TB_MENU_LOCALIZED.language, 0)
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.TUTORIALNODATAFOUND)
		self:quit()
		TBMenu.StatusMessage:reload()
		return nil
	end
	local tutorialData = tutorial:readAll()
	tutorial:close()

	self.CurrentTutorial = id

	---@type TutorialStep[]
	local steps = {}
	for _, ln in pairs(tutorialData) do
		ln = ln:gsub(";$", "")
		if (ln:find("^STEP")) then
			if (ln:find("^STEPSKIP")) then
				steps[#steps].skip = ln:gsub("STEPSKIP ", "") + 0
			elseif (ln:find("^STEPFALLBACK")) then
				steps[#steps].fallback = ln:gsub("STEPFALLBACK ", "") + 0
			else
				steps[#steps + 1] = { skip = 0, id = #steps + 1 }
			end
		elseif (ln:find("^NEWGAME")) then
			steps[#steps].newgame = true
			steps[#steps].mod = ln:gsub("^NEWGAME ", "")
		elseif (ln:find("^LOADREPLAY")) then
			steps[#steps].replay = ln:gsub("^LOADREPLAY ", ""):gsub(" %d", "")
			local _, cacheSpecified = ln:gsub("%d$", "")
			if (cacheSpecified > 0) then
				steps[#steps].cached = ln:sub(-1) + 0
			else
				steps[#steps].cached = 0
			end
		elseif (ln:find("^LOADPLAYER")) then
			steps[#steps].loadplayers = steps[#steps].loadplayers or {}
			ln = ln:gsub("^LOADPLAYER ", "")
			local playerid = tonumber(ln:gsub("%D", "")) or 0
			local player = ln:gsub("^%d ", "")
			steps[#steps].loadplayers[playerid] = player
		elseif (ln:find("^ENABLECAMERA")) then
			steps[#steps].enablecamera = true
		elseif (ln:find("^DISABLECAMERA")) then
			steps[#steps].disablecamera = true
		elseif (ln:find("^DAMAGE %d")) then
			steps[#steps].damage = ln:gsub("%D", "") + 0
		elseif (ln:find("^DAMAGEOPT %d")) then
			steps[#steps].damageopt = ln:gsub("%D", "") + 0
		elseif (ln:find("^DISMEMBER")) then
			steps[#steps].dismember = ln:gsub("^DISMEMBER ", "")
		elseif (ln:find("^FRACTURE")) then
			steps[#steps].fracture = ln:gsub("^FRACTURE ", "")
		elseif (ln:find("^SHOWSAYMESSAGE")) then
			steps[#steps].showsaymessage = true
		elseif (ln:find("^HIDESAYMESSAGE")) then
			steps[#steps].hidesaymessage = true
		elseif (ln:find("^SHOWHINTMESSAGE")) then
			steps[#steps].showhintmessage = true
		elseif (ln:find("^HIDEHINTMESSAGE")) then
			steps[#steps].hidehintmessage = true
		elseif (ln:find("^SHOWTASKMESSAGE")) then
			steps[#steps].showtaskmessage = true
		elseif (ln:find("^HIDETASKMESSAGE")) then
			steps[#steps].hidetaskmessage = true
		---Tooltip functions are deprecated, use `OPT tooltip 1|0` instead
		--[[elseif (ln:find("^SHOWTOOLTIP")) then
			steps[#steps].showtooltip = true
		elseif (ln:find("^HIDETOOLTIP")) then
			steps[#steps].hidetooltip = true]]
		elseif (ln:find("^SHOWWAITBUTTON")) then
			steps[#steps].showwaitbtn = true
		elseif (ln:find("^HIDEWAITBUTTON")) then
			steps[#steps].hidewaitbtn = true
		elseif (ln:find("^TASKCOMPLETE")) then
			steps[#steps].marktaskcomplete = true
		elseif (ln:find("^TASKOPTCOMPLETE")) then
			steps[#steps].taskoptcomplete = ln:gsub("^TASKOPTCOMPLETE ", "") + 0
		elseif (ln:find("^TASKOPT")) then
			local data = { ln:gsub("^TASKOPT ", ""):match(("([^\t]+)\t*"):rep(2)) }
			steps[#steps].taskoptional = steps[#steps].taskoptional or {}
			table.insert(steps[#steps].taskoptional, { id = data[1] + 0, text = data[2] })
		elseif (ln:find("^TASKADD")) then
			local data = { ln:gsub("^TASKADD ", ""):match(("([^\t]+)\t*"):rep(2)) }
			steps[#steps].taskadditional = steps[#steps].taskadditional or {}
			table.insert(steps[#steps].taskadditional, { id = data[1] + 0, text = data[2] })
		elseif (ln:find("^TASK")) then
			steps[#steps].task = ln:gsub("^TASK ", "")
		elseif (ln:find("^MESSAGE")) then
			steps[#steps].message = ln:gsub("^MESSAGE ", "")
		elseif (ln:find("^SAY")) then
			steps[#steps].messageby = ln:gsub("^SAY ", "")
		elseif (ln:find("^ADVANCE")) then
			steps[#steps].progressstep = true
			self.TotalSteps = self.TotalSteps + 1
		elseif (ln:find("^DELAY")) then
			steps[#steps].delay = ln:gsub("^%D+", "") + 0
		elseif (ln:find("^VICTORY")) then
			steps[#steps].victory = true
		elseif (ln:find("^EDITGAME")) then
			steps[#steps].editgame = true
		elseif (ln:find("^PLAYFRAMES")) then
			steps[#steps].playframes = ln:gsub("%D", "") + 0
		elseif (ln:find("^MOVEPLAYER")) then
			local player = ln:find("^MOVEPLAYER TORI") and TORI or UKE
			steps[#steps].moveplayer = steps[#steps].moveplayer or {}
			steps[#steps].moveplayer[player] = steps[#steps].moveplayer[player] or {}
			if (ln:find("HOLDALL$")) then
				for i,v in pairs(JOINTS) do
					table.insert(steps[#steps].moveplayer[player], { joint = i, state = "HOLD" })
				end
			elseif (ln:find("RELAXALL$")) then
				for i,v in pairs(JOINTS) do
					table.insert(steps[#steps].moveplayer[player], { joint = i, state = "RELAX" })
				end
			else
				local data = { ln:gsub("^MOVEPLAYER %a+ ", ""):match(("([^ ]+) *"):rep(2)) }
				table.insert(steps[#steps].moveplayer[player], { joint = data[1], state = data[2] })
			end
		elseif (ln:find("^MOVEJOINT")) then
			steps[#steps].movejoint = steps[#steps].movejoint or {}
			local optional = false
			local optTask = 0
			if (ln:find("^MOVEJOINTOPTIONAL")) then
				optional = true
				if (ln:find("%d$")) then
					optTask = ln:gsub("^%D+", "") + 0
					ln = ln:gsub(" " .. optTask .. "$", "")
				end
			end
			local data = { ln:gsub("^MOVEJOINT" .. (optional and "OPTIONAL " or " "), ""):match(("([^ ]+) *"):rep(2)) }
			table.insert(steps[#steps].movejoint, { joint = data[1], state = data[2], opt = optional, optTask = optTask })
		elseif (ln:find("^WAITBUTTON")) then
			steps[#steps].waitbtn = true
		elseif (ln:find("^JOINTLOCK")) then
			steps[#steps].jointlock = true
		elseif (ln:find("^JOINTUNLOCK")) then
			steps[#steps].jointunlock = true
		elseif (ln:find("^KEYBOARDLOCK")) then
			steps[#steps].keyboardlock = true
		elseif (ln:find("^SHIFTUNLOCK")) then
			steps[#steps].shiftunlock = true
		elseif (ln:find("^PLAYSOUND")) then
			steps[#steps].playsound = ln:gsub("PLAYSOUND ", "") + 0
		elseif(ln:find("^FAILFRAME")) then
			steps[#steps].failframe = ln:gsub("FAILFRAME ", "") + 0
			steps[#steps].fallbackrequirement = true
		elseif(ln:find("^PROCEEDFRAME")) then
			steps[#steps].proceedframe = ln:gsub("PROCEEDFRAME ", "") + 0
		elseif (ln:find("^GHOSTMODE")) then
			local ghost = ln:gsub("^GHOSTMODE ", "")
			steps[#steps].ghostmode = ghost == "TORI" and 1 or (ghost == "NONE" and 0 or 2)
		elseif (ln:find("^KEYBOARDUNLOCK")) then
			steps[#steps].keyboardunlock = true
			if (ln:len() > 14) then
				steps[#steps].keystounlock = ln:gsub("KEYBOARDUNLOCK ", ""):lower()
			end
		elseif (ln:find("^INTROFADE")) then
			steps[#steps].introOverlay = true
		elseif (ln:find("^OUTROFADE")) then
			steps[#steps].outroOverlay = true
		elseif (ln:find("^PLAYERLOCK")) then
			steps[#steps].playerlock = ln:gsub("PLAYERLOCK ", "") + 0
		elseif (ln:find("^CAMERAMODE")) then
			steps[#steps].cameramode = ln:gsub("CAMERAMODE ", "") + 0
		elseif (ln:find("^CUSTOMFUNC")) then
			steps[#steps].customfuncfile = TutorialsInternal.LoadFile(cfuncpath .. id .. ".lua")
			steps[#steps].customfunc = ln:gsub("CUSTOMFUNC ", "")
		elseif (ln:find("^OPT")) then
			steps[#steps].opt = true
			steps[#steps].opts = steps[#steps].opts or {}
			local opt = {
				name = ln:gsub("OPT ", ""):gsub(" %d+.*$", ""),
				value = ln:gsub("%D", "") + 0
			}
			table.insert(steps[#steps].opts, opt)
		end
	end
	return steps
end

---@alias TutorialStepRequirementType
---| "button"
---| "transition"
---| "damage"
---| "dismember"
---| "fracture"
---| "message"
---| "delay"
---| "victory"
---| "jointmove"
---| "playframes"
---| "loadreplay"
---| "hintmessagefade"
---| "taskwindowmove"
---| "messagewindowmove"
---| "custom"

---@class TutorialStepRequirement
---@field ready boolean
---@field optional boolean
---@field optReady boolean
---@field type TutorialStepRequirementType

---Checks whether step requirements are complete
---@param reqTable TutorialStepRequirement[]
---@param excludeRequirement ?TutorialStepRequirementType
---@return boolean
function TutorialsInternal.CheckRequirements(reqTable, excludeRequirement)
	for _, v in ipairs(reqTable) do
		if (type(v) == "table") then
			if (not v.ready) then
				if (v.type ~= excludeRequirement) then
					return false
				end
			end
		end
	end
	return true
end

---Checks whether all optional step requirements are complete
---@param reqTable TutorialStepRequirement[]
---@return boolean
function TutorialsInternal.checkOptRequirements(reqTable)
	for _, v in pairs(reqTable) do
		if (type(v) == "table") then
			if (v.optional) then
				if (not v.optReady) then
					return false
				end
			end
		end
	end
	return true
end

---Shows generic step intro / outro overlay
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param out boolean?
---@param speed number?
function Tutorials:showOverlay(viewElement, reqTable, out, speed)
	local speed = speed or 1
	local req = TutorialsInternal.AddRequirement("transition", reqTable)

	if (self.StepOverlay ~= nil) then
		self.StepOverlay:kill()
		self.StepOverlay = nil
	end
	local elementParent = out and self.MainView or viewElement
	local overlay = elementParent:addChild({
		bgColor = table.clone(UICOLORWHITE)
	})
	if (out) then
		self.StepOverlay = overlay
	end

	local spawnClock = UIElement.clock
	overlay:addCustomDisplay(function()
			local ratio = (UIElement.clock - spawnClock) * speed * 2
			overlay.bgColor[4] = UITween.SineTween(out and 0 or 1, out and 1 or 0, ratio)
			if (ratio >= 1) then
				req.ready = true
				reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
				if (not out) then
					overlay:kill()
				end
			end
		end, true)
end

---Shortcut function to show generic intro overlay
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
function Tutorials:introOverlay(viewElement, reqTable)
	self:showOverlay(viewElement, reqTable)
end

---Shortcut function to show generic outro overlay
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
function Tutorials:outroOverlay(viewElement, reqTable)
	self:showOverlay(viewElement, reqTable, true)
end

---Shortcut function to hide step `Continue` button
function Tutorials:hideWaitButton()
	self:showWaitButton(nil, true)
end

---Displays or hides step `Continue` button
---@param _ any
---@param hide ?boolean
function Tutorials:showWaitButton(_, hide)
	if (hide) then
		self.ContinueButton:hide()
	else
		self.ContinueButton:show()
		self.ContinueButton:activate()
		self.ContinueButton:deactivate()
	end
end

---@class TutorialContinueButton : UIElement
---@field req TutorialStepRequirement
---@field reqTable TutorialStepRequirement[]

---Adds `Continue` button press requirement for the step
---@param reqTable TutorialStepRequirement[]
function Tutorials:reqButton(reqTable)
	local req = TutorialsInternal.AddRequirement("button", reqTable)

	if (not self.ContinueButton:isDisplayed()) then
		self:showWaitButton()
	end

	local buttonWait = self.ContinueButton:addChild({})
	buttonWait:addCustomDisplay(true, function()
			if (TutorialsInternal.CheckRequirements(reqTable, "button")) then
				self.ContinueButton:activate()
				self.ContinueButton.req = req
				self.ContinueButton.reqTable = reqTable
				self.ContinueButton:addMouseUpHandler(function()
						req.ready = true
						reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
						self.ContinueButton:deactivate()
						self.ContinueButton.req = nil
						self.ContinueButton.reqTable = nil
					end)
				buttonWait:kill()
			end
		end)
end

---Adds damage requirement for the step
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param dmg integer
---@param opt ?boolean
function Tutorials:reqDamage(viewElement, reqTable, dmg, opt)
	local opt = opt or false

	local req = TutorialsInternal.AddRequirement("damage", reqTable)
	req.ready, req.optional = opt, opt

	local reqElement = viewElement:addChild({ })
	reqElement:addCustomDisplay(true, function()
			if (get_player_info(1).injury > dmg) then
				if (opt) then
					req.optReady = true
					reqTable.skip = TutorialsInternal.checkOptRequirements(reqTable) and 1 or 0
					if (reqTable.skip == 1) then
						self:taskOptComplete(0)
					end
				else
					req.ready = true
					reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
				end
				reqElement:kill()
			end
		end)
end

---Adds dismember requirement for the step
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param jointName string
function Tutorials:reqDismember(viewElement, reqTable, jointName)
	if (not JOINTS[jointName]) then
		if (TB_MENU_DEBUG) then
			echo("No joint found with name " .. jointName)
		end
		return nil
	end

	local req = TutorialsInternal.AddRequirement("dismember", reqTable)

	local reqElement = viewElement:addChild({ })
	local jointPulse = self.MainView3D:addChild({
		playerAttach = UKE,
		attachJoint = JOINTS[jointName],
		pos = { 0, 0, 0 },
		size = { 1, 1, 1 },
		shapeType = SPHERE,
		bgColor = { 0.3, 0.1, 0.7, 1 }
	})
	local jointPulseLastClock = UIElement.clock
	jointPulse:addCustomDisplay(false, function()
			local timeDiff = UIElement.clock - jointPulseLastClock
			jointPulse.size.x = jointPulse.size.x + timeDiff / 15
			jointPulse.bgColor[4] = jointPulse.bgColor[4] - timeDiff * 5
			if (jointPulse.size.y + 0.1 < jointPulse.size.x) then
				jointPulse.size.x = jointPulse.size.y
				jointPulse.bgColor[4] = 1
			end
			jointPulseLastClock = UIElement.clock
		end)
	reqElement:addCustomDisplay(true, function()
			if (get_joint_dismember(1, JOINTS[jointName])) then
				req.ready = true
				reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
				jointPulse:kill()
				reqElement:kill()
			end
		end)
end

---Adds fracture requirement for the step
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param jointName string
function Tutorials:reqFracture(viewElement, reqTable, jointName)
	if (not JOINTS[jointName]) then
		if (TB_MENU_DEBUG) then
			echo("No joint found with name " .. jointName)
		end
		return nil
	end

	local req = TutorialsInternal.AddRequirement("fracture", reqTable)

	local reqElement = viewElement:addChild({ })
	reqElement:addCustomDisplay(true, function()
			if (get_joint_fracture(1, JOINTS[jointName])) then
				req.ready = true
				reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
				reqElement:kill()
			end
		end)
end

---Displays tasks window
---@param _ any
---@param reqTable TutorialStepRequirement[]
---@param message string
function Tutorials:showTask(_, reqTable, message)
	local req = TutorialsInternal.AddRequirement("message", reqTable)
	local messageTransparency = self.TaskView:addChild({ })
	local textColor = { 1, 1, 1, 0 }
	local spawnClock = UIElement.clock
	messageTransparency:addCustomDisplay(true, function()
			textColor[4] = UITween.SineTween(textColor[4], 1, UIElement.clock - spawnClock)
			if (textColor[4] >= 1) then
				textColor[4] = 1
				messageTransparency:kill()
				req.ready = true
				reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
			end
		end)

	self.TaskView:addAdaptedText(true, message, nil, nil, 4, LEFTMID, 0.7, nil, nil, nil, textColor)
end

---Displays hint window
---@param _ any
---@param reqTable TutorialStepRequirement[]
---@param message string
function Tutorials:showHint(_, reqTable, message)
	local req = TutorialsInternal.AddRequirement("message", reqTable)
	self.HintMessageView:kill(true)

	local messageTransparency = self.HintView:addChild({ })
	local textColor = { 1, 1, 1, 0 }
	local spawnClock = UIElement.clock
	messageTransparency:addCustomDisplay(true, function()
			textColor[4] = UITween.SineTween(textColor[4], 1, UIElement.clock - spawnClock)
			if (textColor[4] >= 1) then
				textColor[4] = 1
				messageTransparency:kill()
				req.ready = true
				reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
			end
		end)

	self.HintMessageView:addAdaptedText(true, message, nil, nil, 4, nil, 0.8, nil, nil, nil, textColor)

	for i, v in pairs(self.HintMessageView.dispstr) do
		local _, count = utf8.gsub(v, "%b~~", "")
		local endposLast = 0
		for _ = 1, count do
			local startpos, endpos = utf8.find(v, "%b~~", endposLast)
			endposLast = endpos + 1
			if (startpos) then
				local displayLength = get_string_length(utf8.sub(v, 0, startpos - 1), 4) * self.HintMessageView.textScale - 1
				local displayLineLength = get_string_length(v, 4) * self.HintMessageView.textScale
				local displayKey = utf8.sub(v, startpos + 1, endpos - 1)
				local displayKeyLength = get_string_length(utf8.sub(v, startpos, endpos), 4) * self.HintMessageView.textScale + 2
				local keyPressBG = self.HintMessageView:addChild({
					pos = { (self.HintMessageView.size.w - displayLineLength) / 2 + displayLength, (self.HintMessageView.size.h - 24 * self.HintMessageView.textScale * #self.HintMessageView.dispstr) / 2 + 24 * self.HintMessageView.textScale * (i - 1) },
					size = { displayKeyLength, 28 * self.HintMessageView.textScale },
					bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					shapeType = ROUNDED,
					rounded = 4
				})
				local keyPress = keyPressBG:addChild({
					shift = { 1, 1 },
					bgColor = TB_MENU_DEFAULT_BG_COLOR
				}, true)
				keyPress:addAdaptedText(displayKey, nil, nil, 4)
			end
		end
	end
end

---Displays player message
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param message string
---@param messageby string
function Tutorials:showMessage(viewElement, reqTable, message, messageby)
	local req = TutorialsInternal.AddRequirement("message", reqTable)

	local animationWait = viewElement:addChild({ })
	self.MessageView.doSkip = false
	animationWait:addCustomDisplay(true, function()
		if (self.MessageViewHolder.pos.x > WIN_W - self.MessageViewHolder.size.w) then
			return
		end
		animationWait:kill()

		if (self.MessageHeadViewport.lastAuthor ~= messageby) then
			self.MessageHeadViewport.lastAuthor = messageby
			self.MessageHeadViewport:kill(true)
			if (messageby == "PLAYER") then
				TBMenu:showPlayerHeadAvatar(self.MessageHeadViewport, TB_MENU_PLAYER_INFO)
				self.MessageViewNameBG.bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR)
				self.MessageViewBG.shadowColor[2] = table.clone(TB_MENU_DEFAULT_BG_COLOR)
				self.MessageViewName:addAdaptedText(true, TB_MENU_PLAYER_INFO.username or "Tori", nil, nil, 2)
			else
				self.MessageViewName:addAdaptedText(true, messageby, nil, nil, 2)
				if (messageby == "SENSEI") then
					messageby = "senseitutorial"
				end
				local playerInfo = PlayerInfo.Get(messageby)
				playerInfo:getItems(PLAYERINFO_CSCOPE_COLORS + PLAYERINFO_CSCOPE_TEXTURES)
				TBMenu:showPlayerHeadAvatar(self.MessageHeadViewport, playerInfo)
				self.MessageViewNameBG.bgColor = { 0.2, 0.34, 0.87, 1 }
				self.MessageViewBG.shadowColor[2] = { 0.2, 0.34, 0.87, 1 }
			end
		end

		local messageBuilder = self.MessageView:addChild({ })
		local lastClock = UIElement.clock
		local lastSub = 0
		messageBuilder:addCustomDisplay(true, function()
				local sub = self.MessageView.doSkip and utf8.len(message) or lastSub
				if (lastClock < UIElement.clock) then
					sub = lastSub + math.round((UIElement.clock - lastClock) * 25)
					if (sub ~= lastSub) then
						local pausePos, endPos = utf8.find(utf8.sub(message, lastSub + 1, sub), "[.,?!-:;]")
						if (pausePos ~= nil) then
							sub = lastSub + 1 + endPos
							lastClock = UIElement.clock + 0.1
						else
							lastClock = UIElement.clock
						end
						lastSub = sub
					end
				end
				self.MessageViewHolder:addAdaptedText(false, utf8.sub(message, 0, sub), nil, nil, nil, LEFTMID)

				if (sub >= utf8.len(message)) then
					req.ready = true
					reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
					messageBuilder:kill()
				end
			end)
	end)
end

---Adds time delay requirement
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param delay number
function Tutorials:reqDelay(viewElement, reqTable, delay)
	local req = TutorialsInternal.AddRequirement("delay", reqTable)

	local reqElement = viewElement:addChild({})
	local spawnTime = UIElement.clock
	reqElement:addCustomDisplay(true, function()
			if (UIElement.clock - spawnTime > delay) then
				req.ready = true
				reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
				reqElement:kill()
			end
		end)
end

---Adds player victory requirement
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
function Tutorials:reqVictory(viewElement, reqTable)
	local req = TutorialsInternal.AddRequirement("victory", reqTable)

	local reqElement = viewElement:addChild({})
	reqElement:addCustomDisplay(true, function()
			if (get_world_state().winner == 0) then
				req.ready = true
				reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
				reqElement:kill()
			end
		end)
end

---Adds joint move requirement
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param info TutorialMoveRequirement
function Tutorials:reqJointMove(viewElement, reqTable, info)
	local req = TutorialsInternal.AddRequirement("jointmove", reqTable)
	if (info.opt) then
		req.ready = info.opt
		req.optional = true
		req.optReady = false
	end
	table.insert(Tutorials.UnignoredJoints, JOINTS[info.joint])

	local reqElement = viewElement:addChild({})
	local jointPulse
	if (not info.opt) then
		jointPulse = self.MainView3D:addChild({
			playerAttach = TORI,
			attachJoint = JOINTS[info.joint],
			pos = { 0, 0, 0 },
			size = { 1, 1, 1 },
			shapeType = SPHERE,
			bgColor = { 0.3, 0.1, 0.7, 1 }
		})
		local jointPulseLastClock = UIElement.clock
		jointPulse:addCustomDisplay(false, function()
				local timeDiff = UIElement.clock - jointPulseLastClock
				jointPulse.size.x = jointPulse.size.x + timeDiff / 4
				jointPulse.bgColor[4] = jointPulse.bgColor[4] - timeDiff
				if (jointPulse.size.y + 0.25 < jointPulse.size.x) then
					jointPulse.size.x = jointPulse.size.y
					jointPulse.bgColor[4] = 1
				end
				jointPulseLastClock = UIElement.clock
			end)
	end
	reqElement:addCustomDisplay(true, function()
			if (get_joint_info(0, JOINTS[info.joint]).state == JOINT_STATE[info.state]) then
				for i,v in pairs(Tutorials.UnignoredJoints) do
					if (v == JOINTS[info.joint]) then
						table.remove(Tutorials.UnignoredJoints, i)
						break
					end
				end
				req.ready = true
				if (info.opt) then
					req.optReady = true
					reqTable.skip = TutorialsInternal.checkOptRequirements(reqTable) and 1 or 0
					if (reqTable.skip == 1) then
						Tutorials:taskOptComplete(info.optTask)
					end
				end
				reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
				reqElement:kill()
				if (jointPulse) then
					jointPulse:kill()
				end
			end
		end)
end

---Plays specified number of frames
---@param _ any
---@param reqTable TutorialStepRequirement[]
---@param frames integer
function Tutorials:playFrames(_, reqTable, frames)
	local req = TutorialsInternal.AddRequirement("playframes", reqTable)
	local currentFrame = get_world_state().match_frame
	if (self.ReplayCache == true) then
		set_replay_speed(self.ReplaySpeed)
	else
		frames = frames - 1
		run_frames(frames - (get_world_state().replay_mode - 1))
	end

	local function checkFrame()
		if (get_world_state().match_frame == currentFrame + frames) then
			if (self.ReplayCache == true) then
				set_replay_speed(0)
			end
			req.ready = true
			reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
			remove_hook("enter_frame", "playFrame")
		end
	end

	add_hook("enter_frame", "playFrame", checkFrame)
end

---Sets joint states as per specified data
---@param data TutorialMove[][]
function Tutorials:moveJoints(data)
	for i, player in pairs(data) do
		for _, joint in pairs(player) do
			set_joint_state(i, JOINTS[joint.joint], JOINT_STATE[joint.state])
		end
	end
end

---Starts new game
---@param _ any
---@param reqTable TutorialStepRequirement[]
---@param mod ?string
function Tutorials:startNewGame(_, reqTable, mod)
	TUTORIAL_LEAVEGAME = true
	if (mod) then
		runCmd("lm " .. mod)
	else
		start_new_game()
	end
	TUTORIAL_LEAVEGAME = false
	reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
end

---Loads players' customs onto player spots
---@param players string[]
function Tutorials:loadPlayer(players)
	for i,v in pairs(players) do
		if (v == "PLAYER") then
			v = TB_MENU_PLAYER_INFO.username
		elseif (v == "SENSEI") then
			v = "senseitutorial"
		end
		runCmd("loadplayer " .. i .. " " .. v)
	end
end

---Loads replay and pauses it
---@param _ any
---@param reqTable TutorialStepRequirement[]
---@param replay string
---@param cache integer
function Tutorials:loadReplay(_, reqTable, replay, cache)
	self.ReplayCache = cache ~= 0

	TUTORIAL_LEAVEGAME = true
	open_replay("system/tutorial/" .. replay, cache)
	if (self.ReplayCache) then
		set_replay_speed(0)
	end
	freeze_game()
	TUTORIAL_LEAVEGAME = false

	reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
end

---Runs a custom function from a preloaded file
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param file function
---@param func string
function Tutorials:runTutorialCustomFunction(viewElement, reqTable, file, func)
	TutorialsInternal.ExportLegacyGlobals(self)

	---@type function[]?
	local loadedFuncs = file()
	if (loadedFuncs == nil) then
		---In legacy version of Tutorials backend we would be looking for a `functions` global table
		---@diagnostic disable-next-line: undefined-global
		loadedFuncs = functions
	end
	if (loadedFuncs[func]) then
		loadedFuncs[func](viewElement, reqTable)
	end
end

---Publicly exposed method to check current step requirements completion
---@param reqTable TutorialStepRequirement[]
---@return boolean
function Tutorials:checkRequirements(reqTable)
	return TutorialsInternal.CheckRequirements(reqTable)
end

---Generic Tutorials keyboard input handler
---@param key integer
---@param keycode integer
---@param jointlock ?boolean
---@param keyboardlock ?boolean
---@return integer
function Tutorials.HandleKeyPress(key, keycode, jointlock, keyboardlock)
	if ((jointlock and TUTORIALJOINTLOCK) or (keyboardlock and TUTORIALKEYBOARDLOCK)) then
		for _, v in pairs(Tutorials.UnignoredKeys) do
			if (key == v[1] or keycode == v[2]) then
				return 0
			end
		end
		return 1
	elseif ((key == 112 or key == 114) and not TUTORIAL_SPECIAL_RP_IGNORE) then
		return 1
	end
	return 0
end

---Generic Tutorials joint select handler
---@param _ integer
---@param joint PlayerJoint
---@return integer
function Tutorials.HandleJointSelect(_, joint)
	for _, v in pairs(Tutorials.UnignoredJoints) do
		if (joint == v) then
			return 0
		end
	end
	Tooltip.TouchDeselect()
	return 1
end

---Generic Tutorials body select handler
---@param _ integer
---@param body PlayerBody
---@return integer
function Tutorials.HandleBodySelect(_, body)
	if (not TUTORIALJOINTLOCK) then
		if (body == 11 or body == 12) then
			return 0
		end
	end
	Tooltip.TouchDeselect()
	return 1
end

---Enters game edit mode
function Tutorials:editGame()
	edit_game()
	set_camera_mode(0)
end

---Shorthand function to hide hint display
---@param reqTable TutorialStepRequirement[]
function Tutorials:hideHintWindow(reqTable)
	self:showHintWindow(reqTable, true)
end

---Shows or hides hint display
---@param reqTable TutorialStepRequirement[]
---@param hide ?boolean
function Tutorials:showHintWindow(reqTable, hide)
	local req = TutorialsInternal.AddRequirement("hintmessagefade", reqTable)

	if (hide) then
		self.HintMessageView:kill(true)
		self.HintMessageView:addCustomDisplay(true, function() end)
	end

	local windowFade = self.HintView:addChild({})
	windowFade.killAction = function()
		req.ready = true
		reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
	end

	local spawnClock = UIElement.clock
	windowFade:addCustomDisplay(true, function()
			self.HintView.bgColor[4] = UITween.SineTween(self.HintView.bgColor[4], hide and 0 or 0.7, UIElement.clock - spawnClock)
			if (hide and self.HintView.bgColor[4] <= 0) then
				self.HintView.bgColor[4] = 0
				windowFade:kill()
			elseif (not hide and self.HintView.bgColor[4] >= 0.7) then
				self.HintView.bgColor[4] = 0.7
				windowFade:kill()
			end
		end)
end

---Adds optional task
---@param data TutorialTask
---@param taskText string
function Tutorials:addOptionalTask(data, taskText)
	local optTaskColor = table.clone(TB_MENU_DEFAULT_BG_COLOR)
	optTaskColor[4] = 0.7

	local optTaskView = self.TaskViewHolder:addChild({
		pos = { 0, self.TaskViewHolder.size.h - 40 },
		size = { self.TaskViewHolder.size.w, 40 },
		bgColor = optTaskColor
	})

	local optTaskMarkView = optTaskView:addChild({
		pos = { 10, 8 },
		size = { 24, 24 },
		bgColor = { 0, 0, 0, 0.2 },
		shapeType = ROUNDED,
		rounded = 4
	})

	local optTaskMark = optTaskMarkView:addChild({
		bgImage = "../textures/menu/general/buttons/checkmark.tga"
	})
	optTaskMark:hide(true)
	local optTaskMarkFail = optTaskMarkView:addChild({
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})
	optTaskMarkFail:hide(true)

	local optTaskTextView = optTaskView:addChild({
		pos = { 44, 3 },
		size = { optTaskView.size.w - 54, 34 }
	})
	optTaskTextView:addAdaptedText(true, taskText, nil, nil, 4, LEFTMID, 0.6)

	self.TaskViewHolder:hide()
	optTaskView:show()
	self.TaskViewHolder:show()

	local posVertical = #self.TaskViewHolder.optional
	local task = { id = data.id, complete = false, element = optTaskView, mark = optTaskMark, markFail = optTaskMarkFail, textView = optTaskTextView }
	table.insert(self.TaskViewHolder.optional, task)

	local spawnClock = UIElement.clock
	optTaskView:addCustomDisplay(false, function()
			local targetShift = self.TaskViewHolder.size.h + posVertical * 40
			if (optTaskView.shift.y < targetShift) then
				optTaskView:moveTo(nil, UITween.SineTween(optTaskView.shift.y, targetShift, UIElement.clock - spawnClock))
			else
				optTaskView:addCustomDisplay(false, function() end)
			end
		end)
end

---Adds additional task
---@param data TutorialTask
---@param taskText string
function Tutorials:addAdditionalTask(data, taskText)
	local optTaskColor = table.clone(TB_MENU_DEFAULT_BG_COLOR)
	optTaskColor[4] = 0.7

	local optTaskView = self.TaskViewHolder:addChild({
		pos = { 0, self.TaskViewHolder.size.h - 40 },
		size = { self.TaskViewHolder.size.w, 40 },
		bgColor = optTaskColor
	})

	local optTaskTextView = optTaskView:addChild({
		pos = { 10, 3 },
		size = { optTaskView.size.w - 20, 34 }
	})
	optTaskTextView:addAdaptedText(true, taskText, nil, nil, 4, LEFTMID, 0.6)

	self.TaskViewHolder:hide()
	optTaskView:show()
	self.TaskViewHolder:show()

	local posVertical = #self.TaskViewHolder.extra
	local task = { id = data.id, complete = false, element = optTaskView, textView = optTaskTextView }
	table.insert(self.TaskViewHolder.extra, task)

	local spawnClock = UIElement.clock
	optTaskView:addCustomDisplay(false, function()
			local targetShift = self.TaskViewHolder.size.h + posVertical * 40
			if (optTaskView.shift.y < targetShift) then
				optTaskView:moveTo(nil, UITween.SineTween(optTaskView.shift.y, targetShift, UIElement.clock - spawnClock))
			else
				optTaskView:addCustomDisplay(false, function() end)
			end
		end)
end

---Marks an optional task incomplete
---@param id integer
function Tutorials:taskOptIncomplete(id)
	for _, v in pairs(self.TaskViewHolder.optional) do
		if (v.id == id) then
			v.mark:hide(true)
			v.markFail:hide(true)
			v.complete = false
		end
	end
end

---Plays a generic task completion animation
---@param viewElement UIElement
function TutorialsInternal.PlayTaskAnimation(viewElement)
	if (viewElement == nil or viewElement.destroyed) then
		return
	end

	local spawnClock = UIElement.clock
	viewElement:addCustomDisplay(false, function()
			local animateRatio = UITween.SineEaseIn(UIElement.clock - spawnClock)
			if (animateRatio == 1) then
				viewElement:addCustomDisplay(false, function() end)
				return
			end
			set_color(1, 1, 1, animateRatio * 0.7)
			draw_disk(
				viewElement.pos.x + viewElement.size.w / 2,
				viewElement.pos.y + viewElement.size.h / 2,
				0, viewElement.size.w * animateRatio, 20, 1, 0, 360, 0)
		end)
end

---Marks an optional task complete
---@param id any
function Tutorials:taskOptComplete(id)
	local targetTask = nil
	for _, v in pairs(self.TaskViewHolder.optional) do
		if (v.id == id) then
			targetTask = v
		end
	end
	if (targetTask == nil) then
		return
	end

	targetTask.complete = true
	if (targetTask.mark:isDisplayed()) then
		return
	end
	targetTask.mark:show(true)

	TutorialsInternal.PlayTaskAnimation(targetTask.mark)
	play_sound(36)
end

---Marks the main task complete
---@param noOptFail ?boolean
function Tutorials:taskComplete(noOptFail)
	self.TaskMark:show(true)
	if (not noOptFail) then
		for _, v in pairs(self.TaskViewHolder.optional) do
			if (not v.complete) then
				v.markFail:show(true)
				v.markFail.bgColor = { 1, 0, 0, 0.2 }
			end
		end
	end

	TutorialsInternal.PlayTaskAnimation(self.TaskMark:addChild({ }))
	play_sound(36)
end

---Sets ghost mode
---@param mode GhostMode
function Tutorials:setGhostMode(mode)
	set_ghost(mode)
end

---Plays a sound by its id
---@param id integer
function Tutorials:playSound(id)
	play_sound(id)
end

---Shorthand function to hide task window
---@param reqTable TutorialStepRequirement[]
function Tutorials:hideTaskWindow(reqTable)
	Tutorials:showTaskWindow(reqTable, true)
end

---Displays or hides task window
---@param reqTable TutorialStepRequirement[]
---@param hide ?boolean
---@param disableTaskReset ?boolean
function Tutorials:showTaskWindow(reqTable, hide, disableTaskReset)
	local req = TutorialsInternal.AddRequirement("taskwindowmove", reqTable)

	local spawnClock = UIElement.clock
	if (hide) then
		self.TaskViewHolder:addCustomDisplay(false, function()
				local targetShift = -self.TaskViewHolder.parent.size.w - self.TaskViewHolder.size.w
				if (self.TaskViewHolder.shift.x ~= targetShift) then
					self.TaskViewHolder:moveTo(UITween.SineTween(self.TaskViewHolder.shift.x, targetShift, UIElement.clock - spawnClock))
				else
					if (not disableTaskReset) then
						for _, v in pairs(self.TaskViewHolder.optional) do
							v.element:kill()
						end
						for _, v in pairs(self.TaskViewHolder.extra) do
							v.element:kill()
						end
						self.TaskViewHolder.optional = {}
						self.TaskViewHolder.extra = {}
					end
					self.TaskViewHolder:addCustomDisplay(false, function() end)
					req.ready = true
					reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
				end
			end)
	else
		if (not disableTaskReset) then
			self.TaskMark:hide(true)
		end
		self.TaskViewHolder:addCustomDisplay(false, function()
				local targetShift = -self.TaskViewHolder.parent.size.w - 10
				if (self.TaskViewHolder.shift.x ~= targetShift) then
					self.TaskViewHolder:moveTo(UITween.SineTween(self.TaskViewHolder.shift.x, targetShift, UIElement.clock - spawnClock))
				else
					self.TaskViewHolder:addCustomDisplay(false, function() end)
					req.ready = true
					reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
				end
			end)
	end
end

---Checks whether fail frame has been reached
---@param viewElement UIElement
---@param val integer
---@param steps TutorialStep[]
---@param currentStep integer
function Tutorials:checkFailFrame(viewElement, val, steps, currentStep)
	local fallback = steps[currentStep].fallback or 0
	viewElement:addChild({}):addCustomDisplay(true, function()
			if (self.WorldState.match_frame >= val) then
				viewElement:kill()
				self.MainView3D:kill(true)
				self:runSteps(steps, currentStep - fallback)
			end
		end)
end

---Checks whether proceed frame has been reached
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param val integer
---@param steps TutorialStep[]
---@param currentStep integer
function Tutorials:checkProceedFrame(viewElement, reqTable, val, steps, currentStep)
	reqTable.skip = reqTable.skip
	viewElement:addChild({}):addCustomDisplay(true, function()
			if (self.WorldState.match_frame >= val) then
				viewElement:kill()
				self.MainView3D:kill(true)
				self:runSteps(steps, currentStep + 1 + reqTable.skip)
			end
		end)
end

---Helper function to recursively set alpha for a UIElement and all its children
---@param element UIElement|UIElement3D
---@param alpha number
function TutorialsInternal.SetChildAlphaRecursive(element, alpha)
	element.bgColor[4] = alpha
	for _, v in pairs(element.child) do
		TutorialsInternal.SetChildAlphaRecursive(v, alpha)
	end
end

---Sets opacity for all player message head viewport elements
---@param alpha number
function Tutorials:setMessageViewportOpacity(alpha)
	if (self.MessageHeadViewport.child == nil or self.MessageHeadViewport.child[1] == nil) then
		return
	end
	for _, v in pairs(self.MessageHeadViewport.child[1].child) do
		TutorialsInternal.SetChildAlphaRecursive(v, alpha)
	end
end

---Shortcut function to hide player message window
---@param reqTable TutorialStepRequirement[]
function Tutorials:hideMessageWindow(reqTable)
	self:showMessageWindow(reqTable, true)
end

---Shows or hides player message window
---@param reqTable TutorialStepRequirement[]
---@param hide ?boolean
function Tutorials:showMessageWindow(reqTable, hide)
	local req = TutorialsInternal.AddRequirement("messagewindowmove", reqTable)

	local windowMover = self.MessageView:addChild({})
	local spawnClock = UIElement.clock
	if (hide) then
		windowMover:addCustomDisplay(true, function()
				local ratio = UIElement.clock - spawnClock
				self.MessageView:moveTo(UITween.SineTween(self.MessageView.shift.x, self.MessageView.parent.size.w, ratio))
				self:setMessageViewportOpacity(UITween.SineTween(1, 0, ratio * 1.5))

				if (ratio >= 1) then
					self.MessageHeadViewport.lastAuthor = nil
					self.MessageViewNameBG.bgColor = table.clone(self.MessageViewBG.hoverColor)
					self.MessageViewBG.shadowColor[2] = table.clone(self.MessageViewBG.hoverColor)
					self.MessageViewHolder:addCustomDisplay(false, function() end)
					self.MessageViewName:addCustomDisplay(false, function() end)
					self.MessageView:moveTo(self.MessageView.parent.size.w)
					windowMover:kill()
					req.ready = true
					reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
				end
			end)
	else
		windowMover:addCustomDisplay(true, function()
				local targetShift = self.MessageView.parent.size.w - self.MessageView.size.w
				local ratio = UIElement.clock - spawnClock
				self.MessageView:moveTo(UITween.SineTween(self.MessageView.shift.x, targetShift, ratio))
				self:setMessageViewportOpacity(UITween.SineTween(0, 1, ratio * 1.5))

				if (ratio >= 1) then
					windowMover:kill()
					req.ready = true
					reqTable.ready = TutorialsInternal.CheckRequirements(reqTable)
				end
			end)
	end
end

---Sets the hint or player message for current step
---@param message string
---@param author ?string
function Tutorials:setStepMessage(message, author)
	if (message) then
		self.CurrentStep.message = message
	end
	if (author) then
		self.CurrentStep.messageby = author
	end
end

---Internal function to handle game option changes which should also affect mobile hud
---@param option TutorialOption
function TutorialsInternal.HandleMobileOption(option)
	if (not is_mobile()) then return end

	if (option.name == "hud") then
		for _, button in pairs(TBHud.MiscButtonHolders) do
			button:setVisible(option.value == 1, true)
		end
		TBHud.CommitStepButtonHolder:setVisible(option.value == 1, true)
		TBHud.HoldAllButtonHolder:setVisible(option.value == 1, true)
	elseif (option.name == "holdall") then
		TBHud.HoldAllButtonHolder:setVisible(option.value == 1, true)
	elseif (option.name == "spacebar") then
		TBHud.CommitStepButtonHolder:setVisible(option.value == 1, true)
	end
end

---Main stepper function for the Tutorials manager
---@param steps TutorialStep[]
---@param currentStep ?integer
function Tutorials:runSteps(steps, currentStep)
	local currentStep = currentStep or 1
	local requirements = { ready = false, skip = 0 }
	self.CurrentStep = steps[currentStep]

	local stepElement = self.MainView:addChild({})
	if (TB_MENU_DEBUG) then
		local stepDisplay = stepElement:addChild({
			pos = { 5, -100 },
			size = { 60, 70 },
			uiColor = UICOLORBLACK
		})
		stepDisplay:addAdaptedText(true, 's' .. currentStep, nil, nil, FONTS.BIG, nil, 0.7, nil, 0.6)
	end
	stepElement:addChild({}):addCustomDisplay(true, function()
			if (requirements.ready) then
				local skip = steps[currentStep].skip
				if (requirements.skip) then
					skip = skip + requirements.skip
				end
				remove_hooks("tbTutorialsCustom")
				stepElement:kill()
				self.MainView3D:kill(true)
				if (not steps[currentStep].fallbackrequirement and steps[currentStep].fallback) then
					self:runSteps(steps, currentStep - steps[currentStep].fallback)
				elseif (currentStep + skip < #steps) then
					self:runSteps(steps, currentStep + 1 + skip)
				else
					self:showTutorialEnd()
				end
			end
		end)

	if (steps[currentStep].opts) then
		for _, v in pairs(steps[currentStep].opts) do
			local found = false
			for _, k in pairs(self.StoredOptions) do
				if (k.name == v.name) then
					found = true
				end
			end
			if (not found) then
				table.insert(self.StoredOptions, { name = v.name, value = get_option(v.name) })
			end
			set_option(v.name, v.value)
			TutorialsInternal.HandleMobileOption(v)
		end
	end
	if (steps[currentStep].progressstep) then
		self.ProgressStep = self.ProgressStep + 1
	end
	if (steps[currentStep].introOverlay) then
		self:introOverlay(stepElement, requirements)
	elseif (steps[currentStep].outroOverlay) then
		self:outroOverlay(stepElement, requirements)
	end
	if (steps[currentStep].newgame) then
		self:startNewGame(stepElement, requirements, steps[currentStep].mod)
	end
	if (steps[currentStep].replay) then
		self:loadReplay(stepElement, requirements, steps[currentStep].replay, steps[currentStep].cached)
	end
	if (steps[currentStep].editgame) then
		self:editGame()
	end
	if (steps[currentStep].loadplayers) then
		self:loadPlayer(steps[currentStep].loadplayers)
	end
	if (steps[currentStep].jointlock) then
		TUTORIALJOINTLOCK = true
		Tutorials.UnignoredJoints = {}
		TutorialsInternal.HandleMobileOption({ name = "holdall", value = 0 })
	end
	if (steps[currentStep].jointunlock) then
		TUTORIALJOINTLOCK = false
		for _, v in pairs(JOINTS) do
			table.insert(Tutorials.UnignoredJoints, v)
		end
	end
	if (steps[currentStep].keyboardlock) then
		TUTORIALKEYBOARDLOCK = true
		Tutorials.UnignoredKeys = {}
		TutorialsInternal.HandleMobileOption({ name = "holdall", value = 0 })
		TutorialsInternal.HandleMobileOption({ name = "spacebar", value = 0 })
	end
	if (steps[currentStep].playerlock) then
		disable_player_select(steps[currentStep].playerlock)
	else
		disable_player_select(-1)
	end
	if (steps[currentStep].showsaymessage) then
		self:showMessageWindow(requirements)
	elseif (steps[currentStep].hidesaymessage) then
		self:hideMessageWindow(requirements)
	end
	if (steps[currentStep].showwaitbtn) then
		self:showWaitButton()
	elseif (steps[currentStep].hidewaitbtn) then
		self:hideWaitButton()
	end
	if (steps[currentStep].showhintmessage) then
		self:showHintWindow(requirements)
	elseif (steps[currentStep].hidehintmessage) then
		self:hideHintWindow(requirements)
	end
	if (steps[currentStep].showtaskmessage) then
		self:showTaskWindow(requirements)
	elseif (steps[currentStep].hidetaskmessage) then
		self:hideTaskWindow(requirements)
	end
	if (steps[currentStep].taskoptcomplete) then
		self:taskOptComplete(steps[currentStep].taskoptcomplete)
	end
	if (steps[currentStep].shiftunlock) then
		table.insert(Tutorials.UnignoredKeys, { 303 })
		table.insert(Tutorials.UnignoredKeys, { 304 })
	end
	if (steps[currentStep].keyboardunlock) then
		if (steps[currentStep].keystounlock) then
			for i = 1, steps[currentStep].keystounlock:len() do
				local key = string.byte(steps[currentStep].keystounlock:sub(i, i))
				table.insert(Tutorials.UnignoredKeys, { key, (key > 96 and key < 123) and key - 93 or nil })
				if (key == 97) then
					table.insert(Tutorials.UnignoredKeys, { 276 })
				elseif (key == 119) then
					table.insert(Tutorials.UnignoredKeys, { 273 })
				elseif (key == 100) then
					table.insert(Tutorials.UnignoredKeys, { 275 })
				elseif (key == 115) then
					table.insert(Tutorials.UnignoredKeys, { 274 })
				end

				if (is_mobile()) then
					if (key == 99) then
						TutorialsInternal.HandleMobileOption({ name = "holdall", value = 1 })
					elseif (key == 32) then
						TutorialsInternal.HandleMobileOption({ name = "spacebar", value = 1 })
					end
				end
			end
		else
			TUTORIALKEYBOARDLOCK = false
		end
	end
	if (steps[currentStep].enablecamera) then
		enable_mouse_camera_movement()
	elseif (steps[currentStep].disablecamera) then
		disable_mouse_camera_movement()
	end
	if (steps[currentStep].cameramode) then
		set_camera_mode(steps[currentStep].cameramode)
	end

	for reqType, val in pairs(steps[currentStep]) do
		if (reqType == "damage") then
			self:reqDamage(stepElement, requirements, val)
		elseif (reqType == "damageopt") then
			self:reqDamage(stepElement, requirements, val, true)
		elseif (reqType == "dismember") then
			self:reqDismember(stepElement, requirements, val)
		elseif (reqType == "fracture") then
			self:reqFracture(stepElement, requirements, val)
		elseif (reqType == "ghostmode") then
			self:setGhostMode(val)
		elseif (reqType == "message") then
			local randomStart, randomEnd = utf8.find(val, "%%d%d+")
			if (randomStart) then
				local randomText = utf8.sub(val, randomStart, randomEnd)
				local randomNum = utf8.gsub(randomText, "%D", "") + 0
				val = utf8.gsub(val, "%%d%d+", math.random(1, randomNum))
			end
			if (steps[currentStep].messageby) then
				self:showMessage(stepElement, requirements, self.LocalizedMessages[val], steps[currentStep].messageby)
			else
				self:showHint(stepElement, requirements, self.LocalizedMessages[val])
			end
		elseif (reqType == "task") then
			self:showTask(stepElement, requirements, self.LocalizedMessages[val])
		elseif (reqType == "taskoptional") then
			for _, task in pairs(val) do
				self:addOptionalTask(task, self.LocalizedMessages[task.text])
			end
		elseif (reqType == "taskadditional") then
			for _, task in pairs(val) do
				self:addAdditionalTask(task, self.LocalizedMessages[task.text])
			end
		elseif (reqType == "marktaskcomplete") then
			self:taskComplete()
		elseif (reqType == "delay") then
			self:reqDelay(stepElement, requirements, val)
		elseif (reqType == "victory") then
			self:reqVictory(stepElement, requirements)
		elseif (reqType == "playframes") then
			self:playFrames(stepElement, requirements, val)
		elseif (reqType == "moveplayer") then
			self:moveJoints(val)
		elseif (reqType == "playsound") then
			self:playSound(val)
		elseif (reqType == "failframe") then
			self:checkFailFrame(stepElement, val, steps, currentStep)
		elseif (reqType == "proceedframe") then
			self:checkProceedFrame(stepElement, requirements, val, steps, currentStep)
		elseif (reqType == "movejoint") then
			for _, data in pairs(val) do
				self:reqJointMove(stepElement, requirements, data)
			end
		end
	end
	if (steps[currentStep].waitbtn) then
		self:reqButton(requirements)
	end
	if (steps[currentStep].customfuncfile ~= nil) then
		self:runTutorialCustomFunction(stepElement, requirements, steps[currentStep].customfuncfile, steps[currentStep].customfunc)
	end
end

---Updates Tutorials config file
---@param next ?boolean
---@return boolean
function TutorialsInternal.UpdateConfig(next)
	-- Steam achievements integration
	if (type(Tutorials.CurrentTutorial) == "number") then
		local level = get_tutorial_level()
		if (level < Tutorials.CurrentTutorial or Tutorials.CurrentTutorial > 4) then
			---@diagnostic disable-next-line: param-type-mismatch
			set_tutorial_level(Tutorials.CurrentTutorial)
		end
	end

	local tutorialsConfig = Files:open("../data/tutorials/config.cfg")
	if (not tutorialsConfig.data) then
		return false
	end

	---@type integer|string
	local nextTutId = 1
	for _, ln in pairs(tutorialsConfig:readAll()) do
		if (ln:find("^NEXT")) then
			nextTutId = ln:gsub("^NEXT ", "") + 0
			break
		end
	end
	if (Tutorials.CurrentTutorial >= nextTutId) then
		if (next) then
			nextTutId = Tutorials.CurrentTutorial + 1
		else
			nextTutId = Tutorials.CurrentTutorial
		end
	end

	tutorialsConfig:reopen(FILES_MODE_WRITE)
	tutorialsConfig:writeLine("NEXT " .. nextTutId)
	tutorialsConfig:writeLine("LAST " .. Tutorials.CurrentTutorial)
	tutorialsConfig:close()
	return true
end

---Connects to a beginner room with most players
function Tutorials:beginnerConnect()
	local players = RoomList.GetPlayers()

	local rooms = { "beginner%d", "public%d" }
	local roomsOnline = {}
	for _, online in pairs(players) do
		if (online.room:find(rooms[1]) or online.room:find(rooms[2])) then
			roomsOnline[online.room] = roomsOnline[online.room] or { players = 0 }
			roomsOnline[online.room].players = roomsOnline[online.room].players + 1
		end
	end
	for i, room in pairs(roomsOnline) do
		room.name = i
	end
	roomsOnline = table.qsort(roomsOnline, "players", true)
	self:quit()

	if (#roomsOnline > 0) then
		for _, room in pairs(roomsOnline) do
			if (room.players > 1 and room.players < 5) then
				runCmd("jo " .. room.name)
				close_menu()
				return
			end
		end
		runCmd("jo " .. roomsOnline[1].name)
	else
		runCmd("jo beginner1")
	end
	close_menu()
end

---@class TutorialSectionButton : MenuSectionButton
---@field shift number

---Displays Tutorial end screen
---@param buttonsCustom ?TutorialSectionButton[]
function Tutorials:showTutorialEnd(buttonsCustom)
	TUTORIAL_LEAVEGAME = true
	usage_event("tutorial" .. self.CurrentTutorial .. "complete")

	local buttons = {}
	local nextTutorial = Files:open("../data/tutorials/tutorial" .. (type(self.CurrentTutorial) == "number" and (self.CurrentTutorial + 1) or 'non-existing') .. ".dat")
	if (type(self.CurrentTutorial) == "number") then
		TutorialsInternal.UpdateConfig(nextTutorial.data ~= nil)
	end

	local scale = WIN_W > WIN_H * 2 and WIN_H or WIN_W / 7 * 6
	if (scale > 1024) then
		scale = 1024
	end
	local buttonHolder = self.MainView:addChild({
		shift = { (WIN_W - scale) / 2, (WIN_H - scale / 2.5) / 2 }
	})
	if (not buttonsCustom) then
		if (nextTutorial.data) then
			table.insert(buttons, {
				title = TB_MENU_LOCALIZED.TUTORIALSCONTINUETONEXT,
				size = 0.66,
				shift = 0,
				image = "../textures/menu/tutorial" .. self.CurrentTutorial + 1 .. ".tga",
				action = function() self:runTutorial(self.CurrentTutorial + 1, self.RequireCloseMenu) end
			})
		end
		table.insert(buttons, {
			title = TB_MENU_LOCALIZED.TUTORIALSBACKTOMAIN,
			size = #buttons == 0 and 0.66 or 0.33,
			shift = #buttons == 0 and buttonHolder.size.w * 0.17 + 20 or 0,
			image = #buttons == 0 and "../textures/menu/freeplay.tga" or "../textures/menu/multiplayer.tga",
			action = function() if (self.RequireCloseMenu) then close_menu() end self:quit() end
		})
	else
		buttons = buttonsCustom
	end
	nextTutorial:close()

	local maxWidthButton = { 0, 0 }
	for i, v in pairs(buttons) do
		if v.size > maxWidthButton[2] then
			maxWidthButton[2] = v.size
			maxWidthButton[1] = i
		end
	end
	local imageRes = buttonHolder.size.w * maxWidthButton[2] - 20
	local shift = 0
	for _, v in pairs(buttons) do
		local button = buttonHolder:addChild({
			pos = { shift + v.shift, 0 },
			size = { buttonHolder.size.w * v.size - 20, buttonHolder.size.h },
			bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
			interactive = true,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		shift = shift + button.size.w + 40

		--- Do we actually still need all this?
		button:deactivate()
		button.animateColor[4] = 0
		button:addCustomDisplay(false, function()
				if (button.animateColor[4] < 1) then
					button.animateColor[4] = button.animateColor[4] + 0.05
				else
					button:activate()
					button:addCustomDisplay(false, function() end)
					local imageSizeW, imageSizeH = button.size.w - 20, (imageRes - 20) / maxWidthButton[2] * v.size
					if (v.size >= 0.5) then
						imageSizeW, imageSizeH = (imageRes - 20) / maxWidthButton[2] * v.size, (imageRes - 20) / maxWidthButton[2] * v.size / 2
					end
					local buttonImage = UIElement:new({
						parent = button,
						pos = { 10, 10 },
						size = { imageSizeW, imageSizeH },
						bgColor = table.clone(button.bgColor),
						bgImage = v.image
					})
					buttonImage:addCustomDisplay(false, function()
						if (buttonImage.bgColor[4] > 0) then
							buttonImage.bgColor[4] = buttonImage.bgColor[4] - 0.1
							set_color(unpack(buttonImage.bgColor))
							draw_quad(buttonImage.pos.x, buttonImage.pos.y, buttonImage.size.w, buttonImage.size.h)
						else
							buttonImage:addCustomDisplay(false, function() end)
						end
					end)
				end
		end)
		button:addMouseUpHandler(v.action)
		local buttonText = button:addChild({
			pos = { 10, -button.size.h / 5 - 10 },
			size = { button.size.w - 20, button.size.h / 5 }
		})
		buttonText:addAdaptedText(true, v.title)
	end
end

---Sets discord RPC for the default tutorials
function TutorialsInternal.SetDiscordRPC()
	local currentTutorialname = nil
	if (Tutorials.CurrentTutorial == 1) then
		currentTutorialname = TB_MENU_LOCALIZED.TUTORIALSINTRONAME
	elseif (Tutorials.CurrentTutorial == 2) then
		currentTutorialname = TB_MENU_LOCALIZED.TUTORIALSPUNCHNAME
	elseif (Tutorials.CurrentTutorial == 3) then
		currentTutorialname = TB_MENU_LOCALIZED.TUTORIALSKICKNAME
	elseif (Tutorials.CurrentTutorial == 4) then
		currentTutorialname = TB_MENU_LOCALIZED.MAINMENUFIGHTUKENAME
	elseif (Tutorials.CurrentTutorial == 5) then
		currentTutorialname = TB_MENU_LOCALIZED.MAINMENUCOMEBACKNAME
	end
	set_discord_rpc(currentTutorialname, TB_MENU_LOCALIZED.DISCORDRPCINTUTORIAL)
end

---Generic function to run the tutorial \
---*This is also used by the Events manager*
---@param tutorialSteps TutorialStep[]
---@param postTutorial ?boolean
function Tutorials:runTutorialBase(tutorialSteps, postTutorial)
	TUTORIAL_ISACTIVE = true
	TUTORIAL_LEAVEGAME = true

	self.RequireCloseMenu = false
	self.TotalSteps = 0
	self.ProgressStep = 0

	TutorialsInternal.LoadHooks(self)

	start_new_game()
	chat_input_deactivate()
	if (is_mobile()) then
		TBHud.ChatButtonHolder:hide()
	end

	if (postTutorial) then
		open_menu(19)
		close_menu()
		TUTORIAL_LEAVEGAME = false
		self.RequireCloseMenu = true
	end

	self:runSteps(tutorialSteps)
end

---Runs the tutorial
---@param id number|string
---@param postTutorial ?boolean
function Tutorials:runTutorial(id, postTutorial)
	self:loadOverlay()
	local tutorialSteps = self:loadTutorial(id)
	if (not tutorialSteps) then
		return
	end

	if (not self:getLocalization(id)) then
		self:quit()
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.TUTORIALSNOLOCALIZATIONFOUND)
		return
	end

	TutorialsInternal.UpdateConfig()
	TutorialsInternal.SetDiscordRPC()
	usage_event("tutorial" .. id .. "begin")
	self:runTutorialBase(tutorialSteps, postTutorial)
end

---Exports globals that were available before Tutorials v5.60
---@param manager Tutorials
function TutorialsInternal.ExportLegacyGlobals(manager)
	_G.CURRENT_STEP = manager.CurrentStep
	_G.CURRENT_TUTORIAL = manager.CurrentTutorial
	_G.tbTutorialsTaskMark = manager.TaskMark
	_G.tbTutorialsTask = manager.TaskViewHolder
	_G.tbTutorialsOverlay = manager.StepOverlay
	_G.tbTutorialsContinueButton = manager.ContinueButton
	_G.tbTutorials3DHolder = manager.MainView3D
end

---@class TutorialsTaskView : UIElement
---@field optional TutorialTask[]
---@field extra TutorialTask[]

---Initializes all the main GUI elements used by Tutorials
function Tutorials:loadOverlay()
	local safe_x, safe_y, safe_w, safe_h = get_window_safe_size()
	safe_x = math.max(safe_x, WIN_W - safe_x - safe_w)
	safe_y = math.max(safe_y, WIN_H - safe_y - safe_h)

	if (self.MainView) then
		self.MainView:kill()
	end
	self.MainView = UIElement:new({
		globalid = self.Globalid,
		pos = { 0, 0 },
		size = { WIN_W, WIN_H }
	})
	self.MainView:addCustomDisplay(true, function()
			self.WorldState = get_world_state()
		end)

	if (self.MainView3D) then
		self.MainView3D:kill()
	end
	self.MainView3D = UIElement3D:new({
		globalid = self.Globalid,
		pos = { 1, 0, 0 },
		size = { 0, 0, 0 }
	})
	self.MainView3D:addCustomDisplay(false, function() end)

	---@diagnostic disable-next-line: assign-type-mismatch
	self.TaskViewHolder = self.MainView:addChild({
		pos = { -self.MainView.size.w - 400, 20 },
		size = { 400, 50 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	self.TaskViewHolder.optional = {}
	self.TaskViewHolder.extra = {}

	local tbTutorialsTaskMarkOutline = self.TaskViewHolder:addChild({
		pos = { 10, 10 },
		size = { 30, 30 },
		bgColor = { 1, 1, 1, 0.8 },
		shapeType = ROUNDED,
		rounded = 4
	})
	local tbTutorialsTaskMarkBackground = tbTutorialsTaskMarkOutline:addChild({
		shift = { 2, 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	}, true)
	self.TaskMark = tbTutorialsTaskMarkBackground:addChild({
		bgImage = "../textures/menu/general/buttons/checkmark.tga"
	})
	self.TaskMark:hide(true)
	self.TaskView = self.TaskViewHolder:addChild({
		pos = { 50, 5 },
		size = { self.TaskViewHolder.size.w - 55, self.TaskViewHolder.size.h - 10 }
	})

	---@diagnostic disable-next-line: assign-type-mismatch
	self.ContinueButton = self.MainView:addChild({
		pos = is_mobile() and { self.MainView.size.w - TBHud.DefaultButtonSize * 2.2, self.MainView.size.h - TBHud.DefaultButtonSize - TBHud.DefaultSmallerButtonSize * 0.5 } or { self.MainView.size.w - 100, self.MainView.size.h - 80 },
		size = is_mobile() and { TBHud.DefaultButtonSize, TBHud.DefaultButtonSize } or { 60, 60 },
		shapeType = ROUNDED,
		rounded = 100,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
		inactiveColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
		interactive = true,
		hoverSound = 31
	})
	local buttonPulse = self.ContinueButton:addChild({
		pos = { self.ContinueButton.size.w / 2, self.ContinueButton.size.h / 2 },
		size = { self.ContinueButton.size.w / 2, self.ContinueButton.size.h / 2 },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	local pulseClock = 0
	buttonPulse:addCustomDisplay(true, function()
			if (self.ContinueButton:isActive()) then
				if (pulseClock == 0) then
					pulseClock = UIElement.clock + 0.2
				end
				local pulseRatio = UITween.SineEaseOut(UIElement.clock - pulseClock)
				local r, g, b, a = unpack(buttonPulse.bgColor)
				set_color(r, g, b, a - pulseRatio)
				draw_disk(buttonPulse.pos.x, buttonPulse.pos.y, buttonPulse.size.w, buttonPulse.size.w * (1 + pulseRatio / 2), 50, 1, 0, 360, 0)
				if (pulseRatio == 1) then
					pulseClock = UIElement.clock + 0.2
				end
			else
				pulseClock = 0
			end
		end)
	self.ContinueButton:addChild({
		shift = { self.ContinueButton.size.w / 6, self.ContinueButton.size.w / 6 },
		bgImage = "../textures/menu/general/buttons/playpause.tga",
		imageAtlas = true,
		atlas = { x = 0, y = 0, w = 128, h = 128 }
	})

	self.HintView = self.MainView:addChild({
		pos = { 0, self.ContinueButton.shift.y - 15 },
		size = { self.MainView.size.w, self.MainView.size.h - self.ContinueButton.shift.y + 15 },
		bgColor = { 0, 0, 0, 0 }
	})
	if (not is_mobile()) then
		local messageViewShift = (self.HintView.size.w - self.ContinueButton.shift.x) * 1.5
		self.HintMessageView = self.HintView:addChild({
			pos = { messageViewShift, 5 },
			size = { self.HintView.size.w - messageViewShift * 2, self.HintView.size.h - math.max(10, safe_y) }
		})
	else
		---On mobile we show the hint on the left side to ensure TBHud buttons are fully visible
		local hintViewBG = self.HintView:addChild({
			pos = { 0, 0 },
			size = { self.HintView.size.w / 2, self.HintView.size.h },
			bgColor = self.HintView.bgColor
		})
		local hintViewGradient = hintViewBG:addChild({
			pos = { hintViewBG.size.w, 0 },
			size = { self.ContinueButton.shift.x - hintViewBG.size.w - 20, hintViewBG.size.h },
			bgGradient = { { 1, 1, 1, 1 }, { 1, 1, 1, 0 } },
			bgGradientMode = 15,
			imageColor = self.HintView.bgColor
		})
		self.HintMessageView = hintViewBG:addChild({
			pos = { math.max(safe_x, 20), 5 },
			size = { hintViewBG.size.w - math.max(safe_x, 20) * 2, hintViewBG.size.h - math.max(10, safe_y) }
		})
		self.HintView:addCustomDisplay(true, function() end)
	end

	self.MessageView = self.MainView:addChild({
		pos = { self.MainView.size.w, self.ContinueButton.shift.y - 120 },
		size = { self.MainView.size.w / 2 + safe_x, 100 },
		interactive = true
	})
	self.MessageView:addMouseUpHandler(function() self.MessageView.doSkip = true end)
	self.MessageViewNameBG = self.MessageView:addChild({
		parent = self.MessageView,
		pos = { self.MessageView.size.h / 2, -self.MessageView.size.h - 35 },
		size = { 196, 64 },
		shapeType = ROUNDED,
		rounded = 5,
		bgColor = { 0.852, 0.852, 0.852, 1 }
	})
	self.MessageViewNameBG:addCustomDisplay(false, function()
			set_color(unpack(self.MessageViewNameBG.bgColor))
			draw_quad(self.MessageViewNameBG.pos.x + self.MessageViewNameBG.size.w, self.MessageViewNameBG.pos.y + 5, 10, 59)
			draw_quad(self.MessageViewNameBG.pos.x + self.MessageViewNameBG.size.w + 10, self.MessageViewNameBG.pos.y + 8, 5, 56)
			draw_quad(self.MessageViewNameBG.pos.x + self.MessageViewNameBG.size.w + 15, self.MessageViewNameBG.pos.y + 10, 5, 54)
			draw_quad(self.MessageViewNameBG.pos.x + self.MessageViewNameBG.size.w + 20, self.MessageViewNameBG.pos.y + 15, 5, 49)
			draw_quad(self.MessageViewNameBG.pos.x + self.MessageViewNameBG.size.w + 25, self.MessageViewNameBG.pos.y + 22, 5, 42)
			draw_quad(self.MessageViewNameBG.pos.x + self.MessageViewNameBG.size.w + 30, self.MessageViewNameBG.pos.y + 35, 5, 34)
		end)
	local messageAuthorNameOverlay = self.MessageViewNameBG:addChild({
		size = { 256, 64 },
		bgImage = "../textures/menu/general/tutorial_speech_box_dotted.tga"
	})
	self.MessageViewName = messageAuthorNameOverlay:addChild({
		pos = { 10, 0 },
		size = { messageAuthorNameOverlay.size.w - 30, 34 }
	})
	self.MessageViewBG = self.MessageView:addChild({
		pos = { self.MessageView.size.h / 2, 0 },
		size = { self.MessageView.size.w - self.MessageView.size.h / 2, self.MessageView.size.h },
		bgColor = { 0.129, 0.129, 0.129, 1 },
		shapeType = ROUNDED,
		rounded = 10,
		innerShadow = { 0, 5 },
		shadowColor = { 0.852, 0.852, 0.852, 1 }
	})
	self.MessageViewBG.hoverColor = { 0.852, 0.852, 0.852, 1 }
	self.MessageViewHolder = self.MessageView:addChild({
		pos = { self.MessageView.size.h + 25, 10 },
		size = { self.MessageView.size.w - self.MessageView.size.h - 25 - math.max(20, safe_x), self.MessageView.size.h - 20 }
	})
	local playerHeadHolder = self.MessageView:addChild({
		pos = { 0, -self.MessageView.size.h - 5 },
		size = { self.MessageView.size.h + 10, self.MessageView.size.h + 10 },
		bgColor = { 0, 0, 0, 1 },
		shapeType = ROUNDED,
		rounded = self.MessageView.size.h
	})
	self.MessageHeadViewport = playerHeadHolder:addChild({
		shift = { 2, 2 },
		bgColor = { 0.129, 0.129, 0.129, 1 }
	}, true)

	---Make sure Continue button is on top of other elements
	self.ContinueButton:reload()
	self.ContinueButton:deactivate()

	if (self.TotalSteps > 0) then
		local tutorialProgress = self.MainView:addChild({
			pos = { 0, -5 },
			size = { self.MainView.size.w, 5 },
			bgColor = { 1, 1, 1, 0.5 }
		})
		local step = self.ProgressStep
		tutorialProgress:addCustomDisplay(false, function()
				if (step < self.ProgressStep) then
					step = step + 0.05
				end
				set_color(unpack(TB_MENU_DEFAULT_BG_COLOR))
				draw_quad(tutorialProgress.pos.x, tutorialProgress.pos.y, tutorialProgress.size.w / self.TotalSteps * step, tutorialProgress.size.h)
			end)
	end
end

---Returns default navigation buttons for main menu
---@return MenuNavButton[]
function Tutorials:getNavigationButtons()
	return {
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
			action = function()
					TBMenu:clearNavSection()
					TBMenu:showNavigationBar()
					TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
				end
		}
	}
end

---Returns list with all default tutorials
---@return table
function Tutorials:getAllTutorials()
	return {
		{
			id = 1,
			title = TB_MENU_LOCALIZED.TUTORIALSINTRONAME,
			subtitle = TB_MENU_LOCALIZED.TUTORIALSINTRODESC,
		},
		{
			id = 2,
			title = TB_MENU_LOCALIZED.TUTORIALSPUNCHNAME,
			subtitle = TB_MENU_LOCALIZED.TUTORIALSPUNCHDESC,
		},
		{
			id = 3,
			title = TB_MENU_LOCALIZED.TUTORIALSKICKNAME,
			subtitle = TB_MENU_LOCALIZED.TUTORIALSKICKDESC,
		},
		{
			id = 4,
			title = TB_MENU_LOCALIZED.TUTORIALSCHALLENGEUKENAME,
			subtitle = TB_MENU_LOCALIZED.TUTORIALSCHALLENGEUKEDESC,
		},
		{
			id = 5,
			title = TB_MENU_LOCALIZED.TUTORIALSCOMEBACKPRACTICENAME,
			subtitle = TB_MENU_LOCALIZED.TUTORIALSCOMEBACKPRACTICEDESC,
		}
	}
end

---Displays all tutorials menu
---@param featuredTutorial integer
function Tutorials:showAllTutorials(featuredTutorial)
	local tutorials = self:getAllTutorials()
	local size = 1 / math.ceil(#tutorials / 2)

	if (#tutorials % 2 == 1) then
		tutorials[featuredTutorial].size = size
		tutorials[featuredTutorial].mode = ORIENTATION_LANDSCAPE
		if (not tutorials[featuredTutorial].image) then
			tutorials[featuredTutorial].image = "../textures/menu/tutorial" .. featuredTutorial .. "_small.tga"
			tutorials[featuredTutorial].ratio = 1.055
		end
		if (featuredTutorial % 2 == 0) then
			local temp = table.clone(tutorials[featuredTutorial])
			tutorials[featuredTutorial] = table.clone(tutorials[featuredTutorial - 1])
			tutorials[featuredTutorial - 1] = temp
		end
	end
	for i, _ in pairs(tutorials) do
		if (not tutorials[i].size) then
			tutorials[i].vsize = 0.5
			tutorials[i].image = "../textures/menu/tutorial" .. tutorials[i].id .. ".tga"
			tutorials[i].size = size
			tutorials[i].ratio = 0.5
		end
		if (i > featuredTutorial and TB_MENU_PLAYER_INFO.data.qi < i * 250) then
			tutorials[i].locked = true
		end
		tutorials[i].action = function() self:runTutorial(tutorials[i].id) end
		tutorials[i].quit = true
	end
	TBMenu:showSection(tutorials, nil, TB_MENU_LOCALIZED.TUTORIALSLOCKED)
end

---Returns Tutorials config data
---@return integer #Next tutorial id
---@return integer #Last played tutorial id
function Tutorials:getConfig()
	local tutorialsConfig = Files:open("../data/tutorials/config.cfg")
	local nextTutorial, lastTutorial = 1, 1
	if (tutorialsConfig.data) then
		for _, ln in pairs(tutorialsConfig:readAll()) do
			if (ln:find("^LAST")) then
				lastTutorial = ln:gsub("^LAST ", "") + 0
			elseif (ln:find("^NEXT")) then
				nextTutorial = ln:gsub("^NEXT ", "") + 0
			end
		end
		tutorialsConfig:close()
	end
	return nextTutorial, lastTutorial
end

---Returns list of main tutorial buttons
---@return MenuSectionButton[]
function Tutorials:getMainMenuButtons()
	local tutorials = self:getAllTutorials()
	local nextTutorial, lastTutorial = self:getConfig()
	local allTutorialsNext = nextTutorial
	if (nextTutorial == 5 and lastTutorial >= 4) then
		nextTutorial = 4
		lastTutorial = 5
	elseif (lastTutorial == 1) then
		lastTutorial = nextTutorial
	end

	---@type MenuSectionButton
	local mainTutorialButton = {
		title = tutorials[nextTutorial].title,
		subtitle = tutorials[nextTutorial].subtitle,
		image = tutorials[nextTutorial].image or ("../textures/menu/tutorial" .. nextTutorial .. ".tga"),
		mode = ORIENTATION_LANDSCAPE,
		size = 0.47,
		ratio = 0.5,
		action = function() self:runTutorial(nextTutorial) end,
		quit = true,
		disableUnload = true
	}
	---@type MenuSectionButton
	local lastTutorialButton = {
		title = tutorials[lastTutorial].title,
		subtitle = tutorials[lastTutorial].subtitle,
		image = tutorials[lastTutorial].smallimage or ("../textures/menu/tutorial" .. lastTutorial .. "_small.tga"),
		mode = ORIENTATION_PORTRAIT,
		size = 0.235,
		ratio = 1.055,
		action = function() self:runTutorial(lastTutorial) end,
		quit = true,
		disableUnload = true
	}
	---@type MenuSectionButton
	local allTutorialsButton = {
		title = TB_MENU_LOCALIZED.TUTORIALSVIEWALLNAME,
		subtitle = TB_MENU_LOCALIZED.TUTORIALSVIEWALLDESC,
		image = "../textures/menu/tutorials_all_small.tga",
		mode = ORIENTATION_LANDSCAPE_SHORTER,
		size = 0.295,
		ratio = 0.819,
		action = function()
			TBMenu:clearNavSection()
			self:showAllTutorials(allTutorialsNext)
			TBMenu:showNavigationBar(self:getNavigationButtons(), true)
		end,
		disableUnload = true
	}

	if (lastTutorial ~= nextTutorial) then
		return {
			mainTutorialButton,
			lastTutorialButton,
			allTutorialsButton
		}
	else
		mainTutorialButton.size = 0.5
		allTutorialsButton.image = "../textures/menu/tutorials_all.tga"
		allTutorialsButton.mode = ORIENTATION_LANDSCAPE
		allTutorialsButton.size = 0.5
		allTutorialsButton.ratio = 0.5
		return {
			mainTutorialButton,
			allTutorialsButton
		}
	end
end

---Loads default Tutorials hooks
---@param manager Tutorials
function TutorialsInternal.LoadHooks(manager)
	add_hook("key_down", "tbTutorialKeyboardHandler", function(key, kcode)
			return Tutorials.HandleKeyPress(key, kcode, true, true)
		end)
	add_hook("key_up", "tbTutorialKeyboardHandler", function(key, kcode)
			if (key == 13) then
				if (manager.MessageView) then
					manager.MessageView.doSkip = true
				end
				if (manager.ContinueButton.isactive) then
					if (manager.ContinueButton.req.ready ~= nil) then
						manager.ContinueButton.req.ready = true
						manager.ContinueButton.reqTable.ready = TutorialsInternal.CheckRequirements(manager.ContinueButton.reqTable)
						manager.ContinueButton:deactivate()
					end
				end
			else
				return Tutorials.HandleKeyPress(key, kcode, true, true)
			end
		end)

	add_hook("draw2d", "tbTutorialsVisual", function()
			if (TB_MENU_MAIN_ISOPEN == 0) then
				UIElement:drawVisuals(manager.Globalid)
			end
		end)
	add_hook("draw3d", "tbTutorialsVisual", function()
			if (TB_MENU_MAIN_ISOPEN == 0) then
				UIElement3D:drawVisuals(manager.Globalid)
			end
		end)
	add_hook("draw_viewport", "tbTutorialsVisual", function()
			if (TB_MENU_MAIN_ISOPEN == 0) then
				UIElement3D:drawViewport(manager.Globalid)
			end
		end)

	add_hook("leave_game", "tbTutorialsVisual", function()
			if (not TUTORIAL_LEAVEGAME and TB_MENU_MAIN_ISOPEN == 0) then
				manager:quitPopup()
			end
		end)
	add_hook("console", "tbTutorialsVisual", function() return 1 end)
	add_hook("mouse_button_down", "tbTutorialKeyboardHandler", function()
			local ws = get_world_state()
			if (ws.selected_joint ~= -1) then
				return Tutorials.HandleJointSelect(ws.selected_player, ws.selected_joint)
			end
			return Tutorials.HandleBodySelect(ws.selected_player, ws.selected_body)
		end)
	add_hook("joint_select", "tbTutorialKeyboardHandler", Tutorials.HandleJointSelect)
	add_hook("body_select", "tbTutorialKeyboardHandler", Tutorials.HandleBodySelect)

	--- Reload tooltip so that
	Tooltip.Init()
end
