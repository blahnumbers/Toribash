-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local smoke_pos_x = { }
local smoke_pos_y = { }
local smoke_pos_z = { }
local smoke_vel_z = { }
local smoke_rad = { }

local angle = 45

local function is_animated()
	return (get_world_state().game_paused==0 and is_game_frozen()==1 and get_world_state().replay_mode==1) or (get_world_state().game_paused==0 and is_game_frozen()==0 and get_world_state().replay_mode==0 ) or (get_world_state().replay_mode==2 and get_world_state().game_paused==0) 
end

local function atmo_cartoon()

	if(get_option("shaders")==0) then
		set_color(0.10, 0.60, 0.10,1)
		draw_box(0, 0, 0.025, 1000, 1000, 0.08, 0, 0, 0)
		set_color(0.00, 0.30, 2.00,0.6)
		draw_sphere(0, 0, 0, -500)
		
		set_color(1.30, 1.25, 0.40,0.9)
		local sun_u = 0.90
		local sun_v = 1.05
		local sun_rad = 35
		draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), sun_rad)
	end

	set_color(0.5,0.28,0,1)
	
	
	draw_capsule( -23, 25, 4.0, 7.75, 1.2, 0, -3, 0)
	draw_capsule( -21, 24.75, 7, 2.75, 0.5, -28, -64, 8)
	draw_capsule( -24.5, 25.25, 7.25, 1.75, 0.5, -4, 56, 4)
	draw_capsule( -23, 24, 7.25, 1.5, 0.5, -36, 4, -8)
	
	draw_capsule( -5, -32, 3.5, 6.75, 1, 0, 4, 0)
	draw_capsule( -3, -32.25, 6, 2.75, 0.5, -28, -64, 8)
	draw_capsule( -6.75, -31.75, 7.25, 1.75, 0.5, -4, 56, 4)
	draw_capsule( -5, -30.5, 6.75, 1.5, 0.5, 60, 4, -8)
	
	draw_capsule( -35, 23, 4.0, 7.75, 1.25, 0, -4, 0)
	draw_capsule( -36.5, 21.75, 6.25, 4.25, 0.75, 124, -220, 0)
	
	
	draw_capsule( 16, 16, 4.5, 8.75, 1, 0, 0, 0)
	draw_capsule( 14.5, 16, 7.25, 2.5, 0.75, 0, 64, 0)
	draw_capsule( 18, 15.25, 8, 3.25, 0.5, -212, 64, 0)
				
	set_color(0.00,0.5,0.08,1)
	
	draw_sphere(-23.25,23.75,9.75,2.7)
	draw_sphere(-26,25.5,9.25,3)
	draw_sphere(-19.5,26,9,2.9)
	draw_sphere(-22.5,25.25,12.2,3.25)
	draw_sphere(-25.75,25.75,11.5,2.75)

	draw_sphere(-4.75,-29.75,9.5,2.7)
	draw_sphere(-8,-31.5,9.5,3)
	draw_sphere(-1.5,-31,8.25,2.5)
	draw_sphere(-4.5,-31.25,10.8,3.25)
	draw_sphere(-6.25,-31.75,11.75,2.75)

	draw_sphere(-38, 20, 7.5,2.5)
	draw_sphere(-38, 22.5, 10.25,3)
	draw_sphere(-34.75, 21.25, 10.25,3)
	draw_sphere(-34.75, 25.5, 9.25,3.75)
	draw_sphere(-34.75, 24.5, 11.75,3.75)
	draw_sphere(-37, 20.75, 11.25,2.5)

	draw_sphere( 19.75, 15.25, 9.25,2.25)
	draw_sphere( 12.25, 16.5, 9.25,2.75)
	draw_sphere( 15, 16.75, 11,3)
	draw_sphere( 17, 16.75, 11,3)
	draw_sphere( 19.5, 16.5, 11.25,2.25)
	draw_sphere( 16.25, 16.5, 12.25,2.25)
	
	set_color(1.00,1.0,0.88,1)
	draw_box(39.75,-4.75,3,12,13.5,6,0,0,-28)
	draw_box(40.00,-10.75,8,1.5,1.5,5,0,0,-28)
		
	set_color(1.00,0.2,0.2,1)
	for i=0,20 do
		draw_box(39.75,-4.75,6.125+i/4,14-i/3,15.5-i/1.5,0.25,0,0,-28)
	end
	
	set_color(0.56,0.29,0.01,1)
	draw_box(32.80,-4.75,2,0.25,2.00,4,0,0,-28)
		
	set_color(0.8,0.8,0.0,1)
	draw_capsule(32.80, -4.25, 2, 1.0,0.1,90,90,-28)

	set_color(0.5,0.5,0.60,1.0)
	draw_box(36.20,-10.75,3,0.25,2.00,2,0,0,-28)

	set_color(0.80,0.80,0.55,1)
	draw_box(-60.00,-15.00,11,10,10,22,0,0,0)
	set_color(0.70,0.2,0.2,1)
	for i=0,20 do
		draw_box(-60.00,-15.00,22.125+i/4,12-i/2,12-i/2,0.25,0,0,0)
	end

	set_color(0.56,0.29,0.01,1)
	draw_box(-55.00,-12.00,2,0.25,2.00,4,0,0,0)
	
	set_color(0.8,0.8,0.8,1)
	draw_capsule(-55.00, -15.00, 20, 4.0,0.5,0,90,0)
	
	set_color(0.90,0.70,0.50,1)
	draw_box(-53.50,-15.00,20,0.25,2.50,27,angle,0,0)
	draw_box(-53.50,-15.00,20,0.25,27,2.50,angle,0,0)
	
	if(is_animated()) then
		angle = angle + 0.5
	end
	
	for i=0,50 do
		set_color(1.00, 1.00, 1.00,1)
		draw_sphere(smoke_pos_x[i],smoke_pos_y[i],smoke_pos_z[i],smoke_rad[i])
		if(is_animated()) then
			smoke_pos_z[i] = smoke_pos_z[i] + smoke_vel_z[i]
			smoke_rad[i] = smoke_rad[i] - 0.005
			if(smoke_rad[i]<0) then
				smoke_pos_x[i] = math.random(3950,4050)/100
				smoke_pos_y[i] = math.random(-1100,-1050)/100
				smoke_pos_z[i] = 11
				smoke_vel_z[i] = math.random(10,100)/1000
				smoke_rad[i] = math.random(80,150)/300
			end
		end
	end
	
	set_color(0.56,0.29,0.01,1)
	for i=0,10 do
		draw_capsule(5 + 3*i, -30.00, 0.77, 1.5,0.2,0,0,0)
	end
	draw_box(20,-30.00,1,31,0.25,0.5,0,0,0)
	
end

for i=0,50 do
	smoke_pos_x[i] = math.random(3950,4050)/100
	smoke_pos_y[i] = math.random(-1100,-1050)/100
	smoke_pos_z[i] = 11
	smoke_vel_z[i] = math.random(10,100)/1000
	smoke_rad[i] = math.random(80,150)/300
end

add_hook("draw3d", "atmo", atmo_cartoon)