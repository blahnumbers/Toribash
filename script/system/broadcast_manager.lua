-- Advanced global message display
require("toriui.uielement")
require("system.network_request")

if (not Broadcasts) then
	---@class Broadcast
	---@field id integer Broadcast ID according to Toribash database
	---@field msg string Global message associated with the broadcast
	---@field room string|nil Room name parsed from global message
	---@field user string Name of the user who sent out the broadcast
	---@field time integer Time when this broadcast was retrieved
	---@field minqi integer	Broadcast min Qi requirement
	---@field maxqi integer Broadcast max Qi requirement

	---Manager class to handle Toribash global messages popups
	---
	---**Version 5.70**
	---* Added `HookName` field
	---
	---**Version 5.65**
	---* Minor fixes to broadcast data parsing from server
	---
	---**Version 5.64**
	---* Broadcast belt restriction support
	---
	---**Version 5.60:**
	---* Broadcasts are now initialized automatically on script launch
	---
	---**Ver 1.1 updates:**
	--- - All globals are now class fields
	--- - Tweaked visuals for popups to take less space
	--- - Do not display auto tourney announcements if user opted out from them
	---@class Broadcasts
	---@field IsActive boolean Whether Broadcasts manager is currently active
	---@field LastBroadcast integer Last displayed broadcast ID
	---@field DisplayDuration integer Popup display duration in seconds
	---@field IsDisplayed boolean Whether there's a broadcast popup displayed at the moment, only used on desktop platforms
	---@field StalePeriod integer Cutoff in seconds to consider broadcast stale
	Broadcasts = {
		ver = 5.70,
		IsActive = false,
		LastBroadcast = 0,
		DisplayDuration = 12,
		StalePeriod = 600,
		IsDisplayed = false,
		HookName = "__tbBroadcastsManager"
	}
	Broadcasts.__index = Broadcasts
end

