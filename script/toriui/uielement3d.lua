require('toriui.uielement')

---@alias EulerRotationConvention
---| 'XYZ' EULER_XYZ
---| 'ZYX' EULER_ZYX
EULER_XYZ = 'XYZ'
EULER_ZYX = 'ZYX'

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
---@type UIElement3D[][]
UIVisual3DManager = UIVisual3DManager or {}
---@type UIElement3D[][]
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
	---@field child UIElement3D[] List of all object children
	---@field viewport UIElement3D|UIElement Viewport element
	---@field pos Vector3 Object's **absolute** position in the world
	---@field shift Vector3 Object's position **relative to its parent**
	---@field shiftInternal Vector3 Object's rotation adjusted relative position
	---@field size Vector3 Object size
	---@field rotMatrix number[][] Object's rotation as a [rotation matrix](https://en.wikipedia.org/wiki/Rotation_matrix)
	---@field rotMatrixTB MatrixTB Object's rotation as a Toribash rotation matrix
	---@field rotXYZ EulerRotation Object's rotation in [Euler angles](https://en.wikipedia.org/wiki/Euler_angles)
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

	---@class EulerRotation : Vector3
	---@field convention EulerRotationConvention
	EulerRotation = {}
	EulerRotation.__index = EulerRotation
end

---Initializes an **EulerRotation** object with the specified data in degrees
---@param x number?
---@param y number?
---@param z number?
---@param convention EulerRotationConvention? Defaults to `EULER_XYZ` if none specified
---@return EulerRotation
function EulerRotation.New(x, y, z, convention)
	local rot = {
		x = x or 0,
		y = y or 0,
		z = z or 0,
		convention = convention or EULER_XYZ
	}
	setmetatable(rot, EulerRotation)
	return rot
end

---Initializes an **EulerRotation** object with the specified data in radians
---@param x number?
---@param y number?
---@param z number?
---@param convention EulerRotationConvention? Defaults to `EULER_XYZ` if none specified
---@return EulerRotation
function EulerRotation.NewRadian(x, y, z, convention)
	return EulerRotation.New(math.deg(x or 0), math.deg(y or 0), math.deg(z or 0), convention)
end

---Returns a corresponding rotation matrix
---@return number[][]?
function EulerRotation:toMatrix()
	return UIElement3D.GetMatrixFromEuler(math.rad(self.x), math.rad(self.y), math.rad(self.z), self.convention)
end

---Returns a corresponding Toribash rotation matrix and a regular rotation matrix
---@return MatrixTB
---@return number[][]
function EulerRotation:toMatrixTB()
	local matrix = self:toMatrix()
	---@type MatrixTB
	local matrixTB = {
		r0 = 1,		r1 = 0,		r2 = 0,		r3 = 0,
		r4 = 0,		r5 = 1,		r6 = 0,		r7 = 0,
		r8 = 0,		r9 = 0,		r10 = 1,	r11 = 0
	}
	if (matrix) then
		matrixTB.r0 = matrix[1][1]
		matrixTB.r1 = matrix[2][1]
		matrixTB.r2 = matrix[3][1]
		matrixTB.r4 = matrix[1][2]
		matrixTB.r5 = matrix[2][2]
		matrixTB.r6 = matrix[3][2]
		matrixTB.r8 = matrix[1][3]
		matrixTB.r9 = matrix[2][3]
		matrixTB.r10 = matrix[3][3]
	else
		matrix = {
			{ 1, 0, 0 },
			{ 0, 1, 0 },
			{ 0, 0, 1 }
		}
	end
	return matrixTB, matrix
end

