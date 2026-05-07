local CS = game:GetService("CollectionService")
local mud = CS:GetTagged("Mud")

for _, block in pairs(mud) do
	block.Touched:Connect(function(hit)
		local char = hit.Parent
		local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid")
		if hum then
			char:SetAttribute("Slowed", true)
		else
			return
		end
	end)
	
	block.TouchEnded:Connect(function(hit)
		local char = hit.Parent
		local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Humanoid")
		if hum then
			char:SetAttribute("Slowed", false)
		else
			return
		end
	end)
end
