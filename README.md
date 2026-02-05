# Toribash Data Directory

This directory contains all configuration, asset, and script data for Toribash - the most hardcore fighting game you've ever played.

## Overview

The `data/` folder is the backbone of Toribash's content system, containing:
- **Game scripts** - Lua-based gameplay logic, menu systems, and UI framework
- **Visual assets** - Textures, models, shaders, and atmosphere configurations
- **Audio assets** - Music, ambient sounds, and sound effects
- **Configuration files** - Game settings, language definitions, and player data
- **Modding framework** - Custom mods (`.tbm`) and mod assets

## Directory Structure

### Core Directories

#### `script/`
Lua scripting system for Toribash gameplay and UI.

- **`script/toriui/`** - Modern UI framework (`UIElement` class and utilities)
  - `uielement.lua` - Main 2D GUI element system
  - `uielement3d.lua` - 3D rendering elements
  - `uitween.lua` - Animation/tween system
  - `json.lua` - JSON parsing utilities
  - `unicode.lua`, `utf8.lua` - Text encoding support

- **`script/system/`** - Core game systems and managers
  - `menu_main.lua` - Entry point for Toribash's main menu
  - `menu_manager.lua` - Main menu UI manager class
  - `playerinfo_manager.lua` - Player info data manager
  - `settings_manager.lua` - Game settings and preferences manager
  - Manager classes for game subsystems:
    - `atmospheres_manager.lua` - Shader and atmospheres / 3D environment management
    - `mods_manager.lua` - Mod browser manager
    - `replays_manager.lua` - Replay browser and viewer manager
	- `store_manager.lua` - Store and item info manager
    - `market_manager.lua` - In-game market system manager
    - `clans_manager.lua` - Clans system manager
    - `tutorial_manager.lua` - Tutorials system framework
    - `events_online_manager.lua` - In-game events framework, based on Tutorials system
    - `roomlist_manager.lua` - Room list / browser manager
    - *And more...*
  - Defines and settings:
    - `system_defines.lua` - Global constants, Toribash API functions, and enumerations
    - `menu_defines.lua` - Menu system constants
    - `settings_defines.lua` - Settings configuration
    - `atmospheres_defines.lua` - Environment presets

#### `atmospheres/`
Pre-configured 3D environments and lighting settings.

- `.atmo` files - Atmosphere configuration (.tbm-like format)
- `.lua` files - Custom script customizations for the environment
- Examples: Dark Forest, Desert, Japan, Underwater, Winter, Volcano, etc.

#### `textures/`
Texture assets used by game UI.

#### `models/`
3D model data used by the in-game Store.

#### `shader/`
`.inc` files that customize lighting and game visuals using the exposed settings.

#### `sounds/`
Default audio files used for the character effects and game UI.

#### `music/`
Background music tracks.

#### `mod/`
Community-created and official mods (`.tbm` files).

Includes:
- Combat modifications (aikido, boxing, judo, etc.)
- Custom environments and stages
- Game variant mods (bowling, climbing, etc.)

#### `mod_assets/`
Shared resources and assets used by mods.

#### `language/` and `script/system/language`
Localization files for supported languages.

#### `tutorials/`
In-game tutorial data files.

#### `fonts/`
Font files for text rendering.

## Key Components

### UIElement System

The modern UI framework built around the `UIElement` class provides:
- 2D interactive elements
- Mouse and keyboard event handling
- Animations with color transitions and sound effects for interations
- Text rendering with multiple fonts and alignment options
- Scrollable lists with customizable scroll bars

**Documentation**: See [docs/UIELEMENT.md](docs/UIELEMENT.md)

### UIElement3D System

`UIElement3D` class extends UIElement with 3D capabilities:
- 3D rendering in game world
- 3D viewport rendering in UI
- Shape primitives (cubes, spheres, capsules)
- Custom model rendering
- Effects system (glow, dithering, voronoi)
- Player attachment points

**Documentation**: See [docs/UIELEMENT3D.md](docs/UIELEMENT3D.md)

### Menu System

`TBMenu` class orchestrates the core UI and includes methods to generate uniform UI elements, including interactive text fields, draggable windows, scrollable lists and more.

**Documentation**: See [docs/MENU_MANAGER.md](docs/MENU_MANAGER.md)

## Quick Links

- **[UIElement Documentation](docs/UIELEMENT.md)** - Complete API reference for 2D UI elements
- **[UIElement3D Documentation](docs/UIELEMENT3D.md)** - 3D rendering and viewport system
- **[Menu Manager Documentation](docs/MENU_MANAGER.md)** - Main menu system and UI orchestration
- **[System Classes Documentation](docs/SYSTEM_CLASSES.md)** - Core game system managers

## Development Notes

### Script Requirements

Most Lua scripts in `script/` require Toribash game runtime (custom Lua environment with game APIs).
Toribash uses Lua version 5.1 for compatibility reasons, so keep this in mind when using default Lua functionality.

### Common Global APIs

Toribash exposes a lot of custom functionality to Lua. You can see the definitions for all globally available API functions in [system_defines.lua](script/system/system_defines.lua).

### Color Format

Colors are typically represented as `{r, g, b, a}` arrays with values in range `0-1`.

Common color constants:
```lua
UICOLORWHITE = { 1, 1, 1, 1 }
UICOLORBLACK = { 0, 0, 0, 1 }
UICOLORRED = { 1, 0, 0, 1 }
```

### Text Alignment Enumerations

- `LEFT` (0), `CENTER` (1), `RIGHT` (2) - Horizontal alignment
- `LEFTBOT` (3), `CENTERBOT` (4), `RIGHTBOT` (5) - Bottom alignment
- `LEFTMID` (6), `CENTERMID` (7), `RIGHTMID` (8) - Middle alignment

### Font IDs

- `0-2` - Badaboom fonts (big, small, medium)
- `3` - Bedrock medium
- `4` - Arial Bold medium
- `5-8` - Kanji-supporting fonts
- `9` - Badaboom giant
- `10-19` - High-DPI variants (@2x)

**Last Updated**: February 3rd, 2026  
**Data Version**: Toribash 5.76+
