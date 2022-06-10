-- Battle Pass manager class
-- DO NOT MODIFY THIS FILE
require("system/menu_defines")
require("system/menu_manager")
require("system/store_manager")
require("system/player_info")

if (BattlePass == nil or TB_MENU_DEBUG) then
	BattlePass = { __index = {} }
	setmetatable({}, BattlePass)
end

function BattlePass:getNavigationButtons(showBack)
	local buttonsData = {
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
			action = function() Matchmake:quit() end,
			width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONTOMAIN, FONTS.BIG) * 0.65 + 30
		}
	}
	if (showBack) then
		table.insert(buttonsData, {
			text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
			action = function()
				tbMenuCurrentSection:kill(true)
				tbMenuNavigationBar:kill(true)
				TBMenu:showNavigationBar()
				Matchmake:showRanked()
			end
		})
	end
	return buttonsData
end

function BattlePass:getLevelData()
	Request:queue(function() download_server_info("battlepass&get=levels") end, "battlepass_levels", function()
			local response = get_network_response()
			if (not response:find("^LEVEL")) then
				BattlePass.LevelData = nil
				return
			end
			BattlePass.LevelData = {}
			for ln in response:gmatch("[^\n]+\n?") do
				if (not ln:find("^LEVEL")) then
					local data = { ln:match(("([^\t]*)\t?"):rep(9)) }
					table.insert(BattlePass.LevelData, {
						level = tonumber(data[1]),
						xp = tonumber(data[2]),
						xp_total = tonumber(data[3]),
						tc = tonumber(data[4]),
						st = tonumber(data[5]),
						itemid = tonumber(data[6]),
						tc_premium = tonumber(data[7]),
						st_premium = tonumber(data[8]),
						itemid_premium = tonumber(data[9])
					})
				end
			end
			BattlePass.LevelData[0] = {
				xp = 0, xp_total = 0, tc = 0, st = 0, itemid = 0, tc_premium = 0, st_premium = 0, itemid_premium = 0
			}
		end)
end

function BattlePass:getUserData(viewElement)
	if (not BattlePass.LevelData) then
		BattlePass:getLevelData()
	end
	Request:queue(function() download_server_info("battlepass&username=" .. TB_MENU_PLAYER_INFO.username) end, "battlepass_userinfo", function()
			local response = get_network_response()
			if (not response:find("^BPUSER") or not BattlePass.LevelData) then
				BattlePass.UserData = nil
				if (viewElement and not viewElement.destroyed) then
					viewElement:kill(true)
					TBMenu:addBottomBloodSmudge(viewElement)
					viewElement:addAdaptedText(nil, TB_MENU_LOCALIZED.ACCOUNTINFOERROR)
				end
				return
			end
			local data = { response:match(("([^\t]*)\t?"):rep(5)) }
			BattlePass.UserData = {
				level = tonumber(data[2]),
				xp = tonumber(data[3]),
				premium = tonumber(data[4]) == 1,
				level_premium = tonumber(data[5])
			}
			for i,v in ipairs(BattlePass.LevelData) do
				if (v.xp_total <= BattlePass.UserData.xp) then
					BattlePass.UserData.level_available = v.level
				else
					break
				end
			end
			if (viewElement and not viewElement.destroyed) then
				BattlePass:showMain()
			end
		end)
end

