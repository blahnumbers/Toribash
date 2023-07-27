-- Modern UI shaders & atmosheres screen
-- DO NOT MODIFY THIS FILE

if (TBMenu == nil) then
	open_menu(19)
	close_menu()
end

require("toriui.uielement3d")
require("system.iofiles")
require("system.menu_manager")
require("system.atmospheres_manager")

if (Atmospheres.MainElement ~= nil) then
	Atmospheres.Quit()
	return
end
Atmospheres:showMain()
