-- Queuelist Dropdown Menu
require("system.playerinfo_manager")
require("toriui.uielement3d")
require("system.friendlist_manager")
require("system.iofiles")

---@class QueueListPlayerInfo : QueuePlayerInfo
---@field id integer Player id in the queue

if (QueueList == nil) then
	---**Queue list manager class**
	---
	---**Version 5.60:**
	---* Updates to match new language design
	---* Added documentation with EmmyLua annotations
	---@class QueueList
	---@field MainElement UIElement
	QueueList = {
		ver = 5.60,
		__index = {}
	}
	QueueList.__index = QueueList
	local cln = {}
	setmetatable(cln, QueueList)
end

local QueueListInternal = {}
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

---Destroys currently displayed QueueList window
---@param keepHook ?boolean
function QueueList:quit(keepHook)
	if (not keepHook) then
		remove_hooks("queuelistKeyboard")
		chat_input_activate()
	end

	if (QueueList.MainElement) then
		QueueList.MainElement:kill()
		QueueList.MainElement = nil
	end
end

function QueueList:addPlayerInfos(viewElement, info, bout)
	local playerInfo = PlayerInfo.Get(info.nick)
	playerInfo:getClan()

	local infosH = 35
	local nameHolder = viewElement:addChild({
		pos = { 75, 0 },
		size = { viewElement.size.w - 90, 35 }
	})
	nameHolder:addAdaptedText(nil, playerInfo.username, nil, nil, FONTS.BIG, LEFTMID)

	local beltInfo = PlayerInfo.getBeltFromQi(info.games_played)
	local beltHolder = viewElement:addChild({
		pos = { 75, infosH },
		size = { viewElement.size.w - 90, 25 }
	})
	infosH = infosH + beltHolder.size.h
	beltHolder:addAdaptedText(true, beltInfo.name .. " Belt, " .. info.games_played .. " Qi", nil, nil, nil, LEFTMID)

	local clanHolder = nil
	if (playerInfo.clan.id > 0) then
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
		clanNameHolder:addAdaptedText(true, playerInfo.clan.tag .. " " .. playerInfo.clan.name .. (playerInfo.clan.isleader and " (" .. TB_MENU_LOCALIZED.QUEUELISTDROPDOWNCLANLEADER .. ")" or ""), nil, nil, 4, LEFTMID, nil, 0.6)
		clanHolder:addMouseHandlers(nil, function()
				QueueList:quit()
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
		size = { 80, 80 },
		viewport = true
	})
	TBMenu:showPlayerHeadAvatar(headViewport, playerInfo)

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
---@return QueuePlayerInfo|nil
function QueueList:getCurrentPlayerInfo()
	local currentPlayerLower = PlayerInfo.Get().username:lower()
	for i, v in pairs(get_bouts()) do
		if (PlayerInfo.Get(v).username:lower() == currentPlayerLower) then
			return get_bout_info(i - 1)
		end
	end
	for i, v in pairs(get_spectators()) do
		if (PlayerInfo.Get(v).username:lower() == currentPlayerLower) then
			return get_spectator_info(i - 1)
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
			action = function() runCmd("nudgeup " .. pName, true) QueueList:quit() end
		},
		{
			name = "nudgedown",
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGEDOWN,
			action = function() runCmd("nudgedown " .. pName, true) QueueList:quit() end
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
	button:addMouseHandlers(nil, function() nudge() QueueList:quit() end)
end

---Spawns main QueueList window controls
---@param viewElement UIElement
---@param info QueueListPlayerInfo Target player's queue info
---@param userinfo QueuePlayerInfo Local player's queue info
---@param bout boolean
---@return integer #Added buttons' height
function QueueList:addPlayerControls(viewElement, info, userinfo, bout)
	local pName = PlayerInfo.Get(info.nick).username:lower()
	if (not FRIENDSLIST_FRIENDS) then
		FriendsList:getFriends()
	end
	local isFriend = false
	for _, v in pairs(FRIENDSLIST_FRIENDS) do
		if (v.username:lower() == pName) then
			isFriend = true
		end
	end
	local isIgnored = false
	for _, v in pairs(FRIENDSLIST_IGNORE) do
		if (v:lower() == pName) then
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

	local isUser = PlayerInfo.Get().username:lower() == pName

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
			show = bout,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNFSPEC,
			action = function(s) runCmd("fspec " .. s, true) end
		},
		{
			name = "fenter",
			show = not bout,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNFENTER,
			action = function(s) runCmd("fenter " .. s, true) end
		},
		{
			name = "nudge",
			show = bout and info.id > 1,
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
			action = function() TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.QUEUELISTDROPDOWNSCRAMBLECONFIRM, function() runCmd("scramble", true) QueueList:quit() end) return 1 end
		},
		{
			name = "specall",
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNSPECTATEALL,
			action = function() TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.QUEUELISTDROPDOWNSPECALLCONFIRM, function() runCmd("specall", true) QueueList:quit() end) return 1 end
		},
		{
			name = "muteall",
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNMUTEALL,
			action = function() runCmd("muteall", true) QueueList:quit() end
		},
		{
			name = "unmuteall",
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNUNMUTEALL,
			action = function() runCmd("unmuteall", true) QueueList:quit() end
		},
	}

	local infoH, buttonH = viewElement.size.h + 5, 25
	if (not isUser) then
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
						local rVal = v.action(pName)
						if (not rVal) then
							QueueList:quit()
						elseif (rVal == 2) then
							QueueList:quit(true)
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
						if (not v.action(pName)) then
							QueueList:quit()
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
---@param bout boolean
---@param id integer
function QueueList:show(info, bout, id)
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

	if (QueueList.MainElement ~= nil) then
		QueueList:quit()
	end
	QueueList.MainElement = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { 0, 0 },
		size = { WIN_W, WIN_H },
		interactive = true
	})
	QueueList.MainElement:addMouseHandlers(nil, QueueList.quit, nil, QueueList.quit)

	local hShift = QueueList:getHorizontalShift()
	local posX = MOUSE_X > WIN_W - 30 - hShift and WIN_W - 30 - hShift or MOUSE_X

	local queuelistBoxBG = QueueList.MainElement:addChild({
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
	queuelistBox.size.h = QueueList:addPlayerInfos(queuelistBox, info, bout)
	queuelistBox.size.h = QueueList:addPlayerControls(queuelistBox, info, userinfo, bout)


	queuelistBoxBG.size.h = queuelistBox.size.h + 2
	if (queuelistBoxBG.size.h + queuelistBoxBG.pos.y + 10 > WIN_H) then
		queuelistBoxBG:moveTo(nil, WIN_H - queuelistBoxBG.size.h - 10)
	end
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
	return bout
end

---Wrapper functio nto retrieve spec information by id
---@param id integer
---@return QueueListPlayerInfo|nil
function QueueListInternal.getSpecInfo(id)
	if (id < 0) then
		return nil
	end

	---@diagnostic disable-next-line: return-type-mismatch
	return get_spectator_info(id)
end

add_hook("bout_mouse_up", "queuelistManager", function(id)
	local boutInfo = QueueListInternal.getBoutInfo(id)
	if (boutInfo ~= nil) then
		QueueList:show(boutInfo, true, id)
	end
end)
add_hook("spec_mouse_up", "queuelistManager", function(id)
	local specInfo = QueueListInternal.getSpecInfo(id)
	if (specInfo ~= nil) then
		QueueList:show(specInfo, false, id)
	end
end)
