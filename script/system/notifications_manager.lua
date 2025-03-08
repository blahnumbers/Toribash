require("toriui.uielement")
require("system.network_request")
require("system.menu_manager")
require("system.playerinfo_manager")
require("system.quests_manager")

if (Notifications == nil) then
	---Notifications manager class
	---
	---**Version 5.72:**
	---* Message deletion without complete notification cache reload
	---
	---**Version 5.60:**
	---* Full EmmyLua annotations
	---* Moved globals to be Notifications class fields
	---* Security updates to make messages data inaccessible by other scripts
	---
	---**Ver 1.2 updates:**
	---* Notifications:getNavigationButtons() will now swap out "To Main" button with "Back" if showBack param is true
	---* Notifications:getNavigationButtons() backAction argument support for custom functionality when showBack is set to true
	---@class Notifications
	Notifications = {
		MessageLoadingInProgress = false,
		LastUpdate = { count = -1000, data = -1000 },
		ver = 5.72,
		__index = {}
	}
end

---@class NotificationMessageBit
---@field text string
---@field indent integer
---@field quote boolean
---@field list boolean

---@class NotificationMessageAttachment
---@field mbitidx integer Corresponding message bit id
---@field pos integer Attachment position in text
---@field url string Link URL
---@field isInventory boolean Whether the attachment link is pointing to user inventory
---@field word string Link display text
---@field buttons UIElement[]

---@class NotificationMessage
---@field id integer Message id
---@field title string Message title
---@field user string Message sender's username
---@field read boolean
---@field date string
---@field nameColor Color
---@field textColor Color
---@field message NotificationMessageBit[]
---@field attachments NotificationMessageAttachment[]

---Internal helper class for Notifications class
---@class NotificationsInternal
---@field NotificationsData NotificationMessage[]
---@field NotificationsMessages string[] Table containing cached text for user messages
local NotificationsInternal = {
	NotificationsUser = PlayerInfo.Get().username,
	NotificationsData = {},
	NotificationsMessages = {},
	__index = {}
}

---Deletes a message from cache
---@param messageInfo NotificationMessage
function NotificationsInternal.DeleteMessage(messageInfo)
	for i, v in pairs(NotificationsInternal.NotificationsData) do
		if (v.id == messageInfo.id) then
			table.remove(NotificationsInternal.NotificationsData, i)
			NotificationsInternal.NotificationsMessages[v.id] = nil
			break
		end
	end
end

function Notifications:quit()
	TBMenu:clearNavSection()
	TBMenu:showNavigationBar()
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
	TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
end

---Returns navigation buttons data for current Notifications screen
---@param showBack? boolean
---@param justClaimed? boolean
---@param backAction? function
---@return MenuNavButton[]
function Notifications:getNavigationButtons(showBack, justClaimed, backAction)
	---@type MenuNavButton[]
	local navigation = {
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
			action = function() Notifications:quit() end,
		},
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONLOGINREWARDS,
			misctext = (PlayerInfo.getLoginRewards().available and not justClaimed) and "!" or nil,
			action = function() Notifications:showLoginRewards() TB_MENU_NOTIFICATIONS_LASTSCREEN = 1 end,
			right = true,
			sectionId = 1
		},
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONQUESTS,
			misctext = TB_MENU_QUESTS_GLOBAL_COUNT + TB_MENU_QUESTS_COUNT > 0 and tostring(TB_MENU_QUESTS_GLOBAL_COUNT + TB_MENU_QUESTS_COUNT) or nil,
			action = function() Quests:showMain() TB_MENU_NOTIFICATIONS_LASTSCREEN = 2 end,
			right = true,
			sectionId = 2
		},
		{
			text = TB_MENU_LOCALIZED.MESSAGESTITLE,
			misctext = TB_MENU_NOTIFICATIONS_UNREAD_COUNT > 0 and TB_MENU_NOTIFICATIONS_UNREAD_COUNT or nil,
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

---Displays login rewards screen
function Notifications:showLoginRewards()
	local rewards = PlayerInfo.getLoginRewards()
	if (rewards.days == 0 and rewards.available == false and rewards.timeLeft == 0) then
		rewards.available = true
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REWARDSCLAIMNETWORKERROR)
		return
	end
	TB_MENU_PLAYER_INFO.rewards = rewards
	if ((table.empty(Rewards.Data) and Rewards.ParseData() == false) or not Store.Ready) then
		TBMenu:showStatusMessage(TB_MENU_LOCALIZED.STOREDATALOADERROR)
		return
	end
	Rewards:showMain(TBMenu.CurrentSection, TB_MENU_PLAYER_INFO.rewards)
