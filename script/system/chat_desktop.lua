---Tabs for modern chat UI
---Draws the chat tabs and loads the other modern chat UI scripts (as of 5.78)
---
---@author surge

---What `get_desktop_chat_tabs()` reports about one tab
---@class DesktopChatTab
---@field id integer
---@field name string
---@field username string The other player, for a whisper tab
---@field selected boolean
---@field whisper boolean
---@field closable boolean
---@field unread integer
---@field x number
---@field y number
---@field w number
---@field h number

---The elements kept for each tab, recoloured every frame
---@class DesktopChatTabView
---@field button UIElement
---@field label UIElement
---@field close_icon UIElement?
---@field room_icon UIElement?
---@field avatar_objects UIElement3D[]?
---@field avatar_alphas number[]
---@field pop_at number When the unread badge last popped
---@field unread integer?
---@field selected boolean?

if not get_desktop_chat_tabs or is_mobile() then
	return
end

require("toriui.uielement3d")
if get_desktop_chat_emojis then
	require("system.chat_emoji")
end
if get_desktop_chat_completions then
	require("system.chat_completion")
end
if get_desktop_chat_scroll then
	require("system.chat_scroll")
end

local HOOK_SET = "desktopChatTabs"
local GLOBAL_ID = 1020
local MAX_TABS = 8
local BASE_TAB_HEIGHT = 38
---Seconds an unread badge's pop takes to settle
local BADGE_POP_TIME = 0.4
local CLOSE_TEXTURE = "../textures/menu/general/buttons/crosswhite.tga"

local SELECTED_COLOUR = TB_MENU_DEFAULT_DARKER_COLOR
local SELECTED_TEXT_COLOUR = TB_MENU_UI_TEXT_COLOR
local TAB_COLOUR = TB_MENU_DEFAULT_INACTIVE_COLOR
local TAB_HOVER_COLOUR = TB_MENU_DEFAULT_LIGHTEST_COLOR
local TEXT_COLOUR = get_color_rgba(COLORS.GREY)
TEXT_COLOUR[4] = 1
---An unread tab keeps its grey background, but its name goes darker
local UNREAD_TEXT_COLOUR = { 0.12, 0.12, 0.12, 1 }

---@type UIElement?
local tabs_root
---@type string?
local layout_key
---@type table<integer, DesktopChatTabView>
local tab_views = {}

local function destroy_tabs()
	if tabs_root then
		tabs_root:kill()
		tabs_root = nil
	end
	tab_views, layout_key = {}, nil
end

---A whisper tab gets the other player's head, any other tab the room icon
---@param button UIElement
---@param tab DesktopChatTab
---@param scale number
---@param view DesktopChatTabView
local function add_tab_icon(button, tab, scale, view)
	-- Centred in the 50 px slot on the left of the tab
	local avatar_size = (tab.whisper and 32 or 24) * scale
	local avatar_holder = button:addChild({
		pos = { (50 * scale - avatar_size) / 2, (tab.h - avatar_size) / 2 },
		size = { avatar_size, avatar_size },
	})
	if not tab.whisper then
		view.room_icon = avatar_holder:addChild({ shift = { 0, 0 }, bgImage = TB_MENU_FRIENDS_BUTTON, imageColor = TEXT_COLOUR })
		return
	end

	local avatar = TBMenu:showPlayerHeadAvatar(avatar_holder, tab.username)
	avatar.rootHolder:resetRotation()
	-- Zooms in on the head and its items together
	avatar.rootHolder:moveTo(0, -0.6, 0)
	if avatar.avatarObjects[2] then
		avatar.avatarObjects[2]:hide(true)
	end
	view.avatar_objects = avatar.avatarObjects
	for index, object in ipairs(view.avatar_objects) do
		view.avatar_alphas[index] = object.bgColor[4]
	end
end

