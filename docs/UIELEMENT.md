# UIElement - 2D GUI Framework

Complete API documentation for the Toribash UI element system, a comprehensive 2D graphical user interface framework built on Lua.

**Version**: 5.76  
**File**: `script/toriui/uielement.lua`

## Table of Contents

1. [Overview](#overview)
2. [Enumerations & Constants](#enumerations--constants)
3. [Core Classes](#core-classes)
4. [Creating Elements](#creating-elements)
5. [Styling & Appearance](#styling--appearance)
6. [Event Handlers](#event-handlers)
7. [Text Rendering](#text-rendering)
8. [Scrollable Lists](#scrollable-lists)
9. [Element Lifecycle](#element-lifecycle)
10. [Utilities](#utilities)
11. [Advanced Topics](#advanced-topics)
12. [Common Patterns](#common-patterns)
13. [Version History](#version-history)

## Overview

## Overview

`UIElement` is the **primary tool for building user interfaces** in Toribash. It provides everything needed to create interactive UIs with rendering, event handling, and layout management.

### When to Use UIElement vs TBMenu

**Use UIElement directly** for the majority of your UI:
- Containers and panels
- Buttons with custom behavior
- Labels and text displays
- Image displays
- Layout structures
- Custom UI components
- Any simple interactive elements

**Use TBMenu helper methods** for complex interactive components:
- **Text input fields** → `TBMenu:spawnTextField2()` - handles keyboard input, cursor, selection
- **Sliders** → `TBMenu:spawnSlider2()` - drag interaction and value mapping
- **Dropdowns** → `TBMenu:spawnDropdown()` - expandable menus with selection
- **Toggles/Checkboxes** → `TBMenu:spawnToggle2()` - state management and styling
- **Draggable windows** → `TBMenu:spawnWindowOverlay()` - window management
- **Scrollable lists** → `TBMenu:prepareScrollableList()` - scroll bar setup

These complex components have existing implementations in TBMenu - there's no need to build them from scratch.

### What UIElement Provides

- **Rendering** - Backgrounds, images, rounded corners, gradients
- **Text display** - Font rendering with alignment and adaptive sizing
- **Event handling** - Mouse clicks, hover states, keyboard input
- **Hierarchy** - Parent-child relationships with relative positioning
- **Interactivity** - Hover/pressed/inactive color states
- **Custom drawing** - Frame-by-frame rendering callbacks
- **3D viewports** - Embedded 3D rendering contexts

---

## Enumerations & Constants

### Shape Types

```lua
SQUARE = 1      -- Rectangular elements with sharp corners
ROUNDED = 2     -- Elements with rounded corners
```

### Button States

Represents the interactive state of an element:

```lua
BTN_NONE = 0    -- Default/inactive state
BTN_HVR = 1     -- Mouse hovering over element
BTN_FOCUS = 2   -- Keyboard focus (rarely used)
BTN_DN = 3      -- Mouse button pressed down
```

### Text Alignment

Horizontal and vertical text positioning:

```lua
-- Horizontal alignment
LEFT = 0
CENTER = 1
RIGHT = 2

-- Vertical alignment combinations
LEFTBOT = 3         -- Bottom-left
CENTERBOT = 4       -- Bottom-center
RIGHTBOT = 5        -- Bottom-right
LEFTMID = 6         -- Middle-left
CENTERMID = 7       -- Middle-center
RIGHTMID = 8        -- Middle-right
```

### Scroll Modes

For scrollable lists:

```lua
SCROLL_VERTICAL = 1      -- Vertical scrolling (default)
SCROLL_HORIZONTAL = 2    -- Horizontal scrolling
```

### Font IDs

Standard fonts available in the engine:

```lua
0-2     -- Badaboom fonts (big, small, medium)
3       -- Bedrock medium
4       -- Arial Bold medium (used for RTL languages)
5-8     -- Kanji-supporting fonts (small/medium variants)
9       -- Badaboom giant
10-19   -- High-DPI variants (@2x)
```

### Color Constants

Pre-defined colors in RGBA format `{r, g, b, a}`:

```lua
UICOLORWHITE = { 1, 1, 1, 1 }
UICOLORBLACK = { 0, 0, 0, 1 }
UICOLORRED = { 1, 0, 0, 1 }
UICOLORGREEN = { 0, 1, 0, 1 }
UICOLORBLUE = { 0, 0, 1, 1 }
UICOLORTORI = { 0.58, 0, 0, 1 }     -- Toribash red

DEFTEXTCOLOR = { 1, 1, 1, 1 }        -- Default text color
DEFSHADOWCOLOR = { 0, 0, 0, 0.6 }    -- Default text shadow
```

### Sort Orders

For sorting elements in lists:

```lua
SORT_ASCENDING = false      -- Ascending order (A-Z, 0-9)
SORT_DESCENDING = true      -- Descending order (Z-A, 9-0)
```

---

## Core Classes

#### Vector2

```lua
local vec = Vector2.New(x, y)
```

**Fields:**
- `x: number` - X coordinate
- `y: number` - Y coordinate

**Methods:**
- `magnitude(): number` - Get vector length
- `normalize(): Vector2` - Return normalized vector (length = 1)
- `clampMagnitude(max): Vector2` - Clamp vector length to maximum
- `multiply(n): Vector2` - Scale vector by scalar
- `add(other): Vector2` - Add another vector

### Vector2Base

Pseudo-class representing a 2D vector. Created as a simple table.

**Important:** UIElement fields representing positions are typically `Vector2Base` tables instead of the full `Vector2` class objects.

```lua
-- These are all valid:
local pos = {100, 200}           -- Simple table
local size = {x = 300, y = 400}  -- Table with named fields that fits Vector2Base format
local vec = Vector2.New(50, 50)  -- Actual Vector2 object
```

### Rect

Pseudo-class representing a rectangle with position and size. Similar to `Vector2Base`, this is a simple table.

```lua
local rect = {
    x = 100,
    y = 200,
    w = 300,
    h = 400
}
```

---

## Creating Elements

### UIElement Constructor

Creates a new UI element with specified options.

```lua
local element = UIElement.new({
    globalid = 1000,
    pos = {100, 200},       -- Absolute position [x, y]
    size = {200, 100},      -- Element dimensions [width, height]
    bgColor = {1, 1, 1, 1}, -- Background color [r, g, b, a]
    interactive = true,     -- Enable mouse/keyboard interaction
    -- See common options below
})
```

**Note on `globalid`:** You typically don't need to specify a `globalid`. By default, all UIElements use `TB_MENU_HUB_GLOBALID` and are automatically rendered by the main menu system in `menu_main.lua`. Only specify a custom `globalid` if you're creating your own rendering loop with `UIElement.drawVisuals(globalid)` via the `draw2d` hook (and optionally viewport rendering via `draw_viewport` hook).
```

#### Common UIElementOptions

These are the options you'll typically use:

| Parameter | Type | Description |
|-----------|------|-------------|
| `globalid` | integer | Rendering context ID (rarely needed - defaults to `TB_MENU_HUB_GLOBALID`) |
| `parent` | UIElement | Parent element |
| `pos` | number[] | Position `[x, y]` (relative to parent or absolute for root elements) |
| `size` | number[] | Dimensions `[width, height]` |
| `shift` | number[] | Uniform padding values when used to create UIElements via `addChild()` |
| `interactive` | boolean | Enable mouse interaction |
| `bgColor` | Color | Background color `[r, g, b, a]` (default transparent) |
| `hoverColor` | Color | Color when mouse hovers (for interactive elements) |
| `pressedColor` | Color | Color when mouse button pressed |
| `inactiveColor` | Color | Color when element is disabled |
| `uiColor` | Color | Default text color for `addAdaptedText()` |
| `uiShadowColor` | Color | Text shadow color |
| `bgImage` | string\|string[] | Image path or `[main, fallback]` |
| `imageColor` | Color | Image tint multiplier (default `{1,1,1,1}`) |
| `imageHoverColor` | Color | Image tint on hover |
| `imagePressedColor` | Color | Image tint when pressed |
| `viewport` | boolean | Enable 3D rendering viewport |
| `shapeType` | UIElementShape | `SQUARE` (1) or `ROUNDED` (2) |
| `rounded` | number\|number[] | Corner radius (for ROUNDED shape) |
| `hoverSound` | SoundId | Sound ID to play on hover |
| `clickThrough` | boolean | Allow clicks to pass through element |
| `bgGradient` | Color[] | Generate gradient: `[color1, color2]` |

#### Advanced/Internal Options (Rarely Needed)

These options are used internally by TBMenu or for advanced custom components. **Most users should not use these directly**:

| Parameter | Description | Use Instead |
|-----------|-------------|-------------|
| `textfield`, `textfieldstr`, etc. | Text input internals | `TBMenu:spawnTextField2()` |
| `toggle` | Toggle/checkbox internals | `TBMenu:spawnToggle2()` |
| `scrollEnabled` | Scroll event handling | `TBMenu:prepareScrollableList()` |
| `imagePatterned`, `imageAtlas`, `atlas` | Texture rendering modes | Direct use for custom textures |
| `keyboard`, `permanentListener` | Keyboard event routing | Direct event handlers |
| `innerShadow`, `shadowColor` | UI styling internals | TBMenu styling |
| `disableUnload` | Texture memory management | Shared textures only |

**Important: UIElement Properties vs UIElementOptions**

UIElement properties do not always reflect the same information as UIElementOptions parameters:

- **`pos`**: In UIElementOptions, this is typically **relative to parent** (absolute only for root elements). You can use **negative values** to offset from parent's right/bottom edge:
  ```lua
  pos = {-5, -10}  -- Equivalent to {parent.size.w - 5, parent.size.h - 10}
  ```
  However, `UIElement.pos` is **always the absolute position** on screen.

- **`shift`**: In UIElementOptions (when using `addChild()`), this creates a **full-size child with padding**:
  ```lua
  shift = {10, 10}  -- Equivalent to pos = {10, 10}, size = {parent.size.w - 20, parent.size.h - 20}
  ```
  In the UIElement object itself, `shift` reflects the offset relative to the parent.

---

### addChild() - Create Child Element

```lua
local child = parent:addChild({
    pos = {10, 10},         -- Relative to parent
    size = {100, 50},
    bgColor = {0.5, 0.5, 0.5, 1}
})

-- Position from right/bottom edge
local cornerElement = parent:addChild({
    pos = {-110, -50},      -- 110px from right, 50px from bottom
    size = {100, 40}
})

-- Full-size child with padding using shift
local paddedChild = parent:addChild({
    shift = {10, 10},       -- 10px padding on all sides
    bgColor = {0.2, 0.2, 0.2, 1}
})

-- Copy parent's shape settings
local rounded = parent:addChild({
    shift = {10, 10}
}, true)  -- Copies shapeType and rounded from parent
```

Shorthand for creating a child element with automatic parent linking. This is essentially an equivalent of specifying `parent = parentElement` in UIElementOptions when creating a UIElement using new().

**Parameters:**
- `o: UIElementOptions` - Child configuration
- `copyShape?: boolean` - If `true`, copies parent's `shapeType` and `rounded` values to the child

**Returns:** `UIElement` - The created child element

---

## Styling & Appearance

**Note:** All styling options described here can be set via `UIElementOptions` during element creation. The methods below are primarily used when you need to dynamically modify UI styling at runtime.

### Colors and States

#### setRounded()

Sets corner rounding for `ROUNDED` shape type elements.

```lua
element:setRounded(15)          -- Uniform rounding
element:setRounded({10, 20})    -- Top, bottom rounding
```

**Note:** To change colors at runtime, directly modify the element's color properties.  
Please keep in mind that Lua table assignments are done by reference.

```lua
element.bgColor = { 1, 0, 0, 1 }        -- Set new background color
element.hoverColor[1] = 0.5             -- Modify hover color's red value
element.imageColor = UICOLORWHITE       -- Change image tint to a **reference** of default white (unsafe)
```

### Images and Textures

#### updateImage()

Load and display an image texture.

```lua
element:updateImage("../textures/menu/buttons/play.tga")

-- With fallback texture
element:updateImage("../textures/custom.tga", "../textures/default.tga")
```

**Parameters:**
- `path: string` - Image file path
- `fallback?: string` - Fallback path if main texture missing

#### updateImageGradient()

Create a gradient background based on player character meshes.

```lua
element:updateImageGradient(color1, color2, bodypartId)
```

### Visibility

#### show()

Display the element and all its children.

```lua
element:show()              -- Normal show
element:show(true)          -- Force show even if noreload flag was set
```

**Parameters:**
- `forceReload?: boolean` - If `true`, overrides the `noreload` flag set by previous `hide()` calls

#### hide()

Hide the element and all its children (remains in memory).

```lua
element:hide()              -- Normal hide
element:hide(true)          -- Hide and prevent subsequent show() calls
```

**Parameters:**
- `noreload?: boolean` - If `true`, element will ignore subsequent `show()` calls unless `forceReload` is used

#### isDisplayed()

Check if element is currently visible.

```lua
if element:isDisplayed() then
    -- Element is visible
end
```

#### reload()

Toggle element visibility (hides then shows). This will place the element on top of its immediate parent's render tree.

```lua
element:reload()
```

---

## Event Handlers

### Mouse Handlers

Elements can respond to mouse input through callback functions.

#### addMouseHandlers()

Register multiple mouse event callbacks at once.

```lua
element:addMouseHandlers(
    function(buttonId, x, y)    -- btnDown - Mouse button pressed
    end,
    function(buttonId, x, y)    -- btnUp - Mouse button released
    end,
    function(x, y)              -- btnHover - Mouse moved over element
    end,
    function(buttonId, x, y)    -- btnRightUp - Right mouse button released
    end,
    function(buttonId, x, y)    -- btnUpOutside - Released outside element
    end
)
```

#### Shorthand Methods

```lua
element:addMouseDownHandler(function(buttonId, x, y) end)
element:addMouseUpHandler(function(buttonId, x, y) end)
element:addMouseMoveHandler(function(x, y) end)
element:addMouseUpRightHandler(function(buttonId, x, y) end)
element:addMouseUpOutsideHandler(function(buttonId, x, y) end)
```

### Keyboard Handlers

#### addKeyboardHandlers()

```lua
element:addKeyboardHandlers(
    function(key)  -- keyDown - Key pressed (keycode)
    end,
    function(key)  -- keyUp - Key released
    end
)
```

#### addEnterAction()

Trigger when Enter/Return key is pressed.

```lua
element:addEnterAction(function()
    print("Enter pressed!")
end)

-- Remove callback
element:removeEnterAction()
```

#### addTabAction()

Trigger when Tab key is pressed.

```lua
element:addTabAction(function()
    print("Tab pressed!")
end)

-- Remove callback
element:removeTabAction()
```

#### addInputCallback()

For text fields - called when text input changes.

```lua
element:addInputCallback(function()
    print("Text changed to: " .. element.textfieldstr[1])
end)
```

### Focus Management

#### addTabSwitch()

Switch to another element when Tab is pressed.

```lua
element:addTabSwitch(nextInputElement)

-- Remove tab switch behavior
element:removeTabSwitch()
```

#### addTabSwitchPrev()

Switch to another element when Shift+Tab is pressed.

```lua
element:addTabSwitchPrev(previousInputElement)

-- Remove reverse tab switch
element:removeTabSwitchPrev()
```

#### addOnReceiveTabFocus()

Called when element receives keyboard focus via Tab.

```lua
element:addOnReceiveTabFocus(function()
    print("Element focused!")
end)

-- Remove callback
element:removeOnReceiveTabFocus()
```

#### addOnLoseTabFocus()

Called when element loses keyboard focus.

```lua
element:addOnLoseTabFocus(function()
    print("Element lost focus!")
end)

-- Remove callback
element:removeOnLoseTabFocus()
```

---

## Text Rendering

### addAdaptedText()

Render text that automatically sizes to fit the element. Preferred for most text display needs.

**Primary overload (recommended):**

```lua
element:addAdaptedText("Hello World!", {
    font = FONTS.MEDIUM,         -- Font ID (default: FONTS.MEDIUM)
    align = CENTER,              -- Alignment (default: LEFT)
    maxscale = 1.0,              -- Maximum text scale (default: 1.0)
    minscale = 0.2,              -- Minimum text scale (default: 0.2)
    color = {1, 1, 1, 1},        -- Text color (default: element.uiColor)
    shadow = 1,                  -- Shadow offset (default: 0)
    shadowColor = {0, 0, 0, 1},  -- Shadow color
    shadowIntensity = 1,         -- Shadow opacity
    padding = {x = 5, y = 5, w = 5, h = 5}, -- Padding (can also be number or {x, y})
    intensity = 1,               -- Text opacity (0-1)
    isTextfield = false,         -- Internal: text field mode
    baselineScale = 1            -- Baseline font size multiplier
}, override)  -- override: replace existing text
```

**Legacy overload (all parameters):**

```lua
element:addAdaptedText(
    override,          -- boolean: replace existing text
    "Hello World!",    -- string: text content
    x, y,              -- number/table: padding (single value or {x, y} or {x, y, w, h})
    fontId,            -- FontId: font to use
    alignment,         -- UIElementTextAlign: text alignment
    maxscale,          -- number: max scale
    minscale,          -- number: min scale
    intensity,         -- number: text opacity
    shadow,            -- number: shadow offset
    col1, col2,        -- Color: text color, shadow color
    textfield,         -- boolean: internal textfield mode
    baselineScale      -- number: baseline multiplier
)
```

### uiText()

Manual text rendering with full control. **Use this only for dynamic strings that change frequently at runtime** - for static or infrequent text, `addAdaptedText()` is preferred.

```lua
element:uiText(
    "Custom Text",     -- string: text to render
    x, y,              -- number/table: position or padding
    font,              -- FontId: font to use
    align,             -- UIElementTextAlign: alignment
    scale,             -- number: text scale
    angle,             -- number: rotation angle
    shadow,            -- number: shadow offset
    col1, col2,        -- Color: text color, shadow color
    intensity,         -- number: text opacity
    check,             -- boolean: check if text fits (returns boolean)
    baselineScale,     -- number: baseline multiplier
    nosmooth,          -- boolean: disable text smoothing
    textfield,         -- boolean: internal textfield mode
    shadowIntensity    -- number: shadow opacity
)
```

### Text Properties (Read-Only)

- `str: string` - Current text string
- `dispstr: string[]` - Text split into lines
- `strindices: integer[]` - Length of each line (for text fields)
- `textFont: integer` - Current font ID
- `textScale: number` - Current text scale
- `textAlign: integer` - Current alignment

### Text Field Operations

**Important:** For creating text input fields, use `TBMenu:spawnTextField2()`. See [Menu Manager - spawnTextField2()](MENU_MANAGER.md#spawntextfield2).

**Reading text field content:**

```lua
-- Safe: read current text
local text = element.textfieldstr[1]
```

**Modifying text field state (advanced - use with caution):**

```lua
-- WARNING: Manual modifications are risky and should only be done
-- if you absolutely know what you're doing.
-- In most scenarios, this is not needed.

element.textfieldstr[1] = "New text"  -- Set text programmatically
element.textfieldindex = 5            -- Set cursor position (0-indexed)
```

---

## Scrollable Lists

### How Scrollable Lists Work

UIElement doesn't support clipping/cutout areas, so scrollable lists are "faked" by moving list elements relative to their container. Understanding the parameters is important:

- **`listHolder`**: Container that holds all list items. Gets moved to simulate scrolling.
- **`listElements`**: Array of UI elements in the list. **Must all have the same height (vertical) or width (horizontal)**.
- **`toReload`**: Holder element that contains borders that will be rendered on top of the list area. Borders must be **at least the same size as list elements** to prevent items from "popping in/out" at the edges.
- **`posShift`**: Table (usually `{0}`) that tracks scroll position. Use a persistent table if you'd like to retain scroll state across reloads, otherwise this argument can be omitted.
- **`scrollIgnoreOverride`**: Set to `true` **only** when the list needs to be interactive while a `TBMenu:spawnWindowOverlay()` is active.

### makeScrollBar()

Converts an element into a scroll bar that controls a scrollable list. 

**For typical use cases, use [`TBMenu:prepareScrollableList()`](MENU_MANAGER.md#preparescrollablelist)** which handles the setup.

```lua
scrollBar:makeScrollBar(
    listHolder,          -- UIElement: container for list items
    listElements,        -- UIElement[]: array of list items (must have uniform size)
    toReload,            -- UIElement: border/overlay element (prevents pop-in/out)
    posShift,            -- number[]: table to track scroll position (e.g., {0})
    scrollSpeed,         -- number?: scroll speed multiplier (default: 1)
    scrollIgnoreOverride,-- boolean?: interact with active overlay (default: false)
    orientation          -- UIElementScrollMode?: SCROLL_VERTICAL or SCROLL_HORIZONTAL
)
```

### makeHorizontalScrollBar()

Shorthand for horizontal scrolling. Same parameters as `makeScrollBar()` except orientation is set to `SCROLL_HORIZONTAL`.

```lua
scrollBar:makeHorizontalScrollBar(
    listHolder,          -- UIElement: container for list items  
    listElements,        -- UIElement[]: array of list items
    toReload,            -- UIElement: border/overlay element
    posShift,            -- number[]: scroll position tracker
    scrollSpeed,         -- number?: scroll speed multiplier
    scrollIgnoreOverride -- boolean?: interact with active overlay
)
```

**Example usage:** See [Menu Manager - prepareScrollableList()](MENU_MANAGER.md#preparescrollablelist) for a practical implementation example.

---

## Element Lifecycle

### Moving and Sizing

#### moveTo()

Change element position.

```lua
element:moveTo(x, y)              -- Move to absolute position
element:moveTo(x, y, true)        -- Relative shift from current position
```

**Parameters:**
- `x, y: number` - New position coordinates
- `relative?: boolean` - If `true`, treats x/y as relative offset; if `false` or omitted, absolute position

#### Resizing Elements

There is no `resize()` method. To resize an element, directly modify its `size` property:

```lua
element.size.w = 300  -- Change width
element.size.h = 200  -- Change height
```

#### updatePos()

Recalculate absolute position for element and all children. **Generally redundant** - position is automatically marked as dirty when using `moveTo()` and batch-recalculated before the next render loop. Only use this to force instant position updates.

```lua
element:updatePos()  -- Force position recalculation
```

### Destruction

#### kill()

Destroy element, its children, and remove from rendering/input loops.

```lua
element:kill()          -- Destroy element and all children
element:kill(true)      -- Destroy only children, keep element
```

**Parameters:**
- `childOnly?: boolean` - If `true`, destroys only children but keeps the element itself

#### Checking if Destroyed

**Important:** `element == nil` is **NOT** a sufficient way to check if an element has been destroyed, as Lua references likely still exist.

The correct way:

```lua
if element == nil or element.destroyed then
    -- Element has been destroyed
end
```

#### killAction Callback

Execute code when element is destroyed.

```lua
element.killAction = function()
    print("Element was destroyed!")
end
```

### Display Callback

#### onShow Callback

Execute code when element is displayed.

```lua
element.onShow = function()
    print("Element is now visible!")
    -- Refresh data, update text, etc.
end
```

---

## Utilities

### Custom Rendering & Frame Updates

#### addCustomDisplay()

**The primary way to specify custom behavior that executes every render loop.** This doesn't have to contain rendering logic - it can be any frame-by-frame logic you want to run while the element exists, without creating a new `draw2d` hook.

**Only one custom rendering function per slot** (early/late update) can be attached to a UIElement at a time. Calling `addCustomDisplay()` again replaces the existing callback.

```lua
-- Basic usage: add late-render callback
element:addCustomDisplay(function()
    -- Custom drawing or logic here
    -- Runs every frame after default rendering
end)

-- Override default rendering entirely
element:addCustomDisplay(true, function()
    -- This REPLACES default rendering
    -- Element's bgColor, bgImage, etc. will not be drawn
end)

-- Early-render callback (before default rendering)
element:addCustomDisplay(function()
    -- Runs every frame
end, true)  -- true = draw before default

-- Full signature
element:addCustomDisplay(overrideDefault, renderFunc, drawBefore)
```

**Parameters:**
- `overrideDefault: boolean|function` - If `boolean`: whether to replace default rendering. If `function`: treated as `renderFunc` with defaults.
- `renderFunc: function` - The callback to execute each frame
- `drawBefore?: boolean` - If `true`, executes before default rendering; otherwise after

**Example - Custom drawing:**

```lua
element:addCustomDisplay(function()
    set_color(1, 0, 0, 1)
    draw_quad(element.pos.x, element.pos.y, element.size.w, element.size.h)
end)
```

**Example - Frame-by-frame logic without rendering:**

```lua
local rotation = 0
element:addCustomDisplay(function()
    rotation = rotation + 1
    if rotation >= 360 then
        rotation = 0
    end
    -- Update child elements, animate values, etc.
end)
```

### Display Callback

#### onShow Callback

Execute code when element is displayed.

```lua
element.onShow = function()
    print("Element is now visible!")
    -- Refresh data, update text, etc.
end
```

### Table Utilities

Including UIElement extends Lua's `table` library with helper functions:

```lua
local copy = table.clone(originalTable)       -- Deep copy
local reversed = table.reverse(myTable)       -- Returns reversed copy
local isEmpty = table.empty(myTable)          -- Check if table is empty (returns boolean)
local sorted = table.qsort(myTable, sortField, order)        -- Returns copy of table sorted by field(s) with order control
local v1, v2, v3 = table.unpack_all(myTable)  -- Unpack string-keyed tables (loses key order)
```

### String Utilities

In a similar fashion to `table` extensions, UIElement provides several extensions to `string` and `utf8` libraries:

```lua
local escaped = string.escape(str)           -- Escape special characters
local safe_upper = utf8.safe_upper(str)      -- UTF-8 safe uppercase
local safe_lower = utf8.safe_lower(str)      -- UTF-8 safe lowercase
local safe_sub = utf8.safe_sub(str, i, j)    -- UTF-8 safe substring
```

**Note:** As Toribash uses Lua 5.1, we rely on an external implementation of UTF-8 support which does not always handle malformed strings exactly the same way as the built-in `string` library does, and would sometimes throw errors instead of silently returning. Safe versions of `utf8` functions wrap the calls into `pcall()` to mimic the standard behavior and fall back to equivalent functions from the `string` library on errors.

### Debugging & Output

**Note:** `print()` is **not** the default Lua `print()` - it's essentially a `echo()` wrapper. If you'd like to actually print messages to stderr / log files, refer to `Files` class available in `script/system/iofiles.lua`.

```lua
print(value)                    -- Output to chat via echo()
print(value, true)              -- Return as string instead

print_r(value)                  -- Recursive table print
print_r(value, true)            -- Return recursive output as string

print_json(data)                -- Output data as JSON
```

### Global Utilities

```lua
-- Generate unique IDs
local id = generate_uid()
```

### Window Information

UIElement provides **cached global variables** for resolution and safe areas:

```lua
-- Cached window dimensions (updated automatically by UIElement)
local width = WIN_W    -- Window width
local height = WIN_H   -- Window height

-- Safe area insets (for devices with notches/cutouts)
local insetX = SAFE_X  -- Horizontal safe inset
local insetY = SAFE_Y  -- Vertical safe inset
```

These are more efficient than calling `get_window_size()` repeatedly.

### State Checking

```lua
-- Check if element is displayed
if element:isDisplayed() then
    -- Element is currently visible
end

-- Check if element is active (not deactivated)
if element:isActive() then
    -- Element can receive interactions
end

-- Check hover/press state
element.hoverState  -- Current state: BTN_NONE, BTN_HVR, BTN_DN
```

---

## Advanced Topics

### Performance Considerations

- **Light UI Mode**: UIElement automatically adapts to graphics settings selected by the user. When enabled, the framework dynamically limits functionality (button color transitions, rounded corners for non-circular elements, etc.) to optimize performance.
- **Delta Time**: `UIElement.deltaClock` tracks time since last frame for animations
- **Caching**: Most text rendered via `addAdaptedText()` and `uiText()` is cached for performance. UIElement also dynamically maintains the lifecycle of all loaded textures to optimize memory usage.

### Global Managers (Internal)

These are typically managed internally but available for inspection:

```lua
UIElementManager          -- All root elements
UIVisualManager          -- Elements grouped by render context
UIMouseHandler           -- Interactive elements
UIKeyboardHandler        -- Elements with keyboard input
UIScrollbarHandler       -- Scroll bars and scrollable lists
```

---

## Common Patterns

### Creating a Simple Button

```lua
local button = parent:addChild({
    pos = {10, 10},
    size = {100, 40},
    bgColor = {0.2, 0.2, 0.8, 1},
    hoverColor = {0.3, 0.3, 1, 1},
    pressedColor = {0.1, 0.1, 0.6, 1},
    interactive = true,
    shapeType = ROUNDED,
    rounded = 5
})

button:addAdaptedText("Click Me")

button:addMouseHandlers(nil, function()
    print("Button clicked!")
end)
```

### Creating a Panel with Text

```lua
local panel = parent:addChild({
    pos = {50, 50},
    size = {300, 200},
    bgColor = {0.1, 0.1, 0.1, 0.9},
    shapeType = ROUNDED,
    rounded = 10
})

panel:addAdaptedText("Panel Title", {
    font = FONTS.BIG,
    align = CENTER,
    shift = {x = 0, y = 10}
})
```

### Image Display

```lua
local imageElement = parent:addChild({
    pos = {100, 100},
    size = {256, 256},
    bgImage = "../textures/menu/logo.tga"
})
```

### Proper UI Lifecycle Management

**Important:** Any UI created with UIElement must have an exit point that completely destroys all elements. You may choose one of these approaches:

#### Approach 1: Global Variable + On/Off cycling

```lua
-- test.lua
-- Test if root element exists
if myTestUI then
    -- Destroy it and exit
    myTestUI:kill()
    myTestUI = nil
    return
end

-- Create new root element if it doesn't exist
myTestUI = UIElement:new({
    pos = {100, 100},
    size = {400, 300},
    bgColor = {0, 0, 0, 0.8}
})

-- Add content...

-- To load or unload the script, repeatedly execute /ls test.lua
```

This is a similar logic to what `system/menu_main.lua` uses - menu script is loaded every time ESC key is pressed.

#### Approach 2: ARG-based Destruction (Recommended for test scripts)

```lua
-- test.lua
-- Always destroy the pre-existing root element
if myTestUI then
	myTestUI:kill()
	myTestUI = nil
end
-- Check the argument passed to the script
if ARG == 'exit' then
    return
end

-- Create new root element
myTestUI = UIElement:new({
    pos = {100, 100},
    size = {400, 300},
    bgColor = {0, 0, 0, 0.8}
})

-- Add content...

-- To destroy: /ls test.lua exit
```

#### Approach 3: Explicit Close Button (Required for local variables)

```lua
-- Local variable approach requires explicit cleanup
local function createMyUI()
    local root = UIElement:new({
        pos = {0, 0},
        size = {WIN_W, WIN_H}
    })
    
    -- MUST have a way to destroy the UI
    local closeButton = root:addChild({
        pos = {-110, 10},
        size = {100, 40},
        bgColor = {0.8, 0.2, 0.2, 1},
        interactive = true
    })
    closeButton:addAdaptedText("Close")
    closeButton:addMouseHandlers(nil, function()
        root:kill()
    end)
    
    return root
end

local myUI = createMyUI()
```

### Complex Interactive Components

For complex components like text inputs, dropdowns, sliders, and toggles, use the TBMenu helper methods:

```lua
-- Text input fields
local textField = TBMenu:spawnTextField2(...)  -- See MENU_MANAGER.md

-- Sliders
local slider = TBMenu:spawnSlider2(...)

-- Dropdowns
local dropdown = TBMenu:spawnDropdown(...)

-- Toggles/Checkboxes  
local toggle = TBMenu:spawnToggle2(...)

-- Scrollable lists
local scrollBar, listHolder = TBMenu:prepareScrollableList(...)
```

See [Menu Manager Documentation](MENU_MANAGER.md) for details on these methods.

---

## Version History

**5.76** - Latest
- Horizontal mouse scroll support for horizontal scrollable lists

**5.74**
- `table.equals()` for table comparison
- `UIElement.deltaClock` for frame time tracking
- Text field max length support

**5.71**
- Performance improvements with local function references

**5.70**
- Cached `get_world_state()` results
- Optimized color rendering

**5.65**
- Added `onShow` callback
- Error handling for callbacks with `pcall()`

**5.62**
- `bgImageDefault` flag for tracking fallback textures

---

## See Also

- [UIElement3D Documentation](UIELEMENT3D.md) - 3D rendering capabilities
- [Menu Manager Documentation](MENU_MANAGER.md) - High-level UI orchestration
- [Main README](../README.md) - Repository overview
