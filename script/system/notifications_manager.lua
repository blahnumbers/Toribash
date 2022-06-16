TB_MENU_NOTIFICATIONS_MESSAGES = TB_MENU_NOTIFICATIONS_MESSAGES or {}

do
	-- Notifications manager class
	--
	-- **Ver 1.2 updates:**
	-- * Notifications:getNavigationButtons() will now swap out "To Main" button with "Back" if showBack param is true
	-- * Notifications:getNavigationButtons() backAction argument support for custom functionality when showBack is set to true
	Notifications = { ver = 1.2 }
	Notifications.__index = Notifications
	local cln = {}
	setmetatable(cln, Notifications)

	function Notifications:quit()
		tbMenuCurrentSection:kill(true)
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end

	function Notifications:getNavigationButtons(showBack, justClaimed, backAction)
		local navigation = {
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
				action = function() Notifications:quit() end,
			},
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONLOGINREWARDS,
				misctext = (PlayerInfo:getLoginRewards().available and not justClaimed) and "!" or nil,
				action = function() Notifications:showLoginRewards() TB_MENU_NOTIFICATIONS_LASTSCREEN = 1 end,
				right = true,
				sectionId = 1
			},
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONQUESTS,
				misctext = TB_MENU_QUESTS_GLOBAL_COUNT + TB_MENU_QUESTS_COUNT > 0 and TB_MENU_QUESTS_GLOBAL_COUNT + TB_MENU_QUESTS_COUNT or nil,
				action = function() Notifications:showQuests() TB_MENU_NOTIFICATIONS_LASTSCREEN = 2 end,
				right = true,
				sectionId = 2
			},
			{
				text = TB_MENU_LOCALIZED.WORDNOTIFICATIONS,
				misctext = TB_MENU_NOTIFICATIONS_NET_COUNT > 0 and TB_MENU_NOTIFICATIONS_NET_COUNT or nil,
				action = function() Notifications:prepareNotifications() TB_MENU_NOTIFICATIONS_LASTSCREEN = 3 end,
				right = true,
				sectionId = 3
			}
		}
		if (showBack) then
			local back = {
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = function()
					if (backAction) then
						backAction()
					else
						Notifications:showMain()
					end
				end
			}
			navigation[1] = back
		end
		return navigation
	end

	function Notifications:showLoginRewards()
		local rewards = PlayerInfo:getLoginRewards()
		if (rewards.days == 0 and rewards.available == false and rewards.timeLeft == 0) then
			rewards.available = true
			TBMenu:showDataError(TB_MENU_LOCALIZED.REWARDSCLAIMNETWORKERROR)
		end
		TB_MENU_PLAYER_INFO.rewards = rewards
		if (Rewards:getRewardData()) then
			if (TB_STORE_DATA.ready) then
				Rewards:showMain(tbMenuCurrentSection, TB_MENU_PLAYER_INFO.rewards)
			else
				TBMenu:showDataError(TB_MENU_LOCALIZED.STOREDATALOADERROR)
			end
		end
	end

	function Notifications:showQuests()
		Quests:showMain()
	end

	function Notifications:beautifySystemAccounts(name)
		local color = { 1, 1, 1, 1 }
		if (name == "ToriBot") then
			name = "^27" .. name
			color = cloneTable(TB_MENU_DEFAULT_ORANGE)
		elseif (name == "Event Squad") then
			name = "^32" .. name
			color = cloneTable(TB_MENU_DEFAULT_ORANGE)
		end

		return name, color
	end

	function Notifications:getNetworkNotifications()
		TB_MENU_NOTIFICATIONS_DATA = {}
		return pcall(function()
				local response = get_network_response()
				local lines = {}
				local pattern = '([^\n]+)'
				local _ = string.gsub(response, pattern, function(val) table.insert(lines, val) end)

				for i, ln in pairs(lines) do
					local data_stream = { ln:match(("([^\t]*)\t?"):rep(5)) }
					data_stream[3], data_stream[6] = Notifications:beautifySystemAccounts(data_stream[3])
					table.insert(TB_MENU_NOTIFICATIONS_DATA, {
						id = data_stream[1] + 0,
						title = data_stream[2],
						user = data_stream[3],
						read = data_stream[4] ~= '0',
						date = data_stream[5],
						color = data_stream[6]
					})
				end
			end)
	end

	function Notifications:showNotificationText(viewElement, notification)
		viewElement:kill(true)
		TBMenu:addBottomBloodSmudge(viewElement, 2)

		local messageHolder = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h - 70 }
		})
		local messageTitle = UIElement:new({
			parent = messageHolder,
			pos = { 25, 0 },
			size = { messageHolder.size.w - 50, 50 }
		})
		messageTitle:addAdaptedText(true, notification.title, nil, nil, nil, LEFTMID)
		local messageFrom = UIElement:new({
			parent = messageHolder,
			pos = { 25, messageTitle.shift.y + messageTitle.size.h },
			size = { messageHolder.size.w - 50, 40 }
		})
		messageFrom:addAdaptedText(true, "Sent by " .. notification.user .. "\n" .. notification.date, nil, nil, 4, LEFTMID)
		local shiftY = 0
		for i,v in pairs(notification.message) do
			local messageText = UIElement:new({
				parent = messageHolder,
				pos = { 25 + (v.indent and v.indent or 0), messageFrom.shift.y + messageFrom.size.h + 10 + shiftY },
				size = { messageHolder.size.w - (v.indent and 100 or 50), messageHolder.size.h - shiftY - messageFrom.shift.y - messageFrom.size.h - 20 }
			})
			messageText:addAdaptedText(true, v.text, nil, nil, 4, LEFT, 0.8, 0.8)
			local heightMod = getFontMod(messageText.textFont) * messageText.textScale * 10
			messageText.size.h = math.ceil(#messageText.dispstr * heightMod) + 1
			shiftY = shiftY + messageText.size.h + 10

			-- Add quote line after element height adjustments
			if (v.quote) then
				local quoteLine = messageText:addChild({
					pos = { -messageText.size.w - 15, 0 },
					size = { 3, messageText.size.h },
					bgColor = UICOLORWHITE
				})
			end
			if (v.list) then
				local listBullet = messageText:addChild({
					pos = { -messageText.size.w - 20, 5 },
					size = { 10, 10 },
					shapeType = ROUNDED,
					rounded = 10,
					bgColor = UICOLORWHITE
				})
			end

			if (shiftY > messageHolder.size.h) then
				messageText.size.h = messageHolder.size.h - messageText.shift.y
				break
			end

			for j, attch in pairs(notification.attachments) do
				if (attch.mbitidx == i) then
					local pos = 0
					for k = 1, #messageText.dispstr do
						if (pos + messageText.dispstr[k]:len() > attch.pos) then
							local xPosAt = get_string_length(messageText.dispstr[k]:sub(0, attch.pos - pos), messageText.textFont) * messageText.textScale
							local button = UIElement:new({
								parent = messageText,
								pos = { xPosAt, heightMod * (k - 1) },
								size = { math.ceil(get_string_length(attch.word, messageText.textFont) * messageText.textScale), math.ceil(heightMod) },
								bgColor = TB_MENU_DEFAULT_BLUE,
								hoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
								pressedColor = TB_MENU_DEFAULT_YELLOW,
								interactive = true
							})
							button:addMouseHandlers(nil, function()
									if (attch.isInventory) then
										Notifications:quit()
										Torishop:prepareInventory(tbMenuCurrentSection)
									else
										open_url(attch.url)
									end
								end)
							button:addCustomDisplay(true, function()
									button:uiText(attch.word, nil, nil, messageText.textFont, LEFT, messageText.textScale, nil, nil, button:getButtonColor())
								end)
							break
						end
						pos = pos + messageText.dispstr[k]:len()
					end
					break
				end
			end
		end

		local messageButtons = UIElement:new({
			parent = viewElement,
			pos = { 0, messageHolder.size.h + messageHolder.shift.y },
			size = { viewElement.size.w, viewElement.size.h - messageHolder.size.h - messageHolder.shift.y * 2 }
		})
		local messageViewForums = UIElement:new({
			parent = messageButtons,
			pos = { messageButtons.size.w / 4, 10 },
			size = { messageButtons.size.w / 2, messageButtons.size.h - 30 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		messageViewForums:addMouseHandlers(nil, function()
				open_url("https://forum.toribash.com/private.php?do=showpm&pmid=" .. notification.id)
			end)
		TBMenu:showTextExternal(messageViewForums, TB_MENU_LOCALIZED.NOTIFICATIONSVIEWPMFORUMS)
	end

	function Notifications:fixBBCode(message)
		local pattern = "%[[^%]]+%]"
		local messagebits = { { text = '' } }
		local attachments = {}
		local lastPos = 0
		local skipWord = nil

		local message = string.gsub(message, "%'", "\'")
		message = string.gsub(message, "\n", "\n")
		local _ = string.gsub(message, pattern, function(match)
				local sPos, ePos
				pcall(function()
					local matchcln = string.gsub(match, "[('.?%[%])%*]", "%%%1")
					sPos, ePos = string.find(message, matchcln, lastPos)
					local matchlwr = string.lower(match)
					if (matchlwr == "[/img]") then
						skipWord = "~IMAGE~"
					else
						skipWord = nil
					end

					if (not skipWord) then
						messagebits[#messagebits].text = messagebits[#messagebits].text .. string.sub(message, lastPos, sPos - 1)
					else
						messagebits[#messagebits].text = messagebits[#messagebits].text .. skipWord
					end

					if (string.find(matchlwr, "%[url=") == 1) then
						table.insert(attachments, {
							pos = messagebits[#messagebits].text:len(),
							url = match:gsub("^%[%w+=['\"]?([^'\"]*)['\"]?%]", "%1"),
							mbitidx = #messagebits
						})
						if (attachments[#attachments].url:find("tori_inventory") ~= nil) then
							attachments[#attachments].isInventory = true
						end
						if (attachments[#attachments].url:find("^http") == nil) then
							attachments[#attachments].url = "https://" .. attachments[#attachments].url
						end
					end
					if (string.find(matchlwr, "%[/url") == 1) then
						-- Safety check for broken links
						if (attachments[#attachments] and not attachments[#attachments].word) then
							attachments[#attachments].word = string.sub(message, lastPos, sPos - 1)
						end
					end

					if (string.find(matchlwr, "%[quote") == 1) then
						messagebits[#messagebits + 1] = { text = '', quote = true, indent = 50 }
					end
					if (string.find(matchlwr, "%[/quote") == 1) then
						messagebits[#messagebits + 1] = { text = '' }
					end

					if (string.find(matchlwr, "%[%*") == 1) then
						messagebits[#messagebits + 1] = { text = '', list = true, indent = 30 }
					end
					if (string.find(matchlwr, "%[/list") == 1) then
						messagebits[#messagebits + 1] = { text = '' }
					end
				end)

				if (lastPos < ePos) then
					lastPos = ePos + 1
				end
			end)
		messagebits[#messagebits].text = messagebits[#messagebits].text .. string.sub(message, lastPos)

		return messagebits, attachments
	end

	function Notifications:loadNotificationText(viewElement, notification, newMark)
		-- Make sure they can't spam this too much
		if (TB_MENU_NOTIFICATION_MESSAGE_LOADING) then
			return false
		else
			TB_MENU_NOTIFICATION_MESSAGE_LOADING = true
		end

		viewElement:kill(true)
		if (TB_MENU_NOTIFICATIONS_MESSAGES[notification.id]) then
			TB_MENU_NOTIFICATION_MESSAGE_LOADING = false
			notification.message, notification.attachments = Notifications:fixBBCode(TB_MENU_NOTIFICATIONS_MESSAGES[notification.id])
			Notifications:showNotificationText(viewElement, notification)
			return true
		end

		TBMenu:addBottomBloodSmudge(viewElement, 2)
		local loader = UIElement:new({
			parent = viewElement,
			pos = { 30, 50 },
			size = { viewElement.size.w - 60, viewElement.size.h - 100 }
		})
		TBMenu:displayLoadingMark(loader, TB_MENU_LOCALIZED.NOTIFICATIONSLOADINGPM)
		Request:queue(function() get_notifications_pmtext(notification.id) end, 'net_notifications', function()
				if (loader:isDisplayed()) then
					TB_MENU_NOTIFICATION_MESSAGE_LOADING = false
					TB_MENU_NOTIFICATIONS_MESSAGES[notification.id] = get_network_response()
					notification.message, notification.attachments = Notifications:fixBBCode(get_network_response())
					Notifications:showNotificationText(viewElement, notification)
					if (newMark) then
						newMark.pmTitle:moveTo(newMark.shift.x)
						newMark.pmTitle.size.w = newMark.pmTitle.size.w + newMark.size.w + newMark.shift.x
						newMark:hide(true)
						notification.read = true
						if (TB_MENU_NOTIFICATIONS_NET_COUNT > 0) then
							TB_MENU_NOTIFICATIONS_NET_COUNT = TB_MENU_NOTIFICATIONS_NET_COUNT - 1
							tbMenuNavigationBar:kill(true)
							TBMenu:showNavigationBar(Notifications:getNavigationButtons(), true, true, TB_MENU_NOTIFICATIONS_LASTSCREEN)
						end
					end
				end
			end, function()
				if (loader:isDisplayed()) then
					TB_MENU_NOTIFICATION_MESSAGE_LOADING = false
					loader:kill(true)
					loader:addAdaptedText(true, TB_MENU_LOCALIZED.ERRORTRYAGAIN)
				end
			end)
		return true
	end

	function Notifications:getTotalNotifications(forceReload)
		-- Update once per 2 minutes or with force reload
		if (TB_MENU_NOTIFICATIONS_LASTUPDATE.count + 120 < os.clock() or forceReload) then
			Request:queue(function() get_notifications_count() end, "net_notifications", function()
					TB_MENU_NOTIFICATIONS_NET_COUNT = string.gsub(get_network_response(), "TOTALMSGS[^%d]*(%d+)[^%d]*", "%1")
					TB_MENU_NOTIFICATIONS_NET_COUNT = tonumber(TB_MENU_NOTIFICATIONS_NET_COUNT) or 0
					if (TB_MENU_NOTIFICATIONS_NET_COUNT > 0) then
						local notificationsCountWidth = get_string_length(TB_MENU_NOTIFICATIONS_COUNT + TB_MENU_NOTIFICATIONS_NET_COUNT, 4)
						notificationsCountWidth = notificationsCountWidth > tbMenuNotificationsCount.size.h and (notificationsCountWidth > tbMenuNotificationsCount.size.h * 2 and tbMenuNotificationsCount.size.h * 2 or notificationsCountWidth) or tbMenuNotificationsCount.size.h
						tbMenuNotificationsCount.size.w = notificationsCountWidth
						tbMenuNotificationsCount:moveTo(-notificationsCountWidth)
						tbMenuNotificationsCount:show()
					end
				end)
			TB_MENU_NOTIFICATIONS_LASTUPDATE.count = os.clock()
		end
	end

	function Notifications:showNotifications(viewElement)
		usage_event("notifications")
		viewElement:kill(true)

		local elementHeight = 50
		local notificationsHolder = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.4 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(notificationsHolder, elementHeight, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

		local notificationsHeader = UIElement:new({
			parent = topBar,
			pos = { 15, 8 },
			size = { topBar.size.w - 40 - topBar.size.h, topBar.size.h - 16 }
		})
		notificationsHeader:addAdaptedText(true, TB_MENU_LOCALIZED.NOTIFICATIONSHEADER, nil, nil, FONTS.BIG, LEFTMID)
		local notificationsReload = UIElement:new({
			parent = topBar,
			pos = { -topBar.size.h, 10 },
			size = { topBar.size.h - 16, topBar.size.h - 16 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 5,
			bgImage = "../textures/menu/general/buttons/reload.tga"
		})
		notificationsReload:addMouseHandlers(nil, function()
				Notifications:prepareNotifications(true)
			end)
		TBMenu:addBottomBloodSmudge(botBar, 1)

		local notificationBody = UIElement:new({
			parent = viewElement,
			pos = { notificationsHolder.shift.x + notificationsHolder.size.w + 10, 0 },
			size = { viewElement.size.w - notificationsHolder.shift.x * 2 - notificationsHolder.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(notificationBody, 2)

		if (#TB_MENU_NOTIFICATIONS_DATA == 0) then
			listingHolder:addAdaptedText(true, TB_MENU_LOCALIZED.NOTIFICATIONSEMPTY)
			return
		end

		local listElements = {}
		local selectedElement = nil
		for i, notification in pairs(TB_MENU_NOTIFICATIONS_DATA) do
			local notificationElement = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listElements, notificationElement)
			local notificationBG = UIElement:new({
				parent = notificationElement,
				pos = { 10, 5 },
				size = { notificationElement.size.w - 12, notificationElement.size.h - 10 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})

			local shiftX = 0
			local unreadMark
			if (not notification.read) then
				unreadMark = UIElement:new({
					parent = notificationBG,
					pos = { 10, 10 },
					size = { notificationBG.size.h, notificationBG.size.h - 20 },
					bgColor = TB_MENU_DEFAULT_BLUE,
					shapeType = ROUNDED,
					rounded = 10
				})
				unreadMark:addAdaptedText(false, TB_MENU_LOCALIZED.WORDNEW, nil, nil, nil, nil, 0.6)
				shiftX = unreadMark.shift.x + unreadMark.size.w
			end
			local notificationTitle = UIElement:new({
				parent = notificationBG,
				pos = { 10 + shiftX, 2 },
				size = { notificationBG.size.w / 3 * 2 - 15 - shiftX, notificationBG.size.h - 4 },
				uiColor = notification.color
			})
			notificationTitle:addAdaptedText(true, notification.title, nil, nil, 4, LEFTMID, 0.7)
			if (unreadMark) then
				unreadMark.pmTitle = notificationTitle
			end
			local notificationFrom = UIElement:new({
				parent = notificationBG,
				pos = { notificationTitle.size.w + notificationTitle.shift.x + 10, 2 },
				size = { notificationBG.size.w - (notificationTitle.size.w + notificationTitle.shift.x + 10) - 10, notificationBG.size.h / 2 - 2 }
			})
			notificationFrom:addAdaptedText(true, notification.user, nil, nil, 4, RIGHTBOT, 0.7)
			local notificationDate = UIElement:new({
				parent = notificationBG,
				pos = { notificationFrom.shift.x, notificationFrom.shift.y + notificationFrom.size.h + 2 },
				size = { notificationFrom.size.w, notificationFrom.size.h }
			})
			notificationDate:addAdaptedText(true, notification.date, nil, nil, 4, RIGHT, 0.6)


			notificationBG:addMouseHandlers(nil, function()
					if (Notifications:loadNotificationText(notificationBody, notification, unreadMark)) then
						if (selectedElement) then
							selectedElement.bgColor = table.clone(TB_MENU_DEFAULT_DARKER_COLOR)
						end
						selectedElement = notificationBG
						selectedElement.bgColor = table.clone(TB_MENU_DEFAULT_LIGHTER_COLOR)
					end
				end)
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
	end

	function Notifications:prepareNotifications(forceReload)
		tbMenuCurrentSection:kill(true)
		if (forceReload) then
			TB_MENU_NOTIFICATIONS_LASTUPDATE.data = 0
		end

		if (TB_MENU_NOTIFICATIONS_LASTUPDATE.data + 60 < os.time()) then
			Notifications:getTotalNotifications(true)
			local notificationsMain = tbMenuCurrentSection:addChild({
				shift = { 5, 0 },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			TBMenu:addBottomBloodSmudge(notificationsMain, 1)
			local loader = notificationsMain:addChild({
				shift = { notificationsMain.size.w / 5, notificationsMain.size.h / 5 }
			})
			TBMenu:displayLoadingMark(loader, TB_MENU_LOCALIZED.NOTIFICATIONSLOADING)
			Request:queue(function() get_notifications() end, "net_notifications", function()
					if (loader:isDisplayed()) then
						if (Notifications:getNetworkNotifications()) then
							tbMenuNavigationBar:kill(true)
							TBMenu:showNavigationBar(Notifications:getNavigationButtons(), true, true, TB_MENU_NOTIFICATIONS_LASTSCREEN)
							Notifications:showNotifications(tbMenuCurrentSection)
							TB_MENU_NOTIFICATIONS_LASTUPDATE.data = os.time()
						else
							loader:kill(true)
							loader:addAdaptedText(false, TB_MENU_LOCALIZED.ERRORTRYAGAIN)
						end
					end
				end, function()
					if (loader:isDisplayed()) then
						loader:kill(true)
						loader:addAdaptedText(false, TB_MENU_LOCALIZED.ERRORTRYAGAIN)
					end
				end)
		else
			Notifications:showNotifications(tbMenuCurrentSection)
		end
	end

	function Notifications:showMain(override)
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 4
		local rewards = PlayerInfo:getLoginRewards()
		local navButtons = Notifications:getNavigationButtons()
		if (rewards.available and not override) then
			Notifications:showLoginRewards()
			TB_MENU_NOTIFICATIONS_LASTSCREEN = 1
			TBMenu:showNavigationBar(navButtons, true, true, 1)
		else
			for i,v in pairs(navButtons) do
				if (v.sectionId == TB_MENU_NOTIFICATIONS_LASTSCREEN) then
					v.action()
					TBMenu:showNavigationBar(navButtons, true, true, v.sectionId)
					return
				end
			end
		end
	end
end
