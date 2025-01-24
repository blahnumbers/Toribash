-- Script made by Kyat
-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local graphics_level = Settings and Settings.GetLevel() or 1
local nb_bubbles = (graphics_level + 1) * 100

local bubble_pos = { }	--X,Y,Z
local bubble_step = { }
local bubble_bigstep = { }
local bubble_radius = { }
local bubble_alpha = { }
local bubble_color = { }
local bubble_speed = { }
local bubble_fixed = { }

local function bubble_init(i)
	bubble_pos[i] = {math.random(-250,250), math.random(-250,250),math.random(-25,-5)}
	bubble_radius[i] = math.random(150,650)/100
	bubble_bigstep[i] = math.random(1000,25000)/100
	bubble_step[i] = 0
	bubble_alpha[i] = math.random(33,67)/100
	bubble_color[i] = math.random(1,100)
	bubble_speed[i] = math.random(0,15)/100
	bubble_fixed[i] = math.random(0,100)
end

local function bcolor(i, alpha_mult)
	if bubble_color[i] <= 25 then
		set_color(1.0,1.0,1.0,bubble_alpha[i] * alpha_mult)
	elseif bubble_color[i] <= 50 then
		set_color(0.4,0.0,0.0,bubble_alpha[i] * alpha_mult)
	elseif bubble_color[i] <= 75 then
		set_color(0.75,0.80,0.8,bubble_alpha[i] * alpha_mult)
	else
		set_color(0.80,0.25,0.75,bubble_alpha[i] * alpha_mult)
	end
end

for i=1,nb_bubbles do
	bubble_init(i)
end


local function atmo_bubbles()
	if(get_option("shaders")==0) then
		set_color(1.2,1,1.2,1)
		draw_box(0, 0, 0.025, 1000, 1000, 0.08, 0, 0, 0)
		set_color(1.9, 1.5, 1.9,1)
		draw_sphere(0, 0, 0, -500)
		
		local sun_u = 0.05
		local sun_v = 0.25
		local sun_rad = 40
		local sun_power = 10
		
		set_color(1.00, 1.00, 1.00,0.5)
		draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), sun_rad)
		for i=sun_rad,math.abs(sun_rad+sun_power),10 do
			set_color(1.0, 1.0, 1.0,0.03)
			draw_sphere(math.ceil(500*math.cos(sun_u*math.pi)*math.cos(sun_v*math.pi)),math.ceil(500*math.cos(sun_u*math.pi)*math.sin(sun_v*math.pi)), math.ceil(500*math.sin(sun_u*math.pi)), i)
		end
	end
	for i = 1, nb_bubbles do
		bcolor(i, 1 - math.pow(bubble_step[i] / bubble_bigstep[i], 3))
		draw_sphere(bubble_pos[i][1], bubble_pos[i][2], bubble_pos[i][3], bubble_radius[i])
	end
end

local function atmo_bubbles_enterframe(_, speed)
	for i = 1, nb_bubbles do
		if (bubble_step[i] <= bubble_bigstep[i]) then
			bubble_step[i] = bubble_step[i] + 1 * speed
			if (bubble_fixed[i] <= 75) then
				bubble_pos[i][3] = bubble_pos[i][3] + bubble_speed[i] * speed
			end
		else
			bubble_init(i)
		end
	end
end

return {
	onRender = atmo_bubbles,
	onEnterFrame = atmo_bubbles_enterframe
}