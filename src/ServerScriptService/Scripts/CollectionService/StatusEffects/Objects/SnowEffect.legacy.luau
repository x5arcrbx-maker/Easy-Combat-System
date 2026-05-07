local CS = game:GetService("CollectionService")
local snow = CS:GetTagged("Snow")

for i, block in pairs(snow) do
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
