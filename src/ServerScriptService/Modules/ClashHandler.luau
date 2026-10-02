-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- VARIABLES
local KB_time: number = 0.1
local KB_force: number = 20
--
local Modules = script.Parent

-- REMOTES
local vfxRemote = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.SkillVFX :: RemoteEvent

-- MODULES
local KnockbackHandler = require(Modules.KnockbackHandler)

-- Code --
local ClashModule = {}

function ClashModule.Clash(attacker: Model, target: Model)
	local attackType = attacker:GetAttribute("AttackType")
	local opponentAttackType = target:GetAttribute("AttackType")

	KnockbackHandler.Apply(attacker, target, KB_force, KB_time, "Push")
	KnockbackHandler.Apply(target, attacker, KB_force, KB_time, "Push")

	local attackerRootPart = attacker:FindFirstChild("HumanoidRootPart") :: BasePart

	if attackType == "Sharp" and opponentAttackType == "Sharp" then
		vfxRemote:FireAllClients(attackerRootPart, "Clash_Sharp")
	else
		vfxRemote:FireAllClients(attackerRootPart, "Clash_Blunt")
	end
end

return ClashModule
