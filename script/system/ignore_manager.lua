if (ChatIgnore == nil) then
	---**Chat filtering manager class**
	---
	---**Version 5.70**
	---* Added `ChatIgnoreInternal` utility class to make sure only functions we want are exposed
	---* Added ability to filter whole word only
	---* Added `ChatIgnore.AddWord` to allow user-customizable chat filters
	---* Updated filtering to replace whole affected word with grawlix instead of only the matched substring
	---* Fixed various cases when filtering would ignore a string it should match
	---* Added `HookName` field
	---
	---**Version 5.60**
	---* Class can now be used as a submodule to filter input
	---* Updated list of banned words
	---@class ChatIgnore
	---@field HookName string
	---@field ModeWholeWord 0
	---@field ModeAnyPart 1
	---@field ver number
	ChatIgnore = {
		ver = 5.70,
		HookName = "__tbMenuChatCensorIgnore",
		ModeWholeWord = 0,
		ModeAnyPart = 1
	}
	ChatIgnore.__index = ChatIgnore
end

---@class ChatIgnoreInternal
---Utility class for **ChatIgnore** manager
---@field BannedWords string[] Predefined list of banned words
---@field BannedWholeWords string[] Predefined list of banned whole words
---@field BannedWordsCustom string[] List of user customizable banned words
---@field BannedWholeWordsCustom string[] List of user customizable banned whole words
---@field BannedWordsActive string[] Currently active list of banned words
---@field BannedWordsWholeActive string[] Currently active list of banned whole words
local ChatIgnoreInternal = {
	BannedWords = {
		---English
		"nigg", "fuck", "cunt", "retard", "fag", "bitch", "pussy",
		"dick", "cock", "rapist", "tranny",	"whore", "slut",
		"chink",
		---Russian
		"пидop", "хyй", "пиздa", "нerp", "нигeр", "eбaть", "хуeв",
		---Portuguese
		"viado", "negao", "crioulo", "foder", "caralho", "porra",
		"cona", "buceta", "paneleiro", "vadia", "estepr", "travesti"
	},
	BannedWholeWords = {
		---English
		"nga", "igga", "dyke", "kike", "coon",
		"rape", "rapes", "raped", "raping",
		---Portuguese
		"puta", "tuga"
	},
	BannedWordsCustom = {},
	BannedWholeWordsCustom = {},
	BannedWordsActive = {},
	BannedWordsWholeActive = {}
}
ChatIgnoreInternal.__index = ChatIgnoreInternal

---Populates banned words lists
function ChatIgnore.PopulateLists()
	local similars = {
		e = "eе3ё",
		a = "aа4ã",
		t = "tт7",
		g = "g6",
		o = "oо0",
		s = "s5",
		z = "z2",
		c = "cсkк",
		p = "pр",
		r = "rг",
		k = "kк",
		y = "yу",
		il = "il1"
	}

	ChatIgnoreInternal.BannedWordsActive = {}
	for _, word in ipairs(ChatIgnoreInternal.BannedWords) do
		word = utf8.gsub(word, "(.)", "[%1]+")
		for symbol, replace in pairs(similars) do
			word = utf8.gsub(word, symbol, replace)
		end
		table.insert(ChatIgnoreInternal.BannedWordsActive, word)
	end
	for _, word in ipairs(ChatIgnoreInternal.BannedWordsCustom) do
		pcall(function()
			word = utf8.gsub(word, "(.)", "[%1]+")
			for symbol, replace in pairs(similars) do
				word = utf8.gsub(word, symbol, replace)
			end
			table.insert(ChatIgnoreInternal.BannedWordsActive, word)
		end)
	end

	ChatIgnoreInternal.BannedWordsWholeActive = {}
	for _, word in ipairs(ChatIgnoreInternal.BannedWholeWords) do
		word = utf8.gsub(word, "(.)", "[%1]+")
		for symbol, replace in pairs(similars) do
			word = utf8.gsub(word, symbol, replace)
		end
		table.insert(ChatIgnoreInternal.BannedWordsWholeActive, word)
	end
	for _, word in ipairs(ChatIgnoreInternal.BannedWholeWordsCustom) do
		pcall(function()
			word = utf8.gsub(word, "(.)", "[%1]+")
			for symbol, replace in pairs(similars) do
				word = utf8.gsub(word, symbol, replace)
			end
			table.insert(ChatIgnoreInternal.BannedWordsWholeActive, word)
		end)
	end
end

