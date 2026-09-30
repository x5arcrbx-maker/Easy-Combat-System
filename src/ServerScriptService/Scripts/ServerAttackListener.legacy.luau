-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- MODULES
local modules = ServerScriptService:FindFirstChild("Modules")
-- local hitManager = require(modules:FindFirstChild("HitManager"))
local skillsLibrary = require(modules:FindFirstChild("SkillsLibrary"))

-- REMOTES
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local attackCharacter_remote = remotesFolder:FindFirstChild("CharacterAttack")

-- VARIABLES

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
