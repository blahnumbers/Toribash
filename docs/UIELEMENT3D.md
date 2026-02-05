# UIElement3D - 3D Rendering Framework

Complete API documentation for 3D elements in Toribash, extending the UIElement system to render 3D objects, viewports, and effects.

**Version**: 5.72  
**File**: `script/toriui/uielement3d.lua`  
**Dependencies**: `script/toriui/uielement.lua`

## Table of Contents

1. [Overview](#overview)
2. [Enumerations & Constants](#enumerations--constants)
3. [Core Classes](#core-classes)
4. [Creating 3D Elements](#creating-3d-elements)
5. [Transforms & Positioning](#transforms--positioning)
6. [Rendering Effects](#rendering-effects)
7. [Model Management](#model-management)
8. [Viewport Rendering](#viewport-rendering)
9. [Player Attachment](#player-attachment)
10. [Advanced Topics](#advanced-topics)
11. [Common Patterns](#common-patterns)
12. [Version History](#version-history)

## Overview

`UIElement3D` extends `UIElement` to provide 3D rendering capabilities for in-world game objects and UI viewports. 

**Primary use cases:**
- Render 3D objects in the game world
- Display 3D objects in UI viewports
- Attach visual elements to player bodyparts/joints

**Key features:**
- Shape primitives (cubes, spheres, capsules) and custom OBJ models
- Full 3D transformations with Euler angles and rotation matrices
- Visual effects system (glow, dithering, voronoi, color shift)
- Automatic model caching and resource management
- Player attachment system

**Note**: UIElement3D objects are render-only and do not have colliders or physics. To add interactive 3D objects to the world, create custom mods with Toribash modmaker.

---

## Enumerations & Constants

### 3D Shape Types

Shape primitives available for rendering:

```lua
CUBE = 1          -- Rectangular box/cube
SPHERE = 2        -- Spherical shape
CAPSULE = 3       -- Cylinder with hemispherical ends
CUSTOMOBJ = 4     -- Load custom OBJ model file
VIEWPORT = 5      -- Off-screen render target
```

### Euler Rotation Conventions

How Euler angles are interpreted for rotations:

```lua
EULER_XYZ = 'XYZ'   -- Rotate around X, then Y, then Z
EULER_ZYX = 'ZYX'   -- Rotate around Z, then Y, then X
```

### Render Effects

Visual effects applied during rendering:

```lua
-- Available effects include:
-- - Glow/bloom effects
-- - Dithering
-- - Voronoi/ripple effects
-- - Color shifting
```

---

## Core Classes

### UIElement3D

Main class for 3D rendering elements. Extends `UIElement`.

```lua
local obj = UIElement3D.new(options)  -- See Creating 3D Elements section for full options
```

**Key properties:**
- Inherits all UIElement fields (see [UIElement Documentation](UIELEMENT.md))
- `pos: Vector3Base` - Absolute world position
- `shift: Vector3Base` - Position relative to parent
- `size: Vector3Base` - Object scale
- `rotMatrix: number[][]` - 3x3 rotation matrix
- `rotXYZ: EulerRotation` - Euler angles representation
- `shapeType: UIElement3DShape` - Shape primitive type
- `objModel: integer` - Model ID for CUSTOMOBJ shapes (managed internally)
- `playerAttach: integer` - Attached player ID (nil if not attached)

**Key methods:**
- `addChild(options): UIElement3D` - Create child 3D element
- `moveTo(x, y, z, absolute)` - Move element (relative by default)
- `rotate(x, y, z)` - Apply Euler rotation
- `resetRotation()` - Reset to identity rotation
- `syncPlayer()` / `syncPlayerPosition()` / `syncPlayerRotation()` - Sync with attached bodypart
- `addCustomDisplay(func, displayBefore)` - Add custom rendering callback
- `addOnEnterFrame(func)` - Add logic callback for enter_frame hook
- `kill(childOnly)` - Destroy element
- `show(forceReload)` / `hide(noreload)` - Toggle visibility

**Static methods:**
- `UIElement3D.drawVisuals(globalid)` - Render regular 3D elements (draw3d/post_draw3d hooks)
- `UIElement3D.drawViewport(globalid)` - Render viewport elements (draw_viewport hook)
- `UIElement3D.drawEnterFrame(globalid)` - Execute enter_frame callbacks (enter_frame hook)

### Vector3

Full 3D vector class with utility methods.

```lua
local vec = Vector3.New(x, y, z)
```

**Fields:**
- `x: number` - X coordinate
- `y: number` - Y coordinate
- `z: number` - Z coordinate

**Methods:**
- `magnitude(): number` - Get vector length
- `normalize(): Vector3` - Return normalized vector (length = 1)
- `add(other): Vector3` - Add vectors
- `cross(other): Vector3` - Cross product
- `multiply(n): Vector3` - Scale by scalar
- `clampMagnitude(max): Vector3` - Clamp vector length

### Vector3Base

Pseudo-class representing a 3D vector. Created as a simple table.

**Important:** UIElement3D fields representing positions are typically `Vector3Base` tables instead of full `Vector3` class objects.

```lua
-- These are all valid for Vector3Base parameters:
local pos = {0, 0, 0}              -- Array format
local pos = {x = 0, y = 0, z = 0}  -- Table with named fields
local vec = Vector3.New(0, 0, 0)   -- Actual Vector3 object (also valid)
```

### EulerRotation

Class for Euler angle rotations with conversion utilities.

```lua
local rot = EulerRotation.New(pitch, yaw, roll, convention)
local rot = EulerRotation.NewRadian(x, y, z, convention)  -- From radians
```

**Fields:**
- `x: number` - Pitch (rotation around X axis) in degrees
- `y: number` - Yaw (rotation around Y axis) in degrees
- `z: number` - Roll (rotation around Z axis) in degrees
- `convention: EulerRotationConvention` - Rotation order (EULER_XYZ or EULER_ZYX)

**Methods:**
- `toMatrix(): number[][]` - Convert to rotation matrix
- `toMatrixTB(): MatrixTB, number[][]` - Convert to Toribash and standard matrices

### Utils3D

Utility class for 3D math operations.

**Matrix Conversion:**
- `MatrixToMatrixTB(matrix): MatrixTB` - Convert rotation matrix to Toribash format
- `MatrixTBToMatrix(matrixTB): number[][]` - Convert Toribash matrix to standard format

**Rotation Utilities:**
- `GetEulerFromMatrix(matrix, convention): EulerRotation` - Extract Euler angles from matrix
- `GetEulerFromMatrixTB(matrixTB): EulerRotation` - Extract Euler angles from TB matrix
- `GetMatrixFromEuler(x, y, z, convention): number[][]` - Create rotation matrix from Euler angles (radians)

**Matrix Operations:**
- `MatrixMultiply(a, b): number[][]` - Multiply matrices or matrix by scalar
- `MatrixIdentity(): number[][]` - Returns 3x3 identity matrix
- `MatrixInverse(matrix): number[][]` - Returns inverse (transpose) of matrix

---

## Creating 3D Elements

### UIElement3DOptions

All parameters available when creating a UIElement3D object with `UIElement3D.new(options)`.

**Inherits all UIElement options** - See [UIElement Documentation](UIELEMENT.md) for inherited parameters (bgColor, bgImage, interactive, etc.)

**3D-Specific Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pos` | number[] | Yes | Position as array `[x, y, z]`. **Absolute** if no parent, **relative to parent** if has parent |
| `size` | number[] | Yes | Size as array `[sx, sy, sz]` |
| `shapeType` | UIElement3DShape | No | Shape type: CUBE, SPHERE, CAPSULE, CUSTOMOBJ, VIEWPORT (default: CUBE) |
| `rot` | number[] | No | Euler angles `[pitch, yaw, roll]` in degrees |
| `eulerConvention` | EulerRotationConvention | No | Rotation order: EULER_XYZ or EULER_ZYX (default: EULER_XYZ) |
| `objModel` | string | Conditional | OBJ model path (required for CUSTOMOBJ shapeType) |
| `parent` | UIElement3D\|UIElement | No | Parent element for hierarchy |
| `globalid` | integer | No | Global ID for rendering context (inherits from parent if not set, default: 1000) |
| `viewport` | boolean | No | Set to `true` for viewport rendering mode. See [Viewport Rendering](#viewport-rendering) |
| `playerAttach` | integer | No | Player ID (0-based) to attach this element to |
| `attachBodypart` | integer | Conditional | Bodypart ID (0-20) for attachment. See BODYPARTS enum in system_defines.lua |
| `attachJoint` | integer | Conditional | Joint ID (0-19) for attachment. Mutually exclusive with attachBodypart. See JOINTS enum |
| `ignoreDepth` | boolean | No | Skip depth buffer writes (useful for transparent/overlay objects) |
| `disableUnload` | boolean | No | Prevent automatic texture/model unloading |
| `effects` | table | No | Rendering effects configuration. See [effects table structure](#effects-table) |

**Important notes:**
- `pos`, `size`, and `rot` must be **arrays** (not tables with named keys)
- When `viewport = true`, element will be rendered in viewport mode (requires proper setup, see Viewport Rendering section)
- `attachBodypart` and `attachJoint` are mutually exclusive - use one or the other, not both

#### Effects Table

```lua
effects = {
    id = EFFECT_TYPE.FRESNEL,     -- Effect ID bitmask (see EFFECT_TYPE enum)
    glowColor = COLORS.WHITE,     -- ColorId for glow effect
    glowIntensity = 10,           -- Glow concentration at the edges
    ditherPixelSize = 4,          -- Dither pixel size
    voronoiColor = COLORS.BLUE,   -- ColorId for ripple effect
    voronoiScale = 1.0,           -- Ripple scale
    voronoiFresnel = true,        -- Use fresnel for ripple
    shiftColor = COLORS.RED,      -- ColorId for color shift
    shiftScale = 1.0,             -- Color shift intensity
    shiftPeriod = 1.0             -- Color shift animation speed
}
```

**All effect properties are optional**. Effects are enabled via the `id` field (effectid bitmask).

### Basic Examples

#### Simple 3D Object

```lua
-- Root element (absolute positioning)
local element = UIElement3D.new({
    pos = {0, 0, 0},
    size = {1, 1, 1},
    shapeType = SPHERE,
    bgColor = {1, 0, 0, 1}  -- Red sphere
})
```

#### Child Element

```lua
-- Child element (position relative to parent)
local child = UIElement3D.new({
    parent = element,
    pos = {2, 0, 0},        -- 2 units to the right of parent
    size = {0.5, 0.5, 0.5},
    shapeType = CUBE,
    bgColor = UICOLORBLACK
})

-- Or use addChild shortcut
local child2 = element:addChild({
    pos = {0, 2, 0},
    size = {0.5, 0.5, 0.5},
    shapeType = CUBE,
    bgColor = UICOLORBLACK
})
```

#### Custom Model

```lua
local model = UIElement3D.new({
    pos = {0, 0, 0},
    size = {1, 1, 1},
    shapeType = CUSTOMOBJ,
    objModel = "../models/sword.obj",
    rot = {0, 45, 0}  -- Rotated 45 degrees around Y axis
})
```

#### With Effects

```lua
local glowing = UIElement3D.new({
    pos = {0, 0, 0},
    size = {1, 1, 1},
    shapeType = SPHERE,
    effects = {
        id = EFFECT_TYPE.FRESNEL,
        glowColor = COLORS.AQUA,
        glowIntensity = 20
    }
})
```

---

## Transforms & Positioning

### Position Management

#### moveTo()

Move the element in 3D space.

**Unlike UIElement's moveTo()**, this moves **relatively** by default. Set `absolute` to `true` for absolute positioning.

```lua
-- Move relatively (default) - adds to current position
element:moveTo(1, 0, -2)

-- Move to absolute position
element:moveTo(5, 3, -10, true)

-- Partial updates (nil values are ignored)
element:moveTo(nil, 2, nil)  -- Only moves Y axis
```

**Parameters:**
- `x: number?` - X movement/position (nil to skip)
- `y: number?` - Y movement/position (nil to skip)
- `z: number?` - Z movement/position (nil to skip)
- `absolute: boolean?` - If true, sets absolute position; if false/nil, moves relatively

**Note**: Does nothing if element has `playerAttach` set.

### Rotation

#### rotate()

Apply rotation by Euler angles (in degrees).

```lua
-- Rotate by individual angles (degrees)
element:rotate(pitch, yaw, roll)

-- Or pass EulerRotation object
local rotation = EulerRotation.New(45, 90, 0, EULER_XYZ)
element:rotate(rotation)
```

**Note**: Calling with all angles as 0 will be ignored (no-op). Rotation is applied relative to the element's current rotation.

#### resetRotation()

Resets object's rotation to identity matrix.

```lua
element:resetRotation()
```

#### Get Current Rotation

```lua
-- As Euler angles
local pitch, yaw, roll = element.rotXYZ.x, element.rotXYZ.y, element.rotXYZ.z

-- As matrix
local matrix = element.rotMatrix
local tbMatrix = element.rotMatrixTB
```

### Scaling

Set scale by directly modifying the `size` property:

```lua
-- Modify element width and depth, keep the same height
element.size.x = 1.0
element.size.y = 1.5
```

---

## Rendering Effects

Rendering effects are controlled by the **`effectid`** property, which is a bitmask value that determines which effects are active. Effect IDs are defined in the `EFFECT_TYPE` enum in `script/system/system_defines.lua`.

### Effect Types (EFFECT_TYPE)

Available effect types that can be combined with bitwise OR:

```lua
EFFECT_TYPE.NONE = 0           -- No effects
EFFECT_TYPE.CELSHADED = 1      -- Toon shading
EFFECT_TYPE.FRESNEL = 2        -- Glow/fresnel effect
EFFECT_TYPE.DITHERING = 4      -- Dithering effect
EFFECT_TYPE.VORONOI = 8        -- Ripples/voronoi effect
EFFECT_TYPE.COLORSHIFT = 16    -- Color shift effect
```

**Combine multiple effects using bitwise OR:**

```lua
element.effectid = EFFECT_TYPE.FRESNEL + EFFECT_TYPE.DITHERING  -- Glow + dithering
```

### Enabling Effects

**Primary control:** Set `effectid` to enable effects. Without a non-zero `effectid`, effect properties have no effect.

```lua
-- Enable glow effect
element.effectid = EFFECT_TYPE.FRESNEL
element.glowColor = COLORS.AQUA
element.glowIntensity = 0.8

-- Disable all effects
element.effectid = 0
```

### Glow/Fresnel Effect

Controlled by `EFFECT_TYPE.FRESNEL`.

```lua
element.effectid = EFFECT_TYPE.FRESNEL
element.glowColor = COLORS.WHITE       -- ColorId (see COLORS enum in system_defines.lua)
element.glowIntensity = 30             -- Glow concentration at edges
```

### Dithering Effect

Controlled by `EFFECT_TYPE.DITHERING`.

```lua
element.effectid = EFFECT_TYPE.DITHERING
element.ditherPixelSize = 4            -- Pixel size (larger = more visible dither)
```

### Voronoi (Ripple) Effect

Controlled by `EFFECT_TYPE.VORONOI`.

```lua
element.effectid = EFFECT_TYPE.VORONOI
element.voronoiColor = COLORS.BLUE     -- ColorId for ripple color
element.voronoiScale = 1.0             -- Ripple amplitude/scale
element.voronoiFresnel = true          -- Apply fresnel mask to ripples
```

### Color Shift Effect

Controlled by `EFFECT_TYPE.COLORSHIFT`.

```lua
element.effectid = EFFECT_TYPE.COLORSHIFT
element.shiftColor = COLORS.RED        -- ColorId for color shift
element.shiftScale = 1.0               -- Shift intensity
element.shiftPeriod = 1.0              -- Animation speed multiplier
```

### Combined Effects Example

```lua
-- Combine glow and ripples
local obj = UIElement3D.new({
    pos = {0, 0, 0},
    size = {1, 1, 1},
    shapeType = SPHERE,
	bgColor = UICOLORWHITE,
    effects = {
        id = EFFECT_TYPE.FRESNEL + EFFECT_TYPE.VORONOI,
        glowColor = COLORS.GOLD,
        glowIntensity = 20,
        voronoiColor = COLORS.AQUA,
        voronoiScale = 1.2,
        voronoiFresnel = true
    }
})
```

### Color IDs

Effect colors use the `COLORS` enum from `script/system/system_defines.lua`. Common values:

```lua
COLORS.WHITE, COLORS.BLACK, COLORS.RED, COLORS.BLUE, COLORS.GREEN
COLORS.YELLOW, COLORS.PURPLE, COLORS.ORANGE, COLORS.PINK
COLORS.GOLD, COLORS.AQUA, COLORS.MARINE, COLORS.TOXIC
-- ... and many more (see system_defines.lua for full list)
```

---

## Model Management

### Loading Custom Models

Custom OBJ model files can be loaded and rendered:

```lua
local customObj = UIElement3D.new({
    ...
    shapeType = CUSTOMOBJ,
    objModel = "../models/sword.obj"
})
```

### Model Cache

UIElement3D automatically caches loaded models. Each model is automatically unloaded from memory when all UIElement3D instances using it are destroyed.

---

## Viewport Rendering

Viewports enable rendering 3D scenes into 2D UI elements, allowing you to display 3D content in the interface (e.g., character previews, miniature scenes).

### Viewport Architecture

A viewport setup requires three components:

1. **2D Viewport Container** - A regular UIElement with `viewport = true`
2. **3D Viewport Root** - A UIElement3D with `shapeType = VIEWPORT` and `viewport = true`, attached to the container
3. **3D Content** - UIElement3D objects with `viewport = true`, created as children of the root or with explicit `viewport = true`

### Setting Up a Viewport

```lua
-- 1. Create the 2D container
local viewportContainer = UIElement.new({
    pos = {100, 100},
    size = {512, 512},
    viewport = true              -- Mark as viewport container
})

-- 2. Create the 3D viewport root element
local viewportRoot = UIElement3D.new({
    parent = viewportContainer,
    shapeType = VIEWPORT,         -- Special viewport shape
    viewport = true,              -- Enable viewport mode
    pos = {0, 0, 0},
    size = {0, 0, 0}
})

-- 3. Add 3D objects as children
local obj = viewportRoot:addChild({
    pos = {0, 0, -2},             -- Position in viewport space
    size = {1, 1, 1},
    shapeType = SPHERE,
    bgColor = UICOLORRED
})
-- viewport = true is automatically inherited from parent

-- Or create with explicit viewport flag
local obj2 = UIElement3D.new({
    parent = viewportRoot,
    viewport = true,              -- Explicitly mark for viewport rendering
    pos = {2, 0, -2},
    size = {1, 1, 1},
    shapeType = CUBE,
	bgColor = UICOLORBLUE
})
```

### Key Properties

**viewport (in UIElement3DOptions)**
- When `true`, marks the element for viewport rendering mode
- Automatically inherited by children created via `addChild()`
- Sets the internal `viewportElement` property to `true`

**viewport (UIElement3D property)**
- For `shapeType = VIEWPORT` elements, this stores a reference to the 2D viewport container (UIElement)
- For other elements, this is not used

**viewportElement (UIElement3D property)**
- Internal flag set to `true` when element is in viewport mode
- Determines which render loop the element uses

### Rendering Custom Viewports

Viewport elements with custom globalid must be rendered in the `draw_viewport` hook:

```lua
add_hook("draw_viewport", "myViewportHook", function()
    UIElement3D.drawViewport(2000)  -- Render viewport elements with globalid 2000
end)
```

**Note**: When using the default globalid managed by `main_menu.lua` (TB_MENU_HUB_GLOBALID), you don't need to manually spawn hooks - the main menu handles this automatically.

---

## Player Attachment

UIElement3D objects can be attached to player bodyparts or joints to automatically handle position / rotation changes.

### Basic Attachment

```lua
-- Attach to bodypart
element.playerAttach = 0                 -- Player ID (0-based)
element.attachBodypart = BODYPARTS.HEAD  -- Use BODYPARTS enum

-- OR attach to joint (mutually exclusive with attachBodypart)
element.playerAttach = 0
element.attachJoint = JOINTS.R_SHOULDER  -- Use JOINTS enum
```

**Important:**
- When attached to a **bodypart**, the element's position is **relative to the bodypart center**
- When attached to a **joint**, the element is positioned **at the joint location**
- For joints with sphere shapes, radius is automatically scaled by joint radius
- **moveTo() does nothing** on attached elements
- Attachment works automatically without needing to call sync methods for basic rendering

### When to Use Sync Methods

The `syncPlayer*()` methods are **only necessary** for root elements (no parent) when you need to:
- Update child element transforms based on bodypart movement
- Access accurate transform data in custom logic/calculations
- Manually control sync timing instead of relying on automatic attachment

**For simple attachment and rendering, just setting `playerAttach` and `attachBodypart`/`attachJoint` is sufficient.**

```lua
-- Sync all transforms
element:syncPlayer()

-- Sync only rotation (useful when position is managed separately)
element:syncPlayerRotation(updateChildPosition)  -- updateChildPosition defaults to true

-- Sync only position
element:syncPlayerPosition()
```

**Note**: These methods only work on elements **without a parent** that have `playerAttach` and `attachBodypart` set.

### BODYPARTS Enum

Use the `BODYPARTS` enum (defined in `script/system/system_defines.lua`) for bodypart references:

```lua
BODYPARTS.HEAD           -- 0
BODYPARTS.BREAST         -- 1
BODYPARTS.CHEST          -- 2
BODYPARTS.STOMACH        -- 3
BODYPARTS.GROIN          -- 4
BODYPARTS.R_PECS         -- 5
BODYPARTS.R_BICEPS       -- 6
BODYPARTS.R_TRICEPS      -- 7
BODYPARTS.L_PECS         -- 8
BODYPARTS.L_BICEPS       -- 9
BODYPARTS.L_TRICEPS      -- 10
BODYPARTS.R_HAND         -- 11
BODYPARTS.L_HAND         -- 12
BODYPARTS.R_BUTT         -- 13
BODYPARTS.L_BUTT         -- 14
BODYPARTS.R_THIGH        -- 15
BODYPARTS.L_THIGH        -- 16
BODYPARTS.L_LEG          -- 17 (shin)
BODYPARTS.R_LEG          -- 18 (shin)
BODYPARTS.R_FOOT         -- 19
BODYPARTS.L_FOOT         -- 20
```

### JOINTS Enum

Use the `JOINTS` enum for joint references:

```lua
JOINTS.NECK              -- 0
JOINTS.CHEST             -- 1
JOINTS.LUMBAR            -- 2
JOINTS.ABS               -- 3
JOINTS.R_PECS            -- 4
JOINTS.R_SHOULDER        -- 5
JOINTS.R_ELBOW           -- 6
JOINTS.L_PECS            -- 7
JOINTS.L_SHOULDER        -- 8
JOINTS.L_ELBOW           -- 9
JOINTS.R_WRIST           -- 10
JOINTS.L_WRIST           -- 11
JOINTS.R_GLUTE           -- 12
JOINTS.L_GLUTE           -- 13
JOINTS.R_HIP             -- 14
JOINTS.L_HIP             -- 15
JOINTS.R_KNEE            -- 16
JOINTS.L_KNEE            -- 17
JOINTS.R_ANKLE           -- 18
JOINTS.L_ANKLE           -- 19
```

### Examples

```lua
-- Simulate gold glow effect on player's head
local headGlow = UIElement3D.new({
    pos = {0, 0, 0},
    size = {get_body_info(0, 0).sides.x, 1, 1},
    shapeType = SPHERE,
    bgColor = {1, 1, 1, 0.01},          -- Color must not be fully transparent for default rendering to work
    playerAttach = 0,
    attachBodypart = BODYPARTS.HEAD,
    effects = {
        id = EFFECT_TYPE.FRESNEL,
        glowColor = COLORS.GOLD,
        glowIntensity = 20
    }
})

-- Indicator at joint position
local jointMarker = UIElement3D.new({
    pos = {0, 0, 0},
    size = {1, 1, 1},
    shapeType = SPHERE,
    playerAttach = 0,
    attachJoint = JOINTS.R_SHOULDER,
    bgColor = {1, 0, 0, 1}
})
```

---

## Advanced Topics

### Custom Rendering

UIElement3D supports custom rendering callbacks similar to UIElement.

#### addCustomDisplay()

This method is inherited from UIElement and allows specifying custom logic to be executed during the rendering loop:

```lua
-- Add custom display callback
element:addCustomDisplay(function()
    -- Custom drawing code
    -- Called after base element rendering logic
end)

-- Run before default rendering
element:addCustomDisplay(function()
    -- Pre-rendering logic
end, true)  -- true = run before default display
```

**When to use:**
- Custom drawing logic
- Modifying element properties before/after rendering
- Implementing custom animations or effects

#### addOnEnterFrame()

Allows adding custom logic that will be executed after the game physics step:

```lua
element:addOnEnterFrame(function()
    -- Logic executed on enter_frame
    -- Called from UIElement3D.drawEnterFrame() loop
end)
```

**When to use:**
- Game logic that needs to run after physics steps
- Calculations based on game state
- Non-rendering updates

**Note**: For rendering updates, use `addCustomDisplay()` instead.

---

## Common Patterns

The most common use of UIElement3D is for rendering visual-only 3D objects in the game world, such as atmospheric effects and environmental elements.

### Basic Setup

```lua
-- Create root holder (typically done once)
local holder = UIElement3D.new({
    pos = {0, 0, 0},
    size = {0, 0, 0}
})

-- Add environmental object
local cloud = holder:addChild({
    pos = {10, 5, 20},
    size = {3, 2, 0.5},
    shapeType = CUBE,
    bgColor = {1, 1, 1, 0.6}
})
```

### Advanced Setup

Based on automatic object generation with random values from `script/system/atmospheres_manager.lua`:

```lua
-- Root holder for all atmosphere elements
local EntityHolder = UIElement3D.new({
    pos = {0, 0, 0},
    size = {0, 0, 0}
})

-- Spawn multiple similar objects with randomization
for i = 1, 10 do
    local obj = EntityHolder:addChild({
        pos = {
            math.random(-20, 20),
            math.random(-20, 20),
            math.random(0, 5)
        },
        size = {
            math.random(5, 15) / 10,
            math.random(5, 15) / 10,
            math.random(5, 15) / 10
        },
        rot = {
            math.random(0, 360),
            math.random(0, 360),
            math.random(0, 360)
        },
        shapeType = CUBE,
        bgColor = {1, 1, 1, 0.7}
    })
    
    -- Add custom animation
    obj:addCustomDisplay(function()
        obj:rotate(0, 0.5, 0)  -- Slowly rotate
    end)
end
```

### Loading Custom Models

```lua
-- Load Jack-o-Lantern model and attach it to player's head
local jackLantern = holder:addChild({
    pos = {0, 0, 0},
    size = {1, 1, 1},
    shapeType = CUSTOMOBJ,
    objModel = "../mod_assets/spooky/jack_lantern",
    playerAttach = 0,
    attachBody = BODYPARTS.HEAD
})

-- Models are automatically cached and unloaded when the element is destroyed
```

---

## Version History

**5.72** - Latest
- Voronoi and color shift effects support

**5.71**
- Performance improvements with local function references

**5.66**
- Added `absolute` argument support to `moveTo()`
- Support for passing `EulerRotation` objects to `rotate()`

**5.63**
- `ignoreDepth` support for object rendering

**5.62**
- Set GL_REPEAT texture wrapping mode by default

---

## See Also

- [UIElement Documentation](UIELEMENT.md) - 2D UI framework (base class)
- [Menu Manager Documentation](MENU_MANAGER.md) - UI orchestration
- [Main README](../README.md) - Repository overview
