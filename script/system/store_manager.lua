-- new store manager class

TB_INVENTORY_PAGE = TB_INVENTORY_PAGE or {}
TB_ITEM_DETAILS = TB_ITEM_DETAILS or nil

ITEM_SET = 1458
ITEM_FLAME = 936
ITEM_SHIAI_TOKEN = 2528

INVENTORY_DEACTIVATED = 1
INVENTORY_ACTIVATED = 2
INVENTORY_MARKET = 3
INVENTORY_ALL = 4
TB_INVENTORY_MODE = TB_INVENTORY_MODE or INVENTORY_DEACTIVATED

INVENTORY_DEACTIVATE = 1
INVENTORY_ACTIVATE = 2
INVENTORY_ADDSET = 3
INVENTORY_REMOVESET = 4
INVENTORY_UNPACK = 5

INVENTORY_UPDATE = false
INVENTORY_MOUSE_POS = { x = 0, y = 0 }

do
	Torishop = {}
    Torishop.__index = Torishop
	local cln = {}
	setmetatable(cln, Torishop)
	
	function Torishop:getItems()
		local file = io.open("torishop/torishop.txt")
		if (not file) then
			return false
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
			{ "locked", numeric = true }
		}
		local TorishopData = {}
		for ln in file:lines() do
			if string.match(ln, "^PRODUCT") then
				local segments = #data_types + 1
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local item = {}
				for i,v in pairs(data_types) do
					item[v[1]] = data_stream[i + 1]
					if (v.numeric) then
						item[v[1]] = tonumber(item[v[1]])
					end
				end
				TorishopData[item.itemid] = item
			end
		end
		file:close()
		return TorishopData
	end
	
	function Torishop:getItemInfo(itemid)
		if (not TB_STORE_DATA) then
			TB_STORE_DATA = Torishop:getItems()
		end
		return TB_STORE_DATA[itemid]
	end
	
	function Torishop:getSaleItem(temp)
		local temp = temp or nil
		itemData = {
			id = 0,
		 	name = "",
			tcOld = 1,
			tc = 1,
			usdOld = 1,
			usd = 1
		}
		if (temp) then
			return itemData
		end
		local file = io.open("torishop/torishop.txt")
		if (not file) then
			return itemData
		end
		for ln in file:lines() do
			if string.match(ln, "^PRODUCT") then
				local segments = 19
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				if (data_stream[6] == "1") then
					itemData.id = data_stream[4]
					itemData.name = data_stream[5]
					itemData.tcOld = tonumber(data_stream[9])
					itemData.tc = tonumber(data_stream[7])
					itemData.usdOld = tonumber(data_stream[10])
					itemData.usd = tonumber(data_stream[8])
					return itemData
				end
			end
		end
		file:close()
	end
	
	function Torishop:getTcSales()
		local data = {}
		local file = io.open("torishop/torishop.txt")
		if (file == nil) then
			return
		end
		
		for ln in file:lines() do
			if string.match(ln, "^PRODUCT") then
				local segments = 19
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				if (data_stream[2] == '45' and data_stream[18] == '0' and data_stream[19] == '0') then
					table.insert(data, { itemid = data_stream[4], name = data_stream[5], price = tonumber(data_stream[8]) })
				end
			end
		end
		file:close()
		
		return UIElement:qsort(data, "price", false)
	end
	
	function Torishop:getInventoryRaw()
		local file = io.open("torishop/invent.txt")
		if (not file) then
			return false
		end
		local data_types = { 
			{ "inventid", numeric = true }, 
			{ "itemid", numeric = true },
			{ "description", },
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
			{ "unpackable", bool = true }
		}
		local inventory = {}
		local itemUpdated = TB_ITEM_DETAILS and 0 or 1
		for ln in file:lines() do
			if string.match(ln, "^INVITEM") then
				local segments = #data_types + 1
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local item = {}
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
			if (itemUpdated == 0) then
				TB_ITEM_DETAILS = nil
			end
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
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function Torishop:refreshInventory()
		INVENTORY_UPDATE = false
		UIElement:runCmd("download " .. TB_MENU_PLAYER_INFO.username)
		Torishop:prepareInventory(tbMenuCurrentSection)
	end
		
	function Torishop:getNavigationButtons(showBack)
		local navigation = {
			{ 
				text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN, 
				action = function() TB_MENU_INVENTORY_ISOPEN = 0 Torishop:quit() end, 
				width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONTOMAIN, FONTS.BIG) * 0.65 + 30 
			}
		}
		if (showBack) then
			local back = {
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = function() 
					TB_SET_PAGE = 1
					Torishop:showInventory(tbMenuCurrentSection)
				end,
				width = 130
			}
			table.insert(navigation, back)
		end
		return navigation
	end
	
	function Torishop:showStore(viewElement)
		viewElement:kill(true)
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
			local icon = UIElement:new({
				parent = viewElement,
				pos = { horizontalShift + ((i - 1) % itemsPerLine) * itemScale, (line - 1) * itemScale },
				size = { itemScale, itemScale },
				bgImage = "../textures/store/items/" .. v.itemid .. ".tga"
			})
			if (i % itemsPerLine == 0) then
				line = line + 1
			end
		end
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
			
			itemName:addCustomDisplay(true, function()
					itemName:uiText(item.name .. " " .. numItemsStr, nil, nil, FONTS.BIG, nil, 0.6, nil, nil, nil, nil, 0.2)
				end)
			local setName = UIElement:new({
				parent = inventoryItemView,
				pos = { 0, itemName.size.h },
				size = { inventoryItemView.size.w, 20 }
			})
			setName:addCustomDisplay(true, function()
					setName:uiText(item.setname, nil, nil, FONTS.MEDIUM, nil, 0.9, nil, nil, nil, nil, 0.05)
				end)
			local inventoryView = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, itemName.size.h + setName.size.h + 10 },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 2 - itemName.size.h - setName.size.h },
				bgColor = { 0, 0, 0, 0.1 }
			})
			local inventoryHolder = UIElement:new({
				parent = inventoryView,
				pos = { 5, 10 },
				size = { inventoryView.size.w - 10, inventoryView.size.h - 20 }
			})
			Torishop:showSetDetailsItems(inventoryHolder, item.contents)
		elseif (item.itemid == ITEM_FLAME) then
			local itemName = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, 0 },
				size = { inventoryItemView.size.w - 20, 50 }
			})
			itemName:addCustomDisplay(true, function()
					itemName:uiText(item.name, nil, nil, FONTS.BIG, nil, 0.6, nil, nil, nil, nil, 0.2)
				end)
			local flameName = UIElement:new({
				parent = inventoryItemView,
				pos = { 0, itemName.size.h },
				size = { inventoryItemView.size.w, 20 }
			})
			flameName:addCustomDisplay(true, function()
					flameName:uiText(item.flamename, nil, nil, FONTS.MEDIUM, nil, 0.9, nil, nil, nil, nil, 0.05)
				end)
			local itemInfo = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, itemName.size.h + flameName.size.h + 10 },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 2 - itemName.size.h - flameName.size.h },
				bgColor = { 0, 0, 0, 0.1 }
			})
			local itemIcon = UIElement:new({
				parent = itemInfo,
				pos = { 8, (itemInfo.size.h - 64) / 2 },
				size = { 64, 64 },
				bgImage = "../textures/store/items/" .. item.itemid .. ".tga"
			})
			local itemDescription = UIElement:new({
				parent = itemInfo,
				pos = { 80, 10 },
				size = { itemInfo.size.w - 90, itemInfo.size.h - 20 }
			})
			itemDescription:addCustomDisplay(false, function()
					itemDescription:uiText(TB_MENU_LOCALIZED.STOREFLAMEBODYPART .. " ".. item.bodypartname:lower() .. "\n" .. TB_MENU_LOCALIZED.STOREFLAMEID .. ": " .. item.flameid, nil, nil, 4, LEFTMID, 0.6)
				end)
		else
			if (item.insideset) then
				local itemName = UIElement:new({
					parent = inventoryItemView,
					pos = { 10, 0 },
					size = { inventoryItemView.size.w - 20, 50 }
				})
				itemName:addCustomDisplay(true, function()
						itemName:uiText(item.name, nil, nil, FONTS.BIG, nil, 0.6, nil, nil, nil, nil, 0.2)
					end)
				local setCaption = UIElement:new({
					parent = inventoryItemView,
					pos = { 10, 50 },
					size = { inventoryItemView.size.w - 20, 20 }
				})
				setCaption:addCustomDisplay(true, function()
						setCaption:uiText(TB_MENU_LOCALIZED.STOREITEMINSIDESET .. ": " .. item.parentset.setname, nil, nil, FONTS.MEDIUM, nil, 0.9, nil, nil, nil, nil, 0.05)
					end)
			else
				local itemName = UIElement:new({
					parent = inventoryItemView,
					pos = { 10, 0 },
					size = { inventoryItemView.size.w - 20, 70 }
				})
				itemName:addCustomDisplay(true, function()
						itemName:uiText(item.name, nil, nil, FONTS.BIG, nil, 0.6, nil, nil, nil, nil, 0.2)
					end)
			end
			local itemInfo = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, 80 },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 2 - 70 },
				bgColor = { 0, 0, 0, 0.1 }
			})
			local itemIcon = UIElement:new({
				parent = itemInfo,
				pos = { 8, (itemInfo.size.h - 64) / 2 },
				size = { 64, 64 },
				bgImage = "../textures/store/items/" .. item.itemid .. ".tga"
			})
			local itemDescription = UIElement:new({
				parent = itemInfo,
				pos = { 80, 10 },
				size = { itemInfo.size.w - 90, itemInfo.size.h - 20 }
			})
			local modelBodypartStr = ''
			if (item.bodypartname ~= '0') then
				modelBodypartStr = TB_MENU_LOCALIZED.STOREOBJITEMBODYPART .. " " .. item.bodypartname:lower() .. "\n"
			end
			local itemDescStr = item.description == '0' and '' or item.description
			if (modelBodypartStr .. itemDescStr == '') then
				itemDescStr = TB_MENU_LOCALIZED.STOREITEMNODESCRIPTION
			end
			itemDescription:addCustomDisplay(true, function()
					itemDescription:uiText(modelBodypartStr .. itemDescStr, nil, nil, 4, LEFTMID, 0.6)
				end)
		end
		local buttonYPos = -inventoryItemView.size.h / 7
		if (item.itemid ~= ITEM_SET) then
			if (item.insideset) then
			local addSetButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.3 }
			})
			--if (item.insideset) then
				addSetButton:addCustomDisplay(false, function()
						addSetButton:uiText(TB_MENU_LOCALIZED.STOREITEMGOTOSET, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)
				addSetButton:addMouseHandlers(nil, function()
						Torishop:showInventoryPage(item.parentset.contents, nil, mode, TB_MENU_LOCALIZED.STORESETITEMNAME .. ": " .. item.parentset.setname, "invid" .. item.parentset.inventid, nil, true)
					end)
			--[[elseif (item.setid == 0) then
				addSetButton:addCustomDisplay(false, function()
						addSetButton:uiText(TB_MENU_LOCALIZED.STOREITEMADDTOSET, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)
			else 
				addSetButton:addCustomDisplay(false, function()
						addSetButton:uiText(TB_MENU_LOCALIZED.STOREITEMREMOVEFROMSET, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)				
			end--]]
			buttonYPos = buttonYPos - inventoryItemView.size.h / 7
			end
		elseif (#item.contents > 0) then
			local viewSet = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.3 }
			})
			viewSet:addCustomDisplay(false, function()
					viewSet:uiText(TB_MENU_LOCALIZED.STOREVIEWSETITEMS, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
				end)
			viewSet:addMouseHandlers(nil, function()
					Torishop:showInventoryPage(item.contents, nil, mode, TB_MENU_LOCALIZED.STOREITEMSINSET .. ": " .. item.setname, "invid" .. item.inventid, nil, true)
				end, nil)
			buttonYPos = buttonYPos - inventoryItemView.size.h / 7
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
					open_dialog_box(INVENTORY_MARKETSELL, item.inventid, TB_MENU_LOCALIZED.STOREDIALOGMARKETSELL1 .. " " .. item.name .. " " .. TB_MENU_LOCALIZED.STOREDIALOGMARKETSELL2)
				end, nil)
			buttonYPos = buttonYPos - inventoryItemView.size.h / 7
		end--]]
		if (item.activateable and not item.unpackable) then
			local activateButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.3 }
			})
			if (item.active) then
				activateButton:addCustomDisplay(false, function()
						activateButton:uiText(TB_MENU_LOCALIZED.STOREITEMDEACTIVATE, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)
				activateButton:addMouseHandlers(nil, function(s, posX, posY)
						INVENTORY_UPDATE = true
						INVENTORY_MOUSE_POS = { x = posX, y = posY }
						open_dialog_box(INVENTORY_DEACTIVATE, TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGDEACTIVATE2 .. "?"), item.inventid)
					end, nil)
			else
				activateButton:addCustomDisplay(false, function()
						activateButton:uiText(TB_MENU_LOCALIZED.STOREITEMACTIVATE, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)
				activateButton:addMouseHandlers(nil, function()
						INVENTORY_UPDATE = true
						INVENTORY_MOUSE_POS = { x = posX, y = posY }
						open_dialog_box(INVENTORY_ACTIVATE, TB_MENU_LOCALIZED.STOREDIALOGACTIVATE1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 .. "?"), item.inventid)
					end, nil)
			end
		elseif (item.unpackable) then
			local unpackButton = UIElement:new({
				parent = inventoryItemView,
				pos = { 10, buttonYPos },
				size = { inventoryItemView.size.w - 20, inventoryItemView.size.h / 8 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.3 }
			})
			unpackButton:addCustomDisplay(false, function()
					unpackButton:uiText(TB_MENU_LOCALIZED.STOREITEMUNPACK, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
				end)
			unpackButton:addMouseHandlers(nil, function()
					INVENTORY_UPDATE = true
					INVENTORY_MOUSE_POS = { x = posX, y = posY }
					open_dialog_box(INVENTORY_UNPACK, TB_MENU_LOCALIZED.STOREDIALOGUNPACK1 .. " " .. item.name .. (TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGUNPACK2 .. "?") .. "\n" .. TB_MENU_LOCALIZED.STOREDIALOGUNPACKINFO, item.inventid)
				end, nil)
		end
	end
	
	function Torishop:showInventorySingleItemData(itemView, item, itemScale)
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
	end
		
	function Torishop:showInventoryPage(inventoryItems, pageShift, mode, title, pageid, itemScale, showBack)
		local showBack = showBack or false
		local itemScale = itemScale or 100
		
		local inventoryOptions = {
			{ name = TB_MENU_LOCALIZED.STOREACTIVATEDINVENTORY, val = INVENTORY_ACTIVATED },
			{ name = TB_MENU_LOCALIZED.STOREDEACTIVATEDINVENTORY, val = INVENTORY_DEACTIVATED },
			{ name = TB_MENU_LOCALIZED.STOREMARKETINVENTORY, val = INVENTORY_MARKET },
			{ name = TB_MENU_LOCALIZED.STOREINVENTORYALLITEMS, val = INVENTORY_ALL },
		}
		
		TB_INVENTORY_PAGE[pageid] = TB_INVENTORY_PAGE[pageid] or 1
		
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar(Torishop:getNavigationButtons(showBack), true)
		
		inventoryView:kill(true)
		local bottomSmudge = TBMenu:addBottomBloodSmudge(inventoryView, 1)
		
		local inventoryTitle = UIElement:new({
			parent = inventoryView,
			pos = { 25, 5 },
			size = { inventoryView.size.w - 75, 50 }
		})
		
		if (mode) then
			local inventoryModeButton = nil
			for i,v in pairs(inventoryOptions) do
				if (v.val == mode) then
					inventoryModeButton = UIElement:new({
						parent = inventoryTitle,
						pos = { inventoryTitle.size.w / 2 + get_string_length(v.name, FONTS.BIG) * 0.7 / 2, 0 },
						size = { inventoryTitle.size.h, inventoryTitle.size.h },
						interactive = true,
						shapeType = ROUNDED,
						rounded = inventoryTitle.size.h,
						bgColor = { 0, 0, 0, 0 },
						hoverColor = { 1, 1, 1, 0.2 },
						pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
						bgImage = "../textures/menu/general/buttons/arrowbotwhite.tga"
					})
					inventoryTitle:addCustomDisplay(true, function()
							inventoryTitle:uiText(v.name, nil, nil, FONTS.BIG, nil, 0.7, nil, nil, nil, nil, 0.2)
						end)
					break
				end
			end
			local filterSelection = UIElement:new({
				parent = inventoryView,
				pos = { inventoryView.size.w / 6, 0 },
				size = { inventoryView.size.w / 3 * 2, #inventoryOptions * 40 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			})
			for i, v in pairs(inventoryOptions) do
				local filterSelectionOption = UIElement:new({
					parent = filterSelection,
					pos = { 0, (i - 1) * 40 },
					size = { filterSelection.size.w, 40 },
					interactive = true,
					bgColor = { 0, 0, 0, 0 },
					hoverColor = { 0, 0, 0, 0.2 },
					pressedColor = { 1, 0, 0, 0.1 }
				})
				filterSelectionOption:addCustomDisplay(false, function()
						filterSelectionOption:uiText(v.name, nil, nil, 4, CENTERMID, 0.7)
					end)
				filterSelectionOption:addMouseHandlers(nil, function()
						Torishop:showInventory(tbMenuCurrentSection, v.val)
					end, nil)
			end
			inventoryModeButton:addMouseHandlers(nil, function()
					local filterBackground = UIElement:new({
						parent = tbMenuCurrentSection,
						pos = { 0, 0 },
						size = { tbMenuCurrentSection.size.w, tbMenuCurrentSection.size.h },
						interactive = true
					})
					filterBackground:addMouseHandlers(nil, function()
							filterSelection:hide()
							filterBackground:kill()
						end)
					filterSelection:show()
				end, nil)
			filterSelection:hide()
		else
			inventoryTitle:addCustomDisplay(true, function()
					inventoryTitle:uiText(title, nil, nil, FONTS.BIG, nil, 0.7, nil, nil, nil, nil, 0.2)
				end)
		end
		
		local inventoryPage = UIElement:new({
			parent = inventoryView,
			pos = { 50, inventoryTitle.size.h + 10 },
			size = { inventoryView.size.w - 100, inventoryView.size.h - inventoryTitle.size.h - 20 }
		})
		
		local lineItems = math.floor(inventoryPage.size.w / itemScale) 
		local invRows = math.floor((inventoryPage.size.h - 20) / itemScale)
		local maxPages = math.ceil(#inventoryItems / lineItems / invRows)
		
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
			item:addMouseHandlers(nil, function()
					Torishop:showInventoryItem(inventoryItems[i])
				end)
			Torishop:showInventorySingleItemData(item, inventoryItems[i], itemScale)
			if (i % lineItems == 0) then
				line = line + 1
			end
		end
		
		if (#inventoryItemView.child == 0) then
			Torishop:showInventoryItem(TB_ITEM_DETAILS or inventoryItems[invStartShift])
		end
	end
	
	function Torishop:prepareInventory(viewElement)
		TB_MENU_INVENTORY_ISOPEN = 1
		viewElement:kill(true)
		download_inventory()
		TB_MENU_DOWNLOAD_INACTION = true
		local inventoryWait = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local bottomSmudge = TBMenu:addBottomBloodSmudge(inventoryWait, 1)
		local startTime = os.time()
		inventoryWait:addCustomDisplay(false, function()
				inventoryWait:uiText(TB_MENU_LOCALIZED.STOREINVENTORYLOADING .. string.rep(".", (os.time() - startTime) % 4))
				for i,v in pairs(get_downloads()) do
					if (v:match("data/script/torishop/invent.txt")) then
						return
					end
				end
				Torishop:showInventory(viewElement)
			end)
	end
	
	function Torishop:showInventory(viewElement, mode)
		viewElement:kill(true)
		local mode = mode or TB_INVENTORY_MODE
		TB_INVENTORY_MODE = mode
		local playerInventory = Torishop:getInventory(mode)
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
	
	function Torishop:showTorishopMain(viewElement)
		viewElement:kill(true)
		local tcPurchaseView = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.6 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local bottomSmudge = TBMenu:addBottomBloodSmudge(tcPurchaseView, 1)
		Torishop:showTcPurchase(tcPurchaseView)
		
		
		local buttons = {
			{ title = TB_MENU_LOCALIZED.STOREGOTOSHOP, subtitle = TB_MENU_LOCALIZED.STORESHOPDESC, size = 0.4, vsize = 0.5, action = function() close_menu() open_menu(12) end, noQuit = true },
			{ title = TB_MENU_LOCALIZED.STOREGOTOINVENTORY, subtitle = TB_MENU_LOCALIZED.STOREINVENTORYDESC, size = 0.4, vsize = 0.5, action = function() if (#get_downloads() == 0) then Torishop:prepareInventory(viewElement) end end, noQuit = true },
		}
		TBMenu:showSection(buttons, tcPurchaseView.size.w)
	end
	
end