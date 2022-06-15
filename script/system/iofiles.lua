-- Files I/O manager
require("toriui/uielement")

FILES_MODE_READONLY = 'r'
FILES_MODE_WRITE = 'w+'
FILES_MODE_APPEND = 'a'
FILES_MODE_READWRITE = 'r+'

---@alias mode
---| 'r' # FILES_MODE_READONLY
---| 'w'
---| 'a' # FILES_MODE_APPEND
---| 'r+' # FILES_MODE_READWRITE
---| 'w+' # FILES_MODE_WRITE
---| 'a+'
---| 'rb'
---| 'wb'
---| 'ab'
---| 'r+b'
---| 'w+b'
---| 'a+b'

-- Internal cross-platform function to open a file
---@param path string File path
---@param mode mode File open mode
---@param isroot integer|nil If 1, will start looking for file in Toribash root folder instead of data/script
---@return file*|string[]|nil
local function filesOpenInternal(path, mode, isroot)
	if (PLATFORM == "ANDROID") then
		return read_file(path, mode, isroot)
	end
	return io.open(path, mode, isroot)
end

-- Internal cross-platform function to read all contents of a file
---@param file file*|string[] File data we received after filesOpenInternal() call
---@return string[]
local function filesReadAllInternal(file)
	if (PLATFORM == "ANDROID") then
		return file
	end
	return file:read("*all")
end

do
	-- **Ver 1.1**
	-- * Semantic updates to use Files class as a static alternative to spawn new File class objects
	-- * EmmyLua annotations
	---@class Files
	Files = { ver = 1.1 }
	Files.__index = Files

	---@class File
	---@field path string File path
	---@field isroot integer|nil If 1, file lookup started at Toribash root folder
	---@field mode mode Mode the file was opened with
	---@field data file*|string[] File pointer received from io.open() call or a string array on Android
	File = {}
	File.__index = File

	---@deprecated
	-- **DEPRECATED**: Use Files:open() instead
	function Files:new(path, mode)
		return Files:open(path, mode)
	end

	-- Opens a file at a specified path
	---@param path string Path to the file. In case we want to start file lookup at Toribash root folder, path should start with `../`.
	---@param mode? mode Mode to open the file with. Defaults to `FILES_MODE_READONLY`.
	---@return File
	function Files:open(path, mode)
		if (not path) then
			return false
		end
		local mode = mode or FILES_MODE_READONLY

		local file = {}
		setmetatable(file, File)

		file.mode = mode

		local isroot = path:match("^%.%.%/") and 1 or nil
		file.isroot = isroot

		local path = path:gsub("^%.%.%/", "")
		file.path = path

		if (not file:isDownloading()) then
			file.data = filesOpenInternal(path, mode, isroot)
			return file
		end

		return file
	end

	-- Reopens the File object we received earlier
	---@param mode? mode New mode to open file with
	---@return File
	function File:reopen(mode)
		self:close()
		local mode = mode or self.mode
		if (not self:isDownloading()) then
			self.data = filesOpenInternal(self.path, mode, self.isroot)
		end
	end

	-- Reads the whole file and returns all its contents line-by-line in a table
	---@return string[]
	function File:readAll()
		if (not self.data) then
			return { }
		end
		local filedata = filesReadAllInternal(self.data)

		-- Remove all CRs
		filedata = filedata:gsub("\r", "")

		local lines = {}
		-- Replace lines() with gmatch to ensure we only read LF newlines
		for ln in filedata:gmatch("[^\n]*\n") do
			local line = ln:gsub("\n$", '')
			table.insert(lines, line)
		end
		if (#lines == 0 and filedata:len() > 0) then
			return { filedata }
		end
		return lines
	end

	-- Writes a line to an opened file. Appends newline at the end if it's missing.
	--
	-- *Currently not supported on Android devices*
	---@param line string String to write to the file
	---@return boolean
	function File:writeLine(line)
		if (not self.data or PLATFORM == "ANDROID") then
			return false
		end

		local line = line:find("\n$") and line or (line .. "\n")
		self.data:write(line)
		return true
	end

	-- Writes a line to the debug.txt file located in Toribash root folder
	---@param line string
	---@param rewrite boolean If true, will open output file with FILES_MODE_WRITE mode to clear its previous contents
	---@return nil
	function Files:writeDebug(line, rewrite)
		local debug = Files:open("../debug.txt", rewrite and FILES_MODE_WRITE or FILES_MODE_APPEND)
		if (type(line) == "table") then
			debug:writeLine(os.clock() .. ': ' .. debugEcho(line, nil, true))
		else
			debug:writeLine(os.clock() .. ': ' .. line)
		end
		debug:close()
	end

	-- Checks whether the file is currently being downloaded or is in download queue
	---@return boolean
	function File:isDownloading()
		for i,v in pairs(get_downloads()) do
			if (v:match(string.escape(self.path:gsub("%.%a+$", "")) .. "%.%a+$")) then
				return true
			end
		end
		return false
	end

	-- Closes the file
	---@return nil
	function File:close()
		if (self.data) then
			if (PLATFORM ~= "ANDROID") then
				self.data:close()
			end
			self.data = nil
		end
	end
end
