---@meta

--[[ GLOBAL VARIABLES ]]

---@alias Platform
---| "WINDOWS"
---| "APPLE"
---| "LINUX"
---| "ANDROID"
---| "IPHONEOS"
---| "UNKNOWN"

---Current platform name
---@type Platform
_G.PLATFORM = nil

---@type boolean
_G.REPLAY_VIEWER = nil

---Current game version
---@type string
_G.TORIBASH_VERSION = nil

---Current game beta version, if defined
---@type string|nil
_G.BETA_VERSION = nil

---Current build version
---@type string
_G.BUILD_VERSION = nil

---Default Toribash fonts
_G.FONTS = {
	BIG = 0,
	SMALL = 1,
	MEDIUM = 2,
	LMEDIUM = 4,
	BIGGER = 9
}

---@alias ChatMessageType
---| 0 MSGTYPE.NONE
---| 1 MSGTYPE.SERVER
---| 2 MSGTYPE.URL
---| 4 MSGTYPE.INGAME
---| 8 MSGTYPE.USER
---| 16 MSGTYPE.PLAYER

---Message types
_G.MSGTYPE = {
	NONE = 0,
	SERVER = 1,
	URL = 2,
	INGAME = 4,
	USER = 8,
	PLAYER = 16
}

---Haptics types
_G.HAPTICS = {
	IMPACT = 0,
	SELECTION = 1
}

---Joint names
_G.JOINTS = {
	NECK = 0,
	CHEST = 1,
	LUMBAR = 2,
	ABS = 3,
	R_PECS = 4,
	R_SHOULDER = 5,
	R_ELBOW = 6,
	L_PECS = 7,
	L_SHOULDER = 8,
	L_ELBOW = 9,
	R_WRIST = 10,
	L_WRIST = 11,
	R_GLUTE = 12,
	L_GLUTE = 13,
	R_HIP = 14,
	L_HIP = 15,
	R_KNEE = 16,
	L_KNEE = 17,
	R_ANKLE = 18,
	L_ANKLE = 19
}

---Joint states
_G.JOINT_STATE = {
	FORWARD = 1,
	BACK = 2,
	HOLD = 3,
	RELAX = 4
}

---Bodypart names
_G.BODYPARTS = {
	HEAD = 0,
	BREAST = 1,
	CHEST = 2,
	STOMACH = 3,
	GROIN = 4,
	R_PECS = 5,
	R_BICEPS = 6,
	R_TRICEPS = 7,
	L_PECS = 8,
	L_BICEPS = 9,
	L_TRICEPS = 10,
	R_HAND = 11,
	L_HAND = 12,
	R_BUTT = 13,
	L_BUTT = 14,
	R_THIGH = 15,
	L_THIGH = 16,
	L_LEG = 17,
	R_LEG = 18,
	R_FOOT = 19,
	L_FOOT = 20
}


--[[ DRAWING FUNCTIONS ]]

---Sets the color for follow-up draw calls. \
---*All color-related functions use percentages instead of classic RGB values, e.g red is `1 0 0` instead of `255 0 0`*
---@param r number
---@param g number
---@param b number
---@param a number
function set_color(r, g, b, a) end

---Default function to draw lines
---@param x1 number Line start X coordinate
---@param y1 number Line start Y coordinate
---@param x2 number Line end X coordinate
---@param y2 number Line end Y coordinate
---@param width number Line width in pixels
function draw_line(x1, y1, x2, y2, width) end

---Default function to draw rectangles
---@param pos_x number X coordinate of the top left corner
---@param pos_y number Y coordinate of the top left corner
---@param width number
---@param height number
---@param texture_id ?integer Texture id retrieved from `load_texture()` call
---@param tiled ?boolean If true, applied texture will repeat itself instead of being stretched
---@param r ?number Override color's `R` value
---@param g ?number Override color's `G` value
---@param b ?number Override color's `B` value
---@param a ?number Override color's alpha
function draw_quad(pos_x, pos_y, width, height, texture_id, tiled, r, g, b, a) end

---Default function to draw disks or circles
---@param pos_x number Center X position for drawing
---@param pos_y number Center Y position for drawing
---@param inner number Pixel offset from center to start the drawing from
---@param outer number Pixel offset from center to end the drawing at
---@param slices integer Number of slices for the drawn disk (higher amount = smoother edge)
---@param loops integer
---@param start number Start angle for the drawing
---@param sweep number Disk length in degrees
---@param blend integer
function draw_disk(pos_x, pos_y, inner, outer, slices, loops, start, sweep, blend) end

---Draws text with the specified scale and rotation
---@param text string
---@param pos_x number
---@param pos_y number
---@param angle number
---@param scale number
---@param font_type ?FontId
function draw_text_angle_scale(text, pos_x, pos_y, angle, scale, font_type) end

---Activates a 3D viewport for subsequent draw calls
---@param pos_x number
---@param pos_y number
---@param size_x number
---@param size_y number
function set_viewport(pos_x, pos_y, size_x, size_y) end

