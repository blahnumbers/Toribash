-- Modern UI flames screen
-- DO NOT MODIFY THIS FILE

if (TBMenu == nil) then
	open_menu(19)
	close_menu()
end

dofile("system/menu_backend_defines.lua")
require("toriui.uielement3d")
require("system.menu_manager")
require("system.playerinfo_manager")
require("system.iofiles")
require("system.flames_manager")

if (Flames.MainElement) then
	if (get_shift_key_state() == 0) then
		Flames.Quit()
	else
		Flames.Minimize()
	end
	return
end

if (not Flames.IsMinimized) then
	Flames.GetCurrentFlames()
end
Flames:showMain()
