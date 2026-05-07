--//:SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//:MODULES
local DialogueService = require(ReplicatedStorage.Modules.Packages.DialogueService)

--//:REFERENCES
local remote = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.Dialogue :: UnreliableRemoteEvent
local player = game:GetService("Players").LocalPlayer

--//:EVENTS
remote.OnClientEvent:Connect(function(
	bodyText: string,
	name: string,
	textColor3: Color3?,
	textStrokeColor3: Color3?, 
	textScaled: boolean?, 
	textSize: number?, 
	fontFace: Font?, 
	speed: number?,
	pitch: number?
)
	DialogueService.Speak(
		player,
		bodyText,
		name,
		textColor3,
		textStrokeColor3,
		textScaled,
		textSize,
		fontFace,
		speed,
		pitch
	)
	print("Dialogue received from server") -- Optional: Debugging output
end)