--[[
	Place this script in ServerScriptService

	For instructions on how to use, refer to the devforum post:
	https://devforum.roblox.com/t/smooth-r6-ragdoll-for-players-and-npcs-plug-and-play
]]

-- SERVICES
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

-- VARIABLES
local attributeName: string = "Ragdolled"
--
local R6Ragdoll = script.Parent :: Folder
local deathSoundsFolder = R6Ragdoll:FindFirstChild("DeathSounds") :: Folder?
--
local deathSounds = deathSoundsFolder and deathSoundsFolder:GetChildren() or nil :: { Sound? }
local ragParts = R6Ragdoll.RagdollParts:GetChildren() :: { BallSocketConstraint | Attachment }
--
local FunctionsModule = R6Ragdoll:FindFirstChildOfClass("ModuleScript")
local clientScript = R6Ragdoll:FindFirstChildOfClass("LocalScript") :: LocalScript

-- MODULES
local functionScript = require(FunctionsModule)

-- Code --
PhysicsService:RegisterCollisionGroup("Ragdoll")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Setup ragdoll
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		--character["Head"].Size = Vector3.new(1, 1, 1)
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
				v.Parent = character[v:GetAttribute("Parent")]
			elseif v:IsA("BallSocketConstraint") then
				v.Attachment0 = clones[v:GetAttribute("0")]
				v.Attachment1 = clones[v:GetAttribute("1")]
				v.Parent = constraintsFolder
			end
		end
		constraintsFolder.Parent = character

		local motorsFolder = Instance.new("Folder")
		motorsFolder.Name = "Motors"
		local value
		for _, v in ipairs(character.Torso:GetChildren()) do
			if v:IsA("Motor6D") then
				value = Instance.new("ObjectValue")
				value.Value = v
				value.Parent = motorsFolder
			end
		end
		motorsFolder.Parent = constraintsFolder

		-- Ragdoll event

		character:GetAttributeChangedSignal(attributeName):Connect(function()
			if character:GetAttribute(attributeName) then
				functionScript:Ragdoll(character)
			else
				functionScript:Unragdoll(character)
			end
		end)

		clientScript:Clone().Parent = character

		--Connect died event
		humanoid.Died:Once(function()
			character:SetAttribute(attributeName, true)

			--//Extras
			if deathSounds and type(deathSounds) == "table" then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local deathAudio = deathSounds[math.random(1, #deathSounds)]
					if not deathAudio then
						return
					end
					local cloneAudio = deathAudio:Clone()
					cloneAudio.Parent = hrp
					cloneAudio:Play()
					game:GetService("Debris"):AddItem(cloneAudio, cloneAudio.TimeLength + 1)
				end
			end
			--//
		end) --End of died event
	end) --End of characteracter added
end) --End of player added
