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
	
	function Torishop:getSaleItem()
		itemData = {
			id = 0,
		 	name = "",
			tcOld = nil,
			tc = nil,
			usdOld = nil,
			usd = nil
		}
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
				for j, k in pairs(inventory) do
					if (v.setid ~= k.inventid) then
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
						break
					end
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
		tbMenuNavigationBar:kill()
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
				text = "To Main", 
				action = function() Torishop:quit() end, 
				width = 160 
			}
		}
		if (showBack) then
			local back = {
				text = "Back",
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
			
			local numItemsStr = "(EMPTY)"
			if (#item.contents == 1) then
				numItemsStr = "(1 item)"
			elseif (#item.contents > 1) then
				numItemsStr = "(" .. #item.contents .. " items)"
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
					itemDescription:uiText("Particle flame for your "..item.bodypartname .. "\nFlame Forger ID: " .. item.flameid, nil, nil, 4, LEFTMID, 0.6)
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
						setCaption:uiText("Inside Set: " .. item.parentset.setname, nil, nil, FONTS.MEDIUM, nil, 0.9, nil, nil, nil, nil, 0.05)
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
				modelBodypartStr = "Custom 3D model for " .. item.bodypartname .. "\n"
			end
			local itemDescStr = item.description == '0' and '' or item.description
			if (modelBodypartStr .. itemDescStr == '') then
				itemDescStr = "This item has no description"
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
						addSetButton:uiText("Go to set", nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)
				addSetButton:addMouseHandlers(nil, function()
						Torishop:showInventoryPage(item.parentset.contents, nil, mode, "Items inside Set: " .. item.parentset.setname, "invid" .. item.parentset.inventid, nil, true)
					end)
			--[[elseif (item.setid == 0) then
				addSetButton:addCustomDisplay(false, function()
						addSetButton:uiText("Add to set", nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)
			else 
				addSetButton:addCustomDisplay(false, function()
						addSetButton:uiText("Remove from set", nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
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
					viewSet:uiText("View set items", nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
				end)
			viewSet:addMouseHandlers(nil, function()
					Torishop:showInventoryPage(item.contents, nil, mode, "Items inside Set: " .. item.setname, "invid" .. item.inventid, nil, true)
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
					marketSellButton:uiText("Sell in market", nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
				end)
			marketSellButton:addMouseHandlers(nil, function()
					open_dialog_box(INVENTORY_MARKETSELL, item.inventid, "Are you sure want to put " .. item.name .. " in market?")
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
						activateButton:uiText("Deactivate", nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)
				activateButton:addMouseHandlers(nil, function(s, posX, posY)
						INVENTORY_UPDATE = true
						INVENTORY_MOUSE_POS = { x = posX, y = posY }
						open_dialog_box(INVENTORY_DEACTIVATE, "Are you sure want to deactivate " .. item.name .. "?", item.inventid)
					end, nil)
			else
				activateButton:addCustomDisplay(false, function()
						activateButton:uiText("Activate", nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
					end)
				activateButton:addMouseHandlers(nil, function()
						INVENTORY_UPDATE = true
						INVENTORY_MOUSE_POS = { x = posX, y = posY }
						open_dialog_box(INVENTORY_ACTIVATE, "Are you sure want to activate " .. item.name .. "?\nAny conflicting item will be deactivated.", item.inventid)
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
					unpackButton:uiText("Unpack", nil, nil, nil, nil, nil, nil, nil, nil, nil, 0.2)
				end)
			unpackButton:addMouseHandlers(nil, function()
					INVENTORY_UPDATE = true
					INVENTORY_MOUSE_POS = { x = posX, y = posY }
					open_dialog_box(INVENTORY_UNPACK, "Are you sure want to unpack " .. item.name .. "?\nUnpacked items will be put in a set\nand placed in your deactivated inventory.", item.inventid)
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
			setNumItems = " (EMPTY)"
			if (#item.contents == 1) then
				setNumItems = " (1 item)"
			elseif (#item.contents > 1) then
				setNumItems = " (" .. #item.contents .. " items)"
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
			{ name = "Activated Inventory", val = INVENTORY_ACTIVATED },
			{ name = "Deactivated Inventory", val = INVENTORY_DEACTIVATED },
			{ name = "Market Inventory", val = INVENTORY_MARKET },
			{ name = "All inventory items", val = INVENTORY_ALL },
		}
		
		TB_INVENTORY_PAGE[pageid] = TB_INVENTORY_PAGE[pageid] or 1
		
		tbMenuNavigationBar:kill()
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
						bgImage = "/system/arrowbotwhite.tga"
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
				bgImage = "/system/arrowleft.tga"
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
				bgImage = "/system/arrowright.tga"
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
				inventoryPagination:uiText("Page " .. TB_INVENTORY_PAGE[pageid] .. " of " .. maxPages)
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
		viewElement:kill(true)
		download_inventory()
		local inventoryWait = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local bottomSmudge = TBMenu:addBottomBloodSmudge(inventoryWait, 1)
		local startTime = os.time()
		inventoryWait:addCustomDisplay(false, function()
				inventoryWait:uiText("Loading data from Toriverse" .. string.rep(".", (os.time() - startTime) % 4))
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
	
	function Torishop:showTcPurchase(viewElement)
		viewElement:kill(true)
		local tcData = Torishop:getTcSales()
		local torishopView = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.7 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local bottomSmudge = TBMenu:addBottomBloodSmudge(torishopView, 1)
		
		local torishopRight = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w * 0.7 + 5, 0 },
			size = { viewElement.size.w * 0.3 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local bottomSmudge2 = TBMenu:addBottomBloodSmudge(torishopRight, 1)
		
		local torishopButton = UIElement:new({
			parent = torishopRight,
			pos = { 10, 10 },
			size = { torishopRight.size.w - 20, torishopRight.size.h / 4 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.1 },
			hoverSound = 31
		})
		torishopButton:addCustomDisplay(false, function()
				torishopButton:uiText("Open Torishop", nil, nil, FONTS.BIG, nil, 0.5)
			end)
		torishopButton:addMouseHandlers(nil, function()
				Torishop:showStore(viewElement)
			end, nil)
			
		local inventoryButton = UIElement:new({
			parent = torishopRight,
			pos = { 10, torishopRight.size.h / 4 + 20 },
			size = { torishopRight.size.w - 20, torishopRight.size.h / 4 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.1 },
			hoverSound = 31
		})
		inventoryButton:addCustomDisplay(false, function()
				inventoryButton:uiText("Open Inventory", nil, nil, FONTS.BIG, nil, 0.5)
			end)
		inventoryButton:addMouseHandlers(nil, function()
				if (#get_downloads() == 0) then
					Torishop:prepareInventory(viewElement)
				end
			end, nil)
		for i,v in pairs(tcData) do
			local tcEntry = UIElement:new({
				parent = torishopView,
				pos = { 0, (i - 1) * torishopView.size.h / #tcData },
				size = { torishopView.size.w, torishopView.size.h / #tcData },
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
							local waitStr = "Working" .. string.rep(".", (os.time() - pressTime) % 3)
							if (os.time() - pressTime >= 30) then
								waitStr = "Something went wrong"
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
				pos = { 10, (tcEntry.size.h - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = "torishop/icons/tc.tga"
			})
			local itemDetails = UIElement:new({
				parent = tcEntry,
				pos = { 40 + iconScale, 0 },
				size = { tcEntry.size.w - iconScale - 50, tcEntry.size.h }
			})
			local itemName = UIElement:new({
				parent = itemDetails,
				pos = { 0, 0 },
				size = { itemDetails.size.w, itemDetails.size.h / 2 }
			})
			itemName:addCustomDisplay(true, function()
					itemName:uiText(v.name, nil, nil, FONTS.BIG, LEFTBOT, 0.6, nil, 1)
				end)
			local itemPrice = UIElement:new({
				parent = itemDetails,
				pos = { 0, itemDetails.size.h / 2 + 5 },
				size = { itemDetails.size.w, itemDetails.size.h / 2 - 5 }
			})
			itemPrice:addCustomDisplay(true, function()
					itemPrice:uiText("$" .. v.price, nil, nil, FONTS.MEDIUM, LEFT, 0.9, nil, 0.6)
				end)
		end
	end
	
end