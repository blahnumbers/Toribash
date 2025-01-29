require("system.menu_manager")

if (News == nil) then
	---@class NewsItemData : MenuSectionButton
	---@field id integer
	---@field hasMiniImage boolean
	---@field isEvent boolean
	---@field eventid integer
	---@field isBattlePass boolean
	---@field featured boolean
	---@field isRead boolean
	---@field withUrlAuth boolean

	---**Toribash News manager class**
	---
	---**Version 5.70**
	---* Added `HookName` field
	---
	---**Version 5.65**
	---* Added `withUrlAuth` NewsItemData param to force open URLs in main browser on mobile devices
	---
	---**Version 5.60:**
	---* News config to display unread news to user
	---* Deprecated initAction for news items
	---* Deprecated small images for news items
	---* Added documentation with EmmyLua annotations
	---@class News
	---@field Cache NewsItemData[]
	---@field DownloadQueue string[]
	---@field HasUnreadNews boolean
	News = {
		Cache = {},
		DownloadQueue = {},
		HasUnreadNews = false,
		LastRefresh = -1000000,
		HookName = "__tbNewsManager",
		ver = 5.70
	}
	News.__index = News
end

---Returns a predefined set of default news to show to user
---@return NewsItemData[]
function News:getDefaultNews()
	return {
		{
			title = "Welcome to Toribash " .. TORIBASH_VERSION .. "!",
			subtitle = "",
			ratio = 0.5,
			image = "../textures/menu/promo/toribash.tga",
			action = function() open_url("https://forum.toribash.com/forumdisplay.php?f=35") end,
			disableUnload = true,
			isRead = true
		},
		{
			title = "Toribash Events",
			subtitle = "Go online to participate in Toribash events",
			ratio = 0.66,
			featured = true,
			image = "../textures/menu/promo/noevents-placeholder.tga",
			action = function() open_url("https://forum.toribash.com/forumdisplay.php?f=37") end,
			disableUnload = true,
			isRead = true
		}
	}
end

---Adds a news promo image to the download queue
---@param imageName string
function News:addToQueue(imageName)
	for _, v in pairs(self.DownloadQueue) do
		if (v == imageName) then
			return
		end
	end
	table.insert(self.DownloadQueue, imageName)
end

---Removes a news promo image from the download queue
---@param imageName string
function News:removeFromQueue(imageName)
	for i, v in pairs(self.DownloadQueue) do
		if (imageName:find(".*/" .. v .. "$")) then
			table.remove(self.DownloadQueue, i)
			return
		end
	end
end

---Parses news config file
function News.LoadConfig()
	local file = Files.Open("../data/news.cfg")
	if (not file.data) then
		return
	end
	local lines = file:readAll()
	file:close()

	for _, ln in pairs(lines) do
		if (ln:find("^NEWSID")) then
			local sid = ln:gsub("NEWSID (%d+);.*", "%1")
			local isread = ln:gsub(".*;(%d+)$", "%1")
			local id = tonumber(sid)
			if (id ~= nil and isread == "1") then
				for _, v in pairs(News.Cache) do
					if (v.id == id) then
						v.isRead = true
					end
				end
			end
		end
	end
end

---Updates config with current news data
function News.UpdateConfig()
	local file = Files.Open("../data/news.cfg", FILES_MODE_WRITE)
	if (not file.data) then
		return
	end

	local lastUnreadState = News.HasUnreadNews
	News.HasUnreadNews = false
	for _, v in pairs(News.Cache) do
		if (v.isRead) then
			file:writeLine("NEWSID " .. tostring(v.id) .. ";1")
		else
			News.HasUnreadNews = true
		end
	end
	file:close()

	if (lastUnreadState ~= News.HasUnreadNews) then
		TBMenu:reloadNavigationIfNeeded()
	end
end

