-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local graphics_level = Settings and Settings.GetLevel() or 1
local nb_leaves = (graphics_level + 1) * 20
local nb_leaves_floor = (graphics_level + 1) * 30

local leaves_pos_x = { }
local leaves_pos_y = { }
local leaves_pos_z = { }
local leaves_speedx = { }
local leaves_speedy = { }
local leaves_speedz = { }
local leaves_sizex = { }
local leaves_sizey = { }
local leaves_rot_x = { }
local leaves_rot_y = { }
local leaves_rot_z = { }
local leaves_drot_x = { }
local leaves_drot_y = { }
local leaves_drot_z = { }

local floor_leaves_pos_x = { }
local floor_leaves_pos_y = { }
local floor_leaves_sizex = { }
local floor_leaves_sizey = { }
local floor_leaves_rot = { }

local function atmo_japan_night()

	if(get_option("shaders")==0) then
		set_color(0.10, 0.50, 0.10,1)
		draw_box(0, 0, 0.025, 1000, 1000, 0.08, 0, 0, 0)
		set_color(1.00, 0.00, 0.00,0.3)
		draw_sphere(0, 0, 0, -500)
		
		local sun_u = 0.05
		local sun_v = 1.19
		local sun_rad = 50
 		local sun_power = 50

		set_color(1.00, 0.10, 0.00,0.5)
		draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), sun_rad)
		for i=sun_rad,math.abs(sun_rad+sun_power),10 do
			set_color(1, 1, 1,0.03)
			draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), i)
		end
	end

	set_color(0.5,0.28,0,1)
	draw_capsule( -9.5, 34.25, 3.5, 7, 0.75, 0, 0, 0)
	draw_capsule( -8, 34.25, 5.75, 3.5, 0.5, 0, -52, 0)
	draw_capsule( -9.75, 33, 6.25, 2.25, 0.25, -52, 16, -12)
	
	draw_capsule( 5, 28, 3.5, 6.75, 1, 0, 4, 0)
	draw_capsule( 7, 27.75, 6, 2.75, 0.5, -28, -64, 8)
	draw_capsule( 3.5, 28.25, 7.25, 1.75, 0.5, -4, 56, 4)
	draw_capsule( 5, 27, 7.25, 1.5, 0.5, -36, 4, -8)
	
	draw_capsule( -23, 25, 4.0, 7.75, 1.2, 0, -3, 0)
	draw_capsule( -21, 24.75, 7, 2.75, 0.5, -28, -64, 8)
	draw_capsule( -24.5, 25.25, 7.25, 1.75, 0.5, -4, 56, 4)
	draw_capsule( -23, 24, 7.25, 1.5, 0.5, -36, 4, -8)
	
	draw_capsule( 9.5, -36.25, 3.5, 7, 0.75, 0, 0, 0)
	draw_capsule( 8.5, -36.75, 6.25, 1.5, 0.25, 148, -52, 0)
	draw_capsule( 10.75, -35.75, 5.25, 1.5, 0.25, 48, -52, 0)

	draw_capsule( -36.25, 9.5, 3.5, 7, 0.75, 0, 0, 0)
	draw_capsule( -37.5, 9, 6.25, 1.5, 0.25, 148, -52, 0)
	draw_capsule( -35.5, 9.75, 5.25, 1.5, 0.25, 48, -52, 0)
	
	draw_capsule( -5, -32, 3.5, 6.75, 1, 0, 4, 0)
	draw_capsule( -3, -32.25, 6, 2.75, 0.5, -28, -64, 8)
	draw_capsule( -6.75, -31.75, 7.25, 1.75, 0.5, -4, 56, 4)
	draw_capsule( -5, -30.5, 6.75, 1.5, 0.5, 60, 4, -8)
	
	draw_capsule( 23, -35, 4.0, 7.75, 1.2, 0, -3, 0)	
	draw_capsule( 25, -35.25, 7, 2.75, 0.5, -28, -64, 8)
	draw_capsule( 21.5, -34.75, 7.25, 1.75, 0.5, -4, 56, 4)
	draw_capsule( 23, -33.5, 7.25, 1.5, 0.5, 66, 4, -8)
	
	draw_capsule( -32, -5, 3.5, 6.75, 1, 0, 4, 0)
	draw_capsule( -31.75, -3.25, 6, 2, 0.5, 52, -12, 0)
	draw_capsule( -31.75, -6.5, 6.75, 2, 0.5, -44, -12, 0)
	draw_capsule( -30.75, -6, 6.75, 2, 0.5, -32, -56, 0)
	
	draw_capsule( -35, 23, 4.0, 7.75, 1.25, 0, -4, 0)
	draw_capsule( -36.5, 21.75, 6.25, 4.25, 0.75, 124, -220, 0)
	
	draw_capsule( 34.25, -9.5, 3.5, 7, 0.75, 0, 0, 0)
	draw_capsule( 34.25, -8.25, 5.5, 2.75, 0.5, 40, 0, 0)
	draw_capsule( 33.75, -10.25, 6, 1.75, 0.75, 136, 152, 0)
	
	draw_capsule( 28, 5, 3.5, 6.75, 1, 0, 4, 0)
	draw_capsule( 26.25, 6, 6, 3, 0.5, 48, 52, 0)
	draw_capsule( 27.5, 3.75, 6, 2, 0.75, 128, 168, 0)

	draw_capsule( 16, 16, 4.5, 8.75, 1, 0, 0, 0)
	draw_capsule( 14.5, 16, 7.25, 2.5, 0.75, 0, 64, 0)
	draw_capsule( 18, 15.25, 8, 3.25, 0.5, -212, 64, 0)
	
	draw_capsule( 25, -23, 4.0, 7.75, 1.25, 0, -4, 0)
	draw_capsule( 24.5, -25, 6.25, 2.75, 0.75, -56, 16, 0)
		
	set_color(0.75,0.43,0.69,1)
	draw_capsule( -10, 32.5, 9, 1.75, 2.5, 96, 0, 0)
	draw_capsule( -6.5, 33.75, 9, 1.75, 2.5, 92, 84, 0)
	draw_capsule( -8.25, 34.75, 9.5, 1.25, 2.5, 92, 84, 0)
	
	draw_sphere(-8.5,33,10.75,3.25)
	draw_sphere(-8.5,34.75,9.75,3.25)
	draw_sphere(-10.25,34.75,10,3.25)
	
	draw_sphere(5.25,26.75,9.75,2.7)
	draw_sphere(2,28.5,9.25,3)
	draw_sphere(8.5,28,8,2.5)
	draw_sphere(5.5,28.25,10.7,3.25)
	draw_sphere(3.75,28.75,11.5,2.75)
	
	draw_sphere(-23.25,23.75,9.75,2.7)
	draw_sphere(-26,25.5,9.25,3)
	draw_sphere(-19.5,26,9,2.9)
	draw_sphere(-22.5,25.25,12.2,3.25)
	draw_sphere(-25.75,25.75,11.5,2.75)
	
	draw_sphere(7.25, -37, 7.25,1.75)
	draw_sphere(11.5, -35, 6.25,1.25)
	draw_sphere(9.75, -35, 7.5,2)
	draw_sphere(8.25, -35.5, 8.5,2.25)
	draw_sphere(10.75, -35.5, 8.5,2.25)
	draw_sphere(9.75, -36.75, 9.5,2.25)
	draw_sphere(9.75, -37.75, 8,2.25)

	draw_sphere(-37, 7.25, 7.25,1.75)
	draw_sphere(-35, 11.5, 6.25,1.25)
	draw_sphere(-35, 9.75, 7.5,2)
	draw_sphere(-35.5, 8.25, 8.5,2.25)
	draw_sphere(-35.5, 10.75, 8.5,2.25)
	draw_sphere(-36.75, 9.75, 9.5,2.25)
	draw_sphere(-37.75, 9.75, 8,2.25)	
	
	draw_sphere(-4.75,-29.75,9.5,2.7)
	draw_sphere(-8,-31.5,9.5,3)
	draw_sphere(-1.5,-31,8.25,2.5)
	draw_sphere(-4.5,-31.25,10.8,3.25)
	draw_sphere(-6.25,-31.75,11.75,2.75)
	
	draw_sphere(19.25,-34.25,9.75,2.7)
	draw_sphere(23,-34.5,10.75,3)
	draw_sphere(25.5,-34,9,2.9)
	draw_sphere(22,-34.75,11.2,3.25)
	draw_sphere(23.75,-32.25,9.5,2.75)
	
	draw_sphere(-31.5, -2.25, 7.25,1.75)
	draw_sphere(-29.75, -8, 9,2.5)
	draw_sphere(-30, -4.75, 9.5,3)
	draw_sphere(-33, -4.75, 9.5,3)
	draw_sphere(-33, -6.25, 9.5,3)
	draw_sphere(-32, -6.25, 10.75,3)
	draw_sphere(-32, -3.5, 9.75,3)
	draw_sphere(-32.25, -2, 10.25,2)
	
	draw_sphere(-38, 20, 7.5,2.5)
	draw_sphere(-38, 22.5, 10.25,3)
	draw_sphere(-34.75, 21.25, 10.25,3)
	draw_sphere(-34.75, 25.5, 9.25,3.75)
	draw_sphere(-34.75, 24.5, 11.75,3.75)
	draw_sphere(-37, 20.75, 11.25,2.5)

	draw_sphere(34.25, -6.75, 7,1.75)
	draw_sphere(33, -12.5, 7.5,2.25)
	draw_sphere(33.5, -9.25, 8.75,2.5)
	draw_sphere(34.75, -10.5, 9.25,2.5)
	draw_sphere(34.75, -7, 8.75,2.5)
	draw_sphere( 35.25, -7.5, 10,2.25)
	
	draw_sphere( 27.5, 1.75, 7.75,2)
	draw_sphere( 25.5, 7.75, 7.75,2.5)
	draw_sphere( 25.5, 4.25, 9,2.75)
	draw_sphere( 26, 6.25, 10.25,2.75)
	draw_sphere( 26.25, 2.75, 9.75,2.75)
	draw_sphere( 26.25, 4.5, 12.25,1.5)

	draw_sphere( 19.75, 15.25, 9.25,2.25)
	draw_sphere( 12.25, 16.5, 9.25,2.75)
	draw_sphere( 15, 16.75, 11,3)
	draw_sphere( 17, 16.75, 11,3)
	draw_sphere( 19.5, 16.5, 11.25,2.25)
	draw_sphere( 16.25, 16.5, 12.25,2.25)
	
	draw_sphere( 24.5, -26, 8.25,2.25)
	draw_sphere( 25, -23.75, 10.25,3)
	draw_sphere( 25, -21, 7.25,3)
	draw_sphere( 25, -21, 9.25,3)
	draw_sphere( 25, -21, 10.75,2.25)
	
	
	
	for i=0,nb_leaves do
		draw_box( leaves_pos_x[i], leaves_pos_y[i], leaves_pos_z[i], leaves_sizex[i], leaves_sizey[i], 0.001, leaves_rot_x[i], leaves_rot_y[i], leaves_rot_z[i]) 
	end
	
	for i=0,nb_leaves_floor do
		draw_box( floor_leaves_pos_x[i], floor_leaves_pos_y[i], 0.001, floor_leaves_sizex[i], floor_leaves_sizey[i], 0.001, 0, 0, floor_leaves_rot[i]) 
	end
