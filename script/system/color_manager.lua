do
 	ColorManager = {}
	ColorManager.__index = ColorManager
	ColorResult = {}
	Color3dResult = { 0, 0, 0, 0}
	
	local defaultColor = {1,1,1,1}
	
	function ColorManager:create()
		local cln = {}
		setmetatable(cln, ColorManager)
    end
	
	function ColorManager:showMain()
		colorBG = UIElement:new( {
			pos = {10, 10},
			size = {600, 370},
			bgColor = {0.5,0.5,0.5,1}
		})
		local colorQuit = UIElement:new( {
			parent = colorBG,
			pos = {-40, 0},
			size = {40, 40},
			interactive = true,
			bgColor = {1,0,0,1},
			hoverColor = {1,0.2,0.2,1},
			pressedColor = {0.4,0,0,1}
		})
		colorQuit:addMouseHandlers(nil, function()
				remove_hooks("colorManagerVisual")
				colorBG:kill()
			end, nil)
		local colorMix = UIElement:new( {
			parent = colorBG,
			pos = {20, 50},
			size = {560, 100},
			bgColor = { defaultColor[1], defaultColor[2], defaultColor[3], defaultColor[4] }
		})
		colorMix:addCustomDisplay(false, function()
				local col = {}
				for i = 1, 3 do
					col[i] = string.format("%02X", math.floor(colorMix.bgColor[i] * 255))
				end
				colorMix:uiText(col[1] .. col[2] .. col[3], nil, colorMix.pos.y + 20, FONTS.BIG, nil, 0.8, nil, 1.5)
			end)
		ColorResult = colorMix.bgColor
		local colorButtons = {}
		local colors = { {1,-1,-1,1}, {-1,1,-1,1}, {-1,-1,1,1}, {1,1,-1,1}, {1,-1,1,1}, {-1,1,1,1}, {-1,-1,-1,1}, {1,1,1,1} }
		local colValues = { 0, 0, 0, 0, 0, 0, 0, 0 }
		local sColValues = { 0, 0, 0, 0, 0, 0, 0, 0 }
		for i = 1, 8 do
			colorButtons[i] = UIElement:new( {
				parent = colorBG,
				pos = {30 + (i - 1) * 70, 175},
				size = {50, 50},
				bgColor = colors[i],
				interactive = true
			})
			colorButtons[i]:addMouseHandlers(nil, function()
					colValues[i] = colValues[i] + 1
					for j = 1, 3 do
						local intensityMod = 3 - colValues[i] - sColValues[i]
						if (intensityMod < 1) then
							intensityMod = 1
						end
						colorMix.bgColor[j] = colorMix.bgColor[j] + colorButtons[i].bgColor[j] / 10 * intensityMod
						if (colorMix.bgColor[j] > 1) then
							colorMix.bgColor[j] = 1
						elseif (colorMix.bgColor[j] < 0) then
							colorMix.bgColor[j] = 0
						end
					end
				end, nil)
			colorButtons[i]:addCustomDisplay(false, function()
					colorButtons[i]:uiText(colValues[i], nil, colorButtons[i].pos.y + 10, nil, nil, nil, nil, 1)
				end)
		end
		local superColorButtons = {}
		for i = 1, 8 do
			superColorButtons[i] = UIElement:new( {
				parent = colorBG,
				pos = {30 + (i - 1) * 70, 245},
				size = {50, 50},
				bgColor = colors[i],
				interactive = true
			})
			superColorButtons[i]:addMouseHandlers(nil, function()
					sColValues[i] = sColValues[i] + 1
					for j = 1, 3 do
						local intensityMod = 3 - sColValues[i] - colValues[i]
						if (intensityMod < 1) then
							intensityMod = 1
						end
						colorMix.bgColor[j] = colorMix.bgColor[j] + superColorButtons[i].bgColor[j] / 5 * intensityMod
						if (colorMix.bgColor[j] > 1) then
							colorMix.bgColor[j] = 1
						elseif (colorMix.bgColor[j] < 0) then
							colorMix.bgColor[j] = 0
						end
					end
				end, nil)
			superColorButtons[i]:addCustomDisplay(false, function()
					superColorButtons[i]:uiText("2x", nil, superColorButtons[i].pos.y, FONTS.SMALL, nil, nil, nil, 0.5)
					superColorButtons[i]:uiText(sColValues[i], nil, superColorButtons[i].pos.y + 17, nil, nil, nil, nil, 1)
				end)
		end
		local colorGlow = UIElement:new( {
			parent = colorBG,
			pos = { 30, 315 },
			size = { 200, 35 },
			bgColor = {0,0,0,1},
			interactive = true,
			hoverColor = {0.2,0.2,0.2,1},
			pressedColor = {0.6,0.6,0.6,1}
		})
		colorGlow:addMouseHandlers(nil, function()
				Color3dResult[4] = math.abs(Color3dResult[4] - 1)
				for i = 1, 3 do
					if (colorMix.bgColor[i] > 1 and Color3dResult[4] == 1) then
						Color3dResult[i] = 0.5
					else
						Color3dResult[i] = 0
					end
				end
			end, nil)
		colorGlow:addCustomDisplay(false, function()
				colorGlow:uiText("Add glow")
			end)
		local colorReset = UIElement:new( {
			parent = colorBG,
			pos = {270, 315},
			size = {300, 35},
			bgColor = {0,0,0,1},
			interactive = true,
			hoverColor = {0.2,0.2,0.2,1},
			pressedColor = {0.6,0.6,0.6,1}
		})
		colorReset:addMouseHandlers(nil, function() 
				for i = 1, 4 do
					colorMix.bgColor[i] = defaultColor[i]
				end
				for i = 1, #colValues do
					colValues[i] = 0
					sColValues[i] = 0
				end
			end, nil)
		colorReset:addCustomDisplay(false, function()
				colorReset:uiText("Reset to default", nil, colorReset.pos.y + 3)
			end)
	end

	function ColorManager:drawVisuals()
		for i, v in pairs(UIElementManager) do
			v:updatePos()
		end
		for i, v in pairs(UIVisualManager) do
			v:display()
		end
	end
	
	function ColorManager:draw3dVisuals()
		local col = { ColorResult[1] + Color3dResult[1], ColorResult[2] + Color3dResult[2], ColorResult[3] + Color3dResult[3], ColorResult[4] }
		set_color(unpack(col))
		draw_sphere(1,1,1,1)
	end
end