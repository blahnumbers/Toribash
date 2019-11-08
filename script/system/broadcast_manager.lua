-- Advanced global message display
require("system/network_request")

BROADCAST_DISPLAYED = false
BROADCAST_DELAY = 10
LAST_BROADCAST = 0

do
	Broadcasts = {}
	Broadcasts.__index = Broadcasts
	local cln = {}
	setmetatable(cln, Broadcasts)
	
	function Broadcasts:showBroadcast(broadcast)
		if (broadcast.id <= LAST_BROADCAST) then
			return false
		end
		if (BROADCAST_DISPLAYED) then
			local waiter = UIElement:new({
				globalid = TB_MENU_HUB_GLOBALID,
				pos = { 0, 0 },
				size = { 0, 0 }
			})
			waiter:addCustomDisplay(true, function()
					if (not BROADCAST_DISPLAYED) then
						waiter:kill()
						Broadcasts:showBroadcast(broadcast)
					end
				end)
			return true
		end
		
		BROADCAST_DISPLAYED = true
		local notificationHolder = UIElement:new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { WIN_W, WIN_H - 200 },
			size = { 450, 140 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5,
			innerShadow = { 0, 5 },
			shadowColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local popupClose = UIElement:new({
			parent = notificationHolder,
			pos = { -35, 5 },
			size = { 30, 30 },
			shapeType = notificationHolder.shapeType,
			rounded = notificationHolder.rounded,
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		local popupCloseIcon = UIElement:new({
			parent = popupClose,
			pos = { 3, 3 },
			size = { popupClose.size.w - 6, popupClose.size.h - 6 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		local buttonClicked = false
		popupClose:addMouseHandlers(nil, function()
				buttonClicked = true
			end)
		local broadcastInfo = UIElement:new({
			parent = notificationHolder,
			pos = { 10, 5 },
			size = { notificationHolder.size.w - 20, notificationHolder.size.h - (broadcast.room and 55 or 0) }
		})
		local broadcastTitle = UIElement:new({
			parent = broadcastInfo,
			pos = { 0, 0 },
			size = { broadcastInfo.size.w - 35, 32 }
		})
		broadcastTitle:addAdaptedText(true, "ToriBroadcast: " .. broadcast.user, nil, nil, FONTS.BIG, LEFTMID, nil, nil, nil, 1)
		local broadcastText = UIElement:new({
			parent = broadcastInfo,
			pos = { 0, broadcastTitle.size.h },
			size = { broadcastInfo.size.w, broadcastInfo.size.h - broadcastTitle.size.h }
		})
		broadcastText:addAdaptedText(true, broadcast.msg, nil, nil, nil, LEFTMID)
		if (broadcast.room) then
			local broadcastRoom = UIElement:new({
				parent = notificationHolder,
				pos = { 20, broadcastInfo.size.h + broadcastInfo.shift.y + 5 },
				size = { notificationHolder.size.w - 40, notificationHolder.size.h - broadcastInfo.size.h - broadcastInfo.shift.y - 15 },
				interactive = true,
				shapeType = notificationHolder.shapeType,
				rounded = notificationHolder.rounded,
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
			})
			broadcastRoom:addAdaptedText(nil, "Join " .. broadcast.room)
			broadcastRoom:addMouseHandlers(nil, function()
					UIElement:runCmd("join " .. broadcast.room)
					buttonClicked = true
				end)
		end
		
		local progress = math.pi / 10
		notificationHolder:addCustomDisplay(false, function()
				if (notificationHolder.pos.x > WIN_W - notificationHolder.size.w) then
					notificationHolder:moveTo(-notificationHolder.size.w * 0.07 * math.sin(progress), nil, true)
					progress = progress + math.pi / 30
				else
					local clock = os.clock()
					notificationHolder:addCustomDisplay(false, function()
							set_color(1, 1, 1, 1)
							draw_quad(notificationHolder.pos.x, notificationHolder.pos.y + notificationHolder.size.h - 5, notificationHolder.size.w * (os.clock() - clock) / BROADCAST_DELAY, 5)
							if (clock + BROADCAST_DELAY < os.clock() or buttonClicked) then
								local progress = math.pi / 10
								notificationHolder:addCustomDisplay(false, function()
									set_color(1, 1, 1, 1)
									local size = notificationHolder.size.w * (os.clock() - clock) / BROADCAST_DELAY
									if (size > notificationHolder.size.w) then
										size = notificationHolder.size.w
									end
									draw_quad(notificationHolder.pos.x, notificationHolder.pos.y + notificationHolder.size.h - 5, size, 5)
										if (notificationHolder.pos.x < WIN_W) then
											notificationHolder:moveTo(notificationHolder.size.w * 0.07 * math.sin(progress), nil, true)
											progress = progress + math.pi / 30
										else
											notificationHolder:kill()
											BROADCAST_DISPLAYED = false
										end
									end)
							end
						end)
				end
			end)
		LAST_BROADCAST = broadcast.id
	end
	
	function Broadcasts:fetchBroadcast()
		Request:new("broadcast", function()
				local response = get_network_response()
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
				Broadcasts:showBroadcast(broadcast)
			end)
		download_server_info("last_broadcast")
	end
	
	function Broadcasts:activate()
		Broadcasts:deactivate()
		BROADCASTS_ACTIVE = true
		add_hook("console", "broadcast_manager", function(s, i)
				if (i == 1) then
					if (s:find("%[global%]")) then
						Broadcasts:fetchBroadcast()
					end
				end
			end)
		if (get_option("showbroadcast") == 2) then
			Broadcasts:addListener()
		end
	end
	
	function Broadcasts:addListener()
		BROADCASTS_LISTENER_ACTIVE = true
		local clock = -60
		add_hook("draw2d", "broadcast_manager", function()
				if (get_world_state().game_type == 0 and not TUTORIAL_ISACTIVE) then
					if (clock < os.clock() - 60) then
						if (get_network_task() == 0) then
							clock = os.clock()
							Broadcasts:fetchBroadcast()
						end
					end
				end
			end)
	end
	
	function Broadcasts:deactivate()
		BROADCASTS_ACTIVE = false
		remove_hooks("broadcast_manager")
	end
end
