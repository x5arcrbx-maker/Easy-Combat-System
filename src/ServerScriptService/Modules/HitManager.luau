local Modules = script.Parent
local KnockbackHandler = require(Modules:FindFirstChild("KnockbackHandler"))

local HitManager = {}

function HitManager.TryHit(attacker: Model, target: Model, force: number, forceTime: number, damage: number)
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid then
		return
	end
	local attackerHumanoid = attacker:FindFirstChildOfClass("Humanoid")
	if not attackerHumanoid then
		return
	end

	if not force then
		warn("Force is nil. Cannot process hit.")
		return
	elseif type(force) ~= "number" then
		warn("Force is not a number. Cannot process hit.")
		return
	end
	if not forceTime then
		warn("Force time is nil. Cannot process hit.")
		return
	elseif type(forceTime) ~= "number" then
		warn("Force time is not a number. Cannot process hit.")
		return
	end
	if not damage then
		warn("Damage is nil. Cannot process hit.")
		return
	elseif type(damage) ~= "number" then
		warn("Damage is not a number. Cannot process hit.")
		return
	end

	--Proceed with attack logic
	-- print(attacker.Name .. " hit " .. target.Name .. " for " .. damage .. " damage.")
	-- print("BEFORE HIT - Attacker Health: " .. attackerHumanoid.Health .. ", Target Health: " .. targetHumanoid.Health)
	KnockbackHandler.ApplyKnockback(attacker, target, force, forceTime)
	targetHumanoid:TakeDamage(damage)
	-- print("AFTER HIT - Attacker Health: " .. attackerHumanoid.Health .. ", Target Health: " .. targetHumanoid.Health)
end

return HitManager