end

---Returns custom colors to use for provided account names
---@param name string
---@return Color|nil
---@return Color
function Notifications:beautifySystemAccounts(name)
	local nameColor = nil
	if (name == "ToriBot") then
		nameColor = get_color_from_hex("E430E4")
	elseif (name == "Event Squad") then
		nameColor = get_color_from_hex("AD36AF")
	elseif (name == "Market Squad") then
		nameColor = get_color_from_hex("3FA741")
	end

	return nameColor, nameColor == nil and { 1, 1, 1, 1 } or TB_MENU_DEFAULT_YELLOW
end

---Parses notifications data from network response
---@return boolean
function Notifications:getNetworkNotifications()
	local currentUser = PlayerInfo.Get().username
	if (NotificationsInternal.NotificationsUser ~= currentUser) then
		NotificationsInternal.NotificationsData = {}
		NotificationsInternal.NotificationsUser = currentUser
	end

	local cachedPmIds = {}
	for _, v in pairs(NotificationsInternal.NotificationsData) do
		table.insert(cachedPmIds, v.id)
	end

	return pcall(function()
			local response = get_network_response()
			local lines = {}
			local pattern = '([^\n]+)'
			local _ = utf8.gsub(response, pattern, function(val) table.insert(lines, val) end)

			for _, ln in pairs(lines) do
				local data_stream = { utf8.match(ln, ("([^\t]*)\t?"):rep(5)) }
				local pmId = data_stream[1] + 0
				if (not in_array(pmId, cachedPmIds)) then
					data_stream[6], data_stream[7] = Notifications:beautifySystemAccounts(data_stream[3])
					table.insert(NotificationsInternal.NotificationsData, {
						id = pmId,
						title = stripColors(data_stream[2]),
						user = data_stream[3],
						read = data_stream[4] ~= '0',
						date = data_stream[5],
						nameColor = data_stream[6],
						textColor = data_stream[7]
					})
				end
			end
			NotificationsInternal.NotificationsData = table.qsort(NotificationsInternal.NotificationsData, { "id" }, { SORT_DESCENDING })
		end)
end

