
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
	draw_quad(120, win_h - 120, win_w - 240, 120)
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
			hand_text['screen_state'] = "RELEASE"
		else
			hand_text['screen_state'] = "GRAB"
		end

		-- Draw hand name
		set_color(0.5, 0.5, 0.5, 0.8)
		draw_quad(hand_text.x + 30, hand_text.y + 10, 160, 30)
		set_color(0.0, 0.0, 0.0, 1.0)
		draw_text(hand_text.body_name, hand_text.x + 40, hand_text.y + 15)

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
		draw_quad(joint_text.x + 30, joint_text.y + 10, 160, 30)
		set_color(0.0, 0.0, 0.0, 1.0)
		draw_text(joint_text.joint_name, joint_text.x + 40, joint_text.y + 15)

		-- Draw joint state
		set_color(0.7, 0.7, 0.7, 0.8)
		draw_quad(joint_text.x + 30, joint_text.y + 40, 160, 30)
		set_color(0.0, 0.3, 0.0, 1.0)
		draw_text(joint_text.screen_state, joint_text.x + 40, joint_text.y + 45)
	end
end


-- Hand/Joint Alerts
local body_alert_size = 0
local body_alert_alpha = 1
local hand_alert_render = false
local joint_alert_render = false

function enlarge_body_alert()
	if (joint_alert_render == true or hand_alert_render == true) then
		body_alert_size = body_alert_size + 0.01
		body_alert_alpha = body_alert_alpha - 0.02
		if (body_alert_alpha < 0) then
			body_alert_size = 0
			body_alert_alpha = 1
		end
		set_timeout(5, enlarge_body_alert)
	end
end

local left_hand = nil
local right_hand = nil

function start_hand_alert()
	left_hand = get_body_info(0, BODYPARTS.L_HAND)
	right_hand = get_body_info(0, BODYPARTS.R_HAND)

	body_alert_size = 0
	body_alert_alpha = 1
	hand_alert_render = true
	set_timeout(5, enlarge_body_alert)
end
function end_hand_alert()
	hand_alert_render = false
end
function render_hand_alert()
	if (hand_alert_render == true) then
		set_color(0.5, 0.5, 0.5, body_alert_alpha)
		draw_box_m(left_hand.pos.x, left_hand.pos.y, left_hand.pos.z, body_alert_size, body_alert_size, body_alert_size, left_hand.rot)
		draw_box_m(right_hand.pos.x, right_hand.pos.y, right_hand.pos.z, body_alert_size, body_alert_size, body_alert_size, right_hand.rot)
	end
end

local joint = {{ j = nil, x = 0, y = 0, z = 0 }, { j = nil, x = 0, y = 0, z = 0 }}
local color = { relax = 0, force = 0 }

function start_joint_alert(joint_1, joint_2)	-- Pass in up to 2 joints
	joint[1].j = joint_1
	joint[2].j = joint_2

	if (joint[1].j ~= nil) then
		local tmp = get_joint_color(0, joint[1].j)
		color.relax = tmp.joint.relax
		color.force = tmp.joint.force
		joint[1].x, joint[1].y, joint[1].z = get_joint_pos(0, joint[1].j)
		set_selected_joint_force_color(0, joint[1].j, 25)
		set_selected_joint_relax_color(0, joint[1].j, 25)
	end
	if (joint[2].j ~= nil) then
		local tmp = get_joint_color(0, joint[2].j)
		color.relax = tmp.joint.relax
		color.force = tmp.joint.force
		joint[2].x, joint[2].y, joint[2].z = get_joint_pos(0, joint[2].j)
		set_selected_joint_force_color(0, joint[2].j, 25)
		set_selected_joint_relax_color(0, joint[2].j, 25)
	end

	if (joint[1].j ~= nil) then
		body_alert_size = 0
		body_alert_alpha = 1
		joint_alert_render = true
		set_timeout(5, enlarge_body_alert)
	end
