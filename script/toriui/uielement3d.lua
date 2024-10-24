require('toriui.uielement')

---Local references to frequently used global functions to improve performance
local rad = math.rad
local deg = math.deg
local sin = math.sin
local cos = math.cos
local atan2 = math.atan2
local asin = math.asin
local abs = math.abs
local min = math.min
local max = math.max
local sqrt = math.sqrt
local setColor = set_color
local drawBoxM = draw_box_m
local drawSphereM = draw_sphere_m
local drawCapsuleM = draw_capsule_m
local drawObjM = draw_obj_m

---@alias EulerRotationConvention
---| 'XYZ' EULER_XYZ
---| 'ZYX' EULER_ZYX
_G.EULER_XYZ = 'XYZ'
_G.EULER_ZYX = 'ZYX'

---@alias UIElement3DShape
---| 1 CUBE
---| 2 SPHERE
---| 3 CAPSULE
---| 4 CUSTOMOBJ
---| 5 VIEWPORT
_G.CUBE = 1
_G.SPHERE = 2
_G.CAPSULE = 3
_G.CUSTOMOBJ = 4
_G.VIEWPORT = 5

---@class RenderEffect
---@field id RenderEffectId
---@field glowColor ColorId
---@field glowIntensity number
---@field ditherPixelSize integer
---@field voronoiColor ColorId
---@field voronoiScale number
---@field voronoiFresnel boolean
---@field shiftColor ColorId
---@field shiftScale number
---@field shiftPeriod number

---@type UIElement3D[]
_G.UIElement3DManager = _G.UIElement3DManager or {}
---@type UIElement3D[][]
_G.UIVisual3DManager = _G.UIVisual3DManager or {}
---@type UIElement3D[][]
_G.UIVisual3DManagerViewport = _G.UIVisual3DManagerViewport or {}

---@class UIElement3DModelCacheEntry
---@field name string Cached model file path
---@field count integer Number of UIElement3D objects that currently use the model

---@type UIElement3DModelCacheEntry[]
_G.UIElement3DModelCache = _G.UIElement3DModelCache or {}
_G.UIElement3DModelIndex = _G.UIElement3DModelIndex or 0

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
	---@field eulerConvention EulerRotationConvention Euler angles convention used to initialize object rotation
	---@field ignoreDepth boolean Whether this object should skip depth writing when being rendered

	---**Toribash 3D elements manager class**
	---
	---**Version 5.72**
	---* Voronoi and color shift effects support
	---
	---**Version 5.71**
	---* Minor performance improvements by using local references to frequently used global functions
	---
	---**Version 5.66**
	---* Added `absolute` argument support to `moveTo()` method
	---* Added support for passing a `EulerRotation` object to `rotate()` method
	---
	---**Version 5.63**
	---* `ignoreDepth` support for object rendering
	---
	---**Version 5.62**
	---* Set `GL_REPEAT` texture wrapping mode for all UIElement3D objects by default
	---@class UIElement3D : UIElement
	---@field parent UIElement3D|UIElement Parent element
	---@field child UIElement3D[] List of all object children
	---@field viewport UIElement3D|UIElement Viewport element
	---@field pos Vector3Base Object's **absolute** position in the world
	---@field shift Vector3Base Object's position **relative to its parent**
	---@field size Vector3Base Object size
	---@field rotMatrix number[][] Object's rotation as a [rotation matrix](https://en.wikipedia.org/wiki/Rotation_matrix)
	---@field rotMatrixTB MatrixTB Object's rotation as a Toribash rotation matrix
	---@field rotXYZ EulerRotation Object's rotation in [Euler angles](https://en.wikipedia.org/wiki/Euler_angles)
	---@field __rotMatrixSelf number[][] Object's own rotation as a rotation matrix
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
	---@field ignoreDepth boolean Whether this object should skip depth writing when being rendered
	---@field voronoiColor ColorId Element's voronoi (ripples) effect color ID
	---@field voronoiScale number Element's voronoi (ripples) effect scale
	---@field voronoiFresnel boolean Element's voronoi (ripples) effect fresnel state
	---@field shiftColor ColorId Element's shift effect color ID
	---@field shiftScale number Element's shift effect scale
	---@field shiftPeriod number Element's shift effect timescale modifier
	---@field effectNoUnload boolean *Experimental.* If set to `true`, will disable automatic effect unloading at the end of the draw loop, passing the effect to any objects rendered after this one.
	UIElement3D = {
		ver = 5.72
	}
	UIElement3D.__index = UIElement3D
	setmetatable(UIElement3D, UIElement)

	---**Utility class containing 3D object manipulation functionality**
	---
	---**Version 5.61**
	---* Added `MatrixToMatrixTB()` and `MatrixTBToMatrix()`
	---
	---**Version 5.60**
	---* Initial release
	---@class Utils3D
	Utils3D = {
		ver = UIElement3D.ver
	}
	Utils3D.__index = Utils3D

	---@class Vector3 : Vector3Base
	Vector3 = {}
	Vector3.__index = Vector3

	---@class EulerRotation : Vector3Base
	---@field convention EulerRotationConvention
	EulerRotation = {}
	EulerRotation.__index = EulerRotation