---Draws a 3D line from point A to point B with the specified width. \
---*This function doesn't get batched in backend so you likely want to call it from `post_draw3d` hook instead of `draw3d` to ensure proper rendering*
---@param start_x number
---@param start_y number
---@param start_z number
---@param end_x number
---@param end_y number
---@param end_z number
---@param width number
function draw_line_3d(start_x, start_y, start_z, end_x, end_y, end_z, width) end

---Draws a 3D sphere with the specified settings
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param radius number
---@param rotation_x ?number
---@param rotation_y ?number
---@param rotation_z ?number
---@param texture_id ?integer Texture id retrieved from `load_texture()` call
function draw_sphere(pos_x, pos_y, pos_z, radius, rotation_x, rotation_y, rotation_z, texture_id) end

---Loads a TGA texture by the specified path and returns texture id or -1 on error
---@param path string
---@return integer
function load_texture(path) end

---Unloads a texture with the specified id
---@param id integer
function unload_texture(id) end


--[[ TEXT FUNCTIONS ]]

---Returns on-screen text length in pixels according to specified settings
---@param message string
---@param font FontId
---@param raw ?boolean If true, will ignore current graphics DPI setting
---@return number
function get_string_length(message, font, raw) end

---Localizes a RTL string
---@param text string
function localize_rtl(text) end


--[[ CAMERA CONTROLS ]]

---Enables keyboard / touch camera movement
function enable_camera_movement() end

---Disables keyboard / touch camera movement
function disable_camera_movement() end

---Enables mouse / touch camera movement
function enable_mouse_camera_movement() end

---Disables mouse / touch camera movement
function disable_mouse_camera_movement() end

---Sets field of view
---@param field_of_view number
function set_fov(field_of_view) end

--[[ SCREEN RELATED FUNCTIONS ]]

---Returns screen resolution values
---@return integer width DPI adapted screen width
---@return integer height DPI adapted screen height
---@return integer width_raw Raw screen width
---@return integer height_raw Raw screen height
---@nodiscard
function get_window_size() end

---Returns screen safe size \
---This is useful on mobile devices with rounded screen corners and cutouts / notches
---@return integer x DPI adapted X shift
---@return integer y DPI adapted Y shift
---@return integer width DPI adapted safe screen width
---@return integer height DPI adapted safe screen height
---@nodiscard
function get_window_safe_size() end

---Returns maximum supported screen resolution
---@return integer width
---@return integer height
---@nodiscard
function get_maximum_window_size() end

---@class DpiAwarenessInfo
---@field ISDPIAWARE integer
---@field DPISCALING number

---Returns dpi awareness info on Windows
---@return DpiAwarenessInfo
function get_dpiawareness() end

---Returns screen position of a specified player joint
---@param player integer
---@param joint integer
---@return integer x
---@return integer y
---@return integer z
function get_joint_screen_pos(player, joint) end

---Returns screen position of a specified player bodypart
---@param player integer
---@param body integer
---@return integer x
---@return integer y
---@return integer z
function get_body_screen_pos(player, body) end

--[[ GAME FUNCTIONS ]]

---@alias WorldStateGameType
---| 0 #Single Player
---| 1 #Multi Player

---@alias WorldStateWinner
---| -1 #No winner | Draw
---| 0 #Tori
---| 1 #Uke

---@class WorldState
---@field game_type WorldStateGameType
---@field game_paused integer
---@field replay_mode integer
---@field match_frame integer Current frame
---@field turn_frame integer
---@field turn_timeout integer
---@field reaction_time integer Current reaction time
---@field game_frame integer Total match length
---@field frame_tick integer
---@field num_players integer
---@field num_bouts integer
---@field selected_player integer
---@field selected_joint integer
---@field selected_body integer
---@field match_turn integer
---@field match_turn_frame integer
---@field winner WorldStateWinner

---Returns world state information
---@return WorldState
function get_world_state() end

---@class BodyInfo
---@field name string
---@field mod_name string
---@field pos Vector3
---@field rot Matrix4x4
---@field sides Vector3

---Returns player body information
---@param player integer
---@param body integer
---@return BodyInfo
function get_body_info(player, body) end

---@alias JointInfoState
---| 0 #None
---| 1 #Forward
---| 2 #Backward
---| 3 #Hold
---| 4 #Relax

---@class JointInfo
---@field state JointInfoState
---@field screen_state string Adapted readable state name
---@field name string
---@field mod_name string

---Returns player joint information
---@param player integer
---@param joint integer
---@return JointInfo
function get_joint_info(player, joint) end

---Returns joint dismember state
---@param player integer
---@param joint integer
---@return boolean
function get_joint_dismember(player, joint) end

---Returns joint fracture state
---@param player integer
---@param joint integer
---@return boolean
function get_joint_fracture(player, joint) end

---Sets joint state for the specified player
---@param player integer
---@param joint integer
---@param state integer
---@param with_onchange_effects ?boolean Whether to automatically rewind ghost and play joint change state sound
function set_joint_state(player, joint, state, with_onchange_effects) end

---Returns a joint-specific readable state name
---@param joint integer
---@param state integer
---@return string
function get_joint_state_name(joint, state) end

---Returns player grip state
---@param player integer
---@param hand integer
---@return integer
function get_grip_info(player, hand) end

---Sets player grip state
---@param player integer
---@param hand integer
---@param state integer
function set_grip_info(player, hand, state) end

