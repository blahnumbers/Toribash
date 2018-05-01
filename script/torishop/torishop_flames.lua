dofile ("gui/image.lua")

-- Global
local width, height = get_window_size()
local options = { backgroundclick = 0, name = 0, timer = 0, uke = 0, score = 0, hint = 0, feedback = 0, text = 0, chat = 0, blood = 0, bruise = 0}

local items_per_shelf = math.floor(math.floor((height-290)/140)*2)

local first = true
local change_section_first = true
local current_shelf = 1
local total_shelves = 0

local confirm_name = nil
local confirm_id = nil

local data_types = { "catid", "catname", "itemid", "itemname", "on_sale", "now_tc_price", "now_usd_price", "price", "price_usd", "sale_time", "sale_promotion", "qi", "tier", "subscriptionid", "ingame", "colorid", "hidden", "locked" }
local data_table = {}
local data_table_lines = 0
local data_exists = false

local player_name = get_master().master.nick
local items = 0

local icon = {}
local pos_icon = {}

local preview_flames = 1
local details_flameid = {0, 0, 0, 0, 0, 0}
local details_flamename = {0, 0, 0, 0, 0, 0}
local effects_option = get_option("effects")

local BTN_UP = 1
local BTN_HOVER = 2
local BTN_DOWN = 3

local flameflag = 0

local tempinfo = { force = 0, relax = 0, primary = 0, secondary = 0, torso = 0, blood = 0, ghost = 0, rhmt = 0, lhmt = 0, rlmt = 0, llmt = 0, dq = 0, grip = 0, timer = 0, text = 0, emote = 0, hair = 0 }
local tempflag = 0

local texture_sleepy = false
local texture_rain = false

local preview_max = 5

function draw_grip()
	local grip_info = set_grip_info(0,11,1)
	local right_hand = get_body_info(0, BODYPARTS.R_HAND)
	get_colors(grip_color)
	set_color(color_r, color_g, color_b, 0.7)
	draw_sphere(right_hand.pos.x-0.12, right_hand.pos.y-0.07, right_hand.pos.z+0.02, 0.08)
end

function load_user()
	local temp = io.open("torishop/flames.cfg", "r")
	if temp == nil then return 0 end
	for ln in temp:lines() do
		if (string.match(ln, "temp") or string.match(ln, "s")) then
		else
			tempinfo.force, tempinfo.relax, tempinfo.primary, tempinfo.secondary, tempinfo.torso, tempinfo.blood, tempinfo.ghost, tempinfo.rhmt, tempinfo.lhmt, tempinfo.rlmt, tempinfo.llmt, tempinfo.dq, tempinfo.grip, tempinfo.timer, tempinfo.text, tempinfo.emote, tempinfo.hair = ln:match("([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+)")
		end
	end
	temp:close()
end

function update_customs()
	if (tempinfo.force ~= "0" and tempinfo.force ~= 0) then set_joint_replay_color(0, tempinfo.force) end
	if (tempinfo.relax ~= "0" and tempinfo.relax ~= 0) then set_joint_relax_color(0, tempinfo.relax) end
	if (tempinfo.primary ~= "0" and tempinfo.primary ~= 0) then set_gradient_primary_color(0, tempinfo.primary) end
	if (tempinfo.secondary ~= "0" and tempinfo.secondary ~= 0) then set_gradient_secondary_color(0, tempinfo.secondary) end
	if (tempinfo.torso ~= "0" and tempinfo.torso ~= 0) then set_torso_color(0, tempinfo.torso) end
	if (tempinfo.blood ~= "0" and tempinfo.blood ~= 0) then set_blood_color(0, tempinfo.blood) end
	if (tempinfo.ghost ~= "0" and tempinfo.ghost ~= 0) then set_ghost_color(0, tempinfo.ghost) end
	if (tempinfo.lhmt ~= "0" and tempinfo.lhmt ~= 0) then set_separate_trail_color(0, 0, tempinfo.lhmt) end
	if (tempinfo.rhmt ~= "0" and tempinfo.rhmt ~= 0) then set_separate_trail_color(0, 1, tempinfo.rhmt) end
	if (tempinfo.llmt ~= "0" and tempinfo.llmt ~= 0) then set_separate_trail_color(0, 2, tempinfo.llmt) end
	if (tempinfo.rlmt ~= "0" and tempinfo.rlmt ~= 0) then set_separate_trail_color(0, 3, tempinfo.rlmt) end
	if (tempinfo.hair ~= "0" and tempinfo.hair ~= 0) then set_hair_color(0, tempinfo.hair) end
