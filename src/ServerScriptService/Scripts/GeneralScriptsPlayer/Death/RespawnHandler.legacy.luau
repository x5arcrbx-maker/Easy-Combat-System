local ReplicatedStorage = game:GetService("ReplicatedStorage")
local respawnPlayer = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.RespawnPlayer :: RemoteEvent


respawnPlayer.OnServerEvent:Connect(function(player: Player)
	if player and player.Character then
		player.CharacterAdded:Once(function()
			local character = player.Character
			local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

			local playerSpawns = workspace.PlayerSpawns
			local spawnLocations = playerSpawns:GetChildren()
			local randomSpawn = spawnLocations[ math.random(1, #spawnLocations) ]
			humanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 5, 0) --Prevent clipping by offsetting by 5 studs up
		end)
		player:LoadCharacterAsync() --Respawn player
	end -- player/character safeguard
end) --End of respawnPlayer.OnServerEvent