end

---**UIElement3D helper class** \
---*Contains functions that only get used internally and which we don't want to expose.*
---@class UIElement3DInternal
local UIElement3DInternal = {}

---Initializes a **Vector3** object
---@param x number?
---@param y number?
---@param z number?
---@return Vector3
function Vector3.New(x, y, z)
	local vector = { x = x or 0, y = y or 0, z = z or 0 }
	setmetatable(vector, Vector3)
	return vector
end

---Returns a cross product of current and given Vector3 objects
---@param other Vector3|Vector3Base
---@return Vector3
function Vector3:cross(other)
	return Vector3.New(
		self.y * other.z - self.z * other.y,
		self.z * other.x - self.x * other.z,
		self.x * other.y - self.y * other.x
	)
end

---Returns vector magnitude
---@return number
function Vector3:magnitude()
	return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

---Returns a normalized version of a vector
---@return Vector3
function Vector3:normalize()
	local mag = self:magnitude()
	if (mag == 0) then
		return Vector3.New(self.x, self.y, self.z)
	end
	return Vector3.New(self.x / mag, self.y / mag, self.z / mag)
end

---Returns a vector with the clamped magnitude
---@param max number
---@return Vector3
function Vector3:clampMagnitude(max)
	if (max <= 0) then return Vector3.New() end
	local mag = self:magnitude()
	if (max <= mag) then
		return Vector3.New(self.x, self.y, self.z)
	end
	local f = min(mag, max) / mag
	return Vector3.New(self.x * f, self.y * f, self.z * f)
end

---Returns a vector that represents current vector multiplied by a given value
---@param n number
function Vector3:multiply(n)
	return Vector3.New(self.x * n, self.y * n, self.z * n)
end

---Returns a vector produced by adding given vector to current one
---@param other Vector3|Vector3Base
---@return Vector3
function Vector3:add(other)
	return Vector3.New(self.x + other.x, self.y + other.y, self.z + other.z)
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
	return EulerRotation.New(deg(x or 0), deg(y or 0), deg(z or 0), convention)
end

---Returns a corresponding rotation matrix
---@return number[][]?
function EulerRotation:toMatrix()
	return Utils3D.GetMatrixFromEuler(rad(self.x), rad(self.y), rad(self.z), self.convention)
end