---**UIElement3D helper class** \
---*Contains functions that only get used internally and which we don't want to expose.*
---@class UIElement3DInternal
local UIElement3DInternal = {}

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
		child = { },
		rotXYZ = EulerRotation.New(),
		pos = { x = 0, y = 0, z = 0 },
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
		elem.shiftInternal = { x = 0, y = 0, z = 0 }
		elem.rotXYZ.x = elem.parent.rotXYZ.x
		elem.rotXYZ.y = elem.parent.rotXYZ.y
		elem.rotXYZ.z = elem.parent.rotXYZ.z
		UIElement3DInternal.SetChildPosition(elem)
	else
		if (o.shapeType == VIEWPORT) then
			elem.viewport = o.parent
			table.insert(elem.viewport.child, elem)
		end
		elem.pos.x = o.pos[1]
		elem.pos.y = o.pos[2]
		elem.pos.z = o.pos[3]
	end
	if (o.globalid) then
		elem.globalid = o.globalid
	end

	elem.size = { x = o.size[1], y = o.size[2], z = o.size[3] }
	if (o.rot) then
		elem.rotXYZ.x = elem.rotXYZ.x + o.rot[1]
		elem.rotXYZ.y = elem.rotXYZ.y + o.rot[2]
		elem.rotXYZ.z = elem.rotXYZ.z + o.rot[3]
	end
	elem.rotMatrixTB, elem.rotMatrix = elem.rotXYZ:toMatrixTB()

	if (o.objModel) then
		elem.shapeType = CUSTOMOBJ
		elem.disableUnload = o.disableUnload
		elem:updateObj(o.objModel)
	end

	if (o.bgGradient) then
		elem.bgColor = { 1, 1, 1, 1 }
		elem:updateImageGradient(o.bgGradient[1], o.bgGradient[2], o.bgGradientMode)
	elseif (o.bgColor) then
		elem.bgColor = o.bgColor
	end
	if (o.bgImage or elem.bgImage) then
		elem.disableUnload = o.disableUnload
		if (elem.bgImage == nil) then
			if (type(o.bgImage) == "table") then
				elem:updateImage(o.bgImage[1], o.bgImage[2])
			else
				---@diagnostic disable-next-line: param-type-mismatch
				elem:updateImage(o.bgImage)
			end
		end
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

	---Do we actually still need UIElement3DManager?
	---Might be useful for cleanup but it's not used in object lifetime anymore
	table.insert(UIElement3DManager, elem)
	if (o.viewport) then
		elem.viewportElement = true
		UIVisual3DManagerViewport[elem.globalid] = UIVisual3DManagerViewport[elem.globalid] or { }
		table.insert(UIVisual3DManagerViewport[elem.globalid], elem)
	else
		UIVisual3DManager[elem.globalid] = UIVisual3DManager[elem.globalid] or { }
		table.insert(UIVisual3DManager[elem.globalid], elem)
	end

	return elem
end

---Spawns a new UIElement3D and sets the calling object as its parent. \
---*Unlike `UIElement:addChild()`, this doesn't support `shift` value and is only a shortcut method to initialize an object with a predefined parent.*
---@param o UIElement3DOptions
---@return UIElement3D
function UIElement3D:addChild(o)
	o.pos = o.pos and o.pos or { 0, 0, 0 }
	o.size = o.size and o.size or { 0, 0, 0 }
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
	if (self.viewport) then
		set_viewport(self.viewport.pos.x, self.viewport.pos.y, self.viewport.size.w, self.viewport.size.h)
		return
	end
	if (self.effectid) then
		set_draw_effect(self.effectid, self.glowColor, self.glowIntensity, self.ditherPixelSize)
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
			draw_obj_m(self.objModel, self.pos.x, self.pos.y, self.pos.z, self.size.x, self.size.y, self.size.z, self.rotMatrixTB)
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
			draw_box_m(self.pos.x, self.pos.y, self.pos.z, self.size.x, self.size.y, self.size.z, self.rotMatrixTB, self.bgImage)
		else
			draw_box_m(self.pos.x, self.pos.y, self.pos.z, self.size.x, self.size.y, self.size.z, self.rotMatrixTB)
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
			draw_capsule_m(drawPos.x, drawPos.y, drawPos.z, self.size.y, self.size.x, self.rotMatrixTB, self.bgImage)
		else
			draw_capsule_m(drawPos.x, drawPos.y, drawPos.z, self.size.y, self.size.x, self.rotMatrixTB)
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
			draw_sphere_m(drawPos.x, drawPos.y, drawPos.z, self.size.x * scale, self.rotMatrixTB, self.bgImage)
		else
			draw_sphere_m(drawPos.x, drawPos.y, drawPos.z, self.size.x * scale)
		end
	end
