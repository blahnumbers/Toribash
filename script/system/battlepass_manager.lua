-- Battle Pass manager class
-- DO NOT MODIFY THIS FILE
require("system/menu_defines")
require("system/menu_manager")
require("system/store_manager")
require("system/player_info")
require("system/matchmake_manager")

if (BattlePass == nil or TB_MENU_DEBUG) then
	---@class BattlePassLevel
	---@field level integer Battle Pass level ID
	---@field xp integer XP required to get to this level from previous one
	---@field xp_total integer Total XP requirement to get to this level
	---@field tc integer Toricredits reward for this level
	---@field st integer Shiai Tokens reward for this level
	---@field itemid integer Item reward's ID for this level
	---@field tc_premium integer Premium Toricredits reward for this level
	---@field st_premium integer Premium Shiai Tokens reward for this level
	---@field itemid_premium integer Premium item reward's ID for this level

	---@class BattlePassUserData
	---@field level integer Highest level that user has claimed rewards for
	---@field xp integer Total BP XP for user
	---@field premium boolean Whether user has a premium version of the Battle Pass
	---@field level_premium integer Highest premium level that user has claimed rewards for
	---@field level_available integer Target level according to BP XP owned by user
	---@field qi integer Player Qi at the moment of last data fetching
	---@field upgrade_price integer Shiai Token price for upgrading to next BP level

	---@class BattlePassReward
	---@field tc integer
	---@field st integer
	---@field itemid integer
	---@field claimed boolean Whether this reward has already been claimed
	---@field locked boolean Whether this reward is currently available for the user
	---@field premium boolean Whether this is a reward for Premium BP only
	---@field static boolean If true, reward icon will not be interactable
	---@field bgColor Color Background color override
	---@field hoverColor Color Hover color override
	---@field pressedColor Color Pressed color override
	---@field bgOutlineColor Color Outline color override

	---@class BattlePass
	---@field LevelData BattlePassLevel[] Level data for the Battle Pass
	---@field UserData BattlePassUserData Current user's data for the Battle Pass
	---@field wasOpened boolean Whether the user has opened the Battle Pass screen during this session
	BattlePass = {
		__index = {},
		ver = 1.0,
		LevelData = nil,
		UserData = nil,
		wasOpened = false
	}
	setmetatable({}, BattlePass)
end

---@param showBack? boolean Whether to display the "back" button. Assumed false by default.
---@return MenuNavButton[] #Navigation buttons data to be used for TBMenu:showNavigationBar()
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
				TBMenu:showBattlepass()
			end
		})
	end
	return buttonsData
end

-- Queues a network request to download BP level information and stores it in BattlePass.LevelData
---@return nil
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
					local _, segments = ln:gsub("([^\t]*)\t?", "")
					local data = { ln:match(("([^\t]*)\t?"):rep(segments)) }
					table.insert(BattlePass.LevelData, {
						level = tonumber(data[1]) or 0,
						xp = tonumber(data[2]) or 0,
						xp_total = tonumber(data[3]) or 0,
						tc = tonumber(data[4]) or 0,
						st = tonumber(data[5]) or 0,
						itemid = tonumber(data[6]) or 0,
						tc_premium = tonumber(data[7]) or 0,
						st_premium = tonumber(data[8]) or 0,
						itemid_premium = tonumber(data[9]) or 0
					})
				end
			end
			BattlePass.LevelData[0] = {
				xp = 0, xp_total = 0, tc = 0, st = 0, itemid = 0, tc_premium = 0, st_premium = 0, itemid_premium = 0
			}
		end)
end

-- Queues a network request to download user's BP statistics.\
-- If BattlePass.LevelData is empty, triggers BattlePass:getLevelData() first.
---@param viewElement? UIElement Optional viewport to display Battle Pass screen in after successful data request
---@return nil
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
			local _, segments = response:gsub("([^\t]*)\t?", "")
			local data = { response:match(("([^\t]*)\t?"):rep(segments)) }
			BattlePass.UserData = {
				level = tonumber(data[2]) or 0,
				xp = tonumber(data[3]) or 0,
				premium = tonumber(data[4]) == 1,
				level_premium = tonumber(data[5]) or 0,
				qi = TB_MENU_PLAYER_INFO.data.qi,
				upgrade_price = tonumber(data[6]) or 0
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
			elseif (TB_MENU_MAIN_ISOPEN == 1 and TB_MENU_SPECIAL_SCREEN_ISOPEN == 0) then
				tbMenuNavigationBar:kill(true)
				TBMenu:showNavigationBar()
			end
		end)
