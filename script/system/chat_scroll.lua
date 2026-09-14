-- Reuse the menu scrollbar thumb while the native chat owns the history and offset.
local root, thumb, signature, state, grab
local hook, globalid = "desktopChatScroll", 1023
local function destroy()
    if (root) then root:kill() end
    root, thumb, signature, state, grab = nil, nil, nil, nil, nil
end
local function move(y)
    if (not state or not thumb) then return end
    local track = thumb.parent
    local travel = track.size.h - thumb.size.h
    if (travel <= 0) then return end
    local fraction = math.max(0, math.min(1, (y - track.pos.y - (grab or thumb.size.h / 2)) / travel))
    set_desktop_chat_scroll(state.tab, math.floor(fraction * (state.total - state.visible) + 0.5))
end
add_hook("pre_draw", hook, function()
    local current = get_desktop_chat_scroll()
    if (not current or current.total <= current.visible or current.h <= 10
        or TB_MENU_MAIN_ISOPEN == 1 or TB_MENU_SPECIAL_SCREEN_ISOPEN == 1) then destroy() return end
    local key = table.concat({ current.tab, current.total, current.visible, current.x, current.y, current.h }, ":")
    if (key ~= signature) then
        destroy()
        signature = key
        root = UIElement:new({ globalid = globalid, pos = { current.x, current.y }, size = { 12, current.h } })
        local track = root:addChild({ size = { 12, current.h }, interactive = true, scrollEnabled = true })
        local holder = root:addChild({ size = { 0, current.h } })
        thumb = TBMenu:spawnScrollBar(holder, current.total, current.h / current.visible)
        thumb:addMouseHandlers(function(button, x, y)
            if (button < 4) then grab = y - thumb.pos.y
            else set_desktop_chat_scroll(state.tab, state.offset - y * 3) end
        end, function() grab = nil end, function(x, y)
            if (grab) then move(y) end
        end, nil, function() grab = nil end)
        track:addMouseDownHandler(function(button, x, y)
            if (button < 4) then move(y)
            else set_desktop_chat_scroll(state.tab, state.offset - y * 3) end
        end)
    end
    state = current
    local travel = thumb.parent.size.h - thumb.size.h
    thumb:moveTo(nil, travel * math.max(0, current.offset) / (current.total - current.visible))
    root:updatePos()
end)
add_hook("draw2d", hook, function() if (root) then UIElement.drawVisuals(globalid) end end)
add_hook("resolution_changed", hook, destroy)
add_hook("new_game", hook, destroy)
add_hook("unload", hook, destroy)
