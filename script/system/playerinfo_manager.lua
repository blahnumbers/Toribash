-- Player info fetcher
require("system.iofiles")
require("system.network_request")
require("system.ranking_manager")
require("system.clans_manager")

---@alias PlayerInfoScope
---| 0 None | PLAYERINFO_SCOPE_NONE
---| 1 General (balance, belt) | PLAYERINFO_SCOPE_GENERAL
PLAYERINFO_SCOPE_NONE = 0
PLAYERINFO_SCOPE_GENERAL = 1

---@alias PlayerInfoCustomsScope
---| 1 Colors | PLAYERINFO_CSCOPE_COLORS
---| 2 Textures | PLAYERINFO_CSCOPE_TEXTURES
---| 3 Colors + Textures
---| 4 Objects | PLAYERINFO_CSCOPE_OBJECTS
---| 5 Colors + Objects
---| 6 Textures + Objects
---| 7 Colors + Textures + Objects
---| 8 Effects | ITEMS_CSCOPE_EFFECTS
---| 9 Colors + Effects
---| 10 Textures + Effects
---| 11 Colors + Textures + Effects
---| 12 Objects + Effects
---| 13 Colors + Objects + Effects
---| 14 Textures + Objects + Effects
---| 15 Colors + Textures + Objects + Effects | PLAYERINFO_CSCOPE_ALL
PLAYERINFO_CSCOPE_COLORS = 1
PLAYERINFO_CSCOPE_TEXTURES = 2
PLAYERINFO_CSCOPE_OBJECTS = 4
PLAYERINFO_CSCOPE_EFFECTS = 8
PLAYERINFO_CSCOPE_ALL = bit.bor(PLAYERINFO_CSCOPE_COLORS, PLAYERINFO_CSCOPE_TEXTURES, PLAYERINFO_CSCOPE_OBJECTS, PLAYERINFO_CSCOPE_EFFECTS)

if (PlayerInfo == nil) then
	---**Player information class**
	---
	---**Version 5.60**
	---* Object-oriented approach, introduced **PlayerInfo.Get()** function that returns an object to work with
	---* Added documentation with EmmyLua annotations
	---@class PlayerInfo
	---@field username string
	---@field clan PlayerInfoClan
	---@field items PlayerInfoCustoms
	---@field ranking PlayerInfoRanking
	---@field data PlayerInfoData
	---@field __isCurrentUser boolean Internal flag that will be set to `true` if this data belongs to the currently logged in user
	PlayerInfo = {
		ver = 5.60
	}
	PlayerInfo.__index = PlayerInfo
end

---**PlayerInfo** helper class \
---@see PlayerInfo
---@class PlayerInfoInternal
local PlayerInfoInternal = {}

---Shortcut function to retrieve a setting from `get_master()`
---@param option ?PlayerMasterOption
---@return boolean|number|string
---@overload fun():PlayerMasterInfo
function PlayerInfoInternal.getMaster(option)
	local returnVal = nil
	if (option) then
		returnVal = get_master().master[option]
	else
		returnVal = get_master().master
	end
	return returnVal
end

---Internal function to escape the name with clan tag and preceding prefixes
---@param name string
---@return string
---@return string
function PlayerInfoInternal.escapeName(name)
	local player_name, clan_tag = name, ""
	local braces = { "[]", "()", "{}" }

	for _, v in pairs(braces) do
		clan_tag = name:match("%b" .. v)
		if (clan_tag) then
			clan_tag = clan_tag:gsub("%W", "")
			player_name = player_name:gsub(".*%b" .. v, "")
			break
		end
	end

	return player_name, clan_tag
end

---Fetches current user's cleaned name or purifies a specified username. \
---*Not preferred as of Toribash 5.60, use PlayerInfo.Get() instead*
---@deprecated
---@param player? string Custom username that we want to clean from clan tag or any prefixes
---@return string
function PlayerInfo:getUser(player)
	local player_name = player or PlayerInfoInternal.getMaster("nick")
	---@diagnostic disable-next-line: param-type-mismatch
	local name_clean = PlayerInfoInternal.escapeName(player_name)
	return name_clean