---Returns joint position in 3D world
---@param player integer
---@param joint integer
---@return number x
---@return number y
---@return number z
---@nodiscard
function get_joint_pos(player, joint) end

---Starts a new game
---@param safe ?boolean If `true` is passed, will report ready event when in multiplayer instead of starting new free play game
function start_new_game(safe) end

---Pauses game
function freeze_game() end

---Unpauses game
function unfreeze_game() end

---Returns value depending on game freeze state
---@return integer
function is_game_frozen() end

---Steps the game simulation. \
---*Pass `true` to simulate SHIFT + SPACE behavior*
---@param single_frame ?boolean
function step_game(single_frame) end

---Rewinds the replay to the beginning
function rewind_replay() end

---Rewinds the replay to the specified frame
---@param frame number
function rewind_replay_to_frame(frame) end

---Enters replay edit mode
function edit_game() end

---Simulates the game for the specified number of frames
---@param frames integer
function run_frames(frames) end

---An aggregated value that's built based on disqualification, grip, dismemberment and fracture values
---@alias GamerulesFlags
---| 0 None
---| 1 DQ
---| 2 Dismemberment
---| 3 DQ + Dismemberment
---| 4 No grip
---| 5 DQ + No grip
---| 6 Dismemberment + No grip
---| 7 DQ + Dismemberment + No grip
---| 8 Fracture
---| 9 DQ + Fracture
---| 10 Dismemberment + Fracture
---| 11 DQ + Dismemberment + Fracture
---| 12 No grip + Fracture
---| 13 DQ + No grip + Fracture
---| 14 Dismemberment + No grip + Fracture
---| 15 DQ + Dismemberment + No grip + Fracture

---@class Gamerules
---@field mod					string			Mod file name
---@field matchframes			integer			Maximum match frames
---@field turnframes			string			Turn frames, comma-separated
---@field flags					GamerulesFlags	Mod flags
---@field grip					integer			Whether grips are enabled
---@field dismemberment			integer			Whether dismemberment is enabled
---@field fracture				integer			Whether fracture is enabled
---@field disqualification		integer			Whether disqualification is enabled
---@field dqtimeout				integer			Disqualification timeout
---@field dismemberthreshold	integer			Joint dismemberment threshold
---@field fracturethreshold		integer			Joint fracture threshold
---@field pointthreshold		integer			Whether the mod uses regular scoring system or point-based system
---@field winpoint				integer			Points threshold to win the match, 0 is no limit
---@field dojotype				integer			`0` - square dojo, `1` - round dojo
---@field dojosize				integer			Dojo size
---@field engagedistance		integer			Starting distance between players
---@field engageheight			integer			Starting height for players
---@field engagerotation		integer			Starting rotation for players
---@field engageplayerpos		string			Per-player position coordinates. If specified, this will override `engagedistance`, `engageheight` and `engagerotation` values
---@field engageplayerrot		string			Per-player rotations. Requires `engageplayerpos` to be specified.
---@field damage				integer			Damage scoring mode. `0` - opponent damage only, `1` - self and opponent damage, `2` - self damage only.
---@field gravity				string			World gravity
---@field sumo					integer			Which bodyparts are exampted from DQing or getting damage. `0` - classic (feet and hands), `1` - sumo (wrists, feet and hands).
---@field reactiontime			integer			Reaction time for a turn (used in Multiplayer only)
---@field drawwinner			integer			Determines which player will be considered a winner on Draw. `0` - default (no winner), `1` - Tori wins, `2` - Uke wins.
---@field maxcontacts			integer			Determines collision accuracy, higher value means more simultaneous collisions support
---@field ghostlength			integer			Maximum ghost length
---@field ghostspeed			integer			Ghost display speed
---@field ghostcustom			integer			Internal value to specify whether to use `ghostlength` and `ghostspeed` values
---@field grabmode				integer			`0` - classic grabs (fixed), `1` - ball joint (rotatable) grabs
---@field tearthreshold			integer			Ball joint grabs' break threshold
---@field numplayers			integer			Player count for the mod

---Returns current game rules
---@return Gamerules
function get_game_rules() end

---Returns current value for the specified gamerule
---@param gamerule string
---@return string
function get_gamerule(gamerule) end

---Sets the value for the specified gamerule
---@param gamerule string
---@param value string
function set_gamerule(gamerule, value) end

---@class FightPlayerInfo
---@field name string
---@field injury number
---@field score number
---@field num_textures integer

---Returns information on specified player or nil on error
---@param playerid integer
---@return FightPlayerInfo|nil
function get_player_info(playerid) end

---@alias GhostMode
---| 0 GHOST_NONE
---| 1 GHOST_SELECTED
---| 2 GHOST_BOTH

---Returns current ghost mode
---@return GhostMode
function get_ghost() end

---Sets ghost mode to the specified value
---@param mode GhostMode
function set_ghost(mode) end


--[[ MOD FUNCTIONS ]]

---Returns the position of the specified environment object
---@param obj_id integer
---@return number x
---@return number y
---@return number z
---@nodiscard
function get_obj_pos(obj_id) end

