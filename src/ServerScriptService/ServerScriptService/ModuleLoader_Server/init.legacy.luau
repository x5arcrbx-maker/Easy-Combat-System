local CollectionService = game:GetService("CollectionService")
local tagToCheck = "ModuleToLoad"

local function loadModuleScript(moduleScript: any)
	task.spawn(function()
		if moduleScript:IsA("ModuleScript") and moduleScript:GetAttribute("Enabled") then
			local success, result = pcall(function()
				local module = require(moduleScript)
				module:Init()
			end)
			if not success then
				warn("Failed to initialize module: " .. moduleScript.Name .. " - " .. tostring(result))
			end
		end
	end)
end

for _, v in pairs(CollectionService:GetTagged(tagToCheck)) do
	if not v:FindFirstAncestorOfClass("LocalScript") then
		loadModuleScript(v)
	end
end
CollectionService:GetInstanceAddedSignal(tagToCheck):Connect(loadModuleScript)