---@alias ChatIgnoreWordMode
---| 0	ChatIgnore.ModeWholeWord | Will only match whole words
---| 1	ChatIgnore.ModeAnyPart | Will match any part of the word
---
---Adds a word to chat filter list. \
---Make sure to repopulate banned words list after you're done adding new words
---@see ChatIgnore.PopulateLists
---@param word string
---@param ignoreMode ChatIgnoreWordMode
function ChatIgnore.BanWord(word, ignoreMode)
	if (type(word) ~= "string") then
		error("Invalid word specified")
	end
	if (ignoreMode ~= ChatIgnore.ModeWholeWord and ignoreMode ~= ChatIgnore.ModeAnyPart) then
		error("Invalid ignore mode specified")
	end

	local targetTable = ignoreMode == ChatIgnore.ModeWholeWord and ChatIgnoreInternal.BannedWholeWordsCustom or ChatIgnoreInternal.BannedWordsCustom
	for _, v in pairs(targetTable) do
		if (v == word) then
			return true
		end
	end
	table.insert(targetTable, word)
	return true
end

---Escapes input if it matches any banned words
---@param line string
---@return string
---@return boolean
function ChatIgnore.FilterInput(line)
	local grawlixSymbols = table.shuffle({ "!", "@", "#", "$", "^", "&", "*" })
	local grawlix = table.implode(grawlixSymbols, '')
	local replaced = false
	---@type boolean, integer|nil, integer|nil
	local result, nameStart, nameEnd = pcall(function() return utf8.find(line, '%b<>') end)
	if (result == false) then
		nameStart, nameEnd = string.find(line, '%b<>')
	end
	nameStart = nameStart or 0
	nameEnd = nameEnd or 0

	---@param lib stringlib|utf8lib
	---@param input string
	---@param word string
	---@param init integer
	local matchWholeWord = function(lib, input, word, init)
		local matchStart, matchEnd = lib.find(input, '([^%w_])' .. word .. '([^%w_])', init)
		if (matchStart ~= nil) then return matchStart + 1, matchEnd - 1 end

		matchStart, matchEnd = lib.find(input, '([^%w_])' .. word .. '$', init)
		if (matchStart ~= nil) then return matchStart + 1, matchEnd end

		matchStart, matchEnd = lib.find(input, '^' .. word .. '([^%w_])', init)
		if (matchStart ~= nil) then return matchStart, matchEnd - 1 end

		matchStart, matchEnd = lib.find(input, '^' .. word .. '$', init)
		return matchStart, matchEnd
	end

	---@param lib stringlib|utf8lib
	---@param word string
	---@param matchWhole boolean?
	local doFilter = function(lib, word, matchWhole)
		while (1) do
			local wStart, wEnd = nil, nil
			if (matchWhole) then
				wStart, wEnd = matchWholeWord(lib, line, word, nameEnd)
			else
				wStart, wEnd = lib.find(lib.lower(line), "%a*" .. word .. "%a*", nameEnd)
			end
			if (wStart == nil) then break end

			---@diagnostic disable-next-line: param-type-mismatch
			line = lib.sub(line, nameStart, wStart - 1) .. lib.sub(grawlix, 1, wEnd - wStart + 1) .. lib.sub(line, wEnd + 1)
			replaced = true
		end
	end

	for _, word in pairs(ChatIgnoreInternal.BannedWordsActive) do
		if (pcall(function() doFilter(utf8, word) end) == false) then
			doFilter(string, word)
		end
	end
	for _, word in pairs(ChatIgnoreInternal.BannedWordsWholeActive) do
		if (pcall(function() doFilter(utf8, word, true) end) == false) then
			doFilter(string, word, true)
		end
	end

	return line, replaced
end

---Checks whether a chat line contains any words we'd like to escape and pushes escaped string to console if needed
---@param line string
---@param msgType ChatMessageType
---@param tabId integer
---@return boolean
function ChatIgnoreInternal.CheckLine(line, msgType, tabId)
	local chatcensor = get_option("chatcensor")
	if (msgType == MSGTYPE.INGAME and chatcensor > 1) then
		return true
	end
	if (msgType >= MSGTYPE.USER and chatcensor % 2 == 1) then
		local message, replaced = ChatIgnore.FilterInput(line)
		if (replaced) then
			if (msgType == MSGTYPE.PLAYER) then
				echo("^02" .. TB_MENU_LOCALIZED.CHATCENSOREDMESSAGE, tabId, true)
			end
			echo(message, tabId, true)
			return true
		end
	end
	return false
end

ChatIgnore.PopulateLists()
if (not is_mobile()) then
	add_hook("console", ChatIgnore.HookName, function(...)
		if (ChatIgnoreInternal.CheckLine(...)) then return 1 end
	end)
end
