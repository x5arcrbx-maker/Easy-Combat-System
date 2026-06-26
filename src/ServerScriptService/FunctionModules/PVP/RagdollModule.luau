local RagdollModule = {}

function RagdollModule.Ragdoll(char, timeTotal)
	if not char then
		warn("Character not given into: (".. script.Name .. " ), function: RagdollModule.Ragdoll")
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if not hum then return end

	local RagdollValue = char:FindFirstChild("IsRagdoll") :: BoolValue?
	if not RagdollValue then return end
	if RagdollValue.Value then
		return
	end -- Already ragdolled

	--Setting attributes
	RagdollValue.Value = true -- Apply Ragdoll effect
	char:SetAttribute("Ragdolled", true)

	--Removing Ragdoll after timeTotal
	task.delay(timeTotal or 2.5, function()
		if char:GetAttribute("Knocked") then
			return
		end

		RagdollValue.Value = false -- Remove Ragdoll effect
		char:SetAttribute("Ragdolled", false)
	end)
end

return RagdollModule

--REMOVE RAGDOLL, RIGHT ABOVE DEBRISCHARACTER
--hum.PlatformStand = false
--hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
--hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)

--APPLY RAGDOLL, AT VERY END
--hum.PlatformStand = true
--hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
--hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
