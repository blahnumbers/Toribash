do
	ANNOUNCEMENT_START = 0
		
	ShopAnn = {}
    ShopAnn.__index = ShopAnn
    
    function ShopAnn:create()
		local cln = {}
		setmetatable(cln, ShopAnn)
    end
	
	function ShopAnn:showItem(data)
		displayInfo = UIElement:new({
			parent = shopAnnViewBG,
			pos = { 50, 50 },
			size = { 300, 170 },
			shapeType = ROUNDED,
			rounded = 5,
			bgColor = {0.16,0.04,0.15,0.8}
		})
		local itemIcon = UIElement:new({
			parent = displayInfo,
			pos = { 10, 10 },
			size = { 64, 64 },
			bgImage = data.icon
		})
		local itemName = UIElement:new({
			parent = displayInfo,
			pos = { 84, 10 },
			size = { displayInfo.size.w - 94, 26 }
		})
		itemName:addCustomDisplay(false, function()
				itemName:uiText(data.name, nil, nil, FONTS.BIG, LEFT, 0.5)
			end)
		local itemDesc = UIElement:new({
			parent = displayInfo,
			pos = { 84, 41 },
			size = { displayInfo.size.w - 94, 33 }
		})
		itemDesc:addCustomDisplay(false, function()
				itemDesc:uiText(data.description, nil, nil, 4, LEFT, 0.6)
			end)
		local stView = UIElement:new({
			parent = displayInfo,
			pos = { displayInfo.size.w / 6, 79 },
			size = { displayInfo.size.w / 6 * 4, 30 }
		})
		local stIcon = UIElement:new({
			parent = stView,
			pos = { 0, 0 },
			size = { stView.size.h, stView.size.h },
			bgImage = "/system/st32px.tga"
		})
		local stPrice = UIElement:new({
			parent = stView,
			pos = { stView.size.h + 10, 2 },
			size = { stView.size.w - stView.size.h - 10, stView.size.h - 4 }
		})
		stPrice:addCustomDisplay(false, function()
				stPrice:uiText(data.price .. " Shiai Tokens", nil, nil, nil, LEFT)
			end)
		local exchangeButton = UIElement:new({
			parent = displayInfo,
			pos = { 10, 115 },
			size = { displayInfo.size.w - 20, 45 },
			interactive = true,
			bgColor = {0.32,0.08,0.3,0.5},
			hoverColor = {0.32,0.08,0.3,0.9},
			pressedColor = {0.16,0.04,0.15,0.9},
			shapeType = ROUNDED,
			rounded = 3
		})
		exchangeButton:addCustomDisplay(false, function()
				exchangeButton:uiText("Exchange Shiai Tokens", nil, exchangeButton.pos.y + 10)
			end)
		exchangeButton:addMouseHandlers(nil, function()
				open_url("http://forum.toribash.com/tori_token_exchange.php")
			end, nil)
	end
	
	function ShopAnn:displayTori(viewElement)
		local itemsData = {
			{ name = "raygun", image = "system/promo/toriraygun.tga", pos = { 0.53, 0.47 }, scale = 0.17 },
			{ name = "helmet", image = "system/promo/torihelmet.tga", pos = { 0.48, 0.14 }, scale = 0.17 },
			{ name = "jetpack trail", image = "system/promo/torijettrail.tga", pos = { -1.28, 0.51 }, scale = 0.9 },
			{ name = "jetpack", image = "system/promo/torijetpack.tga", pos = { 0.34, 0.25 }, scale = 0.3 },
			{ name = "people", image = "system/promo/people.tga", pos = { 0.1, -0.26 }, scale = 0.26 }
		}
		local toriDisplayMain = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 2, viewElement.size.h / 6 },
			size = { viewElement.size.h / 2, viewElement.size.h / 2},
			bgImage = "system/promo/tori.tga"
		})
		local toriItems = {}
		for i, v in pairs(itemsData) do
			if (v.name == "people") then
				toriItems[i] = UIElement:new({ 
					parent = viewElement,
					pos = { viewElement.size.w * v.pos[1], viewElement.size.w * v.pos[2] },
					size = { viewElement.size.w * v.scale, viewElement.size.w * v.scale },
					bgImage = v.image
				})				
			else
				toriItems[i] = UIElement:new({ 
					parent = toriDisplayMain,
					pos = { toriDisplayMain.size.w * v.pos[1], toriDisplayMain.size.w * v.pos[2] },
					size = { toriDisplayMain.size.w * v.scale, toriDisplayMain.size.w * v.scale },
					bgImage = v.image
				})
			end
		end
	end
	
	function ShopAnn:showButton(data, button)
		local buttonElement = UIElement:new({
			parent = button.parent,
			pos = { button.shift.x, button.shift.y },
			size = { button.size.w, button.size.h },
			interactive = true,
			hoverColor = { 1, 1, 1, 0.3 },
			pressedColor = { 1, 1, 1, 0.5 }
		})
		local icon = UIElement:new({
			parent = buttonElement,
			pos = { (buttonElement.size.w - buttonElement.size.h) / 2, 0 },
			size = { buttonElement.size.h, buttonElement.size.h },
			bgImage = data.image
		})
		buttonElement:addMouseHandlers(nil, function() if (displayInfo) then displayInfo:kill() end ShopAnn:showItem(data.shopData) end, nil)
	end
	
	function ShopAnn:initButtons(viewElement, num)
		local num = num or 1
		local buttons = {
			{ shopData = { name = "Space Helmet", description = "Protects from the cold vacuum of space.", price = 6, icon = "torishop/icons/space helmet.tga" }, image = "system/promo/spacehelmet.tga" },
			{ shopData = { name = "U.F.O", description = "Extraterrestrials are observing your ABD Skills!", price = 6, icon = "torishop/icons/u.f.o.tga" }, image = "system/promo/ufo.tga" },
			{ shopData = { name = "Raygun", description = "Blast them suckers! Zap Zap!", price = 4, icon = "torishop/icons/raygun.tga" }, image = "system/promo/raygun.tga" },
			{ shopData = { name = "Jetpack", description = "You're going to spaaaaace!", price = 5, icon = "torishop/icons/jetpack.tga" }, image = "system/promo/jetpack.tga" },
			{ shopData = { name = "Antenna", description = "Totally not for mind control.", price = 3, icon = "torishop/icons/antenna.tga" }, image = "system/promo/antenna.tga" }
		}
		local size = viewElement.size.w / #buttons > 128 and 128 or viewElement.size.w / #buttons
		local posX = (size - 128) / 2
		local button = UIElement:new({
			parent = viewElement,
			pos = { (viewElement.size.w / #buttons) * (num - 1), -128 },
			size = { viewElement.size.w / #buttons, size }
		})
		local ANN_BUTTONPROGRESS = 0
		local ANN_BUTTONSPAWNED = false
		button:addCustomDisplay(true, function()
				if (ANN_BUTTONPROGRESS < math.pi) then
					set_color(1,1,1,1)
					draw_disk(button.pos.x + (viewElement.size.w / #buttons - size) / 2 + 64, button.pos.y + 64, 0, 45 * math.sin(ANN_BUTTONPROGRESS), 500, 1, 0, 360, 0)
					ANN_BUTTONPROGRESS = ANN_BUTTONPROGRESS + math.pi / 30
				else
					button:kill()
					if (num + 1 <= #buttons) then
						ShopAnn:initButtons(viewElement, num + 1)
					end
				end
				if (ANN_BUTTONPROGRESS >= math.pi / 2 and not ANN_BUTTONSPAWNED) then
					ShopAnn:showButton(buttons[num], button)
					ANN_BUTTONSPAWNED = true
				end
			end)
	end
	
	function ShopAnn:showMain()
		local annHeight = WIN_H / 4 * 3
		local annWidth = (annHeight + annHeight / 3 > WIN_W * 4 / 3) and WIN_W / 3 * 4 or annHeight + annHeight / 3 
		shopAnnViewBG = UIElement:new( {	
			pos = { WIN_W/2 - annWidth/2, WIN_H/2 - annHeight/2 },
			size = { annWidth, annHeight },
			bgColor = {0.16,0.04,0.15,0.95}
		} )
		local bgSpace = "/system/promo/space.tga"
		local shopAnnImage = UIElement:new( {	
			parent = shopAnnViewBG,
			pos = { 10, 10},
			size = { annWidth - 20, annHeight - 20 },
			bgImage = bgSpace
		} )		
		ShopAnn:initButtons(shopAnnImage)
		ShopAnn:displayTori(shopAnnImage)
		local quitButton = UIElement:new( {	parent = shopAnnViewBG,
											pos = { -50, 10 },
											size = { 40, 40 },
											bgColor = { 0,0,0,0.2 },
											interactive = true,
											hoverColor = { 1,1,1,0.2},
											pressedColor = { 1,0,0,0.5} } )
		quitButton:addCustomDisplay(false, function()
			local indent = 12
			local weight = 5
			set_color(1,1,1,1)
			draw_line(quitButton.pos.x + indent, quitButton.pos.y + indent, quitButton.pos.x + quitButton.size.w - indent, quitButton.pos.y + quitButton.size.h - indent, weight)
			draw_line(quitButton.pos.x + quitButton.size.w - indent, quitButton.pos.y + indent, quitButton.pos.x + indent, quitButton.pos.y + quitButton.size.h - indent, weight)
		end)
		quitButton:addMouseHandlers(function() end, function()
				shopAnnViewBG:kill()
				remove_hooks("shopAnnouncementVisual")
				SHOP_ANNOUNCEMENT_LAUNCHED = false
			end, function() end)
	end
	
	function ShopAnn:drawVisuals()
		for i, v in pairs(UIElementManager) do
			v:updatePos()
		end
		for i, v in pairs(UIVisualManager) do
			v:display()
		end
	end
end