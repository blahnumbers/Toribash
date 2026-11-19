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
---@field name string
---@field username string? The other player, for a whisper tab
---@field named boolean The open tab, unless it's the room, which shows its name and close button
---@field x number Where the tab is drawn now, which trails its place for a moment after the bar is laid out again
---@field slide_from number? Where the tab slides from
---@field slide_at number? When it started to
---@field reveal_at number? When the name and close button started to fade in
---@field reveal number Opacity of the name and close button
---@field label UIElement?
---@field close UIElement?
---@field pill UIElement? The red disc behind the open tab's head
---@field disc UIElement? The room icon's disc, or the grey disc behind a head
---@field room_icon UIElement?
---@field letter_disc UIElement? The disc with an initial, for a tab with no head to show
---@field letter UIElement?
---@field head DesktopChatHead? The player's head, for a whisper tab that shows one
---@field head_over number? How far the head's box hangs over the tab on each side
---@field tip DesktopChatTabTip?
---@field pop_at number When the unread badge last popped
---@field unread integer?
---@field selected boolean?

---A player's head. Kept while they have a tab, however often the bar is laid out again: loading a head texture
---takes long enough to stall a frame
---@class DesktopChatHead
---@field holder UIElement
---@field viewport UIElement
---@field objects UIElement3D[] The parts that are shown, dimmed with their tab
---@field x number?
---@field y number?
---@field size number?

---The name shown above a tab the mouse rests on
---@class DesktopChatTabTip
---@field popup UIElement
---@field since number? When the mouse came to rest on the tab
---@field held boolean Kept back until the mouse leaves, after a press
---@field shown boolean

if not get_desktop_chat_tabs or is_mobile() then
	return
end

require("toriui.uielement3d")
-- Hooks run in the order they're added, so what's required later draws on top: the scrollbar goes first,
-- under the emoji picker and the command list
if get_desktop_chat_scroll then
	require("system.chat_scroll")
end
if get_desktop_chat_emojis then
	require("system.chat_emoji")
end
if get_desktop_chat_completions then
	require("system.chat_completion")
end

local HOOK_SET = "desktopChatTabs"
local GLOBAL_ID = 1020
local MAX_TABS = 8
local BASE_TAB_HEIGHT = 26
---Tab names use the same plain font as list rows elsewhere in the menus
local TAB_FONT = FONTS.LMEDIUM
local TAB_TEXT_SCALE = 0.62
---Seconds an unread badge's pop takes to settle
local BADGE_POP_TIME = 0.4
---Seconds a tab takes to slide to its new place when the bar is laid out again, and the open tab's name to fade in.
---Short enough that it never holds a click back: tabs take clicks where they are drawn all the way
local SLIDE_TIME = 0.09
---Seconds the mouse rests on a tab before its name shows, as the menus' popups do
local TOOLTIP_DELAY = 0.3

local RED = TB_MENU_DEFAULT_BG_COLOR
---The open tab's name, a darker shade of the menus' red so it reads on the light default scene
local NAME_RED = { 0.56, 0.09, 0.09, 1 }
local CLOSE_GREY = { 0.6, 0.6, 0.6, 1 }
local CLOSE_HOVER_GREY = { 0.53, 0.53, 0.53, 1 }
local CLOSE_PRESSED_GREY = { 0.47, 0.47, 0.47, 1 }
local WHITE = { 1, 1, 1, 1 }
---The room icon's disc when another chat is open, and the disc a head sits on
local ROOM_IDLE_COLOUR = TB_MENU_DEFAULT_INACTIVE_COLOR
local ROOM_IDLE_ICON = { 0.24, 0.24, 0.24, 1 }
local HEAD_DISC_COLOUR = { 0.74, 0.74, 0.74, 1 }
---A chat with nothing new is dimmed: the room icon fades, a head fades over its grey disc
local IDLE_ROOM_ALPHA = 0.7
local IDLE_HEAD_ALPHA = 0.55
---Hovered tabs darken by this, pressed ones by the second
local HOVER_SHADE, PRESS_SHADE = 0.85, 0.72

