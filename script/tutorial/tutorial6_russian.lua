
-- Common
local win_w, win_h = get_window_size()
local tutorial_stage = 0
local globaltimeouts = { }

function set_timeout(timeout, fn)
	local temp = 0
	if (get_option("framerate") == 30) then
		temp = get_world_state().frame_tick - 350
	else
		temp = get_world_state().frame_tick - 700
	end
	if (fn) then
		table.insert(globaltimeouts, { timeleft = timeout*(get_world_state().frame_tick - temp)/1000, func = fn } )
	end
end
function run_timeout(delta)
	delta = delta or 1	-- Prevent it from being nil

	local final = { }
	for i, t in ipairs(globaltimeouts) do
		t.timeleft = t.timeleft - delta
		if (t.timeleft < 0) then
			t.func()
		else
			table.insert(final, t)
		end
	end
	globaltimeouts = final
end


-- Message Box
local font_type = FONTS.MEDIUM
local font_info_height = 32
local font_info_width = 15

local msg1, msg2, msg3 = '', '', ''
local mid_print = false
local alpha = 1

function set_message(str1, str2, str3, mid) -- Set up to three lines of text for drawing
	msg1 = str1 or ''
	msg2 = str2 or ''
	msg3 = str3 or ''
	mid_print = mid
	alpha = 1
end
function change_message(timeout, str1, str2, str3, mid)
	set_timeout(timeout, function() set_message(str1, str2, str3, mid) end)
end
function draw_message()
	local num_msg = 0;
	if (msg1 ~= '') then
		num_msg = num_msg + 1
	end
	if (msg2 ~= '') then
		num_msg = num_msg + 1
	end
	if (msg3 ~= '') then
		num_msg = num_msg + 1
	end

	local y_mid = win_h - font_info_height*(3 - 0.5*(3 - num_msg) + 0.3)
	if (mid_print == true) then
		y_mid = win_h/2 - font_info_height
	end

	set_color(0, 0, 0, alpha)
	draw_centered_text(msg1, y_mid, font_type)
	draw_centered_text(msg2, y_mid + font_info_height, font_type)
	draw_centered_text(msg3, y_mid + font_info_height*2, font_type)
end
function draw_textbox()
	set_color(0.9, 0.9, 0.9, 0.8)
	draw_quad(120, win_h - 120, win_w - 270, 120)
end


-- Hand/Joint Tooltips
local hand_text = nil
local joint_text = nil
local hand_joint_render = false

function set_hand_tooltip(player, body)
	if ((body == BODYPARTS.L_HAND or body == BODYPARTS.R_HAND) and player == 0) then
		hand_text = { }
		local hand_info = get_body_info(player, body)
		hand_text['body_name'] = hand_info.name
		hand_text['player'] = player
		hand_text['hand'] = body
		hand_text['x'], hand_text['y'] = get_body_screen_pos(player, body)
	else
		hand_text = nil
	end
end
function draw_hand_tooltip()
	if (hand_text ~= nil and hand_joint_render == true) then
		-- get current grip from stored player and hand
		if (get_grip_info(hand_text.player, hand_text.hand) == 0) then
			hand_text['screen_state'] = "АНГРАБ"
		else
			hand_text['screen_state'] = "ГРАБ"
		end

		-- Draw hand name
		set_color(0.5, 0.5, 0.5, 0.8)
		draw_quad(hand_text.x + 30, hand_text.y + 10, 160, 30)
		set_color(0.0, 0.0, 0.0, 1.0)
		if (hand_text.body_name) == "L_HAND" then
		draw_text("ЛЕВАЯ ЛАДОНЬ", hand_text.x + 40, hand_text.y + 15)
		end
		if (hand_text.body_name) == "R_HAND" then
		draw_text("ПРАВАЯ ЛАДОНЬ", hand_text.x + 40, hand_text.y + 15)
		end

		-- Draw hand state
		set_color(0.7, 0.7, 0.7, 0.8)
		draw_quad(hand_text.x + 30, hand_text.y + 40, 160, 30)
		set_color(0.0, 0.3, 0.0, 1.0)
		draw_text(hand_text.screen_state, hand_text.x + 40, hand_text.y + 45)
	end
