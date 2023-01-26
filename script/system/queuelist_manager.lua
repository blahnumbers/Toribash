-- Queuelist Dropdown Menu
require("system.playerinfo_manager")
require("toriui.uielement3d")
require("system.friendlist_manager")
require("system.iofiles")
require("system.flag_manager")

---@class QueueListPlayerInfo : QueuePlayerInfo
---@field button UIElement UI button associated with the player
---@field id integer Player id in the queue
---@field spectator boolean Whether this player is a spectator
---@field isMe boolean
---@field pInfo PlayerInfo

---@class QueueListCachePlayers
---@field Bouts QueueListPlayerInfo[]
---@field Specs QueueListPlayerInfo[]
---@field total integer Cached total number of bouts + specs
---@field list UIElement
---@field listElements UIElement[]

---@class QueueListCache
---@field Room OnlineRoomInfo
---@field Players QueueListCachePlayers

if (QueueList == nil) then
	---**Queue list manager class**
	---
	---**Version 5.60:**
	---* Updates to match new language design
	---* Added documentation with EmmyLua annotations
	---@class QueueList
	---@field MainWindow UIElement
	---@field PopupWindow UIElement
	---@field Cache QueueListCache
	---@field Globalid integer
	QueueList = {
		Globalid = 1012,
		ver = 5.60
	}
	QueueList.__index = QueueList
end

---Helper class for **QueueList** manager
---@class QueueListInternal
local QueueListInternal = {
	listButtonHeight = 25
}
setmetatable({}, QueueListInternal)

---@class QueueListInfoField
---@field title string Internal title for the info field
---@field color string HEX encoded color for the badge
---@field text string Main text to show on the badge
---@field desc string Description text for the badge
---@field icon string Icon path

---List of all badges a user can have displayed
---@type QueueListInfoField
QueueListInternal.InfoFields = {
	{
		title = "legend",
		color = "BB9600",
		text = TB_MENU_LOCALIZED.QUEUELISTLEGENDTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTLEGENDDESC
	},
	{
		title = "muted",
		color = "808080",
		text = TB_MENU_LOCALIZED.QUEUELISTMUTEDTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTMUTEDDESC
	},
	{
		title = "helpsquad",
		color = "FA7E1A",
		text = TB_MENU_LOCALIZED.QUEUELISTTORIAGENTTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTTORIAGENTDESC
	},
	{
		title = "marketsquad",
		color = "3FA741",
		text = TB_MENU_LOCALIZED.QUEUELISTMARKETSQUADTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTMARKETSQUADDESC
	},
	{
		title = "eventsquad",
		color = "690069",
		text = TB_MENU_LOCALIZED.QUEUELISTEVENTSQUADTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTEVENTSQUADDESC
	},
	{
		title = "admin",
		color = "FF0000",
		text = TB_MENU_LOCALIZED.QUEUELISTINGAMEADMINTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTINGAMEADMINDESC
	},
	{
		title = "op",
		color = "00FF00",
		text = TB_MENU_LOCALIZED.QUEUELISTROOMOPTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTROOMOPDESC
	}
}

---Destroys currently displayed QueueList popup window
function QueueList.DestroyPopup()
	if (QueueList.PopupWindow) then
		QueueList.PopupWindow:kill()
		QueueList.PopupWindow = nil
	end
end