end

-- Displays main the progress bar for the main Battle Pass screen
---@param viewElement UIElement
---@return nil
function BattlePass:showProgress(viewElement)
	local playerLevelHolder = viewElement:addChild({
		pos = { 0, 0 },
		size = { viewElement.size.w / 5, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_ORANGE,
		uiColor = UICOLORBLACK,
		bgImage = "../textures/menu/battlepass/romanpattern2.tga",
		imagePatterned = true,
		imageColor = { 0.555, 0.362, 0.24, 0.3 }
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
		pos = { playerLevelHolder.size.w, 0 },
		size = { viewElement.size.w - playerLevelHolder.size.w * (BattlePass.UserData.premium and 2 or 2.6), viewElement.size.h }
	})
	local sideShift = 30
	local playerExpInfo = playerExpBarHolder:addChild({
		pos = { sideShift, 10 },
		size = { playerExpBarHolder.size.w / 3, (playerExpBarHolder.size.h - 20) / 2 }
	})
	playerExpInfo:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSEXPERIENCE .. ":^35 " .. PlayerInfo:currencyFormat(BattlePass.UserData.xp) .. (BattlePass.LevelData[BattlePass.UserData.level + 1] and (" / " .. PlayerInfo:currencyFormat(BattlePass.LevelData[BattlePass.UserData.level + 1].xp_total)) or ''), nil, nil, 4, LEFTBOT, 0.75)
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

	local purchaseLevelOrClaimRewardButtonHolder = viewElement:addChild({
		pos = { playerExpBarHolder.shift.x + playerExpBarHolder.size.w + 5, 0 },
		size = { (playerLevelHolder.size.w / (BattlePass.UserData.premium and 1 or 1.6)) - 20, viewElement.size.h }
	})
	local purchaseLevelOrClaimRewardButton = purchaseLevelOrClaimRewardButtonHolder:addChild({
		shift = { 0, 15 },
		interactive = true,
		bgColor = BattlePass.UserData.level == BattlePass.UserData.level_available and TB_MENU_DEFAULT_DARKER_COLOR or TB_MENU_DEFAULT_DARKER_ORANGE,
		hoverColor = BattlePass.UserData.level == BattlePass.UserData.level_available and TB_MENU_DEFAULT_DARKEST_COLOR or TB_MENU_DEFAULT_ORANGE,
		pressedColor = BattlePass.UserData.level == BattlePass.UserData.level_available and TB_MENU_DEFAULT_DARKER_COLOR or TB_MENU_DEFAULT_DARKER_ORANGE,
		shapeType = ROUNDED,
		uiColor = BattlePass.UserData.level == BattlePass.UserData.level_available and UICOLORWHITE or UICOLORBLACK,
		rounded = 4
	})
	local purchaseLevelOrClaimRewardButtonText = purchaseLevelOrClaimRewardButton:addChild({ shift = { 10, 5 } })
	if (BattlePass.UserData.level == BattlePass.UserData.level_available) then
		purchaseLevelOrClaimRewardButton:addMouseUpHandler(BattlePass.spawnPurchaseLevelWindow)
		purchaseLevelOrClaimRewardButtonText:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSPURCHASELEVEL)
	else
		purchaseLevelOrClaimRewardButton:addMouseUpHandler(BattlePass.spawnPrizeClaimWindow)
		purchaseLevelOrClaimRewardButtonText:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSCLAIMREWARD)
	end

	if (not BattlePass.UserData.premium) then
		local purchasePremiumHolder = viewElement:addChild({
			pos = { purchaseLevelOrClaimRewardButtonHolder.shift.x + purchaseLevelOrClaimRewardButtonHolder.size.w + 10, 0 },
			size = { viewElement.size.w - (purchaseLevelOrClaimRewardButtonHolder.shift.x + purchaseLevelOrClaimRewardButtonHolder.size.w + 30), viewElement.size.h }
		})
		local purchasePremiumButton = purchasePremiumHolder:addChild({
			shift = { 0, 15 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_ORANGE,
			hoverColor = TB_MENU_DEFAULT_ORANGE,
			pressedColor = TB_MENU_DEFAULT_DARKER_ORANGE,
			uiColor = UICOLORBLACK,
			shapeType = ROUNDED,
			rounded = 4
		})
		local purchasePremiumButtonText = purchasePremiumButton:addChild({ shift = { 10, 5 } })
		purchasePremiumButton:addMouseUpHandler(BattlePass.spawnPurchasePrimeWindow)
		purchasePremiumButtonText:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSPURCHASEPREMIUM)
	end

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

