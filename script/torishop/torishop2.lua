dofile ("gui/image.lua")

TORISHOP_ISOPEN = 1

-- Global
local width, height = get_window_size()
local options = { backgroundclick = 0, name = 0, timer = 0, uke = 0, score = 0, hint = 0, feedback = 0 }

local items_per_shelf = math.floor((height-400)/100)*4
local sale_items_per_shelf = math.floor((height-400)/100)
local items_per_shelf_next = math.floor((height-450)/100)*4

local main_page = true
local main_view = 0
local details_name = nil

local position = height - 240
local step = 80

local first = true
local change_section_first = { }
local change_announcement = true

local BTN_UP = 1
local BTN_HOVER = 2
local BTN_DOWN = 3

local current_section = 1
local current_shelf = 1
local total_shelves = 0
local total_shelves_all = 0
local total_shelves_all2 = 0

local confirm_name = nil
local confirm_id = nil

-- Data Initializing
local data_types = { "catid", "catname", "itemid", "itemname", "on_sale", "now_tc_price", "now_usd_price", "price", "price_usd", "sale_time", "sale_promotion", "qi", "tier", "subscriptionid", "ingame", "colorid", "hidden", "locked" }
local data_table = {}		-- this will store the item data obtained from torishop.txt
local data_table_usd = {}
local data_table_lines = 0
local data_table_usd_lines = 0
local data_exists = false

local name = get_master().master.nick
local player_name = get_master().master.nick
local qi = nil
local tc = nil
local belt = "unidentified belt"
local belt_next = "unidentified belt"

local name_ss = "none"
local size_ss = 0
local ss_shift = 0

local sub_in_section = 0

local grip_color = 0
local color_r = nil
local color_g = nil
local color_b = nil

local timer_custom_color = false
local usertext_custom_color = false
local can_buy = nil
local buysteam = false
local purchase_button = nil

local cart = { 0 }
local cart_current = 0
local cart_button = nil
local cart_slide = 0
local cart_sum = 0
local cart_shift = 0
local cart_warning = {false, false}
local warning_flag = false
local transparency = 0
local cart_icon = {}
local cart_minimize = false
local cart_type = nil
local cartremovestate = {}
local SINGLE_ITEM = 0
local CART_ITEMS = 1

local items_all, items = 0, 0
local items_nextqi = 0
local hellomessage = math.random(1,3)

local icon = {}
local pos_icon = {}
local ss_icon = {}
local effects_option = get_option("effects")

local tempinfo = { force = 0, relax = 0, primary = 0, secondary = 0, torso = 0, blood = 0, ghost = 0, rhmt = 0, lhmt = 0, rlmt = 0, llmt = 0, dq = 0, grip = 0, timer = 0, text = 0, emote = 0, hair = 0 }
local tempflag = 0

local buy_type = SINGLE_ITEM

local sale = false
local sale_timer = os.time()
local sale_icon = nil

local wait_for_update = 0
local wait_warning = 1
local warning_time = os.time()
local is_grip = 0

local head_texture_choose = false
local featuredseed = math.random(0,1)

-- use to check toribooster text. use this if the default string.find or string.match does not work
function verify_same_string(string_to_check, the_string)
	for i=1, string.len(string_to_check) do
		if string.byte (the_string, i) ~= string.byte (string_to_check, i) then
			return 0
		end
	end
	return 1
end

function errormessage()
	set_color(1,1,1,0.8)
	draw_quad(0,0,width,height) 
	set_color(0,0,0,1)
	if (height <= 1100) then
	draw_centered_text("Please log in with your", height/2-65, FONTS.BIG)
	draw_centered_text("Toribash account", height/2, FONTS.BIG)
	draw_centered_text("to be able to use Torishop", height/2+65, FONTS.BIG)
	draw_centered_text("Please log in with your", height/2-65, FONTS.BIG)
	draw_centered_text("Toribash account", height/2, FONTS.BIG)
	draw_centered_text("to be able to use Torishop", height/2+65, FONTS.BIG)
	else
	draw_centered_text("Please log in with your Toribash account", height/2-50, FONTS.BIG)
	draw_centered_text("to be able to use Torishop", height/2+50, FONTS.BIG)
	draw_centered_text("Please log in with your Toribash account", height/2-50, FONTS.BIG)
	draw_centered_text("to be able to use Torishop", height/2+50, FONTS.BIG)
	end
end

function get_playerinfo()
	if string.find(name, "]") then
		name = string.sub(name, string.find(name, "]") + 1)
	end
    local file = io.open("custom/" .. name .. "/item.dat", 'r', 60)
	if (file == nil) then
		qi = 0
		tc = 0
		return
	end
		
    for ln in file:lines() do
		if string.match(ln, "^BELT 0;") then
			qi = string.gsub(ln, "BELT 0;", "")
			qi = tonumber(qi)
        end
		if string.match(ln, "^TC 0;") then
			tc = string.gsub(ln, "TC 0;", "")
			for i=10000, 0, -50 do
			tc = string.gsub(tc, " "..i, "")
			end
			tc = string.gsub(tc, " 10", "")
			tc = tonumber(tc)
		end
    end
    file:close()
	
	if ((qi >= 0) and (qi < 20)) then belt = "White Belt" qi_next = 20 belt_next = "Yellow Belt"
	elseif ((qi >= 20) and (qi < 50)) then belt = "Yellow Belt" qi_next = 50 belt_next = "Orange Belt"
	elseif ((qi >= 50) and (qi < 100)) then belt = "Orange Belt" qi_next = 100 belt_next = "Green Belt"
	elseif ((qi >= 100) and (qi < 200)) then belt = "Green Belt" qi_next = 200 belt_next = "Blue Belt"
	elseif ((qi >= 200) and (qi < 500)) then belt = "Blue Belt" qi_next = 500 belt_next = "Brown Belt"
	elseif ((qi >= 500) and (qi < 1000)) then belt = "Brown Belt" qi_next = 1000 belt_next = "Black Belt"
	elseif ((qi >= 1000) and (qi < 2000)) then belt = "Black Belt" qi_next = 2000 belt_next = "2nd Dan"
	elseif ((qi >= 2000) and (qi < 3000)) then belt = "2nd Dan" qi_next = 3000 belt_next = "3rd Dan"
	elseif ((qi >= 3000) and (qi < 4000)) then belt = "3rd Dan" qi_next = 4000 belt_next = "4th Dan"
	elseif ((qi >= 4000) and (qi < 5000)) then belt = "4th Dan" qi_next = 5000 belt_next = "5th Dan"
	elseif ((qi >= 5000) and (qi < 6000)) then belt = "5th Dan" qi_next = 6000 belt_next = "6th Dan"
	elseif ((qi >= 6000) and (qi < 7000)) then belt = "6th Dan" qi_next = 7000 belt_next = "7th Dan"
	elseif ((qi >= 7000) and (qi < 8000)) then belt = "7th Dan" qi_next = 8000 belt_next = "8th Dan"
	elseif ((qi >= 8000) and (qi < 9000)) then belt = "8th Dan" qi_next = 9000 belt_next = "9th Dan"
	elseif ((qi >= 9000) and (qi < 10000)) then belt = "9th Dan" qi_next = 10000 belt_next = "10th Dan"
	elseif ((qi >= 10000) and (qi < 15000)) then belt = "10th Dan" qi_next = 15000 belt_next = "Master Belt"
	elseif ((qi >= 15000) and (qi < 20000)) then belt = "Master Belt" qi_next = 20000 belt_next = "Custom Belt"
	elseif ((qi >= 20000) and (qi < 50000)) then belt = "Custom Belt" qi_next = 50000 belt_next = "God Belt"
	elseif ((qi >= 50000) and (qi < 100000)) then belt = "God Belt" qi_next = 100000 belt_next = "One Belt"
	elseif ((qi >= 100000) and (qi < 1000000)) then belt = "One Belt" qi_next = 1000000 belt_next = "Elite Belt"
	elseif (qi >= 1000000) then belt = "Elite Belt"
	end
end

	
function load_data()
	local file = io.open("torishop/torishop.txt") --'http://www.toribash.com/dump/store.php
	if (file == nil) then
		return
 	end
	for i, v in ipairs(data_types) do
		data_table[v] = {}
		data_table_usd[v] = {}
	end

	local current_line = 0
	local _current_line = 0
	
	for ln in file:lines() do
		if string.match(ln, "^PRODUCT") then
			local segments = 19
			local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }	-- split a tab separated string into an array
			
			-- Adjust forum torishop sections
			local skip = nil
			if (data_stream[2] == "1") then data_stream[2] = "6"
			elseif (data_stream[2] == "2") then 
			elseif (data_stream[2] == "5") then 
			elseif (data_stream[2] == "10") then data_stream[2] = "26"
			elseif (data_stream[2] == "11") then data_stream[2] = "7"
			elseif (data_stream[2] == "12") then data_stream[2] = "9"
			-- elseif (data_stream[2] == "18") then data_stream[2] = "32" - Collectibles
			elseif (data_stream[2] == "20") then data_stream[2] = "3"
			elseif (data_stream[2] == "21") then data_stream[2] = "4"
			elseif (data_stream[2] == "22") then 
				data_stream[2] = "1"
			elseif (data_stream[2] == "23") then data_stream[2] = "26"
			elseif (data_stream[2] == "24") then data_stream[2] = "11"
			elseif (data_stream[2] == "27") then
				data_stream[2] = "8"
				data_stream[5] = string.gsub(data_stream[5], "Right Hand Motion Trail", "RHMT")
			elseif (data_stream[2] == "28") then 
				data_stream[2] = "8"
				data_stream[5] = string.gsub(data_stream[5], "Left Hand Motion Trail", "LHMT")
			elseif (data_stream[2] == "29") then 
				data_stream[2] = "8"
				data_stream[5] = string.gsub(data_stream[5], "Right Leg Motion Trail", "RLMT")
			elseif (data_stream[2] == "30") then 
				data_stream[2] = "8"
				data_stream[5] = string.gsub(data_stream[5], "Left Leg Motion Trail", "LLMT")
			elseif (data_stream[2] == "34") then data_stream[2] = "12"
			elseif (data_stream[2] == "41") then data_stream[2] = "10"
			elseif (data_stream[2] == "43") then data_stream[2] = "13"
			elseif (data_stream[2] == "44") then data_stream[2] = "27"
			elseif (data_stream[2] == "46") then 
				if (data_stream[5] == "Box of Boxes") then
					data_stream[2] = "30"
				else
					data_stream[2] = "28"
				end
			elseif (data_stream[2] == "48") then data_stream[2] = "29"
			elseif (data_stream[2] == "54") then 
				if string.find (data_stream[5], "256x256") then 
					data_stream[2] = "16"
				elseif string.find (data_stream[5], "512x512") then
					data_stream[2] = "17"
				else 
					data_stream[2] = "15"
				end
			elseif (data_stream[2] == "55") then data_stream[2] = "18"
			elseif (data_stream[2] == "57") then data_stream[2] = "19"
			elseif (data_stream[2] == "58") then 
				data_stream[2] = "20"
				data_stream[5] = string.sub(data_stream[5], 6)
				data_stream[5] = "GUI" .. data_stream[5]
			elseif (data_stream[2] == "59") then data_stream[2] = "26"
			elseif (data_stream[2] == "68") then data_stream[2] = "25"
			elseif (data_stream[2] == "72") then data_stream[2] = "21"
			elseif (data_stream[2] == "73") then data_stream[2] = "14"
			elseif (data_stream[2] == "74") then 
				if string.find (data_stream[5], "256x256") then 
					data_stream[2] = "16"
				elseif string.find (data_stream[5], "512x512") then
					data_stream[2] = "17"
				else 
					data_stream[2] = "15"
				end
			elseif (data_stream[2] == "78") then 
				if (string.lower(data_stream[5]) == "colossal sword" or
					string.lower(data_stream[5]) == "hidden blade" or
					string.lower(data_stream[5]) == "kunai holster" or
					string.lower(data_stream[5]) == "nailbat" or
					string.lower(data_stream[5]) == "ukelele" or
					string.lower(data_stream[5]) == "barbed wire" or
					string.lower(data_stream[5]) == "portable cassette" or
					string.lower(data_stream[5]) == "fish friend" or
					string.lower(data_stream[5]) == "katana" or
					string.lower(data_stream[5]) == "zombie hand" or
					string.lower(data_stream[5]) == "lil spooks" or
					string.lower(data_stream[5]) == "obsidian scythe" or
					string.lower(data_stream[5]) == "tombstone" or
					string.lower(data_stream[5]) == "broom stick" or
					string.lower(data_stream[5]) == "little latching elf" or
					string.lower(data_stream[5]) == "candy cane" or
					string.lower(data_stream[5]) == "demon wings" or
					string.lower(data_stream[5]) == "shoveler's shovel" or
					string.lower(data_stream[5]) == "sword in the stone") then
					data_stream[2] = "23"
				else
					data_stream[2] = "22"
				end
			elseif (data_stream[2] == "79") then 
				if (data_stream[5] == "Forum VIP" or
					data_stream[5] == "Wibbles" or
					data_stream[5] == "Wibbles Anonymous") then
					data_stream[2] = "26"
				else
					data_stream[2] = "24"
				end
			elseif (data_stream[2] == "80") then
				if (string.lower(data_stream[5]) == "sound pack") then 
					data_stream[2] = "26"
					data_stream[18] = "0"
				elseif string.find(string.lower(data_stream[5]), "texture") then
					if string.find(string.lower(data_stream[5]), "head texture") then
						if string.find(data_stream[5], "128") then
							data_stream[2] = "33"
						elseif string.find(data_stream[5], "256") then
							data_stream[2] = "34"
						else
							data_stream[2] = "35"
						end
						data_stream[18] = "0"
					elseif string.find(string.lower(data_stream[5]), "body texture pack") then
						data_stream[2] = "29"
						data_stream[18] = "0"
					end
				elseif (string.lower(data_stream[5]) == "cyborg" or
						string.lower(data_stream[5]) == "cel shaded tori" or
						string.lower(data_stream[5]) == "toriarmor" or
						string.lower(data_stream[5]) == "tori pirate" or
						string.lower(data_stream[5]) == "skeletal tori" or
						string.lower(data_stream[5]) == "muay thai legend" or
						string.lower(data_stream[5]) == "drake" or
						string.lower(data_stream[5]) == "tori ninja") then
					data_stream[2] = "31"
				elseif (string.lower(data_stream[5]) == "halloween special" or
						string.lower(data_stream[5]) == "tori armor v2") then
					data_stream[2] = "31"
					data_stream[19] = "0"
				else
					data_stream[2] = "30"
				end
			else skip = 1 end
			
			if (data_stream[14] == "1") then
				data_stream[14] = "Beginner"
			elseif (data_stream[14] == "2") then
				data_stream[14] = "I"
			elseif (data_stream[14] == "3") then
				data_stream[14] = "II"
			elseif (data_stream[14] == "4") then
				data_stream[14] = "III"
			elseif (data_stream[14] == "5") then
				data_stream[14] = "IV"
			elseif (data_stream[14] == "6") then
				data_stream[14] = "V"
			elseif (data_stream[14] == "7") then
				data_stream[14] = "VI"
			elseif (data_stream[14] == "8") then
				data_stream[14] = "VII"
			elseif (data_stream[14] == "9") then
				data_stream[14] = "VIII"
			elseif (data_stream[14] == "10") then
				data_stream[14] = "IX"
			elseif (data_stream[14] == "11") then
				data_stream[14] = "X"
			elseif (data_stream[14] == "12") then
				data_stream[14] = "Elite"
			end
			
			if (not skip and (data_stream[18] ~= "1" and data_stream[19] ~= "1")) then
				current_line = current_line + 1
				for i, v in ipairs(data_types) do
					data_table[v][current_line] = data_stream[i + 1]
				end
			
				if (data_stream[10] ~= "0.00") then 
					_current_line = _current_line + 1
					for i, v in ipairs(data_types) do
						data_table_usd[v][_current_line] = data_stream[i + 1]
					end
				end
			end
		end
	end
	file:close()
	
	if (current_line > 0) then
		data_table_lines = current_line
		data_exists = true
	end
	
	if (_current_line > 0) then
		data_table_usd_lines = _current_line
	end
	
	get_playerinfo()
end

local section_order = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35 }
local sections = {}	-- Refer to catid in Torishop.txt for section numbers used
local sections_ = {}

function load_sections()
	-- Colors Section
	sections[1] = { name = "Force Colors", total_items = 0, try = true, selected_index = 0 }
	sections[2] = { name = "Relax Colors", total_items = 0, try = true, selected_index = 0 }
	sections[3] = { name = "Primary Gradients", total_items = 0, try = true, selected_index = 0 }
	sections[4] = { name = "Secondary Gradients", total_items = 0, try = true, selected_index = 0 }
	sections[5] = { name = "Torso Colors", total_items = 0, try = true, selected_index = 0 }
	sections[6] = { name = "Blood Colors", total_items = 0, try = true, selected_index = 0 }
	sections[7] = { name = "Ghost Colors", total_items = 0, try = true, selected_index = 0 }
	sections[8] = { name = "Motion Trails", total_items = 0, try = true, selected_index = 0 }
	sections[9] = { name = "DQ Rings", total_items = 0, try = true, selected_index = 0 }
	sections[10] = { name = "Grip Colors", total_items = 0, try = true, selected_index = 0 }
	sections[11] = { name = "Timers", total_items = 0, try = true, selected_index = 0 }
	sections[12] = { name = "User Text Colors", total_items = 0, try = true, selected_index = 0 }
	sections[13] = { name = "Emote Colors", total_items = 0, try = true, selected_index = 0 }
	sections[14] = { name = "Hair Colors", total_items = 0, try = true, selected_index = 0}
	-- Textures Section
	sections[15] = { name = "128x128 Textures", total_items = 0, try = false, selected_index = 0 }
	sections[16] = { name = "256x256 Textures", total_items = 0, try = false, selected_index = 0 }
	sections[17] = { name = "512x512 Textures", total_items = 0, try = false, selected_index = 0 }
	sections[18] = { name = "Misc Textures", total_items = 0, try = false, selected_index = 0 }
	sections[19] = { name = "Trail Textures", total_items = 0, try = false, selected_index = 0 }
	sections[20] = { name = "GUI Textures", total_items = 0, try = false, selected_index = 0 }
	-- Hairs & Models Section
	sections[21] = { name = "Hair Styles", total_items = 0, try = true, selected_index = 0}
	sections[22] = { name = "Head Models", total_items = 0, try = true, selected_index = 0}
	sections[23] = { name = "Misc Models", total_items = 0, try = true, select = false, selected_index = 0 }
	-- Misc Section
	sections[24] = { name = "Boosters", total_items = 0, try = false, selected_index = 0 }
	sections[25] = { name = "QI", total_items = 0, try = false, selected_index = 0 }
	sections[26] = { name = "Misc", total_items = 0, try = false, selected_index = 0 }
	-- Color & Tier Packs
	sections[27] = { name = "Color Packs", total_items = 0, try = true, select = false, selected_index = 0 }
	sections[28] = { name = "Tier Packs", total_items = 0, try = false, select = false, selected_index = 0 }
	-- Premade Texture Packs
	sections[29] = { name = "Texture Packs", total_items = 0, try = true, select = false, selected_index = 0 }
	-- Model Packs
	sections[30] = { name = "Model Packs", total_items = 0, try = true, selected_index = 0 }
	-- Full Toris
	sections[31] = { name = "Full Toris", total_items = 0, try = true, selected_index = 0 }
	-- Sale Section
	sections[32] = { name = "Sale items", total_items = 0, try = false, selected_index = 0 }
	-- Premade Textures
	sections[33] = { name = "128px Head Textures", total_items = 0, try = true, selected_index = 0 }
	sections[34] = { name = "256px Head Textures", total_items = 0, try = true, selected_index = 0 }
	sections[35] = { name = "512px Head Textures", total_items = 0, try = true, selected_index = 0 }
	
	for i = 1, 35 do
		sections[i].selected_index = 1
		change_section_first[i] = 1
	end
	
	-- USD 
	
	-- Colors Section
	sections_[1] = { name = "Force Colors", total_items = 0, try = true, selected_index = 0 }
	sections_[2] = { name = "Relax Colors", total_items = 0, try = true, selected_index = 0 }
	sections_[3] = { name = "Primary Gradients", total_items = 0, try = true, selected_index = 0 }
	sections_[4] = { name = "Secondary Gradients", total_items = 0, try = true, selected_index = 0 }
	sections_[5] = { name = "Torso Colors", total_items = 0, try = true, selected_index = 0 }
	sections_[6] = { name = "Blood Colors", total_items = 0, try = true, selected_index = 0 }
	sections_[7] = { name = "Ghost Colors", total_items = 0, try = true, selected_index = 0 }
	sections_[8] = { name = "Motion Trails", total_items = 0, try = true, selected_index = 0 }
	sections_[9] = { name = "DQ Rings", total_items = 0, try = true, selected_index = 0 }
	sections_[10] = { name = "Grip Colors", total_items = 0, try = true, selected_index = 0 }
	sections_[11] = { name = "Timers", total_items = 0, try = true, selected_index = 0 }
	sections_[12] = { name = "User Text Colors", total_items = 0, try = true, selected_index = 0 }
	sections_[13] = { name = "Emote Colors", total_items = 0, try = true, selected_index = 0 }
	sections_[14] = { name = "Hair Colors", total_items = 0, try = true, selected_index = 0}
	-- Textures Section
	sections_[15] = { name = "128x128 Textures", total_items = 0, try = false, selected_index = 0 }
	sections_[16] = { name = "256x256 Textures", total_items = 0, try = false, selected_index = 0 }
	sections_[17] = { name = "512x512 Textures", total_items = 0, try = false, selected_index = 0 }
	sections_[18] = { name = "Misc Textures", total_items = 0, try = false, selected_index = 0 }
	sections_[19] = { name = "Trail Textures", total_items = 0, try = false, selected_index = 0 }
	sections_[20] = { name = "GUI Textures", total_items = 0, try = false, selected_index = 0 }
	-- Hairs & Models Section
	sections_[21] = { name = "Hair Styles", total_items = 0, try = true, selected_index = 0}
	sections_[22] = { name = "Head Models", total_items = 0, try = true, selected_index = 0}
	sections_[23] = { name = "Misc Models", total_items = 0, try = true, select = false, selected_index = 0 }
	-- Misc Section
	sections_[24] = { name = "Boosters", total_items = 0, try = false, selected_index = 0 }
	sections_[25] = { name = "QI", total_items = 0, try = false, selected_index = 0 }
	sections_[26] = { name = "Misc", total_items = 0, try = false, selected_index = 0 }
	-- Packs & Full Toris Section
	sections_[27] = { name = "Color Packs", total_items = 0, try = false, select = false, selected_index = 0 }
	sections_[28] = { name = "Tier Packs", total_items = 0, try = false, select = false, selected_index = 0 }
	sections_[29] = { name = "Texture Packs", total_items = 0, try = true, select = false, selected_index = 0 }
	-- Misc Section
	sections_[30] = { name = "Sounds", total_items = 0, try = false, selected_index = 0 }
	sections_[31] = { name = "Collectibles", total_items = 0, try = false, selected_index = 0 }
	-- Sale Section
	sections_[32] = { name = "Sale items", total_items = 0, try = false, selected_index = 0 }
	-- Premade Textures
	sections_[33] = { name = "128px Head Textures", total_items = 0, try = true, selected_index = 0 }
	sections_[34] = { name = "256px Head Textures", total_items = 0, try = true, selected_index = 0 }
	sections_[35] = { name = "512px Head Textures", total_items = 0, try = true, selected_index = 0 }
end

function view_flames()
	local temp = io.open("torishop/flames.cfg", "w")
	if (temp == nil) then
		return
	end
	temp:write("temp file generated to transition between torishop.lua & torishop_flames.lua\n")
	temp:write(tempinfo.force.." "..tempinfo.relax.." "..tempinfo.primary.." "..tempinfo.secondary.." ")
	temp:write(tempinfo.torso.." "..tempinfo.blood.." "..tempinfo.ghost.." "..tempinfo.rhmt.." "..tempinfo.lhmt.." ")
	temp:write(tempinfo.rlmt.." "..tempinfo.llmt.." "..tempinfo.dq.." "..tempinfo.grip.." "..tempinfo.timer.." ")
	temp:write(tempinfo.text.." "..tempinfo.emote.." "..tempinfo.hair.."\n")
	for i = 1, 31 do
		temp:write("section "..sections[i].selected_index.." "..sections_[i].selected_index.." "..change_section_first[i].."\n")
	end
	temp:close()
	close_torishop()
	run_cmd("ls torishop/torishop_flames.lua")
end


function get_colors(colors)
	 colors = tonumber(colors)
	 local color_info = get_color_info(colors)
	 color_r = color_info.r
	 color_g = color_info.g
	 color_b = color_info.b
end

function load_items()
	for line = 1, data_table_lines do
		local id = tonumber(data_table.catid[line])
		--echo(id.." "..data_table.itemname[line])
		local num = sections[id].total_items + 1
		sections[id][num] = {}
		sections[id][num].name = data_table.itemname[line]
		sections[id][num].price = data_table.now_tc_price[line]
		sections[id][num].old_price = data_table.price[line]
		sections[id][num].price_usd = data_table.now_usd_price[line]
		sections[id][num].old_price_usd = data_table.price_usd[line]
		sections[id][num].qi = data_table.qi[line]
		sections[id][num].color = data_table.colorid[line]
		sections[id][num].id = data_table.itemid[line]
		sections[id][num].tier = data_table.tier[line]
		sections[id][num].on_sale = data_table.on_sale[line]
		sections[id].total_items = num
		if (data_table.on_sale[line] == "1") then
			local sale_num = sections[32].total_items + 1
			sections[32][sale_num] = {}
			sections[32][sale_num].name = data_table.itemname[line]
			sections[32][sale_num].price = data_table.now_tc_price[line]
			sections[32][sale_num].old_price = data_table.price[line]
			sections[32][sale_num].price_usd = data_table.now_usd_price[line]
			sections[32][sale_num].old_price_usd = data_table.price_usd[line]
			sections[32][sale_num].qi = data_table.qi[line]
			sections[32][sale_num].color = data_table.colorid[line]
			sections[32][sale_num].id = data_table.itemid[line]
			sections[32][sale_num].tier = data_table.tier[line]
			sections[32][sale_num].on_sale = data_table.on_sale[line]
			sections[32][sale_num].promo = data_table.sale_promotion[line]
			sections[32][sale_num].timeleft = data_table.sale_time[line]
			sections[32].total_items = sale_num
		end
		if (string.find(string.lower(data_table.itemname[line]), "head texture") and id < 33) then
			local id = nil
			if (string.find(string.lower(data_table.itemname[line]), "head")) then
				if (string.find(string.lower(data_table.itemname[line]), "128")) then id = 33 end
				if (string.find(string.lower(data_table.itemname[line]), "256")) then id = 34 end
				if (string.find(string.lower(data_table.itemname[line]), "512")) then id = 35 end
			end
			local num = sections[id].total_items + 1
			sections[id][num] = {}
			sections[id][num].name = data_table.itemname[line]
			sections[id][num].price = data_table.now_tc_price[line]
			sections[id][num].old_price = data_table.price[line]
			sections[id][num].price_usd = data_table.now_usd_price[line]
			sections[id][num].old_price_usd = data_table.price_usd[line]
			sections[id][num].qi = data_table.qi[line]
			sections[id][num].color = data_table.colorid[line]
			sections[id][num].id = data_table.itemid[line]
			sections[id][num].tier = data_table.tier[line]
			sections[id][num].on_sale = data_table.on_sale[line]
			sections[id].total_items = num
		end
		line = line + 1
	end
	
	for line = 1, data_table_usd_lines do
		local id = tonumber(data_table_usd.catid[line])
		local num = sections_[id].total_items + 1
		sections_[id][num] = {}
		sections_[id][num].name = data_table_usd.itemname[line]
		sections_[id][num].price = data_table_usd.now_tc_price[line]
		sections_[id][num].old_price = data_table_usd.price[line]
		sections_[id][num].price_usd = data_table_usd.now_usd_price[line]
		sections_[id][num].old_price_usd = data_table_usd.price_usd[line]
		sections_[id][num].qi = data_table_usd.qi[line]
		sections_[id][num].color = data_table_usd.colorid[line]
		sections_[id][num].id = data_table_usd.itemid[line]
		sections_[id][num].tier = data_table_usd.tier[line]
		sections_[id][num].on_sale = data_table_usd.on_sale[line]
		sections_[id].total_items = num
		line = line + 1
	end
end

function run_sale_timer()
	local timer = os.difftime(os.time(), sale_timer)
	if (timer > 0) then
		for i = 1, sections[32].total_items do
			sections[32][i].timeleft = sections[32][i].timeleft - timer
		end
		sale_timer = os.time()
	end
end

local button_click_radius = 9
local buttons = {}
local cartbuttons = {}
local salebuttons = {}

function load_buttons()
	-- Arrow-type buttons
	buttons.arrows = {}
	buttons.arrows.prev_shelf = { x = 25, y = height-((height-292)/2), angle = 270, state = BTN_UP }
	buttons.arrows.next_shelf = { x = 465, y = height-((height-292)/2), angle = 90, state = BTN_UP }
	buttons.arrows.cart_next = { x = 900, y = 490, angle = 90, state = BTN_UP }
	buttons.arrows.cart_prev = { x = 870, y = 490, angle = 270, state = BTN_UP }
	buttons.arrows.cart_min = { x = 935, y = 0, angle = 0, state = BTN_UP }
	
	-- Text-type buttons
	if (main_page == false) then main_y = 10 else main_y = height-30 end
	
	-- Text Buttons
	buttons.torishop = { x = 162, y = main_y, w = 165, h = 20, state = BTN_UP }
	buttons.none = { x = 36, y = 43, w = 56, h = 20, state = BTN_UP }
	buttons.default = { x = 110, y = 43, w = 84, h = 20, state = BTN_UP }
	buttons.tomain = { x = 428, y = 10, w = 52, h = 20, state = BTN_UP }

	-- MainView0 Buttons
	buttons.sonsale = { x = 10, y = height - 360, w = 470, h = 120, state = BTN_UP }
	buttons.sfeatured = { x = 10, y = height/10 - 10, w = 470, h = 275, state = BTN_UP }
	buttons.sfeatured1 = { x = 10, y = height/10 - 10, w = 230, h = 275, state = BTN_UP }
	buttons.sfeatured2 = { x = 250, y = height/10 - 10, w = 230, h = 275, state = BTN_UP }
	
	buttons.mainsingle =  {x = 10, y = position, w = 230, h = 150, state = BTN_UP }
	buttons.mainfull =  {x = 250, y = position, w = 230, h = 150, state = BTN_UP }
	
	buttons.sflames = { x = 85, y = position + step + step, w = 320, h = 40, state = BTN_UP }
	
	-- MainView1 Buttons
	buttons.scolors = { x = 10, y = position, w = 230, h = 70, state = BTN_UP }
	buttons.stextures = { x = 250, y = position, w = 230, h = 70, state = BTN_UP }
	buttons.shairs = { x = 10, y = position + step, w = 230, h = 70, state = BTN_UP }
	buttons.smisc = { x = 250, y = position + step, w = 230, h = 70, state = BTN_UP }
	
	--MainView2 Buttons
	buttons.scolorpacks = { x = 10, y = position, w = 230, h = 70, state = BTN_UP }
	buttons.stexturesets = { x = 250, y = position, w = 230, h = 70, state = BTN_UP }
	buttons.smodelpacks = { x = 10, y = position + step, w = 230, h = 70, state = BTN_UP }
	buttons.sfulltoris = { x = 250, y = position + step, w = 230, h = 70, state = BTN_UP }
	
	-- Purchase Buttons
	buttons.buy = { x = 313, y = 135, w = 128, h = 34, state = BTN_UP }
	buttons.gettc = { x = 330, y = 135, w = 128, h = 34, state = BTN_UP }
	buttons.buysteam = { x = 330, y = 170, w = 128, h = 34, state = BTN_UP }
	buttons.tocarttc = { x = 441, y = 135, w = 34, h = 34, state = BTN_UP }
	buttons.cartbuy = { x = 810, y = height - 36, w = 128, h = 34, state = BTN_UP }

	-- Vip/Prime info Button
	buttons.info_prime = { x = 175, y = 294, w = 150, h = 20, state = BTN_UP } 
	
	-- Confirm Screen Buttons
	buttons.confirm = { x = width/2 - 105, y = height/2 - 10, w = 230, h = 20, state = BTN_UP }
	buttons.cancel = { x = width/2 - 40, y = height/2 + 20, w = 80, h = 20, state = BTN_UP }

	for i = 1, items_per_shelf do
		buttons[i] = {}
	end
		
	for i = 1, 5 do
		cartbuttons[i] = {}
		cartbuttons[i].cartremove = { x = 0, y = 0, w = 0, h = 0 } 
		cartremovestate[i] = BTN_UP
	end
