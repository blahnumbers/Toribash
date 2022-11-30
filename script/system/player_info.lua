-- Player info fetcher
require("system.iofiles")
require("system.network_request")
require("system.ranking_manager")

if (PlayerInfo == nil) then
	PlayerInfo = {
		__index = {}
	}
	setmetatable({}, PlayerInfo)
end

local getMaster = function(option)
	add_hook("console", "playerInfoFetchConsoleIgnore", function(s,i)
		return 1
	end)
	local returnVal = nil
	if (option) then
		returnVal = get_master().master[option]
	else
		returnVal = get_master().master
	end
	remove_hooks("playerInfoFetchConsoleIgnore")
	return returnVal
end

---Fetches current user's cleaned name or purifies a specified username
---@param player? string Custom username that we want to clean from clan tag or any prefixes
---@return string
function PlayerInfo:getUser(player)
	local player_name = player or getMaster("nick")
	player_name = player_name:gsub(".*%b{}", "")
	player_name = player_name:gsub(".*%b[]", "")
	player_name = player_name:gsub(".*%b()", "")

	return player_name
end

---Fetches clan tag from the specified username. Returns nil on empty tag.
---@param player string Player name
---@return string|nil
function PlayerInfo:getClanTag(player)
	local name, tag = player, nil
	local braces = { "[]", "()", "{}" }

	for i,v in pairs(braces) do
		tag = name:match("%b" .. v)
		if (tag) then
			tag = tag:gsub("%W", "")
			break
		end
	end

	return tag
end

function PlayerInfo:getLoginRewardStatus()
	return getMaster("reward_result")
end

---@class LoginRewards
---@field days integer Current login day streak
---@field available boolean Whether the reward is currently available for claiming
---@field timeLeft integer Seconds left to claim the reward

---Retrieves current login rewards availability status
---@return LoginRewards
function PlayerInfo:getLoginRewards()
	local master = getMaster()
	return {
		days = master.days,
		available = master.available == 1 and true or false,
		timeLeft = master.seconds,
	}
end

function PlayerInfo:getLoginRewardError()
	return getMaster("reward_error")
end

function PlayerInfo:getTextures(data)
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
	for i, ln in pairs(data) do
		if string.match(ln, "^TEXBODY 0; ") then
			ln = ln:gsub("TEXBODY 0; ", "")
			local data_stream = { ln:match(("([^%s]*)%s*"):rep(21)) }
			for j, v in pairs(textures) do
				v.equipped = tonumber(data_stream[v.id]) == 0 and true or false
			end
		end
	end
	return textures
end

function PlayerInfo:getColors(data)
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
	for i, ln in pairs(data) do
		if string.match(ln, "^FORCOL 0;0 ") then
			ln = ln:gsub("^FORCOL 0;0 ", "")
			local color = tonumber(ln:match("%d+"))
			colors.force = color == 0 and colors.force or color
		elseif string.match(ln, "^RELCOL 0;0 ") then
			ln = ln:gsub("^RELCOL 0;0 ", "")
			local color = tonumber(ln:match("%d+"))
			colors.relax = color == 0 and colors.relax or color
		elseif string.match(ln, "^GRADCOL1 0;0 ") then
			ln = ln:gsub("^GRADCOL1 0;0 ", "")
			colors.pgrad = tonumber(ln:match("%d+"))
		elseif string.match(ln, "^GRADCOL2 0;0 ") then
			ln = ln:gsub("^GRADCOL2 0;0 ", "")
			colors.sgrad = tonumber(ln:match("%d+"))
		elseif string.match(ln, "^BODCOL 0;0 ") then
			ln = ln:gsub("^BODCOL 0;0 0 1 ", "")
			colors.torso = tonumber(ln:match("%d+"))
		end
	end
	return colors
end

function PlayerInfo:getObjs(data)
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
	local function getValues(data)
		local dataStream = { data:match(("(%d+) ?"):rep(6)) }
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
	for i, ln in pairs(data) do
		if (string.match(ln, "^OBJ0 0; 1")) then
			ln = ln:gsub("^OBJ0 0; 1 ", "")
			objs.head = getValues(ln)
		end
	end
	return objs
end