end

function load_data()
	local file = io.open("torishop/torishop.txt")
	if (file == nil) then
		return
 	end

	for i, v in ipairs(data_types) do
		data_table[v] = {}
	end

	local current_line = 0
	for ln in file:lines() do
		if string.match(ln, "^PRODUCT") then
			segments = 19
			local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }	-- split a tab separated string into an array
			if (data_stream[2] == "80" and string.find(data_stream[5], "Flame:") and data_stream[19] == "0") then
				data_stream[5] = string.gsub(data_stream[5], "Flame: ", "")
				current_line = current_line + 1
				for i, v in ipairs(data_types) do
					data_table[v][current_line] = data_stream[i + 1]
				end
			end
		end
	end
	file:close()
	
	if (current_line > 0) then
		data_table_lines = current_line
		data_exists = true
	end
end

local flames = {}
flames.total_items = 0
flames.selected_index = 1

function load_items()
	for line = 1, data_table_lines do
		local num = flames.total_items + 1
		flames[num] = {}
		flames[num].id = data_table.itemid[line]
		flames[num].name = data_table.itemname[line]
		flames[num].price_usd = data_table.price_usd[line]
		flames[num].flameid = data_table.colorid[line]
		if (flames[num].flameid == "4613") then
			flames[num].flameid = "4613 4614"
		end
		--echo(data_table.itemid[line].." "..data_table.itemname[line].." "..data_table.price_usd[line].." "..data_table.colorid[line])
		flames.total_items = num
		line = line + 1
	end
	
	total_shelves = math.ceil(flames.total_items/items_per_shelf)
end

local button_click_radius = 9
local buttons = {}

function load_buttons()
	-- Arrow-type buttons
	buttons.arrows = {}
	buttons.arrows.prev_shelf = { x = 25, y = height-((height-200)/2), angle = 270, state = BTN_UP }
	buttons.arrows.next_shelf = { x = 465, y = height-((height-200)/2), angle = 90, state = BTN_UP }
	
	-- Text-type buttons
	if (main_page == false) then main_y = 10 else main_y = height-30 end
	buttons.torishop = { x = 162, y = main_y, w = 165, h = 20, state = BTN_UP }
	buttons.tomain = { x = 340, y = 20, w = 116, h = 20, state = BTN_UP }
	
	buttons.buysteam = { x = 30, y = 160, w = 128, h = 38, state = BTN_UP }
	buttons.preview = { x = 180, y = 160, w = 128, h = 38, state = BTN_UP }
	buttons.multipreview = { x = 330, y = 160, w = 128, h = 38, state = BTN_UP }
	
	for i = 1, items_per_shelf do
		buttons[i] = {}
		buttons.confirm = { x = width/2 - 105, y = height/2 - 10, w = 230, h = 20, state = BTN_UP }
		buttons.cancel = { x = width/2 - 40, y = height/2 + 20, w = 80, h = 20, state = BTN_UP }
	end
end


function change_shelf(num)
	current_shelf = current_shelf + num
	if (current_shelf < 1) then
		current_shelf = total_shelves
	elseif (current_shelf > total_shelves) then
		current_shelf = 1
	end
end

function select_color(r1, g1, b1, a1, marked, r2, g2, b2, a2)
	if (marked == true) then
		set_color(r2, g2, b2, a2)
	else
		set_color(r1, g1, b1, a1)
	end
end

function select_color_links(state)
	if (state == BTN_UP) then
		set_color(1, 1, 1, 1)
	elseif (state == BTN_DOWN) then
		set_color(0.16,0.66,0.86,1)
	else
		set_color(0.82, 0.39, 0.39, 1.0)
	end
end

function clear_icons()
	for k = 1, items_per_shelf do
		pos_icon[k] = nil
		if (icon[k]) then unload_texture(icon[k]) end
	end
	clear_ss_icons()
