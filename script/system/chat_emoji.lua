---Emoji for modern chat UI
---Adds the emoji picker and the input's frame, and names the emoji in chat on hover (as of 5.78)
---
---@author surge

---One of the engine's chat emoji
---@class DesktopChatEmoji
---@field code string What gets typed, and what the tooltips show
---@field file string

---Where `get_desktop_chat_emoji_regions()` says an emoji is drawn in chat
---@class DesktopChatEmojiRegion
---@field emoji integer Its index in the emoji list
---@field x number
---@field y number
---@field size number

local HOOK_SET = "desktopChatEmoji"
local GLOBAL_ID = 1021
local BASE_INPUT_HEIGHT = 34
local PICKER_COLUMNS = 5
local CELL_SIZE = 40
local EMOJI_FOLDER = "../textures/chat/emoji/"
local BUTTON_EMOJI = ":happy:"

local KEY_ESCAPE = 27
local KEY_RETURN = 13
local KEY_KEYPAD_ENTER = 271
local KEY_UP = 273
local KEY_DOWN = 274
local KEY_RIGHT = 275
local KEY_LEFT = 276

---How far each arrow key moves through the picker
---@type table<integer, integer>
local ARROW_STEPS = {
	[KEY_RIGHT] = 1,
	[KEY_LEFT] = -1,
	[KEY_UP] = -PICKER_COLUMNS,
	[KEY_DOWN] = PICKER_COLUMNS,
}

---@type DesktopChatEmoji[]
local emojis = get_desktop_chat_emojis()

---Holds the input's frame, the emoji button and the picker
---@type UIElement?
local input_root
---@type UIElement?
local picker
---Holds the tooltips over emoji in chat
---@type UIElement?
local tooltip_root
---@type string?
local input_key
---@type string?
local regions_key
---@type UIElement[]
local picker_cells = {}
---The cell the arrow keys are on
local keyboard_index = 1

-- Read by chat_completion.lua and chat_scroll.lua, which stay out of the picker's way
TB_CHAT_EMOJI_PICKER_OPEN = false

local function close_picker()
	TB_CHAT_EMOJI_PICKER_OPEN = false
	if picker then
		picker:kill()
		picker = nil
	end
	picker_cells = {}
end

local function destroy_emoji_ui()
	close_picker()
	if input_root then
		input_root:kill()
		input_root = nil
	end
	if tooltip_root then
		tooltip_root:kill()
		tooltip_root = nil
	end
	input_key, regions_key = nil, nil
end

---Shows the emoji's code above it on hover
---@param element UIElement
---@param code string
local function add_tooltip(element, code)
	local popup = TBMenu:displayPopup(element, code, true)
	popup:moveTo(0, -element.size.h - popup.size.h - 6)
end

---@param index integer
local function insert_emoji(index)
	if insert_desktop_chat_emoji(index - 1) then
		close_picker()
	end
end

---@param input DesktopChatInput
---@param scale number
local function toggle_picker(input, scale)
	if picker then
		close_picker()
		return
	end

	TB_CHAT_EMOJI_PICKER_OPEN = true
	-- Covers the screen so a click anywhere else closes it
	picker = input_root:addChild({ size = { WIN_W, WIN_H }, interactive = true })
	picker:addMouseUpHandler(close_picker)
	local width, height = 216 * scale, 136 * scale
	local panel = picker:addChild({
		pos = { math.max(8, input.x + input.w + 38 * scale - width), math.max(8, input.y - height - 8 * scale) },
		size = { width, height },
		interactive = true,
		shapeType = ROUNDED,
		rounded = 7 * scale,
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
	})
	for index, emoji in ipairs(emojis) do
		local column = (index - 1) % PICKER_COLUMNS
		local row = math.floor((index - 1) / PICKER_COLUMNS)
		local cell = panel:addChild({
			pos = { (8 + column * CELL_SIZE) * scale, (8 + row * CELL_SIZE) * scale },
			size = { CELL_SIZE * scale, CELL_SIZE * scale },
			interactive = true,
			shapeType = ROUNDED,
			rounded = 5 * scale,
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_BG_COLOR,
		})
		cell:addChild({ shift = { 5 * scale, 5 * scale }, bgImage = EMOJI_FOLDER .. emoji.file })
		cell:addMouseUpHandler(function()
			insert_emoji(index)
		end)
		add_tooltip(cell, emoji.code)
		picker_cells[index] = cell
	end
	keyboard_index = 1
