-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- MODULES
local modules = ServerScriptService:WaitForChild("Modules")
local HitHandler = require(modules:WaitForChild("HitHandler"))

-- REMOTES
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local attackCharacter_remote = remotesFolder:WaitForChild("CharacterAttack")

-- VARIABLES
local lightAtkHitbox: Vector3 = Vector3.new(4, 4, 5)
local heavyAtkHitbox: Vector3 = Vector3.new(7, 7, 8)

-- FUNCTIONS
local function castHitbox(character, cframe: CFrame, hitboxSize: Vector3)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params:AddToFilter(character)
	local new_cframe = cframe * CFrame.new(0, 0, -hitboxSize.Z / 2) --place hitbox infront of character
	local hitParts = workspace:GetPartBoundsInBox(new_cframe, hitboxSize, params)
	if hitParts then
		for _, part in pairs(hitParts) do
			local hitCharacter = part:FindFirstAncestorOfClass("Model")
			if hitCharacter and hitCharacter ~= character then
				HitHandler.TryHit(character, hitCharacter)
			end
		end
	end
end

local standardAttacks = {
	Light = function(character: Model, rootPart: BasePart)
		castHitbox(character, rootPart.CFrame, lightAtkHitbox)
	end,
	Heavy = function(character: Model, rootPart: BasePart)
		castHitbox(character, rootPart.CFrame, heavyAtkHitbox)
	end,
}

attackCharacter_remote.OnServerEvent:Connect(function(player, attackType: string)
	local character = player.Character
	if character and standardAttacks[attackType] then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			standardAttacks[attackType](character, rootPart)
		end
	end
end)