---@type UIElement?
local tabs_root
---@type UIElement?
local heads_root
---@type table<string, DesktopChatHead>
local heads = {}
---Whether this client has the draw2d_under pass, which draws the bar under the rest of the Lua UI and the badges
---over the heads. Older clients draw the bar in the usual passes
local has_under_pass = false
local under_pass_hooked = false
---Screen pixels per unit of the UI's coordinates (the high DPI setting)
local dpi = 1
---Where and when a tab was last pressed: a tab built under the mouse right after a press (the bar is laid out again
---when the open chat changes) keeps its tooltip back until the mouse leaves it
local last_press = { x = -1, y = -1, clock = -1e9 }
---@type string?
local layout_key
---@type table<integer, DesktopChatTabView>
local tab_views = {}
---Whether each player has a head texture to show, looked up once: it takes reading their item file
---@type table<string, boolean>
local head_textures = {}
---Set when a download finished: a whisper's head may have arrived
local heads_stale = false

local on_draw2d_under

---The client only runs the draw2d_under pass while a script listens to it, so the bar only listens while it's there
---@param hooked boolean
local function set_under_pass_hooked(hooked)
	if not has_under_pass or under_pass_hooked == hooked then
		return
	end
	under_pass_hooked = hooked
	if hooked then
		add_hook("draw2d_under", HOOK_SET, on_draw2d_under)
	else
		remove_hook("draw2d_under", HOOK_SET)
	end
end

---Takes the bar down. The heads stay loaded for when it's back (a menu was opened, the HUD hidden) unless told not to
---@param with_heads boolean?
local function destroy_tabs(with_heads)
	if tabs_root then
		tabs_root:kill()
		tabs_root = nil
	end
	tab_views, layout_key = {}, nil
	if with_heads and heads_root then
		heads_root:kill()
		heads_root, heads = nil, {}
	end
	set_under_pass_hooked(false)
end

---To the nearest screen pixel
---@param value number
---@return number
local function snap(value)
	return math.floor(value * dpi + 0.5) / dpi
end

---A rectangle with fully round ends, in the current colour
local function draw_pill(x, y, w, h)
	local r = h / 2
	if w > h then
		draw_quad(x + r, y, w - h, h)
	end
	draw_disk(x + r, y + r, 0, r, 24, 1, -180, 180, 0)
	draw_disk(x + w - r, y + r, 0, r, 24, 1, 0, 180, 0)
end

---Whether the player wears a head texture that's on disk; without one their head is the same plain ball as
---everyone else's
---@param username string
---@return boolean
local function has_head_texture(username)
	local known = head_textures[username]
	if known == nil then
		local ok, items = pcall(PlayerInfo.getItems, PlayerInfo, username, PLAYERINFO_CSCOPE_TEXTURES)
		known = ok and items ~= nil and items.textures ~= nil and items.textures.head ~= nil
			and items.textures.head.equipped == true
		if known then
			-- Their items can say so before the texture itself has been downloaded
			local exists
			ok, exists = pcall(Files.Exists, "../custom/" .. username .. "/head.tga")
			known = ok and exists == true
		end
		head_textures[username] = known
	end
	return known
end

---The box a head is drawn in, for a tab at x. Whole screen pixels on every side: the viewport is placed in whole
---pixels, and a part of a pixel left the head off centre on its disc. The client cuts the box's edges down to whole
---pixels, so each is nudged a quarter pixel to the side that can't lose one to rounding
---@param x number
---@param tab DesktopChatTab
---@param over number
---@return number x
---@return number y
---@return number size
local function get_head_box(x, tab, over)
	return snap(x) - over + 0.25 / dpi, snap(tab.y) - over - 0.5 / dpi, snap(tab.h) + 2 * over + 0.25 / dpi
end

---A whisper's head: its head texture only, items left out so every head is the same size
---@param username string
---@return DesktopChatHead
local function get_head(username)
	local head = heads[username]
	if head then
		return head
	end
	heads_root = heads_root or UIElement:new({ globalid = GLOBAL_ID, pos = { 0, 0 }, size = { WIN_W, WIN_H } })
	local holder = heads_root:addChild({ pos = { 0, 0 }, size = { BASE_TAB_HEIGHT, BASE_TAB_HEIGHT } })
	local avatar = TBMenu:showPlayerHeadAvatar(holder, username)
	avatar.rootHolder:resetRotation()
	avatar.rootHolder:moveTo(0, -0.6, 0)
	head = { holder = holder, viewport = avatar, objects = {} }
	local ball = avatar.avatarObjects[1]
	if ball then
		-- An item can replace the head ball; with items left out the ball has to show
		ball.bgColor[4] = 1
		table.insert(head.objects, ball)
	end
	for i = 2, #avatar.avatarObjects do
		avatar.avatarObjects[i]:hide(true)
	end
	heads[username] = head
	return head
