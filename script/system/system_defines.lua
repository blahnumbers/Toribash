---@meta
---This file contains documentation for all Toribash-specific Lua functions and global variables
---You DO NOT need to include this file in any of your scripts, it is only used by EmmyLua plugins
---
---Updated as of Toribash 5.60

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

---@alias HapticsType
---| 0 HAPTICS.IMPACT
---| 1 HAPTICS.SELECTION

---Haptics types
_G.HAPTICS = {
	IMPACT = 0,
	SELECTION = 1
}

---@alias PlayerJoint
---| 0	JOINTS.NECK
---| 1	JOINTS.CHEST
---| 2	JOINTS.LUMBAR
---| 3	JOINTS.ABS
---| 4	JOINTS.R_PECS
---| 5	JOINTS.R_SHOULDER
---| 6	JOINTS.R_ELBOW
---| 7	JOINTS.L_PECS
---| 8	JOINTS.L_SHOULDER
---| 9	JOINTS.L_ELBOW
---| 10	JOINTS.R_WRIST
---| 11	JOINTS.L_WRIST
---| 12	JOINTS.R_GLUTE
---| 13	JOINTS.L_GLUTE
---| 14	JOINTS.R_HIP
---| 15	JOINTS.L_HIP
---| 16	JOINTS.R_KNEE
---| 17	JOINTS.L_KNEE
---| 18	JOINTS.R_ANKLE
---| 19	JOINTS.L_ANKLE

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

---@alias PlayerJointState
---| 1	JOINT_STATE.FORWARD
---| 2	JOINT_STATE.BACK
---| 3	JOINT_STATE.HOLD
---| 4	JOINT_STATE.RELAX

---Joint states
_G.JOINT_STATE = {
	FORWARD = 1,
	BACK = 2,
	HOLD = 3,
	RELAX = 4
}

---@alias PlayerBody
---| 0	BODYPARTS.HEAD
---| 1	BODYPARTS.BREAST
---| 2	BODYPARTS.CHEST
---| 3	BODYPARTS.STOMACH
---| 4	BODYPARTS.GROIN
---| 5	BODYPARTS.R_PECS
---| 6	BODYPARTS.R_BICEPS
---| 7	BODYPARTS.R_TRICEPS
---| 8	BODYPARTS.L_PECS
---| 9	BODYPARTS.L_BICEPS
---| 10	BODYPARTS.L_TRICEPS
---| 11	BODYPARTS.R_HAND
---| 12	BODYPARTS.L_HAND
---| 13	BODYPARTS.R_BUTT
---| 14	BODYPARTS.L_BUTT
---| 15	BODYPARTS.R_THIGH
---| 16	BODYPARTS.L_THIGH
---| 17	BODYPARTS.L_LEG
---| 18	BODYPARTS.R_LEG
---| 19	BODYPARTS.R_FOOT
---| 20	BODYPARTS.L_FOOT

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

---Default function to draw triangles
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param x3 number
---@param y3 number
---@param z3 number
function draw_triangle(x1, y1, z1, x2, y2, z2, x3, y3, z3) end

---Generates font style based on the source font id
---@param source_fontid FontId
---@param scale number
---@param outline integer
---@return integer --Generated font id or `-1` on error
function generate_font(source_fontid, scale, outline) end

---Draws text at the specified position
---@param text string
---@param pos_x number
---@param pos_y number
---@param font_type ?FontId
function draw_text(text, pos_x, pos_y, font_type) end

---Draws right-aligned text from the specified position
---@param text string
---@param pos_x number
---@param pos_y number
---@param font_type ?FontId
function draw_right_text(text, pos_x, pos_y, font_type) end

---Draws centered text at the specified height
---@param text string
---@param pos_y number
---@param font_type ?FontId
function draw_centered_text(text, pos_y, font_type) end

---Draws text with the specified scale and rotation
---@param text string
---@param pos_x number
---@param pos_y number
---@param angle number
---@param scale number
---@param font_type ?FontId
function draw_text_angle_scale(text, pos_x, pos_y, angle, scale, font_type) end

---Built-in function to draw text in a box
---@param text string
---@param pos_x number
---@param pos_y number
---@param box_width number
---@param box_height number
---@param line_height number
---@param font_type ?FontId
function draw_boxed_text(text, pos_x, pos_y, box_width, box_height, line_height, font_type) end

---Draws text in 3D world
---@param text string
---@param x number
---@param y number
---@param z number
---@param ax number
---@param ay number
---@param az number
---@param size number
---@param font_type FontId
function draw_text_3d(text, x, y, z, ax, ay, az, size, font_type) end

---Activates a 3D viewport for subsequent draw calls
---@param pos_x number
---@param pos_y number
---@param size_x number
---@param size_y number
function set_viewport(pos_x, pos_y, size_x, size_y) end

