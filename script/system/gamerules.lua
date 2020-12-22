-- Modern UI gamerules screen
-- DO NOT MODIFY THIS FILE

require("toriui/uielement3d")
require("system/iofiles")
require("system/menu_manager")
dofile("system/gamerules_manager.lua")

if (GAMERULES_MENU_MAIN_ELEMENT) then
	GAMERULES_MENU_MAIN_ELEMENT:kill()
	GAMERULES_MENU_MAIN_ELEMENT = nil
	return
end

Gamerules:showMain()
