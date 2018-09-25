-- UI class

WIN_W, WIN_H = get_window_size()
MOUSE_X, MOUSE_Y = 0, 0

FONTS.BIGGER = 9

KEYBOARDGLOBALIGNORE = KEYBOARDGLOBALIGNORE or false
LONGKEYPRESSED = { status = false, key = nil, time = nil, repeats = 0 }

SQUARE = 1
ROUNDED = 2

LEFT = 0
CENTER = 1
RIGHT = 2
LEFTBOT = 3
CENTERBOT = 4
RIGHTBOT = 5
LEFTMID = 6
CENTERMID = 7
RIGHTMID = 8

BTN_DN = 1
BTN_HVR = 2

DEFTEXTURE = "../textures/menu/logos/toribash.tga"
TEXTURECACHE = {}
TEXTUREINDEX = TEXTUREINDEX or 0
DEFTEXTCOLOR = DEFTEXTCOLOR or { 1, 1, 1, 1 }
DEFSHADOWCOLOR = DEFSHADOWCOLOR or { 0, 0, 0, 0.6 }

UICOLORWHITE = {1,1,1,1}
UICOLORBLACK = {0,0,0,1}
UICOLORRED = {1,0,0,1}
UICOLORGREEN = {0,1,0,1}
UICOLORBLUE = {0,0,1,1}