---Displays a broadcast pop-up in game
---@param broadcast Broadcast
---@return boolean #Whether the pop-up has been displayed or queued for display
function Broadcasts:showBroadcast(broadcast)
	if (broadcast.id <= self.LastBroadcast or broadcast.time + self.StalePeriod < os.time()) then
		return false
	end

	local broadcastRoom = nil
	if (is_mobile()) then
		local popupView = TBHudPopup.New(self.DisplayDuration)
		local broadcastInfo = popupView:addChild({
			pos = { 20, 5 },
			size = { broadcast.room and (popupView.size.w - 50) * 0.7 or popupView.size.w - 20, popupView.size.h - 10 }
		})
		local broadcastTitle = broadcastInfo:addChild({
			pos = { 0, 0 },
			size = { broadcastInfo.size.w, popupView.size.h / 3 }
		})
		broadcastTitle:addAdaptedText(true, TB_MENU_LOCALIZED.BROADCASTSBROADCAST .. ": " .. broadcast.user, nil, nil, FONTS.BIG, LEFTBOT, 0.8, nil, 0.6)
		local broadcastText = broadcastInfo:addChild({
			pos = { 0, broadcastTitle.size.h },
			size = { broadcastInfo.size.w, broadcastInfo.size.h - broadcastTitle.size.h }
		})
		broadcastText:addAdaptedText(true, broadcast.msg, nil, nil, 4, LEFTMID, 0.8)

		if (broadcast.room) then
			local broadcastButtonHolder = popupView:addChild({
				pos = { broadcastInfo.shift.x * 2 + broadcastInfo.size.w, broadcastInfo.shift.y },
				size = { popupView.size.w - broadcastInfo.shift.x * 3 - broadcastInfo.size.w, broadcastInfo.size.h }
			}, true)
			broadcastRoom = broadcastButtonHolder:addChild({
				shift = { 0, 10 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			}, true)
			broadcastRoom:addAdaptedText(false, TB_MENU_LOCALIZED.BROADCASTSJOIN .. " " .. broadcast.room)
			broadcastRoom:addMouseHandlers(nil, function()
					runCmd("join " .. broadcast.room)
					popupView:Close()
				end)
		end
	else
		if (self.IsDisplayed) then
			local waiter = UIElement.new({
				globalid = TB_MENU_HUB_GLOBALID,
				pos = { 0, 0 },
				size = { 0, 0 }
			})
			waiter:addCustomDisplay(true, function()
					if (not self.IsDisplayed) then
						waiter:kill()
						self:showBroadcast(broadcast)
					end
				end)
			return true
		end

		self.IsDisplayed = true
		local notificationHolder = UIElement.new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { WIN_W, WIN_H - 310 },
			size = { 450, 250 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5,
			innerShadow = { 0, 5 },
			shadowColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		notificationHolder.killAction = function() self.IsDisplayed = false end

		local popupClose = notificationHolder:addChild({
			pos = { -35, 5 },
			size = { 30, 30 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		popupClose:addChild({
			shift = { 3, 3 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		local buttonClicked = false
		popupClose:addMouseHandlers(nil, function()
				buttonClicked = true
			end)
		local broadcastInfo = notificationHolder:addChild({
			pos = { 10, 5 },
			size = { notificationHolder.size.w - 20, notificationHolder.size.h - (broadcast.room and 55 or 0) }
		})
		local broadcastTitle = broadcastInfo:addChild({
			pos = { 0, 0 },
			size = { broadcastInfo.size.w - 35, 32 }
		})
		broadcastTitle:addAdaptedText(true, TB_MENU_LOCALIZED.BROADCASTSBROADCAST .. ": " .. broadcast.user, nil, nil, FONTS.BIG, LEFTMID, 0.8, nil, 0.6)
		local broadcastText = broadcastInfo:addChild({
			pos = { 0, broadcastTitle.size.h },
			size = { broadcastInfo.size.w, broadcastInfo.size.h - broadcastTitle.size.h }
		})
		broadcastText:addAdaptedText(true, broadcast.msg, nil, nil, 4, LEFTMID, 0.8)
		broadcastText.size.h = math.max(#broadcastText.dispstr * 10 * getFontMod(broadcastText.textFont) * broadcastText.textScale + 5, 45)
		broadcastInfo.size.h = broadcastTitle.size.h + broadcastText.size.h
		notificationHolder.size.h = broadcastInfo.size.h + (broadcast.room and 55 or 15)
		notificationHolder:moveTo(nil, WIN_H - notificationHolder.size.h - 60)

		if (broadcast.room) then
			broadcastRoom = notificationHolder:addChild({
				pos = { 20, broadcastInfo.size.h + broadcastInfo.shift.y + 5 },
				size = { notificationHolder.size.w - 40, notificationHolder.size.h - broadcastInfo.size.h - broadcastInfo.shift.y - 15 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			}, true)
			broadcastRoom:addAdaptedText(false, TB_MENU_LOCALIZED.BROADCASTSJOIN .. " " .. broadcast.room)
			broadcastRoom:addMouseHandlers(nil, function()
					runCmd("join " .. broadcast.room)
					buttonClicked = true
				end)
		end

		local broadcastDisplayTimer = notificationHolder:addChild({
			pos = { 0, -notificationHolder.rounded },
			size = { notificationHolder.rounded * 2, notificationHolder.rounded },
			rounded = { 0, notificationHolder.rounded },
			bgColor = UICOLORWHITE
		}, true)

		local spawnClock = UIElement.clock
		notificationHolder:addCustomDisplay(false, function()
				local ratio = UIElement.clock - spawnClock
				if (ratio < 1) then
					notificationHolder:moveTo(UITween.SineTween(notificationHolder.pos.x, WIN_W - notificationHolder.size.w, ratio))
				end
				local progress = math.min(1, (UIElement.clock - spawnClock) / self.DisplayDuration)
				broadcastDisplayTimer.size.w = math.max(notificationHolder.size.w * progress, broadcastDisplayTimer.size.w)
				if (progress == 1 or buttonClicked) then
					spawnClock = UIElement.clock
					notificationHolder:addCustomDisplay(false, function()
							local ratio = UIElement.clock - spawnClock
							notificationHolder:moveTo(UITween.SineTween(notificationHolder.pos.x, WIN_W, ratio))
							if (ratio >= 1) then
								notificationHolder:kill()
							end
						end)
				end
			end)
	end
	local roomInfo = get_room_info() or { name = "'" }
	if (broadcastRoom ~= nil and roomInfo.name == broadcast.room) then
		broadcastRoom:deactivate()
	end
	self.LastBroadcast = broadcast.id
	return true
end

---Fetches and parses recent broadcast data from Toribash server\
---If there's a hit, queues the broadcast for display
function Broadcasts:fetchBroadcast()
	Request:queue(function() download_server_info("last_broadcast") end, "broadcast", function()
			local response = get_network_response()
			if (string.len(response) == 0) then return end
			---@type Broadcast
			local broadcast = { id = 0, time = os.time(), minqi = -1, maxqi = -1 }
			for ln in response:gmatch("[^\n]*\n?") do
				local ln = ln:gsub("\n$", '')
				if (ln:find("^BROADCASTID 0;")) then
					local id = ln:gsub("^BROADCASTID 0;", '')
					id = id:gsub("[^%d]", "")
					broadcast.id = tonumber(id) or 0
				elseif (ln:find("^BROADCASTMSG 0;")) then
					broadcast.msg = ln:gsub("^BROADCASTMSG 0;", '')
					broadcast.msg = broadcast.msg:gsub("%^%d%d", '')
					broadcast.msg = broadcast.msg:gsub("%%%d%d%d", '')
					if (broadcast.msg:find("[Jj][Oo][Ii]?[Nn]? %w+")) then
						local str = broadcast.msg:gsub("^.*/?[Jj][Oo][Ii]?[Nn]? ", '')
						if (str ~= broadcast.msg) then
							local room = str:gsub("%W+.*$", '')
							if (room ~= '') then
								broadcast.room = room
							end
						end
					end
				elseif (ln:find("^BROADCASTUSER 0;")) then
					broadcast.user = ln:gsub("^BROADCASTUSER 0;", '')
				elseif (ln:find("^BROADCASTQI 0;")) then
					local qiStr = ln:gsub("^BROADCASTQI 0;", '')
					local qi = { qiStr:match(("(%d+) ?"):rep(2)) }
					broadcast.minqi = tonumber(qi[1]) or 0
					broadcast.maxqi = tonumber(qi[2]) or 0
				end
			end
			if (broadcast.room and broadcast.room:find("^tourney%d$") and bit.band(tonumber(get_option("showbroadcast")) or 0, 4) ~= 0) then
				self.LastBroadcast = broadcast.id
				return
			end
			local playerQi = (TB_MENU_PLAYER_INFO and TB_MENU_PLAYER_INFO.data) and TB_MENU_PLAYER_INFO.data.qi or 0
			if (broadcast.minqi > playerQi or (broadcast.maxqi ~= 0 and broadcast.maxqi < playerQi)) then
				self.LastBroadcast = broadcast.id
				return
			end
			Broadcasts:showBroadcast(broadcast)
		end)
end

---Unloads broadcasts related hooks
function Broadcasts:deactivate()
	self.IsActive = false
	remove_hooks(self.HookName)
end

---Activates broadcasts surveyor hooks
function Broadcasts:activate()
	self:deactivate()
	self.IsActive = true
	add_hook("console", self.HookName, function(s, i)
			if (i == 1) then
				if (utf8.find(s, "%[global%]")) then
					Broadcasts:fetchBroadcast()
				end
			end
		end)
	if (bit.band(tonumber(get_option("showbroadcast")) or 0, 2) ~= 0) then
		Broadcasts:addListener()
	end
end

---Adds a listener hook that periodically checks for new in-game broadcasts while the user is in Free Play mode
function Broadcasts:addListener()
	local clock = -60
	add_hook("draw2d", self.HookName, function()
			if (UIElement.WorldState.game_type == 0 and not TUTORIAL_ISACTIVE) then
				if (clock < UIElement.clock - 60) then
					clock = UIElement.clock
					Broadcasts:fetchBroadcast()
				end
			end
		end)
end

Broadcasts:activate()
