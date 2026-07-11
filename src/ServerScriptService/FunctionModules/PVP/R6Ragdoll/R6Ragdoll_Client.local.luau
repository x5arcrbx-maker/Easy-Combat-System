local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local ragollTrigger = char:WaitForChild("RagdollTrigger")
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

-- Makes hands interact with head better
local head = char:WaitForChild("Head")
head.Size = Vector3.new(1,1,1)

ragollTrigger.Changed:Connect(function(bool)
	if bool then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		hrp:ApplyAngularImpulse(Vector3.new(-90, 0, 0))
	else
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end)