local Modules = script.Parent
local HitboxCaster = require(Modules:WaitForChild("HitboxCaster"))

local SkillsLibrary = {}

SkillsLibrary.standardAttacks = {
	Light = {
		Hitbox = {
			Size = Vector3.new(5, 6, 5),
			Shape = "Rectangle",
		},
		Damage = 4,
		StunTime_self = 0.4,
		StunTime_target = 0.7,
		StunType_self = "Stunned",
		StunType_target = "Stunned",
		Force = 30,
		ForceTime = 0.1,
		Direction = "Push",
		trigger = function(character: Model, rootPart: BasePart)
			HitboxCaster.TryCast(
				SkillsLibrary.standardAttacks.Light.Hitbox.Shape,
				character,
				rootPart.CFrame,
				SkillsLibrary.standardAttacks.Light.Hitbox.Size,
				SkillsLibrary.standardAttacks.Light.Damage,
				SkillsLibrary.standardAttacks.Light.StunTime_self,
				SkillsLibrary.standardAttacks.Light.StunTime_target,
				SkillsLibrary.standardAttacks.Light.StunType_self,
				SkillsLibrary.standardAttacks.Light.StunType_target,
				SkillsLibrary.standardAttacks.Light.Force,
				SkillsLibrary.standardAttacks.Light.ForceTime,
				SkillsLibrary.standardAttacks.Light.Direction
			)
		end,
	},
	Heavy = {
		Hitbox = {
			Size = Vector3.new(5.5, 7, 8),
			Shape = "Rectangle",
		},
		Damage = 8,
		StunTime_self = 1,
		StunTime_target = 2,
		StunType_self = "Stunned",
		StunType_target = "Stunned",
		Force = 50,
		ForceTime = 0.2,
		Direction = "Push",
		trigger = function(character: Model, rootPart: BasePart)
			HitboxCaster.TryCast(
				SkillsLibrary.standardAttacks.Heavy.Hitbox.Shape,
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
				SkillsLibrary.standardAttacks.Heavy.Direction
			)
		end,
	},
}

return SkillsLibrary
