---Better Ghost by bleed
---Draws a ghost showing where each fighter will be when the current turn ends
---Original post: https://forum.toribash.com/showthread.php?t=672946
---
---@author bleed (original)
---@author surge (modifications)
---@author AssassinPro, niavic, barbarbar, LostMail (additional credits)

require("toriui.uielement")
require("toriui.uielement3d")

local vector3 = dofile("system/betterghost/b_utils/b_utils_vector3.lua")
local rotation = dofile("system/betterghost/b_utils/b_utils_rot.lua")

---@class BetterGhostPlayerShapes
---@field bodies table<PlayerBody, UIElement3D>
---@field joints table<PlayerJoint, UIElement3D>

---How the ghost cache stores a body part or an environment object
---@class BetterGhostCachedBody
---@field pos number[]
---@field quat number[]
---@field size number[]
---@field shape integer

---@class BetterGhostFutureGhost
local future_ghost = {}

local HOOK_SET = "__tbBetterGhostFuture"
local JOINT_COUNT = 20
local BODY_COUNT = 21
local MAX_DRAWN_PLAYERS = 2
local STATIC_FLAG = 8

-- A little bigger than the real parts so the two don't flicker through each other
local SIZE_MARGIN = 0.005

---The body part each joint moves with
---@type table<PlayerJoint, PlayerBody>
local JOINT_PARENTS = { [0] = 0, 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 15, 16, 18, 17 }

---Engine shape ids (as the ghost cache and `get_body_info()` give them) to toriui shapes
---@type table<integer, UIElement3DShape>
local SHAPES = { [0] = SPHERE, [1] = CUBE, [2] = CAPSULE }

---@type table<integer, BetterGhostPlayerShapes>
local player_shapes = {}

---Each joint's position relative to its body part, in the body part's own space
---@type table<integer, table<PlayerJoint, Vector3Base>>
local joint_offsets = {}

---@type UIElement3D[]
local environment_shapes = {}

---The object each environment shape follows
---@type integer[]
local environment_ids = {}

local is_visible = false

---@param count integer
---@return table<integer, UIElement3D>
local function create_shapes(count)
	local shapes = {}
	for i = 0, count - 1 do
		shapes[i] = UIElement3D:new({
			shapeType = SPHERE,
			size = { 0.2, 0.2, 0.2 },
			pos = { 1 + i, 1, 1 },
			bgColor = { 1, 0, 0, 1 },
			ignoreDepth = true,
		})
	end
	return shapes
end

---@param shapes table<integer, UIElement3D>
local function kill_shapes(shapes)
	for i, shape in pairs(shapes) do
		shape:kill(false)
		shapes[i] = nil
	end
end

---@param shapes table<integer, UIElement3D>
local function hide_shapes(shapes)
	for _, shape in pairs(shapes) do
		shape:hide(false)
	end
end

---@param shapes table<integer, UIElement3D>
local function show_shapes(shapes)
	for _, shape in pairs(shapes) do
		shape:show(true)
	end
end

---@param from number[]
---@param to number[]
---@param amount number
---@return number[]
local function lerp_array(from, to, amount)
	local result = {}
	for i = 1, #from do
		result[i] = from[i] + (to[i] - from[i]) * amount
	end
	return result
end

---Blended a component at a time like the classic ghost does, then scaled back to a unit rotation
---@param from number[]
---@param to number[]
---@param amount number
---@return number[]
local function lerp_quaternion(from, to, amount)
	local result = lerp_array(from, to, amount)
	local length = math.sqrt(result[1] * result[1] + result[2] * result[2] + result[3] * result[3] + result[4] * result[4])
	if length > 0 then
		for i = 1, 4 do
			result[i] = result[i] / length
		end
	end
	return result
end

---@param from BetterGhostCachedBody[]
---@param to BetterGhostCachedBody[]
---@param amount number
---@return BetterGhostCachedBody[]
local function lerp_bodies(from, to, amount)
	local result = {}
	for i, body in ipairs(from) do
		local next_body = to[i]
		if next_body then
			result[i] = {
				pos = lerp_array(body.pos, next_body.pos, amount),
				quat = body.quat and lerp_quaternion(body.quat, next_body.quat, amount),
				size = body.size,
				shape = body.shape,
			}
		else
			result[i] = body
		end
	end
	return result
end

---The ghost cache at `frame`, blended with the next frame when it's partway between two
---@param frame number
---@return PlayerGhostCache[]|GhostFrameCache
local function get_cache_at(frame)
	local whole_frame = math.floor(frame)
	local amount = frame - whole_frame
	local cache = get_ghost_cache(whole_frame)
	if amount == 0 then
		return cache
	end

	local next_cache = get_ghost_cache(whole_frame + 1)
	local result = { envs = lerp_bodies(cache.envs, next_cache.envs, amount) }
	for player = 1, get_world_state().num_players do
		result[player] = {
			bodies = lerp_bodies(cache[player].bodies, next_cache[player].bodies, amount),
			joints = lerp_bodies(cache[player].joints, next_cache[player].joints, amount),
		}
	end
	return result
end

---@param shape UIElement3D
---@param cached BetterGhostCachedBody
local function place_shape(shape, cached)
	local position = vector3.from_array(cached.pos)
	local angles = rotation.to_euler_degrees(rotation.from_array(cached.quat))
	shape:moveTo(position.x, position.y, position.z, true)
	shape:resetRotation()
	shape:rotate(angles.x, angles.y, angles.z)
