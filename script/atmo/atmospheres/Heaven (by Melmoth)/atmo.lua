-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local heaven_cloud_pos_x = { }
local heaven_cloud_pos_y = { }
local heaven_cloud_pos_z = { }
local heaven_cloud_rad = { }
local heaven_cloud_delta = { }
local heaven_cloud_alpha = { }

local shine = 200
local delta_shine = 1.5

local function is_animated()
	return (get_world_state().game_paused==0 and is_game_frozen()==1 and get_world_state().replay_mode==1) or (get_world_state().game_paused==0 and is_game_frozen()==0 and get_world_state().replay_mode==0 ) or (get_world_state().replay_mode==2 and get_world_state().game_paused==0) 
end

local function atmo_heaven()

	if(get_option("shaders")==0) then
		set_color(0.90, 0.90, 2.00,0.3)
		draw_sphere(0, 0, 0, -800)
		
		set_color(2.00, 1.70, 0.00,0.5)
		local sun_u = 0.01
		local sun_v = 1.00
		local sun_rad = 30
		local sun_power = 20
		
		draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), sun_rad)
		for i=sun_rad,math.abs(sun_rad+sun_power),10 do
			set_color(2, 2, 2,0.03)
			draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), i)
		end
	end
	
	set_color(1.80, 1.80, 1.80,1)
	draw_box(0, 0, 0.025, 1000, 1000, 0.08, 0, 0, 0)
	
	set_color(shine/100, shine/200, 0.00,1)
	draw_box(-300, -30, 40, 10, 10, 80, 0, 0, 22.5)
	draw_box(-300, 30, 40, 10, 10, 80, 0, 0, 22.5)
	draw_box(-300, 0, 1, 14, 60, 2, 0, 0, 0)
	for i=0,39 do
		draw_box(-300, 0, 81+i/2, 14, 80-2*i, 0.5, 0, 0, 0)
	end
	set_color(1, 1, 1,shine/300)
	draw_box(-300, 0, 40, 1, 60, 80, 0, 0, 0)
	
	if(is_animated()) then
		shine = shine + delta_shine
		if(shine > 250) then
			delta_shine = -1.5
			shine = 250
		end
		if(shine < 200) then
			delta_shine = 1.5
			shine = 200
		end
		for i=0,200 do
			heaven_cloud_rad[i] = heaven_cloud_rad[i] + heaven_cloud_delta[i]
			heaven_cloud_alpha[i] = heaven_cloud_alpha[i] + heaven_cloud_delta[i]
			if(heaven_cloud_alpha[i] < 0.5 or heaven_cloud_alpha[i] > 0.8) then
				heaven_cloud_delta[i] = -1*heaven_cloud_delta[i]
			end
		end
	end
	
	for i=0,200 do
		set_color(10.00, 10.00, 10.00,heaven_cloud_alpha[i])
		draw_sphere(heaven_cloud_pos_x[i],heaven_cloud_pos_y[i],0,heaven_cloud_rad[i])
	end
	
	

end

for i=0,200 do
	heaven_cloud_pos_x[i] = math.random(-5100,5100)/100
	heaven_cloud_pos_y[i] = math.random(-5100,5100)/100
	heaven_cloud_rad[i] = math.random(80,300)/100
	heaven_cloud_delta[i] = math.random(-20,20)/3000
	heaven_cloud_alpha[i] = math.random(50,80)/100
end
	
add_hook("draw3d", "atmo", atmo_heaven)