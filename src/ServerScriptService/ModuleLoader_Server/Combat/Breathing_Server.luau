local module = {}

function module:Init()
	--//:SERVICES
	local RunService 		= game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players 			= game:GetService("Players")

	--//:REFERENCES
	local breathing_remote = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.BreathingBar :: RemoteEvent


	--//:VARIABLES
	local PREVENTION_ATTRIBUTES: {string} = {
		"Knocked",
		"Carried",
		"Gripped",
		"TrueStunned",
		"Ragdolled",

		"Stunned",
		"Blocking",
		"UsingAttack",
	}
	local connections: {[Model]: {RBXScriptConnection?}} = {}
	setmetatable(connections, {__mode = "k"}) --when character is gone, memory is freed

	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			connections[character] = {}
		end)
	end)

	--//FUNCTIONS//

	--Handles disconnecting heartbeat connection in character connections table.
	local function cancelBreathing(character: Model)
		local characterConnections = connections[character]
		if not characterConnections then return end

		if characterConnections.Heartbeat then
			characterConnections.Heartbeat:Disconnect()
			characterConnections.Heartbeat = nil
		end
	end

	--Cancels breathing if character has any prevention attributes true.
	local function checkPreventionAttributes(character: Model): boolean
		for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
			if character:GetAttribute(attribute) then
				return false
			end
		end
		return true
	end

	--Handles math for breathing bar, while assuring it doesn't go above 100.
	local function breathingBar_math(character: Model): boolean
		local currentBreathingAmount = character:GetAttribute("BreathingBar")
		if not currentBreathingAmount then return false end


		if (currentBreathingAmount + 1.65) > 100 then
			character:SetAttribute("BreathingBar", 100)
			return false
		else
			character:SetAttribute("BreathingBar", currentBreathingAmount + 1.1)
			return true
		end
	end

	--------------

	-- Listen for breathing start/end from client
	breathing_remote.OnServerEvent:Connect(function(player, isBreathing: boolean)
		local character = player.Character
		local characterConnections = connections[character]

		for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
			if character:GetAttribute(attribute) then
				cancelBreathing()
				return
			end
		end

		if isBreathing == true then
			if characterConnections.Heartbeat then return end
			-- Connect the timer logic to RunService.Heartbeat
			local heartbeat_Conn: RBXScriptConnection
			heartbeat_Conn = RunService.Heartbeat:Connect(function()
				if not checkPreventionAttributes(character) or not breathingBar_math(character) then
					cancelBreathing()
				end
			end)

			characterConnections.Heartbeat = heartbeat_Conn
		else
			cancelBreathing(character)
		end
	end)

end

return module