end

---@param player integer
---@param cache PlayerGhostCache
---@param colour Color
local function draw_player(player, cache, colour)
	local shapes = player_shapes[player]

	for joint = 0, JOINT_COUNT - 1 do
		local parent_rotation = rotation.from_array(cache.bodies[JOINT_PARENTS[joint] + 1].quat)
		local offset = vector3.rotate_by_inverse(rotation.invert(parent_rotation), joint_offsets[player][joint])
		local position = vector3.add(vector3.from_array(cache.joints[joint + 1].pos), offset)

		local shape = shapes.joints[joint]
		shape:moveTo(position.x, position.y, position.z, true)
		shape.size = { x = get_joint_radius(player, joint) + SIZE_MARGIN, y = 1, z = 1 }
		shape.bgColor = colour
	end

	for body = 0, BODY_COUNT - 1 do
		local body_info = get_body_info(player, body)
		local shape = shapes.bodies[body]
		place_shape(shape, cache.bodies[body + 1])
		shape.size = vector3.add_to_each(body_info.sides, SIZE_MARGIN)
		shape.shapeType = SHAPES[body_info.shape]
		shape.bgColor = colour
	end
end

---@param cache BetterGhostCachedBody[]
---@param get_object_colour fun(object_id: integer): Color
local function draw_environment(cache, get_object_colour)
	if #cache == 0 then
		return
	end

	for i, shape in ipairs(environment_shapes) do
		local object_id = environment_ids[i]
		local object = cache[object_id + 1]
		if object == nil then
			return -- The mod changed and the new match hasn't rebuilt the shapes yet
		end

		place_shape(shape, object)
		shape.size = vector3.add_to_each(vector3.from_array(object.size), SIZE_MARGIN)
		shape.shapeType = SHAPES[object.shape] or object.shape
		shape.bgColor = get_object_colour(object_id)
	end
end

---One shape for each environment object that can move
local function create_environment_shapes()
	kill_shapes(environment_shapes)
	environment_shapes = {}
	environment_ids = {}

	local cache = get_ghost_cache(1).envs
	for object_id = 0, #cache - 1 do
		local flag = get_obj_flag(object_id)
		local is_static = flag == nil or math.floor(flag / STATIC_FLAG) % 2 == 1
		if not is_static then
			local shape = UIElement3D:new({ shapeType = SPHERE, pos = { 0, 0, 0 }, size = { 0.1, 0.1, 0.1 }, ignoreDepth = true })
			table.insert(environment_shapes, shape)
			table.insert(environment_ids, object_id)
		end
	end
end

---@param player integer
---@return table<PlayerJoint, Vector3Base>
local function get_joint_offsets(player)
	local offsets = {}
	for joint = 0, JOINT_COUNT - 1 do
		local parent = get_body_info(player, JOINT_PARENTS[joint])
		local offset = vector3.subtract(get_joint_pos2(player, joint), parent.pos)
		offsets[joint] = vector3.rotate_by_inverse(rotation.from_matrix(parent.rot), offset)
	end
	return offsets
end

local function on_match_begin()
	create_environment_shapes()
	for player = 0, get_world_state().num_players - 1 do
		joint_offsets[player] = get_joint_offsets(player)
	end

	if is_visible then
		future_ghost.show()
	else
		future_ghost.hide()
	end
end

function future_ghost.show()
	is_visible = true
	local player_count = get_world_state().num_players
	for player, shapes in pairs(player_shapes) do
		if player < player_count then
			show_shapes(shapes.bodies)
			show_shapes(shapes.joints)
		else
			hide_shapes(shapes.bodies)
			hide_shapes(shapes.joints)
		end
	end
	show_shapes(environment_shapes)
end

function future_ghost.hide()
	is_visible = false
	for _, shapes in pairs(player_shapes) do
		hide_shapes(shapes.bodies)
		hide_shapes(shapes.joints)
	end
	hide_shapes(environment_shapes)
end

---Removes the shapes and hooks for good
function future_ghost.kill()
	for _, shapes in pairs(player_shapes) do
		kill_shapes(shapes.bodies)
		kill_shapes(shapes.joints)
	end
	kill_shapes(environment_shapes)
	remove_hooks(HOOK_SET)
end

---Puts the ghost where the ghost cache has everything at `frame`, which can be partway between two frames
---@param frame number
---@param player_colours table<integer, Color> An alpha of 0 hides that player
---@param get_object_colour fun(object_id: integer): Color
function future_ghost.draw_at_frame(frame, player_colours, get_object_colour)
	local cache = get_cache_at(frame)
	for player = 0, math.min(get_world_state().num_players, MAX_DRAWN_PLAYERS) - 1 do
		draw_player(player, cache[player + 1], player_colours[player])
	end
	draw_environment(cache.envs, get_object_colour)
end

for player = 0, MAX_DRAWN_PLAYERS - 1 do
	local joints = create_shapes(JOINT_COUNT)
	local bodies = create_shapes(BODY_COUNT)
	player_shapes[player] = { joints = joints, bodies = bodies }
end
on_match_begin()

remove_hooks(HOOK_SET)
add_hook("match_begin", HOOK_SET, on_match_begin)
add_hook("new_game", HOOK_SET, on_match_begin)

return future_ghost
