-- Modern UI mods screen
-- DO NOT MODIFY THIS FILE

if (TBMenu == nil) then
	open_menu(19)
	close_menu()
end

require("toriui.uielement3d")
require("system.iofiles")
require("system.menu_manager")
require("system.mods_manager")

if (Mods.MainElement) then
	Mods.Quit()
	return
end

Mods:showMain()
