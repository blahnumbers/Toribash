require("toriui.uielement")
require("toriui.uitween")

if (Tooltip == nil) then
	local bgColor = table.clone(TB_MENU_DEFAULT_DARKEST_COLOR)
	bgColor[4] = 0.6

	---Advanced tooltip manager class
	---
	---**Version 5.70**
	---* Use a cached WorldState value instead of additional direct calls to get_world_state()
	---
	---**Version 5.61**
	---* Added **TooltipInternal** class to use for fields we don't want exposed
	---* Added optional event callbacks for mobile controls
	---* Added function to disable mobile state wheel
	---* Added `IsTouchCommitted` field
	---* Set target touch player and joint on button down hook from world state info
	---
	---**Version 5.60**
	---* All global variables used by tooltip are now fields of Tooltip class
	---* Mobile controls on joint hold
	---* Tooltip hooks are now never unloaded, use tooltip option value to detect whether we should display tooltip ui
	---@class Tooltip
	---@field Globalid integer Globalid for UIElement display
	---@field GrabDisplayActive boolean Whether grab display is currently active
	---@field IsActive boolean Whether tooltip is active and waiting for input
	---@field IsDisplayed boolean Whether tooltip is currently displayed on screen
	---@field IsTouchCommitted boolean Whether touch input has been committed
	---@field HookName string Default tooltip hooks name
	---@field FractureColor Color
	---@field DismemberColor Color
	---@field BackgroundColor Color Tooltip UI background color
	---@field TouchInputDelay number Delay in seconds before touch control ring will start appearing
	---@field TouchInputGrowDuration number Duration in seconds for touch control ring to finish animation
	Tooltip = {
		Globalid = 1010,
		GrabDisplayActive = false,
		IsActive = false,
		IsDisplayed = false,
		IsTouchCommitted = true,
		HookName = "__tbTooltipManager",
		FractureColor = { 0.44, 0.41, 1, 1 },
		DismemberColor = { 1, 0, 0, 1 },
		BackgroundColor = table.clone(bgColor),
		TouchInputDelay = 0.1,
		TouchInputGrowDuration = 0.1,
		ver = 5.70
	}
	Tooltip.__index = Tooltip

	Tooltip.HolderElement = UIElement:new({
		globalid = Tooltip.Globalid,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
	Tooltip.HolderElement:addCustomDisplay(true, function() Tooltip.WorldState = UIElement.WorldState end)
end

---@alias TooltipJointNone
---| -1 NONE

---Internal helper class for **Tooltip manager**
---@class TooltipInternal
---@field WaitForTouchInput boolean Whether we're waiting for touch input
---@field TouchInputTargetPlayer integer Touch input targeted player id
---@field TouchInputTargetJoint PlayerJoint|TooltipJointNone Touch input targeted joint id
---@field TouchInputPosition table Touch position for the last touch control wheel trigger
---@field OnToggleWheelEvents function[] Optional callbacks executed on joint state wheel selection (mobile only)
---@field OnTapEvents function[] Optional callbacks executed on joint tap (mobile only)
local TooltipInternal = {
	WaitForTouchInput = false,
	TouchInputTargetPlayer = -1,
	TouchInputTargetJoint = -1,
	OnToggleWheelEvents = { },
	OnTapEvents = { },
	InputMode = is_mobile() and INPUT_TYPE.TOUCH or INPUT_TYPE.MOUSE
}

---Calls Destroy() method and marks Tooltip class inactive
function Tooltip.Quit()
	Tooltip.Destroy()
	Tooltip.IsActive = false
end

---Destroys Tooltip elements
function Tooltip.Destroy()
	Tooltip.HolderElement:kill(true)
end

function Tooltip.DestroyAndDeselect()
	Tooltip.GrabDisplayActive = false
	Tooltip.Destroy()
	Tooltip.TouchDeselect()
end

---Unsets touch target player and joint
function Tooltip.TouchDeselect()
	TooltipInternal.TouchInputTargetPlayer = -1
	TooltipInternal.TouchInputTargetJoint = -1
end

function Tooltip.EnableFocusCam()
	set_option("focuscam", tonumber(get_option("camerafocus")) or 0)
end

---Adds mobile toggle wheel function callback and associates it with a specified name
---@param name string
---@param func function
function Tooltip.AddOnToggleWheelEvent(name, func)
	TooltipInternal.OnToggleWheelEvents[name] = func
end

---Removes mobile wheel function callback with a corresponding name
---@param name string
function Tooltip.RemoveOnToggleWheelEvent(name)
	TooltipInternal.OnToggleWheelEvents[name] = nil
end

---Adds mobile tap function callback and associates it with a specified name
---@param name string
---@param func function
function Tooltip.AddOnTapEvent(name, func)
	TooltipInternal.OnTapEvents[name] = func
end

---Removes mobile tap function callback with a corresponding name
---@param name string
function Tooltip.RemoveOnTapEvent(name)
	TooltipInternal.OnTapEvents[name] = nil
end

---Initializes Tooltip hooks and enables the module
function Tooltip.Init()
	Tooltip.DestroyAndDeselect()

	remove_hooks(Tooltip.HookName)
	add_hook("joint_select", Tooltip.HookName, function(player, joint)
			if (STORE_VANILLA_PREVIEW) then return end
			local _, crush = pcall(function()
					if (is_mobile() or joint < 0 or player < 0) then
						return false
					end
					return get_joint_dismember(player, joint) or get_joint_fracture(player, joint)
				end)
			if (players_accept_input() == false and not crush) then return end
			local discard = Tooltip:showTooltipJoint(player, joint)
			if (is_mobile()) then
				Tooltip.EnableFocusCam()
				if (TooltipInternal.InputMode == INPUT_TYPE.TOUCH) then
					return discard
				end
			end
		end)
	add_hook("body_select", Tooltip.HookName, function(player, body)
			if (players_accept_input() == false or STORE_VANILLA_PREVIEW) then return end
			if (is_mobile()) then Tooltip.EnableFocusCam() end
			if (get_option("tooltip") == 1 and Tooltip.IsActive) then
				Tooltip:showTooltipBody(player, body)
			end
		end)
	if (is_mobile()) then
		add_hook("mouse_button_down", Tooltip.HookName, function(s)
				if (players_accept_input() == false or
					s ~= 1 or TooltipInternal.InputMode ~= INPUT_TYPE.TOUCH) then
						return
				end

				Tooltip.WorldState = get_world_state()
				TooltipInternal.TouchInputTargetPlayer = Tooltip.WorldState.selected_player
				TooltipInternal.TouchInputTargetJoint = Tooltip.WorldState.selected_joint
				Tooltip:showTouchControls()
			end)
		add_hook("mouse_button_up", Tooltip.HookName, function()
				if (players_accept_input() == false or
					TooltipInternal.InputMode ~= INPUT_TYPE.TOUCH) then
						return
				end

				Tooltip.SetTouchJointState()
			end)
		add_hook("input_type_change", Tooltip.HookName, function(type)
				TooltipInternal.InputMode = type
			end)
	end

	add_hook("enter_frame", Tooltip.HookName, Tooltip.DestroyAndDeselect)
	add_hook("exit_freeze", Tooltip.HookName, Tooltip.DestroyAndDeselect)
	add_hook("leave_game", Tooltip.HookName, Tooltip.DestroyAndDeselect)
	add_hook("new_game", Tooltip.HookName, Tooltip.DestroyAndDeselect)
	add_hook("player_select", Tooltip.HookName, function()
			Tooltip.DestroyAndDeselect()
			if (is_mobile()) then
				Tooltip.EnableFocusCam()
			end
		end)

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
	local tbTooltip = self.HolderElement:addChild({
		pos = { x + 15, y - 5 },
		size = { width, height }
	})
	tbTooltip.killAction = function() self.IsDisplayed = false end
	self.IsDisplayed = true

	if (tbTooltip.pos.x + tbTooltip.size.w > WIN_W - 10) then
		tbTooltip:moveTo(WIN_W - 10 - tbTooltip.size.w)
	end
	if (tbTooltip.pos.y + tbTooltip.size.h > WIN_H - 10) then
		tbTooltip:moveTo(nil, WIN_H - 10 - tbTooltip.size.h)
	end

	tbTooltip:addCustomDisplay(true, function()
			if (self.WorldState.replay_mode == 1 or
				self.WorldState.match_frame ~= frame or
				self.WorldState.selected_player < 0 or
				TB_MENU_MAIN_ISOPEN == 1) then
				self.Destroy()
				return
			end
		end)

	return tbTooltip
end

---Displays Tooltip for a bodypart at current cursor position
---@param player integer Player id
---@param body integer Body id
function Tooltip:showTooltipBody(player, body)
	self.DestroyAndDeselect()

	self.WorldState = get_world_state()
	if (self.WorldState.replay_mode == 1 or body < 0 or body >= 21) then
		return
	end

	local bodyInfo = get_body_info(player, body)
	bodyInfo.name = bodyInfo.name:gsub("^R_", "RIGHT "):gsub("^L_", "LEFT ")

	local height = (body == 11 or body == 12) and 70 or 40
	local width = get_string_length(bodyInfo.name, FONTS.MEDIUM) + 20
	width = width < 200 and 200 or width
	local heightMod = (body == 11 or body == 12) and 3 or 2

	local tbTooltip = self:spawnTooltipMain(self.WorldState.match_frame, width, height, get_body_screen_pos(player, body))
	local tbTooltipOutline = tbTooltip:addChild({
		bgColor = { 1, 1, 1, 0.4 },
		shapeType = ROUNDED,
		rounded = 4
	})
	local tbTooltipView = tbTooltipOutline:addChild({
		shift = { 1, 1 },
		bgColor = self.BackgroundColor
	}, true)
	local jointTooltipName = tbTooltipView:addChild({
		pos = { 10, 5 },
		size = { tbTooltipView.size.w - 20, tbTooltipView.size.h / heightMod * 2 - 10 }
	})
	jointTooltipName:addAdaptedText(true, bodyInfo.name, nil, nil, nil, LEFTMID)

	if (body == 11 or body == 12) then
		self.GrabDisplayActive = true
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
				draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 6 * 5, jointTooltipState.pos.y + jointTooltipState.size.h / 3 * 2, 0, jointTooltipState.size.h / 3, 20, 1, 0, 360, 1)
			end
		end

		jointTooltipState:addCustomDisplay(true, function()
				local grab = get_grip_info(player, body)
				drawGrabState(grab)
				jointTooltipState:uiText(grab == 0 and "UNGRABBING" or "GRABBING", nil, nil, 4, LEFTMID, 0.7)
			end)
	end
end

---Displays Tooltip for a joint at current cursor position
---@param player integer Player id
---@param joint integer Joint id
---@return integer
function Tooltip:showTooltipJoint(player, joint)
	if (self.GrabDisplayActive) then
		return 0
	end
	if (TooltipInternal.TouchInputPosition ~= nil) then
		return 1
	end
	self.Destroy()

	self.WorldState = get_world_state()
	if (self.WorldState.replay_mode == 1 or
		joint < 0 or joint >= 20 or
		not self.IsActive or
		get_option("tooltip") == 0) then
		return 0
	end

	local jointInfo = get_joint_info(player, joint)
	local width = get_string_length(jointInfo.name, FONTS.MEDIUM) + 20
	width = width < 200 and 200 or width

	local tbTooltip = self:spawnTooltipMain(self.WorldState.match_frame, width, 70, get_joint_screen_pos(player, joint))
	local tbTooltipOutline = tbTooltip:addChild({
		bgColor = { 1, 1, 1, 0.4 },
		shapeType = ROUNDED,
		rounded = 4
	})
	local tbTooltipView = tbTooltipOutline:addChild({
		shift = { 1, 1 },
		bgColor = self.BackgroundColor
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
		set_color(self.DismemberColor[1], self.DismemberColor[2], self.DismemberColor[3], self.DismemberColor[4])
		draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 2, jointTooltipState.pos.y + jointTooltipState.size.h / 2, 0, jointTooltipState.size.h / 2, 20, 1, 0, 360, 0)
	end
	local function drawFractured()
		set_color(self.FractureColor[1], self.FractureColor[2], self.FractureColor[3], self.FractureColor[4])
		draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 2, jointTooltipState.pos.y + jointTooltipState.size.h / 2, 0, jointTooltipState.size.h / 2, 20, 1, 0, 360, 0)
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
			set_color(relaxColor[1], relaxColor[2], relaxColor[3], relaxColor[4])
			draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 2, jointTooltipState.pos.y + jointTooltipState.size.h / 2, 0, jointTooltipState.size.h / 3, 20, 1, 0, 360, 0)
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
		set_color(forceColor[1], forceColor[2], forceColor[3], forceColor[4])
		draw_disk(tbTooltipView.pos.x + 10 + jointTooltipState.size.h / 2, jointTooltipState.pos.y + jointTooltipState.size.h / 2, 0, jointTooltipState.size.h / 2 - 0.5, 20, 1, rotation, scale, 0)
	end
	local _, crush = pcall(function() return get_joint_dismember(player, joint) end)
	if (crush) then
		local crushText = utf8.upper(TB_MENU_LOCALIZED.TOOLTIPDISMEMBERED)
		jointTooltipState:addCustomDisplay(true, function()
			drawDismembered()
			jointTooltipState:uiText(crushText, nil, nil, 4, LEFTMID, 0.7, nil, 0.2, nil, UICOLORRED)
		end)
		return 1
	end
	_, crush = pcall(function() return get_joint_fracture(player, joint) end)
	if (crush) then
		local crushText = utf8.upper(TB_MENU_LOCALIZED.TOOLTIPFRACTURED)
		jointTooltipState:addCustomDisplay(true, function()
			drawFractured()
			jointTooltipState:uiText(crushText, nil, nil, 4, LEFTMID, 0.7, nil, 0.2, nil, UICOLORRED)
		end)
		return 1
	end
	jointTooltipState:addCustomDisplay(true, function()
			local jInfo = get_joint_info(player, joint)
			drawJointState(jInfo.state)
			jointTooltipState:uiText(jInfo.screen_state, nil, nil, 4, LEFTMID, 0.7)
		end)
	return 1