---Returns a corresponding Toribash rotation matrix and a regular rotation matrix
---@return MatrixTB
---@return number[][]
function EulerRotation:toMatrixTB()
	local matrix = self:toMatrix() or Utils3D.MatrixIdentity()
	return Utils3D.MatrixToMatrixTB(matrix), matrix
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
		child = { },
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
		local eulerRotation = EulerRotation.New(o.rot[1], o.rot[2], o.rot[3], o.eulerConvention)
		---@diagnostic disable-next-line: assign-type-mismatch
		elem.__rotMatrixSelf = eulerRotation:toMatrix()
		if (elem.parent) then
			---@diagnostic disable-next-line: assign-type-mismatch, param-type-mismatch
			elem.rotMatrix = Utils3D.MatrixMultiply(elem.__rotMatrixSelf, elem.parent.rotMatrix)
		else
			elem.rotMatrix = table.clone(elem.__rotMatrixSelf)
		end
	else
		elem.__rotMatrixSelf = Utils3D.MatrixIdentity()
		elem.rotMatrix = table.clone(elem.parent and elem.parent.rotMatrix or elem.__rotMatrixSelf)
	end
	elem.rotMatrixTB = Utils3D.MatrixToMatrixTB(elem.rotMatrix)
	elem.rotXYZ = Utils3D.GetEulerFromMatrix(elem.rotMatrix, EULER_XYZ)

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
		if (elem.bgImage) then
			---Always set GL_REPEAT for UIElement3D objects by default, some of our default shapes' UVs rely on it
			set_texture_wrapmode(elem.bgImage, TEXTURE_WRAP.REPEAT)
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
		elem.voronoiColor = o.effects.voronoiColor or 0
		elem.voronoiScale = o.effects.voronoiScale or 0
		elem.voronoiFresnel = o.effects.voronoiFresnel == nil and true or o.effects.voronoiFresnel
		elem.shiftColor = o.effects.shiftColor or 0
		elem.shiftScale = o.effects.shiftScale or 0
		elem.shiftPeriod = o.effects.shiftPeriod or 1
	end
	if (o.ignoreDepth) then
		elem.ignoreDepth = o.ignoreDepth
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
		set_draw_effect(self.effectid, self.glowColor, self.glowIntensity, self.ditherPixelSize, self.voronoiScale, self.voronoiFresnel, self.voronoiColor, self.shiftColor, self.shiftScale, self.shiftPeriod)
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
			setColor(self.animateColor[1], self.animateColor[2], self.animateColor[3], self.animateColor[4])
		elseif (self.hoverState == BTN_DN and self.pressedColor) then
			setColor(self.pressedColor[1], self.pressedColor[2], self.pressedColor[3], self.pressedColor[4])
		else
			setColor(self.bgColor[1], self.bgColor[2], self.bgColor[3], self.bgColor[4])
		end
		if (self.shapeType == CUBE) then
			self:drawBox()
		elseif (self.shapeType == SPHERE) then
			self:drawSphere()
		elseif (self.shapeType == CAPSULE) then
			self:drawCapsule()
		elseif (self.shapeType == CUSTOMOBJ and self.objModel ~= nil) then
			drawObjM(self.objModel, self.pos.x, self.pos.y, self.pos.z, self.size.x, self.size.y, self.size.z, self.rotMatrixTB, self.ignoreDepth)
		end
	end
	if (self.customDisplay) then
		self.customDisplay()
	end
	if (self.effectid and self.effectNoUnload ~= true) then
		set_draw_effect(0)
	end
end

---Generic internal function to draw a cube UIElement3D object. \
---*You likely don't need to run this manually.*
function UIElement3D:drawBox()
	if (self.playerAttach) then
		local body = get_body_info(self.playerAttach, self.attachBodypart)
		drawBoxM(body.pos.x + self.pos.x, body.pos.y + self.pos.y, body.pos.z + self.pos.z, self.size.x, self.size.y, self.size.z, body.rot, self.bgImage, self.ignoreDepth)
	else
		drawBoxM(self.pos.x, self.pos.y, self.pos.z, self.size.x, self.size.y, self.size.z, self.rotMatrixTB, self.bgImage, self.ignoreDepth)
	end
end

---Generic internal function to draw a capsule UIElement3D object. \
---*You likely don't need to run this manually.*
function UIElement3D:drawCapsule()
	if (self.playerAttach and self.attachBodypart) then
		local body = get_body_info(self.playerAttach, self.attachBodypart)
		drawCapsuleM(body.pos.x, body.pos.y, body.pos.z, self.size.y, self.size.x, body.rot, self.bgImage, self.ignoreDepth)
	else
		local drawPos = (self.playerAttach and self.attachJoint) and get_joint_pos2(self.playerAttach, self.attachJoint) or self.pos
		drawCapsuleM(drawPos.x, drawPos.y, drawPos.z, self.size.y, self.size.x, self.rotMatrixTB, self.bgImage, self.ignoreDepth)
	end