---@alias ColorId
---| 0	COLOR_NONE
---| 1	COLOR_WHITE
---| 2	COLOR_RED
---| 3	COLOR_DARK_RED
---| 4	COLOR_BLUE | Vortex
---| 5	COLOR_DARK_BLUE
---| 6	COLOR_PURPLE
---| 7	COLOR_BLACK
---| 8	COLOR_GREY
---| 9	COLOR_YELLOW | Static
---| 10	COLOR_GREEN | Spring
---| 11	COLOR_NEPTUNE
---| 12	COLOR_ECTO
---| 13	COLOR_SPRING
---| 14	COLOR_VIOLET
---| 15	COLOR_PINK
---| 16	COLOR_ORANGE | Copper
---| 17	COLOR_SKIN
---| 18	COLOR_LIGHT_ORANGE
---| 19	COLOR_BROWN
---| 20	COLOR_BLOOD
---| 21	COLOR_RELAX | Juryo
---| 22	COLOR_RELAX_SEL | Aurora
---| 23	COLOR_HOLD
---| 24	COLOR_HOLD_SEL
---| 25	COLOR_FRACTURE
---| 26	COLOR_ACID
---| 27	COLOR_AMETHYST
---| 28	COLOR_AQUA
---| 29	COLOR_BRONZE
---| 30	COLOR_DEMON
---| 31	COLOR_DRAGON
---| 32	COLOR_ELF
---| 33	COLOR_GOLD
---| 34	COLOR_MARINE
---| 35	COLOR_NOXIOUS
---| 36	COLOR_ORC
---| 37	COLOR_QUICKSILVER
---| 38	COLOR_RADIOACTIVE
---| 39	COLOR_SAPPHIRE
---| 40	COLOR_TOXIC
---| 41	COLOR_VAMPIRE
---| 42	COLOR_CHRONOS
---| 43	COLOR_GAIA
---| 44	COLOR_GLADIATOR
---| 45	COLOR_HYDRA
---| 46	COLOR_PHAROS
---| 47	COLOR_SPHINX
---| 48	COLOR_TITAN
---| 49	COLOR_TYPHON
---| 50	COLOR_PURE
---| 51	COLOR_BOREAL
---| 52	COLOR_WILDFIRE
---| 53	COLOR_BLOSSOM
---| 54	COLOR_TESLA
---| 55	COLOR_HAWK
---| 56	COLOR_DBLUE
---| 57	COLOR_GARNET | Crimson
---| 58	COLOR_HPINK | Raptor
---| 59	COLOR_CERULEAN | Plasma
---| 60	COLOR_LPINK
---| 61	COLOR_PUMPKIN | Amber
---| 62	COLOR_AZURITE
---| 63	COLOR_IVORY
---| 64	COLOR_PARROT | Viridian
---| 65	COLOR_SHAMAN
---| 66	COLOR_SAKURA
---| 67	COLOR_PEACH
---| 68	COLOR_FLAME
---| 69	COLOR_DEEP | Onyx
---| 70	COLOR_RUBY
---| 71	COLOR_CRIMSON | Supernova
---| 72	COLOR_NOVA
---| 73	COLOR_MAROON
---| 74	COLOR_CORAL
---| 75	COLOR_INDIGO | Adamantium
---| 76	COLOR_SANGRIA
---| 77	COLOR_TEXT
---| 78	COLOR_TEXT_BG
---| 79	COLOR_TEXT_SEL
---| 80	COLOR_TEXT_DISABLED
---| 81	COLOR_MENU_TEXT
---| 82	COLOR_MENU_TEXT_BG
---| 83	COLOR_MENU_TEXT_SEL
---| 84	COLOR_MENU_TEXT_DISABLED
---| 85	COLOR_MSG_NOTYPE | Void
---| 86	COLOR_MSG_WHISPER | Imperial
---| 87	COLOR_MSG_SERVER | Platinum
---| 88	COLOR_MSG_SRVURL
---| 89	COLOR_MSG_INGAME | Cobra
---| 90	COLOR_MSG_GAMURL
---| 91	COLOR_MSG_USER
---| 92	COLOR_MSG_PLAYER
---| 93	COLOR_MSG_URL
---| 94	COLOR_MSG_URLSEL
---| 95	COLOR_OPAL | Hunter
---| 96	COLOR_VOID
---| 97	COLOR_ANTIQUEWHITE2 | Ivory
---| 98	COLOR_CADETBLUE3
---| 99	COLOR_CHOCOLATE
---| 100	COLOR_DARKGOLDENROD4 | Old Gold
---| 101	COLOR_DARKOLIVEGREEN | Camo
---| 102	COLOR_DARKSLATEBLUE | Magnetite
---| 103	COLOR_DARKSEAGREEN1
---| 104	COLOR_DARKSLATEGREY | Vulcan
---| 105	COLOR_DEEPPINK3 | Hot Pink
---| 106	COLOR_DODGERBLUE4 | Raider
---| 107	COLOR_HOTPINK4 | Tyrian
---| 108	COLOR_LEMONCHIFFON4 | Kevlar
---| 109	COLOR_LIGHTBLUE3 | Maya
---| 110	COLOR_MIDNIGHTBLUE | Alpha
---| 111	COLOR_PALEVIOLETRED4
---| 112	COLOR_VIOLETRED4
---| 113	COLOR_PURPLE4 | Demolition
---| 114	COLOR_MEDIUMORCHID4 | Persia
---| 115	COLOR_MAGENTA4 | Velvet
---| 116	COLOR_MEDIUMPURPLE3 | Warrior
---| 117	COLOR_THISTLE4
---| 118	COLOR_FIREBRICK3 | Mysterio
---| 119	COLOR_AQUAMARINE
---| 120	COLOR_BURLYWOOD4 | Superfly
---| 121	COLOR_LIGHTPINK4 | Knox
---| 122	COLOR_MEDIUMSPRINGGREEN
---| 123	COLOR_PALEGREEN | Helios
---| 124	COLOR_SGIOLIVEDRAB | Olive
---| 125	COLOR_MONOCHROME | Impure
---| 126	COLOR_OMNI
---| 127	COLOR_ZEAL
---| 128	COLOR_MAGMA
---| 129	COLOR_CRUSHER
---| 130	COLOR_SUPERIOR
---| 131	COLOR_DARK_PURPLE | Astro
---| 132	COLOR_SAKURA2 | Sakura
---| 133	COLOR_MANA
---| 134	COLOR_FOSSIL
---| 135	COLOR_METEOR
---| 136	COLOR_DIAMOND
---| 137	COLOR_IVY
---| 138	COLOR_RUIN
---| 139	COLOR_HERA

