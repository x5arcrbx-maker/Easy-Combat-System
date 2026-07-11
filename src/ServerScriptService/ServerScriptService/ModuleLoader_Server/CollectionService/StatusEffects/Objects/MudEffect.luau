local module = {}

function module:Init()
	local CollectionService = game:GetService("CollectionService")

	for _, block in pairs(CollectionService:GetTagged("Mud")) do
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

end

return module