---Sets the position for the specified environment object
---@param obj_id integer
---@param x number
---@param y number
---@param z number
function set_obj_pos(obj_id, x, y, z) end

---Returns size of the specified environment object. \
---This function will always return 3 values but they vary depending on object shape:
---* Box: regular xyz dimensions
---* Sphere: `x` contains shape radius
---* Cylinder: `x` contains shape radius, `y` contains length
---@param obj_id integer
---@return number x
---@return number y
---@return number z
function get_obj_sides(obj_id) end

---Sets the size for the specified environment object
---@param obj_id integer
---@param x number
---@param y number
---@param z number
function set_obj_sides(obj_id, x, y, z) end

---Returns the rotation matrix of the specified environment object \
---@see UIElement3D.getEulerAnglesFromMatrixTB
---@param obj_id integer
---@return number[]
function get_obj_rot(obj_id) end

---Sets the rotation for the specified environment object
---@param obj_id integer
---@param x number
---@param y number
---@param z number
function set_obj_rot(obj_id, x, y, z) end

---Applies force to the specified environment object
---@param obj_id integer
---@param x number
---@param y number
---@param z number
function set_obj_force(obj_id, x, y, z) end

---Sets color for the specified environment object
---@param obj_id integer
---@param r number
---@param g number
---@param b number
---@param a number
function set_obj_color(obj_id, r, g, b, a) end

---Returns linear velocity of the specified environment object
---@param obj_id integer
---@return number x
---@return number y
---@return number z
---@nodiscard
function get_obj_linear_vel(obj_id) end

---Sets linear velocity for the specified environment object \
---*You might be looking for `set_obj_force()` instead*
---@param obj_id integer
---@param x number
---@param y number
---@param z number
function set_obj_linear_vel(obj_id, x, y, z) end

---Returns angular velocity of the specified environment object
---@param obj_id integer
---@return number x
---@return number y
---@return number z
---@nodiscard
function get_obj_angular_vel(obj_id) end

---Sets angular velocity for the specified environment object
---@param obj_id integer
---@param x number
---@param y number
---@param z number
function set_obj_angular_vel(obj_id, x, y, z) end

---Returns flag value for the specified environment object
---@param obj_id integer
---@return integer
function get_obj_flag(obj_id) end

---Sets flag value for the specified environment object
---@param obj_id integer
---@param flag integer
function set_obj_flag(obj_id, flag) end

---Returns visiblity value for the specified environment object
---@param obj_id integer
---@return integer
function get_obj_vis(obj_id) end

---Sets visibility value for the specified environment object
---@param obj_id integer
---@param visibility integer
function set_obj_vis(obj_id, visibility) end

---Returns bounce value for the specified environment object
---@param obj_id integer
---@return number
function get_obj_bounce(obj_id) end

---Sets bounce value for the specified environment object
---@param obj_id integer
---@param bounce number
function set_obj_bounce(obj_id, bounce) end

---Returns mass value for the specified environment object
---@param obj_id integer
---@return number
function get_obj_nass(obj_id) end

---Sets mass value for the specified environment object
---@param obj_id integer
---@param mass number
function set_obj_mass(obj_id, mass) end


--[[ REPLAY FUNCTIONS ]]

---Returns currently used replay cache value
---@return number
function get_replay_cache() end

---Renames a replay file
---@param filename string
---@param new_filename string
---@return any result
function rename_replay(filename, new_filename) end

---Deletes a replay file
---@param filename string
---@return any result
function delete_replay(filename) end

---Plays the next replay in current folder
function play_next_replay() end

---Plays the previous replay in current folder
function play_prev_replay() end

---Returns current replay playback speed
---@return number
function get_replay_speed() end

---Sets current replay playback speed
---@param speed number
function set_replay_speed(speed) end

--[[ CUSTOMIZATION RELATED FUNCTIONS ]]

---Returns joint color IDs
---@param player any
---@param joint any
---@return integer #Force color ID
---@return integer #Relax color ID
function get_joint_colors(player, joint) end

---@deprecated
---This function will be removed in future releases
function get_joint_color(player, joint) end

---@class ColorInfo
---@field name string
---@field game_name string
---@field r number
---@field g number
---@field b number

---Returns information about a Toribash color
---@param colorid integer
---@return ColorInfo
function get_color_info(colorid) end

---Returns RGBA values of a Toribash color
---@param colorid integer
---@return Color
function get_color_rgba(colorid) end


--[[ MOBILE FILE IO AND GENERAL FILE IO OVERRIDES ]]

---Opens a file, in the mode specified in the string `mode`. \
---*This is a modified version of default `io.open()` function that starts file lookup at `data/script` directory by default.* \
---[View documents](command:extension.lua.doc?["en-us/51/manual.html/pdf-io.open"])
---@param filename string
---@param mode?    openmode
---@param root?    integer Pass `1` to open file at Toribash root folder
---@return file*?
---@return string? errmsg
---@diagnostic disable-next-line: duplicate-set-field
function io.open(filename, mode, root) end

---Attempts to open a file at location and returns the index on success or nil on failure
---@param path string
---@param mode ?mode
---@param root ?integer|boolean If `true|1`, will look up from Toribash root location instead of data/script
---@return integer|nil
function file_open(path, mode, root) end

