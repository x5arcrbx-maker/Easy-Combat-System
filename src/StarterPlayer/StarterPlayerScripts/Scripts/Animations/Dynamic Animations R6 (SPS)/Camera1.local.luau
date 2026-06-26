-- Camera1 (Client) — mirrors new mainwork for other players
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimationSettingsPath = ReplicatedStorage.Modules.Packages["Dynamic Animations R6"].AnimationSettings
local AnimationSettings = require(AnimationSettingsPath)

local clientRemote = ReplicatedStorage.Remotes_Bindables.Remotes["Dynamic Animations R6"].OnClient

local localPlayer = Players.LocalPlayer
local CameraData = {}

-- Build set of reversible animation IDs for quick lookup
local targetAnimIdSet = {}
local reversableFolder = AnimationSettingsPath.ReversableAnimations
for _, anim in ipairs(reversableFolder:GetChildren()) do
	if anim:IsA("Animation") then
		targetAnimIdSet[anim.AnimationId] = true
	end
end

-- Helper: Foot IK raycast (uses per-character raycastParams passed in)
local function getFootOffset(char, humanoid, footCFrame, raycastParams)
	if not AnimationSettings.EnableFootIK or humanoid.Sit or humanoid.PlatformStand then
		return 0
	end

	local rayOrigin = footCFrame.Position + footCFrame.UpVector * AnimationSettings.footOffsetY
	local rayDirection = -footCFrame.UpVector * AnimationSettings.footRayLength

	raycastParams.FilterDescendantsInstances = { char }

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result and result.Instance and result.Instance:IsA("BasePart") then
		local hitDistance = (rayOrigin - result.Position).Magnitude
		local offset = AnimationSettings.footRayLength - hitDistance - AnimationSettings.footBaseOffset
		return math.clamp(offset, -AnimationSettings.maxFootDrop, AnimationSettings.maxFootHeight)
	end

	return 0
end

-- Helper: Compute leg adjustment (forward shift + pitch)
local function computeLegAdjustment(offset, side)
	if offset > 0 then
		local forwardShift = offset * AnimationSettings.legForwardMultiplier * side
		local pitch = -offset * AnimationSettings.legPitchMultiplier * side
		return forwardShift, pitch
	end
	return 0, 0
end

-- Helper: compute target Hip C0
local function computeHipC0(origC0, footOffset, forwardShift, footPitch, xResXZ, xRes, legsCounterCFrame)
	return legsCounterCFrame
		* origC0
		* CFrame.new(-xResXZ * 70 + forwardShift, footOffset, math.abs(xResXZ) * -30)
		* CFrame.Angles(0, -xRes, footPitch)
end

-- Receive camera data from server for other players
-- signature: (player, camCFrame, normalizedMoveDir, veryNormalizedMoveDir, cameraBasedFlag)
clientRemote.OnClientEvent:Connect(
	function(player, camCFrame, normalizedMoveDir, veryNormalizedMoveDir, cameraBasedFlag)
		if player ~= localPlayer and camCFrame and normalizedMoveDir and veryNormalizedMoveDir ~= nil then
			CameraData[player] = {
				dataCamCFrame = camCFrame,
				CamPos = camCFrame.Position,
				normalizedMoveDir = normalizedMoveDir,
				VeryNormalizedMoveDir = veryNormalizedMoveDir,
				CameraBased = cameraBasedFlag and true or false,
			}
		end
	end
)

