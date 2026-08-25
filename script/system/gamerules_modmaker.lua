-- Modern UI gamerules screen, opened from Mod Maker
-- Thin wrapper around gamerules_manager.lua - do not duplicate its logic here

require("toriui.uielement3d")
require("system.iofiles")
require("system.menu_manager")
require("system.gamerules_manager")

-- Marks that this menu was opened from Mod Maker rather than the main menu,
-- so a future change can offer an "Export Mod" step instead of just applying
-- the rules to the current match.
Gamerules.ModMakerContext = true

if (Gamerules.MainElement) then
	Gamerules.Quit()
	return
end

Gamerules.showMain()