---@alias RenderEffectId
---| 0 None
---| 1 Cel Shaded
---| 2 Fresnel Glow
---| 3 Cel Shaded + Fresnel Glow
---| 4 Dithering
---| 5 Cel Shaded + Dithering
---| 6 Fresnel Glow + Dithering
---| 7 Cel Shaded + Fresnel Glow + Dithering

---Sets the rendering effects for subsequent 3D drawing calls
---@param effectid RenderEffectId
---@param glow_colorid ?ColorId
---@param glow_intensity ?number
---@param dither_pixelsize ?integer
function set_draw_effect(effectid, glow_colorid, glow_intensity, dither_pixelsize) end

---Draws a 3D cube with the specified settings (use Euler angles)
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param size_x number
---@param size_y number
---@param size_z number
---@param rot_x ?number
---@param rot_y ?number
---@param rot_z ?number
---@param texture_id ?integer Texture id retrieved from `load_texture()` call
function draw_box(pos_x, pos_y, pos_z, size_x, size_y, size_z, rot_x, rot_y, rot_z, texture_id) end

---Draws a 3D cube with the specified settings (use rotation matrix)
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param size_x number
---@param size_y number
---@param size_z number
---@param rot_matrix ?Matrix4x4
---@param texture_id ?integer Texture id retrieved from `load_texture()` call
function draw_box_m(pos_x, pos_y, pos_z, size_x, size_y, size_z, rot_matrix, texture_id) end

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

---Draws a 2D disk in a 3D world
---@param pos_x number Center X position for drawing
---@param pos_y number Center Y position for drawing
---@param pos_z number Center Z position for drawing
---@param inner number Pixel offset from center to start the drawing from
---@param outer number Pixel offset from center to end the drawing at
---@param slices integer Number of slices for the drawn disk (higher amount = smoother edge)
---@param loops integer
---@param start number Start angle for the drawing
---@param sweep number Disk length in degrees
---@param blend integer
function draw_disk_3d(pos_x, pos_y, pos_z, inner, outer, slices, loops, start, sweep, blend) end

---Draws a 3D sphere with the specified settings (use Euler angles)
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param radius number
---@param rotation_x ?number
---@param rotation_y ?number
---@param rotation_z ?number
---@param texture_id ?integer Texture id retrieved from `load_texture()` call
function draw_sphere(pos_x, pos_y, pos_z, radius, rotation_x, rotation_y, rotation_z, texture_id) end

---Draws a 3D sphere with the specified settings (use rotation matrix)
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param radius number
---@param rotation_matrix ?Matrix4x4
---@param texture_id ?integer Texture id retrieved from `load_texture()` call
function draw_sphere_m(pos_x, pos_y, pos_z, radius, rotation_matrix, texture_id) end

---Draws a 3D capsule with the specified settings (use Euler angles)
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param length number
---@param radius number
---@param rot_x ?number
---@param rot_y ?number
---@param rot_z ?number
---@param texture_id ?integer Texture id retrieved from `load_texture()` call
function draw_capsule(pos_x, pos_y, pos_z, length, radius, rot_x, rot_y, rot_z, texture_id) end

