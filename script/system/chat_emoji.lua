-- The native catalogue supplies codes and filenames; display names are intentionally unused.
local emojis = get_desktop_chat_emojis()
local globalid, hook = 1021, "desktopChatEmoji"
local root, picker, regionsRoot, inputKey, regionsKey
local pickerCells, keyboardIndex = {}, 1
TB_CHAT_EMOJI_PICKER_OPEN = false
local function closePicker()
    TB_CHAT_EMOJI_PICKER_OPEN = false
    if (picker) then picker:kill() picker = nil end
    pickerCells = {}
end
local function reset()
    closePicker()
    if (root) then root:kill() root = nil end
    if (regionsRoot) then regionsRoot:kill() regionsRoot = nil end
    inputKey, regionsKey = nil, nil
end
local function tooltip(element, code)
    local popup = TBMenu:displayPopup(element, code, true)
    popup:moveTo(0, -element.size.h - popup.size.h - 6)
end
local function choose(index)
    if (insert_desktop_chat_emoji(index - 1)) then closePicker() end
end
local function openPicker(input, scale)
    if (picker) then closePicker() return end
    TB_CHAT_EMOJI_PICKER_OPEN = true
    picker = root:addChild({ size = { WIN_W, WIN_H }, interactive = true })
    picker:addMouseUpHandler(closePicker)
    local width, height = 216 * scale, 136 * scale
    local panel = picker:addChild({
        pos = { math.max(8, input.x + input.w + 38 * scale - width), math.max(8, input.y - height - 8 * scale) },
        size = { width, height }, interactive = true, shapeType = ROUNDED, rounded = 7 * scale,
        bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
    })
    for index, emoji in ipairs(emojis) do
        local cell = panel:addChild({
            pos = { (8 + (index - 1) % 5 * 40) * scale, (8 + math.floor((index - 1) / 5) * 40) * scale },
            size = { 40 * scale, 40 * scale }, interactive = true, shapeType = ROUNDED, rounded = 5 * scale,
            bgColor = TB_MENU_DEFAULT_DARKEST_COLOR, hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR, pressedColor = TB_MENU_DEFAULT_BG_COLOR
        })
        cell:addChild({ shift = { 5 * scale, 5 * scale }, bgImage = "../textures/chat/emoji/" .. emoji.file })
        cell:addMouseUpHandler(function() choose(index) end)
        tooltip(cell, emoji.code)
        pickerCells[index] = cell
    end
    keyboardIndex = 1
end
add_hook("pre_draw", hook, function()
    local input = get_desktop_chat_input()
    if (not input or TB_MENU_MAIN_ISOPEN == 1 or TB_MENU_SPECIAL_SCREEN_ISOPEN == 1) then reset() return end
    local key = table.concat({ input.x, input.y, input.w, input.h, tostring(input.visible), tostring(input.skin), tostring(input.focused) }, ":")
    if (key == inputKey) then return end
    reset()
    inputKey = key
    local scale = input.h / 34
    root = UIElement:new({ globalid = globalid, pos = { 0, 0 }, size = { WIN_W, WIN_H } })
    if (not input.visible) then return end -- Keep inline emoji tooltips available.
    if (input.skin) then
        -- Only the outline is drawn after the native text, leaving glyphs and caret untouched.
        local frame = root:addChild({ pos = { input.x, input.y }, size = { input.w + 38 * scale, input.h } })
        frame:addCustomDisplay(false, function()
            local x, y, w, h, r = frame.pos.x, frame.pos.y, frame.size.w, frame.size.h, 4 * scale
            set_color(TB_MENU_UI_TEXT_COLOR[1], TB_MENU_UI_TEXT_COLOR[2], TB_MENU_UI_TEXT_COLOR[3], 180 / 255)
            draw_quad(x + input.w, y + 1, w - input.w - 1, h - 2)
            set_color(unpack(input.focused and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_INACTIVE_COLOR))
            draw_quad(x + r, y, w - 2 * r, 1)
            draw_quad(x + r, y + h - 1, w - 2 * r, 1)
            draw_quad(x, y + r, 1, h - 2 * r)
            draw_quad(x + w - 1, y + r, 1, h - 2 * r)
            draw_disk(x + r, y + r, math.max(0, r - 1), r, 16, 1, -180, 90, 0)
            draw_disk(x + w - r, y + r, math.max(0, r - 1), r, 16, 1, 90, 90, 0)
            draw_disk(x + r, y + h - r, math.max(0, r - 1), r, 16, 1, -90, 90, 0)
            draw_disk(x + w - r, y + h - r, math.max(0, r - 1), r, 16, 1, 0, 90, 0)
        end)
    end
    local button = root:addChild({
        pos = { input.x + input.w + 4 * scale, input.y }, size = { 34 * scale, input.h },
        interactive = true, shapeType = ROUNDED, rounded = 6 * scale,
        bgColor = input.skin and { 0, 0, 0, 0 } or TB_MENU_DEFAULT_BG_COLOR, hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR, pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
    })
    for _, emoji in ipairs(emojis) do
        if (emoji.code == ":happy:") then button:addChild({ shift = { 5 * scale, 5 * scale }, bgImage = "../textures/chat/emoji/" .. emoji.file }) break end
    end
    button:addMouseUpHandler(function() openPicker(input, scale) end)
end)
add_hook("draw2d", hook, function()
    local regions = get_desktop_chat_emoji_regions() or {}
    local parts = {}
    if (root and not picker) then
        for _, region in ipairs(regions) do parts[#parts + 1] = table.concat({ region.emoji, region.x, region.y, region.size }, ":") end
    end
    local key = table.concat(parts, "|")
    if (key ~= regionsKey) then
        if (regionsRoot) then regionsRoot:kill() regionsRoot = nil end
        regionsKey = key
        if (key ~= "") then
            regionsRoot = UIElement:new({ globalid = globalid, pos = { 0, 0 }, size = { WIN_W, WIN_H } })
            for _, region in ipairs(regions) do
                local area = regionsRoot:addChild({ pos = { region.x, region.y }, size = { region.size, region.size } })
                tooltip(area, emojis[region.emoji].code)
            end
        end
    end
    if (root) then UIElement.drawVisuals(globalid) end
end)
add_hook("key_down", hook, function(key)
    if (not picker) then return end
    if (key == 27) then closePicker() return 1 end
    if (key == 13 or key == 271) then choose(keyboardIndex) return 1 end
    local movement = ({ [275] = 1, [276] = -1, [273] = -5, [274] = 5 })[key]
    if (movement) then
        keyboardIndex = (keyboardIndex - 1 + movement) % #emojis + 1
        for index, cell in ipairs(pickerCells) do cell.bgColor = index == keyboardIndex and TB_MENU_DEFAULT_LIGHTER_COLOR or TB_MENU_DEFAULT_DARKEST_COLOR end
        return 1
    end
end)
add_hook("resolution_changed", hook, reset)
add_hook("new_game", hook, reset)
add_hook("unload", hook, reset)
