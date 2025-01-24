-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/
-- Script made by Kyat

local flystar_anim = { }
local flystar_step = { }
local flystar_bigstep = { }
local flystar__pos_X = { }
local flystar__pos_Y = { }
local flystar__pos_Z = { }
local flystar_dir_X = { }
local flystar_dir_Y = { }
local flystar_dir_Z = { }
local flystar_radius = { }
local flystar_alpha = { }
local flystar_length = { }

local star_pos_x = { }
local star_pos_y = { }
local star_pos_z = { }
local star_rad   = { }

local star_cube_pos_x = { }
local star_cube_pos_y = { }
local star_cube_pos_z = { }
local star_cube_rot_x = { }
local star_cube_rot_y = { }
local star_cube_rot_z = { }
local star_cube_dir_x = { }
local star_cube_dir_y = { }
local star_cube_dir_z = { }

local starcaps_pos_x = { }
local starcaps_pos_y = { }
local starcaps_pos_z = { }
local starcaps_rad = { }
local starcaps_size = { }

--initialize the stars
--#spheres
for i=1,49 do
	--standing stars - shorter range
	star_pos_x[i] = math.random(-250,250)
	while star_pos_x[i] > -50 and star_pos_x[i] < 50 do	star_pos_x[i] = math.random(-250,250) end
	star_pos_y[i] = math.random(-250,250)
	while star_pos_y[i] > -50 and star_pos_y[i] < 50 do	star_pos_y[i] = math.random(-250,250) end

	star_pos_z[i] = math.random(0,120)
	star_rad[i]   = math.random(20,50)/100	
end
for i=50,75 do
	--blinking stars - middle range
	star_pos_x[i] = math.random(-500,500)
	while star_pos_x[i] > -120 and star_pos_x[i] < 120 do	star_pos_x[i] = math.random(-500,500) end
	star_pos_y[i] = math.random(-500,500)
	while star_pos_y[i] > -120 and star_pos_y[i] < 120 do	star_pos_y[i] = math.random(-500,500) end

	star_pos_z[i] = math.random(0,120)
	star_rad[i]   = math.random(20,50)/100	

	starcaps_pos_x[i] = star_pos_x[i]
	starcaps_pos_y[i] = star_pos_y[i]
	starcaps_pos_z[i] = star_pos_z[i]
	starcaps_rad[i] = star_rad[i]
	starcaps_size[i] = starcaps_rad[i]
end
for i=76,120 do
--above stars		
	star_pos_x[i] = math.random(-64,64)
	star_pos_y[i] = math.random(-64,64)
	
	if (star_pos_x[i] <= 10 or star_pos_x[i] >= -10) then
				--short range
				star_pos_z[i] = math.random(25,35)
				star_rad[i]   = math.random(5,7)/100
	else
				--Mid range
				star_pos_z[i] = math.random(35,60)
				star_rad[i]   = math.random(7,10)/100
	end
end
--#cubes
for i=1,78 do
	--rotating stars - long distance
	star_cube_pos_x[i] = math.random(-360,360)
	while star_cube_pos_x[i] > -128 and star_cube_pos_x[i] < 128 do	star_cube_pos_x[i] = math.random(-360,360) end
	star_cube_pos_y[i] = math.random(-360,360)
	while star_cube_pos_y[i] > -128 and star_cube_pos_y[i] < 128 do	star_cube_pos_y[i] = math.random(-360,360) end

	star_cube_pos_z[i] = math.random(0,250)
	star_cube_rot_x[i]   = math.random(-360,360)
	star_cube_rot_y[i]   = math.random(-360,360)
	star_cube_rot_z[i]   = math.random(-360,360)
	star_cube_dir_x[i]   = math.random(-360,360)
	star_cube_dir_y[i]   = math.random(-360,360)
	star_cube_dir_z[i]   = math.random(-360,360)
end