function PlayerInfo:getEffects(data)
	local effects = {
		force = { _id = 0, id = EFFECTS_NONE },
		relax = { _id = 1, id = EFFECTS_NONE },
		body = { _id = 2, id = EFFECTS_NONE },
		head = { _id = 3, id = EFFECTS_NONE }
	}
	if (not data) then
		effects.default = true
		return effects
	end

	for i, ln in pairs(data) do
		-- Only check activated
		if (string.match(ln, "^EFFECT%d 0; 1")) then
			ln = ln:gsub("^EFFECT(%d+) 0; 1(.*)$", "%1%2 ")
			local _, values = ln:gsub(" ", "")
			local data = { ln:match(("([^ ]*) "):rep(values)) }

			for i,v in pairs(effects) do
				if (v._id == tonumber(data[1])) then
					v.id = data[2]
					v.glowColor = data[3]
					v.glowIntensity = data[4]
					v.ditherPixelSize = data[5]
				end
			end
		end
	end
	return effects
end

function PlayerInfo:getItems(player, colorsOnly)
	local player = player and player or "tori"
	local items = {
		colors = {},
		textures = {},
		objs = {}
	}
	local customs = Files:open("../custom/" .. player .. "/item.dat", FILES_MODE_READONLY)
	local customsData = customs:readAll()
	customs:close()

	items.colors = PlayerInfo:getColors(customsData)
	if (not colorsOnly) then
		items.textures = PlayerInfo:getTextures(customsData)
		items.objs = PlayerInfo:getObjs(customsData)
		items.effects = PlayerInfo:getEffects(customsData)
	end
	return items
end

---Updates a `RankingPlayer` object with additional fields
---@param ranking RankingPlayer
---@return nil
function PlayerInfo:getRankTier(ranking)
	if (ranking.wins + ranking.loses >= Ranking.QualificationMatches) then
		for i,v in pairs(Ranking.RankingTiers) do
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

---@return RankingPlayer
function PlayerInfo:getRanking()
	---@type RankingPlayer
	local ranking = {
		elo = nil,
		title = nil,
		rank = nil,
		image = nil,
		wins = nil,
		loses = nil
	}

	local master = getMaster()

	if (master.elo) then
		ranking.elo = master.elo
		ranking.wins = master.season_win
		ranking.loses = master.season_lose
		ranking.rank = master.rank
		PlayerInfo:getRankTier(ranking)
	end
	return ranking
end

function PlayerInfo:getClan(player, tag)
	local clanInfo = {
		id = 0,
		name = "",
		tag = "",
		isleader = false
	}
	if (not player) then
		return clanInfo
	end
	if (not tag) then
		local customs = Files:open("../custom/" .. player .. "/item.dat", FILES_MODE_READONLY)
		if (not customs.data) then
			customs = Files:open("../custom/" .. player:lower() .. "/item.dat", FILES_MODE_READONLY)
			if (not customs.data) then
				return clanInfo
			end
		end
		for i,ln in pairs(customs:readAll()) do
			if string.match(ln, "^CLAN 0;") then
				ln = string.gsub(ln, "CLAN 0;", "")
				local clanid = ln:match("%d+");
				clanInfo.id = tonumber(clanid)
				if (clanInfo.id ~= 0) then
					clanInfo.tag = ln:match("%S+$")
				end
				break
			end
		end
		customs:close()
		if (clanInfo.id == 0) then
			return clanInfo
		end
	else
		clanInfo.tag = tag
	end

	local clans = Files:open("clans/clans.txt", FILES_MODE_READONLY)
	if (not clans.data) then
		return clanInfo
	end
	for i,ln in pairs(clans:readAll()) do
		if string.match(ln, "^CLAN") then
			local segments, found = 14, false
			local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
			if (tonumber(data_stream[2]) == clanInfo.id and clanInfo.id > 0) then
				clanInfo.name = data_stream[3]
				found = true
			elseif (data_stream[4] == clanInfo.tag and clanInfo.tag ~= '') then
				clanInfo.id = tonumber(data_stream[2])
				clanInfo.tag = data_stream[5] == '1' and ("[" .. clanInfo.tag .. "]") or ("(" .. clanInfo.tag .. ")")
				clanInfo.name = data_stream[3]
				found = true
			end
			if (found) then
				if (data_stream[14]:match(PlayerInfo:getUser())) then
					clanInfo.isleader = true
				end
				break
			end
		end
	end
	clans:close()
	return clanInfo
end

