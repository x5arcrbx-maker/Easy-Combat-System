local Modules = script.Parent
local HitboxCaster = require(Modules:WaitForChild("HitboxCaster"))

local SkillsLibrary = {}

SkillsLibrary.standardAttacks = {
	Light = {
		hitbox = Vector3.new(4, 4, 5),
		Damage = 4,
		StunTime_self = 0.4,
		StunTime_target = 0.7,
		StunType_self = "Stunned",
		StunType_target = "Stunned",
		Force = 30,
		ForceTime = 0.1,
		trigger = function(character: Model, rootPart: BasePart)
			HitboxCaster.castRectangleHitbox(
				character,
				rootPart.CFrame,
				SkillsLibrary.standardAttacks.Light.hitbox,
				SkillsLibrary.standardAttacks.Light.Damage,
				SkillsLibrary.standardAttacks.Light.StunTime_self,
				SkillsLibrary.standardAttacks.Light.StunTime_target,
				SkillsLibrary.standardAttacks.Light.StunType_self,
				SkillsLibrary.standardAttacks.Light.StunType_target,
				SkillsLibrary.standardAttacks.Light.Force,
				SkillsLibrary.standardAttacks.Light.ForceTime
			)
		end,
	},
	Heavy = {
		hitbox = Vector3.new(7, 7, 8),
		Damage = 8,
		StunTime_self = 1,
		StunTime_target = 2,
		StunType_self = "Stunned",
		StunType_target = "Stunned",
		Force = 50,
		ForceTime = 0.2,
		trigger = function(character: Model, rootPart: BasePart)
			HitboxCaster.castRectangleHitbox(
				character,
				rootPart.CFrame,
				SkillsLibrary.standardAttacks.Heavy.hitbox,
				SkillsLibrary.standardAttacks.Heavy.Damage,
				SkillsLibrary.standardAttacks.Heavy.StunTime_self,
				SkillsLibrary.standardAttacks.Heavy.StunTime_target,
				SkillsLibrary.standardAttacks.Heavy.StunType_self,
				SkillsLibrary.standardAttacks.Heavy.StunType_target,
				SkillsLibrary.standardAttacks.Heavy.Force,
				SkillsLibrary.standardAttacks.Heavy.ForceTime
			)
		end,
	},
}

return SkillsLibrary