end

---Displays touch controls wheel
function Tooltip:showTouchControls()
	if (self.WorldState.replay_mode == 1) then
		self.TouchDeselect()
	end
	if (self.GrabDisplayActive or TooltipInternal.TouchInputTargetPlayer < 0 or TooltipInternal.TouchInputTargetJoint < 0 or TooltipInternal.TouchInputTargetJoint >= 20) then
		return
	end
	self.Destroy()
	self.IsTouchCommitted = false

	local wheelMode = get_option("tooltipmode")
	if (wheelMode == 3) then
		self.SetTouchJointState()
		return
	end

	---@diagnostic disable-next-line: param-type-mismatch
	local jointPos = { get_joint_screen_pos(TooltipInternal.TouchInputTargetPlayer, TooltipInternal.TouchInputTargetJoint) }
	TooltipInternal.TouchInputPosition = {
		x = jointPos[1],
		y = jointPos[2]
	}
	local touchControlsHolder = self.HolderElement:addChild({
		pos = { jointPos[1] - 75, jointPos[2] - 75 },
		size = { 150, 150 }
	})
	add_hook("pre_draw", "tooltipTouchPositionFixer", function()
			if (TooltipInternal.TouchInputTargetPlayer == -1 or TooltipInternal.TouchInputTargetJoint == -1) then return end
			pcall(function()
				---@diagnostic disable-next-line: param-type-mismatch
				TooltipInternal.TouchInputPosition.x, TooltipInternal.TouchInputPosition.y = get_joint_screen_pos(TooltipInternal.TouchInputTargetPlayer, TooltipInternal.TouchInputTargetJoint)
				touchControlsHolder:moveTo(TooltipInternal.TouchInputPosition.x - touchControlsHolder.size.w / 2, TooltipInternal.TouchInputPosition.y - touchControlsHolder.size.h / 2)
				touchControlsHolder:updatePos()
			end)
		end)
	disable_mouse_camera_movement()
	touchControlsHolder.killAction = function()
		enable_mouse_camera_movement()
		remove_hook("pre_draw", "tooltipTouchPositionFixer")
	end
	local touchControlsVisual = touchControlsHolder:addChild({
		pos = { 74, 74 },
		size = { 2, 2 },
		bgColor = UICOLORWHITE
	})

	local jointStateTextColor = { 0, 0, 0, 0 }
	local jointStateShadowColor = { 255, 255, 255, 0 }
	if (wheelMode == 0 or wheelMode == 2) then
		local touchControlsTopTitle = touchControlsHolder:addChild({
			pos = { -touchControlsHolder.size.w - 150, -touchControlsHolder.size.h - 50 },
			size = { 300 + touchControlsHolder.size.w, 30 }
		})
		---@diagnostic disable-next-line: param-type-mismatch
		touchControlsTopTitle:addAdaptedText(true, get_joint_state_name(TooltipInternal.TouchInputTargetJoint, 3), nil, nil, FONTS.BIG, CENTERBOT, 0.6, nil, nil, 2, jointStateTextColor, jointStateShadowColor)

		local touchControlsBotTitle = touchControlsHolder:addChild({
			pos = { -touchControlsHolder.size.w - 150, touchControlsHolder.size.h + 20 },
			size = { 300 + touchControlsHolder.size.w, 30 }
		})
		---@diagnostic disable-next-line: param-type-mismatch
		touchControlsBotTitle:addAdaptedText(true, get_joint_state_name(TooltipInternal.TouchInputTargetJoint, 4), nil, nil, FONTS.BIG, CENTER, 0.6, nil, nil, 2, jointStateTextColor, jointStateShadowColor)
	end

	if (wheelMode == 0 or wheelMode == 1) then
		local touchControlsRightTitle = touchControlsHolder:addChild({
			pos = { touchControlsHolder.size.w + 20, touchControlsHolder.size.h / 2 - 15 },
			size = { 250, 30 }
		})
		---@diagnostic disable-next-line: param-type-mismatch
		touchControlsRightTitle:addAdaptedText(true, get_joint_state_name(TooltipInternal.TouchInputTargetJoint, 1), nil, nil, FONTS.BIG, LEFTMID, 0.6, nil, nil, 2, jointStateTextColor, jointStateShadowColor)

		local touchControlsLeftTitle = touchControlsHolder:addChild({
			pos = { -touchControlsHolder.size.w - 270, touchControlsHolder.size.h / 2 - 15 },
			size = { 250, 30 }
		})
		---@diagnostic disable-next-line: param-type-mismatch
		touchControlsLeftTitle:addAdaptedText(true, get_joint_state_name(TooltipInternal.TouchInputTargetJoint, 2), nil, nil, FONTS.BIG, RIGHTMID, 0.6, nil, nil, 2, jointStateTextColor, jointStateShadowColor)
	end

	touchControlsHolder.pressTimer = os.clock_real()
	touchControlsHolder.firstPlay = true
	touchControlsHolder:addCustomDisplay(function()
			if (touchControlsVisual.size.w == touchControlsHolder.size.w) then
				TooltipInternal.WaitForTouchInput = true
				return
			end
			if (UIElement.clock - touchControlsHolder.pressTimer < self.TouchInputDelay) then
				return
			end
			if (touchControlsHolder.firstPlay) then
				touchControlsHolder.firstPlay = false
				play_haptics(0.2, HAPTICS.IMPACT)
			end

			local ratio = (UIElement.clock - touchControlsHolder.pressTimer - self.TouchInputDelay) / self.TouchInputGrowDuration
			local tweenRatio = UITween.SineEaseIn(ratio)
			touchControlsVisual.size.w = touchControlsHolder.size.w * tweenRatio
			touchControlsVisual.size.h = touchControlsVisual.size.w
			local moveTarget = math.floor((touchControlsHolder.size.w - touchControlsVisual.size.w) / 2)
			touchControlsVisual:moveTo(moveTarget, moveTarget)

			jointStateTextColor[4] = 0.7 * tweenRatio
			jointStateShadowColor[4] = 0.8 * tweenRatio
		end)

	---@diagnostic disable-next-line: param-type-mismatch
	local lastJointState = get_joint_info(TooltipInternal.TouchInputTargetPlayer, TooltipInternal.TouchInputTargetJoint).state
	local fallbackJointState = lastJointState
	touchControlsVisual:addCustomDisplay(true, function()
			local centerPoint = {
				x = touchControlsHolder.pos.x + touchControlsHolder.size.w / 2,
				y = touchControlsHolder.pos.y + touchControlsHolder.size.h / 2
			}

			local ringSize = touchControlsVisual.size.w / 2
			local ringStartSize = ringSize * 0.7
			set_color(0, 0, 0, 1)
			if (wheelMode == 0) then
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 50, 80, 0) -- right
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 140, 80, 0) -- top
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 230, 80, 0) -- left
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 320, 80, 0) -- bottom
			elseif (wheelMode == 1) then
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 5, 170, 0) -- right
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 185, 170, 0) -- left
			else
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 95, 170, 0) -- top
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 275, 170, 0) -- bottom
			end

			ringSize = ringSize - 1
			ringStartSize = ringStartSize + 1
			set_color(255, 255, 255, 1)
			if (wheelMode == 0) then
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 51, 78, 0) -- right
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 141, 78, 0) -- top
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 231, 78, 0) -- left
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 321, 78, 0) -- bottom
			elseif (wheelMode == 1) then
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 6, 168, 0) -- right
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 186, 168, 0) -- left
			else
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 96, 168, 0) -- top
				draw_disk(centerPoint.x, centerPoint.y, ringStartSize, ringSize, 0, 1, 276, 168, 0) -- bottom
			end

			local mouseDelta = self:getTouchMouseDelta()
			local selectionAngle = 90
			if (wheelMode == 1) then
				mouseDelta.y = 0
				selectionAngle = 180
			elseif (wheelMode == 2) then
				mouseDelta.x = 0
				selectionAngle = 180
			end

			set_color(TB_MENU_DEFAULT_DARKER_COLOR[1], TB_MENU_DEFAULT_DARKER_COLOR[2], TB_MENU_DEFAULT_DARKER_COLOR[3], TB_MENU_DEFAULT_DARKER_COLOR[4])
			local targetJointState = lastJointState
			if (mouseDelta.x ~= 0 or mouseDelta.y ~= 0) then
				if (math.abs(mouseDelta.x) > math.abs(mouseDelta.y)) then
					if (mouseDelta.x > 0) then
						draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 0, 1, 90 - selectionAngle / 2, selectionAngle, 0) -- right
						targetJointState = 1
					else
						draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 0, 1, 270 - selectionAngle / 2, selectionAngle, 0) -- left
						targetJointState = 2
					end
				else
					if (mouseDelta.y > 0) then
						draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 0, 1, 360 - selectionAngle / 2, selectionAngle, 0) -- bottom
						targetJointState = 4
					else
						draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 0, 1, 180 - selectionAngle / 2, selectionAngle, 0) -- top
						targetJointState = 3
					end
				end
			else
				if (fallbackJointState == 1 and wheelMode ~= 2) then
					draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 0, 1, 90 - selectionAngle / 2, selectionAngle, 0) -- right
				elseif (fallbackJointState == 2 and wheelMode ~= 2) then
					draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 0, 1, 270 - selectionAngle / 2, selectionAngle, 0) -- left
				elseif (fallbackJointState == 3 and wheelMode ~= 1) then
					draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 0, 1, 180 - selectionAngle / 2, selectionAngle, 0) -- top
				elseif (fallbackJointState == 4 and wheelMode ~= 1) then
					draw_disk(centerPoint.x, centerPoint.y, ringStartSize * 0.95, ringSize * 1.1, 0, 1, 360 - selectionAngle / 2, selectionAngle, 0) -- bottom
				end
				targetJointState = fallbackJointState
			end

			---It's possible that target player is no longer valid
			---Wrap set_joint_state() in a pcall to ensure we only proceed on success
			if (lastJointState ~= targetJointState and TooltipInternal.WaitForTouchInput) then
				---@diagnostic disable-next-line: param-type-mismatch
				local result = pcall(function() set_joint_state(TooltipInternal.TouchInputTargetPlayer, TooltipInternal.TouchInputTargetJoint, targetJointState, true) end)
				if (result) then
					play_haptics(0.6, HAPTICS.SELECTION)
					lastJointState = targetJointState
					for _, v in pairs(TooltipInternal.OnToggleWheelEvents) do
						if (type(v) == "function") then
							pcall(v)
						end
					end
				end
			end
		end)
