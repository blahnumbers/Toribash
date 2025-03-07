require("system.iofiles")
require("system.playerinfo_manager")
require("toriui.uielement3d")
require("system.flag_manager")
require("system.friends_manager")

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
	---**Version 5.70**
	---* Added `HookName` field
	---
	---**Version 5.62:**
	---* New ignore functionality
	---* Queue list dropdown menu size tweaks
	---
	---**Version 5.61:**
	---* Automatically open chat with the new tab when whispering user
	---
	---**Version 5.60:**
	---* Updates to match new language design
	---* Added documentation with EmmyLua annotations
	---@class QueueList
	---@field MainWindow UIElement
	---@field PopupWindow UIElement
	---@field Cache QueueListCache
	---@field LastHudOption number
	---@field Globalid integer
	QueueList = {
		Globalid = 1012,
		PopupWidth = math.min(WIN_W * 0.22, 450),
		LastHudOption = 1,
		HookName = "__tbQueueListManager",
		ver = 5.70
	}
	QueueList.__index = QueueList
end

---Helper class for **QueueList** manager
---@class QueueListInternal
local QueueListInternal = {
	listButtonHeight = 25
}

---@class QueueListInfoField
---@field title string Internal title for the info field
---@field color Color Badge color
---@field text string Main text to show on the badge
---@field desc string Description text for the badge
---@field icon string Icon path
---@field atlasX integer Icon spreadsheet X shift

