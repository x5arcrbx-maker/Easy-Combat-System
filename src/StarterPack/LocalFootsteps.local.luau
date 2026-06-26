--PUT THIS SCRIPT IN STARTERPACK

--//:SERVICES//
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
---------------

----------
script:WaitForChild("FootstepSounds").Parent = SoundService
local materials = SoundService:WaitForChild("FootstepSounds") :: SoundGroup
----------

--//:VARIABLES//
local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local _hrp = char:FindFirstChild("HumanoidRootPart") :: Part
local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid

local walking: boolean = false
local MAXSPEED: number = 16
local currentSpeed: number = 0
local _defaultWalkSpeed: number = game:GetService("StarterPlayer").CharacterWalkSpeed
----------------

--//:FUNCTIONS//
local function getMaterial(): string
	local floormat: Enum.Material = hum.FloorMaterial
	if not floormat then
		floormat = "Air"
	end
	local material: string = string.split(tostring(floormat), "Enum.Material.")[2]
	return material
end
----------------

--//:MAIN//
hum.Running:Connect(function(speed)
	if speed > hum.WalkSpeed / 2 then
		walking = true
	else
		walking = false
	end
end)

local lastmat: string?
RunService.Heartbeat:Connect(function()
	if walking then
		local material: string = getMaterial()
		if material ~= lastmat and lastmat ~= nil then
			materials[lastmat].Playing = false
		end

		local materialSound = materials:FindFirstChild(material)
		if materialSound then
			if hum.WalkSpeed > MAXSPEED then
				currentSpeed = MAXSPEED
			else
				currentSpeed = hum.WalkSpeed
			end
			materialSound.PlaybackSpeed = currentSpeed / (currentSpeed < MAXSPEED and 12.5 or 12)
			materialSound.Playing = true
			lastmat = material
		end
	else
		for _, sound in pairs(materials:GetChildren()) do
			sound.Playing = false
		end
	end
end)
-----------
