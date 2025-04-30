-- Battle Pass manager class
-- DO NOT MODIFY THIS FILE
require("system.menu_defines")
require("system.menu_manager")
require("system.store_manager")
require("system.ranking_manager")

if (BattlePass == nil) then
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
	---@field item StoreItem Item reward for this level
	---@field item_premium StoreItem Premium item reward for this level

	---@class BattlePassUserData
	---@field level integer Highest level that user has claimed rewards for
	---@field xp integer Total BP XP for user
	---@field premium boolean Whether user has a premium version of the Battle Pass
	---@field level_premium integer Highest premium level that user has claimed rewards for
	---@field level_available integer Target level according to BP XP owned by user
	---@field qi integer Player Qi at the moment of last data fetching
	---@field upgrade_price integer Shiai Token price for upgrading to next BP level

	---@class BattlePassReward : EventRewardBase
	---@field item StoreItem?
	---@field claimed boolean Whether this reward has already been claimed
	---@field locked boolean Whether this reward is currently available for the user
	---@field premium boolean Whether this is a reward for Premium BP only
	---@field static boolean If true, reward icon will not be interactable
	---@field bgColor Color Background color override
	---@field hoverColor Color Hover color override
	---@field pressedColor Color Pressed color override
	---@field bgOutlineColor Color Outline color override
	---@field textBackdropColor Color Backdrop color override used for prize text info
	---@field textColor Color Prize text info color override
	---@field withoutPopup boolean?

	---**Battle Pass manager class**
	---
	---**Version 5.74**
	---* Better display for premium levels with multiple rewards
	---
	---**Version 5.65**
	---* Tweaks to prevent data update spam when BP isn't active
	---
	---**Version 5.62**
	---* Queue missing prize item textures for download
	---
	---**Version 5.61**
	---* Added `QiRequirement` field
	---
	---**Version 5.60**
	---* Rewards popup display offset fix for Shiai Tokens
	---* Minor visual tweaks for user xp bar
	---
	---**Version 1.0**
	---* Initial release
	---@class BattlePass
	---@field LevelData BattlePassLevel[]? Level data for the Battle Pass
	---@field UserData BattlePassUserData? Current user's data for the Battle Pass
	---@field TimeLeft integer Time left in seconds until this BP is over
	---@field MaxLevelPrizes integer Max number of prizes in a single level available for claiming
	---@field QiRequirement integer User qi requirement to access Battle Pass
	---@field wasOpened boolean Whether the user has opened the Battle Pass screen during this session
	BattlePass = {
		ver = 5.74,
		TimeLeft = -1,
		MaxLevelPrizes = 2,
		QiRequirement = 20,
		wasOpened = false
	}
	BattlePass.__index = BattlePass
end

-- Queues a network request to download BP level information and stores it in BattlePass.LevelData
function BattlePass:getLevelData()
	Request:queue(function() download_server_info("battlepass&get=levels") end, "battlepass_levels", function()
			local response = get_network_response()
			if (not response:find("^LEVEL")) then
				BattlePass.LevelData = { }
				return
			end
			BattlePass.LevelData = { }
			BattlePass.MaxLevelPrizes = 2
			for ln in response:gmatch("[^\n]+\n?") do
				if (not ln:find("^LEVEL")) then
					local _, segments = ln:gsub("([^\t]*)\t?", "")
					local data = { ln:match(("([^\t]*)\t?"):rep(segments)) }
					---@type BattlePassLevel
					local levelData = {
						level = tonumber(data[1]) or 0,
						xp = tonumber(data[2]) or 0,
						xp_total = tonumber(data[3]) or 0,
						tc = tonumber(data[4]) or 0,
						st = tonumber(data[5]) or 0,
						itemid = tonumber(data[6]) or 0,
						tc_premium = tonumber(data[7]) or 0,
						st_premium = tonumber(data[8]) or 0,
						itemid_premium = tonumber(data[9]) or 0
					}
					levelData.item = Store:getItemInfo(levelData.itemid)
					levelData.item_premium = Store:getItemInfo(levelData.itemid_premium)
					local levelPrizes = 0
					for i, v in pairs(levelData) do
						if (not in_array(i, { "level", "xp", "xp_total" }) and type(v) == "number") then
							if (v > 0) then
								levelPrizes = levelPrizes + 1
							end
						end
					end
					table.insert(BattlePass.LevelData, levelData)
					BattlePass.MaxLevelPrizes = math.max(BattlePass.MaxLevelPrizes, levelPrizes)
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
					viewElement:addAdaptedText(false, TB_MENU_LOCALIZED.ACCOUNTINFOERROR)
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
				upgrade_price = tonumber(data[6]) or 0,
				level_available = 0
			}
			BattlePass.TimeLeft = tonumber(data[7]) or 0
			BattlePass.UpdateTimestamp = os.time()
			for _, v in ipairs(BattlePass.LevelData) do
				if (v.xp_total <= BattlePass.UserData.xp) then
					BattlePass.UserData.level_available = v.level
				else
					break
				end
			end
			if (Quests.QuestsData ~= nil) then
				Quests:addBattlePassQuests()
			end
			if (viewElement and not viewElement.destroyed) then
				BattlePass:showMain()
			else
				TBMenu:reloadNavigationIfNeeded()
			end
		end)
