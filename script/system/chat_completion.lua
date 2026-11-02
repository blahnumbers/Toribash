---Command reference for modern chat UI
---Lists the commands matching what's typed, with their usage, above the chat input. Clicking one fills it in (as of 5.78)
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
---@field dismissed integer? Goes up each time Escape closes the reference (newer executables)
---@field x number
---@field y number
---@field w number
---@field h number

---One of the engine's Tab completions
---@class DesktopChatCompletion
---@field text string
---@field help string
---@field alias string

---One line of the reference
---@class DesktopChatReferenceRow
---@field text string
---@field fill string What clicking it puts in the input
---@field exact boolean Whether it's for the command exactly as typed

---What the local player may use
---@class DesktopChatPermissions
---@field online boolean
---@field level integer 0 for everyone, then `AUTH_LEVELS`
---@field fighter boolean

-- Older executables don't have the reference, so they keep just the engine's Tab completion
if not set_desktop_chat_reference then
	return
end

local commands = require("system.chat_commands")
local server_commands = require("system.chat_server_commands")

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
---Seconds a permission check is reused for
local PERMISSION_REFRESH = 1
local AUTH_LEVELS = { halfop = 1, op = 2, admin = 3 }
---The engine's help text for server commands it has no usage line for
local PRIVILEGED_HELP = "Requires room permissions"
local SERVER_HELP = "Server command"
---Placeholders older executables list among the commands (GET, POST and ECHO are protocol words), and the
---engine's server commands that game servers don't have
local HIDDEN_COMMANDS = { GET = true, POST = true, ECHO = true, chat = true, invokecrash = true, unpause = true, giftnudge = true }
---Who the server accepts each of its commands from: the level `get_permissions()` reports
---@type table<string, integer>
local server_auth = {}
for _, command in ipairs(server_commands) do
	server_auth[command.cmd] = AUTH_LEVELS[command.auth] or 0
end

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
---How many times the engine had closed it on Escape when last checked
---@type integer?
local last_dismissal
---Tab asked for it, so it shows straight away, even for a lone / or after arguments
local is_forced = false
---@type DesktopChatPermissions?
local permissions
local permissions_checked_at = -math.huge

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
	permissions = nil
end

---The server's view of the local player: admins (staff, event and help squad), room operators, half-operators.
---Offline everything is allowed. Online and not found in the room yet, only commands for everyone show
---@return DesktopChatPermissions
local function get_permissions()
	if permissions and UIElement.clock - permissions_checked_at < PERMISSION_REFRESH then
		return permissions
	end
	local world = get_world_state()
	---@type DesktopChatPermissions
	local result
	if world.game_type ~= 1 then
		result = { online = false, level = AUTH_LEVELS.admin, fighter = true }
	else
		result = { online = true, level = 0, fighter = false }
		local netid = get_current_netid()
		---@param info QueuePlayerInfo?
		---@param is_fighter boolean
		local function check(info, is_fighter)
			if not info or info.netid ~= netid then
				return false
			end
			if info.admin or info.eventsquad or info.helpsquad then
				result.level = AUTH_LEVELS.admin
			elseif info.op then
				result.level = AUTH_LEVELS.op
			elseif info.halfop then
				result.level = AUTH_LEVELS.halfop
			end
			result.fighter = is_fighter
			return true
		end
		local found = false
		for i, _ in pairs(get_bouts() or {}) do
			if check(get_bout_info(i - 1), i <= (world.num_players or 2)) then
				found = true
				break
			end
		end
		if not found then
			for i, _ in pairs(get_spectators() or {}) do
				if check(get_spectator_info(i - 1), false) then
					break
				end
			end
		end
	end
	permissions, permissions_checked_at = result, UIElement.clock
	return result
end

---What clicking a usage line fills in: the command words before its first argument, then a space if it takes any.
---Arguments already typed are kept
---@param info string
---@param args string?
---@return string
local function get_usage_fill(info, args)
	local head = info:match("^([^%^%%]*)"):gsub("%s+$", "")
	local description_at = info:find("%125", 1, true) or #info + 1
	local argument_at = info:find("^", 1, true)
	local takes_arguments = argument_at ~= nil and argument_at < description_at
	if args and args ~= "" then
		return head .. " " .. args
	end
	return head .. (takes_arguments and " " or "")