end

function load_ss_buttons()
	if (main_section == 3 or main_section == 4) then
		swidth = 100
	elseif (main_section >= 5 and main_section <= 8) then
		swidth = 128
	else
		swidth = 32
	end
	for ss = 1, sub_in_section do
		buttons[ss] = {}
		buttons[ss].choose_ss = { x = 4+ss*5+(ss-1)*(swidth-3), y = 7, w = swidth, h = 32, state = BTN_UP }
	end
end

function change_ss()
	if (main_page == false) then
		if (main_section == 1) then sub_in_section = 14
		elseif (main_section == 2) then sub_in_section = 6
		elseif (main_section == 3) then sub_in_section = 3
		elseif (main_section == 4) then sub_in_section = 3
		elseif (main_section == 5) then sub_in_section = 2
		elseif (main_section <= 8) then sub_in_section = 1
		else sub_in_section = 0
		end 
	end
	load_ss_buttons()
end

-- Debugging
function check_items(num)	-- For debugging purposes only
	print(sections[num].name .. " : " .. sections[num].total_items .. " items")
	tmp = 1
	while (tmp <= sections[num].total_items) do
		print(sections[num][tmp].name .. " " .. sections[num][tmp].price .. " " .. sections[num][tmp].qi .. " " .. sections[num][tmp].color)
		tmp = tmp + 1
	end
end

-- Player
local player = {}

function init_player()
	local name = get_master().master.nick
	if (name ~= nil) then
		load_player(0, name)	-- use player customs if logged in
	end
	
	local data1 = set_torishop(0)
	player.blood = data1.blood_color
	player.torso = data1.torso_color
	player.ghost = data1.ghost_color
	player.impact = data1.impact_color
	player.pgrad = data1.grad_pri_color
	player.sgrad = data1.grad_sec_color
	player.lhmt = { data1.lh_trail_r, data1.lh_trail_g, data1.lh_trail_b, data1.lh_trail_a }
	player.rhmt = { data1.rh_trail_r, data1.rh_trail_g, data1.rh_trail_b, data1.rh_trail_a }
	player.llmt = { data1.ll_trail_r, data1.ll_trail_g, data1.ll_trail_b, data1.ll_trail_a }
	player.rlmt = { data1.rl_trail_r, data1.rl_trail_g, data1.rl_trail_b, data1.rl_trail_a }
	
	local data2 = get_joint_color(0, 0)
	player.relax = data2.joint.relax
	player.force = data2.joint.force
end

function draw_grip()
	is_grip = 1
	local grip_info = set_grip_info(0,11,1)
	local right_hand = get_body_info(0, BODYPARTS.R_HAND)
	get_colors(grip_color)
	set_color(color_r, color_g, color_b, 0.7)
	draw_sphere(right_hand.pos.x-0.12, right_hand.pos.y-0.07, right_hand.pos.z+0.02,
		 0.08)
end

function draw_timer()
	if (timer_custom_color == true) then
	get_colors(timer_color)
	set_color(color_r, color_g, color_b, 0.3)
	else set_color(0.58,0,0,0.3)
	end
	draw_disk(width-((width-490)/2), 42, 20, 40, 15, 1, 180, -150, 0)
end

function draw_usertext()
	if (usertext_custom_color == true) then
	get_colors(usertext_color)
	set_color(color_r, color_g, color_b, 1)
	else set_color(0.58,0,0,1)
	end
	draw_right_text("1337", 10, 0, FONTS.BIG)
	draw_right_text(name, 10, 50, FONTS.MEDIUM)
end

function apply_texture(texture, section)
	local loads = 0
	local resolution = 0
	local seed = 0
	if section == 29 then
		if string.find(string.lower(texture), "256") then resolution = 1
		elseif string.find(string.lower(texture), "512") then resolution = 2
		end
		if string.find(string.lower(texture), "goraxx") then seed = 100
		elseif string.find(string.lower(texture), "trancebot") then seed = 101
		end
		loads = 20
	elseif (section > 32 and section < 36) then
		if section == 34 then resolution = 1
		elseif section == 35 then resolution = 2 
		end
		if string.find(string.lower(texture), "nautikor") then seed = 1
		elseif string.find(string.lower(texture), "randombot001") then seed = 2 
		elseif string.find(string.lower(texture), "avionic") then seed = 3
		elseif string.find(string.lower(texture), "geo") then seed = 4
		elseif string.find(string.lower(texture), "space owl") then seed = 5
		elseif string.find(string.lower(texture), "blind warrior") then seed = 6
		elseif string.find(string.lower(texture), "technologic") then seed = 7
		elseif string.find(string.lower(texture), "pink") then seed = 8
		elseif string.find(string.lower(texture), "t-05") then seed = 9
		elseif string.find(string.lower(texture), "hardened soul") then seed = 10
		elseif string.find(string.lower(texture), "fire guardian") then seed = 11
		elseif string.find(string.lower(texture), "orc warlord") then seed = 12
		end
	end
	if seed ~= 0 then
		for i = 0, loads do
			set_body_texture(i, seed * 10 + resolution)
		end
	end
end

