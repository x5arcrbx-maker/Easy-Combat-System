local Modules = script.Parent
local HitboxCaster = require(Modules:WaitForChild("HitboxCaster"))

local SkillsLibrary = {}

SkillsLibrary.standardAttacks = {
	Light = {
		hitbox = Vector3.new(4, 4, 5),
		Damage = 4,
		trigger = function(character: Model, rootPart: BasePart)
			HitboxCaster.castRectangleHitbox(
				character,
				rootPart.CFrame,
				SkillsLibrary.standardAttacks.Light.hitbox,
				SkillsLibrary.standardAttacks.Light.Damage
			)
		end,
	},
	Heavy = {
		hitbox = Vector3.new(7, 7, 8),
		Damage = 8,
		trigger = function(character: Model, rootPart: BasePart)
			HitboxCaster.castRectangleHitbox(
				character,
				rootPart.CFrame,
				SkillsLibrary.standardAttacks.Heavy.hitbox,
				SkillsLibrary.standardAttacks.Heavy.Damage
			)
		end,
	},
}

return SkillsLibrary
