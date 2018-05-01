local width, height = get_window_size()
local BTN_UP = 1
local BTN_HOVER = 2
local BTN_DOWN = 3
local MOUSE_UP = 0
local MOUSE_DOWN = 1
local mouse_state = MOUSE_UP

local mod_rotation = {}
local rotation_current = 0
local time1 = os.time()

local time2
local settings_state = 0
local settings_wait = 1

local command = {}
local buttons = {}

function load_buttons()
	buttons.set = { x = width - 500, y = height - 40, w = 500, h = 40, state = BTN_UP }
	buttons.quit = { x = width - 42, y = height - 590, w = 32, h = 32, state = BTN_UP }
	buttons.minimize = { x = width - 74, y = height - 590, w = 32, h = 32, state = BTN_UP, current = false }
	buttons.add_mod = { x = width - 350, y = height - 175, w = 50, h = 25, state = BTN_UP }
	buttons.mod_remove = {}
	
	buttons.desc = { x = width - 490, y = height - 130, w = 420, h = 35, state = BTN_UP, current = "", active = false, mark = 1 }
	buttons.motd = { x = width - 490, y = height - 83, w = 420, h = 35, state = BTN_UP, current = "", active = false, mark = 1 }
	buttons.modfield = { x = width - 490, y = height - 175, w = 140, h = 25, state = BTN_UP, current = "", active = false, mark = 1 }
	buttons.minelo = { x = width - 205, y = height - 420, w = 50, h = 25, state = BTN_UP, current = nil, active = false, mark = 1 }
	buttons.maxelo = { x = width - 135, y = height - 420, w = 50, h = 25, state = BTN_UP, current = nil, active = false, mark = 1 }
	buttons.minqi = { x = width - 205, y = height - 525, w = 50, h = 25, state = BTN_UP, current = 0, active = false, mark = 1 }
	buttons.maxqi = { x = width - 135, y = height - 525, w = 50, h = 25, state = BTN_UP, current = 0, active = false, mark = 1 }
	buttons.static = { x = width - 280, y = height - 485, w = 25, h = 25, state = BTN_UP, current = -1, active = false, mark = 1 }
	buttons.defaulttc = { x = width - 150, y = height - 380, w = 140, h = 25, state = BTN_UP, current = 0, active = false, mark = 1 }
	buttons.maxclients = { x = width - 150, y = height - 350, w = 140, h = 25, state = BTN_UP, current = 25, active = false, mark = 1 }
	buttons.maxcontacts = { x = width - 150, y = height - 320, w = 140, h = 25, state = BTN_UP, current = 20, active = false, mark = 1 }
	buttons.istourney = { x = width - 280, y = height - 278, w = 25, h = 25, state = BTN_UP, current = -1, active = false, mark = 1 }
	buttons.knockoutprize = { x = width - 150, y = height - 235, w = 140, h = 25, state = BTN_UP, current = "", active = false, mark = 1 }
	buttons.knockoutinterval = { x = width - 150, y = height - 205, w = 140, h = 25, state = BTN_UP, current = "", active = false, mark = 1 }
	buttons.tourneyminplayers = { x = width - 150, y = height - 175, w = 140, h = 25, state = BTN_UP, current = "", active = false, mark = 1 }
	
end

function reload_mod_remove()
	for i = 1, #mod_rotation do
		local length = get_string_length(mod_rotation[i], FONTS.SMALL)
		buttons.mod_remove[i] = { x = width - 490 + length + 6, y = height - 545 + i * 25, w = 20, h = 20, state = BTN_UP }
	end
end
	
