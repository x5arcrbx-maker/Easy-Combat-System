local character = script.Parent

function AddDowned()
	local downed = Instance.new("ObjectValue")
	downed.Parent = game:GetService("ReplicatedStorage").Values.Downed
	downed.Name = character.Name
	downed.Value = character
	
	character:SetAttribute("Knocked", true)
end

function RemoveDowned()
	local downed = game:GetService("ReplicatedStorage").Values.Downed:FindFirstChild(character.Name)
	if downed then
		downed:Destroy()
		character:SetAttribute("Knocked", false)
	end
end

local Humanoid = character:FindFirstChildOfClass("Humanoid")
if Humanoid then
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	Humanoid.HealthChanged:Connect(function(health)
		if health > 0 then
			return
		end
		if Humanoid:GetStateEnabled(Enum.HumanoidStateType.Dead) == false then
			character.RagdollTrigger.Value = true
			AddDowned(character)
		end
	end)
end

--[[
--	Debugger	--

task.wait(2)
character.Humanoid.Health = 0
--]]

Humanoid.HealthChanged:Connect(function()
	if not character:GetAttribute("Knocked") then
		return
	end
	if not ( (Humanoid.Health / Humanoid.MaxHealth) >= 0.15) then
		return
	end
	if character.RagdollTrigger.Value == false then
		return
	end
	
	character.RagdollTrigger.Value = false
	RemoveDowned(character)
end)