local SkillGuard = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local addCooldownRemote: RemoteEvent =
	ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.CooldownGUI
local Attributes = require(ReplicatedStorage.Modules.Tables.Attributes)
local CooldownHandler = require(script.Parent.CooldownHandler)
local playerCooldowns = require(script.Parent.PlayerCooldowns)

-- Atomically check cooldown + prevention + reserve + set UsingAttack
-- returns (ok, remaining)
function SkillGuard:CheckSkillAllowed(
	player: Player,
	char: Model,
	skill: string,
	cooldown: number,
	useEndlagSystem: boolean,
	duration: number?
): (boolean, number)
	playerCooldowns[player] = playerCooldowns[player] or {}

	-- Check cooldown
	local remaining = CooldownHandler:GetRemainingCooldown(player, skill)
	if remaining > 0 then
		return false, remaining
	end

	if char:GetAttribute("UsingAttack") then
		return false, 0
	end

	if useEndlagSystem then
		--Set UsingAttack and Slowed
		char:SetAttribute("UsingAttack", true)
		char:SetAttribute("Slowed", true)
		task.delay(duration, function()
			char:SetAttribute("UsingAttack", false)
			char:SetAttribute("Slowed", false)
		end)
	else
		--Set UsingAttack
		char:SetAttribute("UsingAttack", true)
		char:SetAttribute("Slowed", true)
	end

	-- Check prevention attributes (excluding UsingAttack since we just set it)
	for _, attribute in ipairs(Attributes.PREVENTION_ATTRIBUTES) do
		if char:GetAttribute(attribute) then
			char:SetAttribute("UsingAttack", false)
			return false, 0
		end
	end

	-- Reserve cooldown (set expiresAt)
	playerCooldowns[player][skill] = tick() + (cooldown or 0)

	-- Send cooldown to player's GUI
	addCooldownRemote:FireClient(player, skill, cooldown)

	return true, 0
end

function SkillGuard:CanPlayFX(char: Model): boolean
	-- Check if char can play FX (not stunned, ragdolled, etc.)
	for _, attribute in ipairs(Attributes.PREVENTION_ATTRIBUTES) do
		if char:GetAttribute(attribute) then
			return false
		end
	end
	return true
end

return SkillGuard
