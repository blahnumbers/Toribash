-- Toribash UI manager
-- Created by sir @ Nabi Studios

local w, h = get_window_size()
---Window width that UIElement class currently operates with. \
---**This value does not update live and may not represent the actual window size**.
WIN_W = w
---Window height that UIElement class currently operates with. \
---**This value does not update live and may not represent the actual window size**.
WIN_H = h

add_hook("resolution_changed", "uiResolutionUpdater", function() WIN_W, WIN_H = get_window_size() end)

---Current cursor X coordinate
MOUSE_X = 0
---Current cursor Y coordinate
MOUSE_Y = 0

---True if uilight option is currently enabled \
---Disables animations and some unimportant effects to improve GUI performance on lower end machines
UIMODE_LIGHT = get_option("uilight") == 1

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

KEYBOARDGLOBALIGNORE = KEYBOARDGLOBALIGNORE or false

---@alias UIElementShape
---| 1 # SQUARE
---| 2 # ROUNDED
SQUARE = 1
ROUNDED = 2

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
LEFT = 0
CENTER = 1
RIGHT = 2
LEFTBOT = 3
CENTERBOT = 4
RIGHTBOT = 5
LEFTMID = 6
CENTERMID = 7
RIGHTMID = 8

---@alias UIElementBtnState
---| false # Default UIElement button state
---| 1 # Hover state
---| 2 # Focused state - only used with keyboard controls
---| 3 # Down state
BTN_NONE = false
BTN_HVR = 1
BTN_FOCUS = 2
BTN_DN = 3

---@alias UIElementScrollMode
---| 1 # SCROLL_VERTICAL
---| 2 # SCROLL_HORIZONTAL
SCROLL_VERTICAL = 1
SCROLL_HORIZONTAL = 2

---@alias sort
---| true # SORT_DESCENDING
---| false # SORT_ASCENDING
SORT_DESCENDING = true
SORT_ASCENDING = false

-- Default texture that will be used for fallback by UIElement:updateTexture()
DEFTEXTURE = "../textures/menu/logos/toribash.tga"
TEXTURECACHE = TEXTURECACHE or {}
TEXTUREINDEX = TEXTUREINDEX or 0

STEAM_INT_ID = 3449

---@alias Color number[]
---@type Color
UICOLORWHITE = {1,1,1,1}
---@type Color
UICOLORBLACK = {0,0,0,1}
---@type Color
UICOLORRED = {1,0,0,1}
---@type Color
UICOLORGREEN = {0,1,0,1}
---@type Color
UICOLORBLUE = {0,0,1,1}
---@type Color
UICOLORTORI = {0.58,0,0,1}
---@type Color
DEFTEXTCOLOR = DEFTEXTCOLOR or { 1, 1, 1, 1 }
---@type Color
DEFSHADOWCOLOR = DEFSHADOWCOLOR or { 0, 0, 0, 0.6 }

---@class Vector2
---@field x number
---@field y number

---@class Vector3 : Vector2
---@field z number

---@class Rect : Vector2
---@field w number
---@field h number

---@class Matrix4x4
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

---@type UIElement[]
UIElementManager = UIElementManager or {}
---@type UIElement[]
UIVisualManager = UIVisualManager or {}
---@type UIElement[]
UIViewportManager = UIViewportManager or {}
---@type UIElement[]
UIMouseHandler = UIMouseHandler or {}
---@type UIElement[]
UIKeyboardHandler = UIKeyboardHandler or {}
---@type UIElement[]
UIScrollbarHandler = UIScrollbarHandler or {}

if (not UIElement) then
	---@class UIElementSize
	---@field w number
	---@field h number

	-- Options to use to spawn the new UIElement object\
	-- Majority of options are the same as UIElement class fields
	---@class UIElementOptions
	---@field globalid number
	---@field parent UIElement Specifying a parent will set its globalid and some other settings automatically
	---@field pos number[] Object's target position (relative to parent, if applicable). Negative values imply offset from the opposite direction.
	---@field size number[]
	---@field shift number[] Object's padding (horizontal and vertical). *Only used when spawning an object with UIElement:addChild()*.
	---@field rot number[] Object's rotation (relative to parent, if applicable). *Only used for objects that are parented to a 3D viewport element*.
	---@field radius number *Only used for objects that are parented to a 3D viewport element*.
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
	---@field imageColor Color
	---@field imageHoverColor Color
	---@field imagePressedColor Color
	---@field textfield boolean Whether the object will be used as a text field
	---@field textfieldstr string|string[]
	---@field textfieldsingleline boolean
	---@field textfieldkeepfocusonhide boolean
	---@field isNumeric boolean Whether the textfield object should only accept numeric values
	---@field allowNegative boolean Whether the numeric only textfield should accept negative values
	---@field allowDecimal boolean Whether the numeric only textfield should accept decimal values
	---@field toggle boolean Whether the object will be used as a toggle
	---@field innerShadow number|number[]
	---@field shadowColor Color|Color[]
	---@field shapeType UIElementShape
	---@field rounded number|number[] Rounding size to use for an object with `ROUNDED` shapeType
	---@field scrollEnabled boolean
	---@field keyboard boolean True if we want to spawn the object with default keyboard handlers
	---@field permanentListener boolean
	---@field hoverSound number
	---@field upSound number
	---@field downSound number
	---@field clickThrough boolean
	---@field hoverThrough boolean

	-- Toribash GUI elements manager class
	--
	-- **Ver 2.0 updates:**
	-- * Rewritten all keyboard handlers to make better use of SDL text input events
	-- * `UIElement.keyboardHooks()` to initialize generic text field handlers on start
	-- * `UIElement.mouseHooks()` is now an abstract class function
	-- * `print_r` renamed to `print` to match default Lua function name
	--
	-- **Ver 1.6 updates:**
	-- * `hoverThrough` support
	-- * `UIElement.clock` value to store last graphics update time tick
	-- * Use UITween class for framerate independent animations
	--
	-- **Ver 1.5 updates:**
	-- * `imageHoverColor` and `imagePressedColor` support
	-- * `UIElement:qsort()`, `UIElement:runCmd()` marked as deprecated
	-- * New `table.qsort()`, `table.reverse()`, `table.clone()`, `table.compare()`, `table.empty()`, `table.unpack_all()` functions to replace legacy names
	-- * New `string.escape()` to replace legacy strEsc() function
	-- * Guid() is now `generate_uid()` to prevent confusion with a potential class name
	-- * debugEcho() is now `print_r(mixed data, boolean returnString)`
	--
	-- **Ver 1.4 updates:**
	-- * `UIElement:mouseHooks()` is now initialized when this script is loaded to ensure it isn't required in every script that requires UIElements
	-- * Moved scrollable list update on mouse bar scroll from mouse_move hook to pre_draw for better performance
	-- * Different top/bottom rounding support and `roundedInternal` UIElement field
	-- * Added EmmyLua annotations for some methods
	---@class UIElement
	---@field globalid number Global ID to use for UIElement internal update / display loops
	---@field parent UIElement Parent element
	---@field child UIElement[] Table containing the list of all children of an object
	---@field pos Vector2|Vector3 Object's **absolute** position
	---@field shift? Vector2 Object position **relative to its parent**
	---@field size UIElementSize Object size
	---@field rot? Vector3 *Only applicable to elements displayed in a 3D viewport*
	---@field radius? number *Only applicable to elements displayed in a 3D viewport*
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
	---@field disableUnload boolean True if object's image should not get unloaded when object is destroyed. **Only use this if you know what you're doing**.
	---@field imagePatterned boolean True if object's image should be drawn in patterned mode
	---@field imageColor Color Color modifier that should be applied to object's image. Default is `{ 1, 1, 1, 1 }`.
	---@field imageHoverColor Color Target image color modifier when UIElement is in hover state. *Only used when object is interactive*.
	---@field imagePressedColor Color Image color modifier when UIElement is in pressed state. *Only used when object is interactive*.
	---@field imageAnimateColor Color Current image color modifier when in normal or hover state. *Only used when object is interactive and UI animations are enabled*.
	---@field keyboard boolean True for objects that currently handle keyboard events
	---@field textfield boolean Internal value to modify behavior for elements that are going to be used as text fields
	---@field textfieldstr string[] Text field data. Stored as a table to be able to access data by its reference. **Access UIElement.textfieldstr[1] for the actual string data of a text field**. *Only used for textfield objects*.
	---@field textfieldindex number Current input index (cursor position) for the text field. *Only used for textfield objects*.
	---@field textfieldsingleline boolean Whether the text field should accept multiline input. *Only used for textfield objects*.
	---@field textfieldkeepfocusonhide boolean Whether text field should keep or lose focus when hide() is called on it. Default is `false`.
	---@field toggle boolean Internal value to modify behavior for elements that are going to be used as toggles
	---@field innerShadow number[] Table containing top and bottom inner shadow size
	---@field shadowColor Color[] Table containing top and bottom inner shadow colors
	---@field shapeType UIElementShape Object's shape type. Can be either SQUARE (1) or ROUNDED (2).
	---@field roundedInternal number[] Values that the object will use for rounding edges (top and bottom)
	---@field rounded number Max value out of UIElement.roundedInternal values
	---@field isactive boolean Internal value to tell if an interactive object is currently active
	---@field scrollEnabled boolean If true, an interactive object will also handle mouse scroll events in its UIElement.btnDown() callback
	---@field hoverState UIElementBtnState Current mouse hover state of an object
	---@field pressedPos Vector2 Internal table containing relative cursor position at the moment of UIElement.btnDown() call on an active scroll bar
	---@field permanentListener boolean True if we want an object with keyboard handlers to react to all keyboard events, even when not in focus. Permanent keyboard listeners will also not exit keyboard loop early.
	---@field hoverSound integer Sound ID to play when object enters BTN_HVR mouse hover state
	---@field hoverClock number Time for the BTN_HVR state enter
	---@field upSound integer Sound ID to play when object exits BTN_DN mouse hover state
	---@field downSound integer Sound ID to play when object enters BTN_DN mouse hover state
	---@field clickThrough boolean If true, successful click on an object will not exit mouse loop early
	---@field hoverThrough boolean If true, hovering over an object will not exit mouse loop early
	---@field displayed boolean Read-only value to tell if the object is currently being displayed
	---@field destroyed boolean Read-only value to indicate the object has been destroyed. Use this to check whether the UIElement still exists when a UIElement:kill() function may have been called on its reference elsewhere.
	---@field killAction function Additional callback to be executed when object is being destroyed
	---@field scrollBar UIElement Reference to scrollable list holder's scroll bar
	---@field positionDirty boolean Read-only value to tell the UIElement internal loops to refresh element position
	---@field scrollableListTouchScrollActive boolean Read-only value used for scrollable list view elements on touch devices
	UIElement = {
		ver = 2.0,
		clock = os.clock(),
		animationDuration = 0.1
	}
	UIElement.__index = UIElement

	-- Whether UIElement.mouseHooks() has already been called to spawn mouse hooks
	---@type boolean
	UIElement.__mouseHooks = nil

	---Whether UIElement.keyboardHooks() has been called to initialize keyboard hooks
	UIElement.__keyboardHooks = nil
