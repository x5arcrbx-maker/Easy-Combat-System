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
	end

	if hum.Health < currentHealth and hum.Health > 0 then --Less damage than last regen tick, set currentHealth to hum.Health and set lastDamage to tick()
		currentHealth = hum.Health
		lastDamage = tick()
	elseif hum.Health > currentHealth and hum.Health > 0 then
		if currentHealth + regenerationSize > hum.Health then
			lastDamage = tick()
		end
		currentHealth = hum.Health	
	end
end

local function hungerCheck()
	local hunger = char:GetAttribute("Hunger")
	if hunger > 0 then
		regenerationSize = 0.5
	else
		regenerationSize = 0.25
	end
end

hum:GetPropertyChangedSignal("Health"):Connect(updateRegen)
hum:GetPropertyChangedSignal("MaxHealth"):Connect(updateRegen)

while true do
	if hum:GetState() == Enum.HumanoidStateType.Dead then return end --Do not regen if already dead

	if lastDamage == nil or (tick() - lastDamage) > 0 then
		if currentHealth < regenerationLimit then
			local timePassed = (tick() - lastRegen)
			if timePassed >= regenerationRate then
				lastRegen = tick()
				hungerCheck()
				local healthToAdd = regenerationSize
				hum.Health = math.min(hum.Health + healthToAdd, hum.MaxHealth)
			end
		end
	end
	task.wait()
end
