-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local bubble_pos_x = { }
local bubble_pos_y = { }
local bubble_pos_z = { }
local bubble_vel_z = { }
local bubble_alpha = { }
local bubble_rad = { }

local function is_animated()
	return (get_world_state().game_paused==0 and is_game_frozen()==1 and get_world_state().replay_mode==1) or (get_world_state().game_paused==0 and is_game_frozen()==0 and get_world_state().replay_mode==0 ) or (get_world_state().replay_mode==2 and get_world_state().game_paused==0) 
end

local function atmo_underwater()

	if(get_option("shaders")==0) then
		set_color(0.50, 0.50, 0.40,1)
		draw_box(0, 0, 0.025, 1000, 1000, 0.08, 0, 0, 0)
		set_color(1, 1, 2,1)
		draw_sphere(0, 0, 0, -500)
		set_color(0.5,0.5,2,0.1)
		for i=1,30 do
		 draw_sphere(0, 0, 0, 5 + math.random(-100,100)/1000 + 5*i)
		end
	else
		-- blue "fog"
		camera_info = get_camera_info()
		set_color(1.00, 1.00, -2.00,-0.1)
		for i=0,5 do
			draw_sphere(math.random(-100,100)/1000 + camera_info.pos.x,math.random(-100,100)/1000 + camera_info.pos.y,math.random(-100,100)/1000 + camera_info.pos.z,-i)
		end
	end

	for i=1,100 do
		set_color(1.00, 1.00, 1.00,bubble_alpha[i])
		draw_sphere(bubble_pos_x[i],bubble_pos_y[i],bubble_pos_z[i],bubble_rad[i])
		if(is_animated()) then
			bubble_pos_z[i] = bubble_pos_z[i] + bubble_vel_z[i]
			bubble_alpha[i] = bubble_alpha[i] - 0.005
			if(bubble_alpha[i]<0) then
				if(i<41) then
					local body_info = get_body_info(0, 0)
					bubble_pos_x[i] = body_info.pos.x + math.random(-500,500)/2000
					bubble_pos_y[i] = body_info.pos.y + math.random(-500,500)/2000
					bubble_pos_z[i] = body_info.pos.z + math.random(0,500)/1000
					bubble_vel_z[i] = math.random(10,100)/5000
					bubble_rad[i] = math.random(200,500)/4000
					bubble_alpha[i] = math.random(500,1000)/1000
				elseif(i<81) then
					local body_info = get_body_info(1, 0)
					bubble_pos_x[i] = body_info.pos.x + math.random(-500,500)/2000
					bubble_pos_y[i] = body_info.pos.y + math.random(-500,500)/2000
					bubble_pos_z[i] = body_info.pos.z + math.random(0,500)/1000
					bubble_vel_z[i] = math.random(10,100)/5000
					bubble_rad[i] = math.random(200,500)/4000
					bubble_alpha[i] = math.random(500,1000)/1000
				else
					bubble_pos_x[i] = math.random(-2100,2100)/100
					bubble_pos_y[i] = math.random(-2100,2100)/100
					bubble_rad[i] = math.random(200,500)/4000
					bubble_pos_z[i] = bubble_rad[i]/2 +  math.random(0,2000)/2000
					bubble_vel_z[i] = math.random(100,1000)/8000
					bubble_alpha[i] = math.random(200,500)/1000
				end
			end
		end
	end

end

local body_info = get_body_info(0, 0)
for i=1,40 do
	bubble_pos_x[i] = body_info.pos.x + math.random(-500,500)/2000
	bubble_pos_y[i] = body_info.pos.y + math.random(-500,500)/2000
	bubble_pos_z[i] = body_info.pos.z + math.random(0,500)/1000
	bubble_vel_z[i] = math.random(10,100)/5000
	bubble_rad[i] = math.random(200,500)/4000
	bubble_alpha[i] = math.random(500,1000)/1000
end
body_info = get_body_info(1, 0)
for i=41,80 do
	bubble_pos_x[i] = body_info.pos.x + math.random(-500,500)/2000
	bubble_pos_y[i] = body_info.pos.y + math.random(-500,500)/2000
	bubble_pos_z[i] = body_info.pos.z + math.random(0,500)/1000
	bubble_vel_z[i] = math.random(10,100)/5000
	bubble_rad[i] = math.random(200,500)/4000
	bubble_alpha[i] = math.random(500,1000)/1000
end
for i=81,100 do
	bubble_pos_x[i] = math.random(-2100,2100)/100
	bubble_pos_y[i] = math.random(-2100,2100)/100
	bubble_rad[i] = math.random(200,500)/4000
	bubble_pos_z[i] = bubble_rad[i]/2 +  math.random(0,2000)/2000
	bubble_vel_z[i] = math.random(100,1000)/8000
	bubble_alpha[i] = math.random(200,500)/1000
end

add_hook("draw3d", "atmo", atmo_underwater)


