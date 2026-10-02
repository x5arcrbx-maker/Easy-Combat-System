--SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- VARIABLES
local Modules = script.Parent
local RS_Modules = ReplicatedStorage:FindFirstChild("Modules") :: Folder
local RS_Functions = RS_Modules:FindFirstChild("Functions")

-- MODULES
local HitboxCaster = require(Modules:WaitForChild("HitboxCaster"))
local _allowedToAttack = require(RS_Functions:FindFirstChild("AllowedToAttack"))

-- Code --
local SkillsLibrary = {}

SkillsLibrary.standardAttacks = {
	Light = {
		Hitbox = {
			Size = Vector3.new(5, 6, 5),
			Shape = "Rectangle",
		},
		Duration = 0.15,
		Damage = 4,
		StunTime_self = 0.3,
		StunTime_target = 0.65,
		StunType_self = "Stunned",
		StunType_target = "Stunned",
		Force = 15,
		ForceTime = 0.1,
		Direction = "Push",
		Ragdoll = {
			Value = false,
			Time = 0, -- will be set later
		},
		trigger = function(character: Model, rootPart: BasePart)
			-- if not allowedToAttack(character) then
			-- 	return
			-- end

			local WindUp: number
			if not character:GetAttribute("Weapon") or character:GetAttribute("Weapon") == "Default" then
				WindUp = 0.15
			else
				WindUp = 0.2
			end
			local currentCombo: number = character:GetAttribute("Combo") or 0
			local comboToSet: number
			local lastTimeHit = character:GetAttribute("ComboLastHit")
			local resetTime = character:GetAttribute("ComboResetTime")
			if ((tick() - lastTimeHit) >= resetTime) or ((currentCombo + 1) > 5) then
				comboToSet = 1
			else
				comboToSet = math.min(currentCombo + 1, 5)
			end

			local new_StunTime_target: number = SkillsLibrary.standardAttacks.Light.StunTime_target
			local new_Force: number = SkillsLibrary.standardAttacks.Light.Force
			local new_RagdollValue: number = SkillsLibrary.standardAttacks.Light.Ragdoll.Value
			local new_RagdollTime: number = SkillsLibrary.standardAttacks.Light.Ragdoll.Time
			if comboToSet == 5 then
				new_StunTime_target = new_StunTime_target * 1.5
				new_Force = new_Force * 4
				new_RagdollValue = true
				new_RagdollTime = new_StunTime_target
			end

			task.delay(WindUp, function()
				HitboxCaster.TryCast(
					SkillsLibrary.standardAttacks.Light.Hitbox.Shape,
					SkillsLibrary.standardAttacks.Light.Duration,
					character,
					rootPart.CFrame,
					SkillsLibrary.standardAttacks.Light.Hitbox.Size,
					SkillsLibrary.standardAttacks.Light.Damage,
					SkillsLibrary.standardAttacks.Light.StunTime_self,
					new_StunTime_target,
					SkillsLibrary.standardAttacks.Light.StunType_self,
					SkillsLibrary.standardAttacks.Light.StunType_target,
					new_Force,
					SkillsLibrary.standardAttacks.Light.ForceTime,
					SkillsLibrary.standardAttacks.Light.Direction,
					new_RagdollValue,
					new_RagdollTime
				)
				character:SetAttribute("Combo", comboToSet)
				print(string.format("set attribute Combo to %d", comboToSet))
				character:SetAttribute("ComboLastHit", tick())
			end)
		end,
	},
	Heavy = {
		Hitbox = {
			Size = Vector3.new(5.5, 7, 8),
			Shape = "Rectangle",
		},
		Duration = 0.3,
		Damage = 8,
		StunTime_self = 1.1,
		StunTime_target = 2,
		StunType_self = "Stunned",
		StunType_target = "Stunned",
		Force = 50,
		ForceTime = 0.2,
		Direction = "Push",
		Ragdoll = {
			Value = true,
			Time = 0, -- will be changed later
		},
		trigger = function(character: Model, rootPart: BasePart)
			-- if not allowedToAttack(character) then
			-- 	return
			-- end

			local WindUp: number
			if not character:GetAttribute("Weapon") or character:GetAttribute("Weapon") == "Default" then
				WindUp = 0.45
			else
				WindUp = 0.5
			end

			SkillsLibrary.standardAttacks.Heavy.Ragdoll.Time = SkillsLibrary.standardAttacks.Heavy.StunTime_target

			task.delay(
				WindUp,
				HitboxCaster.TryCast,
				SkillsLibrary.standardAttacks.Heavy.Hitbox.Shape,
				SkillsLibrary.standardAttacks.Heavy.Duration,
				character,
				rootPart.CFrame,
				SkillsLibrary.standardAttacks.Heavy.Hitbox.Size,
				SkillsLibrary.standardAttacks.Heavy.Damage,
				SkillsLibrary.standardAttacks.Heavy.StunTime_self,
				SkillsLibrary.standardAttacks.Heavy.StunTime_target,
				SkillsLibrary.standardAttacks.Heavy.StunType_self,
				SkillsLibrary.standardAttacks.Heavy.StunType_target,
				SkillsLibrary.standardAttacks.Heavy.Force,
				SkillsLibrary.standardAttacks.Heavy.ForceTime,
				SkillsLibrary.standardAttacks.Heavy.Direction,
				SkillsLibrary.standardAttacks.Heavy.Ragdoll.Value,
				SkillsLibrary.standardAttacks.Heavy.Ragdoll.Time
			)
		end,
	},
}

return SkillsLibrary