end

---Generic internal function to draw a sphere UIElement3D object. \
---*You likely don't need to run this manually.*
function UIElement3D:drawSphere()
	if (self.playerAttach and self.attachBodypart) then
		local body = get_body_info(self.playerAttach, self.attachBodypart)
		drawSphereM(body.pos.x + self.pos.x, body.pos.y + self.pos.y, body.pos.z + self.pos.z, self.size.x, body.rot, self.bgImage, self.ignoreDepth)
	else
		local drawPos = (self.playerAttach and self.attachJoint) and get_joint_pos2(self.playerAttach, self.attachJoint) or self.pos
		local scale = (self.playerAttach and self.attachJoint) and get_joint_radius(self.playerAttach, self.attachJoint) or 1

		if (self.bgImage) then
			drawSphereM(drawPos.x, drawPos.y, drawPos.z, self.size.x * scale, self.rotMatrixTB, self.bgImage, self.ignoreDepth)
		else
			drawSphereM(drawPos.x, drawPos.y, drawPos.z, self.size.x * scale, nil, nil, self.ignoreDepth)
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
---@overload fun(globalid: integer)
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

---Internal function to set the shift and global position of the current UIElement3D in relation to its parent
---@param object UIElement3D
function UIElement3DInternal.SetChildPosition(object)
	if (object.parent == nil) then
		return
	end

	local rotatedShift = Utils3D.MatrixMultiply({ { object.shift.x, object.shift.y, object.shift.z } }, object.parent.rotMatrix)
	if (rotatedShift) then
		local newShift = rotatedShift[1]
		object.pos.x = object.parent.pos.x + newShift[1]
		object.pos.y = object.parent.pos.y + newShift[2]
		object.pos.z = object.parent.pos.z + newShift[3]
	end
end

---Internal function to update positions of all the current UIElement3D object's children
---@param object UIElement3D
function UIElement3DInternal.UpdateChildrenPosition(object)
	for _, v in pairs(object.child) do
		UIElement3DInternal.UpdatePosition(v)
	end
end

---Internal function to update absolute position of the UIElement3D object and all its children
---@param object UIElement3D
function UIElement3DInternal.UpdatePosition(object)
	if (object.parent) then
		UIElement3DInternal.SetChildPosition(object)
	end
	UIElement3DInternal.UpdateChildrenPosition(object)
end

---Moves the UIElement3D object and updates its and its children's absolute positions accordingly. \
---Unlike UIElement method, this moves object relatively to its current position by default. Pass `true` as `absolute` value to override this behavior.
---@param x number
---@param y number
---@param z number
---@param absolute ?boolean
function UIElement3D:moveTo(x, y, z, absolute)
	if (self.playerAttach) then
		return
	end
	if (self.parent) then
		if (absolute == true) then
			if (x) then self.shift.x = x end
			if (y) then self.shift.y = y end
			if (z) then self.shift.z = z end
		else
			if (x) then self.shift.x = self.shift.x + x end
			if (y) then self.shift.y = self.shift.y + y end
			if (z) then self.shift.z = self.shift.z + z end
		end
	elseif (absolute == true) then
		if (x) then self.pos.x = x end
		if (y) then self.pos.y = y end
		if (z) then self.pos.z = z end
	else
		if (x) then self.pos.x = self.pos.x + x end
		if (y) then self.pos.y = self.pos.y + y end
		if (z) then self.pos.z = self.pos.z + z end
	end

	UIElement3DInternal.UpdatePosition(self)
end

---Internal function to handle rotation of a UIElement3D object and its children
---@param object UIElement3D
---@param rotMatrix number[][]
function UIElement3DInternal.Rotate(object, rotMatrix)
	local newRotMatrix = Utils3D.MatrixMultiply(object.__rotMatrixSelf, rotMatrix)
	if (newRotMatrix == nil) then return end

	object.__rotMatrixSelf = newRotMatrix
	if (object.parent) then
		---@diagnostic disable-next-line: assign-type-mismatch, param-type-mismatch
		object.rotMatrix = Utils3D.MatrixMultiply(object.__rotMatrixSelf, object.parent.rotMatrix)
	else
		object.rotMatrix = table.clone(object.__rotMatrixSelf)
	end
	object.rotMatrixTB = Utils3D.MatrixToMatrixTB(object.rotMatrix)
	object.rotXYZ = Utils3D.GetEulerFromMatrix(object.rotMatrix, EULER_XYZ)

	for _, v in pairs(object.child) do
		UIElement3DInternal.RotateChild(v)
	end
