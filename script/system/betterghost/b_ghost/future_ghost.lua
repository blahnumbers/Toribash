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
---@field body_count integer
---@field joint_count integer

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

---The body part each joint moves with, for each fighter
---@type table<integer, table<PlayerJoint, PlayerBody>>
local joint_parents = {}

---@type UIElement3D[]
local environment_shapes = {}

---The object each environment shape follows
---@type integer[]
local environment_ids = {}

local is_visible = false

---How many joints and body parts a fighter has: the classic ones plus a mod's extra limbs
---@param player integer
---@return integer joint_count
---@return integer body_count
local function get_part_counts(player)
	if get_num_joints == nil or player >= get_world_state().num_players then
		return JOINT_COUNT, BODY_COUNT
	end
	return get_num_joints(player), get_num_bodies(player)
end

---The body part each joint of a fighter moves with, as the engine picks it: a classic joint keeps its classic
---part while it still connects it (a mod can re-wire it), any other joint goes with the second part it connects
---@param player integer
---@return table<PlayerJoint, PlayerBody>
local function get_joint_parents(player)
	if get_joint_bodies == nil then
		return JOINT_PARENTS
	end
	local parents = {}
	for joint = 0, get_part_counts(player) - 1 do
		local body1, body2 = get_joint_bodies(player, joint)
		local classic = JOINT_PARENTS[joint]
		parents[joint] = (classic == body1 or classic == body2) and classic or body2
	end
	return parents
end

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
	-- pairs: the objects' keys can have gaps (see create_environment_shapes)
	for i, body in pairs(from) do
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

---Drawn for parts the cache doesn't hold
---@type Color
local NO_COLOUR = { 0, 0, 0, 0 }

---Sets a shape's size only when it changed: the sizes stay the same all match, and a new table each redraw adds up
---@param shape UIElement3D
---@param x number
---@param y number
---@param z number
local function set_size(shape, x, y, z)
	local size = shape.size
	if size.x ~= x or size.y ~= y or size.z ~= z then
		shape.size = { x = x, y = y, z = z }
	end
end

