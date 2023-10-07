require('system.tutorial_manager')

if (EventsOnline == nil) then
	---Manager class for in-game events, based on **Tutorials** class.
	---@class EventsOnline : Tutorials
	EventsOnline = {
		ver = Tutorials.ver,
		__index = Tutorials
	}
	setmetatable(EventsOnline, Tutorials)
end

---Loads an event located in `data/script/events` directory
---@param eventName string
---@return TutorialStep[]?
function EventsOnline:loadEvent(eventName)
	return Tutorials:loadTutorial(eventName, "events/")
end

---Runs a check whether all event files are present
---@param eventName string
---@param requireMod ?boolean
---@return boolean
function EventsOnline:checkFiles(eventName, requireMod)
	local event = Files.Open("events/" .. eventName .. ".dat")
	if (not event.data) then
		return false
	end
	event:close()
	local eventscript = Files.Open("events/" .. eventName .. ".lua")
	if (not eventscript.data) then
		return false
	end
	eventscript:close()
	local eventloc = Files.Open("events/" .. eventName .. "_english.txt")
	if (not eventloc.data) then
		return false
	end
	eventloc:close()
	if (requireMod) then
		local eventmod = Files.Open("../data/mod/system/events/" .. eventName .. ".tbm")
		if (not eventmod.data) then
			return false
		end
		eventmod:close()
	end
	return true
end

---Runs an event with the specified name
---@param eventName string
function EventsOnline:playEvent(eventName)
	Tutorials:setQuitPopupOverride(EventsOnline.QuitPopup)
	Tutorials:loadOverlay()
	local eventSteps = self:loadEvent(eventName)
	if (not eventSteps) then
		return
	end

	if (not Tutorials:getLocalization(eventName, get_language(), "events/")) then
		Tutorials:quit()
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.TUTORIALSNOLOCALIZATIONFOUND)
		return
	end

	usage_event("event" .. eventName .. "begin")
	Tutorials:runTutorialBase(eventSteps)
end

---Quit popup override for Events interface
function EventsOnline.QuitPopup()
	if (Tutorials.QuitOverlay) then
		Tutorials.QuitOverlay:kill()
		Tutorials.QuitOverlay = nil
		return
	end
	Tutorials.QuitOverlay = TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.EVENTSLEAVINGPROMPT,
		function()
			close_menu()
			runCmd("savereplay --eventtmp" .. Tutorials.CurrentTutorial)
			Tutorials:quit()
		end,
		function()
			close_menu()
			TUTORIAL_LEAVEGAME = false
		end,
		function()
			close_menu()
			Tutorials:quit()
		end,
		TB_MENU_LOCALIZED.BUTTONCONTINUENOSAVE,
		Tutorials.Globalid)
end
