require("system.playerinfo_manager")

if (Bounty == nil) then
	---**Bounty manager class**
	---
	---**Version 5.60**:
	---* Added EmmyLua annotations
	---* Visual updates to match 5.60 design
	---@class Bounty
	---@field DataList PlayerBounty[]
	Bounty = {
		DataList = {},
		LastUpdate = -1,
		StalePeriod = 300,
		ver = 5.60
	}
	Bounty.__index = Bounty
end

---@class PlayerBounty
---@field id integer
---@field player string Player name
---@field reward integer Toricredits bounty reward
---@field since integer Timestamp when the bounty was added
---@field claimed integer Timestamp when the bounty was claimed
---@field claimedby string Bounty hunter name
---@field decap boolean Whether this bounty requires a decap to be claimed
---@field room string|nil Name of the room that the target is currenly in

---Parses bounty data retrieved from Toribash servers
---@param data string
function Bounty.ParseBountyData(data)
	local onlinePlayers = RoomList.GetPlayers()
	local data_types = { "userid", "player", "tc", "since", "claimed", "claimedby", "decap" }

	-- Don't display multiple bounties on same user; only first one will be claimed when user is defeated
	local useridList = {}
	for ln in data:gmatch("[^\n]*\n?") do
		pcall(function()
			if (not ln:find("^#?USERID")) then
				local data_stream = { ln:match(("([^\t]*)\t"):rep(#data_types)) }
				local online = nil
				for _, v in pairs(onlinePlayers) do
					if (PlayerInfo.Get(v.username).username:lower() == data_stream[2]:lower()) then
						online = v.room
					end
				end

				local userid = tonumber(data_stream[1])
				if (userid ~= nil and data_stream[2] ~= nil and not in_array(userid, useridList)) then
					table.insert(Bounty.DataList, {
						player = data_stream[2],
						reward = tonumber(data_stream[3]) or 0,
						since = tonumber(data_stream[4]) or 0,
						claimed = tonumber(data_stream[5]) or 0,
						claimedby = data_stream[6],
						decap = data_stream[7] == '1',
						room = online
					})
					table.insert(useridList, userid)
				end
			end
		end)
	end
	Bounty.LastUpdate = UIElement.clock
end

---Exits Bounty screen
function Bounty.Quit()
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
	TBMenu:clearNavSection()
	TBMenu:showNavigationBar()
	TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
end

---Returns navigation buttons data for Bounty screen
---@return MenuNavButton[]
function Bounty:getNavigationButtons()
	return {
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
			action = Bounty.Quit
		}
	}
end

-- Halloween 2018 stuff
--[[function Bounty:showCurrentTargetHalloween(objectiveView, target)
	if (not target) then
		local noActiveBountiesMessage = UIElement:new({
			parent = objectiveView,
			pos = { 0, 0 },
			size = { objectiveView.size.w, objectiveView.size.h }
		})
		noActiveBountiesMessage:addAdaptedText(true, "No bounties currently active, check again later!")
		return
	end
	download_head(target.player)

	local bgSize = objectiveView.size.h > 1024 and 1024 or objectiveView.size.h
	bgSize = objectiveView.size.w < objectiveView.size.h * 1.6 and objectiveView.size.w / 1.6 or bgSize

	local wantedBackground = UIElement:new({
		parent = objectiveView,
		pos = { -objectiveView.size.w - bgSize / 8, (objectiveView.size.h - bgSize) / 2 },
		size = { bgSize, bgSize },
		bgImage = "../textures/menu/general/bounty_wanted.tga"
	})
	local objectiveViewport = UIElement:new({
		parent = objectiveView,
		pos = { bgSize / 10, (objectiveView.size.h - bgSize / 2) / 2 },
		size = { bgSize / 2, bgSize / 2 },
		viewport = true
	})
	local objectiveHead = UIElement:new({
		parent = objectiveViewport,
		pos = { 0, 0, 10 },
		rot = { 0, 0, -10 },
		radius = 0.9,
		bgColor = { 1, 1, 1, 1 },
		bgImage = { "../../custom/" .. target.player .. "/head.tga", "../../custom/tori/head.tga" }
	})
	objectiveHead:addCustomDisplay(false, function()
			if (#get_downloads() == 0) then
				objectiveHead:updateImage("../../custom/" .. target.player .. "/head.tga", "../../custom/tori/head.tga")
				objectiveHead:addCustomDisplay(false, function() end)
			end
		end)
	local objectiveTitle = UIElement:new({
		parent = objectiveView,
		pos = { bgSize * 0.8, 0 },
		size = { objectiveView.size.w - bgSize * 0.9, objectiveView.size.h / 7 }
	})
	objectiveTitle:addAdaptedText(true, "Current target", nil, nil, FONTS.BIG, LEFTBOT, 0.65)
	local playerName = UIElement:new({
		parent = objectiveView,
		pos = { objectiveTitle.shift.x, objectiveTitle.shift.y + objectiveTitle.size.h * 7 / 6 },
		size = { objectiveTitle.size.w, objectiveTitle.size.h }
	})
	playerName:addAdaptedText(true, "Player: " .. target.player, nil, nil, nil, LEFTBOT)
	local objectiveSpecifics = UIElement:new({
		parent = objectiveView,
		pos = { objectiveTitle.shift.x, playerName.shift.y + playerName.size.h * 7 / 6 },
		size = { objectiveTitle.size.w, objectiveTitle.size.h }
	})
	objectiveSpecifics:addAdaptedText(true, "Objective: " .. (target.decap == 0 and "defeat in fight" or "Decapitate and win"), nil, nil, nil, LEFTMID)
	local bountyReward = UIElement:new({
		parent = objectiveView,
		pos = { objectiveTitle.shift.x, objectiveSpecifics.shift.y + objectiveSpecifics.size.h * 7 / 6 },
		size = { objectiveTitle.size.w, objectiveTitle.size.h }
	})
	bountyReward:addAdaptedText(true, "Reward: " .. target.reward .. " TC", nil, nil, nil, LEFT)
	local bountyRoom = UIElement:new({
		parent = objectiveView,
		pos = { objectiveTitle.shift.x, bountyReward.shift.y + bountyReward.size.h * 7 / 6 },
		size = { objectiveTitle.size.w, objectiveTitle.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = ROUNDED,
		rounded = 20
	})
	if (target.room) then
		local sign = UIElement:new({
			parent = bountyRoom,
			pos = { 10, bountyRoom.size.h / 2 - 10 },
			size = { 20, 20 },
			bgColor = UICOLORGREEN,
			shapeType = ROUNDED,
			rounded = 20
		})
		bountyRoom:addAdaptedText(false, "Online in " .. target.room, 40, nil, nil, LEFTMID)
		local joinButton = UIElement:new({
			parent = bountyRoom,
			pos = { -bountyRoom.size.w / 3, 10 },
			size = { bountyRoom.size.w / 3 - 10, bountyRoom.size.h - 20 },
			shapeType = ROUNDED,
			rounded = 20,
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		joinButton:addAdaptedText(false, "Join room", nil, nil, nil, nil, 0.8)
		joinButton:addMouseHandlers(nil, function()
				UIElement:runCmd("jo " .. target.room)
				close_menu()
			end)
	else
		local sign = UIElement:new({
			parent = bountyRoom,
			pos = { 10, bountyRoom.size.h / 2 - 10 },
			size = { 20, 20 },
			bgColor = UICOLORRED,
			shapeType = ROUNDED,
			rounded = 20
		})
		bountyRoom:addAdaptedText(false, "Offline", 40, nil, nil, LEFTMID)
	end
	local aboutEvent = UIElement:new({
		parent = objectiveView,
		pos = { objectiveTitle.shift.x, bountyRoom.shift.y + bountyRoom.size.h * 7 / 6 },
		size = { objectiveTitle.size.w, objectiveTitle.size.h },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		shapeType = ROUNDED,
		rounded = 20
	})
	aboutEvent:addAdaptedText(false, "About Toribash's Most Wanted")
	aboutEvent:addMouseHandlers(nil, function()
			Bounty:showAboutEvent(objectiveHead)
		end)
end

function Bounty:getHalloweenEventInfo()
	local function getRandom(list)
		local seed = math.random(1, #list)
		return list[seed]
	end

	local season = {
		{
			titleimg = "../textures/menu/promo/halloween/description.tga",
			desc = "Halloween is upon us, and trouble is brewing on the streets. The Police has compiled a list of bloodthirsty maniacs and merciless criminals. Bounties have been places on their heads. It's time to hunt!\nEvery hour, there will be a new bounty placed on a randomly selected player and it will be up to you to find them and defeat them. In addition to that, there will be special bounties with higher rewards, which will be placed on carefully selected people within the community. You will be rewarded if you can claim the bounty that has been put on someone's head.",
		},
		{
			titleimg = "../textures/menu/promo/halloween/rules.tga",
			desc = "- Rigging matches to receive bounty rewards is prohibited.\n- Do not request for prizes won on one account to be sent to another account. You will receive all the items you won on the account you participated on."
		},
		{
			titleimg = "../textures/menu/promo/halloween/prizes.tga",
			prizes = {
				{
					title = "Best bounty hunter:",
					prizes = {
						items = { { itemid = getRandom({ 2031, 1997, 2030, 2029, 2028, 2188, 2281, 2674, 2741, 2743, 2742, 2784, 2783, 2785 }), name = "Random Halloween 3D Item" } },
						tc = 100000,
						st = 8
					}
				},
				{
					title = "Claim at least 2 bounties:",
					prizes = {
						items = { { itemid = getRandom({ 2031, 1997, 2030, 2029, 2028, 2188, 2281, 2674, 2741, 2743, 2742, 2784, 2783, 2785 }), name = "Random Halloween 3D Item" } },
						st = 2
					}
				},
			}
		}
	}
	return season
end

function Bounty:showHalloweenAboutEvent(headObject, bountyList)
	headObject:hide()
	bountiesScrollBar:deactivate()

	local eventOverlay = TBMenu:spawnWindowOverlay()
	local eventViewHeight = eventOverlay.size.h / 2 > 532 and 532 or eventOverlay.size.h / 5 * 3
	if (eventViewHeight > eventOverlay.size.w / 8 * 3) then
		eventViewHeight = eventOverlay.size.w / 8 * 2
	end
	local eventViewBackground = UIElement:new({
		parent = eventOverlay,
		pos = { eventOverlay.size.w / 8, eventOverlay.size.h / 2 - eventViewHeight / 2 },
		size = { eventOverlay.size.w / 8 * 6, eventViewHeight },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	local eventViewImage = UIElement:new({
		parent = eventViewBackground,
		pos = { 10, 10 },
		size = { eventViewHeight - 20, eventViewHeight - 20 },
		bgImage = "../textures/menu/promo/halloweenblock.tga"
	})
	local eventView = UIElement:new({
		parent = eventViewBackground,
		pos = { eventViewHeight, 0 },
		size = { eventViewBackground.size.w - eventViewHeight, eventViewBackground.size.h }
	})

	local eventInfo = Bounty:getEventInfo()

	local elementHeight = 33.8
	local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(eventView, 40, 45, 20)

	local eventTitle = UIElement:new({
		parent = topBar,
		pos = { 10, 0 },
		size = { topBar.size.w - 20, topBar.size.h }
	})
	eventTitle:addAdaptedText(true, "Toribash's Most Wanted", nil, nil, FONTS.BIG)

	local backButton = UIElement:new({
		parent = botBar,
		pos = { -botBar.size.w / 3, 5 },
		size = { botBar.size.w / 3 - 20, botBar.size.h - 10 },
		interactive = true,
		bgColor = { 0, 0, 0, 0.3 },
		hoverColor = { 0, 0, 0, 0.5 },
		pressedColor = { 1, 1, 1, 0.2 }
	})
	backButton:addAdaptedText(false, TB_MENU_LOCALIZED.NAVBUTTONBACK)
	backButton:addMouseHandlers(nil, function()
			eventOverlay:kill()
			headObject:show()
			bountiesScrollBar:activate()
		end)

	local listElements = {}
	local count = 0
	for i, info in pairs(eventInfo) do
		count = count + 1
		if (info.titleimg) then
			local titleImageSize = listingHolder.size.w >= elementHeight * 8 and elementHeight * 8 or listingHolder.size.w
			local infoTitle = UIElement:new({
				parent = listingHolder,
				pos = { (listingHolder.size.w - titleImageSize) / 2, #listElements * elementHeight },
				size = { titleImageSize, titleImageSize / 8 },
				bgImage = info.titleimg
			})
			table.insert(listElements, infoTitle)
		end
		if (info.desc) then
			local textString = textAdapt(info.desc, 4, 0.7, listingHolder.size.w - 30)
			local rows = math.ceil(#textString / 2)
			for i = 1, rows do
				local infoRow = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				local string = textString[i * 2] and textString[i * 2 - 1] .. textString[i * 2] or textString[i * 2 - 1]
				infoRow:addCustomDisplay(true, function()
						infoRow:uiText(string, nil, nil, 4, LEFT, 0.7)
					end)
				table.insert(listElements, infoRow)
			end
		end
		if (info.prizes) then
			for k, prize in pairs(info.prizes) do
				local prizeTitleHolder = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				local prizeListSign = UIElement:new({
					parent = prizeTitleHolder,
					pos = { elementHeight / 3, elementHeight / 3 },
					size = { elementHeight / 3, elementHeight / 3 },
					shapeType = ROUNDED,
					rounded = elementHeight / 6,
					bgColor = UICOLORBLACK
				})
				local prizeTitle = UIElement:new({
					parent = prizeTitleHolder,
					pos = { elementHeight, 0 },
					size = { prizeTitleHolder.size.w - elementHeight, elementHeight }
				})
				prizeTitle:addAdaptedText(true, prize.title, nil, nil, nil, LEFTMID)
				table.insert(listElements, prizeTitleHolder)
				if (prize.prizes.items) then
					local count = 0
					local itemsRow = UIElement:new({
						parent = listingHolder,
						pos = { 40, #listElements * elementHeight },
						size = { listingHolder.size.w - 50, elementHeight }
					})
					table.insert(listElements, itemsRow)
					local currentRow = itemsRow
					for j, item in pairs(prize.prizes.items) do
						count = count + 1
						if (count * (elementHeight + 10) > listingHolder.size.w - 20) then
							local itemsRowNew = UIElement:new({
								parent = listingHolder,
								pos = { 40, #listingHolder * elementHeight },
								size = { listingHolder.size.w - 50, elementHeight }
							})
							table.insert(listElements, itemsRowNew)
							count = 1
							currentRow = itemsRowNew
						end
						local itemDisplay = UIElement:new({
							parent = currentRow,
							pos = { (count - 1) * (elementHeight + 10), 0 },
							size = { elementHeight, elementHeight },
							interactive = true,
							bgImage = item.customicon and "../textures/store/" .. item.customicon ..".tga" or "../textures/store/items/" .. item.itemid .. ".tga"
						})
						local itemInfo = UIElement:new({
							parent = itemDisplay,
							pos = { 5, 5 },
							size = { 250, 84 },
							bgColor = { 1, 1, 1, 0.85 },
							shapeType = ROUNDED,
							rounded = 5
						})
						local itemTexture = UIElement:new({
							parent = itemInfo,
							pos = { 10, 10 },
							size = { 64, 64 },
							bgImage = item.customicon and "../textures/store/" .. item.customicon ..".tga" or "../textures/store/items/" .. item.itemid .. ".tga"
						})
						local itemDescription = UIElement:new({
							parent = itemInfo,
							pos = { 84, 10 },
							size = { itemInfo.size.w - 94, itemInfo.size.h - 20 }
						})
						itemDescription:addAdaptedText(false, item.name, nil, nil, 4, nil, 0.7, nil, nil, nil, UICOLORBLACK)
						itemDisplay:addCustomDisplay(false, function()
								if (itemDisplay.hoverState ~= BTN_NONE) then
									itemInfo:show()
								else
									itemInfo:hide()
								end
							end)
					end
				end
				if (prize.prizes.tc) then
					local tcPrizeHolder = UIElement:new({
						parent = listingHolder,
						pos = { 40, #listElements * elementHeight },
						size = { listingHolder.size.w - 50, elementHeight }
					})
					table.insert(listElements, tcPrizeHolder)
					local tcSign = UIElement:new({
						parent = tcPrizeHolder,
						pos = { 0, 5 },
						size = { elementHeight - 10, elementHeight - 10 },
						bgImage = "../textures/store/toricredit_tiny.tga"
					})
					local tcPrize = UIElement:new({
						parent = tcPrizeHolder,
						pos = { elementHeight, 0 },
						size = { tcPrizeHolder.size.w - elementHeight, elementHeight }
					})
					tcPrize:addAdaptedText(true, prize.prizes.tc .. " Toricredits", nil, nil, nil, LEFTMID, 0.8)
				end
				if (prize.prizes.st) then
					local stPrizeHolder = UIElement:new({
						parent = listingHolder,
						pos = { 40, #listElements * elementHeight },
						size = { listingHolder.size.w - 50, elementHeight }
					})
					table.insert(listElements, stPrizeHolder)
					local stSign = UIElement:new({
						parent = stPrizeHolder,
						pos = { 0, 5 },
						size = { elementHeight - 10, elementHeight - 10 },
						bgImage = "../textures/store/shiaitoken_tiny.tga"
					})
					local stPrize = UIElement:new({
						parent = stPrizeHolder,
						pos = { elementHeight, 0 },
						size = { stPrizeHolder.size.w - elementHeight, elementHeight }
					})
					stPrize:addAdaptedText(true, prize.prizes.st .. " Shiai Tokens", nil, nil, nil, LEFTMID, 0.8)
				end
				if (prize.prizes.misc) then
					local miscPrize = UIElement:new({
						parent = listingHolder,
						pos = { 40, #listElements * elementHeight },
						size = { listingHolder.size.w - 50, elementHeight }
					})
					table.insert(listElements, miscPrize)
					miscPrize:addAdaptedText(true, "+ " .. prize.prizes.misc, nil, nil, nil, LEFTMID, 0.9)
				end
			end
		end
		if (count < #eventInfo) then
			local separator = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			local separatorLine = UIElement:new({
				parent = separator,
				pos = { 10, separator.size.h / 2 - 0.5 },
				size = { separator.size.w - 20, 1 },
				bgColor = { 1, 1, 1, 0.2 }
			})
			table.insert(listElements, separator)
		end
	end

	for i,v in pairs(listElements) do
		v:hide()
	end

	local eventInfoScrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	eventInfoScrollBar:makeScrollBar(listingHolder, listElements, toReload)
end]]

---@class PlayerBountyInfo
---@field claimed integer Number of bounties claimed by the user
---@field userClaimed integer Number of bounties set on user that have been claimed
---@field userTotal integer Total number of bounties set on user

---Parses user bounty stats retrieved from Toribash servers
---@param data string
---@return PlayerBountyInfo
function Bounty.ParseUserStats(data)
	---@type PlayerBountyInfo
	local userStats = {}
	for ln in data:gmatch("[^\n]*\n?") do
		ln = ln:gsub("\n$", '')
		local val = ln:gsub("^%w+ 0;", "")
		if (ln:find("^CLAIMED 0;")) then
			userStats.claimed = tonumber(val) or 0
		elseif (ln:find("^USERCLAIMED 0;")) then
			userStats.userClaimed = tonumber(val) or 0
		elseif (ln:find("^USERTOTAL 0;")) then
			userStats.userTotal = tonumber(val) or 0
		end
	end
	return userStats
end

---Displays Bounty screen main view
---@param viewElement UIElement
---@param userStats PlayerBountyInfo
function Bounty:showMainView(viewElement, userStats)
	viewElement:kill(true)
	usage_event("bounties")

	local headerTitle = viewElement:addChild({
		pos = { 20, 10 },
		size = { viewElement.size.w - 40, 40 }
	})
	headerTitle:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYYOURSTATISTICS, nil, nil, FONTS.BIG)

	if (not userStats.claimed) then
		viewElement:addAdaptedText(false, TB_MENU_LOCALIZED.ERRORTRYAGAIN)
		return
	end

	local claimedBounties = viewElement:addChild({
		pos = { 20, headerTitle.size.h + headerTitle.shift.y * 2 },
		size = { (viewElement.size.w - 40) / 2 - 10, viewElement.size.h - headerTitle.size.h - headerTitle.shift.y * 2 - 15 }
	})
	local iconSize = claimedBounties.size.w > claimedBounties.size.h * 0.8 and claimedBounties.size.h * 0.8 or claimedBounties.size.w
	local claimedBountiesIcon = claimedBounties:addChild({
		pos = { (claimedBounties.size.w - iconSize) / 2, 0 },
		size = { iconSize, iconSize },
		bgImage = "../textures/menu/general/quests/bountiesuser.tga"
	})
	local claimedBountiesHolder = claimedBounties:addChild({
		pos = { 0, claimedBountiesIcon.size.h * 0.75 },
		size = { claimedBounties.size.w, claimedBounties.size.h - claimedBountiesIcon.size.h * 0.75 },
		bgColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR),
		shapeType = ROUNDED,
		rounded = 10
	})
	claimedBountiesHolder.bgColor[4] = 0.75
	local claimedBountiesTitle = claimedBountiesHolder:addChild({
		size = { claimedBountiesHolder.size.w, claimedBountiesHolder.size.h / 5 * 2 }
	})
	claimedBountiesTitle:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYCLAIMEDBOUNTIES)
	local claimedBountiesStat = claimedBountiesHolder:addChild({
		pos = { 0, claimedBountiesTitle.size.h },
		size = { claimedBountiesHolder.size.w, claimedBountiesHolder.size.h - claimedBountiesTitle.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS
	}, true)
	claimedBountiesStat:setRounded({ 0, claimedBountiesStat.rounded })
	claimedBountiesStat:addAdaptedText(false, tostring(userStats.claimed), nil, nil, FONTS.BIG, nil, 1, nil, 0.5)

	local userBounties = viewElement:addChild({
		pos = { claimedBounties.shift.x + claimedBounties.size.w + 20, claimedBounties.shift.y },
		size = { claimedBounties.size.w, claimedBounties.size.h }
	})
	local userBountiesIcon = userBounties:addChild({
		pos = { (userBounties.size.w - iconSize) / 2, 0 },
		size = { iconSize, iconSize },
		bgImage = "../textures/menu/general/quests/bountiesstats.tga"
	})
	local userBountiesHolder = userBounties:addChild({
		pos = { 0, claimedBountiesHolder.shift.y },
		size = { userBounties.size.w, claimedBountiesHolder.size.h },
		bgColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR),
		shapeType = claimedBountiesHolder.shapeType,
		rounded = claimedBountiesHolder.rounded
	})
	userBountiesHolder.bgColor[4] = 0.75
	local userBountiesTitle = userBountiesHolder:addChild({
		size = { userBountiesHolder.size.w, userBountiesHolder.size.h / 5 * 2 }
	})
	userBountiesTitle:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYUSERBOUNTIES)
	local userBountiesStat = userBountiesHolder:addChild({
		pos = { 0, userBountiesTitle.size.h },
		size = { userBountiesHolder.size.w, userBountiesHolder.size.h - userBountiesTitle.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR_TRANS
	})
	claimedBountiesStat:setRounded({ 0, claimedBountiesStat.rounded })
	userBountiesStat:addAdaptedText(false, TB_MENU_LOCALIZED.WORDTOTAL .. ": " .. userStats.userTotal .. "\n" .. TB_MENU_LOCALIZED.WORDCLAIMED .. ": " .. userStats.userClaimed, nil, nil, FONTS.BIG, nil, 0.5, nil, 0.5)
end

---Displays bounties list
---@param viewElement UIElement
function Bounty:showBountyList(viewElement)
	local elementHeight = 35
	local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 50, elementHeight, 20, TB_MENU_DEFAULT_BG_COLOR)
	TBMenu:addBottomBloodSmudge(botBar, 2)

	local bountyListTitle = topBar:addChild({
		shift = { 10, 5 },
	})
	bountyListTitle:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYLATEST, nil, nil, FONTS.BIG, nil, 0.65)

	local listElements = {}
	local bountyData = table.qsort(Bounty.DataList, { 'id', 'room', 'reward', 'claimedby' }, { SORT_ASCENDING, SORT_DESCENDING, SORT_DESCENDING, SORT_ASCENDING })

	for _, v in pairs(bountyData) do
		local holderTop = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, holderTop)
		local bgTop = holderTop:addChild({
			pos = { 10, 3 },
			size = { holderTop.size.w - 10, holderTop.size.h - 3 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = { 4, 0 }
		})
		local bountyPlayer = bgTop:addChild({
			pos = { 10, 3 },
			size = { bgTop.size.w / 3 * 2 - 20, bgTop.size.h - 6 }
		})
		bountyPlayer:addAdaptedText(true, (v.decap and (TB_MENU_LOCALIZED.WORDDECAPV .. " ") or (TB_MENU_LOCALIZED.WORDBEAT .. " ")) .. v.player, nil, nil, nil, LEFTMID)
		local bountyPrice = bgTop:addChild({
			pos = { -bgTop.size.w / 3 + 10, 3 },
			size = { bgTop.size.w / 3 - 20, bgTop.size.h - 6 }
		})
		bountyPrice:addAdaptedText(true, v.reward .. " TC", nil, nil, FONTS.MEDIUM, RIGHTMID)
		local strlen = get_string_length(bountyPrice.dispstr[1], bountyPrice.textFont) * bountyPrice.textScale
		local tcIcon = bountyPrice:addChild({
			pos = { -strlen - 28, 2 },
			size = { 23, 23 },
			bgImage = "../textures/store/toricredit_tiny.tga"
		})

		local holderBottom = listingHolder:addChild({
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight }
		})
		table.insert(listElements, holderBottom)
		local bgBottom = holderBottom:addChild({
			pos = { 10, 0 },
			size = { holderBottom.size.w - 10, holderBottom.size.h - 3 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = bgTop.shapeType,
			rounded = { 0, bgTop.roundedInternal[1] }
		})

		local bountyInfo = bgBottom:addChild({ shift = { 10, 3 } })
		if (v.claimedby == "") then
			local onlineStatusIcon = bountyInfo:addChild({
				pos = { 0, 4 },
				size = { bountyInfo.size.h - 8, bountyInfo.size.h - 8 },
				shapeType = ROUNDED,
				rounded = bountyInfo.size.h,
				bgColor = not v.room and UICOLORRED or UICOLORGREEN
			})
			local onlineStatus = bountyInfo:addChild({
				pos = { onlineStatusIcon.shift.x + onlineStatusIcon.size.w + 5, 3 },
				size = { bountyInfo.size.w - onlineStatusIcon.shift.x - onlineStatusIcon.size.w - 5, bountyInfo.size.h - 8 }
			})
			onlineStatus:addAdaptedText(true, (not v.room and TB_MENU_LOCALIZED.BOUNTYOFFLINE or (TB_MENU_LOCALIZED.BOUNTYONLINEIN .. " " .. v.room)), nil, nil, 4, LEFTMID)

			if (v.room) then
				bgBottom.size.h = holderBottom.size.h
				bgBottom.shapeType = SQUARE
				local holderBottomJoin = listingHolder:addChild({
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, holderBottomJoin)
				local bgBottomJoin = holderBottomJoin:addChild({
					pos = { 10, 0 },
					size = { holderBottomJoin.size.w - 10, holderBottomJoin.size.h - 3 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					shapeType = bgTop.shapeType,
					rounded = bgBottom.roundedInternal
				})
				local joinButton = bgBottomJoin:addChild({
					pos = { 5, 0 },
					size = { bgBottomJoin.size.w - 10, bgBottomJoin.size.h - 5 },
					interactive = true,
					hoverThrough = true,
					clickThrough = true,
					bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					hoverColor = TB_MENU_DEFAULT_BG_COLOR,
					pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
				}, true)
				if (bgBottomJoin.roundedInternal) then
					joinButton:setRounded(math.max(unpack(bgBottomJoin.roundedInternal)))
				end
				joinButton:addAdaptedText(TB_MENU_LOCALIZED.FRIENDSLISTJOINROOM, nil, nil, nil, nil, 0.8)
				joinButton:addMouseUpHandler(function()
						runCmd("jo " .. v.room)
						close_menu()
				end)
			end
		else
			bountyInfo:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYCLAIMEDBY .. " " .. v.claimedby .. " " .. TB_MENU_LOCALIZED.BOUNTYCLAIMEDBYIN .. " " .. TBMenu:getTime(v.claimed, 1), nil, nil, 4, LEFTMID, 0.7)
		end
	end

	for _, v in pairs(listElements) do
		v:hide()
	end
	local bountiesScrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	bountiesScrollBar:makeScrollBar(listingHolder, listElements, toReload)
end

---Displays new bounty creation UI
---@param viewElement UIElement
function Bounty:displayBountyAdd(viewElement)
	local displayHolder = viewElement:addChild({
		pos = { 20, viewElement.size.h * 0.05 },
		size = { viewElement.size.w - 40, viewElement.size.h * 0.85 },
		shapeType = ROUNDED,
		rounded = 4
	})
	local bountyAddTitle = displayHolder:addChild({
		size = { displayHolder.size.w, displayHolder.size.h / 4 }
	})
	bountyAddTitle:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYADDBOUNTYTITLE, nil, nil, nil, LEFTMID)

	local bountyAddData = { name = { "" }, text = { "" }, claimtext = { "" }, amount = { "" } }
	---@type TextFieldInputSettings
	local textFieldSettings = { fontId = 4, textScale = 0.75, darkerMode = true }
	local bountyAddNameTextfield = TBMenu:spawnTextField2(displayHolder, {
		x = 0, y = bountyAddTitle.size.h,
		w = displayHolder.size.w / 2 - 5, h = (displayHolder.size.h - bountyAddTitle.size.h) / 3 - 5
	}, bountyAddData.name, TB_MENU_LOCALIZED.BOUNTYADDUSERNAME, textFieldSettings)
	local bountyAddAmountTextfield = TBMenu:spawnTextField2(displayHolder, {
		x = displayHolder.size.w / 2 + 5, y = bountyAddTitle.size.h,
		w = displayHolder.size.w / 2 - 5, h = (displayHolder.size.h - bountyAddTitle.size.h) / 3 - 5
	}, bountyAddData.amount, TB_MENU_LOCALIZED.BOUNTYADDAMOUNT, textFieldSettings)
	local bountyAddTextTextfield = TBMenu:spawnTextField2(displayHolder, {
		x = 0, y = bountyAddNameTextfield.size.h + bountyAddTitle.size.h + 15,
		w = displayHolder.size.w / 3 * 2 - 5, h = (displayHolder.size.h - bountyAddTitle.size.h) / 3 - 5
	}, bountyAddData.text, TB_MENU_LOCALIZED.BOUNTYADDTEXT, textFieldSettings)
	bountyAddTextTextfield:addKeyboardHandlers(function()
			local replacements
			bountyAddTextTextfield.textfieldstr[1], replacements =  bountyAddTextTextfield.textfieldstr[1]:gsub(";", "")
			bountyAddTextTextfield.textfieldindex = bountyAddTextTextfield.textfieldindex - replacements
			if (bountyAddTextTextfield.textfieldstr[1]:len() > 32) then
				bountyAddTextTextfield.textfieldstr[1] = bountyAddTextTextfield.textfieldstr[1]:sub(0, 32)
				bountyAddTextTextfield.textfieldindex = bountyAddTextTextfield.textfieldindex - 1
			end
		end)
	local bountyAddClaimTextTextfield = TBMenu:spawnTextField2(displayHolder, {
		x = 0, y = bountyAddNameTextfield.size.h + bountyAddTitle.size.h * 2 + 20,
		w = displayHolder.size.w / 3 * 2 - 5, h = (displayHolder.size.h - bountyAddTitle.size.h) / 3 - 5
	}, bountyAddData.claimtext, TB_MENU_LOCALIZED.BOUNTYADDCLAIMTEXT, textFieldSettings)
	bountyAddClaimTextTextfield:addKeyboardHandlers(function()
			local replacements
			bountyAddClaimTextTextfield.textfieldstr[1], replacements =  bountyAddClaimTextTextfield.textfieldstr[1]:gsub(";", "")
			bountyAddClaimTextTextfield.textfieldindex = bountyAddClaimTextTextfield.textfieldindex - replacements
			if (bountyAddClaimTextTextfield.textfieldstr[1]:len() > 32) then
				bountyAddClaimTextTextfield.textfieldstr[1] = bountyAddClaimTextTextfield.textfieldstr[1]:sub(0, 32)
				bountyAddClaimTextTextfield.textfieldindex = bountyAddClaimTextTextfield.textfieldindex - 1
			end
		end)

	local bountyAddButton = displayHolder:addChild({
		pos = { bountyAddTextTextfield.size.w + 20, bountyAddNameTextfield.size.h + bountyAddTitle.size.h + 15 },
		size = { displayHolder.size.w - bountyAddTextTextfield.size.w - 20, (displayHolder.size.h - bountyAddTitle.size.h) / 3 * 2 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		hoverColor = TB_MENU_DEFAULT_BG_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	bountyAddButton:addAdaptedText(TB_MENU_LOCALIZED.BOUNTYADDBOUNTY)
	bountyAddButton:addMouseUpHandler(function()
			if (bountyAddData.name[1] == "") then
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.BOUNTYERRORNOUSER)
				return
			end
			if (tonumber(bountyAddData.amount[1]) == nil or tonumber(bountyAddData.amount[1]) < 100) then
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.BOUNTYERRORAMOUNT)
				return
			end

			local overlay = TBMenu:spawnWindowOverlay()
			local loadingMark = overlay:addChild({
				pos = { overlay.size.w / 2 - 200, overlay.size.h / 2 - 75 },
				size = { 400, 150 },
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				shapeType = ROUNDED,
				rounded = 4
			})
			TBMenu:displayLoadingMarkSmall(loadingMark, TB_MENU_LOCALIZED.REQUESTFINISHINGACTIVE)
			Request:queue(function()
					local bountyPrice = bountyAddData.amount[1] + 0
					if (string.len(bountyAddData.claimtext[1]) > 0) then
						bountyPrice = bountyPrice + 2000
					end
					show_dialog_box(BOUNTY_ADD_ACTION,
						TB_MENU_LOCALIZED.BOUNTYCONFIRM1 .. " " .. bountyAddData.amount[1] .. " " .. TB_MENU_LOCALIZED.WORDTC .. " " .. TB_MENU_LOCALIZED.BOUNTYCONFIRM2 .. " " .. bountyAddData.name[1] .. "?" .. (string.len(bountyAddData.claimtext[1]) > 0 and ("\n\n^33" .. TB_MENU_LOCALIZED.MARKETYOUWILLBECHARGED .. " " .. bountyPrice .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. ".") or ''),
						bountyAddData.name[1] .. ";" .. bountyAddData.amount[1] .. ";" .. bountyAddData.text[1] .. ";" .. bountyAddData.claimtext[1],
						true)
					loadingMark:kill(true)
					TBMenu:displayLoadingMarkSmall(loadingMark, TB_MENU_LOCALIZED.NETWORKLOADING)

					overlay:addMouseMoveHandler(function(x)
							if (x < WIN_W / 2) then
								overlay:kill()
								Request:cancelCurrentRequest()
							else
								overlay:addMouseHandlers(nil, nil, function() end)
							end
						end)
				end, "tbMenuBountyAddRequest", function()
					overlay:kill(true)
					local reload = false
					local response = get_network_response()
					local result = response:find("GATEWAY 0; 0")
					local error = result and false or response:gsub("GATEWAY 0; 1 ", "")

					local postScreen = overlay:addChild({
						pos = { overlay.size.w / 4, overlay.size.h / 2 - 70 },
						size = { overlay.size.w / 2, 140 },
						bgColor = TB_MENU_DEFAULT_BG_COLOR,
						shapeType = ROUNDED,
						rounded = 4
					})
					local postScreenText = postScreen:addChild({
						pos = { 20, 10 },
						size = { postScreen.size.w - 40, postScreen.size.h / 2 }
					})
					if (result) then
						postScreenText:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYSUCCESS1 .. " " .. bountyAddData.name[1] .. " " .. TB_MENU_LOCALIZED.BOUNTYSUCCESS2 .. " " .. bountyAddData.amount[1] .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. "!")
						reload = true
					else
						postScreenText:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYERROR1 .. " " .. bountyAddData.amount[1] .. " " .. TB_MENU_LOCALIZED.BOUNTYERROR2 .. " " .. bountyAddData.name[1] .. ":\n" .. error)
					end
					local closeButton = postScreen:addChild({
						pos = { postScreen.size.w / 4, postScreenText.shift.y * 2 + postScreenText.size.h },
						size = { postScreen.size.w / 2, postScreen.size.h - postScreenText.shift.y * 3 - postScreenText.size.h },
						interactive = true,
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
						hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
					}, true)
					closeButton:addAdaptedText(TB_MENU_LOCALIZED.BUTTONOK)
					closeButton:addMouseUpHandler(function()
							overlay:kill()
							if (reload) then
								update_tc_balance()
								TB_MENU_PLAYER_INFO.data.tc = TB_MENU_PLAYER_INFO.data.tc - bountyAddData.amount[1]
								TBMenu:showUserBar()
								Bounty:prepare(true)
							end
						end)
				end, function()
					overlay:kill()
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORTRYAGAIN)
				end)
		end)
end

---Displays Bounty main screen
function Bounty:showBounties()
	TBMenu.CurrentSection:kill(true)
	local mainView = TBMenu.CurrentSection:addChild({
		pos = { 5, 0 },
		size = { TBMenu.CurrentSection.size.w / 5 * 3 - 10, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local playerStatsView = mainView:addChild({
		size = { mainView.size.w, mainView.size.h - math.min(mainView.size.h * 0.4, 200) }
	})
	TBMenu:displayLoadingMark(playerStatsView, TB_MENU_LOCALIZED.BOUNTYREFRESHINGSTATS)
	local bountyAddView = mainView:addChild({
		pos = { 0, playerStatsView.size.h },
		size = { mainView.size.w, mainView.size.h - playerStatsView.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	TBMenu:addBottomBloodSmudge(bountyAddView, 1)
	Bounty:displayBountyAdd(bountyAddView)

	Request:queue(function()
			download_server_info("bountystats&username=" .. TB_MENU_PLAYER_INFO.username)
		end,
		"tbMenuBountyUserinfo",
		function()
			if (mainView ~= nil and not mainView.destroyed) then
				local userStats = Bounty.ParseUserStats(get_network_response())
				Bounty:showMainView(playerStatsView, userStats)
			end
		end,
		function()
			if (mainView ~= nil and not mainView.destroyed) then
				mainView:kill(true)
				TBMenu:addBottomBloodSmudge(mainView, 1)
				mainView:addAdaptedText(false, TB_MENU_LOCALIZED.ACCOUNTINFOERROR)
			end
		end)

	local bountyList = TBMenu.CurrentSection:addChild({
		pos = { mainView.size.w + 15, 0 },
		size = { TBMenu.CurrentSection.size.w / 5 * 2 - 10, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	Bounty:showBountyList(bountyList)
end

---Returns most relevant bounty target
---@return PlayerBounty?
function Bounty.GetTarget()
	local bounties = {}
	for _, v in pairs(Bounty.DataList) do
		if (v.claimedby == "") then
			table.insert(bounties, v)
		end
	end

	if (#bounties > 0) then
		bounties = table.qsort(bounties, "reward", SORT_DESCENDING)
		for _, v in pairs(bounties) do
			if (v.room) then
				return v
			end
		end
		return bounties[1]
	else
		return nil
	end
end

---Prepares Bounty data and displays main screen when ready
---@param reload ?boolean
function Bounty:prepare(reload)
	TBMenu.CurrentSection:kill(true)

	TB_MENU_SPECIAL_SCREEN_ISOPEN = 7
	RoomList.RefreshIfNeeded()

	if (#Bounty.DataList == 0 or Bounty.LastUpdate + Bounty.StalePeriod < UIElement.clock or reload) then
		Bounty.DataList = {}
		local loadingOverlay = TBMenu.CurrentSection:addChild({
			pos = { 5, 0 },
			size = { TBMenu.CurrentSection.size.w - 10, TBMenu.CurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(loadingOverlay, 1)
		TBMenu:displayLoadingMark(loadingOverlay, TB_MENU_LOCALIZED.BOUNTYUPDATINGLIST)
		Request:queue(function() download_server_info("bounties") end, "tbMenuBountyNetworkFetch", function()
				if (loadingOverlay == nil or loadingOverlay.destroyed) then
					return
				end
				Bounty.ParseBountyData(get_network_response())
				Bounty:showBounties()
			end, function()
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORTRYAGAIN .. "\n" .. get_network_error())
				if (loadingOverlay ~= nil and not loadingOverlay.destroyed) then
					Bounty.Quit()
				end
			end)
	else
		Bounty:showBounties()
	end
end
