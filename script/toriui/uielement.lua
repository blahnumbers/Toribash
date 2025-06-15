-- Toribash UI manager
-- Created by sir @ Nabi Studios

require('toriui.json')

local w, h = get_window_size()
---Window width that UIElement class currently operates with
_G.WIN_W = w
---Window height that UIElement class currently operates with
_G.WIN_H = h
---Current screen ratio
_G.SCREEN_RATIO = WIN_W / WIN_H

local safe_x, safe_y, safe_w, safe_h = get_window_safe_size()
---Safe screen area X offset
_G.SAFE_X = math.max(safe_x, _G.WIN_W - safe_w - safe_x)
---Safe screen area Y offset
_G.SAFE_Y = math.max(safe_y, _G.WIN_H - safe_h - safe_y)

---Current cursor X coordinate
_G.MOUSE_X = 0
---Current cursor Y coordinate
_G.MOUSE_Y = 0

---Local references to frequently used global functions to improve performance
local drawQuad = draw_quad
local drawDisk = draw_disk
local setColor = set_color
local drawText = draw_text_angle_scale
local is_mobile = is_mobile()

---@alias FontId
---| 0 # FONTS.BIG | Badaboom big
---| 1 # FONTS.SMALL | Arial small (chat default)
---| 2 # FONTS.MEDIUM | Badaboom medium
---| 3 # Bedrock medium
---| 4 # Arial Bold medium
---| 5 # Kanji supported small
---| 6 # Kanji supported medium
---| 7 # SimHei small
---| 8 # SimHei medium
---| 9 # FONTS.BIGGER | Badaboom giant
---| 10 # Badaboom big @2
---| 11 # Arial small @2
---| 12 # Badaboom medium @2
---| 13 # Bedrock medium @2
---| 14 # Arial Bold medium @2
---| 15 # Kanji supported small @2
---| 16 # Kanji supported medium @2
---| 17 # SimHei small @2
---| 18 # SimHei medium @2
---| 19 # Badaboom giant @2

---@alias UIElementShape
---| 1 # SQUARE
---| 2 # ROUNDED
_G.SQUARE = 1
_G.ROUNDED = 2

---@alias UIElementTextAlign
---| 0 # LEFT | Top Left
---| 1 # CENTER | Top Center
---| 2 # RIGHT | Top Right
---| 3 # LEFTBOT | Bottom Left
---| 4 # CENTERBOT | Bottom Center
---| 5 # RIGHTBOT | Bottom Right
---| 6 # LEFTMID | Middle Left
---| 7 # CENTERMID | Middle Center
---| 8 # RIGHTMID | Middle Right
_G.LEFT = 0
_G.CENTER = 1
_G.RIGHT = 2
_G.LEFTBOT = 3
_G.CENTERBOT = 4
_G.RIGHTBOT = 5
_G.LEFTMID = 6
_G.CENTERMID = 7
_G.RIGHTMID = 8

---@alias UIElementBtnState
---| 0 # BTN_NONE | Default UIElement button state
---| 1 # BTN_HVR | Hover state
---| 2 # BTN_FOCUS | Focused state - only used with keyboard controls
---| 3 # BTN_DN | Pressed state
_G.BTN_NONE = 0
_G.BTN_HVR = 1
_G.BTN_FOCUS = 2
_G.BTN_DN = 3

---@alias UIElementScrollMode
---| 1 # SCROLL_VERTICAL
---| 2 # SCROLL_HORIZONTAL
_G.SCROLL_VERTICAL = 1
_G.SCROLL_HORIZONTAL = 2

---@alias SortOrder
---| true # SORT_DESCENDING
---| false # SORT_ASCENDING
_G.SORT_DESCENDING = true
_G.SORT_ASCENDING = false

---@alias Color number[]
_G.UICOLORWHITE = { 1, 1, 1, 1 }
_G.UICOLORBLACK = { 0, 0, 0, 1 }
_G.UICOLORRED = { 1, 0, 0, 1 }
_G.UICOLORGREEN = { 0, 1, 0, 1 }
_G.UICOLORBLUE = { 0, 0, 1, 1 }
_G.UICOLORTORI = { 0.58, 0, 0, 1 }
_G.DEFTEXTCOLOR = _G.DEFTEXTCOLOR or { 1, 1, 1, 1 }
_G.DEFSHADOWCOLOR = _G.DEFSHADOWCOLOR or { 0, 0, 0, 0.6 }

---@class Vector2Base
---@field x number
---@field y number

---@class Vector3Base : Vector2Base
---@field z number

---@class Rect : Vector2Base
---@field w number
---@field h number

---@type UIElement[]
_G.UIElementManager = _G.UIElementManager or {}
---@type UIElement[][]
_G.UIVisualManager = _G.UIVisualManager or {}
---@type UIElement[]
_G.UIViewportManager = _G.UIViewportManager or {}
---@type UIElement[]
_G.UIMouseHandler = _G.UIMouseHandler or {}
---@type UIElement[]
_G.UIKeyboardHandler = _G.UIKeyboardHandler or {}
---@type UIElement[]
_G.UIScrollbarHandler = _G.UIScrollbarHandler or {}

---@type integer[]
_G.UIElementTextureCache = _G.UIElementTextureCache or {}
_G.UIElementTextureIndex = _G.UIElementTextureIndex or 0
-- Default texture that will be used for fallback by `UIElement:updateTexture()`
_G.UIElementDefaultTexture = "../textures/menu/logos/toribash.tga"

if (not UIElement) then
	---@class UIElementSize
	---@field w number
	---@field h number

	---Options to use to spawn the new UIElement object.\
	---*Majority of these are the same as UIElement class fields.*
	---@class UIElementOptions
	---@field globalid integer
	---@field parent UIElement Specifying a parent will set its globalid and some other settings automatically
	---@field pos number[] Object's target position (relative to parent, if applicable). Negative values imply offset from the opposite direction.
	---@field size number[]
	---@field shift number[] Object's padding (horizontal and vertical). *Only used when spawning an object with UIElement:addChild()*.
	---@field interactive boolean
	---@field bgColor Color
	---@field hoverColor Color
	---@field pressedColor Color
	---@field inactiveColor Color
	---@field uiColor Color
	---@field uiShadowColor Color
	---@field viewport boolean
	---@field bgImage string|string[] Image path for the object. Alternatively, can be an array with two elements for main texture and fallback option in case main texture file is missing.
	---@field disableUnload boolean
	---@field imagePatterned boolean
	---@field imageAtlas boolean
	---@field imageColor Color
	---@field atlas Rect
	---@field imageHoverColor Color
	---@field imagePressedColor Color
	---@field imageInactiveColor Color
	---@field textfield boolean Whether the object will be used as a text field
	---@field textfieldstr string|string[]
	---@field textfieldsingleline boolean
	---@field textfieldkeepfocusonhide boolean
	---@field inputType KeyboardInputType On-screen keyboard input type
	---@field autoCompletion boolean On-screen keyboard autocompletion
	---@field returnKeyType KeyboardReturnType On-screen keyboard return key type
	---@field isNumeric boolean Whether the textfield object should only accept numeric values
	---@field allowNegative boolean Whether the numeric only textfield should accept negative values
	---@field allowDecimal boolean Whether the numeric only textfield should accept decimal values
	---@field customRegex string Custom regex string to match textfield input against
	---@field toggle boolean Whether the object will be used as a toggle
	---@field innerShadow number|number[]
	---@field shadowColor Color|Color[]
	---@field shadowOffset number
	---@field shapeType UIElementShape
	---@field rounded number|number[] Rounding size to use for an object with `ROUNDED` shapeType
	---@field scrollEnabled boolean
	---@field keyboard boolean True if we want to spawn the object with default keyboard handlers
	---@field permanentListener boolean
	---@field hoverSound SoundId
	---@field upSound SoundId
	---@field downSound SoundId
	---@field clickThrough boolean
	---@field hoverThrough boolean
	---@field bgGradient Color[] List of two colors to generate gradient with
	---@field bgGradientMode PlayerBody Toribash bodypart id to base gradient UV on
	---@field maxLength integer Optional max length value for text fields

	---**Toribash GUI elements manager class**
	---
	---**Version 5.74**
	---* Replace `table.compare()` with `table.equals()` to make sure return value makes sense
	---* `UIElement.deltaClock` to track time since last rendered frame
	---* Text field max length support
	---
	---**Version 5.71**
	---* Minor performance improvements by using local references to frequently used global functions
	---
	---**Version 5.70**
	---* Keep a cached copy of `get_world_state()` result in `UIElement.WorldState` to reduce direct calls
	---* Do not use unpack() on colors for setColor() calls to slightly improve performance
	---
	---**Version 5.65:**
	---* Added `UIElement.onShow` callback function to execute at the end of `UIElement.show()` call
	---* `UIElement.killAction` and `UIElement.onShow` are now wrapped into pcall() to ensure default behavior proceeds uninterrupted in case of error
	---* Marked `UIElement.killAction` and `UIElement.onShow` as nullable
	---
	---**Version 5.62:**
	---* `UIElement.bgImageDefault` boolean value to tell which texture was loaded during `UIElement.updateImage()` call
	---
	---**Version 5.61:**
	---* On-screen keyboard customization support for text fields
	---
	---**Version 5.60:**
	---* Rewritten all keyboard handlers to make better use of SDL text input events
	---* `UIElement.keyboardHooks()` to initialize generic text field handlers on start
	---* `UIElement.mouseHooks()` is now an abstract class function
	---* `print` and `print_r` functions for easier debug
	---* Gradient generation support for generated UIElements
	---
	---**Version 1.6:**
	---* `hoverThrough` support
	---* `UIElement.clock` value to store last graphics update time tick
	---* Use UITween class for framerate independent animations
	---
	---**Version 1.5:**
	---* `imageHoverColor` and `imagePressedColor` support
	---* `UIElement:qsort()`, `UIElement:runCmd()` marked as deprecated
	---* New `table.qsort()`, `table.reverse()`, `table.clone()`, `table.compare()`, `table.empty()`, `table.unpack_all()` functions to replace legacy names
	---* New `string.escape()` to replace legacy strEsc() function
	---* Guid() is now `generate_uid()` to prevent confusion with a potential class name
	---* debugEcho() is now `print_r(mixed data, boolean returnString)`
	---
	---**Version 1.4:**
	---* `UIElement:mouseHooks()` is now initialized when this script is loaded to ensure it isn't required in every script that requires UIElements
	---* Moved scrollable list update on mouse bar scroll from mouse_move hook to pre_draw for better performance
	---* Different top/bottom rounding support and `roundedInternal` UIElement field
	---* Added EmmyLua annotations for some methods
	---@class UIElement
	---@field lightUIMode boolean Disables animations and some unimportant effects to improve GUI performance on lower end machines, this is based on `uilight` option
	---@field globalid integer Global ID to use for UIElement internal update / display loops
	---@field parent UIElement Parent element
	---@field child UIElement[] Table containing the list of all children of an object
	---@field pos Vector2Base Object's **absolute** position
	---@field shift? Vector2Base Object position **relative to its parent**
	---@field size UIElementSize Object size
	---@field uiColor Color Default text color to be used for uiText() calls
	---@field uiShadowColor Color Default text shadow color to be used for uiText() calls
	---@field viewport boolean True for UIElement objects that act as a 3D viewport holder
	---@field bgColor Color Object's background color
	---@field hoverColor Color Object's background color when in hover state. *Only used when object is interactive*.
	---@field pressedColor Color Object's background color when in pressed state. *Only used when object is interactive*.
	---@field inactiveColor Color Object's background color when in disabled state. *Only used when object is interactive*.
	---@field animateColor Color Object's current background color when in normal or hover state. *Only used when object is interactive and UI animations are enabled*.
	---@field interactive boolean Whether the object is interactive
	---@field bgImage integer Object's image ID obtained from load_texture() call
	---@field bgImageDefault boolean Whether the loaded texture is a default fallback
	---@field disableUnload boolean True if object's image should not get unloaded when object is destroyed. **Only use this if you know what you're doing**.
	---@field drawMode integer Draw mode for normal (quad) objects
	---@field atlas Rect Atlas settings for patterned and atlas objects
	---@field imageColor Color Color modifier that should be applied to object's image. Default is `{ 1, 1, 1, 1 }`.
	---@field imageHoverColor Color Target image color modifier when UIElement is in hover state. *Only used when object is interactive*.
	---@field imagePressedColor Color Image color modifier when UIElement is in pressed state. *Only used when object is interactive*.
	---@field imageAnimateColor Color Current image color modifier when in normal or hover state. *Only used when object is interactive and UI animations are enabled*.
	---@field imageInactiveColor Color Image color modifier when UIElement is in inactive state. *Only used when object is interactive*.
	---@field keyboard boolean True for objects that currently handle keyboard events
	---@field textfield boolean Internal value to modify behavior for elements that are going to be used as text fields
	---@field textfieldstr string[] Text field data. Stored as a table to be able to access data by its reference. **Access UIElement.textfieldstr[1] for the actual string data of a text field**. *Only used for textfield objects*.
	---@field textfieldcursorlen integer Text field cursor internal length. *Only used for textfield objects*.
	---@field textfieldindex number Current input index (cursor position) for the text field. *Only used for textfield objects*.
	---@field textfieldsingleline boolean Whether the text field should accept multiline input. *Only used for textfield objects*.
	---@field textfieldkeepfocusonhide boolean Whether text field should keep or lose focus when hide() is called on it. Default is `false`.
	---@field inputType KeyboardInputType On-screen keyboard input type
	---@field autoCompletion boolean On-screen keyboard autocompletion
	---@field returnKeyType KeyboardReturnType On-screen keyboard return key type
	---@field toggle boolean Internal value to modify behavior for elements that are going to be used as toggles
	---@field innerShadow number[] Table containing top and bottom inner shadow size
	---@field shadowColor Color[] Table containing top and bottom inner shadow colors
	---@field shadowOffset number Custom text shadow offset value to use for uiText() rendering
	---@field shapeType UIElementShape Object's shape type. Can be either `SQUARE` (1) or `ROUNDED` (2).
	---@field roundedInternal number[] Values that the object will use for rounding edges (top and bottom)
	---@field rounded number Max value out of UIElement.roundedInternal values
	---@field isactive boolean Internal value to tell if an interactive object is currently active
	---@field scrollEnabled boolean If true, an interactive object will also handle mouse scroll events in its `UIElement.btnDown()` callback
	---@field hoverState UIElementBtnState Current mouse hover state of an object
	---@field pressedPos Vector2Base Internal table containing relative cursor position at the moment of `UIElement.btnDown()` call on an active scroll bar
	---@field permanentListener boolean True if we want an object with keyboard handlers to react to all keyboard events, even when not in focus. Permanent keyboard listeners will also not exit keyboard loop early.
	---@field hoverSound integer Sound ID to play when object enters `BTN_HVR` mouse hover state
	---@field hoverClock number Time for the BTN_HVR state enter
	---@field upSound integer Sound ID to play when object exits `BTN_DN` mouse hover state
	---@field downSound integer Sound ID to play when object enters `BTN_DN` mouse hover state
	---@field clickThrough boolean If true, successful click on an object will not exit mouse loop early
	---@field hoverThrough boolean If true, hovering over an object will not exit mouse loop early
	---@field displayed boolean Read-only value to tell if the object is currently being displayed
	---@field destroyed boolean Read-only value to indicate the object has been destroyed. Use this to check whether the UIElement still exists when a UIElement:kill() function may have been called on its reference elsewhere.
	---@field killAction function? Additional callback to be executed when object is being destroyed
	---@field onShow function? Additional callback to executed at the end of object's `UIElement.show()` call
	---@field scrollBar UIScrollBar Reference to scrollable list holder's scroll bar
	---@field __positionDirty boolean Read-only value to tell the UIElement internal loops to refresh element position
	---@field scrollableListTouchScrollActive boolean Read-only value used for scrollable list view elements on touch devices
	---@field prevInput UIElement Previous input element, set with `UIElement.addTabSwitchPrev()`
	---@field nextInput UIElement Next input element, set with `UIElement.addTabSwitch()`
	---@field str string Cached string value used by `UIElement.uiText()`
	---@field dispstr string[] Cached per-line representation of element text rendered by `UIElement.uiText()`
	---@field strindices integer[] Cached string lengths generated by `UIElement.uiText()` internals used for textfield objects.
	---@field textfieldmaxlength integer Maximum allowed length for textfield UIElements. 0 if no limit is specified.
	UIElement = {
		ver = 5.74,
		animationDuration = 0.1,
		longPressDuration = 0.25,
		lightUIMode = get_option("uilight") == 1
	}
	UIElement.__index = UIElement

	-- Whether UIElement.mouseHooks() has already been called to spawn mouse hooks
	---@type boolean
	UIElement.__mouseHooks = nil

	---Whether UIElement.keyboardHooks() has been called to initialize keyboard hooks
	---@type boolean
	UIElement.__keyboardHooks = nil

	---Whether UIElement.drawHooks() has been called to initialize helper drawing hook
	---@type boolean
	UIElement.__drawHooks = nil

	---Last rendering cycle timestamp
	---@type number
	UIElement.clock = os.clock_real()

	---Time since last rendered frame
	---@type number
	UIElement.deltaClock = 0

	---World state for current frame
	---@type WorldState
	UIElement.WorldState = get_world_state()

	---@class Vector2 : Vector2Base
	Vector2 = {}
	Vector2.__index = Vector2