function set_player_color(item)
	local section_index = section_order[current_section]
	local name = 0
	local color = 0
	if (current_shelf <= total_shelves_all) then
		name = sections[section_index].name
		color = sections[section_index][item].color
	else
		name = sections_[section_index].name
		color = sections_[section_index][item].color
	end
	
	local head = get_body_info(0, BODYPARTS.HEAD)

	if (name == "Force Colors") then
		set_joint_force_color(0, color)
		tempinfo.force = color
	elseif (name == "Relax Colors") then
		set_joint_relax_color(0, color)
		tempinfo.relax = color
	elseif (name == "Primary Gradients") then
		set_gradient_primary_color(0, color)
		tempinfo.primary = color
	elseif (name == "Secondary Gradients") then
		set_gradient_secondary_color(0, color)
		tempinfo.secondary = color
	elseif (name == "Torso Colors") then
		set_torso_color(0, color)
		tempinfo.torso = color
	elseif (name == "Blood Colors") then
		set_blood_color(0, color)
		tempinfo.blood = color
	elseif (name == "Ghost Colors") then
		set_ghost_color(0, color)
		tempinfo.ghost = color
	elseif (name == "Grip Colors") then
		grip_color = color
		add_hook("draw3d", "grip", draw_grip)
		tempinfo.grip = color
	elseif (string.find (details_name, "LHMT")) then
		set_separate_trail_color(0, 0, color)
		tempinfo.lhmt = color
	elseif (string.find (details_name, "RHMT")) then
		set_separate_trail_color(0, 1, color)
		tempinfo.rhmt = color
	elseif (string.find (details_name, "LLMT")) then
		set_separate_trail_color(0, 2, color)
		tempinfo.llmt = color
	elseif (string.find (details_name, "RLMT")) then
		set_separate_trail_color(0, 3, color)
		tempinfo.rlmt = color
	elseif (name == "DQ Rings") then
		set_ground_impact_color(0, color)
		tempinfo.dq = color
	elseif (name == "Timers") then
		timer_color = color
		timer_custom_color = true
		tempinfo.timer = color
	elseif (name == "User Text Colors") then
		usertext_color = color
		usertext_custom_color = true
		tempinfo.text = color
	elseif (name == "Emote Colors") then
		if (string.len(color) < 2) then  
		run_cmd("em ^0"..color..details_name)
		elseif (string.len(color) > 2) then
		run_cmd("em %"..color..details_name)
		else
		run_cmd("em ^"..color..details_name)
		end
		tempinfo.emote = color
	elseif (name == "Color Packs") then
			set_joint_force_color(0, color)
			set_joint_relax_color(0, color)
			set_blood_color(0, color)
			set_gradient_primary_color(0, color)
			set_gradient_secondary_color(0, color)
			set_torso_color(0, color)
			set_ghost_color(0, color)
			grip_color = color
			add_hook("draw3d", "grip", draw_grip)
			set_separate_trail_color(0, 0, color)
			set_separate_trail_color(0, 1, color)
			set_separate_trail_color(0, 2, color)
			set_separate_trail_color(0, 3, color)
			set_ground_impact_color(0, color)
			timer_color = color
			timer_custom_color = true
			usertext_color = color
			usertext_custom_color = true
			if (string.len(color) < 2) then  
				run_cmd("em ^0"..color..details_name)
			elseif (string.len(color) > 2) then
				run_cmd("em %"..color..details_name)
			else
				run_cmd("em ^"..color..details_name)
			end
			set_hair_color(0, color)
			tempinfo.force = color
			tempinfo.relax = color
			tempinfo.blood = color
			tempinfo.primary = color
			tempinfo.secondary = color
			tempinfo.torso = color
			tempinfo.ghost = color
			tempinfo.grip = color
			tempinfo.rhmt = color
			tempinfo.lhmt = color
			tempinfo.rlmt = color
			tempinfo.llmt = color
			tempinfo.dq = color
			tempinfo.text = color
			tempinfo.timer = color
			tempinfo.emote = color
			tempinfo.hair = color
	elseif (name == "Hair Styles") then
	if (details_name == "Candy Locks") then
			set_hair_settings(0, 0, 1, 8, 125, 300, 0, 4, 3, 15, 30, 1, 1, 1, 15, 0, 40, 100)
			set_hair_settings(0, 1, 1, 0, 235, 295, 0, 4, 3, 15, 30, 5, 1, 1, 15, 0, 14, 100)
			set_hair_settings(0, 2, 1, 1, 0, 45, 0, 9, 4, 32, 40, 1, 1, 24, 15, 0, 24, 100)
			set_hair_settings(0, 3, 1, 8, 206, 230, 152, 5, 10, 20, 0, 17, 1, 50, 14, 0, 0, 100)
			set_hair_settings(0, 4, 1, 8, 184, 219, 178, 6, 10, 20, 0, 20, 5, 1, 5, 0, 0, 100)
			set_hair_settings(0, 5, 1, 8, 157, 221, 155, 5, 10, 20, 0, 18, 1, 36, 18, 0, 0, 100)
			set_hair_settings(0, 6, 1, 8, 360, 44, 180, 10, 10, 32, 38, 4, 25, 31, 56, 0, 0, 1)
			set_hair_settings(0, 7, 1, 1, 0, 66, 0, 3, 10, 46, 45, 16, 30, 1, 56, 0, 0, 100)
			set_hair_settings(0, 8, 1, 1, 0, 48, 0, 3, 10, 46, 45, 1, 34, 18, 56, 0, 0, 100)
			set_hair_settings(0, 9, 1, 1, 0, 33, 0, 3, 10, 46, 45, 1, 38, 18, 56, 0, 0, 100)
			set_hair_settings(0, 10, 1, 1, 0, 39, 0, 3, 10, 46, 40, 6, 43, 24, 56, 0, 0, 100)
			set_hair_settings(0, 11, 1, 1, 0, 29, 0, 3, 10, 41, 1, 41, 23, 1, 56, 0, 0, 100)
			set_hair_settings(0, 12, 1, 8, 314, 136, 223, 4, 10, 20, 1, 1, 16, 34, 56, 0, 0, 100)
			set_hair_settings(0, 13, 1, 0, 276, 103, 165, 5, 10, 20, 1, 2, 21, 48, 56, 0, 0, 3)
			set_hair_settings(0, 14, 1, 0, 269, 90, 165, 5, 10, 20, 1, 2, 21, 42, 56, 0, 0, 3)
			set_hair_settings(0, 15, 1, 8, 275, 274, 21, 5, 10, 20, 0, 2, 24, 32, 56, 0, 0, 3)
	elseif (details_name == "Cat Ears") then
			set_hair_settings(0, 0, 1, 8, 55, 80, 350, 3, 4, 30, 0, 1, 30, 1, 50, 5, 0, 100)
			set_hair_settings(0, 1, 1, 8, 305, 80, 10, 3, 4, 30, 0, 1, 30, 1, 50, 5, 0, 100)
			for i=2, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Centurion") then
			set_hair_settings(0, 0, 1, 8, 0, 0, 360, 6, 10, 30, 38, 2, 4, 2, 26, 8, 0, 50)
			set_hair_settings(0, 1, 1, 8, 0, 30, 360, 6, 10, 30, 38, 4, 6, 1, 26, 8, 0, 50)
			set_hair_settings(0, 2, 1, 8, 0, 60, 360, 6, 10, 30, 38, 4, 6, 1, 26, 8, 0, 50)
			set_hair_settings(0, 3, 1, 8, 0, 90, 360, 6, 10, 30, 38, 4, 6, 1, 26, 8, 0, 50)
			for i=4, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Daimyo Hat and Scarf") then
			set_hair_settings(0, 0, 1, 1, 0, 95, 0, 3, 10, 80, 20, 1, 56, 1, 16, 10, 0, 0)
			set_hair_settings(0, 1, 1, 8, 0, 297, 0, 6, 3, 24, 46, 18, 1, 100, 16, 12, 48, 40)
			for i=2, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Gentleman's Essentials") then
			set_hair_settings(0, 0, 1, 1, 0, 65, 0, 3, 10, 60, 60, 20, 1, 1, 7, 11, 0, 1)
			set_hair_settings(0, 1, 1, 1, 0, 65, 0, 3, 10, 46, 46, 44, 56, 1, 7, 11, 0, 1)
			set_hair_settings(0, 2, 1, 1, 100, 155, 0, 3, 10, 25, 0, 44, 1, 1, 7, 11, 57, 34)
			set_hair_settings(0, 3, 1, 8, 100, 140, 0, 4, 7, 10, 5, 3, 3, 100, 7, 11, 0, 1)
			for i=4, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Jiyu Dreads") then
			set_hair_settings(0, 0, 1, 8, 2, 86, 0, 9, 10, 14, 10, 3, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 1, 1, 8, 25, 82, 0, 9, 10, 14, 10, 3, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 2, 1, 8, 335, 82, 0, 9, 10, 14, 10, 3, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 3, 1, 8, 50, 86, 0, 9, 10, 14, 10, 3, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 4, 1, 8, 310, 86, 0, 9, 10, 14, 10, 2, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 5, 1, 8, 0, 70, 0, 9, 10, 14, 10, 2, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 6, 1, 8, 15, 70, 0, 9, 10, 14, 10, 2, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 7, 1, 8, 345, 70, 0, 9, 10, 14, 10, 2, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 8, 1, 8, 25, 35, 0, 9, 10, 14, 10, 2, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 9, 1, 8, 335, 35, 0, 9, 10, 14, 10, 2, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 10, 1, 8, 52, 57, 0, 9, 10, 14, 10, 2, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 11, 1, 8, 308, 57, 0, 9, 10, 14, 10, 2, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 12, 1, 8, 0, 0, 0, 9, 10, 14, 10, 2, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 13, 1, 8, 65, 35, 0, 9, 10, 14, 10, 2, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 14, 1, 8, 295, 35, 0, 9, 10, 14, 10, 2, 26, 32, 52, 7, 0, 6)
			set_hair_settings(0, 15, 1, 8, 358, 86, 0, 9, 10, 14, 10, 3, 26, 32, 52, 7, 0, 6)
	elseif (details_name == "Minihawk") then
			set_hair_settings(0, 0, 1, 8, 0, 10, 0, 3, 5, 18, 22, 4, 30, 1, 50, 10, 0, 50)
			set_hair_settings(0, 1, 1, 8, 0, 20, 0, 3, 5, 18, 22, 4, 30, 1, 50, 10, 0, 50)
			set_hair_settings(0, 2, 1, 8, 0, 30, 0, 3, 5, 18, 22, 4, 30, 1, 50, 10, 0, 50)
			set_hair_settings(0, 3, 1, 8, 0, 40, 0, 3, 5, 18, 22, 4, 30, 1, 50, 10, 0, 50)
			set_hair_settings(0, 4, 1, 8, 0, 50, 0, 3, 5, 18, 22, 4, 30, 1, 50, 10, 0, 50)
			set_hair_settings(0, 5, 1, 8, 0, 60, 0, 3, 5, 18, 22, 4, 30, 1, 50, 10, 0, 50)
			for i=6, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Mohawk") then
			set_hair_settings(0, 0, 1, 8, 0, 0, 0, 4, 5, 30, 32, 1, 1, 1, 50, 7, 54, 54)
			set_hair_settings(0, 1, 1, 8, 0, 20, 0, 4, 5, 30, 32, 1, 1, 1, 50, 10, 0, 50)
			set_hair_settings(0, 2, 1, 8, 0, 40, 0, 4, 5, 30, 32, 1, 1, 1, 50, 10, 0, 50)
			set_hair_settings(0, 3, 1, 8, 0, 60, 0, 4, 5, 30, 32, 1, 1, 1, 50, 10, 0, 50)
			set_hair_settings(0, 4, 1, 8, 0, 80, 0, 4, 5, 30, 32, 1, 1, 1, 50, 10, 0, 50)
			set_hair_settings(0, 5, 1, 8, 0, 100, 0, 4, 5, 30, 32, 1, 1, 1, 50, 10, 0, 50)
			for i=6, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Pony Tail") then
			set_hair_settings(0, 0, 1, 8, 0, 60, 180, 8, 10, 15, 25, 10, 1, 10, 2, 1, 0, 50)
			for i=1, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Spiky Hair") then
			set_hair_settings(0, 0, 1, 8, 0, 0, 0, 5, 4, 20, 0, 1, 1, 20, 38, 1, 0, 50)
			set_hair_settings(0, 1, 1, 8, 0, 30, 0, 5, 4, 20, 0, 1, 1, 20, 38, 1, 0, 50)
			set_hair_settings(0, 2, 1, 8, 0, 60, 0, 5, 4, 20, 0, 1, 1, 20, 38, 1, 0, 50)
			set_hair_settings(0, 3, 1, 8, 0, 90, 0, 5, 4, 20, 0, 1, 1, 20, 38, 1, 0, 50)
			set_hair_settings(0, 4, 1, 8, 0, 120, 0, 5, 4, 20, 0, 1, 1, 20, 38, 1, 0, 50)
			set_hair_settings(0, 5, 1, 8, 0, 150, 0, 5, 4, 20, 0, 1, 1, 20, 38, 1, 0, 50)
			for i=6, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Surfer's Seishin") then
			set_hair_settings(0, 0, 1, 8, 0, 100, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 1, 1, 8, 30, 80, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 2, 1, 8, 60, 90, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 3, 1, 8, 90, 70, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 4, 1, 8, 330, 80, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 5, 1, 8, 300, 90, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 6, 1, 8, 270, 70, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 7, 1, 8, 0, 50, 0, 4, 10, 31, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 8, 1, 8, 0, 0, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 9, 1, 8, 50, 45, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 10, 1, 8, 310, 45, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 11, 1, 8, 115, 30, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 12, 1, 8, 245, 30, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 13, 1, 8, 30, 110, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 14, 1, 8, 330, 110, 0, 4, 10, 30, 0, 1, 1, 1, 0, 0, 0, 76)
			set_hair_settings(0, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	elseif (details_name == "The Sultan's Fez") then
			set_hair_settings(0, 0, 1, 1, 0, 70, 0, 10, 10, 30, 25, 40, 16, 10, 2, 0, 0, 1)
			set_hair_settings(0, 1, 1, 0, 0, 70, 180, 8, 10, 0, 19, 17, 5, 6, 18, 0, 0, 55)
			for i=2, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Santa Hat") then
			set_hair_settings(0, 0, 1, 2, 146, 295, 280, 4, 10, 43, 0, 10, 28, 42, 68, 0, 0, 54)
			set_hair_settings(0, 1, 1, 1, 145, 291, 0, 5, 10, 46, 44, 6, 21, 16, 0, 0, 0, 100)
			set_hair_settings(0, 2, 1, 5, 144, 296, 280, 4, 10, 0, 19, 11, 26, 50, 0, 0, 46, 54)
			for i=3, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Santa Beard") then
			set_hair_settings(0, 0, 1, 3, 340, 250, 315, 4, 10, 30, 0, 15, 30, 20, 0, 0, 0, 100)
			set_hair_settings(0, 1, 1, 3, 20, 250, 45, 4, 10, 30, 0, 15, 30, 20, 0, 0, 0, 100)
			set_hair_settings(0, 2, 1, 3, 0, 247, 0, 4, 10, 30, 0, 20, 30, 20, 0, 0, 0, 100)
			set_hair_settings(0, 3, 1, 1, 342, 210, 240, 10, 10, 17, 0, 45, 1, 10, 0, 0, 0, 100)
			set_hair_settings(0, 4, 1, 1, 18, 210, 120, 10, 10, 17, 0, 45, 1, 10, 0, 0, 0, 100)
			set_hair_settings(0, 5, 1, 1, 330, 220, 285, 10, 10, 19, 0, 45, 2, 10, 0, 0, 0, 100)
			set_hair_settings(0, 6, 1, 1, 30, 220, 75, 10, 10, 19, 0, 45, 2, 10, 0, 0, 0, 100)
			set_hair_settings(0, 7, 1, 1, 220, 130, 55, 10, 10, 20, 0, 45, 8, 10, 0, 0, 0, 100)
			set_hair_settings(0, 8, 1, 1, 140, 130, 305, 10, 10, 20, 0, 45, 8, 10, 0, 0, 0, 100)
			set_hair_settings(0, 9, 1, 1, 135, 115, 310, 10, 10, 20, 0, 45, 15, 10, 0, 0, 0, 100)
			set_hair_settings(0, 10, 1, 1, 225, 115, 50, 10, 10, 20, 0, 45, 15, 10, 0, 0, 0, 0)
			for i=11, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Uke Hair") then
			set_hair_settings(0, 0, 1, 8, 0, 55, 0, 3, 10, 30, 0, 1, 1, 1, 28, 0, 0, 100)
			set_hair_settings(0, 1, 1, 0, 0, 55, 0, 3, 10, 10, 25, 9, 1, 1, 28, 0, 30, 100)
			for i=2, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Tori Hair") then
			set_hair_settings(0, 0, 1, 6, 0, 50, 0, 4, 8, 15, 20, 1, 1, 1, 2, 0, 0, 52)
			for i=1, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Jester Hat") then
			set_hair_settings(0, 0, 1, 8, 12, 90, 165, 10, 6, 36, 0, 1, 1, 1, 28, 0, 0, 50)
			set_hair_settings(0, 1, 1, 8, 348, 90, 195, 10, 6, 36, 0, 1, 1, 1, 41, 0, 0, 50)
			set_hair_settings(0, 2, 1, 8, 0, 69, 180, 10, 4, 34, 0, 1, 1, 1, 9, 0, 0, 50)
			for i=3, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Zabrak Horns") then
			set_hair_settings(0, 0, 1, 1, 0, 136, 0, 5, 4, 16, 0, 45, 13, 20, 120, 8, 0, 1)
			set_hair_settings(0, 1, 1, 1, 34, 123, 346, 5, 4, 16, 0, 45, 13, 20, 120, 8, 0, 1)
			set_hair_settings(0, 2, 1, 1, 326, 123, 14, 5, 4, 16, 0, 45, 13, 20, 120, 8, 0, 1)
			set_hair_settings(0, 3, 1, 1, 45, 95, 336, 5, 4, 16, 0, 45, 11, 20, 120, 8, 0, 1)
			set_hair_settings(0, 4, 1, 1, 315, 95, 14, 5, 4, 16, 0, 46, 11, 20, 120, 8, 0, 1)
			set_hair_settings(0, 5, 1, 1, 0, 50, 0, 5, 4, 19, 0, 45, 14, 22, 120, 8, 0, 1)
			set_hair_settings(0, 6, 1, 1, 32, 70, 343, 5, 4, 16, 0, 46, 12, 20, 120, 8, 0, 1)
			set_hair_settings(0, 7, 1, 1, 328, 70, 17, 5, 4, 16, 0, 46, 12, 20, 120, 8, 0, 1)
			set_hair_settings(0, 8, 1, 1, 104, 259, 21, 5, 4, 14, 0, 44, 1, 20, 120, 8, 0, 1)
			set_hair_settings(0, 9, 1, 1, 103, 272, 21, 5, 4, 14, 0, 44, 1, 20, 120, 8, 0, 1)
			set_hair_settings(0, 10, 1, 1, 77, 88, 338, 5, 4, 14, 0, 44, 1, 20, 120, 8, 0, 1)
			set_hair_settings(0, 11, 1, 1, 76, 101, 338, 5, 4, 14, 0, 44, 1, 20, 120, 8, 0, 1)
			for i=12, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Dark Duke") then
			set_hair_settings(0, 0, 1, 8, 300, 80, 60, 5, 10, 40, 0, 5, 30, 20, 25, 3, 0, 50)
			set_hair_settings(0, 1, 1, 8, 0, 122, 307, 5, 10, 30, 0, 4, 30, 20, 25, 3, 0, 50)
			set_hair_settings(0, 2, 1, 8, 0, 78, 324, 5, 10, 30, 0, 5, 30, 20, 25, 3, 0, 50)
			set_hair_settings(0, 3, 1, 8, 0, 43, 330, 5, 10, 35, 0, 4, 30, 20, 25, 3, 0, 50)
			set_hair_settings(0, 4, 1, 8, 0, 1, 305, 5, 10, 35, 0, 5, 30, 20, 25, 3, 0, 50)
			set_hair_settings(0, 5, 1, 8, 60, 80, 300, 5, 10, 40, 0, 5, 30, 20, 25, 3, 0, 50)
			for i=6, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Dread Tail") then
			set_hair_settings(0, 0, 1, 8, 0, 70, 180, 10, 10, 10, 10, 17, 20, 30, 100, 10, 0, 40)
			set_hair_settings(0, 1, 1, 1, 0, 69, 0, 10, 10, 20, 25, 5, 25, 1, 59, 0, 0, 100)
			set_hair_settings(0, 2, 1, 8, 4, 74, 181, 10, 10, 10, 10, 17, 20, 30, 50, 10, 0, 40)
			set_hair_settings(0, 3, 1, 8, 1, 78, 179, 10, 10, 10, 10, 17, 20, 30, 50, 10, 0, 40)
			set_hair_settings(0, 4, 1, 8, 0, 75, 181, 10, 10, 10, 10, 17, 20, 30, 100, 10, 0, 40)
			set_hair_settings(0, 5, 1, 8, 2, 79, 180, 10, 10, 10, 10, 17, 20, 30, 100, 10, 0, 40)
			set_hair_settings(0, 6, 1, 8, 0, 78, 180, 10, 10, 10, 10, 17, 20, 30, 100, 10, 0, 40)
			for i=7, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Mayan Warrior") then
			set_hair_settings(0, 0, 1, 8, 0, 70, 180, 5, 6, 25, 0, 5, 5, 15, 47, 10, 0, 100)
			set_hair_settings(0, 1, 1, 8, 330, 80, 180, 5, 6, 25, 0, 5, 5, 15, 49, 10, 0, 100)
			set_hair_settings(0, 2, 1, 8, 300, 80, 190, 5, 6, 25, 0, 5, 5, 15, 100, 10, 0, 100)
			set_hair_settings(0, 3, 1, 8, 270, 90, 0, 3, 6, 25, 0, 5, 5, 15, 30, 10, 0, 100)
			set_hair_settings(0, 4, 1, 8, 230, 110, 0, 3, 6, 25, 0, 5, 5, 15, 50, 10, 0, 100)
			set_hair_settings(0, 5, 1, 8, 30, 80, 180, 5, 6, 25, 0, 5, 5, 15, 49, 10, 0, 100)
			set_hair_settings(0, 6, 1, 8, 60, 80, 170, 5, 6, 25, 0, 5, 5, 15, 100, 10, 0, 100)
			set_hair_settings(0, 7, 1, 8, 90, 90, 0, 3, 6, 25, 0, 5, 5, 15, 30, 10, 0, 100)
			set_hair_settings(0, 8, 1, 8, 130, 110, 0, 3, 6, 25, 0, 5, 5, 15, 50, 10, 0, 100)
			set_hair_settings(0, 9, 1, 8, 0, 230, 0, 3, 6, 25, 0, 5, 5, 15, 8, 10, 0, 100)
			for i=10, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "Sifu Beard") then
			set_hair_settings(0, 0, 1, 8, 338, 216, 259, 9, 3, 8, 0, 6, 24, 22, 0, 3, 0, 10)
			set_hair_settings(0, 1, 1, 8, 22, 216, 101, 9, 3, 8, 0, 6, 24, 22, 0, 3, 0, 10)
			set_hair_settings(0, 2, 1, 1, 0, 244, 0, 8, 10, 24, 0, 1, 31, 2, 0, 3, 0, 100)
			set_hair_settings(0, 3, 1, 1, 0, 244, 0, 6, 10, 0, 16, 56, 1, 22, 0, 3, 0, 100)
			set_hair_settings(0, 4, 1, 1, 0, 244, 0, 7, 10, 0, 10, 1, 28, 28, 76, 0, 0, 100)
			for i=5, 15 do
			set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	elseif (details_name == "RAGE!") then
			set_hair_settings(0, 0, 1, 8, 43, 108, 208, 3, 3, 0, 14, 20, 32, 1, 2, 0, 0, 100)
			set_hair_settings(0, 1, 1, 8, 324, 93, 208, 3, 3, 0, 14, 20, 32, 1, 9, 0, 0, 100)
			set_hair_settings(0, 2, 1, 8, 28, 64, 208, 3, 3, 0, 14, 20, 32, 1, 3, 0, 0, 100)
			set_hair_settings(0, 3, 1, 8, 331, 72, 208, 3, 3, 0, 14, 20, 32, 1, 52, 0, 0, 100)
			set_hair_settings(0, 4, 1, 8, 338, 115, 208, 3, 3, 0, 14, 20, 32, 1, 52, 0, 0, 100)
			set_hair_settings(0, 5, 1, 8, 0, 28, 208, 3, 3, 0, 14, 20, 32, 1, 3, 0, 0, 100)
			set_hair_settings(0, 6, 1, 8, 21, 129, 208, 3, 3, 0, 14, 20, 32, 1, 52, 0, 0, 100)
			set_hair_settings(0, 7, 1, 8, 43, 57, 208, 3, 3, 0, 14, 20, 32, 1, 9, 0, 0, 100)
			set_hair_settings(0, 8, 1, 8, 324, 50, 208, 3, 3, 0, 14, 20, 32, 1, 9, 0, 0, 100)
			set_hair_settings(0, 9, 1, 8, 7, 57, 208, 3, 3, 0, 14, 20, 32, 1, 52, 0, 0, 100)
			set_hair_settings(0, 10, 1, 8, 0, 72, 208, 3, 3, 0, 14, 20, 32, 1, 9, 0, 0, 100)
			set_hair_settings(0, 11, 1, 8, 360, 100, 208, 3, 3, 0, 14, 20, 32, 1, 52, 0, 0, 100)
			set_hair_settings(0, 12, 1, 8, 50, 79, 208, 3, 3, 0, 14, 20, 32, 1, 52, 0, 0, 100)
			set_hair_settings(0, 13, 1, 8, 21, 86, 208, 3, 3, 0, 14, 20, 32, 1, 9, 0, 0, 100)
			for i=14, 15 do
				set_hair_settings(0, i, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			end
	end
		reset_hair(0)
	elseif (name == "Hair Colors") then
		set_hair_color(0, color)
		tempinfo.hair = color
	elseif (name == "Head Models" or name == "Misc Models" or name == "Sale items") then
		local model_name = details_name:lower()
		if (string.find(model_name, " ")) then
		model_name = string.gsub(model_name, " ", "_") end
		if (model_name == "officer_cap" or
			model_name == "frankenbolts" or
			model_name == "witch_hat" or
			model_name == "propeller_hat" or
			model_name == "skull_necklace" or
			model_name == "brain" or
			model_name == "button_eyes" or
			model_name == "rudolph_nose_and_antlers" or
			model_name == "elven_hat" or
			model_name == "santa's_hat" or
			model_name == "mullet" or
			model_name == "blindfold" or
			model_name == "bunny_ears" or
			model_name == "odd_mask" or
			model_name == "beret_o'_messieurs" or
			model_name == "painter's_mustache" or
			model_name == "gentlemen's_mustache" or
			model_name == "sunglasses" or
			model_name == "swag_cap" or
			model_name == "beaten_halo" or 
			model_name == "beaten_horns" or
			model_name == "cereal_box" or
			model_name == "crayon_tori_box" or
			model_name == "deal_with_it" or 
			model_name == "duckbill" or
			model_name == "flammable_box" or
			model_name == "hampa_box" or
			model_name == "magical_uni-horn" or
			model_name == "nerd_glasses" or
			model_name == "poker_hat" or
			model_name == "smile_box" or
			model_name == "swagtastic_gear" or
			model_name == "the_kick-me_box" or
			model_name == "tori_box" or
			model_name == "totally_3d!_(glasses)" or
			model_name == "beerhat" or
			model_name == "bucket_helmet" or
			model_name == "court_jester" or
			model_name == "demon_horns" or
			model_name == "flower_crown" or
			model_name == "gangster_bandana" or
			model_name == "head_toriboppers" or
			model_name == "jim_the_tuna" or
			model_name == "kitsune_mask" or
			model_name == "side_kitsune_mask" or
			model_name == "yin_the_orca" or
			model_name == "cowboy_hat" or
			model_name == "tv_box" or 
			model_name == "soderspy" or
			model_name == "viking_helmet" or
			model_name == "forehead_protector" or
			model_name == "vagabond" or
			model_name == "road_fighter" or
			model_name == "kid_popstar" or
			model_name == "plague_doctor_mask" or
			model_name == "soderhair") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 0 255 1 0 0 0")
		elseif (model_name == "shutter_shades") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 31 255 0 0 0 0")
		elseif (model_name == "red_submarine") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 2 255 1 0 0 0")
		elseif (model_name == "green_hat") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 10 255 0 0 0 0")
		elseif (model_name == "headphones") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 55 255 1 0 0 0")
		elseif (model_name == "football_helmet") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 50 255 1 0 0 0")
		elseif (model_name == "barbed_wire") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 9 0 255 0 0 0 0")
		elseif (model_name == "boxing_helm") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 41 255 1 0 0 0")
		elseif (model_name == "eye_patch") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 30 255 1 0 0 0")
		elseif (model_name == "jack-o'-lantern") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 0 255 1 0 1 0")
		elseif (model_name == "tengu_mask") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 50 255 1 0 0 0")
		elseif (model_name == "little_latching_elf") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 17 0 255 1 0 0 0")
		elseif (model_name == "portable_cassette" or 
			model_name == "kunai_holster" or
			model_name == "love_potion") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 16 0 255 1 0 0 0")
		elseif (model_name == "left_boxing_glove" or 
			model_name == "left_box-ing_glove" or
			model_name == "pirate_hook") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 12 0 255 1 0 1 0")
		elseif (model_name == "right_boxing_glove" or 
			model_name == "right_box-ing_glove") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 11 0 255 1 0 1 0")
		elseif (model_name == "left_kickin'_kick") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 20 0 255 1 0 1 0")
		elseif (model_name == "right_kickin'_kick") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 19 0 255 1 0 1 0")
		elseif (model_name == "kamehamehair") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 9 255 0 0 0 0")
		elseif (model_name == "candy_cane" or
			model_name == "fashionable_bow-tie" or
			model_name == "nailbat" or
			model_name == "ukelele" or
			model_name == "demon_wings" or
			model_name == "fish_friend" or
			model_name == "broom_stick" or 
			model_name == "obsidian_scythe" or 
			model_name == "shoveler's_shovel") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 1 0 255 1 0 0 0")
		elseif (model_name == "katana") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 1 0 255 1 1 0 0")
		elseif (model_name == "right_punkspike") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 7 0 255 1 0 0 0")
		elseif (model_name == "left_punkspike") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 10 0 255 1 0 0 0")
		elseif (model_name == "elbow_pad_-_right") then run_cmd("obj load data/script/torishop/models/elbow_pad.obj 0 7 0 255 1 0 0 0")
		elseif (model_name == "elbow_pad_-_left") then run_cmd("obj load data/script/torishop/models/elbow_pad.obj 0 9 0 255 1 0 0 0")
		elseif (model_name == "head_axe" or
				model_name == "ruined_crown") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 50 255 1 1 0 0")
		elseif (model_name == "chef_hat" or
			model_name == "pilgrim's_hat" or
			model_name == "pipe" or
			model_name == "ski_goggles" or
			model_name == "hazard_mask" or
			model_name == "steampunk_goggles" or
			model_name == "clout_goggles" or
			model_name == "pirate_hat" or 
			model_name == "indian_headdress" or
			string.find(model_name, "beanie")) then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 0 255 1 1 0 0")
		elseif (model_name == "colossal_sword") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 2 0 255 1 0 0 0")
		elseif (model_name == "hidden_blade" or 
			model_name == "right_armblade") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 7 0 255 1 0 0 0")
		elseif (model_name == "pirate_belt") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 4 0 255 1 0 0 0")
		elseif (model_name == "zombie_hand") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 17 0 255 1 0 0 0")
		elseif (model_name == "left_armblade") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 10 0 255 1 0 0 0")
		elseif (model_name == "sword_in_the_stone" or
				model_name == "tombstone") then run_cmd("objfloor load data/script/torishop/models/"..model_name..".obj 0 1")
		elseif (model_name == "lil_spooks") then run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 1 0 255 1 0 0 0")
		end
	elseif (name == "Model Packs" or name == "Full Toris") then
		if (details_name == "Cel Shaded Tori") then
			run_cmd("obj load data/script/torishop/models/celshaded_head.obj 0 0 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_breast.obj 0 1 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_chest.obj 0 2 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_stomach.obj 0 3 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_thorax.obj 0 4 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_r_pecs.obj 0 5 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_r_biceps.obj 0 6 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_r_triceps.obj 0 7 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_l_pecs.obj 0 8 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_l_biceps.obj 0 9 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_l_triceps.obj 0 10 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_r_hand.obj 0 11 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_l_hand.obj 0 12 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_r_butt.obj 0 13 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_l_butt.obj 0 14 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_r_thigh.obj 0 15 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_l_thigh.obj 0 16 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_r_leg.obj 0 17 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_l_leg.obj 0 18 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_r_foot.obj 0 19 7 255 0 1 0 0")
			run_cmd("obj load data/script/torishop/models/celshaded_l_foot.obj 0 20 7 255 0 1 0 0")
		elseif (details_name == "ToriArmor") then
			run_cmd("obj load data/script/torishop/models/toriarmor_head.obj 0 0 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/toriarmor_r_biceps.obj 0 6 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/toriarmor_r_triceps.obj 0 7 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/toriarmor_l_biceps.obj 0 9 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/toriarmor_l_triceps.obj 0 10 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/toriarmor_r_hand.obj 0 11 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/toriarmor_l_hand.obj 0 12 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/toriarmor_r_thigh.obj 0 15 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/toriarmor_l_thigh.obj 0 16 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/toriarmor_r_leg.obj 0 17 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/toriarmor_l_leg.obj 0 18 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/toriarmor_r_foot.obj 0 19 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/toriarmor_l_foot.obj 0 20 0 255 1 0 0 0")
		elseif (string.find(details_name, "Mecha Arm")) then
			if (details_name == "Mecha Arms" or details_name == "Mecha Arm Right") then
				run_cmd("obj load data/script/torishop/models/mecharm_r_biceps.obj 0 6 0 255 1 0 1 0")
				run_cmd("obj load data/script/torishop/models/mecharm_r_triceps.obj 0 7 0 255 1 0 1 0")
				run_cmd("obj load data/script/torishop/models/mecharm_r_hand.obj 0 11 0 255 1 0 1 0")
			end
			if (details_name == "Mecha Arms" or details_name == "Mecha Arm Left") then
				run_cmd("obj load data/script/torishop/models/mecharm_l_biceps.obj 0 9 0 255 1 0 1 0")
				run_cmd("obj load data/script/torishop/models/mecharm_l_triceps.obj 0 10 0 255 1 0 1 0")
				run_cmd("obj load data/script/torishop/models/mecharm_l_hand.obj 0 12 0 255 1 0 1 0")
			end
		elseif (details_name == "Cyborg") then
			run_cmd("obj load data/script/torishop/models/cyborg_head.obj 0 0 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/cyborg_chest.obj 0 2 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/cyborg_stomach.obj 0 3 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/cyborg_r_biceps.obj 0 6 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/cyborg_r_triceps.obj 0 7 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/cyborg_l_biceps.obj 0 9 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/cyborg_r_thigh.obj 0 15 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/cyborg_l_thigh.obj 0 16 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/cyborg_r_leg.obj 0 17 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/cyborg_l_leg.obj 0 18 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/cyborg_r_foot.obj 0 19 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/cyborg_l_foot.obj 0 20 0 255 1 0 1 0")
		elseif (details_name == "Peg Leg") then
			run_cmd("obj load data/script/torishop/models/peg_leg.obj 0 18 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/peg_leg_foot.obj 0 19 0 255 1 0 1 0")
		elseif (details_name == "Boxer Pack") then
			run_cmd("obj load data/script/torishop/models/boxing_helm.obj 0 0 41 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/left_boxing_glove.obj 0 12 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/right_boxing_glove.obj 0 11 0 255 1 0 1 0")
		elseif (details_name == "Box of Boxes") then
			local tmpload = math.random(1, 8)
			if (tmpload == 1) then
				model_name = "cereal_box"
			elseif (tmpload == 2) then
				model_name = "crayon_tori_box"
			elseif (tmpload == 3) then
				model_name = "flammable_box"
			elseif (tmpload == 4) then
				model_name = "hampa_box"
			elseif (tmpload == 5) then
				model_name = "smile_box"
			elseif (tmpload == 6) then
				model_name = "the_kick-me_box"
			elseif (tmpload == 7) then
				model_name = "tori_box"
			elseif (tmpload == 8) then
				model_name = "tv_box"
			end
			run_cmd("obj load data/script/torishop/models/"..model_name..".obj 0 0 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/left_box-ing_glove.obj 0 12 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/right_box-ing_glove.obj 0 11 0 255 1 0 1 0")
		elseif (details_name == "Geta") then
			run_cmd("obj load data/script/torishop/models/geta_r.obj 0 19 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/geta_l.obj 0 20 0 255 1 0 0 0")
		elseif (details_name == "Flippers") then
			run_cmd("obj load data/script/torishop/models/flipper_r.obj 0 19 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/flipper_l.obj 0 20 0 255 1 0 1 0")
		elseif (details_name == "Flip Flops") then
			run_cmd("obj load data/script/torishop/models/flip_flop_r.obj 0 19 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/flip_flop_l.obj 0 20 0 255 1 0 1 0")
		elseif (details_name == "Kickin' Kicks") then
			run_cmd("obj load data/script/torishop/models/left_kickin'_kick.obj 0 20 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/right_kickin'_kick.obj 0 19 0 255 1 0 1 0")
		elseif (details_name == "Armblades") then
			run_cmd("obj load data/script/torishop/models/right_armblade.obj 0 7 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/left_armblade.obj 0 10 0 255 1 0 0 0")
		elseif (details_name == "Punkspikes") then
			run_cmd("obj load data/script/torishop/models/right_punkspike.obj 0 7 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/left_punkspike.obj 0 10 0 255 1 0 0 0")
		elseif (details_name == "Elbow Pads") then 
			run_cmd("obj load data/script/torishop/models/elbow_pad_r.obj 0 7 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/elbow_pad_l.obj 0 10 0 255 1 0 0 0")
		elseif (details_name == "July Muay Thai Promo") then
			set_joint_force_color(0, 87)
			set_joint_relax_color(0, 116)
			run_cmd("obj load data/script/torishop/models/muay_head.obj 0 0 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/muay_r_biceps.obj 0 6 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/muay_l_biceps.obj 0 9 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/muay_r_hand.obj 0 11 0 255 1 1 1 0")
			run_cmd("obj load data/script/torishop/models/muay_l_hand.obj 0 12 0 255 1 1 1 0")
			run_cmd("obj load data/script/torishop/models/muay_r_foot.obj 0 19 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/muay_l_foot.obj 0 20 0 255 1 0 1 0")
		elseif (details_name == "Tori Pirate") then
			run_cmd("obj load data/script/torishop/models/pirate_hat.obj 0 0 0 255 1 1 0 0")
			run_cmd("obj load data/script/torishop/models/pirate_belt.obj 0 4 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/pirate_hook.obj 0 12 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/peg_leg.obj 0 18 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/peg_leg_foot.obj 0 19 0 255 1 0 1 0")
		elseif (details_name == "Skeletal Tori") then
			run_cmd("obj load data/script/torishop/models/skeletal_head.obj 0 0 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_chest.obj 0 2 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_thorax.obj 0 4 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_r_biceps.obj 0 6 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_r_triceps.obj 0 7 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_l_biceps.obj 0 9 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_l_triceps.obj 0 10 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_r_hand.obj 0 11 0 255 1 1 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_l_hand.obj 0 12 0 255 1 1 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_r_thigh.obj 0 15 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_l_thigh.obj 0 16 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_l_leg.obj 0 17 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_r_leg.obj 0 18 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_r_foot.obj 0 19 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/skeletal_l_foot.obj 0 20 0 255 1 0 1 0")
		elseif (details_name == "Drake") then
			run_cmd("obj load data/script/torishop/models/drake_head.obj 0 0 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/drake_thorax.obj 0 4 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/drake_r_pecs.obj 0 5 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/drake_l_pecs.obj 0 8 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/drake_r_hand.obj 0 11 0 255 1 1 1 0")
			run_cmd("obj load data/script/torishop/models/drake_l_hand.obj 0 12 0 255 1 1 1 0")
			run_cmd("obj load data/script/torishop/models/drake_r_foot.obj 0 19 0 255 1 1 1 0")
			run_cmd("obj load data/script/torishop/models/drake_l_foot.obj 0 20 0 255 1 1 1 0")
		elseif (details_name == "Muay Thai Legend") then
			run_cmd("obj load data/script/torishop/models/muay_head.obj 0 0 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/muay_r_biceps.obj 0 6 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/muay_l_biceps.obj 0 9 0 255 1 0 0 0")
			run_cmd("obj load data/script/torishop/models/muay_r_hand.obj 0 11 0 255 1 1 1 0")
			run_cmd("obj load data/script/torishop/models/muay_l_hand.obj 0 12 0 255 1 1 1 0")
			run_cmd("obj load data/script/torishop/models/muay_r_foot.obj 0 19 0 255 1 0 1 0")
			run_cmd("obj load data/script/torishop/models/muay_l_foot.obj 0 20 0 255 1 0 1 0")
		elseif (details_name == "Tori Armor V2") then
			run_cmd("lp 0ToriArmorV2")
		elseif (details_name == "Tori Ninja") then
			run_cmd("lp 0torininja")
		elseif (details_name == "Halloween Special") then
			run_cmd("lp 0halloweenspecial")
		end
	end
end

function set_player_default_color()
	local section_index = section_order[current_section]
	local name = sections[section_index].name
	
	if (name == "Force Colors") then
		set_joint_force_color(0, player.force)
	elseif (name == "Relax Colors") then
		set_joint_relax_color(0, player.relax)
	elseif (name == "Primary Gradients") then
		set_gradient_primary_color(0, player.pgrad)
	elseif (name == "Secondary Gradients") then
		set_gradient_secondary_color(0, player.sgrad)
	elseif (name == "Torso Colors") then
		set_torso_color(0, player.torso)
	elseif (name == "Blood Colors") then
		set_blood_color(0, player.blood)
	elseif (name == "Ghost Colors") then
		set_ghost_color(0, player.ghost)
	elseif (name == "Grip Colors") then
		local grip_info = set_grip_info(0,11,0)
		remove_hooks("grip")
		is_grip = 0
	elseif (string.find(name, "Motion Trails")) then
		if (player.lhmt[1] == 1 and player.lhmt[2] == 1 and player.lhmt[3] == 1 and player.lhmt[4] == 1) then
			set_separate_trail_color(0, 0, 0)
		else
			set_separate_trail_color_2(0, 0, player.lhmt[1], player.lhmt[2], player.lhmt[3], player.lhmt[4])
		end
		if (player.rhmt[1] == 1 and player.rhmt[2] == 1 and player.rhmt[3] == 1 and player.rhmt[4] == 1) then
			set_separate_trail_color(0, 1, 0)
		else
			set_separate_trail_color_2(0, 1, player.rhmt[1], player.rhmt[2], player.rhmt[3], player.rhmt[4])
		end
		if (player.llmt[1] == 1 and player.llmt[2] == 1 and player.llmt[3] == 1 and player.llmt[4] == 1) then
			set_separate_trail_color(0, 2, 0)
		else
			set_separate_trail_color_2(0, 2, player.llmt[1], player.llmt[2], player.llmt[3], player.llmt[4])
		end
		if (player.rlmt[1] == 1 and player.rlmt[2] == 1 and player.rlmt[3] == 1 and player.rlmt[4] == 1) then
			set_separate_trail_color(0, 3, 0)
		else
			set_separate_trail_color_2(0, 3, player.rlmt[1], player.rlmt[2], player.rlmt[3], player.rlmt[4])
		end
	elseif (name == "DQ Rings") then
		set_ground_impact_color(0, player.impact)
	elseif (name == "Timers") then
		timer_custom_color = false
	elseif (name == "User Text Colors") then
		usertext_custom_color = false
	--elseif (name == "Emote Colors") then
	elseif (name == "Color Packs") then
		set_joint_force_color(0, player.force)
		set_joint_relax_color(0, player.relax)
		set_blood_color(0, player.blood)
		set_gradient_primary_color(0, player.pgrad)
		set_gradient_secondary_color(0, player.sgrad)
		set_torso_color(0, player.torso)
		set_ghost_color(0, player.ghost)
		local grip_info = set_grip_info(0,11,0)
		remove_hooks("grip")
		is_grip = 0
		if (player.lhmt[1] == 1 and player.lhmt[2] == 1 and player.lhmt[3] == 1 and player.lhmt[4] == 1) then
			set_separate_trail_color(0, 0, 0)
		else
			set_separate_trail_color_2(0, 0, player.lhmt[1], player.lhmt[2], player.lhmt[3], player.lhmt[4])
		end
		if (player.rhmt[1] == 1 and player.rhmt[2] == 1 and player.rhmt[3] == 1 and player.rhmt[4] == 1) then
			set_separate_trail_color(0, 1, 0)
		else
			set_separate_trail_color_2(0, 1, player.rhmt[1], player.rhmt[2], player.rhmt[3], player.rhmt[4])
		end
		if (player.llmt[1] == 1 and player.llmt[2] == 1 and player.llmt[3] == 1 and player.llmt[4] == 1) then
			set_separate_trail_color(0, 2, 0)
		else
			set_separate_trail_color_2(0, 2, player.llmt[1], player.llmt[2], player.llmt[3], player.llmt[4])
		end
		if (player.rlmt[1] == 1 and player.rlmt[2] == 1 and player.rlmt[3] == 1 and player.rlmt[4] == 1) then
			set_separate_trail_color(0, 3, 0)
		else
			set_separate_trail_color_2(0, 3, player.rlmt[1], player.rlmt[2], player.rlmt[3], player.rlmt[4])
		end
		set_ground_impact_color(0, player.impact)
		timer_custom_color = false
		usertext_custom_color = false
		set_hair_color(0, 0)
	elseif (name == "Hair Styles") then
		set_hair_settings(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	elseif (name == "Hair Colors") then
		set_hair_color(0, 0)
	elseif (name == "Model Packs") then
		run_cmd("obj unloadall")
	end
end
function set_player_default_all()
		run_cmd("lp 0"..player_name)
end


-- Internal
function change_section(num)
	cart_reload()
	local items_shelf = items_per_shelf
	local items_shelf_next = items_per_shelf_next
	if (main_page == false) then
		current_section = num
		local section = section_order[current_section]
		items_all = sections[section].total_items
		items = items_all
		if (current_section == 32) then 
			total_shelves = math.ceil(items / sale_items_per_shelf)
			total_shelves_all = total_shelves
			total_shelves_all2 = total_shelves
			current_shelf = 1
			if (sections[section].selected_index > 0) then
				current_shelf = math.floor(sections[section].selected_index/sale_items_per_shelf) + 1
				if (sections[section].selected_index % sale_items_per_shelf == 0) then current_shelf = current_shelf - 1 end
			end
		else
			items_usd_all = sections_[section].total_items 
			items_usd_skip = items_usd_all
			items_nextqi = 0
			items_usd = 0
			
			for i = 1, items_all do
				local item_index = i + (current_shelf - 1)*items_shelf
				local shelf_qi = tonumber(sections[section][item_index].qi)
				if (shelf_qi > qi) then items = (items - 1)
					if (shelf_qi <= qi_next) then items_nextqi = (items_nextqi + 1)
					end
				end
			end	
						
			for i = 1, items_usd_all do
				local item_index = i + (current_shelf - 1)*items_shelf
				local shelf_qi = tonumber(sections_[section][item_index].qi)
				local shelf_usd = tonumber(sections_[section][item_index].price_usd)
				if (shelf_qi > qi_next and shelf_usd > 0) then 
					items_usd = (items_usd + 1)
					items_usd_skip = items_usd_skip - 1
				end
			end
			
			total_shelves = math.ceil(items/items_shelf)
			total_shelves_all = math.ceil(items/items_shelf) + math.ceil(items_nextqi/items_shelf_next)
			total_shelves_all2 = math.ceil(items/items_shelf) + math.ceil(items_nextqi/items_shelf_next) + math.ceil(items_usd/items_shelf_next)
			current_shelf = 1
			if (sections[section].selected_index > 0) then
				if (sections[section].selected_index > items) then
					current_shelf = math.floor((sections[section].selected_index - items)/items_shelf_next) + total_shelves + 1
					if (sections[section].selected_index - items)%items_shelf_next == 0 then
						current_shelf = current_shelf - 1
					end
				else
					current_shelf = math.floor(sections[section].selected_index/items_shelf) + 1
					if (sections[section].selected_index % items_shelf == 0) then current_shelf = current_shelf - 1 end
				end
			else 
				current_shelf = math.floor(sections_[section].selected_index/items_shelf_next) + total_shelves_all + 1
				if (sections_[section].selected_index % items_shelf_next == 0) then current_shelf = current_shelf - 1 end
			end	
		end
	end
end

function change_shelf(num)
	current_shelf = current_shelf + num
	if (current_shelf < 1) then
		current_shelf = total_shelves_all2
	elseif (current_shelf > total_shelves_all2) then
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
function select_scolor_links(state)
	if (state == BTN_UP) then
		set_color(1,1,1,1)
		section_marked = false
	elseif (state == BTN_DOWN) then
		set_color(0.5,0.5,0.5,1)
		section_marked = true
	else
		set_color(1,1,1,1)
		section_marked = true
	end
end

function clear_ss_icons()
	for j = 1, sub_in_section do
		if (ss_icon[j]) then unload_texture(ss_icon[j]) end
		ss_icon[j] = nil
	end
end

function clear_icons()
	for k = 1, items_per_shelf do
		pos_icon[k] = nil
		if (icon[k]) then unload_texture(icon[k]) end
	end
	clear_ss_icons()
end

function cart_reload()
	for j = 1, 5 do
		if (cart_icon[j]) then 
			unload_texture(cart_icon[j])
			cart_icon[j] = nil
		end
	end
end

local MOUSE_UP = 0
local MOUSE_DOWN = 1
local mouse_state = MOUSE_UP

function btn_dn(button, x, y)
	if (x > button.x and x < (button.x + button.w) and y > button.y and y < (button.y + button.h)) then
		button.state = BTN_DOWN
	end
end

function mouse_down(mouse_btn, x, y)
	mouse_state = MOUSE_DOWN
	
	if (x > buttons.torishop.x and x < (buttons.torishop.x + buttons.torishop.w) and y > buttons.torishop.y and y < (buttons.torishop.y + buttons.torishop.h)) then
		buttons.torishop.state = BTN_DOWN
	end
	
	btn_dn(buttons.tomain, x, y)
	
	if (main_page == true) then
		local r = button_click_radius
		for i, v in pairs(buttons.arrows) do
			if (v == buttons.arrows.cart_next or v == buttons.arrows.cart_prev or v == buttons.arrows.cart_min) then
				if (x > (v.x - r) and x < (v.x + r) and y > (v.y - r) and y < (v.y + r)) then
					v.state = BTN_DOWN
				end
			end
		end
		if (x > buttons.mainsingle.x and x < (buttons.mainsingle.x + buttons.mainsingle.w) and y > buttons.mainsingle.y and y < (buttons.mainsingle.y + buttons.mainsingle.h)) then
			buttons.mainsingle.state = BTN_DOWN
		end
		if (x > buttons.mainfull.x and x < (buttons.mainfull.x + buttons.mainfull.w) and y > buttons.mainfull.y and y < (buttons.mainfull.y + buttons.mainfull.h)) then
			buttons.mainfull.state = BTN_DOWN
		end
		if (sale == true) then
			btn_dn(buttons.sonsale, x, y)
		end
		if (main_view == 0) then
			btn_dn(buttons.mainsingle, x, y)
			btn_dn(buttons.mainfull, x, y)
		elseif (main_view == 1) then
			btn_dn(buttons.scolors, x, y)
			btn_dn(buttons.stextures, x, y)
			btn_dn(buttons.shairs, x, y)
			btn_dn(buttons.smisc, x, y)
		else
			btn_dn(buttons.scolorpacks, x, y)
			btn_dn(buttons.stexturesets, x, y)
			btn_dn(buttons.smodelpacks, x, y)
			btn_dn(buttons.sfulltoris, x, y)
		end
		btn_dn(buttons.sflames, x, y)
	
	else
		
		local r = button_click_radius
		for i, v in pairs(buttons.arrows) do
			if (x > (v.x - r) and x < (v.x + r) and y > (v.y - r) and y < (v.y + r)) then
				v.state = BTN_DOWN
			end
		end
		
			btn_dn(buttons.none, x, y)
			btn_dn(buttons.default, x, y)
		
		if (details_name == "Forum VIP" or details_name == "Halloween Special") then
			btn_dn(buttons.info_prime, x, y)
		end
		
		if (cart_current > 0) then
			btn_dn(buttons.cartbuy, x, y)
		
			for i = 1, 5 do
				if (x > cartbuttons[i].cartremove.x and x < (cartbuttons[i].cartremove.x + cartbuttons[i].cartremove.w) and y > cartbuttons[i].cartremove.y and y < (cartbuttons[i].cartremove.y + cartbuttons[i].cartremove.h)) then
					cartremovestate[i] = BTN_DOWN
				end
			end
		end
		
		for ss = 1, sub_in_section do
			btn_dn(buttons[ss].choose_ss, x, y)
		end
		
		for i = 1, items_per_shelf do
			btn_dn(buttons[i].icon, x, y)
			btn_dn(buttons.buy, x, y)
			btn_dn(buttons.tocarttc, x, y)
			btn_dn(buttons.buysteam, x, y)
			btn_dn(buttons.gettc, x, y)	
		end
	end
	
	if confirm_name ~= nil then
		btn_dn(buttons.confirm, x, y)
		btn_dn(buttons.cancel, x, y)
	end
end

function gotosection(button, sale, mainsection, section, x, y)
	if (x > button.x and x < (button.x + button.w) and y > button.y and y < (button.y + button.h)) then
		button.state = BTN_UP
		main_section = mainsection
		if (sale == true) then
			buttons.tomain.y = 15
			buttons.tomain.x = 428
		else 
			buttons.tomain.y = 43
			buttons.tomain.x = 400
		end
		current_section = section
		ss_shift = section - 1
		current_shelf = 1
		first = true
		main_page = false
		if (sections[current_section].selected_index == 0) then
			sections[current_section].selected_index = 1
		end
		change_ss()
		change_section(current_section)
		clear_icons() 
	end
end

function gotofeatured(button, mainsection, section, sectionshift, x, y, url)
	if (x > button.x and x < (button.x + button.w) and y > button.y and y < (button.y + button.h)) then
		if (url ~= nil) then
			if (url == "flames") then
				tempflag = 1
				view_flames()
			elseif (url == "shop_announcement") then
				close_torishop()
				start_new_game()
				run_cmd("ls2 shop_announcement.lua -override")
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
			else
				open_url(url)
			end
		else
			buttons.tomain.y = 43
			buttons.tomain.x = 400
			main_section = mainsection
			current_section = section
			ss_shift = sectionshift
			current_shelf = 1
			first = true
			main_page = false
			if (sections[current_section].selected_index == 0) then
				sections[current_section].selected_index = 1
			end
			change_ss()
			change_section(current_section)
			clear_icons() 
		end
	end
end

function mouse_up(mouse_btn, x, y)
	mouse_state = MOUSE_UP
	local section_index = section_order[current_section]	
	
	if (x > buttons.torishop.x and x < (buttons.torishop.x + buttons.torishop.w) and y > buttons.torishop.y and y < (buttons.torishop.y + buttons.torishop.h)) then
		buttons.torishop.state = BTN_HOVER
		--open_url("http://www.toribash.com/forum/tori_inventory.php")	-- NON-STEAM
		run_cmd("it")                                           	 	-- STEAM
	end
	
	if confirm_name ~= nil then
		if (x > buttons.confirm.x and x < (buttons.confirm.x + buttons.confirm.w) and y > buttons.confirm.y and y < (buttons.confirm.y + buttons.confirm.h)) then
			buttons.confirm.state = BTN_HOVER
			if ((details_price ~= 0) and (buysteam == false)) then 
				if (buy_type == SINGLE_ITEM) then 
					run_cmd("bi " .. confirm_id)
				elseif (buy_type == CART_ITEMS) then
					run_cmd("mbi " .. cart_current .. " " .. confirm_id)
					for i = 1, #cart do
						cart[i] = nil
					end
					cart_current = 0
				end
			else
				run_cmd("steam purchase "..confirm_id)                                           	  -- STEAM
				--open_url("http://forum.toribash.com/tori_shop.php?action=proceed&item="..confirm_id)  -- NON-STEAM
			end
			confirm_name = nil
			confirm_id = nil
			buysteam = false
			buy_type = SINGLE_ITEM
		end
	
		if (x > buttons.cancel.x and x < (buttons.cancel.x + buttons.cancel.w) and y > buttons.cancel.y and y < (buttons.cancel.y + buttons.cancel.h)) then
			buttons.cancel.state = BTN_HOVER
			confirm_name = nil
			confirm_id = nil
		end
	end
	
	if (main_page == true) then
		local r = button_click_radius
		for i, v in pairs(buttons.arrows) do
			if (x > (v.x - r) and x < (v.x + r) and y > (v.y - r) and y < (v.y + r)) then
				v.state = BTN_HOVER
				if (v == buttons.arrows.cart_next) then
					if (cart_shift + 5 <= cart_current) then
						cart_shift = cart_shift + 5
						cart_reload()
					end
				elseif (v == buttons.arrows.cart_prev) then
					if (cart_shift - 5 >= 0) then
						cart_shift = cart_shift - 5
						cart_reload()
					end
				elseif (v == buttons.arrows.cart_min) then
					if (cart_minimize == false) then cart_minimize = true
					else cart_minimize = false
					end
				end
			end
		end
		if (sale == true) then
			gotosection(buttons.sonsale, true, 9, 32, x, y)
		end
		if (main_view == 0) then
			if (x > buttons.mainsingle.x and x < (buttons.mainsingle.x + buttons.mainsingle.w) and y > buttons.mainsingle.y and y < (buttons.mainsingle.y + buttons.mainsingle.h)) then
				main_view = 1
				featuredseed = math.random(0,1)
			end
			if (x > buttons.mainfull.x and x < (buttons.mainfull.x + buttons.mainfull.w) and y > buttons.mainfull.y and y < (buttons.mainfull.y + buttons.mainfull.h)) then
				main_view = 2
			end
		elseif (main_view == 1) then
			gotosection(buttons.scolors, false, 1, 1, x, y)
			gotosection(buttons.stextures, false, 2, 15, x, y)
			gotosection(buttons.shairs, false, 3, 21, x, y)
			gotosection(buttons.smisc, false, 4, 24, x, y)
		else 
			gotosection(buttons.scolorpacks, false, 5, 27, x, y)
			gotosection(buttons.stexturesets, false, 6, 29, x, y)
			gotosection(buttons.smodelpacks, false, 7, 30, x, y)
			gotosection(buttons.sfulltoris, false, 8, 31, x, y)
		end
		if (x > buttons.sflames.x and x < (buttons.sflames.x + buttons.sflames.w) and y > buttons.sflames.y and y < (buttons.sflames.y + buttons.sflames.h)) then
			buttons.sflames.state = BTN_HOVER
			tempflag = 1
			view_flames()
		end
		if (height >= 720) then
			gotofeatured(buttons.sfeatured, 3, 23, 20, x, y)
		end
	else
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
			elseif (v == buttons.arrows.cart_next) then
				if (cart_shift + 5 <= cart_current) then
					cart_shift = cart_shift + 5
					cart_reload()
				end
			elseif (v == buttons.arrows.cart_prev) then
				if (cart_shift - 5 >= 0) then
					cart_shift = cart_shift - 5
					cart_reload()
				end
			elseif (v == buttons.arrows.cart_min) then
				if (cart_minimize == false) then cart_minimize = true
				else cart_minimize = false
				end
			end
		end
	end
	
	if (x > buttons.none.x and x < (buttons.none.x + buttons.none.w) and y > buttons.none.y and y < (buttons.none.y + buttons.none.h)) then
		buttons.none.state = BTN_HOVER
		if (sections[section_index].try == true) then
			sections[section_index].selected_index = 0
			set_player_default_color()
			details_name = nil
			clear_icons()
		end
	end

	if (x > buttons.default.x and x < (buttons.default.x + buttons.default.w) and y > buttons.default.y and y < (buttons.default.y + buttons.default.h)) then
		buttons.default.state = BTN_HOVER
		if (sections[section_index].try == true) then
			sections[section_index].selected_index = 0
			set_player_default_all()
			details_name = nil
			clear_icons()
		end
	end
	
	if (details_name == "Forum VIP") then
	if (x > buttons.info_prime.x and x < (buttons.info_prime.x + buttons.info_prime.w) and y > buttons.info_prime.y and y < (buttons.info_prime.y + buttons.info_prime.h)) then
		buttons.info_prime.state = BTN_HOVER
		open_url("http://forum.toribash.com/faq.php?faq=forum_main#faq_forum_vip")
	end
	elseif (details_name == "Halloween Special") then
	if (x > buttons.info_prime.x and x < (buttons.info_prime.x + buttons.info_prime.w) and y > buttons.info_prime.y and y < (buttons.info_prime.y + buttons.info_prime.h)) then
		buttons.info_prime.state = BTN_HOVER
		open_url("http://forum.toribash.com/tori_token_exchange.php")
	end
	end
	
	for ss = 1, sub_in_section do
		if (x > buttons[ss].choose_ss.x and x < (buttons[ss].choose_ss.x + buttons[ss].choose_ss.w) and y > buttons[ss].choose_ss.y and y < (buttons[ss].choose_ss.y + buttons[ss].choose_ss.h)) then
			buttons[ss].choose_ss.state = BTN_HOVER
			current_shelf = 1 
			if (main_section == 1) then ss_shift = 0
			elseif (main_section == 2) then ss_shift = 14
			elseif (main_section == 3) then ss_shift = 20
			elseif (main_section == 4) then ss_shift = 23
			elseif (main_section == 5) then ss_shift = 26
			elseif (main_section == 6) then ss_shift = 28
			elseif (main_section == 7) then ss_shift = 29
			elseif (main_section == 8) then ss_shift = 30
			elseif (main_section == 9) then ss_shift = 31
			end 
			if (sections[ss_shift+ss].selected_index == 0) then
				sections[ss_shift+ss].selected_index = 1
			end
			change_section(ss_shift+ss)
			clear_icons()
		end
	end
	
	if (current_shelf <= total_shelves) then
		local per_shelf, ignore_qi = nil
		if (current_section == 32) then
			per_shelf = sale_items_per_shelf
			ignore_qi = 1
		else 
			per_shelf = items_per_shelf
			ignore_qi = nil
		end
		
		for i = 1, per_shelf do
			local item_index = i + (current_shelf - 1)*per_shelf
			if (item_index > #sections[section_index]) then
                break
            end
			if (x > buttons[i].icon.x and x < (buttons[i].icon.x + buttons[i].icon.w) and y > buttons[i].icon.y and y < (buttons[i].icon.y + buttons[i].icon.h)) then
				local shelf_qi = tonumber(sections[section_index][item_index].qi)
				if (shelf_qi <= qi or ignore_qi) then
					buttons[i].icon.state = BTN_HOVER
					details_qi = tonumber(sections[section_index][item_index].qi)
					details_name = sections[section_index][item_index].name
					details_tier = sections[section_index][item_index].tier
					details_price = tonumber(sections[section_index][item_index].price)
					details_price_usd = sections[section_index][item_index].price_usd
					details_id = sections[section_index][item_index].id
					sections[section_index].selected_index = item_index
					if (current_section ~= 32) then 
						sections_[section_index].selected_index = 0
					end
					change_section_first[section_index] = 0
					if (sections[section_index].try == true) then
						if section_index == 29 then
							apply_texture(details_name, section_index)							
						elseif section_index < 33 then
							set_player_color(item_index)
						else
							apply_texture(details_name, section_index)
						end
					end
				end
			end
		end
	elseif (current_shelf <= total_shelves_all) then
		for i = 1, items_per_shelf_next do
			local item_index = i + (current_shelf - total_shelves - 1)*items_per_shelf_next + items
			if (item_index > #sections[section_index]) then
                break
            end
			local shelf_qi = tonumber(sections[section_index][item_index].qi)
			if (shelf_qi <= qi_next) then
			if (x > buttons[i].icon.x and x < (buttons[i].icon.x + buttons[i].icon.w) and y > buttons[i].icon.y and y < (buttons[i].icon.y + buttons[i].icon.h)) then
			buttons[i].icon.state = BTN_HOVER
			details_name = sections[section_index][item_index].name
			details_qi = tonumber(sections[section_index][item_index].qi)
			details_tier = sections[section_index][item_index].tier
			details_price = tonumber(sections[section_index][item_index].price)
			details_price_usd = sections[section_index][item_index].price_usd
			details_id = sections[section_index][item_index].id
			sections[section_index].selected_index = item_index
			sections_[section_index].selected_index = 0
			change_section_first[section_index] = 0
				if (sections[section_index].try == true) then
					set_player_color(item_index)
				end
				end
			end
		end
	else
		for i = 1, items_per_shelf_next do
			local item_index = i + (current_shelf - total_shelves_all - 1)*items_per_shelf_next + items_usd_skip
			if (item_index > #sections_[section_index]) then
                break
            end
			local shelf_qi = tonumber(sections_[section_index][item_index].qi)
			if (shelf_qi > qi_next) then
			if (x > buttons[i].icon.x and x < (buttons[i].icon.x + buttons[i].icon.w) and y > buttons[i].icon.y and y < (buttons[i].icon.y + buttons[i].icon.h)) then
			buttons[i].icon.state = BTN_HOVER
			details_name = sections_[section_index][item_index].name
			details_qi = tonumber(sections_[section_index][item_index].qi)
			details_tier = sections_[section_index][item_index].tier
			details_price = tonumber(sections_[section_index][item_index].price)
			details_price_usd = sections_[section_index][item_index].price_usd
			details_id = sections_[section_index][item_index].id
			sections_[section_index].selected_index = item_index
			sections[section_index].selected_index = 0
			change_section_first[section_index] = 0
				if (sections_[section_index].try == true) then
					set_player_color(item_index)
				end
				end
			end
		end
	end
		
	if (x > buttons.buy.x and x < (buttons.buy.x + buttons.buy.w) and y > buttons.buy.y and y < (buttons.buy.y + buttons.buy.h)) then
		buttons.buy.state = BTN_HOVER
			if (can_buy == true and details_price > 0) then
				if (string.find(string.lower(details_name), "head texture") and current_section < 33) then
					main_section = 9 ss_shift = 32 current_shelf = 1 first = true
					if string.find(string.lower(details_name), "128") then current_section = 33
					elseif string.find(string.lower(details_name), "256") then current_section = 34
					elseif string.find(string.lower(details_name), "512") then current_section = 35 end
					main_page = false
					if (sections[current_section].selected_index == 0) then
						sections[current_section].selected_index = 1
					end
					change_ss() change_section(current_section) clear_icons() 
				else
					buy_type = SINGLE_ITEM
					confirm_name = details_name
					confirm_id = details_id
				end
			end				
	end
	if (x > buttons.tocarttc.x and x < (buttons.tocarttc.x + buttons.tocarttc.w) and y > buttons.tocarttc.y and y < (buttons.tocarttc.y + buttons.tocarttc.h)) then
		buttons.tocarttc.state = BTN_HOVER
		if (details_price > 0 and can_buy == true and cart_sum + details_price <= tc and cart_current < 10) then
			if (string.find(string.lower(details_name), "head texture") and current_section < 33) then
				main_section = 9 ss_shift = 32 current_shelf = 1 first = true
				if string.find(string.lower(details_name), "128") then current_section = 33
				elseif string.find(string.lower(details_name), "256") then current_section = 34
				elseif string.find(string.lower(details_name), "512") then current_section = 35 end
				main_page = false
				if (sections[current_section].selected_index == 0) then
					sections[current_section].selected_index = 1
				end
				change_ss() change_section(current_section) clear_icons() 
			else
				if (cart_type == nil) then
					cart_type = 1
				end
				if (cart_type == 1 and cart_current < 10) then
					cart_current = cart_current + 1
					cart[cart_current] = { name = details_name, price = details_price, id = details_id}
					if (string.find(details_name, "Secondary Gradient")) then
						cart[cart_current].name = string.gsub(details_name, "Secondary Gradient", "sec. grad.")
					end
					if (string.find(details_name, "Primary Gradient")) then
						cart[cart_current].name = string.gsub(details_name, "Primary Gradient", "pr. grad.")
					end
					if (string.find(details_name, "Right Leg Trail")) then
						cart[cart_current].name = string.gsub(details_name, "Right Leg Trail", "rlmt")
					end
					if (string.find(details_name, "Left Leg Trail")) then
						cart[cart_current].name = string.gsub(details_name, "Left Leg Trail", "llmt")
					end
					if (string.find(details_name, "Right Hand Trail")) then
						cart[cart_current].name = string.gsub(details_name, "Right Hand Trail", "rhmt")
					end
					if (string.find(details_name, "Left Hand Trail")) then
						cart[cart_current].name = string.gsub(details_name, "Left Hand Trail", "lhmt")
					end
				end
			end
		elseif (cart_current == 10) then
			cart_warning[2] = true
		elseif (cart_sum + details_price > tc) then
			cart_warning[1] = true
		end
	end
	
	if (details_price_usd ~= "0.00") then
		if (x > buttons.buysteam.x and x < (buttons.buysteam.x + buttons.buysteam.w) and y > buttons.buysteam.y and y < (buttons.buysteam.y + buttons.buysteam.h)) then
			buttons.buysteam.state = BTN_HOVER
			if (string.find(string.lower(details_name), "head texture") and current_section < 33) then
					main_section = 9 ss_shift = 32 current_shelf = 1 first = true
					if string.find(string.lower(details_name), "128") then current_section = 33
					elseif string.find(string.lower(details_name), "256") then current_section = 34
					elseif string.find(string.lower(details_name), "512") then current_section = 35 end
					main_page = false
					if (sections[current_section].selected_index == 0) then
						sections[current_section].selected_index = 1
					end
					change_ss() change_section(current_section) clear_icons() 
			else		
				buysteam = true
				buy_type = SINGLE_ITEM
				confirm_name = details_name
				confirm_id = details_id
			end
		end
	end
	if ((details_price > tc) and (details_qi <= qi)) then
		if (x > buttons.gettc.x and x < (buttons.gettc.x + buttons.gettc.w) and y > buttons.gettc.y and y < (buttons.gettc.y + buttons.gettc.h)) then
			buttons.gettc.state = BTN_HOVER
			open_menu(15)
		end
	end
	end
	if (cart_current > 0) then
		if (x > buttons.cartbuy.x and x < (buttons.cartbuy.x + buttons.cartbuy.w) and y > buttons.cartbuy.y and y < (buttons.cartbuy.y + buttons.cartbuy.h)) then
			buttons.cartbuy.state = BTN_HOVER
				confirm_name = "all items from the cart"
				confirm_id = ""
				buy_type = CART_ITEMS
				for i = 1, #cart do
					if (i > 1) then 
						confirm_id = confirm_id .. ","
					end
				confirm_id = confirm_id .. cart[i].id
			end				
		end
		
		for i = 1, 5 do
			if (x > cartbuttons[i].cartremove.x and x < (cartbuttons[i].cartremove.x + cartbuttons[i].cartremove.w) and y > cartbuttons[i].cartremove.y and y < (cartbuttons[i].cartremove.y + cartbuttons[i].cartremove.h)) then
				cartremovestate[i] = BTN_HOVER
				for j = i + cart_shift, cart_current - 1 do
					cart[j] = cart[j + 1]
				end
				cart[cart_current] = nil
				cart_current = cart_current - 1
				if (cart_current == cart_shift and cart_current ~= 0) then cart_shift = cart_shift - 5 end
				cart_reload()
				break
			end
		end
	end
	
	if (main_view ~= 0 or main_page == false) then
		if (x > buttons.tomain.x and x < (buttons.tomain.x + buttons.tomain.w) and y > buttons.tomain.y and y < (buttons.tomain.y + buttons.tomain.h)) then
			buttons.tomain.state = BTN_HOVER
			if (current_section >= 33) then
				main_section = 2
				current_section = current_section - 18
				ss_shift = 14
				current_shelf = 1
				first = true
				change_ss()
				change_section(current_section)
				clear_icons() 
			else
				if (sale_icon) then unload_texture(sale_icon) end
				sale_icon = nil
				if (main_page == true) then
					main_view = 0
					featuredseed = math.random(0,1)
				else
					main_page = true
					featuredseed = math.random(0,1)
				end
				buttons.tomain.y = 10
				buttons.tomain.x = 428
				change_announcement = true
				main_section = 0
				clear_icons()
			end
		end
	end
end

function btn_move(button, x, y)
	if (x > button.x and x < (button.x + button.w) and y > button.y and y < (button.y + button.h)) then
		if (mouse_state == MOUSE_DOWN) then
			button.state = BTN_DOWN
		else
			button.state = BTN_HOVER
		end
	else
		button.state = BTN_UP
	end
end

function mouse_move(x, y)
	btn_move(buttons.torishop, x, y)
	
	if confirm_name ~= nil then
		btn_move(buttons.confirm, x, y)
		btn_move(buttons.cancel, x, y)
	end
	
	btn_move(buttons.tomain, x, y)
	
	if (main_page == true) then
		local r = button_click_radius
		for i, v in pairs(buttons.arrows) do
			if (v == buttons.arrows.cart_next or v == buttons.arrows.cart_prev or v == buttons.arrows.cart_min) then
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
		end
		if (sale == true) then
			btn_move(buttons.sonsale, x, y)
		end
		if (main_view == 0) then
			btn_move(buttons.mainsingle, x, y)
			btn_move(buttons.mainfull, x, y)
		elseif (main_view == 1) then
			btn_move(buttons.scolors, x, y)
			btn_move(buttons.stextures, x, y)
			btn_move(buttons.shairs, x, y)
			btn_move(buttons.smisc, x, y)
		else
			btn_move(buttons.scolorpacks, x, y)
			btn_move(buttons.stexturesets, x, y)
			btn_move(buttons.smodelpacks, x, y)
			btn_move(buttons.sfulltoris, x, y)
		end
		btn_move(buttons.sflames, x, y)
	else
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
		
		btn_move(buttons.none, x, y)
		btn_move(buttons.default, x, y)
		if (details_name == "Forum VIP" or details_name == "Halloween Special") then
			btn_move(buttons.info_prime, x, y)
		end
		
		for ss = 1, sub_in_section do
			if (x > buttons[ss].choose_ss.x and x < (buttons[ss].choose_ss.x + buttons[ss].choose_ss.w) and y > buttons[ss].choose_ss.y and y < (buttons[ss].choose_ss.y + buttons[ss].choose_ss.h)) then
				if (mouse_state == MOUSE_DOWN) then
					buttons[ss].choose_ss.state = BTN_DOWN
				else
					buttons[ss].choose_ss.state = BTN_HOVER
				end
			else
				buttons[ss].choose_ss.state = BTN_UP
			end
		end	
		
		for i = 1, items_per_shelf do
			btn_move(buttons[i].icon, x, y)
			btn_move(buttons.buy, x, y)
			btn_move(buttons.tocarttc, x, y)
			btn_move(buttons.buysteam, x, y)
			btn_move(buttons.gettc, x, y)		
		end
	end
	if (cart_current > 0) then
		btn_move(buttons.cartbuy, x, y)
		
		for i = 1, 5 do
		if (x > cartbuttons[i].cartremove.x and x < (cartbuttons[i].cartremove.x + cartbuttons[i].cartremove.w) and y > cartbuttons[i].cartremove.y and y < (cartbuttons[i].cartremove.y + cartbuttons[i].cartremove.h)) then
			if (mouse_state == MOUSE_DOWN) then
				cartremovestate[i] = BTN_DOWN
			else
				cartremovestate[i] = BTN_HOVER
			end
		else
			cartremovestate[i] = BTN_UP
		end
	end	
	end
end

function key_down(key)
	--[[if (key == string.byte(' ')) then
		draw_ground_impact(0)		
		return 1
	end--]]
end
function key_up(key)
	if (key ~= string.byte('z') and key ~= string.byte('x') and key ~= string.byte('c')) then
		return 1
	end
end

function get_main_sale_time(item)
	local timeleft = sections[32][item].timeleft
	local timetype = "second"
	local timemod = 0
	local returnstring = ""
	
	if tonumber(timeleft) <= 0 then return "Sale is over!" end
	
	if (math.floor(timeleft / 86400) > 1) then
		timetype = "days"
		timeleft = math.floor(timeleft / 86400)
	elseif (math.floor(timeleft / 86400) == 1) then
		timetype = "day"
		timeleft = math.floor(timeleft / 86400)
	elseif (math.floor(timeleft / 3600) > 1) then
		timetype = "hours"
		timeleft = math.floor(timeleft / 3600)
	elseif (math.floor(timeleft / 3600) == 1) then
		timetype = "hour"
		timeleft = math.floor(timeleft / 3600)
	elseif (math.floor(timeleft / 60) > 1) then
		timetype = "minutes"
		timeleft = math.floor(timeleft / 60)
	elseif (math.floor(timeleft / 60) == 1) then
		timetype = "minute"
		timeleft = math.floor(timeleft / 60)
	elseif (timeleft > 1) then 
		timetype = "seconds"
	end
	
	returnstring = timeleft .. " " .. timetype .. " left"
	return returnstring
end

function get_sale_time(item)
	local timeleft = sections[32][item].timeleft
	local timeprint = timeleft
	local timetype = "second"
	local timemod = 0
	local returnstring = ""
	
	for i = 1, 2 do
		if (math.floor(timeleft / 2592000) > 1) then
			timetype = "months"
			timeprint = math.floor(timeleft / 2592000)
		elseif (math.floor(timeleft / 2592000) == 1) then
			timetype = "month"
			timeprint = math.floor(timeleft / 2592000)
		elseif (math.floor(timeleft / 604800) > 1) then
			timetype = "weeks"
			timeprint = math.floor(timeleft / 604800)
			timemod = 604800
		elseif (math.floor(timeleft / 604800) == 1) then
			timetype = "week"
			timeprint = math.floor(timeleft / 604800)
			timemod = 604800
		elseif (math.floor(timeleft / 86400) > 1) then
			timetype = "days"
			timeprint = math.floor(timeleft / 86400)
			timemod = 86400
		elseif (math.floor(timeleft / 86400) == 1) then
			timetype = "day"
			timeprint = math.floor(timeleft / 86400)
			timemod = 86400
		elseif (math.floor(timeleft / 3600) > 1) then
			timetype = "hours"
			timeprint = math.floor(timeleft / 3600)
			timemod = 3600
		elseif (math.floor(timeleft / 3600) == 1) then
			timetype = "hour"
			timeprint = math.floor(timeleft / 3600)
			timemod = 3600
		elseif (math.floor(timeleft / 60) > 1) then
			timetype = "minutes"
			timeprint = math.floor(timeleft / 60)
			timemod = 60
		elseif (math.floor(timeleft / 60) == 1) then
			timetype = "minute"
			timeprint = math.floor(timeleft / 60)
			timemod = 60
		elseif (timeleft > 1) then 
			timetype = "seconds"
			timeprint = timeleft
			timemod = 0
		end
		
		if (timeleft < 0) then
			return "Sale is over!"
		end
		
		returnstring = returnstring .. timeprint .. " " .. timetype .. " "
		if (timemod == 0) then
			return returnstring
		else
			timeleft = timeleft - timemod * timeprint
		end
	end
	return returnstring .. "left"
end	


-- Drawing

function draw_item(section, item, pos, marked, flag)	-- the section the item is from, the item index in the section, the shelf position, whether it is selected
	local name, id = 0, 0
	local w_add = 100
	
	if (flag == 1) then
		name = sections[section][item].name
		id = sections[section][item].id
	else 
		name = sections_[section][item].name
		id = sections_[section][item].id
	end
		
	if (string.find(name, "Secondary Gradient")) then
		name = string.gsub(name, "Secondary Gradient", "Sec. Grad.")
	end
	if (string.find(name, "Primary Gradient")) then
		name = string.gsub(name, "Primary Gradient", "Pr. Grad.")
	end
	
	-- Item Icons	
	if (current_shelf <= total_shelves) then
		if (pos == 1) then
			w_shelf = 64
			h_shelf = 360
		end
		if (w_shelf + 100 > 490) then 
			w_shelf = 64
			h_shelf = h_shelf + 100
		end
		if (h_shelf + 100 > height) then
			h_shelf = 360
		end
	else
		if (pos == 1) then
			w_shelf = 64
			h_shelf = 400
		end
		if (w_shelf + w_add > 490) then 
			w_shelf = 64
			h_shelf = h_shelf + 100
		end
		if (h_shelf + 140 > height) then
			h_shelf = 400
		end
	end

	name = name:lower()
	
	-- HALLOWEEN SPECIALS
	if ((string.find(name, "frankenbolts")) or 
		((string.find(name, "jack")) and (string.find(name, "lantern"))) or 
		(string.find(name, "button eyes")) or 
		(string.find(name, "brain")) or 
		(string.find(name, "demon wings")) or 
		(string.find(name, "halloween special")) or 
		(string.find(name, "skull necklace"))) then
		select_color(0.95,0.83,0.01,0.4,marked,0.95,0.83,0.01,0.8)
	else
		select_color(1,1,1,0.23,marked,0,0,0,0.4)
	end
	
	-- CHRISTMAS SPECIALS
	if ((string.find(name, "santa hat")) or 
		(string.find(name, "santa beard")) or 
		(string.find(name, "candy cane")) or 
		(string.find(name, "little latching elf")) or 
		(string.find(name, "elven hat"))) then
		select_color(0.6,0.7,0.95,0.8,marked,0.4,0.5,0.95,0.8)
	else
		select_color(1,1,1,0.23,marked,0,0,0,0.4)
	end
	
	buttons[pos].icon = { x = w_shelf, y = h_shelf, w = 64, h = 64, state = BTN_UP }
	if (buttons[pos].icon.state == BTN_UP) then
		draw_disk(buttons[pos].icon.x+20, buttons[pos].icon.y+20, 0, 30, 500, 1, -180, 90, 0)
		draw_disk(buttons[pos].icon.x+20, buttons[pos].icon.y+44, 0, 30, 500, 1, -90, 90, 0)
		draw_disk(buttons[pos].icon.x+44, buttons[pos].icon.y+20, 0, 30, 500, 1, 90, 90, 0)
		draw_disk(buttons[pos].icon.x+44, buttons[pos].icon.y+44, 0, 30, 500, 1, 0, 90, 0)
		draw_quad(buttons[pos].icon.x-10, buttons[pos].icon.y+20, 84, 24)
		draw_quad(buttons[pos].icon.x+20, buttons[pos].icon.y-10, 24, 30)
		draw_quad(buttons[pos].icon.x+20, buttons[pos].icon.y+44, 24, 30) end
	set_color(1,1,1,1)
	if (pos_icon[pos] == nil) then
		local tempicon = io.open("data/textures/store/items/"..id..".tga", "r", 1)
		if (tempicon == nil) then
			icon[pos] = load_texture("../textures/store/default.tga")
		else
			icon[pos] = load_texture("../textures/store/items/"..id..".tga")
			io.close(tempicon)
		end
		pos_icon[pos] = 1 
	end
	draw_quad(buttons[pos].icon.x, buttons[pos].icon.y, 64, 64, icon[pos])
	w_shelf = w_shelf + w_add
end

function tc_format(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

function usd_format(n)
	local dot = string.find(n, ".")
	if (dot == nil) then
		return dot..".00"
	elseif (dot == string.len(n) - 1) then
		return dot.."0"
	else
		return dot
	end
end

function draw_sale_item(item, pos, marked)
	local name = sections[32][item].name
	local id = sections[32][item].id
	
	local timeleft_length = get_string_length(get_sale_time(item), FONTS.MEDIUM)
	
	if (string.find(name, "Secondary Gradient")) then
		name = string.gsub(name, "Secondary Gradient", "Sec. Grad.")
	end
	if (string.find(name, "Primary Gradient")) then
		name = string.gsub(name, "Primary Gradient", "Pr. Grad.")
	end
	
	
	buttons[pos].icon = { x = 49, y = 345 + (pos - 1) * 100, w = 392, h = 94, state = BTN_UP }
	select_color(1,1,1,0.23,marked,0,0,0,0.4)
	if (buttons[pos].icon.state == BTN_UP) then
		draw_disk(buttons[pos].icon.x+35, buttons[pos].icon.y+35, 0, 30, 500, 1, -180, 90, 0)
		draw_disk(buttons[pos].icon.x+35, buttons[pos].icon.y+59, 0, 30, 500, 1, -90, 90, 0)
		draw_disk(buttons[pos].icon.x+357, buttons[pos].icon.y+35, 0, 30, 500, 1, 90, 90, 0)
		draw_disk(buttons[pos].icon.x+357, buttons[pos].icon.y+59, 0, 30, 500, 1, 0, 90, 0)
		draw_quad(buttons[pos].icon.x+5, buttons[pos].icon.y+35, 382, 24)
		draw_quad(buttons[pos].icon.x+35, buttons[pos].icon.y+5, 322, 30)
		draw_quad(buttons[pos].icon.x+35, buttons[pos].icon.y+59, 322, 30) end
	set_color(1,1,1,1)
	if (pos_icon[pos] == nil) then
		local tempicon = io.open("data/textures/store/items/"..id..".tga", "r", 1)
		if (tempicon == nil) then
			icon[pos] = load_texture("../textures/store/default.tga")
		else
			icon[pos] = load_texture("../textures/store/items/"..id..".tga")
			io.close(tempicon)
		end
		pos_icon[pos] = 1 
	end
	draw_quad(buttons[pos].icon.x + 20, buttons[pos].icon.y + 15, 64, 64, icon[pos])
	select_color(0,0,0,1,marked,1,1,1,1)	
	draw_text(get_sale_time(item), 420 - timeleft_length, buttons[pos].icon.y + 35, FONTS.MEDIUM)
	
end


function draw_btn(button, img, imgbutton, size)
	set_color(1,1,1,1)
	if (button.state == BTN_UP) then
		imgbutton = load_texture("torishop/gui/" .. img .. ".tga")
	elseif (button.state == BTN_HOVER) then
		imgbutton = load_texture("torishop/gui/" .. img .. "_hvr.tga")
	else
		imgbutton = load_texture("torishop/gui/" .. img .. "_dn.tga")
	end
	draw_quad(button.x, button.y, size, size, imgbutton)
end

function draw_buysteam()
	set_color(1,1,1,1)
	if (buttons.buysteam.state == BTN_UP) then
	buysteam_button = load_texture("torishop/gui/buysteam.tga")			-- STEAM
	--buysteam_button = load_texture("torishop/gui/buypaypal.tga")		-- NON-STEAM
	elseif (buttons.buysteam.state == BTN_HOVER) then
	buysteam_button = load_texture("torishop/gui/buysteam_hvr.tga")		-- STEAM
	--buysteam_button = load_texture("torishop/gui/buypaypal_hvr.tga")	-- NON-STEAM
	else
	buysteam_button = load_texture("torishop/gui/buysteam_dn.tga")		-- STEAM
	--buysteam_button = load_texture("torishop/gui/buypaypal_dn.tga")	-- NON-STEAM
	end
	draw_quad(buttons.buysteam.x, buttons.buysteam.y, 128, 128, buysteam_button)
end

function load_images()
	purchase_button_unav = load_texture("torishop/gui/purchase_unavailable.tga")
	sect_singleitems = load_texture("/torishop/gui/singleitems.tga")
	sect_singleitems_ = load_texture("/torishop/gui/singleitems_.tga")
	sect_fulltoris = load_texture("/torishop/gui/fulltoris.tga")
	sect_fulltoris_ = load_texture("/torishop/gui/fulltoris_.tga")
	sect_colors = load_texture("/torishop/gui/colors.tga")
	sect_colors_ = load_texture("/torishop/gui/colors_.tga")
	sect_textures = load_texture("/torishop/gui/textures.tga")
	sect_textures_ = load_texture("/torishop/gui/textures_.tga")
	sect_hairs = load_texture("/torishop/gui/hairs.tga")
	sect_hairs_ = load_texture("/torishop/gui/hairs_.tga")
	sect_subscriptions_ = load_texture("/torishop/gui/subscriptions_.tga")
	sect_subscriptions = load_texture("/torishop/gui/subscriptions.tga")
	sect_packs = load_texture("/torishop/gui/packs.tga")
	sect_packs_ = load_texture("/torishop/gui/packs_.tga")
	sect_misc = load_texture("/torishop/gui/misc.tga")
	sect_misc_ = load_texture("/torishop/gui/misc_.tga")
	--torishop_announcement = load_texture("/torishop/gui/featuredbeanies.tga")
	--torishop_announcement1 = load_texture("/torishop/gui/featuredfulltextures.tga")
	--torishop_announcement2 = load_texture("/torishop/gui/featuredbarbershop.tga")
	--torishop_announcement3 = load_texture("/torishop/gui/featuredmuaypromo.tga")
	torishop_announcement4 = load_texture("/torishop/gui/featuredlilspook.tga")
	--torishop_announcement5 = load_texture("/torishop/gui/featuredlotterypro.tga")
	sect_flames = load_texture("/torishop/gui/flames.tga")
	sect_flames_ = load_texture("/torishop/gui/flames_.tga")
	sale_main = load_texture("/torishop/gui/dailysale.tga")
	sale_main_ = load_texture("/torishop/gui/dailysale_.tga")
	sect_texturesets = load_texture("/torishop/gui/texturesets.tga")
	sect_texturesets_ = load_texture("/torishop/gui/texturesets_.tga")
	sect_colorpacks = load_texture("/torishop/gui/colorpacks.tga")
	sect_colorpacks_ = load_texture("/torishop/gui/colorpacks_.tga")
	sect_modelpacks = load_texture("/torishop/gui/modelpacks.tga")
	sect_modelpacks_ = load_texture("/torishop/gui/modelpacks_.tga")
	sect_sfulltoris = load_texture("/torishop/gui/sfulltoris.tga")
	sect_sfulltoris_ = load_texture("/torishop/gui/sfulltoris_.tga")
	halloween_special = load_texture("torishop/gui/halloween_special.tga")
--	christmas_special = load_texture("torishop/gui/christmas_special.tga")
end

function unload_images()
	if (torishop_announcement) then unload_texture(torishop_announcement) end
	if (torishop_announcement1) then unload_texture(torishop_announcement1) end
	if (torishop_announcement2) then unload_texture(torishop_announcement2) end
	if (torishop_announcement3) then unload_texture(torishop_announcement3) end
	if (torishop_announcement4) then unload_texture(torishop_announcement4) end
	if (torishop_announcement5) then unload_texture(torishop_announcement5) end
	if (purchase_button_unav) then unload_texture(purchase_button_unav) end
	if (gettc_button) then unload_texture(gettc_button) end
	if (buysteam_button) then unload_texture(buysteam_button) end
	if (purchase_button) then unload_texture(purchase_button) end
	if (cart_purchase) then unload_texture(cart_purchase) end
	if (cart_button) then unload_texture(cart_button) end
	if (cart_remove) then unload_texture(cart_remove) end
	if (sale_icon) then unload_texture(sale_icon) end
--	if (buyqi_button) then unload_texture(buyqi_button) end
	unload_texture(sect_singleitems)
	unload_texture(sect_singleitems_)
	unload_texture(sect_fulltoris)
	unload_texture(sect_fulltoris_)
	unload_texture(sect_colors)
	unload_texture(sect_colors_)
	unload_texture(sect_textures)
	unload_texture(sect_textures_)
	unload_texture(sect_hairs)
	unload_texture(sect_hairs_)
	unload_texture(sect_subscriptions)
	unload_texture(sect_subscriptions_)
	unload_texture(sect_packs)
	unload_texture(sect_packs_)
	unload_texture(sect_misc)
	unload_texture(sect_misc_)
	unload_texture(sect_flames)
	unload_texture(sect_flames_)
	unload_texture(sale_main)
	unload_texture(sale_main_)
	unload_texture(sect_texturesets)
	unload_texture(sect_texturesets_)
	unload_texture(sect_colorpacks)
	unload_texture(sect_colorpacks_)
	unload_texture(sect_modelpacks)
	unload_texture(sect_modelpacks_)
	unload_texture(sect_sfulltoris)
	unload_texture(sect_sfulltoris_)
	unload_texture(halloween_special)
--	unload_texture(christmas_special)
end

function print_desc(text, pos)
	local strlen = get_string_length(text, FONTS.MEDIUM)
	local x = 245-strlen/2
	draw_text(text, x, 220 + pos * 23, FONTS.MEDIUM)
end

function draw_shelf()
	local section_index = section_order[current_section]
	local pages_length
	local heightmod = 0
	local tocarttmp = ""
	local tocarttmpsize = 64
	
	set_color(0,0,0,1)
	-- Draw items on the shelf
	
	-- an awful hack to make purchase buttons work on few items
	if (first == true) then
		local i = 1
		repeat
			local item_index = i + (current_shelf - 1)*items_per_shelf
				if (item_index > sections[1].total_items) then
					break
				end
				local selected = false
				if (item_index == sections[1].selected_index) then
					selected = true
				end
					draw_item(section_order[1], item_index, i, selected, 1)
			i = i + 1
		until (i > items_per_shelf)
		first = false
		clear_icons()
	end
	-- end of hack
	
	if (current_section == 32) then
		for i = 1, sale_items_per_shelf do
			local item_index = i + (current_shelf - 1)*sale_items_per_shelf
			if (item_index > sections[section_index].total_items) then
				break
			end
			local selected = false
			if (item_index == sections[section_index].selected_index) then
				selected = true
			end
			draw_sale_item(item_index, i, selected)
		end
	else
		for i = 1, items_per_shelf do
			local item_index = i + (current_shelf - 1)*items_per_shelf
			if (item_index > sections[section_index].total_items) then
				break
			end
			local selected = false
			if (item_index == sections[section_index].selected_index) then
				selected = true
			end
				local shelf_qi = tonumber(sections[section_index][item_index].qi)
				if (shelf_qi <= qi) then
					draw_item(section_index, item_index, i, selected, 1)
				end
			
		end
		set_color(0,0,0,1)
		if ((current_shelf == total_shelves) and (total_shelves < total_shelves_all)) then 
			if (h_shelf+200 < height) then
				draw_text("Go to the next page to see", 105, h_shelf+((height-80-h_shelf)/2), FONTS.MEDIUM)
				draw_text("what items will be unlocked", 95, h_shelf+((height-80-h_shelf)/2)+25, FONTS.MEDIUM)
				draw_text("on "..belt_next.."!", 160, h_shelf+((height-80-h_shelf)/2)+50, FONTS.MEDIUM)
			end
		elseif (current_shelf > total_shelves and current_shelf <= total_shelves_all) then
			draw_text("Available with "..belt_next..":", 60, 355, FONTS.MEDIUM)
			for i = 1, items_per_shelf_next do
				local item_index = i + (current_shelf - total_shelves - 1)*items_per_shelf_next + items
					if (item_index > sections[section_index].total_items) then
						break
					end
				local selected = false
					if (item_index == sections[section_index].selected_index) then
						selected = true
					end
				local shelf_qi = tonumber(sections[section_index][item_index].qi)
				if (shelf_qi <= qi_next) then
					draw_item(section_index, item_index, i, selected, 1)
				end
			end
		elseif (current_shelf > total_shelves_all) then
			draw_text("Available now for USD:", 60, 355, FONTS.MEDIUM)
			for i = 1, items_per_shelf_next do
				local item_index = i + (current_shelf - total_shelves_all - 1)*items_per_shelf_next + items_usd_skip
					if (item_index > sections_[section_index].total_items) then
						break
					end
				local selected = false
					if (item_index == sections_[section_index].selected_index) then
						selected = true
					end
				local shelf_qi = tonumber(sections_[section_index][item_index].qi)
				local shelf_usd = tonumber(sections_[section_index][item_index].price_usd)
				if (shelf_qi > qi_next) then
					draw_item(section_index, item_index, i, selected, 0)
				else i = i - 1
				end
			end
		end
	end
	
	if (change_section_first[section_index] == 1) then
		details_qi = tonumber(sections[current_section][1].qi)
		details_name = sections[current_section][1].name
		details_tier = sections[current_section][1].tier
		details_price = tonumber(sections[current_section][1].price)
		details_price_usd = sections[current_section][1].price_usd
		details_id = sections[current_section][1].id
		if (current_section == 32) then
			details_old_price = tonumber(sections[current_section][1].old_price)
			details_old_price_usd = sections[current_section][1].old_price_usd
		end
	elseif (sections[section_index].selected_index ~= 0) then
		details_qi = tonumber(sections[current_section][sections[section_index].selected_index].qi)
		details_name = sections[current_section][sections[section_index].selected_index].name
		details_tier = sections[current_section][sections[section_index].selected_index].tier
		details_price = tonumber(sections[current_section][sections[section_index].selected_index].price)
		details_price_usd = sections[current_section][sections[section_index].selected_index].price_usd
		details_id = sections[current_section][sections[section_index].selected_index].id
		if (current_section == 32) then
			details_old_price = tonumber(sections[current_section][sections[section_index].selected_index].old_price)
			details_old_price_usd = sections[current_section][sections[section_index].selected_index].old_price_usd
		end
	end
	
	-- Draw shelf text
	if ((current_shelf <= total_shelves_all and sections[section_index].try == true) or (current_shelf > total_shelves_all and sections_[section_index].try == true)) then
		select_color_links(buttons.none.state)
		draw_text("UNDO", buttons.none.x, buttons.none.y, FONTS.MEDIUM)
		select_color_links(buttons.default.state)
		draw_text("DEFAULT", buttons.default.x, buttons.default.y, FONTS.MEDIUM)
	end
	
	select_color_links(buttons.tomain.state)
	draw_text("BACK", buttons.tomain.x, buttons.tomain.y, FONTS.MEDIUM)
	
	set_color(1,1,1,1)
	pages_length = get_string_length("Page: " .. current_shelf .. " of " .. total_shelves_all2, FONTS.MEDIUM)
	draw_text("Page:  " .. current_shelf .. " of " .. total_shelves_all2, 245 - pages_length / 2, height-55, FONTS.MEDIUM)
	
	if (current_section == 32) then
		set_color(0,0,0,0.2)
		draw_quad(10,50,470,290)
		set_color(0,0,0,1)
		draw_quad(9,50,1,290)
		draw_quad(480,50,1,290)
		draw_quad(9,49,472,1)
		draw_quad(9,340,472,1)
	else
		set_color(0,0,0,0.2)
		draw_quad(10,70,470,270)
		set_color(0,0,0,1)
		draw_quad(9,70,1,270)
		draw_quad(480,70,1,270)
		draw_quad(9,69,472,1)
		draw_quad(9,340,472,1)
	end
	
	if (details_name == nil) then draw_text("CLICK ON ITEM", 30, 140, FONTS.BIG)
		draw_text("FOR DETAILS", 180, 200, FONTS.BIG)
		draw_text("CLICK ON ITEM", 30, 140, FONTS.BIG)
		draw_text("FOR DETAILS", 180, 200, FONTS.BIG)
	else
	if (string.find(details_name, "RHMT")) then
		details_name = string.gsub(details_name, "RHMT", "Right Hand Trail")
	elseif (string.find(details_name, "LHMT")) then
		details_name = string.gsub(details_name, "LHMT", "Left Hand Trail")
	elseif (string.find(details_name, "RLMT")) then
		details_name = string.gsub(details_name, "RLMT", "Right Leg Trail")
	elseif (string.find(details_name, "LLMT")) then
		details_name = string.gsub(details_name, "LLMT", "Left Leg Trail")
	end
	if (details_name == "Jiy&#252; Dreads") then details_name = "Jiyü Dreads" end
	
	if (current_section == 32) then
	heightmod = -20
	else
	heightmod = 0
	end
	set_color(1,1,1,1)
	draw_text(details_name, 245 - math.floor(get_string_length(details_name, FONTS.MEDIUM) / 2), 80 + heightmod, FONTS.MEDIUM)
	if ((details_price > tc) and (details_qi > qi)) then set_color(1,1,1,0.3) draw_quad(10,105 + heightmod,469,25)set_color(0,0,0,1) draw_text("You don't have enough TC & QI to buy this!", 20, 105 + heightmod, FONTS.MEDIUM)
		if (details_price_usd ~= "0.00") then
			if (current_section == 32) then
				buttons.buysteam.x = 177
				buttons.buysteam.y = 300
			else
				buttons.buysteam.x = 330
				buttons.buysteam.y = 135
			end
		draw_buysteam()
		end
	elseif (details_price > tc) then set_color(1,1,1,0.3) draw_quad(10,105 + heightmod,469,25)set_color(0,0,0,1) draw_text("You don't have enough TC to buy this!", 40, 105 + heightmod, FONTS.MEDIUM)
		if (details_price_usd == "0.00") then
			if (current_section == 32) then
				buttons.gettc.x = 177
				buttons.gettc.y = 300
			else
				buttons.gettc.x = 330
				buttons.gettc.y = 135
			end
		else
			if (current_section == 32) then
				buttons.gettc.x = 68
				buttons.gettc.y = 300
				buttons.buysteam.x = 294
				buttons.buysteam.y = 300
			else
				buttons.gettc.x = 330
				buttons.gettc.y = 135
				buttons.buysteam.x = 330
				buttons.buysteam.y = 170
			end
			draw_buysteam()
		end
		can_buy = false
		draw_btn(buttons.gettc, "gettc", gettc_button, 128)
	elseif (details_qi > qi) then set_color(1,1,1,0.3) draw_quad(10,105 + heightmod,469,25)set_color(0,0,0,1) draw_text("You don't have enough qi to buy this!", 40, 105 + heightmod, FONTS.MEDIUM)
		if (details_price_usd ~= "0.00") then
			if (current_section == 32) then
				buttons.buysteam.x = 177
				buttons.buysteam.y = 300
			else
				buttons.buysteam.x = 330
				buttons.buysteam.y = 135
			end
			draw_buysteam()
		end
	elseif ((details_price == 0) and (details_price_usd ~= "0.00")) then
		can_buy = true
		set_color(1,1,1,1)
		if (current_section == 32) then
			buttons.buysteam.x = 177
			buttons.buysteam.y = 300
		else
			buttons.buysteam.x = 330
			buttons.buysteam.y = 135
		end
		draw_buysteam()
	elseif (details_price ~= 0 and details_price_usd ~= "0.00") then
		can_buy = true
		if (current_section == 32) then
			buttons.buy.x = 31
			buttons.buy.y = 300
			buttons.buysteam.x = 331
			buttons.buysteam.y = 300
			buttons.tocarttc.x = 181
			buttons.tocarttc.y = 300
			buttons.tocarttc.w = 128
		else
			buttons.buy.x = 313
			buttons.buy.y = 135
			buttons.buysteam.x = 330
			buttons.buysteam.y = 170
			buttons.tocarttc.x = 441
			buttons.tocarttc.y = 135
			buttons.tocarttc.w = 34
		end
		draw_buysteam()
		draw_btn(buttons.buy, "purchase", purchase_button, 128)
		if (current_section == 32) then 
			tocarttmp = "_big"
			tocarttmpsize = 128
		end
		if (details_price + cart_sum > tc or cart_current >= 10) then
			cart_button = load_texture("torishop/gui/tocart" .. tocarttmp .. "_unav.tga")
		elseif (buttons.tocarttc.state == BTN_UP) then
			cart_button = load_texture("torishop/gui/tocart" .. tocarttmp .. ".tga")
		elseif (buttons.tocarttc.state == BTN_HOVER) then
			cart_button = load_texture("torishop/gui/tocart" .. tocarttmp .. "_hvr.tga")
		else
			cart_button = load_texture("torishop/gui/tocart" .. tocarttmp .. "_dn.tga")
		end
		draw_quad(buttons.tocarttc.x, buttons.tocarttc.y, tocarttmpsize, tocarttmpsize, cart_button)
	elseif (details_price == 0 and details_price_usd == "0.00") then
		can_buy = false	
	else
		can_buy = true
		set_color(1,1,1,1)
		if (current_section == 32) then
			buttons.buy.x = 68
			buttons.buy.y = 300
			buttons.tocarttc.x = 294
			buttons.tocarttc.y = 300
			buttons.tocarttc.w = 128
		else
			buttons.buy.x = 313
			buttons.buy.y = 135
			buttons.tocarttc.x = 441
			buttons.tocarttc.y = 135
			buttons.tocarttc.w = 34
		end
		draw_btn(buttons.buy, "purchase", purchase_button, 128)
		if (current_section == 32) then 
			tocarttmp = "_big"
			tocarttmpsize = 128
		end
		if (details_price + cart_sum > tc or cart_current >= 10) then
			cart_button = load_texture("torishop/gui/tocart" .. tocarttmp .. "_unav.tga")
		elseif (buttons.tocarttc.state == BTN_UP) then
			cart_button = load_texture("torishop/gui/tocart" .. tocarttmp .. ".tga")
		elseif (buttons.tocarttc.state == BTN_HOVER) then
			cart_button = load_texture("torishop/gui/tocart" .. tocarttmp .. "_hvr.tga")
		else
			cart_button = load_texture("torishop/gui/tocart" .. tocarttmp .. "_dn.tga")
		end
		draw_quad(buttons.tocarttc.x, buttons.tocarttc.y, tocarttmpsize, tocarttmpsize, cart_button)
	end
		
	set_color(1,1,1,1)
	if (current_section == 32) then
		if ((details_price_usd == "0.00") and (details_price ~= 0)) then
			set_color(1,1,1,0.7)
			draw_text(tc_format(details_old_price).." TC", 245 - get_string_length(tc_format(details_old_price).." TC ", FONTS.MEDIUM) / 2, 127, FONTS.MEDIUM)
			set_color(1,0,0,1)
			draw_quad(245 - get_string_length(tc_format(details_old_price).." TC     ", FONTS.MEDIUM) / 2, 140, get_string_length(tc_format(details_old_price).." TC    ", FONTS.MEDIUM), 1)
			set_color(1,1,1,1)
			draw_text_angle_scale(tc_format(details_price).." TC", 245 - math.floor(get_string_length(tc_format(details_price).." TC ", FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
			draw_text_angle_scale(tc_format(details_price).." TC", 245 - math.floor(get_string_length(tc_format(details_price).." TC ", FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
		elseif ((details_price_usd ~= "0.00") and (details_price ~= 0)) then
			set_color(1,1,1,0.7)
			draw_text(tc_format(details_old_price).." TC", 128 - get_string_length(tc_format(details_old_price).." TC ", FONTS.MEDIUM) / 2, 127, FONTS.MEDIUM)
			set_color(1,0,0,1)
			draw_quad(128 - get_string_length(tc_format(details_old_price).." TC     ", FONTS.MEDIUM) / 2, 140, get_string_length(tc_format(details_old_price).." TC    ", FONTS.MEDIUM), 1)
			set_color(1,1,1,1)
			draw_text_angle_scale(tc_format(details_price).." TC", 128 - math.floor(get_string_length(tc_format(details_price).." TC ", FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
			draw_text_angle_scale(tc_format(details_price).." TC", 128 - math.floor(get_string_length(tc_format(details_price).." TC ", FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
			
			set_color(1,1,1,0.7)
			draw_text("$ "..details_old_price_usd, 362 - get_string_length("$ "..details_old_price_usd, FONTS.MEDIUM) / 2, 127, FONTS.MEDIUM)
			set_color(1,0,0,1)
			draw_quad(362 - get_string_length("$    "..details_old_price_usd, FONTS.MEDIUM) / 2, 140, get_string_length("$    "..details_old_price_usd, FONTS.MEDIUM), 1)
			set_color(1,1,1,1)
			draw_text_angle_scale("$ "..details_price_usd, 362 - math.floor(get_string_length("$ "..details_price_usd, FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
			draw_text_angle_scale("$ "..details_price_usd, 362 - math.floor(get_string_length("$ "..details_price_usd, FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
		else 	if (details_name == "ToriBooster-10000") then 
					set_color(1,1,1,0.7)
					draw_text("$ "..details_old_price_usd.." per day", 245 - get_string_length("$ "..details_old_price_usd.." per day", FONTS.MEDIUM) / 2, 127, FONTS.MEDIUM)
					set_color(1,0,0,1)
					draw_quad(245 - get_string_length("$    "..details_old_price_usd.." per day", FONTS.MEDIUM) / 2, 140, get_string_length("$    "..details_old_price_usd.." per day", FONTS.MEDIUM), 1)
					set_color(1,1,1,1)
					draw_text_angle_scale("$ "..details_price_usd.." per day", 245 - math.floor(get_string_length("$ "..details_price_usd.." per day", FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
					draw_text_angle_scale("$ "..details_price_usd.." per day", 245 - math.floor(get_string_length("$ "..details_price_usd.." per day", FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
				elseif string.find(details_name, "Booster") then 
					set_color(1,1,1,0.7)
					draw_text("$ "..details_old_price_usd.." per month", 245 - get_string_length("$ "..details_old_price_usd.." per month", FONTS.MEDIUM) / 2, 127, FONTS.MEDIUM)
					set_color(1,0,0,1)
					draw_quad(245 - get_string_length("$    "..details_old_price_usd.." per month", FONTS.MEDIUM) / 2, 140, get_string_length("$    "..details_old_price_usd.." per month", FONTS.MEDIUM), 1)
					set_color(1,1,1,1)
					draw_text_angle_scale("$ "..details_price_usd.." per month", 245 - math.floor(get_string_length("$ "..details_price_usd.." per month", FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
					draw_text_angle_scale("$ "..details_price_usd.." per month", 245 - math.floor(get_string_length("$ "..details_price_usd.." per month", FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
				elseif (details_name == "Forum VIP") then 
					set_color(1,1,1,0.7)
					draw_text("$ "..details_old_price_usd.." per 6 months", 245 - get_string_length("$ "..details_old_price_usd.." per 6 months", FONTS.MEDIUM) / 2, 127, FONTS.MEDIUM)
					set_color(1,0,0,1)
					draw_quad(245 - get_string_length("$    "..details_old_price_usd.." per 6 months", FONTS.MEDIUM) / 2, 140, get_string_length("$    "..details_old_price_usd.." per 6 months", FONTS.MEDIUM), 1)
					set_color(1,1,1,1)
					draw_text_angle_scale("$ "..details_price_usd.." per 6 months", 245 - math.floor(get_string_length("$ "..details_price_usd.." per 6 months", FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
					draw_text_angle_scale("$ "..details_price_usd.." per 6 months", 245 - math.floor(get_string_length("$ "..details_price_usd.." per 6 months", FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
					buttons.info_prime.x = 245 - get_string_length("What is this?", FONTS.MEDIUM) / 2
					buttons.info_prime.y = 245
					select_color_links(buttons.info_prime.state)
					draw_text("What is this?", buttons.info_prime.x, buttons.info_prime.y, FONTS.MEDIUM)
				else 
					set_color(1,1,1,0.7)
					draw_text("$ "..details_old_price_usd, 245 - get_string_length("$ "..details_old_price_usd, FONTS.MEDIUM) / 2, 127, FONTS.MEDIUM)
					set_color(1,0,0,1)
					draw_quad(245 - get_string_length("$    "..details_old_price_usd, FONTS.MEDIUM) / 2, 140, get_string_length("$    "..details_old_price_usd, FONTS.MEDIUM), 1)
					set_color(1,1,1,1)
					draw_text_angle_scale("$ "..details_price_usd, 245 - math.floor(get_string_length("$ "..details_price_usd, FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
					draw_text_angle_scale("$ "..details_price_usd, 245 - math.floor(get_string_length("$ "..details_price_usd, FONTS.BIG) * 0.7 / 2), 140, 0, 0.7, FONTS.BIG)
				end
		end
		set_color(1, 1, 1, 1)
		if (details_tier ~= "0") then
			draw_text("Tier: "..details_tier, 245 - math.floor(get_string_length("Tier: "..details_tier, FONTS.MEDIUM) / 2), 210, FONTS.MEDIUM)
			if (details_qi ~= 0) then
				draw_text("Requires "..details_qi.." qi", 245 - math.floor(get_string_length("Requires: "..details_qi.." qi", FONTS.MEDIUM) / 2), 235, FONTS.MEDIUM)
			else 
				draw_text("Doesn't require qi", 245 - math.floor(get_string_length("Doesn't require qi", FONTS.MEDIUM) / 2), 235, FONTS.MEDIUM)
			end
		elseif ((details_tier == "None") and (details_qi ~= 0)) then
			draw_text("Requires "..details_qi.." qi", 245 - math.floor(get_string_length("Requires: "..details_qi.." qi", FONTS.MEDIUM) / 2), 210, FONTS.MEDIUM)
		else 
			draw_text("Doesn't require qi", 245 - math.floor(get_string_length("Doesn't require qi", FONTS.MEDIUM) / 2), 210, FONTS.MEDIUM)
		end
	else
	if ((details_price_usd == "0.00") and (details_price ~= 0)) then	draw_text("Price: "..tc_format(details_price).." TC", 30, 130, FONTS.MEDIUM)
	elseif ((details_price_usd ~= "0.00") and (details_price ~= 0)) then draw_text("Price: "..tc_format(details_price).." TC / $"..details_price_usd, 30, 130, FONTS.MEDIUM)
	else 	if (details_name == "Forum VIP") then draw_text("Price: $"..details_price_usd.." per 6 months", 30, 130, FONTS.MEDIUM)
			elseif (details_name == "ToriBooster-10000") then draw_text("Price: $"..details_price_usd.." per day", 30, 130, FONTS.MEDIUM)
			elseif string.find(details_name, "Booster") then draw_text("Price: $"..details_price_usd.." per month", 30, 130, FONTS.MEDIUM)
			elseif (details_price_usd ~= "0.00") then draw_text("Price: $"..details_price_usd, 30, 130, FONTS.MEDIUM) end
	end
	if (details_tier ~= "0") then
	draw_text("Tier: "..details_tier, 30, 155, FONTS.MEDIUM)
	if (details_qi ~= 0) then
	draw_text("Requires "..details_qi.." qi", 30, 180, FONTS.MEDIUM)
	else draw_text("Doesn't require qi", 30, 180, FONTS.MEDIUM) end
	elseif ((details_tier == "None") and (details_qi ~= 0)) then
	draw_text("QI: "..details_qi, 30, 155, FONTS.MEDIUM)
	elseif (details_price ~= 0 or details_price_usd ~= "0.00") then draw_text("Doesn't require qi", 30, 155, FONTS.MEDIUM)
	end
	
	if (string.find(details_name, "Zabrak Horns")) then
		print_desc("Try not to get cut in half!", 2)
	elseif (string.find(details_name, "Sakura")) then
		print_desc("Sakura bloom and die fast.", 1)
		print_desc("Some may think of it as a flaw,", 2)
		print_desc("but certainly not the true Sakura-bito.", 3)
	elseif (string.find(details_name, "Vagabond")) then
		print_desc("Being the lone wanderer taught you", 0)
		print_desc("a lot of things. Defeating your opponents", 1)
		print_desc("with no effort is, obviously, one of them.", 2)
	elseif (string.find(details_name, "Soderhair")) then
		print_desc("The trademark hairstyle of the Toribash God Hampa.", 1)
		print_desc("Careful, it might make you old!", 2)
	elseif (string.find(details_name, "Kid Popstar")) then
		print_desc("\"I'm in love with you forever,", 0)
		print_desc("Nothing will stand in my way,", 1)
		print_desc("And of course it doesn't matter", 2)
		print_desc("That you're nine and I am eight.\"", 3)
	elseif (string.find(details_name, "Road Fighter")) then
		print_desc("Hey boy, whatcha lookin' at?", 1)
	elseif (string.find(details_name, "Soderhair")) then
		print_desc("The trademark hairstyle of the Toribash God Hampa.", 1)
		print_desc("Careful, it might make you old!", 2)
	elseif (string.find(details_name, "Shoveler's Shovel")) then
		print_desc("Shovel your way out of any situation!", 1)
		print_desc("Makes a nice SMOK when hitting faces.", 2)
	elseif (string.find(details_name, "Sword In The Stone")) then
		print_desc("Are you the chosen one?", 2)
	elseif (string.find(details_name, "Sifu Beard")) then
		print_desc("The glorious beard of", 0)
		print_desc("legendary martial art masters..", 1)
		print_desc("or old guys who are", 2)
		print_desc("too lazy to shave.", 3)
	elseif (string.find(details_name, "Muay Thai Legend")) then
		print_desc("Muay thai legend gear; only those", 0)
		print_desc("who train vigorously for countless", 1)
		print_desc("years can develop the incredible", 2)
		print_desc("skills of yours", 3)
	elseif (string.find(details_name, "Tori Pirate")) then
		print_desc("Yarr!", 2)
	elseif (string.find(details_name, "Skeletal Tori")) then
		print_desc("One cannot kill", 1)
		print_desc("what's been long dead", 2)
	elseif (string.find(details_name, "Drake")) then
		print_desc("Dragon soul is gives you", 0)
		print_desc("ultimate strengh and incinerates", 1)
		print_desc("all of your enemies", 2)
	elseif (string.find(details_name, "Brain")) then
		set_color(0.95,0.83,0.01, 1)
		print_desc("Halloween Limited Item", 1)
		set_color(1,1,1,1)
		print_desc("Hmmm... yummy!", 2)
	elseif (string.find(details_name, "Broom Stick")) then
		set_color(0.95,0.83,0.01, 1)
		print_desc("Halloween Limited Item", 1)
		set_color(1,1,1,1)
		print_desc("Allows to fly AND clean floors!", 2)
	elseif (string.find(details_name, "Button Eyes")) then
		set_color(0.95,0.83,0.01, 1)
		print_desc("Halloween Limited Item", 1)
		set_color(1,1,1,1)
		print_desc("The world definitely looks", 2)
		print_desc("better now... right?", 3)
	elseif (string.find(details_name, "Demon Wings")) then
		set_color(0.95,0.83,0.01, 1)
		print_desc("Halloween Limited Item", 0)
		set_color(1,1,1,1)
		print_desc("Now you can be cooler - just like Satan!", 1)
	elseif (string.find(details_name, "Tori Armor V2")) then
		print_desc("Season One Unique Prize", -2)
		print_desc("This set was only obtainable", 0)
		print_desc("by reaching rank 1 during", 1)
		print_desc("Toribash's first ranking season", 2)
	elseif (string.find(details_name, "Little Latching Elf")) then
		print_desc("A tiny friend that would", 1)
		print_desc("Never gonna give you up!", 2)
	elseif string.find(details_name, "Tier") then
		local details_tier_print = string.gsub(details_name, " Pack", "")
		local details_name_length = string.len(details_tier_print)
		draw_text("This pack contains all", 125, 220, FONTS.MEDIUM)
		draw_text(details_tier_print.." items", 220 - details_name_length*5, 243, FONTS.MEDIUM)
		draw_text("Unlock it to unpack all items", 90, 266, FONTS.MEDIUM)
		draw_text("in your inventory", 150, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Trancebot") then
		draw_text("A preloaded Trancebot", 120, 255, FONTS.MEDIUM)
		draw_text("texture set by Marrez", 120, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Goraxx") then
		draw_text("A preloaded Goraxx", 135, 255, FONTS.MEDIUM)
		draw_text("texture set by Rogue", 128, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Randombot001") then
		draw_text("A preloaded Randombot001", 100, 255, FONTS.MEDIUM)
		draw_text("head texture by AHD", 138, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Avionic") then
		draw_text("A preloaded Avionic", 140, 255, FONTS.MEDIUM)
		draw_text("head texture by AHD", 138, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Geo") then
		draw_text("A preloaded Geo", 155, 255, FONTS.MEDIUM)
		draw_text("head texture by AHD", 138, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Nautikor") then
		draw_text("A preloaded Nautikor", 132, 255, FONTS.MEDIUM)
		draw_text("head texture by AHD", 138, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Orc Warlord") then
		draw_text("A preloaded Orc Warlord", 110, 255, FONTS.MEDIUM)
		draw_text("head texture by Pheature", 107, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Space Owl") then
		draw_text("A preloaded Space Owl", 120, 255, FONTS.MEDIUM)
		draw_text("head texture by Stalker", 110, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "T-05") then
		draw_text("A preloaded T-05", 145, 255, FONTS.MEDIUM)
		draw_text("head texture by jusmi", 118, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Pink!") then
		draw_text("A preloaded Pink!", 140, 255, FONTS.MEDIUM)
		draw_text("head texture by Marrez", 110, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Blind Warrior") then
		draw_text("A preloaded Blind Warrior", 95, 255, FONTS.MEDIUM)
		draw_text("head texture by jusmi", 118, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Hardened Soul") then
		draw_text("A preloaded Hardened Soul", 95, 255, FONTS.MEDIUM)
		draw_text("head texture by jusmi", 118, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Fire Guardian") then
		draw_text("A preloaded Fire Guardian", 98, 255, FONTS.MEDIUM)
		draw_text("head texture by Wancorne", 95, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Technologic") then
		draw_text("A preloaded Technologic", 108, 255, FONTS.MEDIUM)
		draw_text("head texture by Marrez", 110, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Boxer Pack") then
		draw_text("In 'as new' condition!", 123, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Texture Pack") then
		local details_texture_print = string.gsub(details_name, " Pack", "")
		local details_name_length = string.len(details_texture_print)
		draw_text("This pack contains all", 125, 220, FONTS.MEDIUM)
		draw_text(details_texture_print.."s", 220 - details_name_length*5, 243, FONTS.MEDIUM)
		draw_text("Unlock it to unpack all items", 90, 266, FONTS.MEDIUM)
		draw_text("in your inventory", 150, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Pack") then
		local details_name_print = string.gsub(details_name, " Pack", "")
		local details_name_length = string.len(details_name_print)
		draw_text("This pack contains full", 120, 220, FONTS.MEDIUM)
		draw_text(details_name_print.." set", 220 - details_name_length*5, 243, FONTS.MEDIUM)
		draw_text("Unlock it to unpack all items", 90, 266, FONTS.MEDIUM)
		draw_text("in your inventory", 150, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Demon Horns") then
	draw_text("Unleash the demon within you!", 80, 260, FONTS.MEDIUM)
	set_color(0.16,0.66,0.86,1)
	draw_text("Forged by Stalker", 140, 223, FONTS.MEDIUM)
	elseif string.find(details_name, "Yin the Orca") then
	draw_text("Deep in the deep dark blue,", 100, 243, FONTS.MEDIUM)
	draw_text("there lived a whale...", 130, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Acid") then
	draw_text("Those who hold this have the power to", 34, 220, FONTS.MEDIUM)
	draw_text("burn their hits deep into their enemies,", 26, 243, FONTS.MEDIUM)
	draw_text("melting almost anything that stands in", 24, 266, FONTS.MEDIUM)
	draw_text("their way.", 192, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Adamantium") then
	draw_text("Believed to be harnessed from a creature", 17, 220, FONTS.MEDIUM)
	draw_text("from another universe, Adamantium is an", 14, 243, FONTS.MEDIUM)
	draw_text("extremely rare mineral. Harness the", 40, 266, FONTS.MEDIUM)
	draw_text("unbreakable, nearly indestructible", 48, 289, FONTS.MEDIUM)
	draw_text("powers of this mineral.", 122, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Alpha") then
	draw_text("Alpha Imperial. A signature item", 60, 220, FONTS.MEDIUM)
	draw_text("in honor of the great clan Alpha,", 58, 243, FONTS.MEDIUM)
	draw_text("this is a limited edition color, fused", 37, 266, FONTS.MEDIUM)
	draw_text("with Imperial to produce a dark finish.", 27, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Amber") then
	draw_text("Made from fossilized ancients, this", 43, 243, FONTS.MEDIUM)
	draw_text("mineral embodies the spirits of the old,", 22, 266, FONTS.MEDIUM)
	draw_text("allowing you to harness their powers.", 32, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Amethyst") then
	draw_text("The miraculous powers of amethyst", 44, 220, FONTS.MEDIUM)
	draw_text("have been sought after since", 83, 243, FONTS.MEDIUM)
	draw_text("the beginning of time;", 120, 266, FONTS.MEDIUM)
	draw_text("bringing good fortune in war", 76, 289, FONTS.MEDIUM)
	draw_text("and the coveted ability to ward off evil.", 24, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Aqua") then
	draw_text("Embrace the power of water", 90, 243, FONTS.MEDIUM)
	draw_text("as you defeat your enemies", 97, 266, FONTS.MEDIUM)
	draw_text("with fluid motion.", 150, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Aurora") then
	draw_text("Ancient elves mastered the art of", 60, 220, FONTS.MEDIUM)
	draw_text("channeling plasma through atomic", 50, 243, FONTS.MEDIUM)
	draw_text("oxygen, producing tremendous energy", 25, 266, FONTS.MEDIUM)
	draw_text("surges... what we now know today", 56, 289, FONTS.MEDIUM)
	draw_text("as auroras.", 190, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Azurite") then
	draw_text("Minerals forged in the earth form the", 30, 220, FONTS.MEDIUM)
	draw_text("elusive Azurite... Rare in its form,", 50, 243, FONTS.MEDIUM)
	draw_text("forged for its Strength and Resilience", 26, 266, FONTS.MEDIUM)
	draw_text("in combat.", 190, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Beetle") then
	draw_text("Beetles are quick and nimble and their", 30, 220, FONTS.MEDIUM)
	draw_text("true power is unleashed in numbers...", 35, 243, FONTS.MEDIUM)
	draw_text("Devouring those who dare to trespass", 30, 266, FONTS.MEDIUM)
	draw_text("en-masse.", 192, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Bronze") then
	draw_text("The discovery of bronze by prehistoric", 30, 220, FONTS.MEDIUM)
	draw_text("people gave them harder and more", 55, 243, FONTS.MEDIUM)
	draw_text("durable weapons and armor.", 84, 266, FONTS.MEDIUM)
	draw_text("This forged metal stands the", 81, 289, FONTS.MEDIUM)
	draw_text("test of time, and so shall you.", 77, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Camo") then
	draw_text("Stealth, speed and agility.", 100, 220, FONTS.MEDIUM)
	draw_text("You eliminate your targets silently,", 45, 243, FONTS.MEDIUM)
	draw_text("then disappear into the night", 80, 266, FONTS.MEDIUM)
	draw_text("as swiftly as you came...", 110, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Chronos") then
	draw_text("Be the master of all time.", 105, 243, FONTS.MEDIUM)
	draw_text("The pink, squishy and adorable", 75, 266, FONTS.MEDIUM)
	draw_text("kind of time.", 180, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Cobra") then
	draw_text("Stealth, power and speed are hallmarks", 25, 220, FONTS.MEDIUM)
	draw_text("of the cobra.", 180, 243, FONTS.MEDIUM)
	draw_text("Draw upon the lethal energies", 80, 266, FONTS.MEDIUM)
	draw_text("of this creature.", 160, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Copper") then
	draw_text("The true power of copper lies in its", 50, 220, FONTS.MEDIUM)
	draw_text("ability to channel electrical energy,", 40, 243, FONTS.MEDIUM)
	draw_text("allowing those who possess it to", 58, 266, FONTS.MEDIUM)
	draw_text("manipulate surges of power from", 52, 289, FONTS.MEDIUM)
	draw_text("the heavens.", 190, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Crimson") then
	draw_text("The fusion of acid, aluminium and blood", 25, 220, FONTS.MEDIUM)
	draw_text("gives rise to this potent mineral.", 60, 243, FONTS.MEDIUM)
	draw_text("The simmering blood provides", 80, 266, FONTS.MEDIUM)
	draw_text("a gentle glow...", 160, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Demolition") then
	draw_text("Pure destruction.", 150, 243, FONTS.MEDIUM)
	draw_text("Inspired by the demolition domination", 30, 266, FONTS.MEDIUM)
	draw_text("of the World Tag Team Championships.", 35, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Demon") then
	draw_text("Broken free from the underworld,", 50, 220, FONTS.MEDIUM)
	draw_text("the unholy fire will rain destruction", 40, 243, FONTS.MEDIUM)
	draw_text("upon all who stand in your way.", 70, 266, FONTS.MEDIUM)
	draw_text("This evil runs through your veins tonight.", 16, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Dragon") then
	draw_text("Ever heard of the person", 110, 220, FONTS.MEDIUM)
	draw_text("who called the purple dragon 'Barney'?", 26, 243, FONTS.MEDIUM)
	draw_text("It is hard to talk", 150, 266, FONTS.MEDIUM)
	draw_text("when you're a pile of ashes.", 95, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Ecto") then
	draw_text("Psychokinetic forces surround you", 45, 243, FONTS.MEDIUM)
	draw_text("as you allow channel spirits", 80, 266, FONTS.MEDIUM)
	draw_text("to wreak havoc on your opponents.", 48, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Elf") then
	draw_text("Elves are powerful mythical creatures,", 22, 220, FONTS.MEDIUM)
	draw_text("powerful in the ways of the light.", 55, 243, FONTS.MEDIUM)
	draw_text("Never-aging and wise in the ways", 57, 266, FONTS.MEDIUM)
	draw_text("of the Earth. Let these spirits", 75, 289, FONTS.MEDIUM)
	draw_text("of the Norse guide you.", 115, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Gaia") then
	draw_text("Adorn yourself with the blessed colors", 28, 220, FONTS.MEDIUM)
	draw_text("of the Earth Mother.", 135, 243, FONTS.MEDIUM)
	draw_text("Then dress yourself up in costumes", 47, 266, FONTS.MEDIUM)
	draw_text("and socialize with... wait what?", 65, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Gladiator") then
	draw_text("Ascend over your opponent", 100, 243, FONTS.MEDIUM)
	draw_text("and taste the thrill of combat.", 80, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Old Gold") then
	draw_text("Exclusive and bold,", 138, 243, FONTS.MEDIUM)
	draw_text("a perfect match with void and demon", 35, 266, FONTS.MEDIUM)
	draw_text("for that ancient look.", 122, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Golden Toricredit") then
	draw_text("While gold was an interesting innovation,", 14, 243, FONTS.MEDIUM)
	draw_text("this collectable coin is just a tad too", 35, 266, FONTS.MEDIUM)
	draw_text("thick to fit in the normal deposit slots.", 25, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Gold") then
	draw_text("The other half of hampanity.", 90, 220, FONTS.MEDIUM)
	draw_text("Gold is for the wealthy and those", 60, 243, FONTS.MEDIUM)
	draw_text("who partake in the worship of", 72, 266, FONTS.MEDIUM)
	draw_text("the god [MAD]Hampa", 130, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Helios") then
	draw_text("Let the spirit of the titans", 95, 243, FONTS.MEDIUM)
	draw_text("flow through you in combat.", 87, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Hot Pink") then
	draw_text("Pour les femmes.", 155, 243, FONTS.MEDIUM)
	draw_text("For the month we celebrate", 90, 266, FONTS.MEDIUM)
	draw_text("women in Toribash ;)", 130, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Hunter") then
	draw_text("The Hunter is a mysterious and", 65, 243, FONTS.MEDIUM)
	draw_text("powerful foe, it's best to not face him", 30, 266, FONTS.MEDIUM)
	draw_text("in the darkness of his domain.", 70, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Hydra") then
	draw_text("The offspring of Typhon and venomous", 31, 220, FONTS.MEDIUM)
	draw_text("with its numerous heads.", 110, 243, FONTS.MEDIUM)
	draw_text("Harness its fearsome power", 90, 266, FONTS.MEDIUM)
	draw_text("and bring devastation upon your foes.", 33, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Imperial") then
	draw_text("Kings, emperors and lords of the past", 33, 220, FONTS.MEDIUM)
	draw_text("wore the imperial color as a sign of", 42, 243, FONTS.MEDIUM)
	draw_text("nobility, wealth, elegance", 100, 266, FONTS.MEDIUM)
	draw_text(" and superiority.", 150, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Ivory") then
	draw_text("Hard, unbreakable and incorruptible.", 36, 243, FONTS.MEDIUM)
	draw_text("Some say this valuable mineral", 70, 266, FONTS.MEDIUM)
	draw_text("is matched only by Pure.", 110, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Juryo") then
	draw_text("The Juryo division is a recognition", 50, 220, FONTS.MEDIUM)
	draw_text("of a fighter's prowess in the art of sumo,", 13, 243, FONTS.MEDIUM)
	draw_text("ranking just below the Makuuchi division", 16, 266, FONTS.MEDIUM)
	draw_text("of top-class fighters.", 126, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Kevlar") then
	draw_text("Strong and light,", 155, 243, FONTS.MEDIUM)
	draw_text("kevlar is used by armies worldwide", 50, 266, FONTS.MEDIUM)
	draw_text("for heavy-duty protection.", 95, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Knox") then
	draw_text("Many theories abound on the origin", 46, 220, FONTS.MEDIUM)
	draw_text("of the name Knox.", 150, 243, FONTS.MEDIUM)
	draw_text("Some say alludes to a huge gold deposit,", 25, 266, FONTS.MEDIUM)
	draw_text("others claim it's an ad for Knox Gelatin™.", 19, 289, FONTS.MEDIUM)
	draw_text("Really it's a wrestler.", 125, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Magma") then
	draw_text("Magma dons you like the Waru.", 82, 243, FONTS.MEDIUM)
	draw_text("It flows in your veins.", 128, 266, FONTS.MEDIUM)
	draw_text("One body, one soul.", 142, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Magnetite") then
	draw_text("Those who wield the powerful magnetite", 25, 220, FONTS.MEDIUM)
	draw_text("have the ablity to manipulate and channel", 16, 243, FONTS.MEDIUM)
	draw_text("electro-magnetic fields", 120, 266, FONTS.MEDIUM)
	draw_text("through and around their bodies...", 64, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Marine") then
	draw_text("One half of hampanity.", 123, 220, FONTS.MEDIUM)
	draw_text("Drawing from the tidal forces", 76, 243, FONTS.MEDIUM)
	draw_text("by the god [MAD]Hampa.", 119, 266, FONTS.MEDIUM)
	draw_text("You serve the one god only!", 95, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Maya") then
	draw_text("Mayans were known for their", 80, 220, FONTS.MEDIUM)
	draw_text("deep intellect, strategy and culture.", 44, 243, FONTS.MEDIUM)
	draw_text("This rich mayan blue brings about", 60, 266, FONTS.MEDIUM)
	draw_text("spirits and inspiration from a time ", 50, 289, FONTS.MEDIUM)
	draw_text("lost to man.", 180, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Mysterio") then
	draw_text("Droppin' Da Dime", 152, 243, FONTS.MEDIUM)
	draw_text("and a Six One Nine.", 145, 266, FONTS.MEDIUM)
	draw_text("No one does it like Mysterio.", 90, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Neptune") then
	draw_text("Let the spirit of Poseidon", 105, 220, FONTS.MEDIUM)
	draw_text("guide your every move.", 120, 243, FONTS.MEDIUM)
	draw_text("The healing calm of water fused with", 38, 266, FONTS.MEDIUM)
	draw_text("the destructive power of tidal waves", 38, 289, FONTS.MEDIUM)
	draw_text("flow through your veins.", 110, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Noxious") then
	draw_text("A great evil causes this emanation.", 50, 220, FONTS.MEDIUM)
	draw_text("The flames burn a strong hue...", 70, 243, FONTS.MEDIUM)
	draw_text("Alluring from afar, devastating", 60, 266, FONTS.MEDIUM)
	draw_text("from close range.", 150, 289, FONTS.MEDIUM)
	draw_text(" Vanquish them soldier!", 117, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Olive") then
	draw_text("This rich color blends well", 90, 243, FONTS.MEDIUM)
	draw_text("with any military style suit.", 85, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Orc") then
	draw_text("The animal inside stays silent", 83, 243, FONTS.MEDIUM)
	draw_text("until it can kill again...", 115, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Persian") then
	draw_text("Persia. The land where the light", 71, 220, FONTS.MEDIUM)
	draw_text("shines and burns bright...", 110, 243, FONTS.MEDIUM)
	draw_text("a symbol of the rich history", 95, 266, FONTS.MEDIUM)
	draw_text("and greatness of the ancient empires.", 35, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Pharos") then
	draw_text("The ancient pharaohs harnessed", 70, 220, FONTS.MEDIUM)
	draw_text("the power of the cold from the poles", 41, 243, FONTS.MEDIUM)
	draw_text("to rain a hail of frost upon their enemies,", 13, 266, FONTS.MEDIUM)
	draw_text("rendering them immobile. Call upon this", 23, 289, FONTS.MEDIUM)
	draw_text("power of frost in your time of need.", 40, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Plasma") then
	draw_text("Draw upon the potent", 130, 220, FONTS.MEDIUM)
	draw_text("electrical charges of plasma ", 83, 243, FONTS.MEDIUM)
	draw_text("as you manipulate magnetic fields,", 55, 266, FONTS.MEDIUM)
	draw_text("repelling and destroying your opponents", 16, 289, FONTS.MEDIUM)
	draw_text("with your powerful aura.", 110, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Platinum") then
	draw_text("Forged from solar explosions, platinum", 20, 220, FONTS.MEDIUM)
	draw_text("is a precious mineral that has been", 50, 243, FONTS.MEDIUM)
	draw_text("sought after by every major civilization;", 16, 266, FONTS.MEDIUM)
	draw_text("from past pharaohs, emperors and kings", 18, 289, FONTS.MEDIUM)
	draw_text("to present day nouveau riches.", 72, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Pure") then
	draw_text("The holy fire radiates within your being...", 17, 220, FONTS.MEDIUM)
	draw_text("Burning strong enough to overwhelm", 40, 243, FONTS.MEDIUM)
	draw_text("the strongest of demons.", 105, 266, FONTS.MEDIUM)
	draw_text("Set forth and redeem", 125, 289, FONTS.MEDIUM)
	draw_text(" the universe soldier!", 120, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Quicksilver") then
	draw_text("Be fast. Be quick. Be mercurial.", 75, 220, FONTS.MEDIUM)
	draw_text("And nothing is cooler than the", 77, 243, FONTS.MEDIUM)
	draw_text("Terminator melting in pools", 89, 266, FONTS.MEDIUM)
	draw_text("of quicksilver. Go on, coat yourself", 44, 289, FONTS.MEDIUM)
	draw_text("in hot, Terminator juice!", 107, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Radioactive") then
	draw_text("The Surgeon General says that", 80, 220, FONTS.MEDIUM)
	draw_text("wearing this won't give you", 90, 243, FONTS.MEDIUM)
	draw_text("amazing mutant powers.", 110, 266, FONTS.MEDIUM)
	draw_text("However, you won't ever need a", 70, 289, FONTS.MEDIUM)
	draw_text("flashlight ever again.", 125, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Raider") then	
	draw_text("This deep blue", 175, 243, FONTS.MEDIUM)
	draw_text("is reminiscent of raiders", 110, 266, FONTS.MEDIUM)
	draw_text("of lost tombs...", 165, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Raptor") then
	draw_text("Raptors were swift, aggressive", 68, 220, FONTS.MEDIUM)
	draw_text("creatures in prehistoric times,", 70, 243, FONTS.MEDIUM)
	draw_text("known for stalking, plundering,", 64, 266, FONTS.MEDIUM)
	draw_text("then annihilating their prey.", 85, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Sapphire") then
	draw_text("Ancient tribes used sapphire to represent", 13, 220, FONTS.MEDIUM)
	draw_text("resilience in the face of intensity.", 56, 243, FONTS.MEDIUM)
	draw_text("Now you will bear this very power.", 56, 266, FONTS.MEDIUM)
	draw_text("Not even hellfire can harm you now...", 40, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Shaman") then	
	draw_text("Call upon the tribal fires", 105, 243, FONTS.MEDIUM)
	draw_text("to bring hell upon them all.", 95, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Sphinx") then
	draw_text("The power of the old Egyptian empire", 40, 220, FONTS.MEDIUM)
	draw_text("still flows deep within your body", 65, 243, FONTS.MEDIUM)
	draw_text("and your patience guides you", 90, 266, FONTS.MEDIUM)
	draw_text("to victory", 195, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Static") then	
	draw_text("As the electricity builds within you,", 45, 243, FONTS.MEDIUM)
	draw_text("you strike down all your enemies", 60, 266, FONTS.MEDIUM)
	draw_text("with lightning speed.", 130, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Superfly") then	
	draw_text("From the maker of", 140, 243, FONTS.MEDIUM)
	draw_text("the superfly splash...", 130, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Supernova") then
	draw_text("The energies from interstellar", 70, 220, FONTS.MEDIUM)
	draw_text("explosions fuel you...", 125, 243, FONTS.MEDIUM)
	draw_text("As you feel the power", 125, 266, FONTS.MEDIUM)
	draw_text("flowing through your joints,", 80, 289, FONTS.MEDIUM)
	draw_text("your body emits a burning red glow.", 45, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Titan") then
	draw_text("The spirit of the twelve deities", 67, 220, FONTS.MEDIUM)
	draw_text("of the golden age is with you.", 75, 243, FONTS.MEDIUM)
	draw_text("Worn by the champions", 110, 266, FONTS.MEDIUM)
	draw_text("within the world of Toribash.", 75, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Toxic") then
	draw_text("Toribashians who underwent horrific", 35, 220, FONTS.MEDIUM)
	draw_text("experiments in the name of science...", 38, 243, FONTS.MEDIUM)
	draw_text("and came out the other side", 90, 266, FONTS.MEDIUM)
	draw_text("something new...", 155, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Typhon") then	
	draw_text("Summon the energy of", 120, 243, FONTS.MEDIUM)
	draw_text("Typhon, God of Wind,", 130, 266, FONTS.MEDIUM)
	draw_text("to annihilate your enemies.", 90, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Tyrian") then
	draw_text("Tyrian was a color worn by the great", 40, 220, FONTS.MEDIUM)
	draw_text("warriors and conquerors in history", 43, 243, FONTS.MEDIUM)
	draw_text("as a symbol of their", 130, 266, FONTS.MEDIUM)
	draw_text("strength and influence.", 110, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Vampire") then
	draw_text("The lust for blood drives you", 85, 220, FONTS.MEDIUM)
	draw_text("as you drain every last drop", 85, 243, FONTS.MEDIUM)
	draw_text("from your victims...", 130, 266, FONTS.MEDIUM)
	draw_text("The One... True...", 150, 289, FONTS.MEDIUM)
	draw_text("Nocturnal... Beast!", 130, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Velvet") then	
	draw_text("Velvet is pure luxury.", 125, 243, FONTS.MEDIUM)
	draw_text("Royalty, Wealth, Sophistication.", 60, 266, FONTS.MEDIUM)
	draw_text("Only the rich need apply.", 105, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Viridian") then
	draw_text("Created from rocks of the planetary", 45, 220, FONTS.MEDIUM)
	draw_text("system Viridian and fused with hydrogen,", 18, 243, FONTS.MEDIUM)
	draw_text("This is both a highly explosive", 78, 266, FONTS.MEDIUM)
	draw_text("and reactive material.", 120, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "deprecated") then
	draw_text("Not in use.", 185, 255, FONTS.MEDIUM)
	draw_text("Please use this item for something else.", 23, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Void") then
	draw_text("The living vortex draws the life", 70, 220, FONTS.MEDIUM)
	draw_text("out of your opponents,", 120, 243, FONTS.MEDIUM)
	draw_text("devouring every inch of light.", 80, 266, FONTS.MEDIUM)
	draw_text("This is anti-matter at its most powerful!", 20, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Vortex") then
	draw_text("Peaceful, yet deadly.", 130, 243, FONTS.MEDIUM)
	draw_text("Strike fear into your enemies", 80, 266, FONTS.MEDIUM)
	draw_text("as they enter the eye of the hurricane!", 30, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Vulcan") then
	draw_text("Hailing from a different galaxy,", 65, 243, FONTS.MEDIUM)
	draw_text("vulcans have the ability to control", 50, 266, FONTS.MEDIUM)
	draw_text("the perception of time and space.", 60, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Warrior") then
	draw_text("The adrenaline rush,", 140, 220, FONTS.MEDIUM)
	draw_text("the gorilla press drop,", 122, 243, FONTS.MEDIUM)
	draw_text("the running powerslam.", 115, 266, FONTS.MEDIUM)
	draw_text("All hallmarks of the legendary", 75, 289, FONTS.MEDIUM)
	draw_text("Warrior in the ring.", 137, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Blossom") then
	draw_text("Sakura only blooms for a few", 85, 243, FONTS.MEDIUM)
	draw_text("days in spring.", 165, 266, FONTS.MEDIUM)
	draw_text("As the petals fall, so do your enemies.", 38, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Hawk") then
	draw_text("You strike your opponents down", 75, 243, FONTS.MEDIUM)
	draw_text("much faster, while the Hawk spirit", 55, 266, FONTS.MEDIUM)
	draw_text("gives you the power of focus.", 85, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Wildfire") then
	draw_text("You become one with the Wildfire,", 60, 243, FONTS.MEDIUM)
	draw_text("incinerating anything that", 100, 266, FONTS.MEDIUM)
	draw_text("stands in your way.", 140, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Boreal") then
	draw_text("Find your place in the ecosystem.", 60, 243, FONTS.MEDIUM)
	draw_text("Top the food chain.", 140, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Tesla") then
	draw_text("Unique properties of this material", 60, 243, FONTS.MEDIUM)
	draw_text("allow you to contain the power", 80, 266, FONTS.MEDIUM)
	draw_text("of a neuron star.", 150, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Onyx") then
	draw_text("Synthesized from the power", 90, 220, FONTS.MEDIUM)
	draw_text("of thousands deceased warriors,", 65, 243, FONTS.MEDIUM)
	draw_text("the Earth's core produced but one gem:", 30, 266, FONTS.MEDIUM)
	draw_text("the mighty Onyx", 155, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Ground Texture") then
	if string.find(details_name, "256") then
	draw_text("A 256x256 image for the", 103, 255, FONTS.MEDIUM)
	elseif string.find(details_name, "512") then
	draw_text("A 512x512 image for the", 105, 255, FONTS.MEDIUM)
	else
	draw_text("A 128x128 image for the", 103, 255, FONTS.MEDIUM)
	end
	draw_text("floor area near you", 127, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "128x128 ") then
	local texture_name = nil
	draw_text("A 128x128 empty texture slot", 77, 255, FONTS.MEDIUM)
	texture_name = string.lower(details_name)
	texture_name = string.gsub(texture_name, "128x128 ", "")
	texture_name = string.gsub(texture_name, "texture", "")
	texture_name = string.gsub(texture_name, "joint ", "")
	texture_name = "for your "..texture_name
	local texture_name_width = get_string_length(texture_name, 2)
	draw_text(texture_name, 245 - texture_name_width / 2, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "256x256 ") then
	local texture_name = nil
	draw_text("A 256x256 empty texture slot", 77, 255, FONTS.MEDIUM)
	texture_name = string.lower(details_name)
	texture_name = string.gsub(texture_name, "256x256 ", "")
	texture_name = string.gsub(texture_name, "texture", "")
	texture_name = string.gsub(texture_name, "joint ", "")
	texture_name = "for your "..texture_name
	local texture_name_width = get_string_length(texture_name, 2)
	draw_text(texture_name, 245 - texture_name_width / 2, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "512x512 ") then
	local texture_name = nil
	draw_text("A 512x512 empty texture slot", 77, 255, FONTS.MEDIUM)
	texture_name = string.lower(details_name)
	texture_name = string.gsub(texture_name, "512x512 ", "")
	texture_name = string.gsub(texture_name, "texture", " ")
	texture_name = string.gsub(texture_name, "joint ", " ")
	texture_name = "for your "..texture_name
	local texture_name_width = get_string_length(texture_name, 2)
	draw_text(texture_name, 245 - texture_name_width / 2, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "DQ Texture") then
	draw_text("Tradable texture for your DQ Ring", 49, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Flame Particle Texture") then
	draw_text("This item allows you to change the shape", 21, 239, FONTS.MEDIUM)
	draw_text("of your flame using a texture", 75, 262, FONTS.MEDIUM)
	set_color(0,0,0,1)
	draw_text("REQUIRES AN EXISTING FLAME!", 86, 294, FONTS.MEDIUM)
	set_color(0.16,0.66,0.86,1)
	draw_text("REQUIRES AN EXISTING FLAME!", 87, 294, FONTS.MEDIUM)
	elseif string.find(details_name, "Trail Texture") then
	local texture_name = nil
	texture_name = "A textured trail for your "..string.gsub(details_name, "Trail Texture", "")
	texture_name_length = get_string_length(texture_name, 2)
	draw_text(texture_name, 245 - texture_name_length / 2, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "GUI Background") then
	draw_text("A custom image for the", 110, 255, FONTS.MEDIUM)
	draw_text("Toribash main menu background", 60, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "GUI Header") then
	draw_text("A custom image to replace the", 80, 255, FONTS.MEDIUM)
	draw_text("'Toribash' caption in the main menu", 45, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "GUI Logo") then
	draw_text("A custom image for the", 110, 255, FONTS.MEDIUM)
	draw_text("Toribash logo in the main menu", 68, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "GUI Splatter") then
	draw_text("A custom image to replace the", 78, 255, FONTS.MEDIUM)
	draw_text("blood splatter in the main menu", 68, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Tori Hair") then
	draw_text("The spirit of the Tori", 130, 255, FONTS.MEDIUM)
	draw_text("resides in those who wear this hair.", 45, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Uke Hair") then
	draw_text("The spirit of the Uke", 133, 255, FONTS.MEDIUM)
	draw_text("resides in those who wear this hair.", 45, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Candy Locks") then	
	draw_text("We found this rare hair", 115, 220, FONTS.MEDIUM)
	draw_text("in a Harajuku alley way.", 115, 243, FONTS.MEDIUM)
	draw_text("Only worn by the players who", 85, 266, FONTS.MEDIUM)
	draw_text("fracture knees to socialize.", 88, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Cat Ears") then	
	draw_text("Your keen sense of hearing is recognized", 18, 220, FONTS.MEDIUM)
	draw_text("by Toribashians everywhere.", 90, 243, FONTS.MEDIUM)
	draw_text("Your agility and nine lives", 100, 266, FONTS.MEDIUM)
	draw_text("serve as a trademark.", 125, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Gentleman's Essentials") then
	draw_text("Class and style are the marks", 85, 255, FONTS.MEDIUM)
	draw_text("of a true gentleman.", 133, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Jiyu Dreads") then
	draw_text("Steel drums are playing your anthem.", 35, 220, FONTS.MEDIUM)
	draw_text("The sand is warm under your feet.", 55, 243, FONTS.MEDIUM)
	draw_text("You sweep your hair aside,", 95, 266, FONTS.MEDIUM)
	draw_text("channel your inner calm,", 100, 289, FONTS.MEDIUM)
	draw_text("and prepare for the fight.", 95, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Daimyo Hat and Scarf") then
	draw_text("Heavy sun makes for tired ninja eyes.", 37, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Centurion") then
	draw_text("For the selected few.", 130, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Pony Tail") then
	draw_text("The Pony Tail. A warriors pride.", 77, 220, FONTS.MEDIUM)
	draw_text("Symbolises maturity and accomplishment.", 12, 243, FONTS.MEDIUM)
	draw_text("Wear this to show off your fighting", 42, 266, FONTS.MEDIUM)
	draw_text("prowess and to strike fear into the", 42, 289, FONTS.MEDIUM)
	draw_text("hearts of your opponents.", 105, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Surfer's Seishin") then
	draw_text("Out in the water you're", 115, 220, FONTS.MEDIUM)
	draw_text("free and relaxed.", 150, 243, FONTS.MEDIUM)
	draw_text("The only things you feel is the pulse", 45, 266, FONTS.MEDIUM)
	draw_text("of the water and the anticipation", 55, 289, FONTS.MEDIUM)
	draw_text("for the next big wave.", 120, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "The Sultan's Fez") then
	draw_text("Created by only the most select", 70, 220, FONTS.MEDIUM)
	draw_text("Moorish artisans,", 148, 243, FONTS.MEDIUM)
	draw_text("this shapely hat will aid you", 85, 266, FONTS.MEDIUM)
	draw_text("in your conquers.", 150, 289, FONTS.MEDIUM)
	draw_text("Ladies love it.", 175, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Football Helmet") then	
	draw_text("It won't stop your head coming off.", 50, 243, FONTS.MEDIUM)
	draw_text("Heck, it won't even mitigate damage.", 43, 266, FONTS.MEDIUM)
	draw_text("Still looks cool though.", 120, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Officer Cap") then
	draw_text("Item based on Noir's winning entry", 48, 255, FONTS.MEDIUM)
	draw_text("of the Coiffure Salon event.", 90, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Shutter Shades") then
	draw_text("There have always been those who didn't", 23, 220, FONTS.MEDIUM)
	draw_text("want UV protection and weren't", 70, 243, FONTS.MEDIUM)
	draw_text("interested in polarized lenses.", 75, 266, FONTS.MEDIUM)
	draw_text("They wanted more.", 145, 289, FONTS.MEDIUM)
	draw_text("And so the shutter shades were born.", 40, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Headphones") then
	draw_text("The music moves through you.", 85, 220, FONTS.MEDIUM)
	draw_text("Your sense of style is second only", 55, 243, FONTS.MEDIUM)
	draw_text("to your fighting spirit.", 115, 266, FONTS.MEDIUM)
	draw_text("Let the canorous melodies carry you", 40, 289, FONTS.MEDIUM)
	draw_text("to victory and bring the beatdown.", 50, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Green Hat") then
	draw_text("Despite being useless for", 103, 220, FONTS.MEDIUM)
	draw_text("hand to hand combat, it redeems itself", 28, 243, FONTS.MEDIUM)
	draw_text("by being green and a hat.", 108, 266, FONTS.MEDIUM)
	draw_text("Everything Fish has ever dreamed of.", 40, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Red Submarine") then
	draw_text("To rival the green hat,", 120, 220, FONTS.MEDIUM)
	draw_text("a red sombrero was created.", 85, 243, FONTS.MEDIUM)
	draw_text("Despite boonana's best efforts,", 70, 266, FONTS.MEDIUM)
	draw_text("it came out looking like a submarine.", 40, 289, FONTS.MEDIUM)
	draw_text("So here it is!", 170, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Barbed Wire") then
	draw_text("Hopefully your tetanus vaccines", 70, 255, FONTS.MEDIUM)
	draw_text("are up to date.", 165, 278, FONTS.MEDIUM)
	elseif verify_same_string(details_name, "ToriBooster-50") == 1 then
	draw_text("ToriBooster 50 allows its holder", 60, 255, FONTS.MEDIUM)
	draw_text("to get 50 TC per win!", 135, 278, FONTS.MEDIUM)
	elseif verify_same_string(details_name, "ToriBooster-100") == 1 then
	draw_text("ToriBooster 100 allows its holder", 55, 255, FONTS.MEDIUM)
	draw_text("to get 100 TC per win!", 130, 278, FONTS.MEDIUM)
	elseif verify_same_string(details_name, "ToriBooster-200") == 1 then
	draw_text("ToriBooster 200 allows its holder", 53, 255, FONTS.MEDIUM)
	draw_text("to get 200 TC per win!", 128, 278, FONTS.MEDIUM)
	elseif verify_same_string(details_name, "ToriBooster-500") == 1 then
	draw_text("ToriBooster 500 allows its holder", 54, 255, FONTS.MEDIUM)
	draw_text("to get 500 TC per win!", 129, 278, FONTS.MEDIUM)
	elseif verify_same_string(details_name, "ToriBooster-1000") == 1 then
	draw_text("ToriBooster 1000 allows its holder", 48, 243, FONTS.MEDIUM)
	draw_text("to get 1000 TC per win!", 123, 266, FONTS.MEDIUM)
	draw_text("This is easy money.", 144, 294, FONTS.MEDIUM)
	elseif verify_same_string(details_name, "ToriBooster-10000") == 1 then
	draw_text("ToriBooster 10000 allows its holder", 42, 243, FONTS.MEDIUM)
	draw_text("to get 10000 TC per win!", 117, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Qi Booster X2") then
	draw_text("QiBooster-X2 allows its holder", 67, 255, FONTS.MEDIUM)
	draw_text("to gain belts and Qi twice as fast.", 55, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Forum VIP") then
	draw_text("Pack that allows you", 130, 243, FONTS.MEDIUM)
	draw_text("new forum functionality", 105, 266, FONTS.MEDIUM)
	set_color(0,0,0,1)
	draw_text("What's this?", 175, 294, FONTS.MEDIUM)
	if (buttons.info_prime.state == BTN_UP) then
		set_color(0.16,0.66,0.86,1)
	elseif (buttons.info_prime.state == BTN_DOWN) then
		set_color(0.58, 0, 0, 1)
	else
		set_color(0.82, 0.39, 0.39, 1.0)
	end
	draw_text("What's this?", 176, 294, FONTS.MEDIUM)
	elseif string.find(details_name, "Qi 10000") then
	draw_text("Adds 10000 Qi to your game account.", 44, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Qi 1000") then
	draw_text("Adds 1000 Qi to your game account.", 50, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Qi 5000") then
	draw_text("Adds 5000 Qi to your game account.", 49, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Head Avatar") then	
	draw_text("For good luck and ingame companionship.", 15, 243, FONTS.MEDIUM)
	draw_text("Uses your current head texture", 68, 266, FONTS.MEDIUM)
	draw_text("and appears under your nickname.", 55, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Set") then	
	draw_text("Sets can contain other items.", 77, 243, FONTS.MEDIUM)
	draw_text("Good for trading packs and", 85, 266, FONTS.MEDIUM)
	draw_text("organizing your inventory.", 88, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Custom Belt") then	
	draw_text("For the few who reach", 118, 243, FONTS.MEDIUM)
	draw_text("20,000 games played", 125, 266, FONTS.MEDIUM)
	draw_text("they can choose their own title.", 65, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "DQ Sound") then	
	draw_text("Sound played when you DQ.", 98, 255, FONTS.MEDIUM)
	draw_text("Even if you lose, do it in style.", 75, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Grip Sound") then	
	draw_text("This item allows you to play", 90, 243, FONTS.MEDIUM)
	draw_text("a custom sound when your character", 40, 266, FONTS.MEDIUM)
	draw_text("grips the other player.", 110, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Hit 1 Sound") then	
	draw_text("Sound played when your Tori", 85, 243, FONTS.MEDIUM)
	draw_text("gets a light hit.", 157, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Hit 2 Sound") then	
	draw_text("Sound played when your Tori", 85, 243, FONTS.MEDIUM)
	draw_text("gets a medium-light hit.", 113, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Hit 3 Sound") then	
	draw_text("Sound played when your Tori", 85, 243, FONTS.MEDIUM)
	draw_text("gets a medium hit.", 145, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Hit 4 Sound") then	
	draw_text("Sound played when your Tori", 85, 243, FONTS.MEDIUM)
	draw_text("gets a medium-hard hit.", 115, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Hit 5 Sound") then	
	draw_text("Sound played when your Tori", 85, 243, FONTS.MEDIUM)
	draw_text("gets a hard hit.", 158, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Kiai Sound") then
	draw_text("Kiai! Your shout echoes through the dojo.", 16, 243, FONTS.MEDIUM)
	draw_text("Strengthening your moral and weakening", 15, 266, FONTS.MEDIUM)
	draw_text("your opponents' knees.", 120, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Win Sound") then
	draw_text("You shout out in triumph", 110, 220, FONTS.MEDIUM)
	draw_text("for you have fought and won.", 85, 243, FONTS.MEDIUM)
	draw_text("Another victory and another step", 55, 266, FONTS.MEDIUM)
	draw_text("closer to the top.", 145, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Blood Vodka") then
	draw_text("Blood Vodka was originally made", 60, 197, FONTS.MEDIUM)
	draw_text("in the middle of the Raging Luerio War.", 35, 220, FONTS.MEDIUM)
	draw_text("Right when there seemed no hope,", 60, 243, FONTS.MEDIUM)
	draw_text("a battalion right in the heat of the battle", 15, 266, FONTS.MEDIUM)
	draw_text("created the most astonishing vodka...", 35, 289, FONTS.MEDIUM)
	draw_text("Blood Vodka, named for their fallen.", 40, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Casino Chips") then
	draw_text("Stack 'em up!", 170, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Contact KiTFoX") then
	draw_text("No matter what the problem is -", 70, 255, FONTS.MEDIUM)
	draw_text("contact KiTFoX!", 160, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Eriol Icecream") then
	draw_text("A small icecream on a cone from the last", 20, 197, FONTS.MEDIUM)
	draw_text("bucket of icecream that was ever created", 14, 220, FONTS.MEDIUM)
	draw_text("by the Eriol people, sought after", 63, 243, FONTS.MEDIUM)
	draw_text("for the last 400,000 years.", 95, 266, FONTS.MEDIUM)
	draw_text("Some say the secret to their extinction", 25, 289, FONTS.MEDIUM)
	draw_text("somehow lies in this icecream...", 65, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "hampa's knife") then
	draw_text("Used by hampa to cut off his leg after it", 25, 197, FONTS.MEDIUM)
	draw_text("was trapped by a massive boulder during", 19, 220, FONTS.MEDIUM)
	draw_text("mountain climbing with Kai-Tiger who got", 12, 243, FONTS.MEDIUM)
	draw_text("so scared that he ran away. hampa later", 22, 266, FONTS.MEDIUM)
	draw_text("found him and cut off both of his legs.", 32, 289, FONTS.MEDIUM)
	draw_text("This is a masterpeice of Tori history.", 38, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Hector Relax") then
	draw_text("When Hector managed to obtain every", 35, 197, FONTS.MEDIUM)
	draw_text("kind of items in Toribash,", 100, 220, FONTS.MEDIUM)
	draw_text("Hector Relax was created to trick him.", 30, 243, FONTS.MEDIUM)
	draw_text("The trick worked for several weeks.", 43, 266, FONTS.MEDIUM)
	draw_text("After that, this rare item was lying", 42, 289, FONTS.MEDIUM)
	draw_text("in his inventory too.", 135, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Highland Tomatoes") then
	draw_text("The Highland Tomatoes are one of the", 35, 197, FONTS.MEDIUM)
	draw_text("most popular drugs in the universe.", 44, 220, FONTS.MEDIUM)
	draw_text("It has LSD, Cannabis and DXM as well", 42, 243, FONTS.MEDIUM)
	draw_text("as the flavour of tomatoes.", 90, 266, FONTS.MEDIUM)
	draw_text("Because of the demand,", 113, 289, FONTS.MEDIUM)
	draw_text("this drug is very expensive.", 92, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Lighter") then
	draw_text("This is a lighter to light your", 80, 255, FONTS.MEDIUM)
	draw_text("Marlboro smokes!", 140, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Marlboro Lights") then
	draw_text("These are extreme smokes!", 96, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "master siku's toy piano") then
	draw_text("THAS AS THA TAY PAANA THAT ANCA BALANGAD", 20, 197, FONTS.MEDIUM)
	draw_text("TA THA LAGANDARY MASTAR SIKU.", 80, 220, FONTS.MEDIUM)
	draw_text("WHAN SIKU DASAPPAARAD APAN AXPLARATAAN", 15, 243, FONTS.MEDIUM)
	draw_text("AF A BLACKHALA, HAS ATAMS WARA", 70, 266, FONTS.MEDIUM)
	draw_text("AACTAANAD AFF. THAS AS ANA AF", 80, 289, FONTS.MEDIUM)
	draw_text("THA FAW ATAMS AP FAR PABLAC AACTAAN.", 37, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Organic Cucumber") then	
	draw_text("Grown in veb's greenhouse the only", 50, 243, FONTS.MEDIUM)
	draw_text("additive is a secret blend of 'awesome'", 30, 266, FONTS.MEDIUM)
	draw_text("guaranteeing a perfect yield.", 80, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Pet Rock") then
	draw_text("This tiny rock, which must be fed and", 37, 220, FONTS.MEDIUM)
	draw_text("watered daily, has been proven to", 55, 243, FONTS.MEDIUM)
	draw_text("provide companionship in even the most", 22, 266, FONTS.MEDIUM)
	draw_text("dire of situations, and to be completely", 22, 289, FONTS.MEDIUM)
	draw_text("immune to industrial grade incinerators.", 15, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Pickled Cucumbers") then
	draw_text("This is what happens to cucumbers", 53, 255, FONTS.MEDIUM)
	draw_text("when you drown them in vinegar.", 63, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Pocket Rockets") then
	draw_text("The most powerful starting hand", 60, 255, FONTS.MEDIUM)
	draw_text("in Texas Hold'em.", 155, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Scotch Tape") then
	draw_text("This is the tape that was used throughout", 17, 197, FONTS.MEDIUM)
	draw_text("the ancient Toriworld. After a severely", 26, 220, FONTS.MEDIUM)
	draw_text("brutal fight, the Old Toris would pick", 35, 243, FONTS.MEDIUM)
	draw_text("themselves up and tape themselves back", 23, 266, FONTS.MEDIUM)
	draw_text("into working order. It was the most", 42, 289, FONTS.MEDIUM)
	draw_text("painful yet effective way, back then.", 38, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Shades") then
	draw_text("Be careful, don't be giving away tells...", 27, 255, FONTS.MEDIUM)
	draw_text("wear your shades!", 150, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "ToriBeer") then
	draw_text("This beer was created with water from", 30, 197, FONTS.MEDIUM)
	draw_text("the Kuleso Spring, the most sacred water", 16, 220, FONTS.MEDIUM)
	draw_text("spring in the whole of Tori.", 90, 243, FONTS.MEDIUM)
	draw_text("This beer has won over 7 awards", 60, 266, FONTS.MEDIUM)
	draw_text("for its outstanding and unique", 65, 289, FONTS.MEDIUM)
	draw_text("colour and taste.", 145, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "ToriBurger") then
	draw_text("ToriBurger comes from the Restaurant", 30, 197, FONTS.MEDIUM)
	draw_text("at the end of the Universe.", 100, 220, FONTS.MEDIUM)
	draw_text("Some say it doesn't actually exist...", 45, 243, FONTS.MEDIUM)
	draw_text("but others say you must believe.", 62, 266, FONTS.MEDIUM)
	draw_text("For if you believe there is a ToriBurger,", 23, 289, FONTS.MEDIUM)
	draw_text(" there shall be a ToriBurger", 85, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Boxing Helm") then
	draw_text("In 'as new' condition!", 123, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Boxing Glove") then
	draw_text("Despite its appearance", 120, 255, FONTS.MEDIUM)
	draw_text("it won't make your punches softer.", 50, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Eye Patch") then
	draw_text("Defence +1", 182, 243, FONTS.MEDIUM)
	draw_text("Depth perception -2", 130, 266, FONTS.MEDIUM)
	draw_text("Piratyness +100", 150, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Frankenbolts") then
	set_color(0.95,0.83,0.01, 1)
	print_desc("Halloween Limited Item", 1)
	set_color(1,1,1,1)
	print_desc("No, this doesn't make you a doctor...", 2)
	elseif string.find(details_name, "Lil Spooks") then
	set_color(0.95,0.83,0.01, 1)
	print_desc("Halloween Limited Item", 1)
	set_color(1,1,1,1)
	print_desc("Spooks you and cheers you up", 2)
	print_desc("at the same time!", 3)
elseif string.find(details_name, "Zombie Hand") then
	set_color(0.95,0.83,0.01, 1)
	print_desc("Halloween Limited Item", 1)
	set_color(1,1,1,1)
	print_desc("Who could know that those zombies", 2)
	print_desc("have such a strong grip?", 3)
	elseif (string.find(details_name, "Jack") and string.find(details_name, "lantern")) then
	set_color(0.95,0.83,0.01, 1)
	print_desc("Halloween Limited Item", 0)
	set_color(1,1,1,1)
	print_desc("With this pumpkin on your head,", 1)
	print_desc("you're all set to start trick or treating!", 2)
	elseif string.find(details_name, "Witch Hat") then
	set_color(0.95,0.83,0.01, 1)
	print_desc("Halloween Limited Item", -1)
	set_color(1, 1, 1, 1)
	draw_text("Legends say it gives it's wearer", 69, 243, FONTS.MEDIUM)
	draw_text("magical powers...", 150, 266, FONTS.MEDIUM)
	draw_text("no one ever discovered how to use them.", 24, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Skull Necklace") then
	set_color(0.95,0.83,0.01, 1)
	print_desc("Halloween Limited Item", -1)
	set_color(1,1,1,1)
	print_desc("A beautiful masterpiece to show your", 0)
	print_desc("foes what you reserve for them", 1)
	print_desc("after their demise.", 2)
	elseif string.find(details_name, "Portable Cassette") then
	draw_text("This was once the pinnacle", 90, 255, FONTS.MEDIUM)
	draw_text("of portable music technology.", 72, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Propeller Hat") then
	draw_text("Chuckachuckachuckachucka", 90, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Kickin' Kick") then
	draw_text("Very stylish.", 175, 255, FONTS.MEDIUM)
	elseif string.find(details_name, "Kamehamehair") then
	draw_text("May cause beams of energy", 94, 243, FONTS.MEDIUM)
	draw_text("to shoot from your hands.", 100, 266, FONTS.MEDIUM)
	draw_text("All I'm saiyan is to be careful.", 80, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Santa's Hat") then
	draw_text("Headgear of the greatest", 100, 220, FONTS.MEDIUM)
	draw_text("elven factories owner ever.", 88, 243, FONTS.MEDIUM)
	draw_text("Is definitely better than that", 81, 266, FONTS.MEDIUM)
	draw_text("wiggly Santa Hat from 2013.", 86, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Candy Cane") then
	draw_text("The only candy that will", 110, 210, FONTS.MEDIUM)
	draw_text("really last forever (*).", 115, 233, FONTS.MEDIUM)
	draw_text("* because it's stuck to your back.", 54, 266, FONTS.MEDIUM)
	draw_text("How did you plan to lick it?", 95, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Elven Hat") then
	draw_text("By wearing this you are agreeing", 60, 197, FONTS.MEDIUM)
	draw_text("to work 24/7 fabricating tablets", 55, 220, FONTS.MEDIUM)
	draw_text("for 7 year olds during next year.", 55, 243, FONTS.MEDIUM)
	draw_text("Also hampa thinks that it looks", 65, 266, FONTS.MEDIUM)
	draw_text("like a rave hat from 1996.", 100, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Rudolph Nose and Antlers") then
	draw_text("Congratulations on becoming", 80, 243, FONTS.MEDIUM)
	draw_text("a magical reindeer!", 135, 266, FONTS.MEDIUM)
	draw_text("Now light your nose and get high!", 60, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Mullet") then
	draw_text("Business in the front,", 123, 255, FONTS.MEDIUM)
	draw_text("Party in the back", 150, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Geta") then
	draw_text("I had a friend once, but he called", 62, 197, FONTS.MEDIUM)
	draw_text("my Fumikomi no Keri a pair of", 73, 220, FONTS.MEDIUM)
	draw_text("wooden sandals, so I teleported behind", 28, 243, FONTS.MEDIUM)
	draw_text("him and slashed him in half", 92, 266, FONTS.MEDIUM)
	draw_text("with my wooden katano.", 112, 289, FONTS.MEDIUM)
	draw_text("Nothing personal, kid.", 121, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Seishin") then
	draw_text("Small part of the bright future.", 60, 243, FONTS.MEDIUM)
	draw_text("Dismemberthreshold: +10", 100, 270, FONTS.MEDIUM)
	draw_text("Damage: x1.1", 165, 293, FONTS.MEDIUM)
	set_color(0.16,0.66,0.86,1)
	draw_text("ITEMS DO NOT STACK", 137, 215, FONTS.MEDIUM)
	elseif string.find(details_name, "Punkspike") then
	draw_text("Noobcalp damage +10", 135, 243, FONTS.MEDIUM)
	draw_text("Moshpit presence +20", 130, 266, FONTS.MEDIUM)
	draw_text("Parental approval -5", 132, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Blindfold") then
	draw_text("Like the eye patch but", 125, 210, FONTS.MEDIUM)
	draw_text("all over your face and head.", 90, 233, FONTS.MEDIUM)
	draw_text("No matter - because who needs vision", 40, 266, FONTS.MEDIUM)
	draw_text("when you have crazy ass ninja instinct!", 25, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Bunny Ears") then
	draw_text("All that was left of Peter Rabbit", 65, 255, FONTS.MEDIUM)
	draw_text("after Mr. McGregor finally caught him.", 25, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Jester Hat") then
	draw_text("WHAT'S RED AND CRUNCHY?..", 100, 255, FONTS.MEDIUM)
	draw_text("A FIRE ENGINE SANDWICH!!!", 100, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Odd Mask") then
	draw_text("If Cupid and a crow had a love child,", 40, 243, FONTS.MEDIUM)
	draw_text("he'd probably look like you", 90, 270, FONTS.MEDIUM)
	set_color(0.16,0.66,0.86,1)
	draw_text("Odlov's legendary item", 120, 215, FONTS.MEDIUM)
	elseif string.find(details_name, "SWAG Cap") then
	draw_text("Get your #SWAG on", 140, 255, FONTS.MEDIUM)
	draw_text("with this dope-ass cap!", 115, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Swagtastic Gear") then
	draw_text("Now with 420% more #SWAG & MLG,", 50, 255, FONTS.MEDIUM)
	draw_text("and not to forget - weed!", 105, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Gentlemen's Mustache") then
	draw_text("Sir, there seems to be", 125, 255, FONTS.MEDIUM)
	draw_text("a squirrel on your upper lip.", 90, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Painter's Mustache") then
	draw_text("Mon cher, you seem to have", 95, 255, FONTS.MEDIUM)
	draw_text("some paint on your Stache!", 100, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Beret O' Messieurs") then
	draw_text("Excusez-moi mon ami, mais", 100, 255, FONTS.MEDIUM)
	draw_text("vouz avez aucune chance contre moi!", 35, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Santa Hat") then
	draw_text("Spread joy and positive vibes using", 55, 220, FONTS.MEDIUM)
	draw_text("a 2013 Santa Hat while shoveling through", 19, 243, FONTS.MEDIUM)
	draw_text("snow in a drunken rage from the heart", 30, 266, FONTS.MEDIUM)
	draw_text("of Finland, home of Siku.", 100, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Santa Beard") then
	draw_text("Nothing brings Saami groupies", 75, 220, FONTS.MEDIUM)
	draw_text("for Santa likes his beard.", 105, 243, FONTS.MEDIUM)
	draw_text("It was forged over centuries,", 85, 266, FONTS.MEDIUM)
	draw_text("in the freezing cold of Lapland.", 75, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Side Kitsune Mask") then
	draw_text("Minimalist version of the Kitsune Mask,", 23, 220, FONTS.MEDIUM)
	draw_text("placed on the side. Use it if you wish", 45, 243, FONTS.MEDIUM)
	draw_text("to not hide your face while still", 66, 266, FONTS.MEDIUM)
	draw_text("praising to the mighty kitsunes.", 65, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Beaten Halo") then
	draw_text("How could it possibly be undamaged?", 35, 243, FONTS.MEDIUM)
	draw_text("You fight so often!", 140, 266, FONTS.MEDIUM)
	draw_text("Be more careful...", 145, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Beerhat") then
	draw_text("Love has 4 letters,", 145, 243, FONTS.MEDIUM)
	draw_text("so does beer,", 170, 266, FONTS.MEDIUM)
	draw_text("beer is love.", 175, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Court Jester") then
	draw_text("Don't let your teeth make you lose", 55, 243, FONTS.MEDIUM)
	draw_text("respect by permanently keeping them", 36, 266, FONTS.MEDIUM)
	draw_text("opened for the sake of being friendly.", 36, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Head Toriboppers") then
	draw_text("Parties aren't memorable until", 75, 243, FONTS.MEDIUM)
	draw_text("you're wearing a head bopper", 87, 266, FONTS.MEDIUM)
	draw_text("while crafting memories.", 105, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Kunai Holster") then
	draw_text("A battle-hardened Kunai,", 110, 243, FONTS.MEDIUM)
	draw_text("once wielded by the legendary kunoichi,", 30, 266, FONTS.MEDIUM)
	draw_text("THIGGIST, the Eighth Hokage.", 90, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Armblade") then
	draw_text("An Armblade for a stylish Fighter!", 55, 256, FONTS.MEDIUM)
	draw_text("*Cosmetic Purpose Only*", 110, 279, FONTS.MEDIUM)
	elseif string.find(details_name, "Pilgrim's Hat") then
	draw_text("The day where all that matters is food!", 30, 256, FONTS.MEDIUM)
	draw_text("Oops, I mean family.", 130, 279, FONTS.MEDIUM)
	elseif string.find(details_name, "Pipe") then
	draw_text("You may die sooner, but at least", 70, 256, FONTS.MEDIUM)
	draw_text("you went out with style.", 115, 279, FONTS.MEDIUM)
	elseif string.find(details_name, "Ski Goggles") then
	draw_text("Not like you're going to", 105, 243, FONTS.MEDIUM)
	draw_text("slalom down mount Everest,", 85, 266, FONTS.MEDIUM)
	draw_text("but they still look cool.", 107, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Fashionable Bow") then
	draw_text("Now you can wear this nice", 100, 233, FONTS.MEDIUM)
	draw_text("Valentine-themed bow-tie on your dates,", 22, 256, FONTS.MEDIUM)
	draw_text("or even give them to your special", 60, 279, FONTS.MEDIUM)
	draw_text("someone for them to wear as a present!", 25, 302, FONTS.MEDIUM)
	set_color(0.16,0.66,0.86,1)
	draw_text("Original design by Leanmarkie", 80, 200, FONTS.MEDIUM)
	elseif string.find(details_name, "Love Potion") then
	draw_text("Extracted Oxytocin, Serotonin and", 50, 243, FONTS.MEDIUM)
	draw_text("Dopamine guaranteed to beguile your", 37, 266, FONTS.MEDIUM)
	draw_text("target in deep love.", 135, 289, FONTS.MEDIUM)
	set_color(0.16,0.66,0.86,1)
	draw_text("Original design by Wyverneon", 80, 210, FONTS.MEDIUM)
	elseif string.find(details_name, "Tengu Mask") then
	draw_text("Summons the power", 130, 255, FONTS.MEDIUM)
	draw_text("of a legendary creature!", 102, 279, FONTS.MEDIUM)
	set_color(0.16,0.66,0.86,1)
	draw_text("Forged by Stalker", 140, 200, FONTS.MEDIUM)
	elseif string.find(details_name, "Hidden Blade") then
	draw_text("Signature weapon of an assassin.", 60, 233, FONTS.MEDIUM)
	draw_text("Kill without leaving a trace,", 90, 256, FONTS.MEDIUM)
	draw_text("because the shadows are", 110, 279, FONTS.MEDIUM)
	draw_text("your best disguise.", 138, 302, FONTS.MEDIUM)
	elseif string.find(details_name, "Kitsune Mask") then
	draw_text_angle_scale("Kitsune is the Japanese word for fox", 70, 233, 0, 0.9, FONTS.MEDIUM)
	draw_text_angle_scale("also known as an intelligent and magic youkai", 28, 253, 0, 0.9, FONTS.MEDIUM)
	draw_text_angle_scale("in their folklore. They usually shape shift into", 30, 273, 0, 0.9, FONTS.MEDIUM)
	draw_text_angle_scale("men and women to trick others, so what would", 22, 293, 0, 0.9, FONTS.MEDIUM)
	draw_text_angle_scale("be more ironic than disguising as one of them?", 25, 313, 0, 0.9, FONTS.MEDIUM)
	set_color(0.16,0.66,0.86,1)
	draw_text("Forged by Stalker", 140, 200, FONTS.MEDIUM)
	elseif string.find(details_name, "Flower Crown") then
	draw_text("Pretty wreath, a headdress made of", 45, 220, FONTS.MEDIUM)
	draw_text("leaves, grasses, flowers or branches.", 35, 243, FONTS.MEDIUM)
	draw_text("It is typically worn in festive occasions", 20, 266, FONTS.MEDIUM)
	draw_text("and on holy days.", 150, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Gangster Bandana") then
	draw_text("In case you need to show", 105, 255, FONTS.MEDIUM)
	draw_text("who is the B0SS in the Hood.", 87, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Beaten Horns") then
	draw_text("OW, MY FREAKING HORN!!!", 115, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Bucket Helmet") then
	draw_text("For safety purposes.", 130, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Chef Hat") then
	draw_text("Next step: 99 cooking.", 120, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Cereal Box") then
	draw_text("Second place winner of", 117, 255, FONTS.MEDIUM)
	draw_text("'Head in a Box' event", 132, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Crayon Tori Box") then
	draw_text("First place winner of", 128, 255, FONTS.MEDIUM)
	draw_text("'Head in a Box' event", 132, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Hampa Box") then
	draw_text("Fifth place winner of", 128, 255, FONTS.MEDIUM)
	draw_text("'Head in a Box' event", 132, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Smile Box") then
	draw_text("Third place winner of", 128, 255, FONTS.MEDIUM)
	draw_text("'Head in a Box' event", 132, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Tori Box") then
	draw_text("Fifth place winner of", 128, 255, FONTS.MEDIUM)
	draw_text("'Head in a Box' event", 132, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "TV Box") then
	draw_text("Fourth place winner of", 120, 255, FONTS.MEDIUM)
	draw_text("'Head in a Box' event", 132, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Deal With It") then
	draw_text("You know...it never harmed anyone", 55, 255, FONTS.MEDIUM)
	draw_text("to just", 115, 279, FONTS.MEDIUM)
	draw_text_angle_scale("Deal With It.", 200, 273, 0, 0.6, FONTS.BIG)
	draw_text_angle_scale("Deal With It.", 200, 273, 0, 0.6, FONTS.BIG)
	elseif string.find(details_name, "Duckbill") then
	draw_text("QUACK!", 200, 255, FONTS.MEDIUM)
	draw_text("The duckbill movement has passed!", 55, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Elbow Pad") then
	draw_text("For your protection! Safety first!", 50, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Flammable Box") then
	draw_text("Keep away from fire!!!", 120, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Steampunk Goggles") then
	draw_text("A Maniac's dream come true.", 85, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Box-") and string.find(details_name, "Glove") then
	draw_text("For Box-ing!", 180, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Magical Uni-") then
	draw_text("OOOOOOOOOOOOH, PRETTY COLORS!", 65, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Nerd Glasses") then
	draw_text("You wouldn't hit a guy with glasses,", 45, 255, FONTS.MEDIUM)
	draw_text("would you?!?", 175, 278, FONTS.MEDIUM) 
	elseif string.find(details_name, "Poker Hat") then
	draw_text("MY P-P-POKER HAT MY P-POKER HAT!", 58, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Jim the Tuna") then
	draw_text("Escapee from the canning factory", 55, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "The Kick-") and string.find(details_name, "Me Box") then
	draw_text("For when your head needs a good kicking!", 18, 243, FONTS.MEDIUM)
	draw_text_angle_scale("(However you feel like some padding would be nice)", 27, 266, 0, 0.8, FONTS.MEDIUM)
	elseif string.find(details_name, "Totally 3D!") then
	draw_text("3D Glasses 3D Item in a 3D Game?!?", 53, 255, FONTS.MEDIUM) 
	draw_text("Totally 3D! (glasses)!", 130, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Colossal Sword") then
	draw_text("A legendary sword created by", 75, 255, FONTS.MEDIUM) 
	draw_text("the God himself, Zeus.", 115, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Hazard Mask") then
	draw_text("Want some of that Cyber-Gothic look?", 35, 255, FONTS.MEDIUM) 
	draw_text("You can have that now!", 115, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Nailbat") then
	draw_text("A Makeshift Weapon often used to", 55, 243, FONTS.MEDIUM) 
	draw_text("brutally murder zombies.", 100, 266, FONTS.MEDIUM)
	draw_text("As deadly as it is simple.", 110, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Ash Switch") then
	draw_text("Makes magic!", 170, 266, FONTS.MEDIUM)
	elseif string.find(details_name, "Master siku's Toy Piano") then
	draw_text("THAS AS THA TAY PAANA THAT ANCA BALANGAD", 20, 197, FONTS.MEDIUM)
	draw_text("TA THA LAGANDARY MASTAR SIKU. WHAN SIKU", 22, 220, FONTS.MEDIUM)
	draw_text("DASAPPAARAD APAN AXPLARATAAN AF A,", 42, 243, FONTS.MEDIUM)
	draw_text("BLACKHALA, HAS ATAMS WARA AACTAANAD AFF.", 13, 266, FONTS.MEDIUM)
	draw_text("THAS AS ANA AF THA FAW ATAMS AP FAR", 48, 289, FONTS.MEDIUM)
	draw_text("PABLAC AACTAAN.", 160, 312, FONTS.MEDIUM)
	elseif string.find(details_name, "Cel Shaded Tori") then
	draw_text("This is how you'd look if", 110, 255, FONTS.MEDIUM) 
	draw_text("it was 2008 now!", 145, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "ToriArmor") then
	draw_text("The Tori Armor Set,", 140, 255, FONTS.MEDIUM) 
	draw_text("created by dumbn00b", 125, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Mecha Arm") then
	draw_text("If you have been Dismembered", 80, 255, FONTS.MEDIUM) 
	draw_text("we can rearm you", 145, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Cowboy Hat") then
	draw_text("Winner of the 3D Showdown Event!", 55, 243, FONTS.MEDIUM) 
	draw_text("A Western Themed Cowboy Hat", 80, 266, FONTS.MEDIUM)
	draw_text("idea inspired by Code", 125, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Box of Boxes") then
	draw_text("This is the boxception!", 115, 266, FONTS.MEDIUM) 
	elseif string.find(details_name, "Flip Flops") then
	draw_text("Type of open-toed footwear sandal,", 45, 255, FONTS.MEDIUM) 
	draw_text("typically worn as a form of casual wear.", 20, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Flippers") then
	draw_text("Synthetic flat forelimb", 115, 255, FONTS.MEDIUM) 
	draw_text("for movement through water.", 80, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Cyborg") then
	draw_text("You have been assembled", 105, 255, FONTS.MEDIUM) 
	draw_text("to destroy.", 180, 278, FONTS.MEDIUM)
	elseif string.find(details_name, "Beanie") then
	draw_text("Unleash your inner hipster", 100, 243, FONTS.MEDIUM)
	draw_text("with these commercial,", 116, 266, FONTS.MEDIUM)
	draw_text("mass-produced Beanies.", 115, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Fish Friend") then
	draw_text("I caught my biggest fish but", 90, 243, FONTS.MEDIUM)
	draw_text("can't post it on Facebook because", 56, 266, FONTS.MEDIUM)
	draw_text("my wife thinks I'm working.", 90, 289, FONTS.MEDIUM)
	elseif string.find(details_name, "Soderspy") then
	print_desc("I've got your back!", 2) 
	elseif string.find(details_name, "RAGE!") then
	print_desc("TELL ME I LOOK LIKE A PORCUPINE ONCE AGAIN", 1) 
	print_desc("AND I'LL WRECK YOU SO HARD!!!", 2)
	elseif string.find(details_name, "Clout Goggles") then
	print_desc("For when you want to look cool", 1) 
	print_desc("or just blocking out the sun", 2)
	elseif string.find(details_name, "Head Axe") then
	set_color(0.95,0.83,0.01, 1)
	print_desc("Halloween Limited Item", 1)
	set_color(1,1,1,1)
	print_desc("Heads up!", 2)
	elseif string.find(details_name, "Tombstone") then
	set_color(0.95,0.83,0.01, 1)
	print_desc("Halloween Limited Item", 1)
	set_color(1,1,1,1)
	print_desc("Looks like your ancestor", 2)
	print_desc("wants in on the fight!", 3)
	elseif string.find(details_name, "Obsidian Scythe") then
	set_color(0.95,0.83,0.01, 1)
	print_desc("Halloween Limited Item", 0)
	set_color(1,1,1,1)
	print_desc("The Weapon of Demon Hunters.", 1)
	print_desc("Rewarded to those who have slain", 2)
	print_desc("a Werewolf, a Reaper, and the Devil.", 3)
	elseif string.find(details_name, "Plague Doctor Mask") then
	set_color(0.95,0.83,0.01, 1)
	print_desc("Halloween Limited Item", -1)
	set_color(1,1,1,1)
	print_desc("Originally used by medieval doctors to protect", 0)
	print_desc("from plague, this mask also comes in handy", 1)
	print_desc("when you need to hide your identity", 2)
	print_desc("from the unsuspecting victims.", 3)
	elseif string.find(details_name, "Indian Headdress") then
	print_desc("Contrary to popular belief,", 1) 
	print_desc("did not originate in India", 2)
	elseif string.find(details_name, "Ruined Crown") then
	print_desc("Crown of the Ruined King", 2) 
	elseif string.find(details_name, "Forehead Protector") then
	print_desc("I won't run away anymore,", 1) 
	print_desc("not even with a point lead,", 2)
	print_desc("that is my ninja way!", 3)
	elseif string.find(details_name, "Viking Helmet") then
	print_desc("One of Solax spare helmets,", 1) 
	print_desc("lost after a night full of Mead", 2)
	print_desc("and pillaging", 3)
	elseif string.find(details_name, "Katana") then
	print_desc("A Japanese trademark weapon", 1) 
	print_desc("brought to Toriworld by hampa-san", 2)
	print_desc("during the Gold Age", 3)
	elseif string.find(details_name, "Tori Ninja") then
	print_desc("Become the stealthy assassin", 1) 
	print_desc("armed with the deadliest weapons", 2)
	print_desc("the Toriworld seen yet", 3)
	end
	end
	end
	
	-- Subsection buttons	
	if (main_section == 1) then name_ss = "colors" size_ss = 32
	elseif (main_section == 2) then name_ss = "textures" size_ss = 32
	elseif (main_section == 3) then name_ss = "hairs" size_ss = 128
	elseif (main_section == 4) then name_ss = "misc" size_ss = 128
	elseif (main_section == 5) then name_ss = "colorpacks" size_ss = 128
	elseif (main_section == 6) then name_ss = "texturesets" size_ss = 128
	elseif (main_section == 7) then name_ss = "modelpacks" size_ss = 128
	elseif (main_section == 8) then name_ss = "fulltoris" size_ss = 128
	end
	
	for ss = 1, sub_in_section do
	if (ss == current_section-ss_shift) then
		set_color(1,1,1,0.5)
		draw_disk(buttons[ss].choose_ss.x + (buttons[ss].choose_ss.w - 32) + 16, buttons[ss].choose_ss.y + 16, 0, 16, 100, 1, 0, 180, 0)
		draw_quad(buttons[ss].choose_ss.x + 16, buttons[ss].choose_ss.y, buttons[ss].choose_ss.w - 32, 32)
		draw_disk(buttons[ss].choose_ss.x + 16, buttons[ss].choose_ss.y + 16, 0, 16, 100, 1, 180, 180, 0)
		set_color(0,0,0,0.8)
		draw_disk(buttons[ss].choose_ss.x+16, buttons[ss].choose_ss.y+16, 16, 17, 100, 1, 0, 180, 0)
		draw_disk(buttons[ss].choose_ss.x+16, buttons[ss].choose_ss.y+16, 16, 17, 100, 1, 180, 180, 0)
	else
	if (buttons[ss].choose_ss.state == BTN_HOVER) then
		set_color(1,1,1,0.5)
	elseif (buttons[ss].choose_ss.state == BTN_UP) then
		set_color(0,0,0,0.5)
	else set_color(1,1,1,0.2) end
		draw_disk(buttons[ss].choose_ss.x + (buttons[ss].choose_ss.w - 32) + 16, buttons[ss].choose_ss.y+16, 0, 16, 100, 1, 0, 180, 0)
		draw_quad(buttons[ss].choose_ss.x + 16, buttons[ss].choose_ss.y, buttons[ss].choose_ss.w - 32, 32)
		draw_disk(buttons[ss].choose_ss.x + 16, buttons[ss].choose_ss.y+16, 0, 16, 100, 1, 180, 180, 0)
	end
	
		set_color(1,1,1,1)
		if (ss_icon[ss] ~= load_texture("/torishop/gui/ss/"..name_ss..ss..".tga")) then 
			ss_icon[ss] = load_texture("/torishop/gui/ss/"..name_ss..ss..".tga")
		end
		draw_quad(buttons[ss].choose_ss.x, buttons[ss].choose_ss.y, size_ss, size_ss, ss_icon[ss])
	end
end

function draw_sectionbutton_bg(but_x, but_y, but_w, but_h)
	set_color(0,0,0,0.2)
	draw_disk(but_x+15, but_y+15, 0, 15, 500, 1, -180, 90, 0)
	draw_disk(but_x+15, but_y+but_h-15, 0, 15, 500, 1, -90, 90, 0)
	draw_disk(but_x+but_w-15, but_y+15, 0, 15, 500, 1, 90, 90, 0)
	draw_disk(but_x+but_w-15, but_y+but_h-15, 0, 15, 500, 1, 0, 90, 0)
	draw_quad(but_x+15, but_y, but_w-30, but_h)
	draw_quad(but_x, but_y+15, 15, but_h-30)
	draw_quad(but_x+but_w-15, but_y+15, 15, but_h-30)
end

function draw_sectionbutton_icon(but_x, but_y, section_button, section_button_, res)
	if (section_marked == true) then draw_quad(but_x, but_y, res, res, section_button)
	else draw_quad(but_x, but_y, res, res, section_button_) end
end

function draw_cart_icon(pos)
	if (cart_icon[pos] == nil) then
		if (string.find(cart[pos + cart_shift].name, "Superior")) then
			cart_icon[pos] = load_texture("torishop/icons/superior.tga")
		else
			cart_icon[pos] = load_texture("torishop/icons/"..cart[pos + cart_shift].name..".tga")
		end
	end
	cartbuttons[pos].cartremove = { x = 560, y = height + pos * 36 - cart_slide, w = 16, h = 16, state = BTN_UP }
	if (cartremovestate[pos] == BTN_UP) then
		cart_remove = load_texture("torishop/gui/cartremove.tga")
	elseif (cartremovestate[pos] == BTN_HOVER) then
		cart_remove = load_texture("torishop/gui/cartremove_hvr.tga")
	else
		cart_remove = load_texture("torishop/gui/cartremove_dn.tga")
	end
	draw_quad(cartbuttons[pos].cartremove.x, cartbuttons[pos].cartremove.y, 32, 32, cart_remove)
	draw_quad(583, height + pos * 36 - cart_slide - 8, 32, 32, cart_icon[pos])
end

function draw_cart_warning(cart_warning_type)
	for i = 1, #cart_warning_type do
		if (cart_warning_type[i] == true) then
			if (warning_flag == false and transparency < 1) then
				transparency = transparency + 0.05
			elseif (warning_flag == false and transparency >= 1) then
				set_color(0, 0, 0, 1)
				draw_quad(551, height - 1, transparency, 1)
				if (transparency <= 400) then
					transparency = transparency + 5
				else
					warning_flag = true
					transparency = 1
				end
			elseif (warning_flag == true) then
				transparency = transparency - 0.05
				if (transparency < 0) then
					cart_warning_type[i] = false
					warning_flag = false
				end
			end
			set_color(0, 0, 0, transparency)
			draw_quad(551, height - 38, 400, 38)
			set_color(1, 1, 1, transparency)
			if (i == 1) then
				draw_text("You don't have enough TC!", 560, height - 34, FONTS.MEDIUM)
			else
				draw_text("Cart is full!", 560, height - 34, FONTS.MEDIUM)
			end
		end
	end
end

function draw_cart()
	local color_bg = 0.6
	local color_bg_end = false
	cart_sum = 0
	
	-- CART ANIMATIONS
	if (cart_current == 0) then
		if (cart_slide > 0) then
			cart_slide = cart_slide - 4
		end
	elseif (cart_minimize == false) then
		if (cart_slide < cart_current*36 + 64) then
			if (cart_current < 5) then
				cart_slide = cart_slide + 4
			elseif (cart_slide < 244) then
				cart_slide = cart_slide + 4
			end
		elseif (cart_slide > cart_current*36 + 64) then
			cart_slide = cart_slide - 4
		end
	elseif (cart_minimize == true) then
		if (cart_slide > 64) then
			cart_slide = cart_slide - 4
		end
	end
	
	-- CART BG
	for i = 1, 400 do
		if (color_bg >= 0.8) then
			color_bg_end = true
		end
		if (color_bg_end == false) then
			color_bg = color_bg + i/100000
		else 
			color_bg = color_bg - i/250000 
		end
		set_color(color_bg, 0, 0, 1)
		draw_quad(550 + i, height - cart_slide, 1, cart_slide)
	end
	
	set_color(0, 0, 0, 0.2)
	draw_quad(551, height - cart_slide, 400, 28)
	
	-- LOAD CART ITEM ICONS
	if (cart_current > 0) then
		for i = 1, #cart do
			cart_sum = cart_sum + cart[i].price
		end
		
		if (buttons.cartbuy.state == BTN_UP) then
			cart_purchase = load_texture("torishop/gui/purchase.tga")
		elseif (buttons.cartbuy.state == BTN_HOVER) then
			cart_purchase = load_texture("torishop/gui/purchase_hvr.tga")
		else
			cart_purchase = load_texture("torishop/gui/purchase_dn.tga")
		end
	end
		
	-- CART MAIN
	if (cart_current == 0) then
	elseif (cart_minimize == false) then
		set_color(1, 1, 1, 1)
		for i = 1, 5 do
			if (i + cart_shift > cart_current) then break end
			draw_cart_icon(i)
			local nametemp = ""
			if string.len(cart[i + cart_shift].name) > 15 then
				for j = 1, 13 do
					nametemp = nametemp .. cart[i + cart_shift].name:sub(j,j)
				end
				draw_text(nametemp .. "...", 620, height + i * 36 - cart_slide - 6, FONTS.MEDIUM)
			else
				draw_text(cart[i + cart_shift].name, 620, height + i * 36 - cart_slide - 6, FONTS.MEDIUM)
			end
			draw_right_text(cart[i + cart_shift].price.." TC", width - 945, height + i * 36 - cart_slide - 6, FONTS.MEDIUM)
		end
		
		draw_text("Items in the cart: "..cart_current, 560, height - cart_slide + 2, FONTS.MEDIUM)
		if (cart_slide < 64) then
			set_color(0.4, 0, 0, 1)
			draw_quad(551, height + 26 - cart_slide, 400, 38)
			draw_quad(810, height + 28 - cart_slide, 128, 128, cart_purchase) 
			draw_text("Total: "..cart_sum.." TC", 565, height + 32 - cart_slide, FONTS.MEDIUM)
		else
			set_color(0.4, 0, 0, 1)
			draw_quad(551, height - 38, 400, 38)
			draw_quad(810, height - 36, 128, 128, cart_purchase) 
			draw_text("Total: "..cart_sum.." TC", 565, height - 32, FONTS.MEDIUM)
		end
		
		-- MOVE BETWEEN CART PAGES
		if (cart_current > 5 and cart_slide == 244) then
			for i, v in pairs(buttons.arrows) do
				if (v == buttons.arrows.cart_next and cart_shift + 5 < cart_current) then
					if (v.state == BTN_HOVER) then
						draw_disk(v.x, v.y, 0, 13, 3, 1, v.angle, 360, 0)
					elseif (v.state == BTN_DOWN) then
						draw_disk(v.x, v.y, 0, 7, 3, 1, v.angle, 360, 0)
					else
						draw_disk(v.x, v.y, 0, 10, 3, 1, v.angle, 360, 0)
					end
				end
			end
			for i, v in pairs(buttons.arrows) do
				if (v == buttons.arrows.cart_prev and cart_shift - 5 >= 0) then
					if (v.state == BTN_HOVER) then
						draw_disk(v.x, v.y, 0, 13, 3, 1, v.angle, 360, 0)
					elseif (v.state == BTN_DOWN) then
						draw_disk(v.x, v.y, 0, 7, 3, 1, v.angle, 360, 0)
					else
						draw_disk(v.x, v.y, 0, 10, 3, 1, v.angle, 360, 0)
					end
				end
			end
		end
	
		buttons.arrows.cart_min.y = height - cart_slide + 12
				
		for i, v in pairs(buttons.arrows) do
			if (v == buttons.arrows.cart_min) then
				if (v.state == BTN_HOVER) then
					draw_disk(v.x, v.y, 0, 13, 3, 1, v.angle, 360, 0)
				elseif (v.state == BTN_DOWN) then
					draw_disk(v.x, v.y, 0, 7, 3, 1, v.angle, 360, 0)
				else
					draw_disk(v.x, v.y, 0, 10, 3, 1, v.angle, 360, 0)
				end
			end
		end
	elseif (cart_minimize == true) then
		if (cart_slide > 64) then
			for i = 1, 5 do
				if (i + cart_shift > cart_current) then break end
				draw_cart_icon(i)
				local nametemp = ""
				if string.len(cart[i + cart_shift].name) > 15 then
					for j = 1, 13 do
						nametemp = nametemp .. cart[i + cart_shift].name:sub(j,j)
					end
					draw_text(nametemp .. "...", 620, height + i * 36 - cart_slide - 6, FONTS.MEDIUM)
				else
					draw_text(cart[i + cart_shift].name, 620, height + i * 36 - cart_slide - 6, FONTS.MEDIUM)
				end
				draw_right_text(cart[i + cart_shift].price.." TC", width - 945, height + i * 36 - cart_slide - 6, FONTS.MEDIUM)
			end
		else 
			cart_reload()
		end
		
		set_color(1, 1, 1, 1)
		draw_text("Items in the cart: "..cart_current, 560, height - cart_slide + 2, FONTS.MEDIUM)
		set_color(0.4, 0, 0, 1)
		draw_quad(551, height - 38, 400, 38)
		draw_quad(810, height - 36, 128, 128, cart_purchase) 
		set_color(1, 1, 1, 1)
		draw_text("Total: "..cart_sum.." TC", 565, height - 32, FONTS.MEDIUM)
		
		buttons.arrows.cart_min.y = height - cart_slide + 16
		
		set_color(1, 1, 1, 1)
		for i, v in pairs(buttons.arrows) do
			if (v == buttons.arrows.cart_min) then
				if (v.state == BTN_HOVER) then
					draw_disk(v.x, v.y, 0, 13, 3, 1, v.angle + 180, 360, 0)
				elseif (v.state == BTN_DOWN) then
					draw_disk(v.x, v.y, 0, 7, 3, 1, v.angle + 180, 360, 0)
				else
					draw_disk(v.x, v.y, 0, 10, 3, 1, v.angle + 180, 360, 0)
				end
			end
		end
	end
	if (cart_current > 0) then
	
		-- WARNING IN CASE OF INSUFFICIENT FUNDS OR CART FULL
		draw_cart_warning(cart_warning)
		
	end
end

function draw_sectionbutton(button, hovered, unhovered, scale)
	draw_sectionbutton_bg(button.x, button.y, button.w, button.h)
	select_scolor_links(button.state)
	draw_sectionbutton_icon(button.x + 10, button.y, hovered, unhovered, scale)
end

function draw_torishop()
	local sale_name, sale_discount, sale_id
	local sale_marked = false
	local sale_timeleft_length, discount_length
	
	get_playerinfo() -- to avoid torishop reloading after TC purchase
	run_sale_timer()
	
	if (wait_for_update == 1 or wait_for_update == 2) then
		local disp_string = "Updating torishop data, please wait..."
		if (get_string_length(disp_string, FONTS.BIG) * 0.7 + 600 < width) then 
			set_color(0, 0, 0, wait_warning * 0.8)
			draw_text(disp_string, width - get_string_length(disp_string, FONTS.MEDIUM), height - 30, FONTS.MEDIUM)
		end
		if (wait_for_update == 2) then
			wait_warning = wait_warning - 0.01
		end
		if (wait_warning == 0) then
			wait_for_update = 3
		end
		if (os.difftime(os.time(), warning_time) > 25) then
			wait_for_update = -1
			remove_hooks("update_shop")
		end
	elseif (wait_for_update == -1) then
		local disp_string = "Update failed, please try again later"
		if (get_string_length(disp_string, FONTS.BIG) * 0.7 + 600 < width) then 
			set_color(0, 0, 0, wait_warning * 0.8)
			draw_text(disp_string, width - get_string_length(disp_string.." ", FONTS.MEDIUM), height - 30, FONTS.MEDIUM)
			if (os.difftime(os.time(), warning_time) > 30) then
				wait_warning = wait_warning - 0.01
			end
			if (wait_warning == 0) then
				wait_for_update = 3
			end
		end
	end
	
	-- Overlay
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
	
	-- Draw cart
	draw_cart()
	
	-- Main page
	
	if (main_page == true) then
	
		-- PROMO ANNOUNCEMENT HERE
		if (height >= 720) then
			draw_sectionbutton(buttons.sfeatured, torishop_announcement4, torishop_announcement4, 512)
			
			set_color(0,0,0,0.2)
			draw_quad(0, height-1, 490, 1)
			draw_quad(0, height-32, 491, 31)
		end
		
		set_color(1,1,1,1)
		if (hellomessage == 1) then
		draw_text("Hello, "..name.."!", 10, 10, FONTS.MEDIUM)
		draw_text("Hello, "..name.."!", 10, 10, FONTS.MEDIUM)
		elseif (hellomessage == 2) then		
		draw_text("Hi, "..name.."!", 10, 10, FONTS.MEDIUM)
		draw_text("Hi, "..name.."!", 10, 10, FONTS.MEDIUM)
		else
		draw_text("Greetings, "..name.."!", 10, 10, FONTS.MEDIUM)
		draw_text("Greetings, "..name.."!", 10, 10, FONTS.MEDIUM)
		end
		if ((belt == "Orange Belt") or (belt == "Elite Belt")) then
		draw_text("You have "..tc.." TC and an "..belt, 10, 35, FONTS.MEDIUM)
		draw_text("You have "..tc.." TC and an "..belt, 10, 35, FONTS.MEDIUM)
		else
		draw_text("You have "..tc.." TC and a "..belt, 10, 35, FONTS.MEDIUM)
		draw_text("You have "..tc.." TC and a "..belt, 10, 35, FONTS.MEDIUM)
		end
		
		-- Daily sale section
		
		for i = 1, sections[32].total_items do
			if (sections[32][i].promo == "1") then
				sale_name = sections[32][i].name
				sale_id = i
				sale = true
				break
			end
		end
		if (sale == true) then
			set_color(0,0,0,0.2)
			draw_disk(buttons.sonsale.x + 15, buttons.sonsale.y + 5, 0, 15, 500, 1, -180, 90, 0)
			draw_disk(buttons.sonsale.x + 15, buttons.sonsale.y + 95, 0, 15, 500, 1, -90, 90, 0)
			draw_disk(buttons.sonsale.x + buttons.sonsale.w - 15, buttons.sonsale.y + 5, 0, 15, 500, 1, 90, 90, 0)
			draw_disk(buttons.sonsale.x + buttons.sonsale.w - 15, buttons.sonsale.y + 95, 0, 15, 500, 1, 0, 90, 0)
			draw_quad(buttons.sonsale.x, buttons.sonsale.y + 5, 470, 90)
			draw_quad(buttons.sonsale.x + 15, buttons.sonsale.y - 10, 440, 15)
			draw_quad(buttons.sonsale.x + 15, buttons.sonsale.y + 95, 440, 15)
			
			sale_timeleft_length = get_string_length(get_main_sale_time(sale_id) .. " ", FONTS.MEDIUM)
			
			set_color(0, 0, 0, 1)
			draw_text(get_main_sale_time(sale_id), 244 - sale_timeleft_length / 2, height - 361, FONTS.MEDIUM)
			
			set_color(1, 1, 1, 1)
			draw_text(get_main_sale_time(sale_id), 245 - sale_timeleft_length / 2, height - 360, FONTS.MEDIUM)
		
			if (sale_icon == nil) then 				
				sale_icon = load_texture("/torishop/icons/"..sale_name..".tga")
			end
			draw_quad(buttons.sonsale.x + 120, buttons.sonsale.y + 40, 64, 64, sale_icon)
			if (buttons.sonsale.state == BTN_HOVER or buttons.sonsale.state == BTN_DOWN) then
				draw_quad(buttons.sonsale.x, buttons.sonsale.y - 5, 512, 512, sale_main)
			elseif (buttons.sonsale.state == BTN_UP) then
				draw_quad(buttons.sonsale.x, buttons.sonsale.y - 5, 512, 512, sale_main_)
			end
		end
	
		-- Section Buttons
		if (main_view == 0) then -- Main Screen
			draw_sectionbutton(buttons.mainsingle, sect_singleitems, sect_singleitems_, 256)
			draw_sectionbutton(buttons.mainfull, sect_fulltoris, sect_fulltoris_, 256)
		elseif (main_view == 1) then -- Single Items
			draw_sectionbutton(buttons.scolors, sect_colors, sect_colors_, 256)
			draw_sectionbutton(buttons.stextures, sect_textures, sect_textures_, 256)
			draw_sectionbutton(buttons.shairs, sect_hairs, sect_hairs_, 256)
			draw_sectionbutton(buttons.smisc, sect_misc, sect_misc_, 256)
		else -- Full Toris
			draw_sectionbutton(buttons.scolorpacks, sect_colorpacks, sect_colorpacks_, 256)
			draw_sectionbutton(buttons.stexturesets, sect_texturesets, sect_texturesets_, 256)
			draw_sectionbutton(buttons.smodelpacks, sect_modelpacks, sect_modelpacks_, 256)
			draw_sectionbutton(buttons.sfulltoris, sect_sfulltoris, sect_sfulltoris_, 256)
		end
		
		if (main_view ~= 0) then
			select_color_links(buttons.tomain.state)
			draw_text("BACK", buttons.tomain.x, buttons.tomain.y, FONTS.MEDIUM)
			draw_text("BACK", buttons.tomain.x, buttons.tomain.y, FONTS.MEDIUM)
		end
		
		--Go to see flames
		set_color(0,0,0,0.2)
		draw_disk(90, buttons.sflames.y + 5, 0, 5, 500, 1, -180, 90, 0)
		draw_disk(90, buttons.sflames.y + 35, 0, 5, 500, 1, -90, 90, 0)
		draw_disk(400, buttons.sflames.y + 5, 0, 5, 500, 1, 90, 90, 0)
		draw_disk(400, buttons.sflames.y + 35, 0, 5, 500, 1, 0, 90, 0)
		draw_quad(90, buttons.sflames.y, 310, 40)
		draw_quad(85, buttons.sflames.y + 5, 5, 30)
		draw_quad(400, buttons.sflames.y + 5, 5, 30)
		select_scolor_links(buttons.sflames.state)
		draw_sectionbutton_icon(130, buttons.sflames.y - 5, sect_flames, sect_flames_, 256)
	else
		set_color(0,0,0,0.2)
		draw_quad(0, height-1, 490, 1)
		draw_quad(0, height-58, 491, 57)
		
		draw_shelf()
		-- draw arrow buttons
		if (total_shelves_all2 > 1) then
			set_color(0.0, 0.0, 0.0, 1.0)
			buttons.arrows.prev_shelf.x, buttons.arrows.prev_shelf.y = 25, height-((height-292)/2)
			buttons.arrows.next_shelf.x, buttons.arrows.next_shelf.y = 465, height-((height-292)/2)
			for i, v in pairs(buttons.arrows) do
				if (v == buttons.arrows.prev_shelf or v == buttons.arrows.next_shelf) then
					if (v.state == BTN_HOVER) then
						draw_disk(v.x, v.y, 0, 13, 3, 1, v.angle, 360, 0)
					elseif (v.state == BTN_DOWN) then
						draw_disk(v.x, v.y, 0, 7, 3, 1, v.angle, 360, 0)
					else
						draw_disk(v.x, v.y, 0, 10, 3, 1, v.angle, 360, 0)
					end
				end
			end
		end
	end

	-- The Torishop link
	select_color_links(buttons.torishop.state)
	draw_text("OPEN INVENTORY", buttons.torishop.x, buttons.torishop.y, FONTS.MEDIUM)
	
	-- Timer and Usertext
	draw_timer()
	draw_usertext()

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
		if (buttons.confirm.state == BTN_UP) then 
			set_color(0,0,0,1)
		else
			select_color_links(buttons.confirm.state)
		end
		draw_centered_text("Confirm purchase", buttons.confirm.y, FONTS.MEDIUM)
		if (buttons.cancel.state == BTN_UP) then 
			set_color(0,0,0,1)
		else
			select_color_links(buttons.cancel.state)
		end
		draw_centered_text("Cancel", buttons.cancel.y, FONTS.MEDIUM)
	end
	
	
	-- DQ Hint
	if (current_section == 9) then
		draw_ground_impact(0)
	--[[else
		set_color(1,0,0,1)
		draw_right_text("*", 140, height-32, FONTS.MEDIUM)
		set_color(0,0,0,1)
		draw_right_text("Space to DQ", 10, height-30, FONTS.MEDIUM)
		clear_ground_impact(0)--]]
	end
	
end

function draw_offline()
end

function load_temp()
	local temp = io.open("torishop/flames.cfg", "r")
	if (temp == nil) then
		return
	end
	local section = 1
	local line
	for ln in temp:lines() do
		if string.match(ln, "null") then
			wait_for_update = 1
			return 0 
		elseif string.match(ln, "temp") then
		elseif string.match(ln, "section ") then
			line = string.gsub(ln, "section ", "")
			sections[section].selected_index, sections_[section].selected_index, change_section_first[section] = line:match("([^,]+) ([^,]+) ([^,]+)")
			sections[section].selected_index = tonumber(sections[section].selected_index)
			sections_[section].selected_index = tonumber(sections_[section].selected_index)
			change_section_first[section] = tonumber(change_section_first[section])
			section = section + 1
		else 
			tempinfo.force, tempinfo.relax, tempinfo.primary, tempinfo.secondary, tempinfo.torso, tempinfo.blood, tempinfo.ghost, tempinfo.rhmt, tempinfo.lhmt, tempinfo.rlmt, tempinfo.llmt, tempinfo.dq, tempinfo.grip, tempinfo.timer, tempinfo.text, tempinfo.emote, tempinfo.hair = ln:match("([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+) ([^,]+)")
		end	
	if (tempinfo.force ~= "0" and tempinfo.force ~= 0) then set_joint_force_color(0, tempinfo.force) end
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
	if (tempinfo.dq ~= "0" and tempinfo.dq ~= 0) then set_ground_impact_color(0, tempinfo.dq) end
	if (tempinfo.grip ~= "0" and tempinfo.grip ~= 0) then grip_color = tempinfo.grip add_hook("draw3d", "grip", draw_grip) end
	if (tempinfo.timer ~= "0" and tempinfo.timer ~= 0) then timer_color = tempinfo.timer timer_custom_color = true end
	if (tempinfo.text ~= "0" and tempinfo.text ~= 0) then usertext_color = tempinfo.text usertext_custom_color = true end
	end
	temp:close()
end

-- Main
function close_torishop()
	print("closing torishop...")
	if (player_name ~= "") then
		set_player_default_color()
	end
	if (is_grip == 1) then
		local grip_info = set_grip_info(0,11,0)
		remove_hooks("grip")
		is_grip = 0
	end
	uninit_torishop()
	reset_camera(1)
	cart_reload()
	clear_icons()
	clear_ss_icons()
	
	-- Unload static images and item icons
	if (player_name ~= "") then
		unload_images()
	end
	
	for i, v in pairs(options) do
		set_option(i, v) 
	end
	remove_hooks("error")
	run_cmd("opt effects " .. effects_option)
	run_cmd("opt chat 1")
	run_cmd("opt newshopitem 0")
	run_cmd("clear")
	echo(" ")
	echo(" ")
	echo(" ")
	echo(" ")
	if (tempflag == 0) then
		local temp = io.open("torishop/flames.cfg", "w")
		temp:write("null")
		temp:close()
	end
    remove_hooks("torishop")
end

function init_torishop()
	run_cmd("opt chat 0")
	run_cmd("opt effects 2")
	run_cmd("refreshtorishop")
	
	for i, v in pairs(options) do
		options[i] = get_option(i)
		set_option(i, 0)
	end
	
	-- Ensure Torishop can close properly
	add_hook("leave_game", "torishop", close_torishop)
	
	if (player_name == "") then
		start_torishop_camera(1)
		add_hook("draw2d", "error", errormessage)
	else	
		run_cmd("dl "..player_name)
		start_torishop_camera(15)

	
		-- Prepare the player figure
		init_player()
	

		-- Prepare the item display
		load_data()
		if (data_exists == false) then
			print("Error")	-- print no torishop message
		
			add_hook("draw2d", "torishop", draw_offline)
			return
		end

		load_sections()
		load_items()
		load_buttons()
		load_images()
	
		change_section(0)
		change_shelf(0)
		
		load_temp()
	
		add_hook("draw2d", "torishop", draw_torishop)
		add_hook("mouse_button_down", "torishop", mouse_down)
		add_hook("mouse_button_up", "torishop", mouse_up)
		add_hook("mouse_move", "torishop", mouse_move)
		add_hook("key_down", "torishop", key_down)
		add_hook("key_up", "torishop", key_up)
		
	add_hook("console",	"update_shop", function(s,i)
			if (wait_for_update > 0) then
				if (s == "Download of torishop files complete") then
					local sale_name = 0
				
					data_table = {}
					data_table_usd = {}
					data_table_lines = 0
					data_table_usd_lines = 0
					sections = {}
					
					load_data()
					load_sections()
					load_items()
					
					for i = 1, sections[32].total_items do
						if (sections[32][i].promo == "1") then
							sale_id = sections[32][i].id
							sale = true
							sale_icon = load_texture("../textures/store/items/"..sale_id..".tga")
							break
						end
					end
					wait_for_update = 2
				end
			else
				remove_hooks("update_shop")
			end
		end)
		add_hook("console",	"update_player", function(s,i)
			if (s == "Download complete") then
				get_playerinfo()
				remove_hooks("update_player")
			end
		end)
	end
end


-- Run Torishop
init_torishop()