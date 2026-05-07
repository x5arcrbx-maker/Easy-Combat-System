--//:SERVICES
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--//:VARIABLES
local burn_Tick = 1 -- seconds between damage
local burn_Time = 3 -- total seconds to burn
local burn_DMG = 1 -- damage per tick

--//:REFERENCES
local VFX: Folder = game:GetService("ReplicatedStorage").FX.VFX.General.StatusEffects.Burn

--//:FUNCTIONS
local function applyEffect(hum: Humanoid, char: Model)
	--VFX (particles)
	local attachment = Instance.new("Attachment")
	attachment.Parent = char.HumanoidRootPart
	
	for _, v in pairs(VFX:GetChildren()) do
		if not v:IsA("ParticleEmitter") then continue end
		
		local particle = v:Clone()
		particle.Parent = attachment
		particle.Enabled = true
	end
	Debris:AddItem(attachment, burn_Time) --Remove attachment after burn is over (includes particles)

	--VFX (highlight)
	local highlight: Highlight = VFX:FindFirstChildOfClass("Highlight"):Clone()
	highlight.Parent = char
		
	task.delay(burn_Time, function()
		TweenService:Create(
			highlight,
			TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0),
			{
				FillTransparency = 1,
				OutlineTransparency = 1
			}
		):Play()
		Debris:AddItem(highlight, 0.25) --Remove highlight after 0.5 seconds
	end) --^ Creating tweens
	
	--Damage loop
	for _ = 1, burn_Time do 
		if hum.Health <= 0 then break end
		task.wait(burn_Tick)
		hum:TakeDamage(burn_DMG)
	end
	-- Remove tag after effect
	CollectionService:RemoveTag(char, "Burn")
end

-- For newly added Burn
CollectionService:GetInstanceAddedSignal("Burn"):Connect(function(instance: Instance)
	if instance and instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
		local char = instance
		local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid
		applyEffect(hum, char)
	end
end)