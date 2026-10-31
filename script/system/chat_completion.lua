---Command reference for modern chat UI
---Lists the commands matching what's typed, with their usage, above the chat input (as of 5.78)
---
---@author surge

---What `get_desktop_chat_input()` reports about the chat input
---@class DesktopChatInput
---@field visible boolean
---@field skin boolean Whether the Lua skin draws the tabs and the input's frame
---@field focused boolean
---@field text string
---@field caret integer
---@field command string The typed command's full name
---@field font integer
---@field hintFont integer
---@field request integer Goes up each time Tab asks for the reference
---@field x number
---@field y number
---@field w number
---@field h number

---One of the engine's Tab completions
---@class DesktopChatCompletion
---@field text string
---@field help string
---@field alias string

-- Older executables don't have the reference, so they keep just the engine's Tab completion
if not set_desktop_chat_reference then
	return
end

local commands = require("system.chat_commands")

local HOOK_SET = "desktopChatReference"
local GLOBAL_ID = 1022
---Seconds the text has to stay the same before the reference shows by itself
local TYPING_DELAY = 0.5
local MIN_ROW_HEIGHT = 34
local LINE_HEIGHT = 21
local MAX_ROWS_SHOWN = 6
local BASE_INPUT_HEIGHT = 34
---The emoji button's space to the right of the input
local EMOJI_BUTTON_SPACE = 38
local KEY_ESCAPE = 27

---@type UIElement?
local reference_root
---The text and caret it last checked
---@type string?
local draft_key
---@type string?
local rendered_key
local changed_at = 0
---The text Escape closed it on, so it stays closed until that changes
---@type string?
local dismissed_text
local last_request = 0
---Tab asked for it, so it shows straight away, even for a lone / or after arguments
local is_forced = false

local function destroy_reference()
	if reference_root then
		reference_root:kill()
		reference_root = nil
	end
	TB_CHAT_REFERENCE = nil
	rendered_key = nil
	set_desktop_chat_reference(false, false)
end

local function reset_reference()
	destroy_reference()
	draft_key, dismissed_text, is_forced = nil, nil, false
end

