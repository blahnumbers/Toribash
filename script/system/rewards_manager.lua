-- daily login manager class
require("system/store_manager")

do
	TC = 0
	ITEM = 1

	Rewards = {}
	Rewards.__index = Rewards
	local cln = {}
	setmetatable(cln, Rewards)

	RewardData = {}
	
	function Rewards:getRewardData()
		local data_types = { "reward_type", "tc", "item" }
		local file = io.open("system/loginrewards.txt")
		if (file == nil) then
			return false
		end
		
		for ln in file:lines() do
			if string.match(ln, "^REWARD") then
				local segments = 5
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local days = tonumber(data_stream[2])
				RewardData[days - 1] = {}
				
				for i, v in ipairs(data_types) do
					if (i < 3) then
						RewardData[days - 1][v] = tonumber(data_stream[i + 2])
					else 
						RewardData[days - 1][v] = data_stream[i + 2]
					end
				end
				if (RewardData[days - 1].item ~= '0') then
					RewardData[days - 1].item = Torishop:getItemInfo(tonumber(RewardData[days - 1].item))
				end
			end
		end
		
		file:close()
		return true
	end
	
	function Rewards:quit()
		if (get_option("newmenu") == 0 or TB_MENU_MAIN_ISOPEN == 0) then
			tbMenuMain:kill()
			TB_MENU_SPECIAL_SCREEN_ISOPEN = 4
			remove_hooks("tbMainMenuVisual")
			return
		end
		tbMenuCurrentSection:kill(true) 
		tbMenuNavigationBar:kill(true)
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 4
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function Rewards:getNavigationButtons()
		local buttonText = (get_option("newmenu") == 0 or TB_MENU_MAIN_ISOPEN == 0) and TB_MENU_LOCALIZED.NAVBUTTONEXIT or TB_MENU_LOCALIZED.NAVBUTTONTOMAIN
		local buttonsData = {
			{ 
				text = buttonText, 
				action = function() Rewards:quit() end
			}
		}
		return buttonsData
	end
	
	function Rewards:showMain(viewElement, rewardData)
		viewElement:kill(true)
		if (rewardData.days > 6) then
			rewardData.days = rewardData.days % 7
		end
		
		local loginView = UIElement:new({	
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local bloodSmudge = TBMenu:addBottomBloodSmudge(loginView, 1)
		local loginViewTitle = UIElement:new({
			parent = loginView,
			pos = { 0, 0 },
			size = { loginView.size.w, loginView.size.h / 8 }
		})
		loginViewTitle:addCustomDisplay(false, function()
			loginViewTitle:uiText(TB_MENU_LOCALIZED.REWARDSDAILYTITLE, nil, nil, FONTS.BIG, CENTERMID, 0.8, nil, nil, nil, nil, 0.5)
		end)
		local dayRewardsView = UIElement:new({
			parent = loginView,
			pos = { 20, loginViewTitle.size.h },
			size = { loginView.size.w - 40, loginView.size.h * 0.62 }
		})
		local dayRewardWidth = dayRewardsView.size.w / 7
		local dayReward = {}
		
		for i = 0, 6 do
			local bgImg = RewardData[i].item ~= '0' and "../textures/store/items/" .. RewardData[i].item.itemid .. "_big.tga" or "../textures/store/toricredit.tga"
			local iconSize = dayRewardWidth - 40 > dayRewardsView.size.h / 2 and dayRewardsView.size.h / 2 - 20 or dayRewardWidth - 60
			
			dayReward[i] = {}
			dayReward[i].main = UIElement:new({
				parent = dayRewardsView,
				pos = { 0 + i * dayRewardWidth, 0 },
				size = { dayRewardWidth - 20, dayRewardsView.size.h },
				bgColor = i == rewardData.days and { 0, 0, 0, 0.5 } or { 0, 0, 0, 0.3 }
			})
			dayReward[i].day = UIElement:new({
				parent = dayReward[i].main,
				pos = { 5, 0 },
				size = { dayReward[i].main.size.w - 10, dayReward[i].main.size.h / 7 }
			})
			dayReward[i].day:addAdaptedText(true, rewardData.days == i and (rewardData.available and "Today" or "Tomorrow") or TB_MENU_LOCALIZED.REWARDSTIMEDAY .. " " .. i + 1, nil, nil, FONTS.BIG, nil, 0.55, nil, 0.2)
			if (iconSize > 32) then
				iconSize = i == rewardData.days and iconSize + 20 or iconSize
				dayReward[i].icon = UIElement:new({
					parent = dayReward[i].main,
					pos = { (dayReward[i].main.size.w - iconSize) / 2, (dayReward[i].main.size.h - iconSize) / 2 - 10 },
					size = { iconSize, iconSize },
					bgImage = bgImg
				})
			end
			dayReward[i].title = UIElement:new({
				parent = dayReward[i].main,
				pos = { dayReward[i].main.size.w / 10, -dayReward[i].main.size.h / 4 },
				size = { dayReward[i].main.size.w * 0.8, dayReward[i].main.size.h / 5 }
			})
			local rewardStr = RewardData[i].item.itemid ~= 0 and RewardData[i].item.itemname or RewardData[i].tc .. " TC"
			local textScaleModifier = 0
			if (rewardData.days == i) then
				dayReward[i].title:addAdaptedText(true, rewardStr, nil, nil, FONTS.BIG)
			else
				dayReward[i].title:addAdaptedText(true, rewardStr)
			end
		end
		local rewardNextTime = UIElement:new( {
			parent = loginView,
			pos = { 0, -loginView.size.h / 7 - loginView.size.h / 10 },
			size = { loginView.size.w, loginView.size.h / 11 }
		})
		rewardNextTime:addCustomDisplay(true, function()
			rewardNextTime:uiText(Rewards:getTime(rewardData.timeLeft - math.ceil(os.clock()), rewardData.available))
		end)
		local rewardClaim = UIElement:new({
			parent = loginView,
			pos = { loginView.size.w / 6, -loginView.size.h / 7 },
			size = { loginView.size.w / 6 * 4, loginView.size.h / 8 },
			interactive = rewardData.available,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 0, 0, 0.2 },
			downSound = 31
		})
		local rewardClaimText = UIElement:new({
			parent = rewardClaim,
			pos = { rewardClaim.size.w / 20, rewardClaim.size.h / 7 },
			size = { rewardClaim.size.w * 0.9, rewardClaim.size.h / 7 * 5 }
		})
		if (rewardData.available) then
			rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIM, nil, nil, FONTS.BIG)
			rewardClaim:addMouseHandlers(function() end, function()
					rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIMINPROGRESS .. "...", nil, nil, FONTS.BIG)
					Request:queue(function() claim_reward() end, "loginreward", function()
							local response = get_network_response()
							response = response:gsub("REWARDS 0; ", "")
							local rewardRes = { response:match(("(%d+)%s?"):rep(3)) }
							if (rewardRes[1] == '1') then
								if (rewardRes[2] == '0') then
									rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSNOAVAILABLE, nil, nil, FONTS.BIG)
								elseif (rewardRes[2] == '1') then
									rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIMTIMEOUT, nil, nil, FONTS.BIG)
								else
									rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIMERROROTHER, nil, nil, FONTS.BIG)
								end
								rewardClaim:deactivate()
							elseif (rewardRes[1] == '0') then
								rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIMSUCCESS, nil, nil, FONTS.BIG)
								rewardClaim:deactivate()
								update_tc_balance()
								TB_MENU_NOTIFICATIONS_COUNT = math.max(TB_MENU_NOTIFICATIONS_COUNT - 1)
								tbMenuNavigationBar:kill(true)
								TBMenu:showNavigationBar(Notifications:getNavigationButtons(false, true), true, true, TB_MENU_NOTIFICATIONS_LASTSCREEN)
								
								-- Let's update balance instantly, no need to wait for update_tc_balance() to finish downloading customs
								if (RewardData[rewardData.days].tc ~= 0) then
									TB_MENU_PLAYER_INFO.data.tc = TB_MENU_PLAYER_INFO.data.tc + RewardData[rewardData.days].tc
									TBMenu:showUserBar()
								elseif (RewardData[rewardData.days].item.itemid == 2528) then
									TB_MENU_PLAYER_INFO.data.st = TB_MENU_PLAYER_INFO.data.st + 1
									TBMenu:showUserBar()
								end
							end
						end, function()
							rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSCLAIMERROROTHER, nil, nil, FONTS.BIG)
							rewardClaim:deactivate()
						end)
				end)
		else
			rewardClaimText:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSNOAVAILABLE, nil, nil, FONTS.BIG)
		end
	end
	
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
end
