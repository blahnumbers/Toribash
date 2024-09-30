require("toriui.uielement")
require("system.playerinfo_manager")

if (Downloader == nil) then
	---Downloader manager class
	---
	---**Version 5.72**
	---* SafeCall() update to act as a "static" method
	---
	---**Ver 1.0**
	---* Initial release
	---@class Downloader
	---@field ver number Current class version
	---@field Queue function[]
	Downloader = {
		ver = 5.72,
		Queue = { },
		initialized = false
	}
	Downloader.__index = Downloader
end

---Queues a function to be executed on next `downloader_complete` callback
---@param func function
---@return integer|nil #New downloader queue size or `nil` on error
function Downloader:queue(func)
	if (type(func) ~= "function") then
		return nil
	end

	table.insert(self.Queue, func)
	return #self.Queue
end

---Initializes the downloader by queueing some major Toribash data files for update.\
---Will only be called once per session.
---@return nil
function Downloader:init()
	if (self.initialized) then return end
	if (string.len(PlayerInfo.Get().username) > 0) then
		self:queue(download_global_quests)
		self:queue(download_inventory)
	end
	self:queue(download_clan)

	add_hook("downloader_complete", "__tbDownloaderManagerStatic", function()
		if (#self.Queue > 0) then
			local func = self.Queue[1]
			table.remove(self.Queue, 1)
			func()
		end
	end)

	self.initialized = true
end

---Should be used for `downloader_complete` callbacks as they may crash the game on certain functions.\
---Queues a function to be executed on next `pre_draw` callback.
---@param func function
---@return string|nil #Spawned hook set name or `nil` on error
function Downloader.SafeCall(func)
	if (type(func) ~= "function") then
		return nil
	end

	local id = generate_uid and generate_uid() or ("dldr" .. math.random(0, 1000000))
	add_hook("pre_draw", id, function() func() remove_hook("pre_draw", id) end)
	return id
end

Downloader:init()
