local ClashModule = {}

--//:SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris 			= game:GetService("Debris")

--//:REMOTES
local vfxRemote = ReplicatedStorage.Remotes_Bindables.Remotes.GeneralPlayer.SkillVFX :: RemoteEvent

--//:VARIABLES
local KB_TIME: number = 0.1
local KBforce: number = 20

--Knockback function (local)
local function knockback(attackerHRP: BasePart?, opponentHRP: BasePart?)
	if not attackerHRP or not opponentHRP then return end
	
	local Knockback: BodyVelocity = Instance.new("BodyVelocity")
	Knockback.Parent   = opponentHRP
	Knockback.MaxForce = Vector3.new(100000, 100000, 100000)
	-- Push opponent AWAY from attacker (direction from attacker to opponent)
	Knockback.Velocity = (opponentHRP.CFrame.Position - attackerHRP.CFrame.Position).Unit * KBforce
	Debris:AddItem(Knockback, KB_TIME)
end

--Clash function
function ClashModule.Clash(hrp: BasePart, opponentHRP: BasePart)
	local attackerChar: Model = hrp.Parent
	local opponentChar: Model = opponentHRP.Parent
	local attackType 		 = attackerChar:GetAttribute("AttackType")
	local opponentAttackType = opponentChar:GetAttribute("AttackType")

	knockback(hrp, opponentHRP)
	knockback(opponentHRP, hrp)

	if attackType == "Sharp" and opponentAttackType == "Sharp" then
		vfxRemote:FireAllClients(hrp, "Clash_Sharp")
	else
		vfxRemote:FireAllClients(hrp, "Clash_Blunt")
	end
end

return ClashModule
