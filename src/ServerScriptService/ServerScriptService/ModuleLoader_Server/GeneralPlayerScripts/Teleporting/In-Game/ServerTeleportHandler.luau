local module = {}

function module:Init()
	local Players = game:GetService("Players")
	local playerConnections = {}

	--	Main function to teleport player on spawn
	local function teleportOnCharacterAdded(character)
		local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart

		local SpawnsFolder = game:GetService("ReplicatedStorage"):WaitForChild("PlayerSpawns") :: Folder
		local PlayerSpawns = SpawnsFolder:GetChildren() :: { BasePart }
		local spawnPart = PlayerSpawns[math.random(1, #PlayerSpawns)] :: BasePart

		hrp.CFrame = spawnPart.CFrame
	end

	local remote = game:GetService("ReplicatedStorage").Remotes_Bindables.Remotes.GeneralPlayer.SpawnRemote :: RemoteEvent

	remote.OnServerEvent:Connect(function(player)
		if player.Character then
			teleportOnCharacterAdded(player.Character)
		end

		if not playerConnections[player] then
			playerConnections[player] = {}
			if not playerConnections[player].CharacterAdded then
				local characterAdded_conn: RBXScriptConnection
				characterAdded_conn = player.CharacterAdded:Connect(teleportOnCharacterAdded)

				playerConnections[player].CharacterAdded = characterAdded_conn
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if playerConnections[player] then
			for _, conn: RBXScriptConnection in pairs(playerConnections[player]) do
				conn:Disconnect()
				conn = nil
			end
			playerConnections[player] = nil
		end
	end)
end

return module
