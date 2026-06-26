--!strict

--// SETTINGS
local MAX_FALL_FOV: number = 100

--//:SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

--/:VARIABLES
local player = Players.LocalPlayer :: Player
local character = player.Character or player.CharacterAdded:Wait() :: Model
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local _rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

local camera = workspace.CurrentCamera :: Camera

local OutTween: Tween = TweenService:Create(
	camera,
	TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0),
	{ FieldOfView = MAX_FALL_FOV }
)
local InTween: Tween = TweenService:Create(
	camera,
	TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0),
	{ FieldOfView = 70 }
)

--//:MAIN
local function Init()
	humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Freefall then
			InTween:Cancel()
			OutTween:Play()
		elseif oldState == Enum.HumanoidStateType.Freefall then
			OutTween:Cancel()
			InTween:Play()
		end
	end)
end
Init()
