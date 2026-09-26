local HitHandler = {}

HitHandler.TryHit = function(attacker: Model, target: Model)
	local attackerHumanoid = attacker:FindFirstChildOfClass("Humanoid")
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")

	if attackerHumanoid and targetHumanoid then
		-- Apply damage to the target
		local damageAmount = 10 -- You can adjust this value as needed
		if targetHumanoid.Health > 0 then
			targetHumanoid:TakeDamage(damageAmount)
		end
		-- Optionally, you can add additional effects here (e.g., knockback, animations, etc.)
	end
end

return HitHandler
