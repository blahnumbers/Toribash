require('toriui.uielement')

CUBE = 1
SPHERE = 2
CAPSULE = 3
CUSTOMOBJ = 4
VIEWPORT = 5

TORI = 0
UKE = 1

OBJMODELCACHE = OBJMODELCACHE or {}
OBJMODELINDEX = OBJMODELINDEX or 0

---@type UIElement3D[]
UIElement3DManager = UIElement3DManager or {}
---@type UIElement3D[]
UIVisual3DManager = UIVisual3DManager or {}
---@type UIElement3D[]
UIVisual3DManagerViewport = UIVisual3DManagerViewport or {}

if (not UIElement3D) then
	UIElement3D = {
		ver = 5.60,
		__index = UIElement
	}
	setmetatable(UIElement3D, UIElement)
end

function UIElement3D:new(o)
	local elem = {
		globalid = 0,
		parent = nil,
		child = {},
		rotXYZ = { x = 0, y = 0, z = 0 },
		pos = {},
		shift = {},
		bgColor = { 1, 1, 1, 1 },
		shapeType = CUBE
	}
	setmetatable(elem, UIElement3D)
	self.__index = self

	o = o or nil
	if (o) then
		if (o.playerAttach) then
			elem.playerAttach = o.playerAttach
			elem.attachBodypart = o.attachBodypart
			elem.attachJoint = o.attachJoint
		end
		if (o.parent and o.shapeType ~= VIEWPORT) then
			elem.globalid = o.parent.globalid
			elem.parent = o.parent
			table.insert(elem.parent.child, elem)
			elem.shift = { x = o.pos[1], y = o.pos[2], z = o.pos[3] }
			elem.rotXYZ = { x = elem.parent.rotXYZ.x, y = elem.parent.rotXYZ.y, z = elem.parent.rotXYZ.z }
			elem:setChildShift()
			for i,v in pairs(elem.shift) do
				elem.pos[i] = elem.parent.pos[i] + elem.shift[i]
			end
		else
			if (o.shapeType == VIEWPORT) then
				elem.viewport = o.parent
				table.insert(elem.viewport.child, elem)
			end
			elem.pos = { x = o.pos[1], y = o.pos[2], z = o.pos[3] }
		end
		elem.size = { x = o.size[1], y = o.size[2], z = o.size[3] }
		if (o.rot) then
			elem.rotXYZ.x = elem.rotXYZ.x + o.rot[1]
			elem.rotXYZ.y = elem.rotXYZ.y + o.rot[2]
			elem.rotXYZ.z = elem.rotXYZ.z + o.rot[3]
		end
		elem:updateRotations(elem.rotXYZ)
		if (o.objModel) then
			elem.shapeType = CUSTOMOBJ
			elem.disableUnload = o.disableUnload
			elem:updateObj(o.objModel)
		end
		if (o.bgImage) then
			if (type(o.bgImage) == "table") then
				elem:updateImage(o.bgImage[1], o.bgImage[2])
			else
				elem:updateImage(o.bgImage)
			end
		end
		if (o.globalid) then
			elem.globalid = o.globalid
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
		if (o.effects) then
			elem.effectid = o.effects.id or 0
			elem.glowIntensity = o.effects.glowIntensity or 0
			elem.glowColor = o.effects.glowColor or 0
			elem.ditherPixelSize = o.effects.ditherPixelSize or 0
		end

		table.insert(UIElement3DManager, elem)
		if (o.viewport) then
			elem.viewportElement = true
			table.insert(UIVisual3DManagerViewport, elem)
		else
			table.insert(UIVisual3DManager, elem)
		end
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

	if (self.bgImage) then self:updateImage(nil) end
	if (self.objModel) then self:updateObj(nil) end
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
	for i,v in pairs(UIVisual3DManagerViewport) do
		if (self == v) then
			table.remove(UIVisual3DManagerViewport, i)
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

function UIElement3D:addCustomEnterFrame(func)
	self.customEnterFrameFunc = func
	func()
end

