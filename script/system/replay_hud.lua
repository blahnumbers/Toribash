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

add_hook("new_game", Replays.HookNameUI, function()
	set_hint_override()
	Replays:toggleHud(false)
	if (Replays.GameHud ~= nil) then
		Replays.GameHud.queue = nil
		Replays.GameHud.currentQueueIndex = 0
	end
end)
add_hook("new_mp_game", Replays.HookNameUI, function() set_hint_override() end)
add_hook("new_game_mp", Replays.HookNameUI, function() set_hint_override() end)
add_hook("pre_draw", Replays.HookNameUI, function()
	local hud = get_option('hud')
	if (Replays.GameHud.hidden and not Replays.GameHud.manualHidden and not TUTORIAL_ISACTIVE) then
		if (UIElement.WorldState.replay_mode > 0 and UIElement.WorldState.game_type == 0 and (not is_mobile() or hud == 1)) then
			Replays:toggleHud(true)
		end
	elseif (not Replays.GameHud.hidden and is_mobile() and hud == 0) then
		if (UIElement.WorldState.replay_mode > 0) then
			Replays:toggleHud(false)
		end
	end
end)
add_hook("resolution_changed", Replays.HookNameUI, function()
	Replays:spawnReplayAdvancedGui(true)
end)
add_hook("key_up", Replays.HookNameUI, function(key, code)
	---Override default replay navigation to ensure hotkeys work same way UI buttons do
	if (get_keyboard_ctrl() ~= 0 and UIElement.WorldState.game_type == 0 and Replays.GameHud ~= nil) then
		if (key == 93 or key == 125 or code == 48) then
			Replays.GameHud.PlayQueue(1)
			return 1
		end
		if (key == 91 or key == 123 or code == 47) then
			Replays.GameHud.PlayQueue(-1)
			return 1
		end
	end
end)