end

-- Displays main the progress bar for the main Battle Pass screen
---@param viewElement UIElement
function BattlePass:showProgress(viewElement)
	local playerLevelHolder = viewElement:addChild({
		pos = { 0, 0 },
		size = { viewElement.size.w / 5, viewElement.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_ORANGE,
		uiShadowColor = TB_MENU_DEFAULT_ORANGE,
		uiColor = UICOLORBLACK,
		bgImage = "../textures/menu/battlepass/tcpattern.tga",
		imagePatterned = true
	})
	local playerLevelDisplay = playerLevelHolder:addChild({
		pos = { 5, 5 },
		size = { playerLevelHolder.size.w - 10, playerLevelHolder.size.h - 10 },
		shadowOffset = 2.4
	})
	playerLevelDisplay:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSLEVEL, nil, nil, FONTS.BIG, LEFTMID, 0.6, nil, 0, 4)

	local shift = 10 + get_string_length(playerLevelDisplay.dispstr[1], playerLevelDisplay.textFont) * playerLevelDisplay.textScale
	local playerLevelDisplayLevel = playerLevelDisplay:addChild({
		pos = { shift, 0 },
		size = { playerLevelHolder.size.w * 0.9 - shift, playerLevelDisplay.size.h },
		shadowOffset = 3.6
	})
	playerLevelDisplayLevel:addAdaptedText(true, BattlePass.UserData.level .. '', nil, nil, FONTS.BIG, LEFTMID, 0.9, nil, 0, 4)
	local totalWidth = shift + get_string_length(playerLevelDisplayLevel.dispstr[1], playerLevelDisplayLevel.textFont) * playerLevelDisplayLevel.textScale

	playerLevelDisplay:moveTo((playerLevelDisplay.size.w - totalWidth) / 2, nil, true)

	local playerExpBarHolder = viewElement:addChild({
		pos = { playerLevelHolder.size.w, 0 },
		size = { viewElement.size.w - playerLevelHolder.size.w * (BattlePass.UserData.premium and 2 or 2.6), viewElement.size.h }
	})
	local sideShift = 30
	local playerExpInfo = playerExpBarHolder:addChild({
		pos = { sideShift, 10 },
		size = { playerExpBarHolder.size.w - sideShift * 2, (playerExpBarHolder.size.h - 20) / 2 },
		uiShadowColor = TB_MENU_DEFAULT_BG_COLOR
	})
	playerExpInfo:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSEXPERIENCE .. ":", nil, nil, 4, LEFTBOT, 0.75, nil, nil, 4)
	local bpExpLength = get_string_length(playerExpInfo.dispstr[1], playerExpInfo.textFont) * playerExpInfo.textScale + 6
	playerExpInfo:addChild({
		pos = { bpExpLength, 0 },
		size = { playerExpInfo.size.w - bpExpLength, playerExpInfo.size.h },
		uiColor = TB_MENU_DEFAULT_YELLOW,
		uiShadowColor = TB_MENU_DEFAULT_BG_COLOR
	}):addAdaptedText(true, numberFormat(BattlePass.UserData.xp) .. (BattlePass.LevelData[BattlePass.UserData.level + 1] and (" / " .. numberFormat(BattlePass.LevelData[BattlePass.UserData.level + 1].xp_total)) or ''), nil, nil, 4, LEFTBOT, 0.75, nil, nil, 4)
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
		inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
		rounded = 4
	})
	local purchaseLevelOrClaimRewardButtonText = purchaseLevelOrClaimRewardButton:addChild({ shift = { 10, 5 } })
	if (BattlePass.UserData.level == BattlePass.UserData.level_available) then
		if (BattlePass.UserData.level == #BattlePass.LevelData) then
			purchaseLevelOrClaimRewardButton:deactivate()
			local popup = TBMenu:displayPopup(purchaseLevelOrClaimRewardButton, TB_MENU_LOCALIZED.BATTLEPASSREACHEDMAXLEVEL, true)
			if (popup ~= nil) then
				popup:moveTo(-purchaseLevelOrClaimRewardButton.size.w - (popup.size.w - purchaseLevelOrClaimRewardButton.size.w) / 2, purchaseLevelOrClaimRewardButton.size.h + 5)
				if (popup.pos.x + popup.size.w >= WIN_W - 10) then
					popup:moveTo(-(popup.pos.x + popup.size.w - (WIN_W - 10)), nil, true)
				end
			end
		else
			purchaseLevelOrClaimRewardButton:addMouseUpHandler(BattlePass.spawnPurchaseLevelWindow)
		end
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

	local lineColor = table.clone(TB_MENU_DEFAULT_DARKER_ORANGE)
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
---@param override? BattlePassUserData Allows to override user's actual `level_available` and `premium` values
---@return BattlePassReward[]
function BattlePass:getUserAvailableRewards(override)
	local claimRewards = {}
	local tcReward, stReward = 0, 0
	local levelAvailable = (override and override.level) and override.level or BattlePass.UserData.level_available
	local premiumAvailable = (override and override.premium) and override.premium or BattlePass.UserData.premium
	for _, v in ipairs(BattlePass.LevelData) do
		if (v.level > BattlePass.UserData.level and v.level <= levelAvailable) then
			tcReward = tcReward + v.tc
			stReward = stReward + v.st
			if (v.itemid > 0) then
				table.insert(claimRewards, { itemid = v.itemid, item = v.item, static = true })
			end
		end
		if (premiumAvailable) then
			if (v.level > BattlePass.UserData.level_premium and v.level <= levelAvailable) then
				tcReward = tcReward + v.tc_premium
				stReward = stReward + v.st_premium
				if (v.itemid_premium > 0) then
					table.insert(claimRewards, { itemid = v.itemid_premium, item = v.item_premium, premium = true, static = true })
				end
			end
		end
	end
	if (tcReward > 0) then
		table.insert(claimRewards, 1, { tc = tcReward, static = true })
		if (stReward > 0) then
			table.insert(claimRewards, 2, { st = stReward, static = true })
		end
	elseif (stReward > 0) then
		table.insert(claimRewards, 1, { st = stReward, static = true })
	end


	return claimRewards
end

---Displays BattlePass Premium purchase popup
function BattlePass:spawnPurchasePrimeWindow()
	local item = Store:getItemInfo(BATTLEPASS_SUBSCRIPTION_ITEM)
	local displayPrice = "$" .. numberFormat(item.now_usd_price)
	if (_G.PLATFORM == "IPHONEOS") then
		displayPrice = utf8.gsub(get_platform_item_price(item.itemid), "%s", " ")
	end
	local claimWindowBackground
	claimWindowBackground = BattlePass:spawnPrizeConfirmationWindow(
		TB_MENU_LOCALIZED.BATTLEPASSPURCHASEPREMIUM,
		TB_MENU_LOCALIZED.STOREPURCHASECONFIRM .. " " .. item.itemname .. " " .. TB_MENU_LOCALIZED.STOREPURCHASEFOR .. " " .. displayPrice .. "?",
		function() claimWindowBackground.parent:kill() Store.InitUSDPurchase(item) end,
		{ premium = true })
end

---Displays BattlePass level purchase window
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
				show_dialog_box(BATTLEPASS_PURCHASE_LEVEL, "Are you sure you want to upgrade your Battle Pass to level " .. targetLevel .. "?\n\n^35" .. TB_MENU_LOCALIZED.MARKETYOUWILLBECHARGED .. " " .. BattlePass.UserData.upgrade_price .. " " .. TB_MENU_LOCALIZED.WORDSHIAITOKENS, BattlePass.UserData.upgrade_price .. "", true)
			end, "battlepass_purchaselevel", function()
					local response = get_network_response()
					if (response:find("^GATEWAY 0; 0")) then
						claimWindowBackground.parent:kill()
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.BATTLEPASSPURCHASELEVELSUCCESS)
						BattlePass.UserData = nil
						BattlePass:showMain()
						Notifications:getTotalNotifications(true)
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