end

---Fetches clan tag from the specified username. Returns nil on empty tag. \
---*Not preferred as of Toribash 5.60, use PlayerInfo.Get() instead*
---@deprecated
---@param player string Player name
---@return string|nil
function PlayerInfo:getClanTag(player)
	local name, tag = player, nil
	local braces = { "[]", "()", "{}" }

	for _, v in pairs(braces) do
		tag = name:match("%b" .. v)
		if (tag) then
			tag = tag:gsub("%W", "")
			break
		end
	end

	return tag
end

---Retrieves base information about the specified user and returns a populated PlayerInfo object
---@param username ?string
---@param scope ?PlayerInfoScope
---@return PlayerInfo
---@overload fun(scope:PlayerInfoScope):PlayerInfo
function PlayerInfo.Get(username, scope)
	if (type(username) == "number" and scope == nil) then
		scope = username
		username = nil
	end

	---@diagnostic disable-next-line: param-type-mismatch
	local name_clean, clan_tag = PlayerInfoInternal.escapeName(username or PlayerInfoInternal.getMaster("nick"))
	local scope = scope or PLAYERINFO_SCOPE_NONE

	---@type PlayerInfo
	local playerInfo = {
		username = name_clean,
		clan = { tag = clan_tag },
		__isCurrentUser = username == nil
	}
	setmetatable(playerInfo, PlayerInfo)

	if (bit.band(scope, PLAYERINFO_SCOPE_GENERAL)) then
		playerInfo.data = playerInfo:getUserData()
	end

	return playerInfo
end

---@class LoginRewards
---@field days integer Current login day streak
---@field available boolean Whether the reward is currently available for claiming
---@field timeLeft integer Seconds left to claim the reward

---Returns current user's login rewards availability status
---@return LoginRewards
function PlayerInfo.getLoginRewards()
	local master = PlayerInfoInternal.getMaster()
	return {
		days = master.days,
		available = master.available == 1 and true or false,
		timeLeft = master.seconds,
	}
end

---@class PlayerCustomTexture
---@field id integer
---@field equipped boolean

---@class PlayerInfoCustomBase
---@field default boolean If true, it means that object population has failed and it contains default values.

---@class PlayerInfoCustomTextures : PlayerInfoCustomBase
---@field head PlayerCustomTexture
---@field breast PlayerCustomTexture
---@field chest PlayerCustomTexture
---@field groin PlayerCustomTexture
---@field r_pec PlayerCustomTexture
---@field r_bicep PlayerCustomTexture
---@field r_tricep PlayerCustomTexture
---@field l_pec PlayerCustomTexture
---@field l_bicep PlayerCustomTexture
---@field l_tricep PlayerCustomTexture
---@field r_hand PlayerCustomTexture
---@field l_hand PlayerCustomTexture
---@field r_butt PlayerCustomTexture
---@field l_butt PlayerCustomTexture
---@field r_thigh PlayerCustomTexture
---@field l_thigh PlayerCustomTexture
---@field r_leg PlayerCustomTexture
---@field l_leg PlayerCustomTexture
---@field r_foot PlayerCustomTexture
---@field l_foot PlayerCustomTexture


---Parses provided **item.dat** lines and returns information about player's equipped textures
---@param data ?string[]
---@return PlayerInfoCustomTextures
function PlayerInfoInternal.getTextures(data)
	---@type PlayerInfoCustomTextures
	local textures = {
		head = { id = 1, equipped = false },
		breast = { id = 2, equipped = false },
		chest = { id = 3, equipped = false },
		stomach = { id = 4, equipped = false },
		groin = { id = 5, equipped = false },
		r_pec = { id = 6, equipped = false },
		r_bicep = { id = 7, equipped = false },
		r_tricep = { id = 8, equipped = false },
		l_pec = { id = 9, equipped = false },
		l_bicep = { id = 10, equipped = false },
		l_tricep = { id = 11, equipped = false },
		r_hand = { id = 12, equipped = false },
		l_hand = { id = 13, equipped = false },
		r_butt = { id = 14, equipped = false },
		l_butt = { id = 15, equipped = false },
		r_thigh = { id = 16, equipped = false },
		l_thigh = { id = 17, equipped = false },
		l_leg = { id = 18, equipped = false },
		r_leg = { id = 19, equipped = false },
		r_foot = { id = 20, equipped = false },
		l_foot = { id = 21, equipped = false }
	}
	if (not data) then
		textures.default = true
		return textures
	end
	for _, ln in pairs(data) do
		if string.match(ln, "^TEXBODY 0; ") then
			ln = ln:gsub("TEXBODY 0; ", "")
			local data_stream = { ln:match(("([^%s]*)%s*"):rep(21)) }
			for _, v in pairs(textures) do
				v.equipped = tonumber(data_stream[v.id]) == 0 and true or false
			end
		end
	end
	return textures
