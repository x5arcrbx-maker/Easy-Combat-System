-- SERVICES
local Players = game:GetService("Players")

-- VARIABLES
local connections = { players = {} }
local states = {}

-- FUNCTIONS
local function characterAdded(character)
	states[character] = {}
end

-- EVENTS --
Players.PlayerAdded:Connect(function(player)
	-- print("Player added:", player.Name)
	local playerId = player.UserId
	local playerConnections = connections.players[playerId]
	if playerConnections then
		if playerConnections.CharacterAdded then
			playerConnections.CharacterAdded:Disconnect()
			playerConnections.CharacterAdded = nil
		end
	else
		connections.players[playerId] = {}
		playerConnections = connections.players[playerId]
	end

	local characterAdded_conn: RBXScriptConnection?
	characterAdded_conn = player.CharacterAdded:Connect(characterAdded)

	playerConnections.CharacterAdded = characterAdded_conn
end)

Players.PlayerRemoving:Connect(function(player)
	-- print("Player removed:", player.Name)
	local playerId = player.UserId
	local playerConnections = connections.players[playerId]
	if playerConnections then
		if playerConnections.CharacterAdded then
			playerConnections.CharacterAdded:Disconnect()
			playerConnections.CharacterAdded = nil
		end
		connections.players[playerId] = nil
	end
end)

local StunHandler = {}

function StunHandler:Apply(character: Model, stunTime: number, stunType: string)
	local ok, err = pcall(function()
		local arguments = {
			Model = { character },
			number = { stunTime },
			string = { stunType },
		}

		for argName, arg in ipairs(arguments.Model) do
			if arg == nil then
				warn("One or more arguments (type Model) are nil. Cannot apply stun.")
				warn(string.format("Name (%*) : Value (%*)", argName, arg))
				return
			elseif not arg:IsA("Model") then
				warn("One or more arguments (type Model) are not of type Model. Cannot apply stun.")
				warn(string.format("Name (%*) : Value (%*)", argName, arg))
				return
			end
		end

		for argName, arg in ipairs(arguments.number) do
			if arg == nil then
				warn("One or more arguments (type number) are nil. Cannot apply stun.")
				warn(string.format("Name (%*) : Value (%*)", argName, arg))
				return
			elseif type(arg) ~= "number" then
				warn("One or more arguments (type number) are not of type number. Cannot apply stun.")
				warn(string.format("Name (%*) : Value (%*)", argName, arg))
				return
			end
		end

		for argName, arg in ipairs(arguments.string) do
			if arg == nil then
				warn("One or more arguments (type string) are nil. Cannot apply stun.")
				warn(string.format("Name (%*) : Value (%*)", argName, arg))
				return
			elseif type(arg) ~= "string" then
				warn("One or more arguments (type string) are not of type string. Cannot apply stun.")
				warn(string.format("Name (%*) : Value (%*)", argName, arg))
				return
			end
		end

		if not states[character] then
			-- print("Initializing states table for character:", character.Name)
			states[character] = {}
		end

		if states[character][stunType] then
			task.cancel(states[character][stunType])
			states[character][stunType] = task.delay(stunTime, function()
				character:SetAttribute(stunType, false)
				-- print("Stun expired for character:", character.Name, "stun type:", stunType)
				states[character][stunType] = nil
			end)
		else
			character:SetAttribute(stunType, true)
			states[character][stunType] = task.delay(stunTime, function()
				character:SetAttribute(stunType, false)
				-- print("Stun expired for character:", character.Name, "stun type:", stunType)
				states[character][stunType] = nil
			end)
		end
	end)
	if not ok then
		warn("Error applying stun:", err)
	end
end

return StunHandler
