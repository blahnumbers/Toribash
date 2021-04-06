if (TBMenu == nil) then
	open_menu(19)
	close_menu()
end
require("toriui/uielement")
dofile("system/replays_manager.lua")
REPLAY_GUI = REPLAY_GUI or nil

local function replayGuiToggle(mode)
	local mode = mode and not mode or not REPLAY_GUI.hidden
	if (mode == REPLAY_GUI.hidden) then
		return
	end
	REPLAY_GUI.hidden = mode
	if (not REPLAY_GUI.hidden) then
		REPLAY_GUI:show()
	end
end

if (REPLAY_GUI == nil) then
	REPLAY_GUI = Replays:spawnReplayAdvancedGui()
else
	replayGuiToggle()
end
add_hook("new_game", "replay_advanced_gui", function() replayGuiToggle(false) end)