end

---The input's rounded white fill and border. With the skin on, the engine's text field leaves its own
---background clear and only draws the text and caret over this
---@param input DesktopChatInput
---@param scale number
local function build_input_frame(input, scale)
	local frame = input_root:addChild({ pos = { input.x, input.y }, size = { input.w + 38 * scale, input.h } })
	frame:addCustomDisplay(false, function()
		local x, y, w, h, r = frame.pos.x, frame.pos.y, frame.size.w, frame.size.h, 4 * scale
		local inner_radius = math.max(0, r - 1)

		set_color(TB_MENU_UI_TEXT_COLOR[1], TB_MENU_UI_TEXT_COLOR[2], TB_MENU_UI_TEXT_COLOR[3], 180 / 255)
		draw_quad(x + r, y + 1, w - 2 * r, h - 2)
		draw_quad(x + 1, y + r, r - 1, h - 2 * r)
		draw_quad(x + w - r, y + r, r - 1, h - 2 * r)
		draw_disk(x + r, y + r, 0, inner_radius, 16, 1, -180, 90, 0)
		draw_disk(x + w - r, y + r, 0, inner_radius, 16, 1, 90, 90, 0)
		draw_disk(x + r, y + h - r, 0, inner_radius, 16, 1, -90, 90, 0)
		draw_disk(x + w - r, y + h - r, 0, inner_radius, 16, 1, 0, 90, 0)

		set_color(unpack(input.focused and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_INACTIVE_COLOR))
		draw_quad(x + r, y, w - 2 * r, 1)
		draw_quad(x + r, y + h - 1, w - 2 * r, 1)
		draw_quad(x, y + r, 1, h - 2 * r)
		draw_quad(x + w - 1, y + r, 1, h - 2 * r)
		draw_disk(x + r, y + r, inner_radius, r, 16, 1, -180, 90, 0)
		draw_disk(x + w - r, y + r, inner_radius, r, 16, 1, 90, 90, 0)
		draw_disk(x + r, y + h - r, inner_radius, r, 16, 1, -90, 90, 0)
		draw_disk(x + w - r, y + h - r, inner_radius, r, 16, 1, 0, 90, 0)
	end)
end

---@param input DesktopChatInput
---@param scale number
local function build_picker_button(input, scale)
	local button = input_root:addChild({
		pos = { input.x + input.w + 4 * scale, input.y },
		size = { 34 * scale, input.h },
		interactive = true,
		shapeType = ROUNDED,
		rounded = 6 * scale,
		bgColor = input.skin and { 0, 0, 0, 0 } or TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
	})
	for _, emoji in ipairs(emojis) do
		if emoji.code == BUTTON_EMOJI then
			button:addChild({ shift = { 5 * scale, 5 * scale }, bgImage = EMOJI_FOLDER .. emoji.file })
			break
		end
	end
	button:addMouseUpHandler(function()
		toggle_picker(input, scale)
	end)
end

-- The keys below only change when one of their values does, so they're only rebuilt then
local input_values, input_values_key = {}, nil

---@return string
local function get_input_key(input)
	local v = input_values
	if input_values_key and v[1] == input.x and v[2] == input.y and v[3] == input.w and v[4] == input.h
		and v[5] == input.visible and v[6] == input.skin and v[7] == input.focused then
		return input_values_key
	end
	v[1], v[2], v[3], v[4], v[5], v[6], v[7] = input.x, input.y, input.w, input.h, input.visible, input.skin, input.focused
	input_values_key = table.concat({
		input.x,
		input.y,
		input.w,
		input.h,
		tostring(input.visible),
		tostring(input.skin),
		tostring(input.focused),
	}, ":")
	return input_values_key
