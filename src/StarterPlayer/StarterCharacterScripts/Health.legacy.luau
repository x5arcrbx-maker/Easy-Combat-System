local char = script.Parent
local hum = char:FindFirstChildOfClass("Humanoid")

local currentHealth = hum.Health
local lastDamage = nil
local lastRegen = tick()

local regenerationLimit = 1 * hum.MaxHealth
local regenerationRate = 1
local regenerationSize = 0 * hum.MaxHealth

local function updateRegen()
	if hum:GetState() == Enum.HumanoidStateType.Dead then return end --Do not regen if already dead
	
	if hum.Health <= 0 then --if health is at or below 0, kill the humanoid
		hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
		hum:ChangeState(Enum.HumanoidStateType.Dead)
		return
	end
	
	if hum.Health < currentHealth and hum.Health > 0 then --Less HP than last regen tick, meaning humanoid took damage and isn't dead
		currentHealth = hum.Health
		lastDamage = tick()
	elseif hum.Health > currentHealth and hum.Health > 0 then --More HP than last regen tick, meaning humanoid regened HP and isn't dead
		if currentHealth + regenerationSize > hum.Health then
			lastDamage = tick()
		end
		currentHealth = hum.Health	
	end
	
	
end

local function changeRegenSizeBasedOnHunger()
	local hunger = char:GetAttribute("Hunger")
	if hunger > 0 then --character has hunger, so have default regen size
		regenerationSize = 0.5
	else --character has no hunger, decrease regen size
		regenerationSize = 0.25
	end
end

hum:GetPropertyChangedSignal("Health"):Connect(updateRegen)
hum:GetPropertyChangedSignal("MaxHealth"):Connect(updateRegen)

while true do
	if hum:GetState() == Enum.HumanoidStateType.Dead then return end --Do not regen if already dead
	
	if lastDamage == nil or (tick() - lastDamage) > 0 then --humanoid is not currently taking damage (prevents override)
		if currentHealth < regenerationLimit then --humanoid is damaged, regen HP
			local timePassed: number = (tick() - lastRegen)
			if timePassed >= regenerationRate then --enough time has passed to regen HP again
				
				lastRegen = tick()
				
				changeRegenSizeBasedOnHunger()
				local healthToAdd = regenerationSize
				hum.Health = math.min(hum.Health + healthToAdd, hum.MaxHealth) --uses math.min to not go over the MaxHealth
				
				local hunger = char:GetAttribute("Hunger")
				if hunger then --Decrease hunger value on regen if hunger value exists
					if hunger > 0 and hunger <= 100 then
						char:SetAttribute("Hunger", hunger - .5)
					elseif hunger <= 0 then
						char:SetAttribute("Hunger", 0)
					elseif hunger > 100 then
						char:SetAttribute("Hunger", 100)
					end
				end
			end
		end
	end
	task.wait()
end
