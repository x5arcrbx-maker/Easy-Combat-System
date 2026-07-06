local module = {}

function module:Init()
	--//:SERVICES
	local CollectionService = game:GetService("CollectionService")
	local Players = game:GetService("Players")
	local ServerStorage = game:GetService("ServerStorage")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	--//:VARIABLES
	local remote = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.GiveMoveset :: RemoteEvent
	local SkillsetsTools = ServerStorage.Tools["Skillsets(TOOLS)"] :: Folder
	local SkillsetsValues = ReplicatedStorage.Values.Mixed.Skillsets :: Folder
	local OnCooldown = {}

	--//:FUNCTIONS

	--Gives skillset to player
	--	(handles checking for skills in inventory
	--	and removing before giving,
	--	giving skills, giving possible weapon)
	local function giveSkillset(SkillsetGiver: Instance, character: Model, player: Player)
		local earlyAccess = SkillsetGiver:FindFirstChild("Early Access?") :: BoolValue
		if earlyAccess and earlyAccess.Value then
			local hasEarlyAccess = player:GetAttribute("EarlyAccess")
			if not hasEarlyAccess then
				return
			end
		end

		local Category = SkillsetGiver:FindFirstChild("Category?") :: StringValue
		local Name = SkillsetGiver:FindFirstChild("Skillset?") :: StringValue

		if Category and Name then
			local foundCategory = SkillsetsTools:FindFirstChild(Category.Value)
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
					if
						item:IsA("Tool")
						and (CollectionService:HasTag(item, "Skill") or CollectionService:HasTag(item, "SubSkill"))
					then
						item:Destroy()
					end
				end
				for _, item in pairs(character:GetChildren()) do -- Remove weapons in character
					if
						item:IsA("Tool")
						and (CollectionService:HasTag(item, "Skill") or CollectionService:HasTag(item, "SubSkill"))
					then
						item:Destroy()
					end
				end
				--------------------------------------------------------------
				--Iterate through foundSkillset and clone each child individually (each skill)
				for _, item in pairs(foundSkillset:GetChildren()) do
					local itemClone = item:Clone()
					itemClone.Parent = backpack
				end

				--Add randomized subskills to the player's backpack
				local subskillsFolder = SkillsetsTools.Subskills
				for i, tool in pairs(subskillsFolder.General:GetChildren()) do
					if i > 2 then --no more than 2 skills
						break
					else
						local toolClone = tool:Clone()
						toolClone.Parent = backpack
					end
				end

				--If Category is "Breaths", give the player a katana, otherwise remove katana
				if Category.Value == "Breaths" then
					character:SetAttribute("WeaponIsEquipped", false)
					character:SetAttribute("Weapon", "Katana")

					local equippedWeapon = character:FindFirstChild("Weapon")
					if equippedWeapon then --Destroy existing weapon
						equippedWeapon:Destroy()
					end
				else
					character:SetAttribute("WeaponIsEquipped", false)
					character:SetAttribute("Weapon", "None")

					local equippedWeapon = character:FindFirstChild("Weapon")
					if equippedWeapon then --Destroy existing weapon
						equippedWeapon:Destroy()
					end
				end

				bindable:Fire(character)
			else
				warn("Skillset '" .. Name.Value .. "' not found in category '" .. Category.Value .. "'")
			end
		else
			warn("SkillsetGiver is missing 'Category?' or 'Skillset?' value objects")
		end
	end

	remote.OnServerEvent:Connect(function(player: Player, iconName: string?)
		if not iconName then
			if game:GetService("RunService"):IsStudio() then
				warn("Server - Icon name is nil")
			end
			return
		end
		local character: Model? = player.Character

		--Check if the player has a character and that it is a Model with a Humanoid,
		--	and that the player is not in combat or using an attack
		if
			character
			and character:IsA("Model")
			and character:FindFirstChildOfClass("Humanoid")
			and not (character:GetAttribute("InCombat") or character:GetAttribute("UsingAttack"))
		then
			local icon = SkillsetsValues:FindFirstChild(iconName)
			if not icon then
				if game:GetService("RunService"):IsStudio() then
					warn("Icon '" .. iconName .. "' not found in SkillsetsValues")
				end
				return
			end
			giveSkillset(icon, character, player)
		end
	end)
end

return module