end

function preview_flame()
	update_customs()
	
	if (flameflag == 0) then
		remove_hooks("quit")
		flameflag = 1
	elseif (flameflag == 1) then
		local flamelaunch = "loadflame 0"
		unfreeze_game()
		run_cmd("loadreplay system/torishop_flames.rpl")
		run_cmd("loadreplay system/torishop_flames.rpl") -- run command twice to force update game frames
		run_cmd("lp 0"..player_name)
		for i = 1, preview_flames do
			flamelaunch = flamelaunch .. " " .. details_flameid[i]
		end
		run_cmd(flamelaunch)
		flameflag = 2
	elseif (flameflag == 2) then
		add_hook("leave_game", "quit", close_torishop)
		if (texture_sleepy) then
			set_flame_texture(0, "data/script/torishop/flames", "sleepy")
		end
		if (texture_rain) then
			set_flame_texture(0, "data/script/torishop/flames", "rain")
		end
		flameflag = 3
	elseif (flameflag == 3) then
		if (get_world_state().match_frame > get_world_state().game_frame - 10) then
			freeze_game()
			flameflag = 0
			remove_hooks("flamepreview")
		end
	end
end	

local MOUSE_UP = 0
local MOUSE_DOWN = 1
local mouse_state = MOUSE_UP

function mouse_down(mouse_btn, x, y)
	mouse_state = MOUSE_DOWN
	
	if (x > buttons.torishop.x and x < (buttons.torishop.x + buttons.torishop.w) and y > buttons.torishop.y and y < (buttons.torishop.y + buttons.torishop.h)) then
		buttons.torishop.state = BTN_DOWN
	end
	if (x > buttons.tomain.x and x < (buttons.tomain.x + buttons.tomain.w) and y > buttons.tomain.y and y < (buttons.tomain.y + buttons.tomain.h)) then
		buttons.tomain.state = BTN_DOWN
	end		
	
	local r = button_click_radius
	for i, v in pairs(buttons.arrows) do
		if (x > (v.x - r) and x < (v.x + r) and y > (v.y - r) and y < (v.y + r)) then
			v.state = BTN_DOWN
		end
	end
	
	for i = 1, items_per_shelf do
		if (x > buttons[i].icon.x and x < (buttons[i].icon.x + buttons[i].icon.w) and y > buttons[i].icon.y and y < (buttons[i].icon.y + buttons[i].icon.h)) then
			buttons[i].icon.state = BTN_DOWN
		end
		if (x > buttons.buysteam.x and x < (buttons.buysteam.x + buttons.buysteam.w) and y > buttons.buysteam.y and y < (buttons.buysteam.y + buttons.buysteam.h)) then
			buttons.buysteam.state = BTN_DOWN
		end
		if (x > buttons.preview.x and x < (buttons.preview.x + buttons.preview.w) and y > buttons.preview.y and y < (buttons.preview.y + buttons.preview.h)) then
			buttons.preview.state = BTN_DOWN
		end
		if (x > buttons.multipreview.x and x < (buttons.multipreview.x + buttons.multipreview.w) and y > buttons.multipreview.y and y < (buttons.multipreview.y + buttons.multipreview.h)) then
			buttons.multipreview.state = BTN_DOWN
		end
	end
end