end

---@class PlayerInfoCustomColors : PlayerInfoCustomBase
---@field force ColorId
---@field relax ColorId
---@field pgrad ColorId
---@field sgrad ColorId
---@field torso ColorId

---Parses provided **item.dat** lines and returns information about player's equipped colors
---@param data ?string[]
---@return PlayerInfoCustomColors
function PlayerInfoInternal.getColors(data)
	---@type PlayerInfoCustomColors
	local colors = {
		force = 23,
		relax = 21,
		pgrad = 0,
		sgrad = 0,
		torso = 0
	}
	if (not data) then
		colors.default = true
		return colors
	end
	for _, ln in pairs(data) do
		if string.match(ln, "^FORCOL 0;0 ") then
			ln = ln:gsub("^FORCOL 0;0 ", "")
			local color = tonumber(ln:match("%d+")) or 0
			colors.force = color == 0 and colors.force or color
		elseif string.match(ln, "^RELCOL 0;0 ") then
			ln = ln:gsub("^RELCOL 0;0 ", "")
			local color = tonumber(ln:match("%d+")) or 0
			colors.relax = color == 0 and colors.relax or color
		elseif string.match(ln, "^GRADCOL1 0;0 ") then
			ln = ln:gsub("^GRADCOL1 0;0 ", "")
			colors.pgrad = tonumber(ln:match("%d+")) or 0
		elseif string.match(ln, "^GRADCOL2 0;0 ") then
			ln = ln:gsub("^GRADCOL2 0;0 ", "")
			colors.sgrad = tonumber(ln:match("%d+")) or 0
		elseif string.match(ln, "^BODCOL 0;0 ") then
			ln = ln:gsub("^BODCOL 0;0 0 1 ", "")
			colors.torso = tonumber(ln:match("%d+")) or 0
		end
	end
	return colors
end

---@class PlayerCustomObject
---@field equipped boolean
---@field colorid ColorId
---@field alpha integer
---@field textured boolean
---@field dynamic boolean
---@field partless boolean
---@field ghosted boolean

---@class PlayerInfoCustomObjects : PlayerInfoCustomBase
---@field head PlayerCustomObject
---@field breast PlayerCustomObject
---@field chest PlayerCustomObject
---@field groin PlayerCustomObject
---@field r_pec PlayerCustomObject
---@field r_bicep PlayerCustomObject
---@field r_tricep PlayerCustomObject
---@field l_pec PlayerCustomObject
---@field l_bicep PlayerCustomObject
---@field l_tricep PlayerCustomObject
---@field r_hand PlayerCustomObject
---@field l_hand PlayerCustomObject
---@field r_butt PlayerCustomObject
---@field l_butt PlayerCustomObject
---@field r_thigh PlayerCustomObject
---@field l_thigh PlayerCustomObject
---@field r_leg PlayerCustomObject
---@field l_leg PlayerCustomObject
---@field r_foot PlayerCustomObject
---@field l_foot PlayerCustomObject

