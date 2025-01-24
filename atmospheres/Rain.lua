-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local graphics_level = Settings and Settings.GetLevel() or 1
local nb_rain = (graphics_level + 1) * 150

local rain_area_radius = 25
local rain_pos_x = { }
local rain_pos_y = { }
local rain_pos_z = { }
local rain_speed = { }
local rain_rad   = { }
local rain_size  = { }

--initialize the rain
local camera_info = get_camera_info()
for i = 0, nb_rain do
	rain_pos_x[i] = camera_info.pos.x + math.random(0, rain_area_radius) * math.cos(math.random(0, 2 * math.pi))
	rain_pos_y[i] = camera_info.pos.y + math.random(0, rain_area_radius) * math.sin(math.random(0, 2 * math.pi))
	rain_pos_z[i] = camera_info.pos.z+math.random(0,1100)/100
	rain_rad[i]   = math.random(10,20)/1000
	rain_size[i]  = math.random(20,40)/100
	rain_speed[i] = math.random(10,50)/50
end

local function atmo_loch_ness()
	camera_info = get_camera_info()
	
	for i = 0, nb_rain do
		-- check if we got too far from the droplet
		if (Vector2) then
			local dist = Vector2.New(camera_info.pos.x - rain_pos_x[i], camera_info.pos.y - rain_pos_y[i]):magnitude()
			if (dist > rain_area_radius) then
				rain_pos_x[i] = camera_info.pos.x + math.random(0, rain_area_radius) * math.cos(math.random(0, 2 * math.pi))
				rain_pos_y[i] = camera_info.pos.y + math.random(0, rain_area_radius) * math.sin(math.random(0, 2 * math.pi))
			end
			set_color(0.5, 0.5, 0.55, dist / rain_area_radius * 0.8)
		end
		draw_box(rain_pos_x[i], rain_pos_y[i], rain_pos_z[i], rain_rad[i], rain_rad[i],rain_size[i],0,0,rain_pos_z[i]/100)
	end
	if(get_option("shaders")==0) then
		set_color(0.03,0.30,0.00,1)
		draw_box(0, 0, 0.01, 1000, 1000, 0.01, 0, 0, 0)
		set_color(0.6, 0.6, 0.6,1)
		draw_sphere(0, 0, 0, -500)
	end
end

local function atmo_loch_ness_enterframe(_, speed)
	camera_info = get_camera_info()
	for i = 0, nb_rain do
		rain_pos_z[i] = rain_pos_z[i] - rain_speed[i] * speed
		if(rain_pos_z[i] < 0) then
			draw_sphere(rain_pos_x[i],rain_pos_y[i],0,rain_rad[i]*2)
			rain_pos_x[i] = camera_info.pos.x + math.random(0, rain_area_radius) * math.cos(math.random(0, 2 * math.pi))
			rain_pos_y[i] = camera_info.pos.y + math.random(0, rain_area_radius) * math.sin(math.random(0, 2 * math.pi))
			rain_pos_z[i] = camera_info.pos.z + 11
		end
	end
end

return {
	onRender = atmo_loch_ness,
	onEnterFrame = atmo_loch_ness_enterframe
}