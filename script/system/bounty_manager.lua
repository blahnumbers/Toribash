-- Bounty manager class

if (download_fetch_bounties) then
	TB_BOUNTIES_DEFINED = true
end

do
	Bounty = {}
	Bounty.__index = Bounty
	local cln = {}
	setmetatable(cln, Bounty)
	
	function Bounty:getBountyData(data)
		local onlinePlayers = FriendsList:updateOnline()
		local data_types = { "userid", "player", "tc", "since", "claimed", "claimedby", "decap" }
		
		-- Don't display multiple bounties on same user; only first one will be claimed when user is defeated
		local useridList = {}
		
		for i,ln in pairs(data) do
			if (not ln:find("^#?USERID")) then
				local data_stream = { ln:match(("([^\t]*)\t"):rep(#data_types)) }
				local online = false
				for i,v in pairs(onlinePlayers) do
					if (PlayerInfo:getUser(v.player):lower() == data_stream[2]:lower()) then
						online = v.room
					end
				end
				
				local userid = tonumber(data_stream[1])
				if (not in_array(userid, useridList)) then
					table.insert(PlayerBounties, {
						id = i,
						player = data_stream[2],
						reward = data_stream[3] + 0,
						since = data_stream[4] + 0,
						claimed = data_stream[5] + 0,
						claimedby = data_stream[6],
						decap = data_stream[7] == '1',
						room = online
					})
					table.insert(useridList, userid)
				end
			end
		end
	end
	
	function Bounty:quit()
		if (get_option("newmenu") == 0) then
			tbMenuMain:kill()
			remove_hooks("tbMainMenuVisual")
			return
		end
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
		tbMenuCurrentSection:kill(true) 
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function Bounty:getNavigationButtons()
		local buttonText = (get_option("newmenu") == 0 or TB_MENU_MAIN_ISOPEN == 0) and TB_MENU_LOCALIZED.NAVBUTTONEXIT or TB_MENU_LOCALIZED.NAVBUTTONTOMAIN
		local buttonsData = {
			{ 
				text = buttonText, 
				action = function() Bounty:quit() end, 
				width = get_string_length(buttonText, FONTS.BIG) * 0.65 + 30 
			}
		}
		return buttonsData
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
									if (itemDisplay.hoverState) then
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
	
	function Bounty:formatUserStats(dataString)
		local userStats = {}
		for ln in dataString:gmatch("[^\n]*\n?") do
			local ln = ln:gsub("\n$", '')
			if (ln:find("^CLAIMED 0;")) then
				userStats.claimed = ln:gsub("^CLAIMED 0;", "")
			elseif (ln:find("^USERCLAIMED 0;")) then
				userStats.userClaimed = ln:gsub("^USERCLAIMED 0;", "")
			elseif (ln:find("^USERTOTAL 0;")) then
				userStats.userTotal = ln:gsub("^USERTOTAL 0;", "")
			end
		end
		return userStats
	end
	
	function Bounty:showMainView(viewElement, userStats)
		viewElement:kill(true)
		
		local headerTitle = UIElement:new({
			parent = viewElement,
			pos = { 20, 10 },
			size = { viewElement.size.w - 40, 40 }
		})
		headerTitle:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYYOURSTATISTICS, nil, nil, FONTS.BIG)
		
		if (not userStats.claimed) then
			viewElement:addAdaptedText(false, TB_MENU_LOCALIZED.ERRORTRYAGAIN)
			return
		end
		
		local claimedBounties = UIElement:new({
			parent = viewElement,
			pos = { 20, headerTitle.size.h + headerTitle.shift.y },
			size = { (viewElement.size.w - 40) / 2 - 10, viewElement.size.h - headerTitle.size.h - headerTitle.shift.y - 15 }
		})
		local iconSize = claimedBounties.size.w > claimedBounties.size.h * 0.7 and claimedBounties.size.h * 0.7 or claimedBounties.size.w
		local claimedBountiesIcon = UIElement:new({
			parent = claimedBounties,
			pos = { (claimedBounties.size.w - iconSize) / 2, 0 },
			size = { iconSize, iconSize },
			bgImage = "../textures/menu/general/quests/qtypedecap.tga"
		})
		local claimedBountiesHolder = UIElement:new({
			parent = claimedBounties,
			pos = { 0, claimedBountiesIcon.size.h * 0.8 },
			size = { claimedBounties.size.w, claimedBounties.size.h - claimedBountiesIcon.size.h * 0.8 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = ROUNDED,
			rounded = 10
		})
		claimedBountiesHolder.bgColor[4] = 0.5
		local claimedBountiesTitle = UIElement:new({
			parent = claimedBountiesHolder,
			pos = { 0, 0 },
			size = { claimedBountiesHolder.size.w, claimedBountiesHolder.size.h / 5 * 2 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = claimedBountiesHolder.shapeType,
			rounded = claimedBountiesHolder.rounded
		})
		claimedBountiesTitle.bgColor[4] = 0.5
		claimedBountiesTitle:addAdaptedText(false, TB_MENU_LOCALIZED.BOUNTYCLAIMEDBOUNTIES)
		local claimedBountiesStat = UIElement:new({
			parent = claimedBountiesHolder,
			pos = { 0, claimedBountiesTitle.size.h },
			size = { claimedBountiesHolder.size.w, claimedBountiesHolder.size.h - claimedBountiesTitle.size.h }
		})
		claimedBountiesStat:addAdaptedText(true, userStats.claimed .. "", nil, nil, FONTS.BIG, nil, 1, nil, 0.5)
		
		local userBounties = UIElement:new({
			parent = viewElement,
			pos = { claimedBounties.shift.x + claimedBounties.size.w + 20, claimedBounties.shift.y },
			size = { claimedBounties.size.w, claimedBounties.size.h }
		})
		local userBountiesIcon = UIElement:new({
			parent = userBounties,
			pos = { (userBounties.size.w - iconSize) / 2, 0 },
			size = { iconSize, iconSize },
			bgImage = "../textures/menu/general/quests/qtypedecap.tga"
		})
		local userBountiesHolder = UIElement:new({
			parent = userBounties,
			pos = { 0, userBountiesIcon.size.h * 0.8 },
			size = { userBounties.size.w, userBounties.size.h - userBountiesIcon.size.h * 0.8 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = ROUNDED,
			rounded = 10
		})
		userBountiesHolder.bgColor[4] = 0.5
		local userBountiesTitle = UIElement:new({
			parent = userBountiesHolder,
			pos = { 0, 0 },
			size = { userBountiesHolder.size.w, userBountiesHolder.size.h / 5 * 2 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = userBountiesHolder.shapeType,
			rounded = userBountiesHolder.rounded
		})
		userBountiesTitle.bgColor[4] = 0.5
		userBountiesTitle:addAdaptedText(false, TB_MENU_LOCALIZED.BOUNTYUSERBOUNTIES)
		local userBountiesStat = UIElement:new({
			parent = userBountiesHolder,
			pos = { 0, userBountiesTitle.size.h },
			size = { userBountiesHolder.size.w, userBountiesHolder.size.h - userBountiesTitle.size.h }
		})
		userBountiesStat:addAdaptedText(true, string.upper(TB_MENU_LOCALIZED.WORDTOTAL:sub(0, 1)) .. TB_MENU_LOCALIZED.WORDTOTAL:sub(1) .. ": " .. userStats.userTotal .. "\n" .. string.upper(TB_MENU_LOCALIZED.WORDCLAIMED:sub(0, 1)) .. TB_MENU_LOCALIZED.WORDCLAIMED(1) .. ": " .. userStats.userClaimed, nil, nil, FONTS.BIG, nil, 0.55, nil, 0.5)
	end
	
	function Bounty:showBountyList(viewElement)
		local elementHeight = 35
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 50, elementHeight - 12, 20, TB_MENU_DEFAULT_BG_COLOR)
		TBMenu:addBottomBloodSmudge(botBar, 2)
		local bountyListTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 5 },
			size = { topBar.size.w - 20, topBar.size.h - 10 }
		})
		bountyListTitle:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYLATEST, nil, nil, FONTS.BIG, nil, 0.65)
		
		local listEntries = {}
		local bountyData = UIElement:qsort(PlayerBounties, { 'reward' }, true)
		local bountyData = UIElement:qsort(bountyData, { 'claimedby', 'id' }, false)
		for i,v in pairs(bountyData) do
			local holderTop = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listEntries * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listEntries, holderTop)
			local bgTop = UIElement:new({
				parent = holderTop,
				pos = { 10, 3 },
				size = { holderTop.size.w - 10, holderTop.size.h - 3 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			})
			local bountyPlayer = UIElement:new({
				parent = bgTop,
				pos = { 10, 3 },
				size = { bgTop.size.w / 3 * 2 - 20, bgTop.size.h - 6 }
			})
			bountyPlayer:addAdaptedText(true, (v.decap and (TB_MENU_LOCALIZED.WORDDECAPV .. " ") or (TB_MENU_LOCALIZED.WORDBEAT .. " ")) .. v.player, nil, nil, nil, LEFTMID)
			local bountyPrice = UIElement:new({
				parent = bgTop,
				pos = { -bgTop.size.w / 3 + 10, 3 },
				size = { bgTop.size.w / 3 - 20, bgTop.size.h - 6 }
			})
			bountyPrice:addAdaptedText(true, v.reward .. " TC", nil, nil, FONTS.MEDIUM, RIGHTMID)
			local strlen = get_string_length(bountyPrice.dispstr[1], bountyPrice.textFont) * bountyPrice.textScale
			local tcIcon = UIElement:new({
				parent = bountyPrice,
				pos = { -strlen - 28, 2 },
				size = { 23, 23 },
				bgImage = "../textures/store/toricredit_tiny.tga"
			})
			
			local holderBottom = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listEntries * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listEntries, holderBottom)
			local bgBottom = UIElement:new({
				parent = holderBottom,
				pos = { 10, 0 },
				size = { holderBottom.size.w - 10, holderBottom.size.h - 3 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			})
			
			local bountyInfo = UIElement:new({
				parent = bgBottom,
				pos = { 10, 3 },
				size = { bgBottom.size.w - 20, bgBottom.size.h - 6 }
			})
			if (v.claimedby == "") then
				local onlineStatusIcon = UIElement:new({
					parent = bountyInfo,
					pos = { 0, 4 },
					size = { bountyInfo.size.h - 8, bountyInfo.size.h - 8 },
					shapeType = ROUNDED,
					rounded = bountyInfo.size.h,
					bgColor = v.room == false and UICOLORRED or UICOLORGREEN
				})
				local onlineStatus = UIElement:new({
					parent = bountyInfo,
					pos = { onlineStatusIcon.shift.x + onlineStatusIcon.size.w + 5, 3 },
					size = { bountyInfo.size.w - onlineStatusIcon.shift.x - onlineStatusIcon.size.w - 5, bountyInfo.size.h - 8 }
				})
				onlineStatus:addAdaptedText(true, (v.room == false and TB_MENU_LOCALIZED.BOUNTYOFFLINE or (TB_MENU_LOCALIZED.BOUNTYONLINEIN .. " " .. v.room)), nil, nil, 4, LEFTMID)
				if (v.room) then
					bgBottom.size.h = holderBottom.size.h
					local holderBottomJoin = UIElement:new({
						parent = listingHolder,
						pos = { 0, #listEntries * elementHeight },
						size = { listingHolder.size.w, elementHeight }
					})
					table.insert(listEntries, holderBottomJoin)
					local bgBottomJoin = UIElement:new({
						parent = holderBottomJoin,
						pos = { 10, 0 },
						size = { holderBottomJoin.size.w - 10, holderBottomJoin.size.h - 3 },
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR
					})
					local joinButton = UIElement:new({
						parent = bgBottomJoin,
						pos = { 5, 0 },
						size = { bgBottomJoin.size.w - 10, bgBottomJoin.size.h - 5 },
						interactive = true,
						bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						hoverColor = TB_MENU_DEFAULT_BG_COLOR,
						pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
					})
					joinButton:addAdaptedText(false, TB_MENU_LOCALIZED.FRIENDSLISTJOINROOM, nil, nil, nil, nil, 0.8)
				end
			else
				bountyInfo:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYCLAIMEDBY .. " " .. v.claimedby .. " " .. TB_MENU_LOCALIZED.BOUNTYCLAIMEDBYIN .. " " .. TBMenu:getTime(v.claimed, 1), nil, nil, 4, LEFTMID, 0.7)
			end
		end
		for i,v in pairs(listEntries) do
			v:hide()
		end
		
		bountiesScrollBar = TBMenu:spawnScrollBar(listingHolder, #listEntries, elementHeight)
		bountiesScrollBar:makeScrollBar(listingHolder, listEntries, toReload)
	end
	
	function Bounty:displayBountyAdd(viewElement)
		local displayHolder = UIElement:new({
			parent = viewElement,
			pos = { 20, viewElement.size.h > 120 and (viewElement.size.h - 120) / 4 or 0 },
			size = { viewElement.size.w - 40, viewElement.size.h > 120 and 120 or viewElement.size.h }
		})
		local bountyAddTitle = UIElement:new({
			parent = displayHolder,
			pos = { 0, 0 },
			size = { displayHolder.size.w, displayHolder.size.h / 3 }
		})
		bountyAddTitle:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYADDBOUNTYTITLE, nil, nil, nil, LEFTMID)
		
		local bountyAddData = { name = { "" }, text = { "" }, amount = { "" }}
		bountyAddNameTextfield = TBMenu:spawnTextField(displayHolder, 0, bountyAddTitle.size.h, displayHolder.size.w / 2 - 5, (displayHolder.size.h - bountyAddTitle.size.h) / 2 - 5, bountyAddData.name, false, 4, 0.75, UICOLORWHITE, TB_MENU_LOCALIZED.BOUNTYADDUSERNAME, nil, nil, nil, true)
		bountyAddAmountTextfield = TBMenu:spawnTextField(displayHolder, displayHolder.size.w / 2 + 5, bountyAddTitle.size.h, displayHolder.size.w / 2 - 5, (displayHolder.size.h - bountyAddTitle.size.h) / 2 - 5, bountyAddData.amount, true, 4, 0.75, UICOLORWHITE, TB_MENU_LOCALIZED.BOUNTYADDAMOUNT, nil, nil, nil, true)
		bountyAddTextTextfield = TBMenu:spawnTextField(displayHolder, 0, bountyAddNameTextfield.size.h + bountyAddTitle.size.h + 15, displayHolder.size.w / 3 * 2 - 5, (displayHolder.size.h - bountyAddTitle.size.h) / 2 - 5, bountyAddData.text, false, 4, 0.75, UICOLORWHITE, TB_MENU_LOCALIZED.BOUNTYADDTEXT, nil, nil, nil, true)
		bountyAddTextTextfield:addKeyboardHandlers(function()
				if (bountyAddTextTextfield.textfieldstr[1]:len() > 32) then
					bountyAddTextTextfield.textfieldstr[1] = bountyAddTextTextfield.textfieldstr[1]:sub(0, 32)
					bountyAddTextTextfield.textfieldindex = bountyAddTextTextfield.textfieldindex - 1
				end
			end)
			
		bountyAddButton = UIElement:new({
			parent = displayHolder,
			pos = { bountyAddTextTextfield.size.w + 20, bountyAddNameTextfield.size.h + bountyAddTitle.size.h + 15 },
			size = { displayHolder.size.w - bountyAddTextTextfield.size.w - 20, (displayHolder.size.h - bountyAddTitle.size.h) / 2 - 5 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			hoverColor = TB_MENU_DEFAULT_BG_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		bountyAddButton:addAdaptedText(false, TB_MENU_LOCALIZED.BOUNTYADDBOUNTY)
		bountyAddButton:addMouseHandlers(nil, function()
				if (bountyAddData.name[1] == "") then
					TBMenu:showDataError(TB_MENU_LOCALIZED.BOUNTYERRORNOUSER)
					return
				end
				if (tonumber(bountyAddData.amount[1]) < 100) then
					TBMenu:showDataError(TB_MENU_LOCALIZED.BOUNTYERRORAMOUNT)
					return
				end
				
				local overlay = TBMenu:spawnWindowOverlay()
				local loadingMark = UIElement:new({
					parent = overlay,
					pos = { overlay.size.w / 2 - 200, overlay.size.h / 2 - 50 },
					size = { 400, 100 },
					bgColor = TB_MENU_DEFAULT_BG_COLOR
				})
				TBMenu:displayLoadingMarkSmall(loadingMark, TB_MENU_LOCALIZED.REQUESTFINISHINGACTIVE)
				Request:queue(function()
						show_dialog_box(BOUNTY_ADD_ACTION,
							TB_MENU_LOCALIZED.BOUNTYCONFIRM1 .. " " .. bountyAddData.amount[1] .. " " .. TB_MENU_LOCALIZED.BOUNTYCONFIRM2 .. " " .. bountyAddData.name[1] .. "?",
							bountyAddData.name[1] .. ";" .. bountyAddData.amount[1] .. ";" .. bountyAddData.text[1],
							true)
						loadingMark:kill(true)
						TBMenu:displayLoadingMarkSmall(loadingMark, TB_MENU_LOCALIZED.NETWORKLOADING)
						
						overlay:addMouseHandlers(nil, nil, function(x)
								if (x < WIN_W / 2) then
									overlay:kill()
									Request:cancelCurrentRequest()
								else
									overlay:addMouseHandlers(nil, nil, function() end)
								end
							end)
					end, "bountyadd", function()
						overlay:kill(true)
						local reload = false
						local response = get_network_response()
						local result = response:find("GATEWAY 0; 0")
						local error = result and false or response:gsub("GATEWAY 0; 1 ", "")
						
						local postScreen = UIElement:new({
							parent = overlay,
							pos = { overlay.size.w / 4, overlay.size.h / 2 - 70 },
							size = { overlay.size.w / 2, 140 },
							bgColor = TB_MENU_DEFAULT_BG_COLOR
						})
						local postScreenText = UIElement:new({
							parent = postScreen,
							pos = { 20, 10 },
							size = { postScreen.size.w - 40, postScreen.size.h / 2 }
						})
						if (result) then
							postScreenText:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYSUCCESS1 .. " " .. bountyAddData.name[1] .. " " .. TB_MENU_LOCALIZED.BOUNTYSUCCESS2 .. " " .. bountyAddData.amount[1] .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. "!")
							reload = true
						else
							postScreenText:addAdaptedText(true, TB_MENU_LOCALIZED.BOUNTYERROR1 .. " " .. bountyAddData.amount[1] .. " " .. TB_MENU_LOCALIZED.BOUNTYERROR2 .. " " .. bountyAddData.name[1] .. ":\n" .. error)
						end
						local closeButton = UIElement:new({
							parent = postScreen,
							pos = { postScreen.size.w / 4, postScreenText.shift.y * 2 + postScreenText.size.h },
							size = { postScreen.size.w / 2, postScreen.size.h - postScreenText.shift.y * 3 - postScreenText.size.h },
							interactive = true,
							bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
							hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
							pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
						})
						closeButton:addAdaptedText(false, "OK")
						closeButton:addMouseHandlers(nil, function()
								overlay:kill()
								if (reload) then
									Bounty:prepare(true)
								end
							end)
					end, function()
						overlay:kill()
						TBMenu:showDataError(TB_MENU_LOCALIZED.ERRORTRYAGAIN)
					end)
			end)
	end
	
	function Bounty:showBounties()
		add_hook("console", "tbMenuBountiesChatIgnore", function(s,i)
				if (s:find("Download complete")) then
					remove_hooks("tbMenuBountiesChatIgnore")
					return 1
				end
			end)
		tbMenuCurrentSection:kill(true)
		local mainView = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w / 5 * 3 - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local playerStatsView = UIElement:new({
			parent = mainView,
			pos = { 0, 0 },
			size = { mainView.size.w, mainView.size.h * 0.7 }
		})
		TBMenu:displayLoadingMark(playerStatsView, TB_MENU_LOCALIZED.BOUNTYREFRESHINGSTATS)
		local bountyAddView = UIElement:new({
			parent = mainView,
			pos = { 0, playerStatsView.size.h },
			size = { mainView.size.w, mainView.size.h - playerStatsView.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		Bounty:displayBountyAdd(bountyAddView)
		TBMenu:addBottomBloodSmudge(mainView, 1)
		
		Request:queue(function()
				download_server_info("bountystats&username=" .. TB_MENU_PLAYER_INFO.username)
			end,
			"bountyinfo",
			function()
				local userStats = Bounty:formatUserStats(get_network_response())
				Bounty:showMainView(playerStatsView, userStats)
			end,
			function()
				mainView:kill(true)
				TBMenu:addBottomBloodSmudge(playerStatsView, 1)
				mainView:addAdaptedText(false, TB_MENU_LOCALIZED.ACCOUNTINFOERROR)
			end)
		
		local bountyList = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { mainView.size.w + 15, 0 },
			size = { tbMenuCurrentSection.size.w / 5 * 2 - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Bounty:showBountyList(bountyList)
	end
	
	function Bounty:getTarget()
		local bounties = {}
		for i,v in pairs(PlayerBounties) do
			if (v.claimedby == "") then
				table.insert(bounties, v)
			end
		end
		
		if (#bounties > 0) then
			bounties = UIElement:qsort(bounties, "reward", 1)
			for i,v in pairs(bounties) do
				if (v.room) then
					return v
				end
			end
			return bounties[1]
		else
			return false
		end
	end
	
	function Bounty:prepare(reload)
		tbMenuCurrentSection:kill(true)

		PlayerBounties = {}
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 7
		UIElement:runCmd("refresh")
		
		if (BOUNTIES_LAST_UPDATE + 300 < os.clock() or reload) then
			download_fetch_bounties()
		end
		
		local loadOverlay = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(loadOverlay, 1)
		TBMenu:displayLoadingMark(loadOverlay, TB_MENU_LOCALIZED.BOUNTYUPDATINGLIST)
		local bountyFile = Files:new("../data/bounties.txt")
		loadOverlay:addCustomDisplay(false, function()
				if (not bountyFile:isDownloading()) then
					bountyFile:reopen()
					Bounty:getBountyData(bountyFile:readAll())
					Bounty:showBounties()
					BOUNTIES_LAST_UPDATE = os.clock()
				end
			end)
	end
	
end