end

---@param head DesktopChatHead
---@param x number
---@param y number
---@param size number
local function place_head(head, x, y, size)
	if head.x == x and head.y == y and head.size == size then
		return
	end
	head.x, head.y, head.size = x, y, size
	-- The avatar's viewport fills its holder from the holder's far corner
	head.holder.size.w, head.holder.size.h = size, size
	head.viewport.size.w, head.viewport.size.h = size, size
	head.viewport.shift.x, head.viewport.shift.y = -size, -size
	head.holder:moveTo(x, y)
end

---The unread count on the head's top right corner, the menus' yellow with near-black figures, which pops when the
---count goes up
---@param view DesktopChatTabView
---@param scale number
local function draw_badge(view, scale)
	if not view.unread or view.unread <= 0 or view.selected then
		return
	end
	local button = view.button
	local text = view.unread > 9 and "9+" or tostring(view.unread)
	local text_scale = 0.5
	local text_width = get_string_length(text, TAB_FONT) * text_scale
	local h = 16 * scale
	local w = math.max(h, text_width + 9 * scale)
	local pop_left = math.max(0, math.min(1, 1 - (UIElement.clock - view.pop_at) / BADGE_POP_TIME))
	local pop_scale = 1 + 0.3 * pop_left * pop_left
	local centre_x, centre_y = button.pos.x + button.size.h - 3 * scale, button.pos.y + 3 * scale
	w, h = w * pop_scale, h * pop_scale
	local x, y = centre_x - w / 2, centre_y - h / 2

	set_color(TB_MENU_DEFAULT_YELLOW[1], TB_MENU_DEFAULT_YELLOW[2], TB_MENU_DEFAULT_YELLOW[3], 1)
	draw_pill(x, y, w, h)
	set_color(0.1, 0.1, 0, 1)
	draw_text_angle_scale(text, centre_x - text_width * pop_scale / 2, centre_y - 24 * text_scale * pop_scale / 2,
		0, text_scale * pop_scale, TAB_FONT)
end

---The tab's name above it while the mouse rests on it, in the menus' own hover popup; the open tab shows its name
---already and gets none. The popup is the menus', but shown from here: only while the tab itself is under the
---mouse (not a window on top of it), on top of the heads and badges, and not right after a press
---@param view DesktopChatTabView
---@param old DesktopChatTabView? The same tab before the bar was laid out again
local function add_tooltip(view, old)
	local button = view.button
	local popup = TBMenu:displayPopup(button, view.name, true)
	if popup == nil then
		return
	end
	-- The popup's own display loop goes by where the mouse is alone
	button.customDisplayBefore = nil
	local pressed_here = UIElement.clock - last_press.clock < 1
		and last_press.x >= button.pos.x and last_press.x <= button.pos.x + button.size.w
		and last_press.y >= button.pos.y and last_press.y <= button.pos.y + button.size.h
	view.tip = {
		popup = popup,
		since = old and old.tip and old.tip.since or nil,
		held = pressed_here or (old ~= nil and old.tip ~= nil and old.tip.held),
		shown = false,
	}
end

---Centred above the tab, kept inside the window
---@param view DesktopChatTabView
local function place_tooltip(view)
	local button, popup = view.button, view.tip.popup
	local safe_x, _, safe_w = get_window_safe_size()
	local margin = math.max(safe_x, WIN_W - safe_x - safe_w, 4)
	local left = button.pos.x + (button.size.w - popup.size.w) / 2
	left = math.max(margin, math.min(left, WIN_W - margin - popup.size.w))
	-- A negative position is counted from the tab's right or bottom edge
	local shift_x = left - button.pos.x
	popup:moveTo(shift_x >= 0 and shift_x or shift_x - button.size.w, -button.size.h - popup.size.h - 5)
	popup:updatePos()
