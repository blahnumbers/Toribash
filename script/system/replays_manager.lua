-- Replays manager
local REPLAY_VOTE = 101
local SELECTED_REPLAY = { element = nil, defaultColor = nil, time = 0, replay = nil }
local MAXFOLDERLEVELS = 4

if (Replays == nil) then
	---**Toribash Replays manager class**
	---
	---**Version 5.60**
	---* Fixes to make UI work with modern TBMenu class
	---* Use *utf8lib* when parsing replay files to ensure we handle multibyte symbols correctly
	---@class Replays
	---@field RootFolder ReplayDirectory Root replay directory Information
	---@field CacheReady boolean
	Replays = {
		RootFolder = { name = "replay", fullname = "replay" },
		CacheReady = false,
		ver = 5.60
	}
	Replays.__index = Replays

	---Replay information class
	---@class ReplayInfo
	---@field name string Replay name displayed in-game
	---@field filename string Replay filename
	---@field author string Replay author
	---@field bouts string[] List of players in replay
	---@field mod string Replay mod name
	---@field tags string Space separated replay tags
	---@field hiddentags string Space separated replay hidden tags
	---@field uploaded boolean Whether replay has been uploaded to servers
	ReplayInfo = {}
	ReplayInfo.__index = ReplayInfo
end

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

	return rplInfo
end