end
function set_joint_tooltip(player, joint)
	if (joint ~= -1 and player == 0) then
		joint_text = { }
		local joint_info = get_joint_info(player, joint)
		joint_text['player'] = player
		joint_text['joint'] = joint
		joint_text['joint_name'] = joint_info.name
		joint_text['x'], joint_text['y'] = get_joint_screen_pos(player, joint)
	else
		joint_text = nil
	end
end
function draw_joint_tooltip()
	if (joint_text ~= nil and hand_joint_render == true) then
		-- get current state from stored player and joint
		joint_text['screen_state'] = get_joint_info(joint_text.player, joint_text.joint).screen_state

		
		-- Draw joint name
		set_color(0.5, 0.5, 0.5, 0.8)
		draw_quad(joint_text.x + 30, joint_text.y + 10, 230, 30)
		
		set_color(0.0, 0.0, 0.0, 1.0)
		draw_text(joint_text.joint_name, joint_text.x + 40, joint_text.y + 15)

		-- Draw joint state
		set_color(0.7, 0.7, 0.7, 0.8)
		draw_quad(joint_text.x + 30, joint_text.y + 40, 230, 30)
	
	
	-- General
	if (joint_text.screen_state == "НАПРЯЖЕНИЕ:") then
		joint_text.screen_state = "НАПРЯЖЕНИЕ"
	end
	if (joint_text.screen_state == "РАССЛАБЛЕНИЕ:") then
		joint_text.screen_state = "РАССЛАБЛЕНИЕ"
	end
	if (joint_text.screen_state == "СГИБАЕТСЯ:") then
		joint_text.screen_state = "СГИБАЕТСЯ"
	end
	if (joint_text.screen_state == "РАЗГИБАЕТСЯ:") then
		joint_text.screen_state = "РАЗГИБАЕТСЯ"
	end
	if (joint_text.screen_state == "НАКЛОН ВПРАВО:") then
		joint_text.screen_state = "НАКЛОН ВПРАВО"
	end
	if (joint_text.screen_state == "НАКЛОН ВЛЕВО:") then
		joint_text.screen_state = "НАКЛОН ВЛЕВО"
	end
	if (joint_text.screen_state == "РАЗВОРОТ ВПРАВО:") then
		joint_text.screen_state = "РАЗВОРОТ ВПРАВО"
	end
	if (joint_text.screen_state == "РАЗВОРОТ ВЛЕВО:") then
		joint_text.screen_state = "РАЗВОРОТ ВЛЕВО"
	end
	if (joint_text.screen_state == "ОПУСКАЕТСЯ:") then
		joint_text.screen_state = "ОПУСКАЕТСЯ"
	end
	if (joint_text.screen_state == "ПОДНИМАЕТСЯ:") then
		joint_text.screen_state = "ПОДНИМАЕТСЯ"
	end
				
		set_color(0.0, 0.3, 0.0, 1.0)
		draw_text(joint_text.screen_state, joint_text.x + 40, joint_text.y + 45)
	end
end


-- Continue Button
local BTN_UP    = 0
local BTN_HOVER = 1
local BTN_DOWN  = 2

local px = win_w - 110
local py = win_h - 20
local draw_next_btn = false

local next_btn = {
	w = 60,
	h = 60,
	x = win_w - 100,
	y = win_h - 80,
	tx = win_w - 105,
	ty = win_h - 100,
	texture = load_texture('tutorial/next.tga'),
	state = BTN_UP,
	enabled = false,
}

function check_next_btn(x, y)
	return not ((x < next_btn.x or x > next_btn.x + next_btn.w) or (y < next_btn.y or y > next_btn.y + next_btn.h))
