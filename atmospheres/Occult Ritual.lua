-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local pulse = 0

local graphics_level = Settings and Settings.GetLevel() or 1
local nb_flames = (graphics_level + 1) * 100

local flames_pos_x = { }
local flames_pos_y = { }
local flames_pos_z = { }
local flames_speed = { }
local flames_amp_y = { }
local flames_amp_x = { }
local flames_rad   = { }
local flames_alpha   = { }

--initialize the flames
for i=0,nb_flames do
	flames_pos_x[i] = math.random(-600,600)/100
	flames_pos_y[i] = math.random(-600,600)/100
	flames_rad[i]   = math.random(10,20)/200
	flames_pos_z[i] = flames_rad[i]/2
	flames_speed[i] = math.random(10,50)/500
	flames_amp_y[i] = math.random(1,10)/500
	flames_amp_x[i] = math.random(1,10)/500	
	flames_alpha[i] = math.random(1,100)/100
end

local function atmo_occult_ritual()
	local z_pentagram = 0
	if(get_option("shaders")==0) then
		set_color(0.00,0.00,0.00,1)
		draw_box(0, 0, 0.025, 1000, 1000, 0.08, 0, 0, 0)
		draw_sphere(0, 0, 0, -500)
		
		local sun_u = 0.08
		local sun_v = 0.25
		local sun_rad = 40
		local sun_power = 10
		
		set_color(2, 2, 2,0.5)
		draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), sun_rad)
		set_color(-1, -1, -1,1)
		draw_sphere(-40+math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),-30 + math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)),-10 + math.ceil(500*math.sin(sun_u*math.pi)), sun_rad-8)
		
		for i=sun_rad,math.abs(sun_rad+sun_power),10 do
			set_color(2, 2, 2,0.03)
			draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), i)
		end
		z_pentagram = 0.03
	else
		local sun_u = 0.059
		local sun_v = 0.255
		local sun_rad = 70
		set_color(0.1, 0.1, 0.1,1)
		draw_sphere(-40+math.ceil(1000*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),-30 + math.ceil(1000*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)),-10 + math.ceil(1000*math.sin(sun_u*math.pi)), sun_rad-8)
		z_pentagram = 0.045
	end
	
	set_color(2.0+(10*math.cos(pulse/100))/10,0.2+(10*math.cos(pulse/100))/20,0,1)
	local d_size = 1000
	for cpt=0,89 do
		draw_box(1 - math.cos(cpt*4*3.14/180)*(0.5 - d_size/100), -0.1 - math.sin(cpt*4*3.14/180)*(d_size/100 - 0.5), z_pentagram, 1, 1, 0.09, 0, 0, 4*cpt)
	end
	draw_box(5,0,z_pentagram,1,17,0.09,0,0,0)
	draw_box(-1,1,z_pentagram,1,18.4,0.09,0,0,40)
	draw_box(-1,-1,z_pentagram,1,18.2,0.09,0,0,-40)
	draw_box(2,3,z_pentagram,1,18,0.09,0,0,-70)
	draw_box(2,-3,z_pentagram,1,18,0.09,0,0,70)
	
	for i=0,nb_flames do
		set_color(1.00, flames_alpha[i]/2, 0.00,flames_alpha[i])
		draw_sphere(flames_pos_x[i], flames_pos_y[i], flames_pos_z[i], flames_rad[i])
	end
end

local function atmo_occult_ritual_enterframe(_, speed)
	for i = 0, nb_flames do
		flames_pos_z[i] = flames_pos_z[i] + flames_speed[i] * speed
		flames_pos_y[i] = flames_pos_y[i] + flames_amp_y[i] * math.cos(flames_pos_z[i]) * speed
		flames_pos_x[i] = flames_pos_x[i] + flames_amp_x[i] * math.cos(flames_pos_x[i]) * speed
		flames_alpha[i] = flames_alpha[i] - 0.01 * speed
		if(flames_alpha[i] < 0) then
			flames_pos_x[i] = math.random(-600,600)/100
			flames_pos_y[i] = math.random(-600,600)/100
			flames_pos_z[i] = flames_rad[i]/2
			flames_alpha[i] = math.random(1,100)/100
		end
	end
	pulse = pulse + 1
end

return {
	onRender = atmo_occult_ritual,
	onEnterFrame = atmo_occult_ritual_enterframe
}