-- News manager class

do
	News = {}
	News.__index = News
	local cln = {}
	setmetatable(cln, News)
	
	function News:getDefaultNews()
		return {
			{
				title = "Wooo weee",
				subtitle = "Wowzers!",
				ratio = 0.5,
				image = "../textures/menu/promo/golem.tga",
				action = function() end
			},
			{
				title = "azzz",
				subtitle = "test",
				ratio = 0.66,
				featured = true,
				image = "../textures/menu/promo/holeinthewall.tga",
				action = function() end
			}
		}
	end
	
	function News:getNews()
		local file = Files:new("../data/news.txt")
		if (not file.data) then
			return News:getDefaultNews()
		end
		local lines = file:readAll()
		file:close()
		
		local newsData = {}
		for i,ln in pairs(lines) do
			local ln = ln:gsub("\r?\n?", '')
			if (ln:find("^NEWSID")) then
				table.insert(newsData, { ratio = 0.5 })
			elseif (ln:find("^TITLE 0;")) then
				newsData[#newsData].title = ln:gsub("^TITLE 0;", "")
			elseif (ln:find("^SUBTITLE 0;")) then
				newsData[#newsData].subtitle = ln:gsub("^SUBTITLE 0;", "")
			elseif (ln:find("^IMAGE 0;")) then
				newsData[#newsData].image = "../textures/menu/promo/" .. ln:gsub("^IMAGE 0;", "")
			elseif (ln:find("^URL 0;")) then
				newsData[#newsData].action = function() open_url(ln:gsub("^URL 0;", "")) end
			elseif (ln:find("^EVENT 0;")) then
				local eventid = ln:gsub("^EVENT 0;", "") + 0
				newsData[#newsData].action = function() Events:showEventInfo(eventid) end
				newsData[#newsData].initAction = function() Events:showEventInfo(eventid) end
			elseif (ln:find("^FEATURED 0;")) then
				newsData[#newsData].featured = true
				newsData[#newsData].ratio = 0.66
			end
			if (ln:find("^EVENTID")) then
				break
			end
		end
		return newsData
	end
	
	function News:getEvents()
		local file = Files:new("../data/news.txt")
		if (not file.data) then
			return false
		end
		local lines = file:readAll()
		file:close()
		
		local eventData = {}
		for i,ln in pairs(lines) do
			local ln = ln:gsub("\r?\n?", '')
			if (ln:find("^EVENTID")) then
				table.insert(eventData, {
					uiColor = cloneTable(UICOLORWHITE),
					accentColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR),
					buttonHoverColor = cloneTable(TB_MENU_DEFAULT_DARKER_COLOR),
					buttonPressedColor = cloneTable(TB_MENU_DEFAULT_DARKEST_COLOR),
					overlaytransparency = 0
				})
			elseif (#eventData > 0) then
				local evt = eventData[#eventData]
				if (ln:find("^NAME 0;")) then
					evt.name = ln:gsub("^NAME 0;", "")
				elseif (ln:find("^IMAGE 0;")) then
					evt.image = "../textures/menu/promo/events/" .. ln:gsub("^IMAGE 0;", "")
				elseif (ln:find("^URL 0;")) then
					evt.forumlink = ln:gsub("URL 0;", "")
				elseif (ln:find("^PLAYNAME 0;")) then
					evt.action = function() EventsOnline:playEvent(ln:gsub("^PLAYNAME 0;", "")) end
				elseif (ln:find("^PLAYTEXT 0;")) then
					evt.actionText = TB_MENU_LOCALIZED[ln:gsub("^PLAYTEXT 0;", "")] or ln:gsub("^PLAYTEXT 0;", "")
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
					local id = tonumber(ln:sub(1, 1))
					evt.data[id] = { title = ln:sub(2) }
				elseif (ln:find("^DESCDATAIMGTITLE 0;")) then
					local ln = ln:gsub("^DESCDATAIMGTITLE 0;", "")
					local id = tonumber(ln:sub(1, 1))
					local imgtitle = ln:sub(2)
					evt.data[id].imagetitle = "../textures/menu/promo/events/" .. imgtitle
				elseif (ln:find("^DESCDATATEXT 0;")) then
					local ln = ln:gsub("^DESCDATATEXT 0;", "")
					local id = tonumber(ln:sub(1, 1))
					local text = ln:sub(2)
					evt.data[id].desc = text
				elseif (ln:find("^PRIZEDATA 0;")) then
					evt.prizes = evt.prizes or {}
					local ln = ln:gsub("^PRIZEDATA 0;", "")
					local id = tonumber(ln:sub(1, 1))
					evt.prizes[id] = { info = ln:sub(2) }
				elseif (ln:find("^PRIZEIMG 0;")) then
					evt.prizes = evt.prizes or {}
					evt.prizes.imagetitle = "../textures/menu/promo/events/" .. ln:gsub("^PRIZEIMG 0;", "")
				elseif (ln:find("^PRIZETC 0;")) then
					local ln = ln:gsub("^PRIZETC 0;", "")
					local id = tonumber(ln:sub(1, 1))
					local tc = tonumber(ln:sub(2))
					evt.prizes[id].tc = tc
				elseif (ln:find("^PRIZEST 0;")) then
					local ln = ln:gsub("^PRIZEST 0;", "")
					local id = tonumber(ln:sub(1, 1))
					local st = tonumber(ln:sub(2))
					evt.prizes[id].st = st
				elseif (ln:find("^PRIZEITEMS 0;")) then
					local ln = ln:gsub("^PRIZEITEMS 0;", "")
					local id = tonumber(ln:sub(1, 1))
					local cnt = tonumber(ln:sub(2, 2))
					local items = ln:sub(3)
					evt.prizes[id].itemids = { items:match(("(%d+) ?"):rep(cnt)) }
				end
			end
		end
		return eventData
	end
	
end