-- Events manager class

do
	Events = {}
	Events.__index = Events
	local cln = {}
	setmetatable(cln, Events)
	
	function Events:quit()
		tbMenuCurrentSection:kill(true)
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	-- Deprecated, we're using file data now
	-- function Events:getEvents()
	-- 	return {
	-- 		{
	-- 			accentColor = { 0.024, 0.024, 0.024, 1 },
	-- 			uiColor = { 1, 1, 1, 1 },
	-- 			buttonHoverColor = { 0.969, 0.847, 0.122, 1 },
	-- 			buttonPressedColor = { 0.996, 0.769, 0.102, 1 },
	-- 			name = "Hole in the Wall",
	-- 			image = "../textures/menu/promo/events/holeinthewall.tga",
	-- 			forumlink = "http://forum.toribash.com/showthread.php?t=623552",
	-- 			action = function() EventsOnline:playEvent("holeinthewall") end,
	-- 			actionText = "Participate",
	-- 			overlaytransparency = 0,
	-- 			data = {
	-- 				{
	-- 					title = "Description",
	-- 					imagetitle = "../textures/menu/promo/events/hitw_description.tga",
	-- 					desc = "The %115Event Squad ^01are proud to present Hole in the Wall!\nIn this event, we will be providing you with obstacles to complete, and doing so will allow you to win prizes!\nEach challenge will have a different wall, as well as a different objective to complete. Basic obstacles will be the easiest, as your main objective will be getting through the wall in any way possible. Advanced obstacles will be were things pick up a bit.. You will be given a specific objectives to complete in order to pass the challenge."
	-- 				},
	-- 				{
	-- 					title = "Rules",
	-- 					imagetitle = "../textures/menu/promo/events/hitw_rules.tga",
	-- 					desc = "- No Replay Hacking\n- No Replay Stealing\n- No Gamerule Editing"
	-- 				},
	-- 				{
	-- 					title = "How to Enter",
	-- 					imagetitle = "../textures/menu/promo/events/hitw_howtoenter.tga",
	-- 					desc = "You can participate in Hole in the Wall by pressing \"Participate\" button on bottom right, completing the challenge and submitting your replay to Toribash servers.\nAlternatively, you can make a replay in current challenge's mod in Free Play mode and attach it to your post in event thread on forums - if you just upload it to Toribash Community Replays then it won't be judged.\n^02Only one replay per player will be judged."
	-- 				},
	-- 				{
	-- 					title = "Deadline",
	-- 					imagetitle = "../textures/menu/promo/events/hitw_deadline.tga",
	-- 					desc = "We will stop accepting new entries on April 15th, 20:00 (GMT +0)"
	-- 				},
	-- 			},
	-- 			prizes = {
	-- 				imagetitle = "../textures/menu/promo/events/hitw_prizes.tga",
	-- 				{
	-- 					info = "Best Replay",
	-- 					tc = 50000,
	-- 					st = 5,
	-- 					itemids = { 2888 }
	-- 				},
	-- 				{
	-- 					info = "Complete Advanced Task",
	-- 					tc = 5000,
	-- 					st = 2
	-- 				},
	-- 				{
	-- 					info = "Complete Basic Task",
	-- 					tc = 2000,
	-- 					st = 1
	-- 				}
	-- 			}
	-- 		},
	-- 		{
	-- 			accentColor = { 0.776, 0.902, 0.969, 1 },
	-- 			uiColor = { 0.184, 0.192, 0.259, 1 },
	-- 			buttonHoverColor = { 0.121, 0.126, 0.172, 1 },
	-- 			buttonPressedColor = { 0.245, 0.258, 0.369, 1 },
	-- 			name = "GOLEM III: RETURN OF THE GOLEM",
	-- 			image = "../textures/menu/promo/events/golem.tga",
	-- 			forumlink = "http://forum.toribash.com/showthread.php?t=626177",
	-- 			overlaytransparency = 0.3,
	-- 			data = {
	-- 				{
	-- 					title = "Description",
	-- 					imagetitle = "../textures/menu/promo/events/golem_description.tga",
	-- 					desc = "GOLEM COME BACK TO SMASH TINY THING!!!\nIF TINY THING TOUCH HEAD TINY THING WIN, IF GOLEM SQUASH TINY HUMAN BODY HUMAN LOSE! SPLAT!"
	-- 				},
	-- 				{
	-- 					title = "Rules",
	-- 					imagetitle = "../textures/menu/promo/events/golem_rules.tga",
	-- 					desc = "THE SERVER WILL ALWAYS BE BROADCASTED\n3 DISMEMBERS AND YOU LOSE, GET DECAPPED AND YOU'RE OUT UNTIL THE NEXT SERVER IS MADE\nTOUCH GOLEM'S HEAD WITH HANDS OR FEET TO TRIGGER WIN\nNO SKEETS, GOLEM GETS ANGRY WHEN HUMANS PLAY DIRTY\nPERSON TO BE DECAPPED THE MOST AT THE END OF THE EVENT WILL BE BANNED FOR 1 DAY\nMOD IS E_GOLEM, GOLEM_VS_UKE.TBM AND ES_GOLEM.TBM"
	-- 				},
	-- 				{
	-- 					title = "Deadline",
	-- 					imagetitle = "../textures/menu/promo/events/golem_deadline.tga",
	-- 					desc = "4 WEEKS AFTER EVENT START\nHUMAN DO THE MATH, GOLEM NO DO SILLY THINGS"
	-- 				},
	-- 			},
	-- 			prizes = {
	-- 				imagetitle = "../textures/menu/promo/events/golem_prizes.tga",
	-- 				{
	-- 					info = "Defeat Golem",
	-- 					st = 1
	-- 				},
	-- 				{
	-- 					info = "Make Golem Laugh",
	-- 					st = 1
	-- 				},
	-- 				{
	-- 					info = "Most Wins in 1 Server",
	-- 					itemids = { 2801 }
	-- 				},
	-- 				{
	-- 					info = "Most Wins in Total",
	-- 					st = 8,
	-- 					itemids = { 71, 54 }
	-- 				},
	-- 				{
	-- 					info = "Runners Up",
	-- 					st = 5,
	-- 					itemids = { 752, 711 }
	-- 				},
	-- 			}
	-- 		}
	-- 	}
	-- end
	
	function Events:showEventDescription(viewElement, event)
		local elementHeight = 41
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 55, 60, 20, event.accentColor)
		listingView.bgColor = cloneTable(event.accentColor)
		listingView.bgColor[4] = event.overlaytransparency or 0.7
		
		local listElements = {}
		for i, info in pairs(event.data) do
			if (info.imagetitle) then
				local imageScale = elementHeight * 8 > listingHolder.size.w - 20 and (listingHolder.size.w - 20) / 8 or elementHeight
				local infoTitle = UIElement:new({
					parent = listingHolder,
					pos = { listingHolder.size.w / 2 - imageScale * 4, #listElements * elementHeight },
					size = { imageScale * 8, imageScale },
					bgImage = info.imagetitle
				})
				table.insert(listElements, infoTitle)
			elseif (info.title) then
				local infoTitle = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				infoTitle:addAdaptedText(true, info.title, nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
				table.insert(listElements, infoTitle)
			end
			if (info.desc) then
				if (i == 2) then
					DEBUGGING_ACTIVE = true
				end
				local textString = textAdapt(info.desc, 4, 0.9, listingHolder.size.w - 80)
				DEBUGGING_ACTIVE = false
				local rows = math.ceil(#textString / 2)
				for i = 1, rows do
					local infoRow = UIElement:new({
						parent = listingHolder,
						pos = { 50, #listElements * elementHeight },
						size = { listingHolder.size.w - 80, elementHeight }
					})
					infoRow:addCustomDisplay(true, function()
							infoRow:uiText(textString[i * 2 - 1], nil, nil, 4, CENTER, 0.85)
							if (textString[i * 2]) then
								infoRow:uiText(textString[i * 2], nil, nil, 4, CENTERBOT, 0.85)
							end
						end)
					table.insert(listElements, infoRow)
				end
			end
			if (i ~= #event.data) then
				local emptyRow = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				table.insert(listElements, emptyRow)
			end
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
		scrollBar.bgColor = { 0, 0, 0, 0 }
		scrollBar.hoverColor = { 0, 0, 0, 0 }
		scrollBar.pressedColor = { 0, 0, 0, 0 }
		listingScrollBG.bgColor = { 0, 0, 0, 0 }
		
		return topBar, botBar
	end
	
	function Events:showPrizeInfo(prize, listingHolder, elements, elementHeight)
		local rewardView = UIElement:new({
			parent = listingHolder,
			pos = { 10, elements * elementHeight },
			size = { listingHolder.size.w - 20, elementHeight }
		})
		local rewardBulletpoint = UIElement:new({
			parent = rewardView,
			pos = { 0, rewardView.size.h / 2 - 3 },
			size = { 6, 6 },
			bgColor = rewardView.uiColor,
			shapeType = ROUNDED,
			rounded = rewardView.size.h
		})
		local itemIcon = UIElement:new({
			parent = rewardView,
			pos = { rewardBulletpoint.size.w + 5, 2 },
			size = { rewardView.size.h - 4, rewardView.size.h - 4 },
			bgImage = prize.icon or Torishop:getItemIcon(prize.itemid)
		})
		local itemName = UIElement:new({
			parent = rewardView,
			pos = { rewardBulletpoint.size.w + itemIcon.size.w + 10, 0 },
			size = { rewardView.size.w - (rewardBulletpoint.size.w + itemIcon.size.w + 10), rewardView.size.h }
		})
		itemName:addAdaptedText(true, prize.itemname, nil, nil, nil, LEFTMID)
		return rewardView
	end
	
	function Events:showEventPrizes(viewElement, event)
		local elementHeight = 41
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 55, 60, 20, event.accentColor)
		listingView.bgColor = cloneTable(event.accentColor)
		listingView.bgColor[4] = event.overlaytransparency or 0.7
		
		local listElements = {}
		if (event.prizes.imagetitle) then
			local imageScale = elementHeight * 8 > listingHolder.size.w - 20 and (listingHolder.size.w - 20) / 8 or elementHeight
			local infoTitle = UIElement:new({
				parent = listingHolder,
				pos = { listingHolder.size.w / 2 - imageScale * 4, #listElements * elementHeight },
				size = { imageScale * 8, imageScale },
				bgImage = event.prizes.imagetitle
			})
			table.insert(listElements, infoTitle)
		else
			local infoTitle = UIElement:new({
				parent = listingHolder,
				pos = { 10, #listElements * elementHeight },
				size = { listingHolder.size.w - 20, elementHeight }
			})
			infoTitle:addAdaptedText(true, "Prizes", nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
			table.insert(listElements, infoTitle)
		end
		
		for i, prize in pairs(event.prizes) do
			if (prize.info) then
				local infoRow = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				infoRow:addAdaptedText(true, prize.info)
				table.insert(listElements, infoRow)
			end
			if (prize.tc) then
				local itemShopInfo = { itemname = PlayerInfo:currencyFormat(prize.tc) .. " Toricredits", icon = "../textures/store/toricredit.tga" }
				local itemRewardView = Events:showPrizeInfo(itemShopInfo, listingHolder, #listElements, elementHeight)
				table.insert(listElements, itemRewardView)
			end
			if (prize.st) then
				local itemShopInfo = { itemname = prize.st .. (prize.st > 1 and " Shiai Tokens" or " Shiai Token"), icon = "../textures/store/shiaitoken.tga" }
				local itemRewardView = Events:showPrizeInfo(itemShopInfo, listingHolder, #listElements, elementHeight)
				table.insert(listElements, itemRewardView)
			end
			if (prize.itemids) then
				for i, id in pairs(prize.itemids) do
					local itemShopInfo = Torishop:getItemInfo(id)
					local itemRewardView = Events:showPrizeInfo(itemShopInfo, listingHolder, #listElements, elementHeight)
					table.insert(listElements, itemRewardView)
				end
			end
			if (i ~= #event.prizes) then
				local emptyRow = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				table.insert(listElements, emptyRow)
			end
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
		scrollBar.bgColor = { 0, 0, 0, 0 }
		scrollBar.hoverColor = { 0, 0, 0, 0 }
		scrollBar.pressedColor = { 0, 0, 0, 0 }
		listingScrollBG.bgColor = { 0, 0, 0, 0 }
		
		return topBar, botBar
	end
	
	function Events:getEventInfo(id)
		local events = News:getEvents()
		
		events[id].accentColor = events[id].accentColor or TB_MENU_DEFAULT_BG_COLOR
		return events[id]
	end
	
	function Events:showEventInfo(id)
		if (not TB_STORE_DATA.ready) then
			TBMenu:showDataError("Please wait until Torishop data is ready")
			return false
		end
		local event = Events:getEventInfo(id or 1)
		local overlay = TBMenu:spawnWindowOverlay()
		UIScrollbarIgnore = false
		local viewElement = UIElement:new({
			parent = overlay,
			pos = { WIN_W / 10, 100 },
			size = { WIN_W * 0.8, WIN_H - 200 },
			bgColor = event.accentColor,
			uiColor = event.uiColor
		})
		overlay:addMouseHandlers(nil, function()
				overlay:kill()
			end)
		local scale = viewElement.size.h * 2 - 200 < viewElement.size.w and viewElement.size.h - 100 or viewElement.size.w / 2
		local backgroundImage = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 2 - scale, (viewElement.size.h - scale) / 2 },
			size = { scale * 2, scale },
			bgImage = event.image
		})
		
		local descriptionView = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w * 0.6, viewElement.size.h }
		})
		local dtopBar, dbotBar = Events:showEventDescription(descriptionView, event)
		local prizesView = UIElement:new({
			parent = viewElement,
			pos = { descriptionView.size.w, 0 },
			size = { viewElement.size.w - descriptionView.size.w, viewElement.size.h }
		})
		local ptopBar, pbotBar = Events:showEventPrizes(prizesView, event)
		
		local eventName = UIElement:new({
			parent = dtopBar,
			pos = { 10, 5 },
			size = { viewElement.size.w - (dtopBar.size.h - 30), dtopBar.size.h - 10 },
			bgColor = event.accentColor
		})
		table.insert(ptopBar.child, eventName)
		eventName:addAdaptedText(false, event.name, nil, nil, FONTS.BIG)
		
		local eventForumLinkHolder = UIElement:new({
			parent = dbotBar,
			pos = { 0, 0 },
			size = { viewElement.size.w, dbotBar.size.h },
			bgColor = event.accentColor,
			uiColor = event.accentColor
		})
		local buttonHColor, buttonPColor, delta = nil, nil, nil
		if (event.buttonHoverColor and event.buttonPressedColor) then
			buttonHColor = event.buttonHoverColor
			buttonPColor = event.buttonPressedColor
			delta = buttonHColor[1] + buttonHColor[2] + buttonHColor[3]
		else
			buttonHColor = cloneTable(viewElement.uiColor)
			buttonPColor = cloneTable(viewElement.uiColor)
			local delta = buttonHColor[1] + buttonHColor[2] + buttonHColor[3]
			if (delta > 1.5) then
				buttonHColor[2] = (buttonHColor[2] - math.abs(0.8 - buttonHColor[2]))
				buttonHColor[3] = (buttonHColor[3] - math.abs(0.8 - buttonHColor[3]))
				buttonPColor[2] = (buttonPColor[2] - math.abs(0.85 - buttonPColor[2]))
				buttonPColor[3] = (buttonPColor[3] - math.abs(0.85 - buttonPColor[3]))
			else
				buttonHColor[1] = (buttonHColor[1] + math.abs(0.6 - buttonHColor[1]))
				buttonPColor[1] = (buttonPColor[1] + math.abs(0.7 - buttonPColor[1]))
			end
		end
		
		local buttons = event.action and 2 or 1
		local eventForumLink = UIElement:new({
			parent = eventForumLinkHolder,
			pos = { buttons == 2 and viewElement.size.w / 20 or viewElement.size.w * 0.1, 10 },
			size = { buttons == 2 and viewElement.size.w * 0.425 or viewElement.size.w * 0.8, eventForumLinkHolder.size.h - 20 },
			interactive = true,
			bgColor = viewElement.uiColor,
			hoverColor = buttonHColor,
			pressedColor = buttonPColor,
			shapeType = ROUNDED,
			rounded = 3
		})
		table.insert(pbotBar.child, eventForumLink)
		TBMenu:showTextExternal(eventForumLink, "View event on forums")
		eventForumLink:addMouseHandlers(nil, function()
				open_url(event.forumlink)
			end)
		if (event.action) then
			local eventActionButton = UIElement:new({
				parent = eventForumLinkHolder,
				pos = { viewElement.size.w * 0.525, 10 },
				size = { viewElement.size.w * 0.425, eventForumLinkHolder.size.h - 20 },
				interactive = true,
				bgColor = viewElement.uiColor,
				hoverColor = buttonHColor,
				pressedColor = buttonPColor,
				shapeType = ROUNDED,
				rounded = 3
			})
			table.insert(pbotBar.child, eventActionButton)
			eventActionButton:addAdaptedText(false, event.actionText)
			eventActionButton:addMouseHandlers(nil, function()
					close_menu()
					event.action()
				end)
		end
		
		local closeButton = UIElement:new({
			parent = ptopBar,
			pos = { -(ptopBar.size.h - 10), 10 },
			size = { ptopBar.size.h - 20, ptopBar.size.h - 20 },
			bgColor = viewElement.uiColor,
			hoverColor = buttonHColor,
			pressedColor = buttonPColor,
			rounded = 3,
			shapeType = ROUNDED,
			interactive = true
		})
		local closeTexture = "../textures/menu/general/buttons/crosswhite.tga"
		if (delta > 1.5) then
			closeTexture = "../textures/menu/general/buttons/crossblack.tga"
		end
		local closeImage = UIElement:new({
			parent = closeButton,
			pos = { 5, 5 },
			size = { closeButton.size.w - 10, closeButton.size.h - 10 },
			bgImage = closeTexture
		})
		table.insert(dtopBar.child, closeButton)
		closeButton:addMouseHandlers(nil, function()
				overlay:kill()
			end)
	end
end
