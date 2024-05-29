require("toriui.uielement")
require("system.menu_defines")
require("system.menu_manager")
require("system.quests_manager")

local inputData = ARG
local _, popups = inputData:gsub(":", "")
local popupsRaw = { inputData:match(("([^ ]+) ?"):rep(popups)) }
local popupsData = {}
for _, v in pairs(popupsRaw) do
	local data = { v:match(("([^:]*):?"):rep(2)) }
	for i, _ in pairs(data) do
		data[i] = tonumber(data[i])
	end
	table.insert(popupsData, data)
end

local function showPopup(i)
	local displayDuration = Quests.PopupDisplayDuration
	local quest = Quests:getQuestById(popupsData[i][1])
	if (not quest) then
		if (popupsData[i + 1]) then
			showPopup(i + 1)
		end
		return
	end
	local oldProgress = quest.progress
	Quests:setQuestProgress(quest, popupsData[i][2])
	if (oldProgress > quest.progress) then
		displayDuration = 0
	elseif (quest.progress >= quest.requirement) then
		displayDuration = displayDuration * 3
	end
	local percentageThreshold = math.floor(oldProgress / quest.requirement * 3)
	if (math.floor(quest.progress / quest.requirement * 3) == percentageThreshold) then
		if (popupsData[i + 1]) then
			showPopup(i + 1)
		end
		return
	end

	if (is_mobile()) then
		local popupView = TBHudPopup.New(displayDuration)
		local questInfo = popupView:addChild({
			pos = { 20, 5 },
			size = { (popupView.size.w - 50) / 2, popupView.size.h - 10 }
		})
		questInfo.killAction = function()
			if (popupsData[i + 1]) then
				showPopup(i + 1)
			end
		end
		local questName = questInfo:addChild({
			pos = { 0, 0 },
			size = { questInfo.size.w, questInfo.size.h / 2 }
		})
		questName:addAdaptedText(true, quest.name, nil, nil, nil, LEFTBOT)
		local questObjective = questInfo:addChild({
			pos = { 0, questName.shift.y + questName.size.h },
			size = { questInfo.size.w, questInfo.size.h - questName.shift.y * 2 - questName.size.h }
		})
		questObjective:addAdaptedText(true, quest.description, nil, nil, 4, LEFT, 0.7)
		local progressBarHeight = math.min(40, questInfo.size.h)
		local questProgressBarOutline = popupView:addChild({
			pos = { questInfo.shift.x * 2 + questInfo.size.w, (popupView.size.h - progressBarHeight) / 2 },
			size = { popupView.size.w - questInfo.shift.x * 3 - questInfo.size.w, progressBarHeight },
			bgColor = { 1, 1, 1, 0.3 },
			hoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
			shapeType = ROUNDED,
			rounded = 4
		})
		questProgressBarOutline:deactivate()
		local questProgressBar = questProgressBarOutline:addChild({ shift = { 1, 1 }, bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR) }, true)
		local pSize = math.max(questProgressBarOutline.rounded * 2, oldProgress == 0 and 1 or questProgressBar.size.w * (oldProgress / quest.requirement))
		local questProgress = questProgressBar:addChild({
			pos = { 0, 0 },
			size = { pSize, questProgressBar.size.h },
			bgColor = UICOLORWHITE
		}, true)
		local questProgressText = questProgressBar:addChild({
			shift = { 10, 2 },
			uiColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
			uiShadowColor = table.clone(UICOLORWHITE),
			shadowOffset = 2
		})

		local function showClaim(quest)
			local beginClock = UIElement.clock
			questProgressBar.bgColor[4] = 0
			questInfo:addCustomDisplay(false, function()
					local timeDiff = (UIElement.clock - beginClock) * 2
					questProgress.size.w = UITween.SineEaseOut(1 - timeDiff, questProgressBar.size.w)
					for i = 1, 4 do
						questProgressBarOutline.bgColor[i] = UITween.SineTween(questProgressBarOutline.bgColor[i], TB_MENU_DEFAULT_ORANGE[i], timeDiff)
						questProgressText.uiColor[i] = UITween.SineTween(questProgressText.uiColor[i], 0, timeDiff)
					end
					questProgressText.uiColor[4] = UITween.SineTween(questProgressText.uiColor[4], math.abs(1 - timeDiff * 2), timeDiff)
					questProgressText.uiShadowColor[4] = questProgressText.uiColor[4]
					if (timeDiff >= 0.5 and questProgressText.str ~= TB_MENU_LOCALIZED.QUESTSCLAIMREWARD) then
						questProgressText:addAdaptedText(true, TB_MENU_LOCALIZED.QUESTSCLAIMREWARD, nil, nil, nil, nil, nil, nil, nil, questProgressText.shadowOffset)
					end
					if (timeDiff >= 1) then
						questProgress:kill()
						questProgressBarOutline:activate()
						questInfo:addCustomDisplay(false, function() end)
						questProgressBarOutline:addMouseUpHandler(function()
								popupView:Close()
								TB_MENU_QUEST_NOTIFICATIONS = math.max(0, TB_MENU_QUEST_NOTIFICATIONS - 1)
								Quests:claim(quest, nil, Quests.download)
							end)
						return
					end
				end, true)
		end

		local targetSize = questProgressBar.size.w * (quest.progress / quest.requirement)
		questProgress:addCustomDisplay(false, function()
				if (popupView.__launchClock == nil) then return end
				if (questProgress.size.w < targetSize) then
					questProgress.size.w = UITween.SineTween(questProgress.size.w, targetSize, UIElement.clock - popupView.__launchClock - 0.4)
					questProgressText:addAdaptedText(true, math.min(quest.progress, math.ceil(questProgress.size.w / targetSize * quest.progress)) .. " / " .. quest.requirement, nil, nil, nil, nil, nil, nil, nil, questProgressText.shadowOffset)
				else
					if (quest.progress >= quest.requirement) then
						showClaim(quest)
						TB_MENU_QUEST_NOTIFICATIONS = TB_MENU_QUEST_NOTIFICATIONS + 1
					end
					questProgress:addCustomDisplay(false, function() end, true)
				end
			end, true)
	else
		local questProgressNotificationHolder = UIElement:new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { WIN_W, WIN_H - 140 },
			size = { 350, 90 },
			interactive = true,
			bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
			hoverColor = TB_MENU_DEFAULT_YELLOW,
			pressedColor = TB_MENU_DEFAULT_ORANGE,
			shapeType = ROUNDED,
			rounded = 4,
			innerShadow = { 0, 5 },
			shadowColor = table.clone(TB_MENU_DEFAULT_DARKER_COLOR)
		})
		questProgressNotificationHolder:deactivate()
		local popupClose = questProgressNotificationHolder:addChild({
			pos = { -33, 5 },
			size = { 28, 28 },
			shapeType = questProgressNotificationHolder.shapeType,
			rounded = questProgressNotificationHolder.rounded,
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		local popupCloseIcon = popupClose:addChild({
			shift = { 4, 4 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		local buttonClicked = false
		popupClose:addMouseHandlers(nil, function()
				buttonClicked = true
			end)
		local questInfo = questProgressNotificationHolder:addChild({
			shift = { 15, 8 },
		})
		local questName = questInfo:addChild({
			pos = { 0, 0 },
			size = { questInfo.size.w, questInfo.size.h / 3 }
		})
		questName:addAdaptedText(true, quest.name, nil, nil, nil, LEFTMID)
		local questObjective = questInfo:addChild({
			pos = { 0, questInfo.size.h / 3 },
			size = { questInfo.size.w, questInfo.size.h / 4 }
		})
		questObjective:addAdaptedText(true, quest.description, nil, nil, 4, LEFTMID, 0.6)
		local questProgressBarOutline = questInfo:addChild({
			pos = { 0, questInfo.size.h / 5 * 3 + 2 },
			size = { questInfo.size.w, questInfo.size.h / 5 * 2 - 4 },
			bgColor = { 1, 1, 1, 0.3 },
			shapeType = ROUNDED,
			rounded = 3
		})
		local questProgressBar = questProgressBarOutline:addChild({ shift = { 1, 1 }, bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR) }, true)
		local pSize = math.max(questProgressBarOutline.rounded * 2, oldProgress == 0 and 1 or questProgressBar.size.w * (oldProgress / quest.requirement))
		local questProgress = questProgressBar:addChild({
			pos = { 0, 0 },
			size = { pSize, questProgressBar.size.h },
			bgColor = UICOLORWHITE
		}, true)
		local questProgressText = questProgressBar:addChild({ shift = { 10, 2 } })
		local questProgressTimer = questProgressNotificationHolder:addChild({
			pos = { 0, -questProgressNotificationHolder.rounded },
			size = { questProgressNotificationHolder.rounded * 2, questProgressNotificationHolder.rounded },
			rounded = { 0, questProgressNotificationHolder.rounded },
			bgColor = UICOLORWHITE
		}, true)

		local function showClaim(quest)
			local trans = 1
			local grow = 10
			local colorsDiff, barDiff, barOutDiff = {}, {}, {}
			for i,v in pairs(TB_MENU_DEFAULT_ORANGE) do
				colorsDiff[i] = (questProgressNotificationHolder.bgColor[i] - v) / 20
			end
			for i,v in pairs(TB_MENU_DEFAULT_DARKEST_ORANGE) do
				barDiff[i] = (questProgressBar.bgColor[i] - v) / 20
				barOutDiff[i] = (questProgressBarOutline.bgColor[i] - v) / 20
			end
			popupClose:kill()
			questInfo:addCustomDisplay(false, function()
					trans = trans - 0.025
					grow = grow + 0.5
					if (trans < 0) then
						questProgress:kill()
						questProgressNotificationHolder:activate()
						questProgressNotificationHolder:addMouseUpHandler(function()
								buttonClicked = true
								TB_MENU_QUEST_NOTIFICATIONS = math.max(0, TB_MENU_QUEST_NOTIFICATIONS - 1)
								Quests:claim(quest, nil, Quests.download)
							end)

						questInfo:addCustomDisplay(false, function() end)
						return
					end
					if (trans <= 0.5) then
						for i = 1, 3 do
							questProgressNotificationHolder.bgColor[i] = questProgressNotificationHolder.bgColor[i] - colorsDiff[i]
							questProgressNotificationHolder.innerShadow[2] = questProgressNotificationHolder.innerShadow[2] * trans * 2
							questProgressBar.bgColor[i] = questProgressBar.bgColor[i] - barDiff[i]
							questProgressBarOutline.bgColor[i] = questProgressBarOutline.bgColor[i] - barOutDiff[i]
						end
						questProgress.size.w = questProgressBar.size.w * trans * 2

						if (trans <= 0.25) then
							questProgressText.uiColor = { 1, 1, 1, 1 }
							questName.uiColor = { 0, 0, 0, 0.8 }
							questObjective.uiColor = { 0, 0, 0, 0.8 }
							questProgressText:addAdaptedText(true, TB_MENU_LOCALIZED.QUESTSCLAIMREWARD)
						else
							questProgressText.uiColor = { 1, 1, 1, trans * 4 - 1 }
							questName.uiColor = { trans * 4 - 1, trans * 4 - 1, trans * 4 - 1, 0.8 }
							questObjective.uiColor = { trans * 4 - 1, trans * 4 - 1, trans * 4 - 1, 0.8 }
							questProgressText:addAdaptedText(true, questProgressText.str)
						end
					end
				end, true)
		end

		local progress = math.pi / 10
		local barProgress = progress
		local targetSize = questProgressBar.size.w * (quest.progress / quest.requirement)
		local sizeDifference = targetSize - questProgress.size.w
		questProgressNotificationHolder:addCustomDisplay(false, function()
				if (questProgressNotificationHolder.pos.x > WIN_W - 340) then
					questProgressNotificationHolder:moveTo(-questProgressNotificationHolder.size.w * 0.07 * math.sin(progress), nil, true)
					progress = progress + math.pi / 30
				else
					local clock = UIElement.clock
					questProgress:addCustomDisplay(false, function()
							if (questProgress.size.w < (questProgressBar.size.w * (quest.progress / quest.requirement))) then
								questProgress.size.w = questProgress.size.w + sizeDifference * 0.02 * math.sin(barProgress)
								local tSize = targetSize == 0 and 0 or (questProgress.size.w / targetSize)
								questProgressText:addAdaptedText(true, math.min(quest.progress, math.floor(tSize * quest.progress)) .. " / " .. quest.requirement, nil, nil, nil, nil, nil, nil, nil, 1)
								barProgress = barProgress + math.pi / 100
							else
								if (quest.progress >= quest.requirement) then
									showClaim(quest)
									TB_MENU_QUEST_NOTIFICATIONS = TB_MENU_QUEST_NOTIFICATIONS + 1
								end
								questProgress:addCustomDisplay(false, function() end, true)
							end
						end, true)
					questProgressNotificationHolder:addCustomDisplay(false, function()
							questProgressTimer.size.w = math.max(questProgressNotificationHolder.size.w * math.min(1, (UIElement.clock - clock) / displayDuration), questProgressTimer.size.w)
							if (clock + displayDuration < UIElement.clock or buttonClicked) then
								local progress = math.pi / 10
								questProgressNotificationHolder:addCustomDisplay(false, function()
									if (questProgressNotificationHolder.pos.x < WIN_W) then
										questProgressNotificationHolder:moveTo(questProgressNotificationHolder.size.w * 0.07 * math.sin(progress), nil, true)
										progress = progress + math.pi / 30
									else
										questProgressNotificationHolder:kill()
										if (popupsData[i + 1]) then
											showPopup(i + 1)
										end
									end
								end)
							end
						end)
				end
			end)
	end
end

showPopup(1)
