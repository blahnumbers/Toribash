-- (c) Melmoth 2010 - http://g.hssn.free.fr/atmospheres/

local volcano_relief_pos_x = { }
local volcano_relief_pos_y = { }
local volcano_relief_rad = { }
local volcano_lava_pos_x = { }
local volcano_lava_pos_y = { }
local volcano_lava_pos_z = { }
local volcano_lava_vel_x = { }
local volcano_lava_vel_y = { }
local volcano_lava_vel_z = { }
local volcano_lava_rad = { }
local volcano_lava_alpha = { }
local gravity = 0.01
local volcano_ashes_pos_x = { }
local volcano_ashes_pos_y = { }
local volcano_ashes_pos_z = { }
local volcano_ashes_speedx = { }
local volcano_ashes_speedy = { }
local volcano_ashes_speedz = { }
local volcano_ashes_sizex = { }
local volcano_ashes_sizey = { }
local volcano_ashes_rot_x = { }
local volcano_ashes_rot_y = { }
local volcano_ashes_rot_z = { }
local volcano_ashes_drot_x = { }
local volcano_ashes_drot_y = { }
local volcano_ashes_drot_z = { }

local function atmo_volcano()
	if(get_option("shaders")==0) then
		set_color(0.22, 0.2, 0.2,1)
		draw_box(0, 0, 0, 1000, 1000, 0.08, 0, 0, 0)
		set_color(0.42, 0.2, 0.2,1)
		draw_sphere(0, 0, 0, -500)
	end

	set_color(0.12, 0.1, 0.1, 1)
	for i=0,50 do
		draw_sphere(volcano_relief_pos_x[i],volcano_relief_pos_y[i],0,volcano_relief_rad[i])
		draw_box( volcano_ashes_pos_x[i], volcano_ashes_pos_y[i], volcano_ashes_pos_z[i], volcano_ashes_sizex[i], volcano_ashes_sizey[i], 0.001, volcano_ashes_rot_x[i], volcano_ashes_rot_y[i], volcano_ashes_rot_z[i])
	end

	set_color(0.22, 0.2, 0.2,1)
	for i=1,20 do
		for j=0,6 do
			draw_sphere(120*math.cos(i),120*math.sin(i),j*2,15-j+(math.pow(i,2)/10))
		end
	end

	for i=0,175 do
		set_color(1.00, volcano_lava_alpha[i]/2, 0.00,volcano_lava_alpha[i])
		draw_sphere(volcano_lava_pos_x[i],volcano_lava_pos_y[i],volcano_lava_pos_z[i],volcano_lava_rad[i])
	end
end

local function atmo_volcano_enterframe(_, speed)
	for i=0, 50 do
		volcano_ashes_pos_z[i] = volcano_ashes_pos_z[i] + volcano_ashes_speedz[i] * speed
		volcano_ashes_pos_x[i] = volcano_ashes_pos_x[i] + volcano_ashes_speedx[i] * speed
		volcano_ashes_pos_y[i] = volcano_ashes_pos_y[i] + volcano_ashes_speedy[i] * speed

		volcano_ashes_rot_x[i] = volcano_ashes_rot_x[i] + volcano_ashes_drot_x[i] * speed
		volcano_ashes_rot_y[i] = volcano_ashes_rot_y[i] + volcano_ashes_drot_y[i] * speed
		volcano_ashes_rot_z[i] = volcano_ashes_rot_z[i] + volcano_ashes_drot_z[i] * speed

		if (volcano_ashes_pos_z[i] < 0) then
			volcano_ashes_pos_z[i] = 11
		end
	end

	for i=0, 175 do
		volcano_lava_pos_x[i] = volcano_lava_pos_x[i] + volcano_lava_vel_x[i] * speed
		volcano_lava_pos_y[i] = volcano_lava_pos_y[i] + volcano_lava_vel_y[i] * speed
		volcano_lava_pos_z[i] = volcano_lava_pos_z[i] + volcano_lava_vel_z[i] * speed
		volcano_lava_vel_z[i] = volcano_lava_vel_z[i] - gravity * speed
		volcano_lava_alpha[i] = volcano_lava_alpha[i] - 0.05 * speed
		if (volcano_lava_alpha[i] < 0) then
			if (i % 3 == 0) then
				volcano_lava_pos_x[i] = math.random((120*math.cos(9)-2)*1000,(120*math.cos(9)+2)*1000)/1000
				volcano_lava_pos_y[i] = math.random((120*math.sin(9)-2)*1000,(120*math.sin(9)+2)*1000)/1000
			elseif (i % 3 == 1) then
				volcano_lava_pos_x[i] = math.random((120*math.cos(6)-2)*1000,(120*math.cos(6)+2)*1000)/1000
				volcano_lava_pos_y[i] = math.random((120*math.sin(6)-2)*1000,(120*math.sin(6)+2)*1000)/1000
			else
				volcano_lava_pos_x[i] = math.random((120*math.cos(8)-2)*1000,(120*math.cos(8)+2)*1000)/1000
				volcano_lava_pos_y[i] = math.random((120*math.sin(8)-2)*1000,(120*math.sin(8)+2)*1000)/1000
			end
			volcano_lava_pos_z[i] = math.random(250,400)/10
			volcano_lava_vel_x[i] = math.random(-50,50)/100
			volcano_lava_vel_y[i] = math.random(-50,50)/100
			volcano_lava_vel_z[i] = math.random(10,200)/100
			volcano_lava_rad[i] = math.random(400,600)/1000
			volcano_lava_alpha[i] = math.random(1,100)/100
		end
	end
end

-- initialize the small relief and the ashes :
for i=0, 50 do
	volcano_relief_pos_x[i] = math.random(-2100,2100)/100
	volcano_relief_pos_y[i] = math.random(-2100,2100)/100
	volcano_relief_rad[i] = math.random(100,200)/1000
	
	volcano_ashes_pos_x[i] = math.random(-2100,2100)/100
	volcano_ashes_pos_y[i] = math.random(-2100,2100)/100
	volcano_ashes_pos_z[i] = math.random(0,1100)/100
	volcano_ashes_speedx[i] = math.random(-2,2)/100
	volcano_ashes_speedy[i] = math.random(-2,2)/100
	volcano_ashes_speedz[i] = math.random(-3,-1)/100
	volcano_ashes_sizex[i] = math.random(5,10)/100
	volcano_ashes_sizey[i] = math.random(5,10)/100
	volcano_ashes_rot_x[i] = math.random(0,180)
	volcano_ashes_rot_y[i] = math.random(0,180)
	volcano_ashes_rot_z[i] = math.random(0,180)
	volcano_ashes_drot_x[i] = math.random(0,10)
	volcano_ashes_drot_y[i] = math.random(0,20)
	volcano_ashes_drot_z[i] = math.random(0,20)
end

for i=0, 175 do
	volcano_lava_pos_x[i] = math.random((120*math.cos(9)-2)*1000,(120*math.cos(9)+2)*1000)/1000
	volcano_lava_pos_y[i] = math.random((120*math.sin(9)-2)*1000,(120*math.sin(9)+2)*1000)/1000
	volcano_lava_pos_z[i] = math.random(250,400)/10
	volcano_lava_vel_x[i] = math.random(-50,50)/100
	volcano_lava_vel_y[i] = math.random(-50,50)/100
	volcano_lava_vel_z[i] = math.random(10,100)/100
	volcano_lava_rad[i] = math.random(400,600)/1000
	volcano_lava_alpha[i] = math.random(1,100)/100
end

return {
	onRender = atmo_volcano,
	onEnterFrame = atmo_volcano_enterframe
}