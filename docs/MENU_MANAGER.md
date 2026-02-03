# TBMenu - Main Menu System

Complete API documentation for Toribash's main menu orchestration system, managing all UI navigation, screens, and user interactions.

**Version**: 5.76
**File**: `script/system/menu_manager.lua`

## Table of Contents

1. [Overview](#overview)
2. [Core Structure](#core-structure)
3. [Initialization](#initialization)
4. [Main Navigation](#main-navigation)
5. [Screen Management](#screen-management)
6. [UI Components](#ui-components)
7. [Dialogs & Popups](#dialogs--popups)
8. [Data Display](#data-display)
9. [User Avatar & Bar](#user-avatar--bar)
10. [Advanced Features](#advanced-features)

## Overview

`TBMenu` is the primary manager for Toribash's entire UI system. It handles:

- **Main menu navigation** - Screen transitions and layout management
- **Section displays** - Game, market, settings, replays, clans, etc.
- **User interface** - Top bar, user profile, notifications
- **Popups & dialogs** - Confirmation windows, messages, loading screens
- **UI components** - Dropdowns, sliders, toggles, text fields
- **Data visualization** - Lists, rankings, events, store items

### Global Element Holders

`TBMenu` maintains references to major UI elements:

```lua
TBMenu.MenuMain           -- Root menu element
TBMenu.UserBar            -- Top-right user info bar
TBMenu.CurrentSection     -- Currently displayed section
TBMenu.NavigationBar      -- Side/bottom navigation
TBMenu.BottomLeftBar      -- Bottom-left UI container
TBMenu.BottomRightBar     -- Bottom-right UI container
TBMenu.StatusMessage      -- Status/notification display
TBMenu.NotificationsCount -- Notification badge
TBMenu.Popups             -- List of active popups
```

---

## Core Structure

### TBMenu Class Fields

| Field | Type | Description |
|-------|------|-------------|
| `ver` | number | Version number (5.76) |
| `CurrentAnnouncementId` | integer | Currently displayed announcement |
| `CurrentSection` | UIElement | Currently visible content section |
| `MenuMain` | UIElement | Root menu element |
| `UserBar` | UIElement | User profile bar (top-right) |
| `NavigationBar` | UIElement | Navigation controls |
| `BottomLeftBar` | UIElement | Bottom-left panel |
| `BottomRightBar` | UIElement | Bottom-right panel |
| `StatusMessage` | TBMenuStatusMessage | Status text display |
| `NotificationsCount` | UIElement | Notification badge count |
| `HasCustomNavigation` | boolean | Whether custom nav is loaded |
| `Popups` | UIElement[] | List of active popup windows |
| `UserPaymentHistory` | UserPaymentHistory | Cached payment data |
| `UserAccountInfo` | RequestPromise | Cached account info |
| `AccountInfoStalePeriod` | integer | Cache validity in seconds (300) |

### Constants & Styles

Theme colors and styling used throughout the menu:

```lua
TB_MENU_DEFAULT_BG_COLOR         -- Primary background color
TB_MENU_DEFAULT_DARKER_COLOR     -- Darker background
TB_MENU_DEFAULT_DARKEST_COLOR    -- Darkest background
TB_MENU_DEFAULT_BG_COLOR_TRANS   -- Transparent variant
TB_MENU_DEFAULT_INACTIVE_COLOR   -- Disabled element color
TB_MENU_DEFAULT_ORANGE           -- Accent orange color
TB_MENU_LOCALIZED                -- Translated UI strings
```

---

## Initialization

### Init()

Initialize the menu system (called on game startup).

```lua
TBMenu.Init(buildVersion)
```

**Parameters:**
- `buildVersion: integer` - Game build version number

**Effects:**
- Flags main menu opened
- Initializes and caches localization data
- Sets game version build override

### GetTranslation()

Load language/localization strings. Any missing strings will fall back to English versions.

```lua
TBMenu.GetTranslation(language)
```

**Parameters:**
- `language: string` - Language name that matches data files in language/ and script/system/language folders

**Supported Languages:**
- `english`
- `deutsch`
- `french`
- `spanish`
- `portuguese (Portugal)`
- `portuguese (Brazil)`
- `russian`
- `indonesian`
- `polski`
- `arabic` - RTL
- `hebrew` - RTL

### Quit()

Close the menu and return to game.

```lua
TBMenu.Quit()
```

---

## Main Navigation

### openMenu()

Opens a specific menu screen. This method is mostly used internally by the main menu.

```lua
TBMenu:openMenu(screenId)
```

### showHome()

Displays home screen with announcements and news.

```lua
TBMenu:showHome()
```

Features:
- Featured event/announcement display
- Home screen button grid
- Event navigation (prev/next)
- News carousel

### showMain()

Display main menu container (root).

```lua
TBMenu:showMain(noload)
```

**Parameters:**
- `noload?: boolean` - Whether to only initialize core menu elements without opening last viewed menu section

### clearNavSection()

Clear current navigation and section displays.

```lua
TBMenu:clearNavSection()
```

Destroys:
- Navigation bar
- Current section view
- Bottom bars

### playMenuSwitchAnimation()

Animate menu transition between screens. This method is currently unused by the main menu.

```lua
TBMenu:playMenuSwitchAnimation()
```

---

## Screen Management

### showSection()

Display a generic section with button grid navigation.

```lua
TBMenu:showSection(buttonsData, shift, lockedMessage)
```

**Parameters:**
- `buttonsData: MenuSectionButton[]` - Array of button definitions
- `shift?: number[]` - Position offset for section
- `lockedMessage?: string` - Message shown for locked items

**MenuSectionButton Structure:**
```lua
{
    title = "Button Title",          -- Display name
    subtitle = "Subtitle text",      -- Optional subtitle
    image = "../textures/icon.tga",  -- Button texture
    ratio = 1.0,                     -- Image aspect ratio
	size = 0.5,                      -- Horizontal scale (percentage of total section width)
	vsize = 1,                       -- Vertical scale (percentage of total section height)
    action = function() end,         -- Click handler
    locked = false,                  -- Whether locked
    lockedMessage = "Locked",        -- Locked message
    quit = false,                    -- Close menu on click
    hasNotification = false,         -- Show notification badge
    disableUnload = true             -- Keep texture loaded
}
```

### showGameLogo()

Display Toribash game logo.

```lua
TBMenu:showGameLogo()
```

### createImageButtons()

**Deprecated.** Use `imageColor` UIElement functionality instead.

```lua
TBMenu:createImageButtons(parentElement, x, y, w, h, img, imgHvr, imgPress, col, colHvr, colPress, round)
```

---

## Screen Types

### showPlaySection()

Display play mode selection.

```lua
TBMenu:showPlaySection()
```

### showPracticeSection()

Display practice mode options (tutorials).

```lua
TBMenu:showPracticeSection()
```

### showToolsSection()

Display tools and utilities menu.

```lua
TBMenu:showToolsSection()
```

### showStoreMain()

Display main Store interface.

```lua
TBMenu:showStoreMain()
```

### showMarket()

Display player market interface.

```lua
TBMenu:showMarket()
```

### showReplays()

Display replay browser.

```lua
TBMenu:showReplays()
```

### showClans()

Display clans interface or open a specific clan's page by its tag.

```lua
TBMenu:showClans(clantag)
```

**Parameters:**
- `clantag?: string` - Optional specific clan to display

### showFriendsList()

Display friends list interface.

```lua
TBMenu:showFriendsList()
```

### showNotifications()

Display notification center.

```lua
TBMenu:showNotifications()
```

### showScripts()

Display script manager.

```lua
TBMenu:showScripts()
```

### showBounties()

Display bounty system.

```lua
TBMenu:showBounties()
```

### showSettings()

Display game settings/preferences.

```lua
TBMenu:showSettings()
```

Includes:
- Graphics settings
- Audio settings
- Control mapping
- Interface options

### showRanking()

Display seasonal ranking leaderboards.

```lua
TBMenu:showRanking()
```

### showBattlepass()

Displays battle pass interface during an active season.

```lua
TBMenu:showBattlepass()
```

### showAccountMain()

Display player account information.

```lua
TBMenu:showAccountMain()
```

### showAccountPayments()

Display account payments history.

```lua
TBMenu:showAccountPayments()
```

### showMatchmaking()

Display matchmaking/queue interface (deprecated).

```lua
TBMenu:showMatchmaking()
```

---

## UI Components

### Buttons & Containers

#### spawnCloseButton()

Create a generic close button with custom styling.

```lua
TBMenu:spawnCloseButton(viewElement, rect, closeFunc, colorScheme)
```

**Parameters:**
- `viewElement: UIElement` - Parent element
- `rect: Rect` - Position and size `{x, y, w, h}`
- `closeFunc: function` - Callback on click
- `colorScheme?: MenuButtonColorScheme[]` - Custom color scheme

#### spawnWindowOverlay()

Create overlay for modal/dialog windows.

```lua
local overlay = TBMenu:spawnWindowOverlay(globalid, withMouseHandler, colorOverride)
```

**Parameters:**
- `globalid?: integer` - Rendering context
- `withMouseHandler?: boolean` - Enable click handler
- `colorOverride?: Color` - Custom overlay color

### Input Controls

#### spawnTextField2()

Create a generic text field with with input handlers.

```lua
local textField = TBMenu:spawnTextField2(
    viewElement,
    rect,                        -- Position and size
    textFieldString,             -- Initial text
    defaultString,               -- Placeholder text
    inputSettings                -- Input configuration
)
```

#### spawnTextField()

**Deprecated** Use spawnTextField2() instead

```lua
local textField = TBMenu:spawnTextField(
    parent, x, y, w, h,          -- Position and size
    textFieldString,             -- Initial text
    inputSettings,               -- Input configuration
    fontid, scale, color,        -- Text styling
    defaultStr, orientation,     -- Placeholder and layout
    noCursor, multiLine,         -- Input behavior
    darkerMode                   -- Dark theme
)
```

#### spawnSlider2()

Create a generic slider component.

```lua
local slider = TBMenu:spawnSlider2(
    parent,
    rect,                        -- Position and size
    value,                       -- Initial value (0.0-1.0)
    settings,                    -- SliderSettings object
    sliderFunc,                  -- On change callback
    onMouseDown,                 -- Mouse down callback
    onMouseUp                    -- Mouse up callback
    sliderLabelFunc              -- Custom label function
)
```

#### spawnSlider()

Legacy function to create sliders.

```lua
local slider = TBMenu:spawnSlider(
    parent, x, y, w, h,
    textWidth,                   -- Label width
    sliderRadius,                -- Handle size
    value,                       -- Initial value (0.0-1.0)
    settings,                    -- SliderSettings object
    sliderFunc,                  -- On change callback
    onMouseDown,                 -- Mouse down callback
    onMouseUp                    -- Mouse up callback
)
```

#### spawnToggle2()

Create a generic toggle/checkbox component.

```lua
local toggle = TBMenu:spawnToggle2(
    parent,
    rect,                        -- Position and size
    toggleValue,                 -- Initial state (true/false)
    updateFunc                   -- State change callback
)
```

#### spawnToggle()

Legacy function to create toggles.

```lua
local toggle = TBMenu:spawnToggle(
    parent, x, y, w, h,
    toggleValue,                 -- Initial state (true/false)
    updateFunc                   -- State change callback
)
```

#### spawnDropdown()

Create dropdown menu selector.

```lua
local dropdown = TBMenu:spawnDropdown(
    holderElement,
    dropdownElements,            -- DropdownElement[] of options
    elementHeight,               -- Height of each option
    maxHeight,                   -- Max dropdown height
    selectedItem,                -- Initially selected index
    textSettings,                -- Main text styling
    listTextSettings,            -- Dropdown item styling
    keepFocus,                   -- Keep focus when closed
    noOverlaying,                -- Don't overlay parent
    forceDisplayAbove            -- Open upward instead of down
)
```

#### spawnSearchBar()

Create generic search bar at the bottom of the main menu UI with hint text.

```lua
local searchBar = TBMenu:spawnSearchBar(searchString, hint)
```

---

## Dialogs & Popups

### Generic

#### spawnMoveableWindow()

Create a draggable window frame.

```lua
local window = TBMenu:spawnMoveableWindow(rect, globalid)
```

**Parameters:**
- `rect: Rect` - Window position and size
- `globalid: integer` - Rendering context

### Confirmation Windows

#### showConfirmationWindow()

Display yes/no confirmation dialog.

```lua
TBMenu:showConfirmationWindow(
    message,                     -- Dialog message text
    confirmAction,               -- Callback on yes
    cancelAction,                -- Callback on no
    thirdAction,                 -- Optional third button action
    thirdButtonText,             -- Third button label
    globalid                     -- Rendering context
)
```

**Example:**
```lua
TBMenu:showConfirmationWindow(
    "Delete this item?",
    function() print("Confirmed") end,
    function() print("Cancelled") end
)
```

#### showConfirmationWindowInput()

Display dialog with text input field.

```lua
TBMenu:showConfirmationWindowInput(
    title,                       -- Dialog title
    inputInfo,                   -- Input field placeholder
    confirmAction,               -- Callback with input value
    cancelAction,                -- Cancel callback
    subtitle,                    -- Optional subtitle
    globalid                     -- Rendering context
)
```

### Popups & Messages

#### displayPopup()

Show temporary popup message when hovering over a UI element (or tapping it on mobile platforms).

```lua
TBMenu:displayPopup(element, message, forceManualPosCheck, maxHeight)
```

**Parameters:**
- `element: UIElement` - Element to attach popup to
- `message: string` - Message text
- `forceManualPosCheck?: boolean` - Force manual position updating, required when used within scrollable lists
- `maxHeight?: number` - Maximum popup height

#### displayHelpPopup()

Show temporary popup message and injects a question mark into the target element.

```lua
TBMenu:displayHelpPopup(element, message, forceManualPosCheck, noMark, maxHeight)
```

**Parameters:**
- `noMark?: boolean` - Hide question mark icon

#### displayMobilePopup()

Show popup optimized for mobile devices. displayPopup() and displayHelpPopup() will automatically fall back to this function.

```lua
TBMenu:displayMobilePopup(element, message)
```

#### showStatusMessage()

Display status message bar.

```lua
TBMenu:showStatusMessage(message, time)
```

**Parameters:**
- `message: string` - Message text
- `time: number` - Display duration in seconds

**Example:**
```lua
TBMenu:showStatusMessage("Operation completed!", 2.0)
```

#### showDataError()

**Deprecated** Use showStatusMessage() instead.

```lua
TBMenu:showDataError(message, noParent, time)
```

#### showLoginError()

Display login/authentication error. This function is not currently used and will potentially be removed in future.

```lua
TBMenu:showLoginError(viewElement, actionStr)
```

#### displayLoadingMark()

Show loading indicator/spinner.

```lua
TBMenu:displayLoadingMark(element, message, size)
```

#### displayLoadingMarkSmall()

Show small loading indicator.

```lua
TBMenu:displayLoadingMarkSmall(viewElement, message, fontid, loadScale, fontScale)
```

---

## Data Display

### User Information

#### showUserBar()

Display/update user profile bar (top-right).

```lua
TBMenu:showUserBar()
```

Displays:
- Player avatar/head
- Username
- Level/rank
- Currency balance
- Settings/profile shortcuts

#### showPlayerHeadAvatar()

Render player character head as avatar.

```lua
TBMenu:showPlayerHeadAvatar(viewElement, player, extraSize)
```

**Parameters:**
- `viewElement: UIElement` - Container for avatar
- `player: PlayerInfo` - Player data
- `extraSize?: boolean` - Whether 3D viewport should use 2X scale

### Home Button

#### showHomeButton()

Display styled button on home screen.

```lua
TBMenu:showHomeButton(viewElement, buttonData, hasSmudge, extraElements, lockedMessage)
```

**Parameters:**
- `viewElement: UIElement` - Container for button
- `buttonData: MenuSectionButton` - Button configuration (see showSection)
- `hasSmudge?: integer` - Blood smudge effect id, typically equal to button's column number
- `extraElements?: UIElement[]` - Additional child elements
- `lockedMessage?: string` - Override lock message

**Returns:** `titleHeight, descHeight`

### Bottom Bars

#### showBottomBar()

Display bottom UI bar.

```lua
TBMenu:showBottomBar(leftOnly)
```

**Parameters:**
- `leftOnly?: boolean` - Only show left side bar

### Text Rendering

#### showTextWithImage()

Display text alongside an image.

```lua
TBMenu:showTextWithImage(
    viewElement,
    text,                        -- Text content
    fontid,                      -- Font ID
    imgScale,                    -- Image scale
    imagePath,                   -- Image file path
    textImageOptions,            -- Styling options
    left                         -- Image position (left/right)
)
```

#### showTextExternal()

Displays text alongside an icon indicating the text is an external link.

```lua
TBMenu:showTextExternal(viewElement, text, useUiColor)
```

**Parameters:**
- `useUiColor?: boolean` - Use element's UI color

---

## Navigation & Bars

### showNavigationBar()

Display navigation menu buttons.

```lua
TBMenu:showNavigationBar(buttonsData, customNav, customNavHighlight, selectedId)
```

**Parameters:**
- `buttonsData?: MenuNavButton[]` - Navigation button definitions
- `customNav?: boolean` - Whether provided data is custom and should ignore last opened main menu index
- `customNavHighlight?: boolean` - Whether to remember last selected button and keep it marked as active
- `selectedId?: integer` - Initially selected button id

### showMobileNavigationBar()

Mobile-optimized navigation bar. You typically don't need to call this function explicitly as showNavigationBar() will automatically fall back to it on suitable devices / screen resolutions.

```lua
TBMenu:showMobileNavigationBar(buttonsData, customNav, customNavHighlight, selectedId)
```

### getMainNavigationButtons()

Get standard navigation button definitions.

```lua
local buttons = TBMenu:getMainNavigationButtons()
```

**Returns:** Array of MenuSectionButton objects

### reloadNavigationIfNeeded()

Refresh navigation bar if outdated.

```lua
TBMenu:reloadNavigationIfNeeded()
```

---

## Advanced Features

### Scrollable Lists

#### prepareScrollableList()

Prepare a list container for scrolling.

```lua
local toReload, firstBar, secondBar, listingView, listingHolder, scrollBackground
    = TBMenu:prepareScrollableList(
        viewElement,
        firstBarSize,              -- Top/left bar height/width
        secondBarSize,             -- Bottom/right bar height/width
        scrollSize,                -- Scroll bar width/height
        accentColor,               -- Bar background color
        orientation                -- SCROLL_VERTICAL or SCROLL_HORIZONTAL
    )
```

**Returns:**
- `toReload: UIElement` - Element rendered on top
- `firstBar: UIElement` - First navigation bar
- `secondBar: UIElement` - Second navigation bar
- `listingView: UIElement` - Visible list area
- `listingHolder: UIElement` - Container for list items
- `scrollBackground: UIElement` - Scroll bar background


#### spawnScrollBar()

Create a generic scroll bar for a list.

```lua
local scrollBar = TBMenu:spawnScrollBar(
    holderElement,               -- Parent container
    numElements,                 -- Number of list items
    elementSize,                 -- Height/width per item
    orientation                  -- SCROLL_VERTICAL or SCROLL_HORIZONTAL
)
```

### Pagination

#### generatePaginationData()

Generate pagination controls.

```lua
local paginationData = TBMenu:generatePaginationData(totalPages, maxPages, currentPage)
```

**Parameters:**
- `totalPages: integer` - Total number of pages
- `maxPages: integer` - Maximum pages to show in pagination
- `currentPage: integer` - Currently active page

### Utilities

#### getTime()

Format seconds into readable time string.

```lua
local timeString = TBMenu:getTime(seconds, cut)
```

**Parameters:**
- `seconds: integer` - Seconds to format
- `cut?: integer` - Number of segments (e.g. years, days, hours, etc) to show

**Returns:** Formatted time string (e.g., "2 minutes 34 seconds" for 154 seconds)

#### getImageDimensions()

Calculate image size to fit container. This is only used internally for menu section button styling and may not otherwise have a lot of uses.

```lua
local w, h, shift = unpack(TBMenu:getImageDimensions(width, height, ratio, shift1, shift2))
```

**Parameters:**
- `width: number` - Container width
- `height: number` - Container height
- `ratio: number` - Image aspect ratio
- `shift1: number` - Button title offset
- `shift2: number` - Button subtitle offset

**Returns:** Table with `{width, height, verticalShift}`

### Visual Effects

#### addOuterRounding()

Add faked rounded corners to element edges. This is *only* to be used for images - for regular UIElement objects you should use the built-in rounded and shapeType parameters.

```lua
TBMenu:addOuterRounding(element, color, rounding)
```

#### addBottomBloodSmudge()

Add blood smudge effect to the bottom of the element.

```lua
TBMenu:addBottomBloodSmudge(parentElement, num, scale)
```

**Parameters:**
- `num: integer` - Smudge texture id
- `scale?: number` - Vertical size override

---

## Status Message

### TBMenuStatusMessage

Special UIElement for status display.

```lua
-- Access current status message
if TBMenu.StatusMessage then
    local msg = TBMenu.StatusMessage.messageView
    local startTime = TBMenu.StatusMessage.startTime
    local endTime = TBMenu.StatusMessage.endTime
end
```

**Fields:**
- `messageView: UIElement` - Text element
- `startTime: number` - Display start time
- `endTime: number` - Display end time

---

## Common Patterns

### Custom Dialog

```lua
TBMenu:showConfirmationWindow(
    "Are you sure?",
    function()
        -- Yes action
        print("Confirmed!")
    end,
    function()
        -- No action
        print("Cancelled!")
    end,
    nil, nil,
    TB_MENU_HUB_GLOBALID  -- globalid
)
```

### Displaying a List

```lua
local elementHeight = 50
local toReload, _, _, _, listHolder, _ = TBMenu:prepareScrollableList(
    viewElement, elementHeight, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR, SCROLL_VERTICAL
)
local listElements = {}
for i = 1, 50 do
    local item = listHolder:addChild({
        pos = {0, (i-1) * 50},
        size = {listHolder.size.w, 50},
        bgColor = {0.1, 0.1, 0.1, 1},
        interactive = true
    })
	table.insert(listElements, item)
    item:addAdaptedText("Item " .. i)
	item:hide()
end
local scrollBar = TBMenu:spawnScrollBar(listHolder, #listElements, elementHeight)
listHolder.scrollBar = scrollBar
scrollBar:makeScrollBar(listHolder, listElements, toReload)
```

---

## Version History

**5.76** - Latest
- Minor visual tweaks to moveable windows

**5.74**
- Mouse cursor controls for text fields (`spawnTextField2()`)
- UIElement text padding support
- Custom color scheme for close buttons

**5.71**
- New account info screen with payments history

**5.70**
- `spawnSlider2()` with Rect positioning
- Vertical slider support
- Slider label peek on hover

**5.65**
- Dropdown scroll bar override
- Popups list (`TBMenu.Popups`)
- Popup improvements

**5.61**
- On-screen keyboard customization
- `BuildInputFieldSettings()` function

**5.60**
- Global UIElement holders moved to TBMenu fields
- Per-button locked messages
- Single image animated buttons
- Horizontal scrollable lists

---

## See Also

- [UIElement Documentation](UIELEMENT.md) - UI element API
- [UIElement3D Documentation](UIELEMENT3D.md) - 3D rendering
- [menu_main.lua](../../script/system/menu_main.lua) - Modern UI and main menu entry point
- [Main README](../README.md) - Repository overview
