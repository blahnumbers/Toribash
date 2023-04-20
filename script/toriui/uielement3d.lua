require('toriui.uielement')

---@alias UIElement3DShape
---| 1 CUBE
---| 2 SPHERE
---| 3 CAPSULE
---| 4 CUSTOMOBJ
---| 5 VIEWPORT
CUBE = 1
SPHERE = 2
CAPSULE = 3
CUSTOMOBJ = 4
VIEWPORT = 5

---@alias UIElement3DAttachPlayerId
---| 0 TORI
---| 1 UKE
TORI = 0
UKE = 1

---@class RenderEffect
---@field id RenderEffectId Effect id
---@field glowColor ColorId Glow color id
---@field glowIntensity number Glow intensity
---@field ditherPixelSize integer Dithering effect pixel size

OBJMODELCACHE = OBJMODELCACHE or {}
OBJMODELINDEX = OBJMODELINDEX or 0

---@type UIElement3D[]
UIElement3DManager = UIElement3DManager or {}
---@type UIElement3D[]
UIVisual3DManager = UIVisual3DManager or {}
---@type UIElement3D[]
UIVisual3DManagerViewport = UIVisual3DManagerViewport or {}

if (not UIElement3D) then
	---Options to use to spawn the new UIElement3D object.\
	---*Majority of these are the same as UIElement3D class fields.*
	---@class UIElement3DOptions : UIElementOptions
	---@field parent UIElement3D|UIElement Parent element
	---@field rot number[] Object's relative rotation to its parent, in Euler angles
	---@field playerAttach integer Target player id to attach the object to. Should be used with either `attachBodypart` or `attachJoint`.
	---@field attachBodypart integer Target bodypart id to attach the object to. Requires a valid `playerAttach` value.
	---@field attachJoint integer Target joint id to attach the object to. Requires a valid `playerAttach` value.
	---@field objModel string Filename of the custom obj model
	---@field shapeType UIElement3DShape
	---@field effects RenderEffect Rendering effects for the object

	---@class UIElement3D : UIElement
	---@field parent UIElement3D|UIElement Parent element
	---@field viewport UIElement3D|UIElement Viewport element
	---@field pos Vector3 Object's **absolute** position in the world
	---@field shift Vector3 Object **relative** position relative to its parent
	---@field size Vector3 Object size
	---@field rot Vector3 Object rotation
	---@field rotMatrix number[][] Rotation matrix of the object
	---@field rotXYZ Vector3 Object rotation in [Euler angles](https://en.wikipedia.org/wiki/Euler_angles)
	---@field shapeType UIElement3DShape
	---@field playerAttach integer Target player id this object is attached to
	---@field attachBodypart integer Target bodypart id this object is attached to
	---@field attachJoint integer Target joint id this object is attached to
	---@field effectid RenderEffectId Element's rendering effect ID
	---@field glowIntensity number Element's glow intensity
	---@field glowColor ColorId Element's glow color ID
	---@field ditherPixelSize integer Element's dithering effect pixel size
	---@field customEnterFrameFunc function Function to be executed on `enter_frame` callback
	---@field viewportElement boolean Whether this object is displayed in a viewport
	UIElement3D = {
		ver = 5.60
	}
	UIElement3D.__index = UIElement3D
	setmetatable(UIElement3D, UIElement)
end

---Creates a new UIElement3D object
---@param _self UIElement3D
---@param o UIElement3DOptions
---@return UIElement3D
---@overload fun(o: UIElement3DOptions):UIElement3D
function UIElement3D.new(_self, o)
	if (o == nil) then
		if (_self ~= nil) then
			---@diagnostic disable-next-line: cast-local-type
			o = _self
		else
			error("Invalid argument #1 provided to UIElement3D.new(o: UIElement3DOptions)")
		end
	end

	---@type UIElement3D
	local elem = {
		globalid = 1000,
		child = {},
		rot = { 0, 0, 0 },
		rotXYZ = { x = 0, y = 0, z = 0 },
		pos = { 0, 0, 0 },
		shift = { 0, 0, 0 },
		bgColor = { 1, 1, 1, 0 },
		shapeType = CUBE
	}
	setmetatable(elem, UIElement3D)

	---@type UIElement3DOptions
	---@diagnostic disable-next-line: assign-type-mismatch
	o = o
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
		for i, v in pairs(elem.shift) do
			elem.pos[i] = elem.parent.pos[i] + v
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
			---@diagnostic disable-next-line: param-type-mismatch
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

	return elem
end

---Spawns a new UIElement3D and sets the calling object as its parent.
---
---*Unlike `UIElement:addChild()`, this doesn't support `shift` value and is only a shortcut method to initialize an object with a predefined parent.*
---@param o UIElement3DOptions
---@return UIElement3D
function UIElement3D:addChild(o)
	o.pos = o.pos and o.pos or { 0, 0, 0 }
	o.size = o.size and o.size or { self.size.x, self.size.y, self.size.z }
	o.viewport = o.viewport or self.viewportElement
	o.parent = self
	return UIElement3D:new(o)
end

---Destroys current UIElement3D object
---@param childOnly? boolean If true, will only destroy current object's children and keep the object itself
function UIElement3D:kill(childOnly)
	for _,v in pairs(self.child) do
		if (v.kill) then
			v:kill()
		end
	end
	if (childOnly) then
		self.child = {}
		return
	end
	if (self.destroyed) then
		return
	end

	if (self.killAction) then
		self.killAction()
	end
	self:hide(true)

	if (self.bgImage) then self:updateImage(nil) end
	if (self.objModel) then self:updateObj(nil) end
	for i,v in pairs(UIElement3DManager) do
		if (self == v) then
			table.remove(UIElement3DManager, i)
			break
		end
	end

	self.destroyed = true
	self = nil
end

---Specifies a function to be executed on `enter_frame` event callback
---@param func function
function UIElement3D:addOnEnterFrame(func)
	self.customEnterFrameFunc = func
end

---Internal function that's used to draw the UIElement3D. \
---*You likely don't need to call this manually.* \
---@see UIElement3D.drawVisuals
---@see UIElement3D.addCustomDisplay
---@see UIElement3D.addOnEnterFrame
function UIElement3D:display()
	if (self.effectid) then
		set_draw_effect(self.effectid, self.glowColor, self.glowIntensity, self.ditherPixelSize)
	end
	if (self.viewport) then
		set_viewport(self.viewport.pos.x, self.viewport.pos.y, self.viewport.size.w, self.viewport.size.h)
		return
	end
	if (self.customDisplayBefore) then
		self.customDisplayBefore()
	end
	if (self.hoverState ~= BTN_NONE and self.hoverColor) then
		local animateRatio = (UIElement.clock - (self.hoverClock or 0)) / UIElement.animationDuration
		if (UIElement.lightUIMode) then
			for i = 1, 4 do
				self.animateColor[i] = self.hoverColor[i]
			end
		else
			for i = 1, 4 do
				if (self.animateColor[i] ~= self.hoverColor[i]) then
					self.animateColor[i] = UITween.SineTween(self.bgColor[i], self.hoverColor[i], animateRatio)
				end
			end
		end
	else
		if (self.animateColor) then
			for i = 1, 4 do
				self.animateColor[i] = self.bgColor[i]
			end
		end
	end

	if (not self.customDisplayOnly and (self.bgColor[4] > 0 or self.interactive)) then
		if (self.hoverState == BTN_HVR and self.hoverColor) then
			set_color(unpack(self.animateColor))
		elseif (self.hoverState == BTN_DN and self.pressedColor) then
			set_color(unpack(self.pressedColor))
		else
			set_color(unpack(self.bgColor))
		end
		if (self.shapeType == CUBE) then
			self:drawBox()
		elseif (self.shapeType == SPHERE) then
			self:drawSphere()
		elseif (self.shapeType == CAPSULE) then
			self:drawCapsule()
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

---Generic internal function to draw a cube UIElement3D object. \
---*You likely don't need to run this manually.*
function UIElement3D:drawBox()
	if (self.playerAttach) then
		local body = get_body_info(self.playerAttach, self.attachBodypart)
		if (self.bgImage) then
			draw_box_m(body.pos.x + self.pos.x, body.pos.y + self.pos.y, body.pos.z + self.pos.z, self.size.x, self.size.y, self.size.z, body.rot, self.bgImage)
		else
			draw_box_m(body.pos.x + self.pos.x, body.pos.y + self.pos.y, body.pos.z + self.pos.z, self.size.x, self.size.y, self.size.z, body.rot)
		end
	else
		if (self.bgImage) then
			draw_box(self.pos.x, self.pos.y, self.pos.z, self.size.x, self.size.y, self.size.z, self.rot.x, self.rot.y, self.rot.z, self.bgImage)
		else
			draw_box(self.pos.x, self.pos.y, self.pos.z, self.size.x, self.size.y, self.size.z, self.rot.x, self.rot.y, self.rot.z)
		end
	end
end

---Generic internal function to draw a capsule UIElement3D object. \
---*You likely don't need to run this manually.*
function UIElement3D:drawCapsule()
	if (self.playerAttach and self.attachBodypart) then
		local body = get_body_info(self.playerAttach, self.attachBodypart)
		if (self.bgImage) then
			draw_capsule_m(body.pos.x, body.pos.y, body.pos.z, self.size.y, self.size.x, body.rot, self.bgImage)
		else
			draw_capsule_m(body.pos.x, body.pos.y, body.pos.z, self.size.y, self.size.x, body.rot)
		end
	else
		local drawPos = (self.playerAttach and self.attachJoint) and get_joint_pos2(self.playerAttach, self.attachJoint) or self.pos

		if (self.bgImage) then
			draw_capsule(drawPos.x, drawPos.y, drawPos.z, self.size.y, self.size.x, self.rot.x, self.rot.y, self.rot.z, self.bgImage)
		else
			draw_capsule(drawPos.x, drawPos.y, drawPos.z, self.size.y, self.size.x, self.rot.x, self.rot.y, self.rot.z)
		end
	end
end

---Generic internal function to draw a sphere UIElement3D object. \
---*You likely don't need to run this manually.*
function UIElement3D:drawSphere()
	if (self.playerAttach and self.attachBodypart) then
		local body = get_body_info(self.playerAttach, self.attachBodypart)
		if (self.bgImage) then
			draw_sphere_m(body.pos.x + self.pos.x, body.pos.y + self.pos.y, body.pos.z + self.pos.z, self.size.x, body.rot, self.bgImage)
		else
			draw_sphere_m(body.pos.x + self.pos.x, body.pos.y + self.pos.y, body.pos.z + self.pos.z, self.size.x, body.rot)
		end
	else
		local drawPos = (self.playerAttach and self.attachJoint) and get_joint_pos2(self.playerAttach, self.attachJoint) or self.pos
		local scale = (self.playerAttach and self.attachJoint) and get_joint_radius(self.playerAttach, self.attachJoint) or 1

		if (self.bgImage) then
			draw_sphere(drawPos.x, drawPos.y, drawPos.z, self.size.x * scale, self.rot.x, self.rot.y, self.rot.z, self.bgImage)
		else
			draw_sphere(drawPos.x, drawPos.y, drawPos.z, self.size.x * scale)
		end
	end
end

---Main UIElement3D loop that displays the objects. \
---*Must be run from either `draw3d` or `post_draw3d` hook.*
---@param globalid ?integer Global ID that the objects to display belong to
function UIElement3D:drawVisuals(globalid)
	local globalid = globalid or self.globalid
	for _, v in pairs(UIVisual3DManager) do
		if (v.globalid == globalid) then
			v:display()
		end
	end
end

---Main UIElement3D loop that displays viewport elements. \
---*Must be run from `draw_viewport` hook.*
---@param globalid ?integer Global ID that the objects to display belong to
function UIElement3D:drawViewport(globalid)
	local globalid = globalid or self.globalid
	for _, v in pairs(UIVisual3DManagerViewport) do
		if (v.globalid == globalid) then
			v:display()
		end
	end
end

---Main UIElement3D loop to trigger UIElement3D functionality on `enter_frame` hook. \
---**This does not support viewport elements.**
---
---*Must be run from `enter_frame` hook.*
---@param globalid ?integer Global ID that the objects to display belong to
function UIElement3D:drawEnterFrame(globalid)
	local globalid = globalid or self.globalid
	for _, v in pairs(UIVisual3DManager) do
		if (v.globalid == globalid) then
			if (v.customEnterFrameFunc ~= nil) then
				v.customEnterFrameFunc()
			end
		end
	end
end

---Enables current UIElement3D and all its children for display
---@param forceReload ?boolean Whether to override `noreload` value set by previous `hide()` calls
---@return boolean
function UIElement3D:show(forceReload)
	local num = nil

	if (self.noreload and not forceReload) then
		return self.displayed
	elseif (forceReload) then
		self.noreload = nil
	end

	local targetManager = self.viewportElement and UIVisual3DManagerViewport or UIVisual3DManager
	for i,v in pairs(targetManager) do
		if (self == v) then
			num = i
			break
		end
	end

	if (not num) then
		table.insert(targetManager, self)
		if (self.interactive) then
			self:activate()
		end
	end

	for _ ,v in pairs(self.child) do
		v:show()
	end
	self.displayed = true
	return self.displayed
end

---Disables display of current UIElement3D and all its children
---@param noreload ?boolean Whether this UIElement3D should ignore subsequent `show()` calls that don't have override on
function UIElement3D:hide(noreload)
	for _ ,v in pairs(self.child) do
		v:hide()
	end

	if (noreload) then
		self.noreload = true
	end
	if (self.displayed == false) then
		return
	end

	if (self.interactive) then
		self:deactivate()
	end

	local targetManager = self.viewportElement and UIVisual3DManagerViewport or UIVisual3DManager
	for i,v in pairs(targetManager) do
		if (self == v) then
			table.remove(targetManager, i)
			break
		end
	end
	self.displayed = false
end

---Not yet implemented \
---@see create_raycast_body
---@see shoot_camera_ray
function UIElement3D:activate()
end

---Not yet implemented \
---@see create_raycast_body
---@see shoot_camera_ray
function UIElement3D:deactivate()
end

---Internal function to update positions of all the current UIElement3D object's children
function UIElement3D:updatePos()
	for _, v in pairs(self.child) do
		v:updateChildPos()
	end
end

---Internal function to set the shift of the current UIElement3D in relation to its parent
function UIElement3D:setChildShift()
	local rotMatrix = self.parent.rotMatrix
	local shift = self.shift

	local rotatedShift = UIElement3D.multiply({ { shift.x, shift.y, shift.z } }, rotMatrix)
	if (rotatedShift) then
		local newShift = rotatedShift[1]
		self.shift.x = newShift[1]
		self.shift.y = newShift[2]
		self.shift.z = newShift[3]
	end
end

---Internal function to update the absolute position of the UIElement3D object
---@param rotMatrix ?number[][]
---@param pos ?Vector3
---@param shift ?Vector3
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

	for _, v in pairs(self.child) do
		v:updateChildPos(rotMatrix, pos, shiftSum)
	end
end

---Moves the UIElement3D object and updates its and its children's absolute positions accordingly
---@param x number
---@param y number
---@param z number
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

---Rotates the UIElement3D object and updates all its children accordingly
---@param x ?number
---@param y ?number
---@param z ?number
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

	for _, v in pairs(self.child) do
		v:rotate(x, y, z)
	end
	self:updatePos()
end

---Internal function to update the rotation matrix of the UIElement3D object and set the proper `rot` values in Euler angles. \
---*You likely don't need to run this manually.* \
---@see UIElement3D.rotate
---@param rot Vector3
function UIElement3D:updateRotations(rot)
	---@diagnostic disable-next-line: assign-type-mismatch
	self.rotMatrix = UIElement3D.getRotMatrixFromEulerAngles(math.rad(rot.x), math.rad(rot.y), math.rad(rot.z), "xyz")
	local relX, relY, relZ = UIElement3D.getEulerZYXFromRotationMatrix(self.rotMatrix)
	self.rot = { x = relX, y = relY, z = relZ }
end

---Helper function to get the Euler angles (ZYX) from a rotation matrix
---@param R number[][]
---@return number
---@return number
---@return number
---@nodiscard
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

---Helper function to get the Euler angles (XYZ) from a rotation matrix
---@param R number[][]
---@return number
---@return number
---@return number
---@nodiscard
function UIElement3D.getEulerXYZFromRotationMatrix(R)
	local x, y, z

	x = math.atan2(-R[2][3], R[3][3])
	y = math.atan2(R[1][3], R[3][3] * math.cos(x) - R[2][3] * math.sin(x))
	z = math.atan2(R[2][1] * math.cos(x) + R[3][1] * math.sin(x), R[2][2] * math.cos(x) + R[3][2] * math.sin(x))

	return math.deg(x), math.deg(y), math.deg(z)
end

---Helper function to make sure the provided table is a Toribash rotation table
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

---Helper function to get the rotation in Euler angles from a Toribash rotation matrix
---@param rTB Matrix4x4
---@return number
---@return number
---@return number
---@nodiscard
function UIElement3D.getEulerAnglesFromMatrixTB(rTB)
	local rTB = UIElement3D.verifyRotMatrixTB(rTB)
	return UIElement3D.getEulerZYXFromRotationMatrix({
		{ rTB.r0, rTB.r1, rTB.r2, rTB.r3 },
		{ rTB.r4, rTB.r5, rTB.r6, rTB.r7 },
		{ rTB.r8, rTB.r9, rTB.r10, rTB.r11 },
		{ rTB.r12, rTB.r13, rTB.r14, rTB.r15 },
	})
end

---@alias EulerAnglesOrder
---| 'xyz'
---| 'zyx'

---Helper function to get the rotation matrix from Euler angles with the specified convention. \
---*Only `XYZ` and `ZYX` are currently supported as that's what we'd need when working with Toribash rotation matrices.*
---@param x number
---@param y number
---@param z number
---@param order EulerAnglesOrder
---@return number[][]|nil
function UIElement3D.getRotMatrixFromEulerAngles(x, y, z, order)
	local order = order or 'xyz'
	local c1 = math.cos(x)
	local s1 = math.sin(x)
	local c2 = math.cos(y)
	local s2 = math.sin(y)
	local c3 = math.cos(z)
	local s3 = math.sin(z)

	local R = nil
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

---Helper function to multiply a 2-dimensional matrix by a number
---@param a number[][]
---@param b number
---@return number[][]
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

---Helper function to multiply 2-dimensional matrices
---@param a number[][]
---@param b number[][]|number[]|number
---@return number[][]|number[]|nil
function UIElement3D.multiply(a, b)
	if (type(b) == 'number') then
		return UIElement3D.multiplyByNumber(a, b)
	end
	if (#a[1] ~= #b) then
		return nil
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

---Updates a 3D model associated with an object and caches it for later use
---@param model string|nil Model path
---@param noreload ?boolean If true, will not check if existing model should be unloaded
---@return boolean
function UIElement:updateObj(model, noreload)
	require("system.iofiles")
	local filename = ''
	if (model) then
		if (model:find("%.%./", 4)) then
			filename = model:gsub("%.%./%.%./", "")
		elseif (model:find("%.%./")) then
			filename = model:gsub("%.%./", "data/")
		else
			filename = "data/script/" .. model:gsub("^/", "")
		end
	end

	if (not noreload and self.objModel and not self.disableUnload) then
		local id = 0
		for i, _ in pairs(OBJMODELCACHE) do
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
	if (OBJMODELINDEX > 126) then
		return false
	end

	local objFile = Files:open("../" .. filename .. ".obj")
	if (not objFile.data) then
		return false
	end
	objFile:close()

	local objid = -1
	for i = 0, 127 do
		if (OBJMODELCACHE[i]) then
			if (OBJMODELCACHE[i].name == filename) then
				self.objModel = i
				OBJMODELCACHE[i].count = OBJMODELCACHE[i].count + 1
				return true
			end
		elseif (objid < 0) then
			objid = i
		end
	end

	if (load_obj(objid, filename, 1)) then
		self.objModel = objid
	end
	OBJMODELCACHE[objid] = { name = filename, count = 1 }
	OBJMODELINDEX = math.max(OBJMODELINDEX, objid)
	return true
end
