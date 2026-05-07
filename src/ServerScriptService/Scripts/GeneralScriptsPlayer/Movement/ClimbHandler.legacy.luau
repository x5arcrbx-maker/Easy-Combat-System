--//:SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris 			= game:GetService("Debris")
local Players 			= game:GetService("Players")

--//:VARIABLES
local climbEvent: RemoteEvent = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer:WaitForChild("WallClimb")

local playerCooldowns = {} -- Track cooldowns per player

--//:CONSTANTS
local COOLDOWN: number = 0.425 -- seconds

local POSITION_Time: number = 0.15
local FORCE_Amount: number = 60
local FORCE_Time: number = 0.3

--//:FUNCTIONS
local function playAnim(hum: Humanoid)
	local animator = hum:FindFirstChildOfClass("Animator")
	local anim = ReplicatedStorage.Animations.General.Climb:FindFirstChildOfClass("Animation")
	local animTrack = animator:LoadAnimation(anim)
	animTrack:Play()
	animTrack.Stopped:Once(function()
		animTrack:Destroy()
	end)
end

local function playSound(hrp: BasePart)
	local sound = script:FindFirstChildOfClass("Sound")
	if sound then
		sound = sound:Clone()
		sound.Parent = hrp
		sound:Play()
		Debris:AddItem(sound, sound.TimeLength)
	end
end

local function climb(hrp: BasePart)
	local BodyPosition: BodyPosition = Instance.new("BodyPosition")
	BodyPosition.Position = hrp.Position
	BodyPosition.MaxForce = Vector3.new(100000, 100000, 100000)
	BodyPosition.Parent = hrp
	Debris:AddItem(BodyPosition, POSITION_Time)
	
	BodyPosition.Destroying:Once(function()
		playSound(hrp)
	end)
	
	local BodyVelocity: BodyVelocity = Instance.new("BodyVelocity")
	BodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
	BodyVelocity.Velocity = hrp.CFrame.UpVector * FORCE_Amount
	BodyVelocity.Parent = hrp
	Debris:AddItem(BodyVelocity, FORCE_Time)
end

--//:EVENTS
climbEvent.OnServerEvent:Connect(function(player, inAir: boolean)
	if playerCooldowns[player] and tick() - playerCooldowns[player] < COOLDOWN then
		return
	end

	local character = player.Character :: Model?
	if not character then return end
	local hum = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not hrp then return end
	
	if character:GetAttribute("CanClimb") == false then
		return
	end

	local climbCount = character:GetAttribute("ClimbCount") or 0

	-- Raycast setup
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	if inAir then
		if climbCount < 3 then
			local canClimb = character:GetAttribute("CanClimb")
			local state = hum:GetState()
			if canClimb 
				and (
					state == Enum.HumanoidStateType.Jumping 
					or state == Enum.HumanoidStateType.Freefall
				) then
				
				if hum.MoveDirection.Magnitude > 0 then
					local origin = hrp.Position + Vector3.new(0, 2, 0)
					local raycast = workspace:Raycast(origin, hrp.CFrame.LookVector * 4, params)
					if raycast then
						local modelHit = raycast.Instance:FindFirstAncestorOfClass("Model")
						if modelHit and modelHit:FindFirstChildOfClass("Humanoid") then
							return -- Don't climb on other characters
						end
						character:SetAttribute("ClimbCount", climbCount + 1)
						playerCooldowns[player] = tick()
						
						playAnim(hum)
						climb(hrp) --we don't call playSound because climb already calls it
					end
				end
			end
		else
			character:SetAttribute("CanClimb", true)
		end
	else -- landed
		character:SetAttribute("ClimbCount", 0)
		character:SetAttribute("CanClimb", true)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player] = nil
end)
