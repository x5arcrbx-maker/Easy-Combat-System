local HitManager = {}

function HitManager.TryHit(attacker: Model, target: Model, damage: number)
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid then
		return
	end
	local attackerHumanoid = attacker:FindFirstChildOfClass("Humanoid")
	if not attackerHumanoid then
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
	print(attacker.Name .. " hit " .. target.Name .. " for " .. damage .. " damage.")
	print("BEFORE HIT - Attacker Health: " .. attackerHumanoid.Health .. ", Target Health: " .. targetHumanoid.Health)
	targetHumanoid:TakeDamage(damage)
	print("AFTER HIT - Attacker Health: " .. attackerHumanoid.Health .. ", Target Health: " .. targetHumanoid.Health)
end

return HitManager
