-- Replays manager

local SELECTED_REPLAY = { element = nil, defaultColor = nil, time = 0, replay = nil }
local TB_MENU_REPLAYS = { name = "replay", fullname = "replay" }
local SELECTED_FOLDER = TB_MENU_REPLAYS
local MAXFOLDERLEVELS = 4

do
	Replays = {}
	Replays.__index = Replays
	local cln = {}
	setmetatable(cln, Replays)
	
	function Replays:quit()
		if (get_option("newmenu") == 0) then
			FRIENDSLIST_OPEN = false
			tbMenuMain:kill()
			remove_hooks("tbMainMenuVisual")
			return
		end
		tbMenuCurrentSection:kill(true)
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function Replays:getNavigationButtons()
		local buttonText = get_option("newmenu") == 0 and TB_MENU_LOCALIZED.NAVBUTTONEXIT or TB_MENU_LOCALIZED.NAVBUTTONTOMAIN
		local navigation = {
			{ 
				text = buttonText, 
				action = function() Replays:quit() end, 
				width = get_string_length(buttonText, FONTS.BIG) * 0.65 + 30 
			}
		}
		return navigation
	end
	
	function Replays:getReplayInfo(path)
		local replay = Files:new("../" .. path, FILES_MODE_READONLY)
		local rplInfo = {}
		local hasDecap = false
		local version = 0
		
		if (replay.data) then
			for ln in replay.data:lines() do
				if (ln:match("FIGHTNAME 0;")) then
					-- We base version off second replay line instead of actual VERSION
					version = 10
				elseif (ln:match("AUTHOR 0;")) then
					rplInfo.author = ln:gsub("AUTHOR 0;", "")
					rplInfo.author = PlayerInfo:getUser(rplInfo.author:gsub("^ ", ""))
				elseif (ln:match("NEWGAME %d;")) then
					local mod = ln:gsub("NEWGAME %d;", "")
					rplInfo.mod = mod:match("/*%S*%.tbm")
					rplInfo.mod = rplInfo.mod and rplInfo.mod:gsub("/", "") or "classic"
				elseif (ln:match("CRUSH %d; 0") and not hasDecap) then
					rplInfo.hiddentags = rplInfo.hiddentags and rplInfo.hiddentags .. " decap" or "decap"
					hasDecap = true
				end
				if (version > 9) then
					if (ln:match("FIGHTNAME 0;")) then
						rplInfo.name = ln:gsub("FIGHTNAME 0;", "")
						rplInfo.name = rplInfo.name:gsub("^ ", "")
					elseif (ln:match("BOUT 0;")) then
						rplInfo.bout0 = ln:gsub("BOUT 0;", "")
						rplInfo.bout0 = PlayerInfo:getUser(rplInfo.bout0:gsub("^ ", ""))
					elseif (ln:match("BOUT 1;")) then
						rplInfo.bout1 = ln:gsub("BOUT 1;", "")
						rplInfo.bout1 = PlayerInfo:getUser(rplInfo.bout1:gsub("^ ", ""))
					end
				else
					if (ln:match("FIGHT %d;")) then
						local info = ln:gsub("FIGHT %d; ", "")
						rplInfo.bout1 = PlayerInfo:getUser(info:match("[^ ]+$"))
						info = info:gsub(" [^ ]+$", "")
						rplInfo.bout0 = PlayerInfo:getUser(info:match("[^ ]+$"))
						rplInfo.name = info:gsub(" [^ ]+$", "")
					end
				end
			end
		end
		
		local infodata = { name = path, bout0 = " ", bout1 = " ", author = "autosave", mod = "classic", tags = " ", hiddentags = " ", uploaded = 0 }
		for i,v in pairs(infodata) do
			if (not rplInfo[i] or rplInfo[i] == "") then
				rplInfo[i] = v
			end
		end
		
		-- Create replay names for autosave replays
		if (rplInfo.name == "vs") then
			if (path:find(".*_vs_.+%d+_%d+")) then
				local name = path:gsub("^.*/", "")
				name = name:gsub(".rpl$", "")
				local score = string.gsub(name:match("%d+_%d+$"), "_", " - ")
				name = name:sub(0, -string.len(score))
				local bout1 = string.gsub(name:match("_vs_.*$"), "_vs_", "")
				local bout0 = string.gsub(name:match("^.*_vs_"), "_vs_", "")
				bout0 = bout0:gsub("%d+-%d+-", "")
				
				rplInfo.name = bout0 .. " vs " .. bout1 .. " (" .. score .. ")"
			else 
				rplInfo.name = string.gsub(path:gsub("^.*/", ""), ".rpl$", "")
			end
		end
				
		replay:close()
		return rplInfo
	end
	
	function Replays:fetchReplayData(folder, level, file, filedata)
		local folder = folder or "replay"
		local rplTable = level or TB_MENU_REPLAYS
		
		if (not rplTable.replays) then
			rplTable.replays = {}
			rplTable.folders = {}
		end
		
		for i, v in pairs(get_files(folder, "")) do
			if (v:match(".rpl$")) then
				local replaydata = { filename = v:lower() }
				local replaypath = folder and string.lower(folder .. "/" .. v) or replaydata.filename
				local replaydatapath = replaypath:gsub(" ", "_")
				if (filedata[replaydatapath]) then
					replaydata.name = filedata[replaydatapath].name
					replaydata.author = filedata[replaydatapath].author
					replaydata.mod = filedata[replaydatapath].mod
					replaydata.bout0 = filedata[replaydatapath].bout0
					replaydata.bout1 = filedata[replaydatapath].bout1
					replaydata.tags = filedata[replaydatapath].tags
					replaydata.hiddentags = filedata[replaydatapath].hiddentags
					replaydata.uploaded = filedata[replaydatapath].uploaded
				else 
					replaydata = Replays:getReplayInfo(replaypath)
					replaydata.filename = v:lower()
					file.data:write(replaypath .. "\t" ..
									replaydata.name .. "\t" ..
									replaydata.author .. "\t" ..
									replaydata.mod .. "\t" ..
									replaydata.bout0 .. "\t" ..
									replaydata.bout1 .. "\t" ..
									replaydata.tags .. "\t" ..
									replaydata.hiddentags .. "\t" ..
									replaydata.uploaded .. "\t" ..
									"\n")
				end
				table.insert(rplTable.replays, {
					filename = folder == "replay" and replaydata.filename or folder:gsub("^replay/", "") .. "/" .. replaydata.filename,
					name = replaydata.name,
					author = replaydata.author,
					mod = replaydata.mod,
					bouts = { replaydata.bout0, replaydata.bout1 },
					tags = replaydata.tags,
					hiddentags = replaydata.hiddentags,
					uploaded = replaydata.uploaded == 1
				})
			elseif (v ~= "." and v ~= ".." and v ~= "system" and not v:find("%.%a+$")) then
				--if (is_folder(folder .. "/" .. v)) then
					table.insert(rplTable.folders, {
						parent = rplTable,
						name = v,
						fullname = rplTable.fullname .. "/" .. v
					})
					Replays:fetchReplayData(folder .. "/" .. v, rplTable.folders[#rplTable.folders], file, filedata)
					if (rplTable.fullname .. "/" .. v == SELECTED_FOLDER.fullname) then
						SELECTED_FOLDER = rplTable.folders[#rplTable.folders]
					end
				--end
			end
		end
		rplTable.replays = UIElement:qsort(rplTable.replays, "filename")
	end
	
	function Replays:updateReplayFile(replay)
		local file = Files:new("../replay/" .. replay.filename, FILES_MODE_READONLY)
		if (not file.data) then
			TBMenu:showDataError("Error reading replay file")
			return false
		end
		local replaydata = {}
		for ln in file.data:lines() do
			if (ln:find("^FIGHTNAME %d;")) then
				table.insert(replaydata, ln:gsub(";.*$", "; ") .. replay.name)
			elseif (ln:find("^FIGHT %d;")) then
				table.insert(replaydata, ln:gsub(";.*$", "; ") .. replay.name .. " " .. replay.bouts[1] .. " " .. replay.bouts[2])
			else
				table.insert(replaydata, ln)
			end
		end
		file:close()
		
		local file = Files:new("../replay/" .. replay.filename, FILES_MODE_WRITE)
		if (not file.data) then
			TBMenu:showDataError("Error updating replay file")
			return false
		end
		for i, line in pairs(replaydata) do
			file.data:write(line .. "\n")
		end
		file:close()
		
		return true
	end
	
	function Replays:updateReplayCache(replay, newreplay)
		local matchFound = false
		if (newreplay) then
			if (replay.name ~= newreplay.name) then
				echo("updating replay file")
				if (not Replays:updateReplayFile(newreplay)) then
					TBMenu:showDataError("Error updating replay name")
					return false
				end
			end
		end
		
		local file = Files:new("../replay/replaycache.dat", FILES_MODE_READONLY)
		if (not file.data) then
			TBMenu:showDataError("Error reading replay cache file")
			return false
		end
		
		local filedata = {}
		for ln in file.data:lines() do
			if (ln:find("^" .. strEsc("replay/" .. replay.filename))) then
				if (newreplay and not matchFound) then
					matchFound = true
					table.insert(filedata, 
						"replay/" .. newreplay.filename .. "\t" ..
						newreplay.name .. "\t" ..
						newreplay.author .. "\t" ..
						newreplay.mod .. "\t" ..
						newreplay.bouts[1] .. "\t" ..
						newreplay.bouts[2] .. "\t" ..
						newreplay.tags .. "\t" ..
						newreplay.hiddentags .. "\t" ..
						(newreplay.uploaded and "1\t" or "0\t"))
				end
			else
				table.insert(filedata, ln)
			end
		end
		file:close()
		
		local file = Files:new("../replay/replaycache.dat", FILES_MODE_WRITE)
		if (not file.data) then
			TBMenu:showDataError("Error updating replay tags")
			return false
		end
		for i, line in pairs(filedata) do
			file.data:write(line .. "\n")
		end
		file:close()
		
		return true
	end
	
	function Replays:getReplayFolders(folder, level, levelint)
		local folders = folder or {}
		local level = level or TB_MENU_REPLAYS
		local levelint = levelint or 1
		
		if (#folders < 1) then
			table.insert(folders, { name = "replay [root]", fullname = "replay", level = 1 })
		end
		
		local parentFolder = folders[#folders]
				
		for i,v in pairs(level.folders) do
			table.insert(folders, { name = v.name, fullname = parentFolder.fullname .. "/" .. v.name, level = levelint })
			Replays:getReplayFolders(folders, v, levelint + 1)
		end
		return folders
	end
	
	function Replays:getReplayFiles()
		-- Make sure replays table is flushed first
		TB_MENU_REPLAYS.replays = nil
		TB_MENU_REPLAYS.folders = nil
		
		local file = Files:new("../replay/replaycache.dat", FILES_MODE_READWRITE)
		if (not file.data) then
			file = Files:new("../replay/replaycache.dat", FILES_MODE_WRITE)
			if (not file.data) then
				echo("Error creating file")
			end
		end
		
		local filedata = {}
		for ln in file.data:lines() do
			local segments = 8
			local data_stream = { ln:match(("([^\t]+)\t*"):rep(segments)) }
			local filename = string.lower(data_stream[1]:gsub(" ", "_"))
			filedata[filename] = { 
				name = data_stream[2], 
				author = data_stream[3], 
				mod = data_stream[4]:lower(), 
				bout0 = data_stream[5], 
				bout1 = data_stream[6],
			 	tags = data_stream[7]:lower(),
				hiddentags = data_stream[8]:lower(),
				uploaded = tonumber(data_stream[9])
			}
		end
		Replays:fetchReplayData(nil, nil, file, filedata)
		if (not SELECTED_FOLDER.name) then
			SELECTED_FOLDER = TB_MENU_REPLAYS
		end
		file:close()
	end
	
	function Replays:getPopularTags()
		return {
			"multiplayer",
			"madman",
			"manipulation",
			"realism",
			"tricking",
			"sparring",
			"parkour"
		}
	end
	
	function Replays:findReplays(searchString, rplTable, searchResults)
		local replays = rplTable or TB_MENU_REPLAYS
		local searchResults = searchResults or { name = {}, filename = {}, author = {}, bouts = {}, mod = {}, tags = {}, hiddentags = {} }
		local searchString = searchString:lower()
		
		for i, folder in pairs(rplTable.folders) do
			Replays:findReplays(searchString, folder, searchResults)
		end
		for i, replay in pairs(rplTable.replays) do
			if (string.find(replay.name:lower(), searchString)) then
				table.insert(searchResults.name, replay)
			elseif (string.find(replay.filename:lower(), searchString)) then
				table.insert(searchResults.filename, replay)
			elseif (string.find(replay.author:lower(), searchString)) then
				table.insert(searchResults.author, replay)
			elseif (string.find(replay.mod:lower(), searchString)) then
				table.insert(searchResults.mod, replay)
			elseif (string.find(replay.tags:lower(), searchString)) then
				table.insert(searchResults.tags, replay)
			elseif (string.find(replay.hiddentags:lower(), searchString)) then
				table.insert(searchResults.hiddentags, replay)
			else
				for k, bout in pairs(replay.bouts) do
					if (string.find(bout:lower(), searchString)) then
						table.insert(searchResults.bouts, replay)
					end
				end
			end
		end
		return searchResults
	end
	
	function Replays:showSearchList(viewElement, replayInfo, toReload, replays)
		viewElement:kill(true)		
		local posY, elementHeight = 0, 40
		
		local listingHolder = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w - 20, viewElement.size.h }
		})
		
		local listing = {}
		local goBack = UIElement:new({
			parent = listingHolder,
			pos = { 0, posY },
			size = { listingHolder.size.w, elementHeight },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.3 }
		})
		goBack:addCustomDisplay(false, function()
				goBack:uiText("BACK TO ALL REPLAYS", nil, nil, 4, nil, 0.6)
			end)
		goBack:addMouseHandlers(nil, function()
				SELECTED_REPLAY.replay = nil
				Replays:showList(viewElement.parent, replayInfo, rplTable)
			end)
		posY = posY + elementHeight
		table.insert(listing, goBack)
		
		for section, replayList in pairs(replays) do
			if (#replayList > 0) then
				local sectionName = UIElement:new({
					parent = listingHolder,
					pos = { 10, posY },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				local sectionStr = "Match by " .. section
				if (section == "hiddentags") then
					sectionStr = "hidden tags"
				end
				sectionName:addCustomDisplay(true, function()
						sectionName:uiText(sectionStr, nil, nil, nil, LEFTMID)
					end)
				posY = posY + elementHeight
				table.insert(listing, sectionName)
				for i, replay in pairs(replayList) do
					local replayElement = UIElement:new({
						parent = listingHolder,
						pos = { 0, posY },
						size = { listingHolder.size.w, elementHeight },
						interactive = true,
						bgColor = i % 2 ~= 0 and TB_MENU_DEFAULT_DARKER_COLOR or TB_MENU_DEFAULT_BG_COLOR,
						hoverColor = { 0, 0, 0, 0.3 },
						pressedColor = { 1, 1, 1, 0.2 }
					})
					if (SELECTED_REPLAY.replay and SELECTED_REPLAY.replay.filename == replay.filename or i == 1) then
						SELECTED_REPLAY.element = replayElement
						SELECTED_REPLAY.defaultColor = { replayElement.bgColor[1], replayElement.bgColor[2], replayElement.bgColor[3], replayElement.bgColor[4] }
					end
					replayElement:addMouseHandlers(nil, function()
							if (SELECTED_REPLAY.element == replayElement and SELECTED_REPLAY.time + 0.5 > os.clock()) then
								Replays:playReplay(replay)
								return
							end
							SELECTED_REPLAY.time = os.clock()
							SELECTED_REPLAY.element.bgColor = { SELECTED_REPLAY.defaultColor[1], SELECTED_REPLAY.defaultColor[2], SELECTED_REPLAY.defaultColor[3], SELECTED_REPLAY.defaultColor[4] }
							SELECTED_REPLAY.element = replayElement
							SELECTED_REPLAY.defaultColor = { replayElement.bgColor[1], replayElement.bgColor[2], replayElement.bgColor[3], replayElement.bgColor[4] }
							Replays:showReplayInfo(replayInfo, replay)
						end)
					table.insert(listing, replayElement)
					
					local replayName = UIElement:new({
						parent = replayElement,
						pos = { 10, 0 },
						size = { replayElement.size.w / 2 - 20, replayElement.size.h }
					})
					replayName:addCustomDisplay(true, function()
							replayName:uiText(replay.name, nil, nil, 4, LEFTMID, 0.65)
						end)
					local replayNameSeparator = UIElement:new({
						parent = replayElement,
						pos = { replayName.shift.x + replayName.size.w, replayElement.size.h / 4 },
						size = { 1, replayElement.size.h / 2 },
						bgColor = { 1, 1, 1, 0.2 }
					})
					local replayAuthor = UIElement:new({
						parent = replayElement,
						pos = { replayNameSeparator.shift.x, 0 },
						size = { replayElement.size.w / 6, replayElement.size.h }
					})
					local replayAuthorStr = replay.author == "autosave" and "autosave" or "by " .. replay.author
					replayAuthor:addCustomDisplay(true, function()
							replayAuthor:uiText(replayAuthorStr, nil, nil, 4, nil, 0.65)
						end)
					local replayAuthorSeparator = UIElement:new({
						parent = replayElement,
						pos = { replayAuthor.shift.x + replayAuthor.size.w, replayElement.size.h / 4 },
						size = { 1, replayElement.size.h / 2 },
						bgColor = { 1, 1, 1, 0.2 }
					})
					local replayMod = UIElement:new({
						parent = replayElement,
						pos = { replayAuthorSeparator.shift.x, 0 },
						size = { replayElement.size.w - replayAuthorSeparator.shift.x, replayElement.size.h }
					})
					replayMod:addCustomDisplay(true, function()
							replayMod:uiText(replay.mod, nil, nil, 4, nil, 0.65)
						end)
					posY = posY + elementHeight
				end
			end
		end
		
		for i,v in pairs(listing) do
			v:hide()
		end
		
		local listingScrollBG = UIElement:new({
			parent = viewElement,
			pos = { -(viewElement.size.w - listingHolder.size.w), 0 },
			size = { viewElement.size.w - listingHolder.size.w, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local listingScrollBar = TBMenu:spawnScrollBar(listingHolder, #listing, elementHeight)
		listingScrollBar:makeScrollBar(listingHolder, listing, toReload)
	end
	
	function Replays:playReplay(replay)
		local whiteoverlay = UIElement:new({
			parent = tbMenuMain,
			pos = { 0, 0 },
			size = { tbMenuMain.size.w, tbMenuMain.size.h },
			bgColor = { 1, 1, 1, 0 }
		})
		whiteoverlay:addCustomDisplay(false, function()
				whiteoverlay.bgColor[4] = whiteoverlay.bgColor[4] + 0.05
			end)
		local loading = UIElement:new({
			parent = whiteoverlay,
			pos = { WIN_W / 4, WIN_H / 7 * 3 },
			size = { WIN_W / 2, WIN_H / 7 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local wait = 0
		loading:addCustomDisplay(false, function()
				loading:uiText("Loading replay...")
				wait = wait + 1
				if (wait > 4) then
					UIElement:runCmd("loadreplay " .. replay.filename)
					close_menu()
				end
			end)
	end
	
	function Replays:showList(viewElement, replayInfo, level)
		viewElement:kill(true)
		
		local bottomSmudge = TBMenu:addBottomBloodSmudge(viewElement, 1)
		
		local posY, elementHeight = 0, 35
		local rplTable = level or TB_MENU_REPLAYS
		SELECTED_FOLDER = rplTable
		
		local toReload = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h }
		})
		local topBar = UIElement:new({
			parent = toReload,
			pos = { 0, 0 },
			size = { viewElement.size.w, 50 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local replaysTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 0 },
			size = { topBar.size.w / 3 * 2 - 20, topBar.size.h }
		})
		replaysTitle:addCustomDisplay(true, function()
				replaysTitle:uiText(TB_MENU_LOCALIZED.MAINMENUREPLAYSNAME, nil, nil, FONTS.BIG, LEFTMID, 0.75, nil, nil, nil, nil, 0.2)
			end)
			
		if (level.fullname ~= "replay/autosave") then
			local posX = 0
			if (level.fullname ~= "replay/my replays" and level.fullname ~= "replay") then
				local editFolderButton = UIElement:new({
					parent = topBar,
					pos = { -topBar.size.h + 10, 10 },
					size = { topBar.size.h - 20, topBar.size.h - 20 },
					interactive = true,
					bgColor = { 0, 0, 0, 0.1 },
					hoverColor = { 0, 0, 0, 0.3 },
					pressedColor = { 1, 1, 1, 0.2 },
					bgImage = "../textures/menu/general/buttons/edit.tga"
				})
				posX = editFolderButton.shift.x
				editFolderButton:addMouseHandlers(nil, function()
						Replays:showEditFolderWindow()
					end)
			end
			
			local addFolderButton = UIElement:new({
				parent = topBar,
				pos = { topBar.size.w / 3 * 2 + 10, 10 },
				size = { topBar.size.w / 3 - 20 + posX, topBar.size.h - 20 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 }
			})
			addFolderButton:addCustomDisplay(false, function()
					addFolderButton:uiText("Add folder")
				end)
			addFolderButton:addMouseHandlers(nil, function()
					Replays:showNewFolderWindow()
				end)
		end
		
		local botBar = UIElement:new({
			parent = toReload,
			pos = { 0, -elementHeight },
			size = { viewElement.size.w, elementHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local searchInput = UIElement:new({
			parent = botBar,
			pos = { 10, 10 },
			size = { botBar.size.w * 0.7 - 20, botBar.size.h - 10 },
			bgColor = { 1, 1, 1, 0.5 }
		})
		local searchInputField = UIElement:new({
			parent = searchInput,
			pos = { 5, 0 },
			size = { searchInput.size.w - 10, searchInput.size.h },
			interactive = true,
			textfield = true
		})
		searchInputField:addMouseHandlers(function()
				TBMenu:enableMenuKeyboard(searchInputField)
			end)
		TBMenu:displayTextfield(searchInputField, FONTS.SMALL, 1, UICOLORBLACK, "Search for replays here...")
		local searchButton = UIElement:new({
			parent = botBar,
			pos = { botBar.size.w * 0.7, searchInput.shift.y },
			size = { botBar.size.w * 0.3 - 10, searchInput.size.h },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		searchButton:addCustomDisplay(false, function()
				searchButton:uiText("Search")
			end)
		
		local listingView = UIElement:new({
			parent = viewElement,
			pos = { 0, topBar.size.h },
			size = { viewElement.size.w, viewElement.size.h - topBar.size.h - botBar.size.h }
		})
		searchButton:addMouseHandlers(nil, function()
				Replays:showSearchList(listingView, replayInfo, toReload, Replays:findReplays(searchInputField.textfieldstr[1], rplTable))
			end)
		
		local listingHolder = UIElement:new({
			parent = listingView,
			pos = { 0, 0 },
			size = { listingView.size.w - 20, listingView.size.h }
		})
		
		local listing = {}
		if (rplTable ~= TB_MENU_REPLAYS) then
			local folderElement = UIElement:new({
				parent = listingHolder,
				pos = { 0, posY },
				size = { listingHolder.size.w, elementHeight },
				interactive = true,
				bgColor = posY % (elementHeight * 2) == 0 and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 }
			})
			table.insert(listing, folderElement)
			folderElement:addMouseHandlers(nil, function()
					SELECTED_REPLAY.replay = nil
					Replays:showList(viewElement, replayInfo, rplTable.parent)
				end)
			local folderIcon = UIElement:new({
				parent = folderElement,
				pos = { 10, 0 },
				size = { folderElement.size.h, folderElement.size.h },
				bgImage = "../textures/menu/general/back.tga"
			})
			local folderName = UIElement:new({
				parent = folderElement,
				pos = { folderIcon.shift.x * 2 + folderElement.size.h, 0 },
				size = { folderElement.size.w - folderElement.size.h - folderIcon.shift.x * 3, folderElement.size.h }
			})
			folderName:addCustomDisplay(true, function()
					folderName:uiText(rplTable.parent.name, nil, nil, 4, LEFTMID, 0.8)
				end)
			posY = posY + elementHeight
		end
		for i, folder in pairs(rplTable.folders) do
			local folderElement = UIElement:new({
				parent = listingHolder,
				pos = { 0, posY },
				size = { listingHolder.size.w, elementHeight },
				interactive = true,
				bgColor = posY % (elementHeight * 2) == 0 and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 }
			})
			table.insert(listing, folderElement)
			folderElement:addMouseHandlers(nil, function()
					SELECTED_REPLAY.replay = nil
					Replays:showList(viewElement, replayInfo, folder)
				end)
			local folderIcon = UIElement:new({
				parent = folderElement,
				pos = { 10, 0 },
				size = { folderElement.size.h, folderElement.size.h },
				bgImage = "../textures/menu/general/folder.tga"
			})
			local folderName = UIElement:new({
				parent = folderElement,
				pos = { folderIcon.shift.x * 2 + folderElement.size.h, 0 },
				size = { folderElement.size.w - folderElement.size.h - folderIcon.shift.x * 3, folderElement.size.h }
			})
			folderName:addCustomDisplay(true, function()
					folderName:uiText(folder.name, nil, nil, 4, LEFTMID, 0.8)
				end)
			posY = posY + elementHeight
		end
		for i, replay in pairs(rplTable.replays) do
			local replayElement = UIElement:new({
				parent = listingHolder,
				pos = { 0, posY },
				size = { listingHolder.size.w, elementHeight },
				interactive = true,
				bgColor = posY % (elementHeight * 2) == 0 and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_DARKER_COLOR,
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 1, 1, 0.2 }
			})
			if (SELECTED_REPLAY.replay and SELECTED_REPLAY.replay.filename == replay.filename or i == 1) then
				SELECTED_REPLAY.element = replayElement
				SELECTED_REPLAY.defaultColor = { replayElement.bgColor[1], replayElement.bgColor[2], replayElement.bgColor[3], replayElement.bgColor[4] }
			end
			replayElement:addMouseHandlers(nil, function()
					if (SELECTED_REPLAY.element == replayElement and SELECTED_REPLAY.time + 0.5 > os.clock()) then
						Replays:playReplay(replay)
						return
					end
					SELECTED_REPLAY.time = os.clock()
					SELECTED_REPLAY.element.bgColor = { SELECTED_REPLAY.defaultColor[1], SELECTED_REPLAY.defaultColor[2], SELECTED_REPLAY.defaultColor[3], SELECTED_REPLAY.defaultColor[4] }
					SELECTED_REPLAY.element = replayElement
					SELECTED_REPLAY.defaultColor = { replayElement.bgColor[1], replayElement.bgColor[2], replayElement.bgColor[3], replayElement.bgColor[4] }
					Replays:showReplayInfo(replayInfo, replay)
				end)
			table.insert(listing, replayElement)
			
			local replayName = UIElement:new({
				parent = replayElement,
				pos = { 10, 0 },
				size = { replayElement.size.w / 2 - 20, replayElement.size.h }
			})
			replayName:addCustomDisplay(true, function()
					replayName:uiText(replay.name, nil, nil, 4, LEFTMID, 0.65)
				end)
			local replayNameSeparator = UIElement:new({
				parent = replayElement,
				pos = { replayName.shift.x + replayName.size.w, replayElement.size.h / 4 },
				size = { 1, replayElement.size.h / 2 },
				bgColor = { 1, 1, 1, 0.2 }
			})
			local replayAuthor = UIElement:new({
				parent = replayElement,
				pos = { replayNameSeparator.shift.x, 0 },
				size = { replayElement.size.w / 6, replayElement.size.h }
			})
			local replayAuthorStr = replay.author == "autosave" and "autosave" or "by " .. replay.author
			replayAuthor:addCustomDisplay(true, function()
					replayAuthor:uiText(replayAuthorStr, nil, nil, 4, nil, 0.65)
				end)
			local replayAuthorSeparator = UIElement:new({
				parent = replayElement,
				pos = { replayAuthor.shift.x + replayAuthor.size.w, replayElement.size.h / 4 },
				size = { 1, replayElement.size.h / 2 },
				bgColor = { 1, 1, 1, 0.2 }
			})
			local replayMod = UIElement:new({
				parent = replayElement,
				pos = { replayAuthorSeparator.shift.x, 0 },
				size = { replayElement.size.w - replayAuthorSeparator.shift.x, replayElement.size.h }
			})
			replayMod:addCustomDisplay(true, function()
					replayMod:uiText(replay.mod, nil, nil, 4, nil, 0.65)
				end)
			posY = posY + elementHeight
		end
		
		for i,v in pairs(listing) do
			v:hide()
		end
		
		local listingScrollBG = UIElement:new({
			parent = listingView,
			pos = { -(listingView.size.w - listingHolder.size.w), 0 },
			size = { listingView.size.w - listingHolder.size.w, listingView.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local listingScrollBar = TBMenu:spawnScrollBar(listingHolder, #listing, elementHeight)
		listingScrollBar:makeScrollBar(listingHolder, listing, toReload)
		Replays:showReplayInfo(replayInfo, SELECTED_REPLAY.replay or rplTable.replays[1])
	end
	
	function Replays:showReplayTaglistTag(viewElement, updatedTags, tag, elementHeight, posInfo, popularTags)
		local width = get_string_length(tag, 4) * 0.7 + 34
		if (width > viewElement.size.w) then
			width = viewElement.size.w
		end
		if (width + posInfo.x > viewElement.size.w) then
			posInfo.x = 0
			posInfo.y = posInfo.y + elementHeight
		end
		local replayTag = UIElement:new({
			parent = viewElement,
			pos = { posInfo.x, posInfo.y },
			size = { width, elementHeight }
		})
		local replayTagName = UIElement:new({
			parent = replayTag,
			pos = { 10, 0 },
			size = { replayTag.size.w, replayTag.size.h }
		})
		replayTagName:addCustomDisplay(true, function()
				replayTagName:uiText(tag, nil, nil, 4, LEFTMID, 0.7)
			end)
		local replayTagRemoveButton = UIElement:new({
			parent = replayTag,
			pos = { -24, 3 },
			size = { 24, 24 },
			shapeType = ROUNDED,
			rounded = 3,
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		local tagRemoveIcon = UIElement:new({
			parent = replayTagRemoveButton,
			pos = { 4, 4 },
			size = { 16, 16 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		replayTagRemoveButton:addMouseHandlers(nil, function()
				for i,v in pairs(updatedTags) do
					if (v == tag) then
						table.remove(updatedTags, i)
						for j, k in pairs(popularTags) do
							if (j == tag) then
								Replays:tagButtonActivate(k)
								break
							end
						end
						break
					end
				end
				viewElement:kill(true)
				posInfo.x, posInfo.y = 0, 0
				for i,tag in pairs(updatedTags) do
					Replays:showReplayTaglistTag(viewElement, updatedTags, tag, elementHeight, posInfo, popularTags)
				end
			end)
		posInfo.x = posInfo.x + width
	end
	
	function Replays:tagButtonDeactivate(tagAdd)
		tagAdd:deactivate()
		tagAdd:addCustomDisplay(false, function() end)
		tagAdd:updateImage("../textures/menu/general/buttons/checkmark.tga")
		tagAdd.bgColor = { 1, 1, 1, 0.2 }
	end
	
	function Replays:tagButtonActivate(tagAdd)
		tagAdd:updateImage(nil)
		tagAdd:activate()
		tagAdd:addCustomDisplay(false, function()
				set_color(1, 1, 1, 0.8)
				draw_quad(	tagAdd.pos.x + tagAdd.size.w / 2 - 1,
							tagAdd.pos.y + 4,
							2,
							tagAdd.size.h - 8	)
				draw_quad(	tagAdd.pos.x + 4,
							tagAdd.pos.y + tagAdd.size.h / 2 - 1,
							tagAdd.size.w - 8,
							2	)
			end)
		tagAdd.bgColor = { 0, 0, 0, 0.3 }
	end
	
	function Replays:showTags(replayInfoView, replay)
		local updatedTags = {}
		for i in string.gmatch(replay.tags, "%S+") do
			table.insert(updatedTags, i)
		end
		
		local tagsOverlay = UIElement:new({
			parent = tbMenuMain,
			pos = { 0, 0 },
			size = { tbMenuMain.size.w, tbMenuMain.size.h },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 }
		})
		local tagsView = UIElement:new({
			parent = tagsOverlay,
			pos = { tagsOverlay.size.w / 8, tagsOverlay.size.h / 6 },
			size = { tagsOverlay.size.w / 8 * 6, tagsOverlay.size.h / 6 * 4 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local tagsTitle = UIElement:new({
			parent = tagsView,
			pos = { 10, 0 },
			size = { tagsView.size.w - 20, tagsView.size.h / 8 }
		})
		tagsTitle:addCustomDisplay(true, function()
				tagsTitle:uiText("Modifying " .. replay.name ..  " replay tags")
			end)
		
		local popularTagsView = UIElement:new({
			parent = tagsView,
			pos = { 10, tagsTitle.size.h },
			size = { tagsView.size.w / 2 - 20, tagsView.size.h - tagsTitle.size.h * 2 - 10 }
		})
		local replayTags = UIElement:new({
			parent = tagsView,
			pos = { tagsView.size.w / 2 + 10, tagsTitle.size.h },
			size = { tagsView.size.w / 2 - 20, tagsView.size.h / 8 * 7 - tagsTitle.size.h - 10 }
		})
		local tagsSeparator = UIElement:new({
			parent = tagsView,
			pos = { tagsView.size.w / 2 - 1, tagsTitle.size.h + 20 },
			size = { 1, tagsView.size.h - tagsTitle.size.h - 40 },
			bgColor = { 1, 1, 1, 0.2 }
		})		
		
		local posY, elementHeight = 30, 30
		local replayTagListInfo = { y = 0, x = 0 }
		
		local popularTagsName = UIElement:new({
			parent = popularTagsView,
			pos = { 10, 0 },
			size = { popularTagsView.size.w - 20, elementHeight }
		})
		popularTagsName:addCustomDisplay(true, function()
				popularTagsName:uiText("Popular Tags")
			end)
		local replayTagsName = UIElement:new({
			parent = replayTags,
			pos = { 10, 0 },
			size = { replayTags.size.w - 20, elementHeight }
		})
		replayTagsName:addCustomDisplay(true, function()
				replayTagsName:uiText("Assigned Tags")
			end)
		local replayTagsView = UIElement:new({
			parent = replayTags,
			pos = { 0, replayTagsName.size.h },
			size = { replayTags.size.w, replayTags.size.h - replayTagsName.size.h }
		})
		
		local popularTagsButtons = {}
		for i, tag in pairs(Replays:getPopularTags()) do
			if (posY + elementHeight < popularTagsView.size.h) then
				local tagElement = UIElement:new({
					parent = popularTagsView,
					pos = { 0, posY },
					size = { popularTagsView.size.w, elementHeight }
				})
				local tagName = UIElement:new({
					parent = tagElement,
					pos = { 0, 0 },
					size = { tagElement.size.w - 30, tagElement.size.h }
				})
				tagName:addCustomDisplay(true, function()
						tagName:uiText(tag, nil, nil, 4, LEFTMID, 0.7)
					end)
				local tagAdd = UIElement:new({
					parent = tagElement,
					pos = { tagElement.size.w - 24, 3 },
					size = { 24, 24 },
					shapeType = ROUNDED,
					rounded = 3,
					interactive = true,
					bgColor = { 0, 0, 0, 0.3 },
					hoverColor = { 0, 0, 0, 0.5 },
					pressedColor = { 1, 1, 1, 0.2 }
				})
				tagAdd:addMouseHandlers(nil, function()
						table.insert(updatedTags, tag)
						Replays:showReplayTaglistTag(replayTagsView, updatedTags, tag, elementHeight, replayTagListInfo, popularTagsButtons)
						Replays:tagButtonDeactivate(tagAdd)
					end)
				if (not replay.tags:find(tag)) then
					Replays:tagButtonActivate(tagAdd)
				else
					Replays:tagButtonDeactivate(tagAdd)
				end
				popularTagsButtons[tag] = tagAdd
			else 
				break
			end
			posY = posY + elementHeight
		end
		
		local tagInputFieldView = UIElement:new({
			parent = tagsView,
			pos = { 10, -tagsView.size.h / 8 },
			size = { tagsView.size.w / 2 - 20, tagsView.size.h / 10 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local tagInputFieldBG = UIElement:new({
			parent = tagInputFieldView,
			pos = { 1, 1 },
			size = { tagInputFieldView.size.w - 2, tagInputFieldView.size.h - 2 },
			bgColor = { 1, 1, 1, 0.5 }
		})
		local tagInputField = UIElement:new({
			parent = tagInputFieldBG,
			pos = { 5, 0 },
			size = { tagInputFieldBG.size.w - tagInputFieldBG.size.h * 2 - 10, tagInputFieldBG.size.h },
			interactive = true,
			textfield = true
		})
		tagInputField:addMouseHandlers(function()
				TBMenu:enableMenuKeyboard(tagInputField)
			end)
		TBMenu:displayTextfield(tagInputField, FONTS.SMALL, 1, UICOLORBLACK, "Input your own tag here...")
		local tagButton = UIElement:new({
			parent = tagInputFieldBG,
			pos = { -tagInputFieldBG.size.h * 2, 0 },
			size = { tagInputFieldBG.size.h * 2, tagInputFieldBG.size.h },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		tagButton:addCustomDisplay(false, function()
				tagButton:uiText("Add")
			end)
		tagButton:addMouseHandlers(nil, function()
				local tagString = tagInputField.textfieldstr[1]
				if (tagString:gsub("%A", "") == "" or tagString:len() < 2) then
					TBMenu:showDataError("Replay tag should contain at least one letter")
					return
				end
				for i,v in pairs(updatedTags) do
					if (v == tagString) then
						TBMenu:showDataError("This tag has already been added to the replay")
						return
					end
				end
				tagInputField:clearTextfield()
				table.insert(updatedTags, tagString)
				Replays:showReplayTaglistTag(replayTagsView, updatedTags, tagString, elementHeight, replayTagListInfo, popularTagsButtons)
			end)
		
		
		for i, tag in pairs(updatedTags) do
			Replays:showReplayTaglistTag(replayTagsView, updatedTags, tag, elementHeight, replayTagListInfo, popularTagsButtons)
		end
		
		local buttonCancel = UIElement:new({
			parent = tagsView,
			pos = { tagsView.size.w / 2 + 10, -tagsView.size.h / 8 },
			size = { tagsView.size.w / 4 - 15, tagsView.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		buttonCancel:addCustomDisplay(false, function()
				buttonCancel:uiText("Cancel")
			end)
		buttonCancel:addMouseHandlers(nil, function()
				tagsOverlay:kill()
			end)
		local buttonSave = UIElement:new({
			parent = tagsView,
			pos = { tagsView.size.w / 4 * 3, -tagsView.size.h / 8 },
			size = { tagsView.size.w / 4 - 10, tagsView.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		buttonSave:addCustomDisplay(false, function()
				buttonSave:uiText("Save")
			end)
		buttonSave:addMouseHandlers(nil, function()
				local tagsString
				for i,v in pairs(updatedTags) do
					if (i > 1) then
						tagsString = tagsString .. " " .. v
					else
						tagsString = v
					end
				end
				if (not tagsString) then
					tagsString = " "
				end
				
				local newreplay = cloneTable(replay)
				newreplay.tags = tagsString
				
				if (Replays:updateReplayCache(replay, newreplay)) then
					replay.tags = newreplay.tags
				end
				tagsOverlay:kill()
				Replays:showMain(tbMenuCurrentSection)
			end)
	end
	
	function Replays:showEditFolderWindow()
		local editFolderOverlay = TBMenu:spawnWindowOverlay()
		local editFolderView = UIElement:new({
			parent = editFolderOverlay,
			pos = { editFolderOverlay.size.w / 4, editFolderOverlay.size.h / 2 - 100 },
			size = { editFolderOverlay.size.w / 2, 200 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local editFolderTitle = UIElement:new({
			parent = editFolderView,
			pos = { 10, 0 },
			size = { editFolderView.size.w - 20, 50 }
		})
		editFolderTitle:addAdaptedText(true, "Modifying " .. SELECTED_FOLDER.fullname .. " folder", nil, nil, FONTS.BIG)
		local newFolderInputBG = UIElement:new({
			parent = editFolderView,
			pos = { 10, editFolderView.size.h / 2 - 20 },
			size = { editFolderView.size.w - 20, 40 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local newFolderInputOverlay = UIElement:new({
			parent = newFolderInputBG,
			pos = { 1, 1 },
			size = { newFolderInputBG.size.w - 2, newFolderInputBG.size.h - 2 },
			bgColor = { 1, 1, 1, 0.5 }
		})
		local newFolderInput = UIElement:new({
			parent = newFolderInputOverlay,
			pos = { 10, 0 },
			size = { newFolderInputOverlay.size.w - 20, newFolderInputOverlay.size.h },
			interactive = true,
			textfield = true,
			textfieldstr = { SELECTED_FOLDER.name }
		})
		newFolderInput:addMouseHandlers(function()
				TBMenu:enableMenuKeyboard(newFolderInput)
			end)
		TBMenu:displayTextfield(newFolderInput, FONTS.SMALL, nil, UICOLORBLACK, "Folder name")
		
		local posX = 0
		if (#SELECTED_FOLDER.replays == 0 and #SELECTED_FOLDER.folders == 0) then
			local deleteButton = UIElement:new({
				parent = editFolderView,
				pos = { -50, -50 },
				size = { 40, 40 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.3 },
				hoverColor = { 0, 0, 0, 0.5 },
				pressedColor = { 1, 1, 1, 0.2 },
				bgImage = "../textures/menu/general/buttons/trash.tga"
			})
			deleteButton:addMouseHandlers(nil, function()
					echo(SELECTED_FOLDER.fullname)
					local parentFolder = SELECTED_FOLDER.fullname:gsub("/" .. SELECTED_FOLDER.name .. "$", "")
					local result = remove_replay_subfolder(SELECTED_FOLDER.fullname:gsub("^replay/", ""))
					SELECTED_FOLDER = { fullname = parentFolder }
					editFolderOverlay:kill()
					Replays:showMain(tbMenuCurrentSection)
				end)
			posX = posX + 50
		end
		local cancelButton = UIElement:new({
			parent = editFolderView,
			pos = { 10, -50 },
			size = { editFolderView.size.w / 2 - 15 - (posX / 2), 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		cancelButton:addCustomDisplay(false, function()
				cancelButton:uiText("Cancel")
			end)
		cancelButton:addMouseHandlers(nil, function()
				editFolderOverlay:kill()
			end)
		local saveButton = UIElement:new({
			parent = editFolderView,
			pos = { editFolderView.size.w / 2 + 5 - (posX / 2), -50 },
			size = { editFolderView.size.w / 2 - 15 - (posX / 2), 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		saveButton:addCustomDisplay(false, function()
				saveButton:uiText("Update")
			end)
		saveButton:addMouseHandlers(nil, function()
				local newFolderName = newFolderInput.textfieldstr[1]:gsub("%s+$", ""):gsub("^%s+", "")
				local parentFolder = SELECTED_FOLDER.fullname:gsub(SELECTED_FOLDER.name .. "$", "")
				if (SELECTED_FOLDER.name == newFolderName) then
					return
				end
				rename_replay_subfolder(SELECTED_FOLDER.fullname:gsub("^replay/", ""), parentFolder:gsub("^replay/", "") .. newFolderName)
				SELECTED_FOLDER = { fullname = parentFolder .. newFolderName }
				editFolderOverlay:kill()
				Replays:showMain(tbMenuCurrentSection)
			end)
	end
	
	function Replays:showNewFolderWindow()
		local _, level = SELECTED_FOLDER.fullname:gsub("/", "")
		if (level > MAXFOLDERLEVELS - 1) then
			TBMenu:showDataError("You can't spawn more than " .. MAXFOLDERLEVELS .. " folder levels")
			return
		end
		local newFolderOverlay = UIElement:new({
			parent = tbMenuMain,
			pos = { 0, 0 },
			size = { tbMenuMain.size.w, tbMenuMain.size.h },
			interactive = true,
			bgColor = { 0, 0, 0, 0.4 }
		})
		local newFolderView = UIElement:new({
			parent = newFolderOverlay,
			pos = { newFolderOverlay.size.w / 4, newFolderOverlay.size.h / 2 - 100 },
			size = { newFolderOverlay.size.w / 2, 200 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local newFolderTitle = UIElement:new({
			parent = newFolderView,
			pos = { 10, 0 },
			size = { newFolderView.size.w - 20, 50 }
		})
		newFolderTitle:addAdaptedText(true, "Adding new folder inside " .. SELECTED_FOLDER.fullname, nil, nil, FONTS.BIG)
		local newFolderInputBG = UIElement:new({
			parent = newFolderView,
			pos = { 10, newFolderView.size.h / 2 - 20 },
			size = { newFolderView.size.w - 20, 40 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local newFolderInputOverlay = UIElement:new({
			parent = newFolderInputBG,
			pos = { 1, 1 },
			size = { newFolderInputBG.size.w - 2, newFolderInputBG.size.h - 2 },
			bgColor = { 1, 1, 1, 0.5 }
		})
		local newFolderInput = UIElement:new({
			parent = newFolderInputOverlay,
			pos = { 10, 0 },
			size = { newFolderInputOverlay.size.w - 20, newFolderInputOverlay.size.h },
			interactive = true,
			textfield = true
		})
		newFolderInput:addMouseHandlers(function()
				TBMenu:enableMenuKeyboard(newFolderInput)
			end)
		TBMenu:displayTextfield(newFolderInput, FONTS.SMALL, nil, UICOLORBLACK, "New folder name")
		local cancelButton = UIElement:new({
			parent = newFolderView,
			pos = { 10, -50 },
			size = { newFolderView.size.w / 2 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		cancelButton:addCustomDisplay(false, function()
				cancelButton:uiText("Cancel")
			end)
		cancelButton:addMouseHandlers(nil, function()
				newFolderOverlay:kill()
			end)
		local saveButton = UIElement:new({
			parent = newFolderView,
			pos = { newFolderView.size.w / 2 + 5, -50 },
			size = { newFolderView.size.w / 2 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		saveButton:addCustomDisplay(false, function()
				saveButton:uiText("Create")
			end)
		saveButton:addMouseHandlers(nil, function()
				if (newFolderInput.textfieldstr[1] ~= newFolderInput.textfieldstr[1]:match("[^ ][%w+ ]+")) then
					TBMenu:showDataError("Folder name should be alphanumeric")
					return
				end
				local parentFolder = SELECTED_FOLDER.fullname:gsub("^replay/*", "")
				parentFolder = parentFolder:len() > 0 and parentFolder .. "/" or parentFolder
				local newFolderName = parentFolder .. newFolderInput.textfieldstr[1]:gsub(" +$", "")
				add_replay_subfolder(newFolderName)
				newFolderOverlay:kill()
				SELECTED_FOLDER = { fullname = "replay/" .. newFolderName }
				echo(SELECTED_FOLDER.fullname)
				Replays:showMain(tbMenuCurrentSection)
			end)
	end
	
	function Replays:showUploadWindow(replayInfoView, replay)
		local uploadOverlay = UIElement:new({
			parent = tbMenuMain,
			pos = { 0, 0 },
			size = { tbMenuMain.size.w, tbMenuMain.size.h },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 }
		})
		local uploadView = UIElement:new({
			parent = uploadOverlay,
			pos = { uploadOverlay.size.w / 6, uploadOverlay.size.h / 5 },
			size = { uploadOverlay.size.w / 6 * 4, uploadOverlay.size.h / 5 * 3 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local uploadTitle = UIElement:new({
			parent = uploadView,
			pos = { 10, 0 },
			size = { uploadView.size.w - 20, uploadView.size.h / 8 }
		})
		local replayNameSize = 0.7
		while (not uploadTitle:uiText("Upload " .. replay.name ..  " to Toribash servers", nil, nil, FONTS.BIG, nil, replayNameSize, nil, nil, nil, nil, nil, true) and replayNameSize > 0.4) do
			replayNameSize = replayNameSize - 0.05
		end
		uploadTitle:addCustomDisplay(true, function()
				uploadTitle:uiText("Upload " .. replay.name ..  " to Toribash servers", nil, nil, FONTS.BIG, nil, replayNameSize, nil, nil, nil, nil, 0.2)
			end)
		
		local replayUploadInfoView = UIElement:new({
			parent = uploadView,
			pos = { 10, uploadTitle.size.h },
			size = { uploadView.size.w - 20, uploadView.size.h * 7 / 8 - uploadTitle.size.h }
		})
		
		local replayData = {
			{
				name = "Name",
				desc = "This will be the public replay name",
				value = { replay.name },
				input = false
			},
			{
				name = "Description",
				desc = "A short description for your replay",
				tip = "Input the description",
				value = { "" },
				input = true,
				fulltext = true
			},
			{
				name = "Tags",
				desc = "Space-separated tags for your replay",
				value = { string.gsub(replay.tags .. " " .. replay.hiddentags, "^ +", "") },
				tip = "Input replay tags",
				input = true
			}
		}
		
		
		posY, elementHeight = 0, 90
		for i,v in pairs(replayData) do
			local replayUploadInfoHolder = UIElement:new({
				parent = replayUploadInfoView,
				pos = { 0, posY },
				size = { replayUploadInfoView.size.w, elementHeight }
			})
			local replayUploadInfoNameTitle = UIElement:new({
				parent = replayUploadInfoHolder,
				pos = { 0, 0 },
				size = { replayUploadInfoHolder.size.w / 3, replayUploadInfoHolder.size.h / 3 }
			})
			replayUploadInfoNameTitle:addCustomDisplay(true, function()
					replayUploadInfoNameTitle:uiText(v.name, nil, nil, nil, LEFTBOT)
				end)
			local replayUploadInfoNameDesc = UIElement:new({
				parent = replayUploadInfoHolder,
				pos = { 0, replayUploadInfoNameTitle.size.h },
				size = { replayUploadInfoNameTitle.size.w, replayUploadInfoHolder.size.h - replayUploadInfoNameTitle.size.h }
			})
			replayUploadInfoNameDesc:addCustomDisplay(true, function()
					replayUploadInfoNameDesc:uiText(v.desc, nil, nil, 4, LEFT, 0.7)
				end)
			local replayUploadInfoDataField = UIElement:new({
				parent = replayUploadInfoHolder,
				pos = { replayUploadInfoHolder.size.w * 2 / 5, 0 },
				size = { replayUploadInfoHolder.size.w * 3 / 5, replayUploadInfoHolder.size.h }
			})
			local replayUploadInfoDataInputBG = UIElement:new({
				parent = replayUploadInfoDataField,
				pos = { 10, 10 },
				size = { replayUploadInfoDataField.size.w - 20, v.fulltext and replayUploadInfoDataField.size.h - 20 or 30 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			})
			if (v.input) then
				local replayUploadInfoDataInputOverlay = UIElement:new({
					parent = replayUploadInfoDataInputBG,
					pos = { 1, 1 },
					size = { replayUploadInfoDataInputBG.size.w - 2, replayUploadInfoDataInputBG.size.h - 2 },
					bgColor = { 1, 1, 1, 0.5 }
				})
				local replayUploadInfoDataInput = UIElement:new({
					parent = replayUploadInfoDataInputOverlay,
					pos = { 10, 5 },
					size = { replayUploadInfoDataInputOverlay.size.w - 20, replayUploadInfoDataInputOverlay.size.h - 10 },
					interactive = true,
					textfield = true,
					textfieldstr = v.value
				})
				replayUploadInfoDataInput:addMouseHandlers(function()
						TBMenu:enableMenuKeyboard(replayUploadInfoDataInput)
					end)
				TBMenu:displayTextfield(replayUploadInfoDataInput, FONTS.SMALL, nil, UICOLORBLACK, v.tip, v.fulltext and LEFT)
			else
				local replayUploadInfoData = UIElement:new({
					parent = replayUploadInfoDataInputBG,
					pos = { 1, 1 },
					size = { replayUploadInfoDataInputBG.size.w - 2, replayUploadInfoDataInputBG.size.h - 2 },
					bgColor = { 1, 1, 1, 0.3 }
				})
				local replayUploadInfoDataText = UIElement:new({
					parent = replayUploadInfoData,
					pos = { 10, 5 },
					size = { replayUploadInfoData.size.w - 20, replayUploadInfoData.size.h - 10 }
				})
				replayUploadInfoDataText:addCustomDisplay(true, function()
						replayUploadInfoDataText:uiText(v.value[1], nil, nil, 4, LEFTMID, 0.6, nil, nil, UICOLORBLACK)
					end)
			end
			
			posY = posY + elementHeight
		end
		
		local cancelButton = UIElement:new({
			parent = uploadView,
			pos = { 10, -uploadView.size.h / 8 },
			size = { uploadView.size.w / 2 - 15, uploadView.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		cancelButton:addCustomDisplay(false, function()
				cancelButton:uiText("Cancel")
			end)
		cancelButton:addMouseHandlers(nil, function()
				uploadOverlay:kill()
			end)
		local uploadButton = UIElement:new({
			parent = uploadView,
			pos = { uploadView.size.w / 2 + 5, -uploadView.size.h / 8 },
			size = { uploadView.size.w / 2 - 15, uploadView.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		uploadButton:addCustomDisplay(false, function()
				if (replayData[1].value[1] == "" or replayData[2].value[1] == "" or replayData[3].value[1] == "") then
					uploadButton:deactivate()
					uploadButton.bgColor = { 0, 0, 0, 0.1 }
				else
					uploadButton:activate()
					uploadButton.bgColor = { 0, 0, 0, 0.3 }
				end
				uploadButton:uiText("Upload")
			end)
		uploadButton:addMouseHandlers(nil, function()
				open_upload_replay(	"This will upload your replay\nto Toribash servers and make it available for everyone.\nContinue?",
									replayData[1].value[1],
									replayData[2].value[1],
									replayData[3].value[1],
									"replay/" .. replay.filename
								)
				local overlay = UIElement:new({
					pos = { 0, 0 },
					size = { WIN_W, WIN_H }
				})
				local left = UIElement:new({
					parent = overlay,
					pos = { 0, 0 },
					size = { overlay.size.w / 2, overlay.size.h },
					interactive = true
				})
				left:addMouseHandlers(nil, nil, function()
						overlay:kill()
					end)
				local right = UIElement:new({
					parent = overlay,
					pos = { overlay.size.w / 2, 0 },
					size = { overlay.size.w / 2, overlay.size.h },
					interactive = true
				})
				right:addMouseHandlers(nil, nil, function()
						overlay:kill()
						uploadOverlay:kill()
						Replays:showReplayInfo(replayInfoView, replay)
					end)
			end)
	end
	
	function Replays:showFolderDropdown(viewElement, folderdata)
		local entries = #folderdata.data
		local entryHeight = 30
		local dropdownHeight = entries * entryHeight
		local dropdownScrollable = false
		if (dropdownHeight > WIN_H / 2) then
			dropdownHeight = WIN_H / 2
			dropdownScrollable = true
		end
		
		local dropdownOverlay = UIElement:new({
			parent = tbMenuMain,
			pos = { 0, 0 },
			size = { WIN_W, WIN_H },
			interactive = true
		})		
		local dropdownView = UIElement:new({
			parent = viewElement,
			pos = { 0, -viewElement.size.h / 2 - dropdownHeight / 2 },
			size = { viewElement.size.w, dropdownHeight},
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		dropdownOverlay:addMouseHandlers(nil, function()
				dropdownOverlay:kill()
				dropdownView:kill()
			end)
		if (not dropdownScrollable) then
			for i,v in pairs(folderdata.data) do
				local folder = UIElement:new({
					parent = dropdownView,
					pos = { 0, (i - 1) * entryHeight },
					size = { dropdownView.size.w, entryHeight },
					interactive = true,
					bgColor = { 0, 0, 0, 0 },
					hoverColor = { 0, 0, 0, 0.2 },
					pressedColor = { 1, 1, 1, 0.2 }
				})
				local infoHolder = UIElement:new({
					parent = folder,
					pos = { (v.level - 1) / 2 * entryHeight, 0 },
					size = { folder.size.w - (v.level - 1) / 2 * entryHeight, folder.size.h }
				})
				local folderIcon = UIElement:new({
					parent = infoHolder,
					pos = { 0, 0 },
					size = { entryHeight, entryHeight },
					bgImage = "../textures/menu/general/folder.tga"
				})
				local folderText = UIElement:new({
					parent = infoHolder,
					pos = { entryHeight + 10, 0 },
					size = { infoHolder.size.w - entryHeight - 20, infoHolder.size.h }
				})
				folderText:addCustomDisplay(true, function()
						folderText:uiText(v.name, nil, nil, 4, LEFTMID, 0.6)
					end)
				folder:addMouseHandlers(nil, function()
						folderdata.value = v.fullname:gsub("^replay/", "")
						dropdownOverlay:kill()
						dropdownView:kill()
					end)
			end
		end
	end
	
	function Replays:showReplayManageWindow(replayInfoView, replay)
		local manageOverlay = UIElement:new({
			parent = tbMenuMain,
			pos = { 0, 0 },
			size = { tbMenuMain.size.w, tbMenuMain.size.h },
			interactive = true,
			bgColor = { 0, 0, 0, 0.4 }
		})
		local manageView = UIElement:new({
			parent = manageOverlay,
			pos = { manageOverlay.size.w / 6, manageOverlay.size.h / 2 - 130 },
			size = { manageOverlay.size.w / 6 * 4, 260 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local manageTitle = UIElement:new({
			parent = manageView,
			pos = { 10, 0 },
			size = { manageView.size.w - 20, 50 }
		})
		manageTitle:addAdaptedText(true, "Manage " .. replay.name .. " Replay", nil, nil, FONTS.BIG, nil, 0.7, nil, 0.2)
		local replayManageInfoView = UIElement:new({
			parent = manageView,
			pos = { 10, manageTitle.size.h },
			size = { manageView.size.w - 20, manageView.size.h * 7 / 8 - manageTitle.size.h }
		})
		
		
		local _, dirlevel = replay.filename:gsub("/", "")
		local replayData = {
			{
				name = "File Name",
				sysname = "filename",
				value = { replay.filename:gsub("^.*/", ""):gsub("%.rpl$", "") },
				input = true
			},
			{
				name = "Replay Name",
				sysname = "rpltitle",
				value = { replay.name },
				input = true
			},
			{
				name = "Replay Directory",
				sysname = "dir",
				dirlevel = dirlevel,
				value = dirlevel == 0 and "replay" or "replay/" .. replay.filename:gsub("/[^/]+$", ""),
				dropdown = true,
				data = Replays:getReplayFolders()
			}
		}
		
		
		posY, elementHeight = 0, 50
		for i,v in pairs(replayData) do
			local replayManageInfoHolder = UIElement:new({
				parent = replayManageInfoView,
				pos = { 0, posY },
				size = { replayManageInfoView.size.w, elementHeight }
			})
			local replayManageInfoNameTitle = UIElement:new({
				parent = replayManageInfoHolder,
				pos = { 0, 0 },
				size = { replayManageInfoHolder.size.w / 3, replayManageInfoHolder.size.h }
			})
			replayManageInfoNameTitle:addCustomDisplay(true, function()
					replayManageInfoNameTitle:uiText(v.name, nil, nil, nil, LEFTMID)
				end)
			local replayManageInfoDataField = UIElement:new({
				parent = replayManageInfoHolder,
				pos = { replayManageInfoHolder.size.w * 2 / 5, 0 },
				size = { replayManageInfoHolder.size.w * 3 / 5, replayManageInfoHolder.size.h }
			})
			if (v.input) then
				local replayManageInfoDataInputBG = UIElement:new({
					parent = replayManageInfoDataField,
					pos = { 10, 10 },
					size = { replayManageInfoDataField.size.w - 20, 30 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				local replayManageInfoDataInputOverlay = UIElement:new({
					parent = replayManageInfoDataInputBG,
					pos = { 1, 1 },
					size = { replayManageInfoDataInputBG.size.w - 2, replayManageInfoDataInputBG.size.h - 2 },
					bgColor = { 1, 1, 1, 0.5 }
				})
				local replayManageInfoDataInput = UIElement:new({
					parent = replayManageInfoDataInputOverlay,
					pos = { 10, 5 },
					size = { replayManageInfoDataInputOverlay.size.w - 20, replayManageInfoDataInputOverlay.size.h - 10 },
					interactive = true,
					textfield = true,
					textfieldstr = v.value
				})
				replayManageInfoDataInput:addMouseHandlers(function()
						TBMenu:enableMenuKeyboard(replayManageInfoDataInput)
					end)
				TBMenu:displayTextfield(replayManageInfoDataInput, FONTS.SMALL, nil, UICOLORBLACK, v.tip)
			elseif (v.dropdown) then
				local replayManageInfoDataDropdownButtonBG = UIElement:new({
					parent = replayManageInfoDataField,
					pos = { 10, 10 },
					size = { replayManageInfoDataField.size.w - 20, 30 },
					bgColor = { 0, 0, 0, 0.5}
				})
				local replayManageInfoDataDropdownButton = UIElement:new({
					parent = replayManageInfoDataDropdownButtonBG,
					pos = { 1, 1 },
					size = { replayManageInfoDataDropdownButtonBG.size.w - 2, replayManageInfoDataDropdownButtonBG.size.h - 2 },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
					pressedColor = { 1, 0.7, 0.7, 0.6 }
				})
				local replayManageInfoDataDropdownButtonText = UIElement:new({
					parent = replayManageInfoDataDropdownButton,
					pos = { 10, 0 },
					size = { replayManageInfoDataDropdownButton.size.w - 20, replayManageInfoDataDropdownButton.size.h }
				})
				replayManageInfoDataDropdownButtonText:addCustomDisplay(false, function()
						replayManageInfoDataDropdownButtonText:uiText(v.value, nil, nil, 4, LEFTMID, 0.7)
					end)
				replayManageInfoDataDropdownButton:addMouseHandlers(nil, function()
						Replays:showFolderDropdown(replayManageInfoDataDropdownButtonBG, v)
					end)
			end
			
			posY = posY + elementHeight
		end
		
		local cancelButton = UIElement:new({
			parent = manageView,
			pos = { 10, -50 },
			size = { manageView.size.w / 4 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		cancelButton:addCustomDisplay(false, function()
				cancelButton:uiText("Cancel")
			end)
		cancelButton:addMouseHandlers(nil, function()
				manageOverlay:kill()
			end)
		local saveButton = UIElement:new({
			parent = manageView,
			pos = { manageView.size.w / 4 + 5, -50 },
			size = { manageView.size.w / 2 - 10, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		saveButton:addCustomDisplay(false, function()
				saveButton:uiText("Update Replay")
			end)
		saveButton:addMouseHandlers(nil, function()
				local errors = 0
				local fileMove = false
				local newDirectory = nil
				local newReplay = cloneTable(replay)
				
				for i, v in pairs(tableReverse(replayData)) do
					if (v.sysname == "dir") then
						local directory = v.dirlevel == 0 and "replay" or "replay/" .. replay.filename:gsub("/.+$", "")
						if (directory ~= v.value) then
							fileMove = true
							newDirectory = v.value .. "/"
						end
					elseif (v.sysname == "rpltitle") then
						if (v.value[1] ~= replay.name) then
							newReplay.name = v.value[1]
						end
					elseif (v.sysname == "filename") then
						if (v.value[1] ~= replay.filename:gsub("^.*/", ""):gsub("%.rpl$", "") or fileMove) then
							local fileDirectory = replay.filename:find("/") and replay.filename:gsub("/.+$", "/") or "" 
							local newname = (newDirectory or fileDirectory) .. v.value[1] .. ".rpl"
							if (not fileMove) then
								echo("Attempting to change name: " .. replay.filename .. " to " .. newname)
								local result = rename_replay(replay.filename, newname)
								if (result) then
									errors = errors + 1
									echo("Replay rename error: " .. result)
								else
									newReplay.filename = newname
								end
							else
								local result = move_replay(replay.filename, newname)
								if (result) then
									errors = errors + 1
									echo("File move error: " .. result)
								else
									newReplay.filename = newname
									SELECTED_FOLDER = { fullname = "replay/" .. newDirectory:gsub("/$", "") }
								end
							end
						end
					end
				end
				if (errors == 0) then
					Replays:updateReplayCache(replay, newReplay)
					manageOverlay:kill()
					SELECTED_REPLAY.replay = newReplay
					Replays:showMain(tbMenuCurrentSection)
				end
			end)
			
		local deleteButton = UIElement:new({
			parent = manageView,
			pos = { manageView.size.w / 4 * 3 + 5, -50 },
			size = { manageView.size.w / 4 - 15, 40 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		deleteButton:addCustomDisplay(false, function()
				deleteButton:uiText("Delete")
			end)
		deleteButton:addMouseHandlers(nil, function()
				TBMenu:showConfirmationWindow("Are you sure want to delete " .. replay.filename .. " replay?", function()
						local result = delete_replay(replay.filename)
						if (result) then
							TBMenu:showDataError("Error deleting replay")
							return
						end
						manageOverlay:kill()
						Replays:updateReplayCache(replay, nil)
						SELECTED_REPLAY.replay = nil
						Replays:showMain(tbMenuCurrentSection)
					end)
			end)
	end
	
	function Replays:showReplayInfo(viewElement, replay)
		viewElement:kill(true)
		local bottomSmudge = TBMenu:addBottomBloodSmudge(viewElement, 2)
		
		SELECTED_REPLAY.replay = replay
		SELECTED_REPLAY.element.bgColor = { 1, 1, 1, 0.3 }
		
		local replayName = UIElement:new({
			parent = viewElement,
			pos = { 10, 0 },
			size = { viewElement.size.w - 20, viewElement.size.h / 8 }
		})
		local replayNameSize = 0.7
		while (not replayName:uiText(replay.name, nil, nil, FONTS.BIG, nil, replayNameSize, nil, nil, nil, nil, nil, true) and replayNameSize > 0.4) do
			replayNameSize = replayNameSize - 0.05
		end
		replayName:addCustomDisplay(true, function()
				replayName:uiText(replay.name, nil, nil, FONTS.BIG, nil, replayNameSize, nil, nil, nil, nil, 0.2)
			end)
		local replayAuthor = UIElement:new({
			parent = viewElement,
			pos = { 10, replayName.shift.y + replayName.size.h },
			size = { viewElement.size.w - 20, viewElement.size.h / 10 }
		})
		local replayAuthorStr = replay.author == "autosave" and "autosave" or "by " .. replay.author
		replayAuthor:addCustomDisplay(true, function()
				replayAuthor:uiText(replayAuthorStr, nil, nil, 4, nil, 0.8)
			end)
		local replayBouts = UIElement:new({
			parent = viewElement,
			pos = { 10, replayAuthor.shift.y + replayAuthor.size.h },
			size = { viewElement.size.w - 20, viewElement.size.h / 16 }
		})
		local replayBoutsStr = replay.bouts[1] ~= " " and replay.bouts[1] or "DATA CORRUPT"
		for i = 2, #replay.bouts do
			replayBoutsStr = replay.bouts[i] ~= " " and replayBoutsStr .. " vs " .. replay.bouts[i] or replayBoutsStr
		end
		local replayBoutsSize = 0.7
		while (not replayBouts:uiText("Players: " .. replayBoutsStr, nil, nil, 4, nil, replayBoutsSize, nil, nil, nil, nil, nil, true)) do
			replayBoutsSize = replayBoutsSize - 0.05
		end
		replayBouts:addCustomDisplay(true, function()
				replayBouts:uiText("Players: " .. replayBoutsStr, nil, nil, 4, LEFTBOT, replayBoutsSize)
			end)
		local replayMod = UIElement:new({
			parent = viewElement,
			pos = { 10, replayBouts.shift.y + replayBouts.size.h },
			size = { viewElement.size.w - 20, viewElement.size.h / 16 }
		})
		local replayModSize = 0.7
		while (not replayMod:uiText("Mod: " .. replay.mod, nil, nil, 4, nil, replayModSize, nil, nil, nil, nil, nil, true)) do
			replayModSize = replayModSize - 0.05
		end
		replayMod:addCustomDisplay(true, function()
				replayMod:uiText("Mod: " .. replay.mod, nil, nil, 4, LEFTMID, replayModSize)
			end)
		local replayTags = UIElement:new({
			parent = viewElement,
			pos = { 10, replayMod.shift.y + replayMod.size.h },
			size = { viewElement.size.w - 20, viewElement.size.h / 8 }
		})
		local tagsText = replay.tags == " " and "none" or replay.tags
		replayTags:addCustomDisplay(true, function()
				replayTags:uiText("Tags: " .. tagsText, nil, nil, 4, LEFT, 0.7)
			end)
			
		local tagsAdapted = textAdapt("Tags: " .. tagsText, 4, 0.7, viewElement.size.w - 20)
		local tagsDispositionX = get_string_length(tagsAdapted[#tagsAdapted], 4) * 0.7
		local tagsDispositionY = math.ceil((#tagsAdapted - 1) * 16.8) + 1
		if (tagsDispositionX + 10 > replayTags.size.w) then
			tagsDispositionX = 0
			tagsDispositionY = tagsDispositionY + 18
		end
		local replayTagsAdd = UIElement:new({
			parent = replayTags,
			pos = { tagsDispositionX, tagsDispositionY },
			size = { 18, 18 },
			shapeType = ROUNDED,
			rounded = 3,
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		replayTagsAdd:addCustomDisplay(false, function()
				set_color(1, 1, 1, 0.8)
				draw_quad(	replayTagsAdd.pos.x + replayTagsAdd.size.w / 2 - 1,
							replayTagsAdd.pos.y + 4,
							2,
							replayTagsAdd.size.h - 8	)
				draw_quad(	replayTagsAdd.pos.x + 4,
							replayTagsAdd.pos.y + replayTagsAdd.size.h / 2 - 1,
							replayTagsAdd.size.w - 8,
							2	)
			end)
		replayTagsAdd:addMouseHandlers(false, function()
				Replays:showTags(viewElement, replay)
			end)
		
		local replayViewButton = UIElement:new({
			parent = viewElement,
			pos = { 10, -viewElement.size.h / 8 * 3 },
			size = { viewElement.size.w - 20, viewElement.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.3 }
		})
		replayViewButton:addCustomDisplay(false, function()
				replayViewButton:uiText("View Replay")
			end)
		replayViewButton:addMouseHandlers(nil, function()
				Replays:playReplay(replay)
			end)
		local replayUploadButton = UIElement:new({
			parent = viewElement,
			pos = { 10, -viewElement.size.h / 8 * 2 },
			size = { viewElement.size.w - 20, viewElement.size.h / 10 },
			interactive = not replay.uploaded,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.3 }
		})
		replayUploadButton:addCustomDisplay(false, function()
				replayUploadButton:uiText("Upload Replay")
			end)
		replayUploadButton:addMouseHandlers(nil, function()
				Replays:showUploadWindow(viewElement, replay)
			end)
		local replayManageButton = UIElement:new({
			parent = viewElement,
			pos = { 10, -viewElement.size.h / 8 },
			size = { viewElement.size.w - 20, viewElement.size.h / 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 1, 1, 0.3 }
		})
		replayManageButton:addCustomDisplay(false, function()
				replayManageButton:uiText("Manage Replay")
			end)
		replayManageButton:addMouseHandlers(nil, function()
				Replays:showReplayManageWindow(viewElement, replay)
			end)
	end
	
	function Replays:showMain(viewElement)
		viewElement:kill(true)
		Replays:getReplayFiles()
		SELECTED_REPLAY.element = nil
		SELECTED_REPLAY.defaultcolor = nil
		
		local replaysList = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.75 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local replayInfo = UIElement:new({
			parent = viewElement,
			pos = { replaysList.size.w + 15, 0 },
			size = { viewElement.size.w * 0.25 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Replays:showList(replaysList, replayInfo, SELECTED_FOLDER)
	end
	
end