---Draws a 3D capsule with the specified settings (use rotation matrix)
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param length number
---@param radius number
---@param rot_matrix ?Matrix4x4
---@param texture_id ?integer Texture id retrieved from `load_texture()` call
function draw_capsule_m(pos_x, pos_y, pos_z, length, radius, rot_matrix, texture_id) end

---Draws a 3D model with the specified settings (use Euler angles)
---@param model_id integer Object id retrieved from `load_obj()`
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param size_x number
---@param size_y number
---@param size_z number
---@param rot_x ?number
---@param rot_y ?number
---@param rot_z ?number
function draw_obj(model_id, pos_x, pos_y, pos_z, size_x, size_y, size_z, rot_x, rot_y, rot_z) end

---Draws a 3D model with the specified settings (use rotation matrix)
---@param model_id integer Object id retrieved from `load_obj()`
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param size_x number
---@param size_y number
---@param size_z number
---@param rot_matrix ?Matrix4x4
function draw_obj_m(model_id, pos_x, pos_y, pos_z, size_x, size_y, size_z, rot_matrix) end

---Loads a TGA texture by the specified path
---@param path string
---@return integer #Texture id or -1 on error
function load_texture(path) end

---Generates a texture gradient between two specified colors
---@param r1 number
---@param g1 number
---@param b1 number
---@param a1 number
---@param r2 number
---@param g2 number
---@param b2 number
---@param a2 number
---@param body ?PlayerBody
---@overload fun(col1:ColorId, col2:ColorId, body:PlayerBody?)
function generate_texture_gradient(r1, g1, b1, a1, r2, g2, b2, a2, body) end

---Unloads a texture with the specified id
---@param id integer
function unload_texture(id) end

---Loads a 3D model and all associated textures from the specified path and links it on success
---@param obj_id integer Object id the model will be linked to
---@param filename string
---@param absolute integer If `1`, will use the `filename` as an absolute path to the model
---@return boolean
function load_obj(obj_id, filename, absolute) end

---Unloads the 3D model linked to the specified id
---@param obj_id integer
function unload_obj(obj_id) end

---Draws a DQ ring for the specified player
---@param player integer
---@param age ?number
function draw_ground_impact(player, age) end

---Clears DQ ring for the specified player or all players by default
---@param player ?integer
function clear_ground_impact(player) end


--[[ TEXT FUNCTIONS ]]

---Returns on-screen text length in pixels according to specified settings
---@param message string
---@param font FontId
---@param raw ?boolean If true, will ignore current graphics DPI setting
---@return number
function get_string_length(message, font, raw) end

---Converts an RTL string
---@param text string
function convert_rtl(text) end

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

---@alias CameraMode
---| 0 Normal camera
---| 1 Tori camera
---| 2 Uke camera
---| 3 Free camera
---| 4 Free orbital camera

---Activates the specified camera mode
---@param mode CameraMode
function set_camera_mode(mode) end

---Resets camera back to Normal mode
---@param factor number
function reset_camera(factor) end

---Activates Torishop camera mode and sets the specified angle
---@param angle number
function start_torishop_camera(angle) end

---@class CameraInfoMisc
---@field hyp number
---@field angle number

---@class CameraInfo
---@field pos Vector3 Camera look from point
---@field lookat Vector3 Camera look at point
---@field perp Vector3
---@field other CameraInfoMisc

---Returns current camera information
---@return CameraInfo
function get_camera_info() end

---Sets look from position for the camera
---@param x number
---@param y number
---@param z number
function set_camera_pos(x, y, z) end

---Sets look at position for the camera
---@param x number
---@param y number
---@param z number
function set_camera_lookat(x, y, z) end

---Sets camera range
---@param min number
---@param max number
---@param speed ?number
function set_camera_range(min, max, speed) end

---Sets camera angle in degrees
---@param angle number
function set_camera_angle(angle) end

---@class CameraKeyFrame
---@field frame number
---@field pos Vector3
---@field lookat Vector3

---Returns a table containing information on all store camera keyframes
---@return CameraKeyFrame[]
function get_camera_keyframes() end

---@class CameraDepthOfFieldInfo
---@field supported integer
---@field focal_length number
---@field fstop number

---Enables depth of field on supported devices
---@param focal_length number
---@param fstop number
---@return CameraDepthOfFieldInfo
function enable_depth_of_field(focal_length, fstop) end

---Disables depth of field
---@return CameraDepthOfFieldInfo
function disable_depth_of_field() end


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
---@param joint PlayerJoint
---@return integer x
---@return integer y
---@return integer z
function get_joint_screen_pos(player, joint) end

---Returns screen position of a specified player bodypart
---@param player integer
---@param body PlayerBody
---@return integer x
---@return integer y
---@return integer z
function get_body_screen_pos(player, body) end

--[[ GAME FUNCTIONS ]]

---@alias WorldStateGameType
---| 0 Single Player
---| 1 Multi Player