end

---Returns normalized touch input delta
---@return Vector2Base
function Tooltip:getTouchMouseDelta()
	if (TooltipInternal.TouchInputPosition == nil) then
		return { x = 0, y = 0 }
	end

	local mouseDelta = {
		x = MOUSE_X - TooltipInternal.TouchInputPosition.x,
		y = MOUSE_Y - TooltipInternal.TouchInputPosition.y
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
function Tooltip.SetTouchJointState()
	if (TooltipInternal.TouchInputTargetPlayer > -1 and TooltipInternal.TouchInputTargetJoint > -1) then
		if (not TooltipInternal.TouchInputPosition or not TooltipInternal.WaitForTouchInput) then
			Tooltip:toggleJointState(TooltipInternal.TouchInputTargetPlayer, TooltipInternal.TouchInputTargetJoint)
			for _, v in pairs(TooltipInternal.OnTapEvents) do
				if (type(v) == "function") then
					pcall(v)
				end
			end
		end
	end

	TooltipInternal.TouchInputPosition = nil
	TooltipInternal.WaitForTouchInput = false
	Tooltip.IsTouchCommitted = true
	Tooltip.DestroyAndDeselect()
end

---Toggles joint state according to current game settings \
---*This is essentially a copy of the cpp code*
---@param player integer
---@param joint integer
function Tooltip:toggleJointState(player, joint)
	local targetJointState = nil
	local mousebuttons = get_option("mousebuttons")
	---@diagnostic disable-next-line: param-type-mismatch
	local jointState = get_joint_info(TooltipInternal.TouchInputTargetPlayer, TooltipInternal.TouchInputTargetJoint).state
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
