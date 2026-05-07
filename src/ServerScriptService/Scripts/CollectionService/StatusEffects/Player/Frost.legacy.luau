--//:SERVICES
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--//:VARIABLES
local frost_Tick = 1 -- seconds between damage
local frost_Time = 2 -- total seconds to frost
local frost_DMG = 0.75 -- damage per tick

--//:REFERENCES
local VFX: Folder = game:GetService("ReplicatedStorage").FX.VFX.General.StatusEffects.Frost

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
		task.delay(frost_Time, function()
			particle.Enabled = false
		end)
	end
	Debris:AddItem(attachment, frost_Time + 2) --Remove attachment after frost is over (includes particles)

	--VFX (highlight)
	local highlight: Highlight = VFX:FindFirstChildOfClass("Highlight"):Clone()
	highlight.Parent = char
	
	char:SetAttribute("Slowed", true)
	task.delay(frost_Time, function()
		char:SetAttribute("Slowed", false)
		
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
	for _ = 1, frost_Time do 
		if hum.Health <= 0 then break end
		task.wait(frost_Tick)
		hum:TakeDamage(frost_DMG)
	end
	-- Remove tag after effect
	CollectionService:RemoveTag(char, "Frost")
end

-- For newly added frost
CollectionService:GetInstanceAddedSignal("Frost"):Connect(function(instance: Instance)
	if instance and instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
		local char = instance
		local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid
		applyEffect(hum, char)
	end
end)