function BattlePass:showProgress(viewElement)
	local playerLevelHolder = viewElement:addChild({
		pos = { 0, 0 },
		size = { viewElement.size.w / 5, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_ORANGE,
		uiColor = UICOLORBLACK,
		bgImage = "../textures/menu/battlepass/romanpattern2_dark.tga",
		imagePatterned = true
	})
	local playerLevelDisplay = playerLevelHolder:addChild({
		pos = { 5, 5 },
		size = { playerLevelHolder.size.w - 10, playerLevelHolder.size.h - 10 }
	})
	playerLevelDisplay:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSLEVEL, nil, nil, FONTS.BIG, LEFTMID, 0.6, nil, 0)

	local shift = 10 + get_string_length(playerLevelDisplay.dispstr[1], playerLevelDisplay.textFont) * playerLevelDisplay.textScale
	local playerLevelDisplayLevel = playerLevelDisplay:addChild({
		pos = { shift, 0 },
		size = { playerLevelHolder.size.w * 0.9 - shift, playerLevelDisplay.size.h }
	})
	playerLevelDisplayLevel:addAdaptedText(true, BattlePass.UserData.level .. '', nil, nil, FONTS.BIG, LEFTMID, 0.9, nil, 0.6)
	local totalWidth = shift + get_string_length(playerLevelDisplayLevel.dispstr[1], playerLevelDisplayLevel.textFont) * playerLevelDisplayLevel.textScale

	playerLevelDisplay:moveTo((playerLevelDisplay.size.w - totalWidth) / 2, nil, true)

	local playerExpBarHolder = viewElement:addChild({
		shift = { playerLevelHolder.size.w, 0 }
	})
	local sideShift = 30
	local playerExpInfo = playerExpBarHolder:addChild({
		pos = { sideShift, 10 },
		size = { playerExpBarHolder.size.w / 3, (playerExpBarHolder.size.h - 20) / 2 }
	})
	playerExpInfo:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSYOUREXPERIENCE .. "^35 " .. PlayerInfo:currencyFormat(BattlePass.UserData.xp) .. (BattlePass.LevelData[BattlePass.UserData.level + 1] and (" / " .. PlayerInfo:currencyFormat(BattlePass.LevelData[BattlePass.UserData.level + 1].xp_total)) or ''), nil, nil, 4, LEFTBOT, 0.75)
	local playerExpBarBG = playerExpBarHolder:addChild({
		pos = { sideShift, playerExpInfo.shift.y * 2 + playerExpInfo.size.h },
		size = { playerExpBarHolder.size.w - sideShift * 2, 8 },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	local xpProgress = math.max(0, math.min(1, (BattlePass.UserData.xp - BattlePass.LevelData[BattlePass.UserData.level].xp_total) / (BattlePass.LevelData[BattlePass.UserData.level + 1] and BattlePass.LevelData[BattlePass.UserData.level + 1].xp or 1)))
	if (xpProgress > 0) then
		local playerExpBar = playerExpBarBG:addChild({
			pos = { 0, -playerExpBarBG.size.h - 2 },
			size = { playerExpBarBG.size.w * xpProgress, playerExpBarBG.size.h + 4 },
			bgColor = TB_MENU_DEFAULT_DARKER_ORANGE,
			shapeType = ROUNDED,
			rounded = 8
		})
	end

	local purchaseLevelButtonHolder = viewElement:addChild({
		pos = { -playerLevelHolder.size.w - 5, 0 },
		size = { playerLevelHolder.size.w - 10, viewElement.size.h }
	})
	local purchaseLevelButton = purchaseLevelButtonHolder:addChild({
		shift = { 0, 15 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKER_ORANGE,
		shapeType = ROUNDED,
		rounded = 4
	})
	local purchaseLevelButtonText = purchaseLevelButton:addChild({ shift = { 10, 5 } })
	purchaseLevelButtonText:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSPURCHASELEVEL)

	local lineColor = cloneTable(TB_MENU_DEFAULT_DARKER_ORANGE)
	lineColor[4] = 0.7
	local lineShift = 3
	local lineThickness = 2
	viewElement:addCustomDisplay(false, function()
			set_color(unpack(lineColor))
			draw_quad(viewElement.pos.x, viewElement.pos.y + lineShift, viewElement.size.w, lineThickness)
			draw_quad(viewElement.pos.x, viewElement.pos.y + viewElement.size.h - lineThickness - lineShift, viewElement.size.w, lineThickness)
			draw_quad(viewElement.pos.x + viewElement.size.w - lineShift - lineThickness, viewElement.pos.y, lineThickness, viewElement.size.h)
		end)
end

function BattlePass:showPrizeItem(viewElement, prize)
	local prizeDisplayScale = math.min(viewElement.size.w - 20, viewElement.size.h - 10)
	local prizeBackgroundOutline = viewElement:addChild({
		shift = { (viewElement.size.w - prizeDisplayScale) / 2, (viewElement.size.h - prizeDisplayScale) / 2 },
		bgColor = prize.premium and TB_MENU_DEFAULT_DARKER_BLUE or TB_MENU_DEFAULT_DARKER_ORANGE,
		shapeType = ROUNDED,
		rounded = 10
	})
	local prizeBackground = prizeBackgroundOutline:addChild({
		shift = { 2, 2 },
		bgColor = prize.premium and TB_MENU_DEFAULT_BLUE or TB_MENU_DEFAULT_ORANGE
	}, true)

	local prizeIcon, prizeAmount
	if (prize.itemid) then
		 prizeIcon = Torishop:getItemIcon(prize.itemid)
	elseif (prize.tc) then
		prizeIcon = "../textures/store/toricredit.tga"
		prizeAmount = PlayerInfo:currencyFormat(prize.tc)
	elseif (prize.st) then
		prizeIcon = "../textures/store/shiaitoken.tga"
		prizeAmount = PlayerInfo:currencyFormat(prize.st)
	else
		return
	end

	local prizeIcon = prizeBackground:addChild({
		shift = { 3, 3 },
		bgImage = prizeIcon
	})

	if (prize.locked or prize.claimed) then
		local colorOverlay = prizeBackground:addChild({
			bgColor = cloneTable(prizeBackground.bgColor)
		}, true)
		colorOverlay.bgColor[4] = 0.4

		if (prize.locked) then
			local lockedIcon = prizeBackground:addChild({
				pos = { -32, -prizeBackground.size.h },
				size = { 32, 32 },
				bgImage = "../textures/menu/general/buttons/locked.tga"
			})
		else
			local claimedIcon = prizeBackground:addChild({
				shift = { (prizeBackground.size.w - 32) / 2, (prizeBackground.size.h - 32) / 2 },
				shapeType = ROUNDED,
				rounded = 16,
				bgColor = TB_MENU_DEFAULT_BLUE,
				bgImage = "../textures/menu/general/buttons/checkmark.tga"
			})
		end
	end

	if (prize.tc or prize.st) then
		local prizeText = prizeBackgroundOutline:addChild({
			pos = { 0, -30 },
			size = { prizeBackgroundOutline.size.w, 30 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS
		})
		prizeText:addChild({ shift = { 5, 2 } }):addAdaptedText(true, prizeAmount)
	end
end

function BattlePass:showPrizeSingle(prizeHolder, levelData)
	local prizeLevel = prizeHolder:addChild({
		pos = { 10, 10 },
		size = { prizeHolder.size.w - 20, 30 }
	})
	prizeLevel:addAdaptedText(nil, TB_MENU_LOCALIZED.BATTLEPASSLVL .. " " .. levelData.level)
	local prizeBackground = prizeHolder:addChild({
		pos = { 3, 50 },
		size = { prizeHolder.size.w - 6, prizeHolder.size.h - 50 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})

	if (levelData.st > 0 or levelData.tc > 0 or levelData.itemid > 0) then
		local freePrizeHolder = prizeBackground:addChild({
			pos = { 0, 0 },
			size = { prizeBackground.size.w, (prizeBackground.size.h - 20) / 3 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		BattlePass:showPrizeItem(freePrizeHolder, {
			tc = levelData.tc > 0 and levelData.tc or nil,
			st = levelData.st > 0 and levelData.st or nil,
			itemid = levelData.itemid > 0 and levelData.itemid or nil,
			locked = BattlePass.UserData.level_available < levelData.level,
			claimed = BattlePass.UserData.level >= levelData.level
		})
	end

	local premiumPrizes = {}
	if (levelData.st_premium > 0) then
		table.insert(premiumPrizes, {
			st = levelData.st_premium,
			locked = not BattlePass.UserData.premium or BattlePass.UserData.level_available < levelData.level,
			claimed = BattlePass.UserData.level_premium >= levelData.level,
			premium = true
		})
	end
	if (levelData.tc_premium > 0) then
		table.insert(premiumPrizes, {
			tc = levelData.tc_premium,
			locked = not BattlePass.UserData.premium or BattlePass.UserData.level_available < levelData.level,
			claimed = BattlePass.UserData.level_premium >= levelData.level,
			premium = true
		})
	end
	if (levelData.itemid_premium > 0) then
		table.insert(premiumPrizes, {
			itemid = levelData.itemid_premium,
			locked = not BattlePass.UserData.premium or BattlePass.UserData.level_available < levelData.level,
			claimed = BattlePass.UserData.level_premium >= levelData.level,
			premium = true
		})
	end
	local prizeHolderHeight = math.min(prizeBackground.size.w - 10, (prizeBackground.size.h / 3 * 2 - 10 * (#premiumPrizes - 1)) / #premiumPrizes)
	local premiumPrizesHolder = prizeBackground:addChild({
		pos = { 0, -prizeBackground.size.h / 3 - (prizeHolderHeight + 10) * #premiumPrizes / 2 },
		size = { prizeBackground.size.w, (prizeHolderHeight + 10) * #premiumPrizes }
	})
	for i,v in pairs(premiumPrizes) do
		local premiumPrizeHolder = premiumPrizesHolder:addChild({
			pos = { 0, (prizeHolderHeight + 10) * (i - 1) },
			size = { prizeBackground.size.w, prizeHolderHeight }
		})
		BattlePass:showPrizeItem(premiumPrizeHolder, v)
	end
end

function BattlePass:showPrizes(viewElement)
	local prizeHolderSize = 120
	local toReload, leftBar, rightBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, prizeHolderSize, prizeHolderSize, 20, TB_MENU_DEFAULT_BG_COLOR, SCROLL_HORIZONTAL)

	local listElements = {}
	for j = 1, 10 do
		for i,v in ipairs(BattlePass.LevelData) do
			local prizeHolder = UIElement:new({
				parent = listingHolder,
				pos = { #listElements * prizeHolderSize, 0 },
				size = { prizeHolderSize, listingHolder.size.h },
			})
			table.insert(listElements, prizeHolder)
			BattlePass:showPrizeSingle(prizeHolder, v)
		end
	end

	for i,v in pairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, prizeHolderSize, SCROLL_HORIZONTAL)
	listingHolder.scrollBar = scrollBar
	scrollBar:makeHorizontalScrollBar(listingHolder, listElements, toReload, nil, 0.4)

	leftBar:addAdaptedText(false, "SOMETHING GOES HERE")
	rightBar:addAdaptedText(false, "SOMETHING ELSE GOES HERE.\nTOP LEVEL REWARD?")
end

function BattlePass:showMain()
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 2
	tbMenuCurrentSection:kill(true)

	if (not BattlePass.UserData) then
		local battlePassLoading = tbMenuCurrentSection:addChild({
			shift = { 5, 0 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(battlePassLoading)
		TBMenu:displayLoadingMark(battlePassLoading, TB_MENU_LOCALIZED.BATTLEPASSLOADING)
		BattlePass:getUserData(battlePassLoading)
		return
	end

	local leftWidth = math.min((tbMenuCurrentSection.size.h - 90) / 3 * 2 - 5, tbMenuCurrentSection.size.w * 0.3)
	local battlePassProgressHolder = tbMenuCurrentSection:addChild({
		pos = { 5, 0 },
		size = { tbMenuCurrentSection.size.w - 10, 80 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		bgImage = "../textures/menu/battlepass/romanpattern2.tga",
		imagePatterned = true
	})
	BattlePass:showProgress(battlePassProgressHolder)

	local battlePassPrizesHolder = tbMenuCurrentSection:addChild(({
		pos = { 5, battlePassProgressHolder.size.h + 10 },
		size = { tbMenuCurrentSection.size.w - leftWidth - 20, tbMenuCurrentSection.size.h - battlePassProgressHolder.size.h - 10 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	}))
	TBMenu:addBottomBloodSmudge(battlePassPrizesHolder, 1)
	BattlePass:showPrizes(battlePassPrizesHolder)

	local battlePassInfoButton = tbMenuCurrentSection:addChild({
		pos = { battlePassPrizesHolder.shift.x + battlePassPrizesHolder.size.w + 10, battlePassProgressHolder.size.h + 10 },
		size = { leftWidth, leftWidth / 2 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		interactive = true,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		hoverSound = 31
	})
	TBMenu:showHomeButton(battlePassInfoButton, {
		image = "../textures/menu/battlepass/battlepass.tga",
		ratio = 0.475,
		action = function() end
	})
	local battlePassQuestsButton = tbMenuCurrentSection:addChild({
		pos = { battlePassInfoButton.shift.x, battlePassInfoButton.shift.y + battlePassInfoButton.size.h + 10 },
		size = { leftWidth, leftWidth },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		interactive = true,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		hoverSound = 31
	})
	TBMenu:showHomeButton(battlePassQuestsButton, {
		image = "../textures/menu/battlepass/battlepassquests.tga",
		ratio = 1,
		action = function() end
	}, 2)
end