function PlayerInfo:getBeltFromQi(qi)
	local belt = {
		name = nil,
		icon = nil
	}
	if (qi < 20) then
		belt.name = "White"
		belt.icon = "../textures/menu/belts/white.tga"
	elseif (qi < 50) then
		belt.name = "Yellow"
		belt.icon = "../textures/menu/belts/yellow.tga"
	elseif (qi < 100) then
		belt.name = "Orange"
		belt.icon = "../textures/menu/belts/orange.tga"
	elseif (qi < 200) then
		belt.name = "Green"
		belt.icon = "../textures/menu/belts/green.tga"
	elseif (qi < 500) then
		belt.name = "Blue"
		belt.icon = "../textures/menu/belts/blue.tga"
	elseif (qi < 1000) then
		belt.name = "Brown"
		belt.icon = "../textures/menu/belts/brown.tga"
	elseif (qi < 2000) then
		belt.name = "Black"
		belt.icon = "../textures/menu/belts/black.tga"
	elseif (qi < 3000) then
		belt.name = "2nd Dan Black"
		belt.icon = "../textures/menu/belts/black2dan.tga"
	elseif (qi < 4000) then
		belt.name = "3rd Dan Black"
		belt.icon = "../textures/menu/belts/black3dan.tga"
	elseif (qi < 5000) then
		belt.name = "4th Dan Black"
		belt.icon = "../textures/menu/belts/black4dan.tga"
	elseif (qi < 6000) then
		belt.name = "5th Dan Black"
		belt.icon = "../textures/menu/belts/black5dan.tga"
	elseif (qi < 7000) then
		belt.name = "6th Dan Black"
		belt.icon = "../textures/menu/belts/black6dan.tga"
	elseif (qi < 8000) then
		belt.name = "7th Dan Black"
		belt.icon = "../textures/menu/belts/black7dan.tga"
	elseif (qi < 9000) then
		belt.name = "8th Dan Black"
		belt.icon = "../textures/menu/belts/black8dan.tga"
	elseif (qi < 10000) then
		belt.name = "9th Dan Black"
		belt.icon = "../textures/menu/belts/black9dan.tga"
	elseif (qi < 15000) then
		belt.name = "10th Dan Black"
		belt.icon = "../textures/menu/belts/black10dan.tga"
	elseif (qi < 20000) then
		belt.name = "Master"
		belt.icon = "../textures/menu/belts/master.tga"
	elseif (qi < 50000) then
		belt.name = "Custom"
		belt.icon = "../textures/menu/belts/custom.tga"
	elseif (qi < 100000) then
		belt.name = "God"
		belt.icon = "../textures/menu/belts/god.tga"
	elseif (qi < 1000000) then
		belt.name = "One"
		belt.icon = "../textures/menu/belts/one.tga"
	else
		belt.name = "Elite"
		belt.icon = "../textures/menu/belts/elite.tga"
	end
	return belt
end

function PlayerInfo:getUserData(player)
	local userData = {
		tc = 0,
		qi = 0,
		st = 0,
		belt = nil
	}
	if (not player) then
		local master = getMaster()
		userData.tc = master.tc
		userData.st = master.st
		userData.qi = master.qi
		userData.belt = PlayerInfo:getBeltFromQi(userData.qi)
		return userData
	end
	local customs = Files:open("../custom/" .. player .. "/item.dat", FILES_MODE_READONLY)
	if (not customs.data) then
		return userData
	end
	for i,ln in pairs(customs:readAll()) do
		if string.match(ln, "^BELT 0;") then
			userData.qi = string.gsub(ln, "BELT 0;", "")
			userData.qi = tonumber(userData.qi)
			userData.belt = PlayerInfo:getBeltFromQi(userData.qi)
		end
		if string.match(ln, "^TC 0;") then
			userData.tc = string.gsub(ln, "TC 0;", "")
			userData.tc = string.gsub(userData.tc, ".%d+$", "")
			userData.tc = tonumber(userData.tc)
		end
	end

	customs:close()
	return userData
end

