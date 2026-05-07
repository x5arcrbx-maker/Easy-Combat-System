--//:SERVICES
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--//:VARIABLES
local bleed_Tick = 1 -- seconds between damage
local bleed_Time = 3 -- total seconds to bleed
local bleed_DMG = 0.5 -- damage per tick

--//:REFERENCES
local VFXfolder = game:GetService("ReplicatedStorage").FX.VFX.General.StatusEffects.Bleed

--//:FUNCTIONS
local function applyEffect(hum: Humanoid, char: Model)
	--VFX
	local bloodSplashVFX : ParticleEmitter = VFXfolder.BloodSplash:Clone()
		bloodSplashVFX.Parent = char.HumanoidRootPart
		bloodSplashVFX.Enabled = true
	Debris:AddItem(bloodSplashVFX, bleed_Time)
	
	--VFX (highlight)
	local highlight : Highlight = VFXfolder.BleedHighlight:Clone()
		highlight.Parent = char
		
	task.delay(bleed_Time, function()
		TweenService:Create(
			highlight,
			TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0),
			{
				FillTransparency = 1,
				OutlineTransparency = 1
			}
		)
		Debris:AddItem(highlight, 0.25) --Remove highlight after 0.5 seconds
	end) --^ Creating tweens
	
	--Damage loop
	for _ = 1, bleed_Time do
		if hum.Health <= 0 then
			break
		end
		task.wait(bleed_Tick)
		hum:TakeDamage(bleed_DMG)
	end
	-- Remove tag after effect
	CollectionService:RemoveTag(char, "Bleed")
end

-- Apply effect when tag is added
CollectionService:GetInstanceAddedSignal("Bleed"):Connect(function(instance: Instance)
	if instance and instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
		local char = instance
		local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid
		applyEffect(hum, char)
	end
end)