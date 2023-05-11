require("toriui.uielement")
require("system.playerinfo_manager")

if (Downloader == nil) then
	---Downloader manager class
	---
	---**Ver 1.0**
	---* Initial release
	---@class Downloader
	---@field ver number Current class version
	---@field Queue function[]
	Downloader = {
		__index = {},
		ver = 1.0,
		Queue = {},
		initialized = false
	}
	setmetatable({}, Downloader)
end

---Queues a function to be executed on next `downloader_complete` callback
---@param func function
---@return integer|nil #New downloader queue size or `nil` on error
function Downloader:queue(func)
	if (type(func) ~= "function") then
		return nil
	end

	table.insert(Downloader.Queue, func)
	return #Downloader.Queue
end

---Initializes the downloader by queueing some major Toribash data files for update.\
---Will only be called once per session.
---@return nil
function Downloader:init()
	if (Downloader.initialized) then return end
	if (string.len(PlayerInfo.Get().username) > 0) then
		Downloader:queue(function() download_global_quests() end)
		Downloader:queue(function() download_inventory() end)
	end
	Downloader:queue(function() download_clan() end)

	Downloader.initialized = true
end

---Should be used for `downloader_complete` callbacks as they may crash the game on certain functions.\
---Queues a function to be executed on next `pre_draw` callback.
---@param func function
---@return string|nil #Spawned hook set name or `nil` on error
function Downloader:safeCall(func)
	if (type(func) ~= "function") then
		return nil
	end

	local id = generate_uid and generate_uid() or ("dldr" .. math.random(0, 1000000))
	add_hook("pre_draw", id, function() func() remove_hook("pre_draw", id) end)
	return id
end

add_hook("downloader_complete", "tbDownloaderManagerStatic", function()
	if (#Downloader.Queue > 0) then
		local func = Downloader.Queue[1]
		table.remove(Downloader.Queue, 1)
		func()
	end
end)

Downloader:init()
