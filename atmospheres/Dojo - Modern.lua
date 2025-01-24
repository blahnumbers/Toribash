-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local function atmo_modern_dojo()
	set_color(0.96,0.89,0.61,1)
	draw_box(-40, 0, 10, 0.5, 80, 10, 0, 0, 0)
	draw_box(40, 0, 8.5, 0.5, 80, 7, 0, 0, 0)
	draw_box(0, 40, 10, 80, 0.5, 10, 0, 0, 0)
	draw_box(0, -40, 10, 80, 0.5, 10, 0, 0, 0)
	draw_box(40, -39, 13, 0.5, 2, 2, 0, 0, 0)
	for cpt=0,7 do
		draw_box(40, -35 + 10*cpt, 13, 0.5, 6, 2, 0, 0, 0)
	end
	draw_box(40, 39, 13, 0.5, 2, 2, 0, 0, 0)
	draw_box(40, 0, 14.5, 0.5, 80, 1, 0, 0, 0)
	
	
	set_color(0.10,0.20,0.10,1)
	draw_box(-40, 0, 2.5, 0.5, 80, 5, 0, 0, 0)
	draw_box(40, 0, 2.5, 0.5, 80, 5, 0, 0, 0)
	draw_box(0, 40, 2.5, 80, 0.5, 5, 0, 0, 0)
	draw_box(0, -40, 2.5, 80, 0.5, 5, 0, 0, 0)
	
	
	
	set_color(0.86,0.69,0.41,1)
	draw_box(0, 0, 15, 80, 80, 0.001, 0, 0, 0)
	
	set_color(0.10,0.10,0.90,0.1)
	for cpt=0,6 do
		draw_box(40, -30 + 10*cpt, 13, 0.5, 4, 2, 0, 0, 0)
	end
	
	set_color(0.56,0.49,0.21,1)
	for cpt=1,4 do
		draw_box(45 - cpt*20, 0, 14.5, 2, 80, 1, 0, 0, 0)
	end
	for cpt=0,8 do
		draw_box(0, 45 - cpt*10, 14.75, 80, 2, 0.5, 0, 0, 0)
	end
	
	set_color(0.56,0.29,0.01,1)
	draw_box(-40, 20, 4.5, 0.9, 3.5, 9, 0, 0, 0)
	draw_box(-40, 23.54, 4.5, 0.9, 3.5, 9, 0, 0, 0)
	
	set_color(0.4,0.4,0.4,1)
	draw_capsule(-38.5, 20.4, 4, 0.5,0.1)
	draw_capsule(-38.5, 22.8, 4, 0.5,0.1)
	
	
	if(get_option("shaders")==0) then
		set_color(0.00,0.00,1.00,1)
		draw_box(0, 0, 0.02, 80, 80, 0.001, 0, 0, 0)
	end
	set_color(1.00,0.00,0.00,1)
	local d_type = get_game_rules().dojotype
	local d_size = get_game_rules().dojosize
	
	if(d_size == 0) then
		d_type = 0
		d_size = 1600
	end
	if(d_type == 0) then
		draw_box(0.5+d_size/200, -0.1, 0.03, 1, d_size/100, 0.001, 0, 0, 0)
		draw_box(1.5-d_size/200, -0.1, 0.03, 1, d_size/100, 0.001, 0, 0, 0)
		draw_box(1, -0.60+d_size/200, 0.03, d_size/100, 1, 0.001, 0, 0, 0)
		draw_box(1, 0.40-d_size/200, 0.03, d_size/100, 1, 0.001, 0, 0, 0)
	elseif(d_type == 1) then
		for cpt=0,89 do
			draw_box(1 - math.cos(cpt*4*3.14/180)*(0.5 - d_size/100), -0.1 - math.sin(cpt*4*3.14/180)*(d_size/100 - 0.5), 0.03, 1, 1, 0.001, 0, 0, 4*cpt)
			
		end
	end
end

return {
	onRender = atmo_modern_dojo
}