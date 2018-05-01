-- sports! 2018

local enableEnv = 0
local envEnabled = true
local envReduced = false
local animeEnabled = true
sportsMods = { "sports_aikido.tbm" , 
               "sports_abd.tbm" , 
			   "sports_boxshu.tbm" , 
			   "sports_erthtk.tbm" , 
			   "sports_greykido.tbm" , 
			   "sports_judo.tbm" , 
			   "sports_judofrac.tbm" , 
			   "sports_lenshu.tbm" , 
			   "sports_mushu.tbm" , 
			   "sports_ninjutsu.tbm" , 
			   "sports_boxing.tbm" , 
			   "sports_twinswords.tbm" , -- actual sports mods
               "aikido.tbm" , 
			   "lenshu3ng.tbm" } -- testing shit

local function checkMod() -- checks the currently loaded mod
	local connecction = false
	local modName = get_game_rules().mod
	for i, v in pairs(sportsMods) do 
		if v == modName then
			enableEnv = true
			connection = true
		elseif connection == false then
			enableEnv = false
		end
	end
end
local function loadEnv() -- loads a bunch of stuff
	local ox, oy, oz = 1.00, -0.10, 0.00
	if (enableEnv) and (envEnabled) then 
		local octpt = 4.41941738242
		local octs  = 5.27708078463
		set_color( 80/255, 130/255, 60/255, 1.00 )
		draw_box(        ox,        oy,     -0.25, -- draw the field
					 250.00,    250.00,      0.50,
					   0.00,      0.00,      0.00 )
        xp = {   0.00,   0.00,  34.12,    
	             0.00, -34.12, --major lines
		         8.56,   0.00,  -8.56,
			     8.56,   0.00,  -8.56, -- +/- inner lines 1
			    15.56,   0.00, -15.56,
			    15.56,   0.00, -15.56, -- +/- inner lines 2
			     0.00,  octpt,   6.25,   octpt,
			     0.00, -octpt,  -6.25,  -octpt } -- +/- inner circle -fin- 
	    yp = {   0.00,  52.62,   0.00, 
               -52.62,   0.00, --major lines
	            48.00,  43.62,  48.00, 
			   -48.00, -43.62, -48.00, -- +/- inner lines 1
			    42.50,  32.62,  42.50,
			   -42.50, -32.62, -42.50, -- +/- inner lines 2
			     6.25,  octpt,   0.00,  -octpt, 
			    -6.25, -octpt,   0.00,   octpt } -- +/- inner circle -fin- 
	    xs = {  68.00,  68.48,   0.24,   
	            68.48,   0.24, --major lines
	             0.24,  17.00,   0.24,
			     0.24,  17.00,   0.24, -- +/- inner lines 1
			     0.24,  31.00,   0.24,
			     0.24,  31.00,   0.24, -- +/- inner lines 2
			     octs,   octs,   octs,    octs,
			     octs,   octs,   octs,    octs } -- +/- inner circle -fin-
	    ys = {   0.24,   0.24, 105.00,    
	             0.24, 105.00, --major lines
	             9.00,   0.24,   9.00,
			     9.00,   0.24,   9.00, -- +/- inner lines 1
			    20.00,   0.24,  20.00,
			    20.00,   0.24,  20.00, -- +/- inner lines 2
			     0.24,   0.24,   0.24,    0.24,
			     0.24,   0.24,   0.24,    0.24 } -- +/- inner circle -fin-
	    zr = {   0, 0, 0, 
	             0, 0, 
			     0, 0, 0, 
			     0, 0, 0, 
			     0, 0, 0,
			     0, 0, 0,
			     0,  45,  90, 135,
			   180, 225, 270, 315 } --fin- (sets up the lines on the field)
		for i = 1, 25 do  -- the thing that actually does that gigantic chunk of absolute horseshit
			set_color( 230/255, 230/255, 230/255, 1.00 )
			draw_box( xp[i] + ox, yp[i] + oy,    -0.25, -- draw the lines on the field
						   xs[i],      ys[i],    0.505,
							   0,          0,    zr[i] )
		end 
		if (envReduced) then
		else
			set_color( R, G, B, A ) -- [BIG]
			draw_box( pX, pY, pZ,
				      sX, sY, sZ, 
				      rX, rY, rZ ) 
			if (isAnimated) and (animeEnabled) then
				if get_world_state().match_frame == 0 then -- resets animations on newgame & for the replay
					local aR , aG, aB, aA = 0.00 , 0.00 , 0.00 , 0.00 
					local apX, apY, apZ = 1.00 , -0.10 , 0.00
					local asX, asY, asZ = 0.00 , 0.00 , 0.00
					local arX, arY, arZ = 0 , 0 , 0
				end
				set_color( R, G, B, A ) -- animated shit
				draw_box( apX, apY, apZ,
		            	  asX, asY, asZ, 
						  arX, arY, arZ )
			end
		end
	end
end

add_hook( "draw3d" , "loadEnv" , loadEnv )
add_hook( "match_begin" , "checkMod" , checkMod )
add_hook( "new_mp_game" , "checkMod" , function() 
	if (world_state.game_paused == 0) and ((is_game_frozen() == world_state.replay_mode) or (world_state.replay_mode == 2)) then
		 isAnimated = true
	else isAnimated = false
	end
	checkMod()
end )
add_hook( "enter_freeze" , "" , function() -- pauses animation on freeze
isAnimated = false end )
add_hook( "exit_freeze" , "" , function()  -- restarts animation on playback
isAnimated = true end ) 
add_hook( "console" , "" , function(i, s) -- captures commands
	if s == 16 then
		x, j, command = string.find( i, "<%^%d+[%[%(]*%w*[%]%)]*%w+%^%d*>%s*%?(%a+%s*%a*)" )
		if command == "toggle env" then 
			echo( i )		
			if (envEnabled) then 
				envEnabled = false
				echo( "^14Environments : ^08Environment disabled" )
			else envEnabled = true
				echo( "^14Environments : ^08Environment enabled" )			
			end
			return 1
		end
		if command == "toggle animated" then
			echo( i )		
			if (animeEnabled) then
				animeEnabled = false
				echo( "^14Environments : ^08Animations disabled" )
			else animeEnabled = true
				echo( "^14Environments : ^08Animations enabled" )			
			end
			return 1	
		end 
		if command == "toggle reduced" then
			echo ( i )
			if (envReduced) then 
				envReduced = false
				echo( "^14Environments : ^08Displaying full environment" )				
			else envReduced = true
				echo( "^14Environments : ^08Displaying reduced environment" )	
			end
			return 1
		end
		if command == "help" then 
			echo ( i )
			echo( "^14Environments :" )
			echo( "^14?help - ^08displays available commands" )
			echo( "^14?toggle env - ^08enables/disables the environment" )
			echo( "^14?toggle reduced - ^08reduces/restores the number of objects loaded" )
			echo( "^14?toggle animated - ^08enables/disables animations (auto toggled by reduced command)" )
			return 1
		end
	end
end )

echo( "^14Environments : ^07Sports mods enabled!" ) -- echo on startup
echo( "^14Environments : ^07Type ?help to get a list of commands" )