
local chosen_combo = 0
local move = 0
local hint = 0


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
		"Un mouvement simple, qui m'a été appris par Gman80.",
		"Mon coup de pied va te pousser en dehors du ring!",
	},
	{
		"L'infernal Aikido Kick Lift de FNugget!",
		"Je vous soulève avec mon bras gauche, et je vous soulève avec ma jambe droite en même temps.",
		"Chute libre!",
	},
	{
		"evil m'a appris ce mouvement.",
		"Je vais te pousser par terre!",
	},
	{
		"Un opener basique où je tourne mon corps, vous attrape et me prépare à mettre un coup de pied.",
		"Mettre un coup de pied vous soulève du sol. Je peux aussi lever mon bras pour améliorer le momentum.",
		"Maintenant je maintiens ma hanche, pour que mes jambes soient stables et pour rester en équilibre.",
		"Finalement, je relaxe mon pec gauche pour que mon bras me procure un appui supplémentaire.",
		"Ce mouvement a été expliqué par Kyat!",
	},
	{
		"evil a crée ce mouvement.",
		"Je vais te pousser par terre!",
	},
	{
		"evil a crée ce mouvement.",
		"Je vais te pousser en dehors du ring!",
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
		echo("^07<^05Uke^07> " .. advice[chosen_combo][hint])
	end
end
function check_victory()
	remove_hooks("fight uke")

	local winner = get_world_state().winner

	local redirect = function()
		remove_hooks("redirect")
		if (winner == 0) then	-- tori won
			run_cmd("option beginner 5")
			join_room = math.random(1,8)
			if (join_room == 1) then
				run_cmd("join aikido2")
			elseif (join_room == 2) then
				run_cmd("join judo2")
			elseif (join_room == 3) then
				run_cmd("join judo1")
			elseif (join_room == 4) then
				run_cmd("join aikido1b")
			elseif (join_room == 5) then
				run_cmd("join judo1b")
			elseif (join_room == 6) then
				run_cmd("join lenshu1")
			elseif (join_room == 7) then
				run_cmd("join taekkyon2")
			else
				run_cmd("join aikido1")
			end
			echo(" ")
			echo(" ")
			echo(" ")
			echo(" ")
			echo("^07<^05Uke^07> Tu avais gagné... Maintenant, tu fera face à l'enfer!")
			return 1
		elseif (winner == 1) then	-- uke won
			activate_uke()
		else
			run_cmd("lm classic.tbm")
			run_cmd("clear")
			echo("^07<^05Uke^07> Si c'est tout ce que tu avais, avant de s'enfuir! *rire diabolique*")
			echo(" ")
			echo("Trouve Uke trop difficile à battre?")
			echo("Visitez le lien ci-dessous pour obtenir des conseils et astuces!")
			echo("http://forum.toribash.com/forumdisplay.php?f=364")
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
	run_cmd("option hint 1")
	run_cmd("option name 1")
	run_cmd("option score 1")
	run_cmd("option timer 1")
	run_cmd("option feedback 1")
	run_cmd("clear")

	add_hook("enter_freeze", "fight uke", do_combo_move)
	add_hook("exit_freeze", "fight uke", function() redo_combo_move(); speak(); end)
	add_hook("leave_game", "fight uke", check_victory)

	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	echo("^07<^05Uke^07> Il est temps de se venger!")
	echo("^07<^05Uke^07> Ce ne sera pas arrêter jusqu'à ce que vous gagnez ou à fuir!")

	chosen_combo = 0
	move = 0
	hint = 0

	choose_combo()
end


activate_uke()
