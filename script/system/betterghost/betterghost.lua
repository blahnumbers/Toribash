---Better Ghost by bleed
---Draws a ghost showing where each fighter will be when the current turn ends
---Original post: https://forum.toribash.com/showthread.php?t=672946
---
---@author bleed (original)
---@author surge (modifications)
---@author AssassinPro, niavic, barbarbar, LostMail (additional credits)

---What the ghoststyle (your fighter) and ghoststyleopponent options show
---@alias GhostStyle
---| 0 # Classic ghost only
---| 1 # End of turn ghost only
---| 2 # Classic and end of turn ghosts

---Kept between main menu reloads so each load can clean up the one before it
---@class BetterGhostSystem
---@field unload fun()?
BetterGhost = BetterGhost or {}

if BetterGhost.unload then
	BetterGhost.unload()
end

local future_ghost = dofile("system/betterghost/b_ghost/future_ghost.lua")
local colour = dofile("system/betterghost/b_utils/b_utils_colour.lua")

local HOOK_SET = "__tbBetterGhost"

---@type GhostStyle
local STYLE_CLASSIC = 0
---@type GhostStyle
local STYLE_END_OF_TURN = 1
---@type GhostStyle
local STYLE_BOTH = 2

---@type GhostMode
local GHOST_SELECTED = 1
---@type GhostMode
local GHOST_BOTH = 2

local AUTOMATIC_COLOUR = 0
local MOVEMENT_MOVING = 1

---@type Color
local HIDDEN = { 0, 0, 0, 0 }

local is_shown = false

---How much of the ghost is left as it fades out with the classic ghost, only ever below 1 while it moves
local fade = 1

---The match frame the ghost cache last held the drawn frame on
---@type integer?
local ready_match_frame

---Read every frame, so turn frames changed mid game, or a mod's turn frames that change each turn, are followed,
---and a ghost shorter than the turn stops at its last frame
---@return integer
local function get_turn_end_frame()
	return math.min(get_world_state().match_turn_frame, get_ghost_length() - 1)
end

---The turn end, or with the ghostmovement option on, wherever the classic ghost is until it gets there,
---fading out with the classic ghost so it doesn't jump back to the start of the turn
---@return number frame
---@return number fade
---@return integer last_cached_frame
local function get_drawn_frame()
	local turn_end_frame = get_turn_end_frame()
	local classic_frame, classic_fade, last_cached_frame = get_ghost_frame()
	if get_option("ghostmovement") ~= MOVEMENT_MOVING then
		return turn_end_frame, 1, last_cached_frame
	end
	return math.min(classic_frame, turn_end_frame), classic_fade, last_cached_frame
end

---The engine rebuilds the ghost cache a frame at a time after each turn and joint change, and until it
---gets to `frame` that slot still holds an older ghost. One from earlier this turn is fine to keep
---showing until the new one is ready, but one from an earlier turn mustn't show at all
---@param frame number
---@param last_cached_frame integer
---@return boolean
local function is_frame_ready(frame, last_cached_frame)
	local match_frame = get_world_state().match_frame
	if last_cached_frame >= math.ceil(frame) then
		ready_match_frame = match_frame
		return true
	end
	return ready_match_frame == match_frame
end

---@return number
local function get_opacity()
	return get_option("ghostopacity") / 100 * fade
end

---Your fighter's ghost follows your ghost settings, and everyone else's follows the opponent's
---@param player integer
---@return GhostStyle
local function get_style(player)
	return get_option(is_own_ghost(player) and "ghoststyle" or "ghoststyleopponent")
end

---@param player integer
---@return integer
local function get_picked_colour(player)
	return get_option(is_own_ghost(player) and "ghostcolor" or "ghostcoloropponent")
end

---The ghost mode has to be showing them, and their ghost style has to include the end of turn ghost
---@param player integer
---@return boolean
local function is_player_shown(player)
	local ghost_mode = get_ghost()
	local is_in_ghost_mode = ghost_mode == GHOST_BOTH
		or (ghost_mode == GHOST_SELECTED and player == get_world_state().selected_player)
	return is_in_ghost_mode and get_style(player) ~= STYLE_CLASSIC
end

---@return boolean
local function should_show()
	for player = 0, get_world_state().num_players - 1 do
		if is_player_shown(player) then
			return true
		end
	end
	return false
end

---Sets the opacity, and swaps to a contrasting colour when asked, so it can't be mixed up with the classic ghost
---@param rgba Color
---@param is_contrasting boolean
---@return Color
local function get_ghost_colour(rgba, is_contrasting)
	local result = is_contrasting and colour.get_contrasting(rgba) or { rgba[1], rgba[2], rgba[3] }
	result[4] = (rgba[4] or 1) * get_opacity()
	return result
end

---Each player's ghost colour like the classic ghost, contrasting when they show both ghosts, or the colour
---picked in the settings, with anyone not shown hidden
---@return table<integer, Color>
local function get_player_colours()
	local colours = {}
	for player = 0, get_world_state().num_players - 1 do
		local picked = get_picked_colour(player)
		if not is_player_shown(player) then
			colours[player] = HIDDEN
		elseif picked ~= AUTOMATIC_COLOUR then
			colours[player] = get_color_rgba(picked)
			colours[player][4] = get_opacity()
		else
			colours[player] = get_ghost_colour(get_color_rgba(get_ghost_color(player)), get_style(player) == STYLE_BOTH)
		end
	end
	return colours
end

---Objects keep their own colour like on the classic ghost, contrasting while the classic ghost's objects show
---too, and hide when the ghostenvobj option is off
---@param object_id integer
---@return Color
local function get_object_colour(object_id)
	if get_option("ghostenvobj") == 0 then
		return HIDDEN
	end
	local has_classic_objects = get_option("ghoststyle") ~= STYLE_END_OF_TURN
		or get_option("ghoststyleopponent") ~= STYLE_END_OF_TURN
	return get_ghost_colour(get_obj_color(object_id), has_classic_objects)
end

local function on_camera()
	local frame, frame_fade, last_cached_frame = get_drawn_frame()
	local should_be_shown = should_show() and is_frame_ready(frame, last_cached_frame)
	if should_be_shown ~= is_shown then
		is_shown = should_be_shown
		if is_shown then
			future_ghost.show()
		else
			future_ghost.hide()
		end
	end

	if is_shown then
		fade = frame_fade
		future_ghost.draw_at_frame(frame, get_player_colours(), get_object_colour)
	end
end

---A new game starts back at match frame 0, where the last game's ghost could otherwise pass as ready
local function on_new_game()
	ready_match_frame = nil
end

function BetterGhost.unload()
	future_ghost.kill()
	remove_hooks(HOOK_SET)
end

remove_hooks(HOOK_SET)
add_hook("camera", HOOK_SET, on_camera)
add_hook("new_game", HOOK_SET, on_new_game)
