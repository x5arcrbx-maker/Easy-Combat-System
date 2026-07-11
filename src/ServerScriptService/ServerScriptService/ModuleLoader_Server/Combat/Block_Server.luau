local module = {}

function module:Init()
	--//:SERVICES
	local RunService 		= game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")


	--//:REFERENCES
	local blockingEvent_Remote = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.Blocking.BlockingEvent :: RemoteEvent
	local blockingEvent_Bindable  = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.Blocking.BindBlockingEvent :: BindableEvent
	local hitModule_blockingEvent = ReplicatedStorage.Remotes_Bindables.Remotes.PVP.Blocking.hitModule_BlockingEvent :: BindableEvent


	--//:VARIABLES
	local PREVENTION_ATTRIBUTES: {string} = {
		--"Knocked",
		--"Carried",
		--"Gripped",
		"Ragdolled",
		"TrueStunned",
	}
	local characterConnections: {[Model]: {[string]: RBXScriptConnection}} = {}


	--//:CONSTANTS
	local COOLDOWN: number 			= ReplicatedStorage.Values.NumberValues.Combat.Base.Block.CooldownTime.Value
	local GUARDBREAK_Amount: number = ReplicatedStorage.Values.NumberValues.Combat.Base.Block.GuardbreakAmount.Value


	--Cleanup
	local function cleanupConnections(character: Model)
		if characterConnections[character] then
			for _, connection: RBXScriptConnection in pairs(characterConnections[character]) do
				connection:Disconnect()
			end
			characterConnections[character] = nil
		end
	end
	workspace.DescendantRemoving:Connect(function(descendant: Instance)
		if descendant:IsA("Model") and descendant:FindFirstChildOfClass("Humanoid") then
			cleanupConnections(descendant)
		end
	end)


	-- Listen for block start/end from client
	blockingEvent_Remote.OnServerEvent:Connect(function(player, isBlocking: boolean)

		local char: Model? = player.Character
		if not char then return end

		cleanupConnections(char)
		characterConnections[char] = {}

		local heartbeat_Conn: RBXScriptConnection
		local bindBlocking_Conn: RBXScriptConnection

		local blockStartTime: number = 0

	--[[
	for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
		if char:GetAttribute(attribute) then
			-- Force stop blocking
			char:SetAttribute("Blocking", false)

			-- Cleanup
			char:SetAttribute("BlockHits", 0)
			char:SetAttribute("BlockOnCooldown", true)
			task.delay(COOLDOWN, function()
				char:SetAttribute("BlockOnCooldown", false)
			end)
			
			return
		end
	end
	]]

		if isBlocking == true then
			for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
				if char:GetAttribute(attribute) then return end
			end

			blockStartTime = os.clock()
			char:SetAttribute("Blocking", true)

			--print("Blocking started for: " .. player.Name)

			-- Connect the timer logic to RunService.Heartbeat
			heartbeat_Conn = RunService.Heartbeat:Connect(function()
				local actualTime = os.clock() - blockStartTime
				char:SetAttribute("BlockTime", actualTime)
			end)
			characterConnections[char].Heartbeat = heartbeat_Conn

			char:SetAttribute("Blocking", true)
			bindBlocking_Conn = hitModule_blockingEvent.Event:Connect(function(blockHits: number?, blocking: boolean?)
				if (blockHits and blockHits >= GUARDBREAK_Amount) and blocking then
					char:SetAttribute("Blocking", false)

					cleanupConnections(char)
				end
			end)
			characterConnections[char].Bind = bindBlocking_Conn
		else
			char:SetAttribute("Blocking", false)
			char:SetAttribute("BlockHits", 0)
			char:SetAttribute("BlockTime", 0)

			char:SetAttribute("BlockOnCooldown", true)
			task.delay(COOLDOWN, function()
				char:SetAttribute("BlockOnCooldown", false)
			end)

			cleanupConnections(char)
		end
	end)

	-- Listen for bindable blocking event from NPCs
	blockingEvent_Bindable.Event:Connect(function(npc: Model, isBlocking: boolean)

		local char = npc

		cleanupConnections(char)
		characterConnections[char] = {}

		local heartbeat_Conn: RBXScriptConnection
		local bindBlocking_Conn: RBXScriptConnection

		local blockStartTime: number = 0

	--[[
	for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
		if char:GetAttribute(attribute) then
			-- Force stop blocking
			char:SetAttribute("Blocking", false)

			-- Cleanup
			char:SetAttribute("BlockHits", 0)
			char:SetAttribute("BlockOnCooldown", true)
			task.delay(COOLDOWN, function()
				char:SetAttribute("BlockOnCooldown", false)
			end)
			
			return
		end
	end
	]]

		if isBlocking == true then
			for _, attribute in pairs(PREVENTION_ATTRIBUTES) do
				if char:GetAttribute(attribute) then return end
			end

			blockStartTime = os.clock()
			char:SetAttribute("Blocking", true)

			--print("Blocking started for: " .. player.Name)

			-- Connect the timer logic to RunService.Heartbeat
			heartbeat_Conn = RunService.Heartbeat:Connect(function()
				local actualTime = os.clock() - blockStartTime
				char:SetAttribute("BlockTime", actualTime)
			end)
			characterConnections[char].Heartbeat = heartbeat_Conn

			char:SetAttribute("Blocking", true)
			bindBlocking_Conn = hitModule_blockingEvent.Event:Connect(function(blockHits: number, blocking: boolean?)
				if (blockHits and blockHits >= GUARDBREAK_Amount) and blocking then
					char:SetAttribute("Blocking", false)

					cleanupConnections(char)
				end
			end)
			characterConnections[char].Bind = bindBlocking_Conn

		else
			char:SetAttribute("Blocking", false)
			--print("Blocking ended")
			char:SetAttribute("BlockHits", 0)
			--print("BlockHits reset to 0")

			char:SetAttribute("BlockOnCooldown", true)
			task.delay(COOLDOWN, function()
				char:SetAttribute("BlockOnCooldown", false)
			end)

			cleanupConnections(char)
		end
	end)
end

return module