end

---Initializes a **Vector2** object
---@param x number?
---@param y number?
---@return Vector2
function Vector2.New(x, y)
	local vector = { x = x or 0, y = y or 0 }
	setmetatable(vector, Vector2)
	return vector
end

---Returns vector magnitude
---@return number
function Vector2:magnitude()
	return math.sqrt(self.x * self.x + self.y * self.y)
end

---Returns a normalized version of a vector
---@return Vector2
function Vector2:normalize()
	local mag = self:magnitude()
	if (mag == 0) then
		return Vector2.New(self.x, self.y)
	end
	return Vector2.New(self.x / mag, self.y / mag)
end

---Returns a vector with the clamped magnitude
---@param max number
---@return Vector2
function Vector2:clampMagnitude(max)
	if (max <= 0) then return Vector2.New() end
	local mag = self:magnitude()
	if (max <= mag) then
		return Vector2.New(self.x, self.y)
	end
	local f = math.min(mag, max) / mag
	return Vector2.New(self.x * f, self.y * f)
end

---Returns a vector that represents current vector multiplied by a given value
---@param n number
function Vector2:multiply(n)
	return Vector2.New(self.x * n, self.y * n)
end

---Returns a vector produced by adding given vector to current one
---@param other Vector2|Vector2Base
---@return Vector2
function Vector2:add(other)
	return Vector2.New(self.x + other.x, self.y + other.y)
end

---Callback function triggered on text input event while UIElement is active and focused
---@param input string
UIElement.textInput = function(input) end

---Custom callback function triggered on text input event while UIElement is active and focused
UIElement.textInputCustom = function() end

-- Callback function triggered on any keyboard key down event while UIElement is active
---@param key ?number Pressed key's keycode
---@return number|nil
UIElement.keyDown = function(key) end

-- Callback function triggered on any keyboard key up event while UIElement is active
---@param key ?number Pressed key's keycode
---@return number|nil
UIElement.keyUp = function(key) end

-- Custom callback function triggered on any keyboard key down event while UIElement is active
---@param key ?number Pressed key's keycode
---@return number|nil
UIElement.keyDownCustom = function(key) end

-- Custom callback function triggered on any keyboard key up event while UIElement is active
---@param key ?number Pressed key's keycode
---@return number|nil
UIElement.keyUpCustom = function(key) end

-- Callback function triggered on mouse button down event when cursor is within object transform
---@param buttonId ?number Mouse button ID associated with the event
---@param x ?number Mouse cursor X position associated with the event
---@param y ?number Mouse cursor Y position associated with the event
UIElement.btnDown = function(buttonId, x, y) end

-- Callback function triggered on mouse button up event when cursor is within object transform
---@param buttonId ?number Mouse button ID associated with the event
---@param x ?number Mouse cursor X position associated with the event
---@param y ?number Mouse cursor Y position associated with the event
UIElement.btnUp = function(buttonId, x, y) end

-- Callback function triggered on mouse move event when cursor is within object transform
---@param x ?number Mouse cursor X position associated with the event
---@param y ?number Mouse cursor Y position associated with the event
UIElement.btnHover = function(x, y) end

-- Callback function triggered on right mouse button up event when cursor is within object transform\
-- We use a separate event because normally right mouse clicks do not produce events so behavior won't be the same
---@param buttonId ?number Mouse button ID associated with the event
---@param x ?number Mouse cursor X position associated with the event
---@param y ?number Mouse cursor Y position associated with the event
UIElement.btnRightUp = function(buttonId, x, y) end

-- Callback function triggered on mouse button up event when object received button down event but
-- cursor has since moved outside object transform
---@param buttonId ?number Mouse button ID associated with the event
---@param x ?number Mouse cursor X position associated with the event
---@param y ?number Mouse cursor Y position associated with the event
UIElement.btnUpOutside = function(buttonId, x, y) end

-- Spawn a new UI Element
---@param _self UIElement
---@param o UIElementOptions Options to use for spawning the new object
---@return UIElement
---@overload fun(o: UIElementOptions): UIElement
function UIElement.new(_self, o)
	if (o == nil) then
		if (_self ~= nil) then
			---@diagnostic disable-next-line: cast-local-type
			o = _self
		else
			error("Invalid argument #1 provided to UIElement.new(o: UIElementOptions)")
		end
	end

	---@type UIElement
	local elem = {	globalid = 1000,
					child = {},
					pos = {},
					shift = {},
					bgColor = { 1, 1, 1, 0 },
					innerShadow = { 0, 0 },
					__positionDirty = true
					}
	setmetatable(elem, UIElement)

	if (o.parent) then
		elem.globalid = o.parent.globalid
		elem.parent = o.parent
		elem.uiColor = o.parent.uiColor
		elem.uiShadowColor = o.parent.uiShadowColor
		table.insert(elem.parent.child, elem)
		if (o.parent.viewport) then
			elem.pos.x = o.pos[1]
			elem.pos.y = o.pos[2]
			elem.pos.z = o.pos[3]
		else
			elem.shift.x = o.pos[1]
			elem.shift.y = o.pos[2]
			elem.size = { w = o.size[1], h = o.size[2] }
		end
	else
		elem.pos.x = o.pos[1]
		elem.pos.y = o.pos[2]
		elem.size = { w = o.size[1], h = o.size[2] }
	end
	if (o.globalid) then
		elem.globalid = o.globalid
	end
	if (o.uiColor) then
		elem.uiColor = o.uiColor
	end
	if (o.uiShadowColor) then
		elem.uiShadowColor = o.uiShadowColor
	end
	if (o.shadowOffset) then
		elem.shadowOffset = o.shadowOffset
	end
	if (o.viewport) then
		elem.viewport = o.viewport
	end
	if (o.bgGradient) then
		elem:updateImageGradient(o.bgGradient[1], o.bgGradient[2], o.bgGradientMode)
	elseif (o.bgColor) then
		elem.bgColor = o.bgColor
	end
	if (o.bgImage or elem.bgImage) then
		elem.disableUnload = o.disableUnload
		elem.drawMode = o.imagePatterned and 1 or 0
		elem.drawMode = o.imageAtlas and 2 or elem.drawMode
		elem.imageColor = o.imageColor or { 1, 1, 1, 1 }

		elem.atlas = o.atlas or {}
		elem.atlas.x = elem.atlas.x or 0
		elem.atlas.y = elem.atlas.y or 0
		elem.atlas.w = elem.atlas.w or elem.size.w
		elem.atlas.h = elem.atlas.h or elem.size.h

		if (elem.bgImage == nil) then
			if (type(o.bgImage) == "table") then
				elem:updateImage(o.bgImage[1], o.bgImage[2])
			else
				---@diagnostic disable-next-line: param-type-mismatch
				elem:updateImage(o.bgImage)
			end
		end
	end

	-- Textfield value is a table to allow proper initiation / use after obj is created
	if (o.textfield) then
		elem.textfield = o.textfield
		---@diagnostic disable-next-line: assign-type-mismatch
		elem.textfieldstr = o.textfieldstr and (type(o.textfieldstr) == "table" and o.textfieldstr or { o.textfieldstr .. '' }) or { "" }
		elem.inputType = o.inputType or KEYBOARD_INPUT.ASCII
		elem.autoCompletion = o.autoCompletion == nil and true or o.autoCompletion
		elem.returnKeyType = o.returnKeyType or KEYBOARD_RETURN.DEFAULT
		elem.textfieldindex = utf8.safe_len(elem.textfieldstr[1]) or 0
		elem.textfieldcursorlen = 1
		elem.textfieldsingleline = o.textfieldsingleline
		elem.textfieldkeepfocusonhide = o.textfieldkeepfocusonhide
		elem.textfieldmaxlength = o.maxLength or 0
		---@diagnostic disable-next-line: duplicate-set-field
		elem.textInput = function(input) elem:textfieldInput(input, o.isNumeric, o.allowNegative, o.allowDecimal, o.customRegex) end
		---@diagnostic disable-next-line: duplicate-set-field
		elem.keyDown = function(key)
				if (elem:textfieldKeyDown(key) and elem.textInputCustom) then
					-- We have updated textfield input and have a custom text input function defined
					-- Fire a textInputCustom() call for seamless behavior across all input field actions
					elem.textInputCustom()
				end
			end
		---@diagnostic disable-next-line: duplicate-set-field
		elem.keyUp = function(key) elem:textfieldKeyUp(key) end
		table.insert(UIKeyboardHandler, elem)
	end
	if (o.toggle) then
		elem.toggle = o.toggle
		---@diagnostic disable-next-line: duplicate-set-field
		elem.keyUp = function(key) elem:textfieldKeyUp(key) end
		table.insert(UIKeyboardHandler, elem)
	end
	if (o.innerShadow and o.shadowColor) then
		if (type(o.shadowColor[1]) == "table") then
			elem.shadowColor = o.shadowColor
		else
			elem.shadowColor = { o.shadowColor, o.shadowColor }
		end
		---@diagnostic disable-next-line: assign-type-mismatch
		elem.innerShadow = type(o.innerShadow) == "table" and o.innerShadow or { o.innerShadow, o.innerShadow }
	end
	if (o.shapeType == ROUNDED and o.rounded) then
		elem.setRounded(elem, o.rounded)
		-- Light UI mode - don't add rounded corners if it's just for cosmetics
		if (not UIElement.lightUIMode or elem.rounded > elem.size.w / 4) then
			elem.shapeType = o.shapeType
		end
	end
	if (o.interactive) then
		elem.interactive = o.interactive
		elem.isactive = true
		elem.scrollEnabled = o.scrollEnabled or false
		elem.hoverColor = o.hoverColor or nil
		elem.pressedColor = o.pressedColor or nil
		elem.inactiveColor = o.inactiveColor or o.bgColor
		elem.animateColor = table.clone(elem.bgColor)
		if (elem.bgImage) then
			elem.imageHoverColor = o.imageHoverColor or nil
			elem.imagePressedColor = o.imagePressedColor or nil
			elem.imageInactiveColor = o.imageInactiveColor or nil
			elem.imageAnimateColor = table.clone(elem.imageColor)
		end
		elem.hoverState = BTN_NONE
		elem.hoverClock = UIElement.clock
		elem.clickThrough = o.clickThrough
		elem.hoverThrough = o.hoverThrough
		elem.hoverSound = o.hoverSound
		elem.upSound = o.upSound
		elem.downSound = o.downSound
		elem.pressedPos = { x = 0, y = 0 }
		table.insert(UIMouseHandler, elem)
	end
	if (o.keyboard) then
		elem.permanentListener = o.permanentListener
		table.insert(UIKeyboardHandler, elem)
	end

	---Only add root elements to UIElementManager to decrease table traversal speed
	if (elem.parent == nil) then
		table.insert(UIElementManager, elem)
	end

	-- Display is enabled by default, comment this out to disable
	if (elem.viewport or (elem.parent and elem.parent.viewport)) then
		--table.insert(UIViewportManager, elem)
	else
		UIVisualManager[elem.globalid] = UIVisualManager[elem.globalid] or { }
		table.insert(UIVisualManager[elem.globalid], elem)
	end

	-- Force update global x/y pos when spawning element
	elem:updatePos()
	elem.displayed = true

	return elem
end

-- Spawns a new UIElement and sets the calling object as its parent
---@param o UIElementOptions
---@param copyShape? boolean Whether to copy `shapeType` and `rounded` values to the new object
---@return UIElement
function UIElement:addChild(o, copyShape)
	if (o.shift) then
		o.pos = { o.shift[1], o.shift[2] }
		o.size = { self.size.w - o.shift[1] * 2, self.size.h - o.shift[2] * 2 }
	else
		o.pos = o.pos and o.pos or { 0, 0 }
		o.size = o.size and o.size or { self.size.w, self.size.h }
	end

	if (copyShape) then
		o.shapeType = o.shapeType and o.shapeType or self.shapeType
		o.rounded = o.rounded and o.rounded or table.clone(self.roundedInternal)
	end

	o.parent = self
	return UIElement.new(o)
end