---Displays notification in a provided viewport
---@param viewElement UIElement
---@param notification NotificationMessage
function Notifications:showNotificationText(viewElement, notification)
	viewElement:kill(true)
	TBMenu:addBottomBloodSmudge(viewElement, 2)

	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(viewElement, 60, 70, 20, TB_MENU_DEFAULT_BG_COLOR)

	topBar.bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	local messageTitle = topBar:addChild({
		parent = topBar,
		pos = { 25, 5 },
		size = { (topBar.size.w - 50) * 0.65, topBar.size.h - 10 }
	})
	messageTitle:addAdaptedText(true, notification.title, nil, nil, FONTS.BIG, LEFTMID, 0.65, nil, 0.2)

	local messageFrom = topBar:addChild({
		pos = { messageTitle.shift.x + messageTitle.size.w, messageTitle.shift.y },
		size = { (topBar.size.w - 50) - messageTitle.size.w, messageTitle.size.h / 2 }
	})
	messageFrom:addAdaptedText(true, notification.user, nil, nil, 4, RIGHTBOT, 0.8)
	local messageDate = topBar:addChild({
		pos = { messageFrom.shift.x, messageFrom.shift.y + messageFrom.size.h },
		size = { messageFrom.size.w, messageFrom.size.h },
		uiColor = { 1, 1, 1, 0.8 }
	})
	messageDate:addAdaptedText(true, notification.date, nil, nil, 4, RIGHTBOT, 0.6)

	local elementHeight = 25
	local listElements = { listingHolder:addChild({ pos = { 0, 0 }, size = { listingHolder.size.w, elementHeight }}) }
	local attachments = table.clone(notification.attachments)
	for id, v in pairs(notification.message) do
		local textString = textAdapt(v.text, 4, 0.8, listingHolder.size.w - (v.indent or 0) - 50)
		local textLength = 0
		for i = 1, #textString do
			textLength = textLength + utf8.len(textString[i])
			local messageText = listingHolder:addChild({
				pos = { 25 + (v.indent or 0), #listElements * elementHeight },
				size = { listingHolder.size.w - (v.indent or 0) - 50, elementHeight }
			})
			table.insert(listElements, messageText)
			messageText:addAdaptedText(true, textString[i], nil, nil, 4, LEFT, 0.8, 0.8)

			-- Add quote line after element height adjustments
			if (v.quote) then
				messageText:addChild({
					pos = { -messageText.size.w - 15, 0 },
					size = { 3, messageText.size.h },
					bgColor = UICOLORWHITE
				})
			end
			if (v.list) then
				messageText:addChild({
					pos = { -messageText.size.w - 20, 5 },
					size = { 10, 10 },
					shapeType = ROUNDED,
					rounded = 10,
					bgColor = UICOLORWHITE
				})
			end

			for j, attch in pairs(attachments) do
				if (attch.mbitidx == id) then
					local textStringlen = utf8.len(textString[i])
					if (textLength > attch.pos and attch.pos - textLength + textStringlen >= 0) then
						local xPosAt = get_string_length(utf8.sub(messageText.dispstr[1], 0, attch.pos - textLength + textStringlen), messageText.textFont) * messageText.textScale
						local linkText = attch.word
						attachments[j].buttons = attachments[j].buttons or { }
						if (math.ceil(get_string_length(attch.word, messageText.textFont) * messageText.textScale) > messageText.size.w - xPosAt) then
							local lines = textAdapt(attch.word, messageText.textFont, messageText.textScale, messageText.size.w - xPosAt)
							linkText = lines[1]
							attachments[j].word = utf8.gsub(attachments[j].word, "^" .. linkText, "")
							attachments[j].pos = attachments[j].pos + utf8.len(linkText)
						end
						local button = messageText:addChild({
							pos = { xPosAt, 0 },
							size = { math.ceil(get_string_length(linkText, messageText.textFont) * messageText.textScale), messageText.size.h },
							bgColor = attch.isInventory and TB_MENU_DEFAULT_ORANGE or TB_MENU_DEFAULT_DARKER_BLUE,
							hoverColor = attch.isInventory and TB_MENU_DEFAULT_DARKER_ORANGE or TB_MENU_DEFAULT_DARKEST_BLUE,
							pressedColor = attch.isInventory and TB_MENU_DEFAULT_YELLOW or TB_MENU_DEFAULT_BLUE,
							interactive = true,
							clickThrough = true,
							hoverThrough = true
						})
						table.insert(attachments[j].buttons, button)
						button:addMouseHandlers(nil, function()
								if (attch.isInventory) then
									Notifications:quit()
									Store:prepareInventory(TBMenu.CurrentSection)
								else
									open_url(attch.url)
								end
							end)
						button:addCustomDisplay(true, function()
								for _, v in pairs(attachments[j].buttons) do
									button.hoverState = math.max(button.hoverState or 0, v.hoverState or 0)
								end
								if (button.hoverState == BTN_HVR) then
									set_mouse_cursor(1)
								end
							end, true)
						button:addCustomDisplay(true, function()
								button:uiText(linkText, nil, nil, messageText.textFont, LEFT, messageText.textScale, nil, nil, button:getButtonColor())
							end)
						break
					end
				end
			end
		end
	end

	if (#listElements * elementHeight > listingHolder.size.h) then
		for _, v in pairs(listElements) do
			v:hide()
		end

		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload, nil, nil, true)
	end

	local messageButtons = botBar
	local shiftX = messageButtons.size.w * 0.375
	local deleteButtonWidth = messageButtons.size.w - shiftX * 2
	if (notification.nameColor == nil) then
		local messageViewForums = messageButtons:addChild({
			pos = { messageButtons.size.w * 0.125, 10 },
			size = { messageButtons.size.w * 0.5, messageButtons.size.h - 20 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		messageViewForums:addMouseUpHandler(function()
				open_url("https://forum.toribash.com/private.php?do=showpm&pmid=" .. notification.id)
			end)
		TBMenu:showTextExternal(messageViewForums, TB_MENU_LOCALIZED.NOTIFICATIONSVIEWPMFORUMS, true)
		shiftX = messageViewForums.shift.x + messageViewForums.size.w + 20
		deleteButtonWidth = messageButtons.size.w - shiftX - messageViewForums.shift.x
	end
	local messageDelete = messageButtons:addChild({
		pos = { shiftX, 10 },
		size = { deleteButtonWidth, messageButtons.size.h - 20 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	messageDelete:addMouseUpHandler(function()
			TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.NOTIFICATIONSDELETECONFIRM1 .. " " .. notification.user .. "\n" .. TB_MENU_LOCALIZED.NOTIFICATIONSDELETECONFIRM2, function()
				Request:queue(function() delete_notification(notification.id) end, "notifications_delete_" .. notification.id, function()
						local response = get_network_response();
						local success = response:gsub("%D", '')
						if (success == '1') then
							NotificationsInternal.DeleteMessage(notification)
							Notifications:prepareNotifications()
							return
						end
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORTRYAGAIN)
					end, function()
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORTRYAGAIN)
					end)
				end)
		end)
	messageDelete:addAdaptedText(TB_MENU_LOCALIZED.WORDDELETE)
end

---Parses notification message's bbcode and returns the data for display
---@param message string
---@return NotificationMessageBit[]
---@return NotificationMessageAttachment[]
function Notifications:fixBBCode(message)
	local pattern = "%[[^%]]+%]"
	---@type NotificationMessageBit[]
	local messagebits = { { text = '' } }
	---@type NotificationMessageAttachment[]
	local attachments = { }
	local lastPos = 0
	local skipWord = nil

	local message = utf8.gsub(message, "%'", "\'")
	message = utf8.gsub(message, "\n", "\n") -- hack to trick UIElement text drawing to accept multiple newlines
	message = utf8.gsub(message, "&#%d%d%d%d;", "") -- remove unicode symbols that we cannot render
	local _ = utf8.gsub(message, pattern, function(match)
			local sPos, ePos
			pcall(function()
				local matchcln = utf8.gsub(match, "[('.?%[%])%*]", "%%%1")
				sPos, ePos = utf8.find(message, matchcln, lastPos)
				local matchlwr = utf8.lower(match)
				if (matchlwr == "[/img]") then
					skipWord = "~IMAGE~"
				else
					skipWord = nil
				end

				if (not skipWord) then
					messagebits[#messagebits].text = messagebits[#messagebits].text .. utf8.sub(message, lastPos, sPos - 1)
				else
					messagebits[#messagebits].text = messagebits[#messagebits].text .. skipWord
				end

				if (utf8.find(matchlwr, "%[url=") == 1 and utf8.find(match, "toribash.com") ~= nil) then
					table.insert(attachments, {
						pos = utf8.len(messagebits[#messagebits].text),
						url = utf8.gsub(match, "^%[%w+=['\"]?([^'\"]*)['\"]?%]", "%1"),
						mbitidx = #messagebits
					})
					if (utf8.find(attachments[#attachments].url, "tori_inventory") ~= nil) then
						attachments[#attachments].isInventory = true
					end
					if (utf8.find(attachments[#attachments].url, "^http") == nil) then
						attachments[#attachments].url = "https://" .. attachments[#attachments].url
					end
				end
				if (utf8.find(matchlwr, "%[/url") == 1) then
					-- Safety check for broken links
					if (attachments[#attachments] and not attachments[#attachments].word) then
						attachments[#attachments].word = utf8.sub(message, lastPos, sPos - 1)
					end
				end

				if (utf8.find(matchlwr, "%[quote") == 1) then
					messagebits[#messagebits + 1] = { text = '', quote = true, indent = 50 }
				end
				if (utf8.find(matchlwr, "%[/quote") == 1) then
					messagebits[#messagebits + 1] = { text = '' }
				end

				if (utf8.find(matchlwr, "%[%*") == 1) then
					messagebits[#messagebits + 1] = { text = '', list = true, indent = 30 }
				end
				if (utf8.find(matchlwr, "%[/list") == 1) then
					messagebits[#messagebits + 1] = { text = '' }
				end
			end)

			if (lastPos < ePos) then
				lastPos = ePos + 1
			end
		end)
	messagebits[#messagebits].text = messagebits[#messagebits].text .. utf8.sub(message, lastPos)

	return messagebits, attachments
end

---Loads notification text from cache or queues a request to fetch it from Toribash servers.
---@param viewElement UIElement
---@param notification NotificationMessage
---@param newMark? UIElement
---@return boolean
function Notifications:loadNotificationText(viewElement, notification, newMark)
	-- Make sure they can't spam this too much
	if (Notifications.MessageLoadingInProgress) then
		return false
	else
		Notifications.MessageLoadingInProgress = true
	end

	viewElement:kill(true)
	if (NotificationsInternal.NotificationsMessages[notification.id]) then
		Notifications.MessageLoadingInProgress = false
		if (notification.message == nil) then
			notification.message, notification.attachments = Notifications:fixBBCode(NotificationsInternal.NotificationsMessages[notification.id])
		end
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
				Notifications.MessageLoadingInProgress = false
				NotificationsInternal.NotificationsMessages[notification.id] = get_network_response()
				notification.message, notification.attachments = Notifications:fixBBCode(get_network_response())
				Notifications:showNotificationText(viewElement, notification)
				if (newMark ~= nil) then
					---@diagnostic disable-next-line: undefined-field
					newMark.pmTitle:moveTo(newMark.shift.x)
					---@diagnostic disable-next-line: undefined-field
					newMark.pmTitle.size.w = newMark.pmTitle.size.w + newMark.size.w + newMark.shift.x
					newMark:hide(true)
					notification.read = true
					if (TB_MENU_NOTIFICATIONS_UNREAD_COUNT > 0) then
						TB_MENU_NOTIFICATIONS_UNREAD_COUNT = TB_MENU_NOTIFICATIONS_UNREAD_COUNT - 1
						TBMenu.NavigationBar:kill(true)
						TBMenu:showNavigationBar(Notifications:getNavigationButtons(), true, true, TB_MENU_NOTIFICATIONS_LASTSCREEN)
					end
				end
			end
		end, function()
			if (loader:isDisplayed()) then
				Notifications.MessageLoadingInProgress = false
				loader:kill(true)
				loader:addAdaptedText(true, TB_MENU_LOCALIZED.ERRORTRYAGAIN)
			end
		end)
	return true
end

---Queues a network request to refresh total unread messages count
---@param forceReload? boolean
function Notifications:getTotalNotifications(forceReload)
	-- Update once per 2 minutes or with force reload
	if (Notifications.LastUpdate.count + 120 < os.clock_real() or forceReload) then
		Request:queue(function() get_notifications_count() end, "net_notifications", function()
				local count = utf8.gsub(get_network_response(), "TOTALMSGS[^%d]*(%d+)[^%d]*", "%1")
				TB_MENU_NOTIFICATIONS_UNREAD_COUNT = tonumber(count) or 0
				if (TB_MENU_NOTIFICATIONS_UNREAD_COUNT > 0) then
					local notificationsCountWidth = get_string_length("" .. (TB_MENU_NOTIFICATIONS_COUNT + TB_MENU_NOTIFICATIONS_UNREAD_COUNT), 4)
					notificationsCountWidth = notificationsCountWidth > TBMenu.NotificationsCount.size.h and (notificationsCountWidth > TBMenu.NotificationsCount.size.h * 2 and TBMenu.NotificationsCount.size.h * 2 or notificationsCountWidth) or TBMenu.NotificationsCount.size.h
					TBMenu.NotificationsCount.size.w = notificationsCountWidth
					TBMenu.NotificationsCount:moveTo(-notificationsCountWidth)
					TBMenu.NotificationsCount:show()
				end
			end)
		Notifications.LastUpdate.count = os.clock_real()
	end
end

---Displays main notifications screen
---@param viewElement UIElement
function Notifications:showNotifications(viewElement)
	usage_event("notifications")
	viewElement:kill(true)

	local elementHeight = 50
	local notificationsHolder = viewElement:addChild({
		pos = { 5, 0 },
		size = { viewElement.size.w * 0.4 - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(notificationsHolder, elementHeight, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)

	local notificationsHeader = topBar:addChild({
		pos = { 15, 8 },
		size = { topBar.size.w - 40 - topBar.size.h, topBar.size.h - 16 }
	})
	notificationsHeader:addAdaptedText(true, TB_MENU_LOCALIZED.NOTIFICATIONSHEADER, nil, nil, FONTS.BIG, LEFTMID)
	local notificationsReload = topBar:addChild({
		pos = { -topBar.size.h + 5, 5 },
		size = { topBar.size.h - 10, topBar.size.h - 10 },
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

	local notificationBody = viewElement:addChild({
		pos = { notificationsHolder.shift.x + notificationsHolder.size.w + 10, 0 },
		size = { viewElement.size.w - notificationsHolder.shift.x * 2 - notificationsHolder.size.w - 10, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:addBottomBloodSmudge(notificationBody, 2)

	if (#NotificationsInternal.NotificationsData == 0) then
		listingHolder:addAdaptedText(true, TB_MENU_LOCALIZED.NOTIFICATIONSEMPTY)
		return
	end

	local listElements = {}
	local selectedElement = nil
	for i, notification in pairs(NotificationsInternal.NotificationsData) do
		local notificationElement = UIElement:new({
			parent = listingHolder,
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, notificationElement)
		local notificationBG = UIElement:new({
			parent = notificationElement,
			pos = { 10, 2 },
			size = { notificationElement.size.w - 12, notificationElement.size.h - 4 },
			interactive = true,
			clickThrough = true,
			hoverThrough = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
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
			uiColor = notification.textColor
		})
		notificationTitle:addAdaptedText(true, notification.title, nil, nil, 4, LEFTMID, 0.7)
		if (unreadMark) then
			unreadMark.pmTitle = notificationTitle
		end
		local notificationFrom = notificationBG:addChild({
			pos = { notificationTitle.size.w + notificationTitle.shift.x + 10, 2 },
			size = { notificationBG.size.w - (notificationTitle.size.w + notificationTitle.shift.x + 10) - 10, notificationBG.size.h / 2 - 2 },
			uiColor = notification.nameColor
		})
		notificationFrom:addAdaptedText(notification.user, nil, nil, 4, RIGHTBOT, 0.7)
		local notificationDate = notificationBG:addChild({
			pos = { notificationTitle.size.w + notificationTitle.shift.x + 10, notificationFrom.shift.y + notificationFrom.size.h + 2 },
			size = { notificationBG.size.w - (notificationTitle.size.w + notificationTitle.shift.x + 10) - 10, notificationFrom.size.h },
			uiColor = { 1, 1, 1, 0.7}
		})
		notificationDate:addAdaptedText(true, notification.date, nil, nil, 4, RIGHT, 0.5)


		notificationBG:addMouseHandlers(nil, function()
				if (Notifications:loadNotificationText(notificationBody, notification, unreadMark)) then
					if (selectedElement) then
						selectedElement.bgColor = table.clone(TB_MENU_DEFAULT_DARKER_COLOR)
					end
					selectedElement = notificationBG
					selectedElement.bgColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR)
				end
			end)

		if (i == 1) then
			notificationBG.btnUp()
		end
	end
	for _, v in pairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	scrollBar:makeScrollBar(listingHolder, listElements, toReload)
end

---Refreshes notifications data and displays the main notifications screen on successful data update
---@param forceReload? boolean
function Notifications:prepareNotifications(forceReload)
	if (TBMenu.CurrentSection == nil or TBMenu.CurrentSection.destroyed) then
		TBMenu.CreateCurrentSectionView()
	else
		TBMenu.CurrentSection:kill(true)
	end

	if (forceReload or NotificationsInternal.NotificationsUser ~= PlayerInfo.Get().username) then
		Notifications.LastUpdate.data = -1000
	end

	if (Notifications.LastUpdate.data + 120 < os.clock_real()) then
		Notifications:getTotalNotifications(true)
		local notificationsMain = TBMenu.CurrentSection:addChild({
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
						TBMenu.NavigationBar:kill(true)
						TBMenu:showNavigationBar(Notifications:getNavigationButtons(), true, true, TB_MENU_NOTIFICATIONS_LASTSCREEN)
						Notifications:showNotifications(TBMenu.CurrentSection)
						Notifications.LastUpdate.data = os.clock_real()
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
		Notifications:showNotifications(TBMenu.CurrentSection)
	end
end

---Displays notifications tab in main menu. \
---If user has unclaimed login rewards, will always open rewards screen.
function Notifications:showMain()
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 4
	local rewards = PlayerInfo.getLoginRewards()
	local navButtons = Notifications:getNavigationButtons()
	if (rewards.available) then
		Notifications:showLoginRewards()
		TB_MENU_NOTIFICATIONS_LASTSCREEN = 1
		TBMenu:showNavigationBar(navButtons, true, true, 1)
	else
		for _, v in pairs(navButtons) do
			if (v.sectionId == TB_MENU_NOTIFICATIONS_LASTSCREEN) then
				v.action()
				TBMenu:showNavigationBar(navButtons, true, true, v.sectionId)
				return
			end
		end
	end
end
