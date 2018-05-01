-- This tutorial randomly loads either bodybreaker or 3-piece tear and explains the step-by-step process of doing them

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
	percentage = string.format("%i%s", math.floor(cal), "% fait")
	if math.floor(cal) < 10 then
		draw_text(percentage, px + 14, py)
		draw_text(percentage, px + 15, py)
	else
		draw_text(percentage, px + 10, py)
		draw_text(percentage, px + 11, py)
	end
	-- Draw the button text
	set_color(0, 0, 0, 0.3)
	if (percentage == "100% fait") then
		draw_text("Prochain Tutoriel", next_btn.tx-13, next_btn.ty)
		draw_text("Prochain Tutoriel", next_btn.tx-12, next_btn.ty)
	else
		draw_text("Continuer", next_btn.tx+2, next_btn.ty)
		draw_text("Continuer", next_btn.tx+3, next_btn.ty)
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
	draw_text("Finir Entraînement", stop_btn.tx-30, stop_btn.ty)
	draw_text("Finir Entraînement", stop_btn.tx-29, stop_btn.ty)
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
			echo("Accéder l'école de lutte de Toribash en cliquant sur le lien ci-dessous!")
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
	"Tutorial : Mouvements avancés",
	"--------",
	"Apprenez quelques techniques de combat",
	"ou défiez Uke si vous êtes prêt!",
}
local bodybreaker_msg = {
	"Technique  :  Body Breaker",
	"Attrapez votre adversaire par la tête",
	"et mettez le en pièces!",
	"Suivez ces instructions",
	"pour reproduire le mouvement.",
	"Maintenez toutes vos articulations en appuyant sur 'C',",
	"étendez les deux chevilles,",
	"puis finissez le tour",
	"Contractez les deux pecs,",
	"mettez vos deux mains pour attraper,",
	"puis finissez le tour",
	"Contractez les deux hanches,",
	"et finissez le tour",
	"Finissez le tour encore une fois",
	"Contractez les deux genoux,",
	"Baissez les deux épaules,",
	"puis finissez le tour",
	"Etendez les deux genous,",
	"puis finissez le tour",
	"Félicitations!",
}
local threepiece_msg = {
	"Technique  :  Three Piece Tear",
	"Attrapez les bras de votre adversaire",
	"et mettez le en pièce!",
	"Suivez ces instructionss",
	"pour reproduire le mouvement",
	"Contractez les deux genoux,",
	"puis finissez le tour",
	"Finissez le tour encore une fois",
	"Levez les deux épaules,",
	"contractez les deux pecs,",
	"puis finissez le tour",
	"Maintenez toutes vos articulations en appuyant sur 'C',",
	"puis finissez le tour",
	"Tendez les deux genoux,",
	"puis finissez le tour",
	"Baissez les deux épaumes,",
	"attrapez avec vos deux mains,",
	"puis finissez le tour",
	"Contractez les deux hanches,",
	"puis finissez le tour",
	"Contractez les deux genoux,",
	"puis finissez le tour",
	"Tendez les deux pecs,",
	"levez les deux épaules,",
	"puis finissez le tour",
	"Tendez les deux coudes,",
	"lâchez avec vos deux mains,",
	"puis finissez le tour",
	"Bien joué!",
}

local default_background_click = 1
local default_footer_state = 1
local default_autosave = 1
steps = nil

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

	set_steps(math.random(1, 2))

	-- Start the tutorial
	set_timeout(100, advance)
end

function introduction()
	limit_camera = true

	set_message(intro_msg[1], intro_msg[2], intro_msg[3])

	set_timeout(0, start_button_alert)
end

function bodybreaker_1()
	remove_hooks("terminate")

	start_new_game()	-- This clears the settings for the previous replay
	set_gameover_timelimit(4)
	run_cmd("loadreplay system/tut_3-1.rpl")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	set_gameover_timelimit(-1)
	freeze_game()

	add_hook("leave_game", "terminate", terminate)

	limit_camera = false
	relock_keyboard(3)

	set_message(bodybreaker_msg[1])

	set_timeout(0, start_button_alert)
