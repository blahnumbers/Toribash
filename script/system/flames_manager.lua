if (Flames == nil) then
	local _, top_y = get_window_safe_size()

	---**Flames Manager Class**
	---
	---**Version 5.74**
	---* Code style updates and EmmyLua annotations
	---* Fix bug with negative flame values not always being handled correctly
	---@class Flames
	---@field MainElement UIElement|nil
	Flames = {
		MODE_FORGER = 0,
		MODE_BROWSER = 1,
		MODE_BROWSER_STORED = 2,
		MainElement = nil,
		ActiveMode = 0,
		DisplayPos = { x = SAFE_X + 10, y = top_y + 10 },
		ListShift = { 0, 0, 1 },
		UserData = { },
		BrowserInfo = { },
		Parameters = { },
		SearchData = nil,
		DialogId = 120,
		CurrentFlameId = 0,
		IsMinimized = false,
		ver = 5.74
	}
	Flames.__index = Flames
end

---**Flames internal utility class**
local FlamesInternal = {}

---@class FlameBrowserInfoBit
---@field title string
---@field val string

---@class FlameBrowserData
---@field settings integer[]
---@field displayInfo FlameBrowserInfoBit[]
---@field id integer

---@param response string
---@param flameId integer
---@return FlameBrowserData
function FlamesInternal.ParseFlameBrowserData(response, flameId)
	---@type FlameBrowserData
	local flameData = {
		settings = {},
		displayInfo = {},
		id = flameId
	}
	for line in string.gmatch(response, "[^\n]*") do
		if (line:match("^FLAME;.*")) then
			for param in string.gmatch(line, "-?%w+") do
				table.insert(flameData.settings, tonumber(param))
			end
		elseif (line:match("^FLAMENAME;.*")) then
			local name = line:gsub("^FLAMENAME;", "")
			table.insert(flameData.displayInfo, { title = TB_MENU_LOCALIZED.FLAMESFLAMENAME, val = name })
		elseif (line:match("^FLAMEFORGED;.*")) then
			line = line:gsub("^FLAMEFORGED;", "")
			local data = {}
			for val in string.gmatch(line, "%w+") do
				table.insert(data, val)
			end
			table.insert(flameData.displayInfo, { title = TB_MENU_LOCALIZED.STOREFLAMEFORGEDBY, val = data[1] })
			table.insert(flameData.displayInfo, { title = TB_MENU_LOCALIZED.FLAMESSPAWNCOST, val = numberFormat(data[2]) .. " TC" })
		elseif (line:match("^FLAMEDATE;.*")) then
			local date = line:gsub("^FLAMEDATE;", "")
			table.insert(flameData.displayInfo, { title = TB_MENU_LOCALIZED.FLAMESFORGEDATE, val = date })
		elseif (line:match("^FLAMEOWNER;.*")) then
			local name = line:gsub("^FLAMEOWNER;", "")
			table.insert(flameData.displayInfo, { title = TB_MENU_LOCALIZED.FLAMESOWNER, val = name })
		end
	end

	return flameData
end

---Caches current flame settings to `Flames.UserData`
function Flames.GetCurrentFlames()
	-- Read their item.dat first
	-- If we fail to fetch data, load playerid 0 flames
	local custom = Files.Open("../custom/" .. TB_MENU_PLAYER_INFO.username .. "/item.dat")
	local settings = {}
	if (custom.data) then
		local flameid = 0
		local customLines = custom:readAll()
		custom:close()
		for _, line in pairs(customLines) do
			if (line:find("^FLAME")) then
				line = line:gsub("^FLAME%d %d; ", "")

				settings[flameid] = {}
				local paramid = 0
				for param in string.gmatch(line, "-?%d+") do
					settings[flameid][paramid] = tonumber(param)
					paramid = paramid + 1
				end

				flameid = flameid + 1
			end
		end
	end

	for flameid = 0, 4 do
		Flames.UserData[flameid] = { }
		local empty = true
		for id = 0, 52 do
			Flames.UserData[flameid][id] = settings[flameid] and settings[flameid][id] or get_flame_setting(0, flameid, id)
			if (empty and Flames.UserData[flameid][id] ~= 0) then
				empty = false
			end
		end
		Flames.UserData[flameid].empty = empty
	end
end


function Flames.ResetPlayerFlames()
	for flameid,flame in pairs(Flames.UserData) do
		for id, val in pairs(flame) do
			if (type(id) == "number") then
				set_flame_setting(id, val, flameid)
			end
		end
	end
end

function Flames:getFlameGroups()
	return {
		{ name = TB_MENU_LOCALIZED.FLAMESSECTIONGENERAL, ids = { 1, 2, 3, 4, 5 } },
		{ name = TB_MENU_LOCALIZED.FLAMESSECTIONCOLOR, ids = { 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 } },
		{ name = TB_MENU_LOCALIZED.FLAMESSECTIONSIZE, ids = { 17, 18, 19, 20, 21, 22, 23, 24, 25, 26 } },
		{ name = TB_MENU_LOCALIZED.FLAMESSECTIONGRAVITYDISPLACEMENT, ids = { 32, 33, 34, 53, 35, 36, 37, 38, 31, 27, 28, 29, 30 } },
		{ name = TB_MENU_LOCALIZED.FLAMESSECTIONADVANCED, ids = { 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52 } }
	}
end

function Flames:getFlameCostEstimate(flame)
	local cost = 15000 +
		math.abs(flame[4].value) * 20000 +																				-- Blend
		math.abs(flame[10].value / 255) * 10000 +																		-- Color Random
		(math.abs(flame[15].value / 255) * 10000 +																		-- Color Target Random
		math.abs((flame[6].value - flame[11].value) / 255) * 2500 +														-- Color R Diff
		math.abs((flame[7].value - flame[12].value) / 255) * 2500 +														-- Color G Diff
		math.abs((flame[8].value - flame[13].value) / 255) * 2500) * (math.abs(flame[16].value) > 0 and 1 or 0) +		-- Color B Diff
		math.abs(flame[18].value / 100) * 5000 +																		-- Age Limit
		math.abs(flame[21].value / 100) * 30000 +																		-- Emit Amount
		math.abs(flame[22].value / 100) * 10000 +																		-- Size
		(math.abs(flame[22].value - flame[24].value) / 100) * (math.abs(flame[25].value) > 0 and 1 or 0) * 10000 +		-- Size Diff
		math.abs(((flame[23].value + flame[26].value * (math.abs(flame[25].value) > 0 and 1 or 0)) / 100)) * 5000 +		-- Size Random
		math.abs(flame[27].value / 100) * 2500 +																		-- Displace X
		math.abs(flame[28].value / 100) * 2500 + 																		-- Displace Y
		math.abs(flame[29].value / 100) * 2500 +																		-- Displace Z
		math.abs(flame[30].value / 100) * 5000 +																		-- Displace Random
		math.abs(flame[32].value) * 100 +																				-- Gravity X
		math.abs(flame[33].value) * 100 +																				-- Gravity Y
		math.abs(flame[34].value - 30) * 100 +																			-- Gravity Z
		math.abs(flame[35].value) * 100 +																				-- Velocity X
		math.abs(flame[36].value) * 100 +																				-- Velocity Y
		math.abs(flame[37].value) * 100 +																				-- Velocity Z
		math.abs(flame[38].value / 100) * 5000 +																		-- Velocity Random
		math.abs(flame[39].value) * 10000 +																				-- Orbit
		math.abs(flame[43].value) * 10000 +																				-- Gravitate
		math.abs(flame[47].value) * 10000 +																				-- Follow
		math.abs(flame[50].value) * 10000																				-- Sink
	return math.floor(cost / 100) * 100
