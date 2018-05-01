-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local hell_lava_pos_x = { }
local hell_lava_pos_y = { }
local hell_lava_pos_z = { }
local hell_lava_vel_x = { }
local hell_lava_vel_y = { }
local hell_lava_vel_z = { }
local hell_lava_rad = { }
local hell_lava_alpha = { }
local gravity = 0.01

local hell_source_x = { }
local hell_source_y = { }

local function is_animated()
	return (get_world_state().game_paused==0 and is_game_frozen()==1 and get_world_state().replay_mode==1) or (get_world_state().game_paused==0 and is_game_frozen()==0 and get_world_state().replay_mode==0 ) or (get_world_state().replay_mode==2 and get_world_state().game_paused==0) 
end

local function atmo_hell()

	if(get_option("shaders")==0) then
		set_color(3.00, 0.90, 0.0,1)
		draw_box(0, 0, 0, 1000, 1000, 0.08, 0, 0, 0)
		set_color(1.5, 0.4, 0.0,1)
		draw_sphere(0, 0, 0, -500)
	end
	
	set_color(1.00, 0.00, 0.00,1)
	for i=0,9 do
		draw_sphere(hell_source_x[i],hell_source_y[i],0,0.2)
	end
		
	for i=0,300 do
		set_color(1.00, hell_lava_alpha[i]/2, 0.00,hell_lava_alpha[i])
		draw_sphere(hell_lava_pos_x[i],hell_lava_pos_y[i],hell_lava_pos_z[i],hell_lava_rad[i])
		if(is_animated()) then
			hell_lava_pos_x[i] = hell_lava_pos_x[i] + hell_lava_vel_x[i]
			hell_lava_pos_y[i] = hell_lava_pos_y[i] + hell_lava_vel_y[i]
			hell_lava_pos_z[i] = hell_lava_pos_z[i] + hell_lava_vel_z[i]
			hell_lava_vel_z[i] = hell_lava_vel_z[i] - gravity/2
			hell_lava_alpha[i] = hell_lava_alpha[i] - 0.01
			if(hell_lava_alpha[i]<0) then
				hell_lava_pos_x[i] = math.random(-15,15)/50 + hell_source_x[math.mod(i,10)]
				hell_lava_pos_y[i] = math.random(-15,15)/50 + hell_source_y[math.mod(i,10)]
				hell_lava_pos_z[i] = math.random(0,30)/50
				hell_lava_vel_x[i] = math.random(-50,50)/1000
				hell_lava_vel_y[i] = math.random(-50,50)/1000
				hell_lava_vel_z[i] = math.random(10,300)/1000
				hell_lava_rad[i] = math.random(80,150)/1000
				hell_lava_alpha[i] = math.random(1,100)/100
			end
		end
	end
end

for i=0,9 do
	hell_source_x[i] = math.random(-2100,2100)/100
	hell_source_y[i] = math.random(-2100,2100)/100
end

for i=0,300 do
	hell_lava_pos_x[i] = hell_source_x[math.mod(i,10)]
	hell_lava_pos_y[i] = hell_source_y[math.mod(i,10)]
	hell_lava_pos_z[i] = math.random(0,30)/50
	hell_lava_vel_x[i] = math.random(-50,50)/1000
	hell_lava_vel_y[i] = math.random(-50,50)/1000
	hell_lava_vel_z[i] = math.random(10,100)/1000
	hell_lava_rad[i] = math.random(80,150)/1000
	hell_lava_alpha[i] = math.random(1,100)/100
end
	
add_hook("draw3d", "atmo", atmo_hell)