end

---@param view DesktopChatTabView
local function update_tooltip(view)
	local tip = view.tip
	if not tip then
		return
	end
	local state = view.button.hoverState
	if state == BTN_NONE or TB_MENU_POPUPS_DISABLED then
		tip.since, tip.held, tip.shown = nil, false, false
		return
	end
	if state == BTN_DN then
		tip.held = true
	end
	tip.since = tip.since or UIElement.clock
	local shown = not tip.held and UIElement.clock - tip.since >= TOOLTIP_DELAY
	if shown and not tip.shown then
		place_tooltip(view)
	end
	tip.shown = shown
end

---@param tab DesktopChatTab
---@param old DesktopChatTabView? The same tab before the bar was laid out again
---@param interactive UIElement[] Collects the tab's buttons
---@return DesktopChatTabView
local function build_tab(tab, old, interactive)
	local scale = tab.h / BASE_TAB_HEIGHT
	local is_room = tab.id == 0
	-- As the client lays the tabs out: the open tab is wide enough for its name unless it's the room
	local named = tab.selected and not is_room
	local name = tab.whisper and tab.username or tab.name
	if name == "" then
		name = "Game"
	end
	-- A slot is used again once its chat is closed: only the same chat carries anything over
	if old and old.name ~= name then
		old = nil
	end
	local button = tabs_root:addChild({
		pos = { tab.x, tab.y },
		size = { tab.w, tab.h },
		interactive = true,
		bgColor = { 0, 0, 0, 0 },
	})
	button:addMouseHandlers(function()
		last_press.x, last_press.y, last_press.clock = MOUSE_X, MOUSE_Y, UIElement.clock
	end, function()
		select_desktop_chat_tab(tab.id)
	end)
	table.insert(interactive, button)

	---@type DesktopChatTabView
	local view = {
		button = button, name = name, username = tab.whisper and tab.username or nil, named = named,
		x = tab.x, reveal = 1, pop_at = old and old.pop_at or -1e9, unread = old and old.unread or nil,
		selected = tab.selected,
	}
	if named then
		-- The open tab: its head on a red disc, like the room icon when the room is open, and its name beside it
		view.pill = button:addChild({
			pos = { 0, 0 }, size = { tab.h, tab.h }, shapeType = ROUNDED, rounded = tab.h / 2, bgColor = table.clone(RED),
		})
	end

	local has_head = tab.whisper and has_head_texture(tab.username)
	if is_room then
		view.disc = button:addChild({
			pos = { 0, 0 }, size = { tab.h, tab.h }, shapeType = ROUNDED, rounded = tab.h / 2, bgColor = { 1, 1, 1, 1 },
		})
		local icon = 16 * scale
		view.room_icon = view.disc:addChild({
			pos = { (tab.h - icon) / 2, (tab.h - icon) / 2 }, size = { icon, icon },
			bgImage = TB_MENU_FRIENDS_BUTTON, imageColor = { 1, 1, 1, 1 },
		})
	elseif has_head then
		if not named then
			-- A pixel smaller than the head, so none of it shows round the edge
			local disc = tab.h - 2 * scale
			view.disc = button:addChild({
				pos = { scale, scale }, size = { disc, disc }, shapeType = ROUNDED, rounded = disc / 2, bgColor = HEAD_DISC_COLOUR,
			})
		end
		-- The head ball fills 5/6 of its avatar box, so a box about 1.15 times the tab makes the head just cover its grey disc.
		-- A larger box rather than a closer camera, which would bulge the head. It hangs over the tab's edges
		-- The open tab's head is drawn in a box the size of the tab, which leaves an even edge of its red disc round it
		view.head_over = named and 0 or math.floor(tab.h * dpi * 0.075 + 0.5) / dpi
		view.head = get_head(tab.username)
		place_head(view.head, get_head_box(tab.x, tab, view.head_over))
	else
		-- No head to show (a plain head would look the same for everyone): a grey disc with the name's initial
		local size = named and tab.h - 4 * scale or tab.h
		local disc = button:addChild({
			pos = { (tab.h - size) / 2, (tab.h - size) / 2 }, size = { size, size },
			shapeType = ROUNDED, rounded = size / 2, bgColor = table.clone(ROOM_IDLE_COLOUR),
		})
		view.letter_disc = disc
		-- Measured on screen: a capital in this font draws a pixel left of centre in its box
		view.letter = disc:addChild({ pos = { scale, 0 }, size = { size, size }, uiColor = table.clone(ROOM_IDLE_ICON) })
		view.letter:addAdaptedText(false, utf8.upper(utf8.sub(name, 1, 1)), nil, nil, TAB_FONT, CENTERMID, 0.6, 0.6)
	end

	if named then
		-- As drawn on the design canvas, at the game's size: name 5 px after the head, then a 15 px grey disc with the
		-- menus' white cross, 5 px after the name
		local close_size = 15 * scale
		local text_width = get_string_length(name, TAB_FONT) * TAB_TEXT_SCALE
		view.label = button:addChild({
			pos = { tab.h + 5 * scale, 0 },
			-- As wide as the name, with a pixel or two to spare so it's never cut short; a little shorter than the tab:
			-- this font sits low, and centring in a shorter box lifts it to the middle
			size = { text_width + 3 * scale, tab.h - 3 * scale },
			uiColor = table.clone(NAME_RED),
		})
		view.label:addAdaptedText(false, name, nil, nil, TAB_FONT, LEFTMID, TAB_TEXT_SCALE, TAB_TEXT_SCALE)

		if tab.closable then
			-- Right after the name, the same gap from it as the name has from the head's red ring (6 px, measured on screen)
			local close_x = math.min(view.label.shift.x + text_width + 5 * scale, tab.w - close_size)
			local close = button:addChild({
				pos = { close_x, (tab.h - close_size) / 2 },
				size = { close_size, close_size },
				interactive = true,
				shapeType = ROUNDED,
				rounded = close_size / 2,
				bgColor = table.clone(CLOSE_GREY),
				hoverColor = table.clone(CLOSE_HOVER_GREY),
				pressedColor = table.clone(CLOSE_PRESSED_GREY),
			})
			-- The cross drawn as two lines: the menus' cross texture shrunk this small loses its strokes
			local arm = 3.2 * scale
			close:addCustomDisplay(false, function()
				local cx, cy = close.pos.x + close.size.w / 2, close.pos.y + close.size.h / 2
				set_color(1, 1, 1, view.reveal)
				draw_line(cx - arm, cy - arm, cx + arm, cy + arm, 1.7 * scale)
				draw_line(cx - arm, cy + arm, cx + arm, cy - arm, 1.7 * scale)
			end)
			close:addMouseUpHandler(function()
				close_chat_tab(tab.id)
			end)
			view.close = close
			table.insert(interactive, close)
		end
	end

	if old then
		-- Laid out again under the mouse: still hovered, without waiting for the mouse to move
		if old.button.hoverState ~= BTN_NONE and MOUSE_X > tab.x and MOUSE_X < tab.x + tab.w
			and MOUSE_Y > tab.y and MOUSE_Y < tab.y + tab.h then
			button.hoverState, button.hoverClock = BTN_HVR, old.button.hoverClock
		end
		if not UIElement.lightUIMode then
			if old.x ~= tab.x then
				view.slide_from, view.slide_at = old.x, UIElement.clock
			end
			if named and not old.named then
				view.reveal_at = UIElement.clock
			end
		end
	end
	if not named then
		add_tooltip(view, old)
	end
	return view
