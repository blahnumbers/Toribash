---@meta
---This file contains documentation for all Toribash-specific Lua functions and global variables
---You DO NOT need to include this file in any of your scripts, it is only used by EmmyLua plugins
---https://github.com/LuaLS/lua-language-server

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

---Script launch argument will be here
---@type string
_G.ARG = nil

---Additional launch argument used by main menu
---@type string
_G.ARG1 = nil

---Default Toribash fonts
_G.FONTS = {
	BIG = 0,
	SMALL = 1,
	MEDIUM = 2,
	LMEDIUM = 4,
	BIGGER = 9
}

---Toribash game colors
_G.COLORS = {
	NONE = 0,
	WHITE = 1,
	RED = 2,
	DARK_RED = 3,
	BLUE = 4,
	DARK_BLUE = 5,
	PURPLE = 6,
	BLACK = 7,
	GREY = 8,
	YELLOW = 9,
	GREEN = 10,
	NEPTUNE = 11,
	ECTO = 12,
	SPRING = 13,
	VIOLET = 14,
	PINK = 15,
	ORANGE = 16,
	SKIN = 17,
	LIGHT_ORANGE = 18,
	BROWN = 19,
	BLOOD = 20,
	RELAX = 21,
	RELAX_SEL = 22,
	HOLD = 23,
	HOLD_SEL = 24,
	FRACTURE = 25,
	ACID = 26,
	AMETHYST = 27,
	AQUA = 28,
	BRONZE = 29,
	DEMON = 30,
	DRAGON = 31,
	ELF = 32,
	GOLD = 33,
	MARINE = 34,
	NOXIOUS = 35,
	ORC = 36,
	QUICKSILVER = 37,
	RADIOACTIVE = 38,
	SAPPHIRE = 39,
	TOXIC = 40,
	VAMPIRE = 41,
	CHRONOS = 42,
	GAIA = 43,
	GLADIATOR = 44,
	HYDRA = 45,
	PHAROS = 46,
	SPHINX = 47,
	TITAN = 48,
	TYPHON = 49,
	PURE = 50,
	BOREAL = 51,
	WILDFIRE = 52,
	BLOSSOM = 53,
	TESLA = 54,
	HAWK = 55,
	DBLUE = 56,
	GARNET = 57,
	HPINK = 58,
	CERULEAN = 59,
	LPINK = 60,
	PUMPKIN = 61,
	AZURITE = 62,
	IVORY = 63,
	PARROT = 64,
	SHAMAN = 65,
	SAKURA = 66,
	PEACH = 67,
	FLAME = 68,
	DEEP = 69,
	RUBY = 70,
	CRIMSON = 71,
	NOVA = 72,
	MAROON = 73,
	CORAL = 74,
	INDIGO = 75,
	SANGRIA = 76,
	TEXT = 77,
	TEXT_BG = 78,
	TEXT_SEL = 79,
	TEXT_DISABLED = 80,
	MENU_TEXT = 81,
	MENU_TEXT_BG = 82,
	MENU_TEXT_SEL = 83,
	MENU_TEXT_DISABLED = 84,
	MSG_NOTYPE = 85,
	MSG_WHISPER = 86,
	MSG_SERVER = 87,
	MSG_SRVURL = 88,
	MSG_INGAME = 89,
	MSG_GAMURL = 90,
	MSG_USER = 91,
	MSG_PLAYER = 92,
	MSG_URL = 93,
	MSG_URLSEL = 94,
	OPAL = 95,
	VOID = 96,
	ANTIQUEWHITE2 = 97,
	CADETBLUE3 = 98,
	CHOCOLATE = 99,
	DARKGOLDENROD4 = 100,
	DARKOLIVEGREEN = 101,
	DARKSLATEBLUE = 102,
	DARKSEAGREEN1 = 103,
	DARKSLATEGREY = 104,
	DEEPPINK3 = 105,
	DODGERBLUE4 = 106,
	HOTPINK4 = 107,
	LEMONCHIFFON4 = 108,
	LIGHTBLUE3 = 109,
	MIDNIGHTBLUE = 110,
	PALEVIOLETRED4 = 111,
	VIOLETRED4 = 112,
	PURPLE4 = 113,
	MEDIUMORCHID4 = 114,
	MAGENTA4 = 115,
	MEDIUMPURPLE3 = 116,
	THISTLE4 = 117,
	FIREBRICK3 = 118,
	AQUAMARINE = 119,
	BURLYWOOD4 = 120,
	LIGHTPINK4 = 121,
	MEDIUMSPRINGGREEN = 122,
	PALEGREEN = 123,
	SGIOLIVEDRAB = 124,
	MONOCHROME = 125,
	OMNI = 126,
	ZEAL = 127,
	MAGMA = 128,
	CRUSHER = 129,
	SUPERIOR = 130,
	DARK_PURPLE = 131,
	SAKURA2 = 132,
	MANA = 133,
	FOSSIL = 134,
	METEOR = 135,
	DIAMOND = 136,
	IVY = 137,
	RUIN = 138,
	HERA = 139,
	SUNSTONE = 140,
	DARKBROWN = 141,
	TENNISGREEN = 142,
	WISP = 143,
	PHANTOM = 144,
	ULTRABLUE = 145,
	NEON = 146,
	PASTELRED = 147,
	WENGE = 148,
	BRUNSWICKGREEN = 149,
	GLACIER = 150,
	OVERGREEN = 151,
	RHYTHM = 152,
	BRIAR = 153,
	NUM_COLORS = 154
}

---@alias ChatMessageType
---| 0	MSGTYPE.NONE
---| 1	MSGTYPE.SERVER
---| 2	MSGTYPE.URL
---| 4	MSGTYPE.INGAME
---| 8	MSGTYPE.USER
---| 16	MSGTYPE.PLAYER
---| 32	MSGTYPE.WHISPER
---| 64	MSGTYPE.ECHO