-- Specifies rounding value to be used for UIElements with ROUNDED shape type
---@param rounded number|number[]
function UIElement:setRounded(rounded)
	if (type(rounded) ~= "table") then
		self.roundedInternal = { tonumber(rounded) or 0, tonumber(rounded) or 0 }
	else
		self.roundedInternal = { rounded[1], rounded[#rounded] }
	end

	local minSize = math.min(table.unpack_all(self.size))
	local minRounded = self.roundedInternal[1] + self.roundedInternal[2] > minSize and minSize / 2 or math.max(unpack(self.roundedInternal))

	self.rounded = 0
	for i, v in pairs(self.roundedInternal) do
		if (v > minRounded) then
			self.roundedInternal[i] = minRounded
		end
		self.rounded = math.max(self.rounded, self.roundedInternal[i])
	end

	---With GLES we have a perfect disk shader that allows us to draw circles more efficiently
	---Set slices to 0 to use it instead of rendering disks made out of vertices
	self.diskSlices = is_mobile and 0 or math.min(self.rounded * 5, 50)
end

-- Adds mouse handlers to use for an interactive UIElement object
---@param btnDown? function Button down callback function
---@param btnUp? function Button up callback function
---@param btnHover? function Mouse hover callback function
---@param btnRightUp? function Right mouse button up callback function
---@param btnUpOutside? function Outside button up callback function
function UIElement:addMouseHandlers(btnDown, btnUp, btnHover, btnRightUp, btnUpOutside)
	if (btnDown) then
		self.btnDown = btnDown
	end
	if (btnUp) then
		self.btnUp = btnUp
	end
	if (btnHover) then
		self.btnHover = btnHover
	end
	if (btnRightUp) then
		self.btnRightUp = btnRightUp
	end
	if (btnUpOutside) then
		self.btnUpOutside = btnUpOutside
	end
end

---Shorthand function to add mouse button down handler
---@param func function
function UIElement:addMouseDownHandler(func)
	self:addMouseHandlers(func)
end

---Shorthand function to add mouse button up handler
---@param func function
function UIElement:addMouseUpHandler(func)
	self:addMouseHandlers(nil, func)
end

---Shorthand function to add mouse move handler
---@param func function
function UIElement:addMouseMoveHandler(func)
	self:addMouseHandlers(nil, nil, func)
end

---Shorthand function to add mouse right button up handler
---@param func function
function UIElement:addMouseUpRightHandler(func)
	self:addMouseHandlers(nil, nil, nil, func)
end

---Shorthand function to add mouse button up handler when we're while no longer hovering over the object
---@param func function
function UIElement:addMouseUpOutsideHandler(func)
	self:addMouseHandlers(nil ,nil, nil, nil, func)
end

-- Adds keyboard handlers to use for an interactive UIElement object
---@param keyDown? function Keyboard key down callback function
---@param keyUp? function Keyboard key up callback function
function UIElement:addKeyboardHandlers(keyDown, keyUp)
	if (keyDown) then
		self.keyDownCustom = keyDown
	end
	if (keyUp) then
		self.keyUpCustom = keyUp
	end
end

---Adds input handler to use for a textfield object
---@param func? function
function UIElement:addInputCallback(func)
	if (func) then
		self.textInputCustom = func
	end
end

-- Adds enter key handler for an interactive UIElement object
---@param func function
function UIElement:addEnterAction(func)
	self.enteraction = func
end

-- Removes currently set enter key handler
function UIElement:removeEnterAction()
	self.enteraction = nil
end

-- Adds tab key handler for an interactive UIElement object
---@param func function
function UIElement:addTabAction(func)
	self.tabaction = func
end

-- Removes currently set tab key handler
function UIElement:removeTabAction()
	self.tabaction = nil
end

---Adds a function to be executed when a focusable element is tabbed out of
---@param func function
function UIElement:addOnLoseTabFocus(func)
	self.onLoseFocus = func
end

---Removes a function that is executed when a focusable element is tabbed out of
function UIElement:removeOnLoseTabFocus()
	self.onLoseFocus = nil
end

---Adds a function to be executed when a focusable element is tabbed into
---@param func function
function UIElement:addOnReceiveTabFocus(func)
	self.onReceiveFocus = func
end

---Removes a function that is executed when a focusable element is tabbed into
function UIElement:removeOnReceiveTabFocus()
	self.onReceiveFocus = nil
end

---Sets the previous element to switch focus to when pressing `SHIFT` + `TAB`
---@param element UIElement
---@param btnDownArg ?table Any additional arguments to be used by element's `btnDown()` event
function UIElement:addTabSwitchPrev(element, btnDownArg)
	self:addTabSwitch(element, btnDownArg, true)
end

---Sets the element to switch focus to when pressing `TAB`
---@param element UIElement
---@param btnDownArg ?table Any additional arguments to be used by element's `btnDown()` event
---@param prev ?boolean
function UIElement:addTabSwitch(element, btnDownArg, prev)
	local btnDownArg = btnDownArg or {}
	local action = prev and "tabswitchprevaction" or "tabswitchaction"
	local targetName = prev and "prevInput" or "nextInput"
	self[targetName] = element
	self[action] = function()
		if (self.onLoseFocus) then
			self.onLoseFocus()
		end
		for _, v in pairs(UIKeyboardHandler) do
			v.keyboard = false
		end
		element.hoverState = BTN_HVR
		element.btnDown(unpack(btnDownArg))
		if (element.textfield) then
			element.keyboard = true
			disable_camera_movement()
		end
		if (element.onReceiveFocus) then
			element.onReceiveFocus()
		end
	end
end

---Clears the currently set `TAB` switch action
function UIElement:removeTabSwitch()
	self.tabswitchaction = nil
end

---Clears the currently set `SHIFT` + `TAB` switch action
function UIElement:removeTabSwitchPrev()
	self.tabswitchprevaction = nil
end

---Internal function to reload scrollable list elements. \
---*You likely don't need to call it manually.*
---@param listHolder UIElement
---@param listElements UIElement[]
---@param toReload UIElement
---@param enabled UIElement[]
---@param orientation UIElementScrollMode
function UIElement:reloadListElements(listHolder, listElements, toReload, enabled, orientation)
	local listElementSize, shiftVal
	if (orientation == SCROLL_VERTICAL) then
		listElementSize = listElements[1].size.h
		shiftVal = listHolder.shift.y + self.size.h
	else
		listElementSize = listElements[1].size.w
		shiftVal = listHolder.shift.x + self.size.w
	end
	local checkPos = math.abs(math.ceil(-shiftVal / listElementSize))

	for i = #enabled, 1, -1 do
		enabled[i]:hide(true)
		table.remove(enabled)
	end

	if (checkPos > 0 and checkPos * listElementSize + shiftVal > 0) then
		if (listElements[checkPos]) then
			listElements[checkPos]:show(true)
			table.insert(enabled, listElements[checkPos])
		end
	end
	while ((shiftVal + checkPos * listElementSize >= 0) and ((orientation == SCROLL_VERTICAL and listHolder.shift.y or listHolder.shift.x) + checkPos * listElementSize <= 0) and (checkPos < #listElements)) do
		listElements[checkPos + 1]:show(true)
		table.insert(enabled, listElements[checkPos + 1])
		checkPos = checkPos + 1
	end

	toReload:reload()
end

---Shorthand function to initialize a horizontal scrollable list with a scroll bar
---@param listHolder UIElement
---@param listElements UIElement[]
---@param toReload UIElement
---@param posShift ?number[]
---@param scrollSpeed ?number
---@param scrollIgnoreOverride ?boolean
function UIElement:makeHorizontalScrollBar(listHolder, listElements, toReload, posShift, scrollSpeed, scrollIgnoreOverride)
	self:makeScrollBar(listHolder, listElements, toReload, posShift, scrollSpeed, scrollIgnoreOverride, SCROLL_HORIZONTAL)
end

---Function to initialize a scrollable list with a scroll bar. \
---**Important: all list elements must have the same height / width depending on list orientation.**
---@param listHolder UIElement Holder element for all list elements
---@param listElements UIElement[] List of elements that should be scrollable
---@param toReload UIElement Holder element that should be rendered on top of scrollable elements
---@param posShift ?number[]
---@param scrollSpeed ?number
---@param scrollIgnoreOverride ?boolean
---@param orientation ?UIElementScrollMode
function UIElement:makeScrollBar(listHolder, listElements, toReload, posShift, scrollSpeed, scrollIgnoreOverride, orientation)
	local scrollSpeed = scrollSpeed or 1
	local posShift = posShift or { 0 }
	self.orientation = orientation or SCROLL_VERTICAL

	local enabled = {}
	if (self.orientation == SCROLL_VERTICAL) then
		listHolder:moveTo(0, listHolder.shift.y == 0 and -listHolder.size.h or listHolder.shift.y)
	else
		listHolder:moveTo(listHolder.shift.x == 0 and -listHolder.size.w or listHolder.shift.x)
	end
	self.pressedPos = { x = 0, y = 0 }

	self.listReload = function() listHolder.parent:reloadListElements(listHolder, listElements, toReload, enabled, self.orientation) end
	---@diagnostic disable-next-line: undefined-field
	self.scrollReload = function() if (self.holder) then self.holder:reload() end self:reload() end

	self:barScroll(listElements, listHolder, toReload, posShift[1], enabled, true)
	UIElement.updatePos(listHolder)
	local targetPos = nil

	self:addMouseHandlers(
		function(s, x, y)
			if (is_mobile and s < 4) then
				disable_mouse_camera_movement()
			end
			local scrollIgnore = UIScrollbarIgnore
			if (scrollIgnoreOverride and scrollIgnore) then
				UIScrollbarIgnore = false
			end
			local scrollSuccessful = false
			if (s < 4) then
				self.pressedPos = self:getLocalPos(x,y)
				self.hoverState = BTN_DN
			elseif (not UIScrollbarIgnore and ((#UIScrollbarHandler == 1 and listHolder.scrollBar ~= self) or
					(MOUSE_X > listHolder.parent.pos.x and MOUSE_X < listHolder.parent.pos.x + listHolder.parent.size.w and MOUSE_Y > listHolder.parent.pos.y and MOUSE_Y < listHolder.parent.pos.y + listHolder.parent.size.h))) then
				self:mouseScroll(listElements, listHolder, toReload, y * scrollSpeed, enabled)
				posShift[1] = self.orientation == SCROLL_VERTICAL and self.shift.y or self.shift.x
				scrollSuccessful = true
			end
			if (scrollIgnore and not UIScrollbarIgnore) then
				UIScrollbarIgnore = true
			end
			return scrollSuccessful
		end, function()
			self.scrollReload()
			if (is_mobile) then
				enable_mouse_camera_movement()
			end
		end,
		function(x, y)
			if (self.hoverState == BTN_DN) then
				if (self.orientation == SCROLL_VERTICAL) then
					targetPos = self:getLocalPos(x,y).y - self.pressedPos.y + self.shift.y
					posShift[1] = self.shift.y
				else
					targetPos = self:getLocalPos(x,y).x - self.pressedPos.x + self.shift.x
					posShift[1] = self.shift.x
				end
			end
		end, nil, function()
			self.scrollReload()
			if (is_mobile) then
				enable_mouse_camera_movement()
			end
		end)

	if (not self.isScrollBar) then
		self.isScrollBar = true
		table.insert(UIScrollbarHandler, self)
	end

	local barScroller = self:addChild({})
	barScroller.uid = generate_uid()
	barScroller.killAction = function()
		if (listHolder.parent.scrollableListTouchScrollActive) then
			listHolder.parent.btnUp()
		end
		remove_hook("pre_draw", "__uiManagerBarScroller" .. barScroller.uid)
		remove_hook("pre_draw", "__uiManagerTouchScroller" .. barScroller.uid)
	end
	add_hook("pre_draw", "__uiManagerBarScroller" .. barScroller.uid, function()
			if (targetPos ~= nil) then
				self:barScroll(listElements, listHolder, toReload, targetPos, enabled)
				targetPos = nil
			end
		end)

	local lastListHolderVal = -1
	local deltaChange = 0
	local lastClock = UIElement.clock
	listHolder.parent:addMouseHandlers(function(_, x, y)
			disable_mouse_camera_movement()
			listHolder.parent.scrollableListTouchScrollActive = true
			lastListHolderVal = (self.orientation == SCROLL_VERTICAL) and y or x
		end, function()
			listHolder.parent.scrollableListTouchScrollActive = false
			lastListHolderVal = -1
			enable_mouse_camera_movement()
		end, function(x, y)
			if (listHolder.parent.scrollableListTouchScrollActive) then
				lastClock = UIElement.clock
				local targetValue = (self.orientation == SCROLL_VERTICAL) and y or x
				deltaChange = lastListHolderVal - targetValue
				lastListHolderVal = targetValue
			end
		end, nil, function()
			listHolder.parent.scrollableListTouchScrollActive = false
			lastListHolderVal = -1
			enable_mouse_camera_movement()
		end)
	add_hook("pre_draw", "__uiManagerTouchScroller" .. barScroller.uid, function()
			if (listHolder.parent.scrollableListTouchScrollActive and listHolder.parent.hoverState == BTN_NONE) then
				listHolder.parent.scrollableListTouchScrollActive = false
				lastListHolderVal = -1
			elseif (listHolder.parent.hoverState == BTN_DN and UIElement.clock > lastClock + 0.035) then
				local targetValue = (self.orientation == SCROLL_VERTICAL) and MOUSE_Y or MOUSE_X
				deltaChange = lastListHolderVal - targetValue
				lastListHolderVal = targetValue
			end

			if (math.abs(deltaChange) > 0) then
				if (lastListHolderVal < 0) then
					deltaChange = UITween.SineTween(deltaChange, 0, (UIElement.clock - lastClock) * 2)
				end
				self:touchScroll(listElements, listHolder, toReload, deltaChange, enabled)
				posShift[1] = self.orientation == SCROLL_VERTICAL and self.shift.y or self.shift.x
			end
		end)

	call_hook("mouse_move", MOUSE_X, MOUSE_Y)
end

---Internal function to handle mouse wheel scrolling for lists. \
---*You likely don't need to call this manually.*
---@param listElements UIElement[]
---@param listHolder UIElement
---@param toReload UIElement
---@param scroll number
---@param enabled UIElement[]
function UIElement:mouseScroll(listElements, listHolder, toReload, scroll, enabled)
	if (self.orientation == SCROLL_VERTICAL) then
		local elementHeight = listElements[1].size.h
		local listHeight = #listElements * elementHeight
		if (listHeight <= listHolder.size.h) then
			return
		end
		local oldShift = listHolder.shift.y
		if (listHolder.shift.y + scroll * elementHeight > -listHolder.size.h) then
			self:moveTo(self.shift.x, 0)
			listHolder:moveTo(listHolder.shift.x, -listHolder.size.h)
		elseif (listHolder.shift.y + scroll * elementHeight < -listHeight) then
			self:moveTo(self.shift.x, self.parent.size.h - self.size.h)
			listHolder:moveTo(listHolder.shift.x, -listHeight)
		else
			listHolder:moveTo(listHolder.shift.x, listHolder.shift.y + scroll * elementHeight)
			local scrollProgress = -(listHolder.size.h + listHolder.shift.y) / (listHeight - listHolder.size.h)
			self:moveTo(self.shift.x, (self.parent.size.h - self.size.h) * scrollProgress)
		end
		if (oldShift ~= listHolder.shift.y) then
			self.scrollReload()
			self.listReload()
		end
	else
		local elementWidth = listElements[1].size.w
		local listWidth = #listElements * elementWidth
		if (listWidth <= listHolder.size.w) then
			return
		end
		local oldShift = listHolder.shift.x
		if (listHolder.shift.x + scroll * elementWidth > -listHolder.size.w) then
			self:moveTo(0, self.shift.y)
			listHolder:moveTo(-listHolder.size.w, listHolder.shift.y)
		elseif (listHolder.shift.x + scroll * elementWidth < -listWidth) then
			self:moveTo(self.parent.size.w - self.size.w, self.shift.y)
			listHolder:moveTo(-listWidth, listHolder.shift.y)
		else
			listHolder:moveTo(listHolder.shift.x + scroll * elementWidth, listHolder.shift.y)
			local scrollProgress = -(listHolder.size.w + listHolder.shift.x) / (listWidth - listHolder.size.w)
			self:moveTo((self.parent.size.w - self.size.w) * scrollProgress, self.shift.y)
		end
		if (oldShift ~= listHolder.shift.x) then
			self.scrollReload()
			self.listReload()
		end
	end
end

---Internal function to handle scroll bar scrolling for lists. \
---*You likely don't need to call this manually.*
---@param listElements UIElement[]
---@param listHolder UIElement
---@param toReload UIElement
---@param posShift number
---@param enabled UIElement[]
---@param override ?boolean
function UIElement:barScroll(listElements, listHolder, toReload, posShift, enabled, override)
	if (#listElements == 0) then return end
	if (self.orientation == SCROLL_VERTICAL) then
		local sizeH = math.floor(self.size.h / 4)
		local listHeight = listElements[1].size.h * #listElements
		if (listHeight <= listHolder.size.h and not override) then
			return
		end

		if (posShift <= 0) then
			if (self.pressedPos.y < sizeH) then
				self.pressedPos.y = sizeH
			end
			self:moveTo(self.shift.x, 0)
			listHolder:moveTo(listHolder.shift.x, -listHolder.size.h)
		elseif (posShift >= self.parent.size.h - self.size.h) then
			if (self.pressedPos.y > self.parent.size.h - sizeH) then
				self.pressedPos.y = self.parent.size.h - sizeH
			end
			self:moveTo(self.shift.x, self.parent.size.h - self.size.h)
			listHolder:moveTo(listHolder.shift.x, -listHeight)
		else
			self:moveTo(self.shift.x, posShift)
			local scrollProgress = self.shift.y / (self.parent.size.h - self.size.h)
			listHolder:moveTo(listHolder.shift.x, -listHolder.size.h + (listHolder.size.h - listHeight) * scrollProgress)
		end
	else
		local sizeW = math.floor(self.size.w / 4)
		local listWidth = listElements[1].size.w * #listElements
		if (listWidth <= listHolder.size.w) then
			return
		end

		if (posShift <= 0) then
			if (self.pressedPos.x < sizeW) then
				self.pressedPos.x = sizeW
			end
			self:moveTo(0, self.shift.y)
			listHolder:moveTo(-listHolder.size.w, listHolder.shift.y)
		elseif (posShift >= self.parent.size.w - self.size.w) then
			if (self.pressedPos.x > self.parent.size.w - sizeW) then
				self.pressedPos.x = self.parent.size.w - sizeW
			end
			self:moveTo(self.parent.size.w - self.size.w, self.shift.y)
			listHolder:moveTo(-listWidth, listHolder.shift.y)
		else
			self:moveTo(posShift, self.shift.y)
			local scrollProgress = self.shift.x / (self.parent.size.w - self.size.w)
			listHolder:moveTo(-listHolder.size.w + (listHolder.size.w - listWidth) * scrollProgress, listHolder.shift.y)
		end
	end

	listHolder.parent:reloadListElements(listHolder, listElements, toReload, enabled, self.orientation)
end

---Internal function to handle list scrolling with touch input. \
---*You likely don't need to call this manually.*
---@param listElements UIElement[]
---@param listHolder UIElement
---@param toReload UIElement
---@param scrollDelta number
---@param enabled UIElement[]
function UIElement:touchScroll(listElements, listHolder, toReload, scrollDelta, enabled)
	if (#listElements == 0) then return end

	if (self.orientation == SCROLL_VERTICAL) then
		local listHeight = #listElements * listElements[1].size.h
		if (listHeight <= listHolder.size.h) then
			return
		end

		if (scrollDelta > 0) then
			scrollDelta = -1 * math.min(scrollDelta, listHeight + listHolder.shift.y)
		else
			scrollDelta = -1 * math.max(scrollDelta, listHolder.shift.y + listHolder.size.h)
		end

		if (scrollDelta ~= 0) then
			listHolder:moveTo(nil, scrollDelta, true)

			local scrollProgress = -(listHolder.size.h + listHolder.shift.y) / (listHeight - listHolder.size.h)
			self:moveTo(nil, (self.parent.size.h - self.size.h) * scrollProgress)

			self.listReload()
		end
	else
		local listWidth = #listElements * listElements[1].size.w
		if (listWidth <= listHolder.size.w) then
			return
		end

		if (scrollDelta > 0) then
			scrollDelta = -1 * math.min(scrollDelta, listWidth + listHolder.shift.x)
		else
			scrollDelta = -1 * math.max(scrollDelta, listHolder.shift.x + listHolder.size.w)
		end

		if (scrollDelta ~= 0) then
			listHolder:moveTo(scrollDelta, nil, true)

			local scrollProgress = -(listHolder.size.w + listHolder.shift.x) / (listWidth - listHolder.size.w)
			self:moveTo((self.parent.size.w - self.size.w) * scrollProgress, nil)

			self.listReload()
		end
	end
end

-- Sets the specified function to run when UIElement is displayed
---@param overrideDefault boolean If true, will disable default UIElement rendering and only run the specified function
---@param func function Custom function to run when object is displayed
---@param drawBefore? boolean If true, will assign a function to run **before** the default rendering function
---@overload fun(self: UIElement, func: function, drawBefore?: boolean)
function UIElement:addCustomDisplay(overrideDefault, func, drawBefore)
	---@type boolean|function|nil
	local drawBeforeFunc = drawBefore
	if (type(overrideDefault) == "function") then
		drawBeforeFunc = func
		func = overrideDefault
		overrideDefault = false
	end

	self.customDisplayOnly = overrideDefault
	if (drawBeforeFunc) then
		self.customDisplayBefore = func
	else
		self.customDisplay = func
	end
	if (func) then
		func(true)
	end
end

-- Destroys current UIElement object
---@param childOnly? boolean If true, will only destroy current object's children and keep the object itself
function UIElement:kill(childOnly)
	for _, v in pairs(self.child) do
		if (v.kill) then
			v:kill()
		end
	end
	if (childOnly) then
		self.child = {}
		return
	end
	if (self.destroyed) then
		return
	end

	if (self.killAction) then
		pcall(self.killAction)
	end

	self:hide(true)
	if (self.isScrollBar) then
		for i,v in pairs(UIScrollbarHandler) do
			if (self == v) then
				table.remove(UIScrollbarHandler, i)
				break
			end
		end
	end
	if (self.bgImage) then self:updateImage(nil) end
	for i,v in pairs(UIElementManager) do
		if (self == v) then
			table.remove(UIElementManager, i)
			break
		end
	end

	self.destroyed = true
	self = nil
end

---Updates position for all children of current UIElement
function UIElement:updatePos()
	if (self.parent) then
		self:updateChildPos()
	end
	if (self.viewport) then return end
	for _, v in pairs(self.child) do
		v:updatePos()
	end
end

---Clears text field data and resets index to 0
function UIElement:clearTextfield()
	if (self.textfield) then
		self.textfieldstr[1] = ""
		self.textfieldindex = 0
	end
end

---Main UIElement loop that updates objects' position and displays them. \
---**This function must be run from `draw2d` hook to work correctly.**
---@param object UIElement
---@param globalid ?integer Global ID that the objects to display belong to
---@overload fun(globalid: integer)
function UIElement.drawVisuals(object, globalid)
	local globalid = (type(object) == "table" and (object.globalid or globalid) or object)
	if (UIVisualManager[globalid] == nil) then return end

	for _, v in pairs(UIElementManager) do
		if (v.globalid == globalid and v.parent == nil) then
			v:updatePos()
		end
	end
	for _, v in pairs(UIVisualManager[globalid]) do
		v:display()
	end
end

---Legacy UIElement loop to display viewport elements. \
---***UIElement*** *class is no longer used for viewport handling as of version 5.60.* \
---@see UIElement3D.drawViewport
---@deprecated
function UIElement.drawViewport() end

---Legacy internal function that was used to draw a viewport UIElement. \
---***UIElement*** *class is no longer used for viewport handling as of version 5.60.* \
---@see UIElement3D.drawViewport
---@deprecated
function UIElement:displayViewport() end

---Returns UIElement's target image color according to its current state
---@return Color
function UIElement:getImageColor()
	local targetColor = self.imageColor
	if (self.interactive) then
		if (self.isactive) then
			if (self.hoverState ~= BTN_NONE) then
				targetColor = (self.hoverState == BTN_DN and self.imagePressedColor or self.imageAnimateColor) or targetColor
			end
		else
			targetColor = self.imageInactiveColor or targetColor
		end
	end
	return targetColor
end

---Internal function that's used to draw a regular UIElement. \
---*You likely don't need to call this manually.* \
---@see UIElement.drawVisuals
---@see UIElement.addCustomDisplay
function UIElement:display()
	if (self.customDisplayBefore) then
		self.customDisplayBefore()
	end
	if (self.hoverState ~= nil and self.hoverState ~= BTN_NONE) then
		local animateRatio = (UIElement.clock - (self.hoverClock or 0)) / UIElement.animationDuration
		if (self.hoverColor) then
			if (UIElement.lightUIMode) then
				for i = 1, 4 do
					self.animateColor[i] = self.hoverColor[i]
				end
			else
				for i = 1, 4 do
					if (self.animateColor[i] ~= self.hoverColor[i]) then
						self.animateColor[i] = UITween.SineTween(self.bgColor[i], self.hoverColor[i], animateRatio)
					end
				end
			end
		end
		if (self.imageHoverColor) then
			if (UIElement.lightUIMode) then
				for i = 1, 4 do
					self.imageAnimateColor[i] = self.imageHoverColor[i]
				end
			else
				for i = 1, 4 do
					if (self.imageAnimateColor[i] ~= self.imageHoverColor[i]) then
						self.imageAnimateColor[i] = UITween.SineTween(self.imageColor[i], self.imageHoverColor[i], animateRatio)
					end
				end
			end
		end
	else
		if (self.animateColor) then
			for i = 1, 4 do
				self.animateColor[i] = self.bgColor[i]
			end
		end
		if (self.imageAnimateColor) then
			for i = 1, 4 do
				self.imageAnimateColor[i] = self.imageColor[i]
			end
		end
	end

	if (self.interactive and (self.hoverState == BTN_HVR or self.hoverState == BTN_DN) and (self.hoverColor or self.imageHoverColor)) then
		set_mouse_cursor(1)
	end

	if (not self.customDisplayOnly and (self.bgColor[4] > 0 or self.bgImage or self.interactive)) then
		if (self.innerShadow[1] > 0 or self.innerShadow[2] > 0) then
			setColor(self.shadowColor[1][1], self.shadowColor[1][2], self.shadowColor[1][3], self.shadowColor[1][4])
			if (self.shapeType == ROUNDED) then
				drawDisk(self.pos.x + self.roundedInternal[1], self.pos.y + self.roundedInternal[1], 0, self.roundedInternal[1], self.diskSlices, 1, -180, 90, 0)
				drawDisk(self.pos.x + self.size.w - self.roundedInternal[1], self.pos.y + self.roundedInternal[1], 0, self.roundedInternal[1], self.diskSlices, 1, 90, 90, 0)
				if (is_mobile) then
					drawQuad(self.pos.x + self.roundedInternal[1] - 0.2, self.pos.y, self.size.w - self.roundedInternal[1] * 2 + 0.4, self.roundedInternal[1])
					drawQuad(self.pos.x, self.pos.y + self.roundedInternal[1] - 0.2, self.size.w, self.size.h / 2 - self.roundedInternal[1] + 0.2)
				else
					drawQuad(self.pos.x + self.roundedInternal[1], self.pos.y, self.size.w - self.roundedInternal[1] * 2, self.roundedInternal[1])
					drawQuad(self.pos.x, self.pos.y + self.roundedInternal[1], self.size.w, self.size.h / 2 - self.roundedInternal[1])
				end
				setColor(self.shadowColor[2][1], self.shadowColor[2][2], self.shadowColor[2][3], self.shadowColor[2][4])
				drawDisk(self.pos.x + self.roundedInternal[2], self.pos.y + self.size.h - self.roundedInternal[2], 0, self.roundedInternal[2], self.diskSlices, 1, -90, 90, 0)
				drawDisk(self.pos.x + self.size.w - self.roundedInternal[2], self.pos.y + self.size.h - self.roundedInternal[2], 0, self.roundedInternal[2], self.diskSlices, 1, 0, 90, 0)
				if (is_mobile) then
					drawQuad(self.pos.x + self.roundedInternal[2] - 0.2, self.pos.y + self.size.h - self.roundedInternal[2], self.size.w - self.roundedInternal[2] * 2 + 0.4, self.roundedInternal[2])
					drawQuad(self.pos.x, self.pos.y + self.size.h / 2, self.size.w, self.size.h / 2 - self.roundedInternal[2] + 0.2)
				else
					drawQuad(self.pos.x + self.roundedInternal[2], self.pos.y + self.size.h - self.roundedInternal[2], self.size.w - self.roundedInternal[2] * 2, self.roundedInternal[2])
					drawQuad(self.pos.x, self.pos.y + self.size.h / 2, self.size.w, self.size.h / 2 - self.roundedInternal[2])
				end
			else
				drawQuad(self.pos.x, self.pos.y, self.size.w, self.size.h / 2)
				setColor(self.shadowColor[2][1], self.shadowColor[2][2], self.shadowColor[2][3], self.shadowColor[2][4])
				drawQuad(self.pos.x, self.pos.y + self.size.h / 2, self.size.w, self.size.h / 2)
			end
		end
		if (not self.interactive) then
			setColor(self.bgColor[1], self.bgColor[2], self.bgColor[3], self.bgColor[4])
		elseif (self.isactive and self.hoverState ~= BTN_DN) then
			setColor(self.animateColor[1], self.animateColor[2], self.animateColor[3], self.animateColor[4])
		elseif (not self.isactive and self.inactiveColor) then
			setColor(self.inactiveColor[1], self.inactiveColor[2], self.inactiveColor[3], self.inactiveColor[4])
		elseif (self.hoverState == BTN_DN and self.pressedColor) then
			setColor(self.pressedColor[1], self.pressedColor[2], self.pressedColor[3], self.pressedColor[4])
		else
			setColor(self.bgColor[1], self.bgColor[2], self.bgColor[3], self.bgColor[4])
		end
		if (self.shapeType == ROUNDED) then
			drawDisk(self.pos.x + self.roundedInternal[1], self.pos.y + self.roundedInternal[1] + self.innerShadow[1], 0, self.roundedInternal[1], self.diskSlices, 1, -180, 90, 0)
			drawDisk(self.pos.x + self.roundedInternal[2], self.pos.y + self.size.h - self.roundedInternal[2] - self.innerShadow[2], 0, self.roundedInternal[2], self.diskSlices, 1, -90, 90, 0)
			drawDisk(self.pos.x + self.size.w - self.roundedInternal[1], self.pos.y + self.roundedInternal[1] + self.innerShadow[1], 0, self.roundedInternal[1], self.diskSlices, 1, 90, 90, 0)
			drawDisk(self.pos.x + self.size.w - self.roundedInternal[2], self.pos.y + self.size.h - self.roundedInternal[2] - self.innerShadow[2], 0, self.roundedInternal[2], self.diskSlices, 1, 0, 90, 0)
			if (is_mobile) then
				drawQuad(self.pos.x + self.roundedInternal[1] - 0.2, self.pos.y + self.innerShadow[1], self.size.w - self.roundedInternal[1] * 2 + 0.4, self.roundedInternal[1])
				drawQuad(self.pos.x, self.pos.y + self.roundedInternal[1] + self.innerShadow[1] - 0.2, self.size.w, self.size.h - self.roundedInternal[2] - self.roundedInternal[1] - self.innerShadow[2] - self.innerShadow[1] + 0.4)
				drawQuad(self.pos.x + self.roundedInternal[2] - 0.2, self.pos.y + self.size.h - self.roundedInternal[2] - self.innerShadow[2], self.size.w - self.roundedInternal[2] * 2 + 0.4, self.roundedInternal[2] + 0.2)
			else
				drawQuad(self.pos.x + self.roundedInternal[1], self.pos.y + self.innerShadow[1], self.size.w - self.roundedInternal[1] * 2, self.roundedInternal[1])
				drawQuad(self.pos.x, self.pos.y + self.roundedInternal[1] + self.innerShadow[1], self.size.w, self.size.h - self.roundedInternal[2] - self.roundedInternal[1] - self.innerShadow[2] - self.innerShadow[1])
				drawQuad(self.pos.x + self.roundedInternal[2], self.pos.y + self.size.h - self.roundedInternal[2] - self.innerShadow[2], self.size.w - self.roundedInternal[2] * 2, self.roundedInternal[2])
			end
		else
			drawQuad(self.pos.x, self.pos.y + self.innerShadow[1], self.size.w, self.size.h - self.innerShadow[1] - self.innerShadow[2])
		end
		if (self.bgImage) then
			local targetImageColor = self:getImageColor()
			if (targetImageColor[4] > 0) then
				if (self.drawMode == 2) then
					drawQuad(self.pos.x, self.pos.y, self.size.w, self.size.h, self.bgImage, 2, targetImageColor[1], targetImageColor[2], targetImageColor[3], targetImageColor[4], self.atlas.w, self.atlas.h, self.atlas.x, self.atlas.y)
				elseif (self.drawMode == 1) then
					drawQuad(self.pos.x, self.pos.y, self.size.w, self.size.h, self.bgImage, 1, targetImageColor[1], targetImageColor[2], targetImageColor[3], targetImageColor[4], self.atlas.w, self.atlas.h)
				else
					drawQuad(self.pos.x, self.pos.y, self.size.w, self.size.h, self.bgImage, 0, targetImageColor[1], targetImageColor[2], targetImageColor[3], targetImageColor[4])
				end
			end
		end
	end
	if (self.customDisplay) then
		self.customDisplay()
	end
end

---Reloads a UIElement by consecutively calling `hide()` and `show()` methods on it
function UIElement:reload()
	self:hide()
	self:show()
end

---Executes UIElement `show()` or `hide()` method depending on state \
---@see UIElement.show
---@see UIElement.hide
---@param state boolean
---@param override ?boolean
function UIElement:setVisible(state, override)
	if (state == true) then
		self:show(override)
	else
		self:hide(override)
	end
end

---Activates current interactive UIElement and pushes it back in relevant handler queues. \
---*This method is non-recursive: any deactivated interactive children of this UIElement will remain as they are.*
---@param forceReload ?boolean Whether to override `noreloadInteractive` value set by previous `deactivate()` call
function UIElement:activate(forceReload)
	local num = nil
	if (self.isactive) then
		return
	end
	if (self.noreloadInteractive and not forceReload) then
		return
	else
		self.noreloadInteractive = false
	end

	for i,v in pairs(UIMouseHandler) do
		if (self == v) then
			num = i
			break
		end
	end
	if (not num) then
		if (self.interactive) then
			self.hoverState = BTN_NONE
			table.insert(UIMouseHandler, self)
		end
		if (self.keyboard) then
			table.insert(UIKeyboardHandler, self)
		end
		self.isactive = true
	end
end

---Deactivates current interactive UIElement and removes it from handler queues. \
---*This function is non-recursive: any active interactive children of this UIElement will remain as they are.*
---@param noreload ?boolean Whether this UIElement should ignore subsequent `activate()` calls that don't have override on
function UIElement:deactivate(noreload)
	self.hoverState = BTN_NONE
	self.isactive = false

	if (noreload) then
		self.noreloadInteractive = true
	end
	if (self.menuKeyboardId and not self.textfieldkeepfocusonhide) then
		self:disableMenuKeyboard()
	end
	if (self.interactive) then
		for i,v in pairs(UIMouseHandler) do
			if (self == v) then
				table.remove(UIMouseHandler, i)
				break
			end
		end
	end
	if (self.keyboard) then
		for i,v in pairs(UIKeyboardHandler) do
			if (self == v) then
				table.remove(UIKeyboardHandler, i)
				break
			end
		end
	end
end

---Executes UIElement `activate()` or `deactivate()` method depending on state \
---@see UIElement.activate
---@see UIElement.deactivate
---@param state boolean
---@param override ?boolean
function UIElement:setActive(state, override)
	if (state == true) then
		self:activate(override)
	else
		self:deactivate(override)
	end
end

---Returns whether UIElement is being displayed
---@return boolean
function UIElement:isDisplayed()
	return self.displayed
end

---Returns whether an interactive UIElement is currently active
---@return boolean
function UIElement:isActive()
	return self.isactive
end

function UIElement:shouldReceiveInput()
	if (TB_MENU_MAIN_ISOPEN == 1) then
		return self.globalid == TB_MENU_MAIN_GLOBALID
	else
		return self.globalid ~= TB_MENU_MAIN_GLOBALID
	end
end

---Enables current UIElement and all its children for display
---@param forceReload ?boolean Whether to override `noreload` value set by previous `hide()` calls
---@return boolean
function UIElement:show(forceReload)
	local num = nil
	local viewport = (self.viewport or (self.parent and self.parent.viewport)) and true or false

	if (self.noreload and not forceReload) then
		return self.displayed
	elseif (forceReload) then
		self.noreload = nil
	end

	for i,v in pairs(UIVisualManager[self.globalid]) do
		if (self == v) then
			num = i
			break
		end
	end

	if (not num) then
		if (not viewport) then
			table.insert(UIVisualManager[self.globalid], self)
		end
		if (self.interactive or self.keyboard) then
			self:activate()
		end
	end

	for _, v in pairs(self.child) do
		v:show()
	end
	if (self.onShow) then
		pcall(self.onShow)
	end

	self.displayed = true
	return self.displayed
end

---Disables display of current UIElement and all its children
---@param noreload ?boolean Whether this UIElement should ignore subsequent `show()` calls that don't have override on
function UIElement:hide(noreload)
	for _, v in pairs(self.child) do
		v:hide()
	end

	if (noreload) then
		self.noreload = true
	end
	if (self.destroyed == true or self.displayed == false) then
		return
	end

	if (self.interactive or self.keyboard) then
		self:deactivate()
	end

	for i,v in pairs(UIVisualManager[self.globalid]) do
		if (self == v) then
			table.remove(UIVisualManager[self.globalid], i)
			break
		end
	end
	self.displayed = false
end

---Key up event handler for text field elements. \
---*You likely don't need to call this function manually.*
---@param key integer
---@see UIElement.keyboardHooks
function UIElement:textfieldKeyUp(key)
	if (self.textfield and (key == 13 or key == 271) and self.enteraction) then
		self.enteraction(self.textfieldstr[1])
		return
	end
	if (key == 9) then
		local ctrl_pressed = get_keyboard_ctrl() > 0 and true or false
		local target = ctrl_pressed and self.prevInput or self.nextInput
		if (target) then
			if (self.tabaction) then
				self.tabaction(target, ctrl_pressed)
			end
			if (ctrl_pressed) then
				if (self.tabswitchprevaction) then
					self.tabswitchprevaction()
				end
			else
				if (self.tabswitchaction) then
					self.tabswitchaction()
				end
			end
		end
	end
end

---Updates text field with retrieved input \
---*You likely don't need to call this function manually.*
---@param input string
---@param consumeSymbols ?integer How many symbols before the cursor have to be consumed
---@param consumeSymbolsAfter ?integer How many symbols after the cursor have to be consumed
function UIElement:textfieldUpdate(input, consumeSymbols, consumeSymbolsAfter)
	local strLen = utf8.safe_len(input)
	consumeSymbols = consumeSymbols or 0
	consumeSymbolsAfter = consumeSymbolsAfter or 0

	if (self.textfieldmaxlength > 0) then
		local lenDiff = utf8.safe_len(self.textfieldstr[1]) + strLen - consumeSymbols - consumeSymbolsAfter - self.textfieldmaxlength
		if (lenDiff > 0) then
			input = utf8.safe_sub(input, 0, -lenDiff - 1)
			strLen = strLen - lenDiff
			if (strLen == 0) then
				return
			end
		end
	end
	
	local part1 = utf8.safe_sub(self.textfieldstr[1], 0, self.textfieldindex - consumeSymbols)
	local part2 = utf8.safe_sub(self.textfieldstr[1], self.textfieldindex + 1 + consumeSymbolsAfter)
	self.textfieldstr[1] = part1 .. input .. part2
	self.textfieldindex = self.textfieldindex - consumeSymbols + strLen

	-- Double check we didn't get any newlines if content was pasted
	if (self.textfieldsingleline) then
		local replacements = 0
		self.textfieldstr[1], replacements = string.gsub(self.textfieldstr[1], "\\n", "")
		self.textfieldindex = self.textfieldindex - 2 * replacements
		self.textfieldstr[1], replacements = string.gsub(self.textfieldstr[1], "\n", "")
		self.textfieldindex = self.textfieldindex - replacements
	end
end

---Text field input handler function \
---*You likely don't need to call this function manually.*
---@param input string
---@param isNumeric boolean
---@param allowNegative boolean
---@param allowDecimal boolean
---@param customRegexCheck ?string
---@see UIElement.keyboardHooks
function UIElement:textfieldInput(input, isNumeric, allowNegative, allowDecimal, customRegexCheck)
	local replaceSymbols = 0
	local replaceSymbolsAfter = 0
	local negativeSign = false

	if (customRegexCheck) then
		input = utf8.match(input, customRegexCheck)
	end
	if (input == nil) then
		return
	end

	local strLen = utf8.safe_len(input)
	local clipboardPaste = strLen > 1 and get_clipboard_text() == input

	if (isNumeric) then
		if (allowNegative and input:find("^-")) then
			negativeSign = true
		end
		local regexMatch = "[^0-9" .. (allowDecimal and "%.," or "") .. "]"
		input = utf8.gsub(input, regexMatch, "")
		if (allowDecimal) then
			input = utf8.gsub(input, ",", ".")
		end
	end
	if (strLen == 0 and not negativeSign) then
		return
	elseif (strLen > 1 and not clipboardPaste and input:sub(1, 1) ~= ' ') then
		-- We are likely dealing with keyboard autocompletion
		-- Let's try to guess which part of the text we need to replace
		local text = utf8.sub(self.textfieldstr[1], 0, self.textfieldindex)
		local lastWordStart, lastWordReplacements = utf8.gsub(text, "^.*[^%'%w]([%w%']+)$", "%1")
		if (lastWordReplacements == 0) then
			lastWordStart, lastWordReplacements = utf8.gsub(text, "^([%w%']+)$", "%1")
		end
		if (lastWordReplacements ~= 0) then
			local textFromLastWord = utf8.sub(self.textfieldstr[1], self.textfieldindex - utf8.safe_len(lastWordStart) + 1)
			local lastWord, replacements = utf8.gsub(textFromLastWord, "^([%'%w]+ ?).*", "%1")
			if (lastWord ~= nil and replacements ~= 0) then
				replaceSymbols = utf8.safe_len(lastWordStart)
				replaceSymbolsAfter = utf8.safe_len(lastWord) - replaceSymbols
			end
		end
	end
	if (negativeSign and self.textfieldindex - replaceSymbols == 0) then
		input = "-" .. input
	end

	if (utf8.safe_len(input) == 0) then
		return
	end
	self:textfieldUpdate(input, replaceSymbols, replaceSymbolsAfter)
end

---Key down event handler for text field elements. \
---*You likely don't need to call this function manually.*
---@param key integer
---@return boolean
---@see UIElement.keyboardHooks
function UIElement:textfieldKeyDown(key)
	if (key == 8) then -- SDLK_BACKSPACE
		if (self.textfieldindex > 0) then
			self.textfieldstr[1] = utf8.safe_sub(self.textfieldstr[1], 0, self.textfieldindex - 1) .. utf8.safe_sub(self.textfieldstr[1], self.textfieldindex + 1)
			self.textfieldindex = self.textfieldindex - 1
			return true
		end
	elseif (key == 127 or key == 266) then -- SDLK_DELETE
		self.textfieldstr[1] = utf8.safe_sub(self.textfieldstr[1], 0, self.textfieldindex) .. utf8.safe_sub(self.textfieldstr[1], self.textfieldindex + 2)
		return true
	elseif (key == 273 or key == 274) then -- arrows up / down
		--- First let's determine which line we're currently on
		--- We also want to get clean version of strindices that doesn't account for cursor
		local lineIdx = #self.dispstr
		local indicesFixed = {}
		for i, v in ipairs(self.strindices) do
			indicesFixed[i] = v <= self.textfieldindex and v or v - self.textfieldcursorlen
		end
		for i, _ in ipairs(self.dispstr) do
			if (indicesFixed[i] <= self.textfieldindex and indicesFixed[i + 1] > self.textfieldindex) then
				lineIdx = i
				break
			end
		end

		--- Handle unique cases
		if (key == 273 and lineIdx == 1) then -- arrow up and first line
			self.textfieldindex = 0
			return false
		elseif (key == 274 and lineIdx == #self.dispstr) then -- arrow down and last line
			self.textfieldindex = indicesFixed[lineIdx + 1]
			return false
		end

		--- Handle regular cases
		--- This will currently only work correctly on text fields that use LEFT orientations
		--- Arguably we don't really need other cases because multiline text fields with CENTER orientations
		--- are weird and Toribash doesn't have any real audience in countries that use RTL languages
		local newLineIdx = key == 273 and lineIdx - 1 or lineIdx + 1
		local newLineTextIdx = 0
		if (self.textfieldindex ~= indicesFixed[lineIdx] and indicesFixed[newLineIdx + 1] - indicesFixed[newLineIdx] > 1) then
			local textLen = get_string_length(utf8.safe_sub(self.dispstr[lineIdx], 0, self.textfieldindex - self.strindices[lineIdx]), 4)
			local len = utf8.safe_len(utf8.gsub(self.dispstr[newLineIdx], "\n$", ""))
			for i = 1, len do
				if (get_string_length(utf8.safe_sub(self.dispstr[newLineIdx], 0, i), 4) - get_string_length(utf8.safe_sub(self.dispstr[newLineIdx], i, i), 4) * 0.5 > textLen) then
					break
				end
				newLineTextIdx = i
			end
		end
		self.textfieldindex = indicesFixed[newLineIdx] + newLineTextIdx
	elseif (key == 275) then -- arrow right
		self.textfieldindex = self.textfieldindex < utf8.len(self.textfieldstr[1]) and self.textfieldindex + 1 or self.textfieldindex
	elseif (key == 276) then -- arrow left
		self.textfieldindex = self.textfieldindex > 0 and self.textfieldindex - 1 or 0
	elseif (key == 278 or key == 279) then -- home / end
		local lineIdx = #self.dispstr
		local indicesFixed = {}
		for i, v in ipairs(self.strindices) do
			indicesFixed[i] = v <= self.textfieldindex and v or v - self.textfieldcursorlen
		end
		for i, _ in ipairs(self.dispstr) do
			if (indicesFixed[i] <= self.textfieldindex and indicesFixed[i + 1] > self.textfieldindex) then
				lineIdx = i
				break
			end
		end
		if (key == 278) then
			self.textfieldindex = indicesFixed[lineIdx]
		else
			self.textfieldindex = indicesFixed[lineIdx + 1] - (lineIdx == #self.dispstr and 0 or 1)
		end
	elseif (key == 280) then -- pgup
		self.textfieldindex = 0
	elseif (key == 281) then
		self.textfieldindex = utf8.safe_len(self.textfieldstr[1])
	elseif (key == 13 or key == 271 and not self.textfieldsingleline) then -- newline
		self:textfieldUpdate("\n")
		return true
	elseif (key == 118 and (_G.PLATFORM == "APPLE" and get_keyboard_gui() or get_keyboard_ctrl()) > 0) then -- CTRL + V
		local clipboard = get_clipboard_text()
		if (clipboard ~= nil) then
			self:textfieldUpdate(clipboard)
			return true
		end
	end
	return false
end

---Internal UIElement loop to handle key up callback. \
---*You likely don't need to call this function manually.*
---@param key integer
---@return integer
---@see UIElement.keyboardHooks
function UIElement.handleKeyUp(key)
	for _, v in pairs(table.reverse(UIKeyboardHandler)) do
		if (v.keyboard == true) then
			v.keyUp(key)
			if (v.keyUpCustom) then
				v.keyUpCustom(key)
			end
			if (not v.permanentListener) then
				return 1
			end
		end
	end
	return 0
end

---Internal UIElement loop to handle key down callback. \
---*You likely don't need to call this function manually.*
---@param key integer
---@return integer
---@see UIElement.keyboardHooks
function UIElement.handleKeyDown(key)
	for _, v in pairs(table.reverse(UIKeyboardHandler)) do
		if (v.keyboard == true) then
			v.keyDown(key)
			if (v.keyDownCustom) then
				v.keyDownCustom(key)
			end
			if (not v.permanentListener) then
				return 1
			end
		end
	end
	return 0
end

---Internal UIElement loop to handle text input callback. \
---*You likely don't need to call this function manually.*
---@param input string
---@return integer
---@see UIElement.keyboardHooks
function UIElement.handleInput(input)
	for _, v in pairs(table.reverse(UIKeyboardHandler)) do
		if (v.keyboard == true and v.textfield) then
			v.textInput(input)
			if (v.textInputCustom) then
				v.textInputCustom()
			end
			if (not v.permanentListener) then
				return 1
			end
		end
	end
	return 0
end

---Generic method to enable keyboard input handlers for current UIElement
function UIElement:enableMenuKeyboard()
	TB_MENU_INPUT_ISACTIVE = true
	if (self.textfield) then
		enable_menu_keyboard(self.pos.x, self.pos.y, self.size.w, self.size.h + 10, self.textfieldstr[1], self.inputType, self.autoCompletion, self.returnKeyType, self.textfieldindex)
	elseif (not is_mobile) then
		enable_menu_keyboard()
	end
	local id = 1
	for _, v in pairs(UIKeyboardHandler) do
		if (v.menuKeyboardId == id) then
			id = id + 1
		else
			self.menuKeyboardId = id
			break
		end
	end
	if (TB_MENU_MAIN_ISOPEN == 0) then
		chat_input_deactivate()
	end
end

---Generic method to disable keyboard input handlers for current UIElement
function UIElement:disableMenuKeyboard()
	self.menuKeyboardId = nil
	for _, v in pairs(UIKeyboardHandler) do
		if (v.menuKeyboardId) then
			return
		end
	end
	TB_MENU_INPUT_ISACTIVE = false
	disable_menu_keyboard()
	if (TB_MENU_MAIN_ISOPEN == 0) then
		chat_input_activate()
	end
end

---Internal UIElement function to activate generic text input handler hooks
function UIElement.keyboardHooks()
	add_hook("key_down", "__uiManager", function(key)
			if (TB_MENU_INPUT_ISACTIVE == true) then
				return UIElement.handleKeyDown(key)
			end
		end)
	add_hook("key_up", "__uiManager", function(key)
			if (TB_MENU_INPUT_ISACTIVE == true) then
				return UIElement.handleKeyUp(key)
			end
		end)
	add_hook("text_input", "__uiManager", function(input)
			if (TB_MENU_INPUT_ISACTIVE == true) then
				return UIElement.handleInput(input)
			end
		end)

	UIElement.__keyboardHooks = true
end

function UIElement.drawHooks()
	add_hook("draw2d", "__uiManager", function()
		local clock = os.clock_real()
		UIElement.deltaClock = clock - UIElement.clock
		UIElement.clock = clock
		UIElement.lightUIMode = get_option("uilight") == 1
	end)
	add_hook("pre_draw", "__uiManager", function()
		-- Make sure this always contains accurate data, even if game is minimized / running with frame skip
		UIElement.WorldState = get_world_state()
	end)
	add_hook("resolution_changed", "__uiManager", function()
		WIN_W, WIN_H = get_window_size()
		SCREEN_RATIO = WIN_W / WIN_H
		local safe_x, safe_y, safe_w, safe_h = get_window_safe_size()
		SAFE_X = math.max(safe_x, WIN_W - safe_w - safe_x)
		SAFE_Y = math.max(safe_y, WIN_H - safe_h - safe_y)
		local maxHdpi = get_maximum_dpi_scale()
		if (get_option("highdpi") > maxHdpi) then
			set_graphics_option(8, maxHdpi)
			reload_graphics()
		end
	end)

	UIElement.__drawHooks = true
end

---UIElement internal function to handle mouse down event for an object. \
---*You likely don't need to call this function manually.*
---@param btn number Mouse button ID
---@param x number
---@param y number
function UIElement.handleMouseDn(btn, x, y)
	enable_camera_movement()
	for _, v in pairs(UIKeyboardHandler) do
		v.keyboard = v.permanentListener
	end
	for _, v in pairs(table.reverse(UIMouseHandler)) do
		if (v:shouldReceiveInput()) then
			if (x > v.pos.x and x < v.pos.x + v.size.w and y > v.pos.y and y < v.pos.y + v.size.h and btn < 4) then
				if (v.downSound) then
					play_sound(v.downSound)
				end
				v.hoverState = BTN_DN
				v.btnDown(btn, x, y)
				if (v.textfield == true) then
					v.keyboard = true
					disable_camera_movement()
				end
				if (not v.clickThrough) then
					return 1
				end
			elseif (btn >= 4 and v.scrollEnabled == true) then
				if (v.btnDown(btn, x, y)) then
					return
				end
			end
		end
	end
end

---UIElement internal function to handle mouse up event for an object. \
---*You likely don't need to call this function manually.*
---@param btn number Mouse button ID
---@param x number
---@param y number
function UIElement.handleMouseUp(btn, x, y)
	local actionTriggered = false
	for _, v in pairs(table.reverse(UIMouseHandler)) do
		if (v:shouldReceiveInput()) then
			if (v.hoverState == BTN_DN and btn == 1) then
				v.hoverState = BTN_NONE
				if (not actionTriggered and x > v.pos.x and x < v.pos.x + v.size.w and y > v.pos.y and y < v.pos.y + v.size.h) then
					if (not is_mobile) then
						v.hoverState = BTN_HVR
					end
					if (v.upSound) then
						play_sound(v.upSound)
					end
					v.btnUp(btn, x, y)
					actionTriggered = not v.clickThrough
					set_mouse_cursor(1)
				else
					v.btnUpOutside(btn, x, y)
				end
			elseif (btn == 3) then
				if (x > v.pos.x and x < v.pos.x + v.size.w and y > v.pos.y and y < v.pos.y + v.size.h) then
					if (v.upSound) then
						play_sound(v.upSound)
					end
					v.btnRightUp(btn, x, y)
					return
				end
			end
		end
	end
end

---UIElement internal function to handle mouse movement event for an object. \
---*You likely don't need to call this function manually.*
---@param x number
---@param y number
function UIElement.handleMouseHover(x, y)
	local disable = nil
	MOUSE_X, MOUSE_Y = x, y

	for _, v in pairs(table.reverse(UIMouseHandler)) do
		if (v:shouldReceiveInput()) then
			if (v.hoverState == BTN_DN) then
				disable = v.hoverThrough ~= true
				v.btnHover(x,y)
			elseif (disable and not v.scrollableListTouchScrollActive) then
				v.hoverState = BTN_NONE
			elseif (x > v.pos.x and x < v.pos.x + v.size.w and y > v.pos.y and y < v.pos.y + v.size.h) then
				if (v.hoverState == BTN_NONE and v.hoverSound) then
					play_sound(v.hoverSound)
				end
				if (v.hoverState ~= BTN_DN) then
					if (v.hoverState == BTN_NONE) then
						v.hoverClock = os.clock_real()
					end
					v.hoverState = BTN_HVR
					disable = v.hoverThrough ~= true
				end
				v.btnHover(x,y)
				set_mouse_cursor(1)
			elseif (v.scrollableListTouchScrollActive and v.hoverState == BTN_DN) then
				v.btnHover(x, y)
			else
				v.hoverState = BTN_NONE
			end
		end
	end
end

---Internal UIElement function to activate generic mouse handler hooks
function UIElement.mouseHooks()
	add_hook("mouse_button_down", "__uiManager", function(s, x, y)
			local toReturn = TB_MENU_MAIN_ISOPEN == 1 and 1 or 0
			toReturn = UIElement.handleMouseDn(s, x, y) or toReturn
			return toReturn
		end)
	add_hook("mouse_button_up", "__uiManager", function(s, x, y)
			UIElement.handleMouseUp(s, x, y)
		end)
	add_hook("mouse_move", "__uiManager", function(x, y)
			UIElement.handleMouseHover(x, y)
		end)

	UIElement.__mouseHooks = true
end

---Moves current UIElement to specified coordinates
---@param x number|nil
---@param y number|nil
---@param relative ?boolean Shift the object relatively to its current position if `true`, set new anchor point otherwise
function UIElement:moveTo(x, y, relative)
	if (self.parent) then
		if (x) then self.shift.x = relative and ((self.shift.x + x < 0 and self.shift.x >= 0) and (self.shift.x + x - self.parent.size.w) or (self.shift.x + x)) or x end
		if (y) then self.shift.y = relative and ((self.shift.y + y < 0 and self.shift.y >= 0) and (self.shift.y + y - self.parent.size.h) or (self.shift.y + y)) or y end
	else
		if (x) then self.pos.x = relative and self.pos.x + x or x end
		if (y) then self.pos.y = relative and self.pos.y + y or y end
	end
	self:invalidatePosition()
end

---Marks position as dirty for current UIElement and all its children
function UIElement:invalidatePosition()
	if (self.parent ~= nil) then
		self.__positionDirty = true
	end
	for _, v in pairs(self.child) do
		v:invalidatePosition()
	end
end

---Internal function to update position of current UIElement based on its parent movement
function UIElement:updateChildPos()
	if (self.parent.viewport or not self.__positionDirty) then
		return
	end
	if (self.shift.x < 0) then
		self.pos.x = self.parent.pos.x + self.parent.size.w + self.shift.x
	else
		self.pos.x = self.parent.pos.x + self.shift.x
	end
	if (self.shift.y < 0) then
		self.pos.y = self.parent.pos.y + self.parent.size.h + self.shift.y
	else
		self.pos.y = self.parent.pos.y + self.shift.y
	end
	self.__positionDirty = false
end

---@class UITextSettings
---@field padding Vector2Base|Rect
---@field font FontId
---@field align UIElementTextAlign
---@field minscale number
---@field maxscale number
---@field intensity number
---@field shadow number
---@field color Color
---@field shadowColor Color
---@field isTextfield boolean
---@field baselineScale number
---@field shadowIntensity number

---Adapts the specified string to fit inside UIElement object and sets custom display function to draw it
---@param override boolean Whether to disable the default `display()` functionality
---@param str string Text to display in an object
---@param x? number X offset for the displayed text
---@param y? number Y offset for the displayed text
---@param font? FontId
---@param align? UIElementTextAlign
---@param maxscale? number
---@param minscale? number Any text that still doesn't fit inside the object at this scale value will be cut
---@param intensity? number Text color intensity, only used for `FONTS.BIG` and `FONTS.BIGGER`. Use values from `0` to `1`.
---@param shadow? number Text shadow grow value. It is recommended to keep this value relatively low (<10) for best looks.
---@param col1? Color Main text color. Uses UIElement.uiColor by default.
---@param col2? Color Text shadow color. Uses UIElement.uiShadowColor by default.
---@param textfield? boolean Whether this text is supposed to be a part of text box input
---@param baselineScale? number Line height scale
---@overload fun(self, str: string, x?: number, y?: number, font?: FontId, align?: UIElementTextAlign, maxscale?: number, minscale?: number, intensity?: number, shadow?: number, col1?: Color, col2?: Color, textfield?: boolean)
---@overload fun(self, str: string, textSettings: UITextSettings, override: boolean?)
function UIElement:addAdaptedText(override, str, x, y, font, align, maxscale, minscale, intensity, shadow, col1, col2, textfield, baselineScale)
	local shadowIntensity = 0
	if (type(override) == "string") then
		if (type(str) == "table") then
			local isOverride = x
			---@type UITextSettings
			---@diagnostic disable-next-line: cast-local-type
			str = str
			shadowIntensity = str.shadowIntensity
			baselineScale = str.baselineScale
			textfield = str.isTextfield
			col2 = str.shadowColor
			col1 = str.color
			shadow = str.shadow
			intensity = str.intensity
			minscale = str.minscale
			maxscale = str.maxscale
			align = str.align
			font = str.font
			---@diagnostic disable-next-line: cast-local-type
			y = str.padding and (str.padding.h and { str.padding.y, str.padding.h } or str.padding.y) or 0
			---@diagnostic disable-next-line: cast-local-type
			x = str.padding and (str.padding.w and { str.padding.x, str.padding.w } or str.padding.x) or 0
			str = override
			---@type boolean
			---@diagnostic disable-next-line: assign-type-mismatch
			override = isOverride
		else
			---@type boolean
			---@diagnostic disable-next-line: assign-type-mismatch
			textfield = col2
			col2 = col1
			---@type Color
			---@diagnostic disable-next-line: assign-type-mismatch
			col1 = shadow
			shadow = intensity
			intensity = minscale
			minscale = maxscale
			maxscale = align
			---@type UIElementTextAlign
			---@diagnostic disable-next-line: assign-type-mismatch
			align = font
			---@type FontId
			---@diagnostic disable-next-line: assign-type-mismatch
			font = y
			y = x
			---@type number
			---@diagnostic disable-next-line: assign-type-mismatch
			x = str
			str = override
			override = false
		end
	end
	if (type(str) ~= "string" and type(str) ~= "number") then
		Files.LogError("UIElement.addAdaptedText error: string type mismatch (" .. type(str) .. ")")
		return false
	end
	local scale = maxscale or 1
	minscale = minscale or 0.2
	font = font or FONTS.MEDIUM

	while (not self:uiText(str, x, y, font, nil, scale, nil, nil, nil, nil, nil, true, baselineScale, nil, textfield) and scale > minscale) do
		scale = scale - 0.05
	end

	self.textScale = scale
	self.textFont = font
	if (shadow) then
		self.shadowFontid = generate_font(self.textFont, 1, shadow)
	end
	self:addCustomDisplay(override, function()
			self:uiText(str, x, y, font, align, scale, nil, shadow, col1, col2, intensity, nil, baselineScale, nil, textfield, shadowIntensity)
		end)
end

---Helper function to draw text with some additional functionality. \
---*You are likely looking for `UIElement:addAdaptedText()` or `UIElement:uiText()`.*
---@param str string
---@param xPos number
---@param yPos number
---@param angle number
---@param scale number
---@param font FontId
---@param shadow ?number Outline thickness in pixels
---@param color ?Color
---@param shadowColor ?Color
---@param intensity ?number
---@param pixelPerfect ?boolean Whether to floor the text position to make sure we don't start mid-pixel
---@param shadowFontId ?integer Font id for text shadow retrieved from `generate_font()`
---@param shadowOffset ?number Shadow offset override
---@param shadowIntensity ?number
local drawTextNew = function(str, xPos, yPos, angle, scale, font, shadow, color, shadowColor, intensity, pixelPerfect, shadowFontId, shadowOffset, shadowIntensity)
	local col1 = color or DEFTEXTCOLOR
	local col2 = shadowColor or DEFSHADOWCOLOR
	shadow = shadow or nil
	xPos = pixelPerfect and math.floor(xPos) or xPos
	yPos = pixelPerfect and math.floor(yPos) or yPos
	intensity = intensity or col1[4]
	if (shadow and col2[4] > 0) then
		local offset = shadowOffset or shadow / 2
		shadowFontId = shadowFontId or generate_font(font, 1, shadow)
		shadowIntensity = shadowIntensity or 0
		setColor(col2[1], col2[2], col2[3], col2[4])
		drawText(str, xPos - offset, yPos - offset, angle, scale, shadowFontId)
		if ((font == 0 or font == 9) and shadowIntensity > 0) then
			setColor(col2[1], col2[2], col2[3], shadowIntensity)
			drawText(str, xPos - offset, yPos - offset, angle, scale, shadowFontId)
			if (font == 0 or font == 9) then
				drawText(str, xPos - offset, yPos - offset, angle, scale, shadowFontId)
			end
		end
	end

	if (col1[4] <= 0) then return end
	setColor(col1[1], col1[2], col1[3], col1[4])
	drawText(str, xPos, yPos, angle, scale, font)
	if (font == 0 or font == 9) then
		setColor(col1[1], col1[2], col1[3], intensity)
		drawText(str, xPos, yPos, angle, scale, font)
		if (font == 0 or font == 9) then
			drawText(str, xPos, yPos, angle, scale, font)
		end
	end
end

---Generic function to display text within current UIElement using specified settings
---@param input string Text to display in an object
---@param x? number|number[] X offset for the displayed text
---@param y? number|number[] Y offset for the displayed text
---@param font ?FontId
---@param align ?UIElementTextAlign
---@param scale ?number
---@param angle ?number Text rotation in degrees
---@param shadow ?number Text outline thickness in pixels
---@param col1 ?Color Primary text color, uses `uiColor` value by default
---@param col2 ?Color Text shadow color, uses `uiShadowColor` value by default
---@param intensity ?number Text color intensity, only used for `FONTS.BIG` and `FONTS.BIGGER`. Use values from `0` to `1`.
---@param check ?boolean Whether this call is only to be used for checking whether text fits the object with current settings
---@param baselineScale ?number Baseline scale value
---@param nosmooth ?boolean Whether to disable pixel perfect text drawing
---@param textfield ?boolean Whether this function is being used as part of text field display routine
---@param shadowIntensity ?number Text shadow color intensity. Works similarly to `intensity`.
---@return boolean
function UIElement:uiText(input, x, y, font, align, scale, angle, shadow, col1, col2, intensity, check, baselineScale, nosmooth, textfield, shadowIntensity)
	if (not scale and check) then
		Files.LogError("UIElement.uiText() error: cannot take undefined scale argument with check enabled")
		return true
	end
	font = font or FONTS.MEDIUM
	local x2, y2 = 0, 0
	if (x ~= nil) then
		if (type(x) == "table") then
			x2 = tonumber(x[2]) or 0
			x = tonumber(x[1]) or 0
		else
			x = tonumber(x) or 0
		end
	else
		x = 0
	end
	if (y ~= nil) then
		if (type(y) == "table") then
			y2 = tonumber(y[2]) or 0
			y = tonumber(y[1]) or 0
		else
			y = tonumber(y) or 0
		end
	else
		y = 0
	end
	local font_mod = getFontMod(font)
	scale = scale or 1
	angle = angle or 0
	local pos = 0
	align = align or CENTERMID
	col1 = col1 or self.uiColor
	col2 = col2 or self.uiShadowColor
	check = check or false
	local smoothing = not nosmooth
	baselineScale = baselineScale or 1

	local str, indices
	if (check) then
		str, indices = textAdapt(input, font, scale, self.size.w - x - x2, true, textfield, self.textfieldsingleline, self.textfieldindex, self.textfieldcursorlen)
	else
		if (self.str == input) then
			str = self.dispstr
			indices = self.strindices
		else
			str, indices = textAdapt(input, font, scale, self.size.w - x - x2, nil, textfield, self.textfieldsingleline, self.textfieldindex, self.textfieldcursorlen)
		end
		self.str, self.dispstr, self.strindices = input, str, indices
	end

	local fontModScale = font_mod * 10 * scale * baselineScale
	self.startLine = 1
	if (textfield and fontModScale * #str > self.size.h - y2) then
		for i, _ in pairs(str) do
			if (self.textfieldindex < indices[i + 1]) then
				local newLine = i - math.floor(self.size.h / font_mod / 10 / scale / baselineScale) + 1
				if (newLine + 1 < self.startLine) then
					self.startLine = math.max(newLine, self.startLine - 1, 1)
				elseif (newLine > self.startLine) then
					self.startLine = newLine
				end
				break
			end
		end
	end

	for i = self.startLine, #str do
		local xPos = x + self.pos.x
		local yPos = y + self.pos.y
		local strlen = get_string_length(str[i], font) * scale
		if ((align + 2) % 3 == 0) then
			xPos = xPos + (self.size.w - x - x2 - strlen) / 2
		elseif ((align + 1) % 3 == 0) then
			xPos = self.pos.x + self.size.w - x2 - strlen
		end
		if (align >= 3 and align <= 5) then
			yPos = self.pos.y + self.size.h - y2 - #str * fontModScale
			while (yPos < y + self.pos.y and yPos + fontModScale < self.pos.y + self.size.h - y2) do
				yPos = yPos + font_mod * 10 * scale
			end
		elseif (align >= 6 and align <= 8) then
			yPos = yPos + (self.size.h - y - y2 - #str * fontModScale) / 2
			while (yPos < self.pos.y + y and yPos + fontModScale < self.pos.y + self.size.h - y2) do
				yPos = yPos + font_mod * 5 * scale
			end
		end
		if (check == true and (self.size.w - x - x2 < strlen or self.size.h - y - y2 < font_mod * 10 * scale)) then
			return false
		elseif (self.size.h - y - y2 > (pos + 2) * font_mod * 10 * scale) then
			if (check == false) then
				drawTextNew(str[i], xPos, yPos + (pos * fontModScale), angle, scale, font, shadow, col1, col2, intensity, smoothing, self.shadowFontid, self.shadowOffset, shadowIntensity)
			elseif (#str == i) then
				return true
			end
			pos = pos + 1
		elseif (i ~= #str) then
			if (check == true) then
				return false
			end
			drawTextNew(textfield and str[i] or utf8.gsub(str[i], ".$", "..."), xPos, yPos + (pos * fontModScale), angle, scale, font, shadow, col1, col2, intensity, smoothing, self.shadowFontid, self.shadowOffset, shadowIntensity)
			break
		else
			if (check == false) then
				drawTextNew(str[i], xPos, yPos + (pos * fontModScale), angle, scale, font, shadow, col1, col2, intensity, smoothing, self.shadowFontid, self.shadowOffset, shadowIntensity)
			else
				return true
			end
		end
	end
	return false
end

---Returns current UIElement main color
---@return Color
function UIElement:getButtonColor()
	if (self.hoverState == BTN_DN) then
		return self.pressedColor
	elseif (self.hoverState == BTN_HVR) then
		return self.animateColor
	else
		return self.bgColor
	end
end

---Returns current UIElement position relative to its parent
---@return number[]
function UIElement:getPos()
	return { self.shift.x, self.shift.y }
end

---Returns local position of a point within current UIElement
---@param xPos ?number X position of a point. Defaults to current cursor X position.
---@param yPos ?number Y position of a point. Defaults to current cursor Y position.
---@param pos ?Vector2Base
---@return Vector2Base
function UIElement:getLocalPos(xPos, yPos, pos)
	local xPos = xPos or MOUSE_X
	local yPos = yPos or MOUSE_Y
	---@type Vector2Base
	local pos = pos or { x = xPos, y = yPos}
	if (self.parent) then
		pos = self.parent:getLocalPos(xPos, yPos, pos)
		if (self.shift.x < 0) then
			pos.x = pos.x - self.parent.size.w - self.shift.x
		else
			pos.x = pos.x - self.shift.x
		end
		if (self.shift.y < 0) then
			pos.y = pos.y - self.parent.size.h - self.shift.y
		else
			pos.y = pos.y - self.shift.y
		end
	else
		pos.x = xPos - self.pos.x
		pos.y = yPos - self.pos.y
	end
	return pos
end

---Updates a texture associated with an object and caches it for later use
---@param image string|nil Main texture path
---@param default? string Fallback texture path
---@param noreload? boolean If true, will not check if existing texture should be unloaded
function UIElement:updateImage(image, default, noreload)
	require("system.iofiles")
	local default = default or UIElementDefaultTexture
	local filename
	if (image) then
		if (image:find("%.%./", 4)) then
			filename = image:gsub("%.%./%.%./", "")
		elseif (image:find("%.%./")) then
			filename = image:gsub("%.%./", "data/")
		else
			filename = "data/script/" .. image:gsub("^/", "")
		end
	end

	if (not noreload and self.bgImage and not self.disableUnload) then
		local count, id = 0, 0
		for i,v in pairs(UIElementTextureCache) do
			if (v == self.bgImage) then
				count = count + 1
				id = i
			end
		end
		if (count == 1) then
			unload_texture(self.bgImage)
			UIElementTextureIndex = UIElementTextureIndex - 1
		end
		table.remove(UIElementTextureCache, id)
		self.bgImage = nil
		self.bgImageDefault = nil
	end

	if (not image) then
		return
	end

	if (UIElementTextureIndex > 253) then
		self.bgImage = load_texture(UIElementDefaultTexture)
		return
	end
	if (not self.imageColor) then
		self.imageColor = { 1, 1, 1, 1 }
	end

	local tempicon = Files.Open("../" .. filename)
	if (not tempicon.data) then
		local textureid = load_texture(default)
		self.bgImage = textureid
		self.bgImageDefault = true
		UIElementTextureIndex = math.max(UIElementTextureIndex, textureid)
		table.insert(UIElementTextureCache, self.bgImage)
	else
		local textureid = load_texture(image)
		if (textureid == -1) then
			unload_texture(textureid)
			self.bgImage = load_texture(default)
			self.bgImageDefault = true
		else
			self.bgImage = textureid
			self.bgImageDefault = false
		end
		UIElementTextureIndex = math.max(UIElementTextureIndex, textureid)
		table.insert(UIElementTextureCache, self.bgImage)
		tempicon:close()
	end
end

---Generates an image gradient to use for the object and stores it in image cache
---@param color1 Color
---@param color2 Color
---@param gradientMode ?PlayerBody
function UIElement:updateImageGradient(color1, color2, gradientMode)
	if (color1 == nil or color2 == nil) then return end
	if (self.bgImage ~= nil) then
		self:updateImage(nil)
	end
	if (UIElementTextureIndex > 253) then
		return
	end
	if (not self.imageColor) then
		self.imageColor = { 1, 1, 1, 1 }
	end

	local textureid = generate_texture_gradient(color1[1], color1[2], color1[3], color1[4], color2[1], color2[2], color2[3], color2[4], gradientMode or 0)
	if (textureid >= 0) then
		self.bgImage = textureid
		UIElementTextureIndex = math.max(UIElementTextureIndex, textureid)
		table.insert(UIElementTextureCache, self.bgImage)
	end
end

---@alias CmdEchoMode
---| true CMD_ECHO_ENABLED
---| false CMD_ECHO_DISABLED
---| -1 CMD_ECHO_FORCE_DISABLED
CMD_ECHO_ENABLED = true
CMD_ECHO_DISABLED = false
CMD_ECHO_FORCE_DISABLED = -1

---Wrapper function for `run_cmd()` that automatically appends newline at the end of online commands
---@param command string
---@param online ?boolean
---@param echo ?CmdEchoMode
_G.runCmd = function(command, online, echo)
	local online = online and 1 or 0
	local silent = echo ~= CMD_ECHO_ENABLED

	if (echo == CMD_ECHO_FORCE_DISABLED) then
		add_hook("console", "__uiManager", function() return 1 end)
	end
	run_cmd(command .. (online and "\n" or ""), online, silent)
	remove_hook("console", "__uiManager")
end

---@deprecated
---Will be removed with future releases, use `runCmd()` instead \
---@see runCmd
function UIElement:runCmd(command, online, echo)
	runCmd(command, online, echo)
end

---Runs a quicksort by specified key(s) on a table with multikey data
---@generic T
---@param list T Table with the data that we want to sort
---@param sort string|string[] Key or keys which values will be used for sorting
---@param _order? SortOrder|boolean[] Sorting order, defaults to `SORT_ASCENDING`
---@param includeZeros? boolean
---@return T
_G.table.qsort = function(list, sort, _order, includeZeros)
	local arr = {}
	local order = {}

	if (type(_order) ~= "table") then
		---@diagnostic disable-next-line: cast-local-type
		order = { _order and 1 or -1 }
	else
		for i, v in pairs(_order) do
			order[i] = v and 1 or -1
		end
	end

	for _, v in pairs(list) do
		table.insert(arr, v)
	end
	if (type(sort) ~= "table") then
		sort = { sort }
	end

	sort = table.reverse(sort)
	order = table.reverse(order)
	table.sort(arr, function(a,b)
			local cmpRes = false
			for i, v in pairs(sort) do
				local val1 = a[v] == 0 and (includeZeros and 0 or b[v] - (order[i] and order[i] or order[1])) or a[v]
				local val2 = b[v] == 0 and (includeZeros and 0 or a[v] - (order[i] and order[i] or order[1])) or b[v]
				if (type(val1) == "string" or type(val2) == "string") then
					val1 = in_array(type(val1), { "number", "string" }) and string.lower(val1) or ""
					val2 = in_array(type(val2), { "number", "string" }) and string.lower(val2) or ""
				end
				if (type(val1) == "boolean") then
					val1 = val1 and 1 or -1
				end
				if (type(val2) == "boolean") then
					val2 = val2 and 1 or -1
				end
				if (val1 ~= val2) then
					if ((order[i] and order[i] or order[1]) == 1) then
						return val1 > val2
					else
						return val1 < val2
					end
				end
			end
			return cmpRes
		end)
	return arr
end

---@deprecated
---Use `table.qsort()` instead
---@see table.qsort
_G.qsort = function(arr, sort, desc, includeZeros)
	if (type(arr) ~= "table") then
		return arr
	end
	return _G.table.qsort(arr, sort, desc, includeZeros)
end

---@deprecated
---Use `table.qsort()` instead
---@see table.qsort
function UIElement:qsort(arr, sort, desc, includeZeros)
	return table.qsort(arr, sort, desc, includeZeros)
end

---Helper function to retrieve an approximated font height modifier value
---@param font FontId
---@return number
_G.getFontMod = function(font)
	local hires = font >= 10
	local font_mod = 1
	font = font % 10
	if (font == 0) then
		font_mod = 5.8
	elseif (font == 1) then
		font_mod = 1.5
	elseif (font == 2 or font == 4) then
		font_mod = 2.4
	elseif (font == 3) then
		font_mod = 3.6
	elseif (font == 5 or font == 7) then
		font_mod = 3
	elseif (font == 6 or font == 8) then
		font_mod = 4.8
	elseif (font == 9) then
		font_mod = 9.6
	end
	return font_mod * (hires and 2 or 1)
end

---Helper function to split text into lines to fit the specified width. \
---*You are probably looking for `UIElement:addAdaptedText()` or `UIElement:uiText()`.*
---@param str string
---@param font FontId
---@param scale number
---@param maxWidth number
---@param check ?boolean
---@param textfield ?boolean
---@param singleLine ?boolean
---@param textfieldIndex ?integer
---@param cursorLen ?integer
---@return string[]
---@return integer[]
_G.textAdapt = function(str, font, scale, maxWidth, check, textfield, singleLine, textfieldIndex, cursorLen)
	local clockdebug = TB_MENU_DEBUG and os.clock_real() or nil

	local destStr, destIdx = { }, { 0 }
	local newStr, word = "", ""

	-- Fix newlines, remove redundant spaces and ensure the string is in fact a string
	str = string.gsub(tostring(str), "\\n", "\n")
	if (not textfield) then
		str = string.gsub(str, "^%s*", "")
		str = string.gsub(str, "%s*$", "")
	end

	---@param checkstr string
	---@return string
	local function buildString(checkstr)
		if (textfield) then
			return string.match(checkstr, "^\n") or string.match(checkstr, "^%s*%S+%s?") or checkstr
		end

		local newlined = string.match(checkstr, "^.*\n")
		local checkword = string.match(checkstr, "^%s*%S+%s*") or checkstr
		if (newlined) then
			if (string.len(newlined) < string.len(checkword)) then
				checkword = newlined
			end
		end
		return checkword
	end

	if (textfield and singleLine) then
		cursorLen = cursorLen or 0
		local strlen = get_string_length(str, font) * scale
		local len = utf8.safe_len(str)
		local startOffset, endOffset = 0, 0
		while (strlen > maxWidth and str ~= "") do
			if (textfieldIndex < len - 10 - endOffset - cursorLen) then
				endOffset = endOffset + 1
				str = utf8.safe_sub(str, 0, -2)
			else
				startOffset = startOffset + 1
				str = utf8.safe_sub(str, 2)
			end
			strlen = get_string_length(str, font) * scale
		end
		return { str }, { startOffset, startOffset + utf8.safe_len(str) }
	end

	local newline = false
	local laststr = nil
	while (str ~= "" and laststr ~= str) do
		laststr = str
		word = buildString(str)

		-- Wrap word around if it still exceeds text field width
		if (not check) then
			local _, words = string.gsub(word, "%s", "")
			while (words > 0) do
				local checkword = string.gsub(word, "%s*$", "")
				if (checkword ~= word and get_string_length(checkword, font) * scale > maxWidth) then
					local pos = string.find(word, "%s")
					if (pos == utf8.safe_len(word)) then
						break
					end
					word = utf8.safe_sub(word, 1, pos)
				else
					break
				end
			end
			while (utf8.safe_len(word) > 0) do
				local checkword = string.gsub(word, "%s*$", "")
				if (get_string_length(checkword, font) * scale > maxWidth) then
					word = utf8.safe_sub(word, 1, utf8.safe_len(word) - 1)
				else
					break
				end
			end
		end

		if ((get_string_length(newStr .. word, font) * scale > maxWidth or newline) and newStr ~= "") then
			table.insert(destStr, newStr)
			table.insert(destIdx, destIdx[#destIdx] + utf8.safe_len(newStr))
			newStr = word
		else
			newStr = newStr .. word
		end
		str = utf8.safe_sub(str, utf8.safe_len(word) + 1)
		newline = string.match(word, "\n") or string.match(word, "\\n")
	end
	table.insert(destStr, newStr)
	table.insert(destIdx, destIdx[#destIdx] + utf8.safe_len(newStr))

	if (TB_MENU_DEBUG) then
		local calltime = (os.clock_real() - clockdebug) * 1000
		if (calltime > 10) then
			Files.LogError("UIElement textAdapt warning: slow call on string \"" .. utf8.safe_sub(destStr[1], 1, 20) .. "\" (" .. calltime .. "ms)")
		end
	end

	return destStr, destIdx
end

---Wrapper function for `open_dialog_box()` that properly parses newlines
---@param id integer Dialog box type ID
---@param msg string Information message that will be displayed to the user
---@param data string
---@param luaNetwork? boolean
_G.show_dialog_box = function(id, msg, data, luaNetwork)
	return open_dialog_box(id, msg:gsub("%\\n", "\n"), data, luaNetwork)
end

---Checks whether a value is part of the table
---@param needle any
---@param haystack table
---@return boolean
_G.in_array = function(needle, haystack)
	for _, v in pairs(haystack) do
		if (needle == v) then
			return true
		end
	end
	return false
end

---Returns a Toribash color data from HEX input.\
---*Supports `RRRGGGBBB` codes to go over the 255 RGB values for glowy colors.*
---@param hex string
---@return Color
_G.get_color_from_hex = function(hex)
	local color = {}
	local hex = hex:gsub("^#", '')
	local pattern = hex:len() < 7 and "%w%w" or "%w%w%w"
	for col in hex:gmatch(pattern) do
		table.insert(color, tonumber(col, 16) / 256)
	end
	color[4] = 1
	return color
end

---Returns a HEX representation of Toribash RGB values (0 - 1)
---@param r number
---@param g number
---@param b number
---@return string
---@overload fun(rgb: number[]):string
_G.get_hex_from_color = function(r, g, b)
	if (type(r) == "table") then
		return get_hex_from_color(r[1], r[2], r[3])
	end
	return	string.format("%02x", r * 255) ..
			string.format("%02x", g * 255) ..
			string.format("%02x", b * 255)
end

---Returns contrast ratio (0-1) for the specified color
---using some [*magic maths*](https://24ways.org/2010/calculating-color-contrast)
---@param color Color
---@return number
_G.get_color_contrast_ratio = function(color)
	return (color[1] * 299 + color[2] * 587 + color[3] * 114) / 1000
end

---Returns a copy of a table with its contents reversed
---@generic T table|UIElement[]
---@param table T[]
---@return T[]
_G.table.reverse = function(table)
	local tblRev = {}
	for _, v in pairs(table) do
		_G.table.insert(tblRev, 1, v)
	end
	return tblRev
end

---@deprecated
---Use `table.reverse()` instead \
---@see table.reverse
_G.tableReverse = function(table) return _G.table.reverse(table) end

-- Returns a copy of a table
---@generic T
---@param table T
---@return T
_G.table.clone = function(table)
	if (type(table) ~= "table") then
		return nil
	end

	local newTable = {}
	for i,v in pairs(table) do
		if (type(v) == "table") then
			newTable[i] = _G.table.clone(v)
		else
			newTable[i] = v
		end
	end
	return newTable
end

---@deprecated
---Use `table.clone()` instead \
---@see table.clone
_G.cloneTable = function(table) return _G.table.clone(table) end

---Comapres whether two tables contain identical data
---@param self table
---@param table2 table
---@return boolean
_G.table.equals = function(self, table2)
	if (self == nil or type(self) ~= type(table2) or type(self) ~= "table") then
		return false
	elseif (self == table2) then
		return true
	end

	local cnt1, cnt2 = 0, 0
	for _ in pairs(self) do cnt1 = cnt1 + 1 end
	for _ in pairs(table2) do cnt2 = cnt2 + 1 end
	if (cnt1 ~= cnt2) then
		return false
	end

	for i,v in pairs(self) do
		if (v ~= table2[i]) then
			if (type(v) == "table" and type(v) == type(table2[i])) then
				if (not table.equals(self[i], table2[i])) then
					return false
				end
			else
				return false
			end
		end
	end

	return true
end

---@deprecated
---Use `table.equals()` instead \
---@see table.equals
_G.table.compare = function(self, table2) return _G.table.equals(self, table2) end

---Returns count of all table fields
---@generic T
---@param table T[]
---@return integer
_G.table.size = function(table)
	local size = 0
	for _, _ in pairs(table) do
		size = size + 1
	end
	return size
end

---Checks whether the table is empty
---@generic T
---@param table T[]
---@return boolean
_G.table.empty = function(table)
	if (table == nil or next(table) == nil) then
		return true
	end
	return false
end

---@deprecated
---Use `table.empty()` instead \
---@see table.empty
_G.empty = function(table) return _G.table.empty(table) end

---Alternative to unpack() function that returns all table values.\
---*Use with caution, this will ***not*** preserve key order*.
---@generic T
---@param list T[]
---@return T ...
_G.table.unpack_all = function(list)
	local indexedTable = {}
	for _, v in pairs(list) do
		table.insert(indexedTable, v)
	end
	return unpack(indexedTable)
end

---@deprecated
---Use `table.unpack_all()` instead \
---@see table.unpack_all
_G.unpack_all = function(tbl) return _G.table.unpack_all(tbl) end

---Shuffles the table's numbered fields
---@generic T
---@param list T[]
---@return T[]
_G.table.shuffle = function(list)
	local shuffled = {}
	for _, v in ipairs(list) do
		table.insert(shuffled, math.random(1, #shuffled + 1), v)
	end
	return shuffled
end

local debugEchoInternal
---Internal function to output provided data as a string
---@param mixed any
---@param returnString? boolean
---@param msg? string String that will preceed the output
---@param rec? boolean Internal parameter to indicate recursive calls
---@return string|nil
debugEchoInternal = function(mixed, returnString, msg, rec)
	msg = msg and msg .. ": " or ""
	local buildRet = returnString and function(str) _G.DEBUGECHOMSG = _G.DEBUGECHOMSG .. str .. "\n" end or echo
	if (not rec) then
		_G.DEBUGECHOMSG = ""
	end
	local vtype = type(mixed)
	if (vtype == "table") then
		buildRet("entering table " .. msg)
		for i,v in pairs(mixed) do
			debugEchoInternal(v, returnString, msg .. i, true)
		end
	elseif (vtype == "boolean") then
		buildRet(msg .. "(" .. vtype .. ")" .. (mixed and "true" or "false"))
	elseif (vtype == "number" or vtype == "string") then
		buildRet(msg .. "(" .. vtype .. ")" .. mixed)
	else
		buildRet(msg .. "[" .. vtype .. "]")
	end
	if (returnString and not rec) then
		msg = _G.DEBUGECHOMSG
		_G.DEBUGECHOMSG = nil
		return msg
	end
	return nil
end

---Outputs or returns any provided data as a string. \
---@see print_r
---@param data any Data to parse and output
---@param returnString boolean Whether we should return the generated string or use `echo()` to print it in chat
---@return string
---@overload fun(data:any):nil
_G.print = function(data, returnString)
	local dataString = tostring(data)
	if (returnString) then
		return dataString
	end
	echo(dataString)
end

---Outputs or returns provided data as a string. \
---*This function goes recursively over any encountered table to output all values inside.* \
---@see print
---@param data any Data to parse and output
---@param returnString boolean Whether we should return the output as a string
---@return string
---@overload fun(data:any):nil
_G.print_r = function(data, returnString)
	return debugEchoInternal(data, returnString)
end

_G.print_json = function(data)
	return print(JSON.encode(data))
end

---Generates a unique ID
---@return string
_G.generate_uid = function()
	local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	local uid = string.gsub(template, '[xy]', function(c)
		local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format('%x', v)
	end)
	return uid
end

---A safe alternative to `string.char()` which doesn't throw an error on invalid data
---@param ... integer
---@return string
_G.string.schar = function(...)
	local result = ''
	local arg = { ... }
	for _,v in ipairs(arg) do
		local char = ''
		pcall(function() char = string.char(v) end)
		result = result .. char
	end
	return result
end

---Returns a copy of this string with all lowercase letters changed to uppercase. \
---Falls back to `string.upper()` on UTF-8 decode failure.
---@param s string
---@return string
---@nodiscard
_G.utf8.safe_upper = function(s)
	if (not pcall(function() s = utf8.upper(s) end)) then
		s = string.upper(s)
	end
	return s
end

---Returns a copy of this string with all uppercase letters changed to lowercase. \
---Falls back to `string.lower()` on UTF-8 decode failure.
---@param s string
---@return string
---@nodiscard
_G.utf8.safe_lower = function(s)
	if (not pcall(function() s = utf8.lower(s) end)) then
		s = string.lower(s)
	end
	return s
end

---Returns the substring of the string that starts at `i` and continues until `j`. \
---Falls back to `string.sub()` on UTF-8 decode failure.
---@param s  string
---@param i  integer
---@param j? integer
---@return string
---@nodiscard
_G.utf8.safe_sub = function(s, i, j)
	if (not pcall(function() s = utf8.sub(s, i, j) end)) then
		s = string.sub(s, i, j)
	end
	return s
end

---Returns string length. \
---Falls back to `string.len()` on UTF-8 decode failure.
---@param s string
---@return integer
_G.utf8.safe_len = function(s)
	local res, len = pcall(function() return utf8.len(s) end)
	---utf8.len() may not throw an error but return a nil
	---we check for both to ensure this function returns an integer
	if (res == false or len == nil) then
		len = string.len(s)
	end
	return len
end

---Escapes all special characters in a specified string. \
---*This actually uses **utf8lib** functions instead of **stringlib**
---to ensure correct behavior on strings with multibyte symbols.*
---@param str string
---@return string
_G.string.escape = function(str)
	-- escape % symbols
	str = utf8.gsub(str, "%%", "%%%%")
	-- escape other single special characters
	local chars = ".+-*?^$[]()"
	for i = 1, #chars do
		local char = "%" .. utf8.safe_sub(chars, i, i)
		str = utf8.gsub(str, char, "%" .. char)
	end

	-- escape paired special characters
	--[[local paired = { {"%[", "%]"}, { "%(", "%)" } }
	for _, v in pairs(paired) do
		local count = 0
		for _, k in pairs(v) do
			if (utf8.find(str, k)) then
				count = count + 1
			end
		end
		if (count > 0 and count % 2 == 0) then
			for _, k in pairs(v) do
				str = utf8.gsub(str, k, "%" .. k)
			end
		end
	end]]
	return str
end

---Returns a list of strings, each of which is a substring of `str` formed by splitting it on boundaries formed by the string `delimiter`.
---@param str string
---@param delimiter string
---@return string[]
_G.string.explode = function(str, delimiter)
	if (string.len(str) == 0) then
		return { }
	end

	local list = { }
	local checkLength = string.len(delimiter)
	delimiter = string.escape(delimiter)
	local res = pcall(function()
		while (string.find(str, ".*" .. delimiter)) do
			local _, endPos = string.find(str, ".*" .. delimiter)
			table.insert(list, string.sub(str, endPos + 1, string.len(str)))
			str = string.sub(str, 0, endPos - checkLength)
		end
	end)
	if (res) then
		table.insert(list, str)
	end
	return table.reverse(list)
end

---Returns a list of strings, each of which is a substring of `str` formed by splitting it on boundaries formed by the string `delimiter`.
---@param str string
---@param delimiter string
---@return string[]
_G.utf8.explode = function(str, delimiter)
	local str_orig = str
	local list = {}
	local checkLength = utf8.safe_len(delimiter)
	delimiter = string.escape(delimiter)
	local res = pcall(function()
		while (utf8.find(str, ".*" .. delimiter)) do
			local _, endPos = utf8.find(str, ".*" .. delimiter)
			table.insert(list, utf8.safe_sub(str, endPos + 1, utf8.safe_len(str)))
			str = utf8.safe_sub(str, 0, endPos - checkLength)
		end
	end)
	if (not res) then
		return string.explode(str_orig, delimiter)
	end
	table.insert(list, str)
	return table.reverse(list)
end

---Returns a string representation of all the `list` elements in the same order, with the `delimiter` string between each element. \
---*Only table fields that are iteratable with `ipairs()` will be joined.*
---@param list table
---@param delimiter string
---@return string
_G.table.implode = function(list, delimiter)
	local str = ""
	for _, v in ipairs(list) do
		str = str == "" and tostring(v) or (str .. delimiter .. tostring(v))
	end
	return str
end

---Formats the specified number as a monetary value and rounds it to the specified decimal precision
---@param n string|number
---@param decimals ?integer
---@return string
_G.numberFormat = function(n, decimals)
	if (type(n) ~= "number" and type(n) ~= "string") then
		if (TB_MENU_DEBUG) then
			error("invalid value type provided (" .. type(n) .. ")")
		end
		return tostring(n)
	end
	n = tostring(n) -- make sure n is a string if it was a number
	local left, num, right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	if (not num) then return n end
	num = left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
	if (decimals and decimals > 0) then
		local numDecimals = num:match("%.%d+$")
		if (not numDecimals) then
			num = num .. "." .. string.rep("0", decimals)
		else
			numDecimals = numDecimals:len()
			if (numDecimals - 1 > decimals) then
				num = num:sub(0, decimals - numDecimals)
			elseif (numDecimals - 1 < decimals) then
				num = num .. string.rep("0", decimals - numDecimals + 1)
			end
		end
	end
	return num
end

---Returns rounded integral value of a specified number `x`.
---@param x number
---@return integer
_G.math.round = function(x)
	if (x >= 0) then
		return math.floor(x + 0.5)
	else
		return math.ceil(x - 0.5)
	end
end

---Clamps value `x` from `l` to `h`
---@param x number
---@param l number
---@param h number
---@return number
_G.math.clamp = function(x, l, h)
	return math.min(math.max(x, l), h)
end

---Returns an ISO 8601 formatted datetime string
---@param timestamp integer? UNIX timestamp to convert to a string. Defaults to current time.
---@param withTimezoneOffset boolean? Whether to append timezone offset at the end of the string. Defaults to `false`.
---@return string
_G.getTimeISO = function(timestamp, withTimezoneOffset)
	timestamp = type(timestamp) == "number" and timestamp or os.time()
	local datestring = os.date("%Y-%m-%dT%H:%M:%S", timestamp)

	if (withTimezoneOffset) then
		---@diagnostic disable-next-line: param-type-mismatch
		local dt1 = os.time(os.date("*t" , timestamp))	-- UTC time
		---@diagnostic disable-next-line: param-type-mismatch
		local dt2 = os.time(os.date("!*t", timestamp))	-- Local time

		local timezonediff, timezonediffm = math.modf((dt2 - dt1) / 3600)
		if (timezonediff == 0 and timezonediffm == 0) then
			datestring = datestring .. "Z"
		else
			datestring = datestring .. (dt1 > dt2 and "+" or "-") .. string.format("%02d", math.abs(timezonediff))
			if (timezonediffm ~= 0) then
				datestring = datestring .. ":" .. (60 * math.abs(timezonediffm))
			end
		end
	end

	---@diagnostic disable-next-line: return-type-mismatch
	return datestring
end

---Removes Toribash color notations from the specified string
---@param str string
---@return string
_G.stripColors = function(str)
	local str_clean = utf8.gsub(str, "%^%d%d", "")
	str_clean = utf8.gsub(str_clean, "%%%d%d%d", "")
	return str_clean
end

if (not UIElement.__mouseHooks) then
	UIElement.mouseHooks()
end
if (not UIElement.__keyboardHooks) then
	UIElement.keyboardHooks()
end
if (not UIElement.__drawHooks) then
	UIElement.drawHooks()
end
