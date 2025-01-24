-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local pulse = 0

local function atmo_night_club_blue()
	set_color(0.40,0.40,0.70,1)
	draw_box(-40, 0, 5, 0.5, 80, 10, 0, 0, 0)
	draw_box(40, 0, 5, 0.5, 80, 10, 0, 0, 0)
	draw_box(0, 40, 5, 80, 0.5, 10, 0, 0, 0)
	draw_box(0, -40, 5, 80, 0.5, 10, 0, 0, 0)
		
	for i=0,7 do
		for j=0,7 do
			local change_color = math.abs((math.floor(pulse/15) % 2))
			local color = ((i + j + change_color) % 2)
			
			if(get_option("shaders")==0) then
				set_color(color/3,color/3.0,color,1)
				draw_box(-35 + 10*i, -35 + 10*j, 10, 10, 10, 0.001, 0, 0, 0)
				draw_box(-35 + 10*i, -35 + 10*j, 0.025, 10, 10, 0.08, 0, 0, 0)
			else
				set_color(color,color,color,1)
				draw_box(-35 + 10*i, -35 + 10*j, 10, 10, 10, 0.001, 0, 0, 0)
			end
		end
	end
	
	set_color(0.30,0.30,0.30,1)
	draw_box(40, 1.75, 5, 0.9, 10, 10, 0, 0, 0)
		
	set_color(0.30,0.30,0.80,1)
	draw_box(40, 0, 4.5, 1.2, 3.5, 9, 0, 0, 0)
	draw_box(40, 3.55, 4.5, 1.2, 3.5, 9, 0, 0, 0)
		
	set_color(0.5,1,1,1)
	draw_capsule(38.5, 0.4, 4, 0.5,0.1,90,0,0)
	draw_capsule(38.5, 2.8, 4, 0.5,0.1,90,0,0)
	
	set_color(0.00,0.00,0.40,1)
	draw_box(32.5, 25, 2, 15, 30, 4, 0, 0, 0)
	
	set_color(0.00,1.00,1.00,0.1)
	draw_box(32.5, 25, 8, 15, 30, 8, 0, 0, 0)
	
	set_color(0.00,0.30,0.30,1)
	draw_box(-32.5, -25, 2, 15, 30, 4, 0, 0, 0)
	draw_box(-32.5, -25, 9.5, 15, 30, 1, 0, 0, 0)
	
	for i=0,5 do
		if(math.floor(pulse/20) % 8 == i) then
			set_color(0.00,1.00,2.00,0.9)
		else
			set_color(0.00,0.00,2.00,0.9)			
		end
		draw_sphere(-26, -36 + 5 * i, 9, 0.3)
	end
	for i=1,2 do
		if(math.floor(pulse/20) % 8 == i+5) then
			set_color(0.00,1.00,2.00,0.9)
		else
			set_color(0.00,0.00,2.00,0.9)			
		end
		draw_sphere(-26 - 5 *i, -11, 9, 0.3)
	end
	
	set_color(0.60,0.60,0.60,1)
	draw_capsule(39, -22, 9.5, 34,0.2,90,0,0)
	draw_capsule(0, -39, 9.5, 78,0.2,90,90,0)
	draw_capsule(-7, 39, 9.5, 62,0.2,90,90,0)
	draw_capsule(-38.5, 0, 9.5, 78,0.2,90,0,0)
	draw_capsule(0, 0, 9.5, 78,0.2,90,0,0)
	
	set_color(0.25,0.25,0.25,1)
	draw_box(0, 38, 7.2, 2, 2, 4, -30, 0, 0)
	draw_box(-38, 38, 7.5, 2, 2, 4, -15, -15, -40)
	draw_box(0, -38, 7.2, 2, 2, 4, 30, 0, 0)
	draw_box(38, -38, 7.5, 2, 2, 4, 15, 15, -40)
	draw_box(-38, 0, 7.2, 2, 2, 4, 0, -30, 0)
	draw_box(38, -6, 7.2, 2, 2, 4, 0, 30, 0)
	
	set_color(0.3,0.3,0.3,1)
	draw_box(-15, 32.5, 0.5, 25, 15, 1, 0, 0, 0)
	set_color(0.8,0.3,0.3,1)
	draw_box(-15, 33, 1.5, 23, 14, 1, 0, 0, 0)
	
	set_color(0.8,0.8,0.8,1)
	draw_capsule(-21, 28, 5, 10,0.1,0,0,0)
	draw_capsule(-9, 28, 5, 10,0.1,0,0,0)
	
	set_color(0.00,0.10,0.90,1)
	draw_box(30, -38, 0.5, 20, 4, 1, 0, 0, 0)
	draw_box(30, -39.5, 1, 20, 1, 2, 0, 0, 0)
	draw_box(38, -30, 0.5, 4, 20, 1, 0, 0, 0)
	draw_box(39.5, -30, 1, 2, 20, 2, 0, 0, 0)
	
	draw_box(2, -32.5, 0.5, 4, 15, 1, 0, 0, 0)
	draw_box(3.5, -32.5, 1, 2, 15, 2, 0, 0, 0)
	draw_box(-8, -32.5, 0.5, 4, 15, 1, 0, 0, 0)
	draw_box(-9.5, -32.5, 1, 2, 15, 2, 0, 0, 0)
	
	draw_box(-32.5, 12, 0.5, 15, 4, 1, 0, 0, 0)
	draw_box(-32.5, 13.5, 1, 15, 2, 2, 0, 0, 0)
	draw_box(-32.5, 2, 0.5, 15, 4, 1, 0, 0, 0)
	draw_box(-32.5, 0.5, 1, 15, 2, 2, 0, 0, 0)
		
	set_color(0.8,0.8,0.8,1)
	draw_box(32.5, -27, 1.5, 4, 15, 0.2, 0, 0, 0)
	draw_box(27, -32.5, 1.5, 15, 4, 0.2, 0, 0, 0)
	draw_capsule(32.5, -21, 0.75, 1.1,0.3,0,0,0)
	draw_capsule(21, -32.5, 0.75, 1.1,0.3,0,0,0)
	draw_capsule(32.5, -32.5, 0.75, 1.1,0.3,0,0,0)
	
	draw_box(-3, -32.5, 1.5, 4, 15, 0.2, 0, 0, 0)
	draw_capsule(-3, -26, 0.75, 1.1,0.3,0,0,0)
	
	draw_box(-32.5, 7, 1.5, 15, 4, 0.2, 0, 0, 0)
	draw_capsule(-26, 7, 0.75, 1.1,0.3,0,0,0)
	
	set_color(0.2,0.2,0.2,1)
	draw_capsule(-38.5, 13, 9, 1.5,0.5,40*math.cos(pulse/20),50,0)
	draw_capsule(-38.5, 23, 9, 1.5,0.5,40*math.sin(pulse/20),50,0)
	
	set_color(1+math.cos(pulse/10),1+math.cos(pulse/30),1+math.cos(pulse/40),0.8)
	draw_capsule(-38.5, 13, 9, 1.75,0.45,40*math.cos(pulse/20),50,0)
	
	set_color(1+math.cos(pulse/15),1+math.cos(pulse/50),1+math.cos(pulse/5),0.8)
	draw_capsule(-38.5, 23, 9, 1.75,0.45,40*math.sin(pulse/20),50,0)
	
	set_color(0.2,0.2,0.2,1)
	draw_capsule(10, 38.5, 9, 1.5,0.5,50,40*math.cos(pulse/20),0)
	draw_capsule(22, 38.5, 9, 1.5,0.5,50,40*math.sin(pulse/20),0)
	
	set_color(1+math.cos(pulse/10),1+math.cos(pulse/30),1+math.cos(pulse/40),0.8)
	draw_capsule(10, 38.5, 9, 1.75,0.45,50,40*math.cos(pulse/20),0)
	
	set_color(1+math.cos(pulse/15),1+math.cos(pulse/50),1+math.cos(pulse/5),0.8)
	draw_capsule(22, 38.5, 9, 1.75,0.45,50,40*math.sin(pulse/20),0)
	
	set_color(0.2,0.2,0.2,1)
	draw_capsule(-21, 38.5, 9, 1.5,0.5,50,40*math.cos(pulse/20),0)
	draw_capsule(-9, 38.5, 9, 1.5,0.5,50,40*math.sin(pulse/20),0)
	
	set_color(1+math.cos(pulse/40),1+math.cos(pulse/5),1+math.cos(pulse/10),0.8)
	draw_capsule(-21, 38.5, 9, 1.75,0.45,50,40*math.cos(pulse/20),0)
	
	set_color(1+math.cos(pulse/20),1+math.cos(pulse/25),1+math.cos(pulse/5),0.8)
	draw_capsule(-9, 38.5, 9, 1.75,0.45,50,40*math.sin(pulse/20),0)
	
	set_color(0.2,0.2,0.2,1)
	draw_capsule(38.5, -14, 9, 1.5,0.5,40*math.cos(pulse/20),-50,0)
	draw_capsule(38.5, -28, 9, 1.5,0.5,40*math.sin(pulse/20),-50,0)
	
	set_color(1+math.cos(pulse/10),1+math.cos(pulse/30),1+math.cos(pulse/40),0.8)
	draw_capsule(38.5, -14, 9, 1.75,0.45,40*math.cos(pulse/20),-50,0)
	
	set_color(1+math.cos(pulse/15),1+math.cos(pulse/50),1+math.cos(pulse/5),0.8)
	draw_capsule(38.5, -28, 9, 1.75,0.45,40*math.sin(pulse/20),-50,0)
		
	set_color(0.2,0.2,0.2,1)
	draw_capsule(10, -38.5, 9, 1.5,0.5,-50,40*math.cos(pulse/20),0)
	draw_capsule(28, -38.5, 9, 1.5,0.5,-50,40*math.sin(pulse/20),0)
	
	set_color(1+math.cos(pulse/10),1+math.cos(pulse/30),1+math.cos(pulse/40),0.8)
	draw_capsule(10, -38.5, 9, 1.75,0.45,-50,40*math.cos(pulse/20),0)
	
	set_color(1+math.cos(pulse/15),1+math.cos(pulse/50),1+math.cos(pulse/5),0.8)
	draw_capsule(28, -38.5, 9, 1.75,0.45,-50,40*math.sin(pulse/20),0)
	
	set_color(0.2,0.2,0.2,1)
	draw_capsule(-20, -38.5, 9, 1.5,0.5,-50,40*math.cos(pulse/20),0)
	draw_capsule(-8, -38.5, 9, 1.5,0.5,-50,40*math.sin(pulse/20),0)
	
	set_color(1+math.cos(pulse/40),1+math.cos(pulse/5),1+math.cos(pulse/10),0.8)
	draw_capsule(-20, -38.5, 9, 1.75,0.45,-50,40*math.cos(pulse/20),0)
	
	set_color(1+math.cos(pulse/20),1+math.cos(pulse/25),1+math.cos(pulse/5),0.8)
	draw_capsule(-8, -38.5, 9, 1.75,0.45,-50,40*math.sin(pulse/20),0)
	
	set_color(0.2,0.2,0.2,1)
	draw_capsule(0, -30, 9.5, 1.5,0.5,0,40*math.cos(pulse/30),0)
	set_color(1+math.cos(pulse/10),1+math.cos(pulse/20),1+math.cos(pulse/30),0.8)
	draw_capsule(0, -30, 9.5, 1.75,0.45,0,40*math.cos(pulse/30),0)
	
	set_color(0.2,0.2,0.2,1)
	draw_capsule(0, -20, 9.5, 1.5,0.5,0,-40*math.cos(pulse/30),0)
	set_color(1+math.cos(pulse/35),1+math.cos(pulse/5),1+math.cos(pulse/15),0.8)
	draw_capsule(0, -20, 9.5, 1.75,0.45,0,-40*math.cos(pulse/30),0)
	
	set_color(0.2,0.2,0.2,1)
	draw_capsule(0, -10, 9.5, 1.5,0.5,0,40*math.cos(pulse/30),0)
	set_color(1+math.cos(pulse/60),1+math.cos(pulse/10),1+math.cos(pulse/25),0.8)
	draw_capsule(0, -10, 9.5, 1.75,0.45,0,40*math.cos(pulse/30),0)
	
	set_color(0.2,0.2,0.2,1)
	draw_capsule(0, 0, 9.5, 1.5,0.5,0,-40*math.cos(pulse/30),0)
	set_color(1+math.cos(pulse/5),1+math.cos(pulse/25),1+math.cos(pulse/15),0.8)
	draw_capsule(0, 0, 9.5, 1.75,0.45,0,-40*math.cos(pulse/30),0)
	
	set_color(0.2,0.2,0.2,1)
	draw_capsule(0, 10, 9.5, 1.5,0.5,0,40*math.cos(pulse/30),0)
	set_color(1+math.cos(pulse/45),1+math.cos(pulse/25),1+math.cos(pulse/10),0.8)
	draw_capsule(0, 10, 9.5, 1.75,0.45,0,40*math.cos(pulse/30),0)
	
	set_color(0.2,0.2,0.2,1)
	draw_capsule(0, 20, 9.5, 1.5,0.5,0,-40*math.cos(pulse/30),0)
	set_color(1+math.cos(pulse/5),1+math.cos(pulse/15),1+math.cos(pulse/30),0.8)
	draw_capsule(0, 20, 9.5, 1.75,0.45,0,-40*math.cos(pulse/30),0)
	
	set_color(0.2,0.2,0.2,1)
	draw_capsule(0, 30, 9.5, 1.5,0.5,0,40*math.cos(pulse/30),0)
	set_color(1+math.cos(pulse/10),1+math.cos(pulse/30),1+math.cos(pulse/90),0.8)
	draw_capsule(0, 30, 9.5, 1.75,0.45,0,40*math.cos(pulse/30),0)
end

local function atmo_night_club_enterframe(_, speed)
	local change_light = pulse % 30
	local change_floor = pulse % 60
	
	if(change_light==0) then
		set_shader_option(4, math.random(0, 100) / 200, math.random(0,100) / 200, 4 * math.random(0,100) / 200, 1)
	end
	if(change_floor==0) then
		set_shader_option(2, math.random(0, 100) / 200, math.random(0,100) / 200, 4 * math.random(0,100) / 200, 1)
	end
	pulse = pulse + math.round(speed)
end

return {
	onRender = atmo_night_club_blue,
	onEnterFrame = atmo_night_club_enterframe
}