---Parses provided **item.dat** lines and returns information about player's equipped 3D items
---@param data ?string[]
---@return PlayerInfoCustomObjects
function PlayerInfoInternal.getObjs(data)
	---@type PlayerInfoCustomObjects
	local objs = {
		head = { equipped = false },
	}
	if (not data) then
		objs.default = true
		return objs
	end

	local options = {
		"colorid", "alpha", "textured", "dynamic", "partless", "ghosted"
	}
	local optNumeric = {
		colorid = true, alpha = true
	}

	---@param line string
	---@return PlayerCustomObject
	local function getValues(line)
		local dataStream = { line:match(("(%d+) ?"):rep(6)) }
		---@type PlayerCustomObject
		local objValues = {}
		for i,v in pairs(options) do
			objValues[v] = tonumber(dataStream[i])
			if (not optNumeric[v]) then
				objValues[v] = objValues[v] == 1 and true or false
			end
		end
		objValues.equipped = true
		return objValues
	end

	for _, ln in pairs(data) do
		if (string.match(ln, "^OBJ0 0; 1")) then
			ln = ln:gsub("^OBJ0 0; 1 ", "")
			objs.head = getValues(ln)
		end
	end
	return objs
end

---@class PlayerInfoCustomEffects : PlayerInfoCustomBase
---@field force RenderEffect
---@field relax RenderEffect
---@field body RenderEffect
---@field head RenderEffect

---Parses provided **item.dat** lines and returns information about player's equipped effects
---@param data ?string[]
---@return PlayerInfoCustomEffects
function PlayerInfoInternal.getEffects(data)
	---@type PlayerInfoCustomEffects
	local effects = {
		force = { __id = 0, effectId = EFFECTS_NONE },
		relax = { __id = 1, effectId = EFFECTS_NONE },
		body = { __id = 2, effectId = EFFECTS_NONE },
		head = { __id = 3, effectId = EFFECTS_NONE }
	}
	if (not data) then
		effects.default = true
		return effects
	end

	for _, ln in pairs(data) do
		-- Only check activated
		if (string.match(ln, "^EFFECT%d 0; 1")) then
			ln = ln:gsub("^EFFECT(%d+) 0; 1(.*)$", "%1%2 ")
			local _, values = ln:gsub(" ", "")
			local data = { ln:match(("([^ ]*) "):rep(values)) }

			for _, v in pairs(effects) do
				if (v.__id == tonumber(data[1])) then
					v.id = tonumber(data[2]) or EFFECTS_NONE
					v.glowColor = tonumber(data[3]) or 0
					v.glowIntensity = tonumber(data[4]) or 0
					v.ditherPixelSize = tonumber(data[5]) or 0
				end
			end
		end
	end
	return effects
end

---@class PlayerInfoCustoms
---@field colors PlayerInfoCustomColors
---@field textures PlayerInfoCustomTextures
---@field objs PlayerInfoCustomObjects
---@field effects PlayerInfoCustomEffects

---Returns customs information for the specified player
---@param player string
---@param scope PlayerInfoCustomsScope
---@return PlayerInfoCustoms
---@overload fun(self:PlayerInfo, scope:PlayerInfoCustomsScope):PlayerInfoCustoms
function PlayerInfo:getItems(player, scope)
	---@type PlayerInfoCustoms
	local items = {
		colors = {},
		textures = {},
		objs = {},
		effects = {}
	}
	if (self.username ~= nil) then
		self.items = items
	end

	---Ensure the old syntax still works
	if (self.username ~= nil and scope == nil) then
		---@type PlayerInfoCustomsScope
		---@diagnostic disable-next-line: assign-type-mismatch
		scope = player
		player = self.username
		self.customs = items
	else
		player = player and player or "tori"
	end

	local customs = Files:open("../custom/" .. player .. "/item.dat", FILES_MODE_READONLY)
	local customsData = customs:readAll()
	customs:close()

	scope = scope or PLAYERINFO_CSCOPE_COLORS
	items.colors = PlayerInfoInternal.getColors(bit.band(PLAYERINFO_CSCOPE_COLORS, scope) > 0 and customsData or nil)
	items.textures = PlayerInfoInternal.getTextures(bit.band(PLAYERINFO_CSCOPE_TEXTURES, scope) > 0 and customsData or nil)
	items.objs = PlayerInfoInternal.getObjs(bit.band(PLAYERINFO_CSCOPE_OBJECTS, scope) > 0 and customsData or nil)
	items.effects = PlayerInfoInternal.getEffects(bit.band(PLAYERINFO_CSCOPE_EFFECTS, scope) > 0 and customsData or nil)

	return items
