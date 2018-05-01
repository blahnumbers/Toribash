
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
		"Um movimento simples ensinado a mim por Gman80",
		"Irei chutá-lo para fora do ringue!",
	},
	{
		"O Infame chute de Aikido de FNugget!",
		"Elevando-o com meu braço esquerdo, eu o levantarei com minha perna direita ao mesmo tempo.",
		"Aproveite a queda livre!",
	},
	{
		"evil arquitetou este movimento.",
		"Eu o arremessarei para o chão!",
	},
	{
		"Um começo básico em que eu viro meu corpo, o seguro e me preparo para chutar.",
		"Chutando-o, consigo elevá-lo do chão. Também posso levantar meu braço para aumentar o momentum.",
		"Agora eu forço meu quadril para que minhas pernas estejam bem apoiadas.",
		"Por fim, relaxarei meu peito esquerdo para que meu braço abaixe um pouco para formar outro suporte para meu corpo.",
		"Esse movimento foi explicado por Kyat!",
	},
	{
		"evil arquitetou este movimento.",
		"Eu vou empurrá-lo para o chão!",
	},
	{
		"evil arquitetou este movimento.",
		"Eu vou empurrá-lo para fora do ringue!",
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
			echo("^07<^05Uke^07> Você venceu... Agora você enfrentará o inferno!")
			return 1
		elseif (winner == 1) then	-- uke won
			activate_uke()
		else
			run_cmd("lm classic.tbm")
			run_cmd("clear")
			echo("^07<^05Uke^07> Isso é tudo que você tem? É melhor fugir! *gargalhada maléfica*")
			echo(" ")
			echo("Está achando difícil derrotar o Uke?")
			echo("Visite o link abaixo para dicas e truques!")
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
	echo("^07<^05Uke^07> É hora da revanche!")
	echo("^07<^05Uke^07> Isso não vai parar até que você vença ou fuja!")

	chosen_combo = 0
	move = 0
	hint = 0

	choose_combo()
end


activate_uke()
