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
if (Tooltip.ColorNamesHolder == nil) then
	---Color names on hover keep their own holder: the advanced tooltip's is emptied every frame during replays
	Tooltip.ColorNamesHolder = UIElement:new({
		globalid = Tooltip.Globalid + 5,
		pos = { 0, 0 },
		size = { 0, 0 }
	})
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

---Color names on hover (option `colornames`, **5.78**): names the colors a fighter wears where the mouse is,
---for players who can't tell them apart, in the same popup as the advanced tooltip
---@class TooltipColorRow
---@field label string
---@field color integer Color id, 0 for the default look
---@field swatch integer? Color id to show in the swatch when `color` is 0

local TooltipColorNames = {
	HookName = "__tbTooltipColorNames",
	RowHeight = 20,
	TextScale = 0.7,
	---Key of the part the popup shows ("player:body:joint")
	---@type string?
	Key = nil,
	BuiltAt = 0,
	---@type UIElement?
	Popup = nil
}

-- BREAST, CHEST, R_PECS, L_PECS: drawn in the torso color, without a gradient
local TORSO_BODIES = { [1] = true, [2] = true, [5] = true, [8] = true }
-- Body id to trail id: the trails are left hand, right hand, left foot, right foot
local TRAIL_BODIES = { [12] = 0, [11] = 1, [20] = 2, [19] = 3 }

---Whether color names on hover are on
---@return boolean
function Tooltip.ColorNamesEnabled()
	return get_option("colornames") == 1 and not is_mobile()
end

---Plain words for what a color looks like ("dark blue", "light grey"), worked out from its rgb: store names
---like Tesla or Hawk don't say it
---@param colorid integer
---@return string?
function Tooltip.DescribeColor(colorid)
	local ok, info = pcall(get_color_info, colorid)
	if (not ok or type(info) ~= "table") then
		return nil
	end
	local L = TB_MENU_LOCALIZED
	-- Some colors go over 1 (Pure is 1.3) to glow: they look as bright as 1
	local r, g, b = math.min(tonumber(info.r) or 0, 1), math.min(tonumber(info.g) or 0, 1), math.min(tonumber(info.b) or 0, 1)
	local maxValue, minValue = math.max(r, g, b), math.min(r, g, b)
	local delta = maxValue - minValue
	local lightness = (maxValue + minValue) / 2
	local saturation = delta == 0 and 0 or delta / (1 - math.abs(2 * lightness - 1))

	if (saturation < 0.18 or delta < 0.08) then
		if (lightness > 0.85) then
			return L.TOOLTIPHUEWHITE or "white"
		elseif (lightness > 0.6) then
			return (L.TOOLTIPHUELIGHT or "light") .. " " .. (L.TOOLTIPHUEGREY or "grey")
		elseif (lightness > 0.35) then
			return L.TOOLTIPHUEGREY or "grey"
		elseif (lightness > 0.12) then
			return (L.TOOLTIPHUEDARK or "dark") .. " " .. (L.TOOLTIPHUEGREY or "grey")
		end
		return L.TOOLTIPHUEBLACK or "black"
	end

	local hue
	if (maxValue == r) then
		hue = ((g - b) / delta) % 6
	elseif (maxValue == g) then
		hue = (b - r) / delta + 2
	else
		hue = (r - g) / delta + 4
	end
	hue = hue * 60

	local word, shade = nil, true
	if (hue < 15 or hue >= 350) then
		word = lightness > 0.75 and (L.TOOLTIPHUEPINK or "pink") or (L.TOOLTIPHUERED or "red")
		shade = lightness <= 0.75
	elseif (hue < 48) then
		if (lightness < 0.35) then
			word, shade = L.TOOLTIPHUEBROWN or "brown", false
		else
			word = L.TOOLTIPHUEORANGE or "orange"
		end
	elseif (hue < 70) then
		word = L.TOOLTIPHUEYELLOW or "yellow"
	elseif (hue < 95) then
		word = L.TOOLTIPHUELIME or "lime"
	elseif (hue < 160) then
		word = L.TOOLTIPHUEGREEN or "green"
	elseif (hue < 195) then
		word = L.TOOLTIPHUECYAN or "cyan"
	elseif (hue < 255) then
		word = L.TOOLTIPHUEBLUE or "blue"
	elseif (hue < 285) then
		word = L.TOOLTIPHUEPURPLE or "purple"
	elseif (hue < 335) then
		word = lightness > 0.75 and (L.TOOLTIPHUEPINK or "pink") or (L.TOOLTIPHUEMAGENTA or "magenta")
		shade = lightness <= 0.75
	elseif (lightness > 0.5) then
		word, shade = L.TOOLTIPHUEPINK or "pink", false
	else
		-- Crimson, blood: red with a little blue
		word = L.TOOLTIPHUERED or "red"
	end

	if (saturation < 0.35) then
		return (L.TOOLTIPHUEGREYISH or "greyish") .. " " .. word
	elseif (shade and lightness > 0.75) then
		return (L.TOOLTIPHUELIGHT or "light") .. " " .. word
	elseif (shade and lightness < 0.25) then
		return (L.TOOLTIPHUEDARK or "dark") .. " " .. word
	end
	return word
