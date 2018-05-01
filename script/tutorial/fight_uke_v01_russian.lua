
local chosen_combo = 0
local move = 0
local hint = 0

local translate = nil
local width, height = get_window_size()
local name = nil


local combo = {
	{
	{ grip = { 1, 0 }, joint = { 3, 2, 3, 3, 2, 3, 3, 1, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 3, 3 } },	-- combo[1][1]
	{ grip = { 1, 0 }, joint = { 3, 2, 3, 3, 2, 3, 3, 1, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 3, 3 } },
	{ grip = { 0, 0 }, joint = { 3, 2, 3, 3, 2, 3, 3, 1, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 3, 3 } },
	{ grip = { 0, 0 }, joint = { 3, 2, 3, 3, 3, 3, 3, 1, 3, 3, 3, 3, 2, 1, 3, 3, 3, 3, 3, 3 } },
	{ grip = { 0, 0 }, joint = { 3, 2, 3, 3, 3, 3, 3, 1, 3, 3, 3, 3, 2, 3, 3, 3, 3, 3, 3, 3 } },
	},
	{
	{ grip = { 0, 1 }, joint = { 1, 1, 1, 2, 1, 3, 2, 2, 4, 4, 1, 4, 2, 2, 1, 2, 2, 3, 2, 2 } },	-- combo[2][1]
	{ grip = { 0, 1 }, joint = { 1, 1, 1, 3, 1, 3, 2, 2, 2, 1, 1, 1, 2, 2, 1, 2, 1, 3, 2, 2 } },
	{ grip = { 0, 1 }, joint = { 1, 4, 2, 1, 4, 1, 1, 4, 2, 1, 1, 1, 1, 2, 1, 2, 2, 1, 1, 4 } },
	},
	{
	{ grip = { 0, 0 }, joint = { 4, 4, 4, 4, 2, 4, 4, 2, 4, 4, 4, 4, 2, 2, 4, 4, 2, 2, 4, 4 } },	-- combo[5][1]
	{ grip = { 1, 1 }, joint = { 3, 2, 3, 3, 4, 3, 3, 4, 3, 4, 3, 3, 2, 3, 4, 1, 3, 3, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 1, 2, 3, 1, 3, 2, 2, 3, 4, 3, 3, 2, 1, 2, 2, 1, 4, 3, 1 } },
	{ grip = { 1, 1 }, joint = { 3, 1, 2, 2, 1, 1, 2, 2, 2, 4, 3, 3, 1, 2, 2, 2, 1, 4, 3, 1 } },
	{ grip = { 1, 1 }, joint = { 3, 1, 2, 2, 1, 2, 2, 2, 2, 4, 3, 3, 2, 2, 1, 2, 4, 4, 2, 1 } },
	{ grip = { 1, 1 }, joint = { 3, 1, 2, 2, 1, 2, 1, 2, 2, 2, 2, 3, 1, 1, 2, 2, 2, 4, 2, 2 } },
	},
	{
	{ grip = { 1, 0 }, joint = { 3, 2, 2, 3, 2, 3, 3, 1, 3, 3, 1, 3, 2, 2, 2, 1, 3, 2, 3, 3 } },	-- combo[6][1]
	{ grip = { 1, 0 }, joint = { 3, 2, 2, 3, 2, 3, 3, 1, 3, 3, 1, 3, 2, 2, 2, 1, 3, 1, 3, 3 } },
	{ grip = { 1, 0 }, joint = { 3, 2, 2, 3, 2, 2, 3, 1, 3, 3, 1, 3, 1, 1, 2, 3, 3, 1, 3, 3 } },
	{ grip = { 1, 0 }, joint = { 3, 2, 2, 3, 2, 2, 3, 4, 3, 3, 1, 3, 1, 1, 2, 3, 3, 1, 3, 3 } },
	},
	{
	{ grip = { 0, 0 }, joint = { 4, 4, 4, 4, 2, 4, 4, 2, 4, 4, 4, 4, 2, 2, 4, 4, 2, 2, 4, 4 } },	-- combo[7][1]
	{ grip = { 1, 1 }, joint = { 3, 2, 3, 3, 4, 3, 3, 4, 3, 3, 3, 3, 3, 3, 4, 1, 4, 3, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 2, 3, 2, 2, 3, 3, 1, 1, 3, 3, 3, 3, 3, 2, 1, 1, 4, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 2, 3, 2, 2, 3, 3, 1, 1, 3, 3, 3, 3, 3, 2, 2, 1, 1, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 2, 1, 2, 2, 3, 3, 1, 1, 2, 3, 1, 3, 3, 2, 2, 1, 1, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 2, 1, 2, 2, 3, 3, 1, 1, 2, 3, 1, 3, 3, 2, 2, 1, 1, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 2, 1, 2, 2, 3, 2, 1, 1, 2, 1, 1, 3, 3, 2, 4, 1, 4, 2, 3 } },
	},
	{
	{ grip = { 0, 0 }, joint = { 4, 2, 2, 4, 2, 1, 4, 4, 4, 4, 4, 4, 2, 4, 2, 4, 4, 4, 4, 4 } },	-- combo[8][1]
	{ grip = { 1, 0 }, joint = { 4, 2, 2, 4, 2, 2, 4, 4, 4, 4, 4, 4, 2, 4, 2, 1, 4, 4, 4, 4 } },
	{ grip = { 1, 1 }, joint = { 4, 1, 2, 4, 1, 2, 4, 2, 2, 4, 4, 4, 1, 1, 1, 2, 1, 1, 4, 1 } },
	{ grip = { 1, 1 }, joint = { 4, 1, 2, 4, 1, 2, 4, 2, 2, 4, 4, 4, 1, 1, 1, 2, 1, 1, 4, 1 } },
	{ grip = { 1, 1 }, joint = { 4, 1, 1, 4, 1, 2, 4, 2, 1, 4, 4, 4, 2, 1, 1, 1, 1, 1, 4, 1 } },
	},
}