end
function bodybreaker_2()
	unfreeze_game()

	set_message(bodybreaker_msg[2], bodybreaker_msg[3])

	set_timeout(300, start_button_alert)
end
function bodybreaker_3()
	remove_hooks("terminate")

	set_gameover_timelimit(4)
	start_new_game()
	set_gameover_timelimit(-1)

	add_hook("leave_game", "terminate", terminate)

	reset_camera(1)

	set_message(bodybreaker_msg[4], bodybreaker_msg[5])

	set_timeout(0, start_button_alert)
end
function bodybreaker_4()
	relock_keyboard(1)
	unlock_mouse()
	add_hook("joint_select", "bodyparts", set_joint_tooltip)
	add_hook("body_select", "bodyparts", set_hand_tooltip)

	hand_joint_render = true

	set_message(bodybreaker_msg[6], bodybreaker_msg[7], bodybreaker_msg[8])

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
function bodybreaker_5()
	relock_keyboard(1)
	unlock_mouse()

	start_joint_alert(JOINTS.L_ANKLE, JOINTS.R_ANKLE)

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_ANKLE and R_ANKLE
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_ANKLE).state
			local r_joint_info = get_joint_info(0, JOINTS.R_ANKLE).state

			if (joint == JOINTS.L_ANKLE or joint == JOINTS.R_ANKLE) then
				if ((joint == JOINTS.L_ANKLE and l_joint_info == JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.BACK) or
					(joint == JOINTS.R_ANKLE and r_joint_info == JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.BACK)) then
					remove_hooks("conditions")
					set_timeout(1, function() relock_keyboard(3) lock_mouse() end_joint_alert() end)
					set_timeout(50, advance)
				end
			else
				return 1
			end
		elseif (key == string.byte('x')) then	-- x is locked on all joints but L_ANKLE and R_ANKLE
			local joint = get_world_state().selected_joint
			if (joint ~= JOINTS.L_ANKLE and joint ~= JOINTS.R_ANKLE) then
				return 1
			end
		elseif (key == string.byte('c')) then	-- c toggles L_ANKLE, R_ANKLE to hold
			set_joint_state(0, JOINTS.L_ANKLE, JOINT_STATE.HOLD)
			set_joint_state(0, JOINTS.R_ANKLE, JOINT_STATE.HOLD)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)

	local check_mousedown_conditions = function()
		local ws = get_world_state()
		local body = ws.selected_body
		local joint = ws.selected_joint

		if (body > -1 or (joint ~= JOINTS.L_ANKLE and joint ~= JOINTS.R_ANKLE)) then
			return 1
		end
	end
	add_hook("mouse_button_down", "conditions", check_mousedown_conditions)

	local check_mouseup_conditions = function()
		local l_joint_info = get_joint_info(0, JOINTS.L_ANKLE).state
		local r_joint_info = get_joint_info(0, JOINTS.R_ANKLE).state

		if (l_joint_info == JOINT_STATE.BACK and r_joint_info == JOINT_STATE.BACK) then
			relock_keyboard(3)
			lock_mouse()
			end_joint_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function bodybreaker_6()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function bodybreaker_7()
	relock_keyboard(1)
	unlock_mouse()

	local indicator = function(key)
		start_joint_alert(JOINTS.L_PECS, JOINTS.R_PECS)
		remove_hooks("indicator")
	end
	add_hook("enter_freeze", "indicator", indicator)

	set_message(bodybreaker_msg[9], bodybreaker_msg[10], bodybreaker_msg[11])

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_PECS and R_PECS
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_PECS).state
			local r_joint_info = get_joint_info(0, JOINTS.R_PECS).state

			if (joint == JOINTS.L_PECS or joint == JOINTS.R_PECS) then
				if ((joint == JOINTS.L_PECS and l_joint_info == JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.BACK) or
					(joint == JOINTS.R_PECS and r_joint_info == JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.BACK)) then
					remove_hooks("conditions")
					set_timeout(1, function() relock_keyboard(3) lock_mouse() end_joint_alert() end)
					set_timeout(50, advance)
				end
			else
				return 1
			end
		elseif (key == string.byte('x')) then	-- x is locked on all joints but L_PECS and R_PECS
			local joint = get_world_state().selected_joint
			if (joint ~= JOINTS.L_PECS and joint ~= JOINTS.R_PECS) then
				return 1
			end
		elseif (key == string.byte('c')) then	-- c toggles L_PECS, R_PECS to hold
			set_joint_state(0, JOINTS.L_PECS, JOINT_STATE.HOLD)
			set_joint_state(0, JOINTS.R_PECS, JOINT_STATE.HOLD)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)

	local check_mousedown_conditions = function()
		local ws = get_world_state()
		local body = ws.selected_body
		local joint = ws.selected_joint

		if (body > -1 or (joint ~= JOINTS.L_PECS and joint ~= JOINTS.R_PECS)) then
			return 1
		end
	end
	add_hook("mouse_button_down", "conditions", check_mousedown_conditions)

	local check_mouseup_conditions = function()
		local l_joint_info = get_joint_info(0, JOINTS.L_PECS).state
		local r_joint_info = get_joint_info(0, JOINTS.R_PECS).state

		if (l_joint_info == JOINT_STATE.BACK and r_joint_info == JOINT_STATE.BACK) then
			relock_keyboard(3)
			lock_mouse()
			end_joint_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function bodybreaker_8()
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

		if (l_hand_info == 1 and r_hand_info == 1) then
			lock_mouse()
			end_hand_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function bodybreaker_9()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function bodybreaker_10()
	relock_keyboard(1)
	unlock_mouse()

	local indicator = function(key)
		start_joint_alert(JOINTS.L_HIP, JOINTS.R_HIP)
		remove_hooks("indicator")
	end
	add_hook("enter_freeze", "indicator", indicator)

	set_message(bodybreaker_msg[12], bodybreaker_msg[13])

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_HIP and R_HIP
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_HIP).state
			local r_joint_info = get_joint_info(0, JOINTS.R_HIP).state

			if (joint == JOINTS.L_HIP or joint == JOINTS.R_HIP) then
				if ((joint == JOINTS.L_HIP and l_joint_info ~= JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.FORWARD) or
					(joint == JOINTS.R_HIP and r_joint_info ~= JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.FORWARD)) then
					remove_hooks("conditions")
					set_timeout(1, function() relock_keyboard(3) lock_mouse() end_joint_alert() end)
					set_timeout(50, advance)
				end
			else
				return 1
			end
		elseif (key == string.byte('x')) then	-- x is locked on all joints but L_HIP and R_HIP
			local joint = get_world_state().selected_joint
			if (joint ~= JOINTS.L_HIP and joint ~= JOINTS.R_HIP) then
				return 1
			end
		elseif (key == string.byte('c')) then	-- c toggles L_HIP, R_HIP to hold
			set_joint_state(0, JOINTS.L_HIP, JOINT_STATE.HOLD)
			set_joint_state(0, JOINTS.R_HIP, JOINT_STATE.HOLD)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)

	local check_mousedown_conditions = function()
		local ws = get_world_state()
		local body = ws.selected_body
		local joint = ws.selected_joint

		if (body > -1 or (joint ~= JOINTS.L_HIP and joint ~= JOINTS.R_HIP)) then
			return 1
		end
	end
	add_hook("mouse_button_down", "conditions", check_mousedown_conditions)

	local check_mouseup_conditions = function()
		local l_joint_info = get_joint_info(0, JOINTS.L_HIP).state
		local r_joint_info = get_joint_info(0, JOINTS.R_HIP).state

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
function bodybreaker_11()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function bodybreaker_12()
	relock_keyboard(2)

	set_message(bodybreaker_msg[14])

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function bodybreaker_13()
	relock_keyboard(1)
	unlock_mouse()

	local indicator = function(key)
		start_joint_alert(JOINTS.L_KNEE, JOINTS.R_KNEE)
		remove_hooks("indicator")
	end
	add_hook("enter_freeze", "indicator", indicator)

	set_message(bodybreaker_msg[15], bodybreaker_msg[16], bodybreaker_msg[17])

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_KNEE and R_KNEE
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_KNEE).state
			local r_joint_info = get_joint_info(0, JOINTS.R_KNEE).state

			if (joint == JOINTS.L_KNEE or joint == JOINTS.R_KNEE) then
				if ((joint == JOINTS.L_KNEE and l_joint_info == JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.BACK) or
					(joint == JOINTS.R_KNEE and r_joint_info == JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.BACK)) then
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

		if (l_joint_info == JOINT_STATE.BACK and r_joint_info == JOINT_STATE.BACK) then
			relock_keyboard(3)
			lock_mouse()
			end_joint_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function bodybreaker_14()
	relock_keyboard(1)
	unlock_mouse()

	start_joint_alert(JOINTS.L_SHOULDER, JOINTS.R_SHOULDER)

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
function bodybreaker_15()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function bodybreaker_16()
	relock_keyboard(2)

	set_message(bodybreaker_msg[14])

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function bodybreaker_17()
	relock_keyboard(1)
	unlock_mouse()

	local indicator = function(key)
		start_joint_alert(JOINTS.L_KNEE, JOINTS.R_KNEE)
		remove_hooks("indicator")
	end
	add_hook("enter_freeze", "indicator", indicator)

	set_message(bodybreaker_msg[18], bodybreaker_msg[19])

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
function bodybreaker_18()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			hand_joint_render = false
			set_timeout(150, advance)
			run_frames(500)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function bodybreaker_19()
	set_message(bodybreaker_msg[20])

	set_timeout(0, start_button_alert)