function ReplayInfo.FromReplay(path)
	local replay = Files:open("../" .. path, FILES_MODE_READONLY)
	local replayLines = replay:readAll()
	replay:close()

	local rplInfo = ReplayInfo.New(path)
	local hasDecap = false
	local hasMadman = false

	pcall(function()
		for _, ln in pairs(replayLines) do
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
			---This will affect usernames with underscores. Do we care? Probably not.
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
---@return boolean
---@return string? #Error message in case of failure
function ReplayInfo:UpdateFile()
	local file = Files:open("../" .. self.filename)
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
			right = true
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
			local targetText = TB_MENU_LOCALIZED.REPLAYSUPDATINGCACHE .. " (" .. folder .. " folder)\n" .. math.min(math.ceil((count - 1) / #files * 100), 100) .. "% " .. TB_MENU_LOCALIZED.WORDDONE
			if (TBMenu.StatusMessage.messageView.str ~= targetText) then
				TBMenu.StatusMessage.messageView:addAdaptedText(true, targetText, nil, nil, 4, nil, 0.8)
			end

			while (1) do
				local v = files[count]
				pcall(function()
					if (v:match(REPLAY_TEMPNAME) or v:match(REPLAY_SAVETEMPNAME) or (v:find("^" .. REPLAY_EVENT) and not includeEventTemp)) then
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
						if (rplTable.fullname .. "/" .. v == SELECTED_FOLDER.fullname) then
							SELECTED_FOLDER = rplTable.folders[#rplTable.folders]
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
					TBMenu.StatusMessage.endTime = UIElement.clock
					if (not SELECTED_FOLDER.name) then
						SELECTED_FOLDER = Replays.RootFolder
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

	local file = Files:open("../replay/replaycache.dat", FILES_MODE_READONLY)
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
	Replays.RootFolder.replays = nil
	Replays.RootFolder.folders = nil

	local file = Files:open("../replay/replaycache.dat", FILES_MODE_READWRITE)
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
		local cacheName = utf8.gsub(utf8.lower(rplInfo.filename), " ", "_")
		cacheData[cacheName] = rplInfo
	end
	TBMenu:showStatusMessage("")
	Replays:fetchReplayData(Replays.RootFolder.name, Replays.RootFolder, file, cacheData, includeEventTemp)
end

function Replays:getServerReplaysData(lines)
	for i, ln in pairs(lines) do
		if (ln:match("^#Total")) then
			SERVER_REPLAYS.total = ln:gsub("%D", "") + 0
		elseif (not ln:match("^#")) then
			local segments = 10
			local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
			local info = {
				id = tonumber(data_stream[1]),
				rplname = data_stream[2],
				uploader = data_stream[3],
				date = data_stream[4],
				description = data_stream[5]:gsub("\\'", "'"):gsub("\\\"", "\""):gsub("\\r", ""),
				downloads = data_stream[6] + 0,
				score = tonumber(data_stream[7]),
				votes = tonumber(data_stream[8]),
				tags = data_stream[9],
				uservote = tonumber(data_stream[10])
			}
			table.insert(SERVER_REPLAYS, info)
		end
	end
end

function Replays:getReplayComments(lines)
	local comments = {}
	for i, ln in pairs(lines) do
		if (ln:match("^#Total")) then
			comments.total = ln:gsub("%D", "") + 0
		elseif (not ln:match("^#")) then
			local segments = 5
			local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
			pcall(function()
				local comment = {
					id = tonumber(data_stream[1]),
					user = data_stream[2],
					score = tonumber(data_stream[3]),
					comment = data_stream[4]:gsub("\\'", "'"):gsub("\\\"", "\""),
					date = data_stream[5]
				}
				table.insert(comments, comment)
			end)
		end
	end
	return comments
end

function Replays:getServerReplays(action, offset, searchStr)
	TB_MENU_REPLAYS_ONLINE = 1
	local action = action or SERVER_REPLAYS.action
	local offset = offset or SERVER_REPLAYS.offset
	local searchStr = searchStr and searchStr:lower() or SERVER_REPLAYS.search
	if (action ~= SERVER_REPLAYS.action) then
		SELECTED_SERVER_REPLAY.id = 0
	end

	download_replay_result(action, offset, searchStr)
	local overlay = TBMenu:spawnWindowOverlay()
	local waitNotification = UIElement:new({
		parent = overlay,
		pos = { overlay.size.w / 3, overlay.size.h / 2 - 100 },
		size = { overlay.size.w / 3, 200 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local waitMessage = UIElement:new({
		parent = waitNotification,
		pos = { 10, 10 },
		size = { waitNotification.size.w - 20, waitNotification.size.h / 2 }
	})
	waitMessage:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSUPDATINGCOMMUNITY)
	local waitAnimation = UIElement:new({
		parent = waitNotification,
		pos = { waitNotification.size.w / 2 - 25, waitMessage.size.h + waitMessage.shift.y },
		size = { 50, waitNotification.size.h - waitMessage.size.h - waitMessage.shift.y * 3 }
	})
	local infoMessage = TB_MENU_LOCALIZED.REPLAYSFILTERSDATE
	if (action == 2) then
		infoMessage = TB_MENU_LOCALIZED.REPLAYSFILTERSRATING
	elseif (action == 3) then
		infoMessage = TB_MENU_LOCALIZED.REPLAYSFILTERSPOPULARITY
	elseif (action == 4) then
		infoMessage = TB_MENU_LOCALIZED.REPLAYSFILTERSTAGGED .. " \"" .. searchStr .. "\""
	elseif (action == 5) then
		infoMessage = TB_MENU_LOCALIZED.REPLAYSFILTERSBY .. " " .. searchStr
	end
	local serverReplays = Files:open("../data/script/system/rplres.txt", FILES_MODE_READONLY)
	local rot, scale, time = 10, 90, os.clock_real()
	waitAnimation:addCustomDisplay(true, function()
			set_color(1, 1, 1, 0.8)
			draw_disk(waitAnimation.pos.x + waitAnimation.size.w / 2, waitAnimation.pos.y + waitAnimation.size.w / 2, waitAnimation.size.w / 4, waitAnimation.size.w / 2, 200, 1, rot, scale, 0)
			rot = rot + 2.5
			scale = scale > 359 and -360 or scale + 5
			if (os.clock_real() - time > 0.5) then
				if (not serverReplays:isDownloading()) then
					serverReplays:reopen()
					local filedata = serverReplays:readAll()
					serverReplays:close()
					overlay:kill()
					SERVER_REPLAYS = {}
					SERVER_REPLAYS.total = 0
					SERVER_REPLAYS.action = action
					SERVER_REPLAYS.offset = offset
					SERVER_REPLAYS.search = searchStr
					SERVER_REPLAYS.info = infoMessage
					if (filedata) then
						Replays:getServerReplaysData(filedata)
					end
					Replays:showServerReplays()
				end
			end
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

function Replays:findReplays(str, rplTable, searchResults)
	local searchResults = searchResults or { name = {}, filename = {}, author = {}, bouts = {}, mod = {}, tags = {}, hiddentags = {} }
	local searchStringRaw = type(str) == "table" and str[1]:lower() or str:lower()
	local searchStrings = {}
	for i in string.gmatch(searchStringRaw, "[^ ]+") do
		table.insert(searchStrings, i)
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

function Replays:showSearchList(viewElement, replayInfo, toReload, replays)
	viewElement:kill(true)
	local elementHeight = 40

	local listingHolder = UIElement:new({
		parent = viewElement,
		pos = { 0, 0 },
		size = { viewElement.size.w - 20, viewElement.size.h }
	})

	local listElements = {}
	local goBack = UIElement:new({
		parent = listingHolder,
		pos = { 0, #listElements * elementHeight },
		size = { listingHolder.size.w, elementHeight },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	table.insert(listElements, goBack)
	goBack:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSBACKTOALLREPLAYS, nil, nil, 4, nil, 0.6)
	goBack:addMouseHandlers(nil, function()
			TB_MENU_REPLAYS_SEARCH = nil
			Replays:showList(viewElement.parent, replayInfo, SELECTED_FOLDER)
		end)

	for section, replayList in pairs(replays) do
		if (#replayList > 0) then
			local sectionName = UIElement:new({
				parent = listingHolder,
				pos = { 10, #listElements * elementHeight },
				size = { listingHolder.size.w - 20, elementHeight }
			})
			table.insert(listElements, sectionName)
			local sectionStr = TB_MENU_LOCALIZED.REPLAYSMATCHBY .. " " .. section
			if (section == "hiddentags") then
				sectionStr = "hidden tags"
			end
			sectionName:addCustomDisplay(true, function()
					sectionName:uiText(sectionStr, nil, nil, nil, LEFTMID)
				end)
			for i, replay in pairs(replayList) do
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
				if (SELECTED_REPLAY.replay and SELECTED_REPLAY.replay.filename == replay.filename or i == 1) then
					SELECTED_REPLAY.element = replayElement
					SELECTED_REPLAY.defaultColor = { replayElement.bgColor[1], replayElement.bgColor[2], replayElement.bgColor[3], replayElement.bgColor[4] }
				end
				replayElement:addMouseHandlers(nil, function()
						if (SELECTED_REPLAY.element == replayElement and SELECTED_REPLAY.time + 0.5 > os.clock_real()) then
							Replays:playReplay(replay)
							return
						end
						SELECTED_REPLAY.time = os.clock_real()
						SELECTED_REPLAY.element.bgColor = { SELECTED_REPLAY.defaultColor[1], SELECTED_REPLAY.defaultColor[2], SELECTED_REPLAY.defaultColor[3], SELECTED_REPLAY.defaultColor[4] }
						SELECTED_REPLAY.element = replayElement
						SELECTED_REPLAY.defaultColor = { replayElement.bgColor[1], replayElement.bgColor[2], replayElement.bgColor[3], replayElement.bgColor[4] }
						Replays:showReplayInfo(replayInfo, replay)
					end)

				local replayName = UIElement:new({
					parent = replayElement,
					pos = { 10, 0 },
					size = { replayElement.size.w / 2 - 20, replayElement.size.h }
				})
				replayName:addCustomDisplay(true, function()
						replayName:uiText(replay.name, nil, nil, 4, LEFTMID, 0.65)
					end)
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
				replayAuthor:addCustomDisplay(true, function()
						replayAuthor:uiText(replayAuthorStr, nil, nil, 4, nil, 0.65)
					end)
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
				replayMod:addCustomDisplay(true, function()
						replayMod:uiText(replay.mod, nil, nil, 4, nil, 0.65)
					end)
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

function Replays:playReplay(replay)
	local whiteoverlay = TBMenu:spawnWindowOverlay()
	local cacheMode = get_option("replaycache") == 2 and 1 or 0

	local loading = UIElement:new({
		parent = whiteoverlay,
		pos = { WIN_W / 4, WIN_H / 7 * 3 },
		size = { WIN_W / 2, WIN_H / 7 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	if (replay.mod ~= "classic") then
		local files = get_files("data/mod", "")
		local folders = {}
		for i,v in pairs(files) do
			if (not v:find("^%.+[%s%S]*$") and not v:find("%.%a+$") and not v:find("^.*%.tbm$")) then
				table.insert(folders, v)
			end
		end
		local modFile = Files:open("../data/mod/" .. replay.mod)
		local id = 1
		while (not modFile.data and id < #folders) do
			modFile = Files:open("../data/mod/" .. folders[id] .. "/" .. replay.mod)
			id = id + 1
		end
		if (not modFile.data) then
			modFile = Files:open("../data/mod/downloads/" .. replay.mod)
			loading:addAdaptedText(false, TB_MENU_LOCALIZED.MODSDOWNLOADINGMOD)
			local modname = replay.mod:gsub("%.tbm$", "")
			download_mod(modname)
			local downloadWait = UIElement:new({
				parent = loading,
				pos = { 0, 0 },
				size = { 0, 0 }
			})
			local wait = 0
			downloadWait:addCustomDisplay(true, function()
					wait = wait + 1
					if (not modFile:isDownloading() and wait > 5) then
						loading:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
						local framesN = 0
						downloadWait:addCustomDisplay(true, function()
								framesN = framesN + 1
								if (framesN > 4) then
									open_replay(replay.filename, cacheMode)
									close_menu()
								end
							end)
					end
				end)
		else
			modFile:close()
			local wait = 0
			loading:addCustomDisplay(false, function()
					loading:uiText(TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
					wait = wait + 1
					if (wait > 4) then
						open_replay(replay.filename, cacheMode)
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
					open_replay(replay.filename, cacheMode)
					close_menu()
				end
			end)
	end
end

function Replays.ResetCache()
	local file = Files:open("../replay/replaycache.dat", FILES_MODE_WRITE)
	if (not file.data) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORREFRESHINGCACHE)
	end
	file:close()
	Replays.RootFolder.replays = nil
	Replays.RootFolder.folders = nil
	SELECTED_FOLDER = { fullname = "replay" }
	Replays:showMain(TBMenu.CurrentSection)
end

function Replays:showList(viewElement, replayInfo, level, doSearch)
	viewElement:kill(true)

	local elementHeight = 40
	local rplTable = level or Replays.RootFolder
	SELECTED_FOLDER = rplTable

	local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 50, 50, 20, TB_MENU_DEFAULT_BG_COLOR)

	TBMenu:addBottomBloodSmudge(botBar, 1)

	local replaysTitle = UIElement:new({
		parent = topBar,
		pos = { 10, 0 },
		size = { topBar.size.w / 3 * 2 - 20, topBar.size.h }
	})
	local replaysTitleStr = TB_MENU_LOCALIZED.MAINMENUREPLAYSNAME
	if (rplTable.fullname ~= "replay") then
		replaysTitleStr = replaysTitleStr .. " - " .. rplTable.name
	end
	replaysTitle:addAdaptedText(true, replaysTitleStr, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, 0.2)

	if (level.fullname ~= "replay/autosave") then
		local posX = 0
		if (level.fullname ~= "replay/my replays" and level.fullname ~= "replay") then
			local editFolderButton = UIElement:new({
				parent = topBar,
				pos = { -topBar.size.h + 5, 5 },
				size = { topBar.size.h - 10, topBar.size.h - 10 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 },
				bgImage = "../textures/menu/general/buttons/edit.tga"
			})
			posX = editFolderButton.shift.x
			editFolderButton:addMouseHandlers(nil, function()
					Replays:showEditFolderWindow(SELECTED_FOLDER)
				end)
		elseif (level.fullname == "replay") then
			local refreshCacheButton = UIElement:new({
				parent = topBar,
				pos = { -topBar.size.h + 5, 5 },
				size = { topBar.size.h - 10, topBar.size.h - 10 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 },
				bgImage = "../textures/menu/general/buttons/settingsreset.tga"
			})
			posX = refreshCacheButton.shift.x
			refreshCacheButton:addMouseHandlers(nil, function()
					TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYSREFRESHCACHEPROMPT, Replays.ResetCache)
				end)
		end

		local addFolderButton = UIElement:new({
			parent = topBar,
			pos = { topBar.size.w / 3 * 2 + 10, 5 },
			size = { topBar.size.w / 3 - 15 + posX, topBar.size.h - 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		addFolderButton:addCustomDisplay(false, function()
				addFolderButton:uiText(TB_MENU_LOCALIZED.REPLAYSADDFOLDER)
			end)
		addFolderButton:addMouseHandlers(nil, function()
				Replays:showNewFolderWindow()
			end)
	end

	local inputFieldHolder = botBar:addChild({
		shift = { 10, 10 },
		shapeType = ROUNDED,
		rounded = 4
	})
	local searchInputField = TBMenu:spawnTextField2(inputFieldHolder, nil, TB_MENU_REPLAYS_SEARCH, TB_MENU_LOCALIZED.SEARCHNOTE, {
		darkerMode = true,
		fontId = FONTS.LSMALL,
		textScale = 0.65,
		textColor = UICOLORWHITE
	})


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
	--searchInputField:addKeyboardHandlers(nil, searchFunction)
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
				SELECTED_REPLAY.replay = nil
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
		folderName:addCustomDisplay(true, function()
				folderName:uiText(rplTable.parent.name, nil, nil, 4, LEFTMID, 0.8)
			end)
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
				SELECTED_REPLAY.replay = nil
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
		folderName:addCustomDisplay(true, function()
				folderName:uiText(folder.name, nil, nil, 4, LEFTMID, 0.8)
			end)
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
		if (SELECTED_REPLAY.replay and SELECTED_REPLAY.replay.filename == replay.filename or i == 1) then
			SELECTED_REPLAY.element = replayElement
			SELECTED_REPLAY.defaultColor = { replayElement.bgColor[1], replayElement.bgColor[2], replayElement.bgColor[3], replayElement.bgColor[4] }
		end
		replayElement:addMouseHandlers(nil, function()
				if (SELECTED_REPLAY.element == replayElement and SELECTED_REPLAY.time + 0.5 > os.clock_real()) then
					Replays:playReplay(replay)
					return
				end
				SELECTED_REPLAY.time = os.clock_real()
				SELECTED_REPLAY.element.bgColor = { SELECTED_REPLAY.defaultColor[1], SELECTED_REPLAY.defaultColor[2], SELECTED_REPLAY.defaultColor[3], SELECTED_REPLAY.defaultColor[4] }
				SELECTED_REPLAY.element = replayElement
				SELECTED_REPLAY.defaultColor = { replayElement.bgColor[1], replayElement.bgColor[2], replayElement.bgColor[3], replayElement.bgColor[4] }
				Replays:showReplayInfo(replayInfo, replay)
			end)

		local replayName = UIElement:new({
			parent = replayElement,
			pos = { 10, 0 },
			size = { replayElement.size.w / 2 - 20, replayElement.size.h }
		})
		replayName:addCustomDisplay(true, function()
				replayName:uiText(replay.name, nil, nil, 4, LEFTMID, 0.65)
			end)
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
		replayAuthor:addCustomDisplay(true, function()
				replayAuthor:uiText(replayAuthorStr, nil, nil, 4, nil, 0.65)
			end)
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
		replayMod:addCustomDisplay(true, function()
				replayMod:uiText(replay.mod, nil, nil, 4, nil, 0.65)
			end)
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
	Replays:showReplayInfo(replayInfo, SELECTED_REPLAY.replay or rplTable.replays[1])
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
	replayTagName:addCustomDisplay(true, function()
			replayTagName:uiText(tag, nil, nil, 4, LEFTMID, 0.7)
		end)
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
			for i,tag in pairs(updatedTags) do
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
	---@type Vector2
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
		---@type Vector2
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
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS,
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
		size = { editFolderView.size.w - closeButtonSize * 3, 50 }
	})
	editFolderTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSTAGSMODIFYING .. " \"" .. SELECTED_FOLDER.fullname .. "\" " .. TB_MENU_LOCALIZED.REPLAYSMODIFYINGFOLDER, nil, nil, FONTS.BIG)

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
	}, SELECTED_FOLDER.name, TB_MENU_LOCALIZED.REPLAYSFOLDERNAME, {
		textAlign = LEFTMID,
		fontId = 4,
		textScale = 0.8
	})

	local deleteButton = editFolderView:addChild({
		pos = { 10, -50 },
		size = { editFolderView.size.w / 3 - 10, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	deleteButton:addAdaptedText(TB_MENU_LOCALIZED.WORDDELETE)
	deleteButton:addMouseHandlers(nil, function()
			local function delete_folder(folder)
				local parentFolder = folder.fullname:gsub("/" .. folder.name .. "$", "")
				local error = remove_replay_subfolder(folder.fullname:gsub("^replay/", ""))
				if (error) then
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORDELETING .. " " .. TB_MENU_LOCALIZED.REPLAYSERRORDELETINGFOLDER .. " " .. folder.fullname .. ": " .. error)
					return
				end
				SELECTED_FOLDER = { fullname = parentFolder }
			end
			if (#SELECTED_FOLDER.replays == 0 and #SELECTED_FOLDER.folders == 0) then
				delete_folder(SELECTED_FOLDER)
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
						if (error) then
							TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORMOVING .. " " .. v.filename .. " " .. TB_MENU_LOCALIZED.REPLAYSERRORMOVINGTO .. " " .. newFilename .. ": " .. error)
							return
						end
					end
					delete_folder(folder)
				end
				TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYSFOLDERNOTEMPTYDELETEWARNING, function() delete_folder_with_files(SELECTED_FOLDER) editFolderOverlay:kill() Replays:showMain(TBMenu.CurrentSection) end)
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
			local parentFolder = SELECTED_FOLDER.fullname:gsub(SELECTED_FOLDER.name .. "$", "")
			if (SELECTED_FOLDER.name == newFolderName) then
				editFolderOverlay:kill()
				return
			end
			local error = rename_replay_subfolder(SELECTED_FOLDER.fullname:gsub("^replay/", ""), parentFolder:gsub("^replay/", "") .. newFolderName)
			if (error) then
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORRENAMINGFOLDER .. ": " .. error)
				return
			end
			SELECTED_FOLDER = { fullname = parentFolder .. newFolderName }
			editFolderOverlay:kill()
			Replays:showMain(TBMenu.CurrentSection)
		end)
end

function Replays:showNewFolderWindow()
	local _, level = SELECTED_FOLDER.fullname:gsub("/", "")
	if (level > MAXFOLDERLEVELS - 1) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSFOLDERLEVELERROR1 ..  " " .. MAXFOLDERLEVELS .. " " .. TB_MENU_LOCALIZED.REPLAYSFOLDERLEVELERROR2)
		return
	end
	local newFolderOverlay = TBMenu:spawnWindowOverlay()
	local newFolderView = UIElement:new({
		parent = newFolderOverlay,
		pos = { newFolderOverlay.size.w / 4, newFolderOverlay.size.h / 2 - 100 },
		size = { newFolderOverlay.size.w / 2, 200 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local newFolderTitle = UIElement:new({
		parent = newFolderView,
		pos = { 10, 0 },
		size = { newFolderView.size.w - 20, 50 }
	})
	newFolderTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSADDINGFOLDER .. " " .. SELECTED_FOLDER.fullname, nil, nil, FONTS.BIG)
	local newFolderInputBG = UIElement:new({
		parent = newFolderView,
		pos = { 10, newFolderView.size.h / 2 - 20 },
		size = { newFolderView.size.w - 20, 40 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	local newFolderInputOverlay = UIElement:new({
		parent = newFolderInputBG,
		pos = { 1, 1 },
		size = { newFolderInputBG.size.w - 2, newFolderInputBG.size.h - 2 },
		bgColor = { 1, 1, 1, 0.5 }
	})
	local newFolderInput = UIElement:new({
		parent = newFolderInputOverlay,
		pos = { 10, 0 },
		size = { newFolderInputOverlay.size.w - 20, newFolderInputOverlay.size.h },
		interactive = true,
		textfield = true,
		textfieldsingleline = true
	})
	newFolderInput:addMouseHandlers(function()
			newFolderInput:enableMenuKeyboard(newFolderInput)
		end)
	TBMenu:displayTextfield(newFolderInput, FONTS.SMALL, nil, UICOLORBLACK, TB_MENU_LOCALIZED.REPLAYSNEWFOLDERNAME)
	local cancelButton = UIElement:new({
		parent = newFolderView,
		pos = { 10, -50 },
		size = { newFolderView.size.w / 2 - 15, 40 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	cancelButton:addCustomDisplay(false, function()
			cancelButton:uiText(TB_MENU_LOCALIZED.BUTTONCANCEL)
		end)
	cancelButton:addMouseHandlers(nil, function()
			newFolderOverlay:kill()
		end)
	local saveButton = UIElement:new({
		parent = newFolderView,
		pos = { newFolderView.size.w / 2 + 5, -50 },
		size = { newFolderView.size.w / 2 - 15, 40 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	saveButton:addCustomDisplay(false, function()
			saveButton:uiText(TB_MENU_LOCALIZED.BUTTONCREATE)
		end)
	local function spawnNewFolder()
		if (newFolderInput.textfieldstr[1] ~= newFolderInput.textfieldstr[1]:match("[^ ][%w+ ]+")) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSFOLDERALPHANUMERIC)
			return
		end
		local parentFolder = SELECTED_FOLDER.fullname:gsub("^replay/*", "")
		parentFolder = parentFolder:len() > 0 and parentFolder .. "/" or parentFolder
		local newFolderName = parentFolder .. newFolderInput.textfieldstr[1]:gsub(" +$", "")
		local result = add_replay_subfolder(newFolderName)
		if (result) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORADDINGFOLDER .. ": " .. result)
			return
		end
		newFolderOverlay:kill()
		SELECTED_FOLDER = { fullname = "replay/" .. newFolderName }
		Replays:showMain(TBMenu.CurrentSection)
	end
	newFolderInput:addEnterAction(spawnNewFolder)
	saveButton:addMouseHandlers(nil, spawnNewFolder)
end

function Replays:showUploadWindow(replay)
	local uploadOverlay = TBMenu:spawnWindowOverlay()
	local uploadView = UIElement:new({
		parent = uploadOverlay,
		pos = { uploadOverlay.size.w / 6, uploadOverlay.size.h / 5 },
		size = { uploadOverlay.size.w / 6 * 4, uploadOverlay.size.h / 5 * 3 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local uploadTitle = UIElement:new({
		parent = uploadView,
		pos = { 10, 0 },
		size = { uploadView.size.w - 20, uploadView.size.h / 8 }
	})
	uploadTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSUPLOAD .. " " .. replay.name ..  " " .. TB_MENU_LOCALIZED.REPLAYSUPLOADTORIBASHSERVERS, nil, nil, FONTS.BIG, nil, 0.7)

	local replayUploadInfoView = UIElement:new({
		parent = uploadView,
		pos = { 10, uploadTitle.size.h },
		size = { uploadView.size.w - 20, uploadView.size.h * 7 / 8 - uploadTitle.size.h }
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
			tip = TB_MENU_LOCALIZED.REPLAYSDESCTIP,
			value = { "" },
			input = true,
			fulltext = true
		},
		{
			name = TB_MENU_LOCALIZED.REPLAYSTAGS,
			desc = TB_MENU_LOCALIZED.REPLAYSTAGSINFO,
			value = { string.gsub(replay.tags .. " " .. replay.hiddentags, "^ +", "") },
			tip = TB_MENU_LOCALIZED.REPLAYSTAGSTIP,
			input = true
		}
	}


	posY, elementHeight = 0, 90
	for i,v in pairs(replayData) do
		local replayUploadInfoHolder = UIElement:new({
			parent = replayUploadInfoView,
			pos = { 0, posY },
			size = { replayUploadInfoView.size.w, elementHeight }
		})
		local replayUploadInfoNameTitle = UIElement:new({
			parent = replayUploadInfoHolder,
			pos = { 0, 0 },
			size = { replayUploadInfoHolder.size.w / 3, replayUploadInfoHolder.size.h / 3 }
		})
		replayUploadInfoNameTitle:addCustomDisplay(true, function()
				replayUploadInfoNameTitle:uiText(v.name, nil, nil, nil, LEFTBOT)
			end)
		local replayUploadInfoNameDesc = UIElement:new({
			parent = replayUploadInfoHolder,
			pos = { 0, replayUploadInfoNameTitle.size.h },
			size = { replayUploadInfoNameTitle.size.w, replayUploadInfoHolder.size.h - replayUploadInfoNameTitle.size.h }
		})
		replayUploadInfoNameDesc:addCustomDisplay(true, function()
				replayUploadInfoNameDesc:uiText(v.desc, nil, nil, 4, LEFT, 0.7)
			end)
		local replayUploadInfoDataField = UIElement:new({
			parent = replayUploadInfoHolder,
			pos = { replayUploadInfoHolder.size.w * 2 / 5, 0 },
			size = { replayUploadInfoHolder.size.w * 3 / 5, replayUploadInfoHolder.size.h }
		})
		local replayUploadInfoDataInputBG = UIElement:new({
			parent = replayUploadInfoDataField,
			pos = { 10, 10 },
			size = { replayUploadInfoDataField.size.w - 20, v.fulltext and replayUploadInfoDataField.size.h - 20 or 30 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		if (v.input) then
			local replayUploadInfoDataInputOverlay = UIElement:new({
				parent = replayUploadInfoDataInputBG,
				pos = { 1, 1 },
				size = { replayUploadInfoDataInputBG.size.w - 2, replayUploadInfoDataInputBG.size.h - 2 },
				bgColor = { 1, 1, 1, 0.5 }
			})
			local replayUploadInfoDataInput = UIElement:new({
				parent = replayUploadInfoDataInputOverlay,
				pos = { 10, 5 },
				size = { replayUploadInfoDataInputOverlay.size.w - 20, replayUploadInfoDataInputOverlay.size.h - 10 },
				interactive = true,
				textfield = true,
				textfieldstr = v.value,
				textfieldsingleline = not v.fulltext
			})
			replayUploadInfoDataInput:addMouseHandlers(function()
					replayUploadInfoDataInput:enableMenuKeyboard(replayUploadInfoDataInput)
				end)
			TBMenu:displayTextfield(replayUploadInfoDataInput, FONTS.SMALL, nil, UICOLORBLACK, v.tip, v.fulltext and LEFT)
		else
			local replayUploadInfoData = UIElement:new({
				parent = replayUploadInfoDataInputBG,
				pos = { 1, 1 },
				size = { replayUploadInfoDataInputBG.size.w - 2, replayUploadInfoDataInputBG.size.h - 2 },
				bgColor = { 1, 1, 1, 0.3 }
			})
			local replayUploadInfoDataText = UIElement:new({
				parent = replayUploadInfoData,
				pos = { 10, 5 },
				size = { replayUploadInfoData.size.w - 20, replayUploadInfoData.size.h - 10 }
			})
			replayUploadInfoDataText:addCustomDisplay(true, function()
					replayUploadInfoDataText:uiText(v.value[1], nil, nil, 4, LEFTMID, 0.6, nil, nil, UICOLORBLACK)
				end)
		end

		posY = posY + elementHeight
	end

	local cancelButton = UIElement:new({
		parent = uploadView,
		pos = { 10, -uploadView.size.h / 8 },
		size = { uploadView.size.w / 2 - 15, uploadView.size.h / 10 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	cancelButton:addCustomDisplay(false, function()
			cancelButton:uiText(TB_MENU_LOCALIZED.BUTTONCANCEL)
		end)
	cancelButton:addMouseHandlers(nil, function()
			uploadOverlay:kill()
		end)
	local uploadButton = UIElement:new({
		parent = uploadView,
		pos = { uploadView.size.w / 2 + 5, -uploadView.size.h / 8 },
		size = { uploadView.size.w / 2 - 15, uploadView.size.h / 10 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	uploadButton:addCustomDisplay(false, function()
			if (replayData[1].value[1] == "" or replayData[2].value[1] == "" or replayData[3].value[1] == "") then
				uploadButton:deactivate()
				uploadButton.bgColor = { 0, 0, 0, 0.1 }
			else
				uploadButton:activate()
				uploadButton.bgColor = { 0, 0, 0, 0.3 }
			end
			uploadButton:uiText(TB_MENU_LOCALIZED.BUTTONUPLOAD)
		end)
	uploadButton:addMouseHandlers(nil, function()
			local overlay = TBMenu:spawnWindowOverlay()
			local width = overlay.size.w / 7 * 3
			local uploadingView = UIElement:new({
				parent = overlay,
				pos = { (overlay.size.w - width) / 2, overlay.size.h / 2 - overlay.size.h / 10 },
				size = { width, overlay.size.h / 5 },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			TBMenu:displayLoadingMark(uploadingView, TB_MENU_LOCALIZED.REPLAYUPLOADINPROGRESS)
			Request:queue(function()
					upload_replay(	replayData[1].value[1],
									replayData[2].value[1],
									replayData[3].value[1],
									"replay/" .. replay.filename)
				end, "replayupload", function()
					local response = get_network_response()
					if (response:find("^SUCCESS")) then
						uploadingView:kill(true)
						uploadingView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYUPLOADSUCCESSFUL)
						local uploadClose = UIElement:new({
							parent = uploadingView,
							pos = { 0, 0 },
							size = { 0, 0 },
						})
						local spawnTime = os.clock_real()
						uploadClose:addCustomDisplay(true, function()
								if (spawnTime + 1.5 < os.clock_real()) then
									overlay:kill()
									uploadOverlay:kill()
								end
							end)
					else
						overlay:kill()
						TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADERROR .. ": " .. response:gsub("^ERROR 0;", ""), function() end, function() uploadOverlay:kill() end)
					end
				end, function()
					overlay:kill()
					TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADFAILED, function() uploadOverlay:kill() Replays:showUploadWindow(replay) end, function() uploadOverlay:kill() end)
				end)
		end)
end

---Returns `TBMenuDropdown` elements data containing user replay folders hierarchy
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
				local targetPath = (includeRoot and "replay/" or "") .. dir .. v
				table.insert(dropdownOptions, {
					text = (level > 0 and ('' .. string.rep(" ", level * 2)) or '') .. v .. '',
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
					v.value = path
				end, v.value, true)
			local dropdownHolder = dataFieldHolder:addChild({
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			}, true)
			TBMenu:spawnDropdown(dropdownHolder, dropdownOptions, dataFieldHolder.size.h, nil, nil, {
					scale = 0.8, fontid = 4, uppercase = true, alignment = LEFTMID
				}, {
					scale = 0.8, fontid = 4, uppercase = true, alignment = LEFTMID
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

	saveButton:addMouseHandlers(nil, function()
			local newReplay = ReplayInfo.New(replay)
			newReplay.name = replayData[2].value[1]

			local directory = utf8.gsub(replay.filename, "/[^/]+$", "")
			local fileMove = replayData[3].value ~= directory

			print(replayData[3].value)
			print(directory)
			if (replayData[1].value[1] ~= filenameClean or fileMove) then
				local newname = utf8.gsub(replayData[3].value, "^replay(/?)(.*)", "%2%1") .. replayData[1].value[1] .. ".rpl"
				local curname = replay.filename:gsub("^replay/", "")
				local error = rename_replay(curname, newname)
				if (error ~= nil) then
					TBMenu:showStatusMessage((fileMove and TB_MENU_LOCALIZED.REPLAYSERRORMOVINGREPLAY or TB_MENU_LOCALIZED.REPLAYSERRORRENAMINGREPLAY) .. ": " .. result)
					return
				end
				newReplay.filename = "replay/" .. newname
				if (fileMove) then
					SELECTED_FOLDER = { fullname = directory }
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
		bgColor = TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	deleteButton:addAdaptedText(TB_MENU_LOCALIZED.WORDDELETE)
	deleteButton:addMouseHandlers(nil, function()
			TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYSCONFIRMDELETION .. " " .. replay.filename:gsub("^.*/", "") .. " " .. TB_MENU_LOCALIZED.REPLAYSCONFIRMDELETION2, function()
					local result = delete_replay(replay.filename:gsub("^replay/", ""))
					if (result) then
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERRORDELETING .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAY)
						return
					end
					manageOverlay:kill()
					Replays:updateReplayCache(replay, nil)
					SELECTED_REPLAY.replay = nil
					Replays:showMain(TBMenu.CurrentSection)
				end)
		end)
end

function Replays:canUploadReplay(replay)
	if (replay.uploaded == 1) then
		return false
	end

	local isInReplay = false
	if (replay.author == TB_MENU_PLAYER_INFO.username) then
		isInReplay = true
	end
	for i,v in pairs(replay.bouts) do
		if (v == TB_MENU_PLAYER_INFO.username) then
			isInReplay = true
		end
	end
	return isInReplay
end

function Replays:showAutosaveToggle(viewElement)
	local autosaveStatus = get_option("autosave")
	local autosaveView = UIElement:new({
		parent = viewElement,
		pos = { 10, -viewElement.size.h / 8 },
		size = { viewElement.size.w - 20, viewElement.size.h / 10 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	local autosaveCheckbox = UIElement:new({
		parent = autosaveView,
		pos = { 0, 0 },
		size = { autosaveView.size.h, autosaveView.size.h }
	})
	autosaveView:addCustomDisplay(true, function()
			if (autosaveView.hoverState == BTN_DN) then
				set_color(unpack(autosaveView.pressedColor))
			else
				set_color(unpack(autosaveView.animateColor))
			end
			draw_quad(	autosaveView.pos.x + autosaveCheckbox.shift.x,
						autosaveView.pos.y + autosaveCheckbox.shift.y,
						autosaveCheckbox.size.w,
						autosaveCheckbox.size.h	)
		end)
	local autosaveIcon = UIElement:new({
		parent = autosaveCheckbox,
		pos = { 2, 2 },
		size = { autosaveCheckbox.size.w - 4, autosaveCheckbox.size.h - 4 },
		bgImage = "../textures/menu/general/buttons/checkmark.tga"
	})
	if (autosaveStatus == 0) then
		autosaveIcon:hide()
	end
	autosaveView:addMouseHandlers(nil, function()
			autosaveStatus = 1 - autosaveStatus
			set_option("autosave", autosaveStatus)
			if (autosaveStatus == 1) then
				autosaveIcon:show()
			else
				autosaveIcon:hide()
			end
		end)
	local autosaveText = UIElement:new({
		parent = autosaveView,
		pos = { 50, 0 },
		size = { autosaveView.size.w - 60, autosaveView.size.h }
	})
	autosaveText:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSAUTOSAVEOPTION)
end

function Replays:showReplayInfo(viewElement, replay)
	viewElement:kill(true)
	local bottomSmudge = TBMenu:addBottomBloodSmudge(viewElement, 2)
	if (not replay) then
		local heightMod = 0
		if (SELECTED_FOLDER.fullname == "replay/autosave") then
			Replays:showAutosaveToggle(viewElement)
			heightMod = viewElement.size.h / 8
		end
		local noReplaysFound = UIElement:new({
			parent = viewElement,
			pos = { 10, 10 },
			size = { viewElement.size.w - 20, viewElement.size.h - 20 - heightMod }
		})
		noReplaysFound:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSEMPTYFOLDER)
		return
	end

	SELECTED_REPLAY.replay = replay
	if (SELECTED_REPLAY.element) then
		-- Element can be null judging by crash logs but I can't replicate it
		-- Let's hope having this check doesn't spawn more errors
		SELECTED_REPLAY.element.bgColor = { 1, 1, 1, 0.3 }
	end

	local replayName = UIElement:new({
		parent = viewElement,
		pos = { 10, 0 },
		size = { viewElement.size.w - 20, viewElement.size.h / 8 }
	})
	replayName:addAdaptedText(true, replay.name, nil, nil, FONTS.BIG, nil, 0.65, 0.4, 0.2)
	local replayAuthor = UIElement:new({
		parent = viewElement,
		pos = { 10, replayName.shift.y + replayName.size.h },
		size = { viewElement.size.w - 20, viewElement.size.h / 10 }
	})
	local replayAuthorStr = replay.author == "autosave" and "autosave" or TB_MENU_LOCALIZED.REPLAYSBY .. " " .. replay.author
	replayAuthor:addCustomDisplay(true, function()
			replayAuthor:uiText(replayAuthorStr, nil, nil, 4, nil, 0.8)
		end)
	local replayBouts = UIElement:new({
		parent = viewElement,
		pos = { 10, replayAuthor.shift.y + replayAuthor.size.h },
		size = { viewElement.size.w - 20, viewElement.size.h / 16 }
	})
	local replayBoutsStr = replay.bouts[1] ~= " " and replay.bouts[1] or TB_MENU_LOCALIZED.REPLAYSDATACORRUPT
	for i = 2, #replay.bouts do
		replayBoutsStr = replay.bouts[i] ~= " " and replayBoutsStr .. " " .. TB_MENU_LOCALIZED.WORDVS .. " " .. replay.bouts[i] or replayBoutsStr
	end
	replayBouts:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSPLAYERS .. ": " .. replayBoutsStr, nil, nil, 4, LEFTBOT, 0.7)
	local replayMod = UIElement:new({
		parent = viewElement,
		pos = { 10, replayBouts.shift.y + replayBouts.size.h },
		size = { viewElement.size.w - 20, viewElement.size.h / 16 }
	})
	replayMod:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSMOD .. ": " .. replay.mod, nil, nil, 4, LEFTMID, 0.7)
	local replayTags = UIElement:new({
		parent = viewElement,
		pos = { 10, replayMod.shift.y + replayMod.size.h },
		size = { viewElement.size.w - 20, viewElement.size.h / 8 }
	})
	local tagsText = replay.tags == " " and TB_MENU_LOCALIZED.WORDNONE or replay.tags
	replayTags:addCustomDisplay(true, function()
			replayTags:uiText(TB_MENU_LOCALIZED.REPLAYSTAGS .. ": " .. tagsText, nil, nil, 4, LEFT, 0.7)
		end)

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
	local replayTagsAdd = UIElement:new({
		parent = replayTags,
		pos = { tagsDispositionX, tagsDispositionY },
		size = { 18, 18 },
		shapeType = ROUNDED,
		rounded = 3,
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
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

	local posY = 0
	if (SELECTED_FOLDER.fullname == "replay/autosave") then
		Replays:showAutosaveToggle(viewElement)
		posY = -viewElement.size.h / 8
	end

	local replayManageButton = UIElement:new({
		parent = viewElement,
		pos = { 10, -viewElement.size.h / 8 + posY },
		size = { viewElement.size.w - 20, viewElement.size.h / 10 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 1, 1, 0.3 }
	})
	replayManageButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSMANAGE)
	replayManageButton:addMouseHandlers(nil, function()
			Replays:showReplayManageWindow(replay)
		end)
	posY = replayManageButton.shift.y

	if (Replays:canUploadReplay(replay)) then
		local replayUploadButton = UIElement:new({
			parent = viewElement,
			pos = { 10, -viewElement.size.h / 8 + posY },
			size = { viewElement.size.w - 20, viewElement.size.h / 10 },
			interactive = not replay.uploaded,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.3 }
		})
		replayUploadButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONUPLOAD)
		replayUploadButton:addMouseHandlers(nil, function()
				Replays:showUploadWindow(replay)
			end)
		posY = replayUploadButton.shift.y
	end

	local replayViewButton = UIElement:new({
		parent = viewElement,
		pos = { 10, -viewElement.size.h / 8 + posY },
		size = { viewElement.size.w - 20, viewElement.size.h / 10 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 1, 1, 0.3 }
	})
	replayViewButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONVIEW)
	replayViewButton:addMouseHandlers(nil, function()
			Replays:playReplay(replay)
		end)
end

function Replays:showSearchWindow()
	local searchOverlay = TBMenu:spawnWindowOverlay()
	local searchView = UIElement:new({
		parent = searchOverlay,
		pos = { searchOverlay.size.w / 6, searchOverlay.size.h / 2 - 200 },
		size = { searchOverlay.size.w / 3 * 2, 400 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local searchTitle = UIElement:new({
		parent = searchView,
		pos = { 10, 0 },
		size = { searchView.size.w - 20, 50 }
	})
	searchTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSCOMMUNITYTITLEINFO, nil, nil, FONTS.BIG, nil, 0.65)

	local searchByDate = UIElement:new({
		parent = searchView,
		pos = { 10, searchTitle.shift.y + searchTitle.size.h + 10 },
		size = { (searchView.size.w - 30) / 2, 70 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	searchByDate:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSFILTERSDATE)
	searchByDate:addMouseHandlers(nil, function()
			searchOverlay:kill()
			Replays:getServerReplays(1, 1)
		end)

	--[[local searchByRating = UIElement:new({
		parent = searchView,
		pos = { searchByDate.shift.x + searchByDate.size.w + 10, searchTitle.shift.y + searchTitle.size.h + 10 },
		size = { (searchView.size.w - 40) / 3, 70 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	searchByRating:addAdaptedText(false, "By rating")
	searchByRating:addMouseHandlers(nil, function()
			searchOverlay:kill()
			Replays:getServerReplays(2, 1)
		end)]]

	local searchByPopularity = UIElement:new({
		parent = searchView,
		pos = { searchByDate.shift.x + searchByDate.size.w + 10, searchTitle.shift.y + searchTitle.size.h + 10 },
		size = { (searchView.size.w - 30) / 2, 70 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	searchByPopularity:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSFILTERSPOPULARITY)
	searchByPopularity:addMouseHandlers(nil, function()
			searchOverlay:kill()
			Replays:getServerReplays(3, 1)
		end)

	local searchByTagTitle = UIElement:new({
		parent = searchView,
		pos = { 10, searchByDate.shift.y + searchByDate.size.h + 20 },
		size = { searchView.size.w - 20, 25 }
	})
	searchByTagTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSFILTERSBYTAG, nil, nil, nil, LEFTMID)
	local searchByTagView = UIElement:new({
		parent = searchView,
		pos = { 10, searchByTagTitle.shift.y + searchByTagTitle.size.h + 5 },
		size = { searchView.size.w - 20, 40 }
	})
	local searchByTagInputBG = UIElement:new({
		parent = searchByTagView,
		pos = { 0, 0 },
		size = { searchByTagView.size.w - 160, searchByTagView.size.h },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	local searchByTagInputOverlay = UIElement:new({
		parent = searchByTagInputBG,
		pos = { 1, 1 },
		size = { searchByTagInputBG.size.w - 2, searchByTagInputBG.size.h - 2 },
		bgColor = { 1, 1, 1, 0.4 },
	})
	local searchByTagInput = UIElement:new({
		parent = searchByTagInputOverlay,
		pos = { 10, 0 },
		size = { searchByTagInputOverlay.size.w - 20, searchByTagInputOverlay.size.h },
		interactive = true,
		textfield = true,
		textfieldsingleline = true
	})
	searchByTagInput:addMouseHandlers(function()
			searchByTagInput:enableMenuKeyboard(searchByTagInput)
		end)
	TBMenu:displayTextfield(searchByTagInput, 4, 0.7, UICOLORBLACK, TB_MENU_LOCALIZED.SEARCHNOTE)
	local searchByTagButton = UIElement:new({
		parent = searchByTagView,
		pos = { searchByTagInputBG.size.w + 10, 0 },
		size = { searchByTagView.size.w - searchByTagInputBG.size.w - 10, searchByTagView.size.h },
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	searchByTagButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSEARCH)
	searchByTagButton:addMouseHandlers(nil, function()
			searchOverlay:kill()
			Replays:getServerReplays(4, 1, searchByTagInput.textfieldstr[1])
		end)

	local searchByUserTitle = UIElement:new({
		parent = searchView,
		pos = { 10, searchByTagView.shift.y + searchByTagView.size.h + 20 },
		size = { searchView.size.w - 20, 25 }
	})
	searchByUserTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSFILTERSUPLOADER, nil, nil, nil, LEFTMID)
	local searchByUserView = UIElement:new({
		parent = searchView,
		pos = { 10, searchByUserTitle.shift.y + searchByUserTitle.size.h + 5 },
		size = { searchView.size.w - 20, 40 }
	})
	local searchByUserInputBG = UIElement:new({
		parent = searchByUserView,
		pos = { 0, 0 },
		size = { searchByUserView.size.w - 160, searchByUserView.size.h },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	local searchByUserInputOverlay = UIElement:new({
		parent = searchByUserInputBG,
		pos = { 1, 1 },
		size = { searchByUserInputBG.size.w - 2, searchByUserInputBG.size.h - 2 },
		bgColor = { 1, 1, 1, 0.4 },
	})
	local searchByUserInput = UIElement:new({
		parent = searchByUserInputOverlay,
		pos = { 10, 0 },
		size = { searchByUserInputOverlay.size.w - 20, searchByUserInputOverlay.size.h },
		interactive = true,
		textfield = true,
		textfieldsingleline = true
	})
	searchByUserInput:addMouseHandlers(function()
			searchByUserInput:enableMenuKeyboard(searchByUserInput)
		end)
	TBMenu:displayTextfield(searchByUserInput, 4, 0.7, UICOLORBLACK, TB_MENU_LOCALIZED.SEARCHNOTE)
	local searchByUserButton = UIElement:new({
		parent = searchByUserView,
		pos = { searchByUserInputBG.size.w + 10, 0 },
		size = { searchByUserView.size.w - searchByUserInputBG.size.w - 10, searchByUserView.size.h },
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	searchByUserButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSEARCH)
	searchByUserButton:addMouseHandlers(nil, function()
			searchOverlay:kill()
			Replays:getServerReplays(5, 1, searchByUserInput.textfieldstr[1])
		end)

	local cancelButton = UIElement:new({
		parent = searchView,
		pos = { searchView.size.w / 4, -50 },
		size = { searchView.size.w / 2, 40 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	cancelButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCANCEL)
	cancelButton:addMouseHandlers(nil, function()
			searchOverlay:kill()
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
				replayFile = Files:open("../replay/downloads/" .. REPLAY_TEMPNAME .. ".rpl", FILES_MODE_READONLY)
			end
			if (replayFile) then
				if (not replayFile:isDownloading()) then
					replayFile:close()
					local replaydata = ReplayInfo.FromReplay(replayFile.path)
					if (replaydata.mod ~= "classic") then
						local files = get_files("data/mod", "")
						local folders = {}
						for i,v in pairs(files) do
							if (not v:find("^%.+[%s%S]*$") and not v:find("%.%a+$") and not v:find("^.*%.tbm$")) then
								table.insert(folders, v)
							end
						end
						local modFile = Files:open("../data/mod/" .. replaydata.mod)
						local id = 1
						while (not modFile.data and id < #folders) do
							modFile = Files:open("../data/mod/" .. folders[id] .. "/" .. replaydata.mod)
							id = id + 1
						end
						if (not modFile.data) then
							modFile = Files:open("../data/mod/downloads/" .. replaydata.mod)
							previewView:addAdaptedText(false, TB_MENU_LOCALIZED.MODSDOWNLOADINGMOD)
							local modname = replaydata.mod:gsub("%.tbm$", "")
							download_mod(modname)
							local wait = 0
							downloadWait:addCustomDisplay(true, function()
									wait = wait + 1
									if (not modFile:isDownloading() and wait > 5) then
										previewView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
										local framesN = 0
										downloadWait:addCustomDisplay(true, function()
												framesN = framesN + 1
												if (framesN > 4) then
													open_replay("downloads/" .. REPLAY_TEMPNAME .. ".rpl", cacheMode)
													close_menu()
												end
											end)
									end
								end)
						else
							modFile:close()
							downloadWait:addCustomDisplay(false, function()
									previewView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
									local framesN = 0
									downloadWait:addCustomDisplay(true, function()
											framesN = framesN + 1
											if (framesN > 4) then
												open_replay("downloads/" .. REPLAY_TEMPNAME .. ".rpl", cacheMode)
												close_menu()
											end
										end)
								end)
						end
					else
						local wait = 0
						downloadWait:addCustomDisplay(false, function()
								previewView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADINGREPLAY)
								local framesN = 0
								downloadWait:addCustomDisplay(true, function()
										framesN = framesN + 1
										if (framesN > 4) then
											open_replay("downloads/" .. REPLAY_TEMPNAME .. ".rpl", cacheMode)
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
				replayFile = Files:open("../replay/downloads/" .. rplname .. ".rpl", FILES_MODE_READONLY)
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

function Replays:showServerReplayList(replaysList, replayInfo)
	SELECTED_SERVER_REPLAY.element = nil
	SELECTED_SERVER_REPLAY.replay = nil
	SELECTED_SERVER_REPLAY.displayid = nil

	local posX, elementHeight = 0, 25
	local toReload, topBar, botBar, replayListing, replayHolder, scrollBG = TBMenu:prepareScrollableList(replaysList, 50, 35, 20)
	TBMenu:addBottomBloodSmudge(botBar, 1)

	local helpButton = UIElement:new({
		parent = topBar,
		pos = { 10, 10 },
		size = { topBar.size.h - 20, topBar.size.h - 20 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.2 },
		hoverColor = { 1, 1, 1, 0.2 },
		pressedColor = { 1, 1, 1, 0.2 },
		shapeType = ROUNDED,
		rounded = topBar.size.h
	})
	local popup = TBMenu:displayHelpPopup(helpButton, TB_MENU_LOCALIZED.REPLAYSCOMMUNITYDOUBLECLICKINFO, true)
	popup:moveTo(topBar.size.h - 15, -(popup.size.h - topBar.size.h + 20) / 2, true)

	local listTitle = UIElement:new({
		parent = topBar,
		pos = { helpButton.shift.x + helpButton.size.w + 10, 0 },
		size = { topBar.size.w - 20 - helpButton.shift.x - helpButton.size.w, topBar.size.h }
	})
	if (SERVER_REPLAYS.total == 0) then
		listTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSCOMMUNITYNOFOUND, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, 0.2)
	else
		local currentPage, totalPages = math.ceil(SERVER_REPLAYS.offset / 100), math.floor(SERVER_REPLAYS.total / 100)
		listTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSREPLAYS .. " " .. SERVER_REPLAYS.info .. ": " .. TB_MENU_LOCALIZED.PAGINATIONPAGE .. " " .. currentPage .. " " .. TB_MENU_LOCALIZED.PAGINATIONPAGEOF .. " " .. totalPages, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, 0.2)
	end

	local replayElements = {}
	local tempHolder = nil
	if (SERVER_REPLAYS.offset > 1) then
		local offset = SERVER_REPLAYS.offset - 100 > 0 and SERVER_REPLAYS.offset - 100 or 1
		local offsetDecrementButton = UIElement:new({
			parent = replayHolder,
			pos = { 0, posX },
			size = { replayHolder.size.w, elementHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		table.insert(replayElements, offsetDecrementButton)
		offsetDecrementButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADPREVIOUS .. " " .. SERVER_REPLAYS.offset - offset .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAYS:upper(), nil, nil, 4, nil, 0.7)
		offsetDecrementButton:addMouseHandlers(nil, function()
				Replays:getServerReplays(SERVER_REPLAYS.action, offset, SERVER_REPLAYS.search)
			end)
		posX = posX + elementHeight
	end
	for i,v in pairs(SERVER_REPLAYS) do
		if (type(i) == "number") then
			local replayElementHolder = UIElement:new({
				parent = replayHolder,
				pos = { 0, posX },
				size = { replayHolder.size.w, elementHeight * 2 },
				interactive = true,
				bgColor = i % 2 == 1 and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 }
			})
			if (i == 1) then
				tempHolder = replayElementHolder
			end
			local dispid = #replayElements
			if (v.id == SELECTED_SERVER_REPLAY.id) then
				SELECTED_SERVER_REPLAY = { element = replayElementHolder, color = { unpack(replayElementHolder.bgColor) }, id = v.id, replay = v, displayid = dispid }
				replayElementHolder.bgColor = replayElementHolder.pressedColor
			end
			replayElementHolder:addCustomDisplay(true, function()
					if (replayElementHolder.pos.y < topBar.pos.y or replayElementHolder.pos.y > botBar.pos.y) then
						replayElementHolder:deactivate()
					else
						replayElementHolder:activate()
					end
				end)
			local replayElement = UIElement:new({
				parent = replayHolder,
				pos = { 0, posX },
				size = { replayHolder.size.w, elementHeight }
			})
			table.insert(replayElements, replayElement)
			posX = posX + elementHeight
			local replayName = UIElement:new({
				parent = replayElement,
				pos = { 10, 0 },
				size = { replayElement.size.w / 2 - 20, replayElement.size.h }
			})
			replayName:addAdaptedText(true, v.rplname, nil, nil, 4, LEFTMID, 0.65)
			local nameSeparator = UIElement:new({
				parent = replayName,
				pos = { replayName.size.w + replayName.shift.x / 2, replayName.size.h / 4 },
				size = { 1, replayName.size.h / 2 },
				bgColor = { 1, 1, 1, 0.2 }
			})
			local replayRating = UIElement:new({
				parent = replayElement,
				pos = { replayName.shift.x * 2 + replayName.size.w, 0 },
				size = { (replayElement.size.w - replayName.size.w - replayName.shift.x * 5) / 3, replayElement.size.h }
			})
			Replays:showReplayRating(replayRating, v.score, v.votes)
			local ratingSeparator = UIElement:new({
				parent = replayRating,
				pos = { replayRating.size.w + replayName.shift.x / 2, replayRating.size.h / 4 },
				size = { 1, replayRating.size.h / 2 },
				bgColor = { 1, 1, 1, 0.2 }
			})
			local replayUploader = UIElement:new({
				parent = replayElement,
				pos = { -(replayRating.size.w + replayName.shift.x) * 2, 0 },
				size = { replayRating.size.w, replayElement.size.h }
			})
			replayUploader:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSBY .. " " .. v.uploader, nil, nil, 4, nil, 0.65)
			local uploaderSeparator = UIElement:new({
				parent = replayUploader,
				pos = { replayUploader.size.w + replayName.shift.x / 2, replayUploader.size.h / 4 },
				size = { 1, replayUploader.size.h / 2 },
				bgColor = { 1, 1, 1, 0.2 }
			})
			local replayDate = UIElement:new({
				parent = replayElement,
				pos = { -(replayRating.size.w + replayName.shift.x), 0 },
				size = { replayUploader.size.w, replayElement.size.h }
			})
			replayDate:addAdaptedText(true, v.date, nil, nil, 4, nil, 0.65)
			local replayTags = UIElement:new({
				parent = replayHolder,
				pos = { 0, posX },
				size = { replayHolder.size.w, elementHeight }
			})
			replayElement:addCustomDisplay(true, function()
					if ((replayElementHolder.hoverState == BTN_DN and replayTags:isDisplayed()) or (replayElementHolder.hoverState == BTN_DN and MOUSE_Y <= replayElement.pos.y + replayElement.size.h)) then
						set_color(unpack(replayElementHolder.pressedColor))
					elseif (MOUSE_Y > replayElement.pos.y + replayElement.size.h and not replayTags:isDisplayed()) then
						set_color(unpack(replayElementHolder.bgColor))
					else
						set_color(unpack(replayElementHolder.animateColor))
					end
					draw_quad(replayElement.pos.x, replayElement.pos.y, replayElement.size.w, replayElement.size.h)
				end)
			replayTags:addCustomDisplay(true, function()
					if ((replayElementHolder.hoverState == BTN_DN and replayElement:isDisplayed()) or (replayElementHolder.hoverState == BTN_DN and MOUSE_Y >= replayTags.pos.y)) then
						set_color(unpack(replayElementHolder.pressedColor))
					elseif (MOUSE_Y < replayTags.pos.y and not replayElement:isDisplayed()) then
						set_color(unpack(replayElementHolder.bgColor))
					else
						set_color(unpack(replayElementHolder.animateColor))
					end
					draw_quad(replayTags.pos.x, replayTags.pos.y, replayTags.size.w, replayTags.size.h)
				end)
			replayElementHolder.lastPress = 0
			replayElementHolder:addMouseHandlers(nil, function(s, x, y)
					if (y < botBar.pos.y and y > topBar.pos.y + topBar.size.h) then
						if (os.clock_real() - replayElementHolder.lastPress < 0.5) then
							download_replay(v.id, REPLAY_TEMPNAME)
							Replays:showServerReplayPreview()
							return
						end
						replayElementHolder.lastPress = os.clock_real()
						if (SELECTED_SERVER_REPLAY.element) then
							SELECTED_SERVER_REPLAY.element.bgColor = { unpack(SELECTED_SERVER_REPLAY.color) }
						end
						SELECTED_SERVER_REPLAY = { element = replayElementHolder, color = { unpack(replayElementHolder.bgColor) }, id = v.id, replay = v, displayid = dispid }
						replayElementHolder.bgColor = replayElementHolder.pressedColor
						Replays:showServerReplayInfo(replayInfo, v)
					end
				end)
			table.insert(replayElements, replayTags)
			posX = posX + replayTags.size.h
			local replayTagsStr = UIElement:new({
				parent = replayTags,
				pos = { 10, 0 },
				size = { replayTags.size.w / 6 * 5 - 20, replayTags.size.h }
			})
			replayTagsStr:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSTAGS .. ": " .. v.tags, nil, nil, 4, LEFTMID, 0.6)
			local replayDownloads = UIElement:new({
				parent = replayTags,
				pos = { -replayTags.size.w / 6, 0 },
				size = { replayTags.size.w / 6 - 20, replayTags.size.h }
			})
			replayDownloads:addAdaptedText(true, v.downloads .. (v.downloads == 1 and " " .. TB_MENU_LOCALIZED.REPLAYSDOWNLOAD or " " .. TB_MENU_LOCALIZED.REPLAYSDOWNLOADS), nil, nil, 4, RIGHTMID, 0.6)
		end
	end
	if (SERVER_REPLAYS.offset + 100 < SERVER_REPLAYS.total) then
		local offsetIncrementButton = UIElement:new({
			parent = replayHolder,
			pos = { 0, posX },
			size = { replayHolder.size.w, elementHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		table.insert(replayElements, offsetIncrementButton)
		offsetIncrementButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSLOADNEXT .. " " .. (SERVER_REPLAYS.total - SERVER_REPLAYS.offset >= 100 and 100 or SERVER_REPLAYS.total - SERVER_REPLAYS.offset) .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAYS:upper(), nil, nil, 4, nil, 0.7)
		offsetIncrementButton:addMouseHandlers(nil, function()
				Replays:getServerReplays(SERVER_REPLAYS.action, SERVER_REPLAYS.offset + 100, SERVER_REPLAYS.search)
			end)
	end
	for i,v in pairs(replayElements) do
		v:hide()
	end

	local scrollBar = TBMenu:spawnScrollBar(replayHolder, #replayElements, elementHeight)
	if (SERVER_REPLAYS.total > 0) then
		scrollBar:makeScrollBar(replayHolder, replayElements, toReload)
	end

	if (SELECTED_SERVER_REPLAY.displayid and replayHolder.size.h < elementHeight * 2 * SELECTED_SERVER_REPLAY.displayid) then
		scrollBar.btnDown(4, 0, -SELECTED_SERVER_REPLAY.displayid)
	end

	if (not SELECTED_SERVER_REPLAY.replay and tempHolder) then
		SELECTED_SERVER_REPLAY = { element = tempHolder, color = { unpack(tempHolder.bgColor) }, id = SERVER_REPLAYS[1].id, replay = SERVER_REPLAYS[1], displayid = 1 }
		tempHolder.bgColor = tempHolder.pressedColor
	end
	Replays:showServerReplayInfo(replayInfo, SELECTED_SERVER_REPLAY.replay)
end

function Replays:showReplayRating(viewElement, score, votes, uservote)
	local votes = votes
	local score = score
	local scale = math.floor(viewElement.size.w / 5 > viewElement.size.h and viewElement.size.h or viewElement.size.w / 5)
	local displaynum = votes > 0 and math.floor(score / votes + 0.5) or 0
	local leftShift = (viewElement.size.w - scale * 5) / 2
	local uservote = uservote or 0

	for i = 1, displaynum do
		local ratingStar = UIElement:new({
			parent = viewElement,
			pos = { leftShift + (i - 1) * scale, (viewElement.size.h - scale) / 2 },
			size = { scale, scale },
			bgImage = scale > 32 and "../textures/menu/general/buttons/star.tga" or "../textures/menu/general/buttons/startiny.tga"
		})
		if (uservote >= i) then
			local ratingSign = UIElement:new({
				parent = ratingStar,
				pos = { 0, 0 },
				size = { ratingStar.size.w, ratingStar.size.h },
				bgImage = "../textures/menu/general/buttons/starborderglow.tga"
			})
		end
	end
	for i = displaynum + 1, 5 do
		local ratingStarTransparent = UIElement:new({
			parent = viewElement,
			pos = { leftShift + (i - 1) * scale, (viewElement.size.h - scale) / 2 },
			size = { scale, scale },
			bgImage = uservote >= i and "../textures/menu/general/buttons/starborderglow.tga" or (scale > 32 and "../textures/menu/general/buttons/starborder.tga" or "../textures/menu/general/buttons/starbordertiny.tga")
		})
	end
end

function Replays:showReplayRatingVote(viewElement, vote)
	local scale = math.floor(viewElement.size.w / 5) > viewElement.size.h - 10 and viewElement.size.h - 10 or math.floor(viewElement.size.w / 5)
	local width = (viewElement.size.w - 50) / 5 > scale and (viewElement.size.w - 50) / 5 or scale
	local posX = (viewElement.size.w - width * 5) / 2
	local stars = { transparent = {}, colored = {} }
	for i = 5, 1, -1 do
		local starView = UIElement:new({
			parent = viewElement,
			pos = { posX + (5 - i) * width, (viewElement.size.h - scale) / 2 },
			size = { width, scale },
			interactive = true
		})
		starView.starid = 6 - i
		local starTransparent = UIElement:new({
			parent = starView,
			pos = { (starView.size.w - scale) / 2, 0 },
			size = { scale, scale },
			bgImage = "../textures/menu/general/buttons/startransparenthuge.tga"
		})
		local starColoredTransparent = UIElement:new({
			parent = starView,
			pos = { (starView.size.w - scale) / 2, 0 },
			size = { scale, scale },
			bgImage = "../textures/menu/general/buttons/startransparentcoloredhuge.tga"
		})
		local starColored = UIElement:new({
			parent = starView,
			pos = { (starView.size.w - scale) / 2, 0 },
			size = { scale, scale },
			bgImage = "../textures/menu/general/buttons/starhuge.tga"
		})
		starColoredTransparent:hide()
		starColored:hide()
		table.insert(stars.transparent, starColoredTransparent)
		table.insert(stars.colored, starColored)
		starView:addMouseHandlers(nil, function()
				vote.score = starView.starid
				for i = 1, starView.starid do
					stars.colored[i]:show(true)
				end
				for i = starView.starid + 1, 5 do
					stars.colored[i]:hide(true)
				end
			end)
		starView:addCustomDisplay(false, function()
				if (starView.hoverState == BTN_HVR) then
					for i = 1, starView.starid do
						stars.transparent[i]:show()
					end
					for i = starView.starid + 1, 5 do
						stars.transparent[i]:hide()
					end
				else
					stars.transparent[starView.starid]:hide()
				end
			end)
	end
end

function Replays:showReplayVoteWindow(replay)
	local voteOverlay = TBMenu:spawnWindowOverlay()
	local voteView = UIElement:new({
		parent = voteOverlay,
		pos = { voteOverlay.size.w / 4, voteOverlay.size.h / 2 - 200 },
		size = { voteOverlay.size.w / 2, 400 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local voteTitle = UIElement:new({
		parent = voteView,
		pos = { 10, 0 },
		size = { voteView.size.w - 20, 50 }
	})
	voteTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSVOTINGON .. " " .. replay.rplname .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAY, nil, nil, FONTS.BIG, nil, 0.65)
	local voteScoreView = UIElement:new({
		parent = voteView,
		pos = { 10, voteTitle.shift.y + voteTitle.size.h },
		size = { voteView.size.w - 20, 80 }
	})
	local replayVote = { score = 0 }
	Replays:showReplayRatingVote(voteScoreView, replayVote)

	local voteCommentBG = UIElement:new({
		parent = voteView,
		pos = { 10, voteScoreView.shift.y + voteScoreView.size.h + 10 },
		size = { voteView.size.w - 20, 200 },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	local voteCommentOverlay = UIElement:new({
		parent = voteCommentBG,
		pos = { 1, 1 },
		size = { voteCommentBG.size.w - 2, voteCommentBG.size.h - 2 },
		bgColor = { 1, 1, 1, 0.4 }
	})
	local voteCommentInput = UIElement:new({
		parent = voteCommentOverlay,
		pos = { 10, 10 },
		size = { voteCommentOverlay.size.w - 20, voteCommentOverlay.size.h - 20 },
		textfield = true,
		interactive = true
	})
	voteCommentInput:addMouseHandlers(nil, function()
			voteCommentInput:enableMenuKeyboard(voteCommentInput)
		end)
	TBMenu:displayTextfield(voteCommentInput, FONTS.SMALL, 1, UICOLORBLACK, TB_MENU_LOCALIZED.REPLAYSCOMMENT .. " (" .. TB_MENU_LOCALIZED.WORDOPTIONAL .. ")", LEFT)

	local voteCancel = UIElement:new({
		parent = voteView,
		pos = { 10, -50 },
		size = { voteView.size.w / 2 - 15, 40 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	voteCancel:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCANCEL)
	voteCancel:addMouseHandlers(false, function()
			voteOverlay:kill()
		end)
	local voteSubmit = UIElement:new({
		parent = voteView,
		pos = { voteView.size.w / 2 + 5, -50 },
		size = { voteView.size.w / 2 - 15, 40 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	voteSubmit:deactivate()
	voteSubmit:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSUBMIT)
	voteSubmit:addMouseHandlers(nil, function()
			local info = replay.id .. ";" .. replayVote.score .. ";" .. voteCommentInput.textfieldstr[1]
			show_dialog_box(REPLAY_VOTE, TB_MENU_LOCALIZED.REPLAYSVOTECONFIRM1 .. " " .. replayVote.score .. " " .. TB_MENU_LOCALIZED.REPLAYSVOTECONFIRM2, info)
			local waitOverlay = UIElement:new({
				parent = TBMenu.MenuMain,
				pos = { 0, 0 },
				size = { TBMenu.MenuMain.size.w, TBMenu.MenuMain.size.h },
				interactive = true
			})
			waitOverlay:addMouseHandlers(nil, nil, function(x)
					if (x > WIN_W / 2) then
						voteOverlay:kill()
					end
					waitOverlay:kill()
				end)
		end)
	local waitForVote = UIElement:new({
		parent = voteView,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	waitForVote:addCustomDisplay(true, function()
			if (replayVote.score > 0) then
				voteSubmit:activate()
				voteSubmit.bgColor = { 0, 0, 0, 0.3 }
				waitForVote:kill()
			end
		end)
end

function Replays:showReplayCommentList(listingHolder, toReload, elementHeight, comments)
	local commentElements = {}
	for i, comment in pairs(comments) do
		if (type(i) == "number") then
			local commentTop = UIElement:new({
				parent = listingHolder,
				pos = { 0, #commentElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(commentElements, commentTop)
			local commentUserWithDate = UIElement:new({
				parent = commentTop,
				pos = { 10, 0 },
				size = { commentTop.size.w / 2 - 10, commentTop.size.h }
			})
			commentUserWithDate:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSBY .. " " .. comment.user .. " (" .. comment.date .. ")", nil, nil, nil, LEFTMID, nil, nil, 0.2)
			local ratingWidth = commentTop.size.w / 3 > commentTop.size.h * 6 and commentTop.size.h * 6 or commentTop.size.w / 3
			local commentRating = UIElement:new({
				parent = commentTop,
				pos = { -ratingWidth, 0 },
				size = { ratingWidth, commentTop.size.h }
			})
			Replays:showReplayRating(commentRating, comment.score, 1)
			local comment = textAdapt(comment.comment, FONTS.SMALL, 1, listingHolder.size.w - 30)
			local rows = math.ceil(#comment / 2)
			for i = 1, rows do
				local commentBody = UIElement:new({
					parent = listingHolder,
					pos = { 0, #commentElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				commentBody:addCustomDisplay(true, function() end)
				table.insert(commentElements, commentBody)
				local commentText = UIElement:new({
					parent = commentBody,
					pos = { 10, 0 },
					size = { commentBody.size.w - 20, commentBody.size.h }
				})
				local string = comment[i * 2] and comment[i * 2 - 1] .. " " .. comment[i * 2] or comment[i * 2 - 1]
				commentText:addCustomDisplay(true, function()
						commentText:uiText(string, nil, nil, 1, LEFT)
					end)
			end
			if (i ~= #comments) then
				local separator = UIElement:new({
					parent = listingHolder,
					pos = { 0, #commentElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				local separatorLine = UIElement:new({
					parent = separator,
					pos = { 20, separator.size.h / 2 - 0.5 },
					size = { separator.size.w - 40, 1 },
					bgColor = { 1, 1, 1, 0.2 }
				})
				table.insert(commentElements, separator)
			end
		end
	end

	for i,v in pairs(commentElements) do
		v:hide()
	end

	local commentsScrollBar = TBMenu:spawnScrollBar(listingHolder, #commentElements, elementHeight)
	commentsScrollBar:makeScrollBar(listingHolder, commentElements, toReload)
end

function Replays:showReplayComments(replay)
	TBMenu.CurrentSection:kill(true)
	local commentsView = UIElement:new({
		parent = TBMenu.CurrentSection,
		pos = { 5, 0 },
		size = { TBMenu.CurrentSection.size.w - 10, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local elementHeight = 31
	local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(commentsView, 45, 50, 20)
	TBMenu:addBottomBloodSmudge(botBar, 1)

	local topBarTitle = UIElement:new({
		parent = topBar,
		pos = { 10, 0 },
		size = { topBar.size.w - 20, topBar.size.h }
	})
	topBarTitle:addAdaptedText(true, replay.rplname .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAY .. " " .. replay.uploader, nil, nil, FONTS.BIG, LEFTMID, 0.65)

	local downloadWait = UIElement:new({
		parent = listingHolder,
		pos = { 0, 0 },
		size = { listingHolder.size.w, listingHolder.size.h }
	})
	TBMenu:displayLoadingMark(downloadWait, TB_MENU_LOCALIZED.REPLAYSCOMMENTSDOWNLOADING)
	add_hook("downloader_complete", "communityReplaysComments" .. replay.id, function(filename)
			if (filename:find("system/rplcomments.txt")) then
				Downloader:safeCall(function()
						if (not downloadWait or downloadWait.destroyed) then
							return
						end
						local commentsFile = Files:open("../data/script/system/rplcomments.txt", FILES_MODE_READONLY)
						if (commentsFile.data) then
							local comments = Replays:getReplayComments(commentsFile:readAll())
							commentsFile:close()
							downloadWait:kill()
							topBarTitle:addAdaptedText(true, replay.rplname .. " " .. TB_MENU_LOCALIZED.REPLAYSREPLAY .. " " .. replay.uploader, nil, nil, FONTS.BIG, LEFTMID, 0.65)
							Replays:showReplayCommentList(listingHolder, toReload, elementHeight, comments)
						end
					end)
			end
		end)
	download_replay_comments(replay.id)

	local backButton = UIElement:new({
		parent = botBar,
		pos = { -180, 10 },
		size = { 170, botBar.size.h - 10 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	backButton:addAdaptedText(false, TB_MENU_LOCALIZED.NAVBUTTONBACK)
	backButton:addMouseHandlers(nil, function()
			Replays:showServerReplays()
		end)
	if (replay.uploader:lower() ~= TB_MENU_PLAYER_INFO.username:lower() and replay.uservote == 0) then
		local voteButton = UIElement:new({
			parent = botBar,
			pos = { 10, 10 },
			size = { 170, botBar.size.h - 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		voteButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSADDCOMMENT)
		voteButton:addMouseHandlers(nil, function()
				Replays:showReplayVoteWindow(replay)
			end)
	end
end

function Replays:showServerReplayInfo(replayInfo, replay)
	replayInfo:kill(true)
	TBMenu:addBottomBloodSmudge(replayInfo, 2)

	if (not replay) then
		return
	end

	local replayInfoHolder = UIElement:new({
		parent = replayInfo,
		pos = { 0, 0 },
		size = { replayInfo.size.w, replayInfo.size.h / 8 * 5 }
	})
	local replayName = UIElement:new({
		parent = replayInfoHolder,
		pos = { 10, 0 },
		size = { replayInfoHolder.size.w - 20, replayInfoHolder.size.h / 4 }
	})
	replayName:addAdaptedText(true, replay.rplname, nil, nil, FONTS.BIG, nil, 0.65, nil, 0.2)
	local replayUploader = UIElement:new({
		parent = replayInfoHolder,
		pos = { 10, replayName.shift.y + replayName.size.h },
		size = { replayInfoHolder.size.w - 20, replayInfoHolder.size.h / 16 }
	})
	replayUploader:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSBY .. " " .. replay.uploader, nil, nil, 4, nil, 0.75)
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
		bgColor = { 0, 0, 0, 0 },
		hoverColor = { 0, 0, 0, 0.1 },
		pressedColor = { 1, 1, 1, 0.1 }
	})
	replayRating:addMouseHandlers(nil, function()
			Replays:showReplayVoteWindow(replay)
		end)
	if (replay.uploader:lower() == TB_MENU_PLAYER_INFO.username:lower()) then
		replayRating:deactivate()
	end
	Replays:showReplayRating(replayRating, replay.score, replay.votes, replay.uservote)
	local replayDescription = UIElement:new({
		parent = replayInfoHolder,
		pos = { 10, replayRating.shift.y + replayRating.size.h + 10 },
		size = { replayDate.size.w, replayInfoHolder.size.h / 8 * 3 }
	})
	replayDescription:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSDESC .. ": " .. replay.description, nil, nil, 4, LEFT, 0.65, 0.65)

	local replayDownloadButton = UIElement:new({
		parent = replayInfo,
		pos = { 10, -replayInfo.size.h / 8 * 3 },
		size = { replayInfo.size.w - 20, replayInfo.size.h / 10 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	replayDownloadButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSSAVEREPLAY)
	replayDownloadButton:addMouseHandlers(nil, function()
			download_replay(replay.id, replay.rplname:gsub("%s", "_"))
			Replays:showReplayDownloadPopup(replay.rplname:gsub("%s", "_"))
		end)
	local replayCommentsButton = UIElement:new({
		parent = replayInfo,
		pos = { 10, -replayInfo.size.h / 8 * 2 },
		size = { replayInfo.size.w - 20, replayInfo.size.h / 10 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	replayCommentsButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSVIEWCOMMENTS)
	replayCommentsButton:addMouseHandlers(nil, function()
			Replays:showReplayComments(replay)
		end)

	local findReplaysByUserButton = UIElement:new({
		parent = replayInfo,
		pos = { 10, -replayInfo.size.h / 8 },
		size = { replayInfo.size.w - 20, replayInfo.size.h / 10 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 },
		hoverColor = { 0, 0, 0, 0.3 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	findReplaysByUserButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSMOREBY .. " " .. replay.uploader)
	findReplaysByUserButton:addMouseHandlers(nil, function()
			Replays:getServerReplays(5, 1, replay.uploader)
		end)
end

function Replays:showServerReplays()
	local viewElement = TBMenu.CurrentSection
	viewElement:kill(true)
	TBMenu:showNavigationBar(Replays:getNavigationButtons(true), true)

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

	Replays:showServerReplayList(replaysList, replayInfo)
end

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

	SELECTED_REPLAY = { replay = nil, element = nil, defaultcolor = nil, time = 0 }

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
				Replays:showList(replaysList, replayInfo, SELECTED_FOLDER, TB_MENU_REPLAYS_SEARCH)
			end
		end)
end

function Replays:showCustomReplaySelection(mainElement, mod, action)
	local function showCustomReplayChoice(viewElement)
		local holder = viewElement:addChild({
			shift = { viewElement.size.w / 5, viewElement.size.h / 4 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		local replaysToChooseFrom = {}
		local function checkReplay(v)
			if ((mod == nil or v.mod == mod) and (v.author == TB_MENU_PLAYER_INFO.username or (v.author == 'autosave' and v.bouts[1] == TB_MENU_PLAYER_INFO.username))) then
				if (v.name:find("^" .. REPLAY_EVENT)) then
					v.name = 'Autosaved Replay'
				end
				table.insert(replaysToChooseFrom, { path = v.filename, name = v.name })
			end
		end
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

		local topTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 5 },
			size = { topBar.size.w - 20, topBar.size.h - 10 }
		})
		topTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSSELECTREPLAYTOPROCEED, nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
		local botQuit = botBar:addChild({
			pos = { botBar.size.w / 4, 5 },
			size = { botBar.size.w / 2, botBar.size.h - 10 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 3
		})
		botQuit:addAdaptedText(nil, TB_MENU_LOCALIZED.BUTTONCLOSEWINDOW)
		botQuit:addMouseHandlers(nil, function()
				viewElement:kill()
			end)
		if (#replaysToChooseFrom == 0) then
			listingHolder:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSCOMMUNITYNOFOUND, nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
			return
		end

		local listElements = {}
		for _, v in pairs(replaysToChooseFrom) do
			local replayFile = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, replayFile)
			local replayButton = UIElement:new({
				parent = replayFile,
				pos = { 10, 3 },
				size = { replayFile.size.w - 10, replayFile.size.h - 6 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 3
			})
			local replayText = UIElement:new({
				parent = replayButton,
				pos = { 10, 5 },
				size = { replayButton.size.w - 20, replayButton.size.h - 10 }
			})
			replayText:addAdaptedText(true, v.name .. " (" .. v.path .. ")", nil, nil, 4, LEFTMID)
			replayButton:addMouseHandlers(nil, function()
					viewElement:kill()
					action(v.path)
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
		TBMenu:showStatusMessage("Error loading replay cache: " .. error)
		return
	end

	local customReplayOverlay = UIElement:new({
		parent = mainElement,
		pos = { 0, 0 },
		size = { mainElement.size.w, mainElement.size.h },
		interactive = true,
		bgColor = { 0, 0, 0, 0.1 }
	})
	customReplayOverlay:addMouseHandlers(nil, function()
			customReplayOverlay:kill()
		end)
	customReplayOverlay.killAction = function() REPLAYS_CUSTOM_SELECTOR_ACTIVE = false end
	local customReplayLoading = UIElement:new({
		parent = customReplayOverlay,
		pos = { customReplayOverlay.size.w / 5, customReplayOverlay.size.h / 2 - 70 },
		size = { customReplayOverlay.size.w * 0.6, 140 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	customReplayLoading:addAdaptedText(false, TB_MENU_LOCALIZED.MESSAGEPLEASEWAIT or "Please wait...")
	local waiter = UIElement:new({
		parent = customReplayOverlay,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	waiter:addCustomDisplay(false, function()
			if (Replays.CacheReady) then
				customReplayOverlay:kill(true)
				showCustomReplayChoice(customReplayOverlay)
			end
		end)
	REPLAYS_CUSTOM_SELECTOR_ACTIVE = true
end

---Spawns replay advanced hud progress slider in a specified UIElement
---@param viewElement UIElement
---@return TBMenuSlider
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
	replayProgressTitle:addAdaptedText(true, "Progress")

	local worldstate = get_world_state()
	local replaySpeed = 1
	local updateFunc = rewind_replay_to_frame
	local onMouseDn = function()
		replaySpeed = get_replay_speed()
		set_replay_speed(0)
	end
	local onMouseUp = function()
		set_replay_speed(replaySpeed)
	end

	local slider = TBMenu:spawnSlider2(replayProgressHolder,
		{ x = 15, y = 25, h = replayProgressHolder.size.h - 25},
		worldstate.match_frame, {
			sliderRadius = 20,
			textWidth = 30,
			maxValue = worldstate.game_frame + 98,
			minValue = 0
		}, updateFunc, onMouseDn, onMouseUp)
	slider.bgColor = table.clone(UICOLORWHITE)
	slider.value = worldstate.match_frame

	replayProgressHolder:addCustomDisplay(nil, function()
			local worldstate = get_world_state()
			if (slider.settings.maxValue ~= worldstate.game_frame + 98) then
				Replays:spawnReplayAdvancedGui(true)
				return
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
	-- A bit useless now, we can't control them and it only shits up the timeline
	--[[local keyframes = get_camera_keyframes()
	for i = 1, #keyframes do
		local kf = keyframes[i]
		local keyframeButton = UIElement:new({
			parent = slider.parent,
			pos = { -slider.parent.size.w / (worldstate.game_frame + 99) * (worldstate.game_frame + 99 - kf.frame) - 5, slider.parent.size.h / 2 - 5 },
			size = { 10, 10 },
			bgImage = "../textures/menu/general/buttons/square45.tga"
		})
	end
	local afterFrames = UIElement:new({
		parent = slider.parent,
		pos = { -slider.parent.size.w / (worldstate.game_frame + 99) * 99, slider.parent.size.h / 2 - 3 },
		size = { slider.parent.size.w / (worldstate.game_frame + 99) * 99, 6 },
		bgColor = { 1, 1, 1, 0.8 },
		shapeType = ROUNDED,
		rounded = 6
	})]]
	--slider:reload()

	return slider
end

---Spawns replay advanced hud speed slider in a specified UIElement
---@param viewElement UIElement
---@return TBMenuSlider
function Replays:spawnReplaySpeedSlider(viewElement)
	local replaySpeedHolder = viewElement:addChild({
		bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
		shapeType = ROUNDED,
		rounded = 4
	})
	local replaySpeedTitle = UIElement:new({
		parent = replaySpeedHolder,
		pos = { 15, 3 },
		size = { replaySpeedHolder.size.w - 30, 25 }
	})
	replaySpeedTitle:addAdaptedText(true, "Speed")
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

			unfreeze_game()
			set_replay_speed(speed)
		end

		local speedDn = replaySpeedTitle:addChild({
			pos = { (replaySpeedTitle.size.w - textWidth) / 2 - 25, 0 },
			size = { 25, 25 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS,
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
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_TRANS,
			interactive = true,
			shapeType = ROUNDED,
			rounded = 3
		})
		speedUp:addChild({ shift = { 5, 11 }, bgColor = TB_MENU_DEFAULT_LIGHTEST_COLOR }, true)
		speedUp:addChild({ shift = { 11, 5 }, bgColor = TB_MENU_DEFAULT_LIGHTEST_COLOR }, true)
		speedUp:addMouseHandlers(nil, function() setButtonSpeed(1) end)

		speedDn:addCustomDisplay(nil, function()
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

	local sliderSettings = {
		maxValue = 2,
		minValue = -1,
		maxValueDisp = 4,
		minValueDisp = -1.5,
		decimal = 2
	}

	local getSliderSpeed = function(val)
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
				val = val / 75 * 100
			end
		end
		if (val > -0.01 and val < 0) then
			-- Ensure we don't get -0 speed, that looks wack
			val = 0
		end
		return val
	end
	local getSliderSpeedPercentage = function(val)
		--[[ Some maths:
			-1.5 to -1 is 8.3%
			-1 to 0 is 25%
			0 to 1 is 33.3%
			1 to 2 is 16.6%
			2 to 4 is 16.6%
		]]
		if (val < -1.5) then
			return 0
		elseif (val < -1) then
			return 0.083 * (val + 1.5) * 2
		elseif (val < 0) then
			return 0.083 + 0.25 * (val + 1)
		elseif (val <= 1) then
			return 0.333 + 0.333 * val
		elseif (val < 2) then
			return 0.666 + 0.166 * (val - 1)
		elseif (val < 4) then
			return 0.833 + 0.167 * (val - 2) / 2
		end
		return 1
	end

	local updateFunc = function(val, xPos, slider)
		local multiplyBy = tonumber('1' .. string.rep('0', slider.settings.decimal))
		val = getSliderSpeed(val)

		if (math.abs(val) > 1) then
			multiplyBy = multiplyBy / 10
		elseif (math.abs(val) > 2) then
			multiplyBy = 1
		end

		local targetVal = val < 0 and math.ceil(val * multiplyBy) / multiplyBy or math.floor(val * multiplyBy) / multiplyBy
		slider.child[1].labelText[1] = targetVal .. ''

		unfreeze_game()
		set_replay_speed(targetVal)
	end

	local slider = TBMenu:spawnSlider(replaySpeedHolder, 15, 25, nil, replaySpeedHolder.size.h - 25, 30, 20, get_replay_speed(), sliderSettings, updateFunc)
	slider.bgColor = UICOLORWHITE

	local regularSpeed = UIElement:new({
		parent = slider.parent,
		pos = { slider.parent.size.w / 3 + 3, slider.parent.size.h / 2 - 3 },
		size = { slider.parent.size.w / 3 - 6, 6 },
		bgColor = { 1, 1, 1, 0.75 }
	})
	local speedMarks = UIElement:new({
		parent = slider.parent,
		pos = { slider.size.w / 2, slider.parent.size.h / 2 - 13 },
		size = { slider.parent.size.w - slider.size.w, 26 },
		bgColor = { 1, 1, 1, 0.75 },
	})
	speedMarks:addCustomDisplay(true, function()
			set_color(unpack(speedMarks.bgColor))
			-- -1 speed
			local clock = os.clock_real()
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

	replaySpeedHolder:addCustomDisplay(nil, function()
			local replay_speed = get_replay_speed()
			if (slider.value ~= replay_speed) then
				if (slider.hoverState ~= BTN_NONE or slider.parent.hoverState == BTN_DN) then
					return
				end
				local perc = getSliderSpeedPercentage(replay_speed)
				slider:moveTo(perc * (slider.parent.size.w - slider.size.w))
				slider.value = replay_speed
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
---@field hasCache boolean Last replay cache state

---Spawns advanced replay UI
---@param reload ?boolean
---@return ReplayHud
function Replays:spawnReplayAdvancedGui(reload)
	---@type ReplayHud
	local replayGuiHolder
	local posX = is_mobile() and TBHud.DefaultButtonSize * 2.5 or math.max(65 * TB_MENU_GLOBAL_SCALE, WIN_W * 0.15 - 65 * TB_MENU_GLOBAL_SCALE)
	local size = { math.min(1600, WIN_W - posX * 2), 65 * TB_MENU_GLOBAL_SCALE }
	posX = (WIN_W - size[1]) / 2

	local _, safe_y, _, safe_h = get_window_safe_size()
	safe_y = math.max(safe_y, WIN_H - safe_h - safe_y)
	local targetHeightShift = size[2] + math.max(safe_y, 35)

	if (reload) then
		REPLAY_GUI:kill(true)
		replayGuiHolder = REPLAY_GUI
		replayGuiHolder.size.w = size[1]
	else
		---@type ReplayHud
		---@diagnostic disable-next-line: assign-type-mismatch
		replayGuiHolder = UIElement:new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { posX, WIN_H },
			size = { size[1], size[2] }
		})
		replayGuiHolder.hidden = false
		replayGuiHolder.toggleClock = UIElement.clock
		replayGuiHolder.hasCache = get_replay_cache() > 0
		replayGuiHolder:addCustomDisplay(true, function()
				if (not REPLAY_GUI) then
					return
				end
				local ws = get_world_state()

				if (ws.replay_mode ~= 0) then
					local cacheState = get_replay_cache() > 0
					if (REPLAY_GUI.hasCache ~= cacheState) then
						REPLAY_GUI.hasCache = cacheState
						Replays:spawnReplayAdvancedGui(true)
					end
				end

				if (ws.replay_mode == 0) then
					REPLAY_GUI.hidden = true
				end
				if (REPLAY_GUI.prevReplay:isDisplayed()) then
					if (ws.game_type == 1) then
						REPLAY_GUI.prevReplay:hide(true)
						REPLAY_GUI.nextReplay:hide(true)
					end
				elseif (ws.game_type == 0) then
					REPLAY_GUI.prevReplay:show(true)
					REPLAY_GUI.nextReplay:show(true)
				end
				if (replayGuiHolder.hidden) then
					if (replayGuiHolder.pos.y < WIN_H) then
						replayGuiHolder:moveTo(nil, UITween.SineTween(replayGuiHolder.pos.y, WIN_H, UIElement.clock - replayGuiHolder.toggleClock))
					else
						replayGuiHolder:hide()
					end
				else
					if (replayGuiHolder.pos.y > WIN_H - targetHeightShift) then
						replayGuiHolder:moveTo(nil, UITween.SineTween(replayGuiHolder.pos.y, WIN_H - 115, UIElement.clock - replayGuiHolder.toggleClock))
					end
				end
			end)
	end

	local prevReplay = replayGuiHolder:addChild({
		pos = { 0, 0 },
		size = { replayGuiHolder.size.h / 3 * 2, replayGuiHolder.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	prevReplay:addChild({
		shift = { prevReplay.size.w / 6, 0 },
		bgImage = "../textures/menu/general/buttons/arrowleft.tga"
	})
	prevReplay:addMouseHandlers(nil, function() play_prev_replay() end)
	local prevPopup = TBMenu:displayPopup(prevReplay, TB_MENU_LOCALIZED.REPLAYHUDPREVREPLAY)
	prevPopup:moveTo(-(prevReplay.size.w + prevPopup.size.w) / 2, prevReplay.size.h + 2)
	replayGuiHolder.prevReplay = prevReplay

	local nextReplay = replayGuiHolder:addChild({
		pos = { -prevReplay.size.w, 0 },
		size = { prevReplay.size.w, replayGuiHolder.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	nextReplay:addChild({
		shift = { nextReplay.size.w / 6, 0 },
		bgImage = "../textures/menu/general/buttons/arrowright.tga"
	})
	nextReplay:addMouseHandlers(nil, function() play_next_replay() end)
	local nextPopup = TBMenu:displayPopup(nextReplay, TB_MENU_LOCALIZED.REPLAYHUDNEXTREPLAY)
	nextPopup:moveTo(-(nextReplay.size.w + nextPopup.size.w) / 2, nextReplay.size.h + 2)
	replayGuiHolder.nextReplay = nextReplay

	local slidersHolder = replayGuiHolder:addChild({ shift = { prevReplay.size.w + 10, 0 }})
	if (not replayGuiHolder.hasCache) then
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

	return replayGuiHolder
end
