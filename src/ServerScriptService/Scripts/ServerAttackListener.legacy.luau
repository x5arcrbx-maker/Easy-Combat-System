-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- VARIABLES
local SSS_Modules = ServerScriptService:FindFirstChild("Modules")
local RS_Modules = ReplicatedStorage:FindFirstChild("Modules")

-- MODULES
local allowedToAttack = require(RS_Modules:FindFirstChild("AllowedToAttack"))
local skillsLibrary = require(SSS_Modules:FindFirstChild("SkillsLibrary"))

-- REMOTES
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local attackCharacter_remote = remotesFolder:FindFirstChild("CharacterAttack")

-- FUNCTIONS
local function attackExistsInLibrary(attack: string): boolean
	return skillsLibrary.standardAttacks[attack] ~= nil
end

attackCharacter_remote.OnServerEvent:Connect(function(player, attack: string)
	if not attackExistsInLibrary(attack) then
		warn("Invalid attack:", attack, "from player:", player.Name)
		return
	end

	local character = player.Character :: Model?
	if character then
		if not allowedToAttack(character) then
			-- warn("Player is stunned or incapacitated:", player.Name)
			return
		end
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
		if rootPart then
			skillsLibrary.standardAttacks[attack].trigger(character, rootPart)
		else
			warn("Root part not found for player:", player.Name)
		end
	else
		warn("Invalid attack type or character not found for player:", player.Name)
	end
end)