end

local regions_values, regions_values_key = {}, nil

---@param regions DesktopChatEmojiRegion[]
---@param include boolean
---@return string
local function get_regions_key(regions, include)
	local v = regions_values
	local count = include and #regions or 0
	if regions_values_key and v.count == count then
		local same = true
		for i = 1, count do
			local region, base = regions[i], (i - 1) * 4
			if v[base + 1] ~= region.emoji or v[base + 2] ~= region.x or v[base + 3] ~= region.y or v[base + 4] ~= region.size then
				same = false
				break
			end
		end
		if same then
			return regions_values_key
		end
	end
	v.count = count
	local parts = {}
	for i = 1, count do
		local region, base = regions[i], (i - 1) * 4
		v[base + 1], v[base + 2], v[base + 3], v[base + 4] = region.emoji, region.x, region.y, region.size
		parts[#parts + 1] = table.concat({ region.emoji, region.x, region.y, region.size }, ":")
	end
	regions_values_key = table.concat(parts, "|")
	return regions_values_key
end

local function on_pre_draw()
	local input = get_desktop_chat_input()
	if not input or TB_MENU_MAIN_ISOPEN == 1 or TB_MENU_SPECIAL_SCREEN_ISOPEN == 1 then
		destroy_emoji_ui()
		return
	end

	local key = get_input_key(input)
	if key == input_key then
		return
	end

	destroy_emoji_ui()
	input_key = key
	local scale = input.h / BASE_INPUT_HEIGHT
	input_root = UIElement:new({ globalid = GLOBAL_ID, pos = { 0, 0 }, size = { WIN_W, WIN_H } })
	-- Kept while the input is hidden, since the tooltips over emoji in chat still need it
	if not input.visible then
		return
	end

	if input.skin then
		build_input_frame(input, scale)
	end
	build_picker_button(input, scale)
end

---Puts a tooltip over each emoji in chat, rebuilt only when they move
local function update_chat_tooltips()
	---@type DesktopChatEmojiRegion[]
	local regions = get_desktop_chat_emoji_regions() or {}
	local key = get_regions_key(regions, input_root ~= nil and not picker)
	if key == regions_key then
		return
	end

	if tooltip_root then
		tooltip_root:kill()
		tooltip_root = nil
	end
	regions_key = key
	if key == "" then
		return
	end

	tooltip_root = UIElement:new({ globalid = GLOBAL_ID, pos = { 0, 0 }, size = { WIN_W, WIN_H } })
	for _, region in ipairs(regions) do
		local area = tooltip_root:addChild({ pos = { region.x, region.y }, size = { region.size, region.size } })
		add_tooltip(area, emojis[region.emoji].code)
	end
end

local function on_draw2d()
	update_chat_tooltips()
	if input_root then
		UIElement.drawVisuals(GLOBAL_ID)
	end
end

---With the picker open, the arrow keys move through it, Enter picks and Escape closes it
---@param key integer
---@return integer?
local function on_key_down(key)
	if not picker then
		return
	end
	if key == KEY_ESCAPE then
		close_picker()
		return 1
	end
	if key == KEY_RETURN or key == KEY_KEYPAD_ENTER then
		insert_emoji(keyboard_index)
		return 1
	end

	local step = ARROW_STEPS[key]
	if step then
		keyboard_index = (keyboard_index - 1 + step) % #emojis + 1
		for index, cell in ipairs(picker_cells) do
			cell.bgColor = index == keyboard_index and TB_MENU_DEFAULT_LIGHTER_COLOR or TB_MENU_DEFAULT_DARKEST_COLOR
		end
		return 1
	end
end

add_hook("pre_draw", HOOK_SET, on_pre_draw)
add_hook("draw2d", HOOK_SET, on_draw2d)
add_hook("key_down", HOOK_SET, on_key_down)
add_hook("resolution_changed", HOOK_SET, destroy_emoji_ui)
add_hook("new_game", HOOK_SET, destroy_emoji_ui)
add_hook("unload", HOOK_SET, destroy_emoji_ui)
