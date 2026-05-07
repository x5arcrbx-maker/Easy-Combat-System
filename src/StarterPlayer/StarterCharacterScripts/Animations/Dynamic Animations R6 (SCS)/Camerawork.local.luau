-- Camerawork
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players 			= game:GetService("Players")
local RunService 		= game:GetService("RunService")

local AnimationSettingsPath = ReplicatedStorage.Modules.Packages["Dynamic Animations R6"].AnimationSettings
local AnimationSettings = require(AnimationSettingsPath)

local serverRemote = ReplicatedStorage.Remotes_Bindables.Remotes["Dynamic Animations R6"].OnServer

local player   = Players.LocalPlayer
local char 	   = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid") :: Humanoid
local root     = char:WaitForChild("HumanoidRootPart") :: BasePart
--local head 	   = char:WaitForChild("Head") :: BasePart
local cam      = workspace.CurrentCamera
--cam.CameraSubject = head

local cameraBasedEffectsValue = script.Parent:WaitForChild("CameraBasedEffects")

-- Precompute constants from AnimationSettings for reuse (they may change at runtime; we read each send to be safe)
local function getMovementData()
	local rootCFrame = root.CFrame
	local vel = root.AssemblyLinearVelocity

	local worldMoveDir = Vector3.new(vel.X, 0, vel.Z)
	local moveSpeedCap = 16
	if 
		worldMoveDir.Magnitude > moveSpeedCap 
	then
		worldMoveDir = worldMoveDir.Unit * moveSpeedCap
	end

	local moveDir = rootCFrame:VectorToObjectSpace(worldMoveDir)
	local normalizedMoveDir = moveDir / moveSpeedCap

	local veryNormalizedMoveDir = Vector3.zero
	if 
		moveDir.Magnitude > 0.01 
		and not humanoid.PlatformStand 
		and not humanoid.Sit 
	then
		veryNormalizedMoveDir = moveDir.Unit
	end

	return normalizedMoveDir, veryNormalizedMoveDir
end

-- Throttled send loop (0.1s as requested)
while true do
	-- choose camera CF fallback when camera-based effects aren't allowed
	local camCFrame = cam.CFrame
	if 
		not cameraBasedEffectsValue.Value
		or not AnimationSettings.CameraBasedEffects 
	then
		camCFrame = (root.CFrame * CFrame.new(0, 1.41, 1))
	end

	-- If global InversableCameraBasedEffects is false, we still send the camera; receivers will use AnimationSettings.InversableCameraBasedEffects
	local normalizedMoveDir, veryNormalizedMoveDir = getMovementData()

	-- also send this player's local toggle so others know whether to apply camera-driven rotation for this player
	local cameraBasedFlag = cameraBasedEffectsValue.Value and AnimationSettings.CameraBasedEffects

	-- Fire server (player is automatically included by OnServerEvent)
	serverRemote:FireServer(camCFrame, normalizedMoveDir, veryNormalizedMoveDir, cameraBasedFlag)

	task.wait(0.1)
end