function mouse_up(mouse_btn, x, y)
	mouse_state = MOUSE_UP	
	
	if (x > buttons.torishop.x and x < (buttons.torishop.x + buttons.torishop.w) and y > buttons.torishop.y and y < (buttons.torishop.y + buttons.torishop.h)) then
		buttons.torishop.state = BTN_HOVER
	--	open_url("http://www.toribash.com/forum/tori_inventory.php")  -- NON-STEAM
		run_cmd("it")                                           	  -- STEAM
	end
	
	if (x > buttons.tomain.x and x < (buttons.tomain.x + buttons.tomain.w) and y > buttons.tomain.y and y < (buttons.tomain.y + buttons.tomain.h)) then
		buttons.tomain.state = BTN_HOVER
		tempflag = 1
		close_torishop()
		open_menu(12)
	end
	
	local r = button_click_radius
	for i, v in pairs(buttons.arrows) do
		if (x > (v.x - r) and x < (v.x + r) and y > (v.y - r) and y < (v.y + r)) then
			v.state = BTN_HOVER
			if (v == buttons.arrows.prev_shelf) then
				change_shelf(-1)
				clear_icons()
			elseif (v == buttons.arrows.next_shelf) then
				change_shelf(1)
				clear_icons()
			end
		end
	end
	
	if (current_shelf <= total_shelves) then
		for i = 1, items_per_shelf do
			local item_index = i + (current_shelf - 1)*items_per_shelf
			if (item_index > #flames) then
                break
            end
			if (x > buttons[i].icon.x and x < (buttons[i].icon.x + buttons[i].icon.w) and y > buttons[i].icon.y and y < (buttons[i].icon.y + buttons[i].icon.h)) then
				buttons[i].icon.state = BTN_HOVER
				details_name = flames[item_index].name
				details_price_usd = flames[item_index].price_usd
				details_id = flames[item_index].id
				flames.selected_index = item_index
				details_flameid[6] = flames[item_index].flameid
				details_flamename[6] = flames[item_index].name
			end
		end
	end
		
		if (x > buttons.buysteam.x and x < (buttons.buysteam.x + buttons.buysteam.w) and y > buttons.buysteam.y and y < (buttons.buysteam.y + buttons.buysteam.h)) then
			buttons.buysteam.state = BTN_HOVER
			run_cmd("steam purchase "..details_id)	
		end
		if (x > buttons.preview.x and x < (buttons.preview.x + buttons.preview.w) and y > buttons.preview.y and y < (buttons.preview.y + buttons.preview.h)) then
			buttons.preview.state = BTN_HOVER
		remove_hooks("flamepreview")
		flameflag = 0
		preview_flames = 1
		preview_max = 5
		details_flameid[preview_flames] = details_flameid[6]
		details_flamename[preview_flames] = details_flamename[6]
		if (details_flameid[6] == "4613 4614") then
			preview_max = preview_max - 1
		end
		if (details_name == "Sleepy") then
			texture_sleepy = true
		elseif (details_name == "Rain") then
			texture_rain = true
		else
			texture_sleepy = false
			texture_rain = false
		end
		add_hook("draw2d", "flamepreview", preview_flame)
		end
		if (x > buttons.multipreview.x and x < (buttons.multipreview.x + buttons.multipreview.w) and y > buttons.multipreview.y and y < (buttons.multipreview.y + buttons.multipreview.h)) then
			buttons.multipreview.state = BTN_HOVER
		remove_hooks("flamepreview")
		local skip = false
		flameflag = 0
		if (details_flameid[6] == "4613 4614") then
			preview_max = preview_max - 1
			if (preview_flames == preview_max) then 
				skip = true
			end
		end
		if (preview_flames < preview_max) then
			if (details_flameid[1] ~= 0) then
				preview_flames = preview_flames + 1
			end
			details_flameid[preview_flames] = details_flameid[6]
			details_flamename[preview_flames] = details_flamename[6]
			if (details_name == "Sleepy") then
				texture_sleepy = true
			elseif (details_name == "Rain") then
				texture_rain = true
			end
		end
		if (skip == true) then
			preview_max = preview_max + 1
			skip = false
		end
		add_hook("draw2d", "flamepreview", preview_flame)
		end
end

function mouse_move(x, y)
	if (x > buttons.torishop.x and x < (buttons.torishop.x + buttons.torishop.w) and y > buttons.torishop.y and y < (buttons.torishop.y + buttons.torishop.h)) then
		if (mouse_state == MOUSE_DOWN) then
			buttons.torishop.state = BTN_DOWN
		else
			buttons.torishop.state = BTN_HOVER
		end
	else
		buttons.torishop.state = BTN_UP
	end
	if (x > buttons.tomain.x and x < (buttons.tomain.x + buttons.tomain.w) and y > buttons.tomain.y and y < (buttons.tomain.y + buttons.tomain.h)) then
		if (mouse_state == MOUSE_DOWN) then
			buttons.tomain.state = BTN_DOWN
		else
			buttons.tomain.state = BTN_HOVER
		end
	else
		buttons.tomain.state = BTN_UP
	end
	
	local r = button_click_radius
	for i, v in pairs(buttons.arrows) do
		if (x > (v.x - r) and x < (v.x + r) and y > (v.y - r) and y < (v.y + r)) then
			if (mouse_state == MOUSE_DOWN) then
				v.state = BTN_DOWN
			else
				v.state = BTN_HOVER
			end
		else
			v.state = BTN_UP
		end
	end
	
	for i = 1, items_per_shelf do
		if (x > buttons[i].icon.x and x < (buttons[i].icon.x + buttons[i].icon.w) and y > buttons[i].icon.y and y < (buttons[i].icon.y + buttons[i].icon.h)) then
			if (mouse_state == MOUSE_DOWN) then
				buttons[i].icon.state = BTN_DOWN
			else
				buttons[i].icon.state = BTN_HOVER
			end
		else
			buttons[i].icon.state = BTN_UP
		end
		if (x > buttons.buysteam.x and x < (buttons.buysteam.x + buttons.buysteam.w) and y > buttons.buysteam.y and y < (buttons.buysteam.y + buttons.buysteam.h)) then
			if (mouse_state == MOUSE_DOWN) then
				buttons.buysteam.state = BTN_DOWN
			else
				buttons.buysteam.state = BTN_HOVER
			end
		else
			buttons.buysteam.state = BTN_UP
		end
		if (x > buttons.preview.x and x < (buttons.preview.x + buttons.preview.w) and y > buttons.preview.y and y < (buttons.preview.y + buttons.preview.h)) then
			if (mouse_state == MOUSE_DOWN) then
				buttons.preview.state = BTN_DOWN
			else
				buttons.preview.state = BTN_HOVER
			end
		else
			buttons.preview.state = BTN_UP
		end
		if (x > buttons.multipreview.x and x < (buttons.multipreview.x + buttons.multipreview.w) and y > buttons.multipreview.y and y < (buttons.multipreview.y + buttons.multipreview.h)) then
			if (mouse_state == MOUSE_DOWN) then
				buttons.multipreview.state = BTN_DOWN
			else
				buttons.multipreview.state = BTN_HOVER
			end
		else
			buttons.multipreview.state = BTN_UP
		end
	end
end

function key_down(key)
	if (key) then
		return 1
	end
end
function key_up(key)
	if (key) then
		return 1
	end
end

function draw_flame(item, pos, marked, flag)	-- the section the item is from, the item index in the section, the shelf position, whether it is selected
	local name = flames[item].name
		
	-- Flame Icons	
	if (pos == 1) then
		w_shelf = 64
		h_shelf = 250
	end
	if (w_shelf + 180 > 490) then 
		w_shelf = 64
		h_shelf = h_shelf + 140
	end
	if (h_shelf + 130 > height) then
		h_shelf = 250
	end
	
	buttons[pos].icon = { x = w_shelf, y = h_shelf, w = 164, h = 114, state = BTN_UP }
	select_color(1,1,1,0.4,marked,0,0,0,0.4)
	if (buttons[pos].icon.state == BTN_UP) then
		draw_disk(buttons[pos].icon.x+20, buttons[pos].icon.y+20, 0, 30, 500, 1, -180, 90, 0)
		draw_disk(buttons[pos].icon.x+20, buttons[pos].icon.y+94, 0, 30, 500, 1, -90, 90, 0)
		draw_disk(buttons[pos].icon.x+144, buttons[pos].icon.y+20, 0, 30, 500, 1, 90, 90, 0)
		draw_disk(buttons[pos].icon.x+144, buttons[pos].icon.y+94, 0, 30, 500, 1, 0, 90, 0)
		draw_quad(buttons[pos].icon.x-10, buttons[pos].icon.y+20, 184, 74)
		draw_quad(buttons[pos].icon.x+20, buttons[pos].icon.y-10, 124, 30)
		draw_quad(buttons[pos].icon.x+20, buttons[pos].icon.y+94, 124, 30) end
	set_color(1,1,1,1)
		draw_disk(buttons[pos].icon.x+20, buttons[pos].icon.y+20, 0, 26, 500, 1, -180, 90, 0)
		draw_disk(buttons[pos].icon.x+20, buttons[pos].icon.y+94, 0, 26, 500, 1, -90, 90, 0)
		draw_disk(buttons[pos].icon.x+144, buttons[pos].icon.y+20, 0, 26, 500, 1, 90, 90, 0)
		draw_disk(buttons[pos].icon.x+144, buttons[pos].icon.y+94, 0, 26, 500, 1, 0, 90, 0)
		draw_quad(buttons[pos].icon.x-6, buttons[pos].icon.y+20, 176, 74)
		draw_quad(buttons[pos].icon.x+20, buttons[pos].icon.y-6, 124, 26)
		draw_quad(buttons[pos].icon.x+20, buttons[pos].icon.y+94, 124, 26)
	if (pos_icon[pos] == nil) then
		icon[pos] = load_texture("/torishop/icons/"..name..".tga")
		pos_icon[pos] = 1 
	end
	draw_quad(buttons[pos].icon.x - 6, buttons[pos].icon.y - 6, 256, 256, icon[pos])
	w_shelf = w_shelf + 200
end

function draw_shelf()

	set_color(1,1,1,1)
	draw_text("Hi, "..player_name.."!", 20, 20, FONTS.MEDIUM)
	
	-- Draw items on the shelf
	-- an awful hack to make purchase buttons work on few items
	if (first == true) then
	local i = 1
	repeat
		local item_index = i + (current_shelf - 1)*items_per_shelf
		if (item_index > flames.total_items) then
			break
		end
		local selected = false
		if (item_index == flames.selected_index) then
			selected = true
		end
			draw_flame(item_index, i, selected, 1)
		i = i + 1
	until (i > items_per_shelf)
	first = false
	clear_icons()
	end
	-- end of hack
	
	for i = 1, items_per_shelf do
	local item_index = i + (current_shelf - 1)*items_per_shelf
		if (item_index > flames.total_items) then
			break
		end
		local selected = false
		if (item_index == flames.selected_index) then
			selected = true
		end
		draw_flame(item_index, i, selected, 1)
	end
	set_color(1,1,1,1)
	
	if (change_section_first == true) then
		details_name = flames[1].name
		details_price_usd = flames[1].price_usd
		details_id = flames[1].id
		change_section_first = false
	end
	
	if (total_shelves > 9) then 
	if (current_shelf > 19) then
	draw_text("Page:  " .. current_shelf .. " of " .. total_shelves, 167, height-55, FONTS.MEDIUM)
	elseif (current_shelf > 9) then
	draw_text("Page:  " .. current_shelf .. " of " .. total_shelves, 169, height-55, FONTS.MEDIUM)
	else
	draw_text("Page:  " .. current_shelf .. " of " .. total_shelves, 175, height-55, FONTS.MEDIUM)
	end
	else
	draw_text("Page:  " .. current_shelf .. " of " .. total_shelves, 181, height-55, FONTS.MEDIUM)
	end
	
	set_color(0,0,0,0.2)
	draw_quad(10,70,470,150)
	set_color(0,0,0,1)
	draw_quad(9,70,1,150)
	draw_quad(480,70,1,150)
	draw_quad(9,69,472,1)
	draw_quad(9,220,472,1)
	
	
	set_color(1,1,1,1)
	draw_text_angle_scale(details_name, 30, 80, 0, 0.6, FONTS.BIG)
	draw_text_angle_scale(details_name, 30, 80, 0, 0.6, FONTS.BIG)
	if (buttons.buysteam.state == BTN_UP) then
	purchase_button = load_texture("torishop/gui/buysteam.tga")
	elseif (buttons.buysteam.state == BTN_HOVER) then
	purchase_button = load_texture("torishop/gui/buysteam_hvr.tga")
	else
	purchase_button = load_texture("torishop/gui/buysteam_dn.tga")
	end
	draw_quad(buttons.buysteam.x, buttons.buysteam.y, 128, 128, purchase_button)
	
	if (buttons.preview.state == BTN_UP) then
	purchase_button = load_texture("torishop/gui/flamepreview.tga")
	elseif (buttons.preview.state == BTN_HOVER) then
	purchase_button = load_texture("torishop/gui/flamepreview_hvr.tga")
	else
	purchase_button = load_texture("torishop/gui/flamepreview_dn.tga")
	end
	draw_quad(buttons.preview.x, buttons.preview.y, 128, 128, purchase_button)
	
	if (buttons.multipreview.state == BTN_UP) then
	purchase_button = load_texture("torishop/gui/flamemultipreview.tga")
	elseif (buttons.multipreview.state == BTN_HOVER) then
	purchase_button = load_texture("torishop/gui/flamemultipreview_hvr.tga")
	else
	purchase_button = load_texture("torishop/gui/flamemultipreview_dn.tga")
	end
	draw_quad(buttons.multipreview.x, buttons.multipreview.y, 128, 128, purchase_button)
	
	unload_texture(purchase_button)
	
	draw_text("Price: $"..details_price_usd, 30, 120, FONTS.MEDIUM)
	draw_text("Previewing", 505, 6, FONTS.MEDIUM)
	draw_text("flames:", 545, 26, FONTS.MEDIUM)
	if (details_flamename[1] ~= 0) then
		for i = 1, preview_flames do
			local multipreview_texture = load_texture("torishop/icons/"..details_flamename[i]..".tga")
			set_color(0, 0, 0, 1)
			draw_disk(660 + (i - 1) * 70 + 22, 29, 0, 24, 70, 1, 0, 360, 0)
			set_color(1, 1, 1, 1)
			draw_disk(660 + (i - 1) * 70 + 22, 29, 0, 22, 70, 1, 0, 360, 0)
			draw_quad(660 + (i - 1) * 70, 10, 64, 64, multipreview_texture)
			unload_texture(multipreview_texture)
		end
	else
		draw_text("Click on 'preview' or 'multipreview'", 670, 6, FONTS.MEDIUM)
		draw_text("buttons to see flame effects", 670, 26, FONTS.MEDIUM)
	end
	if string.find(details_name, "Sleepy") or string.find(details_name, "Rain") then
	draw_text("Comes with Flame", 460 - get_string_length("Comes with Flame", FONTS.MEDIUM), 90, FONTS.MEDIUM)
	draw_text("Particle Texture", 460 - get_string_length("Particle Texture", FONTS.MEDIUM), 110, FONTS.MEDIUM)
	elseif string.find(details_name, "Fire") then
	draw_text("Produces a burst effect", 460 - get_string_length("Produces a burst effect", FONTS.MEDIUM), 90, FONTS.MEDIUM)
	draw_text("with \"Water\"", 460 - get_string_length("with \"Water\"", FONTS.MEDIUM), 110, FONTS.MEDIUM)
	elseif string.find(details_name, "Water") then
	draw_text("Produces a burst effect", 460 - get_string_length("Produces a burst effect", FONTS.MEDIUM), 90, FONTS.MEDIUM)
	draw_text("with \"Fire\"", 460 - get_string_length("with \"Fire\"", FONTS.MEDIUM), 110, FONTS.MEDIUM)
	elseif string.find(details_name, "Raven Wings") then
	draw_text("Contains two", 460 - get_string_length("Contains two", FONTS.MEDIUM), 90, FONTS.MEDIUM)
	draw_text("flame items", 460 - get_string_length("flame items", FONTS.MEDIUM), 110, FONTS.MEDIUM)
	end
end


function draw_torishop()
	local pos_x, pos_y, pos_z = get_joint_pos(0, 1)
	set_camera_lookat(pos_x - 1.5, pos_y, pos_z)
	set_camera_pos(pos_x - 4, pos_y - 3, pos_z - 0.2)
	
	-- Overlay
	set_color(0, 0, 0, 0.7)
	draw_quad(0, 0, width, 58)
	set_color(0.5, 0, 0, 1)
	draw_quad(0, 0, 490, height)
	local color_bg = 0.6
	local color_bg_end = false
	for i = 1, 490 do
	if (color_bg >= 0.8) then 
		color_bg_end = true
	end
	if (color_bg_end == false) then
		color_bg = color_bg + i/152000
	else color_bg = color_bg - i/360000 end
	set_color(color_bg, 0, 0, 1)
	draw_quad(i, 1, 1, height-2)
	end
	
	set_color(0,0,0,0.2)
	draw_quad(0, height-1, 490, 1)
	draw_quad(0, height-58, 491, 57)
	-- The current shelf
	draw_shelf()
	
	
	if (total_shelves > 1) then
		set_color(0.0, 0.0, 0.0, 1.0)
		for i, v in pairs(buttons.arrows) do
			if (v.state == BTN_HOVER) then
				draw_disk(v.x, v.y, 0, 13, 3, 1, v.angle, 360, 0)
			elseif (v.state == BTN_DOWN) then
				draw_disk(v.x, v.y, 0, 7, 3, 1, v.angle, 360, 0)
			else
				draw_disk(v.x, v.y, 0, 10, 3, 1, v.angle, 360, 0)
			end
		end
	end
	
	select_color_links(buttons.torishop.state)
	draw_text("OPEN INVENTORY", buttons.torishop.x, buttons.torishop.y, FONTS.MEDIUM)
	select_color_links(buttons.tomain.state)
	draw_text("GO TO MAIN", buttons.tomain.x, buttons.tomain.y, FONTS.MEDIUM)
	
	-- Purchase confirmation
	if (confirm_name ~= nil) then
		-- Draw confirmation window
		set_color(0.16, 0.66, 0.86,.9)
		draw_quad(width/2 - 250, height/2 - 90, 500, 150)
		set_color(0,0,0,1)
		draw_quad(width/2 - 250, height/2 - 90, 1, 150)
		draw_quad(width/2 + 250, height/2 - 90, 1, 150)
		draw_quad(width/2 - 250, height/2 - 90, 500, 1)
		draw_quad(width/2 - 250, height/2 + 60, 500, 1)
		
		set_color(0,0,0,1)
		
		if string.len(confirm_name) > 10 then
			draw_centered_text("Are you sure want to buy", buttons.confirm.y - 63, FONTS.MEDIUM)
			draw_centered_text(confirm_name .. "?", buttons.confirm.y - 40, FONTS.MEDIUM)
		else
			draw_centered_text("Are you sure want to buy " .. confirm_name .. "?", buttons.confirm.y - 50, FONTS.MEDIUM)
		end
			
		if (buttons.confirm.state == BTN_UP) then set_color(0,0,0,1)
		else
		select_color_links(buttons.confirm.state) end
		draw_centered_text("Confirm purchase", buttons.confirm.y, FONTS.MEDIUM)
		if (buttons.cancel.state == BTN_UP) then set_color(0,0,0,1)
		else
		select_color_links(buttons.cancel.state) end
		draw_centered_text("Cancel", buttons.cancel.y, FONTS.MEDIUM)
	end
end


function close_torishop()
	--echo("closing torishop...")
	reset_camera(1)
	
	for i, v in pairs(options) do
		set_option(i, v) 
	end
	run_cmd("opt effects " .. effects_option)
	run_cmd("opt chat 1")
	run_cmd("opt newshopitem 0")
	
	if tempflag == 0 then
		local temp = io.open("torishop/flames.cfg", "w")
		temp:write("null")
		temp:close()
	end
	
	run_cmd("clear")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	remove_hooks("quit")
	remove_hooks("flamepreview")
    remove_hooks("torishop")
end

function init_torishop()
	run_cmd("opt effects 2")
--	run_cmd("cacheflames")
	add_hook("draw2d", "flamepreview", preview_flame)
	
	for i, v in pairs(options) do
		options[i] = get_option(i)
		set_option(i, 0)
	end
	set_option("chat", 1)
	
	start_torishop_camera(0)
	
	-- Ensure Torishop can close properly
	add_hook("leave_game", "quit", close_torishop)
	
	-- Load items picked from torishop.lua
	load_user()
		
	-- Prepare the item display
	load_data()
	if (data_exists == false) then
		print("Error")	-- print no torishop message
	
		add_hook("draw2d", "torishop", draw_offline)
		return
	end

	load_items()
	load_buttons()
	
	change_shelf(0)

	add_hook("draw2d", "torishop", draw_torishop)
	add_hook("mouse_button_down", "torishop", mouse_down)
	add_hook("mouse_button_up", "torishop", mouse_up)
	add_hook("mouse_move", "torishop", mouse_move)
	add_hook("key_down", "torishop", key_down)
	add_hook("key_up", "torishop", key_up)
end

-- Run Torishop
init_torishop()