for i=1,11 do
	flystar_anim[i] = 0
	flystar_step[i] = 0
	flystar_bigstep[i] = math.random(0,75)
	flystar_radius[i] = math.random(10,145)/100
	flystar__pos_X[i] = math.random(-360,360)
	flystar__pos_Y[i] = math.random(-360,360)
	flystar__pos_Z[i] = math.random(10,120)
	flystar_length[i] = math.random(5,25)
	flystar_dir_X[i] = math.random(0.2,0.7)
	flystar_dir_Y[i] = math.random(0.2,0.7)
	flystar_dir_Z[i] = math.random(-0.3,0.3)
	flystar_alpha[i] = 0.9
end

local function atmo_outer_space()
	if(get_option("shaders")==0) then
		set_color(0.56, 2.00, 0.08,1)
		draw_box(0, 0, 0.025, 1000, 1000, 0.08, 0, 0, 0)
		set_color(0, 0, 0.05,1)
		draw_sphere(0, 0, 0, -500)
		
		local sun_u = 0.08
		local sun_v = 0.25
		local sun_rad = 40
		local sun_power = 10
		
		set_color(0.60, 0.60, 1.00,0.5)
		draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), sun_rad)
		for i=sun_rad,math.abs(sun_rad+sun_power),10 do
			set_color(1, 0, 0,0.03)
			draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), i)
		end
	end

	set_color(0.33,0.75,1,1)
	--big planet
		draw_sphere(-100.5, 100.25, 20, 8.75)
		set_color(0.33,0.75,1,0.69)
		draw_sphere(-100.5, 100.25, 20, 8.75+1)
		set_color(0.33,0.75,1,0.59)
		draw_sphere(-100.5, 100.25, 20, 8.75+2)
	--3D ring
		set_color(0.43,0.85,1,0.59)
		--set_color(1, 1, 1, 0.51)
		draw_disk_3d(-100.5, 100.25, 20, 12, 19, 32, 1, 0, 0, 0)
	
	--monolith
	set_color(0.08, 0.11, 0.11, 0.99)
	draw_box(40,35,9,2,8,18,0,0,22.5)
	
	-- Planets yellow+big
	set_color(0.55,0.42,0.0,1)
	draw_sphere(-110.75, -315, 65, 7.25)
	set_color(0.55,0.42,0.0,0.65)
	draw_sphere(-110.75, -315, 65, 8.55)
	set_color(0.55,0.42,0.0,0.55)
	draw_sphere(-115.75, -335, 68, 14.75)
	
	-- Planets green
	set_color(0.08, 0.11, 0.11,0.9)
	draw_sphere(-50.75, -435, 168, 55.75)
	set_color(0.08, 1.0,1.0,0.5)
	draw_sphere(-550.75, -119, 125, 3.75)
	set_color(0.08, 1.0,1.0,0.60)
	draw_sphere(-550.75, -122.5, 127, 6.75)
	set_color(0.08, 1.0,1.0,0.40)
	draw_sphere(-550.75, -120, 125, 8.75)
	
	-- Planet purple
	set_color(0.25, 0.0,0.31,1)
	draw_sphere(255.75, -220, 85 , 8.75)
	set_color(0.25, 0.0,0.31,0.75)
	draw_sphere(255.75, -220, 85 , 10.75)

	-- Planet bigwhite
	set_color(0.25,0.25,0.35,1)
	draw_sphere(799, -120, 50 , 15)
	set_color(1,1,1,0.55)
	draw_sphere(799, -120, 47 , 29)
	
	-- Planet bigwhite
	set_color(0.62,0.82,0.84,0.3)
	draw_sphere(0, 0, 250 , 100)
	set_color(0.4,0.97,0.6,1.0)
	draw_sphere(0, 0, 300, 85)
	