end

---Other windows and popups are drawn over the bar, so they take the mouse first: buttons are asked newest first,
---and these are put back as the oldest
---@param interactive UIElement[]
local function lower_input_priority(interactive)
	local ours = {}
	for _, element in ipairs(interactive) do
		ours[element] = true
	end
	local others = {}
	for _, element in ipairs(UIMouseHandler) do
		if not ours[element] then
			table.insert(others, element)
		end
	end
	for i = #UIMouseHandler, 1, -1 do
		UIMouseHandler[i] = nil
	end
	for _, element in ipairs(interactive) do
		table.insert(UIMouseHandler, element)
	end
	for _, element in ipairs(others) do
		table.insert(UIMouseHandler, element)
	end
end

---@param tabs table<integer, DesktopChatTab>
---@param key string
local function build_tabs(tabs, key)
	local old_views = tab_views
	if tabs_root then
		tabs_root:kill()
	end
	tab_views, layout_key = {}, key
	dpi = math.max(1, get_option("highdpi") / 10)
	tabs_root = UIElement:new({ globalid = GLOBAL_ID, pos = { 0, 0 }, size = { WIN_W, WIN_H } })
	local interactive = {}
	for i = 1, MAX_TABS do
		local tab = tabs[i]
		if tab then
			tab_views[i] = build_tab(tab, old_views[i], interactive)
		end
	end
	lower_input_priority(interactive)
	-- Heads of chats that were closed, or whose texture is gone
	for username, head in pairs(heads) do
		local used = false
		for _, view in pairs(tab_views) do
			used = used or view.head == head
		end
		if not used then
			head.holder:kill()
			heads[username] = nil
		end
	end
	set_under_pass_hooked(true)
