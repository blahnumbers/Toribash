if (Tooltip == nil) then
	local bgColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR)
	bgColor[4] = 0.6

	---Advanced tooltip manager class
	---
	---**Ver 2.0**
	---* All global variables used by tooltip are now fields of Tooltip class
	---* Mobile controls on joint hold
	---@class Tooltip
	---@field Globalid integer Globalid for UIElement display
	---@field GrabDisplayActive boolean Whether grab display is currently active
	---@field IsActive boolean Whether tooltip is active and waiting for input
	---@field IsDisplayed boolean Whether tooltip is currently displayed on screen
	---@field HookName string Default tooltip hooks name
	---@field FractureColor Color
	---@field DismemberColor Color
	---@field BackgroundColor Color Tooltip UI background color
	---@field MouseHold boolean Whether user has current input - used for touch only
	---@field WaitForTouchInput boolean Whether we're waiting for touch input
	---@field TouchInputTargetPlayer integer Touch input targeted player id
	---@field TouchInputTargetJoint integer Touch input targeted joint id
	---@field TouchInputPosition table Touch position for the last touch control wheel trigger
	Tooltip = {
		Globalid = 1010,
		GrabDisplayActive = false,
		IsActive = false,
		IsDisplayed = false,
		HookName = "tbSystemTooltip",
		FractureColor = { 0.44, 0.41, 1, 1 },
		DismemberColor = { 1, 0, 0, 1 },
		BackgroundColor = table.clone(bgColor),
		MouseHold = false,
		WaitForTouchInput = false,
		TouchInputTargetPlayer = -1,
		TouchInputTargetJoint = -1,
		TouchInputPosition = nil,
		version = 2,
		__index = {}
	}
	setmetatable({}, Tooltip)
	Tooltip.HolderElement = UIElement:new({
		globalid = Tooltip.Globalid,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	Tooltip.HolderElement:addCustomDisplay(true, function() end)
end

---Exits the Tooltip and destroys all related UIElements
function Tooltip:quit()
	Tooltip.IsActive = false
	remove_hooks(Tooltip.HookName)
	Tooltip:destroy()
end

---Destroys all related UIElements
function Tooltip:destroy()
	Tooltip.HolderElement:kill(true)
	--[[local destroyed = false
	while (not destroyed) do
		destroyed = true
		for _,v in pairs(UIElementManager) do
			if (v.globalid == Tooltip.Globalid) then
				local topParent = v
				while (topParent and topParent.parent) do
					topParent = topParent.parent;
				end
				topParent:kill()
				destroyed = false
				break
			end
		end
	end]]
end

---Initializes Tooltip hooks and enables the module
function Tooltip:create()
	add_hook("joint_select", Tooltip.HookName, function(player, joint)
			Tooltip:showTooltipJoint(player, joint)
			--if (PLATFORM == "ANDROID" or PLATFORM == "IPHONEOS") then
				Tooltip:showTouchControls(player, joint)
			--end
		end)
	add_hook("body_select", Tooltip.HookName, function(player, body)
			Tooltip:showTooltipBody(player, body)
		end)
	--if (PLATFORM == "ANDROID" or PLATFORM == "IPHONEOS") then
		add_hook("mouse_button_down", Tooltip.HookName, function()
				Tooltip.MouseHold = true
			end)
		add_hook("mouse_button_up", Tooltip.HookName, function()
				Tooltip:setTouchJointState()
				Tooltip.MouseHold = false
			end)
	--end
	Tooltip.IsActive = true
end

---Reloads the Tooltip by exiting it and initializing again
function Tooltip:reload()
	Tooltip:quit()
	Tooltip:create()
end

---Displays Tooltip for a bodypart at current cursor position
---@param player integer Player id
---@param body integer Body id
function Tooltip:showTooltipBody(player, body)
	Tooltip.GrabDisplayActive = false
	if (get_option("tooltip") == 0) then
		Tooltip:quit()
		return
	end

	Tooltip:destroy()
	local worldstate = get_world_state()
	if (worldstate.replay_mode == 1) then
		return
	end
	if (body > -1 and body < 21) then
		local bodyInfo = get_body_info(player, body)
		bodyInfo.name = bodyInfo.name:gsub("^R_", "RIGHT "):gsub("^L_", "LEFT ")

		local height = (body == 11 or body == 12) and 70 or 40
		local width = get_string_length(bodyInfo.name, FONTS.MEDIUM) + 20
		width = width < 200 and 200 or width
		local heightMod = (body == 11 or body == 12) and 3 or 2

		local tbTooltip = Tooltip.HolderElement:addChild({
			pos = { MOUSE_X + 15, MOUSE_Y - 15 },
			size = { width, height }
		})
		tbTooltip.killAction = function() Tooltip.IsDisplayed = false end
		Tooltip.IsDisplayed = true

		local frame = worldstate.match_frame
		tbTooltip:addCustomDisplay(true, function()
				local ws = get_world_state()
				if (ws.replay_mode == 1 or ws.match_frame ~= frame or TB_MENU_MAIN_ISOPEN == 1 or ws.selected_player < 0) then
					Tooltip:destroy()
					return
				end
				tbTooltip:moveTo(MOUSE_X + 15, MOUSE_Y - 15)
				if (tbTooltip.pos.x + tbTooltip.size.w > WIN_W - 10) then
					tbTooltip:moveTo(WIN_W - 10 - tbTooltip.size.w)
				end
				if (tbTooltip.pos.y + tbTooltip.size.h > WIN_H - 10) then
					tbTooltip:moveTo(nil, WIN_H - 10 - tbTooltip.size.h)
				end
			end)
		if (tbTooltip.pos.x + tbTooltip.size.w > WIN_W - 10) then
			tbTooltip:moveTo(WIN_W - 10 - tbTooltip.size.w)
		end
		if (tbTooltip.pos.y + tbTooltip.size.h > WIN_H - 10) then
			tbTooltip:moveTo(nil, WIN_H - 10 - tbTooltip.size.h)
		end

		local tbTooltipOutline = UIElement:new({
			parent = tbTooltip,
			pos = { 0, 0 },
			size = { tbTooltip.size.w, tbTooltip.size.h },
			bgColor = { 1, 1, 1, 0.4 },
			shapeType = ROUNDED,
			rounded = 4
		})
		local tbTooltipView = UIElement:new({
			parent = tbTooltipOutline,
			pos = { 1, 1 },
			size = { tbTooltipOutline.size.w - 2, tbTooltipOutline.size.h - 2 },
			bgColor = Tooltip.BackgroundColor,
			shapeType = tbTooltipOutline.shapeType,
			rounded = tbTooltipOutline.rounded
		})
		local jointTooltipName = UIElement:new({
			parent = tbTooltipView,
			pos = { 10, 5 },
			size = { tbTooltipView.size.w - 20, tbTooltipView.size.h / heightMod * 2 - 10 }
		})
		jointTooltipName:addAdaptedText(true, bodyInfo.name, nil, nil, nil, LEFTMID)

		if (body == 11 or body == 12) then
			Tooltip.GrabDisplayActive = true
			local jointTooltipState = UIElement:new({
				parent = tbTooltipView,
				pos = { tbTooltipView.size.h / 3 + 10, jointTooltipName.shift.y + jointTooltipName.size.h },
				size = { tbTooltipView.size.w - tbTooltipView.size.h / 3 - 25, tbTooltipView.size.h / 3 - 5 }
			})
			local function drawGrabState(state)
				set_color(0.9, 0.9, 0.9, 1)
				if (state == 0) then
					draw_quad(tbTooltipView.pos.x + 10, jointTooltipState.pos.y, tbTooltipView.size.h / 3 - 5, tbTooltipView.size.h / 3 - 5)
				else
					draw_quad(tbTooltipView.pos.x + 10, jointTooltipState.pos.y + tbTooltip.size.h / 12, tbTooltipView.size.h / 3 - 5, tbTooltipView.size.h / 9)
					set_color(0, 1, 0, 1)
					draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 6 * 5, jointTooltipState.pos.y + jointTooltipState.size.h / 3 * 2, 0, jointTooltipState.size.h / 3, 500, 1, 0, 360, 1)
				end
			end

			jointTooltipState:addCustomDisplay(true, function()
					local grab = get_grip_info(player, body)
					drawGrabState(grab)
					jointTooltipState:uiText(grab == 0 and "UNGRABBING" or "GRABBING", nil, nil, 4, LEFTMID, 0.7)
				end)
		end
	end
end

---Displays Tooltip for a joint at current cursor position
---@param player integer Player id
---@param joint integer Joint id
function Tooltip:showTooltipJoint(player, joint)
	if (Tooltip.GrabDisplayActive) then
		return
	end
	if (get_option("tooltip") == 0) then
		Tooltip:quit()
		return
	end

	Tooltip:destroy()
	local worldstate = get_world_state()
	if (worldstate.replay_mode == 1) then
		return
	end
	if (joint > -1 and joint < 20) then
		local jointInfo = get_joint_info(player, joint)
		jointInfo.pos = {}
		jointInfo.pos.x, jointInfo.pos.y, jointInfo.pos.z = get_joint_pos(player, joint)

		local width = get_string_length(jointInfo.name, FONTS.MEDIUM) + 20
		width = width < 200 and 200 or width

		local tbTooltip = Tooltip.HolderElement:addChild({
			pos = { MOUSE_X + 15, MOUSE_Y - 15 },
			size = { width, 70 }
		})
		tbTooltip.killAction = function() Tooltip.IsDisplayed = false end
		Tooltip.IsDisplayed = true

		local frame = worldstate.match_frame
		tbTooltip:addCustomDisplay(true, function()
				local ws = get_world_state()
				if (ws.replay_mode == 1 or ws.match_frame ~= frame or TB_MENU_MAIN_ISOPEN == 1 or ws.selected_player < 0) then
					Tooltip:destroy()
					return
				end
				tbTooltip:moveTo(MOUSE_X + 15, MOUSE_Y - 15)
				if (tbTooltip.pos.x + tbTooltip.size.w > WIN_W - 10) then
					tbTooltip:moveTo(WIN_W - 10 - tbTooltip.size.w)
				end
				if (tbTooltip.pos.y + tbTooltip.size.h > WIN_H - 10) then
					tbTooltip:moveTo(nil, WIN_H - 10 - tbTooltip.size.h)
				end
			end)
		if (tbTooltip.pos.x + tbTooltip.size.w > WIN_W - 10) then
			tbTooltip:moveTo(WIN_W - 10 - tbTooltip.size.w)
		end
		if (tbTooltip.pos.y + tbTooltip.size.h > WIN_H - 10) then
			tbTooltip:moveTo(nil, WIN_H - 10 - tbTooltip.size.h)
		end
		local tbTooltipOutline = UIElement:new({
			parent = tbTooltip,
			pos = { 0, 0 },
			size = { tbTooltip.size.w, tbTooltip.size.h },
			bgColor = { 1, 1, 1, 0.4 },
			shapeType = ROUNDED,
			rounded = 4
		})
		local tbTooltipView = UIElement:new({
			parent = tbTooltipOutline,
			pos = { 1, 1 },
			size = { tbTooltipOutline.size.w - 2, tbTooltipOutline.size.h - 2 },
			bgColor = Tooltip.BackgroundColor,
			shapeType = tbTooltipOutline.shapeType,
			rounded = tbTooltipOutline.rounded
		})
		local jointTooltipName = UIElement:new({
			parent = tbTooltipView,
			pos = { 10, 5 },
			size = { tbTooltipView.size.w - 20, tbTooltipView.size.h / 3 * 2 - 10 }
		})
		jointTooltipName:addAdaptedText(true, jointInfo.name, nil, nil, nil, LEFTMID)

		local jointTooltipState = UIElement:new({
			parent = tbTooltipView,
			pos = { tbTooltipView.size.h / 3 + 10, jointTooltipName.shift.y + jointTooltipName.size.h },
			size = { tbTooltipView.size.w - tbTooltipView.size.h / 3 - 25, tbTooltipView.size.h / 3 - 5 }
		})
		local function drawDismembered()
			set_color(unpack(Tooltip.DismemberColor))
			draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 2, jointTooltipState.pos.y + jointTooltipState.size.h / 2, 0, jointTooltipState.size.h / 2, 500, 1, 0, 360, 0)
		end
		local function drawFractured()
			set_color(unpack(Tooltip.FractureColor))
			draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 2, jointTooltipState.pos.y + jointTooltipState.size.h / 2, 0, jointTooltipState.size.h / 2, 500, 1, 0, 360, 0)
		end
		local jointColors = get_joint_color(player, joint)
		if (not jointColors.joint) then
			return
		end

		local forceColor = get_color_info(jointColors.joint.force)
		forceColor = { forceColor.r, forceColor.g, forceColor.b, 1 }
		local relaxColor = get_color_info(jointColors.joint.relax)
		relaxColor = { relaxColor.r, relaxColor.g, relaxColor.b, 1 }

		local function drawJointState(state)
			if (state ~= 3) then
				set_color(unpack(relaxColor))
				draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 2, jointTooltipState.pos.y + jointTooltipState.size.h / 2, 0, jointTooltipState.size.h / 3, 500, 1, 0, 360, 0)
				if (state == 4) then
					return
				end
			end
			local rotation = 0
			local scale = 360
			if (state == 1) then
				rotation = 40
				scale = 180
			elseif (state == 2) then
				rotation = 220
				scale = 180
			end
			set_color(unpack(forceColor))
			draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 2, jointTooltipState.pos.y + jointTooltipState.size.h / 2, 0, jointTooltipState.size.h / 2 - 0.5, 500, 1, rotation, scale, 0)
		end
		jointTooltipState:addCustomDisplay(true, function()
				-- Getting full joint state
				local dismembered = get_joint_dismember(player, joint)
				if (dismembered) then
					drawDismembered()
					jointTooltipState:uiText("DISMEMBERED", nil, nil, 4, LEFTMID, 0.7, nil, 0.2, nil, UICOLORRED)
					return
				end
				local fractured = get_joint_fracture(player, joint)
				if (fractured) then
					drawFractured()
					jointTooltipState:uiText("FRACTURED", nil, nil, 4, LEFTMID, 0.7, nil, 0.2, nil, UICOLORBLUE)
					return
				end
				local jInfo = get_joint_info(player, joint)
				drawJointState(jInfo.state)
				jointTooltipState:uiText(jInfo.screen_state, nil, nil, 4, LEFTMID, 0.7)
			end)
	end