---The unread count on the icon's top right corner, which pops when the count goes up. It's an orange circle,
---or a pill once it needs two digits
---@param button UIElement
---@param tab DesktopChatTab
---@param scale number
---@param view DesktopChatTabView
local function add_unread_badge(button, tab, scale, view)
	local badge = button:addChild({ pos = { 0, 0 }, size = { tab.w, tab.h } })
	badge:addCustomDisplay(false, function()
		if not view.unread or view.unread <= 0 or view.selected then
			return
		end
		local text = tostring(view.unread)
		local text_width = get_string_length(text, FONTS.MEDIUM) * 0.6
		local w, h = math.max(18 * scale, text_width + 8 * scale), 18 * scale
		local centre_x, centre_y = badge.pos.x + 47 * scale - w / 2, badge.pos.y + scale + h / 2
		local pop_left = math.max(0, math.min(1, 1 - (UIElement.clock - view.pop_at) / BADGE_POP_TIME))
		local pop_scale = 1 + 0.35 * pop_left * pop_left
		w, h = w * pop_scale, h * pop_scale
		local x, y, r = centre_x - w / 2, centre_y - h / 2, h / 2

		set_color(TB_MENU_DEFAULT_ORANGE[1], TB_MENU_DEFAULT_ORANGE[2], TB_MENU_DEFAULT_ORANGE[3], 1)
		draw_quad(x + r, y, w - 2 * r, h)
		draw_disk(x + r, y + r, 0, r, 24, 1, -180, 180, 0)
		draw_disk(x + w - r, y + r, 0, r, 24, 1, 0, 180, 0)
		set_color(0, 0, 0, 1)
		draw_text_angle_scale(
			text,
			centre_x - text_width * pop_scale / 2,
			centre_y - 24 * 0.6 * pop_scale / 2,
			0,
			0.6 * pop_scale,
			FONTS.MEDIUM
		)
	end)
end

---@param tab DesktopChatTab
---@return DesktopChatTabView
local function build_tab(tab)
	local scale = tab.h / BASE_TAB_HEIGHT
	local button = tabs_root:addChild({
		pos = { tab.x, tab.y },
		size = { tab.w, tab.h },
		interactive = true,
		shapeType = ROUNDED,
		rounded = 7 * scale,
		bgColor = TAB_COLOUR,
		hoverColor = TAB_HOVER_COLOUR,
		pressedColor = SELECTED_COLOUR,
	})
	button:addMouseUpHandler(function()
		select_desktop_chat_tab(tab.id)
	end)

	---@type DesktopChatTabView
	local view = { button = button, avatar_alphas = {}, pop_at = -1e9 }
	add_tab_icon(button, tab, scale, view)

	local name = tab.whisper and tab.username or tab.name
	if name == "" then
		name = "Game"
	end
	local right_space = tab.closable and 44 * scale or 10 * scale
	view.label = button:addChild({
		pos = { 50 * scale, 0 },
		size = { math.max(4, tab.w - 50 * scale - right_space), tab.h },
		uiColor = TEXT_COLOUR,
	})
	view.label:addAdaptedText(false, name, nil, nil, FONTS.MEDIUM, LEFTMID, 0.85, 0.85)

	if tab.closable then
		local close = button:addChild({ pos = { -34 * scale, 0 }, size = { 24 * scale, tab.h }, interactive = true })
		view.close_icon = close:addChild({
			pos = { 5 * scale, (tab.h - 14 * scale) / 2 },
			size = { 14 * scale, 14 * scale },
			bgImage = CLOSE_TEXTURE,
			imageColor = TEXT_COLOUR,
		})
		close:addMouseUpHandler(function()
			close_chat_tab(tab.id)
		end)
	end

	add_unread_badge(button, tab, scale, view)
	return view
end

---@param tabs table<integer, DesktopChatTab>
---@param key string
local function build_tabs(tabs, key)
	destroy_tabs()
	layout_key = key
	tabs_root = UIElement:new({ globalid = GLOBAL_ID, pos = { 0, 0 }, size = { WIN_W, WIN_H } })
	for i = 1, MAX_TABS do
		if tabs[i] then
			tab_views[i] = build_tab(tabs[i])
		end
	end
end

