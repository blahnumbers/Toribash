-- Player info fetcher

do
	PlayerInfo = {}
	PlayerInfo.__index = PlayerInfo
	local cln = {}
	setmetatable(cln, PlayerInfo)
	
	local RankingData = {
		{
			title = "Diamond Tier",
			showRank = true,
			maxElo = 10000,
			minElo = 1690,
			image = "../textures/menu/ranking/diamond.tga"
		},
		{
			title = "Platinum Tier",
			showRank = true,
			maxElo = 1690,
			minElo = 1645,
			image = "../textures/menu/ranking/platinum.tga"
		},
		{
			title = "Gold Tier",
			showRank = true,
			maxElo = 1645,
			minElo = 1618,
			image = "../textures/menu/ranking/gold.tga"
		},
		{
			title = "Silver Tier",
			showRank = false,
			maxElo = 1618,
			minElo = 1607,
			image = "../textures/menu/ranking/silver.tga"
		},
		{
			title = "Bronze Tier",
			showRank = false,
			maxElo = 1607,
			minElo = 1570,
			image = "../textures/menu/ranking/bronze.tga"
		},
		{
			title = "Elo Hell",
			showRank = false,
			maxElo = 1570,
			minElo = 0,
			image = "../textures/menu/ranking/elohell.tga"
		}
	}
	
	local rankingQualificationMatches = 10
	local rankingQualifying = {
		title = "Qualifying",
		image = "../textures/menu/ranking/qualifying.tga"
	}
	
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
	
	function PlayerInfo:getUser(player)
		local player_name = player or getMaster("nick")
		player_name = player_name:gsub(".*%b{}", "")
		player_name = player_name:gsub(".*%b[]", "")
		player_name = player_name:gsub(".*%b()", "")
		
		return player_name
	end
	
	function PlayerInfo:getLoginRewardStatus()
		return getMaster("reward_result")
	end
	
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
	
	function PlayerInfo:getTextures(file)
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
			l_shin = { id = 18, equipped = false },
			r_shin = { id = 19, equipped = false },
			r_foot = { id = 20, equipped = false },
			l_foot = { id = 21, equipped = false }
		}
		if (not file) then
			return textures
		end
		file:seek("set")
		for ln in file:lines() do
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
	
	function PlayerInfo:getColors(file)
		local colors = {
			force = 23,
			relax = 21
		}
		if (not file) then
			return colors
		end
		file:seek("set", 0)
		for ln in file:lines() do
			if string.match(ln, "^FORCOL 0;0 ") then
				ln = ln:gsub("^FORCOL 0;0 ", "")
				local color = tonumber(ln:match("%d+"))
				colors.force = color == 0 and colors.force or color
			end
			if string.match(ln, "^RELCOL 0;0 ") then
				ln = ln:gsub("^RELCOL 0;0 ", "")
				local color = tonumber(ln:match("%d+"))
				colors.relax = color == 0 and colors.relax or color
			end
		end
		return colors
	end
	
	function PlayerInfo:getItems(player)
		local player = player or "tori"
		local items = {
			colors = {},
			textures = {}
		}
		local file = io.open("custom/" .. player .. "/item.dat", 'r', 1)
		items.colors = PlayerInfo:getColors(file)
		items.textures = PlayerInfo:getTextures(file)
		if (file) then
			file:close()
		end
		return items
	end
	
	function PlayerInfo:getRanking()
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
			if (ranking.wins + ranking.loses >= rankingQualificationMatches) then
				for i,v in pairs(RankingData) do
					if (ranking.elo >= v.minElo and ranking.elo < v.maxElo) then
						ranking.title = v.title
						ranking.image = v.image
						if (v.showRank) then
							ranking.rank = master.rank
						end
						break
					end
				end
			else 
				ranking.title = rankingQualifying.title
				ranking.image = rankingQualifying.image
			end
		end
		return ranking		
	end
	
	function PlayerInfo:getClan(player)
		local clanInfo = {
			id = 0,
			name = "",
			tag = "",
			isleader = false
		}
		if (not player) then
			return clanInfo
		end
		local file = io.open("custom/" .. player .. "/item.dat", 'r', 1)
		if (not file) then
			return clanInfo
		end
		for ln in file:lines() do
			if string.match(ln, "^CLAN 0;") then
				ln = string.gsub(ln, "CLAN 0;", "")
				local clanid = ln:match("%d+");
				clanInfo.id = tonumber(clanid)
				if (clanInfo.id ~= 0) then
					clanInfo.tag = ln:match("%S+$")
				end
				file:close()
				break
			end
		end
		if (clanInfo.id == 0) then
			return clanInfo
		end
		local file = io.open("clans/clans.txt")
		if (not file) then
			return clanInfo
		end
		for ln in file:lines() do
			if string.match(ln, "^CLAN") then
				local segments = 14
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				if (tonumber(data_stream[2]) == clanInfo.id) then
					clanInfo.name = data_stream[3]
					if (data_stream[14]:match(PlayerInfo:getUser())) then
						clanInfo.isleader = true
					end
					break
				end
			end
		end
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
	
	function PlayerInfo:getUserData()
		userData = {
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
		local file = io.open("custom/" .. player .. "/item.dat", 'r', 1)
		if (not file) then
			return userData
		end
		for ln in file:lines() do
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
	    file:close()
		return userData
	end
	
	function PlayerInfo:tcFormat(n)
		local left, num, right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
		return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
	end
	
end