end

---A color's name as the store calls it, with what it looks like when the name doesn't say ("Tesla (purple)").
---Color 0 is "Default", described by `swatch` when given (the default force color, for one)
---@param colorid integer?
---@param swatch integer?
---@return string
function Tooltip.GetColorName(colorid, swatch)
	if (colorid == nil or colorid <= 0) then
		local name = TB_MENU_LOCALIZED.TOOLTIPCOLORDEFAULT or "Default"
		local look = swatch and Tooltip.DescribeColor(swatch)
		return look and (name .. " (" .. look .. ")") or name
	end
	local ok, info = pcall(get_color_info, colorid)
	if (not ok or type(info) ~= "table" or type(info.game_name) ~= "string") then
		return "#" .. colorid
	end
	local name = info.game_name:gsub("_", " ")
	name = name:gsub("(%a)([%w']*)", function(first, rest) return first:upper() .. rest end)
	-- No "Dark Red (red)": the name already says it
	local look = Tooltip.DescribeColor(colorid)
	local lookWord = look and look:match("(%S+)$")
	if (look and not name:lower():find(lookWord:lower(), 1, true)) then
		name = name .. " (" .. look .. ")"
	end
	return name
end

---The colors a fighter wears on a joint (joint >= 0) or a body part, as rows for the tooltip
---@param player integer
---@param body integer
---@param joint integer
---@return TooltipColorRow[]
function Tooltip.GetColorRows(player, body, joint)
	local L = TB_MENU_LOCALIZED
	local rows = {}
	local function add(label, color, swatch)
		table.insert(rows, { label = label, color = tonumber(color) or 0, swatch = swatch })
	end

	---@type PlayerColors?
	local colors = nil
	if (get_player_colors) then
		local ok, result = pcall(get_player_colors, player)
		if (ok and type(result) == "table") then
			colors = result
		end
	end

	if (joint ~= nil and joint >= 0) then
		local jointColors = colors and colors.joints and colors.joints[joint]
		local force, relax = 0, 0
		if (jointColors) then
			force, relax = jointColors.force, jointColors.relax
		else
			local ok, f, r = pcall(get_joint_colors, player, joint)
			if (ok) then
				force, relax = f, r
			end
		end
		add(L.TOOLTIPCOLORFORCE or "Force", force, COLORS.HOLD)
		add(L.TOOLTIPCOLORRELAX or "Relax", relax, COLORS.RELAX)
		if (jointColors and jointColors.item) then
			add(L.TOOLTIPCOLORITEM or "3D item", jointColors.item)
		end
		return rows
	end
	if (body == nil or body < 0) then
		return rows
	end

	-- Older clients only have set_torishop(): one gradient for the whole fighter, no 3D items, hair or trails
	local shop = { }
	if (colors == nil) then
		local ok, result = pcall(set_torishop, player)
		if (ok and type(result) == "table") then
			shop = result
		end
	end
	local bodyColors = colors and colors.bodies and colors.bodies[body] or {
		color = TORSO_BODIES[body] and shop.torso_color or 0,
		primary = shop.grad_pri_color or 0,
		secondary = shop.grad_sec_color or 0
	}

	if (TORSO_BODIES[body]) then
		add(L.TOOLTIPCOLORTORSO or "Torso", bodyColors.color)
	elseif ((bodyColors.primary or 0) <= 0 and (bodyColors.secondary or 0) <= 0) then
		add(L.TOOLTIPCOLORGRADIENT or "Gradient", 0)
	else
		add(L.TOOLTIPCOLORPRIMARY or "Primary gradient", bodyColors.primary)
		add(L.TOOLTIPCOLORSECONDARY or "Secondary gradient", bodyColors.secondary)
	end
	if (bodyColors.item) then
		add(L.TOOLTIPCOLORITEM or "3D item", bodyColors.item)
	end
	if (bodyColors.grab_item) then
		add(L.TOOLTIPCOLORGRABITEM or "3D item (grabbing)", bodyColors.grab_item)
	end
	if (colors and (body == 11 or body == 12)) then
		add(L.TOOLTIPCOLORGRIP or "Grip", colors.grip)
	end
	local trail = TRAIL_BODIES[body]
	if (trail and colors and colors.trails and (colors.trails[trail] or 0) > 0) then
		add(L.TOOLTIPCOLORTRAIL or "Trail", colors.trails[trail])
	end

	if (body == 0) then
		-- The head also lists the colors that belong to the whole fighter
		local seen = { }
		for _, hair in ipairs(colors and colors.hairs or { }) do
			if (not seen[hair]) then
				seen[hair] = true
				add(L.TOOLTIPCOLORHAIR or "Hair", hair)
			end
		end
		local extras = {
			{ "blood", "blood_color", L.TOOLTIPCOLORBLOOD or "Blood" },
			{ "ghost", "ghost_color", L.TOOLTIPCOLORGHOST or "Ghost" },
			{ "impact", "impact_color", L.TOOLTIPCOLORIMPACT or "Impact" },
			{ "timer", nil, L.TOOLTIPCOLORTIMER or "Timer" },
			{ "text", "text_color", L.TOOLTIPCOLORTEXT or "Text" },
			{ "emote", nil, L.TOOLTIPCOLOREMOTE or "Emote" }
		}
		for _, extra in ipairs(extras) do
			local value
			if (colors) then
				value = colors[extra[1]]
			elseif (extra[2]) then
				value = shop[extra[2]]
			end
			if ((tonumber(value) or 0) > 0) then
				add(extra[3], value)
			end
		end
	end
	return rows
