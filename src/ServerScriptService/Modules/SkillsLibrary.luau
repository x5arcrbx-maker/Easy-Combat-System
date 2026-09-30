local Modules = script.Parent
local HitboxCaster = require(Modules:WaitForChild("HitboxCaster"))

local SkillsLibrary = {}

SkillsLibrary.standardAttacks = {
	Light = {
		hitbox = Vector3.new(4, 4, 5),
		Damage = 4,
		Force = 20,
		ForceTime = 0.2,
		trigger = function(character: Model, rootPart: BasePart)
			HitboxCaster.castRectangleHitbox(
				character,
				rootPart.CFrame,
				SkillsLibrary.standardAttacks.Light.hitbox,
				SkillsLibrary.standardAttacks.Light.Damage,
				SkillsLibrary.standardAttacks.Light.Force,
				SkillsLibrary.standardAttacks.Light.ForceTime
			)
		end,
	},
	Heavy = {
		hitbox = Vector3.new(7, 7, 8),
		Damage = 8,
		Force = 20,
		ForceTime = 0.2,
		trigger = function(character: Model, rootPart: BasePart)
			HitboxCaster.castRectangleHitbox(
				character,
				rootPart.CFrame,
				SkillsLibrary.standardAttacks.Heavy.hitbox,
				SkillsLibrary.standardAttacks.Heavy.Damage,
				SkillsLibrary.standardAttacks.Heavy.Force,
				SkillsLibrary.standardAttacks.Heavy.ForceTime
			)
		end,
	},
}

return SkillsLibrary
