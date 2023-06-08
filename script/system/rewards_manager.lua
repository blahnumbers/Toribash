require("system.store_manager")
require("system.quests_manager")
require("system.network_request")
require("system.iofiles")

---@class DayReward
---@field reward_type integer
---@field tc integer
---@field item StoreItem

---@class RewardData
---@field available boolean
---@field days integer
---@field timeLeft integer

if (Rewards == nil) then
	---**Login rewards manager class**
	---
	---**Version 5.60**
	---* Updated visuals
	---@class Rewards
	---@field RewardData DayReward[] List of available rewards
	Rewards = {
		__index = {},
		RewardData = {},
		ver = 5.60
	}
	setmetatable({}, Rewards)
end

---Caches login reward information to `Rewards.RewardData` from the data file
---@return boolean
function Rewards.getRewardData()
	local got_data = false
	local data_types = { "reward_type", "tc", "item" }
	local file = Files.Open("system/loginrewards.txt")
	if (file.data == nil) then
		return false
	end

	local lines = file:readAll()
	file:close()
	for _, ln in pairs(lines) do
		if string.match(ln, "^REWARD") then
			local segments = 5
			local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
			local days = tonumber(data_stream[2])
			Rewards.RewardData[days - 1] = {}

			for i, v in ipairs(data_types) do
				if (i < 3) then
					Rewards.RewardData[days - 1][v] = tonumber(data_stream[i + 2])
				else
					Rewards.RewardData[days - 1][v] = data_stream[i + 2]
				end
			end
			if (Rewards.RewardData[days - 1].item ~= '0') then
				Rewards.RewardData[days - 1].item = Torishop:getItemInfo(tonumber(Rewards.RewardData[days - 1].item) or -1)
			end
			got_data = true
		end
	end

	return got_data
end

