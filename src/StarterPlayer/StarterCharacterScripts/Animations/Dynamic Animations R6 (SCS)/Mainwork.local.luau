local Players 	 		= game:GetService("Players")
local RunService 		= game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player   = Players.LocalPlayer
local char     = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local root     = char:WaitForChild("HumanoidRootPart")
local torso    = char:WaitForChild("Torso")
local head     = char:WaitForChild("Head")
local animator = humanoid:WaitForChild("Animator")
local neck     = torso:WaitForChild("Neck")
local waist    = root:WaitForChild("RootJoint")
local rightHip = torso:WaitForChild("Right Hip")
local leftHip  = torso:WaitForChild("Left Hip")

local cam      = workspace.CurrentCamera

local nOrig, wOrig = neck.C0, waist.C0
local rOrig, lOrig = rightHip.C0, leftHip.C0
neck.MaxVelocity = 1 / 3

local AnimationSettingsPath = ReplicatedStorage.Modules.Packages["Dynamic Animations R6"].AnimationSettings
local AnimationSettings = require(AnimationSettingsPath)

local tr, tor 		 	  = AnimationSettings.HeadTurnRange, AnimationSettings.TorsoTurnRange
local xzR 				  = AnimationSettings.XzRotationRatio
local lerpSpeedHead  	  = AnimationSettings.LerpSpeedHead
local lerpSpeedTorso 	  = AnimationSettings.LerpSpeedTorso
local lerpSpeedLegs  	  = AnimationSettings.LerpSpeedLegs
local multiplier1 		  = AnimationSettings.Multiplier1
local multiplier2 		  = AnimationSettings.Multiplier2
local leanZAmount 		  = AnimationSettings.LeanZAmount
local leanXAmount 		  = AnimationSettings.LeanXAmount
local footAdjustmentSpeed = AnimationSettings.footAdjustmentSpeed
local difference 		  = AnimationSettings.Difference
local inversedCameraBased = AnimationSettings.InversableCameraBasedEffects
local inversableSmoothing = AnimationSettings.InversableCameraSmoothing
local inversableThreshold = AnimationSettings.InversableCameraThreshold

local cameraBasedEffectsSettings = AnimationSettings.CameraBasedEffects
local cameraBasedEffects = script.Parent:WaitForChild("CameraBasedEffects")
local CombinedXZ			     = AnimationSettings.CombinedXZ

local torsoCameraRotation = AnimationSettings.TorsoCameraRotation

-- Build a set for targetAnimIds for faster lookup
local targetAnimIdSet = {}
local reversableAnimationsFolder = AnimationSettingsPath.ReversableAnimations
for _, child in ipairs(reversableAnimationsFolder:GetChildren()) do
	if child:IsA("Animation") then
		targetAnimIdSet[child.AnimationId] = true
	end
end

-- Reuse RaycastParams to avoid new allocation every frame
local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {char}
raycastParams.FilterType 				 = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater 				 = true
raycastParams.RespectCanCollide 		 = true

local footRightOffset = 0
local footLeftOffset  = 0

-- Predefined constants for foot positions (moved out of frame loop)
local rightFootLocalCFrame = CFrame.new(0.5, -2, 0)
local leftFootLocalCFrame = CFrame.new(-0.5, -2, 0)

local function getFootOffset(footCFrame)
	if 
		not AnimationSettings.EnableFootIK 
		or humanoid.Sit 
		or humanoid.PlatformStand 
	then
		return 0
	end
	local rayOrigin    = footCFrame.Position + footCFrame.UpVector * AnimationSettings.footOffsetY
	local rayDirection = -footCFrame.UpVector * AnimationSettings.footRayLength
	local result 	   = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if 
		result 
		and result.Instance 
		and result.Instance:IsA("BasePart") 
	then
		local hitDistance = (rayOrigin - result.Position).Magnitude
		local offset = AnimationSettings.footRayLength - hitDistance - AnimationSettings.footBaseOffset
		return math.clamp(offset, -AnimationSettings.maxFootDrop, AnimationSettings.maxFootHeight)
	end
	return 0
end

-- 'side' should be 1 for right leg, -1 for left leg
local function computeLegAdjustment(offset, side)
	if offset > 0 then
		local forwardShift = offset * AnimationSettings.legForwardMultiplier * side
		local pitch = -offset * AnimationSettings.legPitchMultiplier * side
		return forwardShift, pitch
	end
	return 0, 0
end

-- Helper for computing target Hip C0 with direction multiplier (1 for right, -1 for left)
local function computeHipC0(origC0, footOffset, forwardShift, footPitch, xResXZ, xRes, legsCounterCFrame)
	return legsCounterCFrame * origC0 * CFrame.new(-xResXZ * 70 + forwardShift, footOffset, math.abs(xResXZ) * -30) * CFrame.Angles(0, -xRes, footPitch)
end

