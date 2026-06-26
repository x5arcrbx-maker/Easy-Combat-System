local module = {}

function module:Init()
	local CollectionService = game:GetService("CollectionService")

	for _, block in pairs(CollectionService:GetTagged("Snow")) do
		block.Touched:Connect(function(hit)
			local hum = hit.Parent:FindFirstChild("Humanoid")
			if hum then
				hum.Parent:SetAttribute("Slowed", true)
			end
		end)

		block.TouchEnded:Connect(function(hit)
			local hum = hit.Parent:FindFirstChild("Humanoid")
			if hum then
				hum.Parent:SetAttribute("Slowed", false)
			end
		end)
	end

end

return module