end

---@class PlayerInfoRanking
---@field rank integer
---@field elo number
---@field wins integer
---@field loses integer
---@field games integer
---@field tier RankingTier
---@field nextTierElo number
---@field qualifying boolean

---Helper function to populate `PlayerInfoRanking` object with additional fields
---@param ranking PlayerInfoRanking
function PlayerInfo.getRankTier(ranking)
	if (ranking.wins + ranking.loses >= Ranking.QualificationMatches) then
		for _, v in pairs(Ranking.RankingTiers) do
			if (ranking.elo >= v.minElo and ranking.elo < v.maxElo) then
				ranking.nextTierElo = v.maxElo < 10000 and v.maxElo or 0
				ranking.tier = v
				break
			end
		end
	else
		ranking.tier = Ranking.QualifyingTier
		ranking.qualifying = true
		ranking.nextTierElo = 0
	end
end

---Returns curernt player's ranking information
---@return PlayerInfoRanking
function PlayerInfo:getRanking()
	---@type PlayerInfoRanking
	local ranking = { }
	if (self.username ~= nil) then
		self.ranking = ranking
	end

	local master = PlayerInfoInternal.getMaster()
	if (master.elo) then
		ranking.elo = master.elo
		ranking.wins = master.season_win
		ranking.loses = master.season_lose
		ranking.rank = master.rank
		PlayerInfo.getRankTier(ranking)
	end

	return ranking
end

---@class PlayerInfoClan
---@field id integer Public clan id in Toribash clans system
---@field name string
---@field tag string
---@field isleader boolean Whether user has clan leader permissions

---Returns player's clan information
---@param player string
---@param tag string
---@overload fun(self:PlayerInfo):PlayerInfoClan
---@return PlayerInfoClan
function PlayerInfo:getClan(player, tag)
	local player = player or self.username
	local clanInfo = {
		id = 0,
		name = "",
		tag = self.clan and self.clan.tag or tag,
		isleader = false
	}
	if (self.username ~= nil) then
		self.clan = clanInfo
	end
	if (player == nil) then
		return clanInfo
	end

	---Let's try and see if we can get clanid from item.dat to get the info faster
	local customs = Files:open("../custom/" .. player:lower() .. "/item.dat", FILES_MODE_READONLY)
	if (customs.data) then
		local gotData = false
		for _, ln in pairs(customs:readAll()) do
			if string.match(ln, "^CLAN 0;") then
				ln = string.gsub(ln, "CLAN 0;", "")
				local clanid = ln:match("%d+");
				clanInfo.id = tonumber(clanid) or 0
				if (clanInfo.id ~= 0) then
					clanInfo.tag = ln:match("%S+$")
				end

				gotData = true
				break
			end
		end
		customs:close()
		if (gotData and clanInfo.id == 0) then
			---We got the data and they are not part of the clan, no need to do anything else
			return clanInfo
		end
	end

	if (Clans:getClanData() == nil) then
		---Couldn't get cached clan data, exit with what we have
		return clanInfo
	end

	if (clanInfo.id ~= 0) then
		---We know their clan id, look it up directly without looping through all clans trying to find them
		if (Clans.Data[clanInfo.id] ~= nil) then
			clanInfo.name = Clans.Data[clanInfo.id].name
			clanInfo.isleader = in_array(player, Clans.Data[clanInfo.id].leaders)
		end
	else
		for _, clan in pairs(Clans.Data) do
			if (in_array(player, clan.members)) then
				clanInfo.name = clan.name
				clanInfo.isleader = in_array(player, clan.leaders)
			end
		end
	end
	return clanInfo
end

---@class PlayerInfoBelt
---@field name string
---@field icon string
---@field minQi integer
---@field maxQi integer
---@field nextBelt PlayerInfoBelt

