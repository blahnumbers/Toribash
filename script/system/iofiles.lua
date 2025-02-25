-- Files I/O manager
require("toriui.uielement")
require("toriui.json")

FILES_MODE_READONLY = 'r'
FILES_MODE_WRITE = 'w+'
FILES_MODE_APPEND = 'a'
FILES_MODE_READWRITE = 'r+'

-- Internal cross-platform function to open a file
---@param path string
---@param mode openmode
---@param isroot boolean If true, will start looking for file in Toribash root folder instead of data/script
---@return file*|integer|nil #Lua `file*` object on desktop platforms, file index on mobile or nil on failure
local function filesOpenInternal(path, mode, isroot)
	local file, err = io.open(path, mode, isroot)
	if (type(file) ~= "userdata" or err ~= nil) then
		return nil
	end
	---@diagnostic disable-next-line: return-type-mismatch
	return file
end

-- Internal cross-platform function to read all contents of a file
---@param file file*|integer File interface or file index on mobile platforms
---@return string
local function filesReadAllInternal(file)
	if (type(file) == "number") then
		return file_read(file)
	end
	---@diagnostic disable-next-line: param-type-mismatch
	return file:read("*all")
end

-- Internal cross-platform function to write data to a file
---@param file file*|integer File interface or file index on mobile platforms
---@param data string Data to write to the file
local function filesWriteInternal(file, data)
	if (type(file) == "number") then
		file_write(file, data)
		return
	end
	---@diagnostic disable-next-line: param-type-mismatch
	file:write(data)
end

-- Internal cross-platform function to close a file
---@param file file*|integer File interface or file index on mobile platforms
local function filesCloseInternal(file)
	if (type(file) == "number") then
		return file_close(file)
	end
	---@diagnostic disable-next-line: param-type-mismatch
	file:close()
end

---Sets an override for filesOpenInternal depending on current platform
local function setupFilesOpen()
	if (is_mobile() or (_G.PLATFORM == "APPLE" and not is_steam())) then
		filesOpenInternal = file_open
	end
end

do
	---**Toribash file IO manager**
	---
	---**Version 5.68**
	---* Use setupFilesOpen() to link filesOpenInternal() against custom functions on platforms that require it
	---* Adjustments for standalone macOS build
	---
	---**Version 5.65**
	---* Added `Exists()` method to quickly check whether file exists and is readable
	---
	---**Version 5.61**
	---* Added `LogError()` method to write errors to stderr.txt
	--
	-- **Ver 5.60**
	-- * Reworked file IO for mobile platforms with full read/write support
	--
	-- **Ver 1.1**
	-- * Semantic updates to use Files class as a static alternative to spawn new File class objects
	-- * EmmyLua annotations
	---@class Files
	Files = { ver = 5.68 }
	Files.__index = Files

	---@class File
	---@field path string File path
	---@field isroot boolean If `true`, file lookup started at Toribash root folder
	---@field mode openmode Mode the file was opened with
	---@field data file*|integer|nil File pointer received from `io.open()` call or a file index retrieved by `file_open()` on mobile
	File = {}
	File.__index = File

	---@deprecated
	---@see Files.Open
	function Files:new(path, mode)
		return Files.Open(path, mode)
	end

	---Opens a file at a specified path
	---@param path string Path to the file. In case we want to start file lookup at Toribash root folder, path should start with `../`.
	---@param mode? openmode Mode to open the file with. Defaults to `FILES_MODE_READONLY`.
	---@return File
	---@deprecated
	---@see Files.Open
	function Files:open(path, mode)
		return Files.Open(path, mode)
	end

	---Opens a file at a specified path
	---@param path string Path to the file. In case we want to start file lookup at Toribash root folder, path should start with `../`.
	---@param mode? openmode Mode to open the file with. Defaults to `FILES_MODE_READONLY`.
	---@return File
	function Files.Open(path, mode)
		local file = {
			mode = mode or FILES_MODE_READONLY,
			isroot = path:match("^%.%.%/") and true or false,
			path = path:gsub("^%.%.%/", "")
		}
		setmetatable(file, File)

		if (not file:isDownloading()) then
			file.data = filesOpenInternal(file.path, file.mode, file.isroot)
		end
		return file
	end

	---Returns whether the specified file exists and is readable
	---@param path string
	---@return boolean
	function Files.Exists(path)
		local file = Files.Open(path, "rb")
		if (file.data == nil) then
			return false
		end
		file:close()
		return true
	end

	-- Reopens the File object we received earlier
	---@param mode? openmode New mode to open file with
	function File:reopen(mode)
		self:close()
		mode = mode or self.mode
		if (not self:isDownloading()) then
			self.data = filesOpenInternal(self.path, mode, self.isroot)
		end
	end

	-- Reads the whole file and returns all its contents line-by-line in a table
	---@param raw boolean?
	---@return string[]
	---@overload fun(self: File, raw: true):string
	function File:readAll(raw)
		if (not self.data) then
			return raw == true and "" or { }
		end
		local filedata = filesReadAllInternal(self.data)
		if (raw == true) then
			return filedata
		end

		-- Remove all CRs
		filedata = filedata:gsub("\r", "")

		local lines = {}
		-- Replace lines() with gmatch to ensure we only read LF newlines
		for ln in filedata:gmatch("[^\n]*\n?") do
			local line = ln:gsub("\n$", '')
			table.insert(lines, line)
		end
		if (lines[#lines] == "") then
			table.remove(lines, #lines)
		end
		return lines
	end

	-- Writes a line to an opened file. Appends newline at the end if it's missing.
	---@param line string String to write to the file
	---@return boolean
	function File:writeLine(line)
		if (not self.data) then
			return false
		end

		line = string.find(line, "\n$") and line or (line .. "\n")
		filesWriteInternal(self.data, line)
		return true
	end

	-- Writes a line to the `debug.txt` file located in Toribash root folder
	---@param line any
	---@param rewrite? boolean If true, will open output file with FILES_MODE_WRITE mode to clear its previous contents
	function Files.WriteDebug(line, rewrite)
		local debug = Files.Open("../debug.txt", rewrite and FILES_MODE_WRITE or FILES_MODE_APPEND)
		if (type(line) == "table") then
			debug:writeLine(os.clock_real() .. ': ' .. JSON.encode(line))
		else
			debug:writeLine(os.clock_real() .. ': ' .. tostring(line))
		end
		debug:close()
	end

	---Prints an error string to standard Toribash error log
	---@param line any
	function Files.LogError(line)
		perror("[LogError " .. os.clock_real() .. "] " .. tostring(line))
	end

	-- Checks whether the file is currently being downloaded or is in download queue
	---@return boolean
	function File:isDownloading()
		local downloads = get_downloads()
		for _, v in pairs(downloads) do
			if (v:match(string.escape(self.path:gsub("%.%a+$", "")) .. "%.%a+$")) then
				return true
			end
		end
		return false
	end

	-- Closes the file
	function File:close()
		if (self.data) then
			filesCloseInternal(self.data)
			self.data = nil
		end
	end
end

setupFilesOpen()