function PlayerInfo:getServerUserinfo(username, reload)
	local localized = TB_MENU_LOCALIZED or {}
	local function success(userinfo)
		local response = get_network_response()
		for ln in response:gmatch("[^\n]*\n?") do
			local ln = ln:gsub("\n$", '')
			if (ln:find("^USERNAME 0;")) then
				table.insert(userinfo, {
					name = localized.ACCOUNTUSERNAME or "Username",
					value = ln:gsub("^USERNAME 0;", "")
				})
			elseif (ln:find("^USERID 0;")) then
				table.insert(userinfo, {
					name = localized.ACCOUNTUSERID or "User ID",
					value = ln:gsub("^USERID 0;", "")
				})
			elseif (ln:find("^QI 0;")) then
				local qi = ln:gsub("^QI 0;", "")
				qi = qi:len() > 0 and qi + 0 or 0
				local belt = PlayerInfo:getBeltFromQi(qi)
				table.insert(userinfo, {
					name = "Qi",
					value = qi .. " (" .. belt.name .. " Belt)"
				})
			elseif (ln:find("^TODAYGAMES 0;")) then
				table.insert(userinfo, {
					name = localized.ACCOUNTGAMESPLAYEDTODAY or "Games Played Today",
					value = ln:gsub("^TODAYGAMES 0;", "")
				})
			elseif (ln:find("^TODAYWINS 0;")) then
				table.insert(userinfo, {
					name = localized.ACCOUNTGAMESWONTODAY or "Games Won Today",
					value = ln:gsub("^TODAYWINS 0;", "")
				})
			elseif (ln:find("^TODAYEARNINGS 0;")) then
				table.insert(userinfo, {
					name = localized.ACCOUNTTCEARNINGSTODAY or "Today's Fights Earnings",
					value = ln:gsub("^TODAYEARNINGS 0;", "") .. " ToriCredits"
				})
			elseif (ln:find("^QIRESET 0;")) then
				table.insert(userinfo, {
					name = localized.ACCOUNTQIRESETS or "Daily Qi Limit resets in",
					value = TBMenu:getTime(ln:gsub("^QIRESET 0;", "") + 0, 2)
				})
			elseif (ln:find("^BANNED 0;")) then
				table.insert(userinfo, {
					name = localized.ACCOUNTSTATUS or "Account Status",
					value = (localized.ACCOUNTSUSPENDED or "Suspended") .. " (" .. ln:gsub("^BANNED 0; ?", "") .. ")",
					customColor = UICOLORRED,
					hint = localized.ACCOUNTSUSPENDEDINFO or "Your account has been suspended by Toribash moderators. You can appeal your ban on forums.",
					action = function() open_url("https://forum.toribash.com/forumdisplay.php?f=594") end
				})
			elseif (ln:find("^GREYLIST 0;")) then
				table.insert(userinfo, {
					name = localized.ACCOUNTSTATUS or "Account Status",
					value = (localized.ACCOUNTGREYLISTED or "Trading Greylisted") .. " (" .. TBMenu:getTime(ln:gsub("^GREYLIST 0;", "") + 0, 2) .. ")",
					customColor = TB_MENU_DEFAULT_ORANGE,
					customHoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
					customUiColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					hint = localized.ACCOUNTGREYLISTEDINFO or "Your account has limited trading capabilities. You can wait your greylist period out or contact an administrator to lift it earlier.",
					action = function() open_url("https://www.toribash.com/discord.php") end
				})
			elseif (ln:find("^EMAILERR 0;")) then
				table.insert(userinfo, {
					name = localized.ACCOUNTSTATUS or "Account Status",
					value = localized.ACCOUNTNOEMAIL or "No email connected",
					customColor = TB_MENU_DEFAULT_ORANGE,
					customHoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
					customUiColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					hint = localized.ACCOUNTEMAILERRORINFO or "Your account's capabilities will be limited until you connect an email to your account and confirm it.",
					action = function() open_url("https://forum.toribash.com/profile.php?do=editpassword") end
				})
			elseif (ln:find("^EMAILERR 1;")) then
				table.insert(userinfo, {
					name = localized.ACCOUNTSTATUS or "Account Status",
					value = localized.ACCOUNTAWAITINGCONFIRMATION or "Awaiting Email Confirmation",
					customColor = TB_MENU_DEFAULT_ORANGE,
					customHoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
					customUiColor = TB_MENU_DEFAULT_DARKEST_COLOR,
					hint = localized.ACCOUNTEMAILERRORINFO or "Your account's capabilities will be limited until you connect an email to your account and confirm it.",
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
		userinfo.ready = true
		if (not username) then
			SERVER_USER_INFO = userinfo
			SERVER_USER_INFO.updated = os.clock_real()
		end
	end
	local reload = reload or false
	if (not username and not reload) then
		reload = SERVER_USER_INFO.updated < os.clock_real() - 300
	end
	if (username or reload) then
		return Request:queue(get_player_userinfo, "userinfo", success)
	end
	SERVER_USER_INFO.ready = true
	return SERVER_USER_INFO
end

function PlayerInfo:currencyFormat(n, decimals)
	if (not n) then return n end
	local left, num, right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	if (not num) then return n end
	local num = left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
	if (decimals and decimals > 0) then
		local numDecimals = num:match("%.%d+$")
		if (not numDecimals) then
			num = num .. "." .. string.rep("0", decimals)
		else
			numDecimals = numDecimals:len()
			if (numDecimals - 1 > decimals) then
				num = num:sub(0, decimals - numDecimals)
			elseif (numDecimals - 1 < decimals) then
				num = num .. string.rep("0", decimals - numDecimals + 1)
			end
		end
	end
	return num
end
