---OC-DM2
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

---@class EventTemplateData
---@field CHECKPOINTS EventCheckpoint[]
_T = {
	GLOBAL_SETTINGS = {
		WITH_TOPLIST_DISPLAY = false,
		WITH_FRAMESELAPSED_DISPLAY = false,
		WITH_TASK_TOGGLE = true,
		WITH_TASK_AUTOHIDE = true,
		WITH_WINFRAME_REWIND = false,
		WITH_VERIFY_REPLAY_INTEGRITY = true,
		WITH_RESEED_CHECKPOINTS = false,
		WITH_LOAD_OPENER_REPLAY = true,
		HAS_REPLAY_STEPSKIP = 7,
		MINIMUM_STOPFRAME = 50,
		ALLOW_POST_CHECKPOINT_COMPLETION = true,
		MOBILE_LONGPRESS_ENABLED = true,
		MOD_OVERRIDE = "classic",
		GAMERULE_OVERRIDES = {
			engagedistance = "250",
			matchframes = "1500"
		},
		MIN_VERSION = 5.74,
		EVENT_NAME = "Opener Challenge",
		EVENT_SHORTNAME = "oc8",
		WITH_SUBMISSION_DEFAULT_NAME = true,
		IS_STATIC_EVENT = true,
		ON_FRAME_CHECK_CALLBACK = nil
	},
	MIN_CHECKPOINT_JOINTS = 20,
	MIN_CHECKPOINT_OBJECTS = 1,
	CUSTOM_VISUALS = nil,
	CHECKPOINTS = {
		{
			visible = false,
			costModifier = 1,
			task = 1,
			targetCheck = CHECK_TYPE.OPPONENT_DISMEMBERS,
			compareValue = 1,
			allowSubmit = true
		},
		{
			visible = false,
			costModifier = 1,
			task = 2,
			targetCheck = CHECK_TYPE.OPPONENT_DISMEMBERS,
			compareValue = 3
		},
		{
			visible = false,
			costModifier = 1,
			task = 3,
			targetCheck = CHECK_TYPE.OPPONENT_DISMEMBERS,
			compareValue = 10
		},
		{
			visible = false,
			costModifier = 0,
			isFinal = true,
			targetCheck = CHECK_TYPE.OPPONENT_DISMEMBERS,
			compareValue = 10
		}
	}
}

return dofile("events/template.lua")