end

local function atmo_japan_enterframe(_, speed)
	for i = 0, nb_leaves do
		leaves_pos_z[i] = leaves_pos_z[i] - leaves_speedz[i] * speed
		leaves_pos_x[i] = leaves_pos_x[i] + leaves_speedx[i] * speed
		leaves_pos_y[i] = leaves_pos_y[i] + leaves_speedy[i] * speed
		
		leaves_rot_x[i] = leaves_rot_x[i] + leaves_drot_x[i] * speed
		leaves_rot_y[i] = leaves_rot_y[i] + leaves_drot_y[i] * speed
		leaves_rot_z[i] = leaves_rot_z[i] + leaves_drot_z[i] * speed
		
		if(leaves_pos_z[i] < 0) then
			leaves_pos_z[i] = 11
		end
		if(leaves_pos_x[i] > 25) then
			leaves_pos_x[i] = -25
		end
		if(leaves_pos_y[i] > 25) then
			leaves_pos_y[i] = -25
		end
	end
end

--initialize the leaves
for i=0,nb_leaves do
	leaves_pos_x[i] = math.random(-2100,2100)/100
	leaves_pos_y[i] = math.random(-2100,2100)/100
	leaves_pos_z[i] = math.random(0,1100)/100
	leaves_sizex[i] = math.random(5,10)/100
	leaves_sizey[i] = math.random(5,10)/50
	leaves_speedz[i] = math.random(30,70)/3000
	leaves_speedx[i] = math.random(40,90)/1000
	leaves_speedy[i] = math.random(40,90)/1000
	
	leaves_rot_x[i] = math.random(0,180)
	leaves_rot_y[i] = math.random(0,180)
	leaves_rot_z[i] = math.random(0,180)
	leaves_drot_x[i] = math.random(0,10)
	leaves_drot_y[i] = math.random(0,20)
	leaves_drot_z[i] = math.random(0,20)
end

for i=0,nb_leaves_floor do
	floor_leaves_pos_x[i] = math.random(-2100,2100)/100
	floor_leaves_pos_y[i] = math.random(-2100,2100)/100
	floor_leaves_sizex[i] = math.random(5,10)/100
	floor_leaves_sizey[i] = math.random(5,10)/50
	floor_leaves_rot[i] = math.random(0,180)
end

return {
	onRender = atmo_japan_night,
	onEnterFrame = atmo_japan_enterframe
}