---Adds information about player to display
---@param viewElement UIElement
---@param info QueueListPlayerInfo
---@return number #Added elements' height
function QueueList:addPlayerInfos(viewElement, info)
	info.pInfo:getClan()

	local infosH = 35
	local nameHolder = viewElement:addChild({
		pos = { 75, 0 },
		size = { viewElement.size.w - 90, 35 }
	})
	nameHolder:addAdaptedText(nil, info.pInfo.username, nil, nil, FONTS.BIG, LEFTMID)

	local beltInfo = PlayerInfo.getBeltFromQi(info.games_played)
	local beltHolder = viewElement:addChild({
		pos = { 75, infosH },
		size = { viewElement.size.w - 90, 25 }
	})
	infosH = infosH + beltHolder.size.h
	beltHolder:addAdaptedText(true, beltInfo.name .. " Belt, " .. info.games_played .. " Qi", nil, nil, nil, LEFTMID)

	local clanHolder = nil
	if (info.pInfo.clan.id > 0) then
		clanHolder = UIElement:new({
			parent = viewElement,
			pos = { 0, infosH },
			size = { viewElement.size.w, 25 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		infosH = infosH + clanHolder.size.h
		local clanNameHolder = UIElement:new({
			parent = clanHolder,
			pos = { 75, 5 },
			size = { clanHolder.size.w - 90, clanHolder.size.h - 10 }
		})
		clanNameHolder:addAdaptedText(true, info.pInfo.clan.tag .. " " .. info.pInfo.clan.name .. (info.pInfo.clan.isleader and " (" .. TB_MENU_LOCALIZED.QUEUELISTDROPDOWNCLANLEADER .. ")" or ""), nil, nil, 4, LEFTMID, nil, 0.6)
		clanHolder:addMouseHandlers(nil, function()
				QueueList.DestroyPopup()
				ARG1 = "clans " .. info.nick
				open_menu(19)
			end)
	end

	local headPosY = (infosH - 60) / 2
	if (headPosY < 0) then
		headPosY = 0
	end
	local headHolder = UIElement:new({
		parent = viewElement,
		pos = { 0, headPosY },
		size = { 60, 60 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local headViewport = UIElement:new( {
		parent = headHolder,
		pos = { -70, -70 },
		size = { 80, 80 }
	})
	TBMenu:showPlayerHeadAvatar(headViewport, info.pInfo)

	if (clanHolder) then
		-- Reload to ensure clan button is above head viewport holder
		clanHolder:reload()
	end

	local titleHolder = UIElement:new({
		parent = viewElement,
		pos = { 0, infosH + 5 },
		size = { viewElement.size.w, 25 }
	})
	local titleShift = { x = 15, y = 0 }
	local displayed = 0
	for _, v in pairs(QueueListInternal.InfoFields) do
		if (type(info[v.title]) == "number" and info[v.title] > 0) then
			local r, g, b = unpack(get_color_from_hex(v.color))
			local color = { r = r, g = g, b = b }
			local titleDisplay = UIElement:new({
				parent = titleHolder,
				pos = { titleShift.x, titleShift.y },
				size = { 150, 20 },
				bgColor = { color.r, color.g, color.b, 1 },
				shapeType = ROUNDED,
				rounded = 10,
				uiColor = (math.max(color.r, color.g, color.b) > 0.95 or (color.r + color.g + color.b > 2)) and UICOLORBLACK or UICOLORWHITE
			})
			titleDisplay:addAdaptedText(false, v.text, 10, nil, 4, LEFTMID, 0.6)
			local titleTextLen = get_string_length(titleDisplay.dispstr[1], titleDisplay.textFont) * titleDisplay.textScale + 20
			titleDisplay.size.w = titleTextLen
			if (v.desc) then
				local helpPopupHolder = UIElement:new({
					parent = titleDisplay,
					pos = { 0, 0 },
					size = { titleDisplay.size.w, titleDisplay.size.h },
					interactive = true,
					bgColor = { 0, 0, 0, 0.01 },
					hoverColor = { 1, 1, 1, 0.2 },
					uiColor = UICOLORWHITE,
					shapeType = titleDisplay.shapeType,
					rounded = titleDisplay.rounded
				})
				local helpPopup = TBMenu:displayHelpPopup(helpPopupHolder, v.desc, nil, true)
				helpPopup:moveTo(math.min(-titleDisplay.size.w + (titleDisplay.size.w - helpPopup.size.w) / 2, helpPopup.shift.x))
				helpPopup:moveTo(nil, 25, true)
			end
			titleShift.x = titleShift.x + titleDisplay.size.w + 5
			if (titleShift.x > titleHolder.size.w) then
				titleShift.y = titleShift.y + titleDisplay.size.h + 3
				titleDisplay:moveTo(15, titleShift.y)
				titleShift.x = titleDisplay.size.w + 20
			end
			displayed = displayed + 1
		end
	end
	if (displayed > 0) then
		titleHolder.size.h = titleShift.y + 25
		infosH = infosH + titleHolder.size.h + 5
	else
		titleHolder:kill()
	end

	return infosH
end

---Loops through all players in the room to find current player and returns its info
---@return QueueListPlayerInfo|nil
function QueueList:getCurrentPlayerInfo()
	for _, v in pairs(QueueList.Cache.Players.Bouts) do
		if (v.isMe) then
			return v
		end
	end
	for _, v in pairs(QueueList.Cache.Players.Specs) do
		if (v.isMe) then
			return v
		end
	end
	return nil
end

---Retrieves player IP, bans it and kicks the player out of the room. \
---*This will only work if current user is an ingame administrator.*
---@param pName string
function QueueList:placeIPBan(pName)
	---Let's store time when this was called so that we can exit in case something goes wrong
	local clock = os.clock_real()
	add_hook("console", "queuelistipcheck", function(s, i)
			if (os.clock_real() - clock > 15) then
				remove_hooks("queuelistipcheck")
				return
			end

			if (i == 1) then
				if (s:find("^.*%d+ .+ Playing Authorized")) then
					local ip = s:gsub(" Playing Authorized$", "")
					ip = ip:gsub("^.*%d+ .* ", "")
					remove_hooks("queuelistipcheck")
					runCmd("ban silentadd " .. ip, true)
					runCmd("kick " .. pName, true)
				end
				return 1
			end
		end)
	runCmd("status " .. pName, true)
end

---Spawns a report window
---@param pName string
function QueueList:report(pName)
	local overlay = TBMenu:spawnWindowOverlay()
	overlay:addMouseHandlers(nil, function() overlay:kill() end)
	local reportHolder = overlay:addChild({
		shift = { WIN_W / 5, WIN_H / 2 - 220 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	local reportHeader = reportHolder:addChild({
		pos = { 50, 10 },
		size = { reportHolder.size.w - 100, 35 }
	})
	reportHeader:addAdaptedText(true, TB_MENU_LOCALIZED.REPORTSREPORTINGPLAYER .. ": " .. pName, nil, nil, FONTS.BIG)

	local reportClose = reportHolder:addChild({
		pos = { -40, 5 },
		size = { 35, 35 },
		shapeType = ROUNDED,
		rounded = 4,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	reportClose:addMouseHandlers(nil, overlay.btnUp)
	local reportCloseIcon = reportClose:addChild({
		shift = { 5, 5 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})

	local reportReasonHolder = reportHolder:addChild({
		pos = { 20, reportHeader.size.h + reportHeader.shift.y * 2 },
		size = { reportHolder.size.w - 40, 40 }
	})
	local reportReasonText = reportReasonHolder:addChild({
		pos = { 0, 0 },
		size = { reportReasonHolder.size.w / 4 - 10, reportReasonHolder.size.h },
		uiColor = { 1, 1, 1, 0.9 }
	})
	reportReasonText:addAdaptedText(true, TB_MENU_LOCALIZED.REPORTSREPORTREASON, nil, nil, 4, LEFTMID, 0.7)

	local reportReasonId = 0
	local reportDropdown = {
		{
			text = TB_MENU_LOCALIZED.REPORTSREASONHARASSMENT,
			action = function() reportReasonId = 0 end
		},
		{
			text = TB_MENU_LOCALIZED.REPORTSREASONSPAM,
			action = function() reportReasonId = 1 end
		},
		{
			text = TB_MENU_LOCALIZED.REPORTSREASONCHEATING,
			action = function() reportReasonId = 2 end
		},
		{
			text = TB_MENU_LOCALIZED.REPORTSREASONSCAMMING,
			action = function() reportReasonId = 3 end
		},
		{
			text = TB_MENU_LOCALIZED.REPORTSREASONOTHER,
			action = function() reportReasonId = 4 end
		},
	}
	local reportReasonDropdownBG = reportReasonHolder:addChild({
		pos = { reportReasonText.size.w, 0 },
		size = { reportReasonHolder.size.w - reportReasonText.size.w, reportReasonText.size.h },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local reportReasonDropdown = reportReasonDropdownBG:addChild({
		shift = { 1, 1 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
	}, true)
	TBMenu:spawnDropdown(reportReasonDropdown, reportDropdown, 30, WIN_H - 100, nil, { scale = 0.7 }, { scale = 0.6 })

	local extraMessageHolder = reportHolder:addChild({
		pos = { 20, reportReasonHolder.size.h + reportReasonHolder.shift.y + reportHeader.shift.y },
		size = { reportHolder.size.w - 40, reportHolder.size.h - reportReasonHolder.size.h - reportReasonHolder.shift.y - reportHeader.shift.y * 2 - 100 },
		uiColor = UICOLORWHITE
	})
	local extraMessageTitle = extraMessageHolder:addChild({
		size = { extraMessageHolder.size.w, 25 },
		uiColor = { 1, 1, 1, 0.9 }
	})
	extraMessageTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPORTSEXTRAMESSAGE, nil, nil, 4, LEFTMID, 0.7)

	local extraMessage = TBMenu:spawnTextField2(extraMessageHolder, {
			y = extraMessageTitle.size.h,
			h = extraMessageHolder.size.h - extraMessageTitle.size.h },
		nil, TB_MENU_LOCALIZED.REPORTSEXTRAMESSAGETIP, {
			fontId = FONTS.SMALL,
			textAlign = LEFT,
			allowMultiline = true,
			darkerMode = true
		})
	local chatlogInfo = reportHolder:addChild({
		pos = { 20, extraMessageHolder.size.h + extraMessageHolder.shift.y + 5 },
		size = { reportHolder.size.w - 40, 40 }
	})
	chatlogInfo:addAdaptedText(true, TB_MENU_LOCALIZED.REPORTSCHATLOGINFO .. "\n" .. TB_MENU_LOCALIZED.REPORTSABUSENOTICE, nil, nil, 4, LEFTMID, 0.6)
	local submitReport = reportHolder:addChild({
		pos = { reportHolder.size.w / 4, -50 },
		size = { reportHolder.size.w / 2, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	submitReport:addChild({ shift = { 15, 5 } }):addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONSUBMIT)

	local function showSubmitReport()
		local spawnTime = os.clock_real()
		local waitOverlay = reportHolder:addChild({
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			interactive = true
		}, true)
		local loadingMark = TBMenu:displayLoadingMark(waitOverlay, TB_MENU_LOCALIZED.MESSAGEPLEASEWAIT)

		local response = Request:queue(function()
				report_player(pName, reportReasonId .. "", extraMessage.textfieldstr[1], "")
			end, "reportPlayer" .. pName, function()
				local response = get_network_response()
				if (response:find("GATEWAY 0; 0")) then
					if (waitOverlay.destroyed or not waitOverlay:isDisplayed()) then
						TBMenu:showStatusMessage(reportReasonId == 3 and TB_MENU_LOCALIZED.REPORTSSUCCESSSCAMMING or TB_MENU_LOCALIZED.REPORTSSUCCESSDEFAULT, true)
						return
					end
					waitOverlay:kill(true)
					local successMessage = waitOverlay:addChild({
						pos = { 20, 10 },
						size = { waitOverlay.size.w - 40, waitOverlay.size.h / 2 - 10 }
					})
					successMessage:addAdaptedText(true, reportReasonId == 3 and TB_MENU_LOCALIZED.REPORTSSUCCESSSCAMMING or TB_MENU_LOCALIZED.REPORTSSUCCESSDEFAULT, nil, nil, nil, CENTERBOT)

					local shiftH, buttonH = 10, (waitOverlay.size.h / 2 - 20) / 2 > 50 and 50 or (waitOverlay.size.h / 2 - 20) / 2
					if (reportReasonId == 3) then
						local reportThreadId = response:gsub("GATEWAY 0; 0 ", "")
						local reportThread = waitOverlay:addChild({
							pos = { waitOverlay.size.w / 4, waitOverlay.size.h / 2 + shiftH },
							size = { waitOverlay.size.w / 2, buttonH },
							interactive = true,
							bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
							hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
							pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
						}, true)
						local reportThreadText = reportThread:addChild({
							shift = { reportThread.size.w * 0.05, reportThread.size.h * 0.1 },
						})
						TBMenu:showTextWithImage(reportThreadText, TB_MENU_LOCALIZED.REPORTSREPORTTHREAD .. ": ID " .. reportThreadId, FONTS.MEDIUM, reportThreadText.size.h, "../textures/menu/general/buttons/external.tga")
						reportThread:addMouseHandlers(nil, function() open_url("https://forum.toribash.com/showthread.php?t=" .. reportThreadId) end)
					else
						local discordButton = waitOverlay:addChild({
							pos = { waitOverlay.size.w / 4, waitOverlay.size.h / 2 + shiftH },
							size = { waitOverlay.size.w / 2, buttonH },
							interactive = true,
							bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
							hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
							pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
						}, true)
						local discordButtonText = discordButton:addChild({
							shift = { discordButton.size.w * 0.05, discordButton.size.h * 0.1 },
						})
						TBMenu:showTextWithImage(discordButtonText, TB_MENU_LOCALIZED.DISCORDSERVER, FONTS.MEDIUM, discordButtonText.size.h, "../textures/menu/logos/discord.tga")
						discordButton:addMouseHandlers(nil, function() open_url("https://discord.gg/toribash") end)
					end
					shiftH = shiftH * 2 + buttonH

					local exitButton = waitOverlay:addChild({
						pos = { waitOverlay.size.w / 4, waitOverlay.size.h / 2 + shiftH },
						size = { waitOverlay.size.w / 2, buttonH },
						interactive = true,
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
						hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
					}, true)
					local exitButtonText = exitButton:new({
						shift = { exitButton.size.w * 0.05, exitButton.size.h * 0.1 },
					})
					exitButtonText:addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONCLOSEWINDOW)
					exitButton:addMouseHandlers(nil, overlay.btnUp)
				else
					waitOverlay:kill()
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ACCOUNTINFOERROR, true)
				end
			end, function()
				waitOverlay:kill()
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ACCOUNTINFOERROR, true)
			end)

		local slowResponseWaiter = waitOverlay:addChild({})
		slowResponseWaiter:addCustomDisplay(function()
			if (UIElement.clock - spawnTime > 10 and not response.ready) then
				if (loadingMark.textView ~= nil) then
					loadingMark.textView:addAdaptedText(true, TB_MENU_LOCALIZED.REPORTSLONGWAITMESSAGE)
				end
				slowResponseWaiter:kill()
			end
		end)
	end
	submitReport:addMouseHandlers(nil, function()
			TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPORTSCONFIRMATION .. " " .. pName .. "?\n" .. TB_MENU_LOCALIZED.REPORTSABUSENOTICE, showSubmitReport)
		end)
end

---Shows player nudging options
---@param pName string
---@param viewElement UIElement
---@param info QueueListPlayerInfo
function QueueList:showNudge(pName, viewElement, info)
	viewElement:kill(true)
	viewElement:deactivate()
	local buttons = {
		{
			name = "defualt",
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGECHOOSE,
			default = true
		},
		{
			name = "nudgeup",
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGEUP,
			action = function() runCmd("nudgeup " .. pName, true) QueueList.DestroyPopup() end
		},
		{
			name = "nudgedown",
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGEDOWN,
			action = function() runCmd("nudgedown " .. pName, true) QueueList.DestroyPopup() end
		},
		{
			name = "nudgetopos",
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGECUSTOM,
			action = function() QueueList:showNudgeToPosition(pName, viewElement, info) end
		}
	}

	local colorOverlay = viewElement:addChild({
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	local dropdownHolder = colorOverlay:addChild({
		shift = { 5, 0 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	TBMenu:spawnDropdown(dropdownHolder, buttons, 30, nil, nil, { scale = 0.6 }, { scale = 0.5 })
end

---Shows nudge player to position controls
---@param pName string
---@param viewElement UIElement
---@param info QueueListPlayerInfo
function QueueList:showNudgeToPosition(pName, viewElement, info)
	viewElement:kill(true)

	local textField = TBMenu:spawnTextField2(viewElement, {
			x = 5, w = viewElement.size.w - 100
		}, (info.id - 1) .. "", TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGETOPOSITION, {
			fontId = FONTS.SMALL,
			textAlign = LEFTMID,
			isNumeric = true
		})
	local function nudge()
		runCmd("nudge " .. pName .. " " .. textField.textfieldstr[1], true)
	end
	textField:addEnterAction(nudge)

	local button = viewElement:addChild({
		pos = { -100, 0 },
		size = { 95, viewElement.size.h },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	local buttonText = button:addChild({
		shift = { 15, 5 }
	})
	buttonText:addAdaptedText(true, TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGE, nil, nil, 4)
	button:addMouseHandlers(nil, function() nudge() QueueList.DestroyPopup() end)
end

---Spawns main QueueList window controls
---@param viewElement UIElement
---@param info QueueListPlayerInfo Target player's queue info
---@param userinfo QueuePlayerInfo Local player's queue info
---@return integer #Added buttons' height
function QueueList:addPlayerControls(viewElement, info, userinfo)
	if (not FRIENDSLIST_FRIENDS) then
		FriendsList:getFriends()
	end
	local isFriend = false
	for _, v in pairs(FRIENDSLIST_FRIENDS) do
		if (v.username:lower() == info.pInfo.username) then
			isFriend = true
		end
	end
	local isIgnored = false
	for _, v in pairs(FRIENDSLIST_IGNORE) do
		if (v:lower() == info.pInfo.username) then
			isIgnored = true
		end
	end

	local showControls, showAdvControls = false, false
	if (userinfo.admin ~= 0 or userinfo.eventsquad ~= 0 or userinfo.helpsquad ~= 0) then
		userinfo.ingameadmin = true
		showControls = true
		showAdvControls = true
	elseif (userinfo.op ~= 0) then
		showControls = true
	end
	if (info.admin ~= 0 or info.eventsquad ~= 0 or info.helpsquad ~= 0) then
		info.ingameadmin = true
	end

	local buttons = {
		{
			name = "whisper",
			show = not isIgnored,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNWHISPER,
			action = function(s) runCmd("whisper " .. s) end
		},
		{
			name = "addfriend",
			show = not isFriend,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNADDFRIEND,
			action = function(s) FriendsList:addFriend(s) end
		},
		{
			name = "removefriend",
			show = isFriend,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNREMOVEFRIEND,
			action = function(s) FriendsList:removeFriend(s) end
		},
		{
			name = "ignore",
			show = not isIgnored,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNIGNORE,
			action = function(s) FriendsList:addIgnore(s) end
		},
		{
			name = "unignore",
			show = isIgnored,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNUNIGNORE,
			action = function(s) FriendsList:removeIgnore(s) end
		},
		{
			name = "report",
			show = true,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNREPORT,
			action = function(s) QueueList:report(s) end
		}
	}
	local cButtons = {
		{
			name = "mute",
			show = info.muted == 0 and info.op == 0 and not info.ingameadmin,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNMUTE,
			action = function(s) runCmd("mute " .. s, true) end
		},
		{
			name = "unmute",
			show = info.muted ~= 0,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNUNMUTE,
			action = function(s) runCmd("unmute " .. s, true) end
		},
		{
			name = "op",
			show = info.op == 0 and not info.ingameadmin,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNOP,
			action = function(s) runCmd("op " .. s, true) end
		},
		{
			name = "deop",
			show = info.op ~= 0 and not info.ingameadmin,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNDEOP,
			action = function(s) runCmd("deop " .. s, true) end
		},
		{
			name = "fspec",
			show = not info.spectator,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNFSPEC,
			action = function(s) runCmd("fspec " .. s, true) end
		},
		{
			name = "fenter",
			show = info.spectator,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNFENTER,
			action = function(s) runCmd("fenter " .. s, true) end
		},
		{
			name = "nudge",
			show = not info.spectator and info.id > get_game_rules().numplayers,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGETOPOSITION,
			action = function(s, b) QueueList:showNudge(s, b, info) return 1 end
		},
		{
			name = "kick",
			show = not info.ingameadmin,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNKICK,
			action = function(s) runCmd("kick " .. s, true) end
		},
		{
			name = "ban",
			show = not info.ingameadmin,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNBAN,
			action = function(s) runCmd("ban add " .. s, true) end
		},
		{
			name = "ipban",
			show = showAdvControls and not info.ingameadmin,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNIPBAN,
			action = function(s) QueueList:placeIPBan(s) end
		}
	}
	local gButtons = {
		{
			name = "default",
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNMASSCONTROLS,
			default = true,
		},
		{
			name = "scramble",
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNSCRAMBLE,
			action = function() TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.QUEUELISTDROPDOWNSCRAMBLECONFIRM, function() runCmd("scramble", true) QueueList.DestroyPopup() end) return 1 end
		},
		{
			name = "specall",
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNSPECTATEALL,
			action = function() TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.QUEUELISTDROPDOWNSPECALLCONFIRM, function() runCmd("specall", true) QueueList.DestroyPopup() end) return 1 end
		},
		{
			name = "muteall",
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNMUTEALL,
			action = function() runCmd("muteall", true) QueueList.DestroyPopup() end
		},
		{
			name = "unmuteall",
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNUNMUTEALL,
			action = function() runCmd("unmuteall", true) QueueList.DestroyPopup() end
		},
	}

	local infoH, buttonH = viewElement.size.h + 5, 25
	if (not info.isMe) then
		local separator = viewElement:addChild({
			pos = { 20, viewElement.size.h + 2 },
			size = { viewElement.size.w - 40, 1 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})

		for _, v in pairs(buttons) do
			if (v.show) then
				local contextButton = viewElement:addChild({
					pos = { 0, infoH },
					size = { viewElement.size.w, buttonH },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				})
				local textHolder = contextButton:addChild({
					shift = { 15, 5 }
				})
				textHolder:addAdaptedText(true, v.text, nil, nil, 4, LEFTMID)
				contextButton:addMouseHandlers(nil, function()
						local rVal = v.action(info.pInfo.username)
						if (not rVal) then
							QueueList.DestroyPopup()
						elseif (rVal == 2) then
							QueueList.DestroyPopup()
						end
					end)
				infoH = infoH + buttonH
			end
		end
	end

	if (showControls) then
		local cSeparator = UIElement:new({
			parent = viewElement,
			pos = { 20, infoH + 2 },
			size = { viewElement.size.w - 40, 1 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		infoH = infoH + 5

		for _, v in pairs(cButtons) do
			if (v.show) then
				local contextButton = viewElement:addChild({
					pos = { 0, infoH },
					size = { viewElement.size.w, buttonH },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				})
				local textHolder = contextButton:addChild({
					shift = { 15, 5 }
				})
				textHolder:addAdaptedText(true, v.text, nil, nil, 4, LEFTMID)
				contextButton:addMouseHandlers(nil, function()
						if (not v.action(info.pInfo.username)) then
							QueueList.DestroyPopup()
						end
					end)
				infoH = infoH + buttonH
			end
		end

		local gSeparator = UIElement:new({
			parent = viewElement,
			pos = { 20, infoH + 2 },
			size = { viewElement.size.w - 40, 1 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		infoH = infoH + 5

		local globalControls = UIElement:new({
			parent = viewElement,
			pos = { 0, infoH },
			size = { viewElement.size.w, buttonH }
		})
		local globalControlsHolder = UIElement:new({
			parent = globalControls,
			pos = { 0, 0 },
			size = { viewElement.size.w, buttonH },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:spawnDropdown(globalControlsHolder, gButtons, buttonH, nil, nil, { scale = 0.6 }, { scale = 0.6 })

		infoH = infoH + buttonH + 2
	end

	return infoH
end

---Returns length of the longest name in the queue list
---@return number
function QueueList:getHorizontalShift()
	local maxW = 0
	for _, v in pairs(get_bouts()) do
		local w = get_string_length(v, FONTS.SMALL)
		maxW = math.max(maxW, w)
	end
	for _, v in pairs(get_spectators()) do
		local w = get_string_length(v, FONTS.SMALL)
		maxW = math.max(maxW, w)
	end
	return maxW
end

---Spawns player info display window
---@param info QueueListPlayerInfo
function QueueList:show(info)
	local userinfo = QueueList:getCurrentPlayerInfo()
	if (not info or not userinfo) then
		return
	end
	local pName = PlayerInfo.Get(info.nick).username
	local customs = Files:open("../custom/" .. pName:lower() .. "/item.dat", FILES_MODE_READONLY)
	if (not customs.data) then
		download_head(pName)
	end
	customs:close()

	if (QueueList.PopupWindow ~= nil) then
		QueueList.DestroyPopup()
	end
	QueueList.PopupWindow = UIElement:new({
		globalid = QueueList.Globalid,
		pos = { 0, 0 },
		size = { WIN_W, WIN_H },
		interactive = true
	})
	QueueList.PopupWindow:addMouseHandlers(nil, QueueList.DestroyPopup, nil, QueueList.DestroyPopup)

	local hShift = QueueList:getHorizontalShift()
	local posX = MOUSE_X > WIN_W - 30 - hShift and WIN_W - 30 - hShift or MOUSE_X

	local queuelistBoxBG = QueueList.PopupWindow:addChild({
		pos = { posX - WIN_W / 5, MOUSE_Y - 10 },
		size = { WIN_W / 5, 60 }, -- 60 is basic player info, for other buttons it's going to be incremented as they're added
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true
	})
	local queuelistBox = UIElement:new({
		parent = queuelistBoxBG,
		pos = { 1, 1 },
		size = { queuelistBoxBG.size.w - 2, queuelistBoxBG.size.h - 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	queuelistBox.size.h = QueueList:addPlayerInfos(queuelistBox, info)
	queuelistBox.size.h = QueueList:addPlayerControls(queuelistBox, info, userinfo)


	queuelistBoxBG.size.h = queuelistBox.size.h + 2
	if (queuelistBoxBG.size.h + queuelistBoxBG.pos.y + 10 > WIN_H) then
		queuelistBoxBG:moveTo(nil, WIN_H - queuelistBoxBG.size.h - 10)
	end
end

function QueueList.Destroy()
	QueueList.DestroyPopup()
	if (QueueList.MainElement) then
		QueueList.MainElement:kill()
		QueueList.MainElement = nil
	end
	QueueList.ResetCache()
end

function QueueList.ReloadMainView()
	if (QueueList.MainElement ~= nil) then
		QueueList.MainElement:kill()
		QueueList.MainElement = nil
	end

	local x, y, w, h = get_window_safe_size()
	local x = math.max(x, WIN_W - w - x) + 15
	local listWidth = 500
	QueueList.MainElement = UIElement:new({
		globalid = QueueList.Globalid,
		pos = { WIN_W - listWidth - x, 150 },
		size = { listWidth, WIN_H - 400 }
	})
	local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(QueueList.MainElement, 1, 1, 8, { 0, 0, 0, 0 })
	QueueListInternal.ListHolder = listingHolder
	QueueListInternal.ListElements = {}

	QueueListInternal.ListScrollbar = TBMenu:spawnScrollBar(QueueListInternal.ListHolder, 100, QueueListInternal.listButtonHeight)
	QueueListInternal.ListScrollbar:makeScrollBar(QueueListInternal.ListHolder, QueueListInternal.ListElements, toReload)
end

---Wrapper function to retrieve bout information by id
---@param id integer
---@return QueueListPlayerInfo|nil
function QueueListInternal.getBoutInfo(id)
	if (id < 0) then
		return nil
	end

	---@type QueueListPlayerInfo
	---@diagnostic disable-next-line: assign-type-mismatch
	local bout = get_bout_info(id)
	if (bout == nil) then
		return nil
	end

	bout.id = id
	bout.spectator = false
	bout.pInfo = PlayerInfo.Get(bout.nick)
	bout.isMe = bout.pInfo.username == TB_MENU_PLAYER_INFO.username
	return bout
end

---Wrapper function to retrieve spec information by id
---@param id integer
---@return QueueListPlayerInfo|nil
function QueueListInternal.getSpecInfo(id)
	if (id < 0) then
		return nil
	end

	---@type QueueListPlayerInfo
	---@diagnostic disable-next-line: assign-type-mismatch
	local spec = get_spectator_info(id)
	if (spec == nil) then
		return nil
	end

	spec.id = id
	spec.spectator = true
	spec.pInfo = PlayerInfo.Get(spec.nick)
	spec.isMe = spec.pInfo.username == TB_MENU_PLAYER_INFO.username
	return spec
end

---Resets cache to its default state
function QueueList.ResetCache()
	QueueList.Cache = {
		Players = {
			Bouts = { },
			Specs = { },
			total = 0
		},
		Room = nil
	}
end

---Returns name color for the player
---@param playerInfo QueueListPlayerInfo
function QueueListInternal.getNameColor(playerInfo)
	if (playerInfo.admin ~= 0) then
		return { 0.55, 0.05, 0.05, 1 } -- TB_MENU_DEFAULT_DARKER_COLOR
	elseif (playerInfo.eventsquad ~= 0) then
		return { 0.684, 0.129, 0.949, 1 }
	elseif (playerInfo.helpsquad ~= 0) then
		return { 0.996, 0.496, 0.031, 1 }
	elseif (playerInfo.marketsquad ~= 0) then
		return { 0.027, 0.598, 0, 1 }
	elseif (playerInfo.eventsquad_trial ~= 0) then
		return { 0.625, 0.395, 0.719, 1 }
	elseif (playerInfo.isMe) then
		return { 0, 1, 0, 1 }
	elseif (not playerInfo.spectator and playerInfo.id == 0) then
		return { 0.67, 0.11, 0.11, 1 } -- Tori, TB_MENU_DEFAULT_BG_COLOR
	elseif (not playerInfo.spectator and playerInfo.id == 1) then
		return { 0.242, 0.626, 1, 1 } -- Uke, TB_MENU_DEFAULT_BLUE
	end
	return { 0, 0, 0, 1 }
end

---Returns status icon atlas information for the user
---@param info QueueListPlayerInfo
---@return AtlasData|nil
function QueueListInternal.GetStatusIcon(info)
	---@type Rect
	local atlasInfo = { y = 0, h = 64, w = 64 }
	if (info.admin ~= 0) then
		atlasInfo.x = 0
	elseif (info.eventsquad ~= 0 or info.eventsquad_trial ~= 0) then
		atlasInfo.x = 64
	elseif (info.marketsquad ~= 0) then
		atlasInfo.x = 128
	elseif (info.helpsquad ~= 0) then
		atlasInfo.x = 192
	elseif (info.legend ~= 0) then
		atlasInfo.x = 256
	else
		return nil
	end

	return {
		filename = "../textures/statusicons.tga",
		atlas = atlasInfo
	}
end

---Adds a player to the queue list cache
---@param id integer
---@param name string
---@param bouts ?integer
---@param spectator ?boolean
function QueueList.AddPlayer(id, name, bouts, spectator)
	local playerInfo = spectator and QueueListInternal.getSpecInfo(id - 1) or QueueListInternal.getBoutInfo(id - 1)
	if (playerInfo == nil) then
		return
	end

	local targetTable = spectator and QueueList.Cache.Players.Specs or QueueList.Cache.Players.Bouts
	if (targetTable[id] ~= nil) then
		if (targetTable[id].button ~= nil) then
			targetTable[id].button:kill()
			targetTable[id].button = nil
		end
		targetTable[id] = playerInfo
	else
		table.insert(targetTable, id, playerInfo)
	end

	local listId = playerInfo.id
	if (spectator) then
		listId = bouts + playerInfo.id
	end

	playerInfo.button = QueueListInternal.ListHolder:addChild({
		pos = { 0, listId * QueueListInternal.listButtonHeight },
		size = { QueueList.MainElement.size.w, QueueListInternal.listButtonHeight },
		bgColor = QueueListInternal.getNameColor(playerInfo),
		interactive = true,
		clickThrough = true,
		hoverThrough = true
	})
	playerInfo.button.bgColor[4] = spectator and 0.5 or 0.9
	playerInfo.button.hoverColor = table.clone(playerInfo.button.bgColor)
	playerInfo.button.hoverColor[4] = playerInfo.button.hoverColor[4] + 0.1
	playerInfo.button.pressedColor = table.clone(playerInfo.button.hoverColor)

	---Cache text caption
	playerInfo.button:addAdaptedText(true, name, nil, nil, FONTS.SMALL, RIGHTMID, 1)
	playerInfo.button:addCustomDisplay(true, function()
			local shadow = nil
			if (playerInfo.button.hoverState ~= BTN_NONE) then
				set_mouse_cursor(1)
				shadow = 1
			end

			---Shift it 2 pixels up because otherwise it looks kinda off with our font
			local buttonColor = playerInfo.button:getButtonColor()
			local shadowColor = { buttonColor[1], buttonColor[2], buttonColor[3], 0.5 }
			playerInfo.button:uiText(playerInfo.button.str, nil, -2, playerInfo.button.textFont, RIGHTMID, playerInfo.button.textScale, nil, shadow, buttonColor, shadowColor)
		end)

	playerInfo.button:addMouseUpHandler(function()
			QueueList:show(playerInfo)
		end)
	playerInfo.button:addMouseUpRightHandler(function()
			QueueList:show(playerInfo)
		end)

	local flagScale = 16
	playerInfo.button.size.w = get_string_length(playerInfo.button.dispstr[1], playerInfo.button.textFont) * playerInfo.button.textScale + 5
	playerInfo.button:moveTo(-playerInfo.button.size.w - flagScale - 10)

	local flagInfo = FlagManager.GetFlagInfoByCode(playerInfo.flag_code)
	local playerFlag = playerInfo.button:addChild({
		pos = { playerInfo.button.size.w + 5, (playerInfo.button.size.h - flagScale) / 2 },
		size = { flagScale, flagScale },
		bgImage = flagInfo.filename,
		imageAtlas = true,
		atlas = flagInfo.atlas
	})

	local statusIcon = QueueListInternal.GetStatusIcon(playerInfo)
	if (statusIcon ~= nil) then
		local playerStatus = playerInfo.button:addChild({
			pos = { -playerInfo.button.size.w - playerInfo.button.size.h + 2, 0 },
			size = { playerInfo.button.size.h, playerInfo.button.size.h },
			bgImage = statusIcon.filename,
			imageAtlas = true,
			atlas = statusIcon.atlas
		})
	end
end

---Reloads queue list display with the new values
---@param reinit ?boolean
function QueueList.Reload(reinit)
	local roomInfo = get_room_info()
	if (roomInfo == nil) then
		QueueList.Destroy()
		return
	end

	if (QueueList.Cache.Room == nil or roomInfo.ip ~= QueueList.Cache.Room.ip) then
		---This is the first launch or we are in a new room, reset cache
		QueueList.ResetCache()
		QueueList.ReloadMainView()
	elseif (QueueList.MainElement == nil or reinit == true) then
		QueueList.ReloadMainView()
	end
	QueueList.Cache.Room = roomInfo

	local bouts = get_bouts()
	local numBouts = #bouts
	for i, v in pairs(bouts) do
		if (QueueList.Cache.Players.Bouts[i] == nil or v ~= QueueList.Cache.Players.Bouts[i].nick) then
			QueueList.AddPlayer(i, v)
		end
	end
	while (QueueList.Cache.Players.Bouts[numBouts + 1] ~= nil) do
		QueueList.Cache.Players.Bouts[numBouts + 1].button:kill()
		table.remove(QueueList.Cache.Players.Bouts, #bouts + 1)
	end

	local spectators = get_spectators()
	for i, v in pairs(spectators) do
		if (QueueList.Cache.Players.Specs[i] == nil or v ~= QueueList.Cache.Players.Specs[i].nick) then
			QueueList.AddPlayer(i, v, numBouts, true)
		else
			QueueList.Cache.Players.Specs[i].button:moveTo(nil, (numBouts + i - 1) * QueueListInternal.listButtonHeight)
		end
	end
	while (QueueList.Cache.Players.Specs[#spectators + 1] ~= nil) do
		QueueList.Cache.Players.Specs[#spectators + 1].button:kill()
		table.remove(QueueList.Cache.Players.Specs, #spectators + 1)
	end

	for i = #QueueListInternal.ListElements, 1, -1 do
		table.remove(QueueListInternal.ListElements, i)
	end
	for _, v in pairs(QueueList.Cache.Players.Bouts) do
		table.insert(QueueListInternal.ListElements, v.button)
		v.button:hide(true)
	end
	for _, v in pairs(QueueList.Cache.Players.Specs) do
		table.insert(QueueListInternal.ListElements, v.button)
		v.button:hide(true)
	end

	QueueListInternal.ListScrollbar.size.h = math.max(0.1, math.min(1, (QueueListInternal.ListHolder.size.h) / (#QueueListInternal.ListElements * QueueListInternal.listButtonHeight) or QueueListInternal.ListHolder.size.h)) * QueueListInternal.ListScrollbar.parent.size.h
	QueueListInternal.ListScrollbar.listReload()
	if (QueueListInternal.ListScrollbar.size.h == QueueListInternal.ListScrollbar.parent.size.h) then
		QueueListInternal.ListScrollbar:hide(true)
	else
		QueueListInternal.ListScrollbar:show(true)
	end

	QueueList.Cache.Players.total = #QueueList.Cache.Players.Bouts + #QueueList.Cache.Players.Specs

	if (QueueList.PopupWindow ~= nil) then
		QueueList.PopupWindow:reload()
	end
end

---Initializes the script and sets the default values
function QueueList.Init()
	QueueList.ResetCache()
	QueueList.Reload()
end

QueueList.Init()
add_hook("new_game", "queuelistManager", QueueList.Reload)
add_hook("new_mp_game", "queuelistManager", QueueList.Reload)
add_hook("bout_update", "queuelistManager", QueueList.Reload)
add_hook("spec_update", "queuelistManager", QueueList.Reload)
add_hook("resolution_changed", "queuelistManager", function() QueueList.Reload(true) end)