end
function bodybreaker_20()
	set_message(intro_msg[4], intro_msg[5])

	set_timeout(0, function() start_button_alert(); stop_btn.enabled = true; end)
end

function threepiece_1()
	remove_hooks("terminate")

	start_new_game()	-- This clears the settings for the previous replay
	set_gameover_timelimit(4)
	run_cmd("loadreplay system/tut_3-2.rpl")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	set_gameover_timelimit(-1)
	freeze_game()

	add_hook("leave_game", "terminate", terminate)

	limit_camera = false
	relock_keyboard(3)

	set_message(threepiece_msg[1])

	set_timeout(0, start_button_alert)
end
function threepiece_2()
	unfreeze_game()

	set_message(threepiece_msg[2], threepiece_msg[3])

	set_timeout(300, start_button_alert)
end
function threepiece_3()
	remove_hooks("terminate")

	set_gameover_timelimit(4)
	start_new_game()
	set_gameover_timelimit(-1)

	add_hook("leave_game", "terminate", terminate)

	reset_camera(1)

	set_message(threepiece_msg[4], threepiece_msg[5])

	set_timeout(0, start_button_alert)
end
function threepiece_4()
	relock_keyboard(1)
	unlock_mouse()
	add_hook("joint_select", "bodyparts", set_joint_tooltip)
	add_hook("body_select", "bodyparts", set_hand_tooltip)

	hand_joint_render = true

	start_joint_alert(JOINTS.L_KNEE, JOINTS.R_KNEE)

	set_message(threepiece_msg[6], threepiece_msg[7])

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_KNEE and R_KNEE
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_KNEE).state
			local r_joint_info = get_joint_info(0, JOINTS.R_KNEE).state

			if (joint == JOINTS.L_KNEE or joint == JOINTS.R_KNEE) then
				if ((joint == JOINTS.L_KNEE and l_joint_info == JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.BACK) or
					(joint == JOINTS.R_KNEE and r_joint_info == JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.BACK)) then
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

		if (l_joint_info == JOINT_STATE.BACK and r_joint_info == JOINT_STATE.BACK) then
			relock_keyboard(3)
			lock_mouse()
			end_joint_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function threepiece_5()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_6()
	relock_keyboard(2)

	set_message(threepiece_msg[8])

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_7()
	relock_keyboard(1)
	unlock_mouse()

	local indicator = function(key)
		start_joint_alert(JOINTS.L_SHOULDER, JOINTS.R_SHOULDER)
		remove_hooks("indicator")
	end
	add_hook("enter_freeze", "indicator", indicator)

	set_message(threepiece_msg[9], threepiece_msg[10], threepiece_msg[11])

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_SHOULDER and R_SHOULDER
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_SHOULDER).state
			local r_joint_info = get_joint_info(0, JOINTS.R_SHOULDER).state

			if (joint == JOINTS.L_SHOULDER or joint == JOINTS.R_SHOULDER) then
				if ((joint == JOINTS.L_SHOULDER and l_joint_info == JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.BACK) or
					(joint == JOINTS.R_SHOULDER and r_joint_info == JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.BACK)) then
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

		if (l_joint_info == JOINT_STATE.BACK and r_joint_info == JOINT_STATE.BACK) then
			relock_keyboard(3)
			lock_mouse()
			end_joint_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function threepiece_8()
	relock_keyboard(1)
	unlock_mouse()

	start_joint_alert(JOINTS.L_PECS, JOINTS.R_PECS)

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_PECS and R_PECS
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_PECS).state
			local r_joint_info = get_joint_info(0, JOINTS.R_PECS).state

			if (joint == JOINTS.L_PECS or joint == JOINTS.R_PECS) then
				if ((joint == JOINTS.L_PECS and l_joint_info == JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.BACK) or
					(joint == JOINTS.R_PECS and r_joint_info == JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.BACK)) then
					remove_hooks("conditions")
					set_timeout(1, function() relock_keyboard(3) lock_mouse() end_joint_alert() end)
					set_timeout(50, advance)
				end
			else
				return 1
			end
		elseif (key == string.byte('x')) then	-- x is locked on all joints but L_PECS and R_PECS
			local joint = get_world_state().selected_joint
			if (joint ~= JOINTS.L_PECS and joint ~= JOINTS.R_PECS) then
				return 1
			end
		elseif (key == string.byte('c')) then	-- c toggles L_PECS, R_PECS to hold
			set_joint_state(0, JOINTS.L_PECS, JOINT_STATE.HOLD)
			set_joint_state(0, JOINTS.R_PECS, JOINT_STATE.HOLD)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)

	local check_mousedown_conditions = function()
		local ws = get_world_state()
		local body = ws.selected_body
		local joint = ws.selected_joint

		if (body > -1 or (joint ~= JOINTS.L_PECS and joint ~= JOINTS.R_PECS)) then
			return 1
		end
	end
	add_hook("mouse_button_down", "conditions", check_mousedown_conditions)

	local check_mouseup_conditions = function()
		local l_joint_info = get_joint_info(0, JOINTS.L_PECS).state
		local r_joint_info = get_joint_info(0, JOINTS.R_PECS).state

		if (l_joint_info == JOINT_STATE.BACK and r_joint_info == JOINT_STATE.BACK) then
			relock_keyboard(3)
			lock_mouse()
			end_joint_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function threepiece_9()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_10()
	relock_keyboard(2)

	set_message(threepiece_msg[8])

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_11()
	relock_keyboard(1)
	unlock_mouse()

	set_message(threepiece_msg[12], threepiece_msg[13])

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
function threepiece_12()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_13()
	relock_keyboard(1)
	unlock_mouse()

	local indicator = function(key)
		start_joint_alert(JOINTS.L_KNEE, JOINTS.R_KNEE)
		remove_hooks("indicator")
	end
	add_hook("enter_freeze", "indicator", indicator)

	set_message(threepiece_msg[14], threepiece_msg[15])

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
function threepiece_14()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_15()
	relock_keyboard(1)
	unlock_mouse()

	local indicator = function(key)
		start_joint_alert(JOINTS.L_SHOULDER, JOINTS.R_SHOULDER)
		remove_hooks("indicator")
	end
	add_hook("enter_freeze", "indicator", indicator)

	set_message(threepiece_msg[16], threepiece_msg[17], threepiece_msg[18])

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
function threepiece_16()
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

		if (l_hand_info == 1 and r_hand_info == 1) then
			lock_mouse()
			end_hand_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function threepiece_17()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_18()
	relock_keyboard(2)

	set_message(threepiece_msg[8])

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_19()
	relock_keyboard(1)
	unlock_mouse()

	local indicator = function(key)
		start_joint_alert(JOINTS.L_HIP, JOINTS.R_HIP)
		remove_hooks("indicator")
	end
	add_hook("enter_freeze", "indicator", indicator)

	set_message(threepiece_msg[19], threepiece_msg[20])

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_HIP and R_HIP
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_HIP).state
			local r_joint_info = get_joint_info(0, JOINTS.R_HIP).state

			if (joint == JOINTS.L_HIP or joint == JOINTS.R_HIP) then
				if ((joint == JOINTS.L_HIP and l_joint_info ~= JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.FORWARD) or
					(joint == JOINTS.R_HIP and r_joint_info ~= JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.FORWARD)) then
					remove_hooks("conditions")
					set_timeout(1, function() relock_keyboard(3) lock_mouse() end_joint_alert() end)
					set_timeout(50, advance)
				end
			else
				return 1
			end
		elseif (key == string.byte('x')) then	-- x is locked on all joints but L_HIP and R_HIP
			local joint = get_world_state().selected_joint
			if (joint ~= JOINTS.L_HIP and joint ~= JOINTS.R_HIP) then
				return 1
			end
		elseif (key == string.byte('c')) then	-- c toggles L_HIP, R_HIP to hold
			set_joint_state(0, JOINTS.L_HIP, JOINT_STATE.HOLD)
			set_joint_state(0, JOINTS.R_HIP, JOINT_STATE.HOLD)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)

	local check_mousedown_conditions = function()
		local ws = get_world_state()
		local body = ws.selected_body
		local joint = ws.selected_joint

		if (body > -1 or (joint ~= JOINTS.L_HIP and joint ~= JOINTS.R_HIP)) then
			return 1
		end
	end
	add_hook("mouse_button_down", "conditions", check_mousedown_conditions)

	local check_mouseup_conditions = function()
		local l_joint_info = get_joint_info(0, JOINTS.L_HIP).state
		local r_joint_info = get_joint_info(0, JOINTS.R_HIP).state

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
function threepiece_20()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_21()
	relock_keyboard(2)

	set_message(threepiece_msg[8])

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_22()
	relock_keyboard(1)
	unlock_mouse()

	local indicator = function(key)
		start_joint_alert(JOINTS.L_KNEE, JOINTS.R_KNEE)
		remove_hooks("indicator")
	end
	add_hook("enter_freeze", "indicator", indicator)

	set_message(threepiece_msg[21], threepiece_msg[22])

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_KNEE and R_KNEE
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_KNEE).state
			local r_joint_info = get_joint_info(0, JOINTS.R_KNEE).state

			if (joint == JOINTS.L_KNEE or joint == JOINTS.R_KNEE) then
				if ((joint == JOINTS.L_KNEE and l_joint_info == JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.BACK) or
					(joint == JOINTS.R_KNEE and r_joint_info == JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.BACK)) then
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

		if (l_joint_info == JOINT_STATE.BACK and r_joint_info == JOINT_STATE.BACK) then
			relock_keyboard(3)
			lock_mouse()
			end_joint_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function threepiece_23()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_24()
	relock_keyboard(2)

	set_message(threepiece_msg[8])

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_25()
	relock_keyboard(2)

	set_message("and again...")

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_26()
	relock_keyboard(1)
	unlock_mouse()

	local indicator = function(key)
		start_joint_alert(JOINTS.L_PECS, JOINTS.R_PECS)
		remove_hooks("indicator")
	end
	add_hook("enter_freeze", "indicator", indicator)

	set_message(threepiece_msg[23], threepiece_msg[24], threepiece_msg[25])

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_PECS and R_PECS
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_PECS).state
			local r_joint_info = get_joint_info(0, JOINTS.R_PECS).state

			if (joint == JOINTS.L_PECS or joint == JOINTS.R_PECS) then
				if ((joint == JOINTS.L_PECS and l_joint_info ~= JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.FORWARD) or
					(joint == JOINTS.R_PECS and r_joint_info ~= JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.FORWARD)) then
					remove_hooks("conditions")
					set_timeout(1, function() relock_keyboard(3) lock_mouse() end_joint_alert() end)
					set_timeout(50, advance)
				end
			else
				return 1
			end
		elseif (key == string.byte('x')) then	-- x is locked on all joints but L_PECS and R_PECS
			local joint = get_world_state().selected_joint
			if (joint ~= JOINTS.L_PECS and joint ~= JOINTS.R_PECS) then
				return 1
			end
		elseif (key == string.byte('c')) then	-- c toggles L_PECS, R_PECS to hold
			set_joint_state(0, JOINTS.L_PECS, JOINT_STATE.HOLD)
			set_joint_state(0, JOINTS.R_PECS, JOINT_STATE.HOLD)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)

	local check_mousedown_conditions = function()
		local ws = get_world_state()
		local body = ws.selected_body
		local joint = ws.selected_joint

		if (body > -1 or (joint ~= JOINTS.L_PECS and joint ~= JOINTS.R_PECS)) then
			return 1
		end
	end
	add_hook("mouse_button_down", "conditions", check_mousedown_conditions)

	local check_mouseup_conditions = function()
		local l_joint_info = get_joint_info(0, JOINTS.L_PECS).state
		local r_joint_info = get_joint_info(0, JOINTS.R_PECS).state

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
function threepiece_27()
	relock_keyboard(1)
	unlock_mouse()

	start_joint_alert(JOINTS.L_SHOULDER, JOINTS.R_SHOULDER)

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_SHOULDER and R_SHOULDER
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_SHOULDER).state
			local r_joint_info = get_joint_info(0, JOINTS.R_SHOULDER).state

			if (joint == JOINTS.L_SHOULDER or joint == JOINTS.R_SHOULDER) then
				if ((joint == JOINTS.L_SHOULDER and l_joint_info == JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.BACK) or
					(joint == JOINTS.R_SHOULDER and r_joint_info == JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.BACK)) then
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

		if (l_joint_info == JOINT_STATE.BACK and r_joint_info == JOINT_STATE.BACK) then
			relock_keyboard(3)
			lock_mouse()
			end_joint_alert()
			remove_hooks("conditions")
			set_timeout(50, advance)
		end
	end
	add_hook("mouse_button_up", "conditions", check_mouseup_conditions)
