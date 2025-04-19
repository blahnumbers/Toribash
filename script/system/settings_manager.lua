---@alias SettingsScreen
---| 1 SETTINGS_GRAPHICS
---| 2 SETTINGS_EFFECTS
---| 3 SETTINGS_AUDIO
---| 4 SETTINGS_OTHER
local SETTINGS_GRAPHICS = 1
local SETTINGS_EFFECTS = 2
local SETTINGS_AUDIO = 3
local SETTINGS_OTHER = 4

---@alias SettingControlType
---| 1 TOGGLE
---| 2 SLIDER
---| 3 DROPDOWN
---| 4 INPUT
---| 5 BUTTON
local TOGGLE = 1
local SLIDER = 2
local DROPDOWN = 3
local INPUT = 4
local BUTTON = 5

local SHADERS = 0
local FLUIDBLOOD = 1
local REFLECTIONS = 2
local SOFTSHADOWS = 3
local AMBIENTOCCLUSION = 4
local BUMPMAPPING = 5
local RAYTRACING = 6
local BODYTEXTURES = 7
local HIGHDPI = 8
local BORDERLESS = 9
local ITEMEFFECTS = 10
local DPISCALE_APPLE = 11

if (Settings == nil) then
	---**Settings manager class*
	---
	---**Version 5.63**
	---* Added `Settings.GetLevel()` to get an approximated settings level
	---* Some updates to better match modern code style
	---@class Settings
	---@field ListShift number[]
	---@field ApplyButton UIElement|nil
	Settings = {
		ListShift = { 0, 0, 1 },
		ApplyButton = nil,
		Stored = {}
	}
	Settings.__index = Settings
end

function Settings.Quit()
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
	TB_MENU_SETTINGS_SCREEN_ACTIVE = 1
	TBMenu:clearNavSection()
	TBMenu:showNavigationBar()
	TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
end

function Settings:getNavigationButtons()
	local navigation = {
		{
			text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
			action = Settings.Quit,
		},
		{
			text = TB_MENU_LOCALIZED.SETTINGSABOUT,
			right = true,
			sectionId = -1,
			action = function()
					Settings:showAbout()
				end
		},
		{
			text = TB_MENU_LOCALIZED.SETTINGSOTHER,
			right = true,
			sectionId = SETTINGS_OTHER,
			action = function()
					Settings:showSettings(SETTINGS_OTHER)
				end
		},
		{
			text = TB_MENU_LOCALIZED.SETTINGSAUDIO,
			right = true,
			sectionId = SETTINGS_AUDIO,
			action = function()
					Settings:showSettings(SETTINGS_AUDIO)
				end
		},
		{
			text = TB_MENU_LOCALIZED.SETTINGSEFFECTS,
			right = true,
			sectionId = SETTINGS_EFFECTS,
			action = function()
					Settings:showSettings(SETTINGS_EFFECTS)
				end
		},
		{
			text = TB_MENU_LOCALIZED.SETTINGSGRAPHICS,
			right = true,
			sectionId = SETTINGS_GRAPHICS,
			action = function()
					Settings:showSettings(SETTINGS_GRAPHICS)
				end
		}
	}
	return navigation
end