end

---Width the color rows need inside a tooltip
---@param rows TooltipColorRow[]
---@return number
function Tooltip.GetColorRowsWidth(rows)
	local width = 0
	for _, row in ipairs(rows) do
		local text = row.label .. ": " .. Tooltip.GetColorName(row.color, row.swatch)
		width = math.max(width, get_string_length(text, FONTS.LMEDIUM) * TooltipColorNames.TextScale)
	end
	return width > 0 and width + TooltipColorNames.RowHeight + 10 or 0
end

---Adds color rows to a tooltip view: a swatch, then "Force: Blue"
---@param view UIElement
---@param rows TooltipColorRow[]
---@param y number
function Tooltip.AddColorRows(view, rows, y)
	local rowHeight = TooltipColorNames.RowHeight
	local swatchSize = rowHeight - 8
	for i, row in ipairs(rows) do
		local rowView = view:addChild({
			pos = { 10, y + (i - 1) * rowHeight },
			size = { view.size.w - 20, rowHeight }
		})
		local swatchColorId = row.color > 0 and row.color or row.swatch
		if (swatchColorId) then
			local rgba = get_color_rgba(swatchColorId)
			local swatchOutline = rowView:addChild({
				pos = { 0, (rowHeight - swatchSize) / 2 },
				size = { swatchSize, swatchSize },
				bgColor = { 1, 1, 1, 0.6 },
				shapeType = ROUNDED,
				rounded = 3
			})
			swatchOutline:addChild({
				shift = { 1, 1 },
				bgColor = { math.min(rgba[1], 1), math.min(rgba[2], 1), math.min(rgba[3], 1), 1 },
				shapeType = ROUNDED,
				rounded = 2
			}, true)
		end
		local rowText = rowView:addChild({
			pos = { swatchSize + 8, 0 },
			size = { rowView.size.w - swatchSize - 8, rowHeight }
		})
		rowText:addAdaptedText(true, row.label .. ": " .. Tooltip.GetColorName(row.color, row.swatch), nil, nil, FONTS.LMEDIUM, LEFTMID, TooltipColorNames.TextScale)
	end
