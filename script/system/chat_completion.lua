-- Read-only command reference; native Tab completion is independent of these rows.
if (not set_desktop_chat_reference) then return end -- Older test executables keep native completion.
local catalogue = require("system.chat_commands")
local globalid, hook = 1022, "desktopChatReference"
local root, draftKey, renderedKey, changedAt, dismissedText, request = nil, nil, nil, 0, nil, 0
local forced = false
local function destroy()
    if (root) then root:kill() root = nil end
    TB_CHAT_REFERENCE = nil
    renderedKey = nil
    set_desktop_chat_reference(false, false)
end
local function reset()
    destroy()
    draftKey, dismissedText, forced = nil, nil, false
end
local function matches(input, entries)
    local typed = input.text:match("^/([^ ]+)")
    if (not typed) then
        if (not forced or input.text ~= "/") then return {} end
        typed = ""
    end
    local args = input.text:match("^/[^ ]+ +(.*)")
    local canonical = input.command or typed
    local player = QueueList and QueueList:getCurrentPlayerInfo()
    local online = get_world_state().game_type == 1
    local operator = not online or (player and (player.op or player.admin))
    local rows, seen, covered = {}, {}, {}
    local function add(text)
        if (not seen[text]) then rows[#rows + 1] = text seen[text] = true end
    end
    for _, usage in ipairs(catalogue) do
        local names = type(usage.cmd) == "table" and usage.cmd or { usage.cmd }
        local found = false
        for _, name in ipairs(names) do
            if (args ~= nil) then found = found or name == canonical or name == typed
            else
                found = found or name:sub(1, #typed) == typed or name == canonical
                for _, entry in ipairs(entries) do
                    if (entry.text == name and entry.alias == typed) then found = true end
                end
            end
        end
        if (found) then
            for _, name in ipairs(names) do covered[name] = true end
            if ((not usage.requireOnline or online) and (not usage.requireOperator or operator)
                and (not usage.requireFighter or (player and player.is_fighter))) then
                if (args == nil or args == "" or forced) then add(usage.info) end
            end
        end
    end
    for _, entry in ipairs(entries) do
        if (args ~= nil or not covered[entry.text]) then
            local privileged = entry.help == "Requires room permissions"
            if (not privileged or operator) then
                local command = args ~= nil and entry.text or "/" .. entry.text
                add(command .. (entry.help ~= "" and " %125- " .. entry.help or ""))
            end
        end
    end
    return rows
end
add_hook("pre_draw", hook, function()
    local input = get_desktop_chat_input()
    if (not input or not input.visible or not input.skin or TB_CHAT_EMOJI_PICKER_OPEN
        or TB_MENU_MAIN_ISOPEN == 1 or TB_MENU_SPECIAL_SCREEN_ISOPEN == 1) then reset() return end
    local key = input.text .. "|" .. input.caret
    if (key ~= draftKey) then
        destroy()
        if (dismissedText ~= input.text) then dismissedText = nil end
        draftKey, changedAt, forced = key, UIElement.clock, false
    end
    if (input.request ~= request) then
        request, forced, dismissedText = input.request, true, nil
    end
    if (dismissedText == input.text or (not forced and UIElement.clock - changedAt < 0.5)) then return end
    local entries = get_desktop_chat_completions() or {}
    local rows = matches(input, entries)
    if (#rows == 0) then destroy() return end
    local signature = table.concat(rows, "|") .. input.x .. ":" .. input.y .. ":" .. input.w .. ":" .. input.h
    if (signature == renderedKey) then return end
    destroy()
    renderedKey = signature
    local font = input.font or FONTS.SMALL
    local width = input.w + input.h / 34 * 38
    local wrapped, rowHeight = {}, 34
    for i, text in ipairs(rows) do
        wrapped[i] = textAdapt(text, font, 1, math.max(30, width - 44))
        rowHeight = math.max(rowHeight, #wrapped[i] * 21 + 12)
    end
    local height = math.min(#rows, 6) * rowHeight + 8
    height = math.min(height, input.y - 8)
    root = UIElement:new({ globalid = globalid, pos = { input.x, input.y - height }, size = { width, height }, bgColor = TB_MENU_DEFAULT_BG_COLOR })
    local reload, _, _, _, list = TBMenu:prepareScrollableList(root, 4, 4, 12, TB_MENU_DEFAULT_BG_COLOR)
    local elements = {}
    for i, lines in ipairs(wrapped) do
        local holder = list:addChild({ pos = { 0, (i - 1) * rowHeight }, size = { list.size.w, rowHeight } })
        local row = holder:addChild({ pos = { 6, 2 }, size = { holder.size.w - 6, rowHeight - 4 }, shapeType = ROUNDED, rounded = 4, bgColor = TB_MENU_DEFAULT_DARKER_COLOR, uiColor = TB_MENU_UI_TEXT_COLOR })
        local color = ""
        for j, line in ipairs(lines) do
            local label = row:addChild({ pos = { 10, 4 + (j - 1) * 21 }, size = { row.size.w - 20, 21 }, uiColor = TB_MENU_UI_TEXT_COLOR })
            local text = color .. line
            label:addCustomDisplay(false, function() label:uiText(text, nil, nil, font, LEFTMID, 1) end)
            for code in line:gmatch("[%^%%]%d%d+") do color = code end
        end
        holder:hide()
        elements[#elements + 1] = holder
    end
    local bar = TBMenu:spawnScrollBar(list, #elements, rowHeight)
    bar:makeScrollBar(list, elements, reload)
    TB_CHAT_REFERENCE = root -- (chat_scroll.lua: the wheel over it scrolls it, not the chat)
    set_desktop_chat_reference(true, false)
end)
add_hook("key_down", hook, function(key)
    if (key == 27 and root) then
        local input = get_desktop_chat_input()
        destroy()
        dismissedText = input and input.text
        set_desktop_chat_reference(false, true)
        return 1
    end
end)
add_hook("draw2d", hook, function() if (root) then UIElement.drawVisuals(globalid) end end)
add_hook("resolution_changed", hook, reset)
add_hook("new_game", hook, reset)
add_hook("unload", hook, reset)