end
function render_next_btn()
	-- Draw the Next button
	local x, y, w, h = next_btn.x, next_btn.y, next_btn.w, next_btn.h
	
	if (next_btn.enabled == false) then
		set_color(0, 0, 0, 0.3)
		draw_quad(x, y, w, h, next_btn.texture)
		return
	end
	
	set_color(1, 1, 1, 1)
	if (next_btn.state == BTN_HOVER) then
		x, y = next_btn.x - 2, next_btn.y - 2
		w, h = next_btn.w + 4, next_btn.h + 4
	elseif (next_btn.state == BTN_DOWN) then
		w, h = next_btn.w + 4, next_btn.h + 4
	end
	draw_quad(x, y, w, h, next_btn.texture)
	
	-- Draw the tutorial completion percentage
	cal = math.floor((tutorial_stage/(#steps - 1))*100)
	if (cal < 0) then
		cal = 0
	end

	set_color(0.2, 0.2, 0.2, 1)
	percentage = string.format("%i%s", math.floor(cal), "% выполнено")
	draw_text(percentage, px - 15, py)

	-- Draw the button text
	set_color(0, 0, 0, 0.6)
	if (percentage == "100% выполнено") then
		draw_text("Следующий урок", next_btn.tx - 25, next_btn.ty)
	else
		draw_text("Дальше", next_btn.tx + 5, next_btn.ty)
	end
end

local draw_stop_btn  = false

local stop_btn = {
	w = 60,
	h = 60,
	x = win_w - 100,
	y = win_h - 160,
	tx = win_w - 105,
	ty = win_h - 180,
	texture = load_texture('tutorial/end.tga'),
	state = BTN_UP,
	enabled = false,
}

function check_stop_btn(x, y)
	return not ((x < stop_btn.x or x > stop_btn.x + stop_btn.w) or (y < stop_btn.y or y > stop_btn.y + stop_btn.h))
end
function render_stop_btn()
	if (stop_btn.enabled == false) then
		return
	end

	-- Draw the Stop button
	local x, y, w, h = stop_btn.x, stop_btn.y, stop_btn.w, stop_btn.h

	set_color(0, 0, 0, 0.3)
	draw_quad(x, y, w, h, stop_btn.texture)
	
	set_color(1, 1, 1, 1)
	if (stop_btn.state == BTN_HOVER) then
		x, y = x - 2, y - 2
		w, h = w + 4, h + 4
	elseif (stop_btn.state == BTN_DOWN) then
		w, h = w + 4, h + 4
	end
	draw_quad(x, y, w, h, stop_btn.texture)

	-- Draw the button text
	set_color(0, 0, 0, 0.8)
	draw_text("Выйти из обучения", stop_btn.tx - 30, stop_btn.ty)
end

local button_alert_size = 5
local button_alert_alpha = 1
local button_alert_render = false

function enlarge_button_alert()
	if (button_alert_render == true) then
		button_alert_size = button_alert_size + 0.2
		-- When button alert exceeds a certain size, start to fade out
		if (button_alert_size > 20) then
			button_alert_alpha = button_alert_alpha - 0.02
		end
		-- Reset button alert size once completely faded out
		if (button_alert_alpha < 0) then
			button_alert_size = 5
			button_alert_alpha = 1
		end
		set_timeout(3, enlarge_button_alert)
	end
end
function start_button_alert()
	button_alert_size = 0
	button_alert_alpha = 1
	button_alert_render = true
	next_btn.enabled = true

	set_timeout(3, enlarge_button_alert)
end
function stop_button_alert()
	button_alert_render = false
	next_btn.enabled = false
end
function render_button_alert()
	if (button_alert_render == true) then
		set_color(0.0, 0.0, 0.0, button_alert_alpha)
		inner = button_alert_size - 5
		outer = button_alert_size + 5
		if (inner < 0) then
			inner = 0
		end
		draw_disk(next_btn.x + next_btn.w/2, next_btn.y + next_btn.h/2, inner, outer, 32, 2, 0, 360, 0)
	end
end


-- DQ Ring
local dq_size = 0.0
local dq_alpha = 1
local dq_render = false

function start_dq()
	dq_render = true
	dq_size = 0.0
	dq_alpha = 1

	set_timeout(2, enlarge_dq)
end
function stop_dq()
	dq_render = false
end
function enlarge_dq()
	if (dq_render == true) then
		dq_size = dq_size + 0.1
		if (dq_size >= 10) then
			dq_alpha = dq_alpha - 0.02
		end
		if (dq_alpha < 0) then
			dq_size = 0.0
			dq_alpha = 1
		end

		set_timeout(5, enlarge_dq)
	end
end
function render_dq()
	if (dq_render == true) then
		set_color(1.0, 0.0, 0.0, dq_alpha)
		x = get_body_info(0, 0).pos.x
		y = get_body_info(0, 0).pos.y
		inner = dq_size - 0.4
		outer = dq_size
		if (inner < 0) then
			inner = 0
		end
		draw_disk_3d(x, y, 0.1, inner, outer, 32, 2, 180, -360, 0)
	end
end


-- Quad Alert (Red glow expanding from Boxes)
local quad_alert_size = 0
local quad_alert_alpha = 0.8
local quad_alert_render = false

function start_quad_alert()
	quad_alert_size = 0
	quad_alert_alpha = 0.8
	quad_alert_render = true

	set_timeout(3, enlarge_quad_alert)
end
function stop_quad_alert()
	quad_alert_render = false
end
function enlarge_quad_alert()
	if (quad_alert_render == true) then
		quad_alert_size = quad_alert_size + 0.2
		if (quad_alert_size > 7) then
			quad_alert_alpha = quad_alert_alpha - 0.02
		end
		if (quad_alert_alpha < 0) then
			quad_alert_size = 0
			quad_alert_alpha = 0.8
		end
		set_timeout(3, enlarge_quad_alert)
	end
end
function render_quad_alert(count)
	if (quad_alert_render == true) then
		set_color(1.0, 0.0, 0.0, quad_alert_alpha)
		if (count == 2) then
			draw_quad(win_w - 110 - quad_alert_size, 165 - quad_alert_size, 80 + quad_alert_size*2, 110 + quad_alert_size*2)
		elseif (count == 3) then
			draw_quad(win_w - 110 - quad_alert_size, 90 - quad_alert_size, 67 + quad_alert_size*2, 55 + quad_alert_size*2)
		end
	end
end


-- Other Graphical Overlays
local space_prs = 0
local shift_prs = 0
local z_prs = 0
local x_prs = 0
local c_prs = 0
local w_prs = 0
local s_prs = 0
local a_prs = 0
local d_prs = 0
local wasdshift_render = false;
local spacebar_render = false;
local zxc_render = false;
local mpqueue = 0;

function get_keystates()
	shift_prs = get_shift_key_state()
end

function draw_spacebar()
	set_color(space_prs, 0.0, 0.0, 1.0)
	draw_text("Пробел", win_w/2 - 300, win_h - (win_h/4) - 80, FONTS.BIG)
end
function draw_shift()
	set_color(shift_prs, 0.0, 0.0, 1.0)
	draw_text("SHIFT", win_w/2 - 300, win_h - (win_h/4) - 80, FONTS.BIG)
end
function draw_z()
	set_color(0.5, 0.5, 0.5, 0.8)
	draw_quad(win_w/2 - 330, win_h/2 + 50, 80, 80)
	set_color(z_prs, 0.0, 0.0, 1.0)
	draw_text("Z", win_w/2 - 310, win_h/2 + 60, FONTS.BIG)
end
function draw_x()
	set_color(0.5, 0.5, 0.5, 0.8)
	draw_quad(win_w/2 - 245, win_h/2 + 50, 80, 80)
	set_color(x_prs, 0.0, 0.0, 1.0)
	draw_text("X", win_w/2 - 225, win_h/2 + 60, FONTS.BIG)
end
function draw_c()
	set_color(0.5, 0.5, 0.5, 0.8)
	draw_quad(win_w/2 - 160, win_h/2 + 50, 80, 80)
	set_color(c_prs, 0.0, 0.0, 1.0)
	draw_text("C", win_w/2 - 140, win_h/2 + 60, FONTS.BIG)
end
function draw_arrow_up()
	set_color(0.5, 0.5, 0.5, 0.8)
	draw_disk(win_w/2, win_h/4, 0, 60, 3, 2, 180, 360, 0)
	set_color(w_prs, 0.0, 0.0, 1.0)
	draw_text("W", win_w/2 - 21, win_h/4 - 30, FONTS.BIG)
end
function draw_arrow_down()
	set_color(0.5, 0.5, 0.5, 0.8)
	draw_disk(win_w/2, win_h-(win_h/4)-50, 0, 60, 3, 2, 0, 360, 0)
	set_color(s_prs, 0.0, 0.0, 1.0)
	draw_text("S", win_w/2 - 13, win_h - (win_h/4) - 80, FONTS.BIG)
end
function draw_arrow_left()
	set_color(0.5, 0.5, 0.5, 0.8)
	draw_disk(win_w/4 + 50, win_h/2 - 25, 0, 60, 3, 2, 270, 360, 0)
	set_color(a_prs, 0.0, 0.0, 1.0)
	draw_text("A", win_w/4 + 35, win_h/2 - 60, FONTS.BIG)
end
function draw_arrow_right()
	set_color(0.5, 0.5, 0.5, 0.8)
	draw_disk(win_w - (win_w/4) - 50, win_h/2 - 25, 0, 60, 3, 2, 90, 360, 0)
	set_color(d_prs, 0.0, 0.0, 1.0)
	draw_text("D", win_w - (win_w/4) - 70, win_h/2 - 55, FONTS.BIG)
end
function draw_mpqueue()
	render_quad_alert(mpqueue)

	set_color(0.7, 0.7, 0.7, 1.0)
	if (mpqueue == 2) then
		draw_quad(win_w - 110, 165, 80, 110)	-- Draw box around waiting list
	elseif (mpqueue == 3) then
		draw_quad(win_w - 110, 90, 67, 55)		-- Draw box around playing list
	end
	
	-- Draw names in playing list
	set_color(0.58, 0.0, 0.0, 1.0)
	draw_text("hampa", win_w - 100, 95)
	set_color(0.2, 0.6, 1.0, 1.0)
	draw_text("Dranix", win_w - 100, 120)

	local name = get_master().master.nick
	
		-- Draw names in waiting list
	set_color(0.0, 1.0, 0.0, 1.0)
	draw_text(name, win_w - 100, 195)
	set_color(0.0, 0.0, 0.0, 1.0)
	draw_text("NutHug", win_w - 100, 170)
	draw_text("Tori", win_w - 100, 220)
	draw_text("Uke", win_w - 100, 245)
	run_cmd("cl")
end

function draw_overlays() -- Draws enabled overlays
	if (wasdshift_render == true) then
		draw_shift()
		draw_arrow_up()
		draw_arrow_down()
		draw_arrow_left()
		draw_arrow_right()
	elseif (spacebar_render == true) then
		draw_spacebar()
	elseif (zxc_render == true) then
		draw_z()
		draw_x()
		draw_c()
	elseif (mpqueue > 0) then
		draw_mpqueue()
	end
end


-- Keyboard
function key_down_func(key)
	if (key == string.byte('p')) then
		return 1
	end
	if (wasdshift_render == true) then
		if (key == string.byte('w')) then
			w_prs = 1
		end
		if (key == string.byte('s')) then
			s_prs = 1
		end
		if (key == string.byte('a')) then
			a_prs = 1
		end
		if (key == string.byte('d')) then
			d_prs = 1
		end
	end

	if (zxc_render == true) then
		if (key == string.byte('z')) then
			z_prs = 1
		end
		if (key == string.byte('x')) then
			x_prs = 1
		end
		if (key == string.byte('c')) then
			c_prs = 1
		end
	end

	if (key == string.byte(' ')) then
		if (spacebar_render == true) then
			space_prs = 1
		end
		return 1
	end
end
function key_up_func(key)
	if (key == string.byte('p')) then
		return 1
	end
	if (wasdshift_render == true) then
		if (key == string.byte('w')) then
			w_prs = 0
		end
		if (key == string.byte('s')) then
			s_prs = 0
		end
		if (key == string.byte('a')) then
			a_prs = 0
		end
		if (key == string.byte('d')) then
			d_prs = 0
		end
	end

	if (zxc_render == true) then
		if (key == string.byte('z')) then
			z_prs = 0
		end
		if (key == string.byte('x')) then
			x_prs = 0
		end
		if (key == string.byte('c')) then
			c_prs = 0
		end
	end

	if (key == string.byte(' ')) then
		if (spacebar_render == true) then
			space_prs = 0
		end
		return 1
	end
end
function lock_keyboard()
	remove_hooks("keyboard")
	add_hook("key_down", "keyboard", function() return 1 end)
	add_hook("key_up", "keyboard", function() return 1 end)
end
function unlock_keyboard()
	remove_hooks("keyboard")
	add_hook("key_down", "keyboard", key_down_func)
	add_hook("key_up", "keyboard", key_up_func)
end


-- Mouse
local MOUSE_UP = 0
local MOUSE_DOWN = 1
local mouse_state = MOUSE_UP

function mouse_down(mouse_btn, x, y)
	mouse_state = MOUSE_DOWN
	if (next_btn.enabled == true) then
		if (check_next_btn(x, y) == true) then
			next_btn.state = BTN_DOWN
		end
	end
	if (stop_btn.enabled == true) then
		if (check_stop_btn(x, y) == true) then
			stop_btn.state = BTN_DOWN
		end
	end
end
function mouse_up(mouse_btn, x, y)
	mouse_state = MOUSE_UP
	if (next_btn.enabled == true) then
		next_btn.state = BTN_UP
		if (check_next_btn(x, y) == true) then
			advance()
		end
	end
	if (stop_btn.enabled == true) then
		stop_btn.state = BTN_UP
		if (check_stop_btn(x, y) == true) then
			terminate()
			start_new_game()
		end
	end
end
function mouse_move(x, y)
	if (next_btn.enabled == true) then
		if (check_next_btn(x, y) == true) then
			if (mouse_state == MOUSE_DOWN) then
				next_btn.state = BTN_DOWN
			else
				next_btn.state = BTN_HOVER
			end
		else
			next_btn.state = BTN_UP
		end
	end
	if (stop_btn.enabled == true) then
		if (check_stop_btn(x, y) == true) then
			if (mouse_state == MOUSE_DOWN) then
				stop_btn.state = BTN_DOWN
			else
				stop_btn.state = BTN_HOVER
			end
		else
			stop_btn.state = BTN_UP
		end
	end
end


-- Camera
local limit_camera = false

function update_camera()
	if (limit_camera == true) then
		reset_camera(0.5)
	end
end


-- Update Loop
function update_loop()
	run_timeout(1)
	get_keystates()
	update_camera()
end
function draw_2d()
	render_button_alert()
	render_next_btn()
	render_stop_btn()
	draw_textbox()
	draw_message()
	draw_hand_tooltip()
	draw_joint_tooltip()
	draw_overlays()
end
function draw_3d()
	render_dq()
end



-- Tutorial
function advance() -- Disables button, then runs the next tutorial stage from steps
	stop_button_alert()
	tutorial_stage = tutorial_stage + 1
	if (steps[tutorial_stage] ~= nil) then
		steps[tutorial_stage]()
	end
end

local intro_msg = {
	"Приветствуем тебя в обучении Toribash!",
 }
local camera_msg = {
	"Управление камерой!",
	"Нажимай клавиши 'W/A/S/D' для управления камерой",
	"Держи клавишу Shift во время нажатия 'W/S'",
	"для изменения высоты камеры",
}
local controls_msg = {
	"Управление твоим Тори!",
	"Используй левую кнопку мыши при наведении на суставы",
	"или используй колёсико для изменения их состояний!",
	"Нажми на ладони, чтобы включить граб",
	"Ты сможешь использовать его для захвата противника",
	"Во время наведения курсора на сустав",
	"ты можешь также нажимать клавиши 'Z' или 'X'",
	"Нажми 'C', чтобы переключить состояние всех суставов",
	"с 'Hold' на 'Relax'",
	"Нажми пробел, чтобы закончить свой ход",
}
local game_msg = {
	"Ты можешь делать невероятные движения,",
	"комбинируя состояния суставов!",
	"Видишь это кольцо на полу?",
	"Это кольцо дисквалификации (DQ)",
	"Тебя дисквалифицируют, если твоё тело",
	"коснётся пола первым!",
	"Дисквалифицируй своих оппонентов",
	"или набери больше очков урона, чтобы победить!",
}
local multiplay_msg = {
	"Игра в мультиплеере!",
	"После присоединения к комнате",
	"ты будешь помещён в список ожидающих",
	"Игроки, которые дерутся в данный момент,",
	"отображаются здесь",
	"Победитель матча будет драться",
	"со следующим игроком из списка",
	"Как только ты освоишь несколько движений,",
	"опробуй свои умения в боях с другими игроками!",
}

local default_background_click = 1
local default_footer_state = 1
local default_autosave = 1

function start_tutorial()
	-- Store the current options
	default_background_click = get_option("backgroundclick")
	default_autosave = get_option("autosave")
	default_footer_state = get_option("text")

	-- Disable these options during the tutorial
	set_option("backgroundclick", 0)
	set_option("autosave", 0)
	set_option("text", 0)

	run_cmd("lm classic.tbm")
	run_cmd("option uke 0")
	run_cmd("opt chat 0")

	add_hook("draw2d", "tutorial", draw_2d)
	add_hook("draw3d", "tutorial", function() draw_3d(); update_loop() end)
	add_hook("mouse_button_down", "mouse", mouse_down)
	add_hook("mouse_button_up", "mouse", mouse_up)
	add_hook("mouse_move", "mouse", mouse_move)
	add_hook("leave_game", "terminate", terminate)

	lock_keyboard()

	-- Start the tutorial
	set_timeout(100, advance)
end

function introduction()
	set_message(intro_msg[1])

	run_cmd("dl dranix")
	run_cmd("cl")
	
	set_timeout(0, start_button_alert)
end

function camera_1()
	set_message(camera_msg[1])

	set_timeout(0, start_button_alert)
end
function camera_2()
	unlock_keyboard()

	wasdshift_render = true

	set_message(camera_msg[2])

	-- Continue condition: Press W/S/A/D
	local check_conditions = function(key)
		if (key == string.byte('w') or key == string.byte('s') or key == string.byte('a') or key == string.byte('d')) then
			set_timeout(50, advance)
			remove_hooks("conditions")
		end
	end
	add_hook("key_down", "conditions", check_conditions)
end
function camera_3()
	set_message(camera_msg[3], camera_msg[4])

	-- Continue condition: Hold shift and press W/S
	local check_conditions = function(key)
		if (shift_prs == 1 and (key == string.byte('w') or key == string.byte('s'))) then
			set_timeout(50, start_button_alert)
			remove_hooks("conditions")
		end
	end
	add_hook("key_down", "conditions", check_conditions)
end

function controls_1()
	lock_keyboard()

	wasdshift_render = false
	limit_camera = true

	set_message(controls_msg[1])

	set_timeout(0, start_button_alert)
end
function controls_2()
	unlock_keyboard()
	add_hook("joint_select", "bodyparts", set_joint_tooltip)
	add_hook("body_select", "bodyparts", set_hand_tooltip)

	limit_camera = false
	hand_joint_render = true

	set_message(controls_msg[2], controls_msg[3])

	-- Continue condition: Click on a joint
	local check_conditions = function()
		if (joint_text ~= nil) then
			set_timeout(0, start_button_alert)
			remove_hooks("conditions")
		end
	end
	add_hook("mouse_button_down", "conditions", check_conditions)
end
function controls_3()
	unlock_keyboard()

	set_message(controls_msg[4], controls_msg[5])

	-- Continue condition: Click on a hand
	local check_conditions = function(mouse_btn, x, y)
		if (hand_text ~= nil and mouse_btn == 1) then
			set_timeout(0, start_button_alert)
			remove_hooks("conditions")
		end
	end
	add_hook("mouse_button_down", "conditions", check_conditions)
end
function controls_4()
	zxc_render = true

	set_message(controls_msg[6], controls_msg[7])

	-- Continue condition: Hover over a joint and press Z/X
	local check_conditions = function(key)
		if (joint_text ~= nil and (key == string.byte('z') or key == string.byte('x'))) then
			set_timeout(50, advance)
			remove_hooks("conditions")
		end
	end
	add_hook("key_up", "conditions", check_conditions)
end
function controls_5()
	set_message(controls_msg[8], controls_msg[9])

	-- Continue condition: Press C
	local check_conditions = function(key)
		if (key == string.byte('c')) then
			set_timeout(50, start_button_alert)
			remove_hooks("conditions")
		end
	end
	add_hook("key_up", "conditions", check_conditions)
end
function controls_6()
	zxc_render = false
	spacebar_render = true

	set_message(controls_msg[10])

	-- Continue condition: Press spacebar
	local check_conditions = function(key)
		if (key == string.byte(' ')) then
			set_timeout(180, advance)
			run_frames(180)
			remove_hooks("conditions")
		end
	end
	add_hook("key_up", "conditions", check_conditions)
end

function gameplay_1()
	lock_keyboard()
	reset_camera(1)
	remove_hooks("bodyparts")
	remove_hooks("terminate")

	run_cmd("option uke 1")
	run_cmd("loadreplay system/tut_1-1.rpl")

	add_hook("leave_game", "terminate", terminate)

	hand_joint_render = false
	spacebar_render = false
	limit_camera = true

	set_message(game_msg[1], game_msg[2])

	run_frames(220)
	set_timeout(310, start_dq)
	set_timeout(310, start_button_alert)
end
function gameplay_2()
	set_message(game_msg[3])

	set_timeout(0, start_button_alert)
end
function gameplay_3()
	set_message(game_msg[4])

	set_timeout(0, start_button_alert)
end
function gameplay_4()
	set_message(game_msg[5], game_msg[6])

	set_timeout(0, start_button_alert)
end
function gameplay_5()
	set_message(game_msg[7], game_msg[8])

	set_timeout(0, start_button_alert)
end

function multiplayer_1()
	remove_hooks("terminate")
	
	stop_dq()
	start_new_game()
	run_cmd("option uke 1")
    run_cmd("lp 0hampa")
	run_cmd("lp 1dranix")
	run_cmd("cl");

	add_hook("leave_game", "terminate", terminate)

	mpqueue = 1

	set_message(multiplay_msg[1])

	set_timeout(0, start_button_alert)
end
function multiplayer_2()
	start_quad_alert()

	mpqueue = 2

	set_message(multiplay_msg[2], multiplay_msg[3])

	set_timeout(0, start_button_alert)
end
function multiplayer_3()
	start_quad_alert()

	mpqueue = 3

	set_message(multiplay_msg[4], multiplay_msg[5])

	set_timeout(0, start_button_alert)
end
function multiplayer_4()
	set_message(multiplay_msg[6], multiplay_msg[7])

	set_timeout(0, start_button_alert)
end
function multiplayer_5()
	set_message(multiplay_msg[8], multiplay_msg[9])

	set_timeout(0, function() start_button_alert(); stop_btn.enabled = true; end)
end

function terminate()
	stop_quad_alert()

	mpqueue = 0
	tutorial_stage = 0

	-- Remove all custom hooks used in tutorial
	remove_hooks("tutorial")
	remove_hooks("mouse")
	remove_hooks("keyboard")
	remove_hooks("terminate")
	remove_hooks("bodyparts")
	remove_hooks("conditions")

	-- Set back to stored options
	set_option("backgroundclick", default_background_click)
	set_option("autosave", default_autosave)
	set_option("text", default_footer_state)

	run_cmd("option uke 1")
	run_cmd("set engagedistance 100")
	run_cmd("opt chat 1")
	run_cmd("clear")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo("Загляни на русскоязычный раздел форума Toribash!")
	echo("http://forum.toribash.com/forumdisplay.php?f=672")
end
function end_tutorial()
	terminate()
	run_tutorial(2)
end


-- List of all the steps
steps = {
	introduction,
	camera_1,
	camera_2,
	camera_3,
	controls_1,
	controls_2,
	controls_3,
	controls_4,
	controls_5,
	controls_6,
	gameplay_1,
	gameplay_2,
	gameplay_3,
	gameplay_4,
	gameplay_5,
	multiplayer_1,
	multiplayer_2,
	multiplayer_3,
	multiplayer_4,
	multiplayer_5,
	end_tutorial,
}

-- This line triggers the tutorial
start_tutorial()