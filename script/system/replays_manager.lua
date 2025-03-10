require("toriui.uielement")
require("system.menu_manager")
require("system.iofiles")
require("system.playerinfo_manager")
if (is_mobile()) then
	require("system.hud_manager")
end

if (Replays == nil) then
	---**Toribash Replays manager class**
	---
	---**Version 5.70**
	---* Replay HUD keyframes browser and editor
	---* Display replay speed slider on the right side of the screen for mobile platforms
	---* Updated replay HUD next / prev buttons to use custom logic based on last active replay browser list
	---* Updated `showReplayInfo()` with arguments for replay queue and current idx
	---* Updated `playReplay()` with arguments for replay queue and current idx
	---* Added `HookNameUI` field
	---
	---**Version 5.65**
	---* Updated custom replay selector window with mobile device support
	---* Replay GUI is now part of **Replays** class
	---* Moved all global definitions to **Replays** or **ReplaysInternal**
	---
	---**Version 5.61**
	---* Updated keyboard return type on search bar for mobile devices
	---
	---**Version 5.60**
	---* Fixes to make UI work with modern TBMenu class
	---* Use *utf8lib* when parsing replay files to ensure we handle multibyte symbols correctly
	---@class Replays
	---@field GameHud ReplayHud Replay advanced GUI
	---@field GameHudRight UIElement Replay speed UI holder (mobile platforms only)
	---@field RootFolder ReplayDirectory Root replay directory Information
	---@field ServerCache ReplayServerInfo[] Cached server replays information from the last query
	---@field ServerCacheTotal integer Total replays on server
	---@field ServerCacheSettings ReplayServerQuery Last server query settings
	---@field CacheReady boolean
	Replays = {
		RootFolder = { name = "replay", fullname = "replay" },
		ServerCacheSettings = { action = 1, offset = 0, search = "", id = 0 },
		ServerCacheTotal = 0,
		CacheReady = false,
		SaveFolder = "my replays",
		HookNameUI = "__tbReplaysManagerUI",
		ver = 5.70
	}
	Replays.__index = Replays

	---@class ReplayBaseInfo
	---@field name string Replay name displayed in-game
	---@field author string Replay author
	---@field tags string Space separated replay tags

	---Replay information class
	---@class ReplayInfo : ReplayBaseInfo
	---@field filename string Replay filename
	---@field bouts string[] List of players in replay
	---@field mod string Replay mod name
	---@field hiddentags string Space separated replay hidden tags
	---@field uploaded boolean Whether replay has been uploaded to servers
	ReplayInfo = {}
	ReplayInfo.__index = ReplayInfo

	---@class ReplayServerQuery
	---@field action integer Replay query action id
	---@field offset integer Replay query offset for pagination
	---@field search string Replay query search string
	---@field info string Info string that describes current action id
end

---Internal variables holder for **Replays** class
---@class ReplaysInternal
---@field ReplayVoteAction integer
---@field SelectedReplay ReplayInfo
---@field SelectedFolder ReplayDirectory
---@field SelectedServerReplay table
---@field CustomSelectorActive boolean
---@field MaxFolderLevels integer
---@field ServerTempName string
---@field SaveTempName string
---@field EventTempPrefix string
local ReplaysInternal = {
	ReplayVoteAction = 101,
	SelectedReplay = { element = nil, defaultColor = nil, time = 0, replay = nil },
	SelectedFolder = { fullname = "replay" },
	SelectedServerReplay = { id = 0 },
	CustomSelectorActive = false,
	MaxFolderLevels = 4,
	ServerTempName = "--onlinereplaytempfile",
	SaveTempName = "--localreplaytempfile",
	EventTempPrefix = "--eventtmp"
}

---Returns a new `ReplayInfo` object filled with default information
---@param path string
---@return ReplayInfo
---@overload fun() : ReplayInfo
---@overload fun(source: ReplayInfo): ReplayInfo
function ReplayInfo.New(path)
	---@type ReplayInfo
	local rplInfo
	if (getmetatable(path) == ReplayInfo) then
		---@type ReplayInfo
		---@diagnostic disable-next-line: assign-type-mismatch, cast-local-type
		path = path
		rplInfo = table.clone(path)
	else
		rplInfo = {
			filename = path or "",
			name = path or "",
			author = "autosave",
			bouts = {},
			mod = "classic",
			tags = "",
			hiddentags = "",
			uploaded = false
		}
	end
	setmetatable(rplInfo, ReplayInfo)
	return rplInfo
end

---Copies information from `sourceInfo` to current object
---@param sourceInfo ReplayInfo
function ReplayInfo:Copy(sourceInfo)
	self.name = sourceInfo.name
	self.filename = sourceInfo.filename
	self.author = sourceInfo.author
	self.bouts = table.clone(sourceInfo.bouts)
	self.mod = sourceInfo.mod
	self.tags = sourceInfo.tags
	self.hiddentags = sourceInfo.tags
	self.uploaded = sourceInfo.uploaded
end

---Returns a string representation of current object to use for cache file
---@return string
function ReplayInfo:ToString()
	local datas = { self.filename, self.name, self.author, self.mod }
	table.insert(datas, table.implode(self.bouts, " "))
	table.insert(datas, self.tags)
	table.insert(datas, self.hiddentags)
	table.insert(datas, self.uploaded and 1 or 0)
	return table.implode(datas, "\t") .. "\t"
end

---Returns a `ReplayInfo` object generated from a cache string
---@param str string
---@return ReplayInfo?
function ReplayInfo.FromString(str)
	local rplInfo = ReplayInfo.New()

	local _, segments = utf8.gsub(str, "([^\t]*)\t", "")
	local data_stream = { utf8.match(str, ("([^\t]*)\t"):rep(segments)) }

	rplInfo.filename = data_stream[1]
	rplInfo.name = data_stream[2]
	rplInfo.author = data_stream[3]
	rplInfo.mod = data_stream[4]

	---Legacy format went with 2 hardcoded bouts, new one uses a string with all joined player names
	---We need to be able to handle both correctly
	local res = pcall(function()
		if (segments == 9) then
			table.insert(rplInfo.bouts, data_stream[5])
			table.insert(rplInfo.bouts, data_stream[6])
			rplInfo.tags = utf8.lower(data_stream[7])
			rplInfo.hiddentags = utf8.lower(data_stream[8])
			rplInfo.uploaded = data_stream[9] == "1"
		else
			rplInfo.bouts = utf8.explode(data_stream[5], " ")
			rplInfo.tags = utf8.lower(data_stream[6])
			rplInfo.hiddentags = utf8.lower(data_stream[7])
			rplInfo.uploaded = data_stream[8] == "1"
		end
	end)

	return res and rplInfo or nil
end

function ReplayInfo.FromReplay(path)
	local replay = Files.Open("../" .. path, FILES_MODE_READONLY)
	local replayLines = replay:readAll()
	replay:close()

	local rplInfo = ReplayInfo.New(path)
	local hasDecap = false
	local hasMadman = false

	pcall(function()
		for _, ln in pairs(replayLines) do
			---Trim any spaces at the end of the string
			ln = utf8.gsub(ln, "%s+$", "")
			if (utf8.find(ln, "^FIGHTNAME 0;")) then
				rplInfo.name = utf8.gsub(ln, "FIGHTNAME 0; *", "")
			elseif (utf8.find(ln, "^BOUT %d;")) then
				local bout = utf8.gsub(ln, "BOUT %d; *", "")
				table.insert(rplInfo.bouts, PlayerInfo.Get(bout).username)
			elseif (utf8.find(ln, "^AUTHOR 0;")) then
				local author = utf8.gsub(ln, "AUTHOR 0; *", "")
				if (utf8.len(author) > 0) then
					rplInfo.author = PlayerInfo.Get(author).username
				end
			elseif (utf8.find(ln, "^NEWGAME %d;")) then
				rplInfo.mod = utf8.gsub(ln, "NEWGAME %d;", "")
				rplInfo.mod = utf8.match(rplInfo.mod, "/*%S*%.tbm")
				rplInfo.mod = rplInfo.mod and utf8.gsub(rplInfo.mod, "^.*/", "") or "classic"
			elseif (utf8.find(ln, "^CRUSH %d; 0") and not hasDecap) then
				rplInfo.hiddentags = table.implode({ rplInfo.hiddentags, "decap" }, " ")
				hasDecap = true
			elseif (utf8.find(ln, "^CRUSH %d; %d %d %d %d %d %d") and not hasMadman) then
				rplInfo.hiddentags = table.implode({ rplInfo.hiddentags, "madman" }, " ")
				hasMadman = true
			elseif (utf8.find(ln, "^FIGHT %d;")) then
				---Legacy replay version support
				local info = utf8.gsub(ln, "FIGHT %d; *", "")
				local _, segments = utf8.gsub(info, "([^ ]+) *", "")
				local data_stream = { utf8.match(info, ("([^ ]+) *"):rep(segments)) }
				rplInfo.name = data_stream[1]
				for i = 2, #data_stream do
					table.insert(rplInfo.bouts, PlayerInfo.Get(data_stream[i]).username)
				end
			end
		end
	end)

	---Create replay names for autosave replays
	if (rplInfo.name == "vs") then
		rplInfo.name = utf8.gsub(rplInfo.filename, "^.*/(.+)%.rpl$", "%1")
		pcall(function()
			---This will affect usernames with underscores. Do we care? Probably not. \
			---Alternative is writing a longer regex expression or using bout names
			---which may not match in case of decapAI replays.
			local cleaned = utf8.gsub(rplInfo.name, "[_ ]+", " ")
			rplInfo.name = utf8.gsub(cleaned, "-(%d+) (%d+)", " (%1 - %2)")
		end)
	end

	return rplInfo
end

---Attempts to update replay file with object data. \
---*Only replay name changing is currently supported.*
---@return boolean result
---@return string? error
function ReplayInfo:UpdateFile()
	local file = Files.Open("../" .. self.filename)
	if (not file.data) then
		return false, TB_MENU_LOCALIZED.REPLAYSERRORREADINGFILE
	end

	local fileLines = file:readAll()
	file:close()

	for i, ln in pairs(fileLines) do
		if (utf8.find(ln, "^FIGHTNAME %d;")) then
			local changedLine = utf8.gsub(ln, ";.*$", "; ")
			fileLines[i] = changedLine .. self.name
		elseif (ln:find("^FIGHT %d;")) then
			local changedLine = utf8.gsub(ln, ";.*$", "; ")
			fileLines[i] = changedLine .. self.name .. " " .. table.implode(self.bouts, " ")
		end
	end

	file:reopen(FILES_MODE_WRITE)
	if (not file.data) then
		return false, TB_MENU_LOCALIZED.REPLAYSERRORUPDATINGFILE
	end
	for _, line in pairs(fileLines) do
		file:writeLine(line)
	end
	file:close()

	return true
end

---@class ReplayDirectory
---@field name string Directory name
---@field fullname string Directory path, relative to Toribash root
---@field parent ReplayDirectory|nil Parent replay directory
---@field replays ReplayInfo[] Replays inside this directory
---@field folders ReplayDirectory[] Other replay directories inside this directory

---Exits Replays menu and resets navigation bar with main section elements
function Replays.Quit()
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
	TBMenu:clearNavSection()
	TBMenu:showNavigationBar()
	TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
end

---Returns custom navigation bar data used for Replays menu
---@param isOnline ?boolean
---@return MenuNavButton[]
function Replays:getNavigationButtons(isOnline)
	---@type MenuNavButton[]
	local navigation = {
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
			action = Replays.Quit
		}
	}
	if (isOnline) then
		table.insert(navigation, {
			text = TB_MENU_LOCALIZED.REPLAYSLOCAL,
			action = function() Replays:showMain(TBMenu.CurrentSection) end,
			right = true
		})
		table.insert(navigation, {
			text = TB_MENU_LOCALIZED.REPLAYSSEARCH,
			action = function() Replays:showSearchWindow() end,
			right = true
		})
	else
		table.insert(navigation, {
			text = TB_MENU_LOCALIZED.REPLAYSCOMMUNITY,
			action = function() usage_event("replaysonline") Replays:getServerReplays() end,
			right = true,
			hidden = TB_MENU_PLAYER_INFO.username == ""
		})
	end
	return navigation
end