function UIElement3D:display()
	if (self.effectid) then
		set_draw_effect(self.effectid, self.glowColor, self.glowIntensity, self.ditherPixelSize)
	end
	if (self.viewport) then
		set_viewport(self.viewport.pos.x, self.viewport.pos.y, self.viewport.size.w, self.viewport.size.h)
		return
	end
	if (self.hoverState ~= BTN_NONE and self.hoverColor) then
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
		self.customDisplayBefore()
	end
	if (not self.customDisplayOnly) then
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
				self:drawBox()
			end
		elseif (self.shapeType == SPHERE) then
			if (self.playerAttach) then
				if (self.attachBodypart) then
					local body = get_body_info(self.playerAttach, self.attachBodypart)
					draw_sphere_m(body.pos.x + self.pos.x, body.pos.y + self.pos.y, body.pos.z + self.pos.z, self.size.x, body.rot)
				elseif (self.attachJoint) then
					local joint = get_joint_pos2(self.playerAttach, self.attachJoint)
					local radius = get_joint_radius(self.playerAttach, self.attachJoint)
					self:drawSphere(joint, radius)
				end
			else
				self:drawSphere()
			end
		elseif (self.shapeType == CAPSULE) then
			if (self.playerAttach) then
				if (self.attachBodypart) then
					local body = get_body_info(self.playerAttach, self.attachBodypart)
					draw_capsule_m(body.pos.x, body.pos.y, body.pos.z, self.size.y, self.size.x, body.rot)
				elseif (self.attachJoint) then
					local joint = get_joint_pos2(self.playerAttach, self.attachJoint)
					draw_capsule(joint.x, joint.y, joint.z, self.size.y, self.size.x, self.rot.x, self.rot.y, self.rot.z)
				end
			else
				self:drawCapsule()
			end
		elseif (self.shapeType == CUSTOMOBJ and self.objModel ~= nil) then
			draw_obj(self.objModel, self.pos.x, self.pos.y, self.pos.z, self.size.x, self.size.y, self.size.z, self.rot.x, self.rot.y, self.rot.z)
		end
	end
	if (self.customDisplay) then
		self.customDisplay()
	end
	if (self.effectid) then
		set_draw_effect(0)
	end
end

function UIElement3D:drawBox()
	if (self.bgImage) then
		draw_box(self.pos.x, self.pos.y, self.pos.z, self.size.x, self.size.y, self.size.z, self.rot.x, self.rot.y, self.rot.z, self.bgImage)
	else
		draw_box(self.pos.x, self.pos.y, self.pos.z, self.size.x, self.size.y, self.size.z, self.rot.x, self.rot.y, self.rot.z)
	end
end

function UIElement3D:drawCapsule()
	if (self.bgImage) then
		draw_capsule(self.pos.x, self.pos.y, self.pos.z, self.size.y, self.size.x, self.rot.x, self.rot.y, self.rot.z, self.bgImage)
	else
		draw_capsule(self.pos.x, self.pos.y, self.pos.z, self.size.y, self.size.x, self.rot.x, self.rot.y, self.rot.z)
	end
end

function UIElement3D:drawSphere(displaceTable, scale)
	local drawPos = cloneTable(self.pos)
	local scale = scale or 1
	if (displaceTable) then
		drawPos.x = displaceTable.x
		drawPos.y = displaceTable.y
		drawPos.z = displaceTable.z
	end
	if (self.bgImage) then
		draw_sphere(drawPos.x, drawPos.y, drawPos.z, self.size.x * scale, self.rot.x, self.rot.y, self.rot.z, self.bgImage)
	else
		draw_sphere(drawPos.x, drawPos.y, drawPos.z, self.size.x * scale)
	end
end

function UIElement3D:drawVisuals(globalid)
	for i, v in pairs(UIVisual3DManager) do
		if (v.globalid == globalid) then
			v:display()
		end
	end
end

function UIElement3D:drawViewport(globalid)
	for i, v in pairs(UIVisual3DManagerViewport) do
		if (v.globalid == globalid) then
			v:display()
		end
	end
end

function UIElement3D:playFrameFunc(globalid)
	for i,v in pairs(UIVisual3DManager) do
		if (v.globalid == globalid) then
			if (v.customEnterFrameFunc ~= nil) then
				v.customEnterFrameFunc()
			end
		end
	end
end

function UIElement3D:isDisplayed()
	if (not self.viewportElement) then
		for i,v in pairs(UIVisual3DManager) do
			if (self == v) then
				return true
			end
		end
	else
		for i,v in pairs(UIVisual3DManagerViewport) do
			if (self == v) then
				return true
			end
		end
	end
	return false
end

function UIElement3D:show(forceReload)
	local num = nil

	if (self.noreload and not forceReload) then
		return false
	elseif (forceReload) then
		self.noreload = nil
	end

	for i,v in pairs(self.viewportElement and UIVisual3DManagerViewport or UIVisual3DManager) do
		if (self == v) then
			num = i
			break
		end
	end

	if (not num) then
		table.insert(self.viewportElement and UIVisual3DManagerViewport or UIVisual3DManager, self)
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
		end
	end

	for i,v in pairs(self.viewportElement and UIVisual3DManagerViewport or UIVisual3DManager) do
		if (self == v) then
			num = i
			break
		end
	end

	if (num) then
		table.remove(self.viewportElement and UIVisual3DManagerViewport or UIVisual3DManager, num)
	end
