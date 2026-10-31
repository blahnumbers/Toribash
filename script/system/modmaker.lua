-- Modern UI mod maker screen
-- author: Snowman
require("toriui.uielement3d")
require("system.iofiles")
require("system.menu_manager")
require("system.modmaker_manager")

if (ModMaker.MainElement) then
	ModMaker.Quit()
	return
end

-- Swaps into a sandboxed copy of the mod so editing is safe; can refuse
-- if multiplayer/replay is active (ModMaker.showMain() handles that case).
enter_mod_maker_mode()
ModMaker.showMain()
