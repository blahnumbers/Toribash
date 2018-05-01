-- Script made by Kyat
-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

do

local function is_animated()
	return (get_world_state().game_paused==0 and is_game_frozen()==1 and get_world_state().replay_mode==1) or (get_world_state().game_paused==0 and is_game_frozen()==0 and get_world_state().replay_mode==0 ) or (get_world_state().replay_mode==2 and get_world_state().game_paused==0) 
end

--[[run_cmd("worldshader 0 0.80 0.87 0.80")
run_cmd("worldshader 1 0.20 0.27 0.20") --1.00 1.00 1.00")
run_cmd("worldshader 2 0.40 0.40 0.40")
run_cmd("worldshader 3 1.00 1.00 1.00")
run_cmd("worldshader 4 1.00 1.00 1.00")
run_cmd("worldshader 5 56.00")
run_cmd("worldshader 6 0")
run_cmd("worldshader 7 1")
run_cmd("worldshader 8 0.71 0.00 0.71")
run_cmd("worldshader 9 0.82 0.00 0.22")
run_cmd("worldshader 10 0.00 1.00 1.00")
run_cmd("worldshader 11 1.00 1.00 1.00")
run_cmd("worldshader 12 0.80 0.30 0.50")
run_cmd("worldshader 13 1.00 0.00 0.00")
run_cmd("worldshader 14 0.70 0.70 0.14")
run_cmd("worldshader 15 1.30")]]

local bubble_pos = { }	--X,Y,Z
local bubble_radius = { }
local bubble_alpha = { }
local bubble_color = { }
local bubble_speed = { }
local bubble_dir = { } 
local bubble_topheight = { }
local nb_bubbles = 300

--bubbles Init
function bubble_init(i)
--bubbles
	bubble_pos[i] = {math.random(-250,250), math.random(-250,250),math.random(15,55)}
	--while bubble_pos[i][1] > -50 and bubble_pos[i][1] < 50 do	bubble_pos[i][1] = math.random(-250,250) end
	--while bubble_pos[i][2] > -50 and bubble_pos[i][2] < 50 do	bubble_pos[i][2] = math.random(-250,250) end
	bubble_radius[i] = math.random(150,650)/100
	bubble_alpha[i] = math.random(89,99)/100
	bubble_color[i] = math.random(1,100)
	bubble_speed[i] = math.random(0,15)/100
	bubble_dir[i] = math.random(0,1)
	bubble_topheight[i] = bubble_pos[i][3]
end

function bcolor(i)
	if bubble_color[i]<=29 then
		set_color(1.0,1.0,1.0,bubble_alpha[i])
	elseif bubble_color[i]>29 and bubble_color[i]<=59 then
		set_color(0.80,0.87,1.0,bubble_alpha[i])
	elseif bubble_color[i]>60 and bubble_color[i]<=100 then
		set_color(1.00,0.70,0.80,bubble_alpha[i])
	end
end

for i=1,nb_bubbles do
	bubble_init(i)
end


local function atmo_bbubbles()
	if(get_option("shaders")==0) then
		set_color(1,1.3,1.2,1)
		draw_box(0, 0, 0.025, 1000, 1000, 0.08, 0, 0, 0)
		set_color(1.0, 1.5, 1.6,1)
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
			
				if bubble_dir[i] == 0 then
					if bubble_pos[i][3]-bubble_speed[i] > bubble_radius[i] then 
						bubble_pos[i][3]=bubble_pos[i][3]-bubble_speed[i]
					else
						bubble_dir[i] = 1
					end
				else
					if bubble_pos[i][3]+bubble_speed[i] < bubble_topheight[i] then 
						bubble_pos[i][3]=bubble_pos[i][3]+bubble_speed[i]
					else
						bubble_dir[i] = 0
					end
				end
				bcolor(i)
				draw_sphere(bubble_pos[i][1], bubble_pos[i][2], bubble_pos[i][3], bubble_radius[i])
		end
	else
		for i=1,nb_bubbles do
			bcolor(i)
			draw_sphere(bubble_pos[i][1], bubble_pos[i][2], bubble_pos[i][3], bubble_radius[i])
		end
	end
end

add_hook("draw3d", "atmo", atmo_bbubbles)

end