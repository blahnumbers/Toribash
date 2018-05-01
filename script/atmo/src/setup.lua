-- (c) Melmoth - 2011
echo("^07Installing Melmoth's Atmospheres LUA scripts...")
local file_profile = io.open("profile.tbs", "a", 1)
if(file_profile ~= nil) then
	file_profile:write("\nls atmo/src/atmospheres.lua\n")
	file_profile:close()
	echo("^07Installation finished !")
	echo("^07Restart Toribash, then launch Atmospheres with the '/atmo' command.")
else
	echo("^03ERROR : Setup couldn't write profile.tbs.")
	echo("^07Installation stopped.")
end			

