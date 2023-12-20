if (TBMenu == nil) then
	open_menu(19)
	close_menu()
end

require("system.replays_manager")


if (Replays.GameHud == nil) then
	Replays:spawnReplayAdvancedGui()
else
	Replays:toggleHud()
end

add_hook("new_game", "replay_advanced_gui", function() Replays:toggleHud(false) end)
add_hook("pre_draw", "replay_advanced_gui", function()
	local hud = get_option('hud')
	if (Replays.GameHud.hidden and not Replays.GameHud.manualHidden and not TUTORIAL_ISACTIVE) then
		local ws = get_world_state()
		if (ws.replay_mode > 0 and ws.game_type == 0 and (not is_mobile() or hud == 1)) then
			Replays:toggleHud(true)
		end
	elseif (not Replays.GameHud.hidden and is_mobile() and hud == 0) then
		local ws = get_world_state()
		if (ws.replay_mode > 0) then
			Replays:toggleHud(false)
		end
	end
end)
add_hook("resolution_changed", "replay_advanced_gui", function()
	Replays:spawnReplayAdvancedGui(true)
end)