---@alias WorldStateWinner
---| -1	No winner | Draw
---| 0	Tori
---| 1	Uke

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
---@param body PlayerBody
---@return BodyInfo
function get_body_info(player, body) end

---Returns player body linear velocity
---@param player integer
---@param body PlayerBody
---@return number x
---@return number y
---@return number z
function get_body_linear_vel(player, body) end

---Sets player body linear velocity
---@param player integer
---@param body PlayerBody
---@param x number
---@param y number
---@param z number
function set_body_linear_vel(player, body, x, y, z) end

---Returns player body angular velocity
---@param player integer
---@param body PlayerBody
---@return number x
---@return number y
---@return number z
function get_body_angular_vel(player, body) end

---Sets player body angular velocity
---@param player integer
---@param body PlayerBody
---@param x number
---@param y number
---@param z number
function set_body_angular_vel(player, body, x, y, z) end

---Applies force to player body
---@param player integer
---@param body PlayerBody
---@param x number
---@param y number
---@param z number
function set_body_force(player, body, x, y, z) end

---Sets torque for the player body
---@param player integer
---@param body PlayerBody
---@param x number
---@param y number
---@param z number
function set_body_torque(player, body, x, y, z) end

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
---@param joint PlayerJoint
---@return JointInfo
function get_joint_info(player, joint) end

---Returns joint dismember state
---@param player integer
---@param joint PlayerJoint
---@return boolean
function get_joint_dismember(player, joint) end

---Returns joint fracture state
---@param player integer
---@param joint PlayerJoint
---@return boolean
function get_joint_fracture(player, joint) end

---Sets joint state for the specified player
---@param player integer
---@param joint PlayerJoint
---@param state PlayerJointState
---@param with_onchange_effects ?boolean Whether to automatically rewind ghost and play joint change state sound
function set_joint_state(player, joint, state, with_onchange_effects) end

---Returns a joint-specific readable state name
---@param joint PlayerJoint
---@param state PlayerJointState
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
---@param joint PlayerJoint
---@return number x
---@return number y
---@return number z
---@nodiscard
function get_joint_pos(player, joint) end

---Returns joint position in 3D world as Vector3
---@param player integer
---@param joint PlayerJoint
---@return Vector3
---@nodiscard
function get_joint_pos2(player, joint) end

---Returns joint radius
---@param player integer
---@param joint PlayerJoint
---@return number
function get_joint_radius(player, joint) end

---Selects player with the corresponding id
---@param player integer Player ID or `-1` to deselect all players
function select_player(player) end

---Disables selection of player with the corresponding id
---@param player integer Player ID or `-1` to enable selection for all players
function disable_player_select(player) end

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

---Opens and plays the replay
---@param filename string
---@param cache? integer
---@param check_integrity_threshold? number Replay integrity checker threshold. Lower value means higher precision.
function open_replay(filename, cache, check_integrity_threshold) end

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
---| 0	None
---| 1	DQ
---| 2	Dismemberment
---| 3	DQ + Dismemberment
---| 4	No grip
---| 5	DQ + No grip
---| 6	Dismemberment + No grip
---| 7	DQ + Dismemberment + No grip
---| 8	Fracture
---| 9	DQ + Fracture
---| 10	Dismemberment + Fracture
---| 11	DQ + Dismemberment + Fracture
---| 12	No grip + Fracture
---| 13	DQ + No grip + Fracture
---| 14	Dismemberment + No grip + Fracture
---| 15	DQ + Dismemberment + No grip + Fracture

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

---Sets score for the specified player
---@param player integer
---@param score integer
function set_score(player, score) end

---Returns current player score
---@return number
function get_score(player) end

---Disqualifies the specified player
---@param player integer
function set_dq(player) end

---Forces the specified player to relax all joints
---@param player integer
function relax_player(player) end


--[[ BLOOD ]]

---Returns ids of all active blood particles
---@return integer[]
function get_active_bloods() end

---Returns age of the specified blood particle id
---@param particle_id integer
---@return number
function get_blood_age(particle_id) end

---Returns radius of the specified blood particle
---@param particle_id integer
---@return number
function get_blood_radius(particle_id) end

---Returns blood particle position
---@param particle_id integer
---@return number x
---@return number y
---@return number z
function get_blood_pos(particle_id) end

---Returns blood particle linear velocity
---@param particle_id integer
---@return number x
---@return number y
---@return number z
function get_blood_vel(particle_id) end


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
---@param player integer
---@param joint PlayerJoint
---@return ColorId force_color
---@return ColorId relax_color
function get_joint_colors(player, joint) end

---@deprecated
---@param player integer
---@param joint PlayerJoint
---@return table
---This function will be removed in future releases
function get_joint_color(player, joint) end

---@class ColorInfo
---@field name string
---@field game_name string
---@field r number
---@field g number
---@field b number

---Returns information about a Toribash color
---@param colorid ColorId
---@return ColorInfo
function get_color_info(colorid) end

