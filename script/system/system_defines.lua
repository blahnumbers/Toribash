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


--[[ DRAWING FUNCTIONS ]]

---Sets the color for follow-up draw calls. \
---*All color-related functions use percentages instead of classic RGB values, e.g red is `1 0 0` instead of `255 0 0`*
---@param r number
---@param g number
---@param b number
---@param a number
function set_color(r, g, b, a) end

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

--[[ TEXT FUNCTIONS ]]

---Returns on-screen text length in pixels according to specified settings
---@param message string
---@param font fontid
---@param raw ?boolean If true, will ignore current graphics DPI setting
---@return number
function get_string_length(message, font, raw) end

--[[ CAMERA CONTROLS ]]

---Enables keyboard / touch camera movement
function enable_camera_movement() end

---Disables keyboard / touch camera movement
function disable_camera_movement() end

---Enables mouse / touch camera movement
function enable_mouse_camera_movement() end

---Disables mouse / touch camera movement
function disable_mouse_camera_movement() end

--[[ SCREEN RELATED FUNCTIONS ]]

---Returns screen resolution values
---@return integer width DPI adapted screen width
---@return integer height DPI adapted screen height
---@return integer width_raw Raw screen width
---@return integer height_raw Raw screen height
function get_window_size() end

---Returns maximum supported screen resolution
---@return integer width
---@return integer height
function get_maximum_window_size() end

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

---Returns player grip state
---@param player integer
---@param hand integer
---@return integer
function get_grip_info(player, hand) end

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

--[[ OTHER FUNCTIONS ]]

---@return boolean
function is_steam() end

---Retrieves a list of currently active downloads
---@return string[]
function get_downloads() end

---Retrieves a value of the specified Toribash option
---@param value string
---@return string
function get_option(value) end

---Sets value for the specified Toribash option
---@param option string
---@param value integer
function set_option(option, value) end

---Enables chat input hotkey
function chat_input_activate() end

---Disables chat input hotkey
function chat_input_deactivate() end

---Attempts to enable screen blur
---@return integer #1 if blur is supported, 0 if not
function enable_blur() end

---Disables screen blur
function disable_blur() end

---Enables Lua menu keyboard callbacks \
---*On mobile platforms, this will also bring up on-screen keyboard*
function enable_menu_keyboard() end

---Disables Lua menu keyboard callbacks \
---*On mobile platforms, this will also hide on-screen keyboard*
function disable_menu_keyboard() end

---Prints a local chat message
---@param message string
---@param tab ?integer
function echo(message, tab) end

---@param event string
---@param value ?integer
function usage_event(event, value) end

---Sets Discord Rich Presence state \
---*Only supported on Windows*
---@param state string
---@param detail string
function set_discord_rpc(state, detail) end
