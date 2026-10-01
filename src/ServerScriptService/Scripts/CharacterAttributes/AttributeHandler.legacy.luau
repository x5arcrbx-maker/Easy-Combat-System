-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- VARIABLES
local connections = {
	players = {},
}
--
local attributesModule = ReplicatedStorage.Tables.Dictionaries.Attributes

-- MODULES
local attributes = require(attributesModule)

-- FUNCTIONS
local function addCharacterAttributes(character)
	for _, category1 in pairs(attributes) do
		for _, category2 in pairs(category1) do
			for attributeName, value in pairs(category2) do
				if not character:GetAttribute(attributeName) then
					character:SetAttribute(attributeName, value)
				end
			end
		end
	end
end

-- Code --
Players.PlayerAdded:Connect(function(player)
	local playerId = player.UserId
	if connections.players[playerId] then
		connections.players[playerId]:Disconnect()
		connections.players[playerId] = nil
	end

	local characterAdded_conn: RBXScriptConnection?
	characterAdded_conn = player.CharacterAdded:Connect(addCharacterAttributes)
	if player.Character then
		addCharacterAttributes(player.Character)
	end

	connections.players[player.UserId] = characterAdded_conn
end)

Players.PlayerRemoving:Connect(function(player)
	local playerId = player.UserId
	if connections.players[playerId] then
		connections.players[playerId]:Disconnect()
		connections.players[playerId] = nil
	end
end)

local function initializeExistingPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local playerId = player.UserId
		if not connections.players[playerId] then
			local characterAdded_conn: RBXScriptConnection?
			characterAdded_conn = player.CharacterAdded:Connect(addCharacterAttributes)
			if player.Character then
				addCharacterAttributes(player.Character)
			end
			connections.players[player.UserId] = characterAdded_conn
		end
	end
end
initializeExistingPlayers()

local function initializeExistingNpcs()
	local NpcsFolder = workspace:FindFirstChild("NPCs")
	if not NpcsFolder then
		warn("NPCs folder not found in workspace. Skipping NPC initialization.")
		return
	end

	for _, npc in ipairs(NpcsFolder:GetChildren()) do
		if npc:IsA("Model") and npc:FindFirstChildOfClass("Humanoid") then
			addCharacterAttributes(npc)
		end
	end
end
initializeExistingNpcs()