-- Returns a table with currently available BP rewards for the user
---@param override? table Allows to override user's actual `level_available` and `premium` values
---@return BattlePassReward[]
function BattlePass:getUserAvailableRewards(override)
	local claimRewards = {}
	local tcReward, stReward = 0, 0
	local levelAvailable = (override and override.level) and override.level or BattlePass.UserData.level_available
	local premiumAvailable = (override and override.premium) and override.premium or BattlePass.UserData.premium
	for i,v in ipairs(BattlePass.LevelData) do
		if (v.level > BattlePass.UserData.level and v.level <= levelAvailable) then
			tcReward = tcReward + v.tc
			stReward = stReward + v.st
			if (v.itemid > 0) then
				table.insert(claimRewards, { itemid = v.itemid, static = true })
			end
		end
		if (premiumAvailable) then
			if (v.level > BattlePass.UserData.level_premium and v.level <= levelAvailable) then
				tcReward = tcReward + v.tc_premium
				stReward = stReward + v.st_premium
				if (v.itemid_premium > 0) then
					table.insert(claimRewards, { itemid = v.itemid_premium, premium = true, static = true })
				end
			end
		end
	end
	if (tcReward > 0) then
		table.insert(claimRewards, 1, { tc = tcReward, static = true })
	end
	if (stReward > 0) then
		table.insert(claimRewards, 2, { st = stReward, static = true })
	end

	return claimRewards
end

---@return nil
function BattlePass:spawnPurchasePrimeWindow()
	local item = Torishop:getItemInfo(BATTLEPASS_SUBSCRIPTION_ITEM)
	local targetLevel = BattlePass.UserData.level_available + 1
	local claimWindowBackground
	claimWindowBackground = BattlePass:spawnPrizeConfirmationWindow(
		TB_MENU_LOCALIZED.BATTLEPASSPURCHASEPREMIUM,
		TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " $" .. PlayerInfo:currencyFormat(item.now_usd_price) .. "?",
		function()
			if (is_steam()) then
				runCmd("steam purchase " .. item.itemid)
				claimWindowBackground:kill(true)
				claimWindowBackground.size.h = 100
				claimWindowBackground.size.w = 300
				claimWindowBackground:moveTo((WIN_W - claimWindowBackground.size.w) / 2, (WIN_H - claimWindowBackground.size.h) / 2)
				TBMenu:displayLoadingMark(claimWindowBackground, TB_MENU_LOCALIZED.STOREPROCESSINGSTEAMPURCHASE)
				claimWindowBackground.parent:addMouseMoveHandler(function()
					claimWindowBackground.parent:kill()
					if (get_purchase_done() == 1) then
						TBMenu:showDataError(TB_MENU_LOCALIZED.BATTLEPASSPURCHASEPREMIUMSUCCESS)
						BattlePass.UserData = nil
						BattlePass:showMain()
						Notifications:getTotalNotifications(true)
					else
						TBMenu:showDataError(TB_MENU_LOCALIZED.STOREPURCHASESTEAMCANCELLED)
					end
				end)
			else
				open_url("https://forum.toribash.com/tori_shop.php?action=process&item=" .. item.itemid)
			end
		end,
		{ premium = true })
end

