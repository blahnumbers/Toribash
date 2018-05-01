dofile("toriui/uielement.lua")
dofile("system/player_info.lua")

-- Creating quit() function to exit the script
local function quit()
	tbMenuUserBar:kill()
	remove_hooks("uiVisuals")
end

-- Function that creates the objects
local function createUserBar()
	-- Spawning primary parent object
	tbMenuUserBar = UIElement:new({
		pos = { 20, 20 },
		size = { 500, 100 },
		bgColor = { 0, 0, 0, 0.3 }
	})

	-- Creating the viewport - pay attention to viewport = true property
	local tbMenuUserHeadAvatarViewport = UIElement:new( {
		parent = tbMenuUserBar,
		pos = { 210, 0 },
		size = { tbMenuUserBar.size.h, tbMenuUserBar.size.h },
		viewport = true
	})

	-- Creating the neck sphere with user's force color.
	-- Pay attention to number of elements within pos and rot tables.
	local color = { 1, 1, 1, 1 }
	local tbMenuUserHeadAvatarNeck = UIElement:new({
		parent = tbMenuUserHeadAvatarViewport,
		pos = { 0, 0, 10 },
		rot = { 0, 0, 0 },
		radius = 1,
		bgColor = color
	})
	local colorPreview = UIElement:new({
		parent = tbMenuUserBar,
		pos = { 310, 10 },
		size = { 140, 80 },
		bgColor = color
	})
	
	local textfield = UIElement:new({
		parent = tbMenuUserBar,
		pos = { 10, 10 },
		size = { 200, 40 },
		interactive = true,
		textfield = true,
		textfieldstr = { "1" },
		isNumeric = true,
		bgColor = { 1, 1, 1, 0.2 }
	})
	textfield:addCustomDisplay(false, function()
			textfield:uiText(textfield.textfieldstr[1], textfield.pos.x + 5, textfield.pos.y + 3, 1, LEFT, nil, nil, nil, UICOLORBLACK)
			if (textfield.keyboard) then
				if (math.floor(os.clock() * 1.5 % 2) == 1) then
					textfield:uiText(textfield.textfieldstr[1] .. " ", textfield.pos.x + 5, textfield.pos.y + 3, 1, LEFT, nil, nil, nil, UICOLORBLACK)
				else 
					textfield:uiText(textfield.textfieldstr[1] .. "|", textfield.pos.x + 5, textfield.pos.y + 3, 1, LEFT, nil, nil, nil, UICOLORBLACK)
				end
			end
		end)
	
	local colorName = UIElement:new({
		parent = colorPreview,
		pos = { 0, -20 },
		size = { colorPreview.size.w, 20 },
		bgColor = UICOLORBLACK
	})
	local loadColor = UIElement:new({
		parent = tbMenuUserBar,
		pos = { 10, 60 },
		size = { 100, 30 },
		interactive = true,
		bgColor = { 1, 0.5, 1, 0.3 },
		hoverColor = { 1, 1, 1, 0.5 }
	})
	local nextColor = UIElement:new({
		parent = tbMenuUserBar,
		pos = { 110, 60 },
		size = { 100, 30 },
		interactive = true,
		bgColor = { 1, 0.5, 1, 0.3 },
		hoverColor = { 1, 1, 1, 0.5 }
	})
	loadColor:addCustomDisplay(false, function()
			loadColor:uiText("Load Color", nil, nil, nil, nil, 0.7)
		end)
	loadColor:addMouseHandlers(nil, function()
			set_joint_force_color(0, tonumber(textfield.textfieldstr[1]))
			set_joint_relax_color(0, tonumber(textfield.textfieldstr[1]))
			set_blood_color(0, tonumber(textfield.textfieldstr[1]))
			set_gradient_primary_color(0, tonumber(textfield.textfieldstr[1]))
			set_gradient_secondary_color(0, tonumber(textfield.textfieldstr[1]))
			set_torso_color(0, tonumber(textfield.textfieldstr[1]))
			set_ghost_color(0, tonumber(textfield.textfieldstr[1]))
			local color = get_color_info(tonumber(textfield.textfieldstr[1]))
			colorName:addCustomDisplay(false, function() colorName:uiText(color.name, nil, nil, 4, nil, 0.6) end)
			tbMenuUserHeadAvatarNeck.bgColor = { color.r, color.g, color.b, 1 }
			colorPreview.bgColor = { color.r, color.g, color.b, 1 }
		end)
	nextColor:addCustomDisplay(false, function()
			nextColor:uiText("Next color", nil, nil, nil, nil, 0.7)
		end)
	nextColor:addMouseHandlers(nil, function()
			textfield.textfieldstr[1] = tonumber(textfield.textfieldstr[1]) + 1
			set_joint_force_color(0, tonumber(textfield.textfieldstr[1]))
			set_joint_relax_color(0, tonumber(textfield.textfieldstr[1]))
			set_blood_color(0, tonumber(textfield.textfieldstr[1]))
			set_gradient_primary_color(0, tonumber(textfield.textfieldstr[1]))
			set_gradient_secondary_color(0, tonumber(textfield.textfieldstr[1]))
			set_torso_color(0, tonumber(textfield.textfieldstr[1]))
			set_ghost_color(0, tonumber(textfield.textfieldstr[1]))
			local color = get_color_info(tonumber(textfield.textfieldstr[1]))
			colorName:addCustomDisplay(false, function() colorName:uiText(color.name, nil, nil, 4, nil, 0.6) end)
			tbMenuUserHeadAvatarNeck.bgColor = { color.r, color.g, color.b, 1 }
			colorPreview.bgColor = { color.r, color.g, color.b, 1 }
		end)
	-- Creating quit button
	local quitButton = UIElement:new({
		parent = tbMenuUserBar,
		pos = { -40, 10 },
		size = { 30, 30 },
		interactive = true,
		bgColor = UICOLORGREEN,
		hoverColor = UICOLORBLACK,
		pressedColor = UICOLORBLUE
	})
	quitButton:addMouseHandlers(nil, quit)
end

-- Default drawVisuals() function for draw2d hook.
local function drawVisuals()
	for i, v in pairs(UIElementManager) do
		v:updatePos()
	end
	for i, v in pairs(UIVisualManager) do
		v:display()
	end
end

-- Default drawViewport() function for draw_viewport hook.
-- Similarly to drawVisuals(), cycles through every viewport object and displays it on screen.
local function drawViewport()
	for i, v in pairs(UIViewportManager) do
		v:displayViewport()
	end
end

createUserBar()

-- Adding hooks
add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y) UIElement:handleMouseDn(s, x, y) end)
add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
add_hook("mouse_move", "uiMouseHandler", function(x, y) UIElement:handleMouseHover(x, y) end)
add_hook("key_up", "uiKeyboardHandler", function(key) UIElement:handleKeyUp(key) if (KEYBOARDGLOBALIGNORE) then return 1 end end)
add_hook("key_down", "uiKeyboardHandler", function(key) UIElement:handleKeyDown(key) end)
add_hook("draw2d", "uiVisuals", drawVisuals)
add_hook("draw_viewport", "uiVisuals", drawViewport)