--//:SERVICES
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local NpcService = require(game:GetService("ServerScriptService").Modules.Services.NpcService)

--//;REFERENCES
local NpcFolder: Folder = ServerStorage.NPCs.Regular.Dummy :: Folder
local spawners: Folder? = workspace:FindFirstChild("Spawners")
if not spawners then --Checks if Spawners folder exists
	error("Spawners folder does not exist. Did you forget to create it?")
end


--//:MAIN
for _, npc: Model in pairs(NpcFolder:GetChildren()) do

	local storedSpawns = {}
	local Name = npc.Name

	for _, obj in pairs(spawners:GetChildren()) do
		if string.match(obj.Name, "^" .. Name .. "Spawner") then
			table.insert(storedSpawns, obj)
		end
	end

	if #storedSpawns == 0 then
		warn("(NpcService): No spawner found for", Name)
		continue
	end

	for _, spwn: BasePart in ipairs(storedSpawns) do
		if CollectionService:HasTag(npc, "AttackCharacter") then
			NpcService:SpawnNpc("Regular", "Dummy", Name, spwn, true, true)
		else
			NpcService:SpawnNpc("Regular", "Dummy", Name, spwn)
		end
	end

	task.wait(1)
	
end