end

---Callback function triggered on text input event while UIElement is active and focused
---@param input string
UIElement.textInput = function(input) end

---Custom callback function triggered on text input event while UIElement is active and focused
UIElement.textInputCustom = function() end

-- Callback function triggered on any keyboard key down event while UIElement is active
---@param key number Pressed key's keycode
---@return number|nil
---@overload fun(key?: number)
UIElement.keyDown = function(key) end

-- Callback function triggered on any keyboard key up event while UIElement is active
---@param key number Pressed key's keycode
---@return number|nil
---@overload fun(key?: number)
UIElement.keyUp = function(key) end

-- Custom callback function triggered on any keyboard key down event while UIElement is active
---@param key number Pressed key's keycode
---@return number|nil
---@overload fun(key?: number)
UIElement.keyDownCustom = function(key) end

-- Custom callback function triggered on any keyboard key up event while UIElement is active
---@param key number Pressed key's keycode
---@return number|nil
---@overload fun(key?: number)
UIElement.keyUpCustom = function(key) end

-- Callback function triggered on mouse button down event when cursor is within object transform
---@param buttonId number Mouse button ID associated with the event
---@param x number Mouse cursor X position associated with the event
---@param y number Mouse cursor Y position associated with the event
---@overload fun(buttonId?: number, x?: number, y?: number)
UIElement.btnDown = function(buttonId, x, y) end

-- Callback function triggered on mouse button up event when cursor is within object transform
---@param buttonId number Mouse button ID associated with the event
---@param x number Mouse cursor X position associated with the event
---@param y number Mouse cursor Y position associated with the event
---@overload fun(buttonId?: number, x?: number, y?: number)
UIElement.btnUp = function(buttonId, x, y) end

-- Callback function triggered on mouse move event when cursor is within object transform
---@param x number Mouse cursor X position associated with the event
---@param y number Mouse cursor Y position associated with the event
---@overload fun(x?: number, y?: number)
UIElement.btnHover = function(x, y) end

-- Callback function triggered on right mouse button up event when cursor is within object transform\
-- We use a separate event because normally right mouse clicks do not produce events so behavior won't be the same
---@param buttonId number Mouse button ID associated with the event
---@param x number Mouse cursor X position associated with the event
---@param y number Mouse cursor Y position associated with the event
---@overload fun(buttonId?: number, x?: number, y?: number)
UIElement.btnRightUp = function(buttonId, x, y) end