end

---Displays touch controls wheel
---@param player integer Player id
---@param joint integer Joint id
function Tooltip:showTouchControls(player, joint)
	if (Tooltip.GrabDisplayActive or joint < 0 or joint >= 20) then
		return
	end
	disable_mouse_camera_movement()

	local jointPos = { get_joint_screen_pos(player, joint) }
	Tooltip.TouchInputPosition = {
		x = jointPos[1],
		y = jointPos[2]
	}
	local touchControlsHolder = Tooltip.HolderElement:addChild({
		pos = { jointPos[1] - 75, jointPos[2] - 75 },
		size = { 150, 150 }
	})
	local touchControlsVisual = touchControlsHolder:addChild({
		pos = { 74, 74 },
		size = { 2, 2 },
		bgColor = UICOLORWHITE
	})
	touchControlsHolder.pressTimer = os.clock()
	local startRad, animRad = math.pi / 3, math.pi / 20
	touchControlsHolder:addCustomDisplay(function()
			if (not Tooltip.MouseHold) then
				if (touchControlsVisual:isDisplayed()) then
					touchControlsVisual:hide()
				end
				return
			end
			if (not touchControlsVisual:isDisplayed()) then
				touchControlsHolder.pressTimer = os.clock()
				touchControlsVisual:show()
			end
			if (touchControlsVisual.size.w == touchControlsHolder.size.w) then
				Tooltip.WaitForTouchInput = true
				Tooltip.TouchInputTargetPlayer = player
				Tooltip.TouchInputTargetJoint = joint
				return
			end
			if (os.clock() - touchControlsHolder.pressTimer < 0.2) then
				return
			end

			local animModifier = math.sin(startRad)
			startRad = startRad + animRad
			touchControlsVisual.size.w = math.floor(math.min(touchControlsHolder.size.w, touchControlsVisual.size.w + 20 * animModifier))
			touchControlsVisual.size.h = touchControlsVisual.size.w
			local moveTarget = math.floor((touchControlsHolder.size.w - touchControlsVisual.size.w) / 2)
			touchControlsVisual:moveTo(moveTarget, moveTarget)
		end)

	touchControlsVisual:addCustomDisplay(true, function()
			set_color(255, 255, 255, 1)
			local centerPoint = {
				x = touchControlsHolder.pos.x + touchControlsHolder.size.w / 2,
				y = touchControlsHolder.pos.y + touchControlsHolder.size.h / 2
			}
			local ringSize = touchControlsVisual.size.w / 2
			local ringStartSize = ringSize * 0.7
			draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 10, 1, 50, 80, 1) -- right
			draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 10, 1, 140, 80, 1) -- top
			draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 10, 1, 230, 80, 1) -- left
			draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 10, 1, 320, 80, 1) -- bottom
		end)
