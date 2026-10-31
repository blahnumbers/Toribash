---Better Ghost by bleed
---Draws a ghost showing where each fighter will be when the current turn ends
---Original post: https://forum.toribash.com/showthread.php?t=672946
---
---@author bleed (original)
---@author surge (modifications)
---@author AssassinPro, niavic, barbarbar, LostMail (additional credits)

---@class BetterGhostQuaternion
---@field w number
---@field x number
---@field y number
---@field z number

---@class BetterGhostRotation
local rotation = {}

---@param value number
---@return integer
local function get_sign(value)
	return value >= 0 and 1 or -1
end

---Turns a ghost cache rotation (`{ w, x, y, z }`) into a quaternion
---@param array number[]
---@return BetterGhostQuaternion
function rotation.from_array(array)
	return { w = array[1], x = array[2], y = array[3], z = array[4] }
end

---Creates a quaternion from a body's rotation matrix
---@param matrix MatrixTB
---@return BetterGhostQuaternion
function rotation.from_matrix(matrix)
	local w = math.sqrt(math.max(0, 1 + matrix.r0 + matrix.r5 + matrix.r10)) / 2
	local x = math.sqrt(math.max(0, 1 + matrix.r0 - matrix.r5 - matrix.r10)) / 2
	local y = math.sqrt(math.max(0, 1 - matrix.r0 + matrix.r5 - matrix.r10)) / 2
	local z = math.sqrt(math.max(0, 1 - matrix.r0 - matrix.r5 + matrix.r10)) / 2
	return {
		w = w,
		x = x * get_sign(x * (matrix.r9 - matrix.r6)),
		y = y * get_sign(y * (matrix.r2 - matrix.r8)),
		z = z * get_sign(z * (matrix.r4 - matrix.r1)),
	}
end

---@param quaternion BetterGhostQuaternion
---@return BetterGhostQuaternion
function rotation.invert(quaternion)
	local w, x, y, z = quaternion.w, quaternion.x, quaternion.y, quaternion.z
	local length_squared = w * w + x * x + y * y + z * z
	return { w = w / length_squared, x = -x / length_squared, y = -y / length_squared, z = -z / length_squared }
end

---Converts a quaternion to XYZ Euler angles in degrees, as `UIElement3D:rotate()` takes them
---@param quaternion BetterGhostQuaternion
---@return Vector3Base
function rotation.to_euler_degrees(quaternion)
	local w, x, y, z = quaternion.w, quaternion.x, quaternion.y, quaternion.z
	local pitch_sine = 2 * x * z + 2 * y * w
	return {
		x = math.deg(math.atan2(2 * y * z - 2 * x * w, 1 - 2 * x * x - 2 * y * y)),
		y = math.deg(math.atan2(-2 * x * z - 2 * y * w, math.sqrt(1 - pitch_sine * pitch_sine))),
		z = math.deg(math.atan2(2 * x * y - 2 * z * w, 1 - 2 * y * y - 2 * z * z)),
	}
end

return rotation