---Places a shape where the cache has a body part or an object. The rotation goes straight from the cache's
---quaternion to the matrix the shape is drawn with (as the engine turns a body's quaternion into its rotation), in a
---table the shape keeps: going through Euler angles and UIElement3D:resetRotation() and rotate() came to the same
---matrix (within 1e-6) at several times the cost, which made each redraw take milliseconds
---@param shape UIElement3D
---@param cached BetterGhostCachedBody
local function place_shape(shape, cached)
	local pos = cached.pos
	shape:moveTo(pos[1], pos[2], pos[3], true)

	local q = cached.quat
	local w, x, y, z = q[1], q[2], q[3], q[4]
	local xx, yy, zz = 2 * x * x, 2 * y * y, 2 * z * z
	local matrix = shape.betterGhostRotation
	if matrix == nil then
		matrix = { r3 = 0, r7 = 0, r11 = 0 }
		shape.betterGhostRotation = matrix
	end
	matrix.r0, matrix.r1, matrix.r2 = 1 - yy - zz, 2 * (x * y - w * z), 2 * (x * z + w * y)
	matrix.r4, matrix.r5, matrix.r6 = 2 * (x * y + w * z), 1 - xx - zz, 2 * (y * z - w * x)
	matrix.r8, matrix.r9, matrix.r10 = 2 * (x * z - w * y), 2 * (y * z + w * x), 1 - xx - yy
	shape.rotMatrixTB = matrix
end

---@param player integer
---@param cache PlayerGhostCache
---@param colour Color
local function draw_player(player, cache, colour)
	local shapes = player_shapes[player]

	-- Only what the cache holds (an older engine's cache has the classic parts only)
	local joint_count = math.min(shapes.joint_count, #cache.joints)
	local body_count = math.min(shapes.body_count, #cache.bodies)
	for i = joint_count, shapes.joint_count - 1 do
		shapes.joints[i].bgColor = NO_COLOUR
	end
	for i = body_count, shapes.body_count - 1 do
		shapes.bodies[i].bgColor = NO_COLOUR
	end

	local parents = joint_parents[player]
	local offsets = joint_offsets[player]
	local bodies, joints = cache.bodies, cache.joints
	for joint = 0, joint_count - 1 do
		-- The joint's offset from its body part, turned with the part: rotation.invert() and
		-- vector3.rotate_by_inverse() written out, the same sums without the tables
		local q = bodies[parents[joint] + 1].quat
		local length_squared = q[1] * q[1] + q[2] * q[2] + q[3] * q[3] + q[4] * q[4]
		local w, x, y, z = q[1] / length_squared, -q[2] / length_squared, -q[3] / length_squared, -q[4] / length_squared
		local offset = offsets[joint]
		local ox, oy, oz = offset.x, offset.y, offset.z
		local pos = joints[joint + 1].pos

		local shape = shapes.joints[joint]
		shape:moveTo(
			pos[1] + (ox * (1 - 2 * y * y - 2 * z * z) + oy * 2 * (x * y + w * z) + oz * 2 * (x * z - w * y)),
			pos[2] + (ox * 2 * (x * y - w * z) + oy * (1 - 2 * x * x - 2 * z * z) + oz * 2 * (y * z + w * x)),
			pos[3] + (ox * 2 * (x * z + w * y) + oy * 2 * (y * z - w * x) + oz * (1 - 2 * x * x - 2 * y * y)),
			true)
		set_size(shape, get_joint_radius(player, joint) + SIZE_MARGIN, 1, 1)
		shape.bgColor = colour
	end

	-- The cache has each part's size and shape too, the same as get_body_info() gives
	for body = 0, body_count - 1 do
		local cached = bodies[body + 1]
		local shape = shapes.bodies[body]
		place_shape(shape, cached)
		local size = cached.size
		set_size(shape, size[1] + SIZE_MARGIN, size[2] + SIZE_MARGIN, size[3] + SIZE_MARGIN)
		shape.shapeType = SHAPES[cached.shape]
		shape.bgColor = colour
	end
end

---@param cache BetterGhostCachedBody[]
---@param get_object_colour fun(object_id: integer): Color
local function draw_environment(cache, get_object_colour)
	if next(cache) == nil then
		return
	end

	for i, shape in ipairs(environment_shapes) do
		local object_id = environment_ids[i]
		local object = cache[object_id + 1]
		if object == nil then
			return -- The mod changed and the new match hasn't rebuilt the shapes yet
		end

		place_shape(shape, object)
		local size = object.size
		set_size(shape, size[1] + SIZE_MARGIN, size[2] + SIZE_MARGIN, size[3] + SIZE_MARGIN)
		shape.shapeType = SHAPES[object.shape] or object.shape
		shape.bgColor = get_object_colour(object_id)
	end
end

---One shape for each environment object that can move
local function create_environment_shapes()
	kill_shapes(environment_shapes)
	environment_shapes = {}
	environment_ids = {}

	-- The cache only has the objects that exist, keyed by object id + 1. A mod can skip object numbers, so the
	-- keys can have gaps: asking the engine about a missing object is an error (with menudebug on, every time)
	local object_ids = {}
	for index in pairs(get_ghost_cache(1).envs) do
		table.insert(object_ids, index - 1)
	end
	table.sort(object_ids)
	for _, object_id in ipairs(object_ids) do
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
	local parents = joint_parents[player]
	for joint = 0, get_part_counts(player) - 1 do
		local parent = get_body_info(player, parents[joint])
		local offset = vector3.subtract(get_joint_pos2(player, joint), parent.pos)
		offsets[joint] = vector3.rotate_by_inverse(rotation.from_matrix(parent.rot), offset)
	end
	return offsets
end

---Shapes for every joint and body part of a fighter, made again when a mod changes how many it has
---@param player integer
local function update_player_shapes(player)
	local joint_count, body_count = get_part_counts(player)
	local shapes = player_shapes[player]
	if shapes ~= nil and shapes.joint_count == joint_count and shapes.body_count == body_count then
		return
	end
	if shapes ~= nil then
		kill_shapes(shapes.joints)
		kill_shapes(shapes.bodies)
	end
	player_shapes[player] = {
		joints = create_shapes(joint_count),
		bodies = create_shapes(body_count),
		joint_count = joint_count,
		body_count = body_count,
	}
end

local function on_match_begin()
	for player = 0, MAX_DRAWN_PLAYERS - 1 do
		update_player_shapes(player)
	end
	-- The fighters' shapes first, then the objects', in the order they've always been made (and drawn)
	create_environment_shapes()
	for player = 0, get_world_state().num_players - 1 do
		joint_parents[player] = get_joint_parents(player)
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

---Errors already shown, so one that happens every frame is only shown once
local reported_errors = {}

---Runs `func` so an error in it can't stop the hooks after it (call_hook stops at the first error) or the script
---that loads this one: the error is shown once and the ghost is hidden until it next draws without one
---@param func function
---@param on_error function? Called after the ghost is hidden
---@return function
function future_ghost.guard(func, on_error)
	return function(...)
		local result = { pcall(func, ...) }
		if result[1] then
			return unpack(result, 2)
		end
		local message = tostring(result[2])
		if not reported_errors[message] then
			reported_errors[message] = true
			echo("Better Ghost: " .. message)
		end
		pcall(future_ghost.hide)
		if on_error then
			pcall(on_error)
		end
	end
end

future_ghost.guard(on_match_begin)()

remove_hooks(HOOK_SET)
add_hook("match_begin", HOOK_SET, future_ghost.guard(on_match_begin))
add_hook("new_game", HOOK_SET, future_ghost.guard(on_match_begin))

return future_ghost
