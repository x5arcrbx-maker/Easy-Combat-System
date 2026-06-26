local module = {}

function module:Init()
	local SimpleWeather = game:GetService("ReplicatedStorage").Modules.Packages.SimpleWeather
	local waitTime = SimpleWeather:GetAttribute("WaitTime") * 60 -- In minutes

	local rarities = {
		["Common"] = 50,
		["Uncommon"] = 25,
		["Rare"] = 14,
		["Epic"] = 9,
		["Legendary"] = 2,
		["Exclusive"] = 1
	}
	local weathers = {
		["Common"] = {
			"Default",
			"Windy"
		},
		["Uncommon"] = {
			"Foggy",
			"Rainy"
		},
		["Rare"] = {
			"FoggyRain",
			"HeavyRain"
		},
		["Epic"] = {
			"Snowy"
		},
		["Legendary"] = {
			"ThunderSnow"
		},
		["Exclusive"] = {
			"BloodMoon"
		}
	}


	--Randomizes weather by chance (see above in rarities and weathers)
	local function randomizeWeather()
		--Chance handling
		local totalChance = 0
		for _, rarity in pairs(rarities) do
			totalChance += rarity
		end
		local randomNumber = math.random(0, totalChance)
		local chosenRarity

		for rarity, chance in pairs(rarities) do
			randomNumber -= chance
			if randomNumber <= 0 then
				chosenRarity = rarity
				break
			end
		end

		--Weather handling (set weather based on result)
		local weatherToSetAs = weathers[chosenRarity][math.random(1, #weathers[chosenRarity])]
		game:GetService("ReplicatedStorage"):SetAttribute("CurrentWeather", weatherToSetAs)
	end
	randomizeWeather() --Initialize weather

	while true do --Change weather after waiting the waitTime
		task.wait(waitTime)
		randomizeWeather()
	end

end

return module