---Parses News data file and caches it in **News.Cache**.\
---If datafile is still downloading, returns the corresponding `File` object.
---@param reload ?boolean
---@return File?
function News:getNews(reload)
	if (not (table.empty(self.Cache) or reload)) then
		return
	end

	local file = Files.Open("../data/news.txt")
	if (not file.data) then
		self.Cache = News:getDefaultNews()
		if (file:isDownloading()) then
			return file
		end
		return
	end
	local lines = file:readAll()
	file:close()

	---@type NewsItemData[]
	local newsData = {}
	for _, ln in pairs(lines) do
		local ln = ln:gsub("\r?\n?", '')
		if (ln:find("^NEWSID")) then
			table.insert(newsData, { ratio = 0.5, disableUnload = true, id = ln:gsub("%D", "") })
			newsData[#newsData].id = tonumber(newsData[#newsData].id) or #newsData
			newsData[#newsData].isRead = math.max(newsData[#newsData].id, #newsData) < 10
		elseif (ln:find("^TITLE 0;")) then
			newsData[#newsData].title = ln:gsub("^TITLE 0;", "")
		elseif (ln:find("^SUBTITLE 0;")) then
			newsData[#newsData].subtitle = ln:gsub("^SUBTITLE 0;", "")
		--[[elseif (ln:find("^IMAGESMALL 0;")) then
			local imageName = ln:gsub("^IMAGESMALL 0;", "")
			newsData[#newsData].image2 = { "../textures/menu/promo/" .. imageName, "../textures/menu/promo/toribashsmall.tga" }
			newsData[#newsData].ratio2 = 1
			newsData[#newsData].hasMiniImage = true

			local imageFile = Files.Open("../data/textures/menu/promo/" .. imageName)
			if (not imageFile.data) then
				News:addToQueue(imageName)
				Request:queue(function() download_server_file("get_event_image&name=" .. imageName, 0) end, "newsDownload" .. #newsData)
			end
			imageFile:close()]]
		elseif (ln:find("^IMAGE 0;")) then
			local imageName = ln:gsub("^IMAGE 0;", "")
			newsData[#newsData].image = { "../textures/menu/promo/" .. imageName, newsData[#newsData].featured and "../textures/menu/promo/noevents-placeholder.tga" or "../textures/menu/promo/toribash.tga" }

			local imageFile = Files.Open("../data/textures/menu/promo/" .. imageName)
			if (not imageFile.data) then
				News:addToQueue(imageName)
				Request:queue(function() download_server_file("get_event_image&name=" .. imageName, 0) end, "newsDownload" .. #newsData)
			end
			imageFile:close()
		elseif (ln:find("^URL 0;")) then
			newsData[#newsData].action = function() open_url(ln:gsub("^URL 0;", ""), newsData[#newsData].withUrlAuth) end
		elseif (ln:find("^URLNOAUTH 0;")) then
			newsData[#newsData].withUrlAuth = false
		elseif (ln:find("^STORE 0;")) then
			local itemid = ln:gsub("^STORE 0;", "") + 0
			newsData[#newsData].action = function() Store:showStoreSection(TBMenu.CurrentSection, nil, nil, itemid) end
		elseif (ln:find("^EVENT 0;")) then
			local eventid = ln:gsub("^EVENT 0;", "") + 0
			newsData[#newsData].isEvent = true
			newsData[#newsData].action = function() Events:showEventInfo(eventid) end
			newsData[#newsData].eventid = eventid
		elseif (ln:find("^MODCHAMPIONSHIP 0;")) then
			local eventid = newsData[#newsData].eventid
			newsData[#newsData].isEvent = true
			newsData[#newsData].action = function() Events:loadModChampionship(TBMenu.CurrentSection, eventid) end
		elseif (ln:find("^BLINDFIGHT 0;")) then
			newsData[#newsData].isEvent = true
			newsData[#newsData].action = function() Events:showBlindFight() end
		--[[elseif (ln:find("^MOVEMBER 0;")) then
			newsData[#newsData].action = function() Events:loadMovember(TBMenu.CurrentSection) end]]
		elseif (ln:find("^BATTLEPASS 0;")) then
			newsData[#newsData].isBattlePass = true
			newsData[#newsData].action = function()
				TB_LAST_MENU_SCREEN_OPEN = 11
				TBMenu:clearNavSection()
				TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
				TBMenu:showNavigationBar()
			end
		--[[elseif (ln:find("^COLLECTORCARDS %d+;")) then
			local id = ln:gsub("^COLLECTORCARDS (%d+);", "%1") + 0
			newsData[#newsData].action = function() Torishop:showCollectorsCards(id) end]]
		elseif (ln:find("^FEATURED 0;")) then
			newsData[#newsData].featured = true
			if (newsData[#newsData].image) then
				newsData[#newsData].image[2] = "../textures/menu/promo/noevents-placeholder.tga"
			end
			newsData[#newsData].ratio = 0.66
		end
		if (ln:find("^EVENTID")) then
			break
		end
	end

	local defaultNews = self:getDefaultNews()
	if (TB_MENU_PLAYER_INFO.username == '') then
		for i = #newsData, 1, -1 do
			if (newsData[i].featured) then
				table.remove(newsData, i)
			end
		end
		table.insert(newsData, defaultNews[2])
	end
	if (TB_MENU_PLAYER_INFO.data.qi < BattlePass.QiRequirement) then
		local newsItems = 0
		for i = #newsData, 1, -1 do
			if (newsData[i].isBattlePass) then
				table.remove(newsData, i)
			elseif (not newsData[i].featured) then
				newsItems = newsItems + 1
			end
		end
		if (newsItems == 0) then
			table.insert(newsData, defaultNews[1])
		end
	end

	self.Cache = newsData
	self.LoadConfig()

	self.HasUnreadNews = false
	for _, v in pairs(self.Cache) do
		if (not v.isRead) then
			self.HasUnreadNews = true
			break
		end
	end

	TBMenu:reloadNavigationIfNeeded()
end

---@class NewsEventPrizeBit
---@field info string
---@field imagetitle string
---@field tc integer
---@field st integer
---@field bpxp integer
---@field itemids integer[]

---@class NewsEventInfoBit
---@field title string
---@field imagetitle string
---@field desc string

---@class NewsEventItemData
---@field uiColor Color
---@field accentColor Color
---@field buttonHoverColor Color
---@field buttonPressedColor Color
---@field overlaytransparency number
---@field name string
---@field image string
---@field forumlink string
---@field eventid string
---@field requireMod boolean
---@field actionText string
---@field action function
---@field data NewsEventInfoBit[]
---@field prizes NewsEventPrizeBit[]

---Parses news datafile and returns the events data
---@return NewsEventItemData[]
function News:getEvents()
	local file = Files.Open("../data/news.txt")
	if (not file.data) then
		return {}
	end
	local lines = file:readAll()
	file:close()

	---@type NewsEventItemData[]
	local eventData = {}
	local currentID = 1
	for _, ln in pairs(lines) do
		local ln = ln:gsub("\r?\n?", '')
		if (ln:find("^EVENTID")) then
			local tempId = ln:gsub("%D", "")
			currentID = tonumber(tempId) or 0
			eventData[currentID] = {
				uiColor = table.clone(UICOLORWHITE),
				accentColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
				buttonHoverColor = table.clone(TB_MENU_DEFAULT_DARKER_COLOR),
				buttonPressedColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR),
				overlaytransparency = 0
			}
		elseif (#eventData > 0) then
			local evt = eventData[currentID]
			if (ln:find("^NAME 0;")) then
				evt.name = ln:gsub("^NAME 0;", "")
			elseif (ln:find("^IMAGE 0;")) then
				evt.image = "../textures/menu/promo/events/" .. ln:gsub("^IMAGE 0;", "")
			elseif (ln:find("^URL 0;")) then
				evt.forumlink = ln:gsub("URL 0;", "")
			elseif (ln:find("^PLAYNAME 0;")) then
				evt.eventid = ln:gsub("^PLAYNAME 0;", '')
				evt.action = function() EventsOnline:playEvent(evt.eventid) end
			elseif (ln:find("^PLAYTEXT 0;")) then
				evt.actionText = TB_MENU_LOCALIZED[ln:gsub("^PLAYTEXT 0;", "")] or ln:gsub("^PLAYTEXT 0;", "")
			elseif (ln:find("^REQUIREMOD 0;")) then
				evt.requireMod = true
			elseif (ln:find("^OVERLAYTRANS 0;")) then
				local trans = ln:gsub("^OVERLAYTRANS 0;", "")
				evt.overlaytransparency = tonumber(trans) or 0
			elseif (ln:find("^ACCENTCOLOR 0;")) then
				local color = ln:gsub("^ACCENTCOLOR 0;", "")
				evt.accentColor = get_color_from_hex(color)
			elseif (ln:find("^UICOLOR 0;")) then
				local color = ln:gsub("^UICOLOR 0;", "")
				evt.uiColor = get_color_from_hex(color)
			elseif (ln:find("^BTNHVRCOL 0;")) then
				local color = ln:gsub("^BTNHVRCOL 0;", "")
				evt.buttonHoverColor = get_color_from_hex(color)
			elseif (ln:find("^BTNDNCOL 0;")) then
				local color = ln:gsub("^BTNDNCOL 0;", "")
				evt.buttonPressedColor = get_color_from_hex(color)
			elseif (ln:find("^DESCDATA 0;")) then
				evt.data = evt.data or {}
				local ln = ln:gsub("^DESCDATA 0;", "")
				local id = tonumber(ln:sub(1, 1)) or 0
				evt.data[id] = { title = ln:sub(2) }
			elseif (ln:find("^DESCDATAIMGTITLE 0;")) then
				local ln = ln:gsub("^DESCDATAIMGTITLE 0;", "")
				local id = tonumber(ln:sub(1, 1)) or 0
				local imgtitle = ln:sub(2)
				local file = Files.Open("../data/textures/menu/promo/events/" .. imgtitle)
				if (file.data) then
					evt.data[id].imagetitle = "../textures/menu/promo/events/" .. imgtitle
					file:close()
				end
			elseif (ln:find("^DESCDATATEXT 0;")) then
				local ln = ln:gsub("^DESCDATATEXT 0;", "")
				local id = tonumber(ln:sub(1, 1)) or 0
				local text = ln:sub(2)
				evt.data[id].desc = text
			elseif (ln:find("^PRIZEDATA 0;")) then
				evt.prizes = evt.prizes or {}
				local ln = ln:gsub("^PRIZEDATA 0;", "")
				local id = tonumber(ln:sub(1, 1)) or 0
				evt.prizes[id] = { info = ln:sub(2) }
			--[[elseif (ln:find("^PRIZEIMG 0;")) then
				evt.prizes = evt.prizes or {}
				local imgtitle = ln:gsub("^PRIZEIMG 0;", "")
				local file = Files.Open("../data/textures/menu/promo/events/" .. imgtitle)
				if (file.data) then
					evt.prizes.imagetitle = "../textures/menu/promo/events/" .. imgtitle
					file:close()
				end]]
			elseif (ln:find("^PRIZETC 0;")) then
				local ln = ln:gsub("^PRIZETC 0;", "")
				local id = tonumber(ln:sub(1, 1)) or 0
				local tc = tonumber(ln:sub(2)) or 0
				evt.prizes[id].tc = tc
			elseif (ln:find("^PRIZEST 0;")) then
				local ln = ln:gsub("^PRIZEST 0;", "")
				local id = tonumber(ln:sub(1, 1)) or 0
				local st = tonumber(ln:sub(2)) or 0
				evt.prizes[id].st = st
			elseif (ln:find("^PRIZEBPXP 0;")) then
				local ln = ln:gsub("^PRIZEBPXP 0;", "")
				local id = tonumber(ln:sub(1, 1)) or 0
				local xp = tonumber(ln:sub(2)) or 0
				evt.prizes[id].bpxp = xp
			elseif (ln:find("^PRIZEITEMS 0;")) then
				local ln = ln:gsub("^PRIZEITEMS 0;", "")
				local id = tonumber(ln:sub(1, 1)) or 0
				local cnt = tonumber(ln:sub(2, 2)) or 0
				local items = ln:sub(3)
				evt.prizes[id].itemids = { items:match(("(%d+) ?"):rep(cnt)) }
			end
		end
	end
	return eventData
end

add_hook("downloader_complete", News.HookName, function(filename)
		if (filename:find("data/news.txt")) then
			Downloader.SafeCall(function()
					News:getNews(true)
				end)
		else
			News:removeFromQueue(filename)
		end
	end)