end

---Changes only when a tab is added, closed, renamed, moved, resized or opened
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
					or v[base + 5] ~= tab.x or v[base + 6] ~= tab.y or v[base + 7] ~= tab.w or v[base + 8] ~= tab.h
					or v[base + 9] ~= (tab.selected and i > 1) then
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
			-- The room looks the same laid out open or not; any other tab shows its name while it's open
			v[base + 9] = tab.selected and i > 1
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
				tostring(tab.selected and i > 1),
			}, ":")
		end
	end
	layout_values_key = table.concat(parts, "|")
	return layout_values_key
end

---Slides the tab toward its place and fades the open tab's name in, for a moment after the bar is laid out again
---@param view DesktopChatTabView
---@param tab DesktopChatTab
local function update_tab_motion(view, tab)
	local x = tab.x
	if view.slide_at then
		local left = 1 - (UIElement.clock - view.slide_at) / SLIDE_TIME
		if left <= 0 then
			view.slide_at = nil
		else
			-- Fast at first, settling at the end
			x = snap(tab.x + (view.slide_from - tab.x) * left ^ 3)
		end
	end
	if x ~= view.x then
		view.x = x
		view.button:moveTo(x, nil)
		if view.head then
			place_head(view.head, get_head_box(x, tab, view.head_over))
		end
	end
	if view.reveal_at then
		local shown = (UIElement.clock - view.reveal_at) / SLIDE_TIME
		if shown >= 1 then
			view.reveal_at, shown = nil, 1
		end
		view.reveal = shown
	else
		view.reveal = 1
	end
end

---Colours and dimming that follow the open tab, unread messages and the mouse, every frame
---@param view DesktopChatTabView
---@param tab DesktopChatTab
local function update_tab_colours(view, tab)
	local state = view.button.hoverState
	local active = tab.selected or tab.unread > 0
	local lively = active or state ~= BTN_NONE
	-- A dimmed chat lights up under the mouse; one that's already lit darkens instead
	local shade = 1
	if active and state ~= BTN_NONE then
		shade = state == BTN_DN and PRESS_SHADE or HOVER_SHADE
	end
	if view.room_icon then
		local disc, icon = view.disc.bgColor, view.room_icon.imageColor
		local from, ink = tab.selected and RED or ROOM_IDLE_COLOUR, tab.selected and WHITE or ROOM_IDLE_ICON
		local alpha = lively and 1 or IDLE_ROOM_ALPHA
		disc[1], disc[2], disc[3], disc[4] = from[1] * shade, from[2] * shade, from[3] * shade, alpha
		icon[1], icon[2], icon[3], icon[4] = ink[1], ink[2], ink[3], alpha
	end
	if view.letter_disc then
		local disc, ink = view.letter_disc.bgColor, view.letter.uiColor
		local alpha = lively and 1 or IDLE_ROOM_ALPHA
		disc[1], disc[2], disc[3], disc[4] = ROOM_IDLE_COLOUR[1] * shade, ROOM_IDLE_COLOUR[2] * shade, ROOM_IDLE_COLOUR[3] * shade, alpha
		ink[4] = alpha
	end
	if view.pill then
		local pill = view.pill.bgColor
		pill[1], pill[2], pill[3] = RED[1] * shade, RED[2] * shade, RED[3] * shade
	end
	if view.label then
		view.label.uiColor[4] = view.reveal
	end
	if view.close then
		view.close.bgColor[4], view.close.hoverColor[4], view.close.pressedColor[4] = view.reveal, view.reveal, view.reveal
	end
	if view.head then
		for _, object in ipairs(view.head.objects) do
			local colour = object.bgColor
			colour[1], colour[2], colour[3], colour[4] = shade, shade, shade, lively and 1 or IDLE_HEAD_ALPHA
		end
	end
