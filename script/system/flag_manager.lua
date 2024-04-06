if (FlagManager == nil) then
	---**Flags manager class**
	---
	---Use this to retrieve flag texture information for Toribash flag codes
	---@class FlagManager
	FlagManager = {
		ver = 5.60
	}
	FlagManager.__index = FlagManager
end

---@class AtlasData
---@field filename string
---@field atlas Rect

---Helper class for **Flags manager**
---@class FlagManagerInternal
---@field AtlasDimensions Vector2Base
---@field FlagTextureSize Vector2Base
---@field FlagFiles string[]
---@field FlagsPerAtlas integer
---@field FlagCache string[]
local FlagManagerInternal = {
	AtlasDimensions = { x = 256, y = 256 },
	FlagTextureSize = { x = 16, y = 16 },
	FlagFiles = {
		"../textures/flag0.tga",
		"../textures/flag1.tga"
	}
}
FlagManagerInternal.__index = FlagManagerInternal

FlagManagerInternal.FlagsPerAtlas = math.floor(FlagManagerInternal.AtlasDimensions.x * FlagManagerInternal.AtlasDimensions.y / FlagManagerInternal.FlagTextureSize.x / FlagManagerInternal.FlagTextureSize.y)
FlagManagerInternal.FlagCache = {
	---Begin flag0.tga
	"AA", "AB", "AC", "AD", "AE", "AF", "AG", "AI", "AK", "AL", "AM", "AN", "AO", "AQ", "AR", "AS",
	"AT", "AU", "AW", "AX", "AY", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BL",
	"BM", "BN", "BO", "BQ", "BR", "BS", "BT", "BU", "BV", "BW", "BY", "BZ", "CA", "CC", "CD", "CF",
	"CG", "CH", "CI", "CK", "CL", "CM", "CN", "CO", "CP", "CR", "CS", "CU", "CV", "CW", "CX", "CY",
	"CZ", "DE", "DG", "DJ", "DK", "DM", "DO", "DY", "DZ", "EA", "EC", "EE", "EG", "EH", "EN", "ER",
	"ES", "ET", "EU", "EW", "FI", "FJ", "FK", "FL", "FM", "FO", "FR", "FX", "GA", "GB", "GC", "GD",
	"GE", "GF", "GG", "GH", "GI", "GL", "GM", "GN", "GP", "GQ", "GR", "GS", "GT", "GU", "GW", "GY",
	"HE", "HK", "HM", "HN", "HR", "HT", "HU", "IC", "ID", "IE", "IL", "IM", "IN", "IO", "IQ", "IR",
	"IS", "IT", "JA", "JE", "JM", "JO", "JP", "KA", "KE", "KG", "KH", "KI", "KM", "KN", "KP", "KR",
	"KW", "KY", "KZ", "LA", "LB", "LC", "LF", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "LY", "MA",
	"MC", "MD", "ME", "MF", "MG", "MH", "MK", "ML", "MM", "MN", "MO", "MP", "MQ", "MR", "MS", "MT",
	"MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NC", "NE", "NF", "NG", "NI", "NL", "NO", "NP", "NR",
	"NU", "NZ", "OM", "PA", "PE", "PF", "PG", "PH", "PI", "PK", "PL", "PM", "PN", "PR", "PS", "PT",
	"PW", "PY", "QA", "RA", "RB", "RC", "RE", "RH", "RI", "RL", "RM", "RN", "RO", "RP", "RS", "RU",
	"RW", "RZ", "SA", "SB", "SC", "SD", "SE", "SF", "SG", "SH", "SI", "SJ", "SK", "SL", "SM", "SN",
	"SO", "SQ", "SR", "SS", "ST", "SU", "SV", "SX", "SY", "SZ", "TA", "TC", "TD", "TF", "TG", "TH",
	---End of flag0.tga, begin flag1.tga
	"TJ", "TK", "TL", "TM", "TN", "TO", "TP", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "UK", "UM",
	"US", "UY", "UZ", "VA", "VC", "VE", "VG", "VI", "VN", "VU", "WA", "WF", "WG", "WL", "WO", "WS",
	"WV", "YE", "YT", "YU", "YV", "ZA", "ZM", "ZR", "ZW",
	---Pride flags
	"GAY", "LGG", "LSB", "TRN", "BIS", "MLM", "NBY",
	---Additional country flags
	"ENG", "WAL", "SCT", "NIR"
}

---Returns flag texture information from country code
---@param code string
---@return AtlasData
function FlagManager.GetFlagInfoByCode(code)
	local flagId = 1
	for i, v in pairs(FlagManagerInternal.FlagCache) do
		if (code == v) then
			flagId = i
		end
	end

	local fileId = math.floor(flagId / FlagManagerInternal.FlagsPerAtlas)
	local flagId = flagId - fileId * FlagManagerInternal.FlagsPerAtlas
	local flagLine = math.ceil(flagId / FlagManagerInternal.FlagTextureSize.y) - 1
	local flagSpot = (flagId - 1) % FlagManagerInternal.FlagTextureSize.x

	---@type AtlasData
	local flagData = {
		filename = FlagManagerInternal.FlagFiles[fileId + 1],
		atlas = {
			x = flagSpot * FlagManagerInternal.FlagTextureSize.x,
			y = flagLine * FlagManagerInternal.FlagTextureSize.y,
			w = FlagManagerInternal.FlagTextureSize.x,
			h = FlagManagerInternal.FlagTextureSize.y
		}
	}
	return flagData
end