---Returns RGBA values of a Toribash color
---@param colorid ColorId
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

---Retrieves a list of currently active downloads
---@return string[]
function get_downloads() end

---Clears download queue. This **will not** cancel the ongoing download request.
function clear_download() end

---Downloads a Toribash mod by its name
---@param modname string
function download_mod(modname) end

---Downloads a Toribash replay by its id and saves it using the specified name
---@param id integer
---@param name string
function download_replay(id, name) end

---Fetches the list of replays that match the provided settings\
---@see Request
---@param start_id integer
---@param offset integer
---@param search ?string
function fetch_replay_results(start_id, offset, search) end

---@deprecated
---To be removed in future releases, use `fetch_replay_results()` instead
---@param id integer
---@param offset integer
---@param search string
function download_replay_result(id, offset, search) end

---Fetches comments for the specified replay id \
---@see Request
---@param id integer
function fetch_replay_comments(id) end

---@deprecated
---To be removed in future releases, use `fetch_replay_comments()` instead
---@param id integer
function download_replay_comments(id) end

---Launches a network request to update current user's TC and ST balance
function update_tc_balance() end

---Queues player's head texture for download
---@param username string
function download_head(username) end

---Downloads a data file from Toribash servers
---@param request string
---@param mode integer
function download_server_file(request, mode) end

---Fetches information from Toribash servers\
---@see Request
---@param request string
function download_server_info(request) end

---Fetches Market-specific information from Toribash servers\
---@see Request
---@param request string
function download_market_info(request) end

---Sends a request to retrieve the latest available game version\
---@see Request
function get_latest_version() end

---Returns received data from the last network request\
---@see Request
---@return string
function get_network_response() end

---Returns last network request error\
---@see Request
---@return string
function get_network_error() end

---Reports whether we have an active network task\
---@see Request
---@return integer
function get_network_task() end

---Opens a webpage with user's default browser \
---*Only Toribash links are supported*
---@param url string
function open_url(url) end

---Downloads bounties data and saves it as `data/bounties.txt`
function download_fetch_bounties() end

---Downloads quests data for the specified user
---@param username string
function download_quest(username) end

---Sends a request to claim quest reward
---@param questid integer
function claim_quest(questid) end

---Downloads global quests data for the current user and saves it as `data/quests_global.dat`
function download_global_quests() end

---Downloads general Torishop data and models data
function download_torishop() end

---Downloads inventory datafile for the specified user or current user if no username is specified.
---
---*Current user's inventory is saved to `data/script/torishop/invent.txt`* \
---*Other users' inventory is saved to `data/script/torishop/uinvent.tmp`*
---@param username ?string
function download_inventory(username) end

---Initiates a network request to upload a replay to Toribash servers
---@param name string
---@param description string
---@param tags string
---@param filename string
function upload_replay(name, description, tags, filename) end

---Initiates a network request to upload an event replay to Toribash servers
---@param name string
---@param description string
---@param tags string
---@param filename string
function upload_event_replay(name, description, tags, filename) end

---Downloads clans datafile
function download_clan() end

---Downloads clan logo texture by the specified clan id. \
---*Texture will be saved to `data/textures/clans` directory as `%clanid%.tga`*
---@param clanid integer
function download_clan_logo(clanid) end

---Claims daily login reward, if available
function claim_reward() end

---Claims all available Battle Pass rewards
function battlepass_claim_reward() end

---Fetches ranking toplist for the specified user or the current user by default\
---@see Request
---@param username ?string
function fetch_ranking_toplist(username) end

---Fetches ranking trends for the current user\
---@see Request
function fetch_ranking_trends() end

---Sends a network request to check whether current user qualifies for the specified color's achievement
---@param colorid ?ColorId
function check_color_achievement(colorid) end

---Sends a network request to check whether current user qualifies for global achievements
function check_global_achievements() end

---Submits a player report
---@param name string
---@param reason string
---@param message string
---@param filename ?string
function report_player(name, reason, message, filename) end

---Starts texture upload for the specified inventory item
---@param inventid integer
---@param filepath string
function upload_item_texture(inventid, filepath) end

---Starts texture upload for the specified target
---@param target string
---@param filepath string
function upload_texture_image(target, filepath) end

---Submits item purchase request for Toricredits
---@param data string
function buy_tc(data) end

---Submits item purchase request for Shiai Tokens
---@param data string
function buy_st(data) end

---Queries information about the specified user from Toribash servers. \
---*Leave username empty to request current user info.* \
---@see PlayerInfo.getServerUserinfo
---@param username ?string
function get_player_userinfo(username) end


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

---Returns whether either of ctrl keys is currently down
---@return integer
function get_keyboard_shift() end

---Returns whether caps lock is currently on
---@return integer
function get_keyboard_capslock() end

---Returns whether num lock is currently on
---@return integer
function get_keyboard_numlock() end

---Returns whether scroll lock is currently on
---@return integer
function get_keyboard_scrolllock() end

