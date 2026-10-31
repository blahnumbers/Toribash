---Better Ghost by bleed
---Draws a ghost showing where each fighter will be when the current turn ends
---Original post: https://forum.toribash.com/showthread.php?t=672946
---
---@author bleed (original)
---@author surge (modifications)
---@author AssassinPro, niavic, barbarbar, LostMail (additional credits)

-- Shown while the betterghost option is on (Q in a match); ghoststyle picks whether it replaces the classic ghost
-- Clients without the option only have the classic ghost
if get_option("betterghost") == nil then
	return
end

dofile("system/betterghost/betterghost.lua")
