local DataManager = {}

--//:SERVICES
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--//:VARIABLES
local updateDataRemote = ReplicatedStorage.Remotes_Bindables.Remotes.Data.UpdateData :: UnreliableRemoteEvent

------------------------------------------------------------------------
-- MAIN LOGIC -- MAIN LOGIC -- MAIN LOGIC -- MAIN LOGIC -- MAIN LOGIC --
------------------------------------------------------------------------

-- Store profiles from ProfileStore
DataManager.Profiles = {}
local function GetProfile(player: Player?)
	if not player then
		if RunService:IsStudio() then
			error("GetProfile: Player is nil. Did you forget the [player] argument?", 2)
		else
			warn("GetProfile: Player is nil. Did you forget the [player] argument?")
		end
		return nil
	end
	return DataManager.Profiles[player]
end

--Updates the yen amount for a player (Only adds or subtracts, does NOT set/override)
function DataManager.UpdateYen(player: Player, value: number)
	local profile = GetProfile(player)
	if not profile then
		warn("Profile not found for (" .. player.Name .. ") in DataManager.UpdateYen")
		return
	end
	if typeof(value) ~= "number" then
		return
	end

	--All checks passed, update data
	local yenMultiplier = player:GetAttribute("YenMultiplier") or 1
	profile.Data.Yen += (value * yenMultiplier)

	local leaderstats: Folder? = player:FindFirstChild("leaderstats")
	if not leaderstats then
		warn("Leaderstats not found for (" .. player.Name .. "). Make sure it's a Folder in the player.")
		return
	end
	local yen = leaderstats:FindFirstChild("Yen") :: NumberValue
	if not yen then
		warn("Yen not found for (" .. player.Name .. "). Make sure it's a NumberValue in leaderstats.")
		return
	end
	yen.Value = profile.Data.Yen

	updateDataRemote:FireClient(player, "Yen", profile.Data.Yen)
end
-----------------------------------

---------------------------------------
--|		EXP DATA and SCALING		|--
---------------------------------------

--Does math for updating damage multiplier by level
function DataManager:GetDamageMultiplier(level: number): number
	return 1 + (level * 0.025)
end

--Does math for updating defense multiplier by level
function DataManager:GetDefenseMultiplier(level: number): number
	return 1 + (level * 0.025)
end

--Variables
local BASE_XP: number = 100
local XP_GROWTH: number = 1.25
local VFX_DURATION: number = 1.5
DataManager.MaxLevel = 1000

--Math for leveling system (progressive XP baseline growth)
function DataManager:GetXPForNextLevel(level: number): number
	return math.floor(BASE_XP * (level ^ XP_GROWTH))
end

