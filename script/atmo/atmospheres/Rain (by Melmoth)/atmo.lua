-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local nb_rain = 250 -- if TB crashes when you load this atmospheres, try to reduce this value

local rain_pos_x = { }
local rain_pos_y = { }
local rain_pos_z = { }
local rain_speed = { }
local rain_rad   = { }
local rain_size   = { }

local function is_animated()
	return (get_world_state().game_paused==0 and is_game_frozen()==1 and get_world_state().replay_mode==1) or (get_world_state().game_paused==0 and is_game_frozen()==0 and get_world_state().replay_mode==0 ) or (get_world_state().replay_mode==2 and get_world_state().game_paused==0) 
end

--initialize the rain
local camera_info_1 = get_camera_info()
for i=0,nb_rain do
	rain_pos_x[i] = camera_info_1.pos.x+math.random(-2000,2000)/100
	rain_pos_y[i] = camera_info_1.pos.y+math.random(-2000,2000)/100
	rain_pos_z[i] = camera_info_1.pos.z+math.random(0,1100)/100
	rain_rad[i]   = math.random(10,20)/1000
	rain_size[i]   = math.random(20,40)/100
	rain_speed[i] = math.random(10,50)/50

end

local function atmo_loch_ness()
	local camera_info_2 = get_camera_info()
	
	set_color(0.5,0.5,0.5,0.8)
	for i=0,nb_rain do
		draw_box( rain_pos_x[i], rain_pos_y[i], rain_pos_z[i], rain_rad[i], rain_rad[i],rain_size[i],0,0,rain_pos_z[i]/100) 
		if(is_animated()) then
			rain_pos_z[i] = rain_pos_z[i] - rain_speed[i]
			if(rain_pos_z[i] < 0) then
				draw_sphere(rain_pos_x[i],rain_pos_y[i],0,rain_rad[i]*2)
				rain_pos_x[i] = camera_info_2.pos.x+math.random(-2000,2000)/100
				rain_pos_y[i] = camera_info_2.pos.y+math.random(-2000,2000)/100
				rain_pos_z[i] = camera_info_2.pos.z+11
			end
		end
	end
	if(get_option("shaders")==0) then
		set_color(0.03,0.30,0.00,1)
		draw_box(0, 0, 0.01, 1000, 1000, 0.01, 0, 0, 0)
		set_color(0.6, 0.6, 0.6,1)
		draw_sphere(0, 0, 0, -500)
	else	
		set_color(-0.80, -0.80, -0.80,-0.4)
		draw_sphere(math.random(-100,100)/5000 + camera_info_2.pos.x,math.random(-100,100)/5000 + camera_info_2.pos.y,math.random(-100,100)/5000 + camera_info_2.pos.z,-3)
	end
end

add_hook("draw3d", "atmo", atmo_loch_ness)