local advice = {
	{
		"Простое движение, которое мне показал Gman80.",
		"Я сейчас кикну тебя за пределы доджо!",
	},
	{
		"Это получивший дурную славу киклифт FNugget'а!",
		"Я одновременно лифчу тебя своей левой рукой и ставлю ^07подножку правой ногой.",
		"Наслаждайся падением!",
	},
	{
		"Evilperson придумал это движение.",
		"Я собираюсь перекинуть тебя через себя!",
	},
	{
		"Простой опенер, когда я разворачиваю своё тело, захватываю ^07тебя и готовлюсь к кику.",
		"Удар ногой поднимает тебя с пола. Я также могу поднять свою ^07руку, чтобы сделать движение результативнее.",
		"Сейчас я напрягаю свои бёдра, так что мои ноги подготовлены к посадке.",
		"Под конец, я расслабляю левый сустав груди так, чтобы рука ^07опустилась вниз и стала точкой опоры.",
		"Это движение мне было рассказано Kyat'ом!",
	},
	{
		"Evilperson придумал это движение.",
		"Я собираюсь толкнуть тебя на пол!",
	},
	{
		"Evilperson придумал это движение.",
		"Я собираюсь вытолкнуть тебя за пределы доджо!",
	},
}


function do_combo_move()
	move = move + 1
	if (combo[chosen_combo][move] ~= nil) then
		for i, v in ipairs(combo[chosen_combo][move].grip) do
			set_grip_info(1, i+10, v)
		end
		for i, v in ipairs(combo[chosen_combo][move].joint) do
			set_joint_state(1, i-1, v)
		end
	end
end
function redo_combo_move()
	if (combo[chosen_combo][move] ~= nil) then
		for i, v in ipairs(combo[chosen_combo][move].grip) do
			set_grip_info(1, i+10, v)
		end
		for i, v in ipairs(combo[chosen_combo][move].joint) do
			set_joint_state(1, i-1, v)
		end
	end
end
function speak()
	hint = hint + 1
	if (advice[chosen_combo][hint] ~= nil) then
		echo("<^05Uke^07> " .. advice[chosen_combo][hint])
	end
