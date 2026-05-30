--//:SERVICES
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

--//:VARIABLES
local remote = game:GetService("ReplicatedStorage").Remotes_Bindables.Remotes.GeneralPlayer.GiveMoveset
local SkillsetGivers = CollectionService:GetTagged("SkillsetGiver")
local SkillsetsFolder = ServerStorage:WaitForChild("Skillsets(TOOLS)")
local OnCooldown = {}

--//:FUNCTIONS

--	Gives skillset to player
--		(handles checking for skills in inventory
--		and removing before giving,
--		giving skills, giving possible weapon)
local function giveSkillset(SkillsetGiver: Instance, character: Model, player: Player)
	local Category = SkillsetGiver:FindFirstChild("Category?") :: StringValue
	local Name = SkillsetGiver:FindFirstChild("Skillset?") :: StringValue

	if Category and Name then
		local foundCategory = SkillsetsFolder:FindFirstChild(Category.Value)
		if not foundCategory then
			warn("Category '" .. Category.Value .. "' not found in Skillsets folder")
			return
		end
		local foundName = foundCategory:FindFirstChild(Name.Value)
		if not foundName then
			warn("Skillset '" .. Name.Value .. "' not found in category '" .. Category.Value .. "'")
			return
		end
		local foundSkillset = foundName --If we found both category and name, this is our skillset
		if foundSkillset then
			--Check for cooldown
			if OnCooldown[player.UserId] then --On cooldown, do not give skillset
				return
			else --Set cooldown
				OnCooldown[player.UserId] = true
				task.delay(10, function()
					OnCooldown[player.UserId] = nil
				end)
			end

			--Clear existing weapons from player's backpack and character--
			local backpack = player:FindFirstChild("Backpack") --Get player's backpack
			for _, item in pairs(backpack:GetChildren()) do -- Remove weapons in backpack
				if item:IsA("Tool") and not item:HasTag("SubSkill") then
					if CollectionService:HasTag(item, "Skill") then
						item:Destroy()
					end

					if item:GetAttribute("Katana") or item:GetAttribute("Weapon") then
						item:Destroy()
					end
				end
			end
			for _, item in pairs(character:GetChildren()) do -- Remove weapons in character
				if item:IsA("Tool") and not item:HasTag("SubSkill") then
					if CollectionService:HasTag(item, "Skill") then
						item:Destroy()
					end

					if item:GetAttribute("Katana") or item:GetAttribute("Weapon") then
						item:Destroy()
					end
				end
			end
			--------------------------------------------------------------
			--Iterate through foundSkillset and clone each child individually (each skill)
			for _, item in pairs(foundSkillset:GetChildren()) do
				local itemClone = item:Clone()
				itemClone.Parent = backpack
			end
			--If Category is "Breaths", give the player a katana
			if Category.Value == "Breaths" then
				local katana = foundCategory:FindFirstChild("Katana")
				if katana then
					local katanaClone = katana:Clone()
					katanaClone.Parent = backpack
				end
			end
		else
			warn("Skillset '" .. Name.Value .. "' not found in category '" .. Category.Value .. "'")
		end
	else
		warn("SkillsetGiver is missing 'Category?' or 'Skillset?' value objects")
	end
end

local function InitTouchedEvent()
	for _, SkillsetGiver in pairs(SkillsetGivers) do
		SkillsetGiver.Touched:Connect(function(Hit)
			local Character: Model? = Hit.Parent
			if Character and Character:IsA("Model") and Character:FindFirstChildOfClass("Humanoid") then
				if Character:GetAttribute("InCombat") or Character:GetAttribute("UsingAttack") then
					return
				end

				local player = Players:GetPlayerFromCharacter(Character)
				if player then
					giveSkillset(SkillsetGiver, Character, player)
				end
			end
		end)
	end
end
InitTouchedEvent()

remote.OnServerEvent:Connect(function(player: Player, Frame: Frame?)
	if not player or not Frame then
		return
	end

	local Character: Model? = player.Character
	if Character then
		if Character:GetAttribute("InCombat") or Character:GetAttribute("UsingAttack") then
			return
		end

		giveSkillset(Frame, Character, player)
	end
end)
