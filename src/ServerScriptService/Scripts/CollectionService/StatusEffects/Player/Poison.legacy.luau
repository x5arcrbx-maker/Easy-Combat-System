--//:SERVICES
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

--//:VARIABLES
local poison_Tick = 1 -- seconds between damage
local poison_Time = 6 -- total seconds to poison
local poison_DMG = 0.5 -- damage per tick

--//:REFERENCES
local VFX: Folder = game:GetService("ReplicatedStorage").FX.VFX.General.StatusEffects.Poison


--//:FUNCTIONS
local function applyEffect(hum: Humanoid, char: Model)
	--VFX
	local attachment = Instance.new("Attachment") :: Attachment
	attachment.Parent = char.HumanoidRootPart
	
	for _, v in pairs(VFX:GetChildren()) do
		if not v:IsA("ParticleEmitter") then continue end
		
		local particle = v:Clone()
		particle.Parent = attachment
		particle.Enabled = true
	end
	Debris:AddItem(attachment, poison_Time)
	
	--Damage loop
	for _ = 1, poison_Time do
		if hum.Health <= 0 then break end
		task.wait(poison_Tick)
		hum:TakeDamage(poison_DMG)
	end

	-- Remove tag after effect
	CollectionService:RemoveTag(char, "Poison")
end

-- For newly added Poison
CollectionService:GetInstanceAddedSignal("Poison"):Connect(function(instance: Instance)
	if instance and instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
		local char = instance
		local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid
		applyEffect(hum, char)
	end
end)