end
function check_victory()
	remove_hooks("fight uke")

	local winner = get_world_state().winner

	local redirect = function()
		remove_hooks("redirect")
		if (winner == 0) then	-- tori won
			echo("<^05Uke^07> Ты победил... Теперь тебе придётся отправиться в ад!")
			join_room = math.random(1,8)
			if (join_room == 1) then
				run_cmd("join aikido2")
			elseif (join_room == 2) then
				run_cmd("join judo2")
			elseif (join_room == 3) then
				run_cmd("join judo1")
			elseif (join_room == 4) then
				run_cmd("join lenshu1")
			elseif (join_room == 5) then
				run_cmd("join taekkyon2")
			elseif (join_room == 6) then
				run_cmd("join jousting1")
			elseif (join_room == 7) then
				run_cmd("join twinsword1")
			else
				run_cmd("join aikido1")
			end
			return 1
		elseif (winner == 1) then	-- uke won
			activate_uke()
		else
			remove_hooks ("translate")
			run_cmd("lm classic.tbm")
			run_cmd("option feedback 1")
			run_cmd("clear")
			echo("<^05Uke^07> Если это всё, что ты можешь сделать, беги прочь! *злой смех*")
			echo(" ")
			echo("Не можешь справиться с Uke?")
			echo("Посети русскоязычный раздел форума и тебе там помогут!")
			echo("http://forum.toribash.com/forumdisplay.php?f=672")
		end
		refresh_chat_cache()
	end
	add_hook("new_game", "redirect", redirect)
end