end

function UIElement3D:updatePos()
	for i,v in pairs(self.child) do
		v:updateChildPos()
	end
end

function UIElement3D:setChildShift()
	local rotMatrix = self.parent.rotMatrix
	local pos = self.parent.pos
	local shift = self.shift

	local rotatedShift = UIElement3D.multiply({ { shift.x, shift.y, shift.z } }, rotMatrix)
	if (rotatedShift) then
		local newShift = rotatedShift[1]

		self.shift.x = newShift[1]
		self.shift.y = newShift[2]
		self.shift.z = newShift[3]
	end
end

function UIElement3D:updateChildPos(rotMatrix, pos, shift)
	local rotMatrix = rotMatrix or self.parent.rotMatrix
	local pos = pos or self.parent.pos
	local shift = shift and { x = shift.x + self.shift.x, y = shift.y + self.shift.y, z = shift.z + self.shift.z } or self.shift

	local newPos = UIElement3D.multiply({ { shift.x, shift.y, shift.z } }, rotMatrix)
	local shiftSum = shift
	if (newPos) then
		local vector = newPos[1]

		shiftSum = shift or {
			x = vector[1],
			y = vector[2],
			z = vector[3]
		}

		self.pos.x = pos.x + vector[1]
		self.pos.y = pos.y + vector[2]
		self.pos.z = pos.z + vector[3]
	end

	for i,v in pairs(self.child) do
		v:updateChildPos(rotMatrix, pos, shiftSum)
	end
end

function UIElement3D:moveTo(x, y, z)
	if (self.playerAttach) then
		return
	end
	if (self.parent) then
		if (x) then self.shift.x = self.shift.x + x end
		if (y) then self.shift.y = self.shift.y + y end
		if (z) then self.shift.z = self.shift.z + z end
	else
		if (x) then self.pos.x = self.pos.x + x end
		if (y) then self.pos.y = self.pos.y + y end
		if (z) then self.pos.y = self.pos.z + z end
	end
	self:updateChildPos()
end

function UIElement3D:rotate(x, y, z)
	local x = x or 0
	local y = y or 0
	local z = z or 0
	if (x == 0 and y == 0 and z == 0) then
		return
	end

	local rot = self.rotXYZ
	rot.x = (rot.x + x) % 360
	rot.y = (rot.y + y) % 360
	rot.z = (rot.z + z) % 360
	self:updateRotations(rot)

	for i,v in pairs(self.child) do
		v:rotate(x, y, z)
	end
	self:updatePos()
end

function UIElement3D:updateRotations(rot)
	self.rotMatrix = UIElement3D.getRotMatrixFromEulerAngles(math.rad(rot.x), math.rad(rot.y), math.rad(rot.z), "xyz")
	local relX, relY, relZ = UIElement3D.getEulerZYXFromRotationMatrix(self.rotMatrix)
	self.rot = { x = relX, y = relY, z = relZ }
end

function UIElement3D.getEulerZYXFromRotationMatrix(R)
	local clamp = R[3][1] > 1 and 1 or (R[3][1] < -1 and -1 or R[3][1])
	local x, y, z

	y = math.asin(-clamp)
	if (0.99999 > math.abs(R[3][1])) then
		x = math.atan2(R[3][2], R[3][3])
		z = math.atan2(R[2][1], R[1][1])
	else
		x = 0
		z = math.atan2(-R[1][2], R[2][2])
	end
	return math.deg(x), math.deg(y), math.deg(z)
end

function UIElement3D.getEulerXYZFromRotationMatrix(R)
	local x, y, z

	x = math.atan2(-R[2][3], R[3][3])
	y = math.atan2(R[1][3], R[3][3] * math.cos(x) - R[2][3] * math.sin(x))
	z = math.atan2(R[2][1] * math.cos(x) + R[3][1] * math.sin(x), R[2][2] * math.cos(x) + R[3][2] * math.sin(x))

	return math.deg(x), math.deg(y), math.deg(z)
end

