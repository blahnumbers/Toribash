---EVENT TEMPLATE SCRIPT
---@diagnostic disable: duplicate-doc-alias, duplicate-doc-field
if (_T == nil) then
	error("Template data undefined")
end

local loadExistingReplay, loadReplayOpener, triggerNewgame

---Load in data from from the _T global
---@type EventCheckpoint[]
local checkPoints = _T.CHECKPOINTS
local GLOBAL_SETTINGS = _T.GLOBAL_SETTINGS
local CUSTOM_VISUALS = _T.CUSTOM_VISUALS
local MIN_CHECKPOINT_JOINTS = _T.MIN_CHECKPOINT_JOINTS
local MIN_CHECKPOINT_OBJECTS = _T.MIN_CHECKPOINT_OBJECTS

---@diagnostic disable-next-line: assign-type-mismatch
_T = nil

GLOBAL_SETTINGS.EVENT_SHORTNAME = GLOBAL_SETTINGS.EVENT_SHORTNAME or GLOBAL_SETTINGS.EVENT_NAME


local CLIENT_VERSION = tonumber(_G.TORIBASH_VERSION) or 0
_G.EVENT_REPLAY_ACTIVE = false

local SUBMIT_BUTTON = nil
local CUSTOM_REPLAY_BUTTON = nil

---@alias EventConditionCheckMode
---| 0 CHECK_TYPE.PLAYER_POS
---| 1 CHECK_TYPE.ITEM_POS
---| 2 CHECK_TYPE.PLAYER_CUSTOM
---| 3 CHECK_TYPE.ITEM_CUSTOM
---| 4 CHECK_TYPE.PLAYER_TRIGGER
---| 5 CHECK_TYPE.ITEM_TRIGGER
---| 6 CHECK_TYPE.PLAYER_WIN
---| 7 CHECK_TYPE.PLAYER_POINTS
---| 8 CHECK_TYPE.OPPONENT_POINTS
---| 9 CHECK_TYPE.PLAYER_DISMEMBERS
---| 10 CHECK_TYPE.OPPONENT_DISMEMBERS
---| 11 CHECK_TYPE.FRAMES_ELAPSED
local CHECK_TYPE = {
	PLAYER_POS = 0,
	ITEM_POS = 1,
	PLAYER_CUSTOM = 2,
	ITEM_CUSTOM = 3,
	PLAYER_TRIGGER = 4,
	ITEM_TRIGGER = 5,
	PLAYER_WIN = 6,
	PLAYER_POINTS = 7,
	OPPONENT_POINTS = 8,
	PLAYER_DISMEMBERS = 9,
	OPPONENT_DISMEMBERS = 10,
	FRAMES_ELAPSED = 11
}

---@class EventCheckpoint
---@field pos Vector3Base Checkpoint position
---@field size Vector3Base Checkpoint size
---@field rot Vector3Base Checkpoint rotation (visual only, not currently considered when bounds checking)
---@field linkedDisplayObj integer Env obj id to use position and size from
---@field shape UIElement3DShape Checkpoint shape, `CUSTOMOBJ` uses `SPHERE` method for bounds checking
---@field color Color Checkpoint display color
---@field complete boolean Whether the checkpoint has been completed
---@field failed boolean Whether the checkpoint has been failed
---@field visible boolean Whether the checkpoint should be rendered
---@field task integer Corresponding event task ID
---@field costModifier integer Checkpoint cost modifier to be used to reward different items depending on completed checkpoints
---@field targetCheck EventConditionCheckMode Checkpoint target check mode
---@field allowSubmit boolean Whether completing this checkpoint should make replay submission available
---@field dependsCheckpoints integer[] List of checkpoints that should be completed before this checkpoint
---@field submitDependsCheckpoints integer[] List of checkpoints that should be completed for submission to become available
---@field linkedCheckpoints integer[] List of checkpoints that will automatically receive same completion status
---@field element UIElement3D Corresponding UIElement3D for checkpoint rendering
---@field indicatorDisplay boolean Whether to display a 2D indicator for this checkpoint
---@field indicatorElement UIElement Corresponding UIElement for checkpoint indicator
---@field isFinal boolean Whether this is the final checkpoint
---@field checkFunction function Custom checkpoint condition check function, used with `PLAYER_CUSTOM` and `ITEM_CUSTOM` targetCheck values
---@field objectIds integer[] Checkpoint object target env ids, used with `ITEM_` targetCheck values
---@field trigTargetEnvIds integer[] List of target trigger objects, used with `PLAYER_TRIGGER` and `ITEM_TRIGGER` targetCheck values
---@field trigTargetBodyIds integer[] List of target trigger bodyparts, used with `PLAYER_TRIGGER` targetCheck value
---@field frameCompleted integer Frame when checkpoint was completed
---@field trigAllowedBodyparts integer[] List of allowed bodyparts for player trigger checking on versions before 5.55
---@field inverseCondition boolean Whether this checkpoint should be completed by default and unchecked if condition is met
---@field compareValue number Value to compare dismembers / points condition against
---@field playerId integer Custom player id to use for `PLAYER_POS` checkpoint target check mode
---@field negateCondition boolean Whether condition completion state should be negated during checks
---@field invalidateFunc function Custom checkpoint invalidate function
---@field onInvalidateFunc function Custom callback fired on checkpoint invalidation
---@field onCompleteFunc function Custom callback fired on checkpoint completion
---@field customObjScale number Custom obj scale relative to checkpoint size
---@field customObj string Custom obj path for `CUSTOMOBJ` shape checkpoints
---@field effects RenderEffect Render effects for checkpoint
---@field isRotating boolean Whether this checkpoint should be rotating
---@field indicatorHideDistance number Max distance to checkpoint indicator before it's hidden
---@field ignoreWinFrame boolean If set to `true`, this checkpoint will not set win frame upon completion
---@field ignoreDepth boolean ignoreDepth value for the checkpoint renderer
---@field bodyGeom integer|nil Lua geom associated with the 3D representation of a checkpoint

local spawnTriggerHook = false
if (tbTutorialsTask.misc == nil) then
	tbTutorialsTask.misc = { }
end

---Keep in mind that this will be executed on every step that uses custom functions
for _, v in pairs(checkPoints) do
	v.complete = false
	v.frameCompleted = -1
	if (v.isFinal) then
		v.complete = tbTutorialsTaskMark and tbTutorialsTaskMark:isDisplayed()
	elseif (v.task) then
		if (tbTutorialsTask.optional[v.task]) then
			v.complete = tbTutorialsTask.optional[v.task].complete
		elseif (tbTutorialsTask.misc[v.task]) then
			v.complete = tbTutorialsTask.misc[v.task].complete
		end
	end
	if (v.targetCheck == CHECK_TYPE.PLAYER_TRIGGER or v.targetCheck == CHECK_TYPE.ITEM_TRIGGER) then
		spawnTriggerHook = true
	end
	if (v.linkedDisplayObj) then
		if (v.pos == nil) then
			local x, y, z = get_obj_pos(v.linkedDisplayObj)
			v.pos = { x = x, y = y, z = z }
		end
		if (v.size == nil) then
			local x, y, z = get_obj_sides(v.linkedDisplayObj)
			v.size = { x = x, y = y, z = z }
		end
	end
	if (v.color ~= nil) then
		v.color[4] = 0.7
	end
	if (v.rot == nil) then
		v.rot = { x = 0, y = 0, z = 0 }
	end
end

if (GLOBAL_SETTINGS.WITH_RESEED_CHECKPOINTS) then
	local nameLen = string.len(TB_MENU_PLAYER_INFO.username)
	for i, v in pairs(checkPoints) do
		---Shuffle seed based on username
		if (v.seed == nil) then
			local idx = 1 + i % nameLen
			local idx2 = 1 + (i + 5) % nameLen
			v.seed = string.byte(string.sub(TB_MENU_PLAYER_INFO.username, idx, idx)) + string.byte(string.sub(TB_MENU_PLAYER_INFO.username, idx2, idx2))
		end
	end
	checkPoints = table.qsort(checkPoints, "seed")
end