end

local function on_pre_draw()
	local is_enabled = get_option("legacychat") ~= 1
		and TB_MENU_MAIN_ISOPEN ~= 1
		and TB_MENU_SPECIAL_SCREEN_ISOPEN ~= 1
	---@type table<integer, DesktopChatTab>?
	local tabs = get_desktop_chat_tabs(is_enabled)
	if not is_enabled or not tabs or next(tabs) == nil then
		if tabs_root then
			destroy_tabs()
		end
		return
	end

	if heads_stale then
		-- A head that has arrived since replaces the tab's initial, one that's gone is replaced by it
		heads_stale, head_textures = false, {}
		for _, view in pairs(tab_views) do
			if view.username and has_head_texture(view.username) ~= (view.head ~= nil) then
				layout_key = nil
			end
		end
	end

	local key = get_layout_key(tabs)
	if layout_key ~= key then
		build_tabs(tabs, key)
	end

	for i, view in pairs(tab_views) do
		local tab = tabs[i]
		update_tab_motion(view, tab)
		update_tab_colours(view, tab)
		update_tooltip(view)
		-- No pop for messages that were already unread when the tab appeared, or with the light UI setting
		if view.unread and tab.unread > view.unread and not UIElement.lightUIMode then
			view.pop_at = UIElement.clock
		end
		view.unread, view.selected = tab.unread, tab.selected
	end
end

local function draw_bar()
	UIElement.drawVisuals(GLOBAL_ID)
end

local function draw_heads()
	if not heads_root then
		return
	end
	-- Viewports can be drawn before anything has moved the elements into place
	heads_root:updatePos()
	UIElement3D.drawViewport(GLOBAL_ID)
end

---Unread badges, then the hovered tab's name over them
local function draw_marks()
	for _, view in pairs(tab_views) do
		draw_badge(view, view.button.size.h / BASE_TAB_HEIGHT)
	end
	for _, view in pairs(tab_views) do
		if view.tip and view.tip.shown then
			local popup = view.tip.popup
			popup:display()
			for _, child in ipairs(popup.child) do
				child:display()
			end
		end
	end
end

---The client's pass for HUD that sits under the rest of the Lua UI: tabs, then heads, then badges over the heads
---@param phase integer
on_draw2d_under = function(phase)
	if not tabs_root then
		return
	end
	if phase == 0 then
		draw_bar()
	elseif phase == 1 then
		draw_heads()
	else
		draw_marks()
	end
end

-- Clients without that pass: the bar in the usual passes, where the heads come last and cover the badges' corners
local function on_draw2d()
	if tabs_root then
		draw_bar()
		draw_marks()
	end
end

local function on_draw_viewport()
	if tabs_root then
		draw_heads()
	end
end

local function on_unload()
	destroy_tabs(true)
	get_desktop_chat_tabs(false)
end

add_hook("pre_draw", HOOK_SET, on_pre_draw)
-- Clients that don't know the event refuse the hook
has_under_pass = pcall(add_hook, "draw2d_under", HOOK_SET, on_draw2d_under)
if has_under_pass then
	remove_hook("draw2d_under", HOOK_SET)
else
	add_hook("draw2d", HOOK_SET, on_draw2d)
	add_hook("draw_viewport", HOOK_SET, on_draw_viewport)
end
add_hook("resolution_changed", HOOK_SET, function()
	destroy_tabs(true)
end)
add_hook("new_game", HOOK_SET, function()
	head_textures = {}
	destroy_tabs(true)
end)
-- Only a note to look again: a download callback isn't a safe place to do more
add_hook("downloader_complete", HOOK_SET, function()
	heads_stale = true
end)
add_hook("unload", HOOK_SET, on_unload)
