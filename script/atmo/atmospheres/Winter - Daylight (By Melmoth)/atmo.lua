-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local nb_flakes = 270 -- if TB crashes when you load this atmospheres, try to reduce this value

local flakes_pos_x = { }
local flakes_pos_y = { }
local flakes_pos_z = { }
local flakes_speed = { }
local flakes_amp_y = { }
local flakes_amp_x = { }
local flakes_rad   = { }

local function is_animated()
	return (get_world_state().game_paused==0 and is_game_frozen()==1 and get_world_state().replay_mode==1) or (get_world_state().game_paused==0 and is_game_frozen()==0 and get_world_state().replay_mode==0 ) or (get_world_state().replay_mode==2 and get_world_state().game_paused==0) 
end

--initialize the flakes
camera_info = get_camera_info()
for i=0,nb_flakes do
	flakes_pos_x[i] = camera_info.pos.x+math.random(-1100,1100)/100
	flakes_pos_y[i] = camera_info.pos.y+math.random(-1100,1100)/100
	flakes_pos_z[i] = camera_info.pos.z+math.random(0,1100)/100
	flakes_rad[i]   = math.random(10,20)/1000
	flakes_speed[i] = math.random(10,50)/1000
	flakes_amp_y[i] = math.random(1,10)/1000
	flakes_amp_x[i] = math.random(1,10)/1000	
end

local function atmo_winter_daylight()
	if(get_option("shaders")==0) then
		set_color(2.00,2.00,2.00,1)
		draw_box(0, 0, 0.025, 1000, 1000, 0.08, 0, 0, 0)
		set_color(1.8, 1.8, 2,1)
		draw_sphere(0, 0, 0, -500)
	end
	
	set_color(0.4,0.4,0.4,1)
	draw_sphere(-18.5, 20.25, 0, 1.75)
	draw_sphere(-17.75, 20.5, 0, 1.25)
	
	draw_sphere(38.5, 20.25, 0, 2.75)
	draw_sphere(37.75, 21, 0, 2.25)
	
	draw_sphere(38.5, -40.25, 0, 2.75)
	draw_sphere(37.75, -41, 0, 2.25)
	
	set_color(1,1,1,1)
	draw_sphere(-18.5, 20.25, 0.4, 1.5)
	draw_sphere(38.5, 20.25, 0.4, 2.5)
	draw_sphere(38.5, -40.25, 0.4, 2.5)
	
	for i=0,nb_flakes do
		draw_sphere( flakes_pos_x[i], flakes_pos_y[i], flakes_pos_z[i], flakes_rad[i]) 
		if(is_animated()) then
			flakes_pos_z[i] = flakes_pos_z[i] - flakes_speed[i]
			flakes_pos_y[i] = flakes_pos_y[i] + flakes_amp_y[i] * math.cos(flakes_pos_z[i])
			flakes_pos_x[i] = flakes_pos_x[i] + flakes_amp_x[i] * math.cos(flakes_pos_x[i])
			if(flakes_pos_z[i] < 0) then
				camera_info = get_camera_info()
				flakes_pos_x[i] = camera_info.pos.x+math.random(-1100,1100)/100
				flakes_pos_y[i] = camera_info.pos.y+math.random(-1100,1100)/100
				flakes_pos_z[i] = camera_info.pos.z+11
			end
		end
	end
end

add_hook("draw3d", "atmo", atmo_winter_daylight)