end

---The usage lines for the typed command, then the engine's commands and arguments they don't cover.
---Each command shows once: a usage line from chat_commands.lua or chat_server_commands.lua replaces the
---engine's entry for the same command, and commands the player can't use don't show at all
---@param input DesktopChatInput
---@param entries DesktopChatCompletion[]
---@return DesktopChatReferenceRow[]
local function get_matching_rows(input, entries)
	local text = input.text:lower()
	local typed = text:match("^/([^ ]+)")
	if not typed then
		if not is_forced or text ~= "/" then
			return {}
		end
		typed = ""
	end
	local args = input.text:match("^/[^ ]+ +(.*)")
	local canonical = (input.command and input.command ~= "") and input.command:lower() or typed
	local access = get_permissions()

	---@type DesktopChatReferenceRow[]
	local rows = {}
	local seen, covered = {}, {}
	---@param row_text string
	---@param fill string
	---@param exact boolean
	local function add_row(row_text, fill, exact)
		if not seen[row_text] then
			rows[#rows + 1] = { text = row_text, fill = fill, exact = exact }
			seen[row_text] = true
		end
	end
	---@param name string
	---@return boolean
	local function is_name_match(name)
		if args ~= nil then
			return name == canonical or name == typed
		end
		return name:sub(1, #typed) == typed or name == canonical
	end

	for _, usage in ipairs(commands) do
		local names = type(usage.cmd) == "table" and usage.cmd or { usage.cmd }
		local is_match, is_exact, is_subcommand = false, false, false
		for _, name in ipairs(names) do
			local first_word = name:match("^[^ ]+")
			if name ~= first_word then
				-- /vip add shows while what's typed leads up to it
				is_subcommand = true
				is_match = is_match or ("/" .. name):sub(1, #text) == text or text == "/" .. name .. " "
					or (args == nil and is_name_match(first_word))
			else
				is_match = is_match or is_name_match(name)
				for _, entry in ipairs(entries) do
					if args == nil and entry.text == name and entry.alias:lower() == typed then
						is_match = true
					end
				end
			end
			is_exact = is_exact or first_word == typed or first_word == canonical
		end

		if is_match then
			for _, name in ipairs(names) do
				covered[name] = true
				covered[name:match("^[^ ]+")] = true
			end
			local is_allowed = (not usage.requireOnline or access.online)
				and (not usage.requireOperator or access.level >= AUTH_LEVELS.op)
				and (not usage.requireFighter or access.fighter)
			if is_allowed and (args == nil or args == "" or is_forced or is_subcommand) then
				add_row(usage.info, get_usage_fill(usage.info, not is_subcommand and args or nil), is_exact)
			end
		end
	end

	if access.online then
		for _, command in ipairs(server_commands) do
			if not covered[command.cmd] and is_name_match(command.cmd) then
				covered[command.cmd] = true
				local is_allowed = access.level >= (AUTH_LEVELS[command.auth] or 0)
				if is_allowed and (args == nil or args == "" or is_forced) then
					add_row(command.info, get_usage_fill(command.info, args), command.cmd == typed or command.cmd == canonical)
				end
			end
		end
	end

	for _, entry in ipairs(entries) do
		local is_covered = args == nil and (covered[entry.text:lower()] or covered[entry.alias:lower()])
		local help = entry.help or ""
		local before, after = input.text:sub(1, input.caret), input.text:sub(input.caret + 1)
		-- Everything before the word under the caret: just the slash while it's the command
		local head = args ~= nil and before:match("^(.* )") or "/"
		-- The engine's idea of who may use a server command is out of date, chat_server_commands.lua has the server's
		local needed_level = head == "/" and server_auth[entry.text:lower()] or 0
		if not HIDDEN_COMMANDS[entry.text] and not is_covered and access.level >= needed_level
			and (help ~= PRIVILEGED_HELP or access.level >= AUTH_LEVELS.halfop) then
			if args ~= nil then
				-- Fills in the word under the caret: an argument, or the command itself when the caret is back in it
				local rest = after:gsub("^[^ ]*", "")
				local word = before:sub(#head + 1)
				add_row(
					(head == "/" and "/" or "") .. entry.text .. (help ~= "" and " %125- " .. help or ""),
					head .. entry.text .. (rest == "" and " " or rest),
					entry.text:lower() == word:lower()
				)
			else
				local is_server = help == SERVER_HELP or help == PRIVILEGED_HELP
				local takes_arguments = is_server or help:find("^[<%[]") ~= nil
				local row_text = "/" .. entry.text
				if is_server then
					row_text = row_text .. " %125- " .. (help == PRIVILEGED_HELP and "room command" or "server command")
				elseif help:sub(1, 1) == "-" then
					row_text = row_text .. " %125" .. help
				elseif help ~= "" then
					row_text = row_text .. " ^47" .. help
				end
				add_row(row_text, "/" .. entry.text .. (takes_arguments and " " or ""),
					entry.text:lower() == typed or entry.alias:lower() == typed)
			end
		end
	end

	-- The command exactly as typed comes first
	local ordered = {}
	for i, row in ipairs(rows) do
		ordered[i] = { row = row, index = i }
	end
	table.sort(ordered, function(a, b)
		if a.row.exact ~= b.row.exact then
			return a.row.exact
		end
		return a.index < b.index
	end)
	for i, item in ipairs(ordered) do
		rows[i] = item.row
	end
	return rows
end

---Puts a row's command in the input
---@param row DesktopChatReferenceRow
local function fill_input(row)
	if set_desktop_chat_input(row.fill) then
		destroy_reference()
	end
end

---@param input DesktopChatInput
---@param rows DesktopChatReferenceRow[]
local function build_reference(input, rows)
	local font = input.font or FONTS.SMALL
	local width = input.w + EMOJI_BUTTON_SPACE * (input.h / BASE_INPUT_HEIGHT)
	local wrapped, row_height = {}, MIN_ROW_HEIGHT
	for i, row in ipairs(rows) do
		wrapped[i] = textAdapt(row.text, font, 1, math.max(30, width - 44))
		row_height = math.max(row_height, #wrapped[i] * LINE_HEIGHT + 12)
	end
	local height = math.min(#rows, MAX_ROWS_SHOWN) * row_height + 8
	height = math.min(height, input.y - 8)
	-- Older executables can't fill the input, so their rows aren't buttons
	local is_clickable = set_desktop_chat_input ~= nil

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
			interactive = is_clickable,
			shapeType = ROUNDED,
			rounded = 4,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = is_clickable and TB_MENU_DEFAULT_LIGHTER_COLOR or nil,
			pressedColor = is_clickable and TB_MENU_DEFAULT_BG_COLOR or nil,
			uiColor = TB_MENU_UI_TEXT_COLOR,
		})
		if is_clickable then
			local data = rows[i]
			row:addMouseUpHandler(function()
				fill_input(data)
			end)
		end
		-- A wrapped line starts in the colour the line before it ended on
		local colour_code = ""
		for j, line in ipairs(lines) do
			local label = row:addChild({
				pos = { 10, 4 + (j - 1) * LINE_HEIGHT },
				size = { row.size.w - 20, LINE_HEIGHT },
				uiColor = TB_MENU_UI_TEXT_COLOR,
			})
			local line_text = colour_code .. line
			label:addCustomDisplay(false, function()
				label:uiText(line_text, nil, nil, font, LEFTMID, 1)
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
	-- The engine closes it on Escape while the chat input has the keys, and counts each time
	if input.dismissed and input.dismissed ~= last_dismissal then
		local was_counting = last_dismissal ~= nil
		last_dismissal = input.dismissed
		if was_counting and reference_root then
			destroy_reference()
			dismissed_text = input.text
			-- Still Escape's: the chat input must not act on it as well
			set_desktop_chat_reference(false, true)
			return
		end
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
	local texts = {}
	for i, row in ipairs(rows) do
		texts[i] = row.text .. "\1" .. row.fill
	end
	local signature = table.concat(texts, "|") .. input.x .. ":" .. input.y .. ":" .. input.w .. ":" .. input.h
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