---List of all badges a user can have displayed
---@type QueueListInfoField
QueueListInternal.InfoFields = {
	{
		title = "eventsquad",
		color = { 0.684, 0.129, 0.949, 1 },
		text = TB_MENU_LOCALIZED.QUEUELISTEVENTSQUADTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTEVENTSQUADDESC,
		atlasX = 64
	},
	{
		title = "helpsquad",
		color = { 0.996, 0.496, 0.031, 1 },
		text = TB_MENU_LOCALIZED.QUEUELISTTORIAGENTTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTTORIAGENTDESC,
		atlasX = 192
	},
	{
		title = "marketsquad",
		color = { 0.027, 0.598, 0, 1 },
		text = TB_MENU_LOCALIZED.QUEUELISTMARKETSQUADTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTMARKETSQUADDESC,
		atlasX = 128
	},
	{
		title = "admin",
		color = { 0.55, 0.05, 0.05, 1 },
		text = TB_MENU_LOCALIZED.QUEUELISTINGAMEADMINTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTINGAMEADMINDESC,
		atlasX = 0
	},
	{
		title = "eventsquad_trial",
		color = { 0.625, 0.395, 0.719, 1 },
		text = TB_MENU_LOCALIZED.QUEUELISTEVENTSQUADTRIALTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTEVENTSQUADTRIALDESC,
		atlasX = 64
	},
	{
		title = "op",
		text = TB_MENU_LOCALIZED.QUEUELISTROOMOPTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTROOMOPDESC,
		atlasX = 384
	},
	{
		title = "muted",
		text = TB_MENU_LOCALIZED.QUEUELISTMUTEDTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTMUTEDDESC,
		atlasX = 448
	},
	{
		title = "itemforger",
		text = TB_MENU_LOCALIZED.QUEUELISTITEMFORGERTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTITEMFORGERDESC,
		atlasX = 320
	},
	{
		title = "legend",
		text = TB_MENU_LOCALIZED.QUEUELISTLEGENDTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTLEGENDDESC,
		atlasX = 256
	},
	{
		title = "oldschool",
		text = TB_MENU_LOCALIZED.QUEUELISTOLDSCHOOLTITLE,
		desc = TB_MENU_LOCALIZED.QUEUELISTOLDSCHOOLDESC,
		atlasX = 512
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
	info.pInfo:getItems(PLAYERINFO_CSCOPE_ALL)

	local backdropImage, bgBackdrop = info.pInfo.items.textures.gui.profile_backdrop.equipped and "../textures/menu/profile/rankedgold.tga" or nil, nil
	if (backdropImage) then
		bgBackdrop = viewElement:addChild({
			size = { viewElement.size.w, viewElement.size.h },
			bgImage = backdropImage,
			imageAtlas = true,
			atlas = { x = 0, y = 0, w = 1200, h = 128 }
		})
		TBMenu:addOuterRounding(bgBackdrop, TB_MENU_DEFAULT_BG_COLOR, { 4, 4, 0, 0 })
	end

	local infosH = 35
	local nameHolder = viewElement:addChild({
		pos = { 75, 0 },
		size = { viewElement.size.w - 90, 38 }
	})
	nameHolder:addAdaptedText(info.pInfo.username, {
		font = FONTS.BIG,
		align = LEFTMID,
		shadow = bgBackdrop and 4 or 0,
		intensity = 1
	})

	local beltInfo = PlayerInfo.getBeltFromQi(info.games_played)
	local beltHolder = viewElement:addChild({
		pos = { 75, infosH },
		size = { viewElement.size.w - 90, 25 }
	})
	infosH = infosH + beltHolder.size.h
	beltHolder:addAdaptedText(beltInfo.name .. " Belt, " .. info.games_played .. " Qi", {
		align = LEFTMID,
		shadow = bgBackdrop and 2 or 0
	})

	local clanHolder = nil
	if (info.pInfo.clan.id > 0) then
		clanHolder = viewElement:addChild({
			pos = { 75, infosH },
			size = { viewElement.size.w, 30 },
			interactive = true,
			bgColor = UICOLORWHITE,
			hoverColor = TB_MENU_DEFAULT_YELLOW,
			pressedColor = TB_MENU_DEFAULT_ORANGE
		})
		infosH = infosH + clanHolder.size.h
		local clanHolderShadow = bgBackdrop and 2 or 0
		clanHolder:addAdaptedText(info.pInfo.clan.tag .. " " .. info.pInfo.clan.name .. (info.pInfo.clan.isleader and " (" .. TB_MENU_LOCALIZED.QUEUELISTDROPDOWNCLANLEADER .. ")" or ""), {
			font = FONTS.LMEDIUM,
			align = LEFTMID,
			maxscale = 0.65,
			minscale = 0.55,
			shadow = clanHolderShadow
		})
		clanHolder:addCustomDisplay(true, function()
				clanHolder:uiText(clanHolder.str, nil, nil, clanHolder.textFont, LEFTMID, clanHolder.textScale, nil, clanHolderShadow, clanHolder:getButtonColor())
			end)
		clanHolder:addMouseUpHandler(function()
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
		size = { 60, 60 }
	})
	local headViewport = UIElement:new( {
		parent = headHolder,
		pos = { -70, -70 },
		size = { 80, 80 }
	})
	viewElement.headViewport = headViewport
	TBMenu:showPlayerHeadAvatar(headViewport, info.pInfo)

	if (clanHolder) then
		-- Reload to ensure clan button is above head viewport holder
		clanHolder:reload()
	end

	local titleHolder = UIElement:new({
		parent = viewElement,
		pos = { 10, infosH + 5 },
		size = { viewElement.size.w - 20, 25 }
	})
	local titleShift = { x = 0, y = 0 }
	local displayed = 0
	for _, v in pairs(QueueListInternal.InfoFields) do
		if (info[v.title] == true) then
			local color = v.color or table.clone(TB_MENU_DEFAULT_INACTIVE_COLOR_DARK)
			local titleDisplay = titleHolder:addChild({
				pos = { titleShift.x, titleShift.y },
				size = { 150, 20 },
				bgColor = color,
				shapeType = ROUNDED,
				rounded = 10,
				uiColor = get_color_contrast_ratio(color) > 0.66 and UICOLORBLACK or UICOLORWHITE
			})
			if (v.atlasX ~= nil) then
				local atlasData = QueueListInternal.GetRoleIcon(v.title)
				if (atlasData) then
					titleDisplay:addChild({
						pos = { 0, 0 },
						size = { titleDisplay.size.h, titleDisplay.size.h },
						bgImage = atlasData.filename,
						imageAtlas = true,
						atlas = atlasData.atlas
					})
					local titleText = titleDisplay:addChild({
						pos = { titleDisplay.size.h, 0 },
						size = { titleDisplay.size.w - titleDisplay.size.h, titleDisplay.size.h }
					})
					titleText:addAdaptedText(true, v.text, 5, nil, 4, LEFTMID, 0.6)
					local titleTextLen = get_string_length(titleText.dispstr[1], titleText.textFont) * titleText.textScale + 15
					titleText.size.w = titleTextLen
					titleDisplay.size.w = titleText.size.w + titleDisplay.size.h
				end
			else
				titleDisplay:addAdaptedText(false, v.text, 10, nil, 4, LEFTMID, 0.6)
				local titleTextLen = get_string_length(titleDisplay.dispstr[1], titleDisplay.textFont) * titleDisplay.textScale + 20
				titleDisplay.size.w = titleTextLen
			end
			if (v.desc) then
				local helpPopupHolder = titleDisplay:addChild({
					interactive = true,
					bgColor = { 0, 0, 0, 0.01 },
					hoverColor = { 1, 1, 1, 0.2 },
					uiColor = UICOLORWHITE
				}, true)
				local helpPopup = TBMenu:displayHelpPopup(helpPopupHolder, v.desc, nil, true)
				if (helpPopup ~= nil) then
					helpPopup:moveTo(math.min(-titleDisplay.size.w + (titleDisplay.size.w - helpPopup.size.w) / 2, helpPopup.shift.x))
					helpPopup:moveTo(nil, titleDisplay.size.h + 5, true)
				end
			end
			titleShift.x = titleShift.x + titleDisplay.size.w + 5
			if (titleShift.x > titleHolder.size.w) then
				titleShift.y = titleShift.y + titleDisplay.size.h + 3
				titleDisplay:moveTo(0, titleShift.y)
				titleShift.x = titleDisplay.size.w + 5
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

	if (bgBackdrop ~= nil) then
		bgBackdrop.size.h = math.clamp(450 / bgBackdrop.size.w * 150, infosH, bgBackdrop.size.w / 3)
		bgBackdrop.atlas.h = math.min(bgBackdrop.atlas.w / 3, bgBackdrop.atlas.w / bgBackdrop.size.w * bgBackdrop.size.h)

		local fadeToColor = table.clone(TB_MENU_DEFAULT_BG_COLOR)
		fadeToColor[4] = 0
		bgBackdrop:addChild({
			pos = { 0, -30 },
			size = { bgBackdrop.size.w, 30 },
			bgGradient = { TB_MENU_DEFAULT_BG_COLOR, fadeToColor }
		})
		viewElement:reload()
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
	add_hook("console", self.HookName, function(s, i)
			if (os.clock_real() - clock > 15) then
				remove_hook("console", self.HookName)
				return
			end

			if (i == 1) then
				if (s:find("^.*%d+ .+ Playing Authorized")) then
					local ip = s:gsub(" Playing Authorized$", "")
					ip = ip:gsub("^.*%d+ .* ", "")
					remove_hook("console", self.HookName)
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
	local windowSize = {
		x = math.min(WIN_W * 0.6, 800),
		y = 400
	}
	local reportHolder = overlay:addChild({
		shift = { (WIN_W - windowSize.x) / 2, (WIN_H - windowSize.y) / 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	local reportHeader = reportHolder:addChild({
		pos = { 60, 10 },
		size = { reportHolder.size.w - 120, 35 }
	})
	reportHeader:addAdaptedText(true, TB_MENU_LOCALIZED.REPORTSREPORTINGPLAYER .. ": " .. pName, nil, nil, FONTS.BIG)

	local reportClose = reportHolder:addChild({
		pos = { -50, 10 },
		size = { 40, 40 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	reportClose:addMouseHandlers(nil, function() overlay:kill() end)
	local reportCloseIcon = reportClose:addChild({
		shift = { 5, 5 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})

	local reportReasonHolder = reportHolder:addChild({
		pos = { 60, reportHeader.size.h + reportHeader.shift.y * 4 },
		size = { reportHolder.size.w - 120, 40 }
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
		pos = { reportReasonHolder.shift.x, reportReasonHolder.size.h + reportReasonHolder.shift.y + reportHeader.shift.y },
		size = { reportReasonHolder.size.w, reportHolder.size.h - reportReasonHolder.size.h - reportReasonHolder.shift.y - reportHeader.shift.y * 2 - 120 },
		uiColor = UICOLORWHITE
	}, true)
	local extraMessageTitle = extraMessageHolder:addChild({
		size = { extraMessageHolder.size.w, 25 },
		uiColor = { 1, 1, 1, 0.9 }
	})
	extraMessageTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPORTSEXTRAMESSAGE, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)

	local extraMessage = TBMenu:spawnTextField2(extraMessageHolder, {
			y = extraMessageTitle.size.h + 3,
			h = extraMessageHolder.size.h - extraMessageTitle.size.h },
		nil, TB_MENU_LOCALIZED.REPORTSEXTRAMESSAGETIP, {
			fontId = FONTS.SMALL,
			textAlign = LEFT,
			allowMultiline = true,
			darkerMode = true
		})
	local chatlogInfo = reportHolder:addChild({
		pos = { reportReasonHolder.shift.x, extraMessageHolder.size.h + extraMessageHolder.shift.y + 5 },
		size = { reportReasonHolder.size.w, 40 }
	})
	chatlogInfo:addAdaptedText(true, TB_MENU_LOCALIZED.REPORTSCHATLOGINFO .. "\n" .. TB_MENU_LOCALIZED.REPORTSABUSENOTICE, nil, nil, FONTS.LMEDIUM, nil, 0.6)
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
						TBMenu:showStatusMessage(reportReasonId == 3 and TB_MENU_LOCALIZED.REPORTSSUCCESSSCAMMING or TB_MENU_LOCALIZED.REPORTSSUCCESSDEFAULT)
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
						reportThread:addMouseUpHandler(function() open_url("https://forum.toribash.com/showthread.php?t=" .. reportThreadId) end)
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
						discordButton:addMouseUpHandler(function() open_url("https://toribash.com/discord") end)
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
					local exitButtonText = exitButton:addChild({
						shift = { exitButton.size.w * 0.05, exitButton.size.h * 0.1 },
					})
					exitButtonText:addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONCLOSEWINDOW)
					exitButton:addMouseUpHandler(function() overlay:kill() end)
				else
					waitOverlay:kill()
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ACCOUNTINFOERROR)
				end
			end, function()
				waitOverlay:kill()
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ACCOUNTINFOERROR)
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
	local newElement = viewElement.parent:addChild({
		pos = { viewElement.shift.x, viewElement.shift.y },
		size = { viewElement.size.w, viewElement.size.h }
	})
	viewElement:kill()
	viewElement = newElement
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

	local dropdownHolder = viewElement:addChild({
		shift = { 5, 0 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = ROUNDED,
		rounded = 3
	})
	TBMenu:spawnDropdown(dropdownHolder, buttons, 30, nil, nil, { scale = 0.6 }, { scale = 0.5 })
end

---Shows nudge player to position controls
---@param pName string
---@param viewElement UIElement
---@param info QueueListPlayerInfo
function QueueList:showNudgeToPosition(pName, viewElement, info)
	viewElement:kill(true)
	local textFieldHolder = viewElement:addChild({
		shift = { 10, 2 },
		shapeType = ROUNDED,
		rounded = 3
	})
	local textField = TBMenu:spawnTextField2(textFieldHolder, {
			w = textFieldHolder.size.w - 100
		}, tostring(info.id - 1), TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGECHOOSE, {
			fontId = FONTS.SMALL,
			textAlign = LEFTMID,
			isNumeric = true,
			keepFocusOnHide = true
		})
	local function nudge()
		runCmd("nudge " .. pName .. " " .. textField.textfieldstr[1], true)
		QueueList.DestroyPopup()
	end
	textField:addEnterAction(nudge)

	local button = textFieldHolder:addChild({
		pos = { -100, 0 },
		size = { 100, textFieldHolder.size.h },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	button:addChild({ shift = { 10, 2 } }):addAdaptedText(TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGE, { font = FONTS.LMEDIUM })
	button:addMouseUpHandler(nudge)

	UIElement.handleMouseDn(0, textField.pos.x + 1, textField.pos.y + 1)
	UIElement.handleMouseUp(0, textField.pos.x + 1, textField.pos.y + 1)
end

---Spawns main QueueList window controls
---@param viewElement UIElement
---@param info QueueListPlayerInfo Target player's queue info
---@param userinfo QueuePlayerInfo Local player's queue info
---@return integer #Added buttons' height
function QueueList:addPlayerControls(viewElement, info, userinfo)
	local isFriend = Friends:isFriend(info.pInfo.username)
	local isIgnored = Friends:isIgnored(info.pInfo.username, IGNORE_MODE.CHAT)

	local showControls, showAdvControls = false, false
	if (userinfo.admin or userinfo.eventsquad or userinfo.helpsquad) then
		userinfo.ingameadmin = true
		showControls = true
		showAdvControls = true
	elseif (userinfo.op) then
		showControls = true
	end
	if (info.admin or info.eventsquad or info.helpsquad) then
		info.ingameadmin = true
	end

	local buttons = {
		{
			name = "whisper",
			show = not isIgnored,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNWHISPER,
			action = function(s)
				if (is_mobile()) then
					TBHud:toggleChat(true)
					TBHud.__waitingWhisper = true
				end
				runCmd("whisper " .. s)
			end
		},
		{
			name = "addfriend",
			show = not isFriend,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNADDFRIEND,
			action = function(s) Friends:addFriend(s) end
		},
		{
			name = "removefriend",
			show = isFriend,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNREMOVEFRIEND,
			action = function(s) Friends:removeFriend(s) end
		},
		{
			name = "ignore",
			show = true,
			text = TB_MENU_LOCALIZED.QUEUELISTIGNORESETTINGS,
			action = function(s) Friends:manageIgnoreList(s) end
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
			show = not info.muted and not info.op and not info.ingameadmin,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNMUTE,
			action = function(s) runCmd("mute " .. s, true) end
		},
		{
			name = "unmute",
			show = info.muted,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNUNMUTE,
			action = function(s) runCmd("unmute " .. s, true) end
		},
		{
			name = "op",
			show = not info.op and not info.ingameadmin,
			text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNOP,
			action = function(s) runCmd("op " .. s, true) end
		},
		{
			name = "deop",
			show = info.op and not info.ingameadmin,
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
			show = not info.spectator and info.id >= get_game_rules().numplayers,
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

	local infoH, buttonH = viewElement.size.h + 5, 30
	if (not info.isMe) then
		local separator = viewElement:addChild({
			pos = { 10, viewElement.size.h + 2 },
			size = { viewElement.size.w - 20, 1 },
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
				textHolder:addAdaptedText(true, v.text, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.75)
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
			pos = { 10, infoH + 2 },
			size = { viewElement.size.w - 20, 1 },
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
				textHolder:addAdaptedText(true, v.text, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.75)
				contextButton:addMouseHandlers(nil, function()
						---@diagnostic disable-next-line: redundant-parameter
						if (not v.action(info.pInfo.username, contextButton)) then
							QueueList.DestroyPopup()
						end
					end)
				infoH = infoH + buttonH
			end
		end

		local gSeparator = UIElement:new({
			parent = viewElement,
			pos = { 10, infoH + 2 },
			size = { viewElement.size.w - 20, 1 },
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
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 3
		})
		TBMenu:spawnDropdown(globalControlsHolder, gButtons, buttonH, nil, nil, { scale = 0.6 }, { scale = 0.6 })

		infoH = infoH + buttonH + 2
	end

	return infoH
end

---Spawns player info display window
---@param info QueueListPlayerInfo
function QueueList:show(info)
	if (not info or info.pInfo.username == "") then
		return
	end
	local userinfo = QueueList:getCurrentPlayerInfo()
	if (not userinfo) then
		return
	end

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

	local queuelistBoxBG = QueueList.PopupWindow:addChild({
		pos = { MOUSE_X - 50 - QueueList.PopupWidth, MOUSE_Y - 20 },
		size = { QueueList.PopupWidth, 60 }, -- 60 is required for base player info
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	local queuelistBox = queuelistBoxBG:addChild({
		shift = { 2, 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		uiShadowColor = UICOLORBLACK
	}, true)
	queuelistBox.headViewport = nil

	local pName = string.lower(info.pInfo.username)
	local customs = Files.Open("../custom/" .. pName .. "/item.dat", FILES_MODE_READONLY)
	if (not customs.data) then
		download_head(pName)
		add_hook("downloader_complete", self.HookName, function(file)
				if (string.find(file, pName .. "/item.dat")) then
					Downloader.SafeCall(function()
							if (queuelistBox ~= nil and not queuelistBox.destroyed and
								queuelistBox.headViewport ~= nil and not queuelistBox.headViewport.destroyed) then
								queuelistBox.headViewport:kill(true)
								TBMenu:showPlayerHeadAvatar(queuelistBox.headViewport, info.pInfo)
							end
						end)
					remove_hook("downloader_complete", self.HookName)
				end
			end)
	end
	customs:close()
	queuelistBox.size.h = QueueList:addPlayerInfos(queuelistBox, info)
	queuelistBox.size.h = QueueList:addPlayerControls(queuelistBox, info, userinfo)


	queuelistBoxBG.size.h = queuelistBox.size.h + queuelistBox.shift.y * 2
	local x, y, w, h = get_window_safe_size()
	if (queuelistBoxBG.size.h + queuelistBoxBG.pos.y + 10 > y + h) then
		queuelistBoxBG:moveTo(nil, y + h - queuelistBoxBG.size.h - 10)
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
	local x = math.max(x, WIN_W - w - x)
	local listWidth = 400
	QueueList.MainElement = UIElement:new({
		globalid = QueueList.Globalid,
		pos = { WIN_W - listWidth - x, 150 },
		size = { listWidth, y + h - 350 }
	})
	local toReload, topBar, botBar, listingView, listingHolder = TBMenu:prepareScrollableList(QueueList.MainElement, 1, 1, 8, { 0, 0, 0, 0 })

	---Make sure we don't block mouse clicks on player
	topBar.clickThrough = true
	botBar.clickThrough = true
	listingView.clickThrough = true

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
	bout.isMe = bout.netid == get_current_netid()
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
	spec.isMe = spec.netid == get_current_netid()
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
	for _, v in pairs(QueueListInternal.InfoFields) do
		if (playerInfo[v.title] == true and v.color ~= nil) then
			return table.clone(v.color)
		end
	end

	if (playerInfo.isMe) then
		return { 0, 1, 0, 1 }
	elseif (not playerInfo.spectator and playerInfo.id == 0) then
		return { 0.67, 0.11, 0.11, 1 } -- Tori, TB_MENU_DEFAULT_BG_COLOR
	elseif (not playerInfo.spectator and playerInfo.id == 1) then
		return { 0.242, 0.626, 1, 1 } -- Uke, TB_MENU_DEFAULT_BLUE
	end
	return { 0, 0, 0, 1 }
end

---@class QueueListIcon
---@field atlasData AtlasData
---@field infoField QueueListInfoField

---Returns status icon atlas information for the user
---@param info QueueListPlayerInfo
---@return QueueListIcon|nil
function QueueListInternal.GetStatusIcon(info)
	for _,v in pairs(QueueListInternal.InfoFields) do
		if (info[v.title] == true and v.atlasX ~= nil) then
			return {
				infoField = v,
				atlasData = {
					filename = "../textures/statusicons.tga",
					atlas = { x = v.atlasX, y = 0, h = 64, w = 64 }
				}
			}
		end
	end
	return nil
end

---Returns status icon atlas information for a given role
---@param role string
---@return AtlasData|nil
function QueueListInternal.GetRoleIcon(role)
	for _,v in pairs(QueueListInternal.InfoFields) do
		if (v.title == role and v.atlasX ~= nil) then
			return {
				filename = "../textures/statusicons.tga",
				atlas = { x = v.atlasX, y = 0, h = 64, w = 64 }
			}
		end
	end
	return nil
end

---Adds a player to the queue list cache
---@param id integer
---@param playerInfo ?QueueListPlayerInfo
---@param bouts ?integer
---@param spectator ?boolean
function QueueList.AddPlayer(id, playerInfo, bouts, spectator)
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
	local playerDisplayName = playerInfo.nick
	local playerInfoStatus = ""
	if (spectator and playerInfo.afk) then
		playerInfoStatus = "[afk]"
	end
	if (playerInfo.multiclient) then
		playerInfoStatus = playerInfoStatus .. "[MC]"
	end
	if (playerInfoStatus:len() > 0) then
		playerDisplayName = playerDisplayName .. " ^08" .. playerInfoStatus
	end
	playerInfo.button:addAdaptedText(true, playerDisplayName, nil, nil, FONTS.SMALL, RIGHTMID, 1, 1)
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
	if (spectator) then
		playerInfo.button:moveTo(flagScale, nil, true)
	else
		local playerFlag = playerInfo.button:addChild({
			pos = { playerInfo.button.size.w + 5, (playerInfo.button.size.h - flagScale) / 2 },
			size = { flagScale, flagScale },
			bgImage = flagInfo.filename,
			imageAtlas = true,
			atlas = flagInfo.atlas
		})
	end

	local statusIcon = QueueListInternal.GetStatusIcon(playerInfo)
	if (statusIcon ~= nil) then
		local playerStatus = playerInfo.button:addChild({
			pos = { -playerInfo.button.size.w - playerInfo.button.size.h + 2, 0 },
			size = { playerInfo.button.size.h, playerInfo.button.size.h },
			bgImage = statusIcon.atlasData.filename,
			imageAtlas = true,
			atlas = statusIcon.atlasData.atlas,
			interactive = true,
			clickThrough = true,
			hoverThrough = true
		})
		local infoPopup = TBMenu:displayPopup(playerStatus, statusIcon.infoField.text, nil, playerInfo.button.size.h)
		if (infoPopup ~= nil) then
			infoPopup:moveTo(-playerStatus.size.w - infoPopup.size.w - 5)
		end
	end
end

---Generic function to check if cached player info has changed
---@param playerInfo QueueListPlayerInfo
---@param cachedData QueueListPlayerInfo
function QueueListInternal.InfoChanged(playerInfo, cachedData)
	-- table.compare() won't work here due to potential UIElement field (?)
	if (cachedData == nil) then
		return true
	end
	local changed = playerInfo.nick ~= cachedData.nick or
					playerInfo.perms_bitfield ~= cachedData.perms_bitfield or
					playerInfo.afk ~= cachedData.afk or
					playerInfo.muted ~= cachedData.muted or
					playerInfo.multiclient ~= cachedData.multiclient
	return changed
end

---Reloads queue list display with the new values
---@param reinit ?boolean
function QueueList.Reload(reinit)
	local roomInfo = get_room_info()
	if (roomInfo == nil or QueueList.LastHudOption == 0) then
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
	for i, _ in pairs(bouts) do
		local playerInfo = QueueListInternal.getBoutInfo(i - 1)
		if (playerInfo) then
			if (QueueListInternal.InfoChanged(playerInfo, QueueList.Cache.Players.Bouts[i])) then
				QueueList.AddPlayer(i, playerInfo)
			end
		end
	end
	while (QueueList.Cache.Players.Bouts[numBouts + 1] ~= nil) do
		QueueList.Cache.Players.Bouts[numBouts + 1].button:kill()
		table.remove(QueueList.Cache.Players.Bouts, #bouts + 1)
	end

	local spectators = get_spectators()
	for i, _ in pairs(spectators) do
		local playerInfo = QueueListInternal.getSpecInfo(i - 1)
		if (playerInfo) then
			if (QueueListInternal.InfoChanged(playerInfo, QueueList.Cache.Players.Specs[i])) then
				QueueList.AddPlayer(i, playerInfo, numBouts, true)
			else
				QueueList.Cache.Players.Specs[i].button:moveTo(nil, (numBouts + i - 1) * QueueListInternal.listButtonHeight)
			end
		end
	end
	while (QueueList.Cache.Players.Specs[#spectators + 1] ~= nil) do
		QueueList.Cache.Players.Specs[#spectators + 1].button:kill()
		table.remove(QueueList.Cache.Players.Specs, #spectators + 1)
	end

	for i = #QueueListInternal.ListElements, 1, -1 do
		table.remove(QueueListInternal.ListElements, i)
	end
	local maxButtonWidth = 0
	for _, v in pairs(QueueList.Cache.Players.Bouts) do
		table.insert(QueueListInternal.ListElements, v.button)
		maxButtonWidth = math.max(v.button.size.w, maxButtonWidth)
		v.button:hide(true)
	end
	for _, v in pairs(QueueList.Cache.Players.Specs) do
		table.insert(QueueListInternal.ListElements, v.button)
		maxButtonWidth = math.max(v.button.size.w, maxButtonWidth)
		v.button:hide(true)
	end

	QueueListInternal.ListScrollbar.size.h = math.ceil(math.max(0.1, math.min(1, (QueueListInternal.ListHolder.size.h) / (#QueueListInternal.ListElements * QueueListInternal.listButtonHeight) or QueueListInternal.ListHolder.size.h)) * 100) / 100 * QueueListInternal.ListScrollbar.parent.size.h
	if (#QueueListInternal.ListElements > 0) then
		QueueListInternal.ListScrollbar.listReload()
	end
	if (QueueListInternal.ListScrollbar.size.h == QueueListInternal.ListScrollbar.parent.size.h) then
		QueueListInternal.ListScrollbar:hide(true)
	else
		QueueListInternal.ListScrollbar:show(true)
	end

	maxButtonWidth = maxButtonWidth + QueueListInternal.listButtonHeight * 2
	QueueListInternal.ListHolder.parent.size.w = maxButtonWidth
	QueueListInternal.ListHolder.parent:moveTo(QueueListInternal.ListHolder.parent.parent.size.w - maxButtonWidth)
	QueueListInternal.ListHolder:moveTo(-maxButtonWidth - math.abs(QueueListInternal.ListHolder.size.w - maxButtonWidth) - QueueListInternal.ListScrollbar.parent.size.w * 2)

	QueueList.Cache.Players.total = #QueueList.Cache.Players.Bouts + #QueueList.Cache.Players.Specs

	if (QueueList.PopupWindow ~= nil) then
		QueueList.PopupWindow:reload()
	end
end

---Initializes the script and sets the default values
function QueueList.Init()
	QueueList.ResetCache()
	QueueList.Reload()
	QueueList.PopupWidth = math.min(WIN_W * 0.22, 450)
end

---Destroys or reloads QueueList based on current `hud` option value
function QueueList.UpdateVisibility()
	local hud = tonumber(get_option("hud")) or 0
	if (QueueList.LastHudOption ~= hud) then
		QueueList.LastHudOption = hud
		QueueList.Reload()
	end
end

QueueList.Init()
add_hook("new_game", QueueList.HookName, QueueList.Reload)
add_hook("new_mp_game", QueueList.HookName, QueueList.Reload)
add_hook("bout_update", QueueList.HookName, QueueList.Reload)
add_hook("spec_update", QueueList.HookName, QueueList.Reload)
add_hook("resolution_changed", QueueList.HookName, QueueList.Init)
add_hook("pre_draw", QueueList.HookName, QueueList.UpdateVisibility)
