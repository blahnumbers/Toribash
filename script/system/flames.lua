-- Modern UI flames screen
-- DO NOT MODIFY THIS FILE

if (TBMenu == nil) then
	open_menu(19)
	close_menu()
end

require("toriui/uielement3d")
require("system/menu_manager")
require("system/player_info")
require("system/iofiles")
dofile("system/menu_backend_defines.lua")
dofile("system/flames_manager.lua")

if (FLAMES_MENU_MAIN_ELEMENT) then
	if (get_shift_key_state() == 0) then
		Flames:quit()
	else
		Flames:minimize()
	end
	return
end

if (not FLAMES_MENU_MINIMIZED) then
	Flames:storeCurrentFlames()
end
Flames:showMain()
