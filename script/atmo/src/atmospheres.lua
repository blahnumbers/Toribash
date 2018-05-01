-- (c) 2011 - Melmoth

local tb_w,tb_h = get_window_size()
local mouse_x = 0
local mouse_y = 0
local mouse_click = 0
local current_tab = 1
local record_mode = 0
local rnd_prefix
local tmp_opt_hud,tmp_opt_frate,tmp_opt_ffixed
local list_atmo = {}
local anim_state = 0
local anim_speed = 0
local selected_atmo = 1
local textureid_ui_mainframe
local textureid_ui_close
local textureid_ui_record
local textureid_ui_selected
local textureid_ui_stop_recording
local textureid_ui_tab1
local textureid_ui_tab2
local textureid_ui_tab3
local len_atmoblog = get_string_length("http://g.hssn.free.fr/atmospheres", 1)
local len_onlink = get_string_length("http://melmoth.on.toribash.com", 1)

local function atmo_sort(atmo1,atmo2)
	return string.lower(atmo1[1]) < string.lower(atmo2[1])
end

local function sign(n)
	if(n == 0) then
		return 0
	else
		return n/math.abs(n)
	end
end

local function m_modulo(x,y)
	while(x>y) do
		x = x-y
	end
	while(x<1) do
		x = x+y
	end
	return x
end

local function end_record()
	if(record_mode == 1) then
		set_option('hud',tmp_opt_hud)
		set_option('framerate',tmp_opt_frate)
		set_option('fixedframerate',tmp_opt_ffixed)
		record_mode = 0
	end
end

local function mouse_manager()
	mouse_click = 0
	if(mouse_x>tb_w/2+130 and mouse_x<tb_w/2+152 and mouse_y>98 and mouse_y<120) then
		remove_hook("draw2d","atmo_ui")
		remove_hook("mouse_button_down","atmo_ui")
		remove_hook("mouse_move","atmo_ui")
		unload_texture(textureid_ui_mainframe)
		unload_texture(textureid_ui_close)
		unload_texture(textureid_ui_record)
		unload_texture(textureid_ui_stop_recording)
		unload_texture(textureid_ui_tab1)
		unload_texture(textureid_ui_tab2)
		unload_texture(textureid_ui_tab3)
		unload_texture(textureid_ui_selected)
		
		if(record_mode == 1) then
			end_record()
		end
		return
	end
	if(mouse_x>tb_w/2-141 and mouse_x<tb_w/2-46 and mouse_y>145 and mouse_y<170) then
		current_tab = 1
		return
	end
	if(mouse_x>tb_w/2-46 and mouse_x<tb_w/2+49 and mouse_y>145 and mouse_y<170) then
		current_tab = 2
		return
	end
	if(mouse_x>tb_w/2+49 and mouse_x<tb_w/2+144 and mouse_y>145 and mouse_y<170) then
		current_tab = 3
		return
	end
	if(current_tab == 1) then
		if(mouse_x >= tb_w/2 - 60 and mouse_x <= tb_w/2 + 60) then
			remove_hook("draw3d","atmo")
			if(anim_state == 0) then
				run_cmd("lws " .. list_atmo[selected_atmo][4])
				dofile(list_atmo[selected_atmo][2])
			elseif(anim_speed > 0) then
				run_cmd("lws " .. list_atmo[selected_atmo - 1][4])
				dofile(list_atmo[selected_atmo - 1][2])
			else
				run_cmd("lws " .. list_atmo[selected_atmo + 1][4])
				dofile(list_atmo[selected_atmo + 1][2])
			end
		end
	elseif(current_tab == 2) then
		if(mouse_x>tb_w/2-55 and mouse_x<tb_w/2+55 and mouse_y>320 and mouse_y<345) then
			if (record_mode == 0) then
				tmp_opt_hud = get_option('hud')
				tmp_opt_frate = get_option('framerate')
				tmp_opt_ffixed = get_option('fixedframerate')	
				rnd_prefix = math.random(100,10000)
				set_option('hud',0)
				set_option('framerate',60)
				set_option('fixedframerate',1)
				record_mode = 1
				rewind_replay()
			else
				end_record()
			end
			return
		end	
	elseif(current_tab == 3) then
		if(mouse_x>tb_w/2-len_atmoblog/2 and mouse_x<tb_w/2+len_atmoblog/2 and mouse_y>245 and mouse_y<260) then
			open_url("http://g.hssn.free.fr/atmospheres")
			return
		end
		if(mouse_x>tb_w/2-len_onlink/2 and mouse_x<tb_w/2+len_onlink/2 and mouse_y>310 and mouse_y<325) then
			open_url("http://melmoth.on.toribash.com")
			return
		end
	end
end

