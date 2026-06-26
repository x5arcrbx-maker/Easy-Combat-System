return {
	--	NUMBER VALUES	--
	Yen = 0,
	Experience = 0,
	Level = 1,
	
	-- STRING VALUES	--
	Rank = "None",
	Race = "Human",
	Weapon = "None",

	---- ARRAYS / TABLES --
	Gamepasses = {
		EarlyAccess = false,
		Radio = false
	},
	Inventory = {}, --Table containing all item names (strings) in inventory
	Quests = { --Table containing all quests (QuestService)
		[1] = {
			Name = "None",
			Requirements = "N/A",
			Progress = 0, --In percent
			Completed = false,
			Rewards = "N/A",
		},
		--[[
		[2] = {
			Name = "None",
			Requirements = "N/A",
			Progress = 0,
			Completed = false,
			Rewards = "N/A",
		},
		[3] = {
			Name = "None",
			Requirements = "N/A",
			Progress = 0,
			Completed = false,
			Rewards = "N/A",
		},
		]]
	},
}