---@return nil
function BattlePass:spawnPurchaseLevelWindow()
	---@type UIElement
	local claimWindowBackground
	local targetLevel = BattlePass.UserData.level_available + 1
	claimWindowBackground = BattlePass:spawnPrizeConfirmationWindow(
		TB_MENU_LOCALIZED.BATTLEPASSPURCHASELEVELTITLE .. " " .. targetLevel,
		TB_MENU_LOCALIZED.BATTLEPASSPURCHASELEVELINFO .. "\n\n" .. TB_MENU_LOCALIZED.BATTLEPASSYOUWILLRECEIVEREWARDS,
		function()
			Request:queue(function()
				claimWindowBackground:kill(true)
				claimWindowBackground:hide()
				claimWindowBackground.parent:addMouseMoveHandler(function(x)
						if (x < WIN_W / 2) then
							Request:finalize("battlepass_purchaselevel")
							claimWindowBackground.parent:kill()
						else
							claimWindowBackground.parent:addMouseMoveHandler(function() end)
							claimWindowBackground:show()
							TBMenu:displayLoadingMarkSmall(claimWindowBackground, TB_MENU_LOCALIZED.NETWORKLOADING)
						end
					end)
				show_dialog_box(BATTLEPASS_PURCHASE_LEVEL, "Are you sure you want to upgrade your Battle Pass to level " .. targetLevel .. "?\n\n^35" .. TB_MENU_LOCALIZED.MARKETYOUWILLBECHARGED .. " " .. BattlePass.UserData.upgrade_price .. " " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS, BattlePass.UserData.upgrade_price, true)
			end, "battlepass_purchaselevel", function()
					local response = get_network_response()
					if (response:find("^GATEWAY 0; 0")) then
						claimWindowBackground.parent:kill()
						TBMenu:showDataError(TB_MENU_LOCALIZED.BATTLEPASSPURCHASELEVELSUCCESS)
						BattlePass.UserData = nil
						BattlePass:showMain()
					else
						local error = response:gsub("^GATEWAY %d; %d", "")
						claimWindowBackground:kill(true)
						local textBG = claimWindowBackground:addChild({ shift = { 30, 80 }})
						textBG:moveTo(nil, -40, true)
						textBG:addAdaptedText(true, error)
						local okButton = claimWindowBackground:addChild({
							pos = { claimWindowBackground.size.w / 4, -claimWindowBackground.size.h / 7 - 10 },
							size = { claimWindowBackground.size.w / 2, claimWindowBackground.size.h / 7 },
							interactive = true,
							bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
							hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
							pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
							shapeType = ROUNDED,
							rounded = 4
						})
						okButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONOK)
						okButton:addMouseHandlers(nil, function() claimWindowBackground.parent:kill() end)
					end
				end)
		end,
		{ level = BattlePass.UserData.level_available + 1 })
end

---@return nil
function BattlePass:spawnPrizeClaimWindow()
	local claimWindowBackground
	claimWindowBackground = BattlePass:spawnPrizeConfirmationWindow(
		TB_MENU_LOCALIZED.BATTLEPASSCLAIMREWARDTITLE,
		TB_MENU_LOCALIZED.BATTLEPASSYOUWILLRECEIVEREWARDS,
		function()
			claimWindowBackground:kill(true)
			TBMenu:displayLoadingMark(claimWindowBackground, TB_MENU_LOCALIZED.REWARDSCLAIMINPROGRESS)
			Request:queue(function() battlepass_claim_reward() end, "battlepass_claimreward", function()
					local response = get_network_response()
					if (response:find("^GATEWAY 0; 0")) then
						claimWindowBackground.parent:kill()
						TBMenu:showDataError(TB_MENU_LOCALIZED.BATTLEPASSCLAIMSUCCESS)
						BattlePass.UserData = nil
						BattlePass:showMain()
					else
						claimWindowBackground:kill(true)
						local textBG = claimWindowBackground:addChild({ shift = { 30, 80 }})
						textBG:moveTo(nil, -40, true)
						textBG:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSCLAIMERROR)
						local okButton = claimWindowBackground:addChild({
							pos = { claimWindowBackground.size.w / 4, -claimWindowBackground.size.h / 7 - 10 },
							size = { claimWindowBackground.size.w / 2, claimWindowBackground.size.h / 7 },
							interactive = true,
							bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
							hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
							pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
							shapeType = ROUNDED,
							rounded = 4
						})
						okButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONOK)
						okButton:addMouseHandlers(nil, function() claimWindowBackground.parent:kill() end)
					end
				end)
		end)
end

