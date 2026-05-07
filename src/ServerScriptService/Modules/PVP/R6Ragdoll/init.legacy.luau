--[[
	Place this script in ServerScriptService

	For instructions on how to use, refer to the devforum post:
	https://devforum.roblox.com/t/smooth-r6-ragdoll-for-players-and-npcs-plug-and-play
]]

local PhysicsService = game:GetService("PhysicsService")
local module = require(script.ModuleScript)
local ragParts = script.RagdollParts:GetChildren()
local r6Client = script.R6RagdollClient

PhysicsService:RegisterCollisionGroup("Ragdoll")

game:GetService("Players").PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		-- Setup ragdoll
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		--char["Head"].Size = Vector3.new(1, 1, 1)
		humanoid.BreakJointsOnDeath = false
		humanoid.RequiresNeck = false

		local clones = {}
		for _, v in ipairs(ragParts) do
			clones[v.Name] = v:Clone()
		end

		local constraintsFolder = Instance.new("Folder")
		constraintsFolder.Name = "RagdollConstraints"
		for _, v in pairs(clones) do
			if v:IsA("Attachment") then
				v.Parent = char[v:GetAttribute("Parent")]
			elseif v:IsA("BallSocketConstraint") then
				v.Attachment0 = clones[v:GetAttribute("0")]
				v.Attachment1 = clones[v:GetAttribute("1")]
				v.Parent = constraintsFolder
			end
		end
		constraintsFolder.Parent = char

		local motorsFolder = Instance.new("Folder")
		motorsFolder.Name = "Motors"
		local value
		for _, v in ipairs(char.Torso:GetChildren()) do
			if v:IsA("Motor6D") then
				value = Instance.new("ObjectValue")
				value.Value = v
				value.Parent = motorsFolder
			end
		end
		motorsFolder.Parent = constraintsFolder

		-- Ragdoll trigger
		local trigger = Instance.new("BoolValue")
		trigger.Name = "RagdollTrigger"
		trigger.Parent = char

		trigger.Changed:Connect(function(bool)
			if bool then
				module:Ragdoll(char)
			else
				module:Unragdoll(char)
			end
		end)
		
		r6Client:Clone().Parent = char
		
		--Connect died event
		humanoid.Died:Once(function()
			trigger.Value = true
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local deathAudio = script.DeathSound:Clone()
				deathAudio.Volume = 1.5
				deathAudio.Parent = hrp
				deathAudio:Play()
				game:GetService("Debris"):AddItem(deathAudio, deathAudio.TimeLength)
			end
		end) --End of died event
	end) --End of character added
end) --End of player added