-- Initialize per-player RenderStepped updater
local function initRunServiceForPlayer(otherPlayer)
	if otherPlayer == localPlayer then
		return
	end

	local function setupCharacter(char)
		-- Wait for needed parts
		local _head = char:WaitForChild("Head")
		local humanoid = char:WaitForChild("Humanoid")
		local root = char:WaitForChild("HumanoidRootPart")
		local torso = char:WaitForChild("Torso")
		local neck = torso:WaitForChild("Neck")
		local waist = root:WaitForChild("RootJoint")
		local rightHip = torso:WaitForChild("Right Hip")
		local leftHip = torso:WaitForChild("Left Hip")
		local animator = humanoid:FindFirstChildOfClass("Animator")

		local nOrig, wOrig = neck.C0, waist.C0
		local rOrig, lOrig = rightHip.C0, leftHip.C0

		-- local per-character foot offsets
		local footRightOffset = 0
		local footLeftOffset = 0
		local rightFootLocalCFrame = CFrame.new(0.5, -2, 0)
		local leftFootLocalCFrame = CFrame.new(-0.5, -2, 0)

		-- raycast params reused for this character
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.IgnoreWater = true
		raycastParams.RespectCanCollide = true

		local connection
		connection = RunService.RenderStepped:Connect(function(dt)
			-- Stop if character is gone
			if not char:IsDescendantOf(workspace) then
				connection:Disconnect()
				return
			end

			-- grab cached camera/movement data for this player
			local data = CameraData[otherPlayer]
			if not data then
				return
			end

			-- Pull in settings & constants from AnimationSettings (keeps parity with mainwork)
			local tr, tor = AnimationSettings.HeadTurnRange, AnimationSettings.TorsoTurnRange
			local xzR = AnimationSettings.XzRotationRatio

			local lerpSpeedHead = AnimationSettings.LerpSpeedHead
			local lerpSpeedTorso = AnimationSettings.LerpSpeedTorso
			local lerpSpeedLegs = AnimationSettings.LerpSpeedLegs

			local multiplier1 = AnimationSettings.Multiplier1
			local multiplier2 = AnimationSettings.Multiplier2
			local leanZAmount = AnimationSettings.LeanZAmount
			local leanXAmount = AnimationSettings.LeanXAmount
			local footAdjustmentSpeed = AnimationSettings.footAdjustmentSpeed

			local difference = AnimationSettings.Difference
			local inversedCameraBased = AnimationSettings.InversableCameraBasedEffects
			local inversableSmoothing = AnimationSettings.InversableCameraSmoothing
			local inversableThreshold = AnimationSettings.InversableCameraThreshold

			local cameraBasedEffectsSettings = AnimationSettings.CameraBasedEffects
			local CombinedXZ = AnimationSettings.CombinedXZ

			-- local copy of cam+move data
			local _camPos = data.CamPos
			local camCFrame = data.dataCamCFrame
			local normalizedMoveDir = data.normalizedMoveDir
			local VeryNormalizedMoveDir = data.VeryNormalizedMoveDir

			-- rootcframe
			local rootCFrame = root.CFrame

			-- handle camera-based toggle per-player and global gating
			local applyCameraBasedRotation = data.CameraBased and cameraBasedEffectsSettings
			local goalNeck = CFrame.new()
			local goalWaist = wOrig

			-- === APPLY TRANSFORMATIONS ===
			if applyCameraBasedRotation then
				local cameraDirection = rootCFrame:toObjectSpace(camCFrame).lookVector

				local cameraY = cameraDirection.Y
				local cameraX
				if CombinedXZ == true then
					cameraX = Vector3.new(cameraDirection.X, 0, cameraDirection.Z).Unit.X
				else
					cameraX = cameraDirection.X
				end

				local mp, mp1 = multiplier1, multiplier2

				if inversedCameraBased then
					local avg = -cameraDirection.Z / 2
					local value = -1 + 2 * math.clamp((avg + inversableThreshold) / inversableSmoothing, 0, 1)
					mp = mp * value
					mp1 = mp1 * value
				end

				goalWaist = CFrame.Angles(math.asin(cameraY) * mp, -math.asin(cameraX) * mp, 0) * wOrig
				goalNeck = CFrame.Angles(math.asin(cameraY) * mp * 2, -math.asin(cameraX) * mp1, 0)
			end

			-- Movement + lean
			local walkingBackwards = VeryNormalizedMoveDir.Z > difference

			local xRes = VeryNormalizedMoveDir.X * (tr - math.abs(VeryNormalizedMoveDir.Z) * (tr / 2))
			local xResXZ = VeryNormalizedMoveDir.X * (xzR - math.abs(VeryNormalizedMoveDir.Z) * (xzR / 2))
			local xLean = VeryNormalizedMoveDir.X * tor
			local yxLean = normalizedMoveDir.X * tor
			local zLean = normalizedMoveDir.Z * tor

			-- scale lean with WalkSpeed as in mainwork
			if humanoid.WalkSpeed > 16 then
				local baseWalkSpeed = 16
				local curveSoftness = 16
				local maxMultiplierIncrease = 1.5

				local excessSpeed = humanoid.WalkSpeed - baseWalkSpeed
				local scaled = excessSpeed / (curveSoftness + excessSpeed)

				local zLeanMultiplier = 1 + maxMultiplierIncrease * scaled
				local xLeanMultiplier = 1 + (maxMultiplierIncrease * scaled) / 1.5

				zLean *= zLeanMultiplier
				yxLean *= xLeanMultiplier
				xLean *= xLeanMultiplier
			end

			if walkingBackwards then
				xRes, xLean, xResXZ, yxLean = -xRes, -xLean, -xResXZ, -yxLean
			end

			-- === APPLY TRANSFORMATIONS ===
			local alphaHead = 1 - math.exp(-lerpSpeedHead * dt)
			local alphaTorso = 1 - math.exp(-lerpSpeedTorso * dt)
			local alphaLegs = 1 - lerpSpeedLegs ^ dt

			local targetWaistC0 = goalWaist * CFrame.Angles(-zLean * leanZAmount, -yxLean * leanXAmount, -xLean)
			local WaistLerp = waist.C0:lerp(targetWaistC0, alphaTorso)
			waist.C0 = WaistLerp

			local zLeanCompensation = CFrame.Angles(zLean * leanZAmount, yxLean * leanXAmount, 0)
			local waistRotation = WaistLerp * wOrig:Inverse()
			local _waist_rx, waist_ry, _waist_rz = waistRotation:ToEulerAnglesXYZ()

			if applyCameraBasedRotation then
				local torsoYawOnly = CFrame.Angles(0, waist_ry, 0)
				local inverseYaw = torsoYawOnly:Inverse()

				local targetNeckC0 = goalNeck * inverseYaw * nOrig * zLeanCompensation
				local lerpedNeck = neck.C0:lerp(targetNeckC0, alphaHead)

				local neck_rx, neck_ry, neck_rz = lerpedNeck:ToEulerAnglesXYZ()
				neck.C0 = CFrame.new(nOrig.Position) * CFrame.Angles(neck_rx, neck_ry, neck_rz)
			else
				-- Movement-based torso rotation cancellation with zLean compensation
				local torsoYawOnly = CFrame.Angles(0, waist_ry, 0)
				local inverseYaw = torsoYawOnly:Inverse()

				local targetNeckC0 = inverseYaw * nOrig * zLeanCompensation
				neck.C0 = neck.C0:lerp(targetNeckC0, alphaHead)
			end

			-- FOOT IK for this remote character (per-character offsets)
			local rightFootWorld = rootCFrame * rightFootLocalCFrame
			local leftFootWorld = rootCFrame * leftFootLocalCFrame

			local targetRightOffset = getFootOffset(char, humanoid, rightFootWorld, raycastParams)
			local targetLeftOffset = getFootOffset(char, humanoid, leftFootWorld, raycastParams)

			local alphaFoot = 1 - math.exp(-footAdjustmentSpeed * dt)
			footRightOffset = footRightOffset + (targetRightOffset - footRightOffset) * alphaFoot
			footLeftOffset = footLeftOffset + (targetLeftOffset - footLeftOffset) * alphaFoot

			-- legs counter-frame logic & hip C0
			local currentLegCounterCFrame = targetWaistC0 * wOrig:Inverse()
			local legsCounterCFrame = currentLegCounterCFrame:Inverse()

			local forwardShiftRight, footPitchRight = computeLegAdjustment(footRightOffset, 1)
			local forwardShiftLeft, footPitchLeft = computeLegAdjustment(footLeftOffset, -1)

			local targetRightHipC0 =
				computeHipC0(rOrig, footRightOffset, forwardShiftRight, footPitchRight, xResXZ, xRes, legsCounterCFrame)
			local targetLeftHipC0 =
				computeHipC0(lOrig, footLeftOffset, forwardShiftLeft, footPitchLeft, xResXZ, xRes, legsCounterCFrame)

			rightHip.C0 = rightHip.C0:lerp(targetRightHipC0, alphaLegs)
			leftHip.C0 = leftHip.C0:lerp(targetLeftHipC0, alphaLegs)

			-- Animation speed reversal for reversable animations
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					local anim = track.Animation
					if anim and targetAnimIdSet[anim.AnimationId] then
						local desiredSpeed = walkingBackwards and -1 or 1
						if track.Speed ~= desiredSpeed then
							track:AdjustSpeed(desiredSpeed)
						end
					end
				end
			end
		end)
	end

	-- Hook up existing character if present and future characters
	if otherPlayer.Character then
		setupCharacter(otherPlayer.Character)
	end
	otherPlayer.CharacterAdded:Connect(setupCharacter)
end

-- Connect to all players already in game and future players
for _, player in pairs(Players:GetPlayers()) do
	initRunServiceForPlayer(player)
end
Players.PlayerAdded:Connect(initRunServiceForPlayer)