end

function UIElement3DInternal.RotateChild(object)
	if (object.parent == nil) then return end

	object.rotMatrix = Utils3D.MatrixMultiply(object.__rotMatrixSelf, object.parent.rotMatrix) or object.rotMatrix
	object.rotMatrixTB = Utils3D.MatrixToMatrixTB(object.rotMatrix)
	object.rotXYZ = Utils3D.GetEulerFromMatrix(object.rotMatrix, EULER_XYZ)

	for _, v in pairs(object.child) do
		UIElement3DInternal.RotateChild(v)
	end
end

---Rotates the object and updates all its children accordingly
---@param x ?number
---@param y ?number
---@param z ?number
---@overload fun(self: UIElement3D, rotation: EulerRotation)
function UIElement3D:rotate(x, y, z)
	local eulerRotation = nil
	if (type(x) ~= "table" or x.convention == nil) then
		---@diagnostic disable-next-line: cast-local-type
		x = x or 0
		y = y or 0
		z = z or 0
		if (x == 0 and y == 0 and z == 0) then
			return
		end
		---@diagnostic disable-next-line: param-type-mismatch
		eulerRotation = EulerRotation.New(x, y, z)
	else
		eulerRotation = x
	end

	local rotation = eulerRotation:toMatrix()
	if (rotation ~= nil) then
		UIElement3DInternal.Rotate(self, rotation)
		UIElement3DInternal.UpdateChildrenPosition(self)
	end
end

---Resets object's rotation and sets own rotation matrix to identity
function UIElement3D:resetRotation()
	self.__rotMatrixSelf = Utils3D.MatrixIdentity()
	UIElement3DInternal.Rotate(self, Utils3D.MatrixIdentity())
	UIElement3DInternal.UpdateChildrenPosition(self)
end

---Syncs object's rotation to attached bodypart
---@param updateChildPosition boolean? *Defaults to `true`* \
---@see UIElement3D.syncPlayer
---@see UIElement3D.syncPlayerPosition
function UIElement3D:syncPlayerRotation(updateChildPosition)
	if (self.parent ~= nil or self.playerAttach == nil or self.attachBodypart == nil) then return end
	self.__rotMatrixSelf = Utils3D.MatrixTBToMatrix(get_body_info(self.playerAttach, self.attachBodypart).rot)
	UIElement3DInternal.Rotate(self, Utils3D.MatrixIdentity())
	if (updateChildPosition ~= false) then
		UIElement3DInternal.UpdateChildrenPosition(self)
	end
end

---Syncs object's position to attached bodypart \
---@see UIElement3D.syncPlayer
---@see UIElement3D.syncPlayerRotation
function UIElement3D:syncPlayerPosition()
	if (self.parent ~= nil or self.playerAttach == nil or self.attachBodypart == nil) then return end
	self.pos = get_body_info(self.playerAttach, self.attachBodypart).pos
	UIElement3DInternal.UpdatePosition(self)
end

---Syncs object's position and rotation to attached bodypart \
---@see UIElement3D.syncPlayerRotation
---@see UIElement3D.syncPlayerPosition
function UIElement3D:syncPlayer()
	self:syncPlayerRotation(false)
	self:syncPlayerPosition()
end