---Runs main replay cache data fetcher loop
---@param folder string
---@param rplTable ReplayDirectory
---@param file File
---@param cacheData ReplayInfo[]
---@param includeEventTemp ?boolean
function Replays:fetchReplayData(folder, rplTable, file, cacheData, includeEventTemp)
	if (not rplTable.replays) then
		rplTable.replays = {}
		rplTable.folders = {}
	end

	local files = get_files(folder, "")
	local count = 1
	local maxDelay = 1 / (tonumber(get_option("framerate")) or 30) / 2
	TBMenu.StatusMessage.replayfolders = TBMenu.StatusMessage.replayfolders or {}
	if (not TBMenu.StatusMessage.replayUpdater) then
		TBMenu.StatusMessage.replayUpdater = TBMenu.StatusMessage:addChild({})
		TBMenu.StatusMessage.replayUpdater.killAction = function() file:close() end
	end

	TBMenu.StatusMessage.replayUpdater:addCustomDisplay(true, function()
			TBMenu.StatusMessage.endTime = UIElement.clock + 100
			local targetText = TB_MENU_LOCALIZED.REPLAYSUPDATINGCACHE .. " (" .. folder .. ")\n" .. math.min(math.ceil((count - 1) / #files * 100), 100) .. "% " .. TB_MENU_LOCALIZED.WORDDONE
			if (TBMenu.StatusMessage.messageView.str ~= targetText) then
				TBMenu.StatusMessage.messageView:addAdaptedText(true, targetText, nil, nil, 4, nil, 0.8)
			end

			while (1) do
				local v = files[count]
				pcall(function()
					if (v:match(ReplaysInternal.ServerTempName) or v:match(ReplaysInternal.SaveTempName) or (v:find("^" .. ReplaysInternal.EventTempPrefix) and not includeEventTemp)) then
						---Skip system replay names
					elseif (v:match(".rpl$")) then
						local replaypathfull = folder and (folder .. "/" .. v) or v
						local cacheName = utf8.gsub(utf8.lower(replaypathfull), " ", "_")
						if (cacheData[cacheName]) then
							table.insert(rplTable.replays, cacheData[cacheName])
						else
							local rplInfo = ReplayInfo.FromReplay(replaypathfull)
							file:writeLine(rplInfo:ToString())
							table.insert(rplTable.replays, rplInfo)
						end
					elseif (not v:find("^%.+[%s%S]*$") and v ~= "system" and not v:find("%.%a+$")) then
						table.insert(rplTable.folders, {
							parent = rplTable,
							name = v,
							fullname = rplTable.fullname .. "/" .. v
						})
						table.insert(TBMenu.StatusMessage.replayfolders, { fname = folder .. "/" .. v, rpltbl = rplTable.folders[#rplTable.folders] })
						if (rplTable.fullname .. "/" .. v == ReplaysInternal.SelectedFolder.fullname) then
							ReplaysInternal.SelectedFolder = rplTable.folders[#rplTable.folders]
						end
					end
				end)
				count = count + 1

				if (count > #files or os.clock_real() - UIElement.clock > maxDelay) then
					break
				end
			end
			if (count > #files) then
				if (rplTable.fullname ~= "replay/autosave") then
					pcall(function() rplTable.replays = table.qsort(rplTable.replays, "filename") end)
				end
				if (#TBMenu.StatusMessage.replayfolders > 0) then
					local fname = TBMenu.StatusMessage.replayfolders[1].fname
					local rpltbl = TBMenu.StatusMessage.replayfolders[1].rpltbl
					table.remove(TBMenu.StatusMessage.replayfolders, 1)
					Replays:fetchReplayData(fname, rpltbl, file, cacheData, includeEventTemp)
				else
					TBMenu.StatusMessage.replayUpdater:kill()
					if (TBMenu.StatusMessage.startTime < UIElement.clock - 1) then
						TBMenu.StatusMessage.messageView:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSDATACACHEREADY, nil, nil, 4, nil, 0.8)
						TBMenu.StatusMessage.endTime = UIElement.clock + 2
					else
						TBMenu.StatusMessage:kill()
						TBMenu.StatusMessage = nil
					end
					if (not ReplaysInternal.SelectedFolder.name) then
						ReplaysInternal.SelectedFolder = Replays.RootFolder
					end
					Replays.CacheReady = true
				end
			end
		end)
end

---Updates cache datafile with new replay information
---@param replay ReplayInfo
---@param newreplay ?ReplayInfo
---@return boolean
function Replays:updateReplayCache(replay, newreplay)
	if (newreplay and replay.name ~= newreplay.name) then
		local updated, err = newreplay:UpdateFile()
		if (not updated) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORUPDATINGNAME .. ":\n" .. err)
			return false
		end
	end

	local file = Files.Open("../replay/replaycache.dat", FILES_MODE_READONLY)
	if (not file.data) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORREADINGCACHE)
		return false
	end

	local fileLines = file:readAll()
	file:close()
	for i = #fileLines, 1, -1 do
		local ln = fileLines[i]
		if (utf8.find(ln, "^" .. string.escape(replay.filename))) then
			table.remove(fileLines, i)
			if (newreplay ~= nil) then
				table.insert(fileLines, i, newreplay:ToString())
			end
		end
	end

	file:reopen(FILES_MODE_WRITE)
	if (not file.data) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORUPDATINGTAGS)
		return false
	end
	for _, line in pairs(fileLines) do
		file:writeLine(line)
	end
	file:close()

	return true
end

---Initiates replay cache and launches data fetcher loop
---@param includeEventTemp ?boolean
function Replays:getReplayFiles(includeEventTemp)
	Replays.CacheReady = false
	Replays.RootFolder.replays = nil
	Replays.RootFolder.folders = nil

	local file = Files.Open("../replay/replaycache.dat", FILES_MODE_READWRITE)
	if (not file.data) then
		file:reopen(FILES_MODE_WRITE)
		if (not file.data) then
			TBMenu:showStatusMessage("replaycache.dat: " .. TB_MENU_LOCALIZED.ERRORCREATINGFILE)
			return
		end
	end

	local cacheData = {}
	for _, ln in pairs(file:readAll()) do
		local rplInfo = ReplayInfo.FromString(ln)
		if (rplInfo) then
			local cacheName = utf8.gsub(utf8.lower(rplInfo.filename), " ", "_")
			cacheData[cacheName] = rplInfo
		end
	end
	TBMenu:showStatusMessage("")
	Replays:fetchReplayData(Replays.RootFolder.name, Replays.RootFolder, file, cacheData, includeEventTemp)
end

---@class ReplayServerInfo : ReplayBaseInfo
---@field id integer Replay id in Toribash database
---@field date string Replay upload date
---@field description string Replay description provided by its author
---@field downloads integer Number of times this replay has been downloaded
---@field score number Replay rating average set by other users
---@field votes integer Number of ratings on this replay
---@field uservote integer Local user's vote

---Parses replay data retrieved with a `fetch_replay_results()` call and puts it in **Replays.ServerCache** table. \
---@see fetch_replay_results
---@param data string
function Replays.ParseServerReplaysData(data)
	for ln in data:gmatch("[^\n]+") do
		if (ln:match("^#Total")) then
			local total = ln:gsub("%D", "")
			Replays.ServerCacheTotal = tonumber(total) or 0
		elseif (not ln:match("^#")) then
			local _, segments = ln:gsub("\t", "")
			local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
			pcall(function()
				---@type ReplayServerInfo
				local info = {
					id = tonumber(data_stream[1]) or 0,
					name = data_stream[2],
					author = data_stream[3],
					date = data_stream[4],
					description = data_stream[5],
					downloads = tonumber(data_stream[6]) or 0,
					score = tonumber(data_stream[7]) or 0,
					votes = tonumber(data_stream[8]) or 0,
					tags = data_stream[9],
					uservote = tonumber(data_stream[10]) or 0
				}
				if (info.author ~= nil) then
					table.insert(Replays.ServerCache, info)
				end
			end)
		end
	end
end

---@class ReplayComment
---@field id integer
---@field user string
---@field score integer
---@field comment string
---@field date string

---Parses replay comments retrieved with a `fetch_replay_comments()` call and returns the comments data. \
---@see fetch_replay_comments
---@param data string
---@return ReplayComment[]
function Replays.ParseReplayComments(data)
	---@type ReplayComment[]
	local comments = {}
	for ln in data:gmatch("[^\n]+") do
		if (not ln:match("^#")) then
			local _, segments = ln:gsub("\t", "")
			local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
			pcall(function()
				local comment = {
					id = tonumber(data_stream[1]),
					user = data_stream[2],
					score = tonumber(data_stream[3]),
					comment = data_stream[4],
					date = data_stream[5]
				}
				table.insert(comments, comment)
			end)
		end
	end
	return comments
end

---Queues a network request to fetch community replays information from Toribash server
---@param action ?integer
---@param offset ?integer
---@param searchStr ?string
function Replays:getServerReplays(action, offset, searchStr)
	TB_MENU_REPLAYS_ONLINE = 1
	local action = action or Replays.ServerCacheSettings.action
	local offset = offset or Replays.ServerCacheSettings.offset
	local searchStr = searchStr and utf8.lower(searchStr) or Replays.ServerCacheSettings.search

	local overlay = TBMenu:spawnWindowOverlay()
	local waitNotification = overlay:addChild({
		pos = { overlay.size.w / 3, overlay.size.h / 2 - 100 },
		size = { overlay.size.w / 3, 200 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	TBMenu:displayLoadingMark(waitNotification, TB_MENU_LOCALIZED.REPLAYSUPDATINGCOMMUNITY)

	local infoMessage = TB_MENU_LOCALIZED.REPLAYSFILTERSDATE
	if (action == 2) then
		infoMessage = TB_MENU_LOCALIZED.REPLAYSFILTERSRATING
	elseif (action == 3) then
		infoMessage = TB_MENU_LOCALIZED.REPLAYSFILTERSPOPULARITY
	end

	Request:queue(function() fetch_replay_results(action, offset, searchStr) end, "netCommunityReplays", function()
			if (overlay == nil or overlay.destroyed) then
				return
			end

			Replays.ServerCacheTotal = 0
			Replays.ServerCacheSettings.action = action
			Replays.ServerCacheSettings.offset = offset
			Replays.ServerCacheSettings.search = searchStr
			Replays.ServerCacheSettings.info = infoMessage
			Replays.ServerCache = {}

			Replays.ParseServerReplaysData(get_network_response())
			overlay:kill()
			Replays:showServerReplays()
		end, function()
			if (overlay == nil or overlay.destroyed) then
				return
			end

			overlay:kill()
			TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.ERRORTRYAGAIN .. "\n" .. get_network_error(), function() Replays:getServerReplays(action, offset, searchStr) end)
		end)
end

---Returns a (hardcoded) list of popular replay tags
---@return string[]
function Replays.GetPopularTags()
	return {
		"multiplayer",
		"kick",
		"sparring",
		"aikido",
		"parkour",
		"madman",
		"tricking",
		"manipulation",
		"realism",
		"awesome",
		"punch",
		"split",
		"jump",
		"judo",
		"running"
	}
end

---@class ReplaySearchResults
---@field name ReplayInfo[]
---@field filename ReplayInfo[]
---@field author ReplayInfo[]
---@field bouts ReplayInfo[]
---@field mod ReplayInfo[]
---@field tags ReplayInfo[]
---@field hiddentags ReplayInfo[]

---Performs search among cached replays and returns the list of matching replays
---@param str string|string[]
---@param rplTable ReplayDirectory
---@param searchResults ReplaySearchResults?
---@return ReplaySearchResults
function Replays:findReplays(str, rplTable, searchResults)
	local searchResults = searchResults or { name = {}, filename = {}, author = {}, bouts = {}, mod = {}, tags = {}, hiddentags = {} }
	---@diagnostic disable-next-line: param-type-mismatch
	local searchStringRaw = type(str) == "table" and str[1]:lower() or str:lower()
	local searchStrings = {}
	for i in string.gmatch(searchStringRaw, "[^ ]+") do
		table.insert(searchStrings, string.escape(i))
	end

	for _, folder in pairs(rplTable.folders) do
		Replays:findReplays(searchStringRaw, folder, searchResults)
	end
	for _, replay in pairs(rplTable.replays) do
		if (string.find(replay.name:lower(), searchStrings[1])) then
			table.insert(searchResults.name, replay)
		elseif (string.find(replay.filename:lower(), searchStrings[1])) then
			table.insert(searchResults.filename, replay)
		elseif (string.find(replay.author:lower(), searchStrings[1])) then
			table.insert(searchResults.author, replay)
		elseif (string.find(replay.mod:lower(), searchStrings[1])) then
			table.insert(searchResults.mod, replay)
		elseif (string.find(replay.tags:lower(), searchStrings[1])) then
			table.insert(searchResults.tags, replay)
		elseif (string.find(replay.hiddentags:lower(), searchStrings[1])) then
			table.insert(searchResults.hiddentags, replay)
		else
			for _, bout in pairs(replay.bouts) do
				if (string.find(bout:lower(), searchStrings[1])) then
					table.insert(searchResults.bouts, replay)
				end
			end
		end
	end
	if (#searchStrings > 1) then
		local cleanedFolder = {}
		for i = 2, #searchStrings do
			for j, searchFolder in pairs(searchResults) do
				cleanedFolder = {}
				for _, replay in pairs(searchFolder) do
					local match = false
					if (string.find(replay.name:lower(), searchStrings[i]) or
						string.find(replay.filename:lower(), searchStrings[i]) or
						string.find(replay.author:lower(), searchStrings[i]) or
						string.find(replay.mod:lower(), searchStrings[i]) or
						string.find(replay.tags:lower(), searchStrings[i]) or
						string.find(replay.hiddentags:lower(), searchStrings[i])
					) then
						match = true
					else
						for _, bout in pairs(replay.bouts) do
							if (string.find(bout:lower(), searchStrings[i])) then
								match = true
							end
						end
					end
					if (match) then
						table.insert(cleanedFolder, replay)
					end
				end
				searchResults[j] = cleanedFolder
			end
		end
	end
	return searchResults
end

---@param viewElement UIElement
---@param replayInfo UIElement
---@param toReload UIElement
---@param replays ReplayInfo[][]
function Replays:showSearchList(viewElement, replayInfo, toReload, replays)
	viewElement:kill(true)
	local elementHeight = math.clamp(math.ceil(WIN_H / 20), 40, 55)

	local listingHolder = viewElement:addChild({
		size = { viewElement.size.w - 20, viewElement.size.h }
	})

	local listElements = {}
	local goBack = listingHolder:addChild({
		pos = { 0, #listElements * elementHeight },
		size = { listingHolder.size.w, elementHeight },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	table.insert(listElements, goBack)
	goBack:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSBACKTOALLREPLAYS, nil, nil, FONTS.LMEDIUM, nil, 0.6)
	goBack:addMouseUpHandler(function()
			TB_MENU_REPLAYS_SEARCH = nil
			Replays:showList(viewElement.parent, replayInfo, ReplaysInternal.SelectedFolder)
		end)

	local replayQueue = {}
	for _, list in pairs(replays) do
		for _, replay in pairs(list) do
			table.insert(replayQueue, replay)
		end
	end
	local totalIdx = 0
	for section, replayList in pairs(replays) do
		if (#replayList > 0) then
			local sectionName = listingHolder:addChild({
				pos = { 10, #listElements * elementHeight },
				size = { listingHolder.size.w - 20, elementHeight }
			})
			table.insert(listElements, sectionName)
			local sectionStr = TB_MENU_LOCALIZED.REPLAYSMATCHBY .. " " .. section
			if (section == "hiddentags") then
				sectionStr = "hidden tags"
			end
			sectionName:addAdaptedText(true, sectionStr, nil, nil, nil, LEFTMID)
			for i, replay in pairs(replayList) do
				totalIdx = totalIdx + 1
				local thisIdx = totalIdx
				local replayElementHolder = listingHolder:addChild({
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, replayElementHolder)
				local replayElement = replayElementHolder:addChild({
					pos = { 6, 2 },
					size = { replayElementHolder.size.w - 6, replayElementHolder.size.h - 4 },
					interactive = true,
					clickThrough = true,
					hoverThrough = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					shapeType = ROUNDED,
					rounded = 3
				})
				if (ReplaysInternal.SelectedReplay.replay and ReplaysInternal.SelectedReplay.replay.filename == replay.filename or i == 1) then
					ReplaysInternal.SelectedReplay.element = replayElement
					ReplaysInternal.SelectedReplay.defaultColor = table.clone(replayElement.bgColor)
				end
				replayElement:addMouseHandlers(nil, function()
						if (ReplaysInternal.SelectedReplay.element == replayElement and ReplaysInternal.SelectedReplay.time + 0.5 > os.clock_real()) then
							Replays:playReplay(replay, replayQueue, thisIdx)
							return
						end
						ReplaysInternal.SelectedReplay.time = os.clock_real()
						---@diagnostic disable-next-line: assign-type-mismatch
						ReplaysInternal.SelectedReplay.element.bgColor = table.clone(ReplaysInternal.SelectedReplay.defaultColor)
						ReplaysInternal.SelectedReplay.element = replayElement
						ReplaysInternal.SelectedReplay.defaultColor = table.clone(replayElement.bgColor)
						Replays:showReplayInfo(replayInfo, replayQueue, thisIdx)
					end)

				local replayName = replayElement:addChild({
					pos = { 10, 0 },
					size = { replayElement.size.w / 2 - 20, replayElement.size.h }
				})
				replayName:addAdaptedText(replay.name, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.65)
				local replayNameSeparator = replayElement:addChild({
					pos = { replayName.shift.x + replayName.size.w, replayElement.size.h / 4 },
					size = { 1, replayElement.size.h / 2 },
					bgColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
				})
				local replayAuthor = replayElement:addChild({
					pos = { replayNameSeparator.shift.x, 0 },
					size = { replayElement.size.w / 6, replayElement.size.h }
				})
				local replayAuthorStr = replay.author == "autosave" and TB_MENU_LOCALIZED.REPLAYSAUTHORAUTOSAVE or TB_MENU_LOCALIZED.REPLAYSAUTHORBY .. " " .. replay.author
				replayAuthor:addAdaptedText(replayAuthorStr, nil, nil, FONTS.LMEDIUM, nil, 0.65)
				local replayAuthorSeparator = replayElement:addChild({
					pos = { replayAuthor.shift.x + replayAuthor.size.w, replayElement.size.h / 4 },
					size = { 1, replayElement.size.h / 2 },
					bgColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
				})
				local replayMod = replayElement:addChild({
					pos = { replayAuthorSeparator.shift.x, 0 },
					size = { replayElement.size.w - replayAuthorSeparator.shift.x, replayElement.size.h }
				})
				replayMod:addAdaptedText(replay.mod, nil, nil, FONTS.LMEDIUM, nil, 0.65)
			end
		end
	end

	for _, v in pairs(listElements) do
		v:hide()
	end

	local listingScrollBG = viewElement:addChild({
		pos = { -(viewElement.size.w - listingHolder.size.w), 0 },
		size = { viewElement.size.w - listingHolder.size.w, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local listingScrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingScrollBar:makeScrollBar(listingHolder, listElements, toReload)
end

---@param replay ReplayInfo
---@param replayQueue ReplayInfo[]?
---@param replayIdx integer?
function Replays:playReplay(replay, replayQueue, replayIdx)
	local whiteoverlay = TBMenu:spawnWindowOverlay()
	local cacheMode = get_option("replaycache") == 2 and 1 or 0
	local replayFile = utf8.gsub(replay.filename, "^replay/", "")

	local loading = whiteoverlay:addChild({
		pos = { WIN_W / 4, WIN_H / 7 * 3 },
		size = { WIN_W / 2, WIN_H / 7 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	if (replay.mod ~= "classic") then
		local modname = string.find(replay.mod, "%.tbm$") and replay.mod or (replay.mod .. ".tbm")
		if (not find_mod(modname)) then
			local modFile = Files.Open("../data/mod/downloads/" .. modname)
			loading:addAdaptedText(false, TB_MENU_LOCALIZED.MODSDOWNLOADINGMOD)
			modname = replay.mod:gsub("%.tbm$", "")
			download_mod(modname)
			local wait = 0
			local downloadWait = loading:addChild({ })
			downloadWait:addCustomDisplay(true, function()
					wait = wait + 1
					if (not modFile:isDownloading() and wait > 5) then
						loading:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
						local framesN = 0
						downloadWait:addCustomDisplay(true, function()
								framesN = framesN + 1
								if (framesN > 4) then
									open_replay(replayFile, cacheMode)
									self.GameHud.cacheMode = cacheMode
									self.GameHud.queue = replayQueue
									self.GameHud.currentQueueIndex = replayIdx
									close_menu()
								end
							end)
					end
				end)
		else
			local wait = 0
			loading:addCustomDisplay(false, function()
					loading:uiText(TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
					wait = wait + 1
					if (wait > 4) then
						open_replay(replayFile, cacheMode)
						self.GameHud.cacheMode = cacheMode
						self.GameHud.queue = replayQueue
						self.GameHud.currentQueueIndex = replayIdx
						close_menu()
					end
				end)
		end
	else
		local wait = 0
		loading:addCustomDisplay(false, function()
				loading:uiText(TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
				wait = wait + 1
				if (wait > 4) then
					open_replay(replayFile, cacheMode)
					self.GameHud.cacheMode = cacheMode
					self.GameHud.queue = replayQueue
					self.GameHud.currentQueueIndex = replayIdx
					close_menu()
				end
			end)
	end
end

function Replays.ResetCache()
	local file = Files.Open("../replay/replaycache.dat", FILES_MODE_WRITE)
	if (not file.data) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORREFRESHINGCACHE)
	end
	file:close()
	Replays.RootFolder.replays = nil
	Replays.RootFolder.folders = nil
	ReplaysInternal.SelectedFolder = { fullname = "replay" }
	Replays:showMain(TBMenu.CurrentSection)
end

---Displays list of replays in the specified folder
---@param viewElement UIElement
---@param replayInfo UIElement
---@param level ReplayDirectory?
---@param doSearch boolean?
function Replays:showList(viewElement, replayInfo, level, doSearch)
	viewElement:kill(true)

	local elementHeight = math.clamp(math.ceil(WIN_H / 20), 40, 55)
	local rplTable = level or Replays.RootFolder
	ReplaysInternal.SelectedFolder = rplTable

	local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(viewElement, math.max(50, math.ceil(WIN_H / 16)), elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

	TBMenu:addBottomBloodSmudge(botBar, 1)

	local replaysTitle = topBar:addChild({
		pos = { 10, 0 },
		size = { topBar.size.w * 0.667 - 20, topBar.size.h }
	})
	local replaysTitleStr = TB_MENU_LOCALIZED.MAINMENUREPLAYSNAME
	if (rplTable.fullname ~= "replay") then
		replaysTitleStr = replaysTitleStr .. " - " .. rplTable.name
	end
	replaysTitle:addAdaptedText(true, replaysTitleStr, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, 0.2)

	if (rplTable.fullname ~= "replay/autosave") then
		local posX = 0
		if (rplTable.fullname ~= "replay/my replays" and rplTable.fullname ~= "replay") then
			local editFolderButton = topBar:addChild({
				pos = { -topBar.size.h + 5, 5 },
				size = { topBar.size.h - 10, topBar.size.h - 10 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			editFolderButton:addChild({ shift = { 5, 5 }, bgImage = "../textures/menu/general/buttons/edit.tga" })
			posX = editFolderButton.shift.x
			editFolderButton:addMouseHandlers(nil, function()
					Replays:showEditFolderWindow(ReplaysInternal.SelectedFolder)
				end)
		elseif (rplTable.fullname == "replay") then
			local refreshCacheButton = topBar:addChild({
				pos = { -topBar.size.h + 5, 5 },
				size = { topBar.size.h - 10, topBar.size.h - 10 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			refreshCacheButton:addChild({ shift = { 5, 5 }, bgImage = "../textures/menu/general/buttons/reload.tga" })
			posX = refreshCacheButton.shift.x
			refreshCacheButton:addMouseHandlers(nil, function()
					TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYSREFRESHCACHEPROMPT, Replays.ResetCache)
				end)
		end

		local addFolderButton = topBar:addChild({
			pos = { topBar.size.w / 3 * 2 + 10, 5 },
			size = { topBar.size.w / 3 - 15 + posX, topBar.size.h - 10 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		addFolderButton:addAdaptedText(TB_MENU_LOCALIZED.REPLAYSADDFOLDER)
		addFolderButton:addMouseHandlers(nil, function()
				Replays:showNewFolderWindow()
			end)
	end

	local searchInputField = TBMenu:spawnSearchBar(TB_MENU_REPLAYS_SEARCH, TB_MENU_LOCALIZED.SEARCHNOTE)
	local searchFunction = function()
		if (searchInputField.textfieldstr[1] == "") then
			TB_MENU_REPLAYS_SEARCH = nil
			Replays:showList(viewElement, replayInfo, level)
		else
			TB_MENU_REPLAYS_SEARCH = searchInputField.textfieldstr[1]
			Replays:showSearchList(listingView, replayInfo, toReload, Replays:findReplays(searchInputField.textfieldstr, rplTable))
		end
		searchInputField.btnDown()
		searchInputField.btnUp()
	end
	searchInputField:addEnterAction(searchFunction)

	if (doSearch) then
		Replays:showSearchList(listingView, replayInfo, toReload, Replays:findReplays(TB_MENU_REPLAYS_SEARCH, rplTable))
		return
	end

	local listElements = {}
	if (rplTable.fullname ~= Replays.RootFolder.fullname) then
		local folderElementHolder = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, folderElementHolder)
		local folderElement = folderElementHolder:addChild({
			pos = { 6, 2 },
			size = { folderElementHolder.size.w - 6, folderElementHolder.size.h - 4 },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 3
		})
		folderElement:addMouseHandlers(nil, function()
				ReplaysInternal.SelectedReplay.replay = nil
				Replays:showList(viewElement, replayInfo, rplTable.parent)
			end)
		local folderIcon = UIElement:new({
			parent = folderElement,
			pos = { 10, 0 },
			size = { folderElement.size.h, folderElement.size.h },
			bgImage = "../textures/menu/general/back.tga"
		})
		local folderName = UIElement:new({
			parent = folderElement,
			pos = { folderIcon.shift.x * 2 + folderElement.size.h, 0 },
			size = { folderElement.size.w - folderElement.size.h - folderIcon.shift.x * 3, folderElement.size.h }
		})
		folderName:addAdaptedText(true, rplTable.parent.name, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.8, 0.8)
	end
	for _, folder in pairs(rplTable.folders or {}) do
		local folderElementHolder = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, folderElementHolder)
		local folderElement = folderElementHolder:addChild({
			pos = { 6, 2 },
			size = { folderElementHolder.size.w - 6, folderElementHolder.size.h - 4 },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 3
		})
		folderElement:addMouseHandlers(nil, function()
				ReplaysInternal.SelectedReplay.replay = nil
				Replays:showList(viewElement, replayInfo, folder)
			end)
		local folderIcon = UIElement:new({
			parent = folderElement,
			pos = { 10, folderElement.size.h / 4 },
			size = { folderElement.size.h / 2, folderElement.size.h / 2 },
			bgImage = "../textures/menu/general/folder.tga"
		})
		local folderName = UIElement:new({
			parent = folderElement,
			pos = { folderIcon.shift.x * 2 + folderIcon.size.w, 0 },
			size = { folderElement.size.w - folderIcon.size.w - folderIcon.shift.x * 3, folderElement.size.h }
		})
		folderName:addAdaptedText(true, folder.name, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.8, 0.8)
	end
	for i, replay in pairs(rplTable.replays or {}) do
		local replayElementHolder = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, replayElementHolder)
		local replayElement = replayElementHolder:addChild({
			pos = { 6, 2 },
			size = { replayElementHolder.size.w - 6, replayElementHolder.size.h - 4 },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 3
		})
		if (ReplaysInternal.SelectedReplay.replay and ReplaysInternal.SelectedReplay.replay.filename == replay.filename or i == 1) then
			ReplaysInternal.SelectedReplay.element = replayElement
			ReplaysInternal.SelectedReplay.defaultColor = table.clone(replayElement.bgColor)
		end
		replayElement:addMouseHandlers(nil, function()
				if (ReplaysInternal.SelectedReplay.element == replayElement and ReplaysInternal.SelectedReplay.time + 0.5 > os.clock_real()) then
					Replays:playReplay(replay, rplTable.replays, i)
					return
				end
				ReplaysInternal.SelectedReplay.time = os.clock_real()
				---@diagnostic disable-next-line: assign-type-mismatch
				ReplaysInternal.SelectedReplay.element.bgColor = table.clone(ReplaysInternal.SelectedReplay.defaultColor)
				ReplaysInternal.SelectedReplay.element = replayElement
				ReplaysInternal.SelectedReplay.defaultColor = table.clone(replayElement.bgColor)
				Replays:showReplayInfo(replayInfo, rplTable.replays, i)
			end)

		local replayName = UIElement:new({
			parent = replayElement,
			pos = { 10, 0 },
			size = { replayElement.size.w / 2 - 20, replayElement.size.h }
		})
		replayName:addAdaptedText(true, replay.name, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.65, 0.65)
		local replayNameSeparator = UIElement:new({
			parent = replayElement,
			pos = { replayName.shift.x + replayName.size.w, replayElement.size.h / 4 },
			size = { 1, replayElement.size.h / 2 },
			bgColor = { 1, 1, 1, 0.2 }
		})
		local replayAuthor = UIElement:new({
			parent = replayElement,
			pos = { replayNameSeparator.shift.x, 0 },
			size = { replayElement.size.w / 6, replayElement.size.h }
		})
		local replayAuthorStr = replay.author == "autosave" and TB_MENU_LOCALIZED.REPLAYSAUTHORAUTOSAVE or TB_MENU_LOCALIZED.REPLAYSAUTHORBY .. " " .. replay.author
		replayAuthor:addAdaptedText(true, replayAuthorStr, nil, nil, FONTS.LMEDIUM, nil, 0.65, 0.65)
		local replayAuthorSeparator = UIElement:new({
			parent = replayElement,
			pos = { replayAuthor.shift.x + replayAuthor.size.w, replayElement.size.h / 4 },
			size = { 1, replayElement.size.h / 2 },
			bgColor = { 1, 1, 1, 0.2 }
		})
		local replayMod = UIElement:new({
			parent = replayElement,
			pos = { replayAuthorSeparator.shift.x, 0 },
			size = { replayElement.size.w - replayAuthorSeparator.shift.x, replayElement.size.h }
		})
		replayMod:addAdaptedText(true, replay.mod, nil, nil, FONTS.LMEDIUM, nil, 0.65, 0.65)
	end

	if (#listElements * elementHeight > listingHolder.size.h) then
		for _, v in pairs(listElements) do
			v:hide()
		end
		local listingScrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingScrollBar:makeScrollBar(listingHolder, listElements, toReload)
	else
		listingHolder:moveTo((listingView.size.w - listingHolder.size.w) / 4)
	end
	if (ReplaysInternal.SelectedReplay.replay ~= nil) then
		Replays:showReplayInfo(replayInfo, ReplaysInternal.SelectedReplay.list, ReplaysInternal.SelectedReplay.idx)
	else
		Replays:showReplayInfo(replayInfo, rplTable.replays, 1)
	end
end

function Replays:showReplayTaglistTag(viewElement, updatedTags, tag, elementHeight, posInfo, popularTags)
	local width = get_string_length(tag, 4) * 0.7 + 34
	if (width > viewElement.size.w) then
		width = viewElement.size.w
	end
	if (width + posInfo.x > viewElement.size.w) then
		posInfo.x = 0
		posInfo.y = posInfo.y + elementHeight
	end
	local replayTag = UIElement:new({
		parent = viewElement,
		pos = { posInfo.x, posInfo.y },
		size = { width, elementHeight }
	})
	local replayTagName = UIElement:new({
		parent = replayTag,
		pos = { 10, 0 },
		size = { replayTag.size.w, replayTag.size.h }
	})
	replayTagName:addAdaptedText(true, tag, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7, 0.7)
	local replayTagRemoveButton = UIElement:new({
		parent = replayTag,
		pos = { -24, 3 },
		size = { 24, 24 },
		shapeType = ROUNDED,
		rounded = 3,
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	local tagRemoveIcon = UIElement:new({
		parent = replayTagRemoveButton,
		pos = { 4, 4 },
		size = { 16, 16 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})
	replayTagRemoveButton:addMouseHandlers(nil, function()
			for i,v in pairs(updatedTags) do
				if (v == tag) then
					table.remove(updatedTags, i)
					for j, k in pairs(popularTags) do
						if (j == tag) then
							Replays:tagButtonActivate(k)
							break
						end
					end
					break
				end
			end
			viewElement:kill(true)
			posInfo.x, posInfo.y = 0, 0
			for _, tag in pairs(updatedTags) do
				Replays:showReplayTaglistTag(viewElement, updatedTags, tag, elementHeight, posInfo, popularTags)
			end
		end)
	posInfo.x = posInfo.x + width
end

function Replays:tagButtonDeactivate(tagAdd)
	tagAdd:deactivate()
	tagAdd:addCustomDisplay(false, function() end)
	tagAdd:updateImage("../textures/menu/general/buttons/checkmark.tga")
	tagAdd.bgColor = { 1, 1, 1, 0.2 }
end

function Replays:tagButtonActivate(tagAdd)
	tagAdd:updateImage(nil)
	tagAdd:activate()
	tagAdd:addCustomDisplay(false, function()
			set_color(1, 1, 1, 0.8)
			draw_quad(	tagAdd.pos.x + tagAdd.size.w / 2 - 1,
						tagAdd.pos.y + 4,
						2,
						tagAdd.size.h - 8	)
			draw_quad(	tagAdd.pos.x + 4,
						tagAdd.pos.y + tagAdd.size.h / 2 - 1,
						tagAdd.size.w - 8,
						2	)
		end)
	tagAdd.bgColor = { 0, 0, 0, 0.3 }
end

---Spawns replay tags manager window
---@param replay ReplayInfo
function Replays:showTagsModify(replay)
	---@type string[]
	local updatedTags = {}
	for i in string.gmatch(replay.tags, "%S+") do
		table.insert(updatedTags, i)
	end

	---@type UIElement[]
	local popularTagButtons, assignedTagButtons = {}, {}

	local tagsOverlay = TBMenu:spawnWindowOverlay()
	local windowSize = { x = math.min(900, tagsOverlay.size.w * 0.7), y = math.min(500, tagsOverlay.size.h * 0.6) }
	local tagsView = tagsOverlay:addChild({
		pos = { (tagsOverlay.size.w - windowSize.x) / 2, (tagsOverlay.size.h - windowSize.y) / 2 },
		size = { windowSize.x, windowSize.y },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local tagsTitle = tagsView:addChild({
		pos = { tagsView.size.h / 8, 0 },
		size = { tagsView.size.w - tagsView.size.h / 4, tagsView.size.h / 8 }
	})
	tagsTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSTAGSMODIFYING .. " " .. replay.name ..  " " .. TB_MENU_LOCALIZED.REPLAYSTAGSNAME, nil, nil, FONTS.BIG, nil, 0.75, 0.4, 0.6)
	local closeButtonSize = math.min(45, tagsTitle.size.h - 20)
	local closeButton = tagsView:addChild({
		pos = { -closeButtonSize - 10, 10 },
		size = { closeButtonSize, closeButtonSize },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	closeButton:addMouseUpHandler(function() tagsOverlay:kill() end)
	closeButton:addChild({ shift = { closeButtonSize / 5, closeButtonSize / 5 }, bgImage = "../textures/menu/general/buttons/crosswhite.tga" })

	local elementHeight = 35
	local popularTagsView = tagsView:addChild({
		shift = { 10, tagsTitle.shift.y + tagsTitle.size.h }
	})
	popularTagsView.size.h = math.floor(popularTagsView.size.h / 2)
	local popularTagsTitle = popularTagsView:addChild({
		pos = { 0, 0 },
		size = { popularTagsView.size.w, elementHeight }
	})
	popularTagsTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSPOPULARTAGS, nil, nil, nil, LEFTMID)
	---@type Vector2Base
	popularTagsView.buttonsShift = { x = 0, y = popularTagsTitle.shift.y + popularTagsTitle.size.h }

	local currentTagsView = tagsView:addChild({
		pos = { 10, popularTagsView.shift.y + popularTagsView.size.h },
		size = { tagsView.size.w - 20, popularTagsView.size.h }
	})
	local currentTagsTitle = currentTagsView:addChild({
		pos = { 0, 0 },
		size = { currentTagsView.size.w, elementHeight }
	})
	currentTagsTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSASSIGNEDTAGS, nil, nil, nil, LEFTMID)

	local function reloadAssignedTags()
		---@type Vector2Base
		currentTagsView.buttonsShift = { x = 0, y = currentTagsTitle.shift.y + currentTagsTitle.size.h }
		for _, v in pairs(assignedTagButtons) do
			v:kill()
		end

		for i, tag in pairs(updatedTags) do
			local tagViewBG = currentTagsView:addChild({
				pos = { currentTagsView.buttonsShift.x, currentTagsView.buttonsShift.y },
				size = { currentTagsView.size.w, elementHeight },
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			tagViewBG:addAdaptedText(tag, nil, nil, 4, nil, 0.8)
			tagViewBG.size.w = get_string_length(tagViewBG.dispstr[1], tagViewBG.textFont) * tagViewBG.textScale + 22 + tagViewBG.size.h
			tagViewBG:addCustomDisplay(false, function() end)

			if (tagViewBG.size.w > currentTagsView.size.w - currentTagsView.buttonsShift.x) then
				currentTagsView.buttonsShift.y = currentTagsView.buttonsShift.y + elementHeight + 6
				if (currentTagsView.buttonsShift.y + elementHeight > currentTagsView.size.h) then
					tagViewBG:kill()
					break
				end
				tagViewBG:moveTo(0, currentTagsView.buttonsShift.y)
			end
			currentTagsView.buttonsShift.x = tagViewBG.shift.x + tagViewBG.size.w + 6

			table.insert(assignedTagButtons, tagViewBG)
			local tagView = tagViewBG:addChild({
				shift = { 1, 1 },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			}, true)
			tagView:addChild({
				pos = { 0, 0 },
				size = { tagView.size.w - tagView.size.h, tagView.size.h }
			}):addAdaptedText(true, tag, nil, nil, tagViewBG.textFont, nil, tagViewBG.textScale)
			local tagRemoveButton = tagViewBG:addChild({
				pos = { -tagViewBG.size.h, 0 },
				size = { tagViewBG.size.h, tagViewBG.size.h },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			}, true)
			tagRemoveButton:addChild({
				shift = { 5, 5 },
				bgImage = "../textures/menu/general/buttons/crosswhite.tga"
			})
			tagRemoveButton:addMouseUpHandler(function()
					if (popularTagButtons[tag] ~= nil) then
						popularTagButtons[tag]:activate()
					end
					table.remove(updatedTags, i)
					reloadAssignedTags()
				end)
		end
	end

	for _, tag in pairs(Replays.GetPopularTags()) do
		local tagButton = popularTagsView:addChild({
			pos = { popularTagsView.buttonsShift.x, popularTagsView.buttonsShift.y },
			size = { popularTagsView.size.w, elementHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
			shapeType = ROUNDED,
			rounded = 4
		})
		tagButton:addAdaptedText(tag, nil, nil, 4, nil, 0.8)
		tagButton:addMouseUpHandler(function()
				table.insert(updatedTags, tag)
				tagButton:deactivate()
				reloadAssignedTags()
			end)
		tagButton.size.w = get_string_length(tagButton.dispstr[1], tagButton.textFont) * tagButton.textScale + 30
		if (tagButton.size.w > popularTagsView.size.w - popularTagsView.buttonsShift.x) then
			popularTagsView.buttonsShift.y = popularTagsView.buttonsShift.y + elementHeight + 6
			if (popularTagsView.buttonsShift.y + elementHeight > popularTagsView.size.h) then
				tagButton:kill()
				break
			end
			tagButton:moveTo(0, popularTagsView.buttonsShift.y)
		end
		popularTagButtons[tag] = tagButton
		popularTagsView.buttonsShift.x = tagButton.shift.x + tagButton.size.w + 6
		tagButton:setActive(not replay.tags:find(tag))
	end
	reloadAssignedTags()

	local tagsInputView = tagsView:addChild({
		pos = { 10, -50 },
		size = { tagsView.size.w / 2 - 10, 40 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	}, true)
	local tagInputField = TBMenu:spawnTextField2(tagsInputView, {
			w = tagsInputView.size.w - 100
		}, nil, TB_MENU_LOCALIZED.REPLAYSINPUTTAGHERE, {
			fontId = 4,
			textScale = 0.8
		})
	local tagAddFunction = function()
			local tagString = tagInputField.textfieldstr[1]
			if (tagString:gsub("%A", "") == "" or tagString:len() < 2) then
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSTAGERRORSHORT)
				return
			end
			for _, v in pairs(updatedTags) do
				if (v == tagString) then
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSTAGERRORDUPLICATE)
					return
				end
			end
			tagInputField:clearTextfield()
			table.insert(updatedTags, tagString)
			reloadAssignedTags()
		end
	tagInputField:addEnterAction(tagAddFunction)

	local tagAddButton = tagsInputView:addChild({
		pos = { -100, 0 },
		size = { 100, tagsInputView.size.h },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	tagAddButton:addAdaptedText(TB_MENU_LOCALIZED.BUTTONADD)
	tagAddButton:addMouseUpHandler(tagAddFunction)

	local buttonSave = tagsView:addChild({
		pos = { tagsView.size.w / 3 * 2, -50 },
		size = { tagsView.size.w / 3 - 10, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	buttonSave:addAdaptedText(TB_MENU_LOCALIZED.BUTTONSAVE)
	buttonSave:addMouseHandlers(nil, function()
			local newReplay = ReplayInfo.New(replay)
			newReplay.tags = table.implode(updatedTags, " ")
			if (newReplay.tags == replay.tags) then
				return
			end

			if (Replays:updateReplayCache(replay, newReplay)) then
				replay.tags = newReplay.tags
			end
			tagsOverlay:kill()
			Replays:showMain(TBMenu.CurrentSection)
		end)
end

---Displays folder manager window
---@param folder ReplayDirectory
function Replays:showEditFolderWindow(folder)
	local editFolderOverlay = TBMenu:spawnWindowOverlay()
	local editFolderView = editFolderOverlay:addChild({
		shift = { editFolderOverlay.size.w / 4, editFolderOverlay.size.h / 2 - 100 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})

	local closeButtonSize = 40
	local editFolderTitle = editFolderView:addChild({
		pos = { closeButtonSize * 1.5, 0 },
		size = { editFolderView.size.w - closeButtonSize * 3, 60 }
	})
	editFolderTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSTAGSMODIFYING .. " \"" .. ReplaysInternal.SelectedFolder.fullname .. "\" " .. TB_MENU_LOCALIZED.REPLAYSMODIFYINGFOLDER, nil, nil, FONTS.BIG)

	local closeButton = editFolderView:addChild({
		pos = { -closeButtonSize - 10, 10 },
		size = { closeButtonSize, closeButtonSize },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	closeButton:addMouseUpHandler(function() editFolderOverlay:kill() end)
	closeButton:addChild({ shift = { closeButtonSize / 5, closeButtonSize / 5 }, bgImage = "../textures/menu/general/buttons/crosswhite.tga" })

	local newFolderInput = TBMenu:spawnTextField2(editFolderView, {
		x = 10, y = editFolderView.size.h / 2 - 20,
		w = editFolderView.size.w - 20, h = 40
	}, ReplaysInternal.SelectedFolder.name, TB_MENU_LOCALIZED.REPLAYSFOLDERNAME, {
		textAlign = LEFTMID,
		fontId = 4,
		textScale = 0.8
	})

	local deleteButton = editFolderView:addChild({
		pos = { 10, -50 },
		size = { editFolderView.size.w / 3 - 10, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	deleteButton:addAdaptedText(TB_MENU_LOCALIZED.WORDDELETE)
	deleteButton:addMouseHandlers(nil, function()
			local function delete_folder(folder)
				local parentFolder = folder.fullname:gsub("/" .. folder.name .. "$", "")
				local error = remove_replay_subfolder(folder.fullname:gsub("^replay/", ""))
				if (error ~= nil) then
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORDELETING .. " " .. TB_MENU_LOCALIZED.REPLAYSERRORDELETINGFOLDER .. " " .. folder.fullname .. ": " .. error)
					return
				end
				ReplaysInternal.SelectedFolder = { fullname = parentFolder }
			end
			if (#ReplaysInternal.SelectedFolder.replays == 0 and #ReplaysInternal.SelectedFolder.folders == 0) then
				delete_folder(ReplaysInternal.SelectedFolder)
				editFolderOverlay:kill()
				Replays:showMain(TBMenu.CurrentSection)
			else
				local function delete_folder_with_files(folder, targetFolder)
					local targetFolder = targetFolder or folder.fullname:gsub("^replay/", ""):gsub(folder.name .. ".*$", "")
					for _, v in pairs(folder.folders) do
						delete_folder_with_files(v, targetFolder)
					end
					for _, v in pairs(folder.replays) do
						local newFilename = targetFolder .. v.filename:gsub("^.*/", "")
						local error = rename_replay(v.filename, newFilename)
						if (error ~= nil) then
							TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORMOVING .. " " .. v.filename .. " " .. TB_MENU_LOCALIZED.REPLAYSERRORMOVINGTO .. " " .. newFilename .. ": " .. error)
							return
						end
					end
					delete_folder(folder)
				end
				TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYSFOLDERNOTEMPTYDELETEWARNING, function() delete_folder_with_files(ReplaysInternal.SelectedFolder) editFolderOverlay:kill() Replays:showMain(TBMenu.CurrentSection) end)
			end
		end)

	local saveButton = editFolderView:addChild({
		pos = { editFolderView.size.w / 3 + 10, -50 },
		size = { editFolderView.size.w / 3 * 2 - 20, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	saveButton:addAdaptedText(TB_MENU_LOCALIZED.BUTTONSAVE)
	saveButton:addMouseHandlers(nil, function()
			local newFolderName = newFolderInput.textfieldstr[1]:gsub("%s+$", ""):gsub("^%s+", "")
			local parentFolder = ReplaysInternal.SelectedFolder.fullname:gsub(ReplaysInternal.SelectedFolder.name .. "$", "")
			if (ReplaysInternal.SelectedFolder.name == newFolderName) then
				editFolderOverlay:kill()
				return
			end
			local error = rename_replay_subfolder(ReplaysInternal.SelectedFolder.fullname:gsub("^replay/", ""), parentFolder:gsub("^replay/", "") .. newFolderName)
			if (error ~= nil) then
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORRENAMINGFOLDER .. ": " .. error)
				return
			end
			ReplaysInternal.SelectedFolder = { fullname = parentFolder .. newFolderName }
			editFolderOverlay:kill()
			Replays:showMain(TBMenu.CurrentSection)
		end)
end

---Displays new replay folder creation window
function Replays:showNewFolderWindow()
	local _, level = ReplaysInternal.SelectedFolder.fullname:gsub("/", "")
	if (level > ReplaysInternal.MaxFolderLevels - 1) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSFOLDERLEVELERROR1 ..  " " .. ReplaysInternal.MaxFolderLevels .. " " .. TB_MENU_LOCALIZED.REPLAYSFOLDERLEVELERROR2)
		return
	end
	local newFolderOverlay = TBMenu:spawnWindowOverlay()
	local newFolderView = newFolderOverlay:addChild({
		pos = { newFolderOverlay.size.w / 4, newFolderOverlay.size.h / 2 - 100 },
		size = { newFolderOverlay.size.w / 2, 200 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local closeButtonSize = 40
	local newFolderTitle = UIElement:new({
		parent = newFolderView,
		pos = { closeButtonSize + 20, 0 },
		size = { newFolderView.size.w - (closeButtonSize + 20) * 2, 60 }
	})
	newFolderTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSADDINGFOLDER .. " " .. ReplaysInternal.SelectedFolder.fullname, nil, nil, FONTS.BIG, nil, 0.7, nil, 0.2)

	local closeButton = newFolderView:addChild({
		pos = { -closeButtonSize - 10, 10 },
		size = { closeButtonSize, closeButtonSize },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	closeButton:addMouseUpHandler(function() newFolderOverlay:kill() end)
	closeButton:addChild({ shift = { closeButtonSize / 5, closeButtonSize / 5 }, bgImage = "../textures/menu/general/buttons/crosswhite.tga" })

	local newFolderInput = TBMenu:spawnTextField2(newFolderView, {
		x = 10, y = newFolderView.size.h / 2 - 20,
		w = newFolderView.size.w - 20, h = 40
	}, nil, TB_MENU_LOCALIZED.REPLAYSNEWFOLDERNAME, {
		textAlign = LEFTMID,
		fontId = 4,
		textScale = 0.8
	})

	local saveButton = newFolderView:addChild({
		pos = { newFolderView.size.w / 4, -50 },
		size = { newFolderView.size.w / 2, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	saveButton:addAdaptedText(TB_MENU_LOCALIZED.BUTTONCREATE)

	local function spawnNewFolder()
		---Folders should be only alpha numeric, no utf8 check here
		if (newFolderInput.textfieldstr[1] ~= newFolderInput.textfieldstr[1]:match("[^ ][%w+ ]+")) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSFOLDERALPHANUMERIC)
			return
		end

		local parentFolder = utf8.gsub(ReplaysInternal.SelectedFolder.fullname, "^replay/*", "")
		parentFolder = parentFolder:len() > 0 and parentFolder .. "/" or parentFolder
		local newFolderName = parentFolder .. newFolderInput.textfieldstr[1]:gsub(" +$", "")
		local error = add_replay_subfolder(newFolderName)
		if (error ~= nil) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORADDINGFOLDER .. ": " .. error)
			return
		end
		newFolderOverlay:kill()
		ReplaysInternal.SelectedFolder = { fullname = "replay/" .. newFolderName }
		Replays:showMain(TBMenu.CurrentSection)
	end

	newFolderInput:addEnterAction(spawnNewFolder)
	saveButton:addMouseUpHandler(spawnNewFolder)
end

---Displays upload window for the specified replay
---@param replay ReplayInfo
function Replays:showUploadWindow(replay)
	local uploadOverlay = TBMenu:spawnWindowOverlay()
	local uploadView = uploadOverlay:addChild({
		shift = { uploadOverlay.size.w / 6, (uploadOverlay.size.h - 370) / 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local closeButtonSize = 40
	local uploadTitle = UIElement:new({
		parent = uploadView,
		pos = { closeButtonSize + 20, 0 },
		size = { uploadView.size.w - (closeButtonSize + 20) * 2, 60 }
	})
	uploadTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSUPLOAD .. " " .. replay.name ..  " " .. TB_MENU_LOCALIZED.REPLAYSUPLOADTORIBASHSERVERS, nil, nil, FONTS.BIG, nil, 0.7, nil, 0.2)

	TBMenu:spawnCloseButton(uploadView, { x = -closeButtonSize - 10, y = 10, w = closeButtonSize, h = closeButtonSize }, function() uploadOverlay:kill() end)

	local replayUploadInfoView = uploadView:addChild({
		shift = { 10, uploadTitle.size.h }
	})

	local replayData = {
		{
			name = TB_MENU_LOCALIZED.REPLAYSNAME,
			desc = TB_MENU_LOCALIZED.REPLAYSNAMEINFO,
			value = { replay.name },
			input = false
		},
		{
			name = TB_MENU_LOCALIZED.REPLAYSDESC,
			desc = TB_MENU_LOCALIZED.REPLAYSDESCINFO,
			value = { "" },
			input = true,
			fulltext = true
		},
		{
			name = TB_MENU_LOCALIZED.REPLAYSTAGS,
			desc = TB_MENU_LOCALIZED.REPLAYSTAGSINFO,
			value = { utf8.gsub(replay.tags .. " " .. replay.hiddentags, "^ +", "") },
			input = true,
			fulltext = true
		}
	}

	local shiftY = 0
	for _, v in pairs(replayData) do
		local replayUploadInfoHolder = replayUploadInfoView:addChild({
			pos = { 0, shiftY },
			size = { replayUploadInfoView.size.w, v.fulltext and 90 or 55 }
		})
		local replayUploadInfoNameTitle = replayUploadInfoHolder:addChild({
			pos = { 0, 0 },
			size = { replayUploadInfoHolder.size.w / 3, 30 }
		})
		replayUploadInfoNameTitle:addAdaptedText(true, v.name, nil, nil, nil, LEFTMID)

		local replayUploadInfoNameDesc = replayUploadInfoHolder:addChild({
			pos = { 0, replayUploadInfoNameTitle.size.h },
			size = { replayUploadInfoNameTitle.size.w, replayUploadInfoHolder.size.h - replayUploadInfoNameTitle.size.h }
		})
		replayUploadInfoNameDesc:addAdaptedText(true, v.desc, nil, nil, 4, LEFT, 0.7)

		local replayUploadInfoDataField = replayUploadInfoHolder:addChild({
			pos = { replayUploadInfoHolder.size.w * 0.4, 0 },
			size = { replayUploadInfoHolder.size.w * 0.6, replayUploadInfoHolder.size.h }
		})
		local replayUploadInputHolder = replayUploadInfoDataField:addChild({
			pos = { 10, 10 },
			size = { replayUploadInfoDataField.size.w - 20, v.fulltext and replayUploadInfoDataField.size.h - 20 or 35 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = uploadView.shapeType,
			rounded = uploadView.rounded
		})
		local replayUploadInput = TBMenu:spawnTextField2(replayUploadInputHolder, nil, v.value, v.tip, {
			allowMultiline = v.fulltext,
			textAlign = v.fulltext and LEFT or LEFTMID,
			fontId = 4,
			textScale = 0.7
		})
		if (not v.input) then
			replayUploadInput:deactivate(true)
			replayUploadInput.parent:deactivate(true)
		end
		shiftY = shiftY + replayUploadInfoHolder.size.h
	end

	local uploadButton = uploadView:addChild({
		pos = { uploadView.size.w / 4, -50 },
		size = { uploadView.size.w / 2, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK
	}, true)
	uploadButton:addCustomDisplay(false, function()
			if (replayData[1].value[1] == "" or replayData[2].value[1] == "") then
				if (uploadButton:isActive()) then
					uploadButton:deactivate()
				end
			elseif (not uploadButton:isActive()) then
				uploadButton:activate()
			end
			uploadButton:uiText(TB_MENU_LOCALIZED.BUTTONUPLOAD)
		end)
	uploadButton:addMouseUpHandler(function()
			local overlay = TBMenu:spawnWindowOverlay()
			local windowScale = { math.min(overlay.size.w / 3, 550), math.min(overlay.size.h / 3, 250) }
			local uploadingView = overlay:addChild({
				pos = { (overlay.size.w - windowScale[1]) / 2, (overlay.size.h - windowScale[2]) / 2 },
				size = { windowScale[1], windowScale[2] },
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			TBMenu:displayLoadingMark(uploadingView, TB_MENU_LOCALIZED.REPLAYUPLOADINPROGRESS)
			Request:queue(function()
					upload_replay(	replayData[1].value[1],
									replayData[2].value[1],
									replayData[3].value[1],
									replay.filename)
				end, "replayupload", function()
					local response = get_network_response()
					overlay:kill()
					if (response:find("^SUCCESS")) then
						uploadOverlay:kill()
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYUPLOADSUCCESSFUL)
					else
						TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADERROR .. ": " .. response:gsub("^ERROR 0;", ""), function() end, function() uploadOverlay:kill() end)
					end
				end, function()
					overlay:kill()
					TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADFAILED .. ": " .. get_network_error(), function() end, function() uploadOverlay:kill() end)
				end)
		end)
end

---Returns `UIDropdown` elements data containing user replay folders hierarchy
---@param onSelectAction function
---@param targetFolder ?string
---@param includeRoot ?boolean
---@return DropdownElement[]
function Replays:getReplayFoldersDropdownOptions(onSelectAction, targetFolder, includeRoot)
	---@type DropdownElement[]
	local dropdownOptions = {}
	local getFolders
	getFolders = function(dir, level)
		if (utf8.len(dir) > 0) then
			dir = dir .. "/"
		end
		for _, v in pairs(get_files("replay/" .. dir, "")) do
			if (not utf8.match(v, ".rpl$") and (dir .. v ~= "system") and not utf8.find(v, "^%.+[%s%S]*$") and not utf8.find(v, "%.%a+$")) then
				---@type string
				local targetPath = (includeRoot and "replay/" or "") .. dir .. v
				table.insert(dropdownOptions, {
					text = (level > 0 and ('' .. string.rep(" ", level * 3)) or '') .. v .. '',
					action = function() onSelectAction(targetPath) end,
					selected = targetPath == targetFolder
				})
				getFolders(dir .. v, level + 1)
			end
		end
	end
	if (includeRoot) then
		table.insert(dropdownOptions, {
			text = "replay",
			action = function() onSelectAction("replay") end,
			selected = "replay" == targetFolder
		})
	end
	pcall(function() getFolders('', includeRoot and 1 or 0) end)
	return dropdownOptions
end

---Displays replay manage window
---@param viewElement any Deprecated
---@param replay ReplayInfo
---@overload fun(self: Replays, replay: ReplayInfo)
function Replays:showReplayManageWindow(viewElement, replay)
	if (replay == nil) then
		replay = viewElement
	end

	local manageOverlay = TBMenu:spawnWindowOverlay()
	local windowSize = { x = math.min(800, manageOverlay.size.w * 0.7), y = math.min(350, manageOverlay.size.h * 0.6) }
	local manageView = manageOverlay:addChild({
		parent = manageOverlay,
		pos = { (manageOverlay.size.w - windowSize.x) / 2, (manageOverlay.size.h - windowSize.y) / 2 },
		size = { windowSize.x, windowSize.y },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})

	local closeButtonSize = 40
	local manageTitle = manageView:addChild({
		parent = manageView,
		pos = { closeButtonSize * 1.5, 0 },
		size = { manageView.size.w - closeButtonSize * 3, manageView.size.h / 7 }
	})
	manageTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSMANAGE .. " \"" .. replay.name .. "\" " .. TB_MENU_LOCALIZED.REPLAYSREPLAY, nil, nil, FONTS.BIG, nil, 0.7, nil, 0.2)

	local closeButton = manageView:addChild({
		pos = { -closeButtonSize - 10, 10 },
		size = { closeButtonSize, closeButtonSize },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	closeButton:addMouseUpHandler(function() manageOverlay:kill() end)
	closeButton:addChild({ shift = { closeButtonSize / 5, closeButtonSize / 5 }, bgImage = "../textures/menu/general/buttons/crosswhite.tga" })

	local filenameClean = utf8.gsub(replay.filename, "^.*/", ""):gsub("%.rpl$", "")
	local replayData = {
		{
			name = TB_MENU_LOCALIZED.FILENAME,
			value = { filenameClean },
			input = true
		},
		{
			name = TB_MENU_LOCALIZED.REPLAYSREPLAYNAME,
			value = { replay.name },
			input = true
		},
		{
			name = TB_MENU_LOCALIZED.REPLAYSREPLAYDIR,
			value = replay.filename:gsub("/[^/]+$", ""),
			dropdown = true
		}
	}

	local elementHeight = manageView.size.h / 7
	local manageInfoView = manageView:addChild({
		shift = { 10, math.floor(manageTitle.size.h * 1.5) }
	})

	for i, v in pairs(replayData) do
		local infoHolder = manageInfoView:addChild({
			pos = { 0, (i - 1) * elementHeight + 5 },
			size = { manageInfoView.size.w, elementHeight - 10 }
		})
		local infoLegend = infoHolder:addChild({
			size = { infoHolder.size.w / 3, infoHolder.size.h }
		})
		infoLegend:addAdaptedText(true, v.name, nil, nil, nil, LEFTMID)

		local dataFieldHolder = infoHolder:addChild({
			pos = { infoLegend.size.w + 10, 0 },
			size = { infoHolder.size.w - infoLegend.size.w - 10, infoHolder.size.h },
			shapeType = manageView.shapeType,
			rounded = manageView.rounded
		})
		if (v.input) then
			TBMenu:spawnTextField2(dataFieldHolder, nil, v.value, v.tip, {
					fontId = 4,
					textScale = 0.8
				})
		elseif (v.dropdown) then
			local dropdownOptions = Replays:getReplayFoldersDropdownOptions(function(path)
					---@type string
					v.value = path
				end, v.value, true)
			local dropdownHolder = dataFieldHolder:addChild({
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			}, true)
			TBMenu:spawnDropdown(dropdownHolder, dropdownOptions, dataFieldHolder.size.h * 0.8, nil, nil, {
					scale = 0.8, fontid = 4, uppercase = true, alignment = LEFTMID
				}, {
					scale = 0.65, fontid = 4, uppercase = true, alignment = LEFTMID
				})
		end
	end

	local saveButton = manageView:addChild({
		pos = { manageView.size.w / 3 + 10, -50 },
		size = { manageView.size.w / 3 * 2 - 20, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	saveButton:addAdaptedText(TB_MENU_LOCALIZED.BUTTONSAVE)

	saveButton:addMouseUpHandler(function()
			local newReplay = ReplayInfo.New(replay)
			newReplay.name = replayData[2].value[1]

			local directory = utf8.gsub(replay.filename, "/[^/]+$", "")
			local fileMove = replayData[3].value ~= directory

			if (replayData[1].value[1] ~= filenameClean or fileMove) then
				local newname = utf8.gsub(replayData[3].value, "^replay(/?)(.*)", "%2%1") .. replayData[1].value[1] .. ".rpl"
				local curname = replay.filename:gsub("^replay/", "")
				local error = rename_replay(curname, newname)
				if (error ~= nil) then
					TBMenu:showStatusMessage((fileMove and TB_MENU_LOCALIZED.REPLAYSERRORMOVINGREPLAY or TB_MENU_LOCALIZED.REPLAYSERRORRENAMINGREPLAY) .. ": " .. error)
					return
				end
				newReplay.filename = "replay/" .. newname
				if (fileMove) then
					ReplaysInternal.SelectedFolder = { fullname = directory }
				end
			end

			Replays:updateReplayCache(replay, newReplay)
			replay:Copy(newReplay)
			manageOverlay:kill()
			Replays:showMain(TBMenu.CurrentSection)
		end)

	local deleteButton = manageView:addChild({
		pos = { 10, -50 },
		size = { manageView.size.w / 3 - 10, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	deleteButton:addAdaptedText(TB_MENU_LOCALIZED.WORDDELETE)
	deleteButton:addMouseHandlers(nil, function()
			TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYSCONFIRMDELETION .. " " .. replay.filename:gsub("^.*/", "") .. " " .. TB_MENU_LOCALIZED.REPLAYSCONFIRMDELETION2, function()
					local error = delete_replay(replay.filename:gsub("^replay/", ""))
					if (error ~= nil) then
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORDELETING .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAY .. ": " .. error)
						return
					end
					manageOverlay:kill()
					Replays:updateReplayCache(replay, nil)
					ReplaysInternal.SelectedReplay.replay = nil
					Replays:showMain(TBMenu.CurrentSection)
				end)
		end)
end

function Replays:canUploadReplay(replay)
	if (replay.uploaded == 1) then
		return false
	end

	local isInReplay = false
	local nameLower = string.lower(TB_MENU_PLAYER_INFO.username)
	if (string.lower(replay.author) == nameLower) then
		isInReplay = true
	end
	for _, v in pairs(replay.bouts) do
		if (string.lower(v) == nameLower) then
			isInReplay = true
		end
	end
	return isInReplay
end

---Displays replay autosave toggle that automatically modifies the corresponding game option
---@param viewElement UIElement
---@return UIElement
function Replays:showAutosaveToggle(viewElement)
	local autosaveStatus = tonumber(get_option("autosave")) or 0
	local buttonHeight = math.min(viewElement.size.h / 10, 64)
	local autosaveView = viewElement:addChild({
		pos = { 10, -buttonHeight - 10 },
		size = { viewElement.size.w - 20, buttonHeight },
		shapeType = ROUNDED,
		rounded = 3,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	local toggle = TBMenu:spawnToggle(autosaveView, 8, 8, autosaveView.size.h - 16, autosaveView.size.h - 16, autosaveStatus, function(value)
			set_option("autosave", value)
		end)
	local autosaveText = autosaveView:addChild({
		pos = { toggle.size.h + 20, 0 },
		size = { autosaveView.size.w - toggle.size.h - 30, autosaveView.size.h }
	})
	autosaveText:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSAUTOSAVEOPTION, nil, nil, nil, LEFTMID)
	return autosaveView
end

---@param viewElement UIElement
---@param replaysList ReplayInfo[]
---@param replayIdx integer
function Replays:showReplayInfo(viewElement, replaysList, replayIdx)
	viewElement:kill(true)
	TBMenu:addBottomBloodSmudge(viewElement, 2)

	local buttonWidth = viewElement.size.w - 20
	local buttonHeight = math.min(viewElement.size.h / 10, 64)
	local replay = replaysList[replayIdx]
	if (not replay) then
		local heightMod = 0
		if (ReplaysInternal.SelectedFolder.fullname == "replay/autosave") then
			Replays:showAutosaveToggle(viewElement)
			heightMod = viewElement.size.h / 8
		end
		local noReplaysFound = viewElement:addChild({
			pos = { 10, 10 },
			size = { buttonWidth, viewElement.size.h - 20 - heightMod }
		})
		noReplaysFound:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSEMPTYFOLDER)
		return
	end

	ReplaysInternal.SelectedReplay.replay = replay
	ReplaysInternal.SelectedReplay.list = replaysList
	ReplaysInternal.SelectedReplay.idx = replayIdx
	if (ReplaysInternal.SelectedReplay.element) then
		-- Element can be null judging by crash logs but I can't replicate it
		-- Let's hope having this check doesn't spawn more errors
		ReplaysInternal.SelectedReplay.element.bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	end

	local replayName = viewElement:addChild({
		pos = { 10, 0 },
		size = { buttonWidth, math.min(viewElement.size.h / 8, 100) }
	})
	replayName:addAdaptedText(true, replay.name, nil, nil, FONTS.BIG, nil, 0.65, 0.4, 0.2)
	local replayAuthor = viewElement:addChild({
		pos = { 10, replayName.shift.y + replayName.size.h },
		size = { buttonWidth, buttonHeight }
	})
	local replayAuthorStr = replay.author == "autosave" and "autosave" or TB_MENU_LOCALIZED.REPLAYSBY .. " " .. replay.author
	replayAuthor:addAdaptedText(true, replayAuthorStr, nil, nil, FONTS.LMEDIUM, nil, 0.8, 0.8)
	local replayBouts = viewElement:addChild({
		pos = { 10, replayAuthor.shift.y + replayAuthor.size.h },
		size = { buttonWidth, replayName.size.h / 2 }
	})
	local replayBoutsStr = replay.bouts[1] ~= " " and replay.bouts[1] or TB_MENU_LOCALIZED.REPLAYSDATACORRUPT
	for i = 2, #replay.bouts do
		replayBoutsStr = replay.bouts[i] ~= " " and replayBoutsStr .. " " .. TB_MENU_LOCALIZED.WORDVS .. " " .. replay.bouts[i] or replayBoutsStr
	end
	replayBouts:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSPLAYERS .. ": " .. replayBoutsStr, nil, nil, 4, LEFTBOT, 0.7)
	local replayMod = viewElement:addChild({
		pos = { 10, replayBouts.shift.y + replayBouts.size.h },
		size = { buttonWidth, replayBouts.size.h }
	})
	replayMod:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSMOD .. ": " .. replay.mod, nil, nil, 4, LEFTMID, 0.7)
	local replayTags = UIElement:new({
		parent = viewElement,
		pos = { 10, replayMod.shift.y + replayMod.size.h },
		size = { buttonWidth, replayName.size.h }
	})
	local tagsText = replay.tags == " " and TB_MENU_LOCALIZED.WORDNONE or replay.tags
	replayTags:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSTAGS .. ": " .. tagsText, nil, nil, FONTS.LMEDIUM, LEFT, 0.7, 0.7)

	local tagsAdapted = textAdapt(TB_MENU_LOCALIZED.REPLAYSTAGS .. ": " .. tagsText, 4, 0.7, viewElement.size.w - 20)
	local tagsDispositionX = get_string_length(tagsAdapted[#tagsAdapted], 4) * 0.7
	local tagsDispositionY = math.ceil((#tagsAdapted - 1) * 16.8) + 1
	local linesBack = 0
	while (tagsDispositionY + 18 > replayTags.size.h) do
		tagsDispositionY = tagsDispositionY - 18
		linesBack = linesBack + 1
		tagsDispositionX = get_string_length(tagsAdapted[#tagsAdapted - linesBack], 4) * 0.7
	end
	if (tagsDispositionX + 10 > replayTags.size.w) then
		tagsDispositionX = 0
		tagsDispositionY = tagsDispositionY + 18
	end
	local replayTagsAdd = replayTags:addChild({
		pos = { tagsDispositionX, tagsDispositionY },
		size = { 18, 18 },
		shapeType = ROUNDED,
		rounded = 3,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	replayTagsAdd:addCustomDisplay(false, function()
			set_color(1, 1, 1, 0.8)
			draw_quad(	replayTagsAdd.pos.x + replayTagsAdd.size.w / 2 - 1,
						replayTagsAdd.pos.y + 4,
						2,
						replayTagsAdd.size.h - 8	)
			draw_quad(	replayTagsAdd.pos.x + 4,
						replayTagsAdd.pos.y + replayTagsAdd.size.h / 2 - 1,
						replayTagsAdd.size.w - 8,
						2	)
		end)
	replayTagsAdd:addMouseUpHandler(function()
			Replays:showTagsModify(replay)
		end)

	local posY = -10
	if (ReplaysInternal.SelectedFolder.fullname == "replay/autosave") then
		local autosaveToggleView = Replays:showAutosaveToggle(viewElement)
		posY = autosaveToggleView.shift.y - 10
	end

	local supportsFileSharing = _G.PLATFORM == "IPHONEOS" or _G.PLATFORM == "ANDROID"
	local buttonManageWidth = supportsFileSharing and buttonWidth - buttonHeight - 10 or buttonWidth
	local replayManageButton = viewElement:addChild({
		pos = { 10, -buttonHeight + posY },
		size = { buttonManageWidth, buttonHeight },
		interactive = true,
		shapeType = ROUNDED,
		rounded = 3,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	replayManageButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSMANAGE)
	replayManageButton:addMouseHandlers(nil, function()
			Replays:showReplayManageWindow(replay)
		end)
	if (supportsFileSharing) then
		local replayShareButton = viewElement:addChild({
			pos = { replayManageButton.shift.x + replayManageButton.size.w + 10, replayManageButton.shift.y },
			size = { replayManageButton.size.h, replayManageButton.size.h },
			bgImage = _G.PLATFORM == "IPHONEOS" and "../textures/menu/general/buttons/share-ios.tga" or "../textures/menu/general/buttons/share-android.tga",
			shapeType = ROUNDED,
			rounded = 3,
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		})
		replayShareButton:addMouseUpHandler(function()
			share_file(replay.filename)
		end)
	end
	posY = replayManageButton.shift.y - 10

	if (Replays:canUploadReplay(replay)) then
		local replayUploadButton = viewElement:addChild({
			pos = { 10, -buttonHeight + posY },
			size = { buttonWidth, buttonHeight },
			interactive = not replay.uploaded,
			shapeType = ROUNDED,
			rounded = 3,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK
		})
		replayUploadButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONUPLOAD)
		replayUploadButton:addMouseHandlers(nil, function()
				Replays:showUploadWindow(replay)
			end)
		posY = replayUploadButton.shift.y - 10
	end

	local replayViewButton = viewElement:addChild({
		pos = { 10, -buttonHeight + posY },
		size = { buttonWidth, buttonHeight },
		shapeType = ROUNDED,
		rounded = 3,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	replayViewButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONVIEW)
	replayViewButton:addMouseHandlers(nil, function()
			Replays:playReplay(replay, replaysList, replayIdx)
		end)
end

---Displays community replays search window
function Replays:showSearchWindow()
	local lastSearchData = utf8.explode(Replays.ServerCacheSettings.search, "&")
	local searchOptions = {
		{
			text = TB_MENU_LOCALIZED.REPLAYSFILTERSNAME,
			targetField = "replayname",
			value = { "" }
		},
		{
			text = TB_MENU_LOCALIZED.REPLAYSFILTERSBY,
			targetField = "uploader",
			value = { "" }
		},
		{
			text = TB_MENU_LOCALIZED.REPLAYSFILTERSBYTAG,
			targetField = "tags",
			value = { "" }
		}
	}
	for _, v in pairs(lastSearchData) do
		local data = utf8.explode(v, "=")
		for i, opt in pairs(searchOptions) do
			if (data[1] == opt.targetField) then
				opt.value[1] = data[2]
			end
		end
	end

	local elementHeight = 50
	local windowHeight = (#searchOptions + 3) * elementHeight
	local searchOverlay = TBMenu:spawnWindowOverlay(nil, true)
	local searchViewBackground = searchOverlay:addChild({
		pos = (SCREEN_RATIO > 2) and { TBMenu.NavigationBar.shift.x + TBMenu.NavigationBar.size.w + 5, TBMenu.NavigationBar.shift.y + TBMenu.CurrentSection.size.h + 15 - windowHeight } or { TBMenu.NavigationBar.shift.x + TBMenu.NavigationBar.size.w - 500, TBMenu.NavigationBar.shift.y + TBMenu.NavigationBar.size.h + 5 },
		size = { 500, windowHeight },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		shapeType = ROUNDED,
		rounded = 4,
		interactive = true
	})
	local searchView = searchViewBackground:addChild({
		shift = { 2, 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	}, true)
	local searchTitle = searchView:addChild({
		pos = { 10, 0 },
		size = { searchView.size.w - 20, elementHeight }
	})
	searchTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSCOMMUNITYTITLEINFO)

	for i, v in pairs(searchOptions) do
		local inputLegend = searchView:addChild({
			pos = { 10, i * elementHeight },
			size = { searchView.size.w / 2 - 30, elementHeight }
		})
		inputLegend:addAdaptedText(v.text, nil, nil, nil, LEFTMID)
		local inputHolder = searchView:addChild({
			pos = { inputLegend.shift.x * 2 + inputLegend.size.w, inputLegend.shift.y + 5 },
			size = { inputLegend.size.w, inputLegend.size.h - 10 }
		}, true)
		TBMenu:spawnTextField2(inputHolder, nil, v.value, nil, {
			darkerMode = true,
			fontId = 4,
			textScale = 0.65,
			textAlign = LEFTMID
		})
	end

	local orderByLegend = searchView:addChild({
		pos = { 10, -elementHeight * 2 },
		size = { searchView.size.w / 2 - 30, elementHeight }
	})
	orderByLegend:addAdaptedText(TB_MENU_LOCALIZED.SEARCHFILTERORDER, nil, nil, nil, LEFTMID)
	local orderByHolder = searchView:addChild({
		pos = { orderByLegend.shift.x * 2 + orderByLegend.size.w, orderByLegend.shift.y + 5 },
		size = { orderByLegend.size.w, orderByLegend.size.h - 10 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	}, true)
	local orderByMode = 1
	TBMenu:spawnDropdown(orderByHolder, {
		{
			text = TB_MENU_LOCALIZED.REPLAYSFILTERSDATE,
			action = function() orderByMode = 1 end
		},
		--[[{
			text = TB_MENU_LOCALIZED.REPLAYSFILTERSRATING,
			action = function() orderByMode = 2 end
		},]]
		{
			text = TB_MENU_LOCALIZED.REPLAYSFILTERSPOPULARITY,
			action = function() orderByMode = 3 end
		}
	}, orderByHolder.size.h, nil, nil, {
		fontid = 4, scale = 0.65, alignment = LEFTMID
	}, {
		fontid = 4, scale = 0.65, alignment = CENTERMID
	})

	local searchButton = searchView:addChild({
		pos = { searchView.size.w / 4, -elementHeight + 5 },
		size = { searchView.size.w / 2, elementHeight - 10 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	searchButton:addChild({ shift = { 15, 5 } }):addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSEARCH)
	searchButton:addMouseUpHandler(function()
			local searchString = "0"
			for _, v in pairs(searchOptions) do
				if (utf8.len(v.value[1]) > 0) then
					searchString = searchString .. "&" .. v.targetField .. "=" .. v.value[1]
				end
			end
			searchOverlay:kill()
			Replays:getServerReplays(orderByMode, 0, searchString)
		end)
end

function Replays:showServerReplayPreview()
	local previewOverlay = TBMenu:spawnWindowOverlay()
	local previewView = UIElement:new({
		parent = previewOverlay,
		pos = { previewOverlay.size.w / 3, previewOverlay.size.h / 2 - 50 },
		size = { previewOverlay.size.w / 3, 100 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	previewView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSDOWNLOADINGREPLAY)
	local downloadWait = UIElement:new({
		parent = previewView,
		pos = { 0, 0 },
		size = { 0, 0 }
	})

	local frames = 0
	local replayFile = nil
	local cacheMode = get_option("replaycache") == 2 and 1 or 0
	downloadWait:addCustomDisplay(true, function()
			frames = frames + 1
			if (frames == 10) then
				replayFile = Files.Open("../replay/downloads/" .. ReplaysInternal.ServerTempName .. ".rpl", FILES_MODE_READONLY)
			end
			if (replayFile) then
				if (not replayFile:isDownloading()) then
					replayFile:close()
					local replaydata = ReplayInfo.FromReplay(replayFile.path)
					if (replaydata.mod ~= "classic") then
						local modname = string.find(replaydata.mod, "%.tbm$") and replaydata.mod or (replaydata.mod .. ".tbm")
						if (not find_mod(modname)) then
							local modFile = Files.Open("../data/mod/downloads/" .. modname)
							previewView:addAdaptedText(false, TB_MENU_LOCALIZED.MODSDOWNLOADINGMOD)
							modname = replaydata.mod:gsub("%.tbm$", "")
							download_mod(modname)
							local wait = 0
							local downloadWait = previewView:addChild({ })
							downloadWait:addCustomDisplay(true, function()
								wait = wait + 1
								if (not modFile:isDownloading() and wait > 5) then
									previewView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
									local framesN = 0
									downloadWait:addCustomDisplay(true, function()
											framesN = framesN + 1
											if (framesN > 4) then
												open_replay("downloads/" .. ReplaysInternal.ServerTempName .. ".rpl", cacheMode)
												close_menu()
											end
										end)
								end
							end)
						else
							downloadWait:addCustomDisplay(false, function()
									previewView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
									local framesN = 0
									downloadWait:addCustomDisplay(true, function()
											framesN = framesN + 1
											if (framesN > 4) then
												open_replay("downloads/" .. ReplaysInternal.ServerTempName .. ".rpl", cacheMode)
												close_menu()
											end
										end)
								end)
						end
					else
						downloadWait:addCustomDisplay(false, function()
								previewView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
								local framesN = 0
								downloadWait:addCustomDisplay(true, function()
										framesN = framesN + 1
										if (framesN > 4) then
											open_replay("downloads/" .. ReplaysInternal.ServerTempName .. ".rpl", cacheMode)
											close_menu()
										end
									end)
							end)
					end
				end
			end
		end)
end

function Replays:showReplayDownloadPopup(rplname)
	local notificationView = UIElement:new({
		parent = TBMenu.MenuMain,
		pos = { TBMenu.MenuMain.size.w / 3, -60 },
		size = { TBMenu.MenuMain.size.w / 3, 60 },
		bgColor = { 0, 0, 0, 0.8 }
	})
	notificationView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSDOWNLOADINGREPLAY, nil, nil, nil, nil, nil, nil, nil, nil, { 1, 1, 1, notificationView.bgColor[4] })

	local downloadWait = UIElement:new({
		parent = notificationView,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	local frames = 0
	local replayFile = nil
	downloadWait:addCustomDisplay(true, function()
			frames = frames + 1
			if (frames == 10) then
				replayFile = Files.Open("../replay/downloads/" .. rplname .. ".rpl", FILES_MODE_READONLY)
			end
			if (replayFile) then
				if (not replayFile:isDownloading()) then
					replayFile:close()
					notificationView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSREPLAYSAVEDINFO, nil, nil, nil, nil, nil, nil, nil, nil, { 1, 1, 1, notificationView.bgColor[4] })
					local framesN = 0
					downloadWait:addCustomDisplay(true, function()
							framesN = framesN + 1
							if (framesN > 30) then
								notificationView.bgColor[4] = notificationView.bgColor[4] - 0.05
								notificationView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSREPLAYSAVEDINFO, nil, nil, nil, nil, nil, nil, nil, nil, { 1, 1, 1, notificationView.bgColor[4] })
							end
							if (notificationView.bgColor[4] <= 0) then
								notificationView:kill()
							end
						end)
				end
			end
		end)
end

---Displays replay tags in a specified UIElement viewport
---@param viewElement UIElement
---@param tags string[]
---@param height integer
function Replays:displayTags(viewElement, tags, height, targetScale)
	local x, y = 0, 0
	for _, tag in pairs(tags) do
		local tagElement = viewElement:addChild({
			pos = { x, y },
			size = { viewElement.size.w, height },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = ROUNDED,
			rounded = 3
		})
		tagElement:addAdaptedText(tag, nil, nil, 4, nil, targetScale, targetScale)
		targetScale = tagElement.textScale
		local tagWidth = get_string_length(tagElement.dispstr[1], tagElement.textFont) * tagElement.textScale
		tagElement.size.w = tagWidth + 10
		if (tagElement.shift.x + tagElement.size.w > viewElement.size.w) then
			x = 0
			y = tagElement.shift.y + height + 5
			tagElement:moveTo(x, y)
		end
		if (tagElement.shift.y + tagElement.size.h > viewElement.size.h) then
			tagElement:kill()
			return
		end
		x = tagElement.shift.x + tagElement.size.w + 5
	end
end

---Displays server replays in a UIElement viewport
---@param viewElement UIElement
---@param replayInfoHolder UIElement
function Replays:showServerReplayList(viewElement, replayInfoHolder)
	TBMenu:addBottomBloodSmudge(viewElement, 1)
	ReplaysInternal.SelectedServerReplay.element = nil
	ReplaysInternal.SelectedServerReplay.replay = nil
	ReplaysInternal.SelectedServerReplay.displayid = nil

	local elementHeight = 30
	local toReload, topBar, _, _, replayHolder = TBMenu:prepareScrollableList(viewElement, 50, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

	local helpButton = topBar:addChild({
		pos = { 10, 10 },
		size = { topBar.size.h - 20, topBar.size.h - 20 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		shapeType = ROUNDED,
		rounded = topBar.size.h
	})
	local popup = TBMenu:displayHelpPopup(helpButton, TB_MENU_LOCALIZED.REPLAYSCOMMUNITYDOUBLECLICKINFO)
	if (popup ~= nil) then
		popup:moveTo(topBar.size.h - 15, -(popup.size.h - topBar.size.h + 20) / 2, true)
	end

	local listTitle = topBar:addChild({
		pos = { helpButton.shift.x + helpButton.size.w + 10, 0 },
		size = { (topBar.size.w - 20 - helpButton.shift.x - helpButton.size.w) / 2, topBar.size.h }
	})
	if (Replays.ServerCacheTotal == 0) then
		listTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSCOMMUNITYNOFOUND, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, 0.2)
	else
		local paginationHolder = topBar:addChild({
			pos = { listTitle.shift.x + listTitle.size.w + 10, 7 },
			size = { topBar.size.w - 20 - listTitle.shift.x - listTitle.size.w, topBar.size.h - 14 },
			shapeType = ROUNDED,
			rounded = 4
		})
		local pageButtonWidth = 45
		local currentPage, pages = math.floor(Replays.ServerCacheSettings.offset / 100) + 1, math.floor(Replays.ServerCacheTotal / 100)
		local pagesMax = math.floor(paginationHolder.size.w / pageButtonWidth)
		local pagesData = TBMenu:generatePaginationData(pages, pagesMax, currentPage)

		for i, v in pairs(pagesData) do
			local pageButton = paginationHolder:addChild({
				pos = { (i - 1) * pageButtonWidth, 0 },
				size = { pageButtonWidth * 0.8, paginationHolder.size.h },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK
			}, true)
			pageButton:addAdaptedText(false, v .. '', nil, nil, 4, nil, 0.65)
			pageButton:addMouseHandlers(nil, function()
					Replays:getServerReplays(Replays.ServerCacheSettings.action, (v - 1) * 100, Replays.ServerCacheSettings.search)
				end)
			if (currentPage == v) then
				pageButton:deactivate(true)
			end
		end
		paginationHolder:moveTo(-(#pagesData - 0.2) * pageButtonWidth - helpButton.shift.x)

		listTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSREPLAYS .. " " .. Replays.ServerCacheSettings.info, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, 0.2)
	end

	local listElements = {}
	local firstSelected = nil
	for i, v in pairs(Replays.ServerCache) do
		local buttonTopHolder = replayHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { replayHolder.size.w, elementHeight }
		})
		table.insert(listElements, buttonTopHolder)
		local buttonTopBackground = buttonTopHolder:addChild({
			pos = { 10, 2 },
			size = { buttonTopHolder.size.w - 12, buttonTopHolder.size.h - 2 },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = { 4, 0 }
		})
		local buttonBotHolder = replayHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { replayHolder.size.w, elementHeight }
		})
		table.insert(listElements, buttonBotHolder)
		local buttonBotBackground = buttonBotHolder:addChild({
			pos = { buttonTopBackground.shift.x, 0 },
			size = { buttonTopBackground.size.w, buttonTopBackground.size.h },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = { 0, 4 }
		})
		buttonTopBackground:addCustomDisplay(false, function()
			if (buttonBotBackground.hoverState ~= buttonTopBackground.hoverState and buttonBotBackground:isDisplayed()) then
				if (buttonTopBackground.hoverState > buttonBotBackground.hoverState) then
					buttonBotBackground.hoverState = buttonTopBackground.hoverState
					buttonBotBackground.hoverClock = buttonTopBackground.hoverClock
				else
					buttonTopBackground.hoverState = buttonBotBackground.hoverState
					buttonTopBackground.hoverClock = buttonBotBackground.hoverClock
				end
			end
		end, true)

		if (v.id == ReplaysInternal.SelectedServerReplay.id) then
			ReplaysInternal.SelectedServerReplay = { elements = { buttonTopBackground, buttonBotBackground }, id = v.id, replay = v, displayid = i }
		elseif (i == 1) then
			firstSelected = { elements = { buttonTopBackground, buttonBotBackground }, id = v.id, replay = v, displayid = i }
		end

		local replayName = buttonTopBackground:addChild({
			pos = { 10, 0 },
			size = { buttonTopBackground.size.w / 2 - 20, buttonTopBackground.size.h }
		})
		replayName:addAdaptedText(true, v.name, nil, nil, 4, LEFTMID, 0.65)
		local nameSeparator = replayName:addChild({
			pos = { replayName.size.w + replayName.shift.x / 2, replayName.size.h / 4 },
			size = { 1, replayName.size.h / 2 },
			bgColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
		})
		local replayRating = buttonTopBackground:addChild({
			pos = { replayName.shift.x * 2 + replayName.size.w, 0 },
			size = { (buttonTopBackground.size.w - replayName.size.w - replayName.shift.x * 5) / 3, buttonTopBackground.size.h }
		})
		Replays:showReplayRating(replayRating, v.score, v.votes)
		local ratingSeparator = replayRating:addChild({
			parent = replayRating,
			pos = { replayRating.size.w + replayName.shift.x / 2, replayRating.size.h / 4 },
			size = { 1, replayRating.size.h / 2 },
			bgColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
		})
		local replayUploader = buttonTopBackground:addChild({
			pos = { -(replayRating.size.w + replayName.shift.x) * 2, 0 },
			size = { replayRating.size.w, buttonTopBackground.size.h }
		})
		replayUploader:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSBY .. " " .. v.author, nil, nil, 4, nil, 0.65)
		local uploaderSeparator = UIElement:new({
			parent = replayUploader,
			pos = { replayUploader.size.w + replayName.shift.x / 2, replayUploader.size.h / 4 },
			size = { 1, replayUploader.size.h / 2 },
			bgColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
		})
		local replayDate = buttonTopBackground:addChild({
			pos = { -(replayRating.size.w + replayName.shift.x), 0 },
			size = { replayUploader.size.w, buttonTopBackground.size.h }
		})
		replayDate:addAdaptedText(true, v.date, nil, nil, 4, RIGHTMID, 0.65)
		buttonTopHolder.lastPress = 0
		local clickHandler = function()
			if (os.clock_real() - buttonTopHolder.lastPress < 0.45) then
				download_replay(v.id, ReplaysInternal.ServerTempName)
				Replays:showServerReplayPreview()
				return
			end
			buttonTopHolder.lastPress = os.clock_real()
			if (ReplaysInternal.SelectedServerReplay.elements) then
				for _, element in pairs(ReplaysInternal.SelectedServerReplay.elements) do
					element.bgColor = TB_MENU_DEFAULT_DARKER_COLOR
					element.hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR
				end
			end
			ReplaysInternal.SelectedServerReplay = { elements = { buttonTopBackground, buttonBotBackground }, id = v.id, replay = v, displayid = i }
			for _, element in pairs(ReplaysInternal.SelectedServerReplay.elements) do
				element.bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				element.hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			end
			Replays:showServerReplayInfo(replayInfoHolder, v)
		end
		buttonTopBackground:addMouseUpHandler(clickHandler)
		buttonBotBackground:addMouseUpHandler(clickHandler)

		local replayTagsHolder = buttonBotBackground:addChild({
			pos = { 10, 5 },
			size = { buttonBotBackground.size.w / 6 * 5 - 20, buttonBotBackground.size.h - 10 }
		})
		Replays:displayTags(replayTagsHolder, utf8.explode(v.tags:gsub(" +$", ''), " "), replayTagsHolder.size.h, 0.55)
		local replayDownloads = buttonBotBackground:addChild({
			pos = { -buttonBotBackground.size.w / 6, 0 },
			size = { buttonBotBackground.size.w / 6 - 10, buttonBotBackground.size.h }
		})
		replayDownloads:addAdaptedText(true, v.downloads .. (v.downloads == 1 and " " .. TB_MENU_LOCALIZED.REPLAYSDOWNLOAD or " " .. TB_MENU_LOCALIZED.REPLAYSDOWNLOADS), nil, nil, 4, RIGHTMID, 0.6)
	end

	for _, v in pairs(listElements) do
		v:hide()
	end

	local scrollBar = TBMenu:spawnScrollBar(replayHolder, #listElements, elementHeight)
	scrollBar:makeScrollBar(replayHolder, listElements, toReload)

	if (ReplaysInternal.SelectedServerReplay.displayid and replayHolder.size.h < elementHeight * 2 * ReplaysInternal.SelectedServerReplay.displayid) then
		scrollBar.btnDown(4, 0, -ReplaysInternal.SelectedServerReplay.displayid)
	end

	if (not ReplaysInternal.SelectedServerReplay.replay and firstSelected) then
		ReplaysInternal.SelectedServerReplay = firstSelected
	end
	for _, v in pairs(ReplaysInternal.SelectedServerReplay.elements or {}) do
		v.bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		v.hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	end
	Replays:showServerReplayInfo(replayInfoHolder, ReplaysInternal.SelectedServerReplay.replay)
end

---Displays replay rating
---@param viewElement UIElement
---@param score integer
---@param votes ?integer
---@param uservote ?integer
---@param interactive nil
---@return nil
function Replays:showReplayRating(viewElement, score, votes, uservote, interactive)
	local score = score or 0
	local votes = votes or 0
	local uservote = uservote or 0

	local scale = math.floor(math.min(64, viewElement.size.w / 5, viewElement.size.h))
	local displaynum = (votes > 0 and not interactive) and math.round(score / votes) or 0
	local leftShift = (viewElement.size.w - scale * 5) / 2
	local selectedVote = { 0 }

	for i = 1, displaynum do
		local ratingStar = viewElement:addChild({
			pos = { leftShift + (i - 1) * scale, (viewElement.size.h - scale) / 2 },
			size = { scale, scale },
			bgImage = "../textures/menu/general/buttons/star.tga"
		})
		if (uservote >= i) then
			ratingStar:addChild({
				bgImage = "../textures/menu/general/buttons/starborderglow.tga"
			})
		end
	end
	---@type UIElement[]
	local ratingButtons = {}
	for i = displaynum + 1, 5 do
		local ratingStarTransparent = viewElement:addChild({
			pos = { leftShift + (i - 1) * scale, (viewElement.size.h - scale) / 2 },
			size = { scale, scale },
			bgImage = "../textures/menu/general/buttons/starborder.tga"
		})
		if (interactive) then
			local ratingButton = ratingStarTransparent:addChild({
				bgImage = "../textures/menu/general/buttons/starborderglow.tga",
				imageColor = { 1, 1, 1, 0 },
				imageHoverColor = { 1, 1, 1, 0.85 },
				imagePressedColor = { 1, 1, 1, 1 },
				interactive = true
			})
			table.insert(ratingButtons, ratingButton)
			ratingButton:addMouseUpHandler(function()
				selectedVote[1] = i
				for j = 1, 5 do
					if (j <= i) then
						ratingButtons[j].parent:updateImage("../textures/menu/general/buttons/star.tga")
					else
						ratingButtons[j].parent:updateImage("../textures/menu/general/buttons/starborder.tga")
					end
				end
			end)
		end
	end

	if (interactive) then
		return selectedVote
	end
end

---Displays a replay rating with interactive buttons for voting
---@param viewElement UIElement
---@return integer[]
function Replays:showReplayRatingVote(viewElement)
	---@diagnostic disable-next-line: return-type-mismatch
	return Replays:showReplayRating(viewElement, 0, nil, nil, true)
end

---Displays replay vote window
---@param replay ReplayServerInfo
function Replays:showReplayVoteWindow(replay)
	local voteOverlay = TBMenu:spawnWindowOverlay(nil, true)
	local voteViewSize = { math.min(WIN_W / 2, 600), math.min(WIN_H / 2, 400) }
	local voteView = voteOverlay:addChild({
		shift = { (voteOverlay.size.w - voteViewSize[1]) / 2, (voteOverlay.size.h - voteViewSize[2]) / 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	local topBar = voteView:addChild({
		pos = { 0, 0 },
		size = { voteView.size.w, voteView.size.h / 8 }
	}, true)
	local closeButton = topBar:addChild({
		pos = { -topBar.size.h + 5, 5 },
		size = { topBar.size.h - 10, topBar.size.h - 10 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	closeButton:addMouseUpHandler(function() voteOverlay:kill() end)
	closeButton:addChild({ shift = { 5, 5 }, bgImage = "../textures/menu/general/buttons/crosswhite.tga" })

	topBar:addChild({
		pos = { 10, 5 },
		size = { topBar.size.w - 20 - closeButton.size.w, topBar.size.h - 10 }
	}):addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSVOTINGON .. " " .. replay.name .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAY, nil, nil, FONTS.BIG, nil, 0.65, nil, 0.4)

	local voteScoreView = UIElement:new({
		parent = voteView,
		pos = { 10, topBar.shift.y + topBar.size.h },
		size = { voteView.size.w - 20, voteView.size.h / 5 }
	})
	local replayVote = Replays:showReplayRatingVote(voteScoreView)

	local voteCommentInputHolder = voteView:addChild({
		pos = { 10, voteScoreView.shift.y + voteScoreView.size.h },
		size = { voteView.size.w - 20, voteView.size.h / 2 }
	}, true)
	local voteCommentInput = TBMenu:spawnTextField2(voteCommentInputHolder, nil, nil, TB_MENU_LOCALIZED.REPLAYSCOMMENT .. " (" .. TB_MENU_LOCALIZED.WORDOPTIONAL .. ")", {
		fontId = FONTS.LMEDIUM,
		textScale = 0.65,
		allowMultiline = true,
		textAlign = LEFT
	})

	local voteSubmit = voteView:addChild({
		pos = { voteView.size.w / 4, -voteView.size.h / 8 },
		size = { voteView.size.w / 2, voteView.size.h / 10 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK
	}, true)
	voteSubmit:deactivate()
	voteSubmit:addChild({ shift = { 15, 5 }}):addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONSUBMIT)
	voteSubmit:addMouseHandlers(nil, function()
			local info = replay.id .. ";" .. replayVote[1] .. ";" .. voteCommentInput.textfieldstr[1]
			show_dialog_box(ReplaysInternal.ReplayVoteAction, TB_MENU_LOCALIZED.REPLAYSVOTECONFIRM1 .. " " .. replayVote[1] .. " " .. TB_MENU_LOCALIZED.REPLAYSVOTECONFIRM2, info)
			local waitOverlay = UIElement:new({
				parent = TBMenu.MenuMain,
				pos = { 0, 0 },
				size = { TBMenu.MenuMain.size.w, TBMenu.MenuMain.size.h },
				interactive = true
			})
			waitOverlay:addMouseHandlers(nil, nil, function(x)
					if (x > WIN_W / 2) then
						voteOverlay:kill()
						Replays:getServerReplays(Replays.ServerCacheSettings.action, Replays.ServerCacheSettings.offset, Replays.ServerCacheSettings.search)
					end
					waitOverlay:kill()
				end)
		end)

	local voteWaiter = voteView:addChild({})
	voteWaiter:addCustomDisplay(true, function()
			if (replayVote[1] > 0) then
				voteSubmit:activate()
				voteWaiter:kill()
			end
		end)
end

---Displays replay comments in a scrollable list holder element
---@param listingHolder UIElement
---@param listingView UIElement
---@param toReload UIElement
---@param elementHeight integer
---@param comments ReplayComment[]
function Replays:showReplayCommentList(listingHolder, listingView, toReload, elementHeight, comments)
	local commentElements = {}
	for _, comment in pairs(comments) do
		local commentTop = listingHolder:addChild({
			pos = { 0, #commentElements * math.floor(elementHeight) },
			size = { listingHolder.size.w, elementHeight },
		})
		table.insert(commentElements, commentTop)
		local commentTopBackground = commentTop:addChild({
			pos = { 5, 5 },
			size = { commentTop.size.w - 5, commentTop.size.h - 5 },
			shapeType = ROUNDED,
			rounded = { 4, 0 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local commentUser = commentTopBackground:addChild({
			pos = { 10, 2 },
			size = { (commentTopBackground.size.w - 20) * 0.5, commentTopBackground.size.h - 2 }
		})
		commentUser:addAdaptedText(true, comment.user, nil, nil, nil, LEFTMID)
		local commentDate = commentTopBackground:addChild({
			pos = { commentUser.shift.x + commentUser.size.w, commentUser.shift.y },
			size = { commentTopBackground.size.w - commentUser.shift.x * 2 - commentUser.size.w, commentUser.size.h },
			uiColor = TB_MENU_DEFAULT_INACTIVE_COLOR
		})
		commentDate:addAdaptedText(true, comment.date, nil, nil, 4, RIGHT, 0.6)

		local commentStrings = textAdapt(comment.comment, FONTS.SMALL, 1, listingHolder.size.w - 20)
		local rows = math.ceil(#commentStrings / 2)
		for i = 1, rows do
			local commentLine = listingHolder:addChild({
				pos = { 0, #commentElements * math.floor(elementHeight) },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(commentElements, commentLine)
			local commentBackground = commentLine:addChild({
				pos = { 5, 0 },
				size = { commentLine.size.w - 5, commentLine.size.h },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				shapeType = i == rows and ROUNDED or SQUARE,
				rounded = i == rows and { 0, 4 } or 0
			})
			local commentLineHolder = commentBackground:addChild({
				shift = { 10, 0 }
			})
			local displayString = commentStrings[i * 2] and commentStrings[i * 2 - 1] .. "\n" .. commentStrings[i * 2] or commentStrings[i * 2 - 1]
			commentLineHolder:addAdaptedText(true, displayString, nil, nil, FONTS.SMALL, #commentStrings == 1 and LEFTMID or LEFT, 1, 1)
		end
	end

	if (#commentElements * elementHeight <= listingHolder.size.h) then
		listingHolder:moveTo(7, nil, true)
		return
	end

	for _, v in pairs(commentElements) do
		v:hide()
	end

	local commentsScrollBar = TBMenu:spawnScrollBar(listingHolder, #commentElements, elementHeight)
	commentsScrollBar:makeScrollBar(listingHolder, commentElements, toReload)

	---Enable list scrolling with window overlay on
	listingView:addCustomDisplay(function()
			if (listingView.hoverState == BTN_HVR) then
				UIScrollbarIgnore = false
			else
				UIScrollbarIgnore = true
			end
		end)
	listingView.killAction = function()
		UIScrollbarIgnore = false
	end
end

---Fetches comments for the specified replay and shows them in a separate window when ready
---@param replay ReplayServerInfo
function Replays:showReplayComments(replay)
	local overlay = TBMenu:spawnWindowOverlay()
	local waiterView = overlay:addChild({
		shift = { overlay.size.w / 2 - 250, overlay.size.h / 2 - 100 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	TBMenu:displayLoadingMark(waiterView, TB_MENU_LOCALIZED.REPLAYSCOMMENTSDOWNLOADING)

	Request:queue(function() fetch_replay_comments(replay.id) end, "netCommunityReplayComments", function()
			if (overlay == nil or overlay.destroyed) then
				return
			end

			local comments = Replays.ParseReplayComments(get_network_response())
			for i = #comments, 1, -1 do
				if (string.len(comments[i].comment) == 0) then
					table.remove(comments, i)
				end
			end
			overlay:kill()
			if (#comments == 0) then
				TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYSNOCOMMENTS, function()
						Replays:showReplayVoteWindow(replay)
					end)
			else
				overlay = TBMenu:spawnWindowOverlay(nil, true)
				local commentsSize = { math.min(WIN_W * 0.75, 900), math.min(WIN_H * 0.6, 550) }
				local commentsView = overlay:addChild({
					shift = { (WIN_W - commentsSize[1]) / 2, (WIN_H - commentsSize[2]) / 2 },
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					shapeType = ROUNDED,
					rounded = 4
				})

				local elementHeight = 30.01 -- has to be slightly more than 30 to make sure comments render properly
				local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(commentsView, 45, 60, 20, TB_MENU_DEFAULT_BG_COLOR)

				topBar.shapeType = ROUNDED
				topBar:setRounded({ 4, 0 })
				botBar.shapeType = ROUNDED
				botBar:setRounded(4)

				local closeButton = topBar:addChild({
					pos = { -topBar.size.h + 5, 5 },
					size = { topBar.size.h - 10, topBar.size.h - 10 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				}, true)
				closeButton:addMouseUpHandler(function() overlay:kill() end)
				closeButton:addChild({ shift = { 5, 5 }, bgImage = "../textures/menu/general/buttons/crosswhite.tga" })

				local commentsTitle = topBar:addChild({
					pos = { 10, 5 },
					size = { topBar.size.w - 20 - closeButton.size.w, topBar.size.h - 10 }
				})
				commentsTitle:addAdaptedText(true, replay.name .. " " .. TB_MENU_LOCALIZED.WORDBY .. " " .. replay.author, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, 0.4)

				Replays:showReplayCommentList(listingHolder, listingView, toReload, elementHeight, comments)

				local newCommentButton = botBar:addChild({
					shift = { botBar.size.w / 4, 10 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				}, true)
				newCommentButton:addChild({ shift = { 15, 5 }}):addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSADDCOMMENT)
				newCommentButton:addMouseUpHandler(function() Replays:showReplayVoteWindow(replay) end)
			end
		end, function()
			if (overlay) then
				overlay:kill()
			end
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORGETTINGCOMMENTS .. "\n" .. get_network_error())
		end)
end

function Replays:showServerReplayInfo(viewElement, replay)
	viewElement:kill(true)
	TBMenu:addBottomBloodSmudge(viewElement, 2)

	if (not replay) then
		return
	end

	local replayInfoHolder = viewElement:addChild({
		size = { viewElement.size.w, viewElement.size.h / 8 * 5 }
	})
	local replayName = UIElement:new({
		parent = replayInfoHolder,
		pos = { 10, 0 },
		size = { replayInfoHolder.size.w - 20, replayInfoHolder.size.h / 4 }
	})
	replayName:addAdaptedText(true, replay.name, nil, nil, FONTS.BIG, nil, 0.65, nil, 0.2)
	local replayUploader = UIElement:new({
		parent = replayInfoHolder,
		pos = { 10, replayName.shift.y + replayName.size.h },
		size = { replayInfoHolder.size.w - 20, replayInfoHolder.size.h / 16 }
	})
	replayUploader:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSBY .. " " .. replay.author, nil, nil, 4, nil, 0.75)
	local replayDate = UIElement:new({
		parent = replayInfoHolder,
		pos = { 10, replayUploader.shift.y + replayUploader.size.h },
		size = { replayUploader.size.w, replayInfoHolder.size.h / 16 }
	})
	replayDate:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSUPLOADEDON .. " " .. replay.date, nil, nil, 4, nil, 0.75)
	local replayRating = UIElement:new({
		parent = replayInfoHolder,
		pos = { 10, replayDate.shift.y + replayDate.size.h + 10 },
		size = { replayUploader.size.w, replayInfoHolder.size.h / 4 - 20 },
		interactive = true,
		shapeType = ROUNDED,
		rounded = 5,
		bgColor = { 0, 0, 0, 0.01 },
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	replayRating:addMouseHandlers(nil, function()
			Replays:showReplayVoteWindow(replay)
		end)
	if (string.lower(replay.author) == string.lower(TB_MENU_PLAYER_INFO.username)) then
		replayRating:deactivate()
	end
	Replays:showReplayRating(replayRating, replay.score, replay.votes, replay.uservote)
	local replayDescription = UIElement:new({
		parent = replayInfoHolder,
		pos = { 10, replayRating.shift.y + replayRating.size.h + 10 },
		size = { replayDate.size.w, replayInfoHolder.size.h / 8 * 3 }
	})
	replayDescription:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSDESC .. ": " .. replay.description, nil, nil, 4, LEFT, 0.65, 0.65)

	local replayDownloadButton = viewElement:addChild({
		pos = { 10, -viewElement.size.h / 8 * 3 },
		size = { viewElement.size.w - 20, viewElement.size.h / 10 },
		interactive = true,
		shapeType = ROUNDED,
		rounded = 3,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	replayDownloadButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSSAVEREPLAY)
	replayDownloadButton:addMouseHandlers(nil, function()
			download_replay(replay.id, replay.name:gsub("%s", "_"))
			Replays:showReplayDownloadPopup(replay.name:gsub("%s", "_"))
		end)
	local replayCommentsButton = viewElement:addChild({
		pos = { 10, -viewElement.size.h / 8 * 2 },
		size = { viewElement.size.w - 20, viewElement.size.h / 10 },
		interactive = true,
		shapeType = ROUNDED,
		rounded = 3,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	replayCommentsButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSVIEWCOMMENTS)
	replayCommentsButton:addMouseHandlers(nil, function()
			Replays:showReplayComments(replay)
		end)

	local findReplaysByUserButton = viewElement:addChild({
		pos = { 10, -viewElement.size.h / 8 },
		size = { viewElement.size.w - 20, viewElement.size.h / 10 },
		interactive = true,
		shapeType = ROUNDED,
		rounded = 3,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	findReplaysByUserButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSMOREBY .. " " .. replay.author)
	findReplaysByUserButton:addMouseHandlers(nil, function()
			Replays:getServerReplays(5, 1, replay.author)
		end)
end

---Clears the current section and displays server replays list
function Replays:showServerReplays()
	local viewElement = TBMenu.CurrentSection
	viewElement:kill(true)
	TBMenu:showNavigationBar(Replays:getNavigationButtons(true), true)

	local replayInfoWidth = math.min(math.max(viewElement.size.w * 0.25, 350), viewElement.size.w * 0.4)
	local replaysList = viewElement:addChild({
		pos = { 5, 0 },
		size = { (viewElement.size.w - replayInfoWidth) - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local replayInfo = viewElement:addChild({
		pos = { replaysList.size.w + 15, 0 },
		size = { replayInfoWidth - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	Replays:showServerReplayList(replaysList, replayInfo)
end

---Displays Replays menu default screen and queues cache generation if it's empty
---@param viewElement UIElement
function Replays:showMain(viewElement)
	usage_event("replays")
	TBMenu:showNavigationBar(Replays:getNavigationButtons(), true)
	viewElement:kill(true)

	Replays.CacheReady = false
	if (not Replays.CacheReady) then
		local status, error = pcall(function() Replays:getReplayFiles() end)
		if (not status) then
			viewElement:addChild({
				shift = { 5, 0 },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYSERRORLOADINGCACHE .. " " .. error, Replays.ResetCache, Replays.Quit)
			return
		end
	end
	TB_MENU_REPLAYS_ONLINE = 0

	ReplaysInternal.SelectedReplay = { replay = nil, element = nil, defaultcolor = nil, time = 0, list = {}, idx = 0 }

	local replaysList = UIElement:new({
		parent = viewElement,
		pos = { 5, 0 },
		size = { viewElement.size.w * 0.75 - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local replayInfo = UIElement:new({
		parent = viewElement,
		pos = { replaysList.size.w + 15, 0 },
		size = { viewElement.size.w * 0.25 - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:displayLoadingMark(replaysList, TB_MENU_LOCALIZED.REPLAYSUPDATINGCACHE)
	TBMenu:addBottomBloodSmudge(replaysList, 1)
	TBMenu:addBottomBloodSmudge(replayInfo, 2)
	replaysList:addCustomDisplay(false, function()
			if (Replays.CacheReady) then
				replaysList:kill(true)
				replaysList:addCustomDisplay(false, function() end)
				TBMenu:addBottomBloodSmudge(replaysList, 1)
				Replays:showList(replaysList, replayInfo, ReplaysInternal.SelectedFolder, TB_MENU_REPLAYS_SEARCH)

				if (TBMenu.StatusMessage) then
					TBMenu.StatusMessage:reload()
				end
			end
		end)
end

function Replays:showCustomReplaySelection(mainElement, mod, action)
	if (ReplaysInternal.CustomSelectorActive == true) then return end

	local function showCustomReplayChoice(viewElement)
		local holder = viewElement:addChild({
			shift = { viewElement.size.w / 5, viewElement.size.h / 4 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		local replaysToChooseFrom = {}
		local modExtension = mod
		if (string.match(modExtension, ".*%.tbm$")) then
			mod = string.sub(modExtension, 0, -4)
		else
			modExtension = mod .. ".tbm"
		end
		local nameLower = string.lower(TB_MENU_PLAYER_INFO.username)
		---@param v ReplayInfo
		local function checkReplay(v)
			if ((mod == nil or v.mod == mod or v.mod == modExtension) and (v.author ~= nil and string.lower(v.author) == nameLower or (v.author == 'autosave' and v.bouts[1] ~= nil and string.lower(v.bouts[1]) == nameLower))) then
				if (v.name:find("^" .. ReplaysInternal.EventTempPrefix)) then
					v.name = 'Autosaved Replay'
				end
				table.insert(replaysToChooseFrom, { path = v.filename, name = v.name })
			end
		end
		---@param folder ReplayDirectory
		local function checkFolder(folder)
			for _, v in pairs(folder.replays) do
				checkReplay(v)
			end
			for _, v in pairs(folder.folders) do
				checkFolder(v)
			end
		end
		checkFolder(Replays.RootFolder)

		local elementHeight = 45
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(holder, elementHeight + 15, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)
		topBar.shapeType = ROUNDED
		topBar:setRounded(4)
		botBar.shapeType = ROUNDED
		botBar:setRounded(4)

		local topTitle = topBar:addChild({ shift = { topBar.size.h, 5 } })
		topTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSSELECTREPLAYTOPROCEED, nil, nil, FONTS.BIG, nil, 0.8, nil, 0.5)
		local closeButtonSize = math.min(45, topBar.size.h - 10)
		TBMenu:spawnCloseButton(topBar, {
				x = -closeButtonSize - 5, y = 5,
				w = closeButtonSize, h = closeButtonSize
			}, function() viewElement:kill() end)

		if (#replaysToChooseFrom == 0) then
			listingHolder:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSCOMMUNITYNOFOUND, nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
			return
		end

		local listElements = {}
		for _, v in pairs(replaysToChooseFrom) do
			local replayFile = listingHolder:addChild({
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, replayFile)
			local replayButton = replayFile:addChild({
				pos = { 10, 2 },
				size = { replayFile.size.w - 10, replayFile.size.h - 4 },
				interactive = true,
				clickThrough = true,
				hoverThrough = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 3
			})
			local replayName = replayButton:addChild({
				pos = { 10, 5 },
				size = { (replayButton.size.w - 20) / 2, replayButton.size.h - 10 }
			})
			replayName:addAdaptedText(true, v.name, nil, nil, 4, LEFTMID, 0.8, 0.8)
			local replayPath = replayButton:addChild({
				pos = { replayName.shift.x + replayName.size.w, replayName.shift.y },
				size = { replayName.size.w, replayName.size.h },
				uiColor = { 1, 1, 1, 0.6 }
			})
			local cleanPath = string.gsub(v.path, "^replay/", "")
			replayPath:addAdaptedText(true, cleanPath, nil, nil, 4, RIGHTMID, 0.6, 0.6)
			replayButton:addMouseHandlers(nil, function()
					viewElement:kill()
					action(cleanPath)
				end)
		end
		for _, v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
	end

	local status, error = pcall(function() Replays:getReplayFiles(true) end)
	if (not status) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORLOADIGNCACHESHORT .. ": " .. error)
		return
	end

	local customReplayOverlay = mainElement:addChild({
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 }
	})
	customReplayOverlay:addMouseHandlers(nil, function()
			customReplayOverlay:kill()
		end)
	customReplayOverlay.killAction = function() ReplaysInternal.CustomSelectorActive = false end
	local customReplayLoading = customReplayOverlay:addChild({
		pos = { customReplayOverlay.size.w / 5, customReplayOverlay.size.h / 2 - 70 },
		size = { customReplayOverlay.size.w * 0.6, 140 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	customReplayLoading:addAdaptedText(false, TB_MENU_LOCALIZED.MESSAGEPLEASEWAIT)
	customReplayOverlay:addChild({}):addCustomDisplay(function()
			if (Replays.CacheReady) then
				customReplayOverlay:kill(true)
				showCustomReplayChoice(customReplayOverlay)
			end
		end)
	ReplaysInternal.CustomSelectorActive = true
end

---Spawns replay advanced hud progress slider in a specified UIElement
---@param viewElement UIElement
---@return UISlider
function Replays:spawnReplayProgressSlider(viewElement)
	local replayProgressHolder = viewElement:addChild({
		bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
		shapeType = ROUNDED,
		rounded = 4,
	})
	local replayProgressTitle = replayProgressHolder:addChild({
		pos = { 15, 3 },
		size = { replayProgressHolder.size.w - 30, 25 }
	})
	replayProgressTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSREPLAYPROGRESS)

	local worldstate = UIElement.WorldState
	local replaySpeed = 1
	local onMouseDn = function()
		replaySpeed = get_replay_speed()
		if (replaySpeed > 0) then
			freeze_game()
			set_replay_speed(0)
		end
	end
	local onMouseUp = function()
		if (replaySpeed > 0) then
			unfreeze_game()
			set_replay_speed(replaySpeed, true)
		end
	end

	local slider = TBMenu:spawnSlider2(replayProgressHolder,
		{ x = 15, y = 25, h = replayProgressHolder.size.h - 25},
		worldstate.match_frame, {
			sliderRadius = 20,
			textWidth = 30,
			maxValue = worldstate.game_frame + 98,
			minValue = 0,
			showLabelOnHover = true
		}, rewind_replay_to_frame, onMouseDn, onMouseUp)
	slider.bgColor = table.clone(UICOLORWHITE)
	slider.value = worldstate.match_frame

	local afterFrames = slider.background:addChild({
		pos = { -slider.background.size.w / (worldstate.game_frame + 99) * 99, slider.background.size.h / 2 - 3 },
		size = { slider.background.size.w / (worldstate.game_frame + 99) * 99, 6 },
		bgColor = { 1, 1, 1, 0.7 }
	}, true)

	---Keyframe controls
	local keyframeButtonSize = 16
	local keyframeButtonHoverSize = 24
	local keyframeButtons = {}
	local keyframesCount = 0
	local loadKeyframes

	local onKeyframeUpdated = function()
		local ws = get_world_state()
		rewind_replay()
		rewind_replay_to_frame(ws.match_frame)
		if (ws.game_paused ~= 0) then
			toggle_game_pause()
		end
		loadKeyframes(ws)
	end
	local getKeyframeSliderSpeedValue = function(value)
		if (value > 2) then
			value = 1.5 + (value - 2) / 4
		elseif (value > 1) then
			value = 1 + (value - 1) / 2
		end
		return value
	end

	local is_mobile = is_mobile()
	local keyframeInfoViewHolder = slider.background:addChild({
		size = { 350, is_mobile and 120 or 100 },
		pos = { 0, -slider.background.size.h - (is_mobile and 165 or 145) }
	})
	keyframeInfoViewHolder.keyframe = 0
	keyframeInfoViewHolder.speed = 1
	local overlay = keyframeInfoViewHolder:addChild({
		pos = { -WIN_W * 2, -WIN_H * 2 },
		size = { WIN_W * 3, WIN_H * 3 },
		interactive = true
	})
	overlay:addMouseDownHandler(function() keyframeInfoViewHolder:hide(true) end)
	local keyframeInfoView = keyframeInfoViewHolder:addChild({
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4,
		innerShadow = { is_mobile and 40 or 26, 0 },
		shadowColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local keyframeInfoFrameLabel = keyframeInfoView:addChild({
		pos = { 10, 3 },
		size = { keyframeInfoView.size.w * 0.65, is_mobile and 34 or 20 }
	})
	local keyframeInfoDeleteButton = keyframeInfoView:addChild({
		pos = { keyframeInfoFrameLabel.size.w + keyframeInfoFrameLabel.shift.x, 2 },
		size = { keyframeInfoView.size.w - keyframeInfoFrameLabel.size.w - keyframeInfoFrameLabel.shift.x - 2, is_mobile and 36 or 22 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
	}, true)
	keyframeInfoDeleteButton:addAdaptedText(TB_MENU_LOCALIZED.WORDDELETE)
	keyframeInfoDeleteButton:addMouseUpHandler(function()
		delete_camera_keyframe(keyframeInfoViewHolder.keyframe)
		overlay.btnDown()
		onKeyframeUpdated()
	end)
	local shiftY = keyframeInfoFrameLabel.shift.y * 2 + keyframeInfoFrameLabel.size.h
	local keyframeSpeedLabel = keyframeInfoView:addChild({
		pos = { 10, shiftY + 4 },
		size = { keyframeInfoView.size.w / 3, (keyframeInfoView.size.h - shiftY - 8) / 2 }
	})
	keyframeSpeedLabel:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSREPLAYSPEED, nil, nil, nil, LEFTMID, 0.75)
	local keyframeSpeedSliderHolder = keyframeInfoView:addChild({
		pos = { keyframeInfoView.size.w / 3 + keyframeSpeedLabel.shift.x, keyframeSpeedLabel.shift.y },
		size = { keyframeInfoView.size.w / 3 * 2 - keyframeSpeedLabel.shift.x, keyframeSpeedLabel.size.h }
	})
	local keyframeSpeedSlider
	keyframeSpeedSlider = TBMenu:spawnSlider2(keyframeSpeedSliderHolder, nil, 1, {
		minValue = 0.05, maxValue = 2,
		minValueDisp = '0.05x', maxValueDisp = '4x',
		decimal = 2, textWidth = 40, showLabelOnHover = true
	}, function(value)
		if (value > 1) then
			if (value < 1.5) then
				value = 1 + (value - 1) * 2
				value = math.floor(value * 10) / 10
			else
				value = 2 + (value - 1.5) * 4
				value = math.floor(value * 4) / 4
			end
		else
			value = math.floor(value * 20) / 20
		end
		keyframeInfoViewHolder.speed = value
		---@diagnostic disable-next-line: undefined-field
		keyframeSpeedSlider.label.labelText[1] = tostring(keyframeInfoViewHolder.speed)
	end, nil, function()
		save_camera_keyframe(keyframeInfoViewHolder.keyframe, keyframeInfoViewHolder.speed)
		onKeyframeUpdated()
	end)
	keyframeSpeedSlider.background.bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR)
	keyframeSpeedSlider.bgColor = table.clone(UICOLORWHITE)
	keyframeSpeedSlider.background:addCustomDisplay(function()
			set_color(1, 1, 1, 0.7)
			draw_quad(keyframeSpeedSlider.background.pos.x, keyframeSpeedSlider.background.pos.y, keyframeSpeedSlider.background.size.w / 2, keyframeSpeedSlider.background.size.h)

			draw_quad(keyframeSpeedSlider.background.pos.x + keyframeSpeedSlider.background.size.w * 0.125, keyframeSpeedSlider.background.pos.y - 3, 1, keyframeSpeedSlider.background.size.h + 6)
			draw_quad(keyframeSpeedSlider.background.pos.x + keyframeSpeedSlider.background.size.w * 0.25, keyframeSpeedSlider.background.pos.y - 5, 1, keyframeSpeedSlider.background.size.h + 10)
			draw_quad(keyframeSpeedSlider.background.pos.x + keyframeSpeedSlider.background.size.w * 0.375, keyframeSpeedSlider.background.pos.y - 3, 1, keyframeSpeedSlider.background.size.h + 6)
			draw_quad(keyframeSpeedSlider.background.pos.x + keyframeSpeedSlider.background.size.w * 0.5, keyframeSpeedSlider.background.pos.y - 8, 1, keyframeSpeedSlider.background.size.h + 16)
			draw_quad(keyframeSpeedSlider.background.pos.x + keyframeSpeedSlider.background.size.w * 0.625, keyframeSpeedSlider.background.pos.y - 5, 1, keyframeSpeedSlider.background.size.h + 10)
			draw_quad(keyframeSpeedSlider.background.pos.x + keyframeSpeedSlider.background.size.w * 0.75, keyframeSpeedSlider.background.pos.y - 8, 1, keyframeSpeedSlider.background.size.h + 16)
			draw_quad(keyframeSpeedSlider.background.pos.x + keyframeSpeedSlider.background.size.w * 0.875, keyframeSpeedSlider.background.pos.y - 8, 1, keyframeSpeedSlider.background.size.h + 16)
		end)
	local keyframeInterpolateLabel = keyframeInfoView:addChild({
		pos = { keyframeSpeedLabel.shift.x, keyframeSpeedSliderHolder.shift.y + keyframeSpeedSliderHolder.size.h },
		size = { keyframeInfoView.size.w / 2, keyframeSpeedSliderHolder.size.h }
	})
	keyframeInterpolateLabel:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYKEYFRAMEINTERPOLATION, nil, nil, nil, LEFTMID, 0.75)
	local keyframeInterpolateToggle = TBMenu:spawnToggle(keyframeInfoView, keyframeInfoView.size.w - 5 - keyframeInterpolateLabel.size.h, keyframeInterpolateLabel.shift.y, keyframeInterpolateLabel.size.h, keyframeInterpolateLabel.size.h, true, function(value)
		save_camera_keyframe(keyframeInfoViewHolder.keyframe, keyframeInfoViewHolder.speed, false, value)
		onKeyframeUpdated()
	end)
	keyframeInfoViewHolder:hide(true)

	loadKeyframes = function(ws)
		for _, v in ipairs(keyframeButtons) do
			v:kill()
		end
		if (is_mobile) then
			TBHud.CameraKeyframeEditButtonHolder:hide()
		end

		local keyframes = get_camera_keyframes()
		for i = 1, #keyframes do
			local kf = keyframes[i]
			local keyframeButton = slider.background:addChild({
				pos = { -slider.background.size.w / (worldstate.game_frame + 99) * (worldstate.game_frame + 99 - kf.frame) - keyframeButtonSize / 2, slider.background.size.h - 28 },
				size = { keyframeButtonSize, keyframeButtonSize },
				bgImage = "../textures/menu/general/buttons/square45.tga",
				imageColor = UICOLORWHITE,
				imageHoverColor = UICOLORWHITE,
				interactive = true
			})
			table.insert(keyframeButtons, keyframeButton)
			---@type Vector2Base
			---@diagnostic disable-next-line: assign-type-mismatch
			local initialPos = table.clone(keyframeButton.shift)

			local showKeyframeManage = function()
				keyframeInfoViewHolder:moveTo(math.clamp(keyframeButton.shift.x + keyframeButton.size.w / 2 - keyframeInfoViewHolder.size.w / 2, -slider.background.size.w - 60, 60 - keyframeInfoViewHolder.size.w))
				keyframeInfoViewHolder:show(true)
				keyframeInfoViewHolder.keyframe = kf.frame
				keyframeInfoViewHolder.speed = kf.speed
				keyframeSpeedSlider.setValue(getKeyframeSliderSpeedValue(kf.speed))
				---@diagnostic disable-next-line: undefined-field
				keyframeSpeedSlider.label.labelText[1] = tostring(math.floor(kf.speed * 100) / 100)
				keyframeInterpolateToggle.setValue(kf.interpolate)
				keyframeInfoFrameLabel:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYKEYFRAMEFRAME .. " " .. kf.frame, nil, nil, nil, LEFTMID)
			end
			local clickClock = 0
			local frameTextLength = get_string_length(tostring(kf.frame), FONTS.LMEDIUM) * 0.6
			local frameShadowFontId = generate_font(FONTS.LMEDIUM, 1, 4)
			keyframeButton:addCustomDisplay(function()
				draw_quad(keyframeButton.pos.x + keyframeButton.size.w / 2 - 1, slider.parent.pos.y + slider.parent.size.h - 32, 2, 16)
				if (keyframeButton.hoverState ~= BTN_NONE) then
					if (keyframeButton.size.w < keyframeButtonHoverSize) then
						keyframeButton.size.w = UITween.LinearTween(keyframeButton.size.w, keyframeButtonHoverSize, (UIElement.clock - keyframeButton.hoverClock) * 5)
						local moveAmount = (keyframeButton.size.h - keyframeButton.size.w) / 2
						keyframeButton:moveTo(moveAmount, moveAmount * 2, true)
						keyframeButton.size.h = keyframeButton.size.w
					end
					if (not is_mobile) then
						set_color(unpack(replayProgressHolder.bgColor))
						draw_text_angle_scale(tostring(kf.frame), keyframeButton.pos.x + (keyframeButton.size.w - frameTextLength) / 2 - 2, keyframeButton.pos.y - 18, 0, 0.6, frameShadowFontId)
						set_color(1, 1, 1, 1)
						draw_text_angle_scale(tostring(kf.frame), keyframeButton.pos.x + (keyframeButton.size.w - frameTextLength) / 2, keyframeButton.pos.y - 16, 0, 0.6, FONTS.LMEDIUM)
					end
				else
					keyframeButton.size.w = keyframeButtonSize
					keyframeButton.size.h = keyframeButtonSize
					keyframeButton:moveTo(initialPos.x, initialPos.y)
				end
				if (is_mobile and clickClock > 0 and UIElement.clock - clickClock > UIElement.longPressDuration) then
					play_haptics(0.2, HAPTICS.IMPACT)
					clickClock = 0
					showKeyframeManage()
				end
			end)
			if (is_mobile) then
				keyframeButton:addMouseDownHandler(function()
					clickClock = os.clock_real()
				end)
				keyframeButton:addMouseUpHandler(function()
					if (clickClock > 0) then
						rewind_replay_to_frame(kf.frame)
						TBHud.CameraKeyframeEditButtonHolder:show()
						TBHud.CameraKeyframeEditButtonHolder.child[1]:addMouseUpHandler(showKeyframeManage)
						TBHud.CameraKeyframeEditButtonHolder.frame = kf.frame
					end
					clickClock = 0
				end)
				if (ws.match_frame == kf.frame) then
					TBHud.CameraKeyframeEditButtonHolder:show()
					TBHud.CameraKeyframeEditButtonHolder.child[1]:addMouseUpHandler(showKeyframeManage)
					TBHud.CameraKeyframeEditButtonHolder.frame = kf.frame
				end
			else
				keyframeButton:addMouseUpHandler(function()
					rewind_replay_to_frame(kf.frame)
				end)
			end
			keyframeButton:addMouseUpRightHandler(showKeyframeManage)
		end
		if (#keyframes > 0) then
			set_hint_override(TB_MENU_LOCALIZED.CAMERAKEYFRAMESHINT)
		end

		slider:reload()
		if (keyframeInfoViewHolder:isDisplayed()) then
			keyframeInfoViewHolder:reload()
		end
		keyframesCount = #keyframes
	end
	loadKeyframes(UIElement.WorldState)

	local spawnTime = UIElement.WorldState.replay_mode == 0 and 0 or UIElement.clock
	local hintShown = false
	replayProgressHolder:addCustomDisplay(false, function()
			if (get_camera_keyframes_count() ~= keyframesCount) then
				loadKeyframes(UIElement.WorldState)
			end
			local worldstate = UIElement.WorldState
			if (worldstate.replay_mode ~= 0 and worldstate.game_type == 0) then
				if (not hintShown) then
					if (spawnTime == 0) then
						spawnTime = UIElement.clock
					elseif (UIElement.clock - spawnTime > 20) then
						hintShown = true
						set_hint_override(TB_MENU_LOCALIZED.CAMERAKEYFRAMESHINT)
					end
				else
					if (UIElement.clock - spawnTime > 40) then
						hintShown = false
						spawnTime = UIElement.clock
						set_hint_override()
					end
				end
			end
			if (slider.settings.maxValue ~= worldstate.game_frame + 98) then
				Replays:spawnReplayAdvancedGui(true)
				return
			end
			if (is_mobile and TBHud.CameraKeyframeEditButtonHolder.frame ~= worldstate.match_frame) then
				TBHud.CameraKeyframeEditButtonHolder:hide()
			end
			if (slider.value ~= worldstate.match_frame) then
				if (slider.hoverState ~= BTN_NONE or slider.parent.hoverState == BTN_DN) then
					return
				end
				slider.setValue(worldstate.match_frame, false)
				slider.value = worldstate.match_frame
			end
			if (get_replay_cache() > 0) then
				if (not slider.isactive) then
					slider.parent:activate()
					slider:activate()
					slider:reload()
				end
			else
				if (slider.isactive) then
					slider.btnUp()
					slider:deactivate()
					slider.parent:deactivate()
				end
			end
		end)

	return slider
end

---Spawns replay advanced hud speed slider in a specified UIElement
---@param viewElement UIElement
---@return UISlider
function Replays:spawnReplaySpeedSlider(viewElement)
	local is_mobile = is_mobile()
	local replaySpeedHolder = viewElement:addChild({
		bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
		shapeType = ROUNDED,
		rounded = 4
	})
	if (is_mobile) then
		---Speedometer icon instead of text label, also no buttons
		replaySpeedHolder:addChild({
			pos = { 5, 5 },
			size = { self.GameHudRight.size.w - 10, self.GameHudRight.size.w - 10 },
			bgImage = "../textures/menu/general/speedometer.tga"
		})
	else
		local replaySpeedTitle = replaySpeedHolder:addChild({
			pos = { 15, 3 },
			size = { replaySpeedHolder.size.w - 30, 25 }
		})
		replaySpeedTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSREPLAYSPEED)
		local textWidth = get_string_length(replaySpeedTitle.dispstr[1], replaySpeedTitle.textFont) * replaySpeedTitle.textScale + 60
		if (textWidth + 50 < replaySpeedTitle.size.w) then
			local setButtonSpeed = function(dir)
				local speed = get_replay_speed()
				if (math.abs(speed + dir * 0.01) <= 0.1) then
					speed = speed + dir * 0.01
				elseif (math.abs(speed + dir * 0.1) <= 1) then
					speed = speed + dir * 0.1
				elseif ((dir > 0 and speed + 0.5 <= 4) or (dir < 0 and speed - 0.5 >= -1.5)) then
					speed = speed + dir * 0.5
				else
					return
				end

				local _, keyframe_mode = get_camera_mode()
				if (keyframe_mode < CAMERA_CACHE_MODE.RECORDING and UIElement.WorldState.game_paused == 0) then
					unfreeze_game()
					set_replay_speed(speed, true)
				else
					set_replay_speed(speed, false)
				end
			end

			local speedDn = replaySpeedTitle:addChild({
				pos = { (replaySpeedTitle.size.w - textWidth) / 2 - 25, 0 },
				size = { 25, 25 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
				interactive = true,
				shapeType = ROUNDED,
				rounded = 3
			})
			speedDn:addChild({ shift = { 5, 11 }, bgColor = TB_MENU_DEFAULT_LIGHTEST_COLOR }, true)
			speedDn:addMouseHandlers(nil, function() setButtonSpeed(-1) end)

			local speedUp = replaySpeedTitle:addChild({
				pos = { -(replaySpeedTitle.size.w - textWidth) / 2, 0 },
				size = { 25, 25 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
				interactive = true,
				shapeType = ROUNDED,
				rounded = 3
			})
			speedUp:addChild({ shift = { 5, 11 }, bgColor = TB_MENU_DEFAULT_LIGHTEST_COLOR }, true)
			speedUp:addChild({ shift = { 11, 5 }, bgColor = TB_MENU_DEFAULT_LIGHTEST_COLOR }, true)
			speedUp:addMouseHandlers(nil, function() setButtonSpeed(1) end)

			speedDn:addCustomDisplay(false, function()
					if (speedDn.isactive) then
						if (get_replay_cache() < 1) then
							speedDn:deactivate(true)
							speedUp:deactivate(true)
						end
					elseif (get_replay_cache() > 0) then
						speedDn:activate(true)
						speedUp:activate(true)
					end
				end)
		end
	end

	local getSpeedFromSliderValue = function(val)
		if (val > 1) then
			if (val < 1.5) then
				val = 1 + (val - 1) * 2
			else
				val = 2 + (val - 1.5) * 4
			end
		elseif (val < 0) then
			if (val < -0.75) then
				val = -1 + (val + 0.75) * 2
			else
				val = val / 0.75
			end
		end
		if (val > -0.01 and val < 0) then
			-- Ensure we don't get -0 speed, that looks wack
			val = 0
		end
		return val
	end
	local getSliderValueFromSpeed = function(val)
		if (val > 2) then
			return 1.5 + (val - 2) / 4
		elseif (val > 1) then
			return 1 + (val - 1) / 2
		elseif (val < -1) then
			return -0.75 + (val + 1) / 2
		elseif (val < 0) then
			return val * 0.75
		end
		return val
	end

	local updateFunc = function(val, _, slider)
		local multiplyBy = tonumber('1' .. string.rep('0', slider.settings.decimal))
		val = getSpeedFromSliderValue(val)

		if (math.abs(val) > 1) then
			multiplyBy = multiplyBy / 10
		elseif (math.abs(val) > 2) then
			multiplyBy = 1
		end

		local targetVal = val < 0 and math.ceil(val * multiplyBy) / multiplyBy or math.floor(val * multiplyBy) / multiplyBy
		slider.label.labelText[1] = targetVal .. ''

		local _, keyframe_mode = get_camera_mode()
		if (keyframe_mode < CAMERA_CACHE_MODE.RECORDING and UIElement.WorldState.game_paused == 0) then
			unfreeze_game()
			set_replay_speed(targetVal)
		else
			set_replay_speed(targetVal, false)
		end
	end

	local updateLabelFunc = function(val, slider)
		local multiplyBy = tonumber('1' .. string.rep('0', slider.settings.decimal))
		val = getSpeedFromSliderValue(val)

		if (math.abs(val) > 1) then
			multiplyBy = multiplyBy / 10
		elseif (math.abs(val) > 2) then
			multiplyBy = 1
		end

		local targetVal = val < 0 and math.ceil(val * multiplyBy) / multiplyBy or math.floor(val * multiplyBy) / multiplyBy
		return tostring(targetVal)
	end

	---@type SliderSettings
	local sliderSettings = {
		maxValue = 2,
		minValue = -1,
		maxValueDisp = 4,
		minValueDisp = -1.5,
		decimal = 2,
		sliderRadius = 20,
		textWidth = is_mobile and 16 or 30,
		showLabelOnHover = true,
		vertical = is_mobile
	}
	local sliderRect = sliderSettings.vertical and {
		x = 5, y = replaySpeedHolder.size.w,
		w = replaySpeedHolder.size.w - 10, h = replaySpeedHolder.size.h - replaySpeedHolder.size.w - 5
	} or {
		x = 15, y = 25,
		w = replaySpeedHolder.size.w - 30, h = replaySpeedHolder.size.h - 25
	}
	local speed = get_replay_speed()
	local slider = TBMenu:spawnSlider2(replaySpeedHolder, sliderRect, speed, sliderSettings, updateFunc, nil, nil, updateLabelFunc)
	slider.bgColor = UICOLORWHITE

	local toggleSliderActiveState = function()
		if (get_replay_cache() > 0) then
			if (not slider.isactive) then
				slider.parent:activate()
				slider:activate()
				slider:reload()
			end
		else
			if (slider.isactive) then
				slider.btnUp()
				slider:deactivate()
				slider.parent:deactivate()
			end
		end
	end
	if (is_mobile) then
		local regularSpeed = slider.parent:addChild({
			pos = { slider.parent.size.w / 2 - 3, slider.parent.size.h / 3 + 2 },
			size = { 6, slider.parent.size.h / 3 - 2 },
			bgColor = { 1, 1, 1, 0.7 }
		})
		local speedMarks = slider.parent:addChild({
			pos = { slider.parent.size.w / 2 - 13, slider.size.h / 2 },
			size = { 26, slider.parent.size.h - slider.size.h },
			bgColor = { 1, 1, 1, 0.7 },
		})
		speedMarks:addCustomDisplay(true, function()
				set_color(unpack(speedMarks.bgColor))
				-- -1 speed
				draw_line(speedMarks.pos.x, speedMarks.pos.y + speedMarks.size.h * 0.083, speedMarks.pos.x + speedMarks.size.w, speedMarks.pos.y + speedMarks.size.h * 0.083, 2)

				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.333, speedMarks.pos.y + speedMarks.size.h * 0.1455, speedMarks.pos.x + speedMarks.size.w * 0.667, speedMarks.pos.y + speedMarks.size.h * 0.1455, 2)
				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.25, speedMarks.pos.y + speedMarks.size.h * 0.208, speedMarks.pos.x + speedMarks.size.w * 0.75, speedMarks.pos.y + speedMarks.size.h * 0.208, 2)
				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.333, speedMarks.pos.y + speedMarks.size.h * 0.2705, speedMarks.pos.x + speedMarks.size.w * 0.667, speedMarks.pos.y + speedMarks.size.h * 0.2705, 2)

				-- zero
				draw_line(speedMarks.pos.x, speedMarks.pos.y + speedMarks.size.h * 0.333, speedMarks.pos.x + speedMarks.size.w, speedMarks.pos.y + speedMarks.size.h * 0.333, 2)


				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.333, speedMarks.pos.y + speedMarks.size.h * 0.41625, speedMarks.pos.x + speedMarks.size.w * 0.667, speedMarks.pos.y + speedMarks.size.h * 0.41625, 2)
				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.25, speedMarks.pos.y + speedMarks.size.h * 0.4995, speedMarks.pos.x + speedMarks.size.w * 0.75, speedMarks.pos.y + speedMarks.size.h * 0.4995, 2)
				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.333, speedMarks.pos.y + speedMarks.size.h * 0.58275, speedMarks.pos.x + speedMarks.size.w * 0.667, speedMarks.pos.y + speedMarks.size.h * 0.58275, 2)

				-- 1 speed
				draw_line(speedMarks.pos.x, speedMarks.pos.y + speedMarks.size.h * 0.667, speedMarks.pos.x + speedMarks.size.w, speedMarks.pos.y + speedMarks.size.h * 0.667, 2)

				-- 2 speed
				draw_line(speedMarks.pos.x, speedMarks.pos.y + speedMarks.size.h * 0.833, speedMarks.pos.x + speedMarks.size.w, speedMarks.pos.y + speedMarks.size.h * 0.833, 2)

				toggleSliderActiveState()
			end)
	else
		local regularSpeed = slider.parent:addChild({
			pos = { slider.parent.size.w / 3 + 2, slider.parent.size.h / 2 - 3 },
			size = { slider.parent.size.w / 3 - 4, 6 },
			bgColor = { 1, 1, 1, 0.7 }
		})
		local speedMarks = slider.parent:addChild({
			pos = { slider.size.w / 2, slider.parent.size.h / 2 - 13 },
			size = { slider.parent.size.w - slider.size.w, 26 },
			bgColor = { 1, 1, 1, 0.7 },
		})
		speedMarks:addCustomDisplay(true, function()
				set_color(unpack(speedMarks.bgColor))
				-- -1 speed
				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.083, speedMarks.pos.y, speedMarks.pos.x + speedMarks.size.w * 0.083, speedMarks.pos.y + speedMarks.size.h, 2)

				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.1455, speedMarks.pos.y + speedMarks.size.h * 0.333, speedMarks.pos.x + speedMarks.size.w * 0.1455, speedMarks.pos.y + speedMarks.size.h * 0.667, 2)
				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.208, speedMarks.pos.y + speedMarks.size.h * 0.25, speedMarks.pos.x + speedMarks.size.w * 0.208, speedMarks.pos.y + speedMarks.size.h * 0.75, 2)
				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.2705, speedMarks.pos.y + speedMarks.size.h * 0.333, speedMarks.pos.x + speedMarks.size.w * 0.2705, speedMarks.pos.y + speedMarks.size.h * 0.667, 2)

				-- zero
				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.333, speedMarks.pos.y, speedMarks.pos.x + speedMarks.size.w * 0.333, speedMarks.pos.y + speedMarks.size.h, 2)

				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.41625, speedMarks.pos.y + speedMarks.size.h * 0.333, speedMarks.pos.x + speedMarks.size.w * 0.41625, speedMarks.pos.y + speedMarks.size.h * 0.667, 2)
				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.4995, speedMarks.pos.y + speedMarks.size.h * 0.25, speedMarks.pos.x + speedMarks.size.w * 0.4995, speedMarks.pos.y + speedMarks.size.h * 0.75, 2)
				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.58275, speedMarks.pos.y + speedMarks.size.h * 0.333, speedMarks.pos.x + speedMarks.size.w * 0.58275, speedMarks.pos.y + speedMarks.size.h * 0.667, 2)

				-- 1 speed
				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.667, speedMarks.pos.y, speedMarks.pos.x + speedMarks.size.w * 0.667, speedMarks.pos.y + speedMarks.size.h, 2)

				-- 2 speed
				draw_line(speedMarks.pos.x + speedMarks.size.w * 0.833, speedMarks.pos.y, speedMarks.pos.x + speedMarks.size.w * 0.833, speedMarks.pos.y + speedMarks.size.h, 2)

				toggleSliderActiveState()
			end)
	end

	replaySpeedHolder:addCustomDisplay(false, function()
			local speed, prev = get_replay_speed()
			local value = getSliderValueFromSpeed(UIElement.WorldState.game_paused == 0 and speed or prev)
			if (slider.lastVal ~= value) then
				if (slider.hoverState ~= BTN_NONE or slider.parent.hoverState == BTN_DN) then
					return
				end
				slider.setValue(value)
			end
		end)

	slider:reload()

	return slider
end

---@class ReplayHud : UIElement
---@field prevReplay UIElement Previous replay button
---@field nextReplay UIElement Next replay button
---@field hidden boolean Whether replay hud UIElement is currently hidden from user
---@field manualHidden boolean Whether relpay hud has been manually toggled off
---@field toggleClock number Last hud toggle timestamp
---@field cacheMode integer Last replay load attempt cache mode
---@field hasCache boolean Whether replay cache is available
---@field queue ReplayInfo[]|nil|-1 Replay queue used for prev/next buttons
---@field currentQueueIndex integer? Current replay index in queue
---@field PlayQueue function

---Spawns advanced replay UI
---@param reload ?boolean
---@return ReplayHud?
function Replays:spawnReplayAdvancedGui(reload)
	if (not reload and self.GameHud ~= nil) then return nil end
	set_hint_override()

	local is_mobile = is_mobile()
	local posX = is_mobile and TBHud.DefaultButtonSize * 2.5 or math.max(65 * TB_MENU_GLOBAL_SCALE, WIN_W * 0.15 - 65 * TB_MENU_GLOBAL_SCALE)
	local size = { math.min(1600, WIN_W - posX * 2), 65 * TB_MENU_GLOBAL_SCALE }
	posX = (WIN_W - size[1]) / 2

	local targetHeightShift = size[2] + math.max(SAFE_Y, 40)

	local posYRight = is_mobile and TBHud.DefaultButtonSize * 1.2 or 0
	local sizeRight = is_mobile and (WIN_H - posYRight - TBHud.DefaultButtonSize * 2.5) or 0
	local targetRightShift = size[2] + math.max(SAFE_X, 15)

	if (reload and self.GameHud ~= nil) then
		self.GameHud:kill(true)
		self.GameHud.size.w = size[1]
		self.GameHud:moveTo(posX, WIN_H)
		if (self.GameHudRight) then
			self.GameHudRight:kill(true)
			self.GameHudRight.size.h = sizeRight
			self.GameHudRight:moveTo(WIN_W, posYRight)
		end
	else
		---@diagnostic disable-next-line: assign-type-mismatch
		self.GameHud = UIElement.new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { posX, WIN_H },
			size = { size[1], size[2] }
		})

		if (is_mobile) then
			self.GameHudRight = UIElement.new({
				globalid = TB_MENU_HUB_GLOBALID,
				pos = { WIN_W, posYRight },
				size = { size[2], sizeRight }
			})
		end

		---@param direction 1|-1
		self.GameHud.PlayQueue = function(direction)
			if (self.GameHud.queue == nil or self.GameHud.queue == -1) then
				if (direction == 1) then
					play_next_replay()
				else
					play_prev_replay()
				end
				return
			end

			if (direction == 1) then
				self.GameHud.currentQueueIndex = self.GameHud.currentQueueIndex + 1
				if (self.GameHud.currentQueueIndex > #self.GameHud.queue) then
					self.GameHud.currentQueueIndex = 1
				end
			else
				self.GameHud.currentQueueIndex = self.GameHud.currentQueueIndex - 1
				if (self.GameHud.currentQueueIndex < 1) then
					self.GameHud.currentQueueIndex = #self.GameHud.queue
				end
			end
			local replayFile = utf8.gsub(self.GameHud.queue[self.GameHud.currentQueueIndex].filename, "^replay/", "")
			open_replay(replayFile, self.GameHud.cacheMode)
		end

		self.GameHud.hidden = false
		self.GameHud.toggleClock = UIElement.clock
		self.GameHud.hasCache = get_replay_cache() > 0
		self.GameHud.queue = -1
		self.GameHud:addCustomDisplay(true, function()
				local ws = UIElement.WorldState

				if (ws.replay_mode ~= 0) then
					local cacheState = get_replay_cache() > 0
					if (self.GameHud.hasCache ~= cacheState) then
						self.GameHud.hasCache = cacheState
						Replays:spawnReplayAdvancedGui(true)
					end
				end

				if (ws.replay_mode == 0) then
					self.GameHud.hidden = true
				end
				if (self.GameHud.prevReplay ~= nil and self.GameHud.nextReplay ~= nil) then
					if (self.GameHud.prevReplay:isDisplayed()) then
						if (ws.game_type == 1 or self.GameHud.queue == nil) then
							self.GameHud.prevReplay:hide(true)
							self.GameHud.nextReplay:hide(true)
						end
					elseif (ws.game_type == 0 and self.GameHud.queue ~= nil) then
						self.GameHud.prevReplay:show(true)
						self.GameHud.nextReplay:show(true)
					end
				end
				if (self.GameHud.hidden) then
					if (self.GameHud.pos.y < WIN_H) then
						local tweenTime = (UIElement.clock - self.GameHud.toggleClock) * 1.65
						self.GameHud:moveTo(nil, UITween.SineTween(self.GameHud.pos.y, WIN_H, tweenTime))
						if (self.GameHudRight ~= nil) then
							self.GameHudRight:moveTo(UITween.SineTween(self.GameHudRight.pos.x, WIN_W, tweenTime))
						end
					else
						self.GameHud:hide()
						if (self.GameHudRight ~= nil) then
							self.GameHudRight:hide()
						end
					end
				else
					if (self.GameHud.pos.y > WIN_H - targetHeightShift) then
						local tweenTime = (UIElement.clock - self.GameHud.toggleClock) * 1.65
						self.GameHud:moveTo(nil, UITween.SineTween(self.GameHud.pos.y, WIN_H - targetHeightShift, tweenTime))
						if (self.GameHudRight ~= nil) then
							self.GameHudRight:moveTo(UITween.SineTween(self.GameHudRight.pos.x, WIN_W - targetRightShift, tweenTime))
						end
					end
				end
			end)
	end
	self.GameHud.prevReplay = self.GameHud:addChild({
		pos = { 0, 0 },
		size = { self.GameHud.size.h / 3 * 2, self.GameHud.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	self.GameHud.prevReplay:addChild({
		shift = { self.GameHud.prevReplay.size.w / 6, 0 },
		bgImage = "../textures/menu/general/buttons/arrowleft.tga"
	})
	self.GameHud.prevReplay:addMouseUpHandler(function()
			self.GameHud.PlayQueue(-1)
		end)
	--[[local prevPopup = TBMenu:displayPopup(self.GameHud.prevReplay, TB_MENU_LOCALIZED.REPLAYHUDPREVREPLAY)
	if (prevPopup ~= nil) then
		prevPopup:moveTo(-(self.GameHud.prevReplay.size.w + prevPopup.size.w) / 2, self.GameHud.prevReplay.size.h + 2)
	end]]

	self.GameHud.nextReplay = self.GameHud:addChild({
		pos = { -self.GameHud.prevReplay.size.w, 0 },
		size = { self.GameHud.prevReplay.size.w, self.GameHud.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	self.GameHud.nextReplay:addChild({
		shift = { self.GameHud.nextReplay.size.w / 6, 0 },
		bgImage = "../textures/menu/general/buttons/arrowright.tga"
	})
	self.GameHud.nextReplay:addMouseUpHandler(function()
			self.GameHud.PlayQueue(1)
		end)
	--[[local nextPopup = TBMenu:displayPopup(self.GameHud.nextReplay, TB_MENU_LOCALIZED.REPLAYHUDNEXTREPLAY)
	if (nextPopup ~= nil) then
		nextPopup:moveTo(-(self.GameHud.nextReplay.size.w + nextPopup.size.w) / 2, self.GameHud.nextReplay.size.h + 2)
	end]]

	local slidersHolder = self.GameHud:addChild({ shift = { self.GameHud.prevReplay.size.w + 10, 0 }})
	if (is_mobile) then
		Replays:spawnReplayProgressSlider(slidersHolder)
		if (self.GameHud.hasCache) then
			Replays:spawnReplaySpeedSlider(self.GameHudRight)
		end
	elseif (not self.GameHud.hasCache) then
		Replays:spawnReplayProgressSlider(slidersHolder)
	else
		local speedHolderWidth = math.min(math.max(350, slidersHolder.size.w * 0.1), slidersHolder.size.w * 0.5 - 5)
		local progressHolder = slidersHolder:addChild({
			size = { slidersHolder.size.w - speedHolderWidth - 10, slidersHolder.size.h }
		})
		Replays:spawnReplayProgressSlider(progressHolder)
		local speedHolder = slidersHolder:addChild({
			pos = { -speedHolderWidth, 0 },
			size = { speedHolderWidth, slidersHolder.size.h }
		})
		Replays:spawnReplaySpeedSlider(speedHolder)
	end

	return self.GameHud
end

---@param mode ?boolean
function Replays:toggleHud(mode)
	if (self.GameHud == nil) then return end
	local targetMode = mode ~= nil and not mode or not self.GameHud.hidden
	if (targetMode == self.GameHud.hidden) then
		return
	end
	self.GameHud.hidden = targetMode
	self.GameHud.toggleClock = os.clock_real()
	if (mode == nil) then
		self.GameHud.manualHidden = targetMode
	end
	if (not self.GameHud.hidden) then
		self.GameHud:show()
		if (self.GameHudRight ~= nil) then
			self.GameHudRight:show()
		end
	end
end

---Returns default temp replay name used by replay saver
---@return string
function Replays.GetSaveTempName()
	return ReplaysInternal.SaveTempName
end
