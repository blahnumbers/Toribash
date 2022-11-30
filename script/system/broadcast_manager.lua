-- Advanced global message display
require("toriui.uielement")
require("system.network_request")

if (not Broadcasts or TB_MENU_DEBUG) then
	---@class Broadcast
	---@field id integer Broadcast ID according to Toribash database
	---@field msg string Global message associated with the broadcast
	---@field room string|nil Room name parsed from global message
	---@field user string Name of the user who sent out the broadcast

	---Manager class to handle Toribash global messages popups
	---
	---**Ver 1.1 updates:**
	--- - All globals are now class fields
	--- - Tweaked visuals for popups to take less space
	--- - Do not display auto tourney announcements if user opted out from them
	---@class Broadcasts
	---@field HOOKS_ACTIVE boolean Whether surveyor hooks are currently active
	---@field LAST_BROADCAST integer Last displayed broadcast ID
	---@field DISPLAY_DURATION integer Popup display duration in seconds
	---@field IS_DISPLAYED boolean Whether there's a broadcast popup displayed at the moment
	Broadcasts = {
		_index = {},
		ver = 1.1,
		HOOKS_ACTIVE = false,
		LAST_BROADCAST = 0,
		DISPLAY_DURATION = 12,
		IS_DISPLAYED = false
	}
	setmetatable({}, Broadcasts)
end

---Displays a broadcast pop-up in game
---@param broadcast Broadcast
---@return boolean #Whether the pop-up has been displayed or queued for display
function Broadcasts:showBroadcast(broadcast)
	if (broadcast.id <= Broadcasts.LAST_BROADCAST) then
		return false
	end
	if (Broadcasts.IS_DISPLAYED) then
		local waiter = UIElement:new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { 0, 0 },
			size = { 0, 0 }
		})
		waiter:addCustomDisplay(true, function()
				if (not Broadcasts.IS_DISPLAYED) then
					waiter:kill()
					Broadcasts:showBroadcast(broadcast)
				end
			end)
		return true
	end

	Broadcasts.IS_DISPLAYED = true
	local notificationHolder = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { WIN_W, WIN_H - 310 },
		size = { 450, 250 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		shapeType = ROUNDED,
		rounded = 5,
		innerShadow = { 0, 5 },
		shadowColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	local popupClose = notificationHolder:addChild({
		pos = { -35, 5 },
		size = { 30, 30 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	}, true)
	local popupCloseIcon = popupClose:addChild({
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
	broadcastTitle:addAdaptedText(true, "Broadcast: " .. broadcast.user, nil, nil, FONTS.BIG, LEFTMID, 0.8, nil, 0.6)
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
		local broadcastRoom = notificationHolder:addChild({
			pos = { 20, broadcastInfo.size.h + broadcastInfo.shift.y + 5 },
			size = { notificationHolder.size.w - 40, notificationHolder.size.h - broadcastInfo.size.h - broadcastInfo.shift.y - 15 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		}, true)
		broadcastRoom:addAdaptedText(nil, "Join " .. broadcast.room)
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

	local progress = math.pi / 10
	notificationHolder:addCustomDisplay(false, function()
			if (notificationHolder.pos.x > WIN_W - notificationHolder.size.w) then
				notificationHolder:moveTo(-notificationHolder.size.w * 0.07 * math.sin(progress), nil, true)
				progress = progress + math.pi / 30
			else
				local clock = os.clock_real()
				notificationHolder:addCustomDisplay(false, function()
						broadcastDisplayTimer.size.w = math.max(notificationHolder.size.w * math.min(1, (os.clock_real() - clock) / Broadcasts.DISPLAY_DURATION), broadcastDisplayTimer.size.w)
						if (clock + Broadcasts.DISPLAY_DURATION < os.clock_real() or buttonClicked) then
							local progress = math.pi / 10
							notificationHolder:addCustomDisplay(false, function()
									if (notificationHolder.pos.x < WIN_W) then
										notificationHolder:moveTo(notificationHolder.size.w * 0.07 * math.sin(progress), nil, true)
										progress = progress + math.pi / 30
									else
										notificationHolder:kill()
										Broadcasts.IS_DISPLAYED = false
									end
								end)
						end
					end)
			end
		end)
	Broadcasts.LAST_BROADCAST = broadcast.id
	return true
end

---Fetches and parses recent broadcast data from Toribash server.\
---If there's a hit, queues the broadcast for display.
---@return nil
function Broadcasts:fetchBroadcast()
	Request:queue(function() download_server_info("last_broadcast") end, "broadcast", function()
			local response = get_network_response()
			---@type Broadcast
			local broadcast = { id = 0 }
			for ln in response:gmatch("[^\n]*\n?") do
				local ln = ln:gsub("\n$", '')
				if (ln:find("^BROADCASTID 0;")) then
					broadcast.id = ln:gsub("^BROADCASTID 0;", ''):gsub("[^%d]", "")
					broadcast.id = broadcast.id == '' and 0 or broadcast.id + 0
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
				end
			end
			if (broadcast.room and broadcast.room:find("^tourney%d$") and bit.band(get_option("showbroadcast"), 4) ~= 0) then
				Broadcasts.LAST_BROADCAST = broadcast.id
				return
			end
			Broadcasts:showBroadcast(broadcast)
		end)
end

---Activates broadcasts surveyor hooks
---@return nil
function Broadcasts:activate()
	Broadcasts:deactivate()
	Broadcasts.HOOKS_ACTIVE = true
	add_hook("console", "broadcast_manager", function(s, i)
			if (i == 1) then
				if (s:find("%[global%]")) then
					Broadcasts:fetchBroadcast()
				end
			end
		end)
	if (bit.band(get_option("showbroadcast"), 2) ~= 0) then
		Broadcasts:addListener()
	end
end

---Adds a listener draw2d hook that periodically checks for new in-game broadcasts while the user is in Free Play mode
---@return nil
function Broadcasts:addListener()
	local clock = -60
	add_hook("draw2d", "broadcast_manager", function()
			if (get_world_state().game_type == 0 and not TUTORIAL_ISACTIVE) then
				if (clock < os.clock_real() - 60) then
					clock = os.clock_real()
					Broadcasts:fetchBroadcast()
				end
			end
		end)
end

---Unloads broadcasts related hooks
---@return nil
function Broadcasts:deactivate()
	Broadcasts.HOOKS_ACTIVE = false
	remove_hooks("broadcast_manager")
end