end

function Flames.Quit()
	if (Flames.MainElement ~= nil) then
		Flames.MainElement:kill()
		Flames.MainElement = nil
	end
	Flames.ResetPlayerFlames()
end

function Flames.Minimize()
	if (Flames.MainElement) then
		Flames.MainElement:kill()
		Flames.MainElement = nil
	end
	Flames.IsMinimized = true
end

function Flames:getFlameParameters()
	return {
		{ name = "FLAME_BODYPART", min = 0, max = 20 },
		{ name = "FLAME_TIMESTEP", value = math.random(30, 100), min = 0, max = 100 },
		{ name = "FLAME_DAMPING", value = 100, min = 0, max = 100 },
		{ name = "FLAME_BLEND", value = 0, toggle = true, hasDependency = true },
		{ name = "FLAME_SINK", value = 1, toggle = true },
		{ name = "FLAME_COLOR_R", min = 0, max = 255 },
		{ name = "FLAME_COLOR_G", min = 0, max = 255 },
		{ name = "FLAME_COLOR_B", min = 0, max = 255 },
		{ name = "FLAME_COLOR_A", min = 0, max = 255 },
		{ name = "FLAME_COLOR_RANDOM", value = 0, min = 0, max = 255 },
		{ name = "FLAME_TARGET_COLOR_R", min = 0, max = 255 },
		{ name = "FLAME_TARGET_COLOR_G", min = 0, max = 255 },
		{ name = "FLAME_TARGET_COLOR_B", min = 0, max = 255 },
		{ name = "FLAME_TARGET_COLOR_A", min = 0, max = 255 },
		{ name = "FLAME_TARGET_COLOR_RANDOM", value = 0, min = 0, max = 255 },
		{ name = "FLAME_TARGET_COLOR_SCALE", value = 30, min = 0, max = 100 },
		{ name = "FLAME_AGE_START", value = 0, min = 0, max = 100 },
		{ name = "FLAME_AGE_LIMIT", value = 60, min = 0, max = 100 },
		{ name = "FLAME_AGE_SIGMA", value = 0, min = 0, max = 200 },
		{ name = "FLAME_EMIT_SCALE", value = 20, min = 0, max = 100 },
		{ name = "FLAME_EMIT_AMOUNT", value = 25, min = 0, max = 100 },
		{ name = "FLAME_SIZE", value = 20, min = 0, max = 100 },
		{ name = "FLAME_SIZE_RANDOM", value = 0, min = 0, max = 100 },
		{ name = "FLAME_TARGET_SIZE", value = 10, min = 0, max = 100 },
		{ name = "FLAME_TARGET_SIZE_SCALE", value = 0, min = 0, max = 100 },
		{ name = "FLAME_TARGET_SIZE_RANDOM", value = 10, min = 0, max = 100 },
		{ name = "FLAME_RANDOM_DISPLACE_X", value = 0, min = 0, max = 100 },
		{ name = "FLAME_RANDOM_DISPLACE_Y", value = 0, min = 0, max = 100 },
		{ name = "FLAME_RANDOM_DISPLACE_Z", value = 0, min = 0, max = 100 },
		{ name = "FLAME_DISPLACE_RANDOM", value = 0, min = 0, max = 100 },
		{ name = "FLAME_RELATIVE_VELOCITY", value = 1, toggle = true },
		{ name = "FLAME_GRAVITY_X", value = 0, min = -100, max = 100 },
		{ name = "FLAME_GRAVITY_Y", value = 0, min = -100, max = 100 },
		{ name = "FLAME_GRAVITY_Z", value = 25, min = -100, max = 100 },
		{ name = "FLAME_VELOCITY_X", value = 0, min = -100, max = 100 },
		{ name = "FLAME_VELOCITY_Y", value = 0, min = -100, max = 100 },
		{ name = "FLAME_VELOCITY_Z", value = 0, min = -100, max = 100 },
		{ name = "FLAME_VELOCITY_RANDOM", value = 0, min = 0, max = 100 },
		{ name = "FLAME_ORBIT", value = 0, toggle = true, hasDependency = true },
		{ name = "FLAME_ORBIT_BODYPART", value = 0, depends = 39, min = 0, max = 20	},
		{ name = "FLAME_ORBIT_MAGNITUDE", value = 0, depends = 39, min = 0, max = 100 },
		{ name = "FLAME_ORBIT_EPSILON", value = 0, depends = 39, min = 0, max = 100 },
		{ name = "FLAME_GRAVITATE", value = 0, toggle = true, hasDependency = true },
		{ name = "FLAME_GRAVITATE_MAGNITUDE", value = 0, depends = 43, min = 0, max = 100 },
		{ name = "FLAME_GRAVITATE_EPSILON", value = 0, depends = 43, min = 0, max = 100 },
		{ name = "FLAME_GRAVITATE_MAX_RADIUS", value = 0, depends = 43, min = 0, max = 100 },
		{ name = "FLAME_FOLLOW", value = 0, toggle = true, hasDependency = true },
		{ name = "FLAME_FOLLOW_MAGNITUDE", value = 0, depends = 47, min = 0, max = 100 },
		{ name = "FLAME_FOLLOW_EPSILON", value = 0, depends = 47, min = 0, max = 100 },
		{ name = "FLAME_SINK_BODY", value = 0, toggle = true, hasDependency = true },
		{ name = "FLAME_SINK_BODY_BODYPART", value = 0, depends = 50, min = 0, max = 20 },
		{ name = "FLAME_SINK_BODY_RADIUS", value = 0, depends = 50, min = 0, max = 100 },
		{ name = "FLAME_RELATIVE_GRAVITY", value = 0, toggle = true }
	}
end

function Flames:checkFlamesParametersGenerated(flamesData)
	local flameParameters
	if (flamesData) then
		flameParameters = flamesData
	else
		flameParameters = table.clone(Flames.UserData)
		for i,flame in pairs(flameParameters) do
			flameParameters[i] = Flames:getFlameParameters()
			if (not flame.empty) then
				for id,v in pairs(flameParameters[i]) do
					flameParameters[i][id].value = flame[id - 1] or flameParameters[i][id].value
				end
			end
		end
	end
	return flameParameters
end