-- Spawn a new UI Element
---@param o UIElementOptions Options to use for spawning the new object
---@return UIElement
function UIElement:new(o)
	---@type UIElement
	local elem = {	globalid = 0,
					child = {},
					pos = {},
					shift = {},
					bgColor = { 1, 1, 1, 0 },
					innerShadow = { 0, 0 },
					positionDirty = true
					}
	setmetatable(elem, self)

	o = o or nil
	if (o) then
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
				elem.rot = { x = o.rot[1], y = o.rot[2], z = o.rot[3] }
				elem.radius = o.radius
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
		if (o.viewport) then
			elem.viewport = o.viewport
		end
		if (o.bgColor) then
			elem.bgColor = o.bgColor
		end
		if (o.bgImage) then
			elem.disableUnload = o.disableUnload
			elem.imagePatterned = o.imagePatterned or false
			elem.imageColor = o.imageColor or { 1, 1, 1, 1 }
			if (type(o.bgImage) == "table") then
				elem:updateImage(o.bgImage[1], o.bgImage[2])
			else
				---@diagnostic disable-next-line: param-type-mismatch
				elem:updateImage(o.bgImage)
			end
		end

		-- Textfield value is a table to allow proper initiation / use after obj is created
		if (o.textfield) then
			elem.textfield = o.textfield
			---@diagnostic disable-next-line: assign-type-mismatch
			elem.textfieldstr = o.textfieldstr and (type(o.textfieldstr) == "table" and o.textfieldstr or { o.textfieldstr .. '' }) or { "" }
			elem.textfieldindex = utf8.len(elem.textfieldstr[1])
			elem.textfieldsingleline = o.textfieldsingleline
			elem.textfieldkeepfocusonhide = o.textfieldkeepfocusonhide
			elem.textInput = function(input) elem:textfieldInput(input, o.isNumeric, o.allowNegative, o.allowDecimal) end
			elem.keyDown = function(key)
					if (elem:textfieldKeyDown(key) and elem.textInputCustom) then
						-- We have updated textfield input and have a custom text input function defined
						-- Fire a textInputCustom() call for seamless behavior across all input field actions
						elem.textInputCustom()
					end
				end
			elem.keyUp = function(key) elem:textfieldKeyUp(key) end
			table.insert(UIKeyboardHandler, elem)
		end
		if (o.toggle) then
			elem.toggle = o.toggle
			elem.keyDown = function(key) end
			elem.keyUp = function(key) elem:textfieldKeyUp(key) end
			table.insert(UIKeyboardHandler, elem)
		end
		if (o.innerShadow and o.shadowColor) then
			elem.shadowColor = {}
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
			if (not UIMODE_LIGHT or elem.rounded > elem.size.w / 4) then
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
				elem.imageAnimateColor = table.clone(elem.imageColor)
			end
			elem.hoverState = BTN_NONE
			elem.hoverClock = UIElement.clock
			elem.pressedPos = { x = 0, y = 0 }
			elem.btnDown = function(buttonId, x, y) end
			elem.btnUp = function(buttonId, x, y) end
			elem.btnHover = function(x, y) end
			elem.btnRightUp = function(buttonId, x, y) end
			table.insert(UIMouseHandler, elem)
		end
		if (o.keyboard) then
			elem.permanentListener = o.permanentListener
			elem.keyDown = function(key) end
			elem.keyUp = function(key) end
			elem.keyDownCustom = function(key) end
			elem.keyUpCustom = function(key) end
			table.insert(UIKeyboardHandler, elem)
		end
		if (o.hoverSound) then
			elem.hoverSound = o.hoverSound
		end
		if (o.upSound) then
			elem.upSound = o.upSound
		end
		if (o.downSound) then
			elem.downSound = o.downSound
		end
		if (o.clickThrough) then
			elem.clickThrough = o.clickThrough
		end
		if (o.hoverThrough) then
			elem.hoverThrough = o.hoverThrough
		end

		---Only add root elements to UIElementManager to decrease table traversal speed
		if (elem.parent == nil) then
			table.insert(UIElementManager, elem)
		end

		-- Display is enabled by default, comment this out to disable
		if (elem.viewport or (elem.parent and elem.parent.viewport)) then
			table.insert(UIViewportManager, elem)
		else
			table.insert(UIVisualManager, elem)
		end

		-- Force update global x/y pos when spawning element
		elem:updatePos()
		elem.displayed = true
	end

	return elem
end

-- Spawns a new UIElement and sets the calling object as its parent
---@param o UIElementOptions
---@param copyShape? boolean Whether to copy shapeType and rounded values to the new object
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
	return UIElement:new(o)
end

