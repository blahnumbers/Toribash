-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local graphics_level = Settings and Settings.GetLevel() or 1
local nb_bubbles = (graphics_level + 1) * 50
local cutoff_1 = math.round(nb_bubbles * 0.4)
local cutoff_2 = math.round(nb_bubbles * 0.8)

local bubble_pos_x = { }
local bubble_pos_y = { }
local bubble_pos_z = { }
local bubble_vel_z = { }
local bubble_alpha = { }
local bubble_rad = { }

local function atmo_underwater()
	if(get_option("shaders")==0) then
		set_color(0.50, 0.50, 0.40,1)
		draw_box(0, 0, 0.025, 1000, 1000, 0.08, 0, 0, 0)
		set_color(1, 1, 2,1)
		draw_sphere(0, 0, 0, -500)
		set_color(0.5,0.5,2,0.1)
		for i=1,30 do
		 draw_sphere(0, 0, 0, 5 + math.random(-100,100)/1000 + 5*i)
		end
	else
		-- blue "fog"
		local camera_info = get_camera_info()
		set_color(1.00, 1.00, -2.00,-0.1)
		for i=0,5 do
			draw_sphere(math.random(-100,100)/1000 + camera_info.pos.x,math.random(-100,100)/1000 + camera_info.pos.y,math.random(-100,100)/1000 + camera_info.pos.z,-i)
		end
	end

	for i=1,nb_bubbles do
		set_color(1.00, 1.00, 1.00,bubble_alpha[i])
		draw_sphere(bubble_pos_x[i],bubble_pos_y[i],bubble_pos_z[i],bubble_rad[i])
	end

end

local function atmo_underwater_enterframe(_, speed)
	for i = 1, nb_bubbles do
		bubble_pos_z[i] = bubble_pos_z[i] + bubble_vel_z[i] * speed
		bubble_alpha[i] = bubble_alpha[i] - 0.005 * speed
		if(bubble_alpha[i]<0) then
			if(i <= cutoff_1) then
				local body_info = get_body_info(0, 0)
				bubble_pos_x[i] = body_info.pos.x + math.random(-500,500)/2000
				bubble_pos_y[i] = body_info.pos.y + math.random(-500,500)/2000
				bubble_pos_z[i] = body_info.pos.z + math.random(0,500)/1000
				bubble_vel_z[i] = math.random(10,100)/5000
				bubble_rad[i] = math.random(200,500)/8000
				bubble_alpha[i] = math.random(500,1000)/1000
			elseif(i <= cutoff_2) then
				local body_info = get_body_info(1, 0)
				bubble_pos_x[i] = body_info.pos.x + math.random(-500,500)/2000
				bubble_pos_y[i] = body_info.pos.y + math.random(-500,500)/2000
				bubble_pos_z[i] = body_info.pos.z + math.random(0,500)/1000
				bubble_vel_z[i] = math.random(10,100)/5000
				bubble_rad[i] = math.random(200,500)/8000
				bubble_alpha[i] = math.random(500,1000)/1000
			else
				bubble_pos_x[i] = math.random(-2100,2100)/100
				bubble_pos_y[i] = math.random(-2100,2100)/100
				bubble_rad[i] = math.random(200,500)/4000
				bubble_pos_z[i] = bubble_rad[i]/2 +  math.random(0,2000)/2000
				bubble_vel_z[i] = math.random(100,1000)/8000
				bubble_alpha[i] = math.random(200,500)/1000
			end
		end
	end
end

local body_info = get_body_info(0, 0)
for i=1,cutoff_1 do
	bubble_pos_x[i] = body_info.pos.x + math.random(-500,500)/2000
	bubble_pos_y[i] = body_info.pos.y + math.random(-500,500)/2000
	bubble_pos_z[i] = body_info.pos.z + math.random(0,500)/1000
	bubble_vel_z[i] = math.random(10,100)/5000
	bubble_rad[i] = math.random(200,500)/8000
	bubble_alpha[i] = math.random(500,1000)/1000
end
body_info = get_body_info(1, 0)
for i=cutoff_1+1,cutoff_2 do
	bubble_pos_x[i] = body_info.pos.x + math.random(-500,500)/2000
	bubble_pos_y[i] = body_info.pos.y + math.random(-500,500)/2000
	bubble_pos_z[i] = body_info.pos.z + math.random(0,500)/1000
	bubble_vel_z[i] = math.random(10,100)/5000
	bubble_rad[i] = math.random(200,500)/8000
	bubble_alpha[i] = math.random(500,1000)/1000
end
for i=cutoff_2,nb_bubbles do
	bubble_pos_x[i] = math.random(-2100,2100)/100
	bubble_pos_y[i] = math.random(-2100,2100)/100
	bubble_rad[i] = math.random(200,500)/4000
	bubble_pos_z[i] = bubble_rad[i]/2 +  math.random(0,2000)/2000
	bubble_vel_z[i] = math.random(100,1000)/8000
	bubble_alpha[i] = math.random(200,500)/1000
end

return {
	onRender = atmo_underwater,
	onEnterFrame = atmo_underwater_enterframe
}