local function atmo_draw_menu()
	if (record_mode == 1) then
		local mf = get_world_state().match_frame
		screenshot(string.format("%s_screenshot_%04i.bmp", rnd_prefix,mf), 0)
		if(mf == get_world_state().game_frame + 100) then
			end_record()
		end
	end
	set_color(1, 1, 1, 1)
    	draw_quad(tb_w/2-160, 90, 512, 512, textureid_ui_mainframe)
	if(mouse_x>tb_w/2+130 and mouse_x<tb_w/2+152 and mouse_y>98 and mouse_y<120) then
		set_color(1, 1, 1, 1)
	else
		set_color(0.6, 0.6, 0.6, 1)
	end
	draw_quad(tb_w/2+130, 98, 32, 32, textureid_ui_close)
	if(current_tab == 1) then
		set_color(0.5, 0.5, 0.5, 1)
		draw_quad(tb_w/2-46, 145, 128, 128, textureid_ui_tab2)
		draw_quad(tb_w/2+49, 145, 128, 128, textureid_ui_tab3)
		set_color(1, 1, 1, 1)
		draw_quad(tb_w/2-141, 145, 128, 128, textureid_ui_tab1)
		local nb_atmo = #list_atmo
		if(anim_state >= 20) then
			selected_atmo = m_modulo(selected_atmo - sign(anim_speed), nb_atmo)
			anim_state = 0
			anim_speed = 0
		end
		anim_state = anim_state + math.abs(anim_speed)
		if(anim_speed > 0) then
			set_color(1,1,1,anim_state/25)
			draw_quad(tb_w/2 - 145, 210, 80, 80, list_atmo[m_modulo(selected_atmo - 2, nb_atmo)][3])	
			set_color(1,1,1,0.8+anim_state/100)
			draw_quad(tb_w/2 - 145 + 4.25 * anim_state , 210 - anim_state, 80+2*anim_state, 80+2*anim_state, list_atmo[m_modulo(selected_atmo - 1, nb_atmo)][3])
			set_color(1,1,1,1-anim_state/100)
			draw_quad(tb_w/2 - 60 + 6.25 * anim_state , 190 + anim_state, 120-2*anim_state, 120-2*anim_state, list_atmo[selected_atmo][3])
			set_color(1,1,1,0.8-anim_state/25)
			draw_quad(tb_w/2 + 65, 210, 80, 80, list_atmo[m_modulo(selected_atmo + 1, nb_atmo)][3])			
		elseif(anim_speed < 0) then
			set_color(1,1,1,0.8-anim_state/25)	
			draw_quad(tb_w/2 - 145, 210, 80, 80, list_atmo[m_modulo(selected_atmo - 1, nb_atmo)][3])
			set_color(1,1,1,1-anim_state/100)
			draw_quad(tb_w/2 - 60 - 4.25 * anim_state , 190 + anim_state, 120-2*anim_state, 120-2*anim_state, list_atmo[selected_atmo][3])
			set_color(1,1,1,0.8+anim_state/100)
			draw_quad(tb_w/2 + 65 - 6.25 * anim_state , 210 - anim_state, 80+2*anim_state, 80+2*anim_state, list_atmo[m_modulo(selected_atmo + 1, nb_atmo)][3])
			set_color(1,1,1,anim_state/25)
			draw_quad(tb_w/2 + 65, 210, 80, 80, list_atmo[m_modulo(selected_atmo + 2, nb_atmo)][3])	
		else
			set_color(1,1,1,0.8)
			draw_quad(tb_w/2 - 145, 210, 80, 80, list_atmo[m_modulo(selected_atmo - 1, nb_atmo)][3])
			draw_quad(tb_w/2 + 65, 210, 80, 80, list_atmo[m_modulo(selected_atmo + 1, nb_atmo)][3])
			set_color(1,1,1,1)
			draw_quad(tb_w/2 - 60, 190, 120, 120, list_atmo[selected_atmo][3])			
		end
		if(anim_state == 0) then
			if(mouse_y < 310 and mouse_y > 190) then
				if(mouse_x >= tb_w/2 - 60 and mouse_x <= tb_w/2 + 60) then
					anim_speed = 0
					set_color(1, 1, 1, 1)
					draw_centered_text(list_atmo[selected_atmo][1], 320, 1)
					draw_quad(tb_w/2 - 62, 188, 124, 124, textureid_ui_selected)
				elseif(mouse_x >= tb_w/2 + 65 and mouse_x <= tb_w/2 + 160) then
					anim_speed = -0.8 - (mouse_x - tb_w/2 - 65)/75
				elseif(mouse_x >= tb_w/2 - 160 and mouse_x <= tb_w/2 - 65) then
					anim_speed = 0.8 - (mouse_x - tb_w/2 + 65)/75
				end
			end
		end
	elseif(current_tab == 2) then
		set_color(0.5, 0.5, 0.5, 1)
		draw_quad(tb_w/2-141, 145, 128, 128, textureid_ui_tab1)
		draw_quad(tb_w/2+49, 145, 128, 128, textureid_ui_tab3)
		set_color(1, 1, 1, 1)
		draw_quad(tb_w/2-46, 145, 128, 128, textureid_ui_tab2)
		draw_boxed_text("Load a replay and an atmosphere. Don't forget to set the keyframes before clicking the 'Start Recording' button. Don't close the Atmospheres window or the recording will stop ! You will find your pictures in the '/screenshots/' folder.", tb_w/2-141, 175, 285, 300, 14, 1)
		if(mouse_x>tb_w/2-55 and mouse_x<tb_w/2+55 and mouse_y>320 and mouse_y<345) then
			set_color(1, 1, 1, 1)
		else
			set_color(0.6, 0.6, 0.6, 1)
		end
		if (record_mode == 0) then
			draw_quad(tb_w/2-55, 320, 128, 128, textureid_ui_record)
		else
			draw_quad(tb_w/2-55, 320, 128, 128, textureid_ui_stop_recording)
		end
	elseif(current_tab == 3) then
		set_color(0.5, 0.5, 0.5, 1)
		draw_quad(tb_w/2-141, 145, 128, 128, textureid_ui_tab1)
		draw_quad(tb_w/2-46, 145, 128, 128, textureid_ui_tab2)
		set_color(1, 1, 1, 1)
		draw_quad(tb_w/2+49, 145, 128, 128, textureid_ui_tab3)
		draw_centered_text("Credits", 175, 2)
		draw_centered_text("(c) Melmoth 2011-" .. os.date("*t").year, 205, 1)
		draw_centered_text("Thanks : Kyat & the TB-fr community !", 225, 1)
		if(mouse_x>tb_w/2-len_atmoblog/2 and mouse_x<tb_w/2+len_atmoblog/2 and mouse_y>245 and mouse_y<260) then
			set_color(0.6, 0, 0, 1)
		else
			set_color(0.4, 0, 0, 1)
		end
		draw_centered_text("http://g.hssn.free.fr/atmospheres", 245, 1)
		set_color(1, 1, 1, 1)
		draw_centered_text("Donate", 280, 2)
		if(mouse_x>tb_w/2-len_onlink/2 and mouse_x<tb_w/2+len_onlink/2 and mouse_y>310 and mouse_y<325) then
			set_color(0.6, 0, 0, 1)
		else
			set_color(0.4, 0, 0, 1)
		end
		draw_centered_text("http://melmoth.on.toribash.com", 310, 1)
	end
	if(mouse_click == 1) then
		mouse_manager()
	end	
