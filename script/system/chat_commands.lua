---Chat command reference
---The usage lines the mobile chat suggests and the modern desktop chat shows while typing a command (as of 5.78)
---
---@author surge

---@class HudChatCommand
---@field cmd string|string[] Base command string
---@field info string Example command displayed in UI
---@field regex string Regex expression to match input against
---@field replacement string String to replace with
---@field autoSubmit boolean? Whether this command can be auto submitted upon selection from suggestions
---@field submitCmdMatch boolean? Whether this command should stop being suggested after it gets input arguments
---@field typeCommandRegex string? Custom regex used for matching chat input
---@field requireOperator boolean? Whether this command requires op in multiplayer
---@field requireOnline boolean? Whether this is a multiplayer only command
---@field requireFighter boolean? Whether this command is only available to active fighters

---@type HudChatCommand[]
return {
	{
		cmd = "set",
		info = "/set %125- list all gamerules",
		regex = "^(/%w+).*",
		replacement = "/set",
		submitCmdMatch = true,
		autoSubmit = true
	},
	{
		cmd = "set",
		info = "/set ^38gamerule ^47[value] %125- view or set new gamerule value",
		regex = "^(/%w+) ?(%w*) ?(%w*).*",
		replacement = "/set %2 %3",
		requireOperator = true
	},
	{
		cmd = { "opt", "option" },
		info = "/opt ^38option ^47[value] %125- view or set new option value",
		regex = "^(/%w+) ?(%w*) ?(%w*).*",
		replacement = "/opt %2 %3"
	},
	{
		cmd = { "spec", "spectate" },
		info = "/spec %125- join spectators",
		regex = "^(/%w+).*",
		replacement = "/sp",
		submitCmdMatch = true,
		autoSubmit = true,
		requireOnline = true
	},
	{
		cmd = "enter",
		info = "/enter %125- enter fighting queue",
		regex = "^(/%w+).*",
		replacement = "/en",
		submitCmdMatch = true,
		autoSubmit = true,
		requireOnline = true
	},
	{
		cmd = "emote",
		info = "/emote ^47message %125- display emote message",
		regex = "^(/%w+) ?(.*)",
		replacement = "/emote %2",
		requireFighter = true
	},
	{
		cmd = "join",
		info = "/join ^47roomname %125- join a multiplayer room",
		regex = "^(/%w+) ?(.*)",
		replacement = "/join %2",
	},
	{
		cmd = { "dl", "download" },
		info = "/dl ^47username %125- download player's custom tori",
		regex = "^(/%w+) ?([^%. ]*).*",
		replacement = "/dl %2",
	},
	{
		cmd = { "dl", "download" },
		info = "/dl ^47modname.tbm %125- download a custom mod",
		regex = "^(/%w+) ?([^%. ]*).*",
		replacement = "/dl %2.tbm",
	},
	{
		cmd = { "rt", "reset" },
		info = "/reset %125- reset and restart current fight",
		regex = "^(/%w+).*",
		replacement = "/rt",
		submitCmdMatch = true,
		autoSubmit = true,
		requireOperator = true
	},
	{
		cmd = { "lm", "loadmod" },
		info = "/loadmod ^47modname %125- load a game mod and restart fight",
		regex = "^(/%w+) ?([^%. ]*).*",
		replacement = "/lm %2",
		requireOperator = true
	},
	{
		cmd = { "lp", "loadplayer" },
		info = "/loadplayer ^38id ^47username %125- load user's customs for specified player",
		regex = "^(/%w+) ?(%d*) ?(%w*).*",
		replacement = "/lp %2 %3"
	},
	{
		cmd = "bet",
		info = "/bet ^38amount ^47username %125- bet TC on player's victory in current fight",
		regex = "^(/%w+) ?(%d*) ?(%w*).*",
		replacement = "/bet %2 %3",
		requireOnline = true
	},
	{
		cmd = "bets",
		info = "/bets %125- show all active bets",
		regex = "^(/%w+).*",
		replacement = "/bets",
		requireOnline = true,
		submitCmdMatch = true,
		autoSubmit = true
	},
	{
		cmd = { "pass", "pa" },
		info = "/pass ^47password %125- enter a password protected room",
		regex = "^(/%w+) ?(.*)",
		replacement = "/pass %2",
		requireOnline = true
	},
	{
		cmd = "decapprize",
		info = "/decapprize ^47amount %125- add TC to current decap prize",
		regex = "^(/%w+) ?(%d*).*",
		replacement = "/decapprize %2",
		requireOnline = true
	},
	{
		cmd = "dismemberprize",
		info = "/dismemberprize ^47amount %125- add TC to current dismember prize",
		regex = "^(/%w+) ?(%d*).*",
		replacement = "/dismemberprize %2",
		requireOnline = true
	},
	{
		cmd = "motd",
		info = "/motd ^47message %125- set room welcome message",
		regex = "^(/%w+) ?(.*)",
		replacement = "/motd %2",
		requireOnline = true,
		requireOperator = true
	},
	{
		cmd = "desc",
		info = "/desc ^47message %125- set room description for room list",
		regex = "^(/%w+) ?(.*)",
		replacement = "/desc %2",
		requireOnline = true,
		requireOperator = true
	},
	{
		cmd = "vip add",
		info = "/vip add ^47username %125- add player to room's vip list",
		regex = "^(/%w+) ?[ad]* ?(.*)",
		typeCommandRegex = "^/(%w+ ?%w*).*",
		replacement = "/vip add %2",
		requireOnline = true,
		requireOperator = true
	},
	{
		cmd = "vip del",
		info = "/vip del ^47username %125- remove player from room's vip list",
		regex = "^(/%w+) ?[del]* ?(.*)",
		typeCommandRegex = "^/(%w+ ?%w*).*",
		replacement = "/vip del %2",
		requireOnline = true,
		requireOperator = true
	},
	{
		cmd = "vip list",
		info = "/vip list %125- show vip list for current room",
		regex = "^(/%w+).*",
		typeCommandRegex = "^/(%w+ ?%w*).*",
		replacement = "/vip list",
		requireOnline = true,
		requireOperator = true,
		autoSubmit = true
	},
	{
		cmd = "vip clear",
		info = "/vip clear %125- clear current room's vip list",
		regex = "^(/%w+).*",
		typeCommandRegex = "^/(%w+ ?%w*).*",
		replacement = "/vip clear",
		requireOnline = true,
		requireOperator = true
	},
	{
		cmd = "clanvip add",
		info = "/clanvip add ^47clan %125- add clan to room's vip list",
		regex = "^(/%w+) ?[ad]* ?(.*)",
		typeCommandRegex = "^/(%w+ ?%w*).*",
		replacement = "/clanvip add %2",
		requireOnline = true,
		requireOperator = true
	},
	{
		cmd = "clanvip del",
		info = "/clanvip del ^47clan %125- remove clan from room's vip list",
		regex = "^(/%w+) ?[del]* ?(.*)",
		typeCommandRegex = "^/(%w+ ?%w*).*",
		replacement = "/clanvip del %2",
		requireOnline = true,
		requireOperator = true
	},
	{
		cmd = "clanvip list",
		info = "/clanvip list %125- show clan vip list for current room",
		regex = "^(/%w+).*",
		typeCommandRegex = "^/(%w+ ?%w*).*",
		replacement = "/clanvip list",
		requireOnline = true,
		requireOperator = true,
		autoSubmit = true
	},
	{
		cmd = "clanvip clear",
		info = "/clanvip clear %125- clear current room's clan vip list",
		regex = "^(/%w+).*",
		typeCommandRegex = "^/(%w+ ?%w*).*",
		replacement = "/clanvip clear",
		requireOnline = true,
		requireOperator = true
	},
	{
		cmd = "viponly",
		info = "/viponly ^47on|off %125- toggle whether current room's vip only status",
		regex = "^(/%w+) ?(.*)",
		replacement = "/viponly %2",
		requireOnline = true,
		requireOperator = true
	},
	{
		cmd = "duel start",
		info = "/duel start ^47amount %125- enable duel mode with a specified wager",
		regex = "^(/%w+) ?[star]* ?(%d*).*",
		typeCommandRegex = "^/(%w+ ?%w*).*",
		replacement = "/duel start %2",
		requireOnline = true,
		requireOperator = true
	},
	{
		cmd = "duel stop",
		info = "/duel stop %125- disable duel mode",
		regex = "^(/%w+).*",
		typeCommandRegex = "^/(%w+ ?%w*).*",
		replacement = "/duel stop",
		requireOnline = true,
		requireOperator = true
	},
	{
		cmd = "duel earnings",
		info = "/duel earnings %125- show your earnings in this dueling session",
		regex = "^(/%w+).*",
		typeCommandRegex = "^/(%w+ ?%w*).*",
		replacement = "/duel earnings",
		requireOnline = true,
		autoSubmit = true
	},
	{
		cmd = "duel status",
		info = "/duel status %125- show your earnings in this dueling session",
		regex = "^(/%w+).*",
		typeCommandRegex = "^/(%w+ ?%w*).*",
		replacement = "/duel status",
		requireOnline = true,
		autoSubmit = true
	},
}
