--+==+--
-- Dynamic Animations R6 Scripts -DarkFire_Ninja (@AwesomePeleTDM)
-- Also used a ton of ChatGPT to code it bc a lot of these stuff are beyond my expertise xd
--+==+--

-- AnimationSettings ModuleScript
local AnimationSettings = {
	LerpSpeedHead = 24, -- how fast the head  animates
	LerpSpeedTorso = 8, -- how fast the torso animates
	LerpSpeedLegs = 0.005, -- how fast the legs animate

	HeadTurnRange = math.rad(90), -- the range of the head rotation from Directional Movement
	TorsoTurnRange = math.rad(50), -- the range of the torso rotation from Directional Movement
	XzRotationRatio = math.rad(160) / 140, --scaling factor used for leg rotation, can be buggy

	CameraBasedEffects = true, --if the player's head (and torso if enabled) look where the camera is looking
	CombinedXZ = true, -- If the Z rotation of the camera effects the X rotation of the head too.
	TorsoCameraRotation = false, --If the player's torso moves to look where the camera is looking.
	
	InversableCameraBasedEffects = true, --if the player's head (and torso if enabled) look towards the camera when the camera is facing the front of the player.
	InversableCameraThreshold = 0.3, -- the smaller it is, the sooner the inversion activates when you turn the camera around
	InversableCameraSmoothing = 0.05, -- Controls how gradually the camera-based rotation flips
	
	Multiplier1 = 0.3, --camera based effects, for torso
	Multiplier2 = 1, -- camera based effects, for head

	LeanZAmount = 0.2, -- how much the body can lean on the Z axis.
	LeanXAmount = 0.1, -- how much the body can lean on the X axis.

	LeanBackMulti = 0.125, -- how much the body can lean backwards
	LeanForwardMulti = 0.25, -- how much the body can lean forwards

	Difference = 0.5, --at which point the legs start animating to walk backwards

	-- FOOT IK Constants
	EnableFootIK = true, -- if footIK/FootPlacement is enabled

	footRayLength = 3, --How far down it checks for objects beneath the leg
	footOffsetY = 1.5, --how high above the foot's actual position the raycast starts at
	footBaseOffset = 0.5, --how much the foot is raised or lowered relative to the ground hit point from the raycast

	legPitchMultiplier = 0.8, -- Multiplier of how much the leg rotates when an object is under it
	legForwardMultiplier = 1.0, -- Multiplier of how far forward the leg moves when an object is under it

	maxFootHeight = 0.6, --The max height the foot can be from the ground.
	maxFootDrop = 0, --The max the leg can move down from the body

	footAdjustmentSpeed = 16, --How fast the foot adjustes (how fast it moves up when something is below it)
}

return AnimationSettings