---Reads all data from a file that's currently open by `file_open()`
---@param fileidx integer
---@return string
function file_read(fileidx) end

---Writes data to a file that's currently open by `file_open()`
---@param fileidx integer
---@param data string
---@return boolean
function file_write(fileidx, data) end

---Closes a file that's currently open by `file_open()`
---@param fileidx integer
function file_close(fileidx) end

--[[ NETWORKING ]]

---Launches a network request to update current user's TC and ST balance
function update_tc_balance() end

---Downloads a data file from Toribash servers
---@param request string
---@param mode integer
function download_server_file(request, mode) end

---Fetches information from Toribash servers
---@param request string
function download_server_info(request) end

---Sends a request to retrieve the latest available game version
function get_latest_version() end

---Returns received data from the last network request
---@return string
function get_network_response() end

---Returns last network request error
---@return string
function get_network_error() end

---Reports whether we have an active network task
---@return integer
function get_network_task() end

---Opens a webpage with user's default browser \
---*Only Toribash links are supported*
---@param url string
function open_url(url) end

---Downloads bounties data for the current user
function download_fetch_bounties() end

---Downloads quests data for the specified user
---@param username string
function download_quest(username) end

---Initiates a network request to upload an event replay to Toribash servers
---@param name string
---@param description string
---@param tags string
---@param filename string
function upload_event_replay(name, description, tags, filename) end


-- [[ NOTIFICATIONS ]]

---Sends a network request to fetch total number of unread notifications for the user
function get_notifications_count() end

---Sends a network request to fetch general data about user's inbox
function get_notifications() end

---Sends a network request to download contents of a private message from user's inbox
---@param pmid integer
function get_notifications_pmtext(pmid) end

---Sends a network request to delete private message located in user's inbox
---@param pmid integer
function delete_notification(pmid) end


-- [[ KEYBOARD FUNCTIONS ]]

---Enables Lua menu keyboard callbacks. On mobile platforms, this will also bring up on-screen keyboard. \
---It is recommended to pass input element's position and size on mobile platforms to ensure input field is in focus.
---@overload fun()
---@param inputX integer
---@param inputY integer
---@param inputWidth integer
---@param inputHeight integer
function enable_menu_keyboard(inputX, inputY, inputWidth, inputHeight) end

---Disables Lua menu keyboard callbacks \
---*On mobile platforms, this will also hide on-screen keyboard*
function disable_menu_keyboard() end

---Returns whether either of shift keys is currently down
---@return integer
function get_shift_key_state() end

---Returns whether either of ctrl keys is currently down
---@return integer
function get_keyboard_ctrl() end

---Returns whether caps lock is currently on
---@return integer
function get_keyboard_capslock() end

---Returns whether either of alt keys is currently on
---@return integer
function get_keyboard_alt() end

---Returns current clipboard text contents
---@return string|nil
function get_clipboard_text() end


--[[ BITWISE LUA FUNCTIONS ]]

---@class bitlib
bit = {}