---Displays login rewards screen
---@param viewElement UIElement
---@param rewardData RewardData
function Rewards:showMain(viewElement, rewardData)
	if (viewElement == nil or viewElement.destroyed) then
		return
	end

	viewElement:kill(true)
	if (rewardData.days > 6) then
		rewardData.days = rewardData.days % 7
	end

	local loginView = viewElement:addChild({
		shift = { 5, 0 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	TBMenu:addBottomBloodSmudge(loginView, 1)
	local loginViewTitle = loginView:addChild({
		size = { loginView.size.w, math.min(80, loginView.size.h / 8) }
	})
	loginViewTitle:addCustomDisplay(false, function()
		loginViewTitle:uiText(TB_MENU_LOCALIZED.REWARDSDAILYTITLE, nil, nil, FONTS.BIG, CENTERMID, 0.8, nil, nil, nil, nil, 0.5)
	end)
	local buttonHeight = math.min(60, (loginView.size.h * 0.275 + 30) / 2)
	local dayRewardsView = loginView:addChild({
		pos = { 20, loginViewTitle.size.h },
		size = { loginView.size.w - 40, loginView.size.h - loginViewTitle.size.h - buttonHeight * 2 - 30 }
	})

	local dayRewardWidth = math.min(dayRewardsView.size.w / 7, 220)
	local dayRewardHeight = math.min(dayRewardsView.size.h, 450)
	local leftShift = (dayRewardsView.size.w - dayRewardWidth * 7) / 2
	local topShift = (dayRewardsView.size.h - dayRewardHeight) / 2
	for i = 0, 6 do
		local bgImg = Rewards.RewardData[i].item ~= '0' and "../textures/store/items/" .. Rewards.RewardData[i].item.itemid .. "_big.tga" or "../textures/store/toricredit.tga"
		local iconSize = math.min(dayRewardWidth - 60, dayRewardHeight / 2 - 20, 108)

		local rewardHolder
		if (i == rewardData.days) then
			rewardHolder = dayRewardsView:addChild({
				pos = { leftShift + i * dayRewardWidth, topShift },
				size = { dayRewardWidth - 20, dayRewardHeight },
				bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
		else
			rewardHolder = dayRewardsView:addChild({
				pos = { leftShift + (i + 0.05) * dayRewardWidth, topShift + dayRewardHeight * 0.05 },
				size = { (dayRewardWidth * 0.9) - 20, dayRewardHeight * 0.9 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
		end
		local dayText = rewardHolder:addChild({
			pos = { 10, 0 },
			size = { rewardHolder.size.w - 20, rewardHolder.size.h / 7 }
		})
		if (rewardData.days == i) then
			dayText:addAdaptedText(true, rewardData.available and TB_MENU_LOCALIZED.REWARDSTODAY or TB_MENU_LOCALIZED.REWARDSTOMORROW, nil, nil, FONTS.BIG, nil, 0.6)
		else
			dayText:addAdaptedText(true, TB_MENU_LOCALIZED.REWARDSTIMEDAY .. " " .. i + 1, nil, nil, FONTS.BIG, nil, 0.55, nil, 0.2)
		end

		if (iconSize > 32) then
			iconSize = i == rewardData.days and iconSize + 20 or iconSize
			rewardHolder:addChild({
				pos = { (rewardHolder.size.w - iconSize) / 2, (rewardHolder.size.h - iconSize) / 2 - 10 },
				size = { iconSize, iconSize },
				bgImage = bgImg
			})
		end
		local rewardText = rewardHolder:addChild({
			pos = { rewardHolder.size.w / 10, -rewardHolder.size.h / 4 },
			size = { rewardHolder.size.w * 0.8, rewardHolder.size.h / 5 }
		})
		local rewardStr = Rewards.RewardData[i].item.itemid ~= 0 and Rewards.RewardData[i].item.itemname or Rewards.RewardData[i].tc .. " TC"
		if (rewardData.days == i) then
			rewardText:addAdaptedText(true, rewardStr, nil, nil, FONTS.BIG, nil, 0.65)
		else
			rewardText:addAdaptedText(true, rewardStr)
		end
	end
	local rewardNextTime = loginView:addChild({
		pos = { 0, -buttonHeight * 2 - 30 },
		size = { loginView.size.w, buttonHeight }
	})
	rewardNextTime:addCustomDisplay(true, function()
		rewardNextTime:uiText(Rewards:getTime(rewardData.timeLeft - math.ceil(UIElement.clock), rewardData.available))
	end)
	local rewardClaim = loginView:addChild({
		pos = { loginView.size.w * 0.2, -buttonHeight - 30},
		size = { loginView.size.w * 0.6, buttonHeight },
		interactive = rewardData.available,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		shapeType = ROUNDED,
		rounded = 4,
		downSound = 31
	})
	local rewardClaimText = rewardClaim:addChild({
		shift = { rewardClaim.size.w / 20, rewardClaim.size.h / 7 },
	})

	local doClaim
	doClaim = function(attempt)
		Request:queue(function() claim_reward() end, "loginreward", function()
			local response = get_network_response()
			response = response:gsub("REWARDS 0; ", "")
			local rewardRes = { response:match(("(%d+)%s?"):rep(3)) }
			if (rewardRes[1] == '1') then
				if (not rewardClaimText or rewardClaimText.destroyed) then
					return
				end

				if (rewardRes[2] == '0') then
					rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSNOAVAILABLE, nil, nil, FONTS.BIG)
				elseif (rewardRes[2] == '1') then
					if (attempt == 1) then
						local timeleft = PlayerInfo.Get().getLoginRewards().timeLeft
						local clock = os.clock_real()
						refresh_reward()
						add_hook("draw2d", "tbRewardsRewardRefresh", function()
								if (PlayerInfo.Get().getLoginRewards().timeLeft ~= timeleft or os.clock_real() - clock > 5) then
									remove_hooks("tbRewardsRewardRefresh")
									doClaim(2)
								end
							end)
						return
					end
					rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIMTIMEOUT, nil, nil, FONTS.BIG)
				else
					rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIMERROROTHER, nil, nil, FONTS.BIG)
				end
				rewardClaim:deactivate()
			elseif (rewardRes[1] == '0') then
				update_tc_balance()
				TB_MENU_NOTIFICATIONS_COUNT = math.max(TB_MENU_NOTIFICATIONS_COUNT - 1, 0)

				if (rewardClaimText and not rewardClaimText.destroyed) then
					rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIMSUCCESS, nil, nil, FONTS.BIG)
					rewardClaim:deactivate()
					TBMenu.NavigationBar:kill(true)
					TBMenu:showNavigationBar(Notifications:getNavigationButtons(nil, true), true, true, TB_MENU_NOTIFICATIONS_LASTSCREEN)
				end

				-- Let's update balance instantly, no need to wait for update_tc_balance() to finish downloading customs
				if (Rewards.RewardData[rewardData.days].tc ~= 0) then
					TB_MENU_PLAYER_INFO.data.tc = TB_MENU_PLAYER_INFO.data.tc + Rewards.RewardData[rewardData.days].tc
					if (TBMenu.MenuMain and not TBMenu.MenuMain.destroyed) then
						TBMenu:showUserBar()
					end
				elseif (Rewards.RewardData[rewardData.days].item.itemid == 2528) then
					TB_MENU_PLAYER_INFO.data.st = TB_MENU_PLAYER_INFO.data.st + 1
					if (TBMenu.MenuMain and not TBMenu.MenuMain.destroyed) then
						TBMenu:showUserBar()
					end
				end
				Quests:updateLoginQuestStatus(true)
				BattlePass:getUserData()
			end
		end, function()
			if (rewardClaimText and not rewardClaimText.destroyed) then
				rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIMERROROTHER, nil, nil, FONTS.BIG)
				rewardClaim:deactivate()
			end
		end)
	end

	if (rewardData.available) then
		rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIM, nil, nil, FONTS.BIG)
		rewardClaim:addMouseHandlers(function() end, function()
				rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIMINPROGRESS .. "...", nil, nil, FONTS.BIG)
				doClaim(1)
			end)
	else
		rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSNOAVAILABLE, nil, nil, FONTS.BIG)
	end
end

---Returns a string with time left / status information based on provided login info data
---@param timetonext integer
---@param isClaimed boolean
---@return string
function Rewards:getTime(timetonext, isClaimed)
	if (timetonext <= 0 and not isClaimed) then
		return TB_MENU_LOCALIZED.REWARDSAVAILABLERESTART
	elseif (timetonext <= 0 and isClaimed) then
		return TB_MENU_LOCALIZED.REWARDSEXPIRED
	end

	local returnval = TBMenu:getTime(timetonext)

	if (not isClaimed) then
		return TB_MENU_LOCALIZED.REWARDSNEXTREWARD .. " " .. returnval
	end
	return returnval .. " " .. TB_MENU_LOCALIZED.REWARDSTIMELEFT
end
