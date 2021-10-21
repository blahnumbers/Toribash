do
	Downloader = {}
	Downloader.__index = Downloader
	local cln = {}
	setmetatable(cln, Downloader)
	
	function Downloader:queue(func)
		if (type(func) ~= "function") then
			return
		end
		
		table.insert(TB_DOWNLOADER_QUEUE, func)
	end
	
	function Downloader:init()
		if (TB_DOWNLOADER_INITIALIZED) then return end
		Downloader:queue(function() download_quest(TB_MENU_PLAYER_INFO.username) end)
		Downloader:queue(function() download_global_quests() end)
		Downloader:queue(function() download_clan() end)
		Downloader:queue(function() download_inventory() end)
			
		TB_DOWNLOADER_INITIALIZED = true
	end
	
	-- Should be used for downloader_complete callbacks as they may crash the game on certain functions
	function Downloader:safeCall(func)
		local id = Guid and Guid() or ("dldr" .. math.random(0, 1000000))
		add_hook("pre_draw", id, function() func() remove_hooks(id) end)
	end
	
	add_hook("downloader_complete", "tbDownloaderManagerStatic", function()
		if (#TB_DOWNLOADER_QUEUE > 0) then
			local func = TB_DOWNLOADER_QUEUE[1]
			table.remove(TB_DOWNLOADER_QUEUE, 1)
			func()
		end
	end)
end
