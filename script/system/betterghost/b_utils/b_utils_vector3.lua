---Better Ghost by bleed
---Draws a ghost showing where each fighter will be when the current turn ends
---Original post: https://forum.toribash.com/showthread.php?t=672946
---
---@author bleed (original)
---@author surge (modifications)
---@author AssassinPro, niavic, barbarbar, LostMail (additional credits)

---@class BetterGhostVector3
local vector3 = {}

---Turns a ghost cache position (`{ x, y, z }`) into a vector
---@param array number[]
---@return Vector3Base
function vector3.from_array(array)
	return { x = array[1], y = array[2], z = array[3] }
end

---@param a Vector3Base
---@param b Vector3Base
---@return Vector3Base
function vector3.add(a, b)
	return { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
end

---@param a Vector3Base
---@param b Vector3Base
---@return Vector3Base
function vector3.subtract(a, b)
	return { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
end

---Adds the same amount to each component
---@param vector Vector3Base
---@param amount number
---@return Vector3Base
function vector3.add_to_each(vector, amount)
	return { x = vector.x + amount, y = vector.y + amount, z = vector.z + amount }
end

---Rotates a vector by the inverse of a rotation
---@param rotation BetterGhostQuaternion
---@param vector Vector3Base
---@return Vector3Base
function vector3.rotate_by_inverse(rotation, vector)
	local w, x, y, z = rotation.w, rotation.x, rotation.y, rotation.z
	return {
		x = vector.x * (1 - 2 * y * y - 2 * z * z) + vector.y * 2 * (x * y + w * z) + vector.z * 2 * (x * z - w * y),
		y = vector.x * 2 * (x * y - w * z) + vector.y * (1 - 2 * x * x - 2 * z * z) + vector.z * 2 * (y * z + w * x),
		z = vector.x * 2 * (x * z + w * y) + vector.y * 2 * (y * z - w * x) + vector.z * (1 - 2 * x * x - 2 * y * y),
	}
end

return vector3
