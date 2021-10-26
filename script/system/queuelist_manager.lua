-- Queuelist Dropdown Menu
require("system/player_info")
require("toriui/uielement3d")
require("system/friendlist_manager")
require("system/iofiles")

QUEUELISTMENU = nil

do
	QueueList = {}
	QueueList.__index = QueueList
	local cln = {}
	setmetatable(cln, QueueList)

	function QueueList:quit(keepHook)
		if (not keepHook) then
			remove_hooks("queuelistKeyboard")
			chat_input_activate()
		end
		
		if (QUEUELISTMENU) then
			QUEUELISTMENU:kill()
		end
		QUEUELISTMENU = nil
	end

	function QueueList:addPlayerInfos(viewElement, info, bout)
		local pName = PlayerInfo:getUser(info.nick)
		local infosH = 35
		local nameHolder = UIElement:new({
			parent = viewElement,
			pos = { 75, 0 },
			size = { viewElement.size.w - 90, 35 }
		})
		nameHolder:addAdaptedText(nil, pName, nil, nil, FONTS.BIG, LEFTMID)
		
		local beltInfo = PlayerInfo:getBeltFromQi(info.games_played)
		local beltHolder = UIElement:new({
			parent = viewElement,
			pos = { 75, infosH },
			size = { viewElement.size.w - 90, 25 }
		})
		infosH = infosH + beltHolder.size.h
		beltHolder:addAdaptedText(true, beltInfo.name .. " Belt, " .. info.games_played .. " Qi", nil, nil, nil, LEFTMID)
		
		local pClan = PlayerInfo:getClan(pName, PlayerInfo:getClanTag(info.nick))
		local clanHolder = nil
		if (pClan.id > 0) then
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
			clanNameHolder:addAdaptedText(true, pClan.tag .. " " .. pClan.name .. (pClan.isleader and " (" .. TB_MENU_LOCALIZED.QUEUELISTDROPDOWNCLANLEADER .. ")" or ""), nil, nil, 4, LEFTMID, nil, 0.6)
			clanHolder:addMouseHandlers(nil, function()
					QueueList:quit()
					-- Use ARG1 instead of ARG so that data doesn't get emptied upon open_menu() call
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
		local headViewport3D = UIElement3D:new({
			globalid = TB_MENU_HUB_GLOBALID,
			shapeType = VIEWPORT,
			parent = headViewport,
			pos = { 0, 0, 0 },
			size = { 0, 0, 0 },
			rot = { 0, 0, 0 },
			viewport = true
		})
		table.insert(headViewport.child, headViewport3D)
		local playerItems = PlayerInfo:getItems(pName)
		local playerHead = UIElement3D:new({
			parent = headViewport3D,
			shapeType = SPHERE,
			pos = { 0, 0, 10 },
			size = { 0.9, 0, 0 },
			rot = { 0, 0, -10 },
			viewport = true,
			bgColor = { 1, 1, 1, 1 },
			bgImage = { playerItems.textures.head.equipped and "../../custom/" .. pName .. "/head.tga" or "../../custom/tori/head.tga", "../../custom/tori/head.tga" },
		})
		if (playerItems.objs.head.equipped) then
			local objScale = playerItems.objs.head.dynamic and 2 or 10
			if (playerItems.objs.head.partless) then
				playerHead:kill()
			end
			local modelColor = get_color_info(playerItems.objs.head.colorid)
			local playerHeadModel = UIElement3D:new({
				parent = headViewport3D,
				shapeType = CUSTOMOBJ,
				objModel = "../../custom/" .. pName .. "/head",
				pos = { 0, 0, 10 },
				size = { objScale * 0.9, objScale * 0.9, objScale * 0.9 },
				rot = { 0, 0, -10 },
				viewport = true,
				bgColor = { modelColor.r, modelColor.g, modelColor.b, playerItems.objs.head.alpha / 255 }
			})
		end
		
		if (clanHolder) then
			-- Reload to ensure clan button is above head viewport holder
			clanHolder:reload()
		end
		
		local infoFields = {
			{ title = "legend", color = "BB9600", text = TB_MENU_LOCALIZED.QUEUELISTLEGENDTITLE, desc = TB_MENU_LOCALIZED.QUEUELISTLEGENDDESC },
			{ title = "muted", color = "808080", text = TB_MENU_LOCALIZED.QUEUELISTMUTEDTITLE, desc = TB_MENU_LOCALIZED.QUEUELISTMUTEDDESC },
			{ title = "helpsquad", color = "FA7E1A", text = TB_MENU_LOCALIZED.QUEUELISTTORIAGENTTITLE, desc = TB_MENU_LOCALIZED.QUEUELISTTORIAGENTDESC },
			{ title = "marketsquad", color = "3FA741", text = TB_MENU_LOCALIZED.QUEUELISTMARKETSQUADTITLE, desc = TB_MENU_LOCALIZED.QUEUELISTMARKETSQUADDESC },
			{ title = "eventsquad", color = "690069", text = TB_MENU_LOCALIZED.QUEUELISTEVENTSQUADTITLE, desc = TB_MENU_LOCALIZED.QUEUELISTEVENTSQUADDESC },
			{ title = "admin", color = "FF0000", text = TB_MENU_LOCALIZED.QUEUELISTINGAMEADMINTITLE, desc = TB_MENU_LOCALIZED.QUEUELISTINGAMEADMINDESC },
			{ title = "op", color = "00FF00", text = TB_MENU_LOCALIZED.QUEUELISTROOMOPTITLE, desc = TB_MENU_LOCALIZED.QUEUELISTROOMOPDESC }
		}
		local titleHolder = UIElement:new({
			parent = viewElement,
			pos = { 0, infosH + 5 },
			size = { viewElement.size.w, 25 }
		})
		local titleShift = { x = 15, y = 0 }
		local displayed = 0
		for i,v in pairs(infoFields) do
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

	function QueueList:getCurrentPlayerInfo()
		for i,v in pairs(get_bouts()) do
			local name = PlayerInfo:getUser(v)
			if (name:lower() == TB_MENU_PLAYER_INFO.username:lower()) then
				return get_bout_info(i - 1)
			end
		end
		for i,v in pairs(get_spectators()) do
			local name = PlayerInfo:getUser(v)
			if (name:lower() == TB_MENU_PLAYER_INFO.username:lower()) then
				return get_spectator_info(i - 1)
			end
		end
	end

	function QueueList:placeIPBan(pName)
		add_hook("console", "queuelistipcheck", function(s, i)
				if (i == 1) then
					if (s:find("^.*%d+ .+ Playing Authorized")) then
						local ip = s:gsub(" Playing Authorized$", "")
						ip = ip:gsub("^.*%d+ .* ", "")
						remove_hooks("queuelistipcheck")
						UIElement:runCmd("ban silentadd " .. ip, true)
						UIElement:runCmd("kick " .. pName, true)
					end
					return 1
				end
			end)
		UIElement:runCmd("status " .. pName, true)
	end
	
	function QueueList:report(pName)
		add_hook("key_up", "reportsubmitKeyboard", function(s) UIElement:handleKeyUp(s) return 1 end)
		add_hook("key_down", "reportsubmitKeyboard", function(s) UIElement:handleKeyDown(s) return 1 end)
		chat_input_deactivate()
		
		local overlay = TBMenu:spawnWindowOverlay()
		overlay:addMouseHandlers(nil, function() overlay:kill() remove_hooks("reportsubmitKeyboard") chat_input_activate() end)
		local reportHolder = UIElement:new({
			parent = overlay,
			pos = { WIN_W / 5, WIN_H / 2 - 220 },
			size = { WIN_W / 5 * 3, 440 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			interactive = true
		})
		local reportHeader = UIElement:new({
			parent = reportHolder,
			pos = { 50, 10 },
			size = { reportHolder.size.w - 100, 35 }
		})
		reportHeader:addAdaptedText(true, TB_MENU_LOCALIZED.REPORTSREPORTINGPLAYER .. ": " .. pName, nil, nil, FONTS.BIG)
		local reportClose = UIElement:new({
			parent = reportHolder,
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
		local reportCloseIcon = UIElement:new({
			parent = reportClose,
			pos = { 5, 5 },
			size = { reportClose.size.w - 10, reportClose.size.h - 10 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		local reportReasonHolder = UIElement:new({
			parent = reportHolder,
			pos = { 20, reportHeader.size.h + reportHeader.shift.y * 2 },
			size = { reportHolder.size.w - 40, 40 }
		})
		local reportReasonText = UIElement:new({
			parent = reportReasonHolder,
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
		local reportReasonDropdownBG = UIElement:new({
			parent = reportReasonHolder,
			pos = { reportReasonText.size.w, 0 },
			size = { reportReasonHolder.size.w - reportReasonText.size.w, reportReasonText.size.h },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local reportReasonDropdown = UIElement:new({
			parent = reportReasonDropdownBG,
			pos = { 1, 1 },
			size = { reportReasonDropdownBG.size.w - 2, reportReasonDropdownBG.size.h - 2 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
		})
		TBMenu:spawnDropdown(reportReasonDropdown, reportDropdown, 30, WIN_H - 100, nil, { scale = 0.7 }, { scale = 0.6 })
		local extraMessageHolder = UIElement:new({
			parent = reportHolder,
			pos = { 20, reportReasonHolder.size.h + reportReasonHolder.shift.y + reportHeader.shift.y },
			size = { reportHolder.size.w - 40, reportHolder.size.h - reportReasonHolder.size.h - reportReasonHolder.shift.y - reportHeader.shift.y * 2 - 100 }
		})
		local extraMessageTitle = UIElement:new({
			parent = extraMessageHolder,
			pos = { 0, 0 },
			size = { extraMessageHolder.size.w, 25 },
			uiColor = { 1, 1, 1, 0.9 }
		})
		extraMessageTitle:addAdaptedText(true, TB_MENU_LOCALIZED.REPORTSEXTRAMESSAGE, nil, nil, 4, LEFTMID, 0.7)
		local extraMessage = TBMenu:spawnTextField(extraMessageHolder, 0, extraMessageTitle.size.h, nil, extraMessageHolder.size.h - extraMessageTitle.size.h, nil, nil, FONTS.SMALL, nil, { 1, 1, 1, 1 }, TB_MENU_LOCALIZED.REPORTSEXTRAMESSAGETIP, LEFT, nil, true, true)
		local chatlogInfo = UIElement:new({
			parent = reportHolder,
			pos = { 20, extraMessageHolder.size.h + extraMessageHolder.shift.y + 5 },
			size = { reportHolder.size.w - 40, 40 }
		})
		chatlogInfo:addAdaptedText(true, TB_MENU_LOCALIZED.REPORTSCHATLOGINFO .. "\n" .. TB_MENU_LOCALIZED.REPORTSABUSENOTICE, nil, nil, 4, LEFTMID, 0.6)
		local submitReport = UIElement:new({
			parent = reportHolder,
			pos = { reportHolder.size.w / 4, -50 },
			size = { reportHolder.size.w / 2, 40 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		local submitReportText = UIElement:new({
			parent = submitReport,
			pos = { 15, 5 },
			size = { submitReport.size.w - 30, submitReport.size.h - 10 }
		})
		submitReportText:addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONSUBMIT)
		local function showSubmitReport()
			local waitOverlay = UIElement:new({
				parent = reportHolder,
				pos = { 0, 0 },
				size = { reportHolder.size.w, reportHolder.size.h },
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				interactive = true
			})
			TBMenu:displayLoadingMark(waitOverlay, TB_MENU_LOCALIZED.MESSAGEPLEASEWAIT)
			local function doReport()
				Request:queue(function() report_player(pName, reportReasonId, extraMessage.textfieldstr[1], "") end, "reportPlayer", function()
						local response = get_network_response()
						if (response:find("GATEWAY 0; 0")) then
							if (not waitOverlay:isDisplayed()) then
								TBMenu:showDataError(reportReasonId == 3 and TB_MENU_LOCALIZED.REPORTSSUCCESSSCAMMING or TB_MENU_LOCALIZED.REPORTSSUCCESSDEFAULT, true)
								return
							end
							waitOverlay:kill(true)
							local successMessage = UIElement:new({
								parent = waitOverlay,
								pos = { 20, 10 },
								size = { waitOverlay.size.w - 40, waitOverlay.size.h / 2 - 10 }
							})
							successMessage:addAdaptedText(true, reportReasonId == 3 and TB_MENU_LOCALIZED.REPORTSSUCCESSSCAMMING or TB_MENU_LOCALIZED.REPORTSSUCCESSDEFAULT, nil, nil, nil, CENTERBOT)
							
							local shiftH, buttonH = 10, (waitOverlay.size.h / 2 - 20) / 2 > 50 and 50 or (waitOverlay.size.h / 2 - 20) / 2
							if (reportReasonId == 3) then
								local reportThreadId = response:gsub("GATEWAY 0; 0 ", "")
								local reportThread = UIElement:new({
									parent = waitOverlay,
									pos = { waitOverlay.size.w / 4, waitOverlay.size.h / 2 + shiftH },
									size = { waitOverlay.size.w / 2, buttonH },
									interactive = true,
									bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
									hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
									pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
								})
								local reportThreadText = UIElement:new({
									parent = reportThread,
									pos = { reportThread.size.w / 20, reportThread.size.h / 8 },
									size = { reportThread.size.w * 0.9, reportThread.size.h / 8 * 6 }
								})
								TBMenu:showTextWithImage(reportThreadText, TB_MENU_LOCALIZED.REPORTSREPORTTHREAD .. ": ID " .. reportThreadId, FONTS.MEDIUM, reportThreadText.size.h, "../textures/menu/general/buttons/external.tga")
								reportThread:addMouseHandlers(nil, function() open_url("https://forum.toribash.com/showthread.php?t=" .. reportThreadId) end)
							else
								local discordButton = UIElement:new({
									parent = waitOverlay,
									pos = { waitOverlay.size.w / 4, waitOverlay.size.h / 2 + shiftH },
									size = { waitOverlay.size.w / 2, buttonH },
									interactive = true,
									bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
									hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
									pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
								})
								local discordButtonText = UIElement:new({
									parent = discordButton,
									pos = { discordButton.size.w / 20, discordButton.size.h / 8 },
									size = { discordButton.size.w * 0.9, discordButton.size.h / 8 * 6 }
								})
								TBMenu:showTextWithImage(discordButtonText, TB_MENU_LOCALIZED.DISCORDSERVER, FONTS.MEDIUM, discordButtonText.size.h, "..//textures/menu/logos/discord.tga")
								discordButton:addMouseHandlers(nil, function() open_url("https://discord.gg/toribash") end)
							end
							shiftH = shiftH * 2 + buttonH
							
							local exitButton = UIElement:new({
								parent = waitOverlay,
								pos = { waitOverlay.size.w / 4, waitOverlay.size.h / 2 + shiftH },
								size = { waitOverlay.size.w / 2, buttonH },
								interactive = true,
								bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
								hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
								pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
							})
							local exitButtonText = UIElement:new({
								parent = exitButton,
								pos = { exitButton.size.w / 20, exitButton.size.h / 8 },
								size = { exitButton.size.w * 0.9, exitButton.size.h / 8 * 6 }
							})
							exitButtonText:addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONCLOSEWINDOW)
							exitButton:addMouseHandlers(nil, overlay.btnUp)
						else
							waitOverlay:kill()
							TBMenu:showDataError(TB_MENU_LOCALIZED.ACCOUNTINFOERROR, true)
						end
					end, function()
						waitOverlay:kill()
						TBMenu:showDataError(TB_MENU_LOCALIZED.ACCOUNTINFOERROR, true)
					end)
			end
			if (get_network_task() == 0) then
				doReport()
				local spawnTime = os.clock()
				local messageChanger = UIElement:new({
					parent = reportHolder,
					pos = { 0, 0 },
					size = { 0, 0 }
				})
				messageChanger:addCustomDisplay(true, function()
						if (spawnTime < os.clock() - 5) then
							waitOverlay:kill(true)
							TBMenu:displayLoadingMark(waitOverlay, TB_MENU_LOCALIZED.REPORTSLONGWAITMESSAGE)
						end
					end)
			else
				local waiter = UIElement:new({
					parent = waitOverlay,
					pos = { 0, 0 },
					size = { 0, 0 }
				})
				waiter:addCustomDisplay(true, function()
						if (get_network_task() == 0) then
							waiter:kill()
							local spawnTime = os.clock()
							local messageChanger = UIElement:new({
								parent = reportHolder,
								pos = { 0, 0 },
								size = { 0, 0 }
							})
							messageChanger:addCustomDisplay(true, function()
									if (spawnTime < os.clock() - 5) then
										waitOverlay:kill(true)
										TBMenu:displayLoadingMark(waitOverlay, TB_MENU_LOCALIZED.REPORTSLONGWAITMESSAGE)
									end
								end)
							doReport()
							return
						end
					end)
			end
		end
		submitReport:addMouseHandlers(nil, function()
				TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPORTSCONFIRMATION .. " " .. pName .. "?\n" .. TB_MENU_LOCALIZED.REPORTSABUSENOTICE, showSubmitReport)
			end)
	end
	
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
				action = function() UIElement:runCmd("nudgeup " .. pName, true) QueueList:quit() end
			},
			{
				name = "nudgedown",
				text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGEDOWN,
				action = function() UIElement:runCmd("nudgedown " .. pName, true) QueueList:quit() end
			},
			{
				name = "nudgetopos",
				text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGECUSTOM,
				action = function() QueueList:showNudgeToPosition(pName, viewElement, info) end
			}
		}
		local colorOverlay = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local dropdownHolder = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		TBMenu:spawnDropdown(dropdownHolder, buttons, 30, nil, nil, { scale = 0.6 }, { scale = 0.5 })
		--[[for i,v in pairs(buttons) do
			local button = UIElement:new({
				parent = viewElement,
				pos = { 2 + (i - 1) * viewElement.size.w / #buttons, 0 },
				size = { viewElement.size.w / #buttons - 4, viewElement.size.h },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			local buttonText = UIElement:new({
				parent = button,
				pos = { 10, 5 },
				size = { button.size.w - 20, button.size.h - 10 }
			})
			buttonText:addAdaptedText(true, v.text, nil, nil, 4)
			button:addMouseHandlers(nil, v.action)
		end]]
	end
	
	function QueueList:showNudgeToPosition(pName, viewElement, info)
		viewElement:kill(true)
		add_hook("key_up", "queuelistKeyboard", function(s) UIElement:handleKeyUp(s) return 1 end)
		add_hook("key_down", "queuelistKeyboard", function(s) UIElement:handleKeyDown(s) return 1 end)
		chat_input_deactivate()
		
		local textField = TBMenu:spawnTextField(viewElement, 5, 0, viewElement.size.w - 100, viewElement.size.h, (info.id - 1) .. "", true, FONTS.SMALL, 1, nil, TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGETOPOSITION, LEFTMID)
		local function nudge()
			UIElement:runCmd("nudge " .. pName .. " " .. textField.textfieldstr[1], true)
		end
		textField:addEnterAction(nudge)
		local button = UIElement:new({
			parent = viewElement,
			pos = { -100, 0 },
			size = { 95, viewElement.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		local buttonText = UIElement:new({
			parent = button,
			pos = { 15, 5 },
			size = { button.size.w - 30, button.size.h - 10 }
		})
		buttonText:addAdaptedText(true, TB_MENU_LOCALIZED.QUEUELISTDROPDOWNNUDGE, nil, nil, 4)
		button:addMouseHandlers(nil, function() nudge() QueueList:quit() end)
	end

	function QueueList:addPlayerControls(viewElement, info, userinfo, bout)
		local pName = PlayerInfo:getUser(info.nick)
		if (not FRIENDSLIST_FRIENDS) then
			FriendsList:getFriends()
		end
		local isFriend = false
		for i,v in pairs(FRIENDSLIST_FRIENDS) do
			if (v.username:lower() == pName:lower()) then
				isFriend = true
			end
		end
		local isIgnored = false
		for i,v in pairs(FRIENDSLIST_IGNORE) do
			if (v:lower() == pName:lower()) then
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
		
		local isUser = TB_MENU_PLAYER_INFO.username:lower() == pName:lower()
		
		local buttons = {
			{
				name = "whisper",
				show = not isIgnored,
				text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNWHISPER,
				action = function(s) UIElement:runCmd("whisper " .. s) end
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
				action = function(s) UIElement:runCmd("mute " .. s, true) end
			},
			{
				name = "unmute",
				show = info.muted ~= 0,
				text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNUNMUTE,
				action = function(s) UIElement:runCmd("unmute " .. s, true) end
			},
			{
				name = "op",
				show = info.op == 0 and not info.ingameadmin,
				text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNOP,
				action = function(s) UIElement:runCmd("op " .. s, true) end
			},
			{
				name = "deop",
				show = info.op ~= 0 and not info.ingameadmin,
				text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNDEOP,
				action = function(s) UIElement:runCmd("deop " .. s, true) end
			},
			{
				name = "fspec",
				show = bout,
				text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNFSPEC,
				action = function(s) UIElement:runCmd("fspec " .. s, true) end
			},
			{
				name = "fenter",
				show = not bout,
				text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNFENTER,
				action = function(s) UIElement:runCmd("fenter " .. s, true) end
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
				action = function(s) UIElement:runCmd("kick " .. s, true) end
			},
			{
				name = "ban",
				show = not info.ingameadmin,
				text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNBAN,
				action = function(s) UIElement:runCmd("ban add " .. s, true) end
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
				action = function(s) TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.QUEUELISTDROPDOWNSCRAMBLECONFIRM, function() UIElement:runCmd("scramble", true) QueueList:quit() end) return 1 end
			},
			{
				name = "specall",
				text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNSPECTATEALL,
				action = function(s) TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.QUEUELISTDROPDOWNSPECALLCONFIRM, function() UIElement:runCmd("specall", true) QueueList:quit() end) return 1 end
			},
			{
				name = "muteall",
				text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNMUTEALL,
				action = function(s) UIElement:runCmd("muteall", true) QueueList:quit() end
			},
			{
				name = "unmuteall",
				text = TB_MENU_LOCALIZED.QUEUELISTDROPDOWNUNMUTEALL,
				action = function(s) UIElement:runCmd("unmuteall", true) QueueList:quit() end
			},
		}
		
		local infoH, buttonH = viewElement.size.h + 5, 25
		if (not isUser) then
			local separator = UIElement:new({
				parent = viewElement,
				pos = { 20, viewElement.size.h + 2 },
				size = { viewElement.size.w - 40, 1 },
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			
			for i,v in pairs(buttons) do
				if (v.show) then
					local contextButton = UIElement:new({
						parent = viewElement,
						pos = { 0, infoH },
						size = { viewElement.size.w, buttonH },
						interactive = true,
						bgColor = TB_MENU_DEFAULT_BG_COLOR,
						hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
						pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
					})
					local textHolder = UIElement:new({
						parent = contextButton,
						pos = { 15, 5 },
						size = { contextButton.size.w - 30, contextButton.size.h - 10 }
					})
					textHolder:addAdaptedText(true, v.text, nil, nil, 4, LEFTMID)
					contextButton:addMouseHandlers(nil, function()
							local rVal = v.action(pName, contextButton)
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
			
			for i,v in pairs(cButtons) do
				if (v.show) then
					local contextButton = UIElement:new({
						parent = viewElement,
						pos = { 0, infoH },
						size = { viewElement.size.w, buttonH },
						interactive = true,
						bgColor = TB_MENU_DEFAULT_BG_COLOR,
						hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
						pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
					})
					local textHolder = UIElement:new({
						parent = contextButton,
						pos = { 15, 5 },
						size = { contextButton.size.w - 30, contextButton.size.h - 10 }
					})
					textHolder:addAdaptedText(true, v.text, nil, nil, 4, LEFTMID)
					contextButton:addMouseHandlers(nil, function() if (not v.action(pName, contextButton)) then QueueList:quit() end end)
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
			--[[for i,v in pairs(gButtons) do
				local contextButton = UIElement:new({
					parent = viewElement,
					pos = { 0, infoH },
					size = { viewElement.size.w, buttonH },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				})
				local textHolder = UIElement:new({
					parent = contextButton,
					pos = { 15, 5 },
					size = { contextButton.size.w - 30, contextButton.size.h - 10 }
				})
				textHolder:addAdaptedText(true, v.text, nil, nil, 4, LEFTMID)
				contextButton:addMouseHandlers(nil, function() v.action(pName) QueueList:quit() end)
				infoH = infoH + buttonH
			end]]
		end
		
		return infoH
	end
	
	function QueueList:getHorizontalShift()
		local maxW = 0
		for i,v in pairs(get_bouts()) do
			local w = get_string_length(v, FONTS.SMALL)
			maxW = w > maxW and w or maxW
		end
		for i,v in pairs(get_spectators()) do
			local w = get_string_length(v, FONTS.SMALL)
			maxW = w > maxW and w or maxW
		end
		return maxW
	end

	function QueueList:show(info, bout, id)
		local userinfo = QueueList:getCurrentPlayerInfo()
		if (not info or not userinfo) then
			return
		end
		local pName = PlayerInfo:getUser(info.nick)
		local customs = Files:open("../custom/" .. pName .. "/item.dat", FILES_MODE_READONLY)
		if (not customs.data) then
			download_head(pName)
		end
		customs:close()
		
		WIN_W, WIN_H = get_window_size()
		if (QUEUELISTMENU) then
			QueueList:quit()
		end
		local queuelistMenuHolder = UIElement:new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { 0, 0 },
			size = { WIN_W, WIN_H },
			interactive = true
		})
		QUEUELISTMENU = queuelistMenuHolder
		QUEUELISTMENU:addMouseHandlers(nil, function() QueueList:quit() end, nil, function() QueueList:quit() end)
		local hShift = QueueList:getHorizontalShift()
		local posX = MOUSE_X > WIN_W - 30 - hShift and WIN_W - 30 - hShift or MOUSE_X
		local queuelistBoxBG = UIElement:new({
			parent = queuelistMenuHolder,
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
		queuelistBox.size.h = QueueList:addPlayerControls(queuelistBox, info, userinfo, bout, id)
		
		
		queuelistBoxBG.size.h = queuelistBox.size.h + 2
		if (queuelistBoxBG.size.h + queuelistBoxBG.pos.y + 10 > WIN_H) then
			queuelistBoxBG:moveTo(nil, WIN_H - queuelistBoxBG.size.h - 10)
		end
	end
end

local function getBoutInfo(id)
	if (id < 0) then
		return false
	end
	local bout = get_bout_info(id)
	bout.id = id
	return bout
end
local function getSpecInfo(id)
	if (id < 0) then
		return false
	end
	return get_spectator_info(id)
end

add_hook("bout_mouse_up", "queuelistManager", function(id) QueueList:show(getBoutInfo(id), true, id) end)
add_hook("spec_mouse_up", "queuelistManager", function(id) QueueList:show(getSpecInfo(id), false, id) end)
