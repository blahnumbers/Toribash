if (ChatIgnore == nil) then
	---Helper class that filters chat according to current game settings \
	---**Version 5.60**
	---* Class can now be used as a submodule to filter input
	---* Updated
	---@class ChatIgnore
	---@field ver number
	---@field BannedWords string[] List of words that we don't want to have displayed in chat
	---@field IsActive boolean
	ChatIgnore = {
		ver = 5.60,
		BannedWords = {},
		__index = {}
	}
end

---Populates `ChatIgnore.BannedWords` table with banned word strings
function ChatIgnore:populateBannedWords()
	local bannedWords = {
		"nigg", "fuck", "cunt", "retard", "fag",
		"bitch", "pussy", "dick", "rapist", "cock", "rape",
		"пидop", "хуй", "пиздa", "нerp", "eбaть"
	}
	local similars = {
		e = "[eе3]",
		a = "[aа4]",
		t = "[tт7]",
		g = "[g6]",
		o = "[oо0]",
		s = "[s5]",
		z = "[z2]",
		c = "[cсkк]",
		p = "[pр]",
		r = "[rг]"
	}
	similars["[il]"] = "[il1]"

	---@type string[]
	self.BannedWords = {}
	for _, word in ipairs(bannedWords) do
		for symbol, replace in pairs(similars) do
			word = utf8.gsub(word, symbol, replace)
		end
		table.insert(self.BannedWords, word)
	end
end

---Escapes input if it matches any banned words
---@param line string
---@return string
---@return boolean
function ChatIgnore:filterInput(line)
	local randomCut = math.random(1, string.len("!@#$^&*"))
	local grawlix = string.sub("!@#$^&*", randomCut) .. string.sub("!@#$^&*", 0, randomCut - 1)
	local replaced = false
	local nameStart, nameEnd = line:find('%b<>')
	nameStart = nameStart or 0
	nameEnd = nameEnd or 0
	for _, word in pairs(ChatIgnore.BannedWords) do
		local wStart, wEnd = line:find(word, nameEnd)
		if (wStart) then
			line = line:sub(nameStart, nameEnd) .. line:sub(nameEnd + 1):gsub(word, grawlix:sub(1, wEnd - wStart + 1))
			replaced = true
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
