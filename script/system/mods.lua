-- Modern UI mods screen
-- DO NOT MODIFY THIS FILE

require("toriui/uielement3d")
require("system/iofiles")
require("system/menu_manager")
dofile("system/mods_manager.lua")

if (MODS_MENU_MAIN_ELEMENT) then
	MODS_MENU_MAIN_ELEMENT:kill()
	MODS_MENU_MAIN_ELEMENT = nil
	return
end

Mods:showMain()