---Returns whether either of alt keys is currently on
---@return integer
function get_keyboard_alt() end

---Returns whether either of gui keys is currently down
---@return integer
function get_keyboard_gui() end

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

---@alias GameOption
---| "altimeter"
---| "speedometer"
---| "damagemeter"
---| "scoringmeter"
---| "hud"
---| "gui"
---| "score"
---| "timer"
---| "chat"
---| "spectator"
---| "debug"
---| "name"
---| "emote"
---| "shout"
---| "button"
---| "text"
---| "hint"
---| "feedback"
---| "message"
---| "info"
---| "replayspeed"
---| "cursor"
---| "p4"
---| "p3"
---| "uke"
---| "tori"
---| "blood"
---| "sound"
---| "mousebuttons"
---| "backgroundclick"
---| "rumble"
---| "music"
---| "smartcam"
---| "width"
---| "height"
---| "antialiasing"
---| "benchmark"
---| "fullscreen"
---| "autosave"
---| "rememberrules"
---| "autoupdate"
---| "bruise"
---| "motionblur"
---| "bloodstains"
---| "exhibition"
---| "reflection"
---| "smoothcam"
---| "framerate"
---| "avatar"
---| "fluid"
---| "softshadow"
---| "ambientocclusion"
---| "bumpmapping"
---| "bodytextures"
---| "depthoffield"
---| "anaglyphic"
---| "shaders"
---| "noreload"
---| "equipment"
---| "money"
---| "turnalert"
---| "beginner"
---| "animatedhead"
---| "floortexture"
---| "fixedframerate"
---| "particles"
---| "trails"
---| "keyframes"
---| "ghostcache"
---| "replaycache"
---| "bloodstainremove"
---| "chatcache"
---| "filesort"
---| "raytracing"
---| "hair"
---| "obj"
---| "grip"
---| "flag"
---| "dl"
---| "hairquality"
---| "language"
---| "languagesteam"
---| "worldshader"
---| "effects"
---| "ghostenvobj"
---| "realtimeghost"
---| "newshopitem"
---| "matchmakerx"
---| "matchmakery"
---| "matchmakerhidden"
---| "chatfocus"
---| "clanuipopup"
---| "gleeinit"
---| "blur"
---| "newmenu"
---| "memsize"
---| "matchmakechat"
---| "discordjoin"
---| "comicfx"
---| "highdpi"
---| "keyboardlayout"
---| "focuscam"
---| "personal"
---| "tooltip"
---| "movememory"
---| "soundvolume"
---| "musicvolume"
---| "voicevolume"
---| "chattoggle"
---| "voicetoggle"
---| "chatcensor"
---| "objshadow"
---| "showbroadcast"
---| "uilight"
---| "menudebug"
---| "jointflash"
---| "grnewgame"
---| "replayhudtoggle"
---| "borderless"
---| "dpiscale"
---| "playertext"
---| "dpiawareness"
---| "itemeffects"
---| "usagestats"
---| "jointobjopacity"
---| "systemcursor"
---| "aidifficulty" Toribash builds with AI fight mode only
---| "hudoffset" Mobile platforms only

---Retrieves a value of the specified Toribash option
---@param value GameOption
---@return string
function get_option(value) end

---Sets value for the specified Toribash option
---@param option GameOption
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


--[[ ROOM QUEUE FUNCTIONS ]]

---@class QueuePlayerInfo
---@field nick string Player name
---@field games_played integer Player Qi
---@field rank integer Player rank
---@field streak integer Current win streak
---@field custombeltname string Custom belt name (players with 20,000 Qi or more)
---@field admin boolean Whether this user is an in-game administrator
---@field op boolean Whether this user is a room operator
---@field halfop boolean Whether this user is a half-operator
---@field legend boolean Whether this user is a legend
---@field eventsquad boolean Whether this user is a part of Event Squad
---@field helpsquad boolean Whether this user is a part of Help Squad
---@field marketsquad boolean Whether this user is a part of Market Squad
---@field muted boolean Whether this user is muted
---@field afk boolean Whether this user is afk
---@field multiclient boolean Whether this user is currently multiclienting

---Returns a list of all queue players' names for the room
---@return string[]
function get_bouts() end

---Returns information about queue player by their id in the list
---@param bout_id integer
---@return QueuePlayerInfo
function get_bout_info(bout_id) end

---Returns a list of all spectators' names for the room
---@return string[]
function get_spectators() end

---Returns information about queue spectator by their id in the list
---@param spectator_id integer
---@return QueuePlayerInfo
function get_spectator_info(spectator_id) end


--[[ CHAT FUNCTIONS ]]

---Enables chat input hotkey
function chat_input_activate() end

---Disables chat input hotkey
function chat_input_deactivate() end

---Returns chat input active state
---@return boolean
function chat_input_is_active() end

---Clears chat input
function chat_input_clear() end