--Updates the experience data for a player
function DataManager.UpdateExperience(player: Player, value: number)
	local profile = GetProfile(player)
	if not profile then
		warn("Profile not found for (" .. player.Name .. ") in DataManager.UpdateExperience")
		return
	end
	if typeof(value) ~= "number" then
		return
	end

	--Check if max level
	if profile.Data.Level >= DataManager.MaxLevel then
		return
	end

	--All checks passed, update data
	profile.Data.Experience += value

	local character = player.Character
	if not character then
		warn("Character not found for (" .. player.Name .. ").")
		return
	end

	local level: NumberValue? = player:FindFirstChild("Level")
	if not level then
		warn("Level not found for (" .. player.Name .. "). Make sure it's a NumberValue in (player).")
		return
	end

	local exp: NumberValue? = level:FindFirstChild("Experience")
	if not exp then
		warn("Experience not found for (" .. player.Name .. "). Make sure it's a NumberValue in (player.Level).")
		return
	end
	exp.Value = profile.Data.Experience

	local threshold: NumberValue? = level:FindFirstChild("Threshold")
	if not threshold then
		warn("Threshold not found for (" .. player.Name .. "). Make sure it's a NumberValue in (player.Level).")
		return
	end

	local dmgMultiplier: NumberValue? = character:FindFirstChild("DamageMultiplier")
	if not dmgMultiplier then
		warn("DamageMultiplier not found for (" .. player.Name .. "). Make sure it's a NumberValue in (character).")
		return
	end

	local defenseMultiplier: NumberValue? = character:FindFirstChild("DefenseMultiplier")
	if not defenseMultiplier then
		warn("HealthMultiplier not found for (" .. player.Name .. "). Make sure it's a NumberValue in (character).")
		return
	end

	-- LEVEL-UP CHECK
	while profile.Data.Experience >= DataManager:GetXPForNextLevel(profile.Data.Level) do
		profile.Data.Experience -= DataManager:GetXPForNextLevel(profile.Data.Level)
		profile.Data.Level += 1

		level.Value = profile.Data.Level
		threshold.Value = DataManager:GetXPForNextLevel(profile.Data.Level)
		dmgMultiplier.Value = DataManager:GetDamageMultiplier(level.Value)
		defenseMultiplier.Value = DataManager:GetDefenseMultiplier(level.Value)

		print("Player: (" .. player.Name .. ") has leveled up to Level [" .. profile.Data.Level .. "]!")

		--VFX
		character = player.Character
		if not character then
			return
		end
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end

		local function playVFX()
			local Vfx: Folder? = ReplicatedStorage.FX.VFX.GeneralPlayer.LevelUp:GetChildren()
			if not Vfx then
				return
			end

			for _, v in pairs(Vfx) do
				if hrp:FindFirstChildOfClass("Attachment") then
					local attachment = hrp:FindFirstChildOfClass("Attachment")
					local clone = v:Clone()

					clone.Parent = attachment
					Debris:AddItem(clone, VFX_DURATION)
					if clone:IsA("ParticleEmitter") and clone:GetAttribute("Emit") then
						clone.Enabled = false
						clone:Emit(1)
					elseif clone:IsA("ParticleEmitter") then
						clone.Enabled = false
						clone:Emit(10)
					end
				end
			end
		end
		playVFX()

		--SFX
		local function playSFX()
			local Sfx: Sound? = ReplicatedStorage.FX.SFX.GeneralPlayer.LevelUp
			if not Sfx then
				return
			end

			Sfx = Sfx:Clone()
			Sfx.Parent = hrp
			Sfx:Play()
			Debris:AddItem(Sfx, Sfx.TimeLength)
		end
		playSFX()
	end

	updateDataRemote:FireClient(player, "Experience", profile.Data.Experience)
	updateDataRemote:FireClient(player, "Level", profile.Data.Level)
end

---------------------------------------

--Updates the rank for a player
function DataManager.UpdateRank(player: Player, value: string)
	local profile = GetProfile(player)
	if not profile then
		warn("Profile not found for (" .. player.Name .. ") in DataManager.UpdateRank")
		return
	end
	if typeof(value) ~= "string" then
		return
	end

	--All checks passed, update data
	profile.Data.Rank = value

	local leaderstats: Folder? = player:FindFirstChild("leaderstats")
	if not leaderstats then
		warn(
			"DataManager.UpdateRank: Leaderstats not found for ("
				.. player.Name
				.. "). Make sure it's a Folder in (player)."
		)
		return
	end

	leaderstats.Rank.Value = profile.Data.Rank
	updateDataRemote:FireClient(player, "Rank", profile.Data.Rank)
end

--Update the race for a player
function DataManager.UpdateRace(player: Player, value: string)
	local profile = GetProfile(player)
	if not profile then
		warn("Profile not found for (" .. player.Name .. ") in DataManager.UpdateRace")
		return
	end
	if typeof(value) ~= "string" then
		return
	end

	--All checks passed, update data
	profile.Data.Race = value
end