end

---Height color rows add to a tooltip
---@param rows TooltipColorRow[]
---@return number
local function getColorRowsHeight(rows)
	return #rows > 0 and #rows * TooltipColorNames.RowHeight + 2 or 0
end

---Removes the color names popup
function Tooltip.HideColorNames()
	Tooltip.ColorNamesHolder:kill(true)
	TooltipColorNames.Popup = nil
	TooltipColorNames.Key = nil
end

---Shows the color names popup for a fighter's joint (joint >= 0) or body part
---@param player integer
---@param body integer
---@param joint integer
function Tooltip.ShowColorNames(player, body, joint)
	Tooltip.HideColorNames()
	local rows = Tooltip.GetColorRows(player, body, joint)
	if (#rows == 0) then
		return
	end

	local ok, title = pcall(function()
			if (joint >= 0) then
				return get_joint_info(player, joint).name
			end
			local name = get_body_info(player, body).name:gsub("^R_", "RIGHT "):gsub("^L_", "LEFT ")
			return name
		end)
	if (not ok or type(title) ~= "string") then
		title = ""
	end

	local width = math.max(200, get_string_length(title, FONTS.MEDIUM) + 20, Tooltip.GetColorRowsWidth(rows) + 20)
	local titleHeight = 32
	local popup = Tooltip.ColorNamesHolder:addChild({
		pos = { 0, 0 },
		size = { width, titleHeight + getColorRowsHeight(rows) + 8 }
	})
	local outline = popup:addChild({
		bgColor = { 1, 1, 1, 0.4 },
		shapeType = ROUNDED,
		rounded = 4
	})
	local view = outline:addChild({
		shift = { 1, 1 },
		bgColor = Tooltip.BackgroundColor
	}, true)
	local name = view:addChild({
		pos = { 10, 5 },
		size = { view.size.w - 20, titleHeight - 8 }
	})
	name:addAdaptedText(true, title, nil, nil, nil, LEFTMID)
	Tooltip.AddColorRows(view, rows, titleHeight)

	TooltipColorNames.Popup = popup
	TooltipColorNames.Key = player .. ":" .. body .. ":" .. joint
	TooltipColorNames.BuiltAt = UIElement.clock or 0
end

---Follows the mouse: shows, refreshes or hides the color names popup. The advanced tooltip goes first: it
---lists the same colors while it's shown
local function updateColorNames()
	if (not Tooltip.IsActive or not get_mouse_player_part or not Tooltip.ColorNamesEnabled() or
		Tooltip.IsDisplayed or TB_MENU_MAIN_ISOPEN == 1) then
		if (TooltipColorNames.Key) then
			Tooltip.HideColorNames()
		end
		return
	end

	local player, body, joint = get_mouse_player_part()
	if (player == nil) then
		if (TooltipColorNames.Key) then
			Tooltip.HideColorNames()
		end
		return
	end

	-- Customs can arrive while the mouse rests on a fighter, so the colors are read again every second
	local key = player .. ":" .. body .. ":" .. joint
	if (key ~= TooltipColorNames.Key or (UIElement.clock or 0) - TooltipColorNames.BuiltAt > 1) then
		Tooltip.ShowColorNames(player, body, joint)
	end

	local popup = TooltipColorNames.Popup
	if (popup) then
		local x = math.min(MOUSE_X + 20, WIN_W - 10 - popup.size.w)
		local y = math.min(MOUSE_Y + 10, WIN_H - 10 - popup.size.h)
		popup:moveTo(math.max(x, 10), math.max(y, 10))
	end
end

---Starts color names on hover (the option still decides whether they show)
function Tooltip.InitColorNames()
	Tooltip.HideColorNames()
	remove_hooks(TooltipColorNames.HookName)
	if (is_mobile()) then
		return
	end
	add_hook("pre_draw", TooltipColorNames.HookName, updateColorNames)
	add_hook("draw2d", TooltipColorNames.HookName, function()
			if (TooltipColorNames.Popup and TB_MENU_MAIN_ISOPEN ~= 1) then
				UIElement.drawVisuals(Tooltip.ColorNamesHolder.globalid)
			end
		end)
	add_hook("new_game", TooltipColorNames.HookName, Tooltip.HideColorNames)
	add_hook("leave_game", TooltipColorNames.HookName, Tooltip.HideColorNames)
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

	Tooltip.InitColorNames()
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
	-- Color names on hover: the same rows the color names popup shows, under the usual contents
	local colorRows = self.ColorNamesEnabled() and self.GetColorRows(player, body, -1) or { }
	width = math.max(width, self.GetColorRowsWidth(colorRows) + 20)
	-- Height of the usual contents, which keep their layout
	local viewHeight = height - 2

	local tbTooltip = self:spawnTooltipMain(self.WorldState.match_frame, width, height + getColorRowsHeight(colorRows), get_body_screen_pos(player, body))
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
		size = { tbTooltipView.size.w - 20, viewHeight / heightMod * 2 - 10 }
	})
	jointTooltipName:addAdaptedText(true, bodyInfo.name, nil, nil, nil, LEFTMID)
	if (#colorRows > 0) then
		self.AddColorRows(tbTooltipView, colorRows, viewHeight - 4)
	end

	if (body == 11 or body == 12) then
		self.GrabDisplayActive = true
		local jointTooltipState = tbTooltipView:addChild({
			pos = { viewHeight / 3 + 10, jointTooltipName.shift.y + jointTooltipName.size.h },
			size = { tbTooltipView.size.w - viewHeight / 3 - 25, viewHeight / 3 - 5 }
		})
		local function drawGrabState(state)
			set_color(0.9, 0.9, 0.9, 1)
			if (state == 0) then
				draw_quad(tbTooltipView.pos.x + 10, jointTooltipState.pos.y, viewHeight / 3 - 5, viewHeight / 3 - 5)
			else
				draw_quad(tbTooltipView.pos.x + 10, jointTooltipState.pos.y + height / 12, viewHeight / 3 - 5, viewHeight / 9)
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
	-- Color names on hover: the same rows the color names popup shows, under the joint state
	local colorRows = self.ColorNamesEnabled() and self.GetColorRows(player, -1, joint) or { }
	width = math.max(width, self.GetColorRowsWidth(colorRows) + 20)
	-- Height of the usual contents, which keep their layout
	local viewHeight = 68

	local tbTooltip = self:spawnTooltipMain(self.WorldState.match_frame, width, 70 + getColorRowsHeight(colorRows), get_joint_screen_pos(player, joint))
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
		size = { tbTooltipView.size.w - 20, viewHeight / 3 * 2 - 10 }
	})
	jointTooltipName:addAdaptedText(true, jointInfo.name, nil, nil, nil, LEFTMID)

	local jointTooltipState = tbTooltipView:addChild({
		pos = { viewHeight / 3 + 10, jointTooltipName.shift.y + jointTooltipName.size.h },
		size = { tbTooltipView.size.w - viewHeight / 3 - 25, viewHeight / 3 - 5 }
	})
	if (#colorRows > 0) then
		self.AddColorRows(tbTooltipView, colorRows, viewHeight - 4)
	end
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