end
function end_joint_alert()
	joint_alert_render = false

	if (joint[1].j ~= nil) then
		set_selected_joint_relax_color(0, joint[1].j, color.relax)
		set_selected_joint_force_color(0, joint[1].j, color.force)
	end
	if (joint[2].j ~= nil) then
		set_selected_joint_relax_color(0, joint[2].j, color.relax)
		set_selected_joint_force_color(0, joint[2].j, color.force)
	end

	joint[1].j = nil
	joint[2].j = nil
end
function render_joint_alert()
	if (joint_alert_render == true) then
		set_color(0.5, 0.5, 0.5, body_alert_alpha)
		if (joint[1].j ~= nil) then
			draw_sphere(joint[1].x, joint[1].y, joint[1].z, body_alert_size)
		end
		if (joint[2].j ~= nil) then
			draw_sphere(joint[2].x, joint[2].y, joint[2].z, body_alert_size)
		end
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
		x, y = next_btn.x + 2, next_btn.y + 2
		w, h = next_btn.w - 4, next_btn.h - 4		
	end
	draw_quad(x, y, w, h, next_btn.texture)
	
	-- Draw the tutorial completion percentage
	cal = math.floor((tutorial_stage/(#steps - 1))*100)
	if (cal < 0) then
		cal = 0
	end

	set_color(0.2, 0.2, 0.2, 1)
	percentage = string.format("%i%s", math.floor(cal), "% pronto")
	if math.floor(cal) < 10 then
		draw_text(percentage, px + 6, py)
		draw_text(percentage, px + 7, py)
	else
		draw_text(percentage, px + 2, py)
		draw_text(percentage, px + 3, py)
	end
	-- Draw the button text
	set_color(0, 0, 0, 0.3)
	if (percentage == "100% pronto") then
		draw_text("Próximo", next_btn.tx+6, next_btn.ty)
		draw_text("Próximo", next_btn.tx+7, next_btn.ty)
	else
		draw_text("Continuar", next_btn.tx+2, next_btn.ty)
		draw_text("Continuar", next_btn.tx+3, next_btn.ty)
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
		x, y = x + 2, y + 2 
		w, h = w - 4, h - 4
	end
	draw_quad(x, y, w, h, stop_btn.texture)

	-- Draw the button text
	set_color(0, 0, 0, 0.3)
	draw_text("Finalizar Treinamento", stop_btn.tx-44, stop_btn.ty)
	draw_text("Finalizar Treinamento", stop_btn.tx-43, stop_btn.ty)
end

local button_alert_size = 0
local button_alert_alpha = 0.8
local button_alert_render = false

function enlarge_button_alert()
	if (button_alert_render == true) then
		button_alert_size = button_alert_size + 0.3
		-- When button alert exceeds a certain size, start to fade out
		if (button_alert_size > 20) then
			button_alert_alpha = button_alert_alpha - 0.02
		end
		-- Reset button alert size once completely faded out
		if (button_alert_alpha < 0) then
			button_alert_size = 0
			button_alert_alpha = 0.8
		end
		set_timeout(3, enlarge_button_alert)
	end
end
function start_button_alert()
	button_alert_size = 0
	button_alert_alpha = 0.8
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
		set_color(0.0, 0.0, 1.0, button_alert_alpha)
		inner = button_alert_size - 5
		outer = button_alert_size + 5
		if (inner < 0) then
			inner = 0
		end
		draw_disk(next_btn.x + next_btn.w/2, next_btn.y + next_btn.h/2, inner, outer, 32, 2, 0, 360, 0)
	end
end


-- Keyboard (keys locked by default: LERPK)
function zxc_lock(key)
	if (key == string.byte('z') or key == string.byte('x') or key == string.byte('c')
	or key == string.byte('l') or key == string.byte('e') or key == string.byte('r') or key == string.byte('p') or key == string.byte('k')) then
		print("special lock active")
		return 1
	end
end
function space_lock(key)
	if (key == string.byte(' ')
	or key == string.byte('l') or key == string.byte('e') or key == string.byte('r') or key == string.byte('p') or key == string.byte('k')) then
		print("special lock active")
		return 1
	end
end
function zxc_space_lock(key)
	if (key == string.byte('z') or key == string.byte('x') or key == string.byte('c') or key == string.byte(' ')
	or key == string.byte('l') or key == string.byte('e') or key == string.byte('r') or key == string.byte('p') or key == string.byte('k')) then
		print("special lock active")
		return 1
	end
end
function lock_keyboard(lock_type)	-- lock types: nil = full, 1 = space, 2 = zxc, 3 = space + zxc
	if (lock_type == nil) then	-- Full lock
		add_hook("key_down", "keylock", function() return 1 end)
		add_hook("key_up", "keylock", function() return 1 end)
	elseif (lock_type == 1) then
		add_hook("key_down", "keylock", space_lock)
		add_hook("key_up", "keylock", space_lock)
	elseif (lock_type == 2) then
		add_hook("key_down", "keylock", zxc_lock)
		add_hook("key_up", "keylock", zxc_lock)
	else
		add_hook("key_down", "keylock", zxc_space_lock)
		add_hook("key_up", "keylock", zxc_space_lock)
	end
end
function unlock_keyboard()
	remove_hooks("keylock")
end
function relock_keyboard(lock_type)	-- Use this to prevent multiple hooks from the same functions
	unlock_keyboard()
	lock_keyboard(lock_type)
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
			echo("Acesse a Escola de Luta do Toribash a partir do link abaixo!")
			echo("http://forum.toribash.com/forumdisplay.php?f=362")
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

function mouse_lock()
	ws = get_world_state()
	if (ws.selected_joint > -1 or ws.selected_body > -1) then
		print("special lock active")
		return 1
	end
end
function lock_mouse()
	add_hook("mouse_button_down", "mouselock", mouse_lock)
end
function unlock_mouse()
	remove_hooks("mouselock")
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
	update_camera()
end
function draw_2d()
	draw_textbox()
	draw_message()
	render_button_alert()
	render_next_btn()
	render_stop_btn()
	draw_hand_tooltip()
	draw_joint_tooltip()
end
function draw_3d()
	render_hand_alert()
	render_joint_alert()
end



-- Tutorial
function advance()
	stop_button_alert()
	tutorial_stage = tutorial_stage + 1
	if (steps[tutorial_stage] ~= nil) then
		steps[tutorial_stage]()
	end
end

local intro_msg = {
	"--------",
	"Tutorial de Treinamento Básico",
	"--------",
	"Este tutorial vai mostrá-lo",
	"alguns movimentos de luta!",
}
local part_one_msg = {
	"Agora é a hora de",
	"chutar seu oponente!",
	"Pressione 'C' para forçar todas as suas articulações,",
	"então clique no seu joelho esquerdo para extendê-lo",
	"Finalmente, pressione espaço",
	"para executar seu movimento!",
	"Ótimo chute!",
}
local part_two_msg = {
	"Vamos tentar outro ataque",
	"Desta vez, extenda ambas as pernas",
	"para chutar seu oponente",
	"E então pressione espaço",
	"para terminar o turno",
	"Agora, abaixe ambos os ombros",
	"e solte ambas as mãos",
	"E então pressione espaço",
	"para terminar o turno novamente",
	"Touchdown!",
	"Aprenda algumas técnicas de luta",
	"ou desafie Uke se você estiver preparado!",
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

	disable_player_select(1) -- Disable clicking on Uke

	run_cmd("lm classic.tbm")
	run_cmd("clear")

	add_hook("draw2d", "tutorial", draw_2d)
	add_hook("draw3d", "tutorial", function() draw_3d(); update_loop() end)
	add_hook("mouse_button_down", "mouse", mouse_down)
	add_hook("mouse_button_up", "mouse", mouse_up)
	add_hook("mouse_move", "mouse", mouse_move)
	add_hook("leave_game", "terminate", terminate)

	lock_keyboard()
	lock_mouse()

	-- Start the tutorial
	set_timeout(100, advance)
end

function introduction_1()
	limit_camera = true

	set_message(intro_msg[1], intro_msg[2], intro_msg[3])

	set_timeout(0, start_button_alert)
end
function introduction_2()
	set_message(intro_msg[4], intro_msg[5])

	set_timeout(0, start_button_alert)
end

function part_one_1()
	remove_hooks("terminate")

	start_new_game()	-- This clears the settings for the previous replay
	set_gameover_timelimit(4)
	run_cmd("loadreplay system/tut_2-1.rpl")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")

	add_hook("leave_game", "terminate", terminate)

	set_message("")

	set_timeout(60, edit_game)
	set_timeout(80, advance)
end
function part_one_2()
	relock_keyboard(3)

	-- This is done to reduce collision lag in the later segments, and not as part of the move
	set_grip_info(0, BODYPARTS.L_HAND, 1)
	set_grip_info(0, BODYPARTS.R_HAND, 1)

	limit_camera = false

	set_message(part_one_msg[1], part_one_msg[2])

	set_timeout(0, start_button_alert)
end
function part_one_3()
	relock_keyboard(1)
	unlock_mouse()
	add_hook("joint_select", "bodyparts", set_joint_tooltip)
	add_hook("body_select", "bodyparts", set_hand_tooltip)

	hand_joint_render = true

	set_message(part_one_msg[3], part_one_msg[4])

	local check_key_conditions = function(key)
		if (key == string.byte('c')) then
			for i, v in pairs(JOINTS) do
				set_joint_state(0, v, JOINT_STATE.HOLD)
			end
			relock_keyboard(3)
			lock_mouse()
			remove_hooks("conditions")
			set_timeout(0, advance)
			return 1
		end
	end
	add_hook("key_down", "conditions", check_key_conditions)
end
function part_one_4()
	relock_keyboard(1)
	unlock_mouse()

	start_joint_alert(JOINTS.L_KNEE)

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_KNEE
			if (get_world_state().selected_joint == JOINTS.L_KNEE and get_joint_info(0, JOINTS.L_KNEE).state ~= JOINT_STATE.FORWARD) then
				remove_hooks("conditions")
				set_timeout(1, function() relock_keyboard(3) lock_mouse() end_joint_alert() end)
				set_timeout(50, advance)
			else
				return 1
			end
		elseif (key == string.byte('x')) then	-- x is locked on all joints but L_KNEE
			if (get_world_state().selected_joint ~= JOINTS.L_KNEE) then
				return 1
			end
		elseif (key == string.byte('c')) then	-- c toggles L_KNEE to hold
			set_joint_state(0, JOINTS.L_KNEE, JOINT_STATE.HOLD)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)

	local check_mousedown_conditions = function()
		ws = get_world_state()
		if (ws.selected_joint ~= JOINTS.L_KNEE or ws.selected_body > -1) then
			return 1
		end
	end
	add_hook("mouse_button_down", "conditions", check_mousedown_conditions)

	local check_mouseup_conditions = function()
		if (get_joint_info(0, JOINTS.L_KNEE).state == JOINT_STATE.FORWARD) then
			relock_keyboard(3)
			lock_mouse()
			end_joint_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function part_one_5()
	relock_keyboard(2)
	remove_hooks("bodyparts")

	hand_joint_render = false

	set_message(part_one_msg[5], part_one_msg[6])

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			change_message(100, part_one_msg[7])
			set_timeout(100, start_button_alert)
			set_gameover_timelimit(-1)
			run_frames(500)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end

function part_two_1()
	remove_hooks("terminate")

	start_new_game()	-- This clears the settings for the previous replay
	set_gameover_timelimit(4)
	run_cmd("loadreplay system/tut_2-2.rpl")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	freeze_game()

	add_hook("leave_game", "terminate", terminate)

	relock_keyboard()
	reset_camera(1)
	limit_camera = true

	set_message(part_two_msg[1])

	set_timeout(0, start_button_alert)
end
function part_two_2()
	unfreeze_game()

	set_message("")

	set_timeout(130, edit_game)
	set_timeout(150, advance)
end
function part_two_3()
	relock_keyboard(1)
	unlock_mouse()
	add_hook("joint_select", "bodyparts", set_joint_tooltip)
	add_hook("body_select", "bodyparts", set_hand_tooltip)

	start_joint_alert(JOINTS.L_KNEE, JOINTS.R_KNEE)

	limit_camera = false
	hand_joint_render = true

	set_message(part_two_msg[2], part_two_msg[3])

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_KNEE and R_KNEE
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_KNEE).state
			local r_joint_info = get_joint_info(0, JOINTS.R_KNEE).state

			if (joint == JOINTS.L_KNEE or joint == JOINTS.R_KNEE) then
				if ((joint == JOINTS.L_KNEE and l_joint_info ~= JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.FORWARD) or
					(joint == JOINTS.R_KNEE and r_joint_info ~= JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.FORWARD)) then
					remove_hooks("conditions")
					set_timeout(1, function() relock_keyboard(3) lock_mouse() end_joint_alert() end)
					set_timeout(50, advance)
				end
			else
				return 1
			end
		elseif (key == string.byte('x')) then	-- x is locked on all joints but L_KNEE and R_KNEE
			local joint = get_world_state().selected_joint
			if (joint ~= JOINTS.L_KNEE and joint ~= JOINTS.R_KNEE) then
				return 1
			end
		elseif (key == string.byte('c')) then	-- c toggles L_KNEE, R_KNEE to hold
			set_joint_state(0, JOINTS.L_KNEE, JOINT_STATE.HOLD)
			set_joint_state(0, JOINTS.R_KNEE, JOINT_STATE.HOLD)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)

	local check_mousedown_conditions = function()
		local ws = get_world_state()
		local body = ws.selected_body
		local joint = ws.selected_joint

		if (body > -1 or (joint ~= JOINTS.L_KNEE and joint ~= JOINTS.R_KNEE)) then
			return 1
		end
	end
	add_hook("mouse_button_down", "conditions", check_mousedown_conditions)

	local check_mouseup_conditions = function()
		local l_joint_info = get_joint_info(0, JOINTS.L_KNEE).state
		local r_joint_info = get_joint_info(0, JOINTS.R_KNEE).state

		if (l_joint_info == JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.FORWARD) then
			relock_keyboard(3)
			lock_mouse()
			end_joint_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function part_two_4()
	relock_keyboard(2)

	set_message(part_two_msg[4], part_two_msg[5])

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(50, advance)
			run_frames(30)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function part_two_5()
	relock_keyboard(1)
	unlock_mouse()

	start_joint_alert(JOINTS.L_SHOULDER, JOINTS.R_SHOULDER)

	set_message(part_two_msg[6], part_two_msg[7])

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_SHOULDER and R_SHOULDER
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_SHOULDER).state
			local r_joint_info = get_joint_info(0, JOINTS.R_SHOULDER).state

			if (joint == JOINTS.L_SHOULDER or joint == JOINTS.R_SHOULDER) then
				if ((joint == JOINTS.L_SHOULDER and l_joint_info ~= JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.FORWARD) or
					(joint == JOINTS.R_SHOULDER and r_joint_info ~= JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.FORWARD)) then
					remove_hooks("conditions")
					set_timeout(1, function() relock_keyboard(3) lock_mouse() end_joint_alert() end)
					set_timeout(50, advance)
				end
			else
				return 1
			end
		elseif (key == string.byte('x')) then	-- x is locked on all joints but L_SHOULDER and R_SHOULDER
			local joint = get_world_state().selected_joint
			if (joint ~= JOINTS.L_SHOULDER and joint ~= JOINTS.R_SHOULDER) then
				return 1
			end
		elseif (key == string.byte('c')) then	-- c toggles L_SHOULDER, R_SHOULDER to hold
			set_joint_state(0, JOINTS.L_SHOULDER, JOINT_STATE.HOLD)
			set_joint_state(0, JOINTS.R_SHOULDER, JOINT_STATE.HOLD)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)

	local check_mousedown_conditions = function()
		local ws = get_world_state()
		local body = ws.selected_body
		local joint = ws.selected_joint

		if (body > -1 or (joint ~= JOINTS.L_SHOULDER and joint ~= JOINTS.R_SHOULDER)) then
			return 1
		end
	end
	add_hook("mouse_button_down", "conditions", check_mousedown_conditions)

	local check_mouseup_conditions = function()
		local l_joint_info = get_joint_info(0, JOINTS.L_SHOULDER).state
		local r_joint_info = get_joint_info(0, JOINTS.R_SHOULDER).state

		if (l_joint_info == JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.FORWARD) then
			relock_keyboard(3)
			lock_mouse()
			end_joint_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function part_two_6()
	unlock_mouse()

	start_hand_alert()

	local check_mousedown_conditions = function()
		local ws = get_world_state()
		local body = ws.selected_body
		local joint = ws.selected_joint

		if (joint > -1 or (body ~= BODYPARTS.L_HAND and body ~= BODYPARTS.R_HAND)) then
			return 1
		end
	end
	add_hook("mouse_button_down", "conditions", check_mousedown_conditions)

	local check_mouseup_conditions = function()
		local l_hand_info = get_grip_info(0, BODYPARTS.L_HAND)
		local r_hand_info = get_grip_info(0, BODYPARTS.R_HAND)

		if (l_hand_info == 0 and r_hand_info == 0) then
			lock_mouse()
			end_hand_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function part_two_7()
	relock_keyboard(2)
	remove_hooks("bodyparts")

	hand_joint_render = false

	set_message(part_two_msg[8], part_two_msg[9])

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			change_message(150, part_two_msg[10])
			set_timeout(150, start_button_alert)
			set_gameover_timelimit(-1)
			run_frames(500)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function part_two_8()
	set_message(part_two_msg[11], part_two_msg[12])

	set_timeout(0, function() start_button_alert(); stop_btn.enabled = true; end)