end

---Sets the joint state based on touch input wheel
function Tooltip:setTouchJointState()
	if (Tooltip.TouchInputTargetPlayer > -1 and Tooltip.TouchInputTargetJoint > -1 and Tooltip.TouchInputPosition) then
		local mouseDelta = {
			x = MOUSE_X - Tooltip.TouchInputPosition.x,
			y = MOUSE_Y - Tooltip.TouchInputPosition.y
		}
		local mouseDeltaNormalized = {
			x = math.min(math.abs(mouseDelta.x / mouseDelta.y), 1) * (mouseDelta.x / math.abs(mouseDelta.x)),
			y = math.min(math.abs(mouseDelta.y / mouseDelta.x), 1) * (mouseDelta.y / math.abs(mouseDelta.y))
		}
		if (math.abs(mouseDeltaNormalized.x) > math.abs(mouseDeltaNormalized.y)) then
			if (mouseDeltaNormalized.x > 0) then
				set_joint_state(Tooltip.TouchInputTargetPlayer, Tooltip.TouchInputTargetJoint, 1)
			else
				set_joint_state(Tooltip.TouchInputTargetPlayer, Tooltip.TouchInputTargetJoint, 2)
			end
		else
			if (mouseDeltaNormalized.y > 0) then
				set_joint_state(Tooltip.TouchInputTargetPlayer, Tooltip.TouchInputTargetJoint, 3)
			else
				set_joint_state(Tooltip.TouchInputTargetPlayer, Tooltip.TouchInputTargetJoint, 4)
			end
		end
	end
	Tooltip.TouchInputTargetPlayer = -1
	Tooltip.TouchInputTargetJoint = -1
	Tooltip.TouchInputPosition = nil
	enable_mouse_camera_movement()
end
