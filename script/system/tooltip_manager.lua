require("toriui.uielement")
require("toriui.uitween")

if (Tooltip == nil) then
	local bgColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR)
	bgColor[4] = 0.6

	---Advanced tooltip manager class
	---
	---**Ver 2.0**
	---* All global variables used by tooltip are now fields of Tooltip class
	---* Mobile controls on joint hold
	---* Tooltip hooks are now never unloaded, use tooltip option value to detect whether we should display tooltip ui
	---@class Tooltip
	---@field Globalid integer Globalid for UIElement display
	---@field GrabDisplayActive boolean Whether grab display is currently active
	---@field IsActive boolean Whether tooltip is active and waiting for input
	---@field IsDisplayed boolean Whether tooltip is currently displayed on screen
	---@field HookName string Default tooltip hooks name
	---@field FractureColor Color
	---@field DismemberColor Color
	---@field BackgroundColor Color Tooltip UI background color
	---@field WaitForTouchInput boolean Whether we're waiting for touch input
	---@field TouchInputTargetPlayer integer Touch input targeted player id
	---@field TouchInputTargetJoint PlayerJoint Touch input targeted joint id
	---@field TouchInputPosition table Touch position for the last touch control wheel trigger
	---@field TouchInputDelay number Delay in seconds before touch control ring will start appearing
	---@field TouchInputGrowDuration number Duration in seconds for touch control ring to finish animation
	Tooltip = {
		Globalid = 1010,
		GrabDisplayActive = false,
		IsActive = false,
		IsDisplayed = false,
		HookName = "tbSystemTooltip",
		FractureColor = { 0.44, 0.41, 1, 1 },
		DismemberColor = { 1, 0, 0, 1 },
		BackgroundColor = table.clone(bgColor),
		WaitForTouchInput = false,
		TouchInputTargetPlayer = -1,
		---@diagnostic disable-next-line: assign-type-mismatch
		TouchInputTargetJoint = -1,
		TouchInputDelay = 0.1,
		TouchInputGrowDuration = 0.1,
		version = 5.60
	}
	Tooltip.__index = Tooltip
	setmetatable({}, Tooltip)

	Tooltip.HolderElement = UIElement:new({
		globalid = Tooltip.Globalid,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	Tooltip.HolderElement:addCustomDisplay(true, function() end)
end

---Calls Destroy() method and marks Tooltip class inactive
function Tooltip.Quit()
	Tooltip.Destroy()
	Tooltip.IsActive = false
end

---Destroys Tooltip elements
function Tooltip.Destroy()
	Tooltip.HolderElement:kill(true)
end

---Unsets touch target player and joint
function Tooltip.TouchDeselect()
	Tooltip.TouchInputTargetPlayer = -1
	Tooltip.TouchInputTargetJoint = -1
end

---Initializes Tooltip hooks and enables the module
function Tooltip.Init()
	Tooltip.TouchDeselect()

	add_hook("joint_select", Tooltip.HookName, function(player, joint)
			if (players_accept_input() == false) then return end
			local discard = Tooltip:showTooltipJoint(player, joint)
			if (is_mobile()) then
				return discard
			end
		end)
	add_hook("body_select", Tooltip.HookName, function(player, body)
			if (players_accept_input() == false) then return end
			if (get_option("tooltip") == 1 and Tooltip.IsActive) then
				Tooltip:showTooltipBody(player, body)
			end
		end)
	if (is_mobile()) then
		add_hook("mouse_button_down", Tooltip.HookName, function()
				if (players_accept_input() == false) then return end
				Tooltip:showTouchControls()
			end)
		add_hook("mouse_button_up", Tooltip.HookName, function()
				if (players_accept_input() == false) then return end
				Tooltip.Destroy()
				Tooltip:setTouchJointState()
			end)
		add_hook("exit_freeze", Tooltip.HookName, Tooltip.Destroy)
	end
	Tooltip.IsActive = true
end

---Reloads the Tooltip by exiting it and initializing again
function Tooltip.Reload()
	Tooltip.Quit()
	Tooltip.Init()
end

---A uniform function to generate main tooltip element
---@param width integer
---@param height integer
---@param x integer
---@param y integer
---@return UIElement
function Tooltip:spawnTooltipMain(frame, width, height, x, y)
	local tbTooltip = Tooltip.HolderElement:addChild({
		pos = { x + 15, y - 5 },
		size = { width, height }
	})
	tbTooltip.killAction = function() Tooltip.IsDisplayed = false end
	Tooltip.IsDisplayed = true

	if (tbTooltip.pos.x + tbTooltip.size.w > WIN_W - 10) then
		tbTooltip:moveTo(WIN_W - 10 - tbTooltip.size.w)
	end
	if (tbTooltip.pos.y + tbTooltip.size.h > WIN_H - 10) then
		tbTooltip:moveTo(nil, WIN_H - 10 - tbTooltip.size.h)
	end

	tbTooltip:addCustomDisplay(true, function()
			local ws = get_world_state()
			if (ws.replay_mode == 1 or ws.match_frame ~= frame or TB_MENU_MAIN_ISOPEN == 1 or ws.selected_player < 0) then
				Tooltip.Destroy()
				return
			end
		end)

	return tbTooltip
end

---Displays Tooltip for a bodypart at current cursor position
---@param player integer Player id
---@param body integer Body id
function Tooltip:showTooltipBody(player, body)
	Tooltip.TouchInputTargetPlayer = player
	Tooltip.TouchInputTargetJoint = -1
	Tooltip.GrabDisplayActive = false
	Tooltip.Destroy()

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

		local tbTooltip = Tooltip:spawnTooltipMain(worldstate.match_frame, width, height, get_body_screen_pos(player, body))
		local tbTooltipOutline = tbTooltip:addChild({
			bgColor = { 1, 1, 1, 0.4 },
			shapeType = ROUNDED,
			rounded = 4
		})
		local tbTooltipView = tbTooltipOutline:addChild({
			shift = { 1, 1 },
			bgColor = Tooltip.BackgroundColor
		}, true)
		local jointTooltipName = tbTooltipView:addChild({
			pos = { 10, 5 },
			size = { tbTooltipView.size.w - 20, tbTooltipView.size.h / heightMod * 2 - 10 }
		})
		jointTooltipName:addAdaptedText(true, bodyInfo.name, nil, nil, nil, LEFTMID)

		if (body == 11 or body == 12) then
			Tooltip.GrabDisplayActive = true
			local jointTooltipState = tbTooltipView:addChild({
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
---@return integer
function Tooltip:showTooltipJoint(player, joint)
	Tooltip.TouchInputTargetPlayer = player
	Tooltip.TouchInputTargetJoint = joint

	if (Tooltip.GrabDisplayActive) then
		return 0
	end
	if (Tooltip.TouchInputPosition ~= nil) then
		return 1
	end
	Tooltip.Destroy()

	local worldstate = get_world_state()
	if (worldstate.replay_mode == 1) then
		return 0
	end
	if (joint > -1 and joint < 20) then
		Tooltip.TouchInputTargetPlayer = player
		Tooltip.TouchInputTargetJoint = joint

		if (get_option("tooltip") == 0 or not Tooltip.IsActive) then
			return 0
		end

		local jointInfo = get_joint_info(player, joint)
		local width = get_string_length(jointInfo.name, FONTS.MEDIUM) + 20
		width = width < 200 and 200 or width

		local tbTooltip = Tooltip:spawnTooltipMain(worldstate.match_frame, width, 70, get_joint_screen_pos(player, joint))
		local tbTooltipOutline = tbTooltip:addChild({
			bgColor = { 1, 1, 1, 0.4 },
			shapeType = ROUNDED,
			rounded = 4
		})
		local tbTooltipView = tbTooltipOutline:addChild({
			shift = { 1, 1 },
			bgColor = Tooltip.BackgroundColor
		}, true)
		local jointTooltipName = tbTooltipView:addChild({
			pos = { 10, 5 },
			size = { tbTooltipView.size.w - 20, tbTooltipView.size.h / 3 * 2 - 10 }
		})
		jointTooltipName:addAdaptedText(true, jointInfo.name, nil, nil, nil, LEFTMID)

		local jointTooltipState = tbTooltipView:addChild({
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

		local force, relax = get_joint_colors(player, joint)
		if (force == 0) then
			force = 23
		end
		if (relax == 0) then
			relax = 21
		end
		local forceColor = get_color_rgba(force)
		local relaxColor = get_color_rgba(relax)

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
		return 1
	end

	return 0
end

---Displays touch controls wheel
function Tooltip:showTouchControls()
	if (get_world_state().replay_mode == 1) then
		Tooltip.TouchDeselect()
	end
	if (Tooltip.GrabDisplayActive or Tooltip.TouchInputTargetPlayer < 0 or Tooltip.TouchInputTargetJoint < 0 or Tooltip.TouchInputTargetJoint >= 20) then
		return
	end
	Tooltip.Destroy()

	---@diagnostic disable-next-line: param-type-mismatch
	local jointPos = { get_joint_screen_pos(Tooltip.TouchInputTargetPlayer, Tooltip.TouchInputTargetJoint) }
	Tooltip.TouchInputPosition = {
		x = jointPos[1],
		y = jointPos[2]
	}
	local touchControlsHolder = Tooltip.HolderElement:addChild({
		pos = { jointPos[1] - 75, jointPos[2] - 75 },
		size = { 150, 150 }
	})
	disable_mouse_camera_movement()
	touchControlsHolder.killAction = enable_mouse_camera_movement
	local touchControlsVisual = touchControlsHolder:addChild({
		pos = { 74, 74 },
		size = { 2, 2 },
		bgColor = UICOLORWHITE
	})

	local jointStateTextColor = { 0, 0, 0, 0 }
	local jointStateShadowColor = { 255, 255, 255, 0 }
	local touchControlsTopTitle = touchControlsHolder:addChild({
		pos = { -touchControlsHolder.size.w - 150, -touchControlsHolder.size.h - 50 },
		size = { 300 + touchControlsHolder.size.w, 30 }
	})
	---@diagnostic disable-next-line: param-type-mismatch
	touchControlsTopTitle:addAdaptedText(true, get_joint_state_name(Tooltip.TouchInputTargetJoint, 3), nil, nil, FONTS.BIG, CENTERBOT, 0.6, nil, nil, 2, jointStateTextColor, jointStateShadowColor);

	local touchControlsBotTitle = touchControlsHolder:addChild({
		pos = { -touchControlsHolder.size.w - 150, touchControlsHolder.size.h + 20 },
		size = { 300 + touchControlsHolder.size.w, 30 }
	})
	---@diagnostic disable-next-line: param-type-mismatch
	touchControlsBotTitle:addAdaptedText(true, get_joint_state_name(Tooltip.TouchInputTargetJoint, 4), nil, nil, FONTS.BIG, CENTER, 0.6, nil, nil, 2, jointStateTextColor, jointStateShadowColor);

	local touchControlsRightTitle = touchControlsHolder:addChild({
		pos = { touchControlsHolder.size.w + 20, touchControlsHolder.size.h / 2 - 15 },
		size = { 250, 30 }
	})
	---@diagnostic disable-next-line: param-type-mismatch
	touchControlsRightTitle:addAdaptedText(true, get_joint_state_name(Tooltip.TouchInputTargetJoint, 1), nil, nil, FONTS.BIG, LEFTMID, 0.6, nil, nil, 2, jointStateTextColor, jointStateShadowColor);

	local touchControlsLeftTitle = touchControlsHolder:addChild({
		pos = { -touchControlsHolder.size.w - 270, touchControlsHolder.size.h / 2 - 15 },
		size = { 250, 30 }
	})
	---@diagnostic disable-next-line: param-type-mismatch
	touchControlsLeftTitle:addAdaptedText(true, get_joint_state_name(Tooltip.TouchInputTargetJoint, 2), nil, nil, FONTS.BIG, RIGHTMID, 0.6, nil, nil, 2, jointStateTextColor, jointStateShadowColor);

	touchControlsHolder.pressTimer = UIElement.clock
	touchControlsHolder.firstPlay = true
	touchControlsHolder:addCustomDisplay(function()
			if (touchControlsVisual.size.w == touchControlsHolder.size.w) then
				Tooltip.WaitForTouchInput = true
				return
			end
			if (UIElement.clock - touchControlsHolder.pressTimer < Tooltip.TouchInputDelay) then
				return
			end
			if (touchControlsHolder.firstPlay) then
				touchControlsHolder.firstPlay = false
				play_haptics(0.2, HAPTICS.IMPACT)
			end

			local ratio = (UIElement.clock - touchControlsHolder.pressTimer - Tooltip.TouchInputDelay) / Tooltip.TouchInputGrowDuration
			local tweenRatio = UITween.EaseIn(ratio)
			touchControlsVisual.size.w = touchControlsHolder.size.w * tweenRatio
			touchControlsVisual.size.h = touchControlsVisual.size.w
			local moveTarget = math.floor((touchControlsHolder.size.w - touchControlsVisual.size.w) / 2)
			touchControlsVisual:moveTo(moveTarget, moveTarget)

			jointStateTextColor[4] = 0.7 * tweenRatio
			jointStateShadowColor[4] = 0.8 * tweenRatio
		end)

	---@diagnostic disable-next-line: param-type-mismatch
	local lastJointState = get_joint_info(Tooltip.TouchInputTargetPlayer, Tooltip.TouchInputTargetJoint).state
	local fallbackJointState = lastJointState
	touchControlsVisual:addCustomDisplay(true, function()
			local centerPoint = {
				x = touchControlsHolder.pos.x + touchControlsHolder.size.w / 2,
				y = touchControlsHolder.pos.y + touchControlsHolder.size.h / 2
			}

			local ringSize = touchControlsVisual.size.w / 2
			local ringStartSize = ringSize * 0.7
			set_color(0, 0, 0, 1)
			draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 10, 1, 50, 80, 0) -- right
			draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 10, 1, 140, 80, 0) -- top
			draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 10, 1, 230, 80, 0) -- left
			draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 10, 1, 320, 80, 0) -- bottom

			ringSize = ringSize - 1
			ringStartSize = ringStartSize + 1
			set_color(255, 255, 255, 1)
			draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 10, 1, 51, 78, 0) -- right
			draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 10, 1, 141, 78, 0) -- top
			draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 10, 1, 231, 78, 0) -- left
			draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 10, 1, 321, 78, 0) -- bottom

			local mouseDelta = Tooltip:getTouchMouseDelta()
			set_color(unpack(TB_MENU_DEFAULT_DARKER_COLOR))
			local targetJointState = lastJointState
			if (mouseDelta.x ~= 0 or mouseDelta.y ~= 0) then
				if (math.abs(mouseDelta.x) > math.abs(mouseDelta.y)) then
					if (mouseDelta.x > 0) then
						draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 10, 1, 45, 90, 0) -- right
						targetJointState = 1
					else
						draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 10, 1, 225, 90, 0) -- left
						targetJointState = 2
					end
				else
					if (mouseDelta.y > 0) then
						draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 10, 1, 315, 90, 0) -- bottom
						targetJointState = 4
					else
						draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 10, 1, 135, 90, 0) -- top
						targetJointState = 3
					end
				end
			else
				if (fallbackJointState == 1) then
					draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 10, 1, 45, 90, 0) -- right
				elseif (fallbackJointState == 2) then
					draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 10, 1, 225, 90, 0) -- left
				elseif (fallbackJointState == 3) then
					draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 10, 1, 135, 90, 0) -- top
				else
					draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 10, 1, 315, 90, 0) -- bottom
				end
				targetJointState = fallbackJointState
			end

			if (lastJointState ~= targetJointState) then
				play_haptics(0.6, HAPTICS.SELECTION)
				---@diagnostic disable-next-line: param-type-mismatch
				set_joint_state(Tooltip.TouchInputTargetPlayer, Tooltip.TouchInputTargetJoint, targetJointState, true)
				lastJointState = targetJointState
			end
		end)
