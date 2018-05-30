-- 3D UI class
dofile('toriui/uielement.lua')

CUBE = 1
SPHERE = 2
CYLINDER = 3

TORI = 0
UKE = 1

do
	UIElement3DManager = UIElement3DManager or {}
	UIVisual3DManager = UIVisual3DManager or {}
	
	if (not UIElement3D) then 
		UIElement3D = UIElement:new()
	end
	
	function UIElement3D:new(o)
		local elem = {
			parent = nil,
			child = {},
			pos = {},
			shift = {},
			bgColor = { 1, 1, 1, 1 },
			shapeType = CUBE,
			customDisplay = function() end
		}
		setmetatable(elem, UIElement3D)
		self.__index = self
		
		o = o or nil
		if (o) then
			if (o.playerAttach) then
				elem.playerAttach = o.playerAttach
				elem.attachBodypart = o.attachBodypart
			end
			if (o.parent) then
				elem.parent = o.parent
				table.insert(elem.parent.child, elem)
				elem.shift = { x = o.pos[1], y = o.pos[2], z = o.pos[3] }
				if (o.rot) then
					elem.relrot = { x = o.rot[1], y = o.rot[2], z = o.rot[3] }
				else
					elem.relrot = { x = 0, y = 0, z = 0 }
				end
				for i,v in pairs(elem.shift) do
					if (v < 0) then
						elem.pos[i] = elem.parent.pos[i] + elem.shift[i]
					else
						elem.pos[i] = elem.parent.pos[i] + elem.shift[i]
					end
				end
			else
				elem.pos = { x = o.pos[1], y = o.pos[2], z = o.pos[3] }
			end
			elem.size = { x = o.size[1], y = o.size[2], z = o.size[3] }
			if (o.rot) then
				elem.rot = { x = o.rot[1], y = o.rot[2], z = o.rot[3] }
			else
				elem.rot = { x = 0, y = 0, z = 0 }
			end
			if (o.bgColor) then
				elem.bgColor = o.bgColor
			end
			if (o.hoverColor) then
				elem.hoverColor = o.hoverColor
			end
			if (o.pressedColor) then
				elem.pressedColor = o.pressedColor
			end
			if (o.shapeType) then
				elem.shapeType = o.shapeType
			end
			if (o.interactive) then
				elem.interactive = o.interactive
				table.insert(UIMouseHandler, elem)
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
			
			table.insert(UIElement3DManager, elem)
			table.insert(UIVisual3DManager, elem)
		end
		
		return elem
	end
	
	function UIElement3D:kill(childOnly)
		for i,v in pairs(self.child) do
			v:kill()
		end
		if (childOnly) then
			self.child = {}
			return true
		end
		
		for i,v in pairs(UIMouseHandler) do
			if (self == v) then
				table.remove(UIMouseHandler, i)
				break
			end
		end
		for i,v in pairs(UIVisual3DManager) do
			if (self == v) then
				table.remove(UIVisual3DManager, i)
				break
			end
		end
		for i,v in pairs(UIElement3DManager) do
			if (self == v) then
				table.remove(UIElement3DManager, i)
				break
			end
		end
		self = nil
	end
	
	function UIElement3D:display()
		if (self.hoverState ~= false and self.hoverColor) then
			for i = 1, 4 do
				if ((self.bgColor[i] > self.hoverColor[i] and self.animateColor[i] > self.hoverColor[i]) or (self.bgColor[i] < self.hoverColor[i] and self.animateColor[i] < self.hoverColor[i])) then
					self.animateColor[i] = self.animateColor[i] - math.floor((self.bgColor[i] - self.hoverColor[i]) * 150) / 1000
				end
			end
		else
			if (self.animateColor) then
				for i = 1, 4 do
					self.animateColor[i] = self.bgColor[i]
				end
			end
		end
		if (self.customDisplayBefore) then
			self.customDisplay()
		end
		if (not self.customDisplayTrue) then
			if (self.hoverState == BTN_HVR and self.hoverColor) then
				set_color(unpack(self.animateColor))
			elseif (self.hoverState == BTN_DN and self.pressedColor) then
				set_color(unpack(self.pressedColor))
			else
				set_color(unpack(self.bgColor))
			end
			if (self.shapeType == CUBE) then
				if (self.playerAttach) then
					local body = get_body_info(self.playerAttach, self.attachBodypart)
					draw_box_m(body.pos.x + self.pos.x, body.pos.y + self.pos.y, body.pos.z + self.pos.z, self.size.x, self.size.y, self.size.z, body.rot)
				else
					draw_box(self.pos.x, self.pos.y, self.pos.z, self.size.x, self.size.y, self.size.z, self.rot.x, self.rot.y, self.rot.z)
				end
			elseif (self.shapeType == SPHERE) then
				if (self.playerAttach) then
					local body = get_body_info(self.playerAttach, self.attachBodypart)
			        draw_sphere_m(body.pos.x, body.pos.y, body.pos.z, self.size.x, body.rot)
				else
					draw_sphere(self.pos.x, self.pos.y, self.pos.z, self.size.x)
				end
			elseif (self.shapeType == CYLINDER) then
				if (self.playerAttach) then
					local body = get_body_info(self.playerAttach, self.attachBodypart)					
			        draw_capsule_m(body.pos.x, body.pos.y, body.pos.z, self.size.y, self.size.x, body.rot)
				else
					draw_capsule(self.pos.x, self.pos.y, self.pos.z, self.size.y, self.size.x, self.rot.x, self.rot.y, self.rot.z)
				end
			end
		end
		if (not self.customDisplayBefore) then
			self.customDisplay()
		end
	end
	
	function UIElement3D:show(forceReload)
		local num = nil
		
		if (self.noreload and not forceReload) then
			return false
		elseif (forceReload) then
			self.noreload = nil
		end
		
		for i,v in pairs(UIVisual3DManager) do
			if (self == v) then
				num = i
				break
			end
		end
		
		if (not num) then
			table.insert(UIVisual3DManager, self)
			if (self.interactive) then
				table.insert(UIMouseHandler, self)
			end
		end
		
		for i,v in pairs(self.child) do
			v:show()
		end
	end
	
	function UIElement3D:hide(noreload)
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
			else
				err(UIMouseHandlerEmpty)
			end
		end
		
		for i,v in pairs(UIVisual3DManager) do
			if (self == v) then
				num = i
				break
			end
		end
		
		if (num) then
			table.remove(UIVisual3DManager, num)
		else
			err(UIElementEmpty)
		end
	end
	
	
	function UIElement3D:moveTo(x, y, z)
		if (self.playerAttach) then
			return
		end
		if (self.parent) then
			if (x) then self.shift.x = x end
			if (y) then self.shift.y = y end
			if (z) then self.shift.z = z end
		else
			if (x) then self.pos.x = x end
			if (y) then self.pos.y = y end
			if (z) then self.pos.y = z end
		end
	end
	
	function UIElement3D:rotate(x, y, z)
		local x = x or 0
		local y = y or 0
		local z = z or 0
		local rot = self.rot
		if (self.parent) then
			rot = self.relrot
		end
		rot.x = (rot.x + x) % 360
		rot.y = (rot.y + y) % 360
		rot.z = (rot.z + z) % 360
		
		local max = math.max(rot.x, rot.y, rot.z)
		x = rot.x / max
		y = rot.y / max
		z = rot.z / max
		local angle = math.rad(max)
		
		self.vector = { u = x, v = y, w = z, angle = angle }
	end
	
	function UIElement3D:setupRotMatrix(vector)
		local u2 = vector.u * vector.u
		local v2 = vector.v * vector.v
		local w2 = vector.w * vector.w
		local l = u2 + v2 + w2
		local angle = vector.angle
		local rotationMatrix = {}
		
		local rotationRow1 = {}
		rotationRow1[1] = (u2 + (v2 + w2) * math.cos(angle)) / l
		rotationRow1[2] = (vector.u * vector.v * (1 - math.cos(angle)) - vector.w * math.sqrt(l) * math.sin(angle)) / l
    	rotationRow1[3] = (vector.u * vector.w * (1 - math.cos(angle)) + vector.v * math.sqrt(l) * math.sin(angle)) / l
    	rotationRow1[4] = 0.0
		
		local rotationRow2 = {}
	    rotationRow2[1] = (vector.u * vector.v * (1 - math.cos(angle)) + vector.w * math.sqrt(l) * math.sin(angle)) / l
	    rotationRow2[2] = (v2 + (u2 + w2) * math.cos(angle)) / l
	    rotationRow2[3] = (vector.v * vector.w * (1 - math.cos(angle)) - vector.u * math.sqrt(l) * math.sin(angle)) / l
	    rotationRow2[4] = 0.0;

		local rotationRow3 = {}
	    rotationRow3[1] = (vector.u * vector.w * (1 - math.cos(angle)) - vector.v * math.sqrt(l) * math.sin(angle)) / l
	    rotationRow3[2] = (vector.v * vector.w * (1 - math.cos(angle)) + vector.u * math.sqrt(l) * math.sin(angle)) / l
	    rotationRow3[3] = (w2 + (u2 + v2) * math.cos(angle)) / l
	    rotationRow3[4] = 0.0;

		local rotationRow4 = {}
	    rotationRow4[1] = 0.0
	    rotationRow4[2] = 0.0
	    rotationRow4[3] = 0.0
	    rotationRow4[4] = 1.0
		
		rotationMatrix[1] = rotationRow1
		rotationMatrix[2] = rotationRow2
		rotationMatrix[3] = rotationRow3
		rotationMatrix[4] = rotationRow4
		
		return rotationMatrix
	end
	
	function UIElement3D:updateChildRot()
		local rotMatrix = UIElement3D:setupRotMatrix(self.parent.vector)
		local newPos = UIElement3D:multiply({ { self.shift.x, self.shift.y, self.shift.z, 1 } }, rotMatrix)
		local vector = newPos[1]
		echo("x angle: " .. self.parent.rot.x .. "; pos " .. vector[1])
		echo("y angle: " .. self.parent.rot.y .. "; pos " .. vector[2])
		echo("z angle: " .. self.parent.rot.z .. "; pos " .. vector[3])
		self.pos.x = self.parent.pos.x + vector[1]
		self.pos.y = self.parent.pos.y + vector[2]
		self.pos.z = self.parent.pos.z + vector[3]
		self.rot.x = self.parent.rot.x + self.relrot.x
		self.rot.y = self.parent.rot.y + self.relrot.y
		self.rot.z = self.parent.rot.z + self.relrot.z
	end
	
	function UIElement3D:updateChildPos()
		if (self.parent.vector) then
			self:updateChildRot()