RunService.RenderStepped:Connect(function(dt)
	local rootCFrame = root.CFrame
	local camCFrame  = cam.CFrame
	local vel = root.AssemblyLinearVelocity

	-- Movement-based direction and speed
	local worldMoveDir = Vector3.new(vel.X, 0, vel.Z)
	local moveSpeedCap = 30
	if worldMoveDir.Magnitude > moveSpeedCap then
		worldMoveDir = worldMoveDir.Unit * moveSpeedCap
	end
	local moveDir = rootCFrame:VectorToObjectSpace(worldMoveDir)
	local normalizedMoveDir = moveDir / moveSpeedCap
	local veryNormalizedMoveDir = Vector3.zero
	if moveDir.Magnitude > 0.01 and not humanoid.PlatformStand and not humanoid.Sit then
		veryNormalizedMoveDir = moveDir.Unit
	end
	local walkingBackwards = veryNormalizedMoveDir.Z > difference

	-- Movement-based lean calculations
	local xRes   = veryNormalizedMoveDir.X * (tr - math.abs(veryNormalizedMoveDir.Z) * (tr / 2))
	local xResXZ = veryNormalizedMoveDir.X * (xzR - math.abs(veryNormalizedMoveDir.Z) * (xzR / 2))
	local xLean  = veryNormalizedMoveDir.X * tor
	local yxLean = normalizedMoveDir.X * tor
	local zLean  = normalizedMoveDir.Z * tor

	-- Scale lean based on walkspeed
	if humanoid.WalkSpeed > moveSpeedCap then
		local baseWalkSpeed = moveSpeedCap
		local curveSoftness = moveSpeedCap
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

	-- === CAMERA-BASED ROTATION SECTION ===
	local applyCameraBasedRotation = cameraBasedEffects.Value and cameraBasedEffectsSettings
	local goalNeck  = CFrame.new()
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
			local avg   = (-cameraDirection.Z) / 2
			local value = -1 + 2 * math.clamp((avg + inversableThreshold) / inversableSmoothing, 0, 1)
			mp = mp * value
			mp1 = mp1 * value
		end
		
		if torsoCameraRotation then
			goalWaist = CFrame.Angles(math.asin(cameraY) * mp, -math.asin(cameraX) * mp, 0) *wOrig
		else
			goalWaist = wOrig
		end
		goalNeck = CFrame.Angles(math.asin(cameraY) * mp * 2, -math.asin(cameraX) * mp1, 0)
	end
	
	local alphaHead  = 1 - math.exp(-lerpSpeedHead * dt)
	local alphaTorso = 1 - math.exp(-lerpSpeedTorso * dt)
	local alphaLegs  = 1 - lerpSpeedLegs ^ dt
	
	local goalLean 		= CFrame.Angles(-zLean * leanZAmount, -yxLean * leanXAmount, -xLean)
	local targetWaistC0 = goalWaist * goalLean
	local WaistLerp 	= waist.C0:lerp(targetWaistC0, alphaTorso)
	waist.C0 = WaistLerp

	local zLeanCompensation = CFrame.Angles(zLean * leanZAmount, yxLean * leanXAmount, 0)
	local waistRotation 	= WaistLerp * wOrig:Inverse()
	local rx, ry, rz 		= waistRotation:ToEulerAnglesXYZ()

	if applyCameraBasedRotation then
		local torsoYawOnly = CFrame.Angles(0, ry, 0)
		local inverseYaw   = torsoYawOnly:Inverse()
		local targetNeckC0 = goalNeck * inverseYaw * nOrig * zLeanCompensation
		local lerpedNeck   = neck.C0:lerp(targetNeckC0, alphaHead)
		local rx, ry, rz   = lerpedNeck:ToEulerAnglesXYZ()
		neck.C0 = CFrame.new(nOrig.Position) * CFrame.Angles(rx, ry, rz)
	else
		-- Movement-based torso rotation cancellation with zLean compensation
		local torsoYawOnly = CFrame.Angles(0, ry, 0)
		local inverseYaw = torsoYawOnly:Inverse()
		local targetNeckC0 = inverseYaw * nOrig * zLeanCompensation
		neck.C0 = neck.C0:lerp(targetNeckC0, alphaHead)
	end

	--local neckCounterRotation = (waist.C0 * wOrig:Inverse()):Inverse()
	--neck.C0 = neck.C0:lerp(neckCounterRotation * nOrig, alphaHead)

	---- Waist lean + torso rotation
	--local targetWaistC0 = goalWaist * CFrame.Angles(-zLean * leanZAmount, -yxLean * leanXAmount, -xLean)
	--waist.C0 = waist.C0:lerp(targetWaistC0, alphaTorso)

	-- === FOOT IK ===
	local rightFootWorld = rootCFrame * rightFootLocalCFrame
	local leftFootWorld  = rootCFrame * leftFootLocalCFrame

	local footRightOffsetTarget = getFootOffset(rightFootWorld)
	local footLeftOffsetTarget  = getFootOffset(leftFootWorld)
	local alphaFoot = 1 - math.exp(-footAdjustmentSpeed * dt)

	footRightOffset = footRightOffset + (footRightOffsetTarget - footRightOffset) * alphaFoot
	footLeftOffset  = footLeftOffset + (footLeftOffsetTarget - footLeftOffset) * alphaFoot

	AnimationSettings.rightFootOffset = footRightOffset
	AnimationSettings.leftFootOffset  = footLeftOffset

	local currentLegCounterCFrame = targetWaistC0 * wOrig:Inverse()
	local legsCounterCFrame = currentLegCounterCFrame:Inverse()

	local forwardShiftRight, footPitchRight = computeLegAdjustment(footRightOffset, 1)
	local forwardShiftLeft, footPitchLeft   = computeLegAdjustment(footLeftOffset, -1)

	local targetRightHipC0 = computeHipC0(rOrig, footRightOffset, forwardShiftRight, footPitchRight, xResXZ, xRes, legsCounterCFrame)
	local targetLeftHipC0  = computeHipC0(lOrig, footLeftOffset, forwardShiftLeft, footPitchLeft, xResXZ, xRes, legsCounterCFrame)

	rightHip.C0 = rightHip.C0:lerp(targetRightHipC0, alphaLegs)
	leftHip.C0  = leftHip.C0:lerp(targetLeftHipC0, alphaLegs)

	-- === ANIMATION SPEED REVERSAL ===
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
