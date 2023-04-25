-- News manager class

NEWS_DOWNLOAD_QUEUE = NEWS_DOWNLOAD_QUEUE or {}

do
	News = {}
	News.__index = News
	local cln = {}
	setmetatable(cln, News)

	function News:getDefaultNews()
		return {
			{
				title = "Welcome to Toribash " .. TORIBASH_VERSION .. "!",
				subtitle = "",
				ratio = 0.5,
				image = "../textures/menu/promo/toribash.tga",
				action = function() end,
				disableUnload = true
			},
			{
				title = "Toribash Events",
				subtitle = "Go online to participate in Toribash events",
				ratio = 0.66,
				featured = true,
				image = "../textures/menu/promo/noevents-placeholder.tga",
				action = function() end,
				disableUnload = true
			}
		}
	end

	function News:addToQueue(imageName)
		for i,v in pairs(NEWS_DOWNLOAD_QUEUE) do
			if (v == imageName) then
				return
			end
		end
		table.insert(NEWS_DOWNLOAD_QUEUE, imageName)
	end

	function News:removeFromQueue(imageName)
		for i,v in pairs(NEWS_DOWNLOAD_QUEUE) do
			if (imageName:find(".*/" .. v .. "$")) then
				table.remove(NEWS_DOWNLOAD_QUEUE, i)
				return
			end
		end
	end

	---@class NewsItemData : MenuSectionButton
	---@field hasMiniImage boolean
	---@field initAction function
	---@field isEvent boolean
	---@field eventid integer
	---@field isBattlePass boolean
	---@field featured boolean

	function News:getNews(miniImages)
		local file = Files.Open("../data/news.txt")
		if (not file.data) then
			local news = News:getDefaultNews()
			if (file:isDownloading()) then
				news.downloading = true
				news.file = file
			end
			return news
		end
		local lines = file:readAll()
		file:close()

		---@type NewsItemData[]
		local newsData = {}
		for _, ln in pairs(lines) do
			local ln = ln:gsub("\r?\n?", '')
			if (ln:find("^NEWSID")) then
				table.insert(newsData, { ratio = 0.5, disableUnload = true })
			elseif (ln:find("^TITLE 0;")) then
				newsData[#newsData].title = ln:gsub("^TITLE 0;", "")
			elseif (ln:find("^SUBTITLE 0;")) then
				newsData[#newsData].subtitle = ln:gsub("^SUBTITLE 0;", "")
			elseif (ln:find("^IMAGESMALL 0;") and miniImages) then
				local imageName = ln:gsub("^IMAGESMALL 0;", "")
				newsData[#newsData].image = { "../textures/menu/promo/" .. imageName, "../textures/menu/promo/toribashsmall.tga" }
				newsData[#newsData].ratio = 1
				newsData[#newsData].hasMiniImage = true

				local imageFile = Files.Open("../data/textures/menu/promo/" .. imageName)
				if (not imageFile.data) then
					News:addToQueue(imageName)
					Request:queue(function() download_server_file("get_event_image&name=" .. imageName, 0) end, "newsDownload" .. #newsData)
				end
				imageFile:close()
			elseif (ln:find("^IMAGE 0;")) then
				local imageName = ln:gsub("^IMAGE 0;", "")
				if (newsData[#newsData].image) then
					newsData[#newsData].image2 = { "../textures/menu/promo/" .. imageName, "../textures/menu/promo/toribash.tga" }
					newsData[#newsData].ratio2 = 0.5
				else
					newsData[#newsData].image = { "../textures/menu/promo/" .. imageName, "../textures/menu/promo/toribash.tga" }
				end

				local imageFile = Files.Open("../data/textures/menu/promo/" .. imageName)
				if (not imageFile.data) then
					News:addToQueue(imageName)
					Request:queue(function() download_server_file("get_event_image&name=" .. imageName, 0) end, "newsDownload" .. #newsData)
				end
				imageFile:close()
			elseif (ln:find("^URL 0;")) then
				newsData[#newsData].action = function() open_url(ln:gsub("^URL 0;", "")) end
			elseif (ln:find("^STORE 0;")) then
				local itemid = ln:gsub("^STORE 0;", "") + 0
				newsData[#newsData].action = function() Torishop:showStoreSection(TBMenu.CurrentSection, nil, nil, itemid) end
				newsData[#newsData].initAction = function() Torishop:showStoreSection(TBMenu.CurrentSection, nil, nil, itemid) end
			elseif (ln:find("^EVENT 0;")) then
				local eventid = ln:gsub("^EVENT 0;", "") + 0
				newsData[#newsData].isEvent = true
				newsData[#newsData].action = function() Events:showEventInfo(eventid) end
				newsData[#newsData].initAction = function() Events:showEventInfo(eventid) end
				newsData[#newsData].eventid = eventid
			elseif (ln:find("^MODCHAMPIONSHIP 0;")) then
				local eventid = newsData[#newsData].eventid
				newsData[#newsData].isEvent = true
				newsData[#newsData].action = function() Events:loadModChampionship(TBMenu.CurrentSection, eventid) end
				newsData[#newsData].initAction = function() Events:loadModChampionship(TBMenu.CurrentSection, eventid) end
			elseif (ln:find("^MOVEMBER 0;")) then
				newsData[#newsData].action = function() Events:loadMovember(TBMenu.CurrentSection) end
				newsData[#newsData].initAction = function() Events:loadMovember(TBMenu.CurrentSection) end
			elseif (ln:find("^BATTLEPASS 0;")) then
				newsData[#newsData].isBattlePass = true
				newsData[#newsData].action = function()
					TB_LAST_MENU_SCREEN_OPEN = 11
					TBMenu:clearNavSection()
					TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
					TBMenu:showNavigationBar()
				end
				newsData[#newsData].initAction = newsData[#newsData].action
			elseif (ln:find("^COLLECTORCARDS %d+;")) then
				local id = ln:gsub("^COLLECTORCARDS (%d+);", "%1") + 0
				newsData[#newsData].action = function() Torishop:showCollectorsCards(id) end
				newsData[#newsData].initAction = function() Torishop:showCollectorsCards(id) end
			elseif (ln:find("^FEATURED 0;")) then
				newsData[#newsData].featured = true
				if (miniImages and newsData[#newsData].hasMiniImage) then
					newsData[#newsData].ratio2 = 0.66
				else
					newsData[#newsData].ratio = 0.66
				end
			end
			if (ln:find("^EVENTID")) then
				break
			end
		end
		return newsData
	end

	function News:getEvents()
		local file = Files.Open("../data/news.txt")
		if (not file.data) then
			return {}
		end
		local lines = file:readAll()
		file:close()

		local eventData = {}
		local currentID = 1
		for i,ln in pairs(lines) do
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
					evt.overlaytransparency = tonumber(trans)
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
				elseif (ln:find("^PRIZEIMG 0;")) then
					evt.prizes = evt.prizes or {}
					local imgtitle = ln:gsub("^PRIZEIMG 0;", "")
					local file = Files.Open("../data/textures/menu/promo/events/" .. imgtitle)
					if (file.data) then
						evt.prizes.imagetitle = "../textures/menu/promo/events/" .. imgtitle
						file:close()
					end
				elseif (ln:find("^PRIZETC 0;")) then
					local ln = ln:gsub("^PRIZETC 0;", "")
					local id = tonumber(ln:sub(1, 1)) or 0
					local tc = tonumber(ln:sub(2))
					evt.prizes[id].tc = tc
				elseif (ln:find("^PRIZEST 0;")) then
					local ln = ln:gsub("^PRIZEST 0;", "")
					local id = tonumber(ln:sub(1, 1)) or 0
					local st = tonumber(ln:sub(2))
					evt.prizes[id].st = st
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
end

add_hook("downloader_complete", "news_manager_downloader", function(name)
		News:removeFromQueue(name)
	end)