--[[			if (self.parent.rotMatrix.x ~= 0) then
				local rotated = { x = self.shift.x, y = self.shift.y, z = self.shift.z }
				local angle = (self.parent.rot.x / 180 * math.pi) % (math.pi * 2)
				rotated.y = shift.y * math.cos(angle) + shift.z * math.sin(angle)
				rotated.z = shift.z * math.cos(angle) - shift.y * math.sin(angle)
				self.rot.x = self.rot.x + self.parent.rotMatrix.x
				shift = rotated
			end
			if (self.parent.rotMatrix.y ~= 0) then
				local rotated = { x = self.shift.x, y = self.shift.y, z = self.shift.z }
				local angle = (self.parent.rot.y / 180 * math.pi) % (math.pi * 2)
				rotated.x = shift.x * math.cos(angle) - shift.z * math.sin(angle)
				rotated.z = shift.z * math.cos(angle) + shift.x * math.sin(angle)
				self.rot.y = self.rot.y + self.parent.rotMatrix.y
				shift = rotated
			end
			if (self.parent.rotMatrix.z ~= 0) then
				local rotated = { x = self.shift.x, y = self.shift.y, z = self.shift.z }
				local angle = (self.parent.rot.z / 180 * math.pi) % (math.pi * 2)
				rotated.x = shift.x * math.cos(angle) - shift.y * math.sin(angle)
				rotated.y = shift.y * math.cos(angle) + shift.x * math.sin(angle)
				self.rot.z = self.rot.z + self.parent.rotMatrix.z
				shift = rotated
			end
			self.pos.x = self.parent.pos.x + shift.x
			self.pos.y = self.parent.pos.y + shift.y
			self.pos.z = self.parent.pos.z + shift.z]]
		end
	end
	
	--[[function UIElement3D:updateChildPos()
		if (self.playerAttach) then
			return
		end
		if (self.parent.lastRot) then
			if (self.parent.rot.x ~= self.parent.lastRot.x) then
				local rotMod = (self.parent.rot.x / 180 * math.pi) % (math.pi * 2)
				modified.z = modified.z + (self.parent.size.x + self.shift.z / 2 + self.shift.y / 2) * math.cos(rotMod)
				modified.y = modified.y + (self.parent.size.x + self.shift.z / 2 + self.shift.y / 2) * math.sin(rotMod)
				self.rot.x = self.parent.rot.x + self.relrot.x
			end
			--echo(self.pos.x .. " " .. self.pos.y .. " " .. self.pos.z)
			if (self.parent.rot.y ~= self.parent.lastRot.y) then
				local rotMod = (self.parent.rot.y / 180 * math.pi) % (math.pi * 2)
				modified.x = modified.x + (self.parent.size.y + self.shift.x / 2 + self.shift.z / 2) * math.sin(rotMod)
				modified.z = modified.z + (self.parent.size.y + self.shift.x / 2 + self.shift.z / 2) * math.cos(rotMod)
				self.rot.y = self.parent.rot.y + self.relrot.y
			end
			self.pos.x = self.parent.pos.x + modified.x
			self.pos.y = self.parent.pos.y + modified.y
			self.pos.z = self.parent.pos.z + modified.z
			--echo(self.pos.x .. " " .. self.pos.y .. " " .. self.pos.z)
		end
	end]]
	
	function UIElement3D:multiply(a, b)
		if (#a[1] ~= #b) then
			return false
		end
		
		local matrix = {}
		
		for aRow = 1, #a do
			matrix[aRow] = {}
			for bCol = 1, #b[1] do
				local sum = matrix[aRow][bCol] or 0
				for bRow = 1, #b do
					sum = sum + a[aRow][bRow] * b[bRow][bCol]
				end
				matrix[aRow][bCol] = sum
			end
		end
		
		return matrix
	end
end