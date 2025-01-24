-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local fireflies_center_x = { }
local fireflies_center_y = { }
local fireflies_center_z = { }
local fireflies_rad = { }
local fireflies_pos = { }
local fireflies_speed = { }
local fireflies_size = { }

local function atmo_darkforest()
	if(get_option("shaders")==0) then
		set_color(0.05, 0.25, 0.05,1)
		draw_box(0, 0, 0.025, 1000, 1000, 0.08, 0, 0, 0)
		set_color(0.05, 0.05, 0.05,1)
		draw_sphere(0, 0, 0, -500)
		
		local sun_u = 0.05
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

	
	for i=1,22 do
		set_color(0.15,0.12,0.00,1)
		draw_capsule(90*math.cos(math.pow(i,2)),60*math.sin(math.pow(i,3)),15+i%10/2,30+i%10,1+i%3,math.cos(i)*i%5,math.sin(i)*i%5,0)
		draw_capsule(90*math.cos(math.pow(i,3)),60*math.sin(math.pow(i,2)),15+i%10/2,30+i%10,1+i%3,math.sin(i)*i%5,math.cos(i)*i%5,0)
		set_color(0.15, 0.30, 0.15,1)
		draw_sphere(90*math.cos(math.pow(i,2)),60*math.sin(math.pow(i,3)),80+i%10,50+i%10/2)
		draw_sphere(90*math.cos(math.pow(i,3)),60*math.sin(math.pow(i,2)),80+i%10,50+i%10/2)
	end
	
	
	for i=1,50 do
		set_color(1.0,1.00,1.00,0.8)
		draw_sphere(fireflies_center_x[i]+fireflies_rad[i]*math.cos(fireflies_pos[i]), fireflies_center_y[i]+fireflies_rad[i]*math.sin(fireflies_pos[i]), fireflies_center_z[i]+math.cos(fireflies_pos[i]), fireflies_size[i])
		set_color(1.0,0.90,0.20,0.3)
		draw_sphere(fireflies_center_x[i]+fireflies_rad[i]*math.cos(fireflies_pos[i]), fireflies_center_y[i]+fireflies_rad[i]*math.sin(fireflies_pos[i]), fireflies_center_z[i]+math.cos(fireflies_pos[i]), fireflies_size[i]*math.random(200,300)/100)
	end
end

local function atmo_darkforest_animate(_, speed)
	for i = 1, 50 do
		fireflies_pos[i] = fireflies_pos[i] + fireflies_speed[i] * speed
	end
end

for i=1,10 do
	fireflies_center_x[i] = math.random(-210,210)/100
	fireflies_center_y[i] = math.random(-210,210)/100
	fireflies_center_z[i] = math.random(100,900)/100
	fireflies_rad[i] = math.random(200,300)/100
	fireflies_pos[i] = math.random(50,600)/100
	fireflies_speed[i] = math.random(10,20)/1000
	fireflies_size[i] = math.random(20,50)/1000
end
for i=11,20 do
	fireflies_center_x[i] = math.random(-210,210)/100
	fireflies_center_y[i] = math.random(-210,210)/100
	fireflies_center_z[i] = math.random(100,900)/100
	fireflies_rad[i] = math.random(200,300)/100
	fireflies_pos[i] = math.random(50,600)/100
	fireflies_speed[i] = math.random(-20,-10)/1000
	fireflies_size[i] = math.random(20,50)/1000
end
for i=21,30 do
	fireflies_center_x[i] = math.random(-2100,-1000)/100
	fireflies_center_y[i] = math.random(-2100,-1000)/100
	fireflies_center_z[i] = math.random(100,900)/100
	fireflies_rad[i] = math.random(1200,2000)/100
	fireflies_pos[i] = math.random(50,600)/100
	fireflies_speed[i] = math.random(10,20)/1000
	fireflies_size[i] = math.random(20,50)/1000
end
for i=31,40 do
	fireflies_center_x[i] = math.random(1000,2100)/100
	fireflies_center_y[i] = math.random(1000,2100)/100
	fireflies_center_z[i] = math.random(100,900)/100
	fireflies_rad[i] = math.random(1200,2000)/100
	fireflies_pos[i] = math.random(50,600)/100
	fireflies_speed[i] = math.random(10,20)/1000
	fireflies_size[i] = math.random(20,50)/1000
end
for i=41,50 do
	fireflies_center_x[i] = math.random(-2100,2100)/100
	fireflies_center_y[i] = math.random(-2100,2100)/100
	fireflies_center_z[i] = math.random(100,900)/100
	fireflies_rad[i] = math.random(200,1000)/100
	fireflies_pos[i] = math.random(50,600)/100
	fireflies_speed[i] = math.random(10,20)/1000
	fireflies_size[i] = math.random(20,50)/1000
end

return {
	onRender = atmo_darkforest,
	onEnterFrame = atmo_darkforest_animate
}