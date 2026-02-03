# Toribash Documentation Index

Complete documentation guide for the Toribash game data system, scripts, and UI framework.

## Quick Start

New to Toribash development? Start here:

1. **[Main README](../README.md)** - Overview of the data directory structure
2. **[UIElement Quick Guide](#uielement-quick-start)** - Building UI elements
3. **[Menu Manager Quick Guide](#menu-manager-quick-start)** - Displaying screens

## Documentation Files

### Core UI Framework

#### [UIElement](UIELEMENT.md) - 2D GUI System
**Complete API for building interactive 2D interfaces**

- Creating elements (buttons, panels, text fields)
- Styling (colors, images, rounded corners)
- Event handling (mouse, keyboard, input)
- Text rendering with multiple fonts
- Scrollable lists and containers
- Advanced features (animations, custom drawing)

**Best for:** Building UI screens, forms, menus, HUDs

**Key Classes:**
- `UIElement` - Base 2D element
- `Vector2` - 2D positioning
- `UITween` - Animation utilities

---

#### [UIElement3D](UIELEMENT3D.md) - 3D Rendering System
**Complete API for 3D objects, viewports, and effects**

- Creating 3D objects (cube, sphere, capsule, custom models)
- Viewport rendering in UI
- Transforms and rotations (Euler angles, matrices)
- Visual effects (glow, dithering, color shifts)
- Attaching objects to player character parts

**Best for:** Character viewers, model displays, 3D scene composition

**Key Classes:**
- `UIElement3D` - 3D element with rendering
- `Vector3` - 3D positioning
- `EulerRotation` - Euler angle rotations
- `Utils3D` - Matrix math utilities

---

### High-Level UI Systems

#### [Menu Manager](MENU_MANAGER.md) - Main Menu Orchestration
**API for displaying screens, managing navigation, building UI components**

- Opening menu screens (home, play, market, settings, etc.)
- Creating navigation bars and section views
- Creating generic UI components (text fields, dropdowns, sliders, toggles)
- Displaying dialogs and popups
- Managing user profile bar and notifications
- Pagination and scrollable lists

**Best for:** Building complete menu systems, orchestrating screens

**Key Class:**
- `TBMenu` - Main menu manager

---

#### [System Classes & Managers](SYSTEM_CLASSES.md) - Core Game Systems
**Reference for 40+ manager classes handling various game systems**

Organized by category:

**Core systems:**
- `PlayerInfo` - Player core information + customs (active inventory) data
- `Files` - Platform-agnostic abstraction for reading and writing file data
- `Request` - Networking class to allow simplified data retrieval from Toribash servers
- `Store` - Core store and item info manager

**Content & Assets:**
- `Atmospheres` - 3D environment and shader manager
- `Mods` - Mod loading and management
- `Replays` - Replay management
- `Scripts` - User script management
- `MoveMemory` - Move Memory tool management
- `News` - In-game news and announcements manager

**Social:**
- `Friends` - Friend lists and blocking
- `ChatIgnore` - Chat filtering system
- `Clans` - Clans system
- `Notifications` - Notifications / private messaging system
- `Broadcasts` - In-game broadcast system

**Market & Economy:**
- `Market` - Player market manager class
- `Bounty` - Bounty system
- `Rewards` - Login bonuses and rewards

**Other game systems:**
- `Gamerules` - Game rules (fight settings) manager
- `Ranking` - Ranking system
- `Quests` - Quests system
- `Events` - Static events manager class (Blind Fight, mod championships)
- `BattlePass` - Battle Pass system
- `Tutorials` - In-game tutorials framework
- `EventsOnline` - Limited events framework, based on Tutorials class
- `TBHud` - Base HUD class for mobile platforms

**Configuration:**
- System defines, menu defines, settings
- Default configurations and constants

---

## Quick References

### UIElement Quick Start

Create and display a simple button:

```lua
-- Create root container
-- All UIElements are spawned visible by default
local menu = UIElement.new({
    pos = {100, 100},
    size = {400, 150},
    bgColor = TB_MENU_DEFAULT_BLUE,
    shapeType = ROUNDED,
    rounded = 5
})

-- Add button child
-- Child elements will retain rounded settings of their parent when created with `copyShape = true`
local button = menu:addChild({
    pos = {50, 50},
    size = {300, 50},
    bgColor = TB_MENU_DEFAULT_BG_COLOR,
    hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
    interactive = true
}, true)

-- Add cached button text
button:addAdaptedText("Click Me!")

-- Add click handler
button:addMouseUpHandler(function()
    print("Button clicked!")
end)

-- Add generic close button that destroys the root container on click
TBMenu:spawnCloseButton(menu, { x = -40, y = 0, w = 40, h = 40 }, function() menu:kill() end)
```

### UIElement3D Quick Start

Display a rotating 3D cube:

```lua
-- Create a 3D object
local cube = UIElement3D.new({
    pos = {0, 0, 2},
    size = {1, 1, 1},
    rot = {45, 45, 0},
    shapeType = CUBE,
    bgColor = UICOLORBLACK
})

-- Animate its rotation
cube:addCustomDisplay(function()
    cube:rotate(1, 0.2, 0)
end)
```

---

## Common Tasks

### How do I...

#### Display a Text Input Field?
See: [UIElement > Text Rendering](UIELEMENT.md#text-rendering) or  
[Menu Manager > spawnTextField()](MENU_MANAGER.md#spawntext-field)

#### Create a Scrollable List?
See: [UIElement > Scrollable Lists](UIELEMENT.md#scrollable-lists) or  
[Menu Manager > prepareScrollableList()](MENU_MANAGER.md#scrollable-lists)

#### Show a Confirmation Dialog?
See: [Menu Manager > Dialogs & Popups](MENU_MANAGER.md#dialogs--popups)

#### Get Player Information?
See: [System Classes > Player & Account Systems](SYSTEM_CLASSES.md#player--account-systems)

#### Display a 3D Model?
See: [UIElement3D > Creating 3D Elements](UIELEMENT3D.md#creating-3d-elements)

#### Load and Display a Custom Mod?
See: [System Classes > mods_manager.lua](SYSTEM_CLASSES.md#mods_manager-lua)

#### Add Visual Effects to UI?
See: [UIElement > Styling & Appearance](UIELEMENT.md#styling--appearance)

#### Handle User Input?
See: [UIElement > Event Handlers](UIELEMENT.md#event-handlers)

---

## Getting Help

1. **Check the relevant documentation file** - Each system has detailed API docs
2. **Review common patterns** - Each doc has code examples
3. **Look at system defines** - `*_defines.lua` files contain constants
4. **Study implementations** - View actual usage in `menu_main.lua`, etc.
5. **Use LuaLS annotations** - Code has type hints for IDE support

---

## Contributing Documentation

To improve these docs:

1. Review source code in `script/`
2. Extract API signatures and descriptions
3. Add usage examples
4. Update relevant documentation file
5. Test examples for accuracy

---

## See Also

- [Main README](../README.md) - Repository overview
- [Toribash Website](https://www.toribash.com) - Official game site
- [Toribash Lua Discussion](https://forum.toribash.com/forumdisplay.php?f=65) - Lua Scripts board on Toribash forums
