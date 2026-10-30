---Better Ghost by bleed
---Draws a ghost showing where each fighter will be when the current turn ends
---Original post: https://forum.toribash.com/showthread.php?t=672946
---
---@author bleed (original)
---@author surge (modifications)
---@author AssassinPro, niavic, barbarbar, LostMail (additional credits)

-- Shown when the ghoststyle option is 1 (end of turn ghost only) or 2 (both ghosts)
-- Clients without the option only have the classic ghost
if get_option("ghoststyle") == nil then
	return
end

dofile("system/betterghost/betterghost.lua")
