-- new store manager class

local CATEGORIES_COLORS = { 44, 22, 2, 20, 21, 1, 5, 11, 12, 24, 27, 28, 29, 30, 34, 41, 43, 73 }
--local CATEGORIES_TEXTURES = { 48, 54, 55, 57, 58 }
local CATEGORIES_ADVANCED = { 78, 72, 80, 54, 55, 57, 58, 48 }
local CATEGORIES_ACCOUNT = { 45, 84, 68, 79 }
local CATEGORIES_HIDDEN = { 3 }

local TAB_COLORS = 1
local TAB_TEXTURES = 2
local TAB_ADVANCED = 3
local TAB_ACCOUNT = 4

local ITEM_EMPTY = {
	catid = 0,
	catname = "undef",
	itemid = 0,
	itemname = "undefined",
	on_sale = 0,
	now_tc_price = 0,
	now_usd_price = 0,
	price = 0,
	price_usd = 0,
	sale_time = 0,
	sale_promotion = 0,
	qi = 0,
	tier = 0,
	subscriptionid = 0,
	ingame = 0,
	colorid = 0,
	hidden = 1,
	locked = 1
}

do
	Torishop = {}
	Torishop.__index = Torishop
	local cln = {}
	setmetatable(cln, Torishop)

	function Torishop:getItems()
		local file = Files:new("../data/store.txt")
		if (not file.data) then
			if (get_option('autoupdate') == 0 and not file:isDownloading()) then
				download_torishop()
			end
			return { failed = true }
		end
		local data_types = {
			{ "catid", numeric = true },
			{ "catname" },
			{ "itemid", numeric = true },
			{ "itemname" },
			{ "on_sale", numeric = true },
			{ "now_tc_price", numeric = true },
			{ "now_usd_price", numeric = true },
			{ "price", numeric = true },
			{ "price_usd", numeric = true },
			{ "sale_time", numeric = true },
			{ "sale_promotion", numeric = true },
			{ "qi", numeric = true },
			{ "tier", numeric = true },
			{ "subscriptionid", numeric = true },
			{ "ingame", numeric = true },
			{ "colorid", numeric = true },
			{ "hidden", numeric = true },
			{ "locked", numeric = true },
			{ "description" },
			{ "contents" }
		}
		local TorishopData = {}
		local TorishopSections = {}
		for i, ln in pairs(file:readAll()) do
			if string.match(ln, "^PRODUCT") then
				local _, segments = ln:gsub("\t", "")
				segments = segments
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local item = {}
				for i,v in pairs(data_types) do
					item[v[1]] = data_stream[i + 1]
					if (v.numeric) then
						item[v[1]] = tonumber(item[v[1]])
					end
				end
				local contents = item.contents
				item.contents = {}
				while (contents:len() > 0) do
					table.insert(item.contents, tonumber(contents:match("%d+")))
					contents = contents:gsub("^%d+ ?", "")
				end
				TorishopSections[item.catid] = { name = item.catname }
				item.itemname = item.itemname:gsub("&amp;", "&")
				item.shortname = item.itemname:gsub("Motion Trail", "Trail")
				if (item.locked == 1) then
					item.now_tc_price = 0
					item.now_usd_price = 0
				end
				if (not in_array(item.catid, CATEGORIES_ACCOUNT)) then
					item.now_usd_price = math.ceil(item.now_usd_price)
				end
				TorishopData[item.itemid] = item
			end
		end
		file:close()
		
		TorishopSections[0] = { name = "Color Items" }
		TorishopData.ready = true
		return TorishopData, TorishopSections
	end
	
	function Torishop:getModelsData()
		local file = Files:new("../data/store_obj.txt")
		if (not file.data) then
			return { failed = true }
		end
		local data_types = {
			{ "itemid", numeric = true },
			{ "bodyid", numeric = true },
			{ "colorid", numeric = true },
			{ "alpha", numeric = true },
			{ "dynamic", boolean = true },
			{ "partless", boolean = true },
			{ "level", numeric = true }
		}
		local ModelsData = {}
		for i, ln in pairs(file:readAll()) do
			if string.match(ln, "^OBJ") then
				local _, segments = ln:gsub("\t", "")
				segments = segments
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local item = {}
				for i,v in pairs(data_types) do
					item[v[1]] = tonumber(data_stream[i + 1])
					if (v.boolean) then
						item[v[1]] = item[v[1]] == 1 and true or false
					end
				end
				if (item.level > 0) then
					ModelsData[item.itemid] = ModelsData[item.itemid] or { itemid = item.itemid, levels = 0, upgradeable = true }
					ModelsData[item.itemid][item.level] = item
					ModelsData[item.itemid].levels = ModelsData[item.itemid].levels + 1
				else
					ModelsData[item.itemid] = item
				end
			end
		end
		file:close()
		
		return ModelsData
	end
	
	function Torishop:getStoreSection(sectionid)
		if (sectionid == 1) then
			return { name = TB_MENU_LOCALIZED.STORECOLORSNAME, list = CATEGORIES_COLORS }
		elseif (sectionid == 2) then
			return { name = TB_MENU_LOCALIZED.STOREFLAMEFORGENAME }
		elseif (sectionid == 3) then
			return { name = TB_MENU_LOCALIZED.STOREADVANCEDNAME, list = CATEGORIES_ADVANCED }
		elseif (sectionid == 4) then
			return { name = TB_MENU_LOCALIZED.STOREACCOUNT, list = CATEGORIES_ACCOUNT }
		end
		return false
	end

	function Torishop:getItemInfo(itemid)
		local itemid = tonumber(itemid)
		if (not TB_STORE_DATA) then
			TB_STORE_DATA, TB_STORE_SECTIONS = Torishop:getItems()
		end
		if (TB_STORE_DATA.requireReload) then
			local downloadFinished = true
			for i,v in pairs(get_downloads()) do
				if (v:find("store.txt")) then
					downloadFinished = false
				end
			end
			if (downloadFinished) then
				TB_STORE_DATA, TB_STORE_SECTIONS = Torishop:getItems()
			end
		end
		if (TB_STORE_DATA[itemid]) then
			return TB_STORE_DATA[itemid]
		end
		download_torishop()
		TB_STORE_DATA.requireReload = true
		return ITEM_EMPTY
	end
	
	function Torishop:getItemIcon(item)
		if (type(item) == "table" and item.itemid) then
			return "../textures/store/items/" .. item.itemid .. ".tga"
		elseif (item) then
			return "../textures/store/items/" .. item .. ".tga"
		end
	end

	function Torishop:getSaleItems(featured)
		if (TB_STORE_DATA) then
			if (featured) then
				for i,v in pairs(TB_STORE_DATA) do
					if (type(v) == "table") then
						if (v.on_sale == 1 and v.sale_promotion == 1) then
							return v
						end
					end
				end
			else
				local saleItems = {}
				for i,v in pairs(TB_STORE_DATA) do
					if (type(v) == "table") then
						if (v.on_sale == 1) then
							table.insert(saleItems, v)
						end
					end
				end
				return saleItems
			end
		end
		return false
	end

	function Torishop:getTcSales()
		local data = {}
		local file = Files:new("../data/store.txt")
		if (not file.data) then
			return
		end

		for i, ln in pairs(file:readAll()) do
			if string.match(ln, "^PRODUCT") then
				local segments = 19
				local data_stream = { ln:match(("([^\t]*)\t?"):rep(segments)) }
				if (data_stream[2] == '45' and data_stream[18] == '0' and data_stream[19] == '0') then
					table.insert(data, { itemid = data_stream[4], name = data_stream[5], price = tonumber(data_stream[8]) })
				end
			end
		end
		file:close()

		return UIElement:qsort(data, "price", false)
	end

	function Torishop:getInventoryRaw(itemidOnly)
		local file = Files:new("torishop/invent.txt")
		if (not file.data) then
			return false
		end
		local data_types = {
			{ "inventid", numeric = true },
			{ "itemid", numeric = true },
			{ "upgrade_level", numeric = true },
			{ "flamename" },
			{ "activateable", bool = true },
			{ "flameid", numeric = true },
			{ "bodypartname" },
			{ "setname" },
			{ "active", bool = true },
			{ "tradeable", bool = true },
			{ "uploadable", bool = true },
			{ "setid", numeric = true },
			{ "sale", bool = true },
			{ "price", numeric = true },
			{ "unpackable", bool = true },
			{ "games_played", numeric = true },
			{ "upgrade_games", numeric = true },
			{ "upgrade_price", numeric = true }
		}
		local inventory = {}
		local itemUpdated = TB_ITEM_DETAILS and 0 or 1
		for i, ln in pairs(file:readAll()) do
			if string.match(ln, "^INVITEM") then
				local segments = #data_types + 1
				local data_stream = { ln:match(("([^\t]*)\t?"):rep(segments)) }
				local item = {}

				if (itemidOnly) then
					if (tonumber(data_stream[3]) == itemidOnly) then
						for i,v in pairs(data_types) do
							item[v[1]] = data_stream[i + 1]
							if (v.numeric) then
								item[v[1]] = tonumber(item[v[1]])
							end
							if (v.bool) then
								item[v[1]] = item[v[1]] == '1' and true or false
							end
						end
						item.name = TB_STORE_DATA[item.itemid].itemname
						if (item.itemid ~= ITEM_SHIAI_TOKEN) then
							table.insert(inventory, item)
						end
					end
				else
					for i,v in pairs(data_types) do
						item[v[1]] = data_stream[i + 1]
						if (v.numeric) then
							item[v[1]] = tonumber(item[v[1]])
						end
						if (v.bool) then
							item[v[1]] = item[v[1]] == '1' and true or false
						end
					end
					item.name = TB_STORE_DATA[item.itemid].itemname
					if (itemUpdated == 0 and type(TB_ITEM_DETAILS) == "table") then
						if (item.inventid == TB_ITEM_DETAILS.inventid) then
							TB_ITEM_DETAILS = item
							itemUpdated = 1
						end
					end
					if (item.itemid ~= ITEM_SHIAI_TOKEN) then
						table.insert(inventory, item)
					end
				end
			end
		end
		if (itemUpdated == 0) then
			TB_ITEM_DETAILS = nil
		end
		file:close()
		return inventory
	end

	function Torishop:getInventory(mode)
		local inventoryRaw = Torishop:getInventoryRaw()
		local inventory = {}
		local activatedTemp = {}
		for i,v in pairs(inventoryRaw) do
			if (v.itemid == ITEM_SET) then
				v.contents = {}
			end
			if (v.setid == 0) then
				if 	(mode == INVENTORY_ACTIVATED and v.active and not v.sale) or
				 	(mode == INVENTORY_DEACTIVATED and not v.active and not v.sale) or
					(mode == INVENTORY_MARKET and v.sale) or
					(mode == INVENTORY_ALL) then
					table.insert(inventory, v)
				end
			end
			if	(mode == INVENTORY_ACTIVATED and v.active and v.setid ~= 0) then
				table.insert(activatedTemp, v)
			end
		end
		if (mode == INVENTORY_ACTIVATED) then
			for i, v in pairs(activatedTemp) do
				local isInSet = false
				for j, k in pairs(inventory) do
					if (v.setid == k.inventid) then
						isInSet = true
						break
					end
				end
				if (not isInSet) then
					v.insideset = true
					for s, n in pairs(inventoryRaw) do
						if (v.setid == n.inventid) then
							v.parentset = n
							break
						end
					end
					for s, n in pairs(inventoryRaw) do
						if (n.setid == v.parentset.inventid) then
							table.insert(v.parentset.contents, n)
						end
					end
					table.insert(inventory, v)
				end
			end
		end
		for i,v in pairs(inventoryRaw) do
			if (v.setid ~= 0) then
				for j,k in pairs(inventory) do
					if (v.setid == k.inventid) then
						table.insert(k.contents, v)
						break
					end
				end
			end
		end
		return UIElement:qsort(inventory, "name", false)
	end

	function Torishop:quit()
		tbMenuCurrentSection:kill(true)
		tbMenuNavigationBar:kill(true)
		if (STORE_VANILLA_PREVIEW) then
			STORE_VANILLA_PREVIEW = false
			remove_hooks("storevanillapreview")
			set_option("uke", 1)
			tbMenuHide:show()
			storeVanillaHolder:kill()
			STORE_VANILLA_POST = true
			start_new_game()
		end
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end

	function Torishop:refreshInventory(showInventory)
		INVENTORY_UPDATE = false
		UIElement:runCmd("download " .. TB_MENU_PLAYER_INFO.username)
		if (showInventory) then
			Torishop:prepareInventory(tbMenuCurrentSection, true)
		end
	end
	
	function Torishop:getSectionNavButtons(viewElement, section)
		local buttons = {
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = function() TB_MENU_SPECIAL_SCREEN_ISOPEN = 0 Torishop:quit() end,
			}
		}
		local sections = {
			{
				text = TB_MENU_LOCALIZED.STOREACCOUNT,
				action = function() Torishop:showStoreSection(viewElement, 4) end,
				sectionId = TAB_ACCOUNT,
				right = true,
			},
			{
				text = TB_MENU_LOCALIZED.STOREADVANCED,
				action = function() Torishop:showStoreSection(viewElement, 3) end,
				sectionId = TAB_ADVANCED,
				right = true,
			},
			{
				text = TB_MENU_LOCALIZED.STORETEXTURES,
				action = function() Torishop:showStoreSection(viewElement, 2) end,
				sectionId = TAB_TEXTURES,
				right = true,
			},
			{
				text = TB_MENU_LOCALIZED.STORECOLORS,
				action = function() Torishop:showStoreSection(viewElement, 1) end,
				sectionId = TAB_COLORS,
				right = true,
			},
		}
		for i,v in pairs(sections) do
			--if (i ~= (5 - section)) then
				table.insert(buttons, v)
			--end
		end
		return buttons
	end

	function Torishop:getNavigationButtons(showBack)
		local navigation = {
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
				action = function() TB_MENU_SPECIAL_SCREEN_ISOPEN = 0 Torishop:quit() end,
				width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONTOMAIN, FONTS.BIG) * 0.65 + 30
			}
		}
		if (showBack) then
			local back = {
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = function()
					TB_SET_PAGE = 1
					Torishop:showInventory(tbMenuCurrentSection, nil, SHOW_EMPTY_SETS)
				end,
				width = 130
			}
			table.insert(navigation, back)
		end
		return navigation
	end

	function Torishop:showSetDetailsItems(viewElement, items)
		local itemScale = viewElement.size.h / 2 > 64 and 64 or viewElement.size.h / 2
		local line = 1
		local itemsPerLine = math.floor(viewElement.size.w / itemScale)
		local horizontalShift = (viewElement.size.w - itemsPerLine * itemScale) / 2
		for i,v in pairs(items) do
			if (line * itemScale > viewElement.size.h) then
				break
			end
			local iconHolder = UIElement:new({
				parent = viewElement,
				pos = { horizontalShift + ((i - 1) % itemsPerLine) * itemScale, (line - 1) * itemScale },
				size = { itemScale, itemScale }
			})
			local icon = UIElement:new({
				parent = iconHolder,
				pos = { 2, 2 },
				size = { itemScale - 4, itemScale - 4 },
				bgImage = "../textures/store/items/" .. v.itemid .. ".tga"
			})
			if (i % itemsPerLine == 0) then
				line = line + 1
			end
		end
	end
	
	function Torishop:getItemToDeactivate(item)
		for i,v in pairs(Torishop:getInventoryRaw()) do
			if (v.active) then
				if (TB_STORE_DATA[item.itemid].catid == TB_STORE_DATA[v.itemid].catid) then
					if (TB_STORE_DATA[item.itemid].catid == 78 and TB_STORE_MODELS[v.itemid]) then
						local nModelInfo = TB_STORE_MODELS[item.itemid]
						if (TB_STORE_MODELS[item.itemid].upgradeable) then
							nModelInfo = TB_STORE_MODELS[item.itemid][item.upgrade_level]
						end
						local modelInfo = TB_STORE_MODELS[v.itemid]
						if (TB_STORE_MODELS[v.itemid].upgradeable) then
							modelInfo = TB_STORE_MODELS[v.itemid][v.upgrade_level]
						end
						if (nModelInfo.bodyid == modelInfo.bodyid) then
							return v
						end
					elseif (not in_array(TB_STORE_DATA[item.itemid].catid, { 50, 54, 55, 56, 57, 58, 59, 71, 74, 75 })) then
						return v
					end
				end
			end
		end
		return false
	end

	function Torishop:showInventoryItem(item)
		inventoryItemView:kill(true)
		TB_ITEM_DETAILS = item

		local bottomSmudge = TBMenu:addBottomBloodSmudge(inventoryItemView, 2)
		local itemData = TB_STORE_DATA[item.itemid]
		if (item.itemid == ITEM_SET) then
			local itemName = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, 0 },
				size = { inventoryItemView.size.w - 20, 50 }
			})

			local numItemsStr = "(" .. TB_MENU_LOCALIZED.STORESETEMPTY .. ")"
			if (#item.contents == 1) then
				numItemsStr = "(1 " .. TB_MENU_LOCALIZED.STOREITEM .. ")"
			elseif (#item.contents > 1) then
				numItemsStr = "(" .. #item.contents .. " " .. TB_MENU_LOCALIZED.STOREITEMS .. ")"
			end

			itemName:addAdaptedText(true, item.name .. " " .. numItemsStr, nil, nil, FONTS.BIG, nil, 0.6, nil, 0.2)
			local setName = UIElement:new({
				parent = inventoryItemView,
				pos = { 0, itemName.size.h },
				size = { inventoryItemView.size.w, 20 }
			})
			setName:addAdaptedText(true, item.setname)
			local inventoryViewHeight = inventoryItemView.size.h / 2 - itemName.size.h - setName.size.h
			inventoryViewHeight = inventoryViewHeight > 100 and 100 or inventoryViewHeight
			local inventoryView = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, itemName.size.h + setName.size.h + 10 },
				size = { inventoryItemView.size.w - 20, inventoryViewHeight }
			})
			if (#item.contents > 0) then
				Torishop:showSetDetailsItems(inventoryView, item.contents)
			else
				inventoryView:addAdaptedText(true, itemData.description, nil, nil, 4, LEFTMID, 0.7)
			end
		elseif (item.itemid == ITEM_FLAME) then
			local itemName = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, 0 },
				size = { inventoryItemView.size.w - 20, 50 }
			})
			itemName:addAdaptedText(true, item.name, nil, nil, FONTS.BIG, nil, 0.6, nil, 0.2)
			local flameName = UIElement:new({
				parent = inventoryItemView,
				pos = { 0, itemName.size.h },
				size = { inventoryItemView.size.w, 20 }
			})
			flameName:addAdaptedText(true, item.flamename)
			local itemInfoHeight = inventoryItemView.size.h / 2 - itemName.size.h - flameName.size.h
			itemInfoHeight = itemInfoHeight > 100 and 100 or itemInfoHeight
			local itemInfo = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, itemName.size.h + flameName.size.h + 10 },
				size = { inventoryItemView.size.w - 20, itemInfoHeight }
			})
			local itemIcon = UIElement:new({
				parent = itemInfo,
				pos = { 0, (itemInfo.size.h - 64) / 2 },
				size = { 64, 64 },
				bgImage = "../textures/store/items/" .. item.itemid .. ".tga"
			})
			local itemDescription = UIElement:new({
				parent = itemInfo,
				pos = { 69, 0 },
				size = { itemInfo.size.w - 69, itemInfo.size.h }
			})
			itemDescription:addAdaptedText(true, TB_MENU_LOCALIZED.STOREFLAMEBODYPART .. " ".. item.bodypartname:lower() .. "\n" .. TB_MENU_LOCALIZED.STOREFLAMEID .. ": " .. item.flameid, nil, nil, 4, LEFTMID, 0.7)
		else
			local itemLevel = item.upgrade_level > 0 and " (LVL " .. item.upgrade_level .. ")" or ""
			if (item.insideset) then
				local itemName = UIElement:new({
					parent = inventoryItemView,
					pos = { 10, 0 },
					size = { inventoryItemView.size.w - 20, 50 }
				})
				itemName:addAdaptedText(nil, item.name .. itemLevel, nil, nil, FONTS.BIG, nil, 0.6, nil, 0.2)
				local setCaption = UIElement:new({
					parent = inventoryItemView,
					pos = { 10, 50 },
					size = { inventoryItemView.size.w - 20, 20 }
				})
				setCaption:addAdaptedText(nil, TB_MENU_LOCALIZED.STOREITEMINSIDESET .. ": " .. item.parentset.setname)
			else
				local itemName = UIElement:new({
					parent = inventoryItemView,
					pos = { 10, 0 },
					size = { inventoryItemView.size.w - 20, 70 }
				})
				itemName:addAdaptedText(nil, item.name .. itemLevel, nil, nil, FONTS.BIG, nil, 0.6, nil, 0.2)
			end
			
			local itemInfoHeight = inventoryItemView.size.h / 2 - 80
			itemInfoHeight = itemInfoHeight > 100 and 100 or itemInfoHeight
			local itemInfo = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, 80 },
				size = { inventoryItemView.size.w - 20, itemInfoHeight }
			})
			local itemIcon = UIElement:new({
				parent = itemInfo,
				pos = { 0, (itemInfo.size.h - 64) / 2 },
				size = { 64, 64 },
				bgImage = Torishop:getItemIcon(item.itemid)
			})
			local itemDescription = UIElement:new({
				parent = itemInfo,
				pos = { 69, 0 },
				size = { itemInfo.size.w - 69, itemInfo.size.h }
			})
			local modelBodypartStr = ''
			if (item.bodypartname ~= '0') then
				modelBodypartStr = (item.uploadable and TB_MENU_LOCALIZED.STOREITEMRETEXTURABLE .. " " or "" ) .. TB_MENU_LOCALIZED.STOREOBJITEMBODYPART .. " " .. item.bodypartname:lower()
			end
			itemDescription:addAdaptedText(true, itemData.description .. "\n" .. modelBodypartStr, nil, nil, 4, LEFTMID, 0.7)
			
			if (item.upgrade_level > 0 and ((item.upgrade_games > 0 and item.games_played < item.upgrade_games) or (item.upgrade_price > 0 and item.upgrade_price > TB_MENU_PLAYER_INFO.data.tc))) then
				local itemUpgradeInfo = UIElement:new({
					parent = inventoryItemView,
					pos = { 10, itemInfo.size.h + itemInfo.shift.y + 10 },
					size = { inventoryItemView.size.w - 20, 30 }
				})
				local upgradeString = ''
				local gamesMentioned = false
				if (item.upgrade_games > item.games_played) then
					gamesMentioned = true
					upgradeString = "You need to play " .. (item.upgrade_games - item.games_played) .. " more fights with this item equipped "
				end
				if (item.upgrade_price > TB_MENU_PLAYER_INFO.data.tc) then
					upgradeString = upgradeString == '' and "You need to have " .. item.upgrade_price .. " Toricredits " or "and have " .. item.upgrade_price .. " Toricredits "
				end
				upgradeString = upgradeString .. "to be able to upgrade " .. (gamesMentioned and "it" or "this item")
				itemUpgradeInfo:addAdaptedText(true, upgradeString, nil, nil, 4, nil, 0.6)
			end
		end
		
		local buttonHeight = inventoryItemView.size.h / 10 > 40 and 40 or inventoryItemView.size.h / 10
		local buttonYPos = -buttonHeight * 1.1
		if (item.itemid ~= ITEM_SET) then
			local addSetButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, buttonHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			if (item.insideset) then
				addSetButton:addAdaptedText(nil, TB_MENU_LOCALIZED.STOREITEMGOTOSET)
				addSetButton:addMouseHandlers(nil, function()
						Torishop:showInventoryPage(item.parentset.contents, nil, mode, TB_MENU_LOCALIZED.STORESETITEMNAME .. ": " .. item.parentset.setname, "invid" .. item.parentset.inventid, nil, true)
					end)
			elseif (item.setid == 0) then
				addSetButton:addAdaptedText(nil, TB_MENU_LOCALIZED.STOREITEMADDTOSET)
				addSetButton:addMouseHandlers(nil, function()
						Torishop:showSetSelection(item)
					end)
			else
				addSetButton:addAdaptedText(nil, TB_MENU_LOCALIZED.STOREITEMREMOVEFROMSET)
				addSetButton:addMouseHandlers(nil, function()
						INVENTORY_UPDATE = true
						INVENTORY_MOUSE_POS = { x = posX, y = posY }
						INVENTORY_SELECTION_RESET = true
						local dialogMessage = TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET2 .. "?")
						show_dialog_box(INVENTORY_REMOVESET, dialogMessage, "0 " .. item.inventid)
					end)
			end
			buttonYPos = buttonYPos - buttonHeight * 1.2
		elseif (#item.contents > 0) then
			local viewSet = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, buttonHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			viewSet:addAdaptedText(nil, TB_MENU_LOCALIZED.STOREVIEWSETITEMS)
			viewSet:addMouseHandlers(nil, function()
					Torishop:showInventoryPage(item.contents, nil, mode, TB_MENU_LOCALIZED.STOREITEMSINSET .. ": " .. item.setname, "invid" .. item.inventid, nil, true)
				end, nil)
			buttonYPos = buttonYPos - buttonHeight * 1.2
		end
		--[[if (item.tradeable) then
			local marketSellButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.3 }
			})
			marketSellButton:addCustomDisplay(false, function()
					marketSellButton:uiText(TB_MENU_LOCALIZED.STORESELLMARKET, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
				end)
			marketSellButton:addMouseHandlers(nil, function()
					show_dialog_box(INVENTORY_MARKETSELL, item.inventid, TB_MENU_LOCALIZED.STOREDIALOGMARKETSELL1 .. " " .. item.name .. " " .. TB_MENU_LOCALIZED.STOREDIALOGMARKETSELL2)
				end, nil)
			buttonYPos = buttonYPos - inventoryItemView.size.h / 7
		end--]]
		if (item.upgrade_level > 0 and (item.upgrade_games > 0 or item.upgrade_price > 0) and item.games_played >= item.upgrade_games and item.upgrade_price <= TB_MENU_PLAYER_INFO.data.tc) then
			local upgradeButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, buttonHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			upgradeButton:addAdaptedText(nil, TB_MENU_LOCALIZED.STOREITEMUPGRADEFOR .. " " .. (item.upgrade_price > 0 and (item.upgrade_price .. " TC") or TB_MENU_LOCALIZED.STOREITEMUPGRADEPRICEFREE))
			upgradeButton:addMouseHandlers(nil, function()
					INVENTORY_UPDATE = true
					INVENTORY_MOUSE_POS = { x = posX, y = posY }
					show_dialog_box(INVENTORY_UPGRADE, TB_MENU_LOCALIZED.STOREDIALOGUPGRADE1 .. "\n" .. item.name .. " ".. TB_MENU_LOCALIZED.STOREDIALOGUPGRADE2 .. " " .. (item.upgrade_level + 1) .. "?", item.inventid)
				end)
			buttonYPos = buttonYPos - buttonHeight * 1.2
		end
		if (item.uploadable) then
			local customizeButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, buttonHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			TBMenu:showTextWithImage(customizeButton, TB_MENU_LOCALIZED.STOREITEMSCUSTOMIZE, FONTS.MEDIUM, customizeButton.size.h / 3 * 2, "../textures/menu/general/buttons/external.tga")
			customizeButton:addMouseHandlers(nil, function()
					open_url("https://forum.toribash.com/tori_item.php?invid=" .. item.inventid)
				end)
			buttonYPos = buttonYPos - buttonHeight * 1.2
		end
		if (item.activateable and not item.unpackable) then
			local activateButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, buttonHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			if (item.active) then
				activateButton:addAdaptedText(nil, TB_MENU_LOCALIZED.STOREITEMDEACTIVATE)
				activateButton:addMouseHandlers(nil, function(s, posX, posY)
						INVENTORY_UPDATE = true
						INVENTORY_MOUSE_POS = { x = posX, y = posY }
						show_dialog_box(INVENTORY_DEACTIVATE, TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 .. "?"), item.inventid)
					end, nil)
			else
				local itemToDeactivate = Torishop:getItemToDeactivate(item)
				activateButton:addAdaptedText(nil, TB_MENU_LOCALIZED.STOREITEMACTIVATE)
				activateButton:addMouseHandlers(nil, function()
						INVENTORY_UPDATE = true
						INVENTORY_MOUSE_POS = { x = posX, y = posY }
						show_dialog_box(INVENTORY_ACTIVATE, TB_MENU_LOCALIZED.STOREDIALOGACTIVATE1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 .. "?") .. "\n" .. (itemToDeactivate and itemToDeactivate.name .. " " .. TB_MENU_LOCALIZED.STOREDIALOGITEMCONFLICTDEACTIVATE or TB_MENU_LOCALIZED.STOREDIALOGCONFLICTSDEACTIVATE), item.inventid)
					end, nil)
			end
		elseif (item.unpackable) then
			local unpackButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, buttonHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			unpackButton:addAdaptedText(nil, TB_MENU_LOCALIZED.STOREITEMUNPACK)
			unpackButton:addMouseHandlers(nil, function()
					INVENTORY_UPDATE = true
					INVENTORY_MOUSE_POS = { x = posX, y = posY }
					show_dialog_box(INVENTORY_UNPACK, TB_MENU_LOCALIZED.STOREDIALOGUNPACK1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 .. "?") .. "\n" .. TB_MENU_LOCALIZED.STOREDIALOGUNPACKINFO, item.inventid)
				end, nil)
		end
	end

	function Torishop:showSetSelection(item)
		inventoryItemView:kill(true)

		local inventory = Torishop:getInventory(INVENTORY_ALL)
		local sets = {}
		for i,v in pairs(inventory) do
			if (v.itemid == ITEM_SET) then
				table.insert(sets, v)
			end
		end
		local toReload = UIElement:new({
			parent = inventoryItemView,
			pos = { 0, 0 },
			size = { inventoryItemView.size.w, inventoryItemView.size.h }
		})
		local topBar = UIElement:new({
			parent = toReload,
			pos = { 0, 0 },
			size = { toReload.size.w, 50 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local topBarName = UIElement:new({
			parent = topBar,
			pos = { 10, 0 },
			size = { topBar.size.w - 20, topBar.size.h }
		})
		topBarName:addCustomDisplay(true, function()
				topBarName:uiText(TB_MENU_LOCALIZED.STORESETSELECT, nil, nil, FONTS.MEDIUM, nil, nil, nil, nil, nil, nil, 0.2)
			end)
		local buttonHeight = inventoryItemView.size.h / 10 > 40 and 40 or inventoryItemView.size.h / 10
		local botBar = UIElement:new({
			parent = toReload,
			pos = { 0, -50 },
			size = { toReload.size.w, 50 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local bottomSmudge = TBMenu:addBottomBloodSmudge(botBar, 2)
		local cancelButton = UIElement:new({
			parent = botBar,
			pos = { 10, 50 - buttonHeight * 1.1 },
			size = { botBar.size.w - 20, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		cancelButton:addAdaptedText(nil, TB_MENU_LOCALIZED.STOREBUTTONCANCEL)
		cancelButton:addMouseHandlers(nil, function()
				if (item) then
					Torishop:showInventoryItem(item)
				else
					Torishop:showSelectionControls()
				end
			end)

		local mainHolder = UIElement:new({
			parent = inventoryItemView,
			pos = { 0, topBar.size.h },
			size = { inventoryItemView.size.w, inventoryItemView.size.h - topBar.size.h - botBar.size.h }
		})
		local setsHolder = UIElement:new({
			parent = mainHolder,
			pos = { 0, 0 },
			size = { mainHolder.size.w - 20, mainHolder.size.h }
		})
		local listSets = {}
		for i,v in pairs(sets) do
			local setElement = UIElement:new({
				parent = setsHolder,
				pos = { 0, #listSets * 40 },
				size = { setsHolder.size.w, 40 },
				interactive = true,
				bgColor = { 0, 0, 0, 0 },
				hoverColor = { 0, 0, 0, 0.2 },
				pressedColor = TB_MENU_DEFAULT_DARKER_COLOR
			})
			setElement:addMouseHandlers(nil, function()
					INVENTORY_UPDATE = true
					INVENTORY_MOUSE_POS = { x = posX, y = posY }
					INVENTORY_SELECTION_RESET = true
					if (item) then
						show_dialog_box(INVENTORY_ADDSET, TB_MENU_LOCALIZED.STOREDIALOGADDTOSET1 .. " " .. item.name .. " " .. TB_MENU_LOCALIZED.STOREDIALOGADDTOSET2 .. "?", v.inventid .. " " .. item.inventid)
					else
						local inventidStr = ""
						for i,v in pairs(INVENTORY_SELECTED_ITEMS) do
							inventidStr = inventidStr == "" and v.inventid or inventidStr .. ";" .. v.inventid
						end
						local itemsStr = #INVENTORY_SELECTED_ITEMS == 1 and INVENTORY_SELECTED_ITEMS[1].name or #INVENTORY_SELECTED_ITEMS .. " " .. TB_MENU_LOCALIZED.STOREITEMS
						show_dialog_box(INVENTORY_ADDSET, TB_MENU_LOCALIZED.STOREDIALOGADDTOSET1 .. " " .. itemsStr .. " " .. TB_MENU_LOCALIZED.STOREDIALOGADDTOSET2 .. "?", v.inventid .. " " .. inventidStr)
					end
				end)
			table.insert(listSets, setElement)
			local icon = UIElement:new({
				parent = setElement,
				pos = { 5, 5 },
				size = { setElement.size.h - 10, setElement.size.h - 10 },
				bgImage = "../textures/store/items/" .. ITEM_SET .. ".tga"
			})
			local setName = UIElement:new({
				parent = setElement,
				pos = { setElement.size.h, 0 },
				size = { setElement.size.w - setElement.size.h, setElement.size.h }
			})
			local itemsStr
			if (#v.contents == 0) then
				itemsStr = "(" .. TB_MENU_LOCALIZED.STORESETEMPTY .. ")"
			elseif (#v.contents == 1) then
				itemsStr = "(1 " .. TB_MENU_LOCALIZED.STOREITEM .. ")"
			else
				itemsStr = "(" .. #v.contents .. " " .. TB_MENU_LOCALIZED.STOREITEMS .. ")"
			end
			setName:addCustomDisplay(true, function()
					setName:uiText(v.setname .. " " .. itemsStr, nil, nil, 4, LEFTMID, 0.7)
				end)
		end

		for i,v in pairs(listSets) do
			v:hide()
		end

		local scrollBar = TBMenu:spawnScrollBar(setsHolder, #listSets, 40)
		scrollBar:makeScrollBar(setsHolder, listSets, toReload)
	end

	function Torishop:showSelectionControls()
		inventoryItemView:kill(true)

		local bottomSmudge = TBMenu:addBottomBloodSmudge(inventoryItemView, 2)
		local controlsName = UIElement:new({
			parent = inventoryItemView,
			pos = { 10, 0 },
			size = { inventoryItemView.size.w - 20, 50 }
		})
		controlsName:addAdaptedText(true, TB_MENU_LOCALIZED.STORESETSELECTIONCONTROLS, nil, nil, FONTS.BIG, nil, 0.6, nil, 0.2)
		local controlsInfo = UIElement:new({
			parent = inventoryItemView,
			pos = { 10, 50 },
			size = { inventoryItemView.size.w - 20, 20 }
		})
		controlsInfo:addAdaptedText(true, #INVENTORY_SELECTED_ITEMS == 1 and INVENTORY_SELECTED_ITEMS[1].name or (#INVENTORY_SELECTED_ITEMS .. " " .. TB_MENU_LOCALIZED.STOREITEMS))
		
		local selectionViewHeight = inventoryItemView.size.h / 2 - controlsName.size.h - controlsInfo.size.h
		selectionViewHeight = selectionViewHeight > 100 and 100 or selectionViewHeight
		local selectionView = UIElement:new({
			parent = inventoryItemView,
			pos = { 10, controlsName.size.h + controlsInfo.size.h + 10 },
			size = { inventoryItemView.size.w - 20, selectionViewHeight }
		})
		Torishop:showSetDetailsItems(selectionView, INVENTORY_SELECTED_ITEMS)
		
		local buttonHeight = inventoryItemView.size.h / 10 > 40 and 40 or inventoryItemView.size.h / 10
		local buttonYPos = -buttonHeight * 1.1
		
		local showAddSet, showActivate, showDeactivate, showRemoveSet = true, false, false, false
		for i,v in pairs(INVENTORY_SELECTED_ITEMS) do
			if (v.active) then
				showDeactivate = true
			else
				showActivate = true
			end
			if (v.insideset) then
				showRemoveSet = true
			end
		end
		
		local itemsStr = #INVENTORY_SELECTED_ITEMS == 1 and INVENTORY_SELECTED_ITEMS[1].name or #INVENTORY_SELECTED_ITEMS .. " " .. TB_MENU_LOCALIZED.STOREITEMS
		
		local cleanSelection = UIElement:new({
			parent = inventoryItemView,
			pos = { 10, buttonYPos },
			size = { inventoryItemView.size.w - 20, buttonHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		cleanSelection:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMSCLEANSELECTION)
		cleanSelection:addMouseHandlers(nil, function()
				for i = #INVENTORY_SELECTED_ITEMS, 1, -1 do
					table.remove(INVENTORY_SELECTED_ITEMS, i)
				end
				Torishop:showInventory(tbMenuCurrentSection)
				Torishop:showInventoryItem(TB_ITEM_DETAILS)
			end)
		buttonYPos = buttonYPos - buttonHeight * 1.2
		if (showRemoveSet) then
			local removeSetButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, buttonHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			removeSetButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMREMOVEFROMSET)
			removeSetButton:addMouseHandlers(nil, function()
					INVENTORY_UPDATE = true
					INVENTORY_MOUSE_POS = { x = posX, y = posY }
					INVENTORY_SELECTION_RESET = true
					local inventidStr = ""
					for i,v in pairs(INVENTORY_SELECTED_ITEMS) do
						inventidStr = inventidStr == "" and v.inventid or inventidStr .. ";" .. v.inventid
					end
					show_dialog_box(INVENTORY_REMOVESET, TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET1 .. " " .. itemsStr .. " " .. TB_MENU_LOCALIZED.STOREDIALOGREMOVEFROMSET2 .. "?", "0 " .. inventidStr)
				end)
			buttonYPos = buttonYPos - buttonHeight * 1.2
		end
		
		if (showAddSet) then
			local addSetButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, buttonHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			addSetButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMADDTOSET)
			addSetButton:addMouseHandlers(nil, function()
					Torishop:showSetSelection(false)
				end)
			buttonYPos = buttonYPos - buttonHeight * 1.2
		end
		
		if (showDeactivate) then
			local deactivateButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, buttonHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			deactivateButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMDEACTIVATE)
			deactivateButton:addMouseHandlers(nil, function()
					INVENTORY_UPDATE = true
					INVENTORY_MOUSE_POS = { x = posX, y = posY }
					INVENTORY_SELECTION_RESET = true
					local inventidStr = ""
					for i,v in pairs(INVENTORY_SELECTED_ITEMS) do
						inventidStr = inventidStr == "" and v.inventid or inventidStr .. ";" .. v.inventid
					end
					show_dialog_box(INVENTORY_DEACTIVATE, TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE1 .. " " .. itemsStr .. (TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 .. "?"), inventidStr)
				end)
			buttonYPos = buttonYPos - buttonHeight * 1.2
		end
		
		if (showActivate) then
			local activateButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, buttonHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			activateButton:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMACTIVATE)
			activateButton:addMouseHandlers(nil, function()
					INVENTORY_UPDATE = true
					INVENTORY_MOUSE_POS = { x = posX, y = posY }
					INVENTORY_SELECTION_RESET = true
					local inventidStr = ""
					for i,v in pairs(INVENTORY_SELECTED_ITEMS) do
						inventidStr = inventidStr == "" and v.inventid or inventidStr .. ";" .. v.inventid
					end
					show_dialog_box(INVENTORY_ACTIVATE, TB_MENU_LOCALIZED.STOREDIALOGACTIVATE1 .. " " .. itemsStr .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 .. "?") .. "\n" .. TB_MENU_LOCALIZED.STOREDIALOGCONFLICTSDEACTIVATE, inventidStr)
				end)
		end
	end

	-- Deprecated
	--[[function Torishop:showInventorySingleItemData(itemView, item, itemScale)
		local icon = UIElement:new({
			parent = itemView,
			pos = { (itemScale - 64) / 2, (itemScale - 64) / 2 },
			size = { 64, 64 },
			bgImage = "../textures/store/items/" .. item.itemid .. ".tga"
		})
		local info = UIElement:new({
			parent = itemView,
			pos = { 0, itemView.size.h / 2 },
			size = { itemView.size.w, itemView.size.h / 2 - itemView.rounded }
		})
		if (item.itemid ~= ITEM_SET) then
			local itemSelected = false
			for i,v in pairs(INVENTORY_SELECTED_ITEMS) do
				if (v.inventid == item.inventid) then
					itemSelected = true
					break
				end
			end
			local selectBox = UIElement:new({
				parent = itemView,
				pos = { -30, 10 },
				size = { 20, 20 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.2 },
				hoverColor = { 0, 0, 0, 0.4 }
			})
			local selectIcon = UIElement:new({
				parent = selectBox,
				pos = { 0, 0 },
				size = { selectBox.size.w, selectBox.size.h },
				bgImage = "../textures/menu/general/buttons/checkmark.tga"
			})
			if (not itemSelected) then
				selectIcon:hide(true)
			end

			selectBox:addMouseHandlers(nil, function()
					for i,v in pairs(INVENTORY_SELECTED_ITEMS) do
						if (v.inventid == item.inventid) then
							table.remove(INVENTORY_SELECTED_ITEMS, i)
							selectIcon:hide()
							if (#INVENTORY_SELECTED_ITEMS == 0) then
								Torishop:showInventoryItem(TB_ITEM_DETAILS)
							else
								Torishop:showSelectionControls()
							end
							return
						end
					end
					table.insert(INVENTORY_SELECTED_ITEMS, item)
					Torishop:showSelectionControls()
					selectIcon:show(true)
				end)
		end

		local setname = ""
		local setNumItems = ""
		if (item.itemid == ITEM_SET) then
			setname = item.setname == '0' and "" or ": " .. item.setname
			setNumItems = " (" .. TB_MENU_LOCALIZED.STORESETEMPTY .. ")"
			if (#item.contents == 1) then
				setNumItems = " (1 " .. TB_MENU_LOCALIZED.STOREITEM .. ")"
			elseif (#item.contents > 1) then
				setNumItems = " (" .. #item.contents .. " " .. TB_MENU_LOCALIZED.STOREITEMS .. ")"
			end
		end
		info:addCustomDisplay(false, function()
				local color = itemView:getButtonColor()
				set_color(color[1], color[2], color[3], color[4] * 2)
				draw_quad(info.pos.x, info.pos.y, info.size.w, info.size.h)
				info:uiText(item.name .. setname .. setNumItems, nil, nil, 4, nil, 0.5, nil, nil, { 1 - color[1], 1 - color[2], 1 - color[3], color[4] * 3 })
			end)
	end]]

	function Torishop:showInventoryPage(inventoryItems, pageShift, mode, title, pageid, itemScale, showBack)
		local showBack = showBack or false
		local itemScale = itemScale or 100

		local inventoryModes = {
			{
				text = TB_MENU_LOCALIZED.STOREDEACTIVATEDINVENTORY,
				action = function() Torishop:showInventory(tbMenuCurrentSection, INVENTORY_DEACTIVATED) end
			},
			{
				text = TB_MENU_LOCALIZED.STOREACTIVATEDINVENTORY,
				action = function() Torishop:showInventory(tbMenuCurrentSection, INVENTORY_ACTIVATED) end
			},
			{
				text = TB_MENU_LOCALIZED.STOREMARKETINVENTORY,
				action = function() Torishop:showInventory(tbMenuCurrentSection, INVENTORY_MARKET) end
			},
			{
				text = TB_MENU_LOCALIZED.STOREINVENTORYALLITEMS,
				action = function() Torishop:showInventory(tbMenuCurrentSection, INVENTORY_ALL) end
			}
		}

		TB_INVENTORY_PAGE[pageid] = TB_INVENTORY_PAGE[pageid] or 1

		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar(Torishop:getNavigationButtons(showBack), true)

		inventoryView:kill(true)
		
		local elementHeight = 56
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(inventoryView, elementHeight, elementHeight - 16, 20, TB_MENU_DEFAULT_BG_COLOR)
		local bottomSmudge = TBMenu:addBottomBloodSmudge(botBar, 1)
		
		local itemsPerPage = 100
		local maxPages = math.ceil(#inventoryItems / itemsPerPage)
		
		local page = pageShift and TB_INVENTORY_PAGE[pageid] + pageShift or TB_INVENTORY_PAGE[pageid]
		page = page < 1 and maxPages or page
		TB_INVENTORY_PAGE[pageid] = page > maxPages and 1 or page

		local invStartShift = 1 + (TB_INVENTORY_PAGE[pageid] - 1) * itemsPerPage

		local inventoryTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 10 },
			size = { maxPages > 1 and (topBar.size.w / 2 > 320 and topBar.size.w - 330 or topBar.size.w / 2 - 10) or topBar.size.w - 20, topBar.size.h - 20 }
		})
		if (mode) then
			local dropdownBG = UIElement:new({
				parent = inventoryTitle,
				pos = { 0, 0 },
				size = { inventoryTitle.size.w, inventoryTitle.size.h },
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			local dropdown = UIElement:new({
				parent = dropdownBG,
				pos = { 1, 1 },
				size = { dropdownBG.size.w - 2, dropdownBG.size.h - 2 },
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				interactive = true,
			})
			TBMenu:spawnDropdown(dropdown, inventoryModes, 30, nil, inventoryModes[mode], nil, FONTS.MEDIUM, 0.6)
		else
			inventoryTitle:addAdaptedText(true, title, nil, nil, FONTS.BIG)
		end
		
		if (maxPages > 1) then
			local pagesCount = UIElement:new({
				parent = topBar,
				pos = { inventoryTitle.size.w + 10, 10 },
				size = { topBar.size.w - inventoryTitle.size.w - 20, topBar.size.h - 20 }
			})
			pagesCount:addAdaptedText(true, TB_MENU_LOCALIZED.PAGINATIONPAGE:upper() .. " " .. TB_INVENTORY_PAGE[pageid] .. " " .. TB_MENU_LOCALIZED.PAGINATIONPAGEOF:upper() .. " " .. maxPages, nil, nil, 4, LEFTMID, 0.6)
			local strlen = get_string_length(pagesCount.dispstr[1], pagesCount.textFont) * pagesCount.textScale
			local pagesButtonsHolder = UIElement:new({
				parent = pagesCount,
				pos = { strlen + 10, 0 },
				size = { pagesCount.size.w - strlen - 10, pagesCount.size.h }
			})
			local pagesButtons = { 1 }
			if (maxPages > 7) then
				if (TB_INVENTORY_PAGE[pageid] > 4) then
					for i = TB_INVENTORY_PAGE[pageid] - 2, maxPages - 1 < TB_INVENTORY_PAGE[pageid] and maxPages - 1 or TB_INVENTORY_PAGE[pageid] do
						table.insert(pagesButtons, i)
					end
				else
					for i = 2, TB_INVENTORY_PAGE[pageid] do
						table.insert(pagesButtons, i)
					end
				end
				if (TB_INVENTORY_PAGE[pageid] < maxPages - 3) then
					for i = TB_INVENTORY_PAGE[pageid] + 1, TB_INVENTORY_PAGE[pageid] + 2 do
						table.insert(pagesButtons, i)
					end
				else
					for i = TB_INVENTORY_PAGE[pageid] + 1, maxPages - 1 do
						table.insert(pagesButtons, i)
					end
				end
				table.insert(pagesButtons, maxPages)
			else
				for i = 2, maxPages do
					table.insert(pagesButtons, i)
				end
			end
			
			-- Remove buttons that don't fit the screen
			-- Buttons count has to be stored separately, #pagesButtons may be returning incorrect result from this point on
			local sgn = 1
			local pagesButtonsCount = #pagesButtons
			local buttonWidth = pagesButtonsHolder.size.h / 6 * 5
			local buttonHeight = buttonWidth
			while (pagesButtonsCount * buttonWidth > pagesButtonsHolder.size.w) do
				table.remove(pagesButtons, sgn > 0 and ((pagesButtons[1 + sgn] == 2 and pagesButtonsCount == 6) and pagesButtonsCount - sgn or 1 + sgn) or pagesButtonsCount + sgn)
				sgn = sgn * -1
				pagesButtonsCount = pagesButtonsCount - 1
			end
			local pageButtons = {}
			for i,v in pairs(pagesButtons) do
				local buttonHolder = UIElement:new({
					parent = pagesButtonsHolder,
					pos = { pagesButtonsHolder.size.w - (pagesButtonsCount - #pageButtons) * buttonWidth, 0 },
					size = { buttonWidth, pagesButtonsHolder.size.h }
				})
				table.insert(pageButtons, buttonHolder)
				local button = UIElement:new({
					parent = buttonHolder,
					pos = { 5, 0 },
					size = { buttonHolder.size.w - 5, buttonHolder.size.h },
					interactive = v ~= TB_INVENTORY_PAGE[pageid],
					bgColor = v == TB_INVENTORY_PAGE[pageid] and TB_MENU_DEFAULT_LIGHTER_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				})
				button:addAdaptedText(nil, v .. "", nil, nil, 4, nil, 0.6)
				button:addMouseHandlers(nil, function()
						Torishop:showInventoryPage(inventoryItems, -(TB_INVENTORY_PAGE[pageid] - v), mode, title, pageid, itemScale, showBack)
					end)
			end
			pagesCount:addAdaptedText(true, TB_MENU_LOCALIZED.PAGINATIONPAGE:upper() .. " " .. TB_INVENTORY_PAGE[pageid] .. " " .. TB_MENU_LOCALIZED.PAGINATIONPAGEOF:upper() .. " " .. maxPages, -pagesButtonsCount * buttonWidth - 5, nil, 4, RIGHTMID, 0.6)
		end
		
		local showEmptySets = UIElement:new({
			parent = botBar,
			pos = { 10, 10 },
			size = { botBar.size.w / 2 - 20, botBar.size.h - 10 }
		})
		local showEmptySetsIconOutline = UIElement:new({
			parent = showEmptySets,
			pos = { 0, 5 },
			size = { 25, 25 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local showEmptySetsIconBG = UIElement:new({
			parent = showEmptySetsIconOutline,
			pos = { 1, 1 },
			size = { showEmptySetsIconOutline.size.w - 2, showEmptySetsIconOutline.size.h - 2 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		if (SHOW_EMPTY_SETS == 1) then
			local showEmptySetsIcon = UIElement:new({
				parent = showEmptySetsIconBG,
				pos = { 0, 0 },
				size = { showEmptySetsIconBG.size.w, showEmptySetsIconBG.size.h },
				bgImage = "../textures/menu/general/buttons/checkmark.tga"
			})
		end
		local showEmptySetsText = UIElement:new({
			parent = showEmptySets,
			pos = { 35, 5 },
			size = { showEmptySets.size.w - 35, 25 },
			interactive = true
		})
		showEmptySetsText:addAdaptedText(nil, TB_MENU_LOCALIZED.STORESHOWEMPTYSETS, nil, nil, nil, LEFTMID)
		showEmptySetsIconBG:addMouseHandlers(nil, function()
				Torishop:showInventory(tbMenuCurrentSection, nil, math.abs(SHOW_EMPTY_SETS - 1))
			end)
		showEmptySetsText:addMouseHandlers(nil, function()
				Torishop:showInventory(tbMenuCurrentSection, nil, math.abs(SHOW_EMPTY_SETS - 1))
			end)
		
		local refreshInventory = UIElement:new({
			parent = botBar,
			pos = { -botBar.size.w / 3, 10 },
			size = { botBar.size.w / 3 - 10, 35 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		refreshInventory:addAdaptedText(nil, TB_MENU_LOCALIZED.STOREINVENTORYRELOAD, nil, nil, nil, nil, 0.9)
		refreshInventory:addMouseHandlers(nil, function()
				Torishop:prepareInventory(tbMenuCurrentSection, true)
			end)
		
		local listElements = {}
		
		for i = invStartShift, #inventoryItems > invStartShift + itemsPerPage and invStartShift + itemsPerPage or #inventoryItems do
			local inventoryItem = UIElement:new({
				parent = listingHolder,
				pos = { 10, #listElements * elementHeight },
				size = { listingHolder.size.w - 10, elementHeight }
			})
			table.insert(listElements, inventoryItem)
			local invItemHolder = UIElement:new({
				parent = inventoryItem,
				pos = { 0, 3 },
				size = { inventoryItem.size.w, inventoryItem.size.h - 6 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			invItemHolder:addMouseHandlers(nil, function()
					Torishop:showInventoryItem(inventoryItems[i])
				end)
			local item = Torishop:getItemInfo(inventoryItems[i].itemid)
			local itemIcon = UIElement:new({
				parent = invItemHolder,
				pos = { 8, 2 },
				size = { invItemHolder.size.h - 4, invItemHolder.size.h - 4 },
				bgImage = Torishop:getItemIcon(item.itemid)
			})
			local itemInfoHolder = UIElement:new({
				parent = invItemHolder,
				pos = { invItemHolder.size.h + 15, 2 },
				size = { (invItemHolder.size.w - invItemHolder.size.h - 30) / 3 * 2, invItemHolder.size.h - 4 }
			})
			
			local itemNameString = item.itemname
			if (inventoryItems[i].upgrade_level > 0) then
				itemNameString = itemNameString .. " (LVL " .. inventoryItems[i].upgrade_level .. ")"
			end
			if (inventoryItems[i].flamename ~= '0') then
				itemNameString = itemNameString .. ": " .. inventoryItems[i].flamename
			end
			if (inventoryItems[i].setname ~= '0') then
				itemNameString = inventoryItems[i].setname
			end
			if (inventoryItems[i].bodypartname ~= '0' or inventoryItems[i].setname ~= '0') then
				local itemName = UIElement:new({
					parent = itemInfoHolder,
					pos = { 0, 0 },
					size = { itemInfoHolder.size.w, itemInfoHolder.size.h / 3 * 2 }
				})
				itemName:addAdaptedText(true, itemNameString, nil, nil, FONTS.BIG, LEFTMID, nil, nil, 0.2)
				local itemExtra = UIElement:new({
					parent = itemInfoHolder,
					pos = { 0, itemName.size.h },
					size = { itemInfoHolder.size.w, itemInfoHolder.size.h - itemName.size.h }
				})
				if (inventoryItems[i].bodypartname ~= '0') then
					local bodypartString = (TB_STORE_MODELS[item.itemid] and TB_MENU_LOCALIZED.INVENTORY3DITEMFOR or TB_MENU_LOCALIZED.STOREFLAMEBODYPART) .. " " .. inventoryItems[i].bodypartname
					itemExtra:addAdaptedText(true, bodypartString, nil, nil, 4, LEFTMID)
				else
					local numItemsStr = TB_MENU_LOCALIZED.STORESETEMPTY .. " " .. TB_MENU_LOCALIZED.STORESETITEMNAME
					if (#inventoryItems[i].contents == 1) then
						numItemsStr = "1 " .. TB_MENU_LOCALIZED.STOREITEMSINSET:lower()
					elseif (#inventoryItems[i].contents > 1) then
						numItemsStr = #inventoryItems[i].contents .. " " .. TB_MENU_LOCALIZED.STOREITEMSINSET:lower()
					end
					itemExtra:addAdaptedText(true, numItemsStr, nil, nil, 4, LEFTMID)
				end
			else
				local itemName = UIElement:new({
					parent = itemInfoHolder,
					pos = { 0, itemInfoHolder.size.h / 6 },
					size = { itemInfoHolder.size.w, itemInfoHolder.size.h / 3 * 2 }
				})
				itemName:addAdaptedText(true, itemNameString, nil, nil, FONTS.BIG, LEFTMID, nil, nil, 0.2)
			end
			local lShift = 10
			if (inventoryItems[i].itemid ~= ITEM_SET) then
				local itemSelected = false
				for j,v in pairs(INVENTORY_SELECTED_ITEMS) do
					if (v.inventid == inventoryItems[i].inventid) then
						itemSelected = true
						break
					end
				end
				local selectBox = UIElement:new({
					parent = invItemHolder,
					pos = { -40, invItemHolder.size.h / 2 - 15 },
					size = { 30, 30 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR
				})
				local selectIcon = UIElement:new({
					parent = selectBox,
					pos = { 0, 0 },
					size = { selectBox.size.w, selectBox.size.h },
					bgImage = "../textures/menu/general/buttons/checkmark.tga"
				})
				if (not itemSelected) then
					selectIcon:hide(true)
				end
				lShift = 50
	
				selectBox:addMouseHandlers(nil, function()
						for j,v in pairs(INVENTORY_SELECTED_ITEMS) do
							if (v.inventid == inventoryItems[i].inventid) then
								table.remove(INVENTORY_SELECTED_ITEMS, j)
								selectIcon:hide(true)
								if (#INVENTORY_SELECTED_ITEMS == 0) then
									Torishop:showInventoryItem(TB_ITEM_DETAILS)
								else
									Torishop:showSelectionControls()
								end
								return
							end
						end
						table.insert(INVENTORY_SELECTED_ITEMS, inventoryItems[i])
						Torishop:showSelectionControls()
						selectIcon:show(true)
					end)
			end
			
			local buttonWidth = 120 > (invItemHolder.size.w / 3 - 50) / 2 and (invItemHolder.size.w / 3 - 50) / 2 or 120
			if (inventoryItems[i].activateable and not inventoryItems[i].unpackable) then
				local activateButton = UIElement:new({
					parent = invItemHolder,
					pos = { -buttonWidth - lShift, 10 },
					size = { buttonWidth, invItemHolder.size.h - 20 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				})
				local activateText = UIElement:new({
					parent = activateButton,
					pos = { 10, 5 },
					size = { activateButton.size.w - 20, activateButton.size.h - 10 }
				})
				activateText:addAdaptedText(true, inventoryItems[i].active and TB_MENU_LOCALIZED.STOREITEMDEACTIVATE or TB_MENU_LOCALIZED.STOREITEMACTIVATE)
				activateButton:addMouseHandlers(nil, function()
						INVENTORY_UPDATE = true
						INVENTORY_MOUSE_POS = { x = posX, y = posY }
						show_dialog_box(inventoryItems[i].active and INVENTORY_DEACTIVATE or INVENTORY_ACTIVATE, inventoryItems[i].active and (TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE1 .. " " .. inventoryItems[i].name .. (TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 .. "?")) or (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE1 .. " " .. inventoryItems[i].name .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 .. "?")), inventoryItems[i].inventid)
					end, nil)
				lShift = lShift + buttonWidth + 10
			end
			
			--[[if (inventoryItems[i].uploadable) then
				local editButton = UIElement:new({
					parent = invItemHolder,
					pos = { -buttonWidth - lShift, 10 },
					size = { buttonWidth, invItemHolder.size.h - 20 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				})
				local editText = UIElement:new({
					parent = editButton,
					pos = { 10, 5 },
					size = { editButton.size.w - 20, editButton.size.h - 10 }
				})
				TBMenu:showTextWithImage(editText, TB_MENU_LOCALIZED.STOREITEMSEDIT, FONTS.MEDIUM, editText.size.h, "../textures/menu/general/buttons/external.tga")
				editButton:addMouseHandlers(nil, function()
						open_url("https://forum.toribash.com/tori_item.php?invid=" .. inventoryItems[i].inventid)
					end)
			end]]
		end
		
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
		
		Torishop:showInventoryItem(TB_ITEM_DETAILS or inventoryItems[invStartShift])

		--[[local lineItems = math.floor(inventoryPage.size.w / itemScale)
		local invRows = math.floor((inventoryPage.size.h - 20) / itemScale)
		local maxPages = math.ceil(#inventoryItems / invRows)

		local page = pageShift and TB_INVENTORY_PAGE[pageid] + pageShift or TB_INVENTORY_PAGE[pageid]
		page = page < 1 and maxPages or page
		TB_INVENTORY_PAGE[pageid] = page > maxPages and 1 or page

		local invStartShift = 1 + (TB_INVENTORY_PAGE[pageid] - 1) * lineItems * invRows
		local line = 1


		if (maxPages > 1) then
			local inventoryPrevPage = UIElement:new({
				parent = inventoryView,
				pos = { 10, (inventoryView.size.h - 32) / 2 },
				size = { 32, 64 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.3 },
				hoverColor = { 0, 0, 0, 0.5 },
				pressedColor = { 1, 0, 0, 0.2 },
				bgImage = "../textures/menu/general/buttons/arrowleft.tga"
			})
			inventoryPrevPage:addMouseHandlers(nil, function()
					Torishop:showInventoryPage(inventoryItems, -1, mode, title, pageid, itemScale, showBack)
				end)
			local inventoryNextPage = UIElement:new({
				parent = inventoryView,
				pos = { -42, (inventoryView.size.h - 32) / 2 },
				size = { 32, 64 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.3 },
				hoverColor = { 0, 0, 0, 0.5 },
				pressedColor = { 1, 0, 0, 0.2 },
				bgImage = "../textures/menu/general/buttons/arrowright.tga"
			})
			inventoryNextPage:addMouseHandlers(nil, function()
					Torishop:showInventoryPage(inventoryItems, 1, mode, title, pageid, itemScale, showBack)
				end)
		end

		local inventoryHolder = UIElement:new({
			parent = inventoryPage,
			pos = { (inventoryPage.size.w - itemScale * lineItems) / 2, 0 },
			size = { itemScale * lineItems, inventoryPage.size.h }
		})

		local inventoryPagination = UIElement:new({
			parent = inventoryHolder,
			pos = { 0, -20 },
			size = { inventoryHolder.size.w, 20 }
		})
		inventoryPagination:addCustomDisplay(true, function()
				inventoryPagination:uiText(TB_MENU_LOCALIZED.PAGINATIONPAGE .. " " .. TB_INVENTORY_PAGE[pageid] .. " " .. TB_MENU_LOCALIZED.PAGINATIONPAGEOF .. " " .. maxPages)
			end)

		if (#inventoryItemView.child == 0) then
			if (#INVENTORY_SELECTED_ITEMS == 0) then
				Torishop:showInventoryItem(TB_ITEM_DETAILS or inventoryItems[invStartShift])
			else
				Torishop:showSelectionControls()
			end
		end

		for i = invStartShift, #inventoryItems do
			if (line * itemScale > inventoryHolder.size.h) then
				break
			end
			local item = UIElement:new({
				parent = inventoryHolder,
				pos = { ((i - 1) % lineItems) * itemScale, (line - 1) * itemScale },
				size = { itemScale, itemScale },
				shapeType = ROUNDED,
				rounded = 10,
				interactive = true,
				bgColor = { 0, 0, 0, 0 },
				hoverColor = { 0, 0, 0, 0.4 },
				pressedColor = { 1, 1, 1, 0.3 }
			})
			local itemSelected = UIElement:new({
				parent = item,
				pos = { 5, 5 },
				size = { item.size.w - 10, item.size.h - 10 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				shapeType = item.shapeType,
				rounded = item.rounded
			})
			if (inventoryItems[i].inventid ~= TB_ITEM_DETAILS.inventid) then
				itemSelected:hide()
			end
			itemSelected:addCustomDisplay(false, function()
					if (inventoryItems[i].inventid ~= TB_ITEM_DETAILS.inventid) then
						itemSelected:hide()
					end
				end)
			item:addMouseHandlers(nil, function()
					Torishop:showInventoryItem(inventoryItems[i])
					itemSelected:show()
					item:reload()
				end)
			Torishop:showInventorySingleItemData(item, inventoryItems[i], itemScale)
			if (i % lineItems == 0) then
				line = line + 1
			end
		end]]
	end

	function Torishop:prepareInventory(viewElement, reload)
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 1
		viewElement:kill(true)
		
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar(Torishop:getNavigationButtons(), true)

		if (reload or not TB_INVENTORY_LOADED) then
			download_inventory()
			TB_INVENTORY_LOADED = true
		end
		TB_MENU_DOWNLOAD_INACTION = true
		local inventoryWait = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local bottomSmudge = TBMenu:addBottomBloodSmudge(inventoryWait, 1)
		TBMenu:displayLoadingMark(inventoryWait, TB_MENU_LOCALIZED.MESSAGEPLEASEWAIT)
		inventoryWait:addCustomDisplay(false, function()
				for i,v in pairs(get_downloads()) do
					if (v:match("data/script/torishop/invent.txt")) then
						return
					end
				end
				Torishop:showInventory(viewElement)
				check_steam_color(0)
			end)
	end

	function Torishop:showInventory(viewElement, mode, showSets)
		viewElement:kill(true)
		if (mode) then
			TB_ITEM_DETAILS = nil
		end
		local mode = mode and mode or TB_INVENTORY_MODE
		TB_INVENTORY_MODE = mode
		local playerInventory = Torishop:getInventory(mode)
		
		SHOW_EMPTY_SETS = showSets and showSets or SHOW_EMPTY_SETS
		if (SHOW_EMPTY_SETS == 0) then
			for i = #playerInventory, 1, -1 do
				if (playerInventory[i].itemid == ITEM_SET and #playerInventory[i].contents == 0) then
					table.remove(playerInventory, i)
				end
			end
		end
		
		inventoryView = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.7 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		inventoryItemView = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w * 0.7 + 5, 0 },
			size = { viewElement.size.w * 0.3 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Torishop:showInventoryPage(playerInventory, nil, mode, nil, "page" .. mode)
	end

	function Torishop:showTcPurchase(tcPurchaseView)
		local tcData = Torishop:getTcSales()
		for i,v in pairs(tcData) do
			local tcEntry = UIElement:new({
				parent = tcPurchaseView,
				pos = { 0, (i - 1) * tcPurchaseView.size.h / #tcData },
				size = { tcPurchaseView.size.w, tcPurchaseView.size.h / #tcData },
				interactive = true,
				bgColor = { 0, 0, 0, 0 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.1 },
				hoverSound = 31
			})
			tcEntry:addMouseHandlers(nil, function()
					if (TB_MENU_PLAYER_INFO.username == '') then
						TBMenu:showLoginError(tcPurchaseView.parent, TB_MENU_LOCALIZED.STOREPURCHASETORICREDITS)
						return
					end
					UIElement:runCmd("steam purchase " .. v.itemid)
					local waitNotification = UIElement:new({
						parent = tbMenuMain,
						pos = { WIN_W / 2 - 200, WIN_H / 2 - 50 },
						size = { 400, 100 },
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR
					})
					local pressTime = os.time()
					waitNotification:addCustomDisplay(false, function()
							local waitStr = TB_MENU_LOCALIZED.STORESTEAMPURCHASELOADING .. string.rep(".", (os.time() - pressTime) % 3)
							if (os.time() - pressTime >= 30) then
								waitStr = TB_MENU_LOCALIZED.STORESTEAMPURCHASEERROR
							elseif (os.time() - pressTime >= 35) then
								waitNotification:kill()
							end
							waitNotification:uiText(waitStr)
						end)
					add_hook("console", "tbMenuConsoleIgnore", function(s,i)
							if (s:match("Transaction initiated")) then
								waitNotification:kill()
								return 1
							end
						end)
				end, nil)
			local iconScale = tcEntry.size.h - 20 < 128 and tcEntry.size.h - 20 or 128
			local tcIcon = UIElement:new({
				parent = tcEntry,
				pos = { tcEntry.size.w / 20, (tcEntry.size.h - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = "../textures/store/toricredit.tga"
			})
			local itemDetails = UIElement:new({
				parent = tcEntry,
				pos = { tcIcon.shift.x * 2 + tcIcon.size.w, 0 },
				size = { tcEntry.size.w - (tcIcon.shift.x * 3 + tcIcon.size.w), tcEntry.size.h }
			})
			local itemName = UIElement:new({
				parent = itemDetails,
				pos = { 0, itemDetails.size.h * 0.1 },
				size = { itemDetails.size.w, itemDetails.size.h * 0.5 }
			})
			local itemNameSize = 1
			while (not itemName:uiText(v.name, nil, nil, FONTS.BIG, LEFT, itemNameSize, nil, nil, nil, nil, nil, true)) do
				itemNameSize = itemNameSize - 0.05
			end
			itemName:addCustomDisplay(true, function()
					itemName:uiText(v.name, nil, nil, FONTS.BIG, LEFTBOT, itemNameSize, nil, 1)
				end)

			local itemPrice = UIElement:new({
				parent = itemDetails,
				pos = { 0, itemDetails.size.h * 0.6 },
				size = { itemDetails.size.w, itemDetails.size.h * 0.4 }
			})
			local itemPriceSize = 1
			while (not itemPrice:uiText("$" .. v.price, nil, nil, FONTS.MEDIUM, LEFT, itemPriceSize, nil, nil, nil, nil, nil, true)) do
				itemPriceSize = itemPriceSize - 0.05
			end
			itemPrice:addCustomDisplay(true, function()
					itemPrice:uiText("$" .. v.price, nil, nil, FONTS.MEDIUM, LEFT, itemPriceSize, nil, 0.6)
				end)
		end
	end
	
	function Torishop:showSeasonPassAprilFools()
		TB_MENU_IGNORE_REWARDS = 1
		local overlay = TBMenu:spawnWindowOverlay()
		overlay:addMouseHandlers(nil, function()
				overlay:kill()
				TB_MENU_IGNORE_REWARDS = 0
			end)
		local seasonPassBG = UIElement:new({
			parent = overlay,
			pos = { 100, 150 },
			size = { overlay.size.w - 200, overlay.size.h - 300 },
			bgColor = { 0.847, 0.89, 0.941, 1 },
			shapeType = ROUNDED,
			rounded = 5,
			interactive = true
		})
		local backButton = UIElement:new({
			parent = seasonPassBG,
			pos = { -150, 0 },
			size = { 140, 40 },
			interactive = true,
			bgColor = UICOLORBLACK,
			hoverColor = { 0.431, 0.6, 0.78, 1 },
			pressedColor = { 0.373, 0.557, 0.749, 1 }
		})
		backButton:addCustomDisplay(true, function()
				backButton:uiText(TB_MENU_LOCALIZED.NAVBUTTONBACK, nil, nil, nil, RIGHTMID, nil, nil, nil, backButton:getButtonColor())
			end)
		backButton:addMouseHandlers(nil, function()
				overlay:kill()
				TB_MENU_IGNORE_REWARDS = 0
			end)
		function doShow()
			local seasonPassHolder = UIElement:new({
				parent = seasonPassBG,
				pos = { 10, 25 },
				size = { seasonPassBG.size.w * 0.6, seasonPassBG.size.h - 50 }
			})
			local passImageSize = 1024 > seasonPassHolder.size.w and seasonPassHolder.size.w or 1024
			local seasonPassImage = UIElement:new({
				parent = seasonPassHolder,
				pos = { 0, 0 },
				size = { seasonPassHolder.size.w, seasonPassHolder.size.w / 2 },
				bgImage = "../textures/menu/promo/seasonpasssmall.tga"
			})
			
			local seasonPassInfoHolder = UIElement:new({
				parent = seasonPassHolder,
				pos = { 10, -180 },
				size = { seasonPassHolder.size.w - 20, 110 },
				bgColor = { 0.58, 0.706, 0.835, 0.8 },
				shapeType = ROUNDED,
				rounded = 5
			})
			local seasonPassInfo = UIElement:new({
				parent = seasonPassInfoHolder,
				pos = { 10, 5 },
				size = { seasonPassInfoHolder.size.w - 20, seasonPassInfoHolder.size.h - 10 },
				uiColor = UICOLORBLACK
			})
			seasonPassInfo:addAdaptedText(nil, "Toribash Season Pass 2020 is a special collectible card that upgrades your Toribash account by giving you exclusive access to:\n- ^62NO ^07unique or otherwise unavailable items\n- ^62ZERO ^07Season Pass levels to unlock\n- ^62ALL THE ITEMS ^07that you already own", nil, nil, 4, LEFTMID)
			
			local item = Torishop:getItemInfo(3304)
			local cardPurchaseButtonTC = UIElement:new({
				parent = seasonPassHolder,
				pos = { seasonPassHolder.size.w / 5, -60},
				size = { seasonPassHolder.size.w / 5 * 3, 60 },
				shapeType = ROUNDED,
				rounded = 10,
				hoverColor = { 0.792, 0.851, 0.918, 1 },
				pressedColor = { 0.373, 0.557, 0.749, 1 },
				innerShadow = { 0, 5 },
				shadowColor = { 0.431, 0.6, 0.78, 1 },
				interactive = true,
				bgColor = { 0.58, 0.706, 0.835, 1 },
				uiColor = { 0, 0, 0, 1 }
			})
			if (TB_MENU_PLAYER_INFO.data.tc < item.now_tc_price) then
				cardPurchaseButtonTC:deactivate()
				cardPurchaseButtonTC.uiColor = { 0.4, 0.4, 0.4, 1 }
			end
			cardPurchaseButtonTC:addAdaptedText(false, "Get Season Pass for " .. PlayerInfo:currencyFormat(item.now_tc_price) .. " TC", nil, -2)
			cardPurchaseButtonTC:addMouseHandlers(nil, function()
				TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. PlayerInfo:currencyFormat(item.now_tc_price) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. "?\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 .. " " .. PlayerInfo:currencyFormat(TB_MENU_PLAYER_INFO.data.tc - item.now_tc_price) .. " TC " .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT2, function()
						Torishop:buyItem(item, MODE_TC)
					end)
			end)
			
			local plusSign = UIElement:new({
				parent = seasonPassBG,
				pos = { seasonPassHolder.size.w + seasonPassHolder.shift.x, 25 },
				size = { 20, seasonPassBG.size.h / 3 * 2 },
				uiColor = UICOLORBLACK
			})
			plusSign:addAdaptedText(nil, "+", nil, nil, FONTS.BIG)
			
			local lootBox = Torishop:getItemInfo(3303)
			local lootBoxHolder = UIElement:new({
				parent = seasonPassBG,
				pos = { seasonPassHolder.size.w + seasonPassHolder.shift.x + 20, 25 },
				size = { seasonPassBG.size.w - seasonPassHolder.size.w - seasonPassHolder.shift.x * 2 - 20, seasonPassBG.size.h - 50 },
				uiColor = UICOLORBLACK
			})
			local lootboxIconSize = 256 > lootBoxHolder.size.w - 100 and lootBoxHolder.size.w - 100 or 256
			lootboxIconSize = lootboxIconSize > lootBoxHolder.size.h / 2 and lootBoxHolder.size.h / 2 or lootboxIconSize
			local lootBoxName = UIElement:new({
				parent = lootBoxHolder,
				pos = { 20, 10 },
				size = { lootBoxHolder.size.w - 40, 35 }
			})
			lootBoxName:addAdaptedText(nil, lootBox.itemname, nil, nil, FONTS.BIG, nil, nil, nil, 0.2)
			local lootBoxIcon = UIElement:new({
				parent = lootBoxHolder,
				pos = { (lootBoxHolder.size.w - lootboxIconSize) / 2, 50 },
				size = { lootboxIconSize, lootboxIconSize },
				bgImage = "../textures/store/items/3303_big.tga"
			})
			local lootBoxInfoHolder = UIElement:new({
				parent = lootBoxHolder,
				pos = { 10, -160 },
				size = { lootBoxHolder.size.w - 20, 90 },
				bgColor = { 0.58, 0.706, 0.835, 0.8 },
				shapeType = ROUNDED,
				rounded = 5
			})
			local lootBoxInfo = UIElement:new({
				parent = lootBoxInfoHolder,
				pos = { 10, 5 },
				size = { lootBoxInfoHolder.size.w - 20, lootBoxInfoHolder.size.h - 10 }
			})
			lootBoxInfo:addAdaptedText(nil, lootBox.itemname .. " is an item that utilizes surprise mechanics: by purchasing it you will receive one random color item - including no-qi Void and Demon!", nil, nil, 4)
			
			local lootboxPurchaseButtonTC = UIElement:new({
				parent = lootBoxHolder,
				pos = { 10, -60},
				size = { lootBoxHolder.size.w / 2 - 10, 60 },
				shapeType = ROUNDED,
				rounded = 10,
				hoverColor = { 0.792, 0.851, 0.918, 1 },
				pressedColor = { 0.373, 0.557, 0.749, 1 },
				innerShadow = { 0, 5 },
				shadowColor = { 0.431, 0.6, 0.78, 1 },
				interactive = true,
				bgColor = { 0.58, 0.706, 0.835, 1 },
				uiColor = { 0, 0, 0, 1 }
			})
			if (TB_MENU_PLAYER_INFO.data.tc < lootBox.now_tc_price) then
				lootboxPurchaseButtonTC:deactivate()
				lootboxPurchaseButtonTC.uiColor = { 0.4, 0.4, 0.4, 1 }
			end
			lootboxPurchaseButtonTC:addAdaptedText(false, "Buy for " .. PlayerInfo:currencyFormat(lootBox.now_tc_price) .. " TC", nil, -2)
			lootboxPurchaseButtonTC:addMouseHandlers(nil, function()
				TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. lootBox.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. PlayerInfo:currencyFormat(lootBox.now_tc_price) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. "?\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 .. " " .. PlayerInfo:currencyFormat(TB_MENU_PLAYER_INFO.data.tc - lootBox.now_tc_price) .. " TC " .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT2, function()
						buy_tc(lootBox.itemid .. ":" .. lootBox.now_tc_price)
						Torishop:showPostPurchaseScreen(lootBox, nil, true)
					end)
			end)
			
			local lootboxPurchaseButtonST = UIElement:new({
				parent = lootBoxHolder,
				pos = { lootBoxHolder.size.w / 2 + 10, -60 },
				size = { lootBoxHolder.size.w / 2 - 10, 60 },
				shapeType = ROUNDED,
				rounded = 10,
				hoverColor = { 0.792, 0.851, 0.918, 1 },
				pressedColor = { 0.373, 0.557, 0.749, 1 },
				innerShadow = { 0, 5 },
				shadowColor = { 0.431, 0.6, 0.78, 1 },
				interactive = true,
				bgColor = { 0.58, 0.706, 0.835, 1 },
				uiColor = { 0, 0, 0, 1 }
			})
			if (TB_MENU_PLAYER_INFO.data.st < lootBox.now_usd_price) then
				lootboxPurchaseButtonST:deactivate()
				lootboxPurchaseButtonST.uiColor = { 0.4, 0.4, 0.4, 1 }
			end
			lootboxPurchaseButtonST:addAdaptedText(false, "Buy for " .. lootBox.now_usd_price .. " ST", nil, -2)
			lootboxPurchaseButtonST:addMouseHandlers(nil, function()
				TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. lootBox.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. PlayerInfo:currencyFormat(lootBox.now_usd_price) .. " " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS .. "?\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 .. " " .. PlayerInfo:currencyFormat(TB_MENU_PLAYER_INFO.data.st - lootBox.now_usd_price) .. " ST " .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT2, function()
						buy_st(lootBox.itemid .. ":" .. lootBox.now_usd_price)
						Torishop:showPostPurchaseScreen(lootBox, nil, true)
					end)
			end)
		end
		if (not TB_STORE_DATA.ready) then
			local waiterText = UIElement:new({
				parent = seasonPassBG,
				pos = { 100, 50 },
				size = { seasonPassBG.size.w - 200, seasonPassBG.size.h - 100 },
				uiColor = UICOLORBLACK
			})
			waiterText:addAdaptedText(true, "Loading store data, please wait...")
			local waiter = UIElement:new({
				parent = waiterText,
				pos = { 0, 0 },
				size = { 0, 0 }
			})
			waiter:addCustomDisplay(true, function()
					if (TB_STORE_DATA.ready) then
						waiterText:kill()
						doShow()
					end
				end)
		else
			doShow()
		end
	end
	
	function Torishop:showCollectorsCards(id)
		if (id == 1) then
			Torishop:showCollectorsCardsWC20()
		end
	end

	function Torishop:showCollectorsCardsWC20()
		TB_MENU_IGNORE_REWARDS = 1
		local overlay = TBMenu:spawnWindowOverlay()
		overlay:addMouseHandlers(nil, function()
				overlay:kill()
				TB_MENU_IGNORE_REWARDS = 0
			end)
		local cardsData = {
			{ player = "Velo", itemid = 3388 },
			{ player = "Chax", itemid = 3391 },
			{ player = "heat", itemid = 3386 },
			{ player = "Fire", itemid = 3387 },
			{ player = "watermagic", itemid = 3389 },
			{ player = "melrose", itemid = 3390 },
		--	{ player = "Cicada3301", itemid = 3290 },
		--	{ player = "Wounder", itemid = 3283 },
		}
		local selectedPlayer = math.random(1, #cardsData)

		local cardsOverlay = UIElement:new({
			parent = overlay,
			pos = { 100, 100 },
			size = { overlay.size.w - 200, overlay.size.h - 200 },
			bgColor = { 0.392, 0.211, 0.17, 1 },
			interactive = true
		})
		local scale = cardsOverlay.size.h * 2 < cardsOverlay.size.w and cardsOverlay.size.h or cardsOverlay.size.w / 2
		local cardsBackgroundImage = UIElement:new({
			parent = cardsOverlay,
			pos = { cardsOverlay.size.w / 2 - scale, (cardsOverlay.size.h - scale) / 2 },
			size = { scale * 2, scale },
			bgImage = "../textures/menu/promo/worlds2020/splash.tga"
		})
		local cardsBackgroundAnimation = UIElement:new({
			parent = cardsOverlay,
			pos = { 0, 0 },
			size = { cardsOverlay.size.w, cardsOverlay.size.h }
		})
		local circles = {}
		local spawnCircle = function()
			local gb = math.random(200, 750) / 1000
			local circle = {
				color = { gb, 0, gb * math.random(30, 45) / 100, math.random(60, 100) / 100},
				size = math.random(30, 90) / 10,
				x = math.random(15, cardsOverlay.size.w - 15),
			 	y = math.random(15, cardsOverlay.size.h - 15),
				speed = math.random(50, 100) / 100,
				shift = math.random(10, 40) / 100
			}
			table.insert(circles, circle)
		end
		while (#circles < 100) do
			spawnCircle()
		end
		cardsBackgroundAnimation:addCustomDisplay(true, function()
				while (#circles < 100) do
					spawnCircle()
				end
				for i = #circles, 1, -1 do
					local circleTrans = circles[i].x > circles[i].y and circles[i].y or circles[i].x
					set_color(circles[i].color[1], circles[i].color[2], circles[i].color[3], (circleTrans - 6) / cardsOverlay.size.h * 2)
					draw_disk(cardsOverlay.pos.x + circles[i].x + circles[i].size / 2, cardsOverlay.pos.y + circles[i].y + circles[i].size / 2, 0, circles[i].size, 500, 1, 0, 360, 0)
					circles[i].y = circles[i].y - 1 * circles[i].speed
					circles[i].x = circles[i].x - circles[i].shift * circles[i].speed
					if (circles[i].y < 15 or circles[i].x < 15) then
						table.remove(circles, i)
					end
				end
			end)

		local backButton = UIElement:new({
			parent = cardsOverlay,
			pos = { -150, 0 },
			size = { 140, 40 },
			interactive = true,
			bgColor = UICOLORWHITE,
			hoverColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		backButton:addCustomDisplay(true, function()
				backButton:uiText(TB_MENU_LOCALIZED.NAVBUTTONBACK, nil, nil, nil, RIGHTMID, nil, nil, nil, backButton:getButtonColor())
			end)
		backButton:addMouseHandlers(nil, function()
				overlay:kill()
				TB_MENU_IGNORE_REWARDS = 0
			end)

		local cardsInfoHolder = UIElement:new({
			parent = cardsOverlay,
			pos = { 0, 0 },
			size = { cardsOverlay.size.w, cardsOverlay.size.h }
		})
		Torishop:showCollectorsCardSingle(cardsInfoHolder, cardsData, selectedPlayer)
	end

	function Torishop:showCollectorsCardSingle(cardsOverlay, cardsData, selectedPlayer)
		cardsOverlay:kill(true)
		local cardScale = cardsOverlay.size.h > 532 and 512 or cardsOverlay.size.h - 20
		cardScale = cardScale * 0.8 > cardsOverlay.size.w / 3 and cardsOverlay.size.w / 2.5 or cardScale
		
		local cardImage = UIElement:new({
			parent = cardsOverlay,
			pos = { cardsOverlay.size.w / 3.5 - cardScale / 3, (cardsOverlay.size.h - cardScale) / 2 },
			size = { cardScale, cardScale },
			bgImage = "../textures/menu/promo/worlds2020/" .. cardsData[selectedPlayer].player:lower() .. ".tga"
		})
		local cardInfoHolder = UIElement:new({
			parent = cardsOverlay,
			pos = { cardImage.pos.x + cardImage.size.w * 0.55, cardsOverlay.size.h / 10 },
			size = { cardScale, cardsOverlay.size.h * 0.8 },
			bgColor = { 0.298, 0, 0.075, 0.75 },
			shapeType = ROUNDED,
			rounded = 10
		})
		local cardsDisclaimer = UIElement:new({
			parent = cardInfoHolder,
			pos = { 10, 0 },
			size = { cardInfoHolder.size.w - 20, cardInfoHolder.size.h / 4 },
			uiShadowColor = { 0.298, 0, 0.075, 1 },
			--uiShadowColor = UICOLORWHITE
		})
		cardsDisclaimer:addAdaptedText(true, "World Championship 2020\nCollectors Card", nil, nil, FONTS.BIG, nil, 0.825, nil, 0.25, 1.5)

		local cardName = UIElement:new({
			parent = cardInfoHolder,
			pos = { 10, cardInfoHolder.size.h / 4 },
			size = { cardInfoHolder.size.w - 20, cardInfoHolder.size.h / 4 }
		})
		cardName:addAdaptedText(true, cardsData[selectedPlayer].player, nil, nil, FONTS.BIG)

		local cardInfo = UIElement:new({
			parent = cardInfoHolder,
			pos = { 0, cardInfoHolder.size.h / 2 },
			size = { cardInfoHolder.size.w, cardInfoHolder.size.h / 4 },
			--[[shapeType = ROUNDED,
			rounded = 5,
			bgColor = { 0.118, 0.016, 0.043, 0.7 }]]
		})
		local cardInfoText = UIElement:new({
			parent = cardInfo,
			pos = { 10, 5 },
			size = { cardInfo.size.w - 20, cardInfo.size.h - 10 }
		})
		cardInfoText:addAdaptedText(true, "Purchase this card now and win prize Toricredits if " .. cardsData[selectedPlayer].player .. " wins Toribash World Championship 2020 and becomes the best player of the year!", nil, nil, 4, nil, 0.85)
		
		local item = Torishop:getItemInfo(cardsData[selectedPlayer].itemid)
		local cardPurchaseButtonTC = UIElement:new({
			parent = cardInfoHolder,
			pos = { 20, cardInfoHolder.size.h * 3 / 4 + cardInfoHolder.size.h / 16 },
			size = { cardInfoHolder.size.w / 2 - 30, cardInfoHolder.size.h / 4 - cardInfoHolder.size.h / 8 },
			shapeType = ROUNDED,
			rounded = 10,
			hoverColor = { 0.471, 0, 0.118, 1 },
			pressedColor = { 0.204, 0, 0.112, 1 },
			inactiveColor = { 0.024, 0, 0.075, 1 },
			innerShadow = { 0, 5 },
			shadowColor = { 0.118, 0, 0.059, 1 },
			interactive = true,
			bgColor = { 0.298, 0, 0.075, 1 }
		})
		if (TB_MENU_PLAYER_INFO.data.tc < item.now_tc_price) then
			cardPurchaseButtonTC:deactivate()
		end
		cardPurchaseButtonTC:addAdaptedText(false, "Buy for " .. item.now_tc_price / 1000 .. "K TC", nil, -2)
		cardPurchaseButtonTC:addMouseHandlers(nil, function()
			TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. PlayerInfo:currencyFormat(item.now_tc_price) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. "?\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 .. " " .. PlayerInfo:currencyFormat(TB_MENU_PLAYER_INFO.data.tc - item.now_tc_price) .. " TC " .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT2, function()
					Torishop:buyItem(item, MODE_TC)
				end)
		end)
		
		local cardPurchaseButtonST = UIElement:new({
			parent = cardInfoHolder,
			pos = { cardPurchaseButtonTC.size.w + cardPurchaseButtonTC.shift.x + 20, cardInfoHolder.size.h * 3 / 4 + cardInfoHolder.size.h / 16 },
			size = { cardInfoHolder.size.w / 2 - 30, cardInfoHolder.size.h / 4 - cardInfoHolder.size.h / 8 },
			shapeType = ROUNDED,
			rounded = 10,
			hoverColor = { 0.471, 0, 0.118, 1 },
			pressedColor = { 0.204, 0, 0.112, 1 },
			inactiveColor = { 0.024, 0, 0.075, 1 },
			innerShadow = { 0, 5 },
			shadowColor = { 0.118, 0, 0.059, 1 },
			interactive = true,
			bgColor = { 0.298, 0, 0.075, 1 }
		})
		if (TB_MENU_PLAYER_INFO.data.st < item.now_usd_price) then
			cardPurchaseButtonST:deactivate()
		end
		cardPurchaseButtonST:addAdaptedText(false, "Buy for " .. item.now_usd_price .. " ST", nil, -2)
		cardPurchaseButtonST:addMouseHandlers(nil, function()
			TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. PlayerInfo:currencyFormat(item.now_usd_price) .. " " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS .. "?\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 .. " " .. PlayerInfo:currencyFormat(TB_MENU_PLAYER_INFO.data.st - item.now_usd_price) .. " ST " .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT2, function()
					Torishop:buyItem(item, MODE_ST)
				end)
		end)

		local prevCardButton = UIElement:new({
			parent = cardsOverlay,
			pos = { 5, cardsOverlay.size.h / 2 - 25 },
			size = { 50, 50 },
			shapeType = ROUNDED,
			rounded = 25,
			interactive = true,
			bgColor = { 0.471, 0, 0.118, 0.4 },
			hoverColor = { 0.471, 0, 0.118, 1 },
			pressedColor = { 0.204, 0, 0.112, 1 }
		})
		local prevCardIcon = UIElement:new({
			parent = prevCardButton,
			pos = { 12.5, 0 },
			size = { 25, 50 },
			bgImage = "../textures/menu/general/buttons/arrowleft.tga"
		})
		prevCardButton:addMouseHandlers(nil, function()
				local selectedPlayer = selectedPlayer - 1 < 1 and #cardsData or selectedPlayer - 1
				Torishop:showCollectorsCardSingle(cardsOverlay, cardsData, selectedPlayer)
			end)
		local nextCardButton = UIElement:new({
			parent = cardsOverlay,
			pos = { -65, cardsOverlay.size.h / 2 - 25 },
			size = { 50, 50 },
			shapeType = ROUNDED,
			rounded = 25,
			interactive = true,
			bgColor = { 0.471, 0, 0.118, 0.4 },
			hoverColor = { 0.471, 0, 0.118, 1 },
			pressedColor = { 0.204, 0, 0.112, 1 }
		})
		local nextCardIcon = UIElement:new({
			parent = nextCardButton,
			pos = { 12.5, 0 },
			size = { 25, 50 },
			bgImage = "../textures/menu/general/buttons/arrowright.tga"
		})
		nextCardButton:addMouseHandlers(nil, function()
				local selectedPlayer = selectedPlayer + 1 > #cardsData and 1 or selectedPlayer + 1
				Torishop:showCollectorsCardSingle(cardsOverlay, cardsData, selectedPlayer)
			end)
	end
	
	function Torishop:showStoreAdvancedItemPreview(viewElement, item, noReload, updateOverride, updatedFunc, level)
		local viewport = UIElement:new({
			parent = viewElement,
			pos = { (viewElement.size.w - viewElement.size.h) / 2, 0 },
			size = { viewElement.size.h, viewElement.size.h },
			viewport = true
		})
		local background = UIElement:new({
			parent = viewElement,
			pos = { math.ceil(viewport.shift.x), 1 },
			size = { viewport.size.w - 1, viewElement.size.h - 2 },
			bgColor = UICOLORWHITE,
			bgImage = "../textures/store/presets/previewbgshade.tga"
		})
		local viewport3D = UIElement3D:new({
			globalid = TB_MENU_MAIN_GLOBALID,
			shapeType = VIEWPORT,
			parent = viewport,
			pos = { 0, 0, 0 },
			size = { 0, 0, 0 },
			rot = { 0, 0, 0 },
			viewport = true
		})
		table.insert(viewport.child, viewport3D)
		local previewMain = UIElement3D:new({
			parent = viewport3D,
			shapeType = CUBE,
			pos = { 0, 0, 10 },
			size = { 0, 0, 0 },
			viewport = true
		})
		previewMain:addCustomDisplay(true, function()
				if (viewElement.hoverState ~= BTN_DN) then
					previewMain:rotate(0, 0, 0.2)
				end
			end)
		viewElement:addMouseHandlers(function()
				viewElement.pressedPos.x = MOUSE_X
			end, nil, function()
				if (viewElement.hoverState == BTN_DN) then
					if (MOUSE_X > viewElement.pressedPos.x) then
						previewMain:rotate(0, 0, -15)
					elseif (MOUSE_X < viewElement.pressedPos.x) then
						previewMain:rotate(0, 0, 15)
					end
					viewElement.pressedPos.x = MOUSE_X
				end
			end)
		local previewHolder = UIElement3D:new({
			parent = previewMain,
			shapeType = CUBE,
			pos = { 0, 0, 0 },
			size = { 1, 1, 1 },
			viewport = true
		})
		previewHolder:addCustomDisplay(true, function() end)
		local scaleMultiplier = 2 --get_option("shaders") + 1
		local trans = get_option("shaders") == 1 and 1 or 0.99
		local heightMod = 0
		local iconScale = viewElement.size.w > viewElement.size.h and viewElement.size.h or viewElement.size.w
		iconScale = iconScale > 64 and 64 or iconScale
		if (item.catid == 2) then
			-- Relax Items
			local color = get_color_info(item.colorid)
			local fcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force)
			local force = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUSTOMOBJ,
				objModel = "../models/store/presets/force",
				pos = { 0, 0, 0 },
				size = { 1 * scaleMultiplier, 1 * scaleMultiplier, 1 * scaleMultiplier },
				rot = { 10, 90, 40 },
				bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
				viewport = true
			})
			local relax = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0, 0, 0 },
				size = { 0.8, 0.8, 0.8 },
				rot = { 0, 0, 0 },
				bgColor = { color.r, color.g, color.b, 1 },
				viewport = true
			})
			return true
		elseif (item.catid == 22) then
			-- Force Items
			local color = get_color_info(item.colorid)
			local rcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.relax)
			local force = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUSTOMOBJ,
				objModel = "../models/store/presets/force",
				pos = { 0, 0, 0 },
				size = { 1 * scaleMultiplier, 1 * scaleMultiplier, 1 * scaleMultiplier },
				rot = { 10, 90, 40 },
				bgColor = { color.r, color.g, color.b, 1 },
				viewport = true
			})
			local relax = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0, 0, 0 },
				size = { 0.8, 0.8, 0.8 },
				rot = { 0, 0, 0 },
				bgColor = { rcolor.r, rcolor.g, rcolor.b, 1 },
				viewport = true
			})
			return true
		elseif (item.catid == 1) then
			-- Blood Items
			local color = get_color_info(item.colorid)
			local blood1 = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUSTOMOBJ,
				objModel = "../models/store/presets/blood",
				pos = { 0, 0, -0.3 },
				size = { 0.8 * scaleMultiplier, 0.8 * scaleMultiplier, 0.8 * scaleMultiplier },
				rot = { -90, 0, 80 },
				bgColor = { color.r, color.g, color.b, 1 },
				viewport = true
			})
			return true
		elseif (item.catid == 20 or item.catid == 21) then
			-- Gradient Items
			local color = get_color_info(item.colorid)
			local pcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.pgrad)
			local scolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.sgrad)
			local fcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force)
			local primaryGrad = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				bgImage = "../textures/store/presets/prgrad.tga",
				pos = { 0, 0.2, 0 },
				size = { 2, 0.65, 0.65 },
				rot = { 90, 0, 0 },
				bgColor = item.catid == 20 and { color.r, color.g, color.b, trans } or { pcolor.r, pcolor.g, pcolor.b, trans },
				viewport = true
			})
			local handPrGrad = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				bgImage = "../textures/store/presets/prgrad.tga",
				pos = { 0.2, -1.53, 0 },
				size = { 1.2, 1.2, 1.2 },
				rot = { 90, 0, 0 },
				bgColor = item.catid == 20 and { color.r, color.g, color.b, trans } or { pcolor.r, pcolor.g, pcolor.b, trans },
				viewport = true
			})
			local secondaryGrad = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				bgImage = "../textures/store/presets/secgrad.tga",
				pos = { 0, 0.2, 0 },
				size = { 2, 0.65, 0.65 },
				rot = { 90, 0, 0 },
				bgColor = item.catid == 21 and { color.r, color.g, color.b, trans } or { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
			local handSecGrad = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				bgImage = "../textures/store/presets/secgrad.tga",
				pos = { 0.2, -1.53, 0 },
				size = { 1.2, 1.2, 1.2 },
				rot = { 90, 0, 0 },
				bgColor = item.catid == 21 and { color.r, color.g, color.b, trans } or { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
			local joint1 = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0, 1.2, 0 },
				size = { 0.6, 0.6, 0.6 },
				bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
				viewport = true
			})
			local joint2 = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0, -0.8, 0 },
				size = { 0.5, 0.5, 0.5 },
				bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
				viewport = true
			})
			previewHolder:moveTo(0, 0, -0.3)
			previewMain:rotate(40, 90, 110)
			return true
		elseif (item.catid == 11) then
			-- Ghost Colors
			local color = get_color_info(item.colorid)
			local pcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.pgrad)
			local scolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.sgrad)
			local fcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force)
			
			local cubesec = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0, 0 },
				size = { 1, 1, 1 },
				bgImage = "../textures/store/presets/secgrad.tga",
				rot = { 0, 90, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
			local cubepr = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0, 0 },
				size = { 1, 1, 1 },
				bgImage = "../textures/store/presets/prgrad.tga",
				rot = { 0, 90, 0 },
				bgColor = { pcolor.r, pcolor.g, pcolor.b, trans },
				viewport = true
			})
			local ghost = UIElement3D:new({
				parent = cubepr,
				shapeType = CUBE,
				pos = { 0, 0, 0 },
				size = { cubepr.size.x, cubepr.size.y, cubepr.size.z },
				bgColor = { color.r, color.g, color.b, 0.6 },
				viewport = true
			})
			ghost:addCustomDisplay(nil, function()
					if (ghost.bgColor[4] <= 0) then
						ghost:moveTo(-ghost.shift.x, -ghost.shift.y, 0)
						ghost:rotate(-ghost.rotXYZ.x - 30)
						ghost.bgColor[4] = 0.6
						return
					end
					ghost:moveTo(0.01, -0.005, 0)
					ghost:rotate(0.4)
					ghost.bgColor[4] = ghost.bgColor[4] - 0.01
				end)
			previewMain:rotate(-30, 0, 0)
			return true
		elseif (item.catid == 12) then
			-- DQ colors
			local color = get_color_info(item.colorid)
			local fcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force)
			local head = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { -0.3, 0, 0 },
				size = { 0.8, 0.8, 0.8 },
				rot = { 170, 20, -190 },
				bgImage = TB_MENU_PLAYER_INFO.items.textures.head.equipped and "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/head.tga" or "../../custom/tori/head.tga",
				viewport = true
			})
			local neck = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { -0.6, 0.3, 0.6 },
				size = { 0.4, 0.4, 0.4 },
				bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
				viewport = true
			})
			local dq = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUSTOMOBJ,
				objModel = "../models/store/presets/dq",
				size = { 7, 7, 7 },
				pos = { -0.3, 0, -0.8 },
				rot = { 0, 0, 0 },
				bgColor = { color.r, color.g, color.b, 1 },
				viewport = true
			})
			return true
		elseif (item.catid == 5) then
			-- Torso Items
			local color = get_color_info(item.colorid)
			local pcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.pgrad)
			local scolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.sgrad)
			local fcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force)
			local chest = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0, 0, -0.4 },
				size = { 0.7, 0.7, 0.7 },
				rot = { 0, 0, 0 },
				bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
				viewport = true
			})
			local lumbar = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0, 0.2, -1.2 },
				size = { 0.7, 0.7, 0.7 },
				rot = { 0, 0, 0 },
				bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
				viewport = true
			})
			local rpecs = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0.55, -0.15, 0.4 },
				size = { 0.7, 0.7, 0.7 },
				rot = { 0, 0, 0 },
				bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
				viewport = true
			})
			local lpecs = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { -0.55, -0.15, 0.4 },
				size = { 0.7, 0.7, 0.7 },
				rot = { 0, 0, 0 },
				bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
				viewport = true
			})
			local torsoneck = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0, 0.8 },
				size = { 0.7, 0.4, 0.6 },
				rot = { 0, 0, 0 },
				bgColor = { color.r, color.g, color.b, 1 },
				viewport = true
			})
			local torsorpec = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { -1, 0, 0.35 },
				size = { 1, 0.7, 0.95 },
				rot = { 0, 0, 0 },
				bgColor = { color.r, color.g, color.b, 1 },
				viewport = true
			})
			local torsolpec = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 1, 0, 0.35 },
				size = { 1, 0.7, 0.95 },
				rot = { 0, 0, 0 },
				bgColor = { color.r, color.g, color.b, 1 },
				viewport = true
			})
			local torsochest = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0.05, -0.6 },
				size = { 2.2, 0.7, 1 },
				rot = { 0, 0, 0 },
				bgColor = { color.r, color.g, color.b, 1 },
				viewport = true
			})
			local torsostomachp = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				bgImage = "../textures/store/presets/prgrad.tga",
				pos = { 0, 0.2, -1.6 },
				size = { 0.7, 1.1, 1.4 },
				rot = { 90, 90, 0 },
				bgColor = { pcolor.r, pcolor.g, pcolor.b, trans },
				viewport = true
			})
			local torsostomachs = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				bgImage = "../textures/store/presets/secgrad.tga",
				pos = { 0, 0.2, -1.6 },
				size = { 0.7, 1.1, 1.4 },
				rot = { -90, -90, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
			previewHolder:moveTo(0, 0.6, 0)
			return true
		elseif (item.catid == 41) then
			-- Grip items
			local color = get_color_info(item.colorid)
			local pcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.pgrad)
			local scolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.sgrad)
			local fcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force)
			local handp = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0.3, 0 },
				bgImage = "../textures/store/presets/prgrad.tga",
				size = { 1, 1, 1 },
				rot = { -45, 90, 0 },
				bgColor = { pcolor.r, pcolor.g, pcolor.b, trans },
				viewport = true
			})
			local hands = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0.3, 0 },
				bgImage = "../textures/store/presets/secgrad.tga",
				size = { 1, 1, 1 },
				rot = { -45, 90, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
			local wrist = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0, 0.6, -0.6 },
				size = { 0.45, 0.45, 0.45 },
				rot = { 0, 0, 0 },
				bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
				viewport = true
			})
			local tricepsp = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0.4, -1.3 },
				bgImage = "../textures/store/presets/prgrad.tga",
				size = { 1.1, 0.4, 0.4 },
				rot = { 25, 90, 0 },
				bgColor = { pcolor.r, pcolor.g, pcolor.b, trans },
				viewport = true
			})
			local tricepss = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0.4, -1.3 },
				bgImage = "../textures/store/presets/secgrad.tga",
				size = { 1.1, 0.4, 0.4 },
				rot = { 25, 90, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
			local grip = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0, -0.3, 0.4 },
				size = { 0.4, 0.4, 0.4 },
				bgColor = { color.r, color.g, color.b, 0.7 },
				viewport = true
			})
			previewMain:rotate(0, 0, 40)
			return true
		elseif (item.catid == 27 or item.catid == 28) then
			-- Hand Trail items
			local color = get_color_info(item.colorid)
			local pcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.pgrad)
			local scolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.sgrad)
			local fcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force)
			local handp = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0.3, 0.7 },
				bgImage = "../textures/store/presets/prgrad.tga",
				size = { 0.5, 0.5, 0.5 },
				rot = { -25, -90, 0 },
				bgColor = { pcolor.r, pcolor.g, pcolor.b, trans },
				viewport = true
			})
			local hands = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0.3, 0.7 },
				bgImage = "../textures/store/presets/secgrad.tga",
				size = { 0.5, 0.5, 0.5 },
				rot = { -25, -90, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
			local wrist = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0, 0.4, 0.4 },
				size = { 0.25, 0.25, 0.25 },
				rot = { 0, 0, 0 },
				bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
				viewport = true
			})
			local tricepsp = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0.58, 0 },
				bgImage = "../textures/store/presets/prgrad.tga",
				size = { 1.1, 0.25, 0.25 },
				rot = { -25, 90, 0 },
				bgColor = { pcolor.r, pcolor.g, pcolor.b, trans },
				viewport = true
			})
			local tricepss = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0.58, 0 },
				bgImage = "../textures/store/presets/secgrad.tga",
				size = { 1.1, 0.25, 0.25 },
				rot = { -25, 90, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
			local elbow = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0, 0.9, -0.7 },
				size = { 0.3, 0.3, 0.3 },
				rot = { 0, 0, 0 },
				bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
				viewport = true
			})
			local trail = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUSTOMOBJ,
				objModel = "../models/store/presets/trails",
				pos = { 0, -0.4, -0.2 },
				size = { 1.6 * scaleMultiplier, 1.6 * scaleMultiplier, 1.6 * scaleMultiplier },
				rot = { 80, 90, 0 },
				bgColor = { color.r, color.g, color.b, 1 },
				viewport = true
			})
			previewMain:rotate(0, 0, item.catid == 27 and -130 or 50)
			return true
		elseif (item.catid == 29 or item.catid == 30) then
			-- Leg Trail items
			local color = get_color_info(item.colorid)
			local pcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.pgrad)
			local scolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.sgrad)
			local fcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force)
			local legp = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, -0.3, -0.95 },
				bgImage = "../textures/store/presets/prgrad.tga",
				size = { 1.2, 0.5, 0.15 },
				rot = { 0, 10, -90 },
				bgColor = { pcolor.r, pcolor.g, pcolor.b, trans },
				viewport = true
			})
			local legs = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, -0.3, -0.95 },
				bgImage = "../textures/store/presets/secgrad.tga",
				size = { 1.2, 0.5, 0.15 },
				rot = { 0, 10, -90 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
			local ankle = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0, 0, -0.7 },
				size = { 0.28, 0.28, 0.28 },
				rot = { 0, 0, 0 },
				bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
				viewport = true
			})
			local legp = UIElement3D:new({
				parent = previewHolder,
				shapeType = CAPSULE,
				pos = { 0, -0.25, 0 },
				bgImage = "../textures/store/presets/gradient1.tga",
				size = { 0.3, 1, 0.3 },
				rot = { -25, 0, 0 },
				bgColor = { pcolor.r, pcolor.g, pcolor.b, trans },
				viewport = true
			})
			local legs = UIElement3D:new({
				parent = previewHolder,
				shapeType = CAPSULE,
				pos = { 0, -0.25, 0 },
				bgImage = "../textures/store/presets/gradient2.tga",
				size = { 0.3, 1, 0.3 },
				rot = { -25, 0, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
			local knee = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0, -0.52, 0.72 },
				size = { 0.32, 0.32, 0.32 },
				rot = { 0, 0, 0 },
				bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
				viewport = true
			})
			local trail = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUSTOMOBJ,
				objModel = "../models/store/presets/trails",
				pos = { 0, 0.8, 0 },
				size = { 1.6 * scaleMultiplier, 1.6 * scaleMultiplier, 1.6 * scaleMultiplier },
				rot = { -90, 90, 0 },
				bgColor = { color.r, color.g, color.b, 1 },
				viewport = true
			})
			previewMain:rotate(0, 0, item.catid == 30 and -60 or 50)
			return true
		elseif (item.catid == 73) then
			-- Hair Colors
			local color = get_color_info(item.colorid)
			local scaleMultiplier = scaleMultiplier * 5
			local head = UIElement3D:new({
				parent = previewHolder,
				shapeType = SPHERE,
				pos = { 0, 0, 0 },
				size = { 0.8, 0.8, 0.8 },
				viewport = true,
				bgImage = TB_MENU_PLAYER_INFO.items.textures.head.equipped and "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/head.tga" or "../../custom/tori/head.tga"
			})
			local model = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUSTOMOBJ,
				objModel = "../models/store/presets/hair",
				pos = { 0, 0, 0 },
				size = { 0.8 * scaleMultiplier, 0.8 * scaleMultiplier, 0.8 * scaleMultiplier },
				rot = { 0, 0, 0 },
				bgColor = { color.r, color.g, color.b, trans },
				viewport = true
			})
			previewHolder:moveTo(0, 0, -0.3)
			return true
		elseif (item.catid == 44 and item.colorid ~= 0) then
			-- Color Packs
			local color = get_color_info(item.colorid)
			local boxModel = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUSTOMOBJ,
				objModel = "../models/store/presets/box",
				pos = { 0, 0, -0.1 },
				size = { 1.3, 1.3, 1.3 },
				rot = { -90, 0, 0 },
				bgColor = { 0.7, 0.7, 0.7, 1 },
				viewport = true
			})
			local tbLogo = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUSTOMOBJ,
				objModel = "../models/store/presets/logo",
				pos = { 0, 0, -0.1 },
				size = { 1.3, 1.3, 1.3 },
				rot = { -90, 0, 0 },
				bgColor = { 0.222, 0.137, 0.064, 1 },
				viewport = true
			})
			local itemsModel = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUSTOMOBJ,
				objModel = "../models/store/presets/colourobjs",
				pos = { 0, 0, 0 },
				size = { 1.3, 1.3, 1.3 },
				rot = { -90, 0, 0 },
				bgColor = { color.r, color.g, color.b, 1 },
				viewport = true
			})
			local jointsModel = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUSTOMOBJ,
				objModel = "../models/store/presets/colourobjs_joints",
				pos = { 0, 0, 0 },
				size = { 1.3, 1.3, 1.3 },
				rot = { -90, 0, 0 },
				bgColor = { 0.66, 0.66, 0.66, 1 },
				viewport = true
			})
			local colorGlow = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUSTOMOBJ,
				objModel = "../models/store/presets/glow",
				pos = { 0, 0, -0.1 },
				size = { 1.3, 1.3, 1.3 },
				rot = { -90, 0, 0 },
				bgColor = { color.r, color.g, color.b, 1 },
				viewport = true
			})
			previewHolder:moveTo(0, 0, -0.2)
			previewMain:rotate(-10, 0, -40)
			return true
		elseif (item.catid == 78) then
			-- 3D Items
			if (Torishop:showObjPreview(item, viewElement, previewHolder, scaleMultiplier, trans, nil, level, noReload, updateOverride, updatedFunc)) then
				if (TB_STORE_MODELS[item.itemid].upgradeable) then
					local level = level or 1
					local buttonScale = viewport.shift.x - 5 > 32 and 32 or viewport.shift.x - 5
					if (TB_STORE_MODELS[item.itemid].levels > 1) then
						if (level < TB_STORE_MODELS[item.itemid].levels) then
							local nextLevel = UIElement:new({
								parent = viewElement,
								pos = { -(viewport.shift.x - buttonScale) / 2 - buttonScale, viewElement.size.h / 2 - buttonScale },
								size = { buttonScale, buttonScale * 2 },
								interactive = true,
								bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
								hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
								pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
								bgImage = "../textures/menu/general/buttons/arrowright.tga"
							})
							nextLevel:addMouseHandlers(nil, function()
									viewElement:kill(true)
									Torishop:showStoreAdvancedItemPreview(viewElement, item, noReload, updateOverride, updatedFunc, level + 1)
								end)
						end
						if (level > 1) then
							local prevLevel = UIElement:new({
								parent = viewElement,
								pos = { (viewport.shift.x - buttonScale) / 2, viewElement.size.h / 2 - buttonScale },
								size = { buttonScale, buttonScale * 2 },
								interactive = true,
								bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
								hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
								pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
								bgImage = "../textures/menu/general/buttons/arrowleft.tga"
							})
							prevLevel:addMouseHandlers(nil, function()
									viewElement:kill(true)
									Torishop:showStoreAdvancedItemPreview(viewElement, item, noReload, updateOverride, updatedFunc, level - 1)
								end)
						end
					end
				end
				return true
			else
				heightMod = 30
				if (get_option("autoupdate") == 0 and not updateOverride) then
					local downloadButton = UIElement:new({
						parent = viewElement,
						pos = { 0, iconScale + 5 },
						size = { viewElement.size.w, heightMod },
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
						hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
						interactive = true
					})
					downloadButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSDOWNLOAD)
					downloadButton:addMouseHandlers(nil, function()
							Torishop:showStoreItemInfo(item, noReload, true)
						end)
				else
					local updaterNotice = UIElement:new({
						parent = viewElement,
						pos = { 0, iconScale + 5 },
						size = { viewElement.size.w, heightMod },
						bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
					})
					local updaterNoticeText = UIElement:new({
						parent = updaterNotice,
						pos = { 10, 0 },
						size = { updaterNotice.size.w - 20, updaterNotice.size.h }
					})
					updaterNoticeText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREDOWNLOADINGMODEL)
				end
			end
		elseif (item.catid == 80) then
			-- Full Toris
			item.pack = true
			item.objs = {}
			for i,v in pairs(item.contents) do
				if (TB_STORE_MODELS[v] and not TB_STORE_MODELS[item.itemid]) then
					if (TB_STORE_MODELS[v].upgradeable) then
						item.upgradeable = true
						TB_STORE_MODELS[item.itemid] = cloneTable(TB_STORE_MODELS[v])
					end
				end
				local newItem = Torishop:getItemInfo(v)
				if (newItem.catid == 78) then
					table.insert(item.objs, newItem)
				end
			end
			if (#item.objs > 0) then
				if (Torishop:showObjPreview(item, viewElement, previewHolder, scaleMultiplier, trans, nil, level, noReload, updateOverride, updatedFunc)) then
					if (item.upgradeable) then
						local level = level or 1
						local buttonScale = viewport.shift.x - 5 > 32 and 32 or viewport.shift.x - 5
						if (TB_STORE_MODELS[item.itemid].levels > 1) then
							if (level < TB_STORE_MODELS[item.itemid].levels) then
								local nextLevel = UIElement:new({
									parent = viewElement,
									pos = { -(viewport.shift.x - buttonScale) / 2 - buttonScale, viewElement.size.h / 2 - buttonScale },
									size = { buttonScale, buttonScale * 2 },
									interactive = true,
									bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
									hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
									pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
									bgImage = "../textures/menu/general/buttons/arrowright.tga"
								})
								nextLevel:addMouseHandlers(nil, function()
										viewElement:kill(true)
										Torishop:showStoreAdvancedItemPreview(viewElement, item, noReload, updateOverride, updatedFunc, level + 1)
									end)
							end
							if (level > 1) then
								local prevLevel = UIElement:new({
									parent = viewElement,
									pos = { (viewport.shift.x - buttonScale) / 2, viewElement.size.h / 2 - buttonScale },
									size = { buttonScale, buttonScale * 2 },
									interactive = true,
									bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
									hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
									pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
									bgImage = "../textures/menu/general/buttons/arrowleft.tga"
								})
								prevLevel:addMouseHandlers(nil, function()
										viewElement:kill(true)
										Torishop:showStoreAdvancedItemPreview(viewElement, item, noReload, updateOverride, updatedFunc, level - 1)
									end)
							end
						end
					end
					return true
				else
					heightMod = 30
					if (get_option("autoupdate") == 0 and not updateOverride) then
						local downloadButton = UIElement:new({
							parent = viewElement,
							pos = { 0, iconScale + 5 },
							size = { viewElement.size.w, heightMod },
							bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
							hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
							pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
							interactive = true
						})
						downloadButton:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYSDOWNLOAD)
						downloadButton:addMouseHandlers(nil, function()
								Torishop:showStoreItemInfo(item, noReload, true)
							end)
					else
						local updaterNotice = UIElement:new({
							parent = viewElement,
							pos = { 0, iconScale + 5 },
							size = { viewElement.size.w, heightMod },
							bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
						})
						local updaterNoticeText = UIElement:new({
							parent = updaterNotice,
							pos = { 10, 0 },
							size = { updaterNotice.size.w - 20, updaterNotice.size.h }
						})
						updaterNoticeText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREDOWNLOADINGSET)
					end
				end
			end
		end
		viewport:kill()
		background:kill()
		local iconScale = viewElement.size.w > viewElement.size.h and viewElement.size.h or viewElement.size.w
		iconScale = iconScale > 64 and 64 or iconScale
		viewElement.size.h = iconScale + heightMod + 10
		local itemIcon = UIElement:new({
			parent = viewElement,
			pos = { (viewElement.size.w - iconScale) / 2, 0 },
			size = { iconScale, iconScale },
			bgImage = Torishop:getItemIcon(item.itemid)
		})
		if (heightMod > 0) then
			STORE_DOWNLOADS_COMPLETE = false
			return true
		end
		STORE_DOWNLOADS_COMPLETE = true
		return false
	end
	
	function Torishop:showPlayerBody(previewHolder, trans, customTextures)
		local fcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.force)
		local pcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.pgrad)
		local scolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.sgrad)
		local tcolor = get_color_info(TB_MENU_PLAYER_INFO.items.colors.torso)
		local textures = TB_MENU_PLAYER_INFO.items.textures
		local customPath = "../../custom/" .. TB_MENU_PLAYER_INFO.username .. "/"
		if (customTextures) then
			for i,v in pairs(textures) do
				for j,k in pairs(customTextures) do
					if (i == j) then
						textures[i] = k
					end
				end
			end
		end
		
		local bodyhead = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 0, 0, 0 },
			size = { 0.8, 0.8, 0.8 },
			viewport = true,
			bgImage = textures.head.equipped and (textures.head.path or (customPath .. "head.tga")) or "../../custom/tori/head.tga"
		})
		local bodybreast = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 0, 0.2, -1.8 },
			size = { 0.8, 0.4, 1.2 },
			bgColor = textures.breast.equipped and { 1, 1, 1, 1 } or { tcolor.r, tcolor.g, tcolor.b, 1 },
			bgImage = textures.breast.equipped and (textures.breast.path or (customPath .. "breast.tga")), 
			viewport = true
		})
		local lbodypecs = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 1, 0.2, -2 },
			size = { 0.8, 0.6, 0.8 },
			bgColor = textures.l_pec.equipped and { 1, 1, 1, 1 } or { tcolor.r, tcolor.g, tcolor.b, 1 },
			bgImage = textures.l_pec.equipped and (textures.l_pec.path or (customPath .. "l_pecs.tga")), 
			viewport = true
		})
		local rbodypecs = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -1, 0.2, -2 },
			size = { 0.8, 0.6, 0.8 },
			bgColor = textures.r_pec.equipped and { 1, 1, 1, 1 } or { tcolor.r, tcolor.g, tcolor.b, 1 },
			bgImage = textures.r_pec.equipped and (textures.r_pec.path or (customPath .. "r_pecs.tga")), 
			viewport = true
		})
		local bodychest = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 0, 0.2, -2.8 },
			size = { 2, 0.6, 0.8 },
			bgColor = textures.chest.equipped and { 1, 1, 1, 1 } or { tcolor.r, tcolor.g, tcolor.b, 1 },
			bgImage = textures.chest.equipped and (textures.chest.path or (customPath .. "chest.tga")), 
			viewport = true
		})
		local bodystomach = UIElement3D:new({
			parent = previewHolder,
			pos = { 0, 0.4, -3.6 },
			size = { 1.4, 0.8, 0.6 },
			shapeType = CUBE,
			viewport = true
		})
		local bodystomachp, bodystomachs = nil, nil
		if (textures.stomach.equipped) then
			bodystomach.bgColor = { 1, 1, 1, 1 }
			bodystomach:updateImage(textures.stomach.path or (customPath .. "stomach.tga"))
		else
			bodystomach:addCustomDisplay(true, function() end)
			bodystomachp = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0.4, -3.6 },
				size = { 0.6, 0.8, 1.4 },
				bgColor = { pcolor.r, pcolor.g, pcolor.b, trans },
				bgImage = "../textures/store/presets/prgrad.tga",
				rot = { 90, 90, 0 },
				viewport = true
			})
			bodystomachs = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0.4, -3.6 },
				size = { 0.6, 0.8, 1.4 },
				bgImage = "../textures/store/presets/secgrad.tga",
				rot = { 90, 90, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local bodygroin = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 0, 0.6, -4.4 },
			size = { 0.8, 0.6, 0.8 },
			viewport = true
		})
		local bodygroinp, bodygroins = nil, nil
		if (textures.groin.equipped) then
			bodygroin.bgColor = { 1, 1, 1, 1 }
			bodygroin:updateImage(textures.groin.path or (customPath .. "groin.tga"))
		else
			bodygroin:addCustomDisplay(true, function() end)
			bodygroinp = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0.6, -4.4 },
				size = { 0.8, 0.6, 0.8 },
				bgColor = { pcolor.r, pcolor.g, pcolor.b, trans },
				bgImage = "../textures/store/presets/prgrad.tga",
				rot = { 90, 90, 0 },
				viewport = true
			})
			bodygroins = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0, 0.6, -4.4 },
				size = { 0.8, 0.6, 0.8 },
				bgImage = "../textures/store/presets/secgrad.tga",
				rot = { 90, 90, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local lbodythigh = UIElement3D:new({
			parent = previewHolder,
			shapeType = CAPSULE,
			pos = { 0.8, 0.6, -6.2 },
			size = { 0.48, 0.48, 2.16 },
			viewport = true
		})
		lbodythigh:addCustomDisplay(true, function() end)
		local lbodythighp = UIElement3D:new({
			parent = previewHolder,
			shapeType = CAPSULE,
			pos = { 0.8, 0.6, -6.2 },
			size = { 0.48, 1.2, 0 },
			bgColor = textures.l_thigh.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = textures.l_thigh.equipped and (textures.l_thigh.path or (customPath .. "l_thigh.tga")) or "../textures/store/presets/gradient1.tga",
			rot = { 0, 0, 0 },
			viewport = true
		})
		local lbodythighs = nil
		if (not textures.l_thigh.equipped) then
			lbodythighs = UIElement3D:new({
				parent = previewHolder,
				shapeType = CAPSULE,
				pos = { 0.8, 0.6, -6.2 },
				size = { 0.48, 1.2, 0 },
				bgImage = "../textures/store/presets/gradient2.tga",
				rot = { 0, 0, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local rbodythigh = UIElement3D:new({
			parent = previewHolder,
			shapeType = CAPSULE,
			pos = { -0.8, 0.6, -6.2 },
			size = { 0.48, 0.48, 2.16 },
			viewport = true
		})
		rbodythigh:addCustomDisplay(true, function() end)
		local rbodythighp = UIElement3D:new({
			parent = previewHolder,
			shapeType = CAPSULE,
			pos = { -0.8, 0.6, -6.2 },
			size = { 0.48, 1.2, 0 },
			bgColor = textures.r_thigh.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = textures.r_thigh.equipped and (textures.r_thigh.path or (customPath .. "r_thigh.tga")) or "../textures/store/presets/gradient1.tga",
			rot = { 0, 0, 0 },
			viewport = true
		})
		local rbodythighs = nil
		if (not textures.r_thigh.equipped) then
			rbodythighs = UIElement3D:new({
				parent = previewHolder,
				shapeType = CAPSULE,
				pos = { -0.8, 0.6, -6.2 },
				size = { 0.48, 1.2, 0 },
				bgImage = "../textures/store/presets/gradient2.tga",
				rot = { 0, 0, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local lbodyleg = UIElement3D:new({
			parent = previewHolder,
			shapeType = CAPSULE,
			pos = { 0.8, 0.6, -8.6 },
			size = { 0.52, 0.52, 2.24 },
			viewport = true
		})
		lbodyleg:addCustomDisplay(true, function() end)
		local lbodylegp = UIElement3D:new({
			parent = previewHolder,
			shapeType = CAPSULE,
			pos = { 0.8, 0.6, -8.6 },
			size = { 0.52, 1.2, 0 },
			bgColor = textures.l_leg.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = textures.l_leg.equipped and (textures.l_leg.path or (customPath .. "l_leg.tga")) or "../textures/store/presets/gradient1.tga",
			rot = { 0, 0, 0 },
			viewport = true
		})
		local lbodylegs = nil
		if (not textures.l_leg.equipped) then
			lbodylegs = UIElement3D:new({
				parent = previewHolder,
				shapeType = CAPSULE,
				pos = { 0.8, 0.6, -8.6 },
				size = { 0.52, 1.2, 0 },
				bgImage = "../textures/store/presets/gradient2.tga",
				rot = { 0, 0, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local rbodyleg = UIElement3D:new({
			parent = previewHolder,
			shapeType = CAPSULE,
			pos = { -0.8, 0.6, -8.6 },
			size = { 0.52, 0.52, 2.24 },
			viewport = true
		})
		rbodyleg:addCustomDisplay(true, function() end)
		local rbodylegp = UIElement3D:new({
			parent = previewHolder,
			shapeType = CAPSULE,
			pos = { -0.8, 0.6, -8.6 },
			size = { 0.52, 1.2, 0 },
			bgColor = textures.r_leg.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = textures.r_leg.equipped and (textures.r_leg.path or (customPath .. "r_leg.tga")) or "../textures/store/presets/gradient1.tga",
			rot = { 0, 0, 0 },
			viewport = true
		})
		local rbodylegs = nil
		if (not textures.r_leg.equipped) then
			rbodylegs = UIElement3D:new({
				parent = previewHolder,
				shapeType = CAPSULE,
				pos = { -0.8, 0.6, -8.6 },
				size = { 0.52, 1.2, 0 },
				bgImage = "../textures/store/presets/gradient2.tga",
				rot = { 0, 0, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local lbodyfoot = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 0.8, 0.2, -10.2 },
			size = { 0.8, 2, 0.32 },
			viewport = true
		})
		lbodyfoot:addCustomDisplay(true, function() end)
		local lbodyfootp = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 0.8, 0.2, -10.2 },
			size = { 2, 0.32, 0.8 },
			bgColor = textures.l_foot.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = textures.l_foot.equipped and (textures.l_foot.path or (customPath .. "l_foot.tga")) or "../textures/store/presets/prgrad.tga",
			rot = { 90, 90, 0 },
			viewport = true
		})
		local lbodyfoots = nil
		if (not textures.l_foot.equipped) then
			lbodyfoots = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 0.8, 0.2, -10.2 },
				size = { 2, 0.32, 0.8 },
				bgImage = "../textures/store/presets/secgrad.tga",
				rot = { 90, 90, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local rbodyfoot = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -0.8, 0.2, -10.2 },
			size = { 0.8, 2, 0.32 },
			viewport = true
		})
		rbodyfoot:addCustomDisplay(true, function() end)
		local rbodyfootp = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -0.8, 0.2, -10.2 },
			size = { 2, 0.32, 0.8 },
			bgColor = textures.r_foot.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = textures.r_foot.equipped and (textures.r_foot.path or (customPath .. "r_foot.tga")) or "../textures/store/presets/prgrad.tga",
			rot = { 90, 90, 0 },
			viewport = true
		})
		local rbodyfoots = nil
		if (not textures.r_foot.equipped) then
			rbodyfoots = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { -0.8, 0.2, -10.2 },
				size = { 2, 0.32, 0.8 },
				bgImage = "../textures/store/presets/secgrad.tga",
				rot = { 90, 90, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local lbodybicep = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 2.2, 0.2, -1.4 },
			size = { 1.6, 0.8, 0.8 },
			viewport = true
		})
		lbodybicep:addCustomDisplay(true, function() end)
		local lbodybicepp = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 2.2, 0.2, -1.4 },
			size = { 1.6, 0.8, 0.8 },
			bgColor = textures.l_bicep.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = textures.l_bicep.equipped and (textures.l_bicep.path or (customPath .. "l_biceps.tga")) or "../textures/store/presets/prgrad.tga",
			rot = { 0, 0, 180 },
			viewport = true
		})
		local lbodybiceps = nil
		if (not textures.l_bicep.equipped) then
			lbodybiceps = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 2.2, 0.2, -1.4 },
				size = { 1.6, 0.8, 0.8 },
				bgImage = "../textures/store/presets/secgrad.tga",
				rot = { 0, 0, 180 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local rbodybicep = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -2.2, 0.2, -1.4 },
			size = { 1.6, 0.8, 0.8 },
			viewport = true
		})
		rbodybicep:addCustomDisplay(true, function() end)
		local rbodybicepp = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -2.2, 0.2, -1.4 },
			size = { 1.6, 0.8, 0.8 },
			bgColor = textures.r_bicep.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = textures.r_bicep.equipped and (textures.r_bicep.path or (customPath .. "r_biceps.tga")) or "../textures/store/presets/prgrad.tga",
			rot = { 0, 0, 0 },
			viewport = true
		})
		local rbodybiceps = nil
		if (not textures.r_bicep.equipped) then
			rbodybiceps = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { -2.2, 0.2, -1.4 },
				size = { 1.6, 0.8, 0.8 },
				bgImage = "../textures/store/presets/secgrad.tga",
				rot = { 0, 0, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local lbodytricep = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 3.8, 0.2, -1.4 },
			size = { 1.6, 0.4, 0.4 },
			viewport = true
		})
		lbodytricep:addCustomDisplay(true, function() end)
		local lbodytricepp = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 3.8, 0.2, -1.4 },
			size = { 1.6, 0.4, 0.4 },
			bgColor = textures.l_tricep.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = textures.l_tricep.equipped and (textures.l_tricep.path or (customPath .. "l_triceps.tga")) or "../textures/store/presets/prgrad.tga",
			rot = { 0, 0, 180 },
			viewport = true
		})
		local lbodytriceps = nil
		if (not textures.l_tricep.equipped) then
			lbodytriceps = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 3.8, 0.2, -1.4 },
				size = { 1.6, 0.4, 0.4 },
				bgImage = "../textures/store/presets/secgrad.tga",
				rot = { 0, 0, 180 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local rbodytricep = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -3.8, 0.2, -1.4 },
			size = { 1.6, 0.4, 0.4 },
			viewport = true
		})
		rbodytricep:addCustomDisplay(true, function() end)
		local rbodytricepp = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -3.8, 0.2, -1.4 },
			size = { 1.6, 0.4, 0.4 },
			bgColor = textures.r_tricep.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = textures.r_tricep.equipped and (textures.r_tricep.path or (customPath .. "r_triceps.tga")) or "../textures/store/presets/prgrad.tga",
			rot = { 0, 0, 0 },
			viewport = true
		})
		local rbodytriceps = nil
		if (not textures.r_tricep.equipped) then
			rbodytriceps = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { -3.8, 0.2, -1.4 },
				size = { 1.6, 0.4, 0.4 },
				bgImage = "../textures/store/presets/secgrad.tga",
				rot = { 0, 0, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local lbodyhand = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 5.4, 0, -1.4 },
			size = { 0.88, 0.88, 0.88 },
			viewport = true
		})
		lbodyhand:addCustomDisplay(true, function() end)
		local lbodyhandp = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 5.4, 0, -1.4 },
			size = { 0.88, 0.88, 0.88 },
			bgColor = textures.l_hand.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = textures.l_hand.equipped and (textures.l_hand.path or (customPath .. "l_hand.tga")) or "../textures/store/presets/prgrad.tga",
			rot = { 0, 0, 180 },
			viewport = true
		})
		local lbodyhands = nil
		if (not textures.l_hand.equipped) then
			lbodyhands = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { 5.4, 0, -1.4 },
				size = { 0.88, 0.88, 0.88 },
				bgImage = "../textures/store/presets/secgrad.tga",
				rot = { 0, 0, 180 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local rbodyhand = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -5.4, 0, -1.4 },
			size = { 0.88, 0.88, 0.88 },
			viewport = true
		})
		rbodyhand:addCustomDisplay(true, function() end)
		local rbodyhandp = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -5.4, 0, -1.4 },
			size = { 0.88, 0.88, 0.88 },
			bgColor = textures.r_hand.equipped and { 1, 1, 1, 1 } or { pcolor.r, pcolor.g, pcolor.b, trans },
			bgImage = textures.r_hand.equipped and (textures.r_hand.path or (customPath .. "r_hand.tga")) or "../textures/store/presets/prgrad.tga",
			rot = { 0, 0, 0 },
			viewport = true
		})
		local rbodyhands = nil
		if (not textures.r_hand.equipped) then
			rbodyhands = UIElement3D:new({
				parent = previewHolder,
				shapeType = CUBE,
				pos = { -5.4, 0, -1.4 },
				size = { 0.88, 0.88, 0.88 },
				bgImage = "../textures/store/presets/secgrad.tga",
				rot = { 0, 0, 0 },
				bgColor = { scolor.r, scolor.g, scolor.b, trans },
				viewport = true
			})
		end
		local rbodybutt = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { -0.8, 0.6, -4.8 },
			size = { 0.4, 0.4, 0.4 },
			viewport = true
		})
		local lbodybutt = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUBE,
			pos = { 0.8, 0.6, -4.8 },
			size = { 0.4, 0.4, 0.4 },
			viewport = true
		})
		
		local neck = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 0, 0.2, -0.6 },
			size = { 0.44, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local lpecs = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 0.6, 0, -1.8 },
			size = { 0.72, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local rpecs = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { -0.6, 0, -1.8 },
			size = { 0.72, 0, 0 },
			bgColor = { 1, 0, 1, 1 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local lshoulder = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 1.4, 0.2, -1.4 },
			size = { 0.72, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local rshoulder = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { -1.4, 0.2, -1.4 },
			size = { 0.72, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local lelbow = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 3, 0.2, -1.4 },
			size = { 0.64, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local relbow = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { -3, 0.2, -1.4 },
			size = { 0.64, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local lwrist = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 4.8, 0.2, -1.4 },
			size = { 0.44, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local rwrist = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { -4.8, 0.2, -1.4 },
			size = { 0.44, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local chest = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 0, 0.2, -2.4 },
			size = { 0.72, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local lumbar = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 0, 0.4, -3.2 },
			size = { 0.64, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local abs = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 0, 0.6, -4 },
			size = { 0.56, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local lglute = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 0.4, 1, -4.56 },
			size = { 0.64, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local rglute = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { -0.4, 1, -4.56 },
			size = { 0.64, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local lhip = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 0.84, 0.6, -5 },
			size = { 0.64, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local rhip = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { -0.84, 0.6, -5 },
			size = { 0.64, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local lknee = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 0.8, 0.6, -7.4 },
			size = { 0.56, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local rknee = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { -0.8, 0.6, -7.4 },
			size = { 0.56, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local lankle = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { 0.8, 0.8, -9.6 },
			size = { 0.44, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		local rankle = UIElement3D:new({
			parent = previewHolder,
			shapeType = SPHERE,
			pos = { -0.8, 0.8, -9.6 },
			size = { 0.44, 0, 0 },
			bgColor = { fcolor.r, fcolor.g, fcolor.b, 1 },
			viewport = true
		})
		
		bodystomach.linked = { bodystomachp, bodystomachs }
		bodygroin.linked = { bodygroinp, bodygroins }
		lbodythigh.linked = { lbodythighp, lbodythighs }
		rbodythigh.linked = { rbodythighp, rbodythighs }
		lbodyleg.linked = { lbodylegp, lbodylegs }
		rbodyleg.linked = { rbodylegp, rbodylegs }
		lbodyfoot.linked = { lbodyfootp, lbodyfoots }
		rbodyfoot.linked = { rbodyfootp, rbodyfoots }
		lbodybicep.linked = { lbodybicepp, lbodybiceps }
		rbodybicep.linked = { rbodybicepp, rbodybiceps }
		lbodytricep.linked = { lbodytricepp, lbodytriceps }
		rbodytricep.linked = { rbodytricepp, rbodytriceps }
		lbodyhand.linked = { lbodyhandp, lbodyhands }
		rbodyhand.linked = { rbodyhandp, rbodyhands }
		
		-- neck.linked = { jneck }
		-- lpecs.linked = { jlpecs }
		-- rpecs.linked = { jrpecs }
		-- lshoulder.linked = { jlshoulder }
		-- rshoulder.linked = { jrshoulder }
		-- lelbow.linked = { jlelbow }
		-- relbow.linked = { jrelbow }
		-- lwrist.linked = { jlwrist }
		-- rwrist.linked = { jrwrist }
		-- chest.linked = { jchest }
		-- lumbar.linked = { jlumbar }
		-- abs.linked = { jabs }
		-- lglute.linked = { jlglute }
		-- rglute.linked = { jrglute }
		-- lhip.linked = { jlhip }
		-- rhip.linked = { jrhip }
		-- lknee.linked = { jlknee }
		-- rknee.linked = { jrknee }
		-- lankle.linked = { jlankle }
		-- rankle.linked = { jrankle }
		
		local bodyparts = { bodyhead, bodybreast, bodychest, bodystomach, bodygroin, rbodypecs, rbodybicep, rbodytricep, lbodypecs, lbodybicep, lbodytricep, rbodyhand, lbodyhand, rbodybutt, lbodybutt, rbodythigh, lbodythigh, lbodyleg, rbodyleg, rbodyfoot, lbodyfoot }
		local joints = { neck, chest, lumbar, abs, rpecs, rshoulder, relbow, lpecs, lshoulder, lelbow, rwrist, lwrist, rglute, lglute, rhip, lhip, rknee, lknee, rankle, lankle }
		return { bodypart = bodyparts, joint = joints }
	end
	
	function Torishop:drawObjItem(item, previewHolder, scaleMultiplier, objPath, bodyInfos, cameraMove, level)
		local modelInfo = TB_STORE_MODELS[item.itemid].upgradeable and TB_STORE_MODELS[item.itemid][level or 1] or TB_STORE_MODELS[item.itemid]
		local color = get_color_info(modelInfo.colorid)
		local scaleMultiplier = scaleMultiplier * (modelInfo.dynamic and 1 or 5)
		local modelData = { pos = { 0, 0, 0 }, rot = { 0, 0, 0 } }
		local scale = { 0.8, 0.8, 0.8 }
		if (modelInfo.bodyid < 21) then
			local body = bodyInfos.bodypart[modelInfo.bodyid + 1]
			modelData.pos = { body.shift.x, body.shift.y, body.shift.z }
			if (cameraMove) then
				local pos = body.pos
				previewHolder.parent:rotate(0, 0, -previewHolder.parent.rotXYZ.z)
				previewHolder:moveTo(-pos.x, -pos.y, -pos.z + 10)
			end
		elseif (modelInfo.bodyid < 41) then
			local joint = bodyInfos.joint[modelInfo.bodyid - 20]
			modelData.pos = { joint.shift.x, joint.shift.y, joint.shift.z }
			if (cameraMove) then
				local pos = joint.pos
				previewHolder.parent:rotate(0, 0, -previewHolder.parent.rotXYZ.z)
				previewHolder:moveTo(-pos.x, -pos.y, -pos.z + 10)
			end
		else
			modelData.pos = { 0, 0, -11 }
			if (cameraMove) then
				previewHolder.parent:moveTo(0, 7, 4)
			end
		end
		
		local stonerelax = { 3140, 3143, 3144, 3145, 3146, 3147, 3148, 3149, 3150, 3151, 3152, 3153, 3154, 3155, 3156, 3157, 3158, 3159, 3160, 3161 }
		if (in_array(item.itemid, stonerelax)) then
			modelInfo.partless = true
		end
		
		if (modelInfo.dynamic) then
			if (modelInfo.bodyid < 21) then
				local mScale = bodyInfos.bodypart[modelInfo.bodyid + 1].size
				scale = { mScale.x, mScale.y, mScale.z }
			elseif (modelInfo.bodyid < 41) then
				local mScale = bodyInfos.joint[modelInfo.bodyid - 20].size
				scale = { mScale.x, mScale.x, mScale.x }
			end
		end
		if (modelInfo.partless) then
			if (modelInfo.bodyid < 21) then
				if (bodyInfos.bodypart[modelInfo.bodyid + 1].linked) then
					for i,v in pairs(bodyInfos.bodypart[modelInfo.bodyid + 1].linked) do
						v:kill()
					end
				else
					bodyInfos.bodypart[modelInfo.bodyid + 1]:kill()
				end
			elseif (modelInfo.bodyid < 41) then
				if (bodyInfos.joint[modelInfo.bodyid - 20].linked) then
					for i,v in pairs(bodyInfos.joint[modelInfo.bodyid - 20].linked) do
						v:kill()
					end
				else
					bodyInfos.joint[modelInfo.bodyid - 20]:kill()
				end
			end
		end
		local model = UIElement3D:new({
			parent = previewHolder,
			shapeType = CUSTOMOBJ,
			objModel = objPath,
			pos = modelData.pos,
			size = { scale[1] * scaleMultiplier, scale[2] * scaleMultiplier, scale[3] * scaleMultiplier },
			rot = modelData.rot,
			bgColor = { color.r, color.g, color.b, modelInfo.alpha / 255 },
			viewport = true
		})
		return model
	end
	
	function Torishop:showObjPreview(items, viewElement, previewHolder, scaleMultiplier, trans, textures, level, noReload, updateOverride, updatedFunc)
		local level = level or 1
		viewElement.scrollEnabled = true
		viewElement:addMouseHandlers(function(s, x, y)
				if (s >= 4 and viewElement.hoverState == BTN_HVR) then
					previewHolder.parent:moveTo(0, -0.3 * y)
				else
					viewElement.pressedPos.x = MOUSE_X
				end
			end)
		local itemslist = {}
		if (not items.pack) then
			table.insert(itemslist, items)
		else
			for i,v in pairs(items.objs) do
				table.insert(itemslist, v)
			end
			items.objs = nil
			table.insert(itemslist, items)
		end
		
		local modelDrawn = false
		local bodyInfos = Torishop:showPlayerBody(previewHolder, trans, textures)
		local cameraMove = true
		if (#itemslist > 1) then
			previewHolder.parent:moveTo(0, 10, 4.5)
			cameraMove = false
		end
		
		local itemHolder = nil
		for i, item in pairs(itemslist) do
			local objPath = "../models/store/" .. item.itemid .. (level > 1 and ("_" .. level) or '')
			local objModel = Files:new("../data/models/store/" .. item.itemid .. (level > 1 and ("_" .. level) or '') .. ".obj")
			if (objModel.data) then
				objModel:close()
				itemHolder = Torishop:drawObjItem(item, previewHolder, scaleMultiplier, objPath, bodyInfos, cameraMove, level)
				modelDrawn = true
			end
		end
		if (noReload) then
			return modelDrawn
		end
		
		local function downloadProgress()
			local downloads = get_downloads()
			for i,v in pairs(downloads) do
				for j, item in pairs(itemslist) do
					local objPath = "../models/store/" .. item.itemid .. (level > 1 and ("_" .. level) or '')
					if (v:find(objPath:gsub("%.%./", ""))) then
						return true
					end
				end
			end
			return false
		end
		
		local function downloadFile(i)
			if (TB_STORE_MODELS[itemslist[i].itemid]) then
				if (TB_STORE_MODELS[itemslist[i].itemid].upgradeable) then
					download_server_file(itemslist[i].itemid .. "_" .. level, 1)
				else
					download_server_file(itemslist[i].itemid, 1)
				end
			else
				download_server_file(itemslist[i].itemid, 1)
			end
			if (i < #itemslist) then
				Request:new("store_itemdownload", function()
						local dWait = UIElement:new({
							parent = viewElement,
							pos = { 0, 0 },
							size = { 0, 0 }
						})
						local wait = 0
						dWait:addCustomDisplay(true, function()
								wait = wait + 1
								if (wait > 1) then
									dWait:kill()
									downloadFile(i + 1)
								end
							end)
					end)
			else
				-- store element update time to prevent reloading item info when user has switched to another item preview
				local sectionTime = tbStoreItemInfoHolder and tbStoreItemInfoHolder.updated or 0
				Request:new("store_itemdownload", function()
						local itemUpdater = UIElement:new({
							parent = viewElement,
							pos = { 0, 0 },
							size = { 0, 0 }
						})
						local forcedDelay = os.clock()
						local filesUpdated = false
						itemUpdater:addCustomDisplay(true, function()
								local isDownloading = downloadProgress()
								filesUpdated = filesUpdated or isDownloading
								if (forcedDelay < os.clock() - 0.2 and not isDownloading) then
									if (not itemHolder or filesUpdated) then
										if (itemHolder) then
											itemHolder:kill()
										end
										if (updatedFunc) then
											updatedFunc()
										elseif (sectionTime > 0) then
											if (sectionTime == tbStoreItemInfoHolder.updated) then
												Torishop:showStoreItemInfo(items, true)
											end
										end
									end
									STORE_DOWNLOADS_COMPLETE = true
									MODEL_DOWNLOAD_ACTIVE = false
									itemUpdater:kill()
								end
							end)
					end)
			end
		end
		
		if (updateOverride or get_option("autoupdate") == 1) then
			if (get_network_task() == 0) then
				downloadFile(1)
			else
				MODEL_DOWNLOAD_ACTIVE = true
				local downloadWaiter = UIElement:new({
					parent = viewElement,
					pos = { 0, 0 },
					size = { 0, 0 }
				})
				downloadWaiter:addCustomDisplay(true, function()
						if (get_network_task() == 0) then
							downloadFile(1)
							downloadWaiter:kill()
						end
					end)
			end
		end
		return modelDrawn
	end
	
	function Torishop:buyItem(item, mode)
		function doPurchase()
			if (get_network_task() == 0) then
				if (mode == MODE_TC) then
					buy_tc(item.itemid .. ":" .. item.now_tc_price)
				else
					buy_st(item.itemid .. ":" .. item.now_usd_price)
				end
				Torishop:showPostPurchaseScreen(item)
				return true
			end
			return false
		end
		if (not doPurchase()) then
			local overlay = TBMenu:spawnWindowOverlay()
			overlay:addMouseHandlers(nil, function() overlay:kill() end)
			local waiting = UIElement:new({
				parent = overlay,
				pos = { overlay.size.w / 7 * 2, overlay.size.h / 2 - 75 },
				size = { overlay.size.w / 7 * 3, 150 },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			waiting:addAdaptedText(false, TB_MENU_LOCALIZED.STORELOADING)
			local waiter = UIElement:new({
				parent = waiting,
				pos = { 0, 0 },
				size = { 0, 0 }
			})
			waiter.timer = 0
			waiter:addCustomDisplay(true, function()
					waiter.timer = waiter.timer + 1
					if (waiter.timer > 5) then
						if (doPurchase()) then
							overlay:kill()
						end
					end
				end)
		end
	end
	
	function Torishop:showPostPurchaseScreen(item, forceSucessDisplay, forceRefreshItem)
		local overlay = TBMenu:spawnWindowOverlay()
		local purchasing = UIElement:new({
			parent = overlay,
			pos = { overlay.size.w / 7 * 2, overlay.size.h / 2 - 75 },
			size = { overlay.size.w / 7 * 3, 150 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		purchasing:addAdaptedText(false, TB_MENU_LOCALIZED.STOREPURCHASINGITEM)
		local function fn(text)
			purchasing:addAdaptedText(false, text)
			overlay:addMouseHandlers(nil, function()
					overlay:kill()
				end)
			local timedKill = UIElement:new({
				parent = overlay,
				pos = { 0, 0 },
				size = { 0, 0 }
			})
			local spawnTime = os.clock()
			timedKill:addCustomDisplay(true, function()
					if (spawnTime + 2 < os.clock()) then
						overlay:kill()
					end
				end)
		end
		Request:new("itempurchase", function()
				local response = get_network_response()
				if (response:find("^ERROR 0;")) then
					response = response:gsub("^ERROR 0;", "")
					fn(TB_MENU_LOCALIZED.STOREPURCHASEERROR .. ": " .. response)
				elseif (response:find("^SUCCESS 0;")) then
					local invid = response:gsub("^SUCCESS 0;", "")
					if (forceRefreshItem) then
						local waiter = UIElement:new({
							parent = overlay,
							pos = { 0, 0 },
							size = { 0, 0 }
						})
						waiter.timeAlive = 0
						waiter:addCustomDisplay(true, function()
								waiter.timeAlive = waiter.timeAlive + 1
								if (get_network_task() == 0 and waiter.timeAlive > 5) then
									Request:new("itempurchase", function()
											local response = get_network_response()
											if (response:find("^ITEMID 0;")) then
												local itemid = response:gsub("^ITEMID 0;", "")
												local item = Torishop:getItemInfo(itemid)
												update_tc_balance()
												overlay:kill()
												if (#item.contents > 0) then
													TBMenu:showConfirmationWindow("Congratulations, you have received " .. item.itemname .. "!\nWould you like to unpack your new item?", function()
															INVENTORY_UPDATE = true
															INVENTORY_MOUSE_POS = { x = posX, y = posY }
															show_dialog_box(INVENTORY_UNPACK, TB_MENU_LOCALIZED.STOREDIALOGUNPACK1 .. " " .. item.itemname .. (TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 .. "?") .. "\n" .. TB_MENU_LOCALIZED.STOREDIALOGUNPACKINFO, invid)
														end)
												elseif (item.ingame == 1) then
													if (in_array(item.catid, CATEGORIES_COLORS)) then
														check_steam_color(item.colorid)
													end
													TBMenu:showConfirmationWindow("Congratulations, you have received " .. item.itemname .. "!\nWould you like to activate your new item?", function()
															INVENTORY_UPDATE = true
															INVENTORY_MOUSE_POS = { x = posX, y = posY }
															show_dialog_box(INVENTORY_ACTIVATE, TB_MENU_LOCALIZED.STOREDIALOGACTIVATE1 .. " " .. item.itemname .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 .. "?"), invid)
														end)
												elseif (forceSucessDisplay) then
													TBMenu:showDataError(item.itemname .. " " .. TB_MENU_LOCALIZED.STOREITEMPURCHASESUCCESSFUL)
												end
											else
												fn(TB_MENU_LOCALIZED.STOREPURCHASEERROR)
											end
										end)
									download_server_info("getitemid&invid=" .. invid)
									waiter:kill()
								end
							end)
						return
					end
					update_tc_balance()
					overlay:kill()
					if (#item.contents > 0) then
						TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASESUCCESSFULUNPACK, function()
								INVENTORY_UPDATE = true
								INVENTORY_MOUSE_POS = { x = posX, y = posY }
								show_dialog_box(INVENTORY_UNPACK, TB_MENU_LOCALIZED.STOREDIALOGUNPACK1 .. " " .. item.itemname .. (TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 .. "?") .. "\n" .. TB_MENU_LOCALIZED.STOREDIALOGUNPACKINFO, invid)
							end)
					elseif (item.ingame == 1) then
						if (in_array(item.catid, CATEGORIES_COLORS)) then
							check_steam_color(item.colorid)
						end
						TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASESUCCESSFUL, function()
								INVENTORY_UPDATE = true
								INVENTORY_MOUSE_POS = { x = posX, y = posY }
								show_dialog_box(INVENTORY_ACTIVATE, TB_MENU_LOCALIZED.STOREDIALOGACTIVATE1 .. " " .. item.itemname .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 .. "?"), invid)
							end)
					elseif (forceSucessDisplay) then
						TBMenu:showDataError(item.itemname .. " " .. TB_MENU_LOCALIZED.STOREITEMPURCHASESUCCESSFUL)
					end
				else
					fn(TB_MENU_LOCALIZED.STOREPURCHASEERRORUNDEF)
				end
			end, function()
				fn(TB_MENU_LOCALIZED.STOREPURCHASESERVERERROR)
			end)
	end
	
	function Torishop:previewHairVanilla(item)
		download_server_info("get_hair&itemid=" .. item.itemid)
		if (storeVanillaLoading) then
			storeVanillaLoading:kill()
			storeVanillaLoading = nil
		end
		storeVanillaLoading = UIElement:new({
			globalid = TB_MENU_MAIN_GLOBALID,
			pos = { WIN_W - 200, WIN_H - 50 },
			size = { 200, 50 },
			uiColor = UICOLORBLACK
		})
		TBMenu:displayLoadingMarkSmall(storeVanillaLoading, "Loading")
		Request:new("storevanillahair", function()
				local response = get_network_response()
				storeVanillaLoading:kill()
				if (response:find("ERROR")) then
					TBMenu:showDataError(TB_MENU_LOCALIZED.STOREREQUESTNOTHAIRSTYLE)
				end
				local id = 0
				for ln in response:gmatch("[^\n]+\n?") do
					local hr = { ln:match(("(%d+) ?"):rep(17)) }
					set_hair_settings(0, hr[1], hr[2], hr[3], hr[4], hr[5], hr[6], hr[7], hr[8], hr[9], hr[10], hr[11], hr[12], hr[13], hr[14], hr[15], hr[16], hr[17])
					id = id + 1
				end
				for i = id, 15 do
					set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
				end
				reset_hair(0)
				set_hair_color(0, 0)
			end, function()
				storeVanillaLoading:kill()
				local err = get_network_error()
				if (err:find("Couldn't resolve")) then
					TBMenu:showDataError(TB_MENU_LOCALIZED.REQUESTCONNECTIONERROR)
					return
				end
				TBMenu:showDataError(TB_MENU_LOCALIZED.REQUESTUNKNOWNERROR)
			end)
	end
	
	function Torishop:doItemPreviewVanilla(item, parentItem)
		if (item.catid == 1) then
			set_blood_color(0, item.colorid)
		elseif (item.catid == 2) then
			set_joint_relax_color(0, item.colorid)
		elseif (item.catid == 5) then
			set_torso_color(0, item.colorid)
		elseif (item.catid == 11) then
			set_ghost_color(0, item.colorid)
		elseif (item.catid == 12) then
			set_ground_impact_color(0, item.colorid)
			draw_ground_impact(0)
		elseif (item.catid == 20) then
			set_gradient_primary_color(0, item.colorid)
		elseif (item.catid == 21) then
			set_gradient_secondary_color(0, item.colorid)
		elseif (item.catid == 22) then
			set_joint_force_color(0, item.colorid)
		elseif (item.catid == 24) then
			local rgb = get_color_info(item.colorid)
			storeVanillaTimer.uiColor = { rgb.r, rgb.g, rgb.b, 1 }
		elseif (item.catid == 27) then
			set_separate_trail_color(0, 1, item.colorid)
		elseif (item.catid == 28) then
			set_separate_trail_color(0, 0, item.colorid)
		elseif (item.catid == 29) then
			set_separate_trail_color(0, 3, item.colorid)
		elseif (item.catid == 30) then
			set_separate_trail_color(0, 2, item.colorid)
		elseif (item.catid == 34) then
			local rgb = get_color_info(item.colorid)
			storeVanillaPlayerScore.uiColor = { rgb.r, rgb.g, rgb.b, 1 }
			storeVanillaPlayerName.uiColor = { rgb.r, rgb.g, rgb.b, 1 }
		elseif (item.catid == 41) then
			-- Add a draw3d hook for grip manually; quicker than adding a full UIElement3D object
			add_hook("draw3d", "storevanillapreview", function()
					set_grip_info(0, 11, 1)
					local rHand = get_body_info(0, BODYPARTS.R_HAND)
					local rgb = get_color_info(item.colorid)
					set_color(rgb.r, rgb.g, rgb.b, 0.7)
					draw_sphere(rHand.pos.x - 0.12, rHand.pos.y - 0.07, rHand.pos.z + 0.02, 0.08)
				end)
		elseif (item.catid == 43) then
			UIElement:runCmd("em " .. (item.colorid > 99 and ("%" .. item.colorid) or (item.colorid > 9 and ("^" .. item.colorid) or ("^0" .. item.colorid))) .. item.itemname)
		elseif (item.catid == 44) then
			set_blood_color(0, item.colorid)
			set_joint_relax_color(0, item.colorid)
			set_torso_color(0, item.colorid)
			set_ghost_color(0, item.colorid)
			set_ground_impact_color(0, item.colorid)
			draw_ground_impact(0)
			set_gradient_primary_color(0, item.colorid)
			set_gradient_secondary_color(0, item.colorid)
			set_joint_force_color(0, item.colorid)
			local rgb = get_color_info(item.colorid)
			storeVanillaTimer.uiColor = { rgb.r, rgb.g, rgb.b, 1 }
			set_separate_trail_color(0, 1, item.colorid)
			set_separate_trail_color(0, 0, item.colorid)
			set_separate_trail_color(0, 3, item.colorid)
			set_separate_trail_color(0, 2, item.colorid)
			storeVanillaPlayerScore.uiColor = { rgb.r, rgb.g, rgb.b, 1 }
			storeVanillaPlayerName.uiColor = { rgb.r, rgb.g, rgb.b, 1 }
			add_hook("draw3d", "storevanillapreview", function()
					set_grip_info(0, 11, 1)
					local rHand = get_body_info(0, BODYPARTS.R_HAND)
					set_color(rgb.r, rgb.g, rgb.b, 0.7)
					draw_sphere(rHand.pos.x + 0.12, rHand.pos.y + 0.07, rHand.pos.z + 0.02, 0.08)
				end)
			UIElement:runCmd("em " .. (item.colorid > 99 and ("%" .. item.colorid) or (item.colorid > 9 and ("^" .. item.colorid) or ("^0" .. item.colorid))) .. item.itemname)
		elseif (item.catid == 72) then
			Torishop:previewHairVanilla(item)
		elseif (item.catid == 73) then
			set_hair_color(0, item.colorid)
		elseif (item.catid == 78) then
			local file = Files:new("../data/models/store/" .. item.itemid .. ".obj")
			download_server_file(item.itemid, 1)
			if (not file.data) then
				TBMenu:showDataError("No model found, starting download")
				add_hook("pre_draw", "storevanillapreview", function()
						local downloads = get_downloads()
						if (#downloads > 0 and not parentItem) then
							for i,v in pairs(downloads) do
								if (v:find(item.itemid)) then
									return
								end
							end
						else
							TBMenu:showDataError("Downloads complete")
						end
						remove_hook("pre_draw", "storevanillapreview")
						Torishop:doItemPreviewVanilla(parentItem or item)
					end)
				return
			end
			file:close()
			local modelInfo = cloneTable(TB_STORE_MODELS[item.itemid])
			if (modelInfo.upgradeable) then
				modelInfo = modelInfo[1]
			end
			if (modelInfo.bodyid < 21) then
				UIElement:runCmd("obj load data/models/store/" .. item.itemid .. ".obj 0 " .. modelInfo.bodyid .. " " .. modelInfo.colorid .. " " .. modelInfo.alpha .. " 1 " .. (modelInfo.dynamic and 1 or 0) .. " " .. (modelInfo.partless and 1 or 0))
			elseif (modelInfo.bodyid < 41) then
				UIElement:runCmd("objjoint load data/models/store/" .. item.itemid .. ".obj 0 " .. (modelInfo.bodyid - 21) .. " " .. modelInfo.colorid .. " " .. modelInfo.alpha .. " 1 " .. (modelInfo.dynamic and 1 or 0) .. " " .. (modelInfo.partless and 1 or 0))
			else
				UIElement:runCmd("objfloor load data/models/store/" .. item.itemid .. ".obj 0 " .. (modelInfo.bodyid - 41))
			end
		elseif (item.catid == 80) then
			for i,v in pairs(item.contents) do
				if (TB_STORE_MODELS[v]) then
					Torishop:doItemPreviewVanilla({ catid = 78, itemid = v }, item)
				end
			end
		end
	end
	
	function Torishop:preparePreviewVanilla(item)
		STORE_VANILLA_PREVIEW = true
		set_option("uke", 0)
		set_option("hud", 0)
		chat_input_deactivate()
		open_replay("system/torishop.rpl", 0)
		load_player(0, TB_MENU_PLAYER_INFO.username)
		add_hook("draw2d", "storevanillapreview", function()
				if (get_world_state().match_frame >= 15) then
					add_hook("leave_game", "storevanillapreview", function()
							tbMenuHide.btnUp()
						end)
					edit_game()
					dismember_joint(0, 3)
					run_frames(12)
					add_hook("draw2d", "storevanillapreview", function()
							if (get_world_state().match_frame >= 20) then
								remove_hook("draw2d", "storevanillapreview")
								for i = 0, 19 do
									local jointstate = math.floor(math.random(1, 4))
									set_joint_state(0, i, jointstate)
								end
							end
						end)
				end
			end)
	end
	
	function Torishop:spawnMinSectionView(catid)
		if (storeMinSectionViewHolder) then
			storeMinSectionViewHolder:kill()
			storeMinSectionViewHolder = nil
		end
		storeMinSectionViewHolder = UIElement:new({
			parent = storeVanillaHolder,
			pos = { 10, 10 },
			size = { 450, WIN_H - 100 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local elementHeight = 40
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(storeMinSectionViewHolder, elementHeight + 10, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)
		
		local previewableSectionIds = {
			44, 22, 2, 20, 21, 1, 5, 11, 12, 24, 27, 28, 29, 30, 34, 41, 43, 73, 78, 72, 80
		}
		local previewableSections = {}
		for i,v in pairs(previewableSectionIds) do
			if (v == catid) then
				displaysectionid = i
			end
			table.insert(previewableSections, { text = TB_STORE_SECTIONS[v].name, action = function() Torishop:spawnMinSectionView(v) end })
		end
		local sectionsDropdownBG = UIElement:new({
			parent = topBar,
			pos = { 5, 5 },
			size = { topBar.size.w - 10, topBar.size.h - 10 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local sectionsDropdown = UIElement:new({
			parent = sectionsDropdownBG,
			pos = { 1, 1 },
			size = { sectionsDropdownBG.size.w - 2, sectionsDropdownBG.size.h - 2 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		TBMenu:spawnDropdown(sectionsDropdown, previewableSections, 25, nil, previewableSections[displaysectionid], nil, nil, 0.7)
		
		local resetButton = UIElement:new({
			parent = botBar,
			pos = { 10, 5 },
			size = { botBar.size.w - 20, botBar.size.h - 10 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		resetButton:addAdaptedText(false, TB_MENU_LOCALIZED.SHADERSRESETTODEFAULT)
		resetButton:addMouseHandlers(nil, function()
				load_player(0, TB_MENU_PLAYER_INFO.username)
			end)
		
		local listElements = Torishop:showSectionItemsMin(listingHolder, elementHeight, catid)
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
	end
	
	function Torishop:spawnVanillaControls(item)
		storeVanillaHolder = UIElement:new({
			parent = tbMenuMain,
			pos = { 0, -WIN_H * 2 },
			size = { WIN_W, WIN_H }
		})
		storeVanillaPlayerScore = UIElement:new({
			parent = storeVanillaHolder,
			pos = { WIN_W / 2, 3 },
			size = { WIN_W / 2 - 10, 60 },
			uiColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		storeVanillaPlayerScore:addAdaptedText(true, math.random(0, 10000000) .. "", nil, nil, FONTS.BIG, RIGHT, nil, nil, 0)
		storeVanillaPlayerName = UIElement:new({
			parent = storeVanillaHolder,
			pos = { WIN_W / 2, storeVanillaPlayerScore.size.h + storeVanillaPlayerScore.shift.y - 10 },
			size = { WIN_W / 2 - 10, 30 },
			uiColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		storeVanillaPlayerName:addAdaptedText(true, TB_MENU_PLAYER_INFO.username, nil, nil, nil, RIGHT, nil, nil)
		storeVanillaTimer = UIElement:new({
			parent = storeVanillaHolder,
			pos = { WIN_W / 2, 43 },
			size = { 40, 40 },
			uiColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		storeVanillaTimer:addCustomDisplay(true, function()
				set_color(unpack(storeVanillaTimer.uiColor))
				draw_disk(storeVanillaTimer.pos.x, storeVanillaTimer.pos.y, storeVanillaTimer.size.w - 20, storeVanillaTimer.size.w, 15, 1, 180, -150, 0)
			end)
		
		Torishop:spawnMinSectionView(item.catid)
	end
	
	function Torishop:itemPreviewVanilla(item)
		if (not STORE_VANILLA_PREVIEW) then
			Torishop:preparePreviewVanilla(item)
			Torishop:spawnVanillaControls(item)
		else
			Torishop:spawnMinSectionView(item.catid)
		end
		tbMenuHide.btnUp()
		for i,v in pairs(tbMenuHide.child) do
			v:hide()
		end
		close_menu()
		
		Torishop:doItemPreviewVanilla(item)
	end
	
	function Torishop:showStoreItemInfo(item, noReload, updateOverride)
		STORE_DOWNLOADS_COMPLETE = noReload and true or false
		tbStoreItemInfoHolder:kill(true)
		tbStoreItemInfoHolder.updated = os.clock()
		TBMenu:addBottomBloodSmudge(tbStoreItemInfoHolder, 3)
		local saleBackground
		if (item.on_sale == 1) then
			saleBackground = UIElement:new({
				parent = tbStoreItemInfoHolder,
				pos = { 0, 0 },
				size = { tbStoreItemInfoHolder.size.w, tbStoreItemInfoHolder.size.w },
				bgImage = "../textures/store/sale.tga"
			})
		end
		local itemName = UIElement:new({
			parent = tbStoreItemInfoHolder,
			pos = { 10, 5 },
			size = { tbStoreItemInfoHolder.size.w - 20, 44 },
			uiShadowColor = TB_MENU_DEFAULT_BG_COLOR
		})
		itemName:addAdaptedText(true, item.itemname, nil, nil, FONTS.BIG, nil, nil, nil, nil, item.on_sale == 1 and 2)
		
		local scale = tbStoreItemInfoHolder.size.w - 50
		if (scale > tbStoreItemInfoHolder.size.h / 3) then
			scale = tbStoreItemInfoHolder.size.h / 3
		end
		local itemPreviewAdvanced = UIElement:new({
			parent = tbStoreItemInfoHolder,
			pos = { 0, 54 },
			size = { tbStoreItemInfoHolder.size.w, scale },
			interactive = true
		})
		Torishop:showStoreAdvancedItemPreview(itemPreviewAdvanced, item, noReload, updateOverride, nil, level)
		
		local itemInfo = UIElement:new({
			parent = tbStoreItemInfoHolder,
			pos = { 10, itemPreviewAdvanced.shift.y + itemPreviewAdvanced.size.h + 5 },
			size = { tbStoreItemInfoHolder.size.w - 20, tbStoreItemInfoHolder.size.h - 10 - (itemPreviewAdvanced.shift.y + itemPreviewAdvanced.size.h) }
		})			
		local itemDesc = UIElement:new({
			parent = itemInfo,
			pos = { 0, 0 },
			size = { itemInfo.size.w, item.on_sale == 1 and itemInfo.size.h / 5 or itemInfo.size.h / 3 }
		})
		if (item.qi <= TB_MENU_PLAYER_INFO.data.qi) then
			itemDesc.size.h = itemDesc.size.h + itemInfo.size.h / 8
		end
		itemDesc:addAdaptedText(true, item.description, nil, nil, 4, CENTERMID, nil, 0.6)
		
		if (item.on_sale == 1) then
			local discountInfo = UIElement:new({
				parent = itemInfo,
				pos = { 10, itemDesc.size.h },
				size = { itemInfo.size.w - 20, itemInfo.size.h / 6 },
				uiColor = TB_MENU_DEFAULT_ORANGE
			})
			local percentageTC, percentageST = item.now_tc_price == 0 and 0 or 1 - item.now_tc_price / item.price, item.now_usd_price == 0 and 0 or 1 - item.now_usd_price / item.price_usd
			local percentage = percentageTC > percentageST and math.floor(percentageTC * 100) or math.floor(percentageST * 100)
			if (percentage > 0) then
				discountInfo:addAdaptedText(true, TB_MENU_LOCALIZED.STOREDISCOUNTCHEAPER1 .. " " .. percentage .. "%" .. (TB_MENU_LOCALIZED.STOREDISCOUNTCHEAPER2:len() > 0 and (" " .. TB_MENU_LOCALIZED.STOREDISCOUNTCHEAPER2) or "") .. "!", nil, nil, FONTS.BIG)
			else
				saleBackground:kill()
				discountInfo:kill()
			end
		end
		
		if (TB_MENU_PLAYER_INFO.username == '') then
			return
		end
		
		local buttonH = itemInfo.size.h / 7 > 40 and 40 or itemInfo.size.h / 7
		local iconScale = buttonH > 32 and 32 or buttonH
		local buttonPos = -buttonH * 1.1
		if (item.qi > TB_MENU_PLAYER_INFO.data.qi) then
			local getMoreQi = UIElement:new({
				parent = itemInfo,
				pos = { 0, buttonPos },
				size = { itemInfo.size.w, buttonH },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			local getMoreQiText = UIElement:new({
				parent = getMoreQi,
				pos = { 10, 0 },
				size = { getMoreQi.size.w - 20 - getMoreQi.size.h, getMoreQi.size.h }
			})
			local getMoreQiIcon = UIElement:new({
				parent = getMoreQi,
				pos = { -getMoreQi.size.h + (getMoreQi.size.h - iconScale) / 2 - 5, (getMoreQi.size.h - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = "../textures/store/qi_tiny.tga"
			})
			getMoreQiText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREGETMORE .. " Qi", nil, nil, nil, LEFTMID)
			getMoreQi:addMouseHandlers(nil, function()
				Torishop:showStoreSection(tbMenuCurrentSection, 4, 3)
			end)
			buttonPos = buttonPos - buttonH * 1.2
		end
		if (item.now_usd_price > 0) then
			local buyWithSt = UIElement:new({
				parent = itemInfo,
				pos = { 0, buttonPos },
				size = { itemInfo.size.w, buttonH },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				inactiveColor = { 0.6, 0.6, 0.6, 1 }
			})
			buttonPos = buttonPos - buttonH * 1.2
			local buyWithStText = UIElement:new({
				parent = buyWithSt,
				pos = { 10, 0 },
				size = { buyWithSt.size.w - 20 - buyWithSt.size.h, buyWithSt.size.h }
			})
			if (not in_array(item.catid, CATEGORIES_ACCOUNT)) then
				local buyWithStIcon = UIElement:new({
					parent = buyWithSt,
					pos = { -buyWithSt.size.h + (buyWithSt.size.h - iconScale) / 2 - 5, (buyWithSt.size.h - iconScale) / 2 },
					size = { iconScale, iconScale },
					bgImage = "../textures/store/shiaitoken.tga"
				})
				if (item.now_usd_price > TB_MENU_PLAYER_INFO.data.st) then
					buyWithStText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREGETMORE .. " ST", nil, nil, nil, LEFTMID)
					buyWithSt:addMouseHandlers(nil, function()
							Torishop:showStoreSection(tbMenuCurrentSection, 4, 2)
						end)
				else
					buyWithStText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREBUYFOR .. " " .. PlayerInfo:currencyFormat(item.now_usd_price) .. " ST", nil, nil, nil, LEFTMID)
					buyWithSt:addMouseHandlers(nil, function()
							TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. PlayerInfo:currencyFormat(item.now_usd_price) .. " " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS .. "?\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 ..  " " .. PlayerInfo:currencyFormat(TB_MENU_PLAYER_INFO.data.st - item.now_usd_price) .. " ST " .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT2, function()
									Torishop:buyItem(item, MODE_ST)
								end)
						end)
				end
			else
				local buyWithStIcon = UIElement:new({
					parent = buyWithSt,
					pos = { -buyWithSt.size.h + (buyWithSt.size.h - iconScale) / 2 - 5, (buyWithSt.size.h - iconScale) / 2 },
					size = { iconScale, iconScale },
					bgImage = is_steam() and "../textures/menu/logos/steam.tga" or "../textures/menu/logos/paypal.tga"
				})
				buyWithStText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREBUYFOR .. " $" .. PlayerInfo:currencyFormat(item.now_usd_price), nil, nil, nil, LEFTMID)
				buyWithSt:addMouseHandlers(nil, is_steam() and function()
						UIElement:runCmd("steam purchase " .. item.itemid)
					end or function()
						open_url("http://forum.toribash.com/tori_shop.php?action=process&item=" .. item.itemid)
					end)
			end
		end
		if (item.now_tc_price > 0 and item.qi <= TB_MENU_PLAYER_INFO.data.qi) then
			local buyWithTc = UIElement:new({
				parent = itemInfo,
				pos = { 0, buttonPos },
				size = { itemInfo.size.w, buttonH },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			buttonPos = buttonPos - buttonH * 1.2
			local buyWithTcText = UIElement:new({
				parent = buyWithTc,
				pos = { 10, 0 },
				size = { buyWithTc.size.w - 20 - buyWithTc.size.h, buyWithTc.size.h }
			})
			local buyWithTcIcon = UIElement:new({
				parent = buyWithTc,
				pos = { -buyWithTc.size.h + (buyWithTc.size.h - iconScale) / 2 - 5, (buyWithTc.size.h - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = "../textures/store/toricredit.tga"
			})
			if (item.now_tc_price > TB_MENU_PLAYER_INFO.data.tc) then
				buyWithTcText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREGETMORE .. " TC", nil, nil, nil, LEFTMID)
				buyWithTc:addMouseHandlers(nil, function()
					Torishop:showStoreSection(tbMenuCurrentSection, 4, 1)
				end)
			else
				buyWithTcText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREBUYFOR .. " " .. PlayerInfo:currencyFormat(item.now_tc_price) .. " TC", nil, nil, nil, LEFTMID)
				buyWithTc:addMouseHandlers(nil, function()
					TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. PlayerInfo:currencyFormat(item.now_tc_price) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. "?\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 .. " " .. PlayerInfo:currencyFormat(TB_MENU_PLAYER_INFO.data.tc - item.now_tc_price) .. " TC " .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT2, function()
							Torishop:buyItem(item, MODE_TC)
						end)
				end)
			end
		end
		
		if (in_array(item.catid, { 1, 2, 5, 11, 11, 20, 21, 22, 24, 27, 28, 29, 30, 34, 41, 43, 44, 72, 73, 78, 80 })) then
			local itemPreview = UIElement:new({
				parent = itemInfo,
				pos = { 0, buttonPos },
				size = { itemInfo.size.w, buttonH },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			buttonPos = buttonPos - buttonH * 1.2
			itemPreview:addAdaptedText(false, TB_MENU_LOCALIZED.STOREITEMPREVIEW)
			local function initPreview()
				if (STORE_VANILLA_PREVIEW) then
					Torishop:itemPreviewVanilla(item)
					return
				end
				local overlay = UIElement:new({
					globalid = TB_MENU_MAIN_GLOBALID,
					pos = { 0, 0 },
					size = { WIN_W, WIN_H },
					bgColor = { 0, 0, 0, 0.4 },
					interactive = true
				})
				local loadingText = UIElement:new({
					parent = overlay,
					pos = { WIN_W / 3, WIN_H / 2 - 70 },
					size = { WIN_W / 3, 140 },
					bgColor = TB_MENU_DEFAULT_BG_COLOR
				})
				loadingText:addAdaptedText(false, TB_MENU_LOCALIZED.STORESTEAMPURCHASELOADING)
				local cnt = 0
				overlay:addCustomDisplay(false, function()
						if (cnt > 2) then
							overlay:kill()
							Torishop:itemPreviewVanilla(item)
						end
						cnt = cnt + 1
					end)
			end
			itemPreview:addMouseHandlers(nil, function()
					if (get_world_state().game_type == 1) then
						TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREVANILLAENTERMP, function() initPreview() end)
						return
					end
					initPreview()
				end)
		end
		
		if (item.qi > TB_MENU_PLAYER_INFO.data.qi) then
			local qiReq = UIElement:new({
				parent = itemInfo,
				pos = { -itemInfo.size.w - 10, buttonPos },
				size = { itemInfo.size.w + 20, buttonH },
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			local qiReqText = UIElement:new({
				parent = qiReq,
				pos = { 10, qiReq.size.h / 10 },
				size = { qiReq.size.w - 20, qiReq.size.h * 0.8 }
			})
			qiReqText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREREQUIRES .. " " .. (item.qi - TB_MENU_PLAYER_INFO.data.qi) .. " " .. TB_MENU_LOCALIZED.STOREREQUIRESQI, nil, nil, 4)
		end
	end
	
	function Torishop:addIconToDownloadQueue(item, path, element)
		table.insert(STORE_ICONS_DOWNLOAD_QUEUE, { path = path, itemid = item.itemid, element = element })
		STORE_ICONS_DOWNLOADING = STORE_ICONS_DOWNLOADING or false
		add_hook("draw2d", "storeicondownloads", function()
				if (STORE_ICONS_DOWNLOADING) then
					if (os.clock() - 0.5 < STORE_ICONS_DOWNLOADING) then
						return
					end
					local downloads = get_downloads()
					local searchPath = STORE_ICONS_DOWNLOAD_QUEUE[#STORE_ICONS_DOWNLOAD_QUEUE].path
					searchPath = searchPath:gsub("^%.%./", "../data/")
					for i,v in pairs(downloads) do
						if (v:find(searchPath)) then
							return
						end
					end
					if (not STORE_ICONS_DOWNLOAD_QUEUE[#STORE_ICONS_DOWNLOAD_QUEUE].element.destroyed) then
						STORE_ICONS_DOWNLOAD_QUEUE[#STORE_ICONS_DOWNLOAD_QUEUE].element:updateImage(Torishop:getItemIcon(STORE_ICONS_DOWNLOAD_QUEUE[#STORE_ICONS_DOWNLOAD_QUEUE].itemid))
					end
					table.remove(STORE_ICONS_DOWNLOAD_QUEUE)
					STORE_ICONS_DOWNLOADING = false
					STORE_DOWNLOADS_COMPLETE = true
					return
				end
				if (STORE_DOWNLOADS_COMPLETE and not MODEL_DOWNLOAD_ACTIVE) then
					if (#STORE_ICONS_DOWNLOAD_QUEUE == 0) then
						remove_hooks("storeicondownloads")
						return
					end
					download_server_file("get_icon&itemid=" .. STORE_ICONS_DOWNLOAD_QUEUE[#STORE_ICONS_DOWNLOAD_QUEUE].itemid, 0)
					STORE_DOWNLOADS_COMPLETE = false
					Request:new("storeicondownload", function()
							local response = get_network_response()
							if (response:len() == 0 or response:find("^ERROR")) then
								table.remove(STORE_ICONS_DOWNLOAD_QUEUE)
								STORE_DOWNLOADS_COMPLETE = true
							else
								STORE_ICONS_DOWNLOADING = os.clock()
							end
						end, function()
							table.remove(STORE_ICONS_DOWNLOAD_QUEUE)
							STORE_DOWNLOADS_COMPLETE = true
						end)
				end
			end)
	end
	
	function Torishop:showStoreListItem(listingHolder, listElements, elementHeight, item, stItem, locked)
		local itemHolder = UIElement:new({
			parent = listingHolder,
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, itemHolder)
		local itemSection = UIElement:new({
			parent = itemHolder,
			pos = { 10, 2.5 },
			size = { itemHolder.size.w - 10, itemHolder.size.h - 5 },
			interactive = true,
			bgColor = item.on_sale == 1 and TB_MENU_DEFAULT_ORANGE or TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = item.on_sale == 1 and TB_MENU_DEFAULT_DARKER_ORANGE or TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			uiColor = item.on_sale == 1 and TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local itemIconPath = Torishop:getItemIcon(item.itemid)
		local itemIconFilePath = itemIconPath:gsub("^%.%./", "../data/")
		local itemIconFile = Files:new(itemIconFilePath)
		local downloadingIcon = false
		if (not itemIconFile.data) then
			downloadingIcon = true
		else
			itemIconFile:close()
		end
		local itemIcon = UIElement:new({
			parent = itemSection,
			pos = { 10, (itemSection.size.h - 50) / 2 },
			size = { 50, 50 },
			bgImage = itemIconPath
		})
		if (downloadingIcon) then
			Torishop:addIconToDownloadQueue(item, itemIconPath, itemIcon)
		end
		local iconOverlay = nil
		if (locked) then
			iconOverlay = UIElement:new({
				parent = itemIcon,
				pos = { 0, 0 },
				size = { itemIcon.size.w, itemIcon.size.h },
				bgColor = itemSection.animateColor
			})
			iconOverlay:addCustomDisplay(true, function()
					set_color(iconOverlay.bgColor[1], iconOverlay.bgColor[2], iconOverlay.bgColor[3], 0.6)
					draw_quad(iconOverlay.pos.x, iconOverlay.pos.y, iconOverlay.size.w, iconOverlay.size.h)
				end)
		end
		itemSection:addMouseHandlers(function()
				if (iconOverlay) then
					iconOverlay.bgColor = cloneTable(itemSection.pressedColor)
				end
			end, function()
				Torishop:showStoreItemInfo(item)
				storeListingScrollBar.listReload()
				if (iconOverlay) then
					iconOverlay.bgColor = itemSection.animateColor
				end
			end)
		local itemName = nil
		if (locked) then
			itemName = UIElement:new({
				parent = itemSection,
				pos = { 70, 5 },
				size = { (itemSection.size.w - 80) / 3 * 2, itemSection.size.h - 25 }
			})
			local itemLocked = UIElement:new({
				parent = itemSection,
				pos = { 70, itemSection.size.h - 22 },
				size = { itemName.size.w, 15 }
			})
			local itemLockedIcon = UIElement:new({
				parent = itemSection,
				pos = { 0, 0 },
				size = { 32, 32 },
				bgImage = "../textures/menu/general/buttons/locked.tga"
			})
			
			if (item.qi > TB_MENU_PLAYER_INFO.data.qi and item.locked == 0) then
				itemLocked:addAdaptedText(true, TB_MENU_LOCALIZED.STOREREQUIRES .. " " .. item.qi .. " Qi", nil, nil, 4, LEFTMID)
			else
				itemLocked:addAdaptedText(true, TB_MENU_LOCALIZED.STOREITEMUNAVAILABLE, nil, nil, 4, LEFTMID)
			end
		else 
			itemName = UIElement:new({
				parent = itemSection,
				pos = { 70, 10 },
				size = { (itemSection.size.w - 80) / 3 * 2, itemSection.size.h - 20 }
			})
		end
		itemName:addAdaptedText(true, item.shortname, nil, nil, FONTS.BIG, LEFTMID, 0.55, nil, 0.4)
		local itemPrice = UIElement:new({
			parent = itemSection,
			pos = { itemName.shift.x + itemName.size.w, 0 },
			size = { itemSection.size.w - (itemName.shift.x + itemName.size.w) - 10, itemSection.size.h }
		})
		local pricesString, hasTCPrice = '', false
		if (item.now_tc_price > 0) then
			pricesString = PlayerInfo:currencyFormat(item.now_tc_price) .. " TC"
			hasTCPrice = true
		end
		if (item.now_usd_price > 0) then
			pricesString = (hasTCPrice and (pricesString .. '\n') or '') .. (not stItem and "$" or '') .. PlayerInfo:currencyFormat(item.now_usd_price) .. (stItem and " ST" or "")
		end
		itemPrice:addAdaptedText(true, pricesString, nil, nil, nil, RIGHTMID)
	end
	
	function Torishop:showSectionItemsMin(viewElement, height, catid)
		local sectionItems = {}
		for i,v in pairs(TB_STORE_DATA) do
			if (type(i) == "number") then
				if (v.catid == catid and (v.now_tc_price > 0 or v.now_usd_price > 0) and v.hidden == 0) then
					table.insert(sectionItems, v)
				end
			end
		end
		sectionItems = UIElement:qsort(sectionItems, {'qi', 'now_usd_price', 'now_tc_price', 'itemname'}, false, true)
		local listElements = {}
		for i, item in pairs(sectionItems) do
			local itemHolder = UIElement:new({
				parent = viewElement,
				pos = { 0, #listElements * height },
				size = { viewElement.size.w, height }
			})
			table.insert(listElements, itemHolder)
			local itemButton = UIElement:new({
				parent = itemHolder,
				pos = { 10, 2 },
				size = { itemHolder.size.w - 10, itemHolder.size.h - 4 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			local shiftX = 0
			if (not in_array(item.catid, { 72, 78, 80 })) then
				local rgb = get_color_info(item.colorid)
				local itemColor = UIElement:new({
					parent = itemButton,
					pos = { 13, 5 },
					size = { itemButton.size.h - 10, itemButton.size.h - 10 },
					shapeType = ROUNDED,
					rounded = 5,
					bgColor = { rgb.r, rgb.g, rgb.b, 1 }
				})
				shiftX = itemButton.size.h
			end
			local itemName = UIElement:new({
				parent = itemButton,
				pos = { 15 + shiftX, 2 },
				size = { itemButton.size.w - 70 - shiftX, itemButton.size.h - 4 }
			})
			itemButton:addMouseHandlers(nil, function()
					Torishop:doItemPreviewVanilla(item)
				end)
			itemName:addAdaptedText(true, item.itemname, nil, nil, nil, LEFTMID)
			if (item.qi > TB_MENU_PLAYER_INFO.data.qi and (item.now_usd_price > TB_MENU_PLAYER_INFO.data.st or item.now_usd_price == 0)) then
				local itemLockedIcon = UIElement:new({
					parent = itemButton,
					pos = { -itemButton.size.h - 15, 0 },
					size = { itemButton.size.h, itemButton.size.h },
					bgImage = "../textures/menu/general/buttons/locked.tga"
				})
			end
		end
		return listElements
	end
	
	function Torishop:showSectionItems(viewElement, catid, searchString, itemsList)
		viewElement:kill(true)
		
		local searchString = searchString or ""
		searchString = searchString:lower()
		
		local sectionItems = {}
		if (itemsList) then
			sectionItems = itemsList
		else
			for i,v in pairs(TB_STORE_DATA) do
				if (type(i) == "number") then
					if (v.catid == catid and (v.now_tc_price > 0 or v.now_usd_price > 0) and not (v.locked == 1 and v.hidden == 1)) then
						table.insert(sectionItems, v)
					end
				end
			end
		end
		sectionItems = UIElement:qsort(sectionItems, { 'on_sale', 'now_tc_price', 'now_usd_price', 'itemname' }, false, true)
		sectionItemsDesc = UIElement:qsort(sectionItems, { 'on_sale', 'now_tc_price', 'now_usd_price', 'itemname' }, true, true)
		sectionItemsQi = UIElement:qsort(sectionItems, { 'on_sale', 'qi', 'now_tc_price', 'now_usd_price', 'itemname' }, false, true)
		
		local elementHeight = 64
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, elementHeight, 48, 20, TB_MENU_DEFAULT_BG_COLOR)
		
		local sectionTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 10 },
			size = { topBar.size.w - 20, topBar.size.h - 20 }
		})
		sectionTitle:addAdaptedText(true, TB_MENU_LOCALIZED.STOREVIEWING .. " " .. TB_STORE_SECTIONS[catid].name, nil, nil, FONTS.BIG)
		
		local stItems = not in_array(sectionItems[1].catid, CATEGORIES_ACCOUNT)
		local listElements = {}
		local cnt = 0
		local itemShown = false
		for i, item in pairs(sectionItemsDesc) do
			if (((item.qi <= TB_MENU_PLAYER_INFO.data.qi and (item.now_tc_price > 0 and item.now_tc_price <= TB_MENU_PLAYER_INFO.data.tc)) or (stItems and item.now_usd_price > 0 and item.now_usd_price <= TB_MENU_PLAYER_INFO.data.st)) and (item.locked == 0 and item.hidden == 0)) then
				if (cnt == 0) then
					local separatorAffordable = UIElement:new({
						parent = listingHolder,
						pos = { 0, #listElements * elementHeight },
						size = { listingHolder.size.w, elementHeight }
					})
					table.insert(listElements, separatorAffordable)
					local separatorAffordableText = UIElement:new({
						parent = separatorAffordable,
						pos = { 10, -elementHeight / 7 * 5 - 2.5 },
						size = { separatorAffordable.size.w - 10, elementHeight / 7 * 5 },
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR
					})
					separatorAffordableText:addAdaptedText(false, TB_MENU_LOCALIZED.STOREAVAILABLEITEMS)
					if (not itemShown) then
						itemShown = true
						Torishop:showStoreItemInfo(item)
					end
				end
				Torishop:showStoreListItem(listingHolder, listElements, elementHeight, item, stItems)
				cnt = cnt + 1
			end
		end
		
		cnt = 0
		if (stItems) then
			for i, item in pairs(sectionItems) do
				if (((item.qi <= TB_MENU_PLAYER_INFO.data.qi and item.now_tc_price > TB_MENU_PLAYER_INFO.data.tc and (item.now_usd_price == 0 or item.now_usd_price > TB_MENU_PLAYER_INFO.data.st)) or ((item.qi > TB_MENU_PLAYER_INFO.data.qi or item.now_tc_price == 0) and item.now_usd_price > TB_MENU_PLAYER_INFO.data.st)) and (item.locked == 0 and item.hidden == 0)) then
					if (cnt == 0) then
						local separatorUnavailable = UIElement:new({
							parent = listingHolder,
							pos = { 0, #listElements * elementHeight },
							size = { listingHolder.size.w, elementHeight }
						})
						table.insert(listElements, separatorUnavailable)
						local separatorUnavailableText = UIElement:new({
							parent = separatorUnavailable,
							pos = { 10, -elementHeight / 7 * 5 - 2.5 },
							size = { separatorUnavailable.size.w - 10, elementHeight / 7 * 5 },
							bgColor = TB_MENU_DEFAULT_DARKER_COLOR
						})
						separatorUnavailableText:addAdaptedText(false, TB_MENU_LOCALIZED.STOREEXPENSIVEITEMS)
						if (not itemShown) then
							itemShown = true
							Torishop:showStoreItemInfo(item)
						end
					end
					Torishop:showStoreListItem(listingHolder, listElements, elementHeight, item, stItems)
					cnt = cnt + 1
				end
			end
		else
			for i, item in pairs(sectionItems) do
				if (item.now_tc_price == 0 and item.now_usd_price > 0 and (item.locked == 0 and item.hidden == 0)) then
					if (cnt == 0) then
						local separatorUnavailable = UIElement:new({
							parent = listingHolder,
							pos = { 0, #listElements * elementHeight },
							size = { listingHolder.size.w, elementHeight }
						})
						table.insert(listElements, separatorUnavailable)
						local separatorUnavailableText = UIElement:new({
							parent = separatorUnavailable,
							pos = { 10, -elementHeight / 7 * 5 - 2.5 },
							size = { separatorUnavailable.size.w - 10, elementHeight / 7 * 5 },
							bgColor = TB_MENU_DEFAULT_DARKER_COLOR
						})
						separatorUnavailableText:addAdaptedText(false, TB_MENU_LOCALIZED.STOREUSDITEMS)
						if (not itemShown) then
							itemShown = true
							Torishop:showStoreItemInfo(item)
						end
					end
					Torishop:showStoreListItem(listingHolder, listElements, elementHeight, item, stItems)
					cnt = cnt + 1
				end
			end
		end
		
		cnt = 0
		for i, item in pairs(sectionItemsQi) do
			if ((item.qi > TB_MENU_PLAYER_INFO.data.qi and item.now_usd_price == 0 and item.now_tc_price > 0 and item.hidden == 0 and item.locked == 0) or (searchString ~= "" and (item.hidden == 1 or item.locked == 1))) then
				if (cnt == 0) then
					local separatorLocked = UIElement:new({
						parent = listingHolder,
						pos = { 0, #listElements * elementHeight },
						size = { listingHolder.size.w, elementHeight }
					})
					table.insert(listElements, separatorLocked)
					local separatorLockedText = UIElement:new({
						parent = separatorLocked,
						pos = { 10, -elementHeight / 7 * 5 - 2.5 },
						size = { separatorLocked.size.w - 10, elementHeight / 7 * 5 },
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR
					})
					separatorLockedText:addAdaptedText(false, TB_MENU_LOCALIZED.STORELOCKEDITEMS)
					if (not itemShown) then
						itemShown = true
						Torishop:showStoreItemInfo(item)
					end
				end
				Torishop:showStoreListItem(listingHolder, listElements, elementHeight, item, stItems, true)
				cnt = cnt + 1
			end
		end
		
		for i,v in pairs(listElements) do
			v:hide()
		end
		
		storeListingScrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		storeListingScrollBar:makeScrollBar(listingHolder, listElements, toReload)
		
		TBMenu:addBottomBloodSmudge(botBar, 2)
	end
	
	function Torishop:getItemMainSection(item)
		if (in_array(item.catid, CATEGORIES_COLORS)) then
			return 1
		--elseif (in_array(item.catid, CATEGORIES_TEXTURES)) then
			--return 2
		elseif (in_array(item.catid, CATEGORIES_ADVANCED)) then
			return 3
		elseif (in_array(item.catid, CATEGORIES_ACCOUNT)) then
			return 4
		end
	end
	
	function Torishop:getItemSectionid(sectionList, item)
		for i,v in pairs(sectionList) do
			if (v == item.catid) then
				return i
			end
		end
		return 1
	end
	
	function Torishop:getSearchCategory(category)
		local catid = category.catid
		if (in_array(catid, CATEGORIES_COLORS)) then
			return 0
		end
		if (in_array(catid, CATEGORIES_HIDDEN)) then
			return false
		end
		return catid
	end
	
	function Torishop:getSearchSections(searchString, isSale)
		local searchString = searchString:lower()
		local searchResults = { list = {}, items = {} }
		if (searchString:len() < 3) then
			return searchResults
		end
		
		for i,v in pairs(TB_STORE_DATA) do
			if (type(i) == "number") then
				if ((v.itemname:lower()):find(searchString) and not (v.itemname:lower()):find("test") and (not isSale and true or v.on_sale == 1)) then
					local catid = Torishop:getSearchCategory(v)
					if (catid) then
						if (not searchResults.list[catid]) then
							searchResults.list[catid] = catid
							searchResults.items[catid] = {}
						end
						table.insert(searchResults.items[catid], v)
					end
				end
			end
		end
		return searchResults
	end
	
	function Torishop:showSearchResults(viewElement, searchResults, searchString)
		viewElement:kill(true)
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Torishop:getSectionNavButtons(viewElement, 0), true)
		Torishop:showSearchBar(viewElement, searchString)
		
		local isEmpty = true
		for i,v in pairs(searchResults.list) do
			isEmpty = false
			break
		end
		if (isEmpty) then
			local emptyMessage = UIElement:new({
				parent = viewElement,
				pos = { 5, 0 },
				size = { viewElement.size.w - 10, viewElement.size.h },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			emptyMessage:addAdaptedText(false, searchString:len() >= 3 and TB_MENU_LOCALIZED.STORESEARCHNOITEMS or TB_MENU_LOCALIZED.STORESEARCHSTRINGSHORT, nil, nil, FONTS.BIG)
			TBMenu:addBottomBloodSmudge(emptyMessage, 1)
			return
		end
		local sectionsHolder = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w / 4 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		
		local elementHeight = 40
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(sectionsHolder, 64, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)
		
		local searchTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 10 },
			size = { topBar.size.w - 20, topBar.size.h - 20 }
		})
		searchTitle:addAdaptedText(true, TB_MENU_LOCALIZED.SEARCHRESULTS1 .. "'" .. searchString .. "' " .. TB_MENU_LOCALIZED.SEARCHRESULTS2, nil, nil, FONTS.BIG)
		TBMenu:addBottomBloodSmudge(botBar, 1)
		
		tbStoreItemInfoHolder = UIElement:new({
			parent = viewElement,
			pos = { -viewElement.size.w / 4 + 5, 0 },
			size = { viewElement.size.w / 4 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local sectionItemsView = UIElement:new({
			parent = viewElement,
			pos = { sectionsHolder.shift.x + sectionsHolder.size.w + 10, 0 },
			size = { viewElement.size.w / 2 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		
		local listElements = {}
		local first = true
		for i,v in pairs(searchResults.list) do
			if (first) then
				Torishop:showSectionItems(sectionItemsView, searchResults.list[i], searchString, searchResults.items[i])
				first = false
			end
			local section = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			table.insert(listElements, section)
			section:addAdaptedText(nil, TB_STORE_SECTIONS[v].name)
			section:addMouseHandlers(nil, function()
					Torishop:showSectionItems(sectionItemsView, searchResults.list[i], searchString, searchResults.items[i])
				end)
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
	end
	
	function Torishop:showStoreSection(viewElement, section, sectionid, itemid)
		local itemInfo = itemid and Torishop:getItemInfo(itemid)
		local section = itemid and Torishop:getItemMainSection(itemInfo) or section
		local sectionInfo = Torishop:getStoreSection(section)
		local sectionid = itemid and Torishop:getItemSectionid(sectionInfo.list, itemInfo) or sectionid
		
		TB_LAST_STORE_SECTION = section
		viewElement:kill(true)
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Torishop:getSectionNavButtons(viewElement, section), true, true, TB_LAST_STORE_SECTION)
		
		local sectionsHolder = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w / 4 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		
		local elementHeight = 40
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(sectionsHolder, 64, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)
		
		local sectionTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 10 },
			size = { topBar.size.w - 20, topBar.size.h - 20 }
		})
		sectionTitle:addAdaptedText(true, sectionInfo.name, nil, nil, FONTS.BIG)
		TBMenu:addBottomBloodSmudge(botBar, 1)
		
		tbStoreItemInfoHolder = UIElement:new({
			parent = viewElement,
			pos = { -viewElement.size.w / 4 + 5, 0 },
			size = { viewElement.size.w / 4 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local sectionItemsView = UIElement:new({
			parent = viewElement,
			pos = { sectionsHolder.shift.x + sectionsHolder.size.w + 10, 0 },
			size = { viewElement.size.w / 2 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Torishop:showSectionItems(sectionItemsView, sectionInfo.list[sectionid or 1])
		if (itemid) then
			Torishop:showStoreItemInfo(itemInfo)
		end
		
		local listElements = {}
		local selectedSection = nil
		for i,v in pairs(sectionInfo.list) do
			local section = UIElement:new({
				parent = listingHolder,
				pos = { 5, #listElements * elementHeight },
				size = { listingHolder.size.w - 5, elementHeight },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			table.insert(listElements, section)
			-- We don't have all icons for now
			--[[local sectionIcon = UIElement:new({
				parent = section,
				pos = { 4, 2 },
				size = { section.size.h - 4, section.size.h - 4 },
				bgImage = "torishop/gui/ss/colors" .. i .. ".tga"
			})]]
			local sectionText = UIElement:new({
				parent = section,
				pos = { 10, 0 },
				size = { section.size.w - 20, section.size.h }
			})
			sectionText:addAdaptedText(true, TB_STORE_SECTIONS[v].name, nil, nil, nil, LEFTMID)
			section:addMouseHandlers(nil, function()
					selectedSection.bgColor = TB_MENU_DEFAULT_BG_COLOR
					selectedSection = section
					section.bgColor = TB_MENU_DEFAULT_DARKER_COLOR
					Torishop:showSectionItems(sectionItemsView, v)
				end)
		end
		selectedSection = listElements[1]
		selectedSection.bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
		
		Torishop:showSearchBar(viewElement)
	end
	
	function Torishop:showSearchBar(viewElement, searchString)
		local searchHolder = UIElement:new({
			parent = viewElement,
			pos = { 200, viewElement.size.h },
			size = { viewElement.size.w - 400, 120 },
			interactive = true
		})
		local searchBar = UIElement:new({
			parent = searchHolder,
			pos = { 0, 45 },
			size = { searchHolder.size.w, 40 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5
		})
		local searchTitle = UIElement:new({
			parent = searchBar,
			pos = { 10, 5 },
			size = { 100, searchBar.size.h - 10 }
		})
		searchTitle:addAdaptedText(true, TB_MENU_LOCALIZED.WORDSEARCH .. ":", nil, nil, nil, RIGHTMID)
		local searchBox = TBMenu:spawnTextField(searchBar, searchTitle.size.w + searchTitle.shift.x * 2, 5, searchBar.size.w - searchTitle.size.w - searchTitle.shift.x * 2 - 5, searchBar.size.h - 10, searchString, nil, 4, 0.7, UICOLORWHITE, TB_MENU_LOCALIZED.STORESEARCHHINT)
		searchBox:addEnterAction(function()
				if (searchBox.textfieldstr[1]:gsub("%s", "") == '') then
					Torishop:showStoreSection(viewElement, TB_LAST_STORE_SECTION)
				else
					Torishop:showSearchResults(viewElement, Torishop:getSearchSections(searchBox.textfieldstr[1]), searchBox.textfieldstr[1])
				end
			end)
	end
	
	function Torishop:showDailySaleItem(item)
		local overlay = TBMenu:spawnWindowOverlay()
		overlay:addMouseHandlers(nil, function() overlay:kill() end)
		local saleItemHolder = UIElement:new({
			parent = overlay,
			pos = { WIN_W / 10, 100 },
			size = { WIN_W * 0.8, WIN_H - 200 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5,
			interactive = true
		})
		
		local exitButtonScale = saleItemHolder.size.h > saleItemHolder.size.w and saleItemHolder.size.w or saleItemHolder.size.h
		local saleExit = UIElement:new({
			parent = saleItemHolder,
			pos = { -exitButtonScale / 13, exitButtonScale / 13 - exitButtonScale / 15 },
			size = { exitButtonScale / 15, exitButtonScale / 15 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = saleItemHolder.shapeType,
			rounded = saleItemHolder.rounded * 0.8
		})
		saleExit:addMouseHandlers(nil, function() overlay:kill() end)
		local saleExitIcon = UIElement:new({
			parent = saleExit,
			pos = { 5, 5 },
			size = { saleExit.size.w - 10, saleExit.size.h - 10 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		
		local advancedPreviewHolder = UIElement:new({
			parent = saleItemHolder,
			pos = { 10, saleItemHolder.size.h / 10 + 20 },
			size = { saleItemHolder.size.w / 5 * 2 - 20, saleItemHolder.size.h * 0.7 - 40 }
		})
		local scale = advancedPreviewHolder.size.w - 50
		if (scale > advancedPreviewHolder.size.h) then
			scale = advancedPreviewHolder.size.h - 20
		end
		local advancedPreview = UIElement:new({
			parent = advancedPreviewHolder,
			pos = { 0, (advancedPreviewHolder.size.h - scale) / 2 },
			size = { advancedPreviewHolder.size.w, scale },
			interactive = true
		})
		local advancedPreviewShown = true
		if (not Torishop:showStoreAdvancedItemPreview(advancedPreview, item, false, updateOverride, function() overlay:kill() Torishop:showDailySaleItem(item) end)) then
			advancedPreviewShown = false
			advancedPreview:kill(true)
		end
		
		local itemName = UIElement:new({
			parent = saleItemHolder,
			pos = { saleItemHolder.size.w / 8, 0 },
			size = { saleItemHolder.size.w / 8 * 6, saleItemHolder.size.h / 10 }
		})
		itemName:addAdaptedText(true, item.itemname, nil, nil, FONTS.BIG)
		
		local itemDescHolder = UIElement:new({
			parent = saleItemHolder,
			pos = { advancedPreviewShown and saleItemHolder.size.w / 5 * 2 + 10 or 20, saleItemHolder.size.h / 10 },
			size = { advancedPreviewShown and saleItemHolder.size.w / 5 * 3 - 20 or saleItemHolder.size.w / 5 * 2, advancedPreviewShown and saleItemHolder.size.h * 0.4 or saleItemHolder.size.h * 0.7 }
		})
		local itemDescTitle = UIElement:new({
			parent = itemDescHolder,
			pos = { 0, 0 },
			size = { itemDescHolder.size.w, advancedPreviewShown and itemDescHolder.size.h / 4 or saleItemHolder.size.h * 0.9 / 4 }
		})
		itemDescTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPLAYSDESC, nil, nil, FONTS.BIG, nil, 0.75)
		local itemDesc = UIElement:new({
			parent = itemDescHolder,
			pos = { 0, itemDescTitle.size.h },
			size = { itemDescHolder.size.w, itemDescHolder.size.h - itemDescTitle.size.h }
		})
		itemDesc:addAdaptedText(true, item.description, nil, nil, 4, LEFTMID)
		
		local itemPriceHolder = UIElement:new({
			parent = saleItemHolder,
			pos = { advancedPreviewShown and itemDescHolder.shift.x or saleItemHolder.size.w / 5 * 2 + 10, advancedPreviewShown and itemDescHolder.shift.y + itemDescHolder.size.h or saleItemHolder.size.h / 10 },
			size = { advancedPreviewShown and itemDescHolder.size.w or saleItemHolder.size.w / 5 * 3 - 20, advancedPreviewShown and saleItemHolder.size.h * 0.5 or saleItemHolder.size.h * 0.9 }
		})
		local itemPriceTitle = UIElement:new({
			parent = itemPriceHolder,
			pos = { 0, 0 },
			size = { itemPriceHolder.size.w, itemPriceHolder.size.h / 4 }
		})
		itemPriceTitle:addAdaptedText(true, TB_MENU_LOCALIZED.STOREDISCOUNTEDPRICE, nil, nil, FONTS.BIG, nil, 0.75)
		local pricesNum = (item.now_tc_price > 0 and item.now_usd_price > 0) and (item.qi <= TB_MENU_PLAYER_INFO.data.qi and 2 or 1) or 1
		local tScale1, tScale2 = { FONTS.BIG, 1 }, {FONTS.MEDIUM, 1 }
		if (item.now_tc_price > 0 and item.qi <= TB_MENU_PLAYER_INFO.data.qi) then
			local tcPriceHolder = UIElement:new({
				parent = itemPriceHolder,
				pos = { 10, itemPriceHolder.size.h / 4 },
				size = { itemPriceHolder.size.w / pricesNum - 20, itemPriceHolder.size.h / 3 }
			})
			local tcOldPrice = UIElement:new({
				parent = tcPriceHolder,
				pos = { 0, 0 },
				size = { tcPriceHolder.size.w, tcPriceHolder.size.h / 7 * 3 }
			})
			tcOldPrice:addAdaptedText(true, item.price .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS, nil, nil, FONTS.MEDIUM, CENTERBOT)
			local tcNowPrice = UIElement:new({
				parent = tcPriceHolder,
				pos = { 0, tcPriceHolder.size.h / 7 * 3 },
				size = { tcPriceHolder.size.w, tcPriceHolder.size.h / 7 * 4 },
				uiColor = TB_MENU_DEFAULT_YELLOW
			})
			tcNowPrice:addAdaptedText(true, PlayerInfo:currencyFormat(item.now_tc_price) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS, nil, nil, FONTS.BIG, CENTER)
			if (tcNowPrice.textFont == tcOldPrice.textFont and tcOldPrice.textScale >= tcNowPrice.textScale) then
				tcOldPrice:addAdaptedText(true, item.price .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS, nil, nil, tcNowPrice.textFont, CENTERBOT, tcNowPrice.textScale - 0.2)
			end
			tScale1 = { tcNowPrice.textFont, tcNowPrice.textScale }
			tScale2 = { tcOldPrice.textFont, tcOldPrice.textScale }
			local len = get_string_length(tcOldPrice.dispstr[1], tcOldPrice.textFont) * tcOldPrice.textScale
			local fontMod = tcOldPrice.textFont == 2 and 2.4 or (tcOldPrice.textFont == 0 and 5.6 or (tcOldPrice.textFont == 9 and 10 or 2.4))
			local tcOldPriceStrike = UIElement:new({
				parent = tcOldPrice,
				pos = { (tcOldPrice.size.w - len) / 2 - 5, -fontMod * 5 * tcOldPrice.textScale },
				size = { len + 10, 2 },
				bgColor = UICOLORWHITE
			})
			local purchaseButton = UIElement:new({
				parent = itemPriceHolder,
				pos = { tcPriceHolder.shift.x, -saleItemHolder.size.h * 0.45 / 3 - 10 },
				size = { tcPriceHolder.size.w, saleItemHolder.size.h * 0.45 / 3 - 10 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 3
			})
			local iconScale = purchaseButton.size.h * 0.8 > 64 and 64 or purchaseButton.size.h * 0.8
			local purchaseText = UIElement:new({
				parent = purchaseButton,
				pos = { 10, 5 },
				size = { purchaseButton.size.w - iconScale - 30, purchaseButton.size.h - 10 }
			})
			local purchaseIcon = UIElement:new({
				parent = purchaseButton,
				pos = { -iconScale - 10, (purchaseButton.size.h - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = "../textures/store/toricredit.tga"
			})
			if (item.now_tc_price > TB_MENU_PLAYER_INFO.data.tc) then
				purchaseText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREGETMORE .. " TC")
				purchaseButton:addMouseHandlers(nil, function()
					overlay:kill()
					Torishop:showStoreSection(tbMenuCurrentSection, 4, 1)
				end)
			else
				purchaseText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREBUYWITH .. " TC")
				purchaseButton:addMouseHandlers(nil, function()
						advancedPreview.child[1]:hide()
						TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. PlayerInfo:currencyFormat(item.now_tc_price) .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. "?\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 .. " " .. PlayerInfo:currencyFormat(TB_MENU_PLAYER_INFO.data.tc - item.now_tc_price) .. " TC " .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT2, function() advancedPreview:show()
							Torishop:buyItem(item, MODE_TC)
						end, function() advancedPreview:show() end)
					end)
			end
		end
		if (item.now_usd_price > 0) then
			local stPriceHolder = UIElement:new({
				parent = itemPriceHolder,
				pos = { pricesNum == 2 and itemPriceHolder.size.w / 2 + 10 or 10, itemPriceHolder.size.h / 4 },
				size = { itemPriceHolder.size.w / pricesNum - 20, itemPriceHolder.size.h / 3 }
			})
			local stOldPrice = UIElement:new({
				parent = stPriceHolder,
				pos = { 0, 0 },
				size = { stPriceHolder.size.w, stPriceHolder.size.h / 7 * 3 }
			})
			local stItem = not in_array(item.catid, CATEGORIES_ACCOUNT)
			stOldPrice:addAdaptedText(true, (stItem and "" or "$") .. item.price_usd .. (stItem and (" " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS) or ""), nil, nil, tScale2[1], CENTERBOT, tScale2[2])
			local stNowPrice = UIElement:new({
				parent = stPriceHolder,
				pos = { 0, stPriceHolder.size.h / 7 * 3 },
				size = { stPriceHolder.size.w, stPriceHolder.size.h / 7 * 4 },
				uiColor = TB_MENU_DEFAULT_YELLOW
			})
			stNowPrice:addAdaptedText(true, (stItem and "" or "$") .. item.now_usd_price .. (stItem and (" " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS) or ""), nil, nil, tScale1[1], CENTER, tScale1[2])
			local len = get_string_length(stOldPrice.dispstr[1], stOldPrice.textFont) * stOldPrice.textScale
			local fontMod = stOldPrice.textFont == 2 and 2.4 or (stOldPrice.textFont == 0 and 5.6 or (stOldPrice.textFont == 9 and 10 or 2.4))
			local stOldPriceStrike = UIElement:new({
				parent = stOldPrice,
				pos = { (stOldPrice.size.w - len) / 2 - 5, -fontMod * 5 * stOldPrice.textScale },
				size = { len + 10, 2 },
				bgColor = UICOLORWHITE
			})
			local purchaseButton = UIElement:new({
				parent = itemPriceHolder,
				pos = { stPriceHolder.shift.x, -saleItemHolder.size.h * 0.45 / 3 - 10 },
				size = { stPriceHolder.size.w, saleItemHolder.size.h * 0.45 / 3 - 10 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 3
			})
			local iconScale = purchaseButton.size.h * 0.8 > 64 and 64 or purchaseButton.size.h * 0.8
			local purchaseText = UIElement:new({
				parent = purchaseButton,
				pos = { 10, 5 },
				size = { purchaseButton.size.w - iconScale - 30, purchaseButton.size.h - 10 }
			})
			local purchaseIcon = UIElement:new({
				parent = purchaseButton,
				pos = { -iconScale - 10, (purchaseButton.size.h - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = stItem and "../textures/store/shiaitoken.tga" or (is_steam() and "../textures/menu/logos/steam.tga" or "../textures/menu/logos/paypal.tga")
			})
			if (stItem and item.now_usd_price > TB_MENU_PLAYER_INFO.data.st) then
				purchaseText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREGETMORE .. " ST")
				purchaseButton:addMouseHandlers(nil, function()
					overlay:kill()
					Torishop:showStoreSection(tbMenuCurrentSection, 4, 2)
				end)
			elseif (not stItem) then
				purchaseText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREBUYWITH .. " " .. (is_steam() and "Steam" or "PayPal"))
				purchaseButton:addMouseHandlers(nil, function()
						advancedPreview.child[1]:hide()
						TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " $" .. PlayerInfo:currencyFormat(item.now_usd_price) .. "?", function() if (is_steam()) then UIElement:runCmd("steam purchase " .. item.itemid) else open_url("http://forum.toribash.com/tori_shop.php?action=process&item=" .. item.itemid) end advancedPreview:show() end, function() advancedPreview:show() end)
					end)
			else
				purchaseText:addAdaptedText(true, TB_MENU_LOCALIZED.STOREBUYWITH .. " st")
				purchaseButton:addMouseHandlers(nil, function()
						advancedPreview.child[1]:hide()
						TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. PlayerInfo:currencyFormat(item.now_usd_price) .. " " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS .. "?\n" .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT1 .. " " .. PlayerInfo:currencyFormat(TB_MENU_PLAYER_INFO.data.st - item.now_usd_price) .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEYOUWILLHAVELEFT2, function() advancedPreview:show()
							Torishop:buyItem(item, MODE_ST)
						end, function() advancedPreview:show() end)
					end)
			end
		end
		local viewStoreButton = UIElement:new({
			parent = saleItemHolder,
			pos = { 20, -saleItemHolder.size.h * 0.45 / 3 - 10 },
			size = { saleItemHolder.size.w / 5 * 2 - 40, saleItemHolder.size.h * 0.45 / 3 - 10 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
			shapeType = ROUNDED,
			rounded = 3
		})
		TBMenu:showTextWithImage(viewStoreButton, TB_MENU_LOCALIZED.STOREVIEWIN1 .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREVIEWIN2, FONTS.MEDIUM, viewStoreButton.size.h * 0.7 > 64 and 64 or viewStoreButton.size.h * 0.7, Torishop:getItemIcon(item))
		viewStoreButton:addMouseHandlers(nil, function()
				overlay:kill()
				Torishop:showStoreSection(tbMenuCurrentSection, nil, nil, item.itemid)
			end)
	end

	function Torishop:showMain(viewElement)
		viewElement:kill(true)
		if (not TB_STORE_DATA.ready) then
			local shopLoading = UIElement:new({
				parent = viewElement,
				pos = { 5, 0 },
				size = { viewElement.size.w - 10, viewElement.size.h },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			TBMenu:addBottomBloodSmudge(shopLoading, 1)
			local shopLoadingText = UIElement:new({
				parent = shopLoading,
				pos = { shopLoading.size.w / 6, shopLoading.size.h / 3 },
				size = { shopLoading.size.w / 3 * 2, shopLoading.size.h / 3 }
			})
			TBMenu:displayLoadingMark(shopLoadingText, TB_MENU_LOCALIZED.STORELOADING)
			shopLoading:addCustomDisplay(false, function()
					if (TB_STORE_DATA.ready) then
						Torishop:showMain(viewElement)
					end
				end)
			return
		end
		
		local saleItems = Torishop:getSaleItems()
		local saleFeatured, saleColor = nil, {}
		for i,v in pairs(saleItems) do
			if (v.sale_promotion == 1) then
				saleFeatured = v
			elseif (in_array(v.catid, CATEGORIES_COLORS)) then
				table.insert(saleColor, v)
			end
		end
		saleColor = UIElement:qsort(saleColor, 'catid') --Do this to prevent incorrect name detection when first item is a pack
		local saleColorInfo = #saleColor > 0 and { colorid = saleColor[1].colorid, colorname = saleColor[1].itemname:gsub(" " .. TB_STORE_SECTIONS[saleColor[1].catid].name:sub(1, -8) .. ".*$", "") } or false
		
		--[[local featuredPromos = {
			{
				image = "../textures/menu/promo/store/hairseast.tga",
				ratio = 0.5,
				title = "New 3D hairs are now available!",
				action = function() Torishop:showStoreSection(tbMenuCurrentSection, nil, nil, 3305) end
			},
		}
		--featuredPromoId = math.random(1, 3);
		featuredPromoId = 1]]
		
		local storeButtons = {
			--[[featured = {
				title = featuredPromos[featuredPromoId].title,
				subtitle = featuredPromos[featuredPromoId].subtitle,
				image = featuredPromos[featuredPromoId].image,
				ratio = featuredPromos[featuredPromoId].ratio,
				action = featuredPromos[featuredPromoId].action
			},]]
			featured = {
				title = TB_MENU_LOCALIZED.STOREGOTOINVENTORY,
				subtitle = TB_MENU_LOCALIZED.STOREINVENTORYDESC,
				image = "../textures/menu/inventory.tga",
				ratio = 0.435,
				action = function()
						if (TB_STORE_DATA.ready) then
							Torishop:prepareInventory(tbMenuCurrentSection)
						else
							TBMenu:showDataError(TB_MENU_LOCALIZED.STOREDATALOADERROR)
						end
					end
			},
			salecolor = {
				title = saleColorInfo and (TB_MENU_LOCALIZED.STORESALE1 .. " " .. saleColorInfo.colorname .. (TB_MENU_LOCALIZED.STORESALE2:len() > 0 and (" " .. TB_MENU_LOCALIZED.STORESALE2 .. "!") or "!")) or TB_MENU_LOCALIZED.STORENOCOLORSALE,
				image = "../textures/menu/store/colorsale.tga",
				ratio = 0.5,
				action = function() if (saleColorInfo) then Torishop:showSearchResults(viewElement, Torishop:getSearchSections(saleColorInfo.colorname, true), saleColorInfo.colorname) end end
			},
			dailysale = {
				title = saleFeatured and saleFeatured.itemname or TB_MENU_LOCALIZED.STORENOSALE,
				image = "../textures/menu/store/sale.tga",
				ratio = 0.5,
				action = function() if (saleFeatured) then Torishop:showDailySaleItem(saleFeatured) end end
			},
			storecolors = {
				title = TB_MENU_LOCALIZED.STORECOLORS,
				subtitle = TB_MENU_LOCALIZED.STORECOLORSDESC,
				image = "../textures/menu/store/colors-big.tga",
				image2 = "../textures/menu/store/colors-small.tga",
				ratio = 0.75,
				ratio2 = 0.449,
				action = function() Torishop:showStoreSection(viewElement, 1) end
			},
			storeadvanced = {
				title = TB_MENU_LOCALIZED.STOREADVANCED,
				subtitle = TB_MENU_LOCALIZED.STOREADVANCEDDESC,
				image = "../textures/menu/store/advanced2-big.tga",
				image2 = "../textures/menu/store/advanced2-small.tga",
				ratio = 0.75,
				ratio2 = 0.449,
				action = function() Torishop:showStoreSection(viewElement, 3) end
			},
			storetextures = {
				title = TB_MENU_LOCALIZED.STOREFLAMEFORGE,
				subtitle = TB_MENU_LOCALIZED.STOREFLAMEFORGEDESC,
				image = "../textures/menu/store/flameforge-big.tga",
				image2 = "../textures/menu/store/flameforge-small.tga",
				ratio = 0.75,
				ratio2 = 0.449,
				action = function() close_menu() if (FLAMES_MENU_MAIN_ELEMENT == nil) then dofile("system/flames.lua") end end
			},
			storeaccount = {
				title = TB_MENU_LOCALIZED.STOREACCOUNT,
				subtitle = TB_MENU_LOCALIZED.STOREACCOUNTDESC,
				image = "../textures/menu/store/account-big.tga",
				image2 = "../textures/menu/store/account-small.tga",
				ratio = 0.75,
				ratio2 = 0.449,
				action = function() Torishop:showStoreSection(viewElement, 4) end
			},
		}
		local featuredItem = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.45 - 10, viewElement.size.h / 5 * 3 - 5 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		TBMenu:showHomeButton(featuredItem, storeButtons.featured)
		
		local weeklySale = UIElement:new({
			parent = viewElement,
			pos = { 5, viewElement.size.h / 5 * 3 + 5 },
			size = { viewElement.size.w * 0.225 - 10, viewElement.size.h / 5 * 2 - 5 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		if (saleColorInfo) then
			local colorRGB = get_color_info(saleColorInfo.colorid)
			local colorDiscountHolder = UIElement:new({
				parent = weeklySale,
				pos = { 0, 10 + weeklySale.size.h * 0.15 * storeButtons.salecolor.ratio },
				size = { weeklySale.size.w / 3, weeklySale.size.h * 0.4 * storeButtons.salecolor.ratio },
				bgColor = weeklySale.animateColor
			})
			
			-- 0, 0 for shifts in getImageDimensions is unreliable, ideally need to put actual height values
			local w, h = unpack(TBMenu:getImageDimensions(weeklySale.size.w, weeklySale.size.h, storeButtons.salecolor.ratio, 0, 0))
			local colorBackground = UIElement:new({
				parent = weeklySale,
				pos = { (weeklySale.size.w - w) / 2, 10 },
				size = { w, h },
				bgColor = { colorRGB.r, colorRGB.g, colorRGB.b, 1 }
			})
			
			TBMenu:showHomeButton(weeklySale, storeButtons.salecolor, 1, { colorDiscountHolder })
			colorDiscountHolder:reload()
			local saleDiscount = UIElement:new({
				parent = colorDiscountHolder,
				pos = { 5, 0 },
				size = { colorDiscountHolder.size.w - 10, colorDiscountHolder.size.h }
			})
			local percentageTC, percentageST = saleColor[1].now_tc_price == 0 and 0 or 1 - saleColor[1].now_tc_price / saleColor[1].price, saleColor[1].now_usd_price == 0 and 0 or 1 - saleColor[1].now_usd_price / saleColor[1].price_usd
			local percentage = percentageTC > percentageST and math.floor(percentageTC * 100) or math.floor(percentageST * 100)
			saleDiscount:addAdaptedText(true, "-" .. percentage .. "%")
		else
			local w, h = unpack(TBMenu:getImageDimensions(weeklySale.size.w, weeklySale.size.h, storeButtons.salecolor.ratio, 0, 0))
			local colorBackground = UIElement:new({
				parent = weeklySale,
				pos = { (weeklySale.size.w - w) / 2, 10 },
				size = { w, h },
				bgColor = { 1, 1, 1, 1 }
			})
			TBMenu:showHomeButton(weeklySale, storeButtons.salecolor, 1)
		end
		
		local dailySale = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w * 0.225 + 5, viewElement.size.h / 5 * 3 + 5 },
			size = { viewElement.size.w * 0.225 - 10, viewElement.size.h / 5 * 2 - 5 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		if (saleFeatured) then
			local dailyDiscountHolder = UIElement:new({
				parent = dailySale,
				pos = { 0, 10 + dailySale.size.h * 0.15 * storeButtons.dailysale.ratio },
				size = { dailySale.size.w / 3, dailySale.size.h * 0.4 * storeButtons.dailysale.ratio },
				bgColor = dailySale.animateColor
			})
			TBMenu:showHomeButton(dailySale, storeButtons.dailysale, 2, { dailyDiscountHolder })
			dailyDiscountHolder:reload()
			local dailyDiscount = UIElement:new({
				parent = dailyDiscountHolder,
				pos = { 5, 0 },
				size = { dailyDiscountHolder.size.w - 10, dailyDiscountHolder.size.h }
			})
			local percentageTC, percentageST = saleFeatured.now_tc_price == 0 and 0 or 1 - saleFeatured.now_tc_price / saleFeatured.price, saleFeatured.now_usd_price == 0 and 0 or 1 - saleFeatured.now_usd_price / saleFeatured.price_usd
			local percentage = percentageTC > percentageST and math.floor(percentageTC * 100) or math.floor(percentageST * 100)
			dailyDiscount:addAdaptedText(true, "-" .. percentage .. "%")
			local saleItemIconHolder = UIElement:new({
				parent = dailySale,
				pos = { -10 - (dailySale.size.w - 20) * 0.55, dailySale.size.h * 0.3 * storeButtons.dailysale.ratio },
				size = { (dailySale.size.w - 20) * 0.3, (dailySale.size.w - 20) * 0.3 }
			})
			local iconScale = saleItemIconHolder.size.w > 64 and 64 or saleItemIconHolder.size.w
			local saleItemIcon = UIElement:new({
				parent = saleItemIconHolder,
				pos = { (saleItemIconHolder.size.w - iconScale) / 2, (saleItemIconHolder.size.h - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = Torishop:getItemIcon(saleFeatured.itemid)
			})
		else
			TBMenu:showHomeButton(dailySale, storeButtons.dailysale, 2)
		end
		
		local storeColors = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w * 0.45 + 5, 0 },
			size = { viewElement.size.w * 0.275 - 10, viewElement.size.h / 2 - 5 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		TBMenu:showHomeButton(storeColors, storeButtons.storecolors)
		
		local storeAdvanced = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w * 0.725 + 5, 0 },
			size = { viewElement.size.w * 0.275 - 10, viewElement.size.h / 2 - 5 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		TBMenu:showHomeButton(storeAdvanced, storeButtons.storeadvanced)
		
		local storeTextures = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w * 0.45 + 5, viewElement.size.h / 2 + 5 },
			size = { viewElement.size.w * 0.275 - 10, viewElement.size.h / 2 - 5 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		TBMenu:showHomeButton(storeTextures, storeButtons.storetextures, 3)
		
		local storeAccount = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w * 0.725 + 5, viewElement.size.h / 2 + 5 },
			size = { viewElement.size.w * 0.275 - 10, viewElement.size.h / 2 - 5 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		TBMenu:showHomeButton(storeAccount, storeButtons.storeaccount, 4)
	end
end
