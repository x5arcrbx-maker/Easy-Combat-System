local SkillsService_Client = {}

function SkillsService_Client:Init(tool: Tool)
	local _UserInputService = game:GetService("UserInputService") :: UserInputService

	local NotifyEquipWeapon_Module = require(script:WaitForChild("NotifyEquipWeapon"))

	local player = game:GetService("Players").LocalPlayer :: Player
	local character = player.Character or player.CharacterAdded:Wait() :: Model
	local _humanoid = character:WaitForChild("Humanoid") :: Humanoid

	local skillEvent = tool:FindFirstChildOfClass("RemoteEvent")
	if not skillEvent then
		local childAddedConn
		childAddedConn = tool.ChildAdded:Connect(function(child)
			if child:IsA("RemoteEvent") then
				skillEvent = child
				childAddedConn:Disconnect()
			end
		end)
	end

	tool.Equipped:Connect(function()
		skillEvent:FireServer()
		NotifyEquipWeapon_Module:NotifyPlayer(player, character)
	end)
end

return SkillsService_Client