function Flames:spawnFlameSettings(listingHolder, toReload, elementHeight, flamesData, flameId)
	Flames.ActiveMode = Flames.MODE_FORGER
	local flameId = flameId or 0
	Flames.CurrentFlameId = flameId
	local flameParameters = Flames:checkFlamesParametersGenerated(flamesData)

	local targetListShift = listingHolder.shift.y < 0 and -listingHolder.shift.y or listingHolder.size.h
	targetListShift = targetListShift - listingHolder.size.h

	if (toReload.browserButtons and toReload.forgerButtons) then
		for _, v in pairs(toReload.browserButtons) do
			v:hide(true)
		end
		for _, v in pairs(toReload.browserStoredButtons) do
			v:hide(true)
		end
		for _, v in pairs(toReload.forgerButtons) do
			v:show(true)
		end
	end

	if (listingHolder.scrollBar) then
		listingHolder.scrollBar:kill()
	end
	listingHolder:kill(true)
	listingHolder:moveTo(nil, 0)
	toReload.menuTitle:addAdaptedText(true, TB_MENU_LOCALIZED.FLAMESFORGERTITLE, nil, nil, FONTS.BIG, LEFTMID, 0.6)

	local listElements = {}
	local nameWidth = listingHolder.size.w / 3 > 180 and 180 or listingHolder.size.w / 3
	local flameGroups = Flames:getFlameGroups()
	for _, group in pairs(flameGroups) do
		local groupHolder = UIElement:new({
			parent = listingHolder,
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		table.insert(listElements, groupHolder)
		local groupName = UIElement:new({
			parent = groupHolder,
			pos = { 20, 3 },
			size = { groupHolder.size.w - 40, groupHolder.size.h - 6 }
		})
		groupName:addAdaptedText(true, group.name, nil, nil, FONTS.BIG, LEFTMID, 0.5)
		for _, i in pairs(group.ids) do
			local param = flameParameters[flameId][i]
			param.value = param.value or math.random(param.min, param.max)
			local xShift = param.depends and 10 or 0
			if (not param.depends or flameParameters[flameId][param.depends].value == 1) then
				param.name = param.name:gsub("FLAME_", ""):gsub("_", " ")
				local paramHolder = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight },
					bgColor = TB_MENU_DEFAULT_BG_COLOR
				})
				table.insert(listElements, paramHolder)
				local pHolder = UIElement:new({
					parent = paramHolder,
					pos = { 10, 2 },
					size = { paramHolder.size.w - 10, paramHolder.size.h - 4 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
					shapeType = ROUNDED,
					rounded = 3
				})
				local pName = UIElement:new({
					parent = pHolder,
					pos = { xShift + 10, 5 },
					size = { nameWidth - xShift, pHolder.size.h - 10 }
				})

				local pValueHolder = UIElement:new({
					parent = pHolder,
					pos = { xShift + pName.size.w + pName.shift.x + 5, 3 },
					size = { pHolder.size.w - pName.size.w - pName.shift.x * 2 - 5, pHolder.size.h - 6 },
					shapeType = ROUNDED,
					rounded = 3
				})

				if (param.toggle) then
					local pToggle = TBMenu:spawnToggle(pValueHolder, -pValueHolder.size.h, nil, nil, nil, param.value, function(val)
							param.value = val
							set_flame_setting(i - 1, param.value, flameId)
							toReload.costDisplay.tc = Flames:getFlameCostEstimate(flameParameters[flameId])
							toReload.costDisplay:addAdaptedText(true, TB_MENU_LOCALIZED.FLAMESPRICEESTIMATE .. ": " .. toReload.costDisplay.tc .. " TC", nil, nil, nil, LEFTMID)
							if (param.hasDependency) then
								Flames:spawnFlameSettings(listingHolder, toReload, elementHeight, flameParameters, flameId)
							end
						end)
				else
					local paramSettings = {
						maxValue = param.max or 100,
						minValue = param.min or 0,
						boundParent = listingHolder.parent
					}
					local updateFunc = function(_, _, slider)
						param.value = tonumber(slider.label.labelText[1])
						set_flame_setting(i - 1, param.value, flameId)
						toReload.costDisplay.tc = Flames:getFlameCostEstimate(flameParameters[flameId])
						toReload.costDisplay:addAdaptedText(true, TB_MENU_LOCALIZED.FLAMESPRICEESTIMATE .. ": " .. toReload.costDisplay.tc .. " TC", nil, nil, nil, LEFTMID)
						if (in_array(i, { 1, 40, 51 })) then
							local bodyName = '?'
							for bodyPart,v in pairs(BODYPARTS) do
								if (tonumber(v) == tonumber(slider.label.labelText[1])) then
									bodyName = bodyPart:gsub("^(L_)", "LEFT "):gsub("^(R_)", "RIGHT ")
								end
							end
							slider.label.labelText[1] = bodyName
						end
					end
					TBMenu:spawnSlider2(pValueHolder, nil, param.value, paramSettings, updateFunc)
				end
				set_flame_setting(i - 1, param.value, flameId)
				pName:addAdaptedText(true, param.name, nil, nil, nil, LEFTMID, xShift > 0 and 0.75 or 0.9)
			end
		end
	end
	toReload.costDisplay.tc = Flames:getFlameCostEstimate(flameParameters[flameId])
	toReload.costDisplay:addAdaptedText(true, TB_MENU_LOCALIZED.FLAMESPRICEESTIMATE .. ": " .. toReload.costDisplay.tc .. " TC", nil, nil, nil, LEFTMID)

	for i,v in pairs(listElements) do
		v:hide()
	end

	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar

	-- Set shift for collapsible sections
	Flames.ListShift[2] = #listElements * elementHeight
	targetListShift = targetListShift > Flames.ListShift[2] - listingHolder.size.h and Flames.ListShift[2] - listingHolder.size.h or targetListShift
	Flames.ListShift[3] = scrollBar.parent.size.h - scrollBar.size.h
	Flames.ListShift[1] = targetListShift / (Flames.ListShift[2] - listingHolder.size.h) * Flames.ListShift[3]

	scrollBar:makeScrollBar(listingHolder, listElements, toReload, Flames.ListShift)

	return flameParameters
end

function Flames:spawnBrowseMenuStored(listingHolder, toReload, elementHeight, flamesData, flameId, previewFlames)
	Flames.ActiveMode = Flames.MODE_BROWSER_STORED
	local flameId = flameId or 0
	Flames.CurrentFlameId = flameId
	local previewFlames = previewFlames or Flames.BrowserInfo
	local previewFlame = previewFlames[flameId]

	if (toReload.browserButtons and toReload.forgerButtons) then
		for i,v in pairs(toReload.forgerButtons) do
			v:hide(true)
		end
		for i,v in pairs(toReload.browserButtons) do
			v:hide(true)
		end
		for i,v in pairs(toReload.browserStoredButtons) do
			v:show(true)
		end
	end

	if (listingHolder.scrollBar) then
		listingHolder.scrollBar:kill()
	end
	listingHolder:kill(true)
	listingHolder:moveTo(nil, 0)
	toReload.menuTitle:addAdaptedText(true, TB_MENU_LOCALIZED.FLAMESSTOREDFLAMES, nil, nil, FONTS.BIG, LEFTMID, 0.6)

	local listElements = {}
	local storedFlames = {}

	local storedFile = Files.Open("../data/flames_stored.dat")
	if (storedFile.data) then
		local data = storedFile:readAll()
		storedFile:close()
		local errors = 0
		for i, line in pairs(data) do
			if (line:match("^FLAME ([^;]+);[%d ]+")) then
				local res = pcall(function()
					local flame = { params = {}, id = i, str = line }
					local flameName = line:gsub("^FLAME ([^;]+).*", "%1")
					flame.name = flameName
					local paramsLine = line:gsub("^FLAME [^;]+;", "")
					for param in string.gmatch(paramsLine, "%-?%d+") do
						table.insert(flame.params, tonumber(param))
					end
					table.insert(storedFlames, flame)
				end)
				if (res == false) then
					errors = errors + 1
				end
			end
		end
		if (errors > 0) then
			local errorString = utf8.gsub(TB_MENU_LOCALIZED.FLAMESSTOREDERRORLOADING, "%%d", errors)
			TBMenu:showStatusMessage(errorString)
		end
	end

	for _, flame in pairs(storedFlames) do
		local flameHolder = UIElement:new({
			parent = listingHolder,
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		table.insert(listElements, flameHolder)
		local flameNameHolder = UIElement:new({
			parent = flameHolder,
			pos = { 10, 2 },
			size = { flameHolder.size.w - 10 - elementHeight, flameHolder.size.h - 4 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 3
		})
		flameNameHolder:addMouseHandlers(nil, function()
				local flameParameters = Flames:checkFlamesParametersGenerated(flamesData)
				for i,v in pairs(flameParameters[Flames.CurrentFlameId]) do
					flameParameters[Flames.CurrentFlameId][i].value = flame.params[i]
				end
				Flames:spawnFlameSettings(listingHolder, toReload, elementHeight, flameParameters, Flames.CurrentFlameId)
			end)
		local flameDeleteButton = UIElement:new({
			parent = flameHolder,
			pos = { -flameNameHolder.size.h, flameNameHolder.shift.y },
			size = { flameNameHolder.size.h, flameNameHolder.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 3,
			bgImage = "../textures/menu/general/buttons/trash.tga"
		})
		flameDeleteButton:addMouseHandlers(nil, function()
			local confirmOverlay = TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.FLAMESDELETESTOREDCONFIRM .. " (" .. flame.name .. ")?\n" .. TB_MENU_LOCALIZED.CONFIRMACTIONCANNOTBEUNDONE, function()
				local flamesStoredFile = Files.Open("../data/flames_stored.dat", FILES_MODE_WRITE)
				if (not flamesStoredFile.data) then
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.FLAMESERROROPENINGSTORAGE)
					return
				end
				for k,v in pairs(storedFlames) do
					if (v.id ~= flame.id) then
						flamesStoredFile:writeLine(v.str)
					end
				end
				flamesStoredFile:close()
				Flames:spawnBrowseMenuStored(listingHolder, toReload, elementHeight, flamesData, flameId, previewFlames)
			end, nil, nil, nil, TB_MENU_HUB_GLOBALID)
			end)
		local flameName = UIElement:new({
			parent = flameNameHolder,
			pos = { 10, 5 },
			size = { (flameNameHolder.size.w - 20) / 3 * 2, flameNameHolder.size.h - 10 }
		})
		flameName:addAdaptedText(true, flame.name, nil, nil, nil, LEFTMID, 0.8)

		local flameBodypart = UIElement:new({
			parent = flameNameHolder,
			pos = { flameName.shift.x + flameName.size.w, flameName.shift.y },
			size = { flameNameHolder.size.w - flameName.shift.x * 2 - flameName.size.w, flameName.size.h }
		})
		local bodyName = ""
		for bodyPart,v in pairs(BODYPARTS) do
			if (flame.params[1] == v) then
				bodyName = bodyPart:gsub("^(L_)", "LEFT "):gsub("^(R_)", "RIGHT "):gsub("%u", function(a) return a:lower() end)
			end
		end
		flameBodypart:addAdaptedText(true, TB_MENU_LOCALIZED.FLAMESBODYPARTFOR .. " " .. bodyName, nil, nil, 4, RIGHTMID, 0.7)
	end

	for _, v in pairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar
	scrollBar:makeScrollBar(listingHolder, listElements, toReload)
end

function Flames:spawnBrowseMenu(listingHolder, toReload, elementHeight, flamesData, flameId, previewFlames, searchFlames)
	Flames.ActiveMode = Flames.MODE_BROWSER
	flameId = flameId or 0
	previewFlames = previewFlames or Flames.BrowserInfo
	searchFlames = searchFlames or Flames.SearchData
	Flames.CurrentFlameId = flameId

	local previewFlame = previewFlames[flameId]

	if (toReload.browserButtons and toReload.forgerButtons) then
		for _, v in pairs(toReload.forgerButtons) do
			v:hide(true)
		end
		for _, v in pairs(toReload.browserStoredButtons) do
			v:hide(true)
		end
		for _, v in pairs(toReload.browserButtons) do
			v:show(true)
		end
	end

	if (listingHolder.scrollBar) then
		listingHolder.scrollBar:kill()
	end
	listingHolder:kill(true)
	listingHolder:moveTo(nil, 0)
	toReload.menuTitle:addAdaptedText(true, TB_MENU_LOCALIZED.FLAMESBROWSERTITLE, nil, nil, FONTS.BIG, LEFTMID, 0.6)

	local listElements = {}

	local flameIdLoader = UIElement:new({
		parent = listingHolder,
		pos = { 0, #listElements * elementHeight },
		size = { listingHolder.size.w, elementHeight },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	table.insert(listElements, flameIdLoader)
	local flameIdLoaderHolder = UIElement:new({
		parent = flameIdLoader,
		pos = { 10, 2 },
		size = { flameIdLoader.size.w - 10, flameIdLoader.size.h - 4 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = ROUNDED,
		rounded = 3
	})
	local flameIdLoaderName = UIElement:new({
		parent = flameIdLoaderHolder,
		pos = { 10, 5 },
		size = { flameIdLoaderHolder.size.w / 3, flameIdLoaderHolder.size.h - 10 }
	})
	flameIdLoaderName:addAdaptedText(true, TB_MENU_LOCALIZED.STOREFLAMEID, nil, nil, nil, LEFTMID)
	local flameIdLoaderInput = TBMenu:spawnTextField2(flameIdLoaderHolder, {
		x = flameIdLoaderName.size.w + flameIdLoaderName.shift.x + 5,
		y = 3,
		w = flameIdLoaderHolder.size.w - flameIdLoaderName.size.w - flameIdLoaderName.shift.x * 2 - 5,
		h = flameIdLoaderHolder.size.h - 6
	}, previewFlame and previewFlame.id, TB_MENU_LOCALIZED.STOREFLAMEID, {
		isNumeric = true,
		fontId = 4,
		textScale = 0.7,
		textColor = UICOLORWHITE,
		textAlign = CENTERMID,
		darkerMode = true
	})
	flameIdLoaderInput:addEnterAction(function()
			local flameLoaderOverlay = flameIdLoader:addChild({
				shift = { 10, 5 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				uiColor = UICOLORWHITE,
				shapeType = ROUNDED,
				rounded = 3,
				interactive = true
			})
			TBMenu:displayLoadingMarkSmall(flameLoaderOverlay, TB_MENU_LOCALIZED.NETWORKLOADING)
			UIElement.handleMouseDn(0, -1, 0)

			local flameSystemId = tonumber(flameIdLoaderInput.textfieldstr[1]) or 0
			Request:queue(function()
					download_server_info("flame_fetch_settings&flameid=" .. flameSystemId)
				end,
				"flameidfetch",
				function() -- Success
					flameLoaderOverlay:kill()
					local response = get_network_response()
					if (response:find("^ERROR;")) then
						response = response:gsub("^ERROR;", "")
						TBMenu:showStatusMessage(response)
						return
					end

					previewFlames[flameId] = FlamesInternal.ParseFlameBrowserData(response, flameSystemId)
					Flames.SearchData = nil
					Flames:spawnBrowseMenu(listingHolder, toReload, elementHeight, flamesData, flameId, previewFlames)
				end,
				function() -- Error
					flameLoaderOverlay:kill()
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORTRYAGAIN)
				end)
		end)

	if (previewFlame) then
		for i, v in pairs(previewFlame.settings) do
			set_flame_setting(i - 1, v, flameId)
		end
		for _, data in pairs(previewFlame.displayInfo) do
			local fHolderMain = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listElements * elementHeight },
				size = { listingHolder.size.w, elementHeight },
				bgColor = TB_MENU_DEFAULT_BG_COLOR
			})
			table.insert(listElements, fHolderMain)
			local fHolder = UIElement:new({
				parent = fHolderMain,
				pos = { 10, 2 },
				size = { fHolderMain.size.w - 10, fHolderMain.size.h - 4 },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
				shapeType = ROUNDED,
				rounded = 3
			})
			local fParamName = UIElement:new({
				parent = fHolder,
				pos = { 10, 5 },
				size = { fHolder.size.w / 2 - 20, fHolder.size.h - 10 }
			})
			fParamName:addAdaptedText(false, data.title, nil, nil, nil, LEFTMID)
			local fValueHolder = UIElement:new({
				parent = fHolder,
				pos = { fParamName.size.w + fParamName.shift.x + 5, 2 },
				size = { fHolder.size.w - fParamName.size.w - fParamName.shift.x * 2 - 5, fHolder.size.h - 4 },
				shapeType = ROUNDED,
				rounded = 3
			})
			fValueHolder:addAdaptedText(false, data.val, nil, nil, 4, nil, 0.8)
		end
	end

	if (searchFlames) then
		local fSeparator = UIElement:new({
			parent = listingHolder,
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		table.insert(listElements, fSeparator)

		local fHolderMain = UIElement:new({
			parent = listingHolder,
			pos = { 0, #listElements * elementHeight },
			size = { listingHolder.size.w, elementHeight },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		table.insert(listElements, fHolderMain)
		local fSearchTitle = UIElement:new({
			parent = fHolderMain,
			pos = { 10, 2 },
			size = { fHolderMain.size.w - 10, fHolderMain.size.h - 4 },
		})
		fSearchTitle:addAdaptedText(true, TB_MENU_LOCALIZED.FLAMESSEARCHRESULTS .. " \"" .. searchFlames.query .. "\":", nil, nil, nil, LEFTMID)

		for i,section in pairs(searchFlames) do
			if (type(section) == "table") then
				local forgedShown, ownedShown = false, false
				if (#section.flames > 0) then
					local fHolderMain = UIElement:new({
						parent = listingHolder,
						pos = { 0, #listElements * elementHeight },
						size = { listingHolder.size.w, elementHeight },
						bgColor = TB_MENU_DEFAULT_BG_COLOR
					})
					table.insert(listElements, fHolderMain)
					local fHolder = UIElement:new({
						parent = fHolderMain,
						pos = { 10, 2 },
						size = { fHolderMain.size.w - 10, fHolderMain.size.h - 4 }
					})
					if (section.name == "name") then
						fHolder:addAdaptedText(true, "- " .. TB_MENU_LOCALIZED.FLAMESSEARCHNAME1 .. " \"" .. searchFlames.query .. "\" " .. TB_MENU_LOCALIZED.FLAMESSEARCHNAME2 .. ":", 10, nil, nil, LEFTMID)
					elseif (section.name == "forger") then
						forgedShown = true
						fHolder:addAdaptedText(true, "- " .. TB_MENU_LOCALIZED.FLAMESSEARCHFORGER .. " " .. searchFlames.query .. ":", 10, nil, nil, LEFTMID)
					elseif (section.name == "owner") then
						ownedShown = true
						fHolder:addAdaptedText(true, "- " .. TB_MENU_LOCALIZED.FLAMESSEARCHOWNER .. " " .. searchFlames.query .. ":", 10, nil, nil, LEFTMID)
					end
				end
				for i,v in pairs(section.flames) do
					local fHolderMain = UIElement:new({
						parent = listingHolder,
						pos = { 0, #listElements * elementHeight },
						size = { listingHolder.size.w, elementHeight },
						bgColor = TB_MENU_DEFAULT_BG_COLOR
					})
					table.insert(listElements, fHolderMain)
					local selected = previewFlame and previewFlame.id == v.id or false
					local fHolder = UIElement:new({
						parent = fHolderMain,
						pos = { 10, 2 },
						size = { fHolderMain.size.w - 10, fHolderMain.size.h - 4 },
						shapeType = ROUNDED,
						rounded = 3,
						interactive = true,
						bgColor = selected and TB_MENU_DEFAULT_DARKER_ORANGE or TB_MENU_DEFAULT_DARKER_COLOR,
						hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
					})
					fHolder:addMouseHandlers(nil, function()
						local flameLoaderOverlay = UIElement:new({
							parent = listingHolder.parent,
							pos = { 0, 0 },
							size = { listingHolder.size.w, listingHolder.size.h },
							interactive = true,
							bgColor = TB_MENU_DEFAULT_BG_COLOR
						})
						TBMenu:displayLoadingMark(flameLoaderOverlay, TB_MENU_LOCALIZED.NETWORKLOADING)
						Request:queue(function()
								download_server_info("flame_fetch_settings&flameid=" .. v.id)
							end,
							"flameidfetch", -- Net call name
							function() -- Success
								flameLoaderOverlay:kill()
								local response = get_network_response()
								if (response:find("^ERROR;")) then
									response = response:gsub("^ERROR;", "")
									TBMenu:showStatusMessage(response)
									return
								end
								
								previewFlames[flameId] = FlamesInternal.ParseFlameBrowserData(response, v.id)
								Flames:spawnBrowseMenu(listingHolder, toReload, elementHeight, flamesData, flameId, previewFlames, searchFlames)
							end,
							function() -- Error
								flameLoaderOverlay:kill()
								TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORTRYAGAIN)
							end)
						end)
					local fParamName = UIElement:new({
						parent = fHolder,
						pos = { 10, 5 },
						size = { fHolder.size.w / 2 - 20, fHolder.size.h - 10 }
					})
					fParamName:addAdaptedText(false, v.name, nil, nil, nil, LEFTMID)
					local fValueHolder = UIElement:new({
						parent = fHolder,
						pos = { fParamName.size.w + fParamName.shift.x + 5, 2 },
						size = { fHolder.size.w - fParamName.size.w - fParamName.shift.x * 2 - 5, fHolder.size.h - 4 },
						shapeType = ROUNDED,
						rounded = 3
					})
					local forgedOwnedString
					if (not forgedShown and not ownedShown and v.forger == v.owner) then
						forgedOwnedString = TB_MENU_LOCALIZED.FLAMESFORGEDANDOWNEDBY .. " " .. v.forger
					else
						forgedOwnedString = (not forgedShown and (TB_MENU_LOCALIZED.STOREFLAMEFORGEDBY .. " " .. v.forger) or "") .. "\n" .. (not ownedShown and (TB_MENU_LOCALIZED.STOREITEMOWNEDBY .. " " .. v.owner) or "")
					end
					fValueHolder:addAdaptedText(false, forgedOwnedString, nil, nil, 4, RIGHTMID, 0.65)
				end
			end
		end
	end

	for i,v in pairs(listElements) do
		v:hide()
	end

	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar

	scrollBar:makeScrollBar(listingHolder, listElements, toReload)
end

function Flames:showMain()
	usage_event("flameforge")
	self.IsMinimized = false
	local mainView, mainList, mainMoverHolder = TBMenu:spawnMoveableWindow({
		x = self.DisplayPos.x, y = self.DisplayPos.y,
		w = math.min(WIN_W / 2, 600), h = WIN_H * 0.75
	})
	self.MainElement = mainView
	self.DisplayPos = self.MainElement.pos

	local elementHeight = 40
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(mainList, elementHeight, 80, 15, TB_MENU_DEFAULT_BG_COLOR)

	local flamesName = topBar:addChild({
		pos = { 20, 0 },
		size = { topBar.size.w / 2 - 75, topBar.size.h }
	})
	toReload.menuTitle = flamesName

	local flamesButtonsHolder = botBar:addChild({
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	local flameCostEstimate = UIElement:new({
		parent = flamesButtonsHolder,
		pos = { 10, 5 },
		size = { flamesButtonsHolder.size.w - 20, flamesButtonsHolder.size.h / 2 - 7 }
	})
	flameCostEstimate.tc = 0
	toReload.costDisplay = flameCostEstimate

	if (not Flames.Parameters[1]) then
		Flames.Parameters = Flames:spawnFlameSettings(listingHolder, toReload, elementHeight)
	else
		if (Flames.ActiveMode == Flames.MODE_FORGER) then
			Flames:spawnFlameSettings(listingHolder, toReload, elementHeight, Flames.Parameters, Flames.CurrentFlameId)
		elseif (Flames.ActiveMode == Flames.MODE_BROWSER) then
			Flames:spawnBrowseMenu(listingHolder, toReload, elementHeight, Flames.Parameters, Flames.CurrentFlameId)
		else
			Flames:spawnBrowseMenuStored(listingHolder, toReload, elementHeight, Flames.Parameters, Flames.CurrentFlameId)
		end
	end

	local flameIdShift = flamesName.shift.x + flamesName.size.w + 10
	flameIdShift = flameIdShift < topBar.size.w - 240 and topBar.size.w - 240 or flameIdShift
	local flameIdHolder = UIElement:new({
		parent = topBar,
		pos = { flameIdShift, flamesName.shift.y + 5 },
		size = { topBar.size.w - flameIdShift - 10, flamesName.size.h - 10 },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		shapeType = ROUNDED,
		rounded = 3
	})
	local currentFlameId = 0
	local flameSlots = {}
	for i = 1, 5 do
		table.insert(flameSlots, {
			text = TB_MENU_LOCALIZED.FLAMESSLOTID .. " " .. i,
			action = function()
				currentFlameId = i - 1
				if (Flames.ActiveMode == Flames.MODE_BROWSER) then
					Flames:spawnBrowseMenu(listingHolder, toReload, elementHeight, Flames.Parameters, currentFlameId)
				elseif (Flames.ActiveMode == Flames.MODE_FORGER) then
					Flames:spawnFlameSettings(listingHolder, toReload, elementHeight, Flames.Parameters, currentFlameId)
				else
					Flames.CurrentFlameId = currentFlameId
				end
			end
		})
	end
	local flameIdDropdown = TBMenu:spawnDropdown(flameIdHolder, flameSlots, flameIdHolder.size.h / 3 * 2, nil, flameSlots[Flames.CurrentFlameId + 1], { scale = 0.6, fontid = 4 }, { scale = 0.5, fontid = 4 })

	local flamesFlameSave = UIElement:new({
		parent = topBar,
		pos = { flameIdHolder.shift.x - flameIdHolder.size.h - 5, flameIdHolder.shift.y },
		size = { flameIdHolder.size.h, flameIdHolder.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 4
	})
	local flamesFlameSaveIcon = UIElement:new({
		parent = flamesFlameSave,
		pos = { 8, 8 },
		size = { flamesFlameSave.size.w - 16, flamesFlameSave.size.h - 16 },
		bgImage = "../textures/menu/general/buttons/savewhite.tga"
	})
	flamesFlameSave:addMouseHandlers(nil, function()
			local confirmOverlay = TBMenu:showConfirmationWindowInput(TB_MENU_LOCALIZED.FLAMESSAVINGFLAME, TB_MENU_LOCALIZED.FLAMESFLAMENAME, function(flameName)
				local flameName = flameName == "" and os.date() or flameName:gsub(";", "|")
				local flamesStoredFile = Files.Open("../data/flames_stored.dat", FILES_MODE_APPEND)
				if (not flamesStoredFile.data) then
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.FLAMESERROROPENINGSTORAGE)
					return
				end
				local flameString = "FLAME " .. flameName .. ";"
				for i,v in pairs(Flames.Parameters[Flames.CurrentFlameId]) do
					flameString = flameString .. v.value .. " "
				end
				flamesStoredFile:writeLine(flameString)
				flamesStoredFile:close()
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.FLAMESSTORAGESUCCESS)
			end, nil, TB_MENU_LOCALIZED.FLAMESSAVINGEMPTYDATE, TB_MENU_HUB_GLOBALID)
		end)

	local flamesBrowseButton = UIElement:new({
		parent = flamesButtonsHolder,
		pos = { 10, flameCostEstimate.shift.y + flameCostEstimate.size.h + 4 },
		size = { flamesButtonsHolder.size.w / 3 - 13, flamesButtonsHolder.size.h - flameCostEstimate.shift.y * 2 - flameCostEstimate.size.h - 4 },
		shapeType = ROUNDED,
		rounded = 3,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		inactiveColor = { 0.6, 0.6, 0.6, 0.6 }
	})
	flamesBrowseButton:addAdaptedText(false, TB_MENU_LOCALIZED.FLAMESBROWSE)

	local flamesCreateButton = UIElement:new({
		parent = flamesButtonsHolder,
		pos = { flamesBrowseButton.shift.x + flamesBrowseButton.size.w + 6, flamesBrowseButton.shift.y },
		size = { flamesButtonsHolder.size.w - flamesBrowseButton.size.w - flamesBrowseButton.shift.x * 2 - 6, flamesBrowseButton.size.h },
		shapeType = ROUNDED,
		rounded = 3,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	flamesCreateButton:addAdaptedText(false, TB_MENU_LOCALIZED.FLAMESFORGEFLAME)
	flamesCreateButton:addMouseHandlers(nil, function()
			local confirmOverlay = TBMenu:showConfirmationWindowInput(TB_MENU_LOCALIZED.FLAMESFORGINGFLAME, TB_MENU_LOCALIZED.FLAMESFLAMENAME,
				function(name)
					local name = name:gsub(";", '')
					if (name == '') then
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.FLAMESFORGINGNAMEEMPTY)
						return
					end

					local flameSettingsString = ''
					for i,v in pairs(Flames.Parameters[currentFlameId]) do
						flameSettingsString = flameSettingsString .. v.value .. " "
					end

					local overlay = TBMenu:spawnWindowOverlay()
					local loadingMark = UIElement:new({
						parent = overlay,
						pos = { overlay.size.w / 2 - 200, overlay.size.h / 2 - 50 },
						size = { 400, 100 },
						bgColor = TB_MENU_DEFAULT_BG_COLOR
					})
					TBMenu:displayLoadingMarkSmall(loadingMark, TB_MENU_LOCALIZED.REQUESTFINISHINGACTIVE)
					Request:queue(function()
							show_dialog_box(Flames.DialogId, TB_MENU_LOCALIZED.FLAMESFORGINGCONFIRM1 .. " '" .. name .. "' " .. TB_MENU_LOCALIZED.FLAMESFORGINGCONFIRM2 .. " " .. flameCostEstimate.tc .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. ".\n" .. TB_MENU_LOCALIZED.CONFIRMAREYOUSURE, name .. ";" .. flameCostEstimate.tc .. ";" .. flameSettingsString, true)
							loadingMark:kill(true)
							TBMenu:displayLoadingMarkSmall(loadingMark, TB_MENU_LOCALIZED.NETWORKLOADING)

							overlay:addMouseHandlers(nil, nil, function(x)
									if (x < WIN_W / 2) then
										overlay:kill()
										Request:cancelCurrentRequest()
									else
										overlay:addMouseHandlers(nil, nil, function() end)
									end
								end)
							end, "flameforge", function()
								overlay:kill()
								local response = get_network_response()
								local result = response:find("GATEWAY 0; 0")
								local error = not result and response:gsub("GATEWAY 0; 1 ", "") or false

								if (error) then
									local errMsg = TB_MENU_LOCALIZED.REQUESTUNKNOWNERROR -- Fall back to unknown network error on any undefined error code
									if (error == "1") then
										errMsg = TB_MENU_LOCALIZED.FLAMESERRORPRICEMISMATCH
									elseif (error == "2") then
										errMsg = TB_MENU_LOCALIZED.ERRORINSUFFICIENTFUNDS
									elseif (error == "3") then
										errMsg = TB_MENU_LOCALIZED.ERRORBUYINGITEM
									elseif (error == "4") then
										errMsg = TB_MENU_LOCALIZED.ERRORTRANSFERRINGMONEY
									elseif (error == "5") then
										errMsg = TB_MENU_LOCALIZED.FLAMESERRORSPAWNING
									end
									TBMenu:showStatusMessage(errMsg)
									return
								end

								local invid = response:gsub("GATEWAY 0; 0 ", "")
								TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.STOREPURCHASESUCCESSFUL, function()
										Store:spawnInventoryUpdateWaiter()
										show_dialog_box(2, TB_MENU_LOCALIZED.STOREDIALOGACTIVATE1 .. " " .. name  .. (TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 == " " and "?" or " " .. TB_MENU_LOCALIZED.STOREDIALOGACTIVATE2 .. "?"), invid)
									end)
							end, function()
								overlay:kill()
								TBMenu:showStatusMessage(TB_MENU_LOCALIZED.ERRORTRYAGAIN)
							end)

				end, nil, TB_MENU_LOCALIZED.FLAMESFORGINGCHARGED1 .. " " .. flameCostEstimate.tc .. " " .. TB_MENU_LOCALIZED.WORDTORICREDITS .. " " .. TB_MENU_LOCALIZED.FLAMESFORGINGCHARGED2, TB_MENU_HUB_GLOBALID)
			table.insert(Flames.MainElement.child, confirmOverlay)
		end)

	local flamesBrowserButtonsHolder = UIElement:new({
		parent = botBar,
		pos = { 0, 0 },
		size = { botBar.size.w, botBar.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})
	local flamesBrowserStoredButtonsHolder = UIElement:new({
		parent = botBar,
		pos = { 0, 0 },
		size = { botBar.size.w, botBar.size.h },
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR
	})

	local flamesForgerButton = UIElement:new({
		parent = flamesBrowserButtonsHolder,
		pos = { 10, flamesBrowserButtonsHolder.size.h / 2 + 2 },
		size = { flamesBrowserButtonsHolder.size.w / 2 - 13, flamesBrowserButtonsHolder.size.h / 2 - 7 },
		shapeType = ROUNDED,
		rounded = 3,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	flamesForgerButton:addAdaptedText(false, TB_MENU_LOCALIZED.FLAMESFORGERTITLE)

	local flamesForgerButton2 = UIElement:new({
		parent = flamesBrowserStoredButtonsHolder,
		pos = { 10, flamesBrowserStoredButtonsHolder.size.h / 2 + 2 },
		size = { flamesBrowserStoredButtonsHolder.size.w / 2 - 13, flamesBrowserStoredButtonsHolder.size.h / 2 - 7 },
		shapeType = ROUNDED,
		rounded = 3,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	flamesForgerButton2:addAdaptedText(false, TB_MENU_LOCALIZED.FLAMESFORGERTITLE)

	toReload.browserButtons = { flamesBrowserButtonsHolder }
	toReload.browserStoredButtons = { flamesBrowserStoredButtonsHolder }
	toReload.forgerButtons = { flamesButtonsHolder, flamesFlameSave }

	flamesBrowseButton:addMouseHandlers(nil, function()
			Flames:spawnBrowseMenu(listingHolder, toReload, elementHeight, Flames.Parameters, currentFlameId)
		end)
	flamesForgerButton:addMouseHandlers(nil, function()
			Flames:spawnFlameSettings(listingHolder, toReload, elementHeight, Flames.Parameters, currentFlameId)
		end)
	flamesForgerButton2:addMouseHandlers(nil, function()
			Flames:spawnFlameSettings(listingHolder, toReload, elementHeight, Flames.Parameters, currentFlameId)
		end)

	local flamesStoredButton = UIElement:new({
		parent = flamesBrowserButtonsHolder,
		pos = { flamesForgerButton.shift.x + flamesForgerButton.size.w + 6, flamesForgerButton.shift.y },
		size = { flamesBrowserButtonsHolder.size.w - flamesForgerButton.shift.x * 2 - flamesForgerButton.size.w - 6, flamesForgerButton.size.h },
		shapeType = ROUNDED,
		rounded = 3,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	flamesStoredButton:addAdaptedText(false, TB_MENU_LOCALIZED.FLAMESSTOREDFLAMES)
	flamesStoredButton:addMouseHandlers(nil, function()
			Flames:spawnBrowseMenuStored(listingHolder, toReload, elementHeight, Flames.Parameters, Flames.CurrentFlameId)
		end)

	local flamesSearch = UIElement:new({
		parent = flamesBrowserButtonsHolder,
		pos = { 10, 5 },
		size = { flamesButtonsHolder.size.w - 20, flamesBrowserButtonsHolder.size.h / 2 - 7 },
		shapeType = ROUNDED,
		rounded = 3
	})
	local flamesSearchTextfield = TBMenu:spawnTextField2(flamesSearch, { w = flamesSearch.size.w }, nil, TB_MENU_LOCALIZED.FLAMESSEARCHFLAMES, {
		fontId = 4,
		textScale = 0.7,
		textColor = UICOLORWHITE,
		textAlign = LEFTMID,
		darkerMode = true
	})
	local flamesSearchButton = UIElement:new({
		parent = flamesSearch,
		pos = { -200, 1 },
		size = { 199, flamesSearch.size.h - 2 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	flamesSearchButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSEARCH)
	local doSearch = function(str)
		UIElement.handleMouseDn(0, -1, 0)
		Request:queue(function()
			flamesSearchTextfield:deactivate(true)
			flamesSearchButton:deactivate(true)
			local loader = UIElement:new({
				parent = listingHolder.parent,
				pos = { 0, 0 },
				size = { listingHolder.size.w, listingHolder.size.h + botBar.size.h - flamesBrowserButtonsHolder.size.h },
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				interactive = true
			})
			toReload.searchLoader = loader
			TBMenu:displayLoadingMark(loader, TB_MENU_LOCALIZED.NETWORKLOADING)
			download_server_info("flame_search&search=" .. str)
		end, "flamesearch", function()
			local searchFlames = { query = flamesSearchTextfield.textfieldstr[1], { name = "name", flames = {} }, { name = "forger", flames = {} }, { name = "owner", flames = {} } }

			flamesSearchTextfield.textfieldstr[1] = ""
			flamesSearchTextfield:activate(true)
			flamesSearchButton:activate(true)
			toReload.searchLoader:kill()
			toReload.searchLoader = nil

			local response = get_network_response()
			local results = 0
			local _, target, segments = nil, nil, nil
			for ln in string.gmatch(response, "[^\n]+") do
				if (ln:find("^SEARCHNAMES;")) then
					target = searchFlames[1].flames
				elseif (ln:find("^SEARCHFORGER;")) then
					target = searchFlames[2].flames
				elseif (ln:find("^SEARCHOWNER;")) then
					target = searchFlames[3].flames
				else
					if (target) then
						if (not segments) then
							_, segments = ln:gsub("\t", "")
						end
						local data = { ln:match(("([^\t]*)\t"):rep(segments)) }
						if (data[4] and data[4]:len() > 0) then
							table.insert(target, {
								id = data[1],
								name = data[2],
								forger = data[3],
								owner = data[4]
							})
							results = results + 1
						end
					end
				end
			end
			if (results == 0) then
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.FLAMESSEARCHNONEFOUND)
			else
				Flames.BrowserInfo[currentFlameId] = nil
				Flames.SearchData = searchFlames
				Flames:spawnBrowseMenu(listingHolder, toReload, elementHeight, Flames.Parameters, currentFlameId, nil, searchFlames)
			end
		end, function()
			flamesSearchTextfield.textfieldstr[1] = ""
			flamesSearchTextfield:activate(true)
			flamesSearchButton:activate(true)
			toReload.searchLoader:kill()
			toReload.searchLoader = nil

			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REQUESTUNKNOWNERROR)
		end)
	end
	flamesSearchButton:addMouseHandlers(nil, function()
			doSearch(flamesSearchTextfield.textfieldstr[1])
		end)
	flamesSearchTextfield:addEnterAction(doSearch)

	local flamesBrowseButtonBack = UIElement:new({
		parent = flamesBrowserStoredButtonsHolder,
		pos = { flamesForgerButton2.shift.x + flamesForgerButton2.size.w + 6, flamesForgerButton2.shift.y },
		size = { flamesBrowserStoredButtonsHolder.size.w - flamesForgerButton2.shift.x * 2 - flamesForgerButton2.size.w - 6, flamesForgerButton2.size.h },
		shapeType = ROUNDED,
		rounded = 3,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	flamesBrowseButtonBack:addAdaptedText(false, TB_MENU_LOCALIZED.FLAMESBROWSERTITLE)
	flamesBrowseButtonBack:addMouseHandlers(nil, function()
			Flames:spawnBrowseMenu(listingHolder, toReload, elementHeight, Flames.Parameters, currentFlameId)
		end)

	if (Flames.ActiveMode == Flames.MODE_FORGER) then
		for i,v in pairs(toReload.browserButtons) do v:hide(true) end
		for i,v in pairs(toReload.browserStoredButtons) do v:hide(true) end
	elseif (Flames.ActiveMode == Flames.MODE_BROWSER) then
		for i,v in pairs(toReload.forgerButtons) do v:hide(true) end
		for i,v in pairs(toReload.browserStoredButtons) do v:hide(true) end
	else
		for i,v in pairs(toReload.forgerButtons) do v:hide(true) end
		for i,v in pairs(toReload.browserButtons) do v:hide(true) end
	end

	local quitButton = TBMenu:spawnCloseButton(mainMoverHolder, {
		x = -mainMoverHolder.size.h, y = 0, w = mainMoverHolder.size.h, h = mainMoverHolder.size.h
	}, Flames.Quit)
	local minimizeButton = TBMenu:spawnCloseButton(mainMoverHolder, {
		x = -mainMoverHolder.size.h * 2 - 2, y = 0, w = mainMoverHolder.size.h, h = mainMoverHolder.size.h
	}, Flames.Minimize)
	minimizeButton:kill(true)
	minimizeButton:addChild({
		shift = { 2, minimizeButton.size.h / 2 - 2 },
		shapeType = ROUNDED,
		rounded = 2,
		bgColor = UICOLORWHITE
	})
end
