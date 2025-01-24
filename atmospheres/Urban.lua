-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local graphics_level = Settings and Settings.GetLevel() or 1
local nb_rain = (graphics_level + 1) * 50

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

local function atmo_urban_night()
	camera_info = get_camera_info()
	if(get_option("shaders")==0) then
		set_color(0.60,0.60,0.60,1)
		draw_box(0, 0, 0.01, 1000, 1000, 0.01, 0, 0, 0)
		set_color(0.2, 0.2, 0.2,1)
		draw_sphere(0, 0, 0, -1000)
		
		local sun_u = 0.11
		local sun_v = 0.52
		local sun_rad = 40
		local sun_power = 10
		
		set_color(1.00, 1.00, 1.00,0.5)
		draw_sphere(math.ceil(1000*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(1000*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(1000*math.sin(sun_u*math.pi)), sun_rad)
		for i=sun_rad,math.abs(sun_rad+sun_power),10 do
			set_color(1, 1, 1,0.03)
			draw_sphere(math.ceil(1000*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(1000*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(1000*math.sin(sun_u*math.pi)), i)
		end
	else
		set_color(-0.80, -0.80, -0.80,-0.3)
		draw_sphere(math.random(-100,100)/5000 + camera_info.pos.x,math.random(-100,100)/5000 + camera_info.pos.y,math.random(-100,100)/5000 + camera_info.pos.z,-3)
	end


	set_color(0.8,0.8,0.0,1)
	draw_box(0,0,0.03,0.4,1000,0.01,0,0,0)

	set_color(0.5,0.5,0.5,1)
	draw_box(30,0,0.25,20,1000,0.5,0,0,0)
	draw_box(-30,0,0.25,20,1000,0.5,0,0,0)
	draw_box(60,0,3,1,1000,6,0,0,0)
	draw_box(-60,0,3,1,1000,6,0,0,0)	

	for i = -2,4 do
		set_color(0.30,0.30,0.30,1)
		draw_capsule(22,60*i,0.5,2,0.4,0,0,0)
		draw_capsule(22,60*i,5,10,0.2,0,0,0)
		draw_box(22,60*i,10,0.5,0.5,0.7,0,0,0)
		draw_sphere(22,60*i,0.5,1)
		draw_capsule(-22,60*i,0.5,2,0.4,0,0,0)
		draw_capsule(-22,60*i,5,10,0.2,0,0,0)
		draw_box(-22,60*i,10,0.5,0.5,0.7,0,0,0)
		draw_sphere(-22,60*i,0.5,1)
		set_color(2.00,2.00,1.00,0.8-math.random(0,100)/1000)
		draw_sphere(22,60*i,11.1,1.4)
		draw_sphere(-22,60*i,11.1,1.4)
		set_color(1.30,1.30,1.30,1)
		draw_box(10,60*i,0.03,0.4,40,0.01,0,0,0)
		draw_box(-10,60*i,0.03,0.4,40,0.01,0,0,0)
	end
	
	set_color(0.45,0.4,0.4,1)
	draw_box(-50,40,15,20,40,30,0,0,0)
	set_color(0.7,0.6,0.6,1)
	draw_box(-50,40,26,22,42,4,0,0,0)
	draw_box(-39.5,40,9.5,1,10,2.5,0,0,0)
	set_color(0.7,0.7,0.5,1)
	draw_box(-39.9,40,5.5,0.2,9.80,10,0,0,0)
	set_color(0.8,0.8,0.9,1)
	draw_box(-39.9,40,17.5,0.2,8,5,0,0,0)
	draw_box(-39.9,27,17.5,0.2,8,5,0,0,0)
	draw_box(-39.9,53,17.5,0.2,8,5,0,0,0)
	set_color(1.0,1.0,0.9,1)
	draw_capsule(-39.9,39,4,0.5,0.2,0,90,0)
	draw_capsule(-39.9,41,4,0.5,0.2,0,90,0)
	
	set_color(0.5,0.45,0.45,1)
	draw_box(-45,-5,20,15,40,40,0,0,0)
	set_color(0.95,0.95,0.95,1)
	draw_capsule(-37.2,14,20,40,0.2,0,0,0)
	set_color(0.8,0.8,0.9,1)
	draw_box(-36.9,-5,19.5,0.2,8,4,0,0,0)
	draw_box(-36.9,8,19.5,0.2,8,4,0,0,0)
	draw_box(-36.9,-18,19.5,0.2,8,4,0,0,0)
	draw_box(-36.9,-5,32.5,0.2,8,4,0,0,0)
	draw_box(-36.9,8,32.5,0.2,8,4,0,0,0)
	draw_box(-36.9,-18,32.5,0.2,8,4,0,0,0)
	
	set_color(0.45,0.35,0.35,1)
	draw_box(-50,-55,20,20,40,40,0,0,0)
	set_color(0.8,0.8,0.9,1)
	draw_box(-39.9,-40,14.5,0.2,5,3,0,0,0)
	draw_box(-39.9,-50,14.5,0.2,5,3,0,0,0)
	draw_box(-39.9,-60,14.5,0.2,5,3,0,0,0)
	draw_box(-39.9,-70,14.5,0.2,5,3,0,0,0)
	
	draw_box(-39.9,-40,24.5,0.2,5,3,0,0,0)
	draw_box(-39.9,-50,24.5,0.2,5,3,0,0,0)
	draw_box(-39.9,-60,24.5,0.2,5,3,0,0,0)
	draw_box(-39.9,-70,24.5,0.2,5,3,0,0,0)
	
	draw_box(-39.9,-40,34.5,0.2,5,3,0,0,0)
	draw_box(-39.9,-50,34.5,0.2,5,3,0,0,0)
	draw_box(-39.9,-60,34.5,0.2,5,3,0,0,0)
	draw_box(-39.9,-70,34.5,0.2,5,3,0,0,0)
	
	draw_box(-39.9,-90,30.5,0.2,7,6,0,0,0)
	draw_box(-39.9,-110,30.5,0.2,7,6,0,0,0)
	draw_box(-39.9,-130,30.5,0.2,7,6,0,0,0)
	draw_box(-39.9,-150,30.5,0.2,7,6,0,0,0)
	draw_box(-39.9,-170,30.5,0.2,7,6,0,0,0)
	
	draw_box(-39.9,90,30.5,0.2,10,6,0,0,0)
	draw_box(-39.9,120,30.5,0.2,10,6,0,0,0)
	draw_box(-39.9,150,30.5,0.2,10,6,0,0,0)
	draw_box(-39.9,180,30.5,0.2,10,6,0,0,0)
	draw_box(-39.9,210,30.5,0.2,10,6,0,0,0)
	
	draw_box(39.9,120,30.5,0.2,10,6,0,0,0)
	draw_box(39.9,160,30.5,0.2,10,6,0,0,0)
	
	draw_box(39.9,20,30.5,0.2,10,6,0,0,0)
	draw_box(39.9,40,30.5,0.2,10,6,0,0,0)
	draw_box(39.9,60,30.5,0.2,10,6,0,0,0)
	
	draw_box(39.9,20,15.5,0.2,10,6,0,0,0)
	draw_box(39.9,40,15.5,0.2,10,6,0,0,0)
	draw_box(39.9,60,15.5,0.2,10,6,0,0,0)
	
	draw_box(39.9,-8,23,0.2,15,6,0,0,0)
	draw_box(39.9,-33,23,0.2,15,6,0,0,0)
	draw_box(39.9,-58,23,0.2,15,6,0,0,0)
	draw_box(39.9,-83,23,0.2,15,6,0,0,0)
	
	draw_box(39.9,-110,38,0.2,8,6,0,0,0)
	draw_box(39.9,-130,38,0.2,8,6,0,0,0)
	draw_box(39.9,-150,38,0.2,8,6,0,0,0)
	draw_box(39.9,-110,18,0.2,8,6,0,0,0)
	draw_box(39.9,-130,18,0.2,8,6,0,0,0)
	draw_box(39.9,-150,18,0.2,8,6,0,0,0)
	
	set_color(0.32,0.32,0.3,1)
	draw_box(-50,160,20,20,170,40,0,0,0)
	
	set_color(0.21,0.20,0.2,1)
	draw_box(-60,300,30,40,100,60,0,0,0)
	
	set_color(0.11,0.10,0.1,1)
	draw_box(-40,410,36,40,100,70,0,0,0)
	
	set_color(0,0,0,1)
	draw_box(-150,400,70,40,30,140,0,0,0)
	draw_box(-170,360,80,40,30,160,0,0,0)
	draw_box(-200,240,80,40,60,160,0,0,0)
	draw_box(200,300,80,40,60,160,0,0,0)
	
	set_color(0.32,0.32,0.3,1)
	draw_box(-50,-130,20,20,100,40,0,0,0)
	
	set_color(0.26,0.25,0.25,1)
	draw_box(-40,-240,36,40,100,70,0,0,0)
	
	set_color(0.15,0.15,0.15,1)
	draw_box(-170,-350,70,40,30,140,0,0,0)
	
	set_color(0.42,0.4,0.4,1)
	draw_box(50,40,20,20,60,40,0,0,0)
	
	set_color(0.32,0.3,0.3,1)
	draw_box(50,140,25,20,70,50,0,0,0)
	
	set_color(0.22,0.2,0.2,1)
	draw_box(50,210,15,20,60,30,0,0,0)
	
	set_color(0.11,0.10,0.1,1)
	draw_box(60,300,30,40,100,60,0,0,0)
	draw_box(40,410,40,40,100,80,0,0,0)
	
	set_color(0,0,0,1)
	draw_box(0,480,65,60,60,130,0,0,0)
	draw_box(-80,550,80,50,50,160,0,0,0)
	
	set_color(0.32,0.32,0.3,1)
	draw_box(50,-45,15,20,100,30,0,0,0)
	
	set_color(0.22,0.22,0.2,1)
	draw_box(50,-130,25,20,60,50,0,0,0)
	
	set_color(0.16,0.15,0.15,1)
	draw_box(40,-220,46,40,100,90,0,0,0)
	
	set_color(0,0,0,1)
	draw_box(5,-280,66,40,40,130,0,0,0)
	draw_box(-45,-280,56,40,40,110,0,0,0)
	draw_box(200,-150,80,45,40,160,0,0,0)
	draw_box(260,-330,130,45,50,260,0,0,0)

	for i = 0, nb_rain do
		-- check if we got too far from the droplet
		if (Vector2) then
			local dist = Vector2.New(camera_info.pos.x - rain_pos_x[i], camera_info.pos.y - rain_pos_y[i]):magnitude()
			if (dist > rain_area_radius) then
				rain_pos_x[i] = camera_info.pos.x + math.random(0, rain_area_radius) * math.cos(math.random(0, 2 * math.pi))
				rain_pos_y[i] = camera_info.pos.y + math.random(0, rain_area_radius) * math.sin(math.random(0, 2 * math.pi))
			end
			set_color(1, 1, 1, dist / rain_area_radius * 0.8)
		end
		draw_box(rain_pos_x[i], rain_pos_y[i], rain_pos_z[i], rain_rad[i], rain_rad[i],rain_size[i],0,0,rain_pos_z[i]/100)
	end
end

local function atmo_urban_night_enterframe(_, speed)
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
	onRender = atmo_urban_night,
	onEnterFrame = atmo_urban_night_enterframe
}