end
function threepiece_28()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(0, advance)
			run_frames(10)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_29()
	relock_keyboard(1)
	unlock_mouse()

	local indicator = function(key)
		start_joint_alert(JOINTS.L_ELBOW, JOINTS.R_ELBOW)
		remove_hooks("indicator")
	end
	add_hook("enter_freeze", "indicator", indicator)

	set_message(threepiece_msg[26], threepiece_msg[27], threepiece_msg[28])

	local check_key_conditions = function(key)
		if (key == string.byte('z')) then	-- z is locked on all joints but L_ELBOW and R_ELBOW
			local joint = get_world_state().selected_joint
			local l_joint_info = get_joint_info(0, JOINTS.L_ELBOW).state
			local r_joint_info = get_joint_info(0, JOINTS.R_ELBOW).state

			if (joint == JOINTS.L_ELBOW or joint == JOINTS.R_ELBOW) then
				if ((joint == JOINTS.L_ELBOW and l_joint_info ~= JOINT_STATE.FORWARD and r_joint_info == JOINT_STATE.FORWARD) or
					(joint == JOINTS.R_ELBOW and r_joint_info ~= JOINT_STATE.FORWARD and l_joint_info == JOINT_STATE.FORWARD)) then
					remove_hooks("conditions")
					set_timeout(1, function() relock_keyboard(3) lock_mouse() end_joint_alert() end)
					set_timeout(50, advance)
				end
			else
				return 1
			end
		elseif (key == string.byte('x')) then	-- x is locked on all joints but L_ELBOW and R_ELBOW
			local joint = get_world_state().selected_joint
			if (joint ~= JOINTS.L_ELBOW and joint ~= JOINTS.R_ELBOW) then
				return 1
			end
		elseif (key == string.byte('c')) then	-- c toggles L_ELBOW, R_ELBOW to hold
			set_joint_state(0, JOINTS.L_ELBOW, JOINT_STATE.HOLD)
			set_joint_state(0, JOINTS.R_ELBOW, JOINT_STATE.HOLD)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)

	local check_mousedown_conditions = function()
		local ws = get_world_state()
		local body = ws.selected_body
		local joint = ws.selected_joint

		if (body > -1 or (joint ~= JOINTS.L_ELBOW and joint ~= JOINTS.R_ELBOW)) then
			return 1
		end
	end
	add_hook("mouse_button_down", "conditions", check_mousedown_conditions)

	local check_mouseup_conditions = function()
		local l_joint_info = get_joint_info(0, JOINTS.L_ELBOW).state
		local r_joint_info = get_joint_info(0, JOINTS.R_ELBOW).state

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
function threepiece_30()
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
function threepiece_31()
	relock_keyboard(2)

	local check_key_conditions = function(key)
		if (key == string.byte(' ')) then
			relock_keyboard(3)
			remove_hooks("conditions")
			set_timeout(150, advance)
			run_frames(500)
			return 1
		end
	end
	add_hook("key_up", "conditions", check_key_conditions)
