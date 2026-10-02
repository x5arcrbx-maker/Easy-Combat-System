-- SERVICES
local Debris = game:GetService("Debris")

-- VARIABLES
local directions = {
	["Push"] = function(attackerRootPart: BasePart, targetRootPart: BasePart): Vector3
		return (targetRootPart.Position - attackerRootPart.Position).Unit
	end,
	["Pull"] = function(attackerRootPart: BasePart, targetRootPart: BasePart): Vector3
		return (targetRootPart.Position + attackerRootPart.Position).Unit
	end,
	["Up"] = function(attackerRootPart: BasePart, targetRootPart: BasePart): Vector3
		return (targetRootPart.Position * attackerRootPart.CFrame.UpVector).Unit
	end,
	["Down"] = function(attackerRootPart: BasePart, targetRootPart: BasePart): Vector3
		return (targetRootPart.Position * -attackerRootPart.CFrame.UpVector).Unit
	end,
}

-- FUNCTIONS
local function getDirection(direction: string, attackerRootPart: BasePart, targetRootPart: BasePart): Vector3
	local existingDirectionFunc = directions[direction]
	if not existingDirectionFunc then
		warn(string.format("direction function for (%s) does not exist.", tostring(direction)))
	end
	local directionVector: Vector3 = existingDirectionFunc(attackerRootPart, targetRootPart)
	return directionVector
end

local KnockbackHandler = {}

function KnockbackHandler:Apply(attacker: Model, target: Model, Force: number, Time: number, direction: string?)
	local targetRootPart = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRootPart then
		warn("Target does not have a HumanoidRootPart. Cannot apply knockback.")
		return
	end

	local attackerRootPart = attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not attackerRootPart then
		warn("Attacker does not have a HumanoidRootPart. Cannot apply knockback.")
		return
	end

	local knockbackDirection: Vector3 = getDirection(direction, attackerRootPart, targetRootPart)
	local knockbackVelocity: Vector3 = knockbackDirection * Force

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = knockbackVelocity
	bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
	bodyVelocity.Parent = targetRootPart
	Debris:AddItem(bodyVelocity, Time)
end

return KnockbackHandler