---The usage lines for the typed command, then any of the engine's completions they don't cover
---@param input DesktopChatInput
---@param entries DesktopChatCompletion[]
---@return string[]
local function get_matching_rows(input, entries)
	local typed = input.text:match("^/([^ ]+)")
	if not typed then
		if not is_forced or input.text ~= "/" then
			return {}
		end
		typed = ""
	end
	local args = input.text:match("^/[^ ]+ +(.*)")
	local canonical = input.command or typed
	local player = QueueList and QueueList:getCurrentPlayerInfo()
	local is_online = get_world_state().game_type == 1
	local is_operator = not is_online or (player and (player.op or player.admin))

	local rows, seen, covered = {}, {}, {}
	---@param text string
	local function add_row(text)
		if not seen[text] then
			rows[#rows + 1] = text
			seen[text] = true
		end
	end

	for _, usage in ipairs(commands) do
		local names = type(usage.cmd) == "table" and usage.cmd or { usage.cmd }
		local is_match = false
		for _, name in ipairs(names) do
			if args ~= nil then
				is_match = is_match or name == canonical or name == typed
			else
				is_match = is_match or name:sub(1, #typed) == typed or name == canonical
				for _, entry in ipairs(entries) do
					if entry.text == name and entry.alias == typed then
						is_match = true
					end
				end
			end
		end

		if is_match then
			for _, name in ipairs(names) do
				covered[name] = true
			end
			local is_allowed = (not usage.requireOnline or is_online)
				and (not usage.requireOperator or is_operator)
				and (not usage.requireFighter or (player and player.is_fighter))
			if is_allowed and (args == nil or args == "" or is_forced) then
				add_row(usage.info)
			end
		end
	end

	for _, entry in ipairs(entries) do
		if args ~= nil or not covered[entry.text] then
			local is_privileged = entry.help == "Requires room permissions"
			if not is_privileged or is_operator then
				local command = args ~= nil and entry.text or "/" .. entry.text
				add_row(command .. (entry.help ~= "" and " %125- " .. entry.help or ""))
			end
		end
	end
	return rows
end

---@param input DesktopChatInput
---@param rows string[]
local function build_reference(input, rows)
	local font = input.font or FONTS.SMALL
	local width = input.w + EMOJI_BUTTON_SPACE * (input.h / BASE_INPUT_HEIGHT)
	local wrapped, row_height = {}, MIN_ROW_HEIGHT
	for i, text in ipairs(rows) do
		wrapped[i] = textAdapt(text, font, 1, math.max(30, width - 44))
		row_height = math.max(row_height, #wrapped[i] * LINE_HEIGHT + 12)
	end
	local height = math.min(#rows, MAX_ROWS_SHOWN) * row_height + 8
	height = math.min(height, input.y - 8)

	reference_root = UIElement:new({
		globalid = GLOBAL_ID,
		pos = { input.x, input.y - height },
		size = { width, height },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
	})
	local reload, _, _, _, list = TBMenu:prepareScrollableList(reference_root, 4, 4, 12, TB_MENU_DEFAULT_BG_COLOR)
	local elements = {}
	for i, lines in ipairs(wrapped) do
		local holder = list:addChild({ pos = { 0, (i - 1) * row_height }, size = { list.size.w, row_height } })
		local row = holder:addChild({
			pos = { 6, 2 },
			size = { holder.size.w - 6, row_height - 4 },
			shapeType = ROUNDED,
			rounded = 4,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			uiColor = TB_MENU_UI_TEXT_COLOR,
		})
		-- A wrapped line starts in the colour the line before it ended on
		local colour_code = ""
		for j, line in ipairs(lines) do
			local label = row:addChild({
				pos = { 10, 4 + (j - 1) * LINE_HEIGHT },
				size = { row.size.w - 20, LINE_HEIGHT },
				uiColor = TB_MENU_UI_TEXT_COLOR,
			})
			local text = colour_code .. line
			label:addCustomDisplay(false, function()
				label:uiText(text, nil, nil, font, LEFTMID, 1)
			end)
			for code in line:gmatch("[%^%%]%d%d+") do
				colour_code = code
			end
		end
		holder:hide()
		elements[#elements + 1] = holder
	end
	local scroll_bar = TBMenu:spawnScrollBar(list, #elements, row_height)
	scroll_bar:makeScrollBar(list, elements, reload)
end

local function on_pre_draw()
	local input = get_desktop_chat_input()
	if
		not input
		or not input.visible
		or not input.skin
		or TB_CHAT_EMOJI_PICKER_OPEN
		or TB_MENU_MAIN_ISOPEN == 1
		or TB_MENU_SPECIAL_SCREEN_ISOPEN == 1
	then
		reset_reference()
		return
	end

	local key = input.text .. "|" .. input.caret
	if key ~= draft_key then
		destroy_reference()
		if dismissed_text ~= input.text then
			dismissed_text = nil
		end
		draft_key, changed_at, is_forced = key, UIElement.clock, false
	end
	if input.request ~= last_request then
		last_request, is_forced, dismissed_text = input.request, true, nil
	end
	if dismissed_text == input.text or (not is_forced and UIElement.clock - changed_at < TYPING_DELAY) then
		return
	end

	local rows = get_matching_rows(input, get_desktop_chat_completions() or {})
	if #rows == 0 then
		destroy_reference()
		return
	end
	local signature = table.concat(rows, "|") .. input.x .. ":" .. input.y .. ":" .. input.w .. ":" .. input.h
	if signature == rendered_key then
		return
	end

	destroy_reference()
	rendered_key = signature
	build_reference(input, rows)
	-- chat_scroll.lua leaves the wheel to the reference while the mouse is over it
	TB_CHAT_REFERENCE = reference_root
	set_desktop_chat_reference(true, false)
end

---Escape closes the reference until the text changes
---@param key integer
---@return integer?
local function on_key_down(key)
	if key ~= KEY_ESCAPE or not reference_root then
		return
	end
	local input = get_desktop_chat_input()
	destroy_reference()
	dismissed_text = input and input.text
	set_desktop_chat_reference(false, true)
	return 1
end

local function on_draw2d()
	if reference_root then
		UIElement.drawVisuals(GLOBAL_ID)
	end
end

add_hook("pre_draw", HOOK_SET, on_pre_draw)
add_hook("key_down", HOOK_SET, on_key_down)
add_hook("draw2d", HOOK_SET, on_draw2d)
add_hook("resolution_changed", HOOK_SET, reset_reference)
add_hook("new_game", HOOK_SET, reset_reference)
add_hook("unload", HOOK_SET, reset_reference)
