-- Modern UI flames screen
-- DO NOT MODIFY THIS FILE

require("toriui/uielement3d")
require("system/iofiles")
require("system/menu_manager")
dofile("system/flames_manager.lua")

if (FLAMES_MENU_MAIN_ELEMENT) then
	FLAMES_MENU_MAIN_ELEMENT:kill()
	FLAMES_MENU_MAIN_ELEMENT = nil
	return
end

Flames:showMain()