---Checks whether game client supports minimum event version. \
---**This function must use functionality that's available on as many older builds as possible.**
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@return boolean
local function verifyVersionLogin(viewElement, reqTable)
	if (GLOBAL_SETTINGS.MIN_VERSION > CLIENT_VERSION or TB_MENU_PLAYER_INFO == nil or TB_MENU_PLAYER_INFO.username == "") then
		local req = { type = "exit", ready = false }
		table.insert(reqTable, req)

		select_player(-1)
		local overlay = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h },
			interactive = true,
			bgColor = { 1, 1, 1, 1 }
		})
		local maxWidth = math.min(overlay.size.w * 0.6, 700)
		local messageHolder = UIElement:new({
			parent = overlay,
			pos = { (overlay.size.w - maxWidth) / 2, overlay.size.h / 2 - 100 },
			size = { maxWidth, 200 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		local messageText = UIElement:new({
			parent = messageHolder,
			pos = { 10, 10 },
			size = { messageHolder.size.w - 20, messageHolder.size.h - 80 }
		})
		local errorText = TB_MENU_LOCALIZED.EVENTVERSIONUPDATEREQUIRED
		if (GLOBAL_SETTINGS.MIN_VERSION <= CLIENT_VERSION) then
			errorText = TB_MENU_LOCALIZED.EVENTPLEASELOGINTOPARTICIPATE
		end
		messageText:addAdaptedText(true, errorText)
		local okButton = UIElement:new({
			parent = messageHolder,
			pos = { messageHolder.size.w / 4, -60 },
			size = { messageHolder.size.w / 2, 50 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = messageHolder.shapeType,
			rounded = messageHolder.rounded
		})
		okButton:addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONOK)
		okButton:addMouseHandlers(nil, function()
				overlay:kill()
				close_menu()
				Tutorials:quit()
			end)
		return false
	end
	return true
end

---Helper function to mark all checkpoints incomplete
---@param checkFrame ?boolean Whether to invalidate only the checkpoints that were completed after current frame
local function invalidateCheckpoints(checkFrame)
	local targetFrame = checkFrame and get_world_state().match_frame or -100000
	local canSubmit = false
	local winFrame = -1
	for _, v in pairs(checkPoints) do
		if ((v.invalidateFunc and v.invalidateFunc(v, targetFrame)) or v.frameCompleted == -1 or targetFrame < v.frameCompleted) then
			v.complete = false
			v.failed = false
			if (v.isFinal) then
				tbTutorialsTaskMark:hide(true)
			elseif (v.task) then
				v.frameCompleted = -1
				Tutorials:taskOptIncomplete(v.task)
			end
			if (v.onInvalidateFunc) then
				v.onInvalidateFunc(v, targetFrame)
			end
		else
			winFrame = math.max(winFrame, v.frameCompleted)
		end

		if (v.allowSubmit and v.complete) then
			canSubmit = true
		end
	end
	if (winFrame ~= -1) then
		WIN_FRAME = winFrame
	end

	REPLAY_CAN_BE_SUBMITTED = canSubmit
end

---Spawns top list display and fetches its information from Toribash server
---@param viewElement UIElement
local function spawnToplist(viewElement)
	local elementHeight = 30
	local toplistHolder = viewElement:addChild({
		pos = { viewElement.size.w - 300, 20 },
		size = { 300, 400 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(toplistHolder, elementHeight * 3 / 2, elementHeight - 16, 20, TB_MENU_DEFAULT_BG_COLOR)
	local hideButton = topBar:addChild({
		pos = { -topBar.size.w, 0 },
		size = { 25, topBar.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true
	})
	local rotate_dir = 0
	hideButton.toggleEnabled = EVENT_TOPLIST_DISPLAYED == nil and true or EVENT_TOPLIST_DISPLAYED
	local angle = hideButton.toggleEnabled and 270 or 90
	if (not hideButton.toggleEnabled) then
		toplistHolder:moveTo(-25)
	end
	hideButton:addCustomDisplay(false, function()
			set_color(unpack(UICOLORWHITE))
			draw_disk(hideButton.pos.x + hideButton.size.w / 2, hideButton.pos.y + hideButton.size.h / 2, 0, hideButton.size.w / 3, 3, 1, 60 + angle, 360 + angle, 0)
			if (rotate_dir ~= 0) then
				angle = angle + 10 * rotate_dir
				if (angle < 0) then
					angle = 360 + angle
				end
				toplistHolder:moveTo((toplistHolder.size.w - 25) / 18 * rotate_dir, 0, true)
				if (angle % 180 - 90 == 0) then
					rotate_dir = 0
				end
			end
		end)
	hideButton:addMouseUpHandler(function()
			if (hideButton.toggleEnabled) then
				rotate_dir = 1
				hideButton.toggleEnabled = false
			else
				rotate_dir = -1
				hideButton.toggleEnabled = true
			end
			EVENT_TOPLIST_DISPLAYED = hideButton.toggleEnabled
		end)

	local toplistHeader = topBar:addChild({
		pos = { 25, 5 },
		size = { topBar.size.w - 50, topBar.size.h - 10 }
	})
	toplistHeader:addAdaptedText(true, TB_MENU_LOCALIZED.EVENTSTOPLIST)

	local reloadButton = topBar:addChild({
		pos = { -25, 0 },
		size = { 25, topBar.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true
	})
	reloadButton:addChild({
		pos = { 2, (reloadButton.size.h - (reloadButton.size.w - 4)) / 2 },
		size = { reloadButton.size.w - 4, reloadButton.size.w - 4 },
		bgImage = "../textures/menu/general/buttons/reload.tga",
	})
	reloadButton:addMouseUpHandler(function()
			toplistHolder:kill()
			spawnToplist(viewElement)
		end)

	TBMenu:displayLoadingMark(listingHolder, TB_MENU_LOCALIZED.EVENTSLOADINGTOPPLAYERS)

	local toplistError = function(noEntries)
		if (listingHolder == nil or listingHolder.destroyed) then return end

		listingHolder:kill(true)
		local errorMessage = listingHolder:addChild({
			pos = { 25, 10 },
			size = { listingHolder.size.w - 30, listingHolder.size.h - 20 }
		})
		errorMessage:addAdaptedText(true, noEntries and TB_MENU_LOCALIZED.EVENTSNOPLAYERSHAVESUBMITTEDENTRIES or TB_MENU_LOCALIZED.ACCOUNTINFOERROR)
	end

	local toplistSuccess = function()
		if (listingHolder == nil or listingHolder.destroyed) then return end

		listingHolder:kill(true)
		local response = get_network_response()

		local listElements = {}
		local topSpeed = 0
		for ln in response:gmatch("[^\n]*\n?") do
			if (not ln:find("^#INFO") and ln:len() > 0) then
				local _, segments = ln:gsub("\t", "")
				local data = { ln:match(("([^\t]*)\t?"):rep(segments)) }

				local playerEntry = listingHolder:addChild({
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, playerEntry)
				local playerName = playerEntry:addChild({
					pos = { 10, 2 },
					size = { playerEntry.size.w / 2 - 15, playerEntry.size.h - 5 }
				})
				playerName:addAdaptedText(true, data[1], nil, nil, 4, LEFTMID, 0.7)

				local playerResult = playerEntry:addChild({
					pos = { playerEntry.size.w / 2 + 5, 2 },
					size = { playerEntry.size.w / 2 - 15, playerEntry.size.h - 5 }
				})
				playerResult:addAdaptedText(true, data[2] .. " " .. TB_MENU_LOCALIZED.EVENTSFRAMES, nil, nil, 4, RIGHTMID, 0.7)

				playerEntry:addChild({
					pos = { 25, -1 },
					size = { playerEntry.size.w - 50, 0.5 },
					bgColor = { 1, 1, 1, 0.2 }
				})

				if (topSpeed == 0) then
					topSpeed = data[2]
				end
			end
		end
		if (#listElements == 0) then
			toplistError(true)
			return
		end
		for _, v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = scrollBar
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)

		local targetFrames = topBar:addChild({
			pos = { 0, topBar.size.h },
			size = { listingHolder.size.h, listingHolder.size.h },
			bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR)
		})
		targetFrames:addCustomDisplay(false, function()
				targetFrames.bgColor[4] = 1 - (-toplistHolder.pos.x + WIN_W - 25) / (toplistHolder.size.w - 25)
				targetFrames:uiText("Top speed: " .. topSpeed .. " frames", -70, 100, FONTS.MEDIUM, nil, 0.8, -90, nil, { 1, 1, 1, targetFrames.bgColor[4] })
			end)
	end

	Request:queue(function()
			download_server_info("event_toplist&event=" .. CURRENT_TUTORIAL)
		end, "fetch_toplist", toplistSuccess, toplistError)
end

---Spawns a toggle for task display
local function spawnTaskToggle()
	local taskToggle = tbTutorialsTask:addChild({
		pos = { tbTutorialsTask.size.w, 0 },
		size = { tbTutorialsTask.size.h, tbTutorialsTask.size.h },
		bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR),
		hoverColor = TB_MENU_DEFAULT_BG_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true
	})
	tbTutorialsTask.taskToggle = taskToggle
	taskToggle.bgColor[4] = 0.7
	taskToggle.animateColor[4] = 0.7
	taskToggle.toggleEnabled = true
	taskToggle.spawnTime = GLOBAL_SETTINGS.WITH_TASK_AUTOHIDE and os.time() or 0
	local angle = 90
	local rotate_dir = 0
	taskToggle:addCustomDisplay(false, function()
			set_color(unpack(UICOLORWHITE))
			draw_disk(taskToggle.pos.x + taskToggle.size.w / 2, taskToggle.pos.y + taskToggle.size.h / 2, 0, taskToggle.size.w / 5, 3, 1, 60 + angle, 360 + angle, 0)
			if (rotate_dir ~= 0) then
				angle = angle + 10 * rotate_dir
				if (angle % 180 - 90 == 0) then
					rotate_dir = 0
				end
			end

			if (taskToggle.spawnTime > 0 and taskToggle.toggleEnabled and taskToggle.spawnTime + 25 < os.time()) then
				taskToggle.btnUp()
			end
		end)
	taskToggle:addMouseHandlers(nil, function()
			taskToggle.spawnTime = 0
			if (taskToggle.toggleEnabled) then
				rotate_dir = 1
				taskToggle.toggleEnabled = false
				Tutorials:showTaskWindow({}, true, true)
			else
				rotate_dir = -1
				taskToggle.toggleEnabled = true
				Tutorials:showTaskWindow({}, false, true)
			end
		end)
end

---Renders the checkpoint completion animation
---@param checkPoint EventCheckpoint
local function checkpointComplete(checkPoint)
	if (checkPoint.indicatorElement) then
		checkPoint.indicatorElement:kill()
		checkPoint.indicatorElement = nil
	end

	local check = checkPoint.element
	if (not check or not check.size) then
		return
	end

	local initialSize = table.clone(check.size)
	local clock = UIElement.clock
	check:addCustomDisplay(false, function()
			local rate = UITween.SineTween(1, 0, UIElement.clock - clock)
			check.bgColor[4] = check.bgColor[4] * rate
			check.size.x = initialSize.x + (1 - rate) * initialSize.x * 0.2
			if (checkPoint.shape == CUBE or checkPoint.shape == CUSTOMOBJ) then
				check.size.y = initialSize.y + (1 - rate) * initialSize.y * 0.2
			end
			if (rate == 0) then
				check:kill()
			end
		end)
	check:show()
end

local function autosaveReplay()
	local rplName = string.gsub(GLOBAL_SETTINGS.EVENT_SHORTNAME, "[^a-zA-Z0-9]", "")
	if (REPLAY_CAN_BE_SUBMITTED) then
		rplName = rplName .. "-" .. os.date("%Y-%m-%dT%H%M%S")
	else
		rplName = rplName .. "-LastAttempt"
	end
	runCmd("savereplay " .. rplName)
	TBMenu:showStatusMessage("Your replay has been autosaved as " .. rplName)
end

---Initializes all defined checkpoints and creates UIElement3D objects to render them
---@param viewElement UIElement
---@param withIndicators boolean?
local function loadCheckpoints(viewElement, withIndicators)
	for _, v in pairs(checkPoints) do
		if (v.element) then
			v.element:kill()
		end
		if (v.indicatorElement) then
			v.indicatorElement:kill()
			v.indicatorElement = nil
		end
		if (not v.complete and v.visible) then
			local scale = table.clone(v.size)
			if (v.shape == CUSTOMOBJ and v.customObj ~= nil and type(v.customObjScale) == "number") then
				scale.x = scale.x * v.customObjScale
				scale.y = scale.y * v.customObjScale
				scale.z = scale.z * v.customObjScale
			end
			local checkPoint = tbTutorials3DHolder:addChild({
				pos = { v.pos.x, v.pos.y, v.pos.z + (v.shape == CAPSULE and v.size.y / 2 or 0) },
				size = { scale.x, scale.y, scale.z },
				rot = { v.rot.x, v.rot.y, v.isRotating and math.random(0, 360) or v.rot.z },
				shapeType = v.shape,
				bgColor = v.color and table.clone(v.color) or { 0, 0, 1, 0.5 },
				objModel = v.customObj,
				---@diagnostic disable-next-line: assign-type-mismatch
				effects = v.effects,
				ignoreDepth = v.ignoreDepth
			})
			v.element = checkPoint

			if (v.linkedDisplayObj ~= nil) then
				checkPoint:addCustomDisplay(function()
						--Consider adding rotation here too
						checkPoint.shift.x, checkPoint.shift.y, checkPoint.shift.z = get_obj_pos(v.linkedDisplayObj)
						checkPoint.shift.x = checkPoint.shift.x - 1
						checkPoint:updateChildPos()
					end, true)
			elseif (v.isRotating) then
				checkPoint:addCustomDisplay(function()
						checkPoint:rotate(0, 0, 1)
					end)
			end

			if (v.indicatorDisplay) then
				v.bodyGeom = create_raycast_body(0, v.pos.x + 1, v.pos.y, v.pos.z, v.size.x * 1.1)
				checkPoint.killAction = function()
					destroy_raycast_body(v.bodyGeom)
					v.bodyGeom = nil
				end
				if (withIndicators == true) then
					local checkSize = math.min(46, WIN_H / 25)
					local stepSize = math.ceil(checkSize / 20)
					local checkPointDisplay = UIElement:new({
						parent = viewElement,
						pos = { 0, 0 },
						size = { checkSize, checkSize },
						bgImage = "../textures/menu/general/buttons/square45.tga",
						imageColor = UICOLORBLACK
					})
					v.indicatorElement = checkPointDisplay

					checkPointDisplay:addChild({
						shift = { stepSize, stepSize },
						bgImage = "../textures/menu/general/buttons/square45.tga",
						imageColor = TB_MENU_DEFAULT_BLUE
					}):addChild({
						shift = { stepSize * 3, stepSize * 3 },
						bgImage = "../textures/menu/general/buttons/square45.tga",
						imageColor = TB_MENU_DEFAULT_DARKER_BLUE
					}):addChild({
						shift = { stepSize * 2, stepSize * 2 },
						bgImage = "../textures/menu/general/buttons/square45.tga",
						imageColor = TB_MENU_DEFAULT_BLUE
					})

					-- get_screen_pos() must be executed from a UIElement3D object!
					local indicatorUpdater = checkPoint:addChild({ size = { 1, 1, 1 } })
					indicatorUpdater:addCustomDisplay(true, function()
							local x, y, z = get_screen_pos(checkPoint.pos.x, checkPoint.pos.y, checkPoint.pos.z)
							if (z == 0) then
								checkPointDisplay:show()
								checkPointDisplay:moveTo(math.clamp(x - checkPointDisplay.size.w / 2, 0, WIN_W - checkPointDisplay.size.w), math.clamp(y - checkPointDisplay.size.h / 2, 0, WIN_H - checkPointDisplay.size.h))
							else
								checkPointDisplay:hide()
							end
						end, true)

					if (v.bodyGeom ~= nil) then
						indicatorUpdater:addOnEnterFrame(function()
							local headPos = get_body_info(0, BODYPARTS.HEAD).pos
							local geom, distance = shoot_ray(headPos.x, headPos.y, headPos.z, v.pos.x + 1, v.pos.y, v.pos.z)
							if (geom == v.bodyGeom and distance < v.indicatorHideDistance) then
								checkPointDisplay:show(true)
							else
								checkPointDisplay:hide(true)
							end
						end)
					end
				end
			end
		end
	end
	if (CUSTOM_VISUALS ~= nil) then
		CUSTOM_VISUALS()
	end
	UIElement3D.drawEnterFrame(Tutorials.Globalid)
end

---Checks whether the specified point in 3D world is within the checkpoint
---@param x number
---@param y number
---@param z number
---@param checkPoint EventCheckpoint
---@param adjustValues? boolean
---@return boolean
local function checkInBounds(x, y, z, checkPoint, adjustValues)
	if (adjustValues) then
		x = x - 1
		y = y + 0.1
	end
	if (checkPoint.shape == CUBE) then
		if (checkPoint.pos.x - checkPoint.size.x / 2 < x and checkPoint.pos.x + checkPoint.size.x / 2 > x and
			checkPoint.pos.y - checkPoint.size.y / 2 < y and checkPoint.pos.y + checkPoint.size.y / 2 > y and
			checkPoint.pos.z - checkPoint.size.z / 2 < z and checkPoint.pos.z + checkPoint.size.z / 2 > z) then
			return true
		end
	elseif (checkPoint.shape == CAPSULE) then
		local xR, yR = x - checkPoint.pos.x, y - checkPoint.pos.y
		if (xR * xR + yR * yR <= checkPoint.size.x * checkPoint.size.x and
			checkPoint.pos.z - checkPoint.size.y / 2 < z and checkPoint.pos.z + checkPoint.size.y / 2 > z) then
			return true
		end
	else
		local xR, yR, zR = x - checkPoint.pos.x, y - checkPoint.pos.y, z - checkPoint.pos.z
		if (xR * xR + yR * yR + zR * zR <= checkPoint.size.x * checkPoint.size.x) then
			return true
		end
	end

	return false
end

---Displays replay upload window
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
local function showUploadWindow(viewElement, reqTable)
	local req = { type = "upload", ready = false }
	table.insert(reqTable, req)

	CURRENT_STEP.fallbackrequirement = true

	local handleError = function()
		CURRENT_STEP.fallbackrequirement = false
		req.ready = true
		reqTable.ready = true
	end
	local function uploadReplay(name)
		chat_input_deactivate()
		if (name == nil) then
			name = generate_uid()
		else
			name = name:gsub("%.rpl$", ""):gsub("^%/", "")
			name = name:sub(0, 35) -- attempt to fix infinite replay upload error
		end
		if (name == '') then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYSERROREMPTYNAME)
			handleError()
			return
		end
		runCmd("savereplay " .. name)
		local file = Files.Open("../replay/my replays/" .. name .. ".rpl", FILES_MODE_APPEND)
		if (file.data) then
			local winframe = WIN_FRAME
			for _, check in pairs(checkPoints) do
				---We do not care about inverseCondition checkpoints here
				---They are marked same as normal ones at this point
				if (not check.complete) then
					winframe = winframe + check.costModifier * 10000
				end
			end
			file:writeLine("#ENDFRAME " .. winframe)
			file:close()
		else
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.EVENTSERRORPREPARINGREPLAY)
			handleError()
			return
		end

		local overlay = TBMenu:spawnWindowOverlay()
		local dimensions = { math.min(overlay.size.w * 0.45, 600), math.min(overlay.size.h / 5, 250) }
		local uploadingView = overlay:addChild({
			pos = { (overlay.size.w - dimensions[1]) / 2, (overlay.size.h - dimensions[2]) / 2 },
			size = dimensions,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5
		})
		uploadingView:addAdaptedText(false, TB_MENU_LOCALIZED.REPLAYUPLOADINPROGRESS)
		local success = function(_, response)
			overlay:kill()
			if (response:find("^SUCCESS")) then
				invalidateCheckpoints()
				local prizeDelivered, replacements = response:gsub("^.*;(%w)$", '%1')
				if (replacements == 0 or prizeDelivered ~= '1') then
					CURRENT_STEP.skip = 3
				else
					if (GLOBAL_SETTINGS.IS_STATIC_EVENT) then
						Events.FetchStaticEvents()
					else
						if (BattlePass ~= nil and BattlePass.getUserData) then
							BattlePass:getUserData()
						end
						if (Quests ~= nil and Quests.download) then
							Quests:download(true)
						end
					end
					if (type(request_app_review) == "function") then
						request_app_review()
					end
				end
				req.ready = true
				reqTable.ready = true
			else
				TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADERROR .. ": " .. response:gsub("^ERROR 0;", ""), function() showUploadWindow(viewElement, reqTable) end, handleError)
			end
			delete_replay("my replays/" .. name .. ".rpl")
			if (GLOBAL_SETTINGS.IS_STATIC_EVENT) then
				REPLAY_CAN_BE_SUBMITTED = true
				autosaveReplay()
				REPLAY_CAN_BE_SUBMITTED = false
			end
		end
		local error = function()
			overlay:kill()
			TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.REPLAYUPLOADFAILED, function() showUploadWindow(viewElement, reqTable) end, handleError)
			delete_replay("my replays/" .. name .. ".rpl")
		end
		Request:queue(function()
				upload_event_replay(
					name,
					GLOBAL_SETTINGS.EVENT_SHORTNAME .. " event submission",
					"ESEVNT" .. CURRENT_TUTORIAL,
					"replay/my replays/" .. name .. ".rpl"
				)
			end, "replayupload", success, error)
	end

	local function cancelUpload()
		chat_input_deactivate()
		CURRENT_STEP.fallbackrequirement = false
		reqTable.ready = true
	end
	if (GLOBAL_SETTINGS.WITH_SUBMISSION_DEFAULT_NAME == true) then
		TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.EVENTSSTATICSUBMITTINGENTRY, uploadReplay, cancelUpload)
	else
		TBMenu:showConfirmationWindowInput(TB_MENU_LOCALIZED.EVENTSUPLOADINGENTRY, TB_MENU_LOCALIZED.REPLAYSENTERNAME, uploadReplay, cancelUpload)
	end
end

---Toggles mobile hub
---@param hubBackground UIElement
---@param state boolean
local function toggleHub(hubBackground, state)
	local clock = UIElement.clock
	if (state == true) then
		hubBackground.parent:show()
	end
	hubBackground:addCustomDisplay(function()
		local tweenValue = (UIElement.clock - clock) * 6
		if (state) then
			hubBackground:moveTo(UITween.SineTween(hubBackground.shift.x, hubBackground.parent.size.w - hubBackground.size.w, tweenValue))
		else
			hubBackground:moveTo(UITween.SineTween(hubBackground.shift.x, hubBackground.parent.size.w, tweenValue))
		end
		if (tweenValue >= 1) then
			hubBackground:addCustomDisplay(function() end)
			if (state == false) then
				hubBackground.parent:hide()
			end
		end
	end)
end

---Generic function to display custom replay selection window
---@param viewElement UIElement
local function showCustomReplaySelection(viewElement)
	Replays:showCustomReplaySelection(viewElement, GLOBAL_SETTINGS.MOD_OVERRIDE or (CURRENT_TUTORIAL .. ".tbm"), function(path)
			TUTORIAL_LEAVEGAME = true
			STOPFRAME = -1
			WIN_FRAME = 100000
			local cleanPath = string.gsub(path, "^replay/", "")
			if (SUBMIT_BUTTON ~= nil) then
				SUBMIT_BUTTON:kill()
				SUBMIT_BUTTON = nil
			end
			loadExistingReplay(viewElement, cleanPath)
			EVENT_REPLAY_BROWSER_ISOPEN = false
		end)
end

---Sets an override for mobile hud button action
---@param viewElement UIElement
---@param submitReqTable ?TutorialStepRequirement[]
---@param skipAdd ?integer
local setTutorialHubOverride = function(viewElement, submitReqTable, skipAdd)
	TBHud.SetTutorialHubOverride(function()
		if (SUBMIT_BUTTON ~= nil) then
			SUBMIT_BUTTON.bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR)
			SUBMIT_BUTTON:addCustomDisplay(function() end)
		end
		local uiOverlay = viewElement:addChild({
			interactive = true
		})
		local hubBackground = uiOverlay:addChild({
			pos = { uiOverlay.size.w, 0 },
			size = { TBHud.HubSize.w + SAFE_X, viewElement.size.h },
			bgColor = { 1, 1, 1, 0.7 },
			interactive = true
		})
		local buttonSize = (TBHud.HubSize.w - 20) / 4
		local loadReplayButton = hubBackground:addChild({
			pos = { 10, math.max(SAFE_Y, 20) },
			size = { buttonSize, buttonSize },
			bgImage = "../textures/menu/button_backdrop.tga",
			imageColor = TB_MENU_DEFAULT_BG_COLOR,
			imageHoverColor = TB_MENU_DEFAULT_DARKER_ORANGE,
			imagePressedColor = TB_MENU_DEFAULT_DARKER_ORANGE,
			interactive = true
		})
		loadReplayButton:addMouseUpHandler(function()
				showCustomReplaySelection(viewElement)
				toggleHub(hubBackground, false)
			end)
			loadReplayButton:addChild({
				pos = { 10, 2 },
				size = { loadReplayButton.size.w - 20, loadReplayButton.size.h - 20 },
				bgImage = { "../textures/menu/general/replays_icon.tga", "../textures/menu/replays.tga" }
			})
		local buttonTitleHolder = loadReplayButton:addChild({
			pos = { 0, -30 },
			size = { loadReplayButton.size.w, 30 },
			bgColor = loadReplayButton.imageAnimateColor,
			shapeType = ROUNDED,
			rounded = { 0, 5 }
		})
		buttonTitleHolder:addChild({ shift = { 5, 2 }}):addAdaptedText(TB_MENU_LOCALIZED.EVENTSLOADCUSTOMREPLAYNOHOTKEY)

		toggleHub(hubBackground, true)
		uiOverlay:addMouseUpHandler(function() toggleHub(hubBackground, false) end)

		if (submitReqTable ~= nil) then
			local submitButton = hubBackground:addChild({
				pos = { 10, loadReplayButton.shift.x + loadReplayButton.size.h + 20 },
				size = { TBHud.HubSize.w - 20, 80 },
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
				pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				shapeType = ROUNDED,
				rounded = 5
			})
			submitButton:addChild({ shift = { 10, 5 }}):addAdaptedText(TB_MENU_LOCALIZED.BUTTONSUBMIT)
			submitButton:addMouseUpHandler(function()
				if (_G.EVENT_REPLAY_ACTIVE == true) then
					return
				end

				freeze_game()
				toggleHub(hubBackground, false)
				CURRENT_STEP.skip = skipAdd
				submitReqTable.ready = true
			end)
		end

		local buttonExit = hubBackground:addChild({
			pos = { 10, -50 - math.max(SAFE_Y, 20) },
			size = { TBHud.HubSize.w - 20, 50 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 5
		})
		buttonExit:addChild({ shift = { 10, 5 }}):addAdaptedText("> " .. TB_MENU_LOCALIZED.MOBILEHUDTOMAINMENU)
		buttonExit:addMouseUpHandler(function() open_menu(19) end)
	end)
end

---Displays replay submit button
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
---@param skipAdd ?integer
---@return UIElement
---@return UIElement?
local showSubmitButton = function(viewElement, reqTable, skipAdd)
	local skipAdd = skipAdd or 0
	if (is_mobile()) then
		setTutorialHubOverride(viewElement, reqTable, skipAdd)
		local submitReadyIndicator = viewElement:addChild({
			pos = { TBHud.HubButtonHolder.pos.x + 2, TBHud.HubButtonHolder.pos.y + 2 },
			size = { TBHud.HubButtonHolder.size.w - 4, TBHud.HubButtonHolder.size.h - 4 },
			shapeType = ROUNDED,
			rounded = TBHud.HubButtonHolder.size.w,
			bgColor = table.clone(TB_MENU_DEFAULT_BG_COLOR)
		})
		local spawnTime = UIElement.clock
		submitReadyIndicator:addCustomDisplay(function()
				local tweenRatio = (math.cos((UIElement.clock - spawnTime) * 0.5) + 1) * 0.5
				submitReadyIndicator.bgColor[1] = UITween.SineTween(TB_MENU_DEFAULT_BG_COLOR[1], UICOLORRED[1], tweenRatio)
				submitReadyIndicator.bgColor[2] = UITween.SineTween(TB_MENU_DEFAULT_BG_COLOR[2], UICOLORRED[2], tweenRatio)
				submitReadyIndicator.bgColor[3] = UITween.SineTween(TB_MENU_DEFAULT_BG_COLOR[3], UICOLORRED[3], tweenRatio)
			end)
		submitReadyIndicator:addChild({ shift = { 6, 4 } }):addAdaptedText(true, TB_MENU_LOCALIZED.BUTTONSUBMIT)
		submitReadyIndicator.killAction = function()
			setTutorialHubOverride(viewElement)
		end
		return submitReadyIndicator
	end

	local buttonWidth = CUSTOM_REPLAY_BUTTON ~= nil and CUSTOM_REPLAY_BUTTON.size.w or math.clamp(WIN_W / 5, 250, 400 )
	local submitButton = viewElement:addChild({
		pos = { -buttonWidth - 10, CUSTOM_REPLAY_BUTTON ~= nil and CUSTOM_REPLAY_BUTTON.shift.y - 80 or -80 },
		size = { buttonWidth, 70 },
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		interactive = true,
		shapeType = ROUNDED,
		rounded = 5
	})
	if (CUSTOM_REPLAY_BUTTON ~= nil) then
		local animateBeginTime = 0
		submitButton:addCustomDisplay(function()
				if (CUSTOM_REPLAY_BUTTON == nil) then
					if (animateBeginTime == 0) then
						animateBeginTime = UIElement.clock
					else
						submitButton:moveTo(nil, UITween.SineTween(submitButton.shift.y, WIN_H - submitButton.size.h - 10, UIElement.clock - animateBeginTime))
						if (UIElement.clock - animateBeginTime > 1) then
							submitButton:addCustomDisplay(function() end)
						end
					end
				end
			end)
	end
	submitButton:addChild({ shift = { 10, 5 } }):addAdaptedText(false, TB_MENU_LOCALIZED.BUTTONSUBMIT)
	submitButton:addMouseUpHandler(function()
			if (_G.EVENT_REPLAY_ACTIVE == true) then
				return
			end

			freeze_game()
			CURRENT_STEP.skip = skipAdd
			reqTable.ready = true
		end)
	return submitButton
end

---Generic function to verify checkpoint completion prerequisites
---@param check EventCheckpoint Checkpoint data
---@param extraData? table Any additional data we received from the callback
local function verifyCheckpointPrerequisites(check, extraData)
	for _, linked in pairs(check.dependsCheckpoints or {}) do
		if (checkPoints[linked].complete == false) then
			return
		end
	end

	local checkComplete = false
	local targetTask = check.task
	local ws = get_world_state()
	if (check.targetCheck == CHECK_TYPE.PLAYER_POS) then
		local criteriaMet = 0
		for _, v in pairs(JOINTS) do
			local x, y, z = get_joint_pos(check.playerId or 0, v)
			if (checkInBounds(x, y, z, check, true)) then
				criteriaMet = criteriaMet + 1
			end
		end
		if (criteriaMet >= MIN_CHECKPOINT_JOINTS and
			(check.checkFunction == nil or check.checkFunction(criteriaMet, check))) then
			checkComplete = true
		end
	elseif (check.targetCheck == CHECK_TYPE.ITEM_POS) then
		local criteriaMet = 0
		for _, v in pairs(check.objectIds) do
			local x, y, z = get_obj_pos(v)
			if (checkInBounds(x, y, z, check, true)) then
				criteriaMet = criteriaMet + 1
			end
		end
		if (criteriaMet >= math.min(MIN_CHECKPOINT_OBJECTS, #check.objectIds) and
			(check.checkFunction == nil or check.checkFunction(criteriaMet, check))) then
			checkComplete = true
		end
	elseif (check.targetCheck == CHECK_TYPE.PLAYER_CUSTOM) then
		if (check.checkFunction ~= nil and check.checkFunction(0, check)) then
			checkComplete = true
		end
	elseif (check.targetCheck == CHECK_TYPE.ITEM_CUSTOM) then
		if (check.checkFunction ~= nil) then
			local criteriaMet = 0
			for _, v in pairs(check.objectIds) do
				if (check.checkFunction(v, check)) then
					criteriaMet = criteriaMet + 1
				end
			end
			if (check.negateCondition and criteriaMet > 0 or criteriaMet == #check.objectIds) then
				checkComplete = true
			end
		end
	elseif (check.targetCheck == CHECK_TYPE.PLAYER_TRIGGER) then
		if (extraData ~= nil) then
			local targetObj, otherObj = -1, -1
			if (extraData.p1 ~= -1) then
				targetObj = extraData.b2
				otherObj = extraData.b1
				if (extraData.p2 ~= -1) then
					if (check.trigTargetBodyIds and in_array(targetObj, check.trigTargetBodyIds)) then
						checkComplete = true
					end
				else
					if (check.trigTargetEnvIds and in_array(targetObj, check.trigTargetEnvIds)) then
						checkComplete = true
					end
				end
			elseif (extraData.p2 ~= -1) then
				targetObj = extraData.b1
				otherObj = extraData.b2
				if (extraData.p1 ~= -1) then
					if (check.trigTargetBodyIds and in_array(targetObj, check.trigTargetBodyIds)) then
						checkComplete = true
					end
				else
					if (check.trigTargetEnvIds and in_array(targetObj, check.trigTargetEnvIds)) then
						checkComplete = true
					end
				end
			end
			if (checkComplete and check.checkFunction) then
				checkComplete = check.checkFunction(check, targetObj, otherObj)
			end
		end
	elseif (check.targetCheck == CHECK_TYPE.ITEM_TRIGGER) then
		if (extraData ~= nil and check.trigTargetEnvIds) then
			local id1, id2 = -1, -1
			if (extraData.p1 == -1 and extraData.p2 == -1) then
				for _, v in pairs(check.objectIds) do
					id1 = v
					if (extraData.b1 == v) then
						if (in_array(extraData.b2, check.trigTargetEnvIds)) then
							id2 = extraData.b2
							checkComplete = true
							break
						end
					elseif (extraData.b2 == v) then
						if (in_array(extraData.b1, check.trigTargetEnvIds)) then
							id2 = extraData.b1
							checkComplete = true
							break
						end
					end
				end
			end
			if (checkComplete and check.checkFunction) then
				checkComplete = check.checkFunction(check, id1, id2)
			end
		end
	elseif (check.targetCheck == CHECK_TYPE.PLAYER_WIN) then
		checkComplete = ws.winner == 0 and ws.match_frame < ws.game_frame
	elseif (check.targetCheck == CHECK_TYPE.PLAYER_POINTS) then
		checkComplete = get_player_info(1).injury >= check.compareValue
	elseif (check.targetCheck == CHECK_TYPE.OPPONENT_POINTS) then
		checkComplete = get_player_info(0).injury >= check.compareValue
	elseif (check.targetCheck == CHECK_TYPE.PLAYER_DISMEMBERS or check.targetCheck == CHECK_TYPE.OPPONENT_DISMEMBERS) then
		local dismembers = 0
		local playerId = check.targetCheck == CHECK_TYPE.PLAYER_DISMEMBERS and 0 or 1
		for _,v in pairs(JOINTS) do
			if (get_joint_dismember(playerId, v)) then
				dismembers = dismembers + 1
			end
		end
		checkComplete = dismembers >= check.compareValue
	elseif (check.targetCheck == CHECK_TYPE.FRAMES_ELAPSED) then
		checkComplete = (WIN_FRAME < 100000 and WIN_FRAME or ws.match_frame) > check.compareValue
	end

	if (check.negateCondition) then
		checkComplete = not checkComplete
	end
	if (checkComplete) then
		if (check.onCompleteFunc) then
			check.onCompleteFunc(check)
		end
		check.frameCompleted = ws.match_frame
		if (check.isFinal) then
			Tutorials:taskComplete()
			if (GLOBAL_SETTINGS.ALLOW_POST_CHECKPOINT_COMPLETION) then
				for _, v in pairs(checkPoints) do
					if (not v.complete and v.task ~= nil) then
						Tutorials:taskOptIncomplete(v.task)
						if (v.inverseCondition) then
							local setComplete = true
							for _, linked in pairs(v.dependsCheckpoints or {}) do
								if (checkPoints[linked].complete == false) then
									setComplete = false
									break
								end
							end
							if (setComplete) then
								Tutorials:taskOptComplete(v.task)
							end
						end
					end
				end
			else
				---Make sure we set frameCompleted for all checkpoints that have been affected
				for _, v in pairs(checkPoints) do
					if (not v.complete and v.task ~= nil) then
						v.frameCompleted = check.frameCompleted
					end
				end
			end
		elseif (targetTask) then
			if (check.inverseCondition) then
				Tutorials:taskOptIncomplete(targetTask)
				if (Tutorials.taskOptFail) then
					Tutorials:taskOptFail(targetTask)
					if (check.linkedCheckpoints) then
						for i, v in pairs(checkPoints) do
							if (in_array(i, check.linkedCheckpoints) and v.task) then
								v.complete = false
								v.failed = true
								v.frameCompleted = check.frameCompleted
								Tutorials:taskOptIncomplete(v.task)
								Tutorials:taskOptFail(v.task)
							end
						end
					end
				else
					local tasks = { targetTask }
					if (check.linkedCheckpoints) then
						for i, v in pairs(checkPoints) do
							if (in_array(i, check.linkedCheckpoints) and v.task) then
								table.insert(tasks, v.task)
							end
						end
					end
					for _, v in pairs(tbTutorialsTask.optional) do
						if (in_array(v.id, tasks)) then
							v.mark:hide(true)
							v.markFail:show(true)
							v.complete = false
							v.failed = true
							v.frameCompleted = check.frameCompleted
						end
					end
				end
			else
				Tutorials:taskOptComplete(targetTask)
			end
		end
		check.complete = true
		checkpointComplete(check)
	elseif (check.inverseCondition) then
		Tutorials:taskOptComplete(targetTask)
	end

	if (check.complete and check.allowSubmit) then
		for _, linked in pairs(check.submitDependsCheckpoints or {}) do
			if (checkPoints[linked].complete == false) then
				return
			end
		end
		WIN_FRAME = ws.match_frame
		REPLAY_CAN_BE_SUBMITTED = true
	end
end

---Initializes base event behavior
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
local function eventMain(viewElement, reqTable)
	table.insert(reqTable, { type = "eventMain", ready = false })

	require('system.replays_manager')
	if (GLOBAL_SETTINGS.WITH_TASK_TOGGLE) then
		spawnTaskToggle()
	end
	TUTORIAL_SPECIAL_RP_IGNORE = true

	if (spawnTriggerHook) then
		add_hook("mod_trigger", Tutorials.StaticHook or "tbTutorialsCustomStatic", function(p1, p2, b1, b2)
				for _, v in pairs(checkPoints) do
					if (not v.complete and (v.targetCheck == CHECK_TYPE.PLAYER_TRIGGER or v.targetCheck == CHECK_TYPE.ITEM_TRIGGER)) then
						verifyCheckpointPrerequisites(v, { p1 = p1, p2 = p2, b1 = b1, b2 = b2 })
					end
				end
			end)
	end
	loadCheckpoints(viewElement, true)
	chat_input_deactivate()

	local function isCameraModeKey(key)
		return in_array(key, { 49, 50 })
	end

	local worldstate = get_world_state()
	if (worldstate.replay_mode == 0) then
		if (worldstate.match_frame ~= 0) then
			invalidateCheckpoints()
			loadCheckpoints(viewElement)
			STOPFRAME = worldstate.match_frame
			TUTORIAL_LEAVEGAME = true
			rewind_replay()
			runCmd("zp 0")
			TUTORIAL_LEAVEGAME = false
		elseif (GLOBAL_SETTINGS.WITH_LOAD_OPENER_REPLAY == true) then
			loadReplayOpener(viewElement)
		end
	end

	if (GLOBAL_SETTINGS.WITH_TOPLIST_DISPLAY) then
		spawnToplist(viewElement)
	end
	local gameRulesScreen = nil
	add_hook("leave_game", Tutorials.StaticHook or "tbTutorialsCustomStatic", function()
			if (TUTORIAL_LEAVEGAME) then
				return 1
			end
		end)
	add_hook("key_up", Tutorials.StepHook or "tbTutorialsCustom", function(key, code)
			if ((_G.EVENT_REPLAY_ACTIVE and not isCameraModeKey(key)) or TB_MENU_INPUT_ISACTIVE) then
				return 1
			end
			---Either of ALT keys is down
			if (get_keyboard_alt() > 0) then
				return 1
			end
			local ws = get_world_state()
			---`e` key press
			if (code == 8 and ws.replay_mode ~= 0) then
				if (GLOBAL_SETTINGS.WITH_LOAD_OPENER_REPLAY == false or GLOBAL_SETTINGS.MINIMUM_STOPFRAME <= ws.match_frame) then
					TUTORIAL_LEAVEGAME = true
					STOPFRAME = -1
					edit_game()
					invalidateCheckpoints(true)
					if (not REPLAY_CAN_BE_SUBMITTED) then
						WIN_FRAME = 100000
					end
					loadCheckpoints(viewElement, true)
					TUTORIAL_LEAVEGAME = false
				end
				return 1
			end
			---`f` key press
			if (code == 9) then
				dofile("system/replay_save.lua")
				return 1
			end
			---`p` key press
			if (code == 19) then
				if (ws.replay_mode == 0) then
					return 1
				end
				if (is_mobile()) then
					toggle_game_pause(TBHud.StepSingleFramePause)
				end
			end
			---`r` key press
			if (code == 21) then
				if (ws.replay_mode == 0) then
					STOPFRAME = ws.match_frame
				end
				if (STOPFRAME == 0) then
					STOPFRAME = -1
					return 1
				end
				TUTORIAL_LEAVEGAME = true
				rewind_replay()
				runCmd("zp 0")
				TUTORIAL_LEAVEGAME = false
				return 1
			end
			---spacebar press
			if (code == 44) then
				if (ws.replay_mode == 1) then
					autosaveReplay()
					STOPFRAME = -1
					invalidateCheckpoints()
					loadCheckpoints(viewElement, true)
					WIN_FRAME = 100000
					triggerNewgame(true)
					if (GLOBAL_SETTINGS.WITH_LOAD_OPENER_REPLAY == true) then
						loadReplayOpener(viewElement)
					end
					return 1
				end
			end
			---Either of CTRL keys is down
			if (get_keyboard_ctrl() > 0) then
				---`g` key press
				if (code == 10) then
					if (gameRulesScreen) then
						gameRulesScreen:kill()
						gameRulesScreen = nil
						return 1
					end
					gameRulesScreen = TBMenu:spawnWindowOverlay(TB_TUTORIAL_MODERN_GLOBALID)
					gameRulesScreen:addMouseHandlers(nil, function() gameRulesScreen:kill() gameRulesScreen = nil end)
					local height = math.max(250, WIN_H / 4)
					local gameRulesView = gameRulesScreen:addChild({
						pos = { WIN_W / 4, (WIN_H - height) / 2 },
						size = { WIN_W / 2, height },
						bgColor = TB_MENU_DEFAULT_BG_COLOR,
						shapeType = ROUNDED,
						rounded = 5
					})
					local rulesTitle = gameRulesView:addChild({
						pos = { 50, 10 },
						size = { gameRulesView.size.w - 100, math.min(40, gameRulesView.size.h / 5) }
					})
					rulesTitle:addAdaptedText(true, TB_MENU_LOCALIZED.MAINMENUGAMERULESNAME, nil, nil, FONTS.BIG)
					local gameRulesCloseButton = gameRulesView:addChild({
						pos = { -rulesTitle.size.h - 5, 5 },
						size = { rulesTitle.size.h, rulesTitle.size.h },
						interactive = true,
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
						hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
						shapeType = ROUNDED,
						rounded = 4
					})
					gameRulesCloseButton:addChild({
						pos = { 10, 10 },
						size = { gameRulesCloseButton.size.w - 20, gameRulesCloseButton.size.h - 20 },
						bgImage = "../textures/menu/general/buttons/crosswhite.tga"
					})
					gameRulesCloseButton:addMouseUpHandler(function()
							gameRulesScreen:kill()
							gameRulesScreen = nil
						end)

					local gameRules = get_game_rules()
					local rules = {}
					table.insert(rules, { name = "Mod", value = gameRules.mod:gsub("^.*/", "") })
					table.insert(rules, { name = "Gravity", value = gameRules.gravity:gsub("^" .. ("[-]?[%.%d]*%s"):rep(2), "") })
					table.insert(rules, { name = "Dismemberment", value = gameRules.dismemberment == '1' and TB_MENU_LOCALIZED.SETTINGSENABLED or TB_MENU_LOCALIZED.SETTINGSDISABLED })
					if (gameRules.dismemberment == '1') then
						table.insert(rules, { name = "DM Threshold", value = gameRules.dismemberthreshold })
					end
					table.insert(rules, { name = "Fracture", value = gameRules.fracture == '1' and TB_MENU_LOCALIZED.SETTINGSENABLED or TB_MENU_LOCALIZED.SETTINGSDISABLED })
					if (gameRules.fracture == '1') then
						table.insert(rules, { name = "Frac Threshold", value = gameRules.fracturethreshold })
					end
					table.insert(rules, { name = "Grip", value = gameRules.grip == '1' and TB_MENU_LOCALIZED.SETTINGSENABLED or TB_MENU_LOCALIZED.SETTINGSDISABLED })

					local posY = rulesTitle.shift.y + rulesTitle.size.h
					for _, v in pairs(rules) do
						local ruleHolder = gameRulesView:addChild({
							pos = { 0, posY },
							size = { gameRulesView.size.w, (gameRulesView.size.h - rulesTitle.size.h - rulesTitle.shift.y * 2) / #rules }
						})
						posY = posY + ruleHolder.size.h
						local ruleTitle = ruleHolder:addChild({
							pos = { ruleHolder.size.w / 20, ruleHolder.size.h / 10 },
							size = { ruleHolder.size.w * 0.425, ruleHolder.size.h * 0.8 }
						})
						ruleTitle:addAdaptedText(true, v.name, nil, nil, 4, RIGHTMID)
						local ruleValue = ruleHolder:addChild({
							pos = { -ruleTitle.size.w - ruleTitle.shift.x, ruleTitle.shift.y },
							size = { ruleTitle.size.w, ruleTitle.size.h }
						})
						ruleValue:addAdaptedText(true, v.value, nil, nil, 4, LEFTMID)
					end
					return 1
				---`l` key press
				elseif (code == 15 and not EVENT_REPLAY_BROWSER_ISOPEN) then
					EVENT_REPLAY_BROWSER_ISOPEN = true
					showCustomReplaySelection(viewElement)
				end
				return 1
			end
	end)

	if (is_mobile()) then
		TBHud.ToggleReadyLongPress(GLOBAL_SETTINGS.MOBILE_LONGPRESS_ENABLED)
		TBHud.TogglePauseLongPress(GLOBAL_SETTINGS.MOBILE_LONGPRESS_ENABLED)
		setTutorialHubOverride(viewElement)
	else
		local buttonWidth = math.clamp(WIN_W / 5, 250, 400 )
		local customReplayButton = viewElement:addChild({
			pos = { WIN_W - buttonWidth - 10, WIN_H - 60 },
			size = { buttonWidth, 50 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		CUSTOM_REPLAY_BUTTON = customReplayButton
		customReplayButton.killAction = function() CUSTOM_REPLAY_BUTTON = nil end

		local customReplayButtonText = customReplayButton:addChild({
			pos = { 10, 3 },
			size = { customReplayButton.size.w - customReplayButton.size.h - 20, customReplayButton.size.h - 3 }
		})
		local customReplayButtonKillOutline = customReplayButton:addChild({
			pos = { -customReplayButton.size.h + 2, 2 },
			size = { customReplayButton.size.h - 4, customReplayButton.size.h - 4 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		}, true)
		local customReplayButtonKill = customReplayButtonKillOutline:addChild({
			shift = { 1, 1 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		}, true)
		customReplayButtonKill:addChild({
			shift = { 5, 5 },
			bgImage = "../textures/menu/general/buttons/cross.tga"
		})
		customReplayButtonText:addAdaptedText(TB_MENU_LOCALIZED.EVENTSLOADCUSTOMREPLAY)
		customReplayButton:addMouseUpHandler(function()
				showCustomReplaySelection(viewElement)
			end)
		customReplayButtonKill:addMouseUpHandler(function()
				customReplayButton:kill()
			end)
	end

	if (GLOBAL_SETTINGS.WITH_FRAMESELAPSED_DISPLAY) then
		local framesElapsed = viewElement:addChild({
			pos = { 0, 50 },
			size = { WIN_W, 30 },
			uiColor = TB_MENU_DEFAULT_YELLOW
		})
		framesElapsed:addCustomDisplay(true, function()
				local ws = get_world_state()
				if (ws.match_frame > 0 or WIN_FRAME < 100000) then
					local frame = ws.match_frame
					for _, v in pairs(checkPoints) do
						if (v.isFinal) then
							frame = (v.complete and WIN_FRAME < 100000) and WIN_FRAME or frame
							break
						end
					end
					framesElapsed:uiText(frame .. " " .. TB_MENU_LOCALIZED.EVENTFRAMESELAPSED)
				end
			end)
	end
	if (GLOBAL_SETTINGS.WITH_PLAYER_SCORE_DISPLAY) then
		local playerScore = viewElement:addChild({
			pos = { -490 - math.max(SAFE_X, 10), math.max(SAFE_Y, 3) },
			size = { 490, 40 },
			uiColor = get_color_rgba(3),
			uiShadowColor = { 1, 1, 1, 1 }
		})
		playerScore:addCustomDisplay(function()
				playerScore:uiText(tostring(math.floor(get_player_info(1).injury)), nil, nil, FONTS.BIG, RIGHT, 1, 0, 2, nil, nil, 0)
			end)
	end

	local frame_checked = -1
	add_hook("pre_draw", Tutorials.StepHook or "tbTutorialsCustom", function()
			local ws = get_world_state()
			if (STOPFRAME and STOPFRAME ~= -1) then
				if (ws.match_frame >= STOPFRAME) then
					Tutorials:editGame()
					set_ghost(2)
					STOPFRAME = -1
				end
			end
			if (ws.match_frame >= ws.game_frame + 30 or (GLOBAL_SETTINGS.WITH_WINFRAME_REWIND and ws.match_frame >= WIN_FRAME + 40)) then
				TUTORIAL_LEAVEGAME = true
				rewind_replay()
				runCmd("zp 0")
				TUTORIAL_LEAVEGAME = false
				return
			end
			if (ws.match_frame ~= frame_checked) then
				for _, check in pairs(checkPoints) do
					if (not check.complete and not check.failed) then
						verifyCheckpointPrerequisites(check)
					end
				end
				frame_checked = ws.match_frame
				if (GLOBAL_SETTINGS.ON_FRAME_CHECK_CALLBACK ~= nil) then
					local status, err = pcall(GLOBAL_SETTINGS.ON_FRAME_CHECK_CALLBACK, checkPoints)
					if (status == false) then
						Files.LogError(GLOBAL_SETTINGS.EVENT_SHORTNAME .. " frame_check callback error: " .. err)
					end
				end
			end
			if (SUBMIT_BUTTON == nil and REPLAY_CAN_BE_SUBMITTED) then
				SUBMIT_BUTTON = showSubmitButton(viewElement, reqTable)
			elseif (ws.replay_mode == 0) then
				if (SUBMIT_BUTTON and not REPLAY_CAN_BE_SUBMITTED) then
					SUBMIT_BUTTON:kill()
					SUBMIT_BUTTON = nil
				end
			end
		end)
end

---@class EventReplayStep
---@field frame integer
---@field moves integer[]
---@field grip integer[]
---@field turnLength integer

---Parses a replay file line to a steps data table
---@param line string
---@param steps EventReplayStep[]
local function parseReplaySteps(line, steps)
	if (line:find("^FRAME %d+")) then
		local rplFrameString = line:gsub("^FRAME (%d+);.*$", "%1")
		local rplFrame = tonumber(rplFrameString)
		if (rplFrame == nil) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.REPLAYERRORPARSINGDATA)
			return
		end
		if (#steps > 0) then
			if (rplFrame < steps[#steps].frame) then
				steps = {}
			end
		end
		table.insert(steps, { frame = rplFrame, moves = {}, grip = {}, turnLength = 1 })
		if (#steps ~= 1) then
			steps[#steps - 1].turnLength = steps[#steps].frame - steps[#steps - 1].frame
		end
	elseif (line:find("JOINT 0;")) then
		local jointMoves = line:gsub("JOINT 0; ", "")
		local _, count = jointMoves:gsub(" ", "")
		count = (count + 1) / 2
		local data_stream = { jointMoves:match(("(%d+ %d+) *"):rep(count)) }
		for _, v in pairs(data_stream) do
			local info = { v:match(("(%d+) *"):rep(2)) }
			steps[#steps].moves[info[1] + 0] = info[2] + 0
		end
	elseif (line:find("GRIP 0;")) then
		local gripChanges = line:gsub("GRIP 0; ", "")
		local data_stream = { gripChanges:match(("(%d) ?"):rep(2)) }
		if (data_stream[1] ~= '0') then
			steps[#steps].grip[12] = data_stream[1] == '1' and 1 or 0
		end
		if (data_stream[2] ~= '0') then
			steps[#steps].grip[11] = data_stream[2] == '1' and 1 or 0
		end
	end
end

---Loads a premade replay as event entry
---@param viewElement UIElement
---@param rplFile? string
---@param regenerateMoves? boolean
loadExistingReplay = function(viewElement, rplFile, regenerateMoves)
	local replay = Files.Open(rplFile and ("../replay/" .. rplFile) or ("../replay/my replays/--eventtmp" .. CURRENT_TUTORIAL .. ".rpl"))
	if (not replay.data) then
		Files.LogError("failed to open event replay " .. replay.path)
		return
	end

	invalidateCheckpoints()
	loadCheckpoints(viewElement, true)
	local rplData = replay:readAll()
	replay:close()

	---@type EventReplayStep[]
	local steps = {}
	for _, ln in pairs(rplData) do
		parseReplaySteps(ln, steps)
	end

	if (GLOBAL_SETTINGS.WITH_LOAD_OPENER_REPLAY) then
		---Compare first frames with the opener replay
		local openerReplay = Files.Open("../replay/system/events/" .. CURRENT_TUTORIAL .. ".rpl")
		if (not openerReplay.data) then
			TBMenu:showStatusMessage(TB_MENU_LOCALIZED.EVENTSERRORLOADINGOPENER)
			return
		end

		rplData = openerReplay:readAll()
		openerReplay:close()

		---@type EventReplayStep[]
		local openerSteps = {}
		for _, ln in pairs(rplData) do
			parseReplaySteps(ln, openerSteps)
		end

		for i, v in pairs(openerSteps) do
			if (v.frame >= GLOBAL_SETTINGS.MINIMUM_STOPFRAME) then break end
			---Make sure last opener step doesn't throw comparison error because its turn length is 1
			v.turnLength = steps[i] == nil and v.turnLength or steps[i].turnLength
			if (table.equals(v, steps[i]) == false) then
				TBMenu:showStatusMessage(TB_MENU_LOCALIZED.EVENTSERRORVERIFYINGOPENER)
				STOPFRAME = -1
				invalidateCheckpoints()
				loadCheckpoints(viewElement, true)
				WIN_FRAME = 100000
				triggerNewgame(true)
				loadReplayOpener(viewElement)
				return
			end
		end
	end

	_G.EVENT_REPLAY_ACTIVE = true
	local replay_path = string.gsub(replay.path, "^replay/", "")

	if (regenerateMoves) then
		local current_step = 1
		local function doStepMoves()
			local step = steps[current_step]
			for i,v in pairs(step.moves) do
				set_joint_state(0, i, v)
			end
			for i,v in pairs(step.grip) do
				set_grip_info(0, i, v)
			end
			step_game(true, true)
			current_step = current_step + 1
		end
		add_hook("post_draw3d", Tutorials.StaticHook or "tbTutorialsCustomStatic", function()
				_G.EVENT_REPLAY_ACTIVE = true
				local ws = get_world_state()
				if (ws.match_frame == GLOBAL_SETTINGS.MINIMUM_STOPFRAME) then
					_G.EVENT_REPLAY_ACTIVE = false
					remove_hook("post_draw3d", Tutorials.StaticHook or "tbTutorialsCustomStatic")
					STOPFRAME = -1
					return
				end
				if (current_step > #steps or ws.match_frame < steps[current_step].frame) then
					---Keep stepping until we reach the target frame or minimum stopframe
					step_game(true, true)
				elseif (ws.match_frame == steps[current_step].frame) then
					doStepMoves()
				end
			end)
		return
	end

	local function enterGameMode()
		_G.EVENT_REPLAY_ACTIVE = false
		remove_hook("enter_frame", Tutorials.StaticHook or "tbTutorialsCustomStatic")
		remove_hook("replay_integrity_fail", Tutorials.StaticHook or "tbTutorialsCustomStatic")
		freeze_game()
		Tutorials:editGame()
		set_ghost(2)
		STOPFRAME = -1
	end

	TUTORIAL_LEAVEGAME = true
	if (GLOBAL_SETTINGS.WITH_VERIFY_REPLAY_INTEGRITY) then
		local integrity_fail_start = 0
		add_hook("replay_integrity_fail", Tutorials.StaticHook or "tbTutorialsCustomStatic", function(frame)
				if (integrity_fail_start ~= 0) then
					enterGameMode()
					TBMenu:showStatusMessage(TB_MENU_LOCALIZED.EVENTSREPLAYINTEGRITYFAILATFRAME .. " " .. integrity_fail_start)
					add_hook("post_draw3d", Tutorials.StaticHook or "tbTutorialsCustomStatic", function()
							remove_hook("post_draw3d", Tutorials.StaticHook or "tbTutorialsCustomStatic")
							triggerNewgame()
							if (GLOBAL_SETTINGS.WITH_LOAD_OPENER_REPLAY == true) then
								loadReplayOpener(viewElement)
							end
						end)
					return 1
				end
				integrity_fail_start = frame
				return 0
			end)
		open_replay(replay_path, 0, 0.1)
	else
		open_replay(replay_path)
	end
	freeze_game()
	runCmd("zp 0")
	TUTORIAL_LEAVEGAME = false

	-- Make sure one-turn replays work correctly
	local targetFrame = math.max(steps[#steps].frame, 1)
	run_frames(targetFrame)
	add_hook("enter_frame", Tutorials.StaticHook or "tbTutorialsCustomStatic", function()
			_G.EVENT_REPLAY_ACTIVE = true
			for _, check in pairs(checkPoints) do
				if (not check.complete and not check.failed) then
					verifyCheckpointPrerequisites(check)
				end
			end
			if (get_world_state().match_frame == targetFrame) then
				enterGameMode()
			end
		end)
end

---Initializes checkpoints and loads player's last autosaved replay
---@param viewElement UIElement
local function loadReplayWithCheckpoints(viewElement)
	loadCheckpoints(viewElement, true)
	loadExistingReplay(viewElement)
end

---Similar to `loadReplayWithCheckpoints()`, initializes checkpoints and loads the challenge opener by regenerating moves
---@param viewElement UIElement
loadReplayOpener = function(viewElement)
	loadCheckpoints(viewElement, true)
	loadExistingReplay(viewElement, "system/events/" .. CURRENT_TUTORIAL .. ".rpl", true)
end

---Exports current player behavior to Discord
local function setDiscordRPC()
	set_discord_rpc(GLOBAL_SETTINGS.EVENT_NAME, TB_MENU_LOCALIZED.DISCORDRPCPLAYINGSPEVENT)
end

---Loads the event mod
triggerNewgame = function(noClassicReset)
	TUTORIAL_LEAVEGAME = true
	if (GLOBAL_SETTINGS.WITH_LOAD_OPENER_REPLAY == false) then
		if (not noClassicReset and get_world_state().replay_mode ~= 0) then
			runCmd("lm classic")
		end
		runCmd("lm system/events/" .. CURRENT_TUTORIAL .. ".tbm")
	else
		runCmd("lm classic")
		if (GLOBAL_SETTINGS.MOD_OVERRIDE ~= "classic") then
			runCmd("lm system/events/" .. (GLOBAL_SETTINGS.MOD_OVERRIDE or (CURRENT_TUTORIAL .. ".tbm")))
		end
		if (GLOBAL_SETTINGS.GAMERULE_OVERRIDES ~= nil) then
			for i, v in pairs(GLOBAL_SETTINGS.GAMERULE_OVERRIDES) do
				set_gamerule(i, v)
			end
			runCmd("reset")
		end
	end
	TUTORIAL_LEAVEGAME = false
end

---Displays overlay with "*Please wait...*" text
---@param viewElement UIElement
local function showLoadingOverlay(viewElement)
	if (SAFE_X == nil) then
		local safe_x, safe_y, safe_w, safe_h = get_window_safe_size()
		SAFE_X = math.max(safe_x, WIN_W - safe_w - safe_x)
		SAFE_Y = math.max(safe_y, WIN_H - safe_h - safe_y)
	end

	local overlay = viewElement:addChild({ bgColor = { 1, 1, 1, 1 } })
	local loadingText = overlay:addChild({
		pos = { 0, viewElement.size.h - 50 - SAFE_Y },
		size = { overlay.size.w - SAFE_X, 50 }
	})
	loadingText:addAdaptedText(true, TB_MENU_LOCALIZED.MESSAGEPLEASEWAIT, nil, nil, 4, RIGHTBOT)
end

---Startup function. Does some preliminary checks and sets the mod to prepare for main event behavior.
---@param viewElement UIElement
---@param reqTable TutorialStepRequirement[]
local function launchGame(viewElement, reqTable)
	if (not verifyVersionLogin(viewElement, reqTable)) then
		return
	end

	showLoadingOverlay(viewElement)

	local req = { type = "newgame", ready = false }
	table.insert(reqTable, req)
	setDiscordRPC()

	REPLAY_CAN_BE_SUBMITTED = false
	WIN_FRAME = 100000

	triggerNewgame()

	TUTORIAL_LEAVEGAME = true
	local wipReplay = Files.Open("../replay/my replays/--eventtmp" .. CURRENT_TUTORIAL .. ".rpl")
	if (wipReplay.data) then
		for _, ln in pairs(wipReplay:readAll()) do
			if (ln:find("^JOINT")) then
				CURRENT_STEP.skip = GLOBAL_SETTINGS.HAS_REPLAY_STEPSKIP
				wipReplay:close()
				break
			end
		end
	end

	local reqElement = viewElement:addChild({ size = { 0, 0 } })
	reqElement:addCustomDisplay(true, function()
			req.ready = true
			reqTable.ready = Tutorials:checkRequirements(reqTable)
			reqElement:kill()
			TUTORIAL_LEAVEGAME = false
		end)
end

return {
	InitCheckpoints = loadCheckpoints,
	PrepareNewGame = launchGame,
	TriggerNewGame = triggerNewgame,
	LoadReplay = loadReplayWithCheckpoints,
	EventMain = eventMain,
	UploadEventEntry = showUploadWindow,
	WaitLoadReplay = showLoadingOverlay
}
