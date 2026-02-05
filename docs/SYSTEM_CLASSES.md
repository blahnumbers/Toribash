# System Classes & Managers

Reference for public APIs of core Toribash system managers located in `script/system/` that are suitable for use in third-party scripts.

## Table of Contents

1. [Overview](#overview)
2. [File I/O](#file-io)
3. [Network Requests](#network-requests)
4. [Player Information](#player-information)
5. [Store & Inventory](#store--inventory)
6. [Room List](#room-list)
7. [Download Management](#download-management)
8. [Common Patterns](#common-patterns)

---

## Overview

The `script/system/` directory contains Lua modules that handle core game systems. Most managers are designed for internal use by the main menu system, but several expose public APIs that are safe and useful for third-party scripts:

- **Files** (`iofiles.lua`) - Cross-platform file I/O operations
- **Request** (`network_request.lua`) - Async network request management
- **PlayerInfo** (`playerinfo_manager.lua`) - Player data and statistics
- **Store** (`store_manager.lua`) - Shop items and inventory access
- **RoomList** (`roomlist_manager.lua`) - Online room information
- **Downloader** (`downloader_manager.lua`) - Asset download queue management

**Important:** Other system managers (`atmospheres_manager.lua`, `events_manager.lua`, `clans_manager.lua`, etc.) are tightly coupled to the menu system and should not be used directly in third-party scripts.

---

## File I/O

**Module:** `script/system/iofiles.lua` (v5.68)

Cross-platform file operations for reading, writing, and managing files.

### Classes

#### Files (Static Class)

Main interface for file operations.

**Methods:**

```lua
Files.Open(path, mode)
```
Opens a file for reading or writing.
- **path** `string` - File path. Use `../` prefix to start from Toribash root folder
- **mode** `openmode` - Optional. One of:
  - `FILES_MODE_READONLY` (`'r'`) - Read only (default)
  - `FILES_MODE_WRITE` (`'w+'`) - Write (creates/overwrites)
  - `FILES_MODE_APPEND` (`'a'`) - Append to end
  - `FILES_MODE_READWRITE` (`'r+'`) - Read and write
- **Returns:** `File` object

```lua
Files.Exists(path)
```
Checks if file exists and is readable.
- **path** `string` - File path to check
- **Returns:** `boolean`

```lua
Files.WriteDebug(line, rewrite)
```
Writes debug information to `../debug.txt`.
- **line** `any` - Data to write (tables will be JSON encoded)
- **rewrite** `boolean` - Optional. If true, clears previous contents
- **Returns:** `nil`

```lua
Files.LogError(line)
```
Prints error to Toribash error log (`stderr.txt`).
- **line** `any` - Error message to log
- **Returns:** `nil`

#### File (Instance Class)

Represents an opened file.

**Methods:**

```lua
file:readAll(raw)
```
Reads entire file contents.
- **raw** `boolean` - Optional. If true, returns raw string. Otherwise returns array of lines
- **Returns:** `string[]` or `string` (if raw=true)

```lua
file:writeLine(line)
```
Writes a line to the file (appends newline if missing).
- **line** `string` - Text to write
- **Returns:** `boolean` - Success status

```lua
file:isDownloading()
```
Checks if file is currently being downloaded.
- **Returns:** `boolean`

```lua
file:close()
```
Closes the file.
- **Returns:** `nil`

```lua
file:reopen(mode)
```
Closes and reopens file with new mode.
- **mode** `openmode` - Optional. New mode (defaults to current mode)
- **Returns:** `nil`

### Usage Example

```lua
-- Read a file
local file = Files.Open("data/myfile.txt")
local lines = file:readAll()
file:close()
for _, line in pairs(lines) do
    echo(line)
end

-- Write to a file
local file = Files.Open("../output.txt", FILES_MODE_WRITE)
if file.data then
    file:writeLine("Hello World")
    file:writeLine("Second line")
    file:close()
end

-- Check if file exists
if Files.Exists("data/config.txt") then
    echo("Config file found")
end

-- Debug logging
Files.WriteDebug("Script started")
Files.WriteDebug({player = "Test", score = 100})  -- Logs as JSON
```

---

## Network Requests

**Module:** `script/system/network_request.lua` (v5.76)

Asynchronous network request manager with promise-based API.

### Request Class

**Methods:**

```lua
Request:queue(netcall, name, success, error)
```
Queues a network request for execution.
- **netcall** `function` - Function that initiates the network request (e.g., `download_server_info()`)
- **name** `string` - Optional. Request identifier for debugging
- **success** `function(promise, data)` - Optional. Called on successful response
- **error** `function(promise, data)` - Optional. Called on network error
- **Returns:** `RequestPromise`

```lua
Request:cancel(promise)
```
Cancels a pending request.
- **promise** `RequestPromise` - The promise returned from `Request:queue()`
- **Returns:** `RequestData|nil`

### RequestPromise

Response object returned from `Request:queue()`.

**Fields:**
- **ready** `boolean` - True when request is finalized
- **failed** `boolean` - True if request finalized with error
- **id** `string` - Unique request identifier
- **timestamp** `number` - Request creation time

### Usage Example

```lua
-- Queue a request
local promise = Request:queue(
    function()
        download_server_info("bounties")
    end,
    "getBounties",
    function(_, data)
        Files.WriteDebug("Success! Data:\n" .. data)
    end,
    function(_, data)
        Files.WriteDebug("Error: " .. data)
    end
)

local timeNow = os.clock_real()
add_hook("pre_draw", "cancelTimedRequest", function()
    if (os.clock_real() - timeNow >= 3) then
        -- Check promise status
        if promise.ready then
            if promise.failed then
                echo("Request failed")
            else
                echo("Request succeeded")
            end
        else
            -- Cancel request
            Request:cancel(promise)
            echo("Request canceled")
        end
        remove_hooks("cancelTimedRequest")
    end
end)
```

---

## Player Information

**Module:** `script/system/playerinfo_manager.lua` (v5.76)

Fetches and manages player profile data, statistics, and customizations.

### PlayerInfo Class

**Static Methods:**

```lua
PlayerInfo.Get(username, scope)
```
Creates a PlayerInfo object for the specified player.
- **username** `string` - Optional. Player name (omit for current user)
- **scope** `PlayerInfoScope` - Optional. Data to load:
  - `PLAYERINFO_SCOPE_NONE` (0) - No extra data (default)
  - `PLAYERINFO_SCOPE_GENERAL` (1) - Load TC, ST, Qi, belt data
- **Returns:** `PlayerInfo` object

```lua
PlayerInfo.getBeltFromQi(qi)
```
Converts Qi value to belt information.
- **qi** `integer` - Qi amount
- **Returns:** `PlayerInfoBelt` with fields: `name`, `icon`, `minQi`, `maxQi`, `nextBelt`

```lua
PlayerInfo.getLoginRewards()
```
Gets current user's login reward status.
- **Returns:** `LoginRewards` table with:
  - **days** `integer` - Current login streak
  - **available** `boolean` - Can claim reward now
  - **timeLeft** `integer` - Seconds until reward expires

```lua
PlayerInfo.getServerUserinfo(username)
```
Fetches detailed user info from server (async).
- **username** `string` - Optional. Player name (omit for current user)
- **Returns:** `RequestPromise` - Use with callbacks to handle response

**Instance Methods:**

```lua
playerInfo:getUserData(player)
```
Gets player's TC, ST, Qi, and belt.
- **player** `string` - Optional. Defaults to object's username
- **Returns:** `PlayerInfoData` table:
  - **tc** `integer` - Toricredits
  - **st** `integer` - Shiai Tokens
  - **qi** `integer` - Total Qi
  - **belt** `PlayerInfoBelt` - Belt info

```lua
playerInfo:getItems(player, scope)
```
Gets player's equipped items.
- **player** `string` - Optional. Player name
- **scope** `PlayerInfoCustomsScope` - Optional. What to load (bitmask):
  - `PLAYERINFO_CSCOPE_COLORS` (1) - Body colors
  - `PLAYERINFO_CSCOPE_TEXTURES` (2) - Textures
  - `PLAYERINFO_CSCOPE_OBJECTS` (4) - 3D objects
  - `PLAYERINFO_CSCOPE_EFFECTS` (8) - Visual effects
  - `PLAYERINFO_CSCOPE_ALL` (15) - Everything
- **Returns:** `PlayerInfoCustoms` table with `colors`, `textures`, `objs`, `effects` arrays

```lua
playerInfo:getClan(player, tag)
```
Gets player's clan information.
- **player** `string` - Optional. Player name
- **tag** `string` - Optional. Clan tag if known
- **Returns:** `PlayerInfoClan` table:
  - **id** `integer` - Clan ID
  - **name** `string` - Clan name
  - **tag** `string` - Clan tag
  - **isleader** `boolean` - Whether player is clan leader

```lua
playerInfo:getRanking()
```
Gets current player's ranking data.
- **Returns:** `PlayerInfoRanking` table with ranking info

### Usage Example

```lua
-- Get current user info
local me = PlayerInfo.Get(PLAYERINFO_SCOPE_GENERAL)
echo("Username: " .. me.username)
echo("Toricredits: " .. me.data.tc)
echo("Belt: " .. me.data.belt.name)

-- Get another player's info
local player = PlayerInfo.Get("PlayerName")
local userData = player:getUserData()
echo("Player Qi: " .. userData.qi)

-- Get items
player:getItems(PLAYERINFO_CSCOPE_ALL)
local numTextures = 0
for _, v in pairs(player.items.textures) do
    if (v.equipped) then numTextures = numTextures + 1 end
end
echo("Equipped body textures: " .. numTextures)

-- Get clan info
player:getClan()
if player.clan.id > 0 then
    echo("Clan: " .. player.clan.name .. " [" .. player.clan.tag .. "]")
end

-- Check login rewards
local rewards = PlayerInfo.getLoginRewards()
if rewards.available then
    echo("Can claim day " .. rewards.days .. " reward!")
end

-- Get belt from Qi
local belt = PlayerInfo.getBeltFromQi(50000)
echo("50k Qi = " .. belt.name .. " belt")
```

**Note:** in order to load information about players, their customs must be present in local cache. To ensure you retrieve accurate data, combine PlayerInfo functionality either with `/dl` command or `download_head()` function and wait for downloads to finalize.

---

## Store & Inventory

**Module:** `script/system/store_manager.lua` (v5.70)

Manages Torishop items and player inventory. Most functionality is designed for internal menu system use. For third-party scripts, the main use cases are:
- Querying store item information
- Downloading and parsing inventory data

### Store Class

**Read-Only Properties:**
- **Store.Ready** `boolean` - Whether store data has been loaded

**Public Methods:**

```lua
Store:getItemInfo(itemid)
```
Gets information about a store item by ID. Returns a `StoreItem` object.
- **itemid** `integer` - Item ID to look up
- **Returns:** `StoreItem` - Item details object

```lua
Store:getCategoryInfo(catid)
```
Gets store category information.
- **catid** `integer` - Category ID
- **Returns:** `StoreItemCategory` - Table with `id` and `name` fields

```lua
Store.ParseInventory(path)
```
Parses inventory datafile and returns array of inventory items.
- **path** `string` - Optional. Path to inventory file. If omitted, parses current user's `data/inventory.txt` and caches result in `Store.Inventory`
- **Returns:** `InventoryItem[]|nil`

**Note:** Methods like `Store:isTextureItem()`, `Store:itemSupportsEffects()`, `Store:getSaleFeatured()`, `Store:getSaleItems()`, `Store:getInventoryItems()`, `Store:getInventoryCategoryItems()`, and `Store:getInventory()` are designed for internal menu use and add overhead. Use `StoreItem` methods directly when working with StoreItem objects.

### StoreItem Class

Represents a Torishop item. When you already have a `StoreItem` object (e.g., from `Store:getItemInfo()`), prefer using its methods directly instead of `Store:` wrapper methods.

**Common Fields:**
- **itemid** `integer` - Unique item identifier
- **itemname** `string` - Display name
- **catid** `integer` - Category ID
- **catname** `string` - Category name
- **price** `integer` - Default TC price
- **price_usd** `number` - Default USD/ST price
- **now_tc_price** `integer` - Current TC price (accounts for sales)
- **now_usd_price** `number` - Current USD/ST price (accounts for sales)
- **on_sale** `boolean` - Currently on sale
- **sale_discount** `number` - Sale discount percent
- **sale_time** `integer` - Seconds remaining on sale
- **qi** `integer` - Qi requirement to purchase
- **ingame** `boolean` - Can be equipped on character
- **colorid** `integer` - Color ID (for color items)
- **contents** `integer[]` - Item IDs in pack (for pack items)

**Methods:**

```lua
item:getCopy()
```
Returns a deep copy of the StoreItem object.
- **Returns:** `StoreItem`

```lua
item:isTexture()
```
Checks if item is a texture.
- **Returns:** `boolean`

```lua
item:getIconPath()
```
Gets path to item's icon texture.
- **Returns:** `string` - Path like `"../textures/store/items/123.tga"`

```lua
item:supportsEffects()
```
Checks if item supports visual effects (glow, ripples, color shift).
- **Returns:** `boolean`

### InventoryItem Class

Represents an item in player's inventory. Created by `Store.ParseInventory()`.

**Common Fields:**
- **inventid** `integer` - Unique inventory entry ID
- **itemid** `integer` - Store item ID
- **name** `string` - Item name
- **active** `boolean` - Whether item is currently equipped
- **upgrade_level** `integer` - Current upgrade level (0 if not upgradeable)
- **tradeable** `boolean` - Can be traded
- **customizable** `boolean` - Can be customized
- **uploadable** `boolean` - Supports custom textures
- **setid** `integer` - Parent set inventid (0 if not in a set)
- **parentset** `InventoryItem|nil` - Reference to parent set item
- **contents** `InventoryItem[]|nil` - Items in set (for set items)
- **effectid** `integer` - Applied effect ID
- **glow_colorid** `integer` - Glow effect color
- **voronoi_colorid** `integer` - Ripples effect color
- **shift_colorid** `integer` - Color shift effect color

### Raw Inventory Download API

```lua
download_inventory(username)
```
Native Toribash function to download inventory data from server.
- **username** `string` - Optional. Player name. If omitted, downloads current user's inventory
- **Returns:** `nil` - Triggers async download

**Behavior:**
- Current user's inventory saves to `data/inventory.txt`
- Other users' inventory saves to `data/uinvent.tmp`
- Triggers `downloader_complete` hook when download is finished

### Usage Example

```lua
-- Download and parse hampa's inventory
download_inventory("hampa")

add_hook("downloader_complete", "onInventoryDownload", function(filename)
    if filename:find("data/uinvent.tmp") then
        -- See below for Downloader.SafeCall() info
        Downloader.SafeCall(function()
            -- Parse downloaded inventory
            local inventory = Store.ParseInventory("../data/uinvent.tmp")
            
            if inventory then
                echo("Total items: " .. #inventory)
                
                -- Find specific item
                for _, invItem in pairs(inventory) do
                    if invItem.itemid == 1750 then
                        echo("Found item: " .. invItem.name)
                        if invItem.active then
                            echo("Currently equipped")
                        end
                        break
                    end
                end
            end
        end)
        
        remove_hooks("onInventoryDownload")
    end
end)

-- Working with StoreItem objects efficiently
if Store.Ready then
    local item = Store:getItemInfo(1567)
    
    -- GOOD: Use StoreItem methods directly
    if item:isTexture() then
        echo("This is a texture item")
    end
    
    if item:supportsEffects() then
        echo("Can apply effects")
    end
    
    local iconPath = item:getIconPath()
    
    -- LESS EFFICIENT: Using Store wrappers (adds overhead)
    -- if Store:isTextureItem(1576) then ... end
    -- if Store:itemSupportsEffects(1576) then ... end
end
```

---

## Room List

**Module:** `script/system/roomlist_manager.lua` (v5.70)

Manages multiplayer room listings and player counts.

### RoomList Class

**Static Methods:**

```lua
RoomList.RefreshIfNeeded()
```
Refreshes room cache if data is stale (older than `RoomList.RefreshPeriod` seconds).
- **Returns:** `boolean` - True if refresh was triggered

```lua
RoomList.GetRooms()
```
Gets a copy of cached room list.
- **Returns:** `RoomListInfoExtended[]` - Array of room information tables

```lua
RoomList.GetPlayers()
```
Gets list of all online players across all rooms.
- **Returns:** `RoomListPlayer[]` - Array of `{username, room}` tables

### RoomListInfoExtended Fields

Information about a multiplayer room:
- **id** `integer` - Room ID (1-indexed for Lua)
- **name** `string` - Room name
- **desc** `string` - Room description (may contain color codes)
- **desc_clean** `string` - Description without color codes
- **hostname** `string` - Server address in "ip:port" format
- **mod** `string` - Mod name (e.g., "aikido.tbm")
- **num_players** `integer` - Current player count
- **max_clients** `integer` - Maximum allowed players
- **players** `string[]` - Array of player names in room
- **min_belt** `integer` - Minimum belt requirement
- **max_belt** `integer` - Maximum belt requirement
- **min_rank** `integer` - Minimum rank requirement
- **max_rank** `integer` - Maximum rank requirement
- **min_elo** `number` - Minimum elo requirement
- **max_elo** `number` - Maximum elo requirement
- **entry_fee** `integer` - Room entry fee (TC)
- **is_official** `boolean` - Official Toribash room
- **is_ranked** `boolean` - Ranked matches
- **is_duel_mode** `boolean` - Duel mode enabled
- **is_password_protected** `boolean` - Requires password
- **is_tournament** `boolean` - Tournament room
- **gamerules** `GameRules` - Full game rules object

### Usage Example

```lua
-- Check if room list needs refreshing (and trigger if needed)
local needsRefresh = RoomList.RefreshIfNeeded()

if needsRefresh then
    -- Room list is being refreshed asynchronously
    -- Listen for roomlist_update hook to know when it's done
    add_hook("roomlist_update", "myRoomListHandler", function(error)
        if utf8.len(error) == 0 then
            local rooms = RoomList.GetRooms()
            echo("Room list refreshed! Total rooms: " .. #rooms)
        else
            echo("Room list refresh failed: " .. error)
        end
        remove_hooks("myRoomListHandler")
    end)
else
    -- Cache is still valid, use it directly
    local rooms = RoomList.GetRooms()
    echo("Total rooms: " .. #rooms)
    
    for _, room in pairs(rooms) do
        echo(string.format("[%s] %s - %d/%d players - %s",
            room.is_official and "OFFICIAL" or "CUSTOM",
            room.name,
            room.num_players,
            room.max_clients,
            room.mod
        ))
    end
    
    -- Find rooms for a specific mod
    local aikidoRooms = {}
    for _, room in pairs(rooms) do
        if room.mod == "aikido.tbm" then
            table.insert(aikidoRooms, room)
        end
    end
    echo("Aikido rooms: " .. #aikidoRooms)
    
    -- Get all online players
    local players = RoomList.GetPlayers()
    echo("Total online players: " .. #players)
    for _, p in pairs(players) do
        echo(p.username .. " in " .. p.room)
    end
    
    -- Find rooms with space
    local joinableRooms = {}
    for _, room in pairs(rooms) do
        if room.num_players < room.max_clients and not room.is_password_protected then
            table.insert(joinableRooms, room)
        end
    end
    echo("Joinable rooms: " .. #joinableRooms)
end
```

---

## Download Management

**Module:** `script/system/downloader_manager.lua` (v5.72)

Utility class to help manage download queue and react to downloader completion events. Automatically initialized on startup.

### Downloader Class

**Methods:**

```lua
Downloader:queue(func)
```
Queues a function to execute on next `downloader_complete` callback.
- **func** `function` - Download function to execute (e.g., `download_inventory`, `download_clan`)
- **Returns:** `integer|nil` - New queue size or nil on error

```lua
Downloader.SafeCall(func)
```
Queues a function to run on next `pre_draw` callback. Use this to execute most advanced logic associated with `downloader_complete` to ensure consistency with general function execution loop and prevent crashes.
- **func** `function` - Function to execute safely
- **Returns:** `string|nil` - Hook ID or nil on error

### Usage Example

```lua
-- Instantly begin downloading hampa's base customs and head texture
download_head("hampa")
-- Queue downloads to begin after previous one's completion
Downloader:queue(download_inventory)
Downloader:queue(download_clan)

-- Safe callback usage
add_hook("downloader_complete", "onInventoryDownloaded", function(filename)
    if (filename:find("data/inventory.txt")) then
        Downloader.SafeCall(Store.ParseInventory)
        remove_hooks("onInventoryDownloaded")
    end
end)
```

---

## Common Patterns

### Checking Data Availability

Many managers cache data that needs to be explicitly loaded:

```lua
-- Store: Check if ready before accessing
if not Store.Ready then
    Store.GetItems()  -- Queue download
    echo("Store data loading...")
else
    local item = Store:getItemInfo(100)
    echo("Item: " .. item.itemname)
end

-- RoomList: Handle async refresh properly
if RoomList.RefreshIfNeeded() then
    echo("Refreshing room list...")
    -- Listen for roomlist_update hook to process data when ready
    add_hook("roomlist_update", "handleRoomUpdate", function(error)
        if utf8.len(error) == 0 then
            local rooms = RoomList.GetRooms()
            echo("Rooms: " .. #rooms)
        end
        remove_hooks("handleRoomUpdate")
    end)
else
    -- Cache is valid, use it immediately
    local rooms = RoomList.GetRooms()
    echo("Rooms: " .. #rooms)
end
```

### Async Network Requests

Use `Request:queue()` for network operations with callbacks:

```lua
-- Pattern 1: With success/error callbacks
local promise = Request:queue(
    function()
        download_server_info("last_broadcast")
    end,
    "getLastBroadcast",
    function(response, data)
        echo("Broadcast data received: " .. data)
    end,
    function(response, data)
        echo("Failed to fetch broadcast data: " .. data)
    end
)

-- Pattern 2: Check promise manually
local promise = Request:queue(function()
    download_inventory()
end, "getInventory")

-- Later, check if complete
if promise.ready then
    if promise.failed then
        echo("Download failed")
    else
        echo("Download succeeded")
        Store.ParseInventory()
    end
end
```

### File I/O Safety

All methods available in File class perform an internal check to see whether the file has actually been opened and is available for operations. However, you must always make sure you close all opened files before you dispose of the File instance.

```lua
-- Unsafe example of reading a file
local file = Files.Open("data/config.txt")
-- Good to check if file data is available, but not necessary
if file.data then
    for _, line in pairs(file:readAll()) do
        -- Process file line-by-line
        -- If anything goes wrong here and script crashes during processing,
        -- we will never reach the close() call and File interface will stay open
    end
    file:close()
else
    echo("File not found or not readable")
end

-- Safe example of reading a file
local file = Files.Open("data/config.txt")
if file.data then
    -- Read and cache all data and close the file
    local lines = file:readAll()
    file:close()
    -- Now get to processing - even if something breaks at this point, we don't leak anything
    for _, line in pairs(lines) do
        ...
    end
else
    echo("File not found or not readable")
end
```

### Room Filtering

```lua
-- Get rooms matching criteria
local rooms = RoomList.GetRooms()

-- Filter by mod
local aikidoRooms = {}
for _, room in pairs(rooms) do
    if room.mod == "aikido.tbm" then
        table.insert(aikidoRooms, room)
    end
end

-- Filter by player count
local activeRooms = {}
for _, room in pairs(rooms) do
    if room.num_players >= 4 then
        table.insert(activeRooms, room)
    end
end

-- Filter by requirements
local joinable = {}
local myBelt = PlayerInfo.Get(PLAYERINFO_SCOPE_GENERAL).data.belt.minQi
for _, room in pairs(rooms) do
    local canJoin = not room.is_password_protected and
                    room.num_players < room.max_clients and
                    myBelt >= room.min_belt and
                    myBelt <= room.max_belt
    if canJoin then
        table.insert(joinable, room)
    end
end
```

### Debug Logging

```lua
-- Log to debug.txt in root folder
Files.WriteDebug("Script started")
Files.WriteDebug({
    player = "TestUser",
    score = 100,
    timestamp = os.clock_real()
})

-- Clear previous debug data
Files.WriteDebug("New session", true)

-- Log errors to stderr.txt
Files.LogError("Something went wrong: invalid data")
```

---

## See Also

- [UIElement Documentation](UIELEMENT.md) - 2D UI system
- [UIElement3D Documentation](UIELEMENT3D.md) - 3D rendering system
- [Menu Manager Documentation](MENU_MANAGER.md) - Main menu orchestration (coming soon)
- [Main README](../README.md) - Repository overview


