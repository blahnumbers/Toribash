-- Modern UI gamerules screen
-- DO NOT MODIFY THIS FILE

require("toriui.uielement3d")
require("system.iofiles")
require("system.menu_manager")
require("system.gamerules_manager")

if (Gamerules.MainElement) then
	Gamerules.Quit()
	return
end

Gamerules.showMain()