---Spawns a generic Battle Pass confirmation window and displays the available rewards
---@param title string
---@param message string
---@param onConfirm function Function that will be executed on confirm button press
---@param override? table Overrides to get available rewards
---@return UIElement
function BattlePass:spawnPrizeConfirmationWindow(title, message, onConfirm, override)
	local overlay = TBMenu:spawnWindowOverlay()
	local windowHeight = math.min(300, WIN_H / 2)
	local claimWindowBackground = overlay:addChild({
		shift = { WIN_W / 4, (WIN_H - windowHeight) / 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 5
	})
	local claimWindowText = claimWindowBackground:addChild({
		pos = { 20, claimWindowBackground.size.h / 30 },
		size = { claimWindowBackground.size.w - 40, claimWindowBackground.size.h / 7 }
	})
	claimWindowText:addAdaptedText(true, title, nil, nil, FONTS.BIG)
	local claimWindowInfoText = claimWindowBackground:addChild({
		pos = { 20, claimWindowText.shift.y * 1.6 + claimWindowText.size.h },
		size = { claimWindowBackground.size.w - 40, claimWindowBackground.size.h / 4 }
	})
	claimWindowInfoText:addAdaptedText(true, message, nil, nil, 4, nil, 0.8)
	local claimWindowRewards = claimWindowBackground:addChild({
		pos = { 20, claimWindowInfoText.shift.y + claimWindowInfoText.size.h + claimWindowText.shift.y },
		size = { claimWindowBackground.size.w - 40, claimWindowBackground.size.h / 4 }
	})

	local claimRewards = BattlePass:getUserAvailableRewards(override)

	local prizeDisplaySize = math.min(80, claimWindowRewards.size.h)
	local maxRewards = math.floor(claimWindowRewards.size.w / (prizeDisplaySize + 5))
	local startPos = (claimWindowRewards.size.w - math.min(maxRewards, #claimRewards) * (prizeDisplaySize + 5)) / 2 + 2.5
	for i,v in pairs(claimRewards) do
		local prizeView = claimWindowRewards:addChild({
			pos = { startPos + (prizeDisplaySize + 5) * (i - 1), (claimWindowRewards.size.h - prizeDisplaySize) / 2 },
			size = { prizeDisplaySize, prizeDisplaySize }
		})
		BattlePass:showPrizeItem(prizeView, v)
		if (i >= maxRewards) then break end
		if (#claimRewards > maxRewards and i == maxRewards - 1) then
			local morePrizesView = claimWindowRewards:addChild({
				pos = { startPos + (prizeDisplaySize + 5) * i, (claimWindowRewards.size.h - prizeDisplaySize) / 2 },
				size = { prizeDisplaySize, prizeDisplaySize }
			})
			local morePrizesViewTop = morePrizesView:addChild({
				pos = { 0, 0 },
				size = { prizeDisplaySize, prizeDisplaySize * 0.6 }
			})
			morePrizesViewTop:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSANDMORE1 .. " " .. (#claimRewards - i), nil, nil, FONTS.BIG, CENTERBOT, 0.65)
			local morePrizesViewBot = morePrizesView:addChild({
				pos = { 0, morePrizesViewTop.size.h },
				size = { prizeDisplaySize, morePrizesView.size.h - morePrizesViewTop.size.h }
			})
			morePrizesViewBot:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSANDMORE2, nil, nil, nil, CENTER)
			break
		end
	end

	local cancelButton = claimWindowBackground:addChild({
		pos = { claimWindowBackground.size.w * 0.08, -claimWindowBackground.size.h / 7 - 15 },
		size = { claimWindowBackground.size.w * 0.4, claimWindowBackground.size.h / 7 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	cancelButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCANCEL)
	cancelButton:addMouseHandlers(nil, function() overlay:kill() end)
	local acceptButton = claimWindowBackground:addChild({
		pos = { -claimWindowBackground.size.w * 0.48, -claimWindowBackground.size.h / 7 - 15 },
		size = { claimWindowBackground.size.w * 0.4, claimWindowBackground.size.h / 7 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4
	})
	acceptButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCONTINUE)
	acceptButton:addMouseHandlers(nil, onConfirm)

	return claimWindowBackground
end

---Displays a BP prize in a provided UIElement viewport
---@param viewElement UIElement
---@param prize BattlePassReward
---@return nil
function BattlePass:showPrizeItem(viewElement, prize)
	local prizeDisplayScale = math.min(viewElement.size.w, viewElement.size.h)
	local prizeBackgroundOutline = viewElement:addChild({
		shift = { (viewElement.size.w - prizeDisplayScale) / 2, (viewElement.size.h - prizeDisplayScale) / 2 },
		bgColor = prize.bgOutlineColor or (prize.premium and TB_MENU_DEFAULT_DARKEST_BLUE or TB_MENU_DEFAULT_DARKEST_ORANGE),
		shapeType = ROUNDED,
		rounded = 10
	})
	local prizeBackground = prizeBackgroundOutline:addChild({
		shift = { 2, 2 },
		bgColor = prize.bgColor or (prize.premium and TB_MENU_DEFAULT_DARKER_BLUE or TB_MENU_DEFAULT_DARKER_ORANGE),
		interactive = not prize.static and not prize.locked and not prize.claimed,
		hoverColor = prize.hoverColor or (prize.premium and TB_MENU_DEFAULT_BLUE or TB_MENU_DEFAULT_ORANGE),
		pressedColor = prize.bgColor or (prize.premium and TB_MENU_DEFAULT_DARKER_BLUE or TB_MENU_DEFAULT_DARKER_ORANGE)
	}, true)

	local prizeIcon, prizeAmount
	-- Some free reward levels will have multiple rewards, we want TC/ST to be shown
	if (prize.tc) then
		prizeIcon = "../textures/store/toricredit.tga"
		prizeAmount = PlayerInfo:currencyFormat(prize.tc)
	elseif (prize.st) then
		prizeIcon = "../textures/store/shiaitoken.tga"
		prizeAmount = PlayerInfo:currencyFormat(prize.st)
	elseif (prize.itemid) then
		 prizeIcon = Torishop:getItemIcon(prize.itemid)
	else
		return
	end

	local prizeIcon = prizeBackground:addChild({
		shift = { 8, 8 },
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
	else
		prizeBackground:addMouseHandlers(nil, BattlePass.spawnPrizeClaimWindow)
	end

	if (prize.tc or prize.st) then
		local prizeText = prizeBackgroundOutline:addChild({
			pos = { 0, -30 },
			size = { prizeBackgroundOutline.size.w, 30 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS,
			shapeType = ROUNDED,
			rounded = { 0, prizeBackgroundOutline.rounded }
		})
		prizeText:addChild({ shift = { 5, 2 } }):addAdaptedText(true, prizeAmount)
	end
end

---Displays BP level prize in a specified UIElement viewport
---@param prizeHolder UIElement
---@param levelData BattlePassLevel
---@return nil
function BattlePass:showLevelPrize(prizeHolder, levelData)
	local prizeLevel = prizeHolder:addChild({
		pos = { 10, 10 },
		size = { prizeHolder.size.w - 20, 30 }
	})
	prizeLevel:addAdaptedText(nil, TB_MENU_LOCALIZED.BATTLEPASSLVL .. " " .. levelData.level)
	local prizeBackground = prizeHolder:addChild({
		pos = { 3, 50 },
		size = { prizeHolder.size.w - 6, prizeHolder.size.h - 50 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	if (levelData.st > 0 or levelData.tc > 0 or levelData.itemid > 0) then
		local freePrizeHolder = prizeBackground:addChild({
			pos = { 0, 0 },
			size = { prizeBackground.size.w, (prizeBackground.size.h - 20) / 3 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		BattlePass:showPrizeItem(freePrizeHolder:addChild({ shift = { 15, 10 } }), {
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
	local prizeHolderHeight = math.min(prizeBackground.size.w - 30, (prizeBackground.size.h / 3 * 2 - 10 * (#premiumPrizes - 1)) / #premiumPrizes)
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

---Displays all BP rewards for main Battle Pass view
---@param viewElement UIElement
---@return nil
function BattlePass:showPrizes(viewElement)
	local prizeHolderSize = math.min(120, WIN_W / 12)
	local toReload, leftBar, rightBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, prizeHolderSize, prizeHolderSize, 20, TB_MENU_DEFAULT_DARKER_COLOR, SCROLL_HORIZONTAL)

	---@type BattlePassLevel
	local closest10LevelReward = BattlePass.LevelData[#BattlePass.LevelData]
	local listElements = {}
	for j = 1, 10 do
		for i,v in ipairs(BattlePass.LevelData) do
			local prizeHolder = UIElement:new({
				parent = listingHolder,
				pos = { #listElements * prizeHolderSize, 0 },
				size = { prizeHolderSize, listingHolder.size.h },
			})
			table.insert(listElements, prizeHolder)
			BattlePass:showLevelPrize(prizeHolder, v)

			if (not closest10LevelReward and v.level % 10 == 0 and BattlePass.UserData.level <= v.level) then
				closest10LevelReward = v
			end
		end
	end

	for i,v in pairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, prizeHolderSize, SCROLL_HORIZONTAL)
	listingHolder.scrollBar = scrollBar
	scrollBar:makeHorizontalScrollBar(listingHolder, listElements, toReload, nil, 0.4)

	local leftBarFade = leftBar:addChild({
		pos = { leftBar.size.w, 0 },
		size = { 8, leftBar.size.h - listingScrollBG.size.h },
		bgImage = "../textures/menu/battlepass/fadegradientleft.tga",
		imagePatterned = true,
		imageColor = { 0, 0, 0, 0.4 }
	})
	local rightBarFade = rightBar:addChild({
		pos = { -rightBar.size.w - 8, 0 },
		size = { 8, leftBarFade.size.h },
		bgImage = "../textures/menu/battlepass/fadegradientright.tga",
		imagePatterned = true,
		imageColor = { 0, 0, 0, 0.4 }
	})

	-- Display top unclaimed prize (or max level if all levels have already been claimed)
	local levelName = rightBar:addChild({
		pos = { 10, rightBar.size.h / 40 },
		size = { rightBar.size.w - 20, rightBar.size.h / 10 }
	})
	levelName:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSLVL .. " " .. closest10LevelReward.level, nil, nil, FONTS.BIG, nil, 0.7)

	local availablePrizes = {}
	if (closest10LevelReward.st > 0) then
		table.insert(availablePrizes, {
			st = closest10LevelReward.st,
			locked = BattlePass.UserData.level_available < closest10LevelReward.level,
			claimed = BattlePass.UserData.level >= closest10LevelReward.level,
			static = true
		})
	end
	if (closest10LevelReward.tc > 0) then
		table.insert(availablePrizes, {
			tc = closest10LevelReward.tc,
			locked = BattlePass.UserData.level_available < closest10LevelReward.level,
			claimed = BattlePass.UserData.level >= closest10LevelReward.level,
			static = true
		})
	end
	if (closest10LevelReward.itemid > 0) then
		table.insert(availablePrizes, {
			itemid = closest10LevelReward.itemid,
			locked = BattlePass.UserData.level_available < closest10LevelReward.level,
			claimed = BattlePass.UserData.level >= closest10LevelReward.level,
			static = true
		})
	end
	if (closest10LevelReward.st_premium > 0) then
		table.insert(availablePrizes, {
			st = closest10LevelReward.st_premium,
			locked = not BattlePass.UserData.premium or BattlePass.UserData.level_available < closest10LevelReward.level,
			claimed = BattlePass.UserData.level_premium >= closest10LevelReward.level,
			premium = true,
			static = true
		})
	end
	if (closest10LevelReward.tc_premium > 0) then
		table.insert(availablePrizes, {
			tc = closest10LevelReward.tc_premium,
			locked = not BattlePass.UserData.premium or BattlePass.UserData.level_available < closest10LevelReward.level,
			claimed = BattlePass.UserData.level_premium >= closest10LevelReward.level,
			premium = true,
			static = true
		})
	end
	if (closest10LevelReward.itemid_premium > 0) then
		table.insert(availablePrizes, {
			itemid = closest10LevelReward.itemid_premium,
			locked = not BattlePass.UserData.premium or BattlePass.UserData.level_available < closest10LevelReward.level,
			claimed = BattlePass.UserData.level_premium >= closest10LevelReward.level,
			premium = true,
			static = true
		})
	end
	local topPrizeBackground = rightBar:addChild({
		pos = { 5, levelName.shift.y * 2 + levelName.size.h },
		size = { rightBar.size.w - 10, rightBar.size.h - (levelName.shift.y * 2 + levelName.size.h) }
	})
	local distanceBetweenPrizes = math.max(10, 35 - #availablePrizes * 5)
	local prizeHolderHeight = math.min(topPrizeBackground.size.w - 30, (topPrizeBackground.size.h - distanceBetweenPrizes * (#availablePrizes - 1)) / #availablePrizes)
	local topPrizesHolder = topPrizeBackground:addChild({
		pos = { 0, -topPrizeBackground.size.h / 2 - (prizeHolderHeight + distanceBetweenPrizes) * #availablePrizes / 2 },
		size = { topPrizeBackground.size.w, (prizeHolderHeight + distanceBetweenPrizes) * #availablePrizes }
	})
	for i,v in pairs(availablePrizes) do
		local topPrizeHolder = topPrizesHolder:addChild({
			pos = { 0, (prizeHolderHeight + distanceBetweenPrizes) * (i - 1) },
			size = { topPrizeBackground.size.w, prizeHolderHeight }
		})
		BattlePass:showPrizeItem(topPrizeHolder, v)
	end
end

---Displays Battle Pass main screen
---@return nil
function BattlePass:showMain()
	tbMenuCurrentSection:kill(true)

	if (not BattlePass.UserData or BattlePass.UserData.qi ~= TB_MENU_PLAYER_INFO.data.qi) then
		local battlePassLoading = tbMenuCurrentSection:addChild({
			shift = { 5, 0 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(battlePassLoading)
		TBMenu:displayLoadingMark(battlePassLoading, TB_MENU_LOCALIZED.BATTLEPASSLOADING)
		BattlePass:getUserData(battlePassLoading)
		return
	end

	local leftHeight = (tbMenuCurrentSection.size.h - 90) / 3 - 5
	local leftWidth = math.min(leftHeight * 2.5, tbMenuCurrentSection.size.w * 0.3)
	local battlePassProgressHolder = tbMenuCurrentSection:addChild({
		pos = { 5, 0 },
		size = { tbMenuCurrentSection.size.w - 10, 80 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		bgImage = "../textures/menu/battlepass/romanpattern2.tga",
		imagePatterned = true,
		imageColor = { 0.824, 0.749, 0.482, 0.2 }
	})
	BattlePass:showProgress(battlePassProgressHolder)

	local battlePassPrizesHolder = tbMenuCurrentSection:addChild(({
		pos = { 5, battlePassProgressHolder.size.h + 10 },
		size = { tbMenuCurrentSection.size.w - leftWidth - 20, tbMenuCurrentSection.size.h - battlePassProgressHolder.size.h - 10 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	}))
	TBMenu:addBottomBloodSmudge(battlePassPrizesHolder, 1)
	BattlePass:showPrizes(battlePassPrizesHolder)

	local battlePassInfoButton = tbMenuCurrentSection:addChild({
		pos = { battlePassPrizesHolder.shift.x + battlePassPrizesHolder.size.w + 10, battlePassProgressHolder.size.h + 10 },
		size = { leftWidth, leftHeight },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = true,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		hoverSound = 31
	})
	TBMenu:showHomeButton(battlePassInfoButton, {
		image = "../textures/menu/battlepass/battlepass.tga",
		ratio = 0.375,
		action = function() end
	})
	local battlePassSeasonButton = tbMenuCurrentSection:addChild({
		pos = { battlePassInfoButton.shift.x, battlePassInfoButton.shift.y + battlePassInfoButton.size.h + 10 },
		size = { leftWidth, leftHeight },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = true,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		hoverSound = 31
	})
	TBMenu:showHomeButton(battlePassSeasonButton, {
		image = "../textures/menu/battlepass/season8.tga",
		ratio = 0.375,
		disableUnload = true,
		locked = TB_MENU_PLAYER_INFO.data.qi < 200,
		lockedMessage = "Unlocks at Blue Belt",
		action = Matchmake.showGlobalRanking
	})
	local battlePassQuestsButton = tbMenuCurrentSection:addChild({
		pos = { battlePassInfoButton.shift.x, battlePassSeasonButton.shift.y + battlePassSeasonButton.size.h + 10 },
		size = { leftWidth, leftHeight },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = true,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		hoverSound = 31
	})
	TBMenu:showHomeButton(battlePassQuestsButton, {
		image = "../textures/menu/battlepass/battlepassquests.tga",
		ratio = 0.375,
		action = function()
			Quests:showMain(true, function()
					TBMenu:clearNavSection()
					TBMenu:showNavigationBar()
					BattlePass:showMain()
				end)
		end
	}, 2)
end

if (not BattlePass.UserData) then
	BattlePass:getUserData()
end
