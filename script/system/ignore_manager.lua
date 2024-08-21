if (ChatIgnore == nil) then
	---Helper class that filters chat according to current game settings \
	---**Version 5.70**
	---* Added `BannedWordsWhole` list to store strings that should be filtered only if they make a whole word
	---* Updated filtering to replace whole affected word with grawlix instead of only the matched substring
	---* Fixed various cases when filtering would ignore a string it should match
	---
	---**Version 5.60**
	---* Class can now be used as a submodule to filter input
	---* Updated list of banned words
	---@class ChatIgnore
	---@field ver number
	---@field BannedWords string[] List of words that we don't want to have displayed in chat
	---@field IsActive boolean
	ChatIgnore = {
		ver = 5.70,
		BannedWords = {},
		BannedWordsWhole = {},
		__index = {}
	}
end

---Populates `ChatIgnore.BannedWords` table with banned word strings
function ChatIgnore:populateBannedWords()
	local bannedWords = {
		"nigg", "fuck", "cunt", "retard", "fag", "faggot",
		"bitch", "pussy", "dick", "rapist", "cock", "rape", "tranny",
		"whore", "slut", "dyke", "kike", "chink", "coon",
		"пидop", "хyй", "пиздa", "нerp", "нигeр", "eбaть", "хуeв"
	}
	local bannedWholeWords = {
		"nga", "igga"
	}
	local similars = {
		e = "eе3ё",
		a = "aа4",
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

	---@type string[]
	self.BannedWords = {}
	for _, word in ipairs(bannedWords) do
		word = utf8.gsub(word, "(.)", "[%1]+")
		for symbol, replace in pairs(similars) do
			word = utf8.gsub(word, symbol, replace)
		end
		table.insert(self.BannedWords, word)
	end

	---@type string[]
	self.BannedWordsWhole = {}
	for _, word in ipairs(bannedWholeWords) do
		word = utf8.gsub(word, "(.)", "[%1]+")
		for symbol, replace in pairs(similars) do
			word = utf8.gsub(word, symbol, replace)
		end
		table.insert(self.BannedWordsWhole, word)
	end
end

---Escapes input if it matches any banned words
---@param line string
---@return string
---@return boolean
function ChatIgnore:filterInput(line)
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

	for _, word in pairs(ChatIgnore.BannedWords) do
		if (pcall(function() doFilter(utf8, word) end) == false) then
			doFilter(string, word)
		end
	end
	for _, word in pairs(ChatIgnore.BannedWordsWhole) do
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
function ChatIgnore:checkLine(line, msgType, tabId)
	local chatcensor = get_option("chatcensor")
	if (msgType == MSGTYPE.INGAME and chatcensor > 1) then
		return true
	end
	if (msgType >= MSGTYPE.USER and chatcensor % 2 == 1) then
		local message, replaced = ChatIgnore:filterInput(line)
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

---Activates the standalone chat ignore module
function ChatIgnore:activate()
	add_hook("console", "tbMenuChatCensorIgnore", function(...)
		if (ChatIgnore:checkLine(...)) then return 1 end
	end)
end

---@deprecated
---No longer in use. Will be removed with future releases.
function ChatIgnore:deactivate()
	remove_hooks("tbMenuChatCensorIgnore")
end

ChatIgnore:populateBannedWords()
if (not is_mobile()) then
	ChatIgnore:activate()
end
