-- Snowfall script for Xmas 2017

local shaders = get_option("shaders")
local effects = get_option("effects")
local toriPos = get_body_info(0, 0)
local ukePos = get_body_info(1, 0)
local posX, posY, posZ
local setModFirstSkip = false
local modName = false
local loadMod = false
local snowEnabled = false

if (toriPos.pos.x == ukePos.pos.x) then
	posX = toriPos.pos.x
else 
	posX = (toriPos.pos.x + ukePos.pos.x) / 2
end
if (toriPos.pos.y == ukePos.pos.y) then
	posY = toriPos.pos.y
else 
	posY = (toriPos.pos.y + ukePos.pos.y) / 2
end
if (toriPos.pos.z == ukePos.pos.z) then
	posZ = toriPos.pos.z
else 
	posZ = (toriPos.pos.z + ukePos.pos.z) / 2
end

local xMin = posX - 7
local xMax = posX + 10
local yMin = posY - 7
local yMax = posY + 7
local zMin = 0
local zMax = posZ + 5


local christmasMods = { "judofracxmas.tbm", "aikidoxmas.tbm", "abdxmas.tbm", "judoxmas.tbm", "joustingxmas.tbm", "twinswordxmas.tbm", "erthtkv2xmas.tbm", "boxshuxmas.tbm" }
local Snowfall = {}

for i = 0, 200 do 
	local lradius = math.random() / 30
	local snow = {	radius = lradius,
					pos = { x = math.random(xMin, xMax), y = math.random(yMin, yMax), z = math.random(zMin, zMax) },
					speed = lradius - 0.01
				 }
	table.insert(Snowfall, snow)
end

function drawSnow()
	if (modName) then
		for i, v in pairs(christmasMods) do
			if (modName == v) then
				snowEnabled = true
				modName = false
			end
		end
	end
	if (snowEnabled) then
		if (tonumber(shaders) ~= 0 and tonumber(effects) > 1) then
			set_color(1,1,1,1)
			for i,v in pairs(Snowfall) do
				draw_sphere(v.pos.x, v.pos.y, v.pos.z, v.radius)
				v.pos.z = v.pos.z - v.speed
				v.pos.x = v.pos.x - 0.01
				if (v.pos.z < 0) then
					v.pos.z = zMax
					v.pos.x = math.random(xMin, xMax)
				end
			end
		end
	end
end

add_hook("draw3d", "snowfallChristmas", drawSnow)
add_hook("console", "snowfallChristmasCheckReq", function(s,i)
	if (setModFirstSkip) then
		setModFirstSkip = false
		modName = s
		return 1
	end
	if (s == "set mod") then
		return 1
	end
end)
add_hook("new_game", "snowfallChristmas", function() shaders = get_option("shaders") effects = get_option("effects") setModFirstSkip = true loadMod = false snowEnabled = false run_cmd("set mod") end)