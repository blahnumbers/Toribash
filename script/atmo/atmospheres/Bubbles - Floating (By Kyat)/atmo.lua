-- Script made by Kyat
-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local function is_animated()
	return (get_world_state().game_paused==0 and is_game_frozen()==1 and get_world_state().replay_mode==1) or (get_world_state().game_paused==0 and is_game_frozen()==0 and get_world_state().replay_mode==0 ) or (get_world_state().replay_mode==2 and get_world_state().game_paused==0) 
end

local bubble_pos = { }	--X,Y,Z
local bubble_step = { }
local bubble_bigstep = { }
local bubble_radius = { }
local bubble_alpha = { }
local bubble_color = { }
local bubble_speed = { }
local bubble_fixed = { }
local nb_bubbles = 300

--bubbles Init
function bubble_init(i)
--bubbles
	bubble_pos[i] = {math.random(-250,250), math.random(-250,250),math.random(-25,-5)}
	--while bubble_pos[i][1] > -50 and bubble_pos[i][1] < 50 do	bubble_pos[i][1] = math.random(-250,250) end
	--while bubble_pos[i][2] > -50 and bubble_pos[i][2] < 50 do	bubble_pos[i][2] = math.random(-250,250) end
	bubble_radius[i] = math.random(150,650)/100
	bubble_bigstep[i] = math.random(1000,25000)/100
	bubble_step[i] = 0
	bubble_alpha[i] = math.random(10,25)/100
	bubble_color[i] = math.random(1,100)
	bubble_speed[i] = math.random(0,15)/100
	bubble_fixed[i] = math.random(0,100)
end

function bcolor(i)
	if bubble_color[i]<=29 then
		set_color(1.0,1.0,1.0,bubble_alpha[i])
	elseif bubble_color[i]>29 and bubble_color[i]<=59 then
		set_color(0.4,0.0,0.0,bubble_alpha[i])
	elseif bubble_color[i]>60 and bubble_color[i]<=99 then
		set_color(0.75,0.80,0.8,bubble_alpha[i])
	else
		set_color(0.80,0.25,0.75,bubble_alpha[i])
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
	if(is_animated()) then
		for i=1,nb_bubbles do
			if bubble_step[i] <= bubble_bigstep[i] then
				bubble_step[i]=bubble_step[i]+1
				if bubble_fixed[i] <=75 then
					bubble_pos[i][3]=bubble_pos[i][3]+bubble_speed[i]
				end
				bcolor(i)
				draw_sphere(bubble_pos[i][1], bubble_pos[i][2], bubble_pos[i][3], bubble_radius[i])
			else
			 bubble_init(i)
			end
		end
	else
		for i=1,nb_bubbles do
			bcolor(i)
			draw_sphere(bubble_pos[i][1], bubble_pos[i][2], bubble_pos[i][3], bubble_radius[i])
		end
	end
end

add_hook("draw3d", "atmo", atmo_bubbles)
echo("This atmosphere is designed to be used with shaders and reflection.")