end

---Returns normalized touch input delta
---@return Vector2
function Tooltip:getTouchMouseDelta()
	if (Tooltip.TouchInputPosition == nil) then
		return { x = 0, y = 0 }
	end

	local mouseDelta = {
		x = MOUSE_X - Tooltip.TouchInputPosition.x,
		y = MOUSE_Y - Tooltip.TouchInputPosition.y
	}
	-- We don't want to do anything if input was within "dead" zone
 	if (math.max(math.abs(mouseDelta.x), math.abs(mouseDelta.y)) < 50) then
		return { x = 0, y = 0 }
	end

	-- Now normalize the delta so we can do a simple check later
	local mouseDeltaNormalized = {
		x = math.min(math.abs(mouseDelta.x / mouseDelta.y), 1) * (mouseDelta.x / math.abs(mouseDelta.x)),
		y = math.min(math.abs(mouseDelta.y / mouseDelta.x), 1) * (mouseDelta.y / math.abs(mouseDelta.y))
	}
	return mouseDeltaNormalized
end

---Sets the joint state based on touch input wheel
function Tooltip:setTouchJointState()
	if (Tooltip.TouchInputTargetPlayer > -1 and Tooltip.TouchInputTargetJoint > -1) then
		if (Tooltip.TouchInputPosition and Tooltip.WaitForTouchInput) then
			--[[local mouseDeltaNormalized = Tooltip:getTouchMouseDelta()
			if (mouseDeltaNormalized.x ~= 0 or mouseDeltaNormalized.y ~= 0) then
				if (math.abs(mouseDeltaNormalized.x) > math.abs(mouseDeltaNormalized.y)) then
					if (mouseDeltaNormalized.x > 0) then
						-- Right
						set_joint_state(Tooltip.TouchInputTargetPlayer, Tooltip.TouchInputTargetJoint, 1, true)
					else
						-- Left
						set_joint_state(Tooltip.TouchInputTargetPlayer, Tooltip.TouchInputTargetJoint, 2, true)
					end
				else
					if (mouseDeltaNormalized.y > 0) then
						-- Top
						set_joint_state(Tooltip.TouchInputTargetPlayer, Tooltip.TouchInputTargetJoint, 4, true)
					else
						-- Bottom
						set_joint_state(Tooltip.TouchInputTargetPlayer, Tooltip.TouchInputTargetJoint, 3, true)
					end
				end
			end]]
		else
			Tooltip:toggleJointState(Tooltip.TouchInputTargetPlayer, Tooltip.TouchInputTargetJoint)
		end
	end

	Tooltip.TouchInputPosition = nil
	Tooltip.WaitForTouchInput = false
end

---Toggles joint state according to current game settings \
---*This is essentially a copy of the cpp code*
---@param player integer
---@param joint integer
function Tooltip:toggleJointState(player, joint)
	local targetJointState = nil
	local mousebuttons = get_option("mousebuttons")
	---@diagnostic disable-next-line: param-type-mismatch
	local jointState = get_joint_info(Tooltip.TouchInputTargetPlayer, Tooltip.TouchInputTargetJoint).state
	if (mousebuttons == 1) then
		if (get_shift_key_state() == 1) then
			targetJointState = (jointState - 1) % 4
		else
			targetJointState = jointState % 4 + 1
		end
	elseif (mousebuttons == 2) then
		targetJointState = jointState == 3 and 4 or 3
	else
		targetJointState = jointState == 1 and 2 or 1
	end

	set_joint_state(player, joint, targetJointState, true)
end

Tooltip.Init()
