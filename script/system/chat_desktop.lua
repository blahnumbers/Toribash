-- Desktop chat presentation; routing and keyboard input remain in the native client.
if (not get_desktop_chat_tabs or is_mobile()) then return end
require("toriui.uielement3d")
if (get_desktop_chat_emojis) then require("system.chat_emoji") end

if (get_desktop_chat_completions) then require("system.chat_completion") end

if (get_desktop_chat_scroll) then require("system.chat_scroll") end

local globalid = 1020
local hook = "desktopChatTabs"
local root, signature
local views = {}
local red = TB_MENU_DEFAULT_DARKER_COLOR
local white = TB_MENU_UI_TEXT_COLOR
local ink = get_color_rgba(COLORS.GREY)
ink[4] = 1
local surface = TB_MENU_DEFAULT_INACTIVE_COLOR
local hover = TB_MENU_DEFAULT_LIGHTEST_COLOR
local unreadColor = TB_MENU_DEFAULT_YELLOW

local function destroy()
    if (root) then root:kill() root = nil end
    views, signature = {}, nil
end

local function rebuild(tabs, key)
    destroy()
    signature = key
    root = UIElement:new({ globalid = globalid, pos = { 0, 0 }, size = { WIN_W, WIN_H } })
    for i = 1, 8 do
        local tab = tabs[i]
        if (tab) then
            local scale = tab.h / 38
            local button = root:addChild({
                pos = { tab.x, tab.y }, size = { tab.w, tab.h },
                interactive = true, shapeType = ROUNDED, rounded = 7 * scale,
                bgColor = surface, hoverColor = hover, pressedColor = red
            })
            button:addMouseUpHandler(function() select_desktop_chat_tab(tab.id) end)
            -- The same fixed viewport used by the player-list profile, inside the room icon's padding.
            local avatarSize = (tab.whisper and 32 or 24) * scale
            local avatarHolder = button:addChild({ pos = { (50 * scale - avatarSize) / 2, (tab.h - avatarSize) / 2 }, size = { avatarSize, avatarSize } })
            local roomIcon, avatarObjects
            local avatarAlphas = {}
            if (tab.whisper) then
                local avatar = TBMenu:showPlayerHeadAvatar(avatarHolder, tab.username)
                avatar.rootHolder:resetRotation()
                avatar.rootHolder:moveTo(0, -0.6, 0) -- Zoom the head and its attached items together, inside the fixed viewport.
                if (avatar.avatarObjects[2]) then avatar.avatarObjects[2]:hide(true) end
                avatarObjects = avatar.avatarObjects
                for index, object in ipairs(avatarObjects) do
                    avatarAlphas[index] = object.bgColor[4]
                end
            else
                roomIcon = avatarHolder:addChild({ shift = { 0, 0 }, bgImage = TB_MENU_FRIENDS_BUTTON, imageColor = ink })
            end
            local name = tab.whisper and tab.username or tab.name
            if (name == "") then name = "Game" end
            local right = tab.closable and 44 * scale or 10 * scale
            local label = button:addChild({
                pos = { 50 * scale, 0 }, size = { math.max(4, tab.w - 50 * scale - right), tab.h }, uiColor = ink
            })
            label:addAdaptedText(false, name, nil, nil, FONTS.MEDIUM, LEFTMID, 0.85, 0.85)
            local closeIcon
            if (tab.closable) then
                local close = button:addChild({ pos = { -34 * scale, 0 }, size = { 24 * scale, tab.h }, interactive = true })
                closeIcon = close:addChild({ pos = { 5 * scale, (tab.h - 14 * scale) / 2 }, size = { 14 * scale, 14 * scale }, bgImage = "../textures/menu/general/buttons/crosswhite.tga", imageColor = ink })
                close:addMouseUpHandler(function() close_chat_tab(tab.id) end)
            end
            local badge = button:addChild({ pos = { 26 * scale, tab.h - 20 * scale }, size = { 22 * scale, 20 * scale }, bgColor = red, shapeType = ROUNDED, rounded = 7 * scale, uiColor = white })
            badge:addAdaptedText(false, tostring(tab.unread), nil, nil, FONTS.SMALL, CENTERMID, 0.85)
            views[i] = { button = button, label = label, close = closeIcon, badge = badge, roomIcon = roomIcon, avatarObjects = avatarObjects, avatarAlphas = avatarAlphas }
        end
    end
end

local function refresh()
    local enabled = get_option("chattabstyle") ~= 0 and TB_MENU_MAIN_ISOPEN ~= 1 and TB_MENU_SPECIAL_SCREEN_ISOPEN ~= 1
    local tabs = get_desktop_chat_tabs(enabled)
    if (not enabled or not tabs or next(tabs) == nil) then destroy() return end
    local parts = {}
    for i = 1, 8 do
        local tab = tabs[i]
        if (tab) then parts[#parts + 1] = table.concat({ i, tab.name, tostring(tab.whisper), tostring(tab.closable), tab.x, tab.y, tab.w, tab.h }, ":") end
    end
    local key = table.concat(parts, "|")
    if (signature ~= key) then rebuild(tabs, key) end
    for i, view in pairs(views) do
        local tab = tabs[i]
        view.button.bgColor = tab.selected and red or (tab.unread > 0 and unreadColor or surface)
        view.button.hoverColor = tab.selected and TB_MENU_DEFAULT_BG_COLOR or hover
        local foreground = tab.selected and white or (tab.unread > 0 and UICOLORBLACK or ink)
        view.label.uiColor = foreground
        if (view.close) then view.close.imageColor = foreground end
        if (view.roomIcon) then view.roomIcon.imageColor = foreground end
        for index, object in ipairs(view.avatarObjects or {}) do
            object.bgColor[4] = view.avatarAlphas[index] * ((tab.selected or tab.unread > 0) and 1 or 0.85)
        end
        if (tab.unread > 0 and not tab.selected) then
            if (view.unread ~= tab.unread) then view.badge:addAdaptedText(false, tostring(tab.unread), nil, nil, FONTS.SMALL, CENTERMID, 0.85) end
            view.badge:show()
        else view.badge:hide() end
        view.unread = tab.unread
    end
end

add_hook("pre_draw", hook, refresh)
add_hook("draw2d", hook, function() if (root) then UIElement.drawVisuals(globalid) end end)
-- Viewports draw before draw2d, where UIElement normally updates child positions.
add_hook("draw_viewport", hook, function() if (root) then root:updatePos() UIElement3D.drawViewport(globalid) end end)
add_hook("resolution_changed", hook, destroy)
add_hook("new_game", hook, destroy)
add_hook("unload", hook, function() destroy() get_desktop_chat_tabs(false) end)
