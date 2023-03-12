if (TBMenu == nil) then
	open_menu(19)
	close_menu()
end

require("toriui.uielement")
if (is_mobile()) then
	require("system.hud_manager")
end
require("system.replays_manager")

---@type UIElement
REPLAY_GUI = REPLAY_GUI or nil

local function replayGuiToggle(mode)
	local targetMode = mode ~= nil and not mode or not REPLAY_GUI.hidden
	if (targetMode == REPLAY_GUI.hidden) then
		return
	end
	REPLAY_GUI.hidden = targetMode
	REPLAY_GUI.toggleClock = os.clock_real()
	if (mode == nil) then
		REPLAY_GUI.manualHidden = targetMode
	end
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
add_hook("pre_draw", "replay_advanced_gui", function()
	if (REPLAY_GUI.hidden and not REPLAY_GUI.manualHidden and not TUTORIAL_ISACTIVE) then
		local ws = get_world_state()
		if (ws.replay_mode > 0 and ws.game_type == 0) then
			replayGuiToggle(true)
		end
	end
end)
add_hook("resolution_changed", "replay_advanced_gui", function()
	Replays:spawnReplayAdvancedGui(true)
end)
