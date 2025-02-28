---OC-SPD1
---@diagnostic disable: duplicate-doc-alias, duplicate-doc-field

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

local velocityUpdate = function(_, check, target)
	local ws = get_world_state()
	if (ws.match_frame <= 130) then return false end
	if (tbTutorialsTask.misc[check.task] == nil) then
		tbTutorialsTask.misc[check.task] = { }
	end

	local maxVelocity = 0
	for _, v in pairs(BODYPARTS) do
		local x, y, z = get_body_linear_vel(0, v)
		maxVelocity = math.max(maxVelocity, math.floor(math.sqrt(x * x + y * y + z * z) * 100) / 100)
	end
	local maxStoredVelocity = tbTutorialsTask.misc[check.task].last

	if (maxStoredVelocity ~= nil and maxStoredVelocity.value >= maxVelocity) then
		return maxStoredVelocity.value >= target
	end

	table.insert(tbTutorialsTask.misc[check.task], {
		frame = ws.match_frame, value = maxVelocity
	})
	local lastID = #tbTutorialsTask.misc[check.task]
	tbTutorialsTask.misc[check.task].last = tbTutorialsTask.misc[check.task][lastID]
	return maxVelocity >= target
end

local velocityCachedUpdate = function(target)
	if (tbTutorialsTask.misc[4] == nil or tbTutorialsTask.misc[4].last == nil) then
		return false
	end
	return tbTutorialsTask.misc[4].last.value >= target
end

local velocityReset = function(check, frame, target)
	if (tbTutorialsTask.misc[check.task] == nil) then return end
	local lastID = #tbTutorialsTask.misc[check.task]
	for i = lastID, 1, -1 do
		if (tbTutorialsTask.misc[check.task][i].frame > frame) then
			lastID = lastID - 1
			table.remove(tbTutorialsTask.misc[check.task], i)
			tbTutorialsTask.misc[check.task].last = tbTutorialsTask.misc[check.task][lastID]
		end
	end
	if (tbTutorialsTask.misc[check.task].last == nil or tbTutorialsTask.misc[check.task].last.value < target) then
		return true
	end
	return false
end

_T = {
	GLOBAL_SETTINGS = {
		WITH_TOPLIST_DISPLAY = false,
		WITH_FRAMESELAPSED_DISPLAY = false,
		WITH_TASK_TOGGLE = true,
		WITH_TASK_AUTOHIDE = false,
		WITH_WINFRAME_REWIND = false,
		WITH_VERIFY_REPLAY_INTEGRITY = true,
		WITH_RESEED_CHECKPOINTS = false,
		WITH_LOAD_OPENER_REPLAY = true,
		HAS_REPLAY_STEPSKIP = 7,
		MINIMUM_STOPFRAME = 130,
		ALLOW_POST_CHECKPOINT_COMPLETION = true,
		MOBILE_LONGPRESS_ENABLED = true,
		MOD_OVERRIDE = "classic",
		GAMERULE_OVERRIDES = {
			engagedistance = "274",
			matchframes = "1500",
			dismemberthreshold = "100"
		},
		MIN_VERSION = 5.74,
		EVENT_NAME = "Opener Challenge",
		EVENT_SHORTNAME = "oc7",
		WITH_SUBMISSION_DEFAULT_NAME = true,
		IS_STATIC_EVENT = true,
		ON_FRAME_CHECK_CALLBACK = function(checkPoints)
			if (EventsOnline.TaskView ~= nil and EventsOnline.LocalizedMessages ~= nil) then
				if (tbTutorialsTask.misc[checkPoints[1].task] == nil or tbTutorialsTask.misc[checkPoints[1].task].last == nil) then
					return
				end
				local last = tbTutorialsTask.misc[checkPoints[1].task].last
				local msg = EventsOnline.LocalizedMessages.EVTTASK1
				if (last ~= nil and last.frame > 130) then
					msg = utf8.gsub(EventsOnline.LocalizedMessages.EVTTASKDETAILED, "{x}", tostring(last.value))
					local maxVelocity = 0
					for _, v in pairs(BODYPARTS) do
						local x, y, z = get_body_linear_vel(0, v)
						maxVelocity = math.max(maxVelocity, math.floor(math.sqrt(x * x + y * y + z * z) * 100) / 100)
					end
					msg = utf8.gsub(msg, "{x2}", tostring(maxVelocity))
				end
				EventsOnline.TaskView:addAdaptedText(true, msg, nil, nil, EventsOnline.TaskView.textFont, LEFTMID, EventsOnline.TaskView.textScale)
			end
		end
	},
	MIN_CHECKPOINT_JOINTS = 20,
	MIN_CHECKPOINT_OBJECTS = 1,
	CUSTOM_VISUALS = nil,
	CHECKPOINTS = {
		{
			visible = false,
			costModifier = 0,
			task = 4,
			targetCheck = CHECK_TYPE.PLAYER_CUSTOM,
			checkFunction = function(_, check) return velocityUpdate(_, check, 10000) end,
			invalidateFunc = function(check, frame) return velocityReset(check, frame, 10000) end,
		},
		{
			visible = false,
			costModifier = 1,
			task = 1,
			targetCheck = CHECK_TYPE.PLAYER_CUSTOM,
			checkFunction = function() return velocityCachedUpdate(40) end,
			invalidateFunc = function(check, frame) return velocityReset(check, frame, 40) end,
			allowSubmit = true
		},
		{
			visible = false,
			costModifier = 1,
			task = 2,
			targetCheck = CHECK_TYPE.PLAYER_CUSTOM,
			checkFunction = function() return velocityCachedUpdate(50) end,
			invalidateFunc = function(check, frame) return velocityReset(check, frame, 50) end
		},
		{
			visible = false,
			costModifier = 1,
			task = 3,
			targetCheck = CHECK_TYPE.PLAYER_CUSTOM,
			checkFunction = function() return velocityCachedUpdate(65) end,
			invalidateFunc = function(check, frame) return velocityReset(check, frame, 65) end
		},
		{
			isFinal = true,
			visible = false,
			costModifier = 0,
			targetCheck = CHECK_TYPE.PLAYER_CUSTOM,
			checkFunction = function() return true end,
			dependsCheckpoints = { 3 }
		},
	}
}

return dofile("events/template.lua")
