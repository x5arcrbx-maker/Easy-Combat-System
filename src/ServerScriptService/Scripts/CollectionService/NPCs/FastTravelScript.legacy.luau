--//:SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players 			= game:GetService("Players")

--//:VARIABLES
local vfx_remote: UnreliableRemoteEvent = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.FastTravel:FindFirstChild("FastTravelVFX")
local remote: RemoteEvent = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.FastTravel

--//:MAIN
remote.OnServerEvent:Connect(function(
	player: Player,
	NPC: Model,
	areaToTravelTo: string
)
	--Sanity checks
	if not NPC:IsA("Model") then return end
	if not areaToTravelTo then
		warn("No areaToTravelTo specified for in FastTravel.OnServerEvent for character:" .. NPC.Name)
		return
	end
	
	
	--Destination position (change this to your desired fast travel location)
	local objValue: Instance? = NPC:FindFirstChild(areaToTravelTo)
	if not objValue then --Instance not found
		warn("Instance named (" .. areaToTravelTo .. ") not found within character: " .. NPC.Name)
		return
	elseif not objValue:IsA("ObjectValue") then --Instance found but not an object value
		warn("Instance named (" .. areaToTravelTo .. ") not an ObjectValue for character: " .. NPC.Name)
	elseif not objValue.Value then --No object value within ObjectValue
		warn("ObjectValue.Value is nil for character: " .. NPC.Name .. ". Did you forget to assign an object value?")
		return
	end
	local objPart = objValue.Value --The part which to teleport to
	local destination: Vector3 = objPart.Position + Vector3.new(0, 3, 0) --Add a small offset to avoid clipping

	if player and player.Character then --ensure player and player's character exist
		if player.Character:GetAttribute("InCombat") then return end

		local hrp: Instance? = player.Character:FindFirstChild("HumanoidRootPart")
		if hrp and hrp.Parent == player.Character then hrp.CFrame = CFrame.new(destination) end

		vfx_remote:FireClient(player) --Fire the VFX to the client (covers screen for smooth transition)
	end
end)






--[[ --Old code
for _, character in pairs(CollectionService:GetTagged("FastTravelCharacter")) do -- Iterate through tagged character models
	if not character:IsA("Model") then continue end
	
	
	local torso: BasePart? = character:FindFirstChild("Torso")
	if torso then
		--Destination position (change this to your desired fast travel location)
		local objValue = character:FindFirstChildOfClass("ObjectValue")
		if not objValue then
			warn("No ObjectValue found in character: " .. character.Name)
			continue
		elseif not objValue.Value then
			warn("ObjectValue.Value is nil for character: " .. character.Name)
			continue
		end
		local objPart = objValue.Value --The part which to teleport to
		local destination: Vector3 = objPart.Position + Vector3.new(0, 3, 0) --Add a small offset to avoid clipping

		-- Create a ProximityPrompt if not already present
		local ProximityPart: BasePart = torso
		local prompt: ProximityPrompt = Instance.new("ProximityPrompt")
		
		prompt.ActionText 			 = "Fast Travel to: " .. objPart.Name .. "?"
		prompt.Name 				 = "FastTravel_ProximityPrompt"
		prompt.RequiresLineOfSight   = false
		prompt.MaxActivationDistance = 10
		prompt.MaxIndicatorDistance  = 0
		prompt.HoldDuration 		 = 3
		prompt.Parent 				 = ProximityPart
		prompt.Triggered:Connect(function(player: Player)
			if player and player.Character then
				if player.Character:GetAttribute("InCombat") then return end
				
				local hrp: BasePart = player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then hrp.CFrame = CFrame.new(destination) end
				
				--Fire remote for client-side effects/UI if needed
				if vfx_remote then vfx_remote:FireClient(player) end
			end
		end)
	else 
		warn("No torso found in character model: " .. character.Name) 
	end
end
]]





