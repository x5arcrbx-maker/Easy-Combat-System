--//:SERVICES//
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")


--//:VARIABLES//
local player = game:GetService("Players").LocalPlayer

local saturation_original: number = game:GetService("ReplicatedStorage").Zones.Lighting.DEFAULT.ColorCorrection.Saturation or 0.2
local saturation_low: number = -0.5
local value_multiplier: number = 0.4
local HEALTH_THRESHOLD: number = 40 -- When to start the effect

local tweens: {Tween} = {} --Store tweens to cancel them (prevents overriding eachother)

--//:FUNCTIONS
local function saturationBasedOffHP(health: number, maxHealth: number)

	local healthPercent = health / maxHealth
	local missingPercent = 1 - healthPercent
	
	if missingPercent <= value_multiplier then --Prevents saturation being turnt too high up
		
		local ColorCorrectionEffect = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
		if ColorCorrectionEffect then
			for _, v: Tween in tweens do
				v:Cancel()
				v = nil
			end
			
			local tween: Tween = TweenService:Create(
				ColorCorrectionEffect,
				TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Saturation = saturation_original}
			)
			table.insert(tweens, tween)
			tween:Play()
		end
		
	else --Gradually lower saturation according to HP
		
		local saturationValue = (saturation_original - missingPercent) + value_multiplier -- tweak multiplier

		if saturationValue < saturation_low then 
			saturationValue = saturation_low 
		end

		--Update saturation
		local ColorCorrectionEffect = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
		if ColorCorrectionEffect then
			for _, v: Tween in tweens do
				v:Cancel()
				v = nil
			end
			
			local tween: Tween = TweenService:Create(
				ColorCorrectionEffect,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Saturation = saturationValue}
			)
			table.insert(tweens, tween)
			tween:Play()
		end
		
	end
end


--//:EVENTS//
player.CharacterAdded:Connect(function(character)
	
	--Reference Humanoid and update saturation initially.
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	saturationBasedOffHP(humanoid.MaxHealth, humanoid.MaxHealth)
	
	--//:MAIN
	local healthChanged_connection: RBXScriptConnection
	healthChanged_connection = humanoid.HealthChanged:Connect(function(health: number)
		
		if health <= HEALTH_THRESHOLD then
			saturationBasedOffHP(health, humanoid.MaxHealth)
		else
			saturationBasedOffHP(humanoid.MaxHealth, humanoid.MaxHealth) -- reset to default
		end
		
	end) --^ Detect changes in humanoid's health to adjust saturation.
	
	--Disconnect healthChanged_connection once humanoid dies.
	humanoid.Died:Once(function()
		healthChanged_connection:Disconnect()
	end)
	
end)












