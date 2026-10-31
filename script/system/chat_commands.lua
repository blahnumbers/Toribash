---Chat command reference
---The usage lines the modern chat UI shows while typing a command (as of 5.78)
---
---@author surge

---One usage line, and who can use it
---@class DesktopChatCommandUsage
---@field cmd string|string[] The command, or its names
---@field info string
---@field requireOnline boolean?
---@field requireOperator boolean?
---@field requireFighter boolean?

---Taken from the mobile client's command list
---@type DesktopChatCommandUsage[]
return {
	{ cmd = "set", info = "/set %125- list all gamerules", },
	{ cmd = "set", info = "/set ^38gamerule ^47[value] %125- view or set new gamerule value", requireOperator = true, },
	{ cmd = "opt", info = "/opt ^38option ^47[value] %125- view or set new option value", },
	{ cmd = "spectate", info = "/spec %125- join spectators", requireOnline = true, },
	{ cmd = "enter", info = "/enter %125- enter fighting queue", requireOnline = true, },
	{ cmd = "emote", info = "/emote ^47message %125- display emote message", requireFighter = true, },
	{ cmd = "join", info = "/join ^47roomname %125- join a multiplayer room", },
	{ cmd = { "dl", "download" }, info = "/dl ^47username %125- download player's custom tori", },
	{ cmd = { "dl", "download" }, info = "/dl ^47modname.tbm %125- download a custom mod", },
	{ cmd = { "rt", "reset" }, info = "/reset %125- reset and restart current fight", requireOperator = true, },
	{ cmd = { "lm", "loadmod" }, info = "/loadmod ^47modname %125- load a game mod and restart fight", requireOperator = true, },
	{ cmd = { "lp", "loadplayer" }, info = "/loadplayer ^38id ^47username %125- load user's customs for specified player", },
	{ cmd = "bet", info = "/bet ^38amount ^47username %125- bet TC on player's victory in current fight", requireOnline = true, },
	{ cmd = "bets", info = "/bet %125- show all active bets", requireOnline = true, },
	{ cmd = "passwd", info = "/pass ^47password %125- enter a password protected room", requireOnline = true, },
	{ cmd = "decapprize", info = "/decappize ^47amount %125- add TC to current decap prize", requireOnline = true, },
	{ cmd = "dismemberprize", info = "/dismemberprize ^47amount %125- add TC to current dismember prize", requireOnline = true, },
	{ cmd = "motd", info = "/motd ^47message %125- set room welcome message", requireOnline = true, },
	{ cmd = "desc", info = "/desc ^47message %125- set room description for room list", requireOnline = true, },
	{ cmd = "vip add", info = "/vip add ^47username %125- add player to room's vip list", requireOnline = true, },
	{ cmd = "vip del", info = "/vip del ^47username %125- remove player from room's vip list", requireOnline = true, },
	{ cmd = "vip list", info = "/vip list %125- show vip list for current room", requireOnline = true, },
	{ cmd = "vip clear", info = "/vip clear %125- clear current room's vip list", requireOnline = true, },
	{ cmd = "clanvip add", info = "/clanvip add ^47clan %125- add clan to room's vip list", requireOnline = true, },
	{ cmd = "clanvip del", info = "/clanvip del ^47username %125- remove clan from room's vip list", requireOnline = true, },
	{ cmd = "clanvip list", info = "/clanvip list %125- show clan vip list for current room", requireOnline = true, },
	{ cmd = "clanvip clear", info = "/clanvip clear %125- clear current room's clan vip list", requireOnline = true, },
	{ cmd = "viponly", info = "/viponly ^47on|off %125- toggle whether current room's vip only status", requireOnline = true, },
	{ cmd = "duel start", info = "/duel start ^47amount %125- enable duel mode with a specified wager", requireOnline = true, requireOperator = true, },
	{ cmd = "duel stop", info = "/duel stop %125- disable duel mode", requireOnline = true, requireOperator = true, },
	{ cmd = "duel earnings", info = "/duel earnings %125- show your earnings in this dueling session", requireOnline = true, },
	{ cmd = "duel status", info = "/duel status %125- show your earnings in this dueling session", requireOnline = true, },
}
