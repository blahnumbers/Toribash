-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local graphics_level = Settings and Settings.GetLevel() or 1
local nb_flakes = (graphics_level + 1) * 80

local snowfall_radius = 15
local flakes_pos_x = { }
local flakes_pos_y = { }
local flakes_pos_z = { }
local flakes_speed = { }
local flakes_amp_y = { }
local flakes_amp_x = { }
local flakes_rad   = { }

--initialize the flakes
local camera_info = get_camera_info()
for i=0,nb_flakes do
	flakes_pos_x[i] = camera_info.pos.x + math.random(0, snowfall_radius) * math.cos(math.random(0, 2 * math.pi))
	flakes_pos_y[i] = camera_info.pos.y + math.random(0, snowfall_radius) * math.sin(math.random(0, 2 * math.pi))
	flakes_pos_z[i] = camera_info.pos.z + math.random(0, 1100) / 100
	flakes_rad[i]   = math.random(10,20)/1000
	flakes_speed[i] = math.random(10,50)/1000
	flakes_amp_y[i] = math.random(1,10)/1000
	flakes_amp_x[i] = math.random(1,10)/1000
end

local function atmo_winter_night()
	if(get_option("shaders")==0) then
		set_color(2.00,2.00,2.00,1)
		draw_box(0, 0, 0.025, 1000, 1000, 0.08, 0, 0, 0)
		set_color(0, 0, 0.2,1)
 		draw_sphere(0, 0, 0, -500)

		local sun_u = 0.11
		local sun_v = 0.25
		local sun_rad = 40
		local sun_power = 10

		set_color(1.00, 1.00, 1.00,0.5)
		draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), sun_rad)
		for i=sun_rad,math.abs(sun_rad+sun_power),10 do
			set_color(1, 1, 1,0.03)
			draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), i)
		end
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

	camera_info = get_camera_info()
	for i = 0, nb_flakes do
		if (Vector2) then
			local dist = Vector2.New(camera_info.pos.x - flakes_pos_x[i], camera_info.pos.y - flakes_pos_y[i]):magnitude()
			if (dist > snowfall_radius) then
				flakes_pos_x[i] = camera_info.pos.x + math.random(0, snowfall_radius) * math.cos(math.random(0, 2 * math.pi))
				flakes_pos_y[i] = camera_info.pos.y + math.random(0, snowfall_radius) * math.sin(math.random(0, 2 * math.pi))
			end
		end
		draw_sphere(flakes_pos_x[i], flakes_pos_y[i], flakes_pos_z[i], flakes_rad[i])
	end
end

local function atmo_winter_enterframe(_, speed)
	camera_info = get_camera_info()
	for i = 0, nb_flakes do
		flakes_pos_z[i] = flakes_pos_z[i] - flakes_speed[i] * speed
		flakes_pos_y[i] = flakes_pos_y[i] + flakes_amp_y[i] * math.cos(flakes_pos_z[i]) * speed
		flakes_pos_x[i] = flakes_pos_x[i] + flakes_amp_x[i] * math.cos(flakes_pos_x[i]) * speed
		if (flakes_pos_z[i] < 0) then
			flakes_pos_x[i] = camera_info.pos.x + math.random(0, snowfall_radius) * math.cos(math.random(0, 2 * math.pi))
			flakes_pos_y[i] = camera_info.pos.y + math.random(0, snowfall_radius) * math.sin(math.random(0, 2 * math.pi))
			flakes_pos_z[i] = camera_info.pos.z + 11
		end
	end
end

return {
	onRender = atmo_winter_night,
	onEnterFrame = atmo_winter_enterframe
}