-- Specifies rounding value to be used for UIElements with ROUNDED shape type
---@param rounded number|number[]
function UIElement:setRounded(rounded)
	if (type(rounded) ~= "table") then
		self.roundedInternal = { rounded, rounded }
	else
		self.roundedInternal = { rounded[1], rounded[#rounded] }
	end

	local minRounded = self.roundedInternal[1] + self.roundedInternal[2] > math.min(table.unpack_all(self.size)) and math.min(table.unpack_all(self.size)) / 2 or math.max(unpack(self.roundedInternal))

	self.rounded = 0
	for i,v in pairs(self.roundedInternal) do
		if (v > minRounded) then
			self.roundedInternal[i] = minRounded
		end
		self.rounded = math.max(self.rounded, self.roundedInternal[i])
	end
	self.diskSlices = math.min(self.rounded * 5, 50)
end

-- Adds mouse handlers to use for an interactive UIElement object
---@param btnDown? function Button down callback function
---@param btnUp? function Button up callback function
---@param btnHover? function Mouse hover callback function
---@param btnRightUp? function Right mouse button up callback function
function UIElement:addMouseHandlers(btnDown, btnUp, btnHover, btnRightUp)
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
		for i, v in pairs(UIKeyboardHandler) do
			v.keyboard = false
			KEYBOARDGLOBALIGNORE = false
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

---Function to initialize a scrollable list with a scroll bar
---@param listHolder UIElement
---@param listElements UIElement[]
---@param toReload UIElement
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

	self.listReload = function() toReload:reload() end
	self.scrollReload = function() if (self.holder) then self.holder:reload() end self:reload() end

	self:barScroll(listElements, listHolder, toReload, posShift[1], enabled)
	local targetPos = nil

	self:addMouseHandlers(
		function(s, x, y)
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
		end)

	if (not self.isScrollBar) then
		self.isScrollBar = true
		table.insert(UIScrollbarHandler, self)
	end

	local barScroller = self:addChild({})
	barScroller.uid = generate_uid()
	barScroller.killAction = function()
		remove_hooks("barScroller" .. barScroller.uid)
		remove_hooks("touchScroller" .. barScroller.uid)
	end
	add_hook("pre_draw", "barScroller" .. barScroller.uid, function()
			if (targetPos ~= nil) then
				self:barScroll(listElements, listHolder, toReload, targetPos, enabled)
				targetPos = nil
			end
		end)

	if (is_mobile()) then
		local lastListHolderVal = -1
		local deltaChange = 0
		local lastClock = UIElement.clock
		listHolder.parent:addMouseHandlers(function(_, x, y)
				listHolder.parent.scrollableListTouchScrollActive = true
				lastListHolderVal = (self.orientation == SCROLL_VERTICAL) and y or x
			end, function()
				listHolder.parent.scrollableListTouchScrollActive = false
				lastListHolderVal = -1
			end, function(x, y)
				if (listHolder.parent.scrollableListTouchScrollActive) then
					lastClock = UIElement.clock
					local targetValue = (self.orientation == SCROLL_VERTICAL) and y or x
					deltaChange = lastListHolderVal - targetValue
					lastListHolderVal = targetValue
				end
			end)
		add_hook("pre_draw", "touchScroller" .. barScroller.uid, function()
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
				end
			end)
	end
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
			listHolder.parent:reloadListElements(listHolder, listElements, toReload, enabled, self.orientation)
			self.scrollReload()
		end
	else
		local elementWidth = listElements[1].size.w
		local listWidth = #listElements * elementWidth
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
			listHolder.parent:reloadListElements(listHolder, listElements, toReload, enabled, self.orientation)
			self.scrollReload()
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
function UIElement:barScroll(listElements, listHolder, toReload, posShift, enabled)
	if (#listElements == 0) then return end
	if (self.orientation == SCROLL_VERTICAL) then
		local sizeH = math.floor(self.size.h / 4)
		local listHeight = listElements[1].size.h * #listElements

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

		if (scrollDelta > 0) then
			scrollDelta = -1 * math.min(scrollDelta, listHeight + listHolder.shift.y)
		else
			scrollDelta = -1 * math.max(scrollDelta, listHolder.shift.y + listHolder.size.h)
		end

		if (scrollDelta ~= 0) then
			listHolder:moveTo(listHolder.shift.x, scrollDelta, true)

			local scrollProgress = -(listHolder.size.h + listHolder.shift.y) / (listHeight - listHolder.size.h)
			self:moveTo(self.shift.x, (self.parent.size.h - self.size.h) * scrollProgress)

			listHolder.parent:reloadListElements(listHolder, listElements, toReload, enabled, self.orientation)
		end
	else
		local listWidth = #listElements * listElements[1].size.w

		if (scrollDelta > 0) then
			scrollDelta = -1 * math.min(scrollDelta, listWidth + listHolder.shift.x)
		else
			scrollDelta = -1 * math.max(scrollDelta, listHolder.shift.x + listHolder.size.w)
		end

		if (scrollDelta ~= 0) then
			listHolder:moveTo(scrollDelta, listHolder.shift.y, true)

			local scrollProgress = -(listHolder.size.w + listHolder.shift.x) / (listWidth - listHolder.size.w)
			self:moveTo((self.parent.size.w - self.size.w) * scrollProgress, self.shift.y)

			listHolder.parent:reloadListElements(listHolder, listElements, toReload, enabled, self.orientation)
		end
	end
end

-- Sets the specified function to run when UIElement is displayed
---@param funcOnly boolean|nil If true, will not run default UIElement:display() functionality and only run the specified function
---@param func function Custom function to run when object is displayed
---@param drawBefore? boolean If true, will assign a function to run **before** the main UIElement:display() function
---@overload fun(self: UIElement, func: function, drawBefore?: boolean)
function UIElement:addCustomDisplay(funcOnly, func, drawBefore)
	---@type boolean|function|nil
	local drawBeforeFunc = drawBefore
	if (type(funcOnly) == "function") then
		drawBeforeFunc = func
		func = funcOnly
		funcOnly = false
	end

	self.customDisplayOnly = funcOnly
	if (drawBeforeFunc) then
		self.customDisplayBefore = func
	else
		self.customDisplay = func
	end
	if (func) then
		func()
	end
end

-- Destroys current UIElement object
---@param childOnly? boolean If true, will only destroy current object's children and keep the object itself
function UIElement:kill(childOnly)
	for i,v in pairs(self.child) do
		if (v.kill) then
			v:kill()
		end
	end
	if (childOnly) then
		self.child = {}
		return true
	end
	if (self.destroyed) then
		return true
	end

	if (self.killAction) then
		self.killAction()
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
---*Must be run from `draw2d` hook.*
---@param globalid ?number Global ID that the objects to display belong to
function UIElement:drawVisuals(globalid)
	UIElement.clock = os.clock()
	local globalid = globalid or self.globalid
	for _, v in pairs(UIElementManager) do
		if (v.globalid == globalid) then
			v:updatePos()
		end
	end
	for _, v in pairs(UIVisualManager) do
		if (v.globalid == globalid) then
			v:display()
		end
	end
end

---Main UIElement loop that displays viewport elements. \
---*Must be run from `draw_viewport` hook.*
---@param globalid ?number Global ID that the objects to display belong to
function UIElement:drawViewport(globalid)
	local globalid = globalid or self.globalid
	for i, v in pairs(UIViewportManager) do
		if (v.globalid == globalid) then
			v:displayViewport()
		end
	end
end

---Internal function that's used to draw a viewport UIElement. \
---*You likely don't need to call this manually.* \
---@see UIElement.drawViewport
---@see UIElement.addCustomDisplay
function UIElement:displayViewport()
	if (self.customDisplayBefore) then
		self.customDisplayBefore()
	end
	if (self.viewport) then
		set_viewport(self.pos.x, self.pos.y, self.size.w, self.size.h)
	elseif (not self.customDisplayOnly) then
		set_color(unpack(self.bgColor))
		if (self.bgImage) then
			draw_sphere(self.pos.x, self.pos.y, self.pos.z, self.radius, self.rot.x, self.rot.y, self.rot.z, self.bgImage)
		else
			draw_sphere(self.pos.x, self.pos.y, self.pos.z, self.radius, self.rot.x, self.rot.y, self.rot.z)
		end
	end
	if (self.customDisplay) then
		self.customDisplay()
	end
end

---Internal function that's used to draw a regular UIElement. \
---*You likely don't need to call this manually.* \
---@see UIElement.drawVisuals
---@see UIElement.addCustomDisplay
function UIElement:display()
	if (self.customDisplayBefore) then
		self.customDisplayBefore()
	end
	if (self.hoverState ~= false) then
		local animateRatio = (UIElement.clock - (self.hoverClock or 0)) / UIElement.animationDuration
		if (self.hoverColor) then
			if (UIMODE_LIGHT) then
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
			if (UIMODE_LIGHT) then
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

	if (not self.customDisplayOnly and (self.bgColor[4] > 0 or self.bgImage or self.interactive)) then
		if (self.innerShadow[1] > 0 or self.innerShadow[2] > 0) then
			set_color(unpack(self.shadowColor[1]))
			if (self.shapeType == ROUNDED) then
				draw_disk(self.pos.x + self.roundedInternal[1], self.pos.y + self.roundedInternal[1], 0, self.roundedInternal[1], self.diskSlices, 1, -180, 90, 0)
				draw_disk(self.pos.x + self.size.w - self.roundedInternal[1], self.pos.y + self.roundedInternal[1], 0, self.roundedInternal[1], self.diskSlices, 1, 90, 90, 0)
				draw_quad(self.pos.x + self.roundedInternal[1], self.pos.y, self.size.w - self.roundedInternal[1] * 2, self.roundedInternal[1])
				draw_quad(self.pos.x, self.pos.y + self.roundedInternal[1], self.size.w, self.size.h / 2 - self.roundedInternal[1])
				set_color(unpack(self.shadowColor[2]))
				draw_disk(self.pos.x + self.roundedInternal[2], self.pos.y + self.size.h - self.roundedInternal[2], 0, self.roundedInternal[2], self.diskSlices, 1, -90, 90, 0)
				draw_disk(self.pos.x + self.size.w - self.roundedInternal[2], self.pos.y + self.size.h - self.roundedInternal[2], 0, self.roundedInternal[2], self.diskSlices, 1, 0, 90, 0)
				draw_quad(self.pos.x, self.pos.y + self.size.h / 2, self.size.w, self.size.h / 2 - self.roundedInternal[2])
				draw_quad(self.pos.x + self.roundedInternal[2], self.pos.y + self.size.h - self.roundedInternal[2], self.size.w - self.roundedInternal[2] * 2, self.roundedInternal[2])
			else
				draw_quad(self.pos.x, self.pos.y, self.size.w, self.size.h / 2)
				set_color(unpack(self.shadowColor[2]))
				draw_quad(self.pos.x, self.pos.y + self.size.h / 2, self.size.w, self.size.h / 2)
			end
		end
		if (self.interactive and not self.isactive and self.inactiveColor) then
			set_color(unpack(self.inactiveColor))
		elseif (self.hoverState == BTN_HVR and self.hoverColor) then
			set_color(unpack(self.animateColor))
		elseif (self.hoverState == BTN_FOCUS and self.hoverColor) then
			set_color(unpack(self.animateColor))
		elseif (self.hoverState == BTN_DN and self.pressedColor) then
			set_color(unpack(self.pressedColor))
		elseif (self.interactive) then
			set_color(unpack(self.animateColor))
		else
			set_color(unpack(self.bgColor))
		end
		if (self.interactive and (self.hoverState == BTN_HVR or self.hoverState == BTN_DN) and (self.hoverColor or self.imageHoverColor)) then
			set_mouse_cursor(1)
		end
		if (self.shapeType == ROUNDED) then
			draw_disk(self.pos.x + self.roundedInternal[1], self.pos.y + self.roundedInternal[1] + self.innerShadow[1], 0, self.roundedInternal[1], self.diskSlices, 1, -180, 90, 0)
			draw_disk(self.pos.x + self.roundedInternal[2], self.pos.y + self.size.h - self.roundedInternal[2] - self.innerShadow[2], 0, self.roundedInternal[2], self.diskSlices, 1, -90, 90, 0)
			draw_disk(self.pos.x + self.size.w - self.roundedInternal[1], self.pos.y + self.roundedInternal[1] + self.innerShadow[1], 0, self.roundedInternal[1], self.diskSlices, 1, 90, 90, 0)
			draw_disk(self.pos.x + self.size.w - self.roundedInternal[2], self.pos.y + self.size.h - self.roundedInternal[2] - self.innerShadow[2], 0, self.roundedInternal[2], self.diskSlices, 1, 0, 90, 0)
			draw_quad(self.pos.x + self.roundedInternal[1], self.pos.y + self.innerShadow[1], self.size.w - self.roundedInternal[1] * 2, self.roundedInternal[1])
			draw_quad(self.pos.x, self.pos.y + self.roundedInternal[1] + self.innerShadow[1], self.size.w, self.size.h - self.roundedInternal[2] - self.roundedInternal[1] - self.innerShadow[2] - self.innerShadow[1])
			draw_quad(self.pos.x + self.roundedInternal[2], self.pos.y + self.size.h - self.roundedInternal[2] - self.innerShadow[2], self.size.w - self.roundedInternal[2] * 2, self.roundedInternal[2])
		else
			draw_quad(self.pos.x, self.pos.y + self.innerShadow[1], self.size.w, self.size.h - self.innerShadow[1] - self.innerShadow[2])
		end
		if (self.bgImage) then
			local targetImageColor = self.interactive and ((self.hoverState == BTN_HVR or self.hoverState == BTN_FOCUS) and self.imageAnimateColor or (self.hoverState == BTN_DN and self.imagePressedColor or self.imageColor)) or self.imageColor
			if (self.imagePatterned) then
				draw_quad(self.pos.x, self.pos.y, self.size.w, self.size.h, self.bgImage, self.imagePatterned, targetImageColor[1], targetImageColor[2], targetImageColor[3], targetImageColor[4])
			else
				draw_quad(self.pos.x, self.pos.y, self.size.w, self.size.h, self.bgImage, false, targetImageColor[1], targetImageColor[2], targetImageColor[3], targetImageColor[4])
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

---Whether current UIElement is being displayed
---@return boolean
function UIElement:isDisplayed()
	return self.displayed;
	--[[local viewport = (self.viewport or (self.parent and self.parent.viewport)) and true or false

	if (not viewport) then
		for i,v in pairs(UIVisualManager) do
			if (self == v) then
				return true
			end
		end
	else
		for i,v in pairs(UIViewportManager) do
			if (self == v) then
				return true
			end
		end
	end
	return false]]
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

	for i,v in pairs(UIVisualManager) do
		if (self == v) then
			num = i
			break
		end
	end
	for i,v in pairs(UIViewportManager) do
		if (self == v) then
			num = i
			break
		end
	end

	if (not num) then
		if (viewport) then
			table.insert(UIViewportManager, self)
		else
			table.insert(UIVisualManager, self)
		end
		if (self.interactive or self.keyboard) then
			self:activate()
		end
	end

	for _, v in pairs(self.child) do
		v:show()
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
	if (self.displayed == false) then
		return
	end

	if (self.interactive or self.keyboard) then
		self:deactivate()
	end

	for i,v in pairs(UIVisualManager) do
		if (self == v) then
			table.remove(UIVisualManager, i)
			break
		end
	end

	for i,v in pairs(UIViewportManager) do
		if (self == v) then
			table.remove(UIViewportManager, i)
			break
		end
	end

	if (self.menuKeyboardId and not self.textfieldkeepfocusonhide) then
		self:disableMenuKeyboard()
	end
	self.displayed = false
end

---Key up event handler for text field elements. \
---*You likely don't need to call this function manually.*
---@param key integer
---@see UIElement.keyboardHooks
function UIElement:textfieldKeyUp(key)
	if ((key == 13 or key == 271) and self.enteraction) then
		self.enteraction(self.textfieldstr[1])
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
	local strLen = utf8.len(input)

	local consumeSymbols = consumeSymbols or 0
	local consumeSymbolsAfter = consumeSymbolsAfter or 0
	local part1 = utf8.sub(self.textfieldstr[1], 0, self.textfieldindex - consumeSymbols)
	local part2 = utf8.sub(self.textfieldstr[1], self.textfieldindex + 1 + consumeSymbolsAfter)
	self.textfieldstr[1] = part1 .. input .. part2
	self.textfieldindex = self.textfieldindex - consumeSymbols + strLen

	-- Double check we didn't get any newlines if content was pasted
	if (self.textfieldsingleline) then
		local replacements = 0
		self.textfieldstr[1], replacements = utf8.gsub(self.textfieldstr[1], "\\n", "")
		self.textfieldindex = self.textfieldindex - 2 * replacements
		self.textfieldstr[1], replacements = utf8.gsub(self.textfieldstr[1], "\n", "")
		self.textfieldindex = self.textfieldindex - replacements
	end
end

---Text field input handler function \
---*You likely don't need to call this function manually.*
---@param input string
---@param isNumeric boolean
---@param allowNegative boolean
---@param allowDecimal boolean
---@see UIElement.keyboardHooks
function UIElement:textfieldInput(input, isNumeric, allowNegative, allowDecimal)
	local replaceSymbols = 0
	local replaceSymbolsAfter = 0
	local negativeSign = false
	local clipboardPaste = get_clipboard_text() == input

	local strLen = utf8.len(input)
	if (isNumeric) then
		if (allowNegative and input:find("^-")) then
			negativeSign = true
		end
		local regexMatch = "[^0-9" .. (allowDecimal and "%." or "") .. "]"
		input = utf8.gsub(input, regexMatch, "")
	end
	if (strLen == 0 and not negativeSign) then
		return
	elseif (strLen > 1 and not clipboardPaste) then
		-- We are likely dealing with keyboard autocompletion
		-- Let's try to guess which part of the text we need to replace
		local text = utf8.sub(self.textfieldstr[1], 0, self.textfieldindex)
		local lastWordStart, lastWordReplacements = utf8.gsub(text, "^.*[^%'%w]([%w%']+)$", "%1")
		if (lastWordReplacements == 0) then
			lastWordStart, lastWordReplacements = utf8.gsub(text, "^([%w%']+)$", "%1")
		end
		if (lastWordReplacements ~= 0) then
			local textFromLastWord = utf8.sub(self.textfieldstr[1], self.textfieldindex - utf8.len(lastWordStart) + 1)
			local lastWord, replacements = utf8.gsub(textFromLastWord, "^([%w%'])", "%1")
			if (lastWord ~= nil and replacements ~= 0) then
				replaceSymbols = utf8.len(lastWordStart)
				replaceSymbolsAfter = utf8.len(lastWord) - replaceSymbols
			end
		end
	end
	if (negativeSign and self.textfieldindex - replaceSymbols == 0) then
		input = "-" .. input
	end

	if (utf8.len(input) == 0) then
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
			self.textfieldstr[1] = utf8.sub(self.textfieldstr[1], 0, self.textfieldindex - 1) .. utf8.sub(self.textfieldstr[1], self.textfieldindex + 1)
			self.textfieldindex = self.textfieldindex - 1
			return true
		end
	elseif (key == 127 or key == 266) then -- SDLK_DELETE
		self.textfieldstr[1] = utf8.sub(self.textfieldstr[1], 0, self.textfieldindex) .. utf8.sub(self.textfieldstr[1], self.textfieldindex + 2)
		return true
	elseif (key == 276) then -- arrow left
		self.textfieldindex = self.textfieldindex > 0 and self.textfieldindex - 1 or 0
	elseif (key == 275) then -- arrow right
		self.textfieldindex = self.textfieldindex < utf8.len(self.textfieldstr[1]) and self.textfieldindex + 1 or self.textfieldindex
	elseif (key == 13 or key == 271 and not self.textfieldsingleline) then -- newline
		self:textfieldUpdate("\n")
		return true
	elseif (key == 118 and get_keyboard_ctrl() > 0) then -- CTRL + V
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
			return v.permanentListener and 0 or 1
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
			KEYBOARDGLOBALIGNORE = true
			v.keyDown(key)
			if (v.keyDownCustom) then
				v.keyDownCustom(key)
			end
			return 1
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
	for i,v in pairs(table.reverse(UIKeyboardHandler)) do
		if (v.keyboard == true) then
			v.textInput(input)
			if (v.textInputCustom) then
				v.textInputCustom()
			end
			return 1
		end
	end
	return 0
end

---Generic method to enable keyboard input handlers for current UIElement
function UIElement:enableMenuKeyboard()
	TB_MENU_INPUT_ISACTIVE = true
	enable_menu_keyboard(self.pos.x, self.pos.y, self.size.w, self.size.h)
	local id = 1
	for i,v in pairs(UIKeyboardHandler) do
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
	for i,v in pairs(UIKeyboardHandler) do
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
	add_hook("key_down", "uiKeyboardHandler", function(key)
			if (TB_MENU_INPUT_ISACTIVE) then
				return UIElement.handleKeyDown(key)
			end
		end)
	add_hook("key_up", "uiKeyboardHandler", function(key)
			if (TB_MENU_INPUT_ISACTIVE) then
				return UIElement.handleKeyUp(key)
			end
		end)
	add_hook("text_input", "uiKeyboardHandler", function(input)
			if (TB_MENU_INPUT_ISACTIVE) then
				return UIElement.handleInput(input)
			end
		end)

	UIElement.__keyboardHooks = true
end

---UIElement internal function to handle mouse down event for an object. \
---*You likely don't need to call this function manually.*
---@param btn number Mouse button ID
---@param x number
---@param y number
function UIElement:handleMouseDn(btn, x, y)
	enable_camera_movement()
	for _, v in pairs(UIKeyboardHandler) do
		v.keyboard = v.permanentListener
		KEYBOARDGLOBALIGNORE = false
	end
	for _, v in pairs(table.reverse(UIMouseHandler)) do
		if (v.isactive) then
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
				return v.clickThrough and 0 or 1
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
function UIElement:handleMouseUp(btn, x, y)
	local actionTriggered = false
	for _, v in pairs(table.reverse(UIMouseHandler)) do
		if (v.isactive) then
			if (v.hoverState == BTN_DN and btn == 1) then
				v.hoverState = BTN_NONE
				if (not actionTriggered and x > v.pos.x and x < v.pos.x + v.size.w and y > v.pos.y and y < v.pos.y + v.size.h) then
					v.hoverState = BTN_HVR
					if (v.upSound) then
						play_sound(v.upSound)
					end
					v.btnUp(btn, x, y)
					actionTriggered = true
					set_mouse_cursor(1)
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
function UIElement:handleMouseHover(x, y)
	local disable = nil
	MOUSE_X, MOUSE_Y = x, y

	for _, v in pairs(table.reverse(UIMouseHandler)) do
		if (v.isactive) then
			if (v.hoverState == BTN_DN) then
				disable = v.hoverThrough ~= true
				v.btnHover(x,y)
			elseif (disable and not v.scrollableListTouchScrollActive) then
				v.hoverState = BTN_NONE
			elseif (x > v.pos.x and x < v.pos.x + v.size.w and y > v.pos.y and y < v.pos.y + v.size.h) then
				if (v.hoverState == false and v.hoverSound) then
					play_sound(v.hoverSound)
				end
				if (v.hoverState ~= BTN_DN) then
					if (v.hoverState == BTN_NONE) then
						v.hoverClock = os.clock()
					end
					v.hoverState = BTN_HVR
					if (not v.textfield) then
						disable = v.hoverThrough ~= true
					end
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
	add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y)
			local toReturn = TB_MENU_MAIN_ISOPEN == 1 and 1 or 0
			toReturn = UIElement:handleMouseDn(s, x, y) or toReturn
			if (Tutorials and (TUTORIALJOINTLOCK or (not TUTORIALJOINTLOCK and TUTORIALKEYBOARDLOCK))) then
				toReturn = Tutorials:ignoreMouseClick() or toReturn
			end
			return toReturn
		end)
	add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y)
			UIElement:handleMouseUp(s, x, y)
		end)
	add_hook("mouse_move", "uiMouseHandler", function(x, y)
			UIElement:handleMouseHover(x, y)
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
	self.positionDirty = true
end

---Internal function to update position of current UIElement based on its parent movement
function UIElement:updateChildPos()
	if (self.parent.viewport or not self.positionDirty) then
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
end

---Adapts the specified string to fit inside UIElement object and sets custom display function to draw it
---@param override boolean|nil Whether to disable the default `display()` functionality
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
---@overload fun(self, str: string, x?: number, y?: number, font?: FontId, align?: UIElementTextAlign, maxscale?: number, minscale?: number, intensity?: number, shadow?: number, col1?: Color, col2?: Color, textfield?: boolean)
function UIElement:addAdaptedText(override, str, x, y, font, align, maxscale, minscale, intensity, shadow, col1, col2, textfield)
	if (type(override) == "string") then
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
	if (not str) then
		if (TB_MENU_DEBUG) then
			echo("Error: string is undefined")
		end
		return false
	end
	local scale = maxscale or 1
	local minscale = minscale or 0.2
	local font = font or FONTS.MEDIUM

	while (not self:uiText(str, x, y, font, nil, scale, nil, nil, nil, nil, nil, true, nil, nil, textfield) and scale > minscale) do
		scale = scale - 0.05
	end

	self.textScale = scale
	self.textFont = font
	self:addCustomDisplay(override, function()
			self:uiText(str, x, y, font, align, scale, nil, shadow, col1, col2, intensity, nil, nil, nil, textfield)
		end)
end

---Generic function to display text within current UIElement using specified settings
---@param input string Text to display in an object
---@param x ?number X offset for the displayed text
---@param y ?number Y offset for the displayed text
---@param font ?FontId
---@param align ?UIElementTextAlign
---@param scale ?number
---@param angle ?number Text rotation in degrees
---@param shadow ?number Text shadow grow value. It is recommended to keep this value relatively low (<10) for best looks.
---@param col1 ?Color Primary text color, uses `uiColor` value by default
---@param col2 ?Color Text shadow color, uses `uiShadowColor` value by default
---@param intensity ?number Text color intensity, only used for `FONTS.BIG` and `FONTS.BIGGER`. Use values from `0` to `1`.
---@param check ?boolean Whether this call is only to be used for checking whether text fits the object with current settings
---@param refresh ?boolean Deprecated
---@param nosmooth ?boolean Whether to disable pixel perfect text drawing
---@param textfield ?boolean Whether this function is being used as part of text field display routine
---@return boolean
function UIElement:uiText(input, x, y, font, align, scale, angle, shadow, col1, col2, intensity, check, refresh, nosmooth, textfield)
	if (not scale and check) then
		echo("^04UIElement error: ^07uiText() cannot take undefined scale argument with check enabled")
		return true
	end
	local font = font or FONTS.MEDIUM
	local x = x and self.pos.x + x or self.pos.x
	local y = y and self.pos.y + y or self.pos.y
	local font_mod = getFontMod(font)
	local scale = scale or 1
	local angle = angle or 0
	local pos = 0
	local align = align or CENTERMID
	local col1 = col1 or self.uiColor
	local col2 = col2 or self.uiShadowColor
	local check = check or false
	local smoothing = not nosmooth

	local str
	if (check) then
		str = textAdapt(input, font, scale, self.size.w, true, textfield, self.textfieldsingleline, self.textfieldindex)
	else
		str = self.str == input and self.dispstr or textAdapt(input, font, scale, self.size.w, nil, textfield, self.textfieldsingleline, self.textfieldindex)
		self.str, self.dispstr = input, str
	end

	local startLine = 1
	if (self.textfield and font_mod * 10 * scale * #str > self.size.h) then
		local tfstrlen = 0
		for i, v in pairs(str) do
			tfstrlen = tfstrlen + utf8.len(v)
			if (self.textfieldindex < tfstrlen) then
				startLine = i - math.floor(self.size.h / font_mod / 10 / scale) + 1
				if (startLine < 1) then
					startLine = 1
				end
				break
			end
		end
	end

	for i = startLine, #str do
		local xPos = x
		local yPos = y
		local strlen = get_string_length(str[i], font) * scale
		if ((align + 2) % 3 == 0) then
			xPos = x + (self.size.w - strlen) / 2
		elseif ((align + 1) % 3 == 0) then
			xPos = x + self.size.w - strlen
		end
		if (align >= 3 and align <= 5) then
			yPos = y + self.size.h - #str * font_mod * 10 * scale
			while (yPos < y and yPos + font_mod * 10 * scale < y + self.size.h) do
				yPos = yPos + font_mod * 10 * scale
			end
		elseif (align >= 6 and align <= 8) then
			yPos = y + (self.size.h - #str * font_mod * 10 * scale) / 2
			while (yPos < y and yPos + font_mod * 10 * scale < y + self.size.h) do
				yPos = yPos + font_mod * 5 * scale
			end
		end
		if (check == true and (self.size.w < strlen or self.size.h < font_mod * 10 * scale)) then
			return false
		elseif (self.size.h > (pos + 2) * font_mod * 10 * scale) then
			if (check == false) then
				draw_text_new(str[i], xPos, yPos + (pos * font_mod * 10 * scale), angle, scale, font, shadow, col1, col2, intensity, smoothing)
			elseif (#str == i) then
				return true
			end
			pos = pos + 1
		elseif (i ~= #str) then
			if (check == true) then
				return false
			end
			draw_text_new(str[i]:gsub(".$", "..."), xPos, yPos + (pos * font_mod * 10 * scale), angle, scale, font, shadow, col1, col2, intensity, smoothing)
			break
		else
			if (check == false) then
				draw_text_new(str[i], xPos, yPos + (pos * font_mod * 10 * scale), angle, scale, font, shadow, col1, col2, intensity, smoothing)
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
---@param pos ?Vector2
---@return Vector2
function UIElement:getLocalPos(xPos, yPos, pos)
	local xPos = xPos or MOUSE_X
	local yPos = yPos or MOUSE_Y
	---@type Vector2
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
	local default = default or DEFTEXTURE
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
		for i,v in pairs(TEXTURECACHE) do
			if (v == self.bgImage) then
				count = count + 1
				id = i
			end
		end
		if (count == 1) then
			unload_texture(self.bgImage)
			TEXTUREINDEX = TEXTUREINDEX - 1
		end
		table.remove(TEXTURECACHE, id)
		self.bgImage = nil
	end

	if (not image) then
		return
	end

	if (TEXTUREINDEX > 253) then
		self.bgImage = load_texture(DEFTEXTURE)
		return
	end
	if (not self.imageColor) then
		self.imageColor = { 1, 1, 1, 1 }
	end

	local tempicon = Files:open("../" .. filename)
	if (not tempicon.data) then
		local textureid = load_texture(default)
		self.bgImage = textureid
		TEXTUREINDEX = TEXTUREINDEX > textureid and TEXTUREINDEX or textureid
		table.insert(TEXTURECACHE, self.bgImage)
	else
		local textureid = load_texture(image)
		if (textureid == -1) then
			unload_texture(textureid)
			self.bgImage = load_texture(default)
		else
			self.bgImage = textureid
		end
		TEXTUREINDEX = TEXTUREINDEX > textureid and TEXTUREINDEX or textureid
		table.insert(TEXTURECACHE, self.bgImage)
		tempicon:close()
	end
end

CMD_ECHO_ENABLED = true
CMD_ECHO_DISABLED = false
CMD_ECHO_FORCE_DISABLED = -1

---@alias CmdEchoMode
---| true CMD_ECHO_ENABLED
---| false CMD_ECHO_DISABLED
---| -1 CMD_ECHO_FORCE_DISABLED

---Wrapper function for `run_cmd()` that automatically appends newline at the end of online commands
---@param command string
---@param online ?boolean
---@param echo ?CmdEchoMode
_G.runCmd = function(command, online, echo)
	local online = online and 1 or 0
	local silent = echo ~= CMD_ECHO_ENABLED

	if (echo == CMD_ECHO_FORCE_DISABLED) then
		add_hook("console", "runCmdIgnore", function() return 1 end)
	end
	run_cmd(command .. (online and "\n" or ""), online, silent)
	remove_hooks("runCmdIgnore")
end

---@deprecated
---Will be removed with future releases, use `runCmd()` instead \
---@see runCmd
function UIElement:runCmd(command, online, echo)
	runCmd(command, online, echo)
end

---@deprecated
---Will be removed with future releases, use print() instead \
---@see print
function UIElement:debugEcho(mixed, msg, returnString)
	return print(mixed, returnString)
end

---Runs a quicksort by specified key(s) on a table with multikey data
---@generic T
---@param list T Table with the data that we want to sort
---@param sort string[] Key or keys which values will be used for sorting
---@param order? sort Sorting order, defaults to `SORT_ASCENDING`
---@param includeZeros? boolean
---@overload fun(list: table, sort: string[], order?: boolean[], includeZeros?: boolean)
---@overload fun(list: table, sort: string, order?: boolean[], includeZeros?: boolean)
---@overload fun(list: table, sort: string, order?: sort, includeZeros?: boolean)
---@return T
function table.qsort(list, sort, order, includeZeros)
	local arr = {}

	if (type(order) ~= "table") then
		order = { order and 1 or -1 }
	else
		for i,v in pairs(order) do
			order[i] = v and 1 or -1
		end
	end

	for i, v in pairs(list) do
		table.insert(arr, v)
	end
	if (type(sort) ~= "table") then
		sort = { sort }
	end

	sort = table.reverse(sort)
	---@diagnostic disable-next-line: cast-local-type
	order = table.reverse(order)
	table.sort(arr, function(a,b)
			local cmpRes = false
			for i,v in pairs(sort) do
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
	local font_mod = hires and font - 10 or font
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
---@return string[]
_G.textAdapt = function(str, font, scale, maxWidth, check, textfield, singleLine, textfieldIndex)
	local clockdebug = TB_MENU_DEBUG and os.clock() or nil

	local destStr = {}
	local newStr = ""
	local word = ''
	-- Fix newlines, remove redundant spaces and ensure the string is in fact a string
	local str, _ = string.gsub(str, "\\n", "\n")
	str = str:gsub("^%s*", "")
	str = str:gsub("%s*$", "")

	local function getWord(checkstr)
		local newlined = checkstr:match("^.*\n")
		word = checkstr:match("^%s*%S+%s*")
		if (newlined) then
			if (utf8.len(newlined) < utf8.len(word)) then
				word = newlined
			end
		end
		return word
	end

	local function buildString(checkstr)
		if (textfield) then
			word = checkstr:match("^[^\n]*%S*[^\n]*\n") or checkstr:match("^%s*%S+%s*")
		else
			word = getWord(checkstr)
		end
		return word
	end

	if (textfield and singleLine) then
		local strlen = get_string_length(str, font) * scale
		local targetIndex = 1
		while (strlen > maxWidth) do
			local step = 2
			local len = utf8.len(str)
			local reverseStep = len
			if (strlen > maxWidth) then
				step = len - math.ceil(len / strlen * maxWidth)
				step = step > 1 and step or 2
			end
			while (targetIndex + step >= textfieldIndex) do
				step = step - 1
				reverseStep = reverseStep - 1
				if (step == 1) then
					break
				end
			end
			str = utf8.sub(str, step, reverseStep)
			strlen = get_string_length(str, font) * scale
		end
		return { str }
	end

	local newline = false
	local maxIterations = 1000
	while (str ~= "" and maxIterations > 0) do
		maxIterations = maxIterations - 1
		word = buildString(str)

		-- Wrap word around if it still exceeds text field width
		if (not check) then
			local _, words = word:gsub("%s", "")
			if (words == 0) then
				while (get_string_length(word:gsub("%s*$", ""), font) * scale > maxWidth) do
					word = utf8.sub(word, 1, utf8.len(word) - 1)
				end
			else
				while (words > 0 and get_string_length(word:gsub("%s*$", ""), font) * scale > maxWidth) do
					local pos = word:find("%s")
					if (pos == utf8.len(word)) then
						break
					end
					word = utf8.sub(word, 1, pos)
				end
				while (get_string_length(word:gsub("%s*$", ""), font) * scale > maxWidth) do
					word = utf8.sub(word, 1, utf8.len(word) - 1)
				end
			end
		end

		if ((get_string_length(newStr .. word, font) * scale > maxWidth or newline) and newStr ~= "") then
			table.insert(destStr, newStr)
			newStr = word
		else
			newStr = newStr .. word
		end
		str = utf8.sub(str, utf8.len(word) + 1)
		newline = word:match("\n") or word:match("\\n")
	end
	table.insert(destStr, newStr)

	if (TB_MENU_DEBUG) then
		local clockdebugend = os.clock()
		if (clockdebugend - clockdebug > 0.01) then
			echo("Warning: slow text adapt call on string " .. utf8.sub(destStr[1], 1, 10) .. " - " .. clockdebugend - clockdebug .. " seconds")
		end
	end

	return destStr
end

---Helper function to draw text with some additional functionality. \
---*You are probably looking for `UIElement:addAdaptedText()` or `UIElement:uiText()`.*
---@param str string
---@param xPos number
---@param yPos number
---@param angle number
---@param scale number
---@param font FontId
---@param shadow ?number Text shadow thickness
---@param color ?Color
---@param shadowColor ?Color
---@param intensity ?number
---@param pixelPerfect ?boolean Whether to floor the text position to make sure we don't start mid-pixel
_G.draw_text_new = function(str, xPos, yPos, angle, scale, font, shadow, color, shadowColor, intensity, pixelPerfect)
	local shadow = shadow or nil
	local xPos = pixelPerfect and math.floor(xPos) or xPos
	local yPos = pixelPerfect and math.floor(yPos) or yPos
	local col1 = color or DEFTEXTCOLOR
	local col2 = shadowColor or DEFSHADOWCOLOR
	local intensity = intensity or col1[4]
	if (shadow) then
		set_color(unpack(col2))
		draw_text_angle_scale(str, xPos - shadow, yPos, angle, scale, font)
		draw_text_angle_scale(str, xPos - shadow, yPos - shadow, angle, scale, font)
		draw_text_angle_scale(str, xPos - shadow, yPos + shadow, angle, scale, font)
		draw_text_angle_scale(str, xPos + shadow, yPos, angle, scale, font)
		draw_text_angle_scale(str, xPos + shadow, yPos - shadow, angle, scale, font)
		draw_text_angle_scale(str, xPos + shadow, yPos + shadow, angle, scale, font)
		draw_text_angle_scale(str, xPos, yPos - shadow, angle, scale, font)
		draw_text_angle_scale(str, xPos, yPos + shadow, angle, scale, font)
	end
	if (col1) then
		set_color(unpack(col1))
	end
	draw_text_angle_scale(str, xPos, yPos, angle, scale, font)
	if (font == 0 or font == 9) then
		set_color(col1[1], col1[2], col1[3], intensity)
		draw_text_angle_scale(str, xPos, yPos, angle, scale, font)
		if (font == 0 or font == 9) then
			draw_text_angle_scale(str, xPos, yPos, angle, scale, font)
		end
	end
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
	for i,v in pairs(haystack) do
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

---Returns a copy of a table with its contents reversed
---@generic T table|UIElement[]
---@param table T[]
---@return T[]
_G.table.reverse = function(table)
	local tblRev = {}
	for i, v in pairs(table) do
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
_G.table.compare = function(self, table2)
	if (self == nil or table2 == nil or type(self) ~= type(table2)) then
		return false
	end

	local cnt1, cnt2 = 0, 0
	for _ in pairs(self) do cnt1 = cnt1 + 1 end
	for _ in pairs(table2) do cnt2 = cnt2 + 1 end
	if (cnt1 ~= cnt2) then
		return false
	end

	for i,v in pairs(self) do
		if (v ~= table2[i]) then
			if (type(v) == type(table2[i]) and type(v) == "table") then
				if (not table.compare(self[i], table2[i])) then
					return false
				end
			else
				return false
			end
		end
	end

	return true
end

---Checks whether the table is empty
---@generic T
---@param table T[]
---@return boolean
_G.table.empty = function(table)
	if (next(table) == false) then
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
	for i,v in pairs(list) do
		table.insert(indexedTable, v)
	end
	return unpack(indexedTable)
end

---@deprecated
---Use `table.unpack_all()` instead \
---@see table.unpack_all
_G.unpack_all = function(tbl) return _G.table.unpack_all(tbl) end

---Internal function to output provided data as a string. \
---*You are likely looking for `print()`.*
---@param mixed any
---@param returnString? boolean
---@param msg? string String that will preceed the output
---@param rec? boolean Internal parameter to indicate recursive calls
---@return string|nil
_G.debugEchoInternal = function(mixed, returnString, msg, rec)
	local msg = msg and msg .. ": " or ""
	local buildRet = returnString and function(str) _G.DEBUGECHOMSG = _G.DEBUGECHOMSG .. str .. "\n" end or echo
	if (not rec) then
		_G.DEBUGECHOMSG = ""
	end
	if (type(mixed) == "table") then
		buildRet("entering table " .. msg)
		for i,v in pairs(mixed) do
			debugEchoInternal(v, returnString, msg .. i, true)
		end
	elseif (type(mixed) == "boolean") then
		buildRet(msg .. (mixed and "true" or "false"))
	elseif (type(mixed) == "number" or type(mixed) == "string") then
		buildRet(msg .. mixed)
	else
		buildRet(msg .. "[" .. type(mixed) .. "]")
	end
	if (returnString and not rec) then
		local msg = _G.DEBUGECHOMSG
		_G.DEBUGECHOMSG = nil
		return msg
	end
	return nil
end

---Outputs or returns any provided data as a string
---@param data any Data to parse and output
---@param returnString? boolean Whether we should return the generated string or use `echo()` to print it in chat
---@return string|nil
_G.print = function(data, returnString)
	return debugEchoInternal(data, returnString)
end

---@deprecated
---Use `print()` instead \
---@see print
_G.print_r = function(data, returnString)
	return print(data, returnString)
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

---Escapes all special characters in a specified string
---@param str string
---@return string
_G.string.escape = function(str)
	local str = str

	-- escape % symbols
	str = str:gsub("%%", "%%%%")

	-- escape other single special characters
	local chars = ".+-*?^$"
	for i = 1, #chars do
		local char = "%" .. chars:sub(i, i)
		str = str:gsub(char, "%" .. char)
	end

	-- escape paired special characters
	local paired = { {"%[", "%]"}, { "%(", "%)" } }
	for i,v in pairs(paired) do
		local count = 0
		for j, k in pairs(v) do
			if (str:find(k)) then
				count = count + 1
			end
		end
		if (count == 2) then
			for j, k in pairs(v) do
				str = str:gsub(k, "%" .. k)
			end
		end
	end
	return str
end

if (not UIElement.__mouseHooks) then
	UIElement.mouseHooks()
end
if (not UIElement.__keyboardHooks) then
	UIElement.keyboardHooks()
end
