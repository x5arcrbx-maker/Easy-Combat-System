local Debris = game:GetService("Debris")

local KnockbackHandler = {}

function KnockbackHandler.ApplyKnockback(attacker: Model, target: Model, Force: number, Time: number)
	local targetHumanoidRootPart: BasePart = target:FindFirstChild("HumanoidRootPart")
	if not targetHumanoidRootPart then
		warn("Target does not have a HumanoidRootPart. Cannot apply knockback.")
		return
	end

	local attackerHumanoidRootPart: BasePart = attacker:FindFirstChild("HumanoidRootPart")
	if not attackerHumanoidRootPart then
		warn("Attacker does not have a HumanoidRootPart. Cannot apply knockback.")
		return
	end

	local direction: Vector3 = (targetHumanoidRootPart.Position - attackerHumanoidRootPart.Position).Unit
	local knockbackVelocity: Vector3 = direction * Force

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = knockbackVelocity
	bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
	bodyVelocity.Parent = targetHumanoidRootPart
	Debris:AddItem(bodyVelocity, Time)
end

return KnockbackHandler