---List of all defined Toribash belts. \
---@see PlayerInfo.getBeltFromQi
---@type PlayerInfoBelt[]
PlayerInfoInternal.Belts = {
	{
		name = "",
		icon = "",
		minQi = -1,
		maxQi = -1,
	},
	{
		name = "White",
		icon = "../textures/menu/belts/white.tga",
		minQi = 0,
		maxQi = 19
	},
	{
		name = "Yellow",
		icon = "../textures/menu/belts/yellow.tga",
		minQi = 20,
		maxQi = 49
	},
	{
		name = "Orange",
		icon = "../textures/menu/belts/orange.tga",
		minQi = 50,
		maxQi = 99
	},
	{
		name = "Green",
		icon = "../textures/menu/belts/green.tga",
		minQi = 100,
		maxQi = 199
	},
	{
		name = "Blue",
		icon = "../textures/menu/belts/blue.tga",
		minQi = 200,
		maxQi = 499
	},
	{
		name = "Brown",
		icon = "../textures/menu/belts/brown.tga",
		minQi = 500,
		maxQi = 999
	},
	{
		name = "Black",
		icon = "../textures/menu/belts/black.tga",
		minQi = 1000,
		maxQi = 1999
	},
	{
		name = "Black",
		icon = "../textures/menu/belts/black.tga",
		minQi = 1000,
		maxQi = 1999
	},
	{
		name = "2nd Dan Black",
		icon = "../textures/menu/belts/black2dan.tga",
		minQi = 2000,
		maxQi = 2999
	},
	{
		name = "3rd Dan Black",
		icon = "../textures/menu/belts/black3dan.tga",
		minQi = 3000,
		maxQi = 3999
	},
	{
		name = "4th Dan Black",
		icon = "../textures/menu/belts/black4dan.tga",
		minQi = 4000,
		maxQi = 4999
	},
	{
		name = "5th Dan Black",
		icon = "../textures/menu/belts/black5dan.tga",
		minQi = 5000,
		maxQi = 5999
	},
	{
		name = "6th Dan Black",
		icon = "../textures/menu/belts/black6dan.tga",
		minQi = 6000,
		maxQi = 6999
	},
	{
		name = "7th Dan Black",
		icon = "../textures/menu/belts/black7dan.tga",
		minQi = 7000,
		maxQi = 7999
	},
	{
		name = "8th Dan Black",
		icon = "../textures/menu/belts/black8dan.tga",
		minQi = 8000,
		maxQi = 8999
	},
	{
		name = "9th Dan Black",
		icon = "../textures/menu/belts/black9dan.tga",
		minQi = 9000,
		maxQi = 9999
	},
	{
		name = "10th Dan Black",
		icon = "../textures/menu/belts/black10dan.tga",
		minQi = 10000,
		maxQi = 14999
	},
	{
		name = "Master",
		icon = "../textures/menu/belts/master.tga",
		minQi = 15000,
		maxQi = 19999
	},
	{
		name = "Custom",
		icon = "../textures/menu/belts/custom.tga",
		minQi = 20000,
		maxQi = 49999
	},
	{
		name = "God",
		icon = "../textures/menu/belts/god.tga",
		minQi = 50000,
		maxQi = 99999
	},
	{
		name = "One",
		icon = "../textures/menu/belts/one.tga",
		minQi = 100000,
		maxQi = 999999
	},
	{
		name = "Elite",
		icon = "../textures/menu/belts/elite.tga",
		minQi = 1000000
	},
}

---Returns belt information for the specified Qi amount
---@param qi integer
---@return PlayerInfoBelt
function PlayerInfo.getBeltFromQi(qi)
	---Make sure we return a copy of the object so that the initial array stays unmodified
	for i, belt in pairs(PlayerInfoInternal.Belts) do
		if (belt.minQi <= qi and (belt.maxQi == nil or belt.maxQi >= qi)) then
			local targetBelt = table.clone(belt)
			if (PlayerInfoInternal.Belts[i + 1] ~= nil) then
				targetBelt.nextBelt = table.clone(PlayerInfoInternal.Belts[i + 1])
			end
			return targetBelt
		end
	end
	return table.clone(PlayerInfoInternal.Belts[1])
end

---@class PlayerInfoData
---@field tc integer Toricredits balance
---@field st integer Shiai Tokens balance
---@field qi integer Total player Qi
---@field belt PlayerInfoBelt Player's belt information

