--//:VARIABLES
local character: Model? = game:GetService("Players").LocalPlayer.Character or game:GetService("Players").LocalPlayer.CharacterAdded:Wait()
local hum = character:WaitForChild("Humanoid") :: Humanoid

--//:MODULES
local HumanoidStates = require(game:GetService("ReplicatedStorage").Values.Tables.HumanoidStateTypes)


--//:MAIN
for state: Enum.HumanoidStateType, value: boolean in pairs(HumanoidStates) do
	hum:SetStateEnabled(state, value)
end