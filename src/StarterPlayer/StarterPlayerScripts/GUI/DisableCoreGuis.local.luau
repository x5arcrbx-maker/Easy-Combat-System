--//:	SERVICES	//--
local StarterGui = game:GetService("StarterGui")


--//:	MAIN	//--
--SetCore--
--while task.wait() do -- Disable the reset button in the menu
--	local ok, error = pcall(function()
--		StarterGui:SetCore("ResetButtonCallback", false)
--	end)
--	if ok then break end
--end

while task.wait() do -- Disable Developer console
	local ok, error = pcall(function()
		StarterGui:SetCore("DevConsoleVisible", false)
	end)
	if ok then break end
end

--SetCoreGuiEnabled--
while task.wait() do -- Disable default health bar
	local ok, error = pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)
	if ok then break end
end

while task.wait() do -- Disable default emotes menu
	local ok, error = pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	end)
	if ok then break end
end