---Returns general player information (balance, qi, belt) about the user.
---@param player ?string
---@return PlayerInfoData
---@overload fun(self:PlayerInfo):PlayerInfoData
function PlayerInfo:getUserData(player)
	---@type PlayerInfoData
	local userData = { tc = 0, qi = 0, st = 0 }
	if (self.username ~= nil) then
		self.data = userData
	end

	if (player == nil or self.__isCurrentUser) then
		local master = PlayerInfoInternal.getMaster()
		userData.tc = master.tc
		userData.st = master.st
		userData.qi = master.qi
		userData.belt = PlayerInfo.getBeltFromQi(userData.qi)
		return userData
	end

	local customs = Files:open("../custom/" .. player .. "/item.dat", FILES_MODE_READONLY)
	if (not customs.data) then
		return userData
	end
	local customsData = customs:readAll()
	customs:close()

	for _, ln in pairs(customsData) do
		if (string.match(ln, "^BELT 0;")) then
			local qi = string.gsub(ln, "BELT 0;", "")
			userData.qi = tonumber(qi) or 0
			userData.belt = PlayerInfo.getBeltFromQi(userData.qi)
		end
		if (string.match(ln, "^TC 0;")) then
			local tc = string.gsub(ln, "^TC 0;(%d+)([ %d]*)$", "%1")
			local st = string.gsub(ln, "^TC 0;([ %d]*)( %d+)$", "%2")
			userData.tc = tonumber(tc) or 0
			userData.st = tonumber(st) or 0
		end
	end

	return userData
end