do
	UIElementManager = UIElementManager or {}
	UIVisualManager = UIVisualManager or {}
	UIViewportManager = UIViewportManager or {}
	UIMouseHandler = UIMouseHandler or {}
	UIKeyboardHandler = UIKeyboardHandler or {}
	
	if (not UIElement) then 
		UIElement = {}
		UIElement.__index = UIElement
	end

	-- Spawns new UI Element
	function UIElement:new(o)
		local elem = {	parent = nil,
						child = {},
						pos = {},
						shift = {},
						bgColor = { 1, 1, 1, 0 },
						customDisplay = function() end,
						innerShadow = { 0, 0 },
						}
		setmetatable(elem, self)
		
		o = o or nil
		if (o) then
			if (o.parent) then
				elem.parent = o.parent
				table.insert(elem.parent.child, elem)
				if (o.parent.viewport) then
					elem.pos.x = o.pos[1]
					elem.pos.y = o.pos[2]
					elem.pos.z = o.pos[3]
					elem.rot = { x = o.rot[1], y = o.rot[2], z = o.rot[3] }
					elem.radius = o.radius
				else
					elem.shift.x = o.pos[1]
					elem.shift.y = o.pos[2]
					elem.size = { w = o.size[1], h = o.size[2] }
				end
			else
				elem.pos.x = o.pos[1]
				elem.pos.y = o.pos[2]
				elem.size = { w = o.size[1], h = o.size[2] }
			end
			if (o.viewport) then
				elem.viewport = o.viewport
			end
			if (o.bgColor) then	
				elem.bgColor = o.bgColor 
			end
			if (o.bgImage) then 
				if (type(o.bgImage) == "table") then
					elem:updateImage(o.bgImage[1], o.bgImage[2])
				else
					elem:updateImage(o.bgImage)
				end
			end
			if (o.textfield) then
				-- Textfield value is a table to allow proper initiation / use after obj is created
				elem.textfield = o.textfield
				elem.textfieldstr = o.textfieldstr or { "" }
				elem.textfieldindex = elem.textfieldstr[1]:len()
				elem.textfieldsingleline = o.textfieldsingleline
				elem.keyDown = function(key) elem:textfieldKeyDown(key, o.isNumeric) end
				elem.keyUp = function(key) elem:textfieldKeyUp(key) end
				table.insert(UIKeyboardHandler, elem)
			end
			if (o.innerShadow) then
				elem.shadowColor = {} 
				if (type(o.shadowColor[1]) == "table") then
					elem.shadowColor = o.shadowColor
				else
					elem.shadowColor = { o.shadowColor, o.shadowColor }
				end
				elem.innerShadow = o.innerShadow
			end
			if (o.shapeType) then 
				elem.shapeType = o.shapeType
				if (o.rounded * 2 > elem.size.w or o.rounded * 2 > elem.size.h) then
					if (elem.size.w > elem.size.h) then
						elem.rounded = elem.size.h / 2
					else
						elem.rounded = elem.size.w / 2
					end
				else
					elem.rounded = o.rounded
				end
			end
			if (o.interactive) then 
				elem.interactive = o.interactive
				elem.isactive = true
				elem.scrollEnabled = o.scrollEnabled or nil
				elem.hoverColor = o.hoverColor or nil
				elem.pressedColor = o.pressedColor or nil
				elem.inactiveColor = o.inactiveColor or o.bgColor
				elem.animateColor = {}
				for i = 1, 4 do
					elem.animateColor[i] = elem.bgColor[i]
				end
				elem.hoverState = false
				elem.pressedPos = { x = nil, y = nil }
				elem.btnDown = function() end
				elem.btnUp = function() end
				elem.btnHover = function() end
				table.insert(UIMouseHandler, elem)
			end
			if (o.keyboard) then
				elem.keyDown = function() end
				elem.keyUp = function() end
			end
			if (o.hoverSound) then
				elem.hoverSound = o.hoverSound
			end
			if (o.upSound) then
				elem.upSound = o.upSound
			end
			if (o.downSound) then
				elem.downSound = o.downSound
			end
			
			table.insert(UIElementManager, elem)
			
			-- Display is enabled by default, comment this out to disable
			if (elem.viewport or (elem.parent and elem.parent.viewport)) then
				table.insert(UIViewportManager, elem)
			else	
				table.insert(UIVisualManager, elem)
			end
			
			-- Force update global x/y pos when spawning element
			elem:updatePos()
		end
		
		return elem
	end
	
	function UIElement:addMouseHandlers(btnDown, btnUp, btnHover)
		if (btnDown) then
			self.btnDown = btnDown
		end
		if (btnUp) then
			self.btnUp = btnUp
		end
		if (btnHover) then
			self.btnHover = btnHover
		end
	end
	
	function UIElement:addKeyboardHandlers(keyDown, keyUp)
		if (keyDown) then
			self.keyDown = keyDown
		end
		if (keyUp) then
			self.keyUp = keyUp
		end
	end
	
	function UIElement:addEnterAction(func)
		self.textfieldenteractionenabled = true
		self.textfieldenteraction = func
	end
	
	function UIElement:removeEnterAction()
		self.textfieldenteractionenabled = false
		self.textfieldenteraction = nil
	end
	
	function UIElement:reloadListElements(listHolder, listElements, toReload, enabled)
		local listElementHeight = listElements[1].size.h
		local checkPos = math.abs(math.ceil(-(listHolder.shift.y + self.size.h) / listElementHeight))
		
		for i = #enabled, 1, -1 do
			enabled[i]:hide()
			table.remove(enabled)
		end
		
		if (checkPos > 0 and checkPos * listElementHeight + listHolder.shift.y + self.size.h > 0) then
			listElements[checkPos]:show()
			table.insert(enabled, listElements[checkPos])
		end
		while (listHolder.shift.y + self.size.h + checkPos * listElementHeight >= 0 and listHolder.shift.y + checkPos * listElementHeight <= 0 and checkPos < #listElements) do
			listElements[checkPos + 1]:show()
			table.insert(enabled, listElements[checkPos + 1])
			checkPos = checkPos + 1
		end
		
		toReload:reload()
	end
	
	function UIElement:makeScrollBar(listHolder, listElements, toReload, posShift, scrollSpeed)
		local scrollSpeed = scrollSpeed or 1
		local posShift = posShift or { 0 }
		local enabled = {}
		listHolder.shift.y = listHolder.shift.y == 0 and -listHolder.size.h or listHolder.shift.y
		self.pressedPos = { x = 0, y = 0 }
				
		self:barScroll(listElements, listHolder, toReload, posShift[1], enabled)
		
		self:addMouseHandlers(
			function(s, x, y)
				if (s < 4) then
					self.pressedPos = self:getLocalPos(x,y)
					self.hoverState = BTN_DN
				else
					self:mouseScroll(listElements, listHolder, toReload, y * scrollSpeed, enabled)
					posShift[1] = self.shift.y
				end
			end, nil, 
			function(x, y)
				if (self.hoverState == BTN_DN) then
					local posY = self:getLocalPos(x,y).y - self.pressedPos.y + self.shift.y
					self:barScroll(listElements, listHolder, toReload, posY, enabled)
					posShift[1] = self.shift.y
				end
			end)
	end
	
	function UIElement:mouseScroll(listElements, listHolder, toReload, scroll, enabled)
		local elementHeight = listElements[1].size.h
		local listHeight = #listElements * elementHeight
		if (listHolder.shift.y + scroll * elementHeight > -listHolder.size.h) then
			self:moveTo(self.shift.x, 0)
			listHolder:moveTo(listHolder.shift.x, -listHolder.size.h)
		elseif (listHolder.shift.y + scroll * elementHeight < -listHeight) then
			self:moveTo(self.shift.x, self.parent.size.h - self.size.h)
			listHolder:moveTo(listHolder.shift.x, -listHeight)
		else
			listHolder:moveTo(listHolder.shift.x, listHolder.shift.y + scroll * elementHeight)
			local scrollProgress = -(listHolder.size.h + listHolder.shift.y) / (listHeight - listHolder.size.h)
			self:moveTo(self.shift.x, (self.parent.size.h - self.size.h) * scrollProgress)
		end	
		listHolder.parent:reloadListElements(listHolder, listElements, toReload, enabled)
	end
	
	function UIElement:barScroll(listElements, listHolder, toReload, posY, enabled)
		local sizeH = math.floor(self.size.h / 4)
		local listHeight = listElements[1].size.h * #listElements
		
		if (posY <= 0) then
			if (self.pressedPos.y < sizeH) then
				self.pressedPos.y = sizeH
			end
			self:moveTo(self.shift.x, 0)
			listHolder:moveTo(listHolder.shift.x, -listHolder.size.h)
		elseif (posY >= self.parent.size.h - self.size.h) then
			if (self.pressedPos.y > self.parent.size.h - sizeH) then
				self.pressedPos.y = self.parent.size.h - sizeH
			end			
			self:moveTo(self.shift.x, self.parent.size.h - self.size.h)
			listHolder:moveTo(listHolder.shift.x, -listHeight)
		else
			self:moveTo(self.shift.x, posY)
			local scrollProgress = self.shift.y / (self.parent.size.h - self.size.h)
			listHolder:moveTo(listHolder.shift.x, -listHolder.size.h + (listHolder.size.h - listHeight) * scrollProgress)
		end
		listHolder.parent:reloadListElements(listHolder, listElements, toReload, enabled)
	end
		
	function UIElement:addCustomDisplay(funcTrue, func, drawBefore)
		self.customDisplayTrue = funcTrue
		self.customDisplay = func
		if (drawBefore) then 
			self.customDisplayBefore = drawBefore
		end
	end
	
	function UIElement:kill(childOnly)
		for i,v in pairs(self.child) do
			v:kill()
		end
		if (childOnly) then
			self.child = {}
			return true
		end
		
		if (self.bgImage) then self:updateImage(nil) end
		for i,v in pairs(UIMouseHandler) do
			if (self == v) then
				table.remove(UIMouseHandler, i)
				break
			end
		end
		for i,v in pairs(UIKeyboardHandler) do
			if (self == v) then
				table.remove(UIKeyboardHandler, i)
				break
			end
		end
		for i,v in pairs(UIVisualManager) do
			if (self == v) then
				table.remove(UIVisualManager, i)
				break
			end
		end
		for i,v in pairs(UIElementManager) do
			if (self == v) then
				table.remove(UIElementManager, i)
				break
			end
		end
		for i,v in pairs(UIViewportManager) do
			if (self == v) then
				table.remove(UIViewportManager, i)
				break
			end
		end
		self = nil
	end
	
	function UIElement:updatePos()
		if (self.parent) then 
			self:updateChildPos()
		end
	end
	
	function UIElement:clearTextfield()
		if (self.textfield) then
			self.textfieldstr[1] = ""
			self.textfieldindex = 0
		end
	end
	
	function UIElement:displayViewport()
		if (self.customDisplayBefore) then 
			self.customDisplay()
		end
		if (self.viewport) then
			set_viewport(self.pos.x, self.pos.y, self.size.w, self.size.h)
		else 
			set_color(unpack(self.bgColor))
			if (self.bgImage) then
				draw_sphere(self.pos.x, self.pos.y, self.pos.z, self.radius, self.rot.x, self.rot.y, self.rot.z, self.bgImage)
			else 
				draw_sphere(self.pos.x, self.pos.y, self.pos.z, self.radius, self.rot.x, self.rot.y, self.rot.z)
			end
		end
		if (not self.customDisplayBefore) then
			self.customDisplay()
		end
	end
		
	function UIElement:display()
		if (self.interactive and not self.isactive) then
			for i = 1, 4 do
				if ((self.bgColor[i] > self.inactiveColor[i] and self.animateColor[i] > self.inactiveColor[i]) or (self.bgColor[i] < self.inactiveColor[i] and self.animateColor[i] < self.inactiveColor[i])) then
					self.animateColor[i] = self.animateColor[i] - math.floor((self.bgColor[i] - self.inactiveColor[i]) * 150) / 1000
				end
			end
		elseif (self.hoverState ~= false and self.hoverColor) then
			for i = 1, 4 do
				if ((self.bgColor[i] > self.hoverColor[i] and self.animateColor[i] > self.hoverColor[i]) or (self.bgColor[i] < self.hoverColor[i] and self.animateColor[i] < self.hoverColor[i])) then
					self.animateColor[i] = self.animateColor[i] - math.floor((self.bgColor[i] - self.hoverColor[i]) * 150) / 1000
				end
			end
		elseif (self.animateColor) then
			for i = 1, 4 do
				self.animateColor[i] = self.bgColor[i]
			end
		end
		if (self.customDisplayBefore) then
			self.customDisplay()
		end
		if (not self.customDisplayTrue) then
			if (self.innerShadow[1] > 0 or self.innerShadow[2] > 0) then
				set_color(unpack(self.shadowColor[1]))
				if (self.shapeType == ROUNDED) then
					draw_disk(self.pos.x + self.rounded, self.pos.y + self.rounded, 0, self.rounded, 500, 1, -180, 90, 0)
					draw_disk(self.pos.x + self.size.w - self.rounded, self.pos.y + self.rounded, 0, self.rounded, 500, 1, 90, 90, 0)
					draw_quad(self.pos.x + self.rounded, self.pos.y, self.size.w - self.rounded * 2, self.rounded)
					draw_quad(self.pos.x, self.pos.y + self.rounded, self.size.w, self.size.h / 2 - self.rounded)
					set_color(unpack(self.shadowColor[2]))
					draw_disk(self.pos.x + self.rounded, self.pos.y + self.size.h - self.rounded, 0, self.rounded, 500, 1, -90, 90, 0)
					draw_disk(self.pos.x + self.size.w - self.rounded, self.pos.y + self.size.h - self.rounded, 0, self.rounded, 500, 1, 0, 90, 0)
					draw_quad(self.pos.x, self.pos.y + self.size.h / 2, self.size.w, self.size.h / 2 - self.rounded)
					draw_quad(self.pos.x + self.rounded, self.pos.y + self.size.h - self.rounded, self.size.w - self.rounded * 2, self.rounded)
				else
					draw_quad(self.pos.x, self.pos.y, self.size.w, self.size.h / 2)
					set_color(unpack(self.shadowColor[2]))
					draw_quad(self.pos.x, self.pos.y + self.size.h / 2, self.size.w, self.size.h / 2)
				end
			end
			if (self.hoverState == BTN_HVR and self.hoverColor) then
				set_color(unpack(self.animateColor))
			elseif (self.hoverState == BTN_DN and self.pressedColor) then
				set_color(unpack(self.pressedColor))
			elseif (self.interactive) then
				set_color(unpack(self.animateColor))
			else
				set_color(unpack(self.bgColor))
			end
			if (self.shapeType == ROUNDED) then
				draw_disk(self.pos.x + self.rounded, self.pos.y + self.rounded + self.innerShadow[1], 0, self.rounded, 500, 1, -180, 90, 0)
				draw_disk(self.pos.x + self.rounded, self.pos.y + self.size.h - self.rounded - self.innerShadow[2], 0, self.rounded, 500, 1, -90, 90, 0)
				draw_disk(self.pos.x + self.size.w - self.rounded, self.pos.y + self.rounded + self.innerShadow[1], 0, self.rounded, 500, 1, 90, 90, 0)
				draw_disk(self.pos.x + self.size.w - self.rounded, self.pos.y + self.size.h - self.rounded - self.innerShadow[2], 0, self.rounded, 500, 1, 0, 90, 0)
				draw_quad(self.pos.x + self.rounded, self.pos.y + self.innerShadow[1], self.size.w - self.rounded * 2, self.rounded)
				draw_quad(self.pos.x, self.pos.y + self.rounded + self.innerShadow[1], self.size.w, self.size.h - self.rounded * 2 - self.innerShadow[2] - self.innerShadow[1])
				draw_quad(self.pos.x + self.rounded, self.pos.y + self.size.h - self.rounded - self.innerShadow[2], self.size.w - self.rounded * 2, self.rounded)
			else
				draw_quad(self.pos.x, self.pos.y + self.innerShadow[1], self.size.w, self.size.h - self.innerShadow[1] - self.innerShadow[2])
			end
			if (self.bgImage) then
				draw_quad(self.pos.x, self.pos.y, self.size.w, self.size.h, self.bgImage)
			end
		end
		if (not self.customDisplayBefore) then
			self.customDisplay()
		end
	end
	
	function UIElement:reload()
		self:hide()
		self:show()
	end
	
	function UIElement:activate()
		local num = nil

		for i,v in pairs(UIMouseHandler) do
			if (self == v) then
				num = i
				break
			end
		end
		if (not num) then
			if (self.interactive) then
				self.hoverState = false
				table.insert(UIMouseHandler, self)
			end
			if (self.keyboard) then
				table.insert(UIKeyboardHandler, self)
			end
			self.isactive = true
		end
	end
	
	function UIElement:deactivate()
		local num = nil
		self.hoverState = false
		self.isactive = false
		if (self.interactive) then
			for i,v in pairs(UIMouseHandler) do
				if (self == v) then
					num = i
					break
				end
			end
			if (num) then
				table.remove(UIMouseHandler, num)
			end
		end
		if (self.keyboard) then
			for i,v in pairs(UIKeyboardHandler) do
				if (self == v) then
					num = i
					break
				end
			end
			if (num) then
				table.remove(UIKeyboardHandler, num)
			end
		end
	end
	
	function UIElement:isDisplayed()
		local viewport = (self.viewport or (self.parent and self.parent.viewport)) and true or false
		
		if (not viewport) then
			for i,v in pairs(UIVisualManager) do
				if (self == v) then
					return true
				end
			end
		else
			for i,v in pairs(UIViewportManager) do
				if (self == v) then
					return true
				end
			end
		end
		return false
	end
	
	function UIElement:show(forceReload)
		local num = nil
		local viewport = (self.viewport or (self.parent and self.parent.viewport)) and true or false
		
		if (self.noreload and not forceReload) then
			return false
		elseif (forceReload) then
			self.noreload = nil
		end
		
		for i,v in pairs(UIVisualManager) do
			if (self == v) then
				num = i
				break
			end
		end
		for i,v in pairs(UIViewportManager) do
			if (self == v) then
				num = i
				break
			end
		end
		
		if (not num) then
			if (viewport) then
				table.insert(UIViewportManager, self)
			else
				table.insert(UIVisualManager, self)
			end	
			if (self.interactive) then
				table.insert(UIMouseHandler, self)
			end
			if (self.keyboard) then
				table.insert(UIKeyboardHandler, self)
			end
		end
		
		for i,v in pairs(self.child) do
			v:show()
		end
	end
	
	function UIElement:hide(noreload)
		local num = nil
		for i,v in pairs(self.child) do
			v:hide(noreload)
		end
		
		if (noreload) then 
			self.noreload = true
		end
		
		if (self.interactive) then
			for i,v in pairs(UIMouseHandler) do
				if (self == v) then
					num = i
					break
				end
			end
			if (num) then
				table.remove(UIMouseHandler, num)
			end
		end
		
		if (self.keyboard) then
			for i,v in pairs(UIKeyboardHandler) do
				if (self == v) then
					num = i
					break
				end
			end
			if (num) then
				table.remove(UIKeyboardHandler, num)
			end
		end
		
		for i,v in pairs(UIVisualManager) do
			if (self == v) then
				num = i
				break
			end
		end
		
		for i,v in pairs(UIViewportManager) do
			if (self == v) then
				table.remove(UIViewportManager, i)
				break
			end
		end
		
		if (num) then
			table.remove(UIVisualManager, num)
		end
	end
		
	function UIElement:textfieldKeyUp(key)
		LONGKEYPRESSED.status = false
		LONGKEYPRESSED.key = nil
		LONGKEYPRESSED.time = nil
		LONGKEYPRESSED.repeats = 0
		
		if ((key == 13 or key == 271) and self.textfieldenteractionenabled) then
			self.textfieldenteraction()
		end
	end
	
	function UIElement:textfieldUpdate(symbol)
		local part1 = self.textfieldstr[1]:sub(0, self.textfieldindex)
		local part2 = self.textfieldstr[1]:sub(self.textfieldindex + 1)
		self.textfieldstr[1] = part1 .. symbol .. part2
		if (self.textfieldstr[1]:find("\\n") and self.textfieldsingleline) then
			self.textfieldstr[1] = self.textfieldstr[1]:gsub("\\n", "")
			self.textfieldindex = self.textfieldindex - 2
		end
	end
	
	function UIElement:textfieldKeyDown(key, isNumeric)
		local isNumeric = isNumeric or false
		
		--[[if (LONGKEYPRESSED.status == false or key ~= LONGKEYPRESSED.key) then 
			LONGKEYPRESSED.status = true
			LONGKEYPRESSED.key = key
			LONGKEYPRESSED.time = os.clock()
			LONGKEYPRESSED.repeats = 1
		elseif (os.clock() - LONGKEYPRESSED.time > 0.5 and (LONGKEYPRESSED.repeats < 15 or LONGKEYPRESSED.key == 8 or LONGKEYPRESSED.key == 127 or LONGKEYPRESSED.key == 266) ) then
			LONGKEYPRESSED.repeats = LONGKEYPRESSED.repeats + 1
		else
			return 1
		end]]
		
		if (isNumeric and (get_shift_key_state() > 0 or key < 48 or key > 57) and key ~= 8) then
			return 1
		end
		if (key == 8) then
			if (self.textfieldindex > 0) then
				self.textfieldstr[1] = self.textfieldstr[1]:sub(1, self.textfieldindex - 1) .. self.textfieldstr[1]:sub(self.textfieldindex + 1)
				self.textfieldindex = self.textfieldindex - 1
			end
		elseif (key == 127 or key == 266) then
			self.textfieldstr[1] = self.textfieldstr[1]:sub(1, self.textfieldindex) .. self.textfieldstr[1]:sub(self.textfieldindex + 2) 
		elseif (key == 276) then
			self.textfieldindex = self.textfieldindex > 0 and self.textfieldindex - 1 or 0
		elseif (key == 275) then
			self.textfieldindex = self.textfieldindex < self.textfieldstr[1]:len() and self.textfieldindex + 1 or self.textfieldindex
		else
			if ((key == string.byte('-')) and (get_shift_key_state() > 0)) then
				self:textfieldUpdate("_")
			elseif ((key == string.byte('1')) and (get_shift_key_state() > 0)) then
				self:textfieldUpdate("!")
			elseif ((key == string.byte('2')) and (get_shift_key_state() > 0)) then
				self:textfieldUpdate("@")
			elseif ((key == string.byte('3')) and (get_shift_key_state() > 0)) then
				self:textfieldUpdate("#")
			elseif ((key == string.byte('4')) and (get_shift_key_state() > 0)) then
				self:textfieldUpdate("$")
			elseif ((key == string.byte('5')) and (get_shift_key_state() > 0)) then
				self:textfieldUpdate("%")
			elseif ((key == string.byte('6')) and (get_shift_key_state() > 0)) then
				self:textfieldUpdate("^")
			elseif ((key == string.byte('7')) and (get_shift_key_state() > 0)) then
				self:textfieldUpdate("&")
			elseif ((key == string.byte('8')) and (get_shift_key_state() > 0) or key == 268) then
				self:textfieldUpdate("*")
			elseif ((key == string.byte('9')) and (get_shift_key_state() > 0)) then
				self:textfieldUpdate("(")
			elseif ((key == string.byte('0')) and (get_shift_key_state() > 0)) then
				self:textfieldUpdate(")")
			elseif ((key == string.byte('=')) and (get_shift_key_state() > 0) or key == 270) then
				self:textfieldUpdate("+")
			elseif ((key == string.byte('/')) and (get_shift_key_state() > 0)) then
				self:textfieldUpdate("?")
			elseif ((key == string.byte('\'')) and (get_shift_key_state() > 0)) then
				self:textfieldUpdate("\"")
			elseif ((key == string.byte(';')) and (get_shift_key_state() > 0)) then
				self:textfieldUpdate(":")
			elseif (key == 269) then
				self:textfieldUpdate("-")
			elseif (key == 267) then
				self:textfieldUpdate("/")
			elseif (key >= 97 and key <= 122 and (get_shift_key_state() > 0)) then
				self:textfieldUpdate(string.char(key - 32))
			elseif (key == 13 or key == 271) then
				if (not self.textfieldsingleline) then
					self:textfieldUpdate("\n")
				else
					return
				end
			elseif (key > 256 and key < 265) then
				self:textfieldUpdate(key - 256)
			elseif (key > 300) then
				return
			else
				self:textfieldUpdate(string.char(key))
			end
			self.textfieldindex = self.textfieldindex + 1
		end
	end	
			
	function UIElement:handleKeyUp(key)
		for i, v in pairs(tableReverse(UIKeyboardHandler)) do
			if (v.keyboard == true) then
				v.keyUp(key)
				return 1
			end
		end
	end
	
	function UIElement:handleKeyDown(key)
		for i, v in pairs(tableReverse(UIKeyboardHandler)) do
			if (v.keyboard == true) then
				KEYBOARDGLOBALIGNORE = true
				v.keyDown(key)
				return 1
			end
		end
	end
	
	function UIElement:handleMouseDn(s, x, y)
		enable_camera_movement()
		for i, v in pairs(UIKeyboardHandler) do 
			v.keyboard = false
			KEYBOARDGLOBALIGNORE = false
		end
		for i, v in pairs(tableReverse(UIMouseHandler)) do
			if (x > v.pos.x and x < v.pos.x + v.size.w and y > v.pos.y and y < v.pos.y + v.size.h and s < 4) then
				if (v.downSound) then
					play_sound(v.downSound)
				end
				v.hoverState = BTN_DN
				v.btnDown(s, x, y)
				if (v.textfield == true) then
					v.keyboard = true
					disable_camera_movement()
				end
				return
			elseif (s >= 4 and v.scrollEnabled == true) then
				v.btnDown(s, x, y)
			end
		end
	end
	
	function UIElement:handleMouseUp(s, x, y)
		for i, v in pairs(tableReverse(UIMouseHandler)) do
			if (v.hoverState == BTN_DN) then
				if (v.upSound) then
					play_sound(v.upSound)
				end
				v.hoverState = BTN_HVR
				v.btnUp(s, x, y)
				return
			end
		end
	end
	
	function UIElement:handleMouseHover(x, y)
		local disable = nil
		MOUSE_X, MOUSE_Y = x, y
		
		for i, v in pairs(tableReverse(UIMouseHandler)) do
			if (v.hoverState == BTN_DN) then
				disable = true
				v.btnHover(x,y)
			elseif (disable) then
				v.hoverState = false
			elseif (x > v.pos.x and x < v.pos.x + v.size.w and y > v.pos.y and y < v.pos.y + v.size.h) then
				if (v.hoverState == false and v.hoverSound) then
					play_sound(v.hoverSound)
				end
				if (v.hoverState ~= BTN_DN) then
					v.hoverState = BTN_HVR
					disable = true
				end
				v.btnHover(x,y)
			else
				v.hoverState = false
			end
		end
	end
	
	function UIElement:moveTo(x, y)
		if (self.parent) then
			if (x) then self.shift.x = x end
			if (y) then self.shift.y = y end
		else
			if (x) then self.pos.x = x end
			if (y) then self.pos.y = y end
		end
	end
	
	function UIElement:updateChildPos()
		if (self.parent.viewport) then
			return
		end
		if (self.shift.x < 0) then
			self.pos.x = self.parent.pos.x + self.parent.size.w + self.shift.x
		else
			self.pos.x = self.parent.pos.x + self.shift.x
		end
		if (self.shift.y < 0) then
			self.pos.y = self.parent.pos.y + self.parent.size.h + self.shift.y
		else
			self.pos.y = self.parent.pos.y + self.shift.y
		end
	end
	
	function UIElement:addAdaptedText(override, str, x, y, font, align, maxscale, minscale, intensity, shadow, col1, col2)
		local scale = maxscale or 1
		local minscale = minscale or 0.2
		local font = font
		
		while (not self:uiText(str, x, y, font, nil, scale, nil, nil, nil, nil, nil, true) and scale > minscale) do
			scale = scale - 0.05
			if (scale < 0.5 and font) then
				if (font == FONTS.BIG) then
					font = FONTS.MEDIUM
					scale = 1
					minscale = minscale * 2
				elseif (font == FONTS.BIGGER) then
					font = FONTS.BIG
					scale = 1
					minscale = minscale * 2
				end
			end
		end
		self:addCustomDisplay(override, function()
				self:uiText(str, x, y, font, align, scale, nil, shadow, col1, col2, intensity)
			end)
	end
	
	function UIElement:uiText(str, x, y, font, align, scale, angle, shadow, col1, col2, intensity, check, refresh)
		if (not scale and check) then
			echo("^04UIElement error: ^07uiText cannot take undefined scale argument with check enabled")
			return true
		end
		local font = font or FONTS.MEDIUM
		local x = x and self.pos.x + x or self.pos.x
		local y = y and self.pos.y + y or self.pos.y
		local font_mod = font
		local scale = scale or 1
		local angle = angle or 0
		local pos = 0
		local align = align or CENTERMID
		local check = check or false
		local refresh = refresh or false
		if (font == 2) then
			font_mod = 2.4
		elseif (font == 0) then
			font_mod = 5.6
		elseif (font == 4) then
			font_mod = 2.4
		elseif (font == 1) then
			font_mod = 1.5
		elseif (fonts == 9) then
			font_mod = 10
		end
	
		if (check) then
			str = textAdapt(str, font, scale, self.size.w)
		else
			local strunformatted = str
			str = self.str == strunformatted and self.dispstr or textAdapt(str, font, scale, self.size.w)
			self.str, self.dispstr = strunformatted, str
		end
		
		local startLine = 1
		if (self.textfield and font_mod * 10 * scale * #str > self.size.h) then
			local tfstrlen = 0
			for i, v in pairs(str) do
				tfstrlen = tfstrlen + v:len()
				if (self.textfieldindex < tfstrlen) then
					startLine = i - math.floor(self.size.h / font_mod / 10 / scale) + 1
					if (startLine < 1) then
						startLine = 1
					end
					break
				end
			end
		end
		
		for i = startLine, #str do
			local xPos = x
			local yPos = y
			if ((align + 2) % 3 == 0) then
				xPos = x + self.size.w / 2 - get_string_length(str[i], font) * scale / 2					
			elseif ((align + 1) % 3 == 0) then
				xPos = x + self.size.w - get_string_length(str[i], font) * scale
			end
			if (align >= 3 and align <= 5) then
				yPos = y + self.size.h - #str * font_mod * 10 * scale
				while (yPos < y and yPos + font_mod * 10 * scale < y + self.size.h) do
					yPos = yPos + font_mod * 10 * scale
				end
			elseif (align >= 6 and align <= 8) then
				yPos = y + (self.size.h - #str * font_mod * 10 * scale) / 2
				while (yPos < y and yPos + font_mod * 10 * scale < y + self.size.h) do
					yPos = yPos + font_mod * 5 * scale
				end
			end
			if (check == true and (self.size.w < get_string_length(str[i], font) * scale or self.size.h < font_mod * 10 * scale)) then
				return false
			elseif (self.size.h > (pos + 2) * font_mod * 10 * scale) then
				if (check == false) then
					draw_text_new(str[i], xPos, yPos + (pos * font_mod * 10 * scale), angle, scale, font, shadow, col1, col2, intensity)
				elseif (#str == i) then
					return true
				end
				pos = pos + 1
			elseif (i ~= #str) then
				if (check == true) then 
					return false
				end
				draw_text_new(str[i]:gsub(".$", "..."), xPos, yPos + (pos * font_mod * 10 * scale), angle, scale, font, shadow, col1, col2, intensity)
				break		
			else
				if (check == false) then
					draw_text_new(str[i], xPos, yPos + (pos * font_mod * 10 * scale), angle, scale, font, shadow, col1, col2, intensity)
				else
					return true
				end
			end			
		end
	end
	
	function UIElement:getButtonColor()
		if (self.hoverState == BTN_DN) then
			return self.pressedColor
		elseif (self.hoverState == BTN_HVR) then
			return self.animateColor
		else
			return self.bgColor
		end
	end
	
	function UIElement:getPos()
		local pos = {self.shift.x, self.shift.y}
		return pos
	end
	
	function UIElement:getLocalPos(xPos, yPos, pos)
		local pos = pos or { x = xPos, y = yPos}
		if (self.parent) then
			pos = self.parent:getLocalPos(xPos, yPos, pos)
			if (self.shift.x < 0) then
				pos.x = pos.x - self.parent.size.w - self.shift.x
			else
				pos.x = pos.x - self.shift.x
			end
			if (self.shift.y < 0) then
				pos.y = pos.y - self.parent.size.h - self.shift.y
			else
				pos.y = pos.y - self.shift.y
			end
		else
			pos.x = xPos - self.pos.x
			pos.y = yPos - self.pos.y
		end
		return pos
	end
	
	-- Used to update background texture
	-- Image can be either a string with texture path or a table where image[1] is a path and image[2] is default icon path
	function UIElement:updateImage(image, default, noreload)
		local default = default or DEFTEXTURE
		local filename
		if (image) then
			if (image:find("%.%./", 4)) then
				filename = image:gsub("%.%./%.%./", "")
			elseif (image:find("%.%./")) then
				filename = image:gsub("%.%./", "data/")
			else 
				filename = "data/script/" .. image:gsub("^/", "")
			end
		end
		
		if (not noreload and self.bgImage) then
			local count, id = 0, 0
			for i,v in pairs(TEXTURECACHE) do
				if (v == self.bgImage) then
					count = count + 1
					id = i
				end
			end
			if (count == 1) then
				unload_texture(self.bgImage)
				TEXTUREINDEX = TEXTUREINDEX - 1
			else
				table.remove(TEXTURECACHE, id)
			end		
			self.bgImage = nil		
		end
		
		if (not image) then
			return
		end
		
		if (TEXTUREINDEX > 254) then
			self.bgImage = load_texture(DEFTEXTURE)
			return false
		end
		
		local tempicon = io.open(filename, "r", 1)
		if (not tempicon) then
			local textureid = load_texture(default)
			self.bgImage = textureid
			TEXTUREINDEX = TEXTUREINDEX > textureid and TEXTUREINDEX or textureid
			table.insert(TEXTURECACHE, self.bgImage)
		else
			local textureid = load_texture(image)
			if (textureid == -1) then
				unload_texture(textureid)
				self.bgImage = load_texture(default)
			else
				self.bgImage = textureid
			end
			TEXTUREINDEX = TEXTUREINDEX > textureid and TEXTUREINDEX or textureid
			table.insert(TEXTURECACHE, self.bgImage)
			io.close(tempicon)
		end
	end
	
	function UIElement:runCmd(command, online, echo)
		local online = online and 1 or 0
		local echo = echo or false
		if (echo == false) then
			add_hook("console", "UIManagerSkipEcho", function(s,i)
					return 1
				end)
		end
		run_cmd(command, online)
		remove_hooks("UIManagerSkipEcho")
	end
	
	function UIElement:debugEcho(mixed, msg)
		local msg = msg and msg .. ": " or ""
		if (type(mixed) == "table") then
			echo("entering table " .. msg)
			for i,v in pairs(mixed) do
				UIElement:debugEcho(v, i)
			end
		elseif (type(mixed) == "boolean") then
			echo(msg .. (mixed and "true" or "false"))
		elseif (type(mixed) == "number" or type(mixed) == "string") then
			echo(msg .. mixed)
		end
	end
	
	function UIElement:qsort(arr, sort, desc)
		local a = {}
		local desc = desc and 1 or -1
		for i, v in pairs(arr) do 
			table.insert(a, v) 
		end
		table.sort(a, function(a,b)
				local val1 = a[sort] == 0 and b[sort] - desc or a[sort]
				local val2 = b[sort] == 0 and a[sort] - desc or b[sort]
				if (type(val1) == "string" or type(val2) == "string") then
					val1 = val1:lower()
					val2 = val2:lower()
				end
				if (type(val1) == "boolean") then
					val1 = val1 and 1 or -1
				end
				if (type(val2) == "boolean") then
					val2 = val2 and 1 or -1
				end
				if (desc == 1) then 
					return val1 > val2
				else 
					return val1 < val2
				end
			end)
		return a
	end
	
	function cloneTable(table)
		local newTable = {}
		for i,v in pairs(table) do
			if (type(v) == "table") then
				newTable[i] = cloneTable(v)
			else
				newTable[i] = v
			end
		end
		return newTable
	end
			
	function textAdapt(str, font, scale, maxWidth)
		local clockdebug = os.clock()
		
		local destStr = {}
		local newStr = ""
		-- Fix newlines, remove redundant spaces and ensure the string is in fact a string
		local str = string.gsub(str, "\\n", "\n")
		str = str:gsub("^%s*", "")
		str = str:gsub("%s*$", "")
		
		local attemptPrediction = font == FONTS.SMALL and true or false
		
		local newline = false
		while (str ~= "") do
			if (not attemptPrediction or newStr ~= "") then
				-- Match words followed by newlines separately to allow newline spacing
				word = str:match("^[^\n]*%S*[^\n]*\n") or str:match("^%s*%S+%s*")
			else
				-- Attempt to guess the beginning of a string
				word = str:sub(1, math.floor(maxWidth / 8 * scale))
				word = word:gsub("%s+%S+$", "")
				word = word:gsub("[\n].*$", "")
				if (get_string_length(word, font) * scale > maxWidth) then
					-- Incorrect guess, start building classic way
					word = str:match("^[^\n]*%S*[^\n]*\n") or str:match("^%s*%S+%s*")
				end	
			end
			
			-- Wrap word around if it still exceeds text field width
			while (get_string_length(word, font) * scale > maxWidth) do
				word = word:sub(1, word:len() - 1)
			end
			
			if ((get_string_length(newStr .. word, font) * scale > maxWidth or newline) and newStr ~= "") then
				table.insert(destStr, newStr)
				newline = false
				newStr = word
				str = str:sub(word:len() + 1)
			else
				newStr = newStr .. word
				str = str:sub(word:len() + 1)
			end
			local nextNewline = word:match("\n") or word:match("\\n")
			if (nextNewline) then
				newline = true
			end
		end
		table.insert(destStr, newStr)
		
		local clockdebugend = os.clock()
		if (TB_MENU_DEBUG and clockdebugend - clockdebug > 0.01) then
			echo("Warning: slow text adapt call on string " .. destStr[1]:sub(1, 10) .. " - " .. clockdebugend - clockdebug .. " seconds")
		end
		
		return destStr
	end
	
	function draw_text_new(str, xPos, yPos, angle, scale, font, shadow, col1, col2, intensity)
		local shadow = shadow or nil
		local xPos = math.floor(xPos)
		local yPos = math.floor(yPos)
		local col1 = col1 or DEFTEXTCOLOR
		local col2 = col2 or DEFSHADOWCOLOR
		local intensity = intensity or col1[4]
		if (shadow) then
			set_color(unpack(col2))
			draw_text_angle_scale(str, xPos - shadow, yPos, angle, scale, font)
			draw_text_angle_scale(str, xPos - shadow, yPos - shadow, angle, scale, font)
			draw_text_angle_scale(str, xPos - shadow, yPos + shadow, angle, scale, font)
			draw_text_angle_scale(str, xPos + shadow, yPos, angle, scale, font)
			draw_text_angle_scale(str, xPos + shadow, yPos - shadow, angle, scale, font)
			draw_text_angle_scale(str, xPos + shadow, yPos + shadow, angle, scale, font)
			draw_text_angle_scale(str, xPos, yPos - shadow, angle, scale, font)
			draw_text_angle_scale(str, xPos, yPos + shadow, angle, scale, font)
			set_color(col2[1], col2[2], col2[3], col2[4] * 2)
			draw_text_angle_scale(str, xPos + shadow * 2, yPos + shadow * 2, angle, scale, font)
			draw_text_angle_scale(str, xPos + shadow * 2, yPos + shadow * 2, angle, scale, font)
		end
		if (col1) then
			set_color(unpack(col1))
		end
		draw_text_angle_scale(str, xPos, yPos, angle, scale, font)
		if (font == 2 or font == 0 or font == 9) then
			set_color(col1[1], col1[2], col1[3], intensity)
			draw_text_angle_scale(str, xPos, yPos, angle, scale, font)
		end
	end
	
	function tableReverse(tbl)
		local tblRev = {}
		for i, v in pairs(tbl) do
			table.insert(tblRev, 1, v)
		end
		return tblRev
	end
	
	function strEsc(str)
		local str = str
		
		-- escape % symbols
		str = str:gsub("%%", "%%%%")
		
		-- escape other single special characters
		local chars = ".+-*?^$"
		for i = 1, #chars do
			local char = "%" .. chars:sub(i, i)
			str = str:gsub(char, "%" .. char)
		end
		
		-- escape paired special characters
		local paired = { {"%[", "%]"}, { "%(", "%)" } }
		for i,v in pairs(paired) do
			local count = 0
			for j, k in pairs(v) do
				if (str:find(k)) then
					count = count + 1
				end
			end
			if (count == 2) then
				for j, k in pairs(v) do
					str = str:gsub(k, "%" .. k)
				end
			end
		end	
		return str
	end
end