---Message types
_G.MSGTYPE = {
	NONE = 0,
	SERVER = 1,
	URL = 2,
	INGAME = 4,
	USER = 8,
	PLAYER = 16,
	WHISPER = 32,
	ECHO = 64
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

---@alias KeyboardInputType
---| 0 KEYBOARD_INPUT.DEFAULT
---| 1 KEYBOARD_INPUT.ASCII
---| 2 KEYBOARD_INPUT.NUMBERPAD
---| 3 KEYBOARD_INPUT.EMAIL

---On-screen keyboard input types
_G.KEYBOARD_INPUT = {
	DEFAULT = 0,
	ASCII = 1,
	NUMBERPAD = 2,
	EMAIL = 3
}

---@alias KeyboardReturnType
---| 0 KEYBOARD_RETURN.DEFAULT
---| 1 KEYBOARD_RETURN.SEND
---| 2 KEYBOARD_RETURN.DONE
---| 3 KEYBOARD_RETURN.NEXT
---| 4 KEYBOARD_RETURN.SEARCH
---| 5 KEYBOARD_RETURN.CONTINUE

---On-screen keyboard return button types
_G.KEYBOARD_RETURN = {
	DEFAULT = 0,
	SEND = 1,
	DONE = 2,
	NEXT = 3,
	SEARCH = 4,
	CONTINUE = 5
}

---@alias IgnoreMode
---| 1	IGNORE_MODE.CHAT
---| 2	IGNORE_MODE.SOUNDS
---| 3	Chat + Sounds
---| 4	IGNORE_MODE.MODELS
---| 5	Chat + Models
---| 6	Sounds + Models
---| 7	Chat + Sounds + Models
---| 8	IGNORE_MODE.PARTICLES
---| 9	Chat + Particles
---| 10	Sounds + Particles
---| 11	Chat + Sounds + Particles
---| 12	Models + Particles
---| 13	Chat + Models + Particles
---| 14	Sounds + Models + Particles
---| 15	IGNORE_MODE.ALL

---Ignore list predefined modes
_G.IGNORE_MODE = {
	CHAT = 1,
	SOUNDS = 2,
	MODELS = 4,
	PARTICLES = 8,
	ALL = 15
}

---@alias TextureWrapMode
---| 0	TEXTURE_WRAP.CLAMP_TO_EDGE
---| 1	TEXTURE_WRAP.CLAMP_TO_BORDER
---| 2	TEXTURE_WRAP.MIRRORED_REPEAT
---| 3	TEXTURE_WRAP.REPEAT

---Texture wrapping modes
_G.TEXTURE_WRAP = {
	CLAMP_TO_EDGE = 0,
	CLAMP_TO_BORDER = 1,
	MIRRORED_REPEAT = 2,
	REPEAT = 3
}

---@alias InputType
---| 0	INPUT_TYPE.MOUSE
---| 1	INPUT_TYPE.TOUCH
---| 2	INPUT_TYPE.CONTROLLER

---Input method types
_G.INPUT_TYPE = {
	MOUSE = 0,
	TOUCH = 1,
	CONTROLLER = 2
}

---@alias GameOverType
---| 0	GAMEOVER_TYPE.END_SCORE
---| 1	GAMEOVER_TYPE.END_DRAW
---| 2	GAMEOVER_TYPE.END_DQ
---| 3	GAMEOVER_TYPE.END_TRIGGER

---Game over types
_G.GAMEOVER_TYPE = {
	END_SCORE = 0,
	END_DRAW = 1,
	END_DQ = 2,
	END_TRIGGER = 3
}

---@alias CameraMode
---| 0	CAMERA_MODE.DEFAULT
---| 1	CAMERA_MODE.TORI
---| 2	CAMERA_MODE.UKE
---| 3	CAMERA_MODE.FREE
---| 4	CAMERA_MODE.FREE_ORBITAL

---Camera modes
_G.CAMERA_MODE = {
	DEFAULT = 0,
	TORI = 1,
	UKE = 2,
	FREE = 3,
	FREE_ORBITAL = 4
}

---@alias CameraCacheMode
---| 0	CAMERA_CACHE_MODE.NONE
---| 1	CAMERA_CACHE_MODE.PREPARE
---| 2	CAMERA_CACHE_MODE.RECORDING
---| 3	CAMERA_CACHE_MODE.PLAY

---Camera cache modes
_G.CAMERA_CACHE_MODE = {
	NONE = 0,
	PREPARE = 1,
	RECORDING = 2,
	PLAY = 3
}

---Effect Types
_G.EFFECT_TYPE = {
	NONE = 0,
	CELSHADED = 1,
	FRESNEL = 2,
	DITHERING = 4,
	VORONOI = 8,
	COLORSHIFT = 16
}

---@class MatrixTB
---@field r0 number
---@field r1 number
---@field r2 number
---@field r3 number
---@field r4 number
---@field r5 number
---@field r6 number
---@field r7 number
---@field r8 number
---@field r9 number
---@field r10 number
---@field r11 number
---@field r12 number
---@field r13 number
---@field r14 number
---@field r15 number


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

---@alias Draw2DQuadMode
---| 0 Normal
---| 1 Patterned
---| 2 Atlas

---Default function to draw rectangles
---@param pos_x number X coordinate of the top left corner
---@param pos_y number Y coordinate of the top left corner
---@param width number
---@param height number
---@param texture_id ?integer Texture id retrieved from `load_texture()` call
---@param draw_mode ?Draw2DQuadMode
---@param r ?number
---@param g ?number
---@param b ?number
---@param a ?number
---@overload fun(pos_x:number, pos_y:number, atlas_width:number, atlas_width:number, texture_id:integer, draw_mode:1, r:number, g:number, b:number, a:number, width:number, height:number)
---@overload fun(pos_x:number, pos_y:number, atlas_width:number, atlas_width:number, texture_id:integer, draw_mode:2, r:number, g:number, b:number, a:number, width:number, height:number, atlas_anchor_x:number, atlas_anchor_y:number)
function draw_quad(pos_x, pos_y, width, height, texture_id, draw_mode, r, g, b, a) end

---Default function to draw disks or circles
---@param pos_x number Center X position for drawing
---@param pos_y number Center Y position for drawing
---@param inner number Disk center cutout radius in pixels
---@param outer number Disk radius in pixels
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
---| 0		COLORS.NONE
---| 1		COLORS.WHITE
---| 2		COLORS.RED
---| 3		COLORS.DARK_RED
---| 4		COLORS.BLUE | Vortex
---| 5		COLORS.DARK_BLUE
---| 6		COLORS.PURPLE
---| 7		COLORS.BLACK
---| 8		COLORS.GREY
---| 9		COLORS.YELLOW | Static
---| 10		COLORS.GREEN | Spring
---| 11		COLORS.NEPTUNE
---| 12		COLORS.ECTO
---| 13		COLORS.SPRING
---| 14		COLORS.VIOLET
---| 15		COLORS.PINK
---| 16		COLORS.ORANGE | Copper
---| 17		COLORS.SKIN
---| 18		COLORS.LIGHT_ORANGE
---| 19		COLORS.BROWN
---| 20		COLORS.BLOOD
---| 21		COLORS.RELAX | Juryo
---| 22		COLORS.RELAX_SEL | Aurora
---| 23		COLORS.HOLD
---| 24		COLORS.HOLD_SEL
---| 25		COLORS.FRACTURE
---| 26		COLORS.ACID
---| 27		COLORS.AMETHYST
---| 28		COLORS.AQUA
---| 29		COLORS.BRONZE
---| 30		COLORS.DEMON
---| 31		COLORS.DRAGON
---| 32		COLORS.ELF
---| 33		COLORS.GOLD
---| 34		COLORS.MARINE
---| 35		COLORS.NOXIOUS
---| 36		COLORS.ORC
---| 37		COLORS.QUICKSILVER
---| 38		COLORS.RADIOACTIVE
---| 39		COLORS.SAPPHIRE
---| 40		COLORS.TOXIC
---| 41		COLORS.VAMPIRE
---| 42		COLORS.CHRONOS
---| 43		COLORS.GAIA
---| 44		COLORS.GLADIATOR
---| 45		COLORS.HYDRA
---| 46		COLORS.PHAROS
---| 47		COLORS.SPHINX
---| 48		COLORS.TITAN
---| 49		COLORS.TYPHON
---| 50		COLORS.PURE
---| 51		COLORS.BOREAL
---| 52		COLORS.WILDFIRE
---| 53		COLORS.BLOSSOM
---| 54		COLORS.TESLA
---| 55		COLORS.HAWK
---| 56		COLORS.DBLUE
---| 57		COLORS.GARNET | Crimson
---| 58		COLORS.HPINK | Raptor
---| 59		COLORS.CERULEAN | Plasma
---| 60		COLORS.LPINK
---| 61		COLORS.PUMPKIN | Amber
---| 62		COLORS.AZURITE
---| 63		COLORS.IVORY
---| 64		COLORS.PARROT | Viridian
---| 65		COLORS.SHAMAN
---| 66		COLORS.SAKURA
---| 67		COLORS.PEACH
---| 68		COLORS.FLAME
---| 69		COLORS.DEEP | Onyx
---| 70		COLORS.RUBY
---| 71		COLORS.CRIMSON | Supernova
---| 72		COLORS.NOVA
---| 73		COLORS.MAROON
---| 74		COLORS.CORAL
---| 75		COLORS.INDIGO | Adamantium
---| 76		COLORS.SANGRIA
---| 77		COLORS.TEXT
---| 78		COLORS.TEXT_BG
---| 79		COLORS.TEXT_SEL
---| 80		COLORS.TEXT_DISABLED
---| 81		COLORS.MENU_TEXT
---| 82		COLORS.MENU_TEXT_BG
---| 83		COLORS.MENU_TEXT_SEL
---| 84		COLORS.MENU_TEXT_DISABLED
---| 85		COLORS.MSG_NOTYPE | Void
---| 86		COLORS.MSG_WHISPER | Imperial
---| 87		COLORS.MSG_SERVER | Platinum
---| 88		COLORS.MSG_SRVURL
---| 89		COLORS.MSG_INGAME | Cobra
---| 90		COLORS.MSG_GAMURL
---| 91		COLORS.MSG_USER
---| 92		COLORS.MSG_PLAYER
---| 93		COLORS.MSG_URL
---| 94		COLORS.MSG_URLSEL
---| 95		COLORS.OPAL | Hunter
---| 96		COLORS.VOID
---| 97		COLORS.ANTIQUEWHITE2 | Ivory
---| 98		COLORS.CADETBLUE3
---| 99		COLORS.CHOCOLATE
---| 100	COLORS.DARKGOLDENROD4 | Old Gold
---| 101	COLORS.DARKOLIVEGREEN | Camo
---| 102	COLORS.DARKSLATEBLUE | Magnetite
---| 103	COLORS.DARKSEAGREEN1
---| 104	COLORS.DARKSLATEGREY | Vulcan
---| 105	COLORS.DEEPPINK3 | Hot Pink
---| 106	COLORS.DODGERBLUE4 | Raider
---| 107	COLORS.HOTPINK4 | Tyrian
---| 108	COLORS.LEMONCHIFFON4 | Kevlar
---| 109	COLORS.LIGHTBLUE3 | Maya
---| 110	COLORS.MIDNIGHTBLUE | Alpha
---| 111	COLORS.PALEVIOLETRED4
---| 112	COLORS.VIOLETRED4
---| 113	COLORS.PURPLE4 | Demolition
---| 114	COLORS.MEDIUMORCHID4 | Persia
---| 115	COLORS.MAGENTA4 | Velvet
---| 116	COLORS.MEDIUMPURPLE3 | Warrior
---| 117	COLORS.THISTLE4
---| 118	COLORS.FIREBRICK3 | Mysterio
---| 119	COLORS.AQUAMARINE
---| 120	COLORS.BURLYWOOD4 | Superfly
---| 121	COLORS.LIGHTPINK4 | Knox
---| 122	COLORS.MEDIUMSPRINGGREEN
---| 123	COLORS.PALEGREEN | Helios
---| 124	COLORS.SGIOLIVEDRAB | Olive
---| 125	COLORS.MONOCHROME | Impure
---| 126	COLORS.OMNI
---| 127	COLORS.ZEAL
---| 128	COLORS.MAGMA
---| 129	COLORS.CRUSHER
---| 130	COLORS.SUPERIOR
---| 131	COLORS.DARK_PURPLE | Astro
---| 132	COLORS.SAKURA2 | Sakura
---| 133	COLORS.MANA
---| 134	COLORS.FOSSIL
---| 135	COLORS.METEOR
---| 136	COLORS.DIAMOND
---| 137	COLORS.IVY
---| 138	COLORS.RUIN
---| 139	COLORS.HERA
---| 140	COLORS.SUNSTONE
---| 141	COLORS.DARKBROWN
---| 142	COLORS.TENNISGREEN
---| 143	COLORS.WISP
---| 144	COLORS.PHANTOM
---| 145	COLORS.ULTRABLUE
---| 146	COLORS.NEON
---| 147	COLORS.PASTELRED
---| 148	COLORS.WENGE
---| 149	COLORS.BRUNSWICKGREEN
---| 150	COLORS.GLACIER
---| 151	COLORS.OVERGREEN
---| 152	COLORS.RHYTHM
---| 153	COLORS.BRIAR

---@alias RenderEffectId
---| 0	EFFECT_TYPE.NONE | None
---| 1	EFFECT_TYPE.CELSHADED | Toon Shaded
---| 2	EFFECT_TYPE.FRESNEL | Glow
---| 3	Toon Shaded + Glow
---| 4	EFFECT_TYPE.DITHERING | Dithering
---| 5	Toon Shaded + Dithering
---| 6	Glow + Dithering
---| 7	Toon Shaded + Glow + Dithering
---| 8	EFFECT_TYPE.VORONOI | Ripples
---| 9	Toon Shaded + Ripples
---| 10	Glow + Ripples
---| 11	Toon Shaded + Glow + Ripples
---| 12	Dithering + Ripples
---| 13	Toon Shaded + Dithering + Ripples
---| 14	Glow + Dithering + Ripples
---| 15	Toon Shaded + Glow + Dithering + Ripples
---| 16	EFFECT_TYPE.COLORSHIFT | Color Shift
---| 17	Toon Shaded + Color Shift
---| 18	Glow + Color Shift
---| 19	Toon Shaded + Glow + Color Shift
---| 20	Dithering + Color Shift
---| 21	Toon Shaded + Dithering + Color Shift
---| 22	Glow + Dithering + Color Shift
---| 23	Toon Shaded + Glow + Dithering + Color Shift
---| 24	Ripples + Color Shift
---| 25	Toon Shaded + Ripples + Color Shift
---| 26	Glow + Ripples + Color Shift
---| 27	Toon Shaded + Glow + Ripples + Color Shift
---| 28	Dithering + Ripples + Color Shift
---| 29	Toon Shaded + Dithering + Ripples + Color Shift
---| 30	Glow + Dithering + Ripples + Color Shift
---| 31	Toon Shaded + Glow + Dithering + Ripples + Color Shift

---Sets the rendering effects for subsequent 3D drawing calls
---@param effectid RenderEffectId
---@param glow_colorid ?ColorId
---@param glow_intensity ?number
---@param dither_pixelsize ?integer
---@param voronoi_scale ?number
---@param voronoi_fresnel ?boolean
---@param voronoi_colorid ?ColorId
---@param shift_colorid ?ColorId
---@param shift_scale ?number
---@param shift_period ?number
function set_draw_effect(effectid, glow_colorid, glow_intensity, dither_pixelsize, voronoi_scale, voronoi_fresnel, voronoi_colorid, shift_colorid, shift_scale, shift_period) end

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
---@param no_depth ?boolean Whether **not** to write depth data when rendering this object
function draw_box(pos_x, pos_y, pos_z, size_x, size_y, size_z, rot_x, rot_y, rot_z, texture_id, no_depth) end

---Draws a 3D cube with the specified settings (use rotation matrix)
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param size_x number
---@param size_y number
---@param size_z number
---@param rot_matrix ?MatrixTB
---@param texture_id ?integer Texture id retrieved from `load_texture()` call
---@param no_depth ?boolean Whether **not** to write depth data when rendering this object
function draw_box_m(pos_x, pos_y, pos_z, size_x, size_y, size_z, rot_matrix, texture_id, no_depth) end

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
---@param no_depth ?boolean Whether **not** to write depth data when rendering this object
function draw_sphere(pos_x, pos_y, pos_z, radius, rotation_x, rotation_y, rotation_z, texture_id, no_depth) end

---Draws a 3D sphere with the specified settings (use rotation matrix)
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param radius number
---@param rotation_matrix ?MatrixTB
---@param texture_id ?integer Texture id retrieved from `load_texture()` call
---@param no_depth ?boolean Whether **not** to write depth data when rendering this object
function draw_sphere_m(pos_x, pos_y, pos_z, radius, rotation_matrix, texture_id, no_depth) end

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
---@param no_depth ?boolean Whether **not** to write depth data when rendering this object
function draw_capsule(pos_x, pos_y, pos_z, length, radius, rot_x, rot_y, rot_z, texture_id, no_depth) end

---Draws a 3D capsule with the specified settings (use rotation matrix)
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param length number
---@param radius number
---@param rot_matrix ?MatrixTB
---@param texture_id ?integer Texture id retrieved from `load_texture()` call
---@param no_depth ?boolean Whether **not** to write depth data when rendering this object
function draw_capsule_m(pos_x, pos_y, pos_z, length, radius, rot_matrix, texture_id, no_depth) end

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
---@param no_depth ?boolean Whether **not** to write depth data when rendering this object
function draw_obj(model_id, pos_x, pos_y, pos_z, size_x, size_y, size_z, rot_x, rot_y, rot_z, no_depth) end

---Draws a 3D model with the specified settings (use rotation matrix)
---@param model_id integer Object id retrieved from `load_obj()`
---@param pos_x number
---@param pos_y number
---@param pos_z number
---@param size_x number
---@param size_y number
---@param size_z number
---@param rot_matrix ?MatrixTB
---@param no_depth ?boolean Whether **not** to write depth data when rendering this object
function draw_obj_m(model_id, pos_x, pos_y, pos_z, size_x, size_y, size_z, rot_matrix, no_depth) end

---Loads a TGA texture by the specified path
---@param path string
---@return integer #Texture id or -1 on error
function load_texture(path) end

---Sets texture wrapping mode
---@param texid integer
---@param mode TextureWrapMode
---@return boolean result
---@return string? error
function set_texture_wrapmode(texid, mode) end

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
---@return integer
---@overload fun(col1:ColorId, col2:ColorId, body:PlayerBody?):integer
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

---Localizes an RTL string
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

---Activates the specified camera mode
---@param mode CameraMode
function set_camera_mode(mode) end

---Returns currently active camera mode
---@return CameraMode mode
---@return CameraCacheMode cache_mode
function get_camera_mode() end

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
---@field pos Vector3Base Camera look from point
---@field lookat Vector3Base Camera look at point
---@field perp Vector3Base
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
---@field speed number
---@field interpolate boolean
---@field pos Vector3Base
---@field lookat Vector3Base

---Returns a table containing information on all store camera keyframes
---@return CameraKeyFrame[]
function get_camera_keyframes() end

---Returns number of active camera keyframes
---@return integer
function get_camera_keyframes_count() end

---Saves a new camera keyframe or updates an existing one at the same frame using specified settings
---@param frame integer
---@param speed number
---@param update_pos boolean?
---@param interpolate boolean?
function save_camera_keyframe(frame, speed, update_pos, interpolate) end

----Saves a new camera keyframe using current settings
function save_camera_keyframe() end

---Deletes a stored camera keyframe at the specified frame
---@param frame integer
---@return boolean result
function delete_camera_keyframe(frame) end

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

---Returns maximum supported UI scaling on current device
---@return integer
---@nodiscard
function get_maximum_dpi_scale() end

---@class DpiAwarenessInfo
---@field ISDPIAWARE integer
---@field DPISCALING number

---Returns dpi awareness info on Windows
---@return DpiAwarenessInfo
function get_dpiawareness() end

---Returns screen position of a specified player joint \
---**Must be called from a `draw3d` callback.**
---@param player integer
---@param joint PlayerJoint
---@return integer x
---@return integer y
---@return integer z
function get_joint_screen_pos(player, joint) end

---Returns screen position of a specified player bodypart \
---**Must be called from a `draw3d` callback.**
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
---@field gameover_frame integer

---Returns world state information
---@return WorldState
function get_world_state() end

---@alias ODEBodyShapeType
---| 0 BODY_SPHERE
---| 1 BODY_BOX
---| 2 BODY_CYLINDER

---@class BodyInfo
---@field name string
---@field mod_name string
---@field pos Vector3Base
---@field rot MatrixTB
---@field sides Vector3Base
---@field shape ODEBodyShapeType

---Returns player body information
---@param player integer
---@param body PlayerBody
---@return BodyInfo
function get_body_info(player, body) end


---Sets player bodypart position
---@param player_index integer
---@param body_index PlayerBody
---@param x number
---@param y number
---@param z number
function set_body_pos(player_index, body_index, x, y, z) end

---Sets player bodypart sides
---@param player_index integer
---@param body_index PlayerBody
---@param x number
---@param y number
---@param z number
function set_body_sides(player_index, body_index, x, y, z) end

---Sets player bodypart rotation (Euler angles)
---@param player_index integer
---@param body_index PlayerBody
---@param x number
---@param y number
---@param z number
function set_body_rotation(player_index, body_index, x, y, z) end

---Sets player bodypart rotation (rotation matrix)
---@param player_index integer
---@param body_index PlayerBody
---@param rot MatrixTB
function set_body_rotation_m(player_index, body_index, rot) end

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

---@class JointInfo
---@field state PlayerJointState
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

---Resets joint states to their initial state for current turn. \
---*This is identical to pressing `CTRL` + `Z`*
function undo_move_changes() end

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

---Returns information about gripped object. \
---*This function will only return `-1` if player isn't grabbing anything*
---@param player integer
---@param hand integer
---@return integer playerId
---@return integer ?bodyType
---@return integer ?limbId
---@return integer ?anchor_x
---@return integer ?anchor_y
---@return integer ?anchor_z
function get_grip_lock(player, hand) end

---Dismembers the specified player joint
---@param player integer
---@param joint PlayerJoint
function dismember_joint(player, joint) end

---Fractures the specified player joint
---@param player integer
---@param joint PlayerJoint
function fracture_joint(player, joint) end

---Returns joint position in 3D world
---@param player integer
---@param joint PlayerJoint
---@return number x
---@return number y
---@return number z
---@nodiscard
function get_joint_pos(player, joint) end

---Sets joint position
---@param player integer
---@param joint PlayerJoint
---@param x number
---@param y number
---@param z number
function set_joint_pos(player, joint, x, y, z) end

---Returns joint position in 3D world as `Vector3Base`
---@param player integer
---@param joint PlayerJoint
---@return Vector3Base
---@nodiscard
function get_joint_pos2(player, joint) end

---Returns joint radius
---@param player integer
---@param joint PlayerJoint
---@return number
function get_joint_radius(player, joint) end

---Sets joint radius
---@param player integer
---@param joint PlayerJoint
---@param radius number
function set_joint_radius(player, joint, radius) end

---Selects player with the corresponding id
---@param player integer Player ID or `-1` to deselect all players
---@param mute? boolean Whether not to play player select sound
function select_player(player, mute) end

---Disables selection of player with the corresponding id
---@param player integer Player ID or `-1` to enable selection for all players
function disable_player_select(player) end

---Starts a new game
---@param safe ?boolean If `true` is passed, will report ready event when in multiplayer instead of starting new free play game
function start_new_game(safe) end

---Pauses game. \
---*This **does not** simulate a pause hotkey behavior*. \
---@see toggle_game_pause
function freeze_game() end

---Unpauses game. \
---*This **does not** simulate a pause hotkey behavior*. \
---@see toggle_game_pause
function unfreeze_game() end

---Simulates `pause` hotkey behavior and pauses or unpauses the game depending on its current state. \
---*Pass `true` to simulate SHIFT + P behavior*
---@param single_frame ?boolean
function toggle_game_pause(single_frame) end

---Simulates `pause` hotkey behavior. Will be removed in future releases. \
---@deprecated
---@see toggle_game_pause
function step_to_end() end

---Returns whether game is currently paused
---@return boolean
function is_game_paused() end

---Returns value depending on game **freeze** state. \
---*Not to be confused with `is_game_paused()`* \
---@see is_game_paused
---@return integer
function is_game_frozen() end

---Returns whether currently selected player accepts input
---@return boolean
function players_accept_input() end

---Steps the game simulation. \
---*`single_frame = true` simulates SHIFT + SPACE behavior*
---@param single_frame ?boolean
---@param silent ?boolean
function step_game(single_frame, silent) end

---Opens and plays the replay. \
---When used with replay integrity checking enabled, listen to `replay_integrity_fail` hook for check failures. Lower threshold values mean higher precision but likely will generate false positives.
---@param filename string
---@param cache? integer
---@param check_integrity_threshold? number
---@param check_integrity_vel_threshold? number
function open_replay(filename, cache, check_integrity_threshold, check_integrity_vel_threshold) end

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

---@class GameRules
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
---@return GameRules
function get_game_rules() end

---Returns current value for the specified gamerule
---@param gamerule string
---@return string
function get_gamerule(gamerule) end

---Sets the value for the specified gamerule
---@param gamerule string
---@param value string
function set_gamerule(gamerule, value) end

---Sets default gamerules (classic.tbm)
function set_default_rules() end

---Returns specified turn's length in frames
---@param turn_index integer
---@return integer
function get_turn_frame(turn_index) end

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
---@return GhostMode ghost_mode
function get_ghost() end

---Sets ghost mode to the specified value
---@param ghost_mode GhostMode
function set_ghost(ghost_mode) end

---@class BodyGhostData
---@field shape integer
---@field sides number[]
---@field pos number[]
---@field quat number[]

---@class PlayerGhostCache
---@field bodies BodyGhostData[]
---@field joints BodyGhostData[]

---@class GhostFrameCache
---@field envs BodyGhostData[]

---Returns ghost cache data for the specified frame
---@param frame integer
---@return PlayerGhostCache[]|GhostFrameCache
function get_ghost_cache(frame) end

---Sets score for the specified player
---@param player integer
---@param score integer
function set_score(player, score) end

---Returns current player score
---@return number
function get_score(player) end

---Disqualifies the specified player \
---*This function is deprecated and will be removed in future releases, consider switching to `set_gameover()`* \
---@see set_gameover
---@deprecated
---@param player integer
function set_dq(player) end

---Ends the game with the specified game over type and winner
---@param gameover_type GameOverType
---@param winner_idx integer
function set_gameover(gameover_type, winner_idx) end

---Forces the specified player to relax all joints
---@param player integer
function set_player_relax(player) end

---Returns player bodyparts' visual damage level
---@param player integer
---@param bodypart PlayerBody
---@return number
---@overload fun(player:integer):number[]
function get_body_bruise(player, bodypart) end

---Returns player joints' visual damage level
---@param player integer
---@param joint PlayerJoint
---@return number
---@overload fun(player:integer):number[]
function get_joint_bruise(player, joint) end

---@class FrameBodyInfo
---@field damage number

---@class FrameJointInfo : FrameBodyInfo
---@field dm_damage number
---@field dm_health number
---@field fract_health number
---@field speed number
---@field torque number

---Returns body info on a specified frame
---@param player integer
---@param body PlayerBody
---@param frame integer
---@return FrameBodyInfo
function get_body_on_frame_info(player, body, frame) end

---Returns joint info on a specified frame
---@param player integer
---@param joint PlayerJoint
---@param frame integer
---@return FrameJointInfo
function get_joint_on_frame_info(player, joint, frame) end

---Toggles RPG on or off and returns current RPG state
---@param state boolean
---@return boolean
---@overload fun():boolean
function rpg_state(state) end

---Sets player RPG data for the next game
---@param player integer
---@param strength integer
---@param speed integer
---@param endurance integer
---@param x_scale number
---@param y_scale number
---@param z_scale number
---@overload fun(player: integer, strength: integer, speed: integer, endurance: integer)
function set_rpg(player, strength, speed, endurance, x_scale, y_scale, z_scale) end

---Resets player RPG data for the next game
---@param player integer
function reset_rpg(player) end

---@class PlayerRPG
---@field strength integer
---@field speed integer
---@field endurance integer
---@field x number
---@field y number
---@field z number

---Returns current RPG data for the specified player
---@return PlayerRPG
function get_rpg(player) end


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
---@see Utils3D.GetEulerFromMatrixTB
---@param obj_id integer
---@return number[]
function get_obj_rot(obj_id) end

---Sets the rotation for the specified environment object
---@param obj_id integer
---@param x number
---@param y number
---@param z number
function set_obj_rot(obj_id, x, y, z) end

---Sets rotation matrix for the specified environment object
---@param obj_id integer
---@param mat MatrixTB
function set_obj_rot_m(obj_id, mat) end

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

---Returns color of the specified environment object
---@param obj_id integer
---@return Color
function get_obj_color(obj_id) end

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
function get_obj_mass(obj_id) end

---Sets mass value for the specified environment object
---@param obj_id integer
---@param mass number
function set_obj_mass(obj_id, mass) end

---Returns environment object shape
---@param obj_id integer
---@return integer
function get_obj_shape(obj_id) end


--[[ REPLAY FUNCTIONS ]]

---Returns currently used replay cache value
---@return number
function get_replay_cache() end

---Renames or moves a replay file from `filename` to `new_filename`. \
---*Replay names are relative to `replay/` folder inside Toribash root directory.*
---@param filename string
---@param new_filename string
---@return string? #Error message
function rename_replay(filename, new_filename) end

---Deletes a replay file with name `filename`. \
---*Replay name is relative to `replay/` folder inside Toribash root directory.*
---@param filename string
---@return string? #Error message
function delete_replay(filename) end

---Plays the next replay in current folder
function play_next_replay() end

---Plays the previous replay in current folder
function play_prev_replay() end

---Returns current and previous replay playback speed
---@return number current
---@return number prev
function get_replay_speed() end

---Sets current replay playback speed
---@param speed number
---@param ignore_pause boolean? If set to `false`, will update previous replay speed instead of current
function set_replay_speed(speed, ignore_pause) end

---Creates a replay subfolder at the specified path relative to `replay/`
---@param path string
---@return string? #Error message
function add_replay_subfolder(path) end

---Removes replay subfolder at the specified path relative to `replay/`
---@param path string
---@return string? #Error message
function remove_replay_subfolder(path) end

---Renames a replay subfolder at the specified path relative to `replay/`
---@param path string
---@param new_path string
---@return string? #Error message
function rename_replay_subfolder(path, new_path) end

--[[ CUSTOMIZATION RELATED FUNCTIONS ]]

---Loads specified user's customs on a player
---@param player integer
---@param name string
function load_player(player, name) end

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

---Sets joint colors for the specified player
---@param player integer
---@param relax_color ColorId
---@param force_color ColorId
---@param joint ?PlayerJoint If specified, will only set the colors for that joint id
function set_joint_color(player, relax_color, force_color, joint) end

---Sets joint relax color for the specified player
---@param player integer
---@param color ColorId
function set_joint_relax_color(player, color) end

---Sets joint force color for the specified player
---@param player integer
---@param color ColorId
function set_joint_force_color(player, color) end

---Sets joint replay color for the specified player
---@param player integer
---@param color ColorId
function set_joint_replay_color(player, color) end

---Sets selected joint relax color for the player
---@param player integer
---@param joint PlayerJoint
---@param color ColorId
function set_selected_joint_relax_color(player, joint, color) end

---Sets selected joint force color for the player
---@param player integer
---@param joint PlayerJoint
---@param color ColorId
function set_selected_joint_force_color(player, joint, color) end

---Sets specified bodypart color for the player
---@param player integer
---@param body PlayerBody
---@param color ColorId
function set_body_color(player, body, color) end

---Applies an effect to player customs
---@param player integer
---@param effectid integer
---@param type RenderEffectId
---@param glow_color ?ColorId
---@param glow_intensity ?integer
---@param dither_pixel_size ?integer
---@param voronoi_scale ?integer
---@param voronoi_colorid ?ColorId
---@param shift_colorid ?ColorId
---@param shift_period ?number
function set_body_effect(player, effectid, type, glow_color, glow_intensity, dither_pixel_size, voronoi_scale, voronoi_colorid, shift_colorid, shift_period) end

---Sets blood color for the specified player
---@param player integer
---@param color ColorId
function set_blood_color(player, color) end

---Sets torso color for the specified player
---@param player integer
---@param color ColorId
function set_torso_color(player, color) end

---Sets ghost color for the specified player
---@param player integer
---@param color ColorId
function set_ghost_color(player, color) end

---Sets DQ color for the specified player
---@param player integer
---@param color ColorId
function set_ground_impact_color(player, color) end

---Sets primary gradient color for the specified player
---@param player integer
---@param color ColorId
function set_gradient_primary_color(player, color) end

---Sets secondary gradient color for the specified player
---@param player integer
---@param color ColorId
function set_gradient_secondary_color(player, color) end

---Sets gradient colors for the specified player
---@param player integer
---@param primary ColorId
---@param secondary ColorId
function set_gradient_color(player, primary, secondary) end

---Sets timer color for the specified player
---@param player integer
---@param color ColorId
function set_timex_color(player, color) end

---Sets trail colors for the specified player
---@param player integer
---@param color ColorId
function set_trail_color(player, color) end

---@alias BodyTrail
---| 0 Left Hand
---| 1 Right Hand
---| 2 Left Leg
---| 3 Right Leg

---Sets trail colors for the specified player
---@param player integer
---@param body BodyTrail
---@param color ColorId
function set_separate_trail_color(player, body, color) end

---Sets trail RGBA colors for the specified player
---@param player integer
---@param body BodyTrail
---@param r number
---@param g number
---@param b number
---@param a number
function set_separate_trail_color(player, body, r, g, b, a) end

---Sets hair color for the specified player
---@param player integer
---@param color ColorId
function set_hair_color(player, color) end

---Sets hair settings
---@param player integer
---@param hair integer
---@param enable integer
---@param style integer
---@param x integer
---@param y integer
---@param angle integer
---@param segments integer
---@param slices integer
---@param radius_start integer
---@param radius_end integer
---@param base_length integer
---@param start_length integer
---@param end_length integer
---@param color integer
---@param texture_mode integer
---@param blender integer
---@param stiffness integer
function set_hair_settings(player, hair, enable, style, x, y, angle, segments, slices, radius_start, radius_end, base_length, start_length, end_length, color, texture_mode, blender, stiffness) end

---Resets player hair
---@param player integer
function reset_hair(player) end

---Adds trail particle between two points in 3D world
---@param player integer
---@param body BodyTrail
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
function add_trail_particle(player, body, x1, y1, z1, x2, y2, z2) end

---Returns flame playback state
---@return boolean
function get_flame_playback() end

---Sets flame playback state
---@param state boolean
function set_flame_playback(state) end

---@alias FlameSettingId
---| 0 FLAME_BODYPART
---| 1 FLAME_TIMESTEP
---| 2 FLAME_DAMPING
---| 3 FLAME_BLEND
---| 4 FLAME_SINK
---| 5 FLAME_COLOR_R
---| 6 FLAME_COLOR_G
---| 7 FLAME_COLOR_B
---| 8 FLAME_COLOR_A
---| 9 FLAME_COLOR_RANDOM
---| 10 FLAME_TARGET_COLOR_R
---| 11 FLAME_TARGET_COLOR_G
---| 12 FLAME_TARGET_COLOR_B
---| 13 FLAME_TARGET_COLOR_A
---| 14 FLAME_TARGET_COLOR_RANDOM
---| 15 FLAME_TARGET_COLOR_SCALE
---| 16 FLAME_AGE_START
---| 17 FLAME_AGE_LIMIT
---| 18 FLAME_AGE_SIGMA
---| 19 FLAME_EMIT_SCALE
---| 20 FLAME_EMIT_AMOUNT
---| 21 FLAME_SIZE
---| 22 FLAME_SIZE_RANDOM
---| 23 FLAME_TARGET_SIZE
---| 24 FLAME_TARGET_SIZE_SCALE
---| 25 FLAME_TARGET_SIZE_RANDOM
---| 26 FLAME_RANDOM_DISPLACE_X
---| 27 FLAME_RANDOM_DISPLACE_Y
---| 28 FLAME_RANDOM_DISPLACE_Z
---| 29 FLAME_RANDOM_DISPLACE_RANDOM
---| 30 FLAME_ROTATABLE
---| 31 FLAME_GRAVITY_X
---| 32 FLAME_GRAVITY_Y
---| 33 FLAME_GRAVITY_Z
---| 34 FLAME_VELOCITY_X
---| 35 FLAME_VELOCITY_Y
---| 36 FLAME_VELOCITY_Z
---| 37 FLAME_VELOCITY_RANDOM
---| 38 FLAME_ORBIT
---| 39 FLAME_ORBIT_BODYPART
---| 40 FLAME_ORBIT_MAGNITUDE
---| 41 FLAME_ORBIT_EPSILON
---| 42 FLAME_GRAVITATE
---| 43 FLAME_GRAVITATE_MAGNITUDE
---| 44 FLAME_GRAVITATE_EPSILON
---| 45 FLAME_GRAVITATE_MAX_RADIUS
---| 46 FLAME_FOLLOW
---| 47 FLAME_FOLLOW_MAGNITUDE
---| 48 FLAME_FOLLOW_EPSILON
---| 49 FLAME_SINK_BODY
---| 50 FLAME_SINK_BODY_BODYPART
---| 51 FLAME_SINK_BODY_RADIUS
---| 52 FLAME_ROTATABLE_GRAVITY

---Returns the specified player flame setting value
---@param player integer
---@param flame integer
---@param id FlameSettingId
function get_flame_setting(player, flame, id) end

---Sets a flame value for player in Tori spot
---@param id FlameSettingId
---@param value integer
---@param flame ?integer
---@param playerid ?integer Use `-1` to set settings for a Lua managed flame
function set_flame_setting(id, value, flame, playerid) end

---Sets a texture for player flames
---@param player integer
---@param dir string
---@param name string
function set_flame_texture(player, dir, name) end

---Loads a texture by its full path and sets for a Lua managed flame
---@param path string
---@param flameid integer
---@return boolean
function load_flame_texture(path, flameid) end

---Runs an update loop on Lua managed flames
function update_lua_flames() end

---Loads a body texture from `customse/data/script/` directory onto a bodypart of a player in Tori spot. \
---*This is a legacy Torishop function that is no longer being used and may be deprecated in future releases.*
---@param body integer
---@param number integer
function set_body_texture(body, number) end

---Uninits Torishop and removes all player trails. \
---*This is a legacy Torishop function that is no longer being used and may be deprecated in future releases.*
function uninit_torishop() end

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

---@class TorishopPlayerColors
---@field blood_color integer
---@field torso_color integer
---@field ghost_color integer
---@field impact_color integer
---@field grad_sec_color integer
---@field grad_pri_color integer
---@field grip_color integer
---@field timex_color integer
---@field text_color integer
---@field lh_trail_r number
---@field lh_trail_g number
---@field lh_trail_b number
---@field lh_trail_a number
---@field rh_trail_r number
---@field rh_trail_g number
---@field rh_trail_b number
---@field rh_trail_a number
---@field ll_trail_r number
---@field ll_trail_g number
---@field ll_trail_b number
---@field ll_trail_a number
---@field rl_trail_r number
---@field rl_trail_g number
---@field rl_trail_b number
---@field rl_trail_a number

---Returns player's currently loaded colors information. \
---*This is a legacy Torishop function that is no longer being used and may be deprecated in future releases.*
---@param player integer
---@return TorishopPlayerColors
function set_torishop(player) end


--[[ MOBILE FILE IO AND GENERAL FILE IO OVERRIDES ]]

---Opens a file, in the mode specified in the string `mode`. \
---*This is a modified version of default `io.open()` function that starts file lookup at `data/script` directory by default.* \
---[View documents](command:extension.lua.doc?["en-us/51/manual.html/pdf-io.open"])
---@param filename string
---@param mode?    openmode
---@param root?    integer|boolean If `true`, will open file at Toribash root folder
---@return file*?
---@return string? errmsg
---@diagnostic disable-next-line: duplicate-set-field
function io.open(filename, mode, root) end

---Attempts to open a file at location and returns the index on success or nil on failure
---@param path string
---@param mode ?openmode
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
---@param action_id integer
---@param offset integer
---@param search ?string
function fetch_replay_results(action_id, offset, search) end

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
---@param refresh_rewards boolean? Whether to refresh login rewards state
function update_tc_balance(refresh_rewards) end

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

---Fetches payments history for current user\
---@see Request
function download_payments_history() end

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

---Opens a *toribash.com* url with user's default web browser.
---@param url string
---@param authenticate? boolean Whether we should try to authenticate the user with current credentials. Only works if user is **not** currently logged into an account in their browser. Always set to `true` on iOS.
function open_url(url, authenticate) end

---Downloads bounties data and saves it as `data/bounties.txt`
function download_fetch_bounties() end

---Downloads quests data for the specified user
---@param username string
function download_quest(username) end

---Sends a request to claim quest reward
---@param ... integer
function claim_quest(...) end

---Sends a request to claim global quest reward
---@param questid integer
function claim_quest_global(questid) end

---Downloads global quests data for the current user and saves it as `data/quests_global.dat`
function download_global_quests() end

---Downloads general Torishop data and models data
function download_torishop() end

---Downloads inventory datafile for the specified user or current user if no username is specified.
---
---*Current user's inventory is saved to `data/inventory.txt`* \
---*Other users' inventory is saved to `data/uinvent.tmp`*
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

---Connects to reward server to refresh reward status. \
---*This should only be used in case we receive a timeout error when attempting to claim the reward.*
function refresh_reward() end

---Claims all available Battle Pass rewards
function battlepass_claim_reward() end

---Fetches ranking toplist for the specified mod (or global ranking by default)\
---@see Request
---@param modid ?integer
function fetch_ranking_toplist(modid) end

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

---@alias TextureDisplayMode
---| 0	Default (multiply color both)
---| 2	Texture both
---| 3	Relax texture only
---| 4	Force texture only
---| 5	Relax multiply color only
---| 6	Force multiply color only
---| 7	Relax texture, force multiply color
---| 8	Relax multiply color, force texture

---Submits a new target display mode for a texture item
---@param inventid integer
---@param mode TextureDisplayMode
function submit_texture_item_mode(inventid, mode) end

---Submits item purchase request for Toricredits
---@param data string
function buy_tc(data) end

---Submits item purchase request for Shiai Tokens
---@param data string
function buy_st(data) end

---Registers a list of items available for in-app purchases
---@param itemids integer[]
function register_platform_mtx(itemids) end

---Initiates a platform-specific microtransaction flow
---@param itemid integer
---@return integer? #`0` on success, error id otherwise (or nil on unsupported platforms).
function buy_platform_mtx(itemid) end

---Returns a localized price string for an item on current platform
---@param itemid integer
---@return string
function get_platform_item_price(itemid) end

---Queries information about the specified user from Toribash servers. \
---*Leave username empty to request current user info.* \
---@see PlayerInfo.getServerUserinfo
---@param username ?string
function get_player_userinfo(username) end


-- [[ ROOM LIST ]]

---Queues an asynchronous room list refresh request. \
---On completion, will trigger `roomlist_update` hook callback with error (if any).
function refresh_roomlist() end

---Returns number of cached rooms or `nil` on error
---@return integer|nil
function get_roomlist_num_rooms() end

---@class RoomListInfo
---@field id integer Room id in the cache
---@field name string Room name
---@field desc string Room description
---@field hostname string Public room address in `ip:port` format
---@field num_players integer Current number of players in the room
---@field max_clients integer Maximum allowed number of players in the room
---@field players string[] List of players currently in the room
---@field min_belt integer Minimum belt requirement to join the room
---@field max_belt integer Maximum belt requirement to join the room
---@field min_rank integer Minimum player rank requirement to join the room
---@field max_rank integer Maximum player rank requirement to join the room
---@field min_elo number Minimum elo requirement to join the room
---@field max_elo number Maximum elo requirement to join the room
---@field min_bet integer Room minimum bet amount
---@field entry_fee integer Room entry fee
---@field duel_amount integer Room duel wager
---@field gamerules GameRules Room game rules
---@field is_official boolean
---@field is_ranked boolean
---@field is_duel_mode boolean
---@field is_password_protected boolean
---@field is_tournament boolean

---Returns information about a room with the specified id or `nil` on error
---@param room_id integer
---@return RoomListInfo|nil
function get_roomlist_room_info(room_id) end


-- [[ NOTIFICATIONS ]]

---Sends a network request to fetch total number of unread notifications for the user
function get_notifications_count() end

---Sends a network request to fetch general data about user's inbox
---@param last_pmid ?integer
function get_notifications(last_pmid) end

---Sends a network request to download contents of a private message from user's inbox
---@param pmid integer
function get_notifications_pmtext(pmid) end

---Sends a network request to delete private message located in user's inbox
---@param pmid integer
function delete_notification(pmid) end


-- [[ KEYBOARD FUNCTIONS ]]

---Enables Lua menu keyboard callbacks. \
---*On mobile platforms, this will also bring up on-screen keyboard.* \
---*It is recommended to pass input's position and size on mobile platforms to ensure proper focus.*
---@overload fun()
---@param inputX integer
---@param inputY integer
---@param inputWidth integer
---@param inputHeight integer
---@param text string
---@param inputType? KeyboardInputType
---@param autoCompletion? boolean
---@param returnKeyType? KeyboardReturnType
---@param cursorPosition? integer
---@overload fun(inputX:integer, inputY:integer, inputWidth:integer, inputHeight:integer)
---@overload fun()
function enable_menu_keyboard(inputX, inputY, inputWidth, inputHeight, text, inputType, autoCompletion, returnKeyType, cursorPosition) end

---Disables Lua menu keyboard callbacks. \
---*On mobile platforms, this will also hide on-screen keyboard.*
function disable_menu_keyboard() end

---Adds the word to local device dictionary for this session. \
---*Only works on mobile platforms.*
---@param word string
function keyboard_learn_word(word) end

---Updates menu keyboard settings on mobile platforms
---@param inputType KeyboardInputType
---@param autoCompletion? boolean
---@param returnKeyType? KeyboardReturnType
function set_menu_keyboard(inputType, autoCompletion, returnKeyType) end

---Updates menu keyboard context on mobile platforms
---@param text string
---@param cursorPosition ?integer
function set_menu_keyboard_context(text, cursorPosition) end

---Returns whether either of shift keys is currently down
---@return integer
function get_shift_key_state() end

---Returns whether right alt key is currently down
---@return integer
function get_right_alt_key_state() end

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
---@return integer|nil start
---@return integer|nil end
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
---| "replaycache" #Target value for replay cache
---| "sysreplaycache" #Actual current state of replay cache, read-only
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
---| "invertedcam"
---| "camerafocus"
---| "mipmaplevels"
---| "tooltipmode"
---| "camerasensitivityh"
---| "camerasensitivityy"
---| "ghostobj"
---| "scrollcontrols"
---| "keyframesavemode"
---| "effectsvariablespeed"
---| "aidifficulty" #Toribash builds with AI fight mode only

---Retrieves a value of the specified Toribash option
---@param value GameOption
---@return integer
function get_option(value) end

---Sets value for the specified Toribash option
---@param option GameOption
---@param value integer|boolean
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
---| 8 High DPI mode
---| 9 Borderless window mode
---| 10 Item effects
---| 11 Apple high DPI mode

---Sets value for the specified graphics option \
---Changes will be applied on next `reload_graphics()` call
---@param option GraphicsOption
---@param value string|number
function set_graphics_option(option, value) end

---Reloads graphics and applies changes set by `set_graphics_option()`
function reload_graphics() end

---Returns current custom world shader file name
---@return string
function get_shader_name() end

---@alias ShaderOptionId
---| 0	BACKGROUND_COLOR
---| 1	MIRROR_COLOR
---| 2	FLOOR_COLOR
---| 3	SUNSHINE_COLOR
---| 4	AMBIENT_COLOR
---| 5	FOG_DISTANCE
---| 6	SHARP_SHADOW
---| 7	SKY_ON
---| 8	AMBIENT_LIGHT_DIR
---| 9	SUN_LIGHT_DIR
---| 10	SUNBEAM_COLOR
---| 11	SUN_COLOR
---| 12	SKY_COLOR
---| 13	POLAR_LIGHT_COLOR
---| 14	POLAR_LIGHT_DIR
---| 15	SKY_BLEND_POWER
---| 16	CUSTOM_COLOR_TEXT
---| 17	CUSTOM_COLOR_TEXT_BG
---| 18	CUSTOM_COLOR_TEXT_SEL
---| 19	CUSTOM_COLOR_TEXT_DISABLED
---| 20	CUSTOM_COLOR_MENU_TEXT
---| 21	CUSTOM_COLOR_MENU_TEXT_BG
---| 22	CUSTOM_COLOR_MENU_TEXT_SEL
---| 23	CUSTOM_COLOR_MENU_TEXT_DISABLED
---| 24	CUSTOM_COLOR_MSG_NOTYPE
---| 25	CUSTOM_COLOR_MSG_WHISPER
---| 26	CUSTOM_COLOR_MSG_SERVER
---| 27	CUSTOM_COLOR_MSG_SRVURL
---| 28	CUSTOM_COLOR_MSG_INGAME
---| 29	CUSTOM_COLOR_MSG_GAMURL
---| 30	CUSTOM_COLOR_MSG_USER
---| 31	CUSTOM_COLOR_MSG_PLAYER
---| 32	CUSTOM_COLOR_MSG_URL
---| 33	CUSTOM_COLOR_MSG_URLSEL

---Returns current settings for the specified shader option id
---@param id ShaderOptionId
---@return Color
function get_shader_option(id) end

---Sets the specified settings for shader option id
---@param id ShaderOptionId
---@param x number
---@param y number
---@param z number
---@param w number
---@param reload_sky ?boolean
---@param sky_resolution ?integer
---@return boolean
function set_shader_option(id, x, y, z, w, reload_sky, sky_resolution) end

---@alias SoundCategoryId
---| 0	Shout
---| 1	Dismember
---| 2	Fight alert
---| 3	Freeze
---| 4	Game over
---| 5	Grading
---| 6	Grip
---| 7	Hit
---| 8	Impact
---| 9	Joint
---| 10	Menu
---| 11	None
---| 12	Pain
---| 13	Ready
---| 14	Select player
---| 15	Splash
---| 16	Swoosh

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
---@field netid integer Network id of a player
---@field is_fighter boolean|nil Whether this player is currently playing
---@field games_played integer Player's total Qi
---@field rank integer Player rank
---@field streak integer Current win streak
---@field custombeltname string Custom belt name (players with 20,000 Qi or more)
---@field perms_bitfield integer Player permissions bit field
---@field admin boolean Whether this user is an in-game administrator
---@field op boolean Whether this user is a room operator
---@field halfop boolean Whether this user is a half-operator
---@field legend boolean Whether this user is a legend
---@field eventsquad boolean Whether this user is a part of Event Squad
---@field eventsquad_trial boolean Whether this user is a trial Event Squad member
---@field helpsquad boolean Whether this user is a part of Help Squad
---@field marketsquad boolean Whether this user is a part of Market Squad
---@field itemforger boolean Whether this user is an Item Forger
---@field muted boolean Whether this user is muted
---@field afk boolean Whether this user is afk
---@field multiclient boolean Whether this user is currently multiclienting
---@field oldschool boolean Whether this user is an old schooler
---@field elo number Player elo rating
---@field rank_title string Player rank title
---@field flag_code string Flag code
---@field extra_qi integer Player's added Qi
---@field join_date string Join date in `YYYY-MM-DD` format

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

---Returns current user's network id
---@return integer
function get_current_netid() end


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

---Returns name of the tab with the specified id
---@param id integer
---@return string
function get_chat_tab_name(id) end

---Closes chat tab with the specified id
---@param id integer
function close_chat_tab(id) end

---Hides chat tabs
function hide_chat_button() end


--[[ SOUND FUNCTIONS ]]

---@alias SoundId
---| 0	SND_PAIN1
---| 1	SND_PAIN2
---| 2	SND_PAIN3
---| 3	SND_PAIN4
---| 4	SND_PAIN5
---| 5	SND_PAIN6
---| 6	SND_PAIN7
---| 7	SND_PAIN8
---| 8	SND_HIT_HEAD1
---| 9	SND_HIT_HEAD2
---| 10	SND_HIT_HEAD3
---| 11	SND_HIT1
---| 12	SND_HIT2
---| 13	SND_HIT3
---| 14	SND_HIT4
---| 15	SND_HIT5
---| 16	SND_IMPACT_HARD1
---| 17	SND_IMPACT_HARD2
---| 18	SND_IMPACT_SOFT1
---| 19	SND_IMPACT_SOFT2
---| 20	SND_IMPACT_MINI1
---| 21	SND_IMPACT_MINI2
---| 22	SND_DISMEMBER1
---| 23	SND_DISMEMBER2
---| 24	SND_DISMEMBER3
---| 25	SND_DISMEMBER4
---| 26	SND_DISMEMBER5
---| 27	SND_SWOOSH_HAND
---| 28	SND_SWOOSH_FEET
---| 29	SND_SWOOSH_BODY
---| 30	SND_FOOT_STEP
---| 31	SND_MENU_CLICK
---| 32	SND_SELECT_PLAYER
---| 33	SND_JOINT_HOLD
---| 34	SND_JOINT_OVER
---| 35	SND_JOINT_CHANGE
---| 36	SND_FIGHT_ALERT
---| 37	SND_WIN
---| 38	SND_DQ
---| 39	SND_DRAW
---| 40	SND_SPLASH0
---| 41	SND_SPLASH1
---| 42	SND_SPLASH2
---| 43	SND_SPLASH3
---| 44	SND_SPLASH4
---| 45	SND_SPLASH5
---| 46	SND_SPLASH6
---| 47	SND_SPLASH7
---| 48	SND_SPLASH8
---| 49	SND_SLOWDOWN
---| 50	SND_GRADING
---| 51	SND_READY
---| 52	SND_KIAI
---| 53	SND_SHOUT
---| 54	SND_FREEZE_ENTER
---| 55	SND_FREEZE_EXIT
---| 56	SND_GRIP
---| 57	SND_NECK_FRACTURE
---| 58	SND_TRIGGER
---| 59	SND_TRIGGER1
---| 60	SND_TRIGGER2
---| 61	SND_TRIGGER3
---| 62	SND_TRIGGER4
---| 63	SND_TRIGGER5
---| 64	SND_TRIGGER6
---| 65	SND_TRIGGER7
---| 66	SND_DECAP
---| 67 SND_MESSAGE

---Plays a Toribash sound by its ID
---@param soundid SoundId
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


--[[ IGNORE LIST FUNCTIONS ]]

---@class IgnoreListEntry
---@field name string
---@field mode IgnoreMode

---Returns the list that are currently being ignored
---@return IgnoreListEntry[]
function get_ignore_list() end

---Adds a user to ignore list. \
---If `mode` is unspecified, defaults to `IGNORE_MODE.CHAT`.
---@param user string
---@param mode ?IgnoreMode
function add_ignore_list(user, mode) end

---Removes a user from ignore list. \
---If `mode` is unspecified, defaults to `IGNORE_MODE.ALL`.
---@param user string
---@param mode ?IgnoreMode
function remove_ignore_list(user, mode) end


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
---| "replay_integrity_fail" #Called when replay hacking is detected during replay playthrough with check_integrity mode enabled
---| "bout_update" #Called after bout list update is finished
---| "spec_update" #Called when spectator status update is received
---| "roomlist_update" #Called on room list info request completion
---| "purchase_status" #Called on mobile in-app purchase status change
---| "login" #Called on successful account login
---| "browser" #Web browser completion callback
---| "input_type_change" #Called on input type change, see `INPUT_TYPE` table for types
---| "touch_toggle_hud" #Called on hud toggle via tap with three fingers on mobile platforms
---| "dropfile" #Called on SDL_DROPFILE event
---| "touch_fingermotion_ignore" #Called on finger motion event on touch platforms. Return non-zero value to disable multi finger touch gestures.

---Adds a Lua callback listener \
---*Only one function per `event` + `set_name` pair is supported*
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
---@param event LuaCallback
---@param ... any Callback arguments
function call_hook(event, ...) end

---Returns real time in seconds since application launch
---@return number
function os.clock_real() end


--[[ RAY CASTING ]]

---Creates a geometry body that can be used for Lua raycasting and returns its id on success
---@param type ODEBodyShapeType
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

---Sets raycast body position
---@param body_id integer
---@param x number
---@param y number
---@param z number
---@see create_raycast_body
function set_raycast_body_pos(body_id, x, y, z) end

---Sets raycast body rotation
---@param body_id integer
---@param x number
---@param y number
---@param z number
---@see create_raycast_body
function set_raycast_body_rot(body_id, x, y, z) end

---Sets raycast body rotation matrix
---@param body_id integer
---@param matrix MatrixTB
---@see create_raycast_body
function set_raycast_body_rot_m(body_id, matrix) end

---Sets raycast body size
---@param body_id integer
---@param x number
---@param y ?number
---@param z ?number
---@see create_raycast_body
function set_raycast_body_sides(body_id, x, y, z) end

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

---Returns a list of folders in specified directory
---@param directory string
---@return string[]
function get_folders(directory) end

---Checks whether the specified path is a valid existing folder
---@param path string
---@return boolean
function is_folder(path) end

---Clears Toribash cache folder to free up space.
---@return integer error_code
function remove_cache() end

---Clears Toribash customs folder to free up space.
---*Only available on mobile platforms.*
---@return integer? error_code
function remove_customs() end

---Triggers OS-specific share UI.
---*Only available on mobile platforms.
---@param path string
function share_file(path) end

---Attempts to enable screen blur.
---*Only available on desktop platforms.*
---@return boolean result
function enable_blur() end

---Disables screen blur
function disable_blur() end

---Prints a local chat message
---@param message string
---@param tab ?integer
---@param disable_callback ?boolean If `true`, will not trigger `console` callback
function echo(message, tab, disable_callback) end

---Prints an error message to standard error output file (`stderr.txt` on Windows / Linux or Log Report on macOS)
---@param error string
function perror(error) end

---Executes a game command
---@param command string
---@param online ?integer
---@param silent ?boolean
function run_cmd(command, online, silent) end

---Executes a `/reset` command in a Multiplayer room
function reset_server() end

---General information about a multiplayer room
---@class OnlineRoomInfo
---@field name string
---@field ip string

---Returns current multiplayer room name
---@return OnlineRoomInfo|nil
function get_room_info() end

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

---Returns Steam stat value by its name
---@param name string
---@return number|nil
function get_steam_stat(name) end

---@alias PurchaseCompleteState
---| 0	PURCHASE_UNKNOWN
---| 1	PURCHASE_COMPLETE
---| 2	PURCHASE_ERROR

---Returns in-app purchase finalized status
---@return PurchaseCompleteState state
function get_purchase_done() end

---Returns last in-app purchase message
---@return string
function get_purchase_message() end

---Runs a legacy tutorial by its id
---@param id integer
function run_tutorial(id) end

---Opens platform-specific file browser to select a file that matches the specified extensions
---@param description ?string
---@param extensions ?string `;`-separated list of supported file extensions
---@param ... string Additional description + extension pairs
---@return boolean #Whether file browser is supported on current platform
function open_file_browser(description, extensions, ...) end

---@class BetInfo
---@field tc integer
---@field num integer

---Returns player bet information
---@param player integer
---@return BetInfo
function get_bet_info(player) end

---@alias ScreenshotType
---| 0 SCREENSHOT_PNG_BMP
---| 1 SCREENSHOT_PPM

---Makes a screenshot
---@param filename string
---@param type ?ScreenshotType
function screenshot(filename, type) end

---Returns Lua error number
function get_errno() end

---Saves current mod to a file
---@param filename string
---@return boolean
function export_mod(filename) end

---Deletes a shader file
---@param filename string
function delete_shader(filename) end

---Deletes a mod file
---@param filename string
function delete_mod(filename) end

---Returns the location of a mod with the specified name or nil if it isn't found in mods folder
---@param filename string
---@return string?
function find_mod(filename) end

---Returns value depending on game center availability. *iOS only*
---@return boolean
function is_gamecenter_available() end

---Opens Game Center dashboard. *iOS only*.
function open_gamecenter_dashboard() end

---Display app rating prompt if it's available. *Mobile platforms only*.
function request_app_review() end

---Sets or removes an override for in-game hint message
---@param message string|nil
function set_hint_override(message) end

---Opens achievements screen on supported platforms. \
---@see open_gamecenter_dashboard
function open_achievements() end
