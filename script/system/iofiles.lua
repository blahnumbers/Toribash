-- Files I/O manager

FILES_MODE_READONLY = 'r'
FILES_MODE_WRITE = 'w+'
FILES_MODE_APPEND = 'a'
FILES_MODE_READWRITE = 'r+'

do
	Files = {}
	Files.__index = Files
	
	function Files:new(path, mode)
		if (not path) then
			return false
		end
		local mode = mode or FILES_MODE_READONLY
		
		local File = { mode = mode }
		setmetatable(File, self)
		
		local isroot = path:match("%.%.%/") and 1 or nil
		File.isroot = isroot
		
		local path = path:gsub("%.%.%/", "")
		File.path = path
		
		if (not File:isDownloading()) then
			File.data = io.open(path, mode, isroot)
			return File
		end
		
		return File
	end
	
	function Files:isDownloading()
		for i,v in pairs(get_downloads()) do
			if (v:match(self.path)) then
				return true
			end
		end
		return false
	end
	
	function Files:close()
		if (self.data) then
			self.data:close()
		end
	end
end