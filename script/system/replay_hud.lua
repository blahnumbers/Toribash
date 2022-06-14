if (TBMenu == nil) then
	open_menu(19)
	close_menu()
end

require("toriui/uielement")
require("system/replays_manager")
REPLAY_GUI = REPLAY_GUI or nil

local function replayGuiToggle(mode)
	local targetMode = mode and not mode or not REPLAY_GUI.hidden
	if (targetMode == REPLAY_GUI.hidden) then
		return
	end
	REPLAY_GUI.hidden = targetMode
	if (mode == nil) then
		REPLAY_GUI.manualHidden = targetMode
	end
	if (not REPLAY_GUI.hidden) then
		REPLAY_GUI:show()
	end
end

if (REPLAY_GUI == nil) then
	REPLAY_GUI = Replays:spawnReplayAdvancedGui()
	REPLAY_GUI.doToggle = replayGuiToggle
else
	replayGuiToggle()
end

add_hook("new_game", "replay_advanced_gui", function() replayGuiToggle(false) end)
add_hook("pre_draw", "replay_advanced_gui", function()
	if (REPLAY_GUI.hidden and not REPLAY_GUI.manualHidden) then
		if (get_replay_cache() > 0) then
			local ws = get_world_state()
			if (ws.replay_mode == 1 and ws.game_type == 0) then
				replayGuiToggle(true)
			end
		end
	elseif (not REPLAY_GUI.hidden) then
		local w, h = get_window_size()
		if (REPLAY_GUI.spawnRes[1] ~= w or REPLAY_GUI.spawnRes[2] ~= h) then
			WIN_W, WIN_H = w, h
			Replays:spawnReplayAdvancedGui(true)
		end
	end
end)
