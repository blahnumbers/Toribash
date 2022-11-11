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
function get_window_size() end

---Returns screen safe size \
---This is useful on mobile devices with rounded screen corners and cutouts / notches
---@return integer x DPI adapted X shift
---@return integer y DPI adapted Y shift
---@return integer width DPI adapted safe screen width
---@return integer height DPI adapted safe screen height
function get_window_safe_size() end

---Returns maximum supported screen resolution
---@return integer width
---@return integer height
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

---Starts a new game
function start_new_game() end

---Pauses game
function freeze_game() end

---Unpauses game
function unfreeze_game() end

---Steps game \
---Pass `true` to simulate SHIFT + SPACE behavior
---@param single_frame ?boolean
function step_game(single_frame) end

---Sets the value for the specified gamerule
---@param gamerule string
---@param value string
function set_gamerule(gamerule, value) end

---Returns current value for the specified gamerule
---@param gamerule string
---@return string
function get_gamerule(gamerule) end

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


--[[ REPLAY FUNCTIONS ]]

---Returns currently used replay cache value
---@return number
function get_replay_cache() end

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


--[[ MOBILE FILE IO ]]

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

---Check whether either of shift keys is currently down
---@return integer
function get_shift_key_state() end

---Check whether either of ctrl keys is currently down
---@return integer
function get_keyboard_ctrl() end

---Check whether caps lock is currently on
---@return integer
function get_keyboard_capslock() end


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

---Opens a game menu
---@param id MenuId
function open_menu(id) end

---Internal function to trigger a confirmation box
---@param action integer
---@param message string
---@param data ?string
---@param useLuaNetwork ?boolean
function open_dialog_box(action, message, data, useLuaNetwork) end


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
