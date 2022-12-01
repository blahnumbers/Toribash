-- Modern UI mods screen
-- DO NOT MODIFY THIS FILE

if (TBMenu == nil) then
	open_menu(19)
	close_menu()
end

require("toriui.uielement3d")
require("system.iofiles")
require("system.menu_manager")
dofile("system/mods_manager.lua")

if (Mods.MainElement) then
	Mods.MainElement:kill()
	Mods.MainElement = nil
	return
end

Mods:showMain()
