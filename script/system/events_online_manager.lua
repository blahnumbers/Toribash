-- Online events manager class
-- Inherits a lot of functionality from tutorials
dofile('tutorial/tutorial_manager.lua')

do
	if (not EventsOnline) then
		EventsOnline = {}
		EventsOnline.__index = EventsOnline
		setmetatable(EventsOnline, { __index = Tutorials })
		local cln = {}
		setmetatable(cln, EventsOnline)
		EventsOnline = cln
	end
	
	-- Tutorial class function overrides
	function EventsOnline:loadEvent(eventName)
		return EventsOnline:loadTutorial(eventName, "events/")
	end
	
	function EventsOnline:checkFiles(eventName)
		local event = Files:new("events/" .. eventName .. ".dat")
		if (not event.data) then
			return false
		end
		event:close()
		local eventscript = Files:new("events/" .. eventName .. ".lua")
		if (not eventscript.data) then
			return false
		end
		eventscript:close()
		local eventloc = Files:new("events/" .. eventName .. "_english.txt")
		if (not eventloc.data) then
			return false
		end
		eventloc:close()
		local eventmod = Files:new("../data/mod/system/events/" .. eventName .. ".tbm")
		if (not eventmod.data) then
			return false
		end
		eventmod:close()
		return true
	end
	
	function EventsOnline:playEvent(eventName)
		TUTORIAL_ISACTIVE = true
		TUTORIAL_LEAVEGAME = true
		
		if (get_world_state().game_type == 1) then
			start_new_game()
		end

		EventsOnline:loadHooks()
		-- reload leave_game hook separately to ensure new behavior
		add_hook("leave_game", "tbTutorialsVisual", function()
				if (not TUTORIAL_LEAVEGAME and TB_MENU_MAIN_ISOPEN == 0) then
					EventsOnline:quitPopup()
				end
			end)
		add_hook("key_down", "tbTutorialKeyboardHandler", function(key)
				if (not TB_MENU_INPUT_ISACTIVE) then
					return Tutorials:ignoreKeyPress(key, true, true)
				end
			end)
		add_hook("key_up", "tbTutorialKeyboardHandler", function(key)
				if (TB_MENU_INPUT_ISACTIVE) then
					return
				end
				if (key == 13) then
					if (tbTutorialsContinueButton.isactive) then
						if (tbTutorialsContinueButton.req.ready ~= nil) then
							tbTutorialsContinueButton.req.ready = true
							tbTutorialsContinueButton.reqTable.ready = Tutorials:checkRequirements(tbTutorialsContinueButton.reqTable)
							tbTutorialsContinueButton:deactivate()
						end
					end
				else
					return Tutorials:ignoreKeyPress(key, true, true)
				end
			end)
		EventsOnline:loadOverlay()

		chat_input_deactivate()

		LOCALIZED_MESSAGES = {}
		local eventSteps = EventsOnline:loadEvent(eventName)
		if (not eventSteps) then
			return
		end
		if (EventsOnline:getLocalization(LOCALIZED_MESSAGES, eventName, nil, "events/")) then
			EventsOnline:runSteps(eventSteps, nil, LOCALIZED_MESSAGES)
		end
	end
	
	function Tutorials:updateConfig()
		return 0
	end
	
	function EventsOnline:quitPopup()
		if (tutorialQuitOverlay) then
			tutorialQuitOverlay:kill()
			tutorialQuitOverlay = nil
			return
		end
		tutorialQuitOverlay = TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.EVENTSLEAVINGPROMPT, function() close_menu() UIElement:runCmd("savereplay --eventtmp" .. CURRENT_TUTORIAL) Tutorials:quit() end, function() close_menu() TUTORIAL_LEAVEGAME = false end, function() close_menu() Tutorials:quit() end, TB_MENU_LOCALIZED.BUTTONCONTINUENOSAVE, TB_TUTORIAL_MODERN_GLOBALID)
	end
end
