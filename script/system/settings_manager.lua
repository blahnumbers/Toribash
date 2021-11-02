-- Settings Manager Class

SETTINGS_LIST_SHIFT = SETTINGS_LIST_SHIFT or { 0, 0, 1 }

local SETTINGS_GRAPHICS = 1
local SETTINGS_EFFECTS = 2
local SETTINGS_AUDIO = 3
local SETTINGS_OTHER = 4
local SETTINGS_ABOUT = 5

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

local TB_MENU_MAIN_SETTINGS = {}

local tbMenuApplySettingsButton = nil

do
	Settings = {}
	Settings.__index = Settings
	local cln = {}
	setmetatable(cln, Settings)
	
	function Settings:quit()
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
		TB_MENU_SETTINGS_SCREEN_ACTIVE = 1
		tbMenuCurrentSection:kill(true)
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function Settings:getNavigationButtons(showBack)
		local navigation = {
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
				action = function() Settings:quit() end,
			},
			{
				text = TB_MENU_LOCALIZED.SETTINGSABOUT,
				action = function() end,
				right = true,
				sectionId = -1,
				action = function()
						Settings:showAbout()
					end
			},
			{
				text = TB_MENU_LOCALIZED.SETTINGSOTHER,
				action = function() end,
				right = true,
				sectionId = SETTINGS_OTHER,
				action = function()
						Settings:showSettings(SETTINGS_OTHER)
					end
			},
			{
				text = TB_MENU_LOCALIZED.SETTINGSAUDIO,
				action = function() end,
				right = true,
				sectionId = SETTINGS_AUDIO,
				action = function()
						Settings:showSettings(SETTINGS_AUDIO)
					end
			},
			{
				text = TB_MENU_LOCALIZED.SETTINGSEFFECTS,
				action = function() end,
				right = true,
				sectionId = SETTINGS_EFFECTS,
				action = function()
						Settings:showSettings(SETTINGS_EFFECTS)
					end
			},
			{
				text = TB_MENU_LOCALIZED.SETTINGSGRAPHICS,
				action = function() end,
				right = true,
				sectionId = SETTINGS_GRAPHICS,
				action = function()
						Settings:showSettings(SETTINGS_GRAPHICS)
					end
			}
		}
		if (showBack) then
			local back = {
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = function()
					Notifications:showMain()
				end,
				width = 130
			}
			table.insert(navigation, back)
		end
		return navigation
	end
	
	function Settings:showAbout()
		usage_event("settingsabout")
		tbMenuUserBar:hide()
		UIScrollbarIgnore = true
		local whiteOverlay = UIElement:new({
			parent = tbMenuMain,
			pos = { 0, 0 },
			size = { WIN_W, WIN_H },
			bgColor = cloneTable(UICOLORWHITE),
			interactive = true
		})
		whiteOverlay.killAction = function() UIScrollbarIgnore = false end
		local slowMode = false
		local speedMultiplier = get_option('framerate') == 30 and 2 or 1
		whiteOverlay:addMouseHandlers(nil, function()
				whiteOverlay:kill()
				tbMenuUserBar:show()
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
		local tbTeam = { 'hagan', 'hampa', 'sir' }
		local teamScale = aboutMover.size.w / #tbTeam
		teamScale = teamScale > 512 and 512 or teamScale
		for i,v in pairs(tbTeam) do
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
			teamMemberName:addAdaptedText(true, v, nil, nil, FONTS.BIG, CENTERBOT, 0.55, nil, nil, 2)
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
			whiteOverlay:addCustomDisplay(nil, function()
					whiteOverlay.bgColor[4] = whiteOverlay.bgColor[4] - 0.05
					if (whiteOverlay.bgColor[4] <= 0) then
						whiteOverlay:kill()
						tbMenuUserBar:show()
					end
				end)
		end
		lastElement:addCustomDisplay(false, function()
				if (lastElement.pos.y + lastElement.size.h < 0) then
					lastElement:kill()
					initOutro()
				end
			end)
	end
	
	function Settings:getSettingsData(id)
		local shaders = TB_MENU_MAIN_SETTINGS.shaders and TB_MENU_MAIN_SETTINGS.shaders.value or get_option("shaders")
		
		if (id == SETTINGS_GRAPHICS) then
			local advancedItems = {
				{
					name = TB_MENU_LOCALIZED.SETTINGSSHADERS,
					type = TOGGLE,
					action = function(val) 
							TB_MENU_MAIN_SETTINGS.shaders = { value = val, id = SHADERS, graphics = true }
							Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
						end,
					val = { TB_MENU_MAIN_SETTINGS.shaders and TB_MENU_MAIN_SETTINGS.shaders.value or get_option("shaders") },
					reload = true
				}
			}
			
			if (shaders == 1) then
				table.insert(advancedItems, {
					name = TB_MENU_LOCALIZED.SETTINGSRAYTRACING,
					type = TOGGLE,
					action = function(val) 
							TB_MENU_MAIN_SETTINGS.raytracing = { value = val, id = RAYTRACING, graphics = true }
						end,
					val = { get_option("raytracing") },
					reload = true
				})
			end
			
			table.insert(advancedItems, {
				name = TB_MENU_LOCALIZED.SETTINGSFRAMERATE,
				type = DROPDOWN,
				selectedAction = function()
						local framerate = get_option("framerate")
						local fixedframerate = get_option("fixedframerate")
						if (fixedframerate == 1) then
							if (framerate == 30) then
								return 1
							elseif (framerate == 60) then
								return 2
							else
								return 3
							end
						end
						return 3
					end,
				dropdown = {
					{
						text = "30 " .. TB_MENU_LOCALIZED.SETTINGSFPS,
						action = function()
								TB_MENU_MAIN_SETTINGS.framerate = { value = 30 }
								TB_MENU_MAIN_SETTINGS.fixedframerate = { value = 1 }
								Settings:settingsApplyActivate()
							end
					},
					{
						text = "60 " .. TB_MENU_LOCALIZED.SETTINGSFPS,
						action = function()
								TB_MENU_MAIN_SETTINGS.framerate = { value = 60 }
								TB_MENU_MAIN_SETTINGS.fixedframerate = { value = 1 }
								Settings:settingsApplyActivate()
							end
					},
					{
						text = "75 " .. TB_MENU_LOCALIZED.SETTINGSFPS,
						action = function()
								TB_MENU_MAIN_SETTINGS.framerate = { value = 75 }
								TB_MENU_MAIN_SETTINGS.fixedframerate = { value = 1 }
								Settings:settingsApplyActivate()
							end
					},
					--[[{
						text = TB_MENU_LOCALIZED.SETTINGSFPSUNCAPPED,
						action = function()
								TB_MENU_MAIN_SETTINGS.framerate = { value = 60 }
								TB_MENU_MAIN_SETTINGS.fixedframerate = { value = 0 }
								Settings:settingsApplyActivate()
							end
					}]]
				}
			})
			table.insert(advancedItems, {
				name = TB_MENU_LOCALIZED.SETTINGSBLOOD,
				type = DROPDOWN,
				selectedAction = function() return get_option("blood") + 1 end,
				dropdown = {
					{
						text = TB_MENU_LOCALIZED.WORDNONE,
						action = function()
							TB_MENU_MAIN_SETTINGS.blood = { value = 0 }
							Settings:settingsApplyActivate()
						end
					},
					{
						text = TB_MENU_LOCALIZED.SETTINGSVANILLA,
						action = function()
							TB_MENU_MAIN_SETTINGS.blood = { value = 1 }
							Settings:settingsApplyActivate()
						end
					},
					{
						text = TB_MENU_LOCALIZED.SETTINGSMODERN,
						action = function()
							TB_MENU_MAIN_SETTINGS.blood = { value = 2 }
							Settings:settingsApplyActivate()
						end
					},
				}
			})
			
			if (shaders == 1) then
				table.insert(advancedItems, {
					name = TB_MENU_LOCALIZED.SETTINGSFLUIDBLOOD,
					type = TOGGLE,
					action = function(val) 
							TB_MENU_MAIN_SETTINGS.fluid = { value = val, id = FLUIDBLOOD, graphics = true }
						end,
					val = { get_option("fluid") },
					reload = true
				})
				table.insert(advancedItems, {
					name = TB_MENU_LOCALIZED.SETTINGSFLOORREFLECTIONS,
					type = TOGGLE,
					action = function(val) 
							TB_MENU_MAIN_SETTINGS.reflection = { value = val, id = REFLECTIONS, graphics = true }
						end,
					val = { get_option("reflection") },
					reload = true
				})
				table.insert(advancedItems, {
					name = TB_MENU_LOCALIZED.SETTINGSSOFTSHADOWS,
					type = TOGGLE,
					action = function(val) 
							TB_MENU_MAIN_SETTINGS.softshadow = { value = val, id = SOFTSHADOWS, graphics = true }
						end,
					val = { get_option("softshadow") },
					reload = true
				})
				table.insert(advancedItems, {
					name = TB_MENU_LOCALIZED.SETTINGSAMBIENTOCCLUSION,
					type = TOGGLE,
					action = function(val) 
							TB_MENU_MAIN_SETTINGS.ambientocclusion = { value = val, id = AMBIENTOCCLUSION, graphics = true }
						end,
					val = { get_option("ambientocclusion") },
					reload = true
				})
			end
			
			table.insert(advancedItems, {
				name = TB_MENU_LOCALIZED.SETTINGSDISABLEANIMATIONS,
				type = TOGGLE,
				action = function(val) 
						TB_MENU_MAIN_SETTINGS.uilight = { value = val }
					end,
				val = { get_option("uilight") },
				reload = true
			})
			table.insert(advancedItems, {
				name = TB_MENU_LOCALIZED.SETTINGSJOINTFLASH,
				type = TOGGLE,
				action = function(val) 
						TB_MENU_MAIN_SETTINGS.jointflash = { value = val }
					end,
				val = { get_option("jointflash") },
				reload = true
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
												{ opt = "shader", val = 0, graphics = true, id = SHADERS },
												{ opt = "fluid", val = 0, graphics = true, id = FLUIDBLOOD },
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
												{ opt = "bodytextures", val = 0, graphics = true, id = BODYTEXTURES },
												{ opt = "effects", val = 0 },
												{ opt = "particles", val = 0 },
												{ opt = "fixedframerate", val = 1 },
												{ opt = "uilight", val = 1 }
											}
											for i,v in pairs(options) do
												if (v.graphics) then
													set_graphics_option(v.id, v.val)
												else
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
											{ opt = "shader", val = 0, graphics = true, id = SHADERS },
											{ opt = "fluid", val = 0, graphics = true, id = FLUIDBLOOD },
											{ opt = "framerate", val = 60 },
											{ opt = "reflection", val = 0, graphics = true, id = REFLECTIONS },
											{ opt = "softshadow", val = 0, graphics = true, id = SOFTSHADOWS },
											{ opt = "ambientocclusion", val = 0, graphics = true, id = AMBIENTOCCLUSION },
											{ opt = "bumpmapping", val = 0, graphics = true, id = BUMPMAPPING },
											{ opt = "raytracing", val = 0, graphics = true, id = RAYTRACING },
											{ opt = "trails", val = 1 },
											{ opt = "hair", val = 1 },
											{ opt = "hairquality", val = 0 },
											{ opt = "obj", val = 0 },
											{ opt = "bodytextures", val = 1, graphics = true, id = BODYTEXTURES },
											{ opt = "effects", val = 1 },
											{ opt = "particles", val = 1 },
											{ opt = "fixedframerate", val = 1 },
											{ opt = "uilight", val = 1 }
										}
										for i,v in pairs(options) do
											if (v.graphics) then
												set_graphics_option(v.id, v.val)
											else
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
											{ opt = "shader", val = 1, graphics = true, id = SHADERS },
											{ opt = "fluid", val = 0, graphics = true, id = FLUIDBLOOD },
											{ opt = "framerate", val = 60 },
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
											{ opt = "uilight", val = 0 }
										}
										for i,v in pairs(options) do
											if (v.graphics) then
												set_graphics_option(v.id, v.val)
											else
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
											{ opt = "shader", val = 1, graphics = true, id = SHADERS },
											{ opt = "fluid", val = 1, graphics = true, id = FLUIDBLOOD },
											{ opt = "framerate", val = 75 },
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
											{ opt = "uilight", val = 0 }
										}
										for i,v in pairs(options) do
											if (v.graphics) then
												set_graphics_option(v.id, v.val)
											else
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
											{ opt = "shader", val = 1, graphics = true, id = SHADERS },
											{ opt = "fluid", val = 1, graphics = true, id = FLUIDBLOOD },
											{ opt = "framerate", val = 75 },
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
											{ opt = "uilight", val = 0 }
										}
										for i,v in pairs(options) do
											if (v.graphics) then
												set_graphics_option(v.id, v.val)
											else
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
				}
			}
		elseif (id == SETTINGS_EFFECTS) then
			local generalItems = { }
			if (shaders == 1) then
				table.insert(generalItems, {
					name = TB_MENU_LOCALIZED.SETTINGSITEMEFFECTS,
					type = TOGGLE,
					action = function(val) 
							TB_MENU_MAIN_SETTINGS.itemeffects = { value = val, id = ITEMEFFECTS, graphics = true }
						end,
					val = { get_option("itemeffects") },
					reload = true
				})
			end
			table.insert(generalItems, {
				name = TB_MENU_LOCALIZED.SETTINGSEFFECTSINFO,
				type = DROPDOWN,
				selectedAction = function()
						local effects = TB_MENU_MAIN_SETTINGS.effects and TB_MENU_MAIN_SETTINGS.effects.value or get_option("effects")
						if (effects == 0) then
							return 1
						elseif (effects == 1) then
							return 2
						else
							return 3
						end
					end,
				dropdown = {
					{
						text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
						value = 0,
						name = "effects",
						action = function()
								TB_MENU_MAIN_SETTINGS.effects = { value = 0 }
								Settings:settingsApplyActivate()
								Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
							end
					},
					{
						text = TB_MENU_LOCALIZED.SETTINGSREPLAYSONLY,
						value = 1,
						name = "effects",
						action = function()
								TB_MENU_MAIN_SETTINGS.effects = { value = 1 }
								Settings:settingsApplyActivate()
								Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
							end
					},
					{
						text = TB_MENU_LOCALIZED.SETTINGSENABLED,
						value = 3,
						name = "effects",
						action = function()
								TB_MENU_MAIN_SETTINGS.effects = { value = 3 }
								Settings:settingsApplyActivate()
								Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
							end
					},
				}
			})
			
			local settingsCustomization = nil
			local effects = TB_MENU_MAIN_SETTINGS.effects and TB_MENU_MAIN_SETTINGS.effects.value or get_option("effects")
			if (effects > 0) then
				settingsCustomization = {
					name = TB_MENU_LOCALIZED.SETTINGSPLAYERCUSTOMIZATION,
					items = {
						{
							name = TB_MENU_LOCALIZED.SETTINGSBODYTEXTURES,
							type = TOGGLE,
							action = function(val) 
									TB_MENU_MAIN_SETTINGS.bodytextures = { value = val, id = BODYTEXTURES, graphics = true }
								end,
							val = { get_option("bodytextures") },
							reload = true
						},
						{
							name = TB_MENU_LOCALIZED.SETTINGSTRAILS,
							type = TOGGLE,
							systemname = "trails",
							val = { get_option("trails") }
						},
						{
							name = TB_MENU_LOCALIZED.SETTINGSFLAMES,
							type = TOGGLE,
							systemname = "particles",
							val = { get_option("particles") }
						},
						{
							name = TB_MENU_LOCALIZED.SETTINGSHAIRS,
							type = TOGGLE,
							systemname = "hair",
							val = { get_option("hair") }
						},
						{
							name = TB_MENU_LOCALIZED.SETTINGSOBJMODELS,
							type = TOGGLE,
							systemname = "obj",
							val = { get_option("obj") }
						},
						{
							name = TB_MENU_LOCALIZED.SETTINGSJOINTOBJOPACITY,
							type = SLIDER,
							maxValue = 100,
							systemname = "jointobjopacity",
							val = { get_option("jointobjopacity") }
						},
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
								local volume = get_option("soundvolume")
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
								local volume = get_option("soundvolume")
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
							action = function()
								TBMenu:showHotkeys()
							end
						},
						{
							name = TB_MENU_LOCALIZED.SETTINGSREPLAYHUDTOGGLE,
							type = INPUT,
							inputspecial = true,
							systemname = "replayhudtoggle",
							val = { get_option("replayhudtoggle") }
						},
						{
							name = TB_MENU_LOCALIZED.SETTINGSMOUSEBUTTONS,
							type = DROPDOWN,
							systemname = "mousebuttons",
							selectedAction = function()
									return get_option("mousebuttons") + 1
								end,
							dropdown = {
								{
									text = TB_MENU_LOCALIZED.SETTINGSMOUSEBUTTONS0,
									action = function()
											TB_MENU_MAIN_SETTINGS.mousebuttons = { value = 0 }
											Settings:settingsApplyActivate()
										end
								},
								{
									text = TB_MENU_LOCALIZED.SETTINGSMOUSEBUTTONS1,
									action = function()
											TB_MENU_MAIN_SETTINGS.mousebuttons = { value = 1 }
											Settings:settingsApplyActivate()
										end
								},
								{
									text = TB_MENU_LOCALIZED.SETTINGSMOUSEBUTTONS2,
									action = function()
											TB_MENU_MAIN_SETTINGS.mousebuttons = { value = 2 }
											Settings:settingsApplyActivate()
										end
								}
							}
						},
						{
							name = TB_MENU_LOCALIZED.SETTINGSREPLAYCACHE,
							type = DROPDOWN,
							systemname = "replaycache",
							selectedAction = function()
									return get_option("replaycache") + 1
								end,
							dropdown = {
								{
									text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
									action = function()
											TB_MENU_MAIN_SETTINGS.replaycache = { value = 0 }
											Settings:settingsApplyActivate()
										end
								},
								{
									text = TB_MENU_LOCALIZED.SETTINGSREPLAYCACHESECONDPLAYTHROUGH,
									action = function()
											TB_MENU_MAIN_SETTINGS.replaycache = { value = 1 }
											Settings:settingsApplyActivate()
										end
								},
								{
									text = TB_MENU_LOCALIZED.SETTINGSENABLED,
									action = function()
											TB_MENU_MAIN_SETTINGS.replaycache = { value = 2 }
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
											TB_MENU_MAIN_SETTINGS.memsize = { value = 0 }
											Settings:settingsApplyActivate()
										end
								},
								{
									text = 4096 .. " " .. TB_MENU_LOCALIZED.SETTINGSREPLAYFRAMES,
									action = function()
											TB_MENU_MAIN_SETTINGS.memsize = { value = 1 }
											Settings:settingsApplyActivate()
										end
								},
								{
									text = 8192 .. " " .. TB_MENU_LOCALIZED.SETTINGSREPLAYFRAMES,
									action = function()
											TB_MENU_MAIN_SETTINGS.memsize = { value = 2 }
											Settings:settingsApplyActivate()
										end
								},
							}
						},
						{
							name = TB_MENU_LOCALIZED.SETTINGSAUTOSAVE,
							type = TOGGLE,
							systemname = "autosave",
							val = { get_option("autosave") }
						},
						{
							name = TB_MENU_LOCALIZED.SETTINGSGAMERULES,
							type = TOGGLE,
							systemname = "rememberrules",
							val = { get_option("rememberrules") }
						},
						{
							name = TB_MENU_LOCALIZED.SETTINGSBACKGROUNDCLICK,
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
					name = TB_MENU_LOCALIZED.SETTINGSCHAT,
					items = {
						{
							name = TB_MENU_LOCALIZED.SETTINGSCHATTOGGLE,
							type = INPUT,
							inputspecial = true,
							systemname = "chattoggle",
							val = { get_option("chattoggle") }
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
								TB_MENU_MAIN_SETTINGS.tooltip = { value = val }
								if (val == 1 and not TOOLTIP_ACTIVE) then
									dofile("system/tooltip_manager.lua")
									Tooltip:create()
								end
							end,
							val = { get_option("tooltip") }
						},
						{
							name = TB_MENU_LOCALIZED.SETTINGSMOVEMEMORY,
							type = TOGGLE,
							systemname = "movememory",
							action = function(val)
								TB_MENU_MAIN_SETTINGS.movememory = { value = val }
								if (val == 1 and not MOVEMEMORY_ACTIVE) then
									dofile("system/movememory_manager.lua")
									MoveMemory:spawnHotkeyListener()
								end
							end,
							val = { get_option("movememory") }
						},
						{
							name = TB_MENU_LOCALIZED.SETTINGSBROADCASTS,
							type = DROPDOWN,
							systemname = "showbroadcast",
							selectedAction = function()
									return get_option("showbroadcast") + 1
								end,
							dropdown = {
								{
									text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
									action = function()
											TB_MENU_MAIN_SETTINGS.showbroadcast = { value = 0 }
											Settings:settingsApplyActivate()
										end
								},
								{
									text = TB_MENU_LOCALIZED.SETTINGSSHOWINMP,
									action = function()
											TB_MENU_MAIN_SETTINGS.showbroadcast = { value = 1 }
											Settings:settingsApplyActivate()
										end
								},
								{
									text = TB_MENU_LOCALIZED.SETTINGSALWAYSSHOW,
									action = function()
											TB_MENU_MAIN_SETTINGS.showbroadcast = { value = 2 }
											Settings:settingsApplyActivate()
										end
								},
							}
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
								TB_MENU_MAIN_SETTINGS.tooltip = { value = val }
							end,
							val = { get_option("usagestats") }
						}
					}
				}
			}
		end
	end
	
	function Settings:getGraphicsPreset()
		return function()
				local options = {
					"shaders", "fluid", "framerate", "reflection", "softshadow", "ambientocclusion", "bumpmapping", "raytracing", "trails", "hair", "hairquality", "obj", "effects", "particles", "bodytextures"
				}
				local presets = {
					"0030000000000000", "0060000001100111", "1060000101101311", "1175111101111311", "1175111111111311"
				}
				local userSetting = ""
				for i,v in pairs(options) do
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
		local files = get_files("data/language", "txt")
		for i,v in pairs(files) do
			table.insert(languages, { name = v:gsub("%.txt$", "") })
		end
		local currentLang, langFile = get_language(), nil
		for i,v in pairs(languages) do
			if (v.name == currentLang) then
				langFile = v
				table.remove(languages, i)
				break
			end
		end
		table.insert(languages, 1, langFile)
		for i,v in pairs(languages) do
			local newMenuFile = Files:open("system/language/" .. v.name .. ".txt")
			if (not newMenuFile.data) then
				v.newMenuDisabled = true
			else
				newMenuFile:close()
			end
			table.insert(dropdown, {
				text = v.newMenuDisabled and v.name .. " (" .. TB_MENU_LOCALIZED.SETTINGSBASEHUDONLY .. ")" or v.name,
				action = function()
						set_language(v.name)
						save_custom_config()
						reload_graphics()
						Settings:settingsApplyActivate()
					end
			})
		end
		return dropdown
	end
	
	function Settings:getResolutionItems()
		local fullscreen = TB_MENU_MAIN_SETTINGS.fullscreen and TB_MENU_MAIN_SETTINGS.fullscreen.value or get_option("fullscreen")
		local items
		if (fullscreen == 1) then
			items = {
				{
					name = TB_MENU_LOCALIZED.SETTINGSFULLSCREEN and TB_MENU_LOCALIZED.SETTINGSFULLSCREEN or TB_MENU_LOCALIZED.SETTINGSWINDOWED,
					type = TOGGLE,
					action = function(val)
							TB_MENU_MAIN_SETTINGS.fullscreen = { value = TB_MENU_LOCALIZED.SETTINGSFULLSCREEN and val or 1 - val, reload = true }
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
							TB_MENU_MAIN_SETTINGS.borderless = { id = BORDERLESS, value = val, graphics = true }
						end,
					val = { TB_MENU_MAIN_SETTINGS["borderless"] and TB_MENU_MAIN_SETTINGS["borderless"].value or get_option("borderless") },
					inactive = get_dpiawareness().DPISCALING ~= 1
				})
			end
		else
			-- Use these values instead of get_option() width/height to get highdpi-adapted values on macOS
			local optionWidth, optionHeight = get_window_size()
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
						local maxWidth, maxHeight = get_maximum_window_size()
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
						local maxWidth, maxHeight = get_maximum_window_size()
						return (val > maxHeight and maxHeight or val)
					end
				},
				{
					name = TB_MENU_LOCALIZED.SETTINGSFULLSCREEN and TB_MENU_LOCALIZED.SETTINGSFULLSCREEN or TB_MENU_LOCALIZED.SETTINGSWINDOWED,
					type = TOGGLE,
					action = function(val)
							TB_MENU_MAIN_SETTINGS.fullscreen = { value = TB_MENU_LOCALIZED.SETTINGSFULLSCREEN and val or 1 - val, reload = true }
							Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE, true)
						end,
					val = { TB_MENU_LOCALIZED.SETTINGSFULLSCREEN and fullscreen or 1 - fullscreen }
				}
			}
		end
		if (PLATFORM == "APPLE") then
			table.insert(items, {
				name = TB_MENU_LOCALIZED.SETTINGSHIGHDPI,
				type = TOGGLE,
				action = function(val)
						TB_MENU_MAIN_SETTINGS.highdpi = { id = HIGHDPI, value = val, graphics = true, reload = true }
					end,
				val = { get_option("highdpi") }
			})
		else
			table.insert(items, {
				name = TB_MENU_LOCALIZED.SETTINGSGUISCALING,
				minValue = 100,
				minValueDisp = 1,
				maxValue = 200,
				maxValueDisp = 2,
				type = SLIDER,
				systemname = "highdpi",
				onUpdate = function(slider)
					TB_MENU_MAIN_SETTINGS.highdpi.value = math.floor((tonumber(slider.label.labelText[1]) or 1) / 10 + 0.5)
					TB_MENU_MAIN_SETTINGS.highdpi.id = HIGHDPI
					TB_MENU_MAIN_SETTINGS.highdpi.graphics = true
					TB_MENU_MAIN_SETTINGS.highdpi.reload = true
					slider.label.labelText[1] = math.floor((tonumber(slider.label.labelText[1]) or 1) / 10 + 0.5) / 10 .. 'x'
				end,
				val = { get_option("highdpi") }
			})
		end
		if (PLATFORM == "WINDOWS" and get_dpiawareness().DPISCALING ~= 1) then
			table.insert(items, {
				name = TB_MENU_LOCALIZED.SETTINGSDPIAWARENESS,
				type = TOGGLE,
				action = function(val)
						TB_MENU_MAIN_SETTINGS.dpiawareness = { value = val }
						-- Don't touch borderless - we risk ending up with a borderless window in top left corner
						--[[if (get_option("borderless") == 1 and val == 0) then
							TB_MENU_MAIN_SETTINGS.borderless = { id = BORDERLESS, value = 0, graphics = true }
						elseif (get_option("borderless") == 0 and val == 1) then
							TB_MENU_MAIN_SETTINGS.borderless = { id = BORDERLESS, value = 1, graphics = true }
						end]]
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
						TB_MENU_MAIN_SETTINGS["soundcat" .. option] = { value = 1, default = 0 }
						Settings:settingsApplyActivate()
					end
			},
			{
				text = TB_MENU_LOCALIZED.SETTINGSONLYDEFAULTSOUNDS,
				action = function()
						TB_MENU_MAIN_SETTINGS["soundcat" .. option] = { value = 1, default = 1 }
						Settings:settingsApplyActivate()
					end
			},
			{
				text = TB_MENU_LOCALIZED.SETTINGSDISABLED,
				action = function()
						TB_MENU_MAIN_SETTINGS["soundcat" .. option] = { value = 0, default = 0 }
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
			return "R Alt"
		elseif (key == 308) then
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
	
	function Settings:spawnSlider(viewElement, sliderTable)
		local slider
		slider = TBMenu:spawnSlider(viewElement, nil, nil, nil, nil, nil, nil, sliderTable.val[1], sliderTable, function(val)
				TB_MENU_MAIN_SETTINGS[sliderTable.systemname] = { value = val }
				Settings:settingsApplyActivate()
				if (sliderTable.onUpdate) then
					sliderTable.onUpdate(slider)
				end
			end, nil, function()
				if (sliderTable.onMouseUp) then
					sliderTable.onMouseUp(slider)
				end
			end)
		return slider
		--[[
		local maxVal = sliderTable.maxValue or 1
		local minVal = sliderTable.minValue or 0
		local minText = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { 30, viewElement.size.h }
		})
		minText:addAdaptedText(false, minVal .. "", nil, nil, 4, RIGHTMID, 0.7)
		local maxText = UIElement:new({
			parent = viewElement,
			pos = { -30, 0 },
			size = { 30, viewElement.size.h }
		})
		maxText:addAdaptedText(false, maxVal == 128 and 100 or maxVal .. "", nil, nil, 4, LEFTMID, 0.7)
		local sliderBG = UIElement:new({
			parent = viewElement,
			pos = { 35, 0 },
			size = { viewElement.size.w - 70, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			interactive = true
		})
		sliderBG:addCustomDisplay(true, function()
				set_color(unpack(sliderBG.bgColor))
				draw_quad(sliderBG.pos.x, sliderBG.pos.y + viewElement.size.h / 2 - 3, sliderBG.size.w, 6)
			end)
		local sliderPos = 0
		sliderTable.val[1] = sliderTable.val[1] > maxVal and 1 or sliderTable.val[1] / maxVal
		sliderPos = sliderTable.val[1] * (sliderBG.size.w - 20)
		local slider = UIElement:new({
			parent = sliderBG,
			pos = { sliderPos, -sliderBG.size.h / 2 - 10 },
			size = { 20, 20 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = ROUNDED,
			rounded = 20
		})
		slider:addMouseHandlers(function()
				slider.pressed = true
				slider.pressedPos = slider:getLocalPos()
			end, function()
				slider.pressed = false
			end, function()
				if (slider.pressed) then
					local xPos = MOUSE_X - sliderBG.pos.x - slider.pressedPos.x
					if (xPos < 0) then
						xPos = 0
					elseif (xPos > sliderBG.size.w - slider.size.w) then
						xPos = sliderBG.size.w - slider.size.w
					end
					if (sliderTable.boolean) then
						if (xPos + slider.size.w / 2 > sliderBG.size.w / 2) then
							xPos = sliderBG.size.w - slider.size.w
						else
							xPos = 0
						end
					end
					slider:moveTo(xPos, nil)
					sliderTable.val[1] = xPos / (sliderBG.size.w - 20) * (maxVal - minVal) + minVal
					TB_MENU_MAIN_SETTINGS[sliderTable.systemname] = { value = sliderTable.val[1] }
					Settings:settingsApplyActivate()
				end
			end)
		sliderBG:addMouseHandlers(function()
			local pos = sliderBG:getLocalPos()
			local xPos = pos.x - slider.size.w / 2
			if (xPos < 0) then
				xPos = 0
			elseif (xPos > sliderBG.size.w - slider.size.w) then
				xPos = sliderBG.size.w - slider.size.w
			end
			slider:moveTo(xPos)
			sliderTable.val[1] = xPos / (sliderBG.size.w - 20) * (maxVal - minVal) + minVal
			TB_MENU_MAIN_SETTINGS[sliderTable.systemname] = { value = sliderTable.val[1] }
			Settings:settingsApplyActivate()
		end)
		return slider]]
	end
	
	function Settings:spawnToggle(viewElement, toggle, i)
		local toggleTable = toggle.val
		local toggleBG = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h },
			shapeType = ROUNDED,
			rounded = 3,
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		local toggleView = UIElement:new({
			parent = toggleBG,
			pos = { 1, 1 },
			size = { toggleBG.size.w - 2, toggleBG.size.h - 2 },
			shapeType = ROUNDED,
			rounded = 3,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			inactiveColor = TB_MENU_DEFAULT_LIGHTEST_COLOR,
			interactive = true
		})
		if (toggle.inactive) then
			toggleView:deactivate(true)
		end
		local toggleIcon = UIElement:new({
			parent = toggleView,
			pos = { 0, 0 },
			size = { toggleView.size.w, toggleView.size.h },
			bgImage = "../textures/menu/general/buttons/checkmark.tga"
		})
		if (toggleTable[i] == 0) then
			toggleIcon:hide(true)
		end
		toggleView:addMouseHandlers(nil, function()
				toggleTable[i] = 1 - toggleTable[i]
				if (toggleTable[i] == 1) then
					toggleIcon:show(true)
				else
					toggleIcon:hide(true)
				end
				toggle.action(toggleTable[i])
				Settings:settingsApplyActivate(toggle.reload)
			end)
	end
	
	function Settings:settingsApplyActivate(restart)
		if (not tbMenuApplySettingsButton.isactive or restart) then
			tbMenuApplySettingsButton:activate(true)
			tbMenuApplySettingsButton:addAdaptedText(false, TB_MENU_LOCALIZED.SETTINGSAPPLY .. (restart and " (" .. TB_MENU_LOCALIZED.SETTINGSRESTARTREQUIRED .. ")" or ""))
		end	
	end
	
	function Settings:setChatCensorSettings()
		if (not TB_MENU_MAIN_SETTINGS.chatcensor and not TB_MENU_MAIN_SETTINGS.chatcensorhidesystem) then
			return
		end
		
		local chatcensor = get_option("chatcensor")
		local wordfilter, hidesystem = TB_MENU_MAIN_SETTINGS.chatcensor and TB_MENU_MAIN_SETTINGS.chatcensor.value or (chatcensor % 2), TB_MENU_MAIN_SETTINGS.chatcensorhidesystem and TB_MENU_MAIN_SETTINGS.chatcensorhidesystem.value or (chatcensor > 1 and 1 or 0)

		TB_MENU_MAIN_SETTINGS.chatcensorhidesystem = nil
		TB_MENU_MAIN_SETTINGS.chatcensor = { value = wordfilter + hidesystem * 2 }
	end
	
	function Settings:showSettings(id, keepStoredSettings)
		if (not keepStoredSettings) then
			usage_event("settings" .. id)
		end
		if (tbMenuCurrentSection.settingsInitialized == false) then return end
		tbMenuCurrentSection.settingsInitialized = false
		TB_MENU_SETTINGS_SCREEN_ACTIVE = id
		
		local targetListShift = keepStoredSettings and ((tbMenuCurrentSection.settingsListingHolder.shift.y < 0 and -tbMenuCurrentSection.settingsListingHolder.shift.y or tbMenuCurrentSection.settingsListingHolder.size.h) - tbMenuCurrentSection.settingsListingHolder.size.h) or -1
		
		local applySettingsButtonActive = tbMenuApplySettingsButton and tbMenuApplySettingsButton.isactive
		local applySettingsButtonText = applySettingsButtonActive and tbMenuApplySettingsButton.str
		
		tbMenuCurrentSection:kill(true)
		
		local lastListHeight = SETTINGS_LIST_SHIFT[2]
		local lastListProgress = SETTINGS_LIST_SHIFT[1] > 0 and SETTINGS_LIST_SHIFT[1] / SETTINGS_LIST_SHIFT[3] or 0
		
		local settingsData = Settings:getSettingsData(id)
		local settingsMain = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local elementHeight = 50
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(settingsMain, elementHeight, elementHeight, 20)
		
		TBMenu:addBottomBloodSmudge(botBar, 1)
		tbMenuApplySettingsButton = UIElement:new({
			parent = botBar,
			pos = { botBar.size.w / 4, 10 },
			size = { botBar.size.w / 2, botBar.size.h - 10 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			inactiveColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			shapeType = ROUNDED,
			rounded = 5
		})
		tbMenuApplySettingsButton:addAdaptedText(false, TB_MENU_LOCALIZED.SETTINGSNOCHANGES)
		tbMenuApplySettingsButton:addMouseHandlers(nil, function()
				local reload = false
				Settings:setChatCensorSettings()
				if (TB_MENU_MAIN_SETTINGS["fullscreen"] and TB_MENU_MAIN_SETTINGS["fullscreen"].value == 1 and not SETTINGS_LAST_RESOLUTION) then
					SETTINGS_LAST_RESOLUTION = { WIN_W, WIN_H }
				elseif (not TB_MENU_MAIN_SETTINGS["borderless"]) then
					SETTINGS_LAST_RESOLUTION = nil
				end
				for i,v in pairs(TB_MENU_MAIN_SETTINGS) do
					if (i:find("soundcat")) then
						local catid = i:gsub("^soundcat", "")
						set_sound_category(tonumber(catid), v.value, v.default)
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
							TBMenu:showDataError(TB_MENU_LOCALIZED.SETTINGSAPPLIEDAFTERRESTART)
						end
					end
				end
				if (TB_MENU_MAIN_SETTINGS.chatcensor) then
					dofile("system/ignore_manager.lua")
					if (TB_MENU_MAIN_SETTINGS.chatcensor.value > 0) then
						ChatIgnore:activate()
					else
						ChatIgnore:deactivate()
					end
				end
				if (TB_MENU_MAIN_SETTINGS.showbroadcast) then
					dofile("system/broadcast_manager.lua")
					if (TB_MENU_MAIN_SETTINGS.showbroadcast.value > 0) then
						Broadcasts:activate()
					else
						Broadcasts:deactivate()
					end
				end
				if (not keepStoredSettings) then
					TB_MENU_MAIN_SETTINGS = {}
				end
				tbMenuApplySettingsButton:deactivate(true)
				tbMenuApplySettingsButton:addAdaptedText(false, TB_MENU_LOCALIZED.SETTINGSNOCHANGES)
				save_custom_config()
				if (reload) then
					reload_graphics()
				end
			end)
		tbMenuApplySettingsButton:deactivate(true)
		
		if (applySettingsButtonActive) then
			tbMenuApplySettingsButton:activate(true)
			tbMenuApplySettingsButton:addAdaptedText(false, applySettingsButtonText)
		end
		
		local listElements = {}
		for i,section in pairs(settingsData) do
			local sectionName = UIElement:new({
				parent = listingHolder,
				pos = { 20, #listElements * elementHeight },
				size = { listingHolder.size.w - 40, elementHeight }
			})
			sectionName:addAdaptedText(true, section.name, nil, -3, FONTS.BIG, LEFTBOT, 0.6)
			table.insert(listElements, sectionName)
			for i,item in pairs(section.items) do
				local itemHolder = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				table.insert(listElements, itemHolder)
				local itemView = UIElement:new({
					parent = itemHolder,
					pos = { 20, 3 },
					size = { itemHolder.size.w - 40, itemHolder.size.h - 6 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				local shiftX = 20
				if (item.hint) then
					local hintIcon = UIElement:new({
						parent = itemView,
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
					popup:moveTo(itemView.size.h - 9, -(popup.size.h - itemView.size.h + 14) / 2, true)
					shiftX = shiftX + hintIcon.size.w + 5
				end
				local itemName = UIElement:new({
					parent = itemView,
					pos = { shiftX, 0 },
					size = { itemView.size.w / 2 - 10 - shiftX, itemView.size.h }
				})
				itemName:addAdaptedText(true, item.name, nil, nil, nil, LEFTMID)
				if (item.type == SLIDER) then
					local itemSlider = UIElement:new({
						parent = itemView,
						pos = { itemView.size.w / 2 + 10, 5 },
						size = { itemView.size.w / 2 - 30, itemView.size.h - 10 }
					})
					Settings:spawnSlider(itemSlider, item)
				elseif (item.type == TOGGLE) then
					local itemToggle = UIElement:new({
						parent = itemView,
						pos = { -itemView.size.h - 10, 5 },
						size = { itemView.size.h - 10, itemView.size.h - 10 }
					})
					if (not item.action) then
						item.action = function(val)
							TB_MENU_MAIN_SETTINGS[item.systemname] = { value = val }
						end
					end
					Settings:spawnToggle(itemToggle, item, 1)
				elseif (item.type == INPUT) then
					local itemInput = UIElement:new({
						parent = itemView,
						pos = { itemView.size.w / 3 * 2 - 20, 5 },
						size = { itemView.size.w / 3, itemView.size.h - 10 },
						bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						shapeType = ROUNDED,
						rounded = 3
					})
					if (item.inputspecial) then
						local textField = TBMenu:spawnTextField(itemInput, nil, nil, nil, nil, Settings:getKeyName(item.val[1]), true, nil, 0.8, UICOLORWHITE, item.name, CENTERMID, true)
						textField:addKeyboardHandlers(function(key)
								textField.textfieldstr[1] = Settings:getKeyName(key)
								textField.pressedKeyId = key
							end, function()
								TB_MENU_MAIN_SETTINGS[item.systemname] = { value = textField.pressedKeyId, reload = item.reload }
								Settings:settingsApplyActivate(item.reload)
							end)
					else
						local textField = TBMenu:spawnTextField(itemInput, nil, nil, nil, nil, item.val[1] .. "", true, nil, 0.8, UICOLORWHITE, item.name, CENTERMID)
						textField:addKeyboardHandlers(nil, function()
								if (item.valueVerifyAction) then
									textField.textfieldstr[1] = item.valueVerifyAction(textField.textfieldstr[1]) .. ''
								end
								if (textField.textfieldstr[1] == '') then
									TB_MENU_MAIN_SETTINGS[item.systemname] = nil
								else
									TB_MENU_MAIN_SETTINGS[item.systemname] = { value = tonumber(textField.textfieldstr[1]), reload = item.reload }
									Settings:settingsApplyActivate(item.reload)
								end
							end)
					end
				elseif (item.type == DROPDOWN) then
					local itemDropdownBG = UIElement:new({
						parent = itemView,
						pos = { itemView.size.w / 3 * 2 - 20, 5 },
						size = { itemView.size.w / 3, itemView.size.h - 10 },
						bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						shapeType = ROUNDED,
						rounded = 3
					})
					local itemDropdown = UIElement:new({
						parent = itemDropdownBG,
						pos = { 1, 1 },
						size = { itemDropdownBG.size.w - 2, itemDropdownBG.size.h - 2 },
						bgColor = TB_MENU_DEFAULT_BG_COLOR,
						hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
						interactive = true,
						shapeType = ROUNDED,
						rounded = 3
					})
					local selectedId = 1
					if (item.selectedAction) then
						selectedId = item.selectedAction()
					end
					TBMenu:spawnDropdown(itemDropdown, item.dropdown, 30, WIN_H - 100, item.dropdown[selectedId], { scale = 0.7 }, { scale = 0.6 })
				elseif (item.type == BUTTON) then
					local itemButtonBG = UIElement:new({
						parent = itemView,
						pos = { itemView.size.w / 3 * 2 - 20, 5 },
						size = { itemView.size.w / 3, itemView.size.h - 10 },
						bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
						shapeType = ROUNDED,
						rounded = 3
					})
					local itemButton = UIElement:new({
						parent = itemButtonBG,
						pos = { 1, 1 },
						size = { itemButtonBG.size.w - 2, itemButtonBG.size.h - 2 },
						bgColor = TB_MENU_DEFAULT_BG_COLOR,
						hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
						pressedColor = TB_MENU_DEFAULT_DARKER_COLOR,
						interactive = true,
						shapeType = ROUNDED,
						rounded = 3
					})
					itemButton:addMouseHandlers(nil, item.action)
					itemButton:addAdaptedText(false, string.upper("Press to show"), nil, nil, 4, nil, 0.7)
				end
			end
		end
		local lastElement = UIElement:new({
			parent = listingHolder,
			pos = { 0, #listElements * elementHeight + elementHeight / 2 },
			size = { listingHolder.size.w, elementHeight / 2 },
			bgColor = listingHolder.bgColor
		})
		table.insert(listElements, lastElement)
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = scrollBar
		
		SETTINGS_LIST_SHIFT[2] = #listElements * elementHeight
		targetListShift = targetListShift > SETTINGS_LIST_SHIFT[2] - listingHolder.size.h and SETTINGS_LIST_SHIFT[2] - listingHolder.size.h or targetListShift
		SETTINGS_LIST_SHIFT[3] = scrollBar.parent.size.h - scrollBar.size.h
		SETTINGS_LIST_SHIFT[1] = targetListShift / (SETTINGS_LIST_SHIFT[2] - listingHolder.size.h) * SETTINGS_LIST_SHIFT[3]
		tbMenuCurrentSection.settingsListingHolder = listingHolder
		
		scrollBar:makeScrollBar(listingHolder, listElements, toReload, SETTINGS_LIST_SHIFT)
		
		tbMenuCurrentSection.settingsInitialized = true
	end
	
	function Settings:showMain()
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 6
		Settings:showSettings(TB_MENU_SETTINGS_SCREEN_ACTIVE or 1)
	end
end
