TIER_REGULAR = 0
TIER_PREMIUM = 1

OFFER_SALE = 1
OFFER_PURCHASE = 2

MARKET_SHOP_DATA = MARKET_SHOP_DATA or { }
MARKET_FEATURED_SHOP_DATA = MARKET_FEATURED_SHOP_DATA or nil
MARKET_ACTIVE_MODAL = MARKET_ACTIVE_MODAL or nil
MARKET_OFFERS_HOME = MARKET_OFFERS_HOME or nil

MARKET_TAX = MARKET_TAX or 0.1

MARKET_ELIGIBLE_CATEGORIES = { 1, 2, 5, 10, 11, 12, 15, 18, 19, 20, 21, 22, 24, 26, 27, 28, 29, 30, 33, 34, 35, 36, 37, 38, 41, 43, 44, 46, 48, 49, 50, 54, 55, 56, 57, 58, 60, 71, 72, 73, 74, 78, 80, 82, 83, 87 }

do
	---**Toribash Market manager class**
	---
	---**Version 5.70**
	---* Added `HookName` field
	---
	---**Version 5.65**
	---* Minor code formatting updates and bug fixes to work correctly with the updated Store class
	---@class Market
	Market = {
		ver = 5.70,
		HookName = "__tbMarketManager"
	}
	Market.__index = Market

	function Market:quit()
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end

	function Market:getSectionNavButtons(viewElement, backAction)
		local buttons = {
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = backAction and backAction or function() TB_MENU_SPECIAL_SCREEN_ISOPEN = 0 Market:quit() end,
			}
		}
		return buttons
	end

	---Returns whether the item is eligible to be sold in Market
	---@param item StoreItem
	---@return boolean
	function Market:itemEligible(item)
		return in_array(item.catid, MARKET_ELIGIBLE_CATEGORIES)
	end

	function Market:parseOffersData(response)
		local offers = { sale = {}, purchase = {} }
		local dataTypes = {
			{ "offerid", numeric = true },
			{ "offertype", numeric = true },
			{ "count", numeric = true },
			{ "itemid", numeric = true },
			{ "userid", numeric = true },
			{ "username" },
			{ "time" },
			{ "price", numeric = true },
			{ "shiai", numeric = true },
			{ "games_played", numeric = true },
			{ "flameid", numeric = true },
			{ "flame_name" },
			{ "flame_body" },
			{ "effectid", numeric = true },
			{ "glow_colorid", numeric = true }
		}

		for ln in response:gmatch("[^\n]+\n?") do
			if (not ln:find("^#") and not ln:find("^%w+ 0;")) then
				local _, cnt = ln:gsub('\t', '')
				local data = { ln:match(("([^\t]*)\t"):rep(cnt)) }

				local offer = {}
				for i,v in pairs(dataTypes) do
					offer[v[1]] = v.numeric and (tonumber(data[i]) or 0) or data[i]
				end

				offer.affordable = true
				if (offer.offertype == 1) then
					if (TB_MENU_PLAYER_INFO.data.tc < offer.price or
						(TB_MENU_PLAYER_INFO.data.qi < Store:getItemInfo(offer.itemid).qi and (TB_MENU_PLAYER_INFO.data.st < offer.shiai or offer.shiai == 0))) then
						offer.affordable = false
					end
					table.insert(offers.sale, offer)
				elseif (offer.offertype == 2) then
					table.insert(offers.purchase, offer)
				end
			end
		end
		return offers
	end

	function Market:parseGatewayResponse(response)
		local data = {}
		for ln in response:gmatch("[^\n]+\n?") do
			local ln = ln:gsub("\n?$", '')
			if (ln:find("^GATEWAY")) then
				data.is_success = ln:gsub("^GATEWAY %d; (%d).*", "%1") == '0'
			else
				local msgType = ln:gsub("^(%w+).*", "%1")
				local val = ln:gsub("^%w+ 0;", '')
				data[string.lower(msgType)] = val:gsub("<br ?/?>", "\n")
			end
		end

		return data
	end

	function Market:parseShopInfo(response)
		local shopData = { stats = {} }
		for ln in response:gmatch("[^\n]+\n?") do
			local cleanedValue = ln:gsub("[^;]+;([^\n]*)\n?$", "%1")
			if (ln:find("^TITLE")) then
				shopData.title = cleanedValue
			elseif (ln:find("^DESC")) then
				shopData.description = cleanedValue
			elseif (ln:find("^TIER")) then
				shopData.tier = tonumber(cleanedValue)
			elseif (ln:find("^IMAGEMD5")) then
				shopData.imageMD5 = cleanedValue
			elseif (ln:find("^MARKETTAX")) then
				MARKET_TAX = tonumber(cleanedValue)
			elseif (ln:find("^SALES") or ln:find("^PURCHASES")) then
				local data = { cleanedValue:match(("(%d+) ?"):rep(2)) }
				shopData.stats[ln:sub(1, 1) == 'S' and 'SALES' or 'PURCHASES'] = { count = data[1], tc = data[2] }
			elseif (ln:find("^SALEOFFERS")) then
				local data = { cleanedValue:match(("(%d+) ?"):rep(2)) }
				shopData.stats.offers = { count = tonumber(data[1]), tc = data[2] }
			elseif (ln:find("^BUYREQUESTS")) then
				local data = { cleanedValue:match(("(%d+) ?"):rep(2)) }
				shopData.stats.requests = { count = tonumber(data[1]), tc = data[2] }
			end
		end
		local totalEarnings = (shopData.stats.SALES and shopData.stats.SALES.tc or 0) - (shopData.stats.PURCHASES and shopData.stats.PURCHASES.tc or 0)
		if (totalEarnings > 0) then
			shopData.stats.TOTAL = { tc = totalEarnings }
		end
		return shopData
	end

	function Market:searchItemsByString(string, withCategories)
		local searchString = string:lower()
		if (searchString:gsub("%s", ''):len() < 2) then
			return { }
		end

		local _, wordCount = searchString:gsub("(%S*)%s*", '')
		local words = { searchString:match(("(%S*)%s*"):rep(wordCount)) }

		local searchResults = { categories = {}, items = {} }
		for _, v in pairs(Store.Items) do
			if (Market:itemEligible(v)) then
				local catMatch, itemMatch = true, true
				local catName, itemName = v.catname:lower(), v.itemname:lower()
				for _, k in pairs(words) do
					k = k:gsub("([^%w])", "%%%1")
					if (withCategories) then
						if (not catName:find(k)) then
							catMatch = false
						else
							catName = catName:gsub("%w*" .. k .. "%w*", '', 1)
						end
					end

					if (not itemName:find(k)) then
						itemMatch = false
					else
						itemName = itemName:gsub("%w*" .. k .. "%w*", '', 1)
					end
				end

				if (withCategories and catMatch) then
					searchResults.categories[v.catid] = { name = v.catname }
				end
				if (itemMatch) then
					table.insert(searchResults.items, v)
				end
			end
		end

		return withCategories and searchResults or searchResults.items
	end

	---@class MarketInventoryItem : InventoryItem
	---@field item StoreItem

	---Returns list of inventory items that can be sold in Market
	---@param item StoreItem|InventoryItem|nil
	---@return MarketInventoryItem[]
	function Market:searchItemsInventory(item)
		local matchingItems = {}
		for _, v in pairs(Store.Inventory or {}) do
			pcall(function()
				if (not v.active and (item == nil or item.itemid == v.itemid)) then
					local itemInfo = Store:getItemInfo(v.itemid)
					if (Market:itemEligible(itemInfo)) then
						local invItem = v:getCopy()
						invItem.item = itemInfo
						table.insert(matchingItems, invItem)
					end
				end
			end)
		end
		return matchingItems
	end

	function Market:clearModal()
		if (MARKET_ACTIVE_MODAL and not MARKET_ACTIVE_MODAL.destroyed) then
			MARKET_ACTIVE_MODAL:kill()
			MARKET_ACTIVE_MODAL = nil
		end
	end

	function Market:confirmWaiterModal(requestName, cancelAction)
		Market:clearModal()
		MARKET_ACTIVE_MODAL = TBMenu:spawnWindowOverlay()
		local loaderView = UIElement:new({
			parent = MARKET_ACTIVE_MODAL,
			pos = { MARKET_ACTIVE_MODAL.size.w / 3, MARKET_ACTIVE_MODAL.size.h / 5 * 2 },
			size = { MARKET_ACTIVE_MODAL.size.w / 3, MARKET_ACTIVE_MODAL.size.h / 5 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5
		})
		TBMenu:displayLoadingMarkSmall(loaderView, TB_MENU_LOCALIZED.NETWORKLOADING)
		MARKET_ACTIVE_MODAL:addMouseHandlers(nil, nil, function(x,y)
				if (MARKET_ACTIVE_MODAL.doCheck) then
					if (x < WIN_W / 2) then
						Request:finalize(requestName)
						Market:clearModal()
						if (cancelAction) then
							cancelAction()
						end
					else
						MARKET_ACTIVE_MODAL.doCheck = false
					end
				end
			end)
	end

	function Market:showModalPriceSuggestions(holder, data)
		local displayed = 0
		for i,v in pairs(data) do
			if (i ~= 'count') then
				local suggestion = holder:addChild({
					pos = { 10 + (math.floor(displayed / 2) % 2) * (holder.size.w - 20) / 2, 5 + (holder.size.h - 10) / 2 * (displayed % 2) },
					size = { (holder.size.w - 20) / 2, (holder.size.h - 10) / 2 },
					bgColor = UICOLORWHITE,
					hoverColor = TB_MENU_DEFAULT_ORANGE,
					pressedColor = TB_MENU_DEFAULT_YELLOW,
					interactive = true
				})
				suggestion:addAdaptedText(true, TB_MENU_LOCALIZED['MARKETPRICE' .. i:upper()] .. ": " .. v .. " " .. TB_MENU_LOCALIZED.WORDTC, nil, nil, 4, math.floor(displayed / 2) % 2 == 0 and LEFTMID or RIGHTMID, 0.65)
				suggestion.size.w = get_string_length(suggestion.dispstr[1], suggestion.textFont) * suggestion.textScale
				if (displayed >= 2) then
					suggestion:moveTo(holder.size.w - suggestion.size.w - 10)
				end

				suggestion:addCustomDisplay(true, function()
						suggestion:uiText(suggestion.str, nil, nil, suggestion.textFont, math.floor(displayed / 2) % 2 == 0 and LEFTMID or RIGHTMID, suggestion.textScale, nil, nil, suggestion:getButtonColor())
						if (suggestion.hoverState ~= nil and suggestion.hoverState ~= BTN_NONE) then
							set_mouse_cursor(1)
						end
					end)
				suggestion:addMouseHandlers(nil, function()
						holder.priceInput.textfieldstr[1] = v .. ''
						holder.priceInput.textfieldindex = holder.priceInput.textfieldstr[1]:len()
						holder.priceInput.textInputCustom()
					end)

				displayed = displayed + 1
				if (not holder:isDisplayed()) then
					suggestion:hide()
				end
			end
		end
	end

	function Market:getPriceSuggestions(holders, itemid, showNothingMessage)
		local showNothingMessage = showNothingMessage == nil and true or showNothingMessage
		Request:queue(function()
				download_market_info("get_prices=" .. itemid)
			end, "marketplace_priceinfo_" .. itemid, function()
				local response = get_network_response()
				local priceData = { count = 0 }
				for ln in response:gmatch("[^\n]+\n?") do
					local cleanedValue = ln:gsub("[^;]+;([^\n]*)\n?$", "%1")
					if (ln:find("^SALE")) then
						priceData.lowestSale = cleanedValue
						priceData.count = priceData.count + 1
					elseif (ln:find("^PURCHASE")) then
						priceData.highestBuy = cleanedValue
						priceData.count = priceData.count + 1
					elseif (ln:find("^LASTSEEN")) then
						priceData.lastSeen = cleanedValue
						priceData.count = priceData.count + 1
					end
				end

				local itemInfo = Store:getItemInfo(itemid)

				for _, holder in pairs(holders) do
					holder:kill(true)
					if (itemInfo.hidden == 0 and itemInfo.locked == 0 and itemInfo.price > 0) then
						priceData.shopPrice = itemInfo.price
						priceData.count = priceData.count + 1
					end
					if (priceData.count > 0) then
						Market:showModalPriceSuggestions(holder, priceData)
					elseif (showNothingMessage) then
						holder:addAdaptedText(false, TB_MENU_LOCALIZED.NOTHINGTOSHOW, nil, nil, 4, nil, 0.7)
					end
				end
			end, function()
				for _, holder in pairs(holders) do
					holder:kill(true)
					holder:addAdaptedText(false, TB_MENU_LOCALIZED.REQUESTCONNECTIONERROR .. "\n" .. get_network_error(), nil, nil, 4, nil, 0.7)
				end
			end)
	end

	function Market:doSellItem(selectedItems, targetOffer, backAction)
		local message = targetOffer and TB_MENU_LOCALIZED.MARKETDIALOGSELLCONFIRM or TB_MENU_LOCALIZED.STOREDIALOGMARKETSELL1
		if (#selectedItems > 4) then
			message = message .. " " .. #selectedItems .. " " .. TB_MENU_LOCALIZED.WORDITEMS
		else
			for i,v in pairs(selectedItems) do
				message = message .. " " .. v.item.itemname .. (i == #selectedItems - 1 and ' &' or ',')
			end
			message = message:sub(1, message:len() - 1)
		end
		message = message .. " " .. (targetOffer and (TB_MENU_LOCALIZED.MARKETDIALOGSELLTO .. " " .. targetOffer.username .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. numberFormat(selectedItems[1].marketPrice) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. "?") or (#selectedItems > 1 and TB_MENU_LOCALIZED.STOREDIALOGMARKETSELL2 or (TB_MENU_LOCALIZED.STOREDIALOGMARKETSELLFOR .. " " .. numberFormat(selectedItems[1].marketPrice) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. "?")))

		-- C++ confirmation boxes don't really auto wrap text
		-- Do wrapping with Lua and then build a string with newlines
		local testDisplay = UIElement:new({
			pos = { 0, 0 },
			size = { WIN_W / 2, WIN_H }
		})
		testDisplay:addAdaptedText(true, message)

		message = ''
		for i,v in pairs(testDisplay.dispstr) do
			message = message .. v .. "\n"
		end
		testDisplay:kill()
		message = message:sub(1, message:len() - 1)

		local data = ''
		for i,v in pairs(selectedItems) do
			data = data .. v.inventid .. ";" .. v.marketPrice .. ";" .. (v.userid and v.userid or 0) .. ":"
		end
		data = data:sub(1, data:len() - 1)

		Market:clearModal()
		Market:confirmWaiterModal("marketplace_sell", backAction)
		Request:queue(function()
				MARKET_ACTIVE_MODAL.doCheck = true
				show_dialog_box(MARKET_SELL, message, data, true)
			end, "marketplace_sell", function()
				Market:clearModal()
				download_inventory()

				local response = Market:parseGatewayResponse(get_network_response())
				local message = ''

				local warning, info
				for ln in response.warning:gmatch("[^\n]+\n?") do
					warning = ln
					break
				end
				for ln in response.info:gmatch("[^\n]+\n?") do
					info = ln
					break
				end

				if (#selectedItems > 1) then
					message = response.success .. (warning and ("\n\n" .. warning:gsub("(%w+)", "^37%1")) or '') .. (info and ("\n\n" .. info:gsub("(%w+)", "^39%1")) or '')

					if (response.error and response.extra) then
						local errors = {}
						for ln in response.error:gmatch("[^\n]+\n?") do
							table.insert(errors, ln)
						end
						message = message .. "\n\n"
						for i, inventid in pairs({ response.extra:match(("(%d+),?"):rep(#errors)) }) do
							for j, item in pairs(selectedItems) do
								if (item.inventid == tonumber(inventid)) then
									message = message .. item.item.itemname .. " " .. TB_MENU_LOCALIZED.WORDERROR:lower() .. ": " .. errors[i] .. "\n"
								end
							end
						end
					end

					MARKET_ACTIVE_MODAL = TBMenu:spawnWindowOverlay(nil, true)
					local messageHolder = MARKET_ACTIVE_MODAL:addChild({
						shift = { WIN_W / 4, WIN_H / 3 },
						bgColor = TB_MENU_DEFAULT_BG_COLOR,
						shapeType = ROUNDED,
						rounded = 5
					})

					local messageText = messageHolder:addChild({
						pos = { 10, 20 },
						size = { messageHolder.size.w - 20, messageHolder.size.h - 105 }
					})
					messageText:addAdaptedText(true, message, nil, nil, 4, nil, 0.8)
					while (messageText.textScale < 0.7 and messageHolder.size.h < WIN_H - 200) do
						messageHolder.size.h = messageHolder.size.h + 100
						messageHolder:moveTo(nil, -50, true)
						messageText.size.h = messageText.size.h + 100
						messageText:addAdaptedText(true, message, nil, nil, 4, nil, 0.8)
					end

					local closeButton = messageHolder:addChild({
						pos = { 50, -65 },
						size = { messageHolder.size.w - 100, 45 },
						interactive = true,
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
						hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
						rounded = 4
					}, true)
					closeButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCLOSEWINDOW)
					closeButton:addMouseHandlers(nil, function() Market:clearModal() end)
				else
					message = ((response.is_success and response.success or response.error) or TB_MENU_LOCALIZED.REQUESTUNKNOWNERROR) .. (warning and ("\n\n" .. warning:gsub("(%w+)", "^37%1")) or '') .. (info and ("\n\n" .. info:gsub("(%w+)", "^39%1")) or '')
					TBMenu:showStatusMessage(message)
				end
				usage_event("marketplace_sell")
			end)
	end

	function Market:showSellInventoryItem(inventoryItems)
		local selectedItems = {}
		for i,v in pairs(inventoryItems) do
			local item = v
			item.item = Store:getItemInfo(item.itemid)
			table.insert(selectedItems, item)
		end

		if (MARKET_SHOP_DATA[TB_MENU_PLAYER_INFO.username:lower()]) then
			Market:spawnPriceSetModal(selectedItems, nil, nil, true)
		else
			local overlay = TBMenu:spawnWindowOverlay(nil, true)
			local messageHolder = overlay:addChild({
				shift = { WIN_W / 3, WIN_H / 2 - 100 },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			TBMenu:displayLoadingMark(messageHolder, TB_MENU_LOCALIZED.MARKETLOADINGDATA)
			Request:queue(function()
					download_server_info("marketplace&user=" .. TB_MENU_PLAYER_INFO.username)
				end, "marketplace_userfetch", function()
					local response = get_network_response()
					if (response:find("ERROR")) then
						if (messageHolder and not messageHolder.destroyed) then
							messageHolder:kill(true)
							messageHolder:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETERRORLOADINGSHOP .. ": " .. error)
						end
						return
					end

					local shopData = Market:parseShopInfo(response)
					local username = TB_MENU_PLAYER_INFO.username:lower()
					if (shopData.title) then
						if (not table.equals(shopData, MARKET_SHOP_DATA[username])) then
							local imageReload = not MARKET_SHOP_DATA[username] and true or MARKET_SHOP_DATA[username].imageMD5 ~= shopData.imageMD5
							MARKET_SHOP_DATA[username] = shopData
						end
						overlay:kill()
						Market:spawnPriceSetModal(selectedItems, nil, nil, true)
					else
						messageHolder:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETERRORLOADINGSHOP)
					end
				end)
		end
	end

	function Market:spawnPriceSetModal(selectedItems, item, offer, noBack)
		if (#selectedItems == 0) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MARKETINVENTORYEMPTY)
			return
		end

		Market:clearModal()
		local specialScreen = TB_MENU_SPECIAL_SCREEN_ISOPEN

		local overlay = TBMenu:spawnWindowOverlay()
		MARKET_ACTIVE_MODAL = overlay

		local width = overlay.size.w / 7 * 3
		local height = math.max(overlay.size.h / 2, 550)
		local modalView = overlay:addChild({
			pos = { (overlay.size.w - width) / 2, (overlay.size.h - height) / 2 },
			size = { width, height },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5,
			interactive = true
		})
		modalView.killAction = function()
			TB_MENU_SPECIAL_SCREEN_ISOPEN = specialScreen
		end

		local uniqueItems = {}
		for _, v in pairs(selectedItems) do
			if (not in_array(v.itemid, uniqueItems)) then
				uniqueItems[v.itemid] = v.itemid
			end
		end

		local elementHeight = 50
		local scrollerView = modalView:addChild({ shift = { 0, 5 } })
		local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(scrollerView, elementHeight, 70, 20, TB_MENU_DEFAULT_BG_COLOR)

		topBar:addChild({ shift = { 15, 8 } }):addAdaptedText(true, offer and TB_MENU_LOCALIZED.MARKETMODIFYINGSALEOFFER or TB_MENU_LOCALIZED.MARKETNEWSALEOFFER, nil, nil, FONTS.BIG)

		local listElements = {}
		if (MARKET_SHOP_DATA[TB_MENU_PLAYER_INFO.username:lower()].tier == TIER_REGULAR and MARKET_TAX > 0) then
			local premiumNoticeHolder = listingHolder:addChild({
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight },
				uiColor = TB_MENU_DEFAULT_YELLOW
			})
			premiumNoticeHolder:addChild({ shift = { 20, 4 } }):addAdaptedText(true, TB_MENU_LOCALIZED.MARKETSELLPREMIUMPROMO .. " (" .. MARKET_TAX * 100 .. "%)", nil, nil, 4, nil, 0.7)
			table.insert(listElements, premiumNoticeHolder)
		end
		for _, v in pairs(selectedItems) do
			local elementHolder = listingHolder:addChild({
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, elementHolder)
			local bgTop = elementHolder:addChild({
				pos = { 10, 3 },
				size = { elementHolder.size.w - 10, elementHolder.size.h + 1 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			local itemIcon = bgTop:addChild({
				pos = { 10, 2 },
				size = { bgTop.size.h - 5, bgTop.size.h - 5 },
				bgImage = v.item:getIconPath()
			})
			local itemName = bgTop:addChild({
				pos = { itemIcon.shift.x * 2 + itemIcon.size.w, itemIcon.shift.y },
				size = { bgTop.size.w - itemIcon.shift.x * 3 - itemIcon.size.w - elementHeight, (v.games_played > 0 or v.effectid > 0) and math.floor((itemIcon.size.h - 2) / 2) or (itemIcon.size.h - 2) }
			})
			itemName:addAdaptedText(true, v.displayName or v.item.itemname, nil, nil, 4, LEFTMID, 0.8)

			if (not offer and not noBack) then
				local cancelButton = bgTop:addChild({
					pos = { -42, 5 },
					size = { 32, 32 },
					interactive = true,
					bgColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR),
					hoverColor = TB_MENU_DEFAULT_BG_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					shapeType = ROUNDED,
					rounded = 4
				})
				cancelButton:addChild({ shift = { 3, 3 }, bgImage = TB_MENU_BUTTON_CROSSWHITE })
				cancelButton.clicked = false
				cancelButton:addMouseHandlers(nil, function()
						cancelButton.clicked = not cancelButton.clicked
						if (cancelButton.clicked) then
							cancelButton.bgColor = table.clone(TB_MENU_DEFAULT_INACTIVE_COLOR_DARK)
							for j,k in pairs(selectedItems) do
								if (v.inventid == k.inventid) then
									table.remove(selectedItems, j)
									break
								end
							end
						else
							cancelButton.bgColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR)
							table.insert(selectedItems, v)
						end
					end)
			end

			local extraDataShift = { x = itemIcon.shift.x * 2 + itemIcon.size.w, y = itemName.shift.y + itemName.size.h }
			if (v.games_played > 0) then
				local gamesPlayed = bgTop:addChild({
					pos = { extraDataShift.x, extraDataShift.y },
					size = { bgTop.size.w - extraDataShift.x - itemIcon.shift.x, itemName.size.h },
					shapeType = ROUNDED,
					rounded = itemName.size.h / 2,
					bgColor = { 0.6, 0.6, 0.6, 1 }
				})
				gamesPlayed:addAdaptedText(false, v.games_played .. " " .. TB_MENU_LOCALIZED.WORDGAMES:gsub("^%l", string.upper), nil, nil, 4, nil, 0.65)
				gamesPlayed.size.w = get_string_length(gamesPlayed.str, gamesPlayed.textFont) * gamesPlayed.textScale + 20
				extraDataShift.x = extraDataShift.x + gamesPlayed.size.w + 5
			end
			local effectsHolder = bgTop:addChild({
				pos = { extraDataShift.x, extraDataShift.y },
				size = { bgTop.size.w - extraDataShift.x - itemIcon.shift.x, itemName.size.h }
			})
			Store:showItemEffectCapsules(v, effectsHolder, effectsHolder.size.h)

			local priceHolder = listingHolder:addChild({
				pos = { 10, #listElements * elementHeight },
				size = { listingHolder.size.w - 10, elementHeight },
				bgColor = bgTop.bgColor
			})
			table.insert(listElements, priceHolder)

			local priceInputHolder = priceHolder:addChild({
				shapeType = ROUNDED,
				rounded = 4
			})
			local sellPriceInfo = priceInputHolder:addChild({
				pos = { 10, 4 },
				size = { priceInputHolder.size.w / 5, priceInputHolder.size.h - 8 }
			})
			sellPriceInfo:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETOFFERYOUGET .. ":", nil, nil, 4, LEFTMID, 0.7)
			sellPriceInfo.size.w = get_string_length(sellPriceInfo.dispstr[1], sellPriceInfo.textFont) * sellPriceInfo.textScale

			local inputWidth = MARKET_SHOP_DATA[TB_MENU_PLAYER_INFO.username:lower()].tier == TIER_REGULAR and (priceHolder.size.w / 2 - sellPriceInfo.shift.x * 4 - sellPriceInfo.size.w) or (priceHolder.size.w - sellPriceInfo.shift.x * 3 - sellPriceInfo.size.w)
			local sellPriceInput = TBMenu:spawnTextField2(priceInputHolder, {
				x = sellPriceInfo.shift.x * 2 + sellPriceInfo.size.w, y = 8, w = inputWidth, h = priceHolder.size.h - 16
			}, v.marketPrice and tostring(v.marketPrice) or nil, TB_MENU_LOCALIZED.MARKETPRICEHINT, {
				isNumeric = true,
				fontId = FONTS.LMEDIUM,
				textScale = 0.7,
				textColor = UICOLORWHITE,
				textAlign = CENTERMID,
				inputType = KEYBOARD_INPUT.NUMBERPAD
			})

			local youGetInput
			if (MARKET_SHOP_DATA[TB_MENU_PLAYER_INFO.username:lower()].tier == TIER_REGULAR) then
				local buyerPriceInfo = priceInputHolder:addChild({
					pos = { priceInputHolder.size.w / 2 + sellPriceInfo.shift.x, sellPriceInfo.shift.y },
					size = { priceInputHolder.size.w / 5, sellPriceInfo.size.h }
				})
				buyerPriceInfo:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETPRICEBUYERPAYS .. ":", nil, nil, 4, LEFTMID, 0.7)
				buyerPriceInfo.size.w = get_string_length(buyerPriceInfo.dispstr[1], buyerPriceInfo.textFont) * buyerPriceInfo.textScale

				local inputWidth = priceHolder.size.w / 2 - sellPriceInfo.shift.x * 3 - buyerPriceInfo.size.w
				youGetInput = TBMenu:spawnTextField2(priceInputHolder, {
					x = buyerPriceInfo.shift.x + sellPriceInfo.shift.x + buyerPriceInfo.size.w, y = 8,
					w = inputWidth, h = priceHolder.size.h - 16
				}, v.marketPrice and tostring(math.floor(v.marketPrice * (1 + MARKET_TAX) + 0.5)) or nil, TB_MENU_LOCALIZED.MARKETPRICEHINT, {
					isNumeric = true,
					fontId = FONTS.LMEDIUM,
					textScale = 0.7,
					textColor = UICOLORWHITE,
					textAlign = CENTERMID,
					inputType = KEYBOARD_INPUT.NUMBERPAD
				})

				sellPriceInput.loader = sellPriceInput:addChild({
					pos = { -sellPriceInput.size.h, 0 },
					size = { sellPriceInput.size.h, sellPriceInput.size.h }
				})
				TBMenu:displayLoadingMarkSmall(sellPriceInput.loader, '')
				sellPriceInput.loader:hide(true)
				sellPriceInput.otherInput = youGetInput

				youGetInput.loader = youGetInput:addChild({
					pos = { -youGetInput.size.h, 0 },
					size = { youGetInput.size.h, youGetInput.size.h }
				})
				TBMenu:displayLoadingMarkSmall(youGetInput.loader, '')
				youGetInput.loader:hide(true)
				youGetInput.otherInput = sellPriceInput

				local delay = math.floor(tonumber(get_option("framerate")) / 2)
				youGetInput.changeDelay = 0
				sellPriceInput.changeDelay = 0

				local priceKeyUp = function(input, instant)
					input.changeDelay = instant and 1 or delay
					input.otherInput.parent:deactivate(true)
					input.otherInput:deactivate(true)
					input.otherInput.loader:show(true)
				end
				local checkDelay = function(input, mode)
					if (input.changeDelay > 0) then
						input.changeDelay = input.changeDelay - 1
						if (input.changeDelay == 0) then
							local price = tonumber(input.textfieldstr[1])
							local targetPrice = price == nil and '' or (mode and math.floor(price * (1 + MARKET_TAX) + 0.5) or math.floor(price / (1 + MARKET_TAX) + 0.5))
							input.otherInput.textfieldstr[1] = targetPrice .. ''
							input.otherInput.textfieldindex = input.otherInput.textfieldstr[1]:len()
							input.otherInput.parent:activate(true)
							input.otherInput:activate(true)
							input.otherInput.loader:hide(true)
							if (not mode) then
								priceKeyUp(input.otherInput, true)
							end
						end
						return true
					end
					return false
				end

				youGetInput:addInputCallback(function()
						priceKeyUp(youGetInput, true)
					end)
				sellPriceInput:addInputCallback(function()
						priceKeyUp(sellPriceInput, true)
					end)

				priceHolder:addCustomDisplay(false, function()
					if (checkDelay(youGetInput) or checkDelay(sellPriceInput, true)) then
						v.marketPrice = tonumber(sellPriceInput.textfieldstr[1]) or 0
					end
				end)
			else
				priceHolder:addCustomDisplay(false, function()
					if (sellPriceInput.lastPrice ~= sellPriceInput.textfieldstr[1]) then
						sellPriceInput.lastPrice = sellPriceInput.textfieldstr[1]
						v.marketPrice = tonumber(sellPriceInput.lastPrice) or 0
					end
				end)
			end

			local priceShortcutsHolder = listingHolder:addChild({
				pos = { 10, #listElements * elementHeight },
				size = { listingHolder.size.w - 10, elementHeight },
				bgColor = bgTop.bgColor
			})
			table.insert(listElements, priceShortcutsHolder)
			TBMenu:displayLoadingMarkSmall(priceShortcutsHolder:addChild({ shift = { 15, 4 } }), TB_MENU_LOCALIZED.MARKETLOADINGPRICESUGGESTIONS)

			priceShortcutsHolder.priceInput = youGetInput and youGetInput or sellPriceInput
			if (type(uniqueItems[v.itemid]) == 'table') then
				table.insert(uniqueItems[v.itemid], priceShortcutsHolder)
			else
				uniqueItems[v.itemid] = { priceShortcutsHolder }
			end
		end

		for i,v in pairs(uniqueItems) do
			Market:getPriceSuggestions(v, i)
		end

		if (#listElements * elementHeight > listingHolder.size.h) then
			for _, v in pairs(listElements) do
				v:hide()
			end

			local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
			listingHolder.scrollBar = scrollBar
			scrollBar:makeScrollBar(listingHolder, listElements, toReload, nil, nil, true)
		else
			listingHolder.size.h = #listElements * elementHeight
			listingView.size.h = listingHolder.size.h
			---@diagnostic disable-next-line: undefined-field
			listingHolder.scrollBG.size.h = listingHolder.size.h
			modalView.size.h = topBar.size.h + listingHolder.size.h + botBar.size.h
			toReload.size.h = modalView.size.h
			botBar:moveTo(nil, -botBar.size.h)
			modalView:moveTo(nil, (WIN_H - modalView.size.h) / 2)
			listingHolder:moveTo((listingHolder.parent.size.w - listingHolder.size.w) / 4, nil, true)

			modalView:updatePos()
		end

		local buttons = offer and 3 or 2

		local cancelButton = botBar:addChild({
			pos = { 15, -50 },
			size = { (botBar.size.w - 30 - 10 * (buttons - 1)) / buttons, 40 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		cancelButton:addChild({ shift = { 15, 5 } }):addAdaptedText(true, (offer or noBack) and TB_MENU_LOCALIZED.BUTTONCANCEL or TB_MENU_LOCALIZED.NAVBUTTONBACK)
		cancelButton:addMouseHandlers(nil, function() if (offer or noBack) then Market:clearModal() else Market:spawnInventoryItemSelector(item, selectedItems) end end)

		local submitButton = botBar:addChild({
			pos = { -cancelButton.size.w - cancelButton.shift.x, cancelButton.shift.y },
			size = { cancelButton.size.w, cancelButton.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
			shapeType = cancelButton.shapeType,
			rounded = cancelButton.rounded
		})
		submitButton:addChild({ shift = { 15, 5 } }):addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONSUBMIT)
		submitButton:addMouseHandlers(nil, function()
				if (offer) then
					local newPrice = MARKET_SHOP_DATA[TB_MENU_PLAYER_INFO.username:lower()].tier == TIER_REGULAR and math.floor(selectedItems[1].marketPrice * (1 + MARKET_TAX) + 0.5) or selectedItems[1].marketPrice
					if (newPrice == offer.price) then
						Market:clearModal()
						return
					end

					Market:confirmWaiterModal("marketplace_update")
					Request:queue(function()
							MARKET_ACTIVE_MODAL.doCheck = true
							show_dialog_box(MARKET_UPDATE, TB_MENU_LOCALIZED.MARKETCONFIRMUPDATEOFFER .. " " .. selectedItems[1].item.itemname .. " " .. TB_MENU_LOCALIZED.MARKETSALEOFFER .. "?\n\n" .. TB_MENU_LOCALIZED.MARKETCONFIRMUPDATEOFFERPRICE .. " " .. numberFormat(newPrice) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS, offer.offerid .. ":" .. selectedItems[1].marketPrice, true)
						end, "marketplace_update", function()
							local response = Market:parseGatewayResponse(get_network_response())
							local message = response.is_success and response.success or response.error
							if (response.is_success) then
								message = message .. (response.warning and ("\n" .. response.warning:gsub("(%w+)", "^37%1")) or '') .. (response.info and ("\n" .. response.info:gsub("(%w+)", "^39%1")) or '')
							end

							TBMenu:showStatusMessage(message)
							Market:clearModal()

							offer.price = newPrice
							offer.triggerPriceUpdate()
							download_inventory()
						end, function()
							TBMenu:showStatusMessage(get_network_error())
							Market:clearModal()
						end)
				else
					Market:doSellItem(selectedItems, nil, function()
							Market:spawnPriceSetModal(selectedItems, item, offer)
						end)
				end
			end)
		submitButton:addCustomDisplay(false, function()
				local available = #selectedItems > 0
				for i,v in pairs(selectedItems) do
					if (not v.marketPrice or v.marketPrice < 1) then
						available = false
					end
				end

				if (available) then
					submitButton:activate(true)
				else
					submitButton:deactivate(true)
				end
			end)

		if (offer == nil) then
			return
		end

		local cancelOfferButton = botBar:addChild({
			pos = { cancelButton.shift.x + cancelButton.size.w + 10, cancelButton.shift.y },
			size = { cancelButton.size.w, cancelButton.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
			shapeType = cancelButton.shapeType,
			rounded = cancelButton.rounded
		})
		cancelOfferButton:addChild({ shift = { 15, 5 } }):addAdaptedText(true, TB_MENU_LOCALIZED.MARKETCANCELOFFER)
		cancelOfferButton:addMouseHandlers(nil, function()
				Market:confirmWaiterModal("marketplace_cancel")
				Request:queue(function()
						MARKET_ACTIVE_MODAL.doCheck = true
						show_dialog_box(MARKET_CANCEL, TB_MENU_LOCALIZED.MARKETCONFIRMCANCELOFFER .. " " .. selectedItems[1].item.itemname .. " " .. TB_MENU_LOCALIZED.MARKETSALEOFFER .. "?", offer.offerid, true)
					end, "marketplace_cancel", function()
						local response = Market:parseGatewayResponse(get_network_response())
						local message = response.is_success and response.success or response.error
						if (response.is_success) then
							message = message .. (response.warning and ("\n" .. response.warning:gsub("(%w+)", "^37%1")) or '') .. (response.info and ("\n" .. response.info:gsub("(%w+)", "^39%1")) or '')
						end

						TBMenu:showStatusMessage(message)
						Market:clearModal()

						offer.button:kill(true)
						offer.button:addChild({ shift = { 10, 3 } }):addAdaptedText(true, TB_MENU_LOCALIZED.MARKETOFFERCANCELLED)
						offer.button:deactivate(true)
						download_inventory()
					end, function()
						TBMenu:showStatusMessage(get_network_error())
						Market:clearModal()
					end)
			end)
	end

	function Market:spawnInventoryItemSelector(item, selectedItems, targetOffer)
		local inventoryItems = Market:searchItemsInventory(item)
		if (#inventoryItems == 0) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MARKETINVENTORYEMPTY)
			return
		end

		Market:clearModal()
		local specialScreen = TB_MENU_SPECIAL_SCREEN_ISOPEN

		local overlay = TBMenu:spawnWindowOverlay()
		MARKET_ACTIVE_MODAL = overlay

		local width = overlay.size.w / 2
		local height = math.max(overlay.size.h / 2, 550)
		local modalView = overlay:addChild({
			pos = { (overlay.size.w - width) / 2, (overlay.size.h - height) / 2 },
			size = { width, height },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5,
			interactive = true
		})
		modalView.killAction = function()
			TB_MENU_SPECIAL_SCREEN_ISOPEN = specialScreen
		end

		local elementHeight = math.clamp(WIN_H / 18, 40, 50)
		local scrollerView = modalView:addChild({ shift = { 0, 5 } })
		local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(scrollerView, elementHeight, 100, 20, TB_MENU_DEFAULT_BG_COLOR)

		topBar:addChild({ pos = { 15, 2 }, size = { topBar.size.w - 30, elementHeight - 4 } }):addAdaptedText(true, TB_MENU_LOCALIZED.MARKETNEWSALEOFFER, nil, nil, FONTS.BIG)

		local listElements = {}
		local selectedItems = selectedItems or {}

		local addToSelected = function(itemHolder, itemCancel, v)
			if (#selectedItems >= (targetOffer and 1 or 20)) then
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.MARKETSELECTITEMSQUANTITYERROR)
				return
			end
			itemHolder:deactivate(true)
			itemCancel:show(true)
			table.insert(selectedItems, v)
		end

		local displayPages
		local showInventoryItems

		local targetItems = inventoryItems
		local currentPage = { 1 }
		local selectedSetid = nil
		local displayListShift = { 0 }

		local backToMainHolder = topBar:addChild({
			pos = { 0, topBar.size.h },
			size = { topBar.size.w - 20, elementHeight },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local backToMainButton = backToMainHolder:addChild({
			pos = { 10, 2 },
			size = { backToMainHolder.size.w, elementHeight - 4 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		backToMainButton:addChild({
			pos = { 10, 2 },
			size = { backToMainButton.size.h - 4, backToMainButton.size.h - 4 },
			bgImage = "../textures/menu/general/back.tga"
		})
		local backToMainText = backToMainButton:addChild({
			pos = { 16 + backToMainButton.size.h, 2 },
			size = { backToMainButton.size.w - 26 - backToMainButton.size.h, backToMainButton.size.h - 4 }
		})
		backToMainText:addAdaptedText(true, TB_MENU_LOCALIZED.NAVBUTTONBACK, nil, nil, nil, LEFTMID)
		backToMainButton.size.w = get_string_length(backToMainText.dispstr[1], backToMainText.textFont) * backToMainText.textScale + backToMainButton.size.h + 30
		backToMainButton:addMouseHandlers(nil, function()
				targetItems = inventoryItems
				selectedSetid = nil
				showInventoryItems(currentPage[1])
			end)

		local backToMainInfoText = backToMainHolder:addChild({
			pos = { backToMainButton.shift.x + backToMainButton.size.w + 4, 2 },
			size = { backToMainHolder.size.w - backToMainButton.shift.x - backToMainButton.size.w - 4, backToMainHolder.size.h - 4 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})

		showInventoryItems = function(page)
			for i = 0, #listElements do listElements[i] = nil end

			if (listingHolder.scrollBar) then
				listingHolder.scrollBar:kill()
				listingHolder.scrollBar = nil
			end
			listingHolder:kill(true)
			listingHolder:moveTo(0, 0)

			if (targetItems == inventoryItems) then
				backToMainHolder:hide(true)
			else
				table.insert(listElements, listingHolder:addChild({
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				}))
				backToMainHolder:show(true)
			end

			for i = 1 + (page - 1) * 100, math.min((page) * 100, #targetItems) do
				local v = targetItems[i]
				local element = listingHolder:addChild({
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, element)
				local itemHolder = element:addChild({
					pos = { 10, 2 },
					size = { element.size.w - 10, element.size.h - 4 },
					interactive = true,
					clickThrough = true,
					hoverThrough = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
					shapeType = ROUNDED,
					rounded = 4
				})
				local itemCancel = itemHolder:addChild({
					pos = { -itemHolder.size.h + 4, 4 },
					size = { itemHolder.size.h - 8, itemHolder.size.h - 8 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				}, true)
				local itemCancelIcon = itemCancel:addChild({
					shift = { 4, 4 },
					bgImage = TB_MENU_BUTTON_CROSSWHITE
				})
				itemCancel:addMouseHandlers(nil, function()
						itemHolder:activate(true)
						itemCancel:hide(true)
						for i,v in pairs(selectedItems) do
							if (v.inventid == v.inventid) then
								table.remove(selectedItems, i)
								break
							end
						end
					end)

				local itemName = itemHolder:addChild({
					pos = { 10, 2 },
					size = { itemHolder.size.w - itemCancel.size.h - 20, itemHolder.size.h - 4 }
				})

				v.displayName = v.item.itemname
				if (v.item.itemid == ITEM_FLAME) then
					v.displayName = v.displayName .. ": " .. v.flamename
				end
				if (v.itemid == ITEM_SET) then
					v.displayName = v.displayName .. ": " .. v.setname .. " (" .. #v.contents .. " " .. TB_MENU_LOCALIZED.WORDITEMS:lower() .. ")"
				end
				if (v.parentset ~= nil) then
					local setCaption = " (" .. TB_MENU_LOCALIZED.STORESETITEMNAME .. ": " .. v.parentset.setname .. ")"
					setCaption = utf8.gsub(setCaption, " ", " ^" .. COLORS.ANTIQUEWHITE2)
					v.displayName = v.displayName .. setCaption
				end

				itemName:addAdaptedText(true, v.displayName, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)
				if (v.effectid > 0) then
					itemName.size.w = get_string_length(itemName.dispstr[1], itemName.textFont) * itemName.textScale + 5
					local effectsHolder = itemName:addChild({
						pos = { itemName.size.w, 0 },
						size = { itemName.parent.size.w - itemName.shift.x - itemName.size.w - 15 - itemCancel.size.w, itemName.size.h }
					})
					Store:showItemEffectCapsules(v, effectsHolder)
				end

				itemHolder:addMouseHandlers(nil, function()
						if (v.itemid == ITEM_SET) then
							targetItems = v.contents
							selectedSetid = v.setid
							currentPage[selectedSetid] = currentPage[selectedSetid] or 1
							backToMainInfoText:addAdaptedText(false, v.item.itemname .. ": " .. v.setname, nil, nil, 4, nil, 0.8)
							showInventoryItems(currentPage[selectedSetid])
						else
							addToSelected(itemHolder, itemCancel, v)
						end
					end)

				local isSelected = false
				for j,k in pairs(selectedItems) do
					if (k.inventid == v.inventid) then
						isSelected = true
						itemHolder:deactivate(true)
						itemCancel:show(true)
						break
					end
				end

				if (not isSelected) then
					itemCancel:hide(true)
				end
			end

			listingHolder.numElements = #listElements
			if (#listElements * elementHeight > listingHolder.size.h) then
				for i,v in pairs(listElements) do
					v:hide()
				end

				local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
				listingHolder.scrollBar = scrollBar
				scrollBar:makeScrollBar(listingHolder, listElements, toReload, not selectedSetid and displayListShift, nil, true)
			else
				listingHolder:moveTo((listingHolder.parent.size.w - listingHolder.size.w) / 4, nil, true)
			end

			displayPages()
		end

		local selectedItemsText = botBar:addChild({
			pos = { 15, -90 },
			size = { (botBar.size.w - 30) / (#inventoryItems > 100 and 2 or 0), 30 }
		})
		selectedItemsText:addCustomDisplay(true, function()
				selectedItemsText:uiText(TB_MENU_LOCALIZED.MARKETSELECTEDITEMS .. " " .. #selectedItems, nil, nil, 4, #inventoryItems > 100 and LEFTMID or CENTERMID, 0.75)
			end)

		local pagesSelectorText = botBar:addChild({
			pos = { -selectedItemsText.size.w - selectedItemsText.shift.x, selectedItemsText.shift.y },
			size = { 70, selectedItemsText.size.h }
		})
		pagesSelectorText:addAdaptedText(true, TB_MENU_LOCALIZED.PAGINATIONPAGE .. ":", nil, nil, 4, RIGHTMID, 0.65)
		local pagesSelectorHolder = botBar:addChild({
			pos = { -selectedItemsText.size.w + pagesSelectorText.size.w - selectedItemsText.shift.x, selectedItemsText.shift.y },
			size = { selectedItemsText.size.w - pagesSelectorText.size.w, selectedItemsText.size.h },
			shapeType = ROUNDED,
			rounded = 4
		})

		local pageButtonWidth = 35
		displayPages = function()
			pagesSelectorHolder:kill(true)
			local pages = math.ceil(#targetItems / 100)
			local pagesMax = math.floor(pagesSelectorHolder.size.w / pageButtonWidth)

			local cPage = selectedSetid and currentPage[selectedSetid] or currentPage[1]
			local pagesData = TBMenu:generatePaginationData(pages, pagesMax, cPage)

			for i, v in pairs(pagesData) do
				local pageButton = pagesSelectorHolder:addChild({
					pos = { (i - 1) * pageButtonWidth, 0 },
					size = { pageButtonWidth * 0.8, pagesSelectorHolder.size.h },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK
				}, true)
				pageButton:addAdaptedText(false, v .. '', nil, nil, 4, nil, 0.6)
				pageButton:addMouseHandlers(nil, function()
						if (selectedSetid) then
							currentPage[selectedSetid] = v
						else
							currentPage[1] = v
							displayListShift[1] = 0
						end
						showInventoryItems(v)
					end)
				if (cPage == v) then
					pageButton:deactivate(true)
				end
			end
			pagesSelectorHolder:moveTo(-(#pagesData - 0.2) * pageButtonWidth - selectedItemsText.shift.x)
			pagesSelectorText:moveTo(-(#pagesData - 0.2) * pageButtonWidth - selectedItemsText.shift.x - pagesSelectorText.size.w - 5)
		end

		showInventoryItems(currentPage[1])

		local cancelButton = botBar:addChild({
			pos = { 15, -50 },
			size = { (botBar.size.w - 40) / 2, 40 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		cancelButton:addChild({ shift = { 15, 5 } }):addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONCANCEL)
		cancelButton:addMouseHandlers(nil, function()
				overlay:kill()
			end)

		local submitButton = botBar:addChild({
			pos = { cancelButton.shift.x + cancelButton.size.w + 10, cancelButton.shift.y },
			size = { cancelButton.size.w, cancelButton.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
			shapeType = cancelButton.shapeType,
			rounded = cancelButton.rounded
		})
		submitButton:addChild({ shift = { 15, 5 } }):addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONCONTINUE)
		submitButton:addCustomDisplay(false, function()
				if (#selectedItems < 1) then
					submitButton:deactivate(true)
				else
					submitButton:activate(true)
				end
			end)
		submitButton:addMouseHandlers(nil, function()
				if (targetOffer) then
					for i,v in pairs(selectedItems) do
						v.marketPrice = targetOffer.price
						v.userid = targetOffer.userid
					end
					Market:doSellItem(selectedItems, targetOffer)
				else
					Market:spawnPriceSetModal(selectedItems, item)
				end
			end)

		if (listingHolder.numElements * elementHeight < listingHolder.size.h) then
			listingHolder.size.h = listingHolder.numElements * elementHeight
			listingView.size.h = listingHolder.size.h
			---@diagnostic disable-next-line: undefined-field
			listingHolder.scrollBG.size.h = listingHolder.size.h
			modalView.size.h = topBar.size.h + listingHolder.size.h + botBar.size.h
			toReload.size.h = modalView.size.h
			botBar:moveTo(nil, -botBar.size.h)
			modalView:moveTo(nil, (WIN_H - modalView.size.h) / 2)
		end
	end

	function Market:spawnModifyPurchaseOfferModal(offer)
		Market:clearModal()

		local item = Store:getItemInfo(offer.itemid)
		local overlay = TBMenu:spawnWindowOverlay()
		MARKET_ACTIVE_MODAL = overlay

		local width = overlay.size.w / 7 * 3
		local height = math.max(overlay.size.h / 4, 290)
		local modalView = overlay:addChild({
			pos = { (overlay.size.w - width) / 2, (overlay.size.h - height) / 2 },
			size = { width, height },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5,
			interactive = true
		})
		local modalTitle = modalView:addChild({
			pos = { 15, 5 },
			size = { modalView.size.w - 30, 64 }
		})
		modalTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETMODIFYINGBUYREQUEST .. ": " .. item.itemname, nil, nil, FONTS.BIG, nil, 0.6)

		local cancelButton = modalView:addChild({
			pos = { 15, -55 },
			size = { (modalView.size.w - 50) / 3, 40 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			rounded = 4
		}, true)
		local cancelText = cancelButton:addChild({ shift = { 15, 5 } }):addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONCANCEL)
		cancelButton:addMouseHandlers(nil, function() Market:clearModal() end)

		local cancelOfferButton = modalView:addChild({
			pos = { cancelButton.shift.x + cancelButton.size.w + 10, cancelButton.shift.y },
			size = { cancelButton.size.w, cancelButton.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
			shapeType = cancelButton.shapeType,
			rounded = cancelButton.rounded
		})
		cancelOfferButton:addChild({ shift = { 15, 5 } }):addAdaptedText(true, TB_MENU_LOCALIZED.MARKETCANCELOFFER)
		cancelOfferButton:addMouseHandlers(nil, function()
				Market:confirmWaiterModal("marketplace_cancel")
				Request:queue(function()
						MARKET_ACTIVE_MODAL.doCheck = true
						show_dialog_box(MARKET_CANCEL, TB_MENU_LOCALIZED.MARKETCONFIRMCANCELOFFER .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.MARKETSALEOFFER .. "?", offer.offerid, true)
					end, "marketplace_cancel", function()
						local response = Market:parseGatewayResponse(get_network_response())
						local message = response.is_success and response.success or response.error
						if (response.is_success) then
							message = message .. (response.warning and ("\n" .. response.warning:gsub("(%w+)", "^37%1")) or '') .. (response.info and ("\n" .. response.info:gsub("(%w+)", "^39%1")) or '')
						end

						TBMenu:showStatusMessage(message, 10)
						Market:clearModal()

						if (offer.button ~= nil) then
							offer.button:kill(true)
							offer.button:addChild({ shift = { 10, 3 } }):addAdaptedText(true, TB_MENU_LOCALIZED.MARKETOFFERCANCELLED)
							offer.button:deactivate(true)
						end
						update_tc_balance()
					end, function()
						TBMenu:showStatusMessage(get_network_error())
						Market:clearModal()
					end)
			end)

		local submitButton = modalView:addChild({
			pos = { cancelOfferButton.shift.x + cancelButton.size.w + 10, cancelButton.shift.y },
			size = { cancelButton.size.w, cancelButton.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
			rounded = cancelButton.rounded
		}, true)
		local submitText = submitButton:addChild({ shift = { 15, 5 } })
		submitText:addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONCONTINUE)
		submitButton:addMouseHandlers(nil, function()
			if (submitButton.price == offer.price) then
				Market:clearModal()
				return
			end

			Market:confirmWaiterModal("marketplace_update")
			Request:queue(function()
					MARKET_ACTIVE_MODAL.doCheck = true
					local balanceAfterUpdate = TB_MENU_PLAYER_INFO.data.tc - (submitButton.price - offer.price)
					show_dialog_box(MARKET_UPDATE, TB_MENU_LOCALIZED.MARKETCONFIRMUPDATEOFFER .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.MARKETBUYREQUEST .. "?\n\n" .. TB_MENU_LOCALIZED.MARKETCONFIRMUPDATEOFFERPRICE .. " " .. numberFormat(submitButton.price) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. "\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 .. " " .. numberFormat(balanceAfterUpdate) .. " " .. TB_MENU_LOCALIZED.WORDTC .. " " .. TB_MENU_LOCALIZED.MARKETBUYREQUESTLEFT2, offer.offerid .. ":" .. submitButton.price, true)
				end, "marketplace_update", function()
					local response = Market:parseGatewayResponse(get_network_response())
					local message = response.is_success and response.success or response.error
					if (response.is_success) then
						message = message .. (response.warning and ("\n" .. response.warning:gsub("(%w+)", "^37%1")) or '') .. (response.info and ("\n" .. response.info:gsub("(%w+)", "^39%1")) or '')
					end

					TBMenu:showStatusMessage(message)
					Market:clearModal()

					offer.price = submitButton.price
					if (offer.triggerPriceUpdate) then
						offer.triggerPriceUpdate()
					end
					update_tc_balance()
				end, function()
					TBMenu:showStatusMessage(get_network_error())
					Market:clearModal()
				end)
			end)

		local inputHolder = modalView:addChild({
			pos = { 15, (modalView.size.h - 40) / 2 - 20 },
			size = { modalView.size.w - 30, 40 },
			rounded = 4
		}, true)

		local priceInsufficientFundsError = modalView:addChild({
			pos = { inputHolder.shift.x, (modalView.size.h - 26) / 2 + 20 },
			size = { inputHolder.size.w, 26 }
		})
		priceInsufficientFundsError:hide()

		local inputField = TBMenu:spawnTextField2(inputHolder, nil, tostring(offer.price), TB_MENU_LOCALIZED.MARKETMODALPURCHASEPRICE, {
			isNumeric = true, fontId = 4, textScale = 0.7, textColor = UICOLORWHITE, textAlign = CENTERMID
		})
		inputField:addInputCallback(function()
				local maxVal = math.min(1000000, TB_MENU_PLAYER_INFO.data.tc + offer.price)
				local price = tonumber(inputField.textfieldstr[1]) or -1
				submitButton.price = price
				if (price > maxVal) then
					submitButton:deactivate()
					priceInsufficientFundsError:addAdaptedText(true, price > TB_MENU_PLAYER_INFO.data.tc and (TB_MENU_LOCALIZED.MARKETYOURBALANCEERROR .. " " .. numberFormat(TB_MENU_PLAYER_INFO.data.tc) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS) or TB_MENU_LOCALIZED.MARKETPRICEEXCEEDSMAX, nil, nil, 4, nil, 0.65)
					priceInsufficientFundsError:show()
				elseif (price < 1) then
					submitButton:deactivate()
					priceInsufficientFundsError:hide()
				else
					submitButton:activate()
					priceInsufficientFundsError:hide()
				end
			end)
		submitButton.price = offer.price


		local priceShortcutsHolder = modalView:addChild({
			pos = { 15, -110 },
			size = { modalView.size.w - 30, 45 }
		})
		TBMenu:displayLoadingMarkSmall(priceShortcutsHolder:addChild({ shift = { 15, 4 } }), TB_MENU_LOCALIZED.MARKETLOADINGPRICESUGGESTIONS)
		priceShortcutsHolder.priceInput = inputField
		Market:getPriceSuggestions({ priceShortcutsHolder }, item.itemid, false)
	end

	function Market:showModifyUserShop(shopData, onUpdate)
		Market:clearModal()

		local overlay = TBMenu:spawnWindowOverlay(nil, true)
		MARKET_ACTIVE_MODAL = overlay

		local width = overlay.size.w / 7 * 3
		local height = shopData.tier >= TIER_PREMIUM and 480 or 400
		local modalView = overlay:addChild({
			pos = { (overlay.size.w - width) / 2, (overlay.size.h - height) / 2 },
			size = { width, height },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5,
			interactive = true
		})
		local modalTitle = modalView:addChild({
			pos = { 15, 5 },
			size = { modalView.size.w - 30, 64 }
		})
		modalTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETMODIFYINGSHOPINFO, nil, nil, FONTS.BIG, nil, 0.6)

		local cancelButton = modalView:addChild({
			pos = { 15, -55 },
			size = { (modalView.size.w - 40) / 2, 40 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			rounded = 4
		}, true)
		local cancelText = cancelButton:addChild({ shift = { 15, 5 } })
		cancelText:addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONCANCEL)
		cancelButton:addMouseHandlers(nil, function() Market:clearModal() end)

		local submitButton = modalView:addChild({
			pos = { cancelButton.shift.x + cancelButton.size.w + 10, cancelButton.shift.y },
			size = { cancelButton.size.w, cancelButton.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
			rounded = cancelButton.rounded
		}, true)
		local submitText = submitButton:addChild({ shift = { 15, 5 } })
		submitText:addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONSUBMIT)

		local titleHolder = modalView:addChild({
			pos = { 15, modalTitle.size.h + modalTitle.shift.y + 10 },
			size = { modalView.size.w - 30, 65 }
		})
		titleHolder:addChild({ size = { titleHolder.size.w, 30 } }):addAdaptedText(true, TB_MENU_LOCALIZED.MARKETSHOPTITLE, nil, nil, nil, LEFTMID)
		local titleInputHolder = titleHolder:addChild({
			pos = { 0, 35 },
			size = { titleHolder.size.w, 30 },
			shapeType = ROUNDED,
			rounded = 4
		})
		local titleInput = TBMenu:spawnTextField2(titleInputHolder, nil, shopData.title, TB_MENU_LOCALIZED.MARKETSHOPTITLE, {
			fontId = FONTS.LMEDIUM,
			textScale = 0.8,
			textColor = UICOLORWHITE,
			maxLength = 32,
			textAlign = LEFTMID
		})

		local descHolder = modalView:addChild({
			pos = { 15, titleHolder.size.h + titleHolder.shift.y + 20 },
			size = { modalView.size.w - 30, 160 }
		})
		descHolder:addChild({ size = { descHolder.size.w, 30 } }):addAdaptedText(true, TB_MENU_LOCALIZED.MARKETSHOPDESC, nil, nil, nil, LEFTMID)
		local descInputHolder = descHolder:addChild({
			pos = { 0, 35 },
			size = { descHolder.size.w, descHolder.size.h - 35 },
			shapeType = ROUNDED,
			rounded = 4
		})
		local description = shopData.description:gsub("\r?\n?%\\n", "\n")
		local descInput = TBMenu:spawnTextField2(descInputHolder, nil, description, TB_MENU_LOCALIZED.MARKETSHOPDESC, {
			fontId = FONTS.LMEDIUM,
			textScale = 0.8,
			textColor = UICOLORWHITE,
			maxLength = 512,
			textAlign = LEFT,
			allowMultiline = true
		})

		local newImagePath = nil
		if (shopData.tier >= TIER_PREMIUM) then
			local chooseShopIcon = modalView:addChild({
				pos = { cancelButton.shift.x, cancelButton.shift.y - 75 },
				size = { modalView.size.w - cancelButton.shift.x * 2, 65 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = cancelButton.shapeType,
				rounded = cancelButton.rounded
			})
			chooseShopIcon:addChild({ shift = { 15, 5 }}):addAdaptedText(true, TB_MENU_LOCALIZED.MARKETCHOOSENEWSHOPIMAGE)
			chooseShopIcon:addMouseHandlers(nil, function()
					chooseShopIcon:kill(true)
					TBMenu:displayLoadingMarkSmall(chooseShopIcon, '')
					if (open_file_browser("Image Files", "jpg;jpeg;png;tga;gif;bmp", "All Files", "*")) then
						add_hook("filebrowser_select", Market.HookName, function(filename)
								newImagePath = filename:len() > 0 and filename or nil
								chooseShopIcon:kill(true)
								chooseShopIcon:addChild({ shift = { 15, 5 }}):addAdaptedText(true, newImagePath and (TB_MENU_LOCALIZED.GENERALSELECTEDFILE .. ": " .. newImagePath) or TB_MENU_LOCALIZED.MARKETCHOOSENEWSHOPIMAGE)
								remove_hook("filebrowser_select", Market.HookName)
								return 1
							end)
					end
				end)
		end

		submitButton:addMouseHandlers(nil, function()
				Market:confirmWaiterModal("marketplace_saveshop")
				Request:queue(function()
						MARKET_ACTIVE_MODAL.doCheck = true
						show_dialog_box(MARKET_SAVESHOP, TB_MENU_LOCALIZED.MARKETMODIFYSHOPCONFIRM, titleInput.textfieldstr[1] .. "{^:}" .. descInput.textfieldstr[1], true)
					end, "marketplace_saveshop", function()
						local response = Market:parseGatewayResponse(get_network_response())
						local message = (response.is_success and response.success or response.error) .. (response.warning and ("\n" .. response.warning:gsub("(%w+)", "^37%1")) or '') .. (response.info and ("\n" .. response.info:gsub("(%w+)", "^39%1")) or '')

						if (newImagePath) then
							local waiter = MARKET_ACTIVE_MODAL:addChild({})
							waiter.wait = 4
							waiter:addCustomDisplay(true, function()
									waiter.wait = waiter.wait - 1
									if (waiter.wait <= 0) then
										Request:queue(function()
												upload_texture_image("marketplace_shop_promo", newImagePath)
											end, "marketplace_saveshopimage", function()
												local imgResponse = get_network_response()
												if (imgResponse:find("^GATEWAY 0; 0")) then
													message = message .. "\n" .. TB_MENU_LOCALIZED.MARKETSHOPIMAGEUPDATED
												else
													local errCode = imgResponse:gsub(".* (%d+)", "%1")
													message = message .. "\n" .. TB_MENU_LOCALIZED.MARKETSHOPIMAGEUPDATEERROR .. " (" .. errCode .. ")"
												end

												if (onUpdate) then
													onUpdate()
												end
												TBMenu:showStatusMessage(message)
												Market:clearModal()
											end, function()
												if (response.is_success and onUpdate) then
													onUpdate()
												end
												TBMenu:showStatusMessage(message .. "\n" .. TB_MENU_LOCALIZED.MARKETSHOPIMAGEUPDATEERROR .. ": " .. get_network_error())
												Market:clearModal()
											end)
										waiter:kill()
									end
								end)
							return
						end

						if (response.is_success and onUpdate) then
							onUpdate()
						end
						TBMenu:showStatusMessage(message)
						Market:clearModal()
					end, function()
						TBMenu:showStatusMessage(get_network_error())
						Market:clearModal()
					end)
			end)
	end

	function Market:spawnPurchaseModalInput(item)
		Market:clearModal()

		local overlay = TBMenu:spawnWindowOverlay()
		MARKET_ACTIVE_MODAL = overlay

		local width = overlay.size.w / 7 * 3
		local height = math.max(overlay.size.h / 4, 290)
		local modalView = overlay:addChild({
			pos = { (overlay.size.w - width) / 2, (overlay.size.h - height) / 2 },
			size = { width, height },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5,
			interactive = true
		})
		local modalTitle = modalView:addChild({
			pos = { 15, 5 },
			size = { modalView.size.w - 30, 64 }
		})
		modalTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETNEWPURCHASEOFFER .. ": " .. item.itemname, nil, nil, FONTS.BIG, nil, 0.6)

		local cancelButton = modalView:addChild({
			pos = { 15, -55 },
			size = { (modalView.size.w - 40) / 2, 40 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			rounded = 4
		}, true)
		local cancelText = cancelButton:addChild({ shift = { 15, 5 } })
		cancelText:addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONCANCEL)
		cancelButton:addMouseHandlers(nil, function() Market:clearModal() end)

		local submitButton = modalView:addChild({
			pos = { cancelButton.shift.x + cancelButton.size.w + 10, cancelButton.shift.y },
			size = { cancelButton.size.w, cancelButton.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
			rounded = cancelButton.rounded
		}, true)
		local submitText = submitButton:addChild({ shift = { 15, 5 } })
		submitText:addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONCONTINUE)
		submitButton:addMouseHandlers(nil, function()
				Market:confirmWaiterModal("marketplace_purchase")
				Request:queue(function()
						MARKET_ACTIVE_MODAL.doCheck = true
						show_dialog_box(MARKET_BUY, TB_MENU_LOCALIZED.MARKETPURCHASEOFFERCONFIRM .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. numberFormat(submitButton.price) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. "?\n\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 .. " " .. numberFormat(TB_MENU_PLAYER_INFO.data.tc - submitButton.price) .. " " .. TB_MENU_LOCALIZED.WORDTC .. " " .. TB_MENU_LOCALIZED.MARKETPURCHASEYOUWILLHAVELEFT2, item.itemid .. ":" .. submitButton.price .. ":0:0:0", true)
					end, "marketplace_purchase", function()
						Market:clearModal()
						local response = Market:parseGatewayResponse(get_network_response())
						local message = response.is_success and response.success or response.error
						if (response.is_success) then
							usage_event("marketplace_purchase")
							message = message .. (response.warning and ("\n" .. response.warning:gsub("(%w+)", "^37%1")) or '') .. (response.info and ("\n" .. response.info:gsub("(%w+)", "^39%1")) or '')
						end

						update_tc_balance()
						TBMenu:showStatusMessage(message)
						Market:clearModal()
					end, function()
						TBMenu:showStatusMessage(get_network_error())
						Market:clearModal()
					end)
			end)
		submitButton:deactivate()

		local inputHolder = modalView:addChild({
			pos = { 15, (modalView.size.h - 40) / 2 - 20 },
			size = { modalView.size.w - 30, 40 },
			rounded = 4
		}, true)

		local priceInsufficientFundsError = modalView:addChild({
			pos = { inputHolder.shift.x, (modalView.size.h - 26) / 2 + 20 },
			size = { inputHolder.size.w, 26 }
		})
		priceInsufficientFundsError:hide()

		local inputField = TBMenu:spawnTextField2(inputHolder, nil, nil, TB_MENU_LOCALIZED.MARKETMODALPURCHASEPRICE, {
			isNumeric = true, fontId = 4, textScale = 0.7, textColor = UICOLORWHITE, textAlign = CENTERMID
		})
		inputField:addInputCallback(function()
				local maxVal = math.min(1000000, TB_MENU_PLAYER_INFO.data.tc)
				local price = tonumber(inputField.textfieldstr[1]) or -1
				submitButton.price = price
				if (price > maxVal) then
					submitButton:deactivate()
					priceInsufficientFundsError:addAdaptedText(true, price > TB_MENU_PLAYER_INFO.data.tc and (TB_MENU_LOCALIZED.MARKETYOURBALANCEERROR .. " " .. numberFormat(TB_MENU_PLAYER_INFO.data.tc) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS) or TB_MENU_LOCALIZED.MARKETPRICEEXCEEDSMAX, nil, nil, 4, nil, 0.65)
					priceInsufficientFundsError:show()
				elseif (price < 1) then
					submitButton:deactivate()
					priceInsufficientFundsError:hide()
				else
					submitButton:activate()
					priceInsufficientFundsError:hide()
				end
			end)

		local priceShortcutsHolder = modalView:addChild({
			pos = { 15, -110 },
			size = { modalView.size.w - 30, 45 }
		})
		TBMenu:displayLoadingMarkSmall(priceShortcutsHolder:addChild({ shift = { 15, 4 } }), TB_MENU_LOCALIZED.MARKETLOADINGPRICESUGGESTIONS)
		priceShortcutsHolder.priceInput = inputField
		Market:getPriceSuggestions({ priceShortcutsHolder }, item.itemid, false)
	end

	function Market:spawnItemSelectorModal()
		local specialScreen = TB_MENU_SPECIAL_SCREEN_ISOPEN
		Market:clearModal()

		local overlay = TBMenu:spawnWindowOverlay(nil, true)
		MARKET_ACTIVE_MODAL = overlay

		local width = overlay.size.w / 7 * 3
		local height = math.max(overlay.size.h / 4, 200)
		local modalView = overlay:addChild({
			pos = { (overlay.size.w - width) / 2, (overlay.size.h - height) / 2 },
			size = { width, height },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5,
			interactive = true
		})
		modalView.killAction = function()
				TB_MENU_SPECIAL_SCREEN_ISOPEN = specialScreen
			end
		local modalTitle = modalView:addChild({
			pos = { 15, 5 },
			size = { modalView.size.w - 30, 34 }
		})
		modalTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETSELECTITEMMODAL, nil, nil, FONTS.BIG)

		local cancelButton = modalView:addChild({
			pos = { 15, -55 },
			size = { (modalView.size.w - 40) / 2, 40 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			rounded = 4
		}, true)
		local cancelText = cancelButton:addChild({ shift = { 15, 5 } })
		cancelText:addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONCANCEL)
		cancelButton:addMouseHandlers(nil, function() overlay:kill() end)

		local submitButton = modalView:addChild({
			pos = { cancelButton.shift.x + cancelButton.size.w + 10, cancelButton.shift.y },
			size = { cancelButton.size.w, cancelButton.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
			rounded = cancelButton.rounded
		}, true)
		local submitText = submitButton:addChild({ shift = { 15, 5 } })
		submitText:addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONCONTINUE)
		submitButton:addMouseHandlers(nil, function()
				Market:spawnPurchaseModalInput(submitButton.item)
			end)
		submitButton:deactivate()

		local inputHolder = modalView:addChild({
			shift = { 15, (modalView.size.h - 40) / 2 },
			rounded = 4
		}, true)
		local inputField = TBMenu:spawnTextField2(inputHolder, nil, nil, TB_MENU_LOCALIZED.STORESEARCHHINT, {
			fontId = FONTS.LMEDIUM,
			textScale = 0.7,
			textColor = UICOLORWHITE,
			textAlign = CENTERMID
		})
		inputField:addInputCallback(function()
				if (inputHolder.dropdown) then
					inputHolder.dropdown:kill()
				end

				local searchResults = Market:searchItemsByString(inputField.textfieldstr[1])
				local dropdownList = {}
				local maxId = math.floor(WIN_H / 3 / (inputHolder.size.h * 0.8))
				for _, v in pairs(table.qsort(searchResults, 'itemname')) do
					if (v.qi <= TB_MENU_PLAYER_INFO.data.qi) then
						table.insert(dropdownList, {
							text = v.itemname,
							action = function()
								inputField.textfieldstr[1] = v.itemname
								inputField.textfieldindex = inputField.textfieldstr[1]:len()
								submitButton.item = v
								submitButton:activate()
								inputHolder.dropdown.selectedElement:hide(true)
							end,
							item = v
						})
					end
					if (#dropdownList >= maxId) then break end
				end

				submitButton:deactivate()
				if (#dropdownList == 0) then
					return
				elseif (#dropdownList == 1 and dropdownList[1].text:lower() == inputField.textfieldstr[1]:lower()) then
					submitButton.item = dropdownList[1].item
					submitButton:activate()
					return
				end

				inputHolder.dropdown = TBMenu:spawnDropdown(inputField, dropdownList, inputHolder.size.h * 0.8, WIN_H / 3, { text = '' }, nil, { scale = 0.65, fontid = 4 }, true, true, true)
				inputHolder.dropdown.selectedElement:hide(true)
				inputHolder.dropdown.selectedElement.btnUp()
			end)
	end

	function Market:spawnPurchaseModal(offer, item, price, shiai)
		local confirmMessage = TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. item.itemname .. " "
		if (offer ~= nil) then
			confirmMessage = confirmMessage .. TB_MENU_LOCALIZED.MARKETPURCHASEFROM .. " " .. offer.username .. "?\n" .. TB_MENU_LOCALIZED.MARKETYOUWILLBECHARGED .. " " .. numberFormat(offer.price) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. (offer.shiai > 0 and (" & " .. offer.shiai .. " " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS) or '') .. "."
		else
			confirmMessage = confirmMessage .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. numberFormat(price) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. (shiai > 0 and (" & " .. shiai .. " " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS) or '') .. "?"
		end
		confirmMessage = confirmMessage .. "\n\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 .. " " .. numberFormat(TB_MENU_PLAYER_INFO.data.tc - price) .. " " .. TB_MENU_LOCALIZED.WORDTC .. (shiai > 0 and (" & " .. TB_MENU_PLAYER_INFO.data.st - shiai .. " " .. TB_MENU_LOCALIZED.WORDST) or '') .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT2

		Market:confirmWaiterModal("marketplace_purchase")
		Request:queue(function()
				MARKET_ACTIVE_MODAL.doCheck = true
				show_dialog_box(MARKET_BUY, confirmMessage, item.itemid .. ":" .. price .. ":" .. shiai .. ":" .. (offer and offer.userid or 0) .. ":" .. offer.offerid, true)
			end, "marketplace_purchase", function()
				Market:clearModal()
				local response = Market:parseGatewayResponse(get_network_response())
				local message = response.is_success and response.success or response.error
				if (response.is_success) then
					message = message .. (response.warning and ("\n" .. response.warning:gsub("(%w+)", "^37%1")) or '') .. (response.info and ("\n" .. response.info:gsub("(%w+)", "^39%1")) or '')

					if (offer) then
						offer.button:kill(true)
						offer.button:deactivate(true)
						local buttonText = UIElement:new({
							parent = offer.button,
							pos = { 10, 3 },
							size = { offer.button.size.w - 20, offer.button.size.h - 6 }
						})
						buttonText:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETITEMPURCHASED)
					end
				end

				update_tc_balance()
				TBMenu:showStatusMessage(message, 10)
				Market:clearModal()
			end, function()
				TBMenu:showStatusMessage(get_network_error())
				Market:clearModal()
			end)
	end

	function Market:displaySingleOfferDistinct(listingHolder, offer, height, idx, backAction)
		local item = Store:getItemInfo(offer.itemid)
		local offerView = listingHolder:addChild({
			pos = { 0, idx * height },
			size = { listingHolder.size.w, height }
		})
		local offerViewBG = UIElement:new({
			parent = offerView,
			pos = { 10, 2 },
			size = { offerView.size.w - 10, offerView.size.h - 4 },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		local offerItemIconHolder = offerViewBG:addChild({
			pos = { 10, 5 },
			size = { offerViewBG.size.h - 10, offerViewBG.size.h - 10 },
			bgImage = item:getIconPath()
		})
		local infoSpace = (offerViewBG.size.w - offerItemIconHolder.size.w - offerItemIconHolder.shift.x * 4) / 2
		local offerName = offerViewBG:addChild({
			pos = { offerItemIconHolder.size.w + offerItemIconHolder.shift.x * 2, 0 },
			size = { infoSpace, offerViewBG.size.h * 0.55 }
		})
		offerName:addAdaptedText(true, item.itemname, nil, nil, FONTS.MEDIUM, LEFTBOT, 0.9, 0.9)
		local offerCatName = offerName:addChild({
			pos = { 0, offerName.size.h + 2 },
			size = { offerName.size.w, offerViewBG.size.h - offerName.size.h - 2 },
			uiColor = { 1, 1, 1, 0.7 }
		})
		offerCatName:addAdaptedText(true, item.catname, nil, nil, FONTS.LMEDIUM, LEFT, 0.6)

		if (offer.count > 0) then
			local offersStartingAt = offerViewBG:addChild({
				pos = { offerName.shift.x + offerItemIconHolder.shift.x + offerName.size.w, 0 },
				size = { offerName.size.w, offerViewBG.size.h * 0.4 },
				uiColor = { 1, 1, 1, 0.7 }
			})
			offersStartingAt:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETPRICESTARTINGAT, nil, nil, FONTS.LMEDIUM, RIGHTBOT, 0.6)
			local offersPrices = offerViewBG:addChild({
				pos = { offersStartingAt.shift.x, offersStartingAt.size.h },
				size = { offersStartingAt.size.w, offerViewBG.size.h - offersStartingAt.size.h - 2 }
			})
			offersPrices:addAdaptedText(true, numberFormat(offer.price) .. " " .. TB_MENU_LOCALIZED.WORDTC, nil, nil, FONTS.MEDIUM, RIGHT)
		else
			local offersPrices = offerViewBG:addChild({
				pos = { offerName.shift.x + offerItemIconHolder.shift.x + offerName.size.w, 0 },
				size = { offerName.size.w, offerViewBG.size.h }
			})
			offersPrices:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETNOACTIVEOFFERS .. " " .. TB_MENU_LOCALIZED.MARKETOFFERS, nil, nil, FONTS.LMEDIUM, RIGHTMID, 0.8)
		end

		offerViewBG:addMouseUpHandler(function()
				Market:showItemPage(TBMenu.CurrentSection, item, backAction)
			end)

		return { offerView }
	end

	function Market:displaySingleOffer(viewElement, offer, height, idx, backAction, linkPage)
		local item = Store:getItemInfo(offer.itemid)
		local elements = {}
		local offerHolder = UIElement:new({
			parent = viewElement,
			pos = { 0, height * idx },
			size = { viewElement.size.w, height }
		})
		table.insert(elements, offerHolder)

		local offerBG = UIElement:new({
			parent = offerHolder,
			pos = { 10, 3 },
			size = { offerHolder.size.w - 10, offerHolder.size.h - 3 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		if (offerBG.shapeType == ROUNDED) then
			local offerBGExtra = UIElement:new({
				parent = offerBG,
				pos = { 0, offerBG.size.h - offerBG.rounded },
				size = { offerBG.size.w, offerBG.rounded },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			})
		end
		local itemIcon = UIElement:new({
			parent = offerBG,
			pos = { 10, 5 },
			size = { offerBG.size.h - 5, offerBG.size.h - 5 },
			bgImage = item:getIconPath()
		})

		-- Display offerBy first so we can use more space for item name
		local itemNameShift, itemNameWidth = itemIcon.size.w + itemIcon.shift.x * 2, (offerBG.size.w - itemIcon.size.w - itemIcon.shift.x * 3) / 2
		local offerBy = UIElement:new({
			parent = offerBG,
			pos = { itemNameShift + itemNameWidth + 5, 3 },
			size = { itemNameWidth - 10, offerBG.size.h * 0.6 },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = UICOLORWHITE,
			hoverColor = TB_MENU_DEFAULT_YELLOW,
			pressedColor = TB_MENU_DEFAULT_ORANGE
		})
		offerBy:addAdaptedText(true, TB_MENU_LOCALIZED.WORDBY .. " " .. offer.username, nil, nil, 4, nil, 0.65)
		local elementWidth = get_string_length(offerBy.dispstr[#offerBy.dispstr], offerBy.textFont) * offerBy.textScale
		local elementHeight = #offerBy.dispstr * getFontMod(offerBy.textFont) * 10 + 1
		offerBy:moveTo(offerBy.size.w - elementWidth, (offerBy.size.h - elementHeight) / 2, true)
		offerBy.size.w = elementWidth
		offerBy.size.h = elementHeight
		offerBy:addCustomDisplay(true, function()
				offerBy:uiText(TB_MENU_LOCALIZED.WORDBY .. " " .. offer.username, nil, nil, 4, nil, 0.65, nil, nil, offerBy:getButtonColor())
				if (offerBy.hoverState ~= nil and offerBy.hoverState ~= BTN_NONE) then
					set_mouse_cursor(1)
				end
			end)
		offerBy:addMouseHandlers(nil, function()
				Market:showUserShop(TBMenu.CurrentSection, offer.username, backAction)
			end)

		itemNameWidth = offerBG.size.w - itemNameShift - offerBy.size.w - 25
		local itemName = UIElement:new({
			parent = offerBG,
			pos = { itemNameShift, 3 },
			size = { itemNameWidth, offerBG.size.h * 0.6 },
			interactive = linkPage,
			bgColor = UICOLORWHITE,
			hoverColor = TB_MENU_DEFAULT_ORANGE,
			pressedColor = TB_MENU_DEFAULT_YELLOW
		})
		local itemNameText = item.itemname
		if (offer.flameid > 0) then
			itemNameText = offer.flame_body .. " " .. item.itemname .. ": " .. offer.flame_name .. " (" .. TB_MENU_LOCALIZED.STOREFLAMEID .. " " .. offer.flameid .. ")"
		end
		itemName:addAdaptedText(true, itemNameText, nil, nil, nil, LEFTMID)

		local extraDataShift = { x = 0, y = itemName.shift.y + itemName.size.h }
		local capsuleHeight = offerBG.size.h - itemName.shift.y - itemName.size.h
		if (itemName.textScale < 0.65) then
			itemName.size.h = offerBG.size.h - 3
			itemName.str = ''
			itemName:addAdaptedText(true, itemNameText, nil, nil, nil, LEFTMID)

			if (offer.games_played > 0 or offer.effectid > 0) then
				local additionalHolder = viewElement:addChild({
					pos = { 0, height * (idx + #elements) },
					size = { viewElement.size.w, height }
				})
				table.insert(elements, additionalHolder)

				offerBG = additionalHolder:addChild({
					pos = { 10, 0 },
					size = { offerHolder.size.w - 10, offerHolder.size.h },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				extraDataShift.y = offerBG.size.h * 0.3
				capsuleHeight = offerBG.size.h * 0.4
			end
		end

		itemName.size.w = 0
		for i = 1, #itemName.dispstr do
			local lineWidth = get_string_length(itemName.dispstr[i], itemName.textFont) * itemName.textScale + 1
			itemName.size.w = lineWidth > itemName.size.w and lineWidth or itemName.size.w
		end
		itemName:addCustomDisplay(true, function()
				itemName:uiText(itemName.str, nil, nil, itemName.textFont, LEFTMID, itemName.textScale, nil, nil, itemName:getButtonColor())
				if (itemName.hoverState ~= nil and itemName.hoverState ~= BTN_NONE) then
					set_mouse_cursor(1)
				end
			end)
		itemName:addMouseHandlers(nil, function()
				Market:showItemPage(TBMenu.CurrentSection, item, backAction)
			end)

		if (offer.games_played > 0) then
			local gamesPlayed = UIElement:new({
				parent = offerBG,
				pos = { itemIcon.size.w + itemIcon.shift.x * 2 + extraDataShift.x, extraDataShift.y },
				size = { itemName.size.w, capsuleHeight },
				shapeType = ROUNDED,
				rounded = itemName.size.h,
				bgColor = { 0.6, 0.6, 0.6, 1 }
			})
			gamesPlayed:addAdaptedText(false, offer.games_played .. " " .. TB_MENU_LOCALIZED.WORDGAMES:gsub("^%l", string.upper), nil, nil, 4, nil, 0.65)
			gamesPlayed.size.w = get_string_length(gamesPlayed.str, gamesPlayed.textFont) * gamesPlayed.textScale + 20
			extraDataShift.x = extraDataShift.x + gamesPlayed.size.w + 5
			local popupHolder = UIElement:new({
				parent = gamesPlayed,
				pos = { 0, 0 },
				size = { gamesPlayed.size.w, gamesPlayed.size.h }
			})
			local popup = TBMenu:displayPopup(popupHolder, TB_MENU_LOCALIZED.MARKETGAMESPLAYEDINFO, true)
			if (popup ~= nil) then
				popup:moveTo(nil, -popup.size.h - 5, true)
				popup:moveTo(popupHolder.size.w > popup.size.w and (popupHolder.size.w - popup.size.w) / 2 or -popupHolder.size.w - (popup.size.w - popupHolder.size.w) / 2)
			end
		end
		local effectsHolder = offerBG:addChild({
			pos = { itemIcon.size.w + itemIcon.shift.x * 2 + extraDataShift.x, extraDataShift.y },
			size = { offerBG.size.w - itemIcon.size.w - itemIcon.shift.x * 3 - extraDataShift.x, capsuleHeight }
		})
		Store:showItemEffectCapsules(offer, effectsHolder, capsuleHeight)

		if (offer.username:lower() == TB_MENU_PLAYER_INFO.username:lower()) then
			-- This is current user's offer, we show sell price and what they'll get
			local priceHolder = UIElement:new({
				parent = viewElement,
				pos = { 0, height * (idx + #elements) },
				size = { viewElement.size.w, height }
			})
			table.insert(elements, priceHolder)

			local priceHolderBG = UIElement:new({
				parent = priceHolder,
				pos = { 10, 0 },
				size = { offerBG.size.w, offerHolder.size.h },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			})

			local priceText = UIElement:new({
				parent = priceHolderBG,
				pos = { 15, 3 },
				size = { priceHolderBG.size.w - 30, priceHolderBG.size.h - 6 }
			})

			local priceTextUser
			if (offer.offertype == OFFER_SALE and MARKET_SHOP_DATA[TB_MENU_PLAYER_INFO.username:lower()].tier == TIER_REGULAR) then
				priceText.size.h = priceText.size.h / 2
				priceTextUser = UIElement:new({
					parent = priceText,
					pos = { 0, priceText.size.h },
					size = { priceText.size.w, priceText.size.h }
				})
			end
			local triggerPriceUpdate = function()
				if (offer.offertype == OFFER_SALE and MARKET_SHOP_DATA[TB_MENU_PLAYER_INFO.username:lower()].tier == TIER_REGULAR) then
					priceText:addAdaptedText(true, numberFormat(offer.price) .. " " .. TB_MENU_LOCALIZED.WORDTC, nil, nil, nil, CENTERBOT)
					priceTextUser:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETOFFERYOUGET .. " " .. numberFormat(math.floor(offer.price / (1 + MARKET_TAX) + 0.5)) .. " " .. TB_MENU_LOCALIZED.WORDTC, nil, nil, 4, CENTER, 0.7)
				else
					priceText:addAdaptedText(true, numberFormat(offer.price) .. " " .. TB_MENU_LOCALIZED.WORDTC)
				end
			end
			triggerPriceUpdate()
			offer.triggerPriceUpdate = triggerPriceUpdate
		end

		local offerHolder2 = UIElement:new({
			parent = viewElement,
			pos = { 0, height * (idx + #elements) },
			size = { viewElement.size.w, height }
		})
		table.insert(elements, offerHolder2)

		local offerBG2 = UIElement:new({
			parent = offerHolder2,
			pos = { 10, 0 },
			size = { offerBG.size.w, offerHolder.size.h - 3 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = offerBG.shapeType,
			rounded = offerBG.rounded
		})
		if (offerBG2.shapeType == ROUNDED) then
			local offerBG2Extra = UIElement:new({
				parent = offerBG2,
				pos = { 0, 0 },
				size = { offerBG2.size.w, offerBG2.rounded },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			})
		end
		local actionButton = UIElement:new({
			parent = offerBG2,
			pos = { 10, 5 },
			size = { offerBG2.size.w - 20, offerBG2.size.h - 12 },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
			shapeType = ROUNDED,
			rounded = 4
		})
		local actionButtonText = UIElement:new({
			parent = actionButton,
			pos = { 10, 3 },
			size = { actionButton.size.w - 20, actionButton.size.h - 6 }
		})

		local popupText = ''
		if (item.price ~= 0 or item.price_usd ~= 0) then
			local discountValue = item.price ~= 0 and (math.floor(10000 - (offer.price / item.price) * 10000) / 100) or 0
			if (discountValue ~= 0) then
				if (discountValue > 0) then
					popupText = discountValue .. "% " .. TB_MENU_LOCALIZED.MARKETCHEAPERTHANSTORE .. "\n"
				else
					popupText = -discountValue .. "% " .. TB_MENU_LOCALIZED.MARKETMOREEXPENSIVETHANSTORE .. "\n"
				end
			end
			popupText = popupText .. TB_MENU_LOCALIZED.MARKETSTOREPRICE .. ": " .. (item.price ~= 0 and (numberFormat(item.price) .. " " .. TB_MENU_LOCALIZED.WORDTC) or '') .. ((item.price ~= 0 and item.price_usd ~= 0) and " | " or '') .. (item.price_usd ~= 0 and (item.price_usd .. " " .. TB_MENU_LOCALIZED.WORDST) or '')
		end

		if (offer.offertype == OFFER_SALE) then
			local popupTextExtra = ''
			if (TB_MENU_PLAYER_INFO.data.qi < item.qi) then
				if (offer.shiai == 0) then
					popupTextExtra = TB_MENU_LOCALIZED.MARKETBELTREQUIREMENT:gsub("(%w+)", '^71%1')
				elseif (TB_MENU_PLAYER_INFO.data.st < offer.shiai) then
					popupTextExtra = TB_MENU_LOCALIZED.MARKETBELTSHIAIREQUIREMENT:gsub("(%w+)", '^71%1')
				else
					popupTextExtra = TB_MENU_LOCALIZED.MARKETSHIAIEXPLANATION:gsub("(%w+)", '^39%1')
				end
			end
			if (TB_MENU_PLAYER_INFO.data.tc < offer.price and offer.username:lower() ~= TB_MENU_PLAYER_INFO.username:lower()) then
				popupTextExtra = TB_MENU_LOCALIZED.MARKETINSUFFICIENTFUNDS:gsub("(%w+)", '^71%1') .. "\n" .. popupTextExtra
			end
			if (popupTextExtra ~= '') then
				popupText = popupTextExtra .. (popupText == '' and '' or ("\n\n" .. popupText))
			end
		end

		if (popupText ~= '') then
			local popup = TBMenu:displayPopup(actionButton, popupText)
			if (popup ~= nil) then
				popup:moveTo(actionButton.size.w > popup.size.w and (actionButton.size.w - popup.size.w) / 2 or -actionButton.size.w - (popup.size.w - actionButton.size.w) / 2, actionButton.size.h + 5)
			end
		end

		offer.button = actionButton
		if (offer.username:lower() == TB_MENU_PLAYER_INFO.username:lower()) then
			actionButtonText:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETMODIFYOFFER)
			actionButton:addMouseHandlers(nil, function()
					if (offer.offertype == OFFER_SALE) then
						local selectedItem = offer
						selectedItem.item = item
						selectedItem.marketPrice = math.floor(offer.price / (1 + MARKET_TAX) + 0.5)
						selectedItem.inventid = offer.offerid
						Market:spawnPriceSetModal({ selectedItem }, nil, offer)
					else
						Market:spawnModifyPurchaseOfferModal(offer)
					end
				end)
		elseif (offer.offertype == OFFER_SALE) then
			if (not offer.affordable) then
				actionButton:deactivate(true)
			end
			actionButtonText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREBUYFOR .. " " .. numberFormat(offer.price) .. " " .. TB_MENU_LOCALIZED.WORDTC .. (offer.shiai > 0 and (" ^39+ " .. offer.shiai .. " " .. TB_MENU_LOCALIZED.WORDST) or ""))
			actionButton:addMouseHandlers(nil, function()
					Market:spawnPurchaseModal(offer, item, offer.price, offer.shiai)
				end)
		else
			actionButtonText:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETSELLFOR .. " " .. numberFormat(offer.price) .. " " .. TB_MENU_LOCALIZED.WORDTC)
			actionButton:addMouseHandlers(nil, function()
					Market:spawnInventoryItemSelector(item, nil, offer)
				end)
		end

		offerBG:addCustomDisplay(false, function()
				if (offerBG2.hoverState ~= offerBG.hoverState and offerBG2:isDisplayed()) then
					if (offerBG.hoverState > offerBG2.hoverState) then
						offerBG2.hoverState = offerBG.hoverState
						offerBG2.hoverClock = offerBG.hoverClock
					else
						offerBG.hoverState = offerBG2.hoverState
						offerBG.hoverClock = offerBG2.hoverClock
					end
				end
			end, true)
		return elements
	end

	function Market:showSearchBar(searchString, searchOptions, hint)
		local searchInput, searchBarView = TBMenu:spawnSearchBar(searchString, hint or TB_MENU_LOCALIZED.STORESEARCHHINT)
		searchInput:addInputCallback(function()
				if (searchBarView.dropdown) then
					searchBarView.dropdown:kill()
					searchBarView.options = nil
					searchBarView.hasCategories = false
				end

				local searchResults = Market:searchItemsByString(searchInput.textfieldstr[1], true)
				if (not searchResults) then
					return
				end

				local dropdownList = {}
				if (searchResults.categories) then
					for i,v in pairs(table.qsort(searchResults.categories, 'name')) do
						table.insert(dropdownList, {
							text = TB_MENU_LOCALIZED.MARKETITEMCATEGORY .. ": " .. v.name,
							action = function()
								Market:showSearchOffers(TBMenu.CurrentSection, v.name, searchOptions or { distinct = 1 })
							end
						})
						searchBarView.hasCategories = true
					end
				end
				if (searchResults.items) then
					for i,v in pairs(table.qsort(searchResults.items, 'itemname')) do
						table.insert(dropdownList, {
							text = v.itemname,
							action = function() Market:showItemPage(TBMenu.CurrentSection, v) end
						})
					end
				end
				if (#dropdownList == 0) then
					return
				end

				searchBarView.options = dropdownList
				searchBarView.dropdown = TBMenu:spawnDropdown(searchBarView, dropdownList, searchBarView.size.h * 0.8, WIN_H / 2, { text = '' }, nil, { scale = 0.65, fontid = 4 }, true, true, true)
				searchBarView.dropdown.selectedElement:hide(true)
				searchBarView.dropdown.selectedElement.btnUp()
			end)

		searchInput:addEnterAction(function(inputText)
				if (searchBarView.dropdown) then
					searchBarView.dropdown:kill()
				end
				local showDistinct = searchBarView.hasCategories and 1 or 0
				if (showDistinct == 0) then
					showDistinct = searchBarView.options and (#searchBarView.options > 1 and 1 or 0) or 0
				end
				Market:showSearchOffers(TBMenu.CurrentSection, inputText, searchOptions or { distinct = showDistinct })
			end)
	end

	function Market:displayOffers(viewElement, offers, title, itemBackAction, linkPage)
		viewElement:kill(true)

		if (#offers == 0) then
			local titleView = viewElement:addChild({
				pos = { 15, 5 },
				size = { viewElement.size.w - 30, 45 }
			})
			titleView:addAdaptedText(true, title, nil, nil, FONTS.BIG)
			local noOffersMessage = viewElement:addChild({
				shift = { 15, viewElement.size.h / 3 }
			})
			noOffersMessage:addAdaptedText(true, TB_MENU_LOCALIZED.NOTHINGTOSHOW)
			TBMenu:addBottomBloodSmudge(viewElement, viewElement.idx)
			return
		end

		local elementHeight = math.clamp(WIN_H / 17, 60, 82)
		local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(viewElement, elementHeight, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

		local titleView = topBar:addChild({
			pos = { 15, 5 },
			size = { topBar.size.w - 30, topBar.size.h - 10 }
		})
		titleView:addAdaptedText(true, title, nil, nil, FONTS.BIG, nil, 0.7, nil, 0.5)

		local listElements = {}
		if (#offers * 2 * elementHeight <= listingHolder.size.w) then
			listingHolder.size.w = listingHolder.size.w + 10
		end
		for _, offer in pairs(offers) do
			local elements = offer.count ~= 1 and Market:displaySingleOfferDistinct(listingHolder, offer, elementHeight, #listElements, itemBackAction) or Market:displaySingleOffer(listingHolder, offer, elementHeight, #listElements, itemBackAction, linkPage)
			for _, element in pairs(elements) do
				table.insert(listElements, element)
			end
		end

		if (#listElements * elementHeight > listingHolder.size.h) then
			for _, v in pairs(listElements) do
				v:hide()
			end
			local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
			listingHolder.scrollBar = scrollBar
			scrollBar:makeScrollBar(listingHolder, listElements, toReload)
		end

		TBMenu:addBottomBloodSmudge(botBar, viewElement.idx)
	end

	---Displays item information page with available offers
	---@param viewElement UIElement
	---@param item StoreItem
	---@param backAction function?
	---@overload fun(self: Market, viewElement: UIElement, item: integer, backAction: function?)
	function Market:showItemPage(viewElement, item, backAction)
		if (type(item) == "number") then
			item = Store:getItemInfo(item)
		end
		if (not item or item.itemid == nil or item.itemid == 0) then
			return
		end

		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Market:getSectionNavButtons(viewElement, backAction), true)
		Market:showSearchBar()

		local itemView = viewElement:addChild({
			pos = { 5, 0 },
			size = { math.min(375, viewElement.size.w / 7 * 2), math.max(viewElement.size.h / 5 * 2, viewElement.size.h - 280)},
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local itemName = itemView:addChild({
			pos = { 10, 7 },
			size = { itemView.size.w - 20, 35 }
		})
		itemName:addAdaptedText(true, item.itemname, nil, nil, FONTS.BIG)
		local itemCategory = itemView:addChild({
			pos = { 10, itemName.size.h + itemName.shift.y + 2 },
			size = { itemView.size.w - 20, 14 },
			uiColor = { 1, 1, 1, 0.7 }
		})
		itemCategory:addAdaptedText(true, item.catname, nil, nil, 4, RIGHTMID)

		local shiftY = itemCategory.shift.y + itemCategory.size.h + 5
		local itemDescription
		if (itemView.size.h > 200) then
			itemDescription = itemView:addChild({
				pos = { 80, shiftY },
				size = { itemView.size.w - 90, math.min((itemView.size.h - shiftY - 10) * 0.6, itemView.size.h - shiftY - 90) }
			})
			itemDescription:addAdaptedText(true, item.description, nil, nil, 4, LEFT, 0.65, 0.55)

			local descHeight = #itemDescription.dispstr * getFontMod(itemDescription.textFont) * 10 * itemDescription.textScale
			if (descHeight < itemDescription.size.h) then
				itemDescription.size.h = math.clamp(itemDescription.size.h, 64, descHeight + 1)
			end
			shiftY = itemDescription.shift.y + (itemDescription.size.h - 64) / 2
		end

		local itemIconFilePath = item:getIconPath()
		local itemIcon = itemView:addChild({
			pos = { 10, shiftY },
			size = { 64, 64 },
			bgImage = itemIconFilePath
		})
		if (not Files.Exists(itemIconFilePath)) then
			Store:addIconToDownloadQueue(item, itemIconFilePath, itemIcon)
		end

		local shiftX = itemIcon.shift.x
		if (itemDescription == nil) then
			shiftX = shiftX + itemIcon.size.w + itemIcon.shift.x
		else
			shiftY = itemDescription.shift.y + itemDescription.size.h + 10
		end
		local dataHeight = itemView.size.h - shiftY
		local beltInfo = PlayerInfo.getBeltFromQi(item.qi)
		local beltRestriction = UIElement:new({
			parent = itemView,
			pos = { shiftX, shiftY },
			size = { itemView.size.w - shiftX - itemIcon.shift.x, math.min(dataHeight / 4, 45) },
			uiColor = { 1, 1, 1, 0.85 }
		})
		beltRestriction:addAdaptedText(true, TB_MENU_LOCALIZED.BELTRESTRICTION .. ":___" .. beltInfo.name .. " (" .. numberFormat(item.qi) .. " Qi)", nil, nil, 4, LEFTMID, 0.7)
		beltRestriction:addAdaptedText(true, TB_MENU_LOCALIZED.BELTRESTRICTION .. ":", nil, nil, 4, LEFTMID, beltRestriction.textScale, beltRestriction.textScale)
		beltRestriction.size.w = get_string_length(beltRestriction.dispstr[1], beltRestriction.textFont) * beltRestriction.textScale
		local beltIcon = UIElement:new({
			parent = beltRestriction,
			pos = { beltRestriction.size.w + 5, 0 },
			size = { beltRestriction.size.h, beltRestriction.size.h },
			bgImage = beltInfo.icon
		})
		local beltRestrictionText = UIElement:new({
			parent = beltRestriction,
			pos = { beltRestriction.size.w + beltIcon.size.w + 10, 0 },
			size = { itemView.size.w - 30 - beltRestriction.size.w - beltIcon.size.w, beltRestriction.size.h },
			uiColor = { 1, 1, 1, 1 }
		})
		beltRestrictionText:addAdaptedText(true, beltInfo.name .. " (" .. numberFormat(item.qi) .. " Qi)", nil, nil, 4, LEFTMID, beltRestriction.textScale)
		while (#beltRestrictionText.dispstr > 1 and beltRestrictionText.textScale > 0.5) do
			beltRestrictionText:addAdaptedText(true, beltRestrictionText.str, nil, nil, 4, LEFTMID, beltRestrictionText.textScale - 0.05)
		end

		local extraDataHeight = math.min(dataHeight / 4 * 3 - 10, 80)
		local extraData = itemView:addChild({
			pos = { shiftX, itemView.size.h - extraDataHeight - 10 },
			size = { itemView.size.w - shiftX - itemIcon.shift.x, extraDataHeight }
		})
		TBMenu:displayLoadingMarkSmall(extraData, TB_MENU_LOCALIZED.MARKETLOADINGDATA, 4, 25, 0.75)

		local bestSaleOfferView = UIElement:new({
			parent = viewElement,
			pos = { 5, itemView.size.h + 10 },
			size = { itemView.size.w, (viewElement.size.h - itemView.size.h - 15) / 2 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local bestSaleOfferText = UIElement:new({
			parent = bestSaleOfferView,
			pos = { 15, bestSaleOfferView.size.h / 10 },
			size = { bestSaleOfferView.size.w - 30, bestSaleOfferView.size.h * 0.3 - 10 }
		})
		bestSaleOfferText:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETLOADINGPRICES, nil, nil, 4, CENTERBOT, 0.8)

		local maxButtonWidth = math.max(300, bestSaleOfferView.size.w * 0.6)
		local bestSaleOfferButton = UIElement:new({
			parent = bestSaleOfferView,
			pos = { (bestSaleOfferView.size.w - maxButtonWidth) / 2, bestSaleOfferText.shift.y * 2 + bestSaleOfferText.size.h },
			size = { maxButtonWidth, math.min(55, bestSaleOfferView.size.h - bestSaleOfferText.size.h - bestSaleOfferText.shift.y * 3) },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
			shapeType = ROUNDED,
			rounded = 4
		})
		bestSaleOfferButton:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETPURCHASE)
		bestSaleOfferButton:deactivate()

		local bestBuyRequestView = UIElement:new({
			parent = viewElement,
			pos = { 5, bestSaleOfferView.shift.y + bestSaleOfferView.size.h + 10 },
			size = { bestSaleOfferView.size.w, bestSaleOfferView.size.h - 5 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(bestBuyRequestView, 1)
		local bestBuyRequestText = UIElement:new({
			parent = bestBuyRequestView,
			pos = { 15, (bestBuyRequestView.size.h + 10) / 10 },
			size = { bestBuyRequestView.size.w - 30, (bestBuyRequestView.size.h + 5) * 0.3 - 10 }
		})
		bestBuyRequestText:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETLOADINGPRICES, nil, nil, 4, CENTERBOT, 0.8)
		local bestBuyRequestButton = UIElement:new({
			parent = bestBuyRequestView,
			pos = { bestSaleOfferButton.shift.x, bestSaleOfferButton.shift.y },
			size = { bestSaleOfferButton.size.w, bestSaleOfferButton.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
			shapeType = ROUNDED,
			rounded = 4
		})
		bestBuyRequestButton:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETSELL)
		bestBuyRequestButton:deactivate()

		local saleOffersView = UIElement:new({
			parent = viewElement,
			pos = { itemView.size.w + 15, 0 },
			size = { (viewElement.size.w - itemView.size.w - 30) / 2, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		saleOffersView.idx = 2
		TBMenu:addBottomBloodSmudge(saleOffersView, 2)
		TBMenu:displayLoadingMark(saleOffersView, TB_MENU_LOCALIZED.MARKETLOADINGOFFERS)

		local purchaseOffersView = UIElement:new({
			parent = viewElement,
			pos = { saleOffersView.shift.x + saleOffersView.size.w + 10, 0 },
			size = { saleOffersView.size.w, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		purchaseOffersView.idx = 3
		TBMenu:addBottomBloodSmudge(purchaseOffersView, 3)
		TBMenu:displayLoadingMark(purchaseOffersView, TB_MENU_LOCALIZED.MARKETLOADINGOFFERS)

		local displayRemainingData = function(itemData)
			if (not extraData or extraData.destroyed) then
				return
			end
			extraData:kill()

			local itemCount = extraData:addChild({
				pos = { 0, 0 },
				size = { extraData.size.w * 0.6, extraData.size.h / 3 },
				uiColor = { 1, 1, 1, 0.85 }
			})
			itemCount:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETITEMSTOTAL .. ":", nil, nil, 4, LEFTMID, 0.7)
			local itemOwnedBy = extraData:addChild({
				pos = { itemCount.shift.x, itemCount.size.h + itemCount.shift.y },
				size = { itemCount.size.w, itemCount.size.h },
				uiColor = { 1, 1, 1, 0.85 }
			})
			itemOwnedBy:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETOWNEDBY .. ":", nil, nil, 4, LEFTMID, 0.7)
			local itemTraded = extraData:addChild({
				pos = { itemCount.shift.x, itemCount.size.h + itemOwnedBy.shift.y },
				size = { itemCount.size.w, itemCount.size.h },
				uiColor = { 1, 1, 1, 0.85 },
			})
			itemTraded:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETRECENTLYTRADED .. ":", nil, nil, 4, LEFTMID, 0.7)
			if (itemCount.textScale ~= itemOwnedBy.textScale or itemCount.textScale ~= itemTraded.textScale) then
				local targetScale = math.min(itemCount.textScale, itemOwnedBy.textScale, itemTraded.textScale)
				itemCount:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETITEMSTOTAL .. ":", nil, nil, 4, LEFTMID, targetScale)
				itemOwnedBy:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETOWNEDBY .. ":", nil, nil, 4, LEFTMID, targetScale)
				itemTraded:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETRECENTLYTRADED .. ":", nil, nil, 4, LEFTMID, targetScale)
			end

			local itemCountVal = itemCount:addChild({
				pos = { itemCount.size.w + 5, 0 },
				size = { extraData.size.w - itemCount.size.w - 5, itemCount.size.h },
				uiColor = UICOLORWHITE
			})
			itemCountVal:addAdaptedText(true, (itemData.count and numberFormat(itemData.count) or 0) .. " " .. TB_MENU_LOCALIZED.WORDITEMS, nil, nil, itemCount.textFont, RIGHTMID, itemCount.textScale)
			local itemOwnedByVal = itemOwnedBy:addChild({
				pos = { itemOwnedBy.size.w + 5, 0 },
				size = { itemCountVal.size.w, itemOwnedBy.size.h },
				uiColor = UICOLORWHITE
			})
			itemOwnedByVal:addAdaptedText(true, (itemData.ownedby and numberFormat(itemData.ownedby) or 0) .. " " .. TB_MENU_LOCALIZED.WORDPLAYERS, nil, nil, itemOwnedBy.textFont, RIGHTMID, itemOwnedBy.textScale)
			local itemTradedVal = itemTraded:addChild({
				pos = { itemTraded.size.w + 5, 0 },
				size = { itemCountVal.size.w, itemTraded.size.h },
				uiColor = UICOLORWHITE
			})
			itemTradedVal:addAdaptedText(true, (itemData.traded and numberFormat(itemData.traded) or 0) .. " " .. TB_MENU_LOCALIZED.WORDITEMS, nil, nil, itemTraded.textFont, RIGHTMID, itemTraded.textScale)


			local sellOffers = #itemData.offers.sale
			if (sellOffers > 0) then
				bestSaleOfferText:addAdaptedText(true, sellOffers .. " " .. TB_MENU_LOCALIZED.MARKETSALEOFFERSSTARTINGAT .. " " .. numberFormat(itemData.offers.sale[1].price) .. " " .. TB_MENU_LOCALIZED.WORDTC, nil, nil, 4, CENTERBOT, 0.8)
				bestSaleOfferButton:addMouseHandlers(nil, function()
						Market:spawnPurchaseModalInput(item)
					end)
			else
				bestSaleOfferText:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETNOACTIVEOFFERS .. " " .. string.lower(TB_MENU_LOCALIZED.MARKETSALEOFFERS), nil, nil, 4, CENTERBOT, 0.8)
				bestSaleOfferButton:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETNEWPURCHASEOFFER)
			end

			bestSaleOfferButton:activate()
			if (item.qi > TB_MENU_PLAYER_INFO.data.qi) then
				bestSaleOfferButton:deactivate()
				local popupHolder = UIElement:new({
					parent = bestSaleOfferButton,
					pos = { 0, 0 },
					size = { bestSaleOfferButton.size.w, bestSaleOfferButton.size.h },
					interactive = true
				})
				local popup = TBMenu:displayPopup(popupHolder, TB_MENU_LOCALIZED.MARKETBELTREQUIREMENT .. "\n\n" .. TB_MENU_LOCALIZED.MARKETSHIAIEXPLANATION:gsub("(%w+)", '^39%1'))
				if (popup ~= nil) then
					popup:moveTo(-popupHolder.size.w - (popup.size.w - popupHolder.size.w) / 2, popupHolder.size.h + 5)
				end
			end

			local buyOffers = #itemData.offers.purchase
			if (buyOffers > 0) then
				bestBuyRequestText:addAdaptedText(true, buyOffers .. " " .. TB_MENU_LOCALIZED.MARKETBUYREQUESTSSTARTINGAT .. " " .. numberFormat(itemData.offers.purchase[1].price) .. " " .. TB_MENU_LOCALIZED.WORDTC, nil, nil, 4, CENTERBOT, 0.8)
				bestBuyRequestButton:addMouseHandlers(nil, function()
						Market:spawnInventoryItemSelector(item)
					end)
			else
				bestBuyRequestText:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETNOACTIVEOFFERS .. " " .. string.lower(TB_MENU_LOCALIZED.MARKETPURCHASEREQUESTS), nil, nil, 4, CENTERBOT, 0.8)
				bestBuyRequestButton:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETNEWSALEOFFER)
				bestBuyRequestButton:addMouseHandlers(nil, function()
						Market:spawnInventoryItemSelector(item)
					end)
			end

			local sellItems = Market:searchItemsInventory(item)
			if (#sellItems > 0) then
				bestBuyRequestButton:activate()
			else
				local popup = TBMenu:displayPopup(bestBuyRequestButton, TB_MENU_LOCALIZED.MARKETINVENTORYEMPTY, true)
				if (popup ~= nil) then
					popup:moveTo(nil, -popup.size.h - 5, true)
					popup:moveTo(popup.size.w > popup.parent.size.w and -popup.size.w + (popup.size.w - popup.parent.size.w) / 2 or (popup.parent.size.w - popup.size.w) / 2)
				end
			end

			Market:displayOffers(saleOffersView, itemData.offers.sale, TB_MENU_LOCALIZED.MARKETSALEOFFERS, function() Market:showItemPage(viewElement, item, backAction) end)
			Market:displayOffers(purchaseOffersView, itemData.offers.purchase, TB_MENU_LOCALIZED.MARKETPURCHASEREQUESTS, function() Market:showItemPage(viewElement, item, backAction) end)
		end

		Request:queue(function()
				download_market_info("item=" .. item.itemid)
			end, "marketplace_item", function()
				local response = get_network_response()
				local itemData = { offers = Market:parseOffersData(response) }
				for ln in response:gmatch("[^\n]+\n?") do
					local cleanedValue = ln:gsub("[^;]+;([^\n]*)\n?$", "%1")
					if (ln:find("^COUNT")) then
						itemData.count = tonumber(cleanedValue)
					elseif (ln:find("^OWNED")) then
						itemData.ownedby = tonumber(cleanedValue)
					elseif (ln:find("^TRADED")) then
						itemData.traded = tonumber(cleanedValue)
						break -- This is the last line we need, no need to keep cycling through lines
					end
				end
				displayRemainingData(itemData)
			end, function()
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REQUESTCONNECTIONERROR .. "\n" .. get_network_error())
			end)
	end

	function Market:showSearchOffers(viewElement, search, options)
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Market:getSectionNavButtons(viewElement), true)

		local options = options or {}
		local elementHeight = 45
		local searchFilters = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { math.min(350, viewElement.size.w / 3), viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})

		local offersHolderGeneral = UIElement:new({
			parent = viewElement,
			pos = { searchFilters.size.w + 10, 0 },
			size = { viewElement.size.w - searchFilters.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:displayLoadingMark(offersHolderGeneral, TB_MENU_LOCALIZED.MARKETLOADINGOFFERS)
		TBMenu:addBottomBloodSmudge(offersHolderGeneral, 2)

		local saleOffersHolder = UIElement:new({
			parent = viewElement,
			pos = { offersHolderGeneral.shift.x, 0 },
			size = { offersHolderGeneral.size.w / 2 - 5, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local purchaseOffersHolder = UIElement:new({
			parent = viewElement,
			pos = { saleOffersHolder.shift.x + saleOffersHolder.size.w + 10, 0 },
			size = { saleOffersHolder.size.w, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})

		local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(searchFilters, elementHeight, math.max(elementHeight, 60), 20, TB_MENU_DEFAULT_BG_COLOR)

		local searchFiltersText = topBar:addChild({
			shift = { 15, 5 }
		})
		searchFiltersText:addAdaptedText(true, TB_MENU_LOCALIZED.GENERALSEARCHFILTERS, nil, nil, FONTS.BIG)

		local filterOptions = {
			{ val = 'search', name = TB_MENU_LOCALIZED.STORESEARCHHINT, search = search, text = true, value = search:gsub(" ", "+") },
			{ val = 'minqi', name = TB_MENU_LOCALIZED.SEARCHFILTERMINQI, default = TB_MENU_PLAYER_INFO.data.qi, defaultName = TB_MENU_LOCALIZED.SEARCHFILTERDEFAULTMYQI, value = options.minqi },
			{ val = 'maxqi', name = TB_MENU_LOCALIZED.SEARCHFILTERMAXQI, default = TB_MENU_PLAYER_INFO.data.qi, defaultName = TB_MENU_LOCALIZED.SEARCHFILTERDEFAULTMYQI, value = options.maxqi },
			{ val = 'minprice', name = TB_MENU_LOCALIZED.SEARCHFILTERMINPRICE, default = TB_MENU_PLAYER_INFO.data.tc, defaultName = TB_MENU_LOCALIZED.SEARCHFILTERDEFAULTMYTC, value = options.minprice },
			{ val = 'maxprice', name = TB_MENU_LOCALIZED.SEARCHFILTERMAXPRICE, default = TB_MENU_PLAYER_INFO.data.tc, defaultName = TB_MENU_LOCALIZED.SEARCHFILTERDEFAULTMYTC, value = options.maxprice },
			{ val = 'shopuser', name = TB_MENU_LOCALIZED.SEARCHFILTERSMARKETUSER, text = true, value = options.shopuser }
		}
		table.insert(filterOptions, { val = 'limit', name = TB_MENU_LOCALIZED.SEARCHFILTERLIMIT,
			options = { 10, 25, 50, 100 },
			action = function(id, val) filterOptions[7].value = val end,
			value = options.limit or 25
		})

		for i,v in pairs(filterOptions[#filterOptions].options) do
			if (v == filterOptions[#filterOptions].value) then
				filterOptions[#filterOptions].defaultId = i
				break
			end
			if (v > filterOptions[#filterOptions].value) then
				table.insert(filterOptions[#filterOptions].options, i, filterOptions[#filterOptions].value)
				filterOptions[#filterOptions].defaultId = i
				break
			end
		end
		if (filterOptions[#filterOptions].defaultId == nil) then
			table.insert(filterOptions[#filterOptions].options, filterOptions[#filterOptions].value)
			filterOptions[#filterOptions].defaultId = #filterOptions[#filterOptions].options
		end

		table.insert(filterOptions, { val = 'order', name = TB_MENU_LOCALIZED.SEARCHFILTERORDER, options = {
				TB_MENU_LOCALIZED.SEARCHFILTERORDERPRICE,
				TB_MENU_LOCALIZED.SEARCHFILTERORDERPRICEDESC,
				TB_MENU_LOCALIZED.SEARCHFILTERORDERDATE,
				TB_MENU_LOCALIZED.SEARCHFILTERORDERDATEDESC
			},
			action = function(id, val) filterOptions[8].value = id - 1 end,
			value = options.order or 0
		})
		table.insert(filterOptions, { val = 'distinct', name = TB_MENU_LOCALIZED.MARKETSEARCHGROUPBYITEM, options = {
				TB_MENU_LOCALIZED.SETTINGSENABLED,
				TB_MENU_LOCALIZED.SETTINGSDISABLED
			},
			action = function(id, val) filterOptions[9].value = 2 - id end,
			defaultId = options.distinct and (2 - options.distinct) or 2,
			value = options.distinct or 0
		})

		local handleResponse = function()
			if (not offersHolderGeneral or offersHolderGeneral.destroyed) then
				return
			end

			local response = get_network_response()
			saleOffersHolder:kill(true)
			purchaseOffersHolder:kill(true)
			offersHolderGeneral:kill(true)

			if (response:len() == 0) then
				offersHolderGeneral:show()
				saleOffersHolder:hide()
				purchaseOffersHolder:hide()

				local errorDisplay = UIElement:new({
					parent = offersHolderGeneral,
					pos = { offersHolderGeneral.size.w / 5, offersHolderGeneral.size.h / 3 },
					size = { offersHolderGeneral.size.w * 0.6, offersHolderGeneral.size.h / 3 }
				})
				errorDisplay:addAdaptedText(true, TB_MENU_LOCALIZED.NOTHINGTOSHOW)
				TBMenu:addBottomBloodSmudge(offersHolderGeneral, 2)
				return
			end

			offersHolderGeneral:hide()
			saleOffersHolder:show()
			purchaseOffersHolder:show()

			local offers = Market:parseOffersData(response)
			local filterValues = {}
			for _, v in pairs(filterOptions) do
				filterValues[v.val] = v.value
			end

			if (filterValues.distinct == 1 and #offers.sale < filterValues.limit) then
				for _, v in pairs(Market:searchItemsByString(filterValues.search)) do
					if (#offers.sale >= filterValues.limit) then
						break
					end
					if (v.qi < 50000 and (not filterValues.minqi or (tonumber(filterValues.minqi) or 0) <= v.qi) and (not filterValues.maxqi or (tonumber(filterValues.maxqi) or 0) >= v.qi)) then
						local itemHasOffer = false
						for j,k in pairs(offers.sale) do
							if (k.itemid == v.itemid) then
								itemHasOffer = true
								break
							end
						end

						if (not itemHasOffer) then
							table.insert(offers.sale, {
								offerid = -1,
								offertype = OFFER_SALE,
								count = 0,
								itemid = v.itemid
							})
						end
					end
				end
			end

			Market:displayOffers(saleOffersHolder, offers.sale, TB_MENU_LOCALIZED.MARKETSALEOFFERS, function() Market:showSearchOffers(viewElement, filterValues.search, filterValues) end, true)
			Market:displayOffers(purchaseOffersHolder, offers.purchase, TB_MENU_LOCALIZED.MARKETPURCHASEREQUESTS, function() Market:showSearchOffers(viewElement, filterValues.search, filterValues) end, true)
		end

		local doSearch = function()
			local searchSettings = ''
			for _, v in pairs(filterOptions) do
				if (v.value) then
					searchSettings = searchSettings .. "&" .. v.val .. "=" .. v.value
				end
			end

			saleOffersHolder:kill(true)
			purchaseOffersHolder:kill(true)
			offersHolderGeneral:kill(true)

			offersHolderGeneral:show()
			saleOffersHolder:hide()
			purchaseOffersHolder:hide()

			TBMenu:displayLoadingMark(offersHolderGeneral, TB_MENU_LOCALIZED.MARKETLOADINGOFFERS)
			TBMenu:addBottomBloodSmudge(offersHolderGeneral, 2)

			Request:queue(function()
					download_market_info(searchSettings:sub(2))
				end, "marketplace_offers", handleResponse)
		end

		local listElements = {}
		local prevElem = nil
		for _, v in pairs(filterOptions) do
			local element = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, element)

			local elementName
			if (not v.search) then
				elementName = UIElement:new({
					parent = element,
					pos = { 15, 5 },
					size = { (element.size.w - 30) / 3 - 5, element.size.h - 10 }
				})
				elementName:addAdaptedText(false, v.name, nil, nil, nil, LEFTMID)
				if (elementName.textScale < 0.6) then
					elementName.size.w = element.size.w - 20
					elementName:moveTo(nil, 5, true)
					elementName.str = ''
					elementName:addAdaptedText(false, v.name, nil, nil, nil, LEFTBOT)

					local elementNew = UIElement:new({
						parent = listingHolder,
						pos = { 0, #listElements * elementHeight },
						size = { listingHolder.size.w, elementHeight }
					})
					table.insert(listElements, elementNew)
					element = elementNew
					elementName = nil
				end
			end

			local filterHolder = UIElement:new({
				parent = element,
				pos = { elementName and (elementName.shift.x + elementName.size.w + 10) or 15, 5 },
				size = { element.size.w - (elementName and (elementName.shift.x * 2 + elementName.size.w) or 20), element.size.h - 10 },
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			local interactiveElem
			if (v.options) then
				local dropdownList = {}
				for j, k in pairs(v.options) do
					table.insert(dropdownList, {
						text = k .. '',
						action = function() v.action(j, k) end
					})
				end
				---Prepare same color as text fields use by default
				local lightColor = {}
				for i, v in pairs(TB_MENU_DEFAULT_BG_COLOR) do
					lightColor[i] = v + 0.05
				end
				local dropdownHolder = filterHolder:addChild({
					shift = { 1, 1 },
					bgColor = lightColor
				}, true)
				interactiveElem = TBMenu:spawnDropdown(dropdownHolder, dropdownList, filterHolder.size.h, WIN_H / 3, v.defaultId and dropdownList[v.defaultId] or nil, { scale = 0.7, fontid = 4 }, { scale = 0.6, fontid = 4 })
			else
				interactiveElem = TBMenu:spawnTextField2(filterHolder, nil, v.value, nil, {
					isNumeric = not v.text,
					fontId = FONTS.LMEDIUM,
					textScale = 0.7,
					textColor = UICOLORWHITE,
					textAlign = v.search and LEFTMID or CENTERMID,
					inputType = v.text and KEYBOARD_INPUT.DEFAULT or KEYBOARD_INPUT.NUMBERPAD
				})
				if (v.default) then
					local defaultValue = UIElement:new({
						parent = filterHolder,
						pos = { 0, -filterHolder.size.h * 2 },
						size = { filterHolder.size.w, filterHolder.size.h },
						interactive = true,
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
						hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
						shapeType = filterHolder.shapeType,
						rounded = filterHolder.rounded
					})
					defaultValue:addAdaptedText(false, v.defaultName .. ": " .. v.default, nil, nil, 4, nil, 0.7)
					defaultValue:addMouseHandlers(nil, function()
							v.value = tostring(v.default)
							interactiveElem.textfieldstr[1] = v.default .. ''
							interactiveElem.textfieldindex = interactiveElem.textfieldstr[1]:len()
							defaultValue:hide(true)
						end)
					interactiveElem:addCustomDisplay(false, function()
							if (interactiveElem.keyboard == true and string.find(v.default, interactiveElem.textfieldstr[1]) and (v.default .. '') ~= interactiveElem.textfieldstr[1]) then
								defaultValue:show(true)
							elseif (defaultValue.hoverState == BTN_NONE) then
								defaultValue:hide(true)
							end
						end, true)
				end
				interactiveElem:addInputCallback(function()
						v.value = interactiveElem.textfieldstr[1]:gsub(" ", "+")
					end)
				interactiveElem:addEnterAction(doSearch)
			end
			if (prevElem) then
				prevElem:addTabSwitch(interactiveElem)
				interactiveElem:addTabSwitchPrev(prevElem)
			end
			prevElem = interactiveElem
		end

		if (#listElements * elementHeight > listingHolder.size.h) then
			for _, v in pairs(listElements) do
				v:hide()
			end
			local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
			listingHolder.scrollBar = scrollBar
			scrollBar:makeScrollBar(listingHolder, listElements, toReload)
		else
			listingHolder:moveTo((listingHolder.parent.size.w - listingHolder.size.w) / 4, nil, true)
		end

		TBMenu:addBottomBloodSmudge(botBar, 1)
		local searchButton = botBar:addChild({
			pos = { (botBar.size.w - math.max(300, botBar.size.w * 0.6)) / 2, 4 },
			size = { math.max(300, botBar.size.w * 0.6), botBar.size.h - 14 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		searchButton:addChild({ shift = { 10, 3 } }):addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONSEARCH)

		saleOffersHolder:hide()
		purchaseOffersHolder:hide()

		searchButton:addMouseUpHandler(doSearch)
		Request:queue(function()
				local searchSettings = ''
				for _, v in pairs(filterOptions) do
					if (v.value) then
						searchSettings = searchSettings .. "&" .. v.val .. "=" .. v.value
					end
				end

				download_market_info(searchSettings:sub(2))
			end, "marketplace_offers", handleResponse)
	end

	function Market:displayOffersRecent(viewElement, offersData)
		viewElement:kill(true)

		local elementHeight = math.clamp(viewElement.size.h / 10, 45, 55)
		local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(viewElement, math.max(elementHeight, 50), elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

		local offersTitle = topBar:addChild({ shift = { 15, 5 } })
		offersTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETRECENTPURCHASEREQUESTS, nil, nil, FONTS.BIG, nil, 0.75, nil, 0.5)
		TBMenu:addBottomBloodSmudge(botBar, 2)

		local sellableItemids = { }
		for _, v in pairs(Market:searchItemsInventory()) do
			table.insert(sellableItemids, v.itemid)
		end

		local listElements = { }
		for _, v in pairs(offersData) do
			local item = Store:getItemInfo(v.itemid)
			local offerView = listingHolder:addChild({
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, offerView)
			local offerViewBG = UIElement:new({
				parent = offerView,
				pos = { 10, 2 },
				size = { (offerView.size.w - 10) / 5 * 4, offerView.size.h - 4 },
				interactive = true,
				clickThrough = true,
				hoverThrough = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			offerViewBG:addMouseHandlers(nil, function()
					Market:showItemPage(TBMenu.CurrentSection, item)
				end)
			local offerIcon = offerViewBG:addChild({
				pos = { 10, 3 },
				size = { offerViewBG.size.h - 6, offerViewBG.size.h - 6 },
				bgImage = item:getIconPath()
			})
			local offerItemName = UIElement:new({
				parent = offerViewBG,
				pos = { offerIcon.shift.x * 2 + offerIcon.size.w, 5 },
				size = { (offerViewBG.size.w - (offerIcon.shift.x * 3 + offerIcon.size.w)) * 0.667, offerViewBG.size.h - 10 }
			})
			offerItemName:addAdaptedText(true, item.itemname, nil, nil, FONTS.MEDIUM, LEFTMID, 0.9, 0.9)
			local offerItemPrice = offerViewBG:addChild({
				pos = { offerItemName.shift.x + offerItemName.size.w, 5 },
				size = { offerItemName.size.w * 0.5, offerViewBG.size.h - 10 }
			})
			offerItemPrice:addAdaptedText(false, numberFormat(v.price) .. " " .. TB_MENU_LOCALIZED.WORDTC, nil, nil, FONTS.LMEDIUM, RIGHTMID, 0.7)
			local offerSellButton = offerView:addChild({
				pos = { offerViewBG.shift.x + offerViewBG.size.w + 5, offerViewBG.shift.y },
				size = { offerView.size.w - (offerViewBG.shift.x + offerViewBG.size.w) - 5, offerViewBG.size.h },
				interactive = true,
				clickThrough = true,
				hoverThrough = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
				shapeType = offerViewBG.shapeType,
				rounded = offerViewBG.rounded
			})
			if (v.username ~= TB_MENU_PLAYER_INFO.username and not in_array(item.itemid, sellableItemids)) then
				offerSellButton:deactivate(true)
			end
			offerSellButton:addChild({ shift = { 5, 2 } }):addAdaptedText(true, v.username == TB_MENU_PLAYER_INFO.username and TB_MENU_LOCALIZED.MARKETMODIFY or TB_MENU_LOCALIZED.MARKETSELL, nil, nil, 4, nil, 0.7)
			offerSellButton:addMouseHandlers(nil, function()
					if (v.username == TB_MENU_PLAYER_INFO.username) then
						Market:spawnModifyPurchaseOfferModal(v)
					else
						Market:spawnInventoryItemSelector(item, nil, v)
					end
				end)

			if (not is_mobile()) then
				local sellerInfo = TBMenu:displayPopup(offerViewBG, TB_MENU_LOCALIZED.MARKETOFFERBY .. " " .. v.username .. "\n^37" .. TB_MENU_LOCALIZED.MARKETOFFERPLACEDON .. " " .. v.time)
				if (sellerInfo ~= nil) then
					sellerInfo:moveTo(-sellerInfo.size.w - 5, nil, true)
					sellerInfo:moveTo(nil, sellerInfo.size.h > offerViewBG.size.h and -offerViewBG.size.h - (sellerInfo.size.h - offerViewBG.size.h) / 2 or (offerViewBG.size.h - sellerInfo.size.h) / 2)
				end
			end

			if (not is_mobile() and item.price > 0 and item.price ~= v.price) then
				local discountValue = math.floor(10000 - (v.price / item.price * 10000)) / 100
				local priceDiscount = TBMenu:displayPopup(offerSellButton, discountValue > 0 and (discountValue .. "% cheaper than in Store") or (-discountValue .. " more expensive than in Store"))
				if (priceDiscount ~= nil) then
					priceDiscount:moveTo(nil, -priceDiscount.size.h - 5, true)
					priceDiscount:moveTo(priceDiscount.size.w > offerSellButton.size.w and -offerSellButton.size.w - (priceDiscount.size.w - offerSellButton.size.w) / 2 or (offerSellButton.size.w - priceDiscount.size.h) / 2)
				end
			end
			offerView:hide()
		end

		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = scrollBar
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
	end

	function Market:showMainUserShop(myShopView, refreshImage)
		local myShopData = MARKET_SHOP_DATA[TB_MENU_PLAYER_INFO.username:lower()]
		local myShopTitle = myShopView:addChild({
			pos = { 10, 10 },
			size = { myShopView.size.w - 20, 35 }
		})
		myShopTitle:addAdaptedText(true, myShopData.title, nil, nil, FONTS.BIG)

		local lastElement = myShopTitle
		if (myShopData.tier >= TIER_PREMIUM and myShopView.size.h >= 500) then
			local shopImage = UIElement:new({
				parent = myShopView,
				pos = { 20, lastElement.shift.y + lastElement.size.h + 10 },
				size = { myShopView.size.w - 40, (myShopView.size.w - 40) / 2 },
				bgImage = { "../textures/store/market/" .. string.lower(TB_MENU_PLAYER_INFO.username) .. ".tga", nil }
			})
			lastElement = shopImage
			TBMenu:addOuterRounding(shopImage, myShopView.bgColor, 10)

			if (refreshImage) then
				Request:queue(function()
						download_server_file("marketplace&user=" .. TB_MENU_PLAYER_INFO.username .. "&shop_image", 0)
					end, "marketplace_shopimage", function()
						if (not shopImage or shopImage.destroyed) then
							return
						end
						local response = get_network_response();
						if (not response:find("ERROR")) then
							local textureFile = Files.Open("../data/textures/store/market/" .. string.lower(TB_MENU_PLAYER_INFO.username) .. ".tga")
							shopImage.killAction = function() if (textureFile) then textureFile:close() end end
							shopImage:addCustomDisplay(false, function()
								if (not textureFile:isDownloading()) then
									textureFile:close()
									shopImage:updateImage("../textures/store/market/" .. string.lower(TB_MENU_PLAYER_INFO.username) .. ".tga")
									shopImage.customDisplayBefore = nil
								end
							end, true)
						end
					end)
			end

			local shopDescription = shopImage:addChild({
				shift = { 10, 10 },
				shapeType = ROUNDED,
				rounded = 5,
				bgColor = { 0, 0, 0, 0.75 }
			})
			local shopDescriptionText = shopDescription:addChild({ shift = { 10, 10 } })
			shopDescriptionText:addAdaptedText(false, myShopData.description, nil, nil, 4, RIGHTBOT, 0.7, 0.6)
			local width = 0
			for _,v in pairs(shopDescriptionText.dispstr) do
				local w = get_string_length(v, shopDescriptionText.textFont) * shopDescriptionText.textScale
				width = w > width and w or width
			end
			shopDescriptionText.size = { w = width + 1, h = math.min(shopDescriptionText.size.h, #shopDescriptionText.dispstr * getFontMod(shopDescriptionText.textFont) * 10 * shopDescriptionText.textScale + 1) }
			shopDescription.size = { w = shopDescriptionText.size.w + shopDescriptionText.shift.x * 2, h = shopDescriptionText.size.h + shopDescriptionText.shift.y * 2 }
			shopDescription:moveTo(shopDescription.parent.size.w - shopDescription.size.w - shopDescriptionText.shift.x, shopDescription.parent.size.h - shopDescription.size.h - shopDescriptionText.shift.y)
			local tierSeparator = UIElement:new({
				parent = myShopView,
				pos = { 50, lastElement.shift.y + lastElement.size.h + 15 },
				size = { myShopView.size.w - 100, 1 },
				bgColor = UICOLORWHITE
			})
			lastElement = tierSeparator
		elseif (myShopData.tier == TIER_REGULAR) then
			local premiumUpgradeButton = UIElement:new({
				parent = myShopView,
				pos = { 25, lastElement.shift.y + lastElement.size.h + 10 },
				size = { myShopView.size.w - 50, math.min(myShopView.size.h / 10, 40) },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
				hoverColor = table.clone(TB_MENU_DEFAULT_INACTIVE_COLOR_DARK),
				pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			premiumUpgradeButton.hoverColor[4] = 0.75
			local premiumUpgradeButtonText = premiumUpgradeButton:addChild({
				shift = { 15, 3 },
			})
			premiumUpgradeButtonText:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETUPGRADEPREMIUM)
			premiumUpgradeButton:addMouseUpHandler(function()
				local premiumItem = Store:getItemInfo(3793)
				local displayPrice = "$" .. premiumItem.now_usd_price
				if (_G.PLATFORM == "IPHONEOS") then
					displayPrice = utf8.gsub(get_platform_item_price(premiumItem.itemid), "%s", " ")
				end
				if (string.len(displayPrice) < 2) then
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREITEMNOTAVAILABLE)
					return
				end
				MARKET_ACTIVE_MODAL = TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.MARKETUPGRADEPREMIUMDESC .. "\n\n" .. TB_MENU_LOCALIZED.MARKETPREMIUMPURCHASEPROMPT1 .. " " .. displayPrice .. TB_MENU_LOCALIZED.MARKETPREMIUMPURCHASEPROMPT2, function()
						Store.InitUSDPurchase(premiumItem)
					end)
				MARKET_ACTIVE_MODAL.killAction = function() MARKET_ACTIVE_MODAL = nil end
			end)
			lastElement = premiumUpgradeButton
			local tierSeparator = UIElement:new({
				parent = myShopView,
				pos = { 50, lastElement.shift.y + lastElement.size.h + 15 },
				size = { myShopView.size.w - 100, 1 },
				bgColor = UICOLORWHITE
			})
			lastElement = tierSeparator
		end

		local dataCount = 0
		for _,v in pairs(myShopData.stats) do
			if (v.count or v.tc) then
				dataCount = dataCount + 1
			end
		end

		if (dataCount > 0) then
			local shopStats = myShopView:addChild({
				pos = { 15, lastElement.shift.y + lastElement.size.h + 10 },
				size = { myShopView.size.w - 30, 25 }
			})
			shopStats:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETSHOPSTATS)
			lastElement = shopStats

			for i,v in pairs(myShopData.stats) do
				if ((v.count or v.tc) and TB_MENU_LOCALIZED["MARKETSTATS" .. i]) then
					local shopStat = UIElement:new({
						parent = myShopView,
						pos = { 15, lastElement.shift.y + lastElement.size.h + 5 },
						size = { myShopView.size.w / 2 - 20, 16 }
					})
					local shopStatVal = UIElement:new({
						parent = shopStat,
						pos = { shopStat.size.w + 10, 0 },
						size = { shopStat.size.w, shopStat.size.h }
					})
					shopStat:addAdaptedText(true, (v.count and (v.count .. " ") or '') .. TB_MENU_LOCALIZED["MARKETSTATS" .. i], nil, nil, 4, LEFTMID)
					shopStatVal:addAdaptedText(true, numberFormat(v.tc) .. " " .. TB_MENU_LOCALIZED.WORDTC, nil, nil, 4, RIGHTMID)
					lastElement = shopStat
				end
			end
		end

		local buttonHeight = math.clamp((myShopView.size.h - lastElement.shift.y - lastElement.size.h - 10) / 3 - 10, 45, 55)
		local buttonStartPos = myShopView.size.h - buttonHeight * 3 - 30

		local saleOfferButton = UIElement:new({
			parent = myShopView,
			pos = { 20, buttonStartPos },
			size = { myShopView.size.w - 40, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		saleOfferButton:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETNEWSALEOFFER)
		saleOfferButton:addMouseHandlers(nil, function()
				Market:spawnInventoryItemSelector()
			end)
		local purchaseOfferButton = UIElement:new({
			parent = myShopView,
			pos = { 20, buttonStartPos + buttonHeight + 10 },
			size = { myShopView.size.w - 40, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		purchaseOfferButton:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETNEWPURCHASEOFFER)
		purchaseOfferButton:addMouseHandlers(nil, function()
				Market:spawnItemSelectorModal()
			end)
		local viewShopButton = UIElement:new({
			parent = myShopView,
			pos = { 20, buttonStartPos + (buttonHeight + 10) * 2 },
			size = { myShopView.size.w - 40, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		viewShopButton:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETVIEWMYSHOP)
		viewShopButton:addMouseHandlers(nil, function()
				Market:showUserShop(TBMenu.CurrentSection, TB_MENU_PLAYER_INFO.username)
			end)
	end

	function Market:showUserShop(viewElement, username, backAction)
		usage_event("marketplace_shop")

		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Market:getSectionNavButtons(viewElement, backAction), true)
		Market:showSearchBar(nil, { shopuser = username, limit = 100 }, TB_MENU_LOCALIZED.MARKETSEARCHINSHOP)

		local isMyShop = username:lower() == TB_MENU_PLAYER_INFO.username:lower()
		local shopInfoView = viewElement:addChild({
			size = { math.min(viewElement.size.w / 3, 400), viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(shopInfoView, 1)

		local fetchShopInfo
		local requireReload = { }
		local doShowInfo = function(reload)
			if (not MARKET_SHOP_DATA[username]) then
				return false
			end

			local shopData = MARKET_SHOP_DATA[username]
			local lastElement
			local premiumShopCapsule
			if (shopData.tier >= TIER_PREMIUM) then
				premiumShopCapsule = shopInfoView:addChild({
					pos = { 10, 10 },
					size = { shopInfoView.size.w, 24 },
					bgColor = TB_MENU_DEFAULT_ORANGE,
					uiColor = UICOLORBLACK,
					shapeType = ROUNDED,
					rounded = 12,
					interactive = true
				})
				premiumShopCapsule:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETPREMIUMSHOP, nil, nil, 4, nil, 0.6)
				premiumShopCapsule.size.w = get_string_length(premiumShopCapsule.dispstr[1], premiumShopCapsule.textFont) * premiumShopCapsule.textScale + 20
				premiumShopCapsule:moveTo(-premiumShopCapsule.size.w - 10)

				lastElement = premiumShopCapsule

				local popup = TBMenu:displayHelpPopup(premiumShopCapsule, TB_MENU_LOCALIZED.MARKETPREMIUMSHOPHINT, nil, true)
				if (popup ~= nil) then
					popup:moveTo(-popup.parent.size.w - (popup.size.w - popup.parent.size.w) / 2, popup.parent.size.h + 5)
					table.insert(requireReload, popup)
				end
			end

			local shopTitle = shopInfoView:addChild({
				pos = { 20, 10 },
				size = { shopInfoView.size.w - 40 - (lastElement and lastElement.size.w or 0), 35 }
			})
			shopTitle:addAdaptedText(true, shopData.title, nil, nil, FONTS.BIG, LEFTBOT)
			if (lastElement and #shopTitle.dispstr > 1) then
				shopTitle:moveTo(nil, 29, true)
				shopTitle.size.w = shopInfoView.size.w - 40
				shopTitle.str = ''
				shopTitle:addAdaptedText(true, shopData.title, nil, nil, FONTS.BIG, LEFTBOT)
			end
			local shopTitleBy = shopInfoView:addChild({
				pos = { shopTitle.shift.x, shopTitle.size.h + shopTitle.shift.y },
				size = { shopTitle.size.w, 25 }
			})
			shopTitleBy:addAdaptedText(true, TB_MENU_LOCALIZED.WORDBY .. " " .. username, nil, nil, nil, LEFT)
			lastElement = shopTitleBy

			local segmentMaxHeight = (shopInfoView.size.h - lastElement.shift.y - lastElement.size.h) / (isMyShop and 3 or 2)
			local imageDrawHeight = (shopInfoView.size.w - 40) / 2
			local imageHeight = math.min(segmentMaxHeight, imageDrawHeight)
			if (shopData.tier >= TIER_PREMIUM) then
				local shopImage = shopInfoView:addChild({
					pos = { 20, math.max(20, lastElement.shift.y + lastElement.size.h + 10 - (imageDrawHeight - imageHeight) / 2) },
					size = { shopInfoView.size.w - 40, imageDrawHeight },
					bgImage = { "../textures/store/market/" .. string.lower(username) .. ".tga", nil }
				})
				lastElement = shopImage

				if (imageDrawHeight > imageHeight) then
					local shopImageTopBar = shopImage:addChild({
						pos = { 0, 0 },
						size = { shopImage.size.w, (imageDrawHeight - imageHeight) / 2 },
						bgColor = TB_MENU_DEFAULT_BG_COLOR
					})
					local shopImageBotBar = shopImage:addChild({
						pos = { 0, -(imageDrawHeight - imageHeight) / 2 },
						size = { shopImage.size.w, (imageDrawHeight - imageHeight) / 2 },
						bgColor = TB_MENU_DEFAULT_BG_COLOR
					})
					local shopImageOverlay = shopInfoView:addChild({
						pos = { shopImage.shift.x, shopImage.shift.y + (imageDrawHeight - imageHeight) / 2 },
						size = { shopImage.size.w, imageHeight }
					})
					lastElement = shopImageOverlay

					if (premiumShopCapsule) then
						premiumShopCapsule:reload()
					end
					shopTitle:reload()
					shopTitleBy:reload()
				end
				TBMenu:addOuterRounding(lastElement, shopInfoView.bgColor, 10)

				if (reload) then
					Request:queue(function()
							download_server_file("marketplace&user=" .. TB_MENU_PLAYER_INFO.username .. "&shop_image", 0)
						end, "marketplace_shopimage", function()
							if (not shopImage or shopImage.destroyed) then
								return
							end
							local response = get_network_response();
							if (not response:find("ERROR")) then
								local textureFile = Files.Open("../data/textures/store/market/" .. string.lower(username) .. ".tga")
								shopImage.killAction = function() if (textureFile) then textureFile:close() end end
								shopImage:addCustomDisplay(false, function()
									if (not textureFile:isDownloading()) then
										textureFile:close()
										shopImage:updateImage("../textures/store/market/" .. string.lower(username) .. ".tga")
										shopImage.customDisplayBefore = nil
									end
								end, true)
							end
						end)
				end

				local shopDescription = lastElement:addChild({
					shift = { 10, 10 },
					shapeType = ROUNDED,
					rounded = 5,
					bgColor = { 0, 0, 0, 0.75 }
				})
				local shopDescriptionText = shopDescription:addChild({ shift = { 10, 10 } })
				shopDescriptionText:addAdaptedText(false, shopData.description, nil, nil, 4, RIGHTBOT, 0.7, 0.6)
				local width = 0
				for i,v in pairs(shopDescriptionText.dispstr) do
					local w = get_string_length(v, shopDescriptionText.textFont) * shopDescriptionText.textScale
					width = w > width and w or width
				end
				shopDescriptionText.size = { w = width + 1, h = math.min(shopDescriptionText.size.h, #shopDescriptionText.dispstr * getFontMod(shopDescriptionText.textFont) * 10 * shopDescriptionText.textScale + 1) }
				shopDescription.size = { w = shopDescriptionText.size.w + shopDescriptionText.shift.x * 2, h = shopDescriptionText.size.h + shopDescriptionText.shift.y * 2 }
				shopDescription:moveTo(shopDescription.parent.size.w - shopDescription.size.w - shopDescriptionText.shift.x, shopDescription.parent.size.h - shopDescription.size.h - shopDescriptionText.shift.y)
			else
				local shopDescription = shopInfoView:addChild({
					pos = { 20, lastElement.shift.y + lastElement.size.h + 10 },
					size = { imageHeight * 2, imageHeight },
				})
				shopDescription:addAdaptedText(false, shopData.description, nil, nil, 4, LEFT, 0.8, 0.7)

				local textHeight = #shopDescription.dispstr * getFontMod(shopDescription.textFont) * shopDescription.textScale * 10 + 5
				shopDescription.size.h = math.min(shopDescription.size.h, textHeight)
				lastElement = shopDescription
			end

			segmentMaxHeight = math.min(segmentMaxHeight, (shopInfoView.size.h - lastElement.size.h - lastElement.shift.y) / (isMyShop and 2 or 1))

			local dataCount = 0
			for i,v in pairs(shopData.stats) do
				if (v.count or v.tc) then
					dataCount = dataCount + 1
				end
			end

			if (dataCount > 0) then
				local thisSegmentMax = math.min(segmentMaxHeight - 10, 120)
				local shopStatsHolder = shopInfoView:addChild({
					pos = { 15, isMyShop and (lastElement.shift.y + lastElement.size.h + 10) or -thisSegmentMax },
					size = { shopInfoView.size.w - 30, thisSegmentMax - (isMyShop and 20 or 0) }
				})

				local shopStats
				-- On small screen height stats become barely readable
				-- Title isn't too important, it's clear those are stats - hide it
				if (thisSegmentMax > 90) then
					shopStats = shopStatsHolder:addChild({
						size = { shopStatsHolder.size.w, math.min(thisSegmentMax / 3.75, 32) }
					})
					shopStats:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETSHOPSTATS, nil, nil, FONTS.BIG)
					lastElement = shopStats
				else
					lastElement = {
						shift = { x = 0, y = -5 },
						size = { w = 0, h = 0 }
					}
				end

				local statHeight = math.min((thisSegmentMax - (shopStats and 52 or 20)) / math.min(3, dataCount), 20)
				if (shopData.stats.SALES and shopData.stats.SALES.count) then
					local stat = shopData.stats.SALES
					local finishedSales = shopStatsHolder:addChild({
						pos = { 0, lastElement.shift.y + lastElement.size.h + 5 },
						size = { shopStatsHolder.size.w, statHeight }
					})
					finishedSales:addAdaptedText(true, stat.count .. " " .. TB_MENU_LOCALIZED.MARKETFINISHEDSALESFOR .. " " .. numberFormat(stat.tc) .. " " .. TB_MENU_LOCALIZED.WORDTC, nil, nil, 4)
					lastElement = finishedSales
				end
				if (shopData.stats.offers and shopData.stats.offers.count) then
					local stat = shopData.stats.offers
					local activeSales = shopStatsHolder:addChild({
						pos = { 0, lastElement.shift.y + lastElement.size.h },
						size = { shopStatsHolder.size.w, statHeight }
					})
					activeSales:addAdaptedText(true, stat.count .. " " .. TB_MENU_LOCALIZED.MARKETITEMSONSALE, nil, nil, 4)
					lastElement = activeSales
				end
				if (shopData.stats.requests and shopData.stats.requests.count) then
					local stat = shopData.stats.requests
					local activeRequests = shopStatsHolder:addChild({
						pos = { 0, lastElement.shift.y + lastElement.size.h },
						size = { shopStatsHolder.size.w, statHeight }
					})
					activeRequests:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETLOOKINGTOBUY .. " " .. stat.count .. " " .. TB_MENU_LOCALIZED.WORDITEMS, nil, nil, 4)
					lastElement = activeRequests
				end

				lastElement = shopStatsHolder
			end

			if (isMyShop) then
				segmentMaxHeight = math.min(165, shopInfoView.size.h - lastElement.shift.y - lastElement.size.h, segmentMaxHeight)
				local buttonsHolder = shopInfoView:addChild({
					pos = { 15, -segmentMaxHeight },
					size = { shopInfoView.size.w - 30, segmentMaxHeight }
				})
				local buttonDistance = math.min(segmentMaxHeight / 15, 10)
				local buttonHeight = segmentMaxHeight / 3 - buttonDistance

				local saleOfferButton = buttonsHolder:addChild({
					pos = { 0, 0 },
					size = { buttonsHolder.size.w, buttonHeight },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					shapeType = ROUNDED,
					rounded = 4
				})
				saleOfferButton:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETNEWSALEOFFER)
				saleOfferButton:addMouseHandlers(nil, function()
						Market:spawnInventoryItemSelector()
					end)
				local purchaseOfferButton = buttonsHolder:addChild({
					pos = { 0, buttonHeight + buttonDistance },
					size = { buttonsHolder.size.w, buttonHeight },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					shapeType = ROUNDED,
					rounded = 4
				})
				purchaseOfferButton:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETNEWPURCHASEOFFER)
				purchaseOfferButton:addMouseHandlers(nil, function()
						Market:spawnItemSelectorModal()
					end)
				local editShopButton = buttonsHolder:addChild({
					pos = { 0, (buttonHeight + buttonDistance) * 2 },
					size = { buttonsHolder.size.w, buttonHeight },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
					shapeType = ROUNDED,
					rounded = 4
				})
				editShopButton:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETMODIFYSHOP)
				editShopButton:addMouseHandlers(nil, function()
						Market:showModifyUserShop(MARKET_SHOP_DATA[username], fetchShopInfo)
					end)
			end

			for _, v in pairs(requireReload) do
				v:reload()
			end

			return true
		end

		if (not doShowInfo()) then
			TBMenu:displayLoadingMark(shopInfoView:addChild({ shift = { 25, 50 }}), TB_MENU_LOCALIZED.MARKETLOADINGSHOPBY .. " " .. username)
		end

		fetchShopInfo = function()
			Request:queue(function()
					download_market_info("user=" .. username)
				end, "marketplace_user_shop", function()
					if (not shopInfoView or shopInfoView.destroyed) then
						return
					end

					local response = get_network_response()
					if (response:find("ERROR")) then
						shopInfoView:kill(true)
						TBMenu:addBottomBloodSmudge(shopInfoView, 1)
						local error = response:gsub('ERROR 0;', '')
						shopInfoView:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETERRORLOADINGSHOP .. ": " .. error)
						return
					end

					local shopData = Market:parseShopInfo(response)
					if (shopData.title) then
						if (not table.equals(shopData, MARKET_SHOP_DATA[username])) then
							shopInfoView:kill(true)
							TBMenu:addBottomBloodSmudge(shopInfoView, 1)
							local imageReload = not MARKET_SHOP_DATA[username] and true or MARKET_SHOP_DATA[username].imageMD5 ~= shopData.imageMD5
							MARKET_SHOP_DATA[username] = shopData
							doShowInfo(imageReload)
						end
					else
						shopInfoView:kill(true)
						TBMenu:addBottomBloodSmudge(shopInfoView, 1)
						shopInfoView:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETERRORLOADINGSHOP)
					end
				end)
		end
		fetchShopInfo()

		local offersHolderGeneral = viewElement:addChild({
			pos = { shopInfoView.size.w + 10, 0 },
			size = { viewElement.size.w - shopInfoView.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:displayLoadingMark(offersHolderGeneral, TB_MENU_LOCALIZED.MARKETLOADINGOFFERS)
		TBMenu:addBottomBloodSmudge(offersHolderGeneral, 2)

		local saleOffersHolder = viewElement:addChild({
			pos = { offersHolderGeneral.shift.x, 0 },
			size = { offersHolderGeneral.size.w / 2 - 5, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local purchaseOffersHolder = viewElement:addChild({
			pos = { saleOffersHolder.shift.x + saleOffersHolder.size.w + 10, 0 },
			size = { saleOffersHolder.size.w, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		saleOffersHolder:hide()
		purchaseOffersHolder:hide()

		Request:queue(function()
				download_market_info("search&limit=100&shopuser=" .. username)
			end, "marketplace_offers", function()
				if (not saleOffersHolder or saleOffersHolder.destroyed) then
					return
				end

				local response = get_network_response()
				local overseer = viewElement:addChild({})
				overseer:addCustomDisplay(true, function()
						if (not MARKET_ACTIVE_MODAL or MARKET_ACTIVE_MODAL.destroyed) then
							saleOffersHolder:kill(true)
							purchaseOffersHolder:kill(true)
							offersHolderGeneral:kill(true)

							if (response:len() == 0) then
								offersHolderGeneral:show()
								saleOffersHolder:hide()
								purchaseOffersHolder:hide()

								local errorDisplay = UIElement:new({
									parent = offersHolderGeneral,
									pos = { offersHolderGeneral.size.w / 5, offersHolderGeneral.size.h / 3 },
									size = { offersHolderGeneral.size.w * 0.6, offersHolderGeneral.size.h / 3 }
								})
								errorDisplay:addAdaptedText(true, TB_MENU_LOCALIZED.NOTHINGTOSHOW)
								TBMenu:addBottomBloodSmudge(offersHolderGeneral, 2)
								return
							end

							offersHolderGeneral:hide()
							saleOffersHolder:show()
							purchaseOffersHolder:show()

							local offers = Market:parseOffersData(response)

							Market:displayOffers(saleOffersHolder, offers.sale, TB_MENU_LOCALIZED.MARKETSALEOFFERS, function() Market:showUserShop(viewElement, username) end, true)
							Market:displayOffers(purchaseOffersHolder, offers.purchase, TB_MENU_LOCALIZED.MARKETPURCHASEREQUESTS, function() Market:showUserShop(viewElement, username) end, true)

							for _, v in pairs(requireReload) do
								v:reload()
							end

							overseer:kill()
						end
					end)
			end)
	end

	---Displays main Market screen
	---@param viewElement UIElement
	function Market:showMain(viewElement)
		viewElement:kill(true)
		Market:showSearchBar()

		local myShopView = viewElement:addChild({
			pos = { 5, 0 },
			size = { 0, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		myShopView.size.w = math.min(viewElement.size.w / 4, 375)
		TBMenu:addBottomBloodSmudge(myShopView, 1)

		Request:queue(function()
				download_server_info("marketplace&user=" .. TB_MENU_PLAYER_INFO.username)
			end, "marketplace_userfetch", function()
				if (not myShopView or myShopView.destroyed) then
					return
				end

				local response = get_network_response()
				if (response:find("ERROR")) then
					myShopView:kill(true)
					TBMenu:addBottomBloodSmudge(myShopView, 1)
					local error = response:gsub('ERROR 0;', '')
					myShopView:addAdaptedText(false, error)
					return
				end

				local myShopData = Market:parseShopInfo(response)
				if (myShopData.title) then
					-- We don't really need to reload this if all the data is the same
					if (not table.equals(myShopData, MARKET_SHOP_DATA[TB_MENU_PLAYER_INFO.username:lower()])) then
						-- Data is different but it may be just some stats / base info
						-- Check if image md5 has changed to see whether we need to redownload promo image
						myShopView:kill(true)
						TBMenu:addBottomBloodSmudge(myShopView, 1)
						local imageReload = not MARKET_SHOP_DATA[TB_MENU_PLAYER_INFO.username:lower()] and true or MARKET_SHOP_DATA[TB_MENU_PLAYER_INFO.username:lower()].imageMD5 ~= myShopData.imageMD5
						MARKET_SHOP_DATA[TB_MENU_PLAYER_INFO.username:lower()] = myShopData
						Market:showMainUserShop(myShopView, imageReload)
					end
				else
					myShopView:kill(true)
					TBMenu:addBottomBloodSmudge(myShopView, 1)
					local myShopError = UIElement:new({
						parent = myShopView,
						pos = { 15, myShopView.size.h / 4 },
						size = { myShopView.size.w - 30, myShopView.size.h / 2 }
					})
					myShopError:addAdaptedText(false, TB_MENU_LOCALIZED.MARKETERRORLOADINGSHOP)
				end
			end)

		if (MARKET_SHOP_DATA[TB_MENU_PLAYER_INFO.username:lower()]) then
			Market:showMainUserShop(myShopView)
		else
			TBMenu:displayLoadingMark(myShopView, TB_MENU_LOCALIZED.MARKETLOADINGDATA)
		end
		local myShopViewShift = myShopView.shift.x + myShopView.size.w + 10
		local featuredImageWidth = math.min(500, (viewElement.size.w - myShopViewShift - 10) / 2)
		local featuredImageHeight = math.min(viewElement.size.h / 3, (featuredImageWidth - 20) / 2 + 20)
		local popularSaleOffersView = viewElement:addChild({
			pos = { myShopViewShift, 0 },
			size = { viewElement.size.w - featuredImageWidth - myShopViewShift - 15, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})

		local recentPurchaseOffersView = viewElement:addChild({
			pos = { popularSaleOffersView.shift.x + popularSaleOffersView.size.w + 10, featuredImageHeight + 10 },
			size = { featuredImageWidth, viewElement.size.h - featuredImageHeight - 10 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})

		if (MARKET_OFFERS_HOME == nil or os.clock_real() - MARKET_OFFERS_HOME.refreshTime > 300) then
			MARKET_OFFERS_HOME = nil
			local popularSaleOffersTitle = UIElement:new({
				parent = popularSaleOffersView,
				pos = { 15, 7 },
				size = { popularSaleOffersView.size.w - 30, 35 }
			})
			popularSaleOffersTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETPOPULARSALEOFFERS, nil, nil, FONTS.BIG)
			TBMenu:addBottomBloodSmudge(popularSaleOffersView, 2)
			TBMenu:displayLoadingMark(popularSaleOffersView, TB_MENU_LOCALIZED.MARKETLOADINGOFFERS)

			local recentPurchaseOffersTitle = UIElement:new({
				parent = recentPurchaseOffersView,
				pos = { 15, 7 },
				size = { recentPurchaseOffersView.size.w - 30, 35 }
			})
			recentPurchaseOffersTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MARKETRECENTPURCHASEREQUESTS, nil, nil, FONTS.BIG)
			TBMenu:addBottomBloodSmudge(recentPurchaseOffersView, 2)
			TBMenu:displayLoadingMark(recentPurchaseOffersView, TB_MENU_LOCALIZED.MARKETLOADINGOFFERS)
		else
			Market:displayOffers(popularSaleOffersView, MARKET_OFFERS_HOME.sale, TB_MENU_LOCALIZED.MARKETPOPULARSALEOFFERS)
			Market:displayOffersRecent(recentPurchaseOffersView, MARKET_OFFERS_HOME.purchase)
		end

		Request:queue(function()
				download_server_info("marketplace&offers")
			end, "marketplace_offers", function()
				if (not popularSaleOffersView or popularSaleOffersView.destroyed) then
					return
				end

				local response = get_network_response()
				local offersData = Market:parseOffersData(response)
				if (MARKET_OFFERS_HOME == nil) then
					local overseer = viewElement:addChild({})
					overseer:addCustomDisplay(true, function()
							if (not MARKET_ACTIVE_MODAL or MARKET_ACTIVE_MODAL.destroyed) then
								Market:displayOffers(popularSaleOffersView, offersData.sale, TB_MENU_LOCALIZED.MARKETPOPULARSALEOFFERS)
								Market:displayOffersRecent(recentPurchaseOffersView, offersData.purchase)
								overseer:kill()
							end
						end)
				end
				MARKET_OFFERS_HOME = offersData
				MARKET_OFFERS_HOME.refreshTime = os.clock_real()
			end, function()
				TBMenu:showStatusMessage(get_network_error())
			end)

		local featuredShop = viewElement:addChild({
			pos = { popularSaleOffersView.shift.x + popularSaleOffersView.size.w + 10, 0 },
			size = { featuredImageWidth, featuredImageHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local atlasRatio = featuredImageHeight / featuredImageWidth
		local featuredShopImage = featuredShop:addChild({
			shift = { 10, 10 },
			bgImage = MARKET_FEATURED_SHOP_DATA and ("../textures/store/market/" .. MARKET_FEATURED_SHOP_DATA.user .. ".tga") or  "../textures/store/inventory/noise.tga",
			imageAtlas = MARKET_FEATURED_SHOP_DATA ~= nil,
			atlas = {
				x = 0, y = 512 * (0.5 - atlasRatio),
				w = 1024, h = 1024 * atlasRatio
			}
		})
		TBMenu:addOuterRounding(featuredShopImage, featuredShop.animateColor)

		local featuredLoader
		if (not MARKET_FEATURED_SHOP_DATA) then
			featuredShop:deactivate()
			featuredLoader = featuredShopImage:addChild({
				pos = { 10, 10 },
				size = { 24, 24 }
			})
			TBMenu:displayLoadingMark(featuredLoader, nil, 12)
		else
			local featuredTitle = featuredShopImage:addChild({
				pos = { 10, 10 },
				size = { featuredShopImage.size.w - 20, 35 },
				uiShadowColor = UICOLORBLACK
			})
			featuredTitle:addAdaptedText(true, MARKET_FEATURED_SHOP_DATA.title, nil, nil, FONTS.BIG, RIGHT, nil, nil, nil, 4)
			local featuredTitleUser = featuredShopImage:addChild({
				pos = { 10, 48 },
				size = { featuredShopImage.size.w - 20, 25 },
				uiShadowColor = UICOLORBLACK
			})
			featuredTitleUser:addAdaptedText(true, TB_MENU_LOCALIZED.WORDBY .. " " .. MARKET_FEATURED_SHOP_DATA.user, nil, nil, nil, RIGHT, nil, nil, nil, 1)
			local targetShop = table.clone(MARKET_FEATURED_SHOP_DATA)
			featuredShop:addMouseUpHandler(function()
					Market:showUserShop(TBMenu.CurrentSection, targetShop.user)
					usage_event("marketplace_featured_shop")
				end)
		end

		Request:queue(function()
				download_server_file("marketplace&featured", 0)
			end, "marketplace_featured", function()
				if (not featuredShopImage or featuredShopImage.destroyed) then
					return
				end

				local response = get_network_response()
				local featuredShopData = { user = "" }
				for ln in response:gmatch("[^\t]+\t?") do
					local cleanedValue = ln:gsub("[^;]+;([^\t]*)\t?$", "%1")
					if (ln:find("^USER")) then
						featuredShopData.user = cleanedValue
					elseif (ln:find("^TITLE")) then
						featuredShopData.title = cleanedValue
					elseif (ln:find("^DESC")) then
						featuredShopData.desc = cleanedValue
					end
				end

				local featuredFile = Files.Open("../data/textures/store/market/" .. featuredShopData.user .. ".tga")
				if (featuredFile.data) then
					featuredFile:close()
					if (featuredLoader) then
						featuredLoader:kill()
						featuredShopImage:updateImage("../textures/store/market/" .. featuredShopData.user .. ".tga", "../textures/store/inventory/noise.tga")
					end
				end
				featuredShop:addMouseUpHandler(function()
					Market:showUserShop(TBMenu.CurrentSection, featuredShopData.user)
					usage_event("marketplace_featured_shop")
				end)
				featuredShop.killAction = function() remove_hook("downloader_complete", Market.HookName) end

				add_hook("downloader_complete", Market.HookName, function(filename)
						if (filename:find(featuredShopData.user .. "%.tga")) then
							if (featuredLoader) then
								Downloader.SafeCall(function()
										featuredShopImage:updateImage("../textures/store/market/" .. featuredShopData.user .. ".tga", "../textures/store/inventory/noise.tga")
										featuredLoader:kill()
									end)
							end
							remove_hook("downloader_complete", Market.HookName)
						end
					end)

				if (featuredLoader) then
					local featuredTitle = UIElement:new({
						parent = featuredShopImage,
						pos = { 10, 10 },
						size = { featuredShopImage.size.w - 20, 35 },
					})
					featuredTitle:addAdaptedText(true, featuredShopData.title, nil, nil, FONTS.BIG, RIGHT, nil, nil, nil, 3)
					local featuredTitleUser = UIElement:new({
						parent = featuredShopImage,
						pos = { 10, 48 },
						size = { featuredShopImage.size.w - 20, 25 }
					})
					featuredTitleUser:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSAUTHORBY .. " " .. featuredShopData.user, nil, nil, nil, RIGHT, nil, nil, nil, 2)
				end
				featuredShop:activate()
				MARKET_FEATURED_SHOP_DATA = featuredShopData
			end)
	end
end