---Changes only when a tab is added, closed, renamed, moved or resized
---@param tabs table<integer, DesktopChatTab>
---@return string
local layout_values, layout_values_key = {}, nil
local function get_layout_key(tabs)
	-- Same tabs with the same values as last time: same key, without building it again
	local v = layout_values
	if layout_values_key then
		local same, n = true, 0
		for i = 1, MAX_TABS do
			local tab = tabs[i]
			if tab then
				local base = n * 9
				if v[base + 1] ~= i or v[base + 2] ~= tab.name or v[base + 3] ~= tab.whisper or v[base + 4] ~= tab.closable
					or v[base + 5] ~= tab.x or v[base + 6] ~= tab.y or v[base + 7] ~= tab.w or v[base + 8] ~= tab.h then
					same = false
					break
				end
				n = n + 1
			end
		end
		if same and n == v.count then
			return layout_values_key
		end
	end
	local n = 0
	for i = 1, MAX_TABS do
		local tab = tabs[i]
		if tab then
			local base = n * 9
			v[base + 1], v[base + 2], v[base + 3], v[base + 4] = i, tab.name, tab.whisper, tab.closable
			v[base + 5], v[base + 6], v[base + 7], v[base + 8] = tab.x, tab.y, tab.w, tab.h
			n = n + 1
		end
	end
	v.count = n
	local parts = {}
	for i = 1, MAX_TABS do
		local tab = tabs[i]
		if tab then
			parts[#parts + 1] = table.concat({
				i,
				tab.name,
				tostring(tab.whisper),
				tostring(tab.closable),
				tab.x,
				tab.y,
				tab.w,
				tab.h,
			}, ":")
		end
	end
	layout_values_key = table.concat(parts, "|")
	return layout_values_key
end

---@param view DesktopChatTabView
---@param tab DesktopChatTab
local function update_tab_colours(view, tab)
	view.button.bgColor = tab.selected and SELECTED_COLOUR or TAB_COLOUR
	view.button.hoverColor = tab.selected and TB_MENU_DEFAULT_BG_COLOR or TAB_HOVER_COLOUR

	local text_colour = tab.selected and SELECTED_TEXT_COLOUR or (tab.unread > 0 and UNREAD_TEXT_COLOUR or TEXT_COLOUR)
	view.label.uiColor = text_colour
	if view.close_icon then
		view.close_icon.imageColor = text_colour
	end
	if view.room_icon then
		view.room_icon.imageColor = text_colour
	end
	for index, object in ipairs(view.avatar_objects or {}) do
		object.bgColor[4] = view.avatar_alphas[index] * ((tab.selected or tab.unread > 0) and 1 or 0.85)
	end
end

local function on_pre_draw()
	local is_enabled = get_option("legacychat") ~= 1
		and TB_MENU_MAIN_ISOPEN ~= 1
		and TB_MENU_SPECIAL_SCREEN_ISOPEN ~= 1
	---@type table<integer, DesktopChatTab>?
	local tabs = get_desktop_chat_tabs(is_enabled)
	if not is_enabled or not tabs or next(tabs) == nil then
		destroy_tabs()
		return
	end

	local key = get_layout_key(tabs)
	if layout_key ~= key then
		build_tabs(tabs, key)
	end

	for i, view in pairs(tab_views) do
		local tab = tabs[i]
		update_tab_colours(view, tab)
		-- No pop for messages that were already unread when the tab appeared
		if view.unread and tab.unread > view.unread then
			view.pop_at = UIElement.clock
		end
		view.unread, view.selected = tab.unread, tab.selected
	end
end

local function on_draw2d()
	if tabs_root then
		UIElement.drawVisuals(GLOBAL_ID)
	end
end

-- Viewports draw before draw2d, which is where UIElement normally moves children into place
local function on_draw_viewport()
	if tabs_root then
		tabs_root:updatePos()
		UIElement3D.drawViewport(GLOBAL_ID)
	end
end

local function on_unload()
	destroy_tabs()
	get_desktop_chat_tabs(false)
end

add_hook("pre_draw", HOOK_SET, on_pre_draw)
add_hook("draw2d", HOOK_SET, on_draw2d)
add_hook("draw_viewport", HOOK_SET, on_draw_viewport)
add_hook("resolution_changed", HOOK_SET, destroy_tabs)
add_hook("new_game", HOOK_SET, destroy_tabs)
add_hook("unload", HOOK_SET, on_unload)
