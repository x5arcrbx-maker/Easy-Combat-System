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

function StunHandler:Apply(
	attacker: Model,
	target: Model,
	stunTime_self: number,
	stunTime_target: number,
	stunType_self: string,
	stunType_target: string
)
	local arguments = {
		Model = { attacker, target },
		number = { stunTime_self, stunTime_target },
		string = { stunType_self, stunType_target },
	}

	for _, arg in ipairs(arguments.Model) do
		if arg == nil then
			warn("One or more arguments (type Model) are nil. Cannot apply stun.")
			return
		elseif not arg:IsA("Model") then
			warn("One or more arguments (type Model) are not of type Model. Cannot apply stun.")
			return
		end
	end

	for _, arg in ipairs(arguments.number) do
		if arg == nil then
			warn("One or more arguments (type number) are nil. Cannot apply stun.")
			return
		elseif type(arg) ~= "number" then
			warn("One or more arguments (type number) are not of type number. Cannot apply stun.")
			return
		end
	end

	for _, arg in ipairs(arguments.string) do
		if arg == nil then
			warn("One or more arguments (type string) are nil. Cannot apply stun.")
			return
		elseif type(arg) ~= "string" then
			warn("One or more arguments (type string) are not of type string. Cannot apply stun.")
			return
		end
	end

	if not states[attacker] then
		states[attacker] = {}
	end
	if not states[target] then
		states[target] = {}
	end

	if states[attacker].Stunned then
		task.cancel(states[attacker].Stunned)
		task.delay(stunTime_self, function()
			attacker:SetAttribute(stunType_self, false)
			states[attacker].Stunned = nil
		end)
	else
		attacker:SetAttribute(stunType_self, true)
		states[attacker].Stunned = task.delay(stunTime_self, function()
			attacker:SetAttribute(stunType_self, false)
			states[attacker].Stunned = nil
		end)
	end

	if states[target].Stunned then
		task.cancel(states[target].Stunned)
		task.delay(stunTime_target, function()
			target:SetAttribute(stunType_target, false)
			states[target].Stunned = nil
		end)
	else
		target:SetAttribute(stunType_target, true)
		states[target].Stunned = task.delay(stunTime_target, function()
			target:SetAttribute(stunType_target, false)
			states[target].Stunned = nil
		end)
	end
end

return StunHandler