end

---Main UIElement3D loop that displays the objects. \
---**This function must be run from either `draw3d` or `post_draw3d` hooks to work correctly.**
---@param object UIElement3D
---@param globalid ?integer Global ID that the objects to display belong to
---@overload fun(globalid: integer)
function UIElement3D.drawVisuals(object, globalid)
	local globalid = (type(object) == "table" and (object.globalid or globalid) or object)
	if (UIVisual3DManager[globalid] == nil) then return end

	for _, v in pairs(UIVisual3DManager[globalid]) do
		v:display()
	end
end

---Main UIElement3D loop that displays viewport elements. \
---**This function must be run from either `draw_viewport` hook to work correctly.**
---@param object UIElement3D
---@param globalid ?integer Global ID that the objects to display belong to
---@overload fun(globalid: integer)
function UIElement3D.drawViewport(object, globalid)
	local globalid = (type(object) == "table" and (object.globalid or globalid) or object)

	if (UIVisual3DManagerViewport[globalid] == nil) then return end

	for _, v in pairs(UIVisual3DManagerViewport[globalid]) do
		v:display()
	end
end

---Main UIElement3D loop to trigger UIElement3D functionality on `enter_frame` hook. \
---*Only regular UIElement3D objects are supported, for viewport elements use regular `UIElement3D.drawViewport()` loop*.
---
---**This function must be run from `enter_frame` hook to work as expected.**
---@param object UIElement3D
---@param globalid ?integer Global ID that the objects to display belong to
function UIElement3D.drawEnterFrame(object, globalid)
	local globalid = (type(object) == "table" and (object.globalid or globalid) or object)
	if (UIVisual3DManager[globalid] == nil) then return end

	for _, v in pairs(UIVisual3DManager[globalid]) do
		if (v.customEnterFrameFunc ~= nil) then
			v.customEnterFrameFunc()
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
	for i,v in pairs(targetManager[self.globalid]) do
		if (self == v) then
			num = i
			break
		end
	end

	if (not num) then
		table.insert(targetManager[self.globalid], self)
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
	for i,v in pairs(targetManager[self.globalid]) do
		if (self == v) then
			table.remove(targetManager[self.globalid], i)
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
---@param object UIElement3D
function UIElement3DInternal.UpdateChildrenPosition(object)
	for _, v in pairs(object.child) do
		UIElement3DInternal.UpdatePosition(v, object.rotMatrix, object.pos)
	end
end

---Internal function to set the shift of the current UIElement3D in relation to its parent
---@param object UIElement3D
function UIElement3DInternal.SetChildPosition(object)
	local rotatedShift = UIElement3D.MatrixMultiply({ { object.shift.x, object.shift.y, object.shift.z } }, object.parent.rotMatrix)
	if (rotatedShift) then
		local newShift = rotatedShift[1]
		object.shiftInternal.x = newShift[1]
		object.shiftInternal.y = newShift[2]
		object.shiftInternal.z = newShift[3]
	end
	for i, v in pairs(object.shiftInternal) do
		object.pos[i] = object.parent.pos[i] + v
	end
end

---Internal function to update the absolute position of the UIElement3D object
---@param object UIElement3D
---@param rotMatrix number[][]
---@param pos Vector3
---@param shift ?Vector3
function UIElement3DInternal.UpdatePosition(object, rotMatrix, pos, shift)
	shift = shift and { x = shift.x + object.shift.x, y = shift.y + object.shift.y, z = shift.z + object.shift.z } or object.shift

	local newPos = UIElement3D.MatrixMultiply({ { shift.x, shift.y, shift.z } }, rotMatrix)
	local shiftSum = shift
	if (newPos) then
		local vector = newPos[1]
		shiftSum = shift or {
			x = vector[1],
			y = vector[2],
			z = vector[3]
		}

		object.pos.x = pos.x + vector[1]
		object.pos.y = pos.y + vector[2]
		object.pos.z = pos.z + vector[3]
	end

	for _, v in pairs(object.child) do
		UIElement3DInternal.UpdatePosition(v, rotMatrix, pos, shiftSum)
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
		UIElement3DInternal.SetChildPosition(self)
	else
		if (x) then self.pos.x = self.pos.x + x end
		if (y) then self.pos.y = self.pos.y + y end
		if (z) then self.pos.y = self.pos.z + z end
	end

	UIElement3DInternal.UpdateChildrenPosition(self)
