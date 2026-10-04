-- SERVICES
local CollectionService = game:GetService("CollectionService")

-- VARIABLES
local spawners = CollectionService:GetTagged("Spawner")

-- MODULES
local NpcService = require(game:GetService("ServerScriptService").Services.NpcService)

local spawnerFunctions = {
	["RegularDummy_Spawner"] = function(spawner: BasePart)
		NpcService:SpawnNpc("Regular", "Dummy", "RegularDummy", spawner)
	end,
}

for _, spawner: BasePart in pairs(spawners) do
	if not spawner:IsA("BasePart") then
		warn(string.format("Spawner %s is not a basepart. Continuing iteration", spawner.Name))
	end
	local existingSpawnerFunction = spawnerFunctions[spawner.Name]
	if existingSpawnerFunction then
		existingSpawnerFunction(spawner)
	end
end
