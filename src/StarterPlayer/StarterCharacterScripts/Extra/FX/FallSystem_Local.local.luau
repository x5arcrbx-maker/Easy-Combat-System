--!strict

--// SETTINGS
local MIN_FALL_HEIGHT: number   = 50
local MAX_FALL_FOV: number = 100


--//:SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")


--/:VARIABLES
local player = Players.LocalPlayer :: Player
local character = player.Character or player.CharacterAdded:Wait() :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

local camera = workspace.CurrentCamera :: Camera
--local tweens = {} :: {Tween}
local OutTween: Tween = TweenService:Create(
	camera, 
	TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
	{FieldOfView = MAX_FALL_FOV}
) 
local InTween: Tween = TweenService:Create(
	camera, 
	TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), 
	{FieldOfView = 70}
) 


--//:MAIN
local function onCharacterAdded(character: Model)
	
	local fallStartY: number = 0

	local stateChangedConnection: RBXScriptConnection
	stateChangedConnection = humanoid.StateChanged:Connect(function(
		oldState: Enum.HumanoidStateType, 
		newState: Enum.HumanoidStateType
	)
		if newState == Enum.HumanoidStateType.Freefall then
			--table.insert(tweens, OutTween)
			OutTween:Play()
		elseif oldState == Enum.HumanoidStateType.Freefall 
			and newState ~= Enum.HumanoidStateType.Freefall  then


		end


		if oldState == Enum.HumanoidStateType.Freefall 
			and newState ~= Enum.HumanoidStateType.Freefall 
		then
			OutTween:Cancel()

			InTween:Play()




		end



		if newState == Enum.HumanoidStateType.Freefall then
			fallStartY = rootPart.Position.Y

			OutTween:Play()
		elseif oldState == Enum.HumanoidStateType.Freefall and newState ~= Enum.HumanoidStateType.Freefall then


			if fallDistance >= MIN_FALL_HEIGHT then
				OutTween:Cancel()
				InTween:Play()
			end

		end
	end)

	local heartbeat_conn: RBXScriptConnection
	heartbeat_conn = RunService.Heartbeat:Connect(function()
		local fallEndY: number = rootPart.Position.Y
		local fallDistance: number = fallStartY - fallEndY
		
	end)


end
if character then 
	onCharacterAdded(character) 
else
	player.CharacterAdded:Connect(onCharacterAdded)
end