-- Modern UI flames screen
-- DO NOT MODIFY THIS FILE

require("toriui/uielement3d")
require("system/menu_manager")
dofile("system/menu_backend_defines.lua")
dofile("system/flames_manager.lua")

if (FLAMES_MENU_MAIN_ELEMENT) then
	Flames:quit()
	return
end

Flames:storeCurrentFlames()
Flames:showMain()
