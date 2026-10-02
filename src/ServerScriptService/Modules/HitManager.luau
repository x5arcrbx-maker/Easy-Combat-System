-- VARIABLES
local Modules = script.Parent

-- MODULES
local KnockbackHandler = require(Modules:FindFirstChild("KnockbackHandler"))
local StunHandler = require(Modules:FindFirstChild("StunHandler"))

-- Code --
local HitManager = {}

function HitManager.TryHit(
	attacker: Model,
	target: Model,
	damage: number,
	stunTime_self: number,
	stunTime_target: number,
	stunType_self: string,
	stunType_target: string,
	force: number,
	forceTime: number,
	direction: string,
	ragdollVal: boolean,
	ragdollTime: number
)
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid then
		return
	end
	local attackerHumanoid = attacker:FindFirstChildOfClass("Humanoid")
	if not attackerHumanoid then
		return
	end

	local arguments = {
		Model = {
			attacker,
			target,
		},
		number = {
			damage,
			stunTime_self,
			stunTime_target,
			force,
			forceTime,
		},
		string = {
			stunType_self,
			stunType_target,
			direction,
		},
	}
	for argName, arg in ipairs(arguments.Model) do
		if arg == nil then
			warn("One or more arguments (type Model) are nil. Cannot process hit.")
			warn(string.format("Name (%*) : Value (%*)", argName, arg))
			return
		elseif not arg:IsA("Model") then
			warn("One or more arguments (type Model) are not of type Model. Cannot process hit.")
			warn(string.format("Name (%*) : Value (%*)", argName, arg))
			return
		end
	end
	for argName, arg in ipairs(arguments.number) do
		if arg == nil then
			warn("One or more arguments (type number) are nil. Cannot process hit.")
			warn(string.format("Name (%*) : Value (%*)", argName, arg))
			return
		elseif type(arg) ~= "number" then
			warn("One or more arguments (type number) are not of type number. Cannot process hit.")
			warn(string.format("Name (%*) : Value (%*)", argName, arg))
			return
		end
	end
	for argName, arg in ipairs(arguments.string) do
		if arg == nil then
			warn("One or more arguments (type string) are nil. Cannot process hit.")
			warn(string.format("Name (%*) : Value (%*)", argName, arg))
			return
		elseif type(arg) ~= "string" then
			warn("One or more arguments (type string) are not of type string. Cannot process hit.")
			warn(string.format("Name (%*) : Value (%*)", argName, arg))
			return
		end
	end

	--Proceed with attack logic
	-- print(attacker.Name .. " hit " .. target.Name .. " for " .. damage .. " damage.")
	-- print("BEFORE HIT - Attacker Health: " .. attackerHumanoid.Health .. ", Target Health: " .. targetHumanoid.Health)
	KnockbackHandler:Apply(attacker, target, force, forceTime, direction)
	StunHandler:Apply(target, stunTime_target, stunType_target)
	if ragdollVal then
		StunHandler:Apply(target, ragdollTime, "Ragdolled")
	end
	target:SetAttribute("Ragdoll", true)
	targetHumanoid:TakeDamage(damage)
	-- print("AFTER HIT - Attacker Health: " .. attackerHumanoid.Health .. ", Target Health: " .. targetHumanoid.Health)
end

return HitManager