---Makes sure the provided table is a Toribash rotation table
---@param rTB Matrix4x4|number[]
---@return Matrix4x4
function UIElement3D.verifyRotMatrixTB(rTB)
	if (rTB.r0 ~= nil) then
		return rTB
	end
	return {
		r0 = rTB[1],	r1 = rTB[2],	r2 = rTB[3],	r3 = rTB[4],
		r4 = rTB[5],	r5 = rTB[6],	r6 = rTB[7],	r7 = rTB[8],
		r8 = rTB[9],	r9 = rTB[10],	r10 = rTB[11],	r11 = rTB[12],
		r12 = 0,		r13 = 0,		r14 = 0,		r15 = 1
	}
end

function UIElement3D.getEulerAnglesFromMatrixTB(rTB)
	local rTB = UIElement3D.verifyRotMatrixTB(rTB)
	return UIElement3D.getEulerZYXFromRotationMatrix({
		{ rTB.r0, rTB.r1, rTB.r2, rTB.r3 },
		{ rTB.r4, rTB.r5, rTB.r6, rTB.r7 },
		{ rTB.r8, rTB.r9, rTB.r10, rTB.r11 },
		{ rTB.r12, rTB.r13, rTB.r14, rTB.r15 },
	})
end

function UIElement3D.getRotMatrixFromEulerAngles(x, y, z, order)
	local order = order or "xyz"
	local c1 = math.cos(x)
	local s1 = math.sin(x)
	local c2 = math.cos(y)
	local s2 = math.sin(y)
	local c3 = math.cos(z)
	local s3 = math.sin(z)

	local R
	if (order == 'xyz') then
		R = {
			{ c2 * c3, -c2 * s3, s2 },
			{ c1 * s3 + c3 * s1 * s2, c1 * c3 - s1 * s2 * s3, -c2 * s1 },
			{ s1 * s3 - c1 * c3 * s2, c3 * s1 + c1 * s2 * s3, c1 * c2 }
		}
	elseif (order == 'zyx') then
		R = {
			{ c1 * c2, c1 * s2 * s3 - c3 * s1, s1 * s3 + c1 * c3 * s2 },
			{ c2 * s1, c1 * c3 + s1 * s2 * s3, c3 * s1 * s2 - c1 * s3 },
			{-s2, c2 * s3, c2 * c3 }
		}
	end

	return R
end

function UIElement3D.multiplyByNumber(a, b)
	local matrix = {}
	for i,v in pairs(a) do
		matrix[i] = {}
		for j,k in pairs(v) do
			matrix[i][j] = k * b
		end
	end
	return matrix
end

function UIElement3D.multiply(a, b)
	if (type(b) == 'number') then
		return UIElement3D.multiplyByNumber(a, b)
	end
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

function UIElement:updateObj(model, noreload)
	require("system.iofiles")
	local filename = ''
	local absPath = true
	if (model) then
		if (model:find("%.%./", 4)) then
			filename = model:gsub("%.%./%.%./", "")
		elseif (model:find("%.%./")) then
			filename = model:gsub("%.%./", "data/")
		else
			filename = "data/script/" .. model:gsub("^/", "")
			absPath = false
		end
	end

	if (not noreload and self.objModel and not self.disableUnload) then
		local id = 0
		for i,v in pairs(OBJMODELCACHE) do
			if (i == self.objModel) then
				id = i
				break
			end
		end
		OBJMODELCACHE[id].count = OBJMODELCACHE[id].count - 1
		if (OBJMODELCACHE[id].count == 0) then
			unload_obj(self.objModel)
			OBJMODELCACHE[id] = nil
			OBJMODELINDEX = OBJMODELINDEX - 1
		end
		self.objModel = nil
	end

	if (not model) then
		return true
	end

	local objFile = Files:open("../" .. filename .. ".obj")
	if (not objFile.data) then
		return false
	end
	objFile:close()

	local objid = 0
	for i = 0, 127 do
		if (OBJMODELCACHE[i]) then
			if (OBJMODELCACHE[i].name == filename) then
				self.objModel = i
				OBJMODELCACHE[i].count = OBJMODELCACHE[i].count + 1
				return true
			end
		end
	end
	if (OBJMODELINDEX > 126) then
		return false
	end
	for i = 0, 127 do
		if (not OBJMODELCACHE[i]) then
			objid = i
			break
		end
	end
	-- We don't yet know the exact build version when it'd be supported
	-- Require the first build of 2023
	if (tonumber(BUILD_VERSION) > 221020) then
		if (load_obj(objid, filename, 1)) then
			self.objModel = objid
		end
	else
		if (load_obj(objid, model)) then
			self.objModel = objid
		end
	end
	OBJMODELCACHE[objid] = { name = filename, count = 1 }
	OBJMODELINDEX = OBJMODELINDEX + 1
	return true
end
