-- SERVICES
local Players = game:GetService("Players")
local _PhysicsService = game:GetService("PhysicsService")

-- VARIABLES
local R6Ragdoll = script.Parent :: Folder
--
local attributeName: string = "Ragdolled"
--
local ragParts = R6Ragdoll.RagdollParts:GetChildren() :: { BallSocketConstraint | Attachment }

-- Code --
local module = {}

--Adds necessary objects to character for ragdoll to function properly,
--	and connects an event to the ragdoll attribute.
function module:Setup(character: Model)
	assert(
		Players:GetPlayerFromCharacter(character) == nil,
		"Setting up ragdoll on player characters is already done automatically"
	)

	local humanoid = character:FindFirstChild("Humanoid")
	assert(humanoid, "Can only set-up ragdoll on R6 humanoid rigs")
	assert(humanoid.RigType == Enum.HumanoidRigType.R6, "Can only set-up ragdoll on R6 humanoid rigs")
	assert(humanoid.RootPart ~= nil, "No RootPart was found in the provided rig")
	assert(character:FindFirstChild("HumanoidRootPart"), "No HumanoidRootPart was found in the provided rig")

	for _, v: BasePart in ipairs(character:GetDescendants()) do
		if v:IsA("BasePart") then
			v:SetNetworkOwner(nil)
		end
	end

	-- Setup ragdoll
	--char["Head"].Size = Vector3.new(1, 1, 1)
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false

	local clones = {}
	for _, v in ipairs(ragParts) do
		clones[v.Name] = v:Clone()
	end

	local folder1 = Instance.new("Folder")
	folder1.Name = "RagdollConstraints"
	for _, v in pairs(clones) do
		if v:IsA("Attachment") then
			v.Parent = character[v:GetAttribute("Parent")]
		elseif v:IsA("BallSocketConstraint") then
			v.Attachment0 = clones[v:GetAttribute("0")]
			v.Attachment1 = clones[v:GetAttribute("1")]
			v.Parent = folder1
		end
	end
	folder1.Parent = character

	local folder2 = Instance.new("Folder")
	folder2.Name = "Motors"
	local value
	for _, v in ipairs(character.Torso:GetChildren()) do
		if v:IsA("Motor6D") then
			value = Instance.new("ObjectValue")
			value.Value = v
			value.Parent = folder2
		end
	end
	folder2.Parent = folder1

	-- Ragdoll event
	character:GetAttributeChangedSignal(attributeName):Connect(function()
		if character:GetAttribute(attributeName) then
			module:Ragdoll(character)
			character:SetAttribute("Ragdolled", true)
		else
			module:Unragdoll(character)
			character:SetAttribute("Ragdolled", false)
		end
	end)
end

--Ragdolls character
function module:Ragdoll(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not humanoid or not hrp then
		return
	end
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.AutoRotate = false
	for _, v in ipairs(character.RagdollConstraints.Motors:GetChildren()) do
		v.Value.Enabled = false
	end

	for _, v in ipairs(character:GetChildren()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Ragdoll"
		end
	end

	hrp:ApplyAngularImpulse(Vector3.new(-90, 0, 0))
end

--Unragdolls character
function module:Unragdoll(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	if not humanoid then
		return
	end

	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	for _, v in ipairs(character.RagdollConstraints.Motors:GetChildren()) do
		v.Value.Enabled = true
	end

	for _, v in ipairs(character:GetChildren()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Default"
		end
	end
	humanoid.AutoRotate = true
end

return module
