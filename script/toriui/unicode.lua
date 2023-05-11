if (UnicodeString == nil) then
	---@class UnicodeString
	---@field data string|nil Unicode symbols for the string
	UnicodeString = { ver = 5.60 }
	UnicodeString.__index = UnicodeString
end

---@type UnicodeString
local emptyString = { data = "" }
setmetatable(emptyString, UnicodeString)

---Creates a new `UnicodeString` object and populates it with provided Unicode data
---@param data string
---@return UnicodeString
function UnicodeString.New(data)
	local newString = { data = data }
	setmetatable(newString, UnicodeString)
	return newString
end

---Converts a UTF8 string to `UnicodeString` class object
---@param string string
---@return UnicodeString
function UnicodeString.FromUTF8(string)
	if type(string) ~= "string" then
		return string
	end

	local tb_result = {}
	local i = 0
	while true do
		i = i + 1
		local numbyte = string.byte(string, i)
		if not numbyte then
			break
		end

		local value1, value2

		if numbyte >= 0x00 and numbyte <= 0x7f then
			value1 = numbyte
			value2 = 0
		elseif bit.band(numbyte, 0xe0) == 0xc0 then
			local t1 = bit.band(numbyte, 0x1f)
			i = i + 1
			local t2 = bit.band(string.byte(string, i), 0x3f)

			value1 = bit.bor(t2, bit.lshift(bit.band(t1, 0x03), 6))
			value2 = bit.rshift(t1, 2)
		elseif bit.band(numbyte, 0xf0) == 0xe0 then
			local t1 = bit.band(numbyte, 0x0f)
			i = i + 1
			local t2 = bit.band(string.byte(string, i), 0x3f)
			i = i + 1
			local t3 = bit.band(string.byte(string, i), 0x3f)

			value1 = bit.bor(bit.lshift(bit.band(t2, 0x03), 6), t3)
			value2 = bit.bor(bit.lshift(t1, 4), bit.rshift(t2, 2))
		else
			return table.clone(emptyString)
		end

		tb_result[#tb_result + 1] = string.format("\\u%02x%02x", value2, value1)
	end

	---@class UnicodeString
	local unicodeString = table.clone(emptyString)
	unicodeString.data = table.concat(tb_result)
	setmetatable(unicodeString, UnicodeString)
	return unicodeString
end

---Converts a Unicode string back to a readable UTF8 string
---@return string
function UnicodeString:ToUTF8()
	local tb_result = {}
	local i = 1
	while true do
		local numbyte = string.byte(self.data, i)
		if not numbyte then
			break
		end

		local substr = string.sub(self.data, i, i + 1)
		if (substr == "\\u" or substr == "%u") then
			local unicode = tonumber("0x" .. string.sub(self.data, i + 2, i + 5))
			if not unicode then
				tb_result[#tb_result + 1] = substr
				i = i + 2
			else

				i = i + 6

				if unicode <= 0x007f then
					-- 0xxxxxxx
					tb_result[#tb_result + 1] = string.char(bit.band(unicode, 0x7f))
				elseif unicode >= 0x0080 and unicode <= 0x07ff then
					-- 110xxxxx 10xxxxxx
					tb_result[#tb_result + 1] = string.char(bit.bor(0xc0, bit.band(bit.rshift(unicode, 6), 0x1f)))
					tb_result[#tb_result + 1] = string.char(bit.bor(0x80, bit.band(unicode, 0x3f)))
				elseif unicode >= 0x0800 and unicode <= 0xffff then
					-- 1110xxxx 10xxxxxx 10xxxxxx
					tb_result[#tb_result + 1] = string.char(bit.bor(0xe0, bit.band(bit.rshift(unicode, 12), 0x0f)))
					tb_result[#tb_result + 1] = string.char(bit.bor(0x80, bit.band(bit.rshift(unicode, 6), 0x3f)))
					tb_result[#tb_result + 1] = string.char(bit.bor(0x80, bit.band(unicode, 0x3f)))
				end
			end
		else
			tb_result[#tb_result + 1] = string.char(numbyte)
			i = i + 1
		end
	end

	return table.concat(tb_result)
end