end

---Internal function to handle rotation of a UIElement3D object and its children
---@param object UIElement3D
---@param x number
---@param y number
---@param z number
function UIElement3DInternal.Rotate(object, x, y, z)
	object.rotXYZ.x = (object.rotXYZ.x + x) % 360
	object.rotXYZ.y = (object.rotXYZ.y + y) % 360
	object.rotXYZ.z = (object.rotXYZ.z + z) % 360
	object.rotMatrixTB, object.rotMatrix = object.rotXYZ:toMatrixTB()

	for _, v in pairs(object.child) do
		UIElement3DInternal.Rotate(v, x, y, z)
	end
end

---Rotates the UIElement3D object and updates all its children accordingly
---@param x ?number
---@param y ?number
---@param z ?number
function UIElement3D:rotate(x, y, z)
	x = x or 0
	y = y or 0
	z = z or 0
	if (x == 0 and y == 0 and z == 0) then
		return
	end

	UIElement3DInternal.Rotate(self, x, y, z)
	UIElement3DInternal.UpdateChildrenPosition(self)
end

---Helper function to get the Euler angles from a rotation matrix. \
---*Only `EULER_XYZ` and `EULER_ZYX` conventions are supported.*
---@param R number[][]
---@param convention EulerRotationConvention
---@return EulerRotation
function UIElement3D.GetEulerFromMatrix(R, convention)
	local x, y, z = 0, 0, 0
	if (convention == EULER_XYZ) then
		local sinx = math.sin(x)
		local cosx = math.cos(x)
		x = math.atan2(-R[2][3], R[3][3])
		y = math.atan2(R[1][3], R[3][3] * cosx - R[2][3] * sinx)
		z = math.atan2(R[2][1] * cosx + R[3][1] * sinx, R[2][2] * cosx + R[3][2] * sinx)
	elseif (convention == EULER_ZYX) then
		local clamp = R[3][1] > 1 and 1 or (R[3][1] < -1 and -1 or R[3][1])
		y = math.asin(-clamp)
		if (0.99999 > math.abs(R[3][1])) then
			x = math.atan2(R[3][2], R[3][3])
			z = math.atan2(R[2][1], R[1][1])
		else
			x = 0
			z = math.atan2(-R[1][2], R[2][2])
		end
	elseif (TB_MENU_DEBUG) then
		error("UIElement3D.GetEulerFromMatrix() unsupported convention: " .. convention)
	end

	return EulerRotation.New(math.deg(x), math.deg(y), math.deg(z), convention)
end

---Legacy function to get ZYX euler angles rotation from rotation matrix. \
---@see UIElement3D.GetEulerFromMatrix
---@param R number[][]
---@return number x
---@return number y
---@return number z
---@deprecated
function UIElement3D:getEulerZYXFromRotationMatrix(R)
	local rotation = UIElement3D.GetEulerFromMatrix(R, EULER_ZYX)
	return rotation.x, rotation.y, rotation.z
end

---Legacy function to get XYZ euler angles rotation from rotation matrix. \
---@see UIElement3D.GetEulerFromMatrix
---@param R number[][]
---@return number x
---@return number y
---@return number z
---@deprecated
function UIElement3D:getEulerXYZFromRotationMatrix(R)
	local rotation = UIElement3D.GetEulerFromMatrix(R, EULER_XYZ)
	return rotation.x, rotation.y, rotation.z
end

---Internal helper function to make sure the provided table is a Toribash rotation table
---@param rTB MatrixTB|number[]
---@return MatrixTB
function UIElement3DInternal.VerifyMatrixTB(rTB)
	if (rTB.r0 ~= nil) then
		return rTB
	end
	return {
		r0 = rTB[1],	r1 = rTB[2],	r2 = rTB[3],	r3 = rTB[4],
		r4 = rTB[5],	r5 = rTB[6],	r6 = rTB[7],	r7 = rTB[8],
		r8 = rTB[9],	r9 = rTB[10],	r10 = rTB[11],	r11 = rTB[12]
	}