end

function terminate()
	tutorial_stage = 0

	-- Remove all custom hooks used in tutorial
	remove_hooks("tutorial")
	remove_hooks("mouse")
	remove_hooks("keylock")
	remove_hooks("mouselock")
	remove_hooks("bodyparts")
	remove_hooks("terminate")
	remove_hooks("conditions")

	-- Set back to stored options
	set_option("backgroundclick", default_background_click)
	set_option("autosave", default_autosave)
	set_option("text", default_footer_state)

	disable_player_select(-1)
	set_gameover_timelimit(4)

	run_cmd("option uke 1")
	run_cmd("set engagedistance 100")
	run_cmd("clear")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
end
function end_tutorial()
	terminate()

	echo("Access the Toribash Fight School from the link below!")
	echo("http://forum.toribash.com/forumdisplay.php?f=364")

	-- Run Basic Moves tutorial if player is beginner
	if (get_beginner() < 3) then
		run_cmd("option beginner 3")
		echo(" ")
		echo(" ")
		echo(" ")
		echo(" ")
		echo(" ")
		run_tutorial(3)
	else
		start_new_game()
	end
end


-- List of all the steps
steps = {
	introduction_1,
	introduction_2,
	part_one_1,
	part_one_2,
	part_one_3,
	part_one_4,
	part_one_5,
	part_two_1,
	part_two_2,
	part_two_3,
	part_two_4,
	part_two_5,
	part_two_6,
	part_two_7,
	part_two_8,
	end_tutorial,
}

-- This line triggers the tutorial
start_tutorial()