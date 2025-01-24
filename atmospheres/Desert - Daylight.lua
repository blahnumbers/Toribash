-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local function atmo_desert()
	
	if(get_option("shaders")==0) then
		set_color(1.00, 0.85, 0.35,1)
		draw_box(0, 0, 0.025, 1000, 1000, 0.08, 0, 0, 0)
		set_color(0.50, 0.50, 1.00,0.2)
		draw_sphere(0, 0, 0, -500)
		
		  
		set_color(1.00, 0.70, 0.00,0.5)
		local sun_u = 0.09
		local sun_v = 1.80
		local sun_rad = 30
		local sun_power = 20
		
		draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), sun_rad)
		for i=sun_rad,math.abs(sun_rad+sun_power),10 do
			set_color(1, 1, 1,0.03)
			draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), i)
		end
	end
		
	set_color(0.5,0.28,0,1)
	draw_capsule(60.75, -35, 9.5, 19, 1.25, 0, -4, 0)

	set_color(0.25,0.29,0,1)
	draw_capsule(61.25, -35, 18.75, 0.50, 1.5, 0, -4, 0)

	set_color(0,0.3,0,1)
	draw_capsule(-15.5, 7.25, 1.5, 3, 0.5, 0, 0, 0)
	draw_capsule(-15.75, 6, 3.25, 1.5, 0.5, 0, 0, 0)
	draw_capsule(-15.75, 6.5, 2.5, 0.75, 0.5, -88, 8, 0)
	draw_capsule(-15.25, 8, 1.25, 0.75, 0.5, -88, 8, 0)
	draw_capsule(-15.0, 8.75, 2.4, 2.25, 0.5, 0, 0, 0)

	draw_capsule(9.75, -20.25, 3.5, 6.5, 0.5, 0, 0, 0)
	draw_capsule(7.75, -20.25, 2.75, 2, 0.5, 0, 0, 0)
	draw_capsule(12, -20.25, 3.75, 2, 0.5, 0, 0, 0)
	draw_capsule(8.75, -20.25, 1.75, 2, 0.5, 96, -84, 0)
	draw_capsule(10.75, -20.25, 2.75, 2, 0.5, 96, -84, 0)

	draw_box(61.75, -37.5, 21.25, 2.25, 4.5, 0.25, 24, -4, 0)
	draw_box(59.75, -35.75, 21.25, 2.25, 4.5, 0.25, 12, -20, 52)
	draw_box(63, -36.25, 20.75, 2.25, 4.5, 0.25, 24, -4, -28)
	draw_box(64.25, -34, 20.75, 2.25, 4.5, 0.25, 8, 20, -104)
	draw_box(62.25, -32.5, 20.75, 2.25, 4.5, 0.25, -12, 8, -164)

	draw_box(58.5, -33.25, 21.00, 2.25, 4.5, 0.25, -12, -28, -240)
	draw_box(53, -30.50, 19, 2.25, 10.5, 0.25, 12, 36, -240)
	draw_box(61.75, -44, 20.75, 2.25, 9.5, 0.25, -16, -4, 0)
	draw_box(53.75, -40, 20, 2.25, 12.25, 0.25, -16, 16, 52)
	draw_box(67, -43, 17.5, 2.25, 14.25, 0.25, -28, -20, -28)
	draw_box(71.75, -32.75, 18.75, 2.25, 12.25, 0.25, 20, -24, -104)
	draw_box(64.75, -25, 17.5, 2.25, 14, 0.25, 36, 8, -164)

	
	set_color(0,0.3,0.8,1)
	local z_water = 0
	if(get_option("shaders")==0) then
		z_water = 0.1
	end
	draw_box(46, -21, z_water, 17, 14.75, 0.01, 0, 0, 0)
	draw_box(44.25, -21, z_water, 17, 14.75, 0.01, 0, 0, -12)
	draw_box(44.75, -21, z_water, 17, 14.75, 0.01, 0, 0, -48)
	draw_box(52.5, -19.75, z_water, 17, 14.755, 0.01, 0, 0, -76)
	draw_box(54.5, -19.75, z_water, 17, 14.755, 0.01, 0, 0, -12)

	set_color(0.8, 0.6, 0.1,1)

	for i=0,59 do
		draw_box(-50, -80, i*0.25, 20-(i/3), 20-(i/3), 0.25, 0, 0, -24)
		draw_box(50, 80, i*0.25, 20-(i/3), 20-(i/3), 0.25, 0, 0, 12)
		draw_box(50, 20, i*0.25, 20-(i/3), 20-(i/3), 0.25, 0, 0, 0)
		draw_box(0, 100, i*0.25, 20-(i/3), 20-(i/3), 0.25, 0, 0, 12)
	end
end

return {
	onRender = atmo_desert
}