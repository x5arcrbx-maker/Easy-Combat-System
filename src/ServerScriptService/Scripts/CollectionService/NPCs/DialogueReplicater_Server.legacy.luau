--//:SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players 			= game:GetService("Players")

--//:MODULES
local DialogueService = require(ReplicatedStorage.Modules.Packages.DialogueService)

--//:REFERENCES
local remote: UnreliableRemoteEvent = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.Dialogue --The remote event for client communication

--//:VARIABLES
local dialogueCharacters: {Instance} = CollectionService:GetTagged("DialogueCharacter")


for _, npc in pairs(dialogueCharacters) do -- Iterate through tagged character models
	if not npc:IsA("Model") then
		warn("Invalid NPC model: " .. npc.Name)
		continue
	end

	local torso = npc:FindFirstChild("Torso") :: BasePart?
	if not torso then
		warn("No torso found in character model: " .. npc.Name)
		continue
	end
	
	local ProximityPart: BasePart? = torso
	local prompt: ProximityPrompt? = ProximityPart:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt") :: ProximityPrompt 
		
		prompt.ActionText 		   	 = "Talk"
		prompt.ObjectText 		   	 = "..."
		prompt.RequiresLineOfSight 	 = false
		prompt.MaxActivationDistance = 10
		prompt.MaxIndicatorDistance  = 0
		prompt.HoldDuration 		 = 0.5
		prompt.Parent				 = ProximityPart
	end --^ Create a ProximityPrompt if not already present

	local dialogue = npc:FindFirstChild("Dialogue") :: Folder?
	if not dialogue then
		warn("No dialogue found in NPC: " .. npc.Name .. "Ensure it's a folder in the NPC")
		continue
	end
	local bodyText: StringValue? 	 	 = dialogue:FindFirstChild("BodyText")
	local textColor3: Color3Value? 	     = dialogue:FindFirstChild("TextColor3")
	local textStrokeColor3: Color3Value? = dialogue:FindFirstChild("TextStrokeColor3")
	local textScaled: BoolValue? 	     = dialogue:FindFirstChild("TextScaled")
	local textSize: NumberValue? 		 = dialogue:FindFirstChild("TextSize")
	local fontFace:StringValue? 		 = dialogue:FindFirstChild("FontFace")
	local speed: NumberValue? 		     = dialogue:FindFirstChild("Speed")
	local pitch: NumberValue? 		     = dialogue:FindFirstChild("Pitch")
	
	if not bodyText then
		warn("No BodyText found in NPC: " .. npc.Name)
		continue
	end --^ Ensure the BodyText is present (the only necessary value for the dialogue to work)
	
	-- Connect the prompt's Triggered event to handle player interaction
	prompt.Triggered:Connect(function(player)
		if player and player.Character then
			remote:FireClient(
				player,
				bodyText.Value,
				npc.Name,
				textColor3.Value,
				textStrokeColor3.Value, 
				textScaled.Value, 
				textSize.Value, 
				Font.new(
					fontFace.Value,
					Enum.FontWeight.Regular,
					Enum.FontStyle.Normal
				), 
				speed.Value,
				pitch.Value
			) -- Fire the remote event to the client with the dialogue data
			print("Dialogue triggered by player: " .. player.Name) -- Optional: Debugging output
		end
	end)
end