--Adds tool names to profile.Data.Inventory to ensure tools are saved.
function DataManager.UpdateInventory(player: Player)
	local profile = GetProfile(player)
	if not profile then
		warn("Profile not found for (" .. player.Name .. ") in DataManager.UpdateInventory")
		return
	end
	local character: Model? = player.Character
	if not character then
		warn("Character not found for (" .. player.Name .. ") in DataManager.UpdateInventory")
		return
	end

	--All checks passed, update data
	local inventory: { string } = {} -- Create table to store tool names

	-- Iterate through character and player.Backpack for tools
	-- Ensure v:IsA("Tool"), if so then insert into inventory table
	for _, v: Instance in pairs(character:GetChildren()) do --Find tools in the character
		if v:IsA("Tool") then
			table.insert(inventory, v.Name)
		end
	end
	for _, v: Instance in pairs(player.Backpack:GetChildren()) do --Find tools in the player.Backpack
		if v:IsA("Tool") then
			table.insert(inventory, v.Name)
		end
	end

	-- Iterate through inventory table
	for _, v: string in pairs(inventory) do --What's in inventory table, but NOT in profile.Data.Inventory?
		if not table.find(profile.Data.Inventory, v) then
			table.insert(profile.Data.Inventory, v)
		end --^ if v is NOT found in profile.Data.Inventory, insert into profile.Data.Inventory
	end
	for _, v: string in pairs(profile.Data.Inventory) do --What's in profile.Data.Inventory, but NOT in inventory table?
		if not table.find(inventory, v) then
			table.remove(profile.Data.Inventory, table.find(profile.Data.Inventory, v))
		end --^ if v is NOT in inventory table, remove from profile.Data.Inventory
	end
end

function DataManager.UpdateWeapon(player: Player, value: string)
	local profile = GetProfile(player)
	if not profile then
		warn("Profile not found for (" .. player.Name .. ") in DataManager.UpdateQuest")
		return
	end
	if typeof(value) ~= "string" then
		return
	end

	profile.Data.Weapon = value
end

function DataManager.UpdateQuest(player: Player, value: string)
	local profile = GetProfile(player)
	if not profile then
		warn("Profile not found for (" .. player.Name .. ") in DataManager.UpdateQuest")
		return
	end
	if typeof(value) ~= "string" then
		return
	end

	local quests = profile.Data.Quests
	for _, quest in pairs(quests) do
		if quest.Name == value then
			return
		end
	end

	--All checks passed, update data
end

function DataManager.UpdateKills(player: Player, value: number, settingValue: boolean?)
	local profile = GetProfile(player)
	if not profile then
		warn("Profile not found for (" .. player.Name .. ") in DataManager.UpdateKills")
		return
	end
	if typeof(value) ~= "number" then
		return
	end

	--All checks passed, update data
	if settingValue then
		profile.Data.Kills = value
	else
		profile.Data.Kills += value
	end

	local leaderstats: Folder? = player:FindFirstChild("leaderstats")
	if not leaderstats then
		warn(
			"DataManager.UpdateKills: Leaderstats not found for ("
				.. player.Name
				.. "). Make sure it's a Folder in (player)."
		)
		return
	end

	leaderstats.Kills.Value = profile.Data.Kills
	-- updateDataRemote:FireClient(player, "Rank", profile.Data.Rank)
end

--[[
--function DataManager.ChangeHotbarOrder(player: Player, order: number)
--	local profile = GetProfile()
--	if not profile then
--		return
--	end
--	local currentHotbarOrder = {
--		1,
--		2,
--		3,
--		4,
--		5,
--		6,
--		7,
--		8,
--		9,
--		10
--	}
--	for i, tool: Tool in ipairs(player.Backpack:GetChildren()) do
--		if i >= 1 and i <= 10 then
--			currentHotbarOrder[i] = tool.Name
--		end
--	end
--	profile.Data.HotbarOrder = currentHotbarOrder
	
--	print(currentHotbarOrder)
--end
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
]]

return DataManager