---Displays BattlePass reward claim popup
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
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.BATTLEPASSCLAIMSUCCESS)
						BattlePass.UserData = nil
						BattlePass:showMain()
						update_tc_balance()
						download_inventory()
						Notifications:getTotalNotifications(true)
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
---@param override? BattlePassUserData Override data to use instead of actual user BP stats
---@return UIElement
function BattlePass:spawnPrizeConfirmationWindow(title, message, onConfirm, override)
	local overlay = TBMenu:spawnWindowOverlay()
	local windowHeight = math.min(300, WIN_H / 2)
	local claimWindowBackground = overlay:addChild({
		shift = { WIN_W / 4, (WIN_H - windowHeight) / 2 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 4
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
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	cancelButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCANCEL)
	cancelButton:addMouseHandlers(nil, function() overlay:kill() end)
	local acceptButton = claimWindowBackground:addChild({
		pos = { -claimWindowBackground.size.w * 0.48, -claimWindowBackground.size.h / 7 - 15 },
		size = { claimWindowBackground.size.w * 0.4, claimWindowBackground.size.h / 7 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	acceptButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONCONTINUE)
	acceptButton:addMouseHandlers(nil, onConfirm)

	if (#claimRewards == 0) then
		---No rewards displayed, remove empty space to make the window look nicer
		---This would typically be the case when upgrading to premium while on level 0
		claimWindowBackground.size.h = claimWindowBackground.size.h - claimWindowRewards.size.h
		claimWindowBackground:moveTo(nil, claimWindowRewards.size.h / 2, true)
	end
	return claimWindowBackground
end

---Displays a BP prize in a provided UIElement viewport
---@param viewElement UIElement
---@param prize BattlePassReward
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
		interactive = not prize.static and true and not prize.claimed,
		clickThrough = true,
		hoverThrough = true,
		hoverColor = prize.hoverColor or (prize.locked and (prize.premium and TB_MENU_DEFAULT_DARKER_BLUE or TB_MENU_DEFAULT_DARKER_ORANGE) or (prize.premium and TB_MENU_DEFAULT_BLUE or TB_MENU_DEFAULT_ORANGE)),
		pressedColor = prize.bgColor or (prize.locked and (prize.premium and TB_MENU_DEFAULT_DARKER_BLUE or TB_MENU_DEFAULT_DARKER_ORANGE) or (prize.premium and TB_MENU_DEFAULT_DARKER_BLUE or TB_MENU_DEFAULT_DARKER_ORANGE))
	}, true)

	if (prize.itemid ~= nil and (prize.item == nil or prize.item.itemid == 0)) then
		prize.item = Store:getItemInfo(prize.itemid)
	end
	if (Store.Discounts.Prime == true) then
		if (prize.bpxp ~= nil) then
			prize.bpxp = math.ceil(prize.bpxp * 1.5)
		end
		if (prize.qi ~= nil) then
			prize.qi = math.ceil(prize.qi * 2)
		end
	end
	local iconPath, prizeAmount, prizeTooltip = nil, nil, nil
	-- Some free reward levels will have multiple rewards, we want TC/ST to be shown
	if (prize.tc ~= nil and prize.tc > 0) then
		iconPath = "../textures/store/toricredit.tga"
		prizeAmount = numberFormat(prize.tc)
		if (not prize.withoutPopup) then
			prizeTooltip = TBMenu:displayPopup(prizeBackground, prizeAmount .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS, prize.static)
		end
	elseif (prize.st ~= nil and prize.st > 0) then
		iconPath = "../textures/store/shiaitoken.tga"
		prizeAmount = numberFormat(prize.st)
		if (not prize.withoutPopup) then
			prizeTooltip = TBMenu:displayPopup(prizeBackground, prizeAmount .. " " .. (prizeAmount == '1' and TB_MENU_LOCALIZED.WORDSHIAITOKEN or TB_MENU_LOCALIZED.WORDSHIAITOKENS), prize.static)
		end
	elseif (prize.bpxp ~= nil and prize.bpxp > 0) then
		iconPath = "../textures/menu/battlepass/experience.tga"
		prizeAmount = numberFormat(prize.bpxp)
		if (not prize.withoutPopup) then
			prizeTooltip = TBMenu:displayPopup(prizeBackground, prizeAmount .. " " .. TB_MENU_LOCALIZED.BATTLEPASSEXPERIENCE, prize.static)
		end
	elseif (prize.item ~= nil and prize.item.itemid > 0) then
		iconPath = prize.item:getIconPath()
		if (not prize.withoutPopup) then
			prizeTooltip = TBMenu:displayPopup(prizeBackground, prize.item.itemname .. (string.len(prize.item.description or "") > 0 and ("\n\n" .. prize.item.description) or ''), prize.static, 500)
		end
	elseif (prize.qi ~= nil and prize.qi > 0) then
		iconPath = "../textures/store/qi.tga"
		prizeAmount = numberFormat(prize.qi)
		if (not prize.withoutPopup) then
			prizeTooltip = TBMenu:displayPopup(prizeBackground, prizeAmount .. " " .. TB_MENU_LOCALIZED.WORDQI, prize.static)
		end
	else
		return
	end
	if (prizeTooltip ~= nil) then
		if (prizeBackground.size.w > prizeTooltip.size.w) then
			prizeTooltip:moveTo((prizeBackground.size.w - prizeTooltip.size.w) / 2, prizeBackground.size.h + 5)
		else
			prizeTooltip:moveTo(-prizeBackground.size.w - (prizeTooltip.size.w - prizeBackground.size.w) / 2, prizeBackground.size.h + 5)
		end
	end

	local shiftSize = math.min(viewElement.size.w / 10, 8)
	local prizeIcon = prizeBackground:addChild({
		shift = { shiftSize, shiftSize },
		bgImage = iconPath
	})
	if (prizeIcon.bgImage == nil or prizeIcon.bgImageDefault == true) then
		Store:addIconToDownloadQueue(prize.item.itemid, iconPath, prizeIcon)
	end

	if (prize.locked or prize.claimed) then
		local colorOverlay = prizeBackground:addChild({
			bgColor = table.clone(prizeBackground.bgColor)
		}, true)
		colorOverlay.bgColor[4] = 0.4

		local iconSize = math.min(viewElement.size.w / 2, 32)
		if (prize.locked) then
			prizeBackground:addChild({
				pos = { -iconSize, 0 },
				size = { iconSize, iconSize },
				bgImage = "../textures/menu/general/buttons/locked.tga"
			})
		else
			prizeBackground:addChild({
				pos = { -iconSize, 0 },
				size = { iconSize, iconSize },
				shapeType = ROUNDED,
				rounded = iconSize / 2,
				bgColor = TB_MENU_DEFAULT_BLUE,
				bgImage = "../textures/menu/general/buttons/checkmark.tga"
			})
		end
	else
		prizeBackground:addMouseHandlers(nil, BattlePass.spawnPrizeClaimWindow)
	end

	if (prizeAmount ~= nil) then
		local textHolderSize = math.min(30, prizeBackgroundOutline.size.h / 2)
		if (textHolderSize < 10) then
			return
		end
		local prizeTextHolder = prizeBackgroundOutline:addChild({
			pos = { 0, -textHolderSize },
			size = { prizeBackgroundOutline.size.w, textHolderSize },
			bgColor = prize.textBackdropColor or TB_MENU_DEFAULT_BG_COLOR_TRANS,
			shapeType = ROUNDED,
			rounded = { 0, prizeBackgroundOutline.rounded }
		})
		local prizeText = prizeTextHolder:addChild({
			shift = { 5, 2 },
			uiColor = prize.textColor,
			uiShadowColor = table.clone(prizeBackground.bgColor),
			shadowOffset = 2
		})
		prizeText.uiShadowColor[4] = 0.67
		prizeText:addAdaptedText(prizeAmount, { shadow = 2 }, true)
	end
end

---Displays BP level prize in a specified UIElement viewport
---@param prizeHolder UIElement
---@param levelData BattlePassLevel
function BattlePass:showLevelPrize(prizeHolder, levelData)
	local prizeLevel = prizeHolder:addChild({
		pos = { 10, 10 },
		size = { prizeHolder.size.w - 20, 30 }
	})
	prizeLevel:addAdaptedText(false, TB_MENU_LOCALIZED.BATTLEPASSLVL .. " " .. levelData.level)
	local prizeBackground = prizeHolder:addChild({
		pos = { 3, 50 },
		size = { prizeHolder.size.w - 6, prizeHolder.size.h - 50 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})

	local freePrizeHolder = prizeBackground:addChild({
		pos = { 0, 0 },
		size = { prizeBackground.size.w, prizeBackground.size.h / BattlePass.MaxLevelPrizes },
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
	})
	if (levelData.st > 0 or levelData.tc > 0 or levelData.itemid > 0) then
		BattlePass:showPrizeItem(freePrizeHolder:addChild({ shift = { 15, 10 } }), {
			tc = levelData.tc,
			st = levelData.st,
			item = levelData.item,
			itemid = levelData.itemid,
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
			item = levelData.item_premium,
			itemid = levelData.itemid_premium,
			locked = not BattlePass.UserData.premium or BattlePass.UserData.level_available < levelData.level,
			claimed = BattlePass.UserData.level_premium >= levelData.level,
			premium = true
		})
	end
	local premiumPrizesHolder = prizeBackground:addChild({
		pos = { 15, freePrizeHolder.size.h },
		size = { prizeBackground.size.w - 30, prizeBackground.size.h - freePrizeHolder.size.h }
	})
	local prizeSize = math.min(premiumPrizesHolder.size.w, premiumPrizesHolder.size.h / #premiumPrizes, prizeBackground.size.h / BattlePass.MaxLevelPrizes - 10 * (BattlePass.MaxLevelPrizes - 1), freePrizeHolder.size.w - 10, freePrizeHolder.size.h - 20)
	local prizeHeight = prizeSize + 10
	for i, v in pairs(premiumPrizes) do
		local premiumPrizeHolder = premiumPrizesHolder:addChild({
			pos = { (premiumPrizesHolder.size.w - prizeSize) / 2, (premiumPrizesHolder.size.h - prizeHeight * #premiumPrizes) / 2 + (i - 1) * prizeHeight },
			size = { prizeSize, prizeHeight }
		})
		BattlePass:showPrizeItem(premiumPrizeHolder, v)
	end
end

---Displays all BP rewards for main Battle Pass view
---@param viewElement UIElement
function BattlePass:showPrizes(viewElement)
	local prizeHolderSize = math.clamp(viewElement.size.w / 12, 110, 160)
	local toReload, leftBar, rightBar, _, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, prizeHolderSize, prizeHolderSize, 20, TB_MENU_DEFAULT_DARKER_COLOR, SCROLL_HORIZONTAL)

	---@type BattlePassLevel
	local closestMilestoneReward
	local listElements = {}
	for _, v in ipairs(BattlePass.LevelData) do
		local prizeHolder = UIElement:new({
			parent = listingHolder,
			pos = { #listElements * prizeHolderSize, 0 },
			size = { prizeHolderSize, listingHolder.size.h },
		})
		table.insert(listElements, prizeHolder)
		BattlePass:showLevelPrize(prizeHolder, v)

		if (not closestMilestoneReward and v.level % 5 == 0 and BattlePass.UserData.level <= v.level) then
			closestMilestoneReward = v
		end
	end

	for _, v in pairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, prizeHolderSize, SCROLL_HORIZONTAL)
	listingHolder.scrollBar = scrollBar
	local totalSize = #listElements * prizeHolderSize
	local shift = { math.max(0, (BattlePass.UserData.level - 1)) / #BattlePass.LevelData * totalSize / (totalSize - listingHolder.size.w) * (scrollBar.parent.size.w - scrollBar.size.w) }
	scrollBar:makeHorizontalScrollBar(listingHolder, listElements, toReload, shift, 0.4)

	local fadeColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR)
	fadeColor[4] = 0
	local leftBarFade = leftBar:addChild({
		pos = { leftBar.size.w, 0 },
		size = { 8, leftBar.size.h - listingScrollBG.size.h },
		bgGradient = { TB_MENU_DEFAULT_DARKEST_COLOR, fadeColor },
		bgGradientMode = BODYPARTS.R_THIGH
	})
	local rightBarFade = rightBar:addChild({
		pos = { -rightBar.size.w - 8, 0 },
		size = { 8, leftBarFade.size.h },
		bgGradient = { fadeColor, TB_MENU_DEFAULT_DARKEST_COLOR },
		bgGradientMode = BODYPARTS.R_THIGH
	})

	-- Display top unclaimed prize (or max level if all levels have already been claimed)
	local levelName = rightBar:addChild({
		pos = { 10, rightBar.size.h / 40 },
		size = { rightBar.size.w - 20, rightBar.size.h / 10 }
	})
	levelName:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSLVL .. " " .. closestMilestoneReward.level, nil, nil, FONTS.BIG, nil, 0.7)

	local availablePrizes = {}
	if (closestMilestoneReward.st > 0) then
		table.insert(availablePrizes, {
			st = closestMilestoneReward.st,
			locked = BattlePass.UserData.level_available < closestMilestoneReward.level,
			claimed = BattlePass.UserData.level >= closestMilestoneReward.level,
			static = true
		})
	end
	if (closestMilestoneReward.tc > 0) then
		table.insert(availablePrizes, {
			tc = closestMilestoneReward.tc,
			locked = BattlePass.UserData.level_available < closestMilestoneReward.level,
			claimed = BattlePass.UserData.level >= closestMilestoneReward.level,
			static = true
		})
	end
	if (closestMilestoneReward.itemid > 0) then
		table.insert(availablePrizes, {
			itemid = closestMilestoneReward.itemid,
			item = closestMilestoneReward.item,
			locked = BattlePass.UserData.level_available < closestMilestoneReward.level,
			claimed = BattlePass.UserData.level >= closestMilestoneReward.level,
			static = true
		})
	end
	if (closestMilestoneReward.st_premium > 0) then
		table.insert(availablePrizes, {
			st = closestMilestoneReward.st_premium,
			locked = not BattlePass.UserData.premium or BattlePass.UserData.level_available < closestMilestoneReward.level,
			claimed = BattlePass.UserData.level_premium >= closestMilestoneReward.level,
			premium = true,
			static = true
		})
	end
	if (closestMilestoneReward.tc_premium > 0) then
		table.insert(availablePrizes, {
			tc = closestMilestoneReward.tc_premium,
			locked = not BattlePass.UserData.premium or BattlePass.UserData.level_available < closestMilestoneReward.level,
			claimed = BattlePass.UserData.level_premium >= closestMilestoneReward.level,
			premium = true,
			static = true
		})
	end
	if (closestMilestoneReward.itemid_premium > 0) then
		table.insert(availablePrizes, {
			itemid = closestMilestoneReward.itemid_premium,
			item = closestMilestoneReward.item_premium,
			locked = not BattlePass.UserData.premium or BattlePass.UserData.level_available < closestMilestoneReward.level,
			claimed = BattlePass.UserData.level_premium >= closestMilestoneReward.level,
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
function BattlePass:showMain()
	TBMenu.CurrentSection:kill(true)
	self.wasOpened = true

	if (table.empty(BattlePass.LevelData)) then
		BattlePass.UserData = nil
	end
	if (not BattlePass.UserData or BattlePass.UserData.qi ~= TB_MENU_PLAYER_INFO.data.qi) then
		local battlePassLoading = TBMenu.CurrentSection:addChild({
			shift = { 5, 0 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(battlePassLoading)
		TBMenu:displayLoadingMark(battlePassLoading, TB_MENU_LOCALIZED.BATTLEPASSLOADING)
		BattlePass:getUserData(battlePassLoading)
		return
	end
	if (not Store.Ready) then
		local storeLoading = TBMenu.CurrentSection:addChild({
			shift = { 5, 0 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(storeLoading)
		TBMenu:displayLoadingMark(storeLoading, TB_MENU_LOCALIZED.STORELOADING)
		storeLoading:addCustomDisplay(function()
				if (Store.Ready) then
					BattlePass:showMain()
				end
			end)
		return
	end
	local battlePassProgressHolder = TBMenu.CurrentSection:addChild({
		pos = { 5, 0 },
		size = { TBMenu.CurrentSection.size.w - 10, 80 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		bgImage = "../textures/menu/battlepass/tcpattern.tga",
		imagePatterned = true,
		imageColor = { 0.824, 0.749, 0.482, 1 }
	})
	BattlePass:showProgress(battlePassProgressHolder)

	local buttonWidth = math.min(TBMenu.CurrentSection.size.w * 0.3, 750)
	local infoButtonHeight = buttonWidth * 0.639 + 10
	if (infoButtonHeight > (TBMenu.CurrentSection.size.h - battlePassProgressHolder.size.h - 30) * 0.65) then
		infoButtonHeight = (TBMenu.CurrentSection.size.h - battlePassProgressHolder.size.h - 30) * 0.65
		buttonWidth = math.round((infoButtonHeight - 10) / 0.639)
	end

	local battlePassPrizesView = TBMenu.CurrentSection:addChild(({
		pos = { 5, battlePassProgressHolder.size.h + 10 },
		size = { TBMenu.CurrentSection.size.w - buttonWidth - 25, TBMenu.CurrentSection.size.h - battlePassProgressHolder.size.h - 10 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	}))
	TBMenu:addBottomBloodSmudge(battlePassPrizesView, 1)
	local battlePassTimeLeft = battlePassPrizesView:addChild({
		pos = { 0, -50 },
		size = { battlePassPrizesView.size.w, 40 }
	})
	battlePassTimeLeft:addCustomDisplay(true, function()
			local bpTimeLeft = BattlePass.TimeLeft + BattlePass.UpdateTimestamp - os.time()
			if (bpTimeLeft > 0) then
				battlePassTimeLeft:uiText(TB_MENU_LOCALIZED.BATTLEPASSTIMELEFT .. " " .. TBMenu:getTime(bpTimeLeft, 3))
			else
				battlePassTimeLeft:addAdaptedText(true, TB_MENU_LOCALIZED.BATTLEPASSTIMEOVER)
			end
		end)
	local battlePassPrizesHolder = battlePassPrizesView:addChild({
		size = { battlePassPrizesView.size.w, battlePassPrizesView.size.h + battlePassTimeLeft.shift.y }
	})
	BattlePass:showPrizes(battlePassPrizesHolder)

	local buttonShiftX = battlePassPrizesHolder.shift.x + battlePassPrizesHolder.size.w + 15
	local buttonShiftY = battlePassProgressHolder.size.h + 10

	local battlePassInfoButton = TBMenu.CurrentSection:addChild({
		pos = { buttonShiftX, buttonShiftY },
		size = { buttonWidth, infoButtonHeight },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = true,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		hoverSound = 31
	})
	TBMenu:showHomeButton(battlePassInfoButton, {
		image = "../textures/menu/battlepass/battlepassinfolarge.tga",
		ratio = 0.639,
		disableUnload = true,
		action = Events.ShowBattlepassInfo
	})
	local questsStartY = battlePassInfoButton.shift.y + battlePassInfoButton.size.h + 10
	local battlePassQuestsButton = TBMenu.CurrentSection:addChild({
		pos = { buttonShiftX, questsStartY },
		size = { buttonWidth, TBMenu.CurrentSection.size.h - questsStartY },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		interactive = true,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		hoverSound = 31
	})
	TBMenu:showHomeButton(battlePassQuestsButton, {
		ratio = 0.5,
		title = TB_MENU_LOCALIZED.BATTLEPASSQUESTS,
		subtitle = TB_MENU_LOCALIZED.BATTLEPASSQUESTSDESC,
		disableUnload = true,
		action = function()
			TB_MENU_QUESTS_ACTIVE_SECTION = 4
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