---Parses network response containing player information. \
---@see PlayerInfo.getServerUserinfo
---@param userinfo RequestPromise
function PlayerInfoInternal.parseServerUserinfo(userinfo)
	local response = get_network_response()
	for ln in (response:gmatch("[^\n]*\n?")) do
		local ln = ln:gsub("\n$", '')
		if (ln:find("^USERNAME 0;")) then
			table.insert(userinfo, {
				name = TB_MENU_LOCALIZED.ACCOUNTUSERNAME or "Username",
				value = ln:gsub("^USERNAME 0;", "")
			})
		elseif (ln:find("^USERID 0;")) then
			table.insert(userinfo, {
				name = TB_MENU_LOCALIZED.ACCOUNTUSERID or "User ID",
				value = ln:gsub("^USERID 0;", "")
			})
		elseif (ln:find("^QI 0;")) then
			local qiStr = ln:gsub("^QI 0;", "")
			local qi = tonumber(qiStr) or 0
			local belt = PlayerInfo.getBeltFromQi(qi)
			table.insert(userinfo, {
				name = TB_MENU_LOCALIZED.WORDQI or "Qi",
				value = qi .. " (" .. belt.name .. " Belt)"
			})
		elseif (ln:find("^TODAYGAMES 0;")) then
			table.insert(userinfo, {
				name = TB_MENU_LOCALIZED.ACCOUNTGAMESPLAYEDTODAY or "Games Played Today",
				value = ln:gsub("^TODAYGAMES 0;", "")
			})
		elseif (ln:find("^TODAYWINS 0;")) then
			table.insert(userinfo, {
				name = TB_MENU_LOCALIZED.ACCOUNTGAMESWONTODAY or "Games Won Today",
				value = ln:gsub("^TODAYWINS 0;", "")
			})
		elseif (ln:find("^TODAYEARNINGS 0;")) then
			table.insert(userinfo, {
				name = TB_MENU_LOCALIZED.ACCOUNTTCEARNINGSTODAY or "Today's Fights Earnings",
				value = ln:gsub("^TODAYEARNINGS 0;", "") .. " ToriCredits"
			})
		elseif (ln:find("^QIRESET 0;")) then
			table.insert(userinfo, {
				name = TB_MENU_LOCALIZED.ACCOUNTQIRESETS or "Daily Qi Limit resets in",
				value = TBMenu:getTime(ln:gsub("^QIRESET 0;", "") + 0, 2)
			})
		elseif (ln:find("^BANNED 0;")) then
			table.insert(userinfo, {
				name = TB_MENU_LOCALIZED.ACCOUNTSTATUS or "Account Status",
				value = (TB_MENU_LOCALIZED.ACCOUNTSUSPENDED or "Suspended") .. " (" .. ln:gsub("^BANNED 0; ?", "") .. ")",
				customColor = UICOLORRED,
				hint = TB_MENU_LOCALIZED.ACCOUNTSUSPENDEDINFO or "Your account has been suspended by Toribash moderators. You can appeal your ban on forums.",
				action = function() open_url("https://forum.toribash.com/forumdisplay.php?f=594") end
			})
		elseif (ln:find("^GREYLIST 0;")) then
			table.insert(userinfo, {
				name = TB_MENU_LOCALIZED.ACCOUNTSTATUS or "Account Status",
				value = (TB_MENU_LOCALIZED.ACCOUNTGREYLISTED or "Trading Greylisted") .. " (" .. TBMenu:getTime(ln:gsub("^GREYLIST 0;", "") + 0, 2) .. ")",
				customColor = TB_MENU_DEFAULT_ORANGE,
				customHoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
				customUiColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				hint = TB_MENU_LOCALIZED.ACCOUNTGREYLISTEDINFO or "Your account has limited trading capabilities. You can wait your greylist period out or contact an administrator to lift it earlier.",
				action = function() open_url("https://www.toribash.com/discord.php") end
			})
		elseif (ln:find("^EMAILERR 0;")) then
			table.insert(userinfo, {
				name = TB_MENU_LOCALIZED.ACCOUNTSTATUS or "Account Status",
				value = TB_MENU_LOCALIZED.ACCOUNTNOEMAIL or "No email connected",
				customColor = TB_MENU_DEFAULT_ORANGE,
				customHoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
				customUiColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				hint = TB_MENU_LOCALIZED.ACCOUNTEMAILERRORINFO or "Your account's capabilities will be limited until you connect an email to your account and confirm it.",
				action = function() open_url("https://forum.toribash.com/profile.php?do=editpassword") end
			})
		elseif (ln:find("^EMAILERR 1;")) then
			table.insert(userinfo, {
				name = TB_MENU_LOCALIZED.ACCOUNTSTATUS or "Account Status",
				value = TB_MENU_LOCALIZED.ACCOUNTAWAITINGCONFIRMATION or "Awaiting Email Confirmation",
				customColor = TB_MENU_DEFAULT_ORANGE,
				customHoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
				customUiColor = TB_MENU_DEFAULT_DARKEST_COLOR,
				hint = TB_MENU_LOCALIZED.ACCOUNTEMAILERRORINFO or "Your account's capabilities will be limited until you connect an email to your account and confirm it.",
				action = function() open_url("https://forum.toribash.com/profile.php?do=editpassword") end
			})
		elseif (ln:find("^SUBSCRIPTION %d+;")) then
			local subInfo = ln:gsub("^SUBSCRIPTION %d+; ?", "")
			local subName = subInfo:gsub("^%d+", ""):gsub("^ ", "")
			local subTime = subInfo:sub(0, -subName:len() - 1)
			table.insert(userinfo, {
				name = subName,
				value = TBMenu:getTime(tonumber(subTime) or 0, 2)
			})
		end
	end
end

---Queues a network request to fetch user's information from Toribash servers. \
---*Dataset will differ when requesting information about current user and other users.*
---@param username ?string Leave empty to request information about currently logged in user
---@return RequestPromise
function PlayerInfo.getServerUserinfo(username)
	if (username == nil) then
		return Request:queue(get_player_userinfo, "playerInfoServerUserinfo", PlayerInfoInternal.parseServerUserinfo)
	end
	return Request:queue(function() get_player_userinfo(username) end, "playerInfoServerUserinfo_" .. username, PlayerInfoInternal.parseServerUserinfo)
end

---Will be removed with future releases, use `numberFormat()` instead
---@deprecated
---@param n string|number
---@param decimals ?integer
---@return string
function PlayerInfo:currencyFormat(n, decimals)
	return numberFormat(n, decimals)
end