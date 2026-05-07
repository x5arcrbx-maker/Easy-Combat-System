--Services
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

--Variables
local collisionGroup = "Players"
local collisionGroup2 = "NPCs"

-- Register collision groups if they don't exist
pcall(function() PhysicsService:RegisterCollisionGroup(collisionGroup) end)
pcall(function() PhysicsService:RegisterCollisionGroup(collisionGroup2) end)

-- Recursively set collision group for all BaseParts in a model
local function setCollisionGroupRecursive(model, groupName) --Just sets all baseparts in model to the collision group.
	for k, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = groupName
		end
	end
end

local function onCharacter(character)
	setCollisionGroupRecursive(character, collisionGroup)
	-- Listen for new BaseParts added to the character
	character.DescendantAdded:Connect(function(desc)
		if desc:IsA("BasePart") then
			desc.CollisionGroup = collisionGroup
		end
	end)
end

local function onNPC(npc)
	setCollisionGroupRecursive(npc, collisionGroup2)
	-- Listen for new BaseParts added to the character
	npc.DescendantAdded:Connect(function(desc)
		if desc:IsA("BasePart") then
			desc.CollisionGroup = collisionGroup2
		end
	end)
end

-- Set collision group for new players
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacter)
end)

-- Set collision group for existing player characters
for k, player in Players:GetPlayers() do
	if player.Character then
		onCharacter(player.Character)
	end
end

-- Set collision group for existing NPCs
for k, npc in workspace:GetDescendants() do
	if npc:IsA("Model") and npc:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(npc) then
		onNPC(npc)
	end
end

-- Set collision group for new NPCs (anywhere in workspace)
workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("Model") and desc:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(desc) then
		onNPC(desc)
	end
end)