---Returns the last 100 messages sent from current client
---@return string[]
function get_chat_history() end

---Adds the message to the chat history
---@param msg string
function add_chat_history(msg) end

---Draws default chat messages at the specified position
---@param x number
---@param y number
function draw_chat_messages(x, y) end

---Draws the specified message id at a position
---@param id integer
---@param x number
---@param y number
function draw_chat_message(id, x, y) end

---@return integer
function get_total_chat_lines() end

---@return integer
function get_cur_chat_lines() end

---@return integer
function get_compact_chat_lines() end

---@return integer
function get_full_mode_chat_lines() end

---Returns message type for the specified message id
---@param id integer
---@return ChatMessageType
function get_chat_type(id) end


--[[ SOUND FUNCTIONS ]]

---Plays a Toribash sound by its ID
---@param soundid integer
---@param volume ?number
function play_sound(soundid, volume) end

---Returns current game volume level
---@return integer
function get_volume() end

---Sets game volume level
---@param volume integer
function set_volume(volume) end

---Disables all game sounds
function disable_sound() end

---Enables game sounds
function enable_sound() end


--[[ DISCORD FUNCTIONS ]]

---Sets Discord Rich Presence state \
---*Only supported on Windows*
---@param state string
---@param detail string
function set_discord_rpc(state, detail) end

---Accepts Discord join request \
---*Only supported on Windows*
---@param discordId string
function discord_accept_join(discordId) end

---Refuses Discord join request \
---*Only supported on Windows*
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
---| "replaycheck" #Called when replay hacking is detected during replay playthrough with check_integrity mode enabled

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


--[[ OTHER FUNCTIONS ]]

---@return boolean
function is_steam() end

---@return boolean
function is_steam_logon() end

---@return boolean
function is_mobile() end

---@alias PlayerMasterOption
---| 'nick'
---| 'rank'
---| 'elo'
---| 'season_win'
---| 'season_lose'
---| 'days'
---| 'available'
---| 'seconds'
---| 'tc'
---| 'st'
---| 'qi'
---| 'clanid'
---| 'clan_name'

---@class PlayerMasterInfo
---@field nick string Current user's name
---@field rank integer Current user's rank
---@field elo number Current user's elo rating
---@field season_win integer Current user's ranked wins this season
---@field season_lose integer Current user's ranked losses this season
---@field days integer Current user's login reward streak
---@field available integer Login reward availability status
---@field seconds integer Time left until daily reward expiry
---@field tc integer Current user's ToriCredit balance
---@field st integer Current user's Shiai Token balance
---@field qi integer Current user's Qi
---@field clanid integer Current user's clan id
---@field clan_name string Current user's clan name

---@class PlayerMaster
---@field master PlayerMasterInfo

---Returns master info about the current user
---@return PlayerMaster
function get_master() end

---@class MatchmakerInfo
---@field matching integer Total number of players searching for a match
---@field ranked integer
---@field grappling integer
---@field kicking integer
---@field striking integer

---@class MatchmakerData
---@field info MatchmakerInfo

---Returns matchmaker information
---@return MatchmakerData
function get_matchmaker() end

---Returns a list of files in specified directory
---@param directory string
---@param suffix string
---@return string[]
function get_files(directory, suffix) end

---Attempts to enable screen blur
---@return boolean #Whether blur is supported
function enable_blur() end

---Disables screen blur
function disable_blur() end

---Prints a local chat message
---@param message string
---@param tab ?integer
function echo(message, tab) end

---Executes a game command
---@param command string
---@param online ?integer
---@param silent ?boolean
function run_cmd(command, online, silent) end

---Executes a `/reset` command in a Multiplayer room
function reset_server() end

---@param event string
---@param value ?integer
function usage_event(event, value) end

---Triggers haptics with the specified settings on supported devices. \
---See `HAPTICS` table for supported haptics types.
---@param strength number
---@param type ?HapticsType
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

---Returns screen coordinates of a point in 3D world. \
---**Must be called from a `draw3d` callback.**
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@return integer x
---@return integer y
---@return integer z
function get_screen_pos(pos_x, pos_y, pos_z) end

---Returns current tutorial level. *Steam only.*
function get_tutorial_level() end

---Sets highest tutorial level. *Steam only.*
---@param value integer
function set_tutorial_level(value) end

---Returns Steam stat value by its name
---@param name string
---@return number|nil
function get_steam_stat(name) end

---Awards an achievement to user if prerequisites are met
---@param id integer
function award_achievement(id) end

---Returns in-app purchase finalized status
function get_purchase_done() end

---Runs a legacy tutorial by its id
---@param id integer
function run_tutorial(id) end

---Opens platform-specific file browser to select a file that matches the specified extensions
---@param description ?string
---@param extensions ?string `;`-separated list of supported file extensions
---@param ... string Additional description + extension pairs
---@return boolean #Whether file browser is supported on current platform
function open_file_browser(description, extensions, ...) end