---Helper function to get the Euler angles from a rotation matrix. \
---*Only `EULER_XYZ` and `EULER_ZYX` conventions are supported.*
---@param R number[][]
---@param convention ?EulerRotationConvention
---@return EulerRotation
function Utils3D.GetEulerFromMatrix(R, convention)
	convention = convention or EULER_XYZ
	local x, y, z = 0, 0, 0
	if (convention == EULER_XYZ) then
		x = atan2(-R[2][3], R[3][3])
		local sinx = sin(x)
		local cosx = cos(x)
		y = atan2(R[1][3], R[3][3] * cosx - R[2][3] * sinx)
		z = atan2(R[2][1] * cosx + R[3][1] * sinx, R[2][2] * cosx + R[3][2] * sinx)
	elseif (convention == EULER_ZYX) then
		local clamp = R[3][1] > 1 and 1 or (R[3][1] < -1 and -1 or R[3][1])
		y = asin(-clamp)
		if (0.99999 > abs(R[3][1])) then
			x = atan2(R[3][2], R[3][3])
			z = atan2(R[2][1], R[1][1])
		else
			x = 0
			z = atan2(-R[1][2], R[2][2])
		end
	else
		error("UIElement3D.GetEulerFromMatrix() unsupported convention: " .. convention)
	end

	return EulerRotation.New(deg(x), deg(y), deg(z), convention)
end

---Legacy function to get ZYX euler angles rotation from rotation matrix. \
---@see Utils3D.GetEulerFromMatrix
---@param R number[][]
---@return number x
---@return number y
---@return number z
---@deprecated
function UIElement3D:getEulerZYXFromRotationMatrix(R)
	local rotation = Utils3D.GetEulerFromMatrix(R, EULER_ZYX)
	return rotation.x, rotation.y, rotation.z
end

---Legacy function to get XYZ euler angles rotation from rotation matrix. \
---@see Utils3D.GetEulerFromMatrix
---@param R number[][]
---@return number x
---@return number y
---@return number z
---@deprecated
function UIElement3D:getEulerXYZFromRotationMatrix(R)
	local rotation = Utils3D.GetEulerFromMatrix(R, EULER_XYZ)
	return rotation.x, rotation.y, rotation.z
end

---Utility function to convert a rotation matrix to Toribash rotation matrix
---@param rTB MatrixTB|number[]|number[][]
---@return MatrixTB
function Utils3D.MatrixToMatrixTB(rTB)
	if (rTB.r0 ~= nil) then
		return rTB
	end
	if (type(rTB[1]) == "number") then
		return {
			r0 = rTB[1],	r1 = rTB[2],	r2 = rTB[3],	r3 = rTB[4],
			r4 = rTB[5],	r5 = rTB[6],	r6 = rTB[7],	r7 = rTB[8],
			r8 = rTB[9],	r9 = rTB[10],	r10 = rTB[11],	r11 = rTB[12]
		}
	end
	return {
		r0 = rTB[1][1],		r1 = rTB[2][1],		r2 = rTB[3][1],	 r3 = 0,
		r4 = rTB[1][2],		r5 = rTB[2][2],		r6 = rTB[3][2],	 r7 = 0,
		r8 = rTB[1][3],		r9 = rTB[2][3],		r10 = rTB[3][3], r11 = 0
	}
end

---Utility function to convert Toribash rotation matrix to a regular one
---@param mTB MatrixTB
---@return number[][]
function Utils3D.MatrixTBToMatrix(mTB)
	if (mTB.r0 == nil) then
		return Utils3D.MatrixIdentity()
	end
	return {
		{ mTB.r0, mTB.r4, mTB.r8 },
		{ mTB.r1, mTB.r5, mTB.r9 },
		{ mTB.r2, mTB.r6, mTB.r10 }
	}
end

---Helper function to get the rotation in Euler angles from a Toribash rotation matrix
---@param rTB MatrixTB|number[]|number[][]
---@return EulerRotation
---@nodiscard
function Utils3D.GetEulerFromMatrixTB(rTB)
	rTB = Utils3D.MatrixToMatrixTB(rTB)
	return Utils3D.GetEulerFromMatrix({
		{ rTB.r0, rTB.r1, rTB.r2 },
		{ rTB.r4, rTB.r5, rTB.r6 },
		{ rTB.r8, rTB.r9, rTB.r10 }
	}, EULER_ZYX)
end

---Legacy function to get euler angles from Toribash rotation matrix. \
---@see Utils3D.GetEulerFromMatrixTB
---@param rTB MatrixTB
---@return number x
---@return number y
---@return number z
---@deprecated
function UIElement3D:getEulerAnglesFromMatrixTB(rTB)
	local rotation = Utils3D.GetEulerFromMatrixTB(rTB)
	return rotation.x, rotation.y, rotation.z