function Settings:showAbout()
	usage_event("settingsabout")
	TBMenu.UserBar:hide()
	UIScrollbarIgnore = true
	local whiteOverlay = UIElement:new({
		parent = TBMenu.MenuMain,
		pos = { 0, 0 },
		size = { WIN_W, WIN_H },
		bgColor = table.clone(UICOLORWHITE),
		interactive = true
	})
	whiteOverlay.killAction = function() UIScrollbarIgnore = false end
	local slowMode = false
	local speedMultiplier = get_option('framerate') == 30 and 2 or 1
	whiteOverlay:addMouseHandlers(nil, function()
			whiteOverlay:kill()
			TBMenu.UserBar:show()
		end, function() slowMode = false end)
	local aboutMover = UIElement:new({
		parent = whiteOverlay,
		pos = { WIN_W / 5, WIN_H },
		size = { WIN_W / 5 * 3, 1 },
		uiColor = UICOLORBLACK
	})
	aboutMover:addCustomDisplay(true, function()
		aboutMover:moveTo(nil, slowMode and math.ceil(-WIN_H / 1400 * speedMultiplier) or math.ceil(-WIN_H / 700 * speedMultiplier), true)
	end)
	local tbLogo = UIElement:new({
		parent = aboutMover,
		pos = { aboutMover.size.w / 2 - 128, 0 },
		size = { 256, 256 },
		bgImage = "../textures/menu/logos/toribash_legacy.tga"
	})
	local tbGameTitle = UIElement:new({
		parent = aboutMover,
		pos = { aboutMover.size.w / 2 - 200, tbLogo.shift.y + tbLogo.size.h - 40 },
		size = { 400, 100 },
		bgImage = "../textures/menu/logos/toribashgametitle_legacy.tga"
	})
	local tbDevelopedNabi = UIElement:new({
		parent = aboutMover,
		pos = { 0, tbGameTitle.shift.y + tbGameTitle.size.h },
		size = { aboutMover.size.w, 50 },
		uiColor = UICOLORWHITE
	})
	tbDevelopedNabi:addAdaptedText(true, "Developed by Nabi Studios", nil, nil, FONTS.BIG, nil, 0.65, nil, nil, 2)
	local tbToribashTeam = UIElement:new({
		parent = aboutMover,
		pos = { 0, tbDevelopedNabi.shift.y + tbDevelopedNabi.size.h + 50 },
		size = { aboutMover.size.w, 40 },
	})
	tbToribashTeam:addAdaptedText(true, "Current Team", nil, nil, FONTS.BIG, nil, nil, nil, 0.2)

	-- Keep hampa in the middle and others on sides
	local tbTeam = { 'hampa', 'sir' }
	local teamScale = math.min(256, aboutMover.size.w / #tbTeam)
	for i, v in pairs(tbTeam) do
		local teamMember = UIElement:new({
			parent = aboutMover,
			pos = { aboutMover.size.w / 2 - #tbTeam / 2 * teamScale + (i - 1) * teamScale, tbToribashTeam.shift.y + tbToribashTeam.size.h },
			size = { teamScale, teamScale },
			bgImage = "../textures/menu/about/" .. v .. ".tga"
		})
		local teamMemberName = UIElement:new({
			parent = teamMember,
			pos = { 0, 0 },
			size = { teamMember.size.w, teamMember.size.h },
			uiColor = UICOLORWHITE
		})
		teamMemberName:addAdaptedText(true, v, nil, nil, FONTS.BIG, CENTERBOT, 0.7, nil, nil, 4)
	end


	local tbSpecialThanks = UIElement:new({
		parent = aboutMover,
		pos = { 0, tbToribashTeam.shift.y + tbToribashTeam.size.h + teamScale + 60 },
		size = { aboutMover.size.w, 40 },
	})
	tbSpecialThanks:addAdaptedText(true, "Special Thanks To", nil, nil, FONTS.BIG, nil, nil, nil, 0.2)

	local tbMusicBy = UIElement:new({
		parent = aboutMover,
		pos = { 0, tbSpecialThanks.shift.y + tbSpecialThanks.size.h + 20 },
		size = { aboutMover.size.w, 60 },
		--interactive = true,
		bgColor = UICOLORWHITE,
		hoverColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
		shapeType = ROUNDED,
		rounded = 15
	})
	local tbMusicTMMRW = UIElement:new({
		parent = tbMusicBy,
		pos = { 0, 0 },
		size = { tbMusicBy.size.w, 35 }
	})
	tbMusicTMMRW:addAdaptedText(true, "Jacob \"TMMRW\" Milo", nil, nil, FONTS.BIG)
	-- Looks like our guy is no longer on soundcloud, credit but don't put up a link
	--TBMenu:showTextWithImage(tbMusicTMMRW, "Jacob \"TMMRW\" Milo", FONTS.BIG, 30, "../textures/menu/logos/soundcloud.tga")
	--tbMusicBy:addMouseHandlers(nil, function() open_url("https://soundcloud.com/TMMRW") end, function() slowMode = true end)
	local tbMusicDesc = UIElement:new({
		parent = tbMusicBy,
		pos = { 0, tbMusicTMMRW.size.h },
		size = { tbMusicBy.size.w, tbMusicBy.size.h - tbMusicTMMRW.size.h }
	})
	tbMusicDesc:addAdaptedText(true, "for making Toribash background music")

	local tbStaff = UIElement:new({
		parent = aboutMover,
		pos = { 0, tbMusicBy.size.h + tbMusicBy.shift.y + 40 },
		size = { aboutMover.size.w, 35 }
	})
	tbStaff:addAdaptedText(true, "Toribash Staff", nil, nil, FONTS.BIG)
	local tbStaffAbout = UIElement:new({
		parent = aboutMover,
		pos = { 0, tbMusicBy.size.h + tbMusicBy.shift.y + 40 + tbStaff.size.h },
		size = { aboutMover.size.w, 25 }
	})
	tbStaffAbout:addAdaptedText(true, "for helping us maintain Toribash across the years")

	local tbPlayer = UIElement:new({
		parent = aboutMover,
		pos = { 0, tbStaffAbout.size.h + tbStaffAbout.shift.y + 40 },
		size = { aboutMover.size.w, 35 }
	})
	tbPlayer:addAdaptedText(true, TB_MENU_PLAYER_INFO.username == '' and "and all the players" or ("and you, " .. TB_MENU_PLAYER_INFO.username), nil, nil, FONTS.BIG)
	local tbPlayerThanks = UIElement:new({
		parent = aboutMover,
		pos = { 0, tbPlayer.size.h + tbPlayer.shift.y},
		size = { aboutMover.size.w, 25 }
	})
	tbPlayerThanks:addAdaptedText(true, "for playing Toribash!")

	local lastElement = UIElement:new({
		parent = tbPlayerThanks,
		pos = { 0, 0 },
		size = { tbPlayerThanks.size.w, tbPlayerThanks.size.h }
	})
	local function initOutro()
		local initTime = UIElement.clock
		whiteOverlay:addCustomDisplay(false, function()
				whiteOverlay.bgColor[4] = UITween.SineTween(1, 0, (UIElement.clock - initTime) * 2);
				if (whiteOverlay.bgColor[4] <= 0) then
					whiteOverlay:kill()
					TBMenu.UserBar:show()
				end
			end)
	end
	lastElement:addCustomDisplay(false, function()
			if (lastElement.pos.y + lastElement.size.h <= 0) then
				lastElement:kill()
				initOutro()
			end
		end)
end

function Settings:getSettingsData(id)
	local shaders = Settings.Stored.shaders and Settings.Stored.shaders.value or get_option("shaders")

	if (id == SETTINGS_GRAPHICS) then
		local advancedItems = {
			{
				name = TB_MENU_LOCALIZED.SETTINGSSHADERS,
				type = TOGGLE,
				action = function(val)
						Settings.Stored.shaders = { value = val, id = SHADERS, graphics = true }
						Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
					end,
				val = { Settings.Stored.shaders and Settings.Stored.shaders.value or get_option("shaders") },
				reload = true,
				hidden = is_mobile()
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSRAYTRACING,
				type = TOGGLE,
				action = function(val)
						Settings.Stored.raytracing = { value = val, id = RAYTRACING, graphics = true }
					end,
				val = { get_option("raytracing") },
				reload = true,
				hidden = shaders == 0
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSFRAMERATE,
				type = DROPDOWN,
				selectedAction = function()
						local framerate = get_option("framerate")
						--local fixedframerate = get_option("fixedframerate")
						--if (fixedframerate == 1) then
							if (not is_mobile() and framerate == 75) then
								return 3
							elseif (framerate == 60) then
								return 2
							end
							return 1
						--end
						--return 4
					end,
				dropdown = {
					{
						text = "30 " .. TB_MENU_LOCALIZED.SETTINGSFPS,
						action = function()
								Settings.Stored.framerate = { value = 30 }
								Settings.Stored.fixedframerate = { value = 1 }
								Settings:settingsApplyActivate()
							end
					},
					{
						text = "60 " .. TB_MENU_LOCALIZED.SETTINGSFPS,
						action = function()
								Settings.Stored.framerate = { value = 60 }
								Settings.Stored.fixedframerate = { value = 1 }
								Settings:settingsApplyActivate()
							end
					},
					{
						text = "75 " .. TB_MENU_LOCALIZED.SETTINGSFPS,
						action = function()
								Settings.Stored.framerate = { value = 75 }
								Settings.Stored.fixedframerate = { value = 1 }
								Settings:settingsApplyActivate()
							end,
						hidden = is_mobile()
					}
					--[[{
						text = TB_MENU_LOCALIZED.SETTINGSFPSUNCAPPED,
						action = function()
								Settings.Stored.framerate = { value = 60 }
								Settings.Stored.fixedframerate = { value = 0 }
								Settings:settingsApplyActivate()
							end
					}]]
				}
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSBLOOD,
				type = DROPDOWN,
				selectedAction = function() return Settings.Stored.blood and Settings.Stored.blood.value + 1 or get_option("blood") + 1 end,
				dropdown = {
					{
						text = TB_MENU_LOCALIZED.WORDNONE,
						action = function()
							Settings.Stored.blood = { value = 0 }
							Settings:settingsApplyActivate()
							Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
						end
					},
					{
						text = TB_MENU_LOCALIZED.SETTINGSVANILLA,
						action = function()
							Settings.Stored.blood = { value = 1 }
							Settings:settingsApplyActivate()
							Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
						end
					},
					{
						text = TB_MENU_LOCALIZED.SETTINGSMODERN,
						action = function()
							Settings.Stored.blood = { value = 2 }
							Settings:settingsApplyActivate()
							Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
						end
					},
				}
			}
		}

		if (shaders == 1) then
			if ((Settings.Stored.blood and Settings.Stored.blood.value or get_option("blood")) > 0) then
				table.insert(advancedItems, {
					name = TB_MENU_LOCALIZED.SETTINGSFLUIDBLOOD,
					type = DROPDOWN,
					selectedAction = function()
						local targetValue = Settings.Stored.fluid and Settings.Stored.fluid.value or get_option("fluid")
						if (targetValue == 2) then return 2 end
						if (targetValue == 1) then return 3 end
						return 1
					end,
					dropdown = {
						{
							text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
							action = function()
								Settings.Stored.fluid = { value = 0, id = FLUIDBLOOD, graphics = true }
								Settings:settingsApplyActivate()
							end
						},
						{
							text = TB_MENU_LOCALIZED.SETTINGSQUALITYLOW,
							action = function()
								Settings.Stored.fluid = { value = 2, id = FLUIDBLOOD, graphics = true }
								Settings:settingsApplyActivate()
							end
						},
						{
							text = TB_MENU_LOCALIZED.SETTINGSQUALITYHIGH,
							action = function()
								Settings.Stored.fluid = { value = 1, id = FLUIDBLOOD, graphics = true }
								Settings:settingsApplyActivate()
							end
						}
					},
					reload = true
				})
				table.insert(advancedItems, {
					name = TB_MENU_LOCALIZED.SETTINGSBLOODSTAINS,
					type = TOGGLE,
					action = function(val)
							Settings.Stored.bloodstains = { value = val }
						end,
					val = { Settings.Stored.bloodstains and Settings.Stored.bloodstains.value or get_option("bloodstains") },
				})
			end
			table.insert(advancedItems, {
				name = TB_MENU_LOCALIZED.SETTINGSFLOORREFLECTIONS,
				type = TOGGLE,
				action = function(val)
						Settings.Stored.reflection = { value = val, id = REFLECTIONS, graphics = true }
					end,
				val = { Settings.Stored.reflection and Settings.Stored.reflection.value or get_option("reflection") },
				reload = true
			})
			table.insert(advancedItems, {
				name = TB_MENU_LOCALIZED.SETTINGSSOFTSHADOWS,
				type = TOGGLE,
				action = function(val)
						Settings.Stored.softshadow = { value = val, id = SOFTSHADOWS, graphics = true }
					end,
				val = { Settings.Stored.softshadow and Settings.Stored.softshadow.value or get_option("softshadow") },
				reload = true
			})
			table.insert(advancedItems, {
				name = TB_MENU_LOCALIZED.SETTINGSAMBIENTOCCLUSION,
				type = TOGGLE,
				action = function(val)
						Settings.Stored.ambientocclusion = { value = val, id = AMBIENTOCCLUSION, graphics = true }
					end,
				val = { Settings.Stored.ambientocclusion and Settings.Stored.ambientocclusion.value or get_option("ambientocclusion") },
				reload = true
			})
			--[[table.insert(advancedItems, {
				name = TB_MENU_LOCALIZED.SETTINGSBUMPMAPPING,
				type = TOGGLE,
				action = function(val)
						Settings.Stored.bumpmapping = { value = val, id = BUMPMAPPING, graphics = true }
					end,
				val = { Settings.Stored.bumpmapping and Settings.Stored.bumpmapping.value or get_option("bumpmapping") },
				reload = true
			})]]
		end

		table.insert(advancedItems, {
			name = TB_MENU_LOCALIZED.SETTINGSTEXTUREQUALITY,
			type = DROPDOWN,
			selectedAction = function()
				local targetValue = Settings.Stored.mipmaplevels and Settings.Stored.mipmaplevels.value or (4 - (tonumber(get_option("mipmaplevels")) or 1))
				return math.clamp(targetValue, 1, 3)
			end,
			dropdown = {
				{
					text = TB_MENU_LOCALIZED.SETTINGSMIPMAPPERFORMANCE,
					action = function()
						Settings.Stored.mipmaplevels = { value = 3 }
						Settings:settingsApplyActivate()
					end
				},
				{
					text = TB_MENU_LOCALIZED.SETTINGSMIPMAPBALANCED,
					action = function()
						Settings.Stored.mipmaplevels = { value = 2 }
						Settings:settingsApplyActivate()
					end
				},
				{
					text = TB_MENU_LOCALIZED.SETTINGSMIPMAPQUALITY,
					action = function()
						Settings.Stored.mipmaplevels = { value = 1 }
						Settings:settingsApplyActivate()
					end
				}
			}
		})

		return {
			{
				name = TB_MENU_LOCALIZED.SETTINGSGRAPHICSPRESETS,
				items = {
					{
						name = TB_MENU_LOCALIZED.SETTINGSVISUALSQUALITY,
						type = DROPDOWN,
						selectedAction = Settings:getGraphicsPreset(),
						dropdown = {
							{
								text = TB_MENU_LOCALIZED.SETTINGSCUSTOM
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSLOWEST,
								action = function()
										local options = {
											{ opt = "shaders", val = 0, graphics = true, id = SHADERS },
											{ opt = "fluid", val = 0, graphics = true, id = FLUIDBLOOD },
											{ opt = "bloodstains", val = 0 },
											{ opt = "framerate", val = 30 },
											{ opt = "reflection", val = 0, graphics = true, id = REFLECTIONS },
											{ opt = "softshadow", val = 0, graphics = true, id = SOFTSHADOWS },
											{ opt = "ambientocclusion", val = 0, graphics = true, id = AMBIENTOCCLUSION },
											{ opt = "bumpmapping", val = 0, graphics = true, id = BUMPMAPPING },
											{ opt = "raytracing", val = 0, graphics = true, id = RAYTRACING },
											{ opt = "trails", val = 0 },
											{ opt = "hair", val = 0 },
											{ opt = "hairquality", val = 0 },
											{ opt = "obj", val = 0 },
											{ opt = "bodytextures", val = 1, graphics = true, id = BODYTEXTURES },
											{ opt = "effects", val = 0 },
											{ opt = "particles", val = 0 },
											{ opt = "fixedframerate", val = 1 },
											{ opt = "uilight", val = 1 },
											{ opt = "ghostobj", val = 0 },
											{ opt = "itemeffects", val = 0, graphics = true, id = ITEMEFFECTS }
										}
										Settings.SetMacResolution()
										for _, v in pairs(options) do
											if (v.graphics) then
												set_graphics_option(v.id, v.val)
											else
												---@diagnostic disable-next-line: param-type-mismatch
												set_option(v.opt, v.val)
											end
										end
										save_custom_config()
										reload_graphics()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSLOW,
								action = function()
									local options = {
										{ opt = "shaders", val = 1, graphics = true, id = SHADERS },
										{ opt = "fluid", val = 0, graphics = true, id = FLUIDBLOOD },
										{ opt = "bloodstains", val = is_mobile() and 0 or 1 },
										{ opt = "framerate", val = 30 },
										{ opt = "reflection", val = 0, graphics = true, id = REFLECTIONS },
										{ opt = "softshadow", val = 0, graphics = true, id = SOFTSHADOWS },
										{ opt = "ambientocclusion", val = 0, graphics = true, id = AMBIENTOCCLUSION },
										{ opt = "bumpmapping", val = 0, graphics = true, id = BUMPMAPPING },
										{ opt = "raytracing", val = 0, graphics = true, id = RAYTRACING },
										{ opt = "trails", val = 1 },
										{ opt = "hair", val = 1 },
										{ opt = "hairquality", val = 0 },
										{ opt = "obj", val = 2 },
										{ opt = "bodytextures", val = 1, graphics = true, id = BODYTEXTURES },
										{ opt = "effects", val = 1 },
										{ opt = "particles", val = is_mobile() and 0 or 1 },
										{ opt = "fixedframerate", val = 1 },
										{ opt = "uilight", val = 0 },
										{ opt = "ghostobj", val = 0 },
										{ opt = "itemeffects", val = is_mobile() and 0 or 1, graphics = true, id = ITEMEFFECTS }
									}
									Settings.SetMacResolution()
									for _, v in pairs(options) do
										if (v.graphics) then
											set_graphics_option(v.id, v.val)
										else
											---@diagnostic disable-next-line: param-type-mismatch
											set_option(v.opt, v.val)
										end
									end
									save_custom_config()
									reload_graphics()
								end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSMEDIUM,
								action = function()
									local options = {
										{ opt = "shaders", val = 1, graphics = true, id = SHADERS },
										{ opt = "fluid", val = 2, graphics = true, id = FLUIDBLOOD },
										{ opt = "bloodstains", val = 1 },
										{ opt = "framerate", val = is_mobile() and 30 or 60 },
										{ opt = "reflection", val = 0, graphics = true, id = REFLECTIONS },
										{ opt = "softshadow", val = 0, graphics = true, id = SOFTSHADOWS },
										{ opt = "ambientocclusion", val = 0, graphics = true, id = AMBIENTOCCLUSION },
										{ opt = "bumpmapping", val = 1, graphics = true, id = BUMPMAPPING },
										{ opt = "raytracing", val = 0, graphics = true, id = RAYTRACING },
										{ opt = "trails", val = 1 },
										{ opt = "hair", val = 1 },
										{ opt = "hairquality", val = 0 },
										{ opt = "obj", val = 1 },
										{ opt = "bodytextures", val = 1, graphics = true, id = BODYTEXTURES },
										{ opt = "effects", val = 3 },
										{ opt = "particles", val = 1 },
										{ opt = "fixedframerate", val = 1 },
										{ opt = "uilight", val = 0 },
										{ opt = "ghostobj", val = is_mobile() and 0 or 1 },
										{ opt = "itemeffects", val = 1, graphics = true, id = ITEMEFFECTS }
									}
									Settings.SetMacResolution()
									for _, v in pairs(options) do
										if (v.graphics) then
											set_graphics_option(v.id, v.val)
										else
											---@diagnostic disable-next-line: param-type-mismatch
											set_option(v.opt, v.val)
										end
									end
									save_custom_config()
									reload_graphics()
								end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSHIGH,
								action = function()
									local options = {
										{ opt = "shaders", val = 1, graphics = true, id = SHADERS },
										{ opt = "fluid", val = 1, graphics = true, id = FLUIDBLOOD },
										{ opt = "bloodstains", val = 1 },
										{ opt = "framerate", val = is_mobile() and 60 or 75 },
										{ opt = "reflection", val = 1, graphics = true, id = REFLECTIONS },
										{ opt = "softshadow", val = 1, graphics = true, id = SOFTSHADOWS },
										{ opt = "ambientocclusion", val = 1, graphics = true, id = AMBIENTOCCLUSION },
										{ opt = "bumpmapping", val = 1, graphics = true, id = BUMPMAPPING },
										{ opt = "raytracing", val = 0, graphics = true, id = RAYTRACING },
										{ opt = "trails", val = 1 },
										{ opt = "hair", val = 1 },
										{ opt = "hairquality", val = 1 },
										{ opt = "obj", val = 1 },
										{ opt = "bodytextures", val = 1, graphics = true, id = BODYTEXTURES },
										{ opt = "effects", val = 3 },
										{ opt = "particles", val = 1 },
										{ opt = "fixedframerate", val = 1 },
										{ opt = "uilight", val = 0 },
										{ opt = "ghostobj", val = 1 },
										{ opt = "itemeffects", val = 1, graphics = true, id = ITEMEFFECTS }
									}
									Settings.SetMacResolution()
									for _ ,v in pairs(options) do
										if (v.graphics) then
											set_graphics_option(v.id, v.val)
										else
											---@diagnostic disable-next-line: param-type-mismatch
											set_option(v.opt, v.val)
										end
									end
									save_custom_config()
									reload_graphics()
								end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSHIGHEST,
								action = function()
									local options = {
										{ opt = "shaders", val = 1, graphics = true, id = SHADERS },
										{ opt = "fluid", val = 1, graphics = true, id = FLUIDBLOOD },
										{ opt = "bloodstains", val = 1 },
										{ opt = "framerate", val = is_mobile() and 60 or 75 },
										{ opt = "reflection", val = 1, graphics = true, id = REFLECTIONS },
										{ opt = "softshadow", val = 1, graphics = true, id = SOFTSHADOWS },
										{ opt = "ambientocclusion", val = 1, graphics = true, id = AMBIENTOCCLUSION },
										{ opt = "bumpmapping", val = 1, graphics = true, id = BUMPMAPPING },
										{ opt = "raytracing", val = 1, graphics = true, id = RAYTRACING },
										{ opt = "trails", val = 1 },
										{ opt = "hair", val = 1 },
										{ opt = "hairquality", val = 1 },
										{ opt = "obj", val = 1 },
										{ opt = "bodytextures", val = 1, graphics = true, id = BODYTEXTURES },
										{ opt = "effects", val = 3 },
										{ opt = "particles", val = 1 },
										{ opt = "fixedframerate", val = 1 },
										{ opt = "uilight", val = 0 },
										{ opt = "ghostobj", val = 1 },
										{ opt = "itemeffects", val = 1, graphics = true, id = ITEMEFFECTS }
									}
									Settings.SetMacResolution()
									for _, v in pairs(options) do
										if (v.graphics) then
											set_graphics_option(v.id, v.val)
										else
											---@diagnostic disable-next-line: param-type-mismatch
											set_option(v.opt, v.val)
										end
									end
									save_custom_config()
									reload_graphics()
								end
							}
						}
					}
				}
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSRESOLUTION,
				items = Settings:getResolutionItems()
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSADVANCED,
				hidden = true,
				items = advancedItems
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSGRAPHICSOTHER,
				items = {
					{
						name = TB_MENU_LOCALIZED.SETTINGSSYSTEMCURSOR,
						hint = TB_MENU_LOCALIZED.SETTINGSSYSTEMCURSORHINT,
						type = TOGGLE,
						action = function(val)
								Settings.Stored.systemcursor = { value = val }
							end,
						val = { Settings.Stored.systemcursor and Settings.Stored.systemcursor.value or get_option("systemcursor") },
						hidden = is_mobile()
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSUILIGHT,
						hint = TB_MENU_LOCALIZED.SETTINGSUILIGHTHINT,
						type = TOGGLE,
						action = function(val)
								Settings.Stored.uilight = { value = val }
							end,
						val = { Settings.Stored.uilight and Settings.Stored.uilight.value or get_option("uilight") }
					}
				}
			}
		}
	elseif (id == SETTINGS_EFFECTS) then
		local generalItems = {
			{
				name = TB_MENU_LOCALIZED.SETTINGSITEMEFFECTS,
				type = TOGGLE,
				action = function(val)
						Settings.Stored.itemeffects = { value = val, id = ITEMEFFECTS, graphics = true }
						Settings:settingsApplyActivate()
						Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
					end,
				val = { Settings.Stored.itemeffects and Settings.Stored.itemeffects.value or get_option("itemeffects") },
				reload = true,
				hidden = shaders == 0
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSEFFECTSVARIABLESPEED,
				type = TOGGLE,
				hint = TB_MENU_LOCALIZED.SETTINGSEFFECTSVARIABLESPEEDINFO,
				action = function(val)
					Settings.Stored.effectsvariablespeed = { value = val }
				end,
				val = { Settings.Stored.effectsvariablespeed and Settings.Stored.effectsvariablespeed.value or get_option("effectsvariablespeed") },
				hidden = (Settings.Stored.itemeffects and Settings.Stored.itemeffects.value or get_option("itemeffects")) == 0
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSEFFECTSINFO,
				type = DROPDOWN,
				selectedAction = function()
						local effects = Settings.Stored.effects and Settings.Stored.effects.value or get_option("effects")
						return math.clamp(effects + 1, 1, 3)
					end,
				dropdown = {
					{
						text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
						value = 0,
						name = "effects",
						action = function()
								Settings.Stored.effects = { value = 0 }
								Settings:settingsApplyActivate()
								Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
							end
					},
					{
						text = TB_MENU_LOCALIZED.SETTINGSREPLAYSONLY,
						value = 1,
						name = "effects",
						action = function()
								Settings.Stored.effects = { value = 1 }
								Settings:settingsApplyActivate()
								Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
							end
					},
					{
						text = TB_MENU_LOCALIZED.SETTINGSENABLED,
						value = 3,
						name = "effects",
						action = function()
								Settings.Stored.effects = { value = 3 }
								Settings:settingsApplyActivate()
								Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
							end
					},
				}
			}
		}

		local settingsCustomization = nil
		local effects = Settings.Stored.effects and Settings.Stored.effects.value or get_option("effects")
		if (effects > 0) then
			settingsCustomization = {
				name = TB_MENU_LOCALIZED.SETTINGSPLAYERCUSTOMIZATION,
				items = {
					{
						name = TB_MENU_LOCALIZED.SETTINGSOBJMODELS,
						type = DROPDOWN,
						selectedAction = function()
							return (Settings.Stored.obj and Settings.Stored.obj.value or get_option("obj")) + 1
						end,
						dropdown = {
							{
								text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
								action = function()
									Settings.Stored.obj = { value = 0 }
									Settings:settingsApplyActivate()
									Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
								end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSENABLED,
								action = function()
									Settings.Stored.obj = { value = 1 }
									Settings:settingsApplyActivate()
									Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
								end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSONLYSHOWMINE,
								action = function()
									Settings.Stored.obj = { value = 2 }
									Settings:settingsApplyActivate()
									Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
								end
							}
						}
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSFLAMES,
						type = DROPDOWN,
						selectedAction = function()
							return (Settings.Stored.particles and Settings.Stored.particles.value or get_option("particles")) + 1
						end,
						dropdown = {
							{
								text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
								action = function()
									Settings.Stored.particles = { value = 0 }
									Settings:settingsApplyActivate()
									Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
								end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSENABLED,
								action = function()
									Settings.Stored.particles = { value = 1 }
									Settings:settingsApplyActivate()
									Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
								end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSONLYSHOWMINE,
								action = function()
									Settings.Stored.particles = { value = 2 }
									Settings:settingsApplyActivate()
									Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
								end
							}
						}
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSHAIRS,
						type = TOGGLE,
						systemname = "hair",
						val = { Settings.Stored.hair and Settings.Stored.hair.value or get_option("hair") }
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSBODYTEXTURES,
						type = TOGGLE,
						action = function(val)
								Settings.Stored.bodytextures = { value = val, id = BODYTEXTURES, graphics = true }
							end,
						val = { Settings.Stored.bodytextures and Settings.Stored.bodytextures.value or get_option("bodytextures") },
						reload = true
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSTRAILS,
						type = TOGGLE,
						systemname = "trails",
						val = { Settings.Stored.trails and Settings.Stored.trails.value or get_option("trails") }
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSCOMICFX,
						type = TOGGLE,
						systemname = "comicfx",
						val = { Settings.Stored.comicfx and Settings.Stored.comicfx.value or get_option("comicfx") }
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSJOINTOBJOPACITY,
						type = SLIDER,
						maxValue = 100,
						systemname = "jointobjopacity",
						val = { Settings.Stored.jointobjopacity and Settings.Stored.jointobjopacity.value or get_option("jointobjopacity") },
						hidden = (Settings.Stored.obj and Settings.Stored.obj.value or get_option("obj")) == 0
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSGHOSTOBJ,
						type = TOGGLE,
						systemname = "ghostobj",
						val = { Settings.Stored.ghostobj and Settings.Stored.ghostobj.value or get_option("ghostobj") },
						hidden = (Settings.Stored.obj and Settings.Stored.obj.value or get_option("obj")) == 0
					}
				}
			}
		end

		return {
			{
				name = TB_MENU_LOCALIZED.SETTINGSGENERAL,
				items = generalItems
			},
			settingsCustomization
		}
	elseif (id == SETTINGS_AUDIO) then
		return {
			{
				name = TB_MENU_LOCALIZED.SETTINGSGENERAL,
				items = {
					{
						name = TB_MENU_LOCALIZED.SETTINGSEFFECTSVOLUME,
						type = SLIDER,
						maxValue = 128,
						maxValueDisp = 100,
						systemname = "soundvolume",
						val = { get_option("soundvolume") },
						onUpdate = function(slider)
							slider.label.labelText[1] = math.floor((slider.label.labelText[1] + 0) / 128 * 100 + 0.5)
						end,
						onMouseUp = function(slider)
							play_sound(36, slider.label.labelText[1])
						end
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSMUSICVOLUME,
						type = SLIDER,
						maxValue = 128,
						maxValueDisp = 100,
						systemname = "musicvolume",
						val = { get_option("musicvolume") },
						onUpdate = function(slider)
							slider.label.labelText[1] = math.floor((slider.label.labelText[1] + 0) / 128 * 100 + 0.5)
						end,
						onMouseUp = function(slider)
							play_sound(36, slider.label.labelText[1])
						end
					},
					--[[{
						name = TB_MENU_LOCALIZED.SETTINGSVCVOLUME,
						type = SLIDER,
						maxValue = 128,
						maxValueDisp = 100,
						systemname = "voicevolume",
						val = { get_option("voicevolume") }
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSVCTOGGLE,
						type = INPUT,
						inputspecial = true,
						systemname = "voicetoggle",
						val = { get_option("voicetoggle") }
					},--]]
					{
						name = TB_MENU_LOCALIZED.SETTINGSSOUNDMASTER,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOptionMaster(),
						dropdown = Settings:getAdvancedAudioDropdownMaster()
					},
				}
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSADVANCED,
				items = {
					{
						name = TB_MENU_LOCALIZED.SETTINGSHITEFFECTS,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_HIT),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_HIT)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSGAMEOVER,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_GAMEOVER),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_GAMEOVER)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSREADY,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_READY),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_READY)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSGRIP,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_GRIP),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_GRIP)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSALERT,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_ALERT),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_ALERT)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSDISMEMBER,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_DISMEMBER),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_DISMEMBER)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSFIGHTALERT,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_FIGHT_ALERT),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_FIGHT_ALERT)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSFREEZE,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_FREEZE),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_FREEZE)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSGRADING,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_GRADING),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_GRADING)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSIMPACT,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_IMPACT),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_IMPACT)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSJOINT,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_JOINT),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_JOINT)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSMENU,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_MENU),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_MENU)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSNONE,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_NONE),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_NONE)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSPAIN,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_PAIN),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_PAIN)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSSELECTPLAYER,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_SELECT_PLAYER),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_SELECT_PLAYER)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSSPLASH,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_SPLASH),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_SPLASH)
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSSWOOSH,
						type = DROPDOWN,
						selectedAction = Settings:getAdvancedAudioOption(SND_CAT_SWOOSH),
						dropdown = Settings:getAdvancedAudioDropdown(SND_CAT_SWOOSH)
					},
				}
			}
		}
	elseif (id == SETTINGS_OTHER) then
		return {
			{
				name = TB_MENU_LOCALIZED.SETTINGSLANGUAGE,
				items = {
					-- Steam language can't be currently detected from lua
					--[[{
						name = "Use Steam Language",
						type = TOGGLE,
						systemname = "languagesteam",
						reload = true,
						val = { get_option("languagesteam") }
					},]]
					{
						name = TB_MENU_LOCALIZED.SETTINGSGAMELANGUAGE,
						type = DROPDOWN,
						dropdown = Settings:getLanguageDropdown()
					}
				}
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSGAMEPLAY,
				items = {
					{
						name = TB_MENU_LOCALIZED.MAINMENUHOTKEYSNAME,
						type = BUTTON,
						text = TB_MENU_LOCALIZED.PRESSTOSHOW,
						action = function()
							TBMenu:showHotkeys()
						end,
						hidden = is_mobile()
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSREPLAYHUDTOGGLE,
						type = INPUT,
						inputspecial = true,
						systemname = "replayhudtoggle",
						val = { get_option("replayhudtoggle") },
						hidden = is_mobile()
					},
					{
						name = is_mobile() and TB_MENU_LOCALIZED.SETTINGSMOUSEBUTTONSMOBILE or TB_MENU_LOCALIZED.SETTINGSMOUSEBUTTONS,
						type = DROPDOWN,
						systemname = "mousebuttons",
						selectedAction = function()
								return get_option("mousebuttons")
							end,
						dropdown = {
							{
								text = TB_MENU_LOCALIZED.SETTINGSMOUSEBUTTONS1,
								action = function()
										Settings.Stored.mousebuttons = { value = 1 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSMOUSEBUTTONS2,
								action = function()
										Settings.Stored.mousebuttons = { value = 2 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSMOUSEBUTTONS0,
								action = function()
										Settings.Stored.mousebuttons = { value = 3 }
										Settings:settingsApplyActivate()
									end
							}
						}
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSJOINTSTATEWHEEL,
						type = DROPDOWN,
						systemname = "tooltipmode",
						selectedAction = function()
								return get_option("tooltipmode") + 1
							end,
						dropdown = {
							{
								text = TB_MENU_LOCALIZED.SETTINGSMOUSEBUTTONS1,
								action = function()
										Settings.Stored.tooltipmode = { value = 0 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSMOUSEBUTTONS0,
								action = function()
										Settings.Stored.tooltipmode = { value = 1 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSMOUSEBUTTONS2,
								action = function()
										Settings.Stored.tooltipmode = { value = 2 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
								action = function()
										Settings.Stored.tooltipmode = { value = 3 }
										Settings:settingsApplyActivate()
									end
							}
						},
						hidden = not is_mobile()
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSMOUSESCROLLCONTROLS,
						type = TOGGLE,
						systemname = "scrollcontrols",
						val = { get_option("scrollcontrols") },
						hidden = is_mobile(),
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSGAMERULES,
						hint = TB_MENU_LOCALIZED.SETTINGSGAMERULESHINT,
						type = TOGGLE,
						systemname = "rememberrules",
						val = { get_option("rememberrules") }
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSBACKGROUNDCLICK,
						hint = TB_MENU_LOCALIZED.SETTINGSBACKGROUNDCLICKHINT,
						type = TOGGLE,
						systemname = "backgroundclick",
						val = { get_option("backgroundclick") }
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSAUTOUPDATE,
						type = TOGGLE,
						systemname = "autoupdate",
						val = { get_option("autoupdate") }
					}
				}
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSREPLAYS,
				items = {
					{
						name = TB_MENU_LOCALIZED.SETTINGSREPLAYCACHE,
						type = DROPDOWN,
						systemname = "replaycache",
						selectedAction = function()
								local replaycache, sysreplaycache = get_option("replaycache"), get_option("sysreplaycache")
								return sysreplaycache + (replaycache == sysreplaycache and 2 or 1)
							end,
						dropdown = {
							{
								text = TB_MENU_LOCALIZED.SETTINGSDISABLEDREPLAYCACHEMEMORY,
								hidden = true
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
								action = function()
										Settings.Stored.replaycache = { value = 0 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSREPLAYCACHESECONDPLAYTHROUGH,
								action = function()
										Settings.Stored.replaycache = { value = 1 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSENABLED,
								action = function()
										Settings.Stored.replaycache = { value = 2 }
										Settings:settingsApplyActivate()
									end
							},
						}
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSREPLAYMEMSIZE,
						type = DROPDOWN,
						systemname = "memsize",
						selectedAction = function()
								return get_option("memsize") + 1
							end,
						dropdown = {
							{
								text = 1024 .. " " .. TB_MENU_LOCALIZED.SETTINGSREPLAYFRAMES,
								action = function()
										Settings.Stored.memsize = { value = 0 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = 2048 .. " " .. TB_MENU_LOCALIZED.SETTINGSREPLAYFRAMES,
								action = function()
										Settings.Stored.memsize = { value = 1 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = 4096 .. " " .. TB_MENU_LOCALIZED.SETTINGSREPLAYFRAMES,
								action = function()
										Settings.Stored.memsize = { value = 2 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = 8192 .. " " .. TB_MENU_LOCALIZED.SETTINGSREPLAYFRAMES,
								action = function()
										Settings.Stored.memsize = { value = 3 }
										Settings:settingsApplyActivate()
									end
							}
						}
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSAUTOSAVE,
						type = DROPDOWN,
						systemname = "autosave",
						selectedAction = function()
							return get_option("autosave") + 1
						end,
						dropdown = {
							{
								text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
								action = function()
										Settings.Stored.autosave = { value = 0 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSENABLED,
								action = function()
										Settings.Stored.autosave = { value = 1 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSAUTOSAVEONLYMINE,
								action = function()
										Settings.Stored.autosave = { value = 2 }
										Settings:settingsApplyActivate()
									end
							}
						},
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSKEYFRAMESAVING,
						type = DROPDOWN,
						systemname = "keyframesavemode",
						selectedAction = function()
							return get_option("keyframesavemode") + 1
						end,
						dropdown = {
							{
								text = TB_MENU_LOCALIZED.SETTINGSKEYFRAMESAVEMODE1,
								action = function()
										Settings.Stored.keyframesavemode = { value = 0 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSKEYFRAMESAVEMODE2,
								action = function()
										Settings.Stored.keyframesavemode = { value = 1 }
										Settings:settingsApplyActivate()
									end
							}
						}
					}
				}
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSCAMERA,
				items = {
					{
						name = TB_MENU_LOCALIZED.SETTINGSCAMERAFOCUS,
						type = DROPDOWN,
						systemname = "camerafocus",
						selectedAction = function()
								return get_option("camerafocus") + 1
							end,
						dropdown = {
							{
								text = TB_MENU_LOCALIZED.SETTINGSCAMERAFOCUSNONE,
								action = function()
										Settings.Stored.camerafocus = { value = 0 }
										Settings.Stored.focuscam = { value = 0 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSCAMERAFOCUSPLAYER,
								action = function()
										Settings.Stored.camerafocus = { value = 1 }
										Settings.Stored.focuscam = { value = 0 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSCAMERAFOCUSJOINT,
								action = function()
										Settings.Stored.camerafocus = { value = 2 }
										Settings.Stored.focuscam = { value = 0 }
										Settings:settingsApplyActivate()
									end
							}
						}
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSCAMERASENSITIVITY,
						type = SLIDER,
						minValue = 50,
						minValueDisp = "0.5x",
						maxValue = 200,
						maxValueDisp = "2x",
						systemname = "camerasensitivityh",
						onUpdate = function(slider)
							Settings.Stored.camerasensitivity = {
								value = math.round((tonumber(slider.label.labelText[1]) or 100) / 10) * 10
							}
							slider.label.labelText[1] = math.round((tonumber(slider.label.labelText[1]) or 100) / 10) / 10 .. 'x'
						end,
						val = { get_option("camerasensitivityh") },
						hidden = not is_mobile()
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSCAMERAYSENSITIVITY,
						type = SLIDER,
						minValue = 50,
						minValueDisp = "0.5x",
						maxValue = 200,
						maxValueDisp = "2x",
						systemname = "camerasensitivityy",
						onUpdate = function(slider)
							Settings.Stored.camerasensitivityvert = {
								value = math.round((tonumber(slider.label.labelText[1]) or 100) / 10) * 10
							}
							slider.label.labelText[1] = math.round((tonumber(slider.label.labelText[1]) or 100) / 10) / 10 .. 'x'
						end,
						val = { get_option("camerasensitivityy") },
						hidden = not is_mobile()
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSCAMERAINVERTX,
						type = TOGGLE,
						systemname = "invertedcamx",
						val = { bit.band(tonumber(get_option("invertedcam")) or 0, 1) ~= 0 and 1 or 0 }
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSCAMERAINVERTY,
						type = TOGGLE,
						systemname = "invertedcamy",
						val = { bit.band(tonumber(get_option("invertedcam")) or 0, 2) ~= 0 and 1 or 0 }
					}
				}
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSCHAT,
				items = {
					{
						name = TB_MENU_LOCALIZED.SETTINGSCHATTOGGLE,
						type = INPUT,
						inputspecial = true,
						systemname = "chattoggle",
						val = { get_option("chattoggle") },
						hidden = is_mobile()
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSPROFANITYFILTER,
						type = TOGGLE,
						systemname = "chatcensor",
						val = { get_option("chatcensor") % 2 == 1 and 1 or 0 }
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSHIDEECHO,
						type = TOGGLE,
						systemname = "chatcensorhidesystem",
						val = { get_option("chatcensor") > 1 and 1 or 0 }
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSPLAYERTEXTUCUSTOM,
						type = TOGGLE,
						systemname = "playertext",
						val = { get_option("playertext") }
					}
				}
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSMODERNHUD,
				items = {
					{
						name = TB_MENU_LOCALIZED.SETTINGSTOOLTIP,
						type = TOGGLE,
						systemname = "tooltip",
						action = function(val)
							Settings.Stored.tooltip = { value = val }
						end,
						val = { get_option("tooltip") }
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSJOINTFLASH,
						type = TOGGLE,
						action = function(val)
								Settings.Stored.jointflash = { value = val }
							end,
						val = { Settings.Stored.jointflash and Settings.Stored.jointflash.value or get_option("jointflash") }
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSMOVEMEMORY,
						type = TOGGLE,
						systemname = "movememory",
						action = function(val)
							Settings.Stored.movememory = { value = val }
						end,
						val = { get_option("movememory") },
						hidden = is_mobile()
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSBROADCASTS,
						type = DROPDOWN,
						systemname = "showbroadcast",
						selectedAction = function()
								local showbroadcast = get_option("showbroadcast") + 0
								if (showbroadcast > 2) then
									showbroadcast = bit.bxor(get_option("showbroadcast") + 0, 4)
								end
								return showbroadcast + 1
							end,
						dropdown = {
							{
								text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
								action = function()
										Settings.Stored.showbroadcast = { value = 0 }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSSHOWINMP,
								action = function()
										Settings.Stored.showbroadcast = { value = 1 + bit.band(Settings.Stored["showbroadcast"] and Settings.Stored["showbroadcast"].value or get_option("showbroadcast"), 4) }
										Settings:settingsApplyActivate()
									end
							},
							{
								text = TB_MENU_LOCALIZED.SETTINGSALWAYSSHOW,
								action = function()
										Settings.Stored.showbroadcast = { value = 2 + bit.band(Settings.Stored["showbroadcast"] and Settings.Stored["showbroadcast"].value or get_option("showbroadcast"), 4) }
										Settings:settingsApplyActivate()
									end
							},
						}
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSBROADCASTSAUTO,
						type = TOGGLE,
						systemname = "showbroadcast",
						action = function(val)
							local showbroadcast = Settings.Stored["showbroadcast"] and Settings.Stored["showbroadcast"].value or get_option("showbroadcast")
							if (showbroadcast >= 4) then
								showbroadcast = showbroadcast - 4
							end
							Settings.Stored.showbroadcast = { value = (1 - val) * 4 + showbroadcast }
						end,
						val = { bit.band(get_option("showbroadcast") + 0, 4) == 0 and 1 or 0 }
					}
				}
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSUSAGEREPORTING,
				items = {
					{
						name = TB_MENU_LOCALIZED.SETTINGSSUBMITUSAGE,
						hint = TB_MENU_LOCALIZED.SETTINGSSUBMITUSAGEDESC,
						type = TOGGLE,
						systemname = "usagestats",
						action = function(val)
							Settings.Stored.tooltip = { value = val }
						end,
						val = { get_option("usagestats") }
					}
				}
			},
			{
				name = TB_MENU_LOCALIZED.SETTINGSSTORAGEMANAGEMENT,
				items = {
					{
						name = TB_MENU_LOCALIZED.SETTINGSCACHEFILES,
						hint = TB_MENU_LOCALIZED.SETTINGSCACHEFILESINFO,
						type = BUTTON,
						text = TB_MENU_LOCALIZED.SETTINGSCLEARDATABUTTON,
						action = function()
							local result = remove_cache()
							if (result == 0) then
								TBMenu:showStatusMessage(TB_MENU_LOCALIZED.SETTINGSCACHECLEARSUCCESS)
							else
								TBMenu:showStatusMessage(TB_MENU_LOCALIZED.SETTINGSDATACLEARFAILURE .. (result == nil and "" or " (err " .. result .. ")"))
							end
						end
					},
					{
						name = TB_MENU_LOCALIZED.SETTINGSCUSTOMSFILES,
						hint = TB_MENU_LOCALIZED.SETTINGSCUSTOMSFILESINFO,
						type = BUTTON,
						text = TB_MENU_LOCALIZED.SETTINGSCLEARDATABUTTON,
						action = function()
							local result = remove_customs()
							if (result == 0) then
								TBMenu:showStatusMessage(TB_MENU_LOCALIZED.SETTINGSCUSTOMSCLEARSUCCESS)
							else
								TBMenu:showStatusMessage(TB_MENU_LOCALIZED.SETTINGSDATACLEARFAILURE .. (result == nil and "" or " (err " .. result .. ")"))
							end
							update_tc_balance()
						end,
						hidden = not is_mobile()
					}
				}
			}
		}
	end
end

function Settings:getGraphicsPreset()
	return function()
			local options = {
				"shaders", "fluid", "bloodstains", "framerate", "reflection", "softshadow", "ambientocclusion", "bumpmapping", "raytracing", "trails", "hair", "hairquality", "obj", "effects", "particles", "bodytextures", "uilight", "ghostobj"
			}
			local presets = {
				is_mobile() and "1003000000000000110" or "0003000000000000110",
				is_mobile() and "1003000000110010110" or "1013000000110011110",
				is_mobile() and "1213000010110131100" or "1216000010110131101",
				is_mobile() and "1116011110111131101" or "1117511110111131101",
				is_mobile() and "1116011111111131101" or "1117511111111131101"
			}
			local userSetting = ""
			for _, v in pairs(options) do
				userSetting = userSetting .. get_option(v)
			end
			for i,v in pairs(presets) do
				if (v == userSetting) then
					return i + 1
				end
			end
			return 1
		end
end

function Settings:getLanguageDropdown()
	local languages = {}
	local dropdown = {}
	local current = string.lower(get_language())
	local files = get_files("data/language", "txt")
	for _, v in pairs(files) do
		table.insert(languages, { name = v:gsub("%.txt$", "") })
	end
	for _, v in pairs(languages) do
		v.newMenuDisabled = not Files.Exists("system/language/" .. v.name .. ".txt")
		table.insert(dropdown, {
			text = v.newMenuDisabled and (v.name .. " (" .. TB_MENU_LOCALIZED.SETTINGSBASEHUDONLY .. ")") or v.name,
			selected = string.lower(v.name) == current,
			action = function()
					set_language(v.name)
					TBMenu.GetTranslation(get_language())
					Settings.SetMacResolution()
					save_custom_config()
					reload_graphics()
					Settings:settingsApplyActivate()
				end
		})
	end
	return dropdown
end

function Settings:getResolutionItems()
	local fullscreen = Settings.Stored.fullscreen and Settings.Stored.fullscreen.value or get_option("fullscreen")
	local items = {}
	if (not is_mobile()) then
		if (fullscreen == 1) then
			items = {
				{
					name = TB_MENU_LOCALIZED.SETTINGSFULLSCREEN and TB_MENU_LOCALIZED.SETTINGSFULLSCREEN or TB_MENU_LOCALIZED.SETTINGSWINDOWED,
					type = TOGGLE,
					action = function(val)
							Settings.Stored.fullscreen = { value = TB_MENU_LOCALIZED.SETTINGSFULLSCREEN and val or 1 - val, reload = true }
							Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
						end,
					val = { TB_MENU_LOCALIZED.SETTINGSFULLSCREEN and fullscreen or 1 - fullscreen }
				},
			}
			if (PLATFORM == "WINDOWS") then
				table.insert(items, {
					name = TB_MENU_LOCALIZED.SETTINGSBORDERLESS,
					type = TOGGLE,
					action = function(val)
							Settings.Stored.borderless = { id = BORDERLESS, value = val, graphics = true }
						end,
					val = { Settings.Stored["borderless"] and Settings.Stored["borderless"].value or get_option("borderless") },
					inactive = get_dpiawareness().DPISCALING ~= 1
				})
			end
		else
			-- Use these values instead of get_option() width/height to get highdpi-adapted values on macOS
			local _x, _y, optionWidth, optionHeight = get_window_size()
			--No longer needed as of 230531
			--[[if (PLATFORM == "APPLE") then
				optionWidth = _x
				optionHeight = _y
			end]]
			if (SETTINGS_LAST_RESOLUTION) then
				optionWidth, optionHeight = unpack(SETTINGS_LAST_RESOLUTION)
			end

			items = {
				{
					name = TB_MENU_LOCALIZED.SETTINGSWIDTH,
					type = INPUT,
					systemname = "width",
					reload = true,
					val = { optionWidth },
					valueVerifyAction = function(val)
						if (val == '') then
							return val
						end
						local val = tonumber(val) or 0
						local maxWidth, _ = get_maximum_window_size()
						return (val > maxWidth and maxWidth or val)
					end
				},
				{
					name = TB_MENU_LOCALIZED.SETTINGSHEIGHT,
					type = INPUT,
					systemname = "height",
					reload = true,
					val = { optionHeight },
					valueVerifyAction = function(val)
						if (val == '') then
							return val
						end
						local val = tonumber(val) or 0
						local _, maxHeight = get_maximum_window_size()
						return (val > maxHeight and maxHeight or val)
					end
				},
				{
					name = TB_MENU_LOCALIZED.SETTINGSFULLSCREEN and TB_MENU_LOCALIZED.SETTINGSFULLSCREEN or TB_MENU_LOCALIZED.SETTINGSWINDOWED,
					type = TOGGLE,
					action = function(val)
							Settings.Stored.fullscreen = { value = TB_MENU_LOCALIZED.SETTINGSFULLSCREEN and val or 1 - val, reload = true }
							Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
						end,
					val = { TB_MENU_LOCALIZED.SETTINGSFULLSCREEN and fullscreen or 1 - fullscreen }
				}
			}
		end
	end
	if (PLATFORM == "APPLE") then
		table.insert(items, {
			name = TB_MENU_LOCALIZED.SETTINGSHIGHDPI,
			type = TOGGLE,
			action = function(val)
					Settings.Stored.dpiscale = { id = DPISCALE_APPLE, value = val, graphics = true, reload = true }
				end,
			val = { get_option("dpiscale") }
		})
	end

	local maxHdpi = get_maximum_dpi_scale()
	if (maxHdpi > 10) then
		table.insert(items, {
			name = TB_MENU_LOCALIZED.SETTINGSGUISCALING,
			minValue = 10,
			minValueDisp = "1x",
			maxValue = maxHdpi,
			maxValueDisp = maxHdpi / 10 .. "x",
			type = SLIDER,
			systemname = "highdpi",
			onUpdate = function(slider)
				Settings.Stored.highdpi = {
					value = tonumber(slider.label.labelText[1]) or 1,
					id = HIGHDPI, graphics = true, reload = true
				}
				slider.label.labelText[1] = (tonumber(slider.label.labelText[1]) or 1) / 10 .. 'x'
			end,
			val = { math.max(10, math.min(get_option("highdpi"), maxHdpi)) }
		})
	end

	if (PLATFORM == "WINDOWS" and get_dpiawareness().DPISCALING ~= 1) then
		table.insert(items, {
			name = TB_MENU_LOCALIZED.SETTINGSDPIAWARENESS,
			type = TOGGLE,
			action = function(val)
					Settings.Stored.dpiawareness = { value = val }
				end,
			val = { get_option("dpiawareness") },
			hint = TB_MENU_LOCALIZED.HINTREQUIRESRESTART
		})
	end
	return items
end

function Settings:getAdvancedAudioOptionMaster()
	return function()
			local state, stateDef = get_sound_category(0)
			for i = 1, 16 do
				local state2, stateDef2 = get_sound_category(i)
				if (state2 ~= state or stateDef2 ~= stateDef) then
					return 1
				end
			end
			if (state == 1) then
				if (stateDef == 1) then
					return 3
				else
					return 2
				end
			end
			return 4
		end
end

function Settings:getAdvancedAudioDropdownMaster()
	return {
		{
			text = TB_MENU_LOCALIZED.SETTINGSCUSTOM,
		},
		{
			text = TB_MENU_LOCALIZED.SETTINGSENABLED,
			action = function()
					for i = 0, 16 do
						set_sound_category(i, 1, 0)
					end
					Settings.SetMacResolution()
					save_custom_config()
					reload_graphics()
				end
		},
		{
			text = TB_MENU_LOCALIZED.SETTINGSONLYDEFAULTSOUNDS,
			action = function()
					for i = 0, 16 do
						set_sound_category(i, 1, 1)
					end
					Settings.SetMacResolution()
					save_custom_config()
					reload_graphics()
				end
		},
		{
			text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
			action = function()
					for i = 0, 16 do
						set_sound_category(i, 0, 0)
					end
					Settings.SetMacResolution()
					save_custom_config()
					reload_graphics()
				end
		},
	}
end

function Settings:getAdvancedAudioOption(option)
	return function()
			local opt, default = get_sound_category(option)
			if (opt == 1) then
				if (default == 1) then
					return 2
				else
					return 1
				end
			end
			return 3
		end
end

function Settings:getAdvancedAudioDropdown(option)
	return {
		{
			text = TB_MENU_LOCALIZED.SETTINGSENABLED,
			action = function()
					Settings.Stored["soundcat" .. option] = { value = 1, default = 0 }
					Settings:settingsApplyActivate()
				end
		},
		{
			text = TB_MENU_LOCALIZED.SETTINGSONLYDEFAULTSOUNDS,
			action = function()
					Settings.Stored["soundcat" .. option] = { value = 1, default = 1 }
					Settings:settingsApplyActivate()
				end
		},
		{
			text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
			action = function()
					Settings.Stored["soundcat" .. option] = { value = 0, default = 0 }
					Settings:settingsApplyActivate()
				end
		},
	}
end

function Settings:getKeyName(key)
	if (key == 8) then
		return "Backspace"
	elseif (key == 9) then
		return "Tab"
	elseif (key == 13) then
		return "Enter"
	elseif (key == 127) then
		return "Del"
	elseif (key == 275) then
		return "Arrow Right"
	elseif (key == 276) then
		return "Arrow Left"
	elseif (key == 273) then
		return "Arrow Up"
	elseif (key == 274) then
		return "Arrow Down"
	elseif (key == 278) then
		return "Home"
	elseif (key == 279) then
		return "End"
	elseif (key == 280) then
		return "Page Up"
	elseif (key == 281) then
		return "Page Dn"
	elseif (key >= 282 and key <= 294) then
		return "F" .. key - 281
	elseif (key == 303) then
		return "R Shift"
	elseif (key == 304) then
		return "L Shift"
	elseif (key == 305) then
		return "R Ctrl"
	elseif (key == 306) then
		return "L Ctrl"
	elseif (key == 307) then
		if (_G.PLATFORM == "APPLE") then
			return "R Opt"
		end
		return "R Alt"
	elseif (key == 308) then
		if (_G.PLATFORM == "APPLE") then
			return "L Opt"
		end
		return "L Alt"
	elseif (key == 312) then
		return "L Super"
	elseif (key == 316) then
		return "PrintScreen"
	elseif (key >= 400) then
		return "???"
	else
		return string.schar(key)
	end
end

function Settings:settingsApplyActivate(restart)
	if (Settings.ApplyButton == nil) then return end
	if (not Settings.ApplyButton:isActive() or restart) then
		Settings.ApplyButton:activate(true)
		Settings.ApplyButton:addAdaptedText(false, TB_MENU_LOCALIZED.SETTINGSAPPLY .. (restart and " (" .. TB_MENU_LOCALIZED.SETTINGSRESTARTREQUIRED .. ")" or ""))
	end
end

---macOS high dpi mode leads to issues when calling graphics reload as "real" values are hdpi-adjusted. \
---Make sure we set them according to device physical size, then write any other options on top, then request graphics reload.
---@param width ?integer
---@param height ?integer
function Settings.SetMacResolution(width, height)
	if (PLATFORM ~= "APPLE") then return end
	local _, _, x, y = get_window_size()
	set_option("width", width or x)
	set_option("height", height or y)
end

function Settings.SetChatCensorSettings()
	if (Settings.Stored.chatcensor == nil and Settings.Stored.chatcensorhidesystem == nil) then
		return
	end

	local chatcensor = get_option("chatcensor")
	local wordfilter, hidesystem = Settings.Stored.chatcensor and Settings.Stored.chatcensor.value or (chatcensor % 2), Settings.Stored.chatcensorhidesystem and Settings.Stored.chatcensorhidesystem.value or (chatcensor > 1 and 1 or 0)

	Settings.Stored.chatcensorhidesystem = nil
	Settings.Stored.chatcensor = { value = wordfilter + hidesystem * 2 }
end

function Settings.SetInvertedCameraSettings()
	if (Settings.Stored.invertedcamx == nil and Settings.Stored.invertedcamy == nil) then
		return
	end

	local inverted = tonumber(get_option("invertedcam")) or 0
	local inverted_x = Settings.Stored.invertedcamx and Settings.Stored.invertedcamx.value or (bit.band(inverted, 1) ~= 0 and 1 or 0)
	local inverted_y = Settings.Stored.invertedcamy and Settings.Stored.invertedcamy.value or (bit.band(inverted, 2) ~= 0 and 1 or 0)
	Settings.Stored.invertedcamx = nil
	Settings.Stored.invertedcamy = nil
	Settings.Stored.invertedcam = { value = bit.bor(inverted_x, inverted_y * 2) }
end

function Settings:showSettings(id, keepStoredSettings)
	if (not keepStoredSettings) then
		usage_event("settings" .. id)
	end
	if (TBMenu.CurrentSection.settingsInitialized == false) then return end
	TBMenu.CurrentSection.settingsInitialized = false
	TB_MENU_SETTINGS_SCREEN_ACTIVE = id

	local targetListShift = keepStoredSettings and ((TBMenu.CurrentSection.settingsListingHolder.shift.y < 0 and -TBMenu.CurrentSection.settingsListingHolder.shift.y or TBMenu.CurrentSection.settingsListingHolder.size.h) - TBMenu.CurrentSection.settingsListingHolder.size.h) or -1

	local applySettingsButtonActive = Settings.ApplyButton and Settings.ApplyButton:isActive()
	local applySettingsButtonText = applySettingsButtonActive and Settings.ApplyButton.str

	TBMenu.CurrentSection:kill(true)

	local settingsData = Settings:getSettingsData(id)
	local settingsMain = UIElement.new({
		parent = TBMenu.CurrentSection,
		pos = { 5, 0 },
		size = { TBMenu.CurrentSection.size.w - 10, TBMenu.CurrentSection.size.h },
		bgColor = TB_MENU_DEFAULT_BG_COLOR
	})
	local elementHeight = 50
	local toReload, topBar, botBar, _, listingHolder = TBMenu:prepareScrollableList(settingsMain, elementHeight, elementHeight + 10, 20)

	TBMenu:addBottomBloodSmudge(botBar, 1)
	Settings.ApplyButton = botBar:addChild({
		pos = { botBar.size.w / 4, 10 },
		size = { botBar.size.w / 2, botBar.size.h - 20 },
		interactive = true,
		bgColor = TB_MENU_DEFAULT_BG_COLOR,
		hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
		pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		inactiveColor = TB_MENU_DEFAULT_INACTIVE_COLOR_DARK,
		shapeType = ROUNDED,
		rounded = 5
	})
	Settings.ApplyButton:addAdaptedText(false, TB_MENU_LOCALIZED.SETTINGSNOCHANGES)
	Settings.ApplyButton:addMouseHandlers(nil, function()
			local reload = false
			Settings.SetChatCensorSettings()
			Settings.SetInvertedCameraSettings()
			if (Settings.Stored["fullscreen"] and Settings.Stored["fullscreen"].value == 1 and not SETTINGS_LAST_RESOLUTION) then
				SETTINGS_LAST_RESOLUTION = { WIN_W, WIN_H }
			elseif (not Settings.Stored["borderless"]) then
				SETTINGS_LAST_RESOLUTION = nil
			end
			for i, v in pairs(Settings.Stored) do
				if (i:find("soundcat")) then
					local catid = i:gsub("^soundcat", "")
					set_sound_category(tonumber(catid) + 0, v.value, v.default)
				else
					if (v.graphics) then
						set_graphics_option(v.id, v.value)
						reload = true
					else
						set_option(i, v.value)
					end
					if (v.reload) then
						reload = true
					end
					if (i == 'dpiawareness') then
						TBMenu:showStatusMessage(TB_MENU_LOCALIZED.SETTINGSAPPLIEDAFTERRESTART)
					end
				end
			end
			if (Settings.Stored.showbroadcast) then
				dofile("system/broadcast_manager.lua")
				if (not in_array(Settings.Stored.showbroadcast.value, { 0, 4 })) then
					Broadcasts:activate()
				else
					Broadcasts:deactivate()
				end
			end
			if (reload) then
				Settings.SetMacResolution(
					Settings.Stored["width"] and Settings.Stored["width"].value or nil,
					Settings.Stored["height"] and Settings.Stored["height"].value or nil)
			end
			if (not keepStoredSettings) then
				Settings.Stored = {}
			end
			Settings.ApplyButton:deactivate(true)
			Settings.ApplyButton:addAdaptedText(false, TB_MENU_LOCALIZED.SETTINGSNOCHANGES)
			save_custom_config()
			if (reload) then
				reload_graphics()
			else
				Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
			end
		end)
	Settings.ApplyButton:deactivate(true)

	if (applySettingsButtonActive and type(applySettingsButtonText) == "string") then
		Settings.ApplyButton:activate(true)
		Settings.ApplyButton:addAdaptedText(false, applySettingsButtonText)
	end

	local listElements = {}
	for _, section in pairs(settingsData) do
		if (#section.items > 0) then
			local sectionName = listingHolder:addChild({
				pos = { 20, #listElements * elementHeight },
				size = { listingHolder.size.w - 40, elementHeight }
			})
			sectionName:addAdaptedText(true, section.name, nil, -3, FONTS.BIG, LEFTBOT, 0.6)
			table.insert(listElements, sectionName)
			for _, item in pairs(section.items) do
				if (not item.hidden) then
					local itemHolder = listingHolder:addChild({
						pos = { 0, #listElements * elementHeight },
						size = { listingHolder.size.w, elementHeight }
					})
					table.insert(listElements, itemHolder)
					local itemView = itemHolder:addChild({
						shift = { 20, 3 },
						bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
						shapeType = ROUNDED,
						rounded = 4
					})
					local shiftX = 20
					if (item.hint) then
						local hintIcon = itemView:addChild({
							pos = { shiftX, 7 },
							size = { itemView.size.h - 14, itemView.size.h - 14 },
							interactive = true,
							shapeType = ROUNDED,
							rounded = itemView.size.h,
							bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
							hoverColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
							pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
						})
						local popup = TBMenu:displayHelpPopup(hintIcon, item.hint, true)
						if (popup ~= nil) then
							popup:moveTo(itemView.size.h - 9, -(popup.size.h - itemView.size.h + 14) / 2, true)
						end
						shiftX = shiftX + hintIcon.size.w + 14
					end
					local itemName = itemView:addChild({
						pos = { shiftX, 0 },
						size = { itemView.size.w / 2 - 10 - shiftX, itemView.size.h }
					})
					itemName:addAdaptedText(true, item.name, nil, nil, nil, LEFTMID)
					if (item.type == SLIDER) then
						local itemSlider = itemView:addChild({
							pos = { itemView.size.w / 2 + 10, 5 },
							size = { itemView.size.w / 2 - 30, itemView.size.h - 10 }
						})
						local slider
						slider = TBMenu:spawnSlider2(itemSlider, nil, tonumber(item.val[1]) or 0, item, function(val)
							Settings.Stored[item.systemname] = { value = val }
							Settings:settingsApplyActivate()
							if (item.onUpdate) then
								item.onUpdate(slider)
							end
						end, nil, function()
							if (item.onMouseUp) then
								item.onMouseUp(slider)
							end
						end)
					elseif (item.type == TOGGLE) then
						local itemToggle = itemView:addChild({
							pos = { -itemView.size.h - 10, 5 },
							size = { itemView.size.h - 10, itemView.size.h - 10 },
							shapeType = ROUNDED,
							rounded = 3
						})
						if (not item.action) then
							item.action = function(val)
								Settings.Stored[item.systemname] = { value = val }
							end
						end
						local action = item.action
						item.action = function(val)
							action(val)
							Settings:settingsApplyActivate(item.reload)
						end
						TBMenu:spawnToggle(itemToggle, nil, nil, nil, nil, item.val[1], item.action)
					elseif (item.type == INPUT) then
						local itemInput = itemView:addChild({
							pos = { itemView.size.w / 3 * 2 - 20, 5 },
							size = { itemView.size.w / 3, itemView.size.h - 10 },
							bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
							shapeType = ROUNDED,
							rounded = 3
						})
						if (item.inputspecial) then
							local textField = TBMenu:spawnTextField2(itemInput, nil, Settings:getKeyName(item.val[1]), TB_MENU_LOCALIZED.SETTINGSPRESSKEYTOASSIGN, {
								isNumeric = true,
								fontId = 4,
								textAlign = CENTERMID,
								textScale = 0.8,
								textColor = UICOLORWHITE,
								noCursor = true,
								showDefaultDuringInput = true
							})
							textField:addKeyboardHandlers(function(key)
									textField.textfieldstr[1] = Settings:getKeyName(key)
									textField.pressedKeyId = key
									textField.keyboard = false
									Settings.Stored[item.systemname] = { value = textField.pressedKeyId, reload = item.reload }
									Settings:settingsApplyActivate(item.reload)
								end)
						else
							local textField = TBMenu:spawnTextField2(itemInput, nil, tostring(item.val[1]), item.name, {
								isNumeric = true,
								fontId = 4,
								textAlign = CENTERMID,
								textScale = 0.8,
								textColor = UICOLORWHITE
							})
							textField:addKeyboardHandlers(nil, function()
									if (item.valueVerifyAction) then
										textField.textfieldstr[1] = item.valueVerifyAction(textField.textfieldstr[1]) .. ''
									end
									if (textField.textfieldstr[1] == '') then
										Settings.Stored[item.systemname] = nil
									else
										Settings.Stored[item.systemname] = { value = tonumber(textField.textfieldstr[1]), reload = item.reload }
										Settings:settingsApplyActivate(item.reload)
									end
								end)
						end
					elseif (item.type == DROPDOWN) then
						local itemDropdownBG = itemView:addChild({
							pos = { itemView.size.w / 3 * 2 - 20, 5 },
							size = { itemView.size.w / 3, itemView.size.h - 10 },
							bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
							shapeType = ROUNDED,
							rounded = 3
						})
						local itemDropdown = itemDropdownBG:addChild({
							shift = { 1, 1 },
							bgColor = TB_MENU_DEFAULT_BG_COLOR,
							hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
							interactive = true
						}, true)
						local selectedId = nil
						if (item.selectedAction) then
							selectedId = item.selectedAction()
						end
						TBMenu:spawnDropdown(itemDropdown, item.dropdown, 30, WIN_H - 100, selectedId and item.dropdown[selectedId], { scale = 0.7 }, { scale = 0.6 })
					elseif (item.type == BUTTON) then
						local itemButtonBG = itemView:addChild({
							pos = { itemView.size.w / 3 * 2 - 20, 5 },
							size = { itemView.size.w / 3, itemView.size.h - 10 },
							bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
							shapeType = ROUNDED,
							rounded = 3
						})
						local itemButton = itemButtonBG:addChild({
							shift = { 1, 1 },
							bgColor = TB_MENU_DEFAULT_BG_COLOR,
							hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
							pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
							interactive = true
						}, true)
						itemButton:addMouseHandlers(nil, item.action)
						itemButton:addAdaptedText(false, string.upper(item.text), nil, nil, 4, nil, 0.7)
					end
				end
			end
		end
	end
	local lastElement = listingHolder:addChild({
		pos = { 0, #listElements * elementHeight + elementHeight / 2 },
		size = { listingHolder.size.w, elementHeight / 2 },
		bgColor = listingHolder.bgColor
	})
	table.insert(listElements, lastElement)
	for _, v in pairs(listElements) do
		v:hide()
	end
	local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
	listingHolder.scrollBar = scrollBar

	Settings.ListShift[2] = #listElements * elementHeight
	targetListShift = targetListShift > Settings.ListShift[2] - listingHolder.size.h and Settings.ListShift[2] - listingHolder.size.h or targetListShift
	Settings.ListShift[3] = scrollBar.parent.size.h - scrollBar.size.h
	Settings.ListShift[1] = targetListShift / (Settings.ListShift[2] - listingHolder.size.h) * Settings.ListShift[3]
	TBMenu.CurrentSection.settingsListingHolder = listingHolder

	scrollBar:makeScrollBar(listingHolder, listElements, toReload, Settings.ListShift)

	TBMenu.CurrentSection.settingsInitialized = true
end

function Settings:showMain()
	TB_MENU_SPECIAL_SCREEN_ISOPEN = 6
	Settings.Stored = {}
	Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE or 1)
end

---@alias GraphicsLevel
---| 0 Low (Shaders off)
---| 1 Medium (Shaders and some advanced options on)
---| 2 High (Shaders and advanced options on)

---@return GraphicsLevel level
function Settings.GetLevel()
	if (get_option("shaders") == 0) then return 0 end

	local opts = {
		{ name = "reflection",			val = 1 },
		{ name = "ambientocclusion",	val = 2 },
		{ name = "fluid",				val = 1 },
		{ name = "raytracing",			val = 4 },
		{ name = "softshadow",			val = 1 },
		{ name = "effects",				val = 1 },
		{ name = "obj",					val = 1 },
		{ name = "particles",			val = 1 }
	}
	local total = 0
	for _, v in pairs(opts) do
		if (get_option(v.name) ~= 0) then
			total = total + v.val
		end
	end

	return total >= 6 and 2 or 1
end