end
function threepiece_32()
	set_message(threepiece_msg[29])

	set_timeout(0, start_button_alert)
end
function threepiece_33()
	set_message(intro_msg[4], intro_msg[5])

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
	remove_hooks("indicator")

	-- Set back to stored options
	set_option("backgroundclick", default_background_click)
	set_option("autosave", default_autosave)
	set_option("text", default_footer_state)

	disable_player_select(-1)
	set_gameover_timelimit(4)

	run_cmd("option uke 1")
	run_cmd("set engagedistance 100")
	run_cmd("clear")
end
function end_tutorial()
	terminate()

	echo("Access the Beginner Sanctuary from the link below!")
	echo("http://forum.toribash.com/forumdisplay.php?f=362")

	-- Run Basic Moves tutorial if player is beginner
	if (get_beginner() < 4) then
		run_cmd("option beginner 4")
		run_tutorial(4)
	else
		start_new_game()
	end
end

function set_steps(set)
	if (set == 1) then
		steps = {
			introduction,
			bodybreaker_1,
			bodybreaker_2,
			bodybreaker_3,
			bodybreaker_4,
			bodybreaker_5,
			bodybreaker_6,
			bodybreaker_7,
			bodybreaker_8,
			bodybreaker_9,
			bodybreaker_10,
			bodybreaker_11,
			bodybreaker_12,
			bodybreaker_13,
			bodybreaker_14,
			bodybreaker_15,
			bodybreaker_16,
			bodybreaker_17,
			bodybreaker_18,
			bodybreaker_19,
			bodybreaker_20,
			end_tutorial,
		}
	elseif (set == 2) then
		steps = {
			introduction,
			threepiece_1,
			threepiece_2,
			threepiece_3,
			threepiece_4,
			threepiece_5,
			threepiece_6,
			threepiece_7,
			threepiece_8,
			threepiece_9,
			threepiece_10,
			threepiece_11,
			threepiece_12,
			threepiece_13,
			threepiece_14,
			threepiece_15,
			threepiece_16,
			threepiece_17,
			threepiece_18,
			threepiece_19,
			threepiece_20,
			threepiece_21,
			threepiece_22,
			threepiece_23,
			threepiece_24,
			threepiece_25,
			threepiece_26,
			threepiece_27,
			threepiece_28,
			threepiece_29,
			threepiece_30,
			threepiece_31,
			threepiece_32,
			threepiece_33,
			end_tutorial,
		}
	else
		steps = {
			introduction,
			end_tutorial,
		}
	end
end

start_tutorial()
