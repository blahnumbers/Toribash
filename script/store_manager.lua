-- new store manager class

do
	Torishop = {}
    Torishop.__index = Torishop
	local cln = {}
	setmetatable(cln, Torishop)
	
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
	
	function Torishop:quit()
		tbMenuCurrentSection:kill(true)
		tbMenuNavigationBar:kill()
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function Torishop:getNavigationButtons()
		return {
			{ 
				text = "To Main", 
				action = function() Torishop:quit() end, 
				width = 160 
			}
		}
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
				close_menu()
				open_menu(12)
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
				run_cmd("it")
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