---Normalizes a number to the numeric range for bit operations and returns it.
---
---This function is usually not needed since all bit operations already normalize all of their input arguments. Check the [operational semantics](https://bitop.luajit.org/semantics.html) for details.
---
---[View documentation](https://bitop.luajit.org/api.html#tobit)
---@param x integer
---@return integer
function bit.tobit(x) end

---Returns the bitwise **not** of its argument.
---
---[View documentation](https://bitop.luajit.org/api.html#bnot)
---@param x integer
---@return integer
function bit.bnot(x) end

---Returns the bitwise **and** of all of its arguments. \
---Note that more than two arguments are allowed.
---
---[View documentation](https://bitop.luajit.org/api.html#band)
---@param x1 integer
---@param ... integer
---@return integer
function bit.band(x1, ...) end

---Returns the bitwise **or** of all of its arguments. \
---Note that more than two arguments are allowed.
---
---[View documentation](https://bitop.luajit.org/api.html#bor)
---@param x1 integer
---@param ... integer
---@return integer
function bit.bor(x1, ...) end

---Returns the bitwise **xor** of all of its arguments. \
---Note that more than two arguments are allowed.
---
---[View documentation](https://bitop.luajit.org/api.html#bxor)
---@param x1 integer
---@param ... integer
---@return integer
function bit.bxor(x1, ...) end

---Returns the bitwise **logical left-shift** of its first argument by the number of bits given by the second argument.
---
---Treats the first argument as an unsigned number and shift in 0-bits. \
---Only the lower 5 bits of the shift count are used (reduces to the range [0..31]).
---
---[View documentation](https://bitop.luajit.org/api.html#lshift)
---@param x integer
---@param n integer
---@return integer
function bit.lshift(x, n) end

---Returns the bitwise **logical right-shift** of its first argument by the number of bits given by the second argument.
---
---Treats the first argument as an unsigned number and shift in 0-bits. \
---Only the lower 5 bits of the shift count are used (reduces to the range [0..31]).
---
---[View documentation](https://bitop.luajit.org/api.html#rshift)
---@param x integer
---@param n integer
---@return integer
function bit.rshift(x, n) end

---Returns the bitwise **arithmetic right-shift** of its first argument by the number of bits given by the second argument.
---
---Treats the most-significant bit as a sign bit and replicates it. \
---Only the lower 5 bits of the shift count are used (reduces to the range [0..31]).
---
---[View documentation](https://bitop.luajit.org/api.html#arshift)
---@param x integer
---@param n integer
---@return integer
function bit.arshift(x, n) end

---Returns the bitwise **left rotation** of its first argument by the number of bits given by the second argument. Bits shifted out on one side are shifted back in on the other side. \
---Only the lower 5 bits of the rotate count are used (reduces to the range [0..31]).
---
---[View documentation](https://bitop.luajit.org/api.html#rol)
---@param x integer
---@param n integer
---@return integer
function bit.rol(x, n) end

---Returns the bitwise **right rotation** of its first argument by the number of bits given by the second argument. Bits shifted out on one side are shifted back in on the other side. \
---Only the lower 5 bits of the rotate count are used (reduces to the range [0..31]).
---
---[View documentation](https://bitop.luajit.org/api.html#ror)
---@param x integer
---@param n integer
---@return integer
function bit.ror(x, n) end

---Swaps the bytes of its argument and returns it. \
---This can be used to convert little-endian 32 bit numbers to big-endian 32 bit numbers or vice versa.
---
---[View documentation](https://bitop.luajit.org/api.html#bswap)
---@param x integer
---@return integer
function bit.bswap(x) end

---Converts its first argument to a hex string.
---
---The number of hex digits is given by the absolute value of the optional second argument. Positive numbers between 1 and 8 generate lowercase hex digits. Negative numbers generate uppercase hex digits. Only the least-significant 4*|n| bits are used. The default is to generate 8 lowercase hex digits.
---
---[View documentation](https://bitop.luajit.org/api.html#tohex)
---@param x integer
---@param n ?integer
---@return integer
function bit.tohex(x, n) end


--[[ UTF8 FUNCTIONS ]]

---**UTF-8 module for Lua 5.x** \
---Many of the functions are identical to [stringlib](command:extension.lua.doc?["en-us/51/manual.html/pdf-string"]) in terms of use.
---
---[View more on GitHub](https://github.com/starwing/luautf8)
---@class utf8lib
utf8 = {}

---Returns a string with length equal to the number of arguments, in which each character has the internal numeric code equal to its corresponding argument.
---@param s  string
---@param i? integer
---@param j? integer
---@return integer ...
---@nodiscard
function utf8.byte(s, i, j) end

---Returns a string with length equal to the number of arguments, in which each character has the internal numeric code equal to its corresponding argument.
---@param byte integer
---@param ... integer
---@return string
---@nodiscard
function utf8.char(byte, ...) end

---Looks for the first match of `pattern` (see [§6.4.1](command:extension.lua.doc?["en-us/51/manual.html/6.4.1"])) in the string.
---@param s       string
---@param pattern string
---@param init?   integer
---@param plain?  boolean
---@return integer start
---@return integer end
---@return any ... captured
---@nodiscard
function utf8.find(s, pattern, init, plain) end

---Returns an iterator function that, each time it is called, returns the next captures from `pattern` (see [§6.4.1](command:extension.lua.doc?["en-us/51/manual.html/6.4.1"])) over the string s.
---@param s       string
---@param pattern string
---@return fun():string, ...
---@nodiscard
function utf8.gmatch(s, pattern) end

---Returns a copy of s in which all (or the first `n`, if given) occurrences of the `pattern` (see [§6.4.1](command:extension.lua.doc?["en-us/51/manual.html/6.4.1"])) have been replaced by a replacement string specified by `repl`.
---@param s       string
---@param pattern string
---@param repl    string|number|table|function
---@param n?      integer
---@return string
---@return integer count
---@nodiscard
function utf8.gsub(s, pattern, repl, n) end

---Returns its length.
---@param s string
---@return integer
---@nodiscard
function utf8.len(s) end

---Returns a copy of this string with all uppercase letters changed to lowercase.
---@param s string
---@return string
---@nodiscard
function utf8.lower(s) end

---Looks for the first match of `pattern` (see [§6.4.1](command:extension.lua.doc?["en-us/51/manual.html/6.4.1"])) in the string.
---@param s       string
---@param pattern string
---@param init?   integer
---@return any ...
---@nodiscard
function utf8.match(s, pattern, init) end

---Returns a string that is the string `s` reversed.
---@param s string
---@return string
---@nodiscard
function utf8.reverse(s) end

---Returns the substring of the string that starts at `i` and continues until `j`.
---@param s  string
---@param i  integer
---@param j? integer
---@return string
---@nodiscard
function utf8.sub(s, i, j) end

---Returns a copy of this string with all lowercase letters changed to uppercase.
---@param s string
---@return string
---@nodiscard
function utf8.upper(s) end

---Escapes a str to UTF-8 format string. Supported formats:
--- -`%ddd` - which ddd is a decimal number at any length: change Unicode code point to UTF-8 format.
--- - `%{ddd}` - same as `%nnn` but has bracket around.
--- - `%uddd` - same as `%ddd`, u stands Unicode
--- - `%u{ddd}` - same as `%{ddd}`
--- - `%xhhh` - hexadigit version of `%ddd`
--- - `%x{hhh}` same as `%xhhh`.
--- `%?` - '?' stands for any other character: escape this character.
---@param str string
---@return string
---@nodiscard
function utf8.escape(str) end


--[[ OPTION FUNCTIONS ]]

---Saves current settings to config file
function save_custom_config() end

---Retrieves a value of the specified Toribash option
---@param value string
---@return string
function get_option(value) end

---Sets value for the specified Toribash option
---@param option string
---@param value integer
function set_option(option, value) end

---@alias GraphicsOption
---| 0 Shaders
---| 1 Fluid blood
---| 2 Floor reflections
---| 3 Soft shadows
---| 4 Ambient occlusion
---| 5 Bumpmapping
---| 6 Ray tracing
---| 7 Body textures
---| 8 High dpi mode
---| 9 Borderless window mode
---| 10 Item effects

---Sets value for the specified graphics option \
---Changes will be applied on next `reload_graphics()` call
---@param option GraphicsOption
---@param value string|number
function set_graphics_option(option, value) end

---Reloads graphics and applies changes set by `set_graphics_option()`
function reload_graphics() end

---@alias SoundCategoryId
---| 0 Shout
---| 1 Dismember
---| 2 Fight alert
---| 3 Freeze
---| 4 Game over
---| 5 Grading
---| 6 Grip
---| 7 Hit
---| 8 Impact
---| 9 Joint
---| 10 Menu
---| 11 None
---| 12 Pain
---| 13 Ready
---| 14 Select player
---| 15 Splash
---| 16 Swoosh

---Sets sound category options
---@param id SoundCategoryId
---@param enable integer
---@param default integer
function set_sound_category(id, enable, default) end

---Returns sound category options
---@param id SoundCategoryId
---@return integer enabled
---@return integer default
function get_sound_category(id) end


--[[ OTHER FUNCTIONS ]]

---@return boolean
function is_steam() end

---@return boolean
function is_mobile() end

---Retrieves a list of currently active downloads
---@return string[]
function get_downloads() end

---Returns a list of files in specified directory
---@param directory string
---@param suffix string
---@return string[]
function get_files(directory, suffix) end

---Enables chat input hotkey
function chat_input_activate() end

---Disables chat input hotkey
function chat_input_deactivate() end

---Returns the last 100 messages sent from current client
---@return string[]
function get_chat_history() end

---Attempts to enable screen blur
---@return integer #1 if blur is supported, 0 if not
function enable_blur() end

---Disables screen blur
function disable_blur() end

---Prints a local chat message
---@param message string
---@param tab ?integer
function echo(message, tab) end

---Runs a game command
---@param command string
---@param online ?integer
---@param silent ?boolean
function run_cmd(command, online, silent) end

---@param event string
---@param value ?integer
function usage_event(event, value) end

---Sets Discord Rich Presence state \
---*Only supported on Windows*
---@param state string
---@param detail string
function set_discord_rpc(state, detail) end

---Triggers haptics with the specified settings on supported devices. \
---See `HAPTICS` table for supported haptics types.
---@param strength number
---@param type ?integer
function play_haptics(strength, type) end

---Sets a build version for error reporter
---@param version string
function set_build_version(version) end

---Sets mouse cursor state override
---@param state integer
---@param instant ?boolean
function set_mouse_cursor(state, instant) end

---Closes current game menu
function close_menu() end

---Plays a Toribash sound by its ID
---@param soundid integer
---@param volume ?number
function play_sound(soundid, volume) end

---Returns current game language
---@return string
function get_language() end

---Changes language to the specified one if it's available
---@param language string
---@param deferred ?integer
function set_language(language, deferred) end

---@alias MenuId
---| 1 DISPLAY_FREE
---| 2 DISPLAY_MULTI
---| 3 DISPLAY_SETUP
---| 4 DISPLAY_QUIT
---| 5 DISPLAY_RULES
---| 6 DISPLAY_REPLAY
---| 7 DISPLAY_MODS
---| 8 DISPLAY_SCRIPTS
---| 9 DISPLAY_SHADERS
---| 10 DISPLAY_SAVE
---| 11 DEPRECATED
---| 12 DISPLAY_CUSTOM_PLAYER
---| 13 DISPLAY_SUBMENU_TUTORIAL
---| 14 DISPLAY_ABOUT
---| 15 DISPLAY_BUY_CREDIT
---| 16 DISPLAY_SOUNDS
---| 17 DISPLAY_MOD_MAKER
---| 18 DISPLAY_LOGIN
---| 19 DISPLAY_MAIN
---| 20 DISPLAY_CHAT

---Opens a game menu
---@param id MenuId
function open_menu(id) end

---Internal function to trigger a confirmation box
---@param action integer
---@param message string
---@param data ?string
---@param useLuaNetwork ?boolean
function open_dialog_box(action, message, data, useLuaNetwork) end

---Returns screen coordinates of a point in 3D world
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@return integer x
---@return integer y
---@return integer z
function get_screen_pos(pos_x, pos_y, pos_z) end


--[[ DISCORD FUNCTIONS ]]

---Accepts Discord join request
---@param discordId string
function discord_accept_join(discordId) end

---Refuses Discord join request
---@param discordId string
function discord_reject_join(discordId) end


--[[ CALLBACK / HOOK FUNCTIONS ]]

---@alias LuaCallback
---| "new_game" #Called on new game or world initialization
---| "new_mp_game" #Called when user joins a multiplayer room
---| "enter_frame" #Called in physics stepper before running frame events
---| "end_game" #Called on game end
---| "leave_game" #Called before leaving current game. May be triggered before new game, on replay load, etc.
---| "enter_freeze" #Called when we enter edit mode during the fight
---| "exit_freeze" #Called when we exit edit mode during the fight
---| "match_begin" #Called shortly before the new game
---| "key_up" #Called on keyboard key up event
---| "key_down" #Called on keyboard key down event
---| "mouse_button_up" #Called on mouse button / touch up event
---| "mouse_button_down" #Called on mouse button / touch down event
---| "mouse_move" #Called on mouse move / swipe event
---| "player_select" #Called when a new player is selected (including empty player selection)
---| "joint_select" #Called when new joint is selected (including empty joint selection)
---| "body_select" #Called when new bodypart is selected (including empty bodypart selection)
---| "spec_select_player" #Called when clicking on a player while being a spectator in Multiplayer
---| "draw2d" #Main 2D graphics loop
---| "draw3d" #Main 3D graphics loop
---| "play" #Part of the old Torishop, deprecated
---| "camera" #Main camera loop
---| "console" #Called when chat receives a new message
---| "bout_mouse_down" #Called on mouse button down event for room queue bout list
---| "bout_mouse_up" #Called on mouse button up event for room queue bout list
---| "bout_mouse_over" #deprecated
---| "bout_mouse_outside" #deprecated
---| "spec_mouse_down" #Called on mouse button down event for room queue spec list
---| "spec_mouse_up" #Called on mouse button up event for room queue spec list
---| "spec_mouse_over" #deprecated
---| "spec_mouse_outside" #deprecated
---| "command" #Called when an unused /command is entered
---| "unload" #Called when loading a new script
---| "draw_viewport" #Main viewport graphics loop
---| "key_hold" #Called when holding a keyboard key
---| "pre_draw" #Called before any other drawing callbacks
---| "new_game_mp" #Called on new multiplayer game
---| "network_complete" #Called on successful network request completion
---| "network_error" #Called on network request error
---| "post_draw3d" #Additional 3D graphics loop, executed after all other drawing is done
---| "downloader_complete" #Called when a file from the queue has finished downloading
---| "filebrowser_select" #Called on platform-specific file browser exit
---| "mod_trigger" #Called when a mod trigger is invoked
---| "resolution_changed" #Called when game resolution is updated
---| "console_post" #Called after a non-discarded console hook call
---| "text_input" #Called when text input event is received

---Adds a Lua callback listener \
---*Only one function per event / set_name pair is supported*
---@param event LuaCallback
---@param set_name string Hook set name to allow better hook management and unloading
---@param func function
function add_hook(event, set_name, func) end

---Removes a single Lua callback listener for the specified event / set_name pair
---@param event LuaCallback
---@param set_name string
function remove_hook(event, set_name) end

---Removes all Lua callbacks associated with the specified set_name
---@param set_name string
function remove_hooks(set_name) end

---Returns all currently loaded Lua callbacks
---@return function[][]
function get_hooks() end

---Simulates a Lua callback invocation \
---*This will not trigger any non-Lua exclusive game functionality associated with the relative hook*
---@param event string
---@param ... any Callback arguments
function call_hook(event, ...) end

---Returns real time in seconds since application launch
---@return number
function os.clock_real() end


--[[ RAY CASTING ]]

---@alias ODEBodyType
---| 0 Sphere
---| 1 Box
---| 2 Capped Cylinder

---Creates a geometry body that can be used for Lua raycasting and returns its id on success
---@param type ODEBodyType
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param size_x number Radius for sphere or ccylinder, X dimension for box
---@param size_y ?number Length for ccylinder, Y dimension for box
---@param size_z ?number Z dimension for box
---@param rot_x ?number
---@param rot_y ?number
---@param rot_z ?number
---@return integer|nil
function create_raycast_body(type, pos_x, pos_y, pos_z, size_x, size_y, size_z, rot_x, rot_y, rot_z) end

---Destroys a geometry body created by `create_raycast_body()` call
---@param geomid integer
function destroy_raycast_body(geomid) end

---Shoots a ray from `start` to `end`
---@param start_x number
---@param start_y number
---@param start_z number
---@param end_x number
---@param end_y number
---@param end_z number
---@param ... integer Geom ids that should be ignored during raycasting
---@return integer|nil geomId Geom id that was hit first
---@return number|nil distance Distance from point `start` to the returned `geomId`
function shoot_ray(start_x, start_y, start_z, end_x, end_y, end_z, ...) end

---Shoots a ray from current camera position to a position in the world that corresponds to provided screen position
---@param pos_x integer
---@param pos_y integer
---@param length ?number Maximum ray length
---@return integer|nil geomId Geom id that was hit first
---@return number|nil distance Distance from camera to the returned `geomId`
function shoot_camera_ray(pos_x, pos_y, length) end