function choose_combo()
	chosen_combo = math.random(1, #combo)

	do_combo_move()
end


function activate_uke()
	reset_camera(1)

	set_option("autosave", 0)
	set_option("text", 1)

	set_gameover_timelimit(4)

	start_new_game()	-- This clears the settings for the previous replay
	run_cmd("lm aikido.tbm")
	run_cmd("option uke 1")
	run_cmd("option name 1")
	run_cmd("option score 1")
	run_cmd("option timer 1")
	run_cmd("option feedback 0")
	run_cmd("clear")

	add_hook("enter_freeze", "fight uke", do_combo_move)
	add_hook("exit_freeze", "fight uke", function() redo_combo_move(); speak(); end)
	add_hook("leave_game", "fight uke", check_victory)

	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo("<^05Uke^07> Время расплаты!")
	echo("<^05Uke^07> Это не закончится, пока ты не победишь или не убежишь прочь!")

	chosen_combo = 0
	move = 0
	hint = 0

	choose_combo()
end

local function set_translate(player, joint)
	if (joint ~= -1) then
		translate = { }
		translate['player'] = player
		translate['joint'] = joint
		translate['joint_info'] = get_joint_info(player, joint)
		translate['pos'] = { x=0, y=0 }
		translate['pos'].x, translate['pos'].y = get_joint_screen_pos(player, joint)
			else
		translate = nil
	end
end

local function draw_translate()

	set_color(0, 0, 0, 0.9) 
	if (translate ~= nil and get_world_state().replay_mode == 0) then
	
	--Bodyparts
	if (string.find(translate.joint_info.name, "LEFT PECS")) then
		name = "Левая грудь"
	end
	if (string.find(translate.joint_info.name, "RIGHT PECS")) then
		name = "Правая грудь"
	end
	if (string.find(translate.joint_info.name, "LEFT SHOULDER")) then
		name = "Левое плечо"
	end
	if (string.find(translate.joint_info.name, "RIGHT SHOULDER")) then
		name = "Правое плечо"
	end
	if (string.find(translate.joint_info.name, "LEFT ELBOW")) then
		name = "Левый локоть"
	end
	if (string.find(translate.joint_info.name, "RIGHT ELBOW")) then
		name = "Правый локоть"
	end
	if (string.find(translate.joint_info.name, "LEFT WRIST")) then
		name = "Левое запястье"
	end
	if (string.find(translate.joint_info.name, "RIGHT WRIST")) then
		name = "Правое запястье"
	end
	if (string.find(translate.joint_info.name, "NECK")) then
		name = "Шея"
	end
	if (string.find(translate.joint_info.name, "CHEST")) then
		name = "Грудная клетка"
	end
	if (string.find(translate.joint_info.name, "LUMBAR")) then
		name = "Поясница"
	end
	if (string.find(translate.joint_info.name, "ABS")) then
		name = "Пресс"
	end
	if (string.find(translate.joint_info.name, "LEFT GLUTE")) then
		name = "Левая ягодица"
	end
	if (string.find(translate.joint_info.name, "RIGHT GLUTE")) then
		name = "Правая ягодица"
	end
	if (string.find(translate.joint_info.name, "LEFT HIP")) then
		name = "Левое бедро"
	end
	if (string.find(translate.joint_info.name, "RIGHT HIP")) then
		name = "Правое бедро"
	end
	if (string.find(translate.joint_info.name, "LEFT KNEE")) then
		name = "Левое колено"
	end
	if (string.find(translate.joint_info.name, "RIGHT KNEE")) then
		name = "Правое колено"
	end
	if (string.find(translate.joint_info.name, "LEFT ANKLE")) then
		name = "Левая лодыжка"
	end
	if (string.find(translate.joint_info.name, "RIGHT ANKLE")) then
		name = "Правая лодыжка"
	end
	
	--States
	if (translate.joint_info.name == "NECK" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "NECK" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. "  РАССЛАБЛЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "NECK" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. "  НАКЛОНЯЕТСЯ ВНИЗ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "NECK" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. "  ПОДНИМАЕТСЯ ВВЕРХ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "CHEST" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "CHEST" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "CHEST" and get_joint_info(translate.player, translate.joint).screen_state == "RIGHT ROTATING") then
		draw_centered_text(name .. " ПОВОРАЧИВАЕТСЯ ВПРАВО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "CHEST" and get_joint_info(translate.player, translate.joint).screen_state == "LEFT ROTATING") then
		draw_centered_text(name .. " ПОВОРАЧИВАЕТСЯ ВЛЕВО", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "LUMBAR" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LUMBAR" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LUMBAR" and get_joint_info(translate.player, translate.joint).screen_state == "RIGHT BENDING") then
		draw_centered_text(name .. " СГИБАЕТСЯ ВПРАВО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LUMBAR" and get_joint_info(translate.player, translate.joint).screen_state == "LEFT BENDING") then
		draw_centered_text(name .. " СГИБАЕТСЯ ВЛЕВО", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "ABS" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЁН", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "ABS" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕН", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "ABS" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " НАКЛОНЯЕТСЯ ВПЕРЕД", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "ABS" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " НАКЛОНЯЕТСЯ НАЗАД", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "RIGHT PECS" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT PECS" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT PECS" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT PECS" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "LEFT PECS" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT PECS" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT PECS" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT PECS" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "RIGHT SHOULDER" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT SHOULDER" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT SHOULDER" and get_joint_info(translate.player, translate.joint).screen_state == "LOWERING") then
		draw_centered_text(name .. " ОПУСКАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT SHOULDER" and get_joint_info(translate.player, translate.joint).screen_state == "RAISING") then
		draw_centered_text(name .. " ПОДНИМАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "LEFT SHOULDER" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT SHOULDER" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT SHOULDER" and get_joint_info(translate.player, translate.joint).screen_state == "LOWERING") then
		draw_centered_text(name .. " ОПУСКАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT SHOULDER" and get_joint_info(translate.player, translate.joint).screen_state == "RAISING") then
		draw_centered_text(name .. " ПОДНИМАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "RIGHT ELBOW" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЁН", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT ELBOW" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕН", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT ELBOW" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT ELBOW" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "LEFT ELBOW" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЁН", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT ELBOW" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕН", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT ELBOW" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT ELBOW" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "RIGHT WRIST" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT WRIST" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT WRIST" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT WRIST" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "LEFT WRIST" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT WRIST" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT WRIST" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT WRIST" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "RIGHT GLUTE" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT GLUTE" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT GLUTE" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT GLUTE" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "LEFT GLUTE" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT GLUTE" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT GLUTE" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT GLUTE" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "RIGHT HIP" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT HIP" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT HIP" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT HIP" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "LEFT HIP" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT HIP" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT HIP" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT HIP" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "RIGHT KNEE" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT KNEE" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT KNEE" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT KNEE" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "LEFT KNEE" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT KNEE" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНО", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT KNEE" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT KNEE" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "RIGHT ANKLE" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT ANKLE" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT ANKLE" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "RIGHT ANKLE" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	if (translate.joint_info.name == "LEFT ANKLE" and get_joint_info(translate.player, translate.joint).screen_state == "HOLDING") then
		draw_centered_text(name .. " НАПРЯЖЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT ANKLE" and get_joint_info(translate.player, translate.joint).screen_state == "RELAXING") then
		draw_centered_text(name .. " РАССЛАБЛЕНА", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT ANKLE" and get_joint_info(translate.player, translate.joint).screen_state == "CONTRACTING") then
		draw_centered_text(name .. " СГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end		
	if (translate.joint_info.name == "LEFT ANKLE" and get_joint_info(translate.player, translate.joint).screen_state == "EXTENDING") then
		draw_centered_text(name .. " РАЗГИБАЕТСЯ", height - 60, FONTS.MEDIUM)
	end	
	
	end
end

add_hook("joint_select", "translate", set_translate)
add_hook("draw2d", "translate", draw_translate)
activate_uke()
