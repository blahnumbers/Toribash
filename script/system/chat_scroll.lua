---Scrollbar for modern chat UI
---Adds a scrollbar to the new chat UI (as of 5.78)
---
---@author surge

---What `get_desktop_chat_scroll()` reports about the chat lines
---@class DesktopChatScrollState
---@field tab integer
---@field total integer Lines in the tab
---@field visible integer Lines that fit on screen
---@field offset integer First line shown
---@field x number
---@field y number
---@field h number

local HOOK_SET = "desktopChatScroll"
local GLOBAL_ID = 1023
local WIDTH = 12
local WHEEL_LINES = 3

---@type UIElement?
local scroll_root
---@type UIElement?
local thumb
---@type string?
local layout_key
---@type DesktopChatScrollState?
local scroll_state
---Where on the thumb it was grabbed, while it's being dragged
---@type number?
local grab_offset

local function destroy_scrollbar()
	if scroll_root then
		scroll_root:kill()
	end
	scroll_root, thumb, layout_key, scroll_state, grab_offset = nil, nil, nil, nil, nil
end

---Scrolls the chat so the thumb sits at `y`
---@param y number
local function scroll_to(y)
	if not scroll_state or not thumb then
		return
	end
	local track = thumb.parent
	local travel = track.size.h - thumb.size.h
	if travel <= 0 then
		return
	end
	local fraction = math.max(0, math.min(1, (y - track.pos.y - (grab_offset or thumb.size.h / 2)) / travel))
	set_desktop_chat_scroll(scroll_state.tab, math.floor(fraction * (scroll_state.total - scroll_state.visible) + 0.5))
end

---@param wheel number
local function scroll_by_wheel(wheel)
	set_desktop_chat_scroll(scroll_state.tab, scroll_state.offset - wheel * WHEEL_LINES)
end

---@param current DesktopChatScrollState
local function build_scrollbar(current)
	scroll_root = UIElement:new({ globalid = GLOBAL_ID, pos = { current.x, current.y }, size = { WIDTH, current.h } })
	local track = scroll_root:addChild({ size = { WIDTH, current.h }, interactive = true, scrollEnabled = true })
	local holder = scroll_root:addChild({ size = { 0, current.h } })
	thumb = TBMenu:spawnScrollBar(holder, current.total, current.h / current.visible)
	thumb:addMouseHandlers(
		function(button, x, y)
			if button < 4 then
				grab_offset = y - thumb.pos.y
			else
				scroll_by_wheel(y)
			end
		end,
		function()
			grab_offset = nil
		end,
		function(x, y)
			if grab_offset then
				scroll_to(y)
			end
		end,
		nil,
		function()
			grab_offset = nil
		end
	)
	track:addMouseDownHandler(function(button, x, y)
		if button < 4 then
			scroll_to(y)
		else
			scroll_by_wheel(y)
		end
	end)
end

local function on_pre_draw()
	local current = get_desktop_chat_scroll()
	if
		not current
		or current.total <= current.visible
		or current.h <= 10
		or TB_MENU_MAIN_ISOPEN == 1
		or TB_MENU_SPECIAL_SCREEN_ISOPEN == 1
	then
		destroy_scrollbar()
		return
	end

	local key = table.concat({ current.tab, current.total, current.visible, current.x, current.y, current.h }, ":")
	if key ~= layout_key then
		destroy_scrollbar()
		layout_key = key
		build_scrollbar(current)
	end

	scroll_state = current
	local travel = thumb.parent.size.h - thumb.size.h
	thumb:moveTo(nil, travel * math.max(0, current.offset) / (current.total - current.visible))
	scroll_root:updatePos()
end

local function on_draw2d()
	if scroll_root then
		UIElement.drawVisuals(GLOBAL_ID)
	end
end

---The mouse wheel over the chat lines scrolls them, unless the emoji picker or command reference is in the way
---@param button integer
---@return integer?
local function on_mouse_button_down(button)
	if not scroll_state or (button ~= 4 and button ~= 5) or TB_CHAT_EMOJI_PICKER_OPEN then
		return
	end
	if
		MOUSE_X < 0
		or MOUSE_X >= scroll_state.x
		or MOUSE_Y < scroll_state.y
		or MOUSE_Y > scroll_state.y + scroll_state.h
	then
		return
	end

	local reference = TB_CHAT_REFERENCE
	if
		reference
		and MOUSE_X >= reference.pos.x
		and MOUSE_X <= reference.pos.x + reference.size.w
		and MOUSE_Y >= reference.pos.y
		and MOUSE_Y <= reference.pos.y + reference.size.h
	then
		return
	end

	set_desktop_chat_scroll(scroll_state.tab, scroll_state.offset + (button == 4 and -WHEEL_LINES or WHEEL_LINES))
	return 1
end

add_hook("pre_draw", HOOK_SET, on_pre_draw)
add_hook("draw2d", HOOK_SET, on_draw2d)
add_hook("mouse_button_down", HOOK_SET, on_mouse_button_down)
add_hook("resolution_changed", HOOK_SET, destroy_scrollbar)
add_hook("new_game", HOOK_SET, destroy_scrollbar)
add_hook("unload", HOOK_SET, destroy_scrollbar)