end

---Helper function to get the rotation in Euler angles from a Toribash rotation matrix
---@param rTB MatrixTB
---@return EulerRotation
---@nodiscard
function UIElement3D.GetEulerFromMatrixTB(rTB)
	rTB = UIElement3DInternal.VerifyMatrixTB(rTB)
	return UIElement3D.GetEulerFromMatrix({
		{ rTB.r0, rTB.r1, rTB.r2, rTB.r3 },
		{ rTB.r4, rTB.r5, rTB.r6, rTB.r7 },
		{ rTB.r8, rTB.r9, rTB.r10, rTB.r11 },
		{ 0, 0, 0, 1 },
	}, EULER_ZYX)
end

---Legacy function to get euler angles from Toribash rotation matrix. \
---@see UIElement3D.GetEulerFromMatrixTB
---@param rTB MatrixTB
---@return number x
---@return number y
---@return number z
---@deprecated
function UIElement3D:getEulerAnglesFromMatrixTB(rTB)
	local rotation = UIElement3D.GetEulerFromMatrixTB(rTB)
	return rotation.x, rotation.y, rotation.z
end

---Helper function to get the rotation matrix from Euler angles with the specified convention. \
---*Only `EULER_XYZ` and `EULER_ZYX` conventions are currently supported.*
---@param x number
---@param y number
---@param z number
---@param convention EulerRotationConvention
---@return number[][]?
function UIElement3D.GetMatrixFromEuler(x, y, z, convention)
	convention = string.upper(convention) or EULER_XYZ
	local c1 = math.cos(x)
	local s1 = math.sin(x)
	local c2 = math.cos(y)
	local s2 = math.sin(y)
	local c3 = math.cos(z)
	local s3 = math.sin(z)
	local R = nil

	if (convention == EULER_XYZ) then
		R = {
			{
				c2 * c3,
				-c2 * s3,
				s2
			},
			{
				s1 * s2 * c3 + c1 * s3,
				-s1 * s2 * s3 + c1 * c3,
				-c2 * s1
			},
			{
				-c1 * c3 * s2 + s1 * s3,
				c1 * s2 * s3 + s1 * c3,
				c1 * c2
			}
		}
	elseif (convention == EULER_ZYX) then
		R = {
			{
				c1 * c2,
				c1 * s2 * s3 - s1 * c3,
				c1 * s2 * c3 + s1 * s3
			},
			{
				s1 * c2,
				s1 * s2 * s3 + c1 * c3,
				s1 * s2 * c3 - c1 * s3
			},
			{
				-s2,
				c2 * s3,
				c2 * c3
			}
		}
	elseif (TB_MENU_DEBUG) then
		error("UIElement3D.GetMatrixFromEuler() unsupported convention: " .. convention)
	end

	return R
end

---Legacy function to get rotation matrix from euler angles. \
---@see UIElement3D.GetMatrixFromEuler
---@param x number
---@param y number
---@param z number
---@return number[][]?
---@deprecated
function UIElement3D:getRotMatrixFromEulerAngles(x, y, z)
	return UIElement3D.GetMatrixFromEuler(x, y, z, EULER_XYZ)
end

---Helper function to multiply a 2-dimensional matrix by a number
---@param a number[][]
---@param b number
---@return number[][]
function UIElement3DInternal.MultiplyMatrixNumber(a, b)
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
function UIElement3D.MatrixMultiply(a, b)
	if (type(b) == 'number') then
		return UIElement3DInternal.MultiplyMatrixNumber(a, b)
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

---Legacy function to multiply matrices
---@see UIElement3D.MatrixMultiply
---@param a number[][]
---@param b number[][]|number[]|number
---@return number[][]|number[]|nil
---@deprecated
function UIElement3D:multiply(a, b)
	return UIElement3D.MatrixMultiply(a, b)
end

---Legacy function to multiply a matrix by number
---@see UIElement3D.multiply
---@param a number[][]
---@param b number
---@return number[][]
---@deprecated
function UIElement3D:multiplyByNumber(a, b)
	return UIElement3DInternal.MultiplyMatrixNumber(a, b)
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