end

---Helper function to get the rotation matrix from Euler angles with the specified convention. \
---*Only `EULER_XYZ` and `EULER_ZYX` conventions are currently supported.*
---@param x number
---@param y number
---@param z number
---@param convention ?EulerRotationConvention
---@return number[][]
function Utils3D.GetMatrixFromEuler(x, y, z, convention)
	convention = convention and string.upper(convention) or EULER_XYZ
	local c1 = cos(x)
	local s1 = sin(x)
	local c2 = cos(y)
	local s2 = sin(y)
	local c3 = cos(z)
	local s3 = sin(z)

	local R = {}
	for i = 1, 3 do
		local axis = string.sub(convention, i, i)
		if (axis == 'X') then
			R[i] = {
				{ 1, 0, 0 },
				{ 0, c1, -s1 },
				{ 0, s1, c1 }
			}
		elseif (axis == 'Y') then
			R[i] = {
				{ c2, 0, s2 },
				{ 0, 1, 0 },
				{ -s2, 0, c2 }
			}
		else
			R[i] = {
				{ c3, -s3, 0 },
				{ s3, c3, 0 },
				{ 0, 0, 1}
			}
		end
	end

	---@diagnostic disable-next-line: param-type-mismatch, return-type-mismatch
	return Utils3D.MatrixMultiply(Utils3D.MatrixMultiply(R[3], R[2]), R[1])
end

---Legacy function to get rotation matrix from euler angles. \
---@see Utils3D.GetMatrixFromEuler
---@param x number
---@param y number
---@param z number
---@return number[][]?
---@deprecated
function UIElement3D:getRotMatrixFromEulerAngles(x, y, z)
	return Utils3D.GetMatrixFromEuler(x, y, z, EULER_XYZ)
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
function Utils3D.MatrixMultiply(a, b)
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

---Returns an identity matrix (3x3)
---@return number[][]
function Utils3D.MatrixIdentity()
	return {
		{ 1, 0, 0 },
		{ 0, 1, 0 },
		{ 0, 0, 1 }
	}
end

---Returns inverse matrix
---@param matrix number[][]
---@return number[][]
function Utils3D.MatrixInverse(matrix)
	local inverse = { }
	for i, row in pairs(matrix) do
		inverse[i] = { }
		for j, _ in pairs(row) do
			inverse[i][j] = matrix[j][i]
		end
	end
	return inverse
end

---Legacy function to multiply matrices. \
---@see Utils3D.MatrixMultiply
---@param a number[][]
---@param b number[][]|number[]|number
---@return number[][]|number[]|nil
---@deprecated
function UIElement3D:multiply(a, b)
	return Utils3D.MatrixMultiply(a, b)
end

---Legacy function to multiply a matrix by number. \
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
		for i, _ in pairs(UIElement3DModelCache) do
			if (i == self.objModel) then
				id = i
				break
			end
		end
		UIElement3DModelCache[id].count = UIElement3DModelCache[id].count - 1
		if (UIElement3DModelCache[id].count == 0) then
			unload_obj(self.objModel)
			UIElement3DModelCache[id] = nil
			UIElement3DModelIndex = UIElement3DModelIndex - 1
		end
		self.objModel = nil
	end

	if (not model) then
		return true
	end
	if (UIElement3DModelIndex > 126) then
		return false
	end

	local objFile = Files.Open("../" .. filename .. ".obj")
	if (not objFile.data) then
		return false
	end
	objFile:close()

	local objid = -1
	for i = 0, 127 do
		if (UIElement3DModelCache[i]) then
			if (UIElement3DModelCache[i].name == filename) then
				self.objModel = i
				UIElement3DModelCache[i].count = UIElement3DModelCache[i].count + 1
				return true
			end
		elseif (objid < 0) then
			objid = i
		end
	end

	if (load_obj(objid, filename, 1)) then
		self.objModel = objid
	end
	UIElement3DModelCache[objid] = { name = filename, count = 1 }
	UIElement3DModelIndex = max(UIElement3DModelIndex, objid)
	return true
end