function set_settings()
	if (settings_wait == -1) then
		if (os.difftime(os.time(), time2) > 0) then
			settings_state = settings_state + 1
			settings_wait = -settings_wait
		end
		return 0
	elseif (settings_state <= #command) then
		--echo(command[settings_state])
		run_cmd(command[settings_state])
		settings_wait = -settings_wait
		time2 = os.time()
	else
		remove_hooks("set")
		settings_state = 0
	end
end

function get_settings()
	if (buttons.static.current == 1) then
		command = {	"set \nmode set dbconfig 1", "cp \nmode set autoop 0" }
	end
	if (rotation_current == 1) then
		command[#command + 1] = "cp \nset mod "..mod_rotation[1]
		if (buttons.static.current == 1) then
			command[#command + 1] = "cp \nmode set mod "..mod_rotation[1]
		end
	elseif (rotation_current > 1) then
		for i = 1, #mod_rotation do
			command[#command + 1] = "cp \nmodlist add "..mod_rotation[i]
		end
		if (buttons.static.current == 1) then
			command[#command + 1] = "cp \nmode set modlist"
			for i = 1, #mod_rotation do
				command[#command] = command[#command].." "..mod_rotation[i]
			end
		end
	end
	command[#command + 1] = "cp \nreset"
	command[#command + 1] = "cp \nminbelt "..buttons.minqi.current
	command[#command + 1] = "cp \nmaxbelt "..buttons.maxqi.current
	if (buttons.static.current == 1) then
		if (buttons.minelo.current ~= nil) then
			command[#command + 1] = "cp \nmode set minelo "..buttons.minelo.current
		end
		if (buttons.maxelo.current ~= nil) then
			command[#command + 1] = "cp \nmode set maxelo "..buttons.maxelo.current
		end
		command[#command + 1] = "cp \nmode set defaulttc "..buttons.defaulttc.current
		command[#command + 1] = "cp \nmode set maxclients "..buttons.maxclients.current
		command[#command + 1] = "cp \nmode set maxcontacts "..buttons.maxcontacts.current
	end
	command[#command + 1] = "cp \nmaxclients "..buttons.maxclients.current
	command[#command + 1] = "cp \nmaxcontacts "..buttons.maxcontacts.current
	if (buttons.istourney.current == 1) then
		if (buttons.static.current == 1) then
			if (buttons.knockoutprize.current ~= "") then
				command[#command + 1] = "cp \nmode set knockoutprize "..buttons.knockoutprize.current
			end
		end
		if (buttons.knockoutinterval.current ~= "") then
			command[#command + 1] = "cp \nknockoutinterval "..buttons.knockoutinterval.current
			if (buttons.static.current == 1) then
				command[#command + 1] = "cp \nmode set knockoutinterval "..buttons.knockoutinterval.current
			end
		end
		if (buttons.tourneyminplayers.current ~= "" and buttons.static.current == 1) then
			command[#command + 1] = "cp \nmode set tourneyminplayers "..buttons.tourneyminplayers.current
		end
		command[#command + 1] = "cp \nknockout on"
	end
	if (buttons.desc.current ~= "") then
		command[#command + 1] = "cp \ndesc "..buttons.desc.current
	end
	if (buttons.motd.current ~= "") then
		command[#command + 1] = "cp \nmotd "..buttons.motd.current
		if (buttons.static.current == 1) then
			command[#command + 1] = "cp \nmode set motd "..buttons.motd.current
		end
	end
	if (buttons.static.current == 1) then
		command[#command + 1] = "cp \nmode save"
	end
	settings_state = 1
	add_hook("draw2d", "set", set_settings)
end

function mouse_down(mouse_btn, x, y)
	mouse_state = MOUSE_DOWN
	
	if (x > buttons.set.x and x < (buttons.set.x + buttons.set.w) and (y > buttons.set.y) and y < (buttons.set.y + buttons.set.h)) then
		buttons.set.state = BTN_DOWN
	end
	
	if (x > buttons.add_mod.x and x < (buttons.add_mod.x + buttons.add_mod.w) and (y > buttons.add_mod.y) and y < (buttons.add_mod.y + buttons.add_mod.h)) then
		buttons.add_mod.state = BTN_DOWN
	end
		
	if (x > buttons.quit.x and x < (buttons.quit.x + buttons.quit.w) and (y > buttons.quit.y) and y < (buttons.quit.y + buttons.quit.h)) then
		buttons.quit.state = BTN_DOWN
	end
	
	if (x > buttons.minimize.x and x < (buttons.minimize.x + buttons.minimize.w) and (y > buttons.minimize.y) and y < (buttons.minimize.y + buttons.minimize.h)) then
		buttons.minimize.state = BTN_DOWN
	end
	
	for i = 1, #mod_rotation do
		if (x > buttons.mod_remove[i].x and x < (buttons.mod_remove[i].x + buttons.mod_remove[i].w) and (y > buttons.mod_remove[i].y) and y < (buttons.mod_remove[i].y + buttons.mod_remove[i].h)) then
			buttons.mod_remove[i].state = BTN_DOWN
		end
	end
	
end

function field_up(mouse_btn, x, y, field)
	if (x > field.x and x < (field.x + field.w) and (y > field.y) and y < (field.y + field.h)) then
		field.state = BTN_UP
		field.active = true
	else
		field.active = false
	end
end

function mouse_up(mouse_btn, x, y)
	mouse_state = MOUSE_UP
	
	if (buttons.minimize.current == false) then
		if (x > buttons.set.x and x < (buttons.set.x + buttons.set.w) and (y > buttons.set.y) and y < (buttons.set.y + buttons.set.h)) then
			buttons.set.state = BTN_UP
			if (settings_state == 0) then
				get_settings()
			else 
				remove_hooks("set")
				settings_state = 0
			end
		end
		
		if (x > buttons.add_mod.x and x < (buttons.add_mod.x + buttons.add_mod.w) and (y > buttons.add_mod.y) and y < (buttons.add_mod.y + buttons.add_mod.h)) then
			buttons.add_mod.state = BTN_UP
			if (buttons.modfield.current ~= "") then
				rotation_current = rotation_current + 1
				if not string.find(buttons.modfield.current, ".tbm") then
					buttons.modfield.current = buttons.modfield.current .. ".tbm"
				end
				mod_rotation[rotation_current] = buttons.modfield.current
				buttons.modfield.current = ""
			
				reload_mod_remove()
				
			end
		end
		
		field_up(mouse_btn, x, y, buttons.modfield)
		field_up(mouse_btn, x, y, buttons.minqi)
		field_up(mouse_btn, x, y, buttons.maxqi)
		if (buttons.static.current == 1) then
			field_up(mouse_btn, x, y, buttons.minelo)
			field_up(mouse_btn, x, y, buttons.maxelo)
			field_up(mouse_btn, x, y, buttons.defaulttc)
		end
		field_up(mouse_btn, x, y, buttons.maxclients)
		field_up(mouse_btn, x, y, buttons.maxcontacts)
		if (buttons.istourney.current == 1) then
			field_up(mouse_btn, x, y, buttons.knockoutprize)
			field_up(mouse_btn, x, y, buttons.knockoutinterval)
			field_up(mouse_btn, x, y, buttons.tourneyminplayers)
		end
		field_up(mouse_btn, x, y, buttons.desc)
		field_up(mouse_btn, x, y, buttons.motd)
		
		if (x > buttons.static.x and x < (buttons.static.x + buttons.static.w) and (y > buttons.static.y) and y < (buttons.static.y + buttons.static.h)) then
			buttons.static.current = -buttons.static.current
		end
		
		if (x > buttons.istourney.x and x < (buttons.istourney.x + buttons.istourney.w) and (y > buttons.istourney.y) and y < (buttons.istourney.y + buttons.istourney.h)) then
			buttons.istourney.current = -buttons.istourney.current
		end
				
		for i = 1, #mod_rotation do
			if (x > buttons.mod_remove[i].x and x < (buttons.mod_remove[i].x + buttons.mod_remove[i].w) and (y > buttons.mod_remove[i].y) and y < (buttons.mod_remove[i].y + buttons.mod_remove[i].h)) then
				buttons.mod_remove[i].state = BTN_UP
				for j = i, #mod_rotation do
					if (j < #mod_rotation) then
						mod_rotation[j] = mod_rotation[j + 1]
					else 
						mod_rotation[j] = nil
					end
				end
				reload_mod_remove()
				rotation_current = rotation_current - 1
			end
		end
	end
	
	if (x > buttons.quit.x and x < (buttons.quit.x + buttons.quit.w) and (y > buttons.quit.y) and y < (buttons.quit.y + buttons.quit.h)) then
		buttons.quit.state = BTN_UP
		remove_hooks("visuals")
		remove_hooks("mouse")
		remove_hooks("keyboard")
		remove_hooks("set")
	end
	
	if (x > buttons.minimize.x and x < (buttons.minimize.x + buttons.minimize.w) and (y > buttons.minimize.y) and y < (buttons.minimize.y + buttons.minimize.h)) then
		buttons.minimize.state = BTN_UP
		if (buttons.minimize.current == false) then
			buttons.minimize.current = true
			buttons.quit.y, buttons.minimize.y = height - 40, height - 40
		else 
			buttons.minimize.current = false
			buttons.quit.y, buttons.minimize.y = height - 590, height - 590
		end
	end
end

function mouse_move(x, y)	
	
	if (x > (buttons.set.x) and x < (buttons.set.x + buttons.set.w) and (y > buttons.set.y) and y < (buttons.set.y + buttons.set.h)) then
		if (mouse_state == MOUSE_DOWN) then
			buttons.set.state = BTN_DOWN
		else
			buttons.set.state = BTN_HOVER
		end
	else
		buttons.set.state = BTN_UP
	end
	
	if (x > (buttons.add_mod.x) and x < (buttons.add_mod.x + buttons.add_mod.w) and (y > buttons.add_mod.y) and y < (buttons.add_mod.y + buttons.add_mod.h)) then
		if (mouse_state == MOUSE_DOWN) then
			buttons.add_mod.state = BTN_DOWN
		else
			buttons.add_mod.state = BTN_HOVER
		end
	else
		buttons.add_mod.state = BTN_UP
	end
	
	if (x > (buttons.quit.x) and x < (buttons.quit.x + buttons.quit.w) and (y > buttons.quit.y) and y < (buttons.quit.y + buttons.quit.h)) then
		if (mouse_state == MOUSE_DOWN) then
			buttons.quit.state = BTN_DOWN
		else
			buttons.quit.state = BTN_HOVER
		end
	else
		buttons.quit.state = BTN_UP
	end
	
	if (x > (buttons.minimize.x) and x < (buttons.minimize.x + buttons.minimize.w) and (y > buttons.minimize.y) and y < (buttons.minimize.y + buttons.minimize.h)) then
		if (mouse_state == MOUSE_DOWN) then
			buttons.minimize.state = BTN_DOWN
		else
			buttons.minimize.state = BTN_HOVER
		end
	else
		buttons.minimize.state = BTN_UP
	end

	for i = 1, #mod_rotation do
		if (x > (buttons.mod_remove[i].x) and x < (buttons.mod_remove[i].x + buttons.mod_remove[i].w) and (y > buttons.mod_remove[i].y) and y < (buttons.mod_remove[i].y + buttons.mod_remove[i].h)) then
			if (mouse_state == MOUSE_DOWN) then
				buttons.mod_remove[i].state = BTN_DOWN
			else
				buttons.mod_remove[i].state = BTN_HOVER
			end
		else
			buttons.mod_remove[i].state = BTN_UP
		end
	end
end

function draw_elements(field, text)
	-- Enter mod field
	if (field ~= buttons.modfield and field ~= buttons.desc and field ~= buttons.motd) then
		local length = get_string_length(text, 1)
		set_color(0, 0, 0, 1)
		draw_text(text, width - 160 - length, field.y + 3, 1)
	end
	if (field == buttons.desc) then
		local length = get_string_length("desc", 2)
		set_color(0, 0, 0, 0.8)
		draw_right_text("desc", 35 - length / 2, field.y + 3, 2)
	end
	if (field == buttons.motd) then
		local length = get_string_length("motd", 2)
		set_color(0, 0, 0, 0.8)
		draw_right_text("motd", 35 - length / 2, field.y + 3, 2)
	end
	set_color(0, 0, 0, 0.5)
	draw_quad(field.x, field.y, field.w, field.h)
	if (field.current ~= "" or field.active == true) then
		set_color(1, 1, 1, 1)
		if (field == buttons.desc or field == buttons.motd) then
			draw_text(field.current, field.x + 10, field.y + 3, FONTS.MEDIUM)
		else
			draw_text(field.current, field.x + 10, field.y + 3, FONTS.SMALL)
		end
	else 
		set_color(1, 1, 1, 0.3)
		if (field == buttons.desc or field == buttons.motd) then
			draw_text(text, field.x + 10, field.y + 3, FONTS.MEDIUM)
		else
			draw_text(text, field.x + 10, field.y + 3, FONTS.SMALL)
		end
	end
	if (field.active == true) then
		local length 
		if (field == buttons.desc or field == buttons.motd) then
			length = get_string_length(field.current, FONTS.MEDIUM)
		else
			length = get_string_length(field.current, FONTS.SMALL)	
		end
		if (os.difftime(os.time(), time1) > 0) then
			field.mark = -field.mark
			time1 = os.time()
		end
		if (field.mark == 1) then
			if (field == buttons.desc or field == buttons.motd) then
				draw_text("|", field.x + 10 + length, field.y + 2, 4)
			else
				draw_text("|", field.x + 10 + length, field.y + 3, FONTS.SMALL)
			end
		end
	end
end

function visuals()
	if (buttons.minimize.current == false) then
		-- General UI
		set_color(0, 0, 0, 0.3)
		draw_quad(width - 500, height - 600, 500, 560)
		set_color(0, 0, 0, 0.5)
		draw_quad(width - 490, height - 590, 416, 32)
		set_color(0, 0, 0, 0.3)
		draw_quad(width - 291, height - 558, 2, 418)
		draw_quad(width - 289, height - 496, 289, 2)
		draw_quad(width - 289, height - 390, 289, 2)
		draw_quad(width - 289, height - 288, 289, 2)
		draw_quad(width - 500, height - 140, 500, 2)
		set_color(1, 1, 1, 1)
		draw_text("Erth's boys team server tools", width - 480, height - 586, FONTS.MEDIUM)
		
		-- draw similar fields
		draw_elements(buttons.modfield, "enter mod name")
		draw_elements(buttons.defaulttc, "defaulttc")
		draw_elements(buttons.maxclients, "maxclients")
		draw_elements(buttons.maxcontacts, "maxcontacts")
		draw_elements(buttons.knockoutprize, "ko prize")
		draw_elements(buttons.knockoutinterval, "ko interval")
		draw_elements(buttons.tourneyminplayers, "min players")
		draw_elements(buttons.desc, "room description")
		draw_elements(buttons.motd, "message of the day")
		
		-- draw ranked checkbox
		set_color(0, 0, 0, 0.5)
		draw_quad(buttons.static.x, buttons.static.y, buttons.static.w, buttons.static.h)
		if (buttons.static.current == 1) then 
			draw_quad(width - 289, height - 494, 289, 44)
			set_color(1, 1, 1, 1)
			draw_text("●", buttons.static.x + 5, buttons.static.y - 2, 4)
			set_color(1, 1, 1, 1)
		end
		draw_text("make static", buttons.static.x + 35, buttons.static.y, 2)
		
		
		-- draw tourney checkbox
		set_color(0, 0, 0, 0.5)
		draw_quad(buttons.istourney.x, buttons.istourney.y, buttons.istourney.w, buttons.istourney.h)
		if (buttons.istourney.current == 1) then 
			draw_quad(width - 289, height - 286, 289, 44)
			set_color(1, 1, 1, 1)
			draw_text("●", buttons.istourney.x + 5, buttons.istourney.y - 2, 4)
			set_color(1, 1, 1, 1)
		end
		draw_text("make tournament", buttons.istourney.x + 35, buttons.istourney.y, 2)
		
		-- ELO range
		set_color(0, 0, 0, 0.5)
		draw_quad(buttons.minelo.x, buttons.minelo.y, buttons.minelo.w, buttons.minelo.h)
		draw_quad(buttons.maxelo.x, buttons.maxelo.y, buttons.maxelo.w, buttons.maxelo.h)
		set_color(0, 0, 0, 0.8)
		local length = get_string_length("ELO range", 2)
		draw_text("ELO range", buttons.minelo.x + buttons.minelo.w + 10 - length / 2, height - 445, FONTS.MEDIUM)
		set_color(0, 0, 0, 1)
		draw_text("-", buttons.maxelo.x - 15, buttons.maxelo.y, 4)
		set_color(1, 1, 1, 1)
		
		if (buttons.minelo.current ~= nil) then
			local length = get_string_length(buttons.minelo.current, FONTS.SMALL)
			draw_text(buttons.minelo.current, buttons.minelo.x + buttons.minelo.w / 2 - length / 2, buttons.minelo.y + 3)
		end
		if (buttons.minelo.active == true) then
			local length = 0
			if (buttons.minelo.current ~= nil) then
				length = get_string_length(buttons.minelo.current, FONTS.SMALL)
			end
			if (os.difftime(os.time(), time1) > 0) then
				buttons.minelo.mark = -buttons.minelo.mark
				time1 = os.time()
			end
			if (buttons.minelo.mark == 1) then
				draw_text("|", buttons.minelo.x + buttons.minelo.w / 2 + length / 2, buttons.minelo.y + 3, FONTS.SMALL)
			end
		end
		
		if (buttons.maxelo.current ~= nil) then
			local length = get_string_length(buttons.maxelo.current, FONTS.SMALL)
			draw_text(buttons.maxelo.current, buttons.maxelo.x + buttons.maxelo.w / 2 - length / 2, buttons.maxelo.y + 3)
		end
		if (buttons.maxelo.active == true) then
			local length = 0
			if (buttons.maxelo.current ~= nil) then
				length = get_string_length(buttons.maxelo.current, FONTS.SMALL)
			end
			if (os.difftime(os.time(), time1) > 0) then
				buttons.maxelo.mark = -buttons.maxelo.mark
				time1 = os.time()
			end
			if (buttons.maxelo.mark == 1) then
				draw_text("|", buttons.maxelo.x + buttons.maxelo.w / 2 + length / 2, buttons.maxelo.y + 3, FONTS.SMALL)
			end
		end
		
		-- qi range
		set_color(0, 0, 0, 0.5)
		draw_quad(buttons.minqi.x, buttons.minqi.y, buttons.minqi.w, buttons.minqi.h)
		draw_quad(buttons.maxqi.x, buttons.maxqi.y, buttons.maxqi.w, buttons.maxqi.h)
		set_color(0, 0, 0, 0.8)
		local length = get_string_length("QI range", 2)
		draw_text("QI range", buttons.minqi.x + buttons.minqi.w + 10 - length / 2, height - 552, FONTS.MEDIUM)
		set_color(0, 0, 0, 1)
		draw_text("-", buttons.maxqi.x - 15, buttons.maxqi.y, 4)
		set_color(1, 1, 1, 1)
		
		if (buttons.minqi.current ~= nil) then
			local length = get_string_length(buttons.minqi.current, FONTS.SMALL)
			draw_text(buttons.minqi.current, buttons.minqi.x + buttons.minqi.w / 2 - length / 2, buttons.minqi.y + 3)
		end
		if (buttons.minqi.active == true) then
			local length = 0
			if (buttons.minqi.current ~= nil) then
				length = get_string_length(buttons.minqi.current, FONTS.SMALL)
			end
			if (os.difftime(os.time(), time1) > 0) then
				buttons.minqi.mark = -buttons.minqi.mark
				time1 = os.time()
			end
			if (buttons.minqi.mark == 1) then
				draw_text("|", buttons.minqi.x + buttons.minqi.w / 2 + length / 2, buttons.minqi.y + 3, FONTS.SMALL)
			end
		end
		
		if (buttons.maxqi.current ~= nil) then
			local length = get_string_length(buttons.maxqi.current, FONTS.SMALL)
			draw_text(buttons.maxqi.current, buttons.maxqi.x + buttons.maxqi.w / 2 - length / 2, buttons.maxqi.y + 3)
		end
		if (buttons.maxqi.active == true) then
			local length = 0
			if (buttons.maxqi.current ~= nil) then
				length = get_string_length(buttons.maxqi.current, FONTS.SMALL)
			end
			if (os.difftime(os.time(), time1) > 0) then
				buttons.maxqi.mark = -buttons.maxqi.mark
				time1 = os.time()
			end
			if (buttons.maxqi.mark == 1) then
				draw_text("|", buttons.maxqi.x + buttons.maxqi.w / 2 + length / 2, buttons.maxqi.y + 3, FONTS.SMALL)
			end
		end
		
		
		-- Display mod rotation
		set_color(0, 0, 0, 0.8)
		local modstring
		if (rotation_current == 0) then
			modstring = "Mod list empty"
		else
			modstring = "Mod list:"
		end
		local length = get_string_length(modstring, 2)
			draw_text(modstring, width - 390 - length / 2, height - 552, FONTS.MEDIUM)
		for i = 1, #mod_rotation do
			local length = get_string_length(mod_rotation[i], FONTS.SMALL)
			set_color(0, 0, 0, 0.4)
			draw_quad(width - 490, buttons.mod_remove[i].y, length + 6, 20)
			set_color((buttons.mod_remove[i].state / 3 - 0.3) * 2, 0, 0, 0.7)
			draw_quad(buttons.mod_remove[i].x, buttons.mod_remove[i].y, 20, 20)
			local length = get_string_length("X", 1)
			if (buttons.mod_remove[i].state == BTN_UP) then
				set_color(1, 1, 1, 1)
			else
				set_color(0, 0, 0, 1)
			end
			draw_text("X", buttons.mod_remove[i].x + 10 - length / 2, buttons.mod_remove[i].y + 2)
			set_color(1, 1, 1, 1)
			draw_text(mod_rotation[i], width - 487, buttons.mod_remove[i].y + 2, FONTS.SMALL)
		end
		
		-- Add mod button
		set_color(buttons.add_mod.state / 3, 0, 0, 0.4)
		draw_quad(buttons.add_mod.x, buttons.add_mod.y, buttons.add_mod.w, buttons.add_mod.h)
		local length = get_string_length("add", FONTS.SMALL)
		set_color(0, 0, 0, 1)
		draw_text("add", buttons.add_mod.x + buttons.add_mod.w / 2 - length / 2, buttons.add_mod.y + 4, FONTS.SMALL)
		
		-- Set button
		set_color(buttons.set.state / 3, 0, 0, 0.4)
		draw_quad(buttons.set.x, buttons.set.y, buttons.set.w, buttons.set.h)
		local set_text 
		if (settings_state == 0) then
			set_text = "set" 
		else 
			set_text = "room setup in progress, click to stop"
		end
		local length = get_string_length(set_text, FONTS.MEDIUM)
		set_color(0, 0, 0, 1)
		draw_text(set_text, buttons.set.x + buttons.set.w / 2 - length / 2, buttons.set.y + 9, FONTS.MEDIUM)
	end
	
	-- Quit button
	set_color((buttons.quit.state / 3 - 0.3) * 2, 0, 0, 0.7)
	draw_quad(buttons.quit.x, buttons.quit.y, buttons.quit.w, buttons.quit.h)
	if (buttons.quit.state == BTN_UP) then 
		set_color(1, 1, 1, 1)
	else
		set_color(0, 0, 0, 1)
	end
	local length = get_string_length("X", 4)
	draw_text("X", buttons.quit.x + buttons.quit.h / 2 - length / 2, buttons.quit.y + 3, 4)
	
	-- Minimize button
	set_color((buttons.minimize.state / 3 - 0.3) * 2, 0, 0, 0.7)
	draw_quad(buttons.minimize.x, buttons.minimize.y, buttons.minimize.w, buttons.minimize.h)
	if (buttons.minimize.state == BTN_UP) then 
		set_color(1, 1, 1, 1)
	else
		set_color(0, 0, 0, 1)
	end
	local length = get_string_length("-", 4)
	draw_text("-", buttons.minimize.x + buttons.minimize.h / 2 - length / 2, buttons.minimize.y + 3, 4)

end

function enter_numeric(field, key)
	if (field.active == true) then
		if (key == string.byte('\b')) then
			if (string.len(field.current) == 1) then
				field.current = ""
			else
				field.current = math.floor(field.current / 10)
			end
		elseif (tonumber(string.char(key)) > 9) then 
			return 1
		elseif (field.current ~= nil and field.current ~= "") then
			field.current = field.current * 10 + tonumber(string.char(key))
		else 
			field.current = string.char(key)
		end
	end
end

function enter_alpha(field, key)
	if (field.active == true) then
		if (key == string.byte('\b') and string.len(field.current) > 0) then
			local new_mod = string.sub(field.current, 1, string.len(field.current) - 1)
			field.current = new_mod
		elseif (key ~= string.byte('\b')) then
			if ((key == string.byte('-')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. "_"
			elseif ((key == string.byte('1')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. "!"
			elseif ((key == string.byte('2')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. "@"
			elseif ((key == string.byte('3')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. "#"
			elseif ((key == string.byte('4')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. "$"
			elseif ((key == string.byte('5')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. "%"
			elseif ((key == string.byte('6')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. "^"
			elseif ((key == string.byte('7')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. "&"
			elseif ((key == string.byte('8')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. "*"
			elseif ((key == string.byte('9')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. "("
			elseif ((key == string.byte('0')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. ")"
			elseif ((key == string.byte('=')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. "+"
			elseif ((key == string.byte('/')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. "?"
			elseif ((key == string.byte('\'')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. "\""
			elseif ((key == string.byte(';')) and (get_shift_key_state() > 0)) then
				field.current = field.current .. ":"
			elseif (key >= 97 and key <= 122 and (get_shift_key_state() > 0)) then
				field.current = field.current .. string.char(key - 32)
			else
				field.current = field.current .. string.char(key)
			end
		end
	end
end

local keyboard_enter = function(key)
	enter_alpha(buttons.modfield, key)
	enter_alpha(buttons.desc, key)
	enter_alpha(buttons.motd, key)
		
	enter_numeric(buttons.minelo, key)
	enter_numeric(buttons.maxelo, key)
	enter_numeric(buttons.minqi, key)
	enter_numeric(buttons.maxqi, key)
	enter_numeric(buttons.defaulttc, key)
	enter_numeric(buttons.maxclients, key)
	enter_numeric(buttons.maxcontacts, key)
	enter_numeric(buttons.knockoutprize, key)
	enter_numeric(buttons.knockoutinterval, key)
	enter_numeric(buttons.tourneyminplayers, key)
end

local keyboard_up = function(key)
	if (buttons.modfield.active == true
	or buttons.minelo.active == true 
	or buttons.maxelo.active == true 
	or buttons.minqi.active == true 
	or buttons.maxqi.active == true 
	or buttons.defaulttc.active == true 
	or buttons.maxclients.active == true 
	or buttons.maxcontacts.active == true 
	or buttons.knockoutprize.active == true 
	or buttons.knockoutinterval.active == true 
	or buttons.tourneyminplayers.active == true
	or buttons.desc.active == true
	or buttons.motd.active == true) then
		return 1
	end
end

function script_init()
	load_buttons()

	add_hook("draw2d", "visuals", visuals)
	add_hook("mouse_button_down", "mouse", mouse_down)
	add_hook("mouse_button_up", "mouse", mouse_up)
	add_hook("mouse_move", "mouse", mouse_move)
	add_hook("key_down", "keyboard", keyboard_enter)
	add_hook("key_up", "keyboard", keyboard_up)
end

script_init()