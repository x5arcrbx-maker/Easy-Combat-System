local module = {}

function module:Init()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local respawnPlayer = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.RespawnPlayer :: RemoteEvent
	local spawnSound = script:FindFirstChildOfClass("Sound") :: Sound

	respawnPlayer.OnServerEvent:Connect(function(player: Player)
		if player and player.Character then
			player.CharacterAdded:Once(function()
				local character = player.Character
				local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

				local playerSpawns = ReplicatedStorage.PlayerSpawns
				local spawnLocations = playerSpawns:GetChildren()
				local randomSpawn = spawnLocations[math.random(1, #spawnLocations)]
				humanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 5, 0) --Prevent clipping by offsetting by 5 studs up
				
				task.wait() --Wait for character to load and finish teleporting
				if spawnSound then
					local cloneSound = spawnSound:Clone()
					cloneSound.Parent = humanoidRootPart
					cloneSound:Play()
					game:GetService("Debris"):AddItem(cloneSound, cloneSound.TimeLength + 1) --Destroy sound after it's done playing
				end
			end)
			player:LoadCharacterAsync() --Respawn player
		end -- player/character safeguard
	end) --End of respawnPlayer.OnServerEvent

end

return module
