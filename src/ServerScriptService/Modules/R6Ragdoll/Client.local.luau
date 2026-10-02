-- VARIABLES
local player = game:GetService("Players").LocalPlayer :: Player
local character = player.Character or player.CharacterAdded:Wait() :: Model
--
local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
--
local attributeName: string = "Ragdolled"

-- Code --
humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

-- Makes hands interact with head better
local head = character:WaitForChild("Head")
head.Size = Vector3.new(1, 1, 1)

character:GetAttributeChangedSignal(attributeName):Connect(function()
	if character:GetAttribute(attributeName) then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		hrp:ApplyAngularImpulse(Vector3.new(-90, 0, 0))
	else
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end)