-- draw stars
	local a
	for i=1,49 do
	--Draws the standing stars - white/light blue/light red
		a = math.random(1,100)
		if (a>=1 and a<=33) then
			set_color(1.0,0.0,0.0,0.4)
		elseif (a>=34 and a<=66) then
			set_color(1.0,0.97,0.0,0.3)
		else
			set_color(0.8,0.8,0.8,0.3)
		end
		set_color(0.8,0.8,0.8,0.8)
		draw_sphere( star_pos_x[i], star_pos_y[i], star_pos_z[i], star_rad[i])
		set_color(1.0,1.0,1.0,0.3)
	end
	for i=50,75 do
	--Draws the blinking stars - white/yellow
		set_color(0.8,0.8,0.8,0.8)
		draw_sphere( star_pos_x[i], star_pos_y[i], star_pos_z[i], star_rad[i]) 	
		a = math.random(1,100)
		if (a>=1 and a<=33) then
			set_color(1.0,0.97,0.0,0.4)
		elseif (a>=34 and a<=66) then
			set_color(1.0,0.0,0.0,0.3)
		else
			set_color(1.0,1.0,1.0,0.3)
		end
		starcaps_rad[i] = starcaps_size[i]*math.random(200,400)/100
		draw_sphere( starcaps_pos_x[i], starcaps_pos_y[i], starcaps_pos_z[i], starcaps_rad[i])		
	end
	for i=76,120 do
	--Draws the above stars - white 
		set_color(1,1,1,0.8)
		draw_sphere( star_pos_x[i], star_pos_y[i], star_pos_z[i], star_rad[i]) 	
	end
	--#cubes
	for i=1,78 do
	--rotating stars - long distance
	set_color(1,1,1,0.8)
	star_cube_rot_x[i]=star_cube_rot_x[i]+star_cube_dir_x[i]
	star_cube_rot_y[i]=star_cube_rot_y[i]+star_cube_dir_y[i]
	star_cube_rot_z[i]=star_cube_rot_z[i]+star_cube_dir_z[i]
	draw_box( star_cube_pos_x[i], star_cube_pos_y[i], star_cube_pos_z[i], math.random(30,70)/100, math.random(30,70)/100, math.random(30,70)/100, star_cube_rot_x[i], star_cube_rot_y[i], star_cube_rot_z[i])
	end

	local x, y, z0, myRad
	for i=1,6 do
		if flystar_anim[i]==1 then
			set_color(1.0,1.0,1.0,flystar_alpha[i])
			draw_sphere(flystar__pos_X[i],flystar__pos_Y[i],flystar__pos_Z[i],flystar_radius[i])
			for j = 1,flystar_length[i] do
				x = flystar__pos_X[i]-flystar_dir_X[i]*j
				y = flystar__pos_Y[i]-flystar_dir_Y[i]*j
				z0 = flystar__pos_Z[i]-flystar_dir_Z[i]*j
				myRad = flystar_radius[i]-(flystar_radius[i]/flystar_length[i])*j
				draw_sphere(x,y,z0,myRad)
			end
		end
	end
end

local function atmo_outer_space_enterframe(_, speed)
	for i = 1, 11 do
		if flystar_anim[i] == 0 then
			if flystar_bigstep[i] <= 0 then
				--animation
				flystar_anim[i] = 1
				flystar_bigstep[i] = math.random(60,85)
			else
				flystar_bigstep[i] = flystar_bigstep[i] - 1 * speed
			end
		else
			--animation in progress
			flystar_step[i] = flystar_step[i] + 1 * speed
									
			flystar__pos_X[i] = flystar__pos_X[i] + flystar_dir_X[i] * speed
			flystar__pos_Y[i] = flystar__pos_Y[i] + flystar_dir_Y[i] * speed
			flystar__pos_Z[i] = flystar__pos_Z[i] + flystar_dir_Z[i] * speed
			
			if flystar_step[i] <= flystar_bigstep[i] then
				flystar_alpha[i] = flystar_alpha[i] - (flystar_alpha[i] / flystar_bigstep[i]) * flystar_step[i] * speed
			else
				flystar_anim[i] = 0
				flystar_step[i] = 0
				flystar_bigstep[i] = math.random(0,95)
				flystar__pos_X[i] = math.random(-360,360)
				flystar__pos_Y[i] = math.random(-360,360)
				flystar__pos_Z[i] = math.random(10,120)
				flystar_dir_X[i] = math.random(0.5,0.7)
				flystar_dir_Y[i] = math.random(0.5,0.7)
				flystar_dir_Z[i] = math.random(-30,30)/100
				flystar_radius[i] = math.random(10,145)/100
				flystar_length[i] = math.random(5,25)
				flystar_alpha[i] = 0.9
			end
		end
	end
end

return {
	onRender = atmo_outer_space,
	onEnterFrame = atmo_outer_space_enterframe
}