end

local function atmo_mouse_down(btn,x,y)
	mouse_click = 1
	return 1
end

local function atmo_mouse_move(x,y)
	if(x ~= nil) then
		mouse_x = x
	end
	if(y ~= nil) then	
		mouse_y = y	
	end
end
--[[
			tb_w,tb_h = get_window_size()
			textureid_ui_mainframe = load_texture("atmo/ui/mainframe.tga")
			textureid_ui_close = load_texture("atmo/ui/close.tga")
			textureid_ui_record = load_texture("atmo/ui/record.tga")
			textureid_ui_stop_recording = load_texture("atmo/ui/stoprecording.tga")
			textureid_ui_tab1 = load_texture("atmo/ui/tab1.tga")
			textureid_ui_tab2 = load_texture("atmo/ui/tab2.tga")
			textureid_ui_tab3 = load_texture("atmo/ui/tab3.tga")
			textureid_ui_selected = load_texture("atmo/ui/select.tga")
			list_atmo = { }
			anim_state = 0
			anim_speed = 0
			local tmp_folders = get_files("data/script/atmo/atmospheres","")
			for i = 1, #tmp_folders do
				if(tmp_folders[i] ~= "." and tmp_folders[i] ~= "..") then
					local test_file = io.open("data/script/atmo/atmospheres/" .. tmp_folders[i] .. "/atmo.lua", "r", 1)
					if(test_file ~= nil) then
						test_file:close()
						local atmo_name = tmp_folders[i]
						local atmo_lua_path = "atmo/atmospheres/" .. tmp_folders[i] .. "/atmo.lua"
						local atmo_thumb_path
						local atmo_shaders_path
						test_file = io.open("data/script/atmo/atmospheres/" .. tmp_folders[i] .. "/thumb.tga", "r", 1)
						if(test_file ~= nil) then
							test_file:close()
							atmo_thumb_path = "atmo/atmospheres/" .. tmp_folders[i] .. "/thumb.tga"
						else
							atmo_thumb_path = "atmo/ui/nothumb.tga"
						end
						test_file = io.open("data/script/atmo/atmospheres/" .. tmp_folders[i] .. "/shader.inc", "r", 1)
						if(test_file ~= nil) then
							test_file:close()
							atmo_shaders_path = "../script/atmo/atmospheres/" .. tmp_folders[i] .. "/shader.inc"
						else
							atmo_shaders_path = "../script/atmo/src/default_shader.inc"
						end
						table.insert(list_atmo,{atmo_name,atmo_lua_path,load_texture(atmo_thumb_path),atmo_shaders_path})
					end
				end
			end
			table.sort(list_atmo,atmo_sort)
			if(#list_atmo == 0) then
				echo("Error : no atmosphere found.")
			else
				add_hook("draw2d", "atmo_ui", atmo_draw_menu)
				add_hook("mouse_button_down","atmo_ui", atmo_mouse_down)
				add_hook("mouse_move","atmo_ui